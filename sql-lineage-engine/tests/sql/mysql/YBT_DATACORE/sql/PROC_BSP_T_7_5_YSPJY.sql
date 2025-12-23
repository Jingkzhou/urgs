DROP Procedure IF EXISTS `PROC_BSP_T_7_5_YSPJY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_7_5_YSPJY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN

  /******
      程序名称  ：衍生品交易
      程序功能  ：加工衍生品交易
      目标表：T_7_5
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
	
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
	SET P_PROC_NAME = 'PROC_BSP_T_7_5_YSPJY';
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
	
	DELETE FROM T_7_5 WHERE G050036 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ;										
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
-- 结售汇业务信息表	
 INSERT INTO T_7_5  
 (
     G050001   , -- 01 '交易ID'
     G050002   , -- 02 '交易机构ID'
     G050003   , -- 03 '交易机构名称'
     G050004   , -- 04 '交易账号'
     G050005   , -- 05 '衍生品ID'
     G050006   , -- 06 '交易类型'
     G050007   , -- 07 '交易场所'
	 G050008   , -- 08 '交易日期'
	 G050009   , -- 09 '交易时间'  
	 G050010   , -- 10 '科目ID'  
	 G050011   , -- 11 '科目名称'  
	 G050012   , -- 12 '交割频率'  
	 G050013   , -- 13 '标的数量'  
	 G050014   , -- 14 '标的数量单位'  
	 G050015   , -- 15 '成交价格'  
	 G050016   , -- 16 '成交价格单位'  
	 G050017   , -- 17 '交割方式'  
	 G050018   , -- 18 '期权类型'  
	 G050019   , -- 19 '行权价格'  
	 G050020   , -- 20 '行权价格单位'  
	 G050021   , -- 21 '保证金标识'  
	 G050022   , -- 22 '主协议名称'  
	 G050023   , -- 23 '中央交易对手'  
	 G050024   , -- 24 '交易状态'  
	 G050025   , -- 25 '利率对'  
	 G050037   , -- 37 '交易对手方向'  
	 G050038   , -- 38 '交易对手客户ID'  
	 G050026   , -- 26 '交易对手名称'  
	 G050027   , -- 27 '交易对手大类'  
	 G050028   , -- 28 '交易对手评级'  
	 G050029   , -- 29 '交易对手评级机构'  
	 G050030   , -- 30 '交易对手账号行号'  
	 G050031   , -- 31 '交易对手账号'  
	 G050032   , -- 32 '交易对手账号开户行名称'  
	 G050033   , -- 33 '经办员工ID'  
	 G050034   , -- 34 '审批员工ID'  
	 G050035   , -- 35 '备注'  
	 G050036   , -- 36 '采集日期'	  
	 DIS_DATA_DATE , -- 装入数据日期
     DIS_BANK_ID   , -- 机构号  
     DIS_DEPT      ,
     DEPARTMENT_ID ,-- 业务条线
     G050039
)
      SELECT  
	        SUBSTR( A.FX_TX_REF_NO || A.FX_TERM_REF ,1,100)                        , -- 01 '交易ID'
            ORG.ORG_ID                                                             , -- 02 '交易机构ID'
            ORG.ORG_NAM                                                            , -- 03 '交易机构名称'
            A.FX_TX_REF_NO AS JYBH                                                 , -- 04 '交易账号'
			NULL                                                                   , -- 05 '衍生品ID'
            CASE WHEN A.TRANS_TYPE = 'A' then '01'
                 WHEN A.TRANS_TYPE = 'B' then '02'
                 WHEN A.TRANS_TYPE = 'C' then '03'
                 WHEN A.TRANS_TYPE = 'D' then '04'
                 WHEN A.TRANS_TYPE = 'E' then '05'
              ELSE '00'                                    
            END AS JYLX                                                            , -- 06 '交易类型'
            '01'                                                                   , -- 07 '交易场所'
            TO_CHAR(TO_DATE(A.TX_DATE  ,'YYYYMMDD'),'YYYY-MM-DD')                  , -- 08 '交易日期'
            A.TRANS_TIME                                                           , -- 09 '交易时间'  
            NULL                                                                   , -- 10 '科目ID'  
            NULL                                                                   , -- 11 '科目名称'  
            NULL                                                                   , -- 12 '交割频率'  
            A.SELL_AMT1 AS BDSL                                                    , -- 13 '标的数量'  
            A.SELL_CURR_CD1 AS BDSLDW                                              , -- 14 '标的数量单位'  
            A.BUY_AMT1 AS CJJG                                                     , -- 15 '成交价格'  
            A.BUY_CURR_CD1 AS CJJGDW                                               , -- 16 '成交价格单位'  
            -- CASE WHEN A.SETTLE_TYPE<>'Z' THEN  '交割' ELSE '其他-'||A.SETTLE_TYPE_DISC   END AS JGFS  , -- 17 '交割方式'
            CASE WHEN A.SETTLE_TYPE ='A' THEN '01' -- 全额
                 WHEN A.SETTLE_TYPE ='B' THEN '02' -- 差额
	             WHEN A.SETTLE_TYPE ='C' THEN '03' -- 净额
	             WHEN A.SETTLE_TYPE ='D' THEN '00' -- 其他
	             ELSE '00'
	              END AS JGFS                                                      , -- 17 '交割方式'   因校验公式YBT_JYG05-26，20241015做码值映射，by 87v
  
            NULL                                                                   , -- 18 '期权类型'  
            NULL                                                                   , -- 19 '行权价格'  
            NULL                                                                   , -- 20 '行权价格单位'  
            -- CASE WHEN A.SECURITY_TRAN_FLG = 'Y' THEN '是' ELSE '否' END AS BZJBZ   , -- 21 '保证金标识'  
            CASE WHEN A.SECURITY_TRAN_FLG = 'Y' THEN '1' ELSE '0' END AS BZJBZ     , -- 21 '保证金标识'  因校验公式YBT_JYG05-29，20241015做码值映射，by 87v
            NULL                                                                   , -- 22 '主协议名称'  
            A.CENTRAL_CTPTY_NAME AS ZYJYDS                                         , -- 23 '中央交易对手'  
            '01'                                                                   , -- 24 '交易状态' -- '新增'      因校验公式YBT_JYG05-31，20241015做码值映射，by 87v
            NULL                                                                   , -- 25 '利率对'  
            NULL                                                                   , -- 37 '交易对手方向'  
            A.OPPO_PTY_CD                                                          , -- 38 '交易对手客户ID'  
            A.OPPO_PTY_NAME                                                        , -- 26 '交易对手名称'  
            NULL                                                                   , -- 27 '交易对手大类'  
            NULL                                                                   , -- 28 '交易对手评级'  
            NULL                                                                   , -- 29 '交易对手评级机构'  
            NULL                                                                   , -- 30 '交易对手账号行号'  
            NULL                                                                   , -- 31 '交易对手账号'    
            NULL                                                                   , -- 32 '交易对手账号开户行名称'
            A.TRADER_ID AS JYYGH                                                   , -- 33 '经办员工ID'  
            A.APPROVER_ID AS SPRGH                                                 , -- 34 '审批员工ID'  
            NULL                                                                   , -- 35 '备注'  
            TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 36 '采集日期'	  
            TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
		    A.BRANCH_CODE                                   , -- 机构号
		    null,
		    '',
		    CASE WHEN SUBSTR(A.FX_TX_TYPE,1,1) = 'A' -- 结汇
	       THEN A.BUY_CURR_CD1
	      WHEN SUBSTR(A.FX_TX_TYPE,1,1) = 'B' -- 售汇
	 	  THEN A.SELL_CURR_CD1
		  END                   -- 13.其他协议币种
    FROM SMTMODS.L_ACCT_EXCHANGE_INFO A -- 结售汇业务信息表
    LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
        ON A.BRANCH_CODE = ORG.ORG_NUM
        AND ORG.DATA_DATE = I_DATE
        
    WHERE A.DATA_DATE = I_DATE
      AND SUBSTR(A.FX_TX_TYPE,1,3) IN ('A01','B01','E01')
      AND (  SUBSTR (A.TX_DATE,1,6) || '01'  =  SUBSTR (I_DATE,1,6) || '01' 
        OR EXISTS(SELECT 1 FROM SMTMODS.L_ACCT_EXCHANGE_INFO A1 -- 结售汇业务信息表(上期)
                  WHERE A.FX_TX_REF_NO = A1.FX_TX_REF_NO
                    AND A.EXECUTE_FLG <> A1.EXECUTE_FLG
                    AND A1.DATA_DATE = I_DATE ));
       
                    
-- 衍生合约信息表	
	INSERT INTO T_7_5  
 (
     G050001   , -- 01 '交易ID'
     G050002   , -- 02 '交易机构ID'
     G050003   , -- 03 '交易机构名称'
     G050004   , -- 04 '交易账号'
     G050005   , -- 05 '衍生品ID'
     G050006   , -- 06 '交易类型'
     G050007   , -- 07 '交易场所'
	 G050008   , -- 08 '交易日期'
	 G050009   , -- 09 '交易时间'  
	 G050010   , -- 10 '科目ID'  
	 G050011   , -- 11 '科目名称'  
	 G050012   , -- 12 '交割频率'  
	 G050013   , -- 13 '标的数量'  
	 G050014   , -- 14 '标的数量单位'  
	 G050015   , -- 15 '成交价格'  
	 G050016   , -- 16 '成交价格单位'  
	 G050017   , -- 17 '交割方式'  
	 G050018   , -- 18 '期权类型'  
	 G050019   , -- 19 '行权价格'  
	 G050020   , -- 20 '行权价格单位'  
	 G050021   , -- 21 '保证金标识'  
	 G050022   , -- 22 '主协议名称'  
	 G050023   , -- 23 '中央交易对手'  
	 G050024   , -- 24 '交易状态'  
	 G050025   , -- 25 '利率对'  
	 G050037   , -- 37 '交易对手方向'  
	 G050038   , -- 38 '交易对手客户ID'  
	 G050026   , -- 26 '交易对手名称'  
	 G050027   , -- 27 '交易对手大类'  
	 G050028   , -- 28 '交易对手评级'  
	 G050029   , -- 29 '交易对手评级机构'  
	 G050030   , -- 30 '交易对手账号行号'  
	 G050031   , -- 31 '交易对手账号'  
	 G050032   , -- 32 '交易对手账号开户行名称'  
	 G050033   , -- 33 '经办员工ID'  
	 G050034   , -- 34 '审批员工ID'  
	 G050035   , -- 35 '备注'  
	 G050036   , -- 36 '采集日期'	
	 DIS_DATA_DATE , -- 装入数据日期
     DIS_BANK_ID   ,  -- 机构号  
     DIS_DEPT      ,
     DEPARTMENT_ID ,-- 业务条线
     G050039
	   
)
	SELECT 
           T.REF_NUM               , -- 01 '交易ID'
           ORG.ORG_ID              , -- 02 '交易机构ID'
           ORG.ORG_NAM             , -- 03 '交易机构名称'
           NULL                    , -- 04 '交易账号'
           T.SUBJECT_CD            , -- 05 '衍生品ID'
           T.TRAN_GENRE            , -- 06 '交易类型'
           '01'                    , -- 07 '交易场所'
           TO_CHAR(TO_DATE(T.DEAL_DATE  ,'YYYYMMDD'),'YYYY-MM-DD')           , -- 08 '交易日期'
           T.TRANS_TIME            , -- 09 '交易时间'  
           NULL                    , -- 10 '科目ID'  
           NULL                    , -- 11 '科目名称'  
           T.SETTLE_FREQ           , -- 12 '交割频率'  
           A.SUBJECT_NUM           , -- 13 '标的数量'  
           NULL                    , -- 14 '标的数量单位'  
           NULL                    , -- 15 '成交价格'  
           NULL                    , -- 16 '成交价格单位'  
           T.SETTLE_TYPE           , -- 17 '交割方式'  
           T.OPTION_TYP            , -- 18 '期权类型'  
           T.OPTION_PRICE          , -- 19 '行权价格'  
           T.OPTION_PRICE_UNIT     , -- 20 '行权价格单位'  
           NULL                    , -- 21 '保证金标识'  
           T.AGREEMENT_NAME        , -- 22 '主协议名称'  
           NULL                    , -- 23 '中央交易对手'  
           NULL                    , -- 24 '交易状态'  
           NULL                    , -- 25 '利率对'  
           NULL                    , -- 37 '交易对手方向'  
           T.OPPO_PTY_CD           , -- 38 '交易对手客户ID'  
           T.OPPO_PTY_NAM          , -- 26 '交易对手名称'  
           NULL                    , -- 27 '交易对手大类'  
           NULL                    , -- 28 '交易对手评级'  
           NULL                    , -- 29 '交易对手评级机构'  
           NULL                    , -- 30 '交易对手账号行号'  
           NULL                    , -- 31 '交易对手账号'  
           NULL                    , -- 32 '交易对手账号开户行名称'  
           T.TRADER_ID             , -- 33 '经办员工ID'  
           T.APPROVER_ID           , -- 34 '审批员工ID'  
           NULL                    , -- 35 '备注'  
           TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 36 '采集日期'	  
           TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
		   T.ORG_NUM                                        , -- 机构号  
		   null,
		   '',
		   nvl(t.CURR_CD1,t.CURR_CD2)
    FROM  SMTMODS.L_ACCT_DERIVE_DETAIL_INFO T -- 衍生合约信息表
     LEFT JOIN  SMTMODS.L_AGRE_DERIVE_SUBJECT_INFO A -- 衍生品标的物信息表
        ON T.SUBJECT_CD=A.SUBJECT_CD
        AND A.DATA_DATE =I_DATE
     LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
        ON T.ORG_NUM = ORG.ORG_NUM
        AND ORG.DATA_DATE = I_DATE
     WHERE T.DATA_DATE = I_DATE;

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

