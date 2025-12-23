CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_s68 (II_DATADATE  IN STRING  --跑批日期
                                                     )

  /******************************
  @author:sy
  @create-date:2015-09-19
  @description:G0102
  @modification history:
  m0.shiyu 20230411 新增银行承兑汇票及信用证逻辑
  m1.wty   20241105 修改内容：增加S68借据维度明细数据逻辑，再将明细数据汇总到CBRC_A_REPT_ITEM_VAL。
  -- 需求编号：JLBA202503060004 上线日期：2025-06-19，修改人：王天雨，提出人：金丹 修改原因：修改提取明细数据逻辑，增加一张明细表。明细项增加合同编号，客户名称，机构名称。

目标表：CBRC_A_REPT_ITEM_VAL 
临时表：CBRC_A_REPT_DWD_S68
     CBRC_S68_GREE_INDEX_TMP_1
     CBRC_S68_LOAN_TEMP
     CBRC_S68_LOAN_TEMP_HIS
码值表：CBRC_GREE_LOAN_INDEX
依赖表：CBRC_UPRR_U_BASE_INST
SMTMODS_L_ACCT_LOAN
SMTMODS_L_CUST_ALL
SMTMODS_L_PUBL_RATE
CBRC_REPORT_INDEX_FIELD_VAL
CBRC_REPORT_INDEX_INFO_VAL

  
  *******************************/

 IS
  V_SCHEMA    VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE VARCHAR(30); --当前储存过程名称
  V_PROCNAME  VARCHAR(30); --当前储存过程名称
  V_TAB_NAME  VARCHAR(30); --目标表名
  I_DATADATE  STRING; --数据日期(数值型)YYYYMMDD
  V_STEP_ID   INTEGER; --任务号
  V_ERRORCODE VARCHAR(20); --错误编码
  V_ERRORDESC VARCHAR(300);
  V_STEP_DESC VARCHAR(300); --任务描述
  NUM         INTEGER;
  NEXTDATE    VARCHAR2(10);
  V_STEP_FLAG INTEGER; --任务执行状态标识
  II_STATUS   INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM    VARCHAR2(30);

BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';
    I_DATADATE  := II_DATADATE;
    V_SYSTEM    := 'CBRC';
    V_PROCNAME  := UPPER('PROC_CBRC_IDX2_S68');
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_TAB_NAME  := 'CBRC_A_REPT_ITEM_VAL';
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || 'S68当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    NEXTDATE := TO_CHAR(DATE(I_DATADATE) + 1, 'YYYYMMDD');

    --删除临时表

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S68_GREE_INDEX_TMP_1';
    COMMIT;
    /*DELETE FROM CBRC_REPORT_INDEX_INFO_VAL
     WHERE DDATE = I_DATADATE
       AND REPORT_ID = 'S68';
    COMMIT;

    DELETE FROM CBRC_REPORT_INDEX_FIELD_VAL -- [2025-06-19] [王天雨] [JLBA202503060004] [金丹]清除当期数据。
     WHERE DATA_DATE = I_DATADATE
       AND REPORT_ID = 'S68';
    COMMIT;
*/
--begin 明细需求 bohe20250814



    --清除当前分区表的数据
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_A_REPT_DWD_S68 ';

--end 明细需求 bohe20250814

    --删除目标表S68数据
    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'S68'
       --AND T.FLAG = '2'
       ;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '清理S68当期数据完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -------------------------------------------------------绿色信贷余额-------------------------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生S68指标数据绿色信贷余额，插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_S68_GREE_INDEX_TMP_1
      (DBANK_ID, -- 机构号
       DDATE, -- 数据日期
       REPORT_ID, -- 报表编号
       ROW_NUM, -- 行号
       COL_NUM, -- 列号
       INDEX_ID, -- 指标号
       VAL -- 指标值
       )
      SELECT A.ORG_NUM, -- 机构号
             A.DATA_DATE, -- 数据日期
             'S68',
             ROW_NUMBER() OVER(PARTITION BY A.DATA_DATE, A.ORG_NUM, C.PRIM1, C.GREE_LOAN ORDER BY A.LOAN_ACCT_BAL) ROW_NUM,
             '',
             C.PRIM1 AS ITEM_NUM, -- 指标号
             -- LOAN_ACCT_BAL || ',' || LOAN_NUM || ',' || GREEN_LOAN_TYPE AS VAL -- 指标值
             LOAN_NUM AS VAL -- 指标值          -- [2025-06-19] [王天雨] [JLBA202503060004] [金丹] 指标值修改为存储借据号作为关联明细表的主键。
        FROM SMTMODS_L_ACCT_LOAN A -- 借据表
       INNER JOIN CBRC_GREE_LOAN_INDEX C -- 绿色贷款指标表
          ON A.GREEN_CREDIT_USAGE /*GREEN_LOAN_TYPE*/
             = C.GREE_LOAN
       WHERE A.DATA_DATE = II_DATADATE
         and a.cancel_flg = 'N' --剔除核销
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.GREEN_CREDIT_FLAG = '1' --是否绿色信贷(2024版)
      ;

    COMMIT;

    ----------------------------------------贷款余额指标-------------------------------------------------------


--begin 明细需求 bohe20250814

    INSERT INTO CBRC_A_REPT_DWD_S68
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_1, --机构名
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       COL_5, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同编号
       COL_7, --放款日期
       COL_8 --原始到期日
       )
      SELECT I_DATADATE AS DATA_DATE, -- 数据日期
             A.ORG_NUM AS ORG_NUM, -- 机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S68' AS REP_NUM, --报表编号
             C.PRIM1 AS ITEM_NUM, -- 指标号
             NULL AS COL_1, --机构名
             A.CUST_ID AS COL_2, --客户号
             T.CUST_NAM AS COL_3, --客户名
             A.LOAN_NUM AS COL_4, --贷款编号
             A.LOAN_ACCT_BAL * U.CCY_RATE AS COL5, --贷款余额/贷款金额/客户数/贷款收益
             A.ACCT_NUM AS COL_6, --贷款合同编号
             A.DRAWDOWN_DT AS COL_7, --放款日期
             A.MATURITY_DT AS COL_8 --原始到期日
        FROM SMTMODS_L_ACCT_LOAN A -- 借据表
       INNER JOIN CBRC_GREE_LOAN_INDEX C -- 绿色贷款指标表
          ON A.GREEN_CREDIT_USAGE = C.GREE_LOAN
       LEFT JOIN SMTMODS_L_CUST_ALL T --对公客户信息表
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
       
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.DATA_DATE = I_DATADATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         and a.cancel_flg = 'N' --剔除核销
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.GREEN_CREDIT_FLAG = '1' --是否绿色信贷(2024版)
       ;
    COMMIT;

--end 明细需求 bohe20250814

    -------------------------------------贷款户数----------------------------------------------


--begin 明细需求 bohe20250814

    INSERT INTO CBRC_A_REPT_DWD_S68
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_1, --机构名
       COL_2, --客户号
       COL_3, --客户名
       COL_5 --贷款余额/贷款金额/客户数/贷款收益

       )
       SELECT I_DATADATE AS DATA_DATE, -- 数据日期
             TT.ORG_NUM AS ORG_NUM, -- 机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S68' AS REP_NUM, --报表编号
             TT.PRIM2 AS ITEM_NUM, -- 指标号
             NULL AS COL_1, --机构名
             TT.CUST_ID AS COL_2, --客户号
             TT.CUST_NAM AS COL_3, --客户名
             '1' AS COL_5 --贷款余额/贷款金额/客户数/贷款收益

             FROM (SELECT A.ORG_NUM,A.CUST_ID,T.CUST_NAM, C.PRIM2
        FROM SMTMODS_L_ACCT_LOAN A -- 借据表
       INNER JOIN CBRC_GREE_LOAN_INDEX C -- 绿色贷款指标表
          ON A.GREEN_CREDIT_USAGE = C.GREE_LOAN
       LEFT JOIN SMTMODS_L_CUST_ALL T --对公客户信息表
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
       WHERE A.DATA_DATE =I_DATADATE
         and a.cancel_flg = 'N' --剔除核销
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.GREEN_CREDIT_FLAG = '1' --是否绿色信贷(2024版)
         GROUP BY  A.ORG_NUM,A.CUST_ID,T.CUST_NAM, C.PRIM2 ) TT

       ;
    COMMIT;

--end 明细需求 bohe20250814

    -------------------------------不良贷款 -------------------------------------------



--begin 明细需求 bohe20250814
    INSERT INTO CBRC_A_REPT_DWD_S68
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_1, --机构名
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       COL_5, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同编号
       COL_7, --放款日期
       COL_8 --原始到期日
       )
      SELECT I_DATADATE AS DATA_DATE, -- 数据日期
             A.ORG_NUM AS ORG_NUM, -- 机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S68' AS REP_NUM, --报表编号
             C.PRIM3 AS ITEM_NUM, -- 指标号
             NULL AS COL_1, --机构名
             A.CUST_ID AS COL_2, --客户号
             T.CUST_NAM AS COL_3, --客户名
             A.LOAN_NUM AS COL_4, --贷款编号
             A.LOAN_ACCT_BAL * U.CCY_RATE AS COL_5, --贷款余额/贷款金额/客户数/贷款收益
             A.ACCT_NUM AS COL_6, --贷款合同编号
             A.DRAWDOWN_DT AS COL_7, --放款日期
             A.MATURITY_DT AS COL_8 --原始到期日
        FROM SMTMODS_L_ACCT_LOAN A -- 借据表
       INNER JOIN CBRC_GREE_LOAN_INDEX C -- 绿色贷款指标表
          ON A.GREEN_CREDIT_USAGE = C.GREE_LOAN
       LEFT JOIN SMTMODS_L_CUST_ALL T --对公客户信息表
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.DATA_DATE = I_DATADATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         and a.cancel_flg = 'N' --剔除核销
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.GREEN_CREDIT_FLAG = '1' --是否绿色信贷(2024版)
         AND A.LOAN_GRADE_CD  IN ('3','4','5') --不良贷款
       ;
    COMMIT;
--end 明细需求 bohe20250814



     --累放数据处理

    --年初删除本年累计:



    IF SUBSTR(I_DATADATE, 5, 2) = 01 THEN
      EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S68_LOAN_TEMP';
    ELSE
  
      DELETE FROM CBRC_S68_LOAN_TEMP T WHERE  SUBSTR(T.DATA_DATE,1,6) =SUBSTR(I_DATADATE,1,6);
      COMMIT;

    END IF;

    COMMIT;

    insert into CBRC_S68_LOAN_TEMP
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
       GREEN_CREDIT_USAGE)
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
       A.GREEN_CREDIT_USAGE  --绿色信贷(2024版) 分类
        FROM SMTMODS_L_ACCT_LOAN A --借据信息
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_ALL C --客户表
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and a.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
         AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组 SHIYU 20220210  新口径吴大为
         AND A.GREEN_CREDIT_FLAG ='1'  --是否绿色信贷(2024版)
         AND (SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) = ---取当月
             SUBSTR(I_DATADATE, 1, 6) OR
             (A.INTERNET_LOAN_FLG = 'Y' AND
             A.DRAWDOWN_DT =
             (TRUNC(DATE(I_DATADATE), 'MM') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，上月末数据当月取
             );
    COMMIT;

    --累放备份历史数据
    DELETE FROM CBRC_S68_LOAN_TEMP_HIS
     WHERE SUBSTR(DATA_DATE, 1, 6) = SUBSTR(I_DATADATE, 1, 6);
    COMMIT;

    INSERT INTO CBRC_S68_LOAN_TEMP_HIS
      SELECT DATA_DATE,
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
             GREEN_CREDIT_USAGE
        FROM CBRC_S68_LOAN_TEMP
       WHERE DATA_DATE = I_DATADATE;
    COMMIT;

    -------------------------------------当年累放贷款额  -----------------------------------------


--begin 明细需求 bohe20250814
    INSERT INTO CBRC_A_REPT_DWD_S68
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_1, --机构名
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       COL_5, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同编号
       COL_7, --放款日期
       COL_8 --原始到期日
       )
      SELECT I_DATADATE AS DATA_DATE, -- 数据日期
             T.ORG_NUM AS ORG_NUM, -- 机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S68' AS REP_NUM, --报表编号
             C.PRIM4 AS ITEM_NUM, -- 指标号
             NULL AS COL_1, --机构名
             T.CUST_ID AS COL_2, --客户号
             T.CUST_NAM AS COL_3, --客户名
             T.LOAN_NUM AS COL_4, --贷款编号
             T.LOAN_ACCT_AMT * U.CCY_RATE AS COL_5, --贷款余额/贷款金额/客户数/贷款收益
             A.ACCT_NUM AS COL_6, --贷款合同编号
             T.DRAWDOWN_DT AS COL_7, --放款日期
             T.MATURITY_DT AS COL_8 --原始到期日
        FROM CBRC_S68_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN CBRC_GREE_LOAN_INDEX C -- 绿色贷款指标表
          ON T.GREEN_CREDIT_USAGE = C.GREE_LOAN
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.DATA_DATE = I_DATADATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       ;
    COMMIT;
--end 明细需求 bohe20250814

     -------------------------------------当年累放贷款年化利息收益-------------------------------


--begin 明细需求 bohe20250814
    INSERT INTO CBRC_A_REPT_DWD_S68
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_1, --机构名
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       COL_5, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同编号
       COL_7, --放款日期
       COL_8 --原始到期日
       )
      SELECT I_DATADATE AS DATA_DATE, -- 数据日期
             T.ORG_NUM AS ORG_NUM, -- 机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S68' AS REP_NUM, --报表编号
             C.PRIM5 AS ITEM_NUM, -- 指标号
            NULL AS COL_1, --机构名
             T.CUST_ID AS COL_2, --客户号
             T.CUST_NAM AS COL_3, --客户名
             T.LOAN_NUM AS COL_4, --贷款编号
             T.NHSY * U.CCY_RATE AS COL_5, --贷款余额/贷款金额/客户数/贷款收益
             A.ACCT_NUM AS COL_6, --贷款合同编号
             T.DRAWDOWN_DT AS COL_7, --放款日期
             T.MATURITY_DT AS COL_8 --原始到期日
        FROM CBRC_S68_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
          AND A.DATA_DATE = I_DATADATE
       INNER JOIN CBRC_GREE_LOAN_INDEX C -- 绿色贷款指标表
          ON T.GREEN_CREDIT_USAGE = C.GREE_LOAN
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.DATA_DATE = I_DATADATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
      ;
    COMMIT;
--end 明细需求 bohe20250814

   

    ---------------------------------------------------- S68数据插至目标指标表----------------------------------------------------
  

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
             SUM(COL_5) AS ITEM_VAL, --指标值
             '2' AS FLAG --标志位
        FROM CBRC_A_REPT_DWD_S68 WHERE DATA_DATE = I_DATADATE
       GROUP BY DATA_DATE,ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM;
    COMMIT;
--end 明细需求 bohe20250814

    V_STEP_FLAG := 1;
    V_STEP_DESC := V_PROCNAME || '的业务逻辑全部处理完成';
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
   
END proc_cbrc_idx2_s68