DROP Procedure IF EXISTS `PROC_BSP_T_7_8_BLZCCZ` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_7_8_BLZCCZ"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回CODE
                                         OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
                                         )
BEGIN
/******
      程序名称  ：不良资产处置
      程序功能  ：加工不良资产处置
      目标表：T_7_8
      源表  ：
      创建人  ：LZ
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
	 -- JLBA202409120001_关于一表通监管数据报送系统修改逻辑的需求_二期 20241128	 将数据范围修改为全年
 	 /* 需求编号：JLBA202502200003 上线日期：20250415，修改人：姜俐锋，提出人：李逊昂,吴大为 
                     修改原因：  新增一表通7.8不良资产处置表信用卡核销数据*/
	-- JLBA202505280002 上线日期：2025-06-19，修改人：巴启威  提出人：吴大为  修改原因：因一表通校验问题发现的代码逻辑调整
	 /*需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
	 /*需求编号：JLBA202507250003 上线日期：2025-09-09，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统修改取数逻辑的需求*/
	 /*需求编号：JLBA202509280009 上线日期：2025-10-28，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统修改逻辑的需求 */
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
	SET P_PROC_NAME = 'PROC_BSP_T_7_8_BLZCCZ';
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
	
	DELETE FROM T_7_8 WHERE G080023 = TO_CHAR(P_DATE,'YYYY-MM-DD');
	-- DELETE FROM T_7_8_TMP1 WHERE G080023 = TO_CHAR(P_DATE,'YYYY-MM-DD'); -- 20241128
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';

-- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求：7.8报送范围调整为每日增量
-- JLBA202409120001 20241128 由增量改为全量数据 新增T_7_8_TMP 表

/* JLBA202505280002 上线日期：2025-06-19，修改人：巴启威  提出人：吴大为  修改原因：因一表通校验问题发现的代码逻辑调整:
现金清收	还款当期五级分类为不良
向上迁徙	还款上期为五级分类不良还款当期为五级分类正常
资产转让-批量转让	资产转让
核销	批量转让损失核销(完全回收不报送）
核销后回收	核销后有回收金额*/


	     set gcluster_hash_redistribute_join_optimize = 1;
        
 
-- 信贷资产转让、以物抵债    
 INSERT  INTO T_7_8  (
  G080001,  -- 01.交易
  G080002,  -- 02.机构
  G080003,  -- 03.借据
  G080004,  -- 04.协议
  G080005,  -- 05.客户
  G080006,  -- 06.资产类型
  G080007,  -- 07.处置类型
  G080008,  -- 08.处置日期
  G080009,  -- 09.处置时资产本金余额
  G080010,  -- 10.处置时表内利息余额
  G080011,  -- 11.处置时表外利息余额
  -- G080012,  -- 12.处置后不良资产减少金额
  G080013,  -- 13.处置收回资产金额
  G080014,  -- 14.处置收回表内利息金额
  G080015,  -- 15.处置收回表外利息金额
  G080016,  -- 16.转让资产名称
  G080017,  -- 17.转让资产协议
  G080018,  -- 18.收回标识
  G080019,  -- 19.处置员工
  G080020,  -- 20.处置收回日期
  G080021,  -- 21.处置状态
  G080022,  -- 22.币种
  G080023,  -- 23.采集日期
  DIS_DATA_DATE,
  DIS_BANK_ID,
  DEPARTMENT_ID ,
  G080024,
  G080025,
  DIS_DEPT
)                          
     SELECT 
            A.TRANS_CON_NUM , -- 交易ID
            J.ORG_ID , -- 机构ID
            T.LOAN_NUM , -- 借据ID
            A.TRANS_CON_NUM , -- 协议ID
            T.CUST_ID , -- 客户ID
            CASE  
             WHEN SUBSTR(T.ITEM_CD,1,6) IN ('130301','302002') THEN '01' -- 个人贷款
             WHEN SUBSTR(T.ITEM_CD,1,6) IN ('130302','302001') THEN '02' -- 对公贷款 
             ELSE '09' -- 其他
              END AS ZCLX , -- 资产类型
            CASE 
             WHEN TX_TYPE = '信贷资产转让' THEN '31'  -- 31-资产转让-批量转让
             ELSE 
             '35' END AS G080007 , -- 35-资产转让-其他资产转让
            TO_CHAR( TO_DATE( A.TRANS_CON_DUE_DATE,'YYYYMMDD') ,'YYYY-MM-DD'), -- 处置日期
            NULL , -- 处置时资产本金余额 B.TRANS_LOAN_AMT
            NULL , -- 处置时表内利息余额T.OD_INT
            NULL , -- 处置时表外利息余额T.OD_INT_OBS
            -- A.TRANS_LOAN_AMT , -- 处置后不良资产减少金额
            B.TRANS_LOAN_AMT , -- 处置收回资产金额
            0 , -- 处置收回表内利息金额
            A.TRANS_LOAN_INT, -- 处置收回表外利息金额
            A.TRANS_CON_NUM , -- 转让资产名称
            A.TRANS_CON_NUM , -- 转让资产协议ID
            '03' , -- 收回标识
            A.JBYG_ID , -- 处置员工ID
            NVL(TO_CHAR( TO_DATE( A.TRANS_CON_DUE_DATE ,'YYYYMMDD') ,'YYYY-MM-DD'),'9999-12-31')  , -- 处置收回日期
            CASE WHEN (T.OD_LOAN_ACCT_BAL + T.OD_INT_OBS + T.OD_INT) > 0 THEN '01'
            ELSE '02'
            END AS CZZT, -- 21 处置状态 
            T.CURR_CD , -- 币种
            TO_CHAR( P_DATE ,'YYYY-MM-DD'),
            TO_CHAR( P_DATE ,'YYYY-MM-DD'),
            T.ORG_NUM,
            CASE  
             WHEN T.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
             WHEN T.DEPARTMENTD ='公司金融' OR SUBSTR(T.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
             WHEN T.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
             WHEN T.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
             WHEN SUBSTR(T.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
             WHEN SUBSTR(T.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
             END AS TX,
             SUBSTR(COALESCE (T.LOAN_PURPOSE_CD,T8.CORP_BUSINSESS_TYPE,T7.CORP_TYP),1,4),
            A.JBYG_ID ,
            '信贷资产转让'
       FROM SMTMODS.L_ACCT_LOAN T
      INNER JOIN SMTMODS.L_ACCT_TRANSFER_RELATION B
         ON T.LOAN_NUM = B.LOAN_NUM
        AND T.DATA_DATE = B.DATA_DATE 
      INNER JOIN SMTMODS.L_ACCT_TRANSFER A
         ON B.TRANS_CON_NUM = A.TRANS_CON_NUM
        AND T.DATA_DATE = A.DATA_DATE 
        AND A.TX_TYPE NOT LIKE '行内机构划转%'
       LEFT JOIN VIEW_L_PUBL_ORG_BRA J  -- 机构表
         ON T.ORG_NUM = J.ORG_NUM
        AND J.DATA_DATE = I_DATE  
       LEFT JOIN SMTMODS.L_CUST_P t7
         ON t.CUST_ID = t7.CUST_ID
        AND T7.DATA_DATE = I_DATE
       LEFT JOIN SMTMODS.L_CUST_C t8
         ON t.CUST_ID = t8.CUST_ID
        AND T8.DATA_DATE = I_DATE   
      WHERE T.DATA_DATE = I_DATE 
        AND A.TRANS_CON_DUE_DATE =I_DATE;  --  --  [20250619][巴启威][JLBA202505280002][吴大为]： 取处置日期当天数据
COMMIT;

 -- 1 信贷现金清收:还款当期五级分类为不良
 INSERT  INTO T_7_8  (
  G080001,  -- 01.交易
  G080002,  -- 02.机构
  G080003,  -- 03.借据
  G080004,  -- 04.协议
  G080005,  -- 05.客户
  G080006,  -- 06.资产类型
  G080007,  -- 07.处置类型
  G080008,  -- 08.处置日期
  G080009,  -- 09.处置时资产本金余额
  G080010,  -- 10.处置时表内利息余额
  G080011,  -- 11.处置时表外利息余额
  -- G080012,  -- 12.处置后不良资产减少金额
  G080013,  -- 13.处置收回资产金额
  G080014,  -- 14.处置收回表内利息金额
  G080015,  -- 15.处置收回表外利息金额
  G080016,  -- 16.转让资产名称
  G080017,  -- 17.转让资产协议
  G080018,  -- 18.收回标识
  G080019,  -- 19.处置员工
  G080020,  -- 20.处置收回日期
  G080021,  -- 21.处置状态
  G080022,  -- 22.币种
  G080023,  -- 23.采集日期
  DIS_DATA_DATE,
  DIS_BANK_ID,
  DEPARTMENT_ID,
  G080024,
  G080025,
  DIS_DEPT
)  
       
	   SELECT 
             T2.TX_NO,  -- 01 交易ID
             substr(TRIM(T6.FIN_LIN_NUM ),1,11)|| T2.ORG_NUM,  -- 02 机构ID
             T1.LOAN_NUM, -- 03 借据ID
             T1.ACCT_NUM, -- 04 协议ID
             T1.CUST_ID, -- 05客户ID
             CASE  
             WHEN SUBSTR(T1.ITEM_CD,1,6) IN ('130301','302002') THEN '01' -- 个人贷款
             WHEN SUBSTR(T1.ITEM_CD,1,6) IN ('130302','302001') THEN '02' -- 对公贷款
           --  ELSE '06' 
              ELSE '09'
             -- 其他  -- update 20240929  zjk 根据2.0修改为其他09
             END , -- 06资产类型 
             '20' as G080007 ,  -- 07现金清收
             NVL(TO_CHAR( to_date(T7.REPAY_DT,'yyyymmdd') ,'YYYY-MM-DD'),'9999-12-31') , -- 08 处置日期 
             T1.LOAN_ACCT_BAL, -- 09 处置时资产本金余额
             T1.OD_INT,  -- 10 处置时表内利息余额
             T1.OD_INT_OBS,  -- 11 处置时表外利息余额
             /* CASE WHEN T4.LOAN_GRADE_CD IN ('3','4','5') AND  T1.LOAN_GRADE_CD IN ('1','2') THEN T1.LOAN_ACCT_BAL
                  ELSE T2.PAY_AMT
                   END  ,*/ -- 12 处置后不良资产减少金额
             T2.PAY_AMT , -- 13 处置收回资产金额
             T2.PAY_INT_AMT , -- 14 处置收回表内利息金额
             T2.BWLX , -- 15 处置收回表外利息金额
             NULL , -- 16 转让资产名称
             -- T1.ACCT_NUM , -- 17 转让资产协议ID
             null , -- 因校验公式YBT_JYG08-33 修改
             '03' , -- 18 收回标识
             T1.JBYG_ID , -- 19 处置员工ID
             NVL(TO_CHAR( to_date(T2.REPAY_DT,'yyyymmdd') ,'YYYY-MM-DD'),'9999-12-31'), -- 20 处置收回日期
             CASE WHEN (T1.OD_LOAN_ACCT_BAL + T1.OD_INT_OBS + T1.OD_INT) > 0 THEN '01'
             ELSE '02'
             END AS CZZT, -- 21 处置状态
             T1.CURR_CD ,  -- 22 币种
             TO_CHAR( P_DATE ,'YYYY-MM-DD'),
             TO_CHAR( P_DATE ,'YYYY-MM-DD'),
             T1.ORG_NUM,
             CASE  
             WHEN T1.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
             WHEN T1.DEPARTMENTD ='公司金融' OR SUBSTR(T1.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
             WHEN T1.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
             WHEN T1.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
             WHEN SUBSTR(T1.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
             WHEN SUBSTR(T1.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
             END AS TX,
             --  SUBSTR(COALESCE (T1.LOAN_PURPOSE_CD,T8.CORP_BUSINSESS_TYPE,T9.CORP_TYP),1,4),
                --  企业客户取行业 cust_c 账户类型 LIKE '0102' 取贷款投向 ELSE NULL
             CASE WHEN T8.CUST_ID IS NOT NULL THEN T8.CORP_BUSINSESS_TYPE
                  WHEN T1.ACCT_TYP LIKE '0102%' THEN t1.LOAN_PURPOSE_CD 
                  end G080024,
             T1.JBYG_ID ,
             '现金清收'
        FROM SMTMODS.L_ACCT_LOAN T1 -- 贷款借据信息表 
       INNER JOIN SMTMODS.L_TRAN_LOAN_PAYM T2 -- 贷款还款明细信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS.L_ACCT_TRANSFER_RELATION T3 -- 信贷资产转让表(信贷资产变动因素表)
          ON T1.LOAN_NUM = T3.LOAN_NUM
         and T1.ORG_NUM=T3.ORG_NUM
         AND T1.DATA_DATE = T3.DATA_DATE
        LEFT JOIN SMTMODS.L_ACCT_TRANSFER T5 -- 信贷资产变动关系表
          ON T3.TRANS_CON_NUM=T5.TRANS_CON_NUM
         and T1.ORG_NUM=T5.ORG_NUM
         AND T3.DATA_DATE=T5.DATA_DATE     
        LEFT JOIN VIEW_L_PUBL_ORG_BRA T6  -- 机构表
          ON T1.ORG_NUM =  T6.ORG_NUM
         AND T6.DATA_DATE = I_DATE  
        LEFT JOIN (SELECT DISTINCT j.LOAN_NUM,j.REPAY_DT FROM smtmods.L_TRAN_LOAN_PAYM j WHERE data_date=I_DATE) t7
          ON t1.LOAN_NUM = t7.LOAN_NUM
        LEFT JOIN SMTMODS.L_CUST_P t9
          ON t1.CUST_ID = t9.CUST_ID
         AND T9.DATA_DATE = I_DATE
        LEFT JOIN SMTMODS.L_CUST_C t8
          ON t1.CUST_ID = t8.CUST_ID
         AND T8.DATA_DATE = I_DATE   
       WHERE T1.DATA_DATE = I_DATE
         AND T1.LOAN_GRADE_CD IN ('3','4','5')
         AND (T2.REPAY_DT =  TO_CHAR(TO_DATE(SUBSTR(I_DATE,1,4)||'0101','YYYYMMDD') -1 ,'YYYYMMDD')
              OR T2.REPAY_DT = I_DATE)
         AND NOT EXISTS(SELECT A.LOAN_NUM,A.WRITE_OFF_DATE -- 核销日期
                FROM SMTMODS.L_ACCT_WRITE_OFF A -- 贷款核销
                WHERE A.DATA_DATE = I_DATE
                  AND A.WRITE_OFF_DATE < I_DATE
                  AND A.LOAN_NUM = T1.LOAN_NUM )
         AND (SUBSTR(T1.ITEM_CD,1,6) IN ('130302','130301')  -- 公司贷款 , 个人贷款  
           OR SUBSTR(T1.ITEM_CD,1,4) IN ('1305','1306','7140'))  --  贸易融资  ,垫款  ,银团         --  [20250619][巴启威][JLBA202505280002][吴大为]：增加取数范围限制
         AND t7.REPAY_DT = I_DATE;   --  [20250619][巴启威][JLBA202505280002][吴大为]： 处置日期当天
   COMMIT;          
        
 -- 2 向上迁徙：信贷向上迁徙:还款上期为五级分类不良还款当期为五级分类正常
       INSERT  INTO T_7_8  (
  G080001,  -- 01.交易
  G080002,  -- 02.机构
  G080003,  -- 03.借据
  G080004,  -- 04.协议
  G080005,  -- 05.客户
  G080006,  -- 06.资产类型
  G080007,  -- 07.处置类型
  G080008,  -- 08.处置日期
  G080009,  -- 09.处置时资产本金余额
  G080010,  -- 10.处置时表内利息余额
  G080011,  -- 11.处置时表外利息余额
  -- G080012,  -- 12.处置后不良资产减少金额
  G080013,  -- 13.处置收回资产金额
  G080014,  -- 14.处置收回表内利息金额
  G080015,  -- 15.处置收回表外利息金额
  G080016,  -- 16.转让资产名称
  G080017,  -- 17.转让资产协议
  G080018,  -- 18.收回标识
  G080019,  -- 19.处置员工
  G080020,  -- 20.处置收回日期
  G080021,  -- 21.处置状态
  G080022,  -- 22.币种
  G080023,  -- 23.采集日期
  DIS_DATA_DATE,
  DIS_BANK_ID,
  DEPARTMENT_ID ,
  G080024,
  G080025,
  DIS_DEPT
)                
        SELECT  
             T2.TX_NO,  -- 01 交易ID
             substr(TRIM(T7.FIN_LIN_NUM ),1,11)|| T1.ORG_NUM,  -- 02 机构ID
             T1.LOAN_NUM, -- 03 借据ID
             T1.ACCT_NUM, -- 04 协议ID
             T1.CUST_ID, -- 05客户ID
             CASE  
             WHEN SUBSTR(T1.ITEM_CD,1,6) IN ('130301','302002') THEN '01' -- 个人贷款
             WHEN SUBSTR(T1.ITEM_CD,1,6) IN ('130302','302001') THEN '02' -- 对公贷款 
             --  ELSE '06' 
              ELSE '09'
             -- 其他  -- update 20240929  zjk 根据2.0修改为其他09
             END , -- 06资产类型 
             '10' , -- 07 处置类型
             NVL(TO_CHAR( to_date(T8.REPAY_DT ,'yyyymmdd') ,'YYYY-MM-DD'),'9999-12-31')  , -- 08 处置日期 
             T1.LOAN_ACCT_BAL, -- 09 处置时资产本金余额
             T1.OD_INT,  -- 10 处置时表内利息余额
             T1.OD_INT_OBS,  -- 11 处置时表外利息余额
             /*CASE WHEN T4.LOAN_GRADE_CD IN ('3','4','5') AND  T1.LOAN_GRADE_CD IN ('1','2') THEN T1.LOAN_ACCT_BAL
                       ELSE T2.PAY_AMT
                         END */   -- 12 处置后不良资产减少金额
             T2.PAY_AMT , -- 13 处置收回资产金额
             T2.PAY_INT_AMT , -- 14 处置收回表内利息金额
             T2.BWLX , -- 15 处置收回表外利息金额
             NULL , -- 16 转让资产名称
             -- T1.ACCT_NUM , -- 17 转让资产协议ID
             null , -- 因校验公式YBT_JYG08-33 修改
             '01' , -- 18 收回标识
             T1.JBYG_ID , -- 19 处置员工ID
             NVL(TO_CHAR( to_date( T2.REPAY_DT,'yyyymmdd') ,'YYYY-MM-DD'),'9999-12-31') , -- 20 处置收回日期
             CASE WHEN (T1.OD_LOAN_ACCT_BAL + T1.OD_INT_OBS + T1.OD_INT) > 0 THEN '01'
             ELSE '02'
             END AS CZZT, -- 21 处置状态 
             T1.CURR_CD ,  -- 22 币种
             TO_CHAR( P_DATE ,'YYYY-MM-DD'),
             TO_CHAR( P_DATE ,'YYYY-MM-DD'),
             T1.ORG_NUM,
           CASE  
           WHEN T1.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
           WHEN T1.DEPARTMENTD ='公司金融' OR SUBSTR(T1.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
           WHEN T1.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
           WHEN T1.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
           WHEN SUBSTR(T1.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
           WHEN SUBSTR(T1.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
           END AS TX,
            -- SUBSTR(COALESCE (T1.LOAN_PURPOSE_CD,T10.CORP_BUSINSESS_TYPE,T9.CORP_TYP),1,4),
           CASE WHEN T10.CUST_ID IS NOT NULL THEN T10.CORP_BUSINSESS_TYPE
                WHEN T1.ACCT_TYP LIKE '0102%' THEN t1.LOAN_PURPOSE_CD 
                end G080024,
           T1.JBYG_ID ,
           '向上迁徙'
        FROM SMTMODS.L_ACCT_LOAN T1 -- 贷款借据信息表
       INNER JOIN SMTMODS.L_TRAN_LOAN_PAYM T2 -- 贷款还款明细信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS.L_ACCT_TRANSFER_RELATION T3 -- 信贷资产转让表(信贷资产变动因素表)
          ON T1.LOAN_NUM = T3.LOAN_NUM
         and T1.ORG_NUM=T3.ORG_NUM
         AND T1.DATA_DATE = T3.DATA_DATE
        LEFT JOIN SMTMODS.L_ACCT_LOAN T4
          ON T1.LOAN_NUM = T4.LOAN_NUM
         AND T4.DATA_DATE = TO_CHAR( P_DATE - 1,'YYYYMMDD')
        LEFT JOIN SMTMODS.L_ACCT_TRANSFER T6 -- 信贷资产变动关系表
          ON T3.TRANS_CON_NUM=T6.TRANS_CON_NUM
         and T1.ORG_NUM = T6.ORG_NUM
         AND T3.DATA_DATE=T6.DATA_DATE  
        LEFT JOIN VIEW_L_PUBL_ORG_BRA T7  -- 机构表
          ON T1.ORG_NUM =  T7.ORG_NUM
         AND T7.DATA_DATE = I_DATE  
        LEFT JOIN (SELECT DISTINCT j.LOAN_NUM,j.REPAY_DT FROM smtmods.L_TRAN_LOAN_PAYM j WHERE data_date=I_DATE) t8
          ON t1.LOAN_NUM = t8.LOAN_NUM
        LEFT JOIN SMTMODS.L_CUST_P t9
          ON t1.CUST_ID = t9.CUST_ID
         AND T9.DATA_DATE = I_DATE
        LEFT JOIN SMTMODS.L_CUST_C t10
          ON t1.CUST_ID = t10.CUST_ID
         AND T10.DATA_DATE = I_DATE   
       WHERE T1.DATA_DATE = I_DATE
         AND (SUBSTR(T1.ITEM_CD,1,6) IN ('130302','130301')  -- 公司贷款 , 个人贷款 
           OR SUBSTR(T1.ITEM_CD,1,4) IN ('1305','1306','7140'))  --  贸易融资  ,垫款  ,银团   --  [20250619][巴启威][JLBA202505280002][吴大为]：增加取数范围限制
         AND T1.LOAN_GRADE_CD IN ('1','2')
         AND T4.LOAN_GRADE_CD IN ('3','4','5') ;  --  [20250619][巴启威][JLBA202505280002][吴大为]：与前一天对比五级分类状态;
         COMMIT;
             
             
 -- 3 核销-批量转让损失核销 
     INSERT  INTO T_7_8  (
  G080001,  -- 01.交易
  G080002,  -- 02.机构
  G080003,  -- 03.借据
  G080004,  -- 04.协议
  G080005,  -- 05.客户
  G080006,  -- 06.资产类型
  G080007,  -- 07.处置类型
  G080008,  -- 08.处置日期
  G080009,  -- 09.处置时资产本金余额
  G080010,  -- 10.处置时表内利息余额
  G080011,  -- 11.处置时表外利息余额
  -- G080012,  -- 12.处置后不良资产减少金额
  G080013,  -- 13.处置收回资产金额
  G080014,  -- 14.处置收回表内利息金额
  G080015,  -- 15.处置收回表外利息金额
  G080016,  -- 16.转让资产名称
  G080017,  -- 17.转让资产协议
  G080018,  -- 18.收回标识
  G080019,  -- 19.处置员工
  G080020,  -- 20.处置收回日期
  G080021,  -- 21.处置状态
  G080022,  -- 22.币种
  G080023,  -- 23.采集日期
  DIS_DATA_DATE,
  DIS_BANK_ID,
  DEPARTMENT_ID ,
  G080024,
  G080025,
  DIS_DEPT
)          
	SELECT 
		  T2.TX_NO||'41',    -- 01 交易ID
		  substr(TRIM(T6.FIN_LIN_NUM ),1,11)|| T1.ORG_NUM,  -- 02 机构ID
		  T1.LOAN_NUM, -- 03 借据ID
          T1.ACCT_NUM, -- 04 协议ID
          T1.CUST_ID,  -- 05客户ID
          CASE WHEN T12.ASSET_TYPE = 'A' THEN '01' -- 个人贷款
               WHEN T12.ASSET_TYPE = 'B' THEN '02' -- 对公贷款
               WHEN T12.ASSET_TYPE = 'C' THEN '04' -- 信用卡贷款  -- update 20240929  zjk 根据2.0将个人信用卡贷款由 03 修改为04 个人
               WHEN T12.ASSET_TYPE = 'D' THEN '05' -- 非信贷类债权 -- update 20240929  zjk 根据2.0将 债权修改由04 修改为05
               WHEN T12.ASSET_TYPE = 'E' THEN '08' -- 股权-- update 20240929  zjk 根据2.0将 股权修改由04 修改为08
               END  , -- 06资产类型   20240629 按east修改-- update 20240929  zjk 根据2.0修改为其他09
          '41' , -- 07 处置类型
          NVL(TO_CHAR( TO_DATE( T12.WRITE_OFF_DATE,'YYYYMMDD') ,'YYYY-MM-DD') ,'9999-12-31') , -- 08 处置日期 
          t12.DRAWDOWN_AMT , -- 09处置时资产本金余额  20240629 按east修改
          T1.OD_INT,  -- 10 处置时表内利息余额
          T12.ACCRUAL_OBS, -- 11处置时表外利息余额  20240629 按east修改
          NULL , -- 13处置收回资产金额
          NULL , -- 14处置收回表内利息金额
          NULL , -- 15 处置收回表外利息金额
          NULL , -- 16 转让资产名称
          -- T1.ACCT_NUM, -- 17 转让资产协议ID
          NULL , -- 17 转让资产协议ID 因校验公式YBT_JYG08-33 修改
          NULL ,-- 18 收回标识  20240629 按east修改
          t12.RETRIEVE_EMP_ID, -- 19 处置员工ID  20240629 按east修改
          NULL , -- 20 处置收回日期
          CASE WHEN T12.WRITE_OFF_STS = 'A' THEN '03' -- '账销案存'
               WHEN T12.WRITE_OFF_STS = 'B' THEN '04' -- '完全终结'
               END AS HXZT, -- 21 处置状态      20240629 按east修改
         T1.CURR_CD ,  -- 22 币种
         TO_CHAR( P_DATE ,'YYYY-MM-DD'), 
         TO_CHAR( P_DATE ,'YYYY-MM-DD'),
         T1.ORG_NUM,
         CASE  
           WHEN T1.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
           WHEN T1.DEPARTMENTD ='公司金融' OR SUBSTR(T1.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
           WHEN T1.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
           WHEN T1.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
           WHEN SUBSTR(T1.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
           WHEN SUBSTR(T1.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
          END AS TX  ,
         SUBSTR(COALESCE (T1.LOAN_PURPOSE_CD,T8.CORP_BUSINSESS_TYPE,T7.CORP_TYP),1,4),
         T12.RETRIEVE_EMP_ID ,
         '核销-批量转让损失核销'
        FROM SMTMODS.L_ACCT_LOAN T1 
       INNER JOIN SMTMODS.L_TRAN_LOAN_PAYM T2 -- 贷款还款明细信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
         AND T2.PAY_TYPE='08' -- JLBA202409120001 20241128
        LEFT JOIN SMTMODS.L_ACCT_TRANSFER_RELATION T3 -- 信贷资产转让表(信贷资产变动因素表)
          ON T1.LOAN_NUM = T3.LOAN_NUM
         and T1.ORG_NUM = T3.ORG_NUM
         AND T1.DATA_DATE = T3.DATA_DATE
        LEFT JOIN  SMTMODS.L_ACCT_TRANSFER T5 -- 信贷资产变动关系表
          ON T3.TRANS_CON_NUM=T5.TRANS_CON_NUM
         and T1.ORG_NUM = T5.ORG_NUM
         AND T3.DATA_DATE=T5.DATA_DATE  
        LEFT JOIN VIEW_L_PUBL_ORG_BRA T6  -- 机构表
          ON T1.ORG_NUM =  T6.ORG_NUM
         AND T6.DATA_DATE = I_DATE 
        LEFT JOIN SMTMODS.L_CUST_P t7
          ON t1.CUST_ID = t7.CUST_ID
         AND T7.DATA_DATE = I_DATE
        LEFT JOIN SMTMODS.L_CUST_C t8
          ON t1.CUST_ID = t8.CUST_ID
         AND T8.DATA_DATE = I_DATE   
       INNER JOIN (SELECT T.*,
             		ROW_NUMBER() OVER(PARTITION BY T.ORG_NUM, T.LOAN_NUM ORDER BY T.RETRIEVE_NO DESC) AS RN
        		   FROM SMTMODS.L_ACCT_WRITE_OFF T
      			   WHERE T.DATA_DATE = I_DATE  
      			     AND T.WRITE_OFF_DATE=I_DATE  --   --  [20250619][巴启威][JLBA202505280002][吴大为]：取核销当天
      			     ) T12
          ON T1.LOAN_NUM = T12.LOAN_NUM
       LEFT JOIN (SELECT T1.LOAN_NUM,
                        SUM(NVL(T1.RETRIEVE_AMT, 0)) AS SHBJ, -- 收回本金
                        SUM(NVL(RETRIEVE_INT, 0) + NVL(RETRIEVE_INT_OBS, 0)) AS SHLX -- 收回利息
                   FROM SMTMODS.L_ACCT_WRITE_OFF T1
                  WHERE T1.DATA_DATE = I_DATE
                  GROUP BY T1.ORG_NUM, T1.LOAN_NUM) A2 -- 资产核销(金额类字段分组求和)
        ON T12.LOAN_NUM = A2.LOAN_NUM   
       WHERE T1.DATA_DATE = I_DATE 
       AND (SUBSTR(T1.ITEM_CD,1,6) IN ('130302','130301')  -- 公司贷款 , 个人贷款 
           OR SUBSTR(T1.ITEM_CD,1,4) IN ('1305','1306','7140'))  --  贸易融资  ,垫款  ,银团   --  [20250619][巴启威][JLBA202505280002][吴大为]：增加取数范围限制
       AND T12.RN = 1 
       
       UNION ALL
 --   --  [20250619][巴启威][JLBA202505280002][吴大为]：增加核销-已核销收回   
   SELECT 
	   T2.TX_NO||'70',    -- 01 交易ID
	   substr(TRIM(T6.FIN_LIN_NUM ),1,11)|| T1.ORG_NUM,  -- 02 机构ID
	   T1.LOAN_NUM, -- 03 借据ID
       T1.ACCT_NUM, -- 04 协议ID
       T1.CUST_ID,  -- 05客户ID
       CASE WHEN T12.ASSET_TYPE = 'A' THEN '01' -- 个人贷款
            WHEN T12.ASSET_TYPE = 'B' THEN '02' -- 对公贷款
            WHEN T12.ASSET_TYPE = 'C' THEN '04' -- 信用卡贷款  -- update 20240929  zjk 根据2.0将个人信用卡贷款由 03 修改为04 个人
            WHEN T12.ASSET_TYPE = 'D' THEN '05' -- 非信贷类债权 -- update 20240929  zjk 根据2.0将 债权修改由04 修改为05
            WHEN T12.ASSET_TYPE = 'E' THEN '08' -- 股权-- update 20240929  zjk 根据2.0将 股权修改由04 修改为08
            END  ,
       '70' , -- 07 处置类型
       NULL , -- 08 处置日期 
       NULL , -- 09处置时资产本金余额  20240629 按east修改
       NULL ,  -- 10 处置时表内利息余额
       NULL , -- 11处置时表外利息余额  20240629 按east修改 
       A2.SHBJ , -- 13处置收回资产金额
       A2.SHLX , -- 14处置收回表内利息金额
       T2.BWLX , -- 15 处置收回表外利息金额
       NULL , -- 16 转让资产名称 
       null , -- 17 转让资产协议ID 因校验公式YBT_JYG08-33 修改
       CASE WHEN t12.DRAWDOWN_AMT + t12.ACCRUAL + t12.ACCRUAL_OBS = A2.SHBJ + A2.SHLX THEN   '03'  -- 完全回收
            WHEN A2.SHBJ + A2.SHLX = 0 THEN  '01' -- 未回收
            ELSE  '02' -- 部分回收
            END ,-- 18 收回标识  20240629 按east修改
       t12.RETRIEVE_EMP_ID, -- 19 处置员工ID  20240629 按east修改
       NVL(TO_CHAR( to_date( T2.REPAY_DT,'yyyymmdd') ,'YYYY-MM-DD'),'9999-12-31') , -- 20 处置收回日期
       CASE WHEN T12.WRITE_OFF_STS = 'A' THEN  '03' -- '账销案存'
             WHEN T12.WRITE_OFF_STS = 'B' THEN '04' -- '完全终结'
             END AS HXZT, -- 21 处置状态      20240629 按east修改
       T1.CURR_CD ,  -- 22 币种
       TO_CHAR( P_DATE ,'YYYY-MM-DD'), 
       TO_CHAR( P_DATE ,'YYYY-MM-DD'),
       T1.ORG_NUM,
       CASE  
         WHEN T1.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
         WHEN T1.DEPARTMENTD ='公司金融' OR SUBSTR(T1.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
         WHEN T1.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
         WHEN T1.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
         WHEN SUBSTR(T1.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
         WHEN SUBSTR(T1.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
         END AS TX  ,
       SUBSTR(COALESCE (T1.LOAN_PURPOSE_CD,T8.CORP_BUSINSESS_TYPE,T7.CORP_TYP),1,4),
       t12.RETRIEVE_EMP_ID ,
       '核销-已核销收回'
        FROM SMTMODS.L_ACCT_LOAN T1 
       INNER JOIN SMTMODS.L_TRAN_LOAN_PAYM T2 -- 贷款还款明细信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
         AND T2.PAY_TYPE='08' -- JLBA202409120001 20241128
        LEFT JOIN SMTMODS.L_ACCT_TRANSFER_RELATION T3 -- 信贷资产转让表(信贷资产变动因素表)
          ON T1.LOAN_NUM = T3.LOAN_NUM
         and T1.ORG_NUM = T3.ORG_NUM
         AND T1.DATA_DATE = T3.DATA_DATE
        LEFT JOIN  SMTMODS.L_ACCT_TRANSFER T5 -- 信贷资产变动关系表
          ON T3.TRANS_CON_NUM=T5.TRANS_CON_NUM
         and T1.ORG_NUM = T5.ORG_NUM
         AND T3.DATA_DATE=T5.DATA_DATE  
        LEFT JOIN VIEW_L_PUBL_ORG_BRA T6  -- 机构表
          ON T1.ORG_NUM =  T6.ORG_NUM
         AND T6.DATA_DATE = I_DATE 
        LEFT JOIN SMTMODS.L_CUST_P t7
          ON t1.CUST_ID = t7.CUST_ID
         AND T7.DATA_DATE = I_DATE
        LEFT JOIN SMTMODS.L_CUST_C t8
          ON t1.CUST_ID = t8.CUST_ID
         AND T8.DATA_DATE = I_DATE   
       INNER JOIN (SELECT T.*,
             		ROW_NUMBER() OVER(PARTITION BY T.ORG_NUM, T.LOAN_NUM ORDER BY T.RETRIEVE_NO DESC) AS RN
        		   FROM SMTMODS.L_ACCT_WRITE_OFF T
      			   WHERE T.DATA_DATE = I_DATE  
      			     AND T.RETRIEVE_DATE=I_DATE  -- 取核销回收当天
      			     ) T12
          ON T1.LOAN_NUM = T12.LOAN_NUM
        LEFT JOIN (SELECT T1.LOAN_NUM,
                        SUM(NVL(T1.RETRIEVE_AMT, 0)) AS SHBJ, -- 收回本金
                        SUM(NVL(RETRIEVE_INT, 0) + NVL(RETRIEVE_INT_OBS, 0)) AS SHLX -- 收回利息
                   FROM SMTMODS.L_ACCT_WRITE_OFF T1
                  WHERE T1.DATA_DATE = I_DATE
                  GROUP BY T1.ORG_NUM, T1.LOAN_NUM) A2 -- 资产核销(金额类字段分组求和)
          ON T12.LOAN_NUM = A2.LOAN_NUM   
       WHERE T1.DATA_DATE = I_DATE 
         AND (SUBSTR(T1.ITEM_CD,1,6) IN ('130302','130301')  -- 公司贷款 , 个人贷款 
           OR SUBSTR(T1.ITEM_CD,1,4) IN ('1305','1306','7140'))  --  贸易融资  ,垫款  ,银团   --  [20250619][巴启威][JLBA202505280002][吴大为]：增加取数范围限制
         AND (A2.SHBJ > 0 OR A2.SHLX > 0)
         AND T12.RN = 1;
         
   COMMIT;
        
--  -- 2 向上迁徙：信用卡向上迁徙:还款上期为五级分类不良还款当期为五级分类正常     
        
  INSERT INTO T_7_8  (
  G080001,  -- 01.交易
  G080002,  -- 02.机构
  G080003,  -- 03.借据
  G080004,  -- 04.协议
  G080005,  -- 05.客户
  G080006,  -- 06.资产类型
  G080007,  -- 07.处置类型
  G080008,  -- 08.处置日期
  G080009,  -- 09.处置时资产本金余额
  G080010,  -- 10.处置时表内利息余额
  G080011,  -- 11.处置时表外利息余额
  -- G080012,  -- 12.处置后不良资产减少金额
  G080013,  -- 13.处置收回资产金额
  G080014,  -- 14.处置收回表内利息金额
  G080015,  -- 15.处置收回表外利息金额
  G080016,  -- 16.转让资产名称
  G080017,  -- 17.转让资产协议
  G080018,  -- 18.收回标识
  G080019,  -- 19.处置员工
  G080020,  -- 20.处置收回日期
  G080021,  -- 21.处置状态
  G080022,  -- 22.币种
  G080023,  -- 23.采集日期
  DIS_DATA_DATE,
  DIS_BANK_ID,
  DEPARTMENT_ID ,
  G080024,
  G080025,
  DIS_DEPT
)                          
        SELECT  
             substr(replace((t.CARD_NO || T.ISSUE_NUMBER ||'10' || rand()),'.',''),1,100),  -- 01 交易ID
             'B0302H22201009803' ,  -- 02 机构ID
             T.CARD_NO, -- 03 借据ID
             T.ACCT_NUM, -- 04 协议ID
             T.CUST_ID, -- 05客户ID 
             '04' , -- 06资产类型  UPDATE 20241121 ZJK  2.0正式版修改码值
             '10' , -- 07 处置类型
             TO_CHAR( P_DATE ,'YYYY-MM-DD') , -- 08 处置日期 
             T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 + T1.M6_UP , -- 09 处置时资产本金余额
             T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 + T1.M6_UP , -- 10 处置时表内利息余额
             T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 + T1.M6_UP , -- 11 处置时表外利息余额
             -- NULL , -- 12 处置后不良资产减少金额
             NULL , -- 13 处置收回资产金额
             NULL , -- 14 处置收回表内利息金额
             NULL , -- 15 处置收回表外利息金额
             NULL , -- 16 转让资产名称
             NULL , -- 17 转让资产协议ID
             NULL , -- 18 收回标识
             -- T.JBYG_ID  , -- 19 处置员工ID
             '自动', -- 19 处置员工ID [JLBA202507250003][20250909][巴启威]:与李逊昂确认默认为'自动'
             '9999-12-31' , -- 20 处置收回日期
             '01' , -- 21 处置状态
             T.CURR_CD ,  -- 22 币种
             TO_CHAR( P_DATE ,'YYYY-MM-DD'),
             TO_CHAR( P_DATE ,'YYYY-MM-DD'),
             '009803' ,
             '009803' ,	  -- 信用卡中心 
             NULL , --  SUBSTR(T7.CORP_TYP,1,4), 20250113
             -- T.JBYG_ID ,
             '自动',  -- 25 处置员工ID [JLBA202507250003][20250909][巴启威]:与李逊昂确认默认为'自动'
             '信用卡向上迁移'
        FROM SMTMODS.L_ACCT_CARD_CREDIT T  -- 信用卡账户信息表 
        LEFT JOIN SMTMODS.L_ACCT_CARD_CREDIT T1  
          ON T.CARD_NO = T1.CARD_NO
         AND T1.DATA_DATE = TO_CHAR(P_DATE - 1,'YYYYMMDD')
       WHERE t.data_date = I_DATE
         AND (t.LXQKQS  = 0 OR t.LXQKQS IN (1,2,3))
         AND T.DEALDATE ='00000000'
         AND T1.LXQKQS >= 4;  --  [20250619][巴启威][JLBA202505280002][吴大为]：与前一天对比五级分类状态
  
  /*     
  LXQKQS = 0 THEN 正常
  LXQKQS IN (1,2,3) THEN 关注
  LXQKQS = 4 THEN 次级
  LXQKQS IN 5 6 THEN 可疑
  LXQKQS > 6 THEN 损失 
    */  
     COMMIT; 
     
     
 -- 20250415 [20250415][姜俐锋][JLBA202502200003][李逊昂,吴大为]: 新增信用卡核销与核销后转让部分数据
INSERT INTO T_7_8  (
  G080001,  -- 01.交易
  G080002,  -- 02.机构
  G080003,  -- 03.借据
  G080004,  -- 04.协议
  G080005,  -- 05.客户
  G080006,  -- 06.资产类型
  G080007,  -- 07.处置类型
  G080008,  -- 08.处置日期
  G080009,  -- 09.处置时资产本金余额
  G080010,  -- 10.处置时表内利息余额
  G080011,  -- 11.处置时表外利息余额 
  G080013,  -- 13.处置收回资产金额
  G080014,  -- 14.处置收回表内利息金额
  G080015,  -- 15.处置收回表外利息金额
  G080016,  -- 16.转让资产名称
  G080017,  -- 17.转让资产协议
  G080018,  -- 18.收回标识
  G080019,  -- 19.处置员工
  G080020,  -- 20.处置收回日期
  G080021,  -- 21.处置状态
  G080022,  -- 22.币种
  G080023,  -- 23.采集日期
  DIS_DATA_DATE,
  DIS_BANK_ID,
  DEPARTMENT_ID,
  G080024,
  G080025,
  DIS_DEPT )              
 -- 信用卡核销 
 SELECT 
  substr((T.ACCT_NUM||T.WRITE_OFF_DATE||'46'|| RAND()),1,100) AS G080001,  -- 01.交易
  G.ORG_ID                     AS G080002,  -- 02.机构
  T.LOAN_NUM                   AS G080003,  -- 03.借据
  T.ACCT_NUM                   AS G080004,  -- 04.协议
  T.CUST_ID                    AS G080005,  -- 05.客户
  '04'                         AS G080006,  -- 06.资产类型
  '46'                         AS G080007,  -- 07.处置类型
  TO_CHAR(TO_DATE(T.WRITE_OFF_DATE,'YYYYMMDD') ,'YYYY-MM-DD') AS G080008,  -- 08.处置日期
  T.DRAWDOWN_AMT               AS G080009,  -- 09.处置时资产本金余额
  T.ACCRUAL                    AS G080010,  -- 10.处置时表内利息余额
  T.ACCRUAL_OBS                AS G080011,  -- 11.处置时表外利息余额 
  NULL                         AS G080013,  -- 13.处置收回资产金额
  NULL                         AS G080014,  -- 14.处置收回表内利息金额
  NULL                         AS G080015,  -- 15.处置收回表外利息金额
  NULL                         AS G080016,  -- 16.转让资产名称
  NULL                         AS G080017,  -- 17.转让资产协议
  '01'                         AS G080018,  -- 18.收回标识 
  NULL                         AS G080019,  -- 19.处置员工
  NULL                         AS G080020,  -- 20.处置收回日期  -- 20250415 信用卡核销 没有处置收回日期
  '03'                         AS G080021,  -- 21.处置状态
  T.CURR_CD                    AS G080022,  -- 22.币种
  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD') ,'YYYY-MM-DD')  AS G080023,  -- 23.采集日期
  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD') ,'YYYY-MM-DD')  AS DIS_DATA_DATE,
  '009803'                     AS DIS_BANK_ID,
  '009803'                     AS DEPARTMENT_ID ,
  NULL                         AS G080024,
  nvl(E.EMP_ID,'自动')         AS G080025,  -- 20250421 根据业务新口径修改取数逻辑
  '信用卡核销'                  AS DIS_DEPT
  FROM SMTMODS.L_ACCT_WRITE_OFF T
  LEFT JOIN VIEW_L_PUBL_ORG_BRA G  -- 机构表
    ON T.ORG_NUM = G.ORG_NUM
   AND G.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_PUBL_EMP E  -- 20250421 根据业务新口径修改取数逻辑
    ON E.EMP_ID = T.RETRIEVE_EMP_ID
   AND E.DATA_DATE = I_DATE
 WHERE T.DATA_DATE = I_DATE 
   AND T.WRITE_OFF_DATE = I_DATE   --  [20250619][巴启威][JLBA202505280002][吴大为]： 处置日期当天
   AND EXISTS (SELECT 1 FROM SMTMODS.L_ACCT_CARD_CREDIT W WHERE W.DATA_DATE = I_DATE AND T.ACCT_NUM=W.ACCT_NUM) -- [20250415][姜俐锋][JLBA202502200003][李逊昂,吴大为]: 新增核销部分  
 UNION ALL 
 -- 信用卡核销后回收
 SELECT 
  substr((T.ACCT_NUM||T.RETRIEVE_DATE||'70' || RAND()),1,100) AS G080001,  -- 01.交易
  G.ORG_ID                     AS G080002,  -- 02.机构
  T.LOAN_NUM                   AS G080003,  -- 03.借据
  T.ACCT_NUM                   AS G080004,  -- 04.协议
  T.CUST_ID                    AS G080005,  -- 05.客户
  '04'                         AS G080006,  -- 06.资产类型
  '70'                         AS G080007,  -- 07.处置类型
  TO_CHAR(TO_DATE(T.RETRIEVE_DATE,'YYYYMMDD') ,'YYYY-MM-DD') AS G080008,  -- 08.处置日期
  NULL                         AS G080009,  -- 09.处置时资产本金余额
  NULL                         AS G080010,  -- 10.处置时表内利息余额
  NULL                         AS G080011,  -- 11.处置时表外利息余额 
  T.RETRIEVE_AMT               AS G080013,  -- 13.处置收回资产金额
  T.RETRIEVE_INT               AS G080014,  -- 14.处置收回表内利息金额
  T.RETRIEVE_INT_OBS           AS G080015,  -- 15.处置收回表外利息金额
  NULL                         AS G080016,  -- 16.转让资产名称
  NULL                         AS G080017,  -- 17.转让资产协议
  CASE WHEN T.RETRIEVE_FLG ='A' THEN '01'
       WHEN T.RETRIEVE_FLG ='B' THEN '02'
       WHEN T.RETRIEVE_FLG ='C' THEN '03'
       END                     AS G080018,  -- 18.收回标识 
  nvl(E.EMP_ID,'自动')         AS G080019,  -- 19.收回员工ID -- 20250421 根据业务新口径修改取数逻辑
  TO_CHAR(TO_DATE(T.RETRIEVE_DATE,'YYYYMMDD') ,'YYYY-MM-DD') AS G080020,  -- 20.处置收回日期
  '03'                         AS G080021,  -- 21.处置状态
  T.CURR_CD                    AS G080022,  -- 22.币种
  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD') ,'YYYY-MM-DD')  AS G080023,  -- 23.采集日期
  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD') ,'YYYY-MM-DD')  AS DIS_DATA_DATE,
  '009803'                     AS DIS_BANK_ID,
  '009803'                     AS DEPARTMENT_ID ,
  NULL                         AS G080024,
  NULL                         AS G080025, -- 25.处置员工ID
  '信用卡核销后回收'            AS DIS_DEPT
  FROM SMTMODS.L_ACCT_WRITE_OFF T
  LEFT JOIN VIEW_L_PUBL_ORG_BRA G  -- 机构表
    ON T.ORG_NUM = G.ORG_NUM
   AND G.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_PUBL_EMP E -- 20250421 根据业务新口径修改取数逻辑
    ON E.EMP_ID = T.RETRIEVE_EMP_ID
   AND E.DATA_DATE = I_DATE
 WHERE T.DATA_DATE = I_DATE
   -- AND T.RETRIEVE_FLG <>'C' -- 完全回收不报
   AND nvl(T.RETRIEVE_AMT,0)+ nvl(T.RETRIEVE_INT,0) > 0
   AND T.RETRIEVE_DATE = I_DATE  --  [20250619][巴启威][JLBA202505280002][吴大为]： 处置日期当天
   AND EXISTS (SELECT 1 FROM SMTMODS.L_ACCT_CARD_CREDIT W WHERE W.DATA_DATE = I_DATE AND T.ACCT_NUM=W.ACCT_NUM) ; -- [20250415][姜俐锋][JLBA202502200003][李逊昂,吴大为]: 新增核销后转让部分  
  
     COMMIT;
     
     
     
     
   -- 20250526 姜俐锋新增信用卡转让部分数据加工
  INSERT INTO T_7_8  (
  G080001,  -- 01.交易
  G080002,  -- 02.机构
  G080003,  -- 03.借据
  G080004,  -- 04.协议
  G080005,  -- 05.客户
  G080006,  -- 06.资产类型
  G080007,  -- 07.处置类型
  G080008,  -- 08.处置日期
  G080009,  -- 09.处置时资产本金余额
  G080010,  -- 10.处置时表内利息余额
  G080011,  -- 11.处置时表外利息余额 
  G080013,  -- 13.处置收回资产金额
  G080014,  -- 14.处置收回表内利息金额
  G080015,  -- 15.处置收回表外利息金额
  G080016,  -- 16.转让资产名称
  G080017,  -- 17.转让资产协议
  G080018,  -- 18.收回标识
  G080019,  -- 19.处置员工
  G080020,  -- 20.处置收回日期
  G080021,  -- 21.处置状态
  G080022,  -- 22.币种
  G080023,  -- 23.采集日期
  DIS_DATA_DATE,
  DIS_BANK_ID,
  DEPARTMENT_ID ,
  G080024,
  G080025,
  DIS_DEPT
)                          
        SELECT  
             substr(REPLACE((T.CARD_NO || T.ISSUE_NUMBER ||'10' || RAND()),'.',''),1,100) , -- 01 交易ID
             'B0302H22201009803' ,  -- 02 机构ID
             T.CARD_NO, -- 03 借据ID
             T.ACCT_NUM, -- 04 协议ID
             T.CUST_ID, -- 05客户ID 
             '04' , -- 06资产类型  UPDATE 20241121 ZJK  2.0正式版修改码值
             '31' , -- 07 处置类型
             NULL , -- 08 处置日期 
             NULL , -- 09 处置时资产本金余额
             NULL , -- 10 处置时表内利息余额
             NULL , -- 11 处置时表外利息余额 
             T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP , -- 13 处置收回资产金额
             T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP , -- 14 处置收回表内利息金额
             T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP , -- 15 处置收回表外利息金额
             NULL , -- 16 转让资产名称
             NULL , -- 17 转让资产协议ID
             NULL , -- 18 收回标识
          -- T.JBYG_ID  , -- 19 处置员工ID 
             '自动'     , -- 19 处置员工ID [JLBA202507250003][20250909][巴启威]:与李逊昂确认默认为'自动'
             '9999-12-31' , -- 20 处置收回日期
             '01' , -- 21 处置状态
             T.CURR_CD ,  -- 22 币种
             TO_CHAR( P_DATE ,'YYYY-MM-DD'),
             TO_CHAR( P_DATE ,'YYYY-MM-DD'),
             '009803' ,
             '009803' ,	  -- 信用卡中心 
             NULL , --  SUBSTR(T7.CORP_TYP,1,4), 20250113
          -- T.JBYG_ID ,
             '自动'     , -- 25 处置员工ID [JLBA202507250003][20250909][巴启威]:与李逊昂确认默认为'自动'
             '信用卡转让'
        FROM SMTMODS.L_ACCT_CARD_CREDIT T  -- 信用卡账户信息表  
       WHERE T.DATA_DATE = I_DATE
         AND T.DEALDATE = I_DATE;
     COMMIT;
       
     
  -- 20250526 姜俐锋新增信用卡现金清收部分数据加工     
 INSERT INTO T_7_8  (
  G080001,  -- 01.交易
  G080002,  -- 02.机构
  G080003,  -- 03.借据
  G080004,  -- 04.协议
  G080005,  -- 05.客户
  G080006,  -- 06.资产类型
  G080007,  -- 07.处置类型
  G080008,  -- 08.处置日期
  G080009,  -- 09.处置时资产本金余额
  G080010,  -- 10.处置时表内利息余额
  G080011,  -- 11.处置时表外利息余额
  -- G080012,  -- 12.处置后不良资产减少金额
  G080013,  -- 13.处置收回资产金额
  G080014,  -- 14.处置收回表内利息金额
  G080015,  -- 15.处置收回表外利息金额
  G080016,  -- 16.转让资产名称
  G080017,  -- 17.转让资产协议
  G080018,  -- 18.收回标识
  G080019,  -- 19.处置员工
  G080020,  -- 20.处置收回日期
  G080021,  -- 21.处置状态
  G080022,  -- 22.币种
  G080023,  -- 23.采集日期
  DIS_DATA_DATE,
  DIS_BANK_ID,
  DEPARTMENT_ID ,
  G080024,
  G080025,
  DIS_DEPT
)         
       SELECT   
             replace((t.CARD_NO || T.tx_dt ||T.trade_time||'10'),'.','') AS JYID,  -- 01 交易ID
             'B0302H22201009803' ,  -- 02 机构ID
             T1.CARD_NO, -- 03 借据ID
             T1.ACCT_NUM, -- 04 协议ID
             T1.CUST_ID, -- 05客户ID 
             '04' , -- 06资产类型  UPDATE 20241121 ZJK  2.0正式版修改码值
             '20' , -- 07 处置类型
             TO_CHAR( P_DATE ,'YYYY-MM-DD') , -- 08 处置日期 
             T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 + T1.M6_UP , -- 09 处置时资产本金余额
             T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 + T1.M6_UP , -- 10 处置时表内利息余额
             T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 + T1.M6_UP , -- 11 处置时表外利息余额 
             T.TRANAMT , -- 13 处置收回资产金额
             NULL , -- 14 处置收回表内利息金额
             NULL , -- 15 处置收回表外利息金额
             NULL , -- 16 转让资产名称
             NULL , -- 17 转让资产协议ID
             NULL , -- 18 收回标识
             '自动'  , -- 19 处置员工ID [20251028][巴启威][JLBA202509280009][吴大为]: 默认为自动
             '9999-12-31' , -- 20 处置收回日期
             '01' , -- 21 处置状态
             T1.CURR_CD ,  -- 22 币种
             TO_CHAR( P_DATE ,'YYYY-MM-DD'),
             TO_CHAR( P_DATE ,'YYYY-MM-DD'),
             '009803' ,
             '009803' ,   -- 信用卡中心 
             NULL , --  SUBSTR(T7.CORP_TYP,1,4), 20250113
             '自动' , --  [20251028][巴启威][JLBA202509280009][吴大为]: 默认为自动
             '信用卡现金清收'
            FROM SMTMODS.L_TRAN_CARD_CREDIT_TX T -- 信用卡交易信息表 
           INNER JOIN SMTMODS.L_ACCT_CARD_CREDIT T1  -- 信用卡账户信息表 
              ON T.ACCT_NUM = T1.ACCT_NUM
             AND T1.LXQKQS >= 4
             AND T1.DEALDATE ='00000000'
             AND T1.DATA_DATE = I_DATE
           WHERE T.DATA_DATE  = I_DATE
             AND T.TRANAMT > 0 
             AND T.TRANTYPE IN ('11','12') ; -- 11 还款（转账） 12 还款（存现）

         COMMIT; 
		 -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求：7.8报送范围调整为每日增量
 /*   
  -- JLBA202409120001 20241128 新增
INSERT INTO T_7_8
 (
  G080001        
 ,G080002        
 ,G080003        
 ,G080004        
 ,G080005        
 ,G080006        
 ,G080007        
 ,G080024        
 ,G080008        
 ,G080009        
 ,G080010        
 ,G080011        
 ,G080025        
 ,G080013        
 ,G080014        
 ,G080015        
 ,G080016        
 ,G080017        
 ,G080018        
 ,G080019        
 ,G080020        
 ,G080021        
 ,G080022        
 ,G080023        
 ,DIS_DATA_DATE  
 ,DIS_BANK_ID
 ,DIS_DEPT

)    

SELECT 
  G080001||'_'||replace(DIS_DATA_DATE,'-','')        
 ,G080002        
 ,G080003        
 ,G080004        
 ,G080005        
 ,G080006        
 ,G080007   
 ,G080024        
 ,G080008        
 ,G080009        
 ,G080010        
 ,G080011        
 ,G080025        
 ,G080013        
 ,G080014        
 ,G080015        
 ,G080016        
 ,G080017        
 ,G080018        
 ,G080019        
 ,G080020        
 ,G080021        
 ,G080022        
 ,TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')        
 ,TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')  
 ,DIS_BANK_ID 
 ,DIS_DEPT
FROM T_7_8_TMP1
WHERE  to_date( replace(DIS_DATA_DATE,'-',''),'yyyymmdd') 
BETWEEN TO_DATE(substr( I_DATE,1,4)||'0101','YYYYMMDD')  AND  TO_DATE(I_DATE,'YYYYMMDD');
*/
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

