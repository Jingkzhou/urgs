CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g1102(II_DATADATE  IN string --跑批日期
                                                     
                                                       )
/******************************
  @AUTHOR:FANXIAOYU
  @CREATE-DATE:2015-09-22
  @DESCRIPTION:G1102
  @MODIFICATION HISTORY:LIXIN04 2015-12-29
  M0.20150919-FANXIAOYU-G1102
  M1.20230830 金融市场部取数规则：L层资产表中的五级分类不准确，关联减值准备表取五级分类
  M2.20241224  逾期贷款部分取数逻辑修改
  m3.20241224 信用卡重新取数JLBA202412040012
  需求编号：JLBA202505140011_关于1104报表系统金融市场部报表取数逻辑变更的需求 上线日期：2025-07-29 修改人：常金磊，提出人：康立军 修改内容：调整债券、存单关联减值表的关联条件，解决关联重复问题
  需求编号：JLBA202505280011 上线日期：2025-09-19，修改人：狄家卉，提出人：赵翰君  修改原因：关于实现1104监管报送报表自动化采集加工的需求 增加009801清算中心(国际业务部)外币折人民币业务
  
目标表：CBRC_A_REPT_ITEM_VAL
        CBRC_PUB_DATA_COLLECT_G1102
        CBRC_TMP_ACCT_LOAN_G1102
        CBRC_TMP_AGRE_GUARANTEE
        CBRC_TMP_ASSET_DEVALUE
        CBRC_TMP_ASSET_DEVALUE_S2601
        CBRC_TMP_ASSET_DEVALUE_TH
        CBRC_TMP_FUND_CDS_BAL_G1102
        CBRC_TMP_FUND_MMFUND_G1102
        CBRC_TMP_FUND_REPURCHASE_G1102
        CBRC_TMP_INVEST_BOND_INFO_G1102
        CBRC_TMP_INVEST_OTHER_SUBJECT_G1102
集市表：SMTMODS_V_PUB_FUND_CDS_BAL
        CBRC_V_PUB_FUND_INVEST
        CBRC_V_PUB_FUND_MMFUND
        CBRC_V_PUB_FUND_REPURCHASE
集市表：SMTMODS_L_ACCT_CARD_CREDIT
        SMTMODS_L_ACCT_LOAN
        SMTMODS_L_AGRE_BILL_CONTRACT
        SMTMODS_L_AGRE_BILL_INFO
        SMTMODS_L_AGRE_BOND_INFO
        SMTMODS_L_AGRE_GUARANTEE_CONTRACT
        SMTMODS_L_AGRE_GUARANTEE_RELATION
        SMTMODS_L_AGRE_GUARANTY_INFO
        SMTMODS_L_AGRE_GUA_RELATION
        SMTMODS_L_AGRE_LOAN_CONTRACT
        SMTMODS_L_AGRE_OTHER_SUBJECT_INFO
        SMTMODS_L_FINA_ASSET_DEVALUE
        SMTMODS_L_FINA_GL
        SMTMODS_L_PUBL_RATE


  
  *******************************/
 IS
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE    VARCHAR(30); --当前储存过程名称
  V_TAB_NAME     VARCHAR(30); --目标表名
  I_DATADATE     string; --数据日期(数值型)YYYYMMDD
  D_DATADATE_CCY string; --数据日期(日期型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(4000); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_ERRORDESC    VARCHAR(280); --错误内容
  V_PER_NUM      VARCHAR(30); --报表编号
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM       VARCHAR2(30);

BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';
    V_SYSTEM    := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G1102');
    I_DATADATE  := II_DATADATE;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_PER_NUM      := 'G1102';
    V_TAB_NAME     := 'CBRC_A_REPT_ITEM_VAL';
    D_DATADATE_CCY := TO_DATE(I_DATADATE, 'YYYYMMDD');

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

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_PUB_DATA_COLLECT_G1102';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP_AGRE_GUARANTEE';        --保证金临时表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP_ASSET_DEVALUE';         --减值临时表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP_ASSET_DEVALUE_TH';      --ADD BY DJH 20240827 减值临时表(接009817投行部其他应收款坏账准备金额，数据来源='投行手工补录其他应收款坏账准备')
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP_ACCT_LOAN_G1102';       --贷款+资金中间表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP_INVEST_BOND_INFO_G1102';--投资业务+债券信息中间表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP_FUND_MMFUND_G1102';     --资金往来中间表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP_FUND_REPURCHASE_G1102'; --回购中间表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP_FUND_CDS_BAL_G1102';    --同业存单中间表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP_INVEST_OTHER_SUBJECT_G1102'; --资金+标的中间表


    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --==================================================
    --减值临时表
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '减值临时表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_TMP_ASSET_DEVALUE 
      (DATA_DATE,
       RECORD_ORG,
       BIZ_NO,
       CURR,
       PRIN_SUBJ_NO,
       FIVE_TIER_CLS,
       ACCT_NUM,
       PRIN_FINAL_RESLT,
       OFBS_FINAL_RESLT,
       INT_FINAL_RESLT,
       COLLBL_INT_FINAL_RESLT,
       ACCT_ID)--[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
      SELECT 
       T.DATA_DATE,
       T.RECORD_ORG,
       --买入返售 卖出回购 对应多个押品 减值表按押品存储 BIZ_NO会拼接押品信息 避免关联重复 所以该部分去掉BIZ_NO分组条件
       CASE
         WHEN SUBSTR(T.PRIN_SUBJ_NO, 1, 4) IN ('1111', '2111') THEN
          ''
         ELSE
          T.BIZ_NO
       END,
       T.CURR,
       CASE
         WHEN SUBSTR(T.PRIN_SUBJ_NO, 1, 4) IN ('1111', '2111') THEN
          SUBSTR(T.PRIN_SUBJ_NO, 1, 4)
         ELSE
          T.PRIN_SUBJ_NO
       END PRIN_SUBJ_NO,
       T.FIVE_TIER_CLS,
       T.ACCT_NUM,
       SUM(NVL(T.PRIN_FINAL_RESLT, 0)),
       SUM(NVL(T.OFBS_FINAL_RESLT, 0)),
       SUM(NVL(T.INT_FINAL_RESLT, 0)),
       SUM(NVL(T.COLLBL_INT_FINAL_RESLT, 0)),
       ACCT_ID--[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
        FROM SMTMODS_L_FINA_ASSET_DEVALUE T --资产减值准备
       WHERE T.DATA_DATE = I_DATADATE
       AND (T.DATA_SRC <>'投行手工补录其他应收款坏账准备' OR T.DATA_SRC IS NULL)
       GROUP BY T.RECORD_ORG,
                CASE
                  WHEN SUBSTR(T.PRIN_SUBJ_NO, 1, 4) IN ('1111', '2111') THEN
                   ''
                  ELSE
                   T.BIZ_NO
                END,
                T.CURR,
                CASE
                  WHEN SUBSTR(T.PRIN_SUBJ_NO, 1, 4) IN ('1111', '2111') THEN
                   SUBSTR(T.PRIN_SUBJ_NO, 1, 4)
                  ELSE
                   T.PRIN_SUBJ_NO
                END,
                T.FIVE_TIER_CLS,
                T.DATA_DATE,
                T.ACCT_NUM,
                T.ACCT_ID;--[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
    COMMIT;

      INSERT 
      INTO CBRC_TMP_ASSET_DEVALUE_TH 
        (DATA_DATE,
         RECORD_ORG,
         BIZ_NO,
         CURR,
         PRIN_SUBJ_NO,
         FIVE_TIER_CLS,
         ACCT_NUM,
         FINAL_ECL, -- ADD BY DJH 20240827 此字段为;'应计利息',本表中此字段为了接009817投行部其他应收款坏账准备金额，数据来源='投行手工补录其他应收款坏账准备' 补充进来，为了接数
         DATA_SRC) -- ADD BY DJH 20240827 此字段为;数据来源='投行手工补录其他应收款坏账准备'
        SELECT 
         T.DATA_DATE,
         T.RECORD_ORG,
         T.BIZ_NO,
         T.CURR,
         T.PRIN_SUBJ_NO,
         T.FIVE_TIER_CLS,
         T.ACCT_NUM,
         SUM(NVL(T.FINAL_ECL, 0)),
         T.DATA_SRC
          FROM SMTMODS_L_FINA_ASSET_DEVALUE T --资产减值准备
         WHERE T.DATA_DATE = I_DATADATE
           AND T.DATA_SRC = '投行手工补录其他应收款坏账准备'
         GROUP BY T.DATA_DATE,
                  T.RECORD_ORG,
                  T.BIZ_NO,
                  T.CURR,
                  T.PRIN_SUBJ_NO,
                  T.FIVE_TIER_CLS,
                  T.ACCT_NUM,
                  T.DATA_SRC;
    COMMIT;

    --==================================================
    --押品信息临时表
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '押品信息临时表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --押品信息临时表 --押品市场价值和
    INSERT 
    INTO CBRC_TMP_AGRE_GUARANTEE 
      (DATA_DATE, CONTRACT_NUM, LOAN_SUBTYPE, COLL_MK_VAL, REL_STATUS,GUAR_CONTRACT_NUM,GUARANTEE_SERIAL_NUM,MAIN_GUARANTY_TYP)
      SELECT 
           A.DATA_DATE,
           A.CONTRACT_NUM,--业务合同号
           CASE --担保形式
             WHEN B.GUAR_TYP = 'A0101' THEN --抵押
              'C'
             WHEN B.GUAR_TYP = 'B0101' THEN --质押
              'D'
             WHEN B.GUAR_TYP IN ('C0101', 'C0201', 'C0301', 'C0302', 'C0401') THEN --
              'B'
             ELSE
              'A'
           END AS LOAN_SUBTYPE,
           NVL(D.COLL_MK_VAL, 0) * U.CCY_RATE AS COLL_MK_VAL_SUM,
           C.REL_STATUS,
           A.GUAR_CONTRACT_NUM, -- 担保合同号
           C.GUARANTEE_SERIAL_NUM, --担保物编号
           E.MAIN_GUARANTY_TYP -- 主要担保方式：抵押质押
        FROM SMTMODS_L_AGRE_GUA_RELATION A  --业务合同与担保合同对应关系表
        INNER JOIN SMTMODS_L_AGRE_GUARANTEE_CONTRACT B  --担保合同信息
          ON A.GUAR_CONTRACT_NUM = B.GUAR_CONTRACT_NUM --担保合同号
         AND B.DATA_DATE = I_DATADATE
        INNER JOIN SMTMODS_L_AGRE_GUARANTEE_RELATION C --担保合同与担保信息对应关系表
          ON A.GUAR_CONTRACT_NUM = C.GUAR_CONTRACT_NUM --担保合同与担保信息对应关系表
         AND C.DATA_DATE = I_DATADATE
         AND C.REL_STATUS = 'Y'
        INNER JOIN SMTMODS_L_AGRE_GUARANTY_INFO D --抵质押物详细信息
          ON C.GUARANTEE_SERIAL_NUM = D.GUARANTEE_SERIAL_NUM --担保物编号 押品编号
         AND D.DATA_DATE = I_DATADATE
         AND D.COLL_STATUS = 'Y' --押品状态
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = D.COLL_CCY --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE
        INNER JOIN SMTMODS_L_AGRE_LOAN_CONTRACT E --贷款合同信息表
          ON A.CONTRACT_NUM = E.CONTRACT_NUM
         AND E.DATA_DATE = I_DATADATE
       WHERE C.GUAR_CUST_ID IS NOT NULL
         AND A.DATA_DATE = I_DATADATE
         AND B.GUAR_CONTRACT_STATUS = 'Y' --担保合同有效状态
         AND A.REL_STATUS = 'Y' --关联状态
         AND NVL(D.COLL_MK_VAL * U.CCY_RATE, 0) <> 0
         AND SUBSTR(E.MAIN_GUARANTY_TYP,1,1) IN ('A','B') --只取抵押+质押
         ;
    COMMIT;

    --==================================================
    --贷款+资金中间表
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '贷款+资金中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP_ACCT_LOAN_G1102
    (DATA_DATE, ORG_NUM, ACCT_NUM, LOAN_NUM, SECURITY_AMT, LOAN_GRADE_CD, LOAN_ACCT_BAL, FIVE_TIER_CLS, JZJE, GL_ITEM_CODE, TAG,
     OD_DAYS,OD_FLG,ACCT_TYP,PAY_TYPE,OD_LOAN_ACCT_BAL,GUARANTY_TYP,OD_INT)
    SELECT 
         I_DATADATE AS DATA_DATE,
         A.ORG_NUM AS ORG_NUM, --机构号
         A.ACCT_NUM AS ACCT_NUM, --账号
         A.LOAN_NUM AS LOAN_NUM, --借据
         NVL(A.SECURITY_AMT * U.CCY_RATE, 0) AS SECURITY_AMT, --保证金
         A.LOAN_GRADE_CD AS LOAN_GRADE_CD, --贷款五级分类
         NVL(A.LOAN_ACCT_BAL * U.CCY_RATE, 0) AS LOAN_ACCT_BAL, --贷款余额
         C.FIVE_TIER_CLS AS FIVE_TIER_CLS, --减值五级分类
         (NVL(C.PRIN_FINAL_RESLT, 0) + NVL(C.OFBS_FINAL_RESLT, 0)) * U.CCY_RATE AS JZJE, --减值金额
         A.ITEM_CD AS GL_ITEM_CODE, --科目
         '贷款' TAG, --标识
         OD_DAYS AS OD_DAYS, --逾期天数
         OD_FLG AS OD_FLG, --逾期标志
         ACCT_TYP AS ACCT_TYP, --账户类型
         PAY_TYPE AS PAY_TYPE, --还款方式
         NVL(A.OD_LOAN_ACCT_BAL * U.CCY_RATE, 0) AS OD_LOAN_ACCT_BAL, --逾期贷款余额
         GUARANTY_TYP AS GUARANTY_TYP, --主要担保方式
         OD_INT AS OD_INT --应收利息
      FROM SMTMODS_L_ACCT_LOAN A --贷款
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = I_DATADATE
       AND U.BASIC_CCY = A.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY'
       AND U.DATA_DATE = I_DATADATE
      LEFT JOIN CBRC_TMP_ASSET_DEVALUE C --资产减值准备
        --ON C.BIZ_NO = A.LOAN_NUM
        ON C.ACCT_NUM = A.LOAN_NUM
       AND A.ORG_NUM = C.RECORD_ORG
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ACCT_TYP NOT LIKE '90%'
       AND A.ACCT_STS <> '3'
       AND A.CANCEL_FLG <> 'Y'
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250228 JLBA202408200012 资产未转让
       AND A.BOOK_TYPE = '2' --银行账簿
       AND( A.LOAN_ACCT_BAL <> 0 or A.OD_LOAN_ACCT_BAL <>0 )
    ;
    COMMIT;

    INSERT INTO CBRC_TMP_ACCT_LOAN_G1102
    (DATA_DATE, ORG_NUM, ACCT_NUM, LOAN_NUM, SECURITY_AMT, LOAN_GRADE_CD, LOAN_ACCT_BAL, FIVE_TIER_CLS, JZJE, GL_ITEM_CODE, TAG,DC_DATE)
    SELECT 
         I_DATADATE AS DATA_DATE,
         A.ORG_NUM AS ORG_NUM, --机构号
         A.ACCT_NUM AS ACCT_NUM, --账号
         A.SUBJECT_CD AS LOAN_NUM, --借据
         NVL(A.SECURITY_AMT * U.CCY_RATE, 0) AS SECURITY_AMT, --保证金
         A.GRADE AS LOAN_GRADE_CD, --贷款五级分类
         NVL(A.FACE_VAL * U.CCY_RATE, 0) AS LOAN_ACCT_BAL, --贷款余额
         C.FIVE_TIER_CLS AS FIVE_TIER_CLS, --减值五级分类
         (NVL(C.PRIN_FINAL_RESLT, 0) + NVL(C.OFBS_FINAL_RESLT, 0)) * U.CCY_RATE AS JZJE, --减值金额
         A.GL_ITEM_CODE AS GL_ITEM_CODE, --科目
         '资金买断式转贴' AS TAG, --标识
         DC_DATE AS DC_DATE
      FROM CBRC_V_PUB_FUND_INVEST A
      LEFT JOIN CBRC_TMP_ASSET_DEVALUE C --资产减值准备
        ON C.BIZ_NO = A.ACCT_NUM
       AND A.ORG_NUM = C.RECORD_ORG
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = I_DATADATE
       AND U.BASIC_CCY = A.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
       AND U.DATA_DATE = I_DATADATE
     WHERE A.INVEST_TYP = '11' --买断式转贴现
       AND A.DATA_DATE = I_DATADATE
       AND A.BOOK_TYPE = '2' --账户种类 2 银行账薄
       AND A.FACE_VAL <> 0
    ;
    COMMIT;


    --==============================================================================================
    ----------------------------------------银行账簿信用风险资产--------------------------------------
    --==============================================================================================

    --==============================================================================================
    --1.各项贷款 五级分类 + 逾期  G11_2_1..F  贷款+资金（买断式转贴）+信用卡
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '1.各项贷款 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL, --指标值
       TAG
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       CASE
         WHEN LOAN_GRADE_CD = '1' THEN
          'G11_2_1..C'
         WHEN LOAN_GRADE_CD IS NULL THEN
          'G11_2_1..C'
         WHEN LOAN_GRADE_CD = '2' THEN
          'G11_2_1..D'
         WHEN LOAN_GRADE_CD = '3' THEN
          'G11_2_1..F'
         WHEN LOAN_GRADE_CD = '4' THEN
          'G11_2_1..G'
         WHEN LOAN_GRADE_CD = '5' THEN
          'G11_2_1..H'
       END AS ITEM_NUM, --指标号
       SUM(NVL(A.LOAN_ACCT_BAL, 0)) AS COLLECT_VAL, --指标值
       '贷款' TAG
        FROM CBRC_TMP_ACCT_LOAN_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM,
                 CASE
                   WHEN LOAN_GRADE_CD = '1' THEN
                    'G11_2_1..C'
                   WHEN LOAN_GRADE_CD IS NULL THEN
                    'G11_2_1..C'
                   WHEN LOAN_GRADE_CD = '2' THEN
                    'G11_2_1..D'
                   WHEN LOAN_GRADE_CD = '3' THEN
                    'G11_2_1..F'
                   WHEN LOAN_GRADE_CD = '4' THEN
                    'G11_2_1..G'
                   WHEN LOAN_GRADE_CD = '5' THEN
                    'G11_2_1..H'
                 END;
    COMMIT;

    --逾期
    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL, --指标值
       TAG
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       'G11_2_1..I.2019' AS ITEM_NUM, --指标号
       SUM(NVL(A.LOAN_ACCT_BAL, 0)) AS COLLECT_VAL, --指标值
       '资金买断式转贴逾期' AS TAG
        FROM CBRC_TMP_ACCT_LOAN_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.LOAN_GRADE_CD IN ('3', '4', '5')
         AND A.TAG = '资金买断式转贴'
       GROUP BY A.ORG_NUM;
    COMMIT;

    /* 以下逻辑处理逾期贷款总数 逻辑*/
    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT ORG_NUM AS ORG_NUM,
             'G11_2_1..I.2019' AS ITEM_NUM,
             SUM(NVL(LOAN_ACCT_BAL, 0)) AS ITEM_VAL
        FROM CBRC_TMP_ACCT_LOAN_G1102 A
       WHERE OD_DAYS <= 90
         AND OD_DAYS > 0
         AND OD_FLG = 'Y'
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND ORG_NUM <> '009803'
         AND (ACCT_TYP NOT LIKE '0101%' AND ACCT_TYP NOT LIKE '0103%' AND
              ACCT_TYP NOT LIKE '0104%' AND ACCT_TYP NOT LIKE '0199%' AND
              ACCT_TYP NOT IN ('E01', 'E02') AND ACCT_TYP NOT LIKE '90%')
         AND A.GL_ITEM_CODE NOT LIKE '130105%'
       GROUP BY ORG_NUM;
     COMMIT;

    /* 还款方式 变更为 1 2  等额本息 等额本金  */
    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 

      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT a.ORG_NUM AS ORG_NUM,
             'G11_2_1..I.2019' AS ITEM_NUM,
             SUM(CASE  --JLBA202412040012
                   WHEN A.PAY_TYPE  IN ('01', '02','10','11')  and  b.REPAY_TYP ='1' THEN NVL(a.OD_LOAN_ACCT_BAL,0)
                   ELSE NVL(a.LOAN_ACCT_BAL,0)
                 END) AS ITEM_VAL
        FROM CBRC_TMP_ACCT_LOAN_G1102 A
         left join SMTMODS_L_ACCT_LOAN b
           on  a.loan_num =b.loan_num
            and b.data_date = I_DATADATE
       WHERE a.OD_DAYS > 0
         AND a.OD_DAYS <= 90
         AND a.OD_FLG = 'Y'
         AND a.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         --0101  个人住房贷款 0103  个人消费贷款 0104  个人助学贷款 0199  其他个人类贷款
         AND (a.ACCT_TYP LIKE '0101%' OR a.ACCT_TYP LIKE '0103%' OR
             a.ACCT_TYP LIKE '0104%' OR
             a.ACCT_TYP LIKE '0199%' )
             AND a.ACCT_TYP NOT LIKE '90%'
         AND A.GL_ITEM_CODE NOT LIKE '130105%'
         AND a.ORG_NUM <> '009803'
       GROUP BY a.ORG_NUM;
     COMMIT;

    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 

      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM AS ORG_NUM,
             'G11_2_1..I.2019' AS ITEM_NUM,
             SUM(NVL(LOAN_ACCT_BAL, 0)) AS ITEM_VAL
        FROM CBRC_TMP_ACCT_LOAN_G1102 A
       WHERE A.OD_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND (A.OD_DAYS > 90 OR A.OD_DAYS IS NULL)
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.ACCT_TYP NOT LIKE '90%'
       GROUP BY ORG_NUM;
     COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '1.各项贷款 五级分类 + 逾期 信用卡';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL, --指标值
       TAG
       )
       --JLBA202412040012
       SELECT '009803' AS ORG_NUM,
             case
                  when LXQKQS >= 7 then
                   'G11_2_1..H'
                  when LXQKQS between 5 and 6 then
                   'G11_2_1..G'
                  when LXQKQS = 4 then
                   'G11_2_1..F'
                  when LXQKQS between 1 and 3 then
                   'G11_2_1..D'
                  else
                   'G11_2_1..C'
                end as COLLECT_TYPE,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE) as COLLECT_VAL,
           '信用卡'
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
       group by case
                  when LXQKQS >= 7 then
                   'G11_2_1..H'
                  when LXQKQS between 5 and 6 then
                   'G11_2_1..G'
                  when LXQKQS = 4 then
                   'G11_2_1..F'
                  when LXQKQS between 1 and 3 then
                   'G11_2_1..D'
                  else
                   'G11_2_1..C'
                end;
     
    COMMIT;

    --信用卡逾期JLBA202412040012
    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL, --指标值
       TAG
       )
      SELECT '009803' AS ORG_NUM,
             'G11_2_1..I.2019' AS ITEM_NUM,
             --M4 + M5 + M6 + M6_UP AS ITEM_VAL,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE) AS ITEM_VAL,
             '信用卡逾期'
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
          AND  LXQKQS >= 1 ;
    COMMIT;

    --==============================================================================================
    --1.1保证金和抵质押品价值 五级分类 + 逾期  G11_2_1.1.F
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '1.各项贷款 保证金和抵质押品价值 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --贷款保证金和抵质押品价值
    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT 
     ORG_NUM AS ORG_NUM,
     CASE
       WHEN LOAN_GRADE_CD = '3' THEN
        'G11_2_1.1.F'
       WHEN LOAN_GRADE_CD = '4' THEN
        'G11_2_1.1.G'
       WHEN LOAN_GRADE_CD = '5' THEN
        'G11_2_1.1.H'
     END AS ITEM_NUM, --指标号
     SUM(CASE
           WHEN NVL(SECURITY_AMT, 0) + NVL(COLL_MK_VAL, 0) > NVL(LOAN_ACCT_BAL, 0) + NVL(OD_INT, 0) THEN
            NVL(LOAN_ACCT_BAL, 0) + NVL(OD_INT, 0)
           ELSE
            NVL(SECURITY_AMT, 0) + NVL(COLL_MK_VAL, 0)
         END) AS COLLECT_VAL
      FROM (SELECT 
             LOAN.DATA_DATE AS DATA_DATE,
             LOAN.ORG_NUM AS ORG_NUM, --机构号
             LOAN.LOAN_GRADE_CD AS LOAN_GRADE_CD,
             NVL(GUA.COLL_MK_VAL, 0) AS COLL_MK_VAL,
             LOAN.SECURITY_AMT AS SECURITY_AMT,
             LOAN.LOAN_ACCT_BAL AS LOAN_ACCT_BAL,
             LOAN.OD_INT AS OD_INT,
             LOAN.ACCT_NUM AS ACCT_NUM
              FROM (SELECT T.DATA_DATE AS DATA_DATE,
                           T.ORG_NUM AS ORG_NUM,
                           T.LOAN_GRADE_CD AS LOAN_GRADE_CD,
                           T.ACCT_NUM AS ACCT_NUM,
                           SUM(T.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL,
                           SUM(T.SECURITY_AMT) AS SECURITY_AMT,
                           SUM(T.OD_INT) AS OD_INT
                      FROM CBRC_TMP_ACCT_LOAN_G1102 T
                     WHERE T.DATA_DATE = I_DATADATE
                       AND SUBSTR(GUARANTY_TYP, 1, 1) NOT IN ('C', 'D') --去掉保证信用
                     GROUP BY T.DATA_DATE,T.ORG_NUM, T.LOAN_GRADE_CD, T.ACCT_NUM) LOAN
              LEFT JOIN (SELECT DATA_DATE AS DATA_DATE,
                               CONTRACT_NUM AS CONTRACT_NUM,
                               SUM(COLL_MK_VAL) AS COLL_MK_VAL
                          FROM CBRC_TMP_AGRE_GUARANTEE
                         GROUP BY DATA_DATE, CONTRACT_NUM) GUA
                ON LOAN.ACCT_NUM = GUA.CONTRACT_NUM
               AND GUA.DATA_DATE = I_DATADATE
             WHERE LOAN.DATA_DATE = I_DATADATE
               AND LOAN.LOAN_GRADE_CD IN ('3', '4', '5')) --不良资产
     GROUP BY ORG_NUM,
              CASE
                WHEN LOAN_GRADE_CD = '3' THEN
                 'G11_2_1.1.F'
                WHEN LOAN_GRADE_CD = '4' THEN
                 'G11_2_1.1.G'
                WHEN LOAN_GRADE_CD = '5' THEN
                 'G11_2_1.1.H'
              END;
   COMMIT;


    --贷款保证金和抵质押品价值逾期
    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT 
     ORG_NUM AS ORG_NUM,
     'G11_2_1.1.I.2019' AS ITEM_NUM, --指标号
     SUM(CASE
           WHEN NVL(SECURITY_AMT, 0) + NVL(COLL_MK_VAL, 0) > NVL(LOAN_ACCT_BAL, 0) + NVL(OD_INT, 0) THEN
            NVL(LOAN_ACCT_BAL, 0) + NVL(OD_INT, 0)
           ELSE
            NVL(SECURITY_AMT, 0) + NVL(COLL_MK_VAL, 0)
         END) AS COLLECT_VAL
      FROM (SELECT 
             LOAN.DATA_DATE AS DATA_DATE,
             LOAN.ORG_NUM AS ORG_NUM, --机构号
             LOAN.LOAN_GRADE_CD AS LOAN_GRADE_CD,
             NVL(GUA.COLL_MK_VAL, 0) AS COLL_MK_VAL,
             LOAN.SECURITY_AMT AS SECURITY_AMT,
             LOAN.LOAN_ACCT_BAL AS LOAN_ACCT_BAL,
             LOAN.OD_INT AS OD_INT,
             LOAN.ACCT_NUM AS ACCT_NUM
              FROM (SELECT A.DATA_DATE AS DATA_DATE,
                           A.ORG_NUM AS ORG_NUM,
                           A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
                           A.ACCT_NUM AS ACCT_NUM,
                           SUM(A.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL,
                           SUM(A.SECURITY_AMT) AS SECURITY_AMT,
                           SUM(A.OD_INT) AS OD_INT
                      FROM CBRC_TMP_ACCT_LOAN_G1102 A
                     WHERE A.OD_DAYS <= 90
                       AND A.OD_DAYS > 0
                       AND A.OD_FLG = 'Y'
                       AND A.DATA_DATE = I_DATADATE
                       AND ORG_NUM <> '009803'
                       AND (ACCT_TYP NOT LIKE '0101%' AND ACCT_TYP NOT LIKE '0103%' AND ACCT_TYP NOT LIKE '0104%' AND
                            ACCT_TYP NOT LIKE '0199%' AND ACCT_TYP NOT IN ('E01', 'E02') AND ACCT_TYP NOT LIKE '90%')
                       AND A.GL_ITEM_CODE NOT LIKE '130105%'
                       AND SUBSTR(GUARANTY_TYP, 1, 1) NOT IN ('C', 'D') --去掉保证信用
                     GROUP BY A.DATA_DATE, A.ORG_NUM, A.LOAN_GRADE_CD, A.ACCT_NUM

                    UNION ALL

                    SELECT A.DATA_DATE AS DATA_DATE,
                           A.ORG_NUM AS ORG_NUM,
                           A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
                           A.ACCT_NUM AS ACCT_NUM,
                           SUM(CASE --JLBA202412040012
                                 WHEN A.PAY_TYPE  IN ('01', '02','10','11')  AND B.REPAY_TYP ='1' THEN
                                  NVL(A.OD_LOAN_ACCT_BAL, 0)
                                 ELSE
                                  NVL(A.LOAN_ACCT_BAL, 0)
                               END) AS LOAN_ACCT_BAL,
                           SUM(A.SECURITY_AMT) AS SECURITY_AMT,
                           SUM(A.OD_INT) AS OD_INT
                      FROM CBRC_TMP_ACCT_LOAN_G1102 A
                      LEFT JOIN SMTMODS_L_ACCT_LOAN B
                         ON A.LOAN_NUM =B.LOAN_NUM
                        AND B.DATA_DATE  = I_DATADATE
                     WHERE A.OD_DAYS > 0
                       AND A.OD_DAYS <= 90
                       AND A.OD_FLG = 'Y'
                       AND A.DATA_DATE = I_DATADATE
                       AND (A.ACCT_TYP LIKE '0101%' OR A.ACCT_TYP LIKE '0103%' OR A.ACCT_TYP LIKE '0104%' OR
                            A.ACCT_TYP LIKE '0199%') AND A.ACCT_TYP NOT LIKE '90%'
                       AND A.GL_ITEM_CODE NOT LIKE '130105%'
                       AND SUBSTR(A.GUARANTY_TYP, 1, 1) NOT IN ('C', 'D') --去掉保证信用
                       AND A.ORG_NUM <> '009803'
                     GROUP BY A.DATA_DATE, A.ORG_NUM, A.LOAN_GRADE_CD, A.ACCT_NUM

                    UNION ALL

                    SELECT A.DATA_DATE AS DATA_DATE,
                           A.ORG_NUM AS ORG_NUM,
                           A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
                           A.ACCT_NUM AS ACCT_NUM,
                           SUM(A.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL,
                           SUM(A.SECURITY_AMT) AS SECURITY_AMT,
                           SUM(A.OD_INT) AS OD_INT
                      FROM CBRC_TMP_ACCT_LOAN_G1102 A
                     WHERE A.OD_FLG = 'Y'
                       AND A.DATA_DATE = I_DATADATE
                       AND (A.OD_DAYS > 90 OR A.OD_DAYS IS NULL)
                       AND SUBSTR(GUARANTY_TYP, 1, 1) NOT IN ('C', 'D') --去掉保证信用
                       AND A.ACCT_TYP NOT LIKE '90%'
                     GROUP BY A.DATA_DATE, A.ORG_NUM, A.LOAN_GRADE_CD, A.ACCT_NUM) LOAN
              LEFT JOIN (SELECT DATA_DATE AS DATA_DATE,
                               CONTRACT_NUM AS CONTRACT_NUM,
                               SUM(COLL_MK_VAL) AS COLL_MK_VAL
                          FROM CBRC_TMP_AGRE_GUARANTEE
                         GROUP BY DATA_DATE, CONTRACT_NUM) GUA
                ON LOAN.ACCT_NUM = GUA.CONTRACT_NUM
               AND GUA.DATA_DATE = I_DATADATE
             WHERE LOAN.DATA_DATE = I_DATADATE
               ) --不良资产
     GROUP BY ORG_NUM;
  COMMIT;

   ---信用卡 1.1保证金和抵质押品价值I列取：逾期贷款(M1+M2...+M6+)
   --alter by 20241217 JLBA202412040012

    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT '009803' AS ORG_NUM,
             'G11_2_1.1.I.2019' AS COLLECT_TYPE,
             --M4 + M5 + M6 + M6_UP AS ITEM_VAL,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
          AND  LXQKQS >= 1 ;



    --==============================================================================================
    --1.2减值准备 五级分类 + 逾期 G11_2_1.2.F
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '1.各项贷款 减值 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --贷款减值
    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
       T.ORG_NUM AS ORG_NUM, --机构号
       CASE
         WHEN T.FIVE_TIER_CLS = '01' THEN
          'G11_2_1.2.C'
         WHEN T.FIVE_TIER_CLS IS NULL THEN
          'G11_2_1.2.C'
         WHEN T.FIVE_TIER_CLS = '02' THEN
          'G11_2_1.2.D'
         WHEN T.FIVE_TIER_CLS = '03' THEN
          'G11_2_1.2.F'
         WHEN T.FIVE_TIER_CLS = '04' THEN
          'G11_2_1.2.G'
         WHEN T.FIVE_TIER_CLS = '05' THEN
          'G11_2_1.2.H'
       END AS ITEM_NUM, --指标号
       SUM(NVL(T.JZJE, 0)) AS COLLECT_VAL
        FROM CBRC_TMP_ACCT_LOAN_G1102 T
       WHERE T.DATA_DATE = I_DATADATE
         AND NOT EXISTS (SELECT 1
                FROM CBRC_TMP_ACCT_LOAN_G1102 A
               WHERE A.LOAN_NUM = T.LOAN_NUM
                 AND A.DATA_DATE = I_DATADATE
                 AND A.ORG_NUM = '009804' --剔除金融市场部正常减值数据，从科目40030216里取数据
                 AND A.LOAN_GRADE_CD = '1'
                 )
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN T.FIVE_TIER_CLS = '01' THEN
                   'G11_2_1.2.C'
                  WHEN T.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_1.2.C'
                  WHEN T.FIVE_TIER_CLS = '02' THEN
                   'G11_2_1.2.D'
                  WHEN T.FIVE_TIER_CLS = '03' THEN
                   'G11_2_1.2.F'
                  WHEN T.FIVE_TIER_CLS = '04' THEN
                   'G11_2_1.2.G'
                  WHEN T.FIVE_TIER_CLS = '05' THEN
                   'G11_2_1.2.H'
                END;
    COMMIT;

    --金融市场部正常减值数据，从科目40030216里取数据
    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
       '009804' AS ORG_NUM, --机构号
       'G11_2_1.2.C' COLLECT_TYPE,
       SUM(G.CREDIT_BAL * U.CCY_RATE) COLLECT_VAL
        FROM SMTMODS_L_FINA_GL G
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
         AND U.DATA_DATE = I_DATADATE
       WHERE G.DATA_DATE = I_DATADATE
         AND G.ORG_NUM = '009804'
         AND G.ITEM_CD IN ('40030216');
    COMMIT;


    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT ORG_NUM AS ORG_NUM,
           'G11_2_1.2.I.2019' AS ITEM_NUM,
           SUM(NVL(JZJE, 0)) AS ITEM_VAL
      FROM (SELECT A.DATA_DATE     AS DATA_DATE,
                   A.ORG_NUM       AS ORG_NUM,
                   A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
                   A.ACCT_NUM      AS ACCT_NUM,
                   A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL,
                   A.SECURITY_AMT  AS SECURITY_AMT,
                   A.OD_INT        AS OD_INT,
                   A.JZJE,
                   A.LOAN_NUM
              FROM CBRC_TMP_ACCT_LOAN_G1102 A
             WHERE A.OD_DAYS <= 90
               AND A.OD_DAYS > 0
               AND A.OD_FLG = 'Y'
               AND A.DATA_DATE = I_DATADATE
               AND ORG_NUM <> '009803'
               AND (ACCT_TYP NOT LIKE '0101%' AND ACCT_TYP NOT LIKE '0103%' AND
                   ACCT_TYP NOT LIKE '0104%' AND ACCT_TYP NOT LIKE '0199%' AND
                   ACCT_TYP NOT IN ('E01', 'E02') AND ACCT_TYP NOT LIKE '90%')
               AND A.GL_ITEM_CODE NOT LIKE '130105%'

            UNION ALL

            SELECT A.DATA_DATE AS DATA_DATE,
                   A.ORG_NUM AS ORG_NUM,
                   A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
                   A.ACCT_NUM AS ACCT_NUM,
                   CASE --JLBA202412040012
                     WHEN A.PAY_TYPE  IN ('01', '02','10','11') AND B.REPAY_TYP ='1'  THEN
                      NVL(A.OD_LOAN_ACCT_BAL, 0)
                     ELSE
                      NVL(A.LOAN_ACCT_BAL, 0)
                   END AS LOAN_ACCT_BAL,
                   A.SECURITY_AMT AS SECURITY_AMT,
                   A.OD_INT AS OD_INT,
                   CASE --JLBA202412040012
                     WHEN A.PAY_TYPE  IN ('01', '02','10','11') AND B.REPAY_TYP ='1'  THEN
                      NVL(A.JZJE, 0)
                     ELSE
                      NVL(A.JZJE, 0)
                   END AS JZJE,
                   A.LOAN_NUM
              FROM CBRC_TMP_ACCT_LOAN_G1102 A
                LEFT JOIN SMTMODS_L_ACCT_LOAN B
                   ON A.LOAN_NUM =B.LOAN_NUM
                   AND B.DATA_DATE = I_DATADATE
             WHERE A.OD_DAYS > 0
               AND A.OD_DAYS <= 90
               AND A.OD_FLG = 'Y'
               AND A.DATA_DATE = I_DATADATE
               AND (A.ACCT_TYP LIKE '0101%' OR A.ACCT_TYP LIKE '0103%' OR
                   A.ACCT_TYP LIKE '0104%' OR
                   A.ACCT_TYP LIKE '0199%' )
                   AND A.ACCT_TYP NOT LIKE '90%'
               AND A.GL_ITEM_CODE NOT LIKE '130105%'
               AND A.ORG_NUM <> '009803'

            UNION ALL

            SELECT A.DATA_DATE     AS DATA_DATE,
                   A.ORG_NUM       AS ORG_NUM,
                   A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
                   A.ACCT_NUM      AS ACCT_NUM,
                   A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL,
                   A.SECURITY_AMT  AS SECURITY_AMT,
                   A.OD_INT        AS OD_INT,
                   A.JZJE,
                   A.LOAN_NUM
              FROM CBRC_TMP_ACCT_LOAN_G1102 A
             WHERE A.OD_FLG = 'Y'
               AND A.DATA_DATE = I_DATADATE
               AND (A.OD_DAYS > 90 OR A.OD_DAYS IS NULL)
               AND A.ACCT_TYP NOT LIKE '90%')
     GROUP BY ORG_NUM;
    COMMIT;

    --ALTER TABLE 20241217  JLBA202412040012
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '1.各项贷款 1.2减值准备 信用卡';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      
            SELECT '009803' org_num,
                   'G11_2_1.2.D' COLLECT_TYPE,
               SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 U.CCY_RATE * 0.03 ) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
           AND T.LXQKQS between 1 and 3
           union all
           SELECT '009803' org_num,
                   'G11_2_1.2.F' COLLECT_TYPE,
               SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 U.CCY_RATE * 0.26 ) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
           AND T.LXQKQS =4
            union all
           SELECT '009803' org_num,
                   'G11_2_1.2.G' COLLECT_TYPE,
               SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 U.CCY_RATE * 0.51 ) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
           AND T.LXQKQS between 5 and 6
             union all
           SELECT '009803' org_num,
                   'G11_2_1.2.H' COLLECT_TYPE,
               SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 U.CCY_RATE  ) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
           AND T.LXQKQS >=7

            ;
           COMMIT;
     --新增信用卡逻辑JLBA202412040012
       INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
       SELECT  ORG_NUM , COLLECT_TYPE ,SUM(COLLECT_VAL) FROM (
       SELECT  '009803' ORG_NUM,
             'G11_2_1.2.C' AS COLLECT_TYPE,
             SUM(CASE WHEN G.ITEM_CD ='1304' THEN G.CREDIT_BAL
                  WHEN G.ITEM_CD ='130407' THEN G.CREDIT_BAL*-1 END * U.CCY_RATE) AS COLLECT_VAL

       FROM  SMTMODS_L_FINA_GL G
          LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         WHERE G.DATA_DATE= I_DATADATE
            AND G.ORG_NUM ='009803'
            AND G.ITEM_CD IN ('1304','130407')
       UNION ALL

         SELECT  '009803' ORG_NUM,
                  'G11_2_1.2.C' AS COLLECT_TYPE,
                  SUM(T.COLLECT_VAL) * -1  AS COLLECT_VAL
          FROM  CBRC_PUB_DATA_COLLECT_G1102 T
           WHERE T.COLLECT_TYPE IN ('G11_2_1.2.D','G11_2_1.2.F','G11_2_1.2.G','G11_2_1.2.H')
           ) AA
           GROUP BY ORG_NUM , COLLECT_TYPE
       ;

    COMMIT;

    --信用卡减值逾期
  

    /*
    MODIFY BY DW(20211021) BEGIN
    修改债券、信托、资管等取数口径
    政府债券（国债）：债券产品分类为国债
    地方政府债券：债券产品分类为地方政府债
    央行票据、政府机构债券和政策性金融债：债券产品分类为政策性银行
    非金融企业债券 ：债券产品分类为企业债,公司债,短期融资券,超短期融资券,中期票据,项目收益债券
    商业性金融债券：债券产品分类为非银行金融债,二级资本工具,商业银行,保险公司资本补充债
    外国债券：债券产品种类为外国债券
    注意：如果后期债券产品分类有新增的情况，需修改对应指标限制条件
    */

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '投资业务+债券信息中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP_INVEST_BOND_INFO_G1102
    (DATA_DATE, ORG_NUM, SUBJECT_CD,FIVE_TIER_CLS, PRINCIPAL_BALANCE, STOCK_PRO_TYPE, INVEST_TYP, ISSU_ORG, STOCK_ASSET_TYPE,
     ISSUER_INLAND_FLG, JZJE, IN_OFF_FLG, GL_ITEM_CODE, ACCRUAL, ACCOUNTANT_TYPE,COLLBL_INT_FINAL_RESLT,INT_FINAL_RESLT,BOOK_TYPE,DC_DATE)
      SELECT 
           I_DATADATE AS DATA_DATE, --数据日期
           A.ORG_NUM AS ORG_NUM, --机构号
           A.SUBJECT_CD AS SUBJECT_CD,
           C.FIVE_TIER_CLS AS FIVE_TIER_CLS, --减值五级分类
           NVL(A.PRINCIPAL_BALANCE, 0) * U.CCY_RATE AS PRINCIPAL_BALANCE, --剩余本金
           B.STOCK_PRO_TYPE AS STOCK_PRO_TYPE, --产品分类
           A.INVEST_TYP AS INVEST_TYP, --投资业务品种
           B.ISSU_ORG AS ISSU_ORG, --发行方式
           B.STOCK_ASSET_TYPE AS STOCK_ASSET_TYPE, --资产证券化分类
           B.ISSUER_INLAND_FLG AS ISSUER_INLAND_FLG, --发行主体境内境外标志
           --A.GL_ITEM_CODE IN ('11010302', '11010303', '11010502')
           CASE
              WHEN SUBSTR(A.GL_ITEM_CODE,1,4) = '1101' THEN 0  --交易性金融资产 不取减值数据
              ELSE (NVL(C.PRIN_FINAL_RESLT, 0) + NVL(C.OFBS_FINAL_RESLT, 0)) * U.CCY_RATE
           END AS JZJE,
           A.IN_OFF_FLG AS IN_OFF_FLG, --表内表外标志
           A.GL_ITEM_CODE AS GL_ITEM_CODE, --科目
           --A.ACCRUAL AS ACCRUAL, --利息
           CASE
             WHEN A.ORG_NUM = '009817' THEN NVL(A.ACCRUAL,0) + NVL(A.QTYSK,0)
             ELSE NVL(A.ACCRUAL,0)
           END AS ACCRUAL, --利息
           A.ACCOUNTANT_TYPE AS ACCOUNTANT_TYPE, --会计分类
           CASE
              WHEN SUBSTR(A.GL_ITEM_CODE,1,4) = '1101' THEN 0
              ELSE (NVL(C.COLLBL_INT_FINAL_RESLT, 0)) * U.CCY_RATE
           END AS COLLBL_INT_FINAL_RESLT,
           C.INT_FINAL_RESLT AS INT_FINAL_RESLT,
           A.BOOK_TYPE AS BOOK_TYPE, --账户种类
           A.DC_DATE AS DC_DATE --代偿期
        FROM CBRC_V_PUB_FUND_INVEST A --投资业务信息表 A
        LEFT JOIN SMTMODS_L_AGRE_BOND_INFO B --债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_TMP_ASSET_DEVALUE C --资产减值准备
          ON C.ACCT_NUM = A.ACCT_NUM
         AND NVL(A.ACCT_NO,'&') = NVL(C.ACCT_ID,'&') --[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题] &处理有空值关联不上情况
         AND A.GL_ITEM_CODE = C.PRIN_SUBJ_NO
         AND A.ORG_NUM = C.RECORD_ORG
         AND C.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND NVL(A.PRINCIPAL_BALANCE, 0) <> 0;
    COMMIT;

    --==============================================================================================
    --2.国债 五级分类 + 逾期  G11_2_2..F
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '2.国债 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_2..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_2..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_2..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_2..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_2..H.2016'
             END AS ITEM_NUM, --指标号
             SUM(NVL(A.PRINCIPAL_BALANCE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00' --债券
         AND A.STOCK_PRO_TYPE = 'A'
         AND A.ISSU_ORG = 'A01'
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM, --机构号
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_2..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_2..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_2..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_2..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_2..H.2016'
                END;
    COMMIT;

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             'G11_2_2..I.2019' AS ITEM_NUM, --指标号
             SUM(NVL(A.PRINCIPAL_BALANCE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00' --债券
         AND A.STOCK_PRO_TYPE = 'A'
         AND A.ISSU_ORG = 'A01'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         --AND A.FIVE_TIER_CLS IN ('03', '04', '05')
         AND A.DC_DATE < 0
       GROUP BY A.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --2.2减值准备 五级分类 + 逾期 G11_2_2.2.F
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '2.2减值准备 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' THEN
                'G11_2_2.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_2.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_2.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_2.2.G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_2.2.H.2016'
             END AS ITEM_NUM, --指标号
             SUM(NVL(A.JZJE, 0)) ITEM_VALUE
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00' --债券
         AND A.STOCK_PRO_TYPE = 'A'
         AND A.ISSU_ORG = 'A01'
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.DATA_DATE = I_DATADATE
         AND NVL(A.PRINCIPAL_BALANCE, 0) <> 0
       GROUP BY A.ORG_NUM, --机构号
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' THEN
                   'G11_2_2.2.C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_2.2.D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_2.2.F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_2.2.G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_2.2.H.2016'
                END;
    COMMIT;

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             'G11_2_2.2.I.2019' AS ITEM_NUM, --指标号
             SUM(NVL(A.JZJE, 0)) ITEM_VALUE
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00' --债券
         AND A.STOCK_PRO_TYPE = 'A'
         AND A.ISSU_ORG = 'A01'
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND NVL(A.PRINCIPAL_BALANCE, 0) <> 0
         --AND A.FIVE_TIER_CLS IN ('03', '04', '05')
         AND A.DC_DATE < 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --3.地方政府债券 五级分类 + 逾期  G11_2_3..F
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '3.地方政府债券 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_3..C.2016'
               WHEN A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_3..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_3..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_3..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_3..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_3..H.2016'
             END AS ITEM_NUM, --指标号
             SUM(NVL(A.PRINCIPAL_BALANCE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.STOCK_PRO_TYPE = 'A'
         AND A.ISSU_ORG = 'A02'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_3..C.2016'
                  WHEN A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_3..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_3..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_3..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_3..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_3..H.2016'
                END;
    COMMIT;

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             'G11_2_3..I.2019' AS ITEM_NUM, --指标号
             SUM(NVL(A.PRINCIPAL_BALANCE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.STOCK_PRO_TYPE = 'A'
         AND A.ISSU_ORG = 'A02'
         AND A.BOOK_TYPE = '2' --银行账薄
         --AND A.FIVE_TIER_CLS IN ('03', '04', '05')
         AND A.DC_DATE < 0
         AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --3.2减值准备 五级分类 + 逾期 G11_2_3.2.F
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '3.2减值准备 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102  
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' THEN
                'G11_2_3.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_3.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_3.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_3.2.G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_3.2.H.2016'
             END AS ITEM_NUM, --指标号
             SUM(NVL(A.JZJE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.STOCK_PRO_TYPE = 'A'
         AND A.ISSU_ORG = 'A02'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' THEN
                   'G11_2_3.2.C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_3.2.D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_3.2.F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_3.2.G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_3.2.H.2016'
                END;
    COMMIT;


    INSERT  INTO  CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             'G11_2_3.2.I.2019' AS ITEM_NUM, --指标号
             SUM((NVL(A.JZJE, 0))) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.STOCK_PRO_TYPE = 'A'
         AND A.ISSU_ORG = 'A02'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.DATA_DATE = I_DATADATE
         --AND A.FIVE_TIER_CLS IN ('03', '04', '05')
         AND A.DC_DATE < 0
       GROUP BY A.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --4.央行票据、政府机构债券和政策性金融债 五级分类 + 逾期  G11_2_4..F
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '4.央行票据、政府机构债券和政策性金融债 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_4..C.2016'
               WHEN A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_4..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_4..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_4..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_4..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_4..H.2016'
             END AS ITEM_NUM, --指标号
             SUM(NVL(A.PRINCIPAL_BALANCE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND ((SUBSTR(A.STOCK_PRO_TYPE, 1, 1) = 'B' AND A.ISSU_ORG = 'D01') OR
             (A.STOCK_PRO_TYPE LIKE 'C%' AND A.ISSU_ORG = 'D02') OR
             (SUBSTR(A.STOCK_PRO_TYPE, 1, 1) IN ('C', 'D') AND
             A.ISSU_ORG LIKE 'B%'))
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.DATA_DATE = I_DATADATE
      GROUP BY A.ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_4..C.2016'
               WHEN A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_4..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_4..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_4..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_4..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_4..H.2016'
             END
      ;
    COMMIT;

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102  
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM AS ORG_NUM, --机构号
             'G11_2_4..I.2019' AS ITEM_NUM, --指标号
             SUM(NVL(A.PRINCIPAL_BALANCE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND ((SUBSTR(A.STOCK_PRO_TYPE, 1, 1) = 'B' AND A.ISSU_ORG = 'D01') OR
             (A.STOCK_PRO_TYPE LIKE 'C%' AND A.ISSU_ORG = 'D02') OR
             (SUBSTR(A.STOCK_PRO_TYPE, 1, 1) IN ('C', 'D') AND
             A.ISSU_ORG LIKE 'B%'))
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         --AND A.FIVE_TIER_CLS IN ('03','04','05')
         AND A.DC_DATE < 0
       GROUP BY A.ORG_NUM
      ;
    COMMIT;


    --==============================================================================================
    --4.2减值准备 五级分类 + 逾期 G11_2_4.2.F
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '4.2减值准备 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE,--报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' THEN
                'G11_2_4.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_4.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_4.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_4.2.G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_4.2.H.2016'
             END AS ITEM_NUM, --指标号
             SUM(NVL(A.JZJE,0)) AS COLLECT_VAL --指标值
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND ((SUBSTR(A.STOCK_PRO_TYPE, 1, 1) = 'B' AND A.ISSU_ORG = 'D01') OR
             (A.STOCK_PRO_TYPE LIKE 'C%' AND A.ISSU_ORG = 'D02') OR
             (SUBSTR(A.STOCK_PRO_TYPE, 1, 1) IN ('C', 'D') AND
             A.ISSU_ORG LIKE 'B%'))
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' THEN
                   'G11_2_4.2.C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_4.2.D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_4.2.F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_4.2.G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_4.2.H.2016'
                END;
    COMMIT;

    INSERT   INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE,--报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
             A.ORG_NUM AS ORG_NUM, --机构号
             'G11_2_4.2.I.2019'  AS ITEM_NUM, --指标号
             SUM(NVL(A.JZJE,0))  AS COLLECT_VAL --指标值
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND ((SUBSTR(A.STOCK_PRO_TYPE, 1, 1) = 'B' AND A.ISSU_ORG = 'D01') OR
             (A.STOCK_PRO_TYPE LIKE 'C%' AND A.ISSU_ORG = 'D02') OR
             (SUBSTR(A.STOCK_PRO_TYPE, 1, 1) IN ('C', 'D') AND
             A.ISSU_ORG LIKE 'B%'))
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         --AND A.FIVE_TIER_CLS IN ('03','04','05')
         AND A.DC_DATE < 0
       GROUP BY A.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --5.商业性金融债券 五级分类 + 逾期  G11_2_6..F
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '5.商业性金融债券 五级分类 + 逾期 ';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       CASE
         WHEN A.FIVE_TIER_CLS = '01' THEN
          'G11_2_6..C.2016'
         WHEN A.FIVE_TIER_CLS IS NULL THEN
          'G11_2_6..C.2016'
         WHEN A.FIVE_TIER_CLS = '02' THEN
          'G11_2_6..D.2016'
         WHEN A.FIVE_TIER_CLS = '03' THEN
          'G11_2_6..F.2016'
         WHEN A.FIVE_TIER_CLS = '04' THEN
          'G11_2_6..G.2016'
         WHEN A.FIVE_TIER_CLS = '05' THEN
          'G11_2_6..H.2016'
       END AS ITEM_NUM, --指标号
       SUM(NVL(A.PRINCIPAL_BALANCE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
            --20221221 shiyu  与G31保持一致
         AND (A.STOCK_PRO_TYPE LIKE 'C%' AND A.ISSU_ORG IN ('D03', 'D04', 'D05', 'D06', 'D07'))
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM, --机构号
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' THEN
                   'G11_2_6..C.2016'
                  WHEN A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_6..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_6..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_6..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_6..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_6..H.2016'
                END;
    COMMIT;

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             'G11_2_5..I.2019' AS ITEM_NUM, --指标号
             SUM(NVL(A.PRINCIPAL_BALANCE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
            --20221221 shiyu  与G31保持一致
         AND (A.STOCK_PRO_TYPE LIKE 'C%' AND A.ISSU_ORG IN ('D03', 'D04', 'D05', 'D06', 'D07'))
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         --AND A.FIVE_TIER_CLS IN ('03','04','05')
         AND A.DC_DATE < 0
        GROUP BY A.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --5.2减值准备 五级分类 + 逾期 G11_2_6.2.F
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '5.2减值准备 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' THEN
                'G11_2_6.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_6.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_6.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_6.2.G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_6.2.H.2016'
             END AS ITEM_NUM, --指标号
             SUM(NVL(A.JZJE, 0)) ITEM_VALUE
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
            --20221221 shiyu  与G31保持一致
         AND (A.STOCK_PRO_TYPE LIKE 'C%' AND
             A.ISSU_ORG IN ('D03', 'D04', 'D05', 'D06', 'D07'))
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.DATA_DATE = I_DATADATE
      GROUP BY A.ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' THEN
                'G11_2_6.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_6.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_6.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_6.2.G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_6.2.H.2016'
             END;
    COMMIT;

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM AS ORG_NUM, --机构号
             'G11_2_5.2.I.2019'  AS ITEM_NUM, --指标号
             SUM(NVL(A.JZJE, 0)) ITEM_VALUE
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
            --20221221 shiyu  与G31保持一致
         AND (A.STOCK_PRO_TYPE LIKE 'C%' AND
             A.ISSU_ORG IN ('D03', 'D04', 'D05', 'D06', 'D07'))
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         --AND A.FIVE_TIER_CLS IN ('03','04','05')
         AND A.DC_DATE < 0
       GROUP BY A.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --6.非金融企业债券 五级分类 + 逾期  G11_2_5..F
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '6.非金融企业债券 五级分类 + 逾期 ';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       CASE
         WHEN A.FIVE_TIER_CLS = '01' THEN
          'G11_2_5..C.2016'
         WHEN A.FIVE_TIER_CLS IS NULL THEN
          'G11_2_5..C.2016'
         WHEN A.FIVE_TIER_CLS = '02' THEN
          'G11_2_5..D.2016'
         WHEN A.FIVE_TIER_CLS = '03' THEN
          'G11_2_5..F.2016'
         WHEN A.FIVE_TIER_CLS = '04' THEN
          'G11_2_5..G.2016'
         WHEN A.FIVE_TIER_CLS = '05' THEN
          'G11_2_5..H.2016'
       END AS ITEM_NUM, --指标号
       SUM(NVL(A.PRINCIPAL_BALANCE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND (SUBSTR(A.STOCK_PRO_TYPE, 1, 1) = 'D' AND A.ISSU_ORG LIKE 'C%')
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM, --机构号
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' THEN
                   'G11_2_5..C.2016'
                  WHEN A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_5..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_5..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_5..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_5..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_5..H.2016'
                END;
    COMMIT;

    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       'G11_2_6..I.2019' AS ITEM_NUM, --指标号
       SUM(NVL(A.PRINCIPAL_BALANCE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND (SUBSTR(A.STOCK_PRO_TYPE, 1, 1) = 'D' AND A.ISSU_ORG LIKE 'C%')
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND (A.DC_DATE < 0 OR A.SUBJECT_CD = 'X0003120B2700001')  -- 18华阳经贸CP001 特殊处理指定放在逾期
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --6.2减值准备 五级分类 + 逾期 G11_2_5.2.F
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '6.2减值准备 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )

      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' THEN
                'G11_2_5.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_5.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_5.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_5.2.G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_5.2.H.2016'
             END AS ITEM_NUM, --指标号
             SUM(NVL(A.JZJE, 0)) AS COLLECT_VAL --指标值
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND (SUBSTR(A.STOCK_PRO_TYPE, 1, 1) = 'D' AND A.ISSU_ORG LIKE 'C%')
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' THEN
                   'G11_2_5.2.C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_5.2.D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_5.2.F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_5.2.G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_5.2.H.2016'
                END;
    COMMIT;

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             'G11_2_6.2.I.2019'  AS ITEM_NUM, --指标号
             SUM(NVL(A.JZJE, 0)) AS COLLECT_VAL --指标值
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND (SUBSTR(A.STOCK_PRO_TYPE, 1, 1) = 'D' AND A.ISSU_ORG LIKE 'C%')
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND (A.DC_DATE < 0 OR A.SUBJECT_CD = 'X0003120B2700001')  -- 18华阳经贸CP001 特殊处理指定放在逾期
       GROUP BY A.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --7.资产支持证券 五级分类 + 逾期  G11_2_7..F
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '7.资产支持证券 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       CASE
         WHEN A.FIVE_TIER_CLS = '01' THEN
          'G11_2_7..C.2019'
         WHEN A.FIVE_TIER_CLS IS NULL THEN
          'G11_2_7..C.2019'
         WHEN A.FIVE_TIER_CLS = '02' THEN
          'G11_2_7..D.2019'
         WHEN A.FIVE_TIER_CLS = '03' THEN
          'G11_2_7..F.2019'
         WHEN A.FIVE_TIER_CLS = '04' THEN
          'G11_2_7..G.2019'
         WHEN A.FIVE_TIER_CLS = '05' THEN
          'G11_2_7..H.2019'
       END AS ITEM_NUM, --指标号
       SUM(NVL(A.PRINCIPAL_BALANCE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND A.STOCK_ASSET_TYPE = 'A'
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.IN_OFF_FLG = '1'
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM, --机构号
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' THEN
                   'G11_2_7..C.2019'
                  WHEN A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_7..C.2019'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_7..D.2019'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_7..F.2019'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_7..G.2019'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_7..H.2019'
                END;
    COMMIT;

    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       'G11_2_7..I.2019' AS ITEM_NUM, --指标号
       SUM(NVL(A.PRINCIPAL_BALANCE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND A.STOCK_ASSET_TYPE = 'A'
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.IN_OFF_FLG = '1'
         AND A.BOOK_TYPE = '2' --银行账薄
         --AND A.FIVE_TIER_CLS IN ('03', '04', '05')
         AND A.DC_DATE < 0
       GROUP BY A.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --7.2减值准备 五级分类 + 逾期 G11_2_7.2.F
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '7.2减值准备 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       CASE
         WHEN A.FIVE_TIER_CLS = '01' THEN
          'G11_2_7.2.C.2019'
         WHEN A.FIVE_TIER_CLS IS NULL THEN
          'G11_2_7.2.C.2019'
         WHEN A.FIVE_TIER_CLS = '02' THEN
          'G11_2_7.2.D.2019'
         WHEN A.FIVE_TIER_CLS = '03' THEN
          'G11_2_7.2.F.2019'
         WHEN A.FIVE_TIER_CLS = '04' THEN
          'G11_2_7.2.G.2019'
         WHEN A.FIVE_TIER_CLS = '05' THEN
          'G11_2_7.2.H.2019'
       END AS ITEM_NUM, --指标号
       SUM(NVL(A.JZJE, 0)) AS COLLECT_VAL --指标值
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND A.STOCK_ASSET_TYPE = 'A'
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.IN_OFF_FLG = '1'
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM, --机构号
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' THEN
                   'G11_2_7.2.C.2019'
                  WHEN A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_7.2.C.2019'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_7.2.D.2019'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_7.2.F.2019'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_7.2.G.2019'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_7.2.H.2019'
                END;
    COMMIT;

    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       'G11_2_7.2.I.2019' AS ITEM_NUM, --指标号
       SUM(NVL(A.JZJE, 0)) AS COLLECT_VAL --指标值
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND A.STOCK_ASSET_TYPE = 'A'
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.IN_OFF_FLG = '1'
         AND A.BOOK_TYPE = '2' --银行账薄
         --AND A.FIVE_TIER_CLS IN ('03', '04', '05')
         AND A.DC_DATE < 0
       GROUP BY A.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --8.外国债券 五级分类 + 逾期  G11_2_8..F
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '8.外国债券 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' THEN
                'G11_2_8..C.2019'
               WHEN A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_8..C.2019'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_8..D.2019'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_8..F.2019'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_8..G.2019'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_8..H.2019'
             END AS ITEM_NUM, --指标号
             SUM(NVL(A.PRINCIPAL_BALANCE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND A.STOCK_PRO_TYPE LIKE 'F%'
         AND A.ISSUER_INLAND_FLG = 'N'
         AND A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.IN_OFF_FLG = '1'
         AND (A.STOCK_ASSET_TYPE <> 'A' OR A.STOCK_ASSET_TYPE IS NULL)
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' THEN
                   'G11_2_8..C.2019'
                  WHEN A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_8..C.2019'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_8..D.2019'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_8..F.2019'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_8..G.2019'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_8..H.2019'
                END;
    COMMIT;

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM AS ORG_NUM, --机构号
             'G11_2_8..I.2019'AS ITEM_NUM, --指标号
             SUM(NVL(A.PRINCIPAL_BALANCE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND A.STOCK_PRO_TYPE LIKE 'F%'
         AND A.ISSUER_INLAND_FLG = 'N'
         AND A.DATA_DATE = I_DATADATE
         AND A.IN_OFF_FLG = '1'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND (A.STOCK_ASSET_TYPE <> 'A' OR A.STOCK_ASSET_TYPE IS NULL)
         --AND A.FIVE_TIER_CLS IN ('03','04','05')
         AND A.DC_DATE < 0
       GROUP BY A.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --8.2减值准备 五级分类 + 逾期 G11_2_8.2.F
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '8.2减值准备 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' THEN
                'G11_2_8.2.C.2019'
               WHEN A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_8.2.C.2019'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_8.2.D.2019'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_8.2.F.2019'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_8.2.G.2019'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_8.2.H.2019'
             END AS ITEM_NUM, --指标号
             SUM(NVL(A.JZJE,0)) AS COLLECT_VAL --指标值
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND A.STOCK_PRO_TYPE LIKE 'F%'
         AND A.ISSUER_INLAND_FLG = 'N'
         AND A.DATA_DATE = I_DATADATE
         AND A.IN_OFF_FLG = '1'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND (A.STOCK_ASSET_TYPE <> 'A' OR A.STOCK_ASSET_TYPE IS NULL)
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' THEN
                   'G11_2_8.2.C.2019'
                  WHEN A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_8.2.C.2019'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_8.2.D.2019'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_8.2.F.2019'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_8.2.G.2019'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_8.2.H.2019'
                END;
    COMMIT;

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM AS ORG_NUM, --机构号
             'G11_2_8.2.I.2019' AS ITEM_NUM, --指标号
             SUM(NVL(A.JZJE,0)) AS COLLECT_VAL --指标值
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND A.STOCK_PRO_TYPE LIKE 'F%'
         AND A.ISSUER_INLAND_FLG = 'N'
         AND A.DATA_DATE = I_DATADATE
         AND A.IN_OFF_FLG = '1'
         AND A.BOOK_TYPE = '2' --银行账薄
         --AND A.FIVE_TIER_CLS IN ('03','04','05')
         AND A.DC_DATE < 0
         AND (A.STOCK_ASSET_TYPE <> 'A' OR A.STOCK_ASSET_TYPE IS NULL)
       GROUP BY A.ORG_NUM;
    COMMIT;


    --==============================================================================================
    --资金往来中间表
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '资金往来中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --[2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1302拆出资金本金
    INSERT INTO CBRC_TMP_FUND_MMFUND_G1102
    (DATA_DATE, ORG_NUM, ACCT_NUM, REP_NUM, FIVE_TIER_CLS, BALANCE, ACCRUAL, JZJE, GL_ITEM_CODE, TAG,COLLBL_INT_FINAL_RESLT,INT_FINAL_RESLT,BOOK_TYPE,MATURE_DATE)
    SELECT 
         I_DATADATE AS DATA_DATE,
         A.ORG_NUM AS ORG_NUM,
         A.ACCT_NUM AS ACCT_NUM,
         A.REF_NUM AS REP_NUM,
         C.FIVE_TIER_CLS AS FIVE_TIER_CLS,
         NVL(A.BALANCE, 0) * U.CCY_RATE AS BALANCE,
         NVL(A.ACCRUAL, 0) * U.CCY_RATE AS ACCRUAL,
         --(NVL(C.PRIN_FINAL_RESLT, 0) + NVL(C.OFBS_FINAL_RESLT, 0)) * U.CCY_RATE AS JZJE,
         CASE
            WHEN SUBSTR(A.GL_ITEM_CODE,1,4) = '1101' THEN 0
            ELSE (NVL(C.PRIN_FINAL_RESLT, 0) + NVL(C.OFBS_FINAL_RESLT, 0)) * U.CCY_RATE
         END AS JZJE,
         A.GL_ITEM_CODE AS GL_ITEM_CODE,
         CASE
           WHEN A.GL_ITEM_CODE IN ('10110101','10110102','10110103','10110104','10110105','10110106','10110107',
                                   '10110108','10110109','10110110','10110111')
                                   OR SUBSTR(A.GL_ITEM_CODE, 1, 4) = '1031'
                                   OR SUBSTR(A.GL_ITEM_CODE, 1, 6) = '101102'
             THEN '存放同业'
           WHEN A.GL_ITEM_CODE IN ('13020101','13020102','13020103','13020104','13020105','13020106')
             THEN '拆放同业'
         END AS TAG,
         CASE
            WHEN SUBSTR(A.GL_ITEM_CODE,1,4) = '1101' THEN 0
            ELSE (NVL(C.COLLBL_INT_FINAL_RESLT, 0)) * U.CCY_RATE
         END AS COLLBL_INT_FINAL_RESLT,
         C.INT_FINAL_RESLT AS INT_FINAL_RESLT,
         A.BOOK_TYP AS BOOK_TYP,
         A.MATURE_DATE
      FROM CBRC_V_PUB_FUND_MMFUND A --资金往来信息表
      LEFT JOIN CBRC_TMP_ASSET_DEVALUE C --资产减值准备
        ON C.ACCT_NUM = A.REF_NUM
       AND A.GL_ITEM_CODE = C.PRIN_SUBJ_NO
       AND A.ORG_NUM = C.RECORD_ORG
       AND C.DATA_DATE = I_DATADATE
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = I_DATADATE --正式使用替换为 D_DATADATE_CCY
       AND U.BASIC_CCY = A.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
       AND U.DATA_DATE = I_DATADATE
     WHERE A.DATA_DATE = I_DATADATE
       --AND A.ORG_NUM IN ('009804', '009816', '009817', '009820')
          --存放同业
       AND (A.GL_ITEM_CODE IN ('10110101',
                               '10110102',
                               '10110103',
                               '10110104',
                               '10110105',
                               '10110106',
                               '10110107',
                               '10110108',
                               '10110109',
                               '10110110',
                               '10110111') OR
           SUBSTR(A.GL_ITEM_CODE, 1, 4) = '1031' OR
           SUBSTR(A.GL_ITEM_CODE, 1, 6) = '101102' OR
           --拆放同业
           --AND A.Gl_Item_Code = '13020104'
           --ALTER BY WJB 20221215 根据李姐提供的口径 修改该指标取自如下新科目
           A.GL_ITEM_CODE IN ('13020101',
                               '13020102',
                               '13020103',
                               '13020104',
                               '13020105',
                               '13020106')
            )
       --AND A.BALANCE <> 0 --不能限制此条件 会有本金为零有利息的数据，并且利息有减值
       ;
    COMMIT;

    --==============================================================================================
    --9.存放同业 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '9.存放同业 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_3..C' --存放同业正常类
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_3..D' --存放同业关注类
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_3..F' --存放同业次级类
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_3..G' --存放同业可疑类
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_3..H' --存放同业损失类
             END COLLECT_TYPE,
             SUM(A.BALANCE) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金往来信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.TAG = '存放同业'
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_3..C' --存放同业正常类
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_3..D' --存放同业关注类
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_3..F' --存放同业次级类
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_3..G' --存放同业可疑类
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_3..H' --存放同业损失类
                END,
                ORG_NUM;
   COMMIT;

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM,
             'G11_2_11..I.2019' AS COLLECT_TYPE,
             SUM(A.BALANCE) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金往来信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.TAG = '存放同业'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.MATURE_DATE - I_DATADATE < 0
         --AND A.FIVE_TIER_CLS IN ('03','04','05')
       GROUP BY A.ORG_NUM;
   COMMIT;


    --==============================================================================================
    --9.2减值准备 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '9.2减值准备 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_3.2.C' --存放同业正常类
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_3.2.D' --存放同业关注类
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_3.2.F' --存放同业次级类
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_3.2.G' --存放同业可疑类
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_3.2.H' --存放同业损失类
             END COLLECT_TYPE,
             SUM(NVL(A.JZJE, 0)) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金往来信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.TAG = '存放同业'
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_3.2.C' --存放同业正常类
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_3.2.D' --存放同业关注类
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_3.2.F' --存放同业次级类
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_3.2.G' --存放同业可疑类
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_3.2.H' --存放同业损失类
                END,
                ORG_NUM;
    COMMIT;

    INSERT   INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM,
             'G11_2_11.2.I.2019'  COLLECT_TYPE,
             SUM(NVL(A.JZJE, 0)) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金往来信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.TAG = '存放同业'
         --AND A.FIVE_TIER_CLS IN ('03','04','05')
         AND A.MATURE_DATE - I_DATADATE < 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY ORG_NUM;

    --==============================================================================================
    --10.拆放同业 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '10.拆放同业 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT   INTO CBRC_PUB_DATA_COLLECT_G1102  
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_10..C.2016' --拆放同业正常类
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_10..D.2016' --拆放同业关注类
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_10..F.2016' --拆放同业次级类
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_10..G.2016' --拆放同业可疑类
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_10..H.2016' --拆放同业损失类
             END COLLECT_TYPE,
             SUM(A.BALANCE) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金交易信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.TAG = '拆放同业'
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_10..C.2016' --拆放同业正常类
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_10..D.2016' --拆放同业关注类
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_10..F.2016' --拆放同业次级类
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_10..G.2016' --拆放同业可疑类
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_10..H.2016' --拆放同业损失类
                END,
                ORG_NUM;
    COMMIT;


     INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM,
             'G11_2_12..I.2019'  COLLECT_TYPE,
             SUM(A.BALANCE) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_MMFUND_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.TAG = '拆放同业'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.MATURE_DATE - I_DATADATE < 0
         --AND A.FIVE_TIER_CLS IN ( '03','04','05')
       GROUP BY ORG_NUM;

    --==============================================================================================
    --10.2减值准备 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '10.2减值准备 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' THEN
                'G11_2_10.2.C.2016' --拆放同业减值准备正常类
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_10.2.D.2016' --拆放同业减值准备正常类
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_10.2.F.2016' --拆放同业减值准备正常类
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_10.2.G.2016' --拆放同业减值准备正常类
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_10.2.H.2016' --拆放同业减值准备正常类
             END,
             SUM(NVL(A.JZJE,0)) BALANCE
        FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金交易信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.TAG = '拆放同业'
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' THEN
                   'G11_2_10.2.C.2016' --拆放同业减值准备正常类
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_10.2.D.2016' --拆放同业减值准备正常类
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_10.2.F.2016' --拆放同业减值准备正常类
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_10.2.G.2016' --拆放同业减值准备正常类
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_10.2.H.2016' --拆放同业减值准备正常类
                END;
    COMMIT;

     INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM,
             'G11_2_12.2.I.2019',
             SUM(NVL(A.JZJE,0)) BALANCE
        FROM CBRC_TMP_FUND_MMFUND_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.TAG = '拆放同业'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.MATURE_DATE - I_DATADATE < 0
         --AND A.FIVE_TIER_CLS IN ('03','04','05')
       GROUP BY A.ORG_NUM;
      COMMIT;


    --==============================================================================================
    --回购中间表
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '回购中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --  [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 009801清算中心外币业务1111买入返售本金
    -- 咨询外汇系统：不会存在逾期，到期的时候系统会自动记账，不需要业务手动做到期的业务，因此到期日期可以大于当前日期，与其他机构统一规则
    INSERT INTO CBRC_TMP_FUND_REPURCHASE_G1102
      (DATA_DATE, ORG_NUM, REP_NUM, FIVE_TIER_CLS, BALANCE, ACCRUAL, JZJE, GL_ITEM_CODE, BUSI_TYPE, ASS_TYPE,GENERAL_RESERVE, LOAN_GRADE_CD, END_DT,
       COLLBL_INT_FINAL_RESLT,INT_FINAL_RESLT,BOOK_TYPE)
      SELECT 
           I_DATADATE AS DATA_DATE,
           T.ORG_NUM AS ORG_NUM,
           T.REF_NUM AS REF_NUM,
           C.FIVE_TIER_CLS AS FIVE_TIER_CLS,
           NVL(T.BALANCE,0) * U.CCY_RATE AS BALANCE,
           NVL(T.ACCRUAL,0) * U.CCY_RATE AS ACCRUAL,
           --(NVL(C.PRIN_FINAL_RESLT, 0) + NVL(C.OFBS_FINAL_RESLT, 0)) * U.CCY_RATE AS JZJE,
           CASE
             WHEN SUBSTR(T.GL_ITEM_CODE,1,4) = '1101' THEN 0
             ELSE (NVL(C.PRIN_FINAL_RESLT, 0) + NVL(C.OFBS_FINAL_RESLT, 0)) * U.CCY_RATE
           END AS JZJE,
           T.GL_ITEM_CODE AS GL_ITEM_CODE,
           T.BUSI_TYPE AS BUSI_TYPE,
           T.ASS_TYPE AS ASS_TYPE,
           T.GENERAL_RESERVE AS GENERAL_RESERVE,
           B.LOAN_GRADE_CD AS LOAN_GRADE_CD,
           T.END_DT AS END_DT,
           CASE
            WHEN SUBSTR(T.GL_ITEM_CODE,1,4) = '1101' THEN 0
            ELSE (NVL(C.COLLBL_INT_FINAL_RESLT, 0)) * U.CCY_RATE
           END AS COLLBL_INT_FINAL_RESLT,
           C.INT_FINAL_RESLT AS INT_FINAL_RESLT,
           T.BOOK_TYPE AS BOOK_TYPE
        FROM CBRC_V_PUB_FUND_REPURCHASE T
        LEFT JOIN CBRC_TMP_ASSET_DEVALUE C --资产减值准备
          ON T.REF_NUM = C.ACCT_NUM
         AND T.ORG_NUM = C.RECORD_ORG
         AND PRIN_SUBJ_NO LIKE '1111%'
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON T.ACCT_NUM = B.LOAN_NUM
         AND T.DATA_DATE = B.DATA_DATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.END_DT >= I_DATADATE
         AND T.BALANCE <> 0
      ;
    COMMIT;


    --==============================================================================================
    --11.金融机构间买入返售资产 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '11.金融机构间买入返售资产 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      --取买入返售（债券+票据）的剩余本金，默认正常类
      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             'G11_2_11..C.2016' AS ITEM_NUM, --指标号
             SUM(A.BALANCE) AS COLLECT_VAL --指标值，A.余额（折人民币）
        FROM CBRC_TMP_FUND_REPURCHASE_G1102 A --回购信息表
       WHERE A.BUSI_TYPE LIKE '1%'
         AND A.BOOK_TYPE = '2' --银行账薄
         --AND A.BUSI_TYPE IN ('101', '102') --101质押式买入返售 102买断式买入返售  201质押式卖出回购 202买断式卖出回购
         --AND A.ASS_TYPE IN ('1', '3') --1债券 3票据
         AND A.DATA_DATE = I_DATADATE
         GROUP BY A.ORG_NUM;
    COMMIT;

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT T.ORG_NUM,
             'G11_2_13..I.2019' COLLECT_TYPE,
             SUM(T.BALANCE) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_REPURCHASE_G1102 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.BOOK_TYPE = '2' --银行账薄
         AND T.BUSI_TYPE LIKE '1%'
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') --五级分类为次级、可疑、损失
         AND T.END_DT < D_DATADATE_CCY
       GROUP BY T.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --11.2减值准备 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '11.2减值准备 五级分类 + 逾期 ';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS is null THEN
                'G11_2_11.2.C.2016' --13.金融机构间买入返售资产减值准备正常类
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_11.2.D.2016' --13.金融机构间买入返售资产减值准备关注类
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_11.2.F.2016' --13.金融机构间买入返售资产减值准备次级类
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_11.2.G.2016' --13.金融机构间买入返售资产减值准备可疑类
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_11.2.H.2016' --13.金融机构间买入返售资产减值准备损失类
             END COLLECT_TYPE,
             SUM(NVL(A.JZJE, 0)) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_REPURCHASE_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.BUSI_TYPE LIKE '1%'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS is null THEN
                   'G11_2_11.2.C.2016' --13.金融机构间买入返售资产减值准备正常类
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_11.2.D.2016' --13.金融机构间买入返售资产减值准备关注类
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_11.2.F.2016' --13.金融机构间买入返售资产减值准备次级类
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_11.2.G.2016' --13.金融机构间买入返售资产减值准备可疑类
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_11.2.H.2016' --13.金融机构间买入返售资产减值准备损失类
                END;
    COMMIT;

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  T.ORG_NUM,
             'G11_2_13.2.I.2019' COLLECT_TYPE,
             SUM(T.GENERAL_RESERVE) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_REPURCHASE_G1102 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.BOOK_TYPE = '2' --银行账薄
         AND T.BUSI_TYPE LIKE '1%'
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') --五级分类为次级、可疑、损失
         AND T.END_DT < D_DATADATE_CCY
       GROUP BY T.ORG_NUM;
    COMMIT;


    --==============================================================================================
    --同业存单中间表
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '同业存单中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP_FUND_CDS_BAL_G1102
    (DATA_DATE, ORG_NUM, ACCT_NUM, CDS_NO, FIVE_TIER_CLS, PRINCIPAL_BALANCE, INTEREST_RECEIVABLE,
     JZJE, GL_ITEM_CODE,COLLBL_INT_FINAL_RESLT,INT_FINAL_RESLT,BOOK_TYPE,DC_DATE)
    SELECT 
         I_DATADATE AS DATA_DATE,
         A.ORG_NUM AS ORG_NUM,
         A.ACCT_NUM AS ACCT_NUM,
         A.CDS_NO AS CDS_NO,
         C.FIVE_TIER_CLS AS FIVE_TIER_CLS,
         NVL(A.PRINCIPAL_BALANCE, 0) * U.CCY_RATE AS PRINCIPAL_BALANCE,
         NVL(A.INTEREST_RECEIVABLE, 0) * U.CCY_RATE AS INTEREST_RECEIVABLE,
         --(NVL(C.PRIN_FINAL_RESLT, 0) + NVL(C.OFBS_FINAL_RESLT, 0)) * U.CCY_RATE AS JZJE,
         CASE
            WHEN SUBSTR(A.GL_ITEM_CODE,1,4) = '1101' THEN 0
            ELSE (NVL(C.PRIN_FINAL_RESLT, 0) + NVL(C.OFBS_FINAL_RESLT, 0)) * U.CCY_RATE
         END AS JZJE,
         A.GL_ITEM_CODE AS GL_ITEM_CODE,
         CASE
            WHEN SUBSTR(A.GL_ITEM_CODE,1,4) = '1101' THEN 0
            ELSE (NVL(C.COLLBL_INT_FINAL_RESLT, 0)) * U.CCY_RATE
         END AS COLLBL_INT_FINAL_RESLT,
         C.INT_FINAL_RESLT AS INT_FINAL_RESLT,
         A.BOOK_TYPE AS BOOK_TYPE,
         A.DC_DATE AS DC_DATE
      FROM SMTMODS_V_PUB_FUND_CDS_BAL A --存单投资与发行信息表
      LEFT JOIN CBRC_TMP_ASSET_DEVALUE C --资产减值准备
        --ON A.ACCT_NUM = C.BIZ_NO
        --ON SUBSTR(A.ACCT_NUM,1,INSTR(A.ACCT_NUM,'_')-1) = C.BIZ_NO
        --[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
        ON REPLACE(A.ACCT_NUM,'_','') = C.ACCT_NUM||C.ACCT_ID
       AND A.GL_ITEM_CODE = C.PRIN_SUBJ_NO
       AND A.ORG_NUM = C.RECORD_ORG --一个存单 对应多个机构
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = I_DATADATE
       AND U.BASIC_CCY = A.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
       AND U.DATA_DATE = I_DATADATE
     WHERE A.DATA_DATE = I_DATADATE
       AND A.STOCK_PRO_TYPE = 'A' --A同业存单 B大额存单
       AND A.PRODUCT_PROP = 'A' --A投资 B发行
       AND A.PRINCIPAL_BALANCE <> 0
    ;
    COMMIT;

    --==============================================================================================
    --12.购买同业存单 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '12.购买同业存单 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT   INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_12..C.2016' --14.购买同业存单正常类
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_12..D.2016' --14.购买同业存单关注类
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_12..F.2016' --14.购买同业存单次级类
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_12..G.2016' --14.购买同业存单可疑类
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_12..H.2016' --14.购买同业存单损失类
             END COLLECT_TYPE,
             SUM(A.PRINCIPAL_BALANCE) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_CDS_BAL_G1102 A --存单投资与发行信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_12..C.2016' --14.购买同业存单正常类
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_12..D.2016' --14.购买同业存单关注类
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_12..F.2016' --14.购买同业存单次级类
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_12..G.2016' --14.购买同业存单可疑类
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_12..H.2016' --14.购买同业存单损失类
                END;
    COMMIT;


    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM,
             'G11_2_14..I.2019' COLLECT_TYPE,
             SUM(A.PRINCIPAL_BALANCE) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_CDS_BAL_G1102 A --存单投资与发行信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.DC_DATE < 0
       GROUP BY A.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --12.2减值准备 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '12.2减值准备 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_12.2.C.2016' --14.购买同业存单正常类
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_12.2.D.2016' --14.购买同业存单关注类
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_12.2.F.2016' --14.购买同业存单次级类
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_12.2.G.2016' --14.购买同业存单可疑类
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_12.2.H.2016' --14.购买同业存单损失类
             END COLLECT_TYPE,
             SUM(NVL(A.JZJE, 0)) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_CDS_BAL_G1102 A --存单投资与发行信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_12.2.C.2016' --14.购买同业存单正常类
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_12.2.D.2016' --14.购买同业存单关注类
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_12.2.F.2016' --14.购买同业存单次级类
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_12.2.G.2016' --14.购买同业存单可疑类
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_12.2.H.2016' --14.购买同业存单损失类
                END;
    COMMIT;


    INSERT   INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM,
             'G11_2_14.2.I.2019'  COLLECT_TYPE,
             SUM(NVL(A.JZJE, 0)) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_CDS_BAL_G1102 A --存单投资与发行信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.DC_DATE < 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM;
    COMMIT;


    --==============================================================================================
    --资金+标的中间表
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '13.购买银行理财产品 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP_INVEST_OTHER_SUBJECT_G1102
    SELECT I_DATADATE AS DATA_DATE,
           T.ORG_NUM AS ORG_NUM,
           T.ACCT_NUM AS ACCT_NUM,
           T.GRADE AS GRADE,
           NVL(T.FACE_VAL, 0) * U.CCY_RATE AS FACE_VAL, --账面余额
           T1.SUBJECT_PRO_TYPE AS SUBJECT_PRO_TYPE,     --标的产品分类
           T.INVEST_TYP AS INVEST_TYP,
           NVL(T.MK_VAL, 0) * U.CCY_RATE AS MK_VAL,     --公允价值
           C.FIVE_TIER_CLS AS FIVE_TIER_CLS,
           --(NVL(C.PRIN_FINAL_RESLT, 0) + NVL(C.OFBS_FINAL_RESLT, 0)) * U.CCY_RATE AS JZJE, --减值金额
           CASE
             WHEN SUBSTR(T.GL_ITEM_CODE,1,4) = '1101' THEN 0
             ELSE (NVL(C.PRIN_FINAL_RESLT, 0) + NVL(C.OFBS_FINAL_RESLT, 0)) * U.CCY_RATE
           END AS JZJE,
           T.GL_ITEM_CODE AS GL_ITEM_CODE,
           NVL(T.ACCT_BAL, 0) * U.CCY_RATE AS ACCT_BAL, --持有仓位
           T1.PROTYPE_DIS AS PROTYPE_DIS,               --产品类型说明
           T1.FUNDS_TYPE AS FUNDS_TYPE,                 --基金细类
           NVL(T.ACCRUAL, 0) * U.CCY_RATE AS ACCRUAL,   --利息
           T.IN_OFF_FLG AS IN_OFF_FLG,                  --表内表外标志
           C.RECORD_ORG AS RECORD_ORG,
           C.COLLBL_INT_FINAL_RESLT AS COLLBL_INT_FINAL_RESLT,
           CASE
             WHEN SUBSTR(T.GL_ITEM_CODE,1,4) = '1101' THEN 0
             ELSE (NVL(C.INT_FINAL_RESLT, 0)) * U.CCY_RATE
           END AS INT_FINAL_RESLT,
           T1.ISSU_ORG_NAM AS ISSU_ORG_NAM,
           T.BOOK_TYPE AS BOOK_TYPE,
           T.ACCOUNTANT_TYPE AS ACCOUNTANT_TYPE,
           T.DC_DATE
      FROM CBRC_V_PUB_FUND_INVEST T
      LEFT JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO T1
        ON T.ACCT_NUM = T1.SUBJECT_CD
       AND T1.DATA_DATE = I_DATADATE
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = I_DATADATE
       AND U.BASIC_CCY = T.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
      LEFT JOIN CBRC_TMP_ASSET_DEVALUE C --资产减值准备
        ON T.ACCT_NUM = C.ACCT_NUM
       AND NVL(T.ACCT_NO,'&') = NVL(C.ACCT_ID,'&') --[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题] &处理有空值关联不上情况
       AND T.ORG_NUM = C.RECORD_ORG
     WHERE T.DATA_DATE = I_DATADATE
       ;
    COMMIT;

    --==============================================================================================
    --13.购买银行理财产品 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '13.购买银行理财产品 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT T.ORG_NUM,
             CASE
               WHEN (T.GRADE = '1' OR T.GRADE IS NULL) THEN
                'G11_2_13..C.2016' --正常类
               WHEN T.GRADE = '2' THEN
                'G11_2_13..D.2016' --关注类
               WHEN T.GRADE = '3' THEN
                'G11_2_13..F.2016' --次级类
               WHEN T.GRADE = '4' THEN
                'G11_2_13..G.2016' --可疑类
               WHEN T.GRADE = '5' THEN
                'G11_2_13..H.2016' --损失类
             END COLLECT_TYPE,
             SUM(NVL(T.FACE_VAL, 0)) AS COLLECT_VAL --取持有仓位的五级分类
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.INVEST_TYP = '05' --投资业务品种A0050 理财产品投资
         AND T.SUBJECT_PRO_TYPE = '0502' --标的产品分类G0024 非保本理财
         AND T.BOOK_TYPE = '2' --银行账薄
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN (T.GRADE = '1' OR T.GRADE IS NULL) THEN
                   'G11_2_13..C.2016' --正常类
                  WHEN T.GRADE = '2' THEN
                   'G11_2_13..D.2016' --关注类
                  WHEN T.GRADE = '3' THEN
                   'G11_2_13..F.2016' --次级类
                  WHEN T.GRADE = '4' THEN
                   'G11_2_13..G.2016' --可疑类
                  WHEN T.GRADE = '5' THEN
                   'G11_2_13..H.2016' --损失类
                END;
    COMMIT;


    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT T.ORG_NUM,
             'G11_2_15..I.2016' AS COLLECT_TYPE,
             SUM(NVL(T.FACE_VAL, 0)) AS COLLECT_VAL --取持有仓位的五级分类
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.INVEST_TYP = '05' --投资业务品种A0050 理财产品投资
         AND T.SUBJECT_PRO_TYPE = '0502' --标的产品分类G0024 非保本理财
         AND T.BOOK_TYPE = '2' --银行账薄
       GROUP BY T.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --13.2减值准备 五级分类 + 逾期  无
    --==============================================================================================



    --==============================================================================================
    --14.购买信托产品 五级分类 + 逾期  009804、009820、009817
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '14.购买信托产品 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --009804、009820取资产自己的五级分类
    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN (A.GRADE = '1' OR A.GRADE IS NULL) THEN --正常类
                'G11_2_14..C.2016'
               WHEN A.GRADE = '2' THEN --关注类
                'G11_2_14..D.2016'
               WHEN A.GRADE = '3' THEN --次级类
                'G11_2_14..F.2016'
               WHEN A.GRADE = '4' THEN --可疑类
                'G11_2_14..G.2016'
               WHEN A.GRADE = '5' THEN --损失类
                'G11_2_14..H.2016'
             END AS ITEM_NUM, --指标号
             SUM(A.FACE_VAL + A.MK_VAL) AS COLLECT_VAL --持有仓位+公允价值
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP = '04' --信托产品投资
         AND A.ORG_NUM <> '009817' --投管不在此处取
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN(A.GRADE = '1' OR A.GRADE IS NULL) THEN --正常类
                   'G11_2_14..C.2016'
                  WHEN A.GRADE = '2' THEN --关注类
                   'G11_2_14..D.2016'
                  WHEN A.GRADE = '3' THEN --次级类
                   'G11_2_14..F.2016'
                  WHEN A.GRADE = '4' THEN --可疑类
                   'G11_2_14..G.2016'
                  WHEN A.GRADE = '5' THEN --损失类
                   'G11_2_14..H.2016'
                END;
    COMMIT;

    --009817：存量非标信托关联I9系统，取信托减值的五级分类划分信托本金的五级分类
    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN --正常类
                'G11_2_14..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN --关注类
                'G11_2_14..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN --次级类
                'G11_2_14..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN --可疑类
                'G11_2_14..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN --损失类
                'G11_2_14..H.2016'
             END AS ITEM_NUM, --指标号
             SUM(A.FACE_VAL) AS COLLECT_VAL --持有仓位
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817' --投管
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP = '04' --信托
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN --正常类
                   'G11_2_14..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN --关注类
                   'G11_2_14..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN --次级类
                   'G11_2_14..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN --可疑类
                   'G11_2_14..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN --损失类
                   'G11_2_14..H.2016'
                END;
    COMMIT;


    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT '009804' AS ORG_NUM, --机构号
             'G11_2_16..I.2019' AS ITEM_NUM, --指标号
             SUM(A.FACE_VAL) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.GL_ITEM_CODE = '15010201' --债权投资特定目的载体投资投资成本
         AND A.ORG_NUM = '009804'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP = '04' --信托
         AND A.GRADE IN ('3', '4', '5');
    COMMIT;

    --==============================================================================================
    --14.2减值准备 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '14.2减值准备 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --009820:无减值
    --009804:估值减值系统非标投资业务明细报表中入账机构是金融市场部的，即该笔国民信托的减值
    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.RECORD_ORG,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' THEN
                'G11_2_14.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_14.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_14.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_14.2.H.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_14.2.G.2016'
             END,
             SUM(NVL(A.PRIN_FINAL_RESLT, 0) * U.CCY_RATE) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_ASSET_DEVALUE A --资产减值准备
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.PRIN_SUBJ_NO = '15010201'
         AND A.RECORD_ORG = '009804'
       GROUP BY A.RECORD_ORG,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' THEN
                   'G11_2_14.2.C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_14.2.D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_14.2.F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_14.2.H.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_14.2.G.2016'
                END;
    COMMIT;

    --009817:减值对应I9系统的最终本金ECL字段
    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' THEN
                'G11_2_14.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_14.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_14.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_14.2.H.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_14.2.G.2016'
             END,
             SUM(NVL(A.JZJE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817' --投管
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP = '04' --信托
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' THEN
                   'G11_2_14.2.C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_14.2.D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_14.2.F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_14.2.H.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_14.2.G.2016'
                END;

    COMMIT;

    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM,
             'G11_2_16.2.I.2019',
             SUM(NVL(A.JZJE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.RECORD_ORG = '009817'
         AND A.FIVE_TIER_CLS IN ('03', '04', '05')
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP = '04' --信托
       GROUP BY A.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --15.购买私募基金产品 五级分类 + 逾期  无
    --==============================================================================================
    --==============================================================================================
    --15.2减值准备 五级分类 + 逾期  无
    --==============================================================================================

    --==============================================================================================
    --16.购买公募基金产品 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '16.购买公募基金产品 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             CASE
               WHEN D.GRADE = '1' THEN --正常类
                'G11_2_16..C.2024'
               WHEN D.GRADE = '2' THEN --关注类
                'G11_2_16..D.2024'
               WHEN D.GRADE = '3' THEN --次级类
                'G11_2_16..F.2024'
               WHEN D.GRADE = '4' THEN --可疑类
                'G11_2_16..G.2024'
               WHEN D.GRADE = '5' THEN --损失类
                'G11_2_16..H.2024'
             END ITEM_NUM,
             SUM(NVL(D.ACCT_BAL, 0) + NVL(D.MK_VAL, 0)) ITEM_VALUE
             --SUM(NVL(D.FACE_VAL, 0)) ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D --投资业务信息表
       WHERE D.DATA_DATE = I_DATADATE
         AND D.INVEST_TYP =  '01' --基金
         AND D.BOOK_TYPE = '2' --银行账薄
       GROUP BY D.ORG_NUM,
                CASE
                  WHEN D.GRADE = '1' THEN --正常类
                   'G11_2_16..C.2024'
                  WHEN D.GRADE = '2' THEN --关注类
                   'G11_2_16..D.2024'
                  WHEN D.GRADE = '3' THEN --次级类
                   'G11_2_16..F.2024'
                  WHEN D.GRADE = '4' THEN --可疑类
                   'G11_2_16..G.2024'
                  WHEN D.GRADE = '5' THEN --损失类
                   'G11_2_16..H.2024'
                END;
    COMMIT;

    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             'G11_2_16..I.2024' ITEM_NUM,
             SUM(NVL(D.ACCT_BAL, 0) + NVL(D.MK_VAL, 0)) ITEM_VALUE
             --SUM(NVL(D.FACE_VAL, 0)) ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D --投资业务信息表
       WHERE D.DATA_DATE = I_DATADATE
         AND D.BOOK_TYPE = '2' --银行账薄
         AND D.INVEST_TYP =  '01' --基金
         --AND D.FIVE_TIER_CLS IN ('03','04','05')
         AND D.DC_DATE < 0
       GROUP BY D.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --16.2减值准备 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '16.2减值准备 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             CASE
               WHEN D.GRADE = '1' THEN --正常类
                'G11_2_16.2.C.2024'
               WHEN D.GRADE = '2' THEN --关注类
                'G11_2_16.2.D.2024'
               WHEN D.GRADE = '3' THEN --次级类
                'G11_2_16.2.F.2024'
               WHEN D.GRADE = '4' THEN --可疑类
                'G11_2_16.2.G.2024'
               WHEN D.GRADE = '5' THEN --损失类
                'G11_2_16.2.H.2024'
             END ITEM_NUM,
             --SUM(NVL(D.JZJE, 0)) ITEM_VALUE
             SUM(
               CASE
                 WHEN D.GL_ITEM_CODE IN ('11010302','11010303','11010502') THEN 0
                 ELSE NVL(D.JZJE, 0)
               END) ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D
       WHERE D.DATA_DATE = I_DATADATE
         AND D.INVEST_TYP = '01' --基金
         AND D.BOOK_TYPE = '2' --银行账薄
       GROUP BY D.ORG_NUM,
                CASE
                  WHEN D.GRADE = '1' THEN --正常类
                   'G11_2_16.2.C.2024'
                  WHEN D.GRADE = '2' THEN --关注类
                   'G11_2_16.2.D.2024'
                  WHEN D.GRADE = '3' THEN --次级类
                   'G11_2_16.2.F.2024'
                  WHEN D.GRADE = '4' THEN --可疑类
                   'G11_2_16.2.G.2024'
                  WHEN D.GRADE = '5' THEN --损失类
                   'G11_2_16.2.H.2024'
                END;
    COMMIT;


    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             'G11_2_16.2.I.2024' ITEM_NUM,
             --SUM(NVL(D.JZJE, 0)) ITEM_VALUE
             SUM(
               CASE
                 WHEN D.GL_ITEM_CODE IN ('11010302','11010303','11010502') THEN 0
                 ELSE NVL(D.JZJE, 0)
               END) ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D
       WHERE D.DATA_DATE = I_DATADATE
         AND D.INVEST_TYP = '01' --基金
         --AND D.FIVE_TIER_CLS IN ('03','04','05')
         AND D.DC_DATE < 0
         AND D.BOOK_TYPE = '2' --银行账薄
       GROUP BY D.ORG_NUM;

    COMMIT;


    --==============================================================================================
    --17.购买证券业资产管理产品（不含公募基金） 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '17.购买证券业资产管理产品（不含公募基金） 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             CASE
               WHEN D.GRADE = '1' THEN --正常类
                'G11_2_17..C.2024'
               WHEN D.GRADE = '2' THEN --关注类
                'G11_2_17..D.2024'
               WHEN D.GRADE = '3' THEN --次级类
                'G11_2_17..F.2024'
               WHEN D.GRADE = '4' THEN --可疑类
                'G11_2_17..G.2024'
               WHEN D.GRADE = '5' THEN --损失类
                'G11_2_17..H.2024'
             END ITEM_NUM,
             SUM(CASE
                   WHEN D.PROTYPE_DIS = '其他同业投资' THEN
                    NVL(D.ACCT_BAL, 0)
                   ELSE
                    NVL(D.ACCT_BAL, 0) + NVL(D.MK_VAL, 0)
                 END) AS ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D --投资业务信息表
       WHERE D.DATA_DATE = I_DATADATE
         AND (D.ISSU_ORG_NAM NOT LIKE '民生通惠%' OR  D.ISSU_ORG_NAM IS NULL)
         AND SUBSTR(D.INVEST_TYP, 1, 2) IN ('12', '99')
         AND D.ACCT_NUM NOT IN ('N000310000012723','N000310000012748')
         AND D.BOOK_TYPE = '2' --银行账薄
         AND D.ORG_NUM <> '009817'
       GROUP BY D.ORG_NUM,
                CASE
                  WHEN D.GRADE = '1' THEN --正常类
                   'G11_2_17..C.2024'
                  WHEN D.GRADE = '2' THEN --关注类
                   'G11_2_17..D.2024'
                  WHEN D.GRADE = '3' THEN --次级类
                   'G11_2_17..F.2024'
                  WHEN D.GRADE = '4' THEN --可疑类
                   'G11_2_17..G.2024'
                  WHEN D.GRADE = '5' THEN --损失类
                   'G11_2_17..H.2024'
                END;
    COMMIT;

    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             CASE
               WHEN D.FIVE_TIER_CLS = '01' OR D.FIVE_TIER_CLS IS NULL THEN --正常类
                'G11_2_17..C.2024'
               WHEN D.FIVE_TIER_CLS = '02' THEN --关注类
                'G11_2_17..D.2024'
               WHEN D.FIVE_TIER_CLS = '03' THEN --次级类
                'G11_2_17..F.2024'
               WHEN D.FIVE_TIER_CLS = '04' THEN --可疑类
                'G11_2_17..G.2024'
               WHEN D.FIVE_TIER_CLS = '05' THEN --损失类
                'G11_2_17..H.2024'
             END ITEM_NUM,
             SUM(NVL(D.FACE_VAL, 0)) AS ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D --投资业务信息表
       WHERE D.DATA_DATE = I_DATADATE
         AND (D.ISSU_ORG_NAM NOT LIKE '民生通惠%' OR  D.ISSU_ORG_NAM IS NULL)
         AND SUBSTR(D.INVEST_TYP, 1, 2) IN ('12', '99')
         AND D.ACCT_NUM NOT IN ('N000310000012723','N000310000012748')
         AND D.BOOK_TYPE = '2' --银行账薄
         AND D.ORG_NUM = '009817'
       GROUP BY D.ORG_NUM,
                CASE
                   WHEN D.FIVE_TIER_CLS = '01' OR D.FIVE_TIER_CLS IS NULL THEN --正常类
                    'G11_2_17..C.2024'
                   WHEN D.FIVE_TIER_CLS = '02' THEN --关注类
                    'G11_2_17..D.2024'
                   WHEN D.FIVE_TIER_CLS = '03' THEN --次级类
                    'G11_2_17..F.2024'
                   WHEN D.FIVE_TIER_CLS = '04' THEN --可疑类
                    'G11_2_17..G.2024'
                   WHEN D.FIVE_TIER_CLS = '05' THEN --损失类
                    'G11_2_17..H.2024'
                 END ;
    COMMIT;


    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    --其中3笔资产特殊处理放到逾期  资产编号:东吴基金管理公司+方正证券+华阳经贸
    SELECT 
     A.ORG_NUM AS ORG_NUM, --机构号
     'G11_2_17..I.2024' AS ITEM_NUM, --指标号
     SUM(NVL(A.PRINCIPAL_BALANCE, 0) * U.CCY_RATE) AS COLLECT_VAL
      FROM CBRC_V_PUB_FUND_INVEST A --投资业务信息表 A
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = I_DATADATE
       AND U.BASIC_CCY = A.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
       AND U.DATA_DATE = I_DATADATE
     WHERE A.SUBJECT_CD IN
          --3笔特殊处理的东吴基金管理公司，方正证券，华阳经贸的利息放到逾期
           ('N000310000012013', 'N000310000008023', 'N000310000012993')
       AND A.DATA_DATE = I_DATADATE
       AND A.BOOK_TYPE = '2' --银行账薄
     GROUP BY A.ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             'G11_2_17..I.2024' ITEM_NUM,
             SUM(NVL(D.FACE_VAL, 0)) AS ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D --投资业务信息表
       WHERE D.DATA_DATE = I_DATADATE
         AND (D.ISSU_ORG_NAM NOT LIKE '民生通惠%' OR  D.ISSU_ORG_NAM IS NULL)
         AND SUBSTR(D.INVEST_TYP, 1, 2) IN ('12', '99')
         AND D.ACCT_NUM NOT IN ('N000310000012723','N000310000012748')
         AND D.BOOK_TYPE = '2' --银行账薄
         AND D.ORG_NUM = '009817'
       GROUP BY D.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --17.2减值准备 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '17.2减值准备 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             CASE
               WHEN D.GRADE = '1' THEN --正常类
                'G11_2_17.2.C.2024'
               WHEN D.GRADE = '2' THEN --关注类
                'G11_2_17.2.D.2024'
               WHEN D.GRADE = '3' THEN --次级类
                'G11_2_17.2.F.2024'
               WHEN D.GRADE = '4' THEN --可疑类
                'G11_2_17.2.G.2024'
               WHEN D.GRADE = '5' THEN --损失类
                'G11_2_17.2.H.2024'
             END ITEM_NUM,
             SUM(NVL(D.JZJE, 0)) ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D
       WHERE D.DATA_DATE = I_DATADATE
         AND (D.ISSU_ORG_NAM NOT LIKE '民生通惠%' OR  D.ISSU_ORG_NAM IS NULL)
         AND SUBSTR(D.INVEST_TYP, 1, 2) IN ('12', '99')
         AND D.ACCT_NUM NOT IN ('N000310000012723','N000310000012748')
         AND D.BOOK_TYPE = '2' --银行账薄
         AND D.ORG_NUM <> '009817'
         AND D.GL_ITEM_CODE = '15010201'
       GROUP BY D.ORG_NUM,
                CASE
                  WHEN D.GRADE = '1' THEN --正常类
                   'G11_2_17.2.C.2024'
                  WHEN D.GRADE = '2' THEN --关注类
                   'G11_2_17.2.D.2024'
                  WHEN D.GRADE = '3' THEN --次级类
                   'G11_2_17.2.F.2024'
                  WHEN D.GRADE = '4' THEN --可疑类
                   'G11_2_17.2.G.2024'
                  WHEN D.GRADE = '5' THEN --损失类
                   'G11_2_17.2.H.2024'
                END;
    COMMIT;

    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             CASE
               WHEN D.FIVE_TIER_CLS = '01' OR D.FIVE_TIER_CLS IS NULL THEN --正常类
                'G11_2_17.2.C.2024'
               WHEN D.FIVE_TIER_CLS = '02' THEN --关注类
                'G11_2_17.2.D.2024'
               WHEN D.FIVE_TIER_CLS = '03' THEN --次级类
                'G11_2_17.2.F.2024'
               WHEN D.FIVE_TIER_CLS = '04' THEN --可疑类
                'G11_2_17.2.G.2024'
               WHEN D.FIVE_TIER_CLS = '05' THEN --损失类
                'G11_2_17.2.H.2024'
             END ITEM_NUM,
             SUM(NVL(D.JZJE, 0)) AS ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D --投资业务信息表
       WHERE D.DATA_DATE = I_DATADATE
         AND (D.ISSU_ORG_NAM NOT LIKE '民生通惠%' OR  D.ISSU_ORG_NAM IS NULL)
         AND SUBSTR(D.INVEST_TYP, 1, 2) IN ('12', '99')
         AND D.ACCT_NUM NOT IN ('N000310000012723','N000310000012748')
         AND D.BOOK_TYPE = '2' --银行账薄
         AND D.ORG_NUM = '009817'
       GROUP BY D.ORG_NUM,
                CASE
                   WHEN D.FIVE_TIER_CLS = '01' OR D.FIVE_TIER_CLS IS NULL THEN --正常类
                    'G11_2_17.2.C.2024'
                   WHEN D.FIVE_TIER_CLS = '02' THEN --关注类
                    'G11_2_17.2.D.2024'
                   WHEN D.FIVE_TIER_CLS = '03' THEN --次级类
                    'G11_2_17.2.F.2024'
                   WHEN D.FIVE_TIER_CLS = '04' THEN --可疑类
                    'G11_2_17.2.G.2024'
                   WHEN D.FIVE_TIER_CLS = '05' THEN --损失类
                    'G11_2_17.2.H.2024'
                 END ;
    COMMIT;

    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT 
     A.ORG_NUM AS ORG_NUM, --机构号
     'G11_2_17.2.I.2024' AS ITEM_NUM, --指标号
     SUM((NVL(C.PRIN_FINAL_RESLT, 0) + NVL(C.OFBS_FINAL_RESLT, 0)) * U.CCY_RATE) AS COLLECT_VAL
      FROM CBRC_V_PUB_FUND_INVEST A --投资业务信息表 A
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = I_DATADATE
       AND U.BASIC_CCY = A.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
       AND U.DATA_DATE = I_DATADATE
      LEFT JOIN CBRC_TMP_ASSET_DEVALUE C --资产减值准备
        ON C.ACCT_NUM = A.SUBJECT_CD
       AND A.GL_ITEM_CODE = C.PRIN_SUBJ_NO
       AND A.ORG_NUM = C.RECORD_ORG
       AND C.DATA_DATE = I_DATADATE
     WHERE A.SUBJECT_CD IN
          --3笔特殊处理的东吴基金管理公司，方正证券，华阳经贸的利息放到逾期
           ('N000310000012013', 'N000310000008023', 'N000310000012993')
       AND A.DATA_DATE = I_DATADATE
       AND A.BOOK_TYPE = '2' --银行账薄
     GROUP BY A.ORG_NUM;
    COMMIT;


    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             'G11_2_17.2.I.2024' ITEM_NUM,
             SUM(NVL(D.JZJE, 0)) AS ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D --投资业务信息表
       WHERE D.DATA_DATE = I_DATADATE
         AND SUBSTR(D.INVEST_TYP, 1, 2) IN ('12', '99')
         AND D.ACCT_NUM NOT IN ('N000310000012723','N000310000012748')
         AND (D.ISSU_ORG_NAM NOT LIKE '民生通惠%' OR  D.ISSU_ORG_NAM IS NULL)
         AND D.BOOK_TYPE = '2' --银行账薄
         AND D.ORG_NUM = '009817'
       GROUP BY D.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --18.购买保险业资产管理产品 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '18.购买保险业资产管理产品 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             CASE
               WHEN D.GRADE = '1' THEN --正常类
                'G11_2_18..C.2024'
               WHEN D.GRADE = '2' THEN --关注类
                'G11_2_18..D.2024'
               WHEN D.GRADE = '3' THEN --次级类
                'G11_2_18..F.2024'
               WHEN D.GRADE = '4' THEN --可疑类
                'G11_2_18..G.2024'
               WHEN D.GRADE = '5' THEN --损失类
                'G11_2_18..H.2024'
             END ITEM_NUM,
             SUM(NVL(D.ACCT_BAL, 0) + NVL(D.MK_VAL, 0)) ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D --投资业务信息表
       WHERE D.DATA_DATE = I_DATADATE
         AND D.INVEST_TYP IN ('12'/*, '99'*/) --资产管理产品 其它投资
         AND D.ISSU_ORG_NAM LIKE '民生通惠%'
         AND D.BOOK_TYPE = '2' --银行账薄
       GROUP BY D.ORG_NUM,
                CASE
                  WHEN D.GRADE = '1' THEN --正常类
                   'G11_2_18..C.2024'
                  WHEN D.GRADE = '2' THEN --关注类
                   'G11_2_18..D.2024'
                  WHEN D.GRADE = '3' THEN --次级类
                   'G11_2_18..F.2024'
                  WHEN D.GRADE = '4' THEN --可疑类
                   'G11_2_18..G.2024'
                  WHEN D.GRADE = '5' THEN --损失类
                   'G11_2_18..H.2024'
                END;
    COMMIT;

    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             'G11_2_18..I.2024' ITEM_NUM,
             SUM(NVL(D.ACCT_BAL, 0) + NVL(D.MK_VAL, 0)) ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D --投资业务信息表
       WHERE D.DATA_DATE = I_DATADATE
         AND D.INVEST_TYP IN ('12'/*, '99'*/) --资产管理产品 其它投资
         AND D.ISSU_ORG_NAM LIKE '民生通惠%'
         --AND D.FIVE_TIER_CLS IN ('03','04','05')
         AND D.DC_DATE < 0
         AND D.BOOK_TYPE = '2' --银行账薄
       GROUP BY D.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --18.2减值准备 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '18.2减值准备 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             CASE
               WHEN D.GRADE = '1' THEN --正常类
                'G11_2_18.2.C.2024'
               WHEN D.GRADE = '2' THEN --关注类
                'G11_2_18.2.D.2024'
               WHEN D.GRADE = '3' THEN --次级类
                'G11_2_18.2.F.2024'
               WHEN D.GRADE = '4' THEN --可疑类
                'G11_2_18.2.G.2024'
               WHEN D.GRADE = '5' THEN --损失类
                'G11_2_18.2.H.2024'
             END ITEM_NUM,
             SUM(NVL(D.JZJE, 0)) ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D
       WHERE D.DATA_DATE = I_DATADATE
         AND D.INVEST_TYP IN ('12'/*, '99'*/) --资产管理产品 其它投资
         AND D.ISSU_ORG_NAM LIKE '民生通惠%'
         AND D.BOOK_TYPE = '2' --银行账薄
       GROUP BY D.ORG_NUM,
                CASE
                  WHEN D.GRADE = '1' THEN --正常类
                   'G11_2_18.2.C.2024'
                  WHEN D.GRADE = '2' THEN --关注类
                   'G11_2_18.2.D.2024'
                  WHEN D.GRADE = '3' THEN --次级类
                   'G11_2_18.2.F.2024'
                  WHEN D.GRADE = '4' THEN --可疑类
                   'G11_2_18.2.G.2024'
                  WHEN D.GRADE = '5' THEN --损失类
                   'G11_2_18.2.H.2024'
                END;
    COMMIT;


    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             'G11_2_18.2.I.2024' ITEM_NUM,
             SUM(NVL(D.JZJE, 0)) ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D
       WHERE D.DATA_DATE = I_DATADATE
         AND D.INVEST_TYP IN ('12'/*, '99'*/) --资产管理产品 其它投资
         AND D.ISSU_ORG_NAM LIKE '民生通惠%'
         --AND D.FIVE_TIER_CLS IN ('03','04','05')
         AND D.DC_DATE < 0
         AND D.BOOK_TYPE = '2' --银行账薄
       GROUP BY D.ORG_NUM;

    COMMIT;

    --==============================================================================================
    --19.购买其他债权类融资产品 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '19.购买其他债权类融资产品 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             CASE
               WHEN D.GRADE = '1' THEN --正常类
                'G11_2_19..C.2024'
               WHEN D.GRADE = '2' THEN --关注类
                'G11_2_19..D.2024'
               WHEN D.GRADE = '3' THEN --次级类
                'G11_2_19..F.2024'
               WHEN D.GRADE = '4' THEN --可疑类
                'G11_2_19..G.2024'
               WHEN D.GRADE = '5' THEN --损失类
                'G11_2_19..H.2024'
             END ITEM_NUM,
             SUM(NVL(D.ACCT_BAL, 0) + NVL(D.MK_VAL, 0)) ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D --投资业务信息表
       WHERE D.DATA_DATE = I_DATADATE
         AND D.INVEST_TYP IN ('15') --其他债权融资类产品
         AND D.BOOK_TYPE = '2' --银行账薄
       GROUP BY D.ORG_NUM,
                CASE
                  WHEN D.GRADE = '1' THEN --正常类
                   'G11_2_19..C.2024'
                  WHEN D.GRADE = '2' THEN --关注类
                   'G11_2_19..D.2024'
                  WHEN D.GRADE = '3' THEN --次级类
                   'G11_2_19..F.2024'
                  WHEN D.GRADE = '4' THEN --可疑类
                   'G11_2_19..G.2024'
                  WHEN D.GRADE = '5' THEN --损失类
                   'G11_2_19..H.2024'
                END;
    COMMIT;

    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             'G11_2_19..I.2024' ITEM_NUM,
             SUM(NVL(D.ACCT_BAL, 0) + NVL(D.MK_VAL, 0)) ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D --投资业务信息表
       WHERE D.DATA_DATE = I_DATADATE
         AND D.INVEST_TYP IN ('15') --其他债权融资类产品
         --AND D.FIVE_TIER_CLS IN ('03','04','05')
         AND D.DC_DATE < 0
         AND D.BOOK_TYPE = '2' --银行账薄
       GROUP BY D.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --19.2减值准备 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '19.2减值准备 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             CASE
               WHEN D.GRADE = '1' THEN --正常类
                'G11_2_19.2.C.2024'
               WHEN D.GRADE = '2' THEN --关注类
                'G11_2_19.2.D.2024'
               WHEN D.GRADE = '3' THEN --次级类
                'G11_2_19.2.F.2024'
               WHEN D.GRADE = '4' THEN --可疑类
                'G11_2_19.2.G.2024'
               WHEN D.GRADE = '5' THEN --损失类
                'G11_2_19.2.H.2024'
             END ITEM_NUM,
             SUM(NVL(D.JZJE, 0)) ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D
       WHERE D.DATA_DATE = I_DATADATE
         AND D.INVEST_TYP IN ('15') --其他债权融资类产品
         AND D.BOOK_TYPE = '2' --银行账薄
       GROUP BY D.ORG_NUM,
                CASE
                  WHEN D.GRADE = '1' THEN --正常类
                   'G11_2_19.2.C.2024'
                  WHEN D.GRADE = '2' THEN --关注类
                   'G11_2_19.2.D.2024'
                  WHEN D.GRADE = '3' THEN --次级类
                   'G11_2_19.2.F.2024'
                  WHEN D.GRADE = '4' THEN --可疑类
                   'G11_2_19.2.G.2024'
                  WHEN D.GRADE = '5' THEN --损失类
                   'G11_2_19.2.H.2024'
                END;
    COMMIT;


    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             'G11_2_19.2.I.2024' ITEM_NUM,
             SUM(NVL(D.JZJE, 0)) ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D
       WHERE D.DATA_DATE = I_DATADATE
         AND D.INVEST_TYP IN ('15') --其他债权融资类产品
         --AND D.FIVE_TIER_CLS IN ('03','04','05')
         AND D.DC_DATE < 0
         AND D.BOOK_TYPE = '2' --银行账薄
       GROUP BY D.ORG_NUM;

    COMMIT;

    --==============================================================================================
    --20.购买以上未包括的其他投资产品 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '20.购买以上未包括的其他投资产品 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM AS ORG_NUM, --机构号
           CASE
             WHEN A.GRADE = '1' THEN
              'G11_2_16..C.2016'
             WHEN A.GRADE IS NULL THEN
              'G11_2_16..C.2016'
             WHEN A.GRADE = '2' THEN
              'G11_2_16..D.2016'
             WHEN A.GRADE = '3' THEN
              'G11_2_16..F.2016'
             WHEN A.GRADE = '4' THEN
              'G11_2_16..G.2016'
             WHEN A.GRADE = '5' THEN
              'G11_2_16..H.2016'
           END AS ITEM_NUM, --指标号
           SUM(A.FACE_VAL) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
       FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表
       WHERE A.ACCT_NUM IN ('N000310000012723','N000310000012748')
         AND A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM, --机构号
                CASE
                  WHEN A.GRADE = '1' THEN
                   'G11_2_16..C.2016'
                  WHEN A.GRADE IS NULL THEN
                   'G11_2_16..C.2016'
                  WHEN A.GRADE = '2' THEN
                   'G11_2_16..D.2016'
                  WHEN A.GRADE = '3' THEN
                   'G11_2_16..F.2016'
                  WHEN A.GRADE = '4' THEN
                   'G11_2_16..G.2016'
                  WHEN A.GRADE = '5' THEN
                   'G11_2_16..H.2016'
                END;
    COMMIT;


    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM AS ORG_NUM, --机构号
           'G11_2_18..I.2019' AS ITEM_NUM, --指标号
           SUM(A.FACE_VAL) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
       FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '01'
         AND A.FUNDS_TYPE LIKE 'B%'
         AND A.DATA_DATE = I_DATADATE
         AND A.IN_OFF_FLG = '1'
         AND A.BOOK_TYPE = '2' --银行账薄
         --AND A.FIVE_TIER_CLS IN ('03','04','05')
         AND A.DC_DATE < 0
       GROUP BY A.ORG_NUM;
    COMMIT;



    --==============================================================================================
    --20.2减值准备 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '20.2减值准备 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM AS ORG_NUM, --机构号
           CASE
             WHEN A.GRADE = '1' THEN
              'G11_2_16.2.C.2016'
             WHEN A.GRADE IS NULL THEN
              'G11_2_16.2.C.2016'
             WHEN A.GRADE = '2' THEN
              'G11_2_16.2.D.2016'
             WHEN A.GRADE = '3' THEN
              'G11_2_16.2.F.2016'
             WHEN A.GRADE = '4' THEN
              'G11_2_16.2.G.2016'
             WHEN A.GRADE = '5' THEN
              'G11_2_16.2.H.2016'
           END AS ITEM_NUM, --指标号
           SUM(A.JZJE) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
       FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '01'
         AND A.FUNDS_TYPE LIKE 'B%'
         AND A.DATA_DATE = I_DATADATE
         AND A.IN_OFF_FLG = '1'
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM, --机构号
                CASE
                  WHEN A.GRADE = '1' THEN
                   'G11_2_16.2.C.2016'
                  WHEN A.GRADE IS NULL THEN
                   'G11_2_16.2.C.2016'
                  WHEN A.GRADE = '2' THEN
                   'G11_2_16.2.D.2016'
                  WHEN A.GRADE = '3' THEN
                   'G11_2_16.2.F.2016'
                  WHEN A.GRADE = '4' THEN
                   'G11_2_16.2.G.2016'
                  WHEN A.GRADE = '5' THEN
                   'G11_2_16.2.H.2016'
                END;
    COMMIT;

    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM AS ORG_NUM, --机构号
           CASE
             WHEN A.GRADE = '1' THEN
              'G11_2_16.2.C.2016'
             WHEN A.GRADE IS NULL THEN
              'G11_2_16.2.C.2016'
             WHEN A.GRADE = '2' THEN
              'G11_2_16.2.D.2016'
             WHEN A.GRADE = '3' THEN
              'G11_2_16.2.F.2016'
             WHEN A.GRADE = '4' THEN
              'G11_2_16.2.G.2016'
             WHEN A.GRADE = '5' THEN
              'G11_2_16.2.H.2016'
           END AS ITEM_NUM, --指标号
           SUM(A.JZJE) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
       FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表
       WHERE A.ACCT_NUM IN ('N000310000012723','N000310000012748')
         AND A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM, --机构号
                CASE
                  WHEN A.GRADE = '1' THEN
                   'G11_2_16.2.C.2016'
                  WHEN A.GRADE IS NULL THEN
                   'G11_2_16.2.C.2016'
                  WHEN A.GRADE = '2' THEN
                   'G11_2_16.2.D.2016'
                  WHEN A.GRADE = '3' THEN
                   'G11_2_16.2.F.2016'
                  WHEN A.GRADE = '4' THEN
                   'G11_2_16.2.G.2016'
                  WHEN A.GRADE = '5' THEN
                   'G11_2_16.2.H.2016'
                END;
    COMMIT;


    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM AS ORG_NUM, --机构号
           'G11_2_18.2.I.2019' AS ITEM_NUM, --指标号
           SUM(A.JZJE) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
       FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '01'
         AND A.FUNDS_TYPE LIKE 'B%'
         AND A.DATA_DATE = I_DATADATE
         AND A.IN_OFF_FLG = '1'
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --21.应收利息和其他应收款 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '21.应收利息和其他应收款 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    --同业存单 应收利息
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17..H.2016'
             END COLLECT_TYPE,
             SUM(A.INTEREST_RECEIVABLE) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_CDS_BAL_G1102 A --存单投资与发行信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;
        COMMIT;

    INSERT   INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    --同业存单 应收利息 逾期
      SELECT A.ORG_NUM,
             'G11_2_19..I.2019' COLLECT_TYPE,
             SUM(A.INTEREST_RECEIVABLE) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_CDS_BAL_G1102 A --存单投资与发行信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.DC_DATE < 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM;
     COMMIT;


   INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      --买入返售 应收利息
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17..H.2016'
             END COLLECT_TYPE,
             SUM(A.ACCRUAL) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_REPURCHASE_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BUSI_TYPE LIKE '1%'
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;
        COMMIT;

     INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      --买入返售 应收利息 逾期
      SELECT  T.ORG_NUM,
             'G11_2_19..I.2019'COLLECT_TYPE,
             SUM(T.ACCRUAL) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_REPURCHASE_G1102 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.BUSI_TYPE LIKE '1%'
         --AND T.FIVE_TIER_CLS IN ('03','04','05')
         AND T.END_DT - I_DATADATE < 0
         AND T.BOOK_TYPE = '2' --银行账薄
       GROUP BY T.ORG_NUM;
     COMMIT;


   --债券投资 应收利息
   INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17..H.2016'
             END COLLECT_TYPE,
             SUM(NVL(A.ACCRUAL, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP = '00'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;
       COMMIT;


      --债券投资 应收利息 逾期
      INSERT 
      INTO CBRC_PUB_DATA_COLLECT_G1102 
        (ORG_NUM, --机构号
         COLLECT_TYPE, --报表类型
         COLLECT_VAL --指标值
         )
        SELECT  A.ORG_NUM AS ORG_NUM, --机构号
               'G11_2_19..I.2019' AS ITEM_NUM, --指标号
               SUM(NVL(A.ACCRUAL, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
          FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
         WHERE A.DATA_DATE = I_DATADATE
           AND (A.DC_DATE < 0 OR A.SUBJECT_CD = '1523004')
           AND A.BOOK_TYPE = '2' --银行账薄
           AND A.INVEST_TYP = '00'
         GROUP BY A.ORG_NUM;
       COMMIT;


      --从总账取的应收
      INSERT 
      INTO CBRC_PUB_DATA_COLLECT_G1102 
        (ORG_NUM, --机构号
         COLLECT_TYPE, --报表类型
         COLLECT_VAL --指标值
         )
        SELECT G.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN (G.ITEM_CD = '12210202') THEN 'G11_2_17..C.2016'
                 WHEN G.ITEM_CD = '12210201' THEN 'G11_2_17..D.2016'
               END AS COLLECT_TYPE,
               SUM(G.DEBIT_BAL * U.CCY_RATE) COLLECT_VAL
          FROM SMTMODS_L_FINA_GL G
          LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON U.CCY_DATE = I_DATADATE
           AND U.BASIC_CCY = G.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY'
           AND U.DATA_DATE = I_DATADATE
         WHERE G.DATA_DATE = I_DATADATE
           AND G.ORG_NUM = '009804'
           AND (G.ITEM_CD IN ('12210202','12210201'))
         GROUP BY G.ORG_NUM,
                CASE
                  WHEN (G.ITEM_CD = '12210202') THEN 'G11_2_17..C.2016'
                  WHEN  G.ITEM_CD = '12210201'  THEN 'G11_2_17..D.2016'
                END;
       COMMIT;

    --损失:140万固定值+其他应收款应收1221科目
     INSERT 
     INTO CBRC_PUB_DATA_COLLECT_G1102 
       (ORG_NUM, --机构号
        COLLECT_TYPE, --报表类型
        COLLECT_VAL --指标值
        )
       SELECT 
        A.ORG_NUM AS ORG_NUM, --机构号
        'G11_2_17..H.2016' AS ITEM_NUM, --指标号
        SUM(A.DEBIT_BAL + 1400000) AS COLLECT_VAL
         FROM SMTMODS_L_FINA_GL A
         LEFT JOIN SMTMODS_L_PUBL_RATE U
           ON U.CCY_DATE = I_DATADATE
          AND U.BASIC_CCY = A.CURR_CD --基准币种
          AND U.FORWARD_CCY = 'CNY' --折算币种
          AND U.DATA_DATE = I_DATADATE
        WHERE A.DATA_DATE = I_DATADATE
          AND A.ORG_NUM = '009820'
          AND A.ITEM_CD IN ('1221')
          AND A.CURR_CD = 'BWB'
        GROUP BY A.ORG_NUM;
     COMMIT;

    --逾期取：
    --其他应收款应收1221科目(逾期) + 140万利息逾期固定值;
     INSERT 
     INTO CBRC_PUB_DATA_COLLECT_G1102 
       (ORG_NUM, --机构号
        COLLECT_TYPE, --报表类型
        COLLECT_VAL --指标值
        )
       SELECT 
        A.ORG_NUM AS ORG_NUM, --机构号
        'G11_2_19..I.2019' AS ITEM_NUM, --指标号
        SUM(A.DEBIT_BAL + 1400000) AS COLLECT_VAL
         FROM SMTMODS_L_FINA_GL A
         LEFT JOIN SMTMODS_L_PUBL_RATE U
           ON U.CCY_DATE = I_DATADATE
          AND U.BASIC_CCY = A.CURR_CD --基准币种
          AND U.FORWARD_CCY = 'CNY' --折算币种
          AND U.DATA_DATE = I_DATADATE
        WHERE A.DATA_DATE = I_DATADATE
          AND A.ORG_NUM = '009820'
          AND A.ITEM_CD IN ('1221')
          AND A.CURR_CD = 'BWB'
        GROUP BY A.ORG_NUM;
     COMMIT;


    --基金的应收
    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           CASE
             WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
              'G11_2_17..C.2016'
             WHEN A.FIVE_TIER_CLS = '02' THEN
              'G11_2_17..D.2016'
             WHEN A.FIVE_TIER_CLS = '03' THEN
              'G11_2_17..F.2016'
             WHEN A.FIVE_TIER_CLS = '04' THEN
              'G11_2_17..G.2016'
             WHEN A.FIVE_TIER_CLS = '05' THEN
              'G11_2_17..H.2016'
           END COLLECT_TYPE,
           SUM(A.ACCRUAL) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP IN ('01')
         AND A.ACCRUAL <> 0
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;
    COMMIT;


    --基金的应收 逾期
    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           'G11_2_19..I.2019'AS COLLECT_TYPE,
           SUM(A.ACCRUAL) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP IN ('01')
         --AND A.FIVE_TIER_CLS IN ('03','04','05')
         AND A.DC_DATE < 0
         AND A.ACCRUAL <> 0
       GROUP BY A.ORG_NUM;
    COMMIT;


    --3笔特殊处理的东吴基金管理公司，方正证券，华阳经贸的利息放到逾期
    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       'G11_2_19..I.2019' AS ITEM_NUM, --指标号
       SUM(NVL(A.ACCRUAL, 0) * U.CCY_RATE) AS COLLECT_VAL
        FROM CBRC_V_PUB_FUND_INVEST A --投资业务信息表 A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE
       WHERE A.SUBJECT_CD IN
            --3笔特殊处理的东吴基金管理公司，方正证券，华阳经贸的利息放到逾期
             ('N000310000012013', 'N000310000008023', 'N000310000012993')
         AND A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM;
    COMMIT;


    --存放同业 拆放同业的应收
    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT 
         A.ORG_NUM,
         CASE
           WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
            'G11_2_17..C.2016'
           WHEN A.FIVE_TIER_CLS = '02' THEN
            'G11_2_17..D.2016'
           WHEN A.FIVE_TIER_CLS = '03' THEN
            'G11_2_17..F.2016'
           WHEN A.FIVE_TIER_CLS = '04' THEN
            'G11_2_17..G.2016'
           WHEN A.FIVE_TIER_CLS = '05' THEN
            'G11_2_17..H.2016'
         END COLLECT_TYPE,
         SUM(A.ACCRUAL) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金交易信息表
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ACCRUAL <> 0
       AND A.BOOK_TYPE = '2' --银行账薄
     GROUP BY A.ORG_NUM,
              CASE
                WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                 'G11_2_17..C.2016'
                WHEN A.FIVE_TIER_CLS = '02' THEN
                 'G11_2_17..D.2016'
                WHEN A.FIVE_TIER_CLS = '03' THEN
                 'G11_2_17..F.2016'
                WHEN A.FIVE_TIER_CLS = '04' THEN
                 'G11_2_17..G.2016'
                WHEN A.FIVE_TIER_CLS = '05' THEN
                 'G11_2_17..H.2016'
              END;
    COMMIT;


    --存放同业 拆放同业的应收 逾期
    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT 
         A.ORG_NUM,
         'G11_2_19..I.2019' AS  COLLECT_TYPE,
         SUM(A.ACCRUAL) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金交易信息表
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ACCRUAL <> 0
       AND A.BOOK_TYPE = '2' --银行账薄
       AND A.FIVE_TIER_CLS IN ('03', '04', '05')
     GROUP BY A.ORG_NUM;
    COMMIT;


    --009817：存量非标的应收利息+其他应收款按五级分类划分
    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           CASE
             WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
              'G11_2_17..C.2016'
             WHEN A.FIVE_TIER_CLS = '02' THEN
              'G11_2_17..D.2016'
             WHEN A.FIVE_TIER_CLS = '03' THEN
              'G11_2_17..F.2016'
             WHEN A.FIVE_TIER_CLS = '04' THEN
              'G11_2_17..G.2016'
             WHEN A.FIVE_TIER_CLS = '05' THEN
              'G11_2_17..H.2016'
           END COLLECT_TYPE,
           SUM(A.ACCRUAL) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
         AND A.ACCRUAL <> 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;
    COMMIT;


    --009817：存量非标的应收利息+其他应收款按五级分类划分  逾期
    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           'G11_2_19..I.2019'AS COLLECT_TYPE,
           SUM(A.ACCRUAL) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
         AND A.ACCRUAL <> 0
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.FIVE_TIER_CLS IN ('03','04','05')
         AND A.DC_DATE < 0
       GROUP BY A.ORG_NUM;
    COMMIT;

   --009820 AC账户 应收利息
   INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17..H.2016'
             END COLLECT_TYPE,
             SUM(NVL(A.ACCRUAL, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.ORG_NUM = '009820'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCOUNTANT_TYPE = '3' --AC账户
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;
       COMMIT;

--009816：G01资产负债项目统计表 5.应收利息+11.其他应收款；正常类取归并项  配置公式

---alter by 20241217 JLBA202412040012新增信用卡应收利息和其他应收款C列取：业务状况表（本外币合并）科目“1132”加科目“1221”


     --信用卡
     INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
        SELECT  '009803' AS ORG_NUM ,
               'G11_2_17..C.2016' AS COLLECT_TYPE,
                SUM(G.DEBIT_BAL * U.CCY_RATE)
       FROM  SMTMODS_L_FINA_GL G
          LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         WHERE G.DATA_DATE= I_DATADATE
            AND G.ORG_NUM ='009803'
            AND G.ITEM_CD IN ('1132','1221');
         COMMIT;

         --信用卡 -逾期
    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
        SELECT  '009803' AS ORG_NUM ,
               'G11_2_19..I.2019'  AS COLLECT_TYPE,
                SUM(G.DEBIT_BAL * U.CCY_RATE)
       FROM  SMTMODS_L_FINA_GL G
          LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         WHERE G.DATA_DATE= I_DATADATE
            AND G.ORG_NUM ='009803'
            AND G.ITEM_CD IN ('1132');
         COMMIT;
    --==============================================================================================
    --21.2减值准备 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '21.2减值准备 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --15万其他应收款的减值取科目1231 放关注
    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
       SELECT T.ORG_NUM AS ORG_NUM,
             'G11_2_17.2.D.2016'AS COLLECT_TYPE,
             SUM(NVL(T.CREDIT_BAL,0) * U.CCY_RATE) AS COLLECT_VAL
       FROM SMTMODS_L_FINA_GL T
       LEFT JOIN SMTMODS_L_PUBL_RATE U
         ON U.CCY_DATE = I_DATADATE
        AND U.BASIC_CCY = T.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
        AND U.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ORG_NUM = '009804'
         AND T.ITEM_CD = '1231'
       GROUP BY T.ORG_NUM;
     COMMIT;

     INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      --买入返售 应收利息 减值
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17.2.G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17.2.H.2016'
             END COLLECT_TYPE,
             SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_REPURCHASE_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.BUSI_TYPE LIKE '1%'
       GROUP BY A.ORG_NUM,
                CASE
                   WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                    'G11_2_17.2.C.2016'
                   WHEN A.FIVE_TIER_CLS = '02' THEN
                    'G11_2_17.2.D.2016'
                   WHEN A.FIVE_TIER_CLS = '03' THEN
                    'G11_2_17.2.F.2016'
                   WHEN A.FIVE_TIER_CLS = '04' THEN
                    'G11_2_17.2.G.2016'
                   WHEN A.FIVE_TIER_CLS = '05' THEN
                    'G11_2_17.2.H.2016'
                 END;
    COMMIT;

     INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      --买入返售 应收利息 减值 逾期
      SELECT  A.ORG_NUM,
             'G11_2_19.2.I.2019' AS  COLLECT_TYPE,
             SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_REPURCHASE_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BUSI_TYPE LIKE '1%'
         --AND A.FIVE_TIER_CLS IN ('03','04','05')
         AND A.END_DT - I_DATADATE < 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM;
    COMMIT;


     --债券投资 应收利息 减值
     INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17.2.G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17.2.H.2016'
             END AS ITEM_NUM, --指标号
             SUM(NVL(A.COLLBL_INT_FINAL_RESLT, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP = '00'
       GROUP BY A.ORG_NUM, --机构号
                CASE
                   WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                    'G11_2_17.2.C.2016'
                   WHEN A.FIVE_TIER_CLS = '02' THEN
                    'G11_2_17.2.D.2016'
                   WHEN A.FIVE_TIER_CLS = '03' THEN
                    'G11_2_17.2.F.2016'
                   WHEN A.FIVE_TIER_CLS = '04' THEN
                    'G11_2_17.2.G.2016'
                   WHEN A.FIVE_TIER_CLS = '05' THEN
                    'G11_2_17.2.H.2016'
                 END;
    COMMIT;

     --债券投资 应收利息 减值 逾期
     INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM AS ORG_NUM, --机构号
             'G11_2_19.2.I.2019' AS ITEM_NUM, --指标号
             SUM(NVL(A.COLLBL_INT_FINAL_RESLT, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         --AND A.FIVE_TIER_CLS IN ('03','04','05')
         AND A.DC_DATE < 0
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP = '00'
       GROUP BY A.ORG_NUM;
    COMMIT;


    --存放同业 拆放同业的应收 减值
    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT 
         A.ORG_NUM,
         CASE
           WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
            'G11_2_17.2.C.2016'
           WHEN A.FIVE_TIER_CLS = '02' THEN
            'G11_2_17.2.D.2016'
           WHEN A.FIVE_TIER_CLS = '03' THEN
            'G11_2_17.2.F.2016'
           WHEN A.FIVE_TIER_CLS = '04' THEN
            'G11_2_17.2.G.2016'
           WHEN A.FIVE_TIER_CLS = '05' THEN
            'G11_2_17.2.H.2016'
         END COLLECT_TYPE,
         SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金交易信息表
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ACCRUAL <> 0
       AND A.BOOK_TYPE = '2' --银行账薄
     GROUP BY A.ORG_NUM,
              CASE
                WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                 'G11_2_17.2.C.2016'
                WHEN A.FIVE_TIER_CLS = '02' THEN
                 'G11_2_17.2.D.2016'
                WHEN A.FIVE_TIER_CLS = '03' THEN
                 'G11_2_17.2.F.2016'
                WHEN A.FIVE_TIER_CLS = '04' THEN
                 'G11_2_17.2.G.2016'
                WHEN A.FIVE_TIER_CLS = '05' THEN
                 'G11_2_17.2.H.2016'
              END;
    COMMIT;


    --存放同业 拆放同业的应收 减值 逾期
    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT 
         A.ORG_NUM,
         'G11_2_19.2.I.2019' AS  COLLECT_TYPE,
         SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金交易信息表
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ACCRUAL <> 0
       AND A.BOOK_TYPE = '2' --银行账薄
       --AND A.FIVE_TIER_CLS IN ('03','04','05')
       AND A.MATURE_DATE - I_DATADATE < 0
     GROUP BY A.ORG_NUM;
    COMMIT;


    --AC的应收 减值
    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           CASE
             WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
              'G11_2_17.2.C.2016'
             WHEN A.FIVE_TIER_CLS = '02' THEN
              'G11_2_17.2.D.2016'
             WHEN A.FIVE_TIER_CLS = '03' THEN
              'G11_2_17.2.F.2016'
             WHEN A.FIVE_TIER_CLS = '04' THEN
              'G11_2_17.2.G.2016'
             WHEN A.FIVE_TIER_CLS = '05' THEN
              'G11_2_17.2.H.2016'
           END COLLECT_TYPE,
           SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.GL_ITEM_CODE = '15010201'
         AND A.ACCOUNTANT_TYPE = '3'
         AND A.ACCRUAL <> 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17.2.C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17.2.D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17.2.F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17.2.G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17.2.H.2016'
                END;
    COMMIT;

    INSERT INTO CBRC_PUB_DATA_COLLECT_G1102
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT 
     A.ORG_NUM AS ORG_NUM, --机构号
     'G11_2_19.2.I.2019' AS ITEM_NUM, --指标号
     SUM((NVL(C.COLLBL_INT_FINAL_RESLT, 0)) * U.CCY_RATE) AS COLLECT_VAL
      FROM CBRC_V_PUB_FUND_INVEST A --投资业务信息表 A
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = I_DATADATE
       AND U.BASIC_CCY = A.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
       AND U.DATA_DATE = I_DATADATE
      LEFT JOIN CBRC_TMP_ASSET_DEVALUE C --资产减值准备
        ON C.ACCT_NUM = A.SUBJECT_CD
       AND A.GL_ITEM_CODE = C.PRIN_SUBJ_NO
       AND A.ORG_NUM = C.RECORD_ORG
       AND C.DATA_DATE = I_DATADATE
     WHERE A.SUBJECT_CD IN
          --3笔特殊处理的东吴基金管理公司，方正证券，华阳经贸的利息放到逾期
           ('N000310000012013', 'N000310000008023', 'N000310000012993')
       AND A.DATA_DATE = I_DATADATE
       AND A.BOOK_TYPE = '2' --银行账薄
     GROUP BY A.ORG_NUM;
    COMMIT;


    --损失:140万固定值+其他应收款应收1221科目
     INSERT 
     INTO CBRC_PUB_DATA_COLLECT_G1102 
       (ORG_NUM, --机构号
        COLLECT_TYPE, --报表类型
        COLLECT_VAL --指标值
        )
       SELECT 
        A.ORG_NUM AS ORG_NUM, --机构号
        'G11_2_17.2.H.2016' AS ITEM_NUM, --指标号
        SUM(A.DEBIT_BAL + 1400000) AS COLLECT_VAL
         FROM SMTMODS_L_FINA_GL A
         LEFT JOIN SMTMODS_L_PUBL_RATE U
           ON U.CCY_DATE = I_DATADATE
          AND U.BASIC_CCY = A.CURR_CD --基准币种
          AND U.FORWARD_CCY = 'CNY' --折算币种
          AND U.DATA_DATE = I_DATADATE
        WHERE A.DATA_DATE = I_DATADATE
          AND A.ORG_NUM = '009820'
          AND A.ITEM_CD IN ('1221')
          AND A.CURR_CD = 'BWB'
        GROUP BY A.ORG_NUM;
     COMMIT;


    --逾期:140万固定值+其他应收款应收1221科目
     INSERT 
     INTO CBRC_PUB_DATA_COLLECT_G1102 
       (ORG_NUM, --机构号
        COLLECT_TYPE, --报表类型
        COLLECT_VAL --指标值
        )
       SELECT 
        A.ORG_NUM AS ORG_NUM, --机构号
        'G11_2_19.2.I.2019' AS ITEM_NUM, --指标号
        SUM(A.DEBIT_BAL + 1400000) AS COLLECT_VAL
         FROM SMTMODS_L_FINA_GL A
         LEFT JOIN SMTMODS_L_PUBL_RATE U
           ON U.CCY_DATE = I_DATADATE
          AND U.BASIC_CCY = A.CURR_CD --基准币种
          AND U.FORWARD_CCY = 'CNY' --折算币种
          AND U.DATA_DATE = I_DATADATE
        WHERE A.DATA_DATE = I_DATADATE
          AND A.ORG_NUM = '009820'
          AND A.ITEM_CD IN ('1221')
          AND A.CURR_CD = 'BWB'
        GROUP BY A.ORG_NUM;
     COMMIT;

    --009817：存量非标的应收利息+其他应收款按五级分类划分
    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           CASE
             WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
              'G11_2_17.2.C.2016'
             WHEN A.FIVE_TIER_CLS = '02' THEN
              'G11_2_17.2.D.2016'
             WHEN A.FIVE_TIER_CLS = '03' THEN
              'G11_2_17.2.F.2016'
             WHEN A.FIVE_TIER_CLS = '04' THEN
              'G11_2_17.2.G.2016'
             WHEN A.FIVE_TIER_CLS = '05' THEN
              'G11_2_17.2.H.2016'
           END COLLECT_TYPE,
           SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
         AND A.ACCRUAL <> 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17.2.C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17.2.D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17.2.F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17.2.G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17.2.H.2016'
                END;
    COMMIT;


    --009817：存量非标的应收利息+其他应收款按五级分类划分  逾期
    INSERT 
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           'G11_2_19.2.I.2019'AS COLLECT_TYPE,
           SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
         AND A.ACCRUAL <> 0
         AND A.BOOK_TYPE = '2' --银行账薄
         --AND A.FIVE_TIER_CLS IN ('03','04','05')
         AND A.DC_DATE < 0
       GROUP BY A.ORG_NUM;
    COMMIT;


   /* --其他应收款的减值取科目12310101其他应收款坏账准备贷方，放次级
    INSERT \*+ append*\
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
       SELECT T.ORG_NUM AS ORG_NUM,
             'G11_2_17.2.F.2016'AS COLLECT_TYPE,
             SUM(NVL(T.CREDIT_BAL,0) * U.CCY_RATE) AS COLLECT_VAL
       FROM SMTMODS_L_FINA_GL T
       LEFT JOIN SMTMODS_L_PUBL_RATE U
         ON U.CCY_DATE = I_DATADATE
        AND U.BASIC_CCY = T.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
        AND U.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ORG_NUM = '009817'
         AND T.ITEM_CD = '12310101'
       GROUP BY T.ORG_NUM;
     COMMIT;

    --其他应收款的减值取科目12310101其他应收款坏账准备贷方，放次级
    INSERT \*+ append*\
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
       SELECT T.ORG_NUM AS ORG_NUM,
             'G11_2_19.2.I.2019'AS COLLECT_TYPE,
             SUM(NVL(T.CREDIT_BAL,0) * U.CCY_RATE) AS COLLECT_VAL
       FROM SMTMODS_L_FINA_GL T
       LEFT JOIN SMTMODS_L_PUBL_RATE U
         ON U.CCY_DATE = I_DATADATE
        AND U.BASIC_CCY = T.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
        AND U.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ORG_NUM = '009817'
         AND T.ITEM_CD = '12310101'
       GROUP BY T.ORG_NUM;
     COMMIT;*/

   --ADD BY DJH 20240827 投行前台补录其他应收款的减值

      INSERT 
      INTO CBRC_PUB_DATA_COLLECT_G1102 
        (ORG_NUM, --机构号
         COLLECT_TYPE, --报表类型
         COLLECT_VAL --指标值
         )
        SELECT 
         A.ORG_NUM,
         CASE
           WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
            'G11_2_17.2.C.2016'
           WHEN A.FIVE_TIER_CLS = '02' THEN
            'G11_2_17.2.D.2016'
           WHEN A.FIVE_TIER_CLS = '03' THEN
            'G11_2_17.2.F.2016'
           WHEN A.FIVE_TIER_CLS = '04' THEN
            'G11_2_17.2.G.2016'
           WHEN A.FIVE_TIER_CLS = '05' THEN
            'G11_2_17.2.H.2016'
         END COLLECT_TYPE,
         SUM(NVL(A.FINAL_ECL, 0)) AS COLLECT_VAL
          FROM (SELECT 
                 A.ORG_NUM, --机构号
                 C.FIVE_TIER_CLS, --减值五级分类
                 C.FINAL_ECL,
                 A.BOOK_TYPE,
                 C.DATA_SRC
                  FROM CBRC_V_PUB_FUND_INVEST A --投资业务信息表 A
                 INNER JOIN CBRC_TMP_ASSET_DEVALUE_TH C --资产减值准备
                    ON C.ACCT_NUM = A.ACCT_NUM
                   AND A.GL_ITEM_CODE = C.PRIN_SUBJ_NO
                   AND A.ORG_NUM = C.RECORD_ORG
                   AND C.DATA_DATE = I_DATADATE
                 WHERE A.DATA_DATE = I_DATADATE
                   AND NVL(A.PRINCIPAL_BALANCE, 0) <> 0) A --投资业务信息表
         WHERE A.ORG_NUM = '009817'
           AND A.FINAL_ECL <> 0
           AND A.BOOK_TYPE = '2' --银行账薄
           AND A.DATA_SRC = '投行手工补录其他应收款坏账准备'
         GROUP BY A.ORG_NUM,
                  CASE
                    WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                     'G11_2_17.2.C.2016'
                    WHEN A.FIVE_TIER_CLS = '02' THEN
                     'G11_2_17.2.D.2016'
                    WHEN A.FIVE_TIER_CLS = '03' THEN
                     'G11_2_17.2.F.2016'
                    WHEN A.FIVE_TIER_CLS = '04' THEN
                     'G11_2_17.2.G.2016'
                    WHEN A.FIVE_TIER_CLS = '05' THEN
                     'G11_2_17.2.H.2016'
                  END;
    COMMIT;


      INSERT 
      INTO CBRC_PUB_DATA_COLLECT_G1102 
        (ORG_NUM, --机构号
         COLLECT_TYPE, --报表类型
         COLLECT_VAL --指标值
         )
        SELECT 
         A.ORG_NUM,
         'G11_2_19.2.I.2019' AS COLLECT_TYPE, 
         SUM(NVL(A.FINAL_ECL, 0)) AS COLLECT_VAL
          FROM (SELECT 
                 A.ORG_NUM, --机构号
                 C.FIVE_TIER_CLS, --减值五级分类
                 C.FINAL_ECL,
                 A.BOOK_TYPE,
                 C.DATA_SRC,
                 A.DC_DATE
                  FROM CBRC_V_PUB_FUND_INVEST A --投资业务信息表 A
                 INNER JOIN CBRC_TMP_ASSET_DEVALUE_TH C --资产减值准备
                    ON C.ACCT_NUM = A.ACCT_NUM
                   AND A.GL_ITEM_CODE = C.PRIN_SUBJ_NO
                   AND A.ORG_NUM = C.RECORD_ORG
                   AND C.DATA_DATE = I_DATADATE
                 WHERE A.DATA_DATE = I_DATADATE
                   AND NVL(A.PRINCIPAL_BALANCE, 0) <> 0) A --投资业务信息表
         WHERE A.ORG_NUM = '009817'
           AND A.FINAL_ECL <> 0
           AND A.BOOK_TYPE = '2' --银行账薄
           AND A.DATA_SRC = '投行手工补录其他应收款坏账准备'
           AND DC_DATE < 0
          GROUP BY A.ORG_NUM;
    COMMIT;

    --alter by 20241217 JLBA202412040012信用卡 21.2减值准备C列取：业务状况表（本外币合并）科目“130407”
      INSERT 
      INTO CBRC_PUB_DATA_COLLECT_G1102 
        (ORG_NUM, --机构号
         COLLECT_TYPE, --报表类型
         COLLECT_VAL --指标值
         )
          SELECT  '009803' org_num,
                  'G11_2_17.2.C.2016' as COLLECT_TYPE,
                  sum(g.CREDIT_BAL *u.ccy_rate)

       FROM  SMTMODS_L_FINA_GL G
          LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         WHERE G.DATA_DATE= I_DATADATE
            AND G.ORG_NUM ='009803'
            AND G.ITEM_CD IN ('130407')
           ;
           commit;


    --==============================================================================================
    --22.其他银行账簿承担信用风险资产 五级分类 + 逾期  无
    --==============================================================================================
    --==============================================================================================
    --22.2减值准备 五级分类 + 逾期  无
    --==============================================================================================


    --==============================================================================================
    ----------------------------------------承担信用风险的表外项目------------------------------------
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '承担信用风险的表外项目';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --==============================================================================================
    --24.不可撤销的承诺及或有负债 五级分类 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '24.不可撤销的承诺及或有负债 五级分类 + 逾期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102  
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  G.ORG_NUM AS ORG_NUM, --机构号
             'G11_2_7..C' COLLECT_TYPE,
             SUM(G.DEBIT_BAL * U.CCY_RATE) COLLECT_VAL
        FROM SMTMODS_L_FINA_GL G
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
         AND U.DATA_DATE = I_DATADATE 
       WHERE G.DATA_DATE = I_DATADATE
         AND G.ORG_NUM <> '009804'
         AND G.ITEM_CD IN ('70200201',
                           '70200101',
                           '7010',
                           '70400101',
                           '70400103',
                           '70400201',
                           '70400203',
                           '70400102',
                           '70400104',
                           '70400202',
                           '70400204')
       GROUP BY G.ORG_NUM;
    COMMIT;

    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102  
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             'G11_2_7..C' COLLECT_TYPE,
             SUM(A.AMOUNT * U.CCY_RATE) COLLECT_VAL
        FROM SMTMODS_L_AGRE_BILL_CONTRACT A
       INNER JOIN SMTMODS_L_AGRE_BILL_INFO B
          ON A.BILL_NUM = B.BILL_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON A.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = B.CURR_CD -- 基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN CBRC_TMP_ASSET_DEVALUE_S2601 C
          ON A.BILL_NUM = C.ACCT_NUM
         AND C.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND TO_CHAR(B.MATU_DATE, 'YYYYMMDD') > I_DATADATE ---未到期的
         AND A.BUSI_TYPE = 'BT01' ---转贴现
         AND A.STATUS = '2' ---卖出结束
         AND A.ORG_NUM = '009804'
       GROUP BY A.ORG_NUM;
    COMMIT;

    --==============================================================================================
    --24.2减值准备 五级分类 + 逾期  无
    --==============================================================================================


    --==============================================================================================
    ----------------------------------------交易账簿金融资产-----------------------------------------
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '交易账簿金融资产';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --==============================================================================================
    --26.交易账簿项下金融资产 各项资产 + 逾期
    --==============================================================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '26.交易账簿项下金融资产 各项资产 + 逾期 ';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --债券
    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
    (ORG_NUM, --机构号
     COLLECT_TYPE, --报表类型
     COLLECT_VAL --指标值
    )
    SELECT A.ORG_NUM AS ORG_NUM,
           'G11_2_26..A.2024' AS COLLECT_TYPE,
           SUM(A.PRINCIPAL_BALANCE + A.ACCRUAL) AS COLLECT_VAL
      FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A
     WHERE A.DATA_DATE = I_DATADATE
       AND A.INVEST_TYP = '00'
       AND A.BOOK_TYPE = '1' --交易账薄
    GROUP BY A.ORG_NUM;
    COMMIT;
    --资金往来
    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
    (ORG_NUM, --机构号
     COLLECT_TYPE, --报表类型
     COLLECT_VAL --指标值
    )
    SELECT A.ORG_NUM AS ORG_NUM,
           'G11_2_26..A.2024' AS COLLECT_TYPE,
           SUM(A.BALANCE + A.ACCRUAL) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_MMFUND_G1102 A
     WHERE A.DATA_DATE = I_DATADATE
       AND A.BOOK_TYPE = '1' --交易账薄
    GROUP BY A.ORG_NUM;
    COMMIT;
    --回购
    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
    (ORG_NUM, --机构号
     COLLECT_TYPE, --报表类型
     COLLECT_VAL --指标值
    )
    SELECT A.ORG_NUM AS ORG_NUM,
           'G11_2_26..A.2024' AS COLLECT_TYPE,
           SUM(A.BALANCE + A.ACCRUAL) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_REPURCHASE_G1102 A
     WHERE A.DATA_DATE = I_DATADATE
       AND A.BOOK_TYPE = '1' --交易账薄
       AND A.BUSI_TYPE LIKE '1%'
    GROUP BY A.ORG_NUM;
    COMMIT;
    --存单
    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
    (ORG_NUM, --机构号
     COLLECT_TYPE, --报表类型
     COLLECT_VAL --指标值
    )
    SELECT A.ORG_NUM AS ORG_NUM,
           'G11_2_26..A.2024' AS COLLECT_TYPE,
           SUM(A.PRINCIPAL_BALANCE + A.INTEREST_RECEIVABLE) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_CDS_BAL_G1102 A
     WHERE A.DATA_DATE = I_DATADATE
       AND A.BOOK_TYPE = '1' --交易账薄
    GROUP BY A.ORG_NUM;
    COMMIT;
    --理财 信托 基金 资产管理 等
    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
    (ORG_NUM, --机构号
     COLLECT_TYPE, --报表类型
     COLLECT_VAL --指标值
    )
    SELECT A.ORG_NUM AS ORG_NUM,
           'G11_2_26..A.2024' AS COLLECT_TYPE,
           --SUM(A.ACCT_BAL + A.ACCRUAL) AS COLLECT_VAL
           SUM(
           CASE
             WHEN A.INVEST_TYP IN ('12', '99') AND A.PROTYPE_DIS = '其他同业投资' THEN A.ACCT_BAL
             WHEN A.INVEST_TYP = '04'                  THEN A.FACE_VAL + A.MK_VAL
             WHEN A.INVEST_TYP IN ('12', '99', '01', '15') THEN A.ACCT_BAL + A.MK_VAL
             ELSE A.FACE_VAL
           END) AS COLLECT_VAL
      FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A
     WHERE A.DATA_DATE = I_DATADATE
       AND A.BOOK_TYPE = '1' --交易账薄
       AND SUBSTR(A.INVEST_TYP,1,2) IN ('05','04','01','12','99','15')
    GROUP BY A.ORG_NUM;
    COMMIT;

    --逾期
    --债券
    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
    (ORG_NUM, --机构号
     COLLECT_TYPE, --报表类型
     COLLECT_VAL --指标值
    )
    SELECT A.ORG_NUM AS ORG_NUM,
           'G11_2_26..I.2024' AS COLLECT_TYPE,
           SUM(A.PRINCIPAL_BALANCE + A.ACCRUAL) AS COLLECT_VAL
      FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A
     WHERE A.DATA_DATE = I_DATADATE
       AND A.INVEST_TYP = '00'
       AND A.BOOK_TYPE = '1' --交易账薄
       --AND A.FIVE_TIER_CLS IN ('03','04','05')
       AND A.DC_DATE < 0
    GROUP BY A.ORG_NUM;
    COMMIT;
    --资金往来
    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
    (ORG_NUM, --机构号
     COLLECT_TYPE, --报表类型
     COLLECT_VAL --指标值
    )
    SELECT A.ORG_NUM AS ORG_NUM,
           'G11_2_26..I.2024' AS COLLECT_TYPE,
           SUM(A.BALANCE + A.ACCRUAL) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_MMFUND_G1102 A
     WHERE A.DATA_DATE = I_DATADATE
       AND A.BOOK_TYPE = '1' --交易账薄
       --AND A.FIVE_TIER_CLS IN ('03','04','05')
       AND A.MATURE_DATE - I_DATADATE < 0
    GROUP BY A.ORG_NUM;
    COMMIT;
    --回购
    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
    (ORG_NUM, --机构号
     COLLECT_TYPE, --报表类型
     COLLECT_VAL --指标值
    )
    SELECT A.ORG_NUM AS ORG_NUM,
           'G11_2_26..I.2024' AS COLLECT_TYPE,
           SUM(A.BALANCE + A.ACCRUAL) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_REPURCHASE_G1102 A
     WHERE A.DATA_DATE = I_DATADATE
       AND A.BOOK_TYPE = '1' --交易账薄
       AND A.BUSI_TYPE LIKE '1%'
       --AND A.FIVE_TIER_CLS IN ('03','04','05')
       AND A.END_DT - I_DATADATE < 0
    GROUP BY A.ORG_NUM;
    COMMIT;
    --存单
    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
    (ORG_NUM, --机构号
     COLLECT_TYPE, --报表类型
     COLLECT_VAL --指标值
    )
    SELECT A.ORG_NUM AS ORG_NUM,
           'G11_2_26..I.2024' AS COLLECT_TYPE,
           SUM(A.PRINCIPAL_BALANCE + A.INTEREST_RECEIVABLE) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_CDS_BAL_G1102 A
     WHERE A.DATA_DATE = I_DATADATE
       AND A.BOOK_TYPE = '1' --交易账薄
       AND A.DC_DATE < 0
    GROUP BY A.ORG_NUM;
    COMMIT;
    --理财 信托 基金 资产管理 等
    INSERT  INTO CBRC_PUB_DATA_COLLECT_G1102 
    (ORG_NUM, --机构号
     COLLECT_TYPE, --报表类型
     COLLECT_VAL --指标值
    )
    SELECT A.ORG_NUM AS ORG_NUM,
           'G11_2_26..I.2024' AS COLLECT_TYPE,
           --SUM(A.ACCT_BAL + A.ACCRUAL) AS COLLECT_VAL
           SUM(
           CASE
             WHEN A.INVEST_TYP IN ('12', '99') AND A.PROTYPE_DIS = '其他同业投资' THEN A.ACCT_BAL
             WHEN A.INVEST_TYP = '04'                  THEN A.FACE_VAL + A.MK_VAL
             WHEN A.INVEST_TYP IN ('12', '99', '01', '15') THEN A.ACCT_BAL + A.MK_VAL
             ELSE A.FACE_VAL
           END) AS COLLECT_VAL
      FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A
     WHERE A.DATA_DATE = I_DATADATE
       AND A.BOOK_TYPE = '1' --交易账薄
       AND SUBSTR(A.INVEST_TYP,1,2) IN ('05','04','01','12','99','15')
       --AND A.FIVE_TIER_CLS IN ('03','04','05')
       AND A.DC_DATE < 0
    GROUP BY A.ORG_NUM;
    COMMIT;


    --==============================================================================================
    ----------------------------------------    权益类资产  无   ------------------------------------
    --==============================================================================================

    --==============================================================================================
    --27.非金融企业股权（含股票） 各项资产
    --==============================================================================================
    --==============================================================================================
    --27.1减值准备 各项资产
    --==============================================================================================
    --==============================================================================================
    --28.金融机构股权（含股票） 各项资产
    --==============================================================================================
    --==============================================================================================
    --28.1减值准备 各项资产
    --==============================================================================================


    --------------------------------------------------------------------------------------------------------------------
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
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             V_PER_NUM AS REP_NUM, --报表编号
             COLLECT_TYPE, --指标号
             SUM(COLLECT_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_PUB_DATA_COLLECT_G1102
       WHERE COLLECT_TYPE IS NOT NULL
       GROUP BY ORG_NUM, --机构号
                COLLECT_TYPE; --报表类型
    COMMIT;
   
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
   
END proc_cbrc_idx2_g1102;
