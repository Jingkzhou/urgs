CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_gf01(II_DATADATE  IN string 
                                                  )
/******************************
  @author:
  @create-date:20231227
  @description:GF01
  @modification history:
    分支机构报表《GF01资产负债项目统计表》在归并法人G01报表后加入以下取数逻辑
目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_GF01_L_FINA_GL
     CBRC_GF01_ORG_FLAT
     CBRC_T_ORG_TEMP
依赖表：CBRC_UPRR_U_BASE_INST
集市表：SMTMODS_L_FINA_GL
     SMTMODS_L_PUBL_RATE

  *******************************/
 IS
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE    VARCHAR(30); --当前储存过程名称
  V_REP_NUM      VARCHAR(30); --报表名称
  I_DATADATE     VARCHAR(10); --数据日期(数值型)YYYYMMDD
  V_DATADATE     VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  D_DATADATE_CCY VARCHAR(10); --数据日期(日期型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_ERRORDESC    VARCHAR(280); --错误内容
  II_STATUS      iNTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM       VARCHAR2(30);
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    I_DATADATE     := II_DATADATE;
    V_DATADATE     := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYY-MM-DD');
    D_DATADATE_CCY := I_DATADATE;
    V_SYSTEM       := 'CBRC';
    V_PROCEDURE    := UPPER('PROC_CBRC_IDX2_GF01');
    V_REP_NUM      := 'GF01';

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_REP_NUM || ']表历史数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND REP_NUM = 'GF01'
       AND FLAG IN ('1', '2');
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '加工机构临时表，涉及市辖县辖等特殊汇总机构至CBRC_GF01_ORG_FLAT中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --加工总账临时表，涉及市辖县辖等特殊汇总机构，总账不提供该类机构数据，需自行加工
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_GF01_ORG_FLAT';

    --递归找到所有下级
    FOR DBANK IN (SELECT ORG_NUM FROM CBRC_T_ORG_TEMP) LOOP

      INSERT INTO CBRC_GF01_ORG_FLAT
        (ORG_CODE, SUB_ORG_CODE)
        select distinct INST_ID, PARENT_INST_ID
          from (SELECT distinct INST_ID, DBANK.ORG_NUM AS PARENT_INST_ID
                  FROM CBRC_UPRR_U_BASE_INST
                 WHERE INST_ID IS NOT NULL
                 START WITH PARENT_INST_ID = DBANK.ORG_NUM
                CONNECT BY PRIOR INST_ID = PARENT_INST_ID);

      COMMIT;
    END LOOP;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '加工市瞎特殊机构指标总账信息至CBRC_GF01_L_FINA_GL中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ---加工市瞎特殊机构指标总账信息

    ---CBRC_DATACORE.CBRC_GF01_L_FINA_GL
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_GF01_L_FINA_GL';

    --将现有机构总账表插入到临时表
    insert into CBRC_GF01_L_FINA_GL
      SELECT DATA_DATE,
             ACCTOUNT_DT,
             ORG_NUM,
             ITEM_CD,
             PRODUCT_CD,
             CURR_CD,
             ORIG_CURR_CD,
             CREDIT_D_AMT,
             CREDIT_M_AMT,
             CREDIT_Q_AMT,
             CREDIT_H_Y_AMT,
             CREDIT_Y_AMT,
             CREDIT_BAL,
             DEBIT_D_AMT,
             DEBIT_M_AMT,
             DEBIT_Q_AMT,
             DEBIT_H_Y_AMT,
             DEBIT_Y_AMT,
             DEBIT_BAL,
             DISCOUNTED_FLG,
             SUM_LEVEL_FLG,
             DEPARTMENTD,
             DATE_SOURCESD,
             CREDIT_BAL_PRE,
             DEBIT_BAL_PER
        FROM SMTMODS_L_FINA_GL G
       WHERE G.data_date = I_DATADATE;
    COMMIT;
    --加工市瞎特殊机构指标总账信息
    INSERT INTO CBRC_GF01_L_FINA_GL
      select DATA_DATE,
             ACCTOUNT_DT,
             t.sub_org_code ORG_NUM,
             ITEM_CD,
             PRODUCT_CD,
             CURR_CD,
             ORIG_CURR_CD,
             sum(CREDIT_D_AMT) CREDIT_D_AMT,
             sum(CREDIT_M_AMT) CREDIT_M_AMT,
             sum(CREDIT_Q_AMT) CREDIT_Q_AMT,
             sum(CREDIT_H_Y_AMT) CREDIT_H_Y_AMT,
             sum(CREDIT_Y_AMT) CREDIT_Y_AMT,
             sum(CREDIT_BAL) CREDIT_BAL,
             sum(DEBIT_D_AMT) DEBIT_D_AMT,
             sum(DEBIT_M_AMT) DEBIT_M_AMT,
             sum(DEBIT_Q_AMT) DEBIT_Q_AMT,
             sum(DEBIT_H_Y_AMT) DEBIT_H_Y_AMT,
             sum(DEBIT_Y_AMT) DEBIT_Y_AMT,
             sum(DEBIT_BAL) DEBIT_BAL,
             DISCOUNTED_FLG,
             'N' SUM_LEVEL_FLG,
             DEPARTMENTD,
             DATE_SOURCESD,
             sum(CREDIT_BAL_PRE) CREDIT_BAL_PRE,
             sum(DEBIT_BAL_PER) DEBIT_BAL_PER
        from SMTMODS_L_FINA_GL g
       inner join CBRC_GF01_ORG_FLAT t
          on g.org_num = t.org_code
         and (t.org_code like '%00' or substr(t.org_code, 3, 2) = '98')
       where g.data_date = I_DATADATE
       group by DATA_DATE,
                ACCTOUNT_DT,
                t.sub_org_code,
                ITEM_CD,
                PRODUCT_CD,
                CURR_CD,
                ORIG_CURR_CD,
                DISCOUNTED_FLG,
                DEPARTMENTD,
                DATE_SOURCESD;
    commit;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '加工GF01.70存放系统内款项指标至插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --70.存放系统内款项

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       IS_TOTAL --是否参与汇总：Y 参与汇总  N 不参与汇总
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'GF01' AS REP_NUM, --报表编号
             'GF0100_70..A' AS ITEM_NUM, --指标号
             SUM(CASE
                   WHEN T1.DEBIT_BAL - T1.CREDIT_BAL > 0 THEN
                    T1.DEBIT_BAL - T1.CREDIT_BAL
                   ELSE
                    0
                 END * T2.CCY_RATE) ITEM_VAL,
             '1' AS FLAG,
             'N' AS IS_TOTAL
        FROM CBRC_GF01_L_FINA_GL T1
        LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T1.CURR_CD = T2.BASIC_CCY
         AND T2.FORWARD_CCY = 'CNY'
         AND T1.DATA_DATE = T2.DATA_DATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD IN ('300106')
         AND T1.CURR_CD = 'CNY'
       GROUP BY ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       IS_TOTAL --是否参与汇总：Y 参与汇总  N 不参与汇总
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'GF01' AS REP_NUM, --报表编号
             'GF0100_70..B' AS ITEM_NUM, --指标号
             CASE
               WHEN A.DEBIT_BAL - A.CREDIT_BAL > 0 THEN
                A.DEBIT_BAL - A.CREDIT_BAL
               ELSE
                0
             END ITEM_VAL,
             '1' AS FLAG,
             'N' AS IS_TOTAL
        FROM (SELECT ORG_NUM,
                     SUM(T1.DEBIT_BAL * T2.CCY_RATE) DEBIT_BAL,
                     SUM(T1.CREDIT_BAL * T2.CCY_RATE) CREDIT_BAL
                FROM CBRC_GF01_L_FINA_GL T1
               INNER JOIN SMTMODS_L_PUBL_RATE T2
                  ON T1.CURR_CD = T2.BASIC_CCY
                 AND T2.FORWARD_CCY = 'CNY'
                 AND T1.DATA_DATE = T2.DATA_DATE
               WHERE T1.DATA_DATE = I_DATADATE
                 AND T1.ITEM_CD IN ('300106')
                 AND T1.CURR_CD <> 'CNY'
               GROUP BY ORG_NUM) A;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       IS_TOTAL --是否参与汇总：Y 参与汇总  N 不参与汇总
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'GF01' AS REP_NUM, --报表编号
             'GF0100_70..C' AS ITEM_NUM, --指标号
             CASE
               WHEN A.DEBIT_BAL - A.CREDIT_BAL > 0 THEN
                A.DEBIT_BAL - A.CREDIT_BAL
               ELSE
                0
             END ITEM_VAL,
             '1' AS FLAG,
             'N' AS IS_TOTAL
        FROM (SELECT ORG_NUM,
                     SUM(T1.DEBIT_BAL * T2.CCY_RATE) DEBIT_BAL,
                     SUM(T1.CREDIT_BAL * T2.CCY_RATE) CREDIT_BAL
                FROM CBRC_GF01_L_FINA_GL T1
               INNER JOIN SMTMODS_L_PUBL_RATE T2
                  ON T1.CURR_CD = T2.BASIC_CCY
                 AND T2.FORWARD_CCY = 'CNY'
                 AND T1.DATA_DATE = T2.DATA_DATE
               WHERE T1.DATA_DATE = I_DATADATE
                 AND T1.ITEM_CD IN ('300106')
              -- AND T1.CURR_CD <>'CNY'
               GROUP BY ORG_NUM) A;
    COMMIT;

    --23. 其他资产

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       IS_TOTAL --是否参与汇总：Y 参与汇总  N 不参与汇总
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'GF01' AS REP_NUM, --报表编号
             'GF0100_23..A' AS ITEM_NUM, --指标号
             SUM(CASE
                   WHEN T1.DEBIT_BAL - T1.CREDIT_BAL > 0 THEN
                    T1.DEBIT_BAL - T1.CREDIT_BAL
                   ELSE
                    0
                 END * T2.CCY_RATE) ITEM_VAL,
             '1' AS FLAG,
             'N' AS IS_TOTAL
        FROM CBRC_GF01_L_FINA_GL T1
        LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T1.CURR_CD = T2.BASIC_CCY
         AND T2.FORWARD_CCY = 'CNY'
         AND T1.DATA_DATE = T2.DATA_DATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD IN ('300106','300107')
         AND T1.CURR_CD = 'CNY'
       GROUP BY ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       IS_TOTAL --是否参与汇总：Y 参与汇总  N 不参与汇总
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'GF01' AS REP_NUM, --报表编号
             'GF0100_23..B' AS ITEM_NUM, --指标号
             CASE
               WHEN A.DEBIT_BAL - A.CREDIT_BAL > 0 THEN
                A.DEBIT_BAL - A.CREDIT_BAL
               ELSE
                0
             END ITEM_VAL,
             '1' AS FLAG,
             'N' AS IS_TOTAL
        FROM (SELECT ORG_NUM,
                     SUM(T1.DEBIT_BAL * T2.CCY_RATE) DEBIT_BAL,
                     SUM(T1.CREDIT_BAL * T2.CCY_RATE) CREDIT_BAL
                FROM CBRC_GF01_L_FINA_GL T1
               INNER JOIN SMTMODS_L_PUBL_RATE T2
                  ON T1.CURR_CD = T2.BASIC_CCY
                 AND T2.FORWARD_CCY = 'CNY'
                 AND T1.DATA_DATE = T2.DATA_DATE
               WHERE T1.DATA_DATE = I_DATADATE
                 AND T1.ITEM_CD IN ('300106','300107')
                 AND T1.CURR_CD <> 'CNY'
               GROUP BY ORG_NUM) A;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       IS_TOTAL --是否参与汇总：Y 参与汇总  N 不参与汇总
       )
    
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'GF01' AS REP_NUM, --报表编号
             'GF0100_23..C' AS ITEM_NUM, --指标号
             SUM(A.ITEM_VAL) ITEM_VAL,
             '1' AS FLAG,
             'N' AS IS_TOTAL
        FROM CBRC_A_REPT_ITEM_VAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_NUM IN ('GF0100_23..A', 'GF0100_23..B')
       GROUP BY ORG_NUM ;
       COMMIT;

    --72.系统内存放款项

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       IS_TOTAL --是否参与汇总：Y 参与汇总  N 不参与汇总
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'GF01' AS REP_NUM, --报表编号
             'GF0100_72..A' AS ITEM_NUM, --指标号
             SUM(CASE
                   WHEN T1.CREDIT_BAL - T1.DEBIT_BAL > 0 THEN
                    T1.CREDIT_BAL - T1.DEBIT_BAL
                   ELSE
                    0
                 END * T2.CCY_RATE) ITEM_VAL,
             '1' AS FLAG,
             'N' AS IS_TOTAL
        FROM CBRC_GF01_L_FINA_GL T1
        LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T1.CURR_CD = T2.BASIC_CCY
         AND T2.FORWARD_CCY = 'CNY'
         AND T1.DATA_DATE = T2.DATA_DATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD IN ('300106')
         AND T1.CURR_CD = 'CNY'
       GROUP BY ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       IS_TOTAL --是否参与汇总：Y 参与汇总  N 不参与汇总
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'GF01' AS REP_NUM, --报表编号
             'GF0100_72..B' AS ITEM_NUM, --指标号
             CASE
               WHEN A.CREDIT_BAL - A.DEBIT_BAL > 0 THEN
                A.CREDIT_BAL - A.DEBIT_BAL
               ELSE
                0
             END ITEM_VAL,
             '1' AS FLAG,
             'N' AS IS_TOTAL
        FROM (SELECT ORG_NUM,
                     SUM(T1.DEBIT_BAL * T2.CCY_RATE) DEBIT_BAL,
                     SUM(T1.CREDIT_BAL * T2.CCY_RATE) CREDIT_BAL
                FROM CBRC_GF01_L_FINA_GL T1
               INNER JOIN SMTMODS_L_PUBL_RATE T2
                  ON T1.CURR_CD = T2.BASIC_CCY
                 AND T2.FORWARD_CCY = 'CNY'
                 AND T1.DATA_DATE = T2.DATA_DATE
               WHERE T1.DATA_DATE = I_DATADATE
                 AND T1.ITEM_CD IN ('300106')
                 AND T1.CURR_CD <> 'CNY'
               GROUP BY ORG_NUM) A;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       IS_TOTAL --是否参与汇总：Y 参与汇总  N 不参与汇总
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'GF01' AS REP_NUM, --报表编号
             'GF0100_72..C' AS ITEM_NUM, --指标号
             CASE
               WHEN A.CREDIT_BAL - A.DEBIT_BAL > 0 THEN
                A.CREDIT_BAL - A.DEBIT_BAL
               ELSE
                0
             END ITEM_VAL,
             '1' AS FLAG,
             'N' AS IS_TOTAL
        FROM (SELECT ORG_NUM,
                     SUM(T1.DEBIT_BAL * T2.CCY_RATE) DEBIT_BAL,
                     SUM(T1.CREDIT_BAL * T2.CCY_RATE) CREDIT_BAL
                FROM CBRC_GF01_L_FINA_GL T1
               INNER JOIN SMTMODS_L_PUBL_RATE T2
                  ON T1.CURR_CD = T2.BASIC_CCY
                 AND T2.FORWARD_CCY = 'CNY'
                 AND T1.DATA_DATE = T2.DATA_DATE
               WHERE T1.DATA_DATE = I_DATADATE
                 AND T1.ITEM_CD IN ('300106')
              -- AND T1.CURR_CD <>'CNY'
               GROUP BY ORG_NUM) A;
    COMMIT;

    --47. 其他负债

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       IS_TOTAL --是否参与汇总：Y 参与汇总  N 不参与汇总
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'GF01' AS REP_NUM, --报表编号
             'GF0100_47..A' AS ITEM_NUM, --指标号
             SUM(CASE
                   WHEN T1.CREDIT_BAL - T1.DEBIT_BAL > 0 THEN
                    T1.CREDIT_BAL - T1.DEBIT_BAL
                   ELSE
                    0
                 END * T2.CCY_RATE) ITEM_VAL,
             '1' AS FLAG,
             'N' AS IS_TOTAL
        FROM CBRC_GF01_L_FINA_GL T1
        LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T1.CURR_CD = T2.BASIC_CCY
         AND T2.FORWARD_CCY = 'CNY'
         AND T1.DATA_DATE = T2.DATA_DATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD IN ('300106', '300107')
         AND T1.CURR_CD = 'CNY'
       GROUP BY ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       IS_TOTAL --是否参与汇总：Y 参与汇总  N 不参与汇总
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'GF01' AS REP_NUM, --报表编号
             'GF0100_47..B' AS ITEM_NUM, --指标号
             CASE
               WHEN A.CREDIT_BAL - A.DEBIT_BAL > 0 THEN
                A.CREDIT_BAL - A.DEBIT_BAL
               ELSE
                0
             END ITEM_VAL,
             '1' AS FLAG,
             'N' AS IS_TOTAL
        FROM (SELECT ORG_NUM,
                     T1.ITEM_CD,
                     SUM(T1.DEBIT_BAL * T2.CCY_RATE) DEBIT_BAL,
                     SUM(T1.CREDIT_BAL * T2.CCY_RATE) CREDIT_BAL
                FROM CBRC_GF01_L_FINA_GL T1
               INNER JOIN SMTMODS_L_PUBL_RATE T2
                  ON T1.CURR_CD = T2.BASIC_CCY
                 AND T2.FORWARD_CCY = 'CNY'
                 AND T1.DATA_DATE = T2.DATA_DATE
               WHERE T1.DATA_DATE = I_DATADATE
                 AND T1.ITEM_CD IN ('300106', '300107')
                 AND T1.CURR_CD <> 'CNY'
               GROUP BY ORG_NUM, T1.ITEM_CD) A;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       IS_TOTAL --是否参与汇总：Y 参与汇总  N 不参与汇总
       )
     
        SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'GF01' AS REP_NUM, --报表编号
             'GF0100_47..C' AS ITEM_NUM, --指标号
             SUM(A.ITEM_VAL) ITEM_VAL,
             '1' AS FLAG,
             'N' AS IS_TOTAL
        FROM CBRC_A_REPT_ITEM_VAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_NUM IN ('GF0100_47..A', 'GF0100_47..B')
       GROUP BY ORG_NUM ;
       COMMIT;
    COMMIT;

    --52. 实收资本
    --1)若300107本外币合计口径（借-贷）为负，取该绝对值
    --2）若300107本外币合计口径（借-贷）为正，取4001本外币合计口径贷-300107本外币合计口径（借-贷）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       IS_TOTAL --是否参与汇总：Y 参与汇总  N 不参与汇总
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'GF01' AS REP_NUM, --报表编号
             'GF0100_52..A' AS ITEM_NUM, --指标号
             CASE
               WHEN A.DEBIT_BAL - A.CREDIT_BAL < 0 --借-贷
                THEN
                abs(A.DEBIT_BAL - A.CREDIT_BAL)
               WHEN A.DEBIT_BAL - A.CREDIT_BAL > 0 THEN
                B.CREDIT_BAL1 - (A.DEBIT_BAL - A.CREDIT_BAL)
               ELSE
                0
             END ITEM_VAL,
             '1' AS FLAG,
             'N' AS IS_TOTAL
        FROM (SELECT ORG_NUM,
                     SUM(T1.DEBIT_BAL * T2.CCY_RATE) DEBIT_BAL,
                     SUM(T1.CREDIT_BAL * T2.CCY_RATE) CREDIT_BAL
                FROM CBRC_GF01_L_FINA_GL T1
               INNER JOIN SMTMODS_L_PUBL_RATE T2
                  ON T1.CURR_CD = T2.BASIC_CCY
                 AND T2.FORWARD_CCY = 'CNY'
                 AND T1.DATA_DATE = T2.DATA_DATE
               WHERE T1.DATA_DATE = I_DATADATE
                 AND T1.ITEM_CD IN ('300107')
                 AND T1.CURR_CD = 'CNY'
               GROUP BY ORG_NUM) A
        left join (SELECT ORG_NUM,
                          SUM(T1.CREDIT_BAL * T2.CCY_RATE) CREDIT_BAL1
                     FROM CBRC_GF01_L_FINA_GL T1
                    INNER JOIN SMTMODS_L_PUBL_RATE T2
                       ON T1.CURR_CD = T2.BASIC_CCY
                      AND T2.FORWARD_CCY = 'CNY'
                      AND T1.DATA_DATE = T2.DATA_DATE
                    WHERE T1.DATA_DATE = I_DATADATE
                      AND T1.ITEM_CD IN ('4001')
                      AND T1.CURR_CD = 'CNY'
                    GROUP BY ORG_NUM) B
          ON A.ORG_NUM = B.ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       IS_TOTAL --是否参与汇总：Y 参与汇总  N 不参与汇总
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'GF01' AS REP_NUM, --报表编号
             'GF0100_52..B' AS ITEM_NUM, --指标号
             CASE
               WHEN A.DEBIT_BAL - A.CREDIT_BAL < 0 --借-贷
                THEN
                abs(A.DEBIT_BAL - A.CREDIT_BAL)
               WHEN A.DEBIT_BAL - A.CREDIT_BAL > 0 THEN
                B.CREDIT_BAL1 - (A.DEBIT_BAL - A.CREDIT_BAL)
               ELSE
                0
             END ITEM_VAL,
             '1' AS FLAG,
             'N' AS IS_TOTAL
        FROM (SELECT ORG_NUM,
                     SUM(T1.DEBIT_BAL * T2.CCY_RATE) DEBIT_BAL,
                     SUM(T1.CREDIT_BAL * T2.CCY_RATE) CREDIT_BAL
                FROM CBRC_GF01_L_FINA_GL T1
               INNER JOIN SMTMODS_L_PUBL_RATE T2
                  ON T1.CURR_CD = T2.BASIC_CCY
                 AND T2.FORWARD_CCY = 'CNY'
                 AND T1.DATA_DATE = T2.DATA_DATE
               WHERE T1.DATA_DATE = I_DATADATE
                 AND T1.ITEM_CD IN ('300107')
                 AND T1.CURR_CD <> 'CNY'
               GROUP BY ORG_NUM) A
        left join (SELECT ORG_NUM,
                          SUM(T1.CREDIT_BAL * T2.CCY_RATE) CREDIT_BAL1
                     FROM CBRC_GF01_L_FINA_GL T1
                    INNER JOIN SMTMODS_L_PUBL_RATE T2
                       ON T1.CURR_CD = T2.BASIC_CCY
                      AND T2.FORWARD_CCY = 'CNY'
                      AND T1.DATA_DATE = T2.DATA_DATE
                    WHERE T1.DATA_DATE = I_DATADATE
                      AND T1.ITEM_CD IN ('4001')
                      AND T1.CURR_CD <> 'CNY'
                    GROUP BY ORG_NUM) B
          ON A.ORG_NUM = B.ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       IS_TOTAL --是否参与汇总：Y 参与汇总  N 不参与汇总
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'GF01' AS REP_NUM, --报表编号
             'GF0100_52..C' AS ITEM_NUM, --指标号
             CASE
               WHEN A.DEBIT_BAL - A.CREDIT_BAL < 0 --借-贷
                THEN
                abs(A.DEBIT_BAL - A.CREDIT_BAL)
               WHEN A.DEBIT_BAL - A.CREDIT_BAL > 0 THEN
                B.CREDIT_BAL1 - (A.DEBIT_BAL - A.CREDIT_BAL)
               ELSE
                0
             END ITEM_VAL,
             '1' AS FLAG,
             'N' AS IS_TOTAL
        FROM (SELECT ORG_NUM,
                     SUM(T1.DEBIT_BAL * T2.CCY_RATE) DEBIT_BAL,
                     SUM(T1.CREDIT_BAL * T2.CCY_RATE) CREDIT_BAL
                FROM CBRC_GF01_L_FINA_GL T1
               INNER JOIN SMTMODS_L_PUBL_RATE T2
                  ON T1.CURR_CD = T2.BASIC_CCY
                 AND T2.FORWARD_CCY = 'CNY'
                 AND T1.DATA_DATE = T2.DATA_DATE
               WHERE T1.DATA_DATE = I_DATADATE
                 AND T1.ITEM_CD IN ('300107')
               GROUP BY ORG_NUM) A
        left join (SELECT ORG_NUM,
                          SUM(T1.CREDIT_BAL * T2.CCY_RATE) CREDIT_BAL1
                     FROM CBRC_GF01_L_FINA_GL T1
                    INNER JOIN SMTMODS_L_PUBL_RATE T2
                       ON T1.CURR_CD = T2.BASIC_CCY
                      AND T2.FORWARD_CCY = 'CNY'
                      AND T1.DATA_DATE = T2.DATA_DATE
                    WHERE T1.DATA_DATE = I_DATADATE
                      AND T1.ITEM_CD IN ('4001')
                    GROUP BY ORG_NUM) B
          ON A.ORG_NUM = B.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID+1;
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
   
END proc_cbrc_idx2_gf01