DROP PROCEDURE IF EXISTS PROC_BSP_T_2_5_GRKHJBQK;

CREATE PROCEDURE PROC_BSP_T_2_5_GRKHJBQK(
  IN I_DATE STRING,
  OUT OI_RETCODE INT,
  OUT OI_REMESSAGE STRING
)
LANGUAGE HIVE
BEGIN

  /******
        程序名称  ：个人客户基本情况
        程序功能  ：加工个人客户基本情况
        目标表：T_2_5
        源表  ：  一段
        创建人  ：87v
        创建日期  ：20240109
        版本号：V0.0.1 
  ******/
  -- JLBA202411070004_关于一表通监管数据报送系统修改逻辑的需求 20241212
  /*需求编号：JLBA202504160004   上线日期：20250708，修改人：姜俐锋，提出人：吴大为 关于吉林银行修改单一客户授信逻辑的需求*/
  /*需求编号：JLBA202507250003 上线日期：2025-09-09，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统修改取数逻辑的需求*/

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
  SET P_PROC_NAME = 'PROC_BSP_T_2_5_GRKHJBQK';
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
  TRUNCATE TABLE ybt_datacore.T_2_5;
  CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,current_timestamp(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);

  #3.cust_p数据插入
  SET P_START_DT = current_timestamp();
  SET P_STEP_NO = P_STEP_NO + 1;
  SET P_DESCB = 'cust_p数据插入';
  INSERT INTO ybt_datacore.T_2_5 (
    B050001, B050002, B050003, B050004, B050005, B050006, B050007, B050008, B050009, B050010,
    B050011, B050012, B050013, B050014, B050015, B050016, B050017, B050018, B050019, B050020,
    B050021, B050022, B050023, B050024, B050026, B050027, B050028, B050029, B050030, B050031,
    B050032, B050033, B050034, B050035, B050036, DIS_DATA_DATE, DIS_BANK_ID, DEPARTMENT_ID, B050037
  )
  SELECT
    T1.CUST_ID AS B050001,
    ORG.ORG_ID AS B050002,
    T2.CUST_NAM AS B050003,
    CASE
      WHEN T1.OPERATE_CUST_TYPE = 'A' THEN '02'
      WHEN T1.OPERATE_CUST_TYPE = 'B' THEN '03'
      WHEN T2.INLANDORRSHORE_FLG = 'N' THEN '04'
      ELSE '01'
    END AS B050004,
    CASE WHEN substr(T1.ID_TYPE,1,2) = '10' THEN T1.ID_NO END AS B050005,
    CASE WHEN substr(T1.ID_TYPE,1,2) = '12' THEN T1.ID_NO END AS B050006,
    CASE WHEN substr(T1.ID_TYPE,1,2) NOT IN ('10','12') THEN M.GB_CODE END AS B050007,
    CASE WHEN substr(T1.ID_TYPE,1,2) NOT IN ('10','12') THEN T1.ID_NO END AS B050008,
    CASE
      WHEN T1.NATION_CD <> 'CHN' AND A5.GB_CODE_NAME IS NULL THEN NULL
      WHEN T1.NATION_CD <> 'CHN' AND A5.GB_CODE_NAME IS NOT NULL THEN A5.GB_CODE_NAME
      WHEN coalesce(T1.NATION_CD,'CHN') = 'CHN' THEN coalesce(A5.GB_CODE_NAME,'汉族')
    END AS B050009,
    CASE
      WHEN T1.SEX_TYP = '1' THEN '01'
      WHEN T1.SEX_TYP = '2' THEN '02'
    END AS B050010,
    CASE
      WHEN T1.EDUCATION_CD_SUB = '17' THEN '18'
      WHEN T1.EDUCATION_CD_SUB = '83' THEN '82'
      WHEN T1.EDUCATION_CD_SUB = '18' THEN '90'
      ELSE T1.EDUCATION_CD_SUB
    END AS B050011,
    CASE
      WHEN T1.BIRTH_DT IS NOT NULL THEN date_format(to_date(from_unixtime(unix_timestamp(T1.BIRTH_DT,'yyyyMMdd'))),'yyyy-MM-dd')
      WHEN T2.ID_TYPE LIKE '10%' AND length(T2.ID_NO) = 18 AND substr(T2.ID_NO,7,8) IS NOT NULL AND substr(T2.ID_NO,7,8) NOT LIKE '00%'
        THEN date_format(to_date(from_unixtime(unix_timestamp(substr(T2.ID_NO,7,8),'yyyyMMdd'))),'yyyy-MM-dd')
      ELSE '9999-12-31'
    END AS B050012,
    CASE
      WHEN T1.MARRIAGE_TYP IN ('20','21','22','23') THEN '1'
      WHEN T1.MARRIAGE_TYP IN ('10','30','40') THEN '0'
      WHEN T1.MARRIAGE_TYP = '90' THEN NULL
    END AS B050013,
    coalesce(T3.CUST_TELEPHONE_NO,T3.HAND_PHONE_NO) AS B050014,
    coalesce(T3.HAND_PHONE_NO,T3.CUST_TELEPHONE_NO) AS B050015,
    T1.CORP_NAM AS B050016,
    T3.CORP_PHONE_NO AS B050017,
    T3.CORP_ADDRESS AS B050018,
    CASE
      WHEN T3.UNIT_NATURE = 'A' THEN '01'
      WHEN T3.UNIT_NATURE = 'B' THEN '02'
      WHEN T3.UNIT_NATURE = 'C' THEN '03'
      WHEN T3.UNIT_NATURE = 'D' THEN '04'
      WHEN T3.UNIT_NATURE = 'E' THEN '05'
      WHEN T3.UNIT_NATURE = 'F' THEN '06'
      ELSE '00'
    END AS B050019,
    T1.VOCATION_TYP AS B050020,
    T1.POST_TYP AS B050021,
    T1.INCOME_YEAR AS B050022,
    CASE
      WHEN coalesce(T1.INCOME_YEAR,0) <> 0 THEN T1.INCOME_YEAR
      ELSE T1.INCOME * 12
    END AS B050023,
    T3.CUST_ADDE_DESC AS B050024,
    CASE WHEN T1.STAFF_FLG = 'Y' THEN '1' WHEN T1.STAFF_FLG = 'N' THEN '0' END AS B050026,
    CASE WHEN T1.FIRST_CREDIT_DATE IS NULL THEN '9999-12' ELSE date_format(to_date(from_unixtime(unix_timestamp(T1.FIRST_CREDIT_DATE,'yyyyMMdd'))),'yyyy-MM') END AS B050027,
    CASE WHEN T1.BLACKLIST_FLG = 'Y' THEN '1' WHEN T1.BLACKLIST_FLG = 'N' THEN '0' ELSE '0' END AS B050028,
    CASE
      WHEN T1.BLACKLIST_DATE IS NULL OR T1.BLACKLIST_DATE LIKE '1899%' THEN '9999-12-31'
      WHEN T1.BLACKLIST_DATE > I_DATE THEN date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd')
      ELSE date_format(to_date(from_unixtime(unix_timestamp(T1.BLACKLIST_DATE,'yyyyMMdd'))),'yyyy-MM-dd')
    END AS B050029,
    substr(T1.BLACKLIST_REASON,1,200) AS B050030,
    CASE WHEN T2.RESIDENT_FLG = '1' THEN '1' WHEN T2.RESIDENT_FLG = '2' THEN '0' ELSE '0' END AS B050031,
    CASE WHEN T1.NATION_CD = 'TLS' THEN 'TMP' ELSE coalesce(T1.NATION_CD,'CHN') END AS B050032,
    CASE WHEN T1.CITY_VILLAGE_FLG = 'Y' THEN '1' WHEN T1.CITY_VILLAGE_FLG = 'N' THEN '0' ELSE '0' END AS B050033,
    CASE WHEN P1.COL_12 IS NOT NULL THEN '1' ELSE '0' END AS B050034,
    CASE WHEN P1.COL_11 IS NOT NULL THEN '1' ELSE '0' END AS B050035,
    date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd') AS B050036,
    date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd') AS DIS_DATA_DATE,
    T1.ORG_NUM AS DIS_BANK_ID,
    '0098SJ' AS DEPARTMENT_ID,
    coalesce(T1.ORG_AREA,T1.REGION_CD) AS B050037
  FROM SMTMODS.L_CUST_P T1
  LEFT JOIN SMTMODS.L_CUST_ALL T2
    ON T1.CUST_ID = T2.CUST_ID AND T2.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_CUST_CONTACT T3
    ON T1.CUST_ID = T3.CUST_ID AND T3.DATA_DATE = I_DATE
  LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
    ON T1.ORG_NUM = ORG.ORG_NUM AND ORG.DATA_DATE = I_DATE
  LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M
    ON T1.ID_TYPE = M.L_CODE AND M.L_CODE_TABLE_CODE = 'C0001'
  LEFT JOIN YBT_DATACORE.T_2_5_POORHOUSEHOLD P1
    ON T1.ID_NO = P1.COL_12 AND P1.PATH LIKE 'D:\zjk\贫困户名录%'
  LEFT JOIN YBT_DATACORE.T_2_5_POORHOUSEHOLD P2
    ON T1.ID_NO = P2.COL_11 AND P2.PATH LIKE 'D:\zjk\编外户\%'
  LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE A5
    ON T1.CUST_NATION = A5.L_CODE AND A5.L_CODE_TABLE_CODE = 'C0097'
  WHERE T1.DATA_DATE = I_DATE
    AND (
      EXISTS (SELECT 1 FROM ybt_datacore.t_4_3 A
              WHERE A.D030015 = date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd')
              AND A.D030003 = T1.CUST_ID)
      OR EXISTS (SELECT 1 FROM ybt_datacore.t_8_13 B
              WHERE B.H130023 = date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd')
              AND B.H130002 = T1.CUST_ID)
      OR EXISTS (SELECT 1 FROM ybt_datacore.t_8_5 C
              WHERE C.H050018 = date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd')
              AND C.H050004 = T1.CUST_ID)
      OR EXISTS (SELECT 1 FROM ybt_datacore.t_7_4 D
              WHERE D.G040033 = date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd')
              AND D.G040004 = T1.CUST_ID)
      OR EXISTS (SELECT 1 FROM ybt_datacore.t_8_4 E
              WHERE E.H040036 = date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd')
              AND E.H040001 = T1.CUST_ID)
      OR EXISTS (SELECT 1 FROM YBT_DATACORE.T_7_1 F
              WHERE F.G010032 = date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd')
              AND F.G010003 = T1.CUST_ID)
      OR EXISTS (SELECT 1 FROM YBT_DATACORE.T_7_11 G
              WHERE G.G110013 = date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd')
              AND G.G110002 = T1.CUST_ID)
      OR EXISTS (SELECT 1 FROM YBT_DATACORE.T_1_3 H
              WHERE H.A030028 = date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd')
              AND H.A030006 = T1.ID_NO)
      OR EXISTS (SELECT 1 FROM YBT_DATACORE.T_6_2 J
              WHERE J.F020063 = date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd')
              AND J.F020003 = T1.CUST_ID)
      OR EXISTS (SELECT 1 FROM YBT_DATACORE.T_6_9 K
              WHERE K.F090036 = date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd')
              AND K.F090003 = T1.CUST_ID)
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

