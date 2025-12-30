DROP PROCEDURE IF EXISTS PROC_BSP_T_1_1_JGXX;

CREATE PROCEDURE PROC_BSP_T_1_1_JGXX(
  IN I_DATE STRING,
  OUT OI_RETCODE INT,
  OUT OI_REMESSAGE STRING
)
LANGUAGE HIVE
BEGIN
  /****** 机构信息 ******/

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

  #异常处理
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
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
  SET P_PROC_NAME = 'PROC_BSP_T_1_1_JGXX';
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
  TRUNCATE TABLE T_1_1;
  CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,current_timestamp(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);

  #3.插入数据
  SET P_START_DT = current_timestamp();
  SET P_STEP_NO = P_STEP_NO + 1;
  SET P_DESCB = '数据插入';
  INSERT INTO T_1_1 (
    A010001, -- 01机构id
    A010002, -- 02内部机构号
    A010003, -- 03金融许可证号
    A010004, -- 04统一社会信用代码
    A010005, -- 05银行机构名称
    A010006, -- 06支付行号
    A010007, -- 07机构类型
    A010008, -- 08机构类别
    A010009, -- 09县域机构标识
    A010010, -- 10科技支行标识
    A010011, -- 11科技特色支行标识
    A010012, -- 12科技金融专营机构标识
    A010013, -- 13行政区划
    A010014, -- 14运营状态
    A010015, -- 15成立日期
    A010016, -- 16机构地址
    A010017, -- 17负责人姓名
    A010018, -- 18负责人工号
    A010019, -- 19负责人联系电话
    A010020, -- 20采集日期
    DIS_DATA_DATE,  -- 装入数据日期
    DIS_BANK_ID,    -- 机构号
    DIS_DEPT,
    DEPARTMENT_ID,
    A010021,  -- 2.0zdsj  h
    A010022,  -- 2.0zdsj  h
    A010023   -- 2.0zdsj  h
)
SELECT
    A010001,
    A010002,
    A010003,
    A010004,
    -- 判断：若同一名称重复且成立日期最早，则名称后追加（待撤销）
    CASE 
      WHEN dup_cnt > 1 AND rn = 1 THEN concat(computed_name,'(待撤销)')
      ELSE computed_name
    END AS A010005,
    A010006,
    A010007,
    A010008,
    A010009,
    A010010,
    A010011,
    A010012,
    A010013,
    A010014,
    A010015,
    A010016,
    A010017,
    A010018,
    A010019,
    A010020,
    DIS_DATA_DATE,
    DIS_BANK_ID,
    DIS_DEPT,
    DEPARTMENT_ID,
    A010021,
    A010022,
    A010023
FROM (
  SELECT 
    inner_q.*,
    COUNT(*) OVER (PARTITION BY computed_name) AS dup_cnt,
    ROW_NUMBER() OVER (PARTITION BY computed_name ORDER BY established_date ASC) AS rn
  FROM (
    SELECT
      concat(substr(coalesce(trim(T1.FIN_LIN_NUM), trim(T2.FIN_LIN_NUM)),1,11), T1.ORG_NUM) AS A010001, -- 机构id
      T1.ORG_NUM AS A010002, -- 内部机构号
      COALESCE(TRIM(T1.FIN_LIN_NUM), TRIM(T2.FIN_LIN_NUM), TRIM(T4.FIN_LIN_NUM)) AS A010003, -- 金融许可证号
      COALESCE(T1.ID_NO, T2.ID_NO, T4.ID_NO, T5.ID_NO, T6.ID_NO) AS A010004, -- 统一社会信用代码
      -- 原始名称逻辑，命名结果保存为 computed_name（后续再决定是否追加“（待撤销）”）
      CASE 
        WHEN T1.ORG_NUM = '990000' THEN T1.ORG_NAM
        WHEN T1.ORG_NUM = '000000' THEN concat('吉林银行股份有限公司','(总行)')
        WHEN T1.ORG_NUM LIKE '%0000' THEN concat(T1.ORG_NAM,'(分行管理机构)')
        WHEN T1.ORG_NUM LIKE '%00' THEN 
          CASE 
            WHEN (T1.LEADER_NAME IS NULL OR T1.fzr_id IS NULL) 
                 AND (T1.BANK_TYPE2 IN ('A','B','C','D') OR T1.BANK_TYPE2 IS NULL) 
              THEN T1.ORG_NAM
            WHEN T1.BANK_TYPE2 IN ('B','C','D') THEN T1.ORG_NAM
            ELSE concat(T1.ORG_NAM,'(管理机构)')
          END
        ELSE T1.ORG_NAM
      END AS computed_name,
      COALESCE(T1.BANK_CD, T2.BANK_CD, T4.BANK_CD, T5.BANK_CD, T6.BANK_CD) AS A010006, -- 支付行号
      '05' AS A010007, -- 机构类型
      CASE 
        WHEN T1.BANK_TYPE2 = 'A' THEN '0101'
        WHEN T1.BANK_TYPE2 = 'B' THEN '0201'
        WHEN T1.BANK_TYPE2 = 'C' THEN '0301'
        WHEN T1.BANK_TYPE2 = 'D' THEN '0401'
        WHEN T1.BANK_TYPE2 = 'E' THEN '0501'
      END AS A010008, -- 机构类别
      T1.XYJGBS AS A010009, -- 县域机构标识
      '0' AS A010010, -- 科技支行标识
      CASE WHEN T1.ORG_NUM = '013500' THEN '1' ELSE '0' END AS A010011, -- 科技特色支行标识
      '0' AS A010012, -- 科技金融专营机构标识
      T1.REGION_CD AS A010013, -- 行政区划
      CASE 
        WHEN T1.BUSI_STATE = '01' THEN '01'
        WHEN T1.BUSI_STATE = '02' THEN '02'
        ELSE '00'
      END AS A010014, -- 运营状态
      date_format(established_date,'yyyy-MM-dd') AS A010015, -- 成立日期（字符串格式）
      T1.ORG_ADD AS A010016, -- 机构地址
      T1.LEADER_NAME AS A010017, -- 负责人姓名
      T1.fzr_id AS A010018, -- 负责人工号
      T1.LEADER_TEL AS A010019, -- 负责人联系电话
      date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd') AS A010020, -- 采集日期
      date_format(to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))),'yyyy-MM-dd') AS DIS_DATA_DATE,
      '990000' AS DIS_BANK_ID,
      '' AS DIS_DEPT,
      CASE 
        WHEN T1.BANK_TYPE2 = 'C' THEN '0098RL'
        ELSE '009822'
      END AS DEPARTMENT_ID,
      '0' AS A010021,
      T1.ORG_NUM AS A010022,
      CASE 
        WHEN T1.BANK_TYPE2 IN ('C','D') THEN '99'
        WHEN T1.ORG_TYP IN ('0','6') THEN '01'
        WHEN T1.ORG_TYP = '2' THEN '02'
        WHEN T1.ORG_TYP = '3' THEN '04'
        WHEN T1.ORG_TYP = '4' THEN '06'
      END AS A010023,
      -- 为排序比较将成立日期转换为日期类型（用于窗口函数判断哪条记录的成立日期最早）
      to_date(from_unixtime(unix_timestamp(coalesce(T1.BEGAN_TIME, T2.BEGAN_TIME, T4.BEGAN_TIME, T5.BEGAN_TIME, T6.BEGAN_TIME),'yyyyMMdd'))) AS established_date
    FROM SMTMODS.L_PUBL_ORG_BRA T1
      LEFT JOIN SMTMODS.L_PUBL_ORG_BRA T2
        ON T1.UP_ORG_NUM = T2.ORG_NUM
       AND T2.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_PUBL_ORG_BRA T4
        ON T4.DATA_DATE = T1.DATA_DATE
       AND T2.UP_ORG_NUM = T4.ORG_NUM
      LEFT JOIN SMTMODS.L_PUBL_ORG_BRA T5
        ON T5.DATA_DATE = T1.DATA_DATE
       AND T4.UP_ORG_NUM = T5.ORG_NUM
      LEFT JOIN SMTMODS.L_PUBL_ORG_BRA T6
        ON T6.DATA_DATE = T1.DATA_DATE
       AND T5.UP_ORG_NUM = T6.ORG_NUM
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
      AND (T1.ORG_STATUS <> 'U'
           OR EXISTS (
             SELECT 1
             FROM SMTMODS.L_PUBL_ORG_BRA T7
             WHERE T1.ORG_NUM = T7.ORG_NUM
               AND T7.ORG_STATUS <> 'U'
               AND T7.DATA_DATE = concat(cast(year(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd'))) - 1 AS STRING),'1231')
           )
      )
  ) inner_q
) final;
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

