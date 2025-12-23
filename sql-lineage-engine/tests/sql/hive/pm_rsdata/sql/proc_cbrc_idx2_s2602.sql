CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_s2602(II_DATADATE IN string --跑批日期
                                              )
/******************************
  @author:ZY
  @create-date:20240312
  @description:S26_II 城商行省外分支机构情况表
  @modification history:
  m0.author-create_date-description
  --需求编号：JLBA202504160004_关于吉林银行修改单一客户授信逻辑的需求 提出人：苏桐  上线时间：20250627 修改人：石雨 修改内容：客户授信逻辑

目标表：CBRC_A_REPT_ITEM_VAL 
依赖表：CBRC_U_BASE_INST
临时表：CBRC_TMP_LOAN_FEI_S2602
     CBRC_TMP_LOAN_S2602
     CBRC_TMP_ORG_S2602
集市表：SMTMODS_L_ACCT_LOAN
     SMTMODS_L_ACCT_OBS_LOAN
     SMTMODS_L_AGRE_CREDITLINE
     SMTMODS_L_CUST_ALL
     SMTMODS_L_CUST_C
     SMTMODS_L_CUST_C_GROUP_INFO
     SMTMODS_L_CUST_C_GROUP_MEM
     SMTMODS_L_CUST_SUPLY_CHAIN
     SMTMODS_L_PUBL_ORG_BRA
     SMTMODS_L_PUBL_RATE

  *******************************/
 IS
  --V_SCHEMA    VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE VARCHAR(30); --当前储存过程名称
  V_TAB_NAME  VARCHAR(30); --目标表名
  I_DATADATE  string; --数据日期(数值型)YYYYMMDD
  --V_DATADATE  VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  V_STEP_ID   INTEGER; --任务号
  V_ERRORCODE VARCHAR(20); --错误编码
  V_STEP_DESC VARCHAR(300); --任务描述
  V_STEP_FLAG INTEGER; --任务执行状态标识
  V_ERRORDESC VARCHAR(280); --错误内容
  II_STATUS   INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM    VARCHAR(30);
  
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';

    I_DATADATE  := II_DATADATE;
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_S2602');
	V_SYSTEM    := 'CBRC';
	
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_TAB_NAME := 'CBRC_A_REPT_ITEM_VAL';
    --V_DATADATE := TO_CHAR(I_DATADATE, 'YYYY-MM-DD');

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']S2602当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'S26_II'
       AND T.FLAG = '2';
    COMMIT;

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP_ORG_S2602';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP_LOAN_S2602';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP_LOAN_FEI_S2602';


    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

  --=====================================
    --   S26_II 省外网点、支行、分行数据宽表
    --=====================================


    V_STEP_ID   := 2;
    V_STEP_DESC := '省外网点、支行、分行数据宽表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

INSERT  INTO CBRC_TMP_ORG_S2602
(DATA_DATE,
THIRD_ORG,
THIRD_NAM,
SECOND_ORG,
SECOND_NAM,
FIRST_ORG,
FIRST_NAM
)
SELECT 
 A.DATA_DATE,    ----数据日期
 A.ORG_NUM    AS THIRD_ORG, ---网点机构
 A.ORG_NAM    AS THIRD_NAM, --网点名称
 C.SECOND_ORG AS SECOND_ORG, --  支行机构
 C.SECOND_NAM AS SECOND_NAM, --  支行名称
 C.FIRST_ORG  AS FIRST_ORG, -- 分行机构
 C.FIRST_NAM  AS FIRST_NAM -- 分行名称
  FROM SMTMODS_L_PUBL_ORG_BRA A
 INNER JOIN (SELECT 
              A.DATA_DATE,
              A.ORG_NUM   AS SECOND_ORG, --  支行机构
              A.ORG_NAM   AS SECOND_NAM, --  支行名称
              B.ORG_NUM   AS FIRST_ORG, --  分行机构
              B.ORG_NAM   AS FIRST_NAM --- 分行名称
               FROM SMTMODS_L_PUBL_ORG_BRA A
              INNER JOIN (SELECT B.DATA_DATE, --数据日期
                                B.ORG_NUM, ---  分行机构
                                B.ORG_NAM ---  分行名称
                           FROM SMTMODS_L_PUBL_ORG_BRA B
                          INNER JOIN CBRC_UPRR_U_BASE_INST A
                             ON B.ORG_NUM = A.INST_ID
                          WHERE B.DATA_DATE = I_DATADATE
                            AND A.PARENT_INST_ID = '210000'
                            AND A.ENABLED = 'true') B --   分行表
                 ON A.UP_ORG_NUM = B.ORG_NUM
                AND A.DATA_DATE = B.DATA_DATE
              WHERE A.DATA_DATE = I_DATADATE
                AND A.ORG_NUM LIKE '%00') C ---- 支行表
    ON A.UP_ORG_NUM = C.SECOND_ORG
   AND A.DATA_DATE = C.DATA_DATE
 WHERE A.DATA_DATE = I_DATADATE;
 COMMIT;


    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --=====================================
    --   S26_II 省外分支机构基本情况.6辽宁.省外一级分行数量
    --=====================================

    V_STEP_ID   := 3;
    V_STEP_DESC := '省外一级分行数量';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

INSERT INTO CBRC_A_REPT_ITEM_VAL
  (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)

  SELECT 
   T.DATA_DATE,
   T.FIRST_ORG AS ORG_NUM,
   'CBRC' AS SYS_NAM,
   'S26_II' AS REP_NUM,
   'S26_II_6.A.2024' AS ITEM_NUM,
   COUNT(DISTINCT T.FIRST_ORG) AS ITEM_VAL,
   '2'
    FROM CBRC_TMP_ORG_S2602 T
   WHERE T.DATA_DATE = I_DATADATE
   GROUP BY  T.DATA_DATE,
   T.FIRST_ORG;
COMMIT;


    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --=====================================
    --   S26_II 省外分支机构基本情况.6辽宁.省外二级分行数量
    --=====================================

    V_STEP_ID   := 4;
    V_STEP_DESC := '支行数量';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   INSERT INTO CBRC_A_REPT_ITEM_VAL
     (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
          SELECT 
      T.DATA_DATE,
      T.FIRST_ORG AS ORG_NUM,
      'CBRC' AS SYS_NAM,
      'S26_II' AS REP_NUM,
      'S26_II_6.C.2024' AS ITEM_NUM,
      COUNT(DISTINCT T.SECOND_ORG) AS ITEM_VAL,
      '2'
       FROM CBRC_TMP_ORG_S2602 T
      WHERE T.DATA_DATE = I_DATADATE
      GROUP BY T.DATA_DATE, T.FIRST_ORG;
   COMMIT;


    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S26_II 省外分支机构基本情况.6辽宁.省外支行数量
    --=====================================

    V_STEP_ID   := 5;
    V_STEP_DESC := '网点数量';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
 SELECT 
      T.DATA_DATE,
      T.FIRST_ORG AS ORG_NUM,
      'CBRC' AS SYS_NAM,
      'S26_II' AS REP_NUM,
      'S26_II_6.D.2024' AS ITEM_NUM,
      COUNT(DISTINCT T.THIRD_ORG) AS ITEM_VAL,
      '2'
       FROM CBRC_TMP_ORG_S2602 T
      WHERE T.DATA_DATE = I_DATADATE
      GROUP BY T.DATA_DATE, T.FIRST_ORG;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --==========================================================
    --   S26_II 省外分行资产情况.6辽宁.(贸易融资、供应链）贷款宽表
    --===========================================================


    V_STEP_ID   := 6;
    V_STEP_DESC := '贷款余额（贸易融资、供应链）';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

---贸易融资、供应链-----
INSERT INTO CBRC_TMP_LOAN_S2602
  (DATA_DATE, --日期
   ORG_NUM, ---机构
   REGION_CD_CUST, --客户所属地区
   CUST_ID, --  客户号
   LOAN_NUM, --  借据号
   ACCT_BAL, -- 余额
   GL_ITEM_CODE, -- 科目号
   TAG1 -- 业务标识
   )
--------贸易融资---------
  SELECT I_DATADATE AS DATA_DATE,
         A.ORG_NUM AS ORG_NUM,
         B.REGION_CD AS REGION_CD_CUST,
         A.CUST_ID AS CUST_ID,
         A.LOAN_NUM AS LOAN_NUM,
         A.LOAN_ACCT_BAL* U.CCY_RATE  AS ACCT_BAL,
         A.ITEM_CD AS GL_ITEM_CODE,
         'MYRZ' AS TAG1 --贸易融资
    FROM SMTMODS_L_ACCT_LOAN A
    LEFT JOIN SMTMODS_L_CUST_ALL B
      ON A.CUST_ID = B.CUST_ID
     AND B.DATA_DATE = I_DATADATE
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = I_DATADATE
     AND U.BASIC_CCY = A.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
     AND U.DATA_DATE = I_DATADATE
   WHERE A.DATA_DATE = I_DATADATE
     AND A.ITEM_CD LIKE '1305%' --贸易融资
     AND A.ACCT_TYP NOT LIKE '90%' --去委托贷款
     AND A.ACCT_STS <> '3' --去结清
     AND A.CANCEL_FLG <> 'Y' --去核销
   AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
  UNION ALL
  -------供应链----------
  SELECT I_DATADATE AS DATA_DATE,
         A.ORG_NUM AS ORG_NUM,
         B.REGION_CD AS REGION_CD_CUST,
         A.CUST_ID AS CUST_ID,
         A.LOAN_NUM AS LOAN_NUM,
         A.LOAN_ACCT_BAL AS ACCT_BAL,
         A.ITEM_CD AS GL_ITEM_CODE,
         'GYL' AS TAG1 --供应链
    FROM SMTMODS_L_ACCT_LOAN A
    LEFT JOIN SMTMODS_L_CUST_ALL B
      ON A.CUST_ID = B.CUST_ID
     AND B.DATA_DATE = I_DATADATE
   INNER JOIN (SELECT DISTINCT CUST_ID
                 FROM SMTMODS_L_CUST_SUPLY_CHAIN
                WHERE DATA_DATE = I_DATADATE) E   ---供应链融资客户信息表
      ON A.CUST_ID = E.CUST_ID
   WHERE A.DATA_DATE = I_DATADATE
     AND A.ACCT_TYP NOT LIKE '90%' --去委托贷款
     AND A.ACCT_STS <> '3' --去结清
     AND A.CANCEL_FLG <> 'Y' --去核销
   AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
  UNION ALL
  SELECT I_DATADATE AS DATA_DATE,
         A.ORG_NUM AS ORG_NUM,
         B.REGION_CD AS REGION_CD_CUST,
         A.CUST_ID AS CUST_ID,
         A.ACCT_NUM AS LOAN_NUM,
         A.BALANCE AS ACCT_BAL,
         A.GL_ITEM_CODE AS GL_ITEM_CODE,
         'GYL' AS TAG1 --供应链
    FROM SMTMODS_L_ACCT_OBS_LOAN A
    LEFT JOIN SMTMODS_L_CUST_ALL B
      ON A.CUST_ID = B.CUST_ID
     AND B.DATA_DATE = I_DATADATE
   INNER JOIN (SELECT DISTINCT CUST_ID
                 FROM SMTMODS_L_CUST_SUPLY_CHAIN
                WHERE DATA_DATE = I_DATADATE) E
      ON A.CUST_ID = E.CUST_ID
   WHERE A.DATA_DATE = I_DATADATE
     AND A.ACCT_TYP NOT LIKE '90%' --去委托贷款
     AND A.ACCT_STS <> '3' --去结清
       ;
COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


  --=====================================
    --   S26_II 省外分行资产情况.6辽宁.其中：分行所在省外贷款余额（除贸易融资、供应链）
    --=====================================

    V_STEP_ID   := 7;
    V_STEP_DESC := '贷款余额（除贸易融资、供应链）';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

INSERT INTO CBRC_A_REPT_ITEM_VAL
(DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
SELECT 
 A.DATA_DATE,
 A.ORG_NUM,
 'CBRC' AS SYS_NAM,
 'S26_II' AS REP_NUM,
 'S26_II_7.M.2024' AS ITEM_NUM,
 SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL,
 '2' AS FLAG
  FROM SMTMODS_L_ACCT_LOAN A
  LEFT JOIN SMTMODS_L_PUBL_RATE U
    ON U.CCY_DATE = I_DATADATE
   AND U.BASIC_CCY = A.CURR_CD --基准币种
   AND U.FORWARD_CCY = 'CNY' --折算币种
   AND U.DATA_DATE = I_DATADATE
 WHERE A.DATA_DATE = I_DATADATE
   AND NOT EXISTS (SELECT 
         1
          FROM CBRC_TMP_LOAN_S2602 T2
         WHERE A.DATA_DATE = T2.DATA_DATE
           AND A.LOAN_NUM = T2.LOAN_NUM)
   AND A.ACCT_TYP NOT LIKE '90%' --去委托贷款
   AND A.ACCT_STS <> '3' --去结清
   AND A.CANCEL_FLG <> 'Y' --去核销
   AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
 GROUP BY A.DATA_DATE, A.ORG_NUM;
COMMIT;


    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --==========================================
    --S26_II 集中度情况.6辽宁.非金融企业贷款宽表
    --=========================================


    V_STEP_ID   := 8;
    V_STEP_DESC := '非金融企业贷款宽表(集团和单一法人)';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
--母公司、成员、交易均在省外
INSERT INTO CBRC_TMP_LOAN_FEI_S2602
  (DATA_DATE, ORG_NUM, CUST_NO, LOAN_ACCT_BAL, TAG,CUST_NO_MEM)
------集团-------
  SELECT 
   T.DATA_DATE AS DATA_DATE,
   T2.ORG_NUM AS ORG_NUM,
   T2.CUST_GROUP_NO AS CUST_GROUP_NO,  ---集团号
   SUM(T.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL,
   'JT' AS TAG,
   T3.GROUP_MEM_NO
    FROM SMTMODS_L_ACCT_LOAN T ---借据表
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON T.CURR_CD = U.BASIC_CCY
     AND U.CCY_DATE = I_DATADATE
     AND U.FORWARD_CCY = 'CNY'
     AND U.DATA_DATE = I_DATADATE
   INNER JOIN SMTMODS_L_CUST_C T1 --对公客户表
      ON T.CUST_ID = T1.CUST_ID
     AND T.DATA_DATE = T1.DATA_DATE
     AND T1.DATA_DATE = I_DATADATE
   INNER JOIN SMTMODS_L_CUST_C_GROUP_MEM T3 --集团成员表
      ON T.CUST_ID = T3.GROUP_MEM_NO
     AND SUBSTR(T.ORG_NUM,1,3) = SUBSTR(T3.ORG_NUM,1,3)
     AND T.DATA_DATE = T3.DATA_DATE
     AND T3.DATA_DATE = I_DATADATE
   INNER JOIN SMTMODS_L_CUST_C_GROUP_INFO T2 --集团客户表
      ON T3.CUST_GROUP_NO = T2.CUST_GROUP_NO
     AND SUBSTR(T2.ORG_NUM,1,3) = SUBSTR(T3.ORG_NUM,1,3)
     AND T3.DATA_DATE = T2.DATA_DATE
     AND T2.DATA_DATE = I_DATADATE
   WHERE T.LOAN_PURPOSE_CD NOT LIKE 'J%' --行业类别、非金融企业
     AND T.DATA_DATE = I_DATADATE
     AND T.LOAN_ACCT_BAL <> 0
     AND T.ACCT_TYP NOT LIKE '90%' --去委托贷款
     AND T.ACCT_STS <> '3' --去结清
     AND T.CANCEL_FLG <> 'Y' --去核销
   AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
     AND T1.CUST_TYP NOT LIKE '9%'
     AND T1.CUST_TYP  <> '3'
   GROUP BY T2.ORG_NUM, T2.CUST_GROUP_NO, T.DATA_DATE,T3.GROUP_MEM_NO;
   COMMIT;


   INSERT INTO CBRC_TMP_LOAN_FEI_S2602
  (DATA_DATE, ORG_NUM, CUST_NO, LOAN_ACCT_BAL, TAG)
  ------单一法人-----------
  SELECT 
   T.DATA_DATE AS DATA_DATE,
   T.ORG_NUM AS ORG_NUM,
   T.CUST_ID AS CUST_GROUP_NO,
   SUM(T.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL,
   'DF' AS TAG
    FROM SMTMODS_L_ACCT_LOAN T
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON T.CURR_CD = U.BASIC_CCY
     AND U.CCY_DATE = I_DATADATE
     AND U.FORWARD_CCY = 'CNY'
     AND U.DATA_DATE = I_DATADATE
   INNER JOIN (SELECT 
               DISTINCT (A.CUST_ID) CUST_ID, A.DATA_DATE
                 FROM SMTMODS_L_AGRE_CREDITLINE A
                WHERE
                ----需求编号：JLBA202504160004_关于吉林银行修改单一客户授信逻辑的需求 提出人：苏桐  上线时间：20250627 修改内容：客户授信逻辑
                A.FACILITY_TYP IN( '2','4','1')
                AND A.FACILITY_STS ='Y'
                AND A.DATA_DATE = I_DATADATE   ----单一法人、所有集团成员、供应链
               ) T1
      ON T.CUST_ID = T1.CUST_ID
     AND T.DATA_DATE = T1.DATA_DATE
   INNER JOIN SMTMODS_L_CUST_C C
      ON T.CUST_ID = C.CUST_ID
     AND C.DATA_DATE = I_DATADATE
   WHERE T.LOAN_PURPOSE_CD NOT LIKE 'J%' --行业类别、非金融企业
     AND T.DATA_DATE = I_DATADATE
     AND T.LOAN_ACCT_BAL <> 0
     AND T.ACCT_TYP NOT LIKE '90%' --去委托贷款
     AND T.ACCT_STS <> '3' --去结清
     AND T.CANCEL_FLG <> 'Y' --去核销
   AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
     AND C.CUST_TYP  NOT LIKE '9%' AND   C.CUST_TYP  <> '3'  --3:个体工商户,9其他组织机构
     AND NOT EXISTS  (SELECT  1  FROM  CBRC_TMP_LOAN_FEI_S2602  T1  WHERE  T1.TAG='JT'  AND T.CUST_ID  =T1.CUST_NO_MEM  AND T1.DATA_DATE = T.DATA_DATE   )
     --成员是大连和沈阳，但是母公司非大连和沈阳，算单一法人
   GROUP BY T.DATA_DATE, T.ORG_NUM, T.CUST_ID;
COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

     --=====================================
    --S26_II 集中度情况.6辽宁.非金融企业贷款余额
    --=====================================
    V_STEP_ID   := 9;
    V_STEP_DESC := '非金融企业贷款余额,';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

INSERT INTO CBRC_A_REPT_ITEM_VAL
  (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
    SELECT 
     T.DATA_DATE,
     T.ORG_NUM,
     'CBRC',
     'S26_II',
     'S26_II_6.S.2024',
     SUM(T.LOAN_ACCT_BAL) AS ITEM_VAL,
     '2'
      FROM CBRC_TMP_LOAN_FEI_S2602 T
     WHERE DATA_DATE = I_DATADATE
     GROUP BY T.DATA_DATE, T.ORG_NUM;
COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --=====================================
    --   S26_II 集中度情况.6辽宁.非金融企业贷款户数
    --=====================================


    V_STEP_ID   := 10;
    V_STEP_DESC := '非金融企业贷款户数';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

INSERT INTO CBRC_A_REPT_ITEM_VAL
  (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
  SELECT 
   T.DATA_DATE,
   T.ORG_NUM,
   'CBRC',
   'S26_II',
   'S26_II_6.T.2024',
   COUNT(1) AS ITEM_VAL,
   '2'
    FROM CBRC_TMP_LOAN_FEI_S2602 T
   WHERE DATA_DATE = I_DATADATE
   GROUP BY T.DATA_DATE, T.ORG_NUM;

COMMIT;


    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

  --=====================================
    --   S26_II 集中度情况.6辽宁.最大十户非金融企业贷款合计余额
    --=====================================


    V_STEP_ID   := 11;
    V_STEP_DESC := '按照集团、单一法人确认十大户';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

INSERT INTO CBRC_A_REPT_ITEM_VAL
  (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG,IS_TOTAL)
    SELECT A.DATA_DATE,
         A.FIRST_ORG,
         'CBRC',
         'S26_II',
         'S26_II_6.U.2024',
         A.ITEM_VAL,
         '2',
         'N'
    FROM (SELECT 
           T.DATA_DATE,
           T1.FIRST_ORG,
           T.CUST_NO,
           T.TAG,
           SUM(LOAN_ACCT_BAL) AS ITEM_VAL,
           ROW_NUMBER() OVER(PARTITION BY T.DATA_DATE, T1.FIRST_ORG  ORDER BY SUM(LOAN_ACCT_BAL) DESC) AS RANK_SEQ
            FROM CBRC_TMP_LOAN_FEI_S2602 T
            LEFT  JOIN  CBRC_TMP_ORG_S2602 T1
            ON T.ORG_NUM   = T1.THIRD_ORG
            AND T.DATA_DATE  = T1.DATA_DATE
           WHERE T.DATA_DATE = I_DATADATE
           GROUP BY T.DATA_DATE,
           T.DATA_DATE,
           T1.FIRST_ORG,
           T.CUST_NO,
           T.TAG) A
   WHERE RANK_SEQ <= 10  AND A.FIRST_ORG IS NOT  NULL;
COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


--===========================================================================
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
   
END proc_cbrc_idx2_s2602