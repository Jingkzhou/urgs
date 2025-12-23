CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g19(II_DATADATE IN STRING --跑批日期
                                              ) IS
  /*********************************************************************
  M1.20241224 alter by shiyu 修改内容：科技贷款需求：合同表新增文化及相关产业字段
  M2.20250327 2025年制度升级 删除“工业企业技术改造升级项目”统计项目。明确贷款余额不含“买断式转贴现”和“买断其他票据类资产”
  需求编号：JLBA202503070010_关于吉林银行统一监管报送平台升级的需求 上线日期： 2025-12-26，修改人：狄家卉，提出人：统一监管报送平台升级  修改原因：由汇总数据修改为明细以及汇总
  
目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_A_REPT_DWD_G19
码值表：CBRC_LOAN_FIVE_INDEX --五级分类
      SMTMODS_A_REPT_DWD_MAPPING --明细码值表
      SMTMODS_INTO_FIELD_INDEX
集市表：SMTMODS_L_ACCT_LOAN
     SMTMODS_L_AGRE_LOAN_CONTRACT
     SMTMODS_L_PUBL_RATE
  
  
  *********************************************************************/

  V_SCHEMA    VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE VARCHAR(30); --当前储存过程名称
  V_TAB_NAME  VARCHAR(30); --目标表名
  I_DATADATE  STRING; --数据日期(数值型)YYYYMMDD
  V_STEP_ID   INTEGER; --任务号
  V_STEP_DESC VARCHAR(300); --任务描述
  V_STEP_FLAG INTEGER; --任务执行状态标识
  V_ERRORCODE VARCHAR(20); --错误编码
  V_ERRORDESC VARCHAR(280); --错误内容
  II_STATUS   INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM     VARCHAR2(30);
  

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

    I_DATADATE := II_DATADATE;

    V_SYSTEM    := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G19');
    V_TAB_NAME  := 'G19';

    ------------------------------------------------------------------
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || 'G19当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --删除临时表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G19_DATA_COLLECT_TMP';
    COMMIT;
    --删除目标表G19数据
    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'G19'
       AND T.FLAG = '2';
    COMMIT;

    -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_A_REPT_DWD_G19';


    V_STEP_FLAG := 1;
    V_STEP_DESC := '清理G19当期数据完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -----------------------------------------------------工业转型升级项目-----------------------------------------------

    -----------------------------------------------------战略性新兴产业-------------------------------------------------

    /*投向领域指标表内存放G19统计表内工业企业技术改造升级项目、战略性新兴产业、文化产业/B-L列指标和其对应的贷款投向代码*/
    /*战略新兴产业类型：
    1  节能环保
    2  新一代信息技术
    3  生物产业
    4  高端装备制造
    5  新能源
    6  新材料
    7  新能源汽车
    8  数字创意产业
    9  相关服务业*/

    -----------------------------------------------------战略性新兴产业:节能环保-------------------------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生G19指标数据节能环保，插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

      INSERT 
      INTO CBRC_A_REPT_DWD_G19 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE,
         COL_1,
         COL_2,
         COL_3,
         COL_4,
         COL_5,
         COL_6)
        SELECT 
         I_DATADATE,
         B.ORG_NUM, --机构号
         B.DEPARTMENTD, --数据条线
         'CBRC' AS SYS_NAM,
         'G19' REP_NUM,
         A.TRAN_FLG_CODE AS ITEM_NUM, -- 指标号
         B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
         B.LOAN_NUM AS COL_1, --贷款编号
         B.CURR_CD AS COL_2, --币种
         B.ITEM_CD AS COL_3, --科目号
         B.ACCT_NUM AS COL_4, --贷款合同编号
         C.M_NAME AS COL_5, --战略新兴产业类型
         D.M_NAME AS COL_6 --贷款投向
          FROM   `SMTMODS_INTO_FIELD_INDEX` A -- 投向领域指标表
          LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
            ON A.LOAN_PURPOSE_CD = B.LOAN_PURPOSE_CD
          LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
            ON B.DATA_DATE = R.DATA_DATE
           AND B.CURR_CD = R.BASIC_CCY
           AND R.FORWARD_CCY = 'CNY'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING C
            ON B.INDUST_STG_TYPE = C.M_CODE
           AND C.M_TABLECODE = 'INDUST_STG_TYPE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
            ON A.LOAN_PURPOSE_CD = D.M_CODE
           AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
         WHERE B.DATA_DATE = I_DATADATE
           AND A.COLUMN_OODE = 'C' -- 指标表C列 战略性新兴产业:节能环保
           AND B.INDUST_STG_TYPE = '1' -- 节能环保
           AND LENGTH(A.LOAN_PURPOSE_CD) = 5
           AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
           AND B.ACCT_TYP <> '90'
           AND b.CANCEL_FLG = 'N'
           AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
           AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
           AND B.LOAN_ACCT_BAL <> 0
        UNION ALL
        SELECT I_DATADATE,
               B.ORG_NUM, --机构号
               B.DEPARTMENTD, --数据条线
               'CBRC' AS SYS_NAM,
               'G19' REP_NUM,
               A.TRAN_FLG_CODE AS ITEM_NUM, -- 指标号
               B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
               B.LOAN_NUM AS COL_1, --贷款编号
               B.CURR_CD AS COL_2, --币种
               B.ITEM_CD AS COL_3, --科目号
               B.ACCT_NUM AS COL_4, --贷款合同编号
               C.M_NAME AS COL_5, --战略新兴产业类型
               D.M_NAME AS COL_6 --贷款投向
          FROM SMTMODS_INTO_FIELD_INDEX A -- 投向领域指标表
          LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
            ON A.LOAN_PURPOSE_CD = SUBSTR(B.LOAN_PURPOSE_CD, 1, 4)
          LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
            ON B.DATA_DATE = R.DATA_DATE
           AND B.CURR_CD = R.BASIC_CCY
           AND R.FORWARD_CCY = 'CNY'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING C
            ON B.INDUST_STG_TYPE = C.M_CODE
           AND C.M_TABLECODE = 'INDUST_STG_TYPE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
            ON A.LOAN_PURPOSE_CD = D.M_CODE
           AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
         WHERE B.DATA_DATE = I_DATADATE
           AND A.COLUMN_OODE = 'C' -- 指标表C列 战略性新兴产业:节能环保
           AND B.INDUST_STG_TYPE = '1' -- 节能环保
           AND LENGTH(A.LOAN_PURPOSE_CD) = 4
           AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
           AND B.ACCT_TYP <> '90'
           AND b.CANCEL_FLG = 'N'
           AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
           AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
           AND B.LOAN_ACCT_BAL <> 0
        UNION ALL
        SELECT I_DATADATE,
               B.ORG_NUM, --机构号
               B.DEPARTMENTD, --数据条线
               'CBRC' AS SYS_NAM,
               'G19' REP_NUM,
               A.TRAN_FLG_CODE AS ITEM_NUM, -- 指标号
               B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
               B.LOAN_NUM AS COL_1, --贷款编号
               B.CURR_CD AS COL_2, --币种
               B.ITEM_CD AS COL_3, --科目号
               B.ACCT_NUM AS COL_4, --贷款合同编号
               C.M_NAME AS COL_5, --战略新兴产业类型
               D.M_NAME AS COL_6 --贷款投向
          FROM SMTMODS_INTO_FIELD_INDEX A -- 投向领域指标表
          LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
            ON A.LOAN_PURPOSE_CD = SUBSTR(B.LOAN_PURPOSE_CD, 1, 3)
          LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
            ON B.DATA_DATE = R.DATA_DATE
           AND B.CURR_CD = R.BASIC_CCY
           AND R.FORWARD_CCY = 'CNY'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING C
            ON B.INDUST_STG_TYPE = C.M_CODE
           AND C.M_TABLECODE = 'INDUST_STG_TYPE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
            ON A.LOAN_PURPOSE_CD = D.M_CODE
           AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
         WHERE B.DATA_DATE = I_DATADATE
           AND A.COLUMN_OODE = 'C' -- 指标表C列 战略性新兴产业:节能环保
           AND B.INDUST_STG_TYPE = '1' -- 节能环保
           AND LENGTH(A.LOAN_PURPOSE_CD) = 3
           AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
           AND B.ACCT_TYP <> '90'
           AND b.CANCEL_FLG = 'N'
           AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
           AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
           AND B.LOAN_ACCT_BAL <> 0;
    COMMIT;

    -----------------------------------------------------战略性新兴产业:新一代信息技术--------------------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生G19指标数据新一代信息技术，插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

           INSERT 
           INTO CBRC_A_REPT_DWD_G19 
             (DATA_DATE,
              ORG_NUM,
              DATA_DEPARTMENT,
              SYS_NAM,
              REP_NUM,
              ITEM_NUM,
              TOTAL_VALUE,
              COL_1,
              COL_2,
              COL_3,
              COL_4,
              COL_5,
              COL_6)
             SELECT 
              I_DATADATE,
              B.ORG_NUM, --机构号
              B.DEPARTMENTD, --数据条线
              'CBRC' AS SYS_NAM,
              'G19' REP_NUM,
              A.TRAN_FLG_CODE AS ITEM_NUM, -- 指标号
              B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
              B.LOAN_NUM AS COL_1, --贷款编号
              B.CURR_CD AS COL_2, --币种
              B.ITEM_CD AS COL_3, --科目号
              B.ACCT_NUM AS COL_4, --贷款合同编号
              C.M_NAME AS COL_5, --战略新兴产业类型
              D.M_NAME AS COL_6 --贷款投向
               FROM SMTMODS_INTO_FIELD_INDEX A -- 投向领域指标表
               LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
                 ON A.LOAN_PURPOSE_CD = B.LOAN_PURPOSE_CD
               LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
                 ON B.DATA_DATE = R.DATA_DATE
                AND B.CURR_CD = R.BASIC_CCY
                AND R.FORWARD_CCY = 'CNY'
               LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING C
                 ON B.INDUST_STG_TYPE = C.M_CODE
                AND C.M_TABLECODE = 'INDUST_STG_TYPE'
               LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
                 ON A.LOAN_PURPOSE_CD = D.M_CODE
                AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
              WHERE B.DATA_DATE = I_DATADATE
                AND A.COLUMN_OODE = 'D' -- 指标表D列 战略性新兴产业:新一代信息技术
                AND B.INDUST_STG_TYPE = '2' -- 新一代信息技术
                AND LENGTH(A.LOAN_PURPOSE_CD) = 5
                AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
                AND B.ACCT_TYP <> '90'
                AND b.CANCEL_FLG = 'N'
                AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
                AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
                AND B.LOAN_ACCT_BAL <> 0;
    COMMIT;

    -----------------------------------------------------战略性新兴产业:生物产业-------------------------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生G19指标数据生物产业，插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

        INSERT 
        INTO CBRC_A_REPT_DWD_G19 
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_1,
           COL_2,
           COL_3,
           COL_4,
           COL_5,
           COL_6)
          SELECT 
           I_DATADATE,
           B.ORG_NUM, --机构号
           B.DEPARTMENTD, --数据条线
           'CBRC' AS SYS_NAM,
           'G19' REP_NUM,
           A.TRAN_FLG_CODE AS ITEM_NUM, -- 指标号
           B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
           B.LOAN_NUM AS COL_1, --贷款编号
           B.CURR_CD AS COL_2, --币种
           B.ITEM_CD AS COL_3, --科目号
           B.ACCT_NUM AS COL_4, --贷款合同编号
           C.M_NAME AS COL_5, --战略新兴产业类型
           D.M_NAME AS COL_6 --贷款投向
            FROM SMTMODS_INTO_FIELD_INDEX A -- 投向领域指标表
            LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
              ON A.LOAN_PURPOSE_CD = B.LOAN_PURPOSE_CD
            LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
              ON B.DATA_DATE = R.DATA_DATE
             AND B.CURR_CD = R.BASIC_CCY
             AND R.FORWARD_CCY = 'CNY'
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING C
              ON B.INDUST_STG_TYPE = C.M_CODE
             AND C.M_TABLECODE = 'INDUST_STG_TYPE'
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
              ON A.LOAN_PURPOSE_CD = D.M_CODE
             AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
           WHERE B.DATA_DATE = I_DATADATE
             AND A.COLUMN_OODE = 'E' -- 指标表E列 战略性新兴产业:生物
             AND B.INDUST_STG_TYPE = '3' -- 生物
             AND LENGTH(A.LOAN_PURPOSE_CD) = 5
             AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
             AND B.ACCT_TYP <> '90'
             AND b.CANCEL_FLG = 'N'
             AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
             AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
             AND B.LOAN_ACCT_BAL <> 0
          UNION ALL
          SELECT 
           I_DATADATE,
           B.ORG_NUM, --机构号
           B.DEPARTMENTD, --数据条线
           'CBRC' AS SYS_NAM,
           'G19' REP_NUM,
           A.TRAN_FLG_CODE AS ITEM_NUM, -- 指标号
           B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
           B.LOAN_NUM AS COL_1, --贷款编号
           B.CURR_CD AS COL_2, --币种
           B.ITEM_CD AS COL_3, --科目号
           B.ACCT_NUM AS COL_4, --贷款合同编号
           C.M_NAME AS COL_5, --战略新兴产业类型
           D.M_NAME AS COL_6 --贷款投向
            FROM SMTMODS_INTO_FIELD_INDEX A -- 投向领域指标表
            LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
              ON A.LOAN_PURPOSE_CD = SUBSTR(B.LOAN_PURPOSE_CD, 1, 4)
            LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
              ON B.DATA_DATE = R.DATA_DATE
             AND B.CURR_CD = R.BASIC_CCY
             AND R.FORWARD_CCY = 'CNY'
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING C
              ON B.INDUST_STG_TYPE = C.M_CODE
             AND C.M_TABLECODE = 'INDUST_STG_TYPE'
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
              ON A.LOAN_PURPOSE_CD = D.M_CODE
             AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
           WHERE B.DATA_DATE = I_DATADATE
             AND A.COLUMN_OODE = 'E' -- 指标表E列 战略性新兴产业:生物
             AND B.INDUST_STG_TYPE = '3' -- 生物
             AND LENGTH(A.LOAN_PURPOSE_CD) = 4
             AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
             AND B.ACCT_TYP <> '90'
             AND b.CANCEL_FLG = 'N'
             AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
             AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
             AND B.LOAN_ACCT_BAL <> 0;
        COMMIT;

    -----------------------------------------------------战略性新兴产业:高端装备制造-------------------------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生G19指标数据高端装备制造，插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

        INSERT 
        INTO CBRC_A_REPT_DWD_G19 
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_1,
           COL_2,
           COL_3,
           COL_4,
           COL_5,
           COL_6)
          SELECT 
           I_DATADATE,
           B.ORG_NUM, --机构号
           B.DEPARTMENTD, --数据条线
           'CBRC' AS SYS_NAM,
           'G19' REP_NUM,
           A.TRAN_FLG_CODE AS ITEM_NUM, -- 指标号
           B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
           B.LOAN_NUM AS COL_1, --贷款编号
           B.CURR_CD AS COL_2, --币种
           B.ITEM_CD AS COL_3, --科目号
           B.ACCT_NUM AS COL_4, --贷款合同编号
           C.M_NAME AS COL_5, --战略新兴产业类型
           D.M_NAME AS COL_6 --贷款投向
            FROM SMTMODS_INTO_FIELD_INDEX A -- 投向领域指标表
            LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
              ON A.LOAN_PURPOSE_CD = B.LOAN_PURPOSE_CD
            LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
              ON B.DATA_DATE = R.DATA_DATE
             AND B.CURR_CD = R.BASIC_CCY
             AND R.FORWARD_CCY = 'CNY'
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING C
              ON B.INDUST_STG_TYPE = C.M_CODE
             AND C.M_TABLECODE = 'INDUST_STG_TYPE'
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
              ON A.LOAN_PURPOSE_CD = D.M_CODE
             AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
           WHERE B.DATA_DATE = I_DATADATE
             AND A.COLUMN_OODE = 'F' -- 指标表F列 战略性新兴产业:高端装备制造
             AND B.INDUST_STG_TYPE = '4' -- 高端装备制造
             AND LENGTH(A.LOAN_PURPOSE_CD) = 5
             AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
             AND B.ACCT_TYP <> '90'
             AND b.CANCEL_FLG = 'N'
             AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
             AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
             AND B.LOAN_ACCT_BAL <> 0;
    COMMIT;

    -----------------------------------------------------战略性新兴产业:新能源-------------------------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生G19指标数据新能源，插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

         INSERT 
         INTO CBRC_A_REPT_DWD_G19 
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_1,
            COL_2,
            COL_3,
            COL_4,
            COL_5,
            COL_6)
           SELECT 
            I_DATADATE,
            B.ORG_NUM, --机构号
            B.DEPARTMENTD, --数据条线
            'CBRC' AS SYS_NAM,
            'G19' REP_NUM,
            A.TRAN_FLG_CODE AS ITEM_NUM, -- 指标号
            B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
            B.LOAN_NUM AS COL_1, --贷款编号
            B.CURR_CD AS COL_2, --币种
            B.ITEM_CD AS COL_3, --科目号
            B.ACCT_NUM AS COL_4, --贷款合同编号
            C.M_NAME AS COL_5, --战略新兴产业类型
            D.M_NAME AS COL_6 --贷款投向
             FROM SMTMODS_INTO_FIELD_INDEX A -- 投向领域指标表
             LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
               ON A.LOAN_PURPOSE_CD = B.LOAN_PURPOSE_CD
             LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
               ON B.DATA_DATE = R.DATA_DATE
              AND B.CURR_CD = R.BASIC_CCY
              AND R.FORWARD_CCY = 'CNY'
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING C
               ON B.INDUST_STG_TYPE = C.M_CODE
              AND C.M_TABLECODE = 'INDUST_STG_TYPE'
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
               ON A.LOAN_PURPOSE_CD = D.M_CODE
              AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
            WHERE B.DATA_DATE = I_DATADATE
              AND A.COLUMN_OODE = 'G' -- 指标表G列 战略性新兴产业:新能源
              AND B.INDUST_STG_TYPE = '5' -- 新能源
              AND LENGTH(A.LOAN_PURPOSE_CD) = 5
              AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
              AND B.ACCT_TYP <> '90'
              AND b.CANCEL_FLG = 'N'
              AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
              AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
              AND B.LOAN_ACCT_BAL <> 0;
    COMMIT;

    -----------------------------------------------------战略性新兴产业:新材料-------------------------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生G19指标数据新材料，插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

        INSERT 
        INTO CBRC_A_REPT_DWD_G19 
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_1,
           COL_2,
           COL_3,
           COL_4,
           COL_5,
           COL_6)
          SELECT 
           I_DATADATE,
           B.ORG_NUM, --机构号
           B.DEPARTMENTD, --数据条线
           'CBRC' AS SYS_NAM,
           'G19' REP_NUM,
           A.TRAN_FLG_CODE AS ITEM_NUM, -- 指标号
           B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
           B.LOAN_NUM AS COL_1, --贷款编号
           B.CURR_CD AS COL_2, --币种
           B.ITEM_CD AS COL_3, --科目号
           B.ACCT_NUM AS COL_4, --贷款合同编号
           C.M_NAME AS COL_5, --战略新兴产业类型
           D.M_NAME AS COL_6 --贷款投向
            FROM SMTMODS_INTO_FIELD_INDEX A -- 投向领域指标表
            LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
              ON A.LOAN_PURPOSE_CD = B.LOAN_PURPOSE_CD
            LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
              ON B.DATA_DATE = R.DATA_DATE
             AND B.CURR_CD = R.BASIC_CCY
             AND R.FORWARD_CCY = 'CNY'
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING C
              ON B.INDUST_STG_TYPE = C.M_CODE
             AND C.M_TABLECODE = 'INDUST_STG_TYPE'
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
              ON A.LOAN_PURPOSE_CD = D.M_CODE
             AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
           WHERE B.DATA_DATE = I_DATADATE
             AND A.COLUMN_OODE = 'H' -- 指标表F列 战略性新兴产业:新材料
             AND B.INDUST_STG_TYPE = '6' -- 新材料
             AND LENGTH(A.LOAN_PURPOSE_CD) = 5
             AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
             AND B.ACCT_TYP <> '90'
             AND b.CANCEL_FLG = 'N'
             AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
             AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
             AND B.LOAN_ACCT_BAL <> 0
          UNION ALL
          SELECT 
           I_DATADATE,
           B.ORG_NUM, --机构号
           B.DEPARTMENTD, --数据条线
           'CBRC' AS SYS_NAM,
           'G19' REP_NUM,
           A.TRAN_FLG_CODE AS ITEM_NUM, -- 指标号
           B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
           B.LOAN_NUM AS COL_1, --贷款编号
           B.CURR_CD AS COL_2, --币种
           B.ITEM_CD AS COL_3, --科目号
           B.ACCT_NUM AS COL_4, --贷款合同编号
           C.M_NAME AS COL_5, --战略新兴产业类型
           D.M_NAME AS COL_6 --贷款投向
            FROM SMTMODS_INTO_FIELD_INDEX A -- 投向领域指标表
            LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
              ON A.LOAN_PURPOSE_CD = SUBSTR(B.LOAN_PURPOSE_CD, 1, 4)
            LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
              ON B.DATA_DATE = R.DATA_DATE
             AND B.CURR_CD = R.BASIC_CCY
             AND R.FORWARD_CCY = 'CNY'
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING C
              ON B.INDUST_STG_TYPE = C.M_CODE
             AND C.M_TABLECODE = 'INDUST_STG_TYPE'
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
              ON A.LOAN_PURPOSE_CD = D.M_CODE
             AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
           WHERE B.DATA_DATE = I_DATADATE
             AND A.COLUMN_OODE = 'H' -- 指标表H列 战略性新兴产业:新材料
             AND B.INDUST_STG_TYPE = '6' -- 新材料
             AND LENGTH(A.LOAN_PURPOSE_CD) = 4
             AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
             AND B.ACCT_TYP <> '90'
             AND b.CANCEL_FLG = 'N'
             AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
             AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
             AND B.LOAN_ACCT_BAL <> 0;
        COMMIT;

    -----------------------------------------------------战略性新兴产业:新能源汽车-------------------------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生G19指标数据新能源汽车，插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

        INSERT 
        INTO CBRC_A_REPT_DWD_G19 
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_1,
           COL_2,
           COL_3,
           COL_4,
           COL_5,
           COL_6)
          SELECT 
           I_DATADATE,
           B.ORG_NUM, --机构号
           B.DEPARTMENTD, --数据条线
           'CBRC' AS SYS_NAM,
           'G19' REP_NUM,
           A.TRAN_FLG_CODE AS ITEM_NUM, -- 指标号
           B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
           B.LOAN_NUM AS COL_1, --贷款编号
           B.CURR_CD AS COL_2, --币种
           B.ITEM_CD AS COL_3, --科目号
           B.ACCT_NUM AS COL_4, --贷款合同编号
           C.M_NAME AS COL_5, --战略新兴产业类型
           D.M_NAME AS COL_6 --贷款投向
            FROM SMTMODS_INTO_FIELD_INDEX A -- 投向领域指标表
            LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
              ON A.LOAN_PURPOSE_CD = B.LOAN_PURPOSE_CD
            LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
              ON B.DATA_DATE = R.DATA_DATE
             AND B.CURR_CD = R.BASIC_CCY
             AND R.FORWARD_CCY = 'CNY'
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING C
              ON B.INDUST_STG_TYPE = C.M_CODE
             AND C.M_TABLECODE = 'INDUST_STG_TYPE'
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
              ON A.LOAN_PURPOSE_CD = D.M_CODE
             AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
           WHERE B.DATA_DATE = I_DATADATE
             AND A.COLUMN_OODE = 'I' -- 指标表I列 战略性新兴产业:新能源汽车
             AND B.INDUST_STG_TYPE = '7' -- 新能源汽车
             AND LENGTH(A.LOAN_PURPOSE_CD) = 5
             AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
             AND B.ACCT_TYP <> '90'
             AND b.CANCEL_FLG = 'N'
             AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
             AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
             AND B.LOAN_ACCT_BAL <> 0;
        COMMIT;

    -----------------------------------------------------战略性新兴产业:数字创意-------------------------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生G19指标数据数字创意，插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

       INSERT 
       INTO CBRC_A_REPT_DWD_G19 
         (DATA_DATE,
          ORG_NUM,
          DATA_DEPARTMENT,
          SYS_NAM,
          REP_NUM,
          ITEM_NUM,
          TOTAL_VALUE,
          COL_1,
          COL_2,
          COL_3,
          COL_4,
          COL_5,
          COL_6)
         SELECT 
          I_DATADATE,
          B.ORG_NUM, --机构号
          B.DEPARTMENTD, --数据条线
          'CBRC' AS SYS_NAM,
          'G19' REP_NUM,
          A.TRAN_FLG_CODE AS ITEM_NUM, -- 指标号
          B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
          B.LOAN_NUM AS COL_1, --贷款编号
          B.CURR_CD AS COL_2, --币种
          B.ITEM_CD AS COL_3, --科目号
          B.ACCT_NUM AS COL_4, --贷款合同编号
          C.M_NAME AS COL_5, --战略新兴产业类型
          D.M_NAME AS COL_6 --贷款投向
           FROM SMTMODS_INTO_FIELD_INDEX A -- 投向领域指标表
           LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
             ON A.LOAN_PURPOSE_CD = B.LOAN_PURPOSE_CD
           LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
             ON B.DATA_DATE = R.DATA_DATE
            AND B.CURR_CD = R.BASIC_CCY
            AND R.FORWARD_CCY = 'CNY'
           LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING C
             ON B.INDUST_STG_TYPE = C.M_CODE
            AND C.M_TABLECODE = 'INDUST_STG_TYPE'
           LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
             ON A.LOAN_PURPOSE_CD = D.M_CODE
            AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
          WHERE B.DATA_DATE = I_DATADATE
            AND A.COLUMN_OODE = 'J' -- 指标表J列 战略性新兴产业:数字创意
            AND B.INDUST_STG_TYPE = '8' -- 数字创意
            AND LENGTH(A.LOAN_PURPOSE_CD) = 5
            AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
            AND B.ACCT_TYP <> '90'
            and b.CANCEL_FLG = 'N'
            AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
            AND B.LOAN_ACCT_BAL <> 0;
    COMMIT;

    -----------------------------------------------------战略性新兴产业:相关服务-------------------------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生G19指标数据相关服务，插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

          INSERT 
          INTO CBRC_A_REPT_DWD_G19 
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_1,
             COL_2,
             COL_3,
             COL_4,
             COL_5,
             COL_6)
            SELECT 
             I_DATADATE,
             B.ORG_NUM, --机构号
             B.DEPARTMENTD, --数据条线
             'CBRC' AS SYS_NAM,
             'G19' REP_NUM,
             A.TRAN_FLG_CODE AS ITEM_NUM, -- 指标号
             B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
             B.LOAN_NUM AS COL_1, --贷款编号
             B.CURR_CD AS COL_2, --币种
             B.ITEM_CD AS COL_3, --科目号
             B.ACCT_NUM AS COL_4, --贷款合同编号
             C.M_NAME AS COL_5, --战略新兴产业类型
             D.M_NAME AS COL_6 --贷款投向
              FROM SMTMODS_INTO_FIELD_INDEX A -- 投向领域指标表
              LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
                ON A.LOAN_PURPOSE_CD = B.LOAN_PURPOSE_CD
              LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
                ON B.DATA_DATE = R.DATA_DATE
               AND B.CURR_CD = R.BASIC_CCY
               AND R.FORWARD_CCY = 'CNY'
              LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING C
                ON B.INDUST_STG_TYPE = C.M_CODE
               AND C.M_TABLECODE = 'INDUST_STG_TYPE'
              LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
                ON A.LOAN_PURPOSE_CD = D.M_CODE
               AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
             WHERE B.DATA_DATE = I_DATADATE
               AND A.COLUMN_OODE = 'K' -- 指标表K列 战略性新兴产业:相关服务
               AND B.INDUST_STG_TYPE = '9' -- 相关服务
               AND LENGTH(A.LOAN_PURPOSE_CD) = 5
               AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
               AND B.ACCT_TYP <> '90'
               AND b.CANCEL_FLG = 'N'
               AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
               AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
               AND B.LOAN_ACCT_BAL <> 0;
          COMMIT;
    ----------------------------------------------------文化产业--------------------------------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生G19指标数据文化产业，插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

          INSERT 
          INTO CBRC_A_REPT_DWD_G19 
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_1,
             COL_2,
             COL_3,
             COL_4,
             COL_5,
             COL_6)
            SELECT 
             I_DATADATE,
             B.ORG_NUM, --机构号
             B.DEPARTMENTD, --数据条线
             'CBRC' AS SYS_NAM,
             'G19' REP_NUM,
             A.TRAN_FLG_CODE AS ITEM_NUM, -- 指标号
             B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
             B.LOAN_NUM AS COL_1, --贷款编号
             B.CURR_CD AS COL_2, --币种
             B.ITEM_CD AS COL_3, --科目号
             B.ACCT_NUM AS COL_4, --贷款合同编号
             E.M_NAME AS COL_5, --文化及相关产业
             D.M_NAME AS COL_6 --贷款投向
              FROM SMTMODS_L_ACCT_LOAN B -- 借据表
              LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C --alter by shiyu 原先通过贷款投向取现在改成文化及相关产业字段
                ON B.ACCT_NUM = C.CONTRACT_NUM
               AND C.DATA_DATE = I_DATADATE
              LEFT JOIN SMTMODS_INTO_FIELD_INDEX A -- 投向领域指标表
                ON B.LOAN_PURPOSE_CD = A.LOAN_PURPOSE_CD
              LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
                ON B.DATA_DATE = R.DATA_DATE
               AND B.CURR_CD = R.BASIC_CCY
               AND R.FORWARD_CCY = 'CNY'
              LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
                ON A.LOAN_PURPOSE_CD = D.M_CODE
               AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
              LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING E
                ON C.CULT_RELA_INDU = E.M_CODE
               AND E.M_TABLECODE = 'CULT_RELA_INDU'
             WHERE B.DATA_DATE = I_DATADATE
               AND A.COLUMN_OODE = 'L' -- 指标表L列 文化产业
               AND LENGTH(A.LOAN_PURPOSE_CD) = 5
               AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
               AND B.ACCT_TYP <> '90'
               AND B.CANCEL_FLG = 'N'
               AND NVL(C.CULT_RELA_INDU, '0') <> '0'
               AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
               AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
               AND B.LOAN_ACCT_BAL <> 0;
    COMMIT;

    ---------------------------------------------------贷款五级分类-正常类----------------------------------------------

    /*五级分类指标表内存放G19统计表内正常类、关注类、次级类、可疑类、损失类/M-Q列指标和其对应的贷款投向代码*/

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生G19指标数据贷款五级分类-正常类，插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

        INSERT 
        INTO CBRC_A_REPT_DWD_G19 
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_1,
           COL_2,
           COL_3,
           COL_4,
           COL_5,
           COL_7)
          SELECT 
           I_DATADATE,
           B.ORG_NUM, --机构号
           B.DEPARTMENTD, --数据条线
           'CBRC' AS SYS_NAM,
           'G19' REP_NUM,
           A.FIVE_1 AS ITEM_NUM, -- 指标号
           B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
           B.LOAN_NUM AS COL_1, --贷款编号
           B.CURR_CD AS COL_2, --币种
           B.ITEM_CD AS COL_3, --科目号
           B.ACCT_NUM AS COL_4, --贷款合同编号
           D.M_NAME AS COL_6, --贷款投向
           '正常' AS COL_7 --五级分类
            FROM CBRC_loan_five_index A -- 五级分类指标表
            LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
              ON A.LOAN_PURPOSE_CD = B.LOAN_PURPOSE_CD
            LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
              ON B.DATA_DATE = R.DATA_DATE
             AND B.CURR_CD = R.BASIC_CCY
             AND R.FORWARD_CCY = 'CNY'
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
              ON A.LOAN_PURPOSE_CD = D.M_CODE
             AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
           WHERE B.DATA_DATE = I_DATADATE
             AND B.LOAN_GRADE_CD = '1' -- 五级形态为正常
             AND LENGTH(A.LOAN_PURPOSE_CD) = 5 -- 贷款投向为5位不需汇总，直接关联取
             AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
             AND B.ACCT_TYP <> '90'
             AND b.CANCEL_FLG = 'N'
             AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
             AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
             AND B.LOAN_ACCT_BAL <> 0
          UNION ALL
          SELECT 
           I_DATADATE,
           B.ORG_NUM, --机构号
           B.DEPARTMENTD, --数据条线
           'CBRC' AS SYS_NAM,
           'G19' REP_NUM,
           A.FIVE_1 AS ITEM_NUM, -- 指标号
           B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
           B.LOAN_NUM AS COL_1, --贷款编号
           B.CURR_CD AS COL_2, --币种
           B.ITEM_CD AS COL_3, --科目号
           B.ACCT_NUM AS COL_4, --贷款合同编号
           D.M_NAME AS COL_6, --贷款投向
           '正常' AS COL_7 --五级分类
            FROM CBRC_loan_five_index A -- 五级分类指标表
            LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
              ON A.LOAN_PURPOSE_CD = SUBSTR(B.LOAN_PURPOSE_CD, 1, 4)
            LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
              ON B.DATA_DATE = R.DATA_DATE
             AND B.CURR_CD = R.BASIC_CCY
             AND R.FORWARD_CCY = 'CNY'
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
              ON A.LOAN_PURPOSE_CD = D.M_CODE
             AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
           WHERE B.DATA_DATE = I_DATADATE
             AND B.LOAN_GRADE_CD = '1' -- 五级形态为正常
             AND LENGTH(A.LOAN_PURPOSE_CD) = 4 -- 贷款投向为4位，向上汇总
             AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
             AND B.ACCT_TYP <> '90'
             and b.CANCEL_FLG = 'N'
             AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
             AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
             AND B.LOAN_ACCT_BAL <> 0
          UNION ALL
          SELECT 
           I_DATADATE,
           B.ORG_NUM, --机构号
           B.DEPARTMENTD, --数据条线
           'CBRC' AS SYS_NAM,
           'G19' REP_NUM,
           A.FIVE_1 AS ITEM_NUM, -- 指标号
           B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
           B.LOAN_NUM AS COL_1, --贷款编号
           B.CURR_CD AS COL_2, --币种
           B.ITEM_CD AS COL_3, --科目号
           B.ACCT_NUM AS COL_4, --贷款合同编号
           D.M_NAME AS COL_6, --贷款投向
           '正常' AS COL_7 --五级分类
            FROM CBRC_loan_five_index A -- 五级分类指标表
            LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
              ON A.LOAN_PURPOSE_CD = SUBSTR(B.LOAN_PURPOSE_CD, 1, 3)
            LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
              ON B.DATA_DATE = R.DATA_DATE
             AND B.CURR_CD = R.BASIC_CCY
             AND R.FORWARD_CCY = 'CNY'
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
              ON A.LOAN_PURPOSE_CD = D.M_CODE
             AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
           WHERE B.DATA_DATE = I_DATADATE
             AND B.LOAN_GRADE_CD = '1' -- 五级形态为正常
             AND LENGTH(A.LOAN_PURPOSE_CD) = 3 -- 贷款投向为3位，向上汇总
             AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
             AND B.ACCT_TYP <> '90'
             AND B.CANCEL_FLG = 'N'
             AND ITEM_CD NOT IN ('13010201', --20221017   CJL   同步上产
                                 '13010202',
                                 '13010203',
                                 '13010204',
                                 '13010205',
                                 '13010206',
                                 '13010501',
                                 '13010502',
                                 '13010503',
                                 '13010504',
                                 '13010505',
                                 '13010506',
                                 '13010507',
                                 '13010508')
             AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
             AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
             AND B.LOAN_ACCT_BAL <> 0;
        COMMIT;

    ---------------------------------------------------贷款五级分类-关注类----------------------------------------------

    /*五级分类指标表内存放G19统计表内正常类、关注类、次级类、可疑类、损失类/M-Q列指标和其对应的贷款投向代码*/

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生G19指标数据贷款五级分类-关注类，插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

        INSERT 
        INTO CBRC_A_REPT_DWD_G19 
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_1,
           COL_2,
           COL_3,
           COL_4,
           COL_5,
           COL_7)
          SELECT 
           I_DATADATE,
           B.ORG_NUM, --机构号
           B.DEPARTMENTD, --数据条线
           'CBRC' AS SYS_NAM,
           'G19' REP_NUM,
           A.FIVE_2 AS ITEM_NUM, -- 指标号
           B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
           B.LOAN_NUM AS COL_1, --贷款编号
           B.CURR_CD AS COL_2, --币种
           B.ITEM_CD AS COL_3, --科目号
           B.ACCT_NUM AS COL_4, --贷款合同编号
           D.M_NAME AS COL_6, --贷款投向
           '关注' AS COL_7 --五级分类
            FROM CBRC_loan_five_index A -- 五级分类指标表
            LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
              ON A.LOAN_PURPOSE_CD = B.LOAN_PURPOSE_CD
            LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
              ON B.DATA_DATE = R.DATA_DATE
             AND B.CURR_CD = R.BASIC_CCY
             AND R.FORWARD_CCY = 'CNY'
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
              ON A.LOAN_PURPOSE_CD = D.M_CODE
             AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
           WHERE B.DATA_DATE = I_DATADATE
             AND B.LOAN_GRADE_CD = '2' -- 五级形态为关注
             AND LENGTH(A.LOAN_PURPOSE_CD) = 5 -- 贷款投向为5位不需汇总，直接关联取
             AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
             AND B.ACCT_TYP <> '90'
             AND B.CANCEL_FLG = 'N'
             AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
             AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
             AND B.LOAN_ACCT_BAL <> 0
          UNION ALL
          SELECT 
           I_DATADATE,
           B.ORG_NUM, --机构号
           B.DEPARTMENTD, --数据条线
           'CBRC' AS SYS_NAM,
           'G19' REP_NUM,
           A.FIVE_2 AS ITEM_NUM, -- 指标号
           B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
           B.LOAN_NUM AS COL_1, --贷款编号
           B.CURR_CD AS COL_2, --币种
           B.ITEM_CD AS COL_3, --科目号
           B.ACCT_NUM AS COL_4, --贷款合同编号
           D.M_NAME AS COL_6, --贷款投向
           '关注' AS COL_7 --五级分类
            FROM CBRC_loan_five_index A -- 五级分类指标表
            LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
              ON A.LOAN_PURPOSE_CD = SUBSTR(B.LOAN_PURPOSE_CD, 1, 4)
            LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
              ON B.DATA_DATE = R.DATA_DATE
             AND B.CURR_CD = R.BASIC_CCY
             AND R.FORWARD_CCY = 'CNY'
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
              ON A.LOAN_PURPOSE_CD = D.M_CODE
             AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
           WHERE B.DATA_DATE = I_DATADATE
             AND B.LOAN_GRADE_CD = '2' -- 五级形态为关注
             AND LENGTH(A.LOAN_PURPOSE_CD) = 4 -- 贷款投向为4位，向上汇总
             AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
             AND B.ACCT_TYP <> '90'
             AND B.CANCEL_FLG = 'N'
             AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
             AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
             AND B.LOAN_ACCT_BAL <> 0
          UNION ALL
          SELECT 
           I_DATADATE,
           B.ORG_NUM, --机构号
           B.DEPARTMENTD, --数据条线
           'CBRC' AS SYS_NAM,
           'G19' REP_NUM,
           A.FIVE_2 AS ITEM_NUM, -- 指标号
           B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
           B.LOAN_NUM AS COL_1, --贷款编号
           B.CURR_CD AS COL_2, --币种
           B.ITEM_CD AS COL_3, --科目号
           B.ACCT_NUM AS COL_4, --贷款合同编号
           D.M_NAME AS COL_6, --贷款投向
           '关注' AS COL_7 --五级分类
            FROM CBRC_loan_five_index A -- 五级分类指标表
            LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
              ON A.LOAN_PURPOSE_CD = SUBSTR(B.LOAN_PURPOSE_CD, 1, 3)
            LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
              ON B.DATA_DATE = R.DATA_DATE
             AND B.CURR_CD = R.BASIC_CCY
             AND R.FORWARD_CCY = 'CNY'
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
              ON A.LOAN_PURPOSE_CD = D.M_CODE
             AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
           WHERE B.DATA_DATE = I_DATADATE
             AND B.LOAN_GRADE_CD = '2' -- 五级形态为关注
             AND LENGTH(A.LOAN_PURPOSE_CD) = 3 -- 贷款投向为3位，向上汇总
             AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
             AND B.ACCT_TYP <> '90'
             and b.CANCEL_FLG = 'N'
             AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
             AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
             AND B.LOAN_ACCT_BAL <> 0;
        COMMIT;

    ---------------------------------------------------贷款五级分类-次级类----------------------------------------------

    /*五级分类指标表内存放G19统计表内正常类、关注类、次级类、可疑类、损失类/M-Q列指标和其对应的贷款投向代码*/

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生G19指标数据贷款五级分类-次级类，插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

          INSERT 
          INTO CBRC_A_REPT_DWD_G19 
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_1,
             COL_2,
             COL_3,
             COL_4,
             COL_5,
             COL_7)
            SELECT 
             I_DATADATE,
             B.ORG_NUM, --机构号
             B.DEPARTMENTD, --数据条线
             'CBRC' AS SYS_NAM,
             'G19' REP_NUM,
             A.FIVE_3 AS ITEM_NUM, -- 指标号
             B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
             B.LOAN_NUM AS COL_1, --贷款编号
             B.CURR_CD AS COL_2, --币种
             B.ITEM_CD AS COL_3, --科目号
             B.ACCT_NUM AS COL_4, --贷款合同编号
             D.M_NAME AS COL_6, --贷款投向
             '次级' AS COL_7 --五级分类
              FROM CBRC_loan_five_index A -- 五级分类指标表
              LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
                ON A.LOAN_PURPOSE_CD = B.LOAN_PURPOSE_CD
              LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
                ON B.DATA_DATE = R.DATA_DATE
               AND B.CURR_CD = R.BASIC_CCY
               AND R.FORWARD_CCY = 'CNY'
              LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
                ON A.LOAN_PURPOSE_CD = D.M_CODE
               AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
             WHERE B.DATA_DATE = I_DATADATE
               AND B.LOAN_GRADE_CD = '3' -- 五级形态为次级
               AND LENGTH(A.LOAN_PURPOSE_CD) = 5 -- 贷款投向为5位不需汇总，直接关联取
               AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
               AND B.ACCT_TYP <> '90'
               AND B.CANCEL_FLG = 'N'
               AND B.LOAN_STOCKEN_DATE IS NULL --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
               AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
               AND B.LOAN_ACCT_BAL <> 0
            UNION ALL
            SELECT 
             I_DATADATE,
             B.ORG_NUM, --机构号
             B.DEPARTMENTD, --数据条线
             'CBRC' AS SYS_NAM,
             'G19' REP_NUM,
             A.FIVE_3 AS ITEM_NUM, -- 指标号
             B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
             B.LOAN_NUM AS COL_1, --贷款编号
             B.CURR_CD AS COL_2, --币种
             B.ITEM_CD AS COL_3, --科目号
             B.ACCT_NUM AS COL_4, --贷款合同编号
             D.M_NAME AS COL_6, --贷款投向
             '次级' AS COL_7 --五级分类
              FROM CBRC_loan_five_index A -- 五级分类指标表
              LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
                ON A.LOAN_PURPOSE_CD = SUBSTR(B.LOAN_PURPOSE_CD, 1, 4)
              LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
                ON B.DATA_DATE = R.DATA_DATE
               AND B.CURR_CD = R.BASIC_CCY
               AND R.FORWARD_CCY = 'CNY'
              LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
                ON A.LOAN_PURPOSE_CD = D.M_CODE
               AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
             WHERE B.DATA_DATE = I_DATADATE
               AND B.LOAN_GRADE_CD = '3' -- 五级形态为次级
               AND LENGTH(A.LOAN_PURPOSE_CD) = 4 -- 贷款投向为4位，向上汇总
               AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
               AND B.ACCT_TYP <> '90'
               AND B.CANCEL_FLG = 'N'
               AND B.LOAN_STOCKEN_DATE IS NULL --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
               AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
               AND B.LOAN_ACCT_BAL <> 0
            UNION ALL
            SELECT 
             I_DATADATE,
             B.ORG_NUM, --机构号
             B.DEPARTMENTD, --数据条线
             'CBRC' AS SYS_NAM,
             'G19' REP_NUM,
             A.FIVE_3 AS ITEM_NUM, -- 指标号
             B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
             B.LOAN_NUM AS COL_1, --贷款编号
             B.CURR_CD AS COL_2, --币种
             B.ITEM_CD AS COL_3, --科目号
             B.ACCT_NUM AS COL_4, --贷款合同编号
             D.M_NAME AS COL_6, --贷款投向
             '次级' AS COL_7 --五级分类
              FROM CBRC_loan_five_index A -- 五级分类指标表
              LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
                ON A.LOAN_PURPOSE_CD = SUBSTR(B.LOAN_PURPOSE_CD, 1, 3)
              LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
                ON B.DATA_DATE = R.DATA_DATE
               AND B.CURR_CD = R.BASIC_CCY
               AND R.FORWARD_CCY = 'CNY'
              LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
                ON A.LOAN_PURPOSE_CD = D.M_CODE
               AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
             WHERE B.DATA_DATE = I_DATADATE
               AND B.LOAN_GRADE_CD = '3' -- 五级形态为次级
               AND LENGTH(A.LOAN_PURPOSE_CD) = 3 -- 贷款投向为3位，向上汇总
               AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
               AND B.ACCT_TYP <> '90'
               AND B.CANCEL_FLG = 'N'
               AND B.LOAN_STOCKEN_DATE IS NULL --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
               AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
               AND B.LOAN_ACCT_BAL <> 0;
    COMMIT;

    ---------------------------------------------------贷款五级分类-可疑类----------------------------------------------

    /*五级分类指标表内存放G19统计表内正常类、关注类、次级类、可疑类、损失类/M-Q列指标和其对应的贷款投向代码*/

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生G19指标数据贷款五级分类-可疑类，插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

        INSERT 
        INTO CBRC_A_REPT_DWD_G19 
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_1,
           COL_2,
           COL_3,
           COL_4,
           COL_5,
           COL_7)
          SELECT 
           I_DATADATE,
           B.ORG_NUM, --机构号
           B.DEPARTMENTD, --数据条线
           'CBRC' AS SYS_NAM,
           'G19' REP_NUM,
           A.FIVE_4 AS ITEM_NUM, -- 指标号
           B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
           B.LOAN_NUM AS COL_1, --贷款编号
           B.CURR_CD AS COL_2, --币种
           B.ITEM_CD AS COL_3, --科目号
           B.ACCT_NUM AS COL_4, --贷款合同编号
           D.M_NAME AS COL_6, --贷款投向
           '可疑' AS COL_7 --五级分类
            FROM CBRC_loan_five_index A -- 五级分类指标表
            LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
              ON A.LOAN_PURPOSE_CD = B.LOAN_PURPOSE_CD
            LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
              ON B.DATA_DATE = R.DATA_DATE
             AND B.CURR_CD = R.BASIC_CCY
             AND R.FORWARD_CCY = 'CNY'
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
              ON A.LOAN_PURPOSE_CD = D.M_CODE
             AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
           WHERE B.DATA_DATE = I_DATADATE
             AND B.LOAN_GRADE_CD = '4' -- 五级形态为可疑
             AND LENGTH(A.LOAN_PURPOSE_CD) = 5 -- 贷款投向为5位不需汇总，直接关联取
             AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
             AND B.ACCT_TYP <> '90'
             AND B.CANCEL_FLG = 'N'
             AND B.LOAN_STOCKEN_DATE IS NULL --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
             AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
             AND B.LOAN_ACCT_BAL <> 0
          UNION ALL
          SELECT 
           I_DATADATE,
           B.ORG_NUM, --机构号
           B.DEPARTMENTD, --数据条线
           'CBRC' AS SYS_NAM,
           'G19' REP_NUM,
           A.FIVE_4 AS ITEM_NUM, -- 指标号
           B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
           B.LOAN_NUM AS COL_1, --贷款编号
           B.CURR_CD AS COL_2, --币种
           B.ITEM_CD AS COL_3, --科目号
           B.ACCT_NUM AS COL_4, --贷款合同编号
           D.M_NAME AS COL_6, --贷款投向
           '可疑' AS COL_7 --五级分类
            FROM CBRC_loan_five_index A -- 五级分类指标表
            LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
              ON A.LOAN_PURPOSE_CD = SUBSTR(B.LOAN_PURPOSE_CD, 1, 4)
            LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
              ON B.DATA_DATE = R.DATA_DATE
             AND B.CURR_CD = R.BASIC_CCY
             AND R.FORWARD_CCY = 'CNY'
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
              ON A.LOAN_PURPOSE_CD = D.M_CODE
             AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
           WHERE B.DATA_DATE = I_DATADATE
             AND B.LOAN_GRADE_CD = '4' -- 五级形态为可疑
             AND LENGTH(A.LOAN_PURPOSE_CD) = 4 -- 贷款投向为4位，向上汇总
             AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
             AND B.ACCT_TYP <> '90'
             AND B.CANCEL_FLG = 'N'
             AND B.LOAN_STOCKEN_DATE IS NULL --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
             AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
             AND B.LOAN_ACCT_BAL <> 0
          UNION ALL
          SELECT 
           I_DATADATE,
           B.ORG_NUM, --机构号
           B.DEPARTMENTD, --数据条线
           'CBRC' AS SYS_NAM,
           'G19' REP_NUM,
           A.FIVE_4 AS ITEM_NUM, -- 指标号
           B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
           B.LOAN_NUM AS COL_1, --贷款编号
           B.CURR_CD AS COL_2, --币种
           B.ITEM_CD AS COL_3, --科目号
           B.ACCT_NUM AS COL_4, --贷款合同编号
           D.M_NAME AS COL_6, --贷款投向
           '可疑' AS COL_7 --五级分类
            FROM CBRC_loan_five_index A -- 五级分类指标表
            LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
              ON A.LOAN_PURPOSE_CD = SUBSTR(B.LOAN_PURPOSE_CD, 1, 3)
            LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
              ON B.DATA_DATE = R.DATA_DATE
             AND B.CURR_CD = R.BASIC_CCY
             AND R.FORWARD_CCY = 'CNY'
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
              ON A.LOAN_PURPOSE_CD = D.M_CODE
             AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
           WHERE B.DATA_DATE = I_DATADATE
             AND B.LOAN_GRADE_CD = '4' -- 五级形态为可疑
             AND LENGTH(A.LOAN_PURPOSE_CD) = 3 -- 贷款投向为3位，向上汇总
             AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
             AND B.ACCT_TYP <> '90'
             AND B.CANCEL_FLG = 'N'
             AND B.LOAN_STOCKEN_DATE IS NULL --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
             AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
             AND B.LOAN_ACCT_BAL <> 0;
        COMMIT;

    ---------------------------------------------------贷款五级分类-损失类----------------------------------------------

    /*五级分类指标表内存放G19统计表内正常类、关注类、次级类、可疑类、损失类/M-Q列指标和其对应的贷款投向代码*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生G19指标数据贷款五级分类-损失类，插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

       INSERT 
       INTO CBRC_A_REPT_DWD_G19 
         (DATA_DATE,
          ORG_NUM,
          DATA_DEPARTMENT,
          SYS_NAM,
          REP_NUM,
          ITEM_NUM,
          TOTAL_VALUE,
          COL_1,
          COL_2,
          COL_3,
          COL_4,
          COL_5,
          COL_7)
         SELECT 
          I_DATADATE,
          B.ORG_NUM, --机构号
          B.DEPARTMENTD, --数据条线
          'CBRC' AS SYS_NAM,
          'G19' REP_NUM,
          A.FIVE_5 AS ITEM_NUM, -- 指标号
          B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
          B.LOAN_NUM AS COL_1, --贷款编号
          B.CURR_CD AS COL_2, --币种
          B.ITEM_CD AS COL_3, --科目号
          B.ACCT_NUM AS COL_4, --贷款合同编号
          D.M_NAME AS COL_6, --贷款投向
          '可疑' AS COL_7 --五级分类
           FROM CBRC_loan_five_index A -- 五级分类指标表
           LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
             ON A.LOAN_PURPOSE_CD = B.LOAN_PURPOSE_CD
           LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
             ON B.DATA_DATE = R.DATA_DATE
            AND B.CURR_CD = R.BASIC_CCY
            AND R.FORWARD_CCY = 'CNY'
           LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
             ON A.LOAN_PURPOSE_CD = D.M_CODE
            AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
          WHERE B.DATA_DATE = I_DATADATE
            AND B.LOAN_GRADE_CD = '5' -- 五级形态为损失
            AND LENGTH(A.LOAN_PURPOSE_CD) = 5 -- 贷款投向为5位不需汇总，直接关联取
            AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
            AND B.ACCT_TYP <> '90'
            and b.CANCEL_FLG = 'N'
            AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
            AND B.LOAN_ACCT_BAL <> 0
         UNION ALL
         SELECT 
          I_DATADATE,
          B.ORG_NUM, --机构号
          B.DEPARTMENTD, --数据条线
          'CBRC' AS SYS_NAM,
          'G19' REP_NUM,
          A.FIVE_5 AS ITEM_NUM, -- 指标号
          B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
          B.LOAN_NUM AS COL_1, --贷款编号
          B.CURR_CD AS COL_2, --币种
          B.ITEM_CD AS COL_3, --科目号
          B.ACCT_NUM AS COL_4, --贷款合同编号
          D.M_NAME AS COL_6, --贷款投向
          '可疑' AS COL_7 --五级分类
           FROM CBRC_loan_five_index A -- 五级分类指标表
           LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
             ON A.LOAN_PURPOSE_CD = SUBSTR(B.LOAN_PURPOSE_CD, 1, 4)
           LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
             ON B.DATA_DATE = R.DATA_DATE
            AND B.CURR_CD = R.BASIC_CCY
            AND R.FORWARD_CCY = 'CNY'
           LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
             ON A.LOAN_PURPOSE_CD = D.M_CODE
            AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
          WHERE B.DATA_DATE = I_DATADATE
            AND B.LOAN_GRADE_CD = '5' -- 五级形态为损失
            AND LENGTH(A.LOAN_PURPOSE_CD) = 4 -- 贷款投向为4位，向上汇总
            AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
            AND B.ACCT_TYP <> '90'
            and b.CANCEL_FLG = 'N'
            AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
            AND B.LOAN_ACCT_BAL <> 0
         UNION ALL
         SELECT 
          I_DATADATE,
          B.ORG_NUM, --机构号
          B.DEPARTMENTD, --数据条线
          'CBRC' AS SYS_NAM,
          'G19' REP_NUM,
          A.FIVE_5 AS ITEM_NUM, -- 指标号
          B.LOAN_ACCT_BAL * R.CCY_RATE AS TOTAL_VALUE, --贷款余额(本外币合计)
          B.LOAN_NUM AS COL_1, --贷款编号
          B.CURR_CD AS COL_2, --币种
          B.ITEM_CD AS COL_3, --科目号
          B.ACCT_NUM AS COL_4, --贷款合同编号
          D.M_NAME AS COL_6, --贷款投向
          '可疑' AS COL_7 --五级分类
           FROM CBRC_loan_five_index A -- 五级分类指标表
           LEFT JOIN SMTMODS_L_ACCT_LOAN B -- 借据表
             ON A.LOAN_PURPOSE_CD = SUBSTR(B.LOAN_PURPOSE_CD, 1, 3)
           LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
             ON B.DATA_DATE = R.DATA_DATE
            AND B.CURR_CD = R.BASIC_CCY
            AND R.FORWARD_CCY = 'CNY'
           LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING D
             ON A.LOAN_PURPOSE_CD = D.M_CODE
            AND D.M_TABLECODE = 'LOAN_PURPOSE_CD'
          WHERE B.DATA_DATE = I_DATADATE
            AND B.LOAN_GRADE_CD = '5' -- 五级形态为损失
            AND LENGTH(A.LOAN_PURPOSE_CD) = 3 -- 贷款投向为3位，向上汇总
            AND (B.ACCT_TYP NOT LIKE '01%' OR B.ACCT_TYP LIKE '0102%')
            AND B.ACCT_TYP <> '90'
            and b.CANCEL_FLG = 'N'
            AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --  不含转贴现 20250327
            AND B.LOAN_ACCT_BAL <> 0;
    COMMIT;

    ---------------------------------------------------------G19数据插至目标指标表------------------------------------------------
    V_STEP_ID   := 1;
    V_STEP_DESC := '产生G19指标数据，插至 CBRC_A_REPT_ITEM_VAL 目标表';
    V_STEP_FLAG := 0;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT II_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G19' AS REP_NUM,
             A.ITEM_NUM,
             SUM(A.TOTAL_VALUE) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_A_REPT_DWD_G19 A
       GROUP BY A.ORG_NUM, A.ITEM_NUM;
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
   
END proc_cbrc_idx2_g19