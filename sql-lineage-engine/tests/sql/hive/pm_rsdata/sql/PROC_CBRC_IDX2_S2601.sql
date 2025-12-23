CREATE OR REPLACE PROCEDURE PROC_CBRC_IDX2_S2601(II_DATADATE IN STRING --跑批日期
                                              )
/******************************
  @author:DJH
  @create-date:20240311
  @description:S26_I城商行省外经营情况统计表
  @modification history:
  m0.author-create_date-description
  --需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：石雨，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
  --需求编号：JLBA202505140011_关于1104报表系统金融市场部报表取数逻辑变更的需求 上线日期：2025-07-29 修改人：常金磊，提出人：康立军 修改内容：调整债券、存单关联减值表的关联条件，解决关联重复问题
  --[JLBA202507210012_关于调整财政性存款及一般性存款相关科目统计方式的相关需求][提出人：于佳禾][上线时间：20250918][修改人：石雨][修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
  
目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_S2601_BAL_TMP1
     CBRC_S2601_SNDK_TEMP
     CBRC_TMP1_ACCT_DEPOSIT_S2601
     CBRC_TMP1_ACCT_LOAN_S2601
     CBRC_TMP2_ACCT_LOAN_S2601
     CBRC_TMP_ACCT_DEPOSIT_S2601
     CBRC_TMP_ACCT_LOAN_S2601
     CBRC_TMP_ASSET_DEVALUE_S2601
     CBRC_TMP_ISSUER_CUST_ID_S2601
     CBRC_TMP_PUBL_ORG_BRA_S2601

依赖表：CBRC_FAMS_S26_REPORT  --s26文件落地表 
     CBRC_TM_CBRC_G15_TEMP1
集市表：SMTMODS_L_ACCT_DEPOSIT
     SMTMODS_L_ACCT_LOAN
     SMTMODS_L_ACCT_LOAN_FARMING
     SMTMODS_L_ACCT_OBS_LOAN
     SMTMODS_L_AGRE_BONDISSUER_INFO
     SMTMODS_L_AGRE_BOND_INFO
     SMTMODS_L_CODE_DICTIONARY
     SMTMODS_L_CUST_ALL
     SMTMODS_L_CUST_BILL_TY
     SMTMODS_L_CUST_C
     SMTMODS_L_CUST_C_GROUP_INFO
     SMTMODS_L_CUST_C_GROUP_MEM
     SMTMODS_L_CUST_EXTERNAL_INFO
     SMTMODS_L_CUST_P
     SMTMODS_L_CUST_SUPLY_CHAIN
     SMTMODS_L_FINA_ASSET_DEVALUE
     SMTMODS_L_PUBL_ORG_BRA
     SMTMODS_L_PUBL_RATE
码值表：SMTMODS_S7001_CUST_TEMP
视图表：CBRC_V_PUB_FUND_INVEST
     SMTMODS_V_PUB_IDX_DK_DGSNDK
     SMTMODS_V_PUB_IDX_DK_GRSNDK
     SMTMODS_V_PUB_IDX_DK_GTGSHSNDK
     SMTMODS_V_PUB_IDX_DK_YSDQRJJ
     SMTMODS_V_PUB_IDX_SX_PHJRDKSX

  *******************************/
 IS
  --V_SCHEMA    VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE VARCHAR(30); --当前储存过程名称
  V_TAB_NAME  VARCHAR(30); --目标表名
  I_DATADATE  STRING; --数据日期(数值型)YYYYMMDD
  LAST_YEAR  STRING;
  D_DATADATE  VARCHAR(10); --
  --V_DATADATE  VARCHAR(10); --
  V_STEP_ID   INTEGER; --任务号
  V_ERRORCODE VARCHAR(20); --错误编码
  V_STEP_DESC VARCHAR(300); --任务描述
  V_STEP_FLAG INTEGER; --任务执行状态标识
  V_ERRORDESC VARCHAR(280); --错误内容
  II_STATUS    INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM    VARCHAR(30);
  
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';

    I_DATADATE  := II_DATADATE;
    LAST_YEAR   := SUBSTR(I_DATADATE,1,4) -1 || '1231';
    D_DATADATE  := I_DATADATE;
    --V_DATADATE  := TO_CHAR(TO_DATE(I_DATADATE, 'YYYYMMDD'), 'YYYY-MM-DD');
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_S2601');
	V_SYSTEM    := 'CBRC';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_TAB_NAME := 'CBRC_A_REPT_ITEM_VAL';

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']S2601当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'S26_I'
       AND T.FLAG = '2';
    COMMIT;

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP_ACCT_LOAN_S2601 '; --表内外各项贷款、债券投资
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP1_ACCT_LOAN_S2601'; --贸易融资、供应链
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP2_ACCT_LOAN_S2601'; --表内外各项贷款、债券投资除去法人机构以及分支机构所在省
	
    DELETE FROM CBRC_TMP_ACCT_DEPOSIT_S2601 T WHERE T.DATA_DATE = I_DATADATE ;
    COMMIT;
	
    DELETE FROM CBRC_TMP1_ACCT_DEPOSIT_S2601 T WHERE T.DATA_DATE = I_DATADATE ; --前十大
    COMMIT;
	
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP_ASSET_DEVALUE_S2601'; --减值临时表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP_ISSUER_CUST_ID_S2601'; --债券客户所属地区临时表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP_PUBL_ORG_BRA_S2601'; --机构临时表 去村镇

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --==================================================
    --机构临时表 去村镇
    --==================================================

    INSERT INTO CBRC_TMP_PUBL_ORG_BRA_S2601
      (DATA_DATE, ORG_NUM, ORG_NAM, REGION_CD)
      SELECT DATA_DATE, ORG_NUM, ORG_NAM, REGION_CD
        FROM SMTMODS_L_PUBL_ORG_BRA
       WHERE DATA_DATE = I_DATADATE
         AND ORG_NUM NOT LIKE '5%'
         AND ORG_NUM NOT LIKE '6%'
         AND ORG_NUM NOT IN ('012154','012150','012157','012155','012151','012153','012156','012152');
    COMMIT;
    --==================================================
    --债券客户所属地区临时表
    --==================================================

    INSERT INTO CBRC_TMP_ISSUER_CUST_ID_S2601
    (ISSUER_CUST_ID,REGION_CD,STOCK_CD)
    SELECT A.ISSUER_CUST_ID,COALESCE(B.CODE,C.REGION_CD,D.REGION_CD) REGION_CD,A.STOCK_CD
      FROM SMTMODS_L_AGRE_BONDISSUER_INFO A --债券发行人信息
      LEFT JOIN (SELECT DISTINCT SUBSTR(CODE, 1, 2) CODE,SUBSTR(CODE_DESCRIP, 1, 2) CODE_DESCRIP
                   FROM SMTMODS_L_CODE_DICTIONARY
                  WHERE CODE_CLMN_NAME = 'C0002'
                    AND SUBSTR(CODE, 1, 2) <> '22') B --去吉林
        ON DECODE(SUBSTR(A.ISSUER_CUST_ID, 1, 2),'鞍钢','鞍山',SUBSTR(A.ISSUER_CUST_ID, 1, 2)) = SUBSTR(B.CODE_DESCRIP, 1, 2)
      LEFT JOIN (SELECT T.CUST_NAM,MAX(SUBSTR(T.REGION_CD, 1, 2)) REGION_CD
                    FROM SMTMODS_L_CUST_C T
                   WHERE T.DATA_DATE = I_DATADATE
                    AND T.REGION_CD IS NOT NULL
                    AND SUBSTR(T.REGION_CD, 1, 2) <> '22'
                   GROUP BY T.CUST_NAM) C
        ON A.ISSUER_CUST_ID = C.CUST_NAM
      LEFT JOIN (SELECT T.FINA_ORG_NAME,MAX(B.CODE) REGION_CD
                    FROM SMTMODS_L_CUST_BILL_TY T
                    INNER JOIN (SELECT DISTINCT SUBSTR(CODE, 1, 2) CODE,SUBSTR(CODE_DESCRIP, 1, 2) CODE_DESCRIP
                                 FROM SMTMODS_L_CODE_DICTIONARY
                                WHERE CODE_CLMN_NAME = 'C0002'
                                  AND SUBSTR(CODE, 1, 2) <> '22') B --去吉林
                      ON DECODE(SUBSTR(T.BORROWER_REGISTER_ADDR, 1, 2),'鞍钢','鞍山',SUBSTR(T.BORROWER_REGISTER_ADDR, 1, 2)) = SUBSTR(B.CODE_DESCRIP, 1, 2)
                   WHERE T.DATA_DATE = I_DATADATE
                   GROUP BY T.FINA_ORG_NAME) D
        ON A.ISSUER_CUST_ID = D.FINA_ORG_NAME
     WHERE DATA_DATE = I_DATADATE
       AND COALESCE(B.CODE,C.REGION_CD,D.REGION_CD) IS NOT NULL  ;

       COMMIT;

    --==================================================
    --减值临时表
    --==================================================
    INSERT INTO CBRC_TMP_ASSET_DEVALUE_S2601
      (DATA_DATE,RECORD_ORG,BIZ_NO,CURR,PRIN_SUBJ_NO,FIVE_TIER_CLS,ACCT_NUM,PRIN_FINAL_RESLT,OFBS_FINAL_RESLT,INT_FINAL_RESLT,COLLBL_INT_FINAL_RESLT,ACCT_ID) --[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
      SELECT T.DATA_DATE,
             T.RECORD_ORG,
             T.BIZ_NO,
             T.CURR,
             T.PRIN_SUBJ_NO,
             CASE
               WHEN T.FIVE_TIER_CLS = '01' THEN
                 '1'
               WHEN T.FIVE_TIER_CLS = '02' THEN
                 '2'
               WHEN T.FIVE_TIER_CLS = '03' THEN
                 '3'
               WHEN T.FIVE_TIER_CLS = '04' THEN
                 '4'
               WHEN T.FIVE_TIER_CLS = '05' THEN
                 '5'
               ELSE '1'
             END FIVE_TIER_CLS,
             T.ACCT_NUM,
             SUM(NVL(T.PRIN_FINAL_RESLT, 0)) PRIN_FINAL_RESLT,
             SUM(NVL(T.OFBS_FINAL_RESLT, 0)) OFBS_FINAL_RESLT,
             SUM(NVL(T.INT_FINAL_RESLT, 0)) INT_FINAL_RESLT,
             SUM(NVL(T.COLLBL_INT_FINAL_RESLT, 0)) COLLBL_INT_FINAL_RESLT,
             ACCT_ID  --[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
        FROM SMTMODS_L_FINA_ASSET_DEVALUE T --资产减值准备
       WHERE T.DATA_DATE = I_DATADATE
        AND T.DATA_SRC <> 'CCRD'
       GROUP BY T.RECORD_ORG,T.BIZ_NO,T.CURR,T.PRIN_SUBJ_NO,T.FIVE_TIER_CLS,T.DATA_DATE,T.ACCT_NUM,T.ACCT_ID; --[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
    COMMIT;

    --=====================================
    -- 第I部分：全口径省外融资.省外授信业务总体情况
    --=====================================

    --=====================================
    --   S2601 第一部分中间表
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := 'S2601 第一部分中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP_ACCT_LOAN_S2601
      (DATA_DATE, ORG_NUM,REGION_CD_CUST, CUST_ID, ACCT_NUM,MATUR_DATE, LOAN_GRADE_CD, BALANCE, PRIN_FINAL_RESLT,OFBS_FINAL_RESLT,GL_ITEM_CODE,TAG,TAG1)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             --COALESCE(B.REGION_CD,B.ORG_AREA,'&') AS REGION_CD_CUST,
             NVL(B.REGION_CD,B.ORG_AREA) AS REGION_CD_CUST,
             A.CUST_ID AS CUST_ID,
             A.LOAN_NUM AS ACCT_NUM,
             CASE
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT), D_DATADATE) <= 12 THEN
                '1' -- 一年以内（含一年）
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT), D_DATADATE) > 12 AND MONTHS_BETWEEN(DATE(A.MATURITY_DT), D_DATADATE) <= 60 THEN
                '2' -- 一年至五年（含五年）
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT), D_DATADATE) > 60 AND MONTHS_BETWEEN(DATE(A.MATURITY_DT), D_DATADATE) <= 120 THEN
                '3' -- 五年至十年（含十年）
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT), D_DATADATE) > 120 THEN
                '4' -- 十年以上
             END AS MATURITY_DT,
             A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
             A.LOAN_ACCT_BAL * U.CCY_RATE AS ACCT_BAL,
             NVL(C.PRIN_FINAL_RESLT,0) AS PRIN_FINAL_RESLT,
             NVL(C.OFBS_FINAL_RESLT,0) AS OFBS_FINAL_RESLT,
             A.ITEM_CD AS GL_ITEM_CODE,
             DECODE(SUBSTR(D.REGION_CD, 1, 2), '22', 'SN', 'SY') AS TAG,
             'DK' AS TAG1 --各项贷款
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_TMP_ASSET_DEVALUE_S2601 C
          ON A.LOAN_NUM = C.BIZ_NO
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA D
          ON A.ORG_NUM = D.ORG_NUM
         AND D.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --去委托贷款
         AND A.ACCT_STS <> '3' --去结清
         AND A.CANCEL_FLG <> 'Y' --去核销
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.LOAN_ACCT_BAL > 0
         AND SUBSTR(B.CUST_TYP,1,1) IN ('0','1')  --企业
         AND CORP_BUSINSESS_TYPE NOT LIKE 'J%' --非金融企业
         AND SUBSTR(NVL(B.REGION_CD,B.ORG_AREA),1,2) <> '22' --去吉林  空值暂时不取
      ;
    COMMIT;

    INSERT INTO CBRC_TMP_ACCT_LOAN_S2601
      (DATA_DATE, ORG_NUM,REGION_CD_CUST, CUST_ID,ACCT_NUM,MATUR_DATE, LOAN_GRADE_CD, BALANCE, PRIN_FINAL_RESLT,OFBS_FINAL_RESLT,GL_ITEM_CODE,TAG,TAG1)
    --债券投资 非标信托
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             NVL(E.ORG_AREA,G.AFLT_PROV) AS REGION_CD_CUST, --客户所属地区 住所或经营所在地行政区划
             NVL(E.ECIF_CUST_ID,G.CUST_ID) AS CUST_ID,
             A.ACCT_NUM AS ACCT_NUM,
             CASE
               WHEN (A.DC_DATE <= 360 OR A.ACCT_NUM = 'X0003120B2700001') THEN      '1' -- 一年以内（含一年）
               WHEN A.DC_DATE / 360 <= 5 THEN  '2' -- 一年至五年（含五年）
               WHEN A.DC_DATE / 360 <= 10 THEN '3' -- 五年至十年（含十年）
               WHEN A.DC_DATE / 360 > 10 THEN  '4' -- 十年以上
             END AS MATURITY_DT,
             NVL(C.FIVE_TIER_CLS, 1) AS LOAN_GRADE_CD, --使用减值表的五级分类，为空放正常
             A.PRINCIPAL_BALANCE * U.CCY_RATE AS ACCT_BAL,
             CASE
               WHEN SUBSTR(A.GL_ITEM_CODE,1,4) = '1101' THEN 0
               ELSE NVL(C.PRIN_FINAL_RESLT,0)
             END AS PRIN_FINAL_RESLT,
             CASE
               WHEN SUBSTR(A.GL_ITEM_CODE,1,4) = '1101' THEN 0
               ELSE NVL(C.OFBS_FINAL_RESLT,0)
             END AS OFBS_FINAL_RESLT,
             A.GL_ITEM_CODE AS GL_ITEM_CODE,
             DECODE(SUBSTR(D.REGION_CD, 1, 2), '22', 'SN', 'SY') AS TAG,
             DECODE(A.INVEST_TYP, '11', 'DK','04','FB', 'ZQ') AS TAG1 --买断式转贴
        FROM CBRC_V_PUB_FUND_INVEST A
        LEFT JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_TMP_ASSET_DEVALUE_S2601 C
          ON A.ACCT_NUM = C.BIZ_NO
         AND A.ACCT_NO = C.ACCT_ID  --[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
         AND A.ORG_NUM=C.RECORD_ORG
         AND A.GL_ITEM_CODE = C.PRIN_SUBJ_NO
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA D
          ON A.ORG_NUM = D.ORG_NUM
         AND D.DATA_DATE = I_DATADATE
        LEFT JOIN (SELECT CUST_ID,TYSHXYDM,ECIF_CUST_ID,ORG_AREA,
                    ROW_NUMBER() OVER(PARTITION BY A.ECIF_CUST_ID ORDER BY A.ECIF_CUST_ID) RN
               FROM SMTMODS_L_CUST_BILL_TY A --一个ECIF客户对应,多个同业客户,对应一个公司/银行名
              WHERE A.DATA_DATE = I_DATADATE) E
          ON E.ECIF_CUST_ID = A.CUST_ID
         AND E.RN = '1'
        LEFT JOIN SMTMODS_L_CUST_EXTERNAL_INFO G
          ON G.CUST_ID = A.CUST_ID
         AND G.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND ((B.STOCK_ASSET_TYPE IS NULL
                AND B.ISSUER_INLAND_FLG = 'Y'
                AND (SUBSTR(B.STOCK_PRO_TYPE, 1, 1) = 'D' AND B.ISSU_ORG LIKE 'C%')--D 非金融企业债  发行主题： C  企业
                AND A.INVEST_TYP ='00' --债券投资
               OR A.INVEST_TYP = '04') --信托
             )
         AND A.PRINCIPAL_BALANCE <> 0
         AND A.ORG_NUM = '009804'
         AND SUBSTR(NVL(E.ORG_AREA,G.AFLT_PROV),1,2) NOT IN '22'
      ;
    COMMIT;


    INSERT INTO CBRC_TMP_ACCT_LOAN_S2601
      (DATA_DATE, ORG_NUM,REGION_CD_CUST, CUST_ID,ACCT_NUM, MATUR_DATE, LOAN_GRADE_CD, BALANCE, PRIN_FINAL_RESLT,OFBS_FINAL_RESLT,GL_ITEM_CODE,TAG,TAG1)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             --COALESCE(B.REGION_CD,B.ORG_AREA,'&') AS REGION_CD_CUST,
             NVL(B.REGION_CD,B.ORG_AREA) AS REGION_CD_CUST,
             A.CUST_ID AS CUST_ID, --
             A.ACCT_NUM AS ACCT_NUM,
             CASE
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(D_DATADATE)) <= 12 THEN
                '1' -- 一年以内（含一年）
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(D_DATADATE)) > 12 AND MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(D_DATADATE)) <= 60 THEN
                '2' -- 一年至五年（含五年）
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(D_DATADATE)) > 60 AND MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(D_DATADATE)) <= 120 THEN
                '3' -- 五年至十年（含十年）
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(D_DATADATE)) > 120 THEN
                '4' -- 十年以上
             END AS MATURITY_DT,
             NVL(C.FIVE_TIER_CLS,1) AS LOAN_GRADE_CD, --使用减值表的五级分类，为空放正常
             A.BALANCE * U.CCY_RATE AS ACCT_BAL,
             NVL(C.PRIN_FINAL_RESLT,0) AS PRIN_FINAL_RESLT,
             NVL(C.OFBS_FINAL_RESLT,0) AS OFBS_FINAL_RESLT,
             A.GL_ITEM_CODE AS GL_ITEM_CODE,
             DECODE(SUBSTR(D.REGION_CD, 1, 2), '22', 'SN', 'SY') AS TAG,
             CASE
               --WHEN (A.ACCT_TYP LIKE '6%' OR SUBSTR(A.GL_ITEM_CODE, 1, 4) = '7030') --LIKE 6% 信用风险仍在银行的销售与购买协议 7030 承诺
               WHEN SUBSTR(A.GL_ITEM_CODE, 1, 4) = '7030' -- 承诺
                THEN
                'CN'
               WHEN SUBSTR(A.GL_ITEM_CODE, 1, 4) = '7020' THEN --银城
                'YC'
               WHEN SUBSTR(A.GL_ITEM_CODE, 1, 4) IN ('7040', '7010') THEN --担保（信用证、保函）
                'DB'
             END AS TAG1
        FROM SMTMODS_L_ACCT_OBS_LOAN A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_TMP_ASSET_DEVALUE_S2601 C
          ON A.ACCT_NUM = C.ACCT_NUM
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA D
          ON A.ORG_NUM = D.ORG_NUM
         AND D.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON A.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE SUBSTR(A.GL_ITEM_CODE, 1, 4) IN ('7010', '7020', '7030', '7040') --信用证、银行承兑、保函、承诺
         AND A.DATA_DATE = I_DATADATE
         AND SUBSTR(NVL(B.REGION_CD,B.ORG_AREA),1,2) <> '22' --去吉林  空值先不取
         AND SUBSTR(B.CUST_TYP,1,1) IN ('0','1')  --企业
         AND CORP_BUSINSESS_TYPE NOT LIKE 'J%' --非金融企业
         AND A.ACCT_STS = '1' --账户状态为有效
      ;
    COMMIT;

    --=====================================
    --   S2601 1.1全口径省外融资.剩余期限
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '全口径省外融资.剩余期限';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
    (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       CASE
         WHEN A.TAG1 = 'DK' THEN
           CASE
             WHEN A.MATUR_DATE = '1' THEN 'S26_I_1.1.1.B.2024'
             WHEN A.MATUR_DATE = '2' THEN 'S26_I_1.1.2.B.2024'
             WHEN A.MATUR_DATE = '3' THEN 'S26_I_1.1.3.B.2024'
             WHEN A.MATUR_DATE = '4' THEN 'S26_I_1.1.4.B.2024'
           END
         WHEN A.TAG1 = 'ZQ' THEN
           CASE
             WHEN A.MATUR_DATE = '1' THEN 'S26_I_1.1.1.C.2024'
             WHEN A.MATUR_DATE = '2' THEN 'S26_I_1.1.2.C.2024'
             WHEN A.MATUR_DATE = '3' THEN 'S26_I_1.1.3.C.2024'
             WHEN A.MATUR_DATE = '4' THEN 'S26_I_1.1.4.C.2024'
           END
         WHEN A.TAG1 = 'FB' THEN
           CASE
             WHEN A.MATUR_DATE = '1' THEN 'S26_I_1.1.1.D.2024'
             WHEN A.MATUR_DATE = '2' THEN 'S26_I_1.1.2.D.2024'
             WHEN A.MATUR_DATE = '3' THEN 'S26_I_1.1.3.D.2024'
             WHEN A.MATUR_DATE = '4' THEN 'S26_I_1.1.4.D.2024'
           END
         WHEN A.TAG1 = 'YC' THEN
           CASE
             WHEN A.MATUR_DATE = '1' THEN 'S26_I_1.1.1.G.2024'
             WHEN A.MATUR_DATE = '2' THEN 'S26_I_1.1.2.G.2024'
             WHEN A.MATUR_DATE = '3' THEN 'S26_I_1.1.3.G.2024'
             WHEN A.MATUR_DATE = '4' THEN 'S26_I_1.1.4.G.2024'
           END
         WHEN A.TAG1 = 'CN' THEN
           CASE
             WHEN A.MATUR_DATE = '1' THEN 'S26_I_1.1.1.H.2024'
             WHEN A.MATUR_DATE = '2' THEN 'S26_I_1.1.2.H.2024'
             WHEN A.MATUR_DATE = '3' THEN 'S26_I_1.1.3.H.2024'
             WHEN A.MATUR_DATE = '4' THEN 'S26_I_1.1.4.H.2024'
           END
       END AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
        AND A.TAG1 IN ('DK','ZQ','YC','CN','FB')
      GROUP BY A.ORG_NUM,
               CASE
                 WHEN A.TAG1 = 'DK' THEN
                   CASE
                     WHEN A.MATUR_DATE = '1' THEN 'S26_I_1.1.1.B.2024'
                     WHEN A.MATUR_DATE = '2' THEN 'S26_I_1.1.2.B.2024'
                     WHEN A.MATUR_DATE = '3' THEN 'S26_I_1.1.3.B.2024'
                     WHEN A.MATUR_DATE = '4' THEN 'S26_I_1.1.4.B.2024'
                   END
                 WHEN A.TAG1 = 'ZQ' THEN
                   CASE
                     WHEN A.MATUR_DATE = '1' THEN 'S26_I_1.1.1.C.2024'
                     WHEN A.MATUR_DATE = '2' THEN 'S26_I_1.1.2.C.2024'
                     WHEN A.MATUR_DATE = '3' THEN 'S26_I_1.1.3.C.2024'
                     WHEN A.MATUR_DATE = '4' THEN 'S26_I_1.1.4.C.2024'
                   END
                 WHEN A.TAG1 = 'FB' THEN
                   CASE
                     WHEN A.MATUR_DATE = '1' THEN 'S26_I_1.1.1.D.2024'
                     WHEN A.MATUR_DATE = '2' THEN 'S26_I_1.1.2.D.2024'
                     WHEN A.MATUR_DATE = '3' THEN 'S26_I_1.1.3.D.2024'
                     WHEN A.MATUR_DATE = '4' THEN 'S26_I_1.1.4.D.2024'
                   END
                 WHEN A.TAG1 = 'YC' THEN
                   CASE
                     WHEN A.MATUR_DATE = '1' THEN 'S26_I_1.1.1.G.2024'
                     WHEN A.MATUR_DATE = '2' THEN 'S26_I_1.1.2.G.2024'
                     WHEN A.MATUR_DATE = '3' THEN 'S26_I_1.1.3.G.2024'
                     WHEN A.MATUR_DATE = '4' THEN 'S26_I_1.1.4.G.2024'
                   END
                 WHEN A.TAG1 = 'CN' THEN
                   CASE
                     WHEN A.MATUR_DATE = '1' THEN 'S26_I_1.1.1.H.2024'
                     WHEN A.MATUR_DATE = '2' THEN 'S26_I_1.1.2.H.2024'
                     WHEN A.MATUR_DATE = '3' THEN 'S26_I_1.1.3.H.2024'
                     WHEN A.MATUR_DATE = '4' THEN 'S26_I_1.1.4.H.2024'
                   END
               END;
    COMMIT;


    INSERT INTO CBRC_A_REPT_ITEM_VAL --担保类
    (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       CASE
         WHEN A.MATUR_DATE = '1' THEN 'S26_I_1.1.1.F.2024'
         WHEN A.MATUR_DATE = '2' THEN 'S26_I_1.1.2.F.2024'
         WHEN A.MATUR_DATE = '3' THEN 'S26_I_1.1.3.F.2024'
         WHEN A.MATUR_DATE = '4' THEN 'S26_I_1.1.4.F.2024'
       END AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
        AND A.TAG1 IN ('DB','YC')
      GROUP BY A.ORG_NUM,
               CASE
                 WHEN A.MATUR_DATE = '1' THEN 'S26_I_1.1.1.F.2024'
                 WHEN A.MATUR_DATE = '2' THEN 'S26_I_1.1.2.F.2024'
                 WHEN A.MATUR_DATE = '3' THEN 'S26_I_1.1.3.F.2024'
                 WHEN A.MATUR_DATE = '4' THEN 'S26_I_1.1.4.F.2024'
               END;
    COMMIT;


    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 1.2.1全口径省外融资.不良资产余额
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '全口径省外融资.不良资产余额';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
    (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       CASE
         WHEN A.TAG1 = 'DK' THEN 'S26_I_1.2.1.B.2024'
         WHEN A.TAG1 = 'ZQ' THEN 'S26_I_1.2.1.C.2024'
         WHEN A.TAG1 = 'FB' THEN 'S26_I_1.2.1.D.2024'
         WHEN A.TAG1 = 'YC' THEN 'S26_I_1.2.1.G.2024'
         WHEN A.TAG1 = 'CN' THEN 'S26_I_1.2.1.H.2024'
       END AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
        AND A.TAG1 IN ('DK','ZQ','YC','CN','FB')
        AND A.LOAN_GRADE_CD IN ('3','4','5') --五级分类：次级 可疑 损失
      GROUP BY A.ORG_NUM,
               CASE
                 WHEN A.TAG1 = 'DK' THEN 'S26_I_1.2.1.B.2024'
                 WHEN A.TAG1 = 'ZQ' THEN 'S26_I_1.2.1.C.2024'
                 WHEN A.TAG1 = 'FB' THEN 'S26_I_1.2.1.D.2024'
                 WHEN A.TAG1 = 'YC' THEN 'S26_I_1.2.1.G.2024'
                 WHEN A.TAG1 = 'CN' THEN 'S26_I_1.2.1.H.2024'
               END;
    COMMIT;


    INSERT INTO CBRC_A_REPT_ITEM_VAL
    (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       'S26_I_1.2.1.F.2024' AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
        AND A.LOAN_GRADE_CD IN ('3','4','5')
        AND A.TAG1 IN ('DB','YC')
      GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   --=====================================
    --   S2601 1.2.2全口径省外融资.各项减值准备
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '全口径省外融资.各项减值准备';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
    (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       CASE
         WHEN A.TAG1 = 'DK' THEN 'S26_I_1.2.2.B.2024'
         WHEN A.TAG1 = 'ZQ' THEN 'S26_I_1.2.2.C.2024'
         WHEN A.TAG1 = 'FB' THEN 'S26_I_1.2.2.D.2024'
         WHEN A.TAG1 = 'YC' THEN 'S26_I_1.2.2.G.2024'
         WHEN A.TAG1 = 'CN' THEN 'S26_I_1.2.2.H.2024'
       END AS ITEM_NUM,
       --SUM(DECODE(A.TAG1,'DK',NVL(A.PRIN_FINAL_RESLT,0),'ZQ',NVL(A.PRIN_FINAL_RESLT,0),NVL(A.OFBS_FINAL_RESLT,0))) AS ITEM_VAL,
       SUM(NVL(A.PRIN_FINAL_RESLT,0)+NVL(A.OFBS_FINAL_RESLT,0)) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
        AND A.TAG1 IN ('DK','ZQ','YC','CN','FB')
      GROUP BY A.ORG_NUM,
               CASE
                 WHEN A.TAG1 = 'DK' THEN 'S26_I_1.2.2.B.2024'
                 WHEN A.TAG1 = 'ZQ' THEN 'S26_I_1.2.2.C.2024'
                 WHEN A.TAG1 = 'FB' THEN 'S26_I_1.2.2.D.2024'
                 WHEN A.TAG1 = 'YC' THEN 'S26_I_1.2.2.G.2024'
                 WHEN A.TAG1 = 'CN' THEN 'S26_I_1.2.2.H.2024'
               END;
    COMMIT;


    INSERT INTO CBRC_A_REPT_ITEM_VAL
    (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       'S26_I_1.2.2.F.2024' AS ITEM_NUM,
       SUM(NVL(A.PRIN_FINAL_RESLT,0)+NVL(A.OFBS_FINAL_RESLT,0)) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
        AND A.TAG1 IN ('DB','YC')
      GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


   --=====================================
    --   S2601 1.3.1全口径省外融资.省内机构发放余额（包括总行及总行所在省内分支机构）
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '全口径省外融资.省内机构发放余额（包括总行及总行所在省内分支机构）';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
    (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       CASE
         WHEN A.TAG1 = 'DK' THEN 'S26_I_1.3.1.B.2024'
         WHEN A.TAG1 = 'ZQ' THEN 'S26_I_1.3.1.C.2024'
         WHEN A.TAG1 = 'FB' THEN 'S26_I_1.3.1.D.2024'
         WHEN A.TAG1 = 'YC' THEN 'S26_I_1.3.1.G.2024'
         WHEN A.TAG1 = 'CN' THEN 'S26_I_1.3.1.H.2024'
       END AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
        AND A.TAG1 IN ('DK','ZQ','YC','CN','FB')
        AND A.TAG = 'SN' --省内业务
      GROUP BY A.ORG_NUM,
               CASE
                 WHEN A.TAG1 = 'DK' THEN 'S26_I_1.3.1.B.2024'
                 WHEN A.TAG1 = 'ZQ' THEN 'S26_I_1.3.1.C.2024'
                 WHEN A.TAG1 = 'FB' THEN 'S26_I_1.3.1.D.2024'
                 WHEN A.TAG1 = 'YC' THEN 'S26_I_1.3.1.G.2024'
                 WHEN A.TAG1 = 'CN' THEN 'S26_I_1.3.1.H.2024'
               END;
    COMMIT;


    INSERT INTO CBRC_A_REPT_ITEM_VAL
    (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       'S26_I_1.3.1.F.2024' AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
        AND A.TAG1 IN ('DB','YC')
        AND A.TAG = 'SN' --省内业务
      GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


   --=====================================
    --   S2601 1.3.2全口径省外融资.省外分支机构发放余额
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '全口径省外融资.省外分支机构发放余额）';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
    (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       CASE
         WHEN A.TAG1 = 'DK' THEN 'S26_I_1.3.2.B.2024'
         WHEN A.TAG1 = 'ZQ' THEN 'S26_I_1.3.2.C.2024'
         WHEN A.TAG1 = 'FB' THEN 'S26_I_1.3.2.D.2024'
         WHEN A.TAG1 = 'YC' THEN 'S26_I_1.3.2.G.2024'
         WHEN A.TAG1 = 'CN' THEN 'S26_I_1.3.2.H.2024'
       END AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
        AND A.TAG1 IN ('DK','ZQ','YC','CN','FB')
        AND A.TAG = 'SY'  --省外业务
      GROUP BY A.ORG_NUM,
               CASE
                 WHEN A.TAG1 = 'DK' THEN 'S26_I_1.3.2.B.2024'
                 WHEN A.TAG1 = 'ZQ' THEN 'S26_I_1.3.2.C.2024'
                 WHEN A.TAG1 = 'FB' THEN 'S26_I_1.3.2.D.2024'
                 WHEN A.TAG1 = 'YC' THEN 'S26_I_1.3.2.G.2024'
                 WHEN A.TAG1 = 'CN' THEN 'S26_I_1.3.2.H.2024'
               END;
    COMMIT;


    INSERT INTO CBRC_A_REPT_ITEM_VAL
    (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       'S26_I_1.3.2.F.2024' AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
        AND A.TAG1 IN ('DB','YC')
        AND A.TAG = 'SY' --省外业务
      GROUP BY A.ORG_NUM;
    COMMIT;


    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --=====================================
    --   S2601 1.4投向法人所在省份外的小微企业贷款余额
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '1.4投向法人所在省份外的小微企业贷款余额';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   --此处依赖S7101报表取数
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       'S26_I_1.4.A.2024' AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_S7101_BAL_TMP1 A --贷款借据信息表
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.CORP_SCALE IN ('S', 'T') --小微企业
         AND A.ITEM_CD NOT LIKE '1301%' ---刨除票据
         AND A.FACILITY_AMT <= 10000000 --单户授信总额1000万元以下，单户授信1000万元（含）以下不含票据融资合计
         AND SUBSTR(NVL(B.REGION_CD,B.ORG_AREA),1,2) <> '22' --去吉林  空值先不取
         AND SUBSTR(B.CUST_TYP,1,1) IN ('0','1')  --企业
         AND CORP_BUSINSESS_TYPE NOT LIKE 'J%' --非金融企业
       GROUP BY A.ORG_NUM
      ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 1.5投向法人所在省份外的关联企业融资余额
    --=====================================


    V_STEP_ID   := 1;
    V_STEP_DESC := '1.5投向法人所在省份外的关联企业融资余额';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --关联企业 依赖G15
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
        SELECT
         I_DATADATE AS DATA_DATE,
         B.ORG_CODE AS ORG_NUM,
         'CBRC' AS SYS_NAM,
         'S26_I' AS REP_NUM,
         'S26_I_1.5.A.2024' AS ITEM_NUM,
         SUM(T.BALANCE) AS ITEM_VAL,
         '2' AS FLAG
        FROM (SELECT 
                L.ORG_NUM, SUM(L.LOAN_ACCT_BAL) BALANCE --贷款余额
                FROM CBRC_TM_CBRC_G15_TEMP1 G
               INNER JOIN SMTMODS_L_CUST_C A
                  ON G.ID_NO = A.ID_NO
                 AND A.DATA_DATE = G.DDATE
               INNER JOIN SMTMODS_L_ACCT_LOAN L
                  ON A.CUST_ID = L.CUST_ID
                 AND L.DATA_DATE = A.DATA_DATE
                 AND L.LOAN_ACCT_BAL <> 0
                 AND L.ACCT_TYP NOT LIKE '90%'
               WHERE A.DATA_DATE = I_DATADATE
                 AND L.CANCEL_FLG = 'N'
          AND L.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
                 AND LENGTHB(L.ACCT_NUM) < 36
                 AND SUBSTR(A.CUST_TYP, 1, 1) IN ('0', '1') --企业
                 AND A.CORP_BUSINSESS_TYPE NOT LIKE 'J%' --非金融企业
                 AND SUBSTR(NVL(A.REGION_CD, A.ORG_AREA), 1, 2) <> '22' --去吉林  空值暂时不取
               GROUP BY L.ORG_NUM) T
       INNER JOIN cbrc_TM_L_ORG_FLAT B
          ON T.ORG_NUM = B.SUB_ORG_CODE
       GROUP BY B.ORG_CODE;

  COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 1.6投向法人所在省份外的前十大非金融企业集团客户融资余额合计
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '1.6投向法人所在省份外的前十大非金融企业集团客户融资余额合计';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
    SELECT 
     I_DATADATE AS DATA_DATE,
     ORG_NUM AS ORG_NUM,
     'CBRC' AS SYS_NAM,
     'S26_I' AS REP_NUM,
     'S26_I_1.6.A.2024' AS ITEM_NUM,
     SUM(LOAN_ACCT_BAL) AS ITEM_VAL,
     '2' AS FLAG
      FROM (SELECT T2.ORG_NUM, T2.CUST_GROUP_NO, T2.LOAN_ACCT_BAL, SEQ_NO
              FROM (SELECT T1.*,
                           ROW_NUMBER() OVER(PARTITION BY T1.ORG_NUM ORDER BY T1.LOAN_ACCT_BAL DESC, T1.ORG_NUM, T1.CUST_GROUP_NO) AS SEQ_NO
                      FROM (SELECT B.ORG_CODE AS ORG_NUM,
                                   T.CUST_GROUP_NO,
                                   SUM(LOAN_ACCT_BAL) LOAN_ACCT_BAL
                              FROM (SELECT 
                                     A.ORG_NUM AS ORG_NUM,
                                     D.CUST_GROUP_NO AS CUST_GROUP_NO,
                                     SUM(A.BALANCE) AS LOAN_ACCT_BAL
                                      FROM CBRC_TMP_ACCT_LOAN_S2601 A
                                     INNER JOIN SMTMODS_L_CUST_C_GROUP_MEM B --集团成员信息
                                        ON A.CUST_ID = B.GROUP_MEM_NO --成员代码
                                       AND B.DATA_DATE = I_DATADATE
                                     INNER JOIN SMTMODS_L_CUST_C C
                                        ON A.CUST_ID = C.CUST_ID
                                       AND C.DATA_DATE = I_DATADATE
                                     INNER JOIN SMTMODS_L_CUST_C_GROUP_INFO D
                                        ON B.CUST_GROUP_NO = D.CUST_GROUP_NO
                                       AND D.DATA_DATE = I_DATADATE
                                     WHERE A.DATA_DATE = I_DATADATE
                                     GROUP BY A.ORG_NUM, D.CUST_GROUP_NO) T
                             INNER JOIN CBRC_TM_L_ORG_FLAT B
                                ON T.ORG_NUM = B.SUB_ORG_CODE
                             GROUP BY B.ORG_CODE, T.CUST_GROUP_NO) T1) T2
             WHERE SEQ_NO <= 10)
     GROUP BY ORG_NUM;

    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --=====================================
    --   S2601 CBRC_TMP1_ACCT_LOAN_S2601 贸易融资、供应链融资临时表
    --=====================================

    INSERT INTO CBRC_TMP1_ACCT_LOAN_S2601
      (DATA_DATE, ORG_NUM,REGION_CD_CUST, CUST_ID, ACCT_NUM,MATUR_DATE, LOAN_GRADE_CD, BALANCE, PRIN_FINAL_RESLT,OFBS_FINAL_RESLT,GL_ITEM_CODE,TAG,TAG1)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             A.REGION_CD_CUST AS REGION_CD_CUST,
             A.CUST_ID AS CUST_ID,
             A.ACCT_NUM AS ACCT_NUM,
             A.MATUR_DATE AS MATURITY_DT,
             A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
             A.BALANCE AS ACCT_BAL,
             A.PRIN_FINAL_RESLT AS PRIN_FINAL_RESLT,
             A.OFBS_FINAL_RESLT AS OFBS_FINAL_RESLT,
             A.GL_ITEM_CODE AS GL_ITEM_CODE,
             A.TAG AS TAG,
             'MYRZ' AS TAG1 --贸易融资
        FROM CBRC_TMP_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.GL_ITEM_CODE LIKE '1305%' --贸易融资
         --用于法人及分支机构所在省份以外的贸易融资
         AND NOT EXISTS (SELECT 1 FROM CBRC_TMP_PUBL_ORG_BRA_S2601 T WHERE T.DATA_DATE = I_DATADATE AND SUBSTR(T.REGION_CD,1,2) = SUBSTR(A.REGION_CD_CUST,1,2))
      ;
    COMMIT;

    INSERT INTO CBRC_TMP1_ACCT_LOAN_S2601
      (DATA_DATE, ORG_NUM,REGION_CD_CUST, CUST_ID, ACCT_NUM,MATUR_DATE, LOAN_GRADE_CD, BALANCE, PRIN_FINAL_RESLT,OFBS_FINAL_RESLT,GL_ITEM_CODE,TAG,TAG1)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             A.REGION_CD_CUST AS REGION_CD_CUST,
             A.CUST_ID AS CUST_ID,
             A.ACCT_NUM AS ACCT_NUM,
             A.MATUR_DATE AS MATURITY_DT,
             A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
             A.BALANCE AS ACCT_BAL,
             A.PRIN_FINAL_RESLT AS PRIN_FINAL_RESLT,
             A.OFBS_FINAL_RESLT AS OFBS_FINAL_RESLT,
             A.GL_ITEM_CODE AS GL_ITEM_CODE,
             A.TAG AS TAG,
             'GYL' AS TAG1 --供应链
        FROM CBRC_TMP_ACCT_LOAN_S2601 A
        INNER JOIN (SELECT DISTINCT CUST_ID FROM SMTMODS_L_CUST_SUPLY_CHAIN WHERE DATA_DATE = I_DATADATE AND CUST_TYP = 'A') E
          ON A.CUST_ID = E.CUST_ID
       WHERE A.DATA_DATE = I_DATADATE
         AND NOT EXISTS (SELECT 1 FROM CBRC_TMP_PUBL_ORG_BRA_S2601 T WHERE T.DATA_DATE = I_DATADATE AND SUBSTR(T.REGION_CD,1,2) = SUBSTR(A.REGION_CD_CUST,1,2))
      ;
    COMMIT;


    --=====================================
    --   S2601 1.7.1用于法人及分支机构所在省份以外的贸易融资（不含债券投资、理财投资）
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '1.7.1用于法人及分支机构所在省份以外的贸易融资（不含债券投资、理财投资）';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       'S26_I_1.7.1.A.2024' AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP1_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
        AND TAG1 = 'MYRZ'
       GROUP BY A.ORG_NUM;
    COMMIT;


    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --=====================================
    --   S2601 1.7.2用于法人及分支机构所在省份以外的供应链融资融资（不含债券投资、理财投资）
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '1.7.2用于法人及分支机构所在省份以外的供应链融资融资（不含债券投资、理财投资）';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       'S26_I_1.7.2.A.2024' AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP1_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
        AND TAG1 = 'GYL'
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 法人及分支机构所在省份以外的贷款、债券等临时表
    --=====================================

    INSERT INTO CBRC_TMP2_ACCT_LOAN_S2601
      (DATA_DATE, ORG_NUM,REGION_CD_CUST, CUST_ID, ACCT_NUM,MATUR_DATE, LOAN_GRADE_CD, BALANCE, PRIN_FINAL_RESLT,OFBS_FINAL_RESLT,GL_ITEM_CODE,TAG,TAG1)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             A.REGION_CD_CUST AS REGION_CD_CUST,
             A.CUST_ID AS CUST_ID,
             A.ACCT_NUM AS ACCT_NUM,
             A.MATUR_DATE AS MATURITY_DT,
             A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
             A.BALANCE AS ACCT_BAL,
             A.PRIN_FINAL_RESLT AS PRIN_FINAL_RESLT,
             A.OFBS_FINAL_RESLT AS OFBS_FINAL_RESLT,
             A.GL_ITEM_CODE AS GL_ITEM_CODE,
             A.TAG AS TAG,
             A.TAG1 AS TAG1
        FROM CBRC_TMP_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.TAG1 <> 'ZQ'
         AND NOT EXISTS (SELECT 1
                            FROM CBRC_TMP_PUBL_ORG_BRA_S2601 T
                          WHERE T.DATA_DATE = I_DATADATE
                            AND SUBSTR(T.REGION_CD,1,2) = SUBSTR(A.REGION_CD_CUST,1,2))  --去掉分支机构
         AND NOT EXISTS (SELECT 1
                            FROM CBRC_TMP1_ACCT_LOAN_S2601 T
                           WHERE T.DATA_DATE = I_DATADATE
                             AND A.ACCT_NUM = T.ACCT_NUM) --去掉贸易融资 供应链融资数据
      ;
    COMMIT;

    --=====================================
    --   S2601 1.7.3用于法人及分支机构所在省份以外的信用债投资余额
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '1.7.3用于法人及分支机构所在省份以外的信用债投资余额';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--该指标，业务提出不取数 20240701 金融市场部需求   'S26_I_1.7.3.A.2024'


    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 1.7.4用于法人及分支机构所在省份以外的理财投资余额
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '1.7.4用于法人及分支机构所在省份以外的理财投资余额';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

     INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
     SELECT I_DATADATE AS DATA_DATE,
             '009816' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'S26_I' AS REP_NUM,
             'S26_I_1.7.4.A.2024' AS ITEM_NUM,
             BALANCE AS ITEM_VAL,
             '2' AS FLAG
     FROM CBRC_FAMS_S26_REPORT T
     WHERE T.DATA_DATE = I_DATADATE;

     COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --=====================================
    -- 第I部分：重点监测口径省外融资.省外授信业务总体情况
    --=====================================

    --=====================================
    --   S2601 重点监测口径省外融资.剩余期限
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '重点监测口径省外融资.剩余期限';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
    (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       CASE
         WHEN A.TAG1 = 'DK' THEN
           CASE
             WHEN A.MATUR_DATE = '1' THEN 'S26_I_2.1.1.B.2024'
             WHEN A.MATUR_DATE = '2' THEN 'S26_I_2.1.2.B.2024'
             WHEN A.MATUR_DATE = '3' THEN 'S26_I_2.1.3.B.2024'
             WHEN A.MATUR_DATE = '4' THEN 'S26_I_2.1.4.B.2024'
           END
         WHEN A.TAG1 = 'FB' THEN
           CASE
             WHEN A.MATUR_DATE = '1' THEN 'S26_I_2.1.1.D.2024'
             WHEN A.MATUR_DATE = '2' THEN 'S26_I_2.1.2.D.2024'
             WHEN A.MATUR_DATE = '3' THEN 'S26_I_2.1.3.D.2024'
             WHEN A.MATUR_DATE = '4' THEN 'S26_I_2.1.4.D.2024'
           END
         WHEN A.TAG1 = 'YC' THEN
           CASE
             WHEN A.MATUR_DATE = '1' THEN 'S26_I_2.1.1.G.2024'
             WHEN A.MATUR_DATE = '2' THEN 'S26_I_2.1.2.G.2024'
             WHEN A.MATUR_DATE = '3' THEN 'S26_I_2.1.3.G.2024'
             WHEN A.MATUR_DATE = '4' THEN 'S26_I_2.1.4.G.2024'
           END
         WHEN A.TAG1 = 'CN' THEN
           CASE
             WHEN A.MATUR_DATE = '1' THEN 'S26_I_2.1.1.H.2024'
             WHEN A.MATUR_DATE = '2' THEN 'S26_I_2.1.2.H.2024'
             WHEN A.MATUR_DATE = '3' THEN 'S26_I_2.1.3.H.2024'
             WHEN A.MATUR_DATE = '4' THEN 'S26_I_2.1.4.H.2024'
           END
       END AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP2_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
        AND A.TAG1 IN ('DK','YC','CN','FB')
      GROUP BY A.ORG_NUM,
               CASE
                 WHEN A.TAG1 = 'DK' THEN
                   CASE
                     WHEN A.MATUR_DATE = '1' THEN 'S26_I_2.1.1.B.2024'
                     WHEN A.MATUR_DATE = '2' THEN 'S26_I_2.1.2.B.2024'
                     WHEN A.MATUR_DATE = '3' THEN 'S26_I_2.1.3.B.2024'
                     WHEN A.MATUR_DATE = '4' THEN 'S26_I_2.1.4.B.2024'
                   END
                 WHEN A.TAG1 = 'FB' THEN
                   CASE
                     WHEN A.MATUR_DATE = '1' THEN 'S26_I_2.1.1.D.2024'
                     WHEN A.MATUR_DATE = '2' THEN 'S26_I_2.1.2.D.2024'
                     WHEN A.MATUR_DATE = '3' THEN 'S26_I_2.1.3.D.2024'
                     WHEN A.MATUR_DATE = '4' THEN 'S26_I_2.1.4.D.2024'
                   END
                 WHEN A.TAG1 = 'YC' THEN
                   CASE
                     WHEN A.MATUR_DATE = '1' THEN 'S26_I_2.1.1.G.2024'
                     WHEN A.MATUR_DATE = '2' THEN 'S26_I_2.1.2.G.2024'
                     WHEN A.MATUR_DATE = '3' THEN 'S26_I_2.1.3.G.2024'
                     WHEN A.MATUR_DATE = '4' THEN 'S26_I_2.1.4.G.2024'
                   END
                 WHEN A.TAG1 = 'CN' THEN
                   CASE
                     WHEN A.MATUR_DATE = '1' THEN 'S26_I_2.1.1.H.2024'
                     WHEN A.MATUR_DATE = '2' THEN 'S26_I_2.1.2.H.2024'
                     WHEN A.MATUR_DATE = '3' THEN 'S26_I_2.1.3.H.2024'
                     WHEN A.MATUR_DATE = '4' THEN 'S26_I_2.1.4.H.2024'
                   END
               END;
    COMMIT;


    INSERT INTO CBRC_A_REPT_ITEM_VAL
    (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       CASE
         WHEN A.MATUR_DATE = '1' THEN 'S26_I_2.1.1.F.2024'
         WHEN A.MATUR_DATE = '2' THEN 'S26_I_2.1.2.F.2024'
         WHEN A.MATUR_DATE = '3' THEN 'S26_I_2.1.3.F.2024'
         WHEN A.MATUR_DATE = '4' THEN 'S26_I_2.1.4.F.2024'
       END AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP2_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
        AND A.TAG1 IN ('DB','YC')
      GROUP BY A.ORG_NUM,
               CASE
                 WHEN A.MATUR_DATE = '1' THEN 'S26_I_2.1.1.F.2024'
                 WHEN A.MATUR_DATE = '2' THEN 'S26_I_2.1.2.F.2024'
                 WHEN A.MATUR_DATE = '3' THEN 'S26_I_2.1.3.F.2024'
                 WHEN A.MATUR_DATE = '4' THEN 'S26_I_2.1.4.F.2024'
               END;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 重点监测口径省外融资.不良资产余额
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '重点监测口径省外融资.不良资产余额';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
    (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       CASE
         WHEN A.TAG1 = 'DK' THEN 'S26_I_2.2.1.B.2024'
         WHEN A.TAG1 = 'FB' THEN 'S26_I_2.2.1.D.2024'
         WHEN A.TAG1 = 'YC' THEN 'S26_I_2.2.1.G.2024'
         WHEN A.TAG1 = 'CN' THEN 'S26_I_2.2.1.H.2024'
       END AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP2_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
        AND A.TAG1 IN ('DK','YC','CN','FB')
        AND A.LOAN_GRADE_CD IN ('3','4','5')
      GROUP BY A.ORG_NUM,
               CASE
                 WHEN A.TAG1 = 'DK' THEN 'S26_I_2.2.1.B.2024'
                 WHEN A.TAG1 = 'FB' THEN 'S26_I_2.2.1.D.2024'
                 WHEN A.TAG1 = 'YC' THEN 'S26_I_2.2.1.G.2024'
                 WHEN A.TAG1 = 'CN' THEN 'S26_I_2.2.1.H.2024'
               END;
    COMMIT;


    INSERT INTO CBRC_A_REPT_ITEM_VAL
    (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       'S26_I_2.2.1.F.2024' AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP2_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
        AND A.LOAN_GRADE_CD IN ('3','4','5')
        AND A.TAG1 IN ('DB','YC')
      GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 重点监测口径省外融资.各项减值准备
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '重点监测口径省外融资.各项减值准备';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
    (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       CASE
         WHEN A.TAG1 = 'DK' THEN 'S26_I_2.2.2.B.2024'
         WHEN A.TAG1 = 'FB' THEN 'S26_I_2.2.2.D.2024'
         WHEN A.TAG1 = 'YC' THEN 'S26_I_2.2.2.G.2024'
         WHEN A.TAG1 = 'CN' THEN 'S26_I_2.2.2.H.2024'
       END AS ITEM_NUM,
       SUM(NVL(A.PRIN_FINAL_RESLT,0)+NVL(A.OFBS_FINAL_RESLT,0)) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP2_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
        AND A.TAG1 IN ('DK','YC','CN','FB')
      GROUP BY A.ORG_NUM,
               CASE
                 WHEN A.TAG1 = 'DK' THEN 'S26_I_2.2.2.B.2024'
                 WHEN A.TAG1 = 'FB' THEN 'S26_I_2.2.2.D.2024'
                 WHEN A.TAG1 = 'YC' THEN 'S26_I_2.2.2.G.2024'
                 WHEN A.TAG1 = 'CN' THEN 'S26_I_2.2.2.H.2024'
               END;
    COMMIT;


    INSERT INTO CBRC_A_REPT_ITEM_VAL
    (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       'S26_I_2.2.2.F.2024' AS ITEM_NUM,
       SUM(NVL(A.PRIN_FINAL_RESLT,0)+NVL(A.OFBS_FINAL_RESLT,0)) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP2_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
        AND A.TAG1 IN ('DB','YC')
      GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 重点监测口径省外融资.省内机构发放余额（包括总行及总行所在省内分支机构）
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '重点监测口径省外融资.省内机构发放余额（包括总行及总行所在省内分支机构）';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
    (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       CASE
         WHEN A.TAG1 = 'DK' THEN 'S26_I_2.3.1.B.2024'
         WHEN A.TAG1 = 'FB' THEN 'S26_I_2.3.1.D.2024'
         WHEN A.TAG1 = 'YC' THEN 'S26_I_2.3.1.G.2024'
         WHEN A.TAG1 = 'CN' THEN 'S26_I_2.3.1.H.2024'
       END AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP2_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
        AND A.TAG1 IN ('DK','YC','CN','FB')
        AND A.TAG = 'SN'
      GROUP BY A.ORG_NUM,
               CASE
                 WHEN A.TAG1 = 'DK' THEN 'S26_I_2.3.1.B.2024'
                 WHEN A.TAG1 = 'FB' THEN 'S26_I_2.3.1.D.2024'
                 WHEN A.TAG1 = 'YC' THEN 'S26_I_2.3.1.G.2024'
                 WHEN A.TAG1 = 'CN' THEN 'S26_I_2.3.1.H.2024'
               END;
    COMMIT;


    INSERT INTO CBRC_A_REPT_ITEM_VAL
    (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       'S26_I_2.3.1.F.2024' AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP2_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
        AND A.TAG1 IN ('DB','YC')
        AND A.TAG = 'SN'
      GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 重点监测口径省外融资.省外分支机构发放余额
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '重点监测口径省外融资.省外分支机构发放余额';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
    (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       CASE
         WHEN A.TAG1 = 'DK' THEN 'S26_I_2.3.2.B.2024'
         WHEN A.TAG1 = 'FB' THEN 'S26_I_2.3.2.D.2024'
         WHEN A.TAG1 = 'YC' THEN 'S26_I_2.3.2.G.2024'
         WHEN A.TAG1 = 'CN' THEN 'S26_I_2.3.2.H.2024'
       END AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP2_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
        AND A.TAG1 IN ('DK','YC','CN','FB')
        AND A.TAG = 'SY'
      GROUP BY A.ORG_NUM,
               CASE
                 WHEN A.TAG1 = 'DK' THEN 'S26_I_2.3.2.B.2024'
                 WHEN A.TAG1 = 'FB' THEN 'S26_I_2.3.2.D.2024'
                 WHEN A.TAG1 = 'YC' THEN 'S26_I_2.3.2.G.2024'
                 WHEN A.TAG1 = 'CN' THEN 'S26_I_2.3.2.H.2024'
               END;
    COMMIT;


    INSERT INTO CBRC_A_REPT_ITEM_VAL
    (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       'S26_I_2.3.2.F.2024' AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP2_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
        AND A.TAG1 IN ('DB','YC')
        AND A.TAG = 'SY'
      GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := 1;
    V_STEP_DESC := '省外存款业务总体情况';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --=====================================
    -- 第II部分：省外存款业务总体情况
    --============= ========================

    INSERT 
    INTO CBRC_TMP_ACCT_DEPOSIT_S2601 
    (DATA_DATE, ORG_NUM, ST_INT_DT, CUST_ID, ACCT_NUM, MATUR_DATE, BALANCE, SRJE, GL_ITEM_CODE, REGION_CD, TAG ,TAG1 ,DEPOSIT_NUM)
    SELECT  
           I_DATADATE AS DATA_DATE,
           A.ORG_NUM AS ORG_NUM,
           A.ST_INT_DT AS ST_INT_DT,
           A.CUST_ID AS CUST_ID,
           A.ACCT_NUM AS ACCT_NUM,
           A.MATUR_DATE AS MATUR_DATE,
           A.ACCT_BALANCE * B.CCY_RATE AS BALANCE,
           A.SRJE * B.CCY_RATE AS SRJE,
           A.GL_ITEM_CODE AS GL_ITEM_CODE,
           COALESCE(CASE WHEN C.ID_TYPE IN ('101','102') THEN SUBSTR(C.ID_NO, 1, 6) END,C.REGION_CD,C.ORG_AREA) AS REGION_CD,
           CASE
             WHEN (SUBSTR(A.GL_ITEM_CODE,1,6) = '201107'  OR A.GL_ITEM_CODE LIKE '2010%' --需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：石雨，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
               OR SUBSTR(A.GL_ITEM_CODE,1,4) IN ('2013','2014')) THEN 'QTCK' --其他存款
             WHEN A.GL_ITEM_CODE IN ('20120106', '20120204') THEN 'BXGS' --保险公司
             WHEN (SUBSTR(A.GL_ITEM_CODE,1,6) = '201101' OR (SUBSTR(A.GL_ITEM_CODE,1,6) = '201102' AND D.DEPOSIT_CUSTTYPE IN ('13', '14'))
                 OR A.GL_ITEM_CODE ='22410102' OR (  A.GL_ITEM_CODE IN ('22410101','20110301','20110302','20110303') AND D.DEPOSIT_CUSTTYPE IN ('13', '14') )
               ) 
               THEN 'GRCK' --个人存款
             WHEN ( (SUBSTR(A.GL_ITEM_CODE,1,6) = '201102' AND D.DEPOSIT_CUSTTYPE NOT IN ('13', '14') )
                  OR (A.GL_ITEM_CODE IN ('22410101','20110301','20110302','20110303') AND D.DEPOSIT_CUSTTYPE not IN ('13', '14') ) )
               THEN 'DWCK' --单位存款
           END AS TAG,
           CASE
             WHEN SUBSTR(COALESCE(CASE WHEN C.ID_TYPE IN ('101','102') THEN SUBSTR(C.ID_NO, 1, 6) END,C.REGION_CD,C.ORG_AREA),1,2)
               IN (SELECT DISTINCT SUBSTR(REGION_CD,1,2) FROM CBRC_TMP_PUBL_ORG_BRA_S2601) THEN 'Y' --设有分支机构
             ELSE 'N' --未设分支机构
           END TAG1,
           A.DEPOSIT_NUM DEPOSIT_NUM
      FROM SMTMODS_L_ACCT_DEPOSIT A
      LEFT JOIN SMTMODS_L_PUBL_RATE B --汇率表
        ON B.DATA_DATE = I_DATADATE
       AND A.CURR_CD = B.BASIC_CCY
       AND B.FORWARD_CCY = 'CNY'
      INNER JOIN SMTMODS_L_CUST_ALL C
        ON A.CUST_ID = C.CUST_ID
       AND C.DATA_DATE = I_DATADATE
      LEFT JOIN SMTMODS_L_CUST_C D
        ON A.CUST_ID = D.CUST_ID
       AND D.DATA_DATE = I_DATADATE
      WHERE A.DATA_DATE = I_DATADATE
       AND A.ACCT_BALANCE <> 0
       --客户所属地区  住所或经营所属地区  身份证前六位 判断是否省外客户  空值先不取
       AND COALESCE(CASE WHEN C.ID_TYPE IN ('101','102') THEN SUBSTR(C.ID_NO, 1, 6) END,C.REGION_CD,C.ORG_AREA) NOT LIKE '22%'
       AND (SUBSTR(A.GL_ITEM_CODE, 1, 4) IN ('2013','2014') -- 应解汇款及临时存款、开出汇票
          OR SUBSTR(A.GL_ITEM_CODE, 1, 6) IN ('201101','201102','201107','201103','224101','200801','200901') --个人存款、单位存款、国库定期 --[JLBA202507210012][石雨][修改内容：224101久悬未取款属于活期存款、201103（财政性存款）调整为 一般单位活期存款]
          OR A.GL_ITEM_CODE LIKE '2010%' --需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：石雨，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
          OR A.GL_ITEM_CODE IN ('20120106', '20120204'))-- 保险公司
       AND A.GL_ITEM_CODE NOT IN ('20110111','20110206')  --去除单位和个人的信用卡
       --只取在区域代码中存在的
       AND SUBSTR(COALESCE(CASE WHEN C.ID_TYPE IN ('101','102') THEN SUBSTR(C.ID_NO, 1, 6) END,C.REGION_CD,C.ORG_AREA),1,2)
           IN (SELECT DISTINCT SUBSTR(CODE,1,2)
                 FROM SMTMODS_L_CODE_DICTIONARY
                WHERE CODE_CLMN_NAME = 'C0002')
         ;
     COMMIT;

    --=====================================
    --   S2601 3.1.1设有分支机构省份.本期余额
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '设有分支机构省份.本期余额';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       'S26_I_2_3.1.1.A.2024' AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.TAG1 = 'Y' --设有分支机构
       GROUP BY A.ORG_NUM
      ;
    COMMIT;


    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 3.1.1设有分支机构省份.单位存款
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '设有分支机构省份.单位存款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


   INSERT INTO CBRC_A_REPT_ITEM_VAL
     (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
     SELECT 
      I_DATADATE AS DATA_DATE,
      A.ORG_NUM AS ORG_NUM,
      'CBRC' AS SYS_NAM,
      'S26_I' AS REP_NUM,
      'S26_I_2_3.1.1.B.2024' AS ITEM_NUM,
      SUM(A.BALANCE) AS ITEM_VAL,
      '2' AS FLAG
       FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
       LEFT JOIN SMTMODS_L_CUST_C C
         ON A.CUST_ID = C.CUST_ID
        AND A.DATA_DATE = C.DATA_DATE
      WHERE A.DATA_DATE = I_DATADATE
        AND C.DEPOSIT_CUSTTYPE NOT IN ('13', '14') --排除个体工商户
        AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201102'
        AND A.TAG1 = 'Y' --设有分支机构
      GROUP BY A.ORG_NUM;
   COMMIT;


    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 3.1.1设有分支机构省份.个人存款
    --=====================================


    V_STEP_ID   := 1;
    V_STEP_DESC := '设有分支机构省份.个人存款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   INSERT INTO CBRC_A_REPT_ITEM_VAL
     (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
     SELECT I_DATADATE AS DATA_DATE,
            ORG_NUM AS ORG_NUM,
            'CBRC' AS SYS_NAM,
            'S26_I' AS REP_NUM,
            'S26_I_2_3.1.1.C.2024' AS ITEM_NUM,
            SUM(ACCT_BALANCE) AS ITEM_VAL,
            '2' AS FLAG
       FROM (
          SELECT A.ORG_NUM,A.BALANCE ACCT_BALANCE
            FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
           WHERE A.DATA_DATE = I_DATADATE
             AND SUBSTR(A.GL_ITEM_CODE,1,6) = '201101'
             AND A.TAG1 = 'Y' --设有分支机构
          UNION ALL
          --省外单位个体工商户存款
          SELECT A.ORG_NUM,A.BALANCE ACCT_BALANCE
            FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
            LEFT JOIN SMTMODS_L_CUST_C C
              ON A.CUST_ID = C.CUST_ID
             AND A.DATA_DATE = C.DATA_DATE
           WHERE A.DATA_DATE = I_DATADATE
             AND C.DEPOSIT_CUSTTYPE IN ('13','14') --个体工商户
             AND SUBSTR(A.GL_ITEM_CODE,1,6) = '201102'
             AND A.TAG1 = 'Y' --设有分支机构
             )
      GROUP BY ORG_NUM;
   COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 3.1.1设有分支机构省份.保险公司存款
    --=====================================


    V_STEP_ID   := 1;
    V_STEP_DESC := '设有分支机构省份.保险公司存款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   INSERT INTO CBRC_A_REPT_ITEM_VAL
     (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
     SELECT 
      I_DATADATE AS DATA_DATE,
      A.ORG_NUM AS ORG_NUM,
      'CBRC' AS SYS_NAM,
      'S26_I' AS REP_NUM,
      'S26_I_2_3.1.1.D.2024' AS ITEM_NUM,
      SUM(A.BALANCE) AS ITEM_VAL,
      '2' AS FLAG
       FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
      WHERE A.DATA_DATE = I_DATADATE
        AND A.GL_ITEM_CODE IN ('20120106', '20120204')
        AND A.TAG1 = 'Y' --设有分支机构
      GROUP BY A.ORG_NUM;
   COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 3.1.1设有分支机构省份.其他存款
    --=====================================


    V_STEP_ID   := 1;
    V_STEP_DESC := '设有分支机构省份.其他存款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   INSERT INTO CBRC_A_REPT_ITEM_VAL
     (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
     SELECT 
      I_DATADATE AS DATA_DATE,
      A.ORG_NUM AS ORG_NUM,
      'CBRC' AS SYS_NAM,
      'S26_I' AS REP_NUM,
      'S26_I_2_3.1.1.E.2024' AS ITEM_NUM,
      SUM(A.BALANCE) AS ITEM_VAL,
      '2' AS FLAG
       FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
      WHERE A.DATA_DATE = I_DATADATE
           --201107   国库定期存款  2013     临时性存款     2014   临时性存款
        AND (SUBSTR(A.GL_ITEM_CODE, 1, 4) IN ('2013', '2014') OR  SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201107'
        OR A.GL_ITEM_CODE LIKE '2010%' --需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：石雨，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
        )
        AND A.TAG1 = 'Y' --设有分支机构
      GROUP BY A.ORG_NUM;
   COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 3.1.1设有分支机构省份.本年累计支付利息金额
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '设有分支机构省份.本年累计支付利息金额';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   INSERT INTO CBRC_A_REPT_ITEM_VAL
     (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
     SELECT 
      I_DATADATE AS DATA_DATE,
      A.ORG_NUM AS ORG_NUM,
      'CBRC' AS SYS_NAM,
      'S26_I' AS REP_NUM,
      'S26_I_2_3.1.1.F.2024' AS ITEM_NUM,
      SUM(NVL(A.SRJE,0) - NVL(D.SRJE,0)) AS ITEM_VAL,
      '2' AS FLAG
       FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
       LEFT JOIN CBRC_TMP_ACCT_DEPOSIT_S2601 D
         ON A.ACCT_NUM = D.ACCT_NUM
        AND A.DEPOSIT_NUM = D.DEPOSIT_NUM
        AND D.DATA_DATE = LAST_YEAR
        AND A.TAG1 = D.TAG1 --设有分支机构
      WHERE A.DATA_DATE = I_DATADATE
        AND A.TAG1 = 'Y' --设有分支机构
      GROUP BY A.ORG_NUM;
   COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 3.1.2未设分支机构省份.本期余额
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '未设分支机构省份.本期余额';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       'S26_I_2_3.1.2.A.2024' AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.TAG1 = 'N' --未设分支机构
       GROUP BY A.ORG_NUM
      ;
    COMMIT;


    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 3.1.2未设分支机构省份.单位存款
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '未设分支机构省份.单位存款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


   INSERT INTO CBRC_A_REPT_ITEM_VAL
     (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
     SELECT 
      I_DATADATE AS DATA_DATE,
      A.ORG_NUM AS ORG_NUM,
      'CBRC' AS SYS_NAM,
      'S26_I' AS REP_NUM,
      'S26_I_2_3.1.2.B.2024' AS ITEM_NUM,
      SUM(A.BALANCE) AS ITEM_VAL,
      '2' AS FLAG
       FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
       LEFT JOIN SMTMODS_L_CUST_C C
         ON A.CUST_ID = C.CUST_ID
        AND A.DATA_DATE = C.DATA_DATE
      WHERE A.DATA_DATE = I_DATADATE
        AND C.DEPOSIT_CUSTTYPE NOT IN ('13', '14') --排除个体工商户
        AND (SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201102'
           or  A.GL_ITEM_CODE IN ('22410101','20110301','20110302','20110303','20080101','20090101'))--[JLBA202507210012][石雨][修改内容：22410101单位久悬未取款、201103（财政性存款）调整为 一般单位活期存款]
          
        AND A.TAG1 = 'N' --未设分支机构
      GROUP BY A.ORG_NUM;
   COMMIT;


    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 3.1.2未设分支机构省份.个人存款
    --=====================================


    V_STEP_ID   := 1;
    V_STEP_DESC := '未设分支机构省份.个人存款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   INSERT INTO CBRC_A_REPT_ITEM_VAL
     (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
     SELECT I_DATADATE AS DATA_DATE,
            ORG_NUM AS ORG_NUM,
            'CBRC' AS SYS_NAM,
            'S26_I' AS REP_NUM,
            'S26_I_2_3.1.2.C.2024' AS ITEM_NUM,
            SUM(ACCT_BALANCE) AS ITEM_VAL,
            '2' AS FLAG
       FROM (
          SELECT A.ORG_NUM,A.BALANCE ACCT_BALANCE
            FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
           WHERE A.DATA_DATE = I_DATADATE
             AND (SUBSTR(A.GL_ITEM_CODE,1,6) = '201101' OR A.GL_ITEM_CODE ='22410102') --[JLBA202507210012][石雨][修改内容：22410102个人久悬未取款]
             AND A.TAG1 = 'N' --未设分支机构
          UNION ALL
          --省外单位个体工商户存款
          SELECT A.ORG_NUM,A.BALANCE ACCT_BALANCE
            FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
            LEFT JOIN SMTMODS_L_CUST_C C
              ON A.CUST_ID = C.CUST_ID
             AND A.DATA_DATE = C.DATA_DATE
           WHERE A.DATA_DATE = I_DATADATE
             AND C.DEPOSIT_CUSTTYPE IN ('13','14') --个体工商户
             AND (SUBSTR(A.GL_ITEM_CODE,1,6) = '201102'
                OR A.GL_ITEM_CODE IN ('22410101','20110301','20110302','20110303') )--[JLBA202507210012][石雨][修改内容：22410101单位久悬未取款、201103（财政性存款）调整为 一般单位活期存款]
             AND A.TAG1 = 'N' --未设分支机构
             )
      GROUP BY ORG_NUM;
   COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 3.1.2未设分支机构省份.保险公司存款
    --=====================================


    V_STEP_ID   := 1;
    V_STEP_DESC := '未设分支机构省份.保险公司存款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   INSERT INTO CBRC_A_REPT_ITEM_VAL
     (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
     SELECT 
      I_DATADATE AS DATA_DATE,
      A.ORG_NUM AS ORG_NUM,
      'CBRC' AS SYS_NAM,
      'S26_I' AS REP_NUM,
      'S26_I_2_3.1.2.D.2024' AS ITEM_NUM,
      SUM(A.BALANCE) AS ITEM_VAL,
      '2' AS FLAG
       FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
      WHERE A.DATA_DATE = I_DATADATE
        AND A.GL_ITEM_CODE IN ('20120106', '20120204')
        AND A.TAG1 = 'N' --未设分支机构
      GROUP BY A.ORG_NUM;
   COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 3.1.2未设分支机构省份.其他存款
    --=====================================


    V_STEP_ID   := 1;
    V_STEP_DESC := '未设分支机构省份.其他存款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   INSERT INTO CBRC_A_REPT_ITEM_VAL
     (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
     SELECT 
      I_DATADATE AS DATA_DATE,
      A.ORG_NUM AS ORG_NUM,
      'CBRC' AS SYS_NAM,
      'S26_I' AS REP_NUM,
      'S26_I_2_3.1.2.E.2024' AS ITEM_NUM,
      SUM(A.BALANCE) AS ITEM_VAL,
      '2' AS FLAG
       FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
      WHERE A.DATA_DATE = I_DATADATE
           --201107   国库定期存款  2013     临时性存款     2014   临时性存款
        AND (SUBSTR(A.GL_ITEM_CODE, 1, 4) IN ('2013', '2014') OR  SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201107'
        OR A.GL_ITEM_CODE LIKE '2010%' --需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：石雨，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
        )
        AND A.TAG1 = 'N' --未设分支机构
      GROUP BY A.ORG_NUM;
   COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 3.1.2未设分支机构省份.本年累计支付利息金额
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '未设分支机构省份.本年累计支付利息金额';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   INSERT INTO CBRC_A_REPT_ITEM_VAL
     (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
     SELECT 
      I_DATADATE AS DATA_DATE,
      A.ORG_NUM AS ORG_NUM,
      'CBRC' AS SYS_NAM,
      'S26_I' AS REP_NUM,
      'S26_I_2_3.1.2.F.2024' AS ITEM_NUM,
      SUM(NVL(A.SRJE,0) - NVL(D.SRJE,0)) AS ITEM_VAL,
      '2' AS FLAG
       FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
       LEFT JOIN CBRC_TMP_ACCT_DEPOSIT_S2601 D
         ON A.ACCT_NUM = D.ACCT_NUM
        AND A.DEPOSIT_NUM = D.DEPOSIT_NUM
        AND D.DATA_DATE = LAST_YEAR
      WHERE A.DATA_DATE = I_DATADATE
        AND A.TAG1 = 'N' --未设分支机构
      GROUP BY A.ORG_NUM;
   COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 3.2单户存款金额.单位存款
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '单户存款金额.单位存款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
    SELECT 
     I_DATADATE AS DATA_DATE,
     ORG_NUM AS ORG_NUM,
     'CBRC' AS SYS_NAM,
     'S26_I' AS REP_NUM,
     ITEM_NUM AS ITEM_NUM,
     SUM(ITEM_VAL) AS ITEM_VAL,
     '2' AS FLAG
      FROM (SELECT 
             A.ORG_NUM AS ORG_NUM,
             A.CUST_ID AS CUST_ID,
             CASE
               WHEN SUM(A.BALANCE) <= 500000 THEN
                'S26_I_2_3.2.1.B.2024'
               WHEN SUM(A.BALANCE) > 500000 THEN
                'S26_I_2_3.2.2.B.2024'
             END AS ITEM_NUM,
             SUM(A.BALANCE) AS ITEM_VAL
              FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
              LEFT JOIN SMTMODS_L_CUST_C C
                ON A.CUST_ID = C.CUST_ID
               AND A.DATA_DATE = C.DATA_DATE
             WHERE A.DATA_DATE = I_DATADATE
               AND C.DEPOSIT_CUSTTYPE NOT IN ('13', '14') --排除个体工商户
               AND (SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201102'
                   OR A.GL_ITEM_CODE    IN ('22410101','20110301','20110302','20110303','20080101','20090101')--[JLBA202507210012][石雨][修改内容：22410101单位久悬未取款、201103（财政性存款）调整为 一般单位活期存款]
                   )
             GROUP BY A.ORG_NUM, A.CUST_ID)
     GROUP BY ORG_NUM, ITEM_NUM;
   COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
    SELECT 
     I_DATADATE AS DATA_DATE,
     ORG_NUM AS ORG_NUM,
     'CBRC' AS SYS_NAM,
     'S26_I' AS REP_NUM,
     ITEM_NUM AS ITEM_NUM,
     SUM(ITEM_VAL) AS ITEM_VAL,
     '2' AS FLAG
      FROM (SELECT 
             A.ORG_NUM AS ORG_NUM,
             A.CUST_ID AS CUST_ID,
             CASE
               WHEN SUM(A.BALANCE) <= 50000000 THEN
                'S26_I_2_3.2.3.B.2024'
               WHEN SUM(A.BALANCE) > 50000000 THEN
                'S26_I_2_3.2.4.B.2024'
             END AS ITEM_NUM,
             SUM(A.BALANCE) AS ITEM_VAL
              FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
              LEFT JOIN SMTMODS_L_CUST_C C
                ON A.CUST_ID = C.CUST_ID
               AND A.DATA_DATE = C.DATA_DATE
             WHERE A.DATA_DATE = I_DATADATE
               AND C.DEPOSIT_CUSTTYPE NOT IN ('13', '14') --排除个体工商户
               AND (SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201102'
               OR A.GL_ITEM_CODE    IN ('22410101','20110301','20110302','20110303','20080101','20090101')--[JLBA202507210012][石雨][修改内容：22410101单位久悬未取款、201103（财政性存款）调整为 一般单位活期存款]
                   )
             GROUP BY A.ORG_NUM, A.CUST_ID)
     GROUP BY ORG_NUM, ITEM_NUM;
   COMMIT;


    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --=====================================
    --   S2601 3.2单户存款金额.个人存款
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '单户存款金额.个人存款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
             I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'S26_I' AS REP_NUM,
             ITEM_NUM AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM,
               A.CUST_ID,
               CASE
                 WHEN SUM(A.BALANCE) <= 500000 THEN
                  'S26_I_2_3.2.1.C.2024'
                 WHEN SUM(A.BALANCE) > 500000 THEN
                  'S26_I_2_3.2.2.C.2024'
               END ITEM_NUM,
               SUM(A.BALANCE) ITEM_VAL
                FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
               WHERE A.DATA_DATE = I_DATADATE
                 AND ( SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201101'
                   OR A.GL_ITEM_CODE ='22410102' )--[JLBA202507210012][石雨][修改内容：22410102个人久悬未取款]
               GROUP BY A.ORG_NUM, A.CUST_ID
              UNION ALL
              SELECT 
               A.ORG_NUM,
               A.CUST_ID,
               CASE
                 WHEN SUM(A.BALANCE) <= 500000 THEN
                  'S26_I_2_3.2.1.C.2024'
                 WHEN SUM(A.BALANCE) > 500000 THEN
                  'S26_I_2_3.2.2.C.2024'
               END ITEM_NUM,
               SUM(A.BALANCE) ITEM_VAL
                FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
                LEFT JOIN SMTMODS_L_CUST_C C
                  ON A.CUST_ID = C.CUST_ID
                 AND A.DATA_DATE = C.DATA_DATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND C.DEPOSIT_CUSTTYPE IN ('13', '14') --个体工商户
                 AND (SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201102'
                      OR A.GL_ITEM_CODE    IN ('22410101','20110301','20110302','20110303')--[JLBA202507210012][石雨][修改内容：22410101单位久悬未取款、201103（财政性存款）调整为 一般单位活期存款]
                   )
               GROUP BY A.ORG_NUM, A.CUST_ID)
       GROUP BY ORG_NUM, ITEM_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 3.2单户存款金额.保险公司存款
    --=====================================


    V_STEP_ID   := 1;
    V_STEP_DESC := '单户存款金额.保险公司存款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       ITEM_NUM AS ITEM_NUM,
       SUM(ITEM_VAL) AS ITEM_VAL,
       '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     CASE
                       WHEN SUM(A.BALANCE) <= 50000000 THEN
                        'S26_I_2_3.2.3.D.2024'
                       WHEN SUM(A.BALANCE) > 50000000 THEN
                        'S26_I_2_3.2.4.D.2024'
                     END ITEM_NUM,
                     SUM(A.BALANCE) ITEM_VAL
                FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.GL_ITEM_CODE IN ('20120106', '20120204')
               GROUP BY A.ORG_NUM, A.CUST_ID)
       GROUP BY ORG_NUM, ITEM_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --=====================================
    --   S2601 3.2单户存款金额.其他存款
    --=====================================


    V_STEP_ID   := 1;
    V_STEP_DESC := '单户存款金额.其他存款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       ITEM_NUM AS ITEM_NUM,
       SUM(ITEM_VAL) AS ITEM_VAL,
       '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     CASE
                       WHEN SUM(A.BALANCE) <= 50000000 THEN
                        'S26_I_2_3.2.3.E.2024'
                       WHEN SUM(A.BALANCE) > 50000000 THEN
                        'S26_I_2_3.2.4.E.2024'
                     END ITEM_NUM,
                     SUM(A.BALANCE) ITEM_VAL
                FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
               WHERE A.DATA_DATE = I_DATADATE
                    --201107   国库定期存款  2013     临时性存款     2014   临时性存款
                 AND (SUBSTR(A.GL_ITEM_CODE, 1, 4) IN ('2013', '2014') OR SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201107'
                 OR A.GL_ITEM_CODE LIKE '2010%' --需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：石雨，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
                 )
               GROUP BY A.ORG_NUM, A.CUST_ID)
       GROUP BY ORG_NUM, ITEM_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 3.3存款渠道.3.3.1线下存款.个人存款
    --=====================================


    V_STEP_ID   := 1;
    V_STEP_DESC := '存款渠道.3.3.1线下存款.个人存款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   INSERT INTO CBRC_A_REPT_ITEM_VAL
     (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
     SELECT I_DATADATE AS DATA_DATE,
            ORG_NUM AS ORG_NUM,
            'CBRC' AS SYS_NAM,
            'S26_I' AS REP_NUM,
            'S26_I_2_3.3.1.C.2024' AS ITEM_NUM,
            SUM(ACCT_BALANCE) AS ITEM_VAL,
            '2' AS FLAG
       FROM (
          SELECT A.ORG_NUM,A.BALANCE ACCT_BALANCE
            FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
           WHERE A.DATA_DATE = I_DATADATE
             AND (SUBSTR(A.GL_ITEM_CODE,1,6) = '201101'
               OR A.GL_ITEM_CODE ='22410102' )--[JLBA202507210012][石雨][修改内容：22410102个人久悬未取款]
          UNION ALL
          --省外单位个体工商户存款
          SELECT A.ORG_NUM,A.BALANCE ACCT_BALANCE
            FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
            LEFT JOIN SMTMODS_L_CUST_C C
              ON A.CUST_ID = C.CUST_ID
             AND A.DATA_DATE = C.DATA_DATE
           WHERE A.DATA_DATE = I_DATADATE
             AND C.DEPOSIT_CUSTTYPE IN ('13','14') --个体工商户
             AND (SUBSTR(A.GL_ITEM_CODE,1,6) = '201102'
               OR A.GL_ITEM_CODE    IN ('22410101','20110301','20110302','20110303')--[JLBA202507210012][石雨][修改内容：22410101单位久悬未取款、201103（财政性存款）调整为 一般单位活期存款]
                   )
             
             )
      GROUP BY ORG_NUM;
   COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --=====================================
    --   S2601 4.存款期限.本期余额
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '存款期限.本期余额';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       CASE
         WHEN (A.MATUR_DATE IS NULL OR MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) <= 6) THEN
          'S26_I_2_4.1.A.2024' -- 活期和六个月以内（含）
         WHEN MONTHS_BETWEEN(DATE(A.MATUR_DATE), DATE(A.ST_INT_DT)) > 6 AND MONTHS_BETWEEN(DATE(A.MATUR_DATE), DATE(A.ST_INT_DT)) <= 12 THEN
          'S26_I_2_4.2.A.2024' -- 六个月至一年（含）
         WHEN MONTHS_BETWEEN(DATE(A.MATUR_DATE), DATE(A.ST_INT_DT)) > 12 AND MONTHS_BETWEEN(DATE(A.MATUR_DATE), DATE(A.ST_INT_DT)) <= 36 THEN
          'S26_I_2_4.3.A.2024' -- 一年至三年（含）
         WHEN MONTHS_BETWEEN(DATE(A.MATUR_DATE), DATE(A.ST_INT_DT)) > 36 AND MONTHS_BETWEEN(DATE(A.MATUR_DATE), DATE(A.ST_INT_DT)) <= 60 THEN
          'S26_I_2_4.4.A.2024' -- 三年至五年（含）
         WHEN MONTHS_BETWEEN(DATE(A.MATUR_DATE), DATE(A.ST_INT_DT)) > 60 THEN
          'S26_I_2_4.5.A.2024' -- 五年以上
       END AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM,
                 CASE
         WHEN (A.MATUR_DATE IS NULL OR MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) <= 6) THEN
          'S26_I_2_4.1.A.2024' -- 活期和六个月以内（含）
         WHEN MONTHS_BETWEEN(DATE(A.MATUR_DATE), DATE(A.ST_INT_DT)) > 6 AND MONTHS_BETWEEN(DATE(A.MATUR_DATE), DATE(A.ST_INT_DT)) <= 12 THEN
          'S26_I_2_4.2.A.2024' -- 六个月至一年（含）
         WHEN MONTHS_BETWEEN(DATE(A.MATUR_DATE), DATE(A.ST_INT_DT)) > 12 AND MONTHS_BETWEEN(DATE(A.MATUR_DATE), DATE(A.ST_INT_DT)) <= 36 THEN
          'S26_I_2_4.3.A.2024' -- 一年至三年（含）
         WHEN MONTHS_BETWEEN(DATE(A.MATUR_DATE), DATE(A.ST_INT_DT)) > 36 AND MONTHS_BETWEEN(DATE(A.MATUR_DATE), DATE(A.ST_INT_DT)) <= 60 THEN
          'S26_I_2_4.4.A.2024' -- 三年至五年（含）
         WHEN MONTHS_BETWEEN(DATE(A.MATUR_DATE), DATE(A.ST_INT_DT)) > 60 THEN
          'S26_I_2_4.5.A.2024' -- 五年以上
       END
      ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 5.前十大存款客户存款合计
    --=====================================
    V_STEP_ID   := 1;
    V_STEP_DESC := '前十大存款客户存款明细';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP1_ACCT_DEPOSIT_S2601
    (DATA_DATE, TAG, ORG_NUM, LOAN_ACCT_BAL, CUST_ID, SRJE, SEQ_NO, DEPOSIT_NUM)
    SELECT 
     I_DATADATE AS DATA_DATE,TAG,ORG_NUM, LOAN_ACCT_BAL, CUST_ID, SRJE, SEQ_NO, DEPOSIT_NUM
      FROM (SELECT 
             T1.*,
             ROW_NUMBER() OVER(PARTITION BY T1.ORG_NUM,TAG ORDER BY T1.LOAN_ACCT_BAL DESC, T1.ORG_NUM) AS SEQ_NO
              FROM (SELECT 
                     ORG_CODE AS ORG_NUM,
                     SUM(ACCT_BALANCE) LOAN_ACCT_BAL,
                     SUM(SRJE) SRJE,
                     CUST_ID,
                     TAG,
                     DEPOSIT_NUM
                      FROM (
                            SELECT 
                             A.CUST_ID, A.ORG_NUM, A.BALANCE ACCT_BALANCE, A.SRJE ,A.TAG, A.DEPOSIT_NUM
                              FROM CBRC_TMP_ACCT_DEPOSIT_S2601 A
                             WHERE A.DATA_DATE = I_DATADATE
                            ) T
                     INNER JOIN CBRC_TM_L_ORG_FLAT B
                        ON T.ORG_NUM = B.SUB_ORG_CODE
                     GROUP BY ORG_CODE, CUST_ID, TAG,DEPOSIT_NUM) T1)
     WHERE SEQ_NO <= 10;
    COMMIT;

    --=====================================
    --   S2601 5.前十大存款客户存款合计.本期余额
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '前十大存款客户存款合计.本期余额';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       'S26_I_2.5.A.2024' AS ITEM_NUM,
       SUM(LOAN_ACCT_BAL) AS ITEM_VAL,
       '2' AS FLAG
        FROM (SELECT T2.ORG_NUM,T2.LOAN_ACCT_BAL,SEQ_NEW
                FROM (SELECT T1.*,
                             ROW_NUMBER() OVER(PARTITION BY T1.ORG_NUM ORDER BY T1.LOAN_ACCT_BAL DESC, T1.ORG_NUM) AS SEQ_NEW
                        FROM (SELECT ORG_NUM AS ORG_NUM,SUM(LOAN_ACCT_BAL) LOAN_ACCT_BAL,TAG,SEQ_NO SEQ_OLD
                                FROM CBRC_TMP1_ACCT_DEPOSIT_S2601
                                WHERE DATA_DATE = I_DATADATE
                               GROUP BY ORG_NUM,TAG,SEQ_NO) T1) T2
               WHERE SEQ_NEW <= 10)
       GROUP BY ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 5.前十大存款客户存款合计.单位存款
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '前十大存款客户存款合计.单位存款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       'S26_I_2.5.B.2024' AS ITEM_NUM,
       SUM(LOAN_ACCT_BAL) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP1_ACCT_DEPOSIT_S2601 A
        WHERE A.DATA_DATE = I_DATADATE
          AND A.TAG = 'DWCK'
       GROUP BY ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 5.前十大存款客户存款合计.个人存款
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '前十大存款客户存款合计.个人存款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       'S26_I_2.5.C.2024' AS ITEM_NUM,
       SUM(LOAN_ACCT_BAL) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP1_ACCT_DEPOSIT_S2601 A
        WHERE A.DATA_DATE = I_DATADATE
          AND A.TAG = 'GRCK'
       GROUP BY ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 5.前十大存款客户存款合计.保险公司
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '前十大存款客户存款合计.保险公司';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       'S26_I_2.5.D.2024' AS ITEM_NUM,
       SUM(LOAN_ACCT_BAL) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP1_ACCT_DEPOSIT_S2601 A
        WHERE A.DATA_DATE = I_DATADATE
          AND A.TAG = 'BXGS'
       GROUP BY ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 5.前十大存款客户存款合计.其他存款
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '前十大存款客户存款合计.其他存款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       'S26_I_2.5.E.2024' AS ITEM_NUM,
       SUM(LOAN_ACCT_BAL) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP1_ACCT_DEPOSIT_S2601 A
        WHERE A.DATA_DATE = I_DATADATE
          AND A.TAG = 'QTCK'
       GROUP BY ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S2601 5.前十大存款客户存款合计.累计支付利息
    --=====================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '前十大存款客户存款合计.累计支付利息';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       'S26_I_2.5.F.2024' AS ITEM_NUM,
       SUM(SRJE) AS ITEM_VAL,
       '2' AS FLAG
        FROM (SELECT T2.ORG_NUM, T2.SRJE, SEQ_NEW
                FROM (SELECT T1.*,
                             ROW_NUMBER() OVER(PARTITION BY T1.ORG_NUM ORDER BY T1.LOAN_ACCT_BAL DESC, T1.ORG_NUM) AS SEQ_NEW
                        FROM (SELECT A.ORG_NUM AS ORG_NUM,
                                     SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL,
                                     SUM(NVL(A.SRJE,0) - NVL(D.SRJE,0)) SRJE,
                                     A.TAG,
                                     A.SEQ_NO SEQ_OLD
                                FROM CBRC_TMP1_ACCT_DEPOSIT_S2601 A
                                LEFT JOIN CBRC_TMP1_ACCT_DEPOSIT_S2601 D
                                  ON A.CUST_ID = D.CUST_ID
                                 AND A.DEPOSIT_NUM = D.DEPOSIT_NUM
                                 AND D.DATA_DATE = LAST_YEAR
                                WHERE A.DATA_DATE = I_DATADATE
                               GROUP BY A.ORG_NUM,A.TAG,A.SEQ_NO) T1) T2
               WHERE SEQ_NEW <= 10)
       GROUP BY ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    -- 第III部分：省外业务分地区情况
    --=====================================

    --=====================================
    -- 第III部分：1  6辽宁.全口径省外融资
    --=====================================
    V_STEP_ID   := 1;
    V_STEP_DESC := '辽宁.全口径省外融资';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       CASE
           WHEN (A.REGION_CD_CUST LIKE '11%' AND A.ACCT_NUM <> 'N000310000024539') THEN 'S26_I_3_1.A.2024'  --'%北京%'
           WHEN A.REGION_CD_CUST LIKE '12%' THEN 'S26_I_3_2.A.2024'  --'%天津%'
           WHEN A.REGION_CD_CUST LIKE '13%' THEN 'S26_I_3_3.A.2024'  --'%河北%'
           WHEN A.REGION_CD_CUST LIKE '14%' THEN 'S26_I_3_4.A.2024'  --'%山西%'
           WHEN A.REGION_CD_CUST LIKE '15%' THEN 'S26_I_3_5.A.2024'  --'%内蒙古
           WHEN A.REGION_CD_CUST LIKE '21%' THEN 'S26_I_3_6.A.2024'  --'%辽宁%'
           WHEN A.REGION_CD_CUST LIKE '22%' THEN 'S26_I_3_7.A.2024'  --'%吉林%'
           WHEN A.REGION_CD_CUST LIKE '23%' THEN 'S26_I_3_8.A.2024'  --'%黑龙江
           WHEN (A.REGION_CD_CUST LIKE '31%' OR A.ACCT_NUM = 'N000310000024539') THEN 'S26_I_3_9.A.2024'  --'%上海%'
           WHEN A.REGION_CD_CUST LIKE '32%' THEN 'S26_I_3_10.A.2024'  --'%江苏%'
           WHEN A.REGION_CD_CUST LIKE '33%' THEN 'S26_I_3_11.A.2024'  --'%浙江%'
           WHEN A.REGION_CD_CUST LIKE '34%' THEN 'S26_I_3_12.A.2024'  --'%安徽%'
           WHEN A.REGION_CD_CUST LIKE '35%' THEN 'S26_I_3_13.A.2024'  --'%福建%'
           WHEN A.REGION_CD_CUST LIKE '36%' THEN 'S26_I_3_14.A.2024'  --'%江西%'
           WHEN A.REGION_CD_CUST LIKE '37%' THEN 'S26_I_3_15.A.2024'  --'%山东%'
           WHEN A.REGION_CD_CUST LIKE '41%' THEN 'S26_I_3_16.A.2024'  --'%河南%'
           WHEN A.REGION_CD_CUST LIKE '42%' THEN 'S26_I_3_17.A.2024'  --'%湖北%'
           WHEN A.REGION_CD_CUST LIKE '43%' THEN 'S26_I_3_18.A.2024'  --'%湖南%'
           WHEN A.REGION_CD_CUST LIKE '44%' THEN 'S26_I_3_19.A.2024'  --'%广东%'
           WHEN A.REGION_CD_CUST LIKE '45%' THEN 'S26_I_3_20.A.2024'  --'%广西%'
           WHEN A.REGION_CD_CUST LIKE '46%' THEN 'S26_I_3_21.A.2024'  --'%海南%'
           WHEN A.REGION_CD_CUST LIKE '50%' THEN 'S26_I_3_22.A.2024'  --'%重庆%'
           WHEN A.REGION_CD_CUST LIKE '51%' THEN 'S26_I_3_23.A.2024'  --'%四川%'
           WHEN A.REGION_CD_CUST LIKE '52%' THEN 'S26_I_3_24.A.2024'  --'%贵州%'
           WHEN A.REGION_CD_CUST LIKE '53%' THEN 'S26_I_3_25.A.2024'  --'%云南%'
           WHEN A.REGION_CD_CUST LIKE '54%' THEN 'S26_I_3_26.A.2024'  --'%西藏%'
           WHEN A.REGION_CD_CUST LIKE '61%' THEN 'S26_I_3_27.A.2024'  --'%陕西%'
           WHEN A.REGION_CD_CUST LIKE '62%' THEN 'S26_I_3_28.A.2024'  --'%甘肃%'
           WHEN A.REGION_CD_CUST LIKE '63%' THEN 'S26_I_3_29.A.2024'  --'%青海%'
           WHEN A.REGION_CD_CUST LIKE '64%' THEN 'S26_I_3_30.A.2024'  --'%宁夏%'
           WHEN A.REGION_CD_CUST LIKE '65%' THEN 'S26_I_3_31.A.2024'  --'%新疆%'
           WHEN SUBSTR(A.REGION_CD_CUST,1,2) IN ('71','81','82') THEN 'S26_I_3_32.A.2024' --境外
       END AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM,
             CASE
                 WHEN (A.REGION_CD_CUST LIKE '11%' AND A.ACCT_NUM <> 'N000310000024539') THEN 'S26_I_3_1.A.2024'  --'%北京%'
                 WHEN A.REGION_CD_CUST LIKE '12%' THEN 'S26_I_3_2.A.2024'  --'%天津%'
                 WHEN A.REGION_CD_CUST LIKE '13%' THEN 'S26_I_3_3.A.2024'  --'%河北%'
                 WHEN A.REGION_CD_CUST LIKE '14%' THEN 'S26_I_3_4.A.2024'  --'%山西%'
                 WHEN A.REGION_CD_CUST LIKE '15%' THEN 'S26_I_3_5.A.2024'  --'%内蒙古
                 WHEN A.REGION_CD_CUST LIKE '21%' THEN 'S26_I_3_6.A.2024'  --'%辽宁%'
                 WHEN A.REGION_CD_CUST LIKE '22%' THEN 'S26_I_3_7.A.2024'  --'%吉林%'
                 WHEN A.REGION_CD_CUST LIKE '23%' THEN 'S26_I_3_8.A.2024'  --'%黑龙江
                 WHEN (A.REGION_CD_CUST LIKE '31%' OR A.ACCT_NUM = 'N000310000024539') THEN 'S26_I_3_9.A.2024'  --'%上海%'
                 WHEN A.REGION_CD_CUST LIKE '32%' THEN 'S26_I_3_10.A.2024'  --'%江苏%'
                 WHEN A.REGION_CD_CUST LIKE '33%' THEN 'S26_I_3_11.A.2024'  --'%浙江%'
                 WHEN A.REGION_CD_CUST LIKE '34%' THEN 'S26_I_3_12.A.2024'  --'%安徽%'
                 WHEN A.REGION_CD_CUST LIKE '35%' THEN 'S26_I_3_13.A.2024'  --'%福建%'
                 WHEN A.REGION_CD_CUST LIKE '36%' THEN 'S26_I_3_14.A.2024'  --'%江西%'
                 WHEN A.REGION_CD_CUST LIKE '37%' THEN 'S26_I_3_15.A.2024'  --'%山东%'
                 WHEN A.REGION_CD_CUST LIKE '41%' THEN 'S26_I_3_16.A.2024'  --'%河南%'
                 WHEN A.REGION_CD_CUST LIKE '42%' THEN 'S26_I_3_17.A.2024'  --'%湖北%'
                 WHEN A.REGION_CD_CUST LIKE '43%' THEN 'S26_I_3_18.A.2024'  --'%湖南%'
                 WHEN A.REGION_CD_CUST LIKE '44%' THEN 'S26_I_3_19.A.2024'  --'%广东%'
                 WHEN A.REGION_CD_CUST LIKE '45%' THEN 'S26_I_3_20.A.2024'  --'%广西%'
                 WHEN A.REGION_CD_CUST LIKE '46%' THEN 'S26_I_3_21.A.2024'  --'%海南%'
                 WHEN A.REGION_CD_CUST LIKE '50%' THEN 'S26_I_3_22.A.2024'  --'%重庆%'
                 WHEN A.REGION_CD_CUST LIKE '51%' THEN 'S26_I_3_23.A.2024'  --'%四川%'
                 WHEN A.REGION_CD_CUST LIKE '52%' THEN 'S26_I_3_24.A.2024'  --'%贵州%'
                 WHEN A.REGION_CD_CUST LIKE '53%' THEN 'S26_I_3_25.A.2024'  --'%云南%'
                 WHEN A.REGION_CD_CUST LIKE '54%' THEN 'S26_I_3_26.A.2024'  --'%西藏%'
                 WHEN A.REGION_CD_CUST LIKE '61%' THEN 'S26_I_3_27.A.2024'  --'%陕西%'
                 WHEN A.REGION_CD_CUST LIKE '62%' THEN 'S26_I_3_28.A.2024'  --'%甘肃%'
                 WHEN A.REGION_CD_CUST LIKE '63%' THEN 'S26_I_3_29.A.2024'  --'%青海%'
                 WHEN A.REGION_CD_CUST LIKE '64%' THEN 'S26_I_3_30.A.2024'  --'%宁夏%'
                 WHEN A.REGION_CD_CUST LIKE '65%' THEN 'S26_I_3_31.A.2024'  --'%新疆%'
                 WHEN SUBSTR(A.REGION_CD_CUST,1,2) IN ('71','81','82') THEN 'S26_I_3_32.A.2024' --境外
             END;
  COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    -- 第III部分：1  6辽宁.重点监测口径融资
    --=====================================
    V_STEP_ID   := 1;
    V_STEP_DESC := '辽宁.重点监测口径融资';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       CASE
           WHEN (A.REGION_CD_CUST LIKE '11%' AND A.ACCT_NUM <> 'N000310000024539') THEN 'S26_I_3_1.B.2024'  --'%北京%'
           WHEN A.REGION_CD_CUST LIKE '12%' THEN 'S26_I_3_2.B.2024'  --'%天津%'
           WHEN A.REGION_CD_CUST LIKE '13%' THEN 'S26_I_3_3.B.2024'  --'%河北%'
           WHEN A.REGION_CD_CUST LIKE '14%' THEN 'S26_I_3_4.B.2024'  --'%山西%'
           WHEN A.REGION_CD_CUST LIKE '15%' THEN 'S26_I_3_5.B.2024'  --'%内蒙古
           WHEN A.REGION_CD_CUST LIKE '21%' THEN 'S26_I_3_6.B.2024'  --'%辽宁%'
           WHEN A.REGION_CD_CUST LIKE '22%' THEN 'S26_I_3_7.B.2024'  --'%吉林%'
           WHEN A.REGION_CD_CUST LIKE '23%' THEN 'S26_I_3_8.B.2024'  --'%黑龙江
           WHEN (A.REGION_CD_CUST LIKE '31%' OR A.ACCT_NUM = 'N000310000024539') THEN 'S26_I_3_9.B.2024'  --'%上海%'
           WHEN A.REGION_CD_CUST LIKE '32%' THEN 'S26_I_3_10.B.2024'  --'%江苏%'
           WHEN A.REGION_CD_CUST LIKE '33%' THEN 'S26_I_3_11.B.2024'  --'%浙江%'
           WHEN A.REGION_CD_CUST LIKE '34%' THEN 'S26_I_3_12.B.2024'  --'%安徽%'
           WHEN A.REGION_CD_CUST LIKE '35%' THEN 'S26_I_3_13.B.2024'  --'%福建%'
           WHEN A.REGION_CD_CUST LIKE '36%' THEN 'S26_I_3_14.B.2024'  --'%江西%'
           WHEN A.REGION_CD_CUST LIKE '37%' THEN 'S26_I_3_15.B.2024'  --'%山东%'
           WHEN A.REGION_CD_CUST LIKE '41%' THEN 'S26_I_3_16.B.2024'  --'%河南%'
           WHEN A.REGION_CD_CUST LIKE '42%' THEN 'S26_I_3_17.B.2024'  --'%湖北%'
           WHEN A.REGION_CD_CUST LIKE '43%' THEN 'S26_I_3_18.B.2024'  --'%湖南%'
           WHEN A.REGION_CD_CUST LIKE '44%' THEN 'S26_I_3_19.B.2024'  --'%广东%'
           WHEN A.REGION_CD_CUST LIKE '45%' THEN 'S26_I_3_20.B.2024'  --'%广西%'
           WHEN A.REGION_CD_CUST LIKE '46%' THEN 'S26_I_3_21.B.2024'  --'%海南%'
           WHEN A.REGION_CD_CUST LIKE '50%' THEN 'S26_I_3_22.B.2024'  --'%重庆%'
           WHEN A.REGION_CD_CUST LIKE '51%' THEN 'S26_I_3_23.B.2024'  --'%四川%'
           WHEN A.REGION_CD_CUST LIKE '52%' THEN 'S26_I_3_24.B.2024'  --'%贵州%'
           WHEN A.REGION_CD_CUST LIKE '53%' THEN 'S26_I_3_25.B.2024'  --'%云南%'
           WHEN A.REGION_CD_CUST LIKE '54%' THEN 'S26_I_3_26.B.2024'  --'%西藏%'
           WHEN A.REGION_CD_CUST LIKE '61%' THEN 'S26_I_3_27.B.2024'  --'%陕西%'
           WHEN A.REGION_CD_CUST LIKE '62%' THEN 'S26_I_3_28.B.2024'  --'%甘肃%'
           WHEN A.REGION_CD_CUST LIKE '63%' THEN 'S26_I_3_29.B.2024'  --'%青海%'
           WHEN A.REGION_CD_CUST LIKE '64%' THEN 'S26_I_3_30.B.2024'  --'%宁夏%'
           WHEN A.REGION_CD_CUST LIKE '65%' THEN 'S26_I_3_31.B.2024'  --'%新疆%'
           WHEN SUBSTR(A.REGION_CD_CUST,1,2) IN ('71','81','82') THEN 'S26_I_3_32.B.2024' --境外
       END AS ITEM_NUM,
       SUM(A.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP2_ACCT_LOAN_S2601 A
       WHERE A.DATA_DATE = I_DATADATE
         AND EXISTS (SELECT 1
                        FROM CBRC_TMP2_ACCT_LOAN_S2601 T
                       WHERE T.DATA_DATE = I_DATADATE
                         AND A.ACCT_NUM = T.ACCT_NUM)
       GROUP BY A.ORG_NUM,
             CASE
                 WHEN (A.REGION_CD_CUST LIKE '11%' AND A.ACCT_NUM <> 'N000310000024539') THEN 'S26_I_3_1.B.2024'  --'%北京%'
                 WHEN A.REGION_CD_CUST LIKE '12%' THEN 'S26_I_3_2.B.2024'  --'%天津%'
                 WHEN A.REGION_CD_CUST LIKE '13%' THEN 'S26_I_3_3.B.2024'  --'%河北%'
                 WHEN A.REGION_CD_CUST LIKE '14%' THEN 'S26_I_3_4.B.2024'  --'%山西%'
                 WHEN A.REGION_CD_CUST LIKE '15%' THEN 'S26_I_3_5.B.2024'  --'%内蒙古
                 WHEN A.REGION_CD_CUST LIKE '21%' THEN 'S26_I_3_6.B.2024'  --'%辽宁%'
                 WHEN A.REGION_CD_CUST LIKE '22%' THEN 'S26_I_3_7.B.2024'  --'%吉林%'
                 WHEN A.REGION_CD_CUST LIKE '23%' THEN 'S26_I_3_8.B.2024'  --'%黑龙江
                 WHEN (A.REGION_CD_CUST LIKE '31%' OR A.ACCT_NUM = 'N000310000024539') THEN 'S26_I_3_9.B.2024'  --'%上海%'
                 WHEN A.REGION_CD_CUST LIKE '32%' THEN 'S26_I_3_10.B.2024'  --'%江苏%'
                 WHEN A.REGION_CD_CUST LIKE '33%' THEN 'S26_I_3_11.B.2024'  --'%浙江%'
                 WHEN A.REGION_CD_CUST LIKE '34%' THEN 'S26_I_3_12.B.2024'  --'%安徽%'
                 WHEN A.REGION_CD_CUST LIKE '35%' THEN 'S26_I_3_13.B.2024'  --'%福建%'
                 WHEN A.REGION_CD_CUST LIKE '36%' THEN 'S26_I_3_14.B.2024'  --'%江西%'
                 WHEN A.REGION_CD_CUST LIKE '37%' THEN 'S26_I_3_15.B.2024'  --'%山东%'
                 WHEN A.REGION_CD_CUST LIKE '41%' THEN 'S26_I_3_16.B.2024'  --'%河南%'
                 WHEN A.REGION_CD_CUST LIKE '42%' THEN 'S26_I_3_17.B.2024'  --'%湖北%'
                 WHEN A.REGION_CD_CUST LIKE '43%' THEN 'S26_I_3_18.B.2024'  --'%湖南%'
                 WHEN A.REGION_CD_CUST LIKE '44%' THEN 'S26_I_3_19.B.2024'  --'%广东%'
                 WHEN A.REGION_CD_CUST LIKE '45%' THEN 'S26_I_3_20.B.2024'  --'%广西%'
                 WHEN A.REGION_CD_CUST LIKE '46%' THEN 'S26_I_3_21.B.2024'  --'%海南%'
                 WHEN A.REGION_CD_CUST LIKE '50%' THEN 'S26_I_3_22.B.2024'  --'%重庆%'
                 WHEN A.REGION_CD_CUST LIKE '51%' THEN 'S26_I_3_23.B.2024'  --'%四川%'
                 WHEN A.REGION_CD_CUST LIKE '52%' THEN 'S26_I_3_24.B.2024'  --'%贵州%'
                 WHEN A.REGION_CD_CUST LIKE '53%' THEN 'S26_I_3_25.B.2024'  --'%云南%'
                 WHEN A.REGION_CD_CUST LIKE '54%' THEN 'S26_I_3_26.B.2024'  --'%西藏%'
                 WHEN A.REGION_CD_CUST LIKE '61%' THEN 'S26_I_3_27.B.2024'  --'%陕西%'
                 WHEN A.REGION_CD_CUST LIKE '62%' THEN 'S26_I_3_28.B.2024'  --'%甘肃%'
                 WHEN A.REGION_CD_CUST LIKE '63%' THEN 'S26_I_3_29.B.2024'  --'%青海%'
                 WHEN A.REGION_CD_CUST LIKE '64%' THEN 'S26_I_3_30.B.2024'  --'%宁夏%'
                 WHEN A.REGION_CD_CUST LIKE '65%' THEN 'S26_I_3_31.B.2024'  --'%新疆%'
                 WHEN SUBSTR(A.REGION_CD_CUST,1,2) IN ('71','81','82') THEN 'S26_I_3_32.B.2024' --境外
             END;
       COMMIT;


    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



    --=====================================
    -- 第III部分：1  6辽宁.各项存款余额
    --=====================================
    V_STEP_ID   := 1;
    V_STEP_DESC := '辽宁.各项存款余额';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       C.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S26_I' AS REP_NUM,
       CASE
           WHEN (C.REGION_CD LIKE '11%' AND C.ACCT_NUM <> 'N000310000024539') THEN 'S26_I_3_1.C.2024'  --'%北京%'
           WHEN C.REGION_CD LIKE '12%' THEN 'S26_I_3_2.C.2024'  --'%天津%'
           WHEN C.REGION_CD LIKE '13%' THEN 'S26_I_3_3.C.2024'  --'%河北%'
           WHEN C.REGION_CD LIKE '14%' THEN 'S26_I_3_4.C.2024'  --'%山西%'
           WHEN C.REGION_CD LIKE '15%' THEN 'S26_I_3_5.C.2024'  --'%内蒙古
           WHEN C.REGION_CD LIKE '21%' THEN 'S26_I_3_6.C.2024'  --'%辽宁%'
           WHEN C.REGION_CD LIKE '22%' THEN 'S26_I_3_7.C.2024'  --'%吉林%'
           WHEN C.REGION_CD LIKE '23%' THEN 'S26_I_3_8.C.2024'  --'%黑龙江
           WHEN (C.REGION_CD LIKE '31%' OR C.ACCT_NUM = 'N000310000024539') THEN 'S26_I_3_9.C.2024'  --'%上海%'
           WHEN C.REGION_CD LIKE '32%' THEN 'S26_I_3_10.C.2024'  --'%江苏%'
           WHEN C.REGION_CD LIKE '33%' THEN 'S26_I_3_11.C.2024'  --'%浙江%'
           WHEN C.REGION_CD LIKE '34%' THEN 'S26_I_3_12.C.2024'  --'%安徽%'
           WHEN C.REGION_CD LIKE '35%' THEN 'S26_I_3_13.C.2024'  --'%福建%'
           WHEN C.REGION_CD LIKE '36%' THEN 'S26_I_3_14.C.2024'  --'%江西%'
           WHEN C.REGION_CD LIKE '37%' THEN 'S26_I_3_15.C.2024'  --'%山东%'
           WHEN C.REGION_CD LIKE '41%' THEN 'S26_I_3_16.C.2024'  --'%河南%'
           WHEN C.REGION_CD LIKE '42%' THEN 'S26_I_3_17.C.2024'  --'%湖北%'
           WHEN C.REGION_CD LIKE '43%' THEN 'S26_I_3_18.C.2024'  --'%湖南%'
           WHEN C.REGION_CD LIKE '44%' THEN 'S26_I_3_19.C.2024'  --'%广东%'
           WHEN C.REGION_CD LIKE '45%' THEN 'S26_I_3_20.C.2024'  --'%广西%'
           WHEN C.REGION_CD LIKE '46%' THEN 'S26_I_3_21.C.2024'  --'%海南%'
           WHEN C.REGION_CD LIKE '50%' THEN 'S26_I_3_22.C.2024'  --'%重庆%'
           WHEN C.REGION_CD LIKE '51%' THEN 'S26_I_3_23.C.2024'  --'%四川%'
           WHEN C.REGION_CD LIKE '52%' THEN 'S26_I_3_24.C.2024'  --'%贵州%'
           WHEN C.REGION_CD LIKE '53%' THEN 'S26_I_3_25.C.2024'  --'%云南%'
           WHEN C.REGION_CD LIKE '54%' THEN 'S26_I_3_26.C.2024'  --'%西藏%'
           WHEN C.REGION_CD LIKE '61%' THEN 'S26_I_3_27.C.2024'  --'%陕西%'
           WHEN C.REGION_CD LIKE '62%' THEN 'S26_I_3_28.C.2024'  --'%甘肃%'
           WHEN C.REGION_CD LIKE '63%' THEN 'S26_I_3_29.C.2024'  --'%青海%'
           WHEN C.REGION_CD LIKE '64%' THEN 'S26_I_3_30.C.2024'  --'%宁夏%'
           WHEN C.REGION_CD LIKE '65%' THEN 'S26_I_3_31.C.2024'  --'%新疆%'
           WHEN SUBSTR(C.REGION_CD,1,2) IN ('71','81','82') THEN 'S26_I_3_32.C.2024' --境外
       END AS ITEM_NUM,
       SUM(C.BALANCE) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_TMP_ACCT_DEPOSIT_S2601 C
       WHERE C.DATA_DATE = I_DATADATE
       GROUP BY C.ORG_NUM,
             CASE
               WHEN (C.REGION_CD LIKE '11%' AND C.ACCT_NUM <> 'N000310000024539') THEN 'S26_I_3_1.C.2024'  --'%北京%'
               WHEN C.REGION_CD LIKE '12%' THEN 'S26_I_3_2.C.2024'  --'%天津%'
               WHEN C.REGION_CD LIKE '13%' THEN 'S26_I_3_3.C.2024'  --'%河北%'
               WHEN C.REGION_CD LIKE '14%' THEN 'S26_I_3_4.C.2024'  --'%山西%'
               WHEN C.REGION_CD LIKE '15%' THEN 'S26_I_3_5.C.2024'  --'%内蒙古
               WHEN C.REGION_CD LIKE '21%' THEN 'S26_I_3_6.C.2024'  --'%辽宁%'
               WHEN C.REGION_CD LIKE '22%' THEN 'S26_I_3_7.C.2024'  --'%吉林%'
               WHEN C.REGION_CD LIKE '23%' THEN 'S26_I_3_8.C.2024'  --'%黑龙江
               WHEN (C.REGION_CD LIKE '31%' OR C.ACCT_NUM = 'N000310000024539') THEN 'S26_I_3_9.C.2024'  --'%上海%'
               WHEN C.REGION_CD LIKE '32%' THEN 'S26_I_3_10.C.2024'  --'%江苏%'
               WHEN C.REGION_CD LIKE '33%' THEN 'S26_I_3_11.C.2024'  --'%浙江%'
               WHEN C.REGION_CD LIKE '34%' THEN 'S26_I_3_12.C.2024'  --'%安徽%'
               WHEN C.REGION_CD LIKE '35%' THEN 'S26_I_3_13.C.2024'  --'%福建%'
               WHEN C.REGION_CD LIKE '36%' THEN 'S26_I_3_14.C.2024'  --'%江西%'
               WHEN C.REGION_CD LIKE '37%' THEN 'S26_I_3_15.C.2024'  --'%山东%'
               WHEN C.REGION_CD LIKE '41%' THEN 'S26_I_3_16.C.2024'  --'%河南%'
               WHEN C.REGION_CD LIKE '42%' THEN 'S26_I_3_17.C.2024'  --'%湖北%'
               WHEN C.REGION_CD LIKE '43%' THEN 'S26_I_3_18.C.2024'  --'%湖南%'
               WHEN C.REGION_CD LIKE '44%' THEN 'S26_I_3_19.C.2024'  --'%广东%'
               WHEN C.REGION_CD LIKE '45%' THEN 'S26_I_3_20.C.2024'  --'%广西%'
               WHEN C.REGION_CD LIKE '46%' THEN 'S26_I_3_21.C.2024'  --'%海南%'
               WHEN C.REGION_CD LIKE '50%' THEN 'S26_I_3_22.C.2024'  --'%重庆%'
               WHEN C.REGION_CD LIKE '51%' THEN 'S26_I_3_23.C.2024'  --'%四川%'
               WHEN C.REGION_CD LIKE '52%' THEN 'S26_I_3_24.C.2024'  --'%贵州%'
               WHEN C.REGION_CD LIKE '53%' THEN 'S26_I_3_25.C.2024'  --'%云南%'
               WHEN C.REGION_CD LIKE '54%' THEN 'S26_I_3_26.C.2024'  --'%西藏%'
               WHEN C.REGION_CD LIKE '61%' THEN 'S26_I_3_27.C.2024'  --'%陕西%'
               WHEN C.REGION_CD LIKE '62%' THEN 'S26_I_3_28.C.2024'  --'%甘肃%'
               WHEN C.REGION_CD LIKE '63%' THEN 'S26_I_3_29.C.2024'  --'%青海%'
               WHEN C.REGION_CD LIKE '64%' THEN 'S26_I_3_30.C.2024'  --'%宁夏%'
               WHEN C.REGION_CD LIKE '65%' THEN 'S26_I_3_31.C.2024'  --'%新疆%'
               WHEN SUBSTR(C.REGION_CD,1,2) IN ('71','81','82') THEN 'S26_I_3_32.C.2024' --境外

           END;

    COMMIT;


    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


--===========================================================================
--===========================================================================
    V_STEP_FLAG := 1;
    V_STEP_DESC := V_PROCEDURE || '的业务逻辑全部处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

     UPDATE CBRC_A_REPT_ITEM_VAL
        SET IS_TOTAL = 'N'
      WHERE DATA_DATE = I_DATADATE
        AND REP_NUM = 'S26_I'
        AND ITEM_NUM IN (--集团相关不需要汇总。已在逻辑中处理
                         'S26_I_1.6.A.2024',
                         'S26_I_1.5.A.2024',
                         --存款前十大不需要汇总。已在逻辑中处理
                         'S26_I_2.5.A.2024',
                         'S26_I_2.5.B.2024',
                         'S26_I_2.5.C.2024',
                         'S26_I_2.5.D.2024',
                         'S26_I_2.5.E.2024',
                         'S26_I_2.5.F.2024'
                         );

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
   
END ;