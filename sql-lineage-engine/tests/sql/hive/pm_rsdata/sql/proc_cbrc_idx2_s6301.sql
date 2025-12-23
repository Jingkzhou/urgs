CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_s6301(II_DATADATE  IN STRING  --跑批日期
                                                       )
/******************************
   @AUTHOR:JIHAIJING
   @CREATE-DATE:20150929
   @DESCRIPTION:S6301
   @MODIFICATION HISTORY:LIXIN04 20151228
   M0.AUTHOR-CREATE_DATE-DESCRIPTION
   M1.20160427.SHENYUNFEI.2016制度升级,取消所有E列指标
   M2.202.3.24 shiyu 因测试需要暂时注释掉全量客户表境内外标识=‘Y’ 条件
   M3.制度升级,取消所有【2.地方政府融资平台贷款余额】 --shiyu
   M4.2022.5.18 shiyu 缺失农村合作数据,筛选对公客户类型substr(cust_typ,1,1) in （'1','0'）
   M5
   M6 20220522 SHIYU 新增6.银税合作贷款情况 逻辑
   M7 20220609 新建临时表CBRC_S6301_AMT_TMP1当年累放贷款年化利息收益 ：实际利率按照放款时利率
   m8 新增银税合作贷款逻辑
   M9 20220712 shiyu 授信及表外授信不含可撤销贷款承诺及商票保贴承诺 修改指标4.表外授信余额
   m10  20221117 授信表中剔除磐石授信数据
   m11 申请户数新制度调整,往年申请今年发放也在统计范围
   m12 无还本续贷 口径调整,贷款形式为6无还本续贷  7 再融资
   M13 20231011.ZJM.对涉及累放的指标进行开发,将村镇铺底数据逻辑放进去
   m14 alter by djh 20240115 新制度 整表（不含转贴现）将转帖放在14.买断式转贴现及其子项下
   新增4.表外项目, 6.3银税合作贷款当年累计发放金额、累计发放户数、11.战略性新兴产业贷款到15.企业类贷款合计
   m15 alter by zy 20240626 完善 金融市场部 14.1银行承兑汇票 14.3商业承兑汇票 的取数逻辑
   m16 20250124 修改内容：2025年制度升级
   m17 20250327 shiyu 修改内容：分行反馈五级分类转贴现部分未取到数据INT_ADJEST_AMT有空值,改成nvl(INT_ADJEST_AMT,0)。
   --    需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”,“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
  --需求编号：JLBA202504160004_关于吉林银行修改单一客户授信逻辑的需求 提出人：苏桐  上线时间：20250627 修改人：石雨    修改内容：客户授信逻辑
  
码值表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_A_REPT_DWD_S6301
        CBRC_S6301_AMT_TMP1
        CBRC_S6301_APPLY_C
        CBRC_S6301_APPLY_P
        CBRC_S6301_DATA_COLLECT_BILL_TY
        CBRC_S6301_DATA_COLLECT_FINACIAL
        CBRC_S6301_DATA_COLLECT_GUARANTEE
码值表：CBRC_FINANCE_COMPANY_LIST
        CBRC_INTO_FIELD_INDEX
依赖表：CBRC_UPRR_U_BASE_INST
集市表：SMTMODS_A_REPT_DWD_MAPPING
        SMTMODS_L_ACCT_FUND_INVEST
        SMTMODS_L_ACCT_OBS_LOAN
        SMTMODS_L_ACCT_PROJECT
        SMTMODS_L_AGRE_BILL_INFO
        SMTMODS_L_AGRE_BOND_INFO
        SMTMODS_L_AGRE_CREDITLINE
        SMTMODS_L_AGRE_GUARANTEE_CONTRACT
        SMTMODS_L_AGRE_GUARANTEE_RELATION
        SMTMODS_L_AGRE_GUARANTY_INFO
        SMTMODS_L_AGRE_GUA_RELATION
        SMTMODS_L_AGRE_LOAN_APPLY
        SMTMODS_L_AGRE_LOAN_CONTRACT
        SMTMODS_L_CUST_ALL
        SMTMODS_L_CUST_BILL_TY
        SMTMODS_L_CUST_C
        SMTMODS_L_CUST_EXTERNAL_INFO
        SMTMODS_L_CUST_P
        SMTMODS_L_PUBL_RATE
        SMTMODS_V_PUB_IDX_DK_YSDQRJJ

  *******************************/
 IS
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE    VARCHAR(30); --当前储存过程名称
  V_TAB_NAME     VARCHAR(30); --目标表名
  I_DATADATE     STRING; --数据日期(数值型)YYYYMMDD
  D_DATADATE_CCY STRING; --数据日期(日期型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_ERRORDESC    VARCHAR(280); --错误内容
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时,用于识别存储过程的是否跳过1--跳过 0--不跳过
  NEXTDATE       VARCHAR2(10);
  NUM            INTEGER;
  V_SYSTEM       VARCHAR2(30); 
  
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';

    I_DATADATE  := II_DATADATE;
    V_SYSTEM    := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_S6301');
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_TAB_NAME     := 'CBRC_A_REPT_ITEM_VAL';
    D_DATADATE_CCY := I_DATADATE;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']S6301当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    D_DATADATE_CCY := I_DATADATE;

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S6301_DATA_COLLECT_TMP';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP_S6301_DATA_COLLECT';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP_S6301_DATA_COLLECT2';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S6301_DATA_COLLECT_GUARANTEE';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S6301_DATA_COLLECT_FINACIAL';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S6301_DATA_COLLECT_BILL_TY';
    --  EXECUTE IMMEDIATE 'TRUNCATE TABLE L_ACCT_LOAN_SP_STATUS_TMP';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S6301_APPLY_P';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S6301_APPLY_C';

    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'S6301'
       AND T.FLAG = '2';
    COMMIT;


    --清除当前分区表的数据
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_A_REPT_DWD_S6301' ;

    -----------------------------------------------------------------------大型企业--------------------------------------------------------------------------
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据大型企业至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --1.境内贷款余额合计
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_16 --字段16（控股类型）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          'S63_I_1.1.1.A'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          'S63_I_1.1.2.A'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          'S63_I_1.1.3.A'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          'S63_I_1.1.4.A'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          'S63_I_1.1.5.A'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) +
       (NVL(A.INT_ADJEST_AMT, 0) * U.CCY_RATE) COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）

       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       M1.M_NAME
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
      /*INNER JOIN SMTMODS_L_CUST_ALL T
       ON A.CUST_ID = T.CUST_ID
      AND T.DATA_DATE = I_DATADATE*/
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
          ON B.CORP_HOLD_TYPE = M1.M_CODE
         AND M1.M_TABLECODE = 'CORP_HOLD_TYPE'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND A.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND B.CORP_SCALE = 'B'
         AND A.CANCEL_FLG <> 'Y'
            -- AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让

      ;

    COMMIT;

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_15 --贷款担保方式
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T.GUARANTY_TYP LIKE 'D%' THEN
          'S63_I_1.2.1.A'
         WHEN T.GUARANTY_TYP LIKE 'C%' THEN
          'S63_I_1.2.2.A'
       /*WHEN T.GUARANTY_TYP IN ('A', 'B') THEN
       'S63_I_1.2.3.A'*/
       --20210923  ZHOUJINGKUN UPDATE 新信贷系统修改映射B01  B99
         WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
          'S63_I_1.2.3.A'
         WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN
          'S63_I_1.2.4.A'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(T.LOAN_ACCT_BAL, 0) * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）

       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN t.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN t.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN t.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN t.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN t.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
         WHEN T.GUARANTY_TYP = 'A' THEN
          '质押贷款'
         WHEN T.GUARANTY_TYP = 'B' THEN
          '抵押贷款'
         WHEN T.GUARANTY_TYP = 'B01' THEN
          '房地产抵押贷款'
         WHEN T.GUARANTY_TYP = 'B99' THEN
          '其他抵押贷款'
         WHEN T.GUARANTY_TYP = 'C' THEN
          '保证贷款'
         WHEN T.GUARANTY_TYP = 'C01' THEN
          '联保贷款'
         WHEN T.GUARANTY_TYP = 'C99' THEN
          '其他保证贷款'
         WHEN T.GUARANTY_TYP = 'D' THEN
          '信用/免担保贷款'
         WHEN T.GUARANTY_TYP = 'E' THEN
          '组合担保'
         WHEN T.GUARANTY_TYP = 'Z' THEN
          '其他'
       END COL_15 --贷款担保方式
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD

       WHERE T.DATA_DATE = I_DATADATE
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND A.CORP_SCALE = 'B'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG <> 'Y'
         AND TT.FORWARD_CCY = 'CNY'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;

    COMMIT;

    --   1.3按贷款逾期情况

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_14 -- 字段14（逾期天数）
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /* CASE
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.1.A'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.1.A.2020'
       END AS ITEM_NUM,*/
       --
       CASE
         WHEN A.OD_DAYS < 31 THEN
          'S63_I_1.3.1.A.2025'
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.2.A.2025'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.3.A.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG <> 'Y'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'B'
            --   AND T.INLANDORRSHORE_FLG = 'Y'--m2
         AND A.OD_FLG = 'Y'
         AND A.OD_DAYS < 91 -- 20200114 MODIFY LJP 期限拆分成 60天以内 和61-90
         AND (A.ACCT_TYP NOT LIKE '0101%' AND A.ACCT_TYP NOT LIKE '0103%' AND
             A.ACCT_TYP NOT LIKE '0104%' AND A.ACCT_TYP NOT LIKE '0199%' AND
             A.ACCT_TYP <> 'E01')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_14 -- 字段14（逾期天数）
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*CASE
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.1.A'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.1.A.2020'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS < 31 THEN
          'S63_I_1.3.1.A.2025'
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.2.A.2025'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.3.A.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.OD_LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND A.CANCEL_FLG <> 'Y'
         AND B.CORP_SCALE = 'B'
            -- AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND A.OD_FLG = 'Y'
         AND A.OD_DAYS < 91
         AND (A.ACCT_TYP LIKE '0101%' OR A.ACCT_TYP LIKE '0103%' OR
             A.ACCT_TYP LIKE '0104%' OR A.ACCT_TYP LIKE '0199%' OR
             A.ACCT_TYP = 'E01')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;
    --1.3.2.A  1.3.3.A
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_14 -- 字段14（逾期天数）
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*CASE
         WHEN A.OD_DAYS > 90 AND A.OD_DAYS <= 360 THEN
          'S63_I_1.3.2.A'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.3.A'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS > 90 AND A.OD_DAYS <= 180 THEN
          'S63_I_1.3.4.A.2025'
         WHEN A.OD_DAYS > 180 AND A.OD_DAYS <= 270 THEN
          'S63_I_1.3.5.A.2025'
         WHEN A.OD_DAYS > 270 AND A.OD_DAYS <= 360 THEN
          'S63_I_1.3.6.A.2025'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.7.A.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND A.CANCEL_FLG <> 'Y'
         AND B.CORP_SCALE = 'B'
            ---   AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND A.OD_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.OD_DAYS > 90
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;
    ----------------------------------------------------------------- --中型企业-----------------------------------------------------------
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据中型企业至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12) --  字段12（业务条线）

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          'S63_I_1.1.1.B'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          'S63_I_1.1.2.B'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          'S63_I_1.1.3.B'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          'S63_I_1.1.4.B'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          'S63_I_1.1.5.B'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) +
       (NVL(A.INT_ADJEST_AMT, 0) * U.CCY_RATE) COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'M'
         AND A.CANCEL_FLG <> 'Y'
            --- AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_15 --贷款担保方式
       )
    --   1.2按贷款担保方式
    --20170621 MANAN 修改 按照新逻辑梳理
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T.GUARANTY_TYP LIKE 'D%' THEN
          'S63_I_1.2.1.B'
         WHEN T.GUARANTY_TYP LIKE 'C%' THEN
          'S63_I_1.2.2.B'
       /* WHEN T.GUARANTY_TYP IN ('A', 'B') THEN
       'S63_I_1.2.3.B'*/
         WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN --ZHOUJINGKUN 20210923 新信贷系统码值重新映射
          'S63_I_1.2.3.B'
         WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN
          'S63_I_1.2.4.B'
       END,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(T.LOAN_ACCT_BAL, 0) * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN t.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN t.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN t.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN t.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN t.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
         WHEN T.GUARANTY_TYP = 'A' THEN
          '质押贷款'
         WHEN T.GUARANTY_TYP = 'B' THEN
          '抵押贷款'
         WHEN T.GUARANTY_TYP = 'B01' THEN
          '房地产抵押贷款'
         WHEN T.GUARANTY_TYP = 'B99' THEN
          '其他抵押贷款'
         WHEN T.GUARANTY_TYP = 'C' THEN
          '保证贷款'
         WHEN T.GUARANTY_TYP = 'C01' THEN
          '联保贷款'
         WHEN T.GUARANTY_TYP = 'C99' THEN
          '其他保证贷款'
         WHEN T.GUARANTY_TYP = 'D' THEN
          '信用/免担保贷款'
         WHEN T.GUARANTY_TYP = 'E' THEN
          '组合担保'
         WHEN T.GUARANTY_TYP = 'Z' THEN
          '其他'
       END COL_15 --贷款担保方式
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND A.CORP_SCALE = 'M'
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG <> 'Y'
         AND TT.FORWARD_CCY = 'CNY'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;

    COMMIT;

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_14 -- 字段14（逾期天数）
       )
    --   1.3按贷款逾期情况

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /* CASE
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.1.B'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.1.B.2020'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS < 31 THEN
          'S63_I_1.3.1.B.2025'
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.2.B.2025'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.3.B.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'M'
         AND A.CANCEL_FLG <> 'Y'
            -- AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND A.OD_FLG = 'Y'
         AND A.OD_DAYS < 91
         AND (A.ACCT_TYP NOT LIKE '0101%' AND A.ACCT_TYP NOT LIKE '0103%' AND
             A.ACCT_TYP NOT LIKE '0104%' AND A.ACCT_TYP NOT LIKE '0199%' AND
             A.ACCT_TYP <> 'E01')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_14 -- 字段14（逾期天数）
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /* CASE
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.1.B'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.1.B.2020'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS < 31 THEN
          'S63_I_1.3.1.B.2025'
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.2.B.2025'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.3.B.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.OD_LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'M'
         AND A.CANCEL_FLG <> 'Y'
            ---  AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND A.OD_FLG = 'Y'
         AND A.OD_DAYS < 91
         AND (A.ACCT_TYP LIKE '0101%' OR A.ACCT_TYP LIKE '0103%' OR
             A.ACCT_TYP LIKE '0104%' OR A.ACCT_TYP LIKE '0199%' OR
             A.ACCT_TYP = 'E01')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;

    --1.3.2.B  1.3.3.B
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_14 -- 字段14（逾期天数）
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*CASE
         WHEN A.OD_DAYS > 90 AND A.OD_DAYS < 361 THEN
          'S63_I_1.3.2.B'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.3.B'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS > 90 AND A.OD_DAYS <= 180 THEN
          'S63_I_1.3.4.B.2025'
         WHEN A.OD_DAYS > 180 AND A.OD_DAYS <= 270 THEN
          'S63_I_1.3.5.B.2025'
         WHEN A.OD_DAYS > 270 AND A.OD_DAYS <= 360 THEN
          'S63_I_1.3.6.B.2025'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.7.B.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'M'
         AND A.CANCEL_FLG <> 'Y'
            ---  AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND A.OD_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.OD_DAYS > 90
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;

    -----------------------------------------------------------------------小型企业--------------------------------------------------------------------------
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据小型企业至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12) --  字段12（业务条线）

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          'S63_I_1.1.1.C'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          'S63_I_1.1.2.C'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          'S63_I_1.1.3.C'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          'S63_I_1.1.4.C'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          'S63_I_1.1.5.C'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) +
       (NVL(A.INT_ADJEST_AMT, 0) * U.CCY_RATE) COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         and A.ACCT_TYP NOT LIKE '90%'
         AND B.CORP_SCALE = 'S'
         AND A.CANCEL_FLG <> 'Y'
            --- AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_15 --贷款担保方式
       )
    --   1.2按贷款担保方式
    --20170621 MANAN 修改 按照新逻辑梳理
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T.GUARANTY_TYP LIKE 'D%' THEN
          'S63_I_1.2.1.C'
         WHEN T.GUARANTY_TYP LIKE 'C%' THEN
          'S63_I_1.2.2.C'
       /*   WHEN T.GUARANTY_TYP IN ('A', 'B') THEN
       'S63_I_1.2.3.C'*/
       --20210923  ZHOUJINGKUN UPDATE 新信贷系统修改映射B01  B99
         WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
          'S63_I_1.2.3.C'
         WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN
          'S63_I_1.2.4.C'
       END,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(T.LOAN_ACCT_BAL, 0) * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN t.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN t.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN t.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN t.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN t.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
         WHEN T.GUARANTY_TYP = 'A' THEN
          '质押贷款'
         WHEN T.GUARANTY_TYP = 'B' THEN
          '抵押贷款'
         WHEN T.GUARANTY_TYP = 'B01' THEN
          '房地产抵押贷款'
         WHEN T.GUARANTY_TYP = 'B99' THEN
          '其他抵押贷款'
         WHEN T.GUARANTY_TYP = 'C' THEN
          '保证贷款'
         WHEN T.GUARANTY_TYP = 'C01' THEN
          '联保贷款'
         WHEN T.GUARANTY_TYP = 'C99' THEN
          '其他保证贷款'
         WHEN T.GUARANTY_TYP = 'D' THEN
          '信用/免担保贷款'
         WHEN T.GUARANTY_TYP = 'E' THEN
          '组合担保'
         WHEN T.GUARANTY_TYP = 'Z' THEN
          '其他'
       END COL_15 --贷款担保方式
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
     
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND A.CORP_SCALE = 'S'
         AND T.LOAN_ACCT_BAL <> 0
         AND TT.FORWARD_CCY = 'CNY'
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;

    COMMIT;

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_14 -- 字段14（逾期天数）
       )
    --   1.3按贷款逾期情况

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*CASE
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.1.C'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.1.C.2020'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS < 31 THEN
          'S63_I_1.3.1.C.2025'
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.2.C.2025'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.3.C.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'S'
         AND A.CANCEL_FLG <> 'Y'
            --- AND T.INLANDORRSHORE_FLG = 'Y' --m2
         AND A.OD_FLG = 'Y'
         AND A.OD_DAYS < 91
         AND (A.ACCT_TYP NOT LIKE '0101%' AND A.ACCT_TYP NOT LIKE '0103%' AND
             A.ACCT_TYP NOT LIKE '0104%' AND A.ACCT_TYP NOT LIKE '0199%' AND
             A.ACCT_TYP <> 'E01')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_14 -- 字段14（逾期天数）
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*CASE
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.1.C'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.1.C.2020'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS < 31 THEN
          'S63_I_1.3.1.C.2025'
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.2.C.2025'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.3.C.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.OD_LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'S'
         AND A.CANCEL_FLG <> 'Y'
            ---  AND T.INLANDORRSHORE_FLG = 'Y' --m2
         AND A.OD_FLG = 'Y'
         AND A.OD_DAYS < 91
         AND (A.ACCT_TYP LIKE '0101%' OR A.ACCT_TYP LIKE '0103%' OR
             A.ACCT_TYP LIKE '0104%' OR A.ACCT_TYP LIKE '0199%')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;

    --1.3.2.C  1.3.3.C
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_14 -- 字段14（逾期天数）
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*  CASE
         WHEN A.OD_DAYS > 90 AND A.OD_DAYS < 361 THEN
          'S63_I_1.3.2.C'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.3.C'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS > 90 AND A.OD_DAYS <= 180 THEN
          'S63_I_1.3.4.C.2025'
         WHEN A.OD_DAYS > 180 AND A.OD_DAYS <= 270 THEN
          'S63_I_1.3.5.C.2025'
         WHEN A.OD_DAYS > 270 AND A.OD_DAYS <= 360 THEN
          'S63_I_1.3.6.C.2025'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.7.C.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'S'
         AND A.CANCEL_FLG <> 'Y'
            -- AND T.INLANDORRSHORE_FLG = 'Y' --m2
         AND A.OD_FLG = 'Y'
         AND A.OD_DAYS > 90
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;
    -----------------------------------------------------------------------微型企业--------------------------------------------------------------------------
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据微型企业至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12) --  字段12（业务条线）

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          'S63_I_1.1.1.D'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          'S63_I_1.1.2.D'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          'S63_I_1.1.3.D'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          'S63_I_1.1.4.D'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          'S63_I_1.1.5.D'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) +
       (NVL(A.INT_ADJEST_AMT, 0) * U.CCY_RATE) COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'T'
         AND A.CANCEL_FLG <> 'Y'
            ---  AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_15 --贷款担保方式
       )
    --   1.2按贷款担保方式
    --20170621 MANAN 修改 按照新逻辑梳理
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T.GUARANTY_TYP LIKE 'D%' THEN
          'S63_I_1.2.1.D'
         WHEN T.GUARANTY_TYP LIKE 'C%' THEN
          'S63_I_1.2.2.D'
       --   WHEN T.GUARANTY_TYP IN ('A', 'B') THEN
       --20210923  ZHOUJINGKUN UPDATE 新信贷系统修改映射B01  B99
         WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
          'S63_I_1.2.3.D'
         WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN
          'S63_I_1.2.4.D'
       END,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(T.LOAN_ACCT_BAL, 0) * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN t.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN t.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN t.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN t.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN t.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
         WHEN T.GUARANTY_TYP = 'A' THEN
          '质押贷款'
         WHEN T.GUARANTY_TYP = 'B' THEN
          '抵押贷款'
         WHEN T.GUARANTY_TYP = 'B01' THEN
          '房地产抵押贷款'
         WHEN T.GUARANTY_TYP = 'B99' THEN
          '其他抵押贷款'
         WHEN T.GUARANTY_TYP = 'C' THEN
          '保证贷款'
         WHEN T.GUARANTY_TYP = 'C01' THEN
          '联保贷款'
         WHEN T.GUARANTY_TYP = 'C99' THEN
          '其他保证贷款'
         WHEN T.GUARANTY_TYP = 'D' THEN
          '信用/免担保贷款'
         WHEN T.GUARANTY_TYP = 'E' THEN
          '组合担保'
         WHEN T.GUARANTY_TYP = 'Z' THEN
          '其他'
       END COL_15 --贷款担保方式
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND A.CORP_SCALE = 'T'
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG <> 'Y'
         AND TT.FORWARD_CCY = 'CNY'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_14 -- 字段14（逾期天数）
       )
    --   1.3按贷款逾期情况

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*CASE
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.1.D'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.1.D.2020'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS < 31 THEN
          'S63_I_1.3.1.D.2025'
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.2.D.2025'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.3.D.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'T'
         AND A.CANCEL_FLG <> 'Y'
            ---  AND T.INLANDORRSHORE_FLG = 'Y' --m2
         AND A.OD_FLG = 'Y'
         AND A.OD_DAYS < 91
         AND (A.ACCT_TYP NOT LIKE '0101%' AND A.ACCT_TYP NOT LIKE '0103%' AND
             A.ACCT_TYP NOT LIKE '0104%' AND A.ACCT_TYP NOT LIKE '0199%' AND
             A.ACCT_TYP <> 'E01')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_14 -- 字段14（逾期天数）
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*CASE
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.1.D'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.1.D.2020'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS < 31 THEN
          'S63_I_1.3.1.D.2025'
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.2.D.2025'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.3.D.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.OD_LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'T'
         AND A.CANCEL_FLG <> 'Y'
            --- AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND A.OD_FLG = 'Y'
         AND A.OD_DAYS < 91
         AND (A.ACCT_TYP LIKE '0101%' OR A.ACCT_TYP LIKE '0103%' OR
             A.ACCT_TYP LIKE '0104%' OR A.ACCT_TYP LIKE '0199%')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;

    --1.3.2.D  1.3.3.D
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_14 -- 字段14（逾期天数）
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*CASE
         WHEN A.OD_DAYS > 90 AND A.OD_DAYS < 361 THEN
          'S63_I_1.3.2.D'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.3.D'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS > 90 AND A.OD_DAYS <= 180 THEN
          'S63_I_1.3.4.D.2025'
         WHEN A.OD_DAYS > 180 AND A.OD_DAYS <= 270 THEN
          'S63_I_1.3.5.D.2025'
         WHEN A.OD_DAYS > 270 AND A.OD_DAYS <= 360 THEN
          'S63_I_1.3.6.D.2025'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.7.D.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'T'
         AND A.CANCEL_FLG <> 'Y'
            --- AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND A.OD_FLG = 'Y'
         AND A.OD_DAYS > 90
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    ------------------------个人经营性贷款
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据个人经营性贷款至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18 -- 字段18（个人客户类型（个体工商户 小微企业主 其他个人））
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          'S63_I_1.1.1.F'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          'S63_I_1.1.2.F'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          'S63_I_1.1.3.F'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          'S63_I_1.1.4.F'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          'S63_I_1.1.5.F'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(B.CUST_NAM, C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (nvl(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) +
       (nvl(A.INT_ADJEST_AMT, 0) * U.CCY_RATE) -- m17 20250327 shiyu 修改内容：分行反馈五级分类转贴现部分未取到数据INT_ADJEST_AMT有空值,改成nvl(INT_ADJEST_AMT,0)。
       AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
         WHEN C.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN
          '个体工商户'
         WHEN C.OPERATE_CUST_TYPE = 'B' THEN
          '小微企业主'
         WHEN C.OPERATE_CUST_TYPE = 'Z' THEN
          '其他个人'
       end -- 字段18（个人客户类型（个体工商户 小微企业主 其他个人））
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND A.ACCT_TYP LIKE '0102%'
         AND A.CANCEL_FLG <> 'Y'
            --AND T.INLANDORRSHORE_FLG = 'Y' --m2
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;

    --LIUD MF AT 20200921 经营性贷款按新口径出数。
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18, -- 字段18（个人客户类型（个体工商户 小微企业主 其他个人））
       COL_15 --字段15（贷款担保方式）
       )
    --   1.2按贷款担保方式
      SELECT
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T.GUARANTY_TYP LIKE 'D%' THEN
          'S63_I_1.2.1.F' --信用贷款
         WHEN T.GUARANTY_TYP LIKE 'C%' THEN
          'S63_I_1.2.2.F' --保证贷款
       --   WHEN T.GUARANTY_TYP IN ('A', 'B') THEN
       --20210923  ZHOUJINGKUN UPDATE 新信贷系统修改映射B01  B99
         WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
          'S63_I_1.2.3.F' --抵（质）押贷款
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(B.CUST_NAM, C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
         WHEN C.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN
          '个体工商户'
         WHEN C.OPERATE_CUST_TYPE = 'B' THEN
          '小微企业主'
         WHEN C.OPERATE_CUST_TYPE = 'Z' THEN
          '其他个人'
       end, -- 字段18（个人客户类型（个体工商户 小微企业主 其他个人））
       CASE
         WHEN T.GUARANTY_TYP = 'A' THEN
          '质押贷款'
         WHEN T.GUARANTY_TYP = 'B' THEN
          '抵押贷款'
         WHEN T.GUARANTY_TYP = 'B01' THEN
          '房地产抵押贷款'
         WHEN T.GUARANTY_TYP = 'B99' THEN
          '其他抵押贷款'
         WHEN T.GUARANTY_TYP = 'C' THEN
          '保证贷款'
         WHEN T.GUARANTY_TYP = 'C01' THEN
          '联保贷款'
         WHEN T.GUARANTY_TYP = 'C99' THEN
          '其他保证贷款'
         WHEN T.GUARANTY_TYP = 'D' THEN
          '信用/免担保贷款'
         WHEN T.GUARANTY_TYP = 'E' THEN
          '组合担保'
         WHEN T.GUARANTY_TYP = 'Z' THEN
          '其他'
       END COL_15 --贷款担保方式
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T

        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --经营性贷款
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG <> 'Y'
         AND TT.FORWARD_CCY = 'CNY'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18, -- 字段18（个人客户类型（个体工商户 小微企业主 其他个人））
       COL_14 --字段14（逾期天数）
       )
    --   1.3按贷款逾期情况

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*CASE
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.1.F'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.1.F.2020'
         WHEN A.OD_DAYS < 361 THEN
          'S63_I_1.3.2.F'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.3.F'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS > 0 AND A.OD_DAYS <= 30 THEN
          'S63_I_1.3.1.F.2025'
         WHEN A.OD_DAYS > 30 AND A.OD_DAYS <= 60 THEN
          'S63_I_1.3.2.F.2025'
         WHEN A.OD_DAYS > 60 AND A.OD_DAYS <= 90 THEN
          'S63_I_1.3.3.F.2025'
         WHEN A.OD_DAYS > 90 AND A.OD_DAYS <= 180 THEN
          'S63_I_1.3.4.F.2025'
         WHEN A.OD_DAYS > 180 AND A.OD_DAYS <= 270 THEN
          'S63_I_1.3.5.F.2025'
         WHEN A.OD_DAYS > 270 AND A.OD_DAYS <= 360 THEN
          'S63_I_1.3.6.F.2025'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.7.F.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(B.CUST_NAM, C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
         WHEN C.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN
          '个体工商户'
         WHEN C.OPERATE_CUST_TYPE = 'B' THEN
          '小微企业主'
         WHEN C.OPERATE_CUST_TYPE = 'Z' THEN
          '其他个人'
       end AS COL_18, -- 字段18（个人客户类型（个体工商户 小微企业主 其他个人））

       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND A.ACCT_TYP LIKE '0102%'
            --- AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND A.OD_FLG = 'Y'
         AND A.CANCEL_FLG <> 'Y'
         AND A.OD_DAYS > 0
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;

    COMMIT;
    ----------------------------------------------------------------------- "其中：个体工商户贷款"--------------------------------------------------------------------------
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据 "其中：个体工商户贷款"至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          'S63_I_1.1.1.G'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          'S63_I_1.1.2.G'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          'S63_I_1.1.3.G'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          'S63_I_1.1.4.G'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          'S63_I_1.1.5.G'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(B.CUST_NAM, C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (nvl(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) +
       (nvl(A.INT_ADJEST_AMT, 0) * U.CCY_RATE) -- m17 20250327 shiyu 修改内容：分行反馈五级分类转贴现部分未取到数据INT_ADJEST_AMT有空值,改成nvl(INT_ADJEST_AMT,0)。
       AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND A.ACCT_TYP LIKE '0102%'
         AND A.CANCEL_FLG <> 'Y'
         AND (C.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3')
            --  AND T.INLANDORRSHORE_FLG = 'Y' --m2
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_15 --贷款担保方式
       )
    --   1.2按贷款担保方式
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T.GUARANTY_TYP LIKE 'D%' THEN
          'S63_I_1.2.1.G'
         WHEN T.GUARANTY_TYP LIKE 'C%' THEN
          'S63_I_1.2.2.G'
       -- WHEN T.GUARANTY_TYP IN ('A', 'B') THEN
       --20210923  ZHOUJINGKUN UPDATE 新信贷系统修改映射B01  B99
         WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
          'S63_I_1.2.3.G'
       END,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(P.CUST_NAM, C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
         WHEN T.GUARANTY_TYP = 'A' THEN
          '质押贷款'
         WHEN T.GUARANTY_TYP = 'B' THEN
          '抵押贷款'
         WHEN T.GUARANTY_TYP = 'B01' THEN
          '房地产抵押贷款'
         WHEN T.GUARANTY_TYP = 'B99' THEN
          '其他抵押贷款'
         WHEN T.GUARANTY_TYP = 'C' THEN
          '保证贷款'
         WHEN T.GUARANTY_TYP = 'C01' THEN
          '联保贷款'
         WHEN T.GUARANTY_TYP = 'C99' THEN
          '其他保证贷款'
         WHEN T.GUARANTY_TYP = 'D' THEN
          '信用/免担保贷款'
         WHEN T.GUARANTY_TYP = 'E' THEN
          '组合担保'
         WHEN T.GUARANTY_TYP = 'Z' THEN
          '其他'
       END COL_15 --贷款担保方式
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P P
          ON T.CUST_ID = P.CUST_ID
         AND T.DATA_DATE = P.DATA_DATE
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.CUST_ID = C.CUST_ID
         AND T.DATA_DATE = C.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG <> 'Y'
         AND TT.FORWARD_CCY = 'CNY'
         AND (P.OPERATE_CUST_TYPE = 'A' OR C.CUST_TYP = '3')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL -- add by haorui 20250311 JLBA202408200012 资产未转让
      ;

    COMMIT;

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_14 --逾期天数
       )
    --   1.3按贷款逾期情况

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*CASE
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.1.G'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.1.G.2020'
         WHEN A.OD_DAYS < 361 THEN
          'S63_I_1.3.2.G'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.3.G'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS > 0 AND A.OD_DAYS <= 30 THEN
          'S63_I_1.3.1.G.2025'
         WHEN A.OD_DAYS > 30 AND A.OD_DAYS <= 60 THEN
          'S63_I_1.3.2.G.2025'
         WHEN A.OD_DAYS > 60 AND A.OD_DAYS <= 90 THEN
          'S63_I_1.3.3.G.2025'
         WHEN A.OD_DAYS > 90 AND A.OD_DAYS <= 180 THEN
          'S63_I_1.3.4.G.2025'
         WHEN A.OD_DAYS > 180 AND A.OD_DAYS <= 270 THEN
          'S63_I_1.3.5.G.2025'
         WHEN A.OD_DAYS > 270 AND A.OD_DAYS <= 360 THEN
          'S63_I_1.3.6.G.2025'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.7.G.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       nvl(B.CUST_NAM, C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP LIKE '0102%'
         AND (C.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3')
            --  AND T.INLANDORRSHORE_FLG = 'Y' --m2
         AND A.OD_FLG = 'Y'
         AND A.OD_DAYS > 0
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;

    COMMIT;
    ----------------------------------------------------------------------- "其中：小微企业主贷款"--------------------------------------------------------------------------
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据"其中：小微企业主贷款"至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          'S63_I_1.1.1.H'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          'S63_I_1.1.2.H'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          'S63_I_1.1.3.H'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          'S63_I_1.1.4.H'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          'S63_I_1.1.5.H'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       C.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (nvl(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) +
       (nvl(A.INT_ADJEST_AMT, 0) * U.CCY_RATE) -- m17 20250327 shiyu 修改内容：分行反馈五级分类转贴现部分未取到数据INT_ADJEST_AMT有空值,改成nvl(INT_ADJEST_AMT,0)。
       AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP LIKE '0102%'
         AND C.OPERATE_CUST_TYPE = 'B'
            --  AND T.INLANDORRSHORE_FLG = 'Y' --m2
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_15 --贷款担保方式
       )
    --   1.2按贷款担保方式

      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T.GUARANTY_TYP LIKE 'D%' THEN
          'S63_I_1.2.1.H'
         WHEN T.GUARANTY_TYP LIKE 'C%' THEN
          'S63_I_1.2.2.H'
       -- WHEN T.GUARANTY_TYP IN ('A', 'B') THEN
       --20210923  ZHOUJINGKUN UPDATE 新信贷系统修改映射B01  B99
         WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
          'S63_I_1.2.3.H'
       END,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       P.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
         WHEN T.GUARANTY_TYP = 'A' THEN
          '质押贷款'
         WHEN T.GUARANTY_TYP = 'B' THEN
          '抵押贷款'
         WHEN T.GUARANTY_TYP = 'B01' THEN
          '房地产抵押贷款'
         WHEN T.GUARANTY_TYP = 'B99' THEN
          '其他抵押贷款'
         WHEN T.GUARANTY_TYP = 'C' THEN
          '保证贷款'
         WHEN T.GUARANTY_TYP = 'C01' THEN
          '联保贷款'
         WHEN T.GUARANTY_TYP = 'C99' THEN
          '其他保证贷款'
         WHEN T.GUARANTY_TYP = 'D' THEN
          '信用/免担保贷款'
         WHEN T.GUARANTY_TYP = 'E' THEN
          '组合担保'
         WHEN T.GUARANTY_TYP = 'Z' THEN
          '其他'
       END COL_15 --贷款担保方式
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_P P
          ON T.CUST_ID = P.CUST_ID
         AND T.DATA_DATE = P.DATA_DATE
     
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG <> 'Y'
         AND TT.FORWARD_CCY = 'CNY'
         AND P.OPERATE_CUST_TYPE = 'B'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;

    COMMIT;

    --20201210 ZJK 修改原因A层主要担保方式取担保合同表有多种担保方式 获取MAX 有问题 修改为在L层取数

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_14 --逾期天数
       )
    --   1.3按贷款逾期情况

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*CASE
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.1.H'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.1.H.2020'
         WHEN A.OD_DAYS < 361 THEN
          'S63_I_1.3.2.H'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.3.H'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS > 0 AND A.OD_DAYS <= 30 THEN
          'S63_I_1.3.1.H.2025'
         WHEN A.OD_DAYS > 30 AND A.OD_DAYS <= 60 THEN
          'S63_I_1.3.2.H.2025'
         WHEN A.OD_DAYS > 60 AND A.OD_DAYS <= 90 THEN
          'S63_I_1.3.3.H.2025'
         WHEN A.OD_DAYS > 90 AND A.OD_DAYS <= 180 THEN
          'S63_I_1.3.4.H.2025'
         WHEN A.OD_DAYS > 180 AND A.OD_DAYS <= 270 THEN
          'S63_I_1.3.5.H.2025'
         WHEN A.OD_DAYS > 270 AND A.OD_DAYS <= 360 THEN
          'S63_I_1.3.6.H.2025'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.7.H.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       C.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND A.ACCT_TYP LIKE '0102%'
         AND A.CANCEL_FLG <> 'Y'
         AND C.OPERATE_CUST_TYPE = 'B'
            --- AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND A.OD_FLG = 'Y'
         AND A.OD_DAYS > 0
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.4中长期贷款 开始';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ---------------------1.4中长期贷款 ADD 20200114 LJP--------------------------------------------------
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）

       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.CORP_SCALE = 'B' THEN
          'S63_I_1.4.A'
         WHEN B.CORP_SCALE = 'M' THEN
          'S63_I_1.4.B'
         WHEN B.CORP_SCALE = 'S' THEN
          'S63_I_1.4.C'
         WHEN B.CORP_SCALE = 'T' THEN
          'S63_I_1.4.D'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改,从此视图取。
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            -- AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            ---  AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) > 12
         AND (A.ACCT_TYP NOT LIKE '0101%' AND A.ACCT_TYP NOT LIKE '0103%' AND
             A.ACCT_TYP NOT LIKE '0104%' AND A.ACCT_TYP NOT LIKE '0199%')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
      ;
    COMMIT;

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18)
    --   1.4中长期贷款

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'S63_I_1.4.F' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       nvl(B.CUST_NAM, c.cust_nam) AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       case
         when c.operate_cust_type = 'A' OR B.CUST_TYP = '3' THEN
          '个体工商户'
         when c.operate_cust_type = 'B' then
          '小微企业主'
         when c.operate_cust_type = 'Z' then
          '其他个人'
       END
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改,从此视图取。
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND A.ACCT_TYP LIKE '0102%'
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            --  AND T.INLANDORRSHORE_FLG = 'Y' --m2
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) > 12
            --- AND MONTHS_BETWEEN(A.ACTUAL_MATURITY_DT, A.DRAWDOWN_DT) > 12 --m5
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
      ;
    COMMIT;
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）

       )
    --   1.4中长期贷款

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'S63_I_1.4.G' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       nvl(B.CUST_NAM, c.cust_nam) AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改,从此视图取。
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND A.ACCT_TYP LIKE '0102%'
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (C.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3')
            --AND T.INLANDORRSHORE_FLG = 'Y' --m2
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) > 12
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
      ;
    COMMIT;
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）

       )
    --   1.4中长期贷款

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'S63_I_1.4.H' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       c.cust_nam AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改,从此视图取。
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.ACCT_TYP LIKE '0102%'
         AND C.OPERATE_CUST_TYPE = 'B'
            --  AND T.INLANDORRSHORE_FLG = 'Y' --m2
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) > 12
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
      ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.4中长期贷款 完成';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ---------------------1.4中长期贷款 ADD 20200114 LJP--------------------------------------------------

    ----------------------------------------------------------------------- 3.表内其他授信余额--------------------------------------------------------------------------
  

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据3.表内其他授信余额至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ---2025年新制度指标
    --其中：3.1债券投资
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（账号）
       COL_2, -- 字段2（债券编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（余额）
       COL_6, -- 字段6,-- (债券名称)
       COL_17 --企业规模

       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             CASE
               WHEN nvl(C.CORP_SIZE, C1.CORP_SCALE) in ('01', 'B') THEN
                'S63_I_3.1.A.2025'
               WHEN nvl(C.CORP_SIZE, C1.CORP_SCALE) in ('02', 'M') THEN
                'S63_I_3.1.B.2025'
               WHEN nvl(C.CORP_SIZE, C1.CORP_SCALE) in ('S', '03') THEN
                'S63_I_3.1.C.2025'
               WHEN nvl(C.CORP_SIZE, C1.CORP_SCALE) in ('04', 'T') THEN
                'S63_I_3.1.D.2025'
             END AS ITEM_NUM,
             'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
             A.ACCT_NUM as COL_1, --账号
             B.STOCK_CD as COL_2, --债券编号
             A.CUST_ID, --客户号
             C1.CUST_NAM, --客户名
             (NVL(A.PRINCIPAL_BALANCE, 0) * U.CCY_RATE) COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
             b.STOCK_NAM as COL_6, -- 债券名称
             CASE
               WHEN nvl(C.CORP_SIZE, C1.CORP_SCALE) in ('01', 'B') THEN
                '大型'
               WHEN nvl(C.CORP_SIZE, C1.CORP_SCALE) in ('02', 'M') THEN
                '中型'
               WHEN nvl(C.CORP_SIZE, C1.CORP_SCALE) in ('S', '03') THEN
                '小型'
               WHEN nvl(C.CORP_SIZE, C1.CORP_SCALE) in ('04', 'T') THEN
                '微型'
             END COL_7 --  企业规模
        FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_EXTERNAL_INFO C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C1
          ON A.CUST_ID = C1.CUST_ID
         AND C1.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00' ---投资业务品种
         AND B.STOCK_ASSET_TYPE IS NULL
         AND B.ISSUER_INLAND_FLG = 'Y'
         AND A.PRINCIPAL_BALANCE <> 0
         AND B.STOCK_PRO_TYPE in ('D01', 'D04', 'D05', 'D02') /*D01 短期融资债券\超短期融资券  D04 企业债 D05 公司债 D02 中期票据*/
      ;
    commit;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ----------------------------------------------------------------------- 5.3授信户数--------------------------------------------------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据5.3授信户数至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ---alter by shiyu 20230508 授信户数机构存在在分行机构授信数据,统计时将机构全部截取后两位为00统计
    --modi by djh 20230828  法人综授,大为哥口径确定修改
    /*单位客户及单位名称个体工商户授信协议是否有效状态为‘是’客户计1户
    客户存在表内贷款或表外授信业务且授信协议是否有效状态为‘否’计1户*/
    --20170814 MANAN 修改 原取数错误
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       COL_3, --客户号
       COL_4, --客户名称
       COL_5, --贷款余额/客户数/放款金额
       COL_10 --机构名称
       )
    ---alter by shiyu 20230508 授信户数机构存在在分行机构授信数据,统计时将机构全部截取后两位为00统计
      SELECT 
       I_DATADATE AS DATA_DATE,
       --TMP.ORG_NUM,
       CASE /*WHEN SUBSTR(A.ORG_NUM,1,2) IN ('08','10','11','13') THEN SUBSTR(A.ORG_NUM,1,2)||'0000'*/ --20191012 LJP MODIFY 机构汇总数据缺失,先汇支行再汇分行
         when TMP.ORG_NUM = '009813' then
          '130000'
         WHEN TMP.org_num LIKE '0601%' THEN
          '060300'
         when (SUBSTR(TMP.org_num, 3, 4) = '9801') or
              SUBSTR(TMP.org_num, 1, 4) = '0098' or
              (SUBSTR(TMP.org_num, 3, 2) = '98') then
          TMP.org_num
         ELSE
          SUBSTR(TMP.ORG_NUM, 1, 4) || '00'
       END org_num,
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          'S63_I_5.3.A.2014'
         WHEN C.CORP_SCALE = 'M' THEN
          'S63_I_5.3.B.2014'
         WHEN C.CORP_SCALE = 'S' THEN
          'S63_I_5.3.C.2014'
         WHEN C.CORP_SCALE = 'T' THEN
          'S63_I_5.3.D.2014'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       TMP.CUST_ID AS COL_3, --客户号
       C.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null as COL_10 --机构名称

        FROM (SELECT T.ORG_NUM, T.CUST_ID
                FROM (SELECT T.ORG_NUM, T.CUST_ID
                        FROM SMTMODS_L_AGRE_CREDITLINE T
                       INNER JOIN SMTMODS_L_CUST_C C
                          ON T.CUST_ID = C.CUST_ID
                         AND C.DATA_DATE = I_DATADATE
                         AND UPPER(T.FACILITY_STS) = 'Y'
                         AND T.FACILITY_TYP IN ('2', '4', '1') ----需求编号：JLBA202504160004_关于吉林银行修改单一客户授信逻辑的需求 提出人：苏桐  上线时间：20250627 修改人：石雨    修改内容：客户授信逻辑
                      --AND T.ORG_NUM NOT LIKE '5100%' --M10
                       WHERE T.DATA_DATE = I_DATADATE
                       GROUP BY T.ORG_NUM, T.CUST_ID
                      UNION ALL
                      SELECT T.ORG_NUM, T.CUST_ID
                        FROM SMTMODS_L_AGRE_CREDITLINE T
                       INNER JOIN (SELECT CUST_ID
                                    FROM (SELECT A1.CUST_ID
                                            FROM SMTMODS_L_ACCT_OBS_LOAN A1
                                           WHERE A1.BALANCE <> 0
                                             AND A1.DATA_DATE = I_DATADATE
                                           GROUP BY A1.CUST_ID
                                          UNION ALL
                                          SELECT A.CUST_ID
                                            FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
                                           WHERE A.ACCT_TYP NOT LIKE '90%'
                                             AND A.DATA_DATE = I_DATADATE
                                             AND A.CANCEL_FLG <> 'Y'
                                             AND A.ACCT_STS <> '3'
                                             AND A.LOAN_ACCT_BAL <> 0
                                             AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN
                                                 ('130102', '130105') --m14  不含转贴现
                                             AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
                                           GROUP BY A.CUST_ID)
                                   GROUP BY CUST_ID) T1
                          ON T1.CUST_ID = T.CUST_ID
                       WHERE T.DATA_DATE = I_DATADATE
                         AND UPPER(T.FACILITY_STS) = 'N'
                         AND T.FACILITY_TYP IN ('2', '4', '1') ----需求编号：JLBA202504160004_关于吉林银行修改单一客户授信逻辑的需求 提出人：苏桐  上线时间：20250627 修改人：石雨    修改内容：客户授信逻辑
                      --AND T.ORG_NUM NOT LIKE '5100%' --M10
                       GROUP BY T.ORG_NUM, T.CUST_ID
                      UNION ALL --补充客户授信与业务机构不属于同一家机构,该客户授信机构及业务机构都统计进来
                      SELECT ORG_NUM, CUST_ID
                        FROM (SELECT A1.ORG_NUM, A1.CUST_ID
                                FROM SMTMODS_L_ACCT_OBS_LOAN A1
                               WHERE A1.BALANCE <> 0
                                 AND A1.DATA_DATE = I_DATADATE
                               GROUP BY A1.ORG_NUM, A1.CUST_ID
                              UNION ALL
                              SELECT A.ORG_NUM, A.CUST_ID
                                FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
                               WHERE A.ACCT_TYP NOT LIKE '90%'
                                 AND A.DATA_DATE = I_DATADATE
                                 AND A.CANCEL_FLG <> 'Y'
                                 AND A.ACCT_STS <> '3'
                                 AND A.LOAN_ACCT_BAL <> 0
                                 AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN
                                     ('130102', '130105') --m14  不含转贴现
                                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
                               GROUP BY A.ORG_NUM, A.CUST_ID)
                       GROUP BY ORG_NUM, CUST_ID) T
               GROUP BY T.ORG_NUM, T.CUST_ID) TMP

        LEFT JOIN SMTMODS_L_CUST_C C
          ON TMP.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        
       WHERE SUBSTR(C.CUST_TYP, 1, 1) IN ('1', '0') --M4
         AND C.CORP_SCALE IN ('B', 'M', 'S', 'T')
       GROUP BY CASE /*WHEN SUBSTR(A.ORG_NUM,1,2) IN ('08','10','11','13') THEN SUBSTR(A.ORG_NUM,1,2)||'0000'*/ --20191012 LJP MODIFY 机构汇总数据缺失,先汇支行再汇分行
                  when TMP.ORG_NUM = '009813' then
                   '130000'
                  WHEN TMP.org_num LIKE '0601%' THEN
                   '060300'
                  when (SUBSTR(TMP.org_num, 3, 4) = '9801') or
                       SUBSTR(TMP.org_num, 1, 4) = '0098' or
                       (SUBSTR(TMP.org_num, 3, 2) = '98') then
                   TMP.org_num

                  ELSE
                   SUBSTR(TMP.ORG_NUM, 1, 4) || '00'
                END,
                CASE
                  WHEN C.CORP_SCALE = 'B' THEN
                   'S63_I_5.3.A.2014'
                  WHEN C.CORP_SCALE = 'M' THEN
                   'S63_I_5.3.B.2014'
                  WHEN C.CORP_SCALE = 'S' THEN
                   'S63_I_5.3.C.2014'
                  WHEN C.CORP_SCALE = 'T' THEN
                   'S63_I_5.3.D.2014'
                END,
                TMP.CUST_ID,
                C.CUST_NAM,
                null;

    COMMIT;

    --modi by djh 20230828  法人综授,大为哥口径确定修改
    /*  自然人客户合同状态为‘有效’且贷款未结清的计1户
    */
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       COL_3, --客户号
       COL_4, --客户名称
       COL_5, --贷款余额/客户数/放款金额
       COL_10 --机构名称
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       --TMP.ORG_NUM,
       CASE /*WHEN SUBSTR(A.ORG_NUM,1,2) IN ('08','10','11','13') THEN SUBSTR(A.ORG_NUM,1,2)||'0000'*/ --20191012 LJP MODIFY 机构汇总数据缺失,先汇支行再汇分行
         when TMP.ORG_NUM = '009813' then
          '130000'
         WHEN TMP.org_num LIKE '0601%' THEN
          '060300'
         when (SUBSTR(TMP.org_num, 3, 4) = '9801') or
              SUBSTR(TMP.org_num, 1, 4) = '0098' or
              (SUBSTR(TMP.org_num, 3, 2) = '98')

          then
          TMP.org_num
         ELSE
          SUBSTR(TMP.ORG_NUM, 1, 4) || '00'
       END org_num,
       'S63_I_5.3.F.2014' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       TMP.CUST_ID AS COL_3, --客户号
       C.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null as COL_10 --机构名称
        FROM (SELECT A.CUST_ID,
                     A.CORP_SCALE,
                     --  A.INLANDORRSHORE_FLG,
                     A.CUST_TYP,
                     A.ORG_NUM,
                     A.DATA_DATE,
                     A.ACCT_TYP
                FROM (SELECT LOAN.CUST_ID,
                             LOAN.LOAN_ACCT_BAL,
                             LOAN.DATA_DATE,
                             LOAN.ACCT_TYP,
                             C.CORP_SCALE,
                             LOAN.ORG_NUM,
                             T.INLANDORRSHORE_FLG,
                             C.CUST_TYP
                        FROM (SELECT A.CUST_ID,
                                     A.LOAN_ACCT_BAL,
                                     A.DATA_DATE,
                                     A.ACCT_TYP,
                                     A.ORG_NUM
                                FROM SMTMODS_L_AGRE_LOAN_CONTRACT B
                               INNER JOIN (SELECT A.CUST_ID,
                                                 SUM(A.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL,
                                                 A.DATA_DATE,
                                                 A.ACCT_TYP,
                                                 A.ORG_NUM,
                                                 A.ACCT_NUM
                                            FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
                                           WHERE A.ACCT_TYP NOT LIKE '90%'
                                             AND A.CANCEL_FLG <> 'Y'
                                             AND A.DATA_DATE = I_DATADATE
                                             AND A.ACCT_STS <> '3'
                                             AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN
                                                 ('130102', '130105') --m14  不含转贴现
                                             AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
                                          --AND A.ORG_NUM NOT LIKE '5100%'
                                           GROUP BY A.CUST_ID,
                                                    A.DATA_DATE,
                                                    A.ACCT_TYP,
                                                    A.ORG_NUM,
                                                    A.ACCT_NUM) A
                                  ON A.ACCT_NUM = B.CONTRACT_NUM
                               WHERE B.DATA_DATE = I_DATADATE
                                 AND B.ACCT_STS = '1' --有效

                              ) LOAN
                       INNER JOIN SMTMODS_L_CUST_ALL T
                          ON T.CUST_ID = LOAN.CUST_ID
                         AND T.DATA_DATE = I_DATADATE
                        LEFT JOIN SMTMODS_L_CUST_C C
                          ON T.CUST_ID = C.CUST_ID
                         AND C.DATA_DATE = I_DATADATE) A
               WHERE A.LOAN_ACCT_BAL <> 0
              -----需求编号：JLBA202504160004_关于吉林银行修改单一客户授信逻辑的需求 提出人：苏桐  上线时间：20250627 修改人：石雨    修改内容：客户授信逻辑
              UNION ALL
              SELECT CR.CUST_ID,
                     C.CORP_SCALE,
                     C.CUST_TYP,
                     CR.ORG_NUM,
                     CR.DATA_DATE,
                     '0102' ACCT_TYP
                FROM SMTMODS_L_AGRE_CREDITLINE CR
                LEFT JOIN SMTMODS_L_CUST_C C
                  ON CR.DATA_DATE = C.DATA_DATE
                 AND CR.CUST_ID = C.CUST_ID
                LEFT JOIN SMTMODS_L_CUST_P P
                  ON CR.DATA_DATE = P.DATA_DATE
                 AND CR.CUST_ID = P.CUST_ID
               WHERE CR.DATA_DATE = I_DATADATE
                 AND CR.FACILITY_STS = 'Y'
                 AND (CR.FACILITY_BUSI_TYP = '10' OR
                     ((C.CUST_TYP = '3' OR P.CUST_ID IS NOT NULL) AND
                     CR.FACILITY_BUSI_TYP = '4'))
               GROUP BY CR.CUST_ID,
                        C.CORP_SCALE,
                        C.CUST_TYP,
                        CR.ORG_NUM,
                        CR.DATA_DATE

              ) TMP
        
        LEFT JOIN SMTMODS_L_CUST_ALL C
          ON TMP.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE -- TMP.INLANDORRSHORE_FLG = 'Y' AND --M2
       TMP.ACCT_TYP LIKE '0102%'
       AND TMP.DATA_DATE = I_DATADATE
       GROUP BY CASE /*WHEN SUBSTR(A.ORG_NUM,1,2) IN ('08','10','11','13') THEN SUBSTR(A.ORG_NUM,1,2)||'0000'*/ --20191012 LJP MODIFY 机构汇总数据缺失,先汇支行再汇分行
                  when TMP.ORG_NUM = '009813' then
                   '130000'
                  WHEN TMP.org_num LIKE '0601%' THEN
                   '060300'
                  when (SUBSTR(TMP.org_num, 3, 4) = '9801') or
                       SUBSTR(TMP.org_num, 1, 4) = '0098' or
                       (SUBSTR(TMP.org_num, 3, 2) = '98') then
                   TMP.org_num
                  ELSE
                   SUBSTR(TMP.ORG_NUM, 1, 4) || '00'
                END,
                TMP.CUST_ID,
                C.CUST_NAM,
                null;
    COMMIT;

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       COL_3, --客户号
       COL_4, --客户名称
       COL_5, --贷款余额/客户数/放款金额
       COL_10 --机构名称
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       --TMP.ORG_NUM,
       CASE /*WHEN SUBSTR(A.ORG_NUM,1,2) IN ('08','10','11','13') THEN SUBSTR(A.ORG_NUM,1,2)||'0000'*/ --20191012 LJP MODIFY 机构汇总数据缺失,先汇支行再汇分行
         when TMP.ORG_NUM = '009813' then
          '130000'
         WHEN TMP.org_num LIKE '0601%' THEN
          '060300'
         when (SUBSTR(TMP.org_num, 3, 4) = '9801') or
              SUBSTR(TMP.org_num, 1, 4) = '0098' or
              (SUBSTR(TMP.org_num, 3, 2) = '98') then
          TMP.org_num
         ELSE
          SUBSTR(TMP.ORG_NUM, 1, 4) || '00'
       END org_num,
       CASE
         WHEN (TMP.OPERATE_CUST_TYPE = 'A' OR TMP.CUST_TYP = '3') THEN
          'S63_I_5.3.G.2014'
         WHEN TMP.OPERATE_CUST_TYPE = 'B' THEN
          'S63_I_5.3.H.2014'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       TMP.CUST_ID AS COL_3, --客户号
       C.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null as COL_10 --机构名称
        FROM (SELECT A.CUST_ID,
                     A.CORP_SCALE,
                     -- A.INLANDORRSHORE_FLG,
                     A.CUST_TYP,
                     A.ORG_NUM,
                     A.DATA_DATE,
                     A.ACCT_TYP,
                     A.OPERATE_CUST_TYPE
                FROM (SELECT LOAN.CUST_ID,
                             LOAN.LOAN_ACCT_BAL,
                             LOAN.DATA_DATE,
                             LOAN.ACCT_TYP,
                             C.CORP_SCALE,
                             LOAN.ORG_NUM,
                             --T.INLANDORRSHORE_FLG,
                             C.CUST_TYP,
                             LCP.OPERATE_CUST_TYPE
                        FROM (SELECT A.CUST_ID,
                                     A.LOAN_ACCT_BAL,
                                     A.DATA_DATE,
                                     A.ACCT_TYP,
                                     A.ORG_NUM
                                FROM SMTMODS_L_AGRE_LOAN_CONTRACT B
                               INNER JOIN (SELECT A.CUST_ID,
                                                 SUM(A.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL,
                                                 A.DATA_DATE,
                                                 A.ACCT_TYP,
                                                 A.ORG_NUM,
                                                 A.ACCT_NUM
                                            FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
                                           WHERE A.ACCT_TYP NOT LIKE '90%'
                                             AND A.CANCEL_FLG <> 'Y'
                                             AND A.DATA_DATE = I_DATADATE
                                             AND A.ACCT_STS <> '3'
                                             AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN
                                                 ('130102', '130105') --m14  不含转贴现
                                             AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
                                          --AND A.ORG_NUM NOT LIKE '5100%'
                                           GROUP BY A.CUST_ID,
                                                    A.DATA_DATE,
                                                    A.ACCT_TYP,
                                                    A.ORG_NUM,
                                                    A.ACCT_NUM) A
                                  ON A.ACCT_NUM = B.CONTRACT_NUM
                               WHERE B.DATA_DATE = I_DATADATE
                                 AND B.ACCT_STS = '1' --有效
                              ) LOAN
                        LEFT JOIN SMTMODS_L_CUST_C C
                          ON LOAN.CUST_ID = C.CUST_ID
                         AND C.DATA_DATE = I_DATADATE
                        LEFT JOIN SMTMODS_L_CUST_P LCP
                          ON LOAN.CUST_ID = LCP.CUST_ID
                         AND LCP.DATA_DATE = I_DATADATE) A
               WHERE A.LOAN_ACCT_BAL <> 0
              -----需求编号：JLBA202504160004_关于吉林银行修改单一客户授信逻辑的需求 提出人：苏桐  上线时间：20250627 修改人：石雨    修改内容：客户授信逻辑
              UNION ALL
              SELECT CR.CUST_ID,
                     C.CORP_SCALE,
                     C.CUST_TYP,
                     CR.ORG_NUM,
                     CR.DATA_DATE,
                     '0102' ACCT_TYP,
                     P.OPERATE_CUST_TYPE
                FROM SMTMODS_L_AGRE_CREDITLINE CR
                LEFT JOIN SMTMODS_L_CUST_C C
                  ON CR.DATA_DATE = C.DATA_DATE
                 AND CR.CUST_ID = C.CUST_ID
                LEFT JOIN SMTMODS_L_CUST_P P
                  ON CR.DATA_DATE = P.DATA_DATE
                 AND CR.CUST_ID = P.CUST_ID
               WHERE CR.DATA_DATE = I_DATADATE
                 AND CR.FACILITY_STS = 'Y'
                 AND (CR.FACILITY_BUSI_TYP = '10' OR
                     ((C.CUST_TYP = '3' OR P.CUST_ID IS NOT NULL) AND
                     CR.FACILITY_BUSI_TYP = '4'))
               GROUP BY CR.CUST_ID,
                        C.CORP_SCALE,
                        C.CUST_TYP,
                        CR.ORG_NUM,
                        CR.DATA_DATE,
                        P.OPERATE_CUST_TYPE

              ) TMP
        
        LEFT JOIN SMTMODS_L_CUST_ALL C
          ON TMP.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE --TMP.INLANDORRSHORE_FLG = 'Y' AND
       TMP.ACCT_TYP LIKE '0102%'
       AND TMP.DATA_DATE = I_DATADATE
       AND (TMP.OPERATE_CUST_TYPE IN ('A', 'B') OR TMP.CUST_TYP = '3')
       GROUP BY CASE /*WHEN SUBSTR(A.ORG_NUM,1,2) IN ('08','10','11','13') THEN SUBSTR(A.ORG_NUM,1,2)||'0000'*/ --20191012 LJP MODIFY 机构汇总数据缺失,先汇支行再汇分行
                  when TMP.ORG_NUM = '009813' then
                   '130000'
                  WHEN TMP.org_num LIKE '0601%' THEN
                   '060300'
                  when (SUBSTR(TMP.org_num, 3, 4) = '9801') or
                       SUBSTR(TMP.org_num, 1, 4) = '0098' or
                       (SUBSTR(TMP.org_num, 3, 2) = '98') then
                   TMP.org_num
                  ELSE
                   SUBSTR(TMP.ORG_NUM, 1, 4) || '00'
                END,
                CASE
                  WHEN (TMP.OPERATE_CUST_TYPE = 'A' OR TMP.CUST_TYP = '3') THEN
                   'S63_I_5.3.G.2014'
                  WHEN TMP.OPERATE_CUST_TYPE = 'B' THEN
                   'S63_I_5.3.H.2014'
                END,
                TMP.CUST_ID,
                C.CUST_NAM,
                null;
    COMMIT;
    ----------------------------------------------------------------------- 5.3.1其中：贷款户数--------------------------------------------------------------------------
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据 5.3.1其中：贷款户数至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --20170814 MANAN 修改,原取数表出的数据不对
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       COL_3, --客户号
       COL_4, --客户名称
       COL_5, --贷款余额/客户数/放款金额
       COL_10 --机构名称
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_5.1.A'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_5.1.B'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_5.1.C'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_5.1.D'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.CUST_ID AS COL_3, --客户号
       A.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null as COL_10 --机构名称
        FROM (SELECT LOAN.CUST_ID,
                     LOAN.LOAN_ACCT_BAL,
                     LOAN.DATA_DATE,
                     LOAN.ACCT_TYP,
                     C.CORP_SCALE,
                     LOAN.ORG_NUM,
                     C.CUST_TYP,
                     T.INLANDORRSHORE_FLG,
                     T.CUST_NAM
                FROM (SELECT A.CUST_ID,
                             A.LOAN_ACCT_BAL,
                             A.DATA_DATE,
                             A.ACCT_TYP,
                             A.ORG_NUM
                        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
                       WHERE A.ACCT_TYP NOT LIKE '90%'
                         AND A.CANCEL_FLG <> 'Y'
                         AND A.DATA_DATE = I_DATADATE
                         AND A.ACCT_STS <> '3'
                         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN
                             ('130102', '130105') --m14  不含转贴现
                         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
                      ) LOAN
               INNER JOIN SMTMODS_L_CUST_ALL T
                  ON T.CUST_ID = LOAN.CUST_ID
                 AND T.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_CUST_C C
                  ON T.CUST_ID = C.CUST_ID
                 AND C.DATA_DATE = I_DATADATE) A
       
       WHERE --A.INLANDORRSHORE_FLG = 'Y' --M2
      --A.CUST_TYP = '11'
       substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
       AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
       AND A.DATA_DATE = I_DATADATE
       AND A.LOAN_ACCT_BAL <> 0
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.CORP_SCALE = 'B' THEN
                   'S63_I_5.1.A'
                  WHEN A.CORP_SCALE = 'M' THEN
                   'S63_I_5.1.B'
                  WHEN A.CORP_SCALE = 'S' THEN
                   'S63_I_5.1.C'
                  WHEN A.CORP_SCALE = 'T' THEN
                   'S63_I_5.1.D'
                END,
                A.CUST_ID,
                A.CUST_NAM,
                null;
    COMMIT;

    --ZHOUJINGKUN UPDATE 20210329   松原分行提升个人经验性贷款户数不准确

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       COL_3, --客户号
       COL_4, --客户名称
       COL_5, --贷款余额/客户数/放款金额
       COL_10 --机构名称
       )

      SELECT I_DATADATE AS DATA_DATE,
             B.ORG_NUM,
             'S63_I_5.1.F' AS ITEM_NUM,
             'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
             B.CUST_ID AS COL_3, --客户号
             B.CUST_NAM AS COL_4, --客户名称
             1 AS COL_5, --贷款余额/客户数/放款金额
             null as COL_10 --机构名称
        FROM (

              SELECT

               A.ORG_NUM, C.CUST_ID, C.CUST_NAM
                FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
               INNER JOIN SMTMODS_L_CUST_ALL C
                  ON A.DATA_DATE = C.DATA_DATE
                 AND A.CUST_ID = C.CUST_ID
               WHERE A.ACCT_TYP LIKE '0102%' --个人经营性标识
                 AND A.DATA_DATE = I_DATADATE
                 AND A.CANCEL_FLG <> 'Y'
                 AND A.LOAN_ACCT_BAL > 0 --20211102 LXA ADD 和大为哥确认只取贷款余额大于0的户数
                 AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
               GROUP BY A.ORG_NUM, C.CUST_ID, C.CUST_NAM) B
       
       GROUP BY B.ORG_NUM, B.CUST_ID, B.CUST_NAM, null;

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       COL_3, --客户号
       COL_4, --客户名称
       COL_5, --贷款余额/客户数/放款金额
       COL_10 --机构名称
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'S63_I_5.1.G' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.CUST_ID AS COL_3, --客户号
       A.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null as COL_10 --机构名称
        FROM (SELECT LOAN.CUST_ID,
                     LOAN.LOAN_ACCT_BAL,
                     LOAN.DATA_DATE,
                     LOAN.ACCT_TYP,
                     LCP.OPERATE_CUST_TYPE,
                     C.CUST_TYP,
                     LOAN.ORG_NUM,
                     NVL(C.CUST_NAM, LCP.CUST_NAM) CUST_NAM
                FROM (SELECT A.CUST_ID,
                             A.LOAN_ACCT_BAL,
                             A.DATA_DATE,
                             A.ACCT_TYP,
                             A.ORG_NUM
                        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
                       WHERE A.ACCT_TYP NOT LIKE '90%'
                         AND A.CANCEL_FLG <> 'Y'
                         AND A.DATA_DATE = I_DATADATE
                         AND A.ACCT_STS <> '3'
                         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN
                             ('130102', '130105') --m14  不含转贴现
                         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
                      ) LOAN
                LEFT JOIN SMTMODS_L_CUST_C C
                  ON LOAN.CUST_ID = C.CUST_ID
                 AND C.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_CUST_P LCP
                  ON LOAN.CUST_ID = LCP.CUST_ID
                 AND LCP.DATA_DATE = I_DATADATE) A
       
       WHERE -- A.INLANDORRSHORE_FLG = 'Y' AND --M2
       (A.OPERATE_CUST_TYPE = 'A' OR A.CUST_TYP = '3')
       AND A.DATA_DATE = I_DATADATE
       AND A.LOAN_ACCT_BAL > 0
       AND A.ACCT_TYP LIKE '0102%'
       GROUP BY A.ORG_NUM, a.CUST_ID, a.CUST_NAM, null;
    COMMIT;

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       COL_3, --客户号
       COL_4, --客户名称
       COL_5, --贷款余额/客户数/放款金额
       COL_10 --机构名称
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'S63_I_5.1.H' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.CUST_ID AS COL_3, --客户号
       A.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null as COL_10 --机构名称
        FROM (SELECT LOAN.CUST_ID,
                     LOAN.LOAN_ACCT_BAL,
                     LOAN.DATA_DATE,
                     LOAN.ACCT_TYP,

                     LCP.OPERATE_CUST_TYPE,
                     LOAN.ORG_NUM,
                     NVL(C.CUST_NAM, LCP.CUST_NAM) CUST_NAM
                FROM (SELECT A.CUST_ID,
                             A.LOAN_ACCT_BAL,
                             A.DATA_DATE,
                             A.ACCT_TYP,
                             A.ORG_NUM
                        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
                       WHERE A.ACCT_TYP NOT LIKE '90%'
                         AND A.CANCEL_FLG <> 'Y'
                         AND A.DATA_DATE = I_DATADATE
                         AND A.ACCT_STS <> '3'
                         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN
                             ('130102', '130105') --m14  不含转贴现
                         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
                      ) LOAN

                LEFT JOIN SMTMODS_L_CUST_C C
                  ON LOAN.CUST_ID = C.CUST_ID
                 AND C.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_CUST_P LCP
                  ON LOAN.CUST_ID = LCP.CUST_ID
                 AND LCP.DATA_DATE = I_DATADATE) A
       
       WHERE -- A.INLANDORRSHORE_FLG = 'Y' AND --M2
       A.OPERATE_CUST_TYPE = 'B'
       AND A.DATA_DATE = I_DATADATE
       AND A.LOAN_ACCT_BAL > 0
       AND A.ACCT_TYP LIKE '0102%'
       GROUP BY A.ORG_NUM, a.CUST_ID, a.CUST_NAM, null;
    --修改完成
    COMMIT;
    ----------------------------------------------------------------------- 7.无还本续贷情况--------------------------------------------------------------------------
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据 7.无还本续贷情况 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --7.1无还本续贷贷款余额  大、中、小、微
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）

       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_7.1.A'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_7.1.B'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_7.1.C'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_7.1.D'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0)) +
       (NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0)) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE T.DATA_DATE = I_DATADATE
            --AND T.LOAN_KIND_CD = '6' --借续贷
            -- alter by  shiyu 230202 6无还本续贷,7 再融资
         AND T.LOAN_KIND_CD in ('6', '7')
         AND T.CANCEL_FLG <> 'Y'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND A.CUST_TYP NOT IN ('2', '4', '5') --政府机关、社会团体、事业单位
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;
    -- 7.1无还本续贷贷款余额 个人经营性
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'S63_I_7.1.F' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM, B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0)) +
       (NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0)) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN
          '个体工商户'
         WHEN A.OPERATE_CUST_TYPE = 'A' THEN
          '小微企业主'
         WHEN A.OPERATE_CUST_TYPE = 'Z' THEN
          '其他个人'
       end COL_18
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
            --AND T.LOAN_KIND_CD = '6' --借续贷
            -- alter by  shiyu 230202 6无还本续贷,7 再融资
         AND T.LOAN_KIND_CD in ('6', '7')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    COMMIT;

    --  7.1无还本续贷贷款余额 个体工商户、小微企业主
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN (A.OPERATE_CUST_TYPE = 'A' OR C.CUST_TYP = '3') THEN
          'S63_I_7.1.G'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN
          'S63_I_7.1.H'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM, c.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0)) +
       (NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0)) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.DATA_DATE = C.DATA_DATE
         AND T.CUST_ID = C.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
            --AND T.LOAN_KIND_CD = '6' --借续贷
            -- alter by  shiyu 230202 6无还本续贷,7 再融资
         AND T.LOAN_KIND_CD in ('6', '7')
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;

    COMMIT;

    --7.2当年无还本续贷贷款累放金额  大、中、小、微

        INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_7.2.A'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_7.2.B'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_7.2.C'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_7.2.D'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(T.DRAWDOWN_AMT * U.CCY_RATE, 0)) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE T.DATA_DATE = I_DATADATE
            -- AND T.LOAN_KIND_CD = '6' --借续贷
            -- alter by  shiyu 230202 6无还本续贷,7 再融资
         AND T.LOAN_KIND_CD in ('6', '7')
         AND T.CANCEL_FLG <> 'Y'
         AND T.DRAWDOWN_DT >= TRUNC(D_DATADATE_CCY, 'Y') --发生
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND A.CUST_TYP NOT IN ('2', '4', '5') --政府机关、社会团体、事业单位
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;

    COMMIT;
    -- 7.2当年无还本续贷贷款累放金额 个人经营性
     INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'S63_I_7.2.F' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (NVL(T.DRAWDOWN_AMT * U.CCY_RATE, 0)) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN
          '个体工商户'
         WHEN A.OPERATE_CUST_TYPE = 'A' THEN
          '小微企业主'
         WHEN A.OPERATE_CUST_TYPE = 'Z' THEN
          '其他个人'
       end COL_18
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
        LEFT JOIN  SMTMODS_L_CUST_C B
          ON T.cust_id =B.CUST_ID
          AND B.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
            -- AND T.LOAN_KIND_CD = '6' --借续贷
            -- alter by  shiyu 230202 6无还本续贷,7 再融资
         AND T.LOAN_KIND_CD in ('6', '7')
         AND T.CANCEL_FLG <> 'Y'
         AND T.DRAWDOWN_DT >= TRUNC(D_DATADATE_CCY, 'Y') --发生
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;

    COMMIT;
    --  7.2当年无还本续贷贷款累放金额 个体工商户、小微企业主
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN (A.OPERATE_CUST_TYPE = 'A' OR C.CUST_TYP = '3') THEN
          'S63_I_7.2.G'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN
          'S63_I_7.2.H'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (NVL(T.DRAWDOWN_AMT * U.CCY_RATE, 0)) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.DATA_DATE = C.DATA_DATE
         AND T.CUST_ID = C.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
            --AND T.LOAN_KIND_CD = '6' --借续贷
            -- alter by  shiyu 230202 6无还本续贷,7 再融资
         AND T.LOAN_KIND_CD in ('6', '7')
         AND T.CANCEL_FLG <> 'Y'
         AND T.DRAWDOWN_DT >= TRUNC(D_DATADATE_CCY, 'Y') --发生
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;

    COMMIT;

    --7.3无还本续贷贷款余额户数 大、中、小、微
      INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       COL_3, --客户号
       COL_4, --客户名称
       COL_5, --贷款余额/客户数/放款金额
       COL_10 --机构名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       G.ORG_NUM,
       CASE
         WHEN G.CORP_SCALE = 'B' THEN
          'S63_I_7.3.A.2023'
         WHEN G.CORP_SCALE = 'M' THEN
          'S63_I_7.3.B.2023'
         WHEN G.CORP_SCALE = 'S' THEN
          'S63_I_7.3.C.2023'
         WHEN G.CORP_SCALE = 'T' THEN
          'S63_I_7.3.D.2023'
       END AS ITEM_NUM,
        'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       G.CUST_ID AS COL_3, --客户号
       G.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null AS COL_10 --机构名称
        FROM (SELECT DISTINCT T.ORG_NUM, A.CUST_ID AS CUST_ID, CORP_SCALE,A.CUST_NAM
                FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
                LEFT JOIN SMTMODS_L_CUST_C A
                  ON T.DATA_DATE = A.DATA_DATE
                 AND T.CUST_ID = A.CUST_ID
               WHERE T.DATA_DATE = I_DATADATE
                    -- AND T.LOAN_KIND_CD = '6' --借续贷
                    -- alter by  shiyu 230202 6无还本续贷,7 再融资
                 AND T.LOAN_KIND_CD in ('6', '7')
                 AND T.CANCEL_FLG <> 'Y'
                 AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
                 AND T.LOAN_ACCT_BAL <> 0 --ALTER BY WJB 20230202 计算户数的时候不要贷款余额等于0的
                 AND A.CUST_TYP NOT IN ('2', '4', '5')
                 AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
                 AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
              ) G --政府机关、社会团体、事业单位
            
      GROUP BY G.ORG_NUM,CASE
         WHEN G.CORP_SCALE = 'B' THEN
          'S63_I_7.3.A.2023'
         WHEN G.CORP_SCALE = 'M' THEN
          'S63_I_7.3.B.2023'
         WHEN G.CORP_SCALE = 'S' THEN
          'S63_I_7.3.C.2023'
         WHEN G.CORP_SCALE = 'T' THEN
          'S63_I_7.3.D.2023'
       END,G.CUST_ID,G.CUST_NAM,null ;
    COMMIT;

    -- 7.3无还本续贷贷款余额户数  个人经营性
     INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       COL_3, --客户号
       COL_4, --客户名称
       COL_5, --贷款余额/客户数/放款金额
       COL_10 --机构名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       G.ORG_NUM,
       'S63_I_7.3.F.2023' AS ITEM_NUM,
        'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       G.CUST_ID AS COL_3, --客户号
       G.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null AS COL_10 --机构名称
        FROM (SELECT DISTINCT T.ORG_NUM, T.CUST_ID,NVL(A.CUST_NAM ,B.CUST_NAM) CUST_NAM
                FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
                LEFT JOIN SMTMODS_L_CUST_P A
                  ON T.DATA_DATE = A.DATA_DATE
                 AND T.CUST_ID = A.CUST_ID
                LEFT JOIN SMTMODS_L_CUST_C B
                 ON T.DATA_DATE = B.DATA_DATE
                 AND T.CUST_ID = B.CUST_ID
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.ACCT_TYP LIKE '0102%' --个人经营性
                 AND T.CANCEL_FLG <> 'Y'
                    --AND T.LOAN_KIND_CD = '6' --借续贷
                    -- alter by  shiyu 230202 6无还本续贷,7 再融资
                 AND T.LOAN_KIND_CD in ('6', '7')
                 AND T.LOAN_ACCT_BAL <> 0 --ALTER BY WJB 20230202 计算户数的时候不要贷款余额等于0的
                 AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
                 AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
              ) G
             
       GROUP BY G.ORG_NUM,G.CUST_ID,G.CUST_NAM,null ;
    COMMIT;

    --  7.3无还本续贷贷款余额户数  个体工商户、小微企业主
     INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       COL_3, --客户号
       COL_4, --客户名称
       COL_5, --贷款余额/客户数/放款金额
       COL_10 --机构名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       G.ORG_NUM,
       CASE
         WHEN (G.OPERATE_CUST_TYPE = 'A' OR G.CUST_TYP = '3') THEN
          'S63_I_7.3.G.2023'
         WHEN G.OPERATE_CUST_TYPE = 'B' THEN
          'S63_I_7.3.H.2023'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       G.CUST_ID AS COL_3, --客户号
       G.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null AS COL_10 --机构名称
        FROM (SELECT DISTINCT T.ORG_NUM,
                              T.CUST_ID,
                              A.OPERATE_CUST_TYPE,
                              C.CUST_TYP,
                              NVL(A.CUST_NAM ,C.CUST_NAM)CUST_NAM
                FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
                LEFT JOIN SMTMODS_L_CUST_P A
                  ON T.DATA_DATE = A.DATA_DATE
                 AND T.CUST_ID = A.CUST_ID
                LEFT JOIN SMTMODS_L_CUST_C C
                  ON T.DATA_DATE = C.DATA_DATE
                 AND T.CUST_ID = C.CUST_ID
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.ACCT_TYP LIKE '0102%' --个人经营性
                    --AND T.LOAN_KIND_CD = '6' --借续贷
                    -- alter by  shiyu 230202 6无还本续贷,7 再融资
                 AND T.LOAN_KIND_CD in ('6', '7')
                 AND T.LOAN_ACCT_BAL <> 0 --ALTER BY WJB 20230202 计算户数的时候不要贷款余额等于0的
                 AND T.CANCEL_FLG <> 'Y'
                 AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
                 AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
              ) G
             
       GROUP BY G.ORG_NUM,
                CASE
                  WHEN (G.OPERATE_CUST_TYPE = 'A' OR G.CUST_TYP = '3') THEN
                   'S63_I_7.3.G.2023'
                  WHEN G.OPERATE_CUST_TYPE = 'B' THEN
                   'S63_I_7.3.H.2023'
                END,G.CUST_ID,G.CUST_NAM,null;
    COMMIT;

    --7.4当年无还本续贷贷款累放户数  大、中、小、微

     INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       COL_3, --客户号
       COL_4, --客户名称
       COL_5, --贷款余额/客户数/放款金额
       COL_10 --机构名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       G.ORG_NUM,
       CASE
         WHEN G.CORP_SCALE = 'B' THEN
          'S63_I_7.4.A.2023'
         WHEN G.CORP_SCALE = 'M' THEN
          'S63_I_7.4.B.2023'
         WHEN G.CORP_SCALE = 'S' THEN
          'S63_I_7.4.C.2023'
         WHEN G.CORP_SCALE = 'T' THEN
          'S63_I_7.4.D.2023'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       G.CUST_ID AS COL_3, --客户号
       G.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null AS COL_10 --机构名称
        FROM (SELECT DISTINCT T.ORG_NUM, T.CUST_ID, A.CORP_SCALE,A.CUST_NAM
                FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
                LEFT JOIN SMTMODS_L_CUST_C A
                  ON T.DATA_DATE = A.DATA_DATE
                 AND T.CUST_ID = A.CUST_ID
               WHERE T.DATA_DATE = I_DATADATE
                    -- AND T.LOAN_KIND_CD = '6' --借续贷
                    -- alter by  shiyu 230202 6无还本续贷,7 再融资
                 AND T.LOAN_KIND_CD in ('6', '7')
                 AND T.CANCEL_FLG <> 'Y'
                 AND T.DRAWDOWN_DT >= TRUNC(D_DATADATE_CCY, 'Y') --发生
                 AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
                 AND A.CUST_TYP NOT IN ('2', '4', '5') --政府机关、社会团体、事业单位
                 AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
                 AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
              ) G
             
       GROUP BY G.ORG_NUM,
                CASE
                  WHEN G.CORP_SCALE = 'B' THEN
                   'S63_I_7.4.A.2023'
                  WHEN G.CORP_SCALE = 'M' THEN
                   'S63_I_7.4.B.2023'
                  WHEN G.CORP_SCALE = 'S' THEN
                   'S63_I_7.4.C.2023'
                  WHEN G.CORP_SCALE = 'T' THEN
                   'S63_I_7.4.D.2023'
                END,G.CUST_ID,G.CUST_NAM,null;
    COMMIT;

    -- 7.4当年无还本续贷贷款累放户数 个人经营性

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       COL_3, --客户号
       COL_4, --客户名称
       COL_5, --贷款余额/客户数/放款金额
       COL_10 --机构名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'S63_I_7.4.F.2023' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       G.CUST_ID AS COL_3, --客户号
       G.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null AS COL_10 --机构名称
        FROM (SELECT DISTINCT T.ORG_NUM, T.CUST_ID,NVL(A.CUST_NAM,C.CUST_NAM) CUST_NAM
                FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
                LEFT JOIN SMTMODS_L_CUST_P A
                  ON T.DATA_DATE = A.DATA_DATE
                 AND T.CUST_ID = A.CUST_ID
                LEFT JOIN SMTMODS_L_CUST_C C
                   ON T.DATA_DATE = C.DATA_DATE
                 AND T.CUST_ID = C.CUST_ID
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.ACCT_TYP LIKE '0102%' --个人经营性
                    --AND T.LOAN_KIND_CD = '6' --借续贷
                    -- alter by  shiyu 230202 6无还本续贷,7 再融资
                 AND T.LOAN_KIND_CD in ('6', '7')
                 AND T.CANCEL_FLG <> 'Y'
                 AND T.DRAWDOWN_DT >= TRUNC(D_DATADATE_CCY, 'Y') --发生
                 AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
                 AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
              ) G
             
       GROUP BY ORG_NUM,G.CUST_ID,G.CUST_NAM,null;

    COMMIT;

    --  7.4当年无还本续贷贷款累放户数 个体工商户、小微企业主
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       COL_3, --客户号
       COL_4, --客户名称
       COL_5, --贷款余额/客户数/放款金额
       COL_10 --机构名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       G.ORG_NUM,
       CASE
         WHEN (G.OPERATE_CUST_TYPE = 'A' OR G.CUST_TYP = '3') THEN
          'S63_I_7.4.G.2023'
         WHEN G.OPERATE_CUST_TYPE = 'B' THEN
          'S63_I_7.4.H.2023'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       G.CUST_ID AS COL_3, --客户号
       G.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null AS COL_10 --机构名称
        FROM (SELECT DISTINCT T.ORG_NUM,
                              T.CUST_ID,
                              A.OPERATE_CUST_TYPE,
                              C.CUST_TYP,
                              NVL(A.CUST_NAM,C.CUST_NAM) CUST_NAM
                FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
                LEFT JOIN SMTMODS_L_CUST_P A
                  ON T.DATA_DATE = A.DATA_DATE
                 AND T.CUST_ID = A.CUST_ID
                LEFT JOIN SMTMODS_L_CUST_C C
                  ON T.DATA_DATE = C.DATA_DATE
                 AND T.CUST_ID = C.CUST_ID
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.ACCT_TYP LIKE '0102%' --个人经营性
                    --AND T.LOAN_KIND_CD = '6' --借续贷
                    -- alter by  shiyu 230202 6无还本续贷,7 再融资
                 AND T.LOAN_KIND_CD in ('6', '7')
                 AND T.CANCEL_FLG <> 'Y'
                 AND T.DRAWDOWN_DT >= TRUNC(D_DATADATE_CCY, 'Y') --发生
                 AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
                 AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
              ) G
            
       GROUP BY G.ORG_NUM,
                CASE
                  WHEN (G.OPERATE_CUST_TYPE = 'A' OR G.CUST_TYP = '3') THEN
                   'S63_I_7.4.G.2023'
                  WHEN G.OPERATE_CUST_TYPE = 'B' THEN
                   'S63_I_7.4.H.2023'
                END,G.CUST_ID,G.CUST_NAM,null;

    COMMIT;
    ---------------------------------------------------------------------------------------
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据 1.2.2.1政府性融资担保公司保证贷款 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --1.2.2.1政府性融资担保公司保证贷款 大、中、小、微
     INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       t.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_1.2.2.1.A.2021'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_1.2.2.1.B.2021'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_1.2.2.1.C.2021'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_1.2.2.1.D.2021'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM  AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * TT.CCY_RATE)  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
       INNER JOIN (SELECT
                  
                   DISTINCT B.CONTRACT_NUM --贷款合同号
                     FROM SMTMODS_L_AGRE_GUARANTEE_RELATION F1 --担保合同与担保信息对应关系表
                     LEFT JOIN SMTMODS_L_AGRE_GUARANTEE_CONTRACT F --担保合同表
                       ON F.GUAR_CONTRACT_NUM = F1.GUAR_CONTRACT_NUM
                      AND F.DATA_DATE = I_DATADATE
                     LEFT JOIN SMTMODS_L_AGRE_GUA_RELATION E --业务合同与担保合同对应关系表 E
                       ON E.GUAR_CONTRACT_NUM = F.GUAR_CONTRACT_NUM
                      AND E.DATA_DATE = I_DATADATE
                     LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT B --贷款合同信息表 B
                       ON B.CONTRACT_NUM = E.CONTRACT_NUM
                      AND B.DATA_DATE = I_DATADATE
                    INNER JOIN CBRC_FINANCE_COMPANY_LIST L
                       ON TRIM(F1.GUARANTEE_NAME) = TRIM(L.COMPANY_NAME)
                    WHERE F1.DATA_DATE = I_DATADATE
                      AND F.GUAR_CONTRACT_STATUS = 'Y' --担保合同有效状态
                      AND B.ACCT_STS = '1' --合同状态：1有效
                      and L.GOV_FLG = 'Y' --政府性融资担保公司
                   ) T1
          ON T1.CONTRACT_NUM = T.ACCT_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0')
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.GUARANTY_TYP LIKE 'C%' --担保方式：保证
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;
    --1.2.2.1政府性融资担保公司保证贷款  个人经营性
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'S63_I_1.2.2.1.E.2021' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,C.CUST_NAM)  AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * U.CCY_RATE)  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE WHEN A.OPERATE_CUST_TYPE ='A' OR C.CUST_TYP ='3' THEN '个体工商户'
         WHEN A.OPERATE_CUST_TYPE ='B' THEN '小微企业主'
           WHEN A.OPERATE_CUST_TYPE ='Z'  THEN '其他个人' END
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        left JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
       INNER JOIN (SELECT
                 
                   DISTINCT B.CONTRACT_NUM --贷款合同号
                     FROM SMTMODS_L_AGRE_GUARANTEE_RELATION F1 --担保合同与担保信息对应关系表
                     LEFT JOIN SMTMODS_L_AGRE_GUARANTEE_CONTRACT F --担保合同表
                       ON F.GUAR_CONTRACT_NUM = F1.GUAR_CONTRACT_NUM
                      AND F.DATA_DATE = I_DATADATE
                     LEFT JOIN SMTMODS_L_AGRE_GUA_RELATION E --业务合同与担保合同对应关系表 E
                       ON E.GUAR_CONTRACT_NUM = F.GUAR_CONTRACT_NUM
                      AND E.DATA_DATE = I_DATADATE
                     LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT B --贷款合同信息表 B
                       ON B.CONTRACT_NUM = E.CONTRACT_NUM
                      AND B.DATA_DATE = I_DATADATE
                    INNER JOIN CBRC_FINANCE_COMPANY_LIST L
                       ON TRIM(F1.GUARANTEE_NAME) = TRIM(L.COMPANY_NAME)
                    WHERE F1.DATA_DATE = I_DATADATE
                      AND F.GUAR_CONTRACT_STATUS = 'Y' --担保合同有效状态
                      AND B.ACCT_STS = '1' --合同状态：1有效
                      and L.GOV_FLG = 'Y' --政府性融资担保公司
                   ) T1
          ON T1.CONTRACT_NUM = T.ACCT_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.cust_id =C.CUST_ID
          AND C.DATA_DATE = I_DATADATE
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.ACCT_STS <> '3'
         AND T.GUARANTY_TYP LIKE 'C%' --担保方式：保证
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;

    COMMIT;
    --1.2.2.1政府性融资担保公司保证贷款 个体工商户、小微企业主
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_1.2.2.1.F.2021'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_1.2.2.1.G.2021'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,b.CUST_NAM)  AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * U.CCY_RATE)  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT
                  
                   DISTINCT B.CONTRACT_NUM --贷款合同号
                     FROM SMTMODS_L_AGRE_GUARANTEE_RELATION F1 --担保合同与担保信息对应关系表
                     LEFT JOIN SMTMODS_L_AGRE_GUARANTEE_CONTRACT F --担保合同表
                       ON F.GUAR_CONTRACT_NUM = F1.GUAR_CONTRACT_NUM
                      AND F.DATA_DATE = I_DATADATE
                     LEFT JOIN SMTMODS_L_AGRE_GUA_RELATION E --业务合同与担保合同对应关系表 E
                       ON E.GUAR_CONTRACT_NUM = F.GUAR_CONTRACT_NUM
                      AND E.DATA_DATE = I_DATADATE
                     LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT B --贷款合同信息表 B
                       ON B.CONTRACT_NUM = E.CONTRACT_NUM
                      AND B.DATA_DATE = I_DATADATE
                    INNER JOIN CBRC_FINANCE_COMPANY_LIST L
                       ON TRIM(F1.GUARANTEE_NAME) = TRIM(L.COMPANY_NAME)
                    WHERE F1.DATA_DATE = I_DATADATE
                      AND F.GUAR_CONTRACT_STATUS = 'Y' --担保合同有效状态
                      AND B.ACCT_STS = '1' --合同状态：1有效
                      and L.GOV_FLG = 'Y' --政府性融资担保公司
                   ) T1
          ON T1.CONTRACT_NUM = T.ACCT_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款、小微企业主贷款
             OR B.CUST_TYP = '3')
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.ACCT_STS <> '3'
         AND T.GUARANTY_TYP LIKE 'C%' --担保方式：保证
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    ----制度新增指标-------------------------------------------------
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据 1.2.3.1新型抵质押类贷款 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --1.2.3.1新型抵质押类贷款
    INSERT 
    INTO CBRC_S6301_DATA_COLLECT_GUARANTEE  --S6301新型抵质押类贷款临时表
      (CONTRACT_NUM, COLL_MK_VAL, COLL_MK_VAL_SUM, ZB)
      SELECT 
       T2.CONTRACT_NUM,
       sum(nvl(case
                 when SUBSTR(T4.COLL_TYP, 1, 3) IN ('A05', 'A07') OR
                      T4.COLL_TYP = 'A0606' OR T4.COLL_TYP = 'A1001' --A0606上市股票,A1001存货 ,A05保单,A07其他股权
                  then
                  T4.COLL_MK_VAL * T6.CCY_RATE
               end,
               0)) AS COLL_MK_VAL,
       sum(T4.COLL_MK_VAL * T6.CCY_RATE) AS COLL_MK_VAL_SUM, --押品市场价值
       sum(nvl(case
                 when SUBSTR(T4.COLL_TYP, 1, 3) IN ('A05', 'A07') OR
                      T4.COLL_TYP = 'A0606' OR T4.COLL_TYP = 'A1001' --A0606上市股票,A1001存货 ,A05保单,A07其他股权
                  then
                  T4.COLL_MK_VAL * T6.CCY_RATE
               end,
               0)) / sum(T4.COLL_MK_VAL * T6.CCY_RATE)
        FROM SMTMODS_L_AGRE_GUA_RELATION T2
       INNER JOIN SMTMODS_L_AGRE_GUARANTEE_RELATION T3
          ON T2.GUAR_CONTRACT_NUM = T3.GUAR_CONTRACT_NUM
         AND T3.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_AGRE_GUARANTY_INFO T4
          ON T3.GUARANTEE_SERIAL_NUM = T4.GUARANTEE_SERIAL_NUM
         AND T4.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT T5
          ON T2.CONTRACT_NUM = T5.CONTRACT_NUM
         AND T5.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE T6
          ON T6.DATA_DATE = I_DATADATE
         AND T6.BASIC_CCY = T3.CURR_CD --担保物折币
         AND T6.FORWARD_CCY = 'CNY'
       WHERE T2.DATA_DATE = I_DATADATE
            --AND T5.MAIN_GUARANTY_TYP IN ('0', '1') --主要担保方式：抵押质押
         AND SUBSTR(T5.MAIN_GUARANTY_TYP, 1, 1) IN ('A', 'B') --主要担保方式：抵押质押 合同主要担保方式按照借据的担保方式码值变更为英文
         AND T4.COLL_MK_VAL <> 0
       GROUP BY T2.CONTRACT_NUM;
    COMMIT;

    --1.2.3.1新型抵质押类贷款  大、中、小、微
    --抵押物市值>贷款余额 即贷款余额   贷款余额>抵押物市值 即抵押物市值
     INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_1.2.3.1.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_1.2.3.1.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_1.2.3.1.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_1.2.3.1.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM  AS COL_4, -- 字段4（客户名称）
      T.LOAN_ACCT_BAL * U.CCY_RATE * g.zb  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）

        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN CBRC_S6301_DATA_COLLECT_GUARANTEE G --新型抵质押类贷款临时表
          ON G.CONTRACT_NUM = T.ACCT_NUM
         and COLL_MK_VAL <> 0
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
         
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'  --客户类型为企业
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%' --非委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         and a.cust_typ <> '3'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;
    -- 1.2.3.1新型抵质押类贷款 个人经营性

   INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'S63_I_1.2.3.1.F.2022' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,C.CUST_NAM)  AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * U.CCY_RATE * g.zb)  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE WHEN A.OPERATE_CUST_TYPE ='A' OR C.CUST_TYP ='3' THEN '个体工商户'
         WHEN A.OPERATE_CUST_TYPE ='B' THEN '小微企业主'
           WHEN A.OPERATE_CUST_TYPE ='Z'  THEN '其他个人' END
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN CBRC_S6301_DATA_COLLECT_GUARANTEE G
          ON G.CONTRACT_NUM = T.ACCT_NUM
        left JOIN SMTMODS_L_CUST_P A ---- m17 20250327 shiyu 修改内容：分行反馈问题调整
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C
           ON T.DATA_DATE = c.DATA_DATE
         AND T.CUST_ID = c.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;

    COMMIT;
    --  1.2.3.1新型抵质押类贷款 个体工商户、小微企业主
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' or B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_1.2.3.1.G.2022'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_1.2.3.1.H.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,b.CUST_NAM)  AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * U.CCY_RATE * g.zb)  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN CBRC_S6301_DATA_COLLECT_GUARANTEE G
          ON G.CONTRACT_NUM = T.ACCT_NUM
        left JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND (A.OPERATE_CUST_TYPE in ('A', 'B') --个体工商户贷款,小微企业主贷款
             OR B.CUST_TYP = '3')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据 1.2.4.2财务公司承兑汇票 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --1.2.4=1.2.4.1+1.2.4.2+1.2.4.3
    --1.2.4.1银行承兑汇票扣除财务公司承兑汇票
    --单独建立临时表,取承兑人类型为财务公司,业务上如果票据到期日期都到期了,那么就是已经被承兑了,借据余额就为0
    INSERT 
    INTO CBRC_S6301_DATA_COLLECT_FINACIAL 
      (BILL_NUM, FLAG)
      SELECT 
      DISTINCT T1.BILL_NUM, '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_AGRE_BILL_INFO t1
          ON t.ACCT_NUM = T1.BILL_NUM
         AND T1.DATA_DATE = T.DATA_DATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T1.PAY_BANK_TYPE = 'B' --承兑人类型为财务公司
         AND T.CANCEL_FLG <> 'Y'
         AND T.ITEM_CD LIKE '1301%' --贴现
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL; --add by haorui 20250311 JLBA202408200012 资产未转让

    COMMIT;

    --1.2.4.2财务公司承兑汇票 大、中、小、微
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_1.2.4.2.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_1.2.4.2.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_1.2.4.2.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_1.2.4.2.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
       INNER JOIN (SELECT BILL_NUM
                     FROM CBRC_S6301_DATA_COLLECT_FINACIAL
                    WHERE FLAG = '1') T1
          ON T.ACCT_NUM = T1.BILL_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND A.CUST_TYP <> '3'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.ITEM_CD LIKE '1301%' --贴现
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    --1.2.4.2财务公司承兑汇票 个人经营性
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 ,--  字段12（业务条线）
       COL_18
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'S63_I_1.2.4.2.F.2022' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
        CASE WHEN A.OPERATE_CUST_TYPE ='A' OR C.CUST_TYP ='3' THEN '个体工商户'
            WHEN A.OPERATE_CUST_TYPE ='B' THEN '小微企业主'
            WHEN A.OPERATE_CUST_TYPE ='Z' THEN '其他个人' end
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
       LEFT JOIN SMTMODS_L_CUST_C C
          ON T.cust_id =C.CUST_ID
          AND C.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT BILL_NUM
                     FROM CBRC_S6301_DATA_COLLECT_FINACIAL
                    WHERE FLAG = '1') T1
          ON T.ACCT_NUM = T1.BILL_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.ITEM_CD LIKE '1301%' --贴现
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;

    COMMIT;
    --1.2.4.2财务公司承兑汇票 个体工商户、小微企业主
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_1.2.4.2.G.2022'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_1.2.4.2.H.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT BILL_NUM
                     FROM CBRC_S6301_DATA_COLLECT_FINACIAL
                    WHERE FLAG = '1') T1
          ON T.ACCT_NUM = T1.BILL_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.ITEM_CD LIKE '1301%' --贴现
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据 1.2.4.1银行承兑汇票 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    /* 1.2.4.1银行承兑汇票扣除财务公司承兑汇票,由于银承包含了财务公司,1.2.4.2财务公司承兑汇票已经有
    因此1.2.4.1银行承兑汇票需要去掉 */

    --1.2.4.1银行承兑汇票 大、中、小、微
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_1.2.4.1.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_1.2.4.1.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_1.2.4.1.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_1.2.4.1.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND A.CUST_TYP <> '3'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.ACCT_TYP = '030101' --030101 银行承兑汇票
         AND T.ACCT_NUM NOT IN
             (SELECT BILL_NUM FROM CBRC_S6301_DATA_COLLECT_FINACIAL) --扣除财务公司承兑汇票
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    --1.2.4.1银行承兑汇票 个人经营性
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'S63_I_1.2.4.1.F.2022' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 ,--  字段12（业务条线）
        CASE WHEN A.OPERATE_CUST_TYPE ='A' OR C.CUST_TYP ='3' THEN '个体工商户'
            WHEN A.OPERATE_CUST_TYPE ='B' THEN '小微企业主'
            WHEN A.OPERATE_CUST_TYPE ='Z' THEN '其他个人' end
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
       LEFT JOIN SMTMODS_L_CUST_C C
          ON T.DATA_DATE = C.DATA_DATE
         AND T.CUST_ID = C.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.ACCT_TYP = '030101' --030101 银行承兑汇票
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_NUM NOT IN
             (SELECT BILL_NUM FROM CBRC_S6301_DATA_COLLECT_FINACIAL) --扣除财务公司承兑汇票
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;

    COMMIT;
    --1.2.4.1银行承兑汇票 个体工商户、小微企业主
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_1.2.4.1.G.2022'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_1.2.4.1.H.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CUST_ID = B.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.ACCT_TYP = '030101' --030101 银行承兑汇票
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_NUM NOT IN
             (SELECT BILL_NUM FROM CBRC_S6301_DATA_COLLECT_FINACIAL) --扣除财务公司承兑汇票
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据 1.2.4.3商业承兑汇票 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --1.2.4.3商业承兑汇票 大、中、小、微
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_1.2.4.3.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_1.2.4.3.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_1.2.4.3.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_1.2.4.3.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG <> 'Y'
         AND A.CUST_TYP <> '3'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.ACCT_TYP = '030102' --030102 商业承兑汇票
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    --1.2.4.3商业承兑汇票 个人经营性
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'S63_I_1.2.4.3.F.2022' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * u.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 ,--  字段12（业务条线）
        CASE WHEN A.OPERATE_CUST_TYPE ='A' OR B.CUST_TYP ='3' THEN '个体工商户'
            WHEN A.OPERATE_CUST_TYPE ='B' THEN '小微企业主'
            WHEN A.OPERATE_CUST_TYPE ='Z' THEN '其他个人' end
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CUST_ID = B.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
     
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_TYP = '030102' --030102 商业承兑汇票
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;

    COMMIT;
    --1.2.4.3商业承兑汇票 个体工商户、小微企业主
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' THEN --其中：个体工商户贷款
          'S63_I_1.2.4.3.G.2022'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_1.2.4.3.H.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
      NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CUST_ID = B.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_TYP = '030102' --030102 商业承兑汇票
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --注释M7:计算年化利息收入用放款时的利率
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '加工累放类贷款相关至CBRC_S6301_AMT_TMP1中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ------------------加工当年累计 累放贷款合计------------------
    --年初删除本年累计

    IF SUBSTR(I_DATADATE, 5, 2) = 01 THEN
      EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S6301_AMT_TMP1';
    ELSE
      EXECUTE IMMEDIATE ('DELETE FROM  CBRC_S6301_AMT_TMP1 T WHERE  T.DATA_DATE = ' || '''' ||
                        I_DATADATE || '''' || ''); --删除当前日期数据
    END IF;

    COMMIT;

    --单户累放表 保留历史,每个月的放款相关都放在此表,为统计当年累放收益：实际利率按照放款时利率计算
    INSERT INTO CBRC_S6301_AMT_TMP1
      (DATA_DATE, --数据日期
       ORG_NUM, --机构
       LOAN_NUM, --借据编号
       CUST_ID, --客户号
       CUST_NAM, --客户名称
       ACCT_TYP, --账户类型
       CURR_CD, --币种
       MATURITY_DT, --原始到期日期
       DRAWDOWN_DT, --放款日期
       LOAN_ACCT_AMT, --放款金额
       LOAN_ACCT_BAL, --贷款余额
       REAL_INT_RAT, --实际利率
       NHSY, --年化收益
       OPERATE_CUST_TYPE, --个人经营性类型
       ITEM_CD, --科目号
       CUST_TYP, --对公客户类型
       CORP_SCALE, --企业规模
       GUARANTY_TYP, --贷款担保方式
       CORP_HOLD_TYPE --     企业控股类型
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构
             T.LOAN_NUM, --借据编号
             T.CUST_ID, --     客户号
             NVL(C.CUST_NAM, P.CUST_NAM) AS CUST_NAM, --     客户名称
             T.ACCT_TYP, --账户类型
             T.CURR_CD, --币种
             T.MATURITY_DT, --     原始到期日期
             T.DRAWDOWN_DT, --放款日期
             T.DRAWDOWN_AMT AS LOAN_ACCT_AMT, --放款金额
             T.LOAN_ACCT_BAL AS LOAN_ACCT_BAL, --贷款余额
             T.REAL_INT_RAT, --实际利率
             (T.DRAWDOWN_AMT * T.REAL_INT_RAT / 100) AS NHSY, --年化收益
             P.OPERATE_CUST_TYPE, --个人经营性类型
             T.ITEM_CD, --科目号
             C.CUST_TYP, --对公客户类型
             C.CORP_SCALE, --企业规模
             T.GUARANTY_TYP, --贷款担保方式
             C.CORP_HOLD_TYPE --企业控股类型
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T --ALTER BY WJB 20220621 原始到日期逻辑修改,从此视图取。
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.DATA_DATE = C.DATA_DATE
         AND T.CUST_ID = C.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_P P
          ON P.DATA_DATE = T.DATA_DATE
         AND P.CUST_ID = T.CUST_ID
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND (SUBSTR(TO_CHAR(t.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) = ---取当月
             SUBSTR(I_DATADATE, 1, 6) OR
             (t.INTERNET_LOAN_FLG = 'Y' AND
             t.DRAWDOWN_DT =
             (TRUNC(I_DATADATE, 'MM') - 1)) --modify by 87v : 互联网贷款数据晚一天下发,上月末数据当月取
             )
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
      ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据 2.1当年累放贷款金额 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --2.当年发放贷款情况

    --2.1当年累放贷款金额   大、中、小、微
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       C.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_2.1.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_2.1.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_2.1.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_2.1.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (T.DRAWDOWN_AMT * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 C ---取放款时所属机构
          ON T.LOAN_NUM = C.LOAN_NUM
        
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
            -- AND T.LOAN_ACCT_BAL <> 0
         AND A.CUST_TYP <> '3'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND (T.RESCHED_FLG = 'N' or t.resched_flg is null) -- 累放取非重组
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    --2.1当年累放贷款金额   个人经营性
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       C.ORG_NUM,
       'S63_I_2.1.F.2022' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
      (T.DRAWDOWN_AMT * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
      CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          '个体工商户'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          '小微企业主'
         WHEN A.OPERATE_CUST_TYPE = 'Z' THEN '其他个人'
       END
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_S6301_AMT_TMP1 C ---取放款时所属机构
          ON T.LOAN_NUM = C.LOAN_NUM
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND (T.RESCHED_FLG = 'N' or t.resched_flg is null) -- 累放取非重组
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;

    COMMIT;
    -- 个体工商户、小微企业主
     INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       C.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_2.1.G.2022'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_2.1.H.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
      (T.DRAWDOWN_AMT * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）

        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_S6301_AMT_TMP1 C ---取放款时所属机构
          ON T.LOAN_NUM = C.LOAN_NUM
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') OR B.CUST_TYP = '3')
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND (T.RESCHED_FLG = 'N' or t.resched_flg is null) -- 累放取非重组
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    --2.1.1当年累放信用贷款   大、中、小、微

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       C.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_2.1.1.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_2.1.1.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_2.1.1.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_2.1.1.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (T.DRAWDOWN_AMT * tt.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 C ---取放款时所属机构
          ON T.LOAN_NUM = C.LOAN_NUM
        
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
            --AND T.LOAN_ACCT_BAL <> 0
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.CANCEL_FLG <> 'Y'
         AND (T.RESCHED_FLG = 'N' or t.resched_flg is null) -- 累放取非重组
         AND T.GUARANTY_TYP = 'D' --信用/免担保贷款
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    --2.1.1当年累放信用贷款   个人经营性

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 ,--  字段12（业务条线）
       COL_18
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       C.ORG_NUM,
       'S63_I_2.1.1.F.2022' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
      (T.DRAWDOWN_AMT * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 ,--  字段12（业务条线）
        CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          '个体工商户'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          '小微企业主'
         WHEN A.OPERATE_CUST_TYPE = 'Z' THEN --其中：小微企业主贷款
          '其他个人'
       END
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_S6301_AMT_TMP1 C ---取放款时所属机构
          ON T.LOAN_NUM = C.LOAN_NUM
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND (T.RESCHED_FLG = 'N' or t.resched_flg is null) -- 累放取非重组
         AND T.GUARANTY_TYP = 'D' --信用/免担保贷款
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;

    COMMIT;
    --2.1.1当年累放信用贷款 个体工商户、小微企业主
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       C.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_2.1.1.G.2022'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_2.1.1.H.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
      (T.DRAWDOWN_AMT * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 C ---取放款时所属机构
          ON T.LOAN_NUM = C.LOAN_NUM
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') OR B.CUST_TYP = '3')
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND (T.RESCHED_FLG = 'N' or t.resched_flg is null) -- 累放取非重组
         AND T.GUARANTY_TYP = 'D' --信用/免担保贷款
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据 2.2当年累放贷款年化利息收益 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --2.1.2当年以法人账户透支方式累放贷款金额  无业务,不需要取

    --2.2当年累放贷款年化利息收益
     INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       TT1.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_2.2.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_2.2.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_2.2.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_2.2.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
      (T.DRAWDOWN_AMT * TT.CCY_RATE * TT1.REAL_INT_RAT / 100) AS COL_5, --放款金额*实际利率[执行利率(年)]/100
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 TT1 ---M7取放款时实际利率
          ON T.LOAN_NUM = TT1.LOAN_NUM
       
       WHERE T.DATA_DATE = I_DATADATE
            -- AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND T.CANCEL_FLG <> 'Y'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND (T.RESCHED_FLG = 'N' or t.RESCHED_FLG is null) -- 累放取非重组
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;

    COMMIT;

    --2.2当年累放贷款年化利息收益   个人经营性
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       TT1.ORG_NUM,
       'S63_I_2.2.F.2022' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
      (T.DRAWDOWN_AMT * U.CCY_RATE * TT1.REAL_INT_RAT / 100) AS COL_5, --放款金额*实际利率[执行利率(年)]/100
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
        CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          '个体工商户'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          '小微企业主'
         WHEN A.OPERATE_CUST_TYPE = 'Z' THEN --其中：小微企业主贷款
          '其他个人'
       END
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 TT1 ---M7取放款时实际利率
          ON T.LOAN_NUM = TT1.LOAN_NUM
      
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND (T.RESCHED_FLG = 'N' or t.RESCHED_FLG is null) -- 累放取非重组
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;

    COMMIT;
    --2.2当年累放贷款年化利息收益 个体工商户、小微企业主
     INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       TT1.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR C.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_2.2.G.2022'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_2.2.H.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
      (T.DRAWDOWN_AMT * U.CCY_RATE * TT1.REAL_INT_RAT / 100) AS COL_5, --放款金额*实际利率[执行利率(年)]/100
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.DATA_DATE = C.DATA_DATE
         AND T.CUST_ID = C.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 TT1 ---M7取放款时实际利率
          ON T.LOAN_NUM = TT1.LOAN_NUM
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND (T.RESCHED_FLG = 'N' or t.RESCHED_FLG is null) -- 累放取非重组
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') OR C.CUST_TYP = '3')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;

    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据 5.1贷款当年累计发放贷款户数 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ---5.1贷款当年累计发放贷款户数 --大中小微企业

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM,
             CASE
               WHEN B.CORP_SCALE = 'B' THEN
                'S63_I_5.1.A.2022'
               WHEN B.CORP_SCALE = 'M' THEN
                'S63_I_5.1.B.2022'
               WHEN B.CORP_SCALE = 'S' THEN
                'S63_I_5.1.C.2022'
               WHEN B.CORP_SCALE = 'T' THEN
                'S63_I_5.1.D.2022'
             END AS ITEM_NUM,
              'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.cust_id AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
        LEFT JOIN SMTMODS_L_CUST_C B --对公表 取小微企业
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_S6301_AMT_TMP1 C --取放款时机构
          ON A.LOAN_NUM = C.LOAN_NUM
        
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND A.CANCEL_FLG <> 'Y'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组 SHIYU 20220210  新口径吴大为
         AND SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = ---取当年
             SUBSTR(I_DATADATE, 1, 4)
         AND B.CUST_TYP <> '3'
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY C.ORG_NUM,
                CASE
                  WHEN B.CORP_SCALE = 'B' THEN
                   'S63_I_5.1.A.2022'
                  WHEN B.CORP_SCALE = 'M' THEN
                   'S63_I_5.1.B.2022'
                  WHEN B.CORP_SCALE = 'S' THEN
                   'S63_I_5.1.C.2022'
                  WHEN B.CORP_SCALE = 'T' THEN
                   'S63_I_5.1.D.2022'
                END,A.cust_id,B.CUST_NAM,null;
    COMMIT;

    --   5.1贷款当年累计发放贷款户数 --个人经营性
     INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT I_DATADATE AS DATA_DATE,
             P.ORG_NUM,
             'S63_I_5.1.F.2022' AS ITEM_NUM,
              'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.cust_id AS COL_3, -- 字段3（客户号）
       NVL(B.CUST_NAM,C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
        LEFT JOIN SMTMODS_L_CUST_C B --对公表 取小微企业
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_S6301_AMT_TMP1 P
          ON A.LOAN_NUM = P.LOAN_NUM
        
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND A.CANCEL_FLG <> 'Y'
         AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组 SHIYU 20220210  新口径吴大为
         AND SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = ---取当年
             SUBSTR(I_DATADATE, 1, 4)
         AND A.ACCT_TYP LIKE '0102%'
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      --AND ( C.OPERATE_CUST_TYPE IN ('A','B') OR B.CUST_TYP ='3')
       GROUP BY P.ORG_NUM,A.cust_id,NVL(B.CUST_NAM,C.CUST_NAM),null;
    commit;

    --5.1贷款当年累计发放贷款户数 个体工商户、小微企业主
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT I_DATADATE AS DATA_DATE,
             P.ORG_NUM,
             CASE
               WHEN B.Cust_Typ = '3' OR C.OPERATE_CUST_TYPE = 'A' THEN
                'S63_I_5.1.G.2022'
               WHEN C.OPERATE_CUST_TYPE = 'B' THEN
                'S63_I_5.1.H.2022'
             END AS ITEM_NUM,
             'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
             A.cust_id AS COL_3, -- 字段3（客户号）
       NVL(B.CUST_NAM,C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
        LEFT JOIN SMTMODS_L_CUST_C B --对公表 取小微企业
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_S6301_AMT_TMP1 P
          ON A.LOAN_NUM = P.LOAN_NUM
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND A.CANCEL_FLG <> 'Y'
         AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组 SHIYU 20220210  新口径吴大为
         AND SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = ---取当年
             SUBSTR(I_DATADATE, 1, 4)
         AND A.ACCT_TYP LIKE '0102%'
         AND (C.OPERATE_CUST_TYPE IN ('A', 'B') OR B.CUST_TYP = '3')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY P.ORG_NUM,
                CASE
                  WHEN B.Cust_Typ = '3' OR C.OPERATE_CUST_TYPE = 'A' THEN
                   'S63_I_5.1.G.2022'
                  WHEN C.OPERATE_CUST_TYPE = 'B' THEN
                   'S63_I_5.1.H.2022'
                END,A.cust_id,NVL(B.CUST_NAM,C.CUST_NAM),null;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据 5.2 贷款当年累计申请户数 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --5.2 贷款当年累计申请户数

    -- 原口径：贷款申请日期为当年 ,如果贷款为循环贷款非本年申请,并在当年有放款也统计
    --230202 shiyu 新制度往年申请,今年新发放户数也统计
    --20230316  shiyu 今年发放贷款户数从借据表取数据,原因：吉商数贷这种线上贷款就是没有贷款申请阶段的
    INSERT INTO CBRC_S6301_APPLY_C
      (data_date, org_num, item_num, cust_id)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN B.CORP_SCALE = 'B' THEN
                'S63_I_5.2.A.2022'
               WHEN B.CORP_SCALE = 'M' THEN
                'S63_I_5.2.B.2022'
               WHEN B.CORP_SCALE = 'S' THEN
                'S63_I_5.2.C.2022'
               WHEN B.CORP_SCALE = 'T' THEN
                'S63_I_5.2.D.2022'
             END AS ITEM_NUM,
             A.CUST_ID AS CUST_ID
        FROM SMTMODS_L_AGRE_LOAN_APPLY A
       INNER JOIN SMTMODS_L_CUST_C B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CUST_ID = B.CUST_ID
      /*LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
        ON A.ACCT_NUM = C.ACCT_NUM
       AND C.DATA_DATE = I_DATADATE
      LEFT JOIN SMTMODS_V_PUB_IDX_DK_YSDQRJJ D
        ON C.CONTRACT_NUM = D.ACCT_NUM
       AND D.DATA_DATE = I_DATADATE*/
       WHERE NVL(A.ACCT_TYP, '&') <> '90'
         AND B.CUST_TYP <> '3'
         AND (SUBSTR(TO_CHAR(A.APPLY_DT, 'yyyymmdd'), 1, 4) =
              SUBSTR(I_DATADATE, 1, 4) --本年申请
              /*OR (\*D.CIRCLE_LOAN_FLG = 'Y' \*循环贷款*\
              AND*\ SUBSTR(TO_CHAR(D.DRAWDOWN_DT, 'yyyymmdd'), 1, 4) =
              SUBSTR(I_DATADATE, 1, 4)) --本年发放*/)
         AND B.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND A.DATA_DATE = I_DATADATE
         and A.APPLY_SYS = '2' --审批通过
       group by A.ORG_NUM,
                A.CUST_ID,
                CASE
                  WHEN B.CORP_SCALE = 'B' THEN
                   'S63_I_5.2.A.2022'
                  WHEN B.CORP_SCALE = 'M' THEN
                   'S63_I_5.2.B.2022'
                  WHEN B.CORP_SCALE = 'S' THEN
                   'S63_I_5.2.C.2022'
                  WHEN B.CORP_SCALE = 'T' THEN
                   'S63_I_5.2.D.2022'
                END;
    commit;
    ----借据数据,发放日期为当年
    INSERT INTO CBRC_S6301_APPLY_C
      (data_date, org_num, item_num, cust_id)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN B.CORP_SCALE = 'B' THEN
                'S63_I_5.2.A.2022'
               WHEN B.CORP_SCALE = 'M' THEN
                'S63_I_5.2.B.2022'
               WHEN B.CORP_SCALE = 'S' THEN
                'S63_I_5.2.C.2022'
               WHEN B.CORP_SCALE = 'T' THEN
                'S63_I_5.2.D.2022'
             END AS ITEM_NUM,
             A.CUST_ID AS CUST_ID
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
        LEFT JOIN SMTMODS_L_CUST_C B --对公表 取小微企业
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         and NVL(A.ACCT_TYP, '&') <> '90' --剔除委托贷款
         AND A.CANCEL_FLG <> 'Y'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组 SHIYU 20220210  新口径吴大为
         AND SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = ---取当年
             SUBSTR(I_DATADATE, 1, 4)
         AND B.CUST_TYP <> '3'
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105')
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ; --m14  不含转贴现

    commit;

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT I_DATADATE AS DATA_DATE,
             AA.ORG_NUM,
             AA.ITEM_NUM,
             'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
             AA.cust_id AS COL_3, -- 字段3（客户号）
             C.CUST_NAM AS COL_4, -- 字段4（客户名称）
             1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
             null AS COL_10 --  字段10（机构名称）

        from CBRC_S6301_APPLY_C aa
         LEFT JOIN SMTMODS_L_CUST_C C
            ON AA.CUST_ID =C.CUST_ID
            AND C.DATA_DATE = I_DATADATE
        
       GROUP BY AA.ORG_NUM, AA.ITEM_NUM,AA.cust_id,C.CUST_NAM,null;
    commit;

    INSERT INTO CBRC_S6301_APPLY_P
      (data_date, org_num, item_num, cust_id, OPERATE_CUST_TYPE)
      SELECT
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'S63_I_5.2.F.2022' AS ITEM_NUM,
       A.CUST_ID,
       NVL(P.OPERATE_CUST_TYPE, C.CUST_TYP)

        FROM SMTMODS_L_AGRE_LOAN_APPLY A
        LEFT JOIN SMTMODS_L_CUST_C C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON A.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT E
          ON A.ACCT_NUM = E.ACCT_NUM
         AND E.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_V_PUB_IDX_DK_YSDQRJJ F
          ON E.CONTRACT_NUM = F.ACCT_NUM
         AND F.DATA_DATE = I_DATADATE
       WHERE A.ACCT_TYP LIKE '0102%'
            -- AND B.INLANDORRSHORE_FLG = 'Y'
         AND (SUBSTR(TO_CHAR(A.APPLY_DT, 'yyyymmdd'), 1, 4) =
             SUBSTR(I_DATADATE, 1, 4) --本年申请
             OR ( /*F.CIRCLE_LOAN_FLG = 'Y' \*循环贷款*\
                                                                                  AND*/
              SUBSTR(TO_CHAR(F.DRAWDOWN_DT, 'yyyymmdd'), 1, 4) =
              SUBSTR(I_DATADATE, 1, 4)) --本年发放
             AND SUBSTR(F.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
             )
         and A.APPLY_SYS = '2' --审批通过
         AND A.DATA_DATE = I_DATADATE
      union all
      SELECT I_DATADATE AS DATA_DATE,
             P.ORG_NUM,
             'S63_I_5.2.F.2022' AS ITEM_NUM,
             A.CUST_ID AS LOAN_ACCT_BAL_RMB,
             NVL(C.OPERATE_CUST_TYPE, B.CUST_TYP)
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
        LEFT JOIN SMTMODS_L_CUST_C B --对公表 取小微企业
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_S6301_AMT_TMP1 P
          ON A.LOAN_NUM = P.LOAN_NUM
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND A.CANCEL_FLG <> 'Y'
         AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组 SHIYU 20220210  新口径吴大为
         AND SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = ---取当年
             SUBSTR(I_DATADATE, 1, 4)
         AND A.ACCT_TYP LIKE '0102%'
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105')
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ; --m14  不含转贴现
    COMMIT;

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT I_DATADATE AS DATA_DATE,
             AA.ORG_NUM,
             AA.ITEM_NUM,
             'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
             AA.cust_id AS COL_3, -- 字段3（客户号）
             C.CUST_NAM AS COL_4, -- 字段4（客户名称）
             1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
             null AS COL_10 --  字段10（机构名称）
        FROM CBRC_S6301_APPLY_P aa
          LEFT JOIN SMTMODS_L_CUST_ALL C
            ON AA.CUST_ID =C.CUST_ID
            AND C.DATA_DATE = I_DATADATE
      
       GROUP BY AA.ORG_NUM, AA.ITEM_NUM,AA.cust_id,C.CUST_NAM,null;
    COMMIT;

    --5.2贷款当年累计申请贷款户数 个体工商户、小微企业主

     INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.OPERATE_CUST_TYPE in ('A', '3') THEN
                'S63_I_5.2.G.2022'
               WHEN A.OPERATE_CUST_TYPE = 'B' THEN
                'S63_I_5.2.H.2022'
             END AS ITEM_NUM,
            'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
             A.cust_id AS COL_3, -- 字段3（客户号）
             C.CUST_NAM AS COL_4, -- 字段4（客户名称）
             1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
             null AS COL_10 --  字段10（机构名称）
        FROM CBRC_S6301_APPLY_P A
        LEFT JOIN SMTMODS_L_CUST_ALL C
            ON A.CUST_ID =C.CUST_ID
            AND C.DATA_DATE = I_DATADATE
        
       WHERE A.OPERATE_CUST_TYPE IN ('A', 'B', '3')
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.OPERATE_CUST_TYPE in ('A', '3') THEN
                   'S63_I_5.2.G.2022'
                  WHEN A.OPERATE_CUST_TYPE = 'B' THEN
                   'S63_I_5.2.H.2022'
                END, A.cust_id,C.CUST_NAM,null;
    commit;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取 9.1循环贷余额 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --9.循环贷情况
    --9.1循环贷余额 至CBRC_S6301_DATA_COLLECT_TMP中间表';

    --9.1循环贷余额 大、中、小、微
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       t.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_9.1.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_9.1.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_9.1.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_9.1.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12--  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.CIRCLE_LOAN_FLG = 'Y' -- 是否循环  1是 0 否,贷款合同与借据保持一致
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;
    --9.1循环贷余额  个人经营性
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'S63_I_9.1.F.2022' AS ITEM_NUM,
        'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 ,--  字段12（业务条线）
        CASE WHEN A.OPERATE_CUST_TYPE ='A' OR C.CUST_TYP ='3' THEN '个体工商户'
            WHEN A.OPERATE_CUST_TYPE ='B' THEN '小微企业主'
            WHEN A.OPERATE_CUST_TYPE ='Z' THEN '其他个人' end
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C C
           ON T.DATA_DATE = C.DATA_DATE
         AND T.CUST_ID = C.CUST_ID
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CIRCLE_LOAN_FLG = 'Y' -- 是否循环 1是 0 否,贷款合同与借据保持一致
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;

    COMMIT;
    --9.1循环贷余额 个体工商户、小微企业主
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_9.1.G.2022'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_9.1.H.2022'
       END AS ITEM_NUM,
        'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = T.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CIRCLE_LOAN_FLG = 'Y' -- 是否循环  1是 0 否,贷款合同与借据保持一致
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款、小微企业主贷款
             OR B.CUST_TYP = '3')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    --9.2循环贷户数 大、中、小、微
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       t.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_9.2.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_9.2.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_9.2.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_9.2.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
             T.cust_id AS COL_3, -- 字段3（客户号）
             A.CUST_NAM AS COL_4, -- 字段4（客户名称）
             1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
             null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.ACCT_STS <> '3'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.CIRCLE_LOAN_FLG = 'Y' -- 是否循环 ,贷款合同与借据保持一致,
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY I_DATADATE,
                T.ORG_NUM,
                CASE
                  WHEN A.CORP_SCALE = 'B' THEN
                   'S63_I_9.2.A.2022'
                  WHEN A.CORP_SCALE = 'M' THEN
                   'S63_I_9.2.B.2022'
                  WHEN A.CORP_SCALE = 'S' THEN
                   'S63_I_9.2.C.2022'
                  WHEN A.CORP_SCALE = 'T' THEN
                   'S63_I_9.2.D.2022'
                END,T.cust_id,A.CUST_NAM,null;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取 9.2循环贷户数 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --9.2循环贷户数  个人经营性
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'S63_I_9.2.F.2022' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
             T.cust_id AS COL_3, -- 字段3（客户号）
             A.CUST_NAM AS COL_4, -- 字段4（客户名称）
             1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
             null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_ALL A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND T.CIRCLE_LOAN_FLG = 'Y' -- 是否循环
         AND T.LOAN_ACCT_BAL <> 0
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM,T.cust_id,A.CUST_NAM,null;

    COMMIT;
    --9.2循环贷户数 个体工商户、小微企业主
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_9.2.G.2022'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_9.2.H.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
             T.cust_id AS COL_3, -- 字段3（客户号）
             NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
             1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
             null AS COL_10 --  字段10（机构名称）

        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CUST_ID = B.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND T.CIRCLE_LOAN_FLG = 'Y' -- 是否循环
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款、小微企业主贷款
             OR B.CUST_TYP = '3')
         AND T.LOAN_ACCT_BAL <> 0
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN
                   'S63_I_9.2.G.2022'
                  WHEN A.OPERATE_CUST_TYPE = 'B' THEN
                   'S63_I_9.2.H.2022'
                END,T.cust_id,NVL(A.CUST_NAM,B.CUST_NAM),null;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取 9.3当年循环贷累放金额 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --9.3当年循环贷累放金额 大、中、小、微
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       t.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_9.3.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_9.3.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_9.3.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_9.3.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (t.drawdown_amt * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12--  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.CANCEL_FLG <> 'Y'
         AND T.CIRCLE_LOAN_FLG = 'Y' -- 是否循环
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    --9.3当年循环贷累放金额  个人经营性

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 ,--  字段12（业务条线）
       COL_18
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'S63_I_9.3.F.2022' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (t.drawdown_amt * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
        CASE WHEN A.OPERATE_CUST_TYPE ='A' OR C.CUST_TYP ='3' THEN '个体工商户'
            WHEN A.OPERATE_CUST_TYPE ='B' THEN '小微企业主'
            WHEN A.OPERATE_CUST_TYPE ='Z' THEN '其他个人' end
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.DATA_DATE = C.DATA_DATE
         AND T.CUST_ID = C.CUST_ID
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.CIRCLE_LOAN_FLG = 'Y' -- 是否循环
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;

    COMMIT;

    --9.3当年循环贷累放金额 个体工商户、小微企业主

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_9.3.G.2022'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_9.3.H.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (t.drawdown_amt * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CUST_ID = B.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.CIRCLE_LOAN_FLG = 'Y' -- 是否循环
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款、小微企业主贷款
             OR B.CUST_TYP = '3')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;
    -------------------------6.银税合作贷款情况 --------------------------------
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取 6.1银税合作贷款余额 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --m8 新增银税合作贷款逻辑
    --6.1银税合作贷款余额 --大 中 小 微
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       t.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_6.1.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_6.1.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_6.1.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_6.1.D.2022'
       END AS ITEM_NUM,
        'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * TT.CCY_RATE)  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;
    --6.1银税合作贷款余额  个人经营性
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'S63_I_6.1.F.2022' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12,--  字段12（业务条线）
       CASE WHEN A.OPERATE_CUST_TYPE ='A' OR C.CUST_TYP ='3' THEN '个体工商户'
            WHEN A.OPERATE_CUST_TYPE ='B' THEN '小微企业主'
            WHEN A.OPERATE_CUST_TYPE ='Z' THEN '其他个人' end

        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        
        LEFT JOIN SMTMODS_L_CUST_C C
            ON T.cust_id =C.CUST_ID
          AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;

    COMMIT;
    --6.1银税合作贷款余额 个体工商户、小微企业主
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_6.1.G.2022'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_6.1.H.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12--  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = T.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款、小微企业主贷款
             OR B.CUST_TYP = '3')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取 6.1.1 其中：银税信用贷款余额 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --6.1.1 其中：银税信用贷款余额  --大 中 小 微
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       t.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_6.1.1.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_6.1.1.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_6.1.1.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_6.1.1.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * tt.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12--  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND T.GUARANTY_TYP = 'D'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;
    --6.1.1 其中：银税信用贷款余额   个人经营性
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'S63_I_6.1.1.F.2022' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM ,C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12,--  字段12（业务条线）
       CASE WHEN A.OPERATE_CUST_TYPE ='A' OR C.CUST_TYP ='3' THEN '个体工商户'
            WHEN A.OPERATE_CUST_TYPE ='B' THEN '小微企业主'
            WHEN A.OPERATE_CUST_TYPE ='Z' THEN '其他个人' end
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.cust_id =C.CUST_ID
          AND C.DATA_DATE = I_DATADATE
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.GUARANTY_TYP = 'D' --信用
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;

    COMMIT;
    --6.1.1 其中：银税信用贷款余额  个体工商户、小微企业主
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_6.1.1.G.2022'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_6.1.1.H.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM ,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = T.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND T.GUARANTY_TYP = 'D' --信用
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款、小微企业主贷款
             OR B.CUST_TYP = '3')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取 6.2银税合作授信户数 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --6.2银税合作授信户数 大、中、小、微
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT 
       DISTINCT  I_DATADATE AS DATA_DATE,
       t.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_6.2.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_6.2.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_6.2.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_6.2.D.2022'
       END AS ITEM_NUM,
        'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.cust_id AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.ACCT_STS <> '3'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让

       ;
    COMMIT;

    --6.2银税合作授信户数  个人经营性
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'S63_I_6.2.F.2022' AS ITEM_NUM,
        'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.cust_id AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C C
           ON T.cust_id =C.CUST_ID
           AND C.DATA_DATE = I_DATADATE
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND T.LOAN_ACCT_BAL <> 0
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM,T.cust_id,NVL(A.CUST_NAM,C.CUST_NAM),null;

    COMMIT;
    --6.2银税合作授信户数 个体工商户、小微企业主
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_6.2.G.2022'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_6.2.H.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.cust_id AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CUST_ID = B.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款、小微企业主贷款
             OR B.CUST_TYP = '3')
         AND T.LOAN_ACCT_BAL <> 0
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN
                   'S63_I_6.2.G.2022'
                  WHEN A.OPERATE_CUST_TYPE = 'B' THEN
                   'S63_I_6.2.H.2022'
                END,T.cust_id,NVL(A.CUST_NAM,B.CUST_NAM),null;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取 6.2.1其中：贷款户数 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --6.2.1其中：贷款户数 大、中、小、微
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       t.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_6.2.1.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_6.2.1.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_6.2.1.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_6.2.1.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.ACCT_STS <> '3'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY I_DATADATE,
                T.ORG_NUM,
                CASE
                  WHEN A.CORP_SCALE = 'B' THEN
                   'S63_I_6.2.1.A.2022'
                  WHEN A.CORP_SCALE = 'M' THEN
                   'S63_I_6.2.1.B.2022'
                  WHEN A.CORP_SCALE = 'S' THEN
                   'S63_I_6.2.1.C.2022'
                  WHEN A.CORP_SCALE = 'T' THEN
                   'S63_I_6.2.1.D.2022'
                END,T.CUST_ID,A.CUST_NAM,null;
    COMMIT;

    --6.2.1其中：贷款户数  个人经营性
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'S63_I_6.2.1.F.2022' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       nvl(A.CUST_NAM,b.cust_nam ) AS COL_4, -- 字段4（客户名称）
       1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CUST_ID = B.CUST_ID
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND T.LOAN_ACCT_BAL <> 0
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM,T.CUST_ID,nvl(A.CUST_NAM,b.cust_nam ),null;

    COMMIT;
    --6.2.1其中：贷款户数 个体工商户、小微企业主
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_6.2.1.G.2022'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_6.2.1.H.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       nvl(A.CUST_NAM,b.cust_nam ) AS COL_4, -- 字段4（客户名称）
       1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CUST_ID = B.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
     
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款、小微企业主贷款
             OR B.CUST_TYP = '3')
         AND T.LOAN_ACCT_BAL <> 0
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN
                   'S63_I_6.2.1.G.2022'
                  WHEN A.OPERATE_CUST_TYPE = 'B' THEN
                   'S63_I_6.2.1.H.2022'
                END,T.CUST_ID,nvl(A.CUST_NAM,b.cust_nam ),null;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取 6.2.1.1其中：信用贷款户数 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --6.2.1.1其中：信用贷款户数 大、中、小、微
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       t.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_6.2.1.1.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_6.2.1.1.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_6.2.1.1.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_6.2.1.1.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       null AS COL_10 --  字段10（机构名称）

        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.ACCT_STS <> '3'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND T.GUARANTY_TYP = 'D' --信用
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY I_DATADATE,
                T.ORG_NUM,
                CASE
                  WHEN A.CORP_SCALE = 'B' THEN
                   'S63_I_6.2.1.1.A.2022'
                  WHEN A.CORP_SCALE = 'M' THEN
                   'S63_I_6.2.1.1.B.2022'
                  WHEN A.CORP_SCALE = 'S' THEN
                   'S63_I_6.2.1.1.C.2022'
                  WHEN A.CORP_SCALE = 'T' THEN
                   'S63_I_6.2.1.1.D.2022'
                END,T.CUST_ID,A.CUST_NAM, null;
    COMMIT;
    --6.2.1.1其中：信用贷款户数  个人经营性
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'S63_I_6.2.1.1.F.2022' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       nvl(A.CUST_NAM,c.cust_nam ) AS COL_4, -- 字段4（客户名称）
       1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C C
           ON A.CUST_ID =C.CUST_ID
           AND C.DATA_DATE = I_DATADATE
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND T.GUARANTY_TYP = 'D' --信用
         AND T.LOAN_ACCT_BAL <> 0
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM,T.CUST_ID,nvl(A.CUST_NAM,c.cust_nam ),null;

    COMMIT;
    --6.2.1.1其中：信用贷款户数 个体工商户、小微企业主
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_6.2.1.1.G.2022'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_6.2.1.1.H.2022'
       END AS ITEM_NUM,
        'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       nvl(A.CUST_NAM,B.cust_nam ) AS COL_4, -- 字段4（客户名称）
       1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CUST_ID = B.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND T.GUARANTY_TYP = 'D' --信用
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款、小微企业主贷款
             OR B.CUST_TYP = '3')
         AND T.LOAN_ACCT_BAL <> 0
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN
                   'S63_I_6.2.1.1.G.2022'
                  WHEN A.OPERATE_CUST_TYPE = 'B' THEN
                   'S63_I_6.2.1.1.H.2022'
                END,T.CUST_ID,nvl(A.CUST_NAM,B.cust_nam ),null ;
    COMMIT;
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取 6.3银税合作贷款当年累计发放金额 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    -- alter by djh 20240115
    --6.3银税合作贷款当年累计发放金额  大、中、小、微
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT
       I_DATADATE AS DATA_DATE,
       C.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_6.3.A.2024'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_6.3.B.2024'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_6.3.C.2024'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_6.3.D.2024'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (T.DRAWDOWN_AMT * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12--  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 C ---取放款时所属机构
          ON T.LOAN_NUM = C.LOAN_NUM
        
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND A.CUST_TYP <> '3'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    --6.3银税合作贷款当年累计发放金额   个人经营性
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       C.ORG_NUM,
       'S63_I_6.3.F.2024' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       nvl(A.CUST_NAM,b.cust_nam) AS COL_4, -- 字段4（客户名称）
       (T.DRAWDOWN_AMT * u.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12--  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 C ---取放款时所属机构
          ON T.LOAN_NUM = C.LOAN_NUM
       
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;

    COMMIT;
    --6.3银税合作贷款当年累计发放金额 个体工商户、小微企业主
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT
       I_DATADATE AS DATA_DATE,
       C.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_6.3.G.2024'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_6.3.H.2024'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       nvl(A.CUST_NAM,b.cust_nam) AS COL_4, -- 字段4（客户名称）
       (T.DRAWDOWN_AMT * u.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12--  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_S6301_AMT_TMP1 C ---取放款时所属机构
          ON T.LOAN_NUM = C.LOAN_NUM
      
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') OR B.CUST_TYP = '3')
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取 6.4银税合作贷款当年累计发放户数 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --6.4银税合作贷款当年累计发放户数  大中小微企业
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM,
             CASE
               WHEN B.CORP_SCALE = 'B' THEN
                'S63_I_6.4.A.2024'
               WHEN B.CORP_SCALE = 'M' THEN
                'S63_I_6.4.B.2024'
               WHEN B.CORP_SCALE = 'S' THEN
                'S63_I_6.4.C.2024'
               WHEN B.CORP_SCALE = 'T' THEN
                'S63_I_6.4.D.2024'
             END AS ITEM_NUM,
             'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
        A.cust_id AS COL_3, -- 字段3（客户号）
        B.CUST_NAM AS COL_4, -- 字段4（客户名称）
        1  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
        null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
        LEFT JOIN SMTMODS_L_CUST_C B --对公表
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_S6301_AMT_TMP1 C --取放款时机构
          ON A.LOAN_NUM = C.LOAN_NUM
      
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND A.CANCEL_FLG <> 'Y'
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0')
         AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组
         AND SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = ---取当年
             SUBSTR(I_DATADATE, 1, 4)
         AND B.CUST_TYP <> '3'
         AND A.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY C.ORG_NUM,
                CASE
                  WHEN B.CORP_SCALE = 'B' THEN
                   'S63_I_6.4.A.2024'
                  WHEN B.CORP_SCALE = 'M' THEN
                   'S63_I_6.4.B.2024'
                  WHEN B.CORP_SCALE = 'S' THEN
                   'S63_I_6.4.C.2024'
                  WHEN B.CORP_SCALE = 'T' THEN
                   'S63_I_6.4.D.2024'
                END,A.cust_id,B.CUST_NAM,null;
    COMMIT;

    --6.4银税合作贷款当年累计发放户数 个人经营性
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT I_DATADATE AS DATA_DATE,
             P.ORG_NUM,
             'S63_I_6.4.F.2024' AS ITEM_NUM,
             'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
        A.cust_id AS COL_3, -- 字段3（客户号）
        B.CUST_NAM AS COL_4, -- 字段4（客户名称）
        1  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
        null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
        LEFT JOIN CBRC_S6301_AMT_TMP1 P
          ON A.LOAN_NUM = P.LOAN_NUM
        LEFT JOIN SMTMODS_L_CUST_ALL B
          ON A.cust_id =B.CUST_ID
          AND B.DATA_DATE = I_DATADATE
      
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND A.CANCEL_FLG <> 'Y'
         AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组
         AND SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = ---取当年
             SUBSTR(I_DATADATE, 1, 4)
         AND A.ACCT_TYP LIKE '0102%'
         AND A.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY P.ORG_NUM,A.cust_id,B.CUST_NAM,null;
    COMMIT;

    --6.4银税合作贷款当年累计发放户数 个体工商户、小微企业主
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT I_DATADATE AS DATA_DATE,
             P.ORG_NUM,
             CASE
               WHEN B.CUST_TYP = '3' OR C.OPERATE_CUST_TYPE = 'A' THEN
                'S63_I_6.4.G.2024'
               WHEN C.OPERATE_CUST_TYPE = 'B' THEN
                'S63_I_6.4.H.2024'
             END AS ITEM_NUM,
             'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
        A.cust_id AS COL_3, -- 字段3（客户号）
        nvl(B.CUST_NAM,c.cust_nam) AS COL_4, -- 字段4（客户名称）
        1  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
        null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
        LEFT JOIN SMTMODS_L_CUST_C B --对公表 取小微企业
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_S6301_AMT_TMP1 P
          ON A.LOAN_NUM = P.LOAN_NUM
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND A.CANCEL_FLG <> 'Y'
         AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组
         AND SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = ---取当年
             SUBSTR(I_DATADATE, 1, 4)
         AND A.ACCT_TYP LIKE '0102%'
         AND (C.OPERATE_CUST_TYPE IN ('A', 'B') OR B.CUST_TYP = '3')
         AND A.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY P.ORG_NUM,
                CASE
                  WHEN B.CUST_TYP = '3' OR C.OPERATE_CUST_TYPE = 'A' THEN
                   'S63_I_6.4.G.2024'
                  WHEN C.OPERATE_CUST_TYPE = 'B' THEN
                   'S63_I_6.4.H.2024'
                END,A.cust_id, nvl(B.CUST_NAM,c.cust_nam) ,null;
    COMMIT;
    --4.表外项目   无个人经营性
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取 4.1.银行承兑汇票 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --4.1.银行承兑汇票  大中小微企业
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_12 --  字段12（业务条线）
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             CASE
               WHEN A.CORP_SCALE = 'B' THEN
                'S63_I_4.1.A.2024'
               WHEN A.CORP_SCALE = 'M' THEN
                'S63_I_4.1.B.2024'
               WHEN A.CORP_SCALE = 'S' THEN
                'S63_I_4.1.C.2024'
               WHEN A.CORP_SCALE = 'T' THEN
                'S63_I_4.1.D.2024'
             END AS ITEM_NUM,
             'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NO AS COL_1, -- 字段1（合同号）
       T.ACCT_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
      (NVL(T.BALANCE * TT.CCY_RATE, 0)) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.BUSINESS_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.GL_ITEM_CODE AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
        T.DEPARTMENTD AS COL_12--  字段12（业务条线）
        FROM SMTMODS_L_ACCT_OBS_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = D_DATADATE_CCY
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0')
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND T.ACCT_TYP = '111' --银行承兑汇票
       ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取 4.2.跟单信用证 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --4.2.跟单信用证
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_12 --  字段12（业务条线）
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             CASE
               WHEN A.CORP_SCALE = 'B' THEN
                'S63_I_4.2.A.2024'
               WHEN A.CORP_SCALE = 'M' THEN
                'S63_I_4.2.B.2024'
               WHEN A.CORP_SCALE = 'S' THEN
                'S63_I_4.2.C.2024'
               WHEN A.CORP_SCALE = 'T' THEN
                'S63_I_4.2.D.2024'
             END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NO AS COL_1, -- 字段1（合同号）
       T.ACCT_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
      (NVL(T.BALANCE * TT.CCY_RATE, 0)) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.BUSINESS_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.GL_ITEM_CODE AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.DEPARTMENTD AS COL_12--  字段12（业务条线）
        FROM SMTMODS_L_ACCT_OBS_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = D_DATADATE_CCY
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0')
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND SUBSTR(T.ACCT_TYP, 1, 2) = '31' --跟单信用证
       ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取 4.3.保函 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --4.3.保函
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_12 --  字段12（业务条线）
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             CASE
               WHEN A.CORP_SCALE = 'B' THEN
                'S63_I_4.3.A.2024'
               WHEN A.CORP_SCALE = 'M' THEN
                'S63_I_4.3.B.2024'
               WHEN A.CORP_SCALE = 'S' THEN
                'S63_I_4.3.C.2024'
               WHEN A.CORP_SCALE = 'T' THEN
                'S63_I_4.3.D.2024'
             END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NO AS COL_1, -- 字段1（合同号）
       T.ACCT_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
      (NVL(T.BALANCE * TT.CCY_RATE, 0)) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.BUSINESS_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.GL_ITEM_CODE AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.DEPARTMENTD AS COL_12--  字段12（业务条线）
        FROM SMTMODS_L_ACCT_OBS_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = D_DATADATE_CCY
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
     
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0')
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND SUBSTR(T.ACCT_TYP, 1, 3) IN ('121', '211') --保函
       ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取 4.4.不可无条件撤销的贷款承诺 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --4.4.不可无条件撤销的贷款承诺
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_12 --  字段12（业务条线）
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             CASE
               WHEN A.CORP_SCALE = 'B' THEN
                'S63_I_4.4.A.2024'
               WHEN A.CORP_SCALE = 'M' THEN
                'S63_I_4.4.B.2024'
               WHEN A.CORP_SCALE = 'S' THEN
                'S63_I_4.4.C.2024'
               WHEN A.CORP_SCALE = 'T' THEN
                'S63_I_4.4.D.2024'
             END AS ITEM_NUM,
             'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NO AS COL_1, -- 字段1（合同号）
       T.ACCT_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
      (NVL(T.BALANCE * TT.CCY_RATE, 0)) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.BUSINESS_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.GL_ITEM_CODE AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.DEPARTMENTD AS COL_12--  字段12（业务条线）
        FROM SMTMODS_L_ACCT_OBS_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = D_DATADATE_CCY
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
      
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0')
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND T.GL_ITEM_CODE IN ('70300201') --不可无条件撤销的贷款承诺
       ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取 11.战略性新兴产业贷款 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
       --11.战略性新兴产业贷款 --本项目与G19[战略性新兴产业]含义一致,仅统计G19相应行业中投向战略性新兴产业的贷款
    --11.战略性新兴产业贷款 大、中、小、微
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 ,--  字段12（业务条线）
       COL_13 , --贷款投向
       COL_21  --战略新兴类型
       )
      SELECT B.DATA_DATE, --数据日期
             B.ORG_NUM, --机构号
             CASE
               WHEN A.CORP_SCALE = 'B' THEN
                'S63_I_11.A.2024'
               WHEN A.CORP_SCALE = 'M' THEN
                'S63_I_11.B.2024'
               WHEN A.CORP_SCALE = 'S' THEN
                'S63_I_11.C.2024'
               WHEN A.CORP_SCALE = 'T' THEN
                'S63_I_11.D.2024'
             END AS ITEM_NUM,
             'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       B.ACCT_NUM AS COL_1, -- 字段1（合同号）
       B.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       B.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (B.LOAN_ACCT_BAL * R.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       B.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       B.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       B.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       B.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN B.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN B.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN B.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN B.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN B.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        B.DEPARTMENTD AS COL_12, --  字段12（业务条线）
        B.LOAN_PURPOSE_CD , --贷款投向
        M1.M_NAME
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ B -- 借据表
       INNER JOIN SMTMODS_L_CUST_C A
          ON B.DATA_DATE = A.DATA_DATE
         AND B.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON B.DATA_DATE = R.DATA_DATE
         AND B.CURR_CD = R.BASIC_CCY
         AND R.FORWARD_CCY = 'CNY'
       LEFT JOIN (SELECT LOAN_PURPOSE_CD,
                          DECODE(COLUMN_OODE,'C','1','D','2','E','3', 'F','4','G','5','H','6','I','7','J','8','K','9') AS COLUMN_OODE
                     FROM CBRC_INTO_FIELD_INDEX
                    WHERE COLUMN_OODE NOT IN ('B', 'L')
                      AND LOAN_PURPOSE_CD NOT IN ( 'C30' )--非金属矿物制品业【去掉,会取重复】
                      AND LOAN_PURPOSE_CD NOT IN ( 'Q841') --医院【去掉,会取重复】
                   ) C
          ON  (B.LOAN_PURPOSE_CD = C.LOAN_PURPOSE_CD AND
             B.INDUST_STG_TYPE = C.COLUMN_OODE)     --贷款投向在相应G19投向表中
        
        LEFT JOIN (SELECT LOAN_PURPOSE_CD,
                          DECODE(COLUMN_OODE,'C','1','D','2','E','3', 'F','4','G','5','H','6','I','7','J','8','K','9') AS COLUMN_OODE
                     FROM CBRC_INTO_FIELD_INDEX
                    WHERE COLUMN_OODE NOT IN ('B', 'L')
                      AND LOAN_PURPOSE_CD NOT IN ( 'C30' )--非金属矿物制品业【去掉,会取重复】
                      AND LOAN_PURPOSE_CD NOT IN ( 'Q841') --医院【去掉,会取重复】
                   ) C1
            ON (SUBSTR(B.LOAN_PURPOSE_CD, 1, 4) = C1.LOAN_PURPOSE_CD AND
             B.INDUST_STG_TYPE = C1.COLUMN_OODE)
        LEFT JOIN (SELECT LOAN_PURPOSE_CD,
                          DECODE(COLUMN_OODE,'C','1','D','2','E','3', 'F','4','G','5','H','6','I','7','J','8','K','9') AS COLUMN_OODE
                     FROM CBRC_INTO_FIELD_INDEX
                    WHERE COLUMN_OODE NOT IN ('B', 'L')
                      AND LOAN_PURPOSE_CD NOT IN ( 'C30' )--非金属矿物制品业【去掉,会取重复】
                      AND LOAN_PURPOSE_CD NOT IN ( 'Q841') --医院【去掉,会取重复】
                   ) C2
            ON   (SUBSTR(B.LOAN_PURPOSE_CD, 1, 3) = C2.LOAN_PURPOSE_CD AND
             B.INDUST_STG_TYPE = C2.COLUMN_OODE )  
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
          ON M1.M_CODE =B.INDUST_STG_TYPE
          AND  M_TABLECODE ='INDUST_STG_TYPE'
       WHERE B.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0')
         AND B.INDUST_STG_TYPE IN
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') --战略性新兴产业领域包含节能环保、新一代信息技术、生物、高端装备制造、新能源、新材料、新能源汽车、数字创意、相关服务九类
         AND B.ACCT_TYP NOT LIKE '01%'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND B.ACCT_TYP <> '90'
         AND B.CANCEL_FLG = 'N'
         AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (C.LOAN_PURPOSE_CD IS NOT NULL OR C1.LOAN_PURPOSE_CD  IS NOT NULL  OR C2.LOAN_PURPOSE_CD  IS NOT NULL )
       ;
    COMMIT;

    --11.战略性新兴产业贷款  个人经营性
     INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 ,--  字段12（业务条线）
       COL_13 , --贷款投向
       COL_21,  --战略新兴类型
       COL_18
       )
      SELECT B.DATA_DATE, --数据日期
             B.ORG_NUM, --机构号
             'S63_I_11.F.2024' AS ITEM_NUM,
              'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
       B.ACCT_NUM AS COL_1, -- 字段1（合同号）
       B.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       B.CUST_ID AS COL_3, -- 字段3（客户号）
       nvl(P.CUST_NAM,C1.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (B.LOAN_ACCT_BAL * R.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       B.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       B.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       B.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       B.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN B.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN B.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN B.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN B.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN B.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        B.DEPARTMENTD AS COL_12, --  字段12（业务条线）
        B.LOAN_PURPOSE_CD , --贷款投向
        M1.M_NAME,
        CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' OR C1.CUST_TYP = '3' THEN --其中：个体工商户贷款
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
                '小微企业主'
              WHEN P.OPERATE_CUST_TYPE = 'Z' THEN --其中：小微企业主贷款
                '其他个人'
             END
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ B -- 借据表
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON B.DATA_DATE = R.DATA_DATE
         AND B.CURR_CD = R.BASIC_CCY
         AND R.FORWARD_CCY = 'CNY'
       LEFT JOIN (SELECT LOAN_PURPOSE_CD,
                          DECODE(COLUMN_OODE,'C','1','D','2','E','3', 'F','4','G','5','H','6','I','7','J','8','K','9') AS COLUMN_OODE
                     FROM CBRC_INTO_FIELD_INDEX
                    WHERE COLUMN_OODE NOT IN ('B', 'L')
                      AND LOAN_PURPOSE_CD NOT IN ( 'C30' )--非金属矿物制品业【去掉,会取重复】
                      AND LOAN_PURPOSE_CD NOT IN ( 'Q841') --医院【去掉,会取重复】
                   ) C
          ON  (B.LOAN_PURPOSE_CD = C.LOAN_PURPOSE_CD AND
             B.INDUST_STG_TYPE = C.COLUMN_OODE)     --贷款投向在相应G19投向表中
        
        LEFT JOIN (SELECT LOAN_PURPOSE_CD,
                          DECODE(COLUMN_OODE,'C','1','D','2','E','3', 'F','4','G','5','H','6','I','7','J','8','K','9') AS COLUMN_OODE
                     FROM CBRC_INTO_FIELD_INDEX
                    WHERE COLUMN_OODE NOT IN ('B', 'L')
                      AND LOAN_PURPOSE_CD NOT IN ( 'C30' )--非金属矿物制品业【去掉,会取重复】
                      AND LOAN_PURPOSE_CD NOT IN ( 'Q841') --医院【去掉,会取重复】
                   ) C11
            ON (SUBSTR(B.LOAN_PURPOSE_CD, 1, 4) = C11.LOAN_PURPOSE_CD AND
             B.INDUST_STG_TYPE = C11.COLUMN_OODE)
        LEFT JOIN (SELECT LOAN_PURPOSE_CD,
                          DECODE(COLUMN_OODE,'C','1','D','2','E','3', 'F','4','G','5','H','6','I','7','J','8','K','9') AS COLUMN_OODE
                     FROM CBRC_INTO_FIELD_INDEX
                    WHERE COLUMN_OODE NOT IN ('B', 'L')
                      AND LOAN_PURPOSE_CD NOT IN ( 'C30' )--非金属矿物制品业【去掉,会取重复】
                      AND LOAN_PURPOSE_CD NOT IN ( 'Q841') --医院【去掉,会取重复】
                   ) C22
            ON   (SUBSTR(B.LOAN_PURPOSE_CD, 1, 3) = C22.LOAN_PURPOSE_CD AND
             B.INDUST_STG_TYPE = C22.COLUMN_OODE )  
         LEFT JOIN SMTMODS_L_CUST_P P
          ON B.DATA_DATE = P.DATA_DATE
         AND B.CUST_ID = P.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C1
          ON B.CUST_ID = C1.CUST_ID
         AND B.DATA_DATE = C1.DATA_DATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
          ON M1.M_CODE =B.INDUST_STG_TYPE
          AND  M_TABLECODE ='INDUST_STG_TYPE'
       WHERE B.DATA_DATE = I_DATADATE
         AND B.INDUST_STG_TYPE IN
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') --战略性新兴产业领域包含节能环保、新一代信息技术、生物、高端装备制造、新能源、新材料、新能源汽车、数字创意、相关服务九类
         AND B.ACCT_TYP LIKE '0102%' --个人经营性
         AND B.ACCT_TYP <> '90'
         AND B.CANCEL_FLG = 'N'
         AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
          AND (C.LOAN_PURPOSE_CD IS NOT NULL OR C11.LOAN_PURPOSE_CD  IS NOT NULL  OR C22.LOAN_PURPOSE_CD  IS NOT NULL )
       ;
    COMMIT;

   --11.战略性新兴产业贷款 个体工商户、小微企业主
     INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 ,--  字段12（业务条线）
       COL_13 , --贷款投向
       COL_21  --战略新兴类型
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             CASE
               WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
                'S63_I_11.G.2024'
               WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
                'S63_I_11.H.2024'
             END AS ITEM_NUM,
              'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
       t.ACCT_NUM AS COL_1, -- 字段1（合同号）
      t.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       t.CUST_ID AS COL_3, -- 字段3（客户号）
       nvl(A.CUST_NAM,b.cust_nam) AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
        T.LOAN_PURPOSE_CD , --贷款投向
        M1.M_NAME
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       LEFT JOIN (SELECT LOAN_PURPOSE_CD,
                          DECODE(COLUMN_OODE,'C','1','D','2','E','3', 'F','4','G','5','H','6','I','7','J','8','K','9') AS COLUMN_OODE
                     FROM CBRC_INTO_FIELD_INDEX
                    WHERE COLUMN_OODE NOT IN ('B', 'L')
                      AND LOAN_PURPOSE_CD NOT IN ( 'C30' )--非金属矿物制品业【去掉,会取重复】
                      AND LOAN_PURPOSE_CD NOT IN ( 'Q841') --医院【去掉,会取重复】
                   ) C
          ON  (T.LOAN_PURPOSE_CD = C.LOAN_PURPOSE_CD AND
             T.INDUST_STG_TYPE = C.COLUMN_OODE)     --贷款投向在相应G19投向表中
        
        LEFT JOIN (SELECT LOAN_PURPOSE_CD,
                          DECODE(COLUMN_OODE,'C','1','D','2','E','3', 'F','4','G','5','H','6','I','7','J','8','K','9') AS COLUMN_OODE
                     FROM CBRC_INTO_FIELD_INDEX
                    WHERE COLUMN_OODE NOT IN ('B', 'L')
                      AND LOAN_PURPOSE_CD NOT IN ( 'C30' )--非金属矿物制品业【去掉,会取重复】
                      AND LOAN_PURPOSE_CD NOT IN ( 'Q841') --医院【去掉,会取重复】
                   ) C11
            ON (SUBSTR(T.LOAN_PURPOSE_CD, 1, 4) = C11.LOAN_PURPOSE_CD AND
             T.INDUST_STG_TYPE = C11.COLUMN_OODE)
        LEFT JOIN (SELECT LOAN_PURPOSE_CD,
                          DECODE(COLUMN_OODE,'C','1','D','2','E','3', 'F','4','G','5','H','6','I','7','J','8','K','9') AS COLUMN_OODE
                     FROM CBRC_INTO_FIELD_INDEX
                    WHERE COLUMN_OODE NOT IN ('B', 'L')
                      AND LOAN_PURPOSE_CD NOT IN ( 'C30' )--非金属矿物制品业【去掉,会取重复】
                      AND LOAN_PURPOSE_CD NOT IN ( 'Q841') --医院【去掉,会取重复】
                   ) C22
            ON   (SUBSTR(T.LOAN_PURPOSE_CD, 1, 3) = C22.LOAN_PURPOSE_CD AND
             T.INDUST_STG_TYPE = C22.COLUMN_OODE )  
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = T.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
          ON M1.M_CODE =T.INDUST_STG_TYPE
          AND  M_TABLECODE ='INDUST_STG_TYPE'
      
       WHERE T.DATA_DATE = I_DATADATE
         AND T.INDUST_STG_TYPE IN
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') --战略性新兴产业领域包含节能环保、新一代信息技术、生物、高端装备制造、新能源、新材料、新能源汽车、数字创意、相关服务九类
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款、小微企业主贷款
             OR B.CUST_TYP = '3')
         AND T.ACCT_TYP <> '90'
         AND T.CANCEL_FLG = 'N'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (C.LOAN_PURPOSE_CD IS NOT NULL OR C11.LOAN_PURPOSE_CD  IS NOT NULL  OR C22.LOAN_PURPOSE_CD  IS NOT NULL )
       ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取 12.技术改造项目贷款 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --12.技术改造项目贷款 该项目应与EAST项目贷款信息表中,项目类型为“技术改造项目”的相关贷款保持一致
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12)
      SELECT B.DATA_DATE, --数据日期
             B.ORG_NUM, --机构号
             CASE
               WHEN A.CORP_SCALE = 'B' THEN
                'S63_I_12.A.2024'
               WHEN A.CORP_SCALE = 'M' THEN
                'S63_I_12.B.2024'
               WHEN A.CORP_SCALE = 'S' THEN
                'S63_I_12.C.2024'
               WHEN A.CORP_SCALE = 'T' THEN
                'S63_I_12.D.2024'
             END AS ITEM_NUM,
             'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
             B.ACCT_NUM AS COL_1, -- 字段1（合同号）
             B.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
             B.CUST_ID AS COL_3, -- 字段3（客户号）
             A.CUST_NAM AS COL_4, -- 字段4（客户名称）
            (B.LOAN_ACCT_BAL * R.CCY_RATE) AS COL_5,
            B.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       B.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       B.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       B.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN B.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN B.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN B.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN B.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN B.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       B.DEPARTMENTD AS COL_12  --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ B -- 借据表
       INNER JOIN SMTMODS_L_ACCT_PROJECT C --项目贷款信息表
          ON B.ACCT_NUM = C.ACCT_NUM
         AND C.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_CUST_C A
          ON B.DATA_DATE = A.DATA_DATE
         AND B.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON B.DATA_DATE = R.DATA_DATE
         AND B.CURR_CD = R.BASIC_CCY
         AND R.FORWARD_CCY = 'CNY'
       
       WHERE B.DATA_DATE = I_DATADATE
         AND C.PROJECT_TYPE = 'C' --项目类型为“技术改造项目”
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0')
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND B.ACCT_TYP <> '90'
         AND B.CANCEL_FLG = 'N'
         AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取 13.贸易融资 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --13.贸易融资  大、中、小、微
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12)
      SELECT B.DATA_DATE, --数据日期
             B.ORG_NUM, --机构号
             CASE
               WHEN A.CORP_SCALE = 'B' THEN
                'S63_I_13.A.2024'
               WHEN A.CORP_SCALE = 'M' THEN
                'S63_I_13.B.2024'
               WHEN A.CORP_SCALE = 'S' THEN
                'S63_I_13.C.2024'
               WHEN A.CORP_SCALE = 'T' THEN
                'S63_I_13.D.2024'
             END AS ITEM_NUM,
             'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
             B.ACCT_NUM AS COL_1, -- 字段1（合同号）
             B.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
             B.CUST_ID AS COL_3, -- 字段3（客户号）
             A.CUST_NAM AS COL_4, -- 字段4（客户名称）
             (B.LOAN_ACCT_BAL * R.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       B.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       B.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       B.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       B.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN B.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN B.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN B.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN B.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN B.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       B.DEPARTMENTD AS COL_12  --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ B -- 借据表
       INNER JOIN SMTMODS_L_CUST_C A
          ON B.DATA_DATE = A.DATA_DATE
         AND B.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON B.DATA_DATE = R.DATA_DATE
         AND B.CURR_CD = R.BASIC_CCY
         AND R.FORWARD_CCY = 'CNY'
       
       WHERE B.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0')
         AND SUBSTR(B.ITEM_CD, 1, 4) = '1305' --贸易融资
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND B.ACCT_TYP <> '90'
         AND B.CANCEL_FLG = 'N'
         AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;
    --9.1贸易融资  个人经营性
     INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18
       )
      SELECT B.DATA_DATE, --数据日期
             B.ORG_NUM, --机构号
             'S63_I_13.F.2024' AS ITEM_NUM,
             'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
             B.ACCT_NUM AS COL_1, -- 字段1（合同号）
             B.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
             B.CUST_ID AS COL_3, -- 字段3（客户号）
             NVL(C.CUST_NAM,A.CUST_NAM) AS COL_4, -- 字段4（客户名称）
             (B.LOAN_ACCT_BAL * R.CCY_RATE)  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       B.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       B.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       B.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       B.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN B.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN B.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN B.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN B.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN B.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       B.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
               WHEN A.OPERATE_CUST_TYPE = 'A' OR C.CUST_TYP = '3' THEN --其中：个体工商户贷款
                'S63_I_13.G.2024'
               WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
                'S63_I_13.H.2024'
             END
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ B -- 借据表
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON B.DATA_DATE = R.DATA_DATE
         AND B.CURR_CD = R.BASIC_CCY
         AND R.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_P A
          ON B.DATA_DATE = A.DATA_DATE
         AND B.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C
          ON B.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = B.DATA_DATE
       WHERE B.DATA_DATE = I_DATADATE
         AND SUBSTR(B.ITEM_CD, 1, 4) = '1305' --贸易融资
         AND B.ACCT_TYP LIKE '0102%' --个人经营性
         AND B.ACCT_TYP <> '90'
         AND B.CANCEL_FLG = 'N'
         AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;
    --9.1贸易融资 个体工商户、小微企业主
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             CASE
               WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
                'S63_I_13.G.2024'
               WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
                'S63_I_13.H.2024'
             END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       t.ACCT_NUM AS COL_1, -- 字段1（合同号）
       t.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       t.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * U.CCY_RATE)  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       t.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       t.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       t.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       t.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN t.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN t.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN t.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN t.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN t.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = T.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(T.ITEM_CD, 1, 4) = '1305' --贸易融资
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款、小微企业主贷款
             OR B.CUST_TYP = '3')
         AND T.ACCT_TYP <> '90'
         AND T.CANCEL_FLG = 'N'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取 14.2财务公司承兑汇票 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);  

   

    -----m15 alter by zy 20240626 完善 金融市场部 14.1银行承兑汇票 14.3商业承兑汇票 的取数逻辑
    /* 14.买断式转贴现  原表上面转帖都放在此处
    14.1银行承兑汇票
    14.2财务公司承兑汇票
    14.3商业承兑汇票*/
    --14=14.1+14.2+14.3
    --14.1银行承兑汇票扣除财务公司承兑汇票
    --增加临时表逻辑,取承兑人类型为财务公司,业务上如果票据到期日期都到期了,那么就是已经被承兑了,借据余额就为0
    INSERT 
    INTO CBRC_S6301_DATA_COLLECT_FINACIAL 
      (BILL_NUM, FLAG)
      SELECT 
      DISTINCT T1.BILL_NUM, '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_AGRE_BILL_INFO t1
          ON t.ACCT_NUM = T1.BILL_NUM
         AND T1.DATA_DATE = T.DATA_DATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T1.PAY_BANK_TYPE = 'B' --承兑人类型为财务公司
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL; --add by haorui 20250311 JLBA202408200012 资产未转让
    COMMIT;

    --转贴现同业客户信息表对应的ECIF客户重复,取其中一个
    INSERT INTO CBRC_S6301_DATA_COLLECT_BILL_TY 
      SELECT CUST_ID, ECIF_CUST_ID, LEGAL_TYSHXYDM
        FROM (SELECT ROW_NUMBER() OVER(PARTITION BY CUST_ID ORDER BY ECIF_CUST_ID) RN,
                     T.*
                FROM SMTMODS_L_CUST_BILL_TY T
               WHERE DATA_DATE = I_DATADATE
                 AND T.ORG_NUM NOT LIKE '5%'
                 AND T.ORG_NUM NOT LIKE '6%') --对于总行客户来说,不需要取村镇ECIF客户
       WHERE RN = 1;
    COMMIT;
    --14.2财务公司承兑汇票 大、中、小、微
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T3.CORP_SIZE = '01' THEN
          'S63_I_14.2.A.2024'
         WHEN T3.CORP_SIZE = '02' THEN
          'S63_I_14.2.B.2024'
         WHEN T3.CORP_SIZE = '03' THEN
          'S63_I_14.2.C.2024'
         WHEN T3.CORP_SIZE = '04' THEN
          'S63_I_14.2.D.2024'
       END AS ITEM_NUM,
        'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       T3.ORG_FULLNAME AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS COL_5,-- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN CBRC_S6301_DATA_COLLECT_BILL_TY T2 --（1）买断式转帖客户需要在转贴现同业客户信息表找到对应客户
          ON T.CUST_ID = T2.CUST_ID
      /*INNER JOIN SMTMODS_L_CUST_C T3 --（2）再找到对应ECIF客户的企业规模
       ON T2.ECIF_CUST_ID = T3.CUST_ID
      AND T3.DATA_DATE = I_DATADATE*/
       INNER JOIN SMTMODS_L_CUST_EXTERNAL_INFO T3 --（2）康哥反馈按照总行报送,客户外部信息表（万德债券投资表）存的是总行级别的,风险：刘名赫反馈交易对手在万德债券投资表都存在,不仅只有债券业务,也有票据的
          ON T2.LEGAL_TYSHXYDM = T3.USCD
         AND T3.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT BILL_NUM
                     FROM CBRC_S6301_DATA_COLLECT_FINACIAL
                    WHERE FLAG = '2') T1
          ON T.ACCT_NUM = T1.BILL_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
   
       WHERE T.DATA_DATE = I_DATADATE
            /*AND SUBSTR(T3.CUST_TYP, 1, 1) in ('1', '0')*/ --alter by   zy
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
            /* AND T3.CORP_SCALE IN ('B', 'M', 'S', 'T')*/ --alter by   zy
         AND T3.CORP_SIZE IN ('01', '02', '03', '04')
         AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    /* 14.1银行承兑汇票扣除财务公司承兑汇票,由于银承包含了财务公司,14.2财务公司承兑汇票已经有
    因此14.1银行承兑汇票需要去掉 */

    --14.1银行承兑汇票 大、中、小、微
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       /*CASE
         WHEN T3.CORP_SCALE = 'B' THEN
          'S63_I_14.1.A.2024'
         WHEN T3.CORP_SCALE = 'M' THEN
          'S63_I_14.1.B.2024'
         WHEN T3.CORP_SCALE = 'S' THEN
          'S63_I_14.1.C.2024'
         WHEN T3.CORP_SCALE = 'T' THEN
          'S63_I_14.1.D.2024'
       END AS ITEM_NUM,*/
       CASE
         WHEN T3.CORP_SIZE = '01' THEN
          'S63_I_14.1.A.2024'
         WHEN T3.CORP_SIZE = '02' THEN
          'S63_I_14.1.B.2024'
         WHEN T3.CORP_SIZE = '03' THEN
          'S63_I_14.1.C.2024'
         WHEN T3.CORP_SIZE = '04' THEN
          'S63_I_14.1.D.2024'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       T3.ORG_FULLNAME AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS COL_5,-- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN CBRC_S6301_DATA_COLLECT_BILL_TY T2 --（1）买断式转帖客户需要在转贴现同业客户信息表找到对应客户
          ON T.CUST_ID = T2.CUST_ID
      /*INNER JOIN SMTMODS_L_CUST_C T3 --（2）再找到对应ECIF客户的企业规模
       ON T2.ECIF_CUST_ID = T3.CUST_ID
      AND T3.DATA_DATE = I_DATADATE*/
       INNER JOIN SMTMODS_L_CUST_EXTERNAL_INFO T3 --（2）康哥反馈按照总行报送,客户外部信息表（万德债券投资表）存的是总行级别的,风险：刘名赫反馈交易对手在万德债券投资表都存在,不仅只有债券业务,也有票据的
          ON T2.LEGAL_TYSHXYDM = T3.USCD
         AND T3.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
            /*AND SUBSTR(T3.CUST_TYP, 1, 1) IN ('1', '0')*/
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
            /*AND T3.CORP_SCALE IN ('B', 'M', 'S', 'T')*/
         AND T3.CORP_SIZE IN ('01', '02', '03', '04')
         AND T.ACCT_TYP = '030101' --030101 银行承兑汇票
         AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
         AND T.ACCT_NUM NOT IN
             (SELECT BILL_NUM FROM CBRC_S6301_DATA_COLLECT_FINACIAL) --扣除财务公司承兑汇票
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取 14.3商业承兑汇票 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --14.3商业承兑汇票 大、中、小、微,按照出票人划分企业规模
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T3.CORP_SCALE = 'B' THEN
          'S63_I_14.3.A.2024'
         WHEN T3.CORP_SCALE = 'M' THEN
          'S63_I_14.3.B.2024'
         WHEN T3.CORP_SCALE = 'S' THEN
          'S63_I_14.3.C.2024'
         WHEN T3.CORP_SCALE = 'T' THEN
          'S63_I_14.3.D.2024'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       T3.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS COL_5,-- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_AGRE_BILL_INFO T1 ---（1）票面信息表,找到出票人编号,汇票号码关联
          ON T.DRAFT_NBR = T1.BILL_NUM
         AND T1.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_CUST_C T3 --（2）根据出票人编号找到企业规模
          ON T1.AFF_CODE = T3.CUST_ID
         AND T3.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
      
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(T3.CUST_TYP, 1, 1) in ('1', '0')
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG <> 'Y'
         AND T3.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.ACCT_TYP = '030102' --030102 商业承兑汇票
         AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;
    -----m15 alter by zy 20240626 完善 金融市场部 14.1银行承兑汇票 14.3商业承兑汇票 的取数逻辑

    ---alter by shiyu 20240123 新增专精特新中小企业贷款情况指标

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取 10.“专精特新”中小企业贷款情况 至CBRC_S6301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --10.1专精特新中小企业贷款余额
     INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.CORP_SCALE = 'B' THEN
          'S63_I_10.1.A.2024'
         WHEN B.CORP_SCALE = 'M' THEN
          'S63_I_10.1.B.2024'
         WHEN B.CORP_SCALE = 'S' THEN
          'S63_I_10.1.C.2024'
         WHEN B.CORP_SCALE = 'T' THEN
          'S63_I_10.1.D.2024'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) +
       (NVL(A.INT_ADJEST_AMT, 0) * U.CCY_RATE)  AS COL_5,  -- m17 20250327 shiyu 修改内容：分行反馈五级分类转贴现部分未取到数据INT_ADJEST_AMT有空值,改成nvl(INT_ADJEST_AMT,0)。
        -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
      --    需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
      /*LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                 FROM S7001_CUST_TEMP
                 where  CUST_TYPE like '%专精特新%'
                GROUP BY TRIM(CUST_NAME)) P --专精特新企业名单\制造业单项冠军名单\2022年国家技术创新示范企业名单
      ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
         replace(replace(TRIM(B.CUST_NAM), '(', '（'), ')', '）')*/
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND A.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND B.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND A.CANCEL_FLG <> 'Y'
            --    需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            --and P.CUST_NAME IS NOT NULL
         AND B.IF_SPCLED_NEW_CUST = '1' --是否专精特新客户 1是
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    COMMIT;

    --10.1.1“专精特新”小企业中长期贷款余额
     INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.CORP_SCALE = 'B' THEN
          'S63_I_10.1.1.A.2025'
         WHEN B.CORP_SCALE = 'M' THEN
          'S63_I_10.1.1.B.2025'
         WHEN B.CORP_SCALE = 'S' THEN
          'S63_I_10.1.1.C.2025'
         WHEN B.CORP_SCALE = 'T' THEN
          'S63_I_10.1.1.D.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) +
       (NVL(A.INT_ADJEST_AMT, 0) * U.CCY_RATE)  AS COL_5,  -- m17 20250327 shiyu 修改内容：分行反馈五级分类转贴现部分未取到数据INT_ADJEST_AMT有空值,改成nvl(INT_ADJEST_AMT,0)。
        -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
     
      --    需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
      /*LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                 FROM S7001_CUST_TEMP
                 where  CUST_TYPE like '%专精特新%'
                GROUP BY TRIM(CUST_NAME)) P --专精特新企业名单\制造业单项冠军名单\2022年国家技术创新示范企业名单
      ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
         replace(replace(TRIM(B.CUST_NAM), '(', '（'), ')', '）')*/
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND A.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND B.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            --    需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            --and P.CUST_NAME IS NOT NULL
         AND B.IF_SPCLED_NEW_CUST = '1' --是否专精特新客户 1是

         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) > 12
       ;
    COMMIT;

    --10.1.2“专精特新”中小企业信用贷款余额

    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.CORP_SCALE = 'B' THEN
          'S63_I_10.1.2.A.2025'
         WHEN B.CORP_SCALE = 'M' THEN
          'S63_I_10.1.2.B.2025'
         WHEN B.CORP_SCALE = 'S' THEN
          'S63_I_10.1.2.C.2025'
         WHEN B.CORP_SCALE = 'T' THEN
          'S63_I_10.1.2.D.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) +
       (NVL(A.INT_ADJEST_AMT, 0) * U.CCY_RATE)  AS COL_5,  -- m17 20250327 shiyu 修改内容：分行反馈五级分类转贴现部分未取到数据INT_ADJEST_AMT有空值,改成nvl(INT_ADJEST_AMT,0)。
        -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12 --  字段12（业务条线）
       FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        
      --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
      /* LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                 FROM S7001_CUST_TEMP
                 where  CUST_TYPE like '%专精特新%'
                GROUP BY TRIM(CUST_NAME)) P --专精特新企业名单\制造业单项冠军名单\2022年国家技术创新示范企业名单
      ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
         replace(replace(TRIM(B.CUST_NAM), '(', '（'), ')', '）')*/
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND A.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND B.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            --and P.CUST_NAME IS NOT NULL
         AND B.IF_SPCLED_NEW_CUST = '1' --是否专精特新客户 1是
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.GUARANTY_TYP = 'D'
       ;
    commit;

    --10.1.3“专精特新”中小企业不良贷款余额
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.CORP_SCALE = 'B' THEN
          'S63_I_10.1.3.A.2025'
         WHEN B.CORP_SCALE = 'M' THEN
          'S63_I_10.1.3.B.2025'
         WHEN B.CORP_SCALE = 'S' THEN
          'S63_I_10.1.3.C.2025'
         WHEN B.CORP_SCALE = 'T' THEN
          'S63_I_10.1.3.D.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) +
       (NVL(A.INT_ADJEST_AMT, 0) * U.CCY_RATE)  AS COL_5,  -- m17 20250327 shiyu 修改内容：分行反馈五级分类转贴现部分未取到数据INT_ADJEST_AMT有空值,改成nvl(INT_ADJEST_AMT,0)。
        -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         
      --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
      /*LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                 FROM S7001_CUST_TEMP
                 where  CUST_TYPE like '%专精特新%'
                GROUP BY TRIM(CUST_NAME)) P --专精特新企业名单\制造业单项冠军名单\2022年国家技术创新示范企业名单
      ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
         replace(replace(TRIM(B.CUST_NAM), '(', '（'), ')', '）')*/
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND A.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND B.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            --and P.CUST_NAME IS NOT NULL
         AND B.IF_SPCLED_NEW_CUST = '1' --是否专精特新客户 1是
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_GRADE_CD IN ('3', '4', '5')
       ;

    commit;
    --10.4“专精特新”中小企业存量贷款户数
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.CORP_SCALE = 'B' THEN
          'S63_I_10.4.A.2025'
         WHEN B.CORP_SCALE = 'M' THEN
          'S63_I_10.4.B.2025'
         WHEN B.CORP_SCALE = 'S' THEN
          'S63_I_10.4.C.2025'
         WHEN B.CORP_SCALE = 'T' THEN
          'S63_I_10.4.D.2025'
       END AS ITEM_NUM,
        'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.cust_id AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       null AS COL_10 --  字段10（机构名称）

        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         
      --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据

      /*LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                 FROM S7001_CUST_TEMP
                 where  CUST_TYPE like '%专精特新%'
                GROUP BY TRIM(CUST_NAME)) P --专精特新企业名单\制造业单项冠军名单\2022年国家技术创新示范企业名单
      ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
         replace(replace(TRIM(B.CUST_NAM), '(', '（'), ')', '）')*/
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND A.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND B.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            --and P.CUST_NAME IS NOT NULL
         AND B.IF_SPCLED_NEW_CUST = '1' --是否专精特新客户 1是
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现

       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.CORP_SCALE = 'B' THEN
                   'S63_I_10.4.A.2025'
                  WHEN B.CORP_SCALE = 'M' THEN
                   'S63_I_10.4.B.2025'
                  WHEN B.CORP_SCALE = 'S' THEN
                   'S63_I_10.4.C.2025'
                  WHEN B.CORP_SCALE = 'T' THEN
                   'S63_I_10.4.D.2025'
                END,A.cust_id,B.CUST_NAM,null;
    COMMIT;

    --10.2专精特新中小企业当年累放贷款金额
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       C.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_10.2.A.2024'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_10.2.B.2024'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_10.2.C.2024'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_10.2.D.2024'
       END AS ITEM_NUM,
        'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (DRAWDOWN_AMT * TT.CCY_RATE)AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）--放款金额*实际利率[执行利率(年)]/100
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
      T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 C ---取放款时所属机构
          ON T.LOAN_NUM = C.LOAN_NUM
       
      --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据

      /*LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                 FROM S7001_CUST_TEMP
                 where  CUST_TYPE like '%专精特新%'
                GROUP BY TRIM(CUST_NAME)) P --专精特新企业名单\制造业单项冠军名单\2022年国家技术创新示范企业名单
      ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
         replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')*/
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
            -- AND T.LOAN_ACCT_BAL <> 0
         AND A.CUST_TYP <> '3'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND (T.RESCHED_FLG = 'N' or t.resched_flg is null) -- 累放取非重组
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            --and P.CUST_NAME IS NOT NULL
         AND A.IF_SPCLED_NEW_CUST = '1' --是否专精特新客户 1是
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    commit;
    --10.3专精特新中小企业当年累放贷款年化利息收益
    INSERT INTO CBRC_A_REPT_DWD_S6301
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       TT1.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_10.3.A.2024'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_10.3.B.2024'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_10.3.C.2024'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_10.3.D.2024'
       END AS ITEM_NUM,
        'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (T.DRAWDOWN_AMT * TT.CCY_RATE * TT1.REAL_INT_RAT / 100)  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）--放款金额*实际利率[执行利率(年)]/100
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
      T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 TT1 ---M7取放款时实际利率
          ON T.LOAN_NUM = TT1.LOAN_NUM
      /* LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                 FROM S7001_CUST_TEMP
                 where  CUST_TYPE like '%专精特新%'
                GROUP BY TRIM(CUST_NAME)) P --专精特新企业名单\制造业单项冠军名单\2022年国家技术创新示范企业名单
      ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
         replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')*/
        
       WHERE T.DATA_DATE = I_DATADATE
            -- AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND T.CANCEL_FLG <> 'Y'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND (T.RESCHED_FLG = 'N' or t.RESCHED_FLG is null) -- 累放取非重组
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            --and P.CUST_NAME IS NOT NULL
         AND A.IF_SPCLED_NEW_CUST = '1' --是否专精特新客户 1是
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       ;
    commit;

    --15.企业类贷款合计  归并项
    --=======================================================================================================-
    -------------------------------------S6301数据插至目标指标表--------------------------------------------
    --=====================================================================================================---

    V_STEP_FLAG := V_STEP_FLAG + 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生S6301指标数据,插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(T.COL_5) AS ITEM_VAL,
       '2' AS FLAG
        FROM CBRC_A_REPT_DWD_S6301 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM, T.ITEM_NUM;
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
    V_STEP_DESC := '发生异常。详细信息为,' || TO_CHAR(SQLCODE) ||
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