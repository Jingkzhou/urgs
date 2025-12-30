DROP Procedure IF EXISTS `PROC_BSP_T_8_3_DKZT` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_8_3_DKZT"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN

  /******
      程序名称  ：垫款状态
      程序功能  ：加工垫款状态
      目标表：T_8_3
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
	SET P_PROC_NAME = 'PROC_BSP_T_8_3_DKZT';
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
	
	DELETE FROM T_8_3 WHERE H030013 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ;										
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
 INSERT INTO T_8_3
 (
   H030001    , -- 01 '协议ID'
   H030002    , -- 02 '客户ID'
   H030003    , -- 03 '机构ID'
   H030004    , -- 04 '借据ID'
   H030005    , -- 05 '原协议ID'
   H030006    , -- 06 '币种'
   H030007    , -- 07 '垫款类型'
   H030008    , -- 08 '垫款金额'
   H030009    , -- 09 '垫款余额'
   H030010    , -- 10 '垫款日期'
   H030011    , -- 11 '垫款状态'
   H030012    , -- 12 '备注'
   H030013    , -- 13 '采集日期'	  
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID   ,  -- 机构号 
   DIS_DEPT       ,
     DEPARTMENT_ID  -- 业务条线
)
  
    SELECT  
	      --  A.LOAN_NUM                                             , -- 01 '协议ID'
	        a.ACCT_NUM as H030001 , -- 01 '协议ID' update 20241113 zjk 解决校验问题  合同部在6.2合同表中在
            A.CUST_ID                                              , -- 02 '客户ID'
            ORG.ORG_ID                                             , -- 03 '机构ID'
            A.LOAN_NUM                                             , -- 04 '借据ID'
            A.DRAFT_NBR                                            , -- 05 '原协议ID'  20240607 原为 A.ACCT_NUM
            A.CURR_CD                                              , -- 06 '币种'
            case 
              when A.ACCT_TYP ='0903'   then	'01' -- 承兑汇票
              -- when A.ACCT_TYP ='090101' then	'02' -- 融资性保函
              when (A.ACCT_TYP ='090101' OR (A.ACCT_TYP ='0901' AND B.CP_ID = 'BH0050003'))  then	'02' -- 融资性保函 -- 修改20241015
              when A.ACCT_TYP ='099901' then	'03' -- 其他等同于贷款的授信业务
              -- when A.ACCT_TYP ='090102' then	'04' -- 非融资性保函
              when (A.ACCT_TYP ='090102' OR (A.ACCT_TYP ='0901' AND B.CP_ID = 'BH0050001')) then	'04' -- 非融资性保函 -- 修改20241015
              when A.ACCT_TYP ='099902' then	'05' -- 其他与交易相关的或有项目
	          when substring(a.acct_typ,1,4) = '0904'   then '06'                             -- '06' -- 跟单信用证
              when A.ACCT_TYP ='099903' then	'07' -- 其他与贸易相关或有项目
            end                                                    , -- 07 '垫款类型'
            A.DRAWDOWN_AMT                                         , -- 08 '垫款金额'
            CASE WHEN A.CANCEL_FLG='Y' THEN 0
              ELSE A.LOAN_ACCT_BAL
            END AS DKYE                                            , -- 09 '垫款余额'
            TO_CHAR(TO_DATE(A.DRAWDOWN_DT,'YYYYMMDD'),'YYYY-MM-DD'), -- 10 '垫款日期'
            /*CASE WHEN A.LOAN_SELL_INT='Y' THEN '03' -- 转让
                 WHEN A.CANCEL_FLG='Y' THEN '04' -- 核销
                 WHEN A.LOAN_ACCT_BAL > 0 THEN '01' -- 未结清
                 WHEN A.LOAN_ACCT_BAL = 0 THEN '02' -- 已结清
               --  WHEN A.ACCT_STS in('1') THEN '01' -- 未结清
               --  WHEN A.ACCT_STS='3' THEN '02' -- 已结清
               --  WHEN A.ACCT_STS in('9','2') THEN '05' -- 其他
            END AS DKZT                                            ,*/ -- 11 '垫款状态'
            CASE
             -- WHEN A.LOAN_SELL_INT = 'Y' THEN '03' -- 转让 注释 by haorui 20250311 JLBA202408200012 资产未转让
			 WHEN A.LOAN_STOCKEN_DATE IS NOT NULL THEN '03' -- 转让 add by haorui 20250311 JLBA202408200012 资产未转让
             WHEN A.CANCEL_FLG = 'Y' THEN '04' -- 核销 
             WHEN A.ACCT_STS IN ('1','2') THEN '01' -- 未结清
             WHEN A.ACCT_STS = '3' THEN '02' -- 已结清 
             WHEN A.ACCT_STS = '9' THEN '05' -- 其他 
           END AS DKZT, -- 垫款状态
            
            
            NULL                                                   , -- 12 '备注'
            TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')       , -- 13 '采集日期'
            TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')       , -- 装入数据日期
		    A.ORG_NUM                                              , -- 机构号
		    null,
		    '0098JR'
    FROM SMTMODS.L_ACCT_LOAN A -- 贷款借据信息表
    INNER JOIN SMTMODS.L_AGRE_LOAN_CONTRACT B -- 贷款合同信息表
           ON A.ACCT_NUM = B.CONTRACT_NUM
          AND B.DATA_DATE = I_DATE
    INNER JOIN SMTMODS.L_CUST_ALL C -- 全量客户信息表
            ON A.CUST_ID = C.CUST_ID
           AND C.DATA_DATE = I_DATE
    LEFT JOIN (SELECT  DISTINCT LOAN_NUM ,WRITE_OFF_DATE 
             FROM SMTMODS.L_ACCT_WRITE_OFF  -- 贷款核销
             WHERE DATA_DATE=I_DATE ) E
      ON A.LOAN_NUM=E.LOAN_NUM
    LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
        ON A.ORG_NUM = ORG.ORG_NUM
        AND ORG.DATA_DATE = I_DATE
    WHERE A.DATA_DATE = I_DATE -- 根据校验规则，表8.3垫款状态数据要在表6.2贷款协议中存在
      -- AND B.ACCT_STS <> '2'  -- 存在合同状态失效，但有贷款余额的借据
      AND A.ACCT_TYP LIKE '09%' -- 各项垫款
      -- AND A.ACCT_TYP<>'0999' -- 其他垫款
	  -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
      AND ((A.CANCEL_FLG='Y' -- 核销标志
            AND SUBSTR(E.WRITE_OFF_DATE,1,4) = SUBSTR(I_DATE,1,4)) -- 垫款状态为“结清”、“转让”、“核销”的，在报送次月可不再报送
         OR (A.CANCEL_FLG='N' -- 核销标志
             AND (SUBSTR(TO_CHAR(LOAN_STOCKEN_DATE,'YYYYMMDD'),1,4) = SUBSTR(I_DATE,1,4) OR A.LOAN_STOCKEN_DATE IS NULL)    -- add by haorui 20250311 JLBA202408200012 资产未转让
             AND ( A.ACCT_STS NOT IN('2','3') -- 账户状态 3-结清  2-逾期(不取逾期是为了过滤掉无本有息的数据，有本金的会在下面余额大于0的条件中获取到)
             OR  A.LOAN_ACCT_BAL > 0 -- 贷款余额
             OR  A.FINISH_DT  >= SUBSTR(I_DATE,1,4)||'0101' ))) ;-- 结清日期

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


