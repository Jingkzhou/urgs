CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_s74(II_DATADATE  IN STRING --跑批日期
                                                     )
/******************************
  @author:
  @create-date:2025-03-18
  @description:S74
  @modification history:数字贷款
   --需求编号：JLBA202507020013_关于吉林银行1104统一监管报送平台“五篇大文章”统计制度升级的需求 上线日期：20250729 修改人：石雨 提出人：于佳禾，修改内容：按照NGI数据贷款类型取数
  *******************************/
 IS
  V_SCHEMA        VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE     VARCHAR(30); --当前储存过程名称
  V_REP_NUM       VARCHAR(30); --报表名称
  I_DATADATE      STRING; --数据日期(数值型)YYYYMMDD
  V_DATADATE      VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  V_STEP_ID       INTEGER; --任务号
  V_STEP_DESC     VARCHAR(300); --任务描述
  V_STEP_FLAG     INTEGER; --任务执行状态标识
  V_ERRORCODE     VARCHAR(20); --错误编码
  V_ERRORDESC     VARCHAR(280); --错误内容
  D_DATADATE_CCY  STRING;
  II_STATUS       INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_PARTITION_NUM VARCHAR(20); --分区个数
  V_NEXTDATE      INTEGER; --数据日期(数值型)YYYYMMDD
  V_SYSTEM        VARCHAR2(30);
   

BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';

    I_DATADATE     := II_DATADATE;
    V_DATADATE     := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYY-MM-DD');
    D_DATADATE_CCY := I_DATADATE;
    V_SYSTEM       := 'CBRC';
    V_PROCEDURE    := UPPER('PROC_CBRC_IDX2_S74');
    V_REP_NUM      := 'S74';
    V_NEXTDATE     := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD') + 1,
                              'YYYYMMDD');

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

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S74_DIGITAL_TRANS_SERVICES ';

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_A_REPT_DWD_S74';

    --end 明细需求 zhangyq20250815

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'S74 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --累放数据

    --年初删除本年累计:

    IF SUBSTR(I_DATADATE, 5, 2) = 01 THEN
      EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S74_LOAN_TEMP';
    ELSE

      DELETE FROM CBRC_S74_LOAN_TEMP
       WHERE SUBSTR(DATA_DATE, 1, 6) = SUBSTR(I_DATADATE, 1, 6);
      COMMIT;

    END IF;

    COMMIT;

    --begin 明细需求 zhangyq20250815

    insert into CBRC_S74_LOAN_TEMP
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
       DIGITAL_ECONOMY_INDUSTRY,
       ACCT_NUM,
       LOAN_GRADE_CD,
       CORP_SCALE,
       CORP_BUSINSESS_TYPE,
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
       SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY, A.DIGITAL_ECONOMY_INDUSTRY),
              1,
              2), --数据经济产业分类
       A.ACCT_NUM, --合同号
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END LOAN_GRADE_CD, --五级分类
       CASE
         WHEN C1.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C1.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C1.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C1.CORP_SCALE = 'T' THEN
          '微型'
       END CORP_SCALE, --企业规模
       NVL(C1.CORP_BUSINSESS_TYPE, C2.INDUSTRY_TYPE) AS CORP_BUSINSESS_TYPE, --行业分类
       A.DEPARTMENTD --归属部门
        FROM SMTMODS_L_ACCT_LOAN A --借据信息
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = DATE(I_DATADATE, 'yyyymmdd')
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_ALL C --客户表
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT D
          ON D.DATA_DATE = I_DATADATE
         AND A.ACCT_NUM = D.CONTRACT_NUM
        LEFT JOIN SMTMODS_L_CUST_C C1 --对公客户表
          ON A.CUST_ID = C1.CUST_ID
         AND C1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C2 --个人客户表
          ON A.CUST_ID = C2.CUST_ID
         AND C2.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and a.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
         AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组 SHIYU 20220210  新口径吴大为
         AND ((SUBSTR(D.DIGITAL_ECONOMY_INDUSTRY, 1, 2) IN
             ('01', '02', '03', '04') AND A.ACCT_TYP NOT LIKE '0301%') OR
             (SUBSTR(A.DIGITAL_ECONOMY_INDUSTRY, 1, 2) IN
             ('01', '02', '03', '04') AND
             (A.ITEM_CD LIKE '130101%' OR A.ITEM_CD LIKE '130104%'))) --[JLBA202507020013][20250729][石雨][于佳禾][按照NGI数据贷款类型取数]
         AND (SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) = ---取当月
             SUBSTR(I_DATADATE, 1, 6) OR
             (A.INTERNET_LOAN_FLG = 'Y' AND
             A.DRAWDOWN_DT =
             (TRUNC(DATE(I_DATADATE, 'YYYYMMDD'), 'MM') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，上月末数据当月取
             );
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '数字经济产业_累放贷款户数 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 

    INSERT INTO CBRC_A_REPT_DWD_S74
      (DATA_DATE,
       ORG_NUM,
       --DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_2, --字段2(客户号)
       TOTAL_VALUE --字段5(贷款余额/贷款金额/客户数/贷款收益)
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构号
             --T.DEPARTMENTD, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S74' AS REP_NUM, --报表编号
             'S74.1.A' AS ITEM_NUM, --指标号
             T.CUST_ID AS COL_2, --字段2(客户号)
             1 AS TOTAL_VALUE --字段5(贷款余额/贷款金额/客户数/贷款收益)
        FROM CBRC_S74_LOAN_TEMP T
       WHERE SUBSTR(T.DATA_DATE, 1, 4) = SUBSTR(I_DATADATE, 1, 4)
            --- AND t.LOAN_PURPOSE_CD IN(SELECT CODE FROM PUB_KJDK WHERE FLAG = '5.1')
         AND DIGITAL_ECONOMY_INDUSTRY IN ('01', '02', '03', '04') --[JLBA202507020013][20250729][石雨][于佳禾][按照NGI数据贷款类型取数]
       GROUP BY T.ORG_NUM, /*T.DEPARTMENTD, */T.CUST_ID;

    COMMIT;

    

    INSERT INTO CBRC_A_REPT_DWD_S74
      (DATA_DATE,
       ORG_NUM,
       --DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_2, --字段2(客户号)
       TOTAL_VALUE --字段5(贷款余额/贷款金额/客户数/贷款收益)
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构号
             --T.DEPARTMENTD,
             'CBRC' AS SYS_NAM, --模块简称
             'S74' AS REP_NUM, --报表编号
             CASE
               WHEN DIGITAL_ECONOMY_INDUSTRY = '01' THEN
                'S74.1.1.A'
               WHEN DIGITAL_ECONOMY_INDUSTRY = '02' THEN
                'S74.1.2.A'
               WHEN DIGITAL_ECONOMY_INDUSTRY = '03' THEN
                'S74.1.3.A'
               WHEN DIGITAL_ECONOMY_INDUSTRY = '04' THEN
                'S74.1.4.A'
             END AS ITEM_NUM,
             T.CUST_ID AS COL_2, --字段2(客户号)
             1 AS TOTAL_VALUE --字段5(贷款余额/贷款金额/客户数/贷款收益)
        FROM CBRC_S74_LOAN_TEMP T
       WHERE SUBSTR(T.DATA_DATE, 1, 4) = SUBSTR(I_DATADATE, 1, 4)
            --- AND t.LOAN_PURPOSE_CD IN(SELECT CODE FROM PUB_KJDK WHERE FLAG = '5.1')
         AND DIGITAL_ECONOMY_INDUSTRY IN ('01', '02', '03', '04') --[JLBA202507020013][20250729][石雨][于佳禾][按照NGI数据贷款类型取数]
       GROUP BY T.ORG_NUM,
                --T.DEPARTMENTD,
                T.CUST_ID,
                CASE
                  WHEN DIGITAL_ECONOMY_INDUSTRY = '01' THEN
                   'S74.1.1.A'
                  WHEN DIGITAL_ECONOMY_INDUSTRY = '02' THEN
                   'S74.1.2.A'
                  WHEN DIGITAL_ECONOMY_INDUSTRY = '03' THEN
                   'S74.1.3.A'
                  WHEN DIGITAL_ECONOMY_INDUSTRY = '04' THEN
                   'S74.1.4.A'
                END;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '数字经济产业_累放贷款金额 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    

    INSERT INTO CBRC_A_REPT_DWD_S74
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --字段2(客户号)
       COL_3, --字段3(客户名)
       COL_4, --字段4(贷款编号)
       TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
       COL_6, --字段6(贷款合同编号)
       COL_7, --字段7（放款日期）
       COL_8, --字段8（原始到期日）
       COL_9, --字段9（个人客户类型（个体工商户 小微企业主 其他个人））
       COL_10, --字段10（企业规模）
       COL_11, --字段11（客户所属条线）
       COL_12, --字段12（五级分类）
       COL_13, --字段13（行业分类）
       COL_14, --字段14（贷款投向）
       COL_15 --字段15（数字经济核心产业贷款）
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构号
             T.DEPARTMENTD, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S74' AS REP_NUM, --报表编号
             CASE
               WHEN DIGITAL_ECONOMY_INDUSTRY = '01' THEN
                'S74.1.1.B'
               WHEN DIGITAL_ECONOMY_INDUSTRY = '02' THEN
                'S74.1.2.B'
               WHEN DIGITAL_ECONOMY_INDUSTRY = '03' THEN
                'S74.1.3.B'
               WHEN DIGITAL_ECONOMY_INDUSTRY = '04' THEN
                'S74.1.4.B'
             END AS ITEM_NUM,
             T.CUST_ID,
             T.CUST_NAM,
             T.LOAN_NUM,
             NVL(T.LOAN_ACCT_AMT, 0) * B.CCY_RATE AS COLLECT_VAL, --汇总值
             T.ACCT_NUM,
             T.DRAWDOWN_DT,
             T.MATURITY_DT,
             '',
             T.CORP_SCALE,
             '',
             T.LOAN_GRADE_CD,
             T.CORP_BUSINSESS_TYPE,
             T.LOAN_PURPOSE_CD,
             ''
        FROM CBRC_S74_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE SUBSTR(T.DATA_DATE, 1, 4) = SUBSTR(I_DATADATE, 1, 4)
            --  AND t.LOAN_PURPOSE_CD IN (SELECT CODE FROM PUB_KJDK WHERE FLAG = '5.1')
         AND T.DIGITAL_ECONOMY_INDUSTRY IN ('01', '02', '03', '04') --[JLBA202507020013][20250729][石雨][于佳禾][按照NGI数据贷款类型取数]
      ;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '数字经济产业_贷款余额 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    

    INSERT INTO CBRC_A_REPT_DWD_S74
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --字段2(客户号)
       COL_3, --字段3(客户名)
       COL_4, --字段4(贷款编号)
       TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
       COL_6, --字段6(贷款合同编号)
       COL_7, --字段7（放款日期）
       COL_8, --字段8（原始到期日）
       COL_9, --字段9（个人客户类型（个体工商户 小微企业主 其他个人））
       COL_10, --字段10（企业规模）
       COL_11, --字段11（客户所属条线）
       COL_12, --字段12（五级分类）
       COL_13, --字段13（行业分类）
       COL_14, --字段14（贷款投向）
       COL_15 --字段15（数字经济核心产业贷款）
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S74' AS REP_NUM, --报表编号
             CASE
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '01' THEN
                'S74.1.1.C'
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '02' THEN
                'S74.1.2.C'
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '03' THEN
                'S74.1.3.C'
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '04' THEN
                'S74.1.4.C'
             END AS ITEM_NUM,
             A.CUST_ID,
             C.CUST_NAM,
             A.LOAN_NUM,
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS COLLECT_VAL, --汇总值
             A.ACCT_NUM,
             A.DRAWDOWN_DT,
             A.MATURITY_DT,
             '',
             CASE
               WHEN C1.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C1.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C1.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C1.CORP_SCALE = 'T' THEN
                '微型'
             END CORP_SCALE, --企业规模
             '',
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END LOAN_GRADE_CD, --五级分类
             NVL(C1.CORP_BUSINSESS_TYPE, C2.INDUSTRY_TYPE) AS CORP_BUSINSESS_TYPE, --行业分类
             A.LOAN_PURPOSE_CD,
             ''
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT D
          ON D.DATA_DATE = I_DATADATE
         AND A.ACCT_NUM = D.CONTRACT_NUM
        LEFT JOIN SMTMODS_L_CUST_ALL C --客户表
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C1 --对公客户表
          ON A.CUST_ID = C1.CUST_ID
         AND C1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C2 --个人客户表
          ON A.CUST_ID = C2.CUST_ID
         AND C2.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
            /* AND A.LOAN_PURPOSE_CD IN
            (SELECT CODE FROM PUB_KJDK WHERE FLAG = '5.1')*/
         AND (((A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%') AND
             A.ACCT_TYP NOT LIKE '0301%' AND
             SUBSTR(D.DIGITAL_ECONOMY_INDUSTRY, 1, 2) IN
             ('01', '02', '03', '04')) --SHIWENBO BY 20170316-12901 单独取直贴
             OR ((A.ITEM_CD LIKE '130101%' OR A.ITEM_CD LIKE '130104%') AND
             SUBSTR(A.DIGITAL_ECONOMY_INDUSTRY, 1, 2) IN
             ('01', '02', '03', '04'))) --[JLBA202507020013][20250729][石雨][于佳禾][按照NGI数据贷款类型取数]
      ;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '数字经济产业_中长期 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    

    INSERT INTO CBRC_A_REPT_DWD_S74
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --字段2(客户号)
       COL_3, --字段3(客户名)
       COL_4, --字段4(贷款编号)
       TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
       COL_6, --字段6(贷款合同编号)
       COL_7, --字段7（放款日期）
       COL_8, --字段8（原始到期日）
       COL_9, --字段9（个人客户类型（个体工商户 小微企业主 其他个人））
       COL_10, --字段10（企业规模）
       COL_11, --字段11（客户所属条线）
       COL_12, --字段12（五级分类）
       COL_13, --字段13（行业分类）
       COL_14, --字段14（贷款投向）
       COL_15 --字段15（数字经济核心产业贷款）
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S74' AS REP_NUM, --报表编号
             CASE
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '01' THEN
                'S74.1.1.D'
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '02' THEN
                'S74.1.2.D'
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '03' THEN
                'S74.1.3.D'
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '04' THEN
                'S74.1.4.D'
             END AS ITEM_NUM,
             A.CUST_ID,
             C.CUST_NAM,
             A.LOAN_NUM,
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS COLLECT_VAL, --汇总值
             A.ACCT_NUM,
             A.DRAWDOWN_DT,
             A.MATURITY_DT,
             '',
             CASE
               WHEN C1.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C1.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C1.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C1.CORP_SCALE = 'T' THEN
                '微型'
             END CORP_SCALE, --企业规模
             '',
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END LOAN_GRADE_CD, --五级分类
             NVL(C1.CORP_BUSINSESS_TYPE, C2.INDUSTRY_TYPE) AS CORP_BUSINSESS_TYPE, --行业分类
             A.LOAN_PURPOSE_CD,
             ''
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT D
          ON D.DATA_DATE = I_DATADATE
         AND A.ACCT_NUM = D.CONTRACT_NUM
        LEFT JOIN SMTMODS_L_CUST_ALL C --客户表
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C1 --对公客户表
          ON A.CUST_ID = C1.CUST_ID
         AND C1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C2 --个人客户表
          ON A.CUST_ID = C2.CUST_ID
         AND C2.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
            /*AND A.LOAN_PURPOSE_CD IN
            (SELECT CODE FROM PUB_KJDK WHERE FLAG = '5.1')*/
         AND (((A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%') AND
             A.ACCT_TYP NOT LIKE '0301%' AND
             SUBSTR(D.DIGITAL_ECONOMY_INDUSTRY, 1, 2) IN
             ('01', '02', '03', '04')) --SHIWENBO BY 20170316-12901 单独取直贴
             OR ((A.ITEM_CD LIKE '130101%' OR A.ITEM_CD LIKE '130104%') AND
             SUBSTR(A.DIGITAL_ECONOMY_INDUSTRY, 1, 2) IN
             ('01', '02', '03', '04'))) --[JLBA202507020013][20250729][石雨][于佳禾][按照NGI数据贷款类型取数]
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) > 12 --中长期
      ;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '数字经济产业_不良贷款 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    

    INSERT INTO CBRC_A_REPT_DWD_S74
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --字段2(客户号)
       COL_3, --字段3(客户名)
       COL_4, --字段4(贷款编号)
       TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
       COL_6, --字段6(贷款合同编号)
       COL_7, --字段7（放款日期）
       COL_8, --字段8（原始到期日）
       COL_9, --字段9（个人客户类型（个体工商户 小微企业主 其他个人））
       COL_10, --字段10（企业规模）
       COL_11, --字段11（客户所属条线）
       COL_12, --字段12（五级分类）
       COL_13, --字段13（行业分类）
       COL_14, --字段14（贷款投向）
       COL_15 --字段15（数字经济核心产业贷款）
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S74' AS REP_NUM, --报表编号
             CASE
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '01' THEN
                'S74.1.1.E'
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '02' THEN
                'S74.1.2.E'
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '03' THEN
                'S74.1.3.E'
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '04' THEN
                'S74.1.4.E'
             END AS ITEM_NUM,
             A.CUST_ID,
             C.CUST_NAM,
             A.LOAN_NUM,
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS COLLECT_VAL, --汇总值
             A.ACCT_NUM,
             A.DRAWDOWN_DT,
             A.MATURITY_DT,
             '',
             CASE
               WHEN C1.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C1.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C1.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C1.CORP_SCALE = 'T' THEN
                '微型'
             END CORP_SCALE, --企业规模
             '',
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END LOAN_GRADE_CD, --五级分类
             NVL(C1.CORP_BUSINSESS_TYPE, C2.INDUSTRY_TYPE) AS CORP_BUSINSESS_TYPE, --行业分类
             A.LOAN_PURPOSE_CD,
             ''
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT D
          ON D.DATA_DATE = I_DATADATE
         AND A.ACCT_NUM = D.CONTRACT_NUM
        LEFT JOIN SMTMODS_L_CUST_ALL C --客户表
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C1 --对公客户表
          ON A.CUST_ID = C1.CUST_ID
         AND C1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C2 --个人客户表
          ON A.CUST_ID = C2.CUST_ID
         AND C2.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
            /*AND A.LOAN_PURPOSE_CD IN
            (SELECT CODE FROM PUB_KJDK WHERE FLAG = '5.1')*/
            --[JLBA202507020013][20250729][石雨][于佳禾][按照NGI数据贷款类型取数]
         AND (((A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%') AND
             A.ACCT_TYP NOT LIKE '0301%' AND
             SUBSTR(D.DIGITAL_ECONOMY_INDUSTRY, 1, 2) IN
             ('01', '02', '03', '04')) --SHIWENBO BY 20170316-12901 单独取直贴
             OR ((A.ITEM_CD LIKE '130101%' OR A.ITEM_CD LIKE '130104%') AND
             SUBSTR(A.DIGITAL_ECONOMY_INDUSTRY, 1, 2) IN
             ('01', '02', '03', '04')))
         AND A.LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款
      ;

    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '数字经济产业_累放收益 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    

    INSERT INTO CBRC_A_REPT_DWD_S74
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --字段2(客户号)
       COL_3, --字段3(客户名)
       COL_4, --字段4(贷款编号)
       TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
       COL_6, --字段6(贷款合同编号)
       COL_7, --字段7（放款日期）
       COL_8, --字段8（原始到期日）
       COL_9, --字段9（个人客户类型（个体工商户 小微企业主 其他个人））
       COL_10, --字段10（企业规模）
       COL_11, --字段11（客户所属条线）
       COL_12, --字段12（五级分类）
       COL_13, --字段13（行业分类）
       COL_14, --字段14（贷款投向）
       COL_15 --字段15（数字经济核心产业贷款）
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构号
             T.DEPARTMENTD, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S74' AS REP_NUM, --报表编号
             CASE
               WHEN DIGITAL_ECONOMY_INDUSTRY = '01' THEN
                'S74.1.1.F'
               WHEN DIGITAL_ECONOMY_INDUSTRY = '02' THEN
                'S74.1.2.F'
               WHEN DIGITAL_ECONOMY_INDUSTRY = '03' THEN
                'S74.1.3.F'
               WHEN DIGITAL_ECONOMY_INDUSTRY = '04' THEN
                'S74.1.4.F'
             END AS ITEM_NUM,
             T.CUST_ID,
             T.CUST_NAM,
             T.LOAN_NUM,
             NVL(T.NHSY, 0) * B.CCY_RATE AS COLLECT_VAL, --汇总值
             T.ACCT_NUM,
             T.DRAWDOWN_DT,
             T.MATURITY_DT,
             '',
             T.CORP_SCALE,
             '',
             T.LOAN_GRADE_CD,
             T.CORP_BUSINSESS_TYPE,
             T.LOAN_PURPOSE_CD,
             ''
        FROM CBRC_S74_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON T.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE SUBSTR(T.DATA_DATE, 1, 4) = SUBSTR(I_DATADATE, 1, 4)
            /*    AND t.LOAN_PURPOSE_CD IN
            (SELECT CODE FROM PUB_KJDK WHERE FLAG = '5.1')*/
         AND T.DIGITAL_ECONOMY_INDUSTRY IN ('01', '02', '03', '04') --[JLBA202507020013][20250729][石雨][于佳禾][按照NGI数据贷款类型取数]
      ;
    COMMIT;

    --明细汇总

    --end 明细需求 zhangyq20250815

    ------------------------ S74第II部分：金融服务数字化转型---------------------------------------

    -- 3.个人客户数量   4.法人客户数量
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
             'S74' AS REP_NUM, --报表编号
             'S74.4..A' AS ITEM_NUM,
             COUNT(*), --指标值
             '2' AS FLAG
        FROM CBRC_S74_CUST_INFO_JRFUSZHZX T
       WHERE T.CUST_TYPE = '1' -- 1 对公
         AND T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM;

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
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S74' AS REP_NUM, --报表编号
             'S74.3..A' AS ITEM_NUM,
             COUNT(*), --指标值
             '2' AS FLAG
        FROM CBRC_S74_CUST_INFO_JRFUSZHZX T
       WHERE T.CUST_TYPE = '2' -- 2 个人
         AND DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM;

    COMMIT;

    V_STEP_FLAG := 2;
    V_STEP_DESC := '个人客户数量,法人客户数量';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_S74_DIGITAL_TRANS_SERVICES 
      (REFERENCE_NUM,
       ACCOUNT_CODE,
       TRANS_AMT,
       TX_DT,
       ORG_NUM,
       CHANNEL,
       DATA_SOURCE,
       CUST_ID)
      SELECT 
       substr(REFERENCE_NUM, 1, 8) AS REFERENCE_NUM,
       ACCOUNT_CODE,
       TRANS_AMT,
       TX_DT,
       ORG_NUM,
       SUBSTR(SERIAL_NO, 1, 4) AS CHANNEL, -- 全局流水号
       '交易信息表' AS DATA_SOURCE,
       CUST_ID
        FROM SMTMODS_L_TRAN_TX T
       WHERE DATA_DATE >=
             TO_CHAR(ADD_MONTHS(DATE(I_DATADATE, 'YYYYMMDD'), -3) + 1,
                     'YYYYMMDD') --SUBSTR(I_DATADATE,1,4) ||'0101'
         AND DATA_DATE <=
             TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYYMMDD');
    COMMIT;

    V_STEP_FLAG := 5;
    V_STEP_DESC := '总业务笔数L_TRAN_TX三个月';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -- 找到 资金交易，不在交易信息表中的数据
    INSERT 
    INTO CBRC_S74_DIGITAL_TRANS_SERVICES 
      (REFERENCE_NUM,
       ACCOUNT_CODE,
       TRANS_AMT,
       TX_DT,
       CHANNEL,
       DATA_SOURCE,
       CUST_ID)
      SELECT
       SUBSTR(T.REF_NUM, 1, 8),
       T.CONTRACT_NUM,
       T.AMOUNT,
       T.TRAN_DT,
       T.CHANNEL, --交易渠道
       '资金交易表' AS DATA_SOURCE,
       '' AS CUST_ID
        FROM SMTMODS_L_TRAN_FUND_FX T
        LEFT JOIN SMTMODS_L_TRAN_TX T1
          ON SUBSTR(T.REF_NUM, 1, 8) = SUBSTR(T1.REFERENCE_NUM, 1, 8)
         AND T1.ACCOUNT_CODE = T.CONTRACT_NUM
         AND T.DATA_DATE = T1.DATA_DATE
         AND T.AMOUNT = T1.TRANS_AMT
       WHERE ((T.PRODUCT_NAME IS NULL AND T1.ACCOUNT_CODE IS NULL) OR
             T.PRODUCT_NAME IS NOT NULL)
         AND T.DATA_DATE >=
             TO_CHAR(ADD_MONTHS(DATE(I_DATADATE, 'YYYYMMDD'), -3) + 1,
                     'YYYYMMDD')
         AND T.DATA_DATE <=
             TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYYMMDD');
    COMMIT;

    V_STEP_FLAG := 6;
    V_STEP_DESC := '总业务笔数L_TRAN_FUND_FX三个月';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_S74_DIGITAL_TRANS_SERVICES 
      (REFERENCE_NUM,
       ACCOUNT_CODE,
       TRANS_AMT,
       TX_DT,
       CHANNEL,
       DATA_SOURCE,
       CUST_ID)
      SELECT 
       substr(REF_NUM, 1, 8),
       ACCT_NUM,
       AMT,
       TRAN_DATE,
       SELLING_CHANNEL, -- 销售渠道
       '代理代销交易表' AS DATA_SOURCE,
       T.CUST_ID
        FROM SMTMODS_L_TRAN_FINANCE_FUND T
       WHERE DATA_DATE >=
             TO_CHAR(ADD_MONTHS(DATE(I_DATADATE, 'YYYYMMDD'), -3) + 1,
                     'YYYYMMDD')
         AND DATA_DATE <=
             TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYYMMDD');
    COMMIT;

    V_STEP_FLAG := 7;
    V_STEP_DESC := '总业务笔数L_TRAN_FINANCE_FUND三个月';
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
             'S74' AS REP_NUM, --报表编号
             'S74.6..A' AS ITEM_NUM,
             COUNT(*), --指标值
             '2' AS FLAG
        FROM (SELECT REFERENCE_NUM, ACCOUNT_CODE, TRANS_AMT, TX_DT, ORG_NUM
                FROM CBRC_S74_DIGITAL_TRANS_SERVICES) T
       GROUP BY T.ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 8;
    V_STEP_DESC := '总业务笔数';
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
             'S74' AS REP_NUM, --报表编号
             'S74.6.1.A' AS ITEM_NUM,
             COUNT(*), --指标值
             '2' AS FLAG
        FROM (SELECT REFERENCE_NUM,
                     ACCOUNT_CODE,
                     TRANS_AMT,
                     TX_DT,
                     ORG_NUM,
                     CHANNEL
                FROM CBRC_S74_DIGITAL_TRANS_SERVICES
               WHERE CHANNEL IN ('EFSM',
                                 'JLBW',
                                 'JMBK',
                                 'WXIN',
                                 'NBKJ',
                                 'EIBK',
                                 'STIJ',
                                 'SMKS',
                                 '1',
                                 '2',
                                 '3',
                                 '4',
                                 'B',
                                 'D',
                                 'E')) T
       GROUP BY T.ORG_NUM;

    -- 6.1.其中：线上业务笔数
    V_STEP_FLAG := 9;
    V_STEP_DESC := '其中：线上业务笔数';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -- 3.1其中：开通移动端银行业务的客户数量   4.1其中：开通移动端银行业务的客户数量

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
             'S74' AS REP_NUM, --报表编号
             'S74.3.1.A' AS ITEM_NUM,
             COUNT(*), --指标值
             '2' AS FLAG
        FROM (SELECT T.CUST_ID, T.ORG_NUM
                FROM CBRC_S74_DIGITAL_TRANS_SERVICES T
                LEFT JOIN SMTMODS_L_CUST_C T1
                  ON T.CUST_ID = T1.CUST_ID
                 AND T1.DATA_DATE = I_DATADATE
                 AND T1.CUST_TYP <> '3'
               WHERE CHANNEL IN ('JLBW', 'JMBK', 'WXIN', 'NBKJ', 'EIBK')
                 AND T1.CUST_ID IS NULL
               GROUP BY T.CUST_ID, T.ORG_NUM) T
       GROUP BY T.ORG_NUM;

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
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S74' AS REP_NUM, --报表编号
             'S74.4.1.A' AS ITEM_NUM,
             COUNT(*), --指标值
             '2' AS FLAG
        FROM (SELECT T.CUST_ID, T.ORG_NUM
                FROM CBRC_S74_DIGITAL_TRANS_SERVICES T
               INNER JOIN SMTMODS_L_CUST_C T1
                  ON T.CUST_ID = T1.CUST_ID
                 AND T1.DATA_DATE = I_DATADATE
                 AND T1.CUST_TYP <> '3'
               WHERE CHANNEL IN ('JLBW', 'JMBK', 'WXIN', 'NBKJ', 'EIBK')
               GROUP BY T.CUST_ID, T.ORG_NUM) T
       GROUP BY T.ORG_NUM;

    COMMIT;

    --插入结果表
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '插入结果表CBRC_A_REPT_ITEM_VAL';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       ITEM_VAL,
       DATA_DEPARTMENT,
       FLAG)
      SELECT T.DATA_DATE,
             T.ORG_NUM,
             T.SYS_NAM,
             T.REP_NUM,
             T.ITEM_NUM,
             SUM(TOTAL_VALUE) AS ITEM_VAL,
             T.DATA_DEPARTMENT,
             '2' AS FLAG
        FROM CBRC_A_REPT_DWD_S74 T
       GROUP BY T.DATA_DATE,
                T.ORG_NUM,
                T.SYS_NAM,
                T.REP_NUM,
                T.ITEM_NUM,
                DATA_DEPARTMENT;
    COMMIT;

    V_STEP_FLAG := V_STEP_ID + 1;
    V_STEP_DESC := 'S74 逻辑处理完成';
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
   
END proc_cbrc_idx2_s74