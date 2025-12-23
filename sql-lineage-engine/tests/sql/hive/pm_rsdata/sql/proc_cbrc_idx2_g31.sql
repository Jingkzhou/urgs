CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g31(II_DATADATE  IN STRING --跑批日期
                                                 )
/******************************
  @author:CHENGHUIMIN
  @create-date:20211015
  @description:G3101
  @modification history:
  alter by shiyu 20230814 修改内容：金融市场部取数
  alter by shiyu 20230125 新增制度升级指标债券按剩余期限分类
  alter by shiyu 20250327 增加债券投资“修正久期”统计项目
  --JLBA202508060001_关于总账系统对购买的2025年8月8日（含）以后新发行的国债、地方政府债及金融债利息收入进行增值税价税分离的需求  需求提出人:于佳禾 上线时间：20250918 修改人：石雨 修改内容新增科目：新增科目60110509+60110510+60110607+60110608+61110107+61110108+61111407+61111408
  
目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_EV_OVRFLWGPRFT_LOSS_TEMP
     CBRC_PUB_DATA_COLLECT_G3101
集市表：SMTMODS_L_ACCT_FUND_INVEST
     SMTMODS_L_AGRE_BOND_INFO
     SMTMODS_L_AGRE_OTHER_SUBJECT_INFO
     SMTMODS_L_FINA_GL
     SMTMODS_L_PUBL_RATE
     SMTMODS_L_TRAN_EV_OVRFLWG_PRFT_LOSS
  ********************************/
 IS
  V_SCHEMA        VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE     VARCHAR(30); --当前储存过程名称
  V_TAB_NAME      VARCHAR(30); --目标表名
  I_DATADATE      STRING; --数据日期(数值型)YYYYMMDD
  V_DATADATE      VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  V_DATADATE_YEAR VARCHAR(10); --数据日期(字符型)YYYY
  D_DATADATE_CCY  STRING; --数据日期(日期型)YYYYMMDD
  V_STEP_ID       INTEGER; --任务号
  V_STEP_DESC     VARCHAR(4000); --任务描述
  V_STEP_FLAG     INTEGER; --任务执行状态标识
  V_ERRORCODE     VARCHAR(20); --错误编码
  V_ERRORDESC     VARCHAR(280); --错误内容
  V_PER_NUM       VARCHAR(30); --报表编号
  II_STATUS       INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_ZYTQJSZ_SUM   NUMBER(24,6);
  V_ZYTQJSZ_SUM1  NUMBER(24,6);
  V_ZYTQJSZ_SUM2  NUMBER(24,6);
  V_SYSTEM        VARCHAR2(30);

BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID       := 0;
    V_STEP_FLAG     := 0;
    V_STEP_DESC     := '参数初始化处理';
    V_PER_NUM       := 'G31_I';
    I_DATADATE      := II_DATADATE;
    V_DATADATE      := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'),'YYYY-MM-DD');
    V_DATADATE_YEAR := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYY');
    D_DATADATE_CCY  := I_DATADATE;
    V_SYSTEM        := 'CBRC';
    V_PROCEDURE     := UPPER('PROC_CBRC_IDX2_G31');

    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']表历史数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND REP_NUM = V_PER_NUM
       AND FLAG = '2';
    COMMIT;

   
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_PUB_DATA_COLLECT_G3101';

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --========================================================
    --G3101 债券投资合计  待L层可以取数，逻辑需修改从L层出
    --========================================================

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_PER_NUM || '债券投资合计';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ---按类别
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101 
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )

      SELECT a.org_num AS ORG_NUM,
             CASE
                WHEN B.STOCK_PRO_TYPE = 'A' AND B.ISSU_ORG = 'A01' THEN --产品分类,发行主体类型,资产证券化分类,发行主体境内境外标志
                 'G31_I_1.1.A.2018' --1.1国债
                WHEN B.STOCK_PRO_TYPE = 'A' AND B.ISSU_ORG = 'A02' THEN
                 'G31_I_1.2.A.2018' --1.2地方政府债券
                WHEN B.STOCK_PRO_TYPE LIKE 'C%' AND B.ISSU_ORG = 'D02' THEN
                 'G31_I_1.4.A.2018' --1.4政策性金融债
                WHEN SUBSTR(B.STOCK_PRO_TYPE, 1, 1) IN ('C', 'D') AND
                     B.ISSU_ORG LIKE 'B%' AND B.STOCK_ASSET_TYPE IS NULL AND
                     B.ISSUER_INLAND_FLG = 'Y' THEN
                 'G31_I_1.5.A.2018' --'1.5政府机构债券
               WHEN B.STOCK_PRO_TYPE LIKE 'C%' AND
                    B.ISSU_ORG IN ('D03', 'D04', 'D05', 'D06', 'D07') AND
                    B.STOCK_ASSET_TYPE IS NULL AND B.ISSUER_INLAND_FLG = 'Y' THEN
                'G31_I_1.6.A.2018' --1.6商业性金融债
               WHEN B.STOCK_PRO_TYPE = 'D04' AND
                    SUBSTR(B.STOCK_PRO_TYPE, 1, 1) = 'D' AND
                    B.ISSU_ORG LIKE 'C%' THEN
                'G31_I_1.7.1.A.2018' --1.7.1企业债
               WHEN B.STOCK_PRO_TYPE = 'D05' AND
                    SUBSTR(B.STOCK_PRO_TYPE, 1, 1) = 'D' AND
                    B.ISSU_ORG LIKE 'C%' THEN
                'G31_I_1.7.2.A.2018' --1.7.2公司债
               WHEN (B.STOCK_PRO_TYPE LIKE 'D01' OR
                    B.STOCK_PRO_TYPE LIKE 'D02') AND
                    SUBSTR(B.STOCK_PRO_TYPE, 1, 1) = 'D' AND
                    B.ISSU_ORG LIKE 'C%' THEN
                'G31_I_1.7.3.A.2018' --1.7.3企业债务融资工具
               WHEN B.STOCK_ASSET_TYPE IS NOT NULL AND
                    B.ISSUER_INLAND_FLG = 'Y' THEN
                'G31_I_1.8.A.2018' --1.8资产支持证券期末余额
               WHEN B.STOCK_PRO_TYPE LIKE 'F%' AND B.ISSUER_INLAND_FLG = 'N' THEN
                'G31_I_1.9.A.2018' --1.9外国债券
             END ITEM_NUM,
             SUM(NVL(A.Principal_Balance, 0) * U.CCY_RATE) AS ITEM_VALUE --账面余额
        FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00' ---投资业务品种
         AND B.STOCK_ASSET_TYPE IS NULL
         AND B.ISSUER_INLAND_FLG = 'Y'
       GROUP BY a.org_num,
                CASE
                  WHEN B.STOCK_PRO_TYPE = 'A' AND B.ISSU_ORG = 'A01' THEN --产品分类,发行主体类型,资产证券化分类,发行主体境内境外标志
                   'G31_I_1.1.A.2018' --1.1国债
                  WHEN B.STOCK_PRO_TYPE = 'A' AND B.ISSU_ORG = 'A02' THEN
                   'G31_I_1.2.A.2018' --1.2地方政府债券
                  WHEN B.STOCK_PRO_TYPE LIKE 'C%' AND B.ISSU_ORG = 'D02' THEN
                   'G31_I_1.4.A.2018' --1.4政策性金融债
                  WHEN SUBSTR(B.STOCK_PRO_TYPE, 1, 1) IN ('C', 'D') AND
                       B.ISSU_ORG LIKE 'B%' AND B.STOCK_ASSET_TYPE IS NULL AND
                       B.ISSUER_INLAND_FLG = 'Y' THEN
                   'G31_I_1.5.A.2018' --'1.5政府机构债券
                  WHEN B.STOCK_PRO_TYPE LIKE 'C%' AND
                       B.ISSU_ORG IN ('D03', 'D04', 'D05', 'D06', 'D07') AND
                       B.STOCK_ASSET_TYPE IS NULL AND
                       B.ISSUER_INLAND_FLG = 'Y' THEN
                   'G31_I_1.6.A.2018' --1.6商业性金融债
                  WHEN B.STOCK_PRO_TYPE = 'D04' AND
                       SUBSTR(B.STOCK_PRO_TYPE, 1, 1) = 'D' AND
                       B.ISSU_ORG LIKE 'C%' THEN
                   'G31_I_1.7.1.A.2018' --1.7.1企业债
                  WHEN B.STOCK_PRO_TYPE = 'D05' AND
                       SUBSTR(B.STOCK_PRO_TYPE, 1, 1) = 'D' AND
                       B.ISSU_ORG LIKE 'C%' THEN
                   'G31_I_1.7.2.A.2018' --1.7.2公司债
                  WHEN (B.STOCK_PRO_TYPE LIKE 'D01' OR
                       B.STOCK_PRO_TYPE LIKE 'D02') AND
                       SUBSTR(B.STOCK_PRO_TYPE, 1, 1) = 'D' AND
                       B.ISSU_ORG LIKE 'C%' THEN
                   'G31_I_1.7.3.A.2018' --1.7.3企业债务融资工具
                  WHEN B.STOCK_ASSET_TYPE IS NOT NULL AND
                       B.ISSUER_INLAND_FLG = 'Y' THEN
                   'G31_I_1.8.A.2018' --1.8资产支持证券期末余额
                  WHEN B.STOCK_PRO_TYPE LIKE 'F%' AND
                       B.ISSUER_INLAND_FLG = 'N' THEN
                   'G31_I_1.9.A.2018' --1.9外国债券
                END;

    COMMIT;


    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_PER_NUM || '按管理方式';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --自主管理
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101 --PUB_DATA_COLLECT_G31_2016
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT a.org_num AS ORG_NUM,
             'G31_I_1.x.A.2018' ITEM_NUM,
             SUM(NVL(A.Principal_Balance, 0) * U.CCY_RATE) AS ITEM_VALUE --账面余额
        FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00' ---投资业务品种
         AND B.STOCK_ASSET_TYPE IS NULL
         AND B.ISSUER_INLAND_FLG = 'Y'
       GROUP BY a.org_num;
    commit;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_PER_NUM || '按评级';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --按评级（非金融企业债）
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101 --PUB_DATA_COLLECT_G31_2016
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
    --   17沪华信MTN001(101788002)-外部评级C、20四平城投PPN002(032001060)-外部评级AA、18翔控01(X0003118A1600001)-外部评级AA+
    --20230913 业务康立军确认手工修改，与业务不符，默认处理
      SELECT a.org_num AS ORG_NUM,
             case
               when b.APPRAISE_TYPE in ('1', '2') or
                    b.stock_cd = 'X0003118A1600001' then
                'G31_I_1.a.A.2018'
               when b.APPRAISE_TYPE in
                    ('3', '4', '5', '6', '7', '8', '9', 'a', 'b') or
                    b.stock_cd in ('032001060', '101788002') then
                'G31_I_1.b.A.2018'
               else
                'G31_I_1.c.A.2018'
             end ITEM_NUM,
             SUM(NVL(A.Principal_Balance, 0) * U.CCY_RATE) AS ITEM_VALUE --账面余额
        FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00' ---投资业务品种
         AND B.STOCK_ASSET_TYPE IS NULL
         AND B.ISSUER_INLAND_FLG = 'Y'
         and SUBSTR(B.STOCK_PRO_TYPE, 1, 1) = 'D'
         AND B.ISSU_ORG LIKE 'C%' --非金融企业债

       GROUP BY a.org_num,
                case
                  when b.APPRAISE_TYPE in ('1', '2') or
                       b.stock_cd = 'X0003118A1600001' then
                   'G31_I_1.a.A.2018'
                  when b.APPRAISE_TYPE in
                       ('3', '4', '5', '6', '7', '8', '9', 'a', 'b') or
                       b.stock_cd in ('032001060', '101788002') then
                   'G31_I_1.b.A.2018'
                  else
                   'G31_I_1.c.A.2018'
                end;

    commit;

    --按会计分类
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_PER_NUM || '按会计分类';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101 --PUB_DATA_COLLECT_G31_2016
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT a.org_num AS ORG_NUM,
             case
               when a.ACCOUNTANT_TYPE = '1' --交易类
                then
                'G31_I_1.e.A.2018'
               when a.ACCOUNTANT_TYPE = '2' --可供出售类
                then
                'G31_I_1.f.A.2018'
               when a.ACCOUNTANT_TYPE = '3' -- 持有至到期
                then
                'G31_I_1.d.A.2018'
             end ITEM_NUM,
             SUM(NVL(A.Principal_Balance, 0) * U.CCY_RATE) AS ITEM_VALUE --账面余额
        FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00' ---投资业务品种
         AND B.STOCK_ASSET_TYPE IS NULL
         AND B.ISSUER_INLAND_FLG = 'Y'
       GROUP BY a.org_num,
                case
                  when a.ACCOUNTANT_TYPE = '1' --交易类
                   then
                   'G31_I_1.e.A.2018'
                  when a.ACCOUNTANT_TYPE = '2' --可供出售类
                   then
                   'G31_I_1.f.A.2018'
                  when a.ACCOUNTANT_TYPE = '3' -- 持有至到期
                   then
                   'G31_I_1.d.A.2018'
                end;
    commit;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_PER_NUM || '投资收入';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ---投资收入（年初至报告期末数）
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101 --PUB_DATA_COLLECT_G31_2016
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT G.ORG_NUM,
             'G31_I_1.x.B.2018' ITEM_NUM,
             SUM(CASE
                   WHEN G.ITEM_CD IN ('611105', '61110101', '6101', '611106',
                     --[JLBA202508060001][于佳禾][20250918][石雨][新增科目(60110509+60110510+60110607+60110608)贷+（61110107+61110108+61111407+61111408）贷-借]
                     '61110107','61110108','61111407','61111408') THEN
                    G.CREDIT_BAL - G.DEBIT_BAL --贷-借
                   ELSE
                    G.CREDIT_BAL
                 END * U.CCY_RATE) ITEM_VALUE
        FROM SMTMODS_L_FINA_GL G
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE G.ORG_NUM = '009804'
         AND G.DATA_DATE = I_DATADATE
         AND G.ITEM_CD IN ('60110501',
                           '60110502',
                           '60110503',
                           '611105',
                           '61110102',
                           '61110103',
                           '61110104',
                           '61110101',
                           '6101',
                           '60110601',
                           '60110602',
                           '60110603',
                           '611106',
                           --[JLBA202508060001][于佳禾][20250918][石雨][新增科目(60110509+60110510+60110607+60110608)贷+（61110107+61110108+61111407+61111408）贷-借]
                           '60110509','60110510','60110607','60110608',
                           '61110107','61110108','61111407','61111408'
                           )
       GROUP BY G.ORG_NUM;
    COMMIT;

    --1.d 以摊余成本计量

    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101 --PUB_DATA_COLLECT_G31_2016
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT G.ORG_NUM,
             'G31_I_1.d.B.2018' ITEM_NUM,
             SUM(CASE
                   WHEN G.ITEM_CD IN ('611105') THEN
                    G.CREDIT_BAL - G.DEBIT_BAL
                   ELSE
                    G.CREDIT_BAL
                 END * U.CCY_RATE) ITEM_VALUE
        FROM SMTMODS_L_FINA_GL G
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE G.ORG_NUM = '009804'
         AND G.DATA_DATE = I_DATADATE
         AND G.ITEM_CD IN ('60110501', '60110502', '60110503', '611105',
           --[JLBA202508060001][于佳禾][20250918][石雨][新增科目(60110509+60110510+60110607+60110608)贷]
                           '60110509','60110510','60110607','60110608'
                           )
       GROUP BY G.ORG_NUM;
    COMMIT;

    --1.e 以公允价值计量且变动计入当期损益

    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101 --PUB_DATA_COLLECT_G31_2016
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT G.ORG_NUM,
             'G31_I_1.e.B.2018' ITEM_NUM,
             SUM(CASE
                   WHEN G.ITEM_CD IN ('61110101', '6101', '61110107','61110108','61111407','61111408'--[JLBA202508060001][于佳禾][20250918][石雨][新增科目（61110107+61110108+61111407+61111408）贷-借]
                     ) THEN
                    G.CREDIT_BAL - G.DEBIT_BAL
                   ELSE
                    G.CREDIT_BAL
                 END * U.CCY_RATE) ITEM_VALUE
        FROM SMTMODS_L_FINA_GL G
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE G.ORG_NUM = '009804'
         AND G.DATA_DATE = I_DATADATE
         AND G.ITEM_CD IN
             ('61110102', '61110103', '61110104', '61110101', '6101',
               '61110107','61110108','61111407','61111408'--[JLBA202508060001][于佳禾][20250918][石雨][新增科目（61110107+61110108+61111407+61111408）贷-借]

             )
       GROUP BY G.ORG_NUM;
    COMMIT;

    --1.f 以公允价值计量且变动计入其他综合收益

    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101 --PUB_DATA_COLLECT_G31_2016
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT G.ORG_NUM,
             'G31_I_1.f.B.2018' ITEM_NUM,
             SUM(CASE
                   WHEN G.ITEM_CD IN ('611106') THEN
                    G.CREDIT_BAL - G.DEBIT_BAL
                   ELSE
                    G.CREDIT_BAL
                 END * U.CCY_RATE) ITEM_VALUE
        FROM SMTMODS_L_FINA_GL G
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE G.ORG_NUM = '009804'
         AND G.DATA_DATE = I_DATADATE
         AND G.ITEM_CD IN ('60110601', '60110602', '60110603', '611106')

       GROUP BY G.ORG_NUM;
    COMMIT;

    --二级资本债
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101 --PUB_DATA_COLLECT_G31_2016
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT a.org_num AS ORG_NUM,
             'G31_I_0_1.3.A.2022' ITEM_NUM,
             SUM(NVL(A.Principal_Balance, 0) * U.CCY_RATE) AS ITEM_VALUE --账面余额
        FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00' ---投资业务品种
         AND B.STOCK_ASSET_TYPE IS NULL
         AND B.ISSUER_INLAND_FLG = 'Y'
         and b.stock_pro_type in ( /*'C01',*/ 'C0101')
       GROUP BY a.org_num;

  V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_PER_NUM || '债券投资合计按剩余期限分类';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --alter by shiyu 20230125 新增制度升级指标债券按剩余期限分类

    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT a.org_num AS ORG_NUM,
            /* CASE
               WHEN a.BOOK_TYPE = '2' and A.DC_DATE / 365 > 10 AND
                    b.STOCK_NAM <> '18华阳经贸CP001' THEN
                'G31_I_1.k.A.2024' ---10年以上
               WHEN A.BOOK_TYPE = '2' and A.DC_DATE / 365 > 5 THEN
                'G31_I_1.j.A.2024' --5-10年
               WHEN A.BOOK_TYPE = '2' and A.DC_DATE > 365 THEN
                'G31_I_1.i.A.2024' --1-5年
               ELSE
                'G31_I_1.h.A.2024'
             END ITEM_NUM,*/
            CASE
               WHEN  A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'   THEN
                'G31_I_1.k.A.2024' ---10年以上
               WHEN  A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001' THEN
                'G31_I_1.j.A.2024' --5-10年
               WHEN  A.DC_DATE > 360   AND b.STOCK_NAM <> '18华阳经贸CP001' THEN
                'G31_I_1.i.A.2024' --1-5年
               ELSE
                'G31_I_1.h.A.2024'
             END ITEM_NUM,     --ADD  BY  ZY 修改完成
             SUM(NVL(A.Principal_Balance, 0) * U.CCY_RATE) AS ITEM_VALUE --账面余额
        FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00' ---投资业务品种
         AND B.STOCK_ASSET_TYPE IS NULL
         AND B.ISSUER_INLAND_FLG = 'Y'
       GROUP BY a.org_num,
                 CASE
               WHEN  A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'   THEN
                'G31_I_1.k.A.2024' ---10年以上
               WHEN  A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001' THEN
                'G31_I_1.j.A.2024' --5-10年
               WHEN  A.DC_DATE > 360   AND b.STOCK_NAM <> '18华阳经贸CP001' THEN
                'G31_I_1.i.A.2024' --1-5年
               ELSE
                'G31_I_1.h.A.2024'
             END ;
    COMMIT;



    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_PER_NUM || '3.1债券基金-期末余额';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_I_3.1.A.2024' AS ITEM_NUM,
             SUM(A.ACCT_BAL * TT.CCY_RATE + A.MK_VAL * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B --债券信息表
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '01' --基金
         AND B.SUBJECT_PRO_TYPE = '0102' --债券基金
       GROUP BY A.ORG_NUM;

    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_PER_NUM || '3.2货币市场基金-期末余额';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_I_3.2.A.2024' AS ITEM_NUM,
             SUM(A.ACCT_BAL * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B --债券信息表
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '01' --基金
         AND B.SUBJECT_PRO_TYPE = '0103' --货币市场共同基金
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_PER_NUM || '3.y委托管理（公募基金-期末余额';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_I_3.y.A.2024' AS ITEM_NUM,
             SUM(CASE
                   WHEN B.SUBJECT_PRO_TYPE = '0102' --债券基金
                    THEN
                    A.ACCT_BAL * TT.CCY_RATE + A.MK_VAL * TT.CCY_RATE
                   WHEN B.SUBJECT_PRO_TYPE = '0103' --货币市场共同基金
                    THEN
                    A.ACCT_BAL * TT.CCY_RATE
                 END)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B --债券信息表
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '01' --基金
         AND B.SUBJECT_PRO_TYPE in ('0102', --债券基金
                                    '0103') --货币市场共同基金
       GROUP BY A.ORG_NUM;
    commit;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_PER_NUM || '3.y委托管理公募基金-收益';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_I_3.y.B.2024' AS ITEM_NUM,
             SUM(CASE
                   WHEN A.ITEM_CD = '61110202' THEN
                    A.CREDIT_BAL * TT.CCY_RATE - A.DEBIT_BAL * TT.CCY_RATE
                   WHEN A.ITEM_CD = '61111302' THEN
                    A.CREDIT_BAL * TT.CCY_RATE
                 END)
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('61110202', '61111302')
      --AND A.ORG_NUM = '009820'
       GROUP BY A.ORG_NUM;
    COMMIT;




           --========================================================================================================
        --========================================================================================================
            --========================================================================================================
                                                  --G31_II  投资业务情况表
            --========================================================================================================
        --========================================================================================================
            --========================================================================================================

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '5.1理财产品-期末余额';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --取类型是银行理财产品投资的持有仓位
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.1.A.2018' AS ITEM_NUM,
             SUM(A.ACCT_BAL * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP LIKE '05%' --理财
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '5.1理财产品.投资收入（年初至报告期末数）';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--银行理财产品投资的利息收益
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.1.B.2018' AS ITEM_NUM,
             SUM(A.THISMONTH_DIVIDEND_INTEREST * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP LIKE '05%' --理财
       GROUP BY A.ORG_NUM;
    COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '5.2信托产品-期末余额';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --009820:取类型是信托计划投资的持有仓位；
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.2.A.2018' AS ITEM_NUM,
             SUM(CASE
                   WHEN A.ORG_NUM = '009817' THEN A.PRINCIPAL_BALANCE * TT.CCY_RATE
                   ELSE A.ACCT_BAL * TT.CCY_RATE + A.MK_VAL * TT.CCY_RATE
                 END)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP LIKE '04%' --信托
       GROUP BY A.ORG_NUM;
    COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '5.2信托产品|投资收入（年初至报告期末数）';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--信托计划投资的利息收益,委外的利息收益去业务状况表取，台账不准；委外的利息取科目61111304交易性特定目的载体投资非应税投资收入
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.2.B.2018' AS ITEM_NUM,
             SUM(A.THISMONTH_DIVIDEND_INTEREST * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP LIKE '04%' --信托
       GROUP BY A.ORG_NUM;
    COMMIT;

/*    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
    SELECT T.ORG_NUM,
            'G31_II_5.2.B.2018' AS ITEM_NUM,
            SUM(T.CREDIT_BAL)
      FROM SMTMODS_L_FINA_GL T
     WHERE T.DATA_DATE = I_DATADATE
       AND T.ITEM_CD = '61111304'
       AND T.CURR_CD = 'BWB'
       AND T.ORG_NUM = '009820'
     GROUP BY T.ORG_NUM;
    COMMIT;*/

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '5.3证券业资产管理产品（不含公募基金）-期末余额';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --009820:取类型是资管计划投资的持有仓位；扣掉民生通惠资产管理有限公司，该公司属于资管中的保险类；
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.3.A.2018' AS ITEM_NUM,
             SUM((A.ACCT_BAL * TT.CCY_RATE) + (A.MK_VAL * TT.CCY_RATE))
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         --AND A.INVEST_TYP LIKE '12%' --资管计划
         AND B.ISSU_ORG_NAM NOT LIKE '民生通惠%'
         AND SUBSTR(A.INVEST_TYP, 1, 2) IN ('12', '99')
         AND A.ACCT_NUM NOT IN ('N000310000012723','N000310000012748')
       GROUP BY A.ORG_NUM;
    COMMIT;

    --009817:存量非标证券业业务的本金
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.3.A.2018' AS ITEM_NUM,
             SUM(A.PRINCIPAL_BALANCE * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
         AND A.INVEST_TYP LIKE '12%' --资管计划
       GROUP BY A.ORG_NUM;
    COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '5.3证券业资产管理产品|投资收入（年初至报告期末数）';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--资管计划投资的利息收益； 扣掉民生通惠资产管理有限公司，该公司属于资管中的保险类
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.3.B.2018' AS ITEM_NUM,
             SUM(A.THISMONTH_DIVIDEND_INTEREST * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         --AND A.INVEST_TYP LIKE '12%' --资管计划
         AND B.ISSU_ORG_NAM NOT LIKE '民生通惠%'
         AND SUBSTR(A.INVEST_TYP, 1, 2) IN ('12', '99')
         AND A.ACCT_NUM NOT IN ('N000310000012723','N000310000012748')
       GROUP BY A.ORG_NUM;
    COMMIT;



    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '5.4保险业资产管理产品-期末余额';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --取民生通惠资产管理有限公司，该公司属于资管中的保险类；
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.4.A.2018' AS ITEM_NUM,
             SUM((A.ACCT_BAL * TT.CCY_RATE) + (A.MK_VAL * TT.CCY_RATE))
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP LIKE '12%' --资管计划
         AND B.ISSU_ORG_NAM LIKE '民生通惠%'
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '5.4保险业资产管理产品|投资收入（年初至报告期末数）';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--民生通惠资产管理有限公司，该公司属于资管中的保险类，取该公司的利息收益
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.4.B.2018' AS ITEM_NUM,
             SUM(A.THISMONTH_DIVIDEND_INTEREST * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP LIKE '12%' --资管计划
         AND B.ISSU_ORG_NAM LIKE '民生通惠%'
       GROUP BY A.ORG_NUM;
    COMMIT;



    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '5.5其他资产管理产品-期末余额';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.5.A.2018' AS ITEM_NUM,
             SUM(A.PRINCIPAL_BALANCE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP LIKE '99%' --其它投资
         AND A.ACCT_NUM  IN ('N000310000012723','N000310000012748')
         AND B.PROTYPE_DIS = '其他同业投资'
       GROUP BY A.ORG_NUM;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '5.5其他资产管理产品|投资收入（年初至报告期末数）';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--其他同业投资利息收益；
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.5.B.2018' AS ITEM_NUM,
             SUM(A.THISMONTH_DIVIDEND_INTEREST * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP LIKE '99%' --其它投资
         AND A.ACCT_NUM  IN ('N000310000012723','N000310000012748')
         AND B.PROTYPE_DIS = '其他同业投资'
       GROUP BY A.ORG_NUM;
   COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '5.x自主管理（资产管理产品）|期末余额';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --009820;取账户类型是AC账户的持有仓位；
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.x.A.2018' AS ITEM_NUM,
             SUM(A.ACCT_BAL * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCOUNTANT_TYPE = '3' --AC账户
         AND A.ORG_NUM NOT IN ('009817','009804')
         AND SUBSTR(A.INVEST_TYP,1,2) IN ('04','05','12','99')
         AND (A.MATURITY_DATE >= I_DATADATE OR A.MATURITY_DATE < I_DATADATE AND A.ACCT_BAL >= 0)
       GROUP BY A.ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
    SELECT A.ORG_NUM,
           'G31_II_5.x.A.2018' AS ITEM_NUM,
           SUM(A.PRINCIPAL_BALANCE * TT.CCY_RATE)
      FROM SMTMODS_L_ACCT_FUND_INVEST A
      LEFT JOIN SMTMODS_L_PUBL_RATE TT
        ON TT.CCY_DATE = I_DATADATE
       AND TT.BASIC_CCY = A.CURR_CD
       AND TT.FORWARD_CCY = 'CNY'
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ORG_NUM = '009817'
       AND SUBSTR(A.INVEST_TYP, 1, 2) IN ('12')
     GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '5.x自主管理|投资收入（年初至报告期末数）';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--取AC账户的利息收益
   INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.x.B.2018' AS ITEM_NUM,
             SUM(A.THISMONTH_DIVIDEND_INTEREST * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCOUNTANT_TYPE = '3' --AC账户
         AND SUBSTR(A.INVEST_TYP,1,2) IN ('04','05','12','99')
         AND A.ORG_NUM NOT IN ('009817','009804')
         AND (A.MATURITY_DATE >= I_DATADATE OR A.MATURITY_DATE < I_DATADATE AND A.ACCT_BAL >= 0)
       GROUP BY A.ORG_NUM;
    COMMIT;


   INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.x.B.2018' AS ITEM_NUM,
             SUM(A.THISMONTH_DIVIDEND_INTEREST * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.INVEST_TYP,1,2) IN ('12')
         AND A.ORG_NUM = '009817'
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '5.y委托管理（资产管理产品）|期末余额';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--009820;取账户类型是FVTPL账户持有仓位+公允;
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.y.A.2018' AS ITEM_NUM,
             SUM((NVL(A.ACCT_BAL,0) * TT.CCY_RATE) + (NVL(A.MK_VAL,0) * TT.CCY_RATE))
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCOUNTANT_TYPE = '1' --1 交易类 FVTPL账户
         AND SUBSTR(A.INVEST_TYP,1,2) IN ('04','05','12','99')
         AND A.ORG_NUM NOT IN ('009817','009804')
         AND (A.MATURITY_DATE >= I_DATADATE OR A.MATURITY_DATE < I_DATADATE AND A.ACCT_BAL >= 0)
       GROUP BY A.ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.y.A.2018' AS ITEM_NUM,
             SUM(NVL(A.PRINCIPAL_BALANCE,0) * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM IN ( '009817','009804')
         AND SUBSTR(A.INVEST_TYP,1,2) IN ('04')
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '5.y委托管理|投资收入（年初至报告期末数）';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--取账户类型是FVTPL账户利息收益
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.y.B.2018' AS ITEM_NUM,
             SUM(NVL(A.THISMONTH_DIVIDEND_INTEREST,0) * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCOUNTANT_TYPE = '1' --1 交易类 FVTPL账户
         AND SUBSTR(A.INVEST_TYP,1,2) IN ('04','05','12','99')
         AND A.ORG_NUM NOT IN ('009817','009804')
         AND (A.MATURITY_DATE >= I_DATADATE OR A.MATURITY_DATE < I_DATADATE AND A.ACCT_BAL >= 0)
       GROUP BY A.ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.y.B.2018' AS ITEM_NUM,
             SUM(NVL(A.THISMONTH_DIVIDEND_INTEREST,0) * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM IN ('009817','009804')
         AND SUBSTR(A.INVEST_TYP,1,2) IN ('04')
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '5.a公募（资产管理产品）|期末余额';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--009820;取类型是资管计划，取AC账户持有仓位+FVTPL账户持有仓位+公允；
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.a.A.2019' AS ITEM_NUM,
             SUM(
               CASE
                 WHEN ACCOUNTANT_TYPE = '1' THEN (NVL(A.ACCT_BAL,0) * TT.CCY_RATE) + (NVL(A.MK_VAL,0) * TT.CCY_RATE)
                 WHEN A.ACCOUNTANT_TYPE = '3' THEN NVL(A.ACCT_BAL,0) * TT.CCY_RATE
               END)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM <> '009817'
         AND SUBSTR(A.INVEST_TYP,1,2) IN ('04','05','12','99')
         AND (A.MATURITY_DATE >= I_DATADATE OR A.MATURITY_DATE < I_DATADATE AND A.ACCT_BAL >= 0)
       GROUP BY A.ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.a.A.2019' AS ITEM_NUM,
             SUM((NVL(A.PRINCIPAL_BALANCE,0) * TT.CCY_RATE))
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '5.a公募|投资收入（年初至报告期末数）';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--资管计划中取FVTPL账户的利息收益
   INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.a.B.2019' AS ITEM_NUM,
             SUM(NVL(A.THISMONTH_DIVIDEND_INTEREST,0) * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.INVEST_TYP,1,2) IN ('04','05','12','99')
         AND A.ORG_NUM <> '009817'
         AND (A.MATURITY_DATE >= I_DATADATE OR A.MATURITY_DATE < I_DATADATE AND A.ACCT_BAL >= 0)
       GROUP BY A.ORG_NUM;
    COMMIT;

   INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.a.B.2019' AS ITEM_NUM,
             SUM(NVL(A.THISMONTH_DIVIDEND_INTEREST,0) * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '9.全部投资合计|期末余额';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--5.4保险业资产管理产品|期末余额+5.5其他资产管理产品|期末余额+5.x自主管理（资产管理产品）|期末余额+5.y委托管理（资产管理产品）|期末余额+5.a公募（资产管理产品）|期末余额+
--债券基金投资持有仓位+债券基金投资公允+货币市场基金投资持有仓位
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_8..A.2018' AS ITEM_NUM,
             SUM(
               CASE
                 WHEN B.PROTYPE_DIS = '债券基金投资' THEN (NVL(A.ACCT_BAL,0) + NVL(A.MK_VAL,0)) * TT.CCY_RATE
                 WHEN B.PROTYPE_DIS = '货币基金投资' THEN  NVL(A.ACCT_BAL,0) * TT.CCY_RATE
                 WHEN A.ORG_NUM = '009817' THEN A.PRINCIPAL_BALANCE * TT.CCY_RATE
                 WHEN A.ORG_NUM = '009804' THEN NVL(A.PRINCIPAL_BALANCE,0) * TT.CCY_RATE
                ELSE (NVL(A.ACCT_BAL,0) + NVL(A.MK_VAL,0)) * TT.CCY_RATE
               END
             )
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM;
    COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '9.全部投资合计|投资收入（年初至报告期末数）';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--5.4保险业资产管理产品|投资收入+5.5其他资产管理产品|投资收入+5.x自主管理（资产管理产品）|投资收入+
--5.y委托管理（资产管理产品）|投资收入+5.a公募（资产管理产品）|投资收入+G3101的y委托管理（公募基金）投资收入

    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_8..B.2018' AS ITEM_NUM,
             SUM(NVL(A.THISMONTH_DIVIDEND_INTEREST,0) * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCOUNTANT_TYPE = '1' --1 交易类 FVTPL账户
         AND SUBSTR(A.INVEST_TYP,1,2) IN ('04','05','12','99','00')
         AND A.ORG_NUM = '009820'
         AND (A.MATURITY_DATE >= I_DATADATE OR A.MATURITY_DATE < I_DATADATE AND A.ACCT_BAL >= 0)
       GROUP BY A.ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
    SELECT A.ORG_NUM,
           'G31_II_8..B.2018' AS ITEM_NUM,
           SUM(CASE
                 WHEN A.ITEM_CD = '61110202' THEN
                  A.CREDIT_BAL * TT.CCY_RATE - A.DEBIT_BAL * TT.CCY_RATE
                 WHEN A.ITEM_CD = '61111302' THEN
                  A.CREDIT_BAL * TT.CCY_RATE
               END)
      FROM SMTMODS_L_FINA_GL A
      LEFT JOIN SMTMODS_L_PUBL_RATE TT
        ON TT.CCY_DATE = I_DATADATE
       AND TT.BASIC_CCY = A.CURR_CD
       AND TT.FORWARD_CCY = 'CNY'
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ITEM_CD IN ('61110202', '61111302')
       AND A.ORG_NUM = '009820'
     GROUP BY A.ORG_NUM;


    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
    SELECT G.ORG_NUM,
           'G31_II_8..B.2018' ITEM_NUM,
           SUM(CASE
                 WHEN G.ITEM_CD IN ('611105', '61110101', '6101', '611106') THEN
                  G.CREDIT_BAL - G.DEBIT_BAL
                 ELSE
                  G.CREDIT_BAL
               END * U.CCY_RATE) ITEM_VALUE
      FROM SMTMODS_L_FINA_GL G
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = I_DATADATE
       AND U.BASIC_CCY = G.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
     WHERE G.ORG_NUM = '009804'
       AND G.DATA_DATE = I_DATADATE
       AND G.ITEM_CD IN ('60110501',
                         '60110502',
                         '60110503',
                         '611105',
                         '61110102',
                         '61110103',
                         '61110104',
                         '61110101',
                         '6101',
                         '60110601',
                         '60110602',
                         '60110603',
                         '611106')
     GROUP BY G.ORG_NUM;
   COMMIT;


    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_8..B.2018' AS ITEM_NUM,
             SUM(NVL(A.THISMONTH_DIVIDEND_INTEREST,0) * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.INVEST_TYP,1,2) IN ('04','05','12','99','00')
         AND A.ORG_NUM = '009817'
       GROUP BY A.ORG_NUM;
    COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '9.y委托管理合计|期末余额';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--009820:取账户类型是FVTPL账户持有仓位+FVTPL账户的公允+债券基金投资持有仓位+债券基金投资公允+货币市场基金投资持有仓位;
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_8.y.A.2018' AS ITEM_NUM,
             SUM(
               CASE
                 WHEN A.ACCOUNTANT_TYPE = '1' THEN (NVL(A.ACCT_BAL,0) + NVL(A.MK_VAL,0)) * TT.CCY_RATE
                 WHEN PROTYPE_DIS = '债券基金投资' THEN (NVL(A.ACCT_BAL,0) + NVL(A.MK_VAL,0)) * TT.CCY_RATE
                 WHEN PROTYPE_DIS = '货币基金投资' THEN NVL(A.PRINCIPAL_BALANCE,0) * TT.CCY_RATE
               END
                )
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM NOT IN('009817','009804')
         AND (A.ACCOUNTANT_TYPE = '1' OR A.INVEST_TYP = '01')
       GROUP BY A.ORG_NUM;
    COMMIT;


-- 009804 009817：存量非标信托业务的本金
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_8.y.A.2018' AS ITEM_NUM,
             SUM(A.PRINCIPAL_BALANCE * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '04'
         AND A.ORG_NUM IN('009817','009804')
       GROUP BY A.ORG_NUM;
    COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '9.y委托管理合计|投资收入（年初至报告期末数）';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--取账户类型是FVTPL账户利息收益+G3101的y委托管理（公募基金）投资收入
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
    SELECT A.ORG_NUM,
           'G31_II_8.y.B.2018' AS ITEM_NUM,
           SUM(CASE
                 WHEN A.ITEM_CD = '61110202' THEN
                  A.CREDIT_BAL * TT.CCY_RATE - A.DEBIT_BAL * TT.CCY_RATE
                 WHEN A.ITEM_CD = '61111302' THEN
                  A.CREDIT_BAL * TT.CCY_RATE
               END)
      FROM SMTMODS_L_FINA_GL A
      LEFT JOIN SMTMODS_L_PUBL_RATE TT
        ON TT.CCY_DATE = I_DATADATE
       AND TT.BASIC_CCY = A.CURR_CD
       AND TT.FORWARD_CCY = 'CNY'
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ITEM_CD IN ('61110202', '61111302')
       AND A.ORG_NUM <> '009817'
     GROUP BY A.ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_8.y.B.2018' AS ITEM_NUM,
             SUM(A.THISMONTH_DIVIDEND_INTEREST * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B --债券信息表
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCOUNTANT_TYPE = '1' --1 交易类 FVTPL账户
         AND A.INVEST_TYP <> '01'
         AND A.ORG_NUM <> '009817'
       GROUP BY A.ORG_NUM;
    COMMIT;


    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_8.y.B.2018' AS ITEM_NUM,
             SUM(A.THISMONTH_DIVIDEND_INTEREST * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '9.全部投资合计|货币市场工具及货币市场公募基金';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--货币市场基金投资持有仓位+公允
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_8..C.2018' AS ITEM_NUM,
             SUM(A.ACCT_BAL * TT.CCY_RATE + A.MK_VAL * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B --债券信息表
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '01' --基金
         AND B.SUBJECT_PRO_TYPE = '0103' --货币市场共同基金
       GROUP BY A.ORG_NUM;
    COMMIT;




    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '9.全部投资合计|债券及债券公募基金';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--债券基金投资持有仓位+公允
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_8..D.2018' AS ITEM_NUM,
             SUM(A.ACCT_BAL * TT.CCY_RATE + A.MK_VAL * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B --债券信息表
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '01' --基金
         AND B.SUBJECT_PRO_TYPE = '0102' --债券基金
       GROUP BY A.ORG_NUM;
    COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '5.2信托产品|最终投向类型';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
 --009817:存量非标信托业务穿透为信贷类的金额；因为是存量业务，穿透固定
 --009804:穿透固定 ：其他
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             CASE
               WHEN A.ORG_NUM = '009804' THEN 'G31_II_5.2.H.2018'
               WHEN A.ORG_NUM = '009817' THEN 'G31_II_5.2.F.2018'
             END AS ITEM_NUM,
             SUM(A.PRINCIPAL_BALANCE * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '04'
         AND A.ORG_NUM IN ( '009817','009804')
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '5.3证券业资产管理产品（不含公募基金）|最终投向类型';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
--009817:存量非标证券业穿透为信贷类的金额；因为是存量业务，穿透固定
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.3.F.2018' AS ITEM_NUM,
             SUM(A.PRINCIPAL_BALANCE * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '12'
         AND A.ORG_NUM = '009817'
       GROUP BY A.ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
       SELECT A.ORG_NUM,
              'G31_II_8..D.2018' AS ITEM_NUM,
              SUM(NVL(A.PRINCIPAL_BALANCE, 0) * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009804'
         AND A.INVEST_TYP <> '04'
       GROUP BY A.ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
       SELECT A.ORG_NUM,
              'G31_II_8..H.2018' AS ITEM_NUM,
              SUM(NVL(A.PRINCIPAL_BALANCE, 0) * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009804'
         AND A.INVEST_TYP = '04'
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '5.2信托产品|（最终投向为信贷类、权益类或其他的）行业归属';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
--009817:存量非标信托业务穿透为基础设施建设的金额;因为是存量业务，穿透固定
--009804:固定穿透 ：建筑业
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             CASE
               WHEN A.ORG_NUM = '009804' THEN 'G31_II_5.2.L.2018'
               WHEN A.ORG_NUM = '009817' THEN 'G31_II_5.2.M.2018'
             END AS ITEM_NUM,
             SUM(A.PRINCIPAL_BALANCE * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '04'
         AND A.ORG_NUM IN ('009817','009804')
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || '5.3证券业资产管理产品（不含公募基金）|（最终投向为信贷类、权益类或其他的）行业归属';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--009817:存量非标证券业穿透为建筑业的金额;因为是存量业务，穿透固定
    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.3.L.2018' AS ITEM_NUM,
             SUM(A.PRINCIPAL_BALANCE * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '12'
         AND A.ORG_NUM = '009817'
       GROUP BY A.ORG_NUM;
    COMMIT;


----add  by  zy  20240902   1.2.1专项债券
INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
select 
A.ORG_NUM,
             'G31_I_1.2.1.A.2021' AS ITEM_NUM,
SUM(A.PRINCIPAL_BALANCE * U.CCY_RATE ) AS ITEM_VALUE  --账面余额
        FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00' ---投资业务品种，债券投资
          AND B.FXZJYT ='02'  ---专项债券
         AND B.STOCK_ASSET_TYPE IS NULL
         AND B.ISSUER_INLAND_FLG = 'Y'
         AND B.STOCK_PRO_TYPE = 'A' AND B.ISSU_ORG = 'A02'
         GROUP BY A.ORG_NUM ;
         COMMIT;
 ---add  by  zy  20240902   1.2.1专项债券


 ---alter by 20250327 2025年制度升级 新增修正久期数据

  --  清除临时表
   EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_EV_OVRFLWGPRFT_LOSS_TEMP';


   INSERT INTO CBRC_EV_OVRFLWGPRFT_LOSS_TEMP
     (DATA_DATE,
      ZQLX,
      ME,
      ZYTJGXZJQ,
      ZYTQJSZ,
      JYTZ,
      STOCK_CD,
      STOCK_NAM,
      INTFC_NO)
    SELECT A.DATA_DATE,
        CASE
           WHEN B.STOCK_PRO_TYPE = 'A' AND B.ISSU_ORG = 'A01' THEN --产品分类,发行主体类型,资产证券化分类,发行主体境内境外标志
            '国债' --1.1国债
           WHEN B.STOCK_PRO_TYPE = 'A' AND B.ISSU_ORG = 'A02' THEN
            '地方政府债券' --1.2地方政府债券
           WHEN B.STOCK_PRO_TYPE LIKE 'C%' AND B.ISSU_ORG = 'D02' THEN
            '政策性金融债' --1.4政策性金融债
           WHEN SUBSTR(B.STOCK_PRO_TYPE, 1, 1) IN ('C', 'D') AND
                B.ISSU_ORG LIKE 'B%' AND B.STOCK_ASSET_TYPE IS NULL AND
                B.ISSUER_INLAND_FLG = 'Y' THEN
            '政府机构债券' --'1.5政府机构债券
          WHEN B.STOCK_PRO_TYPE LIKE 'C%' AND
               B.ISSU_ORG IN ('D03', 'D04', 'D05', 'D06', 'D07') AND
               B.STOCK_ASSET_TYPE IS NULL AND B.ISSUER_INLAND_FLG = 'Y' THEN
           '商业性金融债' --1.6商业性金融债
          WHEN B.STOCK_PRO_TYPE = 'D04' AND
               SUBSTR(B.STOCK_PRO_TYPE, 1, 1) = 'D' AND B.ISSU_ORG LIKE 'C%' THEN
           '企业债' --1.7.1企业债
          WHEN B.STOCK_PRO_TYPE = 'D05' AND
               SUBSTR(B.STOCK_PRO_TYPE, 1, 1) = 'D' AND B.ISSU_ORG LIKE 'C%' THEN
           '公司债' --1.7.2公司债
          WHEN (B.STOCK_PRO_TYPE LIKE 'D01' OR B.STOCK_PRO_TYPE LIKE 'D02' or
               B.STOCK_PRO_TYPE LIKE 'D99') AND
               SUBSTR(B.STOCK_PRO_TYPE, 1, 1) = 'D' AND B.ISSU_ORG LIKE 'C%' THEN
           '企业债务融资工具' --1.7.3企业债务融资工具
          WHEN B.STOCK_ASSET_TYPE IS NOT NULL AND B.ISSUER_INLAND_FLG = 'Y' THEN
           '资产支持证券' --1.8资产支持证券期末余额
          WHEN B.STOCK_PRO_TYPE LIKE 'F%' AND B.ISSUER_INLAND_FLG = 'N' THEN
           '外国债券' --1.9外国债券
        END ZQLX,
        a.DNMNT ME,
        A.OVRFLWG_PRC_CORR_DURAN ZYTJGXZJQ,
        A.OVRFLWG_FULL_PRC_MKT_VAL ZYTQJSZ,
        case when a.TXN_PORTF like '%AC%' THEN  '持有至到期投资'
              when a.TXN_PORTF like '%FVTPL%' THEN  '交易性金融资产'
              when a.TXN_PORTF like '%FVTOCI%' THEN  '可供出售金融资产' END  JYTZ,
        B.STOCK_CD ,
        B.STOCK_NAM,
        a.INTFC_NO
   FROM SMTMODS_L_TRAN_EV_OVRFLWG_PRFT_LOSS A --折溢摊损益表
  INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
     ON A.Bond_Cd = B.STOCK_CD
    AND B.DATA_DATE = I_DATADATE
  WHERE A.DATA_DATE = I_DATADATE
    AND B.STOCK_ASSET_TYPE IS NULL
    AND B.ISSUER_INLAND_FLG = 'Y'
    and a.TXN_PORTF not like '%债券预发行%';
    COMMIT;


         --1合计值
    SELECT sum(ZYTQJSZ) ZYTQJSZ_sum  into v_ZYTQJSZ_sum
               FROM CBRC_EV_OVRFLWGPRFT_LOSS_TEMP
              WHERE DATA_DATE = I_DATADATE;



 INSERT INTO CBRC_PUB_DATA_COLLECT_G3101 --PUB_DATA_COLLECT_G31_2016
   (ORG_NUM, --机构号
    ITEM_NUM, --指标号
    ITEM_VALUE --指标值
    )
   SELECT '009804' AS ORG_NUM,
          'G31_I_1.C.2025' ITEM_NUM,
          sum(nvl(t.ZYTJGXZJQ, 0) * nvl(t.ZYTQJSZ, 0) / v_ZYTQJSZ_sum) AS ITEM_VALUE --账面余额
     FROM CBRC_EV_OVRFLWGPRFT_LOSS_TEMP T
    where t.DATA_DATE = I_DATADATE;
    COMMIT;


         --1合计值
        SELECT sum(ZYTQJSZ) ZYTQJSZ_sum  into v_ZYTQJSZ_sum1
               FROM CBRC_EV_OVRFLWGPRFT_LOSS_TEMP
              WHERE DATA_DATE = I_DATADATE
               AND  ZQLX IN ('企业债','公司债','企业债务融资工具')
              ;



 INSERT INTO CBRC_PUB_DATA_COLLECT_G3101 --PUB_DATA_COLLECT_G31_2016
   (ORG_NUM, --机构号
    ITEM_NUM, --指标号
    ITEM_VALUE --指标值
    )
   SELECT '009804' AS ORG_NUM,
          'G31_I_1.7.C.2025' ITEM_NUM,
          sum(nvl(t.ZYTJGXZJQ, 0) * nvl(t.ZYTQJSZ, 0) / v_ZYTQJSZ_sum1) AS ITEM_VALUE --账面余额
     FROM CBRC_EV_OVRFLWGPRFT_LOSS_TEMP T
    where t.DATA_DATE = I_DATADATE
    AND  ZQLX IN ('企业债','公司债','企业债务融资工具');
    COMMIT;

    --其中：1.2.1专项债券

     --1合计值
        SELECT sum(ZYTQJSZ) ZYTQJSZ_sum  into v_ZYTQJSZ_sum2
           FROM  CBRC_EV_OVRFLWGPRFT_LOSS_TEMP A
   INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
          ON A.STOCK_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
     WHERE B.FXZJYT ='02'  ---专项债券
         AND B.STOCK_ASSET_TYPE IS NULL
         AND B.ISSUER_INLAND_FLG = 'Y'
         AND B.STOCK_PRO_TYPE = 'A' AND B.ISSU_ORG = 'A02';
         COMMIT;

      INSERT INTO CBRC_PUB_DATA_COLLECT_G3101 --PUB_DATA_COLLECT_G31_2016
   (ORG_NUM, --机构号
    ITEM_NUM, --指标号
    ITEM_VALUE --指标值
    )
   SELECT '009804' AS ORG_NUM,
          'G31_I_1.2.1.C.2025' ITEM_NUM,
          sum(nvl(t.ZYTJGXZJQ, 0) * nvl(t.ZYTQJSZ, 0) / v_ZYTQJSZ_sum2) AS ITEM_VALUE --账面余额
     FROM CBRC_EV_OVRFLWGPRFT_LOSS_TEMP T
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
          ON t.STOCK_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
    where t.DATA_DATE = I_DATADATE
    and  B.FXZJYT ='02'  ---专项债券
         AND B.STOCK_ASSET_TYPE IS NULL
         AND B.ISSUER_INLAND_FLG = 'Y'
         AND B.STOCK_PRO_TYPE = 'A' AND B.ISSU_ORG = 'A02';

    COMMIT;




    INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
    SELECT '009804' AS ORG_NUM,
             CASE
                WHEN t.ZQLX ='国债' THEN
                 'G31_I_1.1.C.2025' --1.1国债
                WHEN t.ZQLX ='地方政府债券' THEN
                 'G31_I_1.2.C.2025' --1.2地方政府债券
                WHEN t.ZQLX ='政策性金融债'  THEN
                 'G31_I_1.4.C.2025' --1.4政策性金融债
                WHEN t.ZQLX ='政府机构债券'  THEN
                 'G31_I_1.5.C.2025' --'1.5政府机构债券
               WHEN t.ZQLX ='商业性金融债'  THEN
                'G31_I_1.6.C.2025' --1.6商业性金融债
               WHEN t.ZQLX ='企业债' THEN
                'G31_I_1.7.1.C.2025' --1.7.1企业债
               WHEN t.ZQLX ='公司债'  THEN
                'G31_I_1.7.2.C.2025' --1.7.2公司债
               WHEN t.ZQLX ='企业债务融资工具'  THEN
                'G31_I_1.7.3.C.2025' --1.7.3企业债务融资工具
               WHEN t.ZQLX ='资产支持证券'  THEN
                'G31_I_1.8.C.2025' --1.8资产支持证券期末余额
               WHEN t.ZQLX ='外国债券'  THEN
                'G31_I_1.9.C.2025' --1.9外国债券
             END ITEM_NUM,
             sum( nvl(t.ZYTJGXZJQ,0) * nvl(t.ZYTQJSZ,0) /t1.ZQLX_sum)   AS ITEM_VALUE --账面余额
               FROM CBRC_EV_OVRFLWGPRFT_LOSS_TEMP T
  LEFT JOIN (SELECT sum(ZYTQJSZ) ZQLX_sum, ZQLX
               FROM CBRC_EV_OVRFLWGPRFT_LOSS_TEMP
              WHERE DATA_DATE = I_DATADATE
              group by ZQLX) t1
       on t.Zqlx = t1.ZQLX
 where t.DATA_DATE = I_DATADATE
 group by CASE
                WHEN t.ZQLX ='国债' THEN
                 'G31_I_1.1.C.2025' --1.1国债
                WHEN t.ZQLX ='地方政府债券' THEN
                 'G31_I_1.2.C.2025' --1.2地方政府债券
                WHEN t.ZQLX ='政策性金融债'  THEN
                 'G31_I_1.4.C.2025' --1.4政策性金融债
                WHEN t.ZQLX ='政府机构债券'  THEN
                 'G31_I_1.5.C.2025' --'1.5政府机构债券
               WHEN t.ZQLX ='商业性金融债'  THEN
                'G31_I_1.6.C.2025' --1.6商业性金融债
               WHEN t.ZQLX ='企业债' THEN
                'G31_I_1.7.1.C.2025' --1.7.1企业债
               WHEN t.ZQLX ='公司债'  THEN
                'G31_I_1.7.2.C.2025' --1.7.2公司债
               WHEN t.ZQLX ='企业债务融资工具'  THEN
                'G31_I_1.7.3.C.2025' --1.7.3企业债务融资工具
               WHEN t.ZQLX ='资产支持证券'  THEN
                'G31_I_1.8.C.2025' --1.8资产支持证券期末余额
               WHEN t.ZQLX ='外国债券'  THEN
                'G31_I_1.9.C.2025' --1.9外国债券
             END;
         COMMIT;


 INSERT INTO CBRC_PUB_DATA_COLLECT_G3101
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
    SELECT '009804' AS ORG_NUM,
       CASE
         WHEN T2.JYTZ = '交易性金融资产' --交易类
          THEN
          'G31_I_1.e.C.2025'
         WHEN T2.JYTZ = '可供出售金融资产' --可供出售类
          THEN
          'G31_I_1.f.C.2025'
         WHEN T2.JYTZ = '持有至到期投资' -- 持有至到期
          THEN
          'G31_I_1.d.C.2025'
       END ITEM_NUM,
       SUM(NVL(T.ZYTJGXZJQ, 0) * NVL(T.ZYTQJSZ, 0) / T2.JYTZ_SUM) AS ITEM_VALUE --账面余额
  FROM CBRC_EV_OVRFLWGPRFT_LOSS_TEMP T
  LEFT JOIN (SELECT SUM(ZYTQJSZ) JYTZ_SUM, JYTZ
               FROM CBRC_EV_OVRFLWGPRFT_LOSS_TEMP
              WHERE DATA_DATE = I_DATADATE
              GROUP BY JYTZ) T2
    ON T.JYTZ = T2.JYTZ
 WHERE T.DATA_DATE = I_DATADATE
 GROUP BY CASE
            WHEN T2.JYTZ = '交易性金融资产' --交易类
             THEN
             'G31_I_1.e.C.2025'
            WHEN T2.JYTZ = '可供出售金融资产' --可供出售类
             THEN
             'G31_I_1.f.C.2025'
            WHEN T2.JYTZ = '持有至到期投资' -- 持有至到期
             THEN
             'G31_I_1.d.C.2025'
          END ;
          COMMIT;


    --==================================================
    --汇总临时表值
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '汇总临时表值';
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
       FLAG, --标志位
       IS_TOTAL)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             V_PER_NUM AS REP_NUM, --报表编号
             ITEM_NUM, --指标号
             SUM(ITEM_VALUE) AS ITEM_VAL,
             '2' AS FLAG,
             CASE
               WHEN ITEM_NUM = 'G31.1..A.2016' THEN --ADD BY DJH 20230506 不参与汇总
                'N'
             END AS IS_TOTAL
        FROM CBRC_PUB_DATA_COLLECT_G3101
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY ORG_NUM, --机构号
                ITEM_NUM; --报表类型

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
   
END proc_cbrc_idx2_g31