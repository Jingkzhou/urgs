CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g03(II_DATADATE  IN string --跑批日期
                                                 )
/******************************
  @author:fanxiaoyu
  @create-date:2015-09-19
  @description:G03
  @modification history:
  m0.20150919-fanxiaoyu-G03
  m1.20230223 shiyu G03口径调整：1512科目由2.A调整到2.C ;   1502科目由2.C 调整到2.A;
  m2.20230223 shiyu G03口径调整:1项期末余额改为从指标出
  m3.20241224 shiyu G03口径调整:2b年初数据新增科目：40030221
  
目标表：CBRC_A_REPT_ITEM_VAL
视图表：SMTMODS_V_PUB_IDX_FINA_GL
集市表：SMTMODS_L_PUBL_RATE
  
  *******************************/
 IS
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE    VARCHAR(30); --当前储存过程名称
  V_REP_NUM      VARCHAR(30); --报表名称
  I_DATADATE     string; --数据日期(数值型)YYYYMMDD
  V_DATADATE     VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  D_DATADATE_CCY string; --数据日期(日期型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_ERRORDESC    VARCHAR(280); --错误内容
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM       VARCHAR2(30);
BEGIN
       IF II_STATUS = 0 THEN
  V_STEP_ID   := 0;
    V_STEP_DESC := '参数初始化处理';
    I_DATADATE     := II_DATADATE;
    V_DATADATE     := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYY-MM-DD');
    D_DATADATE_CCY := I_DATADATE;
    V_SYSTEM       := 'CBRC';
    V_PROCEDURE    := UPPER('PROC_CBRC_IDX2_G03');
    V_REP_NUM      := 'G03';

    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    V_STEP_ID   := 1;
    V_STEP_DESC := '清理 [' || V_REP_NUM || ']表历史数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND REP_NUM = V_REP_NUM
       AND FLAG IN ('1', '2');
    COMMIT;
  
    V_STEP_ID   := 2;
    V_STEP_DESC := '1.资产损失准备';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G03_1..A' AS ITEM_NUM,
             SUM(T.CREDIT_BAL * U.CCY_RATE) ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
      
      --ALTER BY WJB 20230302 该指标取上年末的期末余额
       WHERE T.ITEM_CD IN ('130401',
                           '130402',
                           '130403',
                           '130404',
                           '130405',
                           '130406',
                           '40030215',
                           '40030216',
                           '40030217')
            --ALTER BY WJB 20221216
         AND T.DATA_DATE = substr(I_DATADATE, 1, 4) - 1 || '1231'
       GROUP BY ORG_NUM;
    COMMIT;
  
    --ALTER BY WJB 20221110 根据松原李姐提供的新核心科目映射关系，修改取数逻辑
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (data_date,
       org_num,
       sys_nam,
       rep_num,
       item_num,
       item_val,
       item_val_v,
       flag,
       b_curr_cd,
       is_total)
      SELECT I_DATADATE, --时间
             T.ORG_NUM, --机构号
             'CBRC', --模块简称
             'G03', --科目编号
             'G03_1..B', --指标名称
             SUM(T.DEBIT_BAL * U.CCY_RATE), --金额
             '',
             '1' AS FLAG, --标志位
             'CNY' --币种
            ,
             ''
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
         AND U.DATA_DATE = I_DATADATE
       WHERE T.ITEM_CD IN ('67020101',
                           '67020102',
                           '67020103',
                           '67020105',
                           '67020104',
                           '67020106') --'670201' modify by djh
         AND T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM;
    COMMIT;
  
    --注释2：
  
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G03' AS REP_NUM, --报表编号
             'G03_1..G' AS ITEM_NUM, --指标号
             SUM(T1.CREDIT_BAL * T2.CCY_RATE) AS ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL T1
        LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T1.CURR_CD = T2.BASIC_CCY
         AND T2.FORWARD_CCY = 'CNY'
         AND T1.DATA_DATE = T2.DATA_DATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD IN ('130401',
                            '130402',
                            '130403',
                            '130404',
                            '130405',
                            '130406',
                            '40030215',
                            '40030216',
                            '40030217')
       GROUP BY ORG_NUM;
    COMMIT;
  
    V_STEP_ID   := 3;
    
    V_STEP_DESC := 'G03_2.1.A 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    insert into CBRC_A_REPT_ITEM_VAL
      (data_date,
       org_num,
       sys_nam,
       rep_num,
       item_num,
       item_val,
       item_val_v,
       flag,
       b_curr_cd,
       is_total
       
       )
      SELECT I_DATADATE, --时间
             T.ORG_NUM, --机构号
             'CBRC', --模块简称
             'G03', --科目编号
             'G03_2.1.A', --指标名称
             SUM(T.DEBIT_BAL * U.CCY_RATE), --金额
             '',
             '1' AS FLAG, --标志位
             'CNY' --币种
            ,
             ''
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE --T.ITEM_CD='14509' OR T.ITEM_CD='14510'
       (T.ITEM_CD = '14509' OR T.ITEM_CD = '14510') --CHANGED BY LIRUITING    --被删除科目
       AND T.DATA_DATE = substr(I_DATADATE, 1, 4) - 1 || '1231'
       GROUP BY T.ORG_NUM;
    COMMIT;
  
    V_STEP_ID   := 4;
    
    V_STEP_DESC := 'G03_2.2.A 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    insert into CBRC_A_REPT_ITEM_VAL
      (data_date,
       org_num,
       sys_nam,
       rep_num,
       item_num,
       item_val,
       item_val_v,
       flag,
       b_curr_cd,
       is_total
       
       )
      SELECT I_DATADATE, --时间
             T.ORG_NUM, --机构号
             'CBRC', --模块简称
             'G03', --科目编号
             'G03_2.2.A', --指标名称
             SUM(T.CREDIT_BAL * U.CCY_RATE), --金额
             '',
             '1' as FLAG, --标志位
             'CNY' --币种
            ,
             ''
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE --T.ITEM_CD='14307' OR T.ITEM_CD='14308'
       (T.ITEM_CD = '150201' OR T.ITEM_CD = '150202') --CHANGED BY LIRUITING
       AND T.DATA_DATE = substr(I_DATADATE, 1, 4) - 1 || '1231'
       GROUP BY T.ORG_NUM;
    COMMIT;
  
    V_STEP_ID   := 5;
    
    V_STEP_DESC := 'G03_2.3.A 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    insert into CBRC_A_REPT_ITEM_VAL
      (data_date,
       org_num,
       sys_nam,
       rep_num,
       item_num,
       item_val,
       item_val_v,
       flag,
       b_curr_cd,
       is_total)
      SELECT I_DATADATE, --时间
             T.ORG_NUM, --机构号
             'CBRC', --模块简称
             'G03', --科目编号
             'G03_2.3.A', --指标名称
             SUM(T.CREDIT_BAL * U.CCY_RATE), --金额
             '',
             '1' as FLAG, --标志位
             'CNY' --币种
            ,
             ''
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.ITEM_CD IN ('15120101', '15120102')
         AND T.DATA_DATE = substr(I_DATADATE, 1, 4) - 1 || '1231'
       GROUP BY T.ORG_NUM;
    COMMIT;
  
    V_STEP_ID   := 6;
    
    V_STEP_DESC := 'G03_2.4.A 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    insert into CBRC_A_REPT_ITEM_VAL
      (data_date,
       org_num,
       sys_nam,
       rep_num,
       item_num,
       item_val,
       item_val_v,
       flag,
       b_curr_cd,
       is_total)
      SELECT I_DATADATE, --时间
             T.ORG_NUM, --机构号
             'CBRC', --模块简称
             'G03', --科目编号
             'G03_2.4.A', --指标名称
             SUM(T.CREDIT_BAL * U.CCY_RATE),
             '',
             '1' as FLAG, --标志位
             'CNY' --币种
            ,
             ''
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.ITEM_CD = '1231'
         AND T.DATA_DATE = substr(I_DATADATE, 1, 4) - 1 || '1231'
       GROUP BY T.ORG_NUM;
    COMMIT;
  
    V_STEP_ID   := 7;
    
    V_STEP_DESC := 'G03_2.5.A 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    insert into CBRC_A_REPT_ITEM_VAL
      (data_date,
       org_num,
       sys_nam,
       rep_num,
       item_num,
       item_val,
       item_val_v,
       flag,
       b_curr_cd,
       is_total)
      SELECT I_DATADATE, --时间
             T.ORG_NUM, --机构号
             'CBRC', --模块简称
             'G03', --科目编号
             'G03_2.5.A', --指标名称
             SUM(T.CREDIT_BAL * U.CCY_RATE), --金额
             '',
             '1' as FLAG, --标志位
             'CNY' --币种
            ,
             ''
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.ITEM_CD = '1442'
         AND T.DATA_DATE = substr(I_DATADATE, 1, 4) - 1 || '1231'
       GROUP BY T.ORG_NUM;
    COMMIT;
  
    V_STEP_ID   := 8;
    
    V_STEP_DESC := 'G03_2.6.A 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    insert into CBRC_A_REPT_ITEM_VAL
      (data_date,
       org_num,
       sys_nam,
       rep_num,
       item_num,
       item_val,
       item_val_v,
       flag,
       b_curr_cd,
       is_total)
      SELECT I_DATADATE, --时间
             T.ORG_NUM, --机构号
             'CBRC', --模块简称
             'G03', --科目编号
             'G03_2.6.A', --指标名称
             SUM(T.CREDIT_BAL * U.CCY_RATE), --金额
             '',
             '1' as FLAG, --标志位
             'CNY' --币种
            ,
             ''
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE --T.ITEM_CD='15106' OR T.ITEM_CD='15403'
       (T.ITEM_CD = '160301' OR T.ITEM_CD = '160501') --CHANGD BY LIRUITING
       AND T.DATA_DATE = substr(I_DATADATE, 1, 4) - 1 || '1231'
       GROUP BY T.ORG_NUM;
    COMMIT;
  
    V_STEP_ID   := 9;
    
    V_STEP_DESC := 'G03_2.7.A 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    insert into CBRC_A_REPT_ITEM_VAL
      (data_date,
       org_num,
       sys_nam,
       rep_num,
       item_num,
       item_val,
       item_val_v,
       flag,
       b_curr_cd,
       is_total)
      SELECT I_DATADATE, --时间
             T.ORG_NUM, --机构号
             'CBRC', --模块简称
             'G03', --科目编号
             'G03_2.7.A', --指标名称
             SUM(T.CREDIT_BAL * U.CCY_RATE), --金额
             '',
             '1' as FLAG, --标志位
             'CNY' --币种
            ,
             ''
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.ITEM_CD = '1523'
         AND T.DATA_DATE = substr(I_DATADATE, 1, 4) - 1 || '1231'
       GROUP BY T.ORG_NUM;
    COMMIT;
  
    V_STEP_ID   := 10;
    
    V_STEP_DESC := 'G03_2.8.A 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    insert into CBRC_A_REPT_ITEM_VAL
      (data_date,
       org_num,
       sys_nam,
       rep_num,
       item_num,
       item_val,
       item_val_v,
       flag,
       b_curr_cd,
       is_total)
      SELECT I_DATADATE, --时间
             T.ORG_NUM, --机构号
             'CBRC', --模块简称
             'G03', --科目编号
             'G03_2.8.A', --指标名称
             SUM(T.CREDIT_BAL * U.CCY_RATE), --金额
             '',
             '1' as FLAG, --标志位
             'CNY' --币种
            ,
             ''
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.ITEM_CD = '170301'
         AND T.DATA_DATE = substr(I_DATADATE, 1, 4) - 1 || '1231'
       GROUP BY T.ORG_NUM;
  
    V_STEP_ID   := 11;
    
    V_STEP_DESC := 'G03_2.9.A 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    insert into CBRC_A_REPT_ITEM_VAL
      (data_date,
       org_num,
       sys_nam,
       rep_num,
       item_num,
       item_val,
       item_val_v,
       flag,
       b_curr_cd,
       is_total)
      SELECT I_DATADATE, --时间
             T.ORG_NUM, --机构号
             'CBRC', --模块简称
             'G03', --科目编号
             'G03_2.9.A', --指标名称
             SUM(T.CREDIT_BAL * U.CCY_RATE), --金额
             '',
             '1' as FLAG, --标志位
             'CNY' --币种
            ,
             ''
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.ITEM_CD = '171201'
         AND T.DATA_DATE = substr(I_DATADATE, 1, 4) - 1 || '1231'
       GROUP BY T.ORG_NUM;
    COMMIT;
  
    V_STEP_ID   := 12;
    
    V_STEP_DESC := 'G03_2.10.A 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    insert into CBRC_A_REPT_ITEM_VAL
      (data_date,
       org_num,
       sys_nam,
       rep_num,
       item_num,
       item_val,
       item_val_v,
       flag,
       b_curr_cd,
       is_total)
      SELECT I_DATADATE, --时间
             T.ORG_NUM, --机构号
             'CBRC', --模块简称
             'G03', --科目编号
             'G03_2.10.A', --指标名称
             SUM(T.CREDIT_BAL * U.CCY_RATE), --金额
             '',
             '1' as FLAG, --标志位
             'CNY' --币种
            ,
             ''
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE --T.ITEM_CD='121' OR T.ITEM_CD='14004'    OR T.ITEM_CD='14407' OR T.ITEM_CD='14408'
       (T.ITEM_CD = '1307' OR T.ITEM_CD = '1112' OR T.ITEM_CD = '14407' OR
       T.ITEM_CD = '14408') --CHANGED BY LIRUITING
       AND T.DATA_DATE = substr(I_DATADATE, 1, 4) - 1 || '1231'
       GROUP BY T.ORG_NUM;
    COMMIT;
  
    V_STEP_ID   := 13;
    
    V_STEP_DESC := 'G03_2.1.B 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    insert into CBRC_A_REPT_ITEM_VAL
      (data_date,
       org_num,
       sys_nam,
       rep_num,
       item_num,
       item_val,
       item_val_v,
       flag,
       b_curr_cd,
       is_total)
      SELECT I_DATADATE, --时间
             T.ORG_NUM, --机构号
             'CBRC', --模块简称
             'G03', --科目编号
             'G03_2.1.B', --指标名称
             SUM(T.DEBIT_BAL * U.CCY_RATE), --金额
             '',
             '1' as FLAG, --标志位
             'CNY' --币种
            ,
             ''
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.ITEM_CD IN ('670207', '53105', '670299')
         AND T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM;
    COMMIT;
  
    V_STEP_ID   := 14;
    
    V_STEP_DESC := 'G03_2.2.B 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    insert into CBRC_A_REPT_ITEM_VAL
      (data_date,
       org_num,
       sys_nam,
       rep_num,
       item_num,
       item_val,
       item_val_v,
       flag,
       b_curr_cd,
       is_total)
      SELECT I_DATADATE, --时间
             T.ORG_NUM, --机构号
             'CBRC', --模块简称
             'G03', --科目编号
             'G03_2.2.B', --指标名称
             SUM(T.DEBIT_BAL * U.CCY_RATE), --金额
             '',
             '1' as FLAG, --标志位
             'CNY' --币种
            ,
             ''
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.ITEM_CD = '670206'
         AND T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM;
    COMMIT;
  
    V_STEP_ID   := 15;
    
    V_STEP_DESC := 'G03_2.3.B 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    insert into CBRC_A_REPT_ITEM_VAL
      (data_date,
       org_num,
       sys_nam,
       rep_num,
       item_num,
       item_val,
       item_val_v,
       flag,
       b_curr_cd,
       is_total)
      SELECT I_DATADATE, --时间
             T.ORG_NUM, --机构号
             'CBRC', --模块简称
             'G03', --科目编号
             'G03_2.3.B', --指标名称
             SUM(T.DEBIT_BAL * U.CCY_RATE), --金额
             '',
             '1' as FLAG, --标志位
             'CNY' --币种
            ,
             ''
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.ITEM_CD = '670101'
         AND T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM;
    COMMIT;
  
    V_STEP_ID   := 16;
    
    V_STEP_DESC := 'G03_2.4.B 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    insert into CBRC_A_REPT_ITEM_VAL
      (data_date,
       org_num,
       sys_nam,
       rep_num,
       item_num,
       item_val,
       item_val_v,
       flag,
       b_curr_cd,
       is_total)
      SELECT I_DATADATE, --时间
             T.ORG_NUM, --机构号
             'CBRC', --模块简称
             'G03', --科目编号
             'G03_2.4.B', --指标名称
             SUM(T.DEBIT_BAL * U.CCY_RATE), --金额
             '',
             '1' as FLAG, --标志位
             'CNY' --币种
            ,
             ''
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.ITEM_CD = '670202'
         AND T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM;
    COMMIT;
  
    V_STEP_ID   := 17;
    
    V_STEP_DESC := 'G03_2.5.B 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    insert into CBRC_A_REPT_ITEM_VAL
      (data_date,
       org_num,
       sys_nam,
       rep_num,
       item_num,
       item_val,
       item_val_v,
       flag,
       b_curr_cd,
       is_total)
      SELECT I_DATADATE, --时间
             T.ORG_NUM, --机构号
             'CBRC', --模块简称
             'G03', --科目编号
             'G03_2.5.B', --指标名称
             SUM(T.DEBIT_BAL * U.CCY_RATE), --金额
             '',
             '1' as FLAG, --标志位
             'CNY' --币种
            ,
             ''
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.ITEM_CD = '670105'
         AND T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM;
    COMMIT;
  
    V_STEP_ID   := 18;
    
    V_STEP_DESC := 'G03_2.6.B 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    insert into CBRC_A_REPT_ITEM_VAL
      (data_date,
       org_num,
       sys_nam,
       rep_num,
       item_num,
       item_val,
       item_val_v,
       flag,
       b_curr_cd,
       is_total)
      SELECT I_DATADATE, --时间
             T.ORG_NUM, --机构号
             'CBRC', --模块简称
             'G03', --科目编号
             'G03_2.6.B', --指标名称
             SUM(T.DEBIT_BAL * U.CCY_RATE), --金额
             '',
             '1' as FLAG, --标志位
             'CNY' --币种
            ,
             ''
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE (T.ITEM_CD = '670102' OR T.ITEM_CD = '670103')
         AND T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM;
    COMMIT;
  
    V_STEP_ID   := 19;
    
    V_STEP_DESC := 'G03_2.7.B 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    insert into CBRC_A_REPT_ITEM_VAL
      (data_date,
       org_num,
       sys_nam,
       rep_num,
       item_num,
       item_val,
       item_val_v,
       flag,
       b_curr_cd,
       is_total)
      SELECT I_DATADATE, --时间
             T.ORG_NUM, --机构号
             'CBRC', --模块简称
             'G03', --科目编号
             'G03_2.7.B', --指标名称
             SUM(T.DEBIT_BAL * U.CCY_RATE), --金额
             '',
             '1' as FLAG, --标志位
             'CNY' --币种
            ,
             ''
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.ITEM_CD = '670106'
         AND T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM;
    COMMIT;
  
    V_STEP_ID   := 20;
    
    V_STEP_DESC := 'G03_2.8.B 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    insert into CBRC_A_REPT_ITEM_VAL
      (data_date,
       org_num,
       sys_nam,
       rep_num,
       item_num,
       item_val,
       item_val_v,
       flag,
       b_curr_cd,
       is_total)
      SELECT I_DATADATE, --时间
             T.ORG_NUM, --机构号
             'CBRC', --模块简称
             'G03', --科目编号
             'G03_2.8.B', --指标名称
             SUM(T.DEBIT_BAL * U.CCY_RATE), --金额
             '',
             '1' as FLAG, --标志位
             'CNY' --币种
            ,
             ''
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.ITEM_CD = '670104'
         AND T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM;
    COMMIT;
  
    V_STEP_ID   := 21;
    
    V_STEP_DESC := 'G03_2.9.B 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    insert into CBRC_A_REPT_ITEM_VAL
      (data_date,
       org_num,
       sys_nam,
       rep_num,
       item_num,
       item_val,
       item_val_v,
       flag,
       b_curr_cd,
       is_total)
      SELECT I_DATADATE, --时间
             T.ORG_NUM, --机构号
             'CBRC', --模块简称
             'G03', --科目编号
             'G03_2.9.B', --指标名称
             SUM(T.DEBIT_BAL * U.CCY_RATE), --金额
             '',
             '1' as FLAG, --标志位
             'CNY' --币种
            ,
             ''
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.ITEM_CD = '670107'
         AND T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM;
    COMMIT;
  
    V_STEP_ID   := 22;
    
    V_STEP_DESC := 'G03_2.10.B 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    insert into CBRC_A_REPT_ITEM_VAL
      (data_date,
       org_num,
       sys_nam,
       rep_num,
       item_num,
       item_val,
       item_val_v,
       flag,
       b_curr_cd,
       is_total)
      SELECT I_DATADATE, --时间
             T.ORG_NUM, --机构号
             'CBRC', --模块简称
             'G03', --科目编号
             'G03_2.10.B', --指标名称
             SUM(T.DEBIT_BAL * U.CCY_RATE), --金额
             '',
             '1' as FLAG, --标志位
             'CNY' --币种
            ,
             ''
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE
       T.ITEM_CD IN ('53106', '670205', '670204', '670103', '670299')
       AND T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM;
    COMMIT;
  
    V_STEP_ID   := 23;
    
    V_STEP_DESC := '2.a以摊余成本计量金融资产的减值准备';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G03' AS REP_NUM, --报表编号
       'G03_13..A' AS ITEM_NUM, --指标号
       SUM(NVL(M.CREDIT_BAL, 0)) AS AMT,
       '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL M
       WHERE M.DATA_DATE = substr(I_DATADATE, 1, 4) - 1 || '1231'
         AND M.ITEM_CD IN ('130701', --ALTER BY WJB 20221216 对应老科目 121
                           '130407', --ALTER BY WJB 20221216 对应老科目 13401
                           '10130101', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130102', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130103', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130104', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130105', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130106', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130107', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130108', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130109', --ALTER BY WJB 20221216 对应老科目 13403
                           '12319901', --ALTER BY WJB 20221216 对应老科目 13403
                           '130408', --ALTER BY WJB 20221216 对应老科目 13404
                           '10130201', --ALTER BY WJB 20221216 对应老科目 13405
                           '10130202', --ALTER BY WJB 20221216 对应老科目 13406
                           '13070301', --ALTER BY WJB 20221216 对应老科目 13407
                           '13070302', --ALTER BY WJB 20221216 对应老科目 13408
                           '11120101', --ALTER BY WJB 20221216 对应老科目 14004
                           '11120301', --ALTER BY WJB 20221216 对应老科目 14004
                           '11120201', --ALTER BY WJB 20221216 对应老科目 14004
                           '11120102', --ALTER BY WJB 20221216 对应老科目 14004
                           '11129901', --ALTER BY WJB 20221216 对应老科目 14004
                           '11120103', --ALTER BY WJB 20221216 对应老科目 14005
                           '11120302', --ALTER BY WJB 20221216 对应老科目 14005
                           '11120202', --ALTER BY WJB 20221216 对应老科目 14005
                           '11120104', --ALTER BY WJB 20221216 对应老科目 14005
                           '11129902', --ALTER BY WJB 20221216 对应老科目 14005
                           '150201', --ALTER BY WJB 20221216 对应老科目 14307
                           '150202', --ALTER BY WJB 20221216 对应老科目 14308
                           '150203', --ALTER BY WJB 20221216 对应老科目 14309
                           '150204') --ALTER BY WJB 20221216 对应老科目 14310
         AND M.CURR_CD IN ('CNY', 'ZCNY')
         AND ORG_NUM <> '009820' ---add by  zy   20240819
       GROUP BY ORG_NUM;
    COMMIT;
  
    ------------add  by   zy   start  同业金融部反馈新增科目 新增的科目其他机构也有数据，因此先拆出----
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G03' AS REP_NUM, --报表编号
       'G03_13..A' AS ITEM_NUM, --指标号
       SUM(NVL(M.CREDIT_BAL, 0)) AS AMT,
       '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL M
       WHERE M.DATA_DATE = substr(I_DATADATE, 1, 4) - 1 || '1231'
         AND M.ITEM_CD IN ('130701', --ALTER BY WJB 20221216 对应老科目 121
                           '130407', --ALTER BY WJB 20221216 对应老科目 13401
                           '10130101', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130102', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130103', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130104', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130105', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130106', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130107', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130108', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130109', --ALTER BY WJB 20221216 对应老科目 13403
                           '12319901', --ALTER BY WJB 20221216 对应老科目 13403
                           '130408', --ALTER BY WJB 20221216 对应老科目 13404
                           '10130201', --ALTER BY WJB 20221216 对应老科目 13405
                           '10130202', --ALTER BY WJB 20221216 对应老科目 13406
                           '13070301', --ALTER BY WJB 20221216 对应老科目 13407
                           '13070302', --ALTER BY WJB 20221216 对应老科目 13408
                           '11120101', --ALTER BY WJB 20221216 对应老科目 14004
                           '11120301', --ALTER BY WJB 20221216 对应老科目 14004
                           '11120201', --ALTER BY WJB 20221216 对应老科目 14004
                           '11120102', --ALTER BY WJB 20221216 对应老科目 14004
                           '11129901', --ALTER BY WJB 20221216 对应老科目 14004
                           '11120103', --ALTER BY WJB 20221216 对应老科目 14005
                           '11120302', --ALTER BY WJB 20221216 对应老科目 14005
                           '11120202', --ALTER BY WJB 20221216 对应老科目 14005
                           '11120104', --ALTER BY WJB 20221216 对应老科目 14005
                           '11129902', --ALTER BY WJB 20221216 对应老科目 14005
                           '150201', --ALTER BY WJB 20221216 对应老科目 14307
                           '150202', --ALTER BY WJB 20221216 对应老科目 14308
                           '150203', --ALTER BY WJB 20221216 对应老科目 14309
                           '150204', --ALTER BY WJB 20221216 对应老科目 14310
                           '10130110', --ALTER BY ZY  20240819 同业金融部反馈新增科目
                           '10130111', --ALTER BY ZY  20240819 同业金融部反馈新增科目
                           '10130401', --ALTER BY ZY  20240819 同业金融部反馈新增科目
                           '10130402', --ALTER BY ZY  20240819 同业金融部反馈新增科目
                           '10130301' --ALTER BY ZY  20240819 同业金融部反馈新增科目
                           )
         AND M.CURR_CD IN ('CNY', 'ZCNY')
         AND ORG_NUM = '009820' ---add by  zy   20240819
       GROUP BY ORG_NUM;
    COMMIT;
  
    --------------add  by  zy  end
  
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
    
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G03' AS REP_NUM, --报表编号
             'G03_13..B' AS ITEM_NUM, --指标号
             SUM(CASE
                   WHEN ITEM_CD = '67020210' THEN
                    -T1.DEBIT_BAL * T2.CCY_RATE
                   ELSE
                    T1.DEBIT_BAL * T2.CCY_RATE
                 END) ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL T1
        LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T1.CURR_CD = T2.BASIC_CCY
         AND T2.FORWARD_CCY = 'CNY'
         AND T1.DATA_DATE = T2.DATA_DATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD IN ('67020210',
                            '670206',
                            '670205',
                            '67020401',
                            '67020402',
                            '67020403',
                            '67020404',
                            '67020407',
                            '67020405',
                            '67020406',
                            '670299',
                            --ALTER BY WJB 20221216 以下是原53102老科目 以上科目对应的钱与老科目一致
                            '67020107',
                            '67020108',
                            '67020109',
                            '67020110',
                            '67020111',
                            '67020112',
                            '67020113',
                            '67020114',
                            '67020115',
                            '670202',
                            '670203',
                            '67020408',
                            '67020409')
       GROUP BY ORG_NUM;
    COMMIT;
  
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G03' AS REP_NUM, --报表编号
             'G03_13..G' AS ITEM_NUM, --指标号
             SUM(T1.CREDIT_BAL * T2.CCY_RATE) ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL T1
        LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T1.CURR_CD = T2.BASIC_CCY
         AND T2.FORWARD_CCY = 'CNY'
         AND T1.DATA_DATE = T2.DATA_DATE
       WHERE T1.DATA_DATE = I_DATADATE
            --ALTER BY WJB 20221119 根据新老科目映射 对比过总账表新老科目余额后更新
            --注释M1:按照业务提供新口径---1013;1112;130407;130408;1307;1502
         AND T1.ITEM_CD IN
             ('130407', '1013', '130408', '1307', '1112', '1502')
      
       GROUP BY ORG_NUM;
    COMMIT;
  
    V_STEP_ID   := 24;
    
    V_STEP_DESC := '2.b以公允价值计量且其变动计入其他综合收益金融资产的减值准备';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G03' AS REP_NUM, --报表编号
       'G03_14..A' AS ITEM_NUM, --指标号
       SUM(NVL(M.CREDIT_BAL, 0)) AS AMT,
       '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL M
       WHERE M.DATA_DATE = substr(I_DATADATE, 1, 4) - 1 || '1231'
         AND M.ITEM_CD IN
             ('40030208', '40030209', '40030210', '40030211', '40030221') --alter by  20241224 m3
         AND M.CURR_CD IN ('CNY', 'ZCNY')
       GROUP BY ORG_NUM;
    COMMIT;
  
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G03' AS REP_NUM, --报表编号
       'G03_14..B' AS ITEM_NUM, --指标号
       sum(T1.DEBIT_BAL * T2.CCY_RATE) ITEM_VAL,
       '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL T1
        LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T1.CURR_CD = T2.BASIC_CCY
         AND T2.FORWARD_CCY = 'CNY'
         AND T1.DATA_DATE = T2.DATA_DATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD IN ('670207')
       GROUP BY ORG_NUM;
    COMMIT;
  
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G03' AS REP_NUM, --报表编号
             'G03_14..G' AS ITEM_NUM, --指标号
             SUM(T1.CREDIT_BAL * T2.CCY_RATE) ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL T1
        LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T1.CURR_CD = T2.BASIC_CCY
         AND T2.FORWARD_CCY = 'CNY'
         AND T1.DATA_DATE = T2.DATA_DATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD IN
             ('40030208', '40030209', '40030210', '40030211', '40030221')
       GROUP BY ORG_NUM;
    COMMIT;
  
    V_STEP_ID   := 25;
    
    V_STEP_DESC := '2.c其他减值准备';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G03' AS REP_NUM, --报表编号
       'G03_15..A' AS ITEM_NUM, --指标号
       SUM(NVL(M.CREDIT_BAL, 0)) AS AMT,
       '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL M
       WHERE M.DATA_DATE = substr(I_DATADATE, 1, 4) - 1 || '1231'
         AND M.ITEM_CD IN ('123101', --ALTER BY WJB 20221216 对应老科目 13402
                           '1512', --ALTER BY WJB 20221216 对应老科目 147
                           '1442', --ALTER BY WJB 20221216 对应老科目 150
                           '160301', --ALTER BY WJB 20221216 对应老科目 15306
                           '160501', --ALTER BY WJB 20221216 对应老科目 15403
                           '160801', --ALTER BY WJB 20221216 对应老科目 15502
                           '161101', --ALTER BY WJB 20221216 对应老科目 15603
                           '170301', --ALTER BY WJB 20221216 对应老科目 16103
                           '171201', --ALTER BY WJB 20221216 对应老科目 16402
                           '1523', --ALTER BY WJB 20221216 对应老科目 17204
                           '2801') --ALTER BY WJB 20221216 对应老科目 280
         AND M.CURR_CD IN ('CNY', 'ZCNY')
       GROUP BY ORG_NUM;
    COMMIT;
  
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G03' AS REP_NUM, --报表编号
             'G03_15..B' AS ITEM_NUM, --指标号
             sum(T1.DEBIT_BAL * T2.CCY_RATE) ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL T1
        LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T1.CURR_CD = T2.BASIC_CCY
         AND T2.FORWARD_CCY = 'CNY'
         AND T1.DATA_DATE = T2.DATA_DATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD IN ('67020210', '6701', '670208', '670299') --modify by djh
     
       GROUP BY ORG_NUM;
    COMMIT;
  
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G03' AS REP_NUM, --报表编号
             'G03_15..G' AS ITEM_NUM, --指标号
             SUM(T1.CREDIT_BAL * T2.CCY_RATE) ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL T1
        LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T1.CURR_CD = T2.BASIC_CCY
         AND T2.FORWARD_CCY = 'CNY'
         AND T1.DATA_DATE = T2.DATA_DATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD IN ('1231',
                            '1442',
                            '1603',
                            '1605',
                            '1608',
                            '1611',
                            '1703',
                            '1712',
                            '1523',
                            '1482',
                            --'1502',--注释m1
                            '1512',
                            '280102')
       GROUP BY ORG_NUM;
    COMMIT;
    
    V_STEP_FLAG := 1;
    V_STEP_DESC := V_PROCEDURE || '的业务逻辑全部处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   DBMS_OUTPUT.PUT_LINE('O_STATUS=0');
   DBMS_OUTPUT.PUT_LINE('O_STATUS_DEC=完成'); 
    ------------------------------------------------------------------

  END IF;

EXCEPTION
  WHEN OTHERS THEN
    V_ERRORCODE := SQLCODE;
    V_ERRORDESC := SUBSTR(SQLERRM, 1, 280);
    V_STEP_DESC := '发生异常。详细信息为，' || TO_CHAR(SQLCODE) ||
                   SUBSTR(SQLERRM, 1, 280);
				   
    DBMS_OUTPUT.PUT_LINE('O_STATUS=-1');
    DBMS_OUTPUT.PUT_LINE('O_STATUS_DEC=失败'); 
    --记录异常信息
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
     ROLLBACK;
   
END proc_cbrc_idx2_g03