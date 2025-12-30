DROP Procedure IF EXISTS `PROC_BSP_T_8_13_SXQK` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_8_13_SXQK"(
		IN I_DATE VARCHAR(8),
		OUT OI_RETCODE INT,-- 返回code
		OUT OI_REMESSAGE VARCHAR -- 返回message
	)
BEGIN /******
      程序名称  ：授信情况
      程序功能  ：加工授信情况
      目标表：T_8_13
      源表  ：
      创建人  ：WJB
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
  -- JLBA202411070004_关于一表通监管数据报送系统修改逻辑的需求 20241212
  -- JLBA202501240018_关于一表通监管数据报送系统变更的需求_20250311
    /* 需求编号：JLBA202502200003 上线日期：20250415，修改人：姜俐锋，提出人：李逊昂,吴大为 
                     修改原因：  去掉信用卡核销数据*/
    /* 需求编号：JLBA202502210009 上线日期：20250415，修改人：姜俐锋，提出人：吴大为 */
    /* 需求编号：JLBA202504060003 上线日期：20250513，修改人：狄家卉，提出人：吴大为    关于一表通监管数据报送系统、EAST报送系统修改取数逻辑的需求*/ 
     /*需求编号：JLBA202504160004   上线日期：20250627，修改人：姜俐锋，提出人：吴大为 关于吉林银行修改单一客户授信逻辑的需求*/	
	 /*需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
	 /*需求编号：JLBA202509280009 上线日期：2025-10-28，修改人：巴启威，提出人：吴大为 修改原因：关于一表通监管数据报送系统修改逻辑的需求 */
#声明变量
DECLARE P_DATE  DATE;               #数据日期
DECLARE A_DATE  VARCHAR(10);        #数据日期
DECLARE P_PROC_NAME VARCHAR(200);	#存储过程名称
DECLARE P_STATUS INT;				#执行状态
DECLARE P_START_DT DATETIME;		#日志开始日期
DECLARE P_END_TIME DATETIME;		#日志结束日期
DECLARE P_SQLCDE VARCHAR(200);		#日志错误代码
DECLARE P_STATE VARCHAR(200);		#日志状态代码
DECLARE P_SQLMSG VARCHAR(2000);		#日志详细信息
DECLARE P_STEP_NO INT;				#日志执行步骤
DECLARE P_DESCB VARCHAR(200); 		#日志执行步骤描述
DECLARE BEG_MON_DT VARCHAR(8);		#月初
DECLARE BEG_QUAR_DT VARCHAR(8);		#季初
DECLARE BEG_YEAR_DT VARCHAR(8);		#年初
DECLARE LAST_MON_DT VARCHAR(8);		#上月末
DECLARE LAST_QUAR_DT VARCHAR(8);	#上季末
DECLARE LAST_YEAR_DT VARCHAR(8);	#上年末
DECLARE LAST_DT VARCHAR(8);			#上日
DECLARE FINISH_FLG VARCHAR(8);

#完成标志  
#声明异常
DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN GET DIAGNOSTICS CONDITION 1 P_SQLCDE = GBASE_ERRNO,
P_SQLMSG = MESSAGE_TEXT,
P_STATE = RETURNED_SQLSTATE;

SET P_STATUS =- 1;
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
SET A_DATE = SUBSTR(I_DATE,1,4)|| '-' || SUBSTR(I_DATE,5,2)|| '-' || SUBSTR(I_DATE,7,2);
SET BEG_MON_DT = SUBSTR(I_DATE,1,6)|| '01';
SET BEG_QUAR_DT = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY')|| TRIM( TO_CHAR( QUARTER( TO_DATE( I_DATE, 'YYYYMMDD' ))* 3 - 2, '00' ))|| '01';
SET BEG_YEAR_DT = SUBSTR(I_DATE,1,4)|| '0101';
SET LAST_MON_DT = TO_CHAR(TO_DATE(BEG_MON_DT,'YYYYMMDD')- 1,'YYYYMMDD');
SET LAST_QUAR_DT = TO_CHAR(TO_DATE(BEG_QUAR_DT,'YYYYMMDD')- 1,'YYYYMMDD');
SET LAST_YEAR_DT = TO_CHAR(TO_DATE(BEG_YEAR_DT,'YYYYMMDD')- 1,'YYYYMMDD');
SET LAST_DT = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD')- 1,'YYYYMMDD');
SET P_PROC_NAME = 'PROC_BSP_T_8_13_SXQK';
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

DELETE FROM T_8_13 WHERE H130023 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'); 
DELETE FROM TM_L_ACCT_OBS_TEMP;
DELETE FROM TM_L_ACCT_OBS_SXJE;
DELETE FROM L_CREDITLINE_HZ;
 
CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
-- 加工客户保证金、质押存单、国债 临时表用于计算对公客户授信净额
-- 表内授信
    INSERT INTO TM_L_ACCT_OBS_TEMP
      (CUST_ID, SECURITY_AMT, DATA_DATE, FLAG)
      SELECT 
       T1.CUST_ID,
       SUM(NVL(T1.SECURITY_AMT * T3.CCY_RATE, 0) + NVL(TM.DEP_AMT, 0) +
           NVL(TM.COLL_BILL_AMOUNT, 0)) AS SECURITY_AMT,
       I_DATE,
       '1' AS FLAG
        FROM SMTMODS.L_ACCT_LOAN T1
        LEFT JOIN SMTMODS.L_PUBL_RATE T3
          ON T3.DATA_DATE = I_DATE
         AND T3.BASIC_CCY = T1.SECURITY_CURR -- 表内保证金折币
         AND T3.FORWARD_CCY = 'CNY'
        LEFT JOIN (SELECT T2.CONTRACT_NUM,
                          SUM(NVL(T4.DEP_AMT * T6.CCY_RATE, 0)) AS DEP_AMT, -- 本行存单
                          SUM(NVL(T5.COLL_BILL_AMOUNT * T6.CCY_RATE, 0)) AS COLL_BILL_AMOUNT -- 国债
                     FROM SMTMODS.L_AGRE_GUA_RELATION T2
                     LEFT JOIN SMTMODS.L_AGRE_GUARANTEE_RELATION T3
                       ON T2.GUAR_CONTRACT_NUM = T3.GUAR_CONTRACT_NUM
                      AND T3.DATA_DATE = I_DATE
                     LEFT JOIN SMTMODS.L_AGRE_GUARANTY_INFO T4
                       ON T3.GUARANTEE_SERIAL_NUM = T4.GUARANTEE_SERIAL_NUM
                      AND T4.DATA_DATE = I_DATE
                      AND T4.COLL_TYP='A0201' --  是否本行存单(Y是 N否)
                     LEFT JOIN SMTMODS.L_AGRE_GUARANTY_INFO T5
                       ON T3.GUARANTEE_SERIAL_NUM = T5.GUARANTEE_SERIAL_NUM
                      AND T5.DATA_DATE = I_DATE
                      AND T5.COLL_TYP IN ('A0602', 'A0603')
                     LEFT JOIN SMTMODS.L_PUBL_RATE T6
                       ON T6.DATA_DATE = I_DATE
                      AND T6.BASIC_CCY = T3.CURR_CD -- 担保物折币
                      AND T6.FORWARD_CCY = 'CNY'
                    WHERE T2.DATA_DATE = I_DATE
                    GROUP BY T2.CONTRACT_NUM) TM -- 押品类型为 A0602一级国家及地区的国债  A0603二级国家及地区的国债
          ON T1.ACCT_NUM = TM.CONTRACT_NUM
       WHERE T1.DATA_DATE = I_DATE
         AND T1.CANCEL_FLG = 'N'
		 AND T1.LOAN_STOCKEN_DATE IS NULL    -- ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
       GROUP BY T1.CUST_ID;

SET P_START_DT = NOW();
SET P_STEP_NO = P_STEP_NO + 1;
SET P_DESCB = '表外授信';

CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    -- 表外授信
     INSERT INTO TM_L_ACCT_OBS_TEMP
       (CUST_ID, SECURITY_AMT, DATA_DATE,FLAG)
       SELECT  
        T1.CUST_ID,
        SUM(NVL(T1.SECURITY_AMT * T3.CCY_RATE, 0) + NVL(TM.DEP_AMT, 0) +
            NVL(TM.COLL_BILL_AMOUNT, 0))AS SECURITY_AMT,
        I_DATE,
        '2' AS FLAG
         FROM SMTMODS.L_ACCT_OBS_LOAN T1
         LEFT JOIN SMTMODS.L_PUBL_RATE T3
           ON T3.DATA_DATE = I_DATE
          AND T3.BASIC_CCY = T1.SECURITY_CURR -- 表外保证金折币
          AND T3.FORWARD_CCY = 'CNY'
         LEFT JOIN (SELECT T2.CONTRACT_NUM,
                           SUM(NVL(T4.DEP_AMT * T6.CCY_RATE, 0)) AS DEP_AMT, -- 本行存单
                           SUM(NVL(T5.COLL_BILL_AMOUNT * T6.CCY_RATE, 0)) AS COLL_BILL_AMOUNT -- 国债
                      FROM SMTMODS.L_AGRE_GUA_RELATION T2
                      LEFT JOIN SMTMODS.L_AGRE_GUARANTEE_RELATION T3
                        ON T2.GUAR_CONTRACT_NUM = T3.GUAR_CONTRACT_NUM
                       AND T3.DATA_DATE = I_DATE
                      LEFT JOIN SMTMODS.L_AGRE_GUARANTY_INFO T4
                        ON T3.GUARANTEE_SERIAL_NUM = T4.GUARANTEE_SERIAL_NUM
                       AND T4.DATA_DATE = I_DATE
                       AND T4.COLL_TYP='A0201' --  是否本行存单(Y是 N否)
                      LEFT JOIN SMTMODS.L_AGRE_GUARANTY_INFO T5
                        ON T3.GUARANTEE_SERIAL_NUM = T5.GUARANTEE_SERIAL_NUM
                       AND T5.DATA_DATE = I_DATE
                       AND T5.COLL_TYP IN ('A0602', 'A0603')
                      LEFT JOIN SMTMODS.L_PUBL_RATE T6
                        ON T6.DATA_DATE = I_DATE
                       AND T6.BASIC_CCY = T3.CURR_CD -- 担保物折币
                       AND T6.FORWARD_CCY = 'CNY'
                     WHERE T2.DATA_DATE = I_DATE
                     GROUP BY T2.CONTRACT_NUM) TM -- 押品类型为 A0602一级国家及地区的国债 A0603二级国家及地区的国债
           ON T1.ACCT_NUM = TM.CONTRACT_NUM
        WHERE T1.DATA_DATE = I_DATE
          AND T1.ACCT_STS = '1' -- 
        GROUP BY T1.CUST_ID;

INSERT INTO TM_L_ACCT_OBS_SXJE
  (CUST_ID, SECURITY_AMT, DATA_DATE)
  SELECT CUST_ID, SUM(SECURITY_AMT), DATA_DATE
    FROM TM_L_ACCT_OBS_TEMP
   WHERE DATA_DATE = I_DATE
   GROUP BY CUST_ID, DATA_DATE;
 
INSERT INTO L_CREDITLINE_HZ  
(CUST_ID, FACILITY_AMT,FACILITY_AMT_JYX, DATA_DATE)
 SELECT T1.CUST_ID, 
        SUM ( CASE WHEN T1.FACILITY_STS = 'N' THEN  0  -- 修改判断 如果为失效授信 总额不计算
                   ELSE T1.FACILITY_AMT 
                   END ) AS FACILITY_AMT ,
        SUM (CASE WHEN T1.FACILITY_STS = 'N' AND ( T3.CUST_TYP='3'  OR T2.OPERATE_CUST_TYPE IN ('A','B') ) AND  (T1.FACILITY_TYP IN ('1', '2', '4') OR  t1.FACILITY_BUSI_TYP = '10') THEN  0  -- 修改判断 如果为失效授信 总额不计算
                  WHEN ( T3.CUST_TYP='3'  OR T2.OPERATE_CUST_TYPE IN ('A','B') ) AND  (T1.FACILITY_TYP IN ('1', '2', '4') OR  t1.FACILITY_BUSI_TYP = '10') THEN T1.FACILITY_AMT
                  ELSE NULL
                  END) AS FACILITY_AMT_JYX ,
        T1.DATA_DATE
   FROM SMTMODS.L_AGRE_CREDITLINE T1 -- 授信额度表
   LEFT JOIN SMTMODS.L_CUST_P T2 -- 个人客户信息表
     ON T2.CUST_ID = T1.CUST_ID
    AND T2.DATA_DATE = I_DATE
   LEFT JOIN SMTMODS.L_CUST_C T3 -- 对公客户信息表
     ON T1.CUST_ID = T3.CUST_ID
    AND T3.DATA_DATE = I_DATE 
   LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT L -- 贷款合同信息表
     ON T1.FACILITY_NO = L.CONTRACT_NUM
    AND T1.CUST_ID=L.CUST_ID
    AND L.DATA_DATE = I_DATE
    AND NVL(L.PROD_NAME,'##') NOT IN ('个人遗留贷款无本产品','公司遗留贷款无本产品') -- 剔除无本有息历史数据  
  WHERE T1.DATA_DATE = I_DATE
      AND (T1.FACILITY_STS = 'Y' 
      -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
           OR (L.INTERNET_LOAN_TAG = 'Y' AND L.CONTRACT_EXP_DT = TO_CHAR(TO_DATE((substr(I_DATE,1,4)||'0101') ,'YYYYMMDD') - 1,'YYYYMMDD'))
           OR (T1.FACILITY_STS = 'N' AND L.CONTRACT_EXP_DT >= substr(I_DATE,1,4)||'0101' ))  -- 与授信条件一致
    GROUP BY T1.CUST_ID,T1.DATA_DATE;
-- 数据插入
SET P_START_DT = NOW();
SET P_STEP_NO = P_STEP_NO + 1;
SET P_DESCB = '数据插入';
 
            INSERT INTO T_8_13 
                        ( H130001,       -- 授信ID                      
                          H130002,       -- 客户ID                     
                          H130003,       -- 机构ID                     
                          H130028,       -- 占用集团授信ID                  
                          H130005,       -- 客户类别                     
                          H130006,       -- 授信种类                     
                          H130007,       -- 授信币种                     
                          H130008,       -- 授信额度                     
                          H130024,       -- 授信净额                     
                          H130025,       -- 单户授信总额                    
                          H130029,       -- 个人客户经营性贷款授信总额      
                          H130009,       -- 非保本理财产品授信额度          
                          H130010,       -- 额度申请日期                    
                          H130011,       -- 授信起始日期                    
                          H130012,       -- 授信到期日期                    
                          H130013,       -- 持有债券余额                    
                          H130014,       -- 持有股权余额                    
                          H130015,       -- 表内用信余额                    
                          H130016,       -- 表外用信余额                    
                          H130017,       -- 不考虑风险缓释季末风险暴露金额  
                          H130018,       -- 考虑风险缓释季末风险暴露金额    
                          H130019,       -- 授信审批意见                    
                          H130020,       -- 经办员工ID                     
                          H130021,       -- 审批员工ID                     
                          H130022,       -- 授信状态                     
                          H130026,       -- 授信协议名称                    
                          H130023,       -- 采集日期                     
                          DIS_DATA_DATE, -- 装入数据日期
                          DIS_BANK_ID,   -- 机构号
                          DEPARTMENT_ID,  -- 业务条线
                          DIS_DEPT						  
                          )
                    SELECT 
                          T1.FACILITY_NO        AS  H130001,     --  '授信ID',
                          T1.CUST_ID            AS  H130002,     --  '客户ID',
                          ORG.ORG_ID            AS  H130003,     --  '机构ID',
                          CASE WHEN FACILITY_TYP = '4' THEN T1.FACILITY_NO ELSE NULL END AS H130028,     --  '占用集团授信ID',
                          CASE WHEN T1.FACILITY_BUSI_TYP = '12' THEN '06' -- 信用卡账户默认成 06 其他个人客户
                               WHEN T3.CUST_TYP = '3' THEN '05' -- 个体工商户及小微企业主
                               WHEN T2.OPERATE_CUST_TYPE IN ('A','B') THEN '05' -- 个体工商户及小微企业主
                               WHEN T1.FACILITY_TYP = '0' THEN '02' -- 集团客户
                               WHEN T1.FACILITY_TYP = '1' THEN '04' -- 供应链融资
                               WHEN T1.FACILITY_TYP IN ('2','6') THEN '01' -- 单一法人  2 单一法人授信 7 白名单授信 6 供应链融资成员授信
                               WHEN T1.FACILITY_TYP IN ('3','7') THEN '03' -- 同业客户
                               WHEN T1.FACILITY_TYP = '4' THEN '02' -- 集团客户
                               WHEN T1.FACILITY_TYP = '5' THEN '06' -- 其他个人客户
                               ELSE '07' -- 其他
                               END              AS  H130005,     --  '客户类别',
                          CASE WHEN T1.FACILITY_BUSI_TYP = '1' THEN '01' -- 综合额度授信
                               WHEN T1.FACILITY_BUSI_TYP = '12' THEN '03' -- 信用卡额度授信
                               WHEN T1.FACILITY_BUSI_TYP IN ('11','10') THEN '05' -- 专项额度授信
                               WHEN T1.LOW_CREDIT_RISK_FLG = 'Y' THEN '02' -- 低风险额度授信
                               WHEN T1.TEMP_LIMIT = 'Y' THEN '04' -- 临时额度授信
                               WHEN T1.SPECIAL_CREDIT_FLG = 'Y' THEN '05' -- 专项额度授信
                               WHEN T1.FACILITY_BUSI_TYP = '9' THEN '06'  -- 其他   上述授信类型以外的其他授信类型
                               END              AS H130006,     --  '授信种类',
                          T1.CURR_CD            AS H130007,     --  '授信币种',
                          T1.FACILITY_AMT       AS H130008,     --  '授信额度',
                          CASE WHEN NVL(T1.FACILITY_AMT-TEMP1.SECURITY_AMT,'0') < 0 THEN 0
                               ELSE T1.FACILITY_AMT-NVL(TEMP1.SECURITY_AMT,'0')
                               END              AS H130024,     --  '授信净额',
                          NVL(T5.FACILITY_AMT,0)       AS H130025,     --  '单户授信总额', -- [20250912][姜俐锋]: 补充报送范围，当年报送的业务对应授信信息，当年也应持续报送 但是授信失效应为0
                          NVL(T5.FACILITY_AMT_JYX,0)   AS H130029,     --  '个人客户经营性贷款授信总额', --20250715 修改为null用0
                          NVL(T1.FBBLCSXED,0)   AS H130009,     --  '非保本理财产品授信额度',
                          CASE WHEN T1.FACILITY_TYP IN ('3','7') THEN TO_CHAR(TO_DATE(T1.FACILITY_EFF_DT,'YYYYMMDD')- 30,'YYYY-MM-DD') 
                               ELSE TO_CHAR(TO_DATE(COALESCE(T1.APPLY_DT,T1.FACILITY_EFF_DT,T1.FIRST_CREDIT_DATA),'YYYYMMDD'),'YYYY-MM-DD')
                               END              AS H130010,     -- 10 '额度申请日期' 同业部门要求取 额度申请日期早于 授信起始日期1个月H130010,     --  '额度申请日期'
                          TO_CHAR(TO_DATE(COALESCE(T1.APPLY_DT,T1.FACILITY_EFF_DT,T1.FIRST_CREDIT_DATA),'YYYYMMDD'),'YYYY-MM-DD') AS H130011,           -- 11 '授信起始日期'
                          TO_CHAR(TO_DATE(NVL(T1.FACILITY_END_DT, '99991231'),'YYYYMMDD'),'YYYY-MM-DD') AS H130012,           -- 12 '授信到期日期'
                          NVL(T1.CYZQYE,'0')    AS H130013,     --  '持有债券余额',
                          '0'                   AS H130014,     --  '持有股权余额',
                          NVL(T1.INNER_FACILITY_AMT,0) AS H130015,     --  '表内用信余额'
                          NVL(T1.OUTER_FACILITY_AMT,0) AS H130016,     --  '表外用信余额' 
                          NULL                  AS H130017,     --  '不考虑风险缓释季末风险暴露金额',
                          NULL                  AS H130018,     --  '考虑风险缓释季末风险暴露金额',
                          CASE WHEN T1.FACILITY_TYP IN ('3','7') THEN '同意'
                               ELSE nvl(T1.SXSPYJ,'综合评估通过')
                               END              AS H130019,     --  '授信审批意见'
                          CASE WHEN T1.FACILITY_TYP = '7' THEN '014276'
                               WHEN T1.FACILITY_BUSI_TYP = '12' THEN NVL(D.EMP_ID,'自动')
                               WHEN T1.FACILITY_EMP_ID='wd012601' THEN '自动'
                               ELSE ( CASE WHEN length(T1.FACILITY_EMP_ID)>6 THEN substr('0'||T1.FACILITY_EMP_ID,1,6) 
                                           WHEN length(T1.FACILITY_EMP_ID)<6 THEN LPAD(T1.FACILITY_EMP_ID, 6, '0')
                                           ELSE T1.FACILITY_EMP_ID END )
                               END              AS H130020,                            -- 20 '经办员工ID'
                          CASE WHEN T1.FACILITY_TYP IN ('3','7') THEN '016330'
                               WHEN T1.FACILITY_BUSI_TYP = '12' THEN NVL(D1.EMP_ID,'自动')
                               ELSE T1.AUTHO_NAME
                               END              AS H130021, 	          		  	  	 -- 21 '审批员工ID' 
                          CASE WHEN T1.FACILITY_STS = 'Y' THEN '1' -- 标识此笔授信是否有效。字典如下：0.否，1.是
                               WHEN T1.FACILITY_STS = 'N' THEN '0' -- 标识此笔授信是否有效。字典如下：0.否，1.是
                               END              AS H130022,     --  '授信状态',
                          SUBSTR(CASE WHEN T1.FACILITY_TYP IN ('3','7') THEN  T1.FACILITY_NO || T1.CUST_NAME 
                               ELSE T1.FACILITY_NO || COALESCE(T3.CUST_NAM,T2.CUST_ID,T4.CUST_GROUP_NO ,'' )
                               END,0,64) || '授信'     AS H130026,   --  '授信协议名称',
                          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS H130023 ,     --  '采集日期',
						  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),    --    '装入数据日期'
		                  T1.ORG_NUM,                                          --    '机构号'
						  CASE WHEN T1.FACILITY_BUSI_TYP = '12' THEN '009803'
							   WHEN T1.FACILITY_TYP IN ('3','7') THEN '009820'
							   WHEN T1.FACILITY_TYP IN ('0','1','2','6','4') THEN '0098JR'
							   WHEN T1.FACILITY_TYP IN ( '5' ) THEN '0098LDB'
							   END             AS YWTX ,
						  '1'
                     FROM SMTMODS.L_AGRE_CREDITLINE T1 -- 授信额度表
                     LEFT JOIN SMTMODS.L_CUST_P T2 -- 个人客户信息表
                       ON T2.CUST_ID = T1.CUST_ID
                      AND T2.DATA_DATE = I_DATE
                     LEFT JOIN SMTMODS.L_CUST_C T3 -- 对公客户信息表
                       ON T1.CUST_ID = T3.CUST_ID
                      AND T3.DATA_DATE = I_DATE 
                     LEFT JOIN SMTMODS.L_CUST_C_GROUP_INFO T4 -- 集团客户信息表
                       ON T1.CUST_ID = T4.CUST_GROUP_NO
                      AND T4.DATA_DATE = I_DATE    
                     LEFT JOIN L_CREDITLINE_HZ T5
                       ON T1.CUST_ID = T5.CUST_ID
                     LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表
                       ON T1.ORG_NUM = ORG.ORG_NUM
                      AND ORG.DATA_DATE = I_DATE 
                     LEFT JOIN TM_L_ACCT_OBS_SXJE TEMP1 -- 临时表1 用于计算保证金、质押存单、国债金额
                       ON T1.CUST_ID = TEMP1.CUST_ID 
                     LEFT JOIN SMTMODS.L_PUBL_EMP D -- 员工表  
                       ON T1.FACILITY_EMP_ID = D.EMP_ID
                      AND D.DATA_DATE = I_DATE
                     LEFT JOIN SMTMODS.L_PUBL_EMP D1 -- 员工表
                       ON T1.AUTHO_NAME = D1.EMP_ID
                      AND D1.DATA_DATE = I_DATE 
                     LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT L -- 贷款合同信息表
                       ON T1.FACILITY_NO = L.CONTRACT_NUM
                      AND L.DATA_DATE = I_DATE
                      AND NVL(L.PROD_NAME,'##') NOT IN ('个人遗留贷款无本产品','公司遗留贷款无本产品') -- 剔除无本有息历史数据   
                    WHERE T1.DATA_DATE = I_DATE 
                       AND (T1.FACILITY_EFF_DT <= I_DATE OR T1.FACILITY_EFF_DT IS NULL ) -- [20251028][巴启威][JLBA202509280009][吴大为]:剔除授信起始日期大于数据日期的授信，与6.2贷款合同范围保持一致
                       AND (T1.FACILITY_STS = 'Y' 
                      -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
                       OR (L.INTERNET_LOAN_TAG = 'Y' AND L.CONTRACT_EXP_DT >= TO_CHAR(TO_DATE((substr(I_DATE,1,4)||'0101') ,'YYYYMMDD') - 1,'YYYYMMDD'))
                       OR (T1.FACILITY_STS = 'N' AND L.CONTRACT_EXP_DT >= substr(I_DATE,1,4)||'0101' )
                       -- [20250807][巴启威][JLBA202507090010][吴大为]: 补充报送范围，当年报送的业务对应授信信息，当年也应持续报送
                       OR EXISTS (SELECT 1 FROM YBT_DATACORE.T_6_13 A WHERE A.F130049 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AND A.F130051 = T1.FACILITY_NO)
                       OR EXISTS (SELECT 1 FROM YBT_DATACORE.T_6_14 B WHERE B.F140035 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AND B.F140036 = T1.FACILITY_NO)
                       OR EXISTS (SELECT 1 FROM YBT_DATACORE.T_6_2  C WHERE C.F020063 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AND C.F020064 = T1.FACILITY_NO)                       
                       );
                       COMMIT;
                    
    CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
SET P_START_DT = NOW();
SET P_STEP_NO = P_STEP_NO + 1;
SET P_DESCB = 'RPA数据插入';
 
 
-- RPA 债转股 + 非标
 INSERT INTO T_8_13
  (
   H130001, -- 01 '授信ID'
   H130002, -- 02 '客户ID'
   H130003, -- 03 '机构ID' 
   H130005, -- 05 '客户类别'
   H130006, -- 06 '授信种类'
   H130007, -- 07 '授信币种'
   H130008, -- 08 '授信额度'
   H130024, -- 24 '授信净额'
   H130025, -- 25 '单户授信总额'
   H130009, -- 09 '非保本理财产品授信额度'
   H130010, -- 10 '额度申请日期'
   H130011, -- 11 '授信起始日期'
   H130012, -- 12 '授信到期日期'
   H130013, -- 13 '持有债券余额'
   H130014, -- 14 '持有股权余额'
   H130015, -- 15 '表内用信余额'
   H130016, -- 16 '表外用信余额'
   H130017, -- 17 '不考虑风险缓释季末风险暴露金额'
   H130018, -- 18 '考虑风险缓释季末风险暴露金额'
   H130019, -- 19 '授信审批意见'
   H130020, -- 20 '经办员工ID'
   H130021, -- 21 '审批员工ID' 
   H130022, -- 22 '授信状态'
   H130026, -- 26 '授信协议名称'
   H130023, -- 23 '采集日期'
   DIS_DATA_DATE, -- 装入数据日期
   DIS_BANK_ID,   -- 机构号
   DEPARTMENT_ID, -- 业务条线
   H130028  ,      -- 占用集团授信ID
   DIS_DEPT
   )
 SELECT 
   H130001, -- 01 '授信ID'
   H130002, -- 02 '客户ID'
   H130003, -- 03 '机构ID' 
   SUBSTR (H130005,INSTR(H130005,'[',1,1) + 1 , INSTR(H130005, ']',1 ) -INSTR(H130005,'[',1,1) - 1 ) AS H130005, -- 05 '客户类别'
   SUBSTR (H130006,INSTR(H130006,'[',1,1) + 1 , INSTR(H130006, ']',1 ) -INSTR(H130006,'[',1,1) - 1 ) AS H130006, -- 06 '授信种类'
   SUBSTR (H130007,INSTR(H130007,'[',1,1) + 1 , INSTR(H130007, ']',1 ) -INSTR(H130007,'[',1,1) - 1 ) AS H130007, -- 07 '授信币种'
   TO_NUMBER(REPLACE(H130008,',','')) AS H130008, -- 08 '授信额度'
   TO_NUMBER(REPLACE(H130024,',','')) AS H130024, -- 24 '授信净额'
   TO_NUMBER(REPLACE(H130025,',','')) AS H130025, -- 25 '单户授信总额'
   TO_NUMBER(REPLACE(H130009,',','')) AS H130009, -- 09 '非保本理财产品授信额度'
   H130010, -- 10 '额度申请日期'
   H130011, -- 11 '授信起始日期'
   H130012, -- 12 '授信到期日期'
   TO_NUMBER(REPLACE(H130013,',','')) AS H130013, -- 13 '持有债券余额'
   TO_NUMBER(REPLACE(H130014,',','')) AS H130014, -- 14 '持有股权余额'
   TO_NUMBER(REPLACE(H130015,',','')) AS H130015, -- 15 '表内用信余额'
   TO_NUMBER(REPLACE(H130016,',','')) AS H130016, -- 16 '表外用信余额'
   TO_NUMBER(REPLACE(H130017,',','')) AS H130017, -- 17 '不考虑风险缓释季末风险暴露金额'
   TO_NUMBER(REPLACE(H130018,',','')) AS H130018, -- 18 '考虑风险缓释季末风险暴露金额'
   H130019, -- 19 '授信审批意见'
   H130020, -- 20 '经办员工ID'
   H130021, -- 21 '审批员工ID' 
   SUBSTR (H130022,INSTR(H130022,'[',1,1) + 1 , INSTR(H130022, ']',1 ) -INSTR(H130022,'[',1,1) - 1 ) AS H130022, -- 22 '授信状态'
   H130026, -- 26 '授信协议名称'
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS H130023, -- 23 '采集日期'
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE, -- 装入数据日期
   '990000',   -- 机构号
   '0098JR', -- 业务条线
   H130028 ,      -- 占用集团授信ID
   'RPA'
   FROM ybt_datacore.RPAJ_8_13_SXQK A
 WHERE A.DATA_DATE =I_DATE; 
 COMMIT ;


   CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
   

   INSERT INTO T_8_13
 ( H130001, -- 01 '授信ID'
   H130002, -- 02 '客户ID'
   H130003, -- 03 '机构ID' 
   H130005, -- 05 '客户类别'
   H130006, -- 06 '授信种类'
   H130007, -- 07 '授信币种'
   H130008, -- 08 '授信额度'
   H130024, -- 24 '授信净额'
   H130025, -- 25 '单户授信总额'
   H130009, -- 09 '非保本理财产品授信额度'
   H130010, -- 10 '额度申请日期'
   H130011, -- 11 '授信起始日期'
   H130012, -- 12 '授信到期日期'
   H130013, -- 13 '持有债券余额'
   H130014, -- 14 '持有股权余额'
   H130015, -- 15 '表内用信余额'
   H130016, -- 16 '表外用信余额'
   H130017, -- 17 '不考虑风险缓释季末风险暴露金额'
   H130018, -- 18 '考虑风险缓释季末风险暴露金额'
   H130019, -- 19 '授信审批意见'
   H130020, -- 20 '经办员工ID'
   H130021, -- 21 '审批员工ID' 
   H130022, -- 22 '授信状态'
   H130026, -- 26 '授信协议名称'
   H130023, -- 23 '采集日期'
   DIS_DATA_DATE, -- 装入数据日期
   DIS_BANK_ID,   -- 机构号
   DEPARTMENT_ID, -- 业务条线
   H130028 ,       -- 占用集团授信ID
   DIS_DEPT )
   
 SELECT 
   H130001, -- 01 '授信ID'
   H130002, -- 02 '客户ID'
   H130003, -- 03 '机构ID' 
   SUBSTR (H130005,INSTR(H130005,'[',1,1) + 1 , INSTR(H130005, ']',1 ) -INSTR(H130005,'[',1,1) - 1 ) AS H130005, -- 05 '客户类别'
   SUBSTR (H130006,INSTR(H130006,'[',1,1) + 1 , INSTR(H130006, ']',1 ) -INSTR(H130006,'[',1,1) - 1 ) AS H130006, -- 06 '授信种类'
   SUBSTR (H130007,INSTR(H130007,'[',1,1) + 1 , INSTR(H130007, ']',1 ) -INSTR(H130007,'[',1,1) - 1 ) AS H130007, -- 07 '授信币种'
   TO_NUMBER(REPLACE(H130008,',','')) AS H130008, -- 08 '授信额度'
   TO_NUMBER(REPLACE(H130024,',','')) AS H130024, -- 24 '授信净额'
   TO_NUMBER(REPLACE(H130025,',','')) AS H130025, -- 25 '单户授信总额'
   TO_NUMBER(REPLACE(H130009,',','')) AS H130009, -- 09 '非保本理财产品授信额度'
   H130010, -- 10 '额度申请日期'
   H130011, -- 11 '授信起始日期'
   H130012, -- 12 '授信到期日期'
   TO_NUMBER(REPLACE(H130013,',','')) AS H130013, -- 13 '持有债券余额'
   TO_NUMBER(REPLACE(H130014,',','')) AS H130014, -- 14 '持有股权余额'
   TO_NUMBER(REPLACE(H130015,',','')) AS H130015, -- 15 '表内用信余额'
   TO_NUMBER(REPLACE(H130016,',','')) AS H130016, -- 16 '表外用信余额'
   TO_NUMBER(REPLACE(H130017,',','')) AS H130017, -- 17 '不考虑风险缓释季末风险暴露金额'
   TO_NUMBER(REPLACE(H130018,',','')) AS H130018, -- 18 '考虑风险缓释季末风险暴露金额'
   H130019, -- 19 '授信审批意见'
   H130020, -- 20 '经办员工ID'
   H130021, -- 21 '审批员工ID' 
   SUBSTR (H130022,INSTR(H130022,'[',1,1) + 1 , INSTR(H130022, ']',1 ) -INSTR(H130022,'[',1,1) - 1 ) AS H130022, -- 22 '授信状态'
   H130026, -- 26 '授信协议名称'
   TO_CHAR(TO_DATE( I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS H130023, -- 23 '采集日期'
   TO_CHAR(TO_DATE( I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE, -- 装入数据日期
   '009806',   -- 机构号
   '009806', -- 业务条线
   H130028 ,       -- 占用集团授信ID
   'INTM'
  FROM  ybt_datacore.INTM_SXQK T
  WHERE T.DATA_DATE= I_DATE;
  COMMIT;
  
  CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
  
   
#6.过程结束执行

SET P_START_DT = NOW();
SET P_STEP_NO = P_STEP_NO + 1;
SET P_DESCB = '过程结束执行';

CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);

SET OI_RETCODE = P_STATUS;
SET OI_REMESSAGE = P_DESCB;

SELECT OI_RETCODE,'|',OI_REMESSAGE;
END $$

