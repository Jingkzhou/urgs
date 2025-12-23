DROP Procedure IF EXISTS `PROC_BSP_T_9_1_TZBDGX` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_9_1_TZBDGX"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN
/******
      程序名称  ：投资标的关系
      程序功能  ：加工投资标的关系
      目标表：T_9_1
      源表  ：
      创建人  ：LZ
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
	-- JLBA202409290003_关于一表通校验结果治理的需求（同业金融部） 20241212
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
	SET P_PROC_NAME = 'PROC_BSP_T_9_1_TZBDGX';
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
	
	DELETE FROM T_9_1 WHERE J010014 = to_char(P_DATE,'yyyy-mm-dd');
	
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';

-- 现券-----------

 INSERT  INTO T_9_1  (
   J010001, -- 01.投资标的
   J010002, -- 02.机构
   J010003, -- 03.产品
   J010004, -- 04.上一层投资标的
   J010005, -- 05.占上一层投资标的比例
   J010006, -- 06.产品持有底层资产折算人民币金额
   J010007, -- 07.理财产品持有底层资产折算人民币金额（理财中心）
   J010008, -- 08.产品持有底层资产份额
   J010009, -- 09.理财产品持有底层资产份额（理财中心）
   J010010, -- 10.直接或间接投资标识
   J010011, -- 11.投资标的层级
   J010012, -- 12.产品总层级
   J010013, -- 13.备注
   J010014, -- 14.采集日期
   J010015, -- 15.估值币种
   J010016, -- 16.单位资产估值（净价）
   J010017, -- 17.单位资产估值（全价）
   DIS_DATA_DATE, -- 装入数据日期
   DIS_BANK_ID ,   -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID
) 
select 
 t.SUBJECT_CD  ,  -- 01.投资标的
 ORG.ORG_ID  , -- 02.机构,  -- 2.0 zdsj h
 t.ACCT_NUM  , -- 03.产品,
 t.SUBJECT_CD  , -- 04.上一层投资标的
 '100' ,-- 05.占上一层投资标的比例
 sum(t.PRINCIPAL_BALANCE), -- 06.产品持有底层资产折算人民币金额
 null as J010007,-- 07.理财产品持有底层资产折算人民币金额（理财中心）
 sum(t.PRINCIPAL_BALANCE)as J010008, -- sum(t.FACE_VAL)/t.jj , -- 08.产品持有底层资产份额   加字段  -- 2.0zdsj h 桑铭蔚缺陷提需与产品持有底层资产折算人民币金额一致
 null ,-- 09.理财产品持有底层资产份额（理财中心）
 case when t.ORG_NUM='009804' then '01'when  t.ORG_NUM='009820'then '02'  ELSE '01' end ,-- 10.直接或间接投资标识 20250116
 '1' ,-- 11.投资标的层级
 '1' ,-- 12.产品总层级
  null , -- 13.备注
 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),-- 14.采集日期
 'CNY',-- 15.估值币种
 -- t.jj,-- 16.单位资产估值（净价）  加字段
-- CASE WHEN (t.GL_ITEM_CODE in ('11010302','11010303','15010201')and t.DATE_SOURCESD<>'债券投资'  and REF_NUM <>  'TH') THEN null  --  update 20241216 zjk 取消机构 = 009820 因为非标投资保函 金融市场部，过滤投行业务REF_NUM <>  'TH' 为满足YBT_JYF21-58校验
-- WHEN T.ORG_NUM='009804' THEN null -- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐 :我部无理财业务，应全部为空
-- ELSE t.jj end
 null AS J010016 ,-- 16.单位资产估值（净价） -- 20241227 YBT_JYJ01-41
 CASE WHEN T.ORG_NUM='009804' THEN null -- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐 :我部无理财业务，应全部为空
 ELSE t.qj end AS J010017, -- 17.单位资产估值（全价）
 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 装入数据日期
 t.ORG_NUM ,-- 机构号
 '资金投资' ,-- 业务条线
 t.ORG_NUM 
from smtmods.L_ACCT_FUND_INVEST t 
LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表
   ON T.ORG_NUM = ORG.ORG_NUM
  AND ORG.DATA_DATE = I_DATE
left join smtmods.l_agre_bond_info T1
  on T.ACCT_NUM=T1.STOCK_CD and T1.DATA_DATE=I_DATE
   left join smtmods.L_AGRE_OTHER_SUBJECT_INFO t2 on T.ACCT_NUM=T2.SUBJECT_CD and T2.DATA_DATE=I_DATE
where (t.DATE_SOURCESD='债券投资'or (t.GL_ITEM_CODE in ('11010302','11010303','15010201')and t.DATE_SOURCESD<>'债券投资'  and REF_NUM <>  'TH')) -- 非标投资  公募基金 --  update 20241216 zjk 取消机构 = 009820 因为非标投资保函 金融市场部，过滤投行业务REF_NUM <>  'TH' 为满足YBT_JYF21-58校验
and t.DATA_DATE=I_DATE
-- and t.PRINCIPAL_BALANCE<>'0' and (t1.MATURITY_DT>I_DATE or t2.MATURITY_DT>=I_DATE) -- 产品到期不取-- 2.0 zdsj h
-- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
 AND (T.MATURITY_DATE >= SUBSTR(I_DATE,1,4)||'0101' OR T.MATURITY_DATE IS NULL  or T.FACE_VAL > 0)-- 2.0 zdsj h
-- and t.SUBJECT_CD<>'X0003120B2700001'-- 违约债 实际19年到期  康星 万德数据投资标的编号不一致 万德编号041800014  根据业务老师要求按万德为准  数据去掉  改为固定报送 
group by t.SUBJECT_CD,t.ACCT_NUM,t.ORG_NUM,
case 
 WHEN (t.GL_ITEM_CODE in ('11010302','11010303','15010201')and t.DATE_SOURCESD<>'债券投资'  and REF_NUM <>  'TH') THEN null  --  20241212
 WHEN T.ORG_NUM='009804' THEN null -- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐 :我部无理财业务，应全部为空
 ELSE t.jj 
 END,-- 16.单位资产估值（净价）  加字段  1212
CASE WHEN T.ORG_NUM='009804' THEN null -- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐 :我部无理财业务，应全部为空
 ELSE t.qj END -- 17.单位资产估值（全价）加字段
,ORG.ORG_ID ;


    COMMIT;
	
 -- 回购---------------------
    INSERT  INTO T_9_1  (
  J010001, -- 01.投资标的
   J010002, -- 02.机构
   J010003, -- 03.产品
   J010004, -- 04.上一层投资标的
   J010005, -- 05.占上一层投资标的比例
   J010006, -- 06.产品持有底层资产折算人民币金额
   J010007, -- 07.理财产品持有底层资产折算人民币金额（理财中心）
   J010008, -- 08.产品持有底层资产份额
   J010009, -- 09.理财产品持有底层资产份额（理财中心）
   J010010, -- 10.直接或间接投资标识
   J010011, -- 11.投资标的层级
   J010012, -- 12.产品总层级
   J010013, -- 13.备注
   J010014, -- 14.采集日期
   J010015, -- 15.估值币种
   J010016, -- 16.单位资产估值（净价）
   J010017, -- 17.单位资产估值（全价）
   DIS_DATA_DATE, -- 装入数据日期
   DIS_BANK_ID ,   -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID
) select 
t.DEAL_ACCT_NUM  ,-- 01.投资标的
 ORG.ORG_ID, -- 02.机构
 t.ACCT_NUM ,-- 03.产品
t.DEAL_ACCT_NUM  ,-- 04.上一层投资标的
 '100',-- 05.占上一层投资标的比例
 t.BALANCE,-- 06.产品持有底层资产折算人民币金额
 null,-- 07.理财产品持有底层资产折算人民币金额（理财中心）
 t.BALANCE, -- 08.产品持有底层资产份额
 null,-- 09.理财产品持有底层资产份额（理财中心）
 '01',-- 10.直接或间接投资标识
 '1',-- 11.投资标的层级
 '1',-- 12.产品总层级
 null,-- 13.备注
 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),-- 14.采集日期
 'CNY',-- 15.估值币种
 null,-- 16.单位资产估值（净价）  加字段
 null,-- 17.单位资产估值（全价）加字段
 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
 t.ORG_NUM,-- 机构号
 '回购信息（不包含票据回购）',-- 业务条线
 t.ORG_NUM
from smtmods.L_ACCT_FUND_REPURCHASE t 
LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表
   ON T.ORG_NUM = ORG.ORG_NUM
  AND ORG.DATA_DATE = I_DATE
where  t.DATA_DATE=I_DATE and t.DATE_SOURCESD<>'票据回购'
  and  (t.BALANCE <> '0' OR t.END_DT >= SUBSTR(I_DATE,1,4)||'0101')  -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
      ;
       COMMIT;
       
       
 INSERT  INTO T_9_1  (
   J010001, -- 01.投资标的
   J010002, -- 02.机构
   J010003, -- 03.产品
   J010004, -- 04.上一层投资标的
   J010005, -- 05.占上一层投资标的比例
   J010006, -- 06.产品持有底层资产折算人民币金额
   J010007, -- 07.理财产品持有底层资产折算人民币金额（理财中心）
   J010008, -- 08.产品持有底层资产份额
   J010009, -- 09.理财产品持有底层资产份额（理财中心）
   J010010, -- 10.直接或间接投资标识
   J010011, -- 11.投资标的层级
   J010012, -- 12.产品总层级
   J010013, -- 13.备注
   J010014, -- 14.采集日期
   J010015, -- 15.估值币种
   J010016, -- 16.单位资产估值（净价）
   J010017, -- 17.单位资产估值（全价）
   DIS_DATA_DATE, -- 装入数据日期
   DIS_BANK_ID ,   -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID
) select 
t.SUBJECT_CD as SUBJECT_CD,-- 01.投资标的
ORG.ORG_ID, -- 02.机构
t.SUBJECT_CD as SUBJECT_CD3,-- 03.产品
t.SUBJECT_CD as SUBJECT_CD2 ,-- 04.上一层投资标的
 '100',-- 05.占上一层投资标的比例
 t1.AMOUNT,-- 06.产品持有底层资产折算人民币金额
 null,-- 07.理财产品持有底层资产折算人民币金额（理财中心）
 t1.AMOUNT, -- 08.产品持有底层资产份额
 null,-- 09.理财产品持有底层资产份额（理财中心）
 '01',-- 10.直接或间接投资标识
 '1',-- 11.投资标的层级
 '1',-- 12.产品总层级
 null,-- 13.备注
 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),-- 14.采集日期
 'CNY',-- 15.估值币种
 null,-- 16.单位资产估值（净价）  加字段
 null,-- 17.单位资产估值（全价）加字段
 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
 t.ORG_NUM,-- 机构号
 '票据回购',-- 业务条线
 t.ORG_NUM
from smtmods.L_ACCT_FUND_REPURCHASE t  
LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表
   ON T.ORG_NUM = ORG.ORG_NUM
  AND ORG.DATA_DATE = I_DATE
left join smtmods.l_agre_bill_info  t1 on t.SUBJECT_CD=t1.BILL_NUM and t1.DATA_DATE=I_DATE
where t.DATA_DATE=I_DATE and t.DATE_SOURCESD='票据回购'
  and (t1.AMOUNT<>'0' OR t1.MATU_DATE >= SUBSTR(I_DATE,1,4)||'0101') -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
group by t.SUBJECT_CD,t1.AMOUNT,t.ORG_NUM,ORG.ORG_ID;
       COMMIT;
       
 -- 债券借贷 数仓无逻辑
 
 -- 拆借 009804 009820-------------  acct_num 无重复
  INSERT INTO T_9_1  (
   J010001, -- 01.投资标的
   J010002, -- 02.机构
   J010003, -- 03.产品
   J010004, -- 04.上一层投资标的
   J010005, -- 05.占上一层投资标的比例
   J010006, -- 06.产品持有底层资产折算人民币金额
   J010007, -- 07.理财产品持有底层资产折算人民币金额（理财中心）
   J010008, -- 08.产品持有底层资产份额
   J010009, -- 09.理财产品持有底层资产份额（理财中心）
   J010010, -- 10.直接或间接投资标识
   J010011, -- 11.投资标的层级
   J010012, -- 12.产品总层级
   J010013, -- 13.备注
   J010014, -- 14.采集日期
   J010015, -- 15.估值币种
   J010016, -- 16.单位资产估值（净价）
   J010017, -- 17.单位资产估值（全价）
   DIS_DATA_DATE, -- 装入数据日期
   DIS_BANK_ID ,   -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID
) select
 t.ACCT_NUM  ,-- 01.投资标的
 ORG.ORG_ID, -- 02.机构
 t.ACCT_NUM ,-- 03.产品
 t.ACCT_NUM,-- 04.上一层投资标的
 '100',-- 05.占上一层投资标的比例
 t.BALANCE,-- 06.产品持有底层资产折算人民币金额
 null,-- 07.理财产品持有底层资产折算人民币金额（理财中心）
 t.BALANCE,-- 08.产品持有底层资产份额
 null,-- 09.理财产品持有底层资产份额（理财中心）
 case when t.ORG_NUM='009804' then '01'
      when t.ORG_NUM='009820' and( t.GL_ITEM_CODE like '101101%'or t.GL_ITEM_CODE like '101102%'or t.GL_ITEM_CODE in ('13020102','13020104','13020106')) then '01'
       ELSE '01'  -- 20250116
       end ,-- 10.直接或间接投资标识
 '1',-- 11.投资标的层级
 '1',-- 12.产品总层级
  null,-- 13.备注
  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),-- 14.采集日期
 'CNY',-- 15.估值币种
 null,-- 16.单位资产估值（净价）
 null,-- 17.单位资产估值（全价）
  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
  t.ORG_NUM,-- 机构号
 '资金往来',-- 业务条线
  t.ORG_NUM
from smtmods.L_ACCT_FUND_MMFUND t 
LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表
   ON T.ORG_NUM = ORG.ORG_NUM
  AND ORG.DATA_DATE = I_DATE
  where 
     ((substr(T.gl_item_code, '1', '4') = '2003' AND T.ACCT_TYP = '20201')-- 拆入
           or (T.gl_item_code = '20030105' ) or                                 -- 拆入
           ( substr(T.gl_item_code, '1', '4') = '1302' AND T.ACCT_TYP = '10201')  -- 拆出
          /* or substr(T.ACCT_TYP,1,3)  IN ('105','205')                          -- 同业借出
           or T.gl_item_code = '13020104'                                       -- 同业借出
           or T.gl_item_code in ('20030102','20030106')                         -- 同业借入*/
           or t.GL_ITEM_CODE in ('13020102','13020104','13020106','20030102','20030104','20030106')-- 同业借入  同业借出
           or t.GL_ITEM_CODE like '101101%'or t.GL_ITEM_CODE like '101102%' -- 存放同业活期和存放同业定期
          -- or t.GL_ITEM_CODE in ('72400101','72100101')--  债券借贷 不报
           )
           -- and t.DATA_DATE=I_DATE and t.BALANCE<>'0'and t.MATURE_DATE>=I_DATE
           and t.DATA_DATE=I_DATE 
           and (t.MATURE_DATE >= SUBSTR(I_DATE,1,4)||'0101' -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
                or t.BALANCE<>'0' or t.ACCRUAL <> 0)  -- alter by djh 20240719 有利息无本金数据也加进来
           ;-- 拆出
       
            COMMIT;
            
 -- 同业金融部  同业存单发行与投资-------------同业存单发行CDS_NO会有重，同业存单投资不会有重的     金融市场部只取存单投资的数据    同业金融部都取
     INSERT  INTO T_9_1  (
   J010001, -- 01.投资标的
   J010002, -- 02.机构
   J010003, -- 03.产品
   J010004, -- 04.上一层投资标的
   J010005, -- 05.占上一层投资标的比例
   J010006, -- 06.产品持有底层资产折算人民币金额
   J010007, -- 07.理财产品持有底层资产折算人民币金额（理财中心）
   J010008, -- 08.产品持有底层资产份额
   J010009, -- 09.理财产品持有底层资产份额（理财中心）
   J010010, -- 10.直接或间接投资标识
   J010011, -- 11.投资标的层级
   J010012, -- 12.产品总层级
   J010013, -- 13.备注
   J010014, -- 14.采集日期
   J010015, -- 15.估值币种
   J010016, -- 16.单位资产估值（净价）
   J010017, -- 17.单位资产估值（全价）
   DIS_DATA_DATE, -- 装入数据日期
   DIS_BANK_ID ,   -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID
)select 
 t.CDS_NO as J010001,
  -- 01.投资标的
  ORG.ORG_ID as J010002,-- 02.机构
  t.CDS_NO  as J010003,-- 03.产品
  t.CDS_NO  as J010004, -- 04.上一层投资标的
  '100' as J010005,-- 05.占上一层投资标的比例
  sum(t.FACE_VAL) as J010006,-- 06.产品持有底层资产折算人民币金额
  null as J010007, -- 07.理财产品持有底层资产折算人民币金额（理财中心）
  sum(t.FACE_VAL) as J010008, -- 08.产品持有底层资产份额  -- 2.0zdsj h
  null as J010009,-- 09.理财产品持有底层资产份额（理财中心）
  '01'  as J010010,-- 10.直接或间接投资标识
  '1' as J010011,-- 11.投资标的层级
  '1' as J010012,-- 12.产品总层级
  null as J010013,-- 13.备注
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')as J010014,-- 14.采集日期
   'CNY'as J010015,-- 15.估值币种
  -- t.jj as J010016,-- 16.单位资产估值（净价）	
  NULL  as J010016,-- 16.单位资产估值（净价）-- JLBA202409290003	 20241212
  t.qj as J010017,-- 17.单位资产估值（全价）
  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')as DIS_DATA_DATE, -- 装入数据日期
  t.ORG_NUM as DIS_BANK_ID,-- 机构号
  '存单投资与发行' as DIS_DEPT,-- 业务条线
  t.ORG_NUM as DEPARTMENT_ID from smtmods.l_acct_fund_cds_bal t 
  LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表
   ON T.ORG_NUM = ORG.ORG_NUM
  AND ORG.DATA_DATE = I_DATE
  where (t.PRODUCT_PROP = 'A'or (t.PRODUCT_PROP = 'B'and t.ORG_NUM='009820')) and  t.DATA_DATE=I_DATE 
  and (t.FACE_VAL<>'0' or t.MATURITY_DT >= SUBSTR(I_DATE,1,4)||'0101') -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
  group by
    J010001, -- 01.投资标的
   J010002, -- 02.机构
   J010003, -- 03.产品
   J010004, -- 04.上一层投资标的
   J010005, -- 05.占上一层投资标的比例
   J010007, -- 07.理财产品持有底层资产折算人民币金额（理财中心）
   -- J010008, -- 08.产品持有底层资产份额
   J010009, -- 09.理财产品持有底层资产份额（理财中心）
   J010010, -- 10.直接或间接投资标识
   J010011, -- 11.投资标的层级
   J010012, -- 12.产品总层级
   J010013, -- 13.备注
   J010014, -- 14.采集日期
   J010015, -- 15.估值币种
   J010016, -- 16.单位资产估值（净价）
   J010017, -- 17.单位资产估值（全价）
   DIS_DATA_DATE, -- 装入数据日期
   DIS_BANK_ID ,   -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID
;  -- A 投资  B 发行  


/*
--  金融市场部投资标的101788002，011754134，031672037，151408，151123违约债，根据业务老师要求做固定报送
 INSERT  INTO T_9_1  (
   J010001, -- 01.投资标的
   J010002, -- 02.机构
   J010003, -- 03.产品
   J010004, -- 04.上一层投资标的
   J010005, -- 05.占上一层投资标的比例
   J010006, -- 06.产品持有底层资产折算人民币金额
   J010007, -- 07.理财产品持有底层资产折算人民币金额（理财中心）
   J010008, -- 08.产品持有底层资产份额
   J010009, -- 09.理财产品持有底层资产份额（理财中心）
   J010010, -- 10.直接或间接投资标识
   J010011, -- 11.投资标的层级
   J010012, -- 12.产品总层级
   J010013, -- 13.备注
   J010014, -- 14.采集日期
   J010015, -- 15.估值币种
   J010016, -- 16.单位资产估值（净价）
   J010017, -- 17.单位资产估值（全价）
   DIS_DATA_DATE, -- 装入数据日期
   DIS_BANK_ID ,   -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID
)select 
J010001,
 J010002, 
 J010003,
 J010004, 
 J010005,
 J010006, 
 J010007,
 J010008,
 J010009,
 J010010,
 J010011, 
 J010012, 
 J010013, 
 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')as J010014,-- 14.采集日期
 J010015, 
 J010016, 
 J010017,
  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')as DIS_DATA_DATE, -- 装入数据日期
 '009804' as DIS_BANK_ID,-- 机构号
 '' as DIS_DEPT,-- 业务条线
 '009804' as DEPARTMENT_ID
from t_9_1_gdbs;*/

-- add by wjb 20240709 一表通2.0升级 新增 ：开发大额存单，转股协议存款。

INSERT INTO T_9_1 
(
   J010001, -- 01.投资标的
   J010002, -- 02.机构
   J010003, -- 03.产品
   J010004, -- 04.上一层投资标的
   J010005, -- 05.占上一层投资标的比例
   J010006, -- 06.产品持有底层资产折算人民币金额
   J010007, -- 07.理财产品持有底层资产折算人民币金额（理财中心）
   J010008, -- 08.产品持有底层资产份额
   J010009, -- 09.理财产品持有底层资产份额（理财中心）
   J010010, -- 10.直接或间接投资标识
   J010011, -- 11.投资标的层级
   J010012, -- 12.产品总层级
   J010013, -- 13.备注
   J010014, -- 14.采集日期
   J010015, -- 15.估值币种
   J010016, -- 16.单位资产估值（净价）
   J010017, -- 17.单位资产估值（全价）
   DIS_DATA_DATE,  -- 装入数据日期
   DIS_BANK_ID ,   -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID
)
SELECT 
 T.ACCT_NUM AS SUBJECT_CD,-- 01.投资标的
 ORG.ORG_ID, -- 02.机构
 T.ACCT_NUM AS SUBJECT_CD3 ,-- 03.产品
 T.ACCT_NUM AS SUBJECT_CD2 ,-- 04.上一层投资标的
 '100',-- 05.占上一层投资标的比例
 T.ACCT_BALANCE,-- 06.产品持有底层资产折算人民币金额
 NULL,-- 07.理财产品持有底层资产折算人民币金额（理财中心）
 T.ACCT_BALANCE, -- 08.产品持有底层资产份额
 NULL,-- 09.理财产品持有底层资产份额（理财中心）
 '01',-- 10.直接或间接投资标识
 '1',-- 11.投资标的层级
 '1',-- 12.产品总层级
 NULL,-- 13.备注
 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),-- 14.采集日期
 'CNY',-- 15.估值币种
 NULL,-- 16.单位资产估值（净价）  加字段
 NULL,-- 17.单位资产估值（全价）加字段
 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
 T.ORG_NUM,-- 机构号
 '大额存单，转股协议存款',-- 业务条线
 T.ORG_NUM
 FROM SMTMODS.L_ACCT_DEPOSIT T -- 存款账户信息表
 LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表
   ON T.ORG_NUM = ORG.ORG_NUM
  AND ORG.DATA_DATE = I_DATE
WHERE T.DATA_DATE = I_DATE
  AND T.GL_ITEM_CODE IN ('20110211','20110113','20110208')
  AND (T.ACCT_BALANCE<>'0'  
       OR NVL(T.ACCT_CLDATE,T.MATUR_DATE) >= SUBSTR(I_DATE,1,4)||'0101' -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
	  );

 CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);		
 
	    #4.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '财管数据插入';
	
	INSERT  INTO T_9_1  (
   J010001, -- 01.投资标的
   J010002, -- 02.机构
   J010003, -- 03.产品
   J010004, -- 04.上一层投资标的
   J010005, -- 05.占上一层投资标的比例
   J010006, -- 06.产品持有底层资产折算人民币金额
   J010007, -- 07.理财产品持有底层资产折算人民币金额（理财中心）
   J010008, -- 08.产品持有底层资产份额
   J010009, -- 09.理财产品持有底层资产份额（理财中心）
   J010010, -- 10.直接或间接投资标识
   J010011, -- 11.投资标的层级
   J010012, -- 12.产品总层级
   J010013, -- 13.备注
   J010014, -- 14.采集日期
   J010015, -- 15.估值币种
   J010016, -- 16.单位资产估值（净价）
   J010017, -- 17.单位资产估值（全价）
   DIS_DATA_DATE, -- 装入数据日期
   DIS_BANK_ID ,   -- 机构号
   DIS_DEPT,       -- 业务条线
   DEPARTMENT_ID
)select 
   J010001, -- 01.投资标的
   J010002, -- 02.机构
   J010003, -- 03.产品
   J010004, -- 04.上一层投资标的
   J010005, -- 05.占上一层投资标的比例
   J010006, -- 06.产品持有底层资产折算人民币金额
   J010007, -- 07.理财产品持有底层资产折算人民币金额（理财中心）
   J010008, -- 08.产品持有底层资产份额
   J010009, -- 09.理财产品持有底层资产份额（理财中心）
   J010010, -- 10.直接或间接投资标识
   J010011, -- 11.投资标的层级
   J010012, -- 12.产品总层级
   J010013, -- 13.备注
   J010014, -- 14.采集日期
   J010015, -- 15.估值币种
   J010016, -- 16.单位资产估值（净价）
   J010017, -- 17.单位资产估值（全价）
    TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
   '990000' ,   -- 机构号
   '股权投资',       -- 业务条线
   CASE WHEN  ywxt = '总行机关战略投资管理部' THEN  '0098ZT'
	    WHEN  ywxt = '总行机关运营管理部' THEN  '009801'
      END  
from smtmods.RSF_GQ_INVESTMENT_TARGETRELATIONSHIP t  where  t.DATA_DATE=I_DATE;
commit; 

    #5.RPA数据插入
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = 'RPA数据插入';
	
-- RPA 债转股
INSERT  INTO T_9_1  
  (J010001, -- 01.投资标的
   J010002, -- 02.机构
   J010003, -- 03.产品
   J010004, -- 04.上一层投资标的
   J010005, -- 05.占上一层投资标的比例
   J010006, -- 06.产品持有底层资产折算人民币金额
   J010007, -- 07.理财产品持有底层资产折算人民币金额（理财中心）
   J010008, -- 08.产品持有底层资产份额
   J010009, -- 09.理财产品持有底层资产份额（理财中心）
   J010010, -- 10.直接或间接投资标识
   J010011, -- 11.投资标的层级
   J010012, -- 12.产品总层级
   J010013, -- 13.备注
   J010014, -- 14.采集日期
   J010015, -- 15.估值币种
   J010016, -- 16.单位资产估值（净价）
   J010017, -- 17.单位资产估值（全价）
   DIS_DATA_DATE, -- 装入数据日期
   DIS_BANK_ID ,   -- 机构号 
   DEPARTMENT_ID,
   DIS_DEPT       -- 业务条线
) 
   SELECT 
   J010001, -- 01.投资标的
   J010002, -- 02.机构
   J010003, -- 03.产品
   J010004, -- 04.上一层投资标的
   J010005, -- 05.占上一层投资标的比例
   TO_NUMBER(REPLACE(J010006,',','')) AS J010006, -- 06.产品持有底层资产折算人民币金额
   TO_NUMBER(REPLACE(J010007,',','')) AS J010007, -- 07.理财产品持有底层资产折算人民币金额（理财中心）
   TO_NUMBER(REPLACE(J010008,',','')) AS J010008, -- 08.产品持有底层资产份额
   TO_NUMBER(REPLACE(J010009,',','')) AS J010009, -- 09.理财产品持有底层资产份额（理财中心）
   SUBSTR ( J010010,INSTR(J010010,'[',1,1) + 1 , INSTR(J010010, ']',1 ) -INSTR(J010010,'[',1,1) - 1 ) AS J010010, -- 10.直接或间接投资标识
   J010011, -- 11.投资标的层级
   J010012, -- 12.产品总层级
   J010013, -- 13.备注
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS J010014, -- 14.采集日期
   SUBSTR ( J010015,INSTR(J010015,'[',1,1) + 1 , INSTR(J010015, ']',1 ) -INSTR(J010015,'[',1,1) - 1 ) AS J010015, -- 15.估值币种
   TO_NUMBER(REPLACE(J010016,',','')) AS J010016, -- 16.单位资产估值（净价）
   TO_NUMBER(REPLACE(J010017,',','')) AS J010017, -- 17.单位资产估值（全价）
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE, -- 装入数据日期
   '990000' ,   -- 机构号 
   SUBSTR ( DEPARTMENT_ID,INSTR(DEPARTMENT_ID,'[',1,1) + 1 , INSTR(DEPARTMENT_ID, ']',1 ) -INSTR(DEPARTMENT_ID,'[',1,1) - 1 ) AS DEPARTMENT_ID  ,
   '债转股' as  DIS_DEPT      -- 业务条线
 FROM ybt_datacore.RPAJ_9_1_TZB A
 WHERE A.DATA_DATE =I_DATE;  
 COMMIT ;	
	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
	
	   -- 投管
 INSERT  INTO T_9_1  
  (
   J010001, -- 01.投资标的
   J010002, -- 02.机构
   J010003, -- 03.产品
   J010004, -- 04.上一层投资标的
   J010005, -- 05.占上一层投资标的比例
   J010006, -- 06.产品持有底层资产折算人民币金额
   J010007, -- 07.理财产品持有底层资产折算人民币金额（理财中心）
   J010008, -- 08.产品持有底层资产份额
   J010009, -- 09.理财产品持有底层资产份额（理财中心）
   J010010, -- 10.直接或间接投资标识
   J010011, -- 11.投资标的层级
   J010012, -- 12.产品总层级
   J010013, -- 13.备注
   J010014, -- 14.采集日期
   J010015, -- 15.估值币种
   J010016, -- 16.单位资产估值（净价）
   J010017, -- 17.单位资产估值（全价）
   DIS_DATA_DATE, -- 装入数据日期
   DIS_BANK_ID ,   -- 机构号 
   DEPARTMENT_ID,
   DIS_DEPT      -- 业务条线
) 
 
SELECT 
   J010001, -- 01.投资标的
   J010002, -- 02.机构
   J010003, -- 03.产品
   J010004, -- 04.上一层投资标的
   J010005, -- 05.占上一层投资标的比例
   TO_NUMBER(REPLACE(J010006,',','')) AS J010006, -- 06.产品持有底层资产折算人民币金额
   TO_NUMBER(REPLACE(J010007,',','')) AS J010007, -- 07.理财产品持有底层资产折算人民币金额（理财中心）
   TO_NUMBER(REPLACE(J010008,',','')) AS J010008, -- 08.产品持有底层资产份额
   TO_NUMBER(REPLACE(J010009,',','')) AS J010009, -- 09.理财产品持有底层资产份额（理财中心）
   SUBSTR ( J010010,INSTR(J010010,'[',1,1) + 1 , INSTR(J010010, ']',1 ) -INSTR(J010010,'[',1,1) - 1 ) AS J010010, -- 10.直接或间接投资标识
   J010011, -- 11.投资标的层级
   J010012, -- 12.产品总层级
   J010013, -- 13.备注
   TO_CHAR(TO_DATE( I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS J010014, -- 14.采集日期
   SUBSTR ( J010015,INSTR(J010015,'[',1,1) + 1 , INSTR(J010015, ']',1 ) -INSTR(J010015,'[',1,1) - 1 ) AS J010015, -- 15.估值币种
   TO_NUMBER(REPLACE(J010016,',','')) AS J010016, -- 16.单位资产估值（净价）
   TO_NUMBER(REPLACE(J010017,',','')) AS J010017, -- 17.单位资产估值（全价）
   TO_CHAR(TO_DATE( I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE, -- 装入数据日期
   '009806' ,   -- 机构号 
   SUBSTR ( J010018,INSTR(J010018,'[',1,1) + 1 , INSTR(J010018, ']',1 ) -INSTR(J010018,'[',1,1) - 1 ) AS DEPARTMENT_ID  ,
   '投行' as  DIS_DEPT      -- 业务条线
   FROM ybt_datacore.INTM_TZBDGX T
 WHERE T.DATA_DATE= I_DATE;
 COMMIT;
 
 
 INSERT  INTO T_9_1  
  (
   J010001, -- 01.投资标的
   J010002, -- 02.机构
   J010003, -- 03.产品
   J010004, -- 04.上一层投资标的
   J010005, -- 05.占上一层投资标的比例
   J010006, -- 06.产品持有底层资产折算人民币金额
   J010007, -- 07.理财产品持有底层资产折算人民币金额（理财中心）
   J010008, -- 08.产品持有底层资产份额
   J010009, -- 09.理财产品持有底层资产份额（理财中心）
   J010010, -- 10.直接或间接投资标识
   J010011, -- 11.投资标的层级
   J010012, -- 12.产品总层级
   J010013, -- 13.备注
   J010014, -- 14.采集日期
   J010015, -- 15.估值币种
   J010016, -- 16.单位资产估值（净价）
   J010017, -- 17.单位资产估值（全价）
   DIS_DATA_DATE, -- 装入数据日期
   DIS_BANK_ID ,   -- 机构号 
   DEPARTMENT_ID,
   DIS_DEPT      -- 业务条线
) 
 --  吴大为20250624邮件提出:姜俐锋修改：新增债券发行部分数据 
 SELECT 
   A.ACCT_NUM||A.REF_NUM AS J010001, -- 01.投资标的
   ORG.ORG_ID            AS J010002, -- 02.机构
   A.SUBJECT_CD          AS J010003, -- 03.产品
   A.ACCT_NUM||A.REF_NUM AS J010004, -- 04.上一层投资标的
   100                   AS J010005, -- 05.占上一层投资标的比例
   A.FACE_VAL            AS J010006, -- 06.产品持有底层资产折算人民币金额
   NULL                  AS J010007, -- 07.理财产品持有底层资产折算人民币金额（理财中心）
   100                   AS J010008, -- 08.产品持有底层资产份额
   NULL                  AS J010009, -- 09.理财产品持有底层资产份额（理财中心）
   '01'                  AS J010010, -- 10.直接或间接投资标识
   '1'                   AS J010011, -- 11.投资标的层级
   '1'                   AS J010012, -- 12.产品总层级
   NULL                  AS J010013, -- 13.备注
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS J010014, -- 14.采集日期
   A.CURR_CD             AS J010015, -- 15.估值币种
   A.FACE_VAL            AS J010016, -- 16.单位资产估值（净价）
   A.FACE_VAL            AS J010017, -- 17.单位资产估值（全价）
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE, -- 装入数据日期
   '009806'              AS DIS_BANK_ID ,   -- 机构号
   '债券发行'             AS DIS_DEPT,       -- 业务条线
   '009806'              AS DEPARTMENT_ID
  FROM SMTMODS.L_ACCT_FUND_BOND_ISSUE A  -- 债券发行
  LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
    ON A.ORG_NUM = ORG.ORG_NUM
   AND ORG.DATA_DATE = I_DATE
 WHERE A.DATA_DATE = I_DATE
   AND SUBSTR(A.GL_ITEM_CODE, 1, 4) = '2502'
   AND (A.FACE_VAL <> 0 
       OR A.MATURITY_DATE >= SUBSTR(I_DATE,1,4)||'0101' -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
	   ); 
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


