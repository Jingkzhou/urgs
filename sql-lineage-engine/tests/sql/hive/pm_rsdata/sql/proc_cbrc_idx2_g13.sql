CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g13(II_DATADATE  IN STRING --跑批日期
                                                 )
/******************************
  @author:JIHAIJING
  @create-date:20150929
  @description:G1301,G1302,G1303,G1304
  @modification history:
  m0.author-create_date-description
  M1.20230914 shiyu alter by 金融市场部需求：新增买入返售余额取数规则



目标表：CBRC_A_REPT_ITEM_VAL
集市表：SMTMODS_L_ACCT_FUND_REPURCHASE
     SMTMODS_L_AGRE_BOND_INFO
     SMTMODS_L_AGRE_REPURCHASE_GUARANTY_INFO
  *******************************/
 IS
  V_SCHEMA    VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE VARCHAR(30); --当前储存过程名称
  V_TAB_NAME  VARCHAR(30); --目标表名
  I_DATADATE  STRING; --数据日期(数值型)YYYYMMDD
  V_DATADATE  VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  V_STEP_ID   INTEGER; --任务号
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_ERRORDESC    VARCHAR(280); --错误内容
  V_STEP_DESC VARCHAR(300); --任务描述
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
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G13');
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_TAB_NAME := 'G13';
    V_DATADATE := TO_CHAR(DATE(I_DATADATE), 'YYYYMMDD');

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND REP_NUM = V_TAB_NAME
       AND FLAG = '2';
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生G13-买入返售余额指标数据，插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --M1.20230914 shiyu alter by 金融市场部需求：新增买入返售余额取数规则
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值 (数值型 )
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G13' AS REP_NUM, --报表编号
             CASE
               WHEN TRIM (T.COLL_SUBJECT_TYPE ) LIKE '%国债%' THEN
                'G13_1.3.1.I' --1.3.1国债
               WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%政府债券%' THEN
                'G13_1.3.2.I' --1.3.2地方政府债
               WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%央票%' THEN
                'G13_1.3.3.I' --1.3.3央票
               WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%政府机构债券%' THEN
                'G13_1.3.4.I' --1.3.4政府机构债券
               WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%政策性银行%' THEN
                'G13_1.3.5.I' --1.3.5政策性金融债
               WHEN TRIM(T.COLL_SUBJECT_TYPE) IN ('保险公司资本补充债', '二级资本工具', '次级债', '商业银行') THEN
                'G13_1.3.6.I' --1.3.6商业性金融债
               WHEN TRIM(T.COLL_SUBJECT_TYPE) IN ('企业债券', '一般公司债', '短期融资券', '超短期融资券', '中期票据', '绿色债务融资工具') THEN
                 CASE
                   WHEN C.APPRAISE_TYPE IN ('1','2') THEN 'G13_1.3.7.1.I' --1.3.7.1评级在AA+ (含 )以上
                   WHEN C.APPRAISE_TYPE IN ('3','4','5','6') THEN 'G13_1.3.7.2.I' --1.3.7.2评级在AA+至A之间
                   ELSE 'G13_1.3.7.3.I' --1.3.7.3评级在A以下或无评级
                 END
               ELSE
                'G13_1.3.8.I' --1.3.8其他债券
             END ITEM_NUM, --指标号
             SUM(NVL(T.BALANCE,0)) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_AGRE_REPURCHASE_GUARANTY_INFO T --回购抵质押信息表
       INNER JOIN SMTMODS_L_ACCT_FUND_REPURCHASE B --回购信息表
          ON T.ACCT_NUM = B.ACCT_NUM
         AND B.DATA_DATE = I_DATADATE
         AND B.BUSI_TYPE LIKE '1%'
         AND B.ASS_TYPE = '1' --债券
         AND B.BALANCE > 0
         AND TO_CHAR(B.END_DT, 'YYYYMMDD') >= I_DATADATE --到期日期
        LEFT JOIN SMTMODS_L_AGRE_BOND_INFO C
          ON T.SUBJECT_CD = C.STOCK_CD
        AND C.DATA_DATE = I_DATADATE
       WHERE T.TRADE_DIRECT = '逆回购'
         AND T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN TRIM (T.COLL_SUBJECT_TYPE ) LIKE '%国债%' THEN
                   'G13_1.3.1.I' --1.3.1国债
                  WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%政府债券%' THEN
                   'G13_1.3.2.I' --1.3.2地方政府债
                  WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%央票%' THEN
                   'G13_1.3.3.I' --1.3.3央票
                  WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%政府机构债券%' THEN
                   'G13_1.3.4.I' --1.3.4政府机构债券
                  WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%政策性银行%' THEN
                   'G13_1.3.5.I' --1.3.5政策性金融债
                  WHEN TRIM(T.COLL_SUBJECT_TYPE) IN ('保险公司资本补充债', '二级资本工具', '次级债', '商业银行') THEN
                   'G13_1.3.6.I' --1.3.6商业性金融债
                  WHEN TRIM(T.COLL_SUBJECT_TYPE) IN ('企业债券', '一般公司债', '短期融资券', '超短期融资券', '中期票据', '绿色债务融资工具') THEN
                     CASE
                       WHEN C.APPRAISE_TYPE IN ('1','2') THEN 'G13_1.3.7.1.I' --1.3.7.1评级在AA+ (含 )以上
                       WHEN C.APPRAISE_TYPE IN ('3','4','5','6') THEN 'G13_1.3.7.2.I' --1.3.7.2评级在AA+至A之间
                       ELSE 'G13_1.3.7.3.I' --1.3.7.3评级在A以下或无评级
                     END
                  ELSE
                   'G13_1.3.8.I' --1.3.8其他债券
                END;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生G13-买入返售起始估值指标数据，插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --金融市场部需求：新增买入返售起始估值取数
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值 (数值型 )
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G13' AS REP_NUM, --报表编号
             CASE
               WHEN TRIM (T.COLL_SUBJECT_TYPE )LIKE '%国债%' THEN
                'G13_1.3.1.G' --1.3.1国债起始估值
               WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%政府债券%' THEN
                'G13_1.3.2.G' --1.3.2地方政府债起始估值
               WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%央票%' THEN
                'G13_1.3.3.G' --1.3.3央票起始估值
               WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%政府机构债券%' THEN
                'G13_1.3.4.G' --1.3.4政府机构债券起始估值
               WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%政策性银行%' THEN
                'G13_1.3.5.G' --1.3.5政策性金融债起始估值
               WHEN TRIM(T.COLL_SUBJECT_TYPE) IN ('保险公司资本补充债', '二级资本工具', '次级债', '商业银行') THEN
                'G13_1.3.6.G' --1.3.6商业性金融债起始估值
               WHEN TRIM(T.COLL_SUBJECT_TYPE) IN  ('企业债券', '一般公司债', '短期融资券', '超短期融资券', '中期票据', '绿色债务融资工具') THEN
                  CASE
                   WHEN C.APPRAISE_TYPE IN ('1','2') THEN 'G13_1.3.7.1.G' --1.3.7.1评级在AA+ (含 )以上
                   WHEN C.APPRAISE_TYPE IN ('3','4','5','6') THEN 'G13_1.3.7.2.G' --1.3.7.2评级在AA+至A之间
                   ELSE 'G13_1.3.7.3.G' --1.3.7.3评级在A以下或无评级
                 END
               ELSE
                'G13_1.3.8.G' --1.3.8其他债券
             END ITEM_NUM, --指标号
             --券面额 * 抵质押率 = 质押额 ；质押额 * 押品原始价值 (交易日的中登净价价格 ) = 起始估值
             SUM(NVL(T.BOND_VAL,0) * NVL(T.MORTGAGE_RATIO,0) * (NVL(T.COLL_ORG_VAL,0)/100)) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_AGRE_REPURCHASE_GUARANTY_INFO T --回购抵质押信息表
       INNER JOIN SMTMODS_L_ACCT_FUND_REPURCHASE B --回购信息表
          ON T.ACCT_NUM = B.ACCT_NUM
         AND B.DATA_DATE = I_DATADATE
         AND B.BUSI_TYPE LIKE '1%'
         AND B.ASS_TYPE = '1' --债券
         AND B.BALANCE > 0
         AND TO_CHAR(B.END_DT, 'YYYYMMDD') >= I_DATADATE --到期日期
        LEFT JOIN SMTMODS_L_AGRE_BOND_INFO C
          ON T.SUBJECT_CD = C.STOCK_CD
         AND C.DATA_DATE = I_DATADATE
       WHERE T.TRADE_DIRECT = '逆回购'
         AND T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM,
                CASE
                   WHEN TRIM (T.COLL_SUBJECT_TYPE )LIKE '%国债%' THEN
                    'G13_1.3.1.G' --1.3.1国债起始估值
                   WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%政府债券%' THEN
                    'G13_1.3.2.G' --1.3.2地方政府债起始估值
                   WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%央票%' THEN
                    'G13_1.3.3.G' --1.3.3央票起始估值
                   WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%政府机构债券%' THEN
                    'G13_1.3.4.G' --1.3.4政府机构债券起始估值
                   WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%政策性银行%' THEN
                    'G13_1.3.5.G' --1.3.5政策性金融债起始估值
                   WHEN TRIM(T.COLL_SUBJECT_TYPE) IN ('保险公司资本补充债', '二级资本工具', '次级债', '商业银行') THEN
                    'G13_1.3.6.G' --1.3.6商业性金融债起始估值
                   WHEN TRIM(T.COLL_SUBJECT_TYPE) IN  ('企业债券', '一般公司债', '短期融资券', '超短期融资券', '中期票据', '绿色债务融资工具') THEN
                      CASE
                         WHEN C.APPRAISE_TYPE IN ('1','2') THEN 'G13_1.3.7.1.G' --1.3.7.1评级在AA+ (含 )以上
                         WHEN C.APPRAISE_TYPE IN ('3','4','5','6') THEN 'G13_1.3.7.2.G' --1.3.7.2评级在AA+至A之间
                         ELSE 'G13_1.3.7.3.G' --1.3.7.3评级在A以下或无评级
                       END
                   ELSE
                    'G13_1.3.8.G' --1.3.8其他债券
                 END;
    COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生G13-买入返售最新估值指标数据，插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --金融市场部需求：新增买入返售最新估值取数
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值 (数值型 )
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G13' AS REP_NUM, --报表编号
             CASE
               WHEN TRIM (T.COLL_SUBJECT_TYPE )LIKE '%国债%' THEN
                'G13_1.3.1.H' --1.3.1国债最新估值
               WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%政府债券%' THEN
                'G13_1.3.2.H' --1.3.2地方政府债最新估值
               WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%央票%' THEN
                'G13_1.3.3.H' --1.3.3央票最新估值
               WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%政府机构债券%' THEN
                'G13_1.3.4.H' --1.3.4政府机构债券最新估值
               WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%政策性银行%' THEN
                'G13_1.3.5.H' --1.3.5政策性金融债最新估值
               WHEN TRIM(T.COLL_SUBJECT_TYPE) IN ('保险公司资本补充债', '二级资本工具', '次级债', '商业银行') THEN
                'G13_1.3.6.H' --1.3.6商业性金融债最新估值
               WHEN TRIM(T.COLL_SUBJECT_TYPE) IN  ('企业债券', '一般公司债', '短期融资券', '超短期融资券', '中期票据', '绿色债务融资工具') THEN
                  CASE
                   WHEN C.APPRAISE_TYPE IN ('1','2') THEN 'G13_1.3.7.1.H' --1.3.7.1评级在AA+ (含 )以上
                   WHEN C.APPRAISE_TYPE IN ('3','4','5','6') THEN 'G13_1.3.7.2.H' --1.3.7.2评级在AA+至A之间
                   ELSE 'G13_1.3.7.3.H' --1.3.7.3评级在A以下或无评级
                 END
               ELSE
                'G13_1.3.8.H' --1.3.8其他债券
             END ITEM_NUM, --指标号
             --券面额 * 抵质押率 = 质押额 ；质押额 * 押品市场价值 (报告日的中登净价价格 ) = 最新估值
             SUM(NVL(T.BOND_VAL,0) * NVL(T.MORTGAGE_RATIO,0) * (NVL(T.COLL_MK_VAL,0)/100)) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_AGRE_REPURCHASE_GUARANTY_INFO T --回购抵质押信息表
       INNER JOIN SMTMODS_L_ACCT_FUND_REPURCHASE B --回购信息表
          ON T.ACCT_NUM = B.ACCT_NUM
         AND B.DATA_DATE = I_DATADATE
         AND B.BUSI_TYPE LIKE '1%'
         AND B.ASS_TYPE = '1' --债券
         AND B.BALANCE > 0
         AND TO_CHAR(B.END_DT, 'YYYYMMDD') >= I_DATADATE --到期日期
       LEFT JOIN SMTMODS_L_AGRE_BOND_INFO C
         ON T.SUBJECT_CD = C.STOCK_CD
        AND C.DATA_DATE = I_DATADATE
       WHERE T.TRADE_DIRECT = '逆回购'
         AND T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM,
                CASE
                   WHEN TRIM (T.COLL_SUBJECT_TYPE )LIKE '%国债%' THEN
                    'G13_1.3.1.H' --1.3.1国债最新估值
                   WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%政府债券%' THEN
                    'G13_1.3.2.H' --1.3.2地方政府债最新估值
                   WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%央票%' THEN
                    'G13_1.3.3.H' --1.3.3央票最新估值
                   WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%政府机构债券%' THEN
                    'G13_1.3.4.H' --1.3.4政府机构债券最新估值
                   WHEN TRIM(T.COLL_SUBJECT_TYPE) LIKE '%政策性银行%' THEN
                    'G13_1.3.5.H' --1.3.5政策性金融债最新估值
                   WHEN TRIM(T.COLL_SUBJECT_TYPE) IN ('保险公司资本补充债', '二级资本工具', '次级债', '商业银行') THEN
                    'G13_1.3.6.H' --1.3.6商业性金融债最新估值
                   WHEN TRIM(T.COLL_SUBJECT_TYPE) IN  ('企业债券', '一般公司债', '短期融资券', '超短期融资券', '中期票据', '绿色债务融资工具') THEN
                      CASE
                         WHEN C.APPRAISE_TYPE IN ('1','2') THEN 'G13_1.3.7.1.H' --1.3.7.1评级在AA+ (含 )以上
                         WHEN C.APPRAISE_TYPE IN ('3','4','5','6') THEN 'G13_1.3.7.2.H' --1.3.7.2评级在AA+至A之间
                         ELSE 'G13_1.3.7.3.H' --1.3.7.3评级在A以下或无评级
                       END
                   ELSE
                    'G13_1.3.8.H' --1.3.8其他债券
                 END;
    COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生G13-买入返售票据逆回购，插至目标表';
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
       ITEM_VAL, --指标值 (数值型 )
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G13' AS REP_NUM, --报表编号
             'G13_1.4.G' ITEM_NUM, --指标号
             SUM(NVL(A.BALANCE, 0)) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_FUND_REPURCHASE A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.GL_ITEM_CODE = '111102' --质押式买入返售票据
         AND A.BALANCE > 0
         AND A.END_DT >= I_DATADATE --回购业务信息表[SMTMODS_L_ACCT_FUND_REPURCHASE]?修改数据组范围：质押式回购放开数据范围(筛除20210101之前的脏数据)???卡到期日期>=当前日期?
      GROUP BY A.ORG_NUM ;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值 (数值型 )
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G13' AS REP_NUM, --报表编号
             'G13_1.4.H' ITEM_NUM, --指标号
             SUM(NVL(A.BALANCE, 0)) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_FUND_REPURCHASE A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.GL_ITEM_CODE = '111102' --质押式买入返售票据
         AND A.BALANCE > 0
         AND A.END_DT >= I_DATADATE --回购业务信息表[SMTMODS_L_ACCT_FUND_REPURCHASE]?修改数据组范围：质押式回购放开数据范围(筛除20210101之前的脏数据)???卡到期日期>=当前日期?
      GROUP BY A.ORG_NUM ;
    COMMIT;


    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值 (数值型 )
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G13' AS REP_NUM, --报表编号
             'G13_1.4.I' ITEM_NUM, --指标号
             SUM(NVL(A.BALANCE, 0)) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_FUND_REPURCHASE A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.GL_ITEM_CODE = '111102' --质押式买入返售票据
         AND A.BALANCE > 0
         AND A.END_DT >= I_DATADATE --回购业务信息表[SMTMODS_L_ACCT_FUND_REPURCHASE]?修改数据组范围：质押式回购放开数据范围(筛除20210101之前的脏数据)???卡到期日期>=当前日期?
      GROUP BY A.ORG_NUM ;
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
END proc_cbrc_idx2_g13;
