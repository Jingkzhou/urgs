DROP PROCEDURE IF EXISTS PROC_BSP_T_1_3_YG;

CREATE PROCEDURE PROC_BSP_T_1_3_YG(
  IN I_DATE STRING,
  OUT OI_RETCODE INT,
  OUT OI_REMESSAGE STRING
)
LANGUAGE HIVE
BEGIN
  /******
      程序名称  ：员工
      程序功能  ：加工员工
      目标表：T_1_3
      源表  ：
      创建人  ：LZ
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
   /* 需求编号：JLBA202502210009 上线日期：20250415，修改人：姜俐锋，提出人：吴大为 */
   /* 需求编号：JLBA202507250003 上线日期：2025-09-09，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统修改取数逻辑的需求*/


  #声明变量
  DECLARE P_DATE DATE;
  DECLARE P_PROC_NAME STRING;
  DECLARE P_STATUS INT;
  DECLARE P_START_DT TIMESTAMP;
  DECLARE P_END_TIME TIMESTAMP;
  DECLARE P_SQLCDE STRING;
  DECLARE P_STATE STRING;
  DECLARE P_SQLMSG STRING;
  DECLARE P_STEP_NO INT;
  DECLARE P_DESCB STRING;
  DECLARE BEG_MON_DT STRING;
  DECLARE BEG_QUAR_DT STRING;
  DECLARE BEG_YEAR_DT STRING;
  DECLARE LAST_MON_DT STRING;
  DECLARE LAST_QUAR_DT STRING;
  DECLARE LAST_YEAR_DT STRING;
  DECLARE LAST_DT STRING;
  DECLARE FINISH_FLG STRING;  
  #声明异常
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
   GET DIAGNOSTICS CONDITION 1 P_SQLCDE = GBASE_ERRNO,P_SQLMSG = MESSAGE_TEXT,P_STATE = RETURNED_SQLSTATE;
   SET P_STATUS = -1;
   SET P_START_DT = current_timestamp();
   SET P_STEP_NO = P_STEP_NO + 1;
   SET P_DESCB = '程序异常';
   CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,current_timestamp(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
   SET OI_RETCODE = P_STATUS; 
   SET OI_REMESSAGE = concat(P_DESCB, ':', P_SQLCDE, ' - ', P_SQLMSG);
   SELECT OI_RETCODE,'|',OI_REMESSAGE;
  END;
  
    #变量初始化
	SET P_DATE = to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd')));
	SET BEG_MON_DT = date_format(trunc(P_DATE,'MM'),'yyyyMMdd');
	SET BEG_QUAR_DT = date_format(trunc(P_DATE,'Q'),'yyyyMMdd');
	SET BEG_YEAR_DT = date_format(trunc(P_DATE,'YY'),'yyyyMMdd');
	SET LAST_MON_DT = date_format(date_sub(trunc(P_DATE,'MM'),1),'yyyyMMdd');
	SET LAST_QUAR_DT = date_format(date_sub(trunc(P_DATE,'Q'),1),'yyyyMMdd');
	SET LAST_YEAR_DT = date_format(date_sub(trunc(P_DATE,'YY'),1),'yyyyMMdd');
	SET LAST_DT = date_format(date_sub(P_DATE,1),'yyyyMMdd'); 			
	SET P_PROC_NAME = 'PROC_BSP_T_1_3_YG';
	SET OI_RETCODE = 0;
	SET P_STATUS = 0;
	SET P_STEP_NO = 0;
	
    #1.过程开始执行
	SET P_START_DT = current_timestamp();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '过程开始执行';
				 
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,current_timestamp(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);								

    #2.清除数据
	SET P_START_DT = current_timestamp();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '清除数据';
	
	TRUNCATE TABLE T_1_3;
	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,current_timestamp(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = current_timestamp();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
INSERT INTO YBT_DATACORE.T_1_3  (
    A030001, -- 01.员工ID
    A030002, -- 02.机构ID
    A030003, -- 03.姓名
    A030004, -- 04.国家地区
    A030005, -- 05.证件类型
    A030006, -- 06.证件号码
    A030007, -- 07.手机号码
    A030008, -- 08.办公电话
    A030009, -- 09.入职日期
    A030010, -- 10.所属部门
    A030011, -- 11.职务
    A030012, -- 12.高管标识
    A030013, -- 13.批复日期
    A030014, -- 14.任职日期
    A030015, -- 15.员工类型
    A030016, -- 16.岗位编号
    A030017, -- 17.岗位名称
    A030018, -- 18.岗位标识
    A030019, -- 19.上岗日期
    A030020, -- 20.最近一次轮岗日期
    A030021, -- 21.最近一次强制休假日期
    A030022, -- 22.员工状态
    A030023, -- 23.柜员号
    A030024, -- 24.柜员类型
    A030025, -- 25.柜员权限级别
    A030026, -- 26.柜员状态
    A030027, -- 27.备注
    A030028,  -- 28.采集日期
	DIS_DATA_DATE, -- 装入数据日期
	DIS_BANK_ID,    -- 机构号
	DIS_DEPT,
	DEPARTMENT_ID

)

SELECT     T1.EMP_ID AS A030001 -- 1.工号
          ,concat(substr(trim(T2.FIN_LIN_NUM),1,11),T1.ORG_NUM) AS A030002 -- 2.机构ID
          ,T1.NAME AS A030003  -- 3.姓名
          ,T1.NATION_ID AS A030004 -- 4.国籍
          ,B.GB_CODE AS A030005 -- 5.证件类别  102第二代居民身份证
          ,T1.ID_NUM  AS A030006 -- 6.证件号码
          ,T1.TEL AS A030007 -- 7.联系电话
          ,T1.TEL AS A030008 -- 8.办公电话
          ,date_format(to_date(from_unixtime(unix_timestamp(coalesce(T1.RZSJ,'99991231'),'yyyyMMdd'))),'yyyy-MM-dd')  AS A030009 -- 9.入职日期
          ,T1.DEP AS A030010
       -- ,T1.POST AS A030011  -- 取人力的职务字段   -- 2.0 ZDSJ H 
          ,coalesce(B1.GB_CODE_NAME,T1.POST) AS A030011 -- [JLBA202507250003][20250909][巴启威][吴大为]: 职务映射为中文描述
          ,coalesce(T1.MANGER_FLG,'0') AS A030012 -- 12.是否高管
          ,date_format(to_date(from_unixtime(unix_timestamp(coalesce(T1.PT_DATE,'99991231'),'yyyyMMdd'))),'yyyy-MM-dd') AS A030013-- 13.批复日期
          ,date_format(to_date(from_unixtime(unix_timestamp(coalesce(T1.RZ_DATE,'99991231'),'yyyyMMdd'))),'yyyy-MM-dd') AS A030014  -- 14.任职日期
          ,CASE WHEN T1.YG_TYPE = 'A' THEN '01' -- '正式员工'
                WHEN T1.YG_TYPE = 'C' THEN '02' -- '非正式员工' 
                ELSE '03' -- '其他-' || T1.YG_TYPE_ADD
                 END AS A030015  -- 15.员工类型
           ,T1.POST_NUM  AS A030016 -- 16.岗位编号
           ,T3.POST_NAME AS A030017 -- 17.岗位名称
           ,T3.GWBS AS A030018
           ,CASE WHEN T4.TELLER_FLG = 'N' THEN '9999-12-31'
                 WHEN T1.WORK_DATE IS NOT NULL THEN date_format(to_date(from_unixtime(unix_timestamp(T1.WORK_DATE,'yyyyMMdd'))),'yyyy-MM-dd') -- 一表通校验修改  20240904 王金保
                 ELSE date_format(to_date(from_unixtime(unix_timestamp(T4.WORK_DATE,'yyyyMMdd'))),'yyyy-MM-dd')
                  END AS A030019  -- 19.上岗日期
           ,date_format(to_date(from_unixtime(unix_timestamp(coalesce(T1.ZJYCLGRQ,'99991231'),'yyyyMMdd'))),'yyyy-MM-dd') as A030020  -- 20.最近一次轮岗日期
           ,date_format(to_date(from_unixtime(unix_timestamp(coalesce(T1.ZJYCQZXJRQ,'99991231'),'yyyyMMdd'))),'yyyy-MM-dd')  as A030021-- 21.最近一次强制休假日期
           ,CASE WHEN T1.EMP_STATE in ('A','A01','A02') THEN '01' -- '在职'
                 WHEN T1.EMP_STATE = 'C' THEN '02' -- '退休'
                 WHEN T1.EMP_STATE = 'B' THEN '04' -- '离职'
                 ELSE '00' -- '其他'
                 END  as A030022 -- 22.员工状态
           ,T4.TELLER_NUM  as A030023 -- 23.柜员号
           ,CASE WHEN T4.TELLER_TYPE = '实体柜员' THEN  '01'
                 WHEN T4.TELLER_TYPE IN ('虚拟柜员' ,'机具柜员') THEN '02'  -- [20250415][姜俐锋][JLBA202502210009][吴大为]: 修改柜员类型映射关系，机具柜员映射为虚拟柜员
                 ELSE '00' 
                  END AS A030024  -- 24.柜员类型 
		   ,CASE WHEN T4.TELLER_NUM  IS NOT NULL THEN '00' ELSE NULL  END AS A030025   -- T4.AUTH_LV -- 25.柜员权限级别    UPDATE ZJK 20250113   数据管理部吴大为 运营管理部张昕确认  柜员不为空类型默认为其他
           ,CASE WHEN T4.TELLER_STS IN ('初始','正式签到','正式签退','冻结','锁定','密挂','正常') THEN '01' -- '在岗'
		         WHEN T4.TELLER_STS ='注销' THEN '02' -- '离岗'
		         ELSE '00' -- '其他-其他' 
		         END  AS A030026      -- 20250116    
           ,NULL AS A030027 -- 27.备注
           ,date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd') AS A030028 -- 28.采集日期
           ,date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd') AS DIS_DATA_DATE
           , '990000' AS DIS_BANK_ID
           ,'' AS DIS_DEPT
           ,'0098RL' AS  DEPARTMENT_ID
      FROM SMTMODS.L_PUBL_EMP  T1 -- 员工表
      LEFT JOIN VIEW_L_PUBL_ORG_BRA T2 
        ON T1.ORG_NUM = T2.ORG_NUM -- 这两个机构取总行
       AND T2.DATA_DATE = I_DATE
      LEFT JOIN  -- 岗位信息表      20240305   一个岗位编号对应多个机构数据信息  导致数据翻倍
              (SELECT T6.POST_NUM,T6.POST_NAME,T6.DATA_DATE,T6.GWBS FROM (   -- 2.0ZDSJ H
               SELECT  
               T5.POST_NUM,
               T5.POST_NAME,
               T5.DATA_DATE,
               T5.GWBS,        -- 2.0ZDSJ H
               ROW_NUMBER () OVER(PARTITION BY T5.POST_NUM ORDER BY T5.DATA_DATE/**T5.ORG_NUM**/ DESC) AS NR   -- 0624_LHY 排序改为按日期排序
               FROM SMTMODS.L_PUBL_POST T5 WHERE T5.CANCEL_FLAG = 'N' AND T5.DATA_DATE = I_DATE)T6    
               WHERE NR = '1')T3
        ON T1.POST_NUM = T3.POST_NUM
      LEFT JOIN (SELECT T9.* FROM (SELECT T8.*,
                                   ROW_NUMBER()  OVER(PARTITION BY T8.EMP_ID ORDER BY T8.WORK_DATE DESC) AS NR
                                   FROM SMTMODS.L_PUBL_TELLER T8
                                  WHERE T8.DATA_DATE = I_DATE
                                    AND (T8.TELLER_TYPE <> '虚拟柜员' OR T8.TELLER_NUM NOT LIKE 'H%' OR T8.TELLER_NUM NOT LIKE 'E%') )T9 WHERE NR='1') T4 -- 柜员表
        ON T1.EMP_ID = T4.EMP_ID 
      LEFT JOIN M_DICT_CODETABLE B
        ON T1.ID_TYPE = B.L_CODE
       AND B.L_CODE_TABLE_CODE = 'C0001' 
      LEFT JOIN M_DICT_CODETABLE B1 -- [JLBA202507250003][20250909][巴启威][吴大为]: 职务映射为中文描述
        ON T1.POST = B1.L_CODE
      AND B1.L_CODE_TABLE_CODE = 'C0028'     
     WHERE T1.DATA_DATE = I_DATE
       AND T1.ORG_NUM<>'999999' AND T1.ORG_NUM NOT LIKE '5%'  -- 0624_LHY 同步EAST逻辑
       AND T1.ORG_NUM NOT LIKE '6%' AND T1.ORG_NUM NOT LIKE '7%' AND   T2.ORG_NAM NOT  LIKE  '%村镇%' 
       AND T1.ORG_NUM NOT IN ('120000','120100','120101','021203','020206','021305','020212','021407','020214','021204','020204','010312','010624','010625','010627','010911','012512');
 
    INSERT INTO T_1_3  (
    A030001, -- 01.员工ID
    A030002, -- 02.机构ID
    A030003, -- 03.姓名
    A030004, -- 04.国家地区
    A030005, -- 05.证件类型
    A030006, -- 06.证件号码
    A030007, -- 07.手机号码
    A030008, -- 08.办公电话
    A030009, -- 09.入职日期
    A030010, -- 10.所属部门
    A030011, -- 11.职务
    A030012, -- 12.高管标识
    A030013, -- 13.批复日期
    A030014, -- 14.任职日期
    A030015, -- 15.员工类型
    A030016, -- 16.岗位编号
    A030017, -- 17.岗位名称
    A030018, -- 18.岗位标识
    A030019, -- 19.上岗日期
    A030020, -- 20.最近一次轮岗日期
    A030021, -- 21.最近一次强制休假日期
    A030022, -- 22.员工状态
    A030023, -- 23.柜员号
    A030024, -- 24.柜员类型
    A030025, -- 25.柜员权限级别
    A030026, -- 26.柜员状态
    A030027, -- 27.备注
    A030028,  -- 28.采集日期
	DIS_DATA_DATE, -- 装入数据日期
	DIS_BANK_ID,    -- 机构号
	DIS_DEPT,
	DEPARTMENT_ID

)    
      SELECT 
          T1.EMP_ID as A030001 -- 1.工号
          ,concat(substr(trim(T3.FIN_LIN_NUM),1,11),T3.ORG_NUM) as A030002 -- 2.机构ID
          ,'XNGY' AS A030003  -- 3.姓名
          ,'CHN' AS A030004 -- 4.国籍
          ,NULL AS A030005 -- 5.证件类别  102第二代居民身份证
          ,NULL AS A030006 -- 6.证件号码
          ,NULL AS A030007 -- 7.联系电话
          ,NULL AS A030008-- 8.办公电话
          ,'9999-12-31' AS A030009-- 9.入职日期
          ,T1.DEPARTMENTD AS A030010
          ,NULL AS A030011 -- 11.岗位名称     与EAST统一取机构负责人职务
          ,'0' AS A030012-- 12.是否高管
          ,'9999-12-31' AS A030013 -- 13.批复日期
          ,'9999-12-31' AS A030014  -- 14.任职日期
          ,'03' AS A030015 -- '其他-'  -- 15.员工类型
          ,T1.POST_NUM /**'00022967'**/ AS A030016-- 16.岗位编号
          ,'02' AS A030017 -- 17.岗位名称 
          ,'00000' AS A030018 -- 18.岗位标识
          ,'9999-12-31' AS A030019 -- 19.上岗日期
          ,'9999-12-31' AS A030020 -- 20.最近一次轮岗日期
          ,'9999-12-31' AS A030021 -- 21.最近一次强制休假日期
          , '00'   AS A030022 -- 22.员工状态
           ,T1.TELLER_NUM AS A030023-- 23.柜员号
           ,CASE WHEN T1.TELLER_TYPE IN ('虚拟柜员' ,'机具柜员') THEN '02'  -- [20250415][姜俐锋][JLBA202502210009][吴大为]: 修改柜员类型映射关系，机具柜员映射为虚拟柜员
                ELSE '00' END AS A030024 -- 24.柜员类型
           ,'00' AS A030025 -- 柜员权限级别
           , CASE WHEN  T1.TELLER_STS IN ('初始','锁定','正式签退','正常','密挂') THEN '01'
             WHEN T1.TELLER_STS IN ('注销','离岗')THEN '02'
             ELSE '00'
              END   AS A030026                -- YBT EAST TS
           ,null as A030027 -- 27.备注
           ,date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd') as A030028 -- 28.采集日期
           ,date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd') as DIS_DATA_DATE
           , T1.ORG_NUM as DIS_BANK_ID
           ,'' as DIS_DEPT
           ,'0098RL' as DEPARTMENT_ID
 FROM SMTMODS.L_PUBL_TELLER T1
      INNER JOIN VIEW_L_PUBL_ORG_BRA T3 -- 机构表  
        ON T1.ORG_NUM = T3.ORG_NUM
       AND T3.DATA_DATE = I_DATE
     WHERE   T1.DATA_DATE = I_DATE
       and T1.TELLER_TYPE<>'实体柜员'
       AND T1.ORG_NUM NOT IN ('012102','012103','012104','012105','012106','012107','012108');
       
      COMMIT;
    
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,current_timestamp(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);		

    #4.过程结束执行
	SET P_START_DT = current_timestamp();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '过程结束执行';
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,current_timestamp(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
   SET OI_RETCODE = P_STATUS; 
   SET OI_REMESSAGE = P_DESCB;
   SELECT OI_RETCODE,'|',OI_REMESSAGE;

EXCEPTION
  WHEN ANY THEN
    SET P_SQLCDE = cast(SQLCODE AS STRING);
    SET P_STATE = SQLSTATE;
    SET P_SQLMSG = SQLERRM;
    SET P_STATUS = -1;
    SET P_START_DT = current_timestamp();
    SET P_STEP_NO = P_STEP_NO + 1;
    SET P_DESCB = '程序异常';
    CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,current_timestamp(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    SET OI_RETCODE = P_STATUS;
    SET OI_REMESSAGE = concat(P_DESCB, ':', P_SQLCDE, ' - ', P_SQLMSG);
    SELECT OI_RETCODE,'|',OI_REMESSAGE;
END;

