DROP Procedure IF EXISTS `PROC_BSP_T_6_1_CKXY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_1_CKXY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回CODE
                                         OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
                                         )
BEGIN

  /******
      程序名称  ：存款协议
      程序功能  ：加工存款协议
      目标表：T_6_1
      源表  ：
      创建人  ：87V
      创建日期  ：20240110
      版本号：V0.0.1 
  ******/
	-- JLBA202409120001_关于一表通监管数据报送系统修改逻辑的需求_二期 20241128
	-- JLBA202411070004_关于一表通监管数据报送系统修改逻辑的需求 20241212
    -- JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求   上线日期：20250513  修改人：周敬坤   提出人：吴大为 新增2005、2006、2007、2008、2009、2010科目：其中2005对应以前的201105科目、2006、2007对应以前的201104、201106，此三个科目为财政性存款；新增科目2008、2009，财政性存款；2010对应201107，国库定期存款 
    -- JLBA202502170010_关于EAST及一表通监管报表更改部分报表逻辑的需求 上线日期： 20250527 修改人：王超，提出人：冯启航 --修改内容：由于村镇回行村镇的存折号及活期存款账号与母行存在相同情况，EAST存折信息表存折号字段需要将村镇回行数据增加前缀进行拼接区 分。一表通相关报表同步进行修改。	
    -- JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求 
	-- 需求编号：JLBA202507250003 上线日期：2025-09-09，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统修改取数逻辑的需求  
    -- 需求编号：JLBA202509280009 上线日期：2025-10-28，修改人：巴启威，提出人：吴大为 修改原因：关于一表通监管数据报送系统修改逻辑的需求
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
	SET P_PROC_NAME = 'PROC_BSP_T_6_1_CKXY';
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
	
	DELETE FROM YBT_DATACORE.T_6_1 WHERE F010035 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
    DELETE FROM  T_DEPOSIT_YWGX;
	COMMIT;
   		
 -- JLBA202409120001 20241128 新增逻辑
   /*有无业务关系划分：
    1，机构类客户
    2，保证金
    3，有贷款的客户
    4、对公代发工资户
    5、存单质押
    6、基本户
    为有业务关系的客户，其它的为无业务关系*/
	
   MERGE INTO EBDT_BATCHTRANSDTL_ACCT  A
   USING (SELECT DISTINCT O_ACCT_NUM AS ACCNO, DATA_DATE
             FROM SMTMODS.L_ACCT_DEPOSIT  B
            WHERE STABLE_DEP_TYPE = 'A01'  -- 上游判定逻辑已经是一年内，因此直接更新掉全量数据就可以
              AND DATA_DATE = I_DATE)  B
      ON A.ACCNO = B.ACCNO 
    WHEN MATCHED THEN
         UPDATE SET A.WORKDATE = I_DATE
    WHEN NOT MATCHED THEN
  INSERT (A.ACCNO, A.WORKDATE) VALUES (B.ACCNO, I_DATE);

      
INSERT INTO T_DEPOSIT_YWGX 
-- 保证金
SELECT T.ACCT_NUM,'1' AS YWYWGX
  FROM SMTMODS.L_ACCT_DEPOSIT T
 WHERE T.DATA_DATE = I_DATE
   AND T.GL_ITEM_CODE IN ('20110114', '20110115', '20110209', '20110210')
   AND T.ACCT_BALANCE <> 0
 UNION ALL
-- 存单质押
SELECT T.ACCT_NUM,'1'
  FROM SMTMODS.L_ACCT_DEPOSIT T
 INNER JOIN (SELECT COLL_BILL_ACCT, DEP_MATURITY
               FROM (SELECT /*+PARALLEL(8)*/
                      COLL_BILL_ACCT,
                      DEP_MATURITY,
                      ROW_NUMBER() OVER(PARTITION BY COLL_BILL_ACCT ORDER BY DEP_MATURITY DESC) AS RN
                       FROM SMTMODS.L_AGRE_GUARANTY_INFO
                      WHERE DATA_DATE = I_DATE
                        AND COLL_TYP = 'A0201'
                        AND COLL_STATUS = 'Y' --   押品状态有效
                     ) T
              WHERE RN = 1) T1 --   本行存单
    ON T.O_ACCT_NUM = T1.COLL_BILL_ACCT --   外部账号关联
 WHERE T.DATA_DATE = I_DATE
 UNION ALL
--   代发工资 
SELECT T.ACCT_NUM,'1'
  FROM SMTMODS.L_ACCT_DEPOSIT T
 INNER JOIN (SELECT DISTINCT ACCNO
               FROM EBDT_BATCHTRANSDTL_ACCT
              WHERE WORKDATE BETWEEN (SUBSTR(I_DATE, 1, 4) - 1) ||
                    SUBSTR(I_DATE, 5, 4) AND I_DATE) T1
    ON T.O_ACCT_NUM = T1.ACCNO
 WHERE T.DATA_DATE = I_DATE
   AND T.GL_ITEM_CODE LIKE '20110101%'
 UNION ALL
-- 机构类客户用是否业务关系判断
SELECT T.ACCT_NUM,'1'
  FROM SMTMODS.L_ACCT_DEPOSIT T
 WHERE T.DATA_DATE = I_DATE
   AND BUS_REL = 'Y'
 UNION ALL
-- 有贷款的客户
SELECT T.ACCT_NUM,'1'
  FROM SMTMODS.L_ACCT_DEPOSIT T
 INNER JOIN (SELECT CUST_ID, COUNT(*)
               FROM SMTMODS.L_ACCT_LOAN T
              WHERE T.DATA_DATE = I_DATE
                AND T.LOAN_ACCT_BAL <> 0
              GROUP BY CUST_ID) T1
    ON T.CUST_ID = T1.CUST_ID
 WHERE T.DATA_DATE = I_DATE
 UNION ALL
--  6、基本户
SELECT T.ACCT_NUM,'1'
  FROM SMTMODS.L_ACCT_DEPOSIT T
 INNER JOIN (SELECT /*+PARALLEL(4)*/
             DISTINCT T.ACCT_NUM
               FROM SMTMODS.L_ACCT_DEPOSIT T
              WHERE T.DATA_DATE = I_DATE
                AND T.PBOC_ACCT_NATURE_CD = '0011'
                AND T.ACCT_BALANCE <> 0) T1 -- 基本户
    ON T.ACCT_NUM = T1.ACCT_NUM
 WHERE T.DATA_DATE = I_DATE;  -- 20241128

													
    
    #3插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
   INSERT  INTO YBT_DATACORE.T_6_1  (
       F010001 , -- 01 协议ID
       F010002 , -- 02 机构ID
       F010003 , -- 03 客户ID
       F010004 , -- 04 客户类型
       F010005 , -- 05 科目ID
       F010006 , -- 06 产品ID
       F010007 , -- 07 分户账号
       F010008 , -- 08 存款账户类型
       F010009 , -- 09 提前支取标识
       F010010 , -- 10 提前支取罚息
       F010011 , -- 11 业务关系标识
       F010012 , -- 12 行为性期权标识
       F010013 , -- 13 交易介质
       F010015 , -- 14 交易介质ID
       F010016 , -- 15 保证金账户标识
       F010017 , -- 16 利率
       F010018 , -- 17 利率定价基础
       F010019 , -- 18 开户日期
       F010020 , -- 19 开户金额
       F010021 , -- 20 到期日期
       F010022 , -- 21 协议币种
       F010023 , -- 22 钞汇类别
       F010024 , -- 23 销户日期
       F010026 , -- 24 账户资金控制情况
       F010027 , -- 25 协议状态
       F010028 , -- 26 经办员工ID
       F010029 , -- 27 审查员工ID
       F010030 , -- 28 审批员工ID
       F010031 , -- 29 管户员工ID
       F010036 , -- 30 借记卡卡号
       F010037 , -- 31 借记卡开卡日期
       F010038 , -- 32 借记卡状态
       F010039 , -- 33 借记卡启用柜员ID
       F010040 , -- 34 存折号
       F010041 , -- 35 存折启用日期
       F010042 , -- 36 存折状态
       F010043 , -- 37 存折启用柜员ID
       F010044 , -- 38 其他介质号
       F010045 , -- 39 其他介质启用日期
       F010046 , -- 40 其他介质状态
       F010047 , -- 41 其他介质启用柜员ID
       F010048 , -- 42 存款产品类别
       F010049 , -- 43 社会保障基金存款标识
       F010032 , -- 44 备注
       F010035 ,  -- 45 采集日期
       DIS_DATA_DATE,
       DIS_BANK_ID,    -- 机构号
       DEPARTMENT_ID ,  -- 业务条线
       F010050          -- 特定养老储蓄存款标识
       )
    SELECT 
       A.F010001 , -- 01 协议ID
       A.F010002 , -- 02 机构ID
       A.F010003 , -- 03 客户ID
       A.F010004 , -- 04 客户类型
       A.F010005 , -- 05 科目ID
       A.F010006 , -- 06 产品ID
       A.F010007 , -- 07 分户账号
       A.F010008 , -- 08 存款账户类型
       A.F010009 , -- 09 提前支取标识
       A.F010010 , -- 10 提前支取罚息
       A.F010011 , -- 11 业务关系标识
       A.F010012 , -- 12 行为性期权标识
       A.F010013 , -- 13 交易介质
       A.F010015 , -- 14 交易介质ID
       A.F010016 , -- 15 保证金账户标识
       A.F010017 , -- 16 利率
       A.F010018 , -- 17 利率定价基础
       A.F010019 , -- 18 开户日期
       A.F010020 , -- 19 开户金额
       A.F010021 , -- 20 到期日期
       A.F010022 , -- 21 协议币种
       A.F010023 , -- 22 钞汇类别
       A.F010024 , -- 23 销户日期
       A.F010026 , -- 24 账户资金控制情况
       A.F010027 , -- 25 协议状态
       A.F010028 , -- 26 经办员工ID
       A.F010029 , -- 27 审查员工ID
       A.F010030 , -- 28 审批员工ID
       A.F010031 , -- 29 管户员工ID
       A.F010036 , -- 30 借记卡卡号
       A.F010037 , -- 31 借记卡开卡日期
       A.F010038 , -- 32 借记卡状态
       A.F010039 , -- 33 借记卡启用柜员ID
       A.F010040 , -- 34 存折号
       A.F010041 , -- 35 存折启用日期
       A.F010042 , -- 36 存折状态
       A.F010043 , -- 37 存折启用柜员ID
       A.F010044 , -- 38 其他介质号
       A.F010045 , -- 39 其他介质启用日期
       A.F010046 , -- 40 其他介质状态
       A.F010047 , -- 41 其他介质启用柜员ID
       A.F010048 , -- 42 存款产品类别
       A.F010049 , -- 43 社会保障基金存款标识
       A.F010032 , -- 44 备注
       A.F010035 , -- 45 采集日期
       A.DIS_DATA_DATE,
       A.DIS_BANK_ID ,   -- 机构号
       A.DEPARTMENT_ID ,  -- 业务条线
       '0'              -- 特定养老储蓄存款标识  20241227 YBT_JYF01-137
FROM    
       
   (SELECT X.*
    FROM 
(    SELECT 
       T1.ACCT_NUM   AS F010001              , -- 01 协议ID
       CASE WHEN T1.GL_ITEM_CODE='20110111' THEN 'B0302H22201009803'
            ELSE ORG.ORG_ID
             END  AS F010002                , -- 02  机构ID
	   T1.CUST_ID  AS  F010003               , -- 03 客户ID
	   CASE -- WHEN T5.CUST_TYP <> '3' AND T7.CUST_ID IS NULL THEN '01' -- 单一法人客户（非金融机构）
       WHEN (T5.IS_NGI_CUST='0' and T5.DEPOSIT_CUSTTYPE NOT IN ('13','14') )
       AND (T5.IS_NGI_CUST='1' and NVL(T5.CUST_TYP,0) NOT IN ('3'))  -- [20250521][巴启威][JLBA202504060003][吴大为]: 新增IS_NGI_CUST是否NGI客户标识,与2.1判断方式保持一致
       AND T7.CUST_ID IS NULL THEN '01'   -- 20240731 UPDATE ZJK 吴大为要求存款客户类型使用柜面存款人类型判断
           WHEN T5.CUST_GROUP_NO IS NOT NULL THEN '02' -- 集团客户
        WHEN SUBSTR(T7.FINA_CODE_NEW,1,1) IN ('C','D') THEN '03' -- 银行业金融机构
        WHEN SUBSTR(T7.FINA_CODE_NEW,1,1) NOT IN ('C','D') THEN '04' -- 其他金融机构
         --  WHEN T6.CUST_ID IS NOT NULL OR T5.CUST_TYP = '3' THEN '05' -- 个人客户
       WHEN (T6.CUST_ID IS NOT NULL OR (T5.IS_NGI_CUST='0' and T5.DEPOSIT_CUSTTYPE IN ('13','14')) OR (T5.IS_NGI_CUST='1' and NVL(T5.CUST_TYP,0) IN ('3'))) -- [20250521][巴启威][JLBA202504060003][吴大为]: 新增IS_NGI_CUST是否NGI客户标识,与2.1判断方式保持一致
        THEN '05' -- 个人客户 JLBA202411070004 20241212 YBT_JYF01-76
        -- WHEN THEN '06' -- 非法人类合格机构投资者
        ELSE '00' -- 其他  
	   END   AS F010004                      , -- 04 客户类型 
	   T1.GL_ITEM_CODE  AS F010005           , -- 05 科目ID
	   T1.POC_INDEX_CODE AS F010006          , -- 06 产品ID
	   TRIM(T1.ACCT_NUM)    AS F010007          , -- 07 分户账号     逻辑修改_LHY
	   CASE WHEN T1.GL_ITEM_CODE = '20110111' THEN '01' -- 信用卡溢缴款科目对应账户计入个人I类账户
	        WHEN T1.GL_ITEM_CODE LIKE '2012%'  THEN '08'	-- 同业存款账户
            WHEN T1.DEMAND_DEPOSIT_TYPE = 'A' THEN '01' -- 个人I类账户
	        WHEN T1.DEMAND_DEPOSIT_TYPE = 'B' THEN '02' -- 个人II类账户
			WHEN T1.DEMAND_DEPOSIT_TYPE = 'C' THEN '03' -- 个人III类账户
            WHEN T1.PBOC_ACCT_NATURE_CD = '0011' THEN '04' -- 单位基本存款账户
	        WHEN T1.PBOC_ACCT_NATURE_CD = '0012' THEN '05' -- 单位一般存款账户
		    WHEN SUBSTR(T1.PBOC_ACCT_NATURE_CD,1,4) = '0013' THEN '06' -- 单位专用存款账户
		    WHEN T1.PBOC_ACCT_NATURE_CD = '0014' THEN '07' -- 单位临时存款账户            
	        WHEN SUBSTR(T1.PBOC_ACCT_NATURE_CD,1,1) IN ('1','2','3','4') OR T1.PBOC_ACCT_NATURE_CD IN ('5101','5102','5201','5202') THEN '09'	-- 外汇结算账户
	        WHEN T1.PBOC_ACCT_NATURE_CD IN ('5203','5103','001702') OR T1.DEMAND_DEPOSIT_TYPE = 'E' THEN '10'	-- 非结算账户
	        ELSE '00' -- 其他
	         END   AS  F010008                     , -- 08 存款账户类型
	   '01' AS F010009                    , -- 09 提前支取标识
	   NULL AS  F010010                   , -- 10 提前支取罚息
	   NVL(T9.YWYWGX,'0')     AS F010011     , -- 11 业务关系标识  JLBA202409120001 20241128     
	   '1'  AS F010012                       , -- 12 行为性期权标识
	   CASE  WHEN T3.BANKBOOK_TYPE = '1' THEN  '02'  -- 普通存折
             WHEN T3.BANKBOOK_TYPE = '2' THEN  '04'  -- 存单
             WHEN T3.BANKBOOK_TYPE = '3' THEN '06'  -- 一本通
             WHEN T3.BANKBOOK_TYPE = '4' THEN '05'  -- 大额定期存单
             WHEN T3.BANKBOOK_TYPE = '9' THEN  '09' -- 其他
             WHEN A.ACCT_MED IN ('1','2','3','7') THEN '01' -- 卡
          ELSE '08' -- 无介质             
          END  AS F010013  , -- 13 交易介质    EAST逻辑同步
	   CASE WHEN A.ACCT_MED IN ('1','2','3','7') THEN T2.CP_ID 
	        ELSE null 
	        END    AS F010015              , -- 14 交易介质ID
	   CASE WHEN T1.GL_ITEM_CODE IN ('20110114','20110115','20110209','20110210') THEN '1'
	        ELSE '0'
	         END AS F010016                  , -- 15 保证金账户标识
	   CASE WHEN T1.GL_ITEM_CODE = '20110111' THEN '0' 
	        ELSE NVL(T1.INT_RATE,0)
	         END AS F010017                  , -- 16 利率
       '01' AS  F010018                       , -- 17 利率定价基础
	   CASE WHEN T1.GL_ITEM_CODE ='20110111' THEN NVL(TO_CHAR(TO_DATE(T8.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD') ,TO_CHAR(TO_DATE(T1.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD'))
	        ELSE  (CASE WHEN T1.ACCT_OPDATE > I_DATE THEN TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')  
	                   ELSE TO_CHAR(TO_DATE(T1.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD')
	                    END) -- [20251028][巴启威][JLBA202509280009][吴大为]: 特殊处理开户日期跨日问题
           END AS F010019             , -- 18 开户日期
	   NVL(T1.OPEN_ACCT_AMT,0)  AS F010020          , -- 19 开户金额
	   CASE WHEN T1.GL_ITEM_CODE ='20110111' THEN NVL(TO_CHAR(TO_DATE(T8.ACCT_CLDATE,'YYYYMMDD'),'YYYY-MM-DD') ,'9999-12-31') 
	        ELSE NVL(TO_CHAR(TO_DATE(T1.MATUR_DATE,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') 
	         END AS F010021              , -- 20 到期日期
	   T1.CURR_CD  AS  F010022               , -- 21 协议币种
	   CASE WHEN T1.ACCOUNT_CATA_FLG = '2' THEN '01' -- 钞
	        WHEN T1.ACCOUNT_CATA_FLG = '3' THEN '02' -- 汇
			WHEN T1.ACCOUNT_CATA_FLG = '4' THEN '03' -- 可钞可汇
	    END AS F010023                           ,  -- 22 钞汇类别    
	   TO_CHAR(TO_DATE(T1.ACCT_CLDATE,'YYYYMMDD'),'YYYY-MM-DD')  AS F010024            , -- 23 销户日期
	   NVL(T1.ZHZJKZQK,'05') AS F010026                , -- 24 账户资金控制情况
	   CASE WHEN T1.ACCT_STS IN ('D','N') THEN '01' -- 正常
            WHEN T1.ACCT_STS = 'E01' THEN '02'	 -- 待生效
            WHEN T1.ACCT_STS IN ('E02','L') OR SUBSTR(T1.ACCT_STS,1,1) = 'W' THEN '03'  -- 中止
	        WHEN T1.ACCT_STS = 'C' THEN '04'	-- 终止
	        ELSE '00' 
             END   AS  F010027               , -- 25 协议状态
       DECODE(T1.JBYG_ID,'CONVTELLER','自动',T1.JBYG_ID)   AS  F010028               , -- 26 经办员工ID 20240612 一表通逻辑修正
       NVL(DECODE(T1.SCYG_ID,'CONVTELLER','自动',T1.SCYG_ID),DECODE(T1.JBYG_ID,'CONVTELLER','自动',T1.JBYG_ID))   AS  F010029               , -- 27  审查员工ID
       DECODE(T1.SPYG_ID,'ZN0000','自动',T1.SPYG_ID)   AS  F010030               , -- 28  审批员工ID
       CASE WHEN REGEXP_LIKE(T1.GHYG_ID,'^[0-9]+$') AND LENGTH(T1.GHYG_ID)= 6 THEN T1.GHYG_ID
          ELSE '自动'
           END AS  F010031               , -- 29  管户员工ID
       CASE WHEN A.ACCT_MED = '1' THEN   NVL(T2.CARD_NO,A.TYPE_ID)  
	         END AS  F010036               , -- 30  借记卡卡号
	   TO_CHAR(TO_DATE(T2.USE_DATE,'YYYYMMDD'),'YYYY-MM-DD')  AS F010037               , -- 31 借记卡开卡日期
	   CASE WHEN A.ACCT_MED ='1' OR T2.CARD_NO IS NOT NULL THEN 
	        (CASE WHEN T2.CARDSTAT = 'A' THEN '01' -- 未激活
                  WHEN T2.CARDSTAT = 'N' THEN '02' -- 正常
	              WHEN T2.CARDSTAT = 'Z' THEN '03' -- 注销
	              WHEN T2.CARDSTAT = 'D' THEN '04' -- 冻结
	              WHEN T2.CARDSTAT = 'S' THEN '05' -- 睡眠
	              WHEN T2.CARDSTAT = 'L' THEN '06' -- 挂失
	              ELSE '07' -- 其他
	               END )
	        ELSE ''        
             END	 AS F010038                      , -- 32 借记卡状态
       CASE WHEN A.ACCT_MED ='1' AND REGEXP_LIKE(T2.TELLER_NUM,'^[0-9]+$') AND LENGTH(T2.TELLER_NUM)= 6 THEN T2.TELLER_NUM
          ELSE ''
           END        AS F010039                  , -- 33 借记卡启用柜员ID
	  -- T3.BANKBOOK_CODE || '_' || T3.BANKBOOK_TYPE AS F010040           , -- 34 存折号    EAST逻辑同步
       CASE WHEN T3.PREFIX IS NOT NULL THEN 
                  T3.PREFIX||'_'||T3.BANKBOOK_CODE || '_' || T3.BANKBOOK_TYPE
            ELSE T3.BANKBOOK_CODE || '_' || T3.BANKBOOK_TYPE
              END AS F010040           , -- 34 存折号 JLBA202502170010 王超 冯启航 20250527 村镇回行数据拼上前缀（支票类也有前缀，后续待验证）    	  
	   CASE WHEN T3.OPEN_DATE <= '19490101' THEN '1999-04-01'
               ELSE  (CASE WHEN T3.OPEN_DATE > I_DATE THEN TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')  
	                   ELSE TO_CHAR(TO_DATE(T3.OPEN_DATE,'YYYYMMDD'),'YYYY-MM-DD')
	                    END) -- [20251028][巴启威][JLBA202509280009][吴大为]: 特殊处理开户日期跨日问题
             END    AS F010041              , -- 35 存折启用日期   EAST逻辑同步
	   -- TO_CHAR(TO_DATE(T3.OPEN_DATE,'YYYYMMDD'),'YYYY-MM-DD')  AS F010041              , -- 35 存折启用日期
	   CASE WHEN T3.BANKBOOK_CODE IS NOT NULL THEN 
	        (CASE WHEN T3.BANKBOOK_STATUS = '5' THEN '01' -- 未激活
                  WHEN T3.BANKBOOK_STATUS = '1' THEN '02' -- 正常
                  WHEN T3.BANKBOOK_STATUS = '3' THEN '03' -- 注销
                  WHEN T3.BANKBOOK_STATUS = '2' THEN '04' -- 冻结	 
	              WHEN T3.BANKBOOK_STATUS = '4' THEN '05' -- 睡眠
	              WHEN T3.BANKBOOK_STATUS = '6' THEN '06' -- 挂失
	              ELSE '07' -- 其他
	               END )
	        ELSE ''
	         END  AS F010042                       , -- 36 存折状态 
       DECODE(T3.OPEN_TELLER,'CONVTELLER','自动', T3.OPEN_TELLER) AS F010043                  , -- 37 存折启用柜员ID
	   CASE WHEN A.ACCT_MED = '6' THEN A.TYPE_ID
	         END AS F010044                        , -- 38 其他介质号
	   CASE WHEN A.ACCT_MED = '6' THEN 
	              (CASE WHEN A.QYRQ > I_DATE THEN TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')  
	                    ELSE TO_CHAR(TO_DATE(A.QYRQ,'YYYYMMDD'),'YYYY-MM-DD')
	                    END) -- [20251028][巴启威][JLBA202509280009][吴大为]: 特殊处理开户日期跨日问题
	         END AS F010045                  , -- 39 其他介质启用日期
	   CASE WHEN A.ACCT_MED = '6' THEN 
	         (CASE WHEN A.MEDIUM_STAT = 'A' THEN '02' -- 正常
	               ELSE '03' -- 注销
	                END)
	         END AS F010046                       , -- 40 其他介质状态
	   CASE WHEN A.ACCT_MED = '6' THEN 
	        (CASE WHEN REGEXP_LIKE(A.QYGY_ID,'^[0-9]+$') AND LENGTH(A.QYGY_ID)= 6 THEN A.QYGY_ID
                  ELSE '自动'
                   END)
             END  AS F010047                       , -- 41 其他介质启用柜员ID
       CASE WHEN T1.GL_ITEM_CODE = '20110201' AND T5.DEPOSIT_CUSTTYPE NOT IN ('13','14') THEN '01'    -- 单位活期存款
            WHEN T1.GL_ITEM_CODE IN ('20110202','20110203','20110208') AND T5.DEPOSIT_CUSTTYPE NOT IN ('13','14') THEN '02'	-- 单位定期存款
            WHEN T1.GL_ITEM_CODE = '20110205' AND T5.DEPOSIT_CUSTTYPE NOT IN ('13','14') THEN '03'	-- 单位通知存款
            WHEN T1.GL_ITEM_CODE IN ('20110204','20110211') AND T5.DEPOSIT_CUSTTYPE NOT IN ('13','14') THEN '04'	-- 单位协议存款
            -- WHEN T1.GL_ITEM_CODE = '' THEN '05'	-- 单位协定存款
            WHEN T1.GL_ITEM_CODE IN ('20110209','20110210') AND T5.DEPOSIT_CUSTTYPE NOT IN ('13','14') THEN '06'	-- 单位保证金存款
            WHEN T1.GL_ITEM_CODE = '20110207' AND T5.DEPOSIT_CUSTTYPE NOT IN ('13','14') THEN '07'	-- 单位结构性存款（不含保本理财）
            -- WHEN T1.GL_ITEM_CODE = '' THEN '08'	-- 单位其他存款
            WHEN T1.GL_ITEM_CODE IN ('20110101','20110111') THEN '09'	-- 个人活期存款 
	    WHEN T1.GL_ITEM_CODE = '20110201' AND T5.DEPOSIT_CUSTTYPE IN ('13','14') THEN '09'	-- 个人活期存款
	    WHEN T1.GL_ITEM_CODE IN ('20110103','20110104','20110105','20110106','20110107','20110109','20110113') THEN '10'	-- 个人定期存款
			WHEN T1.GL_ITEM_CODE IN ('20110202','20110203','20110208') AND T5.DEPOSIT_CUSTTYPE IN ('13','14') THEN '10'	-- 个人定期存款
            WHEN T1.GL_ITEM_CODE = '20110102' THEN '11'	-- 定活两便存款
            WHEN T1.GL_ITEM_CODE = '20110110' THEN '12'	-- 个人通知存款
			WHEN T1.GL_ITEM_CODE = '20110205' AND T5.DEPOSIT_CUSTTYPE IN ('13','14') THEN '12'	-- 个人通知存款
            WHEN T1.GL_ITEM_CODE IN ('20110204','20110211') AND T5.DEPOSIT_CUSTTYPE  IN ('13','14') THEN '13'	-- 个人协议存款
            -- WHEN T1.GL_ITEM_CODE = '' THEN '14'	-- 个人协定存款
            WHEN T1.GL_ITEM_CODE IN ('20110114','20110115') THEN '15'	-- 个人保证金存款
			WHEN T1.GL_ITEM_CODE IN ('20110209','20110210') AND T5.DEPOSIT_CUSTTYPE IN ('13','14') THEN '15'	-- 个人保证金存款
            WHEN T1.GL_ITEM_CODE = '20110112' THEN '16'	-- 个人结构性存款（不含保本理财）
			WHEN T1.GL_ITEM_CODE = '20110207' AND T5.DEPOSIT_CUSTTYPE IN ('13','14') THEN '16'	-- 个人结构性存款（不含保本理财）
            WHEN T1.GL_ITEM_CODE = '20110108' THEN '10'	-- 个人其他存款 20110108个人教育储蓄存款  20240613 按个人金融部反馈,20110108科目归类到10-个人定期存款
            WHEN SUBSTR(T1.GL_ITEM_CODE,1,6) = '201107'  or  SUBSTR(T1.GL_ITEM_CODE,1,4) = '2010' THEN '18'	-- 国库定期存款     --   周敬坤 JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求  提出2010 科目  对应201107科目
            WHEN SUBSTR(T1.GL_ITEM_CODE,1,4) = '2013' OR T1.GL_ITEM_CODE = '20140301' THEN '19' -- 临时性存款
            -- WHEN T1.GL_ITEM_CODE IN ('20120106','20120204') THEN '20'	-- 保险公司存款
            -- WHEN T1.GL_ITEM_CODE IN ('201201','201202') THEN '21'	-- 同业存放款项
            WHEN T1.GL_ITEM_CODE IN ('20120106') THEN '20'	-- 20-保险公司活期存款 -- ALTER BY WJB 20240706 一表通2.0升级
            WHEN T1.GL_ITEM_CODE IN ('20120204') THEN '21'	-- 21-保险公司定期存款 -- ALTER BY WJB 20240706 一表通2.0升级
          --  WHEN T1.GL_ITEM_CODE IN ('201201','201202') THEN '22'	-- 22-同业存放款项 -- ALTER BY WJB 20240706 一表通2.0升级
            WHEN SUBSTR(T1.GL_ITEM_CODE,1,4)='2012' THEN '22'	-- 22-同业存放款项 -- ALTER BY WJB 20240706 一表通2.0升级

            ELSE '00'  -- 其他
            END  AS F010048                          , -- 42 存款产品类别
	   CASE WHEN T1.C_DEPOSIT_TYPE LIKE 'C%' THEN '1'
		    ELSE '0'
		    END AS F010049                    , -- 43 社会保障基金存款标识
	   CASE WHEN T5.DEPOSIT_CUSTTYPE IN ('13','14') THEN '1'
	        ELSE '0'
	        END AS F010032                         , -- 44 备注
	   TO_CHAR(TO_DATE(T1.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS F010035 ,   -- 45 采集日期 
	   TO_CHAR(TO_DATE(T1.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE , 
	   CASE WHEN T1.GL_ITEM_CODE='20110111' THEN '009803'
	        ELSE T1.ORG_NUM
	         END AS DIS_BANK_ID    ,
	   CASE WHEN T1.GL_ITEM_CODE IN ('20110114','20110115','20110209','20110210') THEN '0098JR'
	        WHEN T1.TX = '个人金融部' THEN '009821'
	        WHEN T1.TX = '公司金融部' THEN '0098JR'
	        WHEN T1.TX = '机构金融部' THEN '0098JYB'
	        ELSE '009820'
	         END AS DEPARTMENT_ID,
	         ROW_NUMBER() OVER(PARTITION BY T1.ACCT_NUM ORDER BY /*T1.ACCT_NUM*/T1.ACCT_TYPE DESC) N
	         -- [20250807][巴启威][JLBA202507090010][吴大为]:ACCT_TYPE 0602协定户和 0601结算户，监管答疑，同一账户的协定户和结算户合并报送，利率取协定户利率
           FROM SMTMODS.L_ACCT_DEPOSIT T1
	  LEFT JOIN SMTMODS.L_ACCT_DEPOSIT_SUB A -- 存款账户介质关系表
	         ON T1.ACCT_NUM = A.ACCT_NUM
			AND A.DATA_DATE = I_DATE
			AND A.MEDIUM_STAT ='A'
	  LEFT JOIN SMTMODS.L_AGRE_CARD_INFO T2
	         ON A.TYPE_ID = T2.CARD_NO
			AND T2.DATA_DATE = I_DATE
			AND A.ACCT_MED IN ('1','2','3','7')
	  LEFT JOIN SMTMODS.L_ACCT_BANKBOOK T3 -- 存折信息
	         ON A.TYPE_ID = T3.BANKBOOK_CODE
			AND T3.DATA_DATE = I_DATE
			AND A.CUST_ID = T3.CUST_ID 
		    AND A.ACCT_MED IN ('5','6') -- 存折 	存单
			AND T3.BANKBOOK_TYPE IN ('1','2','3','4','9')
            AND T3.BANKBOOK_STATUS_DESC <> '已收回' -- 因校验规则YBT_JYF01-131 发现存在冲的介质号，其中有已收回状态的，所以剔除已收回的介质 87V
	  LEFT JOIN SMTMODS.L_CUST_C T5
	         ON T1.CUST_ID = T5.CUST_ID
	        AND T5.DATA_DATE = I_DATE
	  LEFT JOIN SMTMODS.L_CUST_P T6
	         ON T1.CUST_ID = T6.CUST_ID
	        AND T6.DATA_DATE = I_DATE
	  LEFT JOIN SMTMODS.L_CUST_BILL_TY T7
	         ON T1.CUST_ID = T7.ECIF_CUST_ID -- T7.CUST_ID  -- JLBA202411070004 20241212 
	        AND T7.DATA_DATE = I_DATE 
	  LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
             ON T1.ORG_NUM = ORG.ORG_NUM
            AND ORG.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_ACCT_CARD_CREDIT T8 -- 关联信用卡账户表，取溢缴款的开户日期
             ON T1.ACCT_NUM = T8.ACCT_NUM
            AND T8.DATA_DATE =  I_DATE
      LEFT JOIN T_DEPOSIT_YWGX T9
             ON T1.ACCT_NUM = T9.ACCT_NUM       
     WHERE T1.DATA_DATE = I_DATE 
	             -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
       AND (T1.ACCT_CLDATE >= SUBSTR(I_DATE,1,4)||'0101'
 		     OR ( T1.ACCT_CLDATE IS NULL /*AND  T1.ACCT_BALANCE > 0*/ )
 		     OR T1.ACCT_BALANCE > 0)   -- 20240724 ZJK UPDATE 出现一笔销户日期为空 余额为0的数据
       AND SUBSTR(T1.ORG_NUM,1,1) NOT IN ('5','6','7')	     
       AND org.ORG_NAM NOT LIKE '%村镇%'
       AND  SUBSTR(T1.GL_ITEM_CODE,1,4) IN ('2011','2012','2013','2014','2010') -- [20251015]2010 国库定期存款新科目
	   AND SUBSTR(T1.GL_ITEM_CODE,1,6) <>  '224101'   -- 久悬 
	   AND T1.GL_ITEM_CODE IS NOT NULL 
	   AND SUBSTR(T1.ACCT_STS,1,3)<>'E01' -- EAST 表间校验  
	   AND T1.GL_ITEM_CODE NOT IN ('20110301','20110302','20110303','20110501','20110502','20110111') -- 0408 大为哥剔除
	   AND SUBSTR(T1.GL_ITEM_CODE,1,4) NOT IN ('3010','3020','2005')  --   周敬坤 JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求  提出2005 科目  对应201105科目
	   -- [JLBA202507250003][20250909][巴启威]:增加同业存款
/*AND T1.GL_ITEM_CODE NOT IN ('20120101',
'20120102',
'20120103',
'20120104',
'20120105',
'20120107',
'20120108',
'20120109',
'20120110',
'20120111',
'20120201',
'20120202',
'20120203',
'20120205',
'20120206',
'20120207',
'20120208',
'20120209') -- 0418 按照大为哥口径剔除*/
	   ) X
	   WHERE X.N = 1) A 
	   
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

