DROP Procedure IF EXISTS `PROC_BSP_T_9_5_LCTZBD` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_9_5_LCTZBD"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN
/******
      程序名称  ：理财投资标的
      程序功能  ：加工理财投资标的
      目标表：T_9_5
      源表  ：
      创建人  ：LZ
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
	
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
	SET P_PROC_NAME = 'PROC_BSP_T_9_5_LCTZBD';
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
	
	DELETE FROM T_9_5 WHERE J050087 = to_char(P_DATE,'yyyy-mm-dd');										
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
 /*INSERT  INTO T_9_5  (
   J010001,  -- 01.投资标的
   J010002,  -- 02.机构
   J050001,  -- 01.投资标的
   J050002,  -- 02.投资标的名称
   J050003,  -- 03.机构
   J050004,  -- 04.发行价格
   J050005,  -- 05.发行规模
   J050006,  -- 06.发行机构名称
   J050007,  -- 07.发行机构代码
   J050008,  -- 08.理财发行机构类型
   J050009,  -- 09.发行国家地区
   J050010,  -- 10.投资标的币种
   J050011,  -- 11.投资标的代码
   J050012,  -- 12.行内资产/负债编码
   J050013,  -- 13.资产负债登记编码
   J050014,  -- 14.起息日期
   J050015,  -- 15.发行日期
   J050016,  -- 16.到期日期
   J050017,  -- 17.利率/收益率
   J050018,  -- 18.最近评估价格
   J050019,  -- 19.一级资产类别
   J050020,  -- 20.二级资产类别
   J050021,  -- 21.三级资产类别
   J050022,  -- 22.交易流通场所
   J050023,  -- 23.剩余期限
   J050024,  -- 24.资产
   J050025,  -- 25.资产评级
   J050026,  -- 26.融资人名称
   J050027,  -- 27.融资人统代一码社会信用编码
   J050028,  -- 28.融资人内部评级
   J050029,  -- 29.融资人类型（按规模划分）
   J050030,  -- 30.融资人类型（按技术领域划分）
   J050031,  -- 31.融资人类型（按经济类型划分）
   J050032,  -- 32.融资项目名称
   J050033,  -- 33.融资人行业类型
   J050034,  -- 34.融资项目所属国家地区
   J050035,  -- 35.融资项目行业类型
   J050036,  -- 36.融资项目属于重点监控行业和领域标识
   J050037,  -- 37.重点监控行业和领域类别
   J050038,  -- 38.主要担保方式标识
   J050039,  -- 39.担保说明
   J050040,  -- 40.抵质押物类型
   J050041,  -- 41.抵质押物价值
   J050042,  -- 42.担保性质
   J050043,  -- 43.担保人与融资人关系
   J050044,  -- 44.押品
   J050045,  -- 45.担保协议
   J050046,  -- 46.付息频率
   J050047,  -- 47.资产外部评级
   J050048,  -- 48.收/受益权类型
   J050049,  -- 49.买入返售标识
   J050050,  -- 50.份额面值
   J050051,  -- 51.计息类型
   J050052,  -- 52.计息基础
   J050053,  -- 53.规则付息标识
   J050054,  -- 54.利息分布方式
   J050055,  -- 55.基准利率种类
   J050056,  -- 56.浮动因子标识
   J050057,  -- 57.浮动因子
   J050058,  -- 58.结构档次
   J050059,  -- 59.还本方式
   J050060,  -- 60.分期还本条款标识
   J050061,  -- 61.超额收益分配比例
   J050062,  -- 62.利差
   J050063,  -- 63.增信机构代码
   J050064,  -- 64.增信机构名称
   J050065,  -- 65.融资人外部评级
   J050066,  -- 66.资产内部评级
   J050067,  -- 67.含权类型
   J050068,  -- 68.选择权
   J050069,  -- 69.行权方式
   J050070,  -- 70.行权条件说明
   J050071,  -- 71.固定行权日期
   J050072,  -- 72.首次行权日期
   J050073,  -- 73.行权周期
   J050074,  -- 74.行权价格
   J050075,  -- 75.永续条款类型
   J050076,  -- 76.利息递延条款类型
   J050077,  -- 77.递延利息计息标识
   J050078,  -- 78.首次重定价日期
   J050079,  -- 79.重定价周期
   J050080,  -- 80.部分赎回标识
   J050081,  -- 81.部分赎回比例
   J050082,  -- 82.费用情况说明
   J050083,  -- 83.法定到期日期
   J050084,  -- 84.行内资产类别说明
   J050085,  -- 85.备注
   J050086,  -- 86.还本付息情况说明
   J050087,  -- 87.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID     -- 机构号
                   
) */


	
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

