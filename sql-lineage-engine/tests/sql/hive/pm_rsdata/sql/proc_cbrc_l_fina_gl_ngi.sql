CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_l_fina_gl_ngi(II_DATADATE IN STRING --跑批日期
                                              )
/******************************
  @author:luoyujie
  @create-date:20211030
  @description:总账的汇总逻辑  此处数据为了出G21 1.10其他没有确定到期日的资产数据，根据大为哥提供口径保持和G01扣减后一致
  @modification history:
  m0.author-create_date-description
  m001.xiangxu-20160407-增加2061制度升级后,非单一币种的大集中报表A3414_1特殊处理
  --    需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-27，修改人：石雨，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
  [JLBA202507210012_关于调整财政性存款及一般性存款相关科目统计方式的相关需求][提出人：于佳禾][上线时间：20250918][修改人：石雨][修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
PM_RSDATA.CBRC_A_REPT_ITEM_CONF
PM_RSDATA.CBRC_A_REPT_ITEM_VAL_NGI
PM_RSDATA.CBRC_A_REPT_ITEM_VAL_TMP_NGI
PM_RSDATA.CBRC_L_FINA_GL_NGI_TMP1
PM_RSDATA.CBRC_L_FINA_GL_TMP1_NGI
PM_RSDATA.CBRC_L_FINA_GL_TMP2_NGI
PM_RSDATA.CBRC_L_FINA_GL_TMP3_NGI
PM_RSDATA.CBRC_L_FINA_GL_TMP4_NGI
PM_RSDATA.CBRC_SAP_MAP_INFO
PM_RSDATA.CBRC_SAP_MAP_INFO_TMP1_NGI
PM_RSDATA.CBRC_SAP_MAP_INFO_TMP2_NGI
PM_RSDATA.CBRC_ZH_ITEM_FORMULA
PM_RSDATA.CBRC_ZH_ITEM_REPORT_RELATION
PM_RSDATA.SMTMODS_L_PUBL_RATE
PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL
  *******************************/
 IS
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE     VARCHAR(30); --当前储存过程名称
  V_TAB_NAME     VARCHAR(30); --目标表名
  I_DATADATE     STRING; --数据日期(数值型)YYYYMMDD
  D_DATADATE     STRING; --数据日期(数据型)YYYYMMDD
  D_DATADATE_CCY STRING; --数据日期(日期型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  D_YEAR0101     VARCHAR(20); --年初数据日期
  I_YEAR0101     VARCHAR(20); --上年初日期
  I_YEARMONTH    VARCHAR(20); --本月日期值，YYYYMM00
  V_ERRORDESC    VARCHAR(280); --错误内容
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM       VARCHAR2(30);
  
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';

    I_DATADATE := II_DATADATE;
    V_SYSTEM   := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_L_FINA_GL_NGI');
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

	
	D_DATADATE     := I_DATADATE;
    D_YEAR0101     := to_char(TRUNC(date(I_DATADATE),'YYYY'),'YYYYMMDD') ;
    I_YEAR0101     := TO_CHAR(D_YEAR0101, 'YYYYMMDD');
    D_DATADATE_CCY := I_DATADATE;
    I_YEARMONTH    := TO_CHAR(TRUNC(TO_NUMBER(I_DATADATE), -2))  ;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '截取表[' || V_TAB_NAME || ']上的分区[P' || I_DATADATE ||
                   ']上的数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    EXECUTE IMMEDIATE ('TRUNCATE TABLE PM_RSDATA.CBRC_L_FINA_GL_TMP1_NGI');
    EXECUTE IMMEDIATE ('TRUNCATE TABLE PM_RSDATA.CBRC_SAP_MAP_INFO_TMP1_NGI');
    EXECUTE IMMEDIATE ('TRUNCATE TABLE PM_RSDATA.CBRC_SAP_MAP_INFO_TMP2_NGI');
    EXECUTE IMMEDIATE ('TRUNCATE TABLE PM_RSDATA.CBRC_L_FINA_GL_TMP2_NGI');
    EXECUTE IMMEDIATE ('TRUNCATE TABLE PM_RSDATA.CBRC_L_FINA_GL_TMP3_NGI');
    EXECUTE IMMEDIATE ('TRUNCATE TABLE PM_RSDATA.CBRC_L_FINA_GL_TMP4_NGI');
    EXECUTE IMMEDIATE ('TRUNCATE TABLE PM_RSDATA.CBRC_A_REPT_ITEM_VAL_TMP_NGI');
    EXECUTE IMMEDIATE ('TRUNCATE TABLE PM_RSDATA.CBRC_L_FINA_GL_TMP1_NGI');
    EXECUTE IMMEDIATE ('TRUNCATE TABLE PM_RSDATA.CBRC_L_FINA_GL_NGI_TMP1'); --ADDED BY ZYH 20211202 优化sql

    DELETE FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL_NGI
     WHERE DATA_DATE = I_DATADATE
       AND FLAG = '1'
       AND REP_NUM = 'G01';
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 2;
    V_STEP_DESC := '按日、月、年汇总借方、贷方余额';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO PM_RSDATA.CBRC_L_FINA_GL_NGI_TMP1
      SELECT DISTINCT B.ACCI_NO
      --FROM DATACORE.PM_RSDATA.CBRC_ZH_ITEM_FORMULA A
        FROM PM_RSDATA.CBRC_ZH_ITEM_FORMULA A
      --LEFT JOIN DATACORE.PM_RSDATA.CBRC_SAP_MAP_INFO B ON A.ITEM_ID = B.DPV_ID
        LEFT JOIN PM_RSDATA.CBRC_SAP_MAP_INFO B
          ON A.ITEM_ID = B.DPV_ID
       WHERE A.CONSTANT = 'G01'
         AND A.ITEM_ID = 'A12100' --其他资产
         AND A.ACT_ITEM_CODE = 'G01_23..A'
         AND B.ACCI_NO NOT IN ('100303',
                              -- '201103', --[JLBA202507210012][石雨][修改内容：201103（财政性存款 ）调整为 一般单位活期存款，原逻辑中剔除]
                               '201104',
                               '201105',
                               '201106', --去掉财政性轧差，在1.9
                               '2005','2008','2009', --ALTER BY 20270527 JLBA202504180011
                               '11010105', --23.4投资同业存单去掉投资同业存单1.8持有同业存单
                               '11010205',
                               '11020105',
                               '11020205',
                               '15010105',
                               '15010305',
                               '15010505',
                               '15030105',
                               '15030305',
                               '15030505',
                               '15030705');
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_L_FINA_GL_TMP1_NGI 
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
      SELECT 
       G.DATA_DATE, --数据日期
       TO_CHAR(G.ACCTOUNT_DT, 'YYYY-MM-DD') AS ACCTOUNT_DT, --会计日期
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
                 WHEN DATA_DATE >= I_YEAR0101 AND DATA_DATE <= I_DATADATE THEN
                  G.CREDIT_Y_AMT
               END),
           0) AS CR_Y_AMT, --贷方年累计发生额
       NVL(SUM(CASE
                 WHEN DATA_DATE >= I_YEAR0101 AND DATA_DATE <= I_DATADATE THEN
                  G.DEBIT_Y_AMT
               END),
           0) AS DR_Y_AMT, --借方年累计发生额
       NVL(SUM(CASE
                 WHEN TO_CHAR(TRUNC(TO_NUMBER(DATA_DATE), -2)) = I_YEARMONTH THEN
                  G.CREDIT_M_AMT
               END),
           0) AS CR_M_AMT, --贷方月累计发生额
       NVL(SUM(CASE
                 WHEN TO_CHAR(TRUNC(TO_NUMBER(DATA_DATE), -2)) = I_YEARMONTH THEN
                  G.DEBIT_M_AMT
               END),
           0) AS DR_M_AMT --借方月累计发生额
        FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL G
       INNER JOIN PM_RSDATA.CBRC_L_FINA_GL_NGI_TMP1 K --alter by zyh 20211202 sql优化
      ON G.ITEM_CD = K.ACCI_NO
       WHERE G.DATA_DATE BETWEEN SUBSTR(I_DATADATE,1,4)||'0101' AND I_DATADATE --记账日在本年
         AND G.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
       GROUP BY DATA_DATE, --数据日期
                ACCTOUNT_DT, --会计日期
                ORG_NUM, --机构号
                ITEM_CD, --科目号
                PRODUCT_CD, --产品代码
                CURR_CD, --记账币种
                ORIG_CURR_CD; --原始币种
                COMMIT;

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

    INSERT INTO PM_RSDATA.CBRC_SAP_MAP_INFO_TMP1_NGI
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
       -- FROM DATACORE.PM_RSDATA.CBRC_SAP_MAP_INFO B
       FROM PM_RSDATA.CBRC_SAP_MAP_INFO B
       WHERE B.DATA_TYPE IN
             ('BAL', 'CBAL', 'DBAL', 'CAML', 'DAML', 'YCAML', 'YDAML');
             COMMIT;

    INSERT INTO PM_RSDATA.CBRC_SAP_MAP_INFO_TMP2_NGI
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
        --FROM DATACORE.PM_RSDATA.CBRC_SAP_MAP_INFO B;
        FROM PM_RSDATA.CBRC_SAP_MAP_INFO B;
COMMIT;

    INSERT INTO PM_RSDATA.CBRC_L_FINA_GL_TMP2_NGI
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
        FROM PM_RSDATA.CBRC_L_FINA_GL_TMP1_NGI A
       INNER JOIN PM_RSDATA.CBRC_SAP_MAP_INFO_TMP1_NGI B 
           ON A.ITEM_CD = B.ACCI_NO --科目号相连
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U ON U.CCY_DATE = D_DATADATE_CCY
                               AND U.BASIC_CCY = CURR_CD --基准币种
                               AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE V ON V.CCY_DATE = D_DATADATE_CCY
                               AND V.BASIC_CCY = CURR_CD --基准币种
                               AND V.FORWARD_CCY = 'USD' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND CASE WHEN B.DATA_TYPE = 'BAL' THEN A.BAL_G --余额
      WHEN B.DATA_TYPE = 'CBAL' THEN A.CR_BAL --贷方余额
      WHEN B.DATA_TYPE = 'DBAL' THEN A.DR_BAL --借方余额
      WHEN B.DATA_TYPE = 'CAML' THEN A.CR_M_AMT --贷方月发生额
      WHEN B.DATA_TYPE = 'DAML' THEN A.DR_M_AMT --借方月发生额
      WHEN B.DATA_TYPE = 'YCAML' THEN A.CR_Y_AMT --贷方年发生额
      WHEN B.DATA_TYPE = 'YDAML' THEN A.DR_Y_AMT --借方年发生额
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
    INSERT INTO PM_RSDATA.CBRC_L_FINA_GL_TMP3_NGI
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
        FROM PM_RSDATA.CBRC_L_FINA_GL_TMP2_NGI A
       INNER JOIN PM_RSDATA.CBRC_SAP_MAP_INFO_TMP2_NGI B ON A.DATA_TYPE = B.DATA_TYPE --数据类型
                                         AND A.ITEM_CD LIKE B.ACCI_NO --总账会计科目编号
                                         AND B.PROD_ID = '0000' --产品代码
       GROUP BY A.ACCTOUNT_DT, --会计日期
                A.ORG_NUM, --机构号
                B.DPV_ID, --指标号
                A.ORIG_CURR_CD, --记账币种
                B.DR_FLAG, --轧差组别号
                B.POS_FLAG, --轧差组别号
                B.IS_DEL; --正负号标识
                COMMIT;

    --人民币取人民币，外币折美元。需产品号匹配
    INSERT INTO PM_RSDATA.CBRC_L_FINA_GL_TMP3_NGI
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
        FROM PM_RSDATA.CBRC_L_FINA_GL_TMP2_NGI A
       INNER JOIN PM_RSDATA.CBRC_SAP_MAP_INFO_TMP2_NGI B ON A.DATA_TYPE = B.DATA_TYPE --数据类型
                                         AND A.ITEM_CD LIKE B.ACCI_NO --总账会计科目编号
                                         AND DECODE(A.PRODUCT_CD,
                                                    '0000',
                                                    '1',
                                                    A.PRODUCT_CD) LIKE --产品号相连，需要产品号匹配
                                             CASE WHEN
       SUBSTR(B.PROD_ID, -1, 1) <> '%' THEN B.PROD_ID ELSE SUBSTR(B.PROD_ID, 1, INSTR(B.PROD_ID, '%', 1) - 1) || '%' END AND B.PROD_ID <> '0000'
       GROUP BY A.ACCTOUNT_DT,
                A.ORG_NUM,
                B.DPV_ID,
                A.ORIG_CURR_CD,
                B.DR_FLAG, --轧差组别号
                B.POS_FLAG,
                B.IS_DEL; --正负号标识
                COMMIT;
    --做外币折人民币的计算,无需产品号匹配
    INSERT INTO PM_RSDATA.CBRC_L_FINA_GL_TMP3_NGI
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
        FROM PM_RSDATA.CBRC_L_FINA_GL_TMP2_NGI A
       INNER JOIN PM_RSDATA.CBRC_SAP_MAP_INFO_TMP2_NGI B ON A.DATA_TYPE = B.DATA_TYPE
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
                COMMIT;
    --做外币折人民币的计算,需产品号匹配
    INSERT INTO PM_RSDATA.CBRC_L_FINA_GL_TMP3_NGI
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
        FROM PM_RSDATA.CBRC_L_FINA_GL_TMP2_NGI A
       INNER JOIN PM_RSDATA.CBRC_SAP_MAP_INFO_TMP2_NGI B ON A.DATA_TYPE = B.DATA_TYPE
                                         AND A.ITEM_CD LIKE B.ACCI_NO
                                         AND DECODE(A.PRODUCT_CD,
                                                    '0000',
                                                    '1',
                                                    A.PRODUCT_CD) LIKE CASE WHEN
       SUBSTR(B.PROD_ID, -1, 1) <> '%' THEN B.PROD_ID ELSE SUBSTR(B.PROD_ID, 1, INSTR(B.PROD_ID, '%', 1) - 1) || '%' END --产品号相连
      AND B.PROD_ID <> '0000'
       WHERE A.ORIG_CURR_CD <> 'CNY' --对原始币种不为人民币的进行折人民币计算
       GROUP BY A.ACCTOUNT_DT,
                A.ORG_NUM,
                B.DPV_ID,
                A.ORIG_CURR_CD,
                B.DR_FLAG, --轧差组别号
                B.POS_FLAG,
                B.IS_DEL; --正负号标识
                COMMIT;
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

    INSERT INTO PM_RSDATA.CBRC_L_FINA_GL_TMP4_NGI
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
                FROM PM_RSDATA.CBRC_L_FINA_GL_TMP3_NGI
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
                FROM PM_RSDATA.CBRC_L_FINA_GL_TMP3_NGI
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
                FROM PM_RSDATA.CBRC_L_FINA_GL_TMP3_NGI T
               WHERE B_CURR_CD IN ('CNY', 'FCY') --取人民币和折人民币的值 G33要报人民币
                 AND EXISTS
               (SELECT 1
                        --FROM DATACORE.ZH_ITEM_REPORT_RELATION --------------从旧模型迁移过来（数据从标版中获取）
                       FROM PM_RSDATA.CBRC_ZH_ITEM_REPORT_RELATION
                       WHERE SUBSTR(REPORT_ID, 1, 3) IN ('G32', 'G33')
                         AND ITEM_ID = T.DPV_ID))
       GROUP BY ACCTOUNT_DT,
                ORG_NUM,
                DPV_ID,
                CURR_CD,
                B_CURR_CD,
                DR_FLAG, --轧差组别号
                POS_FLAG;
                COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 7;
    V_STEP_DESC := '汇总所有的报送需要的科目结果到表A_REPT_ITEM_VAL_TMP_NGI';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --1104 分币种，人民币，外币折人民币，本外币合计 (表样呈三列结构)
    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL_TMP_NGI
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
        --FROM DATACORE.PM_RSDATA.CBRC_ZH_ITEM_FORMULA M
        FROM PM_RSDATA.CBRC_ZH_ITEM_FORMULA M
       INNER JOIN PM_RSDATA.CBRC_L_FINA_GL_TMP4_NGI T ON M.ITEM_ID = T.DPV_ID
                                      AND CASE WHEN
       M.CONSTANT IN
                                          ('G01_1', 'G01_2', 'G01_6',
                                           'GF01_1', 'GF01_2', 'GF01_6') THEN 'ALL' WHEN M.ACT_ITEM_CODE LIKE '%A%' THEN 'CNY' WHEN M.ACT_ITEM_CODE LIKE '%B%' THEN 'FCY' WHEN M.ACT_ITEM_CODE LIKE '%C%' THEN 'ALL' END = T.B_CURR_CD
       --INNER JOIN DATACORE.ZH_ITEM_REPORT_RELATION R ON M.ITEM_ID =
       INNER JOIN PM_RSDATA.CBRC_ZH_ITEM_REPORT_RELATION R ON M.ITEM_ID =R.ITEM_ID
                                                    AND M.CONSTANT =R.REPORT_ID

       WHERE M.CONSTANT = 'G01'
         AND M.ITEM_ID = 'A12100' --其他资产
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

    V_STEP_ID   := 8;
    V_STEP_DESC := '将表A_REPT_ITEM_VAL_TMP_NGI中的数据与报送指标配置表关联后，写入指标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL_NGI
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       B_CURR_CD, --报表要求的币种
       ITEM_VAL, --指标值(数值型)
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             --A.SYS_NAM, --模块简称
             B.SYS_NAM, --模块简称    --shiwenbo by 20170407-sysnam 修改模块简称判断，因为CAR为3位，模块简称为4位char型
             A.REPORT_NAM, --报表编号
             A.ITEM_CD, --指标号
             A.B_CURR_CD, --报表要求的币种
             A.INDEX_VAL, --指标值(数值型)
             B.CONF_FLG --标志位：1-总账、2-明细、3-归并、9-个性化
        FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL_TMP_NGI A
       INNER JOIN PM_RSDATA.CBRC_A_REPT_ITEM_CONF B ON --A.SYS_NAM = B.SYS_NAM
       TRIM(A.SYS_NAM) = B.SYS_NAM --模块简称  --shiwenbo by 20170407-sysnam 修改模块简称判断，因为CAR为3位，模块简称为4位char型
       AND A.ITEM_CD = B.ITEM_NUM --统计科目编号
       AND B.USE_FLG = 'Y' --是否启用
       AND B.CONF_FLG = '1'; --从总账出数

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
   
END proc_cbrc_l_fina_gl_ngi