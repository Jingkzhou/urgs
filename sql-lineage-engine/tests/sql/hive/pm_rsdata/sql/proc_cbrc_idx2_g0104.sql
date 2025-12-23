CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g0104(II_DATADATE IN STRING --跑批日期
                                              )
/******************************
  @author:fanxiaoyu
  @create-date:2015-09-20
  @description:G0104
  @modification history:原逻辑存款取期限划分，备份至SP_CBRC_IDX2_G0104_BAK,新逻辑存款只有220按期限分
  m0.20150919-fanxiaoyu-G0104
  M1.20221108 程序优化，三个月至六个月-五年以上 各项存款 可以通过一个程序实现
  m3 alter by 2014科目取贷方-借方
  m4 20250327 alter by shiyu 修改内容：2.B活期储蓄存款 --剔除视图中的个人保证金部分
  m5 20250327 alter by shiyu 修改内容：于佳禾提出定活两便科目放在三个月以内科目里20110102
  -- 需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求
              上线日期：2025-05-27，修改人：巴启威，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
 --[JLBA202507210012_关于调整财政性存款及一般性存款相关科目统计方式的相关需求][提出人：于佳禾][上线时间：20250918][修改人：石雨][修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]


目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_A_REPT_DWD_G0104
视图表:SMTMODS_V_PUB_IDX_FINA_GL    --总账科目表
     SMTMODS_V_PUB_IDX_CK_GTGSHHQ --个体工商户活期存款
     SMTMODS_V_PUB_IDX_CK_GTGSHDQ --个体工商户定期存款
     SMTMODS_V_PUB_IDX_CK_GTGSHTZ --个体工商户通知存款
     SMTMODS_V_PUB_IDX_DK_YSDQRJJ --原始到期日借据表 
集市表:SMTMODS_L_ACCT_LOAN          --贷款借据信息表
     SMTMODS_L_PUBL_RATE          --汇率表
     SMTMODS_L_FINA_GL            --总账科目表
     SMTMODS_L_ACCT_DEPOSIT       --存款账户信息表
     SMTMODS_L_CUST_C             --对公客户补充信息表
  *******************************/ 
 IS
  V_SCHEMA    VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE VARCHAR(30); --当前储存过程名称
  V_REP_NUM   VARCHAR(30); --报表名称
  I_DATADATE  INTEGER; --数据日期(数值型)YYYYMMDD
  V_DATADATE  VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  V_STEP_ID   INTEGER; --任务号
  V_STEP_DESC VARCHAR(300); --任务描述
  V_STEP_FLAG INTEGER; --任务执行状态标识
  V_ERRORCODE VARCHAR(20); --错误编码
  V_ERRORDESC VARCHAR(280); --错误内容
  II_STATUS    INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM    VARCHAR(280)
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_DESC := '参数初始化处理';
    I_DATADATE  := II_DATADATE;
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G0104');
    V_REP_NUM  := 'G01_4';
    V_SYSTEM := 'CBRC';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_REP_NUM || ']表历史数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND REP_NUM = V_REP_NUM
       AND FLAG = '2';
    COMMIT;
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_A_REPT_DWD_G0104';
    COMMIT;
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := 'G0104 1.本金逾期 各项贷款 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --=====================================
    --   G0104 1.本金逾期
    --=====================================
      INSERT INTO CBRC_A_REPT_DWD_G0104
    (DATA_DATE, -- 数据日期
     ORG_NUM, -- 机构号
     DATA_DEPARTMENT, -- 数据条线
     SYS_NAM, -- 模块简称
     REP_NUM, -- 报表编号
     ITEM_NUM, -- 指标号
     TOTAL_VALUE, -- 汇总值
     COL_1, -- 字段1(合同号)
     COL_2, -- 字段2(借据号)
     COL_3, -- 字段3(客户号)
     COL_4, -- 字段4(放款金额)
     COL_5, -- 字段5(放款日期)
     COL_6, -- 字段6(原始到期日期)
     COL_7, -- 字段7(科目号)
     COL_8, -- 字段8(币种)
     COL_9  -- 字段9(账户类型)
     )
    SELECT 
     I_DATADATE AS DATA_DATE, -- 数据日期
     A.ORG_NUM AS ORG_NUM, --机构号
     A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
     'CBRC' AS SYS_NAM, -- 模块简称
     'G01_4' AS REP_NUM, -- 报表编号
     'G01_4_1..C' AS ITEM_NUM, -- 指标号
     NVL(A.OD_LOAN_ACCT_BAL * B.CCY_RATE, 0)  AS TOTAL_VALUE, -- 汇总值
     A.ACCT_NUM AS COL_1, -- 合同号
     A.LOAN_NUM AS COL_2, -- 借据号
     A.CUST_ID AS COL_3, -- 客户号
     A.DRAWDOWN_AMT AS COL_4, -- 放款金额
     A.DRAWDOWN_DT AS COL_5, -- 放款日期
     A.MATURITY_DT AS COL_6, -- 原始到期日期
     A.ITEM_CD AS COL_7, -- 科目号
     A.CURR_CD AS COL_8, -- 币种
     A.ACCT_TYP AS COL_9 -- 账户类型
   FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.OD_LOAN_ACCT_BAL > 0
         AND A.OD_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND (ACCT_TYP not in ('E01', 'E02') OR ORG_NUM <> '009803')
         and acct_typ not like '09%'
         AND acct_typ not like '90%'
         AND A.CANCEL_FLG <> 'Y'
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       ;

    COMMIT;

  INSERT INTO CBRC_A_REPT_DWD_G0104
    (DATA_DATE, -- 数据日期
     ORG_NUM, -- 机构号
     DATA_DEPARTMENT, -- 数据条线
     SYS_NAM, -- 模块简称
     REP_NUM, -- 报表编号
     ITEM_NUM, -- 指标号
     TOTAL_VALUE, -- 汇总值
     COL_1, -- 字段1(合同号)
     COL_2, -- 字段2(借据号)
     COL_3, -- 字段3(客户号)
     COL_4, -- 字段4(放款金额)
     COL_5, -- 字段5(放款日期)
     COL_6, -- 字段6(原始到期日期)
     COL_7, -- 字段7(科目号)
     COL_8, -- 字段8(币种)
     COL_9  -- 字段9(账户类型)
     )
    SELECT 
     I_DATADATE AS DATA_DATE, -- 数据日期
     A.ORG_NUM AS ORG_NUM, --机构号
     A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
     'CBRC' AS SYS_NAM, -- 模块简称
     'G01_4' AS REP_NUM, -- 报表编号
     'G01_4_1..C' AS ITEM_NUM, -- 指标号
     NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0)  AS TOTAL_VALUE, -- 汇总值
     A.ACCT_NUM AS COL_1, -- 合同号
     A.LOAN_NUM AS COL_2, -- 借据号
     A.CUST_ID AS COL_3, -- 客户号
     A.DRAWDOWN_AMT AS COL_4, -- 放款金额
     A.DRAWDOWN_DT AS COL_5, -- 放款日期
     A.MATURITY_DT AS COL_6, -- 原始到期日期
     A.ITEM_CD AS COL_7, -- 科目号
     A.CURR_CD AS COL_8, -- 币种
     A.ACCT_TYP AS COL_9 -- 账户类型
   FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE OD_LOAN_ACCT_BAL > 0
         AND A.DATA_DATE = I_DATADATE
         AND acct_typ like '09%'
            -- and A.DATE_SOURCESD NOT IN ('10301057','10301059')       20211014 ZHOUJINGKUN   新信贷系统改造
         AND A.CANCEL_FLG <> 'Y'
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
  
    COMMIT;
    
   

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
    --liud mf at 20180726 取12203科目数据
      SELECT 
       I_DATADATE AS DATA_DATE,
       '009803' AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       V_REP_NUM AS REP_NUM,
       'G01_4_1..C' AS ITEM_NUM,
       SUM(A.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL,
       '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '130303'
         and A.ORG_NUM = '009803'
       GROUP BY ORG_NUM;
    COMMIT;

  INSERT INTO CBRC_A_REPT_DWD_G0104
    (DATA_DATE, -- 数据日期
     ORG_NUM, -- 机构号
     DATA_DEPARTMENT, -- 数据条线
     SYS_NAM, -- 模块简称
     REP_NUM, -- 报表编号
     ITEM_NUM, -- 指标号
     TOTAL_VALUE, -- 汇总值
     COL_1, -- 字段1(合同号)
     COL_2, -- 字段2(借据号)
     COL_3, -- 字段3(客户号)
     COL_4, -- 字段4(放款金额)
     COL_5, -- 字段5(放款日期)
     COL_6, -- 字段6(原始到期日期)
     COL_7, -- 字段7(科目号)
     COL_8, -- 字段8(币种)
     COL_9 -- 字段9(账户类型)
     )
    SELECT 
     I_DATADATE AS DATA_DATE, -- 数据日期
     A.ORG_NUM AS ORG_NUM, --机构号
     A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
     'CBRC' AS SYS_NAM, -- 模块简称
     'G01_4' AS REP_NUM, -- 报表编号
     'G01_4_1..C' AS ITEM_NUM, -- 指标号
     NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
     A.ACCT_NUM AS COL_1, -- 合同号
     A.LOAN_NUM AS COL_2, -- 借据号
     A.CUST_ID AS COL_3, -- 客户号
     A.DRAWDOWN_AMT AS COL_4, -- 放款金额
     A.DRAWDOWN_DT AS COL_5, -- 放款日期
     A.MATURITY_DT AS COL_6, -- 原始到期日期
     A.ITEM_CD AS COL_7, -- 科目号
     A.CURR_CD AS COL_8, -- 币种
     A.ACCT_TYP AS COL_9 -- 账户类型
      FROM SMTMODS_L_ACCT_LOAN a
      LEFT JOIN SMTMODS_L_PUBL_RATE B
        ON A.DATA_DATE = B.DATA_DATE
       AND A.CURR_CD = B.BASIC_CCY
       AND B.FORWARD_CCY = 'CNY'
     WHERE a.od_flg = 'Y'
       AND A.DATA_DATE = I_DATADATE
       AND acct_typ like '03%'
       AND A.ITEM_CD NOT LIKE '130105%' --  转贴现不算逾期
          --     and A.DATE_SOURCESD NOT IN ('10301057','10301059')     20211014 ZHOUJINGKUN   新信贷系统改造
       AND A.CANCEL_FLG <> 'Y'
       AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
    ;


    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := 'G0104 1.本金逾期 各项贷款 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    
     V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '各项存款 活期 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --==================================================
    --   G0104   各项存款  活期
    --==================================================
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE,
       A.ORG_NUM,
       'CBRC' AS SYS_NAM,
       V_REP_NUM AS REP_NUM,
       'G01_4_2..A' AS ITEM_NUM,
       --SUM(A.CREDIT_BAL*B.CCY_RATE) AS SYS_NAM,
       --注释m3
       SUM(CASE
             WHEN A.ITEM_CD = '2014' THEN
              A.CREDIT_BAL - A.DEBIT_BAL
             ELSE
              A.CREDIT_BAL
           END * B.CCY_RATE) AS SYS_NAM,
       '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.CURR_CD = B.BASIC_CCY
         AND A.DATA_DATE = B.DATA_DATE
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('20110201',
                           '20110101',
                         /*  '20110102',*/
                           '20110111',
                           '20110206',
                           '2013',
                           '2014',
                           '20120106'
                           ,'22410101','20110301','20110302','20110303','22410102' --[JLBA202507210012][石雨][20250918][修改内容：224101久悬未取款、201103（财政性存款）调整为 一般单位活期存款]
                           ,'20080101','20090101' --[JLBA202507210012][石雨][20250918]
                           )
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := 'G0104 各项存款 活期 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '2.活期-三个月以内 各项存款 逻辑处理开始';
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
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       V_REP_NUM AS REP_NUM, --报表编号
       'G01_4_3..A' AS ITEM_NUM, --指标号
       SUM(ACCT_BAL_RMB) AS ITEM_VAL, --标志位
       '2' AS FLAG
        FROM (SELECT ORG_NUM, --CASE WHEN M.ORG_NUM NOT LIKE '__98%' THEN SUBSTR(M.ORG_NUM,1,4)||'00' else m.org_num end as org_num,
                     SUM(M.ACCT_BALANCE * N.CCY_RATE) AS ACCT_BAL_RMB
                FROM SMTMODS_L_ACCT_DEPOSIT M
                LEFT JOIN SMTMODS_L_PUBL_RATE N
                  ON M.DATA_DATE = N.DATA_DATE
                 AND M.CURR_CD = N.BASIC_CCY
                 AND N.FORWARD_CCY = 'CNY'
               WHERE M.DATA_DATE = I_DATADATE
                 AND (MONTHS_BETWEEN(DATE(M.MATUR_DATE), DATE(M.ST_INT_DT)) <= 3 OR
                     M.MATUR_DATE IS NULL)
                 AND (M.GL_ITEM_CODE LIKE '201107%' OR
                      M.GL_ITEM_CODE LIKE '201001%' OR -- 需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：巴启威，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
                     M.GL_ITEM_CODE IN
                     ('20110202', '20110203', '20110204', '20110211')
                     -- OR M.GL_ITEM_CODE LIKE '20503%'
                     OR M.GL_ITEM_CODE IN ('20110208', '20110113')
                     --OR M.GL_ITEM_CODE LIKE '20501%'    -- 20210219  add ljp  从明细取数
                     OR
                     M.GL_ITEM_CODE IN ('20110103',
                                         '20110104',
                                         '20110105',
                                         '20110106',
                                         '20110107',
                                         '20110108',
                                         '20110109')
                     --OR M.GL_ITEM_CODE LIKE '21501%'
                     --OR M.GL_ITEM_CODE LIKE '21505%'
                     OR M.GL_ITEM_CODE LIKE '20120204%')
               GROUP BY ORG_NUM
              -- CASE WHEN M.ORG_NUM NOT LIKE '__98%' THEN SUBSTR(M.ORG_NUM,1,4)||'00' else m.org_num end
              UNION ALL
              SELECT
               A.ORG_NUM, SUM(A.CREDIT_BAL * B.CCY_RATE) AS ACCT_BAL_RMB
                FROM SMTMODS_L_FINA_GL A
              --FROM SMTMODS_V_PUB_IDX_FINA_GL A -- 20221108 update by wangkui
                LEFT JOIN SMTMODS_L_PUBL_RATE B
                  ON A.CURR_CD = B.BASIC_CCY
                 AND A.DATA_DATE = B.DATA_DATE
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                    --按业务要求：202、203、251、21510放三个月以内；219取不到明细，不取数;205、215取拆分科目
                 AND A.ITEM_CD IN
                     ( --'20110109', /*'219',*/
                      '20110102',  --M5
                      '20110205',
                      '20110110',
                      '20110114',
                      '20110115',
                      '20110209',
                      '20110210' /*,'20501_01','20501_02','21501_01','21501_02','21505_01'*/) -- 20210219  modify ljp  从明细取数
               GROUP BY A.ORG_NUM)
       GROUP BY ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '2.活期-三个月以内 各项存款 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '三个月至六个月-五年以上 各项存款 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --==================================================
    --   G0104 4. 三个月至六个月  -- 9. 五年以上 各项存款
    --==================================================

    --alter by  shiyu 20221108 上面注释程序优化
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       V_REP_NUM AS REP_NUM, --报表编号
       CASE
         WHEN MONTHS_BETWEEN(date(M.MATUR_DATE), date(M.ST_INT_DT)) > 3 AND
              MONTHS_BETWEEN(date(M.MATUR_DATE), date(M.ST_INT_DT))<= 6 THEN
          'G01_4_4..A' -- 三个月至六个月
         WHEN MONTHS_BETWEEN(date(M.MATUR_DATE), date(M.ST_INT_DT)) > 6 and
              MONTHS_BETWEEN(date(M.MATUR_DATE), date(M.ST_INT_DT)) <= 12 THEN
          'G01_4_5..A' -- 六个月至一年
         WHEN MONTHS_BETWEEN(date(M.MATUR_DATE), date(M.ST_INT_DT)) > 12 and
              MONTHS_BETWEEN(date(M.MATUR_DATE), date(M.ST_INT_DT)) <= 24 THEN
          'G01_4_6..A' -- 一年至两年
         WHEN MONTHS_BETWEEN(date(M.MATUR_DATE), date(M.ST_INT_DT)) > 24 and
              MONTHS_BETWEEN(date(M.MATUR_DATE), date(M.ST_INT_DT)) <= 36 THEN
          'G01_4_7..A' -- 两年至三年
         WHEN MONTHS_BETWEEN(date(M.MATUR_DATE), date(M.ST_INT_DT)) > 36 and
              MONTHS_BETWEEN(date(M.MATUR_DATE), date(M.ST_INT_DT)) <= 60 THEN
          'G01_4_8..A' -- 三年至五年
         WHEN MONTHS_BETWEEN(date(M.MATUR_DATE), date(M.ST_INT_DT)) > 60 THEN
          'G01_4_9..A' -- 五年以上
       END AS ITEM_NUM, --指标号
       SUM(M.ACCT_BALANCE * N.CCY_RATE) AS ITEM_VAL, --标志位
       '2' AS FLAG
        FROM SMTMODS_L_ACCT_DEPOSIT M
        LEFT JOIN SMTMODS_L_PUBL_RATE N
          ON M.DATA_DATE = N.DATA_DATE
         AND M.CURR_CD = N.BASIC_CCY
         AND N.FORWARD_CCY = 'CNY'
       WHERE M.DATA_DATE = I_DATADATE
         AND (M.GL_ITEM_CODE LIKE '20110701%' OR
              M.GL_ITEM_CODE LIKE '20100101%' OR -- 需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：巴启威，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
             M.GL_ITEM_CODE IN
             ('20110202', '20110203', '20110204', '20110211') OR
             M.GL_ITEM_CODE IN ('20110208', '20110113') OR

             M.GL_ITEM_CODE IN ('20110103',
                                 '20110104',
                                 '20110105',
                                 '20110106',
                                 '20110107',
                                 '20110108',
                                 '20110109' -- 20221123 cancel by wangkui 因为3个月以内的总账已出这个数，本来应该从明细出此科目，为了和对标保持一致，改为从总账出
                                 ) OR M.GL_ITEM_CODE LIKE '20120204%')
       GROUP BY ORG_NUM,
                CASE
         WHEN MONTHS_BETWEEN(date(M.MATUR_DATE), date(M.ST_INT_DT)) > 3 AND
              MONTHS_BETWEEN(date(M.MATUR_DATE), date(M.ST_INT_DT))<= 6 THEN
          'G01_4_4..A' -- 三个月至六个月
         WHEN MONTHS_BETWEEN(date(M.MATUR_DATE), date(M.ST_INT_DT)) > 6 and
              MONTHS_BETWEEN(date(M.MATUR_DATE), date(M.ST_INT_DT)) <= 12 THEN
          'G01_4_5..A' -- 六个月至一年
         WHEN MONTHS_BETWEEN(date(M.MATUR_DATE), date(M.ST_INT_DT)) > 12 and
              MONTHS_BETWEEN(date(M.MATUR_DATE), date(M.ST_INT_DT)) <= 24 THEN
          'G01_4_6..A' -- 一年至两年
         WHEN MONTHS_BETWEEN(date(M.MATUR_DATE), date(M.ST_INT_DT)) > 24 and
              MONTHS_BETWEEN(date(M.MATUR_DATE), date(M.ST_INT_DT)) <= 36 THEN
          'G01_4_7..A' -- 两年至三年
         WHEN MONTHS_BETWEEN(date(M.MATUR_DATE), date(M.ST_INT_DT)) > 36 and
              MONTHS_BETWEEN(date(M.MATUR_DATE), date(M.ST_INT_DT)) <= 60 THEN
          'G01_4_8..A' -- 三年至五年
         WHEN MONTHS_BETWEEN(date(M.MATUR_DATE), date(M.ST_INT_DT)) > 60 THEN
          'G01_4_9..A' -- 五年以上
       END;
    commit;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '三个月至六个月-五年以上 各项存款 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G0104 2.活期 储蓄存款 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --==================================================
    --   G0104 2 活期  其中：储蓄存款
    --==================================================
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, -- 数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_4_2..B' AS ITEM_NUM, --指标号
             SUM(ACCT_BAL_RMB) AS ITEM_VAL, --指标值
             '2' AS FLAG --标志位
        FROM (SELECT 
               A.ORG_NUM, SUM(A.CREDIT_BAL * B.CCY_RATE) AS ACCT_BAL_RMB
                FROM SMTMODS_V_PUB_IDX_FINA_GL A
                LEFT JOIN SMTMODS_L_PUBL_RATE B
                  ON A.CURR_CD = B.BASIC_CCY
                 AND A.DATA_DATE = B.DATA_DATE
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND( A.ITEM_CD IN ('20110101',/* '20110102',*/ '20110111')
                  or A.ITEM_CD='22410102' )--个人久悬未取款--[JLBA202507210012][石雨][修改内容：224101久悬未取款属于活期存款]
               GROUP BY A.ORG_NUM, B.CCY_RATE)
       GROUP BY ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL -- 改为视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, -- 数据日期
       CASE
         WHEN ORG_NUM LIKE '060101%' THEN
          '060300'
                    WHEN ORG_NUM NOT LIKE '__98%' AND ORG_NUM NOT LIKE '5%' AND ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(ORG_NUM, 1, 4) || '00'
         ELSE
          ORG_NUM
       END AS ORG_NUM,
       'CBRC' AS SYS_NAM, --模块简称
       V_REP_NUM AS REP_NUM, --报表编号
       'G01_4_2..B' AS ITEM_NUM, --指标号
       SUM(ACCT_BALANCE_RMB) AS ITEM_VAL,
       '2' AS FLAG --标志位
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHHQ --个体工商户活期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
         AND GL_ITEM_CODE <> '20110209'  --ALTER BY SHIYU 20250327
       GROUP BY ORG_NUM;
    COMMIT;

    --[JLBA202507210012][石雨][修改内容：224101久悬未取款、201103（财政性存款）调整为 一般单位活期存款]

    INSERT INTO CBRC_A_REPT_ITEM_VAL -- 改为视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, -- 数据日期
       CASE
         WHEN T.ORG_NUM LIKE '060101%' THEN
          '060300'
      
                    WHEN T.ORG_NUM NOT LIKE '__98%' AND T.ORG_NUM NOT LIKE '5%' AND T.ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
         ELSE
          T.ORG_NUM
       END AS ORG_NUM,
       'CBRC' AS SYS_NAM, --模块简称
       V_REP_NUM AS REP_NUM, --报表编号
       'G01_4_2..B' AS ITEM_NUM, --指标号
    SUM(T.ACCT_BALANCE * B.CCY_RATE)  AS ITEM_VAL,
    '2' AS FLAG
     from SMTMODS_L_ACCT_DEPOSIT T
    INNER JOIN SMTMODS_L_CUST_C C
       ON T.DATA_DATE = C.DATA_DATE
      AND T.CUST_ID = C.CUST_ID
    INNER JOIN SMTMODS_L_PUBL_RATE B --汇率表
       ON T.DATA_DATE = B.DATA_DATE
      AND T.CURR_CD = B.BASIC_CCY
      AND B.FORWARD_CCY = 'CNY' --折人民币
    WHERE C.DEPOSIT_CUSTTYPE IN ('13', '14')
      AND T.GL_ITEM_CODE IN ('20110301', '20110302', '20110303', '22410101') --201104 一般单位活期  22410101单位久悬未取款
      AND T.ACCT_BALANCE > 0
      AND T.DATA_DATE = I_DATADATE
    GROUP BY CASE
         WHEN T.ORG_NUM LIKE '060101%' THEN
          '060300'
   
                    WHEN T.ORG_NUM NOT LIKE '__98%' AND T.ORG_NUM NOT LIKE '5%' AND T.ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
         ELSE
          T.ORG_NUM
       END;
      COMMIT;




    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := 'G0104 2.活期 储蓄存款 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '三个月以内 储蓄存款 逻辑处理开始';
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
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_4_3..B' AS ITEM_NUM, --指标号
             SUM(ACCT_BAL_RMB) AS ITEM_VAL, --标志位
             '2' AS FLAG
        FROM (SELECT 
               ORG_NUM, SUM(M.ACCT_BALANCE * N.CCY_RATE) AS ACCT_BAL_RMB
                FROM SMTMODS_L_ACCT_DEPOSIT M
                LEFT JOIN SMTMODS_L_PUBL_RATE N
                  ON M.DATA_DATE = N.DATA_DATE
                 AND M.CURR_CD = N.BASIC_CCY
                 AND N.FORWARD_CCY = 'CNY'
               WHERE M.DATA_DATE = I_DATADATE
                 AND (MONTHS_BETWEEN(DATE(M.MATUR_DATE), DATE(M.ST_INT_DT)) <= 3 OR
                     M.MATUR_DATE IS NULL)
                 AND (M.GL_ITEM_CODE LIKE '20110113%' OR
                     M.GL_ITEM_CODE IN ('20110103',
                                         '20110104',
                                         '20110105',
                                         '20110106',
                                         '20110107',
                                         '20110108',
                                         '20110109'))
               GROUP BY ORG_NUM
              UNION ALL
              SELECT A.ORG_NUM,
                     SUM(A.CREDIT_BAL * B.CCY_RATE) AS ACCT_BAL_RMB
                FROM SMTMODS_L_FINA_GL A
              --FROM SMTMODS_V_PUB_IDX_FINA_GL A
                LEFT JOIN SMTMODS_L_PUBL_RATE B
                  ON A.CURR_CD = B.BASIC_CCY
                 AND A.DATA_DATE = B.DATA_DATE
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                    --20170912 根据业务需求219不取数
                 AND A.ITEM_CD IN
                     ( --'20110109', /*'21902',*/
                      '20110110' /*,'21501_01','21501_02','21505_01'*/
                      ,'20110102'   --

                      ) -- 20210219  modify ljp  从明细取数
               GROUP BY A.ORG_NUM)
       GROUP BY ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL --增加个体工商户部分 lfz 20220614
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
     
       ORG_NUM,
       'CBRC' AS SYS_NAM, --模块简称
       V_REP_NUM AS REP_NUM, --报表编号
       'G01_4_3..B' AS ITEM_NUM, --指标号
       SUM(ACCT_BALANCE_RMB) AS ITEM_VAL,
       '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ --个体工商户定期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
         AND (MONTHS_BETWEEN(DATE(MATUR_DATE), DATE(ST_INT_DT)) <= 3 --3个月以内
             OR MATUR_DATE IS NULL)
         AND  gl_item_code <> '20110210' --剔除单位定期保证金存款 --alter by shiyu 20250327
       GROUP BY ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL --增加个体工商户部分 lfz 20220614
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       
       ORG_NUM,
       'CBRC' AS SYS_NAM, --模块简称
       V_REP_NUM AS REP_NUM, --报表编号
       'G01_4_3..B' AS ITEM_NUM, --指标号
       SUM(ACCT_BALANCE_RMB) AS ITEM_VAL,
       '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHTZ --个体工商户通知存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
       GROUP BY ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '三个月以内 储蓄存款 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

     V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '三个月至六个月-五年以上 储蓄存款 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --==================================================
    --   G0104 4. 三个月至六个月  -- 9. 五年以上 储蓄存款
    --==================================================
    --三个月至六个月
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
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_4_4..B' AS ITEM_NUM, --指标号
             SUM(ACCT_BAL_RMB) AS ITEM_VAL, --标志位
             '2' AS FLAG
        FROM (SELECT 
               ORG_NUM,
               --CASE WHEN M.ORG_NUM NOT LIKE '__98%' THEN SUBSTR(M.ORG_NUM,1,4)||'00' else m.org_num end as org_num,
               SUM(M.ACCT_BALANCE * N.CCY_RATE) AS ACCT_BAL_RMB
                FROM SMTMODS_L_ACCT_DEPOSIT M
                LEFT JOIN SMTMODS_L_PUBL_RATE N
                  ON M.DATA_DATE = N.DATA_DATE
                 AND M.CURR_CD = N.BASIC_CCY
                 AND N.FORWARD_CCY = 'CNY'
               WHERE M.DATA_DATE = I_DATADATE
                 AND MONTHS_BETWEEN(DATE(M.MATUR_DATE), DATE(M.ST_INT_DT)) > 3
                 AND MONTHS_BETWEEN(DATE(M.MATUR_DATE), DATE(M.ST_INT_DT)) <= 6
                 AND (M.GL_ITEM_CODE LIKE '20110113%' OR
                     M.GL_ITEM_CODE IN ('20110103',
                                         '20110104',
                                         '20110105',
                                         '20110106',
                                         '20110107',
                                         '20110108',
                                         '20110109') -- 20210219  modify ljp  从明细取数

                     )
               GROUP BY ORG_NUM)
       GROUP BY ORG_NUM;
    COMMIT;
   

    INSERT INTO CBRC_A_REPT_ITEM_VAL --增加个体工商户部分 lfz 20220614
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM,
       'CBRC' AS SYS_NAM, --模块简称
       V_REP_NUM AS REP_NUM, --报表编号
       CASE
         WHEN MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT))  > 3 AND
              MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT)) <= 6 THEN
          'G01_4_4..B' -- 三个月至六个月
         WHEN MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT)) > 6 AND
              MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT)) <= 12 THEN
          'G01_4_5..B' -- 六个月至一年

         when MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT)) > 12 AND
              MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT)) <= 24 then
          'G01_4_6..B' --一年至两年

         when MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT)) > 24 AND
              MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT)) <= 36 then
          'G01_4_7..B' -- 两年至三年
         when MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT)) > 36 AND
              MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT)) <= 60 then
          'G01_4_8..B' -- 三年至五年
         when MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT)) > 60 then
          'G01_4_9..B' -- 五年以上
       end AS ITEM_NUM, --指标号
       sum (ACCT_BALANCE_RMB) AS ITEM_VAL,
       '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ --个体工商户定期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
         and MONTHS_BETWEEN(DATE(MATUR_DATE), DATE(ST_INT_DT)) > 3
         and gl_item_code <> '20110210' --剔除单位定期保证金存款 --alter by shiyu 20250327
       GROUP BY ORG_NUM,V_REP_NUM,
                CASE
         WHEN MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT))  > 3 AND
              MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT)) <= 6 THEN
          'G01_4_4..B' -- 三个月至六个月
         WHEN MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT)) > 6 AND
              MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT)) <= 12 THEN
          'G01_4_5..B' -- 六个月至一年

         when MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT)) > 12 AND
              MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT)) <= 24 then
          'G01_4_6..B' --一年至两年

         when MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT)) > 24 AND
              MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT)) <= 36 then
          'G01_4_7..B' -- 两年至三年
         when MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT)) > 36 AND
              MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT)) <= 60 then
          'G01_4_8..B' -- 三年至五年
         when MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT)) > 60 then
          'G01_4_9..B' -- 五年以上
       end;
    COMMIT;

    --六个月至一年
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
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_4_5..B' AS ITEM_NUM, --指标号
             SUM(ACCT_BAL_RMB) AS ITEM_VAL, --标志位
             '2' AS FLAG
        FROM (SELECT 
               ORG_NUM,

               SUM(M.ACCT_BALANCE * N.CCY_RATE) AS ACCT_BAL_RMB
                FROM SMTMODS_L_ACCT_DEPOSIT M
                LEFT JOIN SMTMODS_L_PUBL_RATE N
                  ON M.DATA_DATE = N.DATA_DATE
                 AND M.CURR_CD = N.BASIC_CCY
                 AND N.FORWARD_CCY = 'CNY'
               WHERE M.DATA_DATE = I_DATADATE
                 AND MONTHS_BETWEEN(DATE(M.MATUR_DATE), DATE(M.ST_INT_DT)) > 6
                 AND MONTHS_BETWEEN(DATE(M.MATUR_DATE), DATE(M.ST_INT_DT)) <= 12
                 AND (M.GL_ITEM_CODE LIKE '20110113%' OR
                     M.GL_ITEM_CODE IN ('20110103',
                                         '20110104',
                                         '20110105',
                                         '20110106',
                                         '20110107',
                                         '20110108',
                                         '20110109')

                     )
               GROUP BY ORG_NUM)
       GROUP BY ORG_NUM;
    COMMIT;
   

    --一年至两年
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       V_REP_NUM AS REP_NUM, --报表编号
       'G01_4_6..B' AS ITEM_NUM, --指标号
       SUM(ACCT_BAL_RMB) AS ITEM_VAL, --标志位
       '2' AS FLAG
        FROM (SELECT 
               ORG_NUM,

               SUM(M.ACCT_BALANCE * N.CCY_RATE) AS ACCT_BAL_RMB
                FROM SMTMODS_L_ACCT_DEPOSIT M
                LEFT JOIN SMTMODS_L_PUBL_RATE N
                  ON M.DATA_DATE = N.DATA_DATE
                 AND M.CURR_CD = N.BASIC_CCY
                 AND N.FORWARD_CCY = 'CNY'
               WHERE M.DATA_DATE = I_DATADATE
                 and MONTHS_BETWEEN(DATE(M.MATUR_DATE), DATE(M.ST_INT_DT)) > 12
                 and MONTHS_BETWEEN(DATE(M.MATUR_DATE), DATE(M.ST_INT_DT)) <= 24
                 AND (M.GL_ITEM_CODE LIKE '20110113%' OR
                     M.GL_ITEM_CODE IN ('20110103',
                                         '20110104',
                                         '20110105',
                                         '20110106',
                                         '20110107',
                                         '20110108',
                                         '20110109'))
               GROUP BY ORG_NUM)
       GROUP BY ORG_NUM;
    COMMIT;
   

    --两年至三年
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
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_4_7..B' AS ITEM_NUM, --指标号
             SUM(ACCT_BAL_RMB) AS ITEM_VAL, --标志位
             '2' AS FLAG
        FROM (SELECT 
               ORG_NUM, SUM(M.ACCT_BALANCE * N.CCY_RATE) AS ACCT_BAL_RMB
                FROM SMTMODS_L_ACCT_DEPOSIT M
                LEFT JOIN SMTMODS_L_PUBL_RATE N
                  ON M.DATA_DATE = N.DATA_DATE
                 AND M.CURR_CD = N.BASIC_CCY
                 AND N.FORWARD_CCY = 'CNY'
               WHERE M.DATA_DATE = I_DATADATE
                 and MONTHS_BETWEEN(DATE(M.MATUR_DATE), DATE(M.ST_INT_DT)) > 24
                 and MONTHS_BETWEEN(DATE(M.MATUR_DATE), DATE(M.ST_INT_DT)) <= 36
                 AND (M.GL_ITEM_CODE LIKE '20110113%' OR
                     M.GL_ITEM_CODE IN ('20110103',
                                         '20110104',
                                         '20110105',
                                         '20110106',
                                         '20110107',
                                         '20110108',
                                         '20110109') -- 20210219  modify ljp  从明细取数

                     )
               GROUP BY ORG_NUM)
       GROUP BY ORG_NUM;
    COMMIT;
  

    --三年至五年
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
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_4_8..B' AS ITEM_NUM, --指标号
             SUM(ACCT_BAL_RMB) AS ITEM_VAL, --标志位
             '2' AS FLAG
        FROM (SELECT 
               ORG_NUM, SUM(M.ACCT_BALANCE * N.CCY_RATE) AS ACCT_BAL_RMB
                FROM SMTMODS_L_ACCT_DEPOSIT M
                LEFT JOIN SMTMODS_L_PUBL_RATE N
                  ON M.DATA_DATE = N.DATA_DATE
                 AND M.CURR_CD = N.BASIC_CCY
                 AND N.FORWARD_CCY = 'CNY'
               WHERE M.DATA_DATE = I_DATADATE
                 and MONTHS_BETWEEN(DATE(M.MATUR_DATE), DATE(M.ST_INT_DT)) > 36
                 and MONTHS_BETWEEN(DATE(M.MATUR_DATE), DATE(M.ST_INT_DT)) <= 60
                 AND (M.GL_ITEM_CODE LIKE '20110113%' OR
                     M.GL_ITEM_CODE IN ('20110103',
                                         '20110104',
                                         '20110105',
                                         '20110106',
                                         '20110107',
                                         '20110108',
                                         '20110109') -- 20210219  modify ljp  从明细取数

                     )
               GROUP BY ORG_NUM)
       GROUP BY ORG_NUM;
    COMMIT;
    

    --五年以上
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
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_4_9..B' AS ITEM_NUM, --指标号
             SUM(ACCT_BAL_RMB) AS ITEM_VAL, --标志位
             '2' AS FLAG
        FROM (SELECT 
               ORG_NUM, SUM(M.ACCT_BALANCE * N.CCY_RATE) AS ACCT_BAL_RMB
                FROM SMTMODS_L_ACCT_DEPOSIT M
                LEFT JOIN SMTMODS_L_PUBL_RATE N
                  ON M.DATA_DATE = N.DATA_DATE
                 AND M.CURR_CD = N.BASIC_CCY
                 AND N.FORWARD_CCY = 'CNY'
               WHERE M.DATA_DATE = I_DATADATE
                 and MONTHS_BETWEEN(DATE(M.MATUR_DATE), DATE(M.ST_INT_DT)) > 60
                 AND (M.GL_ITEM_CODE LIKE '20110113%' OR
                     M.GL_ITEM_CODE IN ('20110103',
                                         '20110104',
                                         '20110105',
                                         '20110106',
                                         '20110107',
                                         '20110108',
                                         '20110109') -- 20210219  modify ljp  从明细取数
                     )
               GROUP BY ORG_NUM)
       GROUP BY ORG_NUM;
    COMMIT;
   

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '三个月至六个月-五年以上 储蓄存款 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

     V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '2.活期 各项贷款-三个月以内 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --==================================================
    --   G0104 2.活期  各项贷款 -- 4. 三个月至六个月
    --==================================================

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_4_2..C' AS ITEM_NUM,
             SUM(A.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD LIKE '130604'
       GROUP BY ORG_NUM;

    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '2.活期 各项贷款-三个月以内 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '三个月以内-五年以上 各项贷款 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --==================================================
    --   G0104 4. 三个月至六个月  -- 9. 五年以上 各项贷款
    --==================================================

        INSERT INTO CBRC_A_REPT_DWD_G0104
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       COL_1, -- 字段1(合同号)
       COL_2, -- 字段2(借据号)
       COL_3, -- 字段3(客户号)
       COL_4, -- 字段4(放款金额)
       COL_5, -- 字段5(放款日期)
       COL_6, -- 字段6(原始到期日期)
       COL_7, -- 字段7(科目号)
       COL_8, -- 字段8(币种)
       COL_9, -- 字段9(账户类型)
       COL_10, -- 贷款余额
       COL_11  -- 逾期贷款余额
       )

    SELECT 
     I_DATADATE AS DATA_DATE, -- 数据日期
     A.ORG_NUM AS ORG_NUM, --机构号
     A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
     'CBRC' AS SYS_NAM, -- 模块简称
     'G01_4' AS REP_NUM, -- 报表编号
     CASE
       WHEN  MONTHS_BETWEEN(date(A.MATURITY_DT), date(A.DRAWDOWN_DT)) > 60 THEN
        'G01_4_9..C'
       WHEN  MONTHS_BETWEEN(date(A.MATURITY_DT), date(A.DRAWDOWN_DT)) > 36 THEN
        'G01_4_8..C'
       WHEN  MONTHS_BETWEEN(date(A.MATURITY_DT), date(A.DRAWDOWN_DT)) > 24 THEN
        'G01_4_7..C'
       WHEN  MONTHS_BETWEEN(date(A.MATURITY_DT), date(A.DRAWDOWN_DT)) > 12 THEN
        'G01_4_6..C'
       WHEN  MONTHS_BETWEEN(date(A.MATURITY_DT), date(A.DRAWDOWN_DT)) > 6 THEN
        'G01_4_5..C'
       WHEN  MONTHS_BETWEEN(date(A.MATURITY_DT), date(A.DRAWDOWN_DT)) > 3 THEN
        'G01_4_4..C'
       WHEN  MONTHS_BETWEEN(date(A.MATURITY_DT), date(A.DRAWDOWN_DT)) >= 0 THEN
        'G01_4_3..C'
     END AS ITEM_NUM, -- 指标号
     NVL(a.loan_acct_bal * B.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
     A.ACCT_NUM AS COL_1, -- 合同号
     A.LOAN_NUM AS COL_2, -- 借据号
     A.CUST_ID AS COL_3, -- 客户号
     A.DRAWDOWN_AMT AS COL_4, -- 放款金额
     A.DRAWDOWN_DT AS COL_5, -- 放款日期
     A.MATURITY_DT AS COL_6, -- 原始到期日期
     A.ITEM_CD AS COL_7, -- 科目号
     A.CURR_CD AS COL_8, -- 币种
     A.ACCT_TYP AS COL_9, -- 账户类型
     A.LOAN_ACCT_BAL AS COL_10, -- 贷款余额
     A.OD_LOAN_ACCT_BAL AS COL_11 -- 逾期贷款余额
      FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
      LEFT JOIN SMTMODS_L_PUBL_RATE B
        ON A.DATA_DATE = B.DATA_DATE
       AND A.CURR_CD = B.BASIC_CCY
       AND B.FORWARD_CCY = 'CNY'
     WHERE A.DATA_DATE = I_DATADATE
       and a.acct_typ not like '09%'
       AND a.acct_typ not like '90%'
       and acct_sts <> '3'
       AND A.CANCEL_FLG <> 'Y'
       AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       AND (a.ACCT_TYP not in ('E01', 'E02') OR a.ORG_NUM <> '009803') --zhuhe20170526
       AND A.ORG_NUM not in ('009804') ---  add  by  zy  20240827
       AND (nvl(a.OD_LOAN_ACCT_BAL, 0) <= 0 AND OD_FLG = 'N')

    UNION ALL

    SELECT 
     I_DATADATE AS DATA_DATE, -- 数据日期
     A.ORG_NUM AS ORG_NUM, --机构号
     A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
     'CBRC' AS SYS_NAM, -- 模块简称
     'G01_4' AS REP_NUM, -- 报表编号
     CASE
       WHEN  MONTHS_BETWEEN(date(A.MATURITY_DT), date(A.DRAWDOWN_DT)) > 60 THEN
        'G01_4_9..C'
       WHEN  MONTHS_BETWEEN(date(A.MATURITY_DT), date(A.DRAWDOWN_DT)) > 36 THEN
        'G01_4_8..C'
       WHEN  MONTHS_BETWEEN(date(A.MATURITY_DT), date(A.DRAWDOWN_DT)) > 24 THEN
        'G01_4_7..C'
       WHEN  MONTHS_BETWEEN(date(A.MATURITY_DT), date(A.DRAWDOWN_DT)) > 12 THEN
        'G01_4_6..C'
       WHEN  MONTHS_BETWEEN(date(A.MATURITY_DT), date(A.DRAWDOWN_DT)) > 6 THEN
        'G01_4_5..C'
       WHEN  MONTHS_BETWEEN(date(A.MATURITY_DT), date(A.DRAWDOWN_DT)) > 3 THEN
        'G01_4_4..C'
       WHEN  MONTHS_BETWEEN(date(A.MATURITY_DT), date(A.DRAWDOWN_DT)) >= 0 THEN
        'G01_4_3..C'
     END AS ITEM_NUM, -- 指标号
     NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
     A.ACCT_NUM AS COL_1, -- 合同号
     A.LOAN_NUM AS COL_2, -- 借据号
     A.CUST_ID AS COL_3, -- 客户号
     A.DRAWDOWN_AMT AS COL_4, -- 放款金额
     A.DRAWDOWN_DT AS COL_5, -- 放款日期
     A.MATURITY_DT AS COL_6, -- 原始到期日期
     A.ITEM_CD AS COL_7, -- 科目号
     A.CURR_CD AS COL_8, -- 币种
     A.ACCT_TYP AS COL_9, -- 账户类型
     A.LOAN_ACCT_BAL AS COL_10, -- 贷款余额
     A.OD_LOAN_ACCT_BAL AS COL_11 -- 逾期贷款余额
      FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
      LEFT JOIN SMTMODS_L_PUBL_RATE B
        ON A.DATA_DATE = B.DATA_DATE
       AND A.CURR_CD = B.BASIC_CCY
       AND B.FORWARD_CCY = 'CNY'
     WHERE A.DATA_DATE = I_DATADATE
       and acct_typ not like '09%'
       AND A.CANCEL_FLG <> 'Y'
       AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       AND A.acct_typ not like '90%'
       AND A.acct_typ not like '03%'
       AND (nvl(A.OD_LOAN_ACCT_BAL, 0) <= 0 AND A.OD_FLG = 'Y')
       and A.acct_sts <> '3'
       and A.LOAN_ACCT_BAL > 0

    ---------------------------------------------------------------------------------------------------------
    UNION ALL

    SELECT I_DATADATE AS DATA_DATE, -- 数据日期
           A.ORG_NUM AS ORG_NUM, --机构号
           A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
           'CBRC' AS SYS_NAM, -- 模块简称
           'G01_4' AS REP_NUM, -- 报表编号
           A.ITEM_NUM, -- 指标号
           NVL(A.loan_acct_bal_1, 0) - nvl(A.od_loan_acct_bal_1, 0) AS TOTAL_VALUE, -- 汇总值
           A.ACCT_NUM AS COL_1, -- 合同号
           A.LOAN_NUM AS COL_2, -- 借据号
           A.CUST_ID AS COL_3, -- 客户号
           A.DRAWDOWN_AMT AS COL_4, -- 放款金额
           A.DRAWDOWN_DT AS COL_5, -- 放款日期
           A.MATURITY_DT AS COL_6, -- 原始到期日期
           A.ITEM_CD AS COL_7, -- 科目号
           A.CURR_CD AS COL_8, -- 币种
           A.ACCT_TYP AS COL_9, -- 账户类型
           A.LOAN_ACCT_BAL AS COL_10, -- 贷款余额
           A.OD_LOAN_ACCT_BAL AS COL_11 -- 逾期贷款余额
      FROM (SELECT 
             a.org_num as ORG_NUM,
             CASE
               WHEN  MONTHS_BETWEEN(date(A.MATURITY_DT), date(A.DRAWDOWN_DT))   > 60 THEN
                'G01_4_9..C'
               WHEN  MONTHS_BETWEEN(date(A.MATURITY_DT), date(A.DRAWDOWN_DT)) > 36 THEN
                'G01_4_8..C'
               WHEN  MONTHS_BETWEEN(date(A.MATURITY_DT), date(A.DRAWDOWN_DT)) > 24 THEN
                'G01_4_7..C'
               WHEN  MONTHS_BETWEEN(date(A.MATURITY_DT), date(A.DRAWDOWN_DT)) > 12 THEN
                'G01_4_6..C'
               WHEN  MONTHS_BETWEEN(date(A.MATURITY_DT), date(A.DRAWDOWN_DT)) > 6 THEN
                'G01_4_5..C'
               WHEN  MONTHS_BETWEEN(date(A.MATURITY_DT), date(A.DRAWDOWN_DT)) > 3 THEN
                'G01_4_4..C'
               WHEN  MONTHS_BETWEEN(date(A.MATURITY_DT), date(A.DRAWDOWN_DT)) >= 0 THEN
                'G01_4_3..C'
             END AS ITEM_NUM,
             NVL(a.loan_acct_bal * B.CCY_RATE, 0) as loan_acct_bal_1,
             a.od_flg as od_flg,
             CASE
               WHEN a.OD_DAYS IS NOT NULL AND a.OD_DAYS <= 90 AND
                    NVL(a.OD_LOAN_ACCT_BAL, 0) = 0 THEN
                a.LOAN_ACCT_BAL * B.CCY_RATE
               ELSE
                a.OD_LOAN_ACCT_BAL * B.CCY_RATE
             END AS od_loan_acct_bal_1,
             A.DEPARTMENTD,
             A.ACCT_NUM, -- 合同号
             A.LOAN_NUM, -- 借据号
             A.CUST_ID, -- 客户号
             A.DRAWDOWN_AMT, -- 放款金额
             A.DRAWDOWN_DT, -- 放款日期
             A.MATURITY_DT, -- 原始到期日期
             A.ITEM_CD, -- 科目号
             A.CURR_CD, -- 币种
             A.ACCT_TYP, -- 账户类型
             A.LOAN_ACCT_BAL, -- 贷款余额
             A.OD_LOAN_ACCT_BAL -- 逾期贷款余额
              FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ a --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
              LEFT JOIN SMTMODS_L_PUBL_RATE B
                ON a.DATA_DATE = B.DATA_DATE
               AND a.CURR_CD = B.BASIC_CCY
               AND B.FORWARD_CCY = 'CNY'
             where a.DATA_DATE = I_DATADATE
               and acct_typ not like '09%'
               AND acct_typ not like '90%'
               AND A.CANCEL_FLG <> 'Y'
               AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
               AND OD_LOAN_ACCT_BAL > 0
               AND OD_FLG = 'Y') A

----------============  add  by  zy  20240827 start   金融市场部新增取数逻辑 ======
 UNION ALL

   SELECT 
    I_DATADATE AS DATA_DATE, -- 数据日期
    T.ORG_NUM AS ORG_NUM, --机构号
    T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
    'CBRC' AS SYS_NAM, -- 模块简称
    'G01_4' AS REP_NUM, -- 报表编号
    CASE
      WHEN MONTHS_BETWEEN(date(T.MATURITY_DT), date(T.DRAWDOWN_DT)) > 1800 THEN
       'G01_4_9..C' ---5年以上
      WHEN MONTHS_BETWEEN(date(T.MATURITY_DT), date(T.DRAWDOWN_DT)) > 1080 THEN
       'G01_4_8..C' --3年至5年
      WHEN MONTHS_BETWEEN(date(T.MATURITY_DT), date(T.DRAWDOWN_DT)) > 720 THEN
       'G01_4_7..C' --两年至三年
      WHEN MONTHS_BETWEEN(date(T.MATURITY_DT), date(T.DRAWDOWN_DT)) > 360 THEN
       'G01_4_6..C' --一年至两年
      WHEN MONTHS_BETWEEN(date(T.MATURITY_DT), date(T.DRAWDOWN_DT)) > 180 THEN
       'G01_4_5..C' ---六个月至一年
      WHEN MONTHS_BETWEEN(date(T.MATURITY_DT), date(T.DRAWDOWN_DT)) > 90 THEN
       'G01_4_4..C' --三个月至六个月
      WHEN MONTHS_BETWEEN(date(T.MATURITY_DT), date(T.DRAWDOWN_DT)) >= 0 THEN
       'G01_4_3..C' --三个月以内
    END AS ITEM_NUM, -- 指标号
    T.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- 汇总值
    T.ACCT_NUM AS COL_1, -- 合同号
    T.LOAN_NUM AS COL_2, -- 借据号
    T.CUST_ID AS COL_3, -- 客户号
    T.DRAWDOWN_AMT  AS COL_4, -- 放款金额
    T.DRAWDOWN_DT AS COL_5, -- 放款日期
    T.MATURITY_DT AS COL_6, -- 原始到期日期
    T.ITEM_CD AS COL_7, -- 科目号
    T.CURR_CD AS COL_8, -- 币种
    T.ACCT_TYP AS COL_9, -- 账户类型
    T.LOAN_ACCT_BAL AS COL_10, -- 贷款余额
    T.OD_LOAN_ACCT_BAL AS COL_11 -- 逾期贷款余额
     FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
     LEFT JOIN SMTMODS_L_PUBL_RATE TT
       ON TT.DATA_DATE = T.DATA_DATE
      AND TT.BASIC_CCY = T.CURR_CD
      and TT.FORWARD_CCY = 'CNY'
    WHERE T.DATA_DATE = I_DATADATE
      AND T.ACCT_TYP NOT LIKE '90%'
      AND T.LOAN_ACCT_BAL <> 0
      AND T.CANCEL_FLG <> 'Y'
      AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      AND T.ACCT_TYP in ('030102', '030101') --030102 商业承兑汇票 030101 银行承兑汇票
      AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
      AND T.LOAN_ACCT_BAL > 0;

    COMMIT;

    /*---------------------所有指标明细汇总插入目标表-----------------------------------  */

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       DATA_DEPARTMENT)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01_4' AS REP_NUM,
             T.ITEM_NUM,
             SUM(TOTAL_VALUE) AS ITEM_VAL,
             '2' AS FLAG,
             DATA_DEPARTMENT
        FROM CBRC_A_REPT_DWD_G0104 T
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM, T.ITEM_NUM, DATA_DEPARTMENT;
       COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := 'G0104 全部逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 DBMS_OUTPUT.PUT_LINE('O_STATUS=0');
DBMS_OUTPUT.PUT_LINE('O_STATUS_DEC=完成'); 
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
 
END proc_cbrc_idx2_g0104