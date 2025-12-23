CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g1405(II_DATADATE  IN string --跑批日期
                                                   )
/******************************
  @AUTHOR:DJH
  @CREATE-DATE:20240415
  @DESCRIPTION:G1405  G14 大额风险暴露统计表-第V部分：同业单一客户大额风险暴露情况表
  @MODIFICATION HISTORY:
  --需求编号：JLBA202505140011_关于1104报表系统金融市场部报表取数逻辑变更的需求 上线日期：2025-07-29 修改人：常金磊，提出人：康立军 修改内容：调整债券、存单关联减值表的关联条件，解决关联重复问题
  需求编号：JLBA202505280011 上线日期： 2025-09-19，修改人：狄家卉，提出人：赵翰君  修改原因：关于实现1104监管报送报表自动化采集加工的需求  增加009801清算中心(国际业务部)外币折人民币业务
  
  
  目标表：CBRC_A_REPT_ITEM_VAL
  
 临时表：
      CBRC_BUSINESS_TABLE_TYDYKH_RESULT
      CBRC_BUSINESS_TABLE_TYDYKH_RESULT_FZ
      CBRC_TMP_ASSET_DEVALUE_PREPARE
      CBRC_TMP_BUSINESS_TABLE_TYDYKH
      CBRC_TMP_BUSINESS_TABLE_TYDYKH_MIDDLE
      CBRC_TMP_BUSINESS_TABLE_TYDYKH_RESULT
      CBRC_TMP_ECIF_L_CUST_BILL_TY
      
   码值表：CBRC_G1405_CONFIG_TMP     --金融市场部
      CBRC_G1405_CONFIG_RESULT_MAPPING
      CBRC_G1405_CONFIG_TMP_FZ     ----金融市场部附注
      CBRC_G1405_CONFIG_TMP_QS     --清算
      CBRC_G1405_CONFIG_TMP_QS_FZ  --清算附注
      CBRC_G1405_CONFIG_TMP_TY   --同业 
      CBRC_G1405_CONFIG_TMP_TY_FZ  --同业附注
      
   视图表：SMTMODS_V_PUB_IDX_FINA_GL
  集市表：SMTMODS_L_ACCT_FUND_CDS_BAL
      SMTMODS_L_ACCT_FUND_INVEST
      SMTMODS_L_ACCT_FUND_MMFUND
      SMTMODS_L_ACCT_FUND_REPURCHASE
      SMTMODS_L_ACCT_LOAN
      SMTMODS_L_AGRE_BILL_INFO
      SMTMODS_L_AGRE_BONDISSUER_INFO
      SMTMODS_L_AGRE_BOND_INFO
      SMTMODS_L_AGRE_REPURCHASE_GUARANTY_INFO
      SMTMODS_L_CUST_BILL_TY
      SMTMODS_L_CUST_C
      SMTMODS_L_FINA_ASSET_DEVALUE
      SMTMODS_L_PUBL_RATE
      SMTMODS_L_TRAN_FUND_FX


  
  
  
  *******************************/
 IS
  V_PROCEDURE VARCHAR(30); --当前储存过程名称
  V_TAB_NAME  VARCHAR(30); --目标表名
  I_DATADATE  string; --数据日期(数值型)YYYYMMDD
  V_STEP_ID   INTEGER; --任务号
  V_STEP_DESC VARCHAR(300); --任务描述
  V_STEP_FLAG INTEGER; --任务执行状态标识
  V_ERRORCODE VARCHAR(20); --错误编码
  V_ERRORDESC VARCHAR(280); --错误内容
  V_PER_NUM   VARCHAR(30); --报表编号
  V_DATADATE  VARCHAR2(10);
  II_STATUS   iNTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM    VARCHAR(30);

BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';
    V_PER_NUM   := 'G1405';
    I_DATADATE  := II_DATADATE;
    V_DATADATE  := TO_CHAR(DATE(I_DATADATE), 'YYYY-MM-DD');
    V_TAB_NAME  := 'G1405';
	V_SYSTEM    := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G1405');
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
 


    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TMP_ASSET_DEVALUE_PREPARE'; --资产减值准备临时表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TMP_ECIF_L_CUST_BILL_TY'; --同业客户信息处理
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TMP_BUSINESS_TABLE_TYDYKH'; --处理业务明细宽表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TMP_BUSINESS_TABLE_TYDYKH_MIDDLE'; --处理业务明细中间表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TMP_BUSINESS_TABLE_TYDYKH_RESULT'; --处理业务明细结果表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_BUSINESS_TABLE_TYDYKH_RESULT'; -- G14 大额风险暴露统计表-第V部分：同业单一客户大额风险暴露情况表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_BUSINESS_TABLE_TYDYKH_RESULT_FZ'; -- G14 大额风险暴露统计表-第V部分：同业单一客户大额风险暴露情况表 附注


    --G1405_CONFIG_RESULT_MAPPING  配置表   G1405_CONFIG_TMP  报表映射指标配置表(金融市场)   G1405_CONFIG_TMP_TY 报表映射指标配置表(同业金融)


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
    INTO CBRC_TMP_ASSET_DEVALUE_PREPARE 
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


    INSERT INTO CBRC_TMP_ECIF_L_CUST_BILL_TY
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
             '1' AS FLAG/*, --按照ECIF_CUST_ID客户号去重复
              ORG_AREA*/
        FROM (SELECT
    A.DATA_DATE
     , A.ORG_NUM
     , A.CUST_ID
     , A.LEGAL_NAME
     , A.FINA_ORG_CODE
     ,A.FINA_CODE_NEW
     , A.FINA_ORG_NAME
     , A.CAPITAL_AMT
     , A.BORROWER_REGISTER_ADDR
     , A.TYSHXYDM
     , A.ORGANIZATIONCODE
     , A.ECIF_CUST_ID
     , A.LEGAL_FLAG
     , A.LEGAL_TYSHXYDM
     , ROW_NUMBER()
        OVER
             ( PARTITION BY A.ECIF_CUST_ID
               ORDER BY
                    A.ECIF_CUST_ID) RN
FROM
    SMTMODS_L_CUST_BILL_TY A --一个ECIF客户对应,多个同业客户,对应一个公司/银行名
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


    INSERT INTO CBRC_TMP_ECIF_L_CUST_BILL_TY
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
             '2' AS FLAG/*, --按照CUST_ID客户号去重复
             ORG_AREA*/
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


    INSERT INTO CBRC_TMP_ECIF_L_CUST_BILL_TY
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
             '3' AS FLAG/*, --关联此段逻辑为了取法人行
             ORG_AREA*/
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


    ---------------------------业务宽表数据加工---------------------------
    ----一般风险暴露合计：其中：买入返售(质押式)+同业债券+同业存单+转帖现


    ---------------------------------------
    ----一般风险暴露其中：买入返售(质押式)  债券 ：质押物发行人
    ---------------------------------------
    --底层质押债是否是 非银行金融债,商业银行债,政策性银行债,同业存单,二级资本债,次级债等,如果是统计进G1405,不是统计进G1403
    --20240331 台账： 2894299000 系统： 2894298999.9998  select 2894299000-2894298999.9998 from dual; 差值0.0002


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


    INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH
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
       PLEDGE_CUST_NAM_S, --24质押客户名称_S
       POLICY_BANK_FLAG --25是否政策性银行标识
       )
      SELECT A.DATA_DATE, --01数据日期
             A.ORG_NUM, --02机构号
             A.CURR_CD, --03币种
             A.BOOK_TYPE, --04账户种类
             B.SUBJECT_CD, --05业务产品编号
             B.SUBJECT_NAM, --06业务名称
             B.COLL_SUBJECT_TYPE, --07业务类别
             SUM(B.BALANCE * U.CCY_RATE) AS BALANCE, --08质押券拆分总和
             SUM(NVL(C1.PRIN_FINAL_RESLT, 0)) PRIN_FINAL_RESLT, --09减值
             SUM(B.BALANCE * U.CCY_RATE - NVL(C1.PRIN_FINAL_RESLT, 0)) PRIN_MINUS, --10本金与减值差值
             A.CUST_ID, --11买入返售交易对手客户号
             T3.ID_NO, --12买入返售交易对手证件号
             T3.CUST_NAM, --13买入返售交易对手名称
             NVL(T1.ECIF_CUST_ID, T2.CUST_ID) PLEDGE_CUST_ID, --14质押的发行人客户号
             NVL(T1.TYSHXYDM, T2.TYSHXYDM) PLEDGE_CUST_NAM, --15质押发行人证件号
             NVL(T1.FINA_ORG_NAME, T2.FINA_ORG_NAME) PLEDGE_CUST_NAM, --16质押发行人客户名称
             '' AS LEGAL_ID_NO, --17法人统一社会信用代码
             '' AS LEGAL_CUST_NAM, --18法人名称
             C.ISSU_ORG, --19发行主体类型 A 政府  B 公共实体  C 企业 D  金融机构 E 境外金融机构
             C.STOCK_PRO_TYPE /*,D.STOCK_PRO_TYPE*/, --20产品分类 如是【债券产品类型】：A 政府债券（指我国政府发行债券） B央行票据 C金融债 D非金融企业债 F外国债 有些细化  或者【存单产品分类】 ：A  同业存单  B  大额存单
             A.GL_ITEM_CODE, --21科目号
             '1' AS FLAG, --22业务标识  买入返售(质押式)  债券
             A.JYDSMC AS CUST_NAM_S, --23买入返售交易对手名称  同（13买入返售交易对手名称）
             B.CUST_NAM AS PLEDGE_CUST_NAM_S, --24质押客户名称 同（16质押发行人客户名称） 即质押券或存单的发行人名称 (宇航说未来L_AGRE_REPURCHASE_GUARANTY_INFO加进来CUST_NAM就是L_AGRE_BOND_INFO发行主体名称）
             CASE
               WHEN NVL(T1.ECIF_CUST_ID, T2.CUST_ID) IN
                    ('8935000095', '8935000132', '8935000149') --政策性银行：8935000095国家开发银行，8935000132中国进出口银行，8935000149中国农业发展银行
                THEN
                'Y'
               ELSE
                'N'
             END AS POLICY_BANK_FLAG
        FROM SMTMODS_L_ACCT_FUND_REPURCHASE A
        LEFT JOIN SMTMODS_L_AGRE_REPURCHASE_GUARANTY_INFO B
          ON A.ACCT_NUM = B.ACCT_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_AGRE_BOND_INFO C --质押券的法人行人
          ON B.SUBJECT_CD = C.STOCK_CD
         AND C.DATA_DATE = I_DATADATE
      /*   LEFT JOIN SMTMODS_L_ACCT_FUND_CDS_BAL D  --此表只有投资和发行存单，没有质押存单，不能从这取相关信息
       ON B.SUBJECT_CD = D.CDS_NO
      AND D.DATA_DATE = I_DATADATE*/
        LEFT JOIN CBRC_TMP_ECIF_L_CUST_BILL_TY T1
          ON B.CUST_ID = T1.ECIF_CUST_ID
         AND T1.FLAG = '1'
        LEFT JOIN CBRC_TMP_ECIF_L_CUST_BILL_TY T2
          ON B.CUST_ID = T2.CUST_ID
         AND T2.FLAG = '2'
        LEFT JOIN SMTMODS_L_CUST_C T3
          ON A.CUST_ID = T3.CUST_ID
         AND T3.DATA_DATE = I_DATADATE
        /*LEFT JOIN CBRC_TMP_ASSET_DEVALUE_PREPARE C --资产减值准备
          ON A.REF_NUM = C.ACCT_NUM
         AND PRIN_SUBJ_NO LIKE '1111%'
         AND A.ORG_NUM=C.RECORD_ORG*/
        LEFT JOIN SMTMODS_L_FINA_ASSET_DEVALUE C1 --资产减值准备
          ON A.REF_NUM||'_'||B.SUBJECT_CD = C1.BIZ_NO
         AND PRIN_SUBJ_NO LIKE '1111%'
         AND A.ORG_NUM = C1.RECORD_ORG
         AND C1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
            --  AND A.ORG_NUM = '009804'
         AND SUBSTR(A.GL_ITEM_CODE,1,6) = '111101' --质押式买入返售债券 -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君]
         AND A.BALANCE <> 0  -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1111买入返售
         AND A.END_DT >= I_DATADATE --回购业务信息表[SMTMODS_L_ACCT_FUND_REPURCHASE]?修改数据组范围：质押式回购放开数据范围(筛除20210101之前的脏数据)???卡到期日期>=当前日期?
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
                NVL(T1.ECIF_CUST_ID, T2.CUST_ID), --质押客户号
                NVL(T1.TYSHXYDM, T2.TYSHXYDM), --质押证件号
                NVL(T1.FINA_ORG_NAME, T2.FINA_ORG_NAME), --质押客户名称
                C.ISSU_ORG, --发行主体类型
                C.STOCK_PRO_TYPE, --产品分类
                A.GL_ITEM_CODE,
                A.JYDSMC,
                --  B.CUST_ID,
                B.CUST_NAM;
    COMMIT;
    ---------------------------------------
    ----一般风险暴露其中：买入返售(质押式)  票据  ：承兑人/行法人
    ---------------------------------------
    --20240331 台账（结算金额）： 232768401.3 系统： 232768401.27 select 232768401.3-232768401.27 from dual; 差值0.03


    --==================================================
    --买入返售(质押式)  票据
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '买入返售(质押式)  票据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH
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
       PLEDGE_CUST_NAM_S, --24质押客户名称_S
       POLICY_BANK_FLAG --25是否政策性银行标识
       )
      SELECT A.DATA_DATE, --01数据日期
             A.ORG_NUM, --02机构号
             A.CURR_CD, --03币种
             A.BOOK_TYPE, --04账户种类
             A.SUBJECT_CD, --05业务产品编号
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
             SUM(A.BALANCE * U.CCY_RATE) AS BALANCE, --08本金 --质押券拆分总和  （台账质押式余额结算金额）
             SUM(NVL(C.PRIN_FINAL_RESLT, 0)) AS PRIN_FINAL_RESLT, --09减值
             SUM(A.BALANCE * U.CCY_RATE - nvl(C.PRIN_FINAL_RESLT, 0)) AS PRIN_MINUS, --10本金与减值差值
             A.CUST_ID AS ID_NO, --11交易对手客户号
             A.JYDSDM AS ID_NO, --12交易对手证件号
             A.JYDSMC AS CUST_NAM, --13交易对手客户名称
             NVL(T1.ECIF_CUST_ID, T2.CUST_ID) AS PLEDGE_CUST_ID, --14承兑人/行法人客户号
             NVL(T1.TYSHXYDM, T2.TYSHXYDM) AS PLEDGE_ID_NO, --15承兑人/行法人证件号
             NVL(T1.FINA_ORG_NAME, T2.FINA_ORG_NAME) AS PLEDGE_CUST_NAM, --16承兑人/行法人客户名称
             '' AS LEGAL_ID_NO, --17法人统一社会信用代码
             '' AS LEGAL_CUST_NAM, --18法人名称
             '' AS ISSU_ORG, --19发行主体类型
             '' AS STOCK_PRO_TYPE, --20产品分类
             A.GL_ITEM_CODE, --21科目号
             '2' AS FLAG, --22业务标识  买入返售(质押式)  票据
             '' AS CUST_NAM_S, --23 客户名称_S
             '' AS PLEDGE_CUST_NAM_S, --24质押客户名称_S
             CASE
               WHEN NVL(T1.ECIF_CUST_ID, T2.CUST_ID) IN
                    ('8935000095', '8935000132', '8935000149') --政策性银行：8935000095国家开发银行，8935000132中国进出口银行，8935000149中国农业发展银行
                THEN
                'Y'
               ELSE
                'N'
             END AS POLICY_BANK_FLAG --25是否政策性银行标识
        FROM SMTMODS_L_ACCT_FUND_REPURCHASE A
        LEFT JOIN SMTMODS_L_AGRE_BILL_INFO B -- 商业汇票票面信息表
          ON A.SUBJECT_CD = B.BILL_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_TMP_ECIF_L_CUST_BILL_TY T1
          ON B.PAY_CUSID = T1.ECIF_CUST_ID
         AND T1.FLAG = '1'
        LEFT JOIN CBRC_TMP_ECIF_L_CUST_BILL_TY T2
          ON B.PAY_CUSID = T2.CUST_ID
         AND T2.FLAG = '2'
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN CBRC_TMP_ASSET_DEVALUE_PREPARE C --资产减值准备
          ON A.REF_NUM = C.ACCT_NUM
         AND PRIN_SUBJ_NO LIKE '1111%'
         AND A.ORG_NUM=C.RECORD_ORG
       WHERE A.DATA_DATE = I_DATADATE
            --  AND A.ORG_NUM = '009804'
         AND A.GL_ITEM_CODE = '111102' --质押式买入返售票据
         AND A.BALANCE > 0
         AND B.BILL_TYPE = '1' --票据类型 --1 银行承兑汇票   2 商业承兑汇票 --G1405只是取银行承兑汇票，G1403取商业承兑汇票
         AND A.END_DT >= I_DATADATE --回购业务信息表[SMTMODS_L_ACCT_FUND_REPURCHASE]?修改数据组范围：质押式回购放开数据范围(筛除20210101之前的脏数据)???卡到期日期>=当前日期?
       GROUP BY A.CUST_ID,A.JYDSDM,A.JYDSMC,A.DATA_DATE, --01数据日期
                A.ORG_NUM, --02机构号
                A.CURR_CD, --03币种
                A.BOOK_TYPE, --04账户种类
                A.SUBJECT_CD, --05业务产品编号
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
                END, --07业务类别
                A.GL_ITEM_CODE, --21科目号
                NVL(T1.ECIF_CUST_ID, T2.CUST_ID),
                NVL(T1.TYSHXYDM, T2.TYSHXYDM),
                NVL(T1.FINA_ORG_NAME, T2.FINA_ORG_NAME),
                CASE
                  WHEN NVL(T1.ECIF_CUST_ID, T2.CUST_ID) IN
                       ('8935000095', '8935000132', '8935000149') --政策性银行：8935000095国家开发银行，8935000132中国进出口银行，8935000149中国农业发展银行
                   THEN
                   'Y'
                  ELSE
                   'N'
                END;
    COMMIT;


    ---------------------------------------
    ----一般风险暴露其中：同业债券   ：债券发行人
    ---------------------------------------
    --20240331 台账（账面余额）： 38317481990.22 系统： 38317481990.22  无差值


    --==================================================
    --同业债券
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '同业债券';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH
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
       PLEDGE_CUST_NAM_S, --24质押客户名称_S
       POLICY_BANK_FLAG --25是否政策性银行标识
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
       NVL(T1.ECIF_CUST_ID, T2.CUST_ID) AS CUST_ID, --11同业债券债券发行人客户号
       NVL(T1.TYSHXYDM, T2.TYSHXYDM) AS ID_NO, --12同业债券债券发行人证件号
       NVL(T1.FINA_ORG_NAME, T2.FINA_ORG_NAME) AS CUST_NAM, --13同业债券债券发行人客户名称
       '' AS PLEDGE_CUST_ID, --14质押客户号
       '' AS PLEDGE_ID_NO, --15质押证件号
       '' AS PLEDGE_CUST_NAM, --16质押客户名称
       '' AS LEGAL_ID_NO, --17法人统一社会信用代码
       '' AS LEGAL_CUST_NAM, --18法人名称
       A.ISSU_ORG, --19发行主体类型
       A.STOCK_PRO_TYPE, --20产品分类
       T.GL_ITEM_CODE, --21科目号
       '3' AS FLAG, --22业务标识 同业债券
       B.ISSUER_CUST_ID AS CUST_NAM_S, --23 同业债券债券发行人客户名称 同（13同业债券债券发行人客户名称）
       '' AS PLEDGE_CUST_NAM_S, --24质押客户名称_S
       CASE
         WHEN NVL(T1.ECIF_CUST_ID, T2.CUST_ID) IN
              ('8935000095', '8935000132', '8935000149') --政策性银行：8935000095国家开发银行，8935000132中国进出口银行，8935000149中国农业发展银行
          THEN
          'Y'
         ELSE
          'N'
       END AS POLICY_BANK_FLAG
        FROM SMTMODS_L_ACCT_FUND_INVEST T
        LEFT JOIN CBRC_TMP_ECIF_L_CUST_BILL_TY T1
          ON T.CUST_ID = T1.ECIF_CUST_ID
         AND T1.FLAG = '1'
        LEFT JOIN CBRC_TMP_ECIF_L_CUST_BILL_TY T2
          ON T.CUST_ID = T2.CUST_ID
         AND T2.FLAG = '2'
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
        LEFT JOIN CBRC_TMP_ASSET_DEVALUE_PREPARE C --资产减值准备
          ON C.ACCT_NUM = T.ACCT_NUM
         AND T.ACCT_NO = C.ACCT_ID  --[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
         AND T.GL_ITEM_CODE = C.PRIN_SUBJ_NO --投资 帐户分类 1101交易性金融资产 1501持有至到期投资 1503可供出售金融资产（一条对多条）
         AND C.DATA_DATE = I_DATADATE
         AND A.ORG_NUM=C.RECORD_ORG
       WHERE T.DATA_DATE = I_DATADATE
         AND ((A.ISSU_ORG = 'D03' AND A.STOCK_PRO_TYPE LIKE 'C%') /*AND A.STOCK_PRO_TYPE NOT IN ('C01', 'C0101')*/ --商业银行债
             OR (A.ISSU_ORG = 'D02' AND A.STOCK_PRO_TYPE LIKE 'C%') /* AND A.STOCK_PRO_TYPE NOT IN ('C01', 'C0101')*/ --政策性银行债
             OR A.STOCK_PRO_TYPE IN ('C01', 'C0101') --次级债、二级资本债
             OR (A.ISSU_ORG NOT IN ('D02', 'D03') AND
             A.STOCK_PRO_TYPE LIKE 'C%')) /*AND A.STOCK_PRO_TYPE NOT IN ('C01', 'C0101')*/ --非银行金融债
         AND PRINCIPAL_BALANCE <> 0;
    COMMIT;
    ---------------------------------------
    ----一般风险暴露其中：其中：政策性金融债 :国家开发银行，中国进出口银行，中国农业发展银行
    ---------------------------------------


    ---------------------------------------
    ----一般风险暴露其中：其中：同业存单
    ---------------------------------------
    --20240331 台账（账面余额）： 13563744410 系统： 13563744410  无差值


    --==================================================
    --同业存单
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '同业存单';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


   INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH
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
      PLEDGE_CUST_NAM_S, --24质押客户名称_S
      POLICY_BANK_FLAG --25是否政策性银行标识
      )
     SELECT 
      A.DATA_DATE, --01数据日期
      A.ORG_NUM, --02机构号
      A.CURR_CD, --03币种
      A.BOOK_TYPE, --04账户种类
      A.CDS_NO AS SUBJECT_CD, --05业务产品编号
      A.STOCK_NAM AS SUBJECT_NAM, --06业务名称
      '' AS COLL_SUBJECT_TYPE, --07业务类别
      A.PRINCIPAL_BALANCE * TT.CCY_RATE AS BALANCE, --08本金,
      CASE
        WHEN A.ACCOUNTANT_TYPE = '1' THEN
         0
        ELSE
         NVL(C.PRIN_FINAL_RESLT, 0) --交易性金融资产不算减值(不计入总账) 会计分类：1、交易类 2、可供出售类 3、持有至到期 4、贷款及应收款
      END AS PRIN_FINAL_RESLT, --09减值
      A.PRINCIPAL_BALANCE * TT.CCY_RATE - CASE
        WHEN A.ACCOUNTANT_TYPE = '1' THEN
         0
        ELSE
         NVL(C.PRIN_FINAL_RESLT, 0) --交易性金融资产不算减值(不计入总账) 会计分类：1、交易类 2、可供出售类 3、持有至到期 4、贷款及应收款
      END AS PRIN_MINUS, --10本金与减值差值
      /* NVL(T1.ECIF_CUST_ID, T2.CUST_ID) AS CUST_ID, --11客户号
      NVL(T1.TYSHXYDM, T2.TYSHXYDM) AS ID_NO, --12证件号
      NVL(T1.FINA_ORG_NAME, T2.FINA_ORG_NAME) AS CUST_NAM, --13客户名称*/
      T3.CUST_ID, --11客户号
      T3.ID_NO, --12证件号
      T3.CUST_NAM, --13客户名称
      '' AS PLEDGE_CUST_ID, --14质押客户号
      '' AS PLEDGE_ID_NO, --15质押证件号
      '' AS PLEDGE_CUST_NAM, --16质押客户名称
      '' AS LEGAL_ID_NO, --17法人统一社会信用代码
      '' AS LEGAL_CUST_NAM, --18法人名称
      '' AS ISSU_ORG, --19发行主体类型
      A.STOCK_PRO_TYPE, --20产品分类  --A  同业存单  B  大额存单
      A.GL_ITEM_CODE, --21科目号
      '4' AS FLAG, --22业务标识  同业存单
      A.CONT_PARTY_NAME AS CUST_NAM_S, --23 客户名称_S
      '' AS PLEDGE_CUST_NAM_S, --24质押客户名称_S
      CASE
        WHEN T3.CUST_ID IN
             ('8935000095', '8935000132', '8935000149') --政策性银行：8935000095国家开发银行，8935000132中国进出口银行，8935000149中国农业发展银行
         THEN
         'Y'
        ELSE
         'N'
      END AS POLICY_BANK_FLAG --25是否政策性银行标识
       FROM SMTMODS_L_ACCT_FUND_CDS_BAL A
       LEFT JOIN SMTMODS_L_CUST_C T3
         ON A.CUST_ID = T3.CUST_ID
        AND T3.DATA_DATE = I_DATADATE
       LEFT JOIN SMTMODS_L_PUBL_RATE TT
         ON TT.CCY_DATE = I_DATADATE
        AND TT.BASIC_CCY = A.CURR_CD
        AND TT.FORWARD_CCY = 'CNY'
       LEFT JOIN CBRC_TMP_ASSET_DEVALUE_PREPARE C --资产减值准备
         -- ON C.ACCT_NUM = A.ACCT_NUM
         -- AND A.GL_ITEM_CODE = C.PRIN_SUBJ_NO
         -- ON SUBSTR(A.ACCT_NUM, 1, INSTR(A.ACCT_NUM, '_') - 1) = C.BIZ_NO
         --[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
         ON REPLACE(A.ACCT_NUM,'_','') = C.ACCT_NUM||C.ACCT_ID
        AND A.GL_ITEM_CODE = C.PRIN_SUBJ_NO 
        AND A.ORG_NUM = C.RECORD_ORG --一个存单 对应多个机构
        AND C.DATA_DATE = I_DATADATE
        AND A.GL_ITEM_CODE = C.PRIN_SUBJ_NO
     -- AND C.RECORD_ORG = '009804'
      WHERE A.DATA_DATE = I_DATADATE
        AND STOCK_PRO_TYPE = 'A' --同业存单
        AND PRODUCT_PROP = 'A' --持有
           --  AND A.ORG_NUM = '009804'--金融市场部 同业金融部均使用此逻辑 20240807 ADD BY DJH
        AND A.PRINCIPAL_BALANCE <> 0
         ;
    COMMIT;

    --20240331 台账（票据（包）金额）： 3984206156.23 系统： 3984206156.23  无差值
    --==================================================
    --转贴现 （转贴现买入）
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '转贴现 （转贴现买入）';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH
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
       PLEDGE_CUST_NAM_S, --24质押客户名称_S
       POLICY_BANK_FLAG --25是否政策性银行标识
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
       NVL(T1.ECIF_CUST_ID, T2.CUST_ID) AS CUST_ID, --11承兑行法人客户号
       NVL(T1.TYSHXYDM, T2.TYSHXYDM) AS ID_NO, --12承兑行法人证件号
       NVL(T1.FINA_ORG_NAME, T2.FINA_ORG_NAME) AS CUST_NAM, --13承兑行法人客户名称
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
       '' AS PLEDGE_CUST_NAM_S, --24质押客户名称_S
       CASE
         WHEN NVL(T1.ECIF_CUST_ID, T2.CUST_ID) IN
              ('8935000095', '8935000132', '8935000149') --政策性银行：8935000095国家开发银行，8935000132中国进出口银行，8935000149中国农业发展银行
          THEN
          'Y'
         ELSE
          'N'
       END AS POLICY_BANK_FLAG --25是否政策性银行标识
        FROM SMTMODS_L_ACCT_LOAN A -- 贷款借据信息表
        LEFT JOIN SMTMODS_L_AGRE_BILL_INFO B -- 商业汇票票面信息表
          ON A.DRAFT_NBR = B.BILL_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_TMP_ECIF_L_CUST_BILL_TY T1
          ON B.PAY_CUSID = T1.ECIF_CUST_ID
         AND T1.FLAG = '1'
        LEFT JOIN CBRC_TMP_ECIF_L_CUST_BILL_TY T2
          ON B.PAY_CUSID = T2.CUST_ID
         AND T2.FLAG = '2'
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_TMP_ASSET_DEVALUE_PREPARE C --资产减值准备
          ON A.LOAN_NUM = C.ACCT_NUM
            -- AND T.GL_ITEM_CODE = C.PRIN_SUBJ_NO
         AND C.DATA_DATE = I_DATADATE
         AND A.ORG_NUM=C.RECORD_ORG
       WHERE A.DATA_DATE = I_DATADATE
         AND (ITEM_CD LIKE '130102%' --以摊余成本计量的转贴现
             OR ITEM_CD LIKE '130105%')
         AND A.LOAN_ACCT_BAL <> 0
         AND A.ORG_NUM = '009804'
         AND B.BILL_TYPE = '1' --票据类型 --1 银行承兑汇票   2 商业承兑汇票 --G1405只是取银行承兑汇票，G1403取商业承兑汇票
         AND (NVL(T1.TYSHXYDM, T2.TYSHXYDM) <>'9122010170255776XN'  OR NVL(T1.TYSHXYDM, T2.TYSHXYDM) IS NULL) --吉林银行去掉
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
                NVL(T1.ECIF_CUST_ID, T2.CUST_ID),
                NVL(T1.TYSHXYDM, T2.TYSHXYDM),
                NVL(T1.FINA_ORG_NAME, T2.FINA_ORG_NAME),
                A.ITEM_CD, --21科目号
                CASE
                  WHEN NVL(T1.ECIF_CUST_ID, T2.CUST_ID) IN
                       ('8935000095', '8935000132', '8935000149') --政策性银行：8935000095国家开发银行，8935000132中国进出口银行，8935000149中国农业发展银行
                   THEN
                   'Y'
                  ELSE
                   'N'
                END;
    COMMIT;

  ---------------------------------------
    ----交易账簿风险暴露
    ---------------------------------------


    ---------------------------------------
    ----潜在风险暴露  （转贴现卖出）
    ---------------------------------------
    ----业务时间在一年内，到期日大于当前日期所有的，票据类型要区分商票还是银票，银票报送G1405,商票报送在G1403(承兑人是银行或者企业)


    --20240331 台账（票据（包）金额）：5381092469.24 系统： 5401092469.24  select 5401092469.24-5381092469.24 from dual; 差值20000000（2千万）


    --实际系统中多取两条131324101042220231218731041934 131322107004220231220732884944 比台账多，是不是确实需要统计进来


    --==================================================
    --潜在风险暴露  （转贴现卖出）
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '潜在风险暴露  （转贴现卖出）';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH
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
       PLEDGE_CUST_NAM_S, --24质押客户名称_S
       POLICY_BANK_FLAG --25是否政策性银行标识
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
       A.ECIF_CUST_ID AS CUST_ID, --11客户号
       A.TYSHXYDM AS ID_NO, --12证件号
       A.FINA_ORG_NAME AS CUST_NAM, --13客户名称
       '' AS PLEDGE_CUST_ID, --14质押客户号
       '' AS PLEDGE_ID_NO, --15质押证件号
       '' AS PLEDGE_CUST_NAM, --16质押客户名称
       A.LEGAL_TYSHXYDM AS LEGAL_ID_NO, --17法人统一社会信用代码
       T3.FINA_ORG_NAME AS LEGAL_CUST_NAM, --18法人名称
       '' AS ISSU_ORG, --19发行主体类型
       '' AS STOCK_PRO_TYPE, --20产品分类
       A.ITEM_CD AS GL_ITEM_CODE, --21科目号
       '6' AS FLAG, --22业务标识 转贴现卖出
       '' AS CUST_NAM_S, --23 客户名称_S
       '' AS PLEDGE_CUST_NAM_S, --24质押客户名称_S
       CASE
         WHEN A.ECIF_CUST_ID IN ('8935000095', '8935000132', '8935000149') --政策性银行：8935000095国家开发银行，8935000132中国进出口银行，8935000149中国农业发展银行
          THEN
          'Y'
         ELSE
          'N'
       END AS POLICY_BANK_FLAG --25是否政策性银行标识
        FROM (select A.CONTRACT_NUM,
                     -- A.CURR_CD,
                     A.ORG_NUM,
                     A.ITEM_CD,
                     NVL(T1.ECIF_CUST_ID, T2.CUST_ID) ECIF_CUST_ID,
                     NVL(T1.TYSHXYDM, T2.TYSHXYDM) TYSHXYDM,
                     NVL(T1.FINA_ORG_NAME, T2.FINA_ORG_NAME) FINA_ORG_NAME,
                     NVL(T1.LEGAL_TYSHXYDM, T2.LEGAL_TYSHXYDM) LEGAL_TYSHXYDM,
                     SUM(A.ACCT_AMOUNT) AMOUNT
                from SMTMODS_L_TRAN_FUND_FX a --资金交易信息表（流水）
                LEFT JOIN (select *
                            from (SELECT A.*,
                                         ROW_NUMBER() OVER(PARTITION BY A.ecif_cust_id ORDER BY A.ecif_cust_id) RN
                                    FROM SMTMODS_L_CUST_BILL_TY A
                                   WHERE A.DATA_DATE = I_DATADATE
                                     AND (a.LEGAL_TYSHXYDM IS NOT NULL OR A.LEGAL_FLAG ='Y'))
                           WHERE RN = '1') T1
                  ON A.CUST_ID = T1.ECIF_CUST_ID
                LEFT JOIN (SELECT *
                            FROM (SELECT ROW_NUMBER() OVER(PARTITION BY CUST_ID ORDER BY CUST_ID) RN,
                                         T.*
                                    FROM SMTMODS_L_CUST_BILL_TY T
                                   WHERE DATA_DATE = I_DATADATE
                                     AND (T.LEGAL_TYSHXYDM IS NOT NULL OR T.LEGAL_FLAG ='Y'))
                           WHERE RN = 1) T2
                  ON A.CUST_ID = T2.CUST_ID
               where A.tran_dt <= I_DATADATE
                 AND A.tran_dt >=
                    TO_CHAR(ADD_MONTHS(DATE(I_DATADATE), -12),'YYYYMMDD')
                 AND A.maturity_dt > I_DATADATE /*> TO_DATE(I_DATADATE, 'YYYY-MM-DD')*/
                    --  and CONTRACT_NUM = '531324200015020240131000487795'
                    -- and a.org_num = '009804'  --不限制金融市场也可
                 --AND A.DATA_DATE = I_DATADATE
                 AND A.BUSI_TYPE = 'I' --资金交易类型：票据买断式转贴现
                 and TRADE_DIRECT = '0' --交易方向：结清（卖出）
                 AND NVL(T1.LEGAL_TYSHXYDM, T2.LEGAL_TYSHXYDM) <>
                     '9122010170255776XN' -- 卖出的交易对手是吉林银行过滤掉
               GROUP BY A.CONTRACT_NUM,
                        -- A.CURR_CD,
                        A.ORG_NUM,
                        A.ITEM_CD,
                        NVL(T1.ecif_cust_id, T2.CUST_ID),
                        NVL(T1.TYSHXYDM, T2.TYSHXYDM),
                        NVL(T1.FINA_ORG_NAME, T2.FINA_ORG_NAME),
                        NVL(T1.LEGAL_TYSHXYDM, T2.LEGAL_TYSHXYDM)) A -- 资金交易信息表
       INNER JOIN SMTMODS_L_AGRE_BILL_INFO D -- 商业汇票票面信息表
          ON A.CONTRACT_NUM = D.BILL_NUM
         AND DATA_DATE = I_DATADATE
         AND D.BILL_TYPE = '1' --票据类型 --1 银行承兑汇票   2 商业承兑汇票 --G1405只是取银行承兑汇票，G1403取商业承兑汇票
        LEFT JOIN CBRC_TMP_ECIF_L_CUST_BILL_TY T3
          ON A.LEGAL_TYSHXYDM = T3.TYSHXYDM --交易对手法人行
         AND T3.FLAG = '3'
       --  AND T3.FINA_ORG_NAME NOT IN ('白山市浑江区农村信用合作联社')
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = D.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_TMP_ASSET_DEVALUE_PREPARE C --资产减值准备
          ON A.CONTRACT_NUM = C.ACCT_NUM
         AND A.ORG_NUM=C.RECORD_ORG
            -- AND T.GL_ITEM_CODE = C.PRIN_SUBJ_NO
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
                A.ECIF_CUST_ID, --11客户号
                A.TYSHXYDM, --12证件号
                A.FINA_ORG_NAME, --13客户名称
                A.LEGAL_TYSHXYDM, --17法人统一社会信用代码
                T3.FINA_ORG_NAME, --18法人名称
                A.ITEM_CD, --21科目号
                CASE
                  WHEN A.ECIF_CUST_ID IN
                       ('8935000095', '8935000132', '8935000149') --政策性银行：8935000095国家开发银行，8935000132中国进出口银行，8935000149中国农业发展银行
                   THEN
                   'Y'
                  ELSE
                   'N'
                END;
    COMMIT;

    --20240807 ADD BY DJH
      /*填报同业客户，目前为借出业务、投资同业存单的同业客户；
      整表取统一报表平台的同业借出，其中LNN开头是借出，填入同业借款，IO开头的是拆出，填入同业拆借，均为一般风险暴露；
      整表默认为同业单一客户；
      其中：拆放同业（取持有仓位）+交易账簿风险暴露（同业存单投资取中登净价金额） 合计降序排列；
      只取前一百；相同客户需要汇总填报*/

    --==================================================
     ------------------------一般风险暴露
     ------------其中：拆放同业   规则：取持有仓位
     --其中：同业拆借
     --其中：同业借款
    --==================================================

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '拆放同业';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1302拆出资金 与G24一样都放入同业拆借
   INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH
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
      PLEDGE_CUST_NAM_S, --24质押客户名称_S
      POLICY_BANK_FLAG --25是否政策性银行标识
      )
     SELECT 
      T.DATA_DATE, --01数据日期
      T.ORG_NUM, --02机构号
      T.CURR_CD, --03币种
      T.BOOK_TYP, --04账户种类
      T.ACCT_TYP, --05业务产品编号
      T.ACCT_STATE_DES, --06账户状态说明
      '' AS COLL_SUBJECT_TYPE, --07业务类别
      T.BALANCE * TT.CCY_RATE AS BALANCE, --08本金,
      NVL(C.PRIN_FINAL_RESLT, 0) AS PRIN_FINAL_RESLT, --09减值 --交易性金融资产不算减值(不计入总账) 会计分类：1、交易类 2、可供出售类 3、持有至到期 4、贷款及应收款
      T.BALANCE * TT.CCY_RATE - NVL(C.PRIN_FINAL_RESLT, 0) AS PRIN_MINUS, --10本金与减值差值--交易性金融资产不算减值(不计入总账) 会计分类：1、交易类 2、可供出售类 3、持有至到期 4、贷款及应收款
      T3.CUST_ID AS CUST_ID, --11同业借款客户号
      T3.ID_NO AS ID_NO, --12同业借款证件号
      T3.CUST_NAM AS CUST_NAM, --13同业借款客户名称
      '' AS PLEDGE_CUST_ID, --14质押客户号
      '' AS PLEDGE_ID_NO, --15质押证件号
      '' AS PLEDGE_CUST_NAM, --16质押客户名称
      '' AS LEGAL_ID_NO, --17法人统一社会信用代码
      '' AS LEGAL_CUST_NAM, --18法人名称
      '' AS ISSU_ORG, --19发行主体类型
      '' AS STOCK_PRO_TYPE, --20产品分类
      T.GL_ITEM_CODE, --21科目号
      '7' AS FLAG, --22业务标识 同业债券
      '' AS CUST_NAM_S, --23 同业债券债券发行人客户名称 同（13同业债券债券发行人客户名称）
      '' AS PLEDGE_CUST_NAM_S, --24质押客户名称_S
      CASE
        WHEN T3.CUST_ID IN
             ('8935000095', '8935000132', '8935000149') --政策性银行：8935000095国家开发银行，8935000132中国进出口银行，8935000149中国农业发展银行
         THEN
         'Y'
        ELSE
         'N'
      END AS POLICY_BANK_FLAG
       FROM SMTMODS_L_ACCT_FUND_MMFUND T
       LEFT JOIN SMTMODS_L_CUST_C T3
         ON T.CUST_ID = T3.CUST_ID
        AND T3.DATA_DATE = I_DATADATE
       LEFT JOIN SMTMODS_L_PUBL_RATE TT
         ON TT.CCY_DATE = I_DATADATE
        AND TT.BASIC_CCY = T.CURR_CD
        AND TT.FORWARD_CCY = 'CNY'
       LEFT JOIN CBRC_TMP_ASSET_DEVALUE_PREPARE C --资产减值准备
         ON C.ACCT_NUM = T.ACCT_NUM
        AND T.GL_ITEM_CODE = C.PRIN_SUBJ_NO --投资 帐户分类 1101交易性金融资产 1501持有至到期投资 1503可供出售金融资产（一条对多条）
        AND C.DATA_DATE = I_DATADATE
        AND T.ORG_NUM = C.RECORD_ORG
      WHERE T.DATA_DATE = I_DATADATE
        AND SUBSTR(T.GL_ITEM_CODE,1,4) = '1302'
        AND BALANCE <> 0
        AND T.ORG_NUM IN ('009820','009801');
    COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '同业拆借';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH
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
      PLEDGE_CUST_NAM_S, --24质押客户名称_S
      POLICY_BANK_FLAG --25是否政策性银行标识
      )
     SELECT 
      T.DATA_DATE, --01数据日期
      T.ORG_NUM, --02机构号
      T.CURR_CD, --03币种
      T.BOOK_TYP, --04账户种类
      T.ACCT_TYP, --05业务产品编号
      T.ACCT_STATE_DES, --06账户状态说明
      '' AS COLL_SUBJECT_TYPE, --07业务类别
      T.BALANCE * TT.CCY_RATE AS BALANCE, --08本金,
      NVL(C.PRIN_FINAL_RESLT, 0) AS PRIN_FINAL_RESLT, --09减值 --交易性金融资产不算减值(不计入总账) 会计分类：1、交易类 2、可供出售类 3、持有至到期 4、贷款及应收款
      T.BALANCE * TT.CCY_RATE - NVL(C.PRIN_FINAL_RESLT, 0) AS PRIN_MINUS, --10本金与减值差值--交易性金融资产不算减值(不计入总账) 会计分类：1、交易类 2、可供出售类 3、持有至到期 4、贷款及应收款
      T3.CUST_ID AS CUST_ID, --11同业借款客户号
      T3.ID_NO AS ID_NO, --12同业借款证件号
      T3.CUST_NAM AS CUST_NAM, --13同业借款客户名称
      '' AS PLEDGE_CUST_ID, --14质押客户号
      '' AS PLEDGE_ID_NO, --15质押证件号
      '' AS PLEDGE_CUST_NAM, --16质押客户名称
      '' AS LEGAL_ID_NO, --17法人统一社会信用代码
      '' AS LEGAL_CUST_NAM, --18法人名称
      '' AS ISSU_ORG, --19发行主体类型
      '' AS STOCK_PRO_TYPE, --20产品分类
      T.GL_ITEM_CODE, --21科目号
      '8' AS FLAG, --22业务标识 同业债券
      '' AS CUST_NAM_S, --23 同业债券债券发行人客户名称 同（13同业债券债券发行人客户名称）
      '' AS PLEDGE_CUST_NAM_S, --24质押客户名称_S
      CASE
        WHEN T3.CUST_ID IN
             ('8935000095', '8935000132', '8935000149') --政策性银行：8935000095国家开发银行，8935000132中国进出口银行，8935000149中国农业发展银行
         THEN
         'Y'
        ELSE
         'N'
      END AS POLICY_BANK_FLAG
       FROM SMTMODS_L_ACCT_FUND_MMFUND T
       LEFT JOIN SMTMODS_L_CUST_C T3
         ON T.CUST_ID = T3.CUST_ID
        AND T3.DATA_DATE = I_DATADATE
       LEFT JOIN SMTMODS_L_PUBL_RATE TT
         ON TT.CCY_DATE = I_DATADATE
        AND TT.BASIC_CCY = T.CURR_CD
        AND TT.FORWARD_CCY = 'CNY'
       LEFT JOIN CBRC_TMP_ASSET_DEVALUE_PREPARE C --资产减值准备
         ON C.ACCT_NUM = T.ACCT_NUM
        AND T.GL_ITEM_CODE = C.PRIN_SUBJ_NO --投资 帐户分类 1101交易性金融资产 1501持有至到期投资 1503可供出售金融资产（一条对多条）
        AND C.DATA_DATE = I_DATADATE
        AND T.ORG_NUM = C.RECORD_ORG
      WHERE T.DATA_DATE = I_DATADATE
        AND SUBSTR(T.GL_ITEM_CODE,1,4) = '1302'
        AND BALANCE <> 0
        AND T.ORG_NUM IN ('009820','009801')
        AND (T.ACCT_NUM LIKE 'IO%' OR T.ORG_NUM='009801'); --IO开头的是拆出，填入同业拆借 009801与G24一样都放入同业拆借
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '同业借款';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


   INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH
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
      PLEDGE_CUST_NAM_S, --24质押客户名称_S
      POLICY_BANK_FLAG --25是否政策性银行标识
      )
     SELECT 
      T.DATA_DATE, --01数据日期
      T.ORG_NUM, --02机构号
      T.CURR_CD, --03币种
      T.BOOK_TYP, --04账户种类
      T.ACCT_TYP, --05业务产品编号
      T.ACCT_STATE_DES, --06账户状态说明
      '' AS COLL_SUBJECT_TYPE, --07业务类别
      T.BALANCE * TT.CCY_RATE AS BALANCE, --08本金,
      NVL(C.PRIN_FINAL_RESLT, 0) AS PRIN_FINAL_RESLT, --09减值 --交易性金融资产不算减值(不计入总账) 会计分类：1、交易类 2、可供出售类 3、持有至到期 4、贷款及应收款
      T.BALANCE * TT.CCY_RATE - NVL(C.PRIN_FINAL_RESLT, 0) AS PRIN_MINUS, --10本金与减值差值--交易性金融资产不算减值(不计入总账) 会计分类：1、交易类 2、可供出售类 3、持有至到期 4、贷款及应收款
      T3.CUST_ID AS CUST_ID, --11同业借款客户号
      T3.ID_NO AS ID_NO, --12同业借款证件号
      T3.CUST_NAM AS CUST_NAM, --13同业借款客户名称
      '' AS PLEDGE_CUST_ID, --14质押客户号
      '' AS PLEDGE_ID_NO, --15质押证件号
      '' AS PLEDGE_CUST_NAM, --16质押客户名称
      '' AS LEGAL_ID_NO, --17法人统一社会信用代码
      '' AS LEGAL_CUST_NAM, --18法人名称
      '' AS ISSU_ORG, --19发行主体类型
      '' AS STOCK_PRO_TYPE, --20产品分类
      T.GL_ITEM_CODE, --21科目号
      '9' AS FLAG, --22业务标识 同业债券
      '' AS CUST_NAM_S, --23 同业债券债券发行人客户名称 同（13同业债券债券发行人客户名称）
      '' AS PLEDGE_CUST_NAM_S, --24质押客户名称_S
      CASE
        WHEN T3.CUST_ID IN
             ('8935000095', '8935000132', '8935000149') --政策性银行：8935000095国家开发银行，8935000132中国进出口银行，8935000149中国农业发展银行
         THEN
         'Y'
        ELSE
         'N'
      END AS POLICY_BANK_FLAG
       FROM SMTMODS_L_ACCT_FUND_MMFUND T
       LEFT JOIN SMTMODS_L_CUST_C T3
         ON T.CUST_ID = T3.CUST_ID
        AND T3.DATA_DATE = I_DATADATE
       LEFT JOIN SMTMODS_L_PUBL_RATE TT
         ON TT.CCY_DATE = I_DATADATE
        AND TT.BASIC_CCY = T.CURR_CD
        AND TT.FORWARD_CCY = 'CNY'
       LEFT JOIN CBRC_TMP_ASSET_DEVALUE_PREPARE C --资产减值准备
         ON C.ACCT_NUM = T.ACCT_NUM
        AND T.GL_ITEM_CODE = C.PRIN_SUBJ_NO --投资 帐户分类 1101交易性金融资产 1501持有至到期投资 1503可供出售金融资产（一条对多条）
        AND C.DATA_DATE = I_DATADATE
        AND T.ORG_NUM = C.RECORD_ORG
      WHERE T.DATA_DATE = I_DATADATE
        AND SUBSTR(T.GL_ITEM_CODE,1,4) = '1302'
        AND BALANCE <> 0
        AND T.ORG_NUM ='009820'
        and T.ACCT_NUM LIKE 'LNN%'; --其中LNN开头是借出，填入同业借款
    COMMIT;
 --  SELECT DISTINCT FLAG FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH;
    -- FLAG 标识 1:买入返售(质押式)债券  2：买入返售(质押式)票据 3：同业债券 4：同业存单  5：转帖现买入 6：转帖现卖出


    ---------------------------业务宽表数据排序[降序]---------------------------
    ----风险暴露总和合计：一般风险暴露合计 (买入返售(质押式)+同业债券+同业存单+转帖现) +交易账簿风险暴露+潜在风险暴露


    ----风险暴露总和其中：不可豁免风险暴露 口径：政策性银行风险暴露可豁免,其他同业机构不可以豁免 (打上标识或者区分,最后区分)


    ----风险缓释转出的风险暴露（转入为负数）(根据不同业务写出)  是不是只有质押有此,最后做处理吧


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


    INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH_MIDDLE
      (CUST_NAM,          --01客户名称
       ID_NO,             --02证件号
       BUY_BACK,          --03买入返售(质押式)
       INTERBANK_BOND,    --04同业债券
       POLICY_BANK,       --05政策性金融债
       INTERBANK_RECEIPT, --06同业存单
       TRADE_ACCOUNT,     --07交易账簿风险暴露
       POTENTIAL_RISK,    --08潜在风险暴露
       PRIN_MINUS,        --09风险缓释转出的风险暴露（转入为负数）
       BALANCE,           --10本金
       PRIN_FINAL_RESLT,  --11减值
       SIGN_TYPE,         --12区分不同业务处理方式
       TRANSFER_DISCOUNT, --13转帖现买入
       POLICY_BANK_FLAG,  --14是否政策性银行标识
       INTERBANK_FUNDING, --15拆放同业
       INTERBANK_BORROWING, --16同业拆借
       INTERBANK_LENDING,  --17同业借款
       ORG_NUM)            --18机构号
    --买入返售(质押式)债券,交易对手
      SELECT NVL(T.CUST_NAM, T.CUST_NAM_S) AS CUST_NAM, --客户名称
             T.ID_NO, --客户代码
             0 AS BUY_BACK, --其中：买入返售(质押式)
             0 AS INTERBANK_BOND, --其中：同业债券
             0 AS POLICY_BANK, --其中：政策性金融债
             0 AS INTERBANK_RECEIPT, --其中：同业存单
             0/*SUM(CASE
                   WHEN T.BOOK_TYPE = '1' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    PRIN_MINUS
                   ELSE
                    0
                 END)*/ AS TRADE_ACCOUNT,
             0 AS POTENTIAL_RISK, --潜在风险暴露
             SUM(T.PRIN_MINUS) AS PRIN_MINUS, --风险缓释转出的风险暴露（转入为负数）
             SUM(T.BALANCE) AS BALANCE, --本金
             SUM(T.PRIN_FINAL_RESLT) PRIN_FINAL_RESLT, --减值
             '01' AS SIGN_TYPE,
             0 AS TRANSFER_DISCOUNT, --转帖现买入
             POLICY_BANK_FLAG, --是否政策性银行标识
             0 AS INTERBANK_FUNDING,
             0 AS INTERBANK_BORROWING,
             0 AS INTERBANK_LENDING,
             T.ORG_NUM
        FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH T
       WHERE T.FLAG IN ('1','2')
       GROUP BY T.ID_NO, NVL(T.CUST_NAM, T.CUST_NAM_S), POLICY_BANK_FLAG, T.ORG_NUM
      --买入返售(质押式) 债券 质押部分,质押的发行人  G1405 非银行金融债，商业银行债，政策性银行债，同业存单，二级资本债，次级债等 ,其他在G1403
      UNION ALL
      SELECT NVL(T.PLEDGE_CUST_NAM, T.PLEDGE_CUST_NAM_S) AS CUST_NAM, --客户名称
             T.PLEDGE_ID_NO, --客户代码
             SUM(CASE
                   WHEN T.BOOK_TYPE = '2' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    T.PRIN_MINUS
                   ELSE
                    0
                 END) AS BUY_BACK, --其中：买入返售(质押式)
             0 AS INTERBANK_BOND, --其中：同业债券
             0 AS POLICY_BANK, --其中：政策性金融债
             0 AS INTERBANK_RECEIPT, --其中：同业存单
             SUM(CASE
                   WHEN T.BOOK_TYPE = '1' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    T.PRIN_MINUS
                   ELSE
                    0
                 END) AS TRADE_ACCOUNT,
             0 AS POTENTIAL_RISK, --潜在风险暴露
             -1 * SUM(T.PRIN_MINUS) AS PRIN_MINUS, --风险缓释转出的风险暴露（转入为负数）  质押部分为转入
             SUM(T.BALANCE) AS BALANCE, --本金
             SUM(T.PRIN_FINAL_RESLT) PRIN_FINAL_RESLT, --减值
             '02' AS SIGN_TYPE,
             0 AS TRANSFER_DISCOUNT, --转帖现买入
             POLICY_BANK_FLAG, --是否政策性银行标识
             0 AS INTERBANK_FUNDING,
             0 AS INTERBANK_BORROWING,
             0 AS INTERBANK_LENDING,
             T.ORG_NUM
        FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH T
       WHERE T.FLAG = '1'
         AND ((T.ISSU_ORG = 'D03' AND T.STOCK_PRO_TYPE LIKE 'C%') /*AND A.STOCK_PRO_TYPE NOT IN ('C01', 'C0101')*/ --商业银行债
             OR (T.ISSU_ORG = 'D02' AND T.STOCK_PRO_TYPE LIKE 'C%') /* AND A.STOCK_PRO_TYPE NOT IN ('C01', 'C0101')*/ --政策性银行债
             OR T.STOCK_PRO_TYPE IN ('C01', 'C0101') --次级债、二级资本债
             OR (T.ISSU_ORG NOT IN ('D02', 'D03') AND
             T.STOCK_PRO_TYPE LIKE 'C%') /*AND A.STOCK_PRO_TYPE NOT IN ('C01', 'C0101')*/ --非银行金融债
             OR COLL_SUBJECT_TYPE = '同业存单') --质押券类别为同业存单也取进来
       GROUP BY T.PLEDGE_ID_NO,
                NVL(T.PLEDGE_CUST_NAM, T.PLEDGE_CUST_NAM_S),
                POLICY_BANK_FLAG,
                T.ORG_NUM
      --买入返售(质押式)票据  承兑人/行
      UNION ALL
      SELECT NVL(T.PLEDGE_CUST_NAM, T.PLEDGE_CUST_NAM_S) AS CUST_NAM, --客户名称
             T.PLEDGE_ID_NO, --客户代码
             SUM(CASE
                   WHEN T.BOOK_TYPE = '2' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    T.PRIN_MINUS
                   ELSE
                    0
                 END) AS BUY_BACK, --其中：买入返售(质押式)
             0 AS INTERBANK_BOND, --其中：同业债券
             0 AS POLICY_BANK, --其中：政策性金融债
             0 AS INTERBANK_RECEIPT, --其中：同业存单
             SUM(CASE
                   WHEN T.BOOK_TYPE = '1' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    PRIN_MINUS
                   ELSE
                    0
                 END) AS TRADE_ACCOUNT,
             0 AS POTENTIAL_RISK, --潜在风险暴露
             -1 * SUM(T.PRIN_MINUS) AS PRIN_MINUS, --风险缓释转出的风险暴露（转入为负数）
             SUM(T.BALANCE) AS BALANCE, --本金
             SUM(T.PRIN_FINAL_RESLT) PRIN_FINAL_RESLT, --减值
             '03' AS SIGN_TYPE,
             0 AS TRANSFER_DISCOUNT, --转帖现买入
             POLICY_BANK_FLAG, --是否政策性银行标识
             0 AS INTERBANK_FUNDING,
             0 AS INTERBANK_BORROWING,
             0 AS INTERBANK_LENDING,
             T.ORG_NUM
        FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH T
       WHERE T.FLAG = '2'
       GROUP BY T.PLEDGE_ID_NO, NVL(T.PLEDGE_CUST_NAM, T.PLEDGE_CUST_NAM_S), POLICY_BANK_FLAG, T.ORG_NUM
      --同业债券  债券发行人   其中：政策性金融债
      UNION ALL
      SELECT NVL(T.CUST_NAM, T.CUST_NAM_S) AS CUST_NAM, --客户名称
             T.ID_NO, --客户代码
             0 AS BUY_BACK, --其中：买入返售(质押式)
             SUM(CASE
                   WHEN T.BOOK_TYPE = '2' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    T.PRIN_MINUS
                   ELSE
                    0
                 END) AS INTERBANK_BOND, --其中：同业债券
             SUM(CASE
                   WHEN T.POLICY_BANK_FLAG = 'Y' AND T.BOOK_TYPE = '2' THEN --是否政策性银行标识
                    PRIN_MINUS
                   ELSE
                    0
                 END) AS POLICY_BANK, --其中：政策性金融债
             0 AS INTERBANK_RECEIPT, --其中：同业存单
             SUM(CASE
                   WHEN T.BOOK_TYPE = '1' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    PRIN_MINUS
                   ELSE
                    0
                 END) AS TRADE_ACCOUNT,
             0 AS POTENTIAL_RISK, --潜在风险暴露
             SUM(T.PRIN_MINUS) AS PRIN_MINUS, --风险缓释转出的风险暴露（转入为负数）
             SUM(T.BALANCE) AS BALANCE, --本金
             SUM(T.PRIN_FINAL_RESLT) PRIN_FINAL_RESLT, --减值
             '04' AS SIGN_TYPE,
             0 AS TRANSFER_DISCOUNT, --转帖现买入
             POLICY_BANK_FLAG, --是否政策性银行标识
             0 AS INTERBANK_FUNDING,
             0 AS INTERBANK_BORROWING,
             0 AS INTERBANK_LENDING,
             T.ORG_NUM
        FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH T
       WHERE T.FLAG = '3'
       GROUP BY T.ID_NO, NVL(T.CUST_NAM, T.CUST_NAM_S), POLICY_BANK_FLAG, T.ORG_NUM
      --同业存单 存单发行人
      UNION ALL
      SELECT NVL(T.CUST_NAM, T.CUST_NAM_S) AS CUST_NAM, --客户名称
             T.ID_NO, --客户代码
             0 AS BUY_BACK, --其中：买入返售(质押式)
             0 AS INTERBANK_BOND, --其中：同业债券
             0 AS POLICY_BANK, --其中：政策性金融债
             SUM(CASE
                   WHEN T.BOOK_TYPE = '2' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    T.PRIN_MINUS
                   ELSE
                    0
                 END) AS INTERBANK_RECEIPT, --其中：同业存单
             SUM(CASE
                   WHEN T.BOOK_TYPE = '1' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    PRIN_MINUS
                   ELSE
                    0
                 END) AS TRADE_ACCOUNT,
             0 AS POTENTIAL_RISK, --潜在风险暴露
             SUM(T.PRIN_MINUS) AS PRIN_MINUS, --风险缓释转出的风险暴露（转入为负数）
             SUM(T.BALANCE) AS BALANCE, --本金
             SUM(T.PRIN_FINAL_RESLT) PRIN_FINAL_RESLT, --减值
             '05' AS SIGN_TYPE,
             0 AS TRANSFER_DISCOUNT, --转帖现买入
             POLICY_BANK_FLAG, --是否政策性银行标识
             0 AS INTERBANK_FUNDING,
             0 AS INTERBANK_BORROWING,
             0 AS INTERBANK_LENDING,
             T.ORG_NUM
        FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH T
       WHERE T.FLAG = '4'
       GROUP BY T.ID_NO, NVL(T.CUST_NAM, T.CUST_NAM_S), POLICY_BANK_FLAG, T.ORG_NUM
      --转帖现买入   承兑人/行
      UNION ALL
      SELECT NVL(T.CUST_NAM, T.CUST_NAM_S) AS CUST_NAM, --客户名称
             T.ID_NO, --客户代码
             0 AS BUY_BACK, --其中：买入返售(质押式)
             0 AS INTERBANK_BOND, --其中：同业债券
             0 AS POLICY_BANK, --其中：政策性金融债
             0 AS INTERBANK_RECEIPT, --其中：同业存单
             SUM(CASE
                   WHEN T.BOOK_TYPE = '1' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    PRIN_MINUS
                   ELSE
                    0
                 END) AS TRADE_ACCOUNT,
             0 AS POTENTIAL_RISK, --潜在风险暴露
             SUM(T.PRIN_MINUS) AS PRIN_MINUS, --风险缓释转出的风险暴露（转入为负数）
             SUM(T.BALANCE) AS BALANCE, --本金
             SUM(T.PRIN_FINAL_RESLT) PRIN_FINAL_RESLT, --减值
             '06' AS SIGN_TYPE,
             SUM(CASE
                   WHEN T.BOOK_TYPE = '2' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    T.PRIN_MINUS
                   ELSE
                    0
                 END) AS TRANSFER_DISCOUNT, --转帖现买入
             POLICY_BANK_FLAG, --是否政策性银行标识
             0 AS INTERBANK_FUNDING,
             0 AS INTERBANK_BORROWING,
             0 AS INTERBANK_LENDING,
             T.ORG_NUM
        FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH T
       WHERE T.FLAG = '5'
       GROUP BY T.ID_NO, NVL(T.CUST_NAM, T.CUST_NAM_S), POLICY_BANK_FLAG, T.ORG_NUM
      --转帖现卖出   承兑人/行
      UNION ALL
      SELECT T.LEGAL_CUST_NAM AS CUST_NAM, --客户名称
             T.LEGAL_ID_NO, --客户代码
             0 AS BUY_BACK, --其中：买入返售(质押式)
             0 AS INTERBANK_BOND, --其中：同业债券
             0 AS POLICY_BANK, --其中：政策性金融债
             0 AS INTERBANK_RECEIPT, --其中：同业存单
             SUM(CASE
                   WHEN T.BOOK_TYPE = '1' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    PRIN_MINUS
                   ELSE
                    0
                 END) AS TRADE_ACCOUNT,
             SUM(CASE
                   WHEN T.BOOK_TYPE = '2' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    T.PRIN_MINUS
                   ELSE
                    0
                 END) AS POTENTIAL_RISK, --潜在风险暴露【转帖现卖出】
             SUM(T.PRIN_MINUS) AS PRIN_MINUS, --风险缓释转出的风险暴露（转入为负数）
             SUM(T.BALANCE) AS BALANCE, --本金
             SUM(T.PRIN_FINAL_RESLT) PRIN_FINAL_RESLT, --减值
             '07' AS SIGN_TYPE,
             0 AS TRANSFER_DISCOUNT, --转帖现买入
             POLICY_BANK_FLAG, --是否政策性银行标识
             0 AS INTERBANK_FUNDING,
             0 AS INTERBANK_BORROWING,
             0 AS INTERBANK_LENDING,
             T.ORG_NUM
        FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH T
       WHERE T.FLAG = '6'
       GROUP BY T.LEGAL_ID_NO, T.LEGAL_CUST_NAM, POLICY_BANK_FLAG, T.ORG_NUM
      UNION ALL
     --同业金融部
      SELECT T.CUST_NAM AS CUST_NAM, --客户名称
             T.ID_NO, --客户代码
             0 AS BUY_BACK, --其中：买入返售(质押式)
             0 AS INTERBANK_BOND, --其中：同业债券
             0 AS POLICY_BANK, --其中：政策性金融债
             0 AS INTERBANK_RECEIPT, --其中：同业存单
             SUM(CASE
                   WHEN T.BOOK_TYPE = '1' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    PRIN_MINUS
                   ELSE
                    0
                 END) AS TRADE_ACCOUNT,
             0 AS POTENTIAL_RISK, --潜在风险暴露
             SUM(T.PRIN_MINUS) AS PRIN_MINUS, --风险缓释转出的风险暴露（转入为负数）
             SUM(T.BALANCE) AS BALANCE, --本金
             SUM(T.PRIN_FINAL_RESLT) PRIN_FINAL_RESLT, --减值
             '08' AS SIGN_TYPE,
             0 AS TRANSFER_DISCOUNT, --转帖现买入
             POLICY_BANK_FLAG, --是否政策性银行标识
             SUM(CASE
                   WHEN T.FLAG ='7'  AND T.BOOK_TYPE = '2' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    T.PRIN_MINUS
                   ELSE
                    0
                 END) INTERBANK_FUNDING,  --拆放同业
             SUM(CASE
                   WHEN  T.FLAG ='8' AND T.BOOK_TYPE = '2' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    T.PRIN_MINUS
                   ELSE
                    0
                 END) INTERBANK_BORROWING, --同业拆借
             SUM(CASE
                   WHEN T.FLAG ='9'  AND T.BOOK_TYPE = '2' THEN --交易账簿风险暴露 1交易账户 2 银行账户
                    T.PRIN_MINUS
                   ELSE
                    0
                 END) INTERBANK_LENDING ,  --同业借款
             T.ORG_NUM
        FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH T
       WHERE T.FLAG IN ('7','8','9')
       GROUP BY T.CUST_NAM,T.ID_NO,POLICY_BANK_FLAG, T.ORG_NUM;
    COMMIT;

    --排序  空的数据为，转贴现买入： 承兑行总行名称：招商银行股份有限公司  PAY_CUSID承兑人（行）为空，一系列票据对应招商银行股份有限公司，名赫沟通暂时空，转贴现在银行授信，但是不开户，没有信息
    ----风险暴露总和合计：一般风险暴露合计 (买入返售(质押式)+同业债券+同业存单+转帖现) +交易账簿风险暴露+潜在风险暴露


    --==================================================
    --业务数据排序结果表处理      【所有结果进行排序】
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '业务数据排序结果表处理';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH_RESULT
      (SEQ_NO, --序号
       CUST_NAM, --01客户名称
       ID_NO, --02证件号
       RISK_TOTAL, --03风险暴露总和合计
       HAVE_RISK_SUBTOTAL, --04其中：不可豁免风险暴露
       GENERAL_RISK_TOTAL, --05一般风险暴露合计
       BUY_BACK, --06买入返售(质押式)
       INTERBANK_BOND, --07同业债券
       POLICY_BANK, --08政策性金融债
       INTERBANK_RECEIPT, --09同业存单
       TRADE_ACCOUNT, --10交易账簿风险暴露
       POTENTIAL_RISK, --11潜在风险暴露
       PRIN_MINUS, --12风险缓释转出的风险暴露（转入为负数）
       INTERBANK_FUNDING, --15拆放同业
       INTERBANK_BORROWING, --16同业拆借
       INTERBANK_LENDING, --17同业借款
       ORG_NUM --18机构
       )
      SELECT ROW_NUMBER() OVER(PARTITION BY ORG_NUM ORDER BY RISK_TOTAL DESC) AS SEQ_NO,
             CUST_NAM,
             ID_NO,
             RISK_TOTAL,
             HAVE_RISK_SUBTOTAL,
             GENERAL_RISK_TOTAL,
             BUY_BACK,
             INTERBANK_BOND,
             POLICY_BANK,
             INTERBANK_RECEIPT,
             TRADE_ACCOUNT,
             POTENTIAL_RISK,
             PRIN_MINUS,
             INTERBANK_FUNDING,
             INTERBANK_BORROWING,
             INTERBANK_LENDING,
             ORG_NUM
        FROM (SELECT CUST_NAM,
                     ID_NO,
                     ORG_NUM,
                     SUM(NVL(BUY_BACK, 0) + NVL(INTERBANK_BOND, 0) +
                         NVL(INTERBANK_RECEIPT, 0) +
                         NVL(TRANSFER_DISCOUNT, 0) + NVL(TRADE_ACCOUNT, 0) +
                         NVL(POTENTIAL_RISK, 0) + NVL(INTERBANK_FUNDING, 0)) RISK_TOTAL, --风险暴露总和合计
                     SUM(CASE
                           WHEN POLICY_BANK_FLAG = 'Y' THEN --政策性银行都可以豁免
                            0
                           ELSE
                            NVL(BUY_BACK, 0) + NVL(INTERBANK_BOND, 0) +
                            NVL(INTERBANK_RECEIPT, 0) + NVL(TRANSFER_DISCOUNT, 0) +
                            NVL(TRADE_ACCOUNT, 0) + NVL(POTENTIAL_RISK, 0) +
                            NVL(INTERBANK_FUNDING, 0)
                         END) HAVE_RISK_SUBTOTAL, --其中：不可豁免风险暴露
                     SUM(NVL(BUY_BACK, 0) + NVL(INTERBANK_BOND, 0) +
                         NVL(INTERBANK_RECEIPT, 0) +
                         NVL(TRANSFER_DISCOUNT, 0) + NVL(INTERBANK_FUNDING, 0)) GENERAL_RISK_TOTAL, -- 一般风险暴露合计
                     SUM(NVL(BUY_BACK, 0)) BUY_BACK, --买入返售(质押式)
                     SUM(NVL(INTERBANK_BOND, 0)) INTERBANK_BOND, --同业债券
                     SUM(NVL(POLICY_BANK, 0)) POLICY_BANK, --政策性金融债
                     SUM(NVL(INTERBANK_RECEIPT, 0)) INTERBANK_RECEIPT, --同业存单
                     SUM(NVL(TRADE_ACCOUNT, 0)) TRADE_ACCOUNT, --交易账簿风险暴露
                     SUM(NVL(POTENTIAL_RISK, 0)) POTENTIAL_RISK, --潜在风险暴露
                     SUM(CASE
                           WHEN SIGN_TYPE IN ('01', '02', '03') THEN
                            NVL(PRIN_MINUS, 0)
                           ELSE
                            0
                         END) PRIN_MINUS, --风险缓释转出的风险暴露（转入为负数）
                     SUM(NVL(INTERBANK_FUNDING, 0)) INTERBANK_FUNDING, --拆放同业
                     SUM(NVL(INTERBANK_BORROWING, 0)) INTERBANK_BORROWING, --同业拆借
                     SUM(NVL(INTERBANK_LENDING, 0))  INTERBANK_LENDING --同业借款
                FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH_MIDDLE
              -- WHERE CUST_NAM = '中国进出口银行'
               GROUP BY CUST_NAM, ID_NO, ORG_NUM) T;
    COMMIT;




    --==================================================
    --G1405数据机构处理最终表   【前100家，不足100，有多少取多少】
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1405数据机构处理最终表前100家';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    INSERT INTO CBRC_BUSINESS_TABLE_TYDYKH_RESULT
      (ORG_CODE,
       SEQ_NO,
       CUST_NAM,
       ID_NO,
       RISK_TOTAL,
       HAVE_RISK_SUBTOTAL,
       GENERAL_RISK_TOTAL,
       BUY_BACK,
       INTERBANK_BOND,
       POLICY_BANK,
       INTERBANK_RECEIPT,
       TRADE_ACCOUNT,
       POTENTIAL_RISK,
       PRIN_MINUS,
       DATA_DATE,
       CUST_TYPE,
       REPORT_ITEM_ID,
       INTERBANK_FUNDING,
       INTERBANK_BORROWING,
       INTERBANK_LENDING)
      SELECT A.ORG_NUM AS ORG_CODE,
             A.SEQ_NO,
             CUST_NAM,
             ID_NO,
             RISK_TOTAL,
             HAVE_RISK_SUBTOTAL,
             GENERAL_RISK_TOTAL,
             BUY_BACK,
             INTERBANK_BOND,
             POLICY_BANK,
             INTERBANK_RECEIPT,
             TRADE_ACCOUNT,
             POTENTIAL_RISK,
             PRIN_MINUS,
             I_DATADATE,
             '同业单一客户' AS CUST_TYPE,
             B.REPORT_ITEM_ID,
             INTERBANK_FUNDING,
             INTERBANK_BORROWING,
             INTERBANK_LENDING
        FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH_RESULT A
        LEFT JOIN CBRC_G1405_CONFIG_RESULT_MAPPING B
          ON A.SEQ_NO = B.SEQ_NO
         AND B.SEQ_NO NOT LIKE 'II_%'
       WHERE A.SEQ_NO <= 100; --金融市场、同业金融小于100数据
    /*  INNER JOIN CBRC_DATACORE.TMP_L_ORG_FLAT B
                  ON B.SUB_ORG_CODE = '009804';   --按照机构和序号排序*/
    -- ORDER BY B.ORG_CODE, SEQ_NO


    COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1405数据机构处理最大单家表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --==================================================
    --附注：最大单家及全部同业融资业务情况（扣除结算性同业存款和风险权重为零资产后）  【最大单家】
    --==================================================
     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币1111买入返售业务排序
    INSERT INTO CBRC_BUSINESS_TABLE_TYDYKH_RESULT_FZ
      (ORG_CODE,
       SEQ_NO,
       CUST_NAM,
       ID_NO,
       CHFTY,
       TYCJ,
       TYJK,
       STFTYDF,
       CFTY,
       MRFS,
       QTTYRC,
       JSXTYCK,
       FXQZ,
       DATA_DATE,
       REPORT_ITEM_ID)
      select ORG_CODE,
             SEQ_NO,
             CUST_NAM,
             ID_NO,
             CHFTY,
             TYCJ,
             TYJK,
             STFTYDF,
             CFTY,
             MRFS,
             QTTYRC,
             JSXTYCK,
             FXQZ,
             DATA_DATE,
             REPORT_ITEM_ID
        from (SELECT ORG_CODE,
                     ROW_NUMBER() OVER(PARTITION BY ORG_CODE ORDER BY SUM(CHFTY + TYCJ + TYJK + STFTYDF + CFTY + MRFS + QTTYRC + JSXTYCK + FXQZ) DESC) AS SEQ_NO,
                     CUST_NAM,
                     ID_NO,
                     CHFTY,
                     TYCJ,
                     TYJK,
                     STFTYDF,
                     CFTY,
                     MRFS,
                     QTTYRC,
                     JSXTYCK,
                     FXQZ,
                     DATA_DATE,
                     REPORT_ITEM_ID
                FROM (SELECT ORG_NUM AS ORG_CODE,
                             'II_' || A.SEQ_NO AS SEQ_NO,
                             A.CUST_NAM AS CUST_NAM,
                             A.ID_NO AS ID_NO,
                             0 AS CHFTY,
                             0 AS TYCJ,
                             0 AS TYJK,
                             0 AS STFTYDF,
                             0 AS CFTY,
                             NVL(A.BALANCE, 0) AS MRFS,
                             0 AS QTTYRC,
                             0 AS JSXTYCK,
                             0 AS FXQZ,
                             I_DATADATE AS DATA_DATE,
                             B.REPORT_ITEM_ID AS REPORT_ITEM_ID
                        FROM (SELECT T.ID_NO AS ID_NO,
                                     T.CUST_NAM AS CUST_NAM,
                                     SUM(T.BALANCE) AS BALANCE,
                                     ORG_NUM,
                                     ROW_NUMBER() OVER(PARTITION BY ORG_NUM ORDER BY SUM(T.BALANCE) DESC) AS SEQ_NO
                                FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH T
                               WHERE T.DATA_DATE = I_DATADATE
                                 AND T.FLAG IN ('1', '2')
                               GROUP BY T.ID_NO, T.CUST_NAM, ORG_NUM) A
                        LEFT JOIN CBRC_G1405_CONFIG_RESULT_MAPPING B
                          ON 'II_' || A.SEQ_NO = B.SEQ_NO
                       WHERE A.SEQ_NO = 1 --买入返售第一名
                      UNION ALL
                      -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币1302拆放同业排序
                      SELECT A.ORG_CODE,
                             'II_' || A.SEQ_NO AS SEQ_NO,
                             A.CUST_NAM AS CUST_NAM,
                             A.ID_NO AS ID_NO,
                             NVL(A.INTERBANK_FUNDING, 0) AS CHFTY, --拆放同业
                             NVL(A.INTERBANK_BORROWING, 0) AS TYCJ, --其中：同业拆借
                             NVL(A.INTERBANK_LENDING, 0) AS TYJK, --其中：同业借款
                             0 AS STFTYDF,
                             0 AS CFTY,
                             0 AS MRFS,
                             0 AS QTTYRC,
                             0 AS JSXTYCK,
                             0 AS FXQZ,
                             I_DATADATE AS DATA_DATE,
                             B.REPORT_ITEM_ID AS REPORT_ITEM_ID
                        FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT A
                        LEFT JOIN CBRC_G1405_CONFIG_RESULT_MAPPING B
                          ON 'II_' || A.SEQ_NO = B.SEQ_NO --拆放同业第一名
                       WHERE A.SEQ_NO = 1) A1
               GROUP BY ORG_CODE,
                        CUST_NAM,
                        ID_NO,
                        CHFTY,
                        TYCJ,
                        TYJK,
                        STFTYDF,
                        CFTY,
                        MRFS,
                        QTTYRC,
                        JSXTYCK,
                        FXQZ,
                        DATA_DATE,
                        REPORT_ITEM_ID) A2
       where A2.SEQ_NO = 1;
    COMMIT;

 --==================================================
    --  【前100家/最大单家更新进配置表】
    --==================================================


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1405数据机构处理前100家/最大单家更新进配置表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    DECLARE
         V_SQL    VARCHAR2(10000);--金融市场
         V_SQL_V  VARCHAR2(10000);--金融市场
         V_SQL1   VARCHAR2(10000); --附注
         V_SQL_V1 VARCHAR2(10000); --附注
         V_SQL2   VARCHAR2(10000); --同业金融
         V_SQL_V2 VARCHAR2(10000); --同业金融
         V_SQL3   VARCHAR2(10000); --附注
         V_SQL_V3 VARCHAR2(10000); --附注
         V_SQL4   VARCHAR2(10000); --总行清算中心(国际业务部)
         V_SQL_V4 VARCHAR2(10000); --总行清算中心(国际业务部)
         V_SQL5   VARCHAR2(10000); --附注
         V_SQL_V5 VARCHAR2(10000); --附注
       

       BEGIN
    --------------金融市场部
         FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1405_CONFIG_TMP F
                    WHERE F.REPORT_ITEM_NAME NOT IN
                          ('CUST_TYPE', 'CUST_NAM', 'ID_NO')) LOOP --补充数值型字段
           V_SQL := 'UPDATE CBRC_G1405_CONFIG_TMP B SET B.ITEM_VAL = (SELECT ' ||
                    NVL(I.REPORT_ITEM_NAME, 0) ||
                    ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                    I_DATADATE || '''' ||  ' AND ORG_CODE = ' || '''' ||
                    '009804' || '''' ||  ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                    I.REPORT_ITEM_NAME || '''';
           --DBMS_OUTPUT.PUT_LINE(V_SQL);
           EXECUTE IMMEDIATE V_SQL;
          COMMIT;
         END LOOP;


         FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1405_CONFIG_TMP F
                    WHERE F.REPORT_ITEM_NAME IN
                          ('CUST_TYPE', 'CUST_NAM', 'ID_NO')) LOOP  --补充字符型字段
           V_SQL_V := 'UPDATE CBRC_G1405_CONFIG_TMP B SET B.ITEM_VAL_V = (SELECT ' ||
                      NVL(I.REPORT_ITEM_NAME, 0) ||
                      ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                      I_DATADATE || '''' || ' AND ORG_CODE = ' || '''' ||
                      '009804' || '''' ||  ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                      I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL);
           EXECUTE IMMEDIATE V_SQL_V;
          COMMIT;
         END LOOP;


       --------------金融市场部  附注
         FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1405_CONFIG_TMP_FZ F
                    WHERE F.REPORT_ITEM_NAME NOT IN
                          ('CUST_NAM', 'ID_NO')) LOOP --补充数值型字段
           V_SQL1 := 'UPDATE CBRC_G1405_CONFIG_TMP_FZ B SET B.ITEM_VAL = (SELECT ' ||
                    NVL(I.REPORT_ITEM_NAME, 0) ||
                    ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_FZ
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                    I_DATADATE || '''' || ' AND ORG_CODE = ' || '''' ||
                    '009804' || '''' ||  ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                    I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL1);
           EXECUTE IMMEDIATE V_SQL1;
         END LOOP;


         FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1405_CONFIG_TMP_FZ F
                    WHERE F.REPORT_ITEM_NAME IN
                          ('CUST_NAM', 'ID_NO')) LOOP  --补充字符型字段
           V_SQL_V1 := 'UPDATE CBRC_G1405_CONFIG_TMP_FZ B SET B.ITEM_VAL_V = (SELECT ' ||
                      NVL(I.REPORT_ITEM_NAME, 0) ||
                      ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_FZ
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                      I_DATADATE || '''' || ' AND ORG_CODE = ' || '''' ||
                      '009804' || '''' ||  ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                      I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL1);
           EXECUTE IMMEDIATE V_SQL_V1;
          COMMIT;
         END LOOP;


       --------------同业金融部
          FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1405_CONFIG_TMP_TY F
                    WHERE F.REPORT_ITEM_NAME NOT IN
                          ('CUST_TYPE', 'CUST_NAM', 'ID_NO')) LOOP --补充数值型字段
           V_SQL2 := 'UPDATE CBRC_G1405_CONFIG_TMP_TY B SET B.ITEM_VAL = (SELECT ' ||
                    NVL(I.REPORT_ITEM_NAME, 0) ||
                    ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                    I_DATADATE || '''' ||  ' AND ORG_CODE = ' || '''' ||
                    '009820' || '''' ||  ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                    I.REPORT_ITEM_NAME || '''';
           --DBMS_OUTPUT.PUT_LINE(V_SQL);
           EXECUTE IMMEDIATE V_SQL2;
          COMMIT;
         END LOOP;


       FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1405_CONFIG_TMP_TY F
                    WHERE F.REPORT_ITEM_NAME IN
                          ('CUST_TYPE', 'CUST_NAM', 'ID_NO')) LOOP  --补充字符型字段
           V_SQL_V2 := 'UPDATE CBRC_G1405_CONFIG_TMP_TY B SET B.ITEM_VAL_V = (SELECT ' ||
                      NVL(I.REPORT_ITEM_NAME, 0) ||
                      ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                      I_DATADATE || '''' || ' AND ORG_CODE = ' || '''' ||
                      '009820' || '''' ||  ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                      I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL);
           EXECUTE IMMEDIATE V_SQL_V2;
          COMMIT;
         END LOOP;


          --------------同业金融部  附注
         FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1405_CONFIG_TMP_TY_FZ F
                    WHERE F.REPORT_ITEM_NAME NOT IN
                          ('CUST_NAM', 'ID_NO')) LOOP --补充数值型字段
           V_SQL3 := 'UPDATE CBRC_G1405_CONFIG_TMP_TY_FZ B SET B.ITEM_VAL = (SELECT ' ||
                    NVL(I.REPORT_ITEM_NAME, 0) ||
                    ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_FZ
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                    I_DATADATE || '''' || ' AND ORG_CODE = ' || '''' ||
                    '009820' || '''' ||  ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                    I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL1);
           EXECUTE IMMEDIATE V_SQL3;
         END LOOP;


         FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1405_CONFIG_TMP_TY_FZ F
                    WHERE F.REPORT_ITEM_NAME IN
                          ('CUST_NAM', 'ID_NO')) LOOP  --补充字符型字段
           V_SQL_V3 := 'UPDATE CBRC_G1405_CONFIG_TMP_TY_FZ B SET B.ITEM_VAL_V = (SELECT ' ||
                      NVL(I.REPORT_ITEM_NAME, 0) ||
                      ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_FZ
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                      I_DATADATE || '''' || ' AND ORG_CODE = ' || '''' ||
                      '009820' || '''' ||  ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                      I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL1);
           EXECUTE IMMEDIATE V_SQL_V3;
          COMMIT;
         END LOOP;
         
        -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801总行清算中心业务
        
        --------------总行清算中心
        
         FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1405_CONFIG_TMP_QS F
                    WHERE F.REPORT_ITEM_NAME NOT IN
                          ('CUST_TYPE', 'CUST_NAM', 'ID_NO')) LOOP --补充数值型字段
           V_SQL4 := 'UPDATE CBRC_G1405_CONFIG_TMP_QS B SET B.ITEM_VAL = (SELECT ' ||
                    NVL(I.REPORT_ITEM_NAME, 0) ||
                    ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                    I_DATADATE || '''' ||  ' AND ORG_CODE = ' || '''' ||
                    '009801' || '''' ||  ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                    I.REPORT_ITEM_NAME || '''';
           --DBMS_OUTPUT.PUT_LINE(V_SQL);
           EXECUTE IMMEDIATE V_SQL4;
          COMMIT;
         END LOOP;


       FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1405_CONFIG_TMP_QS F
                    WHERE F.REPORT_ITEM_NAME IN
                          ('CUST_TYPE', 'CUST_NAM', 'ID_NO')) LOOP  --补充字符型字段
           V_SQL_V4 := 'UPDATE CBRC_G1405_CONFIG_TMP_QS B SET B.ITEM_VAL_V = (SELECT ' ||
                      NVL(I.REPORT_ITEM_NAME, 0) ||
                      ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                      I_DATADATE || '''' || ' AND ORG_CODE = ' || '''' ||
                      '009801' || '''' ||  ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                      I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL);
           EXECUTE IMMEDIATE V_SQL_V4;
          COMMIT;
         END LOOP;
        --------------总行清算中心  附注
        
        FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1405_CONFIG_TMP_QS_FZ F
                    WHERE F.REPORT_ITEM_NAME NOT IN
                          ('CUST_NAM', 'ID_NO')) LOOP --补充数值型字段
           V_SQL5 := 'UPDATE CBRC_G1405_CONFIG_TMP_QS_FZ B SET B.ITEM_VAL = (SELECT ' ||
                    NVL(I.REPORT_ITEM_NAME, 0) ||
                    ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_FZ
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                    I_DATADATE || '''' || ' AND ORG_CODE = ' || '''' ||
                    '009801' || '''' ||  ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                    I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL1);
           EXECUTE IMMEDIATE V_SQL5;
         END LOOP;


         FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1405_CONFIG_TMP_QS_FZ F
                    WHERE F.REPORT_ITEM_NAME IN
                          ('CUST_NAM', 'ID_NO')) LOOP  --补充字符型字段
           V_SQL_V5 := 'UPDATE CBRC_G1405_CONFIG_TMP_QS_FZ B SET B.ITEM_VAL_V = (SELECT ' ||
                      NVL(I.REPORT_ITEM_NAME, 0) ||
                      ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_FZ
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                      I_DATADATE || '''' || ' AND ORG_CODE = ' || '''' ||
                      '009801' || '''' ||  ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                      I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL1);
           EXECUTE IMMEDIATE V_SQL_V5;
          COMMIT;
         END LOOP;

       END;


    --==================================================
    --  【前100家/最大单家更新进CBRC_A_REPT_ITEM_VAL】
    --==================================================

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1405数据机构处理前100家/最大单家进CBRC_A_REPT_ITEM_VAL';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801总行清算中心业务
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       ITEM_VAL,
       ITEM_VAL_V,
       FLAG,
       IS_TOTAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009804',
             'CBRC' AS SYS_NAM,
             'G1405' AS REP_NUM,
             ITEM_NUM AS ITEM_NUM,
             ITEM_VAL AS ITEM_VAL,
             ITEM_VAL_V AS ITEM_VAL_V,
             '2' AS FLAG,
             'Y' AS IS_TOTAL
        FROM CBRC_G1405_CONFIG_TMP
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
             '009804',
             'CBRC' AS SYS_NAM,
             'G1405' AS REP_NUM,
             ITEM_NUM AS ITEM_NUM,
             ITEM_VAL AS ITEM_VAL,
             ITEM_VAL_V AS ITEM_VAL_V,
             '2' AS FLAG,
             'Y' AS IS_TOTAL
        FROM CBRC_G1405_CONFIG_TMP_FZ
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
             '009820',
             'CBRC' AS SYS_NAM,
             'G1405' AS REP_NUM,
             ITEM_NUM AS ITEM_NUM,
             ITEM_VAL AS ITEM_VAL,
             ITEM_VAL_V AS ITEM_VAL_V,
             '2' AS FLAG,
             'Y' AS IS_TOTAL
        FROM CBRC_G1405_CONFIG_TMP_TY
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
             '009820',
             'CBRC' AS SYS_NAM,
             'G1405' AS REP_NUM,
             ITEM_NUM AS ITEM_NUM,
             ITEM_VAL AS ITEM_VAL,
             ITEM_VAL_V AS ITEM_VAL_V,
             '2' AS FLAG,
             'Y' AS IS_TOTAL
        FROM CBRC_G1405_CONFIG_TMP_TY_FZ
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
             '009801',
             'CBRC' AS SYS_NAM,
             'G1405' AS REP_NUM,
             ITEM_NUM AS ITEM_NUM,
             ITEM_VAL AS ITEM_VAL,
             ITEM_VAL_V AS ITEM_VAL_V,
             '2' AS FLAG,
             'Y' AS IS_TOTAL
        FROM CBRC_G1405_CONFIG_TMP_QS
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
             '009801',
             'CBRC' AS SYS_NAM,
             'G1405' AS REP_NUM,
             ITEM_NUM AS ITEM_NUM,
             ITEM_VAL AS ITEM_VAL,
             ITEM_VAL_V AS ITEM_VAL_V,
             '2' AS FLAG,
             'Y' AS IS_TOTAL
        FROM CBRC_G1405_CONFIG_TMP_QS_FZ;


    COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1405数据机构处理全部同业合计及子项(金融市场部)进CBRC_A_REPT_ITEM_VAL';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
--============================================================================
   --附注：最大单家及全部同业融资业务情况（扣除结算性同业存款和风险权重为零资产后）  【全部同业合计】
--============================================================================

   ------------------------------金融市场部  ------------------------------

   --全部同业合计.买入返售
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL,ITEM_VAL_V, FLAG,IS_TOTAL)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G1405' AS REP_NUM,
             'G14_5_102..E.2024' AS ITEM_NUM,
             SUM(NVL(T.BALANCE, 0)) AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '2' AS FLAG,
             'Y' AS IS_TOTAL
        FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.FLAG IN ('1', '2')
       GROUP BY T.ORG_NUM;
    COMMIT;


   --全部同业合计.同业投资业务
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL,ITEM_VAL_V, FLAG,IS_TOTAL)
      --去除国债 地方政府债 信用债
      SELECT I_DATADATE AS DATA_DATE,
              T.ORG_NUM,
              'CBRC' AS SYS_NAM,
              'G1405' AS REP_NUM,
              'G14_5_102..L.2024' AS ITEM_NUM,
              SUM(ITEM_VAL) AS ITEM_VAL,
              '' AS ITEM_VAL_V,
              '2' AS FLAG,
              'Y' AS IS_TOTAL
        FROM (
            SELECT A.ORG_NUM,
                   NVL(A.PRINCIPAL_BALANCE, 0)*U.CCY_RATE AS ITEM_VAL
              FROM SMTMODS_L_ACCT_FUND_INVEST A
              LEFT JOIN SMTMODS_L_AGRE_BOND_INFO B --债券信息表
                ON A.SUBJECT_CD = B.STOCK_CD
               AND B.DATA_DATE = I_DATADATE
              LEFT JOIN SMTMODS_L_PUBL_RATE U
                ON U.CCY_DATE = I_DATADATE
               AND U.BASIC_CCY = A.CURR_CD --基准币种
               AND U.FORWARD_CCY = 'CNY' --折算币种
               AND U.DATA_DATE = I_DATADATE
             WHERE A.DATA_DATE = I_DATADATE
               AND A.INVEST_TYP = '00'
               --AND B.STOCK_PRO_TYPE LIKE 'C%'
               --AND B.ISSU_ORG LIKE 'D%'
               AND ((B.ISSU_ORG = 'D03' AND B.STOCK_PRO_TYPE LIKE 'C%') /*AND A.STOCK_PRO_TYPE NOT IN ('C01', 'C0101')*/ --商业银行债
                OR (B.ISSU_ORG = 'D02' AND B.STOCK_PRO_TYPE LIKE 'C%') /* AND A.STOCK_PRO_TYPE NOT IN ('C01', 'C0101')*/ --政策性银行债
                OR B.STOCK_PRO_TYPE IN ('C01', 'C0101') --次级债、二级资本债
                OR (B.ISSU_ORG NOT IN ('D02', 'D03') AND B.STOCK_PRO_TYPE LIKE 'C%')) /*AND A.STOCK_PRO_TYPE NOT IN ('C01', 'C0101')*/ --非银行金融债
             UNION ALL
             SELECT
                   A.ORG_NUM,
                   NVL(A.PRINCIPAL_BALANCE, 0)*U.CCY_RATE AS ITEM_VAL
                FROM SMTMODS_L_ACCT_FUND_CDS_BAL A --存单投资与发行信息表
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
                 AND U.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.STOCK_PRO_TYPE = 'A' --A同业存单 B大额存单
                 AND A.ORG_NUM = '009804'
                 AND A.PRODUCT_PROP = 'A' --A投资 B发行
                 AND A.FACE_VAL <> 0
               ) T
           GROUP BY T.ORG_NUM;


    COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1405数据机构处理全部同业合计及子项(同业金融部)进CBRC_A_REPT_ITEM_VAL';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 ------------------------------同业金融部 ------------------------------


--全部同业合计   拆放同业  其中：同业拆借  其中：同业借款  （反映填报机构与全部境内金融机构间各同业业务规模的合计）
       INSERT INTO CBRC_A_REPT_ITEM_VAL
         (DATA_DATE,
          ORG_NUM,
          SYS_NAM,
          REP_NUM,
          ITEM_NUM,
          ITEM_VAL,
          ITEM_VAL_V,
          FLAG,
          IS_TOTAL)
         SELECT I_DATADATE AS DATA_DATE,
                T.ORG_NUM,
                'CBRC' AS SYS_NAM,
                'G1405' AS REP_NUM,
                CASE
                  WHEN T.FLAG = '7' THEN  --拆放同业
                   'G14_5_102..C.2024'
                  WHEN T.FLAG = '8' THEN  --其中：同业拆借
                   'G14_5_102..C1.2024'
                  ELSE
                   'G14_5_102..C2.2024'  --其中：同业借款
                END AS ITEM_NUM,
                SUM(NVL(T.BALANCE, 0)) AS ITEM_VAL,
                '' AS ITEM_VAL_V,
                '2' AS FLAG,
                'Y' AS IS_TOTAL
           FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH T
          WHERE T.DATA_DATE = I_DATADATE
            AND T.FLAG IN ('7', '8', '9')
          GROUP BY T.ORG_NUM,
                   CASE
                     WHEN T.FLAG = '7' THEN
                      'G14_5_102..C.2024'
                     WHEN T.FLAG = '8' THEN
                      'G14_5_102..C1.2024'
                     ELSE
                      'G14_5_102..C2.2024'
                   END;
    COMMIT;

--存放同业   1011科目
 INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL,ITEM_VAL_V, FLAG,IS_TOTAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G1405' AS REP_NUM,
             'G14_5_102..D.2024'  AS ITEM_NUM,
             SUM(A.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '2' AS FLAG,
             'Y' AS IS_TOTAL
        FROM  SMTMODS_V_PUB_IDX_FINA_GL A --信用卡逾期
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY' 
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('1011')
         AND A.ORG_NUM = '009820'
         AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
       GROUP BY A.ORG_NUM;

    COMMIT;
--同业投资业务   G01投资  公式取数
  -------------------------------------------------------------------------------------------
   


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
   
END proc_cbrc_idx2_g1405;
