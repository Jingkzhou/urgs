DROP Procedure IF EXISTS `PROC_BSP_T_8_5_XYKFQZT` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_8_5_XYKFQZT"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN

  /******
      程序名称  ：信用卡分期状态
      程序功能  ：加工信用卡分期状态
      目标表：T_8_5
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
/* 需求编号：JLBA202502200003 上线日期：20250415，修改人：姜俐锋，提出人：李逊昂,吴大为 
        修改原因：去掉信用卡核销数据*/	
/* 需求编号：JLBA202504060003 上线日期： 20250513，修改人：狄家卉，提出人：吴大为    关于一表通监管数据报送系统、EAST报送系统修改取数逻辑的需求*/
/*需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
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
	SET P_PROC_NAME = 'PROC_BSP_T_8_5_XYKFQZT';
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
	
	DELETE FROM T_8_5 WHERE H050018 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ;											
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
 INSERT INTO T_8_5
 (
   H050001    , -- 01 '分期业务ID'
   H050002    , -- 02 '卡号'
   H050003    , -- 03 '交易ID'
   H050004    , -- 04 '客户ID'
   H050019    , -- 19 '机构ID'
   H050005    , -- 05 '分期交易类型'
   H050006    , -- 06 '分期业务类型'
   H050007    , -- 07 '币种'
   H050008    , -- 08 '分期总额度'
   H050009    , -- 09 '可用分期额度'
   H050010    , -- 10 '分期金额'
   H050011    , -- 11 '分期期数'
   H050012    , -- 12 '分期利率'
   H050013    , -- 13 '办理分期日期'
   H050014    , -- 14 '办理分期时间'
   H050015    , -- 15 '分期转入卡号'
   H050020    , -- 20 '分期转入户名'
   H050016    , -- 16 '个性化分期标识'
   H050017    , -- 17 '提前结清标识'
   H050021    , -- 21 '分期余额'
   H050018    , -- 18 '采集日期' 
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID   , -- 机构号
   DIS_DEPT      ,
   DEPARTMENT_ID, -- 业务条线
   H050022         -- 逾期金额
          
  )
      SELECT 
           T.ACCT_NUM||T.INSTALLMENT_DATE||
	   CASE WHEN LENGTH( T.INSTALLMENT_TERM  ) = 1 THEN '00000'||T.INSTALLMENT_TERM
                WHEN LENGTH( T.INSTALLMENT_TERM  ) = 2 THEN '0000'||T.INSTALLMENT_TERM
                WHEN LENGTH( T.INSTALLMENT_TERM  ) = 3 THEN '000'||T.INSTALLMENT_TERM
                WHEN LENGTH( T.INSTALLMENT_TERM  ) = 4 THEN '00'||T.INSTALLMENT_TERM
                WHEN LENGTH( T.INSTALLMENT_TERM  ) = 5 THEN '0'||T.INSTALLMENT_TERM
                ELSE T.INSTALLMENT_TERM
                END            AS H050001 , -- 01 '分期业务ID'
           T.CARD_NO           AS H050002 , -- 02 '卡号'
           T.ACCT_NUM||T.INSTALLMENT_DATE||
           CASE WHEN LENGTH( T.INSTALLMENT_TERM  ) = 1 THEN '00000'||T.INSTALLMENT_TERM
                WHEN LENGTH( T.INSTALLMENT_TERM  ) = 2 THEN '0000'||T.INSTALLMENT_TERM
                WHEN LENGTH( T.INSTALLMENT_TERM  ) = 3 THEN '000'||T.INSTALLMENT_TERM
                WHEN LENGTH( T.INSTALLMENT_TERM  ) = 4 THEN '00'||T.INSTALLMENT_TERM
                WHEN LENGTH( T.INSTALLMENT_TERM  ) = 5 THEN '0'||T.INSTALLMENT_TERM
                ELSE T.INSTALLMENT_TERM
                END            AS H050003 , -- 03 '交易ID' 
           T.CUST_ID           AS H050004 , -- 04 '客户ID'
           'B0302H22201009803' AS H050019 , -- 19 '机构ID'
           CASE WHEN T.INSTAL_TRANS_TYPE IN ('D','Y')     THEN '01' -- 普通分期总额
                WHEN T.INSTAL_TRANS_TYPE IN ('A','H','P') THEN '02' -- 普通分期单笔
                WHEN T.INSTAL_TRANS_TYPE = 'L'            THEN '04' -- 专项分期单笔
                WHEN T.INSTAL_TRANS_TYPE IN ('B','W')     THEN '06' -- 现金分期单笔
                WHEN T.INSTAL_TRANS_TYPE ='G'             THEN '07' -- 其他   [20250513] [狄家卉] [JLBA202504060003][吴大为] 增加个性化分期 
                ELSE                                           '02' -- 普通分期单笔 -- 经业务确认，映射不到的部分都给普通分期单笔
                END            AS H050005 , -- 05 '分期交易类型'
           CASE WHEN t.INSTALLMENT_TYPE = 'A' THEN '02' -- 单笔消费分期
	  			WHEN t.INSTALLMENT_TYPE = 'B' THEN '03' -- 现金分期
			    WHEN t.INSTALLMENT_TYPE = 'D' THEN '11' -- 其他
	 			WHEN t.INSTALLMENT_TYPE = 'H' THEN '04' -- POS商户分期
	 			WHEN t.INSTALLMENT_TYPE = 'L' THEN '11' -- 其他
	 			WHEN t.INSTALLMENT_TYPE = 'P' THEN '05' -- 邮购电购分期
	 			WHEN t.INSTALLMENT_TYPE = 'W' THEN '03' -- 现金分期
	 			WHEN t.INSTALLMENT_TYPE = 'Y' THEN '01' -- 账单分期
	 		    WHEN t.INSTALLMENT_TYPE = 'G' THEN '11' -- 其他  [20250513] [狄家卉] [JLBA202504060003][吴大为] 增加个性化分期 
			    ELSE '11'  -- 其他 
	            END            AS H050006 , -- 06 '分期业务类型' -- ALTER BY WJB 20241010  业务李逊昂确认，改用分期类型判断，不再使用产品id
           CASE WHEN T.INSTALLMENT_CUR = '156' THEN 'CNY' END AS H050007 , -- 07 '币种'
           t.INSTAL_AMT        AS H050008 , -- 08 '分期总额度'
           CASE WHEN NVL(T.USE_INSTAL_AMT,0) < 0 THEN 0 ELSE NVL(T.USE_INSTAL_AMT,0) END AS H050009, -- 09 '可用分期额度'
           t.INSTALLMENT_TOTALLYAMT  AS H050010 , -- 10 '分期金额'
           T.INSTALLMENT_NUM               AS H050011 , -- 11 '分期期数'
           T.INSTALLMENT_RATE              AS H050012 , -- 12 '分期利率'
           TO_CHAR(TO_DATE(T.INSTALLMENT_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS H050013 , -- 13 '办理分期日期'
           SUBSTR( T.INSTALLMENT_TIME , 1, 2) || ':' || SUBSTR( T.INSTALLMENT_TIME, 3, 2) || ':' ||SUBSTR( T.INSTALLMENT_TIME , 5, 2) AS H050014, -- 14 '办理分期时间'
           T.FQZRKH                        AS H050015 , -- 15 '分期转入卡号'
           T.FQZRHM                        AS H050020 , -- 20 '分期转入户名'
           T.PERSON_INSTALLMENT_FLG        AS H050016 , -- 16 '个性化分期标识'
           T.TQJQBS                        AS H050017 , -- 17 '提前结清标识'
           T.INSTAL_BAL                    AS H050021 ,  -- 21 '分期余额'
           TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS H050018, -- 18 '采集日期'
           TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE, -- 装入数据日期
		   '009803'                        AS DIS_BANK_ID, -- 机构号	
		   NULL                            AS DIS_DEPT,
		   '009803'                        AS DEPARTMENT_ID ,                                          -- 业务条线  -- 信用卡中心
		  -- NULL 									    	 -- ADD BY WJB 20240624 一表通2.0升级 暂定默认为空
		   CASE WHEN T3.LXQKQS > 0 THEN T.INSTAL_BAL
                WHEN T3.LXQKQS = 0 THEN 0
                END                        AS H050022  -- 逾期金额   [20250513][狄家卉][JLBA202504060003][吴大为]: 信用卡账户逾期，分期表中所有对应业务都为逾期，逾期金额=分期余额
          FROM SMTMODS.L_TRAN_CARDINSTALLMENT_CREDIT T  -- 信用卡分期明细表
          LEFT JOIN SMTMODS.L_TRAN_CARDINSTALLMENT_CREDIT T2 -- 信用卡分期明细表
            ON T.ACCT_NUM||T.INSTALLMENT_DATE||T.INSTALLMENT_TERM = T2.ACCT_NUM||T2.INSTALLMENT_DATE||T2.INSTALLMENT_TERM
           AND T2.DATA_DATE = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD') - 1,'YYYYMMDD')
          LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE T1
            ON T1.L_CODE_TABLE_CODE = 'V0001' 
           AND T.CP_ID = T1.L_CODE
         INNER JOIN SMTMODS.L_ACCT_CARD_CREDIT T3 -- 关联信用卡账户表，去掉转卖
            ON T.ACCT_NUM = T3.ACCT_NUM
           AND T3.DATA_DATE = I_DATE    
		   -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
	     LEFT JOIN SMTMODS.L_TRAN_CARDINSTALLMENT_CREDIT T4 -- 信用卡分期明细表
            ON T.ACCT_NUM||T.INSTALLMENT_DATE||T.INSTALLMENT_TERM = T4.ACCT_NUM||T4.INSTALLMENT_DATE||T4.INSTALLMENT_TERM
           AND T2.DATA_DATE = CONCAT(YEAR(STR_TO_DATE(I_DATE, '%Y%m%d')) - 1, '1231') -- 去年末数据状态
         WHERE T.DATA_DATE = I_DATE 
           AND (NVL(T.INSTALLMENT_TYPE2,'#') <> 'C' OR (NVL(T.INSTALLMENT_TYPE2,'#') = 'C' AND NVL(T2.INSTALLMENT_TYPE2,'#') <> 'C') OR  NVL(T4.INSTALLMENT_TYPE2,'#') <> 'C' ) -- 用分期业务类型2卡结清状态（银数提供逻辑）-- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
		   AND (T3.DEALDATE = I_DATE OR T3.DEALDATE ='00000000')  -- ADD BY HAORUI 20241119 JLBA202410090008信用卡收益权转让 START
	       AND NOT EXISTS (SELECT 1 FROM SMTMODS.L_ACCT_WRITE_OFF W WHERE W.DATA_DATE = I_DATE AND W.DATE_SOURCESD ='信用卡核销'AND W.WRITE_OFF_DATE <> I_DATE AND T.ACCT_NUM=W.ACCT_NUM)-- [20250415][姜俐锋][JLBA202502200003][李逊昂,吴大为]: 去掉核销部分  
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


