DROP PROCEDURE IF EXISTS PROC_BSP_T_2_2_JTJBQK;

CREATE PROCEDURE PROC_BSP_T_2_2_JTJBQK(
  IN I_DATE STRING,
  OUT OI_RETCODE INT,
  OUT OI_REMESSAGE STRING
)
LANGUAGE HIVE
BEGIN

  /******
        程序名称  ：集团基本情况
        程序功能  ：加工集团基本情况
        目标表：T_2_2
        源表  ： 两段 集团客户 和 供应链客户
        创建人  ：87v
        创建日期  ：20240105
        版本号：V0.0.1 
  ******/

  /* 需求编号：JLBA202502210009  上线日期：20250415，修改人：姜俐锋，提出人：吴大为 */
  /* 需求编号：JLBA202504060003 上线日期：20250513,修改人：狄家卉，提出人：吴大为  关于一表通监管数据报送系统、EAST报送系统修改取数逻辑的需求 */
  /* 需求编号：JLBA202504160004 上线日期：20250708，修改人：姜俐锋，提出人：吴大为 关于吉林银行修改单一客户授信逻辑的需求*/

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
  SET P_PROC_NAME = 'PROC_BSP_T_2_2_JTJBQK';
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
  TRUNCATE TABLE YBT_DATACORE.T_2_2;
  CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,current_timestamp(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);

  #3.集团客户数据插入
  SET P_START_DT = current_timestamp();
  SET P_STEP_NO = P_STEP_NO + 1;
  SET P_DESCB = '集团客户数据插入';
  INSERT INTO YBT_DATACORE.T_2_2 (
    B020001,
    B020002,
    B020003,
    B020004,
    B020020,
    B020005,
    B020006,
    B020007,
    B020008,
    B020009,
    B020010,
    B020011,
    B020012,
    B020013,
    B020014,
    B020015,
    B020016,
    B020017,
    B020018,
    B020019,
    DIS_DATA_DATE,
    DIS_BANK_ID,
    DEPARTMENT_ID
  )
  SELECT
    T1.CUST_GROUP_NO AS B020001,
    ORG.ORG_ID AS B020002,
    CASE WHEN T2.GROUP_FLAG = 'Y' THEN coalesce(T2.REGISTER_NBR,TT1.ID_NO) END AS B020003,
    T1.CUST_GROUP_CODE AS B020004,
    CASE WHEN T2.GROUP_FLAG = 'Y' THEN T2.GROUP_MEM_NO END AS B020020,
    CASE WHEN T2.GROUP_FLAG = 'Y' THEN T2.GROUP_MEM_NAM END AS B020005,
    '01' AS B020006,
    T1.CUST_GROUP_NAM AS B020007,
    T6.JTS AS B020008,
    T1.ZCDZ AS B020009,
    T2.NATION_CD AS B020010,
    T1.ZCDXZQH AS B020011,
    coalesce(date_format(to_date(from_unixtime(unix_timestamp(T1.GXZCXXRQ,'yyyyMMdd'))),'yyyy-MM-dd'),'9999-12-31') AS B020012,
    T1.OFFICE_ADDR AS B020013,
    T1.OFFICE_REGION_CD AS B020014,
    coalesce(date_format(to_date(from_unixtime(unix_timestamp(T1.UPDATE_OFFICE_DATE,'yyyyMMdd'))),'yyyy-MM-dd'),'9999-12-31') AS B020015,
    T4.RISK_SGN AS B020016,
    NULL AS B020017,
    CASE
      WHEN T1.CUS_RISK_LV_DE = '01' THEN 'AAA'
      WHEN T1.CUS_RISK_LV_DE = '02' THEN 'AA+'
      WHEN T1.CUS_RISK_LV_DE = '03' THEN 'AA'
      WHEN T1.CUS_RISK_LV_DE = '04' THEN 'AA-'
      WHEN T1.CUS_RISK_LV_DE = '05' THEN 'A+'
      WHEN T1.CUS_RISK_LV_DE = '06' THEN 'A'
      WHEN T1.CUS_RISK_LV_DE = '07' THEN 'A-'
      WHEN T1.CUS_RISK_LV_DE = '08' THEN 'BBB+'
      WHEN T1.CUS_RISK_LV_DE = '09' THEN 'BBB'
      WHEN T1.CUS_RISK_LV_DE = '10' THEN 'BBB-'
      WHEN T1.CUS_RISK_LV_DE = '11' THEN 'B'
      WHEN T1.CUS_RISK_LV_DE = '12' THEN 'C'
      WHEN T1.CUS_RISK_LV_DE = '13' THEN 'D'
      WHEN T1.CUS_RISK_LV_DE = '14' THEN 'E'
    END AS B020018,
    date_format(to_date(from_unixtime(unix_timestamp(T1.DATA_DATE,'yyyyMMdd'))),'yyyy-MM-dd') AS B020019,
    date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd') AS DIS_DATA_DATE,
    T1.ORG_NUM AS DIS_BANK_ID,
    '0098SJ' AS DEPARTMENT_ID
  FROM SMTMODS.L_CUST_C_GROUP_INFO T1
  LEFT JOIN SMTMODS.L_CUST_C_GROUP_MEM T2
    ON T1.CUST_GROUP_NO = T2.CUST_GROUP_NO
   AND T2.DATA_DATE = I_DATE
   AND T2.GROUP_FLAG = 'Y'
  LEFT JOIN SMTMODS.L_CUST_ALL T3
    ON T2.GROUP_MEM_NO = T3.CUST_ID
   AND T3.DATA_DATE = I_DATE
  LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG
    ON T1.ORG_NUM = ORG.ORG_NUM
   AND ORG.DATA_DATE = I_DATE
  LEFT JOIN (
    SELECT CUST_GROUP_NO, COUNT(*) AS JTS
    FROM SMTMODS.L_CUST_C_GROUP_MEM
    WHERE DATA_DATE = I_DATE
    GROUP BY CUST_GROUP_NO
  ) T6
    ON T1.CUST_GROUP_NO = T6.CUST_GROUP_NO
  LEFT JOIN (
    SELECT *
    FROM (
      SELECT AA.*,
             row_number() OVER (PARTITION BY AA.CUST_ID ORDER BY AA.RISK_SGN) AS RN
      FROM SMTMODS.L_CUST_C_RISK_SGN AA
      WHERE AA.DATA_DATE = I_DATE
    ) A
    WHERE A.RN = 1
  ) T4
    ON T1.CUST_GROUP_NO = T4.CUST_ID
   AND T4.DATA_DATE = I_DATE
  INNER JOIN (
    SELECT T.CUST_GROUP_NO
    FROM SMTMODS.L_CUST_C_GROUP_MEM T
    INNER JOIN SMTMODS.L_CUST_C C
      ON T.GROUP_MEM_NO = C.CUST_ID
     AND C.DATA_DATE = I_DATE
     AND C.CUST_TYP <> '3'
    WHERE T.DATA_DATE = I_DATE
    GROUP BY T.CUST_GROUP_NO
    HAVING COUNT(1) > 1
  ) TT
    ON T1.CUST_GROUP_NO = TT.CUST_GROUP_NO
  LEFT JOIN (
    SELECT T.CUST_GROUP_NO, C.ID_NO
    FROM SMTMODS.L_CUST_C_GROUP_MEM T
    INNER JOIN SMTMODS.L_CUST_C C
      ON T.GROUP_MEM_NO = C.CUST_ID
     AND C.DATA_DATE = I_DATE
     AND C.CUST_TYP <> '3'
     AND C.ID_TYPE = '236'
    WHERE T.DATA_DATE = I_DATE
      AND T.GROUP_FLAG = 'Y'
  ) TT1
    ON T1.CUST_GROUP_NO = TT1.CUST_GROUP_NO
  WHERE T1.DATA_DATE = I_DATE
    AND (
      EXISTS (
        SELECT 1
        FROM YBT_DATACORE.T_4_3 A
        WHERE A.D030015 = date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd')
          AND A.D030003 = T3.CUST_ID
      )
      OR EXISTS (
        SELECT 1
        FROM SMTMODS.L_AGRE_CREDITLINE B
        WHERE B.DATA_DATE = I_DATE
          AND B.FACILITY_STS = 'Y'
          AND B.CUST_ID = T3.CUST_ID
      )
      OR EXISTS (
        SELECT 1
        FROM YBT_DATACORE.T_6_2 C
        WHERE C.F020063 = date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd')
          AND C.F020003 = T3.CUST_ID
      )
      OR EXISTS (
        SELECT 1
        FROM YBT_DATACORE.T_3_3 D
        WHERE D.C030010 = date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd')
          AND D.C030007 = T1.CUST_GROUP_NO
      )
      OR EXISTS (
        SELECT 1
        FROM YBT_DATACORE.T_3_4 E
        WHERE E.C040011 = date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd')
          AND E.C040002 = T1.CUST_GROUP_NO
      )
    );

  CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,current_timestamp(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);

  /* 数管部吴大为：去除供应链，只要集团。供应链部分保留注释 */
  /* 
  #4.供应链客户数据插入
  -- ...existing code...
  */

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

