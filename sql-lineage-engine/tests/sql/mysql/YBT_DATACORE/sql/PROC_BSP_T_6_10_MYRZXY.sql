DROP Procedure IF EXISTS `PROC_BSP_T_6_10_MYRZXY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_10_MYRZXY"(IN I_DATE VARCHAR(8),
                                        OUT OI_RETCODE   INT,-- 返回code
                                        OUT OI_REMESSAGE VARCHAR -- 返回message
)
BEGIN

  /******
      程序名称  ：贸易融资协议
      程序功能  ：加工贸易融资协议
      目标表：T_6_10
      源表  ：
      创建人  ：87v
      创建日期  ：20240111
      版本号：V0.0.1 
  ******/
	 /*需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
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
	SET P_PROC_NAME = 'PROC_BSP_T_6_10_MYRZXY';
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

	DELETE FROM T_6_10 WHERE F100026 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
   	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);													
		
	
	#3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
   INSERT INTO T_6_10  (
          F100001 , -- 01 机构ID
          F100002 , -- 02 协议ID
          F100003 , -- 03 产品ID
          F100004 , -- 04 协议币种
          F100005 , -- 05 贸易融资品种
          F100006 , -- 06 贸易融资金额
          F100027 , -- 27 实际支付金额
          F100007 , -- 07 发放日期
          F100008 , -- 08 到期日期
          F100009 , -- 09 购货方名称
          F100010 , -- 10 销货方名称
          F100011 , -- 11 贸易交易内容
          F100012 , -- 12 开证行名称
          F100013 , -- 13 支付对象名称
          F100014 , -- 14 手续费币种
          F100015 , -- 15 手续费金额
          F100016 , -- 16 保证金账号
          F100017 , -- 17 保证金比例
          F100018 , -- 18 保证金币种
          F100019 , -- 19 保证金金额
          F100020 , -- 20 重点产业标识
          F100021 , -- 21 经办员工ID
          F100022 , -- 22 审查员工ID
          F100023 , -- 23 审批员工ID
          F100024 , -- 24 还款对象名称
          F100025 , -- 25 备注
          F100026 , -- 26 采集日期
          DIS_DATA_DATE , -- 装入数据日期
          DIS_BANK_ID   , -- 机构号
          DIS_DEPT      ,
          DEPARTMENT_ID , -- 业务条线
          F100028
          )
 SELECT  
       ORG.ORG_ID                 , -- 01 机构ID
       A.ACCT_NUM                 , -- 02 协议ID
       C.CP_ID                    , -- 03 产品ID -- 新增字段
       A.CURR_CD                  , -- 04 协议币种
       CASE  WHEN E.TRAD_FIN_TYPE IN ('01','02','26') THEN '04' -- 打包贷款
                  WHEN E.TRAD_FIN_TYPE IN ('03','04') THEN '06' -- 出口信用证押汇
                  WHEN E.TRAD_FIN_TYPE IN ('07','08') THEN '08' -- 出口托收押汇
                  WHEN E.TRAD_FIN_TYPE IN ('11','30') THEN '14' -- 商业发票融资
                  WHEN E.TRAD_FIN_TYPE IN ('12','13') AND E.FORF_TYPE='2' THEN '13' -- 二级市场福费廷
                  WHEN E.TRAD_FIN_TYPE IN ('12') AND E.FORF_TYPE<>'2' THEN '11' -- 国内自营福费廷（不含二级市场福费廷）
                  WHEN E.TRAD_FIN_TYPE IN ('13') AND E.FORF_TYPE<>'2' THEN '12' -- 国际自营福费廷（不含二级市场福费廷）
                  WHEN E.TRAD_FIN_TYPE='14' THEN '15' -- 货到付款押汇
                  WHEN E.TRAD_FIN_TYPE='15' THEN '05' -- 进口信用证押汇
                  WHEN E.TRAD_FIN_TYPE='23' THEN '17' -- '18' -- 国际保理
                  WHEN E.TRAD_FIN_TYPE='24' THEN '20' -- 保兑仓
                  WHEN E.TRAD_FIN_TYPE='25' THEN '09' -- 进口代付
                 -- WHEN E.TRAD_FIN_TYPE='28' THEN '买方融资'
                  WHEN E.TRAD_FIN_TYPE='29' THEN '17' -- 国内保理
                  WHEN E.TRAD_FIN_TYPE='27' THEN '03' -- 议付信用证款项
                  WHEN E.TRAD_FIN_TYPE='34' THEN '02' -- 卖方押汇
                  WHEN E.TRAD_FIN_TYPE='35' THEN '07' -- 进口托收押汇
                  WHEN E.TRAD_FIN_TYPE='36' THEN '10' -- 出口代付
                  WHEN E.TRAD_FIN_TYPE='37' THEN '16' -- 先款后货
                  WHEN E.TRAD_FIN_TYPE='38' THEN '19' -- 订单融资
                  WHEN E.TRAD_FIN_TYPE='28' THEN '01' -- 买方押汇
                  /*WHEN E.TRAD_FIN_TYPE='16' THEN '其他-进口代收押汇'
                  WHEN E.TRAD_FIN_TYPE='31' THEN '其他-商品融资'
                  WHEN E.TRAD_FIN_TYPE='05' THEN '其他-出口信用证贴现'
                  WHEN E.TRAD_FIN_TYPE='06' THEN '其他-出口信用证贴现(离岸)'
                  WHEN E.TRAD_FIN_TYPE='09' THEN '其他-出口托收贴现'
                  WHEN E.TRAD_FIN_TYPE='10' THEN '其他-出口托收贴现(OTS)'
                  WHEN E.TRAD_FIN_TYPE='16' THEN '其他-进口代收押汇'
                  WHEN E.TRAD_FIN_TYPE='31' THEN '其他-商品融资'
                  WHEN E.TRAD_FIN_TYPE='32' THEN '其他-'||E.TRAD_FIN_TYPE_DESC
                  ELSE '其他-'||A.ACCT_TYP_DESC*/
                  else '00' -- 其他
            END                            , -- 05 贸易融资品种
       C.CONTRACT_AMT  , -- 06 贸易融资金额
       case when A.LOAN_ACCT_BAL=0 then null else A.LOAN_ACCT_BAL end , -- A.LOAN_ACCT_BAL 27 实际支付金额   20240316  update zhoujingkun  实际支付金额要看单据金额（有的字段叫议付金额）BUG_10009600
       -- 触发校验 JYF10-56【6.10贸易融资协议】.【实际支付金额】非空时应大于0
       
       to_char(to_date(C.CONTRACT_EFF_DT,'yyyymmdd'),'yyyy-mm-dd') , -- 07 发放日期
	   
	   to_char(to_date(C.CONTRACT_ORIG_MATURITY_DT,'yyyymmdd'),'yyyy-mm-dd')  , -- 08 到期日期
	   CASE
              WHEN C.PROD_NAME IN ('进口代收融资','进口信用证押汇','代付业务','国内信用证-买方押汇','国内信用证-买方代付') THEN D.CUST_NAM
              ELSE E.BUY_SUPP_NAME
            END                            , -- 09 购货方名称
       CASE
              WHEN C.PROD_NAME IN ('出口订单融资','出口商业发票融资','出口打包贷款','出口信用证押汇','出口托收融资','国内信用证-打包贷款','国内信用证-卖方押汇','国内信用证-卖方代付') THEN D.CUST_NAM
              ELSE E.SELL_SUPP_NAME
            END                            , -- 10 销货方名称
	   E.TRAD_REMARK                       , -- 11 贸易交易内容
	   E.ISSU_BANK_NAME                    , -- 12 开证行名称
	   NVL(E.PAY_CUST_NAME,D.CUST_NAM)     , -- 13 支付对象名称
	   -- E.PAY_CUST_NAME                     , -- 13 支付对象名称
	   E.FEE_CURR                          , -- 14 手续费币种
	   -- 'CNY'                               , -- 14 手续费币种  -- 信贷反馈手续费币种默认都是人民币
	   NVL(E.FEE_AMT,0)                    , -- 15 手续费金额
	   A.SECURITY_ACCT_NUM                 , -- 16 保证金账号
	   NVL(A.SECURITY_RATE,0)              , -- 17 保证金比例
       A.SECURITY_CURR                     , -- 18 保证金币种
       NVL(A.SECURITY_AMT,0)               , -- 19 保证金金额       
       NVL(INDUST_RSTRUCT_FLG,'0') || DECODE(INDUST_TRAN_FLG,'1','1','2','0','0') || REPLACE(NVL(INDUST_STG_TYPE,'0'),'#','0')
	                                       , -- 20 重点产业标识
	   C.JBYG_ID                           , -- 21 经办员工ID -- 新增字段
	   C.SCYG_ID                           , -- 22 审查员工ID -- 新增字段
	   NVL(C.SPYG_ID,'自动')               , -- 23 审批员工ID -- 新增字段 大为哥与国际业务部确认，为空置为 自动 20250113
	   NVL(E.REPAY_CUST_NAME,D.CUST_NAM)   , -- 24 还款对象名称
	   -- E.REPAY_CUST_NAME                   , -- 24 还款对象名称
	   -- A.REMARK                            , -- 25 备注
	   NULL                                , -- 25 备注
	   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 26 采集日期
	   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
	   A.ORG_NUM                                       , -- 机构号
	   null,
      '0098GJ'                                         , -- 业务条线    -- 国际业务（贸易金融）部
       A.LOAN_NUM
      FROM ( 
      select ACCT_NUM,LOAN_NUM,CURR_CD,ORG_NUM,SECURITY_ACCT_NUM,SECURITY_RATE,SECURITY_CURR,security_amt,INDUST_RSTRUCT_FLG 
             ,INDUST_TRAN_FLG,INDUST_STG_TYPE,SUM(LOAN_ACCT_BAL) as LOAN_ACCT_BAL
          from SMTMODS.L_ACCT_LOAN A  
        WHERE A.DATA_DATE = I_DATE
      AND A.ITEM_CD LIKE '1305%'-- 贸易融资   -- 公司金融：票据的福费廷业务后续接到借据表，补一下科目就行
      AND (A.ACCT_STS<>'3' OR A.LOAN_ACCT_BAL > 0 OR A.FINISH_DT >= SUBSTR(I_DATE,1,4)||'0101' ) -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
      group by ACCT_NUM,LOAN_NUM,CURR_CD,ORG_NUM,SECURITY_ACCT_NUM,SECURITY_RATE,SECURITY_CURR,security_amt,INDUST_RSTRUCT_FLG,INDUST_TRAN_FLG,INDUST_STG_TYPE 
      ) A
      
      INNER JOIN SMTMODS.L_AGRE_LOAN_CONTRACT C
        ON A.ACCT_NUM = C.CONTRACT_NUM
       AND C.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_CUST_ALL D
        ON C.CUST_ID = D.CUST_ID
       AND D.DATA_DATE = I_DATE
      LEFT JOIN (
      select distinct ACCT_NUM,TRAD_FIN_TYPE,FORF_TYPE,SELL_SUPP_NAME,TRAD_REMARK,ISSU_BANK_NAME,PAY_CUST_NAME,BUY_SUPP_NAME,REPAY_CUST_NAME,SELL_SUPP_NAME,FEE_CURR,FEE_AMT
        from SMTMODS.L_ACCT_TRAD_FIN -- 贸易融资补充信息
        WHERE DATA_DATE = I_DATE
         )E
        ON C.CONTRACT_NUM = E.ACCT_NUM
       
      LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
        ON A.ORG_NUM = ORG.ORG_NUM
        AND ORG.DATA_DATE = I_DATE
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


