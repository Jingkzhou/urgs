DROP Procedure IF EXISTS `PROC_BSP_T_8_14_CKZT` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_8_14_CKZT"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN

  /******
      程序名称  ：存款状态
      程序功能  ：加工存款状态表
      目标表：T_8_14
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
  
  -- 20250422 姜俐锋 删除判断 代码冗余 各项存款剔除项标识
  -- 需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求   上线日期：20250513  修改人：周敬坤   提出人：吴大为 新增2005、2006、2007、2008、2009、2010科目：其中2005对应以前的201105科目、2006、2007对应以前的201104、201106，此三个科目为财政性存款；新增科目2008、2009，财政性存款；2010对应201107，国库定期存款 
  -- 需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
  -- 需求编号：JLBA202507250003 上线日期：2025-09-09，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统修改取数逻辑的需求*/
  -- 需求编号：JLBA202509280009 上线日期：2025-10-28，修改人：巴启威，提出人：吴大为 修改原因：关于一表通监管数据报送系统修改逻辑的需求
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
	SET P_PROC_NAME = 'PROC_BSP_T_8_14_CKZT';
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
	
	DELETE FROM ybt_datacore.T_8_14 WHERE H140015 = TO_CHAR(P_DATE,'YYYY-MM-DD') ;
	
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
 INSERT INTO ybt_datacore.T_8_14
   (
    H140001  , -- 01 '分户账号'
    H140018  , -- 18 '协议ID'
    H140002  , -- 02 '客户ID'
    H140003  , -- 03 '机构ID'
    H140004  , -- 04 '币种'
    H140005  , -- 05 '科目ID'
    H140006  , -- 06 '科目名称'
    H140007  , -- 07 '交易介质'
    H140008  , -- 08 '交易介质号'
    H140009  , -- 09 '存款期限'
    H140010  , -- 10 '利率'
    H140011  , -- 11 '开户日期'
    H140012  , -- 12 '销户日期'
    H140013  , -- 13 '存款余额'
    H140014  , -- 14 '账户状态'
    H140017  , -- 17 '钞汇类别'
    H140015  , -- 15 '采集日期'
    H140016  , -- 16 '上次动户日期'    
    DIS_DATA_DATE,
    DIS_BANK_ID,        -- 机构号
    DEPARTMENT_ID,      -- 业务条线
    H140019,            -- 通过互联网吸收的存款类型
    H140020             -- 各项存款剔除项标识
   )
 
        SELECT 
		   T1.ACCT_NUM                               , -- 01 '分户账号'
           T1.ACCT_NUM                               , -- 18 '协议ID'
           T1.CUST_ID                                , -- 02 '客户ID'
           CASE WHEN T1.GL_ITEM_CODE = '20110111' THEN 'B0302H22201009803'
                ELSE ORG.ORG_ID
                 END                                 , -- 03 '机构ID'
           T1.CURR_CD                                , -- 04 '币种'
           T1.GL_ITEM_CODE                           , -- 05 '科目ID'
           CASE WHEN T1.GL_ITEM_CODE = '20110111' THEN '个人信用卡存款'
                ELSE T3.GL_CD_NAME
                 END                                 , -- 06 '科目名称'
           CASE 
            WHEN T4.ACCT_MED IN ('1','2','3','7') THEN '01' -- 卡
            WHEN T4.ACCT_MED = '5'  THEN '02'  -- 普通存折
	        WHEN T4.ACCT_MED = '6'  THEN '05'  -- 存单
	        WHEN T4.ACCT_MED = '11' THEN '08'  -- 无介质
	        ELSE '08' -- 无介质           
	         END                             , -- 07 '交易介质'  -- ALTER BY WJB 20240706 2.0升级修改
	       CASE WHEN T4.ACCT_MED IN ('1','2','3','5','6','7') THEN  T4.TYPE_ID 
	        ELSE ''
	         END                           , -- 08 '交易介质号'
           CASE 
             WHEN SUBSTR(T1.ACCT_TYPE,1,2) = '05' THEN '01' -- 活期
             WHEN T1.ACCT_TYPE = '0401' THEN '02' -- 一天通知存款
             WHEN T1.ACCT_TYPE = '0402' THEN '03' -- 七天通知存款
             WHEN otds_data.months_between(date(T1.MATUR_DATE),date(T1.ST_INT_DT)) <= 1   THEN '04'  -- 1个月
             WHEN otds_data.months_between(date(T1.MATUR_DATE),date(T1.ST_INT_DT)) <= 3   THEN '05'  -- 3个月
             WHEN otds_data.months_between(date(T1.MATUR_DATE),date(T1.ST_INT_DT)) <= 6  THEN '06'  -- 6个月
             WHEN otds_data.months_between(date(T1.MATUR_DATE),date(T1.ST_INT_DT)) <= 12  THEN '07' -- 12个月
             WHEN otds_data.months_between(date(T1.MATUR_DATE),date(T1.ST_INT_DT)) <= 18  THEN '08' -- 18个月
             WHEN otds_data.months_between(date(T1.MATUR_DATE),date(T1.ST_INT_DT)) <= 24  THEN '09' -- 24个月
             WHEN otds_data.months_between(date(T1.MATUR_DATE),date(T1.ST_INT_DT)) <= 36 THEN '10' -- 36个月
             WHEN otds_data.months_between(date(T1.MATUR_DATE),date(T1.ST_INT_DT)) <= 60 THEN '11' -- 60个月
             ELSE '12' -- 其他固定期限
           END                              , -- 09 '存款期限'
           MAX( NVL(T1.INT_RATE,0))          , -- 10 '利率' [20250807][巴启威][JLBA202507090010][吴大为]:监管答疑，同一账户的协定户和结算户(0602协定户和 0601结算户)合并报送，利率取协定户利率(更高)
           CASE WHEN T1.GL_ITEM_CODE ='20110111' THEN NVL(TO_CHAR(TO_DATE(T8.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD') ,TO_CHAR(TO_DATE(T1.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD'))
	            ELSE (CASE WHEN T1.ACCT_OPDATE > I_DATE THEN TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')  
	                   ELSE TO_CHAR(TO_DATE(T1.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD')
	                    END) -- [20251028][巴启威][JLBA202509280009][吴大为]: 特殊处理开户日期跨日问题
                 END                             , -- 11 '开户日期'
           CASE WHEN T1.GL_ITEM_CODE ='20110111' THEN TO_CHAR(TO_DATE(T8.ACCT_CLDATE,'YYYYMMDD'),'YYYY-MM-DD')
	            ELSE TO_CHAR(TO_DATE(T1.ACCT_CLDATE,'YYYYMMDD'),'YYYY-MM-DD')
	             END                                 , -- 12 '销户日期'
           SUM(T1.ACCT_BALANCE)                      , -- 13 '存款余额' [20250807][巴启威][JLBA202507090010][吴大为]:ACCT_STS 0602协定户和 0601结算户，监管答疑，同一账户的协定户和结算户合并报送
           CASE
               WHEN SUBSTR(T1.ACCT_STS, 1, 1) = 'N' THEN
                '01' -- '正常'
               WHEN SUBSTR(T1.ACCT_STS, 1, 1) = 'D' THEN
                '06' -- '其他-休眠'
               WHEN SUBSTR(T1.ACCT_STS, 1, 1) = 'C' THEN
                '03' -- '销户'
               WHEN SUBSTR(T1.ACCT_STS, 1, 1) = 'L' THEN
                '05' -- '止付'
               WHEN SUBSTR(T1.ACCT_STS, 1, 1) = 'W' THEN
                '04' -- '冻结'
               WHEN SUBSTR(T1.ACCT_STS, 1, 3) = 'E01' THEN
                '06' -- '其他-预开户'
               WHEN SUBSTR(T1.ACCT_STS, 1, 3) = 'E02' THEN
                '02' -- '预销户'
               WHEN SUBSTR(T1.ACCT_STS, 1, 1) = 'E99' THEN
                '06' -- '其他'
             END AS ZHZT                            , -- 14 '账户状态'
           CASE 
              WHEN T1.ACCOUNT_CATA_FLG = '2' THEN '01' -- 钞
              WHEN T1.ACCOUNT_CATA_FLG = '3' THEN '02' -- 汇
              WHEN T1.ACCOUNT_CATA_FLG = '4' THEN '03' -- 可钞可汇
             END                                    , -- 17 '钞汇类别'
           TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')             , -- 15 '采集日期'
           CASE WHEN T1.DEPARTMENTD = 'TD' 
              THEN CASE WHEN T1.LAST_TX_DATE = '18000101' THEN TO_CHAR(TO_DATE(T1.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD')
                        WHEN T1.LAST_TX_DATE < T1.ACCT_OPDATE THEN  TO_CHAR(TO_DATE(T1.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD')
                        ELSE NVL(TO_CHAR(TO_DATE(T1.LAST_TX_DATE,'YYYYMMDD'),'YYYY-MM-DD'),TO_CHAR(TO_DATE(T1.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD')) END
                WHEN T1.DEPARTMENTD = 'CH' AND T1.ACCT_TYPE NOT IN ('0601', '0602') 
              THEN CASE WHEN T1.LAST_TX_DATE < T1.ACCT_OPDATE THEN TO_CHAR(TO_DATE(T1.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD')
                        WHEN T1.LAST_TX_DATE > T1.ACCT_CLDATE THEN TO_CHAR(TO_DATE(T1.ACCT_CLDATE,'YYYYMMDD'),'YYYY-MM-DD')
                        ELSE NVL(TO_CHAR(TO_DATE(T1.LAST_TX_DATE,'YYYYMMDD'),'YYYY-MM-DD'), '9999-12-31') END 
                WHEN T1.GL_ITEM_CODE in ('20110110','20110101','20110102','20110103','20110104','20110105','20110106','20110107','20110108','20110109') 
                    and T1.DEPARTMENTD = 'CH'        
              THEN CASE  WHEN T1.LAST_TX_DATE < T1.ACCT_OPDATE THEN TO_CHAR(TO_DATE(T1.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD') 
                         WHEN T1.LAST_TX_DATE > T1.ACCT_CLDATE THEN TO_CHAR(TO_DATE(T1.ACCT_CLDATE,'YYYYMMDD'),'YYYY-MM-DD')
                         ELSE NVL(TO_CHAR(TO_DATE(T1.LAST_TX_DATE,'YYYYMMDD'),'YYYY-MM-DD'), '9999-12-31') END  
                WHEN  T1.DEPARTMENTD = 'CH' 
              THEN CASE  WHEN T1.LAST_TX_DATE < T1.ACCT_OPDATE THEN TO_CHAR(TO_DATE(T1.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD') 
                         WHEN T1.LAST_TX_DATE > T1.ACCT_CLDATE THEN TO_CHAR(TO_DATE(T1.ACCT_CLDATE,'YYYYMMDD'),'YYYY-MM-DD') 
                         ELSE NVL(TO_CHAR(TO_DATE(T1.LAST_TX_DATE,'YYYYMMDD'),'YYYY-MM-DD'), '9999-12-31') end
                ELSE '9999-12-31' END         ,     -- 16 '上次动户日期'   east逻辑同步    
           TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')             ,
           CASE WHEN T1.GL_ITEM_CODE = '20110111' THEN '009803'
                ELSE T1.ORG_NUM
                 END    ,
       CASE WHEN T1.TX = '个人金融部' THEN '009821'
	        WHEN T1.TX = '公司金融部' THEN '0098JR'
	        WHEN T1.TX = '机构金融部' THEN '0098JYB'
	        ELSE '009820'
	         END, -- 业务条线
	   CASE WHEN substr(T4.TYPE_ID,1,8) IN ('62313113','62313118') THEN '04' -- 关联他行Ⅰ类户的Ⅱ类户通过第三方互联网平台
	        ELSE ''
	        END ,   -- 通过互联网吸收的存款类型
	       '0' AS H140020 -- 20250422 姜俐锋 删除 代码冗余 各项存款剔除项标识  ALTER BY WJB 20240706 2.0升级  码值设置为0.否，1.是 ；对于法人透支账户和其他不应计入各项存款的情况，码值选择为“1.是”
      FROM SMTMODS.L_ACCT_DEPOSIT T1 -- 存款账户信息表
      LEFT JOIN SMTMODS.L_FINA_INNER T3 -- 内部科目对照表
             ON TRIM(T1.GL_ITEM_CODE) = TRIM(T3.STAT_SUB_NUM)
            AND TRIM(T1.ORG_NUM) = T3.ORG_NUM
            AND T3.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_ACCT_DEPOSIT_SUB T4
             ON T1.ACCT_NUM = T4.ACCT_NUM 
            AND T4.DATA_DATE = I_DATE
            and T4.MEDIUM_STAT = 'A'
      LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
             ON T1.ORG_NUM = ORG.ORG_NUM
            AND ORG.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_ACCT_CARD_CREDIT T8 -- 关联信用卡账户表，取溢缴款的开户日期
             ON T1.ACCT_NUM = T8.ACCT_NUM
            AND T8.DATA_DATE =  I_DATE
     WHERE T1.DATA_DATE = I_DATE
	   and  SUBSTR(T1.GL_ITEM_CODE,1,4) in ('2011','2012','2013','2014','2010') -- [20251016]:财政性存款新科目 2010
	   AND org.ORG_NAM NOT LIKE '%村镇%'
	   AND T1.GL_ITEM_CODE IS NOT NULL 
	   AND SUBSTR(T1.ACCT_STS,1,3)<>'E01' -- EAST 表间校验 剔除预开户数据
	   AND SUBSTR(T1.GL_ITEM_CODE,1,6) <>  '224101'  -- 久悬.
	   and T1.GL_ITEM_CODE not in ('20110301','20110302','20110303','20110501','20110502','20110111','20050101') -- 0408 大为哥剔除-- 周敬坤 JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求  提出2005 科目  对应201105科目  总账由  20110501- 20110504  迁入20050101
	   and substr(T1.GL_ITEM_CODE,1,4) not in ('3010','3020')  -- 0408 大为哥剔除
	   -- [JLBA202507250003][20250909][巴启威]:增加同业存款
	   /*and T1.GL_ITEM_CODE not in ('20120101',
'20120102',
'20120103',
'20120104',
'20120105',
'20120107',
'20120108',
'20120109',
'20120110',
'20120111',
'20120201',
'20120202',
'20120203',
'20120205',
'20120206',
'20120207',
'20120208',
'20120209') -- 0418 按照大为哥口径剔除*/
      AND (T1.ACCT_CLDATE  >= SUBSTR(I_DATE,1,4)||'0101' /*销户日期*/-- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
           OR (T1.ACCT_CLDATE IS NULL /*AND T1.ACCT_BALANCE > 0*/ ) /*账户余额*/
           OR T1.ACCT_BALANCE > 0)  -- 20241031 ZJK UPDATE 出现一笔销户日期为空 余额为0的数据   修改 
        GROUP BY 
           T1.ACCT_NUM                               , -- 01 '分户账号'
           T1.ACCT_NUM                               , -- 18 '协议ID'
           T1.CUST_ID                                , -- 02 '客户ID'
           CASE WHEN T1.GL_ITEM_CODE = '20110111' THEN 'B0302H22201009803'
                ELSE ORG.ORG_ID
                 END                                 , -- 03 '机构ID'
           T1.CURR_CD                                , -- 04 '币种'
           T1.GL_ITEM_CODE                           , -- 05 '科目ID'
           CASE WHEN T1.GL_ITEM_CODE = '20110111' THEN '个人信用卡存款'
                ELSE T3.GL_CD_NAME
                 END                                 , -- 06 '科目名称'
           CASE 
            WHEN T4.ACCT_MED IN ('1','2','3','7') THEN '01' -- 卡
            WHEN T4.ACCT_MED = '5'  THEN '02'  -- 普通存折
	        WHEN T4.ACCT_MED = '6'  THEN '05'  -- 存单
	        WHEN T4.ACCT_MED = '11' THEN '08'  -- 无介质
	        ELSE '08' -- 无介质           
	         END                             , -- 07 '交易介质'  -- ALTER BY WJB 20240706 2.0升级修改
	       CASE WHEN T4.ACCT_MED IN ('1','2','3','5','6','7') THEN  T4.TYPE_ID 
	        ELSE ''
	         END                           , -- 08 '交易介质号'
           CASE 
             WHEN SUBSTR(T1.ACCT_TYPE,1,2) = '05' THEN '01' -- 活期
             WHEN T1.ACCT_TYPE = '0401' THEN '02' -- 一天通知存款
             WHEN T1.ACCT_TYPE = '0402' THEN '03' -- 七天通知存款
             WHEN otds_data.months_between(date(T1.MATUR_DATE),date(T1.ST_INT_DT)) <= 1   THEN '04'  -- 1个月
             WHEN otds_data.months_between(date(T1.MATUR_DATE),date(T1.ST_INT_DT)) <= 3   THEN '05'  -- 3个月
             WHEN otds_data.months_between(date(T1.MATUR_DATE),date(T1.ST_INT_DT)) <= 6  THEN '06'  -- 6个月
             WHEN otds_data.months_between(date(T1.MATUR_DATE),date(T1.ST_INT_DT)) <= 12  THEN '07' -- 12个月
             WHEN otds_data.months_between(date(T1.MATUR_DATE),date(T1.ST_INT_DT)) <= 18  THEN '08' -- 18个月
             WHEN otds_data.months_between(date(T1.MATUR_DATE),date(T1.ST_INT_DT)) <= 24  THEN '09' -- 24个月
             WHEN otds_data.months_between(date(T1.MATUR_DATE),date(T1.ST_INT_DT)) <= 36 THEN '10' -- 36个月
             WHEN otds_data.months_between(date(T1.MATUR_DATE),date(T1.ST_INT_DT)) <= 60 THEN '11' -- 60个月
             ELSE '12' -- 其他固定期限
           END                              , -- 09 '存款期限'
           CASE WHEN T1.GL_ITEM_CODE ='20110111' THEN NVL(TO_CHAR(TO_DATE(T8.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD') ,TO_CHAR(TO_DATE(T1.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD'))
	            ELSE (CASE WHEN T1.ACCT_OPDATE > I_DATE THEN TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')  
	                   ELSE TO_CHAR(TO_DATE(T1.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD')
	                    END) -- [20251028][巴启威][JLBA202509280009][吴大为]: 特殊处理开户日期跨日问题
                 END                             , -- 11 '开户日期'
           CASE WHEN T1.GL_ITEM_CODE ='20110111' THEN TO_CHAR(TO_DATE(T8.ACCT_CLDATE,'YYYYMMDD'),'YYYY-MM-DD')
	            ELSE TO_CHAR(TO_DATE(T1.ACCT_CLDATE,'YYYYMMDD'),'YYYY-MM-DD')
	             END                                 , -- 12 '销户日期'
	       CASE
               WHEN SUBSTR(T1.ACCT_STS, 1, 1) = 'N' THEN
                '01' -- '正常'
               WHEN SUBSTR(T1.ACCT_STS, 1, 1) = 'D' THEN
                '06' -- '其他-休眠'
               WHEN SUBSTR(T1.ACCT_STS, 1, 1) = 'C' THEN
                '03' -- '销户'
               WHEN SUBSTR(T1.ACCT_STS, 1, 1) = 'L' THEN
                '05' -- '止付'
               WHEN SUBSTR(T1.ACCT_STS, 1, 1) = 'W' THEN
                '04' -- '冻结'
               WHEN SUBSTR(T1.ACCT_STS, 1, 3) = 'E01' THEN
                '06' -- '其他-预开户'
               WHEN SUBSTR(T1.ACCT_STS, 1, 3) = 'E02' THEN
                '02' -- '预销户'
               WHEN SUBSTR(T1.ACCT_STS, 1, 1) = 'E99' THEN
                '06' -- '其他'
             END                             , -- 14 '账户状态'
           CASE 
              WHEN T1.ACCOUNT_CATA_FLG = '2' THEN '01' -- 钞
              WHEN T1.ACCOUNT_CATA_FLG = '3' THEN '02' -- 汇
              WHEN T1.ACCOUNT_CATA_FLG = '4' THEN '03' -- 可钞可汇
             END                                    , -- 17 '钞汇类别'
           TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')             , -- 15 '采集日期'
           CASE WHEN T1.DEPARTMENTD = 'TD' 
              THEN CASE WHEN T1.LAST_TX_DATE = '18000101' THEN TO_CHAR(TO_DATE(T1.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD')
                        WHEN T1.LAST_TX_DATE < T1.ACCT_OPDATE THEN  TO_CHAR(TO_DATE(T1.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD')
                        ELSE NVL(TO_CHAR(TO_DATE(T1.LAST_TX_DATE,'YYYYMMDD'),'YYYY-MM-DD'),TO_CHAR(TO_DATE(T1.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD')) END
                WHEN T1.DEPARTMENTD = 'CH' AND T1.ACCT_TYPE NOT IN ('0601', '0602') 
              THEN CASE WHEN T1.LAST_TX_DATE < T1.ACCT_OPDATE THEN TO_CHAR(TO_DATE(T1.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD')
                        WHEN T1.LAST_TX_DATE > T1.ACCT_CLDATE THEN TO_CHAR(TO_DATE(T1.ACCT_CLDATE,'YYYYMMDD'),'YYYY-MM-DD')
                        ELSE NVL(TO_CHAR(TO_DATE(T1.LAST_TX_DATE,'YYYYMMDD'),'YYYY-MM-DD'), '9999-12-31') END 
                WHEN T1.GL_ITEM_CODE in ('20110110','20110101','20110102','20110103','20110104','20110105','20110106','20110107','20110108','20110109') 
                    and T1.DEPARTMENTD = 'CH'        
              THEN CASE  WHEN T1.LAST_TX_DATE < T1.ACCT_OPDATE THEN TO_CHAR(TO_DATE(T1.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD') 
                         WHEN T1.LAST_TX_DATE > T1.ACCT_CLDATE THEN TO_CHAR(TO_DATE(T1.ACCT_CLDATE,'YYYYMMDD'),'YYYY-MM-DD')
                         ELSE NVL(TO_CHAR(TO_DATE(T1.LAST_TX_DATE,'YYYYMMDD'),'YYYY-MM-DD'), '9999-12-31') END  
                WHEN  T1.DEPARTMENTD = 'CH' 
              THEN CASE  WHEN T1.LAST_TX_DATE < T1.ACCT_OPDATE THEN TO_CHAR(TO_DATE(T1.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD') 
                         WHEN T1.LAST_TX_DATE > T1.ACCT_CLDATE THEN TO_CHAR(TO_DATE(T1.ACCT_CLDATE,'YYYYMMDD'),'YYYY-MM-DD') 
                         ELSE NVL(TO_CHAR(TO_DATE(T1.LAST_TX_DATE,'YYYYMMDD'),'YYYY-MM-DD'), '9999-12-31') end
                ELSE '9999-12-31' END         ,     -- 16 '上次动户日期'   east逻辑同步  
           TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')             ,
           CASE WHEN T1.GL_ITEM_CODE = '20110111' THEN '009803'
                ELSE T1.ORG_NUM
                 END    ,
       CASE WHEN T1.TX = '个人金融部' THEN '009821'
	        WHEN T1.TX = '公司金融部' THEN '0098JR'
	        WHEN T1.TX = '机构金融部' THEN '0098JYB'
	        ELSE '009820'
	         END, -- 业务条线
	   CASE WHEN substr(T4.TYPE_ID,1,8) IN ('62313113','62313118') THEN '04' -- 关联他行Ⅰ类户的Ⅱ类户通过第三方互联网平台
	        ELSE ''
	        END ,   -- 通过互联网吸收的存款类型
	       '0'
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