DROP Procedure IF EXISTS `PROC_BSP_T_4_3_FHZXX` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_4_3_FHZXX"(IN I_DATE VARCHAR(8),
                                        OUT OI_RETCODE   INT,-- 返回code
                                        OUT OI_REMESSAGE VARCHAR -- 返回message
)
BEGIN
/******
      程序名称  ：分户账信息
      程序功能  ：加工分户账信息
      目标表：T_4_3
      源表  ：
      创建人  ：LZ
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
	 -- JLBA202412300003_关于一表通监管报送系统(同业金融部)分户账信息表等字段取值逻辑变更的需求_20250213
	  /* 需求编号：JLBA202502210009   上线日期：20250415，修改人：姜俐锋，提出人：吴大为
      /* 需求编号：JLBA202504060003 上线日期：20250513，修改人：狄家卉，提出人：吴大为    关于一表通监管数据报送系统、EAST报送系统修改取数逻辑的需求 */
	  /* JLBA202505280002 上线日期：2025-06-19，修改人：巴启威  提出人：吴大为  修改原因：因一表通校验问题发现的代码逻辑调整*/
	  /* JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
	  /* JLBA202507250003 上线日期：2025-09-09，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统修改取数逻辑的需求*/
      /*需求编号：JLBA202507300010 上线日期：2025-09-29，修改人：姜俐锋，提出人：信贷新增产品 修改原因：关于新一代信贷管理系统新增线上微贷板块的需求 */
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
   SET OI_REMESSAGE = P_DESCB;
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
	SET P_PROC_NAME = 'PROC_BSP_T_4_3_FHZXX';
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
	
	DELETE FROM ybt_datacore.T_4_3 WHERE D030015 = TO_CHAR(P_DATE,'YYYY-MM-DD');
	
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    

	
	#3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '存款分户账数据插入';
	
	INSERT  INTO ybt_datacore.T_4_3  (
   D030001,  -- 01.机构
   D030002,  -- 02.分户账号
   D030003,  -- 03.客户ID
   D030004,  -- 04.分户账名称
   D030005,  -- 05.分户账类型
   D030006,  -- 06.计息标识
   D030007,  -- 07.计息方式
   D030008,  -- 08.科目
   D030009,  -- 09.币种
   D030010,  -- 10.借贷标识
   D030016,  -- 11.钞汇类别
   D030017,  -- 12.内部账利率
   D030011,  -- 13.开户日期
   D030012,  -- 14.销户日期
   D030013,  -- 15.账户状态
   D030014,  -- 16.备注
   D030015,   -- 17.采集日期
   DIS_DATA_DATE,
   DIS_BANK_ID ,   -- 机构号
   DEPARTMENT_ID ,      -- 业务条线
   D030018,  -- 借方余额
   D030019   -- 贷方余额	    
  )
  SELECT
       CASE WHEN T1.GL_ITEM_CODE='20110111' THEN 'B0302H22201009803'
            ELSE ORG.ORG_ID
             END    AS D030001                    ,  -- 01.机构
	   T1.ACCT_NUM  AS D030002                    ,  -- 02.分户账号
	   T1.CUST_ID   AS D030003                     ,  -- 03.客户ID
	   T1.ACCT_NAM  AS D030004                    ,  -- 04.分户账名称
	   CASE WHEN T2.CUST_ID IS NULL OR T2.CUST_TYP = '3' OR T2.DEPOSIT_CUSTTYPE IN ('13','14') THEN '02' -- 个人
	        ELSE '01' -- 对公
        END AS D030005			                ,  -- 05.分户账类型 [JLBA202507250003][20250909][巴启威]:个体工商户对应的分户账类型，调整为个人
       CASE WHEN T1.GL_ITEM_CODE = '20110111' THEN '0' -- '否' 信用卡溢缴款不计息
	        WHEN (T1.ACCU_INT_FLG = 'N' OR NVL(T1.INT_RATE,0)= 0 ) THEN '0' -- 20250415 [20250415][姜俐锋][JLBA202502210009][吴大为]: 增加利率为0计息方式为否的判断
	        WHEN T1.ACCU_INT_FLG = 'Y' THEN '1' -- '是'
            END AS D030006                        ,  -- 06.计息标识
	   CASE WHEN T1.GL_ITEM_CODE = '20110111' THEN '06' -- 信用卡溢缴款
	        WHEN T1.JXFS IS NOT NULL THEN T1.JXFS
	        WHEN T1.GL_ITEM_CODE = '20110110' THEN '00' -- [20251028][巴启威][JLBA202509280009][吴大为]: 按照增利账户的计息方式,00-其他
             END  AS D030007                     ,  -- 07.计息方式
	   T1.GL_ITEM_CODE  AS D030008               ,  -- 08.科目
	   T1.CURR_CD  AS D030009                    ,  -- 09.币种
	   CASE WHEN T1.GL_ITEM_CODE = '20110111' THEN '01' -- 信用卡溢缴款
	        ELSE '02'
	         END  AS D030010                    ,  -- 10.借贷标识
	   CASE WHEN T1.ACCOUNT_CATA_FLG = '2' THEN '01' -- 钞
	        WHEN T1.ACCOUNT_CATA_FLG = '3' THEN '02' -- 汇
			WHEN T1.ACCOUNT_CATA_FLG = '4' THEN '03' -- 可钞可汇
	    END AS D030016                           ,  -- 11.钞汇类别
	   NULL  AS D030017                          ,  -- 12.内部账利率
       CASE WHEN T1.GL_ITEM_CODE ='20110111' THEN
            (CASE WHEN T1.ORG_NUM='009803' AND  T8.ACCT_OPDATE > I_DATE THEN TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')  
	         ELSE TO_CHAR(TO_DATE(coalesce(T8.ACCT_OPDATE,T1.ACCT_OPDATE),'YYYYMMDD'),'YYYY-MM-DD') 
                  END )   -- [JLBA202507250003][20250909][巴启威]:信用卡的内部账号，从核心账户中获取到的
	         ELSE (CASE WHEN T1.ACCT_OPDATE > I_DATE THEN TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')  
	                   ELSE TO_CHAR(TO_DATE(T1.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD')
	                    END) -- [20251028][巴启威][JLBA202509280009][吴大为]: 特殊处理开户日期跨日问题
             END AS D030012 ,  -- 13.开户日期      
	   CASE WHEN T1.GL_ITEM_CODE ='20110111' THEN NVL(TO_CHAR(TO_DATE(T8.ACCT_CLDATE,'YYYYMMDD'),'YYYY-MM-DD') ,'9999-12-31') 
	        ELSE NVL(TO_CHAR(TO_DATE(T1.ACCT_CLDATE,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') 
	         END AS D030012 ,  -- 14.销户日期
	   CASE WHEN SUBSTR(T1.ACCT_STS, 1, 1) = 'N'   THEN '01' -- '正常'
	        WHEN SUBSTR(T1.ACCT_STS, 1, 3) = 'E02' THEN '02' -- '预销户'
			WHEN SUBSTR(T1.ACCT_STS, 1, 1) = 'C'   THEN '03' -- '销户'
			WHEN SUBSTR(T1.ACCT_STS, 1, 1) = 'W'   THEN '04' -- '冻结'
			WHEN SUBSTR(T1.ACCT_STS, 1, 1) = 'L'   THEN '05' -- '止付'
            ELSE '06' -- 其他
        END   AS D030013                             ,  -- 15.账户状态
	   '存款分户账'||';'||'D030013:'||nvl(T1.ACCT_STATE_DESC ,'1') AS D030014                                ,  -- 16.备注
	   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS D030015        ,  -- 17.采集日期
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE  ,
       CASE WHEN T1.GL_ITEM_CODE='20110111' THEN '009803'
	        ELSE T1.ORG_NUM
	         END  AS DIS_BANK_ID ,                                                   --  '机构号'
		 '009806' AS DEPARTMENT_ID  ,                                                        -- 业务条线  默认计划财务部
	    '0',   -- 借方余额
	    sum(NVL(T1.ACCT_BALANCE,0))  -- 贷方余额
     FROM SMTMODS.L_ACCT_DEPOSIT T1 -- 存款账户信息表
     LEFT JOIN SMTMODS.L_CUST_C T2 
            ON T1.CUST_ID = T2.CUST_ID
           AND T2.DATA_DATE = I_DATE	
     LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
            ON T1.ORG_NUM = ORG.ORG_NUM
           AND ORG.DATA_DATE = I_DATE
     LEFT JOIN SMTMODS.L_ACCT_CARD_CREDIT T8 -- 关联信用卡账户表，取溢缴款的开户日期
             ON T1.ACCT_NUM = T8.ACCT_NUM
            AND T8.DATA_DATE =  I_DATE      
     WHERE T1.DATA_DATE = I_DATE
--        AND (T1.ACCT_CLDATE >= I_DATE
-- 		     OR T1.ACCT_CLDATE IS NULL
-- 		     OR T1.ACCT_BALANCE > 0)

      AND (T1.ACCT_CLDATE >= SUBSTR(I_DATE,1,4)||'0101' -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
 		     or ( T1.ACCT_CLDATE IS null /*and  T1.ACCT_BALANCE > 0*/ ) -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
 		     OR T1.ACCT_BALANCE > 0)   -- update zjk 20240724
	   AND T1.GL_ITEM_CODE NOT LIKE  '2012%' -- 同业存放在资金往来部分插入
	   AND SUBSTR(T1.GL_ITEM_CODE,1,6) <>  '224101'  -- 久悬
	   AND T1.GL_ITEM_CODE IS NOT NULL
	   -- AND ORG.ORG_NAM NOT LIKE '%村镇%' -- [JLBA202507250003][20250909][巴启威]:剔除掉村镇数据
	   AND T1.ORG_NUM NOT IN  ('012104','012157','012102','012153','012150',
                               '012106','012103','012151','012105','012154',
                               '012156','012108','012107','012152','012155') -- [JLBA202507250003][20250909][巴启威]:剔除掉村镇回迁在总行下的内部账户
	   GROUP BY CASE WHEN T1.GL_ITEM_CODE='20110111' THEN 'B0302H22201009803'
            ELSE ORG.ORG_ID
             END    ,  -- 01.机构
	   T1.ACCT_NUM ,  -- 02.分户账号
	   T1.CUST_ID   ,  -- 03.客户ID
	   T1.ACCT_NAM ,  -- 04.分户账名称
	   CASE WHEN T2.CUST_ID IS NULL OR T2.CUST_TYP = '3' OR T2.DEPOSIT_CUSTTYPE IN ('13','14') THEN '02' -- 个人
	        ELSE '01' -- 对公
        END  ,  -- 05.分户账类型  [JLBA202507250003][20250909][巴启威]:个体工商户对应的分户账类型，调整为个人
	    CASE WHEN T1.GL_ITEM_CODE = '20110111' THEN '0' -- '否' 信用卡溢缴款不计息
	         WHEN (T1.ACCU_INT_FLG = 'N' OR NVL(T1.INT_RATE,0)= 0) THEN '0'  -- 20250415 [20250415][姜俐锋][JLBA202502210009][吴大为]: 20250415 增加利率为0计息方式为否的判断
	         WHEN T1.ACCU_INT_FLG = 'Y' THEN '1' -- '是'
             WHEN T1.ACCU_INT_FLG = 'N' THEN '0' -- '否'
             END ,  -- 06.计息标识
       T1.ACCU_INT_FLG,
       T1.INT_RATE,
	   CASE WHEN T1.GL_ITEM_CODE = '20110111' THEN '06' -- 信用卡溢缴款
	        WHEN T1.JXFS IS NOT NULL THEN T1.JXFS
	        WHEN T1.GL_ITEM_CODE = '20110110' THEN '00' -- [20251028][巴启威][JLBA202509280009][吴大为]: 按照增利账户的计息方式,00-其他
             END    ,  -- 07.计息方式
	   T1.GL_ITEM_CODE ,  -- 08.科目
	   T1.CURR_CD  ,  -- 09.币种
	   CASE WHEN T1.GL_ITEM_CODE = '20110111' THEN '01' -- 信用卡溢缴款
	        ELSE '02'
	         END   ,  -- 10.借贷标识
	   CASE WHEN T1.ACCOUNT_CATA_FLG = '2' THEN '01' -- 钞
	        WHEN T1.ACCOUNT_CATA_FLG = '3' THEN '02' -- 汇
			WHEN T1.ACCOUNT_CATA_FLG = '4' THEN '03' -- 可钞可汇
	   END  ,  -- 11.钞汇类别
	   NULL   ,  -- 12.内部账利率  
       CASE WHEN T1.GL_ITEM_CODE ='20110111' THEN
            (CASE WHEN T1.ORG_NUM='009803' AND  T8.ACCT_OPDATE > I_DATE THEN TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')  
	         ELSE TO_CHAR(TO_DATE(coalesce(T8.ACCT_OPDATE,T1.ACCT_OPDATE),'YYYYMMDD'),'YYYY-MM-DD') 
                  END )   -- [JLBA202507250003][20250909][巴启威]:信用卡的内部账号，从核心账户中获取到的
	         ELSE (CASE WHEN T1.ACCT_OPDATE > I_DATE THEN TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')  
	                   ELSE TO_CHAR(TO_DATE(T1.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD')
	                    END) -- [20251028][巴启威][JLBA202509280009][吴大为]: 特殊处理开户日期跨日问题
             END   ,  -- 13.开户日期            
       
	   CASE WHEN T1.GL_ITEM_CODE ='20110111' THEN NVL(TO_CHAR(TO_DATE(T8.ACCT_CLDATE,'YYYYMMDD'),'YYYY-MM-DD') ,'9999-12-31') 
	        ELSE NVL(TO_CHAR(TO_DATE(T1.ACCT_CLDATE,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') 
	         END ,  -- 14.销户日期
	   CASE WHEN SUBSTR(T1.ACCT_STS, 1, 1) = 'N'   THEN '01' -- '正常'
	        WHEN SUBSTR(T1.ACCT_STS, 1, 3) = 'E02' THEN '02' -- '预销户'
			WHEN SUBSTR(T1.ACCT_STS, 1, 1) = 'C'   THEN '03' -- '销户'
			WHEN SUBSTR(T1.ACCT_STS, 1, 1) = 'W'   THEN '04' -- '冻结'
			WHEN SUBSTR(T1.ACCT_STS, 1, 1) = 'L'   THEN '05' -- '止付'
            ELSE '06' -- 其他
        END   ,  -- 15.账户状态
	    '存款分户账'||';'||'D030013:'||nvl(T1.ACCT_STATE_DESC ,'1')            ,  -- 16.备注
	   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')   ,  -- 17.采集日期
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,
       CASE WHEN T1.GL_ITEM_CODE='20110111' THEN '009803'
	        ELSE T1.ORG_NUM
	         END   ,                                                   --  '机构号'
		 '009806' ,                                                        -- 业务条线  默认计划财务部
	    '0'
     ;
     COMMIT;
	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	

	    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '贷款分户账数据插入';
	
	INSERT  INTO ybt_datacore.T_4_3  (
   D030001,  -- 01.机构
   D030002,  -- 02.分户账号
   D030003,  -- 03.客户ID
   D030004,  -- 04.分户账名称
   D030005,  -- 05.分户账类型
   D030006,  -- 06.计息标识
   D030007,  -- 07.计息方式
   D030008,  -- 08.科目
   D030009,  -- 09.币种
   D030010,  -- 10.借贷标识
   D030016,  -- 11.钞汇类别
   D030017,  -- 12.内部账利率
   D030011,  -- 13.开户日期
   D030012,  -- 14.销户日期
   D030013,  -- 15.账户状态
   D030014,  -- 16.备注
   D030015,   -- 17.采集日期
   DIS_DATA_DATE,
   DIS_BANK_ID ,   -- 机构号
   DEPARTMENT_ID ,      -- 业务条线
   D030018,  -- 借方余额
   D030019   -- 贷方余额	    	    
  )
  SELECT
       ORG.ORG_ID                            ,  -- 01.机构
	   CASE
         WHEN SUBSTR(T1.ITEM_CD,1,6) IN ('130101','130104','130102','130105') THEN SUBSTR(T1.ACCT_NUM || NVL(T1.DRAFT_RNG,''),1,60)  
         ELSE T1.LOAN_NUM
         END AS LOAN_NUM     ,  -- 02.分户账号
	   CASE WHEN  SUBSTR(T1.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN NVL(t5.ECIF_CUST_ID,t1.CUST_ID)
       ELSE T1.CUST_ID
       END AS F270002,     -- 03.客户ID  [JLBA202507250003][20250909][巴启威]:客户ID取数补充
	   -- T1.CUST_ID                          ,  -- 03.客户ID
	   NVL(T2.CUST_NAM,T5.FINA_ORG_NAME)                           ,  -- 04.分户账名称   EAST逻辑同步
	   -- NVL(T2.CUST_NAM,T1.ACCT_TYP_DESC)                           ,  -- 04.分户账名称
       CASE WHEN T2.CUST_TYPE = '00' THEN '02' -- 个人
            WHEN T4.CUST_ID IS NOT NULL AND T4.CUST_TYP = '3' THEN '02' -- 个体工商户
	        ELSE '01' -- 对公
		END                                  ,  -- 05.分户账类型
	   CASE WHEN T1.ACCU_INT_FLG = 'Y' THEN '1' -- '是'
            WHEN T1.ACCU_INT_FLG = 'N' THEN '0' -- '否'
        END                                  ,  -- 06.计息标识
     CASE
       WHEN (T1.ACCU_INT_FLG = 'Y' AND T1.INT_REPAY_FREQ = '03') THEN
        '01'
       WHEN (T1.ACCU_INT_FLG = 'Y' AND T1.INT_REPAY_FREQ = '04') THEN
        '02'
       WHEN (T1.ACCU_INT_FLG = 'Y' AND T1.INT_REPAY_FREQ = '05') THEN
        '03'
       WHEN (T1.ACCU_INT_FLG = 'Y' AND T1.INT_REPAY_FREQ = '06') THEN
        '04'
       WHEN (T1.ACCU_INT_FLG = 'Y' AND T1.INT_REPAY_FREQ = '07') THEN
        '07'
       WHEN (T1.ACCU_INT_FLG = 'Y' AND
            T1.INT_REPAY_FREQ IN ('01', '02', '08', '99')) THEN
        '05'
       WHEN T1.ACCU_INT_FLG = 'N' THEN
        '06'
		ELSE '01'
       END                             ,  -- 07.计息方式      一表通转EAST LMH
	   T1.ITEM_CD                            ,  -- 08.科目
	   T1.CURR_CD                            ,  -- 09.币种
	   '01'                                  ,  -- 10.借贷标识
	    CASE WHEN SUBSTR(T1.ITEM_CD,1,4) = '1305' AND T1.CURR_CD NOT IN('CNY','BWB') THEN '02'  -- 贸易融资科目为 汇
		      ELSE NULL
		       END                                    ,  -- 11.钞汇类别
	   NULL                                  ,  -- 12.内部账利率
	   TO_CHAR(TO_DATE(T1.DRAWDOWN_DT, 'YYYYMMDD'),'YYYY-MM-DD') ,  -- 13.开户日期
	   TO_CHAR(TO_DATE(T1.FINISH_DT, 'YYYYMMDD'),'YYYY-MM-DD') ,    -- 14.销户日期
	   CASE WHEN T1.ACCT_STS IN ('1','2') THEN '01' -- '正常'
	        WHEN T1.ACCT_STS = '3' THEN '03'     -- EAST逻辑同步YBT
            ELSE '06' -- 其他
        END                                  ,  -- 15.账户状态
	   '贷款分户账'        ,  -- 16.备注    
	   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')           ,  -- 17.采集日期
	   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
       T1.ORG_NUM,                                                   --  '机构号'
		 '009806'      ,                                                    -- 业务条线  默认计划财务部
	  NVL(T1.LOAN_ACCT_BAL,0),  -- 借方余额
	  '0' -- 贷方余额
      FROM SMTMODS.L_ACCT_LOAN T1
      LEFT JOIN SMTMODS.L_CUST_ALL T2 
              ON T1.CUST_ID = T2.CUST_ID
             AND T2.DATA_DATE = I_DATE 
      LEFT JOIN SMTMODS.L_CUST_C T4
             ON T1.CUST_ID = T4.CUST_ID
            AND T4.DATA_DATE = I_DATE  
      LEFT JOIN (SELECT DISTINCT DATA_DATE,CUST_ID,FINA_ORG_NAME,ECIF_CUST_ID FROM SMTMODS.L_CUST_BILL_TY WHERE DATA_DATE = I_DATE) T5   -- 同步east取数逻辑      
           ON T1.CUST_ID = T5.CUST_ID
           AND T5.DATA_DATE = I_DATE    
     /* LEFT JOIN SMTMODS.L_CUST_BILL_TY T5   -- 同业客户补充信息表
             ON T1.CUST_ID = T5.CUST_ID
            AND T5.DATA_DATE = I_DATE  */
      LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT T3 -- 贷款合同信息表
             ON T1.ACCT_NUM = T3.CONTRACT_NUM
            AND T3.DATA_DATE = I_DATE
      LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
             ON T1.ORG_NUM = ORG.ORG_NUM
            AND ORG.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_ACCT_CARD_CREDIT T8 -- 关联信用卡账户表，取溢缴款的开户日期
             ON T1.ACCT_NUM = T8.ACCT_NUM
            AND T8.DATA_DATE =  I_DATE
      WHERE T1.DATA_DATE = I_DATE
        AND (T1.ACCT_STS <>'3' OR
               T1.LOAN_ACCT_BAL > 0 OR
               T1.FINISH_DT >= SUBSTR(I_DATE,1,4)||'0101' OR -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
              (T1.INTERNET_LOAN_FLG = 'Y' AND T1.FINISH_DT >= TO_CHAR(TO_DATE(SUBSTR(I_DATE,1,4)||'0101', 'YYYYMMDD') - 1,'YYYYMMDD')) or -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
              (T1.CP_ID ='DK001000100041' AND T1.FINISH_DT >= TO_CHAR(TO_DATE(SUBSTR(I_DATE,1,4)||'0101', 'YYYYMMDD') - 1,'YYYYMMDD'))  -- [20250929][姜俐锋][JLBA202507300010][信贷新增产品]: 同网贷部分数据处理方式 
              ) 
        AND NVL(T3.PROD_NAME,'##') NOT IN ('个人遗留贷款无本产品','公司遗留贷款无本产品') -- 剔除无本有息历史数据
        AND NOT EXISTS(
              SELECT A.LOAN_NUM,A.WRITE_OFF_DATE -- 核销日期
                FROM SMTMODS.L_ACCT_WRITE_OFF A -- 贷款核销
                WHERE A.DATA_DATE = I_DATE
                  AND A.WRITE_OFF_DATE < I_DATE
                  AND A.LOAN_NUM = T1.LOAN_NUM
                 )
     ;
     COMMIT;
	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	
 
	    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '资金往来分户账数据插入';
	
	INSERT  INTO ybt_datacore.T_4_3  (
   D030001,  -- 01.机构
   D030002,  -- 02.分户账号
   D030003,  -- 03.客户ID
   D030004,  -- 04.分户账名称
   D030005,  -- 05.分户账类型
   D030006,  -- 06.计息标识
   D030007,  -- 07.计息方式
   D030008,  -- 08.科目
   D030009,  -- 09.币种
   D030010,  -- 10.借贷标识
   D030016,  -- 11.钞汇类别
   D030017,  -- 12.内部账利率
   D030011,  -- 13.开户日期
   D030012,  -- 14.销户日期
   D030013,  -- 15.账户状态
   D030014,  -- 16.备注
   D030015,   -- 17.采集日期
   DIS_DATA_DATE,
   DIS_BANK_ID ,   -- 机构号
   DEPARTMENT_ID ,      -- 业务条线
   D030018,  -- 借方余额
   D030019   -- 贷方余额	    	    
  )
  SELECT
     ORG.ORG_ID                    ,  -- 01.机构
	 T1.ACCT_NUM                   ,  -- 02.分户账号
	 T1.CUST_ID                    ,  -- 03.客户ID
	 CASE WHEN T1.GL_ITEM_CODE ='20040101' AND T1.ORG_NUM ='009801' THEN '吉林银行股份有限公司支小再贷款'
	      ELSE COALESCE(TT.ACCT_NAME,T2.CUST_NAM,T1.CUST_ID)
	       END                     ,  -- 04.分户账名称
	 '01'                          ,  -- 05.分户账类型
     CASE WHEN T1.ACC_INT_TYPE IS NOT NULL THEN '1'
          ELSE '0'
           END                     ,  -- 06.计息标识  	 
	 CASE WHEN T1.ACC_INT_TYPE='1' THEN '01' -- '按月结息'
          WHEN T1.ACC_INT_TYPE='2' THEN '02' -- '按季结息'
		  WHEN T1.ACC_INT_TYPE='6' THEN '03' -- '按半年结息'
          WHEN T1.ACC_INT_TYPE='3' THEN '04' -- '按年结息'
          WHEN T1.ACC_INT_TYPE='4' THEN '05' -- '不定期结息'
          WHEN T1.ACC_INT_TYPE='5' THEN '06' -- '不记利息'
          WHEN T1.ACC_INT_TYPE='7' THEN '07' -- '利随本清'
          ELSE '00' -- '其他'
        END                        ,  -- 07.计息方式
	 T1.GL_ITEM_CODE               ,  -- 08.科目
	 T1.CURR_CD                    ,  -- 09.币种 
	 CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '1' THEN '01' -- 借
	      WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '2' THEN '02' -- 贷
	      WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '7' THEN '02' -- 贷
             END                     ,  -- 10.借贷标识
	 '02'                            ,  -- 11.钞汇类别
	 NULL                          ,  -- 12.内部账利率
	 -- TO_CHAR(TO_DATE(T1.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD')  ,  -- 13.开户日期
	 -- TO_CHAR(TO_DATE(START_DATE,'YYYYMMDD'),'YYYY-MM-DD') as D030011 ,  -- 13.开户日期 20241231
	 CASE WHEN T1.GL_ITEM_CODE ='13020104' THEN TO_CHAR(TO_DATE(T1.START_DATE,'YYYYMMDD'),'YYYY-MM-DD')  -- 20250213 
	 ELSE nvl(TO_CHAR(TO_DATE(T1.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD') ,  TO_CHAR(TO_DATE(T1.START_DATE,'YYYYMMDD'),'YYYY-MM-DD') )
     END  AS D030011 ,  -- 13.开户日期  20250213 
	 NVL(TO_CHAR(TO_DATE(T1.ACCT_CLDATE, 'YYYYMMDD'),'YYYY-MM-DD'), '9999-12-31')  ,  -- 14.销户日期  YBT_JYD03-22、YBT_JYD03-23   修改一表通表4.3中开户日期 字段 同业金融部确认参考 T_8_7合同起始日期，逻辑保持一致
	 CASE WHEN T1.ACCT_STS = 'N' THEN '01' -- 正常
          WHEN T1.ACCT_STS = 'E02' THEN '02' -- 预销户
	      WHEN T1.ACCT_STS = 'C' THEN '03' -- 销户
	      WHEN T1.ACCT_STS = 'W' THEN '04' -- 冻结
  	      ELSE '06' -- 其他
        END                        ,  -- 15.账户状态
	 '资金往来'                   ,  -- 16.备注
	 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')   ,  -- 17.采集日期
	 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
       T1.ORG_NUM,                                                   --  '机构号'
		 '009806'         ,                                                 -- 业务条线  默认计划财务部
	     CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '1' THEN NVL(T1.BALANCE,0)
		      ELSE '0'
		       END                                        , -- 借方余额
		 CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '2' THEN NVL(T1.BALANCE,0)
		      ELSE '0'
		       END                                          -- 贷方余额
      FROM SMTMODS.L_ACCT_FUND_MMFUND T1
	  LEFT JOIN SMTMODS.L_CUST_ALL T2 
             ON T1.CUST_ID = T2.CUST_ID
            AND T2.DATA_DATE = I_DATE      
      LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
             ON T1.ORG_NUM = ORG.ORG_NUM
            AND ORG.DATA_DATE = I_DATE
      left join SMTMODS.L_ACCT_INNER TT
        on T1.ACCT_NUM = TT.ACCT_NUM
       and T1.DATA_DATE = TT.DATA_DATE
      WHERE T1.DATA_DATE = I_DATE
	  -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
        AND (((T1.ACCT_CLDATE > I_DATE OR T1.ACCT_CLDATE IS null) AND T1.BALANCE > 0) or (T1.ACCT_CLDATE >= SUBSTR(I_DATE,1,4)||'0101' and T1.BALANCE = 0) or  T1.ACCRUAL <> 0) -- 与8.7同步  alter by djh 20240719 有利息无本金数据也加进来 
      ;
     COMMIT;
	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	
      
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '表外业务分户账数据插入'; 
	INSERT  INTO ybt_datacore.T_4_3  (
   D030001,  -- 01.机构
   D030002,  -- 02.分户账号
   D030003,  -- 03.客户ID
   D030004,  -- 04.分户账名称
   D030005,  -- 05.分户账类型
   D030006,  -- 06.计息标识
   D030007,  -- 07.计息方式
   D030008,  -- 08.科目
   D030009,  -- 09.币种
   D030010,  -- 10.借贷标识
   D030016,  -- 11.钞汇类别
   D030017,  -- 12.内部账利率
   D030011,  -- 13.开户日期
   D030012,  -- 14.销户日期
   D030013,  -- 15.账户状态
   D030014,  -- 16.备注
   D030015,   -- 17.采集日期
   DIS_DATA_DATE,
   DIS_BANK_ID ,   -- 机构号
   DEPARTMENT_ID ,      -- 业务条线
   D030018,  -- 借方余额
   D030019   -- 贷方余额	    	  
  )
  SELECT
     ORG.ORG_ID                    ,  -- 01.机构
	 T1.ACCT_NUM                   ,  -- 02.分户账号
	 T1.CUST_ID                    ,  -- 03.客户ID
	 T2.CUST_NAM                   ,  -- 04.分户账名称
	 '01'                          ,  -- 05.分户账类型
     '0'                            ,  -- 06.计息标识  	 
	 '06'                         ,  -- 07.计息方式   20250109 zjk   吴大为 确认表外业务计息方式默认为06 不计息
	 T1.GL_ITEM_CODE               ,  -- 08.科目
	 T1.CURR_CD                    ,  -- 09.币种
	 CASE WHEN T1.GL_ITEM_CODE IN ('70300101','70300301','7010')  -- 贷款承诺、商票保贴承诺、信用证
	         THEN '01' -- 借
	      WHEN T1.GL_ITEM_CODE IN ('70400101','70400102','70200101','7010')  -- 融资保函、非融资保函、银行承兑汇票、信用证
	         THEN '02' -- 贷   
	       END                     ,  -- 10.借贷标识
	 CASE WHEN T1.CURR_CD NOT IN('CNY','BWB') THEN '02' 
	      ELSE NULL          
	       END                     ,  -- 11.钞汇类别
	 NULL                          ,  -- 12.内部账利率
	 TO_CHAR(TO_DATE(T1.BUSINESS_DT,'YYYYMMDD'),'YYYY-MM-DD')  ,  -- 13.开户日期
	 CASE WHEN T1.GL_ITEM_CODE IN('70300301') THEN TO_CHAR(TO_DATE(nvl(T3.DISCOUNT_DATE,T1.MATURITY_DT),'YYYYMMDD'),'YYYY-MM-DD') -- [20250513] [狄家卉] [JLBA202504060003][吴大为] 70300301商票保贴业务销户日期取贴现日期
	      WHEN T1.GL_ITEM_CODE IN('70300101') THEN (CASE WHEN t1.BUSINESS_DT > t1.MATURITY_DT THEN TO_CHAR(TO_DATE(t1.MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD') ELSE TO_CHAR(TO_DATE(t1.BUSINESS_DT,'YYYYMMDD'),'YYYY-MM-DD') END )  -- [20250513] [狄家卉] [JLBA202504060003][吴大为] 可撤销贷款承诺贷款发放日与合同到期比较，谁小取谁
              WHEN T1.MATURITY_DT = I_DATE THEN TO_CHAR(TO_DATE(T1.MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD')
	      ELSE '9999-12-31'         
	      END  ,  -- 14.销户日期
	 CASE WHEN T1.ACCT_STS = '1' THEN '01' -- 正常
	      WHEN T1.ACCT_STS = '2' THEN '03' -- 销户
  	      ELSE '06' -- 其他
        END                        ,  -- 15.账户状态
	 '表外业务'    ,  -- 16.备注
	 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')    , -- 17.采集日期
	 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
       T1.ORG_NUM,                                                   --  '机构号'
		 '009806',                                                          -- 业务条线  默认计划财务部
	 CASE WHEN T1.GL_ITEM_CODE IN ('70300101','70300301','7010')  -- 贷款承诺、商票保贴承诺、信用证
	              THEN NVL(T1.BALANCE,0) 
	              ELSE '0'
	            END                                        ,  -- 借方余额
	 CASE WHEN T1.GL_ITEM_CODE IN ('70400101','70400102','70200101','7010')  -- 融资保函、非融资保函、银行承兑汇票、信用证
	              THEN NVL(T1.BALANCE,0)
	              ELSE '0'
	            END                                        -- 贷方余额	 
      FROM SMTMODS.L_ACCT_OBS_LOAN T1
	  LEFT JOIN SMTMODS.L_CUST_ALL T2 
             ON T1.CUST_ID = T2.CUST_ID
            AND T2.DATA_DATE = I_DATE       
      LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
             ON T1.ORG_NUM = ORG.ORG_NUM
            AND ORG.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_AGRE_BILL_INFO T3 
            ON T1.ACCT_NUM = T3.BILL_NUM 
           AND T3.DATA_DATE = I_DATE
      WHERE T1.DATA_DATE = I_DATE
        AND  (T1.MATURITY_DT >= SUBSTR(I_DATE,1,4)||'0101' OR T1.MATURITY_DT IS NULL OR T1.BALANCE > 0 ) -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
     ;
     COMMIT;
	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	
 
	#3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '信用卡分户账数据插入';
	
  INSERT  INTO ybt_datacore.T_4_3  (
   D030001,  -- 01.机构
   D030002,  -- 02.分户账号
   D030003,  -- 03.客户ID
   D030004,  -- 04.分户账名称
   D030005,  -- 05.分户账类型
   D030006,  -- 06.计息标识
   D030007,  -- 07.计息方式
   D030008,  -- 08.科目
   D030009,  -- 09.币种
   D030010,  -- 10.借贷标识
   D030016,  -- 11.钞汇类别
   D030017,  -- 12.内部账利率
   D030011,  -- 13.开户日期
   D030012,  -- 14.销户日期
   D030013,  -- 15.账户状态
   D030014,  -- 16.备注
   D030015,   -- 17.采集日期
   DIS_DATA_DATE,
   DIS_BANK_ID ,   -- 机构号
   DEPARTMENT_ID ,      -- 业务条线
   D030018,  -- 借方余额
   D030019   -- 贷方余额	    	 
  )
  SELECT
     'B0302H22201009803'           ,  -- 01.机构
	 T1.ACCT_NUM                   ,  -- 02.分户账号
	 T1.CUST_ID                    ,  -- 03.客户ID
	 T2.CUST_NAM                   ,  -- 04.分户账名称
	 '02'                          ,  -- 05.分户账类型
     '1'                           ,  -- 06.计息标识  	 
	 '01'                          ,  -- 07.计息方式
	 '130604'                      ,  -- 08.科目
	 T1.CURR_CD                    ,  -- 09.币种
	 '01'                          ,  -- 10.借贷标识
	 NULL                           ,  -- 11.钞汇类别 默认空
	 NULL                            ,  -- 12.内部账利率
	-- TO_CHAR(TO_DATE(T1.ACCT_OPDATE, 'YYYYMMDD'),'YYYY-MM-DD')  ,  -- 13.开户日期
	 CASE WHEN T1.ACCT_OPDATE > I_DATE THEN  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') 
      ELSE TO_CHAR(TO_DATE(T1.ACCT_OPDATE, 'YYYYMMDD'),'YYYY-MM-DD') 
      END AS  D030011 ,  -- 13.开户日期20241230
	 NVL(TO_CHAR(TO_DATE(T1.ACCT_CLDATE, 'YYYYMMDD'),'YYYY-MM-DD'), '9999-12-31')  ,  -- 14.销户日期
	 CASE 
            WHEN T1.ACCOUNTSTAT IN ('Q','WQ') THEN '03' -- 销户
            WHEN T1.ACCOUNTSTAT IN ('D','B')  THEN '04' -- 冻结
            WHEN T1.ACCOUNTSTAT IN ('H')      THEN '05' -- 止付
            WHEN T1.ACCOUNTSTAT IS NULL       THEN '01' -- 正常
            ELSE '06' -- 其他 
            end  ,  -- 15.账户状态  映射不上给其他  以上逻辑来自业务老师李逊昂     [20250521][巴启威]:4.3口径不对，与8.4同步口径                 
	 '信用卡1'                 ,  -- 16.备注
	 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')   ,  -- 17.采集日期
	 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
      '009803',                                                   --  '机构号'
		 '009806',                                                          -- 业务条线  默认计划财务部
	 NVL(T1.M0,0)                                            , -- 借方余额
	  '0'                                             -- 贷方余额 
      FROM SMTMODS.L_ACCT_CARD_CREDIT T1
	  LEFT JOIN SMTMODS.L_CUST_ALL T2 
             ON T1.CUST_ID = T2.CUST_ID
            AND T2.DATA_DATE = I_DATE      
      WHERE T1.DATA_DATE = I_DATE
        AND (T1.ACCT_CLDATE >= SUBSTR(I_DATE,1,4)||'0101' OR T1.ACCT_CLDATE IS NULL) -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
		AND (T1.DEALDATE = I_DATE OR T1.DEALDATE ='00000000')   
	-- add by haorui 20241119 JLBA202410090008信用卡收益权转让 start
	UNION all
	-- 已转让但有溢缴款
	SELECT
		 'B0302H22201009803'           ,  -- 01.机构
		 T1.ACCT_NUM                   ,  -- 02.分户账号
		 T1.CUST_ID                    ,  -- 03.客户ID
		 T2.CUST_NAM                   ,  -- 04.分户账名称
		 '02'                          ,  -- 05.分户账类型
		 '1'                           ,  -- 06.计息标识  	 
		 '01'                          ,  -- 07.计息方式
		 '130604'                      ,  -- 08.科目
		 T1.CURR_CD                    ,  -- 09.币种
		 '01'                          ,  -- 10.借贷标识
		 NULL                           ,  -- 11.钞汇类别 默认空
		 NULL                            ,  -- 12.内部账利率
		 CASE WHEN T1.ACCT_OPDATE > I_DATE THEN  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') 
           ELSE TO_CHAR(TO_DATE(T1.ACCT_OPDATE, 'YYYYMMDD'),'YYYY-MM-DD') 
          END AS  D030011 ,  -- 13.开户日期20241230
		-- TO_CHAR(TO_DATE(T1.ACCT_OPDATE, 'YYYYMMDD'),'YYYY-MM-DD')  ,  -- 13.开户日期
		 NVL(TO_CHAR(TO_DATE(T1.ACCT_CLDATE, 'YYYYMMDD'),'YYYY-MM-DD'), '9999-12-31')  ,  -- 14.销户日期
	     CASE 
            WHEN T1.ACCOUNTSTAT IN ('Q','WQ') THEN '03' -- 销户
            WHEN T1.ACCOUNTSTAT IN ('D','B')  THEN '04' -- 冻结
            WHEN T1.ACCOUNTSTAT IN ('H')      THEN '05' -- 止付
            WHEN T1.ACCOUNTSTAT IS NULL       THEN '01' -- 正常
            ELSE '06' -- 其他 
            end  ,  -- 15.账户状态  映射不上给其他  以上逻辑来自业务老师李逊昂     [20250521][巴启威]:4.3口径不对，与8.4同步口径                 
		 '信用卡2'                 ,  -- 16.备注
		 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')   ,  -- 17.采集日期
		 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
		  '009803',                                                   --  '机构号'
			 '009806',                                                          -- 业务条线  默认计划财务部
		 NVL(T1.M0,0)                                            , -- 借方余额
		  '0'                                             -- 贷方余额 
      FROM SMTMODS.L_ACCT_CARD_CREDIT T1
	  LEFT JOIN SMTMODS.L_ACCT_DEPOSIT T3
	  ON T1.DATA_DATE = T3.DATA_DATE
	  AND T1.ACCT_NUM = T3.ACCT_NUM
	  AND T3.GL_ITEM_CODE ='20110111'
	  LEFT JOIN SMTMODS.L_ACCT_DEPOSIT T4
	  ON T1.ACCT_NUM = T4.ACCT_NUM
	  AND T4.DATA_DATE = LAST_DT
	  AND T4.GL_ITEM_CODE ='20110111'
	  LEFT JOIN SMTMODS.L_CUST_ALL T2 
             ON T1.CUST_ID = T2.CUST_ID
            AND T2.DATA_DATE = I_DATE      
      WHERE T1.DATA_DATE = I_DATE
        AND (T1.ACCT_CLDATE >= SUBSTR(I_DATE,1,4)||'0101' OR T1.ACCT_CLDATE IS NULL) -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
		AND T1.DEALDATE <> '00000000'
		and (T4.ACCT_NUM is not null or T4.ACCT_NUM is null and t3.acct_num is not NULL)  -- 前一天有溢款款 或 前一天无溢缴款当有有溢缴款
	-- add by haorui 20241125 JLBA202410090008信用卡收益权转让 end
       ;
     COMMIT;
	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	

	#3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '投资业务分户账数据插入';
	
	INSERT  INTO ybt_datacore.T_4_3  (
   D030001,  -- 01.机构
   D030002,  -- 02.分户账号
   D030003,  -- 03.客户ID
   D030004,  -- 04.分户账名称
   D030005,  -- 05.分户账类型
   D030006,  -- 06.计息标识
   D030007,  -- 07.计息方式
   D030008,  -- 08.科目
   D030009,  -- 09.币种
   D030010,  -- 10.借贷标识
   D030016,  -- 11.钞汇类别
   D030017,  -- 12.内部账利率
   D030011,  -- 13.开户日期
   D030012,  -- 14.销户日期
   D030013,  -- 15.账户状态
   D030014,  -- 16.备注
   D030015,   -- 17.采集日期
   DIS_DATA_DATE,
   DIS_BANK_ID ,   -- 机构号
   DEPARTMENT_ID ,      -- 业务条线
   D030018,  -- 借方余额
   D030019   -- 贷方余额	    	
  )
  SELECT
       ORG.ORG_ID                     ,  -- 01.机构
	   T1.ACCT_NUM||T1.REF_NUM                    ,  -- 02.分户账号
	   T1.CUST_ID                     ,  -- 03.客户ID
	   T3.CUST_NAM                    ,  -- 04.分户账名称
	   '01'                           ,  -- 05.分户账类型
	   '0'                           ,  -- 06.计息标识  	
	   CASE WHEN T1.JXFS IS NOT NULL THEN T1.JXFS             
	        WHEN T1.GL_ITEM_CODE ='15010201' THEN '06'
	         END                      ,  -- 07.计息方式 -- [20251028][巴启威][JLBA202509280009][吴大为]: 15010201 债权投资特定目的载体投资投资成本 06-不计息
	   T1.GL_ITEM_CODE                ,  -- 08.科目
	   T1.CURR_CD                     ,  -- 09.币种
	   '01'                           ,  -- 10.借贷标识
	   NULL                           ,  -- 11.钞汇类别 默认空
	   NULL                           ,  -- 12.内部账利率
	   /*CASE WHEN T1.TX_DATE> I_DATE THEN  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')
	   ELSE TO_CHAR(TO_DATE(T1.TX_DATE,'YYYYMMDD'),'YYYY-MM-DD')
	   END AS D030011,  -- 13.开户日期*/
	   TO_CHAR(TO_DATE(T1.TX_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS D030011,  -- 13.开户日期
	   CASE WHEN T1.MATURITY_DATE = I_DATE THEN 
	             TO_CHAR(TO_DATE(T1.MATURITY_DATE,'YYYYMMDD'),'YYYY-MM-DD')
	         ELSE '9999-12-31'         
	          END                     ,  -- 14.销户日期
	   CASE WHEN T1.ACCT_STS IN ('A','B','C','D','E','Z') THEN '01' -- '正常'
            ELSE '06' -- 其他
			 END                      ,  -- 15.账户状态
       '投资业务'          ,  -- 16.备注
	   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')    ,  -- 17.采集日期
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
       T1.ORG_NUM,                                                   --  '机构号'
		 '009806' ,                                                         -- 业务条线  默认计划财务部
       NVL(T1.FACE_VAL,0)                              , -- 借方余额
	       '0'                                           -- 贷方余额
      FROM SMTMODS.L_ACCT_FUND_INVEST T1  -- 范围与6.21、8.8同步 
	    LEFT JOIN SMTMODS.L_CUST_ALL T3
               ON T1.CUST_ID = T3.CUST_ID
              AND T3.DATA_DATE = I_DATE 
        LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
               ON T1.ORG_NUM = ORG.ORG_NUM
              AND ORG.DATA_DATE = I_DATE
            WHERE T1.DATA_DATE = I_DATE
			  -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
              AND (T1.MATURITY_DATE >= SUBSTR(I_DATE,1,4)||'0101' OR T1.FACE_VAL > 0)-- 应同业李佶阳要求，不判断到期日
       ;
	   
     COMMIT;
	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	
	
  
	    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '同业存单数据插入';
	
	INSERT  INTO ybt_datacore.T_4_3  (
   D030001,  -- 01.机构
   D030002,  -- 02.分户账号
   D030003,  -- 03.客户ID
   D030004,  -- 04.分户账名称
   D030005,  -- 05.分户账类型
   D030006,  -- 06.计息标识
   D030007,  -- 07.计息方式
   D030008,  -- 08.科目
   D030009,  -- 09.币种
   D030010,  -- 10.借贷标识
   D030016,  -- 11.钞汇类别
   D030017,  -- 12.内部账利率
   D030011,  -- 13.开户日期
   D030012,  -- 14.销户日期
   D030013,  -- 15.账户状态
   D030014,  -- 16.备注
   D030015,   -- 17.采集日期
   DIS_DATA_DATE,
   DIS_BANK_ID ,   -- 机构号
   DEPARTMENT_ID ,      -- 业务条线
   D030018,  -- 借方余额
   D030019   -- 贷方余额	    	
  )
 SELECT
     ORG.ORG_ID  AS D030001                  ,  -- 01.机构
     T.ACCT_NUM || T.CDS_NO                  , -- 02.分户账号  20241212
	 -- FUNC_SUBSTR(T.ACCT_NUM || T.CONT_PARTY_NAME,60) AS D030002 ,  -- 02.分户账号   -- 账号拼交易对手名称，应与7.12、8.9同步  按常城要求截取60位
	 T.CUST_ID  AS  D030003                         ,  -- 03.客户ID -- [20250409][巴启威]原逻辑中客户ID默认为空，现取主表CUST_ID，以便2.3客户表中报送对应客户信息
	 T.STOCK_NAM  AS  D030004                ,  -- 04.分户账名称
	 '01'   AS D030005                       ,  -- 05.分户账类型
     '1'   AS D030006                        ,  -- 06.计息标识  	 
	 '00'   AS D030007                         ,  -- 07.计息方式  [20250619][巴启威][JLBA202505280002][吴大为]：默认 00-其他，5月27日讨论确定
	 T.GL_ITEM_CODE  AS D030008              ,  -- 08.科目
	 T.CURR_CD  AS D030009                   ,  -- 09.币种
	 CASE WHEN SUBSTR(T.GL_ITEM_CODE,1,1) = '1' THEN '01' -- 借
	      WHEN SUBSTR(T.GL_ITEM_CODE,1,1) = '2' THEN '02' -- 贷
	       END   AS D030010                  ,  -- 10.借贷标识
	 '02'  AS D030016                          ,  -- 11.钞汇类别
	 NULL  AS D030017                        ,  -- 12.内部账利率
	 TO_CHAR(TO_DATE(T.ISSU_DT,'YYYYMMDD'),'YYYY-MM-DD')  AS D030011 ,  -- 13.开户日期
	 NVL(TO_CHAR(TO_DATE(T.ACCT_CLDATE, 'YYYYMMDD'),'YYYY-MM-DD'), '9999-12-31') AS D030012 ,  -- 14.销户日期
	 CASE WHEN T.ACCT_STS = 'N' THEN '01' -- 正常
          WHEN T.ACCT_STS = 'E02' THEN '02' -- 预销户
	      WHEN T.ACCT_STS = 'C' THEN '03' -- 销户
	      WHEN T.ACCT_STS = 'W' THEN '04' -- 冻结
  	      ELSE '06' -- 其他
        END           AS D030013             ,  -- 15.账户状态
	 '同业存单'      AS D030014                      ,  -- 16.备注
	 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')  AS D030015 ,  -- 17.采集日期
	 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE,
     T.ORG_NUM AS DIS_BANK_ID,                                                   --  '机构号'
     '009806' AS DEPARTMENT_ID ,                                                        -- 业务条线  默认计划财务部
      CASE WHEN SUBSTR(T.GL_ITEM_CODE,1,1) = '1' THEN NVL(T.FACE_VAL,0)
		      ELSE '0'
		       END                                        , -- 借方余额
		 CASE WHEN SUBSTR(T.GL_ITEM_CODE,1,1) = '2' THEN NVL(T.FACE_VAL,0)
		      ELSE '0'
		       END                                        -- 贷方余额
      FROM SMTMODS.L_ACCT_FUND_CDS_BAL T
      /** LEFT JOIN SMTMODS.L_ACCT_DEPOSIT BZ                 -- 新增备注信息0614
              ON T1.CUST_ID = BZ.CUST_ID 
              AND BZ.DATA_DATE = I_DATE   **/
      LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
             ON T.ORG_NUM = ORG.ORG_NUM
            AND ORG.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_ACCT_FUND_CDS_BAL T1
       ON T.ACCT_NUM || T.CDS_NO = T1.ACCT_NUM || T1.CDS_NO
       and T.CUST_ID = T1.CUST_ID -- [20250625][巴启威]：需要增加交易对手客户ID关联，否则数据存在重复
       AND T1.DATA_DATE = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD') -1 ,'YYYYMMDD')      
      WHERE T.DATA_DATE = I_DATE
		-- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
        AND ((NVL(T.ACCT_STS,'#')<>'03' AND (T.MATURITY_DT >= SUBSTR(I_DATE,1,4)||'0101' OR T.MATURITY_DT IS null)) or (T.ACCT_STS='03' and T1.ACCT_STS<>'03'));-- 范围与8.8、7.7、4.3同步

     COMMIT;
	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	
	
 
	    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '买入返售卖出回购数据插入';
	
	INSERT  INTO ybt_datacore.T_4_3  (
   D030001,  -- 01.机构
   D030002,  -- 02.分户账号
   D030003,  -- 03.客户ID
   D030004,  -- 04.分户账名称
   D030005,  -- 05.分户账类型
   D030006,  -- 06.计息标识
   D030007,  -- 07.计息方式
   D030008,  -- 08.科目
   D030009,  -- 09.币种
   D030010,  -- 10.借贷标识
   D030016,  -- 11.钞汇类别
   D030017,  -- 12.内部账利率
   D030011,  -- 13.开户日期
   D030012,  -- 14.销户日期
   D030013,  -- 15.账户状态
   D030014,  -- 16.备注
   D030015,   -- 17.采集日期
   DIS_DATA_DATE,
   DIS_BANK_ID ,   -- 机构号
   DEPARTMENT_ID ,      -- 业务条线
   D030018,  -- 借方余额
   D030019   -- 贷方余额	    	
  )
  SELECT
     ORG.ORG_ID                    ,  -- 01.机构
	 T1.ACCT_NUM                   ,  -- 02.分户账号
	 T1.CUST_ID                            ,  -- 03.客户ID
	 T1.CUST_ID                   ,  -- 04.分户账名称
	 '01'                          ,  -- 05.分户账类型
     CASE WHEN T1.IS_INTEREST = 'Y' THEN '1' -- '是'
          WHEN T1.IS_INTEREST = 'N' THEN '0' -- '否'
          WHEN T1.ACC_INT_TYPE IS NOT NULL THEN '1' -- '是'
        END                        ,  -- 06.计息标识  	 
	 CASE WHEN T1.ACC_INT_TYPE='1' THEN '01' -- '按月结息'
          WHEN T1.ACC_INT_TYPE='2' THEN '02' -- '按季结息'
		  WHEN T1.ACC_INT_TYPE='6' THEN '03' -- '按半年结息'
          WHEN T1.ACC_INT_TYPE='3' THEN '04' -- '按年结息'
          WHEN T1.ACC_INT_TYPE='4' THEN '05' -- '不定期结息'
          WHEN T1.ACC_INT_TYPE='5' THEN '06' -- '不记利息'
          WHEN T1.ACC_INT_TYPE='7' THEN '07' -- '利随本清'
          ELSE '00' -- '其他'
        END                        ,  -- 07.计息方式
	 T1.GL_ITEM_CODE               ,  -- 08.科目
	 T1.CURR_CD                    ,  -- 09.币种
	 CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '1' THEN '01' -- 借
	      WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '2' THEN '02' -- 贷
	       END                     ,  -- 10.借贷标识
	 '02'                            ,  -- 11.钞汇类别
	 NULL                          ,  -- 12.内部账利率
	 TO_CHAR(TO_DATE(T1.BEG_DT,'YYYYMMDD'),'YYYY-MM-DD')  ,  -- 13.开户日期
	 NVL(TO_CHAR(TO_DATE(T1.ACCT_CLDATE, 'YYYYMMDD'),'YYYY-MM-DD'), '9999-12-31')  ,  -- 14.销户日期
	 CASE WHEN T1.ACCT_CLDATE = I_DATE THEN '03' -- 销户
	      ELSE  '01' -- 正常
		   END                    ,  -- 15.账户状态
	 '买入返售卖出回购'             ,  -- 16.备注
	 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')   ,  -- 17.采集日期
	 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
       T1.ORG_NUM,                                                   --  '机构号'
		 '009806'  ,                                                        -- 业务条线  默认计划财务部
	  CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '1' THEN NVL(T1.BALANCE,0)
		      ELSE '0'
		       END                                        , -- 借方余额
		 CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '2' THEN NVL(T1.BALANCE,0)
		      ELSE '0'
		       END                                        -- 贷方余额 
      FROM SMTMODS.L_ACCT_FUND_REPURCHASE T1 
      LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
             ON T1.ORG_NUM = ORG.ORG_NUM
            AND ORG.DATA_DATE = I_DATE
      WHERE T1.DATA_DATE = I_DATE
	  -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
        AND (((T1.ACCT_CLDATE > I_DATE OR T1.ACCT_CLDATE IS null) AND T1.BALANCE > 0) or (T1.ACCT_CLDATE >= SUBSTR(I_DATE,1,4)||'0101' and T1.BALANCE = 0)) -- 与8.7同步 
      ;
     COMMIT;
	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	
	    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '债券发行数据插入';
	
	INSERT  INTO ybt_datacore.T_4_3  (
   D030001,  -- 01.机构
   D030002,  -- 02.分户账号
   D030003,  -- 03.客户ID
   D030004,  -- 04.分户账名称
   D030005,  -- 05.分户账类型
   D030006,  -- 06.计息标识
   D030007,  -- 07.计息方式
   D030008,  -- 08.科目
   D030009,  -- 09.币种
   D030010,  -- 10.借贷标识
   D030016,  -- 11.钞汇类别
   D030017,  -- 12.内部账利率
   D030011,  -- 13.开户日期
   D030012,  -- 14.销户日期
   D030013,  -- 15.账户状态
   D030014,  -- 16.备注
   D030015,   -- 17.采集日期
   DIS_DATA_DATE,
   DIS_BANK_ID ,   -- 机构号
   DEPARTMENT_ID ,      -- 业务条线
   D030018,  -- 借方余额
   D030019   -- 贷方余额	    	
  )
  SELECT
     ORG.ORG_ID                    ,  -- 01.机构
	 T1.ACCT_NUM||T1.REF_NUM       ,  -- 02.分户账号
	 T1.CUST_ID                            ,  -- 03.客户ID
	 T1.SUBJECT_CD                   ,  -- 04.分户账名称
	 '01'                          ,  -- 05.分户账类型
     CASE WHEN T1.IS_INTEREST = 'Y' THEN '1' -- '是'
          WHEN T1.IS_INTEREST = 'N' THEN '0' -- '否'
        END                        ,  -- 06.计息标识  	 
	 '02'                          ,  -- 07.计息方式-- [20251028][巴启威][JLBA202509280009][吴大为]: 债券发行 的计息方式 默认02-按季计息
	 T1.GL_ITEM_CODE               ,  -- 08.科目
	 T1.CURR_CD                    ,  -- 09.币种
	 CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '1' THEN '01' -- 借
	      WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '2' THEN '02' -- 贷
	       END                     ,  -- 10.借贷标识
	 '02'                            ,  -- 11.钞汇类别
	 NULL                          ,  -- 12.内部账利率
	 TO_CHAR(TO_DATE(T1.INT_ST_DT,'YYYYMMDD'),'YYYY-MM-DD')  ,  -- 13.开户日期
	 CASE WHEN T1.MATURITY_DATE = I_DATE THEN 
	             TO_CHAR(TO_DATE(T1.MATURITY_DATE,'YYYYMMDD'),'YYYY-MM-DD')
	         ELSE '9999-12-31'         
	          END  ,  -- 14.销户日期
     '01'              ,  -- 15.账户状态
	 '债券发行'                 ,  -- 16.备注
	 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')   ,  -- 17.采集日期
	 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
       T1.ORG_NUM,                                                   --  '机构号'
		 '009806' ,                                                         -- 业务条线  默认计划财务部
		 '0'                                              , -- 借方余额
		 NVL(T1.FACE_VAL,0)                               -- 贷方余额
      FROM SMTMODS.L_ACCT_FUND_BOND_ISSUE T1 
      LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
             ON T1.ORG_NUM = ORG.ORG_NUM
            AND ORG.DATA_DATE = I_DATE
      WHERE T1.DATA_DATE = I_DATE
	    AND T1.GL_ITEM_CODE IS NOT NULL
		-- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
        AND (T1.MATURITY_DATE >= SUBSTR(I_DATE,1,4)||'0101' OR T1.MATURITY_DATE IS NULL OR T1.FACE_VAL > 0) 
      ;
     COMMIT;
	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	
	
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '内部分户账数据插入';
	
  INSERT  INTO ybt_datacore.T_4_3  (
   D030001,  -- 01.机构
   D030002,  -- 02.分户账号
   D030003,  -- 03.客户ID
   D030004,  -- 04.分户账名称
   D030005,  -- 05.分户账类型
   D030006,  -- 06.计息标识
   D030007,  -- 07.计息方式
   D030008,  -- 08.科目
   D030009,  -- 09.币种
   D030010,  -- 10.借贷标识
   D030016,  -- 11.钞汇类别
   D030017,  -- 12.内部账利率
   D030011,  -- 13.开户日期
   D030012,  -- 14.销户日期
   D030013,  -- 15.账户状态
   D030014,  -- 16.备注
   D030015,   -- 17.采集日期
   DIS_DATA_DATE,
   DIS_BANK_ID ,   -- 机构号
   DEPARTMENT_ID ,      -- 业务条线
   D030018,  -- 借方余额
   D030019   -- 贷方余额	    	
  )
  SELECT
       ORG.ORG_ID                     ,  -- 01.机构
       T1.ACCT_NUM                     ,  -- 02.分户账号
       T1.CUST_ID                     ,  -- 03.客户ID
	   CASE WHEN REPLACE(T1.ACCT_NAME,'?','') IS NULL THEN '吉林银行内部客户'
            ELSE REPLACE(T1.ACCT_NAME,'?','')
        END                           ,  -- 04.分户账名称
	   '03'                           ,  -- 05.分户账类型 	
	   CASE WHEN T1.INT_FLG = 'Y' THEN '1' -- '是'
            WHEN T1.INT_FLG = 'N' THEN '0' -- '否'
        END                           ,  -- 06.计息标识
       CASE WHEN T1.INT_METH='1' THEN '01' -- '按月结息'
            WHEN T1.INT_METH='2' THEN '02' -- '按季结息'
		    WHEN T1.INT_METH='6' THEN '03' -- '按半年结息'
            WHEN T1.INT_METH='3' THEN '04' -- '按年结息'
            WHEN T1.INT_METH='4' THEN '05' -- '不定期结息'
            WHEN T1.INT_METH='5' THEN '06' -- '不记利息'
            WHEN T1.INT_METH='7' THEN '07' -- '利随本清'
            ELSE '00' -- '其他'
        END                           ,  -- 07.计息方式
       T1.ITEM_ID                     ,  -- 08.科目
	   T1.CURR_CD                     ,  -- 09.币种
	   CASE WHEN T1.CD_TYPE = '1' THEN '01' -- '借'
            WHEN T1.CD_TYPE = '2' THEN '02' -- '贷'
			WHEN T1.CD_TYPE = '3' THEN '03' -- '借贷并列'
        END                           ,  -- 10.借贷标识
       CASE WHEN T1.CURR_CD = 'CNY' THEN NULL
		    ELSE '02'
		     END                      ,  -- 11.钞汇类别
	   NVL(T1.RATE,0)                 ,  -- 12.内部账利率
	   CASE WHEN REPLACE(T1.OPEN_DATE, '/', '') <= '19490101' THEN '1949-01-02'
            ELSE TO_CHAR(TO_DATE(REPLACE(T1.OPEN_DATE, '/', ''),'YYYYMMDD'),'YYYY-MM-DD')
        END                           ,  -- 13.开户日期
	   NVL(TO_CHAR(TO_DATE(REPLACE(T1.CLOSE_DATE, '/', ''),'YYYYMMDD'),'YYYY-MM-DD'), '9999-12-31')  ,  -- 14.销户日期
	   CASE WHEN SUBSTR(T1.ACCT_STATE,1,1) = 'N'   THEN '01' -- '正常'
	        WHEN SUBSTR(T1.ACCT_STATE,1,3) = 'E02' THEN '02' -- '预销户'
			WHEN SUBSTR(T1.ACCT_STATE,1,1) = 'C'   THEN '03' -- '销户'
			WHEN SUBSTR(T1.ACCT_STATE,1,1) = 'W'   THEN '04' -- '冻结'
			WHEN SUBSTR(T1.ACCT_STATE,1,1) = 'L'   THEN '05' -- '止付'
            ELSE '06' -- 其他
        END                           ,  -- 15.账户状态
       '内部账'                            ,  -- 16.备注
	   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')    ,  -- 17.采集日期
	   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
       T1.ORG_NUM,                                                   --  '机构号'
		 '009806' ,                                                         -- 业务条线  默认计划财务部
		NVL(T1.DEBIT_BAL,0) * -1                                    , -- 借方余额
	   NVL(T1.CREDIT_BAL,0)                                     -- 贷方余额 
      FROM SMTMODS.L_ACCT_INNER T1 -- 内部分户账
      LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
             ON T1.ORG_NUM = ORG.ORG_NUM
            AND ORG.DATA_DATE = I_DATE
     WHERE T1.DATA_DATE = I_DATE
       AND T1.ITEM_ID NOT LIKE '9%'
       AND T1.ACCT_NUM NOT LIKE O_ACCT_NUM||ITEM_ID||'%'
       AND (SUBSTR(T1.ACCT_STATE,1,1)<>'C' OR T1.CLOSE_DATE = I_DATE)
       AND NOT EXISTS (SELECT 1 FROM SMTMODS.L_PUBL_ORG_BRA T2 WHERE T2.ORG_NUM = T1.ORG_NUM 
                                   AND T2.ORG_NAM LIKE '%村镇%'
                                   AND T2.DATA_DATE = I_DATE)
       AND NOT EXISTS (SELECT 1 FROM ybt_datacore.T_4_3 A WHERE A.D030002 = T1.ACCT_NUM 
                           AND A.D030015 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'))
       AND T1.ORG_NUM <> '999999' 
       and T1.ACCT_NUM not in ('9019800217000015_1')  -- [2025-03-27] [周敬坤] [邮件需求][吴大为] 为重点指标数据不重复    内部账不报送信用卡溢缴款内部账账号
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