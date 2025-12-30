DROP Procedure IF EXISTS `PROC_BSP_T_8_2_XYZZT` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_8_2_XYZZT"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN

  /******
      程序名称  ：信用证状态
      程序功能  ：加工信用证状态
      目标表：T_8_2
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
	SET P_PROC_NAME = 'PROC_BSP_T_8_2_XYZZT';
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
	
	DELETE FROM T_8_2 WHERE H020013 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ;									
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
 INSERT INTO T_8_2
 (
    H020001    , -- 01 '信用证ID'
    H020002    , -- 02 '开票机构ID'
	H020003    , -- 03 '科目ID'
	H020004    , -- 04 '科目名称'  
    H020005    , -- 05 '议付交单机构'  
	H020006    , -- 06 '币种'  
	H020007    , -- 07 '已兑付金额'  
	H020008    , -- 08 '撤销日期'  
	H020009    , -- 09 '闭卷日期'  
	H020010    , -- 10 '押汇余额'  
	H020011    , -- 11 '垫款余额'  
	H020012    , -- 12 '合同状态'  
	H020013    , -- 13 '采集日期'  
	DIS_DATA_DATE , -- 装入数据日期
    DIS_BANK_ID   , -- 机构号
    DIS_DEPT       ,
     DEPARTMENT_ID  -- 业务条线
	   
)
   SELECT  
       B.LC_NBR            , -- 01 '信用证ID'
       ORG.ORG_ID          , -- 02 '开票机构ID'
       A.GL_ITEM_CODE      , -- 03 '科目ID'
       D.GL_CD_NAME        , -- 04 '科目名称'  
       B.YFJDJG            , -- 05 '议付交单机构'  
       A.CURR_CD           , -- 06 '币种'  
       A.PAID_AMT          , -- 07 '已兑付金额'  
       TO_CHAR(TO_DATE(NVL(B.LC_WRITE_OFF_DT,'99991231'),'YYYYMMDD'),'YYYY-MM-DD'), -- 08 '撤销日期'  
       TO_CHAR(TO_DATE(NVL(B.LETT_CLOSE_DATE,'99991231'),'YYYYMMDD'),'YYYY-MM-DD'), -- 09 '闭卷日期'  
       -- E.LOAN_ACCT_BAL     , -- 10 '押汇余额'
       B.LETT_DOCUM_BAL    , -- 10 '押汇余额'
       /*CASE WHEN A.MONEYADVANCED_FLG = 'Y' AND NVL(F.LOAN_ACCT_BAL,0) <> 0  THEN F.LOAN_ACCT_BAL
         ELSE 0 
           END             , -- 11 '垫款余额'  */
       NVL(F.LOAN_ACCT_BAL,0)     , -- 11 '垫款余额' -- 发文没有说空值给0但是校验不允许空
       CASE WHEN A.BUSI_STATUS <> '00' THEN A.BUSI_STATUS
            ELSE ''
            END            , -- 12 '合同状态'   
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 13 '采集日期'
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
	   A.ORG_NUM                                       , -- 机构号
	   null,
	   '0098GJ'                                          -- 业务条线    -- 国际业务（贸易金融）部           
    FROM SMTMODS.L_ACCT_OBS_LOAN A -- 贷款表外信息表
    LEFT JOIN SMTMODS.L_ACCT_OBS_LOAN_LC B -- 信用证业务补充信息
           ON A.ACCT_NO = B.CONTRACT_NUM
          AND B.DATA_DATE = I_DATE
    LEFT JOIN SMTMODS.L_FINA_INNER D -- 内部科目对照表
           ON A.GL_ITEM_CODE = D.STAT_SUB_NUM
          AND A.ORG_NUM = D.ORG_NUM
          AND D.DATA_DATE = I_DATE    
    /*LEFT JOIN (select ACCT_NUM,SUM(LOAN_ACCT_BAL) LOAN_ACCT_BAL from  SMTMODS.L_ACCT_LOAN
                 where DATA_DATE = I_DATE AND SUBSTR(ITEM_CD,1,6) = '130501' -- 贸易融资
                 group by ACCT_NUM) E
           ON A.ACCT_NO = E.ACCT_NUM
    LEFT JOIN SMTMODS.L_ACCT_TRAD_FIN E -- 贸易融资补充信息
           ON A.ACCT_NO = E.ACCT_NUM  */   
    LEFT JOIN (select ACCT_NUM,SUM(LOAN_ACCT_BAL) LOAN_ACCT_BAL from  SMTMODS.L_ACCT_LOAN
                 where DATA_DATE = I_DATE AND SUBSTR(ITEM_CD,1,6) = '130603' -- 信用证垫款 -- 已闭卷的都没垫款，把下面条件去掉是有值的,但都是0
                 group by ACCT_NUM) F
           ON A.ACCT_NO = F.ACCT_NUM     
    LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
           ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATE
    WHERE A.DATA_DATE = I_DATE -- 此处条件与表6.11信用证协议代码同步
      -- AND A.ACCT_TYP NOT IN ('111','112')
      AND A.BUSI_STATUS = '02' -- 02-正常
      AND A.ACCT_STS = '1'-- 1-有效
      AND SUBSTR(A.GL_ITEM_CODE,1,4) = ('7010') -- 开出信用证    EAST的BSP_SP_EAST5_IE_009_BHYXYZB是保函与信用证，包括了一表通的6.11和6.12
	  -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
      AND (B.LETT_CLOSE_DATE is null or B.LETT_CLOSE_DATE >= SUBSTR(I_DATE,1,4)||'0101' 
       OR (B.LETT_CLOSE_DATE < I_DATE AND A.MATURITY_DT < I_DATE AND A.BALANCE>0)) -- 报送未闭卷  或  已闭卷且逾期(已到期有余额定义为逾期)
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


