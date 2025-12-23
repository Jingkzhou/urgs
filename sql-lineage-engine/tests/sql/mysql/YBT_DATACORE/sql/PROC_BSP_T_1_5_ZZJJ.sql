DROP PROCEDURE IF EXISTS PROC_BSP_T_1_5_ZZJJ;

CREATE PROCEDURE PROC_BSP_T_1_5_ZZJJ(
  IN I_DATE STRING,
  OUT OI_RETCODE INT,
  OUT OI_REMESSAGE STRING
)
LANGUAGE HIVE
BEGIN
  /******
        程序名称  ：自助机具
        程序功能  ：加工自助机具
        目标表：T_1_5
        创建人  ：LZ
        创建日期  ：20240110
        版本号：V0.0.1 
  ******/
  -- JLBA202412200001_关于一表通监管数据报送系统修改逻辑及转EAST脚本的需求_20250116
  /*需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为 修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/

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
  SET P_PROC_NAME = 'PROC_BSP_T_1_5_ZZJJ';
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
  TRUNCATE TABLE T_1_5;
  CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,current_timestamp(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);

  #3.数据插入
  SET P_START_DT = current_timestamp();
  SET P_STEP_NO = P_STEP_NO + 1;
  SET P_DESCB = '数据插入';
  INSERT INTO YBT_DATACORE.T_1_5 (
    A050001,
    A050002,
    A050003,
    A050004,
    A050005,
    A050006,
    A050007,
    A050008,
    A050009,
    A050010,
    A050011,
    A050012,
    DIS_DATA_DATE,
    DIS_BANK_ID,
    DIS_DEPT,
    DEPARTMENT_ID
  )
  SELECT
    T1.EQUIPMENT_NBR AS A050001,
    CASE
      WHEN T1.EQUIPMENT_TYP = 'B' THEN concat(substr(trim(T5.FIN_LIN_NUM),1,11),T4.ORG_NUM)
      ELSE concat(substr(trim(T2.FIN_LIN_NUM),1,11),T1.ORG_NUM)
    END AS A050002,
    CASE
      WHEN T1.EQUIPMENT_TYP = 'A' THEN '01'
      WHEN T1.EQUIPMENT_TYP = 'H' THEN '02'
      ELSE '00'
    END AS A050003,
    T1.SBGYS AS A050004,
    T1.SBWHS AS A050005,
    T1.JJXH AS A050006,
    T1.SBDZ AS A050007,
    CASE
      WHEN T1.EQUIPMENT_TYP IN ('A','H','G') THEN T1.EQUIPMENT_NBR
      ELSE ''
    END AS A050008,
    CASE
      WHEN T1.EQUIPMENT_TYP IN ('A','H','G') THEN coalesce(date_format(to_date(from_unixtime(unix_timestamp(T1.SBQYRQ,'yyyyMMdd'))),'yyyy-MM-dd'),'2019-06-25')
      ELSE coalesce(date_format(to_date(from_unixtime(unix_timestamp(T1.SBQYRQ,'yyyyMMdd'))),'yyyy-MM-dd'),'9999-12-31')
    END AS A050009,
    CASE
      WHEN T1.EQUIPMENT_STS = 'A' THEN '9999-12-31'
      ELSE coalesce(date_format(to_date(from_unixtime(unix_timestamp(T1.SBTYRQ,'yyyyMMdd'))),'yyyy-MM-dd'),'9999-12-31')
    END AS A050010,
    CASE
      WHEN (T1.EQUIPMENT_STS = 'A' OR T1.ORG_NUM = '009822') THEN '01'
      WHEN T1.EQUIPMENT_STS = 'U' THEN '03'
      ELSE '00'
    END AS A050011,
    date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd') AS A050012,
    date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd') AS DIS_DATA_DATE,
    '990000' AS DIS_BANK_ID,
    '' AS DIS_DEPT,
    CASE
      WHEN T1.EQUIPMENT_TYP = 'B' THEN '009821'
      ELSE '009822'
    END AS DEPARTMENT_ID
  FROM SMTMODS.L_PUBL_EQUIPMENT T1
  LEFT JOIN SMTMODS.L_PUBL_ORG_BRA T2
    ON T1.ORG_NUM = T2.ORG_NUM
   AND T2.DATA_DATE = I_DATE 
  LEFT JOIN SMTMODS.L_PUBL_TAG_END_MERCHANT T3
    ON T3.TERMINAL_NO = T1.EQUIPMENT_NBR
   AND T3.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_PUBL_MERCHANT T4
    ON T4.MERCHANT_NBR = T3.MERCHANT_NBR
   AND T4.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_PUBL_ORG_BRA T5
    ON T4.ORG_NUM = T5.ORG_NUM
   AND T5.DATA_DATE = I_DATE
  LEFT JOIN otds_data.T_1_5 T6
    ON T1.EQUIPMENT_NBR = T6.A050001
   AND T6.A050012 = date_format(date_sub(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),1),'yyyyMMdd')
  LEFT JOIN otds_data.T_1_5 T7
    ON T1.EQUIPMENT_NBR = T7.A050001
   AND T6.A050012 = date_format(to_date(from_unixtime(unix_timestamp(concat(cast(year(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))) - 1 AS STRING),'1231'),'yyyyMMdd'))),'yyyyMMdd')
  WHERE (
          T1.EQUIPMENT_STS <> 'U'
          OR (T6.A050011 <> '03' AND T1.EQUIPMENT_STS = 'U')
          OR T7.A050011 <> '03'
        )
    AND (
          (T1.EQUIPMENT_TYP IN ('A','H','G') AND T1.SFSTJJ = 'Y')
          OR T1.EQUIPMENT_TYP NOT IN ('A','H','G')
        )
    AND T1.DATA_DATE = I_DATE
    AND (
          (
            T1.ORG_NUM <> '999999'
            AND T1.ORG_NUM NOT LIKE '5%'
            AND T1.ORG_NUM NOT LIKE '6%'
            AND T1.ORG_NUM NOT LIKE '7%'
            AND T2.ORG_NAM NOT LIKE '%村镇%'
            AND T1.ORG_NUM NOT IN (
              '120000','120100','120101','021203','020206','021305',
              '020212','021407','020214','021204','020204',
              '010312','010624','010625','010627','010911','012512'
            )
          )
          OR T2.ORG_NUM IS NULL
        );

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


