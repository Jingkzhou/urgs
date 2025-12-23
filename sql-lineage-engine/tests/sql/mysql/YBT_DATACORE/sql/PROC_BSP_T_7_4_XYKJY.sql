DROP Procedure IF EXISTS `PROC_BSP_T_7_4_XYKJY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_7_4_XYKJY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN

  /******
      程序名称  ：信用卡交易
      程序功能  ：加工信用卡交易
      目标表：T_7_3
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
	-- JLBA202412200001_关于一表通监管数据报送系统修改逻辑及转EAST脚本的需求_20250116
	-- JLBA202502200003_关于新增一表通7.8不良资产处置表信用卡核销数据的需求_20250415
    /*需求编号：JLBA202504060003 上线日期： 20250513，修改人：狄家卉，提出人：吴大为    关于一表通监管数据报送系统、EAST报送系统修改取数逻辑的需求*/

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
	SET P_PROC_NAME = 'PROC_BSP_T_7_4_XYKJY';
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
	
	DELETE FROM T_7_4 WHERE G040033 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
 INSERT  INTO T_7_4  
 (
       G040001   , -- 01 '交易ID'
       G040002   , -- 02 '卡号'
       G040003   , -- 03 '分户账号'
       G040004   , -- 04 '客户ID'
       G040005   , -- 05 '机构ID'
       G040006   , -- 06 '产品ID'
       G040007   , -- 07 '核心交易日期'
       G040008   , -- 08 '核心交易时间'
       G040009   , -- 09 '交易类型'
       G040010   , -- 10 '交易金额'
       G040011   , -- 11 '账户余额'
       G040012   , -- 12 '科目ID'
       G040013   , -- 13 '科目名称'
       G040014   , -- 14 '手续费金额'
       G040015   , -- 15 '币种'
       G040016   , -- 16 '手续费币种'
       G040017   , -- 17 '对方账号'
       G040018   , -- 18 '对方户名'
       G040019   , -- 19 '对方账号行号'
       G040020   , -- 20 '对方行名'
       G040021   , -- 21 '借贷标识'
       G040022   , -- 22 '商户编号'
       G040023   , -- 23 '商户名称'
       G040024   , -- 24 '线上线下交易标识'
       G040025   , -- 25 '分期业务ID'
       G040026   , -- 26 'IP地址'
       G040027   , -- 27 'MAC地址'
       G040028   , -- 28 '商户类别码'
       G040029   , -- 29 '商户类别码名称'
       G040030   , -- 30 '交易渠道'
       G040031   , -- 31 '交易摘要'
       G040032   , -- 32 '客户备注'
       G040033   , -- 33 '采集日期'
       DIS_DATA_DATE , -- 装入数据日期
       DIS_BANK_ID   , -- 机构号
       DIS_DEPT      ,
       DEPARTMENT_ID  -- 业务条线
)

    SELECT   
       T.REF_NUM                                , -- 01 '交易ID'
       T.CARD_NO                                , -- 02 '卡号'
       T.ACCT_NUM                               , -- 03 '分户账号'
       T1.CUST_ID                               , -- 04 '客户ID'
       -- ORG.ORG_ID                               , -- 05 '机构ID'
       'B0302H22201009803', -- 05 '机构ID' 20250116信用卡业务同意修改方案一表通所有涉及信用卡业务相关报表，机构全部默认009803
       T4.CP_ID                                 , -- 06 '产品ID'
       TO_CHAR(TO_DATE(T.TX_DT,'YYYYMMDD'),'YYYY-MM-DD'), -- 07 '核心交易日期'
       NVL(time_format(SUBSTR(T.TRADE_TIME,1,6),'%H:%i:%s'),'00:00:00') , -- 08 '核心交易时间'
       CASE
         WHEN T.TRANTYPE = '01' THEN '01'                    -- 消费
         -- WHEN T.TRANTYPE = '02' THEN '02'                    -- 现金
         WHEN T.TRANTYPE = '05' THEN '02'                    -- 现金  20240628 银数修改 
         WHEN T.TRANTYPE IN ('11','12','13','14') THEN '03'  -- 还款
         WHEN T.TRANTYPE = '03' THEN '04'                    -- 转账
         WHEN T.TRANTYPE IN ('21','31','41') THEN '05'       -- 其他
       END                                      , -- 09 '交易类型'
       T.TRANAMT                                , -- 10 '交易金额'
       T.JYHYE                                  , -- 11 '账户余额'
       -- T1.SUBJECT_NO                            , -- 12 '科目ID'
       -- T.KMBH                                   , -- 12 '科目ID'
       CASE
       WHEN T.KMBH = '9019813604000016' THEN
        '13060401'
       WHEN T.KMBH = '9019813301000012' THEN
        '11320113'
       WHEN T.KMBH = '9019813902000013' THEN
        '12210202'
       WHEN T.KMBH IS NULL THEN
        '30010801' -- 删除
       END, -- 明细科目编号                                                                  , -- 12 '科目ID' 20240628按照east修改
       -- '13030301'                               , -- 12 '科目ID' -- 默认科目 13030301-个人银行卡透支贷款本金
       --  A.GL_CD_NAME                             , -- 13 '科目名称'
       CASE
       WHEN T.KMBH = '9019813604000016' THEN
        '个人银行卡垫款本金'
       WHEN T.KMBH = '9019813301000012' THEN
        '个人银行卡垫款应收利息'
       WHEN T.KMBH = '9019813902000013' THEN
        '应收手续费挂账'
       WHEN T.KMBH IS NULL THEN
        '银联待清算款'
       END,                                         --  13  科目名称           20240628 按照east修改                                           
       -- '个人银行卡透支贷款本金'                  , -- 13 '科目名称' -- 默认科目 13030301-个人银行卡透支贷款本金
       -- T3.FEE_AMT                                , -- 14 '手续费金额'
       CASE WHEN T.SXFJE >0 THEN  T.SXFJE  ELSE 0 END  , -- 14 '手续费金额'
       T.CURR_CD                                , -- 15 '币种'
       -- T3.FEE_CURR_CD                            , -- 16 '手续费币种'
       'CNY'                                    , -- 16 '手续费币种' -- 默认空值
       -- T.OPPO_ACCT_NUM                          , -- 17 '对方账号'
       CASE WHEN T.XSXXJYBS='02' AND T.JYQD <> '04' THEN NULL
            WHEN XX.ACCT_NUM IS NOT NULL THEN XX.ACCT_NUM
            ELSE T.OPPO_ACCT_NUM
       END,                                       -- 17 '对方账号' -- ALTER BY WJB 20240927银数核对修改
       -- T.OPPO_ACCT_NAM                          , -- 18 '对方户名'
       CASE
       WHEN T.XSXXJYBS='02' AND T.JYQD <> '04' THEN NULL
       ELSE TRIM(T.OPPO_ACCT_NAM)
       END                                      , -- 18 '对方户名' -- ALTER BY WJB 20240927银数核对修改 
       -- substr(T.OPPO_BANK_NUM,1,12)             , -- 19 '对方账号行号'
       CASE
       WHEN T.OPPO_BANK_NUM IN ('Z2012911000011',
                                'Z2002131000014',
                                'Z2026742000018',
                                'Z2014811000011',
                                'Z2013811000010',
                                'Z2016211000010',
                                'Z2010632000017') THEN  
        NULL -- [20250513] [狄家卉] [JLBA202504060003][吴大为] 信用卡交易中的对方账号行号存的是对方的许可证号三方支付平台“抖音支付”“联动优势”“联动支付”“付费通”“天翼电子商务”“网银”“易付宝”为空
       WHEN T.XSXXJYBS='02' AND T.JYQD <> '04' THEN NULL
       WHEN T.JYQD IN ('09','10','11','12') THEN NULL
       ELSE T.OPPO_BANK_NUM
       END                                      , -- 19 '对方账号行号' -- ALTER BY WJB 20240927银数核对修改
       -- T.OPPO_BANK_NAME                         , -- 20 '对方行名'
       CASE
       WHEN T.XSXXJYBS='02' AND T.JYQD <> '04' THEN NULL
       ELSE T.OPPO_BANK_NAME
       END                                      , -- 20 '对方行名' -- ALTER BY WJB 20240927银数核对修改
       '0'||T.CD_TYPE                           , -- 21 '借贷标识'   01-借  02-贷
       T.MERCHANT_NUM                           , -- 22 '商户编号'
       T.MERCHANT_NAME                          , -- 23 '商户名称'
       T.XSXXJYBS                               , -- 24 '线上线下交易标识'  -- 新增字段
       T.FQYWID          						, -- 25 '分期业务ID'
       T.IP_ADDRESS                             , -- 26 'IP地址'
       -- substr(T.MAC_ADDRESS,1,17)               , -- 27 'MAC地址'
       T.MAC_ADDRESS                            , -- 27 'MAC地址' 20240628 按照east修改 
       -- T3.MCC                                    , -- 28 '商户类别码'
       -- T3.MERCHANT_NAME                          , -- 29 '商户类别码名称'
       -- T3.CHANNEL                                , -- 30 '交易渠道'
       T.SHLBM                                  , -- 28 '商户类别码' -- 新增字段
       T.SHLBMMC                                , -- 29 '商户类别码名称' -- 新增字段
       -- T.JYQD                                   , -- 30 '交易渠道' -- 新增字段
       CASE
         WHEN T.OPPO_BANK_NUM IN ('Z2012911000011',
                                  'Z2002131000014',
                                  'Z2026742000018',
                                  'Z2014811000011',
                                  'Z2013811000010',
                                  'Z2016211000010',
                                  'Z2010632000017') THEN
          '07' -- [20250513] [狄家卉] [JLBA202504060003][吴大为] 信用卡交易中的对方账号行号存的是对方的许可证号三方支付平台“抖音支付”“联动优势”“联动支付”“付费通”“天翼电子商务”“网银”“易付宝”第三方支付
         WHEN T.JYQD IN ('09', '10', '11', '12') THEN
          '07' -- 第三方支付
         ELSE
          T.JYQD
       END                                      , -- 30 '交易渠道' -- WJB 20240711 新增的09支付宝、10微信支付、11美团支付、12京东支付；转码转满足一表通发文的07第三方支付
       -- T.JYZY                                , -- 31 '交易摘要' -- 新增字段
       REPLACE(T.JYZY,'/','')                   , -- 31 '交易摘要' -- 去除特殊字符/
       T.KHBZ                                   , -- 32 '客户备注' -- 新增字段
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 33 '采集日期'
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
	   T.ORG_NUM                                       , -- 机构号
	   NULL,
	   '009803'                                          -- 业务条线  -- 信用卡中心
     FROM smtmods.L_TRAN_CARD_CREDIT_TX T  -- 信用卡交易信息表
    INNER JOIN smtmods.L_ACCT_CARD_CREDIT T1  -- 信用卡账户信息表
       ON T.ACCT_NUM = T1.ACCT_NUM
      AND T1.DATA_DATE = I_DATE
    INNER JOIN SMTMODS.L_AGRE_CARD_INFO T4 -- 卡基本信息表
       ON T.CARD_NO = T4.CARD_NO 
      AND T4.DATA_DATE = I_DATE
     LEFT JOIN SMTMODS.L_FINA_INNER A 
       ON T.KMBH = A.STAT_SUB_NUM
      AND T.ORG_NUM = A.ORG_NUM
      AND A.DATA_DATE = I_DATE
     LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
       ON T.ORG_NUM = ORG.ORG_NUM
      AND ORG.DATA_DATE = I_DATE
     LEFT JOIN (SELECT * FROM (SELECT X.TYPE_ID, X.ACCT_NUM, ROW_NUMBER() OVER(PARTITION BY X.TYPE_ID ORDER BY X.ACCT_NUM) AS NUM
                           FROM SMTMODS.L_ACCT_DEPOSIT_SUB X
                          WHERE X.DATA_DATE = I_DATE) XX 
                  WHERE NUM = '1') XX
       ON T.OPPO_ACCT_NUM = XX.TYPE_ID -- ALTER BY WJB 20240927银数核对修改
    WHERE T.DATA_DATE = I_DATE
	-- start add by haorui 20241119 JLBA202410090008信用卡收益权转让  
	  AND (T1.DEALDATE = I_DATE OR T1.DEALDATE ='00000000')  
	  AND NOT EXISTS (SELECT 1 FROM SMTMODS.L_ACCT_WRITE_OFF W WHERE W.DATA_DATE = I_DATE AND W.DATE_SOURCESD ='信用卡核销' AND T1.ACCT_NUM=W.ACCT_NUM) -- 20250415 JLBA202502200003 去掉核销部分  

	UNION ALL 
	SELECT   
       T.REF_NUM                                , -- 01 '交易ID'
       T.CARD_NO                                , -- 02 '卡号'
       T.ACCT_NUM                               , -- 03 '分户账号'
       T1.CUST_ID                               , -- 04 '客户ID'
       -- ORG.ORG_ID                               , -- 05 '机构ID'
       'B0302H22201009803', -- 05 '机构ID' 20250116信用卡业务同意修改方案一表通所有涉及信用卡业务相关报表，机构全部默认009803
       T4.CP_ID                                 , -- 06 '产品ID'
       TO_CHAR(TO_DATE(T.TX_DT,'YYYYMMDD'),'YYYY-MM-DD'), -- 07 '核心交易日期'
       NVL(time_format(SUBSTR(T.TRADE_TIME,1,6),'%H:%i:%s'),'00:00:00') , -- 08 '核心交易时间'
       CASE
         WHEN T.TRANTYPE = '01' THEN '01'                    -- 消费
         -- WHEN T.TRANTYPE = '02' THEN '02'                    -- 现金
         WHEN T.TRANTYPE = '05' THEN '02'                    -- 现金  20240628 银数修改 
         WHEN T.TRANTYPE IN ('11','12','13','14') THEN '03'  -- 还款
         WHEN T.TRANTYPE = '03' THEN '04'                    -- 转账
         WHEN T.TRANTYPE IN ('21','31','41') THEN '05'       -- 其他
       END                                      , -- 09 '交易类型'
       T.TRANAMT                                , -- 10 '交易金额'
       T.JYHYE                                  , -- 11 '账户余额'
       -- T1.SUBJECT_NO                            , -- 12 '科目ID'
       -- T.KMBH                                   , -- 12 '科目ID'
       CASE
       WHEN T.KMBH = '9019813604000016' THEN
        '13060401'
       WHEN T.KMBH = '9019813301000012' THEN
        '11320113'
       WHEN T.KMBH = '9019813902000013' THEN
        '12210202'
       WHEN T.KMBH IS NULL THEN
        '30010801' -- 删除
       END, -- 明细科目编号                                                                  , -- 12 '科目ID' 20240628按照east修改
       -- '13030301'                               , -- 12 '科目ID' -- 默认科目 13030301-个人银行卡透支贷款本金
       --  A.GL_CD_NAME                             , -- 13 '科目名称'
       CASE
       WHEN T.KMBH = '9019813604000016' THEN
        '个人银行卡垫款本金'
       WHEN T.KMBH = '9019813301000012' THEN
        '个人银行卡垫款应收利息'
       WHEN T.KMBH = '9019813902000013' THEN
        '应收手续费挂账'
       WHEN T.KMBH IS NULL THEN
        '银联待清算款'
       END,                                         --  13  科目名称           20240628 按照east修改                                           
       -- '个人银行卡透支贷款本金'                  , -- 13 '科目名称' -- 默认科目 13030301-个人银行卡透支贷款本金
       -- T3.FEE_AMT                                , -- 14 '手续费金额'
       case WHEN T.SXFJE >0 
       then  T.SXFJE 
       else 0 END                            , -- 14 '手续费金额'
       T.CURR_CD                                , -- 15 '币种'
       -- T3.FEE_CURR_CD                            , -- 16 '手续费币种'
       'CNY'                                    , -- 16 '手续费币种' -- 默认空值
       -- T.OPPO_ACCT_NUM                          , -- 17 '对方账号'
       CASE WHEN T.XSXXJYBS='02' AND T.JYQD <> '04' THEN NULL
            WHEN XX.ACCT_NUM IS NOT NULL THEN XX.ACCT_NUM
            ELSE T.OPPO_ACCT_NUM
       END,                                       -- 17 '对方账号' -- ALTER BY WJB 20240927银数核对修改
       -- T.OPPO_ACCT_NAM                          , -- 18 '对方户名'
       CASE
       WHEN T.XSXXJYBS='02' AND T.JYQD <> '04' THEN NULL
       ELSE TRIM(T.OPPO_ACCT_NAM)
       END                                      , -- 18 '对方户名' -- ALTER BY WJB 20240927银数核对修改 
       -- substr(T.OPPO_BANK_NUM,1,12)             , -- 19 '对方账号行号'
       CASE 
       WHEN T.OPPO_BANK_NUM IN ('Z2012911000011',
                                'Z2002131000014',
                                'Z2026742000018',
                                'Z2014811000011',
                                'Z2013811000010',
                                'Z2016211000010',
                                'Z2010632000017') THEN  
        NULL -- [20250513] [狄家卉] [JLBA202504060003][吴大为] 信用卡交易中的对方账号行号存的是对方的许可证号三方支付平台“抖音支付”“联动优势”“联动支付”“付费通”“天翼电子商务”“网银”“易付宝”为空
       WHEN T.XSXXJYBS='02' AND T.JYQD <> '04' THEN NULL
       WHEN T.JYQD IN ('09','10','11','12') THEN NULL
       ELSE T.OPPO_BANK_NUM
       END                                      , -- 19 '对方账号行号' -- ALTER BY WJB 20240927银数核对修改
       -- T.OPPO_BANK_NAME                         , -- 20 '对方行名'
       CASE
       WHEN T.XSXXJYBS='02' AND T.JYQD <> '04' THEN NULL
       ELSE T.OPPO_BANK_NAME
       END                                      , -- 20 '对方行名' -- ALTER BY WJB 20240927银数核对修改
       '0'||T.CD_TYPE                           , -- 21 '借贷标识'   01-借  02-贷
       T.MERCHANT_NUM                           , -- 22 '商户编号'
       T.MERCHANT_NAME                          , -- 23 '商户名称'
       T.XSXXJYBS                               , -- 24 '线上线下交易标识'  -- 新增字段
       T.FQYWID          						, -- 25 '分期业务ID'
       T.IP_ADDRESS                             , -- 26 'IP地址'
       -- substr(T.MAC_ADDRESS,1,17)               , -- 27 'MAC地址'
       T.MAC_ADDRESS                            , -- 27 'MAC地址' 20240628 按照east修改 
       -- T3.MCC                                    , -- 28 '商户类别码'
       -- T3.MERCHANT_NAME                          , -- 29 '商户类别码名称'
       -- T3.CHANNEL                                , -- 30 '交易渠道'
       T.SHLBM                                  , -- 28 '商户类别码' -- 新增字段
       T.SHLBMMC                                , -- 29 '商户类别码名称' -- 新增字段
       -- T.JYQD                                   , -- 30 '交易渠道' -- 新增字段
      CASE
         WHEN T.OPPO_BANK_NUM IN ('Z2012911000011',
                                  'Z2002131000014',
                                  'Z2026742000018',
                                  'Z2014811000011',
                                  'Z2013811000010',
                                  'Z2016211000010',
                                  'Z2010632000017') THEN
          '07' -- [20250513] [狄家卉] [JLBA202504060003][吴大为] 信用卡交易中的对方账号行号存的是对方的许可证号三方支付平台“抖音支付”“联动优势”“联动支付”“付费通”“天翼电子商务”“网银”“易付宝”第三方支付
         WHEN T.JYQD IN ('09', '10', '11', '12') THEN
          '07' -- 第三方支付
         ELSE
          T.JYQD
       END                           , -- 30 '交易渠道' -- WJB 20240711 新增的09支付宝、10微信支付、11美团支付、12京东支付；转码转满足一表通发文的07第三方支付
       -- T.JYZY                                   , -- 31 '交易摘要' -- 新增字段
       REPLACE(T.JYZY,'/','')                   , -- 31 '交易摘要' -- 去除特殊字符/
       T.KHBZ                                   , -- 32 '客户备注' -- 新增字段
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 33 '采集日期'
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
	   T.ORG_NUM                                       , -- 机构号
	   null,
	   '009803'                       
     FROM SMTMODS.L_TRAN_CARD_CREDIT_TX T  -- 信用卡交易信息表
    INNER JOIN SMTMODS.L_ACCT_CARD_CREDIT T1  -- 信用卡账户信息表
       ON T.ACCT_NUM = T1.ACCT_NUM
      AND T1.DATA_DATE = I_DATE
    INNER JOIN SMTMODS.L_AGRE_CARD_INFO T4 -- 卡基本信息表
       ON T.CARD_NO = T4.CARD_NO 
      AND T4.DATA_DATE = I_DATE
	 LEFT JOIN SMTMODS.L_ACCT_DEPOSIT A1
       ON T1.ACCT_NUM = A1.ACCT_NUM
	  AND A1.DATA_DATE=I_DATE 
	  AND A1.GL_ITEM_CODE ='20110111'
	 LEFT JOIN SMTMODS.L_ACCT_DEPOSIT A2
       ON T1.ACCT_NUM = A2.ACCT_NUM
	  AND A2.DATA_DATE=LAST_DT 
	  AND A2.GL_ITEM_CODE ='20110111'
     LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
       ON T.ORG_NUM = ORG.ORG_NUM
      AND ORG.DATA_DATE = I_DATE
     LEFT JOIN (SELECT * FROM (SELECT X.TYPE_ID, X.ACCT_NUM, ROW_NUMBER() OVER(PARTITION BY X.TYPE_ID ORDER BY X.ACCT_NUM) AS NUM
                           FROM SMTMODS.L_ACCT_DEPOSIT_SUB X
                          WHERE X.DATA_DATE = I_DATE) XX 
                  WHERE NUM = '1') XX
       ON T.OPPO_ACCT_NUM = XX.TYPE_ID
    WHERE T.DATA_DATE = I_DATE
	  AND T1.DEALDATE <> '00000000'
	  AND (A2.ACCT_NUM IS NOT NULL OR A2.ACCT_NUM IS NULL AND A1.ACCT_NUM IS NOT NULL)  -- 前一天有溢款款 或 前一天无溢缴款当有有溢缴款
	  AND NOT EXISTS (SELECT 1 FROM SMTMODS.L_ACCT_WRITE_OFF W WHERE W.DATA_DATE = I_DATE AND W.DATE_SOURCESD ='信用卡核销' AND T1.ACCT_NUM=W.ACCT_NUM) -- 20250415 JLBA202502200003 去掉核销部分  
	;
	-- end add by haorui 20241119 JLBA202410090008信用卡收益权转让
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

