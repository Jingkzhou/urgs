DROP PROCEDURE IF EXISTS PROC_BSP_T_1_6_GDJGLFXX;

CREATE PROCEDURE PROC_BSP_T_1_6_GDJGLFXX(
  IN I_DATE STRING,
  OUT OI_RETCODE INT,
  OUT OI_REMESSAGE STRING
)
LANGUAGE HIVE
BEGIN
  /******
        程序名称  ：股东及关联方信息
        程序功能  ：加工股东及关联方信息
        目标表：T_1_6
        源表  ：
        创建人  ：LZ
        创建日期  ：20240109
        版本号：V0.0.1 
JLBA202501020005 关于关联方名单对接一表通及EAST的需求 上线日期：2025-03-27 修改人：王超，提出人：胡春雨   修改原因：将合规系统关联方名单下发到一表通及EAST系统
  ******/

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

  #变量初始化
  SET P_DATE = to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd')));
  SET BEG_MON_DT = date_format(trunc(P_DATE,'MM'),'yyyyMMdd');
  SET BEG_QUAR_DT = date_format(trunc(P_DATE,'Q'),'yyyyMMdd');
  SET BEG_YEAR_DT = date_format(trunc(P_DATE,'YY'),'yyyyMMdd');
  SET LAST_MON_DT = date_format(date_sub(trunc(P_DATE,'MM'),1),'yyyyMMdd');
  SET LAST_QUAR_DT = date_format(date_sub(trunc(P_DATE,'Q'),1),'yyyyMMdd');
  SET LAST_YEAR_DT = date_format(date_sub(trunc(P_DATE,'YY'),1),'yyyyMMdd');
  SET LAST_DT = date_format(date_sub(P_DATE,1),'yyyyMMdd');
  SET P_PROC_NAME = 'PROC_BSP_T_1_6_GDJGLFXX';
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
  TRUNCATE TABLE T_1_6;
  CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,current_timestamp(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);

  #3.关联方数据插入
  SET P_START_DT = current_timestamp();
  SET P_STEP_NO = P_STEP_NO + 1;
  SET P_DESCB = '关联方数据插入';
  INSERT INTO YBT_DATACORE.T_1_6 (
    A060001,
    A060002,
    A060003,
    A060004,
    A060005,
    A060006,
    A060007,
    A060008,
    A060009,
    A060010,
    A060011,
    A060012,
    A060013,
    A060014,
    A060015,
    A060016,
    A060017,
    A060018,
    A060019,
    A060020,
    A060021,
    A060022,
    A060023,
    A060025,
    A060026,
    A060027,
    A060028,
    A060024,
    DIS_DATA_DATE,
    DIS_BANK_ID,
    DEPARTMENT_ID
  )
  SELECT
    T1.VIEW_ID AS A060001,
    'B0302H22201009828' AS A060002,
    T1.RELATION_NAME AS A060003,
    T1.MAIN_TYPE AS A060004,
    T1.ZJLB AS A060005,
    T1.DOCUMENT_NO AS A060006,
    regexp_replace(regexp_replace(T1.BUSINESS_TYPE,'[[]',''), '[]]','') AS A060007,
    T1.REGISTER_ADDRESS AS A060008,
    regexp_replace(regexp_replace(T1.GXLX,'[[]',''), '[]]','') AS A060009,
    T1.CONTROL_NAME AS A060010,
    T1.BANK_COUNT AS A060011,
    T1.BANK_NUM AS A060012,
    T1.BAD_INFO AS A060013,
    regexp_replace(regexp_replace(T1.LIMIT_FLAG,'[[]',''), '[]]','') AS A060014,
    CASE T1.MONEY_SOURCE
      WHEN '1' THEN '01'
      WHEN '2' THEN '02'
      WHEN '3' THEN '03'
      WHEN '4' THEN '04'
      ELSE NULL
    END AS A060015,
    T1.SOURCE_ACOUNT AS A060016,
    CASE T1.STATUS
      WHEN '0' THEN '00'
      WHEN '1' THEN '01'
      ELSE NULL
    END AS A060017,
    T1.STOCKHOLDER_NUM AS A060018,
    T1.STOCKHOLDER_SCALE AS A060019,
    coalesce(T1.INCOME_DATE,'9999-12-31') AS A060020,
    coalesce(T1.PLEDGE_RATIO,'0') AS A060021,
    regexp_replace(regexp_replace(T1.SEND_FLAG,'[[]',''), '[]]','') AS A060022,
    coalesce(
      date_format(from_unixtime(unix_timestamp(T1.LAST_CHANGE,'yyyy-MM-dd HH:mm:ss')),'yyyy-MM-dd'),
      '9999-12-31'
    ) AS A060023,
    NULL AS A060025,
    '0' AS A060026,
    NULL AS A060027,
    NULL AS A060028,
    date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd') AS A060024,
    date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd') AS DIS_DATA_DATE,
    '009828' AS DIS_BANK_ID,
    '009828' AS DEPARTMENT_ID
  FROM (
    SELECT
      SRC.*,
      row_number() OVER (PARTITION BY SRC.DOCUMENT_NO, SRC.RELATION_NAME ORDER BY SRC.DOCUMENT_NO) AS rn
    FROM SMTMODS.L_RELATION_STOCKHOLDER_ADD SRC
    WHERE SRC.DATA_DATE = I_DATE
  ) T1
  WHERE T1.rn = 1;
  CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,current_timestamp(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);

  #4.股东数据插入
  SET P_START_DT = current_timestamp();
  SET P_STEP_NO = P_STEP_NO + 1;
  SET P_DESCB = '股东数据插入';
  INSERT INTO YBT_DATACORE.T_1_6 (
    A060001,
    A060002,
    A060003,
    A060004,
    A060005,
    A060006,
    A060007,
    A060008,
    A060009,
    A060010,
    A060011,
    A060012,
    A060013,
    A060014,
    A060015,
    A060016,
    A060017,
    A060018,
    A060019,
    A060020,
    A060021,
    A060022,
    A060023,
    A060025,
    A060026,
    A060027,
    A060028,
    A060024,
    DIS_DATA_DATE,
    DIS_BANK_ID,
    DEPARTMENT_ID
  )
  SELECT
    T1.A060001,
    T1.A060002,
    T1.A060003,
    T1.A060004,
    T1.A060005,
    T1.A060006,
    T1.A060007,
    T1.A060008,
    T1.A060009,
    T1.A060010,
    T1.A060011,
    T1.A060012,
    T1.A060013,
    T1.A060014,
    T1.A060015,
    T1.A060016,
    T1.A060017,
    T1.A060018,
    T1.A060019,
    T1.A060020,
    T1.A060021,
    T1.A060022,
    T1.A060023,
    T1.A060025,
    T1.A060026,
    T1.A060027,
    T1.A060028,
    date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd') AS A060024,
    date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd') AS DIS_DATA_DATE,
    T1.DIS_BANK_ID,
    T1.DEPARTMENT_ID
  FROM OTDS_DATA.T_1_6 T1
  WHERE T1.DIS_DATA_DATE = date_format(date_sub(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),1),'yyyy-MM-dd')
    AND T1.DEPARTMENT_ID = '0098DB';
  CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,current_timestamp(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);

  #5.过程结束执行
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

