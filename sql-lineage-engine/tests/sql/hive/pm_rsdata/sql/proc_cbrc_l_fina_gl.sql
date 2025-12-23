CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_l_fina_gl(II_DATADATE IN STRING --跑批日期
                                              )
/******************************
  @author:luoyujie
  @create-date:20150924
  @description:总账的汇总逻辑
  @modification history:
  m0.author-create_date-description
  m001.xiangxu-20160407-增加2061制度升级后,非单一币种的大集中报表A3414_1特殊处理

目标表：PM_RSDATA.CBRC_A_REPT_ITEM_VAL
临时表：PM_RSDATA.CBRC_L_FINA_GL_TMP1
     PM_RSDATA.CBRC_SAP_MAP_INFO_TMP1
     PM_RSDATA.CBRC_SAP_MAP_INFO_TMP2
     PM_RSDATA.CBRC_L_FINA_GL_TMP2
     PM_RSDATA.CBRC_L_FINA_GL_TMP3
     PM_RSDATA.CBRC_L_FINA_GL_TMP4
     PM_RSDATA.CBRC_A_REPT_ITEM_VAL_TMP
集市表：PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL
     PM_RSDATA.SMTMODS_L_PUBL_RATE
配置表：PM_RSDATA.CBRC_SAP_MAP_INFO
     PM_RSDATA.CBRC_ZH_ITEM_REPORT_RELATION
     PM_RSDATA.CBRC_ZH_ITEM_FORMULA
     
  *******************************/
 IS
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCNAME     VARCHAR(30); --当前储存过程名称
  V_TAB_NAME     VARCHAR(30); --目标表名
  I_DATADATE     STRING; --数据日期(数值型)YYYYMMDD
  D_DATADATE     STRING; --数据日期(数据型)YYYYMMDD
  D_DATADATE_CCY STRING; --数据日期(日期型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  D_YEAR0101     STRING; --年初数据日期
  I_YEAR0101     STRING; --上年初日期
  I_YEARMONTH    STRING; --本月日期值，YYYYMM00
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_ERRORDESC    VARCHAR(280); --错误内容
  V_PROCEDURE    VARCHAR(30); --当前储存过程名称
  II_STATUS    INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM        VARCHAR2(30);

 
BEGIN


  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';

    I_DATADATE := II_DATADATE;
    V_SYSTEM   := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_L_FINA_GL');
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_TAB_NAME     := 'PM_RSDATA.CBRC_A_REPT_ITEM_VAL';
    D_DATADATE     := I_DATADATE;
    D_YEAR0101     := to_char(TRUNC(date(I_DATADATE),'YYYY'),'YYYYMMDD') ;
    I_YEAR0101     := TO_CHAR(D_YEAR0101, 'YYYYMMDD');
    D_DATADATE_CCY := I_DATADATE;
    I_YEARMONTH    := TRUNC(TO_NUMBER(I_DATADATE), -2)  ;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '删除当期数据及临时表数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    
    EXECUTE IMMEDIATE ('TRUNCATE TABLE PM_RSDATA.CBRC_L_FINA_GL_TMP1');
    EXECUTE IMMEDIATE ('TRUNCATE TABLE PM_RSDATA.CBRC_SAP_MAP_INFO_TMP1');
    EXECUTE IMMEDIATE ('TRUNCATE TABLE PM_RSDATA.CBRC_SAP_MAP_INFO_TMP2');
    EXECUTE IMMEDIATE ('TRUNCATE TABLE PM_RSDATA.CBRC_L_FINA_GL_TMP2');
    EXECUTE IMMEDIATE ('TRUNCATE TABLE PM_RSDATA.CBRC_L_FINA_GL_TMP3');
    EXECUTE IMMEDIATE ('TRUNCATE TABLE PM_RSDATA.CBRC_L_FINA_GL_TMP4');
    EXECUTE IMMEDIATE ('TRUNCATE TABLE PM_RSDATA.CBRC_A_REPT_ITEM_VAL_TMP');

    DELETE FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND FLAG = '1'
       AND REP_NUM NOT IN('G21','G22R','G2501','G2502','G33','G15','G05_I'); -- modi by djh 20220804 由于重新跑删掉过程数据，因此重跑删除去掉;
    COMMIT;
    
   
    V_STEP_ID   := 2;
    V_STEP_DESC := '按日、月、年汇总借方、贷方余额';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO PM_RSDATA.CBRC_L_FINA_GL_TMP1
      (DATA_DATE, --数据日期
       ACCTOUNT_DT, --会计日期
       ORG_NUM, --机构号
       ITEM_CD, --科目号
       PRODUCT_CD, --产品代码
       CURR_CD, --记账币种
       ORIG_CURR_CD, --原始币种
       CR_BAL, --贷方额
       DR_BAL, --借方额
       BAL_G, --余额,取绝对值
       CR_Y_AMT, --贷方年累计发生额
       DR_Y_AMT, --借方年累计发生额
       CR_M_AMT, --贷方月累计发生额
       DR_M_AMT --借方月累计发生额
       )
      SELECT G.DATA_DATE, --数据日期
             TO_CHAR(G.ACCTOUNT_DT, 'YYYYMMDD') AS ACCTOUNT_DT, --会计日期
             G.ORG_NUM, --机构号
             G.ITEM_CD, --科目号
             G.PRODUCT_CD, --产品代码
             G.CURR_CD, --记账币种
             G.ORIG_CURR_CD, --原始币种
             NVL(SUM(CASE
                       WHEN DATA_DATE = I_DATADATE THEN
                        G.CREDIT_BAL
                     END),
                 0) AS CR_BAL, --贷方额
             NVL(SUM(CASE
                       WHEN DATA_DATE = I_DATADATE THEN
                        G.DEBIT_BAL
                     END),
                 0) AS DR_BAL, --借方额
             SUM(CASE
                   WHEN DATA_DATE = I_DATADATE THEN
                    ABS(NVL(G.DEBIT_BAL, 0) - NVL(G.CREDIT_BAL, 0))
                   ELSE
                    0
                 END) AS BAL_G, --余额,取绝对值
             NVL(SUM(CASE
                       WHEN DATA_DATE >= D_YEAR0101 AND DATA_DATE <= I_DATADATE THEN
                        G.CREDIT_Y_AMT
                     END),
                 0) AS CR_Y_AMT, --贷方年累计发生额
             NVL(SUM(CASE
                       WHEN DATA_DATE >= D_YEAR0101 AND DATA_DATE <= I_DATADATE THEN
                        G.DEBIT_Y_AMT
                     END),
                 0) AS DR_Y_AMT, --借方年累计发生额
             NVL(SUM(CASE
                       WHEN SUBSTR(DATA_DATE,1,6) = SUBSTR(I_DATADATE,1,6) THEN
                        G.CREDIT_M_AMT
                     END),
                 0) AS CR_M_AMT, --贷方月累计发生额
             NVL(SUM(CASE
                       WHEN SUBSTR(DATA_DATE,1,6) = SUBSTR(I_DATADATE,1,6) THEN
                        G.DEBIT_M_AMT
                     END),
                 0) AS DR_M_AMT --借方月累计发生额
        FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL G
       WHERE G.ACCTOUNT_DT BETWEEN D_YEAR0101 AND I_DATADATE --记账日在本年
         AND G.DATA_DATE = I_DATADATE
       GROUP BY DATA_DATE, --数据日期
                ACCTOUNT_DT, --会计日期
                ORG_NUM, --机构号
                ITEM_CD, --科目号
                PRODUCT_CD, --产品代码
                CURR_CD, --记账币种
                ORIG_CURR_CD; --原始币种

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 3;
    V_STEP_DESC := '根据总账配置中的数据类型处理数据';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO PM_RSDATA.CBRC_SAP_MAP_INFO_TMP1
      (DATA_TYPE, --借贷标识
       ACCI_NO --科目号
       )
      SELECT DISTINCT DATA_TYPE, --借贷标识
                      CASE
                        WHEN SUBSTR(B.ACCI_NO, -1, 1) <> '%' THEN
                         B.ACCI_NO
                        ELSE
                         SUBSTR(B.ACCI_NO, 1, INSTR(B.ACCI_NO, '%', 1) - 1) || '%'
                      END ACCI_NO --科目号
        FROM PM_RSDATA.CBRC_SAP_MAP_INFO B
       WHERE B.DATA_TYPE IN
             ('BAL', 'CBAL', 'DBAL', 'CAML', 'DAML', 'YCAML', 'YDAML');

    INSERT INTO PM_RSDATA.CBRC_SAP_MAP_INFO_TMP2
      (DPV_ID, --内部指标号
       IS_DEL, --正负号标识
       ACCI_NO, --科目号
       PROD_ID, --产品编号
       DATA_TYPE, --借贷标识
       DR_FLAG, --轧差组别号
       POS_FLAG --轧差组内运算要求：Y表示结果要>0，N表示结果要<0，-表示对结果正负没限制
       )
      SELECT B.DPV_ID, --内部指标号
             CASE
               WHEN IS_DEL = 'Y' THEN
                (-1)
               ELSE
                1
             END, --正负号标识
             CASE
               WHEN SUBSTR(B.ACCI_NO, -1, 1) <> '%' THEN
                B.ACCI_NO
               ELSE
                SUBSTR(B.ACCI_NO, 1, INSTR(B.ACCI_NO, '%', 1) - 1) || '%'
             END ACCI_NO, --科目号
             B.PROD_ID, --产品编号
             B.DATA_TYPE, --借贷标识
             B.DR_FLAG, --轧差组别号
             B.POS_FLAG --轧差组内运算要求：Y表示结果要>0，N表示结果要<0，-表示对结果正负没限制
        FROM PM_RSDATA.CBRC_SAP_MAP_INFO B;
    COMMIT;



    INSERT INTO PM_RSDATA.CBRC_L_FINA_GL_TMP2
      (ACCTOUNT_DT, --会计日期
       ORG_NUM, --机构号
       ITEM_CD, --科目号
       PRODUCT_CD, --产品代码
       CURR_CD, --记账币种
       ORIG_CURR_CD, --原始币种
       DATA_TYPE, --数据类型
       ITEM_VALUE, --原币种余额
       ITEM_VALUE_CNY, --折人民币余额
       ITEM_VALUE_USD --折美元余额
       )
      SELECT DISTINCT A.ACCTOUNT_DT, --会计日期
                      A.ORG_NUM, --机构号
                      A.ITEM_CD, --科目号
                      A.PRODUCT_CD, --产品代码
                      A.CURR_CD, --记账币种
                      A.ORIG_CURR_CD, --原始币种
                      B.DATA_TYPE, --数据类型
                      CASE
                        WHEN B.DATA_TYPE = 'BAL' THEN
                         A.BAL_G --余额
                        WHEN B.DATA_TYPE = 'CBAL' THEN
                         A.CR_BAL --贷方余额
                        WHEN B.DATA_TYPE = 'DBAL' THEN
                         A.DR_BAL --借方余额
                        WHEN B.DATA_TYPE = 'CAML' THEN
                         A.CR_M_AMT --贷方月发生额
                        WHEN B.DATA_TYPE = 'DAML' THEN
                         A.DR_M_AMT --借方月发生额
                        WHEN B.DATA_TYPE = 'YCAML' THEN
                         A.CR_Y_AMT --贷方年发生额
                        WHEN B.DATA_TYPE = 'YDAML' THEN
                         A.DR_Y_AMT --借方年发生额
                      END AS ITEM_VALUE, --原币种余额
                      CASE
                        WHEN B.DATA_TYPE = 'BAL' THEN
                         A.BAL_G * U.CCY_RATE --余额
                        WHEN B.DATA_TYPE = 'CBAL' THEN
                         A.CR_BAL * U.CCY_RATE --贷方余额
                        WHEN B.DATA_TYPE = 'DBAL' THEN
                         A.DR_BAL * U.CCY_RATE --借方余额
                        WHEN B.DATA_TYPE = 'CAML' THEN
                         A.CR_M_AMT * U.CCY_RATE --贷方月发生额
                        WHEN B.DATA_TYPE = 'DAML' THEN
                         A.DR_M_AMT * U.CCY_RATE --借方月发生额
                        WHEN B.DATA_TYPE = 'YCAML' THEN
                         A.CR_Y_AMT * U.CCY_RATE --贷方年发生额
                        WHEN B.DATA_TYPE = 'YDAML' THEN
                         A.DR_Y_AMT * U.CCY_RATE --借方年发生额
                      END AS ITEM_VALUE_CNY, --折人民币
                      CASE
                        WHEN B.DATA_TYPE = 'BAL' THEN
                         A.BAL_G * V.CCY_RATE --余额
                        WHEN B.DATA_TYPE = 'CBAL' THEN
                         A.CR_BAL * V.CCY_RATE --贷方余额
                        WHEN B.DATA_TYPE = 'DBAL' THEN
                         A.DR_BAL * V.CCY_RATE --借方余额
                        WHEN B.DATA_TYPE = 'CAML' THEN
                         A.CR_M_AMT * V.CCY_RATE --贷方月发生额
                        WHEN B.DATA_TYPE = 'DAML' THEN
                         A.DR_M_AMT * V.CCY_RATE --借方月发生额
                        WHEN B.DATA_TYPE = 'YCAML' THEN
                         A.CR_Y_AMT * V.CCY_RATE --贷方年发生额
                        WHEN B.DATA_TYPE = 'YDAML' THEN
                         A.DR_Y_AMT * V.CCY_RATE --借方年发生额
                      END AS ITEM_VALUE_USD --折美元
        FROM PM_RSDATA.CBRC_L_FINA_GL_TMP1 A
       INNER JOIN PM_RSDATA.CBRC_SAP_MAP_INFO_TMP1 B
          ON A.ITEM_CD = B.ACCI_NO --科目号相连
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE V
          ON V.CCY_DATE = I_DATADATE
         AND V.BASIC_CCY = CURR_CD --基准币种
         AND V.FORWARD_CCY = 'USD' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND CASE
               WHEN B.DATA_TYPE = 'BAL' THEN
                A.BAL_G --余额
               WHEN B.DATA_TYPE = 'CBAL' THEN
                A.CR_BAL --贷方余额
               WHEN B.DATA_TYPE = 'DBAL' THEN
                A.DR_BAL --借方余额
               WHEN B.DATA_TYPE = 'CAML' THEN
                A.CR_M_AMT --贷方月发生额
               WHEN B.DATA_TYPE = 'DAML' THEN
                A.DR_M_AMT --借方月发生额
               WHEN B.DATA_TYPE = 'YCAML' THEN
                A.CR_Y_AMT --贷方年发生额
               WHEN B.DATA_TYPE = 'YDAML' THEN
                A.DR_Y_AMT --借方年发生额
             END <> 0; --去掉为零的数据;
             COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);  

   V_STEP_ID   := 4;
    V_STEP_DESC := '区分人民币、美元，按产品类别进行匹配';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --人民币取人民币，外币折美元。无需产品号匹配
    INSERT INTO PM_RSDATA.CBRC_L_FINA_GL_TMP3
      (ACCTOUNT_DT, --会计日期
       ORG_NUM, --机构号
       DPV_ID, --指标号
       CURR_CD, --记账币种
       B_CURR_CD, --原始币种
       DR_FLAG, --轧差组别号
       POS_FLAG, --轧差组内运算要求：Y表示结果要>0，N表示结果要<0，-表示对结果正负没限制
       IS_DEL, --加减法运算标识： Y => 做减法; N => 做加法; - => 不做限制
       BALANCE --额度
       )
      SELECT DISTINCT A.ACCTOUNT_DT, --会计日期
                      A.ORG_NUM, --机构号
                      B.DPV_ID, --总账指标号
                      A.ORIG_CURR_CD AS CURR_CD, --原始币种
                      CASE
                        WHEN A.ORIG_CURR_CD = 'CNY' THEN
                         'CNY'
                        WHEN A.ORIG_CURR_CD <> 'CNY' THEN
                         'USD'
                        ELSE
                         'OTH'
                      END AS B_CURR_CD, --用原始币种生成报表上要求的币种，源币种是人民币的取人民币，非人民币的折成美元
                      B.DR_FLAG, --轧差组别号
                      B.POS_FLAG, --轧差组内运算要求：Y表示结果要>0，N表示结果要<0，-表示对结果正负没限制
                      B.IS_DEL, --加减法运算标识： Y => 做减法; N => 做加法; - => 不做限制
                      B.IS_DEL --正负号标识
                      * SUM(CASE
                              WHEN A.ORIG_CURR_CD = 'CNY' THEN
                               A.ITEM_VALUE_CNY --出人民币报表数据
                              WHEN A.ORIG_CURR_CD <> 'CNY' THEN
                               A.ITEM_VALUE_USD --出美元报表数据（A2开头的人行表）
                              ELSE
                               0
                            END) BALANCE --额度
        FROM PM_RSDATA.CBRC_L_FINA_GL_TMP2 A
       INNER JOIN PM_RSDATA.CBRC_SAP_MAP_INFO_TMP2 B
          ON A.DATA_TYPE = B.DATA_TYPE --数据类型
         AND A.ITEM_CD LIKE B.ACCI_NO --总账会计科目编号
         AND B.PROD_ID = '0000' --产品代码
       GROUP BY A.ACCTOUNT_DT, --会计日期
                A.ORG_NUM, --机构号
                B.DPV_ID, --指标号
                A.ORIG_CURR_CD, --记账币种
                B.DR_FLAG, --轧差组别号
                B.POS_FLAG, --轧差组别号
                B.IS_DEL; --正负号标识

    --人民币取人民币，外币折美元。需产品号匹配
    INSERT INTO PM_RSDATA.CBRC_L_FINA_GL_TMP3
      (ACCTOUNT_DT, --会计日期
       ORG_NUM, --机构号
       DPV_ID, --指标号
       CURR_CD, --记账币种
       B_CURR_CD, --原始币种
       DR_FLAG, --轧差组别号
       POS_FLAG, --轧差组内运算要求：Y表示结果要>0，N表示结果要<0，-表示对结果正负没限制
       IS_DEL, --加减法运算标识： Y => 做减法; N => 做加法; - => 不做限制
       BALANCE --额度
       )
      SELECT DISTINCT A.ACCTOUNT_DT, --会计日期
                      A.ORG_NUM, --机构号
                      B.DPV_ID, --指标号
                      A.ORIG_CURR_CD AS CURR_CD, --原始币种
                      CASE
                        WHEN A.ORIG_CURR_CD = 'CNY' THEN
                         'CNY'
                        WHEN A.ORIG_CURR_CD <> 'CNY' THEN
                         'USD'
                        ELSE
                         'OTH' --当原始币种为空的情况，上述两个条件的判断均为FALSE
                      END AS B_CURR_CD, --用原始币种 生成报表上要求的币种，源币种是人民币的取人民币，非人民币的折成美元
                      B.DR_FLAG, --轧差组别号
                      B.POS_FLAG, --轧差组内运算要求：Y表示结果要>0，N表示结果要<0，-表示对结果正负没限制
                      B.IS_DEL, --加减法运算标识： Y => 做减法; N => 做加法; - => 不做限制
                      B.IS_DEL * --正负号标识
                      SUM(CASE
                            WHEN A.ORIG_CURR_CD = 'CNY' THEN
                             A.ITEM_VALUE_CNY --出人民币报表数据
                            WHEN A.ORIG_CURR_CD <> 'CNY' THEN
                             A.ITEM_VALUE_USD --出美元报表数据
                            ELSE
                             0
                          END) BALANCE --用原始币种 生成报表上要求的币种
        FROM PM_RSDATA.CBRC_L_FINA_GL_TMP2 A
       INNER JOIN PM_RSDATA.CBRC_SAP_MAP_INFO_TMP2 B
          ON A.DATA_TYPE = B.DATA_TYPE --数据类型
         AND A.ITEM_CD LIKE B.ACCI_NO --总账会计科目编号
         AND DECODE(A.PRODUCT_CD, '0000', '1', A.PRODUCT_CD) LIKE --产品号相连，需要产品号匹配
             CASE
               WHEN SUBSTR(B.PROD_ID, -1, 1) <> '%' THEN
                B.PROD_ID
               ELSE
                SUBSTR(B.PROD_ID, 1, INSTR(B.PROD_ID, '%', 1) - 1) || '%'
             END
         AND B.PROD_ID <> '0000'
       GROUP BY A.ACCTOUNT_DT,
                A.ORG_NUM,
                B.DPV_ID,
                A.ORIG_CURR_CD,
                B.DR_FLAG, --轧差组别号
                B.POS_FLAG,
                B.IS_DEL; --正负号标识
    --做外币折人民币的计算,无需产品号匹配
    INSERT INTO PM_RSDATA.CBRC_L_FINA_GL_TMP3
      (ACCTOUNT_DT, --会计日期
       ORG_NUM, --机构号
       DPV_ID, --指标号
       CURR_CD, --记账币种
       B_CURR_CD, --原始币种
       DR_FLAG, --轧差组别号
       POS_FLAG, --轧差组内运算要求：Y表示结果要>0，N表示结果要<0，-表示对结果正负没限制
       IS_DEL, --加减法运算标识： Y => 做减法; N => 做加法; - => 不做限制
       BALANCE --额度
       )
      SELECT DISTINCT A.ACCTOUNT_DT, --会计日期
                      A.ORG_NUM, --机构号
                      B.DPV_ID, --指标号
                      A.ORIG_CURR_CD AS CURR_CD, --原始币种
                      'FCY' AS B_CURR_CD, --生成报表币种，源币种非人民币的折成人民币
                      B.DR_FLAG, --轧差组别号
                      B.POS_FLAG, --轧差组内运算要求：Y表示结果要>0，N表示结果要<0，-表示对结果正负没限制
                      B.IS_DEL, --加减法运算标识： Y => 做减法; N => 做加法; - => 不做限制
                      B.IS_DEL * SUM(A.ITEM_VALUE_CNY) BALANCE --正负号标识 * 额度
        FROM PM_RSDATA.CBRC_L_FINA_GL_TMP2 A
       INNER JOIN PM_RSDATA.CBRC_SAP_MAP_INFO_TMP2 B
          ON A.DATA_TYPE = B.DATA_TYPE
         AND B.PROD_ID = '0000'
       WHERE A.ITEM_CD LIKE B.ACCI_NO --科目号相连
         AND A.ORIG_CURR_CD <> 'CNY' --对原始币种不为人民币的进行折人民币计算
       GROUP BY A.ACCTOUNT_DT,
                A.ORG_NUM,
                B.DPV_ID,
                A.ORIG_CURR_CD,
                B.DR_FLAG, --轧差组别号
                B.POS_FLAG,
                B.IS_DEL; --正负号标识
    --做外币折人民币的计算,需产品号匹配
    INSERT INTO PM_RSDATA.CBRC_L_FINA_GL_TMP3
      (ACCTOUNT_DT, --会计日期
       ORG_NUM, --机构号
       DPV_ID, --指标号
       CURR_CD, --记账币种
       B_CURR_CD, --原始币种
       DR_FLAG, --轧差组别号
       POS_FLAG, --轧差组内运算要求：Y表示结果要>0，N表示结果要<0，-表示对结果正负没限制
       IS_DEL, --加减法运算标识： Y => 做减法; N => 做加法; - => 不做限制
       BALANCE --额度
       )
      SELECT DISTINCT A.ACCTOUNT_DT, --会计日期
                      A.ORG_NUM, --机构号
                      B.DPV_ID, --指标号
                      A.ORIG_CURR_CD AS CURR_CD, --原始币种
                      'FCY' AS B_CURR_CD, --生成报表币种，源币种非人民币的折成人民币
                      DR_FLAG, --轧差组别号
                      B.POS_FLAG, --轧差组内运算要求：Y表示结果要>0，N表示结果要<0，-表示对结果正负没限制
                      B.IS_DEL, --加减法运算标识： Y => 做减法; N => 做加法; - => 不做限制
                      B.IS_DEL * SUM(A.ITEM_VALUE_CNY) BALANCE --正负号标识 * 额度
        FROM PM_RSDATA.CBRC_L_FINA_GL_TMP2 A
       INNER JOIN PM_RSDATA.CBRC_SAP_MAP_INFO_TMP2 B
          ON A.DATA_TYPE = B.DATA_TYPE
         AND A.ITEM_CD LIKE B.ACCI_NO
         AND DECODE(A.PRODUCT_CD, '0000', '1', A.PRODUCT_CD) LIKE CASE
               WHEN SUBSTR(B.PROD_ID, -1, 1) <> '%' THEN
                B.PROD_ID
               ELSE
                SUBSTR(B.PROD_ID, 1, INSTR(B.PROD_ID, '%', 1) - 1) || '%'
             END --产品号相连
         AND B.PROD_ID <> '0000'
       WHERE A.ORIG_CURR_CD <> 'CNY' --对原始币种不为人民币的进行折人民币计算
       GROUP BY A.ACCTOUNT_DT,
                A.ORG_NUM,
                B.DPV_ID,
                A.ORIG_CURR_CD,
                B.DR_FLAG, --轧差组别号
                B.POS_FLAG,
                B.IS_DEL; --正负号标识
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    
    V_STEP_ID   := 6;
    V_STEP_DESC := '区分人民币、美元，按产品类别进行匹配';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO PM_RSDATA.CBRC_L_FINA_GL_TMP4
      (ACCTOUNT_DT,
       ORG_NUM,
       DPV_ID,
       CURR_CD,
       B_CURR_CD,
       DR_FLAG, --轧差组别号
       POS_FLAG,
       BALANCE --
       )
      SELECT ACCTOUNT_DT,
             ORG_NUM,
             DPV_ID,
             CURR_CD,
             B_CURR_CD, --
             DR_FLAG, --轧差组别号
             POS_FLAG, --轧差组内运算要求：Y表示结果要>0，N表示结果要<0，-表示对结果正负没限制
             CASE
               WHEN POS_FLAG = 'Y' THEN
                DECODE(SIGN(SUM(BALANCE)), 1, SUM(BALANCE), 0)
               WHEN POS_FLAG = 'N' THEN
                DECODE(SIGN(SUM(BALANCE)), -1, -SUM(BALANCE), 0) --判断完，结果取正数
               ELSE
                SUM(BALANCE)
             END BALANCE --判断是否有>0的条件，轧差组内运算要求：Y表示结果要>0，N表示结果要<0，-表示对结果正负没限制
        FROM ( --本外币合计
              SELECT ACCTOUNT_DT,
                      ORG_NUM,
                      DPV_ID,
                      '-' AS CURR_CD,
                      'ALL' AS B_CURR_CD,
                      DR_FLAG,
                      POS_FLAG,
                      SUM(BALANCE) BALANCE
                FROM PM_RSDATA.CBRC_L_FINA_GL_TMP3
               WHERE B_CURR_CD IN ('CNY', 'FCY')
               GROUP BY ACCTOUNT_DT,
                         ORG_NUM,
                         DPV_ID,
                         CURR_CD,
                         DR_FLAG,
                         POS_FLAG
              UNION ALL
              --人民币、外币折人民币、外币折美元
              SELECT ACCTOUNT_DT,
                      ORG_NUM,
                      DPV_ID,
                      '-' AS CURR_CD,
                      B_CURR_CD, --报表要求的币种
                      DR_FLAG,
                      POS_FLAG,
                      BALANCE
                FROM PM_RSDATA.CBRC_L_FINA_GL_TMP3
              UNION ALL
              --G32 G33_2 币种取原币币种
              SELECT ACCTOUNT_DT,
                      ORG_NUM,
                      DPV_ID,
                      CURR_CD, --原币币种
                      'S' AS B_CURR_CD, --对需要分币种的报表数据进行特殊标记
                      DR_FLAG,
                      POS_FLAG,
                      BALANCE
                FROM PM_RSDATA.CBRC_L_FINA_GL_TMP3 T
               WHERE B_CURR_CD IN ('CNY', 'FCY') --取人民币和折人民币的值 G33要报人民币
                 AND EXISTS
               (SELECT 1
                        FROM PM_RSDATA.CBRC_ZH_ITEM_REPORT_RELATION --------------从旧模型迁移过来（数据从标版中获取）
                       WHERE SUBSTR(REPORT_ID, 1, 3) IN ('G32', 'G33')
                         AND ITEM_ID = T.DPV_ID))
       GROUP BY ACCTOUNT_DT,
                ORG_NUM,
                DPV_ID,
                CURR_CD,
                B_CURR_CD,
                DR_FLAG, --轧差组别号
                POS_FLAG;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 7;
    V_STEP_DESC := '汇总所有的报送需要的科目结果到表A_REPT_ITEM_VAL_TMP';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --大集中  针对人民币和外币折美元
    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL_TMP
      (ORG_NUM, --机构号
       SYS_NAM, --模块简称
       ITEM_CD, --科目编号
       INDEX_NAM, --指标名称
       B_CURR_CD, --报表要求的币种
       REPORT_NAM, --报表名称
       INDEX_VAL --指标值
       )
      SELECT T.ORG_NUM, --机构号
             'PBOC', --模块简称
             M.ACT_ITEM_CODE, --科目编号
             M.EXT_CONDITION, --指标名称
             T.B_CURR_CD, --报表要求的币种
             M.CONSTANT, --表名
             SUM(T.BALANCE) --余额或折币后的余额
        FROM PM_RSDATA.CBRC_ZH_ITEM_FORMULA M
       INNER JOIN PM_RSDATA.CBRC_L_FINA_GL_TMP4 T
          ON M.ITEM_ID = T.DPV_ID
         AND DECODE(SUBSTR(M.CONSTANT, 1, 2), 'A2', 'USD', 'CNY') =
             T.B_CURR_CD --A2 开头的表报外币折美元，剩下的报人民币
       INNER JOIN PM_RSDATA.CBRC_ZH_ITEM_REPORT_RELATION R
          ON M.ITEM_ID = R.ITEM_ID
         AND M.CONSTANT = R.REPORT_ID
       WHERE M.CONSTANT LIKE 'A%'
         AND M.CONSTANT NOT IN ('A3101_1', 'A3301_1', 'A3414_1', 'A3304_1')
       GROUP BY T.ORG_NUM, --机构号
                M.ACT_ITEM_CODE, --科目号
                M.EXT_CONDITION, --指标名称
                T.B_CURR_CD, --报送币种
                M.CONSTANT; --表名
                commit;
    V_STEP_ID   := 8;
    V_STEP_DESC := '汇总所有的报送需要的科目结果到表A_REPT_ITEM_VAL_TMP';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --非单一币种的大集中报表
    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL_TMP
      (ORG_NUM, --机构号
       SYS_NAM, --模块简称
       ITEM_CD, --科目编号
       INDEX_NAM, --指标名称
       B_CURR_CD, --报表要求的币种
       REPORT_NAM, --报表名称
       INDEX_VAL --指标值
       )
      SELECT T.ORG_NUM, --机构号
             'PBOC', --模块简称
             M.ACT_ITEM_CODE, --科目编号
             M.EXT_CONDITION, --指标名称
             T.B_CURR_CD, --报表要求的币种
             M.CONSTANT, --表名
             SUM(T.BALANCE) --余额或折币后的余额
        FROM PM_RSDATA.CBRC_ZH_ITEM_FORMULA M
       INNER JOIN PM_RSDATA.CBRC_L_FINA_GL_TMP4 T
          ON M.ITEM_ID = T.DPV_ID
         AND T.B_CURR_CD = CASE
               WHEN M.ACT_ITEM_CODE LIKE '%A' THEN
                'CNY'
               WHEN M.ACT_ITEM_CODE LIKE '%B' THEN
                'USD'
               WHEN M.ACT_ITEM_CODE LIKE '%C' THEN
                'ALL'
             END
       INNER JOIN PM_RSDATA.CBRC_ZH_ITEM_REPORT_RELATION R
          ON M.ITEM_ID = R.ITEM_ID
         AND M.CONSTANT = R.REPORT_ID
       WHERE M.CONSTANT IN ('A3101_1', 'A3301_1')
       GROUP BY T.ORG_NUM, --机构号
                M.ACT_ITEM_CODE, --科目号
                M.EXT_CONDITION, --指标名称
                T.B_CURR_CD, --报送币种
                M.CONSTANT; --表名
   commit;
    V_STEP_ID   := 9;
    V_STEP_DESC := '汇总所有的报送需要的科目结果到表A_REPT_ITEM_VAL_TMP';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --非单一币种的大集中报表A3414_1、A3304_1
    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL_TMP
      (ORG_NUM, --机构号
       SYS_NAM, --模块简称
       ITEM_CD, --科目编号
       INDEX_NAM, --指标名称
       B_CURR_CD, --报表要求的币种
       REPORT_NAM, --报表名称
       INDEX_VAL --指标值
       )
      SELECT T.ORG_NUM, --机构号
             'PBOC', --模块简称
             M.ACT_ITEM_CODE, --科目编号
             M.EXT_CONDITION, --指标名称
             T.B_CURR_CD, --报表要求的币种
             M.CONSTANT, --表名
             SUM(T.BALANCE) --余额或折币后的余额
        FROM PM_RSDATA.CBRC_ZH_ITEM_FORMULA M
       INNER JOIN PM_RSDATA.CBRC_L_FINA_GL_TMP4 T
          ON M.ITEM_ID = T.DPV_ID
         AND T.B_CURR_CD = 'ALL' --去掉不需要的币种，避免垃圾数据
       INNER JOIN PM_RSDATA.CBRC_ZH_ITEM_REPORT_RELATION R
          ON M.ITEM_ID = R.ITEM_ID
         AND M.CONSTANT = R.REPORT_ID
       WHERE M.CONSTANT IN ('A3414_1', 'A3304_1')
         AND R.REPORT_ID IN ('A3414_1', 'A3304_1')
       GROUP BY T.ORG_NUM, --机构号
                M.ACT_ITEM_CODE, --科目号
                M.EXT_CONDITION, --指标名称
                T.B_CURR_CD, --报送币种
                M.CONSTANT; --表名
   commit;
    V_STEP_ID   := 10;
    V_STEP_DESC := '汇总所有的报送需要的科目结果到表A_REPT_ITEM_VAL_TMP';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --1104 分币种，人民币，外币折人民币，本外币合计 (表样呈三列结构)
    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL_TMP
      (ORG_NUM, --机构号
       SYS_NAM, --模块简称
       ITEM_CD, --科目编号
       INDEX_NAM, --指标名称
       B_CURR_CD, --报表要求的币种
       REPORT_NAM, --报表名称
       INDEX_VAL --指标值
       )
      SELECT T.ORG_NUM, --机构号
             'CBRC', --模块简称
             M.ACT_ITEM_CODE, --科目编号
             M.EXT_CONDITION, --指标名称
             T.B_CURR_CD, --报表要求的币种
             M.CONSTANT, --表名
             SUM(T.BALANCE) --余额或折币后的余额
        FROM PM_RSDATA.CBRC_ZH_ITEM_FORMULA M
       INNER JOIN PM_RSDATA.CBRC_L_FINA_GL_TMP4 T
          ON M.ITEM_ID = T.DPV_ID
         AND CASE
               WHEN M.CONSTANT IN
                    ('G01_1', 'G01_2', 'G01_6', 'GF01_1', 'GF01_2', 'GF01_6') THEN
                'ALL'
               WHEN M.ACT_ITEM_CODE LIKE '%A%' THEN
                'CNY'
               WHEN M.ACT_ITEM_CODE LIKE '%B%' THEN
                'FCY'
               WHEN M.ACT_ITEM_CODE LIKE '%C%' THEN
                'ALL'
             END = T.B_CURR_CD
       INNER JOIN PM_RSDATA.CBRC_ZH_ITEM_REPORT_RELATION R
          ON M.ITEM_ID = R.ITEM_ID
         AND M.CONSTANT = R.REPORT_ID
       WHERE M.CONSTANT IN ('G01',
                            'G01_1',
                            'G01_2',
                            'G01_3',
                            'G01_5',
                            'G01_6',
                            'G01_9',
                            'G22', --法人报表
                            'G22R',
                            'GF01',
                            'GF01_1',
                            'GF01_2',
                            'GF01_3',
                            'GF01_5',
                            'GF01_6',
                            'GF01_9') --分支报表
       GROUP BY T.ORG_NUM, --机构号
                M.ACT_ITEM_CODE, --科目号
                M.EXT_CONDITION, --指标名称
                T.B_CURR_CD, --报送币种
                M.CONSTANT; --表名
   commit;
    V_STEP_ID   := 11;
    V_STEP_DESC := '汇总所有的报送需要的科目结果到表A_REPT_ITEM_VAL_TMP';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --1104 不分币种
    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL_TMP
      (ORG_NUM, --机构号
       SYS_NAM, --模块简称
       ITEM_CD, --科目编号
       INDEX_NAM, --指标名称
       B_CURR_CD, --报表要求的币种
       REPORT_NAM, --报表名称
       INDEX_VAL --指标值
       )
      SELECT T.ORG_NUM, --机构号
             'CBRC', --模块简称
             M.ACT_ITEM_CODE, --科目编号
             M.EXT_CONDITION, --指标名称
             T.B_CURR_CD, --报表要求的币种
             M.CONSTANT, --表名
             SUM(T.BALANCE) --余额或折币后的余额
        FROM PM_RSDATA.CBRC_ZH_ITEM_FORMULA M
       INNER JOIN PM_RSDATA.CBRC_L_FINA_GL_TMP4 T
          ON M.ITEM_ID = T.DPV_ID
         AND T.B_CURR_CD = 'ALL' --取本外币合计的数据,过滤掉垃圾数据
       INNER JOIN PM_RSDATA.CBRC_ZH_ITEM_REPORT_RELATION R
          ON M.ITEM_ID = R.ITEM_ID
         AND M.CONSTANT = R.REPORT_ID
       WHERE M.CONSTANT NOT IN ('G01',
                                'G01_1',
                                'G01_2',
                                'G01_3',
                                'G01_5',
                                'G01_6',
                                'G01_9',
                                'G22', --法人报表 三列结构
                                'G22R',
                                'GF01',
                                'GF01_1',
                                'GF01_2',
                                'GF01_3',
                                'GF01_5',
                                'GF01_6',
                                'GF01_9', --分支报表 三列结构
                                'G32',
                                'G33_1',
                                'G33_2') --需要特殊处理的表
         AND M.CONSTANT LIKE 'G%'
         AND SUBSTR(M.CONSTANT, 1, 3) NOT IN ('G4A', 'G4B', 'G4C', 'G4D')
       GROUP BY T.ORG_NUM, --机构号
                M.ACT_ITEM_CODE, --科目号
                M.EXT_CONDITION, --指标名称
                T.B_CURR_CD, --报送币种
                M.CONSTANT; --表名
   commit;
    V_STEP_ID   := 12;
    V_STEP_DESC := '汇总所有的报送需要的科目结果到表A_REPT_ITEM_VAL_TMP';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --G32分币种
    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL_TMP
      (ORG_NUM, --机构号
       SYS_NAM, --模块简称
       ITEM_CD, --科目编号
       INDEX_NAM, --指标名称
       B_CURR_CD, --报表要求的币种
       REPORT_NAM, --报表名称
       INDEX_VAL --指标值
       )
      SELECT T.ORG_NUM, --机构号
             'CBRC', --模块简称
             M.ACT_ITEM_CODE, --科目编号
             M.EXT_CONDITION, --指标名称
             T.B_CURR_CD, --报表要求的币种
             M.CONSTANT, --表名
             SUM(T.BALANCE) --余额或折币后的余额
        FROM PM_RSDATA.CBRC_ZH_ITEM_FORMULA M
       INNER JOIN PM_RSDATA.CBRC_L_FINA_GL_TMP4 T
          ON M.ITEM_ID = T.DPV_ID
         AND T.B_CURR_CD = 'S' --取针对G32的数据
       INNER JOIN PM_RSDATA.CBRC_ZH_ITEM_REPORT_RELATION R
          ON M.ITEM_ID = R.ITEM_ID
         AND M.CONSTANT = R.REPORT_ID
       WHERE M.CONSTANT LIKE 'G32%'
         AND M.EXT_CONDITION LIKE '%' || T.CURR_CD || '%' --只取对应币种的数据
       GROUP BY T.ORG_NUM, --机构号
                M.ACT_ITEM_CODE, --科目号
                M.EXT_CONDITION, --指标名称
                T.B_CURR_CD, --报送币种
                M.CONSTANT; --表名
   commit;
    V_STEP_ID   := 13;
    V_STEP_DESC := '汇总所有的报送需要的科目结果到表A_REPT_ITEM_VAL_TMP';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --G32   币种不在以上所列之中的，放在其他里，余额大于零放多头
    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL_TMP
      (ORG_NUM, --机构号
       SYS_NAM, --模块简称
       ITEM_CD, --科目编号
       INDEX_NAM, --指标名称
       B_CURR_CD, --报表要求的币种
       REPORT_NAM, --报表名称
       INDEX_VAL --指标值
       )
      SELECT T.ORG_NUM, --机构号
             'CBRC', --模块简称
             M.ACT_ITEM_CODE, --科目编号
             M.EXT_CONDITION, --指标名称
             T.B_CURR_CD, --报表要求的币种
             M.CONSTANT, --表名
             CASE
               WHEN SUM(T.BALANCE) > 0 THEN
                SUM(T.BALANCE)
               ELSE
                0
             END --余额或折币后的余额
        FROM PM_RSDATA.CBRC_ZH_ITEM_FORMULA M
       INNER JOIN PM_RSDATA.CBRC_L_FINA_GL_TMP4 T
          ON M.ITEM_ID = T.DPV_ID
         AND T.CURR_CD NOT IN
             ('USD', 'EUR', 'JPY', 'GBP', 'HKD', 'CHF', 'AUD', 'CAD', 'CNY') --不包括上述外币和人民币
         AND T.B_CURR_CD = 'S' --取针对G32的数据
       INNER JOIN PM_RSDATA.CBRC_ZH_ITEM_REPORT_RELATION R
          ON M.ITEM_ID = R.ITEM_ID
         AND M.CONSTANT = R.REPORT_ID
       WHERE M.CONSTANT LIKE 'G32%'
         AND M.EXT_CONDITION LIKE '%多%' --计算多头
       GROUP BY T.ORG_NUM, --机构号
                M.ACT_ITEM_CODE, --科目号
                M.EXT_CONDITION, --指标名称
                T.B_CURR_CD, --报送币种
                M.CONSTANT; --表名
   commit;
    V_STEP_ID   := 14;
    V_STEP_DESC := '汇总所有的报送需要的科目结果到表A_REPT_ITEM_VAL_TMP';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --G32 币种不在以上所列之中的，放在其他里，余额大于零放空头
    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL_TMP
      (ORG_NUM, --机构号
       SYS_NAM, --模块简称
       ITEM_CD, --科目编号
       INDEX_NAM, --指标名称
       B_CURR_CD, --报表要求的币种
       REPORT_NAM, --报表名称
       INDEX_VAL --指标值
       )
      SELECT T.ORG_NUM, --机构号
             'CBRC', --模块简称
             M.ACT_ITEM_CODE, --科目编号
             M.EXT_CONDITION, --指标名称
             T.B_CURR_CD, --报表要求的币种
             M.CONSTANT, --表名
             CASE
               WHEN SUM(T.BALANCE) <= 0 THEN
                SUM(T.BALANCE)
               ELSE
                0
             END --余额或折币后的余额
        FROM PM_RSDATA.CBRC_ZH_ITEM_FORMULA M
       INNER JOIN PM_RSDATA.CBRC_L_FINA_GL_TMP4 T
          ON M.ITEM_ID = T.DPV_ID
         AND T.CURR_CD NOT IN
             ('USD', 'EUR', 'JPY', 'GBP', 'HKD', 'CHF', 'AUD', 'CAD', 'CNY') --不包括上述外币和人民币
         AND T.B_CURR_CD = 'S' --取针对G32的数据
       INNER JOIN PM_RSDATA.CBRC_ZH_ITEM_REPORT_RELATION R
          ON M.ITEM_ID = R.ITEM_ID
         AND M.CONSTANT = R.REPORT_ID
       WHERE M.CONSTANT LIKE 'G32%'
         AND M.EXT_CONDITION LIKE '%空%' --计算空头
       GROUP BY T.ORG_NUM, --机构号
                M.ACT_ITEM_CODE, --科目号
                M.EXT_CONDITION, --指标名称
                T.B_CURR_CD, --报送币种
                M.CONSTANT; --表名
   commit;
    V_STEP_ID   := 15;
    V_STEP_DESC := '汇总所有的报送需要的科目结果到表A_REPT_ITEM_VAL_TMP';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --ALTER BY WJB 20220622 G32特殊处理 将总行机构的指标值赋给0198bb国际业务部 各分支行数据由国际业务部统一负责报送

    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL_TMP
      (ORG_NUM, --机构号
       SYS_NAM, --模块简称
       ITEM_CD, --科目编号
       INDEX_NAM, --指标名称
       B_CURR_CD, --报表要求的币种
       REPORT_NAM, --报表名称
       INDEX_VAL --指标值
       )
      SELECT '0198bb' AS ORG_NUM, --机构号
             'CBRC', --模块简称
             T.ITEM_CD, --科目编号
             T.INDEX_NAM, --指标名称
             T.B_CURR_CD, --报表要求的币种
             T.REPORT_NAM, --表名
             T.INDEX_VAL --余额或折币后的余额
        FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL_TMP T
       WHERE T.REPORT_NAM = 'G32'
         AND T.ORG_NUM = '990000'
         AND T.ITEM_CD NOT LIKE '%G32_9.%';
    COMMIT;
    V_STEP_ID   := 16;
    V_STEP_DESC := '汇总所有的报送需要的科目结果到表A_REPT_ITEM_VAL_TMP';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --G33分币种
    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL_TMP
      (ORG_NUM, --机构号
       SYS_NAM, --模块简称
       ITEM_CD, --科目编号
       INDEX_NAM, --指标名称
       B_CURR_CD, --报表要求的币种
       REPORT_NAM, --报表名称
       INDEX_VAL --指标值
       )
      SELECT T.ORG_NUM, --机构号
             'CBRC', --模块简称
             M.ACT_ITEM_CODE, --科目编号
             M.EXT_CONDITION, --指标名称
             T.B_CURR_CD, --报表要求的币种
             M.CONSTANT, --表名
             SUM(T.BALANCE) --余额或折币后的余额
        FROM PM_RSDATA.CBRC_ZH_ITEM_FORMULA M
       INNER JOIN PM_RSDATA.CBRC_L_FINA_GL_TMP4 T
          ON M.ITEM_ID = T.DPV_ID
      --   AND T.B_CURR_CD = 'S' --取针对G33的数据 --20170613 manan 修改，需要多币种数据
       INNER JOIN PM_RSDATA.CBRC_ZH_ITEM_REPORT_RELATION R
          ON M.ITEM_ID = R.ITEM_ID
         AND M.CONSTANT = R.REPORT_ID
       WHERE M.CONSTANT LIKE 'G33%'
       GROUP BY T.ORG_NUM, --机构号
                M.ACT_ITEM_CODE, --科目号
                M.EXT_CONDITION, --指标名称
                T.B_CURR_CD, --报送币种
                M.CONSTANT; --表名
   commit;
    V_STEP_ID   := 17;
    V_STEP_DESC := '汇总所有的报送需要的科目结果到表A_REPT_ITEM_VAL_TMP';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --增加CAR总账指标逻辑
    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL_TMP
      (ORG_NUM, --机构号
       SYS_NAM, --模块简称
       ITEM_CD, --科目编号
       INDEX_NAM, --指标名称
       B_CURR_CD, --报表要求的币种
       REPORT_NAM, --报表名称
       INDEX_VAL --指标值
       )
      SELECT T.ORG_NUM, --机构号
             'CAR', --模块简称
             M.ACT_ITEM_CODE, --科目编号
             M.EXT_CONDITION, --指标名称
             T.B_CURR_CD, --报表要求的币种
             M.CONSTANT, --表名
             SUM(T.BALANCE) --余额或折币后的余额
        FROM PM_RSDATA.CBRC_ZH_ITEM_FORMULA M
       INNER JOIN PM_RSDATA.CBRC_L_FINA_GL_TMP4 T
          ON M.ITEM_ID = T.DPV_ID
         AND T.B_CURR_CD = 'ALL' --取本外币合计的数据,过滤掉垃圾数据
       INNER JOIN PM_RSDATA.CBRC_ZH_ITEM_REPORT_RELATION R
          ON M.ITEM_ID = R.ITEM_ID
         AND M.CONSTANT = R.REPORT_ID
       WHERE SUBSTR(M.CONSTANT, 1, 3) IN ('G4A', 'G4B', 'G4C', 'G4D')
       GROUP BY T.ORG_NUM, --机构号
                M.ACT_ITEM_CODE, --科目号
                M.EXT_CONDITION, --指标名称
                T.B_CURR_CD, --报送币种
                M.CONSTANT; --表名
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 18;
    V_STEP_DESC := '将表A_REPT_ITEM_VAL_TMP中的数据与报送指标配置表关联后，写入指标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
  (DATA_DATE, --数据日期
   ORG_NUM, --机构号
   SYS_NAM, --模块简称
   REP_NUM, --报表编号
   ITEM_NUM, --指标号
   B_CURR_CD, --报表要求的币种
   ITEM_VAL, --指标值(数值型)
   FLAG, --标志位
   IS_TOTAL)
  SELECT I_DATADATE, --数据日期
         A.ORG_NUM, --机构号
         --A.SYS_NAM, --模块简称
         B.SYS_NAM, --模块简称    --shiwenbo by 20170407-sysnam 修改模块简称判断，因为CAR为3位，模块简称为4位char型
         A.REPORT_NAM, --报表编号
         A.ITEM_CD, --指标号
         A.B_CURR_CD, --报表要求的币种
         A.INDEX_VAL, --指标值(数值型)
         B.CONF_FLG, --标志位：1-总账、2-明细、3-归并、9-个性化
         CASE
           WHEN A.ITEM_CD IN ('G01_47..B',
                              'G01_47..A',
                              'G01_23..B',
                              'G01_23..A',
                              'G01_23..C',
                              'G01_1.3.A.091231',
                              'G01_1.4.A.091231',
                              'G01_1_2.3.A',
                              'G01_I_1.1..A.2016',
                              'G01_I_1.3.2.A.2016') THEN
            'N'
         END AS IS_TOTAL
    FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL_TMP A
   INNER JOIN CBRC_A_REPT_ITEM_CONF B
      ON --A.SYS_NAM = B.SYS_NAM
   TRIM(A.SYS_NAM) = B.SYS_NAM --模块简称  --shiwenbo by 20170407-sysnam 修改模块简称判断，因为CAR为3位，模块简称为4位char型
   AND A.ITEM_CD = B.ITEM_NUM --统计科目编号
   AND B.USE_FLG = 'Y' --是否启用
   AND B.CONF_FLG = '1'; --从总账出数

    COMMIT;


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
   
END proc_cbrc_l_fina_gl