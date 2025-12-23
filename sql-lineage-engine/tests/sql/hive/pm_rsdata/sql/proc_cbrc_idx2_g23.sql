CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g23(II_DATADATE IN STRING --跑批日期
                                              )
/******************************
  @author:JIHAIJING
  @create-date:20150929
  @description:G23
  @modification history:
  m0.author-create_date-description
  [JLBA202507210012_关于调整财政性存款及一般性存款相关科目统计方式的相关需求][提出人：于佳禾][上线时间：20250918][修改人：石雨][修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]


目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_TOP_G23
     CBRC_TOP_G23_SY_SUM
     CBRC_TOP_G23_TMP2_UPS
     CBRC_TOP_G23_TMP_UPS
     CBRC_TMP_GROUP_MEM
     CBRC_TMP_GROUP_MEM_2
依赖表：CBRC_UPRR_U_BASE_INST
集市表：SMTMODS_L_ACCT_DEPOSIT
     SMTMODS_L_ACCT_FUND_MMFUND
     SMTMODS_L_CUST_ALL
     SMTMODS_L_CUST_C
     SMTMODS_L_CUST_C_GROUP_INFO
     SMTMODS_L_CUST_C_GROUP_MEM
     SMTMODS_L_CUST_P
     SMTMODS_L_PUBL_RATE

  *******************************/
 IS
  V_SCHEMA    VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE VARCHAR(30); --当前储存过程名称
  V_TAB_NAME  VARCHAR(30); --目标表名
  I_DATADATE  STRING; --数据日期(数值型)YYYYMMDD
  V_DATADATE  VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  V_STEP_ID   INTEGER; --任务号
  V_ERRORCODE VARCHAR(20); --错误编码
  V_STEP_DESC VARCHAR(300); --任务描述
  V_STEP_FLAG INTEGER; --任务执行状态标识
  V_ERRORDESC VARCHAR(280); --错误内容
  II_STATUS   INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM    VARCHAR2(30);
  
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';

    I_DATADATE  := II_DATADATE;
    V_SYSTEM    := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G23');
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_TAB_NAME := 'CBRC_A_REPT_ITEM_VAL';
    V_DATADATE := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYY-MM-DD');

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']G23当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'G23'
       AND T.FLAG = '1';
    COMMIT;
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP_GROUP_MEM ';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP_GROUP_MEM_2 ';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TOP_G23_TMP_UPS ';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TOP_G23_TMP2_UPS ';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TOP_G23';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TOP_G23_SY_SUM'; --add by djh 20230103松原220700-松原分行市辖区，220701-松原分行前郭县机构汇总临时表


    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 2;
    V_STEP_DESC := '集团成员信息预处理';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_TMP_GROUP_MEM 
      (ORG_ID_NO, --组织机构代码
       GROUP_MEM_NAM, --集团名称
       GROUP_MEM_NO --成员代码
       )
      SELECT 
       NVL(D.ORG_ID_NO, B.ORG_ID_NO) AS ORG_ID_NO, --组织机构代码
       C.CUST_GROUP_NAM AS GROUP_MEM_NAM, --集团名称
       B.GROUP_MEM_NO --成员代码
        FROM SMTMODS_L_CUST_C_GROUP_MEM B
       INNER JOIN SMTMODS_L_CUST_C_GROUP_INFO C
          ON B.CUST_GROUP_NO = C.CUST_GROUP_NO
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C_GROUP_MEM D
          ON B.GROUP_MEM_NO = D.GROUP_MEM_NO
         AND D.DATA_DATE = I_DATADATE
         AND D.GROUP_FLAG = 'Y'
       WHERE B.DATA_DATE = I_DATADATE;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 3;
    V_STEP_DESC := '过滤条件1（各项存款不含委托存款和财政性存款，包含国库定期存款）';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -- EXECUTE IMMEDIATE 'ALTER INDEX IND_CBRC_TMP_GROUP_MEM_2 UNUSABLE';
    INSERT 
    INTO CBRC_TMP_GROUP_MEM_2 
      (ORG_NUM, --机构号
       CUST_ID, --客户号
       ACCT_BALANCE, --账户余额
       CURR_CD, --账户币种
       MATUR_DATE, --到期日
       ID_NO, --证件号码
       CUST_NAM, --客户中文名称
       ORG_ID_NO, --组织机构代码
       GROUP_MEM_NAM --集团成员名称
       )
      SELECT 
       X.ORG_NUM, --机构号
       X.CUST_ID, --客户号
       X.ACCT_BALANCE, --账户余额
       X.CURR_CD, --账户币种
       X.MATUR_DATE, --到期日
       X.ID_NO, --证件号码
       X.CUST_NAM, --客户中文名称
       CASE
         WHEN X.CUST_GROUP_NO IS NOT NULL THEN
          X.ORG_ID_NO2
         ELSE
          CASE
            WHEN X.RN = 1 THEN
             X.ORG_ID_NO1
          END
       END AS ORG_ID_NO, --组织机构代码
       CASE
         WHEN X.CUST_GROUP_NO IS NOT NULL THEN
          X.CUST_GROUP_NAM
         ELSE
          CASE
            WHEN X.RN = 1 THEN
             X.CUST_NAM
          END
       END AS GROUP_MEM_NAM --集团成员名称
        FROM (SELECT 
               A.ORG_NUM, --机构号
               A.CUST_ID, --客户号
               A.ACCT_BALANCE, --账户余额
               A.CURR_CD, --账户币种
               A.MATUR_DATE, --到期日
               T1.ID_NO, --证件号码
               T1.CUST_NAM, --客户中文名称
               B.GROUP_FLAG,
               B.ORG_ID_NO AS ORG_ID_NO1,
               E.ORG_ID_NO AS ORG_ID_NO2,
               C.CUST_GROUP_NAM,
               E.ORG_ID_NO CUST_GROUP_NO, --CHANGED BY LIRUITING
               ROW_NUMBER() OVER(PARTITION BY B.CUST_GROUP_NO, B.GROUP_MEM_NO ORDER BY B.GROUP_FLAG ASC, A.ACCT_BALANCE DESC) AS RN
                FROM SMTMODS_L_ACCT_DEPOSIT A
               INNER JOIN (SELECT DISTINCT T.CUST_ID
                            FROM SMTMODS_L_ACCT_DEPOSIT T
                           WHERE T.DATA_DATE = I_DATADATE) D
                  ON D.CUST_ID = A.CUST_ID
               INNER JOIN SMTMODS_L_CUST_ALL T1
                  ON D.CUST_ID = T1.CUST_ID
                 AND T1.DATA_DATE = I_DATADATE
                LEFT 
                JOIN SMTMODS_L_CUST_C_GROUP_MEM B --CHANGED BY LIRUITING
                  ON A.CUST_ID = B.GROUP_MEM_NO
                 AND B.DATA_DATE = I_DATADATE
                LEFT 
                JOIN SMTMODS_L_CUST_C_GROUP_INFO C --CHANGED BY LIRUITING
                  ON B.CUST_GROUP_NO = C.CUST_GROUP_NO
                 AND C.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_CUST_C_GROUP_MEM E
                  ON B.GROUP_MEM_NO = E.GROUP_MEM_NO
                 AND B.CUST_GROUP_NO = E.CUST_GROUP_NO
                 AND E.DATA_DATE = I_DATADATE
                 AND E.GROUP_FLAG = 'Y'
               WHERE (SUBSTR(NVL(A.ACCT_TYPE, '0'), 1, 2) NOT IN
                     ('09', '11') OR A.ACCT_TYPE = '11035'

                     )
                  AND A.ACCT_TYPE NOT IN ('9999','7777','8888','6666'/*,'9001'*/) --剔除内部户及久悬户[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款]
                 /*9999  虚拟账户 7777  母虚账户 8888  子虚账户 6666  久悬户及转营业外账户 9001  久悬*/
                 and a.gl_item_code not like '3010%' --剔除委托存款
               --  and a.gl_item_code not like '201103%' --剔除财政性存款 --[JLBA202507210012][石雨][修改内容：201103（财政性存款 ）调整为 一般单位活期存款，原逻辑中剔除]
                    --AND A.GL_ITEM_CODE NOT LIKE '234%' --ADD SHIYU 20220707 剔除234科目
                 AND A.GL_ITEM_CODE NOT LIKE '2012%' -- 20221125 UPDATE BY WANGKUI 新老科目映射
                 AND A.GL_ITEM_CODE NOT LIKE '250202%' -- 20221125 UPDATE BY WANGKUI 新老科目映射

                 AND A.ACCT_BALANCE > 0
                 AND A.DATA_DATE = I_DATADATE) X;

    COMMIT;
    --   EXECUTE IMMEDIATE 'ALTER INDEX IND_CBRC_TMP_GROUP_MEM_2 REBUILD ';

    INSERT 
    INTO CBRC_TOP_G23_TMP_UPS 
      (ORG_NUM, --机构号
       CUST_ID, --客户号
       CUST_NAM, --客户名称
       ACCT_BAL, --存款余额
       ACCT_BAL_RMB, --存款余额_人民币
       FIXED_ACCT_BAL, --其中：定期存款余额
       FIXED_ACCT_BAL_RMB, --其中：定期存款余额_人民币
       CUST_ID_RE --ADD BY LRT 20170823
       )
      SELECT 
       A.ORG_NUM, --机构号
       NVL(A.ORG_ID_NO, A.ID_NO) AS CUST_ID, --客户号
       NVL(A.GROUP_MEM_NAM, A.CUST_NAM) AS CUST_NAM, --客户名称
       A.ACCT_BALANCE AS ACCT_BAL, --存款余额
       CASE
         WHEN A.CURR_CD != 'CNY' THEN
          A.ACCT_BALANCE * U.CCY_RATE
         ELSE
          A.ACCT_BALANCE
       END AS ACCT_BAL_RMB, --存款余额_人民币
       CASE
         WHEN A.MATUR_DATE IS NOT NULL THEN
          A.ACCT_BALANCE
       END AS FIXED_ACCT_BAL, --其中：定期存款余额
       CASE
         WHEN A.MATUR_DATE IS NOT NULL THEN
          CASE
            WHEN A.CURR_CD != 'CNY' THEN
             A.ACCT_BALANCE * U.CCY_RATE
            ELSE
             A.ACCT_BALANCE
          END
       END AS FIXED_ACCT_BAL_RMB, --其中：定期存款余额_人民币
       A.CUST_ID
        FROM CBRC_TMP_GROUP_MEM_2 A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE; --数据日期  --changed by liruiting 增加汇率表数据日期过滤条件
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 4;
    V_STEP_DESC := '过滤条件2（保险公司存放）';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_TOP_G23_TMP_UPS 
      (ORG_NUM, --机构号
       CUST_ID, --客户号
       CUST_NAM, --客户名称
       ACCT_BAL, --存款余额
       ACCT_BAL_RMB, --存款余额_人民币
       FIXED_ACCT_BAL, --其中：定期存款余额
       FIXED_ACCT_BAL_RMB, --其中：定期存款余额_人民币
       CUST_ID_RE)
      SELECT 
       A.ORG_NUM, --机构号
       NVL(B.ORG_ID_NO, T1.ID_NO) AS CUST_ID, --客户号
       NVL(B.GROUP_MEM_NAM, T1.CUST_NAM) AS CUST_NAM, --客户名称
       A.BALANCE AS ACCT_BAL, --存款余额
       A.BALANCE * U.CCY_RATE AS ACCT_BAL_RMB, --存款余额_人民币
       CASE
         WHEN A.MATURE_DATE IS NOT NULL THEN
          A.BALANCE
       END AS FIXED_ACCT_BAL, --其中：定期存款余额
       CASE
         WHEN A.MATURE_DATE IS NOT NULL THEN
          A.BALANCE * U.CCY_RATE
       END AS FIXED_ACCT_BAL_RMB, --其中：定期存款余额_人民币
       A.CUST_ID
        FROM SMTMODS_L_ACCT_FUND_MMFUND A
       INNER JOIN (SELECT DISTINCT T.CUST_ID
                     FROM SMTMODS_L_ACCT_FUND_MMFUND T
                    WHERE T.DATA_DATE = I_DATADATE) D
          ON D.CUST_ID = A.CUST_ID
       INNER JOIN SMTMODS_L_CUST_ALL T1
          ON D.CUST_ID = T1.CUST_ID
         AND T1.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_CUST_C T2
          ON D.CUST_ID = T2.CUST_ID
         AND T2.DATA_DATE = I_DATADATE
         AND T2.FINA_CODE LIKE 'F%'
        LEFT JOIN CBRC_TMP_GROUP_MEM B
          ON A.CUST_ID = B.GROUP_MEM_NO
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ACCT_TYP LIKE '201%'
         AND A.ACCT_TYP <> '20107'
         AND A.BALANCE > 0
         AND A.DATA_DATE = I_DATADATE
         AND (T2.FINA_CODE LIKE 'F%' OR T2.FINA_CODE = 'H00000' OR
             A.FOREIGN_EX_RESERVE_FLG = 'Y');
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 5;
    V_STEP_DESC := '过滤条件3(2009年1月1日前的邮储协议存款)';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_TOP_G23_TMP_UPS 
      (ORG_NUM, --机构号
       CUST_ID, --客户号
       CUST_NAM, --客户名称
       ACCT_BAL, --存款余额
       ACCT_BAL_RMB, --存款余额_人民币
       FIXED_ACCT_BAL, --其中：定期存款余额
       FIXED_ACCT_BAL_RMB, --其中：定期存款余额_人民币
       CUST_ID_RE)
      SELECT 
       A.ORG_NUM, --机构号
       NVL(B.ORG_ID_NO, T1.ID_NO) AS CUST_ID, --客户号
       NVL(B.GROUP_MEM_NAM, T1.CUST_NAM) AS CUST_NAM, --客户名称
       A.BALANCE AS ACCT_BAL, --存款余额
       A.BALANCE * U.CCY_RATE AS ACCT_BAL_RMB, --存款余额_人民币
       CASE
         WHEN A.MATURE_DATE IS NOT NULL THEN
          A.BALANCE
       END AS FIXED_ACCT_BAL, --其中：定期存款余额
       CASE
         WHEN A.MATURE_DATE IS NOT NULL THEN
          A.BALANCE * U.CCY_RATE
       END AS FIXED_ACCT_BAL_RMB, --其中：定期存款余额_人民币
       A.CUST_ID
        FROM SMTMODS_L_ACCT_FUND_MMFUND A
       INNER JOIN (SELECT DISTINCT T.CUST_ID
                     FROM SMTMODS_L_ACCT_FUND_MMFUND T
                    WHERE T.DATA_DATE = I_DATADATE) D
          ON D.CUST_ID = A.CUST_ID
       INNER JOIN SMTMODS_L_CUST_ALL T1
          ON D.CUST_ID = T1.CUST_ID
         AND T1.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_CUST_C T2
          ON D.CUST_ID = T2.CUST_ID
         AND T2.DATA_DATE = I_DATADATE
         AND T2.FINA_CODE = 'C12141'
        LEFT JOIN CBRC_TMP_GROUP_MEM B
          ON A.CUST_ID = B.GROUP_MEM_NO
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ACCT_TYP = '20107'
         AND A.BALANCE > 0
         AND A.START_DATE <= '20090101'
         AND A.DATA_DATE = I_DATADATE;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 6;
    V_STEP_DESC := '汇总客户金额';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_TOP_G23_TMP2_UPS 
      (ORG_NUM, --机构号
       CUST_ID, --客户号
       CUST_NAM, --客户名称
       ACCT_BAL, --存款余额
       ACCT_BAL_RMB, --存款余额_人民币
       FIXED_ACCT_BAL, --其中：定期存款余额
       FIXED_ACCT_BAL_RMB, --其中：定期存款余额_人民币
       CUST_ID_RE)
      SELECT 
       CASE
         WHEN SUBSTR(A.ORG_NUM, 1, 2) IN ('10', '11', '08') THEN
          SUBSTR(A.ORG_NUM, 1, 2) || '0000'
         ELSE
          SUBSTR(A.ORG_NUM, 1, 4) || '00'
       END, --机构号
       CUST_ID, --客户号
       CUST_NAM, --客户名称
       SUM(ACCT_BAL), --存款余额
       SUM(ACCT_BAL_RMB), --存款余额_人民币
       SUM(FIXED_ACCT_BAL), --其中：定期存款余额
       SUM(FIXED_ACCT_BAL_RMB), --其中：定期存款余额_人民币
       CUST_ID_RE
        FROM CBRC_TOP_G23_TMP_UPS A
       where SUBSTR(A.ORG_NUM, 5, 2) <> '00'
         AND A.CUST_ID <> '0'
         AND A.ORG_NUM <> '029804'
       GROUP BY CASE
                  WHEN SUBSTR(A.ORG_NUM, 1, 2) IN ('10', '11', '08') THEN
                   SUBSTR(A.ORG_NUM, 1, 2) || '0000'
                  ELSE
                   SUBSTR(A.ORG_NUM, 1, 4) || '00'
                END, --机构号
                CUST_ID, --客户号
                CUST_NAM,
                CUST_ID_RE; --客户名称

    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 7;
    V_STEP_DESC := '提取前一百名客户信息';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_TOP_G23 
      (DATA_DATE, --数据日期
       SEQ_NO, --序号
       ORG_NUM, --机构号
       CUST_ID, --客户号
       CUST_NAM, --客户名称
       ACCT_BAL, --存款余额
       ACCT_BAL_RMB, --存款余额_人民币
       FIXED_ACCT_BAL, --其中：定期存款余额
       FIXED_ACCT_BAL_RMB --其中：定期存款余额_人民币
       )
      SELECT 
       I_DATADATE, --数据日期
       SEQ_NO, --序号
       ORG_NUM, --机构号
       CUST_ID, --客户号
       CUST_NAM, --客户名称
       ACCT_BAL, --存款余额
       ACCT_BAL_RMB, --存款余额_人民币
       FIXED_ACCT_BAL, --其中：定期存款余额
       FIXED_ACCT_BAL_RMB --其中：定期存款余额_人民币
        FROM (SELECT A.*,
                     ROW_NUMBER() OVER(PARTITION BY ORG_NUM /*A.ORG_NUM*/ ORDER BY A.ACCT_BAL_RMB DESC, A.CUST_ID) AS SEQ_NO --changed by liruiting
                FROM (SELECT A.ORG_NUM, --机构号
                             -- B.UP_ORG_NUM ORG_NUM, --机构号
                             MAX(A.CUST_ID) CUST_ID, --客户号
                             A.CUST_NAM, --客户名称
                             SUM(A.ACCT_BAL) ACCT_BAL, --存款余额
                             SUM(A.ACCT_BAL_RMB) ACCT_BAL_RMB, --存款余额_人民币
                             SUM(A.FIXED_ACCT_BAL) FIXED_ACCT_BAL, --其中：定期存款余额
                             SUM(A.FIXED_ACCT_BAL_RMB) FIXED_ACCT_BAL_RMB --其中：定期存款余额_人民币
                        FROM CBRC_TOP_G23_TMP2_UPS A
                      --     INNER JOIN L_PUBL_ORG_BRA B ON A.ORG_NUM = B.ORG_NUM
                       INNER JOIN SMTMODS_L_CUST_C C
                          ON A.CUST_ID_RE = C.CUST_ID
                         AND C.DATA_DATE = I_DATADATE
                       GROUP BY /*B.UP_ORG_NUM,*/ A.ORG_NUM, A.CUST_NAM
                      UNION ALL
                      SELECT 
                       A.ORG_NUM,
                       --  B.UP_ORG_NUM ORG_NUM, --机构号
                       A.CUST_ID CUST_ID, --客户号
                       A.CUST_NAM, --客户名称
                       A.ACCT_BAL, --存款余额
                       A.ACCT_BAL_RMB, --存款余额_人民币
                       A.FIXED_ACCT_BAL, --其中：定期存款余额
                       A.FIXED_ACCT_BAL_RMB --其中：定期存款余额_人民币
                        FROM CBRC_TOP_G23_TMP2_UPS A
                      --   INNER JOIN L_PUBL_ORG_BRA B ON A.ORG_NUM = B.ORG_NUM
                       INNER JOIN (select A.cust_id, A.DATA_DATE
                                    FROM SMTMODS_L_CUST_P A
                                    left join SMTMODS_L_CUST_C B
                                      ON A.CUST_ID = B.CUST_ID
                                     AND A.DATA_DATE = B.DATA_DATE
                                   WHERE A.DATA_DATE = I_DATADATE
                                     AND B.CUST_ID IS NULL) P
                          ON A.CUST_ID_RE = P.CUST_ID
                         AND P.DATA_DATE = I_DATADATE) A) --changed by liruiting
       WHERE SEQ_NO <= 100;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 8;
    V_STEP_DESC := '提取数据';
    V_STEP_FLAG := 0;
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
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
    --客户名称
      SELECT T.DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G23' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G23_5_3'
               WHEN T.SEQ_NO = '2' THEN
                'G23_6_3'
               WHEN T.SEQ_NO = '3' THEN
                'G23_7_3'
               WHEN T.SEQ_NO = '4' THEN
                'G23_8_3'
               WHEN T.SEQ_NO = '5' THEN
                'G23_9_3'
               WHEN T.SEQ_NO = '6' THEN
                'G23_10_3'
               WHEN T.SEQ_NO = '7' THEN
                'G23_11_3'
               WHEN T.SEQ_NO = '8' THEN
                'G23_12_3'
               WHEN T.SEQ_NO = '9' THEN
                'G23_13_3'
               WHEN T.SEQ_NO = '10' THEN
                'G23_14_3'
             END AS ITEM_NUM,
             0 AS ITEM_VAL,
             trim(T.CUST_NAM) AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_TOP_G23 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.SEQ_NO <= 10;
    commit;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
    --客户号
      SELECT T.DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G23' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G23_5_4'
               WHEN T.SEQ_NO = '2' THEN
                'G23_6_4'
               WHEN T.SEQ_NO = '3' THEN
                'G23_7_4'
               WHEN T.SEQ_NO = '4' THEN
                'G23_8_4'
               WHEN T.SEQ_NO = '5' THEN
                'G23_9_4'
               WHEN T.SEQ_NO = '6' THEN
                'G23_10_4'
               WHEN T.SEQ_NO = '7' THEN
                'G23_11_4'
               WHEN T.SEQ_NO = '8' THEN
                'G23_12_4'
               WHEN T.SEQ_NO = '9' THEN
                'G23_13_4'
               WHEN T.SEQ_NO = '10' THEN
                'G23_14_4'
             END AS ITEM_NUM,
             0 AS ITEM_VAL,
             T.CUST_ID AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_TOP_G23 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.SEQ_NO <= 10;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
    --存款余额_人民币
      SELECT T.DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G23' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G23_5_5'
               WHEN T.SEQ_NO = '2' THEN
                'G23_6_5'
               WHEN T.SEQ_NO = '3' THEN
                'G23_7_5'
               WHEN T.SEQ_NO = '4' THEN
                'G23_8_5'
               WHEN T.SEQ_NO = '5' THEN
                'G23_9_5'
               WHEN T.SEQ_NO = '6' THEN
                'G23_10_5'
               WHEN T.SEQ_NO = '7' THEN
                'G23_11_5'
               WHEN T.SEQ_NO = '8' THEN
                'G23_12_5'
               WHEN T.SEQ_NO = '9' THEN
                'G23_13_5'
               WHEN T.SEQ_NO = '10' THEN
                'G23_14_5'
             END AS ITEM_NUM,
             NVL(T.ACCT_BAL_RMB, 0) AS ITEM_VAL,
             NULL AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_TOP_G23 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.SEQ_NO <= 10;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
    --其中：定期存款余额_人民币
      SELECT T.DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G23' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G23_5_6'
               WHEN T.SEQ_NO = '2' THEN
                'G23_6_6'
               WHEN T.SEQ_NO = '3' THEN
                'G23_7_6'
               WHEN T.SEQ_NO = '4' THEN
                'G23_8_6'
               WHEN T.SEQ_NO = '5' THEN
                'G23_9_6'
               WHEN T.SEQ_NO = '6' THEN
                'G23_10_6'
               WHEN T.SEQ_NO = '7' THEN
                'G23_11_6'
               WHEN T.SEQ_NO = '8' THEN
                'G23_12_6'
               WHEN T.SEQ_NO = '9' THEN
                'G23_13_6'
               WHEN T.SEQ_NO = '10' THEN
                'G23_14_6'
             END AS ITEM_NUM,
             NVL(T.FIXED_ACCT_BAL_RMB, 0) AS ITEM_VAL,
             NULL AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_TOP_G23 T
        WHERE T.DATA_DATE = I_DATADATE
         AND T.SEQ_NO <= 10;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 9;
    V_STEP_DESC := '提取数据220700-松原分行市辖区，220701-松原分行前郭县机构汇总临时表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --add by djh 20230103 新增220700-松原分行市辖区，220701-松原分行前郭县机构汇总处理逻辑  20240703  220600 白山分行市辖
  INSERT INTO CBRC_TOP_G23_SY_SUM
    (DATA_DATE,
     SEQ_NO,
     ORG_NUM,
     CUST_ID,
     CUST_NAM,
     ACCT_BAL_RMB,
     FIXED_ACCT_BAL_RMB)
    SELECT K.DATA_DATE,
           ROW_NUMBER() OVER(PARTITION BY K.PARENT_INST_ID ORDER BY K.ACCT_BAL_RMB DESC, K.CUST_ID) AS SEQ_NO,
           K.PARENT_INST_ID,
           K.CUST_ID,
           K.CUST_NAM,
           K.ACCT_BAL_RMB,
           K.FIXED_ACCT_BAL_RMB
      FROM (SELECT T.CUST_ID,
                   T.CUST_NAM,
                   T1.PARENT_INST_ID,
                   T.DATA_DATE,
                   SUM(T.ACCT_BAL_RMB) ACCT_BAL_RMB,
                   SUM(T.FIXED_ACCT_BAL_RMB) FIXED_ACCT_BAL_RMB
              FROM CBRC_TOP_G23 T
             INNER JOIN (SELECT INST_ID, T.PARENT_INST_ID
                          FROM /*UPRR.U_BASE_INST@SMTM1104*/  cbrc_uprr_u_base_inst T
                         WHERE T.PARENT_INST_ID IN ('220701', '220700','220600','222400','220400','040189','040689','220300') ) T1
                ON T.ORG_NUM = T1.INST_ID
             WHERE T.DATA_DATE = I_DATADATE
             GROUP BY T.CUST_ID, T.CUST_NAM, T1.PARENT_INST_ID, T.DATA_DATE) K;
    COMMIT;
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 10;
    V_STEP_DESC := '提取数据至CBRC_A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
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
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
    --客户名称
      SELECT T.DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G23' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G23_5_3'
               WHEN T.SEQ_NO = '2' THEN
                'G23_6_3'
               WHEN T.SEQ_NO = '3' THEN
                'G23_7_3'
               WHEN T.SEQ_NO = '4' THEN
                'G23_8_3'
               WHEN T.SEQ_NO = '5' THEN
                'G23_9_3'
               WHEN T.SEQ_NO = '6' THEN
                'G23_10_3'
               WHEN T.SEQ_NO = '7' THEN
                'G23_11_3'
               WHEN T.SEQ_NO = '8' THEN
                'G23_12_3'
               WHEN T.SEQ_NO = '9' THEN
                'G23_13_3'
               WHEN T.SEQ_NO = '10' THEN
                'G23_14_3'
             END AS ITEM_NUM,
             0 AS ITEM_VAL,
             trim(T.CUST_NAM) AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_TOP_G23_SY_SUM T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.SEQ_NO <= 10;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
    --客户号
      SELECT T.DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G23' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G23_5_4'
               WHEN T.SEQ_NO = '2' THEN
                'G23_6_4'
               WHEN T.SEQ_NO = '3' THEN
                'G23_7_4'
               WHEN T.SEQ_NO = '4' THEN
                'G23_8_4'
               WHEN T.SEQ_NO = '5' THEN
                'G23_9_4'
               WHEN T.SEQ_NO = '6' THEN
                'G23_10_4'
               WHEN T.SEQ_NO = '7' THEN
                'G23_11_4'
               WHEN T.SEQ_NO = '8' THEN
                'G23_12_4'
               WHEN T.SEQ_NO = '9' THEN
                'G23_13_4'
               WHEN T.SEQ_NO = '10' THEN
                'G23_14_4'
             END AS ITEM_NUM,
             0 AS ITEM_VAL,
             T.CUST_ID AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_TOP_G23_SY_SUM T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.SEQ_NO <= 10;

    COMMIT;
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
    --存款余额_人民币
      SELECT T.DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G23' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G23_5_5'
               WHEN T.SEQ_NO = '2' THEN
                'G23_6_5'
               WHEN T.SEQ_NO = '3' THEN
                'G23_7_5'
               WHEN T.SEQ_NO = '4' THEN
                'G23_8_5'
               WHEN T.SEQ_NO = '5' THEN
                'G23_9_5'
               WHEN T.SEQ_NO = '6' THEN
                'G23_10_5'
               WHEN T.SEQ_NO = '7' THEN
                'G23_11_5'
               WHEN T.SEQ_NO = '8' THEN
                'G23_12_5'
               WHEN T.SEQ_NO = '9' THEN
                'G23_13_5'
               WHEN T.SEQ_NO = '10' THEN
                'G23_14_5'
             END AS ITEM_NUM,
             NVL(T.ACCT_BAL_RMB, 0) AS ITEM_VAL,
             NULL AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_TOP_G23_SY_SUM T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.SEQ_NO <= 10;
    COMMIT;
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
    --其中：定期存款余额_人民币
      SELECT T.DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G23' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G23_5_6'
               WHEN T.SEQ_NO = '2' THEN
                'G23_6_6'
               WHEN T.SEQ_NO = '3' THEN
                'G23_7_6'
               WHEN T.SEQ_NO = '4' THEN
                'G23_8_6'
               WHEN T.SEQ_NO = '5' THEN
                'G23_9_6'
               WHEN T.SEQ_NO = '6' THEN
                'G23_10_6'
               WHEN T.SEQ_NO = '7' THEN
                'G23_11_6'
               WHEN T.SEQ_NO = '8' THEN
                'G23_12_6'
               WHEN T.SEQ_NO = '9' THEN
                'G23_13_6'
               WHEN T.SEQ_NO = '10' THEN
                'G23_14_6'
             END AS ITEM_NUM,
             NVL(T.FIXED_ACCT_BAL_RMB, 0) AS ITEM_VAL,
             NULL AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_TOP_G23_SY_SUM T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.SEQ_NO <= 10;
    COMMIT;

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
         AND REP_NUM = 'G23';

      COMMIT;
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
   
END proc_cbrc_idx2_g23