DROP Procedure IF EXISTS `PROC_BSP_T_7_1_KHCKZHJY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_7_1_KHCKZHJY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN

  /******
      程序名称  ：客户存款账户交易
      程序功能  ：加工客户存款账户交易
      目标表：T_7_1
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
		-- JLBA202411070004_关于一表通监管数据报送系统修改逻辑的需求 20241212
        -- JLBA202412200001_关于一表通监管数据报送系统修改逻辑及转EAST脚本的需求_20250116
       /* 需求编号：JLBA202504060003 上线日期： 20250513，修改人：狄家卉，提出人：吴大为    关于一表通监管数据报送系统、EAST报送系统修改取数逻辑的需求*/
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
	SET P_PROC_NAME = 'PROC_BSP_T_7_1_KHCKZHJY';
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
	
	DELETE FROM ybt_datacore.T_7_1 WHERE G010032 = TO_CHAR(P_DATE,'YYYY-MM-DD') ;
	
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
 INSERT  INTO ybt_datacore.T_7_1  
 (
G010001 , -- 01'交易ID'
G010002 , -- 02'分户账号'
G010003 , -- 03'客户ID'
G010004 , -- 04'交易机构ID'
G010005 , -- 05'核心交易日期'
G010006 , -- 06'核心交易时间'
G010007 , -- 07'交易金额'
G010008 , -- 08'账户余额'
G010009 , -- 09'币种'
G010010 , -- 10'账号交易类型'
G010011 , -- 11'科目ID'
G010012 , -- 12'科目名称'
G010013 , -- 13'现转标识'
G010014 , -- 14'借贷标识'
G010015 , -- 15'对方账号'
G010016 , -- 16'对方户名'
G010017 , -- 17'对方账号行号'
G010018 , -- 18'对方行名'
G010019 , -- 19'交易摘要'
G010020 , -- 20'冲补抹标识'
G010033 , -- 21'钞汇类别'
G010021 , -- 22'交易渠道'
G010022 , -- 23'交易终端ID'
G010023 , -- 24'IP地址'
G010024 , -- 25'MAC地址'
G010025 , -- 26'外部账号（交易介质号）'
G010026 , -- 27'代办人姓名'
G010027 , -- 28'代办人证件类型'
G010028 , -- 29'代办人证件号码'
G010029 , -- 30'经办员工ID'
G010030 , -- 31'授权员工ID'
G010031 , -- 32'客户备注'
G010032 ,  -- 33'采集日期'	
DIS_DATA_DATE,
DIS_BANK_ID,   -- 机构号
DEPARTMENT_ID ,      -- 业务条线
G010034 -- '银行备注'
)


SELECT  SUBSTR (T1.KEY_TRANS_NO || trim (t1.REFERENCE_NUM) || T1.SERIAL_NO  ,1,60) AS JYXLH , -- 01交易ID
        T2.ACCT_NUM  , -- 02分户账号
        T2.CUST_ID ,   -- 03客户ID
        ORG.ORG_ID ,   -- 04交易机构ID
        TO_CHAR(TO_DATE(T1.TX_DT,'YYYYMMDD'),'YYYY-MM-DD')   ,    -- 05核心交易日期
        SUBSTR(T1.TRANS_TIME, 1, 2) || ':' || SUBSTR(T1.TRANS_TIME, 3, 2) || ':' || SUBSTR(T1.TRANS_TIME, 5, 2) ,  -- 06核心交易时间       
        T1.TRANS_AMT  , -- 07交易金额
        NVL(T1.TRANS_BAL,0)  , -- 08账户余额
        T1.CURRENCY   , -- 09币种
        CASE  WHEN T1.TRANTYPE2 = 'A' THEN '01'  -- 转账
              WHEN T1.TRANTYPE2 = 'B' THEN '02'  -- 取现
          	  WHEN T1.TRANTYPE2 = 'C' THEN '03'  -- 存现
          	  WHEN T1.TRANTYPE2 = 'D' THEN '04'  -- 消费
          	  WHEN T1.TRANTYPE2 = 'E' THEN '05'  -- 代发
			  WHEN T1.TRANTYPE2 = 'F' THEN '06'  -- 代扣
			  WHEN T1.TRANTYPE2 = 'G' THEN '07'  -- 代缴
			  WHEN T1.TRANTYPE2 = 'H' THEN '08'  -- 结息
			  WHEN T1.TRANTYPE2 = 'I' THEN '09'  -- 批量交易
          	  WHEN T1.TRANTYPE2 = 'J' THEN '10'  -- 贷款发放
          	  WHEN T1.TRANTYPE2 = 'K' THEN '11'  -- 还款-还本
          	  WHEN T1.TRANTYPE2 = 'L' THEN '12'  -- 还款-还息
          	  WHEN T1.TRANTYPE2 = 'M' THEN '13'  -- 银证转账
          	  WHEN T1.TRANTYPE2 = 'N' THEN '14'  -- 投资理财
          	  ELSE '15' -- 其他
          END            , -- 10账号交易类型 
        T1.GL_ITEM_CODE , -- 11科目ID
        T4.GL_CD_NAME ,   -- 12科目名称     
       	CASE WHEN T1.TRANS_FLG = '0' /*OR T1.TRANTYPE2 = 'B'*/ THEN '01' -- 现金     一表通转EAST 20240614 LMH ,0705_LHY
       	     WHEN T1.TRANTYPE2 = 'B' THEN '01' -- JLBA202411070004 20241212
       	     WHEN T1.TRANS_FLG = '1' THEN '02' -- 转账
       	     END                                        ,   -- 13现转标志
        CASE WHEN T1.CD_TYPE = '1' THEN '01' -- 借
             WHEN T1.CD_TYPE = '2' THEN '02' -- 贷   
             WHEN T1.CD_TYPE = '3' THEN '03' -- 借贷并列
             END                                        ,   -- 14借贷标志	
        CASE
         WHEN T1.TRANTYPE2 = 'B' then NULL  					-- 一表通转EAST 20240614 LMH
         WHEN T1.TRAN_CODE like 'FEE%' THEN T1.GL_ITEM_CODE    -- [20250513][狄家卉][JLBA202504060003][吴大为]: 修改收取手续费业务规则，取核心系统中交易代码标识为“手续费”，对方账号取该业务手续费收入对应科目
         WHEN T1.OPPO_ACCT_NUM IS NOT NULL THEN T1.OPPO_ACCT_NUM
         WHEN T1.SUMMARY = '柜面IC卡转账圈提' THEN REPLACE(T6.TYPE_ID,'#','')
         WHEN TRIM(T1.TRANTYPE2) IN ('H','I','Z') THEN T2.O_ACCT_NUM
         WHEN T1.SUMMARY LIKE '%手续费%' THEN T2.O_ACCT_NUM
         WHEN T1.SUMMARY LIKE '%工本费%' THEN T2.O_ACCT_NUM
         WHEN T1.SUMMARY IN ('保管箱租金','存单挂失','存折挂失','借记卡换卡','借记卡境外ATM取款','同城ATM跨行转账','异地ATM跨行转账') THEN T2.O_ACCT_NUM
         ELSE T1.OPPO_ACCT_NUM
        END                                             , -- 15 对方账号
       CASE
        WHEN T1.TRANTYPE2 = 'B' THEN NULL 				-- 一表通转EAST 20240614 LMH
        WHEN T1.TRAN_CODE like 'FEE%' THEN T4.GL_CD_NAME    -- [20250513][狄家卉][JLBA202504060003][吴大为]: 修改收取手续费业务规则，取核心系统中交易代码标识为“手续费”，对方账号取该业务手续费收入对应科目名称
        WHEN T1.OPPO_ACCT_NAM IS NOT NULL THEN REPLACE(T1.OPPO_ACCT_NAM,'？','')
        WHEN T1.SUMMARY = '柜面IC卡转账圈提' THEN T2.ACCT_NAM
        WHEN TRIM(T1.TRANTYPE2) IN ('H','I','Z') THEN T2.ACCT_NAM
        WHEN T1.SUMMARY LIKE '%手续费%' THEN T2.ACCT_NAM
        WHEN T1.SUMMARY LIKE '%工本费%' THEN T2.ACCT_NAM
        WHEN T1.SUMMARY IN ('保管箱租金','存单挂失','存折挂失','借记卡换卡','借记卡境外ATM取款','同城ATM跨行转账','异地ATM跨行转账') THEN T2.ACCT_NAM
        ELSE REPLACE(T1.OPPO_ACCT_NAM,'？','')
       END                                                , -- 16 对方户名
      CASE
       WHEN T1.TRANTYPE2 = 'B' then	null			 -- 一表通转EAST 20240614 LMH
       WHEN T1.TRAN_CODE like 'FEE%' THEN '313241010300'    -- [20250513][狄家卉][JLBA202504060003][吴大为]: 修改收取手续费业务规则，取核心系统中交易代码标识为“手续费”，写成固定'313241010300'
       WHEN T1.OPPO_ORG_NUM IS NOT NULL THEN SUBSTR(T1.OPPO_ORG_NUM,1,12)
       WHEN T1.SUMMARY = '柜面IC卡转账圈提' THEN '313241066661'
       WHEN TRIM(T1.TRANTYPE2) IN ('H','Z','I') THEN T5.BANK_CD
       WHEN T1.SUMMARY LIKE '%手续费%' THEN T5.BANK_CD
       WHEN T1.SUMMARY LIKE '%工本费%' THEN T5.BANK_CD
       WHEN T1.SUMMARY IN ('保管箱租金','存单挂失','存折挂失','借记卡换卡','借记卡境外ATM取款','同城ATM跨行转账','异地ATM跨行转账') THEN T5.BANK_CD
        ELSE SUBSTR(T1.OPPO_ORG_NUM,1,12)
      END                                               ,-- 17 对方账号行号
      CASE
       WHEN T1.TRANTYPE2 = 'B' then NULL                  -- 一表通转EAST 20240614 LMH
       WHEN T1.TRAN_CODE like 'FEE%' THEN '吉林银行股份有限公司长春瑞祥支行'    -- [20250513][狄家卉][JLBA202504060003][吴大为]: 修改收取手续费业务规则，取核心系统中交易代码标识为“手续费”，写成固定'吉林银行股份有限公司长春瑞祥支行'
       WHEN T1.OPPO_ORG_NAM IS NOT NULL THEN substr(T1.OPPO_ORG_NAM,1,100)
       WHEN T1.SUMMARY = '柜面IC卡转账圈提' THEN '吉林银行股份有限公司'
       WHEN TRIM(T1.TRANTYPE2) IN ('H','Z','I') THEN T5.ORG_NAM
       WHEN T1.SUMMARY LIKE '%手续费%' THEN T5.ORG_NAM
       WHEN T1.SUMMARY LIKE '%工本费%' THEN T5.ORG_NAM
       WHEN T1.SUMMARY IN ('保管箱租金','存单挂失','存折挂失','借记卡换卡','借记卡境外ATM取款','同城ATM跨行转账','异地ATM跨行转账') THEN T5.ORG_NAM
        ELSE substr(T1.OPPO_ORG_NAM,1,100)
     END                                              , -- 18 对方行名
    
     CASE
       WHEN (T1.SUMMARY IS NULL OR T1.SUMMARY IN ('空', '无')) AND
            T1.TRANS_FLG = '1' AND T1.CD_TYPE = '2' THEN  '转存'
       WHEN (T1.SUMMARY IS NULL OR T1.SUMMARY IN ('空', '无')) AND
            T1.TRANS_FLG = '1' AND NVL(T1.CD_TYPE, '1') = '1' THEN '转取'
       WHEN (T1.SUMMARY IS NULL OR T1.SUMMARY IN ('空', '无')) AND
            NVL(T1.TRANS_FLG, '0') = '0' AND T1.CD_TYPE = '2' THEN '现存'
       WHEN (T1.SUMMARY IS NULL OR T1.SUMMARY IN ('空', '无')) AND
            NVL(T1.TRANS_FLG, '0') = '0' AND NVL(T1.CD_TYPE, '1') = '1' THEN '现取'
       ELSE T1.SUMMARY
     END                                            ,  -- 19交易摘要
       CASE
       WHEN T1.TRAN_STS = 'A' THEN
        '01'
       WHEN T1.TRAN_STS IN ('B', 'C', 'D') THEN
        '02'
       ELSE
        '01'
     END                                              , -- 20冲补抹标志
     CASE WHEN T2.ACCOUNT_CATA_FLG = '2' THEN '01' -- 钞
          WHEN T2.ACCOUNT_CATA_FLG = '3' THEN '02' -- 汇
          WHEN T2.ACCOUNT_CATA_FLG = '4' THEN '03' -- 可钞可汇
          END                                         , -- 21钞汇类别
     CASE  WHEN T1.CHANNEL = '01' THEN '01' -- '柜面'
	       WHEN T1.CHANNEL = '04' and t7.ORG_NUM not like '5%' and t7.ORG_NUM not like '6%' and t7.ORG_NUM not like '7%'   THEN '02' -- 'ATM' 
	       WHEN T1.CHANNEL = '08' THEN '03' -- 'VTM'
           WHEN T1.CHANNEL = '05' THEN '04' -- 'POS'	   
           WHEN T1.CHANNEL = '02' THEN '05' -- '网银'
           WHEN T1.CHANNEL = '06' THEN '06' -- '手机银行'
           WHEN T1.CHANNEL = '07' THEN '07' -- '第三方支付' 
           WHEN T1.CHANNEL = '13' THEN '08' -- '银联交易'
           ELSE '00' -- '其他'
           END                                       , -- 22交易渠道
    case when T1.CHANNEL = '04' then t7.EQUIPMENT_NBR  -- -- 2.0 zdsj h  
           else T1.JYZD_ID
           end                                     , -- 23交易终端ID  
     SUBSTR(T1.IP_ADDRESS,1,39)                      , -- 24 IP地址
     SUBSTR(T1.MAC_ADDRESS,1,12)                     , -- 25 MAC地址
     -- NVL(REPLACE(T6.TYPE_ID,'#',''),T2.O_ACCT_NUM), -- 26 外部账号（交易介质号）           一表通转EAST
     CASE WHEN REPLACE(T6.TYPE_ID,'#','') <> '' then T6.TYPE_ID
          ELSE T2.O_ACCT_NUM
     END,                                            -- 26 外部账号（交易介质号）           一表通转EAST 20240618 LMH
     T1.AGENT_NAME_A                                 , -- 27 代办人姓名
     -- M1.GB_CODE                         , -- 27 代办人姓名  20250116
     M.GB_CODE                          , --  28 代办人证件类别
     T1.AGENT_IDENTIFCATION_A           ,  -- 29 代办人证件号码
     CASE WHEN /*REGEXP_LIKE(T1.OP_TELLER_NUM,'^[0-9]+$') AND */ LENGTH(T1.OP_TELLER_NUM)= 6 and T1.CHANNEL <> '99' THEN T1.OP_TELLER_NUM
          ELSE '自动'
           END                          ,  -- 30 经办员工ID   新加条件T1.CHANNEL <> '99' 0619_LHY
     T1.AU_TELLER_NUM                   ,  -- 31 授权员工ID
     T1.SUMMARY                         ,  -- 32 客户备注   
     TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')       ,  -- 33 采集日期
     TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')       ,     
     T1.ORG_NUM,
     CASE WHEN T2.TX = '个人金融部' THEN '009821'
	      WHEN T2.TX = '公司金融部' THEN '0098JR'
	      WHEN T2.TX = '机构金融部' THEN '0098JYB'
	  ELSE '009820'
	  END,
	  --       NULL -- '银行备注'
	 CASE WHEN t1.APPT_FLAG = 'Y' THEN '预约转账无IP和MAC地址'
     ELSE  NULL
     END AS yhbz -- '银行备注' -- JLBA202411070004 20241212        
  FROM SMTMODS.L_TRAN_TX T1 -- 流水表，主表
  
     INNER JOIN (SELECT DISTINCT A.ACCT_NUM,A.O_ACCT_NUM,A.ACCT_NAM,A.CUST_ID,A.ACCOUNT_CATA_FLG,A.TX FROM SMTMODS.L_ACCT_DEPOSIT A WHERE a.DATA_DATE = I_DATE
                  AND (a.ACCT_CLDATE >= I_DATE
 		     OR ( a.ACCT_CLDATE IS NULL AND  a.ACCT_BALANCE > 0 )
 		     OR a.ACCT_BALANCE > 0)   -- 20240724 ZJK UPDATE 出现一笔销户日期为空 余额为0的数据
	   AND SUBSTR(a.ORG_NUM,1,1) NOT IN ('5','6','7')	     
	   AND  SUBSTR(a.GL_ITEM_CODE,1,4) IN ('2011','2012','2013','2014','2010') -- [20251016]:财政性存款新科目 2010
	   AND SUBSTR(a.GL_ITEM_CODE,1,6) <>  '224101'  -- 久悬 
	   AND a.GL_ITEM_CODE IS NOT NULL
	   AND SUBSTR(a.ACCT_STS,1,3)<>'E01' -- EAST 表间校验
	   AND a.GL_ITEM_CODE NOT IN ('20110301','20110302','20110303','20110501','20110502','20110111') -- 0408 大为哥剔除
	   AND SUBSTR(a.GL_ITEM_CODE,1,4) NOT IN ('3010','3020','2005')  --   周敬坤 JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求  提出2005 科目  对应201105科目
	   AND a.GL_ITEM_CODE NOT IN ('20120101','20120102','20120103','20120104','20120105','20120107','20120108','20120109','20120110','20120111','20120201','20120202','20120203','20120205','20120206','20120207','20120208','20120209') -- 0418 按照大为哥口径剔除
 		     ) T2
        ON T1.ACCOUNT_CODE = T2.ACCT_NUM  
	   
     LEFT JOIN SMTMODS.L_CUST_ALL T3 
        ON T2.CUST_ID = T3.CUST_ID
       AND T3.DATA_DATE = I_DATE

      LEFT JOIN SMTMODS.L_FINA_INNER T4 -- 内部科目表
        ON T1.GL_ITEM_CODE = T4.STAT_SUB_NUM
       AND T1.ORG_NUM = T4.ORG_NUM
       AND T4.DATA_DATE = I_DATE

      LEFT JOIN SMTMODS.L_PUBL_ORG_BRA T5 -- 机构表
        ON T1.ORG_NUM = T5.ORG_NUM
       AND T5.DATA_DATE = I_DATE

      LEFT JOIN (SELECT T.*
                      ,ROW_NUMBER() OVER(PARTITION BY T.ACCT_NUM ORDER BY T.TYPE_ID DESC) AS NUM
                FROM  SMTMODS.L_ACCT_DEPOSIT_SUB T
                WHERE DATA_DATE = I_DATE
                ) T6
      ON T2.ACCT_NUM = T6.ACCT_NUM
      AND T6.NUM = 1
     
      LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
        ON T1.ORG_NUM = ORG.ORG_NUM
        AND ORG.DATA_DATE = I_DATE
      LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M
             ON T1.AGENT_IDENTI_TYPE_A = M.L_CODE
            AND M.L_CODE_TABLE_CODE = 'C0001'
      LEFT join (select * from SMTMODS.L_PUBL_EQUIPMENT t
           where t.data_date=I_DATE 
           and T.EQUIPMENT_TYP in ('A','H','G')
           and T.SFSTJJ='Y' -- 2.0 ZDSJ H
           and t.ORG_NUM not like '5%' 
           and t.ORG_NUM not like '6%' 
           and t.ORG_NUM not like '7%' -- 取自助机具表设备编号 去掉村镇的自助机具    大为哥确认
 ) t7   
      on T1.JYZD_ID= substr(t7.EQUIPMENT_NBR,-8)  -- 终端一体化和柜面的后八位一致
   
      LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M1    -- 20250116 增加对方客户类型
        ON T1.AGENT_IDENTI_TYPE_A = M1.L_CODE
       AND M1.L_CODE_TABLE_CODE = 'C0001'
      WHERE T1.DATA_DATE = I_DATE
       AND T1.TRANS_AMT <> 0  
       AND T1.PAYMENT_PROPERTY IS NULL -- 交易过滤掉支付使用数据
       AND T1.PAYMENT_ORDER IS NULL -- 交易过滤掉支付使用数据
       AND (T1.ZHZT <> '2' OR T1.ZHZT IS NULL)
       AND T1.TRAN_CODE NOT IN ('4589','4586')  -- 理财产品码值 产生交易但是余额不变动
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

