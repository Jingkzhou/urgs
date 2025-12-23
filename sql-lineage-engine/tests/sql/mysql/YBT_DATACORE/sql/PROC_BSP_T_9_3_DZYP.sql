DROP Procedure IF EXISTS `PROC_BSP_T_9_3_DZYP` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_9_3_DZYP"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN
/******
      程序名称  ：抵质押品
      程序功能  ：加工抵质押品
      目标表：T_9_3
      源表  ：
      创建人  ：LZ
      创建日期  ：20240110
      版本号：V0.0.1 
  ******/
	-- JLBA202412200001_关于一表通监管数据报送系统修改逻辑及转EAST脚本的需求_20250116 
	-- JLBA202501240018_关于一表通监管数据报送系统变更的需求_20250311
	   /* 需求编号：JLBA202502210009 上线日期：20250415，修改人：姜俐锋，提出人：吴大为 */
            -- 抵质押率 20250423 [姜俐锋][吴大为]：邮件方式提出修改方案需要*100
	   /* 需求编号：JLBA202504060003 上线日期：20250513，修改人：狄家卉，提出人：吴大为  一表通监管数据报送系统、EAST报送系统取数逻辑*/
	-- JLBA202505280002 上线日期：2025-06-19，修改人：巴启威  提出人：吴大为  修改原因：因一表通校验问题发现的代码逻辑调整
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
	SET P_PROC_NAME = 'PROC_BSP_T_9_3_DZYP';
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
	
	TRUNCATE TABLE TMP_9_3_CONTRACT;
	TRUNCATE TABLE t_9_3_GUARANTEE_SERIAL_NUM;
	DELETE FROM T_9_3 WHERE J030037 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
	
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '临时表TMP_9_3_CONTRACT数据插入';
	
	
	
	-- 添加此临时表的目的是筛选合同表中存在的数据
	INSERT INTO TMP_9_3_CONTRACT
	       (
			GUAR_CONTRACT_NUM, -- 担保合同号
			DIS_DEPT
           ) SELECT
			 DISTINCT T3.GUAR_CONTRACT_NUM,
			 CASE  
             WHEN T2.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
             WHEN T2.DEPARTMENTD ='公司金融' OR SUBSTR(T2.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
             WHEN T2.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
             WHEN T2.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
             WHEN SUBSTR(T2.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
             WHEN SUBSTR(T2.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
             ELSE '009804'
             END AS DEPT
		/*CASE  
           WHEN T2.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
           WHEN T2.DEPARTMENTD ='公司金融' OR SUBSTR(T2.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
           WHEN T2.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
           WHEN T2.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
           WHEN SUBSTR(T2.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
           WHEN SUBSTR(T2.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
           END AS DEPT*/
	       FROM SMTMODS.L_AGRE_LOAN_CONTRACT T1 -- 贷款合同信息表
          INNER JOIN SMTMODS.L_ACCT_LOAN T2 -- 贷款借据临时表 
			 ON T1.CONTRACT_NUM = T2.ACCT_NUM
			AND T2.DATA_DATE = I_DATE
		  INNER JOIN SMTMODS.L_AGRE_GUA_RELATION T3 -- 业务合同与担保合同对应关系表
			 ON T1.CONTRACT_NUM = T3.CONTRACT_NUM
			AND T3.DATA_DATE = I_DATE
		    AND T3.REL_STATUS = 'Y'-- [20250513] [狄家卉] [JLBA202504060003][吴大为]关联状态REL_STATUS为N，即引用类型代码为3解除引用，对应的担保合同也不需要报送了
		  INNER JOIN SMTMODS.L_AGRE_GUARANTEE_RELATION T4 -- 担保合同与担保信息对应关系表
			 ON T3.GUAR_CONTRACT_NUM = T4.GUAR_CONTRACT_NUM
			AND T4.DATA_DATE = I_DATE
	      WHERE T1.DATA_DATE = I_DATE
		  -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
			AND ((T2.CANCEL_FLG = 'Y' AND   T1.CONTRACT_EXP_DT >= SUBSTR(I_DATE,1,4)||'0101' ) OR (T2.CANCEL_FLG = 'N' AND   T1.CONTRACT_EXP_DT  IS NULL AND (T2.LOAN_STOCKEN_DATE IS NULL OR T2.LOAN_STOCKEN_DATE >= SUBSTR(I_DATE,1,4)||'0101')))-- ADD BY HAORUI 20250311 JLBA202408200012 LOAN_STOCKEN_DATE
		    AND T1.ACCT_STS='1' -- 取当天核销和存续得数据
		    AND (T3.GUAR_START_DT <= I_DATE  OR  T3.GUAR_START_DT IS NULL )  --   [20250415][姜俐锋][JLBA202502210009][吴大为]: .一表通所有使用的担保合同和贷款合同，生效日期大于当前日期的，过滤掉

	UNION SELECT
			DISTINCT T3.GUAR_CONTRACT_NUM,
			  CASE WHEN A.DEPARTMENTD= '普惠金融' THEN '0098PH'  
                   WHEN A.DEPARTMENTD= '公司金融' or A.DEPARTMENTD IS NULL  THEN '0098JR' 
                   END  AS DIS_DEPT
		   FROM SMTMODS.L_ACCT_OBS_LOAN A -- 贷款表外信息表
          INNER JOIN SMTMODS.L_AGRE_GUA_RELATION T3 -- 业务合同与担保合同对应关系表
			 ON A.acct_no = T3.CONTRACT_NUM
			AND T3.DATA_DATE = I_DATE
		    AND T3.REL_STATUS = 'Y'-- [20250513] [狄家卉] [JLBA202504060003][吴大为]关联状态REL_STATUS为N，即引用类型代码为3解除引用，对应的担保合同也不需要报送了
	      INNER JOIN SMTMODS.L_AGRE_GUARANTEE_RELATION T4 -- 担保合同与担保信息对应关系表
			 ON T3.GUAR_CONTRACT_NUM = T4.GUAR_CONTRACT_NUM
			AND T4.DATA_DATE = I_DATE
	      WHERE A.DATA_DATE = I_DATE
			AND T3.CONTRACT_NUM_TYPE LIKE 'B%'
			AND  A.ACCT_STS='1'
		    AND (T3.GUAR_START_DT <= I_DATE  OR  T3.GUAR_START_DT IS NULL )  --   [20250415][姜俐锋][JLBA202502210009][吴大为]: .一表通所有使用的担保合同和贷款合同，生效日期大于当前日期的，过滤掉
			;

       COMMIT;
		CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);		
	 
	#4.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '临时表t_9_3_GUARANTEE_SERIAL_NUM数据插入';
	
	-- 添加此临时表的目的是拿押品编号找担保协议，取对应唯一担保协议标识
	INSERT INTO t_9_3_GUARANTEE_SERIAL_NUM
	       (
			DBW_GUARANTEE_SERIAL_NUM, -- 担保物编号
			COUNT1
           )

select GUARANTEE_SERIAL_NUM,COUNT(1) from SMTMODS.L_AGRE_GUARANTEE_RELATION  -- 担保合同与担保信息对应关系表
	where  REL_STATUS = 'Y'  -- 关联状态 有效
	AND DATA_DATE = DATA_DATE 
	AND DATA_DATE = I_DATE
	group by  GUARANTEE_SERIAL_NUM
	having count(1) = 1;

       COMMIT;
		CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);		
	
	#5.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '信贷类数据插入';
	
INSERT  INTO T_9_3  (
   J030001,  -- 01.押品ID
   J030002,  -- 02.担保协议ID
   J030003,  -- 03.机构ID
   J030005,  -- 05.抵质押物类型
   J030006,  -- 06.抵质押物名称
   J030007,  -- 07.抵质押物状态
   J030008,  -- 08.起始估值
   J030009,  -- 09.币种
   J030010,  -- 10.最新估值
   J030011,  -- 11.首次估值日期
   J030012,  -- 12.最新估值日期
   J030013,  -- 13.估值到期日期
   J030014,  -- 14.对应唯一担保协议标识
   J030015,  -- 15.抵押顺位
   J030016,  -- 16.抵质押物所有权人名称
   J030017,  -- 17.抵质押物所有权人证件类型
   J030018,  -- 18.抵质押物所有权人证件号码
   J030019,  -- 19.已抵押价值
   J030020,  -- 20.审批抵质押率
   J030021,  -- 21.抵质押率
   J030022,  -- 22.登记日期
   J030023,  -- 23.登记机构
   J030024,  -- 24.质押票证类型
   J030025,  -- 25.质押票证号码
   J030026,  -- 26.质押票证签发机构
   J030027,  -- 27.权证种类
   J030028,  -- 28.权证登记号码
   J030029,  -- 29.权证登记面积
   -- J030030,  -- 30.纳入合格优质流动性资产储备标识  2.0zdsj h
   -- J030031,  -- 31.可被无条件替换的比例   2.0zdsj h
   J030032,  -- 32.触及预警线标识
   J030033,  -- 33.触及平仓线标识
   J030034,  -- 34.交易场所
   J030035,  -- 35.股票股数
   J030036,  -- 36.备注
   J030037,   -- 37.采集日期
   DIS_DATA_DATE, -- 装入数据日期
   DIS_BANK_ID ,   -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID,
   J030038,-- 同业业务ID
   J030039  -- 是否保证金担保
)
 
SELECT T.GUARANTEE_SERIAL_NUM AS J030001, -- 1.押品编号
       T7.GUAR_CONTRACT_NUM AS J030002,  -- 2.担保合同号
       SUBSTR(TRIM(T1.FIN_LIN_NUM), 1, 11) || T.ORG_NUM AS J030003, -- 3.机构ID
       CASE
          WHEN T.COLL_PRO_TYPE LIKE 'A01%'       THEN '01' -- '1.1现金及其等价物'
          WHEN T.COLL_PRO_TYPE LIKE 'A02%'       THEN '02' -- '1.2贵金属'
          WHEN T.COLL_PRO_TYPE LIKE 'A0301%'     THEN '03' -- '1.3.1国债'
          WHEN T.COLL_PRO_TYPE LIKE 'A0302%'     THEN '04' -- '1.3.2地方政府债'
          WHEN T.COLL_PRO_TYPE LIKE 'A0303%'     THEN '05' -- '1.3.3央票'
          WHEN T.COLL_PRO_TYPE LIKE 'A0304%'     THEN '06' -- '1.3.4政府机构债券'
          WHEN T.COLL_PRO_TYPE LIKE 'A0305%'     THEN '07' -- '1.3.5政策性金融债'
          WHEN T.COLL_PRO_TYPE LIKE 'A0306%'     THEN '08' -- '1.3.6商业性金融债'
          WHEN T.COLL_PRO_TYPE LIKE 'A030701%'   THEN '09' -- '1.3.7.1评级在AA+（含）以上非金融企业债'
          WHEN T.COLL_PRO_TYPE LIKE 'A030702%'   THEN '10' -- '1.3.7.2评级在AA+至A之间非金融企业债'
          WHEN T.COLL_PRO_TYPE LIKE 'A030703%'   THEN '11' -- '1.3.7.3评级在A以下或无评级非金融企业债'
          WHEN T.COLL_PRO_TYPE LIKE 'A0308%'     THEN  '12' -- '1.4.1其他票据'
          WHEN T.COLL_PRO_TYPE LIKE 'A04%'       THEN '13' -- '1.4票据'
          WHEN T.COLL_PRO_TYPE LIKE 'A0501%'     THEN '14' -- '1.5上市股票
          WHEN T.COLL_PRO_TYPE LIKE 'A0502%'     THEN '15' -- '1.5非上市股权
          WHEN T.COLL_PRO_TYPE LIKE 'A0503%'     THEN '16' -- '1.5基金
          WHEN T.COLL_PRO_TYPE LIKE 'A06%'       THEN '17' -- '1.6保单'
          WHEN T.COLL_PRO_TYPE LIKE 'A07%'       THEN  '18' -- '1.7资产管理产品'
          WHEN T.COLL_PRO_TYPE LIKE 'A08%'       THEN '19' -- '1.8其他金融质押品'
          WHEN T.COLL_PRO_TYPE LIKE 'B03%'       THEN '25' -- '2.其他应收账款'
          WHEN T.COLL_PRO_TYPE LIKE 'C01%'       THEN '26' -- '3.1居住用房地产'
          WHEN T.COLL_PRO_TYPE LIKE 'C02%'       THEN '27' -- '3.2经营性房地产'
          WHEN T.COLL_PRO_TYPE LIKE 'C03%'       THEN '28' -- '3.3居住用房地产建设用地使用权'
          WHEN T.COLL_PRO_TYPE LIKE 'C04%'       THEN '29' -- '3.4经营性房地产建设用地使用权'
          WHEN T.COLL_PRO_TYPE LIKE 'C05%'       THEN '30' -- '3.5房产类在建工程'
          WHEN T.COLL_PRO_TYPE LIKE 'C06%'       THEN '31' -- '3.6其他房地产类押品'
          WHEN T.COLL_PRO_TYPE LIKE 'D01%'       THEN '32' -- '4.1存货、仓单和提单'
          WHEN T.COLL_PRO_TYPE LIKE 'D02%'       THEN '33' -- '4.2机器设备'
          WHEN T.COLL_PRO_TYPE LIKE 'D0301%'     THEN '34' -- '4.2车辆'
          WHEN T.COLL_PRO_TYPE LIKE 'D0302%'     THEN '35' -- '4.2飞行器
          WHEN T.COLL_PRO_TYPE LIKE 'D0303%'     THEN '36' -- '4.2船舶
          WHEN T.COLL_PRO_TYPE LIKE 'D0304%'     THEN '37' -- '4.2其他交通运输设备
          WHEN T.COLL_PRO_TYPE = 'D0403'         THEN '38' -- '4.4资源资产'  -- 2.0 ZDSJ H
          WHEN T.COLL_PRO_TYPE LIKE 'D0501%'     THEN '39' -- '4.5专利权'
          WHEN T.COLL_PRO_TYPE LIKE 'D0502%'     THEN '40' -- '4.5商标权
          WHEN T.COLL_PRO_TYPE LIKE 'D0503%'     THEN '41' -- '4.5著作权
          WHEN T.COLL_PRO_TYPE LIKE 'D0504%'     THEN '42' -- '4.5其他知识产权
          WHEN T.COLL_PRO_TYPE LIKE 'D0401'      THEN '46' -- 碳排放权 -- 2.0 ZDSJ H
          WHEN T.COLL_PRO_TYPE LIKE 'D0402'      THEN '47' -- 碳排放权 -- 2.0 ZDSJ H
        ELSE '00' -- '4.6其他' -- ||NVL(M2.CODENAME,'其他')  -- 2.0ZDSJ H 
        END AS J030005, -- 5.抵质押物类型
       SUBSTR(T.COLL_NAME, 1, 200) AS J030006,  -- 6.押品名称 
       CASE
         WHEN T4.GUAR_CONTRACT_STATUS = 'Y' THEN  '01'
         ELSE  '00'
       END AS J030007, -- '其他'    -- 7.抵质押物状态    
       T.COLL_ORG_VAL AS J030008,  -- 8.起始估值
       T.COLL_CCY AS J030009,  -- 9.币种 
       T.COLL_MK_VAL AS J030010, -- 10.最新估值
       NVL(TO_CHAR(TO_DATE(T.FIRST_ASSESS_DT, 'YYYYMMDD'), 'YYYY-MM-DD'), '9999-12-31') AS J030011, -- 11.首次评估日期
       NVL(TO_CHAR(TO_DATE(T.NEWLY_ASSESS_DT, 'YYYYMMDD'), 'YYYY-MM-DD'), '9999-12-31') AS J030012, -- 12.最新评估日期
       NVL(TO_CHAR(TO_DATE(T.ASSESS_MATURITY_DT, 'YYYYMMDD'), 'YYYY-MM-DD'),'9999-12-31') AS J030013, -- 13.评估到期日期
       CASE
         WHEN C.DBW_GUARANTEE_SERIAL_NUM IS NOT NULL THEN  '1'
         ELSE  '0'
       END AS J030014, -- 14.对应唯一担保协议标识 
       NVL(REPLACE(T4.GUAR_SEQ, '#', NULL), '1') AS J030015, -- 15.抵押顺位 
       T.SYQRMC   AS J030016, -- 16.抵质押物所有权人名称
       B.GB_CODE  AS J030017, -- 17.抵质押物所有权人证件类型
       T.SYQRZJHM AS J030018,-- 18.抵质押物所有权人证件号码
       '0' AS J030019, -- 19.已抵押价值.在办理该笔信贷业务前，如已进行过抵押业务,填报押品已经抵押的价值，当填报机构为第一顺位时，已抵押价值填报为0。
       T.MORTGAGE_RATIO * 100 AS J030020,-- 20.审批抵质押率
       -- T4.COLLATERAL_RATIO * 100 AS J030021,-- 21.抵质押率 20250423 [姜俐锋][吴大为]：邮件方式提出修改方案需要*100
       T.YPDZYL * 100 AS J030021, -- 21.抵质押率 -- [20250619][巴启威][JLBA202505280002][吴大为]：押品抵质押率直取NGI押品信息中对应的抵质押率
       CASE
         WHEN ((T.COLL_PRO_TYPE LIKE 'D06%')) THEN NULL
         ELSE  NVL(TO_CHAR(TO_DATE(T.REGISTER_DT, 'YYYYMMDD'), 'YYYY-MM-DD'),'9999-12-31')
       END AS J030022, -- 22.登记日期 [20250619][巴启威][JLBA202505280002][吴大为]：不再单独限制 押品类型  A 质押物类 (T.COLL_TYP LIKE 'A%')不取登记日期，口径与抵押类一致
       CASE
         WHEN (T.COLL_TYP LIKE 'A%') THEN NULL 
         ELSE
          CASE
            WHEN ((T.COLL_PRO_TYPE LIKE 'D06%')) THEN  NULL -- 抵质押物类型为其他时登记机构为空
            ELSE  T.DJJG
          END
       END AS J030023, -- T.DJJG 23.登记机构  
       CASE
         WHEN (T.COLL_TYP LIKE 'A0401' OR T.COLL_TYP LIKE 'A0402') THEN '01'
         WHEN T.COLL_TYP LIKE 'A0403' THEN  '02'
         WHEN T.COLL_TYP LIKE 'A06%'  THEN  '04'
         WHEN T.COLL_TYP LIKE 'A02%'  THEN  '05'
         ELSE NULL -- 其他
       END AS J030024,-- 24.质押票证类型
       CASE
         WHEN (T.COLL_TYP LIKE 'A%') THEN T.COLL_BILL_NUM
         ELSE NULL 
       END AS J030025,  -- 25.质押票证号码
       T.BILL_BANK_CODE AS J030026, -- 26.质押票证签发机构 20240618 修改逻辑,原为 
		   CASE
         WHEN T.COLL_TYP LIKE 'B01%' OR T.COLL_TYP LIKE 'B02%' THEN '0100' -- B01个人住房 B02非个人住房类房产  待确认
         WHEN T.COLL_TYP LIKE 'B06%'    THEN '0200' -- B06其它不动产  待确认
         WHEN T.COLL_TYP LIKE 'B03%'    THEN '0300' -- B03 土地使用权(包含土地附着物)
         WHEN T.COLL_TYP = 'B0403'      THEN '0400' -- B0403  林权
         WHEN T.COLL_TYP = 'B05%'       THEN '0199' -- 其他房地产类权证
         WHEN T.COLL_TYP LIKE 'A08%'    THEN '0500' -- A08  应收账款     待确认
         WHEN T.COLL_PRO_TYPE = 'D0501' THEN '0600' -- 专利权
         WHEN T.COLL_PRO_TYPE = 'D0502' THEN '0700' -- 商标权
         WHEN T.COLL_PRO_TYPE = 'D0503' THEN '0800' -- 著作权
         WHEN T.COLL_TYP = 'B0401'      THEN '0900' -- B0401 采矿权
         ELSE '0000' -- 其他
       END AS J030027,  -- 27.权证种类
       SUBSTR(COALESCE(T.WARRANT_CODE,
                       T.JZ_HOUSE_LAND_NUM,
                       T.SY_HOUSE_LAND_NUM,
                       T.JZ_BUSINESS_HOUSE_NUM,
                       T.SY_BUSINESS_HOUSE_NUM),  1,  100) AS J030028,  -- 28.权证登记号码       居住用房房产证（不动产权证号)   商业用房、工业用房房产证（不动产权证号）    住用房表房地产买卖合同编号       商业用房、工业用房表房地产买卖合同编号     
       ROUND(T.PPTY_AREA, 2) AS J030029, -- 29.权证登记面积  -- 一表通转EAST 20240614 LMH
       CASE
         WHEN T.COLL_TYP = 'A0606' THEN '1' -- '是'
         ELSE  '0'
       END AS J030032,  -- 32.触及预警线标识
       CASE
         WHEN T.COLL_TYP = 'A0606' THEN  '1' -- '是'
         ELSE  '0'
       END AS J030033,  -- 33.触及平仓线标识
       CASE
         WHEN T.COLL_TYP = 'A0606' THEN '01' -- '场内'
         ELSE '02'
       END AS J030034, -- 34.交易场所
       SUBSTR(T.GPSL, 0, 9) AS J030035, -- 35.股票股数  20250419 zhoujingkun  chaochang jiequ 10wei   yuanlai 0,11   
       NULL AS J030036, -- 36.备注
       TO_CHAR(TO_DATE(I_DATE, 'YYYYMMDD'), 'YYYY-MM-DD') AS J030037, -- 37采集日期
       TO_CHAR(TO_DATE(I_DATE, 'YYYYMMDD'), 'YYYY-MM-DD') AS DIS_DATA_DATE,
       T.ORG_NUM AS DIS_BANK_ID,
       '信贷' AS DIS_DEPT,
       T10.DIS_DEPT AS DEPARTMENT_ID,
       NULL AS J030038, -- 2.0 ZDSJ H
       '0' AS J030039 -- 2.0 ZDSJ H
  FROM SMTMODS.L_AGRE_GUARANTY_INFO T -- 抵质押物详细信息
  LEFT JOIN VIEW_L_PUBL_ORG_BRA T1 -- 机构表
    ON T.ORG_NUM = T1.ORG_NUM
   AND T1.DATA_DATE = I_DATE
 INNER JOIN SMTMODS.L_AGRE_GUARANTEE_RELATION T7 -- 担保合同与担保信息对应关系表
    ON T.GUARANTEE_SERIAL_NUM = T7.GUARANTEE_SERIAL_NUM
   AND T7.REL_STATUS = 'Y'
   AND T7.DATA_DATE = I_DATE -- AND T7.RN=1
 INNER JOIN SMTMODS.L_AGRE_GUARANTEE_CONTRACT T4 -- 担保合同信息
    ON T7.GUAR_CONTRACT_NUM = T4.GUAR_CONTRACT_NUM
   AND T4.GUAR_CONTRACT_STATUS = 'Y'
   AND T4.GURA_CONTRACT_AMT <> 0 -- 担保金额不允许为0
   AND T4.DATA_DATE = I_DATE
 INNER JOIN TMP_9_3_CONTRACT T10 -- 筛选表内外合同表中存在的数据
    ON T7.GUAR_CONTRACT_NUM = T10.GUAR_CONTRACT_NUM --  筛选合同表中存在的数据
  LEFT JOIN M_DICT_CODETABLE B
    ON T.SYQRZJLX = B.L_CODE
   AND B.L_CODE_TABLE_CODE = 'C0012'
  LEFT JOIN T_9_3_GUARANTEE_SERIAL_NUM C
    ON T.GUARANTEE_SERIAL_NUM = C.DBW_GUARANTEE_SERIAL_NUM
  LEFT JOIN SMTMODS.L_AGRE_BOND_INFO T11 -- 债务信息表
    ON T.GUARANTEE_SERIAL_NUM = T11.STOCK_CD
   AND T11.DATA_DATE = T.DATA_DATE
 WHERE T.DATA_DATE = I_DATE
   AND T.COLL_STATUS = 'Y';
 COMMIT;
	
CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);

   -- 20250313 吴大为老师指示 去掉 回购类数据
	/*
	#6.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '回购类数据插入';

	 -- zjk update 20241113 加工临时表 由代码中提出创建事务级临时表，提高执行效率
   DROP TEMPORARY TABLE IF EXISTS temp_L_CUST_BILL_TY;
	CREATE TEMPORARY table temp_L_CUST_BILL_TY as
	select * from (SELECT A.*,
	                 ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.CUST_ID) RN
	            FROM SMTMODS.L_CUST_BILL_TY A
	           WHERE A.DATA_DATE = I_DATE) B 
	   WHERE B.RN = '1';
INSERT  INTO T_9_3  (
   J030001,  -- 01.押品ID
   J030002,  -- 02.担保协议ID
   J030003,  -- 03.机构ID
   J030005,  -- 05.抵质押物类型
   J030006,  -- 06.抵质押物名称
   J030007,  -- 07.抵质押物状态
   J030008,  -- 08.起始估值
   J030009,  -- 09.币种
   J030010,  -- 10.最新估值
   J030011,  -- 11.首次估值日期
   J030012,  -- 12.最新估值日期
   J030013,  -- 13.估值到期日期
   J030014,  -- 14.对应唯一担保协议标识
   J030015,  -- 15.抵押顺位
   J030016,  -- 16.抵质押物所有权人名称
   J030017,  -- 17.抵质押物所有权人证件类型
   J030018,  -- 18.抵质押物所有权人证件号码
   J030019,  -- 19.已抵押价值
   J030020,  -- 20.审批抵质押率
   J030021,  -- 21.抵质押率
   J030022,  -- 22.登记日期
   J030023,  -- 23.登记机构
   J030024,  -- 24.质押票证类型
   J030025,  -- 25.质押票证号码
   J030026,  -- 26.质押票证签发机构
   J030027,  -- 27.权证种类
   J030028,  -- 28.权证登记号码
   J030029,  -- 29.权证登记面积
   -- J030030,  -- 30.纳入合格优质流动性资产储备标识
   -- J030031,  -- 31.可被无条件替换的比例
   J030032,  -- 32.触及预警线标识
   J030033,  -- 33.触及平仓线标识
   J030034,  -- 34.交易场所
   J030035,  -- 35.股票股数
   J030036,  -- 36.备注
   J030037,   -- 37.采集日期
   DIS_DATA_DATE, -- 装入数据日期
   DIS_BANK_ID ,   -- 机构号
   DIS_DEPT ,      -- 业务条线
   DEPARTMENT_ID,
   J030038 ,-- 同业业务ID
   J030039  -- 是否保证金担保
)	 
 
SELECT T.SUBJECT_CD AS J030001,  -- 1.押品编号
       T1.DEAL_ACCT_NUM AS J030002, -- 成交单编号 和 主资产代码一对一 -- 2.担保合同号
       SUBSTR(C.FIN_LIN_NUM, 1, 11) || '009804' AS J030003,  -- 3.机构ID
       CASE
         WHEN T.COLL_SUBJECT_TYPE = '国债' THEN  '03'
         WHEN T.COLL_SUBJECT_TYPE = '中期票据' THEN  '13'
         WHEN T.COLL_SUBJECT_TYPE = '同业存单' THEN  '01'
         WHEN T.COLL_SUBJECT_TYPE = '政府债券' THEN  '06'
         WHEN T.COLL_SUBJECT_TYPE = '政策性银行' THEN '07'
         WHEN T.COLL_SUBJECT_TYPE = '超短期融资券' AND
              T4.APPRAISE_TYPE IN ('1', '2') THEN  '09'
         WHEN T.COLL_SUBJECT_TYPE = '超短期融资券' AND
              T4.APPRAISE_TYPE IN ('3', '4', '5', '6') THEN  '10'
         WHEN T.COLL_SUBJECT_TYPE = '超短期融资券' AND
              T4.APPRAISE_TYPE IN ('7', '8', '9', 'a', 'b', 'c')  THEN '11'
         WHEN T4.STOCK_PRO_TYPE LIKE 'C%' AND T4.ISSU_ORG = 'D03' THEN '08'
         WHEN T4.STOCK_PRO_TYPE LIKE 'A%' AND T4.ISSU_ORG = 'A02' THEN '04'
         WHEN T4.STOCK_PRO_TYPE LIKE 'B%' AND T4.ISSU_ORG = 'A01' THEN '05'
         WHEN T.ORG_NUM = '009804' AND T.SUBJECT_NAM LIKE '%国债%' THEN '03' -- 2.0zdsj h  与金融市场部桑铭蔚老师确认  用名称做判断
         WHEN T.ORG_NUM = '009804' AND
              (T.SUBJECT_NAM LIKE '%进出%' OR T.SUBJECT_NAM LIKE '%农发%' OR
              T.SUBJECT_NAM LIKE '%国开%') THEN  '07' -- 2.0zdsj h
         WHEN T.ORG_NUM = '009804' AND
              (T.SUBJECT_NAM LIKE '%PPN%' OR T.SUBJECT_NAM LIKE '%MTN%') THEN  '09' -- 2.0zdsj h
         ELSE  '00' -- 2.0 zdsj h
       END AS J030005 ,  -- 5.押品类型
       T.SUBJECT_NAM AS J030006, -- 6.押品名称
       '01' AS J030007,  -- 7.抵质押物状态   
       NVL(t.COLL_ORG_VAL,0) AS J030008,  -- 8.起始估值
       T1.CURR_CD AS J030009, -- 9.币种 
       NVL(T.COLL_MK_VAL,0) AS J030010,  -- 10.最新估值
       NVL(TO_CHAR(TO_DATE(T1.BEG_DT, 'YYYYMMDD'), 'YYYY-MM-DD'),'9999-12-31') AS J030011, -- 11.首次评估日期
       NVL(TO_CHAR(TO_DATE(T.ZXPGRQ, 'YYYYMMDD'), 'YYYY-MM-DD'), '9999-12-31') AS J030012, -- 12.最新评估日期
       NVL(TO_CHAR(TO_DATE(T1.END_DT, 'YYYYMMDD'), 'YYYY-MM-DD'),'9999-12-31') AS J030013, -- 13.评估到期日期
       '1' AS J030014, -- 14.对应唯一担保协议标识
       '1' AS J030015 , -- 15.抵押顺位
       T.CUST_ID AS J030016,  -- 16.抵质押物所有权人名称
       nvl(B.GB_CODE,B1.GB_CODE) AS J030017, -- 17.抵质押物所有权人证件类型 -- 20250116
       T2.TYSHXYDM AS J030018, -- 18.抵质押物所有权人证件号码
       '0' AS J030019, -- 19.已抵押价值.在办理该笔信贷业务前，如已进行过抵押业务,填报押品已经抵押的价值，当填报机构为第一顺位时，已抵押价值填报为0。
       T.MORTGAGE_RATIO * 100 AS J030020,  -- 20.审批抵质押率
       T.MORTGAGE_RATIO AS J030021,  -- 21.抵质押率 20240618 原为 T4.MORTGAGE_RATIO * 100,为保证与EAST匹配,修改为当前逻辑
       NULL AS J030022, -- 22.登记日期  T1.BEG_DT
       NULL AS J030023, -- 23.登记机构 
       '04' AS J030024, -- 24.质押票证类型
       T.SUBJECT_CD AS J030025,  -- 25.质押票证号码
       T4.ISSU_ORG_NAM AS J030026, -- 26.质押票证签发机构
       NULL AS J030027, -- 27.权证种类
       NULL AS J030028, -- 28.权证登记号码,字段如下:  -- 权证登记号码       居住用房房产证（不动产权证号)   商业用房、工业用房房产证（不动产权证号）    住用房表房地产买卖合同编号       商业用房、工业用房表房地产买卖合同编号     
       NULL AS J030029, -- 29.权证登记面积
       NULL AS J030032, -- 32.触及预警线标识
       NULL AS J030033, -- 33.触及平仓线标识
       NULL AS J030034, -- 34.交易场所 -- BA口径：只有质押物为股票的时候，才涉及到场内场外，金融市场部的质押物不涉及股票，此字段默认空。
       NULL AS J030035, -- 35.股票股数
       NULL AS J030036, -- 36.备注
       TO_CHAR(TO_DATE(I_DATE, 'YYYYMMDD'), 'YYYY-MM-DD') AS J030037, -- 37采集日期
       TO_CHAR(TO_DATE(I_DATE, 'YYYYMMDD'), 'YYYY-MM-DD') AS DIS_DATA_DATE,
       '009804' AS DIS_BANK_ID,
       '回购' AS DIS_DEPT,
       '009804' AS DEPARTMENT_ID,
       -- T.ACCT_NUM || T.SUBJECT_CD , -- 同业业务ID    -- 2.0zdsj h
       T1.ACCT_NUM || T1.REF_NUM AS J030038, -- 同业业务ID   20250311
       '0' AS J030039 -- 是否保证金担保     -- 2.0zdsj h
  FROM SMTMODS.L_AGRE_REPURCHASE_GUARANTY_INFO T -- 回购抵质押物详细信息
 INNER JOIN (SELECT * FROM SMTMODS.L_ACCT_FUND_REPURCHASE T -- 回购信息表
               WHERE T.DATA_DATE = I_DATE 
               AND SUBSTR(T.BUSI_TYPE,1,1) IN ('1','2') -- 1-买入返售 ;2-卖出回购
               AND T.ASS_TYPE IN ('1','2','3') -- 1-债券 2-商业汇票 3-其他票据-- 票据报到6_14票据再贴现里面 20240618因流动性指标 将票据放开
               AND (((T.ACCT_CLDATE > I_DATE OR T.ACCT_CLDATE IS NULL) AND T.BALANCE > 0) 
                  OR (T.ACCT_CLDATE = I_DATE AND T.BALANCE = 0) 
                  OR T.ACCRUAL <> 0 ) -- 与4.3，7.6同步  ALTER BY DJH 20240719 有利息无本金数据也加进来
               AND  T.END_DT>=I_DATE 
               )  t1  
    ON T.ACCT_NUM = T1.ACCT_NUM
  LEFT JOIN TEMP_L_CUST_BILL_TY T2
    -- ON (T.CUST_ID = T2.FINA_ORG_NAME OR T.CUST_ID = T2.CUST_SHORT_NAME)。
    ON t.CUST_ID = t2.ECIF_CUST_ID
   AND T.DATA_DATE = T2.DATA_DATE
  LEFT JOIN SMTMODS.L_CUST_ALL T3 -- 全量客户信息表
    ON T2.ECIF_CUST_ID = T3.CUST_ID
   AND T3.DATA_DATE = T2.DATA_DATE
  LEFT JOIN SMTMODS.L_AGRE_BOND_INFO T4 -- 债券信息表
    ON T.SUBJECT_CD = T4.STOCK_CD
   AND T4.DATA_DATE = T.DATA_DATE
  LEFT JOIN SMTMODS.L_CUST_ALL T5 -- 全量客户信息表
    ON T1.CUST_ID = T5.CUST_ID
   AND T5.DATA_DATE = I_DATE  
  LEFT JOIN M_DICT_CODETABLE B
    ON T3.ID_TYPE2 = B.L_CODE
   AND B.L_CODE_TABLE_CODE = 'C0012'
  LEFT JOIN M_DICT_CODETABLE B1  -- 20250116
    ON T5.ID_TYPE2 = B1.L_CODE
   AND B1.L_CODE_TABLE_CODE = 'C0001'   
  LEFT JOIN SMTMODS.L_PUBL_ORG_BRA C -- 机构表
    ON T.ORG_NUM = C.ORG_NUM
   AND C.DATA_DATE = T.DATA_DATE
 WHERE T.TRADE_DIRECT = '逆回购'
   AND T.DATA_DATE = I_DATE
 ;
   COMMIT;
	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);		
	*/
	
	-- 保证金 2.0zdsj h
	 	
INSERT  INTO T_9_3  (
   J030001,  -- 01.押品ID
   J030002,  -- 02.担保协议ID
   J030003,  -- 03.机构ID
   J030005,  -- 05.抵质押物类型
   J030006,  -- 06.抵质押物名称
   J030007,  -- 07.抵质押物状态
   J030008,  -- 08.起始估值
   J030009,  -- 09.币种
   J030010,  -- 10.最新估值
   J030011,  -- 11.首次估值日期
   J030012,  -- 12.最新估值日期
   J030013,  -- 13.估值到期日期
   J030014,  -- 14.对应唯一担保协议标识
   J030015,  -- 15.抵押顺位
   J030016,  -- 16.抵质押物所有权人名称
   J030017,  -- 17.抵质押物所有权人证件类型
   J030018,  -- 18.抵质押物所有权人证件号码
   J030019,  -- 19.已抵押价值
   J030020,  -- 20.审批抵质押率
   J030021,  -- 21.抵质押率
   J030022,  -- 22.登记日期
   J030023,  -- 23.登记机构
   J030024,  -- 24.质押票证类型
   J030025,  -- 25.质押票证号码
   J030026,  -- 26.质押票证签发机构
   J030027,  -- 27.权证种类
   J030028,  -- 28.权证登记号码
   J030029,  -- 29.权证登记面积
 --  J030030,  -- 30.纳入合格优质流动性资产储备标识  2.0zdsj h
 --  J030031,  -- 31.可被无条件替换的比例   2.0zdsj h
   J030032,  -- 32.触及预警线标识
   J030033,  -- 33.触及平仓线标识
   J030034,  -- 34.交易场所
   J030035,  -- 35.股票股数
   J030036,  -- 36.备注
   J030037,   -- 37.采集日期
   DIS_DATA_DATE, -- 装入数据日期
   DIS_BANK_ID ,   -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID,
   J030038 ,-- 同业业务ID
   J030039  -- 是否保证金担保
)
               SELECT T.SECURITY_ACCT_NUM || '-' || T.CONTRACT_NUM, -- 01.押品ID
                      'BZJ' || '_' || T.CONTRACT_NUM, -- 02.担保协议ID 20241031
                      SUBSTR(TRIM(T1.FIN_LIN_NUM), 1, 11) || T.ORG_NUM, -- 03.机构ID
                      CASE
                        WHEN D.XZLX IN ('003', '004') THEN  '02'
                        ELSE  '01'
                      END AS DZYLX, -- 05.抵质押物类型
                      '保证金', -- 06.抵质押物名称
                      CASE
                        WHEN D.ACCT_STS = 'N' THEN '01' -- 正常
                        WHEN SUBSTR(D.ACCT_STS, 1, 1) = 'W' THEN '02' -- 冻结
                        ELSE  '00' -- 其它
                      END AS DZYWZT, -- 07.抵质押物状态    20241031 原NULL
                      T.CONTRACT_AMT * T.SECURITY_RATE * T3.CCY_RATE, -- 08.起始估值
                      T.SECURITY_CURR, -- 09.币种
                      T.CONTRACT_AMT * T.SECURITY_RATE * T3.CCY_RATE, -- 10.最新估值
                      TO_CHAR(TO_DATE(COALESCE(T.CONTRACT_SIGN_DT,t.CONTRACT_EFF_DT,D.ACCT_OPDATE), 'YYYYMMDD'), 'YYYY-MM-DD'), -- 11.首次估值日期  [20250415][姜俐锋][JLBA202502210009][吴大为]:合同签订日期空取贷款合同生效日期
                      TO_CHAR(TO_DATE(COALESCE(T.CONTRACT_SIGN_DT,t.CONTRACT_EFF_DT,D.ACCT_OPDATE), 'YYYYMMDD'), 'YYYY-MM-DD'), -- 12.最新估值日期  [20250415][姜俐锋][JLBA202502210009][吴大为]:合同签订日期空取贷款合同生效日期
                      TO_CHAR(TO_DATE(T.CONTRACT_ORIG_MATURITY_DT, 'YYYYMMDD'),'YYYY-MM-DD'), -- 13.估值到期日期
                      '1', -- 14.对应唯一担保协议标识
                      '1', -- 15.抵押顺位
                      T2.CUST_NAM, -- 16.抵质押物所有权人名称
                      F.GB_CODE, -- 17.抵质押物所有权人证件类型
                      T2.ID_NO, -- 18.抵质押物所有权人证件号码
                      '0', -- T.CONTRACT_AMT * T.SECURITY_RATE * T3.CCY_RATE, -- 19.已抵押价值
                      T.SECURITY_RATE, -- 20.审批抵质押率
                      T.SECURITY_RATE, -- 21.抵质押率
                      TO_CHAR(TO_DATE(COALESCE(T.CONTRACT_SIGN_DT,t.CONTRACT_EFF_DT,D.ACCT_OPDATE), 'YYYYMMDD'), 'YYYY-MM-DD'), -- 22.登记日期   [20250415][姜俐锋][JLBA202502210009][吴大为]:合同签订日期空取贷款合同生效日期
                      NULL, -- 23.登记机构
                      NULL, -- 24.质押票证类型
                      NULL, -- 25.质押票证号码
                      NULL, -- 26.质押票证签发机构
                      '0000', -- 27.权证种类
                      NULL, -- 28.权证登记号码
                      NULL, -- 29.权证登记面积
                      NULL, -- 32.触及预警线标识
                      NULL, -- 33.触及平仓线标识
                      NULL, -- 34.交易场所
                      NULL, -- 35.股票股数
                      NULL, -- 36.备注
                      TO_CHAR(TO_DATE(I_DATE, 'YYYYMMDD'), 'YYYY-MM-DD'), -- 37.采集日期
                      TO_CHAR(TO_DATE(I_DATE, 'YYYYMMDD'), 'YYYY-MM-DD'),
                      T.ORG_NUM,
                      '保证金1',
                      CASE
                        WHEN (T4.ACCT_NUM IS NOT NULL) THEN
                         CASE
                           WHEN T4.DEPARTMENTD = '信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
                           WHEN T4.DEPARTMENTD = '公司金融' OR  SUBSTR(T4.ITEM_CD, 1, 6) IN ('130601', '130602') THEN  '0098JR' -- 公司金融部(0098JR)
                           WHEN T4.DEPARTMENTD = '个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
                           WHEN T4.DEPARTMENTD = '普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
                           WHEN SUBSTR(T4.ITEM_CD, 1, 6) = '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
                           WHEN SUBSTR(T4.ITEM_CD, 1, 6) IN ('130101', '130102', '130104', '130105', '130103') THEN '009804' -- 吉林银行金融市场部(009804)
                           ELSE '009804'
                         END
                        WHEN (T5.ACCT_NO IS NOT NULL) THEN
                         CASE
                           WHEN T5.DEPARTMENTD = '普惠金融' THEN  '0098PH'
                           WHEN T5.DEPARTMENTD = '公司金融' OR T5.DEPARTMENTD IS NULL THEN '0098JR'
                         END
                      END AS DEPARTMENT_ID,
                      NULL,
                      '1'
                 FROM SMTMODS.L_AGRE_LOAN_CONTRACT T
                 LEFT JOIN (SELECT *
                              FROM (SELECT T.O_ACCT_NUM,
                                           T.DEPOSIT_NUM,
                                           T.XZLX,
                                           T.ACCT_STS,
                                           t.ACCT_OPDATE, --  [20250415][姜俐锋][JLBA202502210009][吴大为]:保证金帐号开户日期
                                           ROW_NUMBER() OVER(PARTITION BY T.O_ACCT_NUM ORDER BY T.DEPOSIT_NUM) AS NUM
                                      FROM SMTMODS.L_ACCT_DEPOSIT T
                                     WHERE T.DATA_DATE = I_DATE) T1
                             WHERE T1.NUM = 1) D
                   ON T.SECURITY_ACCT_NUM = D.O_ACCT_NUM
                 LEFT JOIN VIEW_L_PUBL_ORG_BRA T1 -- 机构表
                   ON T.ORG_NUM = T1.ORG_NUM
                  AND T1.DATA_DATE = I_DATE
                 LEFT JOIN SMTMODS.L_PUBL_RATE T3
                   ON T3.DATA_DATE = I_DATE
                  AND T3.BASIC_CCY = T.SECURITY_CURR -- 基准币种
                  AND T3.FORWARD_CCY = 'CNY'
                 LEFT JOIN SMTMODS.L_CUST_ALL T2
                   ON T.CUST_ID = T2.CUST_ID
                  AND T2.DATA_DATE = I_DATE
                 LEFT JOIN M_DICT_CODETABLE F
                   ON T2.ID_TYPE2 = F.L_CODE   -- 20250116
                  AND F.L_CODE_TABLE_CODE = 'C0001'
                 LEFT JOIN (SELECT *
                              FROM (SELECT T.ACCT_NUM,
                                           T.DEPARTMENTD,
                                           T.ITEM_CD,
                                           T.ACCT_TYP,
                                           ROW_NUMBER() OVER(PARTITION BY T.ACCT_NUM ORDER BY T.LOAN_NUM) AS NUM
                                      FROM SMTMODS.L_ACCT_LOAN T
                                     WHERE T.DATA_DATE = I_DATE) T1
                             WHERE T1.NUM = 1) T4
                   ON T.CONTRACT_NUM = T4.ACCT_NUM
                 LEFT JOIN (SELECT *
                              FROM (SELECT T.ACCT_NO,
                                           T.DEPARTMENTD,
                                           T.ACCT_TYP,
                                           ROW_NUMBER() OVER(PARTITION BY T.ACCT_NO ORDER BY T.ACCT_NUM) AS NUM
                                      FROM SMTMODS.L_ACCT_OBS_LOAN T
                                     WHERE T.DATA_DATE = I_DATE) T1
                             WHERE T1.NUM = 1) T5
                   ON T.CONTRACT_NUM = T5.ACCT_NO
                WHERE T.DATA_DATE = I_DATE
                  AND T.SECURITY_ACCT_NUM IS NOT NULL
                  AND ((T.ACCT_STS = '1' AND T.CONTRACT_AMT <> 0)
                      OR T.CONTRACT_ORIG_MATURITY_DT >= SUBSTR(I_DATE,1,4)||'0101' ) -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
                  AND (T.CONTRACT_EFF_DT <= I_DATE  OR T.CONTRACT_EFF_DT IS NULL) -- [2025-05-13][巴启威][JLBA202504060003]: 剔除合同生效日期大于数据日期的贷款合同，报送范围与6.2保持一致
               UNION ALL -- 2.0 ZDSJ H
               SELECT T.HZF_SECURITY_ACCT_NUM || '-' || T.CONTRACT_NUM, -- 01.押品ID
                      'BZJ' || '_' || T.CONTRACT_NUM, -- 02.担保协议ID
                      SUBSTR(TRIM(T1.FIN_LIN_NUM), 1, 11) || T.ORG_NUM, -- 03.机构ID
                      CASE
                        WHEN D.XZLX IN ('003', '004') THEN '02'
                        ELSE '01'
                      END AS DZYLX, -- 05.抵质押物类型 
                      '保证金', -- 06.抵质押物名称
                      CASE
                        WHEN D.ACCT_STS = 'N' THEN '01' -- 正常
                        WHEN SUBSTR(D.ACCT_STS, 1, 1) = 'W' THEN '02' -- 冻结
                        ELSE '00' -- 其它
                      END AS DZYWZT, -- 07.抵质押物状态 20241031 NULL
                      T.CONTRACT_AMT * T.HZF_SECURITY_RATE * T3.CCY_RATE, -- 08.起始估值
                      T.HZF_SECURITY_CURR, -- 09.币种
                      T.CONTRACT_AMT * T.HZF_SECURITY_RATE * T3.CCY_RATE, -- 10.最新估值
                      TO_CHAR(TO_DATE(COALESCE(T.CONTRACT_SIGN_DT,t.CONTRACT_EFF_DT,D.ACCT_OPDATE), 'YYYYMMDD'), 'YYYY-MM-DD'), -- 11.首次估值日期  [20250415][姜俐锋][JLBA202502210009][吴大为]:合同签订日期空取贷款合同生效日期
                      TO_CHAR(TO_DATE(COALESCE(T.CONTRACT_SIGN_DT,t.CONTRACT_EFF_DT,D.ACCT_OPDATE), 'YYYYMMDD'), 'YYYY-MM-DD'), -- 12.最新估值日期  [20250415][姜俐锋][JLBA202502210009][吴大为]:合同签订日期空取贷款合同生效日期
                      TO_CHAR(TO_DATE(T.CONTRACT_ORIG_MATURITY_DT, 'YYYYMMDD'),'YYYY-MM-DD'), -- 13.估值到期日期
                      '1', -- 14.对应唯一担保协议标识
                      '1', -- 15.抵押顺位
                      T2.CUST_NAM, -- 16.抵质押物所有权人名称
                      F.GB_CODE, -- 17.抵质押物所有权人证件类型
                      T2.ID_NO, -- 18.抵质押物所有权人证件号码
                      '0', -- T.CONTRACT_AMT * T.HZF_SECURITY_RATE * T3.CCY_RATE, -- 19.已抵押价值
                      T.HZF_SECURITY_RATE, -- 20.审批抵质押率
                      T.HZF_SECURITY_RATE, -- 21.抵质押率
                      TO_CHAR(TO_DATE(COALESCE(T.CONTRACT_SIGN_DT,t.CONTRACT_EFF_DT,D.ACCT_OPDATE), 'YYYYMMDD'), 'YYYY-MM-DD'), -- 22.登记日期 [20250415][姜俐锋][JLBA202502210009][吴大为]:合同签订日期空取贷款合同生效日期
                      NULL, -- 23.登记机构
                      NULL, -- 24.质押票证类型 -- [20250415][姜俐锋][JLBA202502210009][吴大为]:默认null
                      NULL, -- 25.质押票证号码
                      NULL, -- 26.质押票证签发机构
                      '0000', -- 27.权证种类
                      NULL, -- 28.权证登记号码
                      NULL, -- 29.权证登记面积
                      NULL, -- 32.触及预警线标识
                      NULL, -- 33.触及平仓线标识
                      NULL, -- 34.交易场所
                      NULL, -- 35.股票股数
                      NULL, -- 36.备注
                      TO_CHAR(TO_DATE(I_DATE, 'YYYYMMDD'), 'YYYY-MM-DD'), -- 37.采集日期
                      TO_CHAR(TO_DATE(I_DATE, 'YYYYMMDD'), 'YYYY-MM-DD'),
                      T.ORG_NUM,
                      '保证金2',
                      CASE
                        WHEN (T4.ACCT_NUM IS NOT NULL) THEN
                         CASE
                           WHEN T4.DEPARTMENTD = '信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
                           WHEN T4.DEPARTMENTD = '公司金融' OR SUBSTR(T4.ITEM_CD, 1, 6) IN ('130601', '130602') THEN '0098JR' -- 公司金融部(0098JR)
                           WHEN T4.DEPARTMENTD = '个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
                           WHEN T4.DEPARTMENTD = '普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
                           WHEN SUBSTR(T4.ITEM_CD, 1, 6) = '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
                           WHEN SUBSTR(T4.ITEM_CD, 1, 6) IN ('130101', '130102', '130104', '130105', '130103') THEN '009804' -- 吉林银行金融市场部(009804)
                           ELSE '009804'
                         END
                        WHEN (T5.ACCT_NO IS NOT NULL) THEN
                         CASE
                           WHEN T5.DEPARTMENTD = '普惠金融' THEN
                            '0098PH'
                           WHEN T5.DEPARTMENTD = '公司金融' OR T5.DEPARTMENTD IS NULL THEN
                            '0098JR'
                         END
                      END AS DEPARTMENT_ID,
                      NULL,
                      '1'
                 FROM SMTMODS.L_AGRE_LOAN_CONTRACT T
                 LEFT JOIN (SELECT *
                              FROM (SELECT T.O_ACCT_NUM,
                                           T.DEPOSIT_NUM,
                                           T.XZLX,
                                           T.ACCT_STS,
                                           T.ACCT_OPDATE,  --  [20250415][姜俐锋][JLBA202502210009][吴大为]:保证金帐号开户日期
                                           ROW_NUMBER() OVER(PARTITION BY T.O_ACCT_NUM ORDER BY T.DEPOSIT_NUM) AS NUM
                                      FROM SMTMODS.L_ACCT_DEPOSIT T
                                     WHERE T.DATA_DATE = I_DATE) T1
                             WHERE T1.NUM = 1) D
                   ON T.HZF_SECURITY_ACCT_NUM = D.O_ACCT_NUM
                 LEFT JOIN VIEW_L_PUBL_ORG_BRA T1 -- 机构表
                   ON T.ORG_NUM = T1.ORG_NUM
                  AND T1.DATA_DATE = I_DATE
                 LEFT JOIN SMTMODS.L_PUBL_RATE T3
                   ON T3.DATA_DATE = I_DATE
                  AND T3.BASIC_CCY = T.HZF_SECURITY_CURR -- 基准币种
                  AND T3.FORWARD_CCY = 'CNY'
                 LEFT JOIN SMTMODS.L_CUST_ALL T2
                   ON T.CUST_ID = T2.CUST_ID
                  AND T2.DATA_DATE = I_DATE
                 LEFT JOIN M_DICT_CODETABLE F
                   ON T2.ID_TYPE2 = F.L_CODE   -- 20250116
                  AND F.L_CODE_TABLE_CODE = 'C0001'
                 LEFT JOIN (SELECT *
                              FROM (SELECT T.ACCT_NUM,
                                           T.DEPARTMENTD,
                                           T.ITEM_CD,
                                           T.ACCT_TYP,
                                           ROW_NUMBER() OVER(PARTITION BY T.ACCT_NUM ORDER BY T.LOAN_NUM) AS NUM
                                      FROM SMTMODS.L_ACCT_LOAN T
                                     WHERE T.DATA_DATE = I_DATE) T1
                             WHERE T1.NUM = 1) T4
                   ON T.CONTRACT_NUM = T4.ACCT_NUM
                 LEFT JOIN (SELECT *
                              FROM (SELECT T.ACCT_NO,
                                           T.DEPARTMENTD,
                                           T.ACCT_TYP,
                                           ROW_NUMBER() OVER(PARTITION BY T.ACCT_NO ORDER BY T.ACCT_NUM) AS NUM
                                      FROM SMTMODS.L_ACCT_OBS_LOAN T
                                     WHERE T.DATA_DATE = I_DATE) T1
                             WHERE T1.NUM = 1) T5
                   ON T.CONTRACT_NUM = T5.ACCT_NO
                WHERE T.DATA_DATE = I_DATE
                  AND T.HZF_SECURITY_ACCT_NUM IS NOT NULL
                  AND ((T.ACCT_STS = '1' AND T.CONTRACT_AMT <> 0)
                        OR T.CONTRACT_ORIG_MATURITY_DT >= SUBSTR(I_DATE,1,4)||'0101' ) -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
                  AND (T.CONTRACT_EFF_DT <= I_DATE  OR T.CONTRACT_EFF_DT IS NULL); -- [2025-05-13][巴启威][JLBA202504060003]: 剔除合同生效日期大于数据日期的贷款合同，报送范围与6.2保持一致
COMMIT ;

 
    #7.RPA数据插入
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = 'RPA数据插入';
	
-- RPA 支小再贷款向央行借款 ，以贷款为抵质押物，公司金融部部分
 INSERT  INTO T_9_3  (
   J030001,  -- 01.押品ID
   J030002,  -- 02.担保协议ID
   J030003,  -- 03.机构ID
   J030005,  -- 05.抵质押物类型
   J030006,  -- 06.抵质押物名称
   J030007,  -- 07.抵质押物状态
   J030008,  -- 08.起始估值
   J030009,  -- 09.币种
   J030010,  -- 10.最新估值
   J030011,  -- 11.首次估值日期
   J030012,  -- 12.最新估值日期
   J030013,  -- 13.估值到期日期
   J030014,  -- 14.对应唯一担保协议标识
   J030015,  -- 15.抵押顺位
   J030016,  -- 16.抵质押物所有权人名称
   J030017,  -- 17.抵质押物所有权人证件类型
   J030018,  -- 18.抵质押物所有权人证件号码
   J030019,  -- 19.已抵押价值
   J030020,  -- 20.审批抵质押率
   J030021,  -- 21.抵质押率
   J030022,  -- 22.登记日期
   J030023,  -- 23.登记机构
   J030024,  -- 24.质押票证类型
   J030025,  -- 25.质押票证号码
   J030026,  -- 26.质押票证签发机构
   J030027,  -- 27.权证种类
   J030028,  -- 28.权证登记号码
   J030029,  -- 29.权证登记面积 
   J030032,  -- 32.触及预警线标识
   J030033,  -- 33.触及平仓线标识
   J030034,  -- 34.交易场所
   J030035,  -- 35.股票股数
   J030036,  -- 36.备注
   J030037,  -- 37.采集日期
   DIS_DATA_DATE, -- 装入数据日期
   DIS_BANK_ID ,  -- 机构号 
   DEPARTMENT_ID ,
   DIS_DEPT ,
   J030039
)
 
 SELECT 
   J030001,  -- 01.押品ID
   J030002,  -- 02.担保协议ID
   J030003,  -- 03.机构ID
   SUBSTR ( J030005,INSTR(J030005,'[',1,1) + 1 , INSTR(J030005, ']',1 ) -INSTR(J030005,'[',1,1) - 1 ) AS J030005,  -- 05.抵质押物类型
   J030006,  -- 06.抵质押物名称
   SUBSTR ( J030007,INSTR(J030007,'[',1,1) + 1 , INSTR(J030007, ']',1 ) -INSTR(J030007,'[',1,1) - 1 ) AS J030007,  -- 07.抵质押物状态
   TO_NUMBER(REPLACE(J030008,',','')) AS J030008,  -- 08.起始估值
   SUBSTR ( J030009,INSTR(J030009,'[',1,1) + 1 , INSTR(J030009, ']',1 ) -INSTR(J030009,'[',1,1) - 1 ) AS J030009,  -- 09.币种
   TO_NUMBER(REPLACE(J030010,',','')) AS J030010,  -- 10.最新估值
   J030011,  -- 11.首次估值日期
   J030012,  -- 12.最新估值日期
   J030013,  -- 13.估值到期日期
   SUBSTR ( J030014,INSTR(J030014,'[',1,1) + 1 , INSTR(J030014, ']',1 ) -INSTR(J030014,'[',1,1) - 1 ) AS J030014,  -- 14.对应唯一担保协议标识
   SUBSTR ( J030015,INSTR(J030015,'[',1,1) + 1 , INSTR(J030015, ']',1 ) -INSTR(J030015,'[',1,1) - 1 ) AS J030015,  -- 15.抵押顺位
   J030016,  -- 16.抵质押物所有权人名称
   SUBSTR ( J030017,INSTR(J030017,'[',1,1) + 1 , INSTR(J030017, ']',1 ) -INSTR(J030017,'[',1,1) - 1 ) AS J030017,  -- 17.抵质押物所有权人证件类型
   J030018,  -- 18.抵质押物所有权人证件号码
   J030019,  -- 19.已抵押价值
   J030020,  -- 20.审批抵质押率
   J030021,  -- 21.抵质押率
   J030022,  -- 22.登记日期
   J030023,  -- 23.登记机构
   SUBSTR ( J030024,INSTR(J030024,'[',1,1) + 1 , INSTR(J030024, ']',1 ) -INSTR(J030024,'[',1,1) - 1 ) AS J030024,  -- 24.质押票证类型
   J030025,  -- 25.质押票证号码
   J030026,  -- 26.质押票证签发机构
   J030027,  -- 27.权证种类
   J030028,  -- 28.权证登记号码
   J030029,  -- 29.权证登记面积 
   J030032,  -- 32.触及预警线标识
   J030033,  -- 33.触及平仓线标识
   J030034,  -- 34.交易场所
   J030035,  -- 35.股票股数
   J030036,  -- 36.备注
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DATA_DATE,   -- 37.采集日期
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE, -- 装入数据日期
   '990000' ,   -- 机构号 
   SUBSTR ( DEPARTMENT_ID,INSTR(DEPARTMENT_ID,'[',1,1) + 1 , INSTR(DEPARTMENT_ID, ']',1 ) -INSTR(DEPARTMENT_ID,'[',1,1) - 1 ) AS DEPARTMENT_ID ,
   '5' as DIS_DEPT,
   J030039
  FROM ybt_datacore.RPAJ_9_3_DZYP A 
 WHERE A.DATA_DATE = I_DATE; 
 COMMIT;
 
 
 
 
 
 -- NGI中增加支小再贷款质押信息录入
 insert into T_9_3(
   J030001,  -- 01.押品ID
   J030002,  -- 02.担保协议ID
   J030003,  -- 03.机构ID
   J030005,  -- 05.抵质押物类型
   J030006,  -- 06.抵质押物名称
   J030007,  -- 07.抵质押物状态
   J030008,  -- 08.起始估值
   J030009,  -- 09.币种
   J030010,  -- 10.最新估值
   J030011,  -- 11.首次估值日期
   J030012,  -- 12.最新估值日期
   J030013,  -- 13.估值到期日期
   J030014,  -- 14.对应唯一担保协议标识
   J030015,  -- 15.抵押顺位
   J030016,  -- 16.抵质押物所有权人名称
   J030017,  -- 17.抵质押物所有权人证件类型
   J030018,  -- 18.抵质押物所有权人证件号码
   J030019,  -- 19.已抵押价值
   J030020,  -- 20.审批抵质押率
   J030021,  -- 21.抵质押率
   J030022,  -- 22.登记日期
   J030023,  -- 23.登记机构
   J030024,  -- 24.质押票证类型
   J030025,  -- 25.质押票证号码
   J030026,  -- 26.质押票证签发机构
   J030027,  -- 27.权证种类
   J030028,  -- 28.权证登记号码
   J030029,  -- 29.权证登记面积
   J030032,  -- 32.触及预警线标识
   J030033,  -- 33.触及平仓线标识
   J030034,  -- 34.交易场所
   J030035,  -- 35.股票股数
   J030036,  -- 36.备注
   J030037,   -- 37.采集日期
   DIS_DATA_DATE, -- 装入数据日期
   DIS_BANK_ID ,   -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID,
   J030038 ,-- 同业业务ID
   J030039  -- 是否保证金担保
 )
 select 
IOU_NUM,-- 押品ID（借据编号）
DYXY_ID, -- 担保协议ID
'B0302H22201009801',-- 押品ID（借据编号）
'19',--  05.抵质押物类型
null,-- 06.抵质押物名称
'01',-- 07.抵质押物状态
null, -- 08.起始估值
'CNY', -- 09.币种
null,-- 10.最新估值
null, -- 11.首次估值日期
null, -- 12.最新估值日期
null, -- 13.估值到期日期
'1',-- 14.对应唯一担保协议标识
'1',-- 15.抵押顺位
'吉林银行股份有限公司', -- 16.抵质押物所有权人名称
'2030',-- 17.抵质押物所有权人证件类型
'70255776-X',-- 18.抵质押物所有权人证件号码
MORTGAGE_VALUE,-- 已抵押价值
APPROVE_MORTGAGE_RATE,-- 审批抵质押率
MORTGAGE_RATE,-- 抵质押率
INPUT_DATE,-- 登记日期
INPUT_ORGN,-- 登记机构
'00', -- 24.质押票证类型
IOU_NUM,-- 质押票证号码
PLEDGE_ORG,-- 质押票证签发机构
case when WARRANT_TYPE='房地产权证'then '0100'
     when WARRANT_TYPE='房屋所有权证'then '0101'
     when WARRANT_TYPE='房屋共有权证'then '0102'
     when WARRANT_TYPE='房屋他项权证'then '0103'
     when WARRANT_TYPE='房地产他项权证'then '0104'
     when WARRANT_TYPE='其他房地产类权证'then '0199'
     when WARRANT_TYPE='不动产权证'then '0200'
     when WARRANT_TYPE='不动产登记证明'then '0201'
     when WARRANT_TYPE='土地使用权权证'then '0300'
     when WARRANT_TYPE='国有土地使用证'then '0301'
     when WARRANT_TYPE='土地他项权证'then '0302'
     when WARRANT_TYPE='林权证'then '0400'
     when WARRANT_TYPE='收费权'then '0500'
     when WARRANT_TYPE='专利权'then '0600'
     when WARRANT_TYPE='商标专用权'then '0700'
     when WARRANT_TYPE='著作权'then '0800'
     when WARRANT_TYPE='采矿权'then '0900'
     when WARRANT_TYPE='其他'then '0000'
     end as WARRANT_TYPE ,-- 权证种类
WARRANT_NUM,-- 权证登记号码
AREA,-- 权证登记面积
case when EARLY_WARNING_LINE ='是' then '1'
 when EARLY_WARNING_LINE ='否' then '0'
 end as EARLY_WARNING_LINE,-- 触及预警线标识
case when CLOSING_LINE ='是' then '1'
 when CLOSING_LINE ='否' then '0'
 end as CLOSING_LINE,-- 触及平仓线标识
case when TRADING_PLACE='场内交易'then '01'
     when TRADING_PLACE='场外交易'then '02'
 end as TRADING_PLACE,-- 交易场所
SHARES_QUANTITY,-- 股票股数
REMARK,-- 备注
TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 28.采集日期
TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
'009801',
6,
'0098JR',
SAME_BUSINESS_ID,-- 同业业务ID
case when IF_DEPOSIT ='是' then '1'
 when IF_DEPOSIT ='否' then '0'
 end as IF_DEPOSIT -- 是否保证金担保
 from T_ZHIXIAO_IOU t where t.data_date=I_DATE;
 COMMIT;
	
	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);

    #7.过程结束执行
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '过程结束执行';
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    SET OI_RETCODE = P_STATUS; 
    SET OI_REMESSAGE = P_DESCB;
    select OI_RETCODE,'|',OI_REMESSAGE;
END $$


