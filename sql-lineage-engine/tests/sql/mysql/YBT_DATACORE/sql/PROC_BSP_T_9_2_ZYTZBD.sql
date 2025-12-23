DROP Procedure IF EXISTS `PROC_BSP_T_9_2_ZYTZBD` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_9_2_ZYTZBD"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN
/******
      程序名称  ：自营投资标的
      程序功能  ：加工自营投资标的
      目标表：T_9_2
      源表  ：vv
      创建人  ：LZ
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
-- JLBA202409290003 关于一表通校验结果治理的需求（同业金融部） 20241212
-- JLBA202412200001_关于一表通监管数据报送系统修改逻辑及转EAST脚本的需求_20250116
-- JLBA202412300003_关于一表通监管报送系统(同业金融部)分户账信息表等字段取值逻辑变更的需求_20250213
-- JLBA202501240018_关于一表通监管数据报送系统变更的需求_20250311
-- 需求编号：JLBA202503050025 上线日期：2025-03-27，修改人：巴启威，提出人：陈聪,吴大为
--         修改原因：'存放同业活期'和'同业存放活期'两个业务对应的'发行价格'和'发行规模'，取对应账户 最早一笔的入账金额，如果取不到交易则都默认为 1
  /* 需求编号：JLBA202502210009 上线日期：20250415，修改人：姜俐锋，提出人：吴大为 */
	 -- [20250422] [姜俐锋] [回购业务增加判断发行机构大类&小类 与投资业务 判断条件同步
-- 需求编号：JLBA202504070013 上线日期：2025-05-13，修改人：巴启威，提出人：陈聪
--         修改原因：同业现取数全部业务,取对应账户 最早一笔的入账金额，如果取不到交易则都默认为 1	 
-- 需求编号：JLBA202505280002 上线日期：2025-06-19，修改人：巴启威  提出人：吴大为  修改原因：因一表通校验问题发现的代码逻辑调整
/*需求编号：JLBA202505270010   上线日期：20250729，修改人：姜俐锋，提出人：吴大为 关于一表通监管数据报送系统新增投资业务指标的需求*/
 /*需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
  #声明变量
  DECLARE P_DATE     DATE; #数据日期
  DECLARE P_PROC_NAME   VARCHAR(200); #存储过程名称
  DECLARE P_STATUS   INT;   #执行状态
  DECLARE P_START_DT   DATETIME; #日志开始日期
  DECLARE P_END_TIME   DATETIME; #日志结束日期
  DECLARE P_SQLCDE  VARCHAR(200); #日志错误代码
  DECLARE P_STATE   VARCHAR(200); #日志状态代码
  DECLARE P_SQLMSG  VARCHAR(2000); #日志详细信息
  DECLARE P_STEP_NO    INT; #日志执行步骤
  DECLARE P_DESCB   VARCHAR(200); #日志执行步骤描述
  DECLARE BEG_MON_DT  VARCHAR(8); #月初
  DECLARE BEG_QUAR_DT  VARCHAR(8); #季初
  DECLARE BEG_YEAR_DT  VARCHAR(8); #年初
  DECLARE LAST_MON_DT   VARCHAR(8); #上月末
  DECLARE LAST_QUAR_DT  VARCHAR(8); #上季末
  DECLARE LAST_YEAR_DT  VARCHAR(8); #上年末
  DECLARE LAST_DT   VARCHAR(8); #上日
  DECLARE FINISH_FLG    VARCHAR(8); #完成标志  
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
 SET P_PROC_NAME = 'PROC_BSP_T_9_2_ZYTZBD';
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
 
 DELETE FROM T_9_2 WHERE J020105 = to_char(P_DATE,'yyyy-mm-dd'); 
 CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
 SET P_START_DT = NOW();
 SET P_STEP_NO = P_STEP_NO + 1;
 SET P_DESCB = '数据插入';


  -- 金融市场部  （1现券 2回购 3债券借贷 4拆借）
  -- 同业金融部 （1借入、借出   2存放同业活期、存放同业定期 3同业存单发行 4同业存单投资 5公募基金、私募、信托、资管、理财 ）
  -- 现券  和 公募基金、私募、信托、资管、理财------非标投资唯一  现券不唯一
INSERT  INTO T_9_2  (
   J020001,   -- 001.投资标的      
   J020002,   -- 002.投资标的名称
   J020003,   -- 003.机构
   J020004,   -- 004.发行价格
   J020005,   -- 005.发行规模
   J020006,   -- 006.发行机构名称
   J020007,   -- 007.发行机构代码
   J020008,   -- 008.发行机构大类
   J020107,   -- 107.发行机构小类
   J020009,   -- 009.发行国家地区
   J020108,   -- 108.交易流通场所
   J020010,   -- 010.投资标的币种
   J020011,   -- 011.投资标的代码
   J020014,   -- 014.起息日期
   J020015,   -- 015.发行日期
   J020016,   -- 016.到期日期
   J020017,   -- 017.投资标的利率类型
   J020018,   -- 018.利率/收益率
   J020019,   -- 019.最近评估价格
   J020020,   -- 020.评估价格日期
   J020021,   -- 021.投融资标的类别
   J020022,   -- 022.资产风险权重
   J020026,   -- 026.基础资产客户名称
   J020027,   -- 027.基础资产客户国家
   J020028,   -- 028.基础资产客户评级
   J020029,   -- 029.基础资产客户评级机构
   J020030,   -- 030.基础资产客户行业类型
   J020031,   -- 031.基础资产外部评级
   J020032,   -- 032.基础资产评级机构
   J020109,   -- 109.基础资产内部评级
   J020033,   -- 033.基础资产最终投向类型
   J020034,   -- 034.基础资产最终投向行业类型
   J020087,   -- 087.含权类型
   J020103,   -- 103.存在变现障碍标识
   J020104,   -- 104.备注
   J020105,   -- 105.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID ,    -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID,
   J020106,   -- 106.是否投向市场化债转股相关产品
   J020110,   -- 110.是否投向产业基金
   J020111    -- 111.被持有股权企业客户ID
) 
select 
   J020001,   -- 001.投资标的
   J020002,   -- 002.投资标的名称
   J020003,   -- 003.机构
   J020004,   -- 004.发行价格
   J020005,   -- 005.发行规模
   J020006,   -- 006.发行机构名称
   J020007,   -- 007.发行机构代码
   J020008,   -- 008.发行机构大类
   J020107,   -- 107.发行机构小类
   J020009,   -- 009.发行国家地区
   J020108,   -- 108.交易流通场所
   J020010,   -- 010.投资标的币种
   J020011,   -- 011.投资标的代码
   J020014,   -- 014.起息日期
   J020015,   -- 015.发行日期
   J020016,   -- 016.到期日期
   J020017,   -- 017.投资标的利率类型
   J020018,   -- 018.利率/收益率
   J020019,   -- 019.最近评估价格
   J020020,   -- 020.评估价格日期
   J020021,   -- 021.投融资标的类别
   J020022,   -- 022.资产风险权重
   J020026,   -- 026.基础资产客户名称
   J020027,   -- 027.基础资产客户国家
   J020028,   -- 028.基础资产客户评级
   J020029,   -- 029.基础资产客户评级机构
   J020030,   -- 030.基础资产客户行业类型
   J020031,   -- 031.基础资产外部评级
   J020032,   -- 032.基础资产评级机构
   J020109,   -- 109.基础资产内部评级
   J020033,   -- 033.基础资产最终投向类型
   J020034,   -- 034.基础资产最终投向行业类型
   J020087,   -- 087.含权类型
   J020103,   -- 103.存在变现障碍标识
   J020104,   -- 104.备注
   J020105,   -- 105.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID ,    -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID,
   J020106,   -- 106.是否投向市场化债转股相关产品
   J020110,   -- 110.是否投向产业基金
   J020111    -- 111.被持有股权企业客户ID
from (select 
t.SUBJECT_CD as J020001,-- 001.投资标的  
nvl(t1.STOCK_NAM,t2.SUBJECT_NAM)  as J020002,-- 002.投资标的名称
ORG.ORG_ID as J020003,-- -- 003.机构
nvl(t1.ISSUER_PRICE,t2.ISSUER_PRICE)  as J020004,-- 004.发行价格
nvl(t1.ISSUE_AMOUNT*100000000,t2.PROCEEDS_NUM)  as J020005, -- 005.发行规模
nvl(t1.ISSU_ORG_NAM,t2.ISSU_ORG_NAM)  as J020006,-- 006.发行机构名称
nvl(T1.INITIAL_ID_NO,T2.ISSUER_ID_NO) as J020007, -- 007.发行机构代码 20241212
-- 20241024_zhoulp_JLBA202409030008_交易对手大类小类
case when m1.GB_CODE  is not null then m1.GB_CODE
     when nvl(t1.ISSU_ORG_NAM,t2.ISSU_ORG_NAM) like '%银行%' then '01' -- [20250619][巴启威][JLBA202505280002][吴大为]：发行机构大类增加名称映射。'%银行%' 映射成对应码值01
     when nvl(t1.ISSU_ORG_NAM,t2.ISSU_ORG_NAM) like '%财政部%' then '09'
     when nvl(t1.ISSU_ORG_NAM,t2.ISSU_ORG_NAM) like '%政府%'   then '09'
     when nvl(t1.ISSU_ORG_NAM,t2.ISSU_ORG_NAM) like '%财政厅%' then '09'
     when nvl(t1.ISSU_ORG_NAM,t2.ISSU_ORG_NAM) like '%财政局%' then '09'
     when nvl(t1.ISSU_ORG_NAM,t2.ISSU_ORG_NAM) like '%理财%公司%' then '01'
     when ce.corp_propty in ('0805010100','0805010200') then '10' -- 国有企业
     when ce.corp_propty in ('0805040000') then '10' -- 集体企业
     when ce.corp_propty in ('0805060000') then '10' -- 其他企业
     when ce.corp_propty in ('0805030100') then '10' -- 中外合资企业
     when nvl(t1.ISSU_ORG_NAM,t2.ISSU_ORG_NAM) like '%有限责任公司%' then '10'
     when nvl(t1.ISSU_ORG_NAM,t2.ISSU_ORG_NAM) like '%股份有限公司%' then '10'
     when nvl(t1.ISSU_ORG_NAM,t2.ISSU_ORG_NAM) like '%基金%' then '06'
     when nvl(t1.ISSU_ORG_NAM,t2.ISSU_ORG_NAM) like '%集团有限公司%' then '10'
     when nvl(t1.ISSU_ORG_NAM,t2.ISSU_ORG_NAM) like '%有限公司%' then '10'
end as J020008, -- 008.发行机构大类
case when m2.GB_CODE  is not null then m2.GB_CODE
     when nvl(t1.ISSU_ORG_NAM,t2.ISSU_ORG_NAM) like '%财政部%' then '090501'
     when nvl(t1.ISSU_ORG_NAM,t2.ISSU_ORG_NAM) like '%政府%'   then '090601'
     when nvl(t1.ISSU_ORG_NAM,t2.ISSU_ORG_NAM) like '%财政厅%' then '090601'
     when nvl(t1.ISSU_ORG_NAM,t2.ISSU_ORG_NAM) like '%财政局%' then '090601'
     when nvl(t1.ISSU_ORG_NAM,t2.ISSU_ORG_NAM) like '%理财%公司%' then '010908'
     when ce.corp_propty in ('0805010100','0805010200') then '100101' -- 国有企业
     when ce.corp_propty in ('0805040000') then '100102' -- 集体企业
     when ce.corp_propty in ('0805060000') then '100108' -- 其他企业
     when ce.corp_propty in ('0805030100') then '100301' -- 中外合资企业
     when nvl(t1.ISSU_ORG_NAM,t2.ISSU_ORG_NAM) like '%有限责任公司%' then '100105'
     when nvl(t1.ISSU_ORG_NAM,t2.ISSU_ORG_NAM) like '%股份有限公司%' then '100106'
     when nvl(t1.ISSU_ORG_NAM,t2.ISSU_ORG_NAM) like '%基金%' then '060201'
     when nvl(t1.ISSU_ORG_NAM,t2.ISSU_ORG_NAM) like '%集团有限公司%' then '100102'
     when nvl(t1.ISSU_ORG_NAM,t2.ISSU_ORG_NAM) like '%有限公司%' then '100105'
end as J020107, -- 107.发行机构小类
'CHN' as J020009, -- 009.发行国家地区
null as J020108 , -- 108.交易流通场所
nvl(t1.CURR_CD,t2.CURR_CD) as J020010 ,-- 010.投资标的币种
t.SUBJECT_CD as J020011, -- 011.投资标的代码
nvl(TO_CHAR(TO_DATE(t1.INT_ST_DT,'YYYYMMDD'),'YYYY-MM-DD'),TO_CHAR(TO_DATE(t2.INT_ST_DT,'YYYYMMDD'),'YYYY-MM-DD'))  as J020014,-- 014.起息日期
nvl(TO_CHAR(TO_DATE( t1.ISSU_DT,'YYYYMMDD'),'YYYY-MM-DD'),TO_CHAR(TO_DATE( t2.ISSU_DT,'YYYYMMDD'),'YYYY-MM-DD'))  as J020015 ,-- 015.发行日期
nvl(TO_CHAR(TO_DATE( t1.MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD'),TO_CHAR(TO_DATE( t2.MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD'))  as J020016 ,-- 016.到期日期
'02' as J020017,-- 017.投资标的利率类型   康星无法判断是否是LPR  -- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐  -- 同业常城同意默认02；金市此需求文档标注默认02
nvl(t1.INT_RAT,t2.INT_RAT)   as  J020018,-- 018.利率/收益率
nvl(t1.CURRENT_EVALUATE_PRICE,t2.CURRENT_EVALUATE_PRICE) as J020019,-- 019.最近评估价格 加字段
nvl(TO_CHAR(TO_DATE( t2.EVALUATE_DT,'YYYYMMDD'),'YYYY-MM-DD'),TO_CHAR(TO_DATE( t1.EVALUATE_DT,'YYYYMMDD'),'YYYY-MM-DD')) as J020020,-- 020.评估价格日期 加字段
case when T1.STOCK_PRO_TYPE='B' then '0300'
     when T1.STOCK_PRO_TYPE='D04' then '0340'
     when T1.STOCK_PRO_TYPE='D05' then '0350'
     when T1.STOCK_PRO_TYPE in (/*'D02',*/ 'D99') then '0350'
     when T1.STOCK_PRO_TYPE='C060401' then '0540'
     when T1.STOCK_PRO_TYPE='C0101' then '0550'
     when T1.STOCK_PRO_TYPE='A' and T1.ISSU_ORG='A01' then '0270'
     when T1.STOCK_PRO_TYPE='A' and T1.ISSU_ORG='A02' then '0280'
     when SUBSTR(T1.STOCK_PRO_TYPE,1,1)='C' then
       case 
         when t1.STOCK_NAM like '%农发%' or   -- 2.0zdsj h
              t1.STOCK_NAM like '%进出%' or   -- 2.0zdsj h
              t1.STOCK_NAM like '%国开%'      -- 2.0zdsj h
         then '0310' else '0330' 
       end
     when T1.STOCK_PRO_TYPE in ('D01','D02') then '0360'    
     when t2.SUBJECT_PRO_TYPE ='0604' then '0640'  -- 2.0 zdsj h
     when t2.SUBJECT_PRO_TYPE ='0605' then '0650'
     when t2.SUBJECT_PRO_TYPE ='0103' then '0480'  -- 2.0 zdsj h 
     when t2.SUBJECT_PRO_TYPE ='04' then '0630'  -- 2.0 zdsj h 
     when t2.SUBJECT_PRO_TYPE ='0102' then '0470'  -- 2.0 zdsj h 
     when t2.SUBJECT_PRO_TYPE ='0799' then '0880'  -- 2.0 zdsj h 
     when t2.SUBJECT_PRO_TYPE='99' then '0880'
     end as J020021 , -- 待映射-- 021.投融资标的类别
null as J020022 ,-- 022.资产风险权重 找RWA系统。
t1.ISSU_ORG_NAM as J020026, -- 026.基础资产客户名称
'CHN'  as J020027,-- 027.基础资产客户国家      -- 2.0 zdsj h
case when t1.ISSUER_LEV='A' then 'AA-以上（含AA-）'
     when t1.ISSUER_LEV='B' then 'A+ 至 BBB-（含BBB-）'
     when t1.ISSUER_LEV='C' then 'BB+ 至 B-（含B-）'
     when t1.ISSUER_LEV='D' then 'B-以下' 
     when t1.ISSUER_LEV='E' then '' end as J020028,-- 028.基础资产客户评级
t1.LEV_ORG as J020029,-- 029.基础资产客户评级机构
m3.GB_CODE as J020030,-- 030.基础资产客户行业类型  -- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐
case when t1.APPRAISE_TYPE='1' then 'AAA级'
     when t1.APPRAISE_TYPE='2' then 'AA+'
     when t1.APPRAISE_TYPE='3' then 'AA'
     when t1.APPRAISE_TYPE='4' then 'AA-' 
     when t1.APPRAISE_TYPE='5' then 'A+' 
     when t1.APPRAISE_TYPE='6' then 'A'
     when t1.APPRAISE_TYPE='7' then 'A-'
     when t1.APPRAISE_TYPE='8' then 'BBB+'
     when t1.APPRAISE_TYPE='9' then 'BBB'
     when t1.APPRAISE_TYPE='A' then 'BBB-' 
     when t1.APPRAISE_TYPE='B' OR t1.STOCK_CD IN ('032001060', '101788002') then 'BBB-级以下' -- [20250729][姜俐锋][JLBA202505270010][吴大为]：与1104 G1102评级条件一致
     when t1.APPRAISE_TYPE='C' then ''
     end as J020031, -- 031.基础资产外部评级
t1.LEV_ORG as J020032 ,-- 032.基础资产评级机构
null as J020109,-- 109.基础资产内部评级
null as J020033,-- 033.基础资产最终投向类型
null as J020034,-- 034.基础资产最终投向行业类型
 -- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐
/*集市
0	无选择权
1	发行人可赎回
2	投资人可回售
3	可赎回或可回售
4	投资人可转债*/
case when     T1.CONTAIN_RIGHT_TPYE='1'then '01'
     when     T1.CONTAIN_RIGHT_TPYE='2'then '04'
     when     T1.CONTAIN_RIGHT_TPYE='3'then '01;04'
     when     T1.CONTAIN_RIGHT_TPYE IN('0','4') then null end
as   J020087, -- 087.含权类型 
case when t.org_num='009820' then '0' when  nvl(t.COLL_AMT,0)>0 then '1' else '0' end as J020103,-- 103.存在变现障碍标识 0-否 1-是
null as J020104,-- 104.备注
TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')as J020105,-- 105.采集日期
TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') as DIS_DATA_DATE,-- 装入数据日期
t.ORG_NUM as DIS_BANK_ID ,
 '投资业务' as DIS_DEPT ,-- 业务条线
 t.ORG_NUM as DEPARTMENT_ID,
'0'  as J020106,   -- 106.是否投向市场化债转股相关产品  0.否，1.是
'0'  as J020110,   -- 110.是否投向产业基金  0.否，1.是
null as J020111,   -- 111.被持有股权企业客户ID
  ROW_NUMBER() OVER(PARTITION BY t.SUBJECT_CD,t.ORG_NUM ORDER by t2.EVALUATE_DT desc) AS RN
 from smtmods.L_ACCT_FUND_INVEST t -- 投资业务信息表
    LEFT JOIN (select * from (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.ECIF_CUST_ID ORDER BY A.ECIF_CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') B1
             ON T.CUST_ID = B1.ECIF_CUST_ID
    LEFT JOIN (select * from (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') B2
             ON T.CUST_ID = B2.CUST_ID          
 LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表
   ON T.ORG_NUM = ORG.ORG_NUM
  AND ORG.DATA_DATE = I_DATE
  left join smtmods.l_agre_bond_info T1
  on T.ACCT_NUM=T1.STOCK_CD and T1.DATA_DATE=I_DATE
  left join smtmods.L_AGRE_OTHER_SUBJECT_INFO t2 
    on T.ACCT_NUM=T2.SUBJECT_CD and T2.DATA_DATE=I_DATE
  left join ybt_datacore.m_dict_codetable m1 on m1.L_CODE_TABLE_CODE = 'V0003' and NVL(B1.DEPT_TYPE,B2.DEPT_TYPE) = m1.l_code
  left join ybt_datacore.m_dict_codetable m2 on m2.L_CODE_TABLE_CODE = 'V0004' and NVL(B1.DEPT_TYPE,B2.DEPT_TYPE) = m2.l_code
  left join SMTMODS.L_CUST_EXTERNAL_INFO ce on CE.DATA_DATE=I_DATE and (t.cust_id=ce.CUST_ID or b2.ECIF_CUST_ID=ce.CUST_ID)
  left join ybt_datacore.m_dict_codetable m3 on m3.L_CODE_TABLE_CODE = 'V0005' and ce.INDS_INVEST = m3.l_code
 where (t.DATE_SOURCESD='债券投资'-- 现券
 or (t.GL_ITEM_CODE in ('11010302','11010303','15010201')and t.DATE_SOURCESD<>'债券投资'  and REF_NUM <>  'TH' )-- 公募基金11010302、私募没有、信托11010303、资管11010303、理财11010303-- 非标投资  公募基金 --  update 20241216 zjk 取消机构 = 009820 因为非标投资保函 金融市场部，过滤投行业务REF_NUM <>  'TH' 为满足YBT_JYF21-58校验
 ) and t.DATA_DATE=I_DATE  -- and  t.PRINCIPAL_BALANCE<>'0' and  (t1.MATURITY_DT>I_DATE or t2.MATURITY_DT>=I_DATE)-- 2.0 zdsj h
 -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
 AND (T.MATURITY_DATE >= SUBSTR(I_DATE,1,4)||'0101' OR T.MATURITY_DATE IS NULL  or T.FACE_VAL > 0)-- 2.0 zdsj h
-- and t.SUBJECT_CD<>'X0003120B2700001'
 )t4 where t4.RN=1  ;
    COMMIT;


-- 回购 --
-- 非票据回购的 债券回购唯一值
INSERT  INTO T_9_2  (
 J020001,   -- 001.投资标的      
   J020002,   -- 002.投资标的名称
   J020003,   -- 003.机构
   J020004,   -- 004.发行价格
   J020005,   -- 005.发行规模
   J020006,   -- 006.发行机构名称
   J020007,   -- 007.发行机构代码
   J020008,   -- 008.发行机构大类
   J020107,   -- 107.发行机构小类
   J020009,   -- 009.发行国家地区
   J020108,   -- 108.交易流通场所
   J020010,   -- 010.投资标的币种
   J020011,   -- 011.投资标的代码
   J020014,   -- 014.起息日期
   J020015,   -- 015.发行日期
   J020016,   -- 016.到期日期
   J020017,   -- 017.投资标的利率类型
   J020018,   -- 018.利率/收益率
   J020019,   -- 019.最近评估价格
   J020020,   -- 020.评估价格日期
   J020021,   -- 021.投融资标的类别
   J020022,   -- 022.资产风险权重
   J020026,   -- 026.基础资产客户名称
   J020027,   -- 027.基础资产客户国家
   J020028,   -- 028.基础资产客户评级
   J020029,   -- 029.基础资产客户评级机构
   J020030,   -- 030.基础资产客户行业类型
   J020031,   -- 031.基础资产外部评级
   J020032,   -- 032.基础资产评级机构
   J020109,   -- 109.基础资产内部评级
   J020033,   -- 033.基础资产最终投向类型
   J020034,   -- 034.基础资产最终投向行业类型
   J020087,   -- 087.含权类型
   J020103,   -- 103.存在变现障碍标识
   J020104,   -- 104.备注
   J020105,   -- 105.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID  ,-- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID,
   J020106,   -- 106.是否投向市场化债转股相关产品
   J020110,   -- 110.是否投向产业基金
   J020111    -- 111.被持有股权企业客户ID
) select 
t.DEAL_ACCT_NUM,-- 001.投资标的  
T.JYDSMC||CASE WHEN T.BUSI_TYPE='101'THEN '质押式买入返售'
               WHEN T.BUSI_TYPE='102'THEN '买断式买入返售' 
               WHEN T.BUSI_TYPE='201'THEN '质押式卖出回购'
               WHEN T.BUSI_TYPE='202'THEN '买断式卖出回购' 
               END ,-- 002.投资标的名称
ORG.ORG_ID,-- -- 003.机构
T.BALANCE,-- 004.发行价格
T.BALANCE, -- 005.发行规模
t.JYDSMC,-- 006.发行机构名称   
T.JYDSDM, -- 007.发行机构代码
-- 20241024_ZHOULP_JLBA202409030008_交易对手大类小类
CASE WHEN M1.GB_CODE IS NOT NULL THEN M1.GB_CODE
     WHEN T.JYDSMC LIKE '%银行%' THEN '01' -- [20250619][巴启威][JLBA202505280002][吴大为]：发行机构大类增加名称映射。'%银行%' 映射成对应码值01
     WHEN T.JYDSMC LIKE '%财政部%' THEN '09'
     WHEN T.JYDSMC LIKE '%政府%'   THEN '09'
     WHEN T.JYDSMC LIKE '%财政厅%' THEN '09'
     WHEN T.JYDSMC LIKE '%财政局%' THEN '09'
     WHEN T.JYDSMC LIKE '%理财%公司%' THEN '01'
     WHEN CE.CORP_PROPTY IN ('0805010100','0805010200') THEN '10' -- 国有企业
     WHEN CE.CORP_PROPTY IN ('0805040000') THEN '10' -- 集体企业
     WHEN CE.CORP_PROPTY IN ('0805060000') THEN '10' -- 其他企业
     WHEN CE.CORP_PROPTY IN ('0805030100') THEN '10' -- 中外合资企业
     WHEN T.JYDSMC LIKE '%有限责任公司%' THEN '10'
     WHEN T.JYDSMC LIKE '%股份有限公司%' THEN '10'
     when T.JYDSMC like '%基金%' then '06'  -- [20250422] [姜俐锋] [增加判断,与投资业务一致]
     when T.JYDSMC like '%集团有限公司%' then '10'
     when T.JYDSMC like '%有限公司%' then '10'
     WHEN M4.GB_CODE IS NOT NULL THEN M4.GB_CODE  --  -- [20250415][姜俐锋][JLBA202502210009][吴大为]: 增加判断
END AS J020008, -- 008.发行机构大类 通过统一社会信用代码增加判断
CASE WHEN M2.GB_CODE  IS NOT NULL THEN M2.GB_CODE
     WHEN T.JYDSMC LIKE '%财政部%' THEN '090501'
     WHEN T.JYDSMC LIKE '%政府%'   THEN '090601'
     WHEN T.JYDSMC LIKE '%财政厅%' THEN '090601'
     WHEN T.JYDSMC LIKE '%财政局%' THEN '090601'
     WHEN T.JYDSMC LIKE '%理财%公司%' THEN '010908'
     WHEN CE.CORP_PROPTY IN ('0805010100','0805010200') THEN '100101' -- 国有企业
     WHEN CE.CORP_PROPTY IN ('0805040000') THEN '100102' -- 集体企业
     WHEN CE.CORP_PROPTY IN ('0805060000') THEN '100108' -- 其他企业
     WHEN CE.CORP_PROPTY IN ('0805030100') THEN '100301' -- 中外合资企业
     WHEN T.JYDSMC LIKE '%有限责任公司%' THEN '100105'
     WHEN T.JYDSMC LIKE '%股份有限公司%' THEN '100106'
     when T.JYDSMC like '%基金%' then '060201'
     when T.JYDSMC like '%集团有限公司%' then '100102'
     when T.JYDSMC like '%有限公司%' then '100105'   -- [20250422] [姜俐锋] [增加判断,与投资业务一致]
END AS J020107, -- 107.发行机构小类
'CHN', -- 009.发行国家地区
'01', -- 108.交易流通场所
'CNY',-- 010.投资标的币种
t.DEAL_ACCT_NUM , -- 011.投资标的代码
TO_CHAR(TO_DATE(t.BEG_DT,'YYYYMMDD'),'YYYY-MM-DD'),-- 014.起息日期
TO_CHAR(TO_DATE(t.BEG_DT,'YYYYMMDD'),'YYYY-MM-DD'),-- 015.发行日期
TO_CHAR(TO_DATE(t.END_DT,'YYYYMMDD'),'YYYY-MM-DD'),-- 016.到期日期
'02' ,-- 017.投资标的利率类型   
T.REAL_INT_RAT ,-- 018.利率/收益率
T.BALANCE,-- 019.最近评估价格 加字段
TO_CHAR(TO_DATE(T.BEG_DT,'YYYYMMDD'),'YYYY-MM-DD'),-- 020.评估价格日期 加字段
CASE WHEN T.BUSI_TYPE IN ('101','102')THEN '0020' 
     WHEN T.BUSI_TYPE IN ('201','202')THEN '0060'END  , -- 021.投融资标的类别
NULL,-- 022.资产风险权重 找RWA系统。
T.JYDSMC, -- 026.基础资产客户名称
'CHN',-- 027.基础资产客户国家
NULL,-- 028.基础资产客户评级
NULL,-- 029.基础资产客户评级机构
M3.GB_CODE AS J020030,-- 030.基础资产客户行业类型  -- 20241024_ZHOULP_JLBA202408290021_金市需求_业务姚司桐
NULL, -- 031.基础资产外部评级
NULL,-- 032.基础资产评级机构
NULL,-- 109.基础资产内部评级
NULL,-- 033.基础资产最终投向类型
NULL,-- 034.基础资产最终投向行业类型
NULL , -- 087.含权类型 待业务给口径
CASE WHEN SUBSTR(T.GL_ITEM_CODE,1,4) IN ('1111','2111') THEN '1' ELSE '0' END  ,-- 103.存在变现障碍标识（数仓反馈债券类的债券编号老信贷   有，新信贷没有接） 20250311
NULL,-- 104.备注
TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),-- 105.采集日期
TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),-- 装入数据日期
T.ORG_NUM,
 '回购业务',-- 业务条线
 T.ORG_NUM,
'0' ,-- 106.是否投向市场化债转股相关产品  0.否，1.是
'0' ,-- 110.是否投向产业基金  0.否，1.是
NULL -- 111.被持有股权企业客户ID
 FROM SMTMODS.L_ACCT_FUND_REPURCHASE T -- 回购信息表
 LEFT JOIN (select * from (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.ECIF_CUST_ID ORDER BY A.ECIF_CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') B1
   ON T.CUST_ID = B1.ECIF_CUST_ID
 LEFT JOIN (select * from (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') B2
   ON T.CUST_ID = B2.CUST_ID
 LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表
   ON T.ORG_NUM = ORG.ORG_NUM
  AND ORG.DATA_DATE = I_DATE
 LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M1 
   ON M1.L_CODE_TABLE_CODE = 'V0003'
  AND NVL(B1.DEPT_TYPE,B2.DEPT_TYPE) = M1.L_CODE
 LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M2 
   ON M2.L_CODE_TABLE_CODE = 'V0004' 
  AND NVL(B1.DEPT_TYPE,B2.DEPT_TYPE) = M2.L_CODE
 LEFT JOIN SMTMODS.L_CUST_EXTERNAL_INFO CE 
   ON CE.DATA_DATE=I_DATE 
  AND (T.CUST_ID=CE.CUST_ID OR B2.ECIF_CUST_ID=CE.CUST_ID)
 LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M3 
   ON M3.L_CODE_TABLE_CODE = 'V0005' 
  AND CE.INDS_INVEST = M3.L_CODE
 LEFT JOIN (select * from (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.TYSHXYDM ORDER BY A.ECIF_CUST_ID) RN  -- 20250421 YBT_JYJ02-16 修改分组条件（ECIF_CUST_ID）改TYSHXYDM
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') t1  --  -- [20250415][姜俐锋][JLBA202502210009][吴大为]: 通过统一社会信用代码增加判断 jlf
   ON t1.TYSHXYDM = T.JYDSDM
  AND t1.DATA_DATE = I_DATE
 LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M4 --  -- [20250415][姜俐锋][JLBA202502210009][吴大为]:通过统一社会信用代码增加判断 jlf
   ON T1.DEPT_TYPE = M4.L_CODE
  AND M4.L_CODE_TABLE_CODE = 'V0003' 
WHERE T.DATA_DATE=I_DATE 
  -- AND T.DATE_SOURCESD<>'票据回购'
  AND (T.BALANCE<>'0'
      OR T.END_DT >= SUBSTR(I_DATE,1,4)||'0101' -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
	  );
COMMIT;
    
--  票据回购-----
INSERT  INTO T_9_2  (
 J020001,   -- 001.投资标的      
   J020002,   -- 002.投资标的名称
   J020003,   -- 003.机构
   J020004,   -- 004.发行价格
   J020005,   -- 005.发行规模
   J020006,   -- 006.发行机构名称
   J020007,   -- 007.发行机构代码
   J020008,   -- 008.发行机构大类
   J020107,   -- 107.发行机构小类
   J020009,   -- 009.发行国家地区
   J020108,   -- 108.交易流通场所
   J020010,   -- 010.投资标的币种
   J020011,   -- 011.投资标的代码
   J020014,   -- 014.起息日期
   J020015,   -- 015.发行日期
   J020016,   -- 016.到期日期
   J020017,   -- 017.投资标的利率类型
   J020018,   -- 018.利率/收益率
   J020019,   -- 019.最近评估价格
   J020020,   -- 020.评估价格日期
   J020021,   -- 021.投融资标的类别
   J020022,   -- 022.资产风险权重
   J020026,   -- 026.基础资产客户名称
   J020027,   -- 027.基础资产客户国家
   J020028,   -- 028.基础资产客户评级
   J020029,   -- 029.基础资产客户评级机构
   J020030,   -- 030.基础资产客户行业类型
   J020031,   -- 031.基础资产外部评级
   J020032,   -- 032.基础资产评级机构
   J020109,   -- 109.基础资产内部评级
   J020033,   -- 033.基础资产最终投向类型
   J020034,   -- 034.基础资产最终投向行业类型
   J020087,   -- 087.含权类型
   J020103,   -- 103.存在变现障碍标识
   J020104,   -- 104.备注
   J020105,   -- 105.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID  ,-- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID,
   J020106,   -- 106.是否投向市场化债转股相关产品
   J020110,   -- 110.是否投向产业基金
   J020111    -- 111.被持有股权企业客户ID
)   
    select 
   J020001,   -- 001.投资标的      
   J020002,   -- 002.投资标的名称
   J020003,   -- 003.机构
   J020004,   -- 004.发行价格
   J020005,   -- 005.发行规模
   J020006,   -- 006.发行机构名称
   J020007,   -- 007.发行机构代码
   J020008,   -- 008.发行机构大类
   J020107,   -- 107.发行机构小类
   J020009,   -- 009.发行国家地区
   J020108,   -- 108.交易流通场所
   J020010,   -- 010.投资标的币种
   J020011,   -- 011.投资标的代码
   J020014,   -- 014.起息日期
   J020015,   -- 015.发行日期
   J020016,   -- 016.到期日期
   J020017,   -- 017.投资标的利率类型
   J020018,   -- 018.利率/收益率
   J020019,   -- 019.最近评估价格
   J020020,   -- 020.评估价格日期
   J020021,   -- 021.投融资标的类别
   J020022,   -- 022.资产风险权重
   J020026,   -- 026.基础资产客户名称
   J020027,   -- 027.基础资产客户国家
   J020028,   -- 028.基础资产客户评级
   J020029,   -- 029.基础资产客户评级机构
   J020030,   -- 030.基础资产客户行业类型
   J020031,   -- 031.基础资产外部评级
   J020032,   -- 032.基础资产评级机构
   J020109,   -- 109.基础资产内部评级
   J020033,   -- 033.基础资产最终投向类型
   J020034,   -- 034.基础资产最终投向行业类型
   J020087,   -- 087.含权类型
   J020103,   -- 103.存在变现障碍标识
   J020104,   -- 104.备注
   J020105,   -- 105.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID  ,-- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID,
   J020106,   -- 106.是否投向市场化债转股相关产品
   J020110,   -- 110.是否投向产业基金
   J020111    -- 111.被持有股权企业客户ID
    FROM 
(SELECT 
 T.DEAL_ACCT_NUM AS J020001,-- 001.投资标的
 T.JYDSMC||CASE WHEN T.BUSI_TYPE='101'THEN '质押式买入返售'
                WHEN T.BUSI_TYPE='201'THEN '质押式卖出回购'END AS J020002,-- 002.投资标的名称
 ORG.ORG_ID AS J020003,-- -- 003.机构
 T1.AMOUNT AS J020004,-- 004.发行价格
 T1.AMOUNT AS J020005, -- 005.发行规模
 T.JYDSMC AS J020006,-- 006.发行机构名称
 T.JYDSDM AS J020007, -- 007.发行机构代码
 -- 20241024_ZHOULP_JLBA202409030008_交易对手大类小类
 CASE WHEN M1.GB_CODE  IS NOT NULL THEN M1.GB_CODE
      WHEN T.JYDSMC LIKE '%银行%' THEN '01' -- [20250619][巴启威][JLBA202505280002][吴大为]：发行机构大类增加名称映射。'%银行%' 映射成对应码值01
      WHEN T.JYDSMC LIKE '%财政部%' THEN '09'
      WHEN T.JYDSMC LIKE '%政府%'   THEN '09'
      WHEN T.JYDSMC LIKE '%财政厅%' THEN '09'
      WHEN T.JYDSMC LIKE '%财政局%' THEN '09'
      WHEN T.JYDSMC LIKE '%理财%公司%' THEN '01'
      WHEN CE.CORP_PROPTY IN ('0805010100','0805010200') THEN '10' -- 国有企业
      WHEN CE.CORP_PROPTY IN ('0805040000') THEN '10' -- 集体企业
      WHEN CE.CORP_PROPTY IN ('0805060000') THEN '10' -- 其他企业
      WHEN CE.CORP_PROPTY IN ('0805030100') THEN '10' -- 中外合资企业
      WHEN T.JYDSMC LIKE '%有限责任公司%' THEN '10'
      WHEN T.JYDSMC LIKE '%股份有限公司%' THEN '10'
      WHEN M4.GB_CODE IS NOT NULL THEN M4.GB_CODE  --  -- [20250415][姜俐锋][JLBA202502210009][吴大为]: 增加判断
       END AS J020008, -- 008.发行机构大类
 CASE WHEN M2.GB_CODE  IS NOT NULL THEN M2.GB_CODE
      WHEN T.JYDSMC LIKE '%财政部%' THEN '090501'
      WHEN T.JYDSMC LIKE '%政府%'   THEN '090601'
      WHEN T.JYDSMC LIKE '%财政厅%' THEN '090601'
      WHEN T.JYDSMC LIKE '%财政局%' THEN '090601'
      WHEN T.JYDSMC LIKE '%理财%公司%' THEN '010908'
      WHEN CE.CORP_PROPTY IN ('0805010100','0805010200') THEN '100101' -- 国有企业
      WHEN CE.CORP_PROPTY IN ('0805040000') THEN '100102' -- 集体企业
      WHEN CE.CORP_PROPTY IN ('0805060000') THEN '100108' -- 其他企业
      WHEN CE.CORP_PROPTY IN ('0805030100') THEN '100301' -- 中外合资企业
      WHEN T.JYDSMC LIKE '%有限责任公司%' THEN '100105'
      WHEN T.JYDSMC LIKE '%股份有限公司%' THEN '100106'
       END AS J020107, -- 107.发行机构小类
 'CHN' AS J020009, -- 009.发行国家地区
 '01' AS J020108, -- 108.交易流通场所
 'CNY' AS J020010,-- 010.投资标的币种
 T.SUBJECT_CD AS J020011, -- 011.投资标的代码
 TO_CHAR(TO_DATE(T1.OPEN_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS J020014,-- 014.起息日期
 TO_CHAR(TO_DATE(T1.OPEN_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS J020015,-- 015.发行日期
 TO_CHAR(TO_DATE(T1.MATU_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS J020016,-- 016.到期日期
 '02' AS J020017,-- 017.投资标的利率类型   
 T.REAL_INT_RAT AS  J020018,-- 018.利率/收益率
 T1.AMOUNT AS J020019,-- 019.最近评估价格 加字段
 TO_CHAR(TO_DATE( T.BEG_DT,'YYYYMMDD'),'YYYY-MM-DD') AS J020020,-- 020.评估价格日期 加字段
 CASE WHEN T.BUSI_TYPE IN ('101','102')THEN '0020' 
      WHEN T.BUSI_TYPE IN ('201','202')THEN '0060'
       END AS J020021 , -- 021.投融资标的类别
 NULL AS J020022,-- 022.资产风险权重 找RWA系统。
 T.JYDSMC AS J020026, -- 026.基础资产客户名称
 'CHN'AS J020027,-- 027.基础资产客户国家
 NULL AS J020028,-- 028.基础资产客户评级
 NULL AS J020029,-- 029.基础资产客户评级机构
 M3.GB_CODE AS J020030,-- 030.基础资产客户行业类型  -- 20241024_ZHOULP_JLBA202408290021_金市需求_业务姚司桐
 NULL AS J020031, -- 031.基础资产外部评级
 NULL AS J020032,-- 032.基础资产评级机构
 NULL AS J020109,-- 109.基础资产内部评级
 NULL AS J020033,-- 033.基础资产最终投向类型
 NULL AS J020034,-- 034.基础资产最终投向行业类型
 NULL AS J020087 , -- 087.含权类型 待业务给口径
 CASE WHEN SUBSTR(T.GL_ITEM_CODE,1,4) IN ('1111','2111') THEN '1' ELSE '0' END  AS J020103,-- 103.存在变现障碍标识（数仓反馈债券类的债券编号老信贷   有，新信贷没有接）
 NULL AS J020104,-- 104.备注 
 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')AS J020105,-- 105.采集日期
 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')AS DIS_DATA_DATE,-- 装入数据日期
 T.ORG_NUM AS DIS_BANK_ID,
 '票据回购' AS DIS_DEPT,-- 业务条线
  T.ORG_NUM AS DEPARTMENT_ID,
 '0'  AS J020106,   -- 106.是否投向市场化债转股相关产品  0.否，1.是
 '0'  AS J020110,   -- 110.是否投向产业基金  0.否，1.是
 NULL AS J020111,   -- 111.被持有股权企业客户ID
 ROW_NUMBER() OVER(PARTITION BY T.SUBJECT_CD ORDER BY T.BEG_DT DESC) AS RN
 FROM SMTMODS.L_ACCT_FUND_REPURCHASE T  -- 回购信息表  
 LEFT JOIN (select * from (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.ECIF_CUST_ID ORDER BY A.ECIF_CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') B1
   ON T.CUST_ID = B1.ECIF_CUST_ID
 LEFT JOIN (select * from (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') B2
   ON T.CUST_ID = B2.CUST_ID
 LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表
   ON T.ORG_NUM = ORG.ORG_NUM
  AND ORG.DATA_DATE = I_DATE
 LEFT JOIN SMTMODS.L_AGRE_BILL_INFO T1 
   ON T.SUBJECT_CD=T1.BILL_NUM
  AND T1.DATA_DATE=I_DATE
 LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M1
   ON M1.L_CODE_TABLE_CODE = 'V0003' 
  AND NVL(B1.DEPT_TYPE,B2.DEPT_TYPE) = M1.L_CODE
 LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M2 
   ON M2.L_CODE_TABLE_CODE = 'V0004' 
  AND NVL(B1.DEPT_TYPE,B2.DEPT_TYPE) = M2.L_CODE
 LEFT JOIN SMTMODS.L_CUST_EXTERNAL_INFO CE 
   ON CE.DATA_DATE=I_DATE 
  AND (T.CUST_ID=CE.CUST_ID OR B2.ECIF_CUST_ID=CE.CUST_ID)
 LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M3
   ON M3.L_CODE_TABLE_CODE = 'V0005' 
  AND CE.INDS_INVEST = M3.L_CODE
 LEFT JOIN (select * from (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.ECIF_CUST_ID ORDER BY A.ECIF_CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') t2  --  -- [20250415][姜俐锋][JLBA202502210009][吴大为]:  通过统一社会信用代码增加判断 jlf
   ON t2.TYSHXYDM = T.JYDSDM
  AND t2.DATA_DATE = I_DATE
 LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M4 --  -- [20250415][姜俐锋][JLBA202502210009][吴大为]:  通过统一社会信用代码增加判断 jlf
   ON T2.DEPT_TYPE = M4.L_CODE
  AND M4.L_CODE_TABLE_CODE = 'V0003'  
WHERE T.DATA_DATE=I_DATE 
  AND SUBSTR(T.BUSI_TYPE,1,1) IN ('1','2') -- 1-买入返售 ;2-卖出回购
  AND T.ASS_TYPE IN ('1','2','3') -- 1-债券 2-商业汇票 3-其他票据-- 票据报到6_14票据再贴现里面 20240618因流动性指标 将票据放开
  -- AND T.END_DT >= I_DATE -- 未到期或到期当日
  -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
  AND (((T.ACCT_CLDATE > I_DATE OR T.ACCT_CLDATE IS NULL) AND T.BALANCE > 0) OR (T.ACCT_CLDATE >= SUBSTR(I_DATE,1,4)||'0101' AND T.BALANCE = 0) OR  ACCRUAL <> 0) -- 与4.3，7.6同步  ALTER BY DJH 20240719 有利息无本金数据也加进来
  AND T.SUBJECT_CD IS NOT NULL  -- 20241024_ZHOULP_JLBA202408290021_金市需求_业务姚司桐  非需求内容，剔除主键空值脏数据
  -- AND T.DATE_SOURCESD='票据回购' AND T1.AMOUNT<>'0'AND T1.MATU_DATE>=I_DATE
)T3 WHERE T3.RN=1;
    COMMIT;
    
-- 拆借 ---------acct_num 没有重复的
  INSERT  INTO T_9_2  (
 J020001,   -- 001.投资标的      
   J020002,   -- 002.投资标的名称
   J020003,   -- 003.机构
   J020004,   -- 004.发行价格
   J020005,   -- 005.发行规模
   J020006,   -- 006.发行机构名称
   J020007,   -- 007.发行机构代码
   J020008,   -- 008.发行机构大类
   J020107,   -- 107.发行机构小类
   J020009,   -- 009.发行国家地区
   J020108,   -- 108.交易流通场所
   J020010,   -- 010.投资标的币种
   J020011,   -- 011.投资标的代码
   J020014,   -- 014.起息日期
   J020015,   -- 015.发行日期
   J020016,   -- 016.到期日期
   J020017,   -- 017.投资标的利率类型
   J020018,   -- 018.利率/收益率
   J020019,   -- 019.最近评估价格
   J020020,   -- 020.评估价格日期
   J020021,   -- 021.投融资标的类别
   J020022,   -- 022.资产风险权重
   J020026,   -- 026.基础资产客户名称
   J020027,   -- 027.基础资产客户国家
   J020028,   -- 028.基础资产客户评级
   J020029,   -- 029.基础资产客户评级机构
   J020030,   -- 030.基础资产客户行业类型
   J020031,   -- 031.基础资产外部评级
   J020032,   -- 032.基础资产评级机构
   J020109,   -- 109.基础资产内部评级
   J020033,   -- 033.基础资产最终投向类型
   J020034,   -- 034.基础资产最终投向行业类型
   J020087,   -- 087.含权类型
   J020103,   -- 103.存在变现障碍标识
   J020104,   -- 104.备注
   J020105,   -- 105.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID,     -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID,
   J020106,   -- 106.是否投向市场化债转股相关产品
   J020110,   -- 110.是否投向产业基金
   J020111    -- 111.被持有股权企业客户ID
)
SELECT 
 T.ACCT_NUM ,-- 001.投资标的  
 CASE WHEN T.ACCT_TYP='10201'THEN T.CUST_ID||'拆放同业'
      WHEN T.ACCT_TYP='20201'THEN T.CUST_ID||'同业拆入'
      WHEN SUBSTR(T.ACCT_TYP,1,3) = '105' /*IN ('105','205')*/ THEN T.CUST_ID||'同业借出'   --  [2025-05-13][巴启威][JLBA202504070013][陈聪]: 业务反馈205同业借入 
      WHEN T.GL_ITEM_CODE = '13020104'  THEN T.CUST_ID||'同业借出'
      WHEN (T.GL_ITEM_CODE IN ('20030102','20030106') OR SUBSTR(T.ACCT_TYP,1,3) = '205')  THEN T.CUST_ID||'同业借入'  --  [2025-05-13][巴启威][JLBA202504070013][陈聪]: 业务反馈205同业借入 
      WHEN T.GL_ITEM_CODE LIKE '101101%'THEN T.CUST_ID||'存放同业活期'
      WHEN T.GL_ITEM_CODE LIKE '101102%'THEN T.CUST_ID||'存放同业定期'
      ELSE T.CUST_ID||T2.GL_CD_NAME
      END ,-- 002.投资标的名称
ORG.ORG_ID,-- -- 003.机构
 NVL(t.FST_CRE_AMT,1) ,-- 004.发行价格 [2025-05-13][巴启威][JLBA202504070013][陈聪]:同业现取数全部业务,取对应账户 最早一笔的入账金额，如果取不到交易则都默认为 1
 NVL(t.FST_CRE_AMT,1) ,-- 005.发行规模 [2025-05-13][巴启威][JLBA202504070013][陈聪]:同业现取数全部业务,取对应账户 最早一笔的入账金额，如果取不到交易则都默认为 1
 t1.CUST_nam,-- 006.发行机构名称
 CASE WHEN ORG1.ORG_NUM IS NOT NULL AND ORG1.ID_NO IS NOT NULL THEN ORG1.ID_NO -- 发行机构为我行分行
      WHEN ORG1.ORG_NUM IS NOT NULL AND ORG1.ID_NO IS NULL THEN '9122010170255776XN' 
      ELSE NVL(T1.ID_NO,T.JYDSTYDM)  END , -- 007.发行机构代码  JLBA202409290003 20241212 
-- 20241024_zhoulp_JLBA202409030008_交易对手大类小类
case when m1.GB_CODE  is not null then m1.GB_CODE
     WHEN ORG1.ORG_NUM IS NOT NULL THEN '01' -- 发行机构为我行
     when T1.CUST_NAM like '%银行%' then '01' -- [20250619][巴启威][JLBA202505280002][吴大为]：发行机构大类增加名称映射。'%银行%' 映射成对应码值01
     when T1.CUST_NAM like '%财政部%' then '09'
     when T1.CUST_NAM like '%政府%'   then '09'
     when T1.CUST_NAM like '%财政厅%' then '09'
     when T1.CUST_NAM like '%财政局%' then '09'
     when T1.CUST_NAM like '%理财%公司%' then '01'
     when ce.corp_propty in ('0805010100','0805010200') then '10' -- 国有企业
     when ce.corp_propty in ('0805040000') then '10' -- 集体企业
     when ce.corp_propty in ('0805060000') then '10' -- 其他企业
     when ce.corp_propty in ('0805030100') then '10' -- 中外合资企业
     when T1.CUST_NAM like '%有限责任公司%' then '10'
     when T1.CUST_NAM like '%股份有限公司%' then '10'
end as J020008, -- 008.发行机构大类
case when m2.GB_CODE  is not null then m2.GB_CODE
     when org1.org_num is not null then '010401' -- 发行机构为我行
     when T1.CUST_NAM like '%财政部%' then '090501'
     when T1.CUST_NAM like '%政府%'   then '090601'
     when T1.CUST_NAM like '%财政厅%' then '090601'
     when T1.CUST_NAM like '%财政局%' then '090601'
     when T1.CUST_NAM like '%理财%公司%' then '010908'
     when ce.corp_propty in ('0805010100','0805010200') then '100101' -- 国有企业
     when ce.corp_propty in ('0805040000') then '100102' -- 集体企业
     when ce.corp_propty in ('0805060000') then '100108' -- 其他企业
     when ce.corp_propty in ('0805030100') then '100301' -- 中外合资企业
     when T1.CUST_NAM like '%有限责任公司%' then '100105'
     when T1.CUST_NAM like '%股份有限公司%' then '100106'
end as J020107, -- 107.发行机构小类        
'CHN' , -- 009.发行国家地区
case when t.ORG_NUM='009804'then '18'else '' end , -- 108.交易流通场所 --20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐 :拆借默认应为18全国银行业同业拆借市场
t.CURR_CD,-- 010.投资标的币种
 t.REF_NUM , -- 011.投资标的代码  2.0zdsj h
TO_CHAR(TO_DATE(t.START_DATE,'YYYYMMDD'),'YYYY-MM-DD'),-- 014.起息日期
TO_CHAR(TO_DATE(t.START_DATE,'YYYYMMDD'),'YYYY-MM-DD'),-- 015.发行日期
TO_CHAR(TO_DATE(t.MATURE_DATE,'YYYYMMDD'),'YYYY-MM-DD'),-- 016.到期日期
-- case when t.ORG_NUM='009804'then '02'else '' end  ,-- 017.投资标的利率类型   康星无法判断是否是LPR
'02',-- 017.投资标的利率类型   康星无法判断是否是LPR  -- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐  -- 同业常城同意默认02；金市此需求文档标注默认02
t.REAL_INT_RAT ,-- 018.利率/收益率
t.balance,-- 019.最近评估价格 加字段
TO_CHAR(TO_DATE(t.START_DATE,'YYYYMMDD'),'YYYY-MM-DD'),-- 020.评估价格日期 加字段
case when t.GL_ITEM_CODE in ('20030101','20030103')then '0090' -- 拆入 拆出
     when t.GL_ITEM_CODE in ('20030105','20030201')then '0100'
     when t.GL_ITEM_CODE in ('13020101','13020103')then '0110'
     when t.GL_ITEM_CODE in ('13020105')then '0120'
     when t.GL_ITEM_CODE in ('13020102','13020104')then '0110'-- 同业借入 同业借出
     when t.GL_ITEM_CODE in ('13020106')then '0120'
     when t.GL_ITEM_CODE in ('20030102','20030104')then '0090'
     when t.GL_ITEM_CODE in ('20030106')then '0100'
     when t.GL_ITEM_CODE in ('10110101','10110110')then '0180'-- 存放同业
     when t.GL_ITEM_CODE in ('10110102','10110103','10110104','10110105','10110106','10110107','10110108','10110109')then '0170'
     when t.GL_ITEM_CODE in ('10110111')then '0190'
     when t.GL_ITEM_CODE in ('10110201','10110202','10110203','10110204','10110205','10110206','10110207','10110208')then '0130'
     when t.GL_ITEM_CODE in ('10110209')then '0140'
     when t.GL_ITEM_CODE='20040101' then '0250' -- 其他同业融入
     when t.GL_ITEM_CODE='20120101' then '0200' -- 结算性同业存放
     when t.GL_ITEM_CODE='20120208' then '0190' -- 非结算性同业存放
     when t.GL_ITEM_CODE='20120201' then '0190' -- 非结算性同业存放
     when t.GL_ITEM_CODE='20030301' then '0250' -- 其他同业融入
     when t.GL_ITEM_CODE='20120105' then '0190' -- 非结算性同业存放
     when t.GL_ITEM_CODE='20120106' then '0190' -- 非结算性同业存放
     when t.GL_ITEM_CODE='10310101' then '0170' -- 非结算性存放同业
     when t.GL_ITEM_CODE='20120103' then '0190' -- 非结算性同业存放
     when t.GL_ITEM_CODE='20120102' then '0200' -- 结算性同业存放
     when t.GL_ITEM_CODE='20120104' then '0190' -- 非结算性同业存放
     when t.GL_ITEM_CODE='20120109' then '0190' -- 非结算性同业存放
     end , -- 021.投融资标的类别
null,-- 022.资产风险权重 找RWA系统。
nvl(t1.cust_nam,t.cust_id), -- 026.基础资产客户名称  -- 2.0zdsj h
'CHN' ,-- 027.基础资产客户国家  -- 2.0zdsj h
CASE WHEN CE.ISSUER_RAT IN ('AAA', 'AA+', 'AA', 'AA-') 
                 THEN 'AA-以上（含AA-）'
                 WHEN CE.ISSUER_RAT IN ('BBB-', 'BBB', 'BBB+', 'A-', 'A', 'A+') 
                 THEN 'A+ 至 BBB-（含BBB-）'
                 WHEN CE.ISSUER_RAT IN ('BB-', 'BB', 'BB+', 'B+', 'B', 'B-') 
                 THEN 'BB+ 至 B-（含B-）'
                 WHEN CE.ISSUER_RAT IS NULL 
                 THEN ''
                 ELSE 'B-以下' 
             end as J020028,-- 028.基础资产客户评级
null as J020029,-- 029.基础资产客户评级机构 -- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐
m3.GB_CODE as J020030,-- 030.基础资产客户行业类型  -- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐
CE.ISSUER_RAT as J020031, -- 031.基础资产外部评级-- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐
null,-- 032.基础资产评级机构
null,-- 109.基础资产内部评级
null,-- 033.基础资产最终投向类型
null,-- 034.基础资产最终投向行业类型
null , -- 087.含权类型 待业务给口径
'0' as J020103, -- case when t.org_num ='009820' then '0' else ''end ,-- 103.存在变现障碍标识（数仓反馈债券类的债券编号老信贷   有，新信贷没有接）
null,-- 104.备注
TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),-- 105.采集日期
TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),-- 装入数据日期
t.ORG_NUM,
'同业资金业务',-- 业务条线
 t.ORG_NUM,
'0'  ,   -- 106.是否投向市场化债转股相关产品  0.否，1.是
'0'  ,   -- 110.是否投向产业基金  0.否，1.是
null -- 111.被持有股权企业客户ID
from smtmods.L_ACCT_FUND_MMFUND t -- 资金往来信息表
LEFT JOIN (select * from (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.ECIF_CUST_ID ORDER BY A.ECIF_CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') B1
             ON T.CUST_ID = B1.ECIF_CUST_ID
LEFT JOIN (select * from (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') B2
             ON T.CUST_ID = B2.CUST_ID
LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表
       ON T.ORG_NUM = ORG.ORG_NUM
      AND ORG.DATA_DATE = I_DATE
LEFT JOIN SMTMODS.L_CUST_ALL T1 
       ON T.CUST_ID=T1.CUST_ID 
      AND T1.DATA_DATE=I_DATE 
LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M1 
       ON M1.L_CODE_TABLE_CODE = 'V0003'
      AND NVL(B1.DEPT_TYPE,B2.DEPT_TYPE) = M1.L_CODE
LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M2
       ON M2.L_CODE_TABLE_CODE = 'V0004' 
      AND NVL(B1.DEPT_TYPE,B2.DEPT_TYPE) = M2.L_CODE
LEFT JOIN SMTMODS.L_CUST_EXTERNAL_INFO CE 
       ON CE.DATA_DATE=I_DATE 
      AND (T.CUST_ID=CE.CUST_ID OR B2.ECIF_CUST_ID=CE.CUST_ID)
LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M3 
       ON M3.L_CODE_TABLE_CODE = 'V0005' 
      AND CE.INDS_INVEST = M3.L_CODE
LEFT JOIN SMTMODS.L_FINA_INNER T2 
       ON T2.STAT_SUB_NUM  = SUBSTR(T.GL_ITEM_CODE ,1,6) 
      AND T2.ORG_NUM ='990000' 
      AND T2.DATA_DATE=I_DATE 
LEFT JOIN SMTMODS.L_PUBL_ORG_BRA ORG1
       ON T.ORG_NUM = ORG1.ORG_NUM
      AND ORG1.DATA_DATE = I_DATE
WHERE -- 2.0ZDSJ H 
          (SUBSTR(T.GL_ITEM_CODE, '1', '4') = '2003'-- 拆入
           OR T.GL_ITEM_CODE = '20030105'            -- 拆入
           OR ( SUBSTR(T.GL_ITEM_CODE, '1', '4') = '1302' AND T.ACCT_TYP = '10201')  -- 拆出
           OR T.GL_ITEM_CODE IN ('13020102','13020104','13020106','20030102','20030104','20030106')-- 同业借入  同业借出
           OR T.GL_ITEM_CODE LIKE '101101%'OR T.GL_ITEM_CODE LIKE '101102%' OR T.GL_ITEM_CODE LIKE '1031%' -- 存放同业活期和存放同业定期
           OR SUBSTR(T.GL_ITEM_CODE, '1', '4') = '2012'   -- 同业存放
           OR T.GL_ITEM_CODE = '20040101' -- 向央行借款
           )
         --  AND T.DATA_DATE=I_DATE  AND T.BALANCE<>'0'AND T.MATURE_DATE>=I_DATE
           AND T.DATA_DATE=I_DATE 
		   -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
           AND T.MATURE_DATE >= SUBSTR(I_DATE,1,4)||'0101' 
           AND (((T.ACCT_CLDATE > I_DATE OR T.ACCT_CLDATE IS NULL) AND T.BALANCE > 0) OR (T.ACCT_CLDATE >= SUBSTR(I_DATE,1,4)||'0101' AND T.BALANCE = 0) OR T.ACCRUAL <> 0) 
         --  AND (T.BALANCE<>'0' OR T.ACCRUAL <> 0)  -- ALTER BY DJH 20240719 有利息无本金数据也加进来
           ;-- 拆出

    
  
    COMMIT;


-- 同业存单发行  ----
INSERT  INTO T_9_2  (
 J020001,   -- 001.投资标的      
   J020002,   -- 002.投资标的名称
   J020003,   -- 003.机构
   J020004,   -- 004.发行价格
   J020005,   -- 005.发行规模
   J020006,   -- 006.发行机构名称
   J020007,   -- 007.发行机构代码
   J020008,   -- 008.发行机构大类
   J020107,   -- 107.发行机构小类
   J020009,   -- 009.发行国家地区
   J020108,   -- 108.交易流通场所
   J020010,   -- 010.投资标的币种
   J020011,   -- 011.投资标的代码
   J020014,   -- 014.起息日期
   J020015,   -- 015.发行日期
   J020016,   -- 016.到期日期
   J020017,   -- 017.投资标的利率类型
   J020018,   -- 018.利率/收益率
   J020019,   -- 019.最近评估价格
   J020020,   -- 020.评估价格日期
   J020021,   -- 021.投融资标的类别
   J020022,   -- 022.资产风险权重
   J020026,   -- 026.基础资产客户名称
   J020027,   -- 027.基础资产客户国家
   J020028,   -- 028.基础资产客户评级
   J020029,   -- 029.基础资产客户评级机构
   J020030,   -- 030.基础资产客户行业类型
   J020031,   -- 031.基础资产外部评级
   J020032,   -- 032.基础资产评级机构
   J020109,   -- 109.基础资产内部评级
   J020033,   -- 033.基础资产最终投向类型
   J020034,   -- 034.基础资产最终投向行业类型
   J020087,   -- 087.含权类型
   J020103,   -- 103.存在变现障碍标识
   J020104,   -- 104.备注
   J020105,   -- 105.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID,     -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID,
   J020106,   -- 106.是否投向市场化债转股相关产品
   J020110,   -- 110.是否投向产业基金
   J020111    -- 111.被持有股权企业客户ID
) select 
   J020001,   -- 001.投资标的      
   J020002,   -- 002.投资标的名称
   J020003,   -- 003.机构
   J020004,   -- 004.发行价格
   J020005,   -- 005.发行规模
   J020006,   -- 006.发行机构名称
   J020007,   -- 007.发行机构代码
   J020008,   -- 008.发行机构大类
   J020107,   -- 107.发行机构小类
   J020009,   -- 009.发行国家地区
   J020108,   -- 108.交易流通场所
   J020010,   -- 010.投资标的币种
   J020011,   -- 011.投资标的代码
   J020014,   -- 014.起息日期
   J020015,   -- 015.发行日期
   J020016,   -- 016.到期日期
   J020017,   -- 017.投资标的利率类型
   J020018,   -- 018.利率/收益率
   J020019,   -- 019.最近评估价格
   J020020,   -- 020.评估价格日期
   J020021,   -- 021.投融资标的类别
   J020022,   -- 022.资产风险权重
   J020026,   -- 026.基础资产客户名称
   J020027,   -- 027.基础资产客户国家
   J020028,   -- 028.基础资产客户评级
   J020029,   -- 029.基础资产客户评级机构
   J020030,   -- 030.基础资产客户行业类型
   J020031,   -- 031.基础资产外部评级
   J020032,   -- 032.基础资产评级机构
   J020109,   -- 109.基础资产内部评级
   J020033,   -- 033.基础资产最终投向类型
   J020034,   -- 034.基础资产最终投向行业类型
   J020087,   -- 087.含权类型
   J020103,   -- 103.存在变现障碍标识
   J020104,   -- 104.备注
   J020105,   -- 105.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID,     -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID,
   J020106,   -- 106.是否投向市场化债转股相关产品
   J020110,   -- 110.是否投向产业基金
   J020111    -- 111.被持有股权企业客户ID
FROM (select 
       T.CDS_NO AS J020001,-- 001.投资标的
       T2.SUBJECT_NAM AS J020002, -- 002.投资标的名称
       ORG.ORG_ID AS J020003 ,  -- 003.机构 
       T2.ISSUER_PRICE AS J020004, -- 004.发行价格
       T2.PROCEEDS_NUM*100000000 AS J020005,-- 005.发行规模
       '吉林银行股份有限公司'AS J020006,-- 006.发行机构名称
       '9122010170255776XN'AS J020007, -- 007.发行机构代码
       '01'   AS J020008,-- 008.发行机构大类   -- 2.0 ZDSJ H
       '010401'AS J020107,-- 107.发行机构小类
       'CHN'  AS J020009,-- 009.发行国家地区
       '01'   AS J020108, -- 108.交易流通场所
       'CNY'  AS J020010,-- 010.投资标的币种
       T.CDS_NO AS J020011,-- 011.投资标的代码
       TO_CHAR(TO_DATE(T2.INT_ST_DT,'YYYYMMDD'),'YYYY-MM-DD') AS J020014, -- 014.起息日期
       TO_CHAR(TO_DATE(T2.ISSU_DT,'YYYYMMDD'),'YYYY-MM-DD') AS J020015,-- 015.发行日期
       TO_CHAR(TO_DATE(T2.MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD') AS J020016, -- 016.到期日期
       '02'   AS J020017,-- 017.投资标的利率类型  -- 20241024_ZHOULP_JLBA202408290021_金市需求_业务姚司桐  -- 同业常城同意默认02；金市此需求文档标注默认02
       T2.INT_RAT AS J020018,-- -- 018.利率/收益率  加字段 
       T2.CURRENT_EVALUATE_PRICE AS J020019, -- 019.最近评估价格
       TO_CHAR(TO_DATE(T2.EVALUATE_DT,'YYYYMMDD'),'YYYY-MM-DD') AS J020020,-- 020.评估价格日期
       '0210' AS J020021,-- 021.投融资标的类别  -- 0901
       NULL   AS J020022,-- 022.资产风险权重
       T3.CONT_PARTY_NAME AS J020026,-- 026.基础资产客户名称
       'CHN'  AS J020027,-- 027.基础资产客户国家
       T3.CTPY_RISK_RATING AS J020028,-- 028.基础资产客户评级  20250213
       T3.CTPY_RATING_ORG  AS J020029,-- 029.基础资产客户评级机构 20250213
       'J6621'AS J020030,-- 030.基础资产客户行业类型
       'AAA'  AS J020031, -- 031.基础资产外部评级
       '联合资信评估股份有限公司'AS J020032,-- 032.基础资产评级机构
       NULL AS J020109,-- 109.基础资产内部评级
       NULL AS J020033,-- 033.基础资产最终投向类型
       NULL AS J020034,-- 034.基础资产最终投向行业类型
       NULL AS J020087, -- 087.含权类型 待业务给口径
       '0'  AS J020103,-- 103.存在变现障碍标识（数仓反馈债券类的债券编号老信贷   有，新信贷没有接）
       NULL AS J020104,-- 104.备注
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')AS J020105,-- 105.采集日期
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')AS DIS_DATA_DATE ,-- 装入数据日期
       T.ORG_NUM AS DIS_BANK_ID,
       '存单发行'  AS DIS_DEPT,-- 业务条线
        T.ORG_NUM AS DEPARTMENT_ID,
       '0'  AS J020106,   -- 106.是否投向市场化债转股相关产品  0.否，1.是
       '0'  AS J020110,   -- 110.是否投向产业基金  0.否，1.是
       NULL AS J020111, -- 111.被持有股权企业客户ID
       ROW_NUMBER() OVER(PARTITION BY T.CDS_NO ORDER BY T2.EVALUATE_DT desc,T3.CTPY_RISK_RATING ) AS RN
  FROM SMTMODS.L_ACCT_FUND_CDS_BAL T -- 存单投资与发行信息表
  LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表
    ON T.ORG_NUM = ORG.ORG_NUM
   AND ORG.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_AGRE_OTHER_SUBJECT_INFO T2 
    ON T.CDS_NO=T2.SUBJECT_CD 
   AND T2.DATA_DATE=I_DATE 
  LEFT JOIN  ( SELECT DISTINCT t3.CTPY_RISK_RATING AS CTPY_RISK_RATING,
                               t3.CTPY_RATING_ORG  AS CTPY_RATING_ORG,
                               T3.CONT_PARTY_NAME  AS CONT_PARTY_NAME,
                               t3.CONT_PARTY_CODE  AS CONT_PARTY_CODE
                FROM SMTMODS.L_TRAN_FUND_FX T3 -- 资金交易信息表  
               WHERE T3.DATA_DATE = I_DATE ) T3
    ON T.CONT_PARTY_CODE = T3.CONT_PARTY_CODE 
 WHERE T.PRODUCT_PROP IN ('B')
   AND T.DATA_DATE=I_DATE 
   AND (T.FACE_VAL<>'0'
       OR T.MATURITY_DT >= SUBSTR(I_DATE,1,4)||'0101' ) -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
   AND T.ORG_NUM='009820'
)T3 WHERE T3.RN=1;
commit;




-- 同业存单投资  ----
INSERT INTO T_9_2  (
   J020001,   -- 001.投资标的      
   J020002,   -- 002.投资标的名称
   J020003,   -- 003.机构
   J020004,   -- 004.发行价格
   J020005,   -- 005.发行规模
   J020006,   -- 006.发行机构名称
   J020007,   -- 007.发行机构代码
   J020008,   -- 008.发行机构大类
   J020107,   -- 107.发行机构小类
   J020009,   -- 009.发行国家地区
   J020108,   -- 108.交易流通场所
   J020010,   -- 010.投资标的币种
   J020011,   -- 011.投资标的代码
   J020014,   -- 014.起息日期
   J020015,   -- 015.发行日期
   J020016,   -- 016.到期日期
   J020017,   -- 017.投资标的利率类型
   J020018,   -- 018.利率/收益率
   J020019,   -- 019.最近评估价格
   J020020,   -- 020.评估价格日期
   J020021,   -- 021.投融资标的类别
   J020022,   -- 022.资产风险权重
   J020026,   -- 026.基础资产客户名称
   J020027,   -- 027.基础资产客户国家
   J020028,   -- 028.基础资产客户评级
   J020029,   -- 029.基础资产客户评级机构
   J020030,   -- 030.基础资产客户行业类型
   J020031,   -- 031.基础资产外部评级
   J020032,   -- 032.基础资产评级机构
   J020109,   -- 109.基础资产内部评级
   J020033,   -- 033.基础资产最终投向类型
   J020034,   -- 034.基础资产最终投向行业类型
   J020087,   -- 087.含权类型
   J020103,   -- 103.存在变现障碍标识
   J020104,   -- 104.备注
   J020105,   -- 105.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID,     -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID,
   J020106,   -- 106.是否投向市场化债转股相关产品
   J020110,   -- 110.是否投向产业基金
   J020111    -- 111.被持有股权企业客户ID
) select 
J020001,   -- 001.投资标的      
   J020002,   -- 002.投资标的名称
   J020003,   -- 003.机构
   J020004,   -- 004.发行价格
   J020005,   -- 005.发行规模
   J020006,   -- 006.发行机构名称
   J020007,   -- 007.发行机构代码
   J020008,   -- 008.发行机构大类
   J020107,   -- 107.发行机构小类
   J020009,   -- 009.发行国家地区
   J020108,   -- 108.交易流通场所
   J020010,   -- 010.投资标的币种
   J020011,   -- 011.投资标的代码
   J020014,   -- 014.起息日期
   J020015,   -- 015.发行日期
   J020016,   -- 016.到期日期
   J020017,   -- 017.投资标的利率类型
   J020018,   -- 018.利率/收益率
   J020019,   -- 019.最近评估价格
   J020020,   -- 020.评估价格日期
   J020021,   -- 021.投融资标的类别
   J020022,   -- 022.资产风险权重
   J020026,   -- 026.基础资产客户名称
   J020027,   -- 027.基础资产客户国家
   J020028,   -- 028.基础资产客户评级
   J020029,   -- 029.基础资产客户评级机构
   J020030,   -- 030.基础资产客户行业类型
   J020031,   -- 031.基础资产外部评级
   J020032,   -- 032.基础资产评级机构
   J020109,   -- 109.基础资产内部评级
   J020033,   -- 033.基础资产最终投向类型
   J020034,   -- 034.基础资产最终投向行业类型
   J020087,   -- 087.含权类型
   J020103,   -- 103.存在变现障碍标识
   J020104,   -- 104.备注
   J020105,   -- 105.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID,     -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID,
   J020106,   -- 106.是否投向市场化债转股相关产品
   J020110,   -- 110.是否投向产业基金
   J020111    -- 111.被持有股权企业客户ID
from (select 
t.CDS_NO as J020001,-- 001.投资标的
t2.SUBJECT_NAM as J020002, -- 002.投资标的名称
ORG.ORG_ID as J020003,  -- 003.机构 
t2.ISSUER_PRICE as J020004 , -- 004.发行价格
t2.PROCEEDS_NUM*100000000 as J020005,-- 005.发行规模 
NVL(t2.ISSU_ORG_NAM,T3.CUST_NAM) as J020006,-- 006.发行机构名称 1212
case when t.ORG_NUM='009804' then t2.ISSUER_ID_NO else T3.ID_NO end  as J020007, -- 007.发行机构代码 1212  -- 2.0 zdsj h
-- 20241212 JLBA202409290003_关于一表通校验结果治理的需求（同业金融部）jlf
-- 20241024_zhoulp_JLBA202409030008_交易对手大类小类
case when m1.GB_CODE  is not null then m1.GB_CODE
     when NVL(t2.ISSU_ORG_NAM,T3.CUST_NAM) like '%银行%' then '01' -- [20250619][巴启威][JLBA202505280002][吴大为]：发行机构大类增加名称映射。'%银行%' 映射成对应码值01
     when NVL(t2.ISSU_ORG_NAM,T3.CUST_NAM) like '%财政部%' then '09'
     when NVL(t2.ISSU_ORG_NAM,T3.CUST_NAM) like '%政府%'   then '09'
     when NVL(t2.ISSU_ORG_NAM,T3.CUST_NAM) like '%财政厅%' then '09'
     when NVL(t2.ISSU_ORG_NAM,T3.CUST_NAM) like '%财政局%' then '09'
     when NVL(t2.ISSU_ORG_NAM,T3.CUST_NAM) like '%理财%公司%' then '01'
     when ce.corp_propty in ('0805010100','0805010200') then '10' -- 国有企业
     when ce.corp_propty in ('0805040000') then '10' -- 集体企业
     when ce.corp_propty in ('0805060000') then '10' -- 其他企业
     when ce.corp_propty in ('0805030100') then '10' -- 中外合资企业
     when NVL(t2.ISSU_ORG_NAM,T3.CUST_NAM) like '%有限责任公司%' then '10'
     when NVL(t2.ISSU_ORG_NAM,T3.CUST_NAM) like '%股份有限公司%' then '10'
end as J020008, -- 008.发行机构大类
case when m2.GB_CODE  is not null then m2.GB_CODE
     when NVL(t2.ISSU_ORG_NAM,T3.CUST_NAM) like '%财政部%' then '090501'
     when NVL(t2.ISSU_ORG_NAM,T3.CUST_NAM) like '%政府%'   then '090601'
     when NVL(t2.ISSU_ORG_NAM,T3.CUST_NAM) like '%财政厅%' then '090601'
     when NVL(t2.ISSU_ORG_NAM,T3.CUST_NAM) like '%财政局%' then '090601'
     when NVL(t2.ISSU_ORG_NAM,T3.CUST_NAM) like '%理财%公司%' then '010908'
     when ce.corp_propty in ('0805010100','0805010200') then '100101' -- 国有企业
     when ce.corp_propty in ('0805040000') then '100102' -- 集体企业
     when ce.corp_propty in ('0805060000') then '100108' -- 其他企业
     when ce.corp_propty in ('0805030100') then '100301' -- 中外合资企业
     when NVL(t2.ISSU_ORG_NAM,T3.CUST_NAM) like '%有限责任公司%' then '100105'
     when NVL(t2.ISSU_ORG_NAM,T3.CUST_NAM) like '%股份有限公司%' then '100106'
end as J020107, -- 107.发行机构小类
'CHN' as J020009,-- 009.发行国家地区
null as J020108, -- 108.交易流通场所
t2.CURR_CD as J020010,-- 010.投资标的币种
t.CDS_NO as J020011,-- 011.投资标的代码   -- 2.0 zdsj h
TO_CHAR(TO_DATE(t2.INT_ST_DT,'YYYYMMDD'),'YYYY-MM-DD') as J020014, -- 014.起息日期
TO_CHAR(TO_DATE(t2.ISSU_DT,'YYYYMMDD'),'YYYY-MM-DD') as J020015,-- 015.发行日期
TO_CHAR(TO_DATE(t2.MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD') as J020016, -- 016.到期日期
'02' as J020017,-- 017.投资标的利率类型  -- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐  -- 同业常城同意默认02；金市此需求文档标注默认02
t2.INT_RAT as J020018,-- -- 018.利率/收益率  加字段 
t2.CURRENT_EVALUATE_PRICE as J020019, -- 019.最近评估价格
TO_CHAR(TO_DATE(t2.EVALUATE_DT,'YYYYMMDD'),'YYYY-MM-DD') as  J020020,-- 020.评估价格日期
'0220' as J020021,-- 021.投融资标的类别
null as J020022,-- 022.资产风险权重
nvl(t3.CUST_NAM,t.CUST_ID) as J020026,-- 026.基础资产客户名称    -- 2.0 zdsj h
'CHN' as J020027,-- 027.基础资产客户国家  -- 2.0 zdsj h
-- null as J020028,-- 028.基础资产客户评级
CASE WHEN T2.ISSUER_LEV IN ('AAA', 'AA+', 'AA', 'AA-') 
                 THEN 'AA-以上（含AA-）'
                 WHEN T2.ISSUER_LEV IN ('BBB-', 'BBB', 'BBB+', 'A-', 'A', 'A+') 
                 THEN 'A+ 至 BBB-（含BBB-）'
                 WHEN T2.ISSUER_LEV IN ('BB-', 'BB', 'BB+', 'B+', 'B', 'B-') 
                 THEN 'BB+ 至 B-（含B-）'
                 WHEN T2.ISSUER_LEV IS NULL 
                 THEN ''
                 ELSE nvl(t4.CTPY_RISK_RATING,'B-以下') 
END as J020028,-- 028.基础资产客户评级 -- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐
T4.CTPY_RATING_ORG  AS J020029,-- 029.基础资产客户评级机构 20250213
m3.GB_CODE as J020030,-- 030.基础资产客户行业类型
T2.ISSUER_LEV as J020031, -- 031.基础资产外部评级 -- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐
null as J020032,-- 032.基础资产评级机构
null as J020109,-- 109.基础资产内部评级
null as J020033,-- 033.基础资产最终投向类型
null as J020034,-- 034.基础资产最终投向行业类型
null as J020087, -- 087.含权类型 待业务给口径
case when t.org_num='009820' then '0' when nvl(t.COLL_AMT,0)>0 then '1' else '0' end as J020103,-- 103.存在变现障碍标识 0-否 1-是
null as J020104,-- 104.备注
TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')as J020105 ,-- 105.采集日期
TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')as DIS_DATA_DATE,-- 装入数据日期
t.ORG_NUM as DIS_BANK_ID,
'存单投资' as DIS_DEPT,-- 业务条线
t.ORG_NUM as DEPARTMENT_ID,
'0'  as J020106,   -- 106.是否投向市场化债转股相关产品  0.否，1.是
'0'  as J020110,   -- 110.是否投向产业基金  0.否，1.是
null as J020111, -- 111.被持有股权企业客户ID
ROW_NUMBER() OVER(PARTITION BY t.CDS_NO,t.ORG_NUM ORDER by t2.EVALUATE_DT desc) AS RN
from smtmods.l_acct_fund_cds_bal t 
LEFT JOIN (select * from (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.ECIF_CUST_ID ORDER BY A.ECIF_CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') B1
             ON T.CUST_ID = B1.ECIF_CUST_ID
    LEFT JOIN (select * from (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') B2
             ON T.CUST_ID = B2.CUST_ID
             
LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表
   ON T.ORG_NUM = ORG.ORG_NUM
  AND ORG.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_AGRE_OTHER_SUBJECT_INFO T2 ON T.CDS_NO=T2.SUBJECT_CD AND T2.DATA_DATE=I_DATE
LEFT JOIN SMTMODS.L_CUST_ALL T3 
ON T.CUST_ID=T3.CUST_ID 
AND T3.DATA_DATE=I_DATE 
LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M1 
ON M1.L_CODE_TABLE_CODE = 'V0003' 
AND NVL(B1.DEPT_TYPE,B2.DEPT_TYPE) = M1.L_CODE
LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M2 
ON M2.L_CODE_TABLE_CODE = 'V0004' 
AND NVL(B1.DEPT_TYPE,B2.DEPT_TYPE) = M2.L_CODE
left join SMTMODS.L_CUST_EXTERNAL_INFO ce on CE.DATA_DATE=I_DATE and (t.cust_id=ce.CUST_ID or b2.ecif_cust_id=ce.CUST_ID)
left join ybt_datacore.m_dict_codetable m3 on m3.L_CODE_TABLE_CODE = 'V0005' and ce.INDS_INVEST = m3.l_code
LEFT JOIN  ( SELECT DISTINCT t3.CTPY_RISK_RATING AS CTPY_RISK_RATING,
                               t3.CTPY_RATING_ORG  AS CTPY_RATING_ORG,
                               T3.CONT_PARTY_NAME  AS CONT_PARTY_NAME,
                               t3.CONT_PARTY_CODE  AS CONT_PARTY_CODE
                FROM SMTMODS.L_TRAN_FUND_FX T3 -- 资金交易信息表  
               WHERE T3.DATA_DATE = I_DATE ) T4
    ON T.CONT_PARTY_CODE = T4.CONT_PARTY_CODE  -- 20250213
where  t.PRODUCT_PROP in ('A')and   t.DATA_DATE=I_DATE 
-- and t.FACE_VAL<>'0'  -- 20250731 因校验公式YBT_JYH08-28 问题 同步8.8
  and  t.MATURITY_DT >= SUBSTR(I_DATE,1,4)||'0101' -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
)t3 where t3.RN=1;
commit;

/*


--  金融市场部投资标的101788002，011754134，031672037，151408，151123违约债，根据业务老师要求做固定报送
INSERT  INTO T_9_2  (
 J020001,   -- 001.投资标的      
   J020002,   -- 002.投资标的名称
   J020003,   -- 003.机构
   J020004,   -- 004.发行价格
   J020005,   -- 005.发行规模
   J020006,   -- 006.发行机构名称
   J020007,   -- 007.发行机构代码
   J020008,   -- 008.发行机构大类
   J020107,   -- 107.发行机构小类
   J020009,   -- 009.发行国家地区
   J020108,   -- 108.交易流通场所
   J020010,   -- 010.投资标的币种
   J020011,   -- 011.投资标的代码
   J020014,   -- 014.起息日期
   J020015,   -- 015.发行日期
   J020016,   -- 016.到期日期
   J020017,   -- 017.投资标的利率类型
   J020018,   -- 018.利率/收益率
   J020019,   -- 019.最近评估价格
   J020020,   -- 020.评估价格日期
   J020021,   -- 021.投融资标的类别
   J020022,   -- 022.资产风险权重
   J020026,   -- 026.基础资产客户名称
   J020027,   -- 027.基础资产客户国家
   J020028,   -- 028.基础资产客户评级
   J020029,   -- 029.基础资产客户评级机构
   J020030,   -- 030.基础资产客户行业类型
   J020031,   -- 031.基础资产外部评级
   J020032,   -- 032.基础资产评级机构
   J020109,   -- 109.基础资产内部评级
   J020033,   -- 033.基础资产最终投向类型
   J020034,   -- 034.基础资产最终投向行业类型
   J020087,   -- 087.含权类型
   J020103,   -- 103.存在变现障碍标识
   J020104,   -- 104.备注
   J020105,   -- 105.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID ,    -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID
) select 
J020001,   -- 001.投资标的      
   J020002,   -- 002.投资标的名称
   J020003,   -- 003.机构
   J020004,   -- 004.发行价格
   J020005,   -- 005.发行规模
   J020006,   -- 006.发行机构名称
   J020007,   -- 007.发行机构代码
   J020008,   -- 008.发行机构大类
   J020107,   -- 107.发行机构小类
   J020009,   -- 009.发行国家地区
   J020108,   -- 108.交易流通场所
   J020010,   -- 010.投资标的币种
   J020011,   -- 011.投资标的代码
   J020014,   -- 014.起息日期
   J020015,   -- 015.发行日期
   J020016,   -- 016.到期日期
   J020017,   -- 017.投资标的利率类型
   J020018,   -- 018.利率/收益率
   J020019,   -- 019.最近评估价格
   J020020,   -- 020.评估价格日期
   J020021,   -- 021.投融资标的类别
   J020022,   -- 022.资产风险权重
   J020026,   -- 026.基础资产客户名称
   J020027,   -- 027.基础资产客户国家
   J020028,   -- 028.基础资产客户评级
   J020029,   -- 029.基础资产客户评级机构
   J020030,   -- 030.基础资产客户行业类型
   J020031,   -- 031.基础资产外部评级
   J020032,   -- 032.基础资产评级机构
   J020109,   -- 109.基础资产内部评级
   J020033,   -- 033.基础资产最终投向类型
   J020034,   -- 034.基础资产最终投向行业类型
   J020087,   -- 087.含权类型
   J020103,   -- 103.存在变现障碍标识
   J020104,   -- 104.备注
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')as J020105 ,-- 105.采集日期
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')as DIS_DATA_DATE,-- 装入数据日期
   '009804' as DIS_BANK_ID,
   '' as DIS_DEPT,-- 业务条线
   '009804' as DEPARTMENT_ID
from  t_9_2_gdbs;
*/


-- ADD BY WJB 20240709  转股协议存款 发行个人大额存单 发行单位大额存单

INSERT  INTO T_9_2  (
 J020001,   -- 001.投资标的      
   J020002,   -- 002.投资标的名称
   J020003,   -- 003.机构
   J020004,   -- 004.发行价格
   J020005,   -- 005.发行规模
   J020006,   -- 006.发行机构名称
   J020007,   -- 007.发行机构代码
   J020008,   -- 008.发行机构大类
   J020107,   -- 107.发行机构小类
   J020009,   -- 009.发行国家地区
   J020108,   -- 108.交易流通场所
   J020010,   -- 010.投资标的币种
   J020011,   -- 011.投资标的代码
   J020014,   -- 014.起息日期
   J020015,   -- 015.发行日期
   J020016,   -- 016.到期日期
   J020017,   -- 017.投资标的利率类型
   J020018,   -- 018.利率/收益率
   J020019,   -- 019.最近评估价格
   J020020,   -- 020.评估价格日期
   J020021,   -- 021.投融资标的类别
   J020022,   -- 022.资产风险权重
   J020026,   -- 026.基础资产客户名称
   J020027,   -- 027.基础资产客户国家
   J020028,   -- 028.基础资产客户评级
   J020029,   -- 029.基础资产客户评级机构
   J020030,   -- 030.基础资产客户行业类型
   J020031,   -- 031.基础资产外部评级
   J020032,   -- 032.基础资产评级机构
   J020109,   -- 109.基础资产内部评级
   J020033,   -- 033.基础资产最终投向类型
   J020034,   -- 034.基础资产最终投向行业类型
   J020087,   -- 087.含权类型
   J020103,   -- 103.存在变现障碍标识
   J020104,   -- 104.备注
   J020105,   -- 105.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID,     -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID,
   J020106,   -- 106.是否投向市场化债转股相关产品
   J020110,   -- 110.是否投向产业基金
   J020111    -- 111.被持有股权企业客户ID
) select 
 t.ACCT_NUM ,-- 001.投资标的  
 CASE when  T.gl_item_code = '20110211'  then t.cust_id||'转股协议存款'
      when  T.gl_item_code in ('20110113','20110208') then t.cust_id||'大额存单'
      end ,-- 002.投资标的名称
ORG.ORG_ID,-- -- 003.机构
T.OPEN_ACCT_AMT, -- 004.发行价格
T.OPEN_ACCT_AMT, -- 005.发行规模
NVL(ca.CUST_NAM,t.cust_id),       -- 006.发行机构名称 20241212
NVL(ca.ID_NO,t.ORG_NUM)  , -- 007.发行机构代码
'01' as J020008, -- 008.发行机构大类   -- 20241212
'010401' as J020107, -- 107.发行机构小类  -- 20241212
'CHN', -- 009.发行国家地区
'03' , -- 108.交易流通场所
t.CURR_CD , -- 010.投资标的币种
NULL , -- 011.投资标的代码     -- 
TO_CHAR(TO_DATE(t.ST_INT_DT,'YYYYMMDD'),'YYYY-MM-DD'),-- 014.起息日期
TO_CHAR(TO_DATE(t.ST_INT_DT,'YYYYMMDD'),'YYYY-MM-DD'),-- 015.发行日期
TO_CHAR(TO_DATE(t.MATUR_DATE,'YYYYMMDD'),'YYYY-MM-DD'),-- 016.到期日期
'02' ,-- 017.投资标的利率类型   康星无法判断是否是LPR -- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐  -- 同业常城同意默认02；金市此需求文档标注默认02
t.INT_RATE ,-- 018.利率/收益率
t.ACCT_BALANCE  ,-- 019.最近评估价格 加字段
TO_CHAR(TO_DATE(t.ST_INT_DT,'YYYYMMDD'),'YYYY-MM-DD'),-- 020.评估价格日期 加字段
'0890',-- 021.投融资标的类别
null,-- 022.资产风险权重 找RWA系统。
t.cust_id , -- 026.基础资产客户名称  20241212
'CHN' ,-- 027.基础资产客户国家 20241212
null,-- 028.基础资产客户评级
null,-- 029.基础资产客户评级机构
null,-- 030.基础资产客户行业类型
null, -- 031.基础资产外部评级
null,-- 032.基础资产评级机构
null,-- 109.基础资产内部评级
null,-- 033.基础资产最终投向类型
null,-- 034.基础资产最终投向行业类型
null , -- 087.含权类型 待业务给口径
'0',-- 103.存在变现障碍标识（数仓反馈债券类的债券编号老信贷   有，新信贷没有接）
null,-- 104.备注
TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),-- 105.采集日期
TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),-- 装入数据日期
t.ORG_NUM,
'转股协议存款 发行个人大额存单 发行单位大额存单',-- 业务条线
 t.ORG_NUM,
'0'  ,   -- 106.是否投向市场化债转股相关产品  0.否，1.是
'0'  ,   -- 110.是否投向产业基金  0.否，1.是
null -- 111.被持有股权企业客户ID
 from smtmods.L_ACCT_DEPOSIT t 
 LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表
   ON T.ORG_NUM = ORG.ORG_NUM
  AND ORG.DATA_DATE = I_DATE
  left join smtmods.l_cust_all ca on ca.DATA_DATE=I_DATE and t.cust_id=ca.cust_id
  left join ybt_datacore.m_dict_codetable m1 on m1.L_CODE_TABLE_CODE = 'V0003' and ca.DEPT_TYPE = m1.l_code
  left join ybt_datacore.m_dict_codetable m2 on m2.L_CODE_TABLE_CODE = 'V0004' and ca.DEPT_TYPE = m2.l_code
WHERE T.DATA_DATE = I_DATE 
  AND T.GL_ITEM_CODE IN ('20110211','20110113','20110208')
  and (T.ACCT_BALANCE > 0
      OR NVL(T.ACCT_CLDATE,T.MATUR_DATE) >= SUBSTR(I_DATE,1,4)||'0101' -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
	  );

 CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB); 
 
 
     #4.插入数据
 SET P_START_DT = NOW();
 SET P_STEP_NO = P_STEP_NO + 1;
 SET P_DESCB = '债券发行数据插入';
 -- 20250116 配合8.7新增债券发行部分
 -- 债券发行
 INSERT  INTO T_9_2  (
   J020001,   -- 001.投资标的      
   J020002,   -- 002.投资标的名称
   J020003,   -- 003.机构
   J020004,   -- 004.发行价格
   J020005,   -- 005.发行规模
   J020006,   -- 006.发行机构名称
   J020007,   -- 007.发行机构代码
   J020008,   -- 008.发行机构大类
   J020107,   -- 107.发行机构小类
   J020009,   -- 009.发行国家地区
   J020108,   -- 108.交易流通场所
   J020010,   -- 010.投资标的币种
   J020011,   -- 011.投资标的代码
   J020014,   -- 014.起息日期
   J020015,   -- 015.发行日期
   J020016,   -- 016.到期日期
   J020017,   -- 017.投资标的利率类型
   J020018,   -- 018.利率/收益率
   J020019,   -- 019.最近评估价格
   J020020,   -- 020.评估价格日期
   J020021,   -- 021.投融资标的类别
   J020022,   -- 022.资产风险权重
   J020026,   -- 026.基础资产客户名称
   J020027,   -- 027.基础资产客户国家
   J020028,   -- 028.基础资产客户评级
   J020029,   -- 029.基础资产客户评级机构
   J020030,   -- 030.基础资产客户行业类型
   J020031,   -- 031.基础资产外部评级
   J020032,   -- 032.基础资产评级机构
   J020109,   -- 109.基础资产内部评级
   J020033,   -- 033.基础资产最终投向类型
   J020034,   -- 034.基础资产最终投向行业类型
   J020087,   -- 087.含权类型
   J020103,   -- 103.存在变现障碍标识
   J020104,   -- 104.备注
   J020105,   -- 105.采集日期
   J020106,   -- 106.是否投向市场化债转股相关产品
   J020110,   -- 110.是否投向产业基金
   J020111,    -- 111.被持有股权企业客户ID
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID,     -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID)
   
  SELECT 
   A.ACCT_NUM||A.REF_NUM AS J020001,   -- 001.投资标的      
   '2999009801债券发行吉林银行20211210'   AS J020002,   -- 002.投资标的名称
   ORG.ORG_ID            AS J020003,   -- 003.机构
   A.FACE_VAL            AS J020004,   -- 004.发行价格
   A.FACE_VAL            AS J020005,   -- 005.发行规模
   '吉林银行股份有限公司' AS J020006,   -- 006.发行机构名称
   '9122010170255776XN'  AS J020007,   -- 007.发行机构代码
   '01'                  AS J020008,   -- 008.发行机构大类
   '010401'              AS J020107,   -- 107.发行机构小类
   'CHN'                 AS J020009,   -- 009.发行国家地区
   '01'                  AS J020108,   -- 108.交易流通场所
   A.CURR_CD             AS J020010,   -- 010.投资标的币种
   A.REF_NUM             AS J020011,   -- 011.投资标的代码
   TO_CHAR(TO_DATE(A.INT_ST_DT,'YYYYMMDD'),'YYYY-MM-DD') AS J020014,   -- 014.起息日期
   TO_CHAR(TO_DATE(A.INT_ST_DT,'YYYYMMDD'),'YYYY-MM-DD') AS J020015,   -- 015.发行日期
   NVL(TO_CHAR(TO_DATE(A.MATURITY_DATE,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') AS J020016,   -- 016.到期日期
   '02'                  AS J020017,   -- 017.投资标的利率类型
   CASE WHEN ACCT_NUM='9250200002593015' THEN 2.57
        WHEN ACCT_NUM='9019827201000055' THEN 4                  
        WHEN ACCT_NUM='9250200002533422' THEN 2.85
        end              AS J020018,   -- 018.利率/收益率 吴大为20250624邮件提出修改  姜俐锋：9250200002593015 利率2.57  9019827201000055利率4 9250200002533422利率2.85
   A.FACE_VAL            AS J020019,   -- 019.最近评估价格
   TO_CHAR(TO_DATE(A.INT_ST_DT,'YYYYMMDD'),'YYYY-MM-DD') AS J020020,   -- 020.评估价格日期
   '0550'                AS J020021,   -- 021.投融资标的类别0230-债券借贷（债券融入）  吴大为20250624邮件提出修改  姜俐锋：将原0230-债券借贷修改为 0550-二级资本债
   NULL                  AS J020022,   -- 022.资产风险权重
   '吉林银行股份有限公司' AS J020026,   -- 026.基础资产客户名称
   'CHN'                 AS J020027,   -- 027.基础资产客户国家
   'AAA'                 AS J020028,   -- 028.基础资产客户评级
   NULL                  AS J020029,   -- 029.基础资产客户评级机构
   'J6621'               AS J020030,   -- 030.基础资产客户行业类型
   'AAA'                 AS J020031,   -- 031.基础资产外部评级
   '联合资信评估股份有限公司'  AS J020032,   -- 032.基础资产评级机构
   NULL                  AS J020109,   -- 109.基础资产内部评级
   NULL                  AS J020033,   -- 033.基础资产最终投向类型
   NULL                  AS J020034,   -- 034.基础资产最终投向行业类型
   NULL                  AS J020087,   -- 087.含权类型
   '0'                   AS J020103,   -- 103.存在变现障碍标识
   NULL                  AS J020104,   -- 104.备注
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS J020105,   -- 105.采集日期
   '0'                   AS J020106,   -- 106.是否投向市场化债转股相关产品
   '0'                   AS J020110,   -- 110.是否投向产业基金
   NULL                  AS J020111,    -- 111.被持有股权企业客户ID
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE, -- 装入数据日期
   A.ORG_NUM  AS DIS_BANK_ID,     -- 机构号
   '债券发行'  AS DIS_DEPT,       -- 业务条线
   '009806'   AS DEPARTMENT_ID
  FROM SMTMODS.L_ACCT_FUND_BOND_ISSUE A  -- 债券发行
  LEFT JOIN SMTMODS.L_FINA_INNER B
    ON A.GL_ITEM_CODE = B.STAT_SUB_NUM
   AND A.ORG_NUM = B.ORG_NUM
   AND B.DATA_DATE = I_DATE
  LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
    ON A.ORG_NUM = ORG.ORG_NUM
   AND ORG.DATA_DATE = I_DATE
 WHERE A.DATA_DATE = I_DATE
   AND SUBSTR(A.GL_ITEM_CODE, 1, 4) = '2502'
   AND (A.FACE_VAL <> 0 
       OR A.MATURITY_DATE >= SUBSTR(I_DATE,1,4)||'0101' -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
	   ); 
   
 
 
     #4.插入数据
 SET P_START_DT = NOW();
 SET P_STEP_NO = P_STEP_NO + 1;
 SET P_DESCB = '财管数据插入';

 INSERT  INTO T_9_2  (
   J020001,   -- 001.投资标的      
   J020002,   -- 002.投资标的名称
   J020003,   -- 003.机构
   J020004,   -- 004.发行价格
   J020005,   -- 005.发行规模
   J020006,   -- 006.发行机构名称
   J020007,   -- 007.发行机构代码
   J020008,   -- 008.发行机构大类
   J020107,   -- 107.发行机构小类
   J020009,   -- 009.发行国家地区
   J020108,   -- 108.交易流通场所
   J020010,   -- 010.投资标的币种
   J020011,   -- 011.投资标的代码
   J020014,   -- 014.起息日期
   J020015,   -- 015.发行日期
   J020016,   -- 016.到期日期
   J020017,   -- 017.投资标的利率类型
   J020018,   -- 018.利率/收益率
   J020019,   -- 019.最近评估价格
   J020020,   -- 020.评估价格日期
   J020021,   -- 021.投融资标的类别
   J020022,   -- 022.资产风险权重
   J020026,   -- 026.基础资产客户名称
   J020027,   -- 027.基础资产客户国家
   J020028,   -- 028.基础资产客户评级
   J020029,   -- 029.基础资产客户评级机构
   J020030,   -- 030.基础资产客户行业类型
   J020031,   -- 031.基础资产外部评级
   J020032,   -- 032.基础资产评级机构
   J020109,   -- 109.基础资产内部评级
   J020033,   -- 033.基础资产最终投向类型
   J020034,   -- 034.基础资产最终投向行业类型
   J020087,   -- 087.含权类型
   J020103,   -- 103.存在变现障碍标识
   J020104,   -- 104.备注
   J020105,   -- 105.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID,     -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID,
   J020106,   -- 106.是否投向市场化债转股相关产品
   J020110,   -- 110.是否投向产业基金
   J020111    -- 111.被持有股权企业客户ID
) select 
   J020001,   -- 001.投资标的      
   J020002,   -- 002.投资标的名称
   J020003,   -- 003.机构
   J020004,   -- 004.发行价格
   J020005,   -- 005.发行规模
   J020006,   -- 006.发行机构名称
   J020007,   -- 007.发行机构代码
   J020008,   -- 008.发行机构大类
   J020107,   -- 107.发行机构小类
   J020009,   -- 009.发行国家地区
   J020108,   -- 108.交易流通场所
   J020010,   -- 010.投资标的币种
   J020011,   -- 011.投资标的代码
   J020014,   -- 014.起息日期
   J020015,   -- 015.发行日期
   J020016,   -- 016.到期日期
   J020017,   -- 017.投资标的利率类型
   J020018,   -- 018.利率/收益率
   J020019,   -- 019.最近评估价格
   J020020,   -- 020.评估价格日期
   J020021,   -- 021.投融资标的类别
   J020022,   -- 022.资产风险权重
   J020026,   -- 026.基础资产客户名称
   J020027,   -- 027.基础资产客户国家
   J020028,   -- 028.基础资产客户评级
   J020029,   -- 029.基础资产客户评级机构
   J020030,   -- 030.基础资产客户行业类型
   J020031,   -- 031.基础资产外部评级
   J020032,   -- 032.基础资产评级机构
   J020109,   -- 109.基础资产内部评级
   J020033,   -- 033.基础资产最终投向类型
   J020034,   -- 034.基础资产最终投向行业类型
   J020087,   -- 087.含权类型
   J020103,   -- 103.存在变现障碍标识
   J020104,   -- 104.备注
   J020105,   -- 105.采集日期
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 装入数据日期
   '990000',     -- 机构号
   '股权投资',       -- 业务条线
   CASE WHEN  ywxt = '总行机关战略投资管理部' THEN  '0098ZT'
	    WHEN  ywxt = '总行机关运营管理部' THEN  '009801'
       END   ,
   J020106,
   J020110,
   J020111
 from smtmods.RSF_GQ_opr_imsjma t  where  t.DATA_DATE=I_DATE;
 commit;
 
    #5.RPA数据插入
 SET P_START_DT = NOW();
 SET P_STEP_NO = P_STEP_NO + 1;
 SET P_DESCB = 'RPA数据插入';
 
-- RPA 债转股
  INSERT  INTO T_9_2  (
   J020001,   -- 001.投资标的      
   J020002,   -- 002.投资标的名称
   J020003,   -- 003.机构
   J020004,   -- 004.发行价格
   J020005,   -- 005.发行规模
   J020006,   -- 006.发行机构名称
   J020007,   -- 007.发行机构代码
   J020008,   -- 008.发行机构大类
   J020107,   -- 107.发行机构小类
   J020009,   -- 009.发行国家地区
   J020108,   -- 108.交易流通场所
   J020010,   -- 010.投资标的币种
   J020011,   -- 011.投资标的代码
   J020014,   -- 014.起息日期
   J020015,   -- 015.发行日期
   J020016,   -- 016.到期日期
   J020017,   -- 017.投资标的利率类型
   J020018,   -- 018.利率/收益率
   J020019,   -- 019.最近评估价格
   J020020,   -- 020.评估价格日期
   J020021,   -- 021.投融资标的类别
   J020022,   -- 022.资产风险权重
   J020026,   -- 026.基础资产客户名称
   J020027,   -- 027.基础资产客户国家
   J020028,   -- 028.基础资产客户评级
   J020029,   -- 029.基础资产客户评级机构
   J020030,   -- 030.基础资产客户行业类型
   J020031,   -- 031.基础资产外部评级
   J020032,   -- 032.基础资产评级机构
   J020109,   -- 109.基础资产内部评级
   J020033,   -- 033.基础资产最终投向类型
   J020034,   -- 034.基础资产最终投向行业类型
   J020087,   -- 087.含权类型
   J020103,   -- 103.存在变现障碍标识
   J020104,   -- 104.备注
   J020105,   -- 105.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID ,    -- 机构号 
   DEPARTMENT_ID,
   J020106,   -- 106.是否投向市场化债转股相关产品
   J020110,   -- 110.是否投向产业基金
   J020111,    -- 111.被持有股权企业客户ID
      DIS_DEPT       -- 业务条线
)

SELECT
   J020001,   -- 001.投资标的      
   J020002,   -- 002.投资标的名称
   J020003,   -- 003.机构
   J020004,   -- 004.发行价格
   TO_NUMBER(REPLACE(J020005,',','')) AS J020005,   -- 005.发行规模
   J020006,   -- 006.发行机构名称
   J020007,   -- 007.发行机构代码
   SUBSTR ( J020008,INSTR(J020008,'[',1,1) + 1 , INSTR(J020008, ']',1 ) -INSTR(J020008,'[',1,1) - 1 ) AS J020008,   -- 008.发行机构大类
   SUBSTR ( J020107,INSTR(J020107,'[',1,1) + 1 , INSTR(J020107, ']',1 ) -INSTR(J020107,'[',1,1) - 1 ) AS J020107,   -- 107.发行机构小类
   SUBSTR ( J020009,INSTR(J020009,'[',1,1) + 1 , INSTR(J020009, ']',1 ) -INSTR(J020009,'[',1,1) - 1 ) AS J020009,   -- 009.发行国家地区
   SUBSTR ( J020108,INSTR(J020108,'[',1,1) + 1 , INSTR(J020108, ']',1 ) -INSTR(J020108,'[',1,1) - 1 ) AS J020108,   -- 108.交易流通场所
   SUBSTR ( J020010,INSTR(J020010,'[',1,1) + 1 , INSTR(J020010, ']',1 ) -INSTR(J020010,'[',1,1) - 1 ) AS J020010,   -- 010.投资标的币种
   J020011,   -- 011.投资标的代码
   J020014,   -- 014.起息日期
   J020015,   -- 015.发行日期
   J020016,   -- 016.到期日期
   SUBSTR ( J020017,INSTR(J020017,'[',1,1) + 1 , INSTR(J020017, ']',1 ) -INSTR(J020017,'[',1,1) - 1 ) AS J020017,   -- 017.投资标的利率类型
   TO_NUMBER(REPLACE(J020018,',','')) AS J020018,   -- 018.利率/收益率
   TO_NUMBER(REPLACE(J020019,',','')) AS J020019,   -- 019.最近评估价格
   J020020,   -- 020.评估价格日期
   J020021,   -- 021.投融资标的类别
   J020022,   -- 022.资产风险权重
   J020026,   -- 026.基础资产客户名称
   SUBSTR ( J020027,INSTR(J020027,'[',1,1) + 1 , INSTR(J020027, ']',1 ) -INSTR(J020027,'[',1,1) - 1 ) AS J020027,   -- 027.基础资产客户国家
   J020028,   -- 028.基础资产客户评级
   J020029,   -- 029.基础资产客户评级机构
   SUBSTR ( J020030,INSTR(J020030,'[',1,1) + 1 , INSTR(J020030, ']',1 ) -INSTR(J020030,'[',1,1) - 1 ) AS J020030,   -- 030.基础资产客户行业类型
   J020031,   -- 031.基础资产外部评级
   J020032,   -- 032.基础资产评级机构
   J020109,   -- 109.基础资产内部评级
   SUBSTR ( J020033,INSTR(J020033,'[',1,1) + 1 , INSTR(J020033, ']',1 ) -INSTR(J020033,'[',1,1) - 1 ) AS J020033,   -- 033.基础资产最终投向类型
   J020034,   -- 034.基础资产最终投向行业类型
   J020087,   -- 087.含权类型
   SUBSTR ( J020103,INSTR(J020103,'[',1,1) + 1 , INSTR(J020103, ']',1 ) -INSTR(J020103,'[',1,1) - 1 ) AS J020103,   -- 103.存在变现障碍标识
   J020104,   -- 104.备注
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DATA_DATE,   -- 105.采集日期
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE , -- 装入数据日期
   '990000' ,    -- 机构号 
   SUBSTR ( DEPARTMENT_ID,INSTR(DEPARTMENT_ID,'[',1,1) + 1 , INSTR(DEPARTMENT_ID, ']',1 ) -INSTR(DEPARTMENT_ID,'[',1,1) - 1 ) AS DEPARTMENT_ID,
   SUBSTR ( J020106,INSTR(J020106,'[',1,1) + 1 , INSTR(J020106, ']',1 ) -INSTR(J020106,'[',1,1) - 1 ) AS J020106,   -- 106.是否投向市场化债转股相关产品
   SUBSTR ( J020110,INSTR(J020110,'[',1,1) + 1 , INSTR(J020110, ']',1 ) -INSTR(J020110,'[',1,1) - 1 ) AS J020110,   -- 110.是否投向产业基金
   J020111,    -- 111.被持有股权企业客户ID
   '债转股' as DIS_DEPT
 FROM ybt_datacore.RPAJ_9_2_ZYTZB A
 WHERE A.DATA_DATE =I_DATE; 
 COMMIT ;

 CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB); 

 -- 投管
  INSERT  INTO T_9_2  (
   J020001,   -- 001.投资标的      
   J020002,   -- 002.投资标的名称
   J020003,   -- 003.机构
   J020004,   -- 004.发行价格
   J020005,   -- 005.发行规模
   J020006,   -- 006.发行机构名称
   J020007,   -- 007.发行机构代码
   J020008,   -- 008.发行机构大类
   J020107,   -- 107.发行机构小类
   J020009,   -- 009.发行国家地区
   J020108,   -- 108.交易流通场所
   J020010,   -- 010.投资标的币种
   J020011,   -- 011.投资标的代码
   J020014,   -- 014.起息日期
   J020015,   -- 015.发行日期
   J020016,   -- 016.到期日期
   J020017,   -- 017.投资标的利率类型
   J020018,   -- 018.利率/收益率
   J020019,   -- 019.最近评估价格
   J020020,   -- 020.评估价格日期
   J020021,   -- 021.投融资标的类别
   J020022,   -- 022.资产风险权重
   J020026,   -- 026.基础资产客户名称
   J020027,   -- 027.基础资产客户国家
   J020028,   -- 028.基础资产客户评级
   J020029,   -- 029.基础资产客户评级机构
   J020030,   -- 030.基础资产客户行业类型
   J020031,   -- 031.基础资产外部评级
   J020032,   -- 032.基础资产评级机构
   J020109,   -- 109.基础资产内部评级
   J020033,   -- 033.基础资产最终投向类型
   J020034,   -- 034.基础资产最终投向行业类型
   J020087,   -- 087.含权类型
   J020103,   -- 103.存在变现障碍标识
   J020104,   -- 104.备注
   J020105,   -- 105.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID ,    -- 机构号 
   DEPARTMENT_ID,
   J020106,   -- 106.是否投向市场化债转股相关产品
   J020110,   -- 110.是否投向产业基金
   J020111,    -- 111.被持有股权企业客户ID
   DIS_DEPT
) 
 SELECT 
   J020001,   -- 001.投资标的      
   J020002,   -- 002.投资标的名称
   J020003,   -- 003.机构
   J020004,   -- 004.发行价格
   TO_NUMBER(REPLACE(J020005,',','')) AS J020005,   -- 005.发行规模
   J020006,   -- 006.发行机构名称
   J020007,   -- 007.发行机构代码
   SUBSTR ( J020008,INSTR(J020008,'[',1,1) + 1 , INSTR(J020008, ']',1 ) -INSTR(J020008,'[',1,1) - 1 ) AS J020008,   -- 008.发行机构大类
   SUBSTR ( J020107,INSTR(J020107,'[',1,1) + 1 , INSTR(J020107, ']',1 ) -INSTR(J020107,'[',1,1) - 1 ) AS J020107,   -- 107.发行机构小类
   SUBSTR ( J020009,INSTR(J020009,'[',1,1) + 1 , INSTR(J020009, ']',1 ) -INSTR(J020009,'[',1,1) - 1 ) AS J020009,   -- 009.发行国家地区
   SUBSTR ( J020108,INSTR(J020108,'[',1,1) + 1 , INSTR(J020108, ']',1 ) -INSTR(J020108,'[',1,1) - 1 ) AS J020108,   -- 108.交易流通场所
   SUBSTR ( J020010,INSTR(J020010,'[',1,1) + 1 , INSTR(J020010, ']',1 ) -INSTR(J020010,'[',1,1) - 1 ) AS J020010,   -- 010.投资标的币种
   J020011,   -- 011.投资标的代码
   J020014,   -- 014.起息日期
   J020015,   -- 015.发行日期
   J020016,   -- 016.到期日期
   SUBSTR ( J020017,INSTR(J020017,'[',1,1) + 1 , INSTR(J020017, ']',1 ) -INSTR(J020017,'[',1,1) - 1 ) AS J020017,   -- 017.投资标的利率类型
   TO_NUMBER(REPLACE(J020018,',','')) AS J020018,   -- 018.利率/收益率
   TO_NUMBER(REPLACE(J020019,',','')) AS J020019,   -- 019.最近评估价格
   J020020,   -- 020.评估价格日期
   J020021,   -- 021.投融资标的类别
   J020022,   -- 022.资产风险权重
   J020026,   -- 026.基础资产客户名称
   SUBSTR ( J020027,INSTR(J020027,'[',1,1) + 1 , INSTR(J020027, ']',1 ) -INSTR(J020027,'[',1,1) - 1 ) AS J020027,   -- 027.基础资产客户国家
   J020028,   -- 028.基础资产客户评级
   J020029,   -- 029.基础资产客户评级机构
   SUBSTR ( J020030,INSTR(J020030,'[',1,1) + 1 , INSTR(J020030, ']',1 ) -INSTR(J020030,'[',1,1) - 1 ) AS J020030,   -- 030.基础资产客户行业类型
   J020031,   -- 031.基础资产外部评级
   J020032,   -- 032.基础资产评级机构
   J020109,   -- 109.基础资产内部评级
   SUBSTR ( J020033,INSTR(J020033,'[',1,1) + 1 , INSTR(J020033, ']',1 ) -INSTR(J020033,'[',1,1) - 1 ) AS J020033,   -- 033.基础资产最终投向类型
   J020034,   -- 034.基础资产最终投向行业类型
   J020087,   -- 087.含权类型
   SUBSTR ( J020103,INSTR(J020103,'[',1,1) + 1 , INSTR(J020103, ']',1 ) -INSTR(J020103,'[',1,1) - 1 ) AS J020103,   -- 103.存在变现障碍标识
   J020104,   -- 104.备注
   TO_CHAR(TO_DATE( I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DATA_DATE,   -- 105.采集日期
   TO_CHAR(TO_DATE( I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE , -- 装入数据日期
   '009806' ,    -- 机构号 
   SUBSTR ( J020112,INSTR(J020112,'[',1,1) + 1 , INSTR(J020112, ']',1 ) -INSTR(J020112,'[',1,1) - 1 ) AS DEPARTMENT_ID,
   SUBSTR ( J020106,INSTR(J020106,'[',1,1) + 1 , INSTR(J020106, ']',1 ) -INSTR(J020106,'[',1,1) - 1 ) AS J020106,   -- 106.是否投向市场化债转股相关产品
   SUBSTR ( J020110,INSTR(J020110,'[',1,1) + 1 , INSTR(J020110, ']',1 ) -INSTR(J020110,'[',1,1) - 1 ) AS J020110,   -- 110.是否投向产业基金
   J020111,    -- 111.被持有股权企业客户ID 
   '投行' as DIS_DEPT
 FROM ybt_datacore.INTM_ZYTZBD t
 WHERE t.data_date= I_DATE;
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
END $$


