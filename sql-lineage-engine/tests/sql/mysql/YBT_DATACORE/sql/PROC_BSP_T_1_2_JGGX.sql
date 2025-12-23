DROP PROCEDURE IF EXISTS PROC_BSP_T_1_2_JGGX;

CREATE PROCEDURE PROC_BSP_T_1_2_JGGX(
  IN I_DATE STRING,
  OUT OI_RETCODE INT,
  OUT OI_REMESSAGE STRING
)
LANGUAGE HIVE
BEGIN
  /******
        程序名称  ：机构关系
        程序功能  ：加工机构关系
        目标表：T_1_2
        创建人  ：LZ
        创建日期  ：20240109
        版本号：V0.0.1 
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
  SET P_PROC_NAME = 'PROC_BSP_T_1_2_JGGX';
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
  TRUNCATE TABLE YBT_DATACORE.T_1_2;
  CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,current_timestamp(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);

  #3.数据插入
  SET P_START_DT = current_timestamp();
  SET P_STEP_NO = P_STEP_NO + 1;
  SET P_DESCB = '数据插入';
  INSERT INTO YBT_DATACORE.T_1_2 (
    A020001,
    A020002,
    A020003,
    DIS_DATA_DATE,
    DIS_BANK_ID,
    DIS_DEPT,
    DEPARTMENT_ID
  )
  SELECT
    concat(substr(coalesce(trim(T1.FIN_LIN_NUM),trim(T2.FIN_LIN_NUM)),1,11),T1.ORG_NUM) AS A020001,
    coalesce(concat(substr(trim(T2.FIN_LIN_NUM),1,11),T1.UP_ORG_NUM),'0') AS A020002,
    date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd') AS A020003,
    date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd') AS DIS_DATA_DATE,
    '990000' AS DIS_BANK_ID,
    '' AS DIS_DEPT,
    '009822' AS DEPARTMENT_ID
  FROM SMTMODS.L_PUBL_ORG_BRA T1
  LEFT JOIN SMTMODS.L_PUBL_ORG_BRA T2
    ON T1.UP_ORG_NUM = T2.ORG_NUM
   AND T1.DATA_DATE = T2.DATA_DATE
  WHERE T1.DATA_DATE = I_DATE
    AND T1.ORG_NUM <> '999999'
    AND T1.ORG_NUM NOT LIKE '5%'
    AND T1.ORG_NUM NOT LIKE '6%'
    AND T1.ORG_NUM NOT LIKE '7%'
    AND T1.ORG_NAM NOT LIKE '%村镇%'
    AND T1.ORG_NUM NOT IN (
      '120000','120100','120101','021203','020206','021305',
      '020212','021407','020214','021204','020204',
      '010312','010624','010625','010627','010911','012512'
    )
    AND (
      T1.ORG_STATUS <> 'U'
      OR EXISTS (
        SELECT 1
        FROM SMTMODS.L_PUBL_ORG_BRA T7
        WHERE T1.ORG_NUM = T7.ORG_NUM
          AND T7.ORG_STATUS <> 'U'
          AND T7.DATA_DATE = concat(cast(year(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))) - 1 AS STRING),'1231')
      )
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

