DROP Procedure IF EXISTS `PROC_BSP_T_8_6_YSPCLQK` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_8_6_YSPCLQK"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN

  /******
      程序名称  ：衍生品存量情况
      程序功能  ：加工衍生品存量情况
      目标表：T_8_6
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
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
	SET P_PROC_NAME = 'PROC_BSP_T_8_6_YSPCLQK';
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
	
	DELETE FROM T_8_6 WHERE H060032 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ;										
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
 INSERT INTO T_8_6
 (
 H060001   , -- 01 '衍生品ID'
 H060002   , -- 02 '交易机构ID'
 H060003   , -- 03 '协议ID'
 H060004   , -- 04 '衍生品名称'
 H060005   , -- 05 '衍生品类型'
 H060006   , -- 06 '基础资产名称'
 H060007   , -- 07 '基础资产类型'
 H060008   , -- 08 '账户类型'
 H060009   , -- 09 '币种'
 H060010   , -- 10 '正总市场价值'
 H060011   , -- 11 '负总市场价值'
 H060012   , -- 12 '估值日期'
 H060013   , -- 13 '多头头寸'
 H060014   , -- 14 '空头头寸'
 H060015   , -- 15 '合同起始日期'
 H060016   , -- 16 '合同终止日期'
 H060017   , -- 17 '衍生品发行日期'
 H060018   , -- 18 '衍生品到期日期'
 H060019   , -- 19 '科目ID'
 H060020   , -- 20 '科目名称'
 H060021   , -- 21 '国家地区'
 H060022   , -- 22 '行权方式'
 H060023   , -- 23 '本方初始币种'
 H060024   , -- 24 '对方初始币种'
 H060025   , -- 25 '本方利率类型'
 H060026   , -- 26 '对方利率类型'
 H060027   , -- 27 '本方利率基准'
 H060028   , -- 28 '本方利率浮动点'
 H060029   , -- 29 '对方利率基准'
 H060030   , -- 30 '对方利率浮动点'
 H060031   , -- 31 '担保协议ID'
 H060033   , -- 33 '估值金额'
 H060032   , -- 32 '采集日期'	
 DIS_DATA_DATE , -- 装入数据日期
 DIS_BANK_ID   , -- 机构号
 DIS_DEPT      ,
 DEPARTMENT_ID , -- 业务条线
 H060034  , -- 估值币种',
 H060035 -- '保证金金额'
 )
 SELECT
        A.SUBJECT_CD          , -- 01 '衍生品ID'
        ORG.ORG_ID            , -- 02 '交易机构ID'
        NULL                  , -- 03 '协议ID'
        A.SUBJECT_NAM         , -- 04 '衍生品名称'
        T.BUSINESS_TYP        , -- 05 '衍生品类型'
        NULL                  , -- 06 '基础资产名称'
        A.SUBJECT_PRO_TYPE    , -- 07 '基础资产类型'
        T.ACCT_TYPE           , -- 08 '账户类型'
        T.CURR_CD1            , -- 09 '币种'
        NULL                  , -- 10 '正总市场价值'
        NULL                  , -- 11 '负总市场价值'
        TO_CHAR(TO_DATE(T.RE_MARKET_DATE ,'YYYYMMDD'),'YYYY-MM-DD')       , -- 12 '估值日期'
        NULL                  , -- 13 '多头头寸'
        NULL                  , -- 14 '空头头寸'
        TO_CHAR(TO_DATE(T.EFFECTIVE_DATE ,'YYYYMMDD'),'YYYY-MM-DD')       , -- 15 '合同起始日期'
        TO_CHAR(TO_DATE(T.MATURITY_DATE  ,'YYYYMMDD'),'YYYY-MM-DD')       , -- 16 '合同终止日期'
        TO_CHAR(TO_DATE( nvl(A.INT_ST_DT ,T.EFFECTIVE_DATE),'YYYYMMDD'),'YYYY-MM-DD')         , -- 17 '衍生品发行日期'
        A.MATURITY_DT         , -- 18 '衍生品到期日期'
        NULL                  , -- 19 '科目ID'
        NULL                  , -- 20 '科目名称'
        NULL                  , -- 21 '国家地区'
        T.EXERCISE_APPR       , -- 22 '行权方式'
        NULL                  , -- 23 '本方初始币种'
        NULL                  , -- 24 '对方初始币种'
        A.INT_RATE_TYP        , -- 25 '本方利率类型'
        A.INT_RATE_TYP        , -- 26 '对方利率类型'
        NULL                  , -- 27 '本方利率基准'
        T.FLOAT_POINT1        , -- 28 '本方利率浮动点'
        NULL                  , -- 29 '对方利率基准'
        T.FLOAT_POINT2        , -- 30 '对方利率浮动点'
        NULL                  , -- 31 '担保协议ID'
        NULL                  , -- 33 '估值金额'
        TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),  -- 32 '采集日期'	
        TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
		T.ORG_NUM                                       , -- 机构号
		NULL ,
		NULL ,   -- 业务条线
        t.CURR_CD1, -- 估值币种',
        NULL -- '保证金金额'
        
    FROM SMTMODS.L_ACCT_DERIVE_DETAIL_INFO T  -- 衍生合约信息表 
       LEFT JOIN  SMTMODS.L_AGRE_DERIVE_SUBJECT_INFO A  -- 衍生品标的物信息表
        ON T.SUBJECT_CD = A.SUBJECT_CD
        AND A.DATA_DATE = I_DATE
       LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
        ON T.ORG_NUM = ORG.ORG_NUM
        AND ORG.DATA_DATE = I_DATE
    WHERE T.DATA_DATE = I_DATE
	  AND T.MATURITY_DATE >= SUBSTR(I_DATE,1,4)||'0101' -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
	;
COMMIT;




INSERT INTO T_8_6
 (
 H060001   , -- 01 '衍生品ID'
 H060002   , -- 02 '交易机构ID'
 H060003   , -- 03 '协议ID'
 H060004   , -- 04 '衍生品名称'
 H060005   , -- 05 '衍生品类型'
 H060006   , -- 06 '基础资产名称'
 H060007   , -- 07 '基础资产类型'
 H060008   , -- 08 '账户类型'
 H060009   , -- 09 '币种'
 H060010   , -- 10 '正总市场价值'
 H060011   , -- 11 '负总市场价值'
 H060012   , -- 12 '估值日期'
 H060013   , -- 13 '多头头寸'
 H060014   , -- 14 '空头头寸'
 H060015   , -- 15 '合同起始日期'
 H060016   , -- 16 '合同终止日期'
 H060017   , -- 17 '衍生品发行日期'
 H060018   , -- 18 '衍生品到期日期'
 H060019   , -- 19 '科目ID'
 H060020   , -- 20 '科目名称'
 H060021   , -- 21 '国家地区'
 H060022   , -- 22 '行权方式'
 H060023   , -- 23 '本方初始币种'
 H060024   , -- 24 '对方初始币种'
 H060025   , -- 25 '本方利率类型'
 H060026   , -- 26 '对方利率类型'
 H060027   , -- 27 '本方利率基准'
 H060028   , -- 28 '本方利率浮动点'
 H060029   , -- 29 '对方利率基准'
 H060030   , -- 30 '对方利率浮动点'
 H060031   , -- 31 '担保协议ID'
 H060033   , -- 33 '估值金额'
 H060032   , -- 32 '采集日期'	
 DIS_DATA_DATE , -- 装入数据日期
 DIS_BANK_ID   , -- 机构号
 DIS_DEPT      ,
 DEPARTMENT_ID , -- 业务条线
 H060034  , -- 估值币种',
 H060035 -- '保证金金额'
 )


 SELECT  
 NULL   , -- 01 '衍生品ID'
 ORG.ORG_ID , -- 02 '交易机构ID'
 A.FX_TX_REF_NO   , -- 03 '协议ID'
 NULL   , -- 04 '衍生品名称'
 NULL   , -- 05 '衍生品类型'
 A.BUY_CURR_CD1||A.SELL_CURR_CD1    , -- 06 '基础资产名称'
 '02'      , -- 07 '基础资产类型'
 '01'      , -- 08 '账户类型'
 	CASE WHEN SUBSTR(A.FX_TX_TYPE,1,1) = 'A' -- 结汇
	     THEN A.BUY_CURR_CD1
		 WHEN SUBSTR(A.FX_TX_TYPE,1,1) = 'B' -- 售汇
		 THEN A.SELL_CURR_CD1
		  END     AS BZ  , -- 09 '币种'
 NULL    , -- 10 '正总市场价值'
 NULL    , -- 11 '负总市场价值'
 NULL    , -- 12 '估值日期'
 NULL    , -- 13 '多头头寸'
 NULL    , -- 14 '空头头寸'
 TO_CHAR(TO_DATE(A.START_DATE,'YYYYMMDD'),'YYYY-MM-DD')   , -- 15 '合同起始日期'
 TO_CHAR(TO_DATE(A.MATURITY_DT ,'YYYYMMDD'),'YYYY-MM-DD')   , -- 16 '合同终止日期'
 NULL   , -- 17 '衍生品发行日期'
 NULL   , -- 18 '衍生品到期日期'
 NULL   , -- 19 '科目ID'
 NULL   , -- 20 '科目名称'
 NULL   , -- 21 '国家地区'
 NULL   , -- 22 '行权方式'
 A.BUY_CURR_CD1   , -- 23 '本方初始币种'
 A.SELL_CURR_CD1   , -- 24 '对方初始币种'
 NULL   , -- 25 '本方利率类型'
 NULL   , -- 26 '对方利率类型'
 NULL   , -- 27 '本方利率基准'
 NULL   , -- 28 '本方利率浮动点'
 NULL   , -- 29 '对方利率基准'
 NULL   , -- 30 '对方利率浮动点'
 NULL   , -- 31 '担保协议ID'
 NULL   , -- 33 '估值金额'
 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 32 '采集日期'	
 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 装入数据日期
 A.BRANCH_CODE   , -- 机构号
 NULL ,
 NULL ,   -- 业务条线
 A.SELL_CURR_CD1 , -- 估值币种',
 NULL  -- '保证金金额'
    
    FROM SMTMODS.L_ACCT_EXCHANGE_INFO A -- 结售汇业务信息表
    LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
      ON A.BRANCH_CODE = ORG.ORG_NUM
     AND ORG.DATA_DATE = I_DATE
   WHERE A.DATA_DATE = I_DATE
     AND SUBSTR(A.FX_TX_TYPE,1,3) IN ('A01','B01','E01')
     AND (SUBSTR (A.TX_DATE,1,4)  =  SUBSTR (I_DATE,1,4)  -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
          OR EXISTS(SELECT 1 FROM SMTMODS.L_ACCT_EXCHANGE_INFO A1 -- 结售汇业务信息表(上期)
                  WHERE A.FX_TX_REF_NO = A1.FX_TX_REF_NO
                    AND A.EXECUTE_FLG <> A1.EXECUTE_FLG
                    AND A1.DATA_DATE = I_DATE ));
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


