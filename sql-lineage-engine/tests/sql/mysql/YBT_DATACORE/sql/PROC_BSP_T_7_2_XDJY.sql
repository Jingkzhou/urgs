DROP Procedure IF EXISTS `PROC_BSP_T_7_2_XDJY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_7_2_XDJY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回CODE
                                         OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
                                         )
BEGIN

  /******
      程序名称  ：信贷交易
      程序功能  ：加工信贷交易
      目标表：T_7_2
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
	-- JLBA202412200001_关于一表通监管数据报送系统修改逻辑及转EAST脚本的需求_20250116
	-- JLBA202501240018_关于一表通监管数据报送系统变更的需求_20250311
	/* 需求编号：JLBA202502210009 上线日期：20250415，修改人：姜俐锋，提出人：吴大为 */
	/* 需求编号：JLBA202505280002 上线日期：2025-06-19，修改人：巴启威  提出人：吴大为  修改原因：因一表通校验问题发现的代码逻辑调整*/
	/* 需求编号：JLBA202507300010 上线日期：2025-09-29，修改人：姜俐锋，提出人：信贷新增产品 修改原因：关于新一代信贷管理系统新增线上微贷板块的需求 */
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
	SET P_PROC_NAME = 'PROC_BSP_T_7_2_XDJY';
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
	
	DELETE FROM T_7_2 WHERE G020030 = TO_CHAR(P_DATE,'YYYY-MM-DD') ;
	
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	 
	
	
	    INSERT  INTO T_7_2  
                   (
                     G020001  , --  01'交易ID'
                     G020002  , --  02'协议ID'
                     G020003  , --  03'分户账号'
                     G020004  , --  04'客户ID'
                     G020005  , --  05'交易机构ID'
                     G020006  , --  06'借据ID'
                     G020007  , --  07'核心交易日期'
                     G020008  , --  08'核心交易时间'
                     G020009  , --  09'交易金额'
                     G020010  , --  10'账户余额'
                     G020011  , --  11'币种'
                     G020012  , --  12'信贷交易类型'
                     G020013  , --  13'科目ID'
                     G020014  , --  14'科目名称'
                     G020015  , --  15'借贷标识'
                     G020016  , --  16'受托支付标识' 信贷资金支付类型
                     G020017  , --  17'对方账号'
                     G020018  , --  18'对方户名'
                     G020019  , --  19'对方账号行号'
                     G020020  , --  20'对方行名'
                     G020021  , --  21'冲补抹标识'
                     G020022  , --  22'经办员工ID'
                     G020023  , --  23'授权员工ID'
                     G020024  , --  24'交易渠道'
                     G020025  , --  25'代办人姓名'
                     G020026  , --  26'代办人证件类型'
                     G020027  , --  27'代办人证件号码'
                     G020028  , --  28'现转标识'
                     G020029  , --  29'摘要'
                     G020030  , --  30'采集日期'
                     DIS_DATA_DATE,
                     DIS_BANK_ID,
                     DEPARTMENT_ID ,
                     DIS_DEPT
                     )
   -- 对公                  
	 SELECT 
            T1.KEY_TRANS_NO||NVL(T1.SERIAL_NO, 1)  ,   --    01'交易ID'
            CASE
                WHEN substr(T2.ITEM_CD,1,6) IN ('130101','130104','130102','130105') THEN  SUBSTR(t2.ACCT_NUM || NVL(t2.DRAFT_RNG,''),1,60)
              --  WHEN T2.ITEM_CD LIKE '1306%' THEN T2.LOAN_NUM  -- 20250116 与6.2同步
                ELSE T2.ACCT_NUM
                end AS XDHTH ,   --    02'协议ID'  
             CASE
                WHEN substr(T2.ITEM_CD,1,6) IN ('130101','130104','130102','130105') THEN  SUBSTR(t2.ACCT_NUM || NVL(t2.DRAFT_RNG,''),1,60)
                ELSE T2.LOAN_NUM  -- 20250311
                end  AS FHZH   ,   --    03'分户账号'
            T2.CUST_ID AS KHTYBH,   --    04'客户ID'
            --  SUBSTR(TRIM(T3.FIN_LIN_NUM ),1,11)||T1.ORG_NUM AS JGH ,   --    05'交易机构ID'
            t3.ORG_ID AS JGH ,   --     05'交易机构ID'  一表通校验修改  20241015 王金保 
            /*CASE
             WHEN T2.ACCT_TYP LIKE '09%' THEN REPLACE(T2.ORIG_ACCT_NO,'#','')
             ELSE T2.LOAN_NUM
            end*/
            CASE WHEN SUBSTR(t2.ITEM_CD, 1, 6) in ('130101', '130102', '130104', '130105') THEN SUBSTR(t2.ACCT_NUM || NVL(t2.DRAFT_RNG,''),1,60)
             ELSE T2.LOAN_NUM
             END AS XDJJH ,   --    06'借据ID' 20250331 与8.1同步修改
            NVL(TO_CHAR(to_date(T1.TX_DT,'YYYYMMDD'), 'YYYY-MM-DD'), '9999-12-31') AS JYRQ ,   --    07'核心交易日期'
            SUBSTR( T1.TRANS_TIME , 1, 2) || ':' || SUBSTR( T1.TRANS_TIME , 3, 2) || ':' ||SUBSTR( T1.TRANS_TIME , 5, 2) AS JYSJ ,   --    08'核心交易时间'
            T1.TRANS_AMT AS JYJE ,   --    09'交易金额'
            CASE WHEN T1.CD_TYPE ='1' --  '借'
                  AND T1.TRANTYPE2 ='J' --  发放 
                THEN T1.TRANS_AMT
                ELSE T2.LOAN_ACCT_BAL + T2.OD_LOAN_ACCT_BAL 
                END AS ZHYE  ,   --    10'账户余额' 20250116 当日放款当日还款，一表通取借据表日终余额所以为0，与大为哥确认如果是01放款账户余额取交易金额解决该问题
            T1.CURRENCY AS BZ  ,   --    11'币种'
            CASE WHEN t1.TRANTYPE2 ='J' THEN '01'   --   发放
                 WHEN t1.TRANTYPE2 ='K'  AND T7.LOAN_NUM IS NOT NULL THEN '02'   --  担保代偿收回
                 WHEN t1.TRANTYPE2 ='K'  AND T7.LOAN_NUM IS NULL THEN '03'   --  非担保代偿收回
                 WHEN t1.TRANTYPE2 ='L' THEN '04'   --   收息
                 ELSE '05'   --   其它
                 END  AS XDJYLX,   --    12'信贷交易类型' 
            TRIM(T1.GL_ITEM_CODE) AS KMBH  ,   --    13'科目ID'
            NVL(T4.Gl_Cd_Name,Q.Gl_Cd_Name) AS MXKMMC ,   --    14'科目名称'
            CASE
             WHEN T1.CD_TYPE = '1' THEN '01'   --   '借'
             WHEN T1.CD_TYPE = '2' THEN '02'   --   '贷'
            END AS JYJDBZ,    --    15'借贷标识'
            
           -- CASE WHEN T2.DRAWDOWN_TYPE = 'B' THEN '1'
           -- ELSE 0   
           -- END AS stzf  ,   --    16'受托支付标识'
            CASE
             WHEN T1.GL_ITEM_CODE='13050101' THEN '02' -- 受托支付 -- 20250311
             WHEN t2.DRAWDOWN_TYPE = 'A' THEN '01' -- 自主支付
             WHEN t2.DRAWDOWN_TYPE = 'B' THEN '02' -- 受托支付
             WHEN t2.DRAWDOWN_TYPE = 'C' THEN '03' -- 混合支付
             WHEN T2.DRAWDOWN_TYPE IS NULL AND T1.GL_ITEM_CODE LIKE '1306%' THEN '01' -- 自主支付 [20250619][巴启威][JLBA202505280002][吴大为]：垫款科目，如果没有放款方式，默认为01-自主支付
            END  AS XDZJZFLX ,   -- 信贷资金支付类型
            NVL(NVL(TRIM(T1.OPPO_ACCT_NUM), T2.PAY_ACCT_NUM),T2.LOAN_FHZ_NUM) AS dfzh ,   --    17'对方账号'
            NVL(T1.OPPO_ACCT_NAM, A.CUST_NAM) AS DFHM ,   --    18'对方户名'
            CASE
             WHEN T2.ORG_NUM = '009808' THEN '313241066661'
             ELSE NVL(T1.OPPO_ORG_NUM, T3.BANK_CD)
            END AS DFXH   ,   --    19'对方账号行号'
            CASE
             WHEN T2.ORG_NUM = '009808' THEN '吉林银行股份有限公司'
             ELSE NVL(T1.OPPO_ORG_NAM, T3.ORG_NAM)
            END AS DFXM  ,   --    20'对方行名'
            CASE WHEN (T1.TRAN_STS IN ('B','C','D') or T1.TRANS_AMT < 0) THEN '02'  --   '冲补抹'   -- [20250415][姜俐锋][JLBA202502210009][吴大为]: 吴大为确认交易金额负数时为冲补抹
                 WHEN T1.TRAN_STS='A' THEN '01'   --   '正常'
                 ELSE '01'   --   '正常'
            END AS CBMBZ  ,   --    21'冲补抹标识'
            NVL(T2.JBYG_ID,T2.EMP_ID) AS JBYG  ,   --    22'经办员工ID'
            NVL(T2.SQY_ID,T2.SPYG_ID) AS SQYG  ,   --    23'授权员工ID'
            CASE WHEN T1.CHANNEL = '01' THEN '01'    --   '柜面'
                 WHEN T1.CHANNEL = '02' THEN '05'    --   '网银'
                 WHEN T1.CHANNEL = '04' THEN '02'    --   'ATM'
                 WHEN T1.CHANNEL = '05' THEN '04'    --   'POS'
                 WHEN T1.CHANNEL = '06' THEN '06'    --   '手机银行'
                 WHEN T1.CHANNEL = '07' THEN '07'    --   '第三方支付'
                 WHEN T1.CHANNEL = '08' THEN '03'    --   'VTM'
                 WHEN T1.CHANNEL = '9999' THEN '00'   --   '其他' 
                 ELSE '00'   --   '其他' 
            END AS JYQD ,   --    24'交易渠道'
           T1.AGENT_NAME_A AS DBRXM ,   --    25'代办人姓名'
           G.GB_CODE_NAME  ,   --    26'代办人证件类型'
           T1.AGENT_IDENTIFCATION_A AS DBRZJHM  ,   --    27'代办人证件号码'
           CASE
             WHEN T1.TRANS_FLG = '0' THEN '01'   --   '现'
             WHEN T1.TRANS_FLG = '1' THEN '02'   --   '转'
           END AS XZBZ ,   --    28'现转标识'
           CASE
             WHEN T1.SUMMARY IS NULL THEN
              (CASE
                WHEN T1.CD_TYPE = '1' THEN
                 '放款'
                WHEN T1.CD_TYPE = '2' THEN
                 '还款'
              END)
             ELSE
              NVL(M.GB_CODE_NAME,T1.SUMMARY)
           END AS ZY  ,   --    29'摘要'
           TO_CHAR(P_DATE,'YYYY-MM-DD'),   --    30'采集日期'
           TO_CHAR(P_DATE,'YYYY-MM-DD'),
           T1.ORG_NUM ,
           CASE  
           WHEN T2.DEPARTMENTD ='信用卡' THEN '009803'   --   吉林银行总行卡部(信用卡中心管理)(009803)
           WHEN T2.DEPARTMENTD ='公司金融' OR SUBSTR(T2.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR'   --   公司金融部(0098JR)
           WHEN T2.DEPARTMENTD ='个人信贷' THEN '0098LDB'   --   零售信贷部(0098LDB)
           WHEN T2.DEPARTMENTD ='普惠金融' THEN '0098PH'   --   普惠金融部(0098PH)
           WHEN SUBSTR(T2.ITEM_CD,1,6)= '130603' THEN '0098GJ'   --   国际业务（贸易金融）部(0098GJ)
           WHEN SUBSTR(T2.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804'   --   吉林银行金融市场部(009804)
           ELSE   '009804'
           END AS TX ,
           'DG'
      FROM SMTMODS.L_TRAN_TX T1  -- 交易信息表
     INNER JOIN SMTMODS.L_ACCT_LOAN T2  -- 贷款借据信息表
        ON T1.ACCOUNT_CODE = T2.LOAN_NUM
       AND T2.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_CUST_ALL A  -- 全量客户表
        ON T1.CUST_ID = A.CUST_ID
       AND A.DATA_DATE = I_DATE
      LEFT JOIN VIEW_L_PUBL_ORG_BRA T3  -- 机构表
        ON T2.ORG_NUM = T3.ORG_NUM
       AND T3.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_FINA_INNER T4  -- 内部科目对照表
        ON TRIM(T1.GL_ITEM_CODE) = T4.STAT_SUB_NUM  -- 20211012日修改：添加trim函数删除空格
       AND T1.ORG_NUM=T4.ORG_NUM
       AND T4.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_FINA_INNER Q  -- 内部科目对照表
        ON TRIM(T1.GL_ITEM_CODE) = Q.STAT_SUB_NUM  -- 20211012日修改：添加trim函数删除空格
       AND Q.ORG_NUM='990000'
       AND Q.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT T6  -- 贷款合同信息表
        ON T2.ACCT_NUM = T6.CONTRACT_NUM
       AND T6.DATA_DATE = I_DATE
      LEFT JOIN M_DICT_CODETABLE M
        ON T1.TRAN_CODE=M.L_CODE
       AND M.L_CODE_TABLE_CODE='TRANS_CODE'
      LEFT JOIN  M_DICT_CODETABLE G
        ON T1.AGENT_IDENTI_TYPE_A = G.L_CODE
       AND G.L_CODE_TABLE_CODE='C0001' 
      LEFT JOIN (SELECT DISTINCT  TT.PAY_TYPE,TT.LOAN_NUM FROM   SMTMODS.L_TRAN_LOAN_PAYM TT WHERE TT.DATA_DATE = I_DATE AND TT.PAY_TYPE ='07') T7
        ON T1.ACCOUNT_CODE=T7.LOAN_NUM
     WHERE T1.DATA_DATE = I_DATE
       AND T1.TRANS_AMT <> 0
       AND t1.PAYMENT_PROPERTY is null   --  交易过滤掉支付使用数据
       AND NVL(T6.PROD_NAME,'##') NOT IN ('个人遗留贷款无本产品','公司遗留贷款无本产品')   --  MODIFY JIANGHUAIFU 剔除无本有息历史数据
       AND t1.PAYMENT_ORDER is null    --  交易过滤掉支付使用数据
       AND (SUBSTR(T2.ITEM_CD,1,6) IN ('130101','130102','130104','130105')   --  票据
            OR T2.ITEM_CD like '1306%'   --  垫款
            OR SUBSTR(T2.ITEM_CD,1,6) IN ('130302')    --  公司贷款
            OR T2.ITEM_CD like '1305%'   --  贸易融资
            OR T2.ITEM_CD  IN('71200102','71200103','71200104','71200202','71200203','71200204','71200302','71200303','71200304')   --  核销
            OR T2.ITEM_CD='30200101'   --  单位委托贷款
           )
        AND T1.GL_ITEM_CODE IS NOT NULL
        AND T1.GL_ITEM_CODE NOT LIKE '7120%' 
        AND (T2.ACCT_STS <> '3'  
              OR T2.LOAN_ACCT_BAL > 0   
              OR  T2.FINISH_DT  = I_DATE 
              OR (T2.INTERNET_LOAN_FLG = 'Y' AND T2.FINISH_DT= TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD')-1,'YYYYMMDD'))  -- 互联网贷款数据晚一天下发，上月末数据当月取
              OR (T2.CP_ID='DK001000100041' AND T2.FINISH_DT= TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD')-1,'YYYYMMDD')) -- [20250929][姜俐锋][JLBA202507300010][信贷新增产品]: 同网贷部分数据处理方式
              ) 
       AND NOT EXISTS(SELECT A.LOAN_NUM,A.WRITE_OFF_DATE -- 核销日期
                FROM SMTMODS.L_ACCT_WRITE_OFF A -- 贷款核销
                WHERE A.DATA_DATE = I_DATE
                  AND A.WRITE_OFF_DATE < I_DATE 
                  AND A.LOAN_NUM = T2.LOAN_NUM )
        AND NVL(T6.PROD_NAME,'##') NOT IN ('个人遗留贷款无本产品','公司遗留贷款无本产品') -- 剔除无本有息历史数据   
        and (T2.LOAN_STOCKEN_DATE IS NULL OR T2.LOAN_STOCKEN_DATE = I_DATE)   -- add by haorui 20250311 JLBA202408200012 资产未转让
        ; 
		 
    COMMIT;              
    
    
        -- 个人         
     INSERT  INTO T_7_2  
                   (
                     G020001  , --  01'交易ID'
                     G020002  , --  02'协议ID'
                     G020003  , --  03'分户账号'
                     G020004  , --  04'客户ID'
                     G020005  , --  05'交易机构ID'
                     G020006  , --  06'借据ID'
                     G020007  , --  07'核心交易日期'
                     G020008  , --  08'核心交易时间'
                     G020009  , --  09'交易金额'
                     G020010  , --  10'账户余额'
                     G020011  , --  11'币种'
                     G020012  , --  12'信贷交易类型'
                     G020013  , --  13'科目ID'
                     G020014  , --  14'科目名称'
                     G020015  , --  15'借贷标识'
                     G020016  , --  16'受托支付标识' 信贷资金支付类型
                     G020017  , --  17'对方账号'
                     G020018  , --  18'对方户名'
                     G020019  , --  19'对方账号行号'
                     G020020  , --  20'对方行名'
                     G020021  , --  21'冲补抹标识'
                     G020022  , --  22'经办员工ID'
                     G020023  , --  23'授权员工ID'
                     G020024  , --  24'交易渠道'
                     G020025  , --  25'代办人姓名'
                     G020026  , --  26'代办人证件类型'
                     G020027  , --  27'代办人证件号码'
                     G020028  , --  28'现转标识'
                     G020029  , --  29'摘要'
                     G020030  , --  30'采集日期'
                     DIS_DATA_DATE,
                     DIS_BANK_ID,
                     DEPARTMENT_ID ,
                     DIS_DEPT
                     )
    
        
	 WITH ACCT_CARD AS 
 (
 SELECT TT.DATA_DATE, TT.ACCT_NUM, TT.TYPE_ID
  FROM (SELECT XX.DATA_DATE, XX.ACCT_NUM, XX.TYPE_ID, ROW_NUMBER() OVER(PARTITION BY XX.TYPE_ID ORDER BY XX.ACCT_NUM) AS NUM
          FROM SMTMODS.L_ACCT_DEPOSIT_SUB XX
         WHERE XX.DATA_DATE = I_DATE) TT
         WHERE TT.NUM = 1)


           SELECT 
            T1.KEY_TRANS_NO||NVL(T1.SERIAL_NO, 1)  , --  01'交易ID'
            CASE
                WHEN substr(T2.ITEM_CD,1,6) IN ('130101','130104','130102','130105') THEN  SUBSTR(t2.ACCT_NUM || NVL(t2.DRAFT_RNG,''),1,60)
               -- WHEN T2.ITEM_CD LIKE '1306%' THEN T2.LOAN_NUM  -- 20250116 与6.2同步
                ELSE T2.ACCT_NUM
                end AS XDHTH , --  02'协议ID'
            T2.LOAN_NUM  AS FHZH   , --  03'分户账号'
            T2.CUST_ID AS KHTYBH, --  04'客户ID'
            -- SUBSTR(TRIM(T3.FIN_LIN_NUM ),1,11)||T1.ORG_NUM AS JGH , --  05'交易机构ID'
            T3.ORG_ID ,       --  05'交易机构ID'  一表通校验修改  20241015 王金保
            CASE
             WHEN T2.ACCT_TYP LIKE '09%' THEN REPLACE(T2.ORIG_ACCT_NO,'#','')
             ELSE T2.LOAN_NUM
            END AS XDJJH , --  06'借据ID'
            NVL(TO_CHAR(to_date(T1.TX_DT,'YYYYMMDD'), 'YYYY-MM-DD'), '9999-12-31') AS JYRQ , --  07'核心交易日期'
             SUBSTR( T1.TRANS_TIME , 1, 2) || ':' || SUBSTR( T1.TRANS_TIME , 3, 2) || ':' ||SUBSTR( T1.TRANS_TIME , 5, 2)   AS JYSJ  , --  08'核心交易时间'
            T1.TRANS_AMT AS JYJE , --  09'交易金额'
            CASE WHEN T1.CD_TYPE ='1' --  '借'
                  AND T1.TRANTYPE2 ='J' --  发放 
                 THEN T1.TRANS_AMT
                 ELSE T2.LOAN_ACCT_BAL + T2.OD_LOAN_ACCT_BAL 
                  END AS ZHYE  , --  10'账户余额'  20250116
            T1.CURRENCY AS BZ  , --  11'币种'
            CASE WHEN t1.TRANTYPE2 ='J' THEN '01'   --   发放
                 WHEN t1.TRANTYPE2 ='K'  AND T7.LOAN_NUM IS NOT NULL THEN '02'   --  担保代偿收回
                 WHEN t1.TRANTYPE2 ='K'  AND T7.LOAN_NUM IS NULL THEN '03'   --  非担保代偿收回
                 WHEN t1.TRANTYPE2 ='L' THEN '04'   --   收息
                 ELSE '05'   --   其它
                 END  AS XDJYLX,   --    12'信贷交易类型' 
            TRIM(T1.GL_ITEM_CODE) AS KMBH  , --  13'科目ID'
            NVL(T4.Gl_Cd_Name,Q.Gl_Cd_Name) AS MXKMMC , --  14'科目名称'
            CASE
             WHEN T1.CD_TYPE = '1' THEN '01' -- '借'
             WHEN T1.CD_TYPE = '2' THEN '02' -- '贷'
            END AS JYJDBZ,  --  15'借贷标识'
            -- CASE WHEN T2.DRAWDOWN_TYPE = 'B' THEN '1'
            -- ELSE 0   
            -- END AS stzf  , --  16'受托支付标识'
            CASE 
             WHEN t2.DRAWDOWN_TYPE = 'A' THEN '01' -- 自主支付
             WHEN t2.DRAWDOWN_TYPE = 'B' THEN '02' -- 受托支付
             WHEN t2.DRAWDOWN_TYPE = 'C' THEN '03' -- 自主支付
             WHEN T2.DRAWDOWN_TYPE IS NULL AND T1.GL_ITEM_CODE LIKE '1306%' THEN '01' -- 自主支付 [20250619][巴启威][JLBA202505280002][吴大为]：垫款科目，如果没有放款方式，默认为01-自主支付
            END  AS XDZJZFLX ,   -- 16 信贷资金支付类型
            NVL(NVL(NVL(AC.ACCT_NUM,T1.OPPO_ACCT_NUM),T2.LOAN_ACCT_NUM),T2.LOAN_FHZ_NUM) AS dfzh , --  17'对方账号'
            NVL(T1.OPPO_ACCT_NAM, A.CUST_NAM) AS DFHM , --  18'对方户名'
            CASE
             WHEN T2.ORG_NUM = '009808' THEN '313241066661'
             ELSE NVL(T1.OPPO_ORG_NUM, T3.BANK_CD)
            END AS DFXH   , --  19'对方账号行号'
            CASE WHEN T2.ORG_NUM = '009808' THEN '吉林银行股份有限公司'
            ELSE NVL(T1.OPPO_ORG_NAM, T3.ORG_NAM)
            END AS DFXM  , --  20'对方行名'
            CASE WHEN (T1.TRAN_STS IN ('B','C','D')  or T1.TRANS_AMT < 0) THEN '02'  --   '冲补抹'   -- [20250415][姜俐锋][JLBA202502210009][吴大为]: 吴大为确认交易金额负数时为冲补抹
                 WHEN T1.TRAN_STS='A' THEN '01' -- '正常'
            ELSE '01' -- '正常'
            END AS CBMBZ  , --  21'冲补抹标识'
            NVL(T2.JBYG_ID,T2.EMP_ID) AS JBYG  , --  22'经办员工ID'
            NVL(T2.SQY_ID,T2.SPYG_ID) AS SQYG  , --  23'授权员工ID'
            CASE WHEN T1.CHANNEL = '01' THEN '01'  -- '柜面'
                 WHEN T1.CHANNEL = '02' THEN '05'  -- '网银'
                 WHEN T1.CHANNEL = '04' THEN '02'  -- 'ATM'
                 WHEN T1.CHANNEL = '05' THEN '04'  -- 'POS'
                 WHEN T1.CHANNEL = '06' THEN '06'  -- '手机银行'
                 WHEN T1.CHANNEL = '07' THEN '07'  -- '第三方支付'
                 WHEN T1.CHANNEL = '08' THEN '03'  -- 'VTM'
                 WHEN T1.CHANNEL = '9999' THEN '00' -- '其他' 
                 ELSE '00' -- '其他' 
            END AS JYQD , --  24'交易渠道'
           T1.AGENT_NAME_A AS DBRXM , --  25'代办人姓名'
           G.GB_CODE_NAME  , --  26'代办人证件类型'
           T1.AGENT_IDENTIFCATION_A AS DBRZJHM  , --  27'代办人证件号码'
           CASE
             WHEN T1.TRANS_FLG = '0' THEN '01' -- '现'
             WHEN T1.TRANS_FLG = '1' THEN '02' -- '转'
           END AS XZBZ , --  28'现转标识'
           CASE
             WHEN T1.SUMMARY IS NULL THEN
              (CASE
                WHEN T1.CD_TYPE = '1' THEN
                 '放款'
                WHEN T1.CD_TYPE = '2' THEN
                 '还款'
              END)
             ELSE
              NVL(M.GB_CODE_NAME,T1.SUMMARY)
           END AS ZY  , --  29'摘要'
           TO_CHAR(P_DATE,'YYYY-MM-DD'), --  30'采集日期'
           TO_CHAR(P_DATE,'YYYY-MM-DD'),
           T1.ORG_NUM ,
           CASE  
           WHEN T2.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
           WHEN T2.DEPARTMENTD ='公司金融' OR SUBSTR(T2.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
           WHEN T2.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
           WHEN T2.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
           WHEN SUBSTR(T2.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
           WHEN SUBSTR(T2.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
           ELSE   '009804'
           END AS TX ,
           'GR'
           FROM SMTMODS.L_TRAN_TX T1  -- 交易信息表
     INNER JOIN SMTMODS.L_ACCT_LOAN T2  -- 贷款借据信息表
        ON T1.ACCOUNT_CODE = T2.LOAN_NUM
       AND T2.DATA_DATE = I_DATE
       AND T2.ITEM_CD NOT LIKE '130302%'  -- 公司贷款
     INNER JOIN SMTMODS.L_CUST_P  B  -- 个人客户信息表
        ON T1.CUST_ID = B.CUST_ID
       AND B.DATA_DATE = I_DATE
     LEFT JOIN SMTMODS.L_CUST_ALL A  -- 客户信息表
        ON T2.CUST_ID = A.CUST_ID
       AND A.DATA_DATE = I_DATE
      LEFT JOIN VIEW_L_PUBL_ORG_BRA T3  -- 机构表
        ON T2.ORG_NUM = T3.ORG_NUM
       AND T3.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_FINA_INNER T4  -- 内部科目对照表
        ON TRIM(T1.GL_ITEM_CODE) = T4.STAT_SUB_NUM
       AND T1.ORG_NUM=T4.ORG_NUM
       AND T4.DATA_DATE = I_DATE
     LEFT JOIN SMTMODS.L_FINA_INNER Q  -- 内部科目对照表
        ON TRIM(T1.GL_ITEM_CODE) = Q.STAT_SUB_NUM  -- 20211012日修改：添加trim函数删除空格
       AND Q.ORG_NUM='990000'
       AND Q.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT T6  -- 贷款合同信息表
        ON T2.ACCT_NUM = T6.CONTRACT_NUM
       AND T6.DATA_DATE = I_DATE
      LEFT JOIN ACCT_CARD AC
        ON SUBSTR(T1.OPPO_ACCT_NUM,0,19) = AC.TYPE_ID
       AND AC.DATA_DATE = I_DATE 
      LEFT JOIN  SMTMODS.L_ACCT_LOAN_ENTRUST F  -- 委托贷款补充信息
        ON T2.LOAN_NUM = F.LOAN_NUM
       AND F.DATA_DATE = I_DATE
      LEFT JOIN M_DICT_CODETABLE M
        ON T1.TRAN_CODE=M.L_CODE
       AND M.L_CODE_TABLE_CODE='TRANS_CODE'   
      LEFT JOIN M_DICT_CODETABLE G
        ON T1.AGENT_IDENTI_TYPE_A = G.L_CODE
       AND G.L_CODE_TABLE_CODE='C0001' 
      LEFT JOIN (SELECT DISTINCT  TT.PAY_TYPE,TT.LOAN_NUM FROM   SMTMODS.L_TRAN_LOAN_PAYM TT WHERE TT.DATA_DATE = I_DATE AND TT.PAY_TYPE ='07') T7
        ON T1.ACCOUNT_CODE=T7.LOAN_NUM
     WHERE T1.DATA_DATE= I_DATE
       AND US_AGE <>  '日终计提'   --  LINSHI 
       AND (CASE
             WHEN T1.TRAN_STS <> 'B' 
              AND T1.TRAN_STS <> 'D'
	      AND T1.TRANS_AMT > 0  -- 正常和补账使交易金额不能<=0
             THEN 1
             WHEN T1.TRAN_STS = 'B' THEN 1
             WHEN T1.TRAN_STS = 'D' THEN 1
             ELSE 0
           END) = 1
    AND t1.PAYMENT_PROPERTY is null  -- 交易过滤掉支付使用数据
    AND NVL(T6.PROD_NAME,'##') NOT IN ('个人遗留贷款无本产品','公司遗留贷款无本产品')  -- MODIFY JIANGHUAIFU 剔除无本有息历史数据
    AND t1.PAYMENT_ORDER is null   -- 交易过滤掉支付使用数据
    AND T1.GL_ITEM_CODE IS NOT NULL
    AND T1.GL_ITEM_CODE NOT LIKE '7120%'
    AND (T2.ACCT_STS <> '3'  
              OR T2.LOAN_ACCT_BAL > 0   
              OR  T2.FINISH_DT  = I_DATE 
              OR (T2.INTERNET_LOAN_FLG = 'Y' AND T2.FINISH_DT= TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD')-1,'YYYYMMDD'))   -- 互联网贷款数据晚一天下发，上月末数据当月取
              OR (T2.CP_ID='DK001000100041' AND T2.FINISH_DT= TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD')-1,'YYYYMMDD')) -- [20250929][姜俐锋][JLBA202507300010][信贷新增产品]: 同网贷部分数据处理方式
              )
    AND NOT EXISTS(SELECT A.LOAN_NUM,A.WRITE_OFF_DATE -- 核销日期
                FROM SMTMODS.L_ACCT_WRITE_OFF A -- 贷款核销
                WHERE A.DATA_DATE = I_DATE
                  AND A.WRITE_OFF_DATE < I_DATE 
                  AND A.LOAN_NUM = T2.LOAN_NUM )
    AND NVL(T6.PROD_NAME,'##') NOT IN ('个人遗留贷款无本产品','公司遗留贷款无本产品') -- 剔除无本有息历史数据   
    AND (T2.LOAN_STOCKEN_DATE IS NULL OR T2.LOAN_STOCKEN_DATE = I_DATE)   -- ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
        ; 
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

