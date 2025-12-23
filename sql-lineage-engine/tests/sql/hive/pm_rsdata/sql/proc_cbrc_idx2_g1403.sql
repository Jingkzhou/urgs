CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g1403(II_DATADATE  IN STRING --跑批日期
                                                   )
/******************************
  @AUTHOR:DJH
  @CREATE-DATE:20240415
  @DESCRIPTION:G1403  G14 第III部分：非同业单一客户大额风险暴露情况表：非同业单一客户大额风险暴露情况表
  @MODIFICATION HISTORY:
  --需求编号：JLBA202505140011_关于1104报表系统金融市场部报表取数逻辑变更的需求 上线日期：2025-07-29 修改人：常金磊，提出人：康立军 修改内容：调整债券、存单关联减值表的关联条件，解决关联重复问题
  需求编号：JLBA202505280011 上线日期： 2025-09-19，修改人：狄家卉，提出人：赵翰君  修改原因：关于实现1104监管报送报表自动化采集加工的需求  增加009801清算中心(国际业务部)外币折人民币业务
  
  
目标表：CBRC_A_REPT_ITEM_VAL
码值表：CBRC_G1403_CONFIG_RESULT_MAPPING
     CBRC_G1403_CONFIG_TMP     --金融市场部配置表
     CBRC_G1403_CONFIG_TMP_QS  --清算中心机构配置表
     CBRC_G1403_CONFIG_TMP_TH  --投行机构配置表
临时表：CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1403
     CBRC_TMP_ASSET_DEVALUE_PREPARE_G1403
     CBRC_TMP_BUSINESS_TABLE_TYDYKH_G1403
     CBRC_TMP_BUSINESS_TABLE_TYDYKH_MIDDLE_G1403
     CBRC_TMP_BUSINESS_TABLE_TYDYKH_RESULT_G1403
     CBRC_TMP_ECIF_L_CUST_BILL_TY_G1403
     CBRC_TMP_L_CUST_EXTERNAL_INFO_G1403
集市表：SMTMODS_L_ACCT_FUND_INVEST
     SMTMODS_L_ACCT_FUND_REPURCHASE
     SMTMODS_L_ACCT_LOAN
     SMTMODS_L_AGRE_BILL_INFO
     SMTMODS_L_AGRE_BONDISSUER_INFO
     SMTMODS_L_AGRE_BOND_INFO
     SMTMODS_L_AGRE_REPURCHASE_GUARANTY_INFO
     SMTMODS_L_CUST_BILL_TY
     SMTMODS_L_CUST_C
     SMTMODS_L_CUST_EXTERNAL_INFO
     SMTMODS_L_FINA_ASSET_DEVALUE
     SMTMODS_L_PUBL_RATE
     SMTMODS_L_TRAN_FUND_FX

  
  ********************************/
 IS
  V_PROCEDURE VARCHAR(30); --当前储存过程名称
  V_TAB_NAME  VARCHAR(30); --目标表名
  I_DATADATE  STRING; --数据日期(数值型)YYYYMMDD
  V_STEP_ID   INTEGER; --任务号
  V_STEP_DESC VARCHAR(300); --任务描述
  V_STEP_FLAG INTEGER; --任务执行状态标识
  V_ERRORCODE VARCHAR(20); --错误编码
  V_ERRORDESC VARCHAR(280); --错误内容
  V_PER_NUM   VARCHAR(30); --报表编号
  V_DATADATE  VARCHAR2(10);
  II_STATUS   INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM    VARCHAR(30);
BEGIN 
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';
    V_PER_NUM   := 'G1403';
    V_SYSTEM    := 'CBRC';
    I_DATADATE  := II_DATADATE;
    V_DATADATE  := TO_CHAR(DATE(I_DATADATE), 'YYYYMMDD');
    V_TAB_NAME  := 'G1403';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G1403');
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
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
       AND IS_TOTAL = 'Y';
    COMMIT;

    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TMP_L_CUST_EXTERNAL_INFO_G1403';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TMP_ASSET_DEVALUE_PREPARE_G1403'; --资产减值准备临时表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TMP_ECIF_L_CUST_BILL_TY_G1403'; --同业客户信息处理
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TMP_BUSINESS_TABLE_TYDYKH_G1403'; --处理业务明细宽表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TMP_BUSINESS_TABLE_TYDYKH_MIDDLE_G1403'; --处理业务明细中间表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TMP_BUSINESS_TABLE_TYDYKH_RESULT_G1403'; --处理业务明细结果表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1403'; -- G14 第III部分：非同业单一客户大额风险暴露情况表：非同业单一客户大额风险暴露情况表

    --G1403_CONFIG_RESULT_MAPPING  配置表   CBRC_G1403_CONFIG_TMP  报表映射指标配置表(金融市场)   CBRC_G1403_CONFIG_TMP_TH 报表映射指标配置表(投资银行部)


    --==================================================
    --减值临时表
    --==================================================

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '资产减值准备临时表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_TMP_ASSET_DEVALUE_PREPARE_G1403 
      (DATA_DATE,
       RECORD_ORG,
       BIZ_NO,
       CURR,
       PRIN_SUBJ_NO,
       FIVE_TIER_CLS,
       ACCT_NUM,
       PRIN_FINAL_RESLT,
       OFBS_FINAL_RESLT,
       FINAL_ECL,
       COLLBL_INT_FINAL_RESLT,
       ACCT_ID)  --[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
      SELECT 
       T.DATA_DATE,
       T.RECORD_ORG,
       CASE
         WHEN SUBSTR(T.PRIN_SUBJ_NO, 1, 4) IN ('1111', '2111') THEN
          ''
         ELSE
          T.BIZ_NO
       END BIZ_NO,  --回购业务对多笔，统一处理
       T.CURR,
       T.PRIN_SUBJ_NO,
       T.FIVE_TIER_CLS,
       T.ACCT_NUM,
       SUM(NVL(T.PRIN_FINAL_RESLT, 0)) PRIN_FINAL_RESLT, --本金减值
       SUM(NVL(T.OFBS_FINAL_RESLT, 0)) OFBS_FINAL_RESLT,  --表外减值
       SUM(NVL(T.FINAL_ECL, 0)) FINAL_ECL,  --应计利息  ADD BY DJH 20240510 根据康哥核对“非信贷明细报表2024-03-27”  增加
       SUM(NVL(T.COLLBL_INT_FINAL_RESLT, 0)) COLLBL_INT_FINAL_RESLT, --应收利息
       ACCT_ID  --[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
        FROM SMTMODS_L_FINA_ASSET_DEVALUE T --资产减值准备
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY T.RECORD_ORG,
                CASE
                  WHEN SUBSTR(T.PRIN_SUBJ_NO, 1, 4) IN ('1111', '2111') THEN
                   ''
                  ELSE
                   T.BIZ_NO
                END,
                T.CURR,
                T.PRIN_SUBJ_NO,
                T.FIVE_TIER_CLS,
                T.DATA_DATE,
                T.ACCT_NUM,
                T.ACCT_ID;  --[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
    COMMIT;
    --==================================================
    --同业客户信息（ECIF_CUST_ID）临时表
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '同业客户信息（ECIF_CUST_ID）临时表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP_ECIF_L_CUST_BILL_TY_G1403
      SELECT DATA_DATE,
             ORG_NUM,
             CUST_ID,
             LEGAL_NAME,
             FINA_ORG_CODE,
             FINA_CODE_NEW,
             FINA_ORG_NAME,
             CAPITAL_AMT,
             BORROWER_REGISTER_ADDR,
             TYSHXYDM,
             ORGANIZATIONCODE,
             ECIF_CUST_ID,
             LEGAL_FLAG,
             LEGAL_TYSHXYDM,
             '1' AS FLAG --按照ECIF_CUST_ID客户号去重复
        FROM (SELECT A.*,
                     ROW_NUMBER() OVER(PARTITION BY A.ECIF_CUST_ID ORDER BY A.ECIF_CUST_ID) RN
                FROM SMTMODS_L_CUST_BILL_TY A --一个ECIF客户对应,多个同业客户,对应一个公司/银行名
               WHERE A.DATA_DATE = I_DATADATE) B
       WHERE B.RN = '1';
    COMMIT;

    --==================================================
    --同业客户信息（CUST_ID）临时表
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '同业客户信息（CUST_ID）临时表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP_ECIF_L_CUST_BILL_TY_G1403
      SELECT DATA_DATE,
             ORG_NUM,
             CUST_ID,
             LEGAL_NAME,
             FINA_ORG_CODE,
             FINA_CODE_NEW,
             FINA_ORG_NAME,
             CAPITAL_AMT,
             BORROWER_REGISTER_ADDR,
             TYSHXYDM,
             ORGANIZATIONCODE,
             ECIF_CUST_ID,
             LEGAL_FLAG,
             LEGAL_TYSHXYDM,
             '2' AS FLAG --按照CUST_ID客户号去重复
        FROM (SELECT A.*,
                     ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.CUST_ID) RN
                FROM SMTMODS_L_CUST_BILL_TY A --一个同业客户,两个ecif客户号,一般这俩ecif客户号都对应一个公司
               WHERE A.DATA_DATE = I_DATADATE) B
       WHERE B.RN = '1';
    COMMIT;

    --==================================================
    --同业客户信息（TYSHXYDM）临时表
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '同业客户信息（TYSHXYDM）临时表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP_ECIF_L_CUST_BILL_TY_G1403
      SELECT DATA_DATE,
             ORG_NUM,
             CUST_ID,
             LEGAL_NAME,
             FINA_ORG_CODE,
             FINA_CODE_NEW,
             FINA_ORG_NAME,
             CAPITAL_AMT,
             BORROWER_REGISTER_ADDR,
             TYSHXYDM,
             ORGANIZATIONCODE,
             ECIF_CUST_ID,
             LEGAL_FLAG,
             LEGAL_TYSHXYDM,
             '3' AS FLAG --关联此段逻辑为了取法人行
        FROM (SELECT A.*,
                     ROW_NUMBER() OVER(PARTITION BY A.TYSHXYDM ORDER BY A.TYSHXYDM) RN
                FROM SMTMODS_L_CUST_BILL_TY A
               WHERE A.DATA_DATE = I_DATADATE
                 AND LEGAL_FLAG = 'Y' --取法人
                 AND TYSHXYDM IS NOT NULL
                 AND TYSHXYDM <> '000000000000000000'
                 AND FINA_ORG_NAME NOT LIKE '%存托%'
                 AND FINA_ORG_NAME NOT LIKE '%资管%'
                 AND FINA_ORG_NAME NOT LIKE '%禁用%'
                 AND A.FINA_ORG_NAME NOT IN ('白山市浑江区农村信用合作联社')) B
       WHERE B.RN = '1';
    COMMIT;


INSERT INTO CBRC_TMP_L_CUST_EXTERNAL_INFO_G1403
  SELECT DATA_DATE,
         ORG_NUM,
         ORG_FULLNAME,
         USCD,
         ORG_CD,
         ORG_SCALE,
         CORP_PROPTY,
         IS_PBANK,
         CBRC_FIN_INST_TYPE,
         ORG_TYPE_MCLS,
         ORG_TYPE_SCLS,
         BELONG_GROUP_ORG_CD,
         BELONG_GROUP_NAME,
         IS_LOCAL_GOVER_FIN_PLAT,
         INDS_INVEST,
         AFLT_PROV,
         AFLT_CITY,
         AFLT_DIST,
         ISSUER_RAT,
         APPRS_COMPNY_NAME,
         CORP_SIZE,
         CUST_ID
    FROM (SELECT A.*,
                 ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.CUST_ID) RN
            FROM SMTMODS_L_CUST_EXTERNAL_INFO A
           WHERE A.DATA_DATE = I_DATADATE) B
   WHERE B.RN = '1';
  COMMIT;


    ---------------------------业务宽表数据加工---------------------------
    ----一般风险暴露合计：其中：买入返售(质押式)+同业债券+同业存单+转帖现

    ---------------------------------------
    ----一般风险暴露其中：同业债券   ：债券发行人
    ---------------------------------------

    --==================================================
    --同业债券 按债券类型区分债券发行方客户分类：地方政府债，国债，短期，超短期，中期票据，企业债，公司债等（包含吉林省财政厅，中华人民共和国财政部，中科建设开发总公司（信托））
    --==================================================

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '同业债券';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


   --吉林省政府：吉林省财政厅
    INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH_G1403
      (DATA_DATE, --01数据日期
       ORG_NUM, --02机构号
       CURR_CD, --03币种
       BOOK_TYPE, --04账户种类
       SUBJECT_CD, --05业务产品编号
       SUBJECT_NAM, --06业务名称
       COLL_SUBJECT_TYPE, --07业务类别
       BALANCE, --08本金
       PRIN_FINAL_RESLT, --09减值
       PRIN_MINUS, --10本金与减值差值
       CUST_ID, --11客户号
       ID_NO, --12证件号
       CUST_NAM, --13客户名称
       PLEDGE_CUST_ID, --14质押客户号
       PLEDGE_ID_NO, --15质押证件号
       PLEDGE_CUST_NAM, --16质押客户名称
       LEGAL_ID_NO, --17法人统一社会信用代码
       LEGAL_CUST_NAM, --18法人名称
       ISSU_ORG, --19发行主体类型
       STOCK_PRO_TYPE, --20产品分类
       GL_ITEM_CODE, --21科目号
       FLAG, --22业务标识
       CUST_NAM_S, --23 客户名称_S
       PLEDGE_CUST_NAM_S --24质押客户名称_S
       )
      SELECT 
       T.DATA_DATE, --01数据日期
       T.ORG_NUM, --02机构号
       T.CURR_CD, --03币种
       T.BOOK_TYPE, --04账户种类
       T.SUBJECT_CD, --05业务产品编号
       A.STOCK_NAM, --06业务名称
       '' AS COLL_SUBJECT_TYPE, --07业务类别
       T.PRINCIPAL_BALANCE * TT.CCY_RATE AS BALANCE, --08本金,
       CASE
         WHEN T.ACCOUNTANT_TYPE = '1' THEN
          0
         ELSE
          NVL(C.PRIN_FINAL_RESLT, 0) --交易性金融资产不算减值(不计入总账) 会计分类：1、交易类 2、可供出售类 3、持有至到期 4、贷款及应收款
       END AS PRIN_FINAL_RESLT, --09减值
       T.PRINCIPAL_BALANCE * TT.CCY_RATE - CASE
         WHEN T.ACCOUNTANT_TYPE = '1' THEN
          0
         ELSE
          NVL(C.PRIN_FINAL_RESLT, 0) --交易性金融资产不算减值(不计入总账) 会计分类：1、交易类 2、可供出售类 3、持有至到期 4、贷款及应收款
       END AS PRIN_MINUS, --10本金与减值差值
       NVL(T4.CUST_ID,T3.CUST_ID) AS CUST_ID, --11同业债券债券发行人客户号
       NVL(T4.ID_NO,T3.USCD) AS ID_NO, --12同业债券债券发行人证件号
       NVL(T4.CUST_NAM,T3.ORG_FULLNAME) AS CUST_NAM, --13同业债券债券发行人客户名称
       '' AS PLEDGE_CUST_ID, --14质押客户号
       '' AS PLEDGE_ID_NO, --15质押证件号
       '' AS PLEDGE_CUST_NAM, --16质押客户名称
       '' AS LEGAL_ID_NO, --17法人统一社会信用代码
       '' AS LEGAL_CUST_NAM, --18法人名称
       A.ISSU_ORG, --19发行主体类型
       A.STOCK_PRO_TYPE, --20产品分类
       T.GL_ITEM_CODE, --21科目号
       '1' AS FLAG, --22业务标识 同业债券
       B.ISSUER_CUST_ID AS CUST_NAM_S, --23 同业债券债券发行人客户名称 同（13同业债券债券发行人客户名称）
       '' AS PLEDGE_CUST_NAM_S --24质押客户名称_S
        FROM SMTMODS_L_ACCT_FUND_INVEST T
        LEFT JOIN SMTMODS_L_AGRE_BOND_INFO A -- 债券信息表
          ON T.SUBJECT_CD = A.STOCK_CD
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_AGRE_BONDISSUER_INFO B --之后不做关联
          ON T.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_TMP_ASSET_DEVALUE_PREPARE_G1403 C --资产减值准备
          ON C.ACCT_NUM = T.ACCT_NUM
         AND T.ACCT_NO = C.ACCT_ID --[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
         AND T.GL_ITEM_CODE = C.PRIN_SUBJ_NO --投资 帐户分类 1101交易性金融资产 1501持有至到期投资 1503可供出售金融资产（一条对多条）
         AND C.DATA_DATE = I_DATADATE
         AND A.ORG_NUM=C.RECORD_ORG
        LEFT JOIN CBRC_TMP_L_CUST_EXTERNAL_INFO_G1403 T3  --客户外部信息表  取所属省
          ON T.CUST_ID=T3.CUST_ID
        -- AND T3.DATA_DATE=I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C  T4  --对公客户补充信息表 政府客户信息客户外部信息表没有，对其补充
          ON T.CUST_ID=T4.CUST_ID
         AND T4.DATA_DATE=I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND ((A.ISSU_ORG = 'A02' AND A.STOCK_PRO_TYPE = 'A') --地方政府债
             OR (A.ISSU_ORG = 'A01' AND A.STOCK_PRO_TYPE = 'A') --国债
             OR (A.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05'))) ----超短期融资券，短期融资券，公司债，企业债，中期票据
         AND PRINCIPAL_BALANCE <> 0
         AND (SUBSTR(T3.AFLT_PROV, 1, 2) <> '22' OR  ((T3.AFLT_PROV IS NULL OR T4.REGION_CD IS NULL) AND  A.ISSU_ORG = 'A02')); --取债券发行人为非吉林省或者政府发行债但是省份为空（政府债没有所属地区）

    COMMIT;

    --填报在： 8913207920 中科建设开发总公司（信托）  91310000633073234F  11328.33 N000310000024539  特殊补进来
    --系统在： 8912746919 国民信托有限公司  911100001429120804  下  11328.33
    INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH_G1403
      (DATA_DATE, --01数据日期
       ORG_NUM, --02机构号
       CURR_CD, --03币种
       BOOK_TYPE, --04账户种类
       SUBJECT_CD, --05业务产品编号
       SUBJECT_NAM, --06业务名称
       COLL_SUBJECT_TYPE, --07业务类别
       BALANCE, --08本金
       PRIN_FINAL_RESLT, --09减值
       PRIN_MINUS, --10本金与减值差值
       CUST_ID, --11客户号
       ID_NO, --12证件号
       CUST_NAM, --13客户名称
       PLEDGE_CUST_ID, --14质押客户号
       PLEDGE_ID_NO, --15质押证件号
       PLEDGE_CUST_NAM, --16质押客户名称
       LEGAL_ID_NO, --17法人统一社会信用代码
       LEGAL_CUST_NAM, --18法人名称
       ISSU_ORG, --19发行主体类型
       STOCK_PRO_TYPE, --20产品分类
       GL_ITEM_CODE, --21科目号
       FLAG, --22业务标识
       CUST_NAM_S, --23 客户名称_S
       PLEDGE_CUST_NAM_S --24质押客户名称_S
       )
      SELECT 
       T.DATA_DATE, --01数据日期
       T.ORG_NUM, --02机构号
       T.CURR_CD, --03币种
       T.BOOK_TYPE, --04账户种类
       T.SUBJECT_CD, --05业务产品编号
       A.STOCK_NAM, --06业务名称
       '' AS COLL_SUBJECT_TYPE, --07业务类别
       T.PRINCIPAL_BALANCE * TT.CCY_RATE AS BALANCE, --08本金,
       CASE
         WHEN T.ACCOUNTANT_TYPE = '1' THEN
          0
         ELSE
          NVL(C.PRIN_FINAL_RESLT, 0) --交易性金融资产不算减值(不计入总账) 会计分类：1、交易类 2、可供出售类 3、持有至到期 4、贷款及应收款
       END AS PRIN_FINAL_RESLT, --09减值
       T.PRINCIPAL_BALANCE * TT.CCY_RATE - CASE
         WHEN T.ACCOUNTANT_TYPE = '1' THEN
          0
         ELSE
          NVL(C.PRIN_FINAL_RESLT, 0) --交易性金融资产不算减值(不计入总账) 会计分类：1、交易类 2、可供出售类 3、持有至到期 4、贷款及应收款
       END AS PRIN_MINUS, --10本金与减值差值
       /*COALESCE(T1.ECIF_CUST_ID, T2.CUST_ID,T3.CUST_ID) AS CUST_ID, --11同业债券债券发行人客户号
       COALESCE(T1.TYSHXYDM, T2.TYSHXYDM,T3.USCD) AS ID_NO, --12同业债券债券发行人证件号
       COALESCE(T1.FINA_ORG_NAME, T2.FINA_ORG_NAME,T3.ORG_FULLNAME) AS CUST_NAM, --13同业债券债券发行人客户名称*/
       T3.CUST_ID AS CUST_ID, --11同业债券债券发行人客户号
       T3.USCD AS ID_NO, --12同业债券债券发行人证件号
       T3.ORG_FULLNAME AS CUST_NAM, --13同业债券债券发行人客户名称
       '' AS PLEDGE_CUST_ID, --14质押客户号
       '' AS PLEDGE_ID_NO, --15质押证件号
       '' AS PLEDGE_CUST_NAM, --16质押客户名称
       '' AS LEGAL_ID_NO, --17法人统一社会信用代码
       '' AS LEGAL_CUST_NAM, --18法人名称
       A.ISSU_ORG, --19发行主体类型
       A.STOCK_PRO_TYPE, --20产品分类
       T.GL_ITEM_CODE, --21科目号
       '2' AS FLAG, --22业务标识 同业债券
       B.ISSUER_CUST_ID AS CUST_NAM_S, --23 同业债券债券发行人客户名称 同（13同业债券债券发行人客户名称）
       '' AS PLEDGE_CUST_NAM_S --24质押客户名称_S
        FROM SMTMODS_L_ACCT_FUND_INVEST T
        LEFT JOIN SMTMODS_L_AGRE_BOND_INFO A -- 债券信息表
          ON T.SUBJECT_CD = A.STOCK_CD
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_AGRE_BONDISSUER_INFO B --之后不做关联
          ON T.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_TMP_ASSET_DEVALUE_PREPARE_G1403 C --资产减值准备
          ON C.ACCT_NUM = T.ACCT_NUM
         AND T.ACCT_NO = C.ACCT_ID --[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
         AND T.GL_ITEM_CODE = C.PRIN_SUBJ_NO --投资 帐户分类 1101交易性金融资产 1501持有至到期投资 1503可供出售金融资产（一条对多条）
         AND C.DATA_DATE = I_DATADATE
         AND A.ORG_NUM=C.RECORD_ORG
        LEFT JOIN CBRC_TMP_L_CUST_EXTERNAL_INFO_G1403 T3  --客户外部信息表
          ON T.CUST_ID=T3.CUST_ID
        -- AND T3.DATA_DATE=I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBJECT_CD='N000310000024539'
         AND (SUBSTR(T3.AFLT_PROV, 1, 2) <> '22' OR  (T3.AFLT_PROV IS NULL AND  A.ISSU_ORG = 'A02')); --取债券发行人为非吉林省或者政府发行债但是省份为空（政府债没有所属地区）

    COMMIT;


    --==================================================
    --买入返售(质押式)  债券
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '买入返售(质押式)  债券';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH_G1403
      (DATA_DATE, --01数据日期
       ORG_NUM, --02机构号
       CURR_CD, --03币种
       BOOK_TYPE, --04账户种类
       SUBJECT_CD, --05业务产品编号
       SUBJECT_NAM, --06业务名称
       COLL_SUBJECT_TYPE, --07业务类别
       BALANCE, --08本金
       PRIN_FINAL_RESLT, --09减值
       PRIN_MINUS, --10本金与减值差值
       CUST_ID, --11客户号
       ID_NO, --12证件号
       CUST_NAM, --13客户名称
       PLEDGE_CUST_ID, --14质押客户号
       PLEDGE_ID_NO, --15质押证件号
       PLEDGE_CUST_NAM, --16质押客户名称
       LEGAL_ID_NO, --17法人统一社会信用代码
       LEGAL_CUST_NAM, --18法人名称
       ISSU_ORG, --19发行主体类型
       STOCK_PRO_TYPE, --20产品分类
       GL_ITEM_CODE, --21科目号
       FLAG, --22业务标识
       CUST_NAM_S, --23 客户名称_S
       PLEDGE_CUST_NAM_S --24质押客户名称_S
       )
      SELECT A.DATA_DATE, --01数据日期
             A.ORG_NUM, --02机构号
             A.CURR_CD, --03币种
             A.BOOK_TYPE, --04账户种类
             B.SUBJECT_CD, --05业务产品编号
             B.SUBJECT_NAM, --06业务名称
             B.COLL_SUBJECT_TYPE, --07业务类别
             SUM(B.BALANCE * U.CCY_RATE) AS BALANCE, --08质押券拆分总和
             SUM(NVL(D.PRIN_FINAL_RESLT, 0)) PRIN_FINAL_RESLT, --09减值
             SUM(B.BALANCE * U.CCY_RATE - NVL(D.PRIN_FINAL_RESLT, 0)) PRIN_MINUS, --10本金与减值差值
             A.CUST_ID, --11买入返售交易对手客户号
             T3.ID_NO, --12买入返售交易对手证件号
             T3.CUST_NAM, --13买入返售交易对手名称
             COALESCE(T4.CUST_ID, T5.CUST_ID) PLEDGE_CUST_ID, --14质押的发行人客户号
             COALESCE(T4.USCD, T5.ID_NO) PLEDGE_CUST_NAM, --15质押发行人证件号
             COALESCE(T4.ORG_FULLNAME,T5.CUST_NAM) PLEDGE_CUST_NAM, --16质押发行人客户名称
             '' AS LEGAL_ID_NO, --17法人统一社会信用代码
             '' AS LEGAL_CUST_NAM, --18法人名称
             C.ISSU_ORG, --19发行主体类型 A 政府  B 公共实体  C 企业 D  金融机构 E 境外金融机构
             C.STOCK_PRO_TYPE /*,D.STOCK_PRO_TYPE*/, --20产品分类 如是【债券产品类型】：A 政府债券（指我国政府发行债券） B央行票据 C金融债 D非金融企业债 F外国债 有些细化  或者【存单产品分类】 ：A  同业存单  B  大额存单
             A.GL_ITEM_CODE, --21科目号
             '3' AS FLAG, --22业务标识  买入返售(质押式)  债券
             A.JYDSMC AS CUST_NAM_S, --23买入返售交易对手名称  同（13买入返售交易对手名称）
             B.CUST_NAM AS PLEDGE_CUST_NAM_S --24质押客户名称 同（16质押发行人客户名称） 即质押券或存单的发行人名称 (宇航说未来L_AGRE_REPURCHASE_GUARANTY_INFO加进来CUST_NAM就是L_AGRE_BOND_INFO发行主体名称）
        FROM SMTMODS_L_ACCT_FUND_REPURCHASE A
        LEFT JOIN SMTMODS_L_AGRE_REPURCHASE_GUARANTY_INFO B
          ON A.ACCT_NUM = B.ACCT_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_AGRE_BOND_INFO C --质押券的法人行人
          ON B.SUBJECT_CD = C.STOCK_CD
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C T3   --为了取买入返售交易对手客户信息
          ON A.CUST_ID = T3.CUST_ID
         AND T3.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_FINA_ASSET_DEVALUE D --资产减值准备
          ON A.REF_NUM || '_' || B.SUBJECT_CD = D.BIZ_NO
         AND PRIN_SUBJ_NO LIKE '1111%'
         AND A.ORG_NUM = D.RECORD_ORG
         AND D.DATA_DATE =I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN CBRC_TMP_L_CUST_EXTERNAL_INFO_G1403 T4 --客户外部信息表  取所属省
          ON B.CUST_ID = T4.CUST_ID
        -- AND T4.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C  T5  --对公客户补充信息表 政府客户信息客户外部信息表没有，对其补充
          ON B.CUST_ID=T5.CUST_ID
         AND T5.DATA_DATE=I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.GL_ITEM_CODE = '111101' --质押式买入返售债券
         AND A.BALANCE <> 0  -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1111买入返售
         AND A.END_DT >= I_DATADATE --回购业务信息表[SMTMODS_L_ACCT_FUND_REPURCHASE]?修改数据组范围：质押式回购放开数据范围(筛除20210101之前的脏数据)???卡到期日期>=当前日期?
         AND ((C.ISSU_ORG = 'A02' AND C.STOCK_PRO_TYPE = 'A') --地方政府债
             OR (C.ISSU_ORG = 'A01' AND C.STOCK_PRO_TYPE = 'A') --国债
             OR (C.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05'))) ----超短期融资券，短期融资券，公司债，企业债，中期票据
         AND (SUBSTR(T4.AFLT_PROV, 1, 2) <> '22' OR  ((T4.AFLT_PROV IS NULL OR T5.REGION_CD IS NULL)AND  C.ISSU_ORG = 'A02')) --取债券发行人为非吉林省或者政府发行债但是省份为空（政府债没有所属地区）
       GROUP BY A.DATA_DATE,
                A.ORG_NUM,
                A.CURR_CD,
                A.BOOK_TYPE,
                B.SUBJECT_CD,
                B.SUBJECT_NAM,
                B.COLL_SUBJECT_TYPE,
                A.CUST_ID, --买入返售交易对手客户号
                T3.ID_NO, --买入返售交易对手证件号
                T3.CUST_NAM, --买入返售交易对手名称
                COALESCE(T4.CUST_ID, T5.CUST_ID), --14质押的发行人客户号
                COALESCE(T4.USCD, T5.ID_NO), --15质押发行人证件号
                COALESCE(T4.ORG_FULLNAME,T5.CUST_NAM), --16质押发行人客户名称
                C.ISSU_ORG, --发行主体类型
                C.STOCK_PRO_TYPE, --产品分类
                A.GL_ITEM_CODE,
                A.JYDSMC,
                --  B.CUST_ID,
                B.CUST_NAM;
    COMMIT;


    --==================================================
    --潜在风险暴露  （转贴现卖出）  G1405银承取承兑行法人行，G1403商承取出票人
    --==================================================
      ----业务时间在一年内，到期日大于当前日期所有的，票据类型要区分商票还是银票，银票报送G1405,商票报送在G1403(承兑人是银行或者企业)

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '潜在风险暴露  （转贴现卖出）';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH_G1403
      (DATA_DATE, --01数据日期
       ORG_NUM, --02机构号
       CURR_CD, --03币种
       BOOK_TYPE, --04账户种类
       SUBJECT_CD, --05业务产品编号
       SUBJECT_NAM, --06业务名称
       COLL_SUBJECT_TYPE, --07业务类别
       BALANCE, --08本金
       PRIN_FINAL_RESLT, --09减值
       PRIN_MINUS, --10本金与减值差值0
       CUST_ID, --11客户号
       ID_NO, --12证件号
       CUST_NAM, --13客户名称
       PLEDGE_CUST_ID, --14质押客户号
       PLEDGE_ID_NO, --15质押证件号
       PLEDGE_CUST_NAM, --16质押客户名称
       LEGAL_ID_NO, --17法人统一社会信用代码
       LEGAL_CUST_NAM, --18法人名称
       ISSU_ORG, --19发行主体类型
       STOCK_PRO_TYPE, --20产品分类
       GL_ITEM_CODE, --21科目号
       FLAG, --22业务标识
       CUST_NAM_S, --23 客户名称_S
       PLEDGE_CUST_NAM_S --24质押客户名称_S
       )
      SELECT 
       D.DATA_DATE, --01数据日期
       A.ORG_NUM, --02机构号
       D.CURR_CD, --03币种
       LA.BOOK_TYPE, --04账户种类
       A.CONTRACT_NUM AS SUBJECT_CD, --05业务产品编号
       '' AS SUBJECT_NAM, --06业务名称
       CASE
         WHEN BILL_TYPE = '1' THEN
          '银行承兑汇票'
         WHEN BILL_TYPE = '2' THEN
          '商业承兑汇票'
         WHEN BILL_TYPE = '3' THEN
          '银行汇票'
         WHEN BILL_TYPE = '4' THEN
          '本票'
         WHEN BILL_TYPE = '5' THEN
          '支票'
       END AS COLL_SUBJECT_TYPE, --07业务类别
       SUM(A.AMOUNT * TT.CCY_RATE) BALANCE, --08本金
       SUM(NVL(C.PRIN_FINAL_RESLT, 0)) PRIN_FINAL_RESLT, --09减值
       SUM(A.AMOUNT * TT.CCY_RATE - NVL(C.PRIN_FINAL_RESLT, 0)) PRIN_MINUS, --10本金与减值差值
       T3.CUST_ID AS CUST_ID, --11客户号
       T3.ID_NO AS ID_NO, --12证件号
       T3.CUST_NAM AS CUST_NAM, --13客户名称
       '' AS PLEDGE_CUST_ID, --14质押客户号
       '' AS PLEDGE_ID_NO, --15质押证件号
       '' AS PLEDGE_CUST_NAM, --16质押客户名称
       '' AS LEGAL_ID_NO, --17法人统一社会信用代码
       '' AS LEGAL_CUST_NAM, --18法人名称
       '' AS ISSU_ORG, --19发行主体类型
       '' AS STOCK_PRO_TYPE, --20产品分类
       A.ITEM_CD AS GL_ITEM_CODE, --21科目号
       '4' AS FLAG, --22业务标识 转贴现卖出
       '' AS CUST_NAM_S, --23 客户名称_S
       '' AS PLEDGE_CUST_NAM_S --24质押客户名称_S
        FROM (select A.CONTRACT_NUM,
                     A.ORG_NUM,
                     A.ITEM_CD,
                     SUM(A.ACCT_AMOUNT) AMOUNT
                from SMTMODS_L_TRAN_FUND_FX a --资金交易信息表（流水）
                LEFT JOIN (select *
                            from (SELECT A.*,
                                         ROW_NUMBER() OVER(PARTITION BY A.ecif_cust_id ORDER BY A.ecif_cust_id) RN
                                    FROM SMTMODS_L_CUST_BILL_TY A
                                   WHERE A.DATA_DATE = I_DATADATE
                                     AND a.LEGAL_TYSHXYDM IS NOT NULL) B
                           WHERE B.RN = '1') T1
                  ON A.CUST_ID = T1.ECIF_CUST_ID
                LEFT JOIN (SELECT *
                            FROM (SELECT ROW_NUMBER() OVER(PARTITION BY CUST_ID ORDER BY CUST_ID) RN,
                                         T.*
                                    FROM SMTMODS_L_CUST_BILL_TY T
                                   WHERE DATA_DATE = I_DATADATE
                                     AND T.LEGAL_TYSHXYDM IS NOT NULL)
                           WHERE RN = 1) T2
                  ON A.CUST_ID = T2.CUST_ID
                LEFT JOIN SMTMODS_L_CUST_C T3
                  ON A.CUST_ID = T3.CUST_ID
                 AND T3.DATA_DATE = I_DATADATE
               where A.tran_dt <= I_DATADATE
                 AND A.tran_dt >=
                     TO_CHAR(ADD_MONTHS(DATE(I_DATADATE), -12),'YYYYMMDD')
                 AND A.maturity_dt > I_DATADATE
                 AND A.BUSI_TYPE = 'I' --资金交易类型：票据买断式转贴现
                 AND TRADE_DIRECT = '0' --交易方向：结清（卖出）
                 AND NVL(T1.LEGAL_TYSHXYDM, T2.LEGAL_TYSHXYDM) <>
                     '9122010170255776XN' -- 卖出的交易对手是吉林银行过滤掉
               GROUP BY A.CONTRACT_NUM,
                        A.ORG_NUM,
                        A.ITEM_CD
              ) A -- 资金交易信息表
       INNER JOIN SMTMODS_L_AGRE_BILL_INFO D -- 商业汇票票面信息表
          ON A.CONTRACT_NUM = D.BILL_NUM
         AND DATA_DATE = I_DATADATE
         AND D.BILL_TYPE = '2' --票据类型 --1 银行承兑汇票   2 商业承兑汇票 --G1405只是取银行承兑汇票，G1403取商业承兑汇票
        LEFT JOIN SMTMODS_L_CUST_C T3 --对公客户表
          ON D.AFF_CODE = T3.CUST_ID
         AND T3.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = D.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_TMP_ASSET_DEVALUE_PREPARE_G1403 C --资产减值准备
          ON A.CONTRACT_NUM = C.ACCT_NUM
         AND A.ORG_NUM = C.RECORD_ORG
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN (SELECT DRAFT_NBR, CUST_ID, BOOK_TYPE
                     FROM SMTMODS_L_ACCT_LOAN -- 贷款借据信息表
                    WHERE DATA_DATE = I_DATADATE
                      and org_num = '009804'
                    GROUP BY DRAFT_NBR, CUST_ID, BOOK_TYPE) LA
          ON D.BILL_NUM = LA.DRAFT_NBR
       GROUP BY D.DATA_DATE, --01数据日期
                A.ORG_NUM, --02机构号
                D.CURR_CD, --03币种
                LA.BOOK_TYPE, --04账户种类
                A.CONTRACT_NUM, --05业务产品编号
                CASE
                  WHEN BILL_TYPE = '1' THEN
                   '银行承兑汇票'
                  WHEN BILL_TYPE = '2' THEN
                   '商业承兑汇票'
                  WHEN BILL_TYPE = '3' THEN
                   '银行汇票'
                  WHEN BILL_TYPE = '4' THEN
                   '本票'
                  WHEN BILL_TYPE = '5' THEN
                   '支票'
                END,
                T3.CUST_ID, --11客户号
                T3.ID_NO, --12证件号
                T3.CUST_NAM, --13客户名称
                A.ITEM_CD; --21科目号

    COMMIT;


      --==================================================
    --转贴现 （转贴现买入）  G1405银承取承兑行法人行，G1403商承取出票人
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '转贴现 （转贴现买入）';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


     INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH_G1403
       (DATA_DATE, --01数据日期
        ORG_NUM, --02机构号
        CURR_CD, --03币种
        BOOK_TYPE, --04账户种类
        SUBJECT_CD, --05业务产品编号
        SUBJECT_NAM, --06业务名称
        COLL_SUBJECT_TYPE, --07业务类别
        BALANCE, --08本金
        PRIN_FINAL_RESLT, --09减值
        PRIN_MINUS, --10本金与减值差值
        CUST_ID, --11客户号
        ID_NO, --12证件号
        CUST_NAM, --13客户名称
        PLEDGE_CUST_ID, --14质押客户号
        PLEDGE_ID_NO, --15质押证件号
        PLEDGE_CUST_NAM, --16质押客户名称
        LEGAL_ID_NO, --17法人统一社会信用代码
        LEGAL_CUST_NAM, --18法人名称
        ISSU_ORG, --19发行主体类型
        STOCK_PRO_TYPE, --20产品分类
        GL_ITEM_CODE, --21科目号
        FLAG, --22业务标识
        CUST_NAM_S, --23 客户名称_S
        PLEDGE_CUST_NAM_S --24质押客户名称_S
        )
       SELECT 
        A.DATA_DATE, --01数据日期
        A.ORG_NUM, --02机构号
        A.CURR_CD, --03币种
        A.BOOK_TYPE, --04账户种类
        A.DRAFT_NBR AS SUBJECT_CD, --05业务产品编号
        '' AS SUBJECT_NAM, --06业务名称
        CASE
          WHEN BILL_TYPE = '1' THEN
           '银行承兑汇票'
          WHEN BILL_TYPE = '2' THEN
           '商业承兑汇票'
          WHEN BILL_TYPE = '3' THEN
           '银行汇票'
          WHEN BILL_TYPE = '4' THEN
           '本票'
          WHEN BILL_TYPE = '5' THEN
           '支票'
        END AS COLL_SUBJECT_TYPE, --07业务类别
        SUM(A.LOAN_ACCT_BAL * TT.CCY_RATE) BALANCE, --08本金
        SUM(NVL(C.PRIN_FINAL_RESLT, 0)) PRIN_FINAL_RESLT, --09减值
        SUM(A.LOAN_ACCT_BAL * TT.CCY_RATE - NVL(C.PRIN_FINAL_RESLT, 0)) PRIN_MINUS, --10本金与减值差值
        T3.CUST_ID AS CUST_ID, --11出票人客户号
        T3.ID_NO AS ID_NO, --12出票人证件号
        T3.CUST_NAM AS CUST_NAM, --13出票人客户名称
        '' AS PLEDGE_CUST_ID, --14质押客户号
        '' AS PLEDGE_ID_NO, --15质押证件号
        '' AS PLEDGE_CUST_NAM, --16质押客户名称
        '' AS LEGAL_ID_NO, --17法人统一社会信用代码
        '' AS LEGAL_CUST_NAM, --18法人名称
        '' AS ISSU_ORG, --19发行主体类型
        A.ACCT_TYP_DESC AS STOCK_PRO_TYPE, --20产品分类
        A.ITEM_CD AS GL_ITEM_CODE, --21科目号
        '5' AS FLAG, --22业务标识  转贴现买入
        '' AS CUST_NAM_S, --23 客户名称_S
        '' AS PLEDGE_CUST_NAM_S --24质押客户名称_S
         FROM SMTMODS_L_ACCT_LOAN A -- 贷款借据信息表
         LEFT JOIN SMTMODS_L_AGRE_BILL_INFO B -- 商业汇票票面信息表
           ON A.DRAFT_NBR = B.BILL_NUM
          AND B.DATA_DATE = I_DATADATE
         LEFT JOIN SMTMODS_L_PUBL_RATE TT
           ON TT.CCY_DATE = I_DATADATE
          AND TT.BASIC_CCY = A.CURR_CD
          AND TT.FORWARD_CCY = 'CNY'
         LEFT JOIN CBRC_TMP_ASSET_DEVALUE_PREPARE_G1403 C --资产减值准备
           ON A.LOAN_NUM = C.ACCT_NUM
             -- AND T.GL_ITEM_CODE = C.PRIN_SUBJ_NO
          AND C.DATA_DATE = I_DATADATE
          AND A.ORG_NUM = C.RECORD_ORG
         LEFT JOIN SMTMODS_L_CUST_C T3 --对公客户表  取出票人客户信息
           ON B.AFF_CODE = T3.CUST_ID
          AND T3.DATA_DATE = I_DATADATE
        WHERE A.DATA_DATE = I_DATADATE
          AND (ITEM_CD LIKE '130102%' --以摊余成本计量的转贴现
              OR ITEM_CD LIKE '130105%')
          AND A.LOAN_ACCT_BAL <> 0
          AND A.ORG_NUM = '009804'
          AND B.BILL_TYPE = '2' --票据类型 --1 银行承兑汇票   2 商业承兑汇票 --G1405只是取银行承兑汇票，G1403取商业承兑汇票
          AND (T3.ID_NO <> '9122010170255776XN' OR T3.ID_NO IS NULL) --吉林银行去掉
        GROUP BY A.DATA_DATE, --01数据日期
                 A.ORG_NUM, --02机构号
                 A.CURR_CD, --03币种
                 A.BOOK_TYPE, --04账户种类
                 A.DRAFT_NBR, --05业务产品编号
                 CASE
                   WHEN BILL_TYPE = '1' THEN
                    '银行承兑汇票'
                   WHEN BILL_TYPE = '2' THEN
                    '商业承兑汇票'
                   WHEN BILL_TYPE = '3' THEN
                    '银行汇票'
                   WHEN BILL_TYPE = '4' THEN
                    '本票'
                   WHEN BILL_TYPE = '5' THEN
                    '支票'
                 END,
                 A.ACCT_TYP_DESC,
                 T3.CUST_ID, --11出票人客户号
                 T3.ID_NO, --12出票人证件号
                 T3.CUST_NAM, --13出票人客户名称
                 A.ITEM_CD; --21科目号

    COMMIT;


    --  SELECT DISTINCT FLAG FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH_G1403;
    -- FLAG 标识 1:买入返售(质押式)债券  2：同业债券 3：信托

    ---------------------------业务宽表数据排序[降序]---------------------------

    --==================================================
    --业务数据中间表处理
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '业务数据中间表处理';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH_MIDDLE_G1403
      (  CUST_NAM,            --客户名称
        ID_NO,               --证件号
        YBFX_GXDK,           --其中：各项贷款
        YBFX_ZQTZ,           --其中：债券投资
        XTCP,                --其中：信托产品
        FBBLC,               --其中：非保本理财
        ZQYZGCP,             --其中：证券业资管产品
        ZCZQHCP,             --资产证券化产品
        JYZBFXBL,            --交易账簿风险暴露
        JYDSXYFX,            --交易对手信用风险暴露
        YC,                  --其中：银行承兑汇票
        XYZ,                 --其中：跟单信用证
        BH,                  --其中：保函
        CN,                  --其中：贷款承诺
        QTFXBL,              --其他风险暴露
        FXHS,                --风险缓释转出的风险暴露（转入为负数）
        LOAN_BALANCE,        --各项贷款余额
        BLDK,                --附注：不良贷款余额
        YQDK,                --附注：逾期贷款余额
        BALANCE,             --本金
        PRIN_FINAL_RESLT,    --减值
        SIGN_TYPE,           --区分不同业务处理方式
        POLICY_BANK_FLAG,    --政策性银行标识
        MRFSZYS,             --买入返售质押式
        POTENTIAL_RISK,      --潜在风险暴露(转帖现卖出商业承兑汇票)   银票报送G1405,商票报送在G1403(承兑人是银行或者企业)
        ORG_NUM,              --机构号,
        TRANSFER_DISCOUNT    --转贴现买入
        )
      --同业债券  债券发行人   其中：政策性金融债
      SELECT NVL(T.CUST_NAM, T.CUST_NAM_S) AS CUST_NAM, --客户名称
             T.ID_NO, --客户代码
             0 YBFX_GXDK,           --其中：各项贷款
             SUM(CASE
                   WHEN T.BOOK_TYPE = '2' AND T.FLAG = '1' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    T.PRIN_MINUS
                   ELSE
                    0
             END) YBFX_ZQTZ,           --其中：债券投资
             SUM(CASE
                   WHEN T.BOOK_TYPE = '2' AND T.FLAG = '2' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    T.PRIN_MINUS
                   ELSE
                    0
             END) XTCP,                --其中：信托产品
             0 FBBLC,               --其中：非保本理财
             0 ZQYZGCP,             --其中：证券业资管产品
             0 ZCZQHCP,             --资产证券化产品
             SUM(CASE
                   WHEN T.BOOK_TYPE = '1' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    PRIN_MINUS
                   ELSE
                    0
             END) JYZBFXBL,            --交易账簿风险暴露
             0 JYDSXYFX,            --交易对手信用风险暴露
             0 YC,                  --其中：银行承兑汇票
             0 XYZ,                 --其中：跟单信用证
             0 BH,                  --其中：保函
             0 CN,                  --其中：贷款承诺
             0 QTFXBL,              --其他风险暴露
             0 FXHS,                --风险缓释转出的风险暴露（转入为负数）
             0 LOAN_BALANCE,        --各项贷款余额
             0 BLDK,                --附注：不良贷款余额
             0 YQDK,                --附注：逾期贷款余额
             SUM(T.BALANCE) AS BALANCE, --本金
             SUM(T.PRIN_FINAL_RESLT) PRIN_FINAL_RESLT, --减值
             '01' AS SIGN_TYPE,
             T.POLICY_BANK_FLAG AS POLICY_BANK_FLAG,
             0 AS MRFSZYS,
             0 AS POTENTIAL_RISK,
             ORG_NUM,
             0 AS  TRANSFER_DISCOUNT --转贴现买入
        FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH_G1403 T
       WHERE T.FLAG IN('1','2')
       GROUP BY T.ID_NO, NVL(T.CUST_NAM, T.CUST_NAM_S), POLICY_BANK_FLAG, ORG_NUM
   --买入返售(质押式) 债券 质押部分,质押的发行人  G1405 非银行金融债，商业银行债，政策性银行债，同业存单，二级资本债，次级债等 ,其他在G1403
      UNION ALL
      SELECT NVL(T.PLEDGE_CUST_NAM, T.PLEDGE_CUST_NAM_S) AS CUST_NAM, --客户名称
             T.PLEDGE_ID_NO, --客户代码
             0 YBFX_GXDK,           --其中：各项贷款
             0 YBFX_ZQTZ,           --其中：债券投资
             0 XTCP,                --其中：信托产品
             0 FBBLC,               --其中：非保本理财
             0 ZQYZGCP,             --其中：证券业资管产品
             0 ZCZQHCP,             --资产证券化产品
             SUM(CASE
                   WHEN T.BOOK_TYPE = '1' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    PRIN_MINUS
                   ELSE
                    0
             END) JYZBFXBL,            --交易账簿风险暴露
             0 JYDSXYFX,            --交易对手信用风险暴露
             0 YC,                  --其中：银行承兑汇票
             0 XYZ,                 --其中：跟单信用证
             0 BH,                  --其中：保函
             0 CN,                  --其中：贷款承诺
             0 QTFXBL,              --其他风险暴露
             -1 * SUM(T.PRIN_MINUS) FXHS,                --风险缓释转出的风险暴露（转入为负数）
             0 LOAN_BALANCE,        --各项贷款余额
             0 BLDK,                --附注：不良贷款余额
             0 YQDK,                --附注：逾期贷款余额
             SUM(T.BALANCE) AS BALANCE, --本金
             SUM(T.PRIN_FINAL_RESLT) PRIN_FINAL_RESLT, --减值
             '02' AS SIGN_TYPE,
             T.POLICY_BANK_FLAG AS POLICY_BANK_FLAG,
             SUM(CASE
                   WHEN T.BOOK_TYPE = '2' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    T.PRIN_MINUS
                   ELSE
                    0
             END) AS MRFSZYS,
             0 AS POTENTIAL_RISK,
             ORG_NUM,
             0 AS  TRANSFER_DISCOUNT --转贴现买入
        FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH_G1403 T
       WHERE T.FLAG = '3'
         AND ((T.ISSU_ORG = 'A02' AND T.STOCK_PRO_TYPE = 'A') --地方政府债
          OR (T.ISSU_ORG = 'A01' AND T.STOCK_PRO_TYPE = 'A') --国债
          OR (T.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05'))) ----超短期融资券，短期融资券，公司债，企业债，中期票据
       GROUP BY T.PLEDGE_ID_NO,
                NVL(T.PLEDGE_CUST_NAM, T.PLEDGE_CUST_NAM_S),
                POLICY_BANK_FLAG,
                ORG_NUM
       --转帖现卖出  （商票取出票人）
      UNION ALL
      SELECT T.CUST_NAM AS CUST_NAM, --客户名称（商票取出票人）
             T.ID_NO, --客户代码（商票取出票人）
             0 YBFX_GXDK,           --其中：各项贷款
             0 YBFX_ZQTZ,           --其中：债券投资
             0 XTCP,                --其中：信托产品
             0 FBBLC,               --其中：非保本理财
             0 ZQYZGCP,             --其中：证券业资管产品
             0 ZCZQHCP,             --资产证券化产品
             SUM(CASE
                   WHEN T.BOOK_TYPE = '1' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    PRIN_MINUS
                   ELSE
                    0
             END) JYZBFXBL,            --交易账簿风险暴露
             0 JYDSXYFX,            --交易对手信用风险暴露
             0 YC,                  --其中：银行承兑汇票
             0 XYZ,                 --其中：跟单信用证
             0 BH,                  --其中：保函
             0 CN,                  --其中：贷款承诺
             0 QTFXBL,              --其他风险暴露
             0  FXHS,                --风险缓释转出的风险暴露（转入为负数）
             0 LOAN_BALANCE,        --各项贷款余额
             0 BLDK,                --附注：不良贷款余额
             0 YQDK,                --附注：逾期贷款余额
             SUM(T.BALANCE) AS BALANCE, --本金
             SUM(T.PRIN_FINAL_RESLT) PRIN_FINAL_RESLT, --减值
             '03' AS SIGN_TYPE,
             T.POLICY_BANK_FLAG AS POLICY_BANK_FLAG,
             0 AS MRFSZYS,
             SUM(CASE
                   WHEN T.BOOK_TYPE = '2' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    T.PRIN_MINUS
                   ELSE
                    0
                 END)  AS POTENTIAL_RISK,   --银票报送G1405,商票报送在G1403(承兑人是银行或者企业)
             ORG_NUM,
             0 AS  TRANSFER_DISCOUNT --转贴现买入
        FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH_G1403 T
       WHERE T.FLAG = '4'
       GROUP BY T.ID_NO, T.CUST_NAM, POLICY_BANK_FLAG, ORG_NUM
       UNION ALL
       -- 转贴现买入
      SELECT T.CUST_NAM AS CUST_NAM, --客户名称（商票取出票人）
             T.ID_NO, --客户代码（商票取出票人）
             0 YBFX_GXDK, --其中：各项贷款
             0 YBFX_ZQTZ, --其中：债券投资
             0 XTCP, --其中：信托产品
             0 FBBLC, --其中：非保本理财
             0 ZQYZGCP, --其中：证券业资管产品
             0 ZCZQHCP, --资产证券化产品
             SUM(CASE
                   WHEN T.BOOK_TYPE = '1' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    PRIN_MINUS
                   ELSE
                    0
                 END) JYZBFXBL, --交易账簿风险暴露
             0 JYDSXYFX, --交易对手信用风险暴露
             0 YC, --其中：银行承兑汇票
             0 XYZ, --其中：跟单信用证
             0 BH, --其中：保函
             0 CN, --其中：贷款承诺
             0 QTFXBL, --其他风险暴露
             0 FXHS, --风险缓释转出的风险暴露（转入为负数）
             0 LOAN_BALANCE, --各项贷款余额
             0 BLDK, --附注：不良贷款余额
             0 YQDK, --附注：逾期贷款余额
             SUM(T.BALANCE) AS BALANCE, --本金
             SUM(T.PRIN_FINAL_RESLT) PRIN_FINAL_RESLT, --减值
             '04' AS SIGN_TYPE,
             T.POLICY_BANK_FLAG AS POLICY_BANK_FLAG,
             0 AS MRFSZYS,
             0 AS POTENTIAL_RISK, --银票报送G1405,商票报送在G1403(承兑人是银行或者企业)
             ORG_NUM,
             SUM(CASE
                   WHEN T.BOOK_TYPE = '2' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    T.PRIN_MINUS
                   ELSE
                    0
                 END) AS TRANSFER_DISCOUNT --转贴现买入
        FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH_G1403 T
       WHERE T.FLAG = '5'
       GROUP BY T.ID_NO, T.CUST_NAM, POLICY_BANK_FLAG, ORG_NUM;
    COMMIT;



    --==================================================
    --业务数据排序结果表处理
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '业务数据排序结果表处理';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH_RESULT_G1403
      (SEQ_NO, -- 序号
       CUST_NAM, -- 客户名称
       ID_NO, -- 证件号
       FXBLHJ, -- 风险暴露合计
       BKHMFXBL, -- 其中：不可豁免风险暴露
       YBFXBLHJ, -- 一般风险暴露合计
       YBFX_GXDK, -- 其中：各项贷款
       YBFX_ZQTZ, -- 其中：债券投资
       ZCGLCP, -- 资产管理产品
       XTCP, -- 其中：信托产品
       FBBLC, -- 其中：非保本理财
       ZQYZGCP, -- 其中：证券业资管产品
       ZCZQHCP, -- 资产证券化产品
       JYZBFXBL, -- 交易账簿风险暴露
       JYDSXYFX, -- 交易对手信用风险暴露
       QZFXBLHJ, -- 潜在风险暴露合计
       YC, -- 其中：银行承兑汇票
       XYZ, -- 其中：跟单信用证
       BH, -- 其中：保函
       CN, -- 其中：贷款承诺
       QTFXBL, -- 其他风险暴露
       FXHS, -- 风险缓释转出的风险暴露（转入为负数）
       LOAN_BALANCE, -- 各项贷款余额
       BLDK, -- 附注：不良贷款余额
       YQDK, -- 附注：逾期贷款余额
       ORG_NUM --机构号
       )
      SELECT ROW_NUMBER() OVER(PARTITION BY ORG_NUM ORDER BY FXBLHJ DESC) AS SEQ_NO, -- 序号
             CUST_NAM, -- 客户名称
             ID_NO, -- 证件号
             FXBLHJ, -- 风险暴露合计
             BKHMFXBL, -- 其中：不可豁免风险暴露
             YBFXBLHJ, -- 一般风险暴露合计
             YBFX_GXDK, -- 其中：各项贷款
             YBFX_ZQTZ, -- 其中：债券投资
             ZCGLCP, -- 资产管理产品
             XTCP, -- 其中：信托产品
             FBBLC, -- 其中：非保本理财
             ZQYZGCP, -- 其中：证券业资管产品
             ZCZQHCP, -- 资产证券化产品
             JYZBFXBL, -- 交易账簿风险暴露
             JYDSXYFX, -- 交易对手信用风险暴露
             QZFXBLHJ, -- 潜在风险暴露合计
             YC, -- 其中：银行承兑汇票
             XYZ, -- 其中：跟单信用证
             BH, -- 其中：保函
             CN, -- 其中：贷款承诺
             QTFXBL, -- 其他风险暴露
             FXHS, -- 风险缓释转出的风险暴露（转入为负数）
             LOAN_BALANCE, -- 各项贷款余额
             BLDK, -- 附注：不良贷款余额
             YQDK, -- 附注：逾期贷款余额
             ORG_NUM  --机构号
        FROM (SELECT CUST_NAM,
                     ID_NO,
                     CASE
                       WHEN ID_NO = '91210000744327380Q' THEN     --华晨汽车集团控股有限公司  91210000744327380Q，特殊数据处理问题，报送在投资银行部009817，非金融市场部009804
                        '009817'
                       ELSE
                        ORG_NUM    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务
                     END ORG_NUM,
                     SUM(YBFX_GXDK + YBFX_ZQTZ + MRFSZYS + XTCP + FBBLC +
                         ZQYZGCP + ZCZQHCP + JYZBFXBL + JYDSXYFX + YC + XYZ + BH + CN +
                         QTFXBL + POTENTIAL_RISK + TRANSFER_DISCOUNT) AS FXBLHJ, -- 风险暴露合计
                     SUM(CASE
                           WHEN POLICY_BANK_FLAG = 'Y' THEN --政策性银行都可以豁免
                            0
                           ELSE
                            YBFX_GXDK + YBFX_ZQTZ + MRFSZYS + XTCP + FBBLC +
                            ZQYZGCP + ZCZQHCP + JYZBFXBL + JYDSXYFX + YC + XYZ + BH + CN +
                            QTFXBL + POTENTIAL_RISK + TRANSFER_DISCOUNT
                         END) AS BKHMFXBL, -- 其中：不可豁免风险暴露
                     SUM(YBFX_GXDK + YBFX_ZQTZ + MRFSZYS  + TRANSFER_DISCOUNT) AS YBFXBLHJ, -- 一般风险暴露合计
                     SUM(YBFX_GXDK) AS YBFX_GXDK, -- 其中：各项贷款
                     SUM(YBFX_ZQTZ) AS YBFX_ZQTZ, -- 其中：债券投资
                     SUM(XTCP + FBBLC + FBBLC) AS ZCGLCP, -- 资产管理产品
                     SUM(XTCP) AS XTCP, -- 其中：信托产品
                     SUM(FBBLC) AS FBBLC, -- 其中：非保本理财
                     SUM(ZQYZGCP) AS ZQYZGCP, -- 其中：证券业资管产
                     SUM(ZCZQHCP) AS ZCZQHCP, -- 资产证券化产品
                     SUM(JYZBFXBL) AS JYZBFXBL, -- 交易账簿风险暴露
                     SUM(JYDSXYFX) AS JYDSXYFX, -- 交易对手信用风险暴
                     SUM(YC + XYZ + BH + CN + POTENTIAL_RISK) AS QZFXBLHJ, -- 潜在风险暴露合计
                     SUM(YC) AS YC, -- 其中：银行承兑汇票
                     SUM(XYZ) AS XYZ, -- 其中：跟单信用证
                     SUM(BH) AS BH, -- 其中：保函
                     SUM(CN) AS CN, -- 其中：贷款承诺
                     SUM(QTFXBL) AS QTFXBL, -- 其他风险暴露
                     SUM(FXHS) AS FXHS, -- 风险缓释转出的风险
                     SUM(LOAN_BALANCE) AS LOAN_BALANCE, -- 各项贷款余额
                     SUM(BLDK) AS BLDK, -- 附注：不良贷款余额
                     SUM(YQDK) AS YQDK -- 附注：逾期贷款余额
                FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH_MIDDLE_G1403 T
               GROUP BY CUST_NAM, ID_NO, ORG_NUM) T;
    COMMIT;


    --==================================================
    --G1403数据机构处理最终表
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1403数据机构处理最终表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1403
      (ORG_CODE,
       SEQ_NO,
       CUST_NAM,
       ID_NO,
       FXBLHJ,
       BKHMFXBL,
       YBFXBLHJ,
       YBFX_GXDK,
       YBFX_ZQTZ,
       ZCGLCP,
       XTCP,
       FBBLC,
       ZQYZGCP,
       ZCZQHCP,
       JYZBFXBL,
       JYDSXYFX,
       QZFXBLHJ,
       YC,
       XYZ,
       BH,
       CN,
       QTFXBL,
       FXHS,
       LOAN_BALANCE,
       BLDK,
       YQDK,
       DATA_DATE,
       CUST_TYPE,
       REPORT_ITEM_ID)
      SELECT CASE
               WHEN ID_NO = '91210000744327380Q' THEN
                '009817'
               ELSE
                ORG_NUM    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务
             END AS ORG_CODE,
             A.SEQ_NO,
             CUST_NAM,
             ID_NO,
             FXBLHJ,
             BKHMFXBL,
             YBFXBLHJ,
             YBFX_GXDK,
             YBFX_ZQTZ,
             ZCGLCP,
             XTCP,
             FBBLC,
             ZQYZGCP,
             ZCZQHCP,
             JYZBFXBL,
             JYDSXYFX,
             QZFXBLHJ,
             YC,
             XYZ,
             BH,
             CN,
             QTFXBL,
             FXHS,
             LOAN_BALANCE,
             BLDK,
             YQDK,
             I_DATADATE,
             '非同业单一客户' AS CUST_TYPE,
             B.REPORT_ITEM_ID
        FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH_RESULT_G1403 A
        LEFT JOIN CBRC_G1403_CONFIG_RESULT_MAPPING B
          ON A.SEQ_NO = B.SEQ_NO
       WHERE A.SEQ_NO <= 100; --金市小于100数据

    COMMIT;

     --==================================================
    --G1403更新客户信息
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1403更新客户信息';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


  --更新客户信息：省政府的是省财政厅,自治区政府是自治区财政厅（财政厅）  市人民政府，市政府是市财政局（财政局）

     UPDATE CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1403 T
        SET T.CUST_NAM = CASE
                           WHEN T.CUST_NAM LIKE '%省政府'  THEN
                            REPLACE(T.CUST_NAM, '省政府', '省财政厅')
                           WHEN T.CUST_NAM LIKE '%自治区政府' THEN
                            REPLACE(T.CUST_NAM, '自治区政府', '自治区财政厅')
                           WHEN T.CUST_NAM LIKE '%市人民政府' THEN
                            REPLACE(T.CUST_NAM, '市人民政府', '市财政局')
                           WHEN T.CUST_NAM LIKE '%市政府' THEN
                            REPLACE(T.CUST_NAM, '市政府', '市财政局')
                           WHEN T.CUST_NAM LIKE '%省人民政府' THEN
                            REPLACE(T.CUST_NAM, '省人民政府', '省财政厅')
                           WHEN T.CUST_NAM LIKE '%自治区人民政府' THEN
                            REPLACE(T.CUST_NAM, '自治区人民政府', '自治区财政厅')
                           ELSE
                            T.CUST_NAM
                         END
      WHERE (T.CUST_NAM LIKE '%省政府' OR T.CUST_NAM LIKE '%自治区政府' OR
            T.CUST_NAM LIKE '%市人民政府' OR T.CUST_NAM LIKE '%市政府'
             OR  T.CUST_NAM LIKE '%省人民政府' OR  T.CUST_NAM LIKE '%自治区人民政府');

     COMMIT;

  --所有中华人民共和国财政部、财政厅，财政局都是可豁免，因此 其中：不可豁免风险暴露都置为0、

     UPDATE CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1403 T
        SET T.BKHMFXBL = 0
      WHERE (T.CUST_NAM LIKE '%财政厅' OR T.CUST_NAM LIKE '%财政局' OR T.CUST_NAM='中华人民共和国财政部' );

     COMMIT;



    --==================================================
    --G1403更新各机构配置结果
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1403更新各机构配置结果';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务
    DECLARE
         V_SQL   VARCHAR2(1000); --金融市场部
         V_SQL_V VARCHAR2(1000);
         V_SQL1   VARCHAR2(1000);--投资银行部
         V_SQL_V1 VARCHAR2(1000);
         V_SQL2   VARCHAR2(1000);--总行清算中心(国际业务部)
         V_SQL_V2 VARCHAR2(1000);
       BEGIN
       ----------------------金融市场部----------------------
         FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1403_CONFIG_TMP F
                    WHERE F.REPORT_ITEM_NAME NOT IN
                          ('CUST_TYPE', 'CUST_NAM', 'ID_NO')) LOOP --补充数值型字段
           V_SQL := 'UPDATE CBRC_G1403_CONFIG_TMP B SET B.ITEM_VAL = (SELECT ' ||
                    NVL(I.REPORT_ITEM_NAME, 0) ||
                    ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1403
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                    I_DATADATE || '''' ||  ' AND ORG_CODE = ' || '''' ||
                    '009804' ||'''' || ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                    I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL);
           EXECUTE IMMEDIATE V_SQL;
         COMMIT;
         END LOOP;

         FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1403_CONFIG_TMP F
                    WHERE F.REPORT_ITEM_NAME IN
                          ('CUST_TYPE', 'CUST_NAM', 'ID_NO')) LOOP  --补充字符型字段
           V_SQL_V := 'UPDATE CBRC_G1403_CONFIG_TMP B SET B.ITEM_VAL_V = (SELECT ' ||
                      NVL(I.REPORT_ITEM_NAME, 0) ||
                      ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1403
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                      I_DATADATE || '''' ||  ' AND ORG_CODE = ' || '''' ||
                      '009804' ||'''' || ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                      I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL);
           EXECUTE IMMEDIATE V_SQL_V;
          COMMIT;
         END LOOP;

      ----------------------投资银行部----------------------
      --只有华晨汽车集团控股有限公司  91210000744327380Q，特殊数据处理问题，报送在投资银行部009817，非金融市场部009804
        FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1403_CONFIG_TMP_TH F
                    WHERE F.REPORT_ITEM_NAME NOT IN
                          ('CUST_TYPE', 'CUST_NAM', 'ID_NO')) LOOP --补充数值型字段
           V_SQL1 := 'UPDATE CBRC_G1403_CONFIG_TMP_TH B SET B.ITEM_VAL = (SELECT ' ||
                    NVL(I.REPORT_ITEM_NAME, 0) ||
                    ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1403
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                    I_DATADATE || '''' ||  ' AND ORG_CODE = ' || '''' ||
                    '009817' ||'''' || ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                    I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL);
           EXECUTE IMMEDIATE V_SQL1;
         COMMIT;
         END LOOP;

         FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1403_CONFIG_TMP_TH F
                    WHERE F.REPORT_ITEM_NAME IN
                          ('CUST_TYPE', 'CUST_NAM', 'ID_NO')) LOOP  --补充字符型字段
           V_SQL_V1 := 'UPDATE CBRC_G1403_CONFIG_TMP_TH B SET B.ITEM_VAL_V = (SELECT ' ||
                      NVL(I.REPORT_ITEM_NAME, 0) ||
                      ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1403
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                      I_DATADATE || '''' ||  ' AND ORG_CODE = ' || '''' ||
                      '009817' ||'''' || ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                      I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL);
           EXECUTE IMMEDIATE V_SQL_V1;
          COMMIT;
         END LOOP;
        ----------------------总行清算中心(国际业务部)----------------------
        FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1403_CONFIG_TMP_QS F
                    WHERE F.REPORT_ITEM_NAME NOT IN
                          ('CUST_TYPE', 'CUST_NAM', 'ID_NO')) LOOP --补充数值型字段
           V_SQL2 := 'UPDATE CBRC_G1403_CONFIG_TMP_QS B SET B.ITEM_VAL = (SELECT ' ||
                    NVL(I.REPORT_ITEM_NAME, 0) ||
                    ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1403
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                    I_DATADATE || '''' ||  ' AND ORG_CODE = ' || '''' ||
                    '009801' ||'''' || ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                    I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL);
           EXECUTE IMMEDIATE V_SQL2;
         COMMIT;
         END LOOP;


         FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1403_CONFIG_TMP_QS F
                    WHERE F.REPORT_ITEM_NAME IN
                          ('CUST_TYPE', 'CUST_NAM', 'ID_NO')) LOOP  --补充字符型字段
           V_SQL_V2 := 'UPDATE CBRC_G1403_CONFIG_TMP_QS B SET B.ITEM_VAL_V = (SELECT ' ||
                      NVL(I.REPORT_ITEM_NAME, 0) ||
                      ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1403
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                      I_DATADATE || '''' ||  ' AND ORG_CODE = ' || '''' ||
                      '009801' ||'''' || ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                      I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL);
           EXECUTE IMMEDIATE V_SQL_V2;
          COMMIT;
         END LOOP;

       END;



    --==================================================
    --G1403插入A_REPT_ITEM_VAL
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1405数据机构处理前100家进A_REPT_ITEM_VAL';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL,ITEM_VAL_V, FLAG,IS_TOTAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009804',
             'CBRC' AS SYS_NAM,
             'G1403' AS REP_NUM,
             ITEM_NUM AS ITEM_NUM,
             ITEM_VAL AS ITEM_VAL,
             ITEM_VAL_V AS ITEM_VAL_V,
             '2' AS FLAG,
             'Y' AS IS_TOTAL
        FROM CBRC_G1403_CONFIG_TMP
       UNION ALL
       SELECT I_DATADATE AS DATA_DATE,
             '009817',
             'CBRC' AS SYS_NAM,
             'G1403' AS REP_NUM,
             ITEM_NUM AS ITEM_NUM,
             ITEM_VAL AS ITEM_VAL,
             ITEM_VAL_V AS ITEM_VAL_V,
             '2' AS FLAG,
             'Y' AS IS_TOTAL
        FROM CBRC_G1403_CONFIG_TMP_TH
        UNION ALL
       SELECT I_DATADATE AS DATA_DATE,
             '009801',
             'CBRC' AS SYS_NAM,
             'G1403' AS REP_NUM,
             ITEM_NUM AS ITEM_NUM,
             ITEM_VAL AS ITEM_VAL,
             ITEM_VAL_V AS ITEM_VAL_V,
             '2' AS FLAG,
             'Y' AS IS_TOTAL
        FROM CBRC_G1403_CONFIG_TMP_QS;

    COMMIT;


    -------------------------------------------------------------------------------------------
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
   
END proc_cbrc_idx2_g1403;
