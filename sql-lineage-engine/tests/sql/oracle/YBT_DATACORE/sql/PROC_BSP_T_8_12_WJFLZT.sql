DROP Procedure IF EXISTS `PROC_BSP_T_8_12_WJFLZT` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_8_12_WJFLZT"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN

  /******
      程序名称  ：五级分类状态
      程序功能  ：加工五级分类状态
      目标表：T_8_12
      源表  ：两段 正常贷款和信用卡
      创建人  ：WJB
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/

     /*需求编号：JLBA202502200003 上线日期：20250415，修改人：姜俐锋，提出人：李逊昂,吴大为 修改原因：  去掉信用卡核销数据*/
	 /*需求编号：JLBA202505280002 上线日期：2025-06-19，修改人：巴启威  提出人：吴大为  修改原因：回退JLBA202504060003版本 
     /*需求编号：JLBA202505270010   上线日期：20250729，修改人：姜俐锋，提出人：吴大为 关于一表通监管数据报送系统新增投资业务指标的需求 修改原因：新增投资类五级分类*/	
     /*需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
	 /*需求编号 JLBA202507250003 上线日期：2025-09-09，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统修改取数逻辑的需求*/
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
	SET P_PROC_NAME = 'PROC_BSP_T_8_12_WJFLZT';
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

	DELETE FROM T_8_12 WHERE H120013 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
	DELETE FROM L_ACCT_GRADE_CHANGE_BDQ;
	DELETE FROM L_ACCT_GRADE_CHANGE_BDH;

	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);

    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '正常贷款数据插入';

INSERT INTO L_ACCT_GRADE_CHANGE_BDH -- 贷款五级形态变动临时表 用于计算该笔借据最新一条五级分类
SELECT AA.* FROM
(
SELECT ROW_NUMBER() OVER(PARTITION BY A.LOAN_NUM ORDER BY A.CHANGE_DATE DESC) AS RN, A.*
  FROM SMTMODS.L_ACCT_GRADE_CHANGE A -- 贷款五级形态变动
) AA 
 WHERE AA.RN ='1'
 ;

INSERT INTO L_ACCT_GRADE_CHANGE_BDQ -- 贷款五级形态变动临时表 用于计算该笔借据倒数第二条五级分类
SELECT AA.* FROM
(
SELECT ROW_NUMBER() OVER(PARTITION BY A.LOAN_NUM ORDER BY A.CHANGE_DATE DESC) AS RN, A.*
  FROM SMTMODS.L_ACCT_GRADE_CHANGE A -- 贷款五级形态变动
) AA 
 WHERE AA.RN ='2'
 ;

-- ALTER BY WJB 20240408 修改取数逻辑 把借据表作为主表 作为最新的一条五级形态记录
INSERT INTO T_8_12
 (
 H120001   , -- 01 '协议ID'
 H120002   , -- 02 '细分资产ID'
 H120003   , -- 03 '机构ID'
 H120004   , -- 04 '调整日期'
 H120005   , -- 05 '当前五级分类'
 H120006   , -- 06 '原五级分类'
 H120007   , -- 07 '变动方式'
 H120008   , -- 08 '变动原因'
 H120009   , -- 09 '经办员工ID'
 H120010   , -- 10 '审查员工ID'
 H120011   , -- 11 '审批员工ID'
 H120012   , -- 12 '币种'
 H120013   , -- 13 '采集日期'
 H120014   , -- 14 '减值准备'
 DIS_DATA_DATE, -- 装入数据日期
 DIS_BANK_ID,   -- 机构号
 DEPARTMENT_ID  -- 业务条线
 )
 
     SELECT      -- T1.ACCT_NUM 			                       	
            CASE WHEN substr(t1.ITEM_CD,1,6) IN ('130101','130102','130104','130105') THEN SUBSTR(t1.ACCT_NUM || NVL(t1.DRAFT_RNG,''),1,60)
                 ELSE T1.ACCT_NUM		
                 END  AS H120001                        ,    -- 01 '协议ID'    0705wwk
            CASE WHEN SUBSTR(t1.ITEM_CD, 1, 6) in ('130101', '130102', '130104', '130105') THEN SUBSTR(t1.ACCT_NUM || NVL(t1.DRAFT_RNG,''),1,60)
                 ELSE T1.LOAN_NUM
                 END  AS H120002                       	, -- 02 '细分资产ID'
            T3.ORG_ID AS H120003                        , -- 03 '机构ID'
            CASE WHEN T4.LOAN_NUM IS NOT NULL THEN TO_CHAR(TO_DATE(T4.CHANGE_DATE,'YYYYMMDD'),'YYYY-MM-DD')
                 WHEN T1.LOAN_KIND_CD = T5.LOAN_KIND_CD THEN '' -- [JLBA202507250003][20250909][巴启威]: 贷款五级形态变动表中缺失的借据（历史数据发生变动），与借据表前一天的五级分类对比是否发生变化
                 END  AS H120004                        , -- 04 '调整日期' 状态一直为正常的借据可置空  
            CASE WHEN T1.LOAN_GRADE_CD = '1' THEN '01' -- 正常
             	 WHEN T1.LOAN_GRADE_CD = '2' THEN '02' -- 关注
             	 WHEN T1.LOAN_GRADE_CD = '3' THEN '03' -- 次级
            	 WHEN T1.LOAN_GRADE_CD = '4' THEN '04' -- 可疑
             	 WHEN T1.LOAN_GRADE_CD = '5' THEN '05' -- 损失
                 ELSE '00' -- 未分级
                 END  AS H120005                        , -- 05 '当前五级分类'
            CASE WHEN (T4.ORI_GRADE_CD = '1' OR T4.ORI_GRADE_CD IS NULL) THEN '01' -- 正常
                 WHEN T4.ORI_GRADE_CD = '2' THEN '02' -- 关注
                 WHEN T4.ORI_GRADE_CD = '3' THEN '03' -- 次级
                 WHEN T4.ORI_GRADE_CD = '4' THEN '04' -- 可疑
                 WHEN T4.ORI_GRADE_CD = '5' THEN '05' -- 损失
                 WHEN T1.LOAN_KIND_CD = T5.LOAN_KIND_CD THEN '0'||T1.LOAN_KIND_CD  -- [JLBA202507250003][20250909][巴启威]: 贷款五级形态变动表中缺失的借据（历史数据发生变动），与借据表前一天的五级分类对比是否发生变化
                 ELSE '00' -- 未分级
                 END  AS H120006                        , -- 06 '原五级分类'
            '01'      AS H120007                        , -- 07 '变动方式' 默认 01 人工
            CASE WHEN  T4.ORI_GRADE_CD < T4.GRADE_CD THEN '下迁'
                 WHEN  T4.ORI_GRADE_CD > T4.GRADE_CD THEN '上迁'
                 ELSE '未变动'
                 END  AS H120008                        , -- 08 '变动原因' 
            COALESCE(T4.OP_EMP_ID,T4.CHANGE_EMP_ID,T1.JBYG_ID,T1.EMP_ID) AS H120009 , -- 09 '经办员工ID' 
            T2.SCYG_ID      AS H120010                  , -- 10 '审查员工ID'
            T2.APP_EMP_ID   AS H120011                  , -- 11 '审批员工ID'
            T1.CURR_CD      AS H120012                  , -- 12 '币种'
            TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS H120013 , -- 13 '采集日期'
            T1.GENERAL_RESERVE AS H120014,                                -- 14 '减值准备'           
            TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),             -- 15 '装入数据日期'
		    T1.ORG_NUM,                                                   -- 16 '机构号'
		    '0098XT'                                                      -- 17 '业务条线  默认信贷与投资管理部'
        FROM SMTMODS.L_ACCT_LOAN T1 -- 贷款借据信息表，把借据表当成最新的一条五级分类
        LEFT JOIN L_ACCT_GRADE_CHANGE_BDQ T2 -- 有变动的借据，倒数第二新一条五级分类临时表
          ON T1.LOAN_NUM = T2.LOAN_NUM
        LEFT JOIN VIEW_L_PUBL_ORG_BRA T3 -- 机构表视图
          ON T1.ORG_NUM = T3.ORG_NUM
         AND T3.DATA_DATE = I_DATE
        LEFT JOIN L_ACCT_GRADE_CHANGE_BDH T4  -- 贷款五级形态变动
          ON T1.LOAN_NUM = T4.LOAN_NUM  
        LEFT JOIN SMTMODS.L_ACCT_LOAN T5  -- [JLBA202507250003][20250909][巴启威]: 贷款五级形态变动表中缺失的借据（历史数据发生变动），与借据表前一天的五级分类对比是否发生变化
          ON t1.LOAN_NUM = t5.LOAN_NUM
         AND t5.DATA_DATE = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD') - 1,'YYYYMMDD')
       WHERE T1.DATA_DATE = I_DATE
        -- AND T1.LOAN_ACCT_BAL <> '0' -- 不取贷款余额为0的借据
        -- AND T1.ACCT_TYP NOT LIKE '90%' -- 不取委托贷款     0620_LHY 补充委托贷款
         AND
         (T1.ACCT_STS <> '3' -- 不取结清的借据
          OR T1.LOAN_ACCT_BAL > 0 -- 不取贷款余额为0的借据
          OR T1.FINISH_DT >= SUBSTR(I_DATE,1,4)||'0101' -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
          OR (T1.INTERNET_LOAN_FLG = 'Y' AND   T1.FINISH_DT = TO_CHAR(TO_DATE((SUBSTR(I_DATE,1,4)||'0101'), 'YYYYMMDD') - 1,'YYYYMMDD'))  -- 取互联网贷款数据 [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
          OR (T1.CP_ID ='DK001000100041' AND  T1.FINISH_DT = TO_CHAR(TO_DATE((SUBSTR(I_DATE,1,4)||'0101'), 'YYYYMMDD') - 1,'YYYYMMDD')) -- [20250929][姜俐锋][JLBA202507300010][信贷新增产品]: 同网贷部分数据处理方式
          )
          AND NOT EXISTS
         (SELECT J.LOAN_NUM,J.WRITE_OFF_DATE -- 核销日期
          FROM SMTMODS.L_ACCT_WRITE_OFF J -- 贷款核销
         WHERE J.DATA_DATE = I_DATE
           AND J.WRITE_OFF_DATE < I_DATE
           AND J.LOAN_NUM = T1.LOAN_NUM )
           AND (T1.LOAN_STOCKEN_DATE IS NULL  OR T1.LOAN_STOCKEN_DATE=I_DATE)  -- add by haorui 20250311 JLBA202408200012 资产未转让
          ;
 
   CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
	
    #4.插入信用卡数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '信用卡数据插入';
	
DELETE FROM L_ACCT_GRADE_CHANGE_XYK ; -- 信用卡五级形态变动临时表

INSERT INTO L_ACCT_GRADE_CHANGE_XYK
(
ACCT_NUM, -- 协议ID
ORG_ID,   -- 机构id
TZRQ,	  -- 调整日期
DQWJFL,   -- 当前五级分类
YWJFL,	  -- 原五级分类
BDFS,     -- 变动方式
JBYG_ID,  -- 经办员工ID
SCYG_ID,  -- 审查员工ID
SPYG_ID,  -- 审批员工ID
BZ,		  -- 币种
CJRQ,	  -- 采集日期
JZZB,	  -- 减值准备
ZRRQ,	  -- 装入数据日期
ORG_NUM,  -- 机构号
YWTX	  -- 业务条线
)
SELECT      T1.ACCT_NUM			                        			, -- 01 '协议ID'
            'B0302H22201009803'                         			, -- 03 '机构ID'
            TO_CHAR(TO_DATE(T1.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD')  , -- 04 '调整日期'  默认数据日期为调整日期
    	    CASE WHEN T1.LXQKQS = '0' THEN '01' -- 正常
     	         WHEN T1.LXQKQS IN ('1','2','3') THEN '02' -- 关注
     	    	 WHEN T1.LXQKQS = '4' THEN '03' -- 次级
     	    	 WHEN T1.LXQKQS IN ('5','6') THEN '04' -- 可疑
     	    	 WHEN T1.LXQKQS > 6 THEN '05' -- 损失
            ELSE '00' -- 未分级
            END                                         			, -- 05 '当前五级分类'
    	    CASE WHEN T2.ACCT_NUM IS NULL THEN
    	    CASE WHEN T1.LXQKQS = '0' THEN '01' -- 正常
     	         WHEN T1.LXQKQS IN ('1','2','3') THEN '02' -- 关注
     	    	 WHEN T1.LXQKQS = '4' THEN '03' -- 次级
     	    	 WHEN T1.LXQKQS IN ('5','6') THEN '04' -- 可疑
     	    	 WHEN T1.LXQKQS > 6 THEN '05' -- 损失
            ELSE '00' -- 未分级
    	    END
    	         WHEN T2.LXQKQS = '0' THEN '01' -- 正常
     	         WHEN T2.LXQKQS IN ('1','2','3') THEN '02' -- 关注
     	    	 WHEN T2.LXQKQS = '4' THEN '03' -- 次级
     	    	 WHEN T2.LXQKQS IN ('5','6') THEN '04' -- 可疑
     	    	 WHEN T2.LXQKQS > 6 THEN '05' -- 损失
            ELSE '00' -- 未分级
            END                                         			, -- 06 '原五级分类'
            '02'                                         			, -- 07 '变动方式'  默认02 自动
            '自动'                                      				, -- 09 '经办员工ID' 若为自动审批，则填写“自动”。
            '自动'                                      				, -- 10 '审查员工ID' 若为自动审批，则填写“自动”。
            '自动'                                      				, -- 11 '审批员工ID' 若为自动审批，则填写“自动”。
            T1.CURR_CD                                  			, -- 12 '币种'
            TO_CHAR(TO_DATE(T1.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD')  , -- 13 '采集日期'
            NVL(T3.JZZB,'0')                                        , -- 14 '减值准备'
            TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),         --    '装入数据日期'
		    '009803',                                                 --    '机构号'
		    '009803'                                                  --    '业务条线  默认信用卡中心'
       FROM SMTMODS.L_ACCT_CARD_CREDIT T1 -- 信用卡账户信息表
       LEFT JOIN (SELECT * FROM SMTMODS.L_ACCT_CARD_CREDIT A1 WHERE A1.DATA_DATE = TO_CHAR(TO_DATE(A1.DATA_DATE,'YYYYMMDD')-1,'YYYYMMDD')) T2 -- 取上期作对比
         ON T1.ACCT_NUM = T2.ACCT_NUM
       LEFT JOIN (SELECT BIZ_NO,SUM(PRIN_FINAL_RESLT+OFBS_FINAL_RESLT+INT_FINAL_RESLT) AS JZZB FROM SMTMODS.L_FINA_ASSET_DEVALUE T WHERE T.DATA_DATE = I_DATE AND T.DATA_SRC = 'CCRD' GROUP BY BIZ_NO) T3
         ON TO_NUMBER(T1.ACCT_NUM) = TO_NUMBER(T3.BIZ_NO) -- T3 用于计算信用卡减值准备临时表
      WHERE T1.DATA_DATE = I_DATE
        AND (T1.DEALDATE = I_DATE OR T1.DEALDATE = '00000000')     -- add by haorui 20241119 JLBA202410090008信用卡收益权转让  start
	    AND NOT EXISTS (SELECT 1 FROM SMTMODS.L_ACCT_WRITE_OFF W WHERE W.DATA_DATE = I_DATE AND W.DATE_SOURCESD ='信用卡核销' AND T1.ACCT_NUM=W.ACCT_NUM) -- 20250415 JLBA202502200003 去掉核销部分  

UNION ALL
		SELECT  
			T1.ACCT_NUM			                        			, -- 01 '协议ID'
            'B0302H22201009803'                         			, -- 03 '机构ID'
            TO_CHAR(TO_DATE(T1.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD')  , -- 04 '调整日期'  默认数据日期为调整日期
    	    CASE WHEN T1.LXQKQS = '0' THEN '01' -- 正常
     	         WHEN T1.LXQKQS IN ('1','2','3') THEN '02' -- 关注
     	    	 WHEN T1.LXQKQS = '4' THEN '03' -- 次级
     	    	 WHEN T1.LXQKQS IN ('5','6') THEN '04' -- 可疑
     	    	 WHEN T1.LXQKQS > 6 THEN '05' -- 损失
            ELSE '00' -- 未分级
            END                                         			, -- 05 '当前五级分类'
    	    CASE WHEN T2.ACCT_NUM IS NULL THEN
    	    CASE WHEN T1.LXQKQS = '0' THEN '01' -- 正常
     	         WHEN T1.LXQKQS IN ('1','2','3') THEN '02' -- 关注
     	    	 WHEN T1.LXQKQS = '4' THEN '03' -- 次级
     	    	 WHEN T1.LXQKQS IN ('5','6') THEN '04' -- 可疑
     	    	 WHEN T1.LXQKQS > 6 THEN '05' -- 损失
            ELSE '00' -- 未分级
    	    END
    	         WHEN T2.LXQKQS = '0' THEN '01' -- 正常
     	         WHEN T2.LXQKQS IN ('1','2','3') THEN '02' -- 关注
     	    	 WHEN T2.LXQKQS = '4' THEN '03' -- 次级
     	    	 WHEN T2.LXQKQS IN ('5','6') THEN '04' -- 可疑
     	    	 WHEN T2.LXQKQS > 6 THEN '05' -- 损失
            ELSE '00' -- 未分级
            END                                         			, -- 06 '原五级分类'
            '02'                                         			, -- 07 '变动方式'  默认02 自动
            '自动'                                      				, -- 09 '经办员工ID' 若为自动审批，则填写“自动”。
            '自动'                                      				, -- 10 '审查员工ID' 若为自动审批，则填写“自动”。
            '自动'                                      				, -- 11 '审批员工ID' 若为自动审批，则填写“自动”。
            T1.CURR_CD                                  			, -- 12 '币种'
            TO_CHAR(TO_DATE(T1.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD')  , -- 13 '采集日期'
            NVL(T3.JZZB,'0')                                        , -- 14 '减值准备'
            TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),         --    '装入数据日期'
		    '009803',                                                 --    '机构号'
		    '009803'                                                  --    '业务条线  默认信用卡中心'
       FROM SMTMODS.L_ACCT_CARD_CREDIT T1 -- 信用卡账户信息表
	   LEFT JOIN SMTMODS.L_ACCT_DEPOSIT TT
		  ON T1.DATA_DATE = TT.DATA_DATE
		  AND T1.ACCT_NUM = TT.ACCT_NUM
		  AND TT.GL_ITEM_CODE ='20110111'
	   LEFT JOIN SMTMODS.L_ACCT_DEPOSIT T4
		  ON T1.ACCT_NUM = T4.ACCT_NUM
		  AND T4.DATA_DATE = LAST_DT
		  AND T4.GL_ITEM_CODE ='20110111'
       LEFT JOIN (SELECT * FROM SMTMODS.L_ACCT_CARD_CREDIT A1 WHERE A1.DATA_DATE = TO_CHAR(TO_DATE(A1.DATA_DATE,'YYYYMMDD')-1,'YYYYMMDD')) T2 -- 取上期作对比
         ON T1.ACCT_NUM = T2.ACCT_NUM
       LEFT JOIN (SELECT BIZ_NO,SUM(PRIN_FINAL_RESLT+OFBS_FINAL_RESLT+INT_FINAL_RESLT) AS JZZB FROM SMTMODS.L_FINA_ASSET_DEVALUE T WHERE T.DATA_DATE = I_DATE AND T.DATA_SRC = 'CCRD' GROUP BY BIZ_NO) T3
         ON TO_NUMBER(T1.ACCT_NUM) = TO_NUMBER(T3.BIZ_NO) -- T3 用于计算信用卡减值准备临时表
      WHERE T1.DATA_DATE = I_DATE
	  AND T1.DEALDATE <> '00000000'  
	  and (T4.ACCT_NUM is not null or T4.ACCT_NUM is null and TT.acct_num is not NULL)  -- 前一天有溢款款 或 前一天无溢缴款当有有溢缴款	  
	  -- add by haorui 20241119 JLBA202410090008信用卡收益权转让 end
      AND NOT EXISTS (SELECT 1 FROM SMTMODS.L_ACCT_WRITE_OFF W WHERE W.DATA_DATE = I_DATE AND W.DATE_SOURCESD ='信用卡核销' AND T1.ACCT_NUM=W.ACCT_NUM)  -- [20250415][姜俐锋][JLBA202502200003][李逊昂,吴大为]: 去掉核销部分  
 ;

INSERT INTO T_8_12
 (
 H120001   , -- 01 '协议ID'
 H120002   , -- 02 '细分资产ID'
 H120003   , -- 03 '机构ID'
 H120004   , -- 04 '调整日期'
 H120005   , -- 05 '当前五级分类'
 H120006   , -- 06 '原五级分类'
 H120007   , -- 07 '变动方式'
 H120008   , -- 08 '变动原因'
 H120009   , -- 09 '经办员工ID'
 H120010   , -- 10 '审查员工ID'
 H120011   , -- 11 '审批员工ID'
 H120012   , -- 12 '币种'
 H120013   , -- 13 '采集日期'
 H120014   , -- 14 '减值准备'
 DIS_DATA_DATE, -- 15 '装入数据日期'
 DIS_BANK_ID,   -- 16 '机构号'
 DEPARTMENT_ID       -- 17 '业务条线'
 )

SELECT   T.ACCT_NUM,			-- 01 '协议ID'
         '',                	-- 02 '细分资产ID'  信用卡数据默认为空
         T.ORG_ID, 				-- 03 '机构ID'
         T.TZRQ,                -- 04 '调整日期'
         T.DQWJFL,				-- 05 '当前五级分类'
         T.YWJFL,               -- 06 '原五级分类'
         T.BDFS,                -- 07 '变动方式'
         CASE WHEN  T.YWJFL < T.DQWJFL THEN '下迁'
              WHEN  T.YWJFL > T.DQWJFL THEN '上迁'
		      WHEN (T.DQWJFL = T.YWJFL OR T.YWJFL IS NULL) THEN '未变动'
         END,                   -- 08 '变动原因'         
         T.JBYG_ID,				-- 09 '经办员工ID'
         T.SCYG_ID,			    -- 10 '审查员工ID'
         T.SPYG_ID,             -- 11 '审批员工ID'
         T.BZ,					-- 12 '币种'
         T.CJRQ,				-- 13 '采集日期'
         T.JZZB,				-- 14 '减值准备'
         T.ZRRQ,                -- 15 '装入数据日期'
         T.ORG_NUM,             -- 16 '机构号'
         T.YWTX                 -- 17 '业务条线'
        FROM L_ACCT_GRADE_CHANGE_XYK T -- 信用卡五级形态变动临时表
        ;
       
	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
	
	
 -- JLBA202505270010_关于一表通监管数据报送系统新增投资业务指标的需求_20250728新增投资部分
INSERT INTO T_8_12
 (
 H120001   , -- 01 '协议ID'
 H120002   , -- 02 '细分资产ID'
 H120003   , -- 03 '机构ID'
 H120004   , -- 04 '调整日期'
 H120005   , -- 05 '当前五级分类'
 H120006   , -- 06 '原五级分类'
 H120007   , -- 07 '变动方式'
 H120008   , -- 08 '变动原因'
 H120009   , -- 09 '经办员工ID'
 H120010   , -- 10 '审查员工ID'
 H120011   , -- 11 '审批员工ID'
 H120012   , -- 12 '币种'
 H120013   , -- 13 '采集日期'
 H120014   , -- 14 '减值准备'
 DIS_DATA_DATE, -- 装入数据日期
 DIS_BANK_ID,   -- 机构号
 DEPARTMENT_ID,  -- 业务条线
 DIS_DEPT
 )
 
SELECT /*+PARALLEL(4)*/
             A.ACCT_NUM AS H120001   , -- 01 '协议ID'
             A.ACCT_NUM||A.REF_NUM AS H120002   , -- 02 '细分资产ID'
             ORG.ORG_ID AS H120003   , -- 03 '机构ID'
             CASE WHEN nvl(C.FIVE_TIER_CLS,'01') <> nvl(C1.FIVE_TIER_CLS,'01') THEN TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')  
                  ELSE NULL 
                   END AS H120004    , -- 04 '调整日期'
             nvl(C.FIVE_TIER_CLS,'01') AS H120005   , -- 05 '当前五级分类'
             nvl(C1.FIVE_TIER_CLS,'01') AS H120006   , -- 06 '原五级分类'
             '02' AS H120007   , -- 07 '变动方式'
             CASE WHEN nvl(C.FIVE_TIER_CLS,'01') > nvl(C1.FIVE_TIER_CLS,'01') THEN '下迁'
                  WHEN nvl(C.FIVE_TIER_CLS,'01') < nvl(C1.FIVE_TIER_CLS,'01') THEN '上迁'
                  ELSE '未变动'
                   END AS H120008   , -- 08 '变动原因'
             F1.GB_CODE AS H120009   , -- 09 '经办员工ID'
             F2.GB_CODE AS H120010   , -- 10 '审查员工ID'
             F3.GB_CODE AS H120011   , -- 11 '审批员工ID'
             A.CURR_CD AS H120012   , -- 12 '币种'
             TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS H120013   , -- 13 '采集日期'
             nvl(A.PREPARATION,0) AS H120014   , -- 14 '减值准备'   -- JLBA202505270010 因校验公式YBT_JYH12-27 修改逻辑为空取0
             TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE, -- 15 '装入数据日期'
             A.ORG_NUM AS DIS_BANK_ID,   -- 16 '机构号'
             '009804' AS DEPARTMENT_ID,   -- 17 '业务条线'
             '投资'
        FROM SMTMODS.L_ACCT_FUND_INVEST A -- 投资业务信息表 A
        LEFT JOIN SMTMODS.L_AGRE_BOND_INFO B -- 债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATE
        LEFT JOIN SMTMODS.L_FINA_ASSET_DEVALUE C -- 资产减值准备  
          ON C.ACCT_NUM = A.ACCT_NUM
         AND A.ACCT_NO = C.ACCT_ID -- [解决债券、存单关联减值重复问题]
         AND A.GL_ITEM_CODE = C.PRIN_SUBJ_NO
         AND A.ORG_NUM = C.RECORD_ORG
         AND C.DATA_DATE = I_DATE
        LEFT JOIN SMTMODS.L_FINA_ASSET_DEVALUE C1 -- 资产减值准备 2 
          ON C1.ACCT_NUM = A.ACCT_NUM
         AND A.ACCT_NO = C1.ACCT_ID 
         AND A.GL_ITEM_CODE = C1.PRIN_SUBJ_NO
         AND A.ORG_NUM = C1.RECORD_ORG
         AND C1.DATA_DATE = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD') -1 ,'YYYY-MM-DD')
        LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表视图 
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATE
        LEFT JOIN M_DICT_CODETABLE F1
          ON A.JBYG_ID = F1.L_CODE
         AND F1.L_CODE_TABLE_CODE ='C0013' 
        LEFT JOIN M_DICT_CODETABLE F2
          ON A.SZYG_ID = F1.L_CODE
         AND F1.L_CODE_TABLE_CODE ='C0013' 
        LEFT JOIN M_DICT_CODETABLE F3
          ON A.SPYG_ID = F1.L_CODE
         AND F1.L_CODE_TABLE_CODE ='C0013' 
       WHERE A.DATA_DATE = I_DATE
         AND NVL(A.PRINCIPAL_BALANCE, 0) <> 0 
         AND B.ISSUER_INLAND_FLG = 'Y' 
         ; 
	
	
	    #4.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '财管数据插入';
	
	
	
INSERT INTO T_8_12
 (
 H120001   , -- 01 '协议ID'
 H120002   , -- 02 '细分资产ID'
 H120003   , -- 03 '机构ID'
 H120004   , -- 04 '调整日期'
 H120005   , -- 05 '当前五级分类'
 H120006   , -- 06 '原五级分类'
 H120007   , -- 07 '变动方式'
 H120008   , -- 08 '变动原因'
 H120009   , -- 09 '经办员工ID'
 H120010   , -- 10 '审查员工ID'
 H120011   , -- 11 '审批员工ID'
 H120012   , -- 12 '币种'
 H120013   , -- 13 '采集日期'
 H120014   , -- 14 '减值准备'
 DIS_DATA_DATE, -- 15 '装入数据日期'
 DIS_BANK_ID,   -- 16 '机构号'
 DEPARTMENT_ID       -- 17 '业务条线'
 )
 select 
  H120001   , -- 01 '协议ID'
 H120002   , -- 02 '细分资产ID'
 H120003   , -- 03 '机构ID'
 H120004   , -- 04 '调整日期'
 H120005   , -- 05 '当前五级分类'
 H120006   , -- 06 '原五级分类'
 H120007   , -- 07 '变动方式'
 H120008   , -- 08 '变动原因'
 H120009   , -- 09 '经办员工ID'
 H120010   , -- 10 '审查员工ID'
 H120011   , -- 11 '审批员工ID'
 H120012   , -- 12 '币种'
 H120013   , -- 13 '采集日期'
 H120014   , -- 14 '减值准备'
  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 15 '装入数据日期'
 '990000',   -- 16 '机构号'
  CASE WHEN  ywxt = '总行机关战略投资管理部' THEN  '0098ZT'
	    WHEN  ywxt = '总行机关运营管理部' THEN  '009801'
    END             -- 17 '业务条线'
 from smtmods.RSF_GQ_FIVELEVE_CLASSIFICATIONSTATUS  t  where  t.DATA_DATE=I_DATE;
 commit;
 
   CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);

	    #4.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = 'RPA数据插入';

-- RPA 债转股 + 非标
INSERT INTO T_8_12
 ( 
 H120001   , -- 01 '协议ID'
 H120002   , -- 02 '细分资产ID'
 H120003   , -- 03 '机构ID'
 H120004   , -- 04 '调整日期'
 H120005   , -- 05 '当前五级分类'
 H120006   , -- 06 '原五级分类'
 H120007   , -- 07 '变动方式'
 H120008   , -- 08 '变动原因'
 H120009   , -- 09 '经办员工ID'
 H120010   , -- 10 '审查员工ID'
 H120011   , -- 11 '审批员工ID'
 H120012   , -- 12 '币种'
 H120013   , -- 13 '采集日期'
 H120014   , -- 14 '减值准备'
 DIS_DATA_DATE, -- 装入数据日期
 DIS_BANK_ID,   -- 机构号
 DEPARTMENT_ID  -- 业务条线
 )
 SELECT 
 H120001   , -- 01 '协议ID'
 H120002   , -- 02 '细分资产ID'
 H120003   , -- 03 '机构ID'
 H120004   , -- 04 '调整日期'
 SUBSTR (H120005,INSTR(H120005,'[',1,1) + 1 , INSTR(H120005, ']',1 ) -INSTR(H120005,'[',1,1) - 1 ) AS H120005   , -- 05 '当前五级分类'
 SUBSTR (H120006,INSTR(H120006,'[',1,1) + 1 , INSTR(H120006, ']',1 ) -INSTR(H120006,'[',1,1) - 1 ) AS H120006   , -- 06 '原五级分类'
 SUBSTR (H120007,INSTR(H120007,'[',1,1) + 1 , INSTR(H120007, ']',1 ) -INSTR(H120007,'[',1,1) - 1 ) AS H120007   , -- 07 '变动方式'
 H120008   , -- 08 '变动原因'
 H120009   , -- 09 '经办员工ID'
 H120010   , -- 10 '审查员工ID'
 H120011   , -- 11 '审批员工ID'
 SUBSTR (H120012,INSTR(H120012,'[',1,1) + 1 , INSTR(H120012, ']',1 ) -INSTR(H120012,'[',1,1) - 1 ) AS H120012   , -- 12 '币种'
 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS H120013   , -- 13 '采集日期'
 TO_NUMBER(REPLACE(H120014,',','')) AS H120014   , -- 14 '减值准备'
 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE, -- 15 '装入数据日期'
 '990000',   -- 16 '机构号'
 SUBSTR ( DEPARTMENT_ID,INSTR(DEPARTMENT_ID,'[',1,1) + 1 , INSTR(DEPARTMENT_ID, ']',1 ) -INSTR(DEPARTMENT_ID,'[',1,1) - 1 ) AS DEPARTMENT_ID       -- 业务条线
  FROM ybt_datacore.RPAJ_8_12_WJFL A
 WHERE A.DATA_DATE =I_DATE; 
 COMMIT ;
 
   CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
	
    -- 投管
 INSERT INTO T_8_12
 ( 
 H120001   , -- 01 '协议ID'
 H120002   , -- 02 '细分资产ID'
 H120003   , -- 03 '机构ID'
 H120004   , -- 04 '调整日期'
 H120005   , -- 05 '当前五级分类'
 H120006   , -- 06 '原五级分类'
 H120007   , -- 07 '变动方式'
 H120008   , -- 08 '变动原因'
 H120009   , -- 09 '经办员工ID'
 H120010   , -- 10 '审查员工ID'
 H120011   , -- 11 '审批员工ID'
 H120012   , -- 12 '币种'
 H120013   , -- 13 '采集日期'
 H120014   , -- 14 '减值准备'
 DIS_DATA_DATE, -- 装入数据日期
 DIS_BANK_ID,   -- 机构号
 DEPARTMENT_ID  -- 业务条线
 )

WITH JZZB_TAB AS (
SELECT A.CONTRACT_NO ,SUM(NVL(PRIN_FINAL_RESLT,0)+NVL(OFBS_FINAL_RESLT,0)+NVL(INT_FINAL_RESLT,0)) AS JZZB
FROM SMTMODS.L_FINA_ASSET_DEVALUE T 
INNER JOIN YBT_DATACORE.INTM_CONTRACT_TRADE_DETAIL A
ON T.BIZ_NO=A.BUSINESS_ID
AND A.DATA_DATE =I_DATE
WHERE T.DATA_DATE =I_DATE
GROUP BY A.CONTRACT_NO
)
SELECT  
 H120001   , -- 01 '协议ID'
 H120002   , -- 02 '细分资产ID'
 H120003   , -- 03 '机构ID'
 H120004   , -- 04 '调整日期'
 SUBSTR (H120005,INSTR(H120005,'[',1,1) + 1 , INSTR(H120005, ']',1 ) -INSTR(H120005,'[',1,1) - 1 ) AS H120005   , -- 05 '当前五级分类'
 SUBSTR (H120006,INSTR(H120006,'[',1,1) + 1 , INSTR(H120006, ']',1 ) -INSTR(H120006,'[',1,1) - 1 ) AS H120006   , -- 06 '原五级分类'
 SUBSTR (H120007,INSTR(H120007,'[',1,1) + 1 , INSTR(H120007, ']',1 ) -INSTR(H120007,'[',1,1) - 1 ) AS H120007   , -- 07 '变动方式'
 H120008   , -- 08 '变动原因'
 H120009   , -- 09 '经办员工ID'
 H120010   , -- 10 '审查员工ID'
 H120011   , -- 11 '审批员工ID'
 SUBSTR (H120012,INSTR(H120012,'[',1,1) + 1 , INSTR(H120012, ']',1 ) -INSTR(H120012,'[',1,1) - 1 ) AS H120012   , -- 12 '币种'
 TO_CHAR(TO_DATE( '20240708','YYYYMMDD'),'YYYY-MM-DD') AS H120013   , -- 13 '采集日期'
 a.JZZB AS H120014   , -- 14 '减值准备'
 TO_CHAR(TO_DATE( '20240708','YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE, -- 15 '装入数据日期'
 '009806',   -- 16 '机构号'
 SUBSTR ( H120015,INSTR(H120015,'[',1,1) + 1 , INSTR(H120015, ']',1 ) -INSTR(H120015,'[',1,1) - 1 ) AS DEPARTMENT_ID       -- 业务条线
 FROM YBT_DATACORE.INTM_WJFLZT T
 LEFT JOIN JZZB_TAB a
 ON t.H120001 =a.CONTRACT_NO
 WHERE T.DATA_DATE= I_DATE; 
 COMMIT;
    CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);

 
    #5.过程结束执行
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '过程结束执行';
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    SET OI_RETCODE = P_STATUS; 
    SET OI_REMESSAGE = P_DESCB;
    select OI_RETCODE,'|',OI_REMESSAGE;
end $$

