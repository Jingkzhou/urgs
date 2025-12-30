DROP Procedure IF EXISTS `PROC_BSP_T_5_3_ZQCPYW` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_5_3_ZQCPYW"(IN I_DATE VARCHAR(8),
                                        OUT OI_RETCODE   INT,-- 返回code
                                        OUT OI_REMESSAGE VARCHAR -- 返回message
)
BEGIN

  /******
      程序名称  ：债券产品业务
      程序功能  ：加工债券产品业务
      目标表：T_2_1
      源表  ：
      创建人  ：87v
      创建日期  ：20240110
      版本号：V0.0.1 
  ******/
	 -- 20250520 吴大为老师邮寄通知修改 债券发行部分取数规则将兑付日期与到期日写为固定日期修改产品号与产品名称取值将产品唯一 修改人姜俐锋 
	 /* JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
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
	SET P_PROC_NAME = 'PROC_BSP_T_5_3_ZQCPYW';
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
	DELETE FROM T_5_3 WHERE E030033 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
    CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3插入债券投资数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '插入债券投资数据';
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
   INSERT  INTO T_5_3  (
      E030001 , -- 01  产品ID
      E030002 , -- 02  机构ID
      E030003 , -- 03  产品名称
      E030004 , -- 04  产品编号
      E030005 , -- 05  债券产品业务类型
      E030006 , -- 06  债券类型代码
      E030007 , -- 07  债券子类型代码
      E030008 , -- 08  票面金额
      E030009 , -- 09  债券期次
      E030010 , -- 10  发行规模
      E030011 , -- 11  债券发行人统一社会信用代码
      E030012 , -- 12  债券发行人名称
      E030013 , -- 13  定期付息账号
      E030014 , -- 14  可回购标识
      E030015 , -- 15  可提前偿还标识
      E030016 , -- 16  发行价格
      E030017 , -- 17  赎回价格
      E030018 , -- 18  发行国家地区
      E030019 , -- 19  担保机构国家地区
      E030020 , -- 20  债券发行机构类型
      E030021 , -- 21  担保机构类型
      E030022 , -- 22  发行方式
      E030023 , -- 23  发行人所在省  --2.0发行人所在地行政区划
      E030024 , -- 24  发行资金用途
      E030025 , -- 25  资产风险权重
      E030026 , -- 26  资产等级
      E030027 , -- 27  主权风险权重
      E030028 , -- 28  基准国债收益率
      E030029 , -- 29  交易方式代码
      E030030 , -- 30  发行日期
      E030031 , -- 31  到期兑付日期
      E030032 , -- 32  备注
      E030033 , -- 33  采集日期
      DIS_DATA_DATE , -- 装入数据日期
      DIS_BANK_ID ,   -- 机构号
      DIS_DEPT,
      DEPARTMENT_ID , -- 业务条线
      E030034         -- 34  币种
       )
     SELECT 
        T1.STOCK_CD                           , -- 01 产品ID
		ORG.ORG_ID                            , -- 02  机构ID
		T1.STOCK_NAM                          , -- 03  产品名称
		T1.STOCK_CD                           , -- 04  产品编号
		case 
		  when T1.STOCK_PRO_TYPE like 'A%' then '01' -- 政府债券
		  when T1.STOCK_PRO_TYPE like 'B%' then '02' -- 中央银行票据
		  when T1.STOCK_PRO_TYPE like 'C%' then '04' -- 金融债券
		  when T1.STOCK_PRO_TYPE like 'D%' then '05' -- 企业信用债券
		 -- when T1.STOCK_PRO_TYPE like 'F%' then '06' -- 资产支持证券
		  when T1.STOCK_PRO_TYPE like 'F%' then '07' -- 外国债券
		END                                   , -- 05  债券产品业务类型
        case 
          when T1.CJZQBS = 'Y'  then '02' -- 02-次级债券
		  when T1.FXZJYT = '01' then '01' -- 01-普通债券
		  when T1.FXZJYT = '02' then '03' -- 03-专项债券
		end                                   , -- 06  债券类型代码
		CASE
		  WHEN T1.STOCK_PRO_TYPE = 'A' AND T1.ISSU_ORG = 'A01' THEN '01' -- 01-国债
		  WHEN T1.STOCK_PRO_TYPE = 'A' AND T1.ISSU_ORG = 'A02' THEN '02' -- 02-地方政府债
		  WHEN T1.STOCK_PRO_TYPE='B' THEN '03' -- 中软产品逻辑
		  WHEN T1.STOCK_PRO_TYPE LIKE 'C%' AND T1.ISSU_ORG = 'D02' THEN '06' -- 06-政策性金融债券
		  WHEN T1.ISSU_ORG='D03' THEN '07'
		  WHEN T1.ISSU_ORG IN('D04','D05','D06','D07') AND T1.STOCK_PRO_TYPE LIKE 'C%' THEN '08'
		  WHEN T1.STOCK_PRO_TYPE = 'D04' AND SUBSTR(T1.STOCK_PRO_TYPE, 1, 1) = 'D' AND T1.ISSU_ORG LIKE 'C%' THEN '09'
		  WHEN T1.STOCK_PRO_TYPE='D01' THEN '10'
		  WHEN T1.STOCK_PRO_TYPE='D02' THEN '11'
		  WHEN T1.STOCK_PRO_TYPE ='D03' THEN '12'
		  WHEN T1.STOCK_PRO_EXP_TYPE='D07' THEN '13' -- 中软产品逻辑
		  WHEN T1.STOCK_PRO_TYPE = 'D05'   AND SUBSTR(T1.STOCK_PRO_TYPE, 1, 1) = 'D' AND T1.ISSU_ORG LIKE 'C%'  THEN '14'
		  WHEN T1.STOCK_PRO_EXP_TYPE='C01' THEN '15' -- 中软产品逻辑
		  WHEN T1.STOCK_PRO_TYPE ='D99' THEN '16' -- 中软产品逻辑
		  WHEN T1.STOCK_PRO_TYPE ='F03' THEN '17' -- 中软产品逻辑
		  WHEN T1.STOCK_PRO_EXP_TYPE='F01' THEN '18' -- 中软产品逻辑
		  WHEN T1.STOCK_PRO_EXP_TYPE='F02' THEN '19' -- 中软产品逻辑
		  WHEN T1.STOCK_PRO_TYPE LIKE 'F%' AND T1.ISSUER_INLAND_FLG = 'N' THEN '20'
          ELSE '22'
		END                                   , -- 07  债券子类型代码
		T1.BOND_VALUE    ,                    -- 08  票面金额
		T1.ZQQC                               ,  -- 09  债券期次
		replace(T1.ISSUE_AMOUNT  ,',','')                      , -- 10  发行规模
		T2.INITIAL_ID_NO                      , -- 11  债券发行人统一社会信用代码
		T2.ISSUER_CUST_ID                     , -- 12  债券发行人名称
		null                                  , -- 13  定期付息账号 -- 默认为空
		T1.KHGBS                              , -- 14  可回购标识 -- 新增字段
		T1.KTQCHBS                            , -- 15  可提前偿还标识 -- 新增字段
		T1.ISSUER_PRICE                       , -- 16  发行价格
		T1.SHJG                               , -- 17  赎回价格
		'CHN'                                 , -- 18  发行国家地区 -- 默认中国
	    -- 'CHN'                                 , -- 19  担保机构国家地区 -- 默认中国
		T2.GUAR_NATION_CD                     , -- 19  担保机构国家地区  -- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐
		case 		
		  when T1.ISSU_ORG like 'A%' then '01' -- 主权国家
		  when T1.ISSU_ORG like 'B%' then '03' -- 公共部门实体
		  when T1.ISSU_ORG like 'C%' then '05' -- 非金融公司
		  when T1.ISSU_ORG like 'D%' then '06' -- 金融机构
		  when T1.ISSU_ORG like 'E%' then '04' -- 其他机构
		END                                   , -- 20  债券发行机构类型
		T2.GUAR_ORG_TYPE                      , -- 21  担保机构类型  -- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐
		case 		
		  when T1.BOND_ISSUE_TYPE = 'A' then '02' -- 定向承销
		  when T1.BOND_ISSUE_TYPE = 'B' then '01' -- 公开发行
		end                                   , -- 22  发行方式
		t2.INITIAL_AREA_CD                    , -- 23  发行人所在省  --2.0发行人所在地行政区划
		T1.FXZJYT                             , -- 24  发行资金用途 -- 新增字段
		NVL(R.RW,R2.RW)                       , -- 25  资产风险权重  -- 20250116_zhoulp_JLBA202408290021_金市需求二阶段_业务姚司桐
		-- T1.ZCDJ                               , -- 26  资产等级 -- 新增字段
        CASE
		  WHEN (T1.STOCK_PRO_TYPE = 'A' AND T1.ISSU_ORG = 'A01') OR-- 01-国债
             (T1.STOCK_PRO_TYPE LIKE 'C%' AND T1.ISSU_ORG = 'D02') OR-- 06-政策性金融债券
              T1.STOCK_CD IN ('032000573', '032001060') 
 		    THEN '01'  -- 一级资产  -- 国债和政策性银行债是一级资产
		  WHEN (T1.STOCK_PRO_TYPE = 'A' AND T1.ISSU_ORG = 'A02') OR-- 02-地方政府债      
		     (T1.APPRAISE_TYPE IN('1','2','3','4') AND T1.STOCK_PRO_TYPE IN('D01','D02','D04','D05')) 
		    THEN '02'   -- 2A资产   -- 地方政府债 和 信用评级大于等于2A的超短期融资券、短期融资券、公司债、中期债是2A资产
		  WHEN T1.APPRAISE_TYPE IN('5','6','7','8','9','A','B') AND T1.STOCK_PRO_TYPE IN('D01','D02','D04','D05')
		    THEN '03'   -- 2B资产   -- 信用评级小于2A的超短期融资券、短期融资券、公司债、中期债是2B资产
        END                                   , -- 26  资产等级
		
		-- T1.RISK_WEIGHT                        , -- 27  主权风险权重
		'02'                                  , -- 27  主权风险权重 -- 默认02 20%
		T5.AVG_YLD                            , -- 28  基准国债收益率  -- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐
		'01;02;03'                            , -- 29  交易方式代码 -- 默认01;02;03
		TO_CHAR(TO_DATE(T1.ISSU_DT,'YYYYMMDD'),'YYYY-MM-DD'), -- 30  发行日期
		TO_CHAR(TO_DATE(T1.CASH_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 31  到期兑付日期
		''                                    , -- 32  备注
		TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 33  采集日期
		TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
		T1.ORG_NUM                                      , -- 机构号
		null,
		'009804'                                        , -- 金融市场部
		T1.CURR_CD                                        -- 34  币种
    FROM SMTMODS.L_AGRE_BOND_INFO T1   -- 债券信息表
      LEFT JOIN SMTMODS.L_AGRE_BONDISSUER_INFO T2  -- 债券发行人信息表
        on T1.STOCK_CD = T2.STOCK_CD 
        and T2.DATA_DATE = I_DATE
      LEFT JOIN (select ACCT_NUM,max(maturity_date) maturity_date,max(FACE_VAL) FACE_VAL from 
                   SMTMODS.L_ACCT_FUND_INVEST where DATA_DATE = I_DATE group by ACCT_NUM) T3  -- 投资业务信息表
        ON T3.ACCT_NUM = T1.STOCK_CD
      /*LEFT JOIN (SELECT A.SUBJECT_CD,MAX(B.END_DT) END_DT,MAX(B.BALANCE) BALANCE FROM SMTMODS.L_AGRE_REPURCHASE_GUARANTY_INFO A -- 回购抵质押物详细信息
                   inner join SMTMODS.L_ACCT_FUND_REPURCHASE B -- 回购信息表
                     on A.ACCT_NUM=B.ACCT_NUM and B.DATA_DATE=I_DATE
                 WHERE A.DATA_DATE=I_DATE group by A.SUBJECT_CD) T4 -- 回购
        ON T4.SUBJECT_CD = T1.STOCK_CD*/
        
      -- 20250116_zhoulp_JLBA202408290021_金市需求二阶段_业务姚司桐  -- 重新改这个逻辑是为了取到任意一笔回购流水，用作关联资本新规取权重。 -- 金市刘洋：多笔回购对应一笔债券的情况，权重是债券级的。
      LEFT JOIN (SELECT A.SUBJECT_CD,MAX(B.REF_NUM) REF_NUM -- 取唯一避免一个债券对应多个回购的情况
                 FROM SMTMODS.L_AGRE_REPURCHASE_GUARANTY_INFO A -- 回购抵质押物详细信息
                   inner join SMTMODS.L_ACCT_FUND_REPURCHASE B -- 回购信息表
                     on A.ACCT_NUM=B.ACCT_NUM and B.DATA_DATE=I_DATE
                 WHERE A.DATA_DATE=I_DATE and (B.BALANCE > 0 or (B.END_DT = I_DATE and B.BALANCE = 0))
                 group by A.SUBJECT_CD) T4 -- 回购
        ON T4.SUBJECT_CD = T1.STOCK_CD
        
      LEFT JOIN (-- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐
        SELECT A.STOCK_CD, AVG(A.YLD) AS AVG_YLD
          FROM (SELECT T1.STOCK_CD,
               C.YLD,
               C.STATE_DATE,
               ROW_NUMBER() OVER(PARTITION BY T1.STOCK_CD ORDER BY C.STATE_DATE DESC) RN
          FROM SMTMODS.L_AGRE_BOND_INFO T1 -- 债券信息表
         INNER JOIN (select C.*,
                           row_number() OVER(partition by STATE_DATE, MTRTY order by DATA_DATE DESC) RN
                      from SMTMODS.JTDP_INTERF_PAYHSRCCASHYIELD C
                     where CURVE_NAME LIKE '%中债国债收益率曲线%'
                       AND CURVE_TYPE = '02' -- 01-即期 02-到期
                       AND C.STATE_DATE < I_DATE) C
            ON C.RN = 1
           and (CASE -- 参照G1803业务老师要求按365天计算，如果此处想改成一年可以用 TIMESTAMPDIFF(MONTH,'2013-04-02','2018-03-02')函数
                 WHEN (TO_DATE(MATURITY_DT, 'YYYYMMDD') -
                      TO_DATE(I_DATE, 'YYYYMMDD')) / 365 < 1 THEN
                  ROUND((TO_DATE(MATURITY_DT, 'YYYYMMDD') -
                        TO_DATE(I_DATE, 'YYYYMMDD')) / 365,
                        2)
                 ELSE
                  ROUND((TO_DATE(MATURITY_DT, 'YYYYMMDD') -
                        TO_DATE(I_DATE, 'YYYYMMDD')) / 365,
                        0)
               END = C.MTRTY)
         WHERE T1.DATA_DATE = I_DATE) A
         WHERE A.RN <= 5
         GROUP BY A.STOCK_CD
      )T5
        ON T1.STOCK_CD=T5.STOCK_CD
      left join (  -- 20250116_zhoulp_JLBA202408290021_金市需求二阶段_业务姚司桐  -- 债券
        select LOAN_REF_NO,RW,row_number() OVER(partition by LOAN_REF_NO order by RW) RN from -- 刘名赫确认一个债对应一个权重，所以取任意一条即可
        (select REPLACE(case when INSTR(LOAN_REF_NO,'-')-1 <0 then LOAN_REF_NO else SUBSTR(LOAN_REF_NO,1,INSTR(LOAN_REF_NO,'-')-1) end,'bd_','') LOAN_REF_NO,RW 
          from smtmods.MR_SA_RWA_RESULT where DATA_DATE = cast(I_DATE as date)-1 and ACCORG_NO='009804')R
          ) R on R.RN = 1 and REPLACE(T1.STOCK_CD,'bd_','') = REPLACE(R.LOAN_REF_NO,'bd_','')
          
      left join (  -- 20250116_zhoulp_JLBA202408290021_金市需求二阶段_业务姚司桐  -- 回购
        select LOAN_REF_NO,RW,row_number() OVER(partition by LOAN_REF_NO order by RW) RN from -- 刘名赫确认一个债对应一个权重，所以取任意一条即可
        (select REPLACE(case when INSTR(LOAN_REF_NO,'-')-1 <0 then LOAN_REF_NO else SUBSTR(LOAN_REF_NO,1,INSTR(LOAN_REF_NO,'-')-1) end,'bd_','') LOAN_REF_NO,RW 
          from smtmods.MR_SA_RWA_RESULT where DATA_DATE = cast(I_DATE as date)-1 and ACCORG_NO='009804')R
          ) R2 on R2.RN = 1 and R.LOAN_REF_NO is null and T4.REF_NUM=R2.LOAN_REF_NO

      LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
        ON T1.ORG_NUM = ORG.ORG_NUM
        AND ORG.DATA_DATE = I_DATE
     WHERE T1.DATA_DATE = I_DATE
	    -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
        AND ((T3.FACE_VAL > 0 or (T3.maturity_date >= SUBSTR(I_DATE,1,4)||'0101' and T3.FACE_VAL = 0)) OR
            -- (T4.BALANCE > 0 or (T4.END_DT = I_DATE and BALANCE = 0))) -- 有票面金额或当天结清
            T4.SUBJECT_CD is not NULL) -- 有票面金额或当天结清
     ;

     #插入债发行数据  -- 一笔  901686
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '插入债发行数据';
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
   INSERT  INTO T_5_3  (
      E030001 , -- 01  产品ID
      E030002 , -- 02  机构ID
      E030003 , -- 03  产品名称
      E030004 , -- 04  产品编号
      E030005 , -- 05  债券产品业务类型
      E030006 , -- 06  债券类型代码
      E030007 , -- 07  债券子类型代码
      E030008 , -- 08  票面金额
      E030009 , -- 09  债券期次
      E030010 , -- 10  发行规模
      E030011 , -- 11  债券发行人统一社会信用代码
      E030012 , -- 12  债券发行人名称
      E030013 , -- 13  定期付息账号
      E030014 , -- 14  可回购标识
      E030015 , -- 15  可提前偿还标识
      E030016 , -- 16  发行价格
      E030017 , -- 17  赎回价格
      E030018 , -- 18  发行国家地区
      E030019 , -- 19  担保机构国家地区
      E030020 , -- 20  债券发行机构类型
      E030021 , -- 21  担保机构类型
      E030022 , -- 22  发行方式
      E030023 , -- 23  发行人所在省 --2.0发行人所在地行政区划
      E030024 , -- 24  发行资金用途
      E030025 , -- 25  资产风险权重
      E030026 , -- 26  资产等级
      E030027 , -- 27  主权风险权重
      E030028 , -- 28  基准国债收益率
      E030029 , -- 29  交易方式代码
      E030030 , -- 30  发行日期
      E030031 , -- 31  到期兑付日期
      E030032 , -- 32  备注
      E030033 , -- 33  采集日期
      DIS_DATA_DATE , -- 装入数据日期
      DIS_BANK_ID ,   -- 机构号
      DIS_DEPT,
      DEPARTMENT_ID,  -- 业务条线
      E030034   -- 34  币种
       )
        -- 20250520 吴大为老师邮寄通知修改 债券发行部分取数规则将兑付日期与到期日写为固定日期修改产品号与产品名称取值将产品唯一 修改人姜俐锋 
     SELECT 
        DISTINCT 
        T.SUBJECT_CD                           , -- 01 产品ID
		ORG.ORG_ID                             , -- 02  机构ID
		A.CPMC                                 , -- 03  产品名称
		T.SUBJECT_CD                           , -- 04  产品编号
		'04'                                   , -- 05  债券产品业务类型 -- 金融债券
		'02'                                   , -- 06  债券类型代码
		'07'                                   , -- 07  债券子类型代码  07-商业银行债券
		-- T.FACE_VAL    ,                    -- 08  票面金额
		100,                    -- 08  票面金额 --业务老师桑铭蔚
		-- T1.ZQQC                               ,  -- 09  债券期次
		null                                   ,  -- 09  债券期次
		-- replace(T1.ISSUE_AMOUNT  ,',','')                      , -- 10  发行规模
		null, -- 10  发行规模
		'9122010170255776XN'                   , -- 11  债券发行人统一社会信用代码
		'吉林银行股份有限公司'                  , -- 12  债券发行人名称
		'9019827201000055'                                  , -- 13  定期付息账号 -- 金融市场部提供
		null                                   , -- 14  可回购标识 -- 新增字段
		null                                   , -- 15  可提前偿还标识 -- 新增字段
		-- T.BOND_FACE_VALUE                       , -- 16  发行价格
		100                                    , -- 16  发行价格 --业务老师桑铭蔚
		null                                   , -- 17  赎回价格
		'CHN'                                  , -- 18  发行国家地区 -- 默认中国
	    -- 'CHN'                                 , -- 19  担保机构国家地区 -- 默认中国
		''                                     , -- 19  担保机构国家地区 -- 默认中国 --需要判断一下，21  担保机构类型不为空的时候再默认中国，否则为空
		'06'                                   , -- 20  债券发行机构类型 -- 金融机构
		''                                     , -- 21  担保机构类型
		'01'                                   , -- 22  发行方式
		'220102'                               , -- 23  发行人所在省  --2.0发行人所在地行政区划
		'01'                                   , -- 24  发行资金用途 -- 新增字段
		null                                   , -- 25  资产风险权重
		-- T1.ZCDJ                               , -- 26  资产等级 -- 新增字段
        null                                   , -- 26  资产等级
		
		-- T1.RISK_WEIGHT                        , -- 27  主权风险权重
		null                                   , -- 27  主权风险权重 -- 默认为空
		null                                   , -- 28  基准国债收益率 -- 默认为空
		-- '01;02;03'                            , -- 29  交易方式代码 -- 默认01;02;03
		'01'                                   , -- 29  交易方式代码
		'2021-12-10'                           , -- 30  发行日期 INT_ST_DT
		'9999-12-31'                           , -- 31  到期兑付日期MATURITY_DATE
		''                                     , -- 32  备注
		TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 33  采集日期
		TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
		T.ORG_NUM                                      , -- 机构号
		null,
		'009804'                                       , -- 金融市场部
		T.CURR_CD                                       -- 34  币种
     FROM SMTMODS.L_ACCT_FUND_BOND_ISSUE T
     LEFT JOIN  SMTMODS.L_BASIC_PRODUCT A
       ON T.SUBJECT_CD=A.CP_ID
      AND A.DATA_DATE= I_DATE
     LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
       ON T.ORG_NUM = ORG.ORG_NUM
      AND ORG.DATA_DATE = I_DATE
    WHERE T.DATA_DATE = I_DATE
      AND T.GL_ITEM_CODE = '25020101'
	  -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
      AND (T.FACE_VAL > 0 or (T.FACE_VAL = 0 and T.MATURITY_DATE >= SUBSTR(I_DATE,1,4)||'0101')) -- 有票面金额或当天结清
   ;

    #4.过程结束执行
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '过程结束执行';
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
   SET OI_RETCODE = P_STATUS; 
   SET OI_REMESSAGE = P_DESCB;
   select OI_RETCODE,'|',OI_REMESSAGE;
END $$


