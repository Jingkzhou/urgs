CREATE OR REPLACE PROCEDURE PROC_CBRC_IDX2_G5305 (II_DATADATE IN STRING --跑批日期
                                              )
/******************************
  @AUTHOR:SHIYU
  @CREATE-DATE:20220228
  @DESCRIPTION:G5305
  m0 .shiyu  20220704  1.3项口径修改为:农户标志为Y OR 是家庭农场 or 农民合作社 or 农业产业化龙头企业
  m1. 20221117 授信额度剔除磐石机构下的授信额度
  m2. 20230828 shiyu 修改内容：单位客户及单位名称的个体工商户取客户授信协议金额，不考虑授信协议状态，自然人客户取客户合同金额合计
  m3. 20240227 shiyu 修改内容：修改农户取数规则，参考大集中逻辑
  M4. 20240228  修改内容：1.3农户及新型农业经营主体：
  需求编号：JLBA202503070010_关于吉林银行统一监管报送平台升级的需求 上线日期： 2025-12-26，修改人：狄家卉，提出人：统一监管报送平台升级  修改原因：由汇总数据修改为明细以及汇总

目标表：CBRC_A_REPT_ITEM_VAL
码值表：CBRC_FINANCE_COMPANY_LIST 
临时表：CBRC_A_REPT_DWD_G5305
     CBRC_G5305_CREDITLINE_HZ
     CBRC_G5305_GUAR_TEMP
     CBRC_G5305_GUAR_TEMP1
     CBRC_UPRR_U_BASE_INST
集市表：SMTMODS_L_ACCT_LOAN
     SMTMODS_L_ACCT_LOAN_FARMING
     SMTMODS_L_AGRE_GUARANTEE_CONTRACT
     SMTMODS_L_AGRE_GUARANTEE_RELATION
     SMTMODS_L_AGRE_GUA_RELATION
     SMTMODS_L_AGRE_LOAN_CONTRACT
     SMTMODS_L_CUST_C
     SMTMODS_L_CUST_P
     SMTMODS_L_PUBL_RATE
     SMTMODS_L_TRAN_LOAN_PAYM
视图： SMTMODS_V_PUB_IDX_DK_GRSNDK
    SMTMODS_V_PUB_IDX_DK_GTGSHSNDK
    SMTMODS_V_PUB_IDX_SX_PHJRDKSX

  *******************************/

 IS
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE    VARCHAR(30); --当前储存过程名称
  V_TAB_NAME     VARCHAR(30); --目标表名
  I_DATADATE     STRING; --数据日期(数值型)YYYYMMDD
  D_DATADATE_CCY STRING; --数据日期(日期型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  NUM            INTEGER;
  NEXTDATE       VARCHAR2(10);
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_ERRORDESC    VARCHAR(280); --错误内容
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
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

    I_DATADATE  := II_DATADATE;
    NEXTDATE := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD') + 1, 'YYYYMMDD');
    V_SYSTEM    := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G5305');
    V_TAB_NAME     := 'G5305';
    D_DATADATE_CCY := I_DATADATE;

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']G5305当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --删除当期数据

    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'G5305'
       AND T.FLAG = '2';
    COMMIT;

    -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_A_REPT_DWD_G5305';

    --删除临时表

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G5305_CREDITLINE_TMP1';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G5305_CREDITLINE_TMP2';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G5305_CREDITLINE_HZ';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G5305_GUAR_TEMP';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G5305_GUAR_TEMP1';

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := 1;
    V_STEP_DESC := '加工授信至G5305_CREDITLINE_HZ中间表';
    V_STEP_FLAG := 0;

     INSERT INTO CBRC_G5305_CREDITLINE_HZ
       (CUST_ID, FACILITY_AMT, DATA_DATE)
       SELECT CUST_ID, FACILITY_AMT, DATA_DATE
         FROM SMTMODS_V_PUB_IDX_SX_PHJRDKSX
        WHERE DATA_DATE = I_DATADATE;
     COMMIT;

    V_STEP_ID   := 1;
    V_STEP_DESC := '加工担保融资公司对应合同至G5305_GUAR_TEMP中间表';
    V_STEP_FLAG := 0;

    --担保融资公司对应的贷款合同号
      INSERT INTO CBRC_G5305_GUAR_TEMP
        (GUAR_CUST_ID,
         GUARANTEE_NAME,
         GUAR_CONTRACT_NUM,
         CONTRACT_NUM,
         GUARANTY_TYPE)
        SELECT
       
        DISTINCT F1.GUAR_CUST_ID, --担保客户号
                 F1.GUARANTEE_NAME, --担保人名称
                 F1.GUAR_CONTRACT_NUM, --担保合同号
                 B.CONTRACT_NUM, --贷款合同号
                 CASE
                   WHEN L.GOV_FLG = 'Y' THEN
                    'C01'
                   ELSE
                    'C02'
                 END --担保人类型（A 政府   B 投资子公司  C 担保公司  C01 政府性融资担保公司  C02 其他担保公司  Z 其他）
          FROM SMTMODS_L_AGRE_GUARANTEE_RELATION F1 --担保合同与担保信息对应关系表
          LEFT JOIN SMTMODS_L_AGRE_GUARANTEE_CONTRACT F --担保合同表
            ON F.GUAR_CONTRACT_NUM = F1.GUAR_CONTRACT_NUM
           AND F.DATA_DATE = I_DATADATE
          LEFT JOIN SMTMODS_L_AGRE_GUA_RELATION E --业务合同与担保合同对应关系表 E
            ON E.GUAR_CONTRACT_NUM = F.GUAR_CONTRACT_NUM
           AND E.DATA_DATE = I_DATADATE
          LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT B --贷款合同信息表 B
            ON B.CONTRACT_NUM = E.CONTRACT_NUM
           AND B.DATA_DATE = I_DATADATE
         INNER JOIN CBRC_finance_company_list L
            ON TRIM(F1.GUARANTEE_NAME) = TRIM(L.COMPANY_NAME)
         WHERE F1.DATA_DATE = I_DATADATE
           AND F.GUAR_CONTRACT_STATUS = 'Y' --担保合同有效状态
              --AND B.MAIN_GUARANTY_TYP = '2' --主要担保方式:保证
           AND B.ACCT_STS = '1'; --合同状态：1有效

    COMMIT;

    V_STEP_ID   := 1;
    V_STEP_DESC := '加工融资担保公司贷款至G5305_GUAR_TEMP1中间表';
    V_STEP_FLAG := 0;


      --融资担保公司贷款临时表
      INSERT INTO CBRC_G5305_GUAR_TEMP1
        (DATA_DATE,
         ORG_NUM,
         LOAN_NUM,
         ACCT_NUM,
         CUST_ID,
         LOAN_ACCT_BAL,
         LOAN_GRADE_CD,
         GENERALIZE_LOAN_FLG,
         NON_COMPENSE_BAL_RMB,
         OD_DAYS,
         OPERATE_CUST_TYPE,
         CUST_TYP,
         CORP_SCALE,
         GUARANTY_TYPE,
         ACCT_TYP,
         FLAG)
        SELECT  
               I_DATADATE,
               T.ORG_NUM, --机构号
               T.LOAN_NUM, --借据号
               T.ACCT_NUM, --合同号
               T.CUST_ID, --客户号
               T.LOAN_ACCT_BAL * TT.CCY_RATE AS LOAN_ACCT_BAL, --贷款余额
               T.LOAN_GRADE_CD, --五级分类你
               CASE
                 WHEN Z.FACILITY_AMT <= 10000000 THEN
                  'Y'
                 ELSE
                  'N'
               END GENERALIZE_LOAN_FLG, --普惠型贷款标志
               T.NON_COMPENSE_BAL_RMB, --未履约担保余额_人民币
               T.OD_DAYS, --逾期天数
               P.OPERATE_CUST_TYPE, --个人经营性类型
               C.CUST_TYP, --对公客户客户分类
               C.CORP_SCALE, --企业规模
               A.GUARANTY_TYPE, --担保人类型
               T.ACCT_TYP, --账户类型
               CASE
                 WHEN NH.LOAN_NUM is not null --农户
                     -- OR C.AGRICLTURAL_MANAGE_TYPE <> 'Z' --农业经营主体类型
                     --注释M4
                      OR F.COOP_LAON_FLAG = 'Y' ---农民合作社贷款标志
                      OR P.CONTRACT_FARMER_TYPE = 'A' --家庭农场
                      OR nvl(c.AGRICLTURAL_MANAGE_TYPE, 'Z') in
                      ('A', 'B', 'C', 'D', 'E', 'F', 'G')
                 --农业经营主体类型A  家庭农场B  农业产业化龙头企业C  农民专业合作社D  同时为家庭农场和农业产业化龙头企业E  同时为家庭农场和农民专业合作社F  同时为农业产业化龙头企业和农民专业合作社G  三者皆认定Z  其他类型
                  THEN
                  'Y'
                 ELSE
                  'N'
               END AS FLAG --农户及新型农业经营主体贷款( 农户标志='Y' or 个人经济主体类型<>'Z' or农业经营主体类型<>'Z' or c.客户分类='0' )
          FROM SMTMODS_L_ACCT_LOAN T
          LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
            ON TT.CCY_DATE = I_DATADATE
           AND TT.BASIC_CCY = T.CURR_CD
           AND TT.FORWARD_CCY = 'CNY'
          LEFT JOIN SMTMODS_L_CUST_P P
            ON T.CUST_ID = P.CUST_ID
           AND P.DATA_DATE = I_DATADATE
          LEFT JOIN SMTMODS_L_CUST_C C
            ON C.CUST_ID = T.CUST_ID
           AND C.DATA_DATE = I_DATADATE
          LEFT JOIN (select *
                       from (SELECT CONTRACT_NUM,
                                    GUARANTY_TYPE,
                                    ROW_NUMBER() OVER(PARTITION BY CONTRACT_NUM ORDER BY GUARANTY_TYPE) RN

                               FROM (SELECT CONTRACT_NUM, GUARANTY_TYPE
                                       FROM CBRC_G5305_GUAR_TEMP
                                      GROUP BY CONTRACT_NUM, GUARANTY_TYPE)) aa
                      WHERE aa.RN = 1) A
            ON T.ACCT_NUM = A.CONTRACT_NUM
          LEFT JOIN CBRC_G5305_CREDITLINE_HZ Z
            ON T.CUST_ID = Z.CUST_ID
           AND Z.DATA_DATE = I_DATADATE
        ---M3.农户贷款
          LEFT JOIN (SELECT *
                       FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款 SMTMODS_V_PUB_IDX_DK_GRSNDK
                      WHERE T.DATA_DATE = I_DATADATE
                        AND SUBSTR(T.SNDKFL, 1, 5) IN
                            ('P_101', 'P_102', 'P_103')
                     UNION ALL
                     SELECT *
                       FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                      WHERE T.DATA_DATE = I_DATADATE
                        AND SUBSTR(T.SNDKFL, 1, 5) IN
                            ('P_101', 'P_102', 'P_103')) NH
            ON NH.LOAN_NUM = T.LOAN_NUM
          LEFT JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充
        --   ACCT_LOAN_FARMING_FULL F --涉农新的全量表 add by  zy
            ON F.DATA_DATE = I_DATADATE
           AND T.LOAN_NUM = F.LOAN_NUM
         WHERE T.DATA_DATE = I_DATADATE
           AND T.ACCT_STS <> '3' --账户状态
           AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
           AND A.GUARANTY_TYPE LIKE 'C%'
           AND T.Cancel_Flg <> 'Y' --剔除核销    20221010
           AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
           AND EXISTS (SELECT 1
                  FROM CBRC_G5305_GUAR_TEMP A
                 WHERE A.CONTRACT_NUM = T.ACCT_NUM);
    COMMIT;
    ----------------------加工G5305指标------------------------------
    V_STEP_ID   := 1;
    V_STEP_DESC := '加工1.由融资担保机构提供担保的贷款余额至A_REPT_DWD_G5305表';
    V_STEP_FLAG := 0;

    --1.由融资担保机构提供担保的贷款余额

    INSERT INTO CBRC_A_REPT_DWD_G5305 
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT,--数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE,-- 汇总值
       COL_1, --客户号
       COL_2, --客户名
       COL_3, --贷款编号
       COL_4, --贷款合同编号
       COL_7, --原始到期日
       COL_8, --科目号
       COL_10, --企业规模
       COL_15, --主要担保方式
       COL_16)  --贷款产品名称
      SELECT 
             I_DATADATE AS DATA_DATE, --数据日期
             T.ORG_NUM AS ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'G5305' AS REP_NUM, --报表编号
             CASE WHEN SUBSTR(T.ORG_NUM,1,2) IN ('55','56') THEN 'G53_5_1..D'
                  WHEN SUBSTR(T.ORG_NUM,1,2) = '52' THEN 'G53_5_1..K'
                  WHEN SUBSTR(T.ORG_NUM,1,2) IN ('10', '11') THEN 'G53_5_1..G'
                  ELSE 'G53_5_1..H'
             END AS ITEM_NUM, --指标号
             T.LOAN_ACCT_BAL AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             C.CUST_NAM AS COL_2, --客户名
             T.LOAN_NUM AS COL_3, --贷款编号
             T.ACCT_NUM AS COL_4, --贷款合同编号
             A.MATURITY_DT AS COL_7, --原始到期日
             A.ITEM_CD AS COL_8, --科目号
             CASE WHEN C.CORP_SCALE = 'B' THEN '大型'
                  WHEN C.CORP_SCALE = 'M' THEN '中型'
                  WHEN C.CORP_SCALE = 'S' THEN '小型'
                  WHEN C.CORP_SCALE = 'T' THEN '微型'
             END AS COL_10, --企业规模
             A.GUARANTY_TYP AS COL_15, --主要担保方式
             A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_G5305_GUAR_TEMP1 T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.DATA_DATE = I_DATADATE
         AND C.CUST_ID = T.CUST_ID
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL > 0;
    COMMIT;

    V_STEP_ID   := 1;
    V_STEP_DESC := '加工1.1用于小微企业贷款余额（含小微企业主和个体工商户）至A_REPT_DWD_G5305表';
    V_STEP_FLAG := 0;

    -- 1.1用于小微企业贷款余额（含小微企业主和个体工商户）
    INSERT INTO CBRC_A_REPT_DWD_G5305 
     (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT,--数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE,-- 汇总值
       COL_1, --客户号
       COL_2, --客户名
       COL_3, --贷款编号
       COL_4, --贷款合同编号
       COL_7, --原始到期日
       COL_8, --科目号
       COL_10, --企业规模
       COL_15, --主要担保方式
       COL_16)  --贷款产品名称
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             T.ORG_NUM AS ORG_NUM, --机构号
              A.DEPARTMENTD AS DATA_DEPARTMENT, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'G5305' AS REP_NUM, --报表编号
             CASE WHEN SUBSTR(T.ORG_NUM,1,2) IN ('55','56') THEN 'G53_5_1.1.D'
                  WHEN SUBSTR(T.ORG_NUM,1,2) = '52' THEN 'G53_5_1.1.K'
               WHEN substr(T.ORG_NUM,1,2) IN ('10', '11') THEN 'G53_5_1.1.G'
               ELSE 'G53_5_1.1.H'
             END AS ITEM_NUM, --指标号
             T.LOAN_ACCT_BAL AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             C.CUST_NAM AS COL_2, --客户名
             T.LOAN_NUM AS COL_3, --贷款编号
             T.ACCT_NUM AS COL_4, --贷款合同编号
             A.MATURITY_DT AS COL_7, --原始到期日
             A.ITEM_CD AS COL_8, --科目号
             CASE WHEN C.CORP_SCALE = 'B' THEN '大型'
                  WHEN C.CORP_SCALE = 'M' THEN '中型'
                  WHEN C.CORP_SCALE = 'S' THEN '小型'
                  WHEN C.CORP_SCALE = 'T' THEN '微型'
             END AS COL_10, --企业规模
             A.GUARANTY_TYP AS COL_15, --主要担保方式
             A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_G5305_GUAR_TEMP1 T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
          AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.DATA_DATE = I_DATADATE
         AND C.CUST_ID = T.CUST_ID
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL > 0
         AND ((T.CORP_SCALE IN ('S', 'T') /*小微企业*/
             AND SUBSTR(T.CUST_TYP, 1, 1) IN ('1', '0')) OR
             ((T.ACCT_TYP LIKE '0102%' /*个人经营性*/
             OR T.ACCT_TYP LIKE '03%') --票据融资
             AND (T.OPERATE_CUST_TYPE IN ('A', 'B') OR T.CUST_TYP='3'))); --个体工商户、小微企业主
    COMMIT;


    V_STEP_ID   := 1;
    V_STEP_DESC := '加工1.1.1普惠型小微企业贷款（单户1000万元以下）至A_REPT_DWD_G5305表';
    V_STEP_FLAG := 0;
    -- 1.1.1普惠型小微企业贷款（单户1000万元以下）

    INSERT INTO CBRC_A_REPT_DWD_G5305 
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT,--数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE,-- 汇总值
       COL_1, --客户号
       COL_2, --客户名
       COL_3, --贷款编号
       COL_4, --贷款合同编号
       COL_7, --原始到期日
       COL_8, --科目号
       COL_10, --企业规模
       COL_15, --主要担保方式
       COL_16)  --贷款产品名称
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             T.ORG_NUM AS ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'G5305' AS REP_NUM, --报表编号
             CASE WHEN SUBSTR(T.ORG_NUM,1,2) IN ('55','56') THEN 'G53_5_1.1.1.D'
                  WHEN SUBSTR(T.ORG_NUM,1,2) = '52' THEN 'G53_5_1.1.1.K'
               WHEN substr(T.ORG_NUM,1,2) IN ('10', '11') THEN 'G53_5_1.1.1.G'
               ELSE 'G53_5_1.1.1.H'
             END AS ITEM_NUM, --指标号
             T.LOAN_ACCT_BAL AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             C.CUST_NAM AS COL_2, --客户名
             T.LOAN_NUM AS COL_3, --贷款编号
             T.ACCT_NUM AS COL_4, --贷款合同编号
             A.MATURITY_DT AS COL_7, --原始到期日
             A.ITEM_CD AS COL_8, --科目号
             CASE WHEN C.CORP_SCALE = 'B' THEN '大型'
                  WHEN C.CORP_SCALE = 'M' THEN '中型'
                  WHEN C.CORP_SCALE = 'S' THEN '小型'
                  WHEN C.CORP_SCALE = 'T' THEN '微型'
             END AS COL_10, --企业规模
             A.GUARANTY_TYP AS COL_15, --主要担保方式
             A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_G5305_GUAR_TEMP1 T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
          AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.DATA_DATE = I_DATADATE
         AND C.CUST_ID = T.CUST_ID
        LEFT JOIN CBRC_G5305_CREDITLINE_HZ T1
          ON T.CUST_ID = T1.CUST_ID
         AND T1.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND ((T.CORP_SCALE IN ('S', 'T') /*小微企业*/
             AND SUBSTR(T.CUST_TYP, 1, 1) IN ('1', '0')) OR
             ((T.ACCT_TYP LIKE '0102%' /*个人经营性*/
             OR T.ACCT_TYP LIKE '03%') --票据融资
             AND (T.OPERATE_CUST_TYPE IN ('A', 'B') OR T.CUST_TYP='3'))) --个体工商户、小微企业主
         AND T1.FACILITY_AMT <= 10000000 --授信额度小于1000万及以下
         AND T.GENERALIZE_LOAN_FLG = 'Y' --普惠型贷款标志
         AND T.LOAN_ACCT_BAL > 0;
    COMMIT;


    V_STEP_ID   := 1;
    V_STEP_DESC := '加工1.2政府性融资担保机构担保的贷款余额至A_REPT_DWD_G5305表';
    V_STEP_FLAG := 0;
    -- 1.2政府性融资担保机构担保的贷款余额

    INSERT INTO CBRC_A_REPT_DWD_G5305 
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT,--数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE,-- 汇总值
       COL_1, --客户号
       COL_2, --客户名
       COL_3, --贷款编号
       COL_4, --贷款合同编号
       COL_7, --原始到期日
       COL_8, --科目号
       COL_10, --企业规模
       COL_15, --主要担保方式
       COL_16)  --贷款产品名称
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             T.ORG_NUM AS ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'G5305' AS REP_NUM, --报表编号
             CASE WHEN SUBSTR(T.ORG_NUM,1,2) IN ('55','56') THEN 'G53_5_1.2.D'
                  WHEN SUBSTR(T.ORG_NUM,1,2) = '52' THEN 'G53_5_1.2.K'
                  WHEN substr(T.ORG_NUM,1,2) IN ('10', '11') THEN 'G53_5_1.2.G'
               ELSE 'G53_5_1.2.H'
             END AS ITEM_NUM, --指标号
             T.LOAN_ACCT_BAL AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             C.CUST_NAM AS COL_2, --客户名
             T.LOAN_NUM AS COL_3, --贷款编号
             T.ACCT_NUM AS COL_4, --贷款合同编号
             A.MATURITY_DT AS COL_7, --原始到期日
             A.ITEM_CD AS COL_8, --科目号
             CASE WHEN C.CORP_SCALE = 'B' THEN '大型'
                  WHEN C.CORP_SCALE = 'M' THEN '中型'
                  WHEN C.CORP_SCALE = 'S' THEN '小型'
                  WHEN C.CORP_SCALE = 'T' THEN '微型'
             END AS COL_10, --企业规模
             A.GUARANTY_TYP AS COL_15, --主要担保方式
             A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_G5305_GUAR_TEMP1 T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
          AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.DATA_DATE = I_DATADATE
         AND C.CUST_ID = T.CUST_ID
       WHERE T.DATA_DATE = I_DATADATE
         AND T.GUARANTY_TYPE = 'C01' --担保人类型：政府性融资担保机构
         AND T.LOAN_ACCT_BAL > 0;
    COMMIT;


    V_STEP_ID   := 1;
    V_STEP_DESC := '加工1.2.1政府性融资担保机构担保的小微企业贷款余额至A_REPT_DWD_G5305表';
    V_STEP_FLAG := 0;
    -- 1.2.1政府性融资担保机构担保的小微企业贷款余额

    INSERT INTO CBRC_A_REPT_DWD_G5305 
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT,--数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE,-- 汇总值
       COL_1, --客户号
       COL_2, --客户名
       COL_3, --贷款编号
       COL_4, --贷款合同编号
       COL_7, --原始到期日
       COL_8, --科目号
       COL_10, --企业规模
       COL_15, --主要担保方式
       COL_16)  --贷款产品名称
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             T.ORG_NUM AS ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'G5305' AS REP_NUM, --报表编号
             CASE WHEN SUBSTR(T.ORG_NUM,1,2) IN ('55','56') THEN 'G53_5_1.2.1.D'
                  WHEN SUBSTR(T.ORG_NUM,1,2) = '52' THEN 'G53_5_1.2.1.K'
                  WHEN substr(T.ORG_NUM,1,2) IN ('10', '11') THEN 'G53_5_1.2.1.G'
               ELSE 'G53_5_1.2.1.H'
             END AS ITEM_NUM, --指标号
             T.LOAN_ACCT_BAL AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             C.CUST_NAM AS COL_2, --客户名
             T.LOAN_NUM AS COL_3, --贷款编号
             T.ACCT_NUM AS COL_4, --贷款合同编号
             A.MATURITY_DT AS COL_7, --原始到期日
             A.ITEM_CD AS COL_8, --科目号
             CASE WHEN C.CORP_SCALE = 'B' THEN '大型'
                  WHEN C.CORP_SCALE = 'M' THEN '中型'
                  WHEN C.CORP_SCALE = 'S' THEN '小型'
                  WHEN C.CORP_SCALE = 'T' THEN '微型'
             END AS COL_10, --企业规模
             A.GUARANTY_TYP AS COL_15, --主要担保方式
             A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_G5305_GUAR_TEMP1 T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
          AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.DATA_DATE = I_DATADATE
         AND C.CUST_ID = T.CUST_ID
       WHERE T.DATA_DATE = I_DATADATE
         AND ((T.CORP_SCALE IN ('S', 'T') /*小微企业*/
             AND SUBSTR(T.CUST_TYP, 1, 1) IN ('1', '0')) OR
             ((T.ACCT_TYP LIKE '0102%' /*个人经营性*/
             OR T.ACCT_TYP LIKE '03%') --票据融资
             AND (T.OPERATE_CUST_TYPE IN ('A', 'B') OR T.CUST_TYP='3'))) --个体工商户、小微企业主
         /*小微企业*/
         AND T.GUARANTY_TYPE = 'C01' --担保人类型：政府性融资担保机构
         AND T.LOAN_ACCT_BAL > 0;
    COMMIT;

    V_STEP_ID   := 1;
    V_STEP_DESC := '加工1.2.1.1政府性融资担保机构担保的普惠型小微企业贷款余额至A_REPT_DWD_G5305表';
    V_STEP_FLAG := 0;

    ---1.2.1.1政府性融资担保机构担保的普惠型小微企业贷款余额

    INSERT INTO CBRC_A_REPT_DWD_G5305 
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT,--数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE,-- 汇总值
       COL_1, --客户号
       COL_2, --客户名
       COL_3, --贷款编号
       COL_4, --贷款合同编号
       COL_7, --原始到期日
       COL_8, --科目号
       COL_10, --企业规模
       COL_15, --主要担保方式
       COL_16)  --贷款产品名称
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             T.ORG_NUM AS ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'G5305' AS REP_NUM, --报表编号
             CASE WHEN SUBSTR(T.ORG_NUM,1,2) IN ('55','56') THEN 'G53_5_1.2.1.1.D'
                  WHEN SUBSTR(T.ORG_NUM,1,2) = '52' THEN 'G53_5_1.2.1.1.K'
                  WHEN substr(T.ORG_NUM,1,2) IN ('10', '11') THEN 'G53_5_1.2.1.1.G'
               ELSE 'G53_5_1.2.1.1.H'
             END AS ITEM_NUM, --指标号
             T.LOAN_ACCT_BAL AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             C.CUST_NAM AS COL_2, --客户名
             T.LOAN_NUM AS COL_3, --贷款编号
             T.ACCT_NUM AS COL_4, --贷款合同编号
             A.MATURITY_DT AS COL_7, --原始到期日
             A.ITEM_CD AS COL_8, --科目号
             CASE WHEN C.CORP_SCALE = 'B' THEN '大型'
                  WHEN C.CORP_SCALE = 'M' THEN '中型'
                  WHEN C.CORP_SCALE = 'S' THEN '小型'
                  WHEN C.CORP_SCALE = 'T' THEN '微型'
             END AS COL_10, --企业规模
             A.GUARANTY_TYP AS COL_15, --主要担保方式
             A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_G5305_GUAR_TEMP1 T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
          AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.DATA_DATE = I_DATADATE
         AND C.CUST_ID = T.CUST_ID
        LEFT JOIN CBRC_G5305_CREDITLINE_HZ T1
          ON T.CUST_ID = T1.CUST_ID
         AND T1.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND ((T.CORP_SCALE IN ('S', 'T') /*小微企业*/
             AND SUBSTR(T.CUST_TYP, 1, 1) IN ('1', '0')) OR
             ((T.ACCT_TYP LIKE '0102%' /*个人经营性*/
             OR T.ACCT_TYP LIKE '03%') --票据融资
             AND (T.OPERATE_CUST_TYPE IN ('A', 'B') OR T.CUST_TYP='3'))) --个体工商户、小微企业主
         AND T1.FACILITY_AMT <= 10000000 --授信额度小于1000万及以下
         AND T.GENERALIZE_LOAN_FLG = 'Y' --普惠型贷款标志
         AND T.GUARANTY_TYPE = 'C01' --担保人类型：政府性融资担保机构
         AND T.LOAN_ACCT_BAL > 0;
    COMMIT;

    V_STEP_ID   := 1;
    V_STEP_DESC := '加工1.3农户及新型农业经营主体贷款余额至A_REPT_DWD_G5305表';
    V_STEP_FLAG := 0;
    --1.3农户及新型农业经营主体贷款余额

    INSERT INTO CBRC_A_REPT_DWD_G5305 
       (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT,--数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE,-- 汇总值
       COL_1, --客户号
       COL_2, --客户名
       COL_3, --贷款编号
       COL_4, --贷款合同编号
       COL_7, --原始到期日
       COL_8, --科目号
       COL_10, --企业规模
       COL_15, --主要担保方式
       COL_16)  --贷款产品名称
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             T.ORG_NUM AS ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'G5305' AS REP_NUM, --报表编号
             CASE WHEN SUBSTR(T.ORG_NUM,1,2) IN ('55','56') THEN 'G53_5_1.3.D'
                  WHEN SUBSTR(T.ORG_NUM,1,2) = '52' THEN 'G53_5_1.3.K'
                  WHEN substr(T.ORG_NUM,1,2) IN ('10', '11') THEN 'G53_5_1.3.G'
               ELSE 'G53_5_1.3.H'
             END AS ITEM_NUM, --指标号
             T.LOAN_ACCT_BAL AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             C.CUST_NAM AS COL_2, --客户名
             T.LOAN_NUM AS COL_3, --贷款编号
             T.ACCT_NUM AS COL_4, --贷款合同编号
             A.MATURITY_DT AS COL_7, --原始到期日
             A.ITEM_CD AS COL_8, --科目号
             CASE WHEN C.CORP_SCALE = 'B' THEN '大型'
                  WHEN C.CORP_SCALE = 'M' THEN '中型'
                  WHEN C.CORP_SCALE = 'S' THEN '小型'
                  WHEN C.CORP_SCALE = 'T' THEN '微型'
             END AS COL_10, --企业规模
             A.GUARANTY_TYP AS COL_15, --主要担保方式
             A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_G5305_GUAR_TEMP1 T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
          AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.DATA_DATE = I_DATADATE
         AND C.CUST_ID = T.CUST_ID
       WHERE T.DATA_DATE = I_DATADATE
         AND T.FLAG = 'Y' --农户及新型农业经营主体贷款标志
         AND T.LOAN_ACCT_BAL > 0;
    COMMIT;


    V_STEP_ID   := 1;
    V_STEP_DESC := '加工 1.4不良贷款余额至A_REPT_DWD_G5305表';
    V_STEP_FLAG := 0;
    -- 1.4不良贷款余额

    INSERT INTO CBRC_A_REPT_DWD_G5305 
       (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT,--数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE,-- 汇总值
       COL_1, --客户号
       COL_2, --客户名
       COL_3, --贷款编号
       COL_4, --贷款合同编号
       COL_7, --原始到期日
       COL_8, --科目号
       COL_10, --企业规模
       COL_15, --主要担保方式
       COL_16)  --贷款产品名称
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             T.ORG_NUM AS ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'G5305' AS REP_NUM, --报表编号
             CASE WHEN SUBSTR(T.ORG_NUM,1,2) IN ('55','56') THEN 'G53_5_1.4.D'
                  WHEN SUBSTR(T.ORG_NUM,1,2) = '52' THEN 'G53_5_1.4.K'
                  WHEN substr(T.ORG_NUM,1,2) IN ('10', '11') THEN 'G53_5_1.4.G'
               ELSE 'G53_5_1.4.H'
             END AS ITEM_NUM, --指标号
             T.LOAN_ACCT_BAL AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             C.CUST_NAM AS COL_2, --客户名
             T.LOAN_NUM AS COL_3, --贷款编号
             T.ACCT_NUM AS COL_4, --贷款合同编号
             A.MATURITY_DT AS COL_7, --原始到期日
             A.ITEM_CD AS COL_8, --科目号
             CASE WHEN C.CORP_SCALE = 'B' THEN '大型'
                  WHEN C.CORP_SCALE = 'M' THEN '中型'
                  WHEN C.CORP_SCALE = 'S' THEN '小型'
                  WHEN C.CORP_SCALE = 'T' THEN '微型'
             END AS COL_10, --企业规模
             A.GUARANTY_TYP AS COL_15, --主要担保方式
             A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_G5305_GUAR_TEMP1 T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
          AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.DATA_DATE = I_DATADATE
         AND C.CUST_ID = T.CUST_ID
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款
         AND T.LOAN_ACCT_BAL > 0;
    COMMIT;

    V_STEP_ID   := 1;
    V_STEP_DESC := '加工2.融资担保机构担保贷款户数至A_REPT_DWD_G5305表';
    V_STEP_FLAG := 0;
    --2.融资担保机构担保贷款户数

    INSERT INTO CBRC_A_REPT_DWD_G5305 
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       COL_1, --客户号
       COL_2) --客户号
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             T.ORG_NUM AS ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'G5305' AS REP_NUM, --报表编号
             CASE
               WHEN SUBSTR(T.ORG_NUM, 1, 2) IN ('55', '56') THEN
                'G53_5_2..D'
               WHEN SUBSTR(T.ORG_NUM, 1, 2) = '52' THEN
                'G53_5_2..K'
               WHEN substr(T.ORG_NUM, 1, 2) IN ('10', '11') THEN
                'G53_5_2..G'
               ELSE
                'G53_5_2..H'
             END AS ITEM_NUM, --指标号
             1 AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             C.CUST_NAM AS COL_2 --客户名
        FROM CBRC_G5305_GUAR_TEMP1 T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.DATA_DATE = I_DATADATE
         AND C.CUST_ID = T.CUST_ID
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL > 0
       GROUP BY T.ORG_NUM,
                A.DEPARTMENTD,
                CASE
                  WHEN SUBSTR(T.ORG_NUM, 1, 2) IN ('55', '56') THEN
                   'G53_5_2..D'
                  WHEN SUBSTR(T.ORG_NUM, 1, 2) = '52' THEN
                   'G53_5_2..K'
                  WHEN SUBSTR(T.ORG_NUM, 1, 2) IN ('10', '11') THEN
                   'G53_5_2..G'
                  ELSE
                   'G53_5_2..H'
                END,
                T.CUST_ID,
                C.CUST_NAM;
    COMMIT;

    V_STEP_ID   := 1;
    V_STEP_DESC := '加工3.本年度累计实际获得代偿金额至A_REPT_DWD_G5305表';
    V_STEP_FLAG := 0;
    ---3.本年度累计实际获得代偿金额

    INSERT INTO CBRC_A_REPT_DWD_G5305 
       (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT,--数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE,-- 汇总值
       COL_1, --客户号
       COL_2, --客户名
       COL_3, --贷款编号
       COL_4, --贷款合同编号
       COL_7, --原始到期日
       COL_8, --科目号
       COL_10, --企业规模
       COL_15, --主要担保方式
       COL_16)  --贷款产品名称
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             T.ORG_NUM AS ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'G5305' AS REP_NUM, --报表编号
             CASE WHEN SUBSTR(Tt.ORG_NUM,1,2) IN ('55','56') THEN 'G53_5_3..D'
                  WHEN SUBSTR(Tt.ORG_NUM,1,2) = '52' THEN 'G53_5_3..K'
                 WHEN substr(Tt.ORG_NUM,1,2) IN ('10', '11') THEN 'G53_5_3..G'
                 ELSE'G53_5_3..H'
             END AS ITEM_NUM, --指标号
             T.LOAN_ACCT_BAL AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             C.CUST_NAM AS COL_2, --客户名
             T.LOAN_NUM AS COL_3, --贷款编号
             T.ACCT_NUM AS COL_4, --贷款合同编号
             A.MATURITY_DT AS COL_7, --原始到期日
             A.ITEM_CD AS COL_8, --科目号
             CASE WHEN C.CORP_SCALE = 'B' THEN '大型'
                  WHEN C.CORP_SCALE = 'M' THEN '中型'
                  WHEN C.CORP_SCALE = 'S' THEN '小型'
                  WHEN C.CORP_SCALE = 'T' THEN '微型'
             END AS COL_10, --企业规模
             A.GUARANTY_TYP AS COL_15, --主要担保方式
             A.CP_NAME AS COL_16 --贷款产品名称
        FROM SMTMODS_L_TRAN_LOAN_PAYM TT
       INNER JOIN CBRC_G5305_GUAR_TEMP1 T
          ON TT.LOAN_NUM = T.LOAN_NUM
         AND T.DATA_DATE = I_DATADATE
  
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = TT.LOAN_NUM
          AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.DATA_DATE = I_DATADATE
         AND C.CUST_ID = T.CUST_ID
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.PAY_TYPE = '07' --还款方式：担保代偿
         AND SUBSTR(TO_CHAR(TT.REPAY_DT, 'YYYYMMDD'), 1, 4) = SUBSTR(I_DATADATE, 1, 4);
    COMMIT;

    V_STEP_ID   := 1;
    V_STEP_DESC := '加工4.融资担保机构尚未履行代偿责任金额至A_REPT_DWD_G5305表';
    V_STEP_FLAG := 0;
    ---4.融资担保机构尚未履行代偿责任金额

    INSERT INTO CBRC_A_REPT_DWD_G5305 
       (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT,--数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE,-- 汇总值
       COL_1, --客户号
       COL_2, --客户名
       COL_3, --贷款编号
       COL_4, --贷款合同编号
       COL_7, --原始到期日
       COL_8, --科目号
       COL_10, --企业规模
       COL_15, --主要担保方式
       COL_16)  --贷款产品名称
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             T.ORG_NUM AS ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'G5305' AS REP_NUM, --报表编号
             CASE WHEN SUBSTR(T.ORG_NUM,1,2) IN ('55','56') THEN 'G53_5_4..D'
                  WHEN SUBSTR(T.ORG_NUM,1,2) = '52' THEN 'G53_5_4..K'
               WHEN substr(T.ORG_NUM,1,2) IN ('10', '11') THEN
                'G53_5_4..G'
               ELSE
                'G53_5_4..H'
             END AS ITEM_NUM, --指标号
             T.NON_COMPENSE_BAL_RMB AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             C.CUST_NAM AS COL_2, --客户名
             T.LOAN_NUM AS COL_3, --贷款编号
             T.ACCT_NUM AS COL_4, --贷款合同编号
             A.MATURITY_DT AS COL_7, --原始到期日
             A.ITEM_CD AS COL_8, --科目号
             CASE WHEN C.CORP_SCALE = 'B' THEN '大型'
                  WHEN C.CORP_SCALE = 'M' THEN '中型'
                  WHEN C.CORP_SCALE = 'S' THEN '小型'
                  WHEN C.CORP_SCALE = 'T' THEN '微型'
             END AS COL_10, --企业规模
             A.GUARANTY_TYP AS COL_15, --主要担保方式
             A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_G5305_GUAR_TEMP1 T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
          AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.DATA_DATE = I_DATADATE
         AND C.CUST_ID = T.CUST_ID
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL > 0
         AND T.OD_DAYS > 0; --逾期天数大于0

    COMMIT;

    V_STEP_ID   := 1;
    V_STEP_DESC := '加工其中:4.1逾期90天以上尚未履行代偿责任金额至A_REPT_DWD_G5305表';
    V_STEP_FLAG := 0;
    ---其中:   4.1逾期90天以上尚未履行代偿责任金额


    INSERT INTO CBRC_A_REPT_DWD_G5305 
       (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT,--数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE,-- 汇总值
       COL_1, --客户号
       COL_2, --客户名
       COL_3, --贷款编号
       COL_4, --贷款合同编号
       COL_7, --原始到期日
       COL_8, --科目号
       COL_10, --企业规模
       COL_15, --主要担保方式
       COL_16)  --贷款产品名称
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             T.ORG_NUM AS ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'G5305' AS REP_NUM, --报表编号
             CASE WHEN SUBSTR(T.ORG_NUM,1,2) IN ('55','56') THEN 'G53_5_4.1.D'
                  WHEN SUBSTR(T.ORG_NUM,1,2) = '52' THEN 'G53_5_4.1.K'
               WHEN substr(T.ORG_NUM,1,2) IN ('10', '11') THEN
                'G53_5_4.1.G'
               ELSE
                'G53_5_4.1.H'
             END AS ITEM_NUM, --指标号
             T.NON_COMPENSE_BAL_RMB AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             C.CUST_NAM AS COL_2, --客户名
             T.LOAN_NUM AS COL_3, --贷款编号
             T.ACCT_NUM AS COL_4, --贷款合同编号
             A.MATURITY_DT AS COL_7, --原始到期日
             A.ITEM_CD AS COL_8, --科目号
             CASE WHEN C.CORP_SCALE = 'B' THEN '大型'
                  WHEN C.CORP_SCALE = 'M' THEN '中型'
                  WHEN C.CORP_SCALE = 'S' THEN '小型'
                  WHEN C.CORP_SCALE = 'T' THEN '微型'
             END AS COL_10, --企业规模
             A.GUARANTY_TYP AS COL_15, --主要担保方式
             A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_G5305_GUAR_TEMP1 T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
          AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.DATA_DATE = I_DATADATE
         AND C.CUST_ID = T.CUST_ID
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL > 0
         AND T.OD_DAYS > 90; --逾期天数大于90
    COMMIT;

    V_STEP_ID   := 1;
    V_STEP_DESC := '加工4.2逾期360天以上尚未履行代偿责任金额至A_REPT_DWD_G5305表';
    V_STEP_FLAG := 0;
    ---4.2逾期360天以上尚未履行代偿责任金额

    INSERT INTO CBRC_A_REPT_DWD_G5305 
       (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT,--数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE,-- 汇总值
       COL_1, --客户号
       COL_2, --客户名
       COL_3, --贷款编号
       COL_4, --贷款合同编号
       COL_7, --原始到期日
       COL_8, --科目号
       COL_10, --企业规模
       COL_15, --主要担保方式
       COL_16)  --贷款产品名称
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             T.ORG_NUM AS ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'G5305' AS REP_NUM, --报表编号
             CASE WHEN SUBSTR(T.ORG_NUM,1,2) IN ('55','56') THEN 'G53_5_4.2.D'
                  WHEN SUBSTR(T.ORG_NUM,1,2) = '52' THEN 'G53_5_4.2.K'
               WHEN substr(T.ORG_NUM,1,2) IN ('10', '11') THEN
                'G53_5_4.2.G'
               ELSE
                'G53_5_4.2.H'
             END AS ITEM_NUM, --指标号
             T.NON_COMPENSE_BAL_RMB AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             C.CUST_NAM AS COL_2, --客户名
             T.LOAN_NUM AS COL_3, --贷款编号
             T.ACCT_NUM AS COL_4, --贷款合同编号
             A.MATURITY_DT AS COL_7, --原始到期日
             A.ITEM_CD AS COL_8, --科目号
             CASE WHEN C.CORP_SCALE = 'B' THEN '大型'
                  WHEN C.CORP_SCALE = 'M' THEN '中型'
                  WHEN C.CORP_SCALE = 'S' THEN '小型'
                  WHEN C.CORP_SCALE = 'T' THEN '微型'
             END AS COL_10, --企业规模
             A.GUARANTY_TYP AS COL_15, --主要担保方式
             A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_G5305_GUAR_TEMP1 T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
          AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.DATA_DATE = I_DATADATE
         AND C.CUST_ID = T.CUST_ID
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL > 0
         AND T.OD_DAYS > 360; --逾期天数大于360
    COMMIT;

    V_STEP_ID   := 1;
    V_STEP_DESC := '加工所有指标至A_REPT_ITEM_VAL表';
    V_STEP_FLAG := 0;

--begin 明细需求 bohe20250814
      INSERT INTO CBRC_A_REPT_ITEM_VAL 
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG --标志位
         )
        SELECT DATA_DATE, --数据日期
               ORG_NUM, --机构号
               SYS_NAM, --模块简称
               REP_NUM, --报表编号
               ITEM_NUM, --指标号
               SUM(TOTAL_VALUE) AS ITEM_VAL, --指标值
               '2' AS FLAG --标志位
          FROM CBRC_A_REPT_DWD_G5305
         WHERE DATA_DATE = I_DATADATE
         GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM;
      COMMIT;
--end 明细需求 bohe20250814

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
   
END ;