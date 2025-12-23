CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_result(II_DATADATE IN string,--
                                          II_REP_NUM IN string
                                          )
/******************************
  @AUTHOR:XIANGXU
  @CREATE-DATE:2015-09-06
  @DESCRIPTION:TMP
  @MODIFICATION HISTORY:
  M0.20150906-XIANGXU-TMP
  
  
cbrc_a_rept_item_val
cbrc_a
cbrc_a_rept_item_result
cbrc_inst_level
cbrc_t_org_temp
cbrc_uprr_u_base_inst
  *******************************/
 IS
  --V_SCHEMA    VARCHAR2(10); --
  V_PROCEDURE VARCHAR2(30); --
  I_DATADATE  string; --()YYYYMMDD
  V_STEP_ID   INTEGER; --
  V_STEP_DESC VARCHAR(300); --
  V_STEP_FLAG INTEGER; --
  V_LAST_M    VARCHAR2(10); --
  V_LAST_Q    VARCHAR2(10); --
  I_PLAN_FLAG INTEGER; --
  I_EPP_FLAG  INTEGER; --
  I_EGS_FLAG  INTEGER; --
  I_EXE_FALSE INTEGER; --
  V_EXE_FLAG  VARCHAR2(10); --/
  V_INT       NUMBER(5);
  V_DATADATE  VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  V_ERRORCODE VARCHAR(20); --错误编码
  V_ERRORDESC VARCHAR(280); --错误内容
  v_Org_Level number(20);

  v_max_level  number(20); --最大级别
  v_curr_level number(20); --当前级别
  V_REP_NUM   VARCHAR2(30); --报表编号
  V_SYSTEM    VARCHAR2(30);

BEGIN
  V_STEP_ID   := 0;
  V_STEP_DESC := '';
  V_SYSTEM    := 'CBRC';
  V_STEP_FLAG := 0;
  I_DATADATE  := II_DATADATE;
  V_DATADATE  := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYY-MM-DD');
  --V_SCHEMA  := USER;

   select  DECODE(UPPER(II_REP_NUM),
                            'G5306','G53_6',
                            'G0101','G01_1',
                            'G0102','G01_2',
                            'G0103','G01_3',
                            'G0104','G01_4',
                            'G0105','G01_5',
                            'G0106','G01_6',
                            'G0107','G01_7',
                            'G0108','G01_8',
                            'G0109','G01_9',
                            'G010101','G01_I_1',
                            'G0501','G05_I',
                            'G11_1','G1101',
                            'G11_2','G1102',
                            'G22','G22R',
                            'G25_1','G2501',
                            'G25_2','G2502',
                            'G3101','G31_I',
                            'G3302','G33_2',
                            'G4A01A','G4A-1(a)',
                            'G53_5','G5305',
                            'S63_1','S6301',
                            'S63_II','S6302',
                            'S63_III','S6303',
                            'S64_1','S6401',
                            'S64_II','S6402',
                            'S65_I','S6501',
                            'S65_II','S6502',
                            'S7001','S70_1',
                            'S71_I','S7101',
                            'S71_II','S7102',
                            'S71_III','S7103', 
                            'G0105','G01_5',
                            'G0601','G06_1',
                            'G0602','G06_2',
                            UPPER(II_REP_NUM)) into V_REP_NUM
                         FROM SYSTEM.DUAL;


  V_PROCEDURE := UPPER('PROC_CBRC_RESULT')||'_'|| II_REP_NUM;
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);
  V_STEP_ID   := 1;
  V_STEP_FLAG := 0;
  V_STEP_DESC := '清理 [CBRC_A_REPT_ITEM_RESULT]表[' || V_DATADATE || ']期数据';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);
  delete CBRC_inst_LEVEL;
  commit;
  DELETE FROM CBRC_A_REPT_ITEM_RESULT WHERE DATA_DATE = V_DATADATE AND REP_NUM= V_REP_NUM;
  commit;

  V_STEP_ID   := 2;
  V_STEP_DESC := '把指标中间表中的数据，依据指标配置表中的配置，抽取到最终的指标表中';
  V_STEP_FLAG := 0;
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);

  INSERT 
  INTO CBRC_A_REPT_ITEM_RESULT 
    (DATA_DATE, --数据日期
     ORG_NUM, --机构号
     SYS_NAM, --系统编号
     REP_NUM, --报表名
     ITEM_NUM, --指标名
     ITEM_VAL, --指标值（数值型）
     ITEM_VAL_V, --指标值（字符型）
     IS_TOTAL,
     DATA_DEPARTMENT
     )
    SELECT V_DATADATE, --数据日期
           B.ORG_NUM, --机构号
           B.SYS_NAM, --系统编号
           B.REP_NUM, --报表名
           B.ITEM_NUM, --指标名
           SUM(B.ITEM_VAL), --指标值（数值型）
           B.ITEM_VAL_V, --指标值（字符型）
           IS_TOTAL,
           '' DATA_DEPARTMENT 
      FROM CBRC_A_REPT_ITEM_VAL B --中间临时指标表
       WHERE B.DATA_DATE = I_DATADATE
         AND B.REP_NUM =  V_REP_NUM
       GROUP BY B.ORG_NUM,B.SYS_NAM,B.REP_NUM ,B.ITEM_NUM,B.ITEM_VAL_V,IS_TOTAL;

  COMMIT;

  FOR ORG_TMP IN (SELECT A.INST_ID, A.INST_NAME, A.INST_SMP_NAME, A.PARENT_INST_ID, A.INST_LAYER, A.ADDRESS, A.ZIP, A.TEL, A.FAX, A.IS_BUSSINESS, A.ORDER_NUM, A.DESCRIPTION, A.START_DATE, A.END_DATE, A.CREATE_TIME, A.ENABLED, A.INST_REGION, A.EMAIL, A.INST_PATH, A.INST_LEVEL, A.IS_HEAD 
 FROM CBRC_UPRR_U_BASE_INST A ) LOOP

    SELECT COUNT(1)
      INTO V_ORG_LEVEL
      FROM CBRC_UPRR_U_BASE_INST T
     START WITH INST_ID = ORG_TMP.INST_ID
    CONNECT BY PRIOR PARENT_INST_ID = INST_ID;

    INSERT INTO CBRC_inst_LEVEL
      (ORG_NUM, ORG_LEVEL)
    VALUES
      (ORG_TMP.INST_ID, V_ORG_LEVEL);
    COMMIT;
  END LOOP;

  V_STEP_ID   := 2;
  V_STEP_DESC := '按照BANK_RELATION汇总数据';
  V_STEP_FLAG := 0;
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);

  SELECT MAX(T.ORG_LEVEL) INTO V_MAX_LEVEL FROM CBRC_inst_LEVEL T;

  FOR I IN 1 .. V_MAX_LEVEL - 1 LOOP

    V_CURR_LEVEL := V_MAX_LEVEL - I;

    insert into CBRC_A
     select  V_CURR_LEVEL from system.dual;
     commit;


    FOR ORGNUM IN (SELECT T.ORG_NUM
                      FROM CBRC_inst_LEVEL T
                     WHERE T.ORG_LEVEL = V_CURR_LEVEL
                     and org_num in
                     (SELECT A3.PARENT_INST_ID
                        FROM CBRC_UPRR_U_BASE_INST A3
                      )

                     )  LOOP

      --删除下级有数据的机构
      DELETE FROM CBRC_A_REPT_ITEM_RESULT A
       WHERE A.DATA_DATE = V_DATADATE
         AND A.ORG_NUM = ORGNUM.ORG_NUM
         AND A.REP_NUM =  V_REP_NUM
         AND EXISTS (SELECT *
                FROM CBRC_A_REPT_ITEM_RESULT A1
               WHERE A1.DATA_DATE = A.DATA_DATE
                 AND A1.REP_NUM = A.REP_NUM
                 AND A1.ITEM_NUM = A.ITEM_NUM
                 AND A1.REP_NUM =  V_REP_NUM
                 AND A1.ORG_NUM IN
                     (SELECT A3.INST_ID
                        FROM CBRC_UPRR_U_BASE_INST A3
                       WHERE A3.PARENT_INST_ID = ORGNUM.ORG_NUM)
                 AND A1.ITEM_VAL <> 0)
        AND (A.IS_TOTAL <> 'N' OR A.IS_TOTAL IS NULL);  --去掉不参与汇总指标

   
      INSERT INTO CBRC_A_REPT_ITEM_RESULT 
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --系统编号
         REP_NUM, --报表名
         ITEM_NUM, --指标名
         ITEM_VAL, --指标值（数值型）
         ITEM_VAL_V --指标值（字符型）
         )
        SELECT V_DATADATE AS DATA_DATE, --数据日期
              ORGNUM.ORG_NUM  AS ORG_NUM, --机构号
               A.SYS_NAM, --系统编号
               A.REP_NUM, --报表名
               A.ITEM_NUM, --指标名
               SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值（数值型）
               MAX(A.ITEM_VAL_V) AS ITEM_VAL_V --指标值（字符型）
          FROM CBRC_A_REPT_ITEM_RESULT A
         where A.ORG_NUM IN
               (SELECT A3.INST_ID
                  FROM CBRC_UPRR_U_BASE_INST A3
                 WHERE A3.PARENT_INST_ID = ORGNUM.ORG_NUM )
           AND A.ITEM_VAL <> 0
           and a.data_date = V_DATADATE
           AND A.REP_NUM =  V_REP_NUM
           AND (A.IS_TOTAL <> 'N' OR A.IS_TOTAL IS NULL)   --去掉不参与汇总指标
         GROUP BY A.SYS_NAM, A.REP_NUM, A.ITEM_NUM, A.B_CURR_CD;
      commit;

      SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                  V_STEP_ID,
                  V_ERRORCODE,
                  ORGNUM.ORG_NUM,
                  II_DATADATE);

    end loop;

  END LOOP;

--汇总县辖 市辖总账数据  zhoujingkun  20221123
  FOR TEMP IN (SELECT ORG_NUM FROM CBRC_T_ORG_TEMP) LOOP
    --CBRC_T_ORG_TEMP该表用于存储市辖县辖等特殊汇总机构，总账不提供该类机构数据，该表在增加汇总机构时手工维护。
    --删除总账数据
    DELETE FROM CBRC_A_REPT_ITEM_RESULT T
     WHERE T.DATA_DATE = V_DATADATE
       AND T.ORG_NUM = TEMP.ORG_NUM
       AND T.REP_NUM = V_REP_NUM
       AND T.ITEM_NUM IN (SELECT DISTINCT ITEM_NUM
                            FROM CBRC_A_REPT_ITEM_RESULT
                           WHERE  IS_TOTAL= 'N')
       AND NOT (T.REP_NUM  LIKE 'G23%' OR T.REP_NUM LIKE 'G15%'OR T.REP_NUM LIKE 'GF01%'); --G23不需要汇总 add  by djh 20230104
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_RESULT
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       ITEM_VAL,
       ITEM_VAL_V,
       B_CURR_CD)
      
        SELECT DATA_DATE,
             TEMP.ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             MAX(ITEM_VAL_V),
             B_CURR_CD
        FROM CBRC_A_REPT_ITEM_RESULT T
       WHERE T.DATA_DATE = V_DATADATE
         AND T.ORG_NUM IN
             (SELECT U.INST_ID
                FROM CBRC_UPRR_U_BASE_INST U
              where PARENT_INST_ID = TEMP.ORG_NUM)
         AND T.ITEM_NUM IN (SELECT DISTINCT ITEM_NUM
                            FROM CBRC_A_REPT_ITEM_RESULT
                           WHERE  IS_TOTAL= 'N')
         AND NOT (T.REP_NUM  LIKE 'G23%' OR T.REP_NUM LIKE 'G15%'OR T.REP_NUM LIKE 'GF01%') --G23不需要汇总 add  by djh 20230104
         AND T.REP_NUM = V_REP_NUM
       GROUP BY DATA_DATE, SYS_NAM, REP_NUM, ITEM_NUM, B_CURR_CD;
    COMMIT;

  END LOOP;

    DBMS_OUTPUT.PUT_LINE('O_STATUS=0');
    DBMS_OUTPUT.PUT_LINE('O_STATUS_DEC=完成'); 

EXCEPTION
  WHEN OTHERS THEN
    V_STEP_DESC := '' || TO_CHAR(SQLCODE) || SUBSTR(SQLERRM, 1, 280);
    V_STEP_FLAG := -1;
    DBMS_OUTPUT.PUT_LINE('O_STATUS=-1');
    DBMS_OUTPUT.PUT_LINE('O_STATUS_DEC=失败'); 
    --记录异常信息
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    ROLLBACK;
  

END proc_cbrc_result