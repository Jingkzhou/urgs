DROP Procedure IF EXISTS `PROC_BSP_T_6_15_FDXDKXY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_15_FDXDKXY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回CODE
                                         OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
                                         )
BEGIN

  /******
      程序名称  ：表6.15房地产贷款协议
      程序功能  ：加工表6.15房地产贷款协议
      目标表：T_6_15
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
	-- JLBA202411070004_关于一表通监管数据报送系统修改逻辑的需求	
	 /*需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
	 /*需求编号：JLBA202507300010 上线日期：2025-09-29，修改人：姜俐锋，提出人：信贷新增产品 修改原因：关于新一代信贷管理系统新增线上微贷板块的需求 */
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
   SELECT OI_RETCODE,'|',OI_REMESSAGE;		
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
	SET P_PROC_NAME = 'PROC_BSP_T_6_15_FDXDKXY';
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
	
	
	
	DELETE FROM T_6_15 WHERE F150016 = TO_CHAR(P_DATE,'YYYY-MM-DD') ;
	
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';

 set gcluster_hash_redistribute_join_optimize = 1;
	
 INSERT INTO T_6_15
 (
    F150001   , -- 01 '协议ID' 
	F150017   , -- 17 '机构ID'
	F150002   , -- 02 '房地产开发贷款对应的项目资本金比例'
	F150003   , -- 03 '房地产开发贷款对应的项目资本金金额'
	F150004   , -- 04 '房地产开发贷款对应的项目投资额'
	F150005   , -- 05 '商业用房购房贷款购买主体类型'
	F150006   , -- 06 '个人住房贷款对应的住房套数'
	F150007   , -- 07 '贷款价值比'
	F150008   , -- 08 '新建个人住房贷款标识'
	F150009   , -- 09 '个人住房贷款利率分类标识'
	F150010   , -- 10 '个人住房贷款基于贷款市场报价利率（LPR）标识'
	F150011   , -- 11 '个人住房贷款对应房屋建筑面积'
	F150012   , -- 12 '个人住房贷款偿债收入比'
	F150013   , -- 13 '个人住房贷款首付金额'
	F150014   , -- 14 '个人住房贷款对应房屋总价'
	F150015   , -- 15 '个人住房贷款对应房地产押品市场价值'
	F150016   , -- 16 '采集日期'		
	DIS_DATA_DATE,
	DIS_BANK_ID,
    DEPARTMENT_ID

 )
 
    WITH  GUARANTY_INFO_TMP AS  -- 押品信息
       (SELECT /*+ PARALLEL(4)*/ DISTINCT  A.CONTRACT_NUM AS CONTRACT_NUM , SUM(NVL(C.COLL_MK_VAL, 0)) AS COLL_MK_VAL
        FROM SMTMODS.L_AGRE_GUA_RELATION A -- 业务合同与担保合同对应关系表
        LEFT JOIN SMTMODS.L_AGRE_GUARANTEE_RELATION B -- 担保合同与担保信息对应关系表
          ON A.GUAR_CONTRACT_NUM = B.GUAR_CONTRACT_NUM
         AND B.DATA_DATE = I_DATE
        LEFT JOIN SMTMODS.L_AGRE_GUARANTY_INFO C -- 抵质押物详细信息
          ON B.GUARANTEE_SERIAL_NUM = C.GUARANTEE_SERIAL_NUM
         AND C.DATA_DATE = I_DATE
       WHERE A.DATA_DATE = I_DATE
         AND UPPER(C.COLL_STATUS) = 'Y' -- 取有效押品
       GROUP BY A.CONTRACT_NUM ),
       
      L_ACCT_LOAN_PAYM_SCHED_TMP1  AS
     (SELECT /*+ PARALLEL(4)*/
       LALPS.LOAN_NUM LOAN_NUM, SUM(LALPS.OS_PPL ) AS OS_PPL, SUM(LALPS.INTEREST ) AS INTEREST
        FROM SMTMODS.L_ACCT_LOAN_PAYM_SCHED LALPS -- 贷款还款计划信息表
       INNER JOIN SMTMODS.L_ACCT_LOAN_REALESTATE LALR -- 房地产贷款补充信息
          ON LALR.LOAN_NUM = LALPS.LOAN_NUM
         AND LALR.DATA_DATE = I_DATE
       WHERE ( SUBSTR(LALPS.DUE_DATE,1,6) = SUBSTR(I_DATE,1,6) OR
             SUBSTR(LALPS.DUE_DATE_INT,1,6) = SUBSTR(I_DATE,1,6))
         AND LALPS.DATA_DATE = I_DATE
       GROUP BY LALPS.LOAN_NUM),
       
      L_ACCT_LOAN_PAYM_SCHED_TMP AS -- 贷款还款预处理计划表
     ( SELECT /*+ PARALLEL(4)*/
       T.LOAN_NUM AS LOAN_NUM, NVL(T.OS_PPL, 0) - NVL(T1.PAY_AMT, 0) AS OS_PPL, NVL(T.INTEREST, 0) - NVL(T1.PAY_INT_AMT, 0) AS INTEREST
        FROM L_ACCT_LOAN_PAYM_SCHED_TMP1 T
        LEFT JOIN (SELECT AA.LOAN_NUM,
                          SUM(AA.PAY_AMT) AS PAY_AMT,
                          SUM(AA.PAY_INT_AMT) AS PAY_INT_AMT
                     FROM SMTMODS.L_TRAN_LOAN_PAYM AA
                    WHERE DATA_DATE = I_DATE
                      AND PAY_TYPE IN ('02', '03')
                    GROUP BY AA.LOAN_NUM) T1
          ON T.LOAN_NUM = T1.LOAN_NUM),
       
   CONTRACT_NUM_VAL_TMP AS  -- 取押品类型
      (SELECT /*+ USE_HASH(A,B,C,U) PARALLEL(8)*/
       A.CONTRACT_NUM  , SUM(NVL(C.COLL_MK_VAL, 0) * U.CCY_RATE) COLL_MK_VAL
        FROM SMTMODS.L_AGRE_GUA_RELATION A -- 业务合同与担保合同对应关系表
        LEFT JOIN SMTMODS.L_AGRE_GUARANTEE_RELATION B -- 担保合同与担保信息对应关系表
          ON A.GUAR_CONTRACT_NUM = B.GUAR_CONTRACT_NUM
         AND B.DATA_DATE = I_DATE
        LEFT JOIN SMTMODS.L_AGRE_GUARANTY_INFO C -- 抵质押物详细信息
          ON B.GUARANTEE_SERIAL_NUM = C.GUARANTEE_SERIAL_NUM
         AND C.DATA_DATE = I_DATE
        LEFT JOIN SMTMODS.L_PUBL_RATE U
          ON U.BASIC_CCY = C.COLL_CCY
         AND U.CCY_DATE =  I_DATE
         AND U.FORWARD_CCY = 'CNY' -- 折算币种
       WHERE A.DATA_DATE = I_DATE
         AND UPPER(C.COLL_STATUS) = 'Y' -- 押品状态取有效
         AND SUBSTR(C.COLL_TYP, 1, 3) IN ('B01', 'B02', 'B03')
       GROUP BY A.CONTRACT_NUM )

    SELECT  
           T2.ACCT_NUM,    -- 01 协议ID
           SUBSTR(TRIM(G.FIN_LIN_NUM ),1,11)||T6.ORG_NUM, -- 02 机构ID
           T1.CAPITAL_RATE,  -- 03 房地产开发贷款对应的项目资本金比例
           decode(T1.PROJECT_INVESTMENT,0,NULL,T1.PROJECT_INVESTMENT) * NVL(T1.CAPITAL_RATE, 0) / 100 * U.CCY_RATE, -- 04 房地产开发贷款对应的项目资本金金额
           decode(T1.PROJECT_INVESTMENT,0,NULL,T1.PROJECT_INVESTMENT) * U.CCY_RATE , -- 05 房地产开发贷款对应的项目投资额 
           CASE WHEN T1.PROPERTYLOAN_TYP = '2011' THEN '01' -- 2011 企业商业用房贷款
                WHEN T1.PROPERTYLOAN_TYP = '2031' THEN '02' -- 2031个人个人商业用房贷款
                WHEN T1.PROPERTYLOAN_TYP = '2021' THEN '03' -- 2021机关团体商业用房贷款
               ELSE  NULL  -- 如不适用可以允许为空  
             END ITEM_NUM ,  -- 05 商业用房购房贷款购买主体类型
           CASE WHEN  SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035', '2036')  THEN T1.OWN_HOUSE 
             ELSE NULL 
             END AS TS,   -- 06 个人住房贷款对应的住房套数
           CASE WHEN NVL(T3.COLL_MK_VAL * U.CCY_RATE, 0) <> 0 
                THEN sum(T2.LOAN_ACCT_BAL * U.CCY_RATE /  NVL(T3.COLL_MK_VAL * U.CCY_RATE, 0)) -- 贷款余额/评估物价值
                ELSE 1  -- 评估价值为0的，默认LTV为1，放入个人住房贷款LTV > 0.8 ,商业用房购房贷款LTV > 0.5中
                END  AS LTV,  -- 07 贷款价值比 
           CASE WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035') THEN '01'  -- 新建住房贷款
                WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2036') THEN '02' -- 二手房屋贷款
             END BS, -- 08 新建个人住房贷款标识
           CASE  WHEN  SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035', '2036')  THEN   
           (CASE WHEN   T2.INT_RATE_TYP = 'F' THEN '01'
                 WHEN   T2.INT_RATE_TYP <> 'F' -- 取浮动利率
                      AND T2.FLOAT_TYPE = 'A' -- LPR 
                      THEN '02' 
                      ELSE '03'
                       END )
           ELSE NULL 
           END AS FLBS, -- 09 个人住房贷款利率分类标识
          CASE WHEN  SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035', '2036')  THEN
         (CASE WHEN T2.RATE_FLOAT / 1 < 0 THEN '01' -- 贷款利率＜LPR
               WHEN T2.RATE_FLOAT / 1 = 0 THEN '02' -- 贷款利率=LPR
               WHEN T2.RATE_FLOAT / 1 > 0 AND T2.RATE_FLOAT / 1 < 0.6 THEN '03' -- 贷款利率＜LPR+60BP
               WHEN T2.RATE_FLOAT / 1 = 0.6 THEN '04'	 -- 贷款利率=LPR+60BP
               WHEN T2.RATE_FLOAT / 1 > 0.6 THEN '05'  -- 贷款利率﹥LPR+60BP
                 ELSE '00'	-- 不基于贷款市场报价利率（LPR）
                END)
           ELSE NULL 
           END AS LPRBS, -- 10 个人住房贷款基于贷款市场报价利率（LPR）标识     
          CASE WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035', '2036')  THEN T1.AREA -- -- JLBA202411070004 20241212由校验公式YBT_JYF15-10，去掉ELSE0 BY 87V
           END AS JZMJ,  -- 11 个人住房贷款对应房屋建筑面积
           T2.CZB * 100 AS CZSRB,  -- 12 个人住房贷款偿债收入比
          CASE WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035', '2036') THEN     -- -- JLBA202411070004 20241212由校验公式YBT_JYF15-10，去掉ELSE0,YBT_JYF15-16 先NVL再乘汇率 BY 87V
           NVL(T1.DOWN_PAYMENTS,0) * U.CCY_RATE  
           END AS SFJE , -- 13 个人住房贷款首付金额
          CASE WHEN  SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035', '2036') THEN    -- -- JLBA202411070004 20241212由校验公式YBT_JYF15-10，去掉ELSE0 BY 87V
           T1.HOUSE_VAL * U.CCY_RATE  -- 因校验公式YBT_JYF15-10，取房屋总价 BY 87V
           END AS FWZJ, -- 14 个人住房贷款对应房屋总价
          CASE WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035', '2036') THEN    -- -- JLBA202411070004 20241212由校验公式YBT_JYF15-10，去掉ELSE0 BY 87V
          T5.COLL_MK_VAL 
           END AS YQJZ,  -- 15 个人住房贷款对应房地产押品市场价值
           
           /*
         CASE WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035', '2036')  THEN T1.AREA
           ELSE 0 
           END,  -- 11 个人住房贷款对应房屋建筑面积
           T2.CZB * 100,  -- 12 个人住房贷款偿债收入比
           CASE WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035', '2036') THEN    
           T1.DOWN_PAYMENTS * U.CCY_RATE  
          ELSE 0 
           END , -- 13 个人住房贷款首付金额
          CASE WHEN  SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035', '2036') THEN    
           T5.COLL_MK_VAL 
          ELSE 0 
           END , -- 14 个人住房贷款对应房屋总价
          CASE WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035', '2036') THEN    
          T5.COLL_MK_VAL 
          ELSE 0 
           END ,  -- 15 个人住房贷款对应房地产押品市场价值
           */
          TO_CHAR(P_DATE,'YYYY-MM-DD') ,-- 16 采集日期
          TO_CHAR(P_DATE,'YYYY-MM-DD') ,-- 16 采集日期
          T6.ORG_NUM,
          CASE  
           WHEN T2.DEPARTMENTD ='信用卡' THEN '0098KG' -- 吉林银行总行卡部(信用卡中心管理)(0098KG)
           WHEN T2.DEPARTMENTD ='公司金融' OR SUBSTR(T2.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
           WHEN T2.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
           WHEN T2.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
           WHEN SUBSTR(T2.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
           WHEN SUBSTR(T2.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
           END AS TX
        FROM SMTMODS.L_ACCT_LOAN_REALESTATE T1  -- 房地产贷款补充信息
       INNER JOIN SMTMODS.L_ACCT_LOAN T2 -- 贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
        -- AND T2.ACCT_STS <> '3' -- 账户状态 -结清 码表A0005 -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
         AND T2.ACCT_TYP NOT LIKE '90%' -- 贷款账户类型-委托贷款 码表A0004
         AND T2.DATA_DATE = I_DATE
        LEFT JOIN GUARANTY_INFO_TMP T3 -- 押品信息 
          ON T2.ACCT_NUM = T3.CONTRACT_NUM
        LEFT JOIN L_ACCT_LOAN_PAYM_SCHED_TMP T4 -- 贷款还款预处理计划表
          ON T1.LOAN_NUM = T4.LOAN_NUM
        LEFT JOIN CONTRACT_NUM_VAL_TMP T5 -- 取押品类型
          ON T2.ACCT_NUM = T5.CONTRACT_NUM
        LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT T6 -- 贷款合同信息表
          ON T1.ACCT_NUM = T6.CONTRACT_NUM
         AND T6.DATA_DATE = I_DATE  
        LEFT JOIN SMTMODS.L_CUST_ALL A
          ON A.CUST_ID = T2.CUST_ID
         AND A.DATA_DATE = I_DATE
        LEFT JOIN SMTMODS.L_CUST_P C
          ON A.CUST_ID = C.CUST_ID  
         AND C.DATA_DATE = I_DATE
        LEFT JOIN SMTMODS.L_PUBL_RATE U
          ON U.CCY_DATE = I_DATE 
         AND U.BASIC_CCY = T2.CURR_CD -- 基准币种
         AND U.FORWARD_CCY = 'CNY' -- 折算币种  
        LEFT JOIN VIEW_L_PUBL_ORG_BRA G -- 机构表
          ON T6.ORG_NUM = G.ORG_NUM
         AND G.DATA_DATE = I_DATE 
       WHERE T1.DATA_DATE = I_DATE
       --  AND T2.LOAN_ACCT_BAL > 0 -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
       --  AND T6.ACCT_STS <> '2'-- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
         AND T2.CANCEL_FLG <>'Y'  -- 剔除核销数据           
		 -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
         AND (T2.LOAN_STOCKEN_DATE IS NULL  OR T2.LOAN_STOCKEN_DATE >= SUBSTR(I_DATE,1,4)||'0101' )   -- ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
         AND (SUBSTR(T2.ITEM_CD,1,6) IN ('130101','130102','130104','130105')  -- 票据
             OR SUBSTR(T2.ITEM_CD,1,6) IN ('130302','130301')  -- 公司贷款 , 个人贷款
             OR SUBSTR(T2.ITEM_CD,1,4) IN ('1305','1306','7140'))  --  贸易融资  ,垫款  ,银团
         AND NVL(T6.PROD_NAME,'##') NOT IN ('个人遗留贷款无本产品','公司遗留贷款无本产品') -- 剔除无本有息历史数据
         AND (T2.ACCT_STS <> '3'
              OR T2.LOAN_ACCT_BAL > 0 
              OR T2.FINISH_DT >= SUBSTR(I_DATE,1,4)||'0101' ) -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
         AND (T6.ACCT_STS <> '2' OR
		  -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
              T6.CONTRACT_EXP_DT >= SUBSTR(I_DATE,1,4)||'0101'  OR 
             (T6.ACCT_STS = '1' AND T6.CONTRACT_EXP_DT IS NULL AND T6.CONTRACT_ORIG_MATURITY_DT >= SUBSTR(I_DATE,1,4)||'0101') OR -- 修改校验20241015      
             (T6.CP_ID ='DK001000100041' AND T6.CONTRACT_EXP_DT IS NULL AND T6.CONTRACT_ORIG_MATURITY_DT >= SUBSTR(I_DATE,1,4)||'0101')  -- [20250929][姜俐锋][JLBA202507300010][信贷新增产品]: 同网贷部分数据处理方式
             )      
         AND NOT EXISTS(SELECT A.LOAN_NUM,A.WRITE_OFF_DATE -- 核销日期
                FROM SMTMODS.L_ACCT_WRITE_OFF A -- 贷款核销
                WHERE A.DATA_DATE = I_DATE
                  AND A.WRITE_OFF_DATE < I_DATE
                  AND A.LOAN_NUM =T2.LOAN_NUM
                 ) 
         AND  T1.PROPERTYLOAN_TYP<>'5'-- 非房地产类贷款
           GROUP BY   T2.ACCT_NUM,    -- 01 协议ID
           NVL(T3.COLL_MK_VAL * U.CCY_RATE, 0),
           SUBSTR(TRIM(G.FIN_LIN_NUM ),1,11)||T6.ORG_NUM, -- 02 机构ID
           T1.CAPITAL_RATE,  -- 03 房地产开发贷款对应的项目资本金比例
           decode(T1.PROJECT_INVESTMENT,0,NULL,T1.PROJECT_INVESTMENT) * NVL(T1.CAPITAL_RATE, 0) / 100 * U.CCY_RATE, -- 04 房地产开发贷款对应的项目资本金金额
           decode(T1.PROJECT_INVESTMENT,0,NULL,T1.PROJECT_INVESTMENT) * U.CCY_RATE , -- 05 房地产开发贷款对应的项目投资额 
           CASE WHEN T1.PROPERTYLOAN_TYP = '2011' THEN '01' -- 2011 企业商业用房贷款
                WHEN T1.PROPERTYLOAN_TYP = '2031' THEN '02' -- 2031个人个人商业用房贷款
                WHEN T1.PROPERTYLOAN_TYP = '2021' THEN '03' -- 2021机关团体商业用房贷款
               ELSE  NULL  -- 如不适用可以允许为空  
             END   ,  -- 05 商业用房购房贷款购买主体类型
           CASE WHEN  SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035', '2036')  THEN T1.OWN_HOUSE 
             ELSE NULL 
             END  ,   -- 06 个人住房贷款对应的住房套数
         
           CASE WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035') THEN '01'  -- 新建住房贷款
                WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2036') THEN '02' -- 二手房屋贷款
             END  , -- 08 新建个人住房贷款标识
           CASE  WHEN  SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035', '2036')  THEN   
           (CASE WHEN   T2.INT_RATE_TYP = 'F' THEN '01'
                 WHEN   T2.INT_RATE_TYP <> 'F' -- 取浮动利率
                      AND T2.FLOAT_TYPE = 'A' -- LPR 
                      THEN '02' 
                      ELSE '03'
                       END )
           ELSE NULL 
           END  , -- 09 个人住房贷款利率分类标识
          CASE WHEN  SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035', '2036')  THEN
         (CASE WHEN T2.RATE_FLOAT / 1 < 0 THEN '01' -- 贷款利率＜LPR
               WHEN T2.RATE_FLOAT / 1 = 0 THEN '02' -- 贷款利率=LPR
               WHEN T2.RATE_FLOAT / 1 > 0 AND T2.RATE_FLOAT / 1 < 0.6 THEN '03' -- 贷款利率＜LPR+60BP
               WHEN T2.RATE_FLOAT / 1 = 0.6 THEN '04'	 -- 贷款利率=LPR+60BP
               WHEN T2.RATE_FLOAT / 1 > 0.6 THEN '05'  -- 贷款利率﹥LPR+60BP
                 ELSE '00'	-- 不基于贷款市场报价利率（LPR）
                END)
           ELSE NULL 
           END , -- 10 个人住房贷款基于贷款市场报价利率（LPR）标识  
            CASE WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035', '2036')  THEN T1.AREA -- 由校验公式YBT_JYF15-10，去掉ELSE0 BY 87V
           END  ,  -- 11 个人住房贷款对应房屋建筑面积
           T2.CZB * 100  ,  -- 12 个人住房贷款偿债收入比
          CASE WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035', '2036') THEN     -- 由校验公式YBT_JYF15-10，去掉ELSE0,YBT_JYF15-16 先NVL再乘汇率 BY 87V
           NVL(T1.DOWN_PAYMENTS,0) * U.CCY_RATE  
           END   , -- 13 个人住房贷款首付金额
          CASE WHEN  SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035', '2036') THEN    -- 由校验公式YBT_JYF15-10，去掉ELSE0 BY 87V
           T1.HOUSE_VAL * U.CCY_RATE  -- 因校验公式YBT_JYF15-10，取房屋总价 BY 87V
           END , -- 14 个人住房贷款对应房屋总价
          CASE WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035', '2036') THEN    -- 由校验公式YBT_JYF15-10，去掉ELSE0 BY 87V
          T5.COLL_MK_VAL 
           END ,    -- 15 个人住房贷款对应房地产押品市场价值
           
           /*
         CASE WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035', '2036')  THEN T1.AREA
           ELSE 0 
           END,  -- 11 个人住房贷款对应房屋建筑面积
           T2.CZB * 100,  -- 12 个人住房贷款偿债收入比
           CASE WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035', '2036') THEN    
           T1.DOWN_PAYMENTS * U.CCY_RATE  
          ELSE 0 
           END , -- 13 个人住房贷款首付金额
          CASE WHEN  SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035', '2036') THEN    
           T5.COLL_MK_VAL 
          ELSE 0 
           END , -- 14 个人住房贷款对应房屋总价
          CASE WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2032', '2033', '2034', '2035', '2036') THEN    
          T5.COLL_MK_VAL 
          ELSE 0 
           END ,  -- 15 个人住房贷款对应房地产押品市场价值
           */
          TO_CHAR(P_DATE,'YYYY-MM-DD') ,-- 16 采集日期
          TO_CHAR(P_DATE,'YYYY-MM-DD') ,-- 16 采集日期
          T6.ORG_NUM,
          CASE  
           WHEN T2.DEPARTMENTD ='信用卡' THEN '0098KG' -- 吉林银行总行卡部(信用卡中心管理)(0098KG)
           WHEN T2.DEPARTMENTD ='公司金融' OR SUBSTR(T2.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
           WHEN T2.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
           WHEN T2.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
           WHEN SUBSTR(T2.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
           WHEN SUBSTR(T2.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
           END 
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
    SELECT OI_RETCODE,'|',OI_REMESSAGE;
END $$

