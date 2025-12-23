CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_s73(II_DATADATE  IN STRING --跑批日期
                                                     )
/******************************
  @author:
  @create-date:2025-03-18
  @description:S73
  @modification history:
   --需求编号：JLBA202507020013_关于吉林银行1104统一监管报送平台“五篇大文章”统计制度升级的需求 上线日期：20250729 修改人：石雨 提出人：于佳禾，修改内容：新增全国养老机构取数逻辑
  *******************************/
 IS
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE    VARCHAR(30); --当前储存过程名称
  V_REP_NUM      VARCHAR(30); --报表名称
  I_DATADATE     STRING; --数据日期(数值型)YYYYMMDD
  V_DATADATE     VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_ERRORDESC    VARCHAR(280); --错误内容
  D_DATADATE_CCY STRING;
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM       VARCHAR2(30);

BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';

    I_DATADATE     := II_DATADATE;
    V_DATADATE     := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYY-MM-DD');
    D_DATADATE_CCY := I_DATADATE;
    V_SYSTEM       := 'CBRC';
    V_PROCEDURE    := UPPER('PROC_CBRC_IDX2_S73');
    V_REP_NUM      := 'S73';

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
       AND REP_NUM = V_REP_NUM
       AND SYS_NAM = 'CBRC';
    COMMIT;

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_A_REPT_DWD_S73';

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'S73 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --累放数据

    --年初删除本年累计:

    IF SUBSTR(I_DATADATE, 5, 2) = 01 THEN
      EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S73_LOAN_TEMP';
    ELSE
      DELETE FROM CBRC_S73_LOAN_TEMP T
       WHERE SUBSTR(T.DATA_DATE, 1, 6) = SUBSTR(I_DATADATE, 1, 6);
      COMMIT;

    END IF;

    COMMIT;

    insert into CBRC_S73_LOAN_TEMP
      (DATA_DATE,
       ORG_NUM,
       CUST_ID,
       LOAN_ACCT_AMT,
       NHSY,
       LOAN_NUM,
       CUST_NAM,
       ITEM_CD,
       MATURITY_DT,
       DRAWDOWN_DT,
       CURR_CD,
       LOAN_PURPOSE_CD,
       QGYL_FLAG,
       PENSION_INDUSTRY,
       YL_FLAG,
       DEPARTMENTD)
      SELECT 
       I_DATADATE DATA_DATE,
       A.ORG_NUM, --机构号
       A.CUST_ID, --客户号
       A.DRAWDOWN_AMT AS LOAN_ACCT_AMT, --累放金额
       A.DRAWDOWN_AMT * A.REAL_INT_RAT / 100 NHSY, --年化收益
       A.LOAN_NUM, --借据号
       C.CUST_NAM, --客户名称
       A.ITEM_CD, --科目号
       A.MATURITY_DT, --原始到期日期
       A.DRAWDOWN_DT, --放款日期
       A.CURR_CD, --币种
       A.LOAN_PURPOSE_CD, --贷款投向
       CASE
         WHEN F.LOAN_NUM IS NOT NULL THEN
          'Y'
         ELSE
          'N'
       END QGYL_FLAG, --全国养老标识
       NVL(D.PENSION_INDUSTRY, A.PENSION_INDUSTRY) PENSION_INDUSTRY, --养老分类
       CASE
         WHEN NVL(D.PENSION_INDUSTRY, A.PENSION_INDUSTRY) IS NOT NULL THEN
          'Y'
         ELSE
          'N'
       END YL_FLAG, --养老标识
       A.DEPARTMENTD --归属部门
        FROM SMTMODS_L_ACCT_LOAN A --借据信息
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_ALL C --客户表
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT D
          ON D.DATA_DATE = I_DATADATE
         AND A.ACCT_NUM = D.CONTRACT_NUM
         AND SUBSTR(D.PENSION_INDUSTRY, 1, 2) IN
             ('01',
              '02',
              '03',
              '04',
              '05',
              '06',
              '07',
              '08',
              '09',
              '10',
              '11',
              '12')
        LEFT JOIN CBRC_QGYL_LIST F -- 全国养老按清单出数 --需求编号：JLBA202507020013_关于吉林银行1104统一监管报送平台“五篇大文章”统计制度升级的需求 上线日期：20250729 修改人：石雨 提出人：于佳禾，修改内容：新增全国养老机构取数逻辑
          ON A.LOAN_NUM = F.LOAN_NUM
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and a.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
         AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组 SHIYU 20220210  新口径吴大为
            ---AND A.LOAN_PURPOSE_CD IN ('Q8514', 'Q8416') --Q8514老年人、残疾人养护服务  Q8416疗养院
         AND (((A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%') AND
             A.ACCT_TYP NOT LIKE '0301%' AND
             D.PENSION_INDUSTRY IS NOT NULL) OR
             ((ITEM_CD LIKE '130101%' OR ITEM_CD LIKE '130104%') AND
             SUBSTR(A.PENSION_INDUSTRY, 1, 2) IN
             ('01',
                '02',
                '03',
                '04',
                '05',
                '06',
                '07',
                '08',
                '09',
                '10',
                '11',
                '12'))) --养老贷款
         AND (SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) =
             SUBSTR(I_DATADATE, 1, 6) ---取当月
             OR (A.INTERNET_LOAN_FLG = 'Y' AND
             A.DRAWDOWN_DT =
             (TRUNC(I_DATADATE, 'MM') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，上月末数据当月取
             );
    COMMIT;

    DELETE FROM CBRC_S73_LOAN_TEMP_HIS
     WHERE SUBSTR(DATA_DATE, 1, 6) = SUBSTR(I_DATADATE, 1, 6);
    COMMIT;

    INSERT INTO CBRC_S73_LOAN_TEMP_HIS
      SELECT DATA_DATE,
             ORG_NUM,
             CUST_ID,
             LOAN_ACCT_AMT,
             NHSY,
             LOAN_NUM,
             CUST_NAM,
             ITEM_CD,
             MATURITY_DT,
             DRAWDOWN_DT,
             CURR_CD,
             LOAN_PURPOSE_CD,
             QGYL_FLAG,
             PENSION_INDUSTRY,
             YL_FLAG,
             DEPARTMENTD --归属部门
        FROM CBRC_S73_LOAN_TEMP
       WHERE DATA_DATE = I_DATADATE;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '养老产业贷款_累放户数 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --begin01 明细需求 zhoulp20250814
    

    --户数
    INSERT INTO CBRC_A_REPT_DWD_S73
      (DATA_DATE,
       ORG_NUM,
       --DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_2, --字段2(客户号)
       COL_3, --字段3(客户名)
       TOTAL_VALUE --字段5(贷款余额/贷款金额/客户数/贷款收益)
       )
      SELECT I_DATADATE,
             T.ORG_NUM, --机构号
             --T.DEPARTMENTD,--数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'S73.1.A' AS ITEM_NUM,
             T.CUST_ID AS COL_2, --字段2(客户号)
             T.CUST_NAM AS COL_3, --字段3(客户名)
             1 AS TOTAL_VALUE --字段5(贷款余额/贷款金额/客户数/贷款收益)
        FROM (SELECT DISTINCT CUST_ID, ORG_NUM, CUST_NAM--, DEPARTMENTD --归属部门
                FROM CBRC_S73_LOAN_TEMP
               WHERE SUBSTR(DATA_DATE, 1, 4) = SUBSTR(I_DATADATE, 1, 4)
                 AND YL_FLAG = 'Y') T;
    COMMIT;
    --end01 明细需求 zhoulp20250814

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '养老产业贷款_累放金额 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --begin02 明细需求 zhoulp20250814
    

    --累放
    INSERT INTO CBRC_A_REPT_DWD_S73
      (data_date,
       org_num,
       DATA_DEPARTMENT,
       sys_nam,
       rep_num,
       item_num,
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
       COL_7, --字段7(放款日期)
       COL_8, --字段8(原始借据到期日期)
       COL_14, --字段14（贷款投向）
       COL_15 --字段15（养老产业贷款类型）
       )
      SELECT I_DATADATE,
             T.ORG_NUM, --机构号
             T.DEPARTMENTD,--数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'S73.1.B' AS ITEM_NUM,
             T.CUST_ID AS col_2, --字段2(客户号)
             T.CUST_NAM AS col_3, --字段3(客户名)
             T.LOAN_NUM AS col_4, --字段4(贷款编号)
             T.LOAN_ACCT_AMT * TT.CCY_RATE AS TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
             T.DRAWDOWN_DT AS COL_7, --字段7(放款日期)
             T.MATURITY_DT AS COL_8, --字段8(原始借据到期日期)
             T.LOAN_PURPOSE_CD AS COL_15, --字段15(贷款投向)
             T.PENSION_INDUSTRY AS COL_15 --字段15（养老产业贷款类型）
        FROM CBRC_S73_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.YL_FLAG = 'Y';
    COMMIT;
    --end02 明细需求 zhoulp20250814

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '养老产业贷款_累放收益 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --begin03 明细需求 zhoulp20250814
   

    --收益
    INSERT INTO CBRC_A_REPT_DWD_S73
      (data_date,
       org_num,
       DATA_DEPARTMENT,--数据条线
       sys_nam,
       rep_num,
       item_num,
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
       COL_7, --字段7(放款日期)
       COL_8, --字段8(原始借据到期日期)
       COL_14, --字段14（贷款投向）
       COL_15 --字段15（养老产业贷款类型）
       )
      SELECT I_DATADATE,
             T.ORG_NUM, --机构号
             T.DEPARTMENTD,--数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'S73.1.F' AS ITEM_NUM,
             T.CUST_ID AS col_2, --字段2(客户号)
             T.CUST_NAM AS col_3, --字段3(客户名)
             T.LOAN_NUM AS col_4, --字段4(贷款编号)
             T.NHSY * TT.CCY_RATE AS TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
             T.DRAWDOWN_DT AS COL_7, --字段7(放款日期)
             T.MATURITY_DT AS COL_8, --字段8(原始借据到期日期)
             T.LOAN_PURPOSE_CD AS COL_15, --字段15(贷款投向)
             T.PENSION_INDUSTRY AS COL_15 --字段15（养老产业贷款类型）
        FROM CBRC_S73_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY';
    COMMIT;
    --end03 明细需求 zhoulp20250814

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '养老产业贷款_贷款余额 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --begin04 明细需求 zhoulp20250814
   

    --贷款余额
    INSERT INTO CBRC_A_REPT_DWD_S73
      (data_date,
       org_num,
       DATA_DEPARTMENT,--数据条线
       sys_nam,
       rep_num,
       item_num,
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
       COL_6, --字段6(贷款合同编号)
       COL_7, --字段7(放款日期)
       COL_8, --字段8(原始借据到期日期)
       COL_15 --字段15（养老产业贷款类型）
       )
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,--数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'S73.1.C' AS ITEM_NUM,
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
             A.ACCT_NUM AS col_6, --字段6(贷款合同编号)
             A.DRAWDOWN_DT AS COL_7, --字段7(放款日期)
             A.MATURITY_DT AS COL_8, --字段8(原始借据到期日期)
             CASE
               WHEN A.ITEM_CD LIKE '130101%' OR A.ITEM_CD LIKE '130104%' THEN
                A.PENSION_INDUSTRY
               ELSE
                D.PENSION_INDUSTRY
             END AS COL_15 --字段15（养老产业贷款类型）

        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT D
          ON D.DATA_DATE = I_DATADATE
         AND A.ACCT_NUM = D.CONTRACT_NUM
         AND SUBSTR(D.PENSION_INDUSTRY, 1, 2) IN
             ('01',
              '02',
              '03',
              '04',
              '05',
              '06',
              '07',
              '08',
              '09',
              '10',
              '11',
              '12')
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
            --AND A.LOAN_PURPOSE_CD IN ('Q8514', 'Q8416') --Q8514老年人、残疾人养护服务  Q8416疗养院
         AND (((A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%') AND
             A.ACCT_TYP NOT LIKE '0301%' AND
             D.PENSION_INDUSTRY IS NOT NULL) OR
             ((ITEM_CD LIKE '130101%' OR ITEM_CD LIKE '130104%') AND
             SUBSTR(A.PENSION_INDUSTRY, 1, 2) IN
             ('01',
                '02',
                '03',
                '04',
                '05',
                '06',
                '07',
                '08',
                '09',
                '10',
                '11',
                '12')));
    COMMIT;
    --end04 明细需求 zhoulp20250814

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '养老产业贷款_中长期 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --begin05 明细需求 zhoulp20250814
    

    --中长期
    INSERT INTO CBRC_A_REPT_DWD_S73
      (data_date,
       org_num,
       DATA_DEPARTMENT,--数据条线
       sys_nam,
       rep_num,
       item_num,
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
       COL_6, --字段6(贷款合同编号)
       COL_7, --字段7(放款日期)
       COL_8, --字段8(原始借据到期日期)
       COL_15 --字段15（养老产业贷款类型）
       )
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,--数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'S73.1.D' AS ITEM_NUM,
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
             A.ACCT_NUM AS col_6, --字段6(贷款合同编号)
             A.DRAWDOWN_DT AS COL_7, --字段7(放款日期)
             A.MATURITY_DT AS COL_8, --字段8(原始借据到期日期)
             CASE
               WHEN A.ITEM_CD LIKE '130101%' OR A.ITEM_CD LIKE '130104%' THEN
                A.PENSION_INDUSTRY
               ELSE
                D.PENSION_INDUSTRY
             END AS COL_15 --字段15（养老产业贷款类型）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT D
          ON D.DATA_DATE = I_DATADATE
         AND A.ACCT_NUM = D.CONTRACT_NUM
         AND SUBSTR(D.PENSION_INDUSTRY, 1, 2) IN
             ('01',
              '02',
              '03',
              '04',
              '05',
              '06',
              '07',
              '08',
              '09',
              '10',
              '11',
              '12')
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
         AND (((A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%') AND
             A.ACCT_TYP NOT LIKE '0301%' AND
             D.PENSION_INDUSTRY IS NOT NULL) OR
             ((ITEM_CD LIKE '130101%' OR ITEM_CD LIKE '130104%') AND
             SUBSTR(A.PENSION_INDUSTRY, 1, 2) IN
             ('01',
                '02',
                '03',
                '04',
                '05',
                '06',
                '07',
                '08',
                '09',
                '10',
                '11',
                '12')))
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) > 12 --中长期
      ;
    COMMIT;
    --end05 明细需求 zhoulp20250814
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '养老产业贷款_不良贷款 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --begin06 明细需求 zhoulp20250814
    

    --不良贷款
    INSERT INTO CBRC_A_REPT_DWD_S73
      (data_date,
       org_num,
       DATA_DEPARTMENT,--数据条线
       sys_nam,
       rep_num,
       item_num,
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
       COL_6, --字段6(贷款合同编号)
       COL_7, --字段7(放款日期)
       COL_8, --字段8(原始借据到期日期)
       COL_9, --字段9(五级分类)
       COL_15 --字段15（养老产业贷款类型）
       )
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,--数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'S73.1.E' AS ITEM_NUM,
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
             A.ACCT_NUM AS col_6, --字段6(贷款合同编号)
             A.DRAWDOWN_DT AS COL_7, --字段7(放款日期)
             A.MATURITY_DT AS COL_8, --字段8(原始借据到期日期)
             A.LOAN_GRADE_CD AS COL_9, --字段9(五级分类)
             CASE
               WHEN A.ITEM_CD LIKE '130101%' OR A.ITEM_CD LIKE '130104%' THEN
                A.PENSION_INDUSTRY
               ELSE
                D.PENSION_INDUSTRY
             END AS COL_15 --字段15（养老产业贷款类型）
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT D
          ON D.DATA_DATE = I_DATADATE
         AND A.ACCT_NUM = D.CONTRACT_NUM
         AND SUBSTR(D.PENSION_INDUSTRY, 1, 2) IN
             ('01',
              '02',
              '03',
              '04',
              '05',
              '06',
              '07',
              '08',
              '09',
              '10',
              '11',
              '12')
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
         AND (((A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%') AND
             A.ACCT_TYP NOT LIKE '0301%' AND
             D.PENSION_INDUSTRY IS NOT NULL) OR
             ((ITEM_CD LIKE '130101%' OR ITEM_CD LIKE '130104%') AND
             SUBSTR(A.PENSION_INDUSTRY, 1, 2) IN
             ('01',
                '02',
                '03',
                '04',
                '05',
                '06',
                '07',
                '08',
                '09',
                '10',
                '11',
                '12')))
         AND A.LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款
      ;
    COMMIT;
    --end06 明细需求 zhoulp20250814

    -----全国养老贷款
    --需求编号：JLBA202507020013_关于吉林银行1104统一监管报送平台“五篇大文章”统计制度升级的需求 上线日期：20250729 修改人：石雨 提出人：于佳禾，修改内容：新增全国养老机构取数逻辑

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '全国养老贷款_累放户数 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --户数
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S73' AS REP_NUM, --报表编号
             'S73.2.A' AS ITEM_NUM,
             COUNT(*) AS COLLECT_VAL, --汇总值
             '2' AS FLAG
        FROM (select DISTINCT CUST_ID, ORG_NUM
                FROM CBRC_S73_LOAN_TEMP
               WHERE SUBSTR(DATA_DATE, 1, 4) = SUBSTR(I_DATADATE, 1, 4)
                 AND QGYL_FLAG = 'Y') T
       GROUP BY T.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '全国养老贷款_累放金额 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --累放
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S73' AS REP_NUM, --报表编号
             'S73.2.B' AS ITEM_NUM,
             SUM(T.LOAN_ACCT_AMT * TT.CCY_RATE) AS COLLECT_VAL, --汇总值
             '2' AS FLAG
        FROM CBRC_S73_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.QGYL_FLAG = 'Y'
       GROUP BY T.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '全国养老贷款_累放收益 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --收益
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S73' AS REP_NUM, --报表编号
             'S73.2.F' AS ITEM_NUM,
             SUM(T.NHSY * TT.CCY_RATE) AS COLLECT_VAL, --汇总值
             '2' AS FLAG
        FROM CBRC_S73_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.QGYL_FLAG = 'Y'
       GROUP BY T.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '全国养老贷款_贷款余额 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --贷款余额
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S73' AS REP_NUM, --报表编号
             'S73.2.C' AS ITEM_NUM,
             SUM(NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
                 NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0)) AS COLLECT_VAL, --汇总值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       INNER JOIN CBRC_QGYL_LIST F -- 全国养老按清单出数
          ON A.LOAN_NUM = F.LOAN_NUM
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
      --AND A.LOAN_PURPOSE_CD IN ('Q8514', 'Q8416') --Q8514老年人、残疾人养护服务  Q8416疗养院
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '全国养老贷款_中长期 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --中长期
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S73' AS REP_NUM, --报表编号
             'S73.2.D' AS ITEM_NUM,
             SUM(NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
                 NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0)) AS COLLECT_VAL, --汇总值
             '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       INNER JOIN CBRC_QGYL_LIST F -- 全国养老按清单出数
          ON A.LOAN_NUM = F.LOAN_NUM
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) > 12 --中长期
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '全国养老贷款_不良贷款 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --不良贷款
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S73' AS REP_NUM, --报表编号
             'S73.2.E' AS ITEM_NUM,
             SUM(NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
                 NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0)) AS COLLECT_VAL, --汇总值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       INNER JOIN CBRC_QGYL_LIST F -- 全国养老按清单出数
          ON A.LOAN_NUM = F.LOAN_NUM
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
         AND A.LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '特定养老储蓄存款余额 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S73' AS REP_NUM, --报表编号
             'S73.7.1.B' AS ITEM_NUM,
             SUM(T.ACCT_BALANCE * TT.CCY_RATE) AS COLLECT_VAL, --汇总值
             '2' AS FLAG

        FROM SMTMODS_L_ACCT_DEPOSIT T
        LEFT JOIN SMTMODS_L_BASIC_PRODUCT P
          ON T.POC_INDEX_CODE = P.CP_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND P.CPMC LIKE '%特定养老储蓄%'
         AND T.ACCT_STS <> 'C'
         AND T.ACCT_BALANCE <> 0
       GROUP BY T.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '特定养老储蓄存款户数 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --户数
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S73' AS REP_NUM, --报表编号
             'S73.7.1.A' AS ITEM_NUM,
             COUNT(*) AS COLLECT_VAL, --汇总值
             '2' AS FLAG
        FROM (SELECT T.ORG_NUM, T.CUST_ID
                FROM SMTMODS_L_ACCT_DEPOSIT T
                LEFT JOIN SMTMODS_L_BASIC_PRODUCT P
                  ON T.POC_INDEX_CODE = P.CP_ID
                 AND P.DATA_DATE = I_DATADATE
               WHERE T.DATA_DATE = I_DATADATE
                 AND P.CPMC LIKE '%特定养老储蓄%'
                 AND T.ACCT_STS <> 'C'
                 AND T.ACCT_BALANCE <> 0
               GROUP BY T.ORG_NUM, T.CUST_ID) T
       GROUP BY T.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '9.1长辈客群金融服务——存款户数 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --9.1存款
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'CBRC' AS SYS_NAM, --模块简称
       'S73' AS REP_NUM, --报表编号
       'S73.9.1.A' AS ITEM_NUM,
       COUNT(*) AS LOAN_ACCT_BAL_RMB,
       '2'
        FROM (SELECT A.ORG_NUM, A.CUST_ID
                FROM SMTMODS_L_ACCT_DEPOSIT A
               INNER JOIN SMTMODS_L_CUST_P C
                  ON A.CUST_ID = C.CUST_ID
                 AND C.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE TT
                  ON TT.DATA_DATE = A.DATA_DATE
                 AND TT.BASIC_CCY = A.CURR_CD
                 AND TT.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                  AND ( A.GL_ITEM_CODE LIKE '201101%' --个人贷款
            OR A.GL_ITEM_CODE LIKE '224101%' ) --[JLBA202507210012][石雨][修改内容：修改内容：新增22410102个人久悬未取款]
                 AND A.ACCT_BALANCE <> 0
                 AND A.ACCT_STS NOT LIKE 'C%'
                 AND ((SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                     SUBSTR(I_DATADATE, 1, 4) - case
                       when func_pbocd_date_flg(SUBSTR(DECODE(C.ID_NO,
                                                                 NULL,
                                                                 '00000020240000',
                                                                 C.ID_NO),
                                                          7,
                                                          8)) = 1 then
                        SUBSTR(DECODE(C.ID_NO,
                                      NULL,
                                      '00000020240000',
                                      C.ID_NO),
                               7,
                               4)
                       else
                        SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4)
                     end >= 55) OR
                     (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                     SUBSTR(I_DATADATE, 1, 4) -
                     SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) >= 55))
               GROUP BY A.ORG_NUM, A.CUST_ID) A
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '9.1长辈客群金融服务——存款余额 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'CBRC' AS SYS_NAM, --模块简称
       'S73' AS REP_NUM, --报表编号
       'S73.9.1.B' AS ITEM_NUM,
       SUM(A.ACCT_BALANCE * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
       '2'
        FROM SMTMODS_L_ACCT_DEPOSIT A
       INNER JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
          AND ( A.GL_ITEM_CODE LIKE '201101%' --个人贷款
            OR A.GL_ITEM_CODE LIKE '224101%' ) --[JLBA202507210012][石雨][修改内容：修改内容：新增22410102个人久悬未取款]
         AND A.ACCT_BALANCE <> 0
         AND A.ACCT_STS NOT LIKE 'C%'
         AND ((SUBSTR(C.ID_TYPE, 1, 2) = '10' AND SUBSTR(I_DATADATE, 1, 4) - case
               when func_pbocd_date_flg(SUBSTR(DECODE(C.ID_NO,
                                                         NULL,
                                                         '00000020240000',
                                                         C.ID_NO),
                                                  7,
                                                  8)) = 1 then
                SUBSTR(DECODE(C.ID_NO, NULL, '00000020240000', C.ID_NO),
                       7,
                       4)
               else
                SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4)
             end >= 55) OR
             (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
             SUBSTR(I_DATADATE, 1, 4) -
             SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) >= 55))
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '9.2长辈客群金融服务_贷款户数 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --9.2贷款
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'CBRC' AS SYS_NAM, --模块简称
       'S73' AS REP_NUM, --报表编号
       'S73.9.2.A' AS ITEM_NUM,
       COUNT(*) AS LOAN_ACCT_BAL_RMB,
       '2'
        FROM (SELECT A.ORG_NUM, A.CUST_ID
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_CUST_P C
                  ON A.CUST_ID = C.CUST_ID
                 AND C.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE TT
                  ON TT.DATA_DATE = A.DATA_DATE
                 AND TT.BASIC_CCY = A.CURR_CD
                 AND TT.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.ACCT_TYP LIKE '01%' --个人贷款
                 AND A.CANCEL_FLG = 'N'
                 AND LENGTHB(A.ACCT_NUM) < 36
                 AND A.LOAN_ACCT_BAL <> 0
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
                 AND ((SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                     SUBSTR(I_DATADATE, 1, 4) - case
                       when func_pbocd_date_flg(SUBSTR(DECODE(C.ID_NO,
                                                                 NULL,
                                                                 '00000020240000',
                                                                 C.ID_NO),
                                                          7,
                                                          8)) = 1 then
                        SUBSTR(DECODE(C.ID_NO,
                                      NULL,
                                      '00000020240000',
                                      C.ID_NO),
                               7,
                               4)
                       else
                        SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4)
                     end >= 55) OR
                     (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                     SUBSTR(I_DATADATE, 1, 4) -
                     SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) >= 55))
               GROUP BY A.ORG_NUM, A.CUST_ID) A
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '9.2长辈客群金融服务_贷款余额 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'CBRC' AS SYS_NAM, --模块简称
       'S73' AS REP_NUM, --报表编号
       'S73.9.2.B' AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
       '2'
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP LIKE '01%' --个人贷款
         AND A.CANCEL_FLG = 'N'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.LOAN_ACCT_BAL <> 0
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
         AND ((SUBSTR(C.ID_TYPE, 1, 2) = '10' AND SUBSTR(I_DATADATE, 1, 4) - case
               when func_pbocd_date_flg(SUBSTR(DECODE(C.ID_NO,
                                                         NULL,
                                                         '00000020240000',
                                                         C.ID_NO),
                                                  7,
                                                  8)) = 1 then
                SUBSTR(DECODE(C.ID_NO, NULL, '00000020240000', C.ID_NO),
                       7,
                       4)
               else
                SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4)
             end >= 55) OR
             (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
             SUBSTR(I_DATADATE, 1, 4) -
             SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) >= 55))
       GROUP BY A.ORG_NUM;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '8代销养老金融产品  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --8.代销养老金融产品
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE
         WHEN T.ORG_NUM LIKE '060101%' THEN
          '060300'
         WHEN T.ORG_NUM NOT LIKE '__98%' AND
              substr(T.ORG_NUM, 1, 1) not in ('5', '6', '7') THEN
          SUBSTR(T.ORG_NUM, 1, 4) || '00'
         ELSE
          T.ORG_NUM
       END ORG_NUM,
       'CBRC' AS SYS_NAM, --模块简称
       'S73' AS REP_NUM, --报表编号
       'S73.8.A' AS ITEM_NUM,
       COUNT(*),
       '2'
        FROM (SELECT T.ORG_NUM, T.CUST_ID
                FROM SMTMODS_L_TRAN_FINANCE_FUND T --代理代销交易表
                LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = T.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE TO_CHAR(T.TRAN_DATE, 'YYYYMMDD') BETWEEN
                     substr(I_DATADATE, 1, 4) || '0101' AND I_DATADATE --交易日期为本年
                 AND T.PROD_CODE IN ('006861', '006862')
               GROUP BY T.ORG_NUM, T.CUST_ID) T
       GROUP BY CASE
                  WHEN T.ORG_NUM LIKE '060101%' THEN
                   '060300'
                  WHEN T.ORG_NUM NOT LIKE '__98%' AND
                       substr(T.ORG_NUM, 1, 1) not in ('5', '6', '7') THEN
                   SUBSTR(T.ORG_NUM, 1, 4) || '00'
                  ELSE
                   T.ORG_NUM
                END;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE
         WHEN T.ORG_NUM LIKE '060101%' THEN
          '060300'
         WHEN T.ORG_NUM NOT LIKE '__98%' AND
              substr(T.ORG_NUM, 1, 1) not in ('5', '6', '7') THEN
          SUBSTR(T.ORG_NUM, 1, 4) || '00'
         ELSE
          T.ORG_NUM
       END ORG_NUM,
       'CBRC' AS SYS_NAM, --模块简称
       'S73' AS REP_NUM, --报表编号
       'S73.8.C' AS ITEM_NUM,
       SUM(T.AMT * NVL(U.CCY_RATE, 0)),
       '2'
        FROM SMTMODS_L_TRAN_FINANCE_FUND T --代理代销交易表
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE TO_CHAR(T.TRAN_DATE, 'YYYYMMDD') BETWEEN
             substr(I_DATADATE, 1, 4) || '0101' AND I_DATADATE --交易日期为本年
         AND T.PROD_CODE IN ('006861', '006862')
       GROUP BY CASE
                  WHEN T.ORG_NUM LIKE '060101%' THEN
                   '060300'
                  WHEN T.ORG_NUM NOT LIKE '__98%' AND
                       substr(T.ORG_NUM, 1, 1) not in ('5', '6', '7') THEN
                   SUBSTR(T.ORG_NUM, 1, 4) || '00'
                  ELSE
                   T.ORG_NUM
                END;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '9.3代理代销金融产品  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE
         WHEN T.ORG_NUM LIKE '060101%' THEN
          '060300'
         WHEN T.ORG_NUM NOT LIKE '__98%' AND
              substr(T.ORG_NUM, 1, 1) not in ('5', '6', '7') THEN
          SUBSTR(T.ORG_NUM, 1, 4) || '00'
         ELSE
          T.ORG_NUM
       END ORG_NUM,
       'CBRC' AS SYS_NAM, --模块简称
       'S73' AS REP_NUM, --报表编号
       'S73.9.3.A' AS ITEM_NUM,
       count(*),
       '2'
        FROM (SELECT T.ORG_NUM, T.CUST_ID
                FROM SMTMODS_L_TRAN_FINANCE_FUND T --代理代销交易表
                LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = T.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
                LEFT JOIN SMTMODS_L_FIMM_PRODUCT P --理财产品信息表
                  ON T.PROD_CODE = P.PRODUCT_CODE
                 AND P.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_CUST_P C
                  ON t.CUST_ID = C.CUST_ID
                 AND C.DATA_DATE = I_DATADATE
               WHERE TO_CHAR(T.TRAN_DATE, 'YYYYMMDD') BETWEEN
                     substr(I_DATADATE, 1, 4) || '0101' AND I_DATADATE --交易日期为本年
                 AND (T.BUSINESS_TYPE IN ('2', '3', '5') or
                      (T.BUSINESS_TYPE = '1' AND
                      P.CASH_MANAGE_PRODUCT_FLG = 'N'))
                 AND ((SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                      SUBSTR(I_DATADATE, 1, 4) - case
                        when func_pbocd_date_flg(SUBSTR(DECODE(C.ID_NO,
                                                                  NULL,
                                                                  '00000020240000',
                                                                  C.ID_NO),
                                                           7,
                                                           8)) = 1 then
                         SUBSTR(DECODE(C.ID_NO,
                                       NULL,
                                       '00000020240000',
                                       C.ID_NO),
                                7,
                                4)
                        else
                         SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4)
                      end >= 55) OR
                      (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                      SUBSTR(I_DATADATE, 1, 4) -
                      SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) >= 55))
               GROUP BY T.ORG_NUM, T.CUST_ID) T
       GROUP BY CASE
                  WHEN T.ORG_NUM LIKE '060101%' THEN
                   '060300'
                  WHEN T.ORG_NUM NOT LIKE '__98%' AND
                       substr(T.ORG_NUM, 1, 1) not in ('5', '6', '7') THEN
                   SUBSTR(T.ORG_NUM, 1, 4) || '00'
                  ELSE
                   T.ORG_NUM
                END;
    commit;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE
         WHEN T.ORG_NUM LIKE '060101%' THEN
          '060300'
         WHEN T.ORG_NUM NOT LIKE '__98%' AND
              substr(T.ORG_NUM, 1, 1) not in ('5', '6', '7') THEN
          SUBSTR(T.ORG_NUM, 1, 4) || '00'
         ELSE
          T.ORG_NUM
       END ORG_NUM,
       'CBRC' AS SYS_NAM, --模块简称
       'S73' AS REP_NUM, --报表编号
       'S73.9.3.C' AS ITEM_NUM,
       SUM(T.AMT * NVL(U.CCY_RATE, 0)),
       '2'
        FROM SMTMODS_L_TRAN_FINANCE_FUND T --代理代销交易表
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_FIMM_PRODUCT P --理财产品信息表
          ON T.PROD_CODE = P.PRODUCT_CODE
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON t.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE TO_CHAR(T.TRAN_DATE, 'YYYYMMDD') BETWEEN
             substr(I_DATADATE, 1, 4) || '0101' AND I_DATADATE --交易日期为本年
         AND (T.BUSINESS_TYPE IN ('2', '3', '5') or
              (T.BUSINESS_TYPE = '1' AND P.CASH_MANAGE_PRODUCT_FLG = 'N'))
         AND ((SUBSTR(C.ID_TYPE, 1, 2) = '10' AND SUBSTR(I_DATADATE, 1, 4) - case
                when func_pbocd_date_flg(SUBSTR(DECODE(C.ID_NO,
                                                          NULL,
                                                          '00000020240000',
                                                          C.ID_NO),
                                                   7,
                                                   8)) = 1 then
                 SUBSTR(DECODE(C.ID_NO, NULL, '00000020240000', C.ID_NO),
                        7,
                        4)
                else
                 SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4)
              end >= 55) OR
              (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
              SUBSTR(I_DATADATE, 1, 4) -
              SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) >= 55))
       GROUP BY CASE
                  WHEN T.ORG_NUM LIKE '060101%' THEN
                   '060300'
                  WHEN T.ORG_NUM NOT LIKE '__98%' AND
                       substr(T.ORG_NUM, 1, 1) not in ('5', '6', '7') THEN
                   SUBSTR(T.ORG_NUM, 1, 4) || '00'
                  ELSE
                   T.ORG_NUM
                END;

    --begin07 明细需求 zhoulp20250814
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
             V_REP_NUM AS REP_NUM, --报表编号
             ITEM_NUM, --指标号
             SUM(TOTAL_VALUE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM CBRC_A_REPT_DWD_S73
       WHERE DATA_DATE = I_DATADATE
       GROUP BY ORG_NUM, ITEM_NUM;
    COMMIT;
    --end07 明细需求 zhoulp20250814





    V_STEP_FLAG := V_STEP_ID + 1;
    V_STEP_DESC := 'S73 逻辑处理完成';
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
   
END proc_cbrc_idx2_s73