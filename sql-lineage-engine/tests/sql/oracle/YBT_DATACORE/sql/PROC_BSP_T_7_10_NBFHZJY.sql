DROP Procedure IF EXISTS `PROC_BSP_T_7_10_NBFHZJY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_7_10_NBFHZJY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN

  /******
      程序名称  ：内部分户账交易
      程序功能  ：加工内部分户账交易
      目标表：T_7_10
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
/* 需求编号：JLBA202504060003 上线日期：20250513,修改人：狄家卉，提出人：吴大为    关于一表通监管数据报送系统、EAST报送系统修改取数逻辑的需求*/
-- 需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求   上线日期：20250513  修改人：周敬坤   提出人：吴大为 新增2005、2006、2007、2008、2009、2010科目：其中2005对应以前的201105科目、2006、2007对应以前的201104、201106，此三个科目为财政性存款；新增科目2008、2009，财政性存款；2010对应201107，国库定期存款 

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
	SET P_PROC_NAME = 'PROC_BSP_T_7_10_NBFHZJY';
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
	
	DELETE FROM ybt_datacore.T_7_10 WHERE G100028 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ;
	
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
	DROP TABLE IF EXISTS ACCT_CARD;
    CREATE TABLE ACCT_CARD AS 
    SELECT 
    XX.DATA_DATE, 
    XX.ACCT_NUM, 
    XX.TYPE_ID, 
    ROW_NUMBER() OVER(PARTITION BY XX.TYPE_ID ORDER BY XX.ACCT_NUM) AS NUM
    FROM SMTMODS.L_ACCT_DEPOSIT_SUB XX
    WHERE XX.DATA_DATE = I_DATE  ;
    COMMIT;     
    
    delete from ACCT ;
    INSERT INTO ACCT(ORG_NUM,ACCT_NUM)
    SELECT ORG_NUM,ACCT_NUM FROM SMTMODS.L_ACCT_DEPOSIT WHERE DATA_DATE=I_DATE AND  (ACCT_TYPE<>'0602' OR ACCT_TYPE IS NULL);
    COMMIT;
    
    INSERT INTO ACCT(ORG_NUM,ACCT_NUM)
    SELECT ORG_NUM,ACCT_NUM FROM SMTMODS.L_ACCT_INNER WHERE DATA_DATE=I_DATE ;        
    COMMIT; 
    
    drop table if EXISTS ACCT_1;
    create table ACCT_1 as SELECT distinct ORG_NUM,ACCT_NUM FROM ACCT    ;      -- LHY
    COMMIT;
    
 INSERT INTO ybt_datacore.T_7_10
 (
       G100001    , -- 01 '交易ID'
       G100002    , -- 02 '分户账号'
       G100029    , -- 29 '机构ID'
       G100003    , -- 03 '核心交易日期'	
       G100004    , -- 04 '核心交易时间'
       G100005    , -- 05 '币种'
       G100006    , -- 06 '交易类型'
       G100007    , -- 07 '科目ID'
       G100008    , -- 08 '科目名称'
       G100009    , -- 09 '借贷标识'
       G100010    , -- 10 '交易金额'
       G100011    , -- 11 '利率'
       G100012    , -- 12 '借方余额'
       G100013    , -- 13 '贷方余额'
       G100014    , -- 14 '对方账号'
       G100015    , -- 15 '对方户名'
       G100016    , -- 16 '对方账号行号'
       G100017    , -- 17 '对方行名'
       G100018    , -- 18 '摘要'
       G100019    , -- 19 '交易渠道'
       G100020    , -- 20 '经办员工ID'
       G100021    , -- 21 '授权员工ID'
       G100022    , -- 22 '冲补抹标识'
       G100023    , -- 23 '对方科目ID'
       G100024    , -- 24 '对方科目名称'
       G100025    , -- 25 '现转标识'
       G100026    , -- 26 '进账日期'
       G100027    , -- 27 '销账日期'
       G100028    , -- 28 '采集日期'
       DIS_DATA_DATE,
       DIS_BANK_ID,
       DEPARTMENT_ID

)
  SELECT 
         SUBSTR(T1.TX_NUM || T1.REFERENCE_SUB_NUM || T1.SUB_NUM,1,60)                                      , -- 01 '交易ID'
         T1.ACCT_NUM                                                                                       , -- 02 '分户账号'
         ORG.ORG_ID                                                                                        , -- 29 '机构ID'
         TO_CHAR(TO_DATE(T1.TX_DATE,'YYYYMMDD'),'YYYY-MM-DD')                                              , -- 03 '核心交易日期'	
          SUBSTR(T1.TX_TIME, 1, 2) || ':' || SUBSTR(T1.TX_TIME, 3, 2) || ':' || SUBSTR(T1.TX_TIME, 5, 2)   , -- 04 '核心交易时间'
         T1.CURR_CD                                                                                        , -- 05 '币种'
         CASE WHEN T1.TX_TYPE = 'A' THEN '01'  -- 转账
              WHEN T1.TX_TYPE = 'B' THEN '02'  -- 取现
          	  WHEN T1.TX_TYPE = 'C' THEN '03'  -- 存现
          	  WHEN T1.TX_TYPE = 'D' THEN '04'  -- 消费
          	  WHEN T1.TX_TYPE IN ('E','G','I') THEN '05' -- 批量业务    
          	  WHEN T1.TX_TYPE = 'F' THEN '06'  -- 代扣  将F单独拿出来 新增06 LHY_0619
          	  WHEN T1.TX_TYPE = 'J' THEN '10'  -- 贷款发放   06改为10 LHY_0619
          	  WHEN T1.TX_TYPE = 'K' THEN '07'  -- 还款-还本
          	  WHEN T1.TX_TYPE = 'L' THEN '08'  -- 还款-还息
          	  WHEN T1.TX_TYPE = 'M' THEN '09'  -- 银证转账
          	  WHEN T1.TX_TYPE = 'N' THEN '10'  -- 投资理财
          	  ELSE '11' 
          END   as jylx                                                                                 , -- 06 '交易类型'
          T1.ITEM_ID                                                                                    , -- 07 '科目ID'
          T3.GL_CD_NAME                                                                                 , -- 08 '科目名称' 
         CASE WHEN T1.PAYMENT_PROPERTY = '1' THEN '01' -- '借'
              WHEN T1.PAYMENT_PROPERTY = '2' THEN '02' -- '贷'       
            END   as jdbs                                                                               , -- 09 '借贷标识'
         ABS(T1.TX_AMT)                                                                                 , -- 10 '交易金额'
         NVL(T2.RATE,0)                                                                                 , -- 11 '利率'
         ABS(T1.DEBIT_BAL)                                                                              , -- 12 '借方余额'
         T1.CREDIT_BAL                                                                                  , -- 13 '贷方余额'
         CASE WHEN T5.KEY_TRANS_NO IS NOT NULL THEN T3.STAT_SUB_NUM    -- [20250513][狄家卉][JLBA202504060003][吴大为]: 修改收取手续费业务规则，取核心系统中交易代码标识为“手续费”，对方账号取该业务手续费收入对应科目
              ELSE NVL(AC.ACCT_NUM,T1.OPPO_ACCT_NUM) END AS G100014                                     , -- 14 '对方账号' 
         CASE WHEN T5.KEY_TRANS_NO IS NOT NULL THEN T3.GL_CD_NAME    -- [20250513][狄家卉][JLBA202504060003][吴大为]: 修改收取手续费业务规则，取核心系统中交易代码标识为“手续费”，对方账号取该业务手续费收入对应科目名称
              ELSE SUBSTR(T1.OPPO_ACCT_NAM,1,100) END AS G100015                                        , -- 15 '对方户名'
         CASE WHEN T5.KEY_TRANS_NO IS NOT NULL THEN '313241010300'   -- [20250513][狄家卉][JLBA202504060003][吴大为]: 修改收取手续费业务规则，取核心系统中交易代码标识为“手续费”，写成固定'313241010300'
              ELSE T1.OPPO_ORG_NUM END  AS G100016                                                      , -- 16 '对方账号行号'
         CASE WHEN T5.KEY_TRANS_NO IS NOT NULL THEN '吉林银行股份有限公司长春瑞祥支行' -- [20250513][狄家卉][JLBA202504060003][吴大为]: 修改收取手续费业务规则，取核心系统中交易代码标识为“手续费”，写成固定'吉林银行股份有限公司长春瑞祥支行'
              ELSE T1.OPPO_ORG_NAM END  AS G100017                                                      , -- 17 '对方行名'
         T1.REMARK                                                                                      , -- 18 '摘要'
         CASE WHEN T1.CHANNEL = '01' THEN '01' -- '柜面'
              WHEN T1.CHANNEL = '04' THEN '02' -- 'ATM'
		      WHEN T1.CHANNEL = '08' THEN '03' -- 'VTM'
              WHEN T1.CHANNEL = '05' THEN '04' -- 'POS'
		      WHEN T1.CHANNEL = '02' THEN '05' -- '网银'
              WHEN T1.CHANNEL = '06' THEN '06' -- '手机银行'
              WHEN T1.CHANNEL = '07' THEN '07' -- '第三方支付' 
              WHEN T1.CHANNEL = '13' THEN '08' -- '银联交易'
              ELSE '00'  -- '其他'
           END                                                                                           , -- 19 '交易渠道'
         CASE WHEN T1.CHANNEL='01' THEN  DECODE(T1.OP_TELLER_NUM,'YW0001','自动',T1.OP_TELLER_NUM)
              ELSE '自动'  -- 20241227 YBT_JYG10-35
              END  AS JBYGID                                                                             , -- 20 '经办员工ID'  
         T1.AUTH_TELLER_CD                                                                               , -- 21 '授权员工ID'
         CASE WHEN T1.TRAN_STS = 'A' THEN '01' -- 正常
		      WHEN T1.TRAN_STS IN ('B','C','D') THEN '02' -- 冲补抹
			   END                                                                                          , -- 22 '冲补抹标识'
         CASE WHEN T2.ORG_NUM>='510000' 
               AND T2.ORG_NUM<'610000' 
               AND (Q1.ORG_NUM IS NOT null or Q2.ORG_NUM IS NOT null)
	           AND SUBSTR(T2.ORG_NUM,1,2)<>SUBSTR(NVL(Q1.ORG_NUM,Q2.ORG_NUM),1,2) THEN NULL  -- 账号是村镇,对方账号是非本村镇账号
	          WHEN NVL(Q1.ORG_NUM,Q2.ORG_NUM)>='510000' 
	           AND NVL(Q1.ORG_NUM,Q2.ORG_NUM)<'610000'
		       AND (T2.ORG_NUM<'510000' OR T2.ORG_NUM>'610000') THEN NULL    -- 账号是总行,对方账号是非总行账号
	          ELSE T1.OPPO_ITEM_ID
               END AS G100023                                                                            , -- 23 '对方科目ID'    EAST转换逻辑使用
         CASE WHEN T2.ORG_NUM>='510000' 
               AND T2.ORG_NUM<'610000'
               AND (Q1.ORG_NUM IS NOT null or Q2.ORG_NUM IS NOT null)
	           AND SUBSTR(T4.ORG_NUM,1,2)<>SUBSTR(NVL(Q1.ORG_NUM,Q2.ORG_NUM),1,2) THEN NULL  -- 账号是村镇,对方账号是非本村镇账号
	          WHEN NVL(Q1.ORG_NUM,Q2.ORG_NUM)>='510000' 
	           AND NVL(Q1.ORG_NUM,Q2.ORG_NUM)<'610000'  
		       AND (T2.ORG_NUM<'510000' OR T2.ORG_NUM>'610000') THEN NULL    -- 账号是总行,对方账号是非总行账号   
	          ELSE T4.GL_CD_NAME
               END AS G100024                                                                            , -- 24 '对方科目名称'    EAST转换逻辑使用  
         CASE WHEN T1.TRANS_FLG = '0' THEN '01' -- 现金
              WHEN T1.TRANS_FLG = '1' THEN '02' -- 转账
              END	  AS G100025,   --  25 '现转标识'  
         TO_CHAR(TO_DATE(T1.INPUT_DATE,'YYYYMMDD'),'YYYY-MM-DD')                                         , -- 26 '进账日期'
         CASE WHEN T1.CLOSE_DATE IS NULL AND T2.ACCT_STATE = 'N' THEN '9999-12-31'                             
              WHEN T1.CLOSE_DATE IS NULL THEN TO_CHAR(TO_DATE(T2.CLOSE_DATE,'YYYYMMDD'),'YYYY-MM-DD')
             ELSE TO_CHAR(TO_DATE(T1.CLOSE_DATE,'YYYYMMDD'),'YYYY-MM-DD')
             END                                                                                             , -- 27 '销账日期'
         TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')                                                                    ,  -- 28 '采集日期'	
         TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,
         T1.ORG_NUM,
         T1.ORG_NUM
         FROM SMTMODS.L_TRAN_ACCT_INNER_TX T1 -- 内部分户账明细记录
         INNER JOIN SMTMODS.L_ACCT_INNER T2
                 ON T1.ACCT_NUM = T2.ACCT_NUM
                AND T2.DATA_DATE = I_DATE
          LEFT JOIN SMTMODS.L_FINA_INNER T3 -- 取科目名称
                 ON T1.ITEM_ID = T3.STAT_SUB_NUM
                AND NVL(T1.ORG_NUM, '009801') = T3.ORG_NUM
                AND T3.DATA_DATE = I_DATE
		  LEFT JOIN SMTMODS.L_FINA_INNER T4 -- 取对方科目名称
                 ON T1.OPPO_ITEM_ID = T4.STAT_SUB_NUM
                AND NVL(T1.ORG_NUM, '009801') = T4.ORG_NUM
                AND T4.DATA_DATE = I_DATE 
          LEFT JOIN (select DATA_DATE,ACCT_NUM,TYPE_ID from ACCT_CARD where NUM = 1 ) AC  -- EAST转换逻辑使用 LHY
                 ON AC.TYPE_ID = T1.OPPO_ACCT_NUM
                AND AC.DATA_DATE = I_DATE     
          LEFT JOIN ACCT_1 Q1    -- EAST转换逻辑使用
                 ON AC.ACCT_NUM = Q1.ACCT_NUM  
          LEFT JOIN ACCT_1 Q2    -- EAST转换逻辑使用  LHY
                 ON T1.OPPO_ACCT_NUM = Q2.ACCT_NUM   
          LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
                 ON T1.ORG_NUM = ORG.ORG_NUM
                AND ORG.DATA_DATE = I_DATE     
          LEFT JOIN (SELECT DISTINCT KEY_TRANS_NO FROM SMTMODS.L_TRAN_TX WHERE TRAN_CODE LIKE 'FEE%'  AND DATA_DATE = I_DATE) T5 -- 交易信息表流水表
                 ON T1.TX_NUM = T5.KEY_TRANS_NO
              WHERE T1.DATA_DATE = I_DATE
                AND T1.INPUT_DATE <= I_DATE
                AND T1.ITEM_ID IS NOT NULL
                AND T1.ITEM_ID <> '20110501' -- 剔除待报解预算收入专户交易
                and t1.ITEM_ID <> '20050101' -- 周敬坤 JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求  提出2005 科目  对应201105科目  总账由  20110501- 20110504  迁入20050101
                AND NOT EXISTS (SELECT 1 FROM SMTMODS.L_PUBL_ORG_BRA X WHERE T2.ORG_NUM = X.ORG_NUM 
                                   AND X.ORG_NAM LIKE '%村镇%'
                                   AND X.DATA_DATE = I_DATE)
                AND T1.ACCT_NUM not in ('9019800217000015_1')  -- [2025-03-27] [周敬坤] [邮件需求][吴大为] 为重点指标数据不重复    内部账不报送信用卡溢缴款内部账账号
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
    select OI_RETCODE,'|',OI_REMESSAGE;
END $$

