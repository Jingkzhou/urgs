CREATE OR REPLACE PROCEDURE PROC_CBRC_IDX2_G2502_DWD(II_DATADATE  IN STRING --跑批日期
                                                   )
/******************************
  @author:djh
  @create-date:20210930
  @description:G2502
  @modification history:
  m0.author-create_date-description
  需求编号：JLBA202503070010_关于吉林银行统一监管报送平台升级的需求 上线日期： 2025-12-26，修改人：狄家卉，提出人：统一监管报送平台升级  修改原因：由汇总数据修改为明细以及汇总
  --需求编号：JLBA202505140011_关于1104报表系统金融市场部报表取数逻辑变更的需求 上线日期：2025-07-29 修改人：常金磊，提出人：康立军 修改内容：调整债券、存单关联减值表的关联条件，解决关联重复问题
  需求编号：JLBA202505280011 上线日期：2025-09-19，修改人：狄家卉，提出人：赵翰君  修改原因：关于实现1104监管报送报表自动化采集加工的需求 增加009801清算中(国际业务部)心外币折人民币业务
[JLBA202507210012_关于调整财政性存款及一般性存款相关科目统计方式的相关需求][提出人：于佳禾][上线时间：20250918][修改人：石雨][修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
   
PM_RSDATA.CBRC_A_REPT_DWD_G2501
PM_RSDATA.CBRC_A_REPT_DWD_G2502
PM_RSDATA.CBRC_A_REPT_ITEM_VAL
PM_RSDATA.CBRC_FDM_LNAC
PM_RSDATA.CBRC_FDM_LNAC_PMT
PM_RSDATA.CBRC_TMP_ASSET_DEVALUE_PREPARE_G
PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL
PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL
PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL
PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT
PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_BRO
PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_SCALE
PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_BUSINESS
PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL
PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY3
PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY3
PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_STABLE
PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_UNSTABLE
PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL
PM_RSDATA.CBRC_TMP_FINANCIAL_MARKET
PM_RSDATA.CBRC_TMP_ITEM_VAL
PM_RSDATA.SMTMODS_L_AGRE_LOAN_CONTRACT
PM_RSDATA.SMTMODS_L_ACCT_CARD_CREDIT
PM_RSDATA.SMTMODS_L_ACCT_LOAN
PM_RSDATA.SMTMODS_L_AGRE_BILL_INFO
PM_RSDATA.SMTMODS_L_AGRE_BOND_INFO
PM_RSDATA.SMTMODS_L_AGRE_OTHER_SUBJECT_INFO
PM_RSDATA.SMTMODS_L_AGRE_REPURCHASE_GUARANTY_INFO
PM_RSDATA.SMTMODS_L_FIMM_FIN_PENE
PM_RSDATA.SMTMODS_L_FINA_ASSET_DEVALUE
PM_RSDATA.SMTMODS_L_FINA_GL
PM_RSDATA.SMTMODS_L_PUBL_RATE
PM_RSDATA.SMTMODS_V_PUB_FUND_CDS_BAL
PM_RSDATA.CBRC_V_PUB_FUND_INVEST
PM_RSDATA.CBRC_V_PUB_FUND_MMFUND
PM_RSDATA.CBRC_V_PUB_FUND_REPURCHASE

 *******************************/
 IS
  V_SCHEMA        VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE     VARCHAR(30); --当前储存过程名称
  V_TAB_NAME      VARCHAR(30); --目标表名
  I_DATADATE      STRING; --数据日期(数值型)YYYYMMDD
  V_DATADATE      VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  V_DATADATE_YEAR VARCHAR(10); --数据日期(字符型)YYYY
  D_DATADATE_CCY  STRING; --数据日期(日期型)YYYYMMDD
  V_STEP_ID       INTEGER; --任务号
  V_STEP_DESC     VARCHAR(4000); --任务描述
  V_STEP_FLAG     INTEGER; --任务执行状态标识
  V_ERRORCODE     VARCHAR(20); --错误编码
  V_ERRORDESC     VARCHAR(280); --错误内容
  V_PER_NUM       VARCHAR(30); --报表编号
  D_DATADATE      STRING;
  II_STATUS       INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM        VARCHAR2(30);

BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';
    I_DATADATE  := II_DATADATE;
    D_DATADATE  := I_DATADATE;
    V_SYSTEM    := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G2502');
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_PER_NUM       := 'G2502';
    V_TAB_NAME      := 'PM_RSDATA.CBRC_A_REPT_ITEM_VAL';
    V_DATADATE      := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYYMMDD');
    V_DATADATE_YEAR := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYY');
    D_DATADATE_CCY  := I_DATADATE;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']表历史数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G2502_DATA_COLLECT_TMP';

    --负债临时表 与G2501区别在于全量，不限制30天以内
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_STABLE'; --零售小企业稳定存款
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_UNSTABLE'; --零售小企业欠稳定存款
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_BUSINESS'; --大中型，有无业务关系存款
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_FINANCIAL_MARKET';  -- ADD BY DJH 20240510 金融市场部业务临时表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_ASSET_DEVALUE_PREPARE_G'; -- ADD BY DJH 20240510 减值临时表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_ITEM_VAL'; -- ADD BY DJH 20240510 同业金融部，金融市场部，投资银行部等业务指标加工临时报

    DELETE FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL T
     WHERE T.REP_NUM = 'G2502'
       AND DATA_DATE = I_DATADATE
       AND T.ITEM_NUM <> 'G25_2_2.1.A.2016'; --现金从总账配置表出数
    COMMIT;

    -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_A_REPT_DWD_G2502';

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
    V_STEP_DESC := '资产减值准备临时表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO PM_RSDATA.CBRC_TMP_ASSET_DEVALUE_PREPARE_G 
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
       ACCT_ID)--[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
      SELECT 
       T.DATA_DATE,
       T.RECORD_ORG,
       CASE
         WHEN SUBSTR(T.PRIN_SUBJ_NO, 1, 4) IN ('1111', '2111') THEN
          null
         ELSE
          T.BIZ_NO
       END BIZ_NO,  --回购业务对多笔，统一处理
       T.CURR,
       CASE
         WHEN SUBSTR(T.PRIN_SUBJ_NO, 1, 4) IN ('1111', '2111') THEN
          SUBSTR(T.PRIN_SUBJ_NO, 1, 4)
         ELSE
          T.PRIN_SUBJ_NO
       END PRIN_SUBJ_NO,
       T.FIVE_TIER_CLS,
       T.ACCT_NUM,
       SUM(NVL(T.PRIN_FINAL_RESLT, 0)) PRIN_FINAL_RESLT, --本金减值
       SUM(NVL(T.OFBS_FINAL_RESLT, 0)) OFBS_FINAL_RESLT,  --表外减值
       SUM(NVL(T.FINAL_ECL, 0)) FINAL_ECL,  --应计利息  ADD BY DJH 20240510 根据康哥核对“非信贷明细报表2024-03-27”  增加
       SUM(NVL(T.COLLBL_INT_FINAL_RESLT, 0)) COLLBL_INT_FINAL_RESLT, --应收利息
       ACCT_ID --[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
        FROM PM_RSDATA.SMTMODS_L_FINA_ASSET_DEVALUE T --资产减值准备
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY T.RECORD_ORG,
                CASE
                  WHEN SUBSTR(T.PRIN_SUBJ_NO, 1, 4) IN ('1111', '2111') THEN
                   null
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
                T.ACCT_ID; --[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
    COMMIT;


    --存款数据   20504在G2502里面放在一级和二级资本（监管扣除前，剩余期限不小于1年）中，因此进去G2502时剔除
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取3.1 稳定存款(零售稳定存款)至TMP_DEPOSIT_WD_DIFF_STABLE中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --3.来自零售和小企业客户的融资
    --3.1 稳定存款
    --========================零售稳定存款========================
    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_STABLE 
      (DATA_DATE, --数据日期,
       ORG_NUM, --机构号,
       ACCT_TYP, --账户类型,
       ACCT_CUR, --账户币种,
       ACCT_BAL, --账户余额,
       ACCT_BAL_RMB, --账户余额_人民币,
       FLAG, --数据标识,
       GL_ITEM_CODE, --科目号,
       CUST_ID, --客户号
       ACCT_NAM, --账户名称
       MATUR_DATE, --到期日
       REMAIN_TERM_CODE, --存款剩余期限代码
       ACCT_NUM, --账号
       BAL_TOTAL,
       FLAG_CODE)
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM, --机构号
       null AS ACCT_TYP, --账户类型
       null AS ACCT_CUR, --账户币种
       T.ACCT_BAL_RMB, --账户余额
       T.ACCT_BAL_RMB, --账户余额_人民币
       null FLAG, --数据标识
       T.GL_ITEM_CODE, --科目号
       T.CUST_ID, --客户号
       null ACCT_NAM, --账户名称
       T.MATUR_DATE, --到期日
       CASE
         WHEN T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX < 180 THEN --<6个月
          'A'
         WHEN REMAIN_TERM_CODE_QX >= 180 AND REMAIN_TERM_CODE_QX < 360 THEN --6-12个月
          'B'
         ELSE
          'C' --≥1年
       END AS REMAIN_TERM_CODE, --剩余期限代码
       T.ACCT_NUM, --账号
       0 AS BAL_TOTAL,
       '001' AS FLAG_CODE --零售
        FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY3 T
       WHERE T.DIFF IN ('A', 'C');

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取3.1 稳定存款(零售稳定存款)至TMP_DEPOSIT_WD_DIFF_STABLE中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取3.1 稳定存款(小企业稳定存款)至TMP_DEPOSIT_WD_DIFF_STABLE中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --========================小企业稳定存款========================
    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_STABLE 
      (DATA_DATE, --数据日期,
       ORG_NUM, --机构号,
       ACCT_TYP, --账户类型,
       ACCT_CUR, --账户币种,
       ACCT_BAL, --账户余额,
       ACCT_BAL_RMB, --账户余额_人民币,
       FLAG, --数据标识,
       GL_ITEM_CODE, --科目号,
       CUST_ID, --客户号
       ACCT_NAM, --账户名称
       MATUR_DATE, --到期日
       REMAIN_TERM_CODE, --存款剩余期限代码
       ACCT_NUM, --账号
       BAL_TOTAL,
       FLAG_CODE)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM, --机构号
             null AS ACCT_TYP, --账户类型
             null AS ACCT_CUR, --账户币种
             T.ACCT_BAL_RMB, --账户余额
             T.ACCT_BAL_RMB, --账户余额_人民币
             null FLAG, --数据标识
             T.GL_ITEM_CODE, --科目号
             T.CUST_ID, --客户号
             null ACCT_NAM, --账户名称
             T.MATUR_DATE, --到期日
             CASE
               WHEN T.REMAIN_TERM_CODE_QX IS NULL OR
                    REMAIN_TERM_CODE_QX < 180 THEN --<6个月
                'A'
               WHEN REMAIN_TERM_CODE_QX >= 180 AND REMAIN_TERM_CODE_QX < 360 THEN --6-12个月
                'B'
               ELSE
                'C' --≥1年
             END AS REMAIN_TERM_CODE, --剩余期限代码
             T.ACCT_NUM, --账号
             0 AS BAL_TOTAL,
             '002' AS FLAG_CODE --小微企业
        FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY3 T
       WHERE T.DIFF IN ('A', 'C')
         AND T.GL_ITEM_CODE <> '20110211'; --客户规模小微型或规模小于800万
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取3.1 稳定存款(小企业稳定存款)至TMP_DEPOSIT_WD_DIFF_STABLE中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取3.2 欠稳定存款(零售欠稳定存款)至TMP_DEPOSIT_WD_DIFF_UNSTABLE中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --3.2 欠稳定存款
    --========================零售欠稳定存款========================
    --来自G2501
    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_UNSTABLE 
      (DATA_DATE, --数据日期,
       ORG_NUM, --机构号,
       ACCT_TYP, --账户类型,
       ACCT_CUR, --账户币种,
       ACCT_BAL, --账户余额,
       ACCT_BAL_RMB, --账户余额_人民币,
       FLAG, --数据标识,
       GL_ITEM_CODE, --科目号,
       CUST_ID, --客户号
       ACCT_NAM, --账户名称
       MATUR_DATE, --到期日
       REMAIN_TERM_CODE, --存款剩余期限代码
       ACCT_NUM, --账号
       BAL_TOTAL,
       FLAG_CODE)
      SELECT DATA_DATE, --数据日期,
             ORG_NUM, --机构号,
             ACCT_TYP, --账户类型,
             ACCT_CUR, --账户币种,
             ACCT_BAL, --账户余额,
             ACCT_BAL_RMB, --账户余额_人民币,
             FLAG, --数据标识,
             GL_ITEM_CODE, --科目号,
             CUST_ID, --客户号
             ACCT_NAM, --账户名称
             MATUR_DATE, --到期日
             CASE
               WHEN REMAIN_TERM_CODE_QX IS NULL OR
                    REMAIN_TERM_CODE_QX < 180 THEN --<6个月
                'A'
               WHEN REMAIN_TERM_CODE_QX >= 180 AND REMAIN_TERM_CODE_QX < 360 THEN --6-12个月
                'B'
               ELSE
                'C' --≥1年
             END AS REMAIN_TERM_CODE, --剩余期限代码
             ACCT_NUM, --账号
             BAL_TOTAL,
             '001' AS FLAG_CODE
        FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL T
       WHERE FLAG_CODE IN ('02', '03')
         AND T.GL_ITEM_CODE <> '20110211'; --欠稳定，个体工商户
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_UNSTABLE 
      (DATA_DATE, --数据日期,
       ORG_NUM, --机构号,
       ACCT_TYP, --账户类型,
       ACCT_CUR, --账户币种,
       ACCT_BAL, --账户余额,
       ACCT_BAL_RMB, --账户余额_人民币,
       FLAG, --数据标识,
       GL_ITEM_CODE, --科目号,
       CUST_ID, --客户号
       ACCT_NAM, --账户名称
       MATUR_DATE, --到期日
       REMAIN_TERM_CODE, --存款剩余期限代码
       ACCT_NUM, --账号
       BAL_TOTAL,
       FLAG_CODE)
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM, --机构号
       null AS ACCT_TYP, --账户类型
       null AS ACCT_CUR, --账户币种
       T.ACCT_BAL_RMB, --账户余额
       T.ACCT_BAL_RMB, --账户余额_人民币
       null FLAG, --数据标识
       T.GL_ITEM_CODE, --科目号
       T.CUST_ID, --客户号
       null ACCT_NAM, --账户名称
       T.MATUR_DATE, --到期日
       CASE
         WHEN T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX < 180 THEN --<6个月
          'A'
         WHEN REMAIN_TERM_CODE_QX >= 180 AND REMAIN_TERM_CODE_QX < 360 THEN --6-12个月
          'B'
         ELSE
          'C' --≥1年
       END AS REMAIN_TERM_CODE, --剩余期限代码
       T.ACCT_NUM, --账号
       0 AS BAL_TOTAL,
       '002' AS FLAG_CODE --零售
        FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY3 T 
       WHERE T.DIFF IN ('B', 'D');
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取3.2 欠稳定存款(零售欠稳定存款)至TMP_DEPOSIT_WD_DIFF_UNSTABLE中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取3.2 欠稳定存款(小企业欠稳定存款)至TMP_DEPOSIT_WD_DIFF_UNSTABLE中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --========================小企业欠稳定存款========================
    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_UNSTABLE 
      (DATA_DATE, --数据日期,
       ORG_NUM, --机构号,
       ACCT_TYP, --账户类型,
       ACCT_CUR, --账户币种,
       ACCT_BAL, --账户余额,
       ACCT_BAL_RMB, --账户余额_人民币,
       FLAG, --数据标识,
       GL_ITEM_CODE, --科目号,
       CUST_ID, --客户号
       ACCT_NAM, --账户名称
       MATUR_DATE, --到期日
       REMAIN_TERM_CODE, --存款剩余期限代码
       ACCT_NUM, --账号
       BAL_TOTAL,
       FLAG_CODE)
      SELECT 
       T.DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.ACCT_TYP, --账户类型
       T.ACCT_CUR, --账户币种
       T.ACCT_BAL, --账户余额
       T.ACCT_BAL_RMB, --账户余额_人民币
       T.FLAG, --数据标识
       T.GL_ITEM_CODE, --科目号
       T.CUST_ID, --客户号
       T.ACCT_NAM, --账户名称
       T.MATUR_DATE, --到期日
       CASE
         WHEN REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX < 180 THEN --<6个月
          'A'
         WHEN REMAIN_TERM_CODE_QX >= 180 AND REMAIN_TERM_CODE_QX < 360 THEN --6-12个月
          'B'
         ELSE
          'C' --≥1年
       END AS REMAIN_TERM_CODE, --剩余期限代码
       T.ACCT_NUM, --账号
       0 AS BAL_TOTAL,
       '003' AS FLAG_CODE
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T
       INNER JOIN (SELECT DISTINCT ACCT_NUM, REAL_SCALE
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_SCALE
                    WHERE DATA_DATE = I_DATADATE) T1
          ON T.ACCT_NUM = T1.ACCT_NUM
        LEFT JOIN (SELECT DISTINCT ACCT_NUM
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT
                    WHERE DATA_DATE = I_DATADATE
                      AND SIGN IN ('A', 'B', 'C')) T2
          ON T.ACCT_NUM = T2.ACCT_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T2.ACCT_NUM IS NULL
         AND T1.REAL_SCALE = 'ST'
         AND T.GL_ITEM_CODE <> '20110211'; --客户规模小微型或规模小于800万
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_UNSTABLE 
      (DATA_DATE, --数据日期,
       ORG_NUM, --机构号,
       ACCT_TYP, --账户类型,
       ACCT_CUR, --账户币种,
       ACCT_BAL, --账户余额,
       ACCT_BAL_RMB, --账户余额_人民币,
       FLAG, --数据标识,
       GL_ITEM_CODE, --科目号,
       CUST_ID, --客户号
       ACCT_NAM, --账户名称
       MATUR_DATE, --到期日
       REMAIN_TERM_CODE, --存款剩余期限代码
       ACCT_NUM, --账号
       BAL_TOTAL,
       FLAG_CODE)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM, --机构号
             null AS ACCT_TYP, --账户类型
             null AS ACCT_CUR, --账户币种
             T.ACCT_BAL_RMB, --账户余额
             T.ACCT_BAL_RMB, --账户余额_人民币
             null FLAG, --数据标识
             T.GL_ITEM_CODE, --科目号
             T.CUST_ID, --客户号
             null ACCT_NAM, --账户名称
             T.MATUR_DATE, --到期日
             CASE
               WHEN T.REMAIN_TERM_CODE_QX IS NULL OR
                    REMAIN_TERM_CODE_QX < 180 THEN --<6个月
                'A'
               WHEN REMAIN_TERM_CODE_QX >= 180 AND REMAIN_TERM_CODE_QX < 360 THEN --6-12个月
                'B'
               ELSE
                'C' --≥1年
             END AS REMAIN_TERM_CODE, --剩余期限代码
             T.ACCT_NUM, --账号
             0 AS BAL_TOTAL,
             '004' AS FLAG_CODE --小微企业
        FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY3 T
       WHERE T.DIFF IN ('B', 'D')
         AND T.GL_ITEM_CODE <> '20110211';

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取3.2 欠稳定存款(小企业欠稳定存款)至TMP_DEPOSIT_WD_DIFF_UNSTABLE中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取4.1业务关系存款至TMP_DEPOSIT_WD_DIFF_BUSINESS中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --4.来自大中型企业、主权、公共部门实体、多边和国家开发银行的融资
    --4.1业务关系存款

    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_BUSINESS 
      (DATA_DATE, --数据日期,
       ORG_NUM, --机构号,
       ACCT_TYP, --账户类型,
       ACCT_CUR, --账户币种,
       ACCT_BAL, --账户余额,
       ACCT_BAL_RMB, --账户余额_人民币,
       FLAG, --数据标识,
       GL_ITEM_CODE, --科目号,
       CUST_ID, --客户号
       ACCT_NAM, --账户名称
       MATUR_DATE, --到期日
       REMAIN_TERM_CODE, --存款剩余期限代码
       ACCT_NUM, --账号
       BAL_TOTAL,
       FLAG_CODE)
      SELECT 
       T.DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.ACCT_TYP, --账户类型
       T.ACCT_CUR, --账户币种
       T.ACCT_BAL, --账户余额
       T.ACCT_BAL_RMB, --账户余额_人民币
       T.FLAG, --数据标识
       T.GL_ITEM_CODE, --科目号
       T.CUST_ID, --客户号
       T.ACCT_NAM, --账户名称
       T.MATUR_DATE, --到期日
       CASE
         WHEN T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX < 180 THEN --<6个月
          'A'
         WHEN REMAIN_TERM_CODE_QX >= 180 AND REMAIN_TERM_CODE_QX < 360 THEN --6-12个月
          'B'
         ELSE
          'C' --≥1年
       END AS REMAIN_TERM_CODE, --剩余期限代码
       T.ACCT_NUM, --账号
       0 AS BAL_TOTAL,
       '001' AS FLAG_CODE
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T
       INNER JOIN (SELECT DISTINCT ACCT_NUM, REAL_SCALE
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_SCALE
                    WHERE DATA_DATE = I_DATADATE) T1
          ON T.ACCT_NUM = T1.ACCT_NUM
       INNER JOIN (SELECT DISTINCT ACCT_NUM
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT
                    WHERE DATA_DATE = I_DATADATE
                      AND SIGN IN ('A', 'B', 'C', 'D')) T2
          ON T.ACCT_NUM = T2.ACCT_NUM
       INNER JOIN (SELECT DISTINCT ACCT_NUM
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_BRO
                    WHERE DATA_DATE = I_DATADATE) T3 --有业务关系
          ON T.ACCT_NUM = T3.ACCT_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T1.REAL_SCALE = 'BM'
         AND T.GL_ITEM_CODE <> '20110211'; --客户规模大于800万
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_BUSINESS 
      (DATA_DATE, --数据日期,
       ORG_NUM, --机构号,
       ACCT_TYP, --账户类型,
       ACCT_CUR, --账户币种,
       ACCT_BAL, --账户余额,
       ACCT_BAL_RMB, --账户余额_人民币,
       FLAG, --数据标识,
       GL_ITEM_CODE, --科目号,
       CUST_ID, --客户号
       ACCT_NAM, --账户名称
       MATUR_DATE, --到期日
       REMAIN_TERM_CODE, --存款剩余期限代码
       ACCT_NUM, --账号
       BAL_TOTAL,
       FLAG_CODE)
      SELECT 
       T.DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.ACCT_TYP, --账户类型
       T.ACCT_CUR, --账户币种
       T.ACCT_BAL, --账户余额
       T.ACCT_BAL_RMB, --账户余额_人民币
       T.FLAG, --数据标识
       T.GL_ITEM_CODE, --科目号
       T.CUST_ID, --客户号
       T.ACCT_NAM, --账户名称
       T.MATUR_DATE, --到期日
       CASE
         WHEN REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX < 180 THEN --<6个月
          'A'
         WHEN REMAIN_TERM_CODE_QX >= 180 AND REMAIN_TERM_CODE_QX < 360 THEN --6-12个月
          'B'
         ELSE
          'C' --≥1年
       END AS REMAIN_TERM_CODE, --剩余期限代码
       T.ACCT_NUM, --账号
       0 AS BAL_TOTAL,
       '002' AS FLAG_CODE
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T
       INNER JOIN (SELECT DISTINCT ACCT_NUM, REAL_SCALE
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_SCALE
                    WHERE DATA_DATE = I_DATADATE) T1
          ON T.ACCT_NUM = T1.ACCT_NUM
        LEFT JOIN (SELECT DISTINCT ACCT_NUM
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT
                    WHERE DATA_DATE = I_DATADATE
                      AND SIGN IN ('A', 'B', 'C', 'D')) T2
          ON T.ACCT_NUM = T2.ACCT_NUM
       INNER JOIN (SELECT DISTINCT ACCT_NUM
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_BRO
                    WHERE DATA_DATE = I_DATADATE) T3 --有业务关系
          ON T.ACCT_NUM = T3.ACCT_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T2.ACCT_NUM IS NULL
         AND T1.REAL_SCALE = 'BM'
         AND T.GL_ITEM_CODE <> '20110211'; --客户规模大于800万
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取4.1业务关系存款至TMP_DEPOSIT_WD_DIFF_BUSINESS中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取4.2非业务关系存款及其他无担保借款至TMP_DEPOSIT_WD_DIFF_BUSINESS中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --4.2非业务关系存款及其他无担保借款
    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_BUSINESS 
      (DATA_DATE, --数据日期,
       ORG_NUM, --机构号,
       ACCT_TYP, --账户类型,
       ACCT_CUR, --账户币种,
       ACCT_BAL, --账户余额,
       ACCT_BAL_RMB, --账户余额_人民币,
       FLAG, --数据标识,
       GL_ITEM_CODE, --科目号,
       CUST_ID, --客户号
       ACCT_NAM, --账户名称
       MATUR_DATE, --到期日
       REMAIN_TERM_CODE, --存款剩余期限代码
       ACCT_NUM, --账号
       BAL_TOTAL,
       FLAG_CODE)
      SELECT 
       T.DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.ACCT_TYP, --账户类型
       T.ACCT_CUR, --账户币种
       T.ACCT_BAL, --账户余额
       T.ACCT_BAL_RMB, --账户余额_人民币
       T.FLAG, --数据标识
       T.GL_ITEM_CODE, --科目号
       T.CUST_ID, --客户号
       T.ACCT_NAM, --账户名称
       T.MATUR_DATE, --到期日
       CASE
         WHEN REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX < 180 THEN --<6个月
          'A'
         WHEN REMAIN_TERM_CODE_QX >= 180 AND REMAIN_TERM_CODE_QX < 360 THEN --6-12个月
          'B'
         ELSE
          'C' --≥1年
       END AS REMAIN_TERM_CODE, --剩余期限代码
       T.ACCT_NUM, --账号
       0 AS BAL_TOTAL,
       '003' AS FLAG_CODE
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T
       INNER JOIN (SELECT DISTINCT ACCT_NUM, REAL_SCALE
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_SCALE
                    WHERE DATA_DATE = I_DATADATE) T1
          ON T.ACCT_NUM = T1.ACCT_NUM
       INNER JOIN (SELECT DISTINCT ACCT_NUM
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT
                    WHERE DATA_DATE = I_DATADATE
                      AND SIGN IN ('A', 'B', 'C', 'D')) T2
          ON T.ACCT_NUM = T2.ACCT_NUM
        LEFT JOIN (SELECT DISTINCT ACCT_NUM
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_BRO
                    WHERE DATA_DATE = I_DATADATE) T3 --无业务关系
          ON T.ACCT_NUM = T3.ACCT_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T3.ACCT_NUM IS NULL
         AND T1.REAL_SCALE = 'BM'
         AND T.GL_ITEM_CODE <> '20110211'; --客户规模大于800万
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_BUSINESS 
      (DATA_DATE, --数据日期,
       ORG_NUM, --机构号,
       ACCT_TYP, --账户类型,
       ACCT_CUR, --账户币种,
       ACCT_BAL, --账户余额,
       ACCT_BAL_RMB, --账户余额_人民币,
       FLAG, --数据标识,
       GL_ITEM_CODE, --科目号,
       CUST_ID, --客户号
       ACCT_NAM, --账户名称
       MATUR_DATE, --到期日
       REMAIN_TERM_CODE, --存款剩余期限代码
       ACCT_NUM, --账号
       BAL_TOTAL,
       FLAG_CODE)
      SELECT 
       T.DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.ACCT_TYP, --账户类型
       T.ACCT_CUR, --账户币种
       T.ACCT_BAL, --账户余额
       T.ACCT_BAL_RMB, --账户余额_人民币
       T.FLAG, --数据标识
       T.GL_ITEM_CODE, --科目号
       T.CUST_ID, --客户号
       T.ACCT_NAM, --账户名称
       T.MATUR_DATE, --到期日
       CASE
         WHEN REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX < 180 THEN --<6个月
          'A'
         WHEN REMAIN_TERM_CODE_QX >= 180 AND REMAIN_TERM_CODE_QX < 360 THEN --6-12个月
          'B'
         ELSE
          'C' --≥1年
       END AS REMAIN_TERM_CODE, --剩余期限代码
       T.ACCT_NUM, --账号
       0 AS BAL_TOTAL,
       '004' AS FLAG_CODE
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T
       INNER JOIN (SELECT DISTINCT ACCT_NUM, REAL_SCALE
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_SCALE
                    WHERE DATA_DATE = I_DATADATE) T1
          ON T.ACCT_NUM = T1.ACCT_NUM
        LEFT JOIN (SELECT DISTINCT ACCT_NUM
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT
                    WHERE DATA_DATE = I_DATADATE
                      AND SIGN IN ('A', 'B', 'C', 'D')) T2
          ON T.ACCT_NUM = T2.ACCT_NUM
        LEFT JOIN (SELECT DISTINCT ACCT_NUM
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_BRO
                    WHERE DATA_DATE = I_DATADATE) T3 --无业务关系
          ON T.ACCT_NUM = T3.ACCT_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T2.ACCT_NUM IS NULL
         AND T3.ACCT_NUM IS NULL
         AND T1.REAL_SCALE = 'BM'
         AND T.GL_ITEM_CODE <> '20110211'; --客户规模大于800万 --ALTER BY 石雨 20250929 JLBA202507210012 新增久悬财政性存款

    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取4.2非业务关系存款及其他无担保借款至TMP_DEPOSIT_WD_DIFF_BUSINESS中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --按客户分组，稳定存款中50万以上部分进欠稳定，进行拆分

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取3.1稳定存款.金额（按剩余期限）至A_REPT_ITEM_VAL中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --3.1稳定存款.金额（按剩余期限）.<6个月
    --3.1稳定存款.金额（按剩余期限）.6-12个月
    --3.1稳定存款.金额（按剩余期限）.≥1年
    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             CASE
               WHEN REMAIN_TERM_CODE = 'A' THEN --<6个月
                'G25_2_1.3.1.A.2016'
               WHEN REMAIN_TERM_CODE = 'B' THEN --6-12个月
                'G25_2_1.3.1.B.2016'
               WHEN REMAIN_TERM_CODE = 'C' THEN
                'G25_2_1.3.1.C.2016' --≥1年
             END AS ITEM_NUM,
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_STABLE T
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取3.1稳定存款.金额（按剩余期限）至A_REPT_ITEM_VAL中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取3.2欠稳定存款.金额（按剩余期限）至A_REPT_ITEM_VAL中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --3.2欠稳定存款.金额（按剩余期限）.<6个月
    --3.2欠稳定存款.金额（按剩余期限）.6-12个月
    --3.2欠稳定存款.金额（按剩余期限）.≥1年
    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             CASE
               WHEN REMAIN_TERM_CODE = 'A' THEN --<6个月
                'G25_2_1.3.2.A.2016'
               WHEN REMAIN_TERM_CODE = 'B' THEN --6-12个月
                'G25_2_1.3.2.B.2016'
               WHEN REMAIN_TERM_CODE = 'C' THEN
                'G25_2_1.3.2.C.2016' --≥1年
             END,
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_UNSTABLE T
       WHERE T.FLAG_CODE IN ('002', '004')--ALTER BY 石雨 20250929 JLBA202507210012 新增久悬财政性存款
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE;
    COMMIT;

    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_1.3.2.A.2016' AS ITEM_NUM, --add by djh20220622 注意与G2501规则相同，所有除不可提前支取的外，其他存款视为活期，要放在6个月内
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_UNSTABLE T
       WHERE T.FLAG_CODE IN ('001', '003') --ALTER BY 石雨 20250929 JLBA202507210012 新增久悬财政性存款
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取3.2欠稳定存款.金额（按剩余期限）至A_REPT_ITEM_VAL中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -----3.5.1其中：定期存款 '21510'其他定期储蓄存款（含有奖储蓄）没有到期日放次日
    /*INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
           (DATA_DATE, --数据日期
            ORG_NUM, --机构号
            SYS_NAM, --模块简称
            REP_NUM, --报表编号
            ITEM_NUM, --指标号
            ITEM_VAL, --指标值
            FLAG, --标志位
            B_CURR_CD --标志位
            )
          SELECT I_DATADATE,
                  A.ORG_NUM AS ORG_NUM,
                 'CBRC' AS SYS_NAM,
                 'G2502' AS REP_NUM,
                 'G25_2_1.3.2.A.2016', --3.2欠稳定存款
                 sum(A.CREDIT_BAL * B.CCY_RATE),
                  '2' AS FLAG,
                  'ALL' AS B_CURR_CD
            FROM  V_PUB_IDX_FINA_GL A
            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
              ON A.DATA_DATE = B.DATA_DATE
             AND A.CURR_CD = B.BASIC_CCY
             AND B.FORWARD_CCY = 'CNY'
           WHERE A.DATA_DATE = I_DATADATE
             AND A.ITEM_CD = '20110109' --'21510'其他定期储蓄存款（含有奖储蓄）
             AND A.CURR_CD <> 'BWB'
             AND A.CREDIT_BAL<>0
             AND A.ORG_NUM NOT LIKE '%0000' --去掉分行，汇总时不需要
             AND A.ORG_NUM NOT IN ('019899', --金融市场总部,因为包含了金融市场部等其它几个机构，汇总时会导致机构重复
                                   '510000', --磐石吉银村镇银行
                                   '222222', --东盛除双阳汇总
                                   '333333', --新双阳
                                   '444444', --净月潭除双阳
                                   '555555') --长春分行（除双阳、榆树、农安）
             GROUP BY ORG_NUM; --本外币合计去掉
           --  and A.ORG_NUM = '000000'
        COMMIT;
    */

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取4.1业务关系存款.金额（按剩余期限）至A_REPT_ITEM_VAL中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --4.1业务关系存款.金额（按剩余期限）.<6个月
    --4.1业务关系存款.金额（按剩余期限）.6-12个月
    --4.1业务关系存款.金额（按剩余期限）.≥1年
    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             CASE
               WHEN REMAIN_TERM_CODE = 'A' THEN --<6个月
                'G25_2_1.4.1.A.2016'
               WHEN REMAIN_TERM_CODE = 'B' THEN --6-12个月
                'G25_2_1.4.1.B.2016'
               WHEN REMAIN_TERM_CODE = 'C' THEN
                'G25_2_1.4.1.C.2016' --≥1年
             END AS ITEM_NUM,
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_BUSINESS T
       WHERE T.FLAG_CODE = '001' --有业务关系
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE;
    COMMIT;

    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_1.4.1.A.2016' AS ITEM_NUM, --add by djh20220622 注意与G2501规则相同，所有除不可提前支取的外，其他存款视为活期，要放在6个月内
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_BUSINESS T
       WHERE T.FLAG_CODE = '002' --有业务关系,且不是稳定存款那些类型的
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取4.1业务关系存款.金额（按剩余期限）至A_REPT_ITEM_VAL中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取4.2非业务关系存款及其他无担保借款.金额（按剩余期限）至A_REPT_ITEM_VAL中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --4.2非业务关系存款及其他无担保借款.金额（按剩余期限）.<6个月
    --4.2非业务关系存款及其他无担保借款.金额（按剩余期限）.6-12个月
    --4.2非业务关系存款及其他无担保借款.金额（按剩余期限）.≥1年
    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             CASE
               WHEN REMAIN_TERM_CODE = 'A' THEN --<6个月
                'G25_2_1.4.2.A.2016'
               WHEN REMAIN_TERM_CODE = 'B' THEN --6-12个月
                'G25_2_1.4.2.B.2016'
               WHEN REMAIN_TERM_CODE = 'C' THEN
                'G25_2_1.4.2.C.2016' --≥1年
             END AS ITEM_NUM,
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_BUSINESS T
       WHERE T.FLAG_CODE = '003' --无业务关系
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE;
    COMMIT;

    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_1.4.2.A.2016' AS ITEM_NUM, --add by djh20220622 注意与G2501规则相同，所有除不可提前支取的外，其他存款视为活期，要放在6个月内
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_BUSINESS T
       WHERE T.FLAG_CODE = '004' --无业务关系,且不是稳定存款那些类型的
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取4.2非业务关系存款及其他无担保借款.金额（按剩余期限）至A_REPT_ITEM_VAL中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --========================贷款========================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取个人贷款住房贷款至A_REPT_DWD_G2502';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



    -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --4住房抵押贷款
    --4.22风险权重高于35%
       INSERT
       INTO PM_RSDATA.CBRC_A_REPT_DWD_G2502 
         (DATA_DATE,
          ORG_NUM,
          DATA_DEPARTMENT,
          SYS_NAM,
          REP_NUM,
          ITEM_NUM,
          TOTAL_VALUE,
          COL_1,
          COL_2,
          COL_3,
          COL_4,
          COL_5,
          COL_6,
          COL_7,
          COL_8)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G2502' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_C < 180 AND T1.IDENTITY_CODE = '1') OR
                 (T1.IDENTITY_CODE = '2' AND PMT_REMAIN_TERM_C <= 90) THEN -- .<6个月 或者逾期小于90天（<-90）即欠本欠息小于90天
             'G25_2_2.4.2.2.A.2016'
            WHEN T1.PMT_REMAIN_TERM_C >= 180 AND T1.PMT_REMAIN_TERM_C < 360 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G25_2_2.4.2.2.B.2016'
            WHEN T1.PMT_REMAIN_TERM_C >= 360 AND T1.IDENTITY_CODE = '1' THEN
             'G25_2_2.4.2.2.C.2016'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT * T2.CCY_RATE AS TOTAL_VALUE, --贷款余额
          T.LOAN_NUM AS COL1, --贷款编号
          T.CURR_CD AS COL2, --币种
          T.ITEM_CD AS COL3, --科目
          TO_CHAR(T.ACTUAL_MATURITY_DT, 'YYYYMMDD') AS COL4, --贷款实际到期日
          TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYYMMDD') AS COL5, --（到期日）还款计划利息到期日/没有还款计划的利息取下月21号 D_DATADATE_CCY + 21
          T.ACCT_NUM AS COL6, --贷款合同编号
          T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数） 还款计划利息到期日/没有还款计划的利息取下月21号D_DATADATE_CCY + 21
          CASE
            WHEN T1.LOAN_GRADE_CD = '1' THEN
             '正常'
            WHEN T1.LOAN_GRADE_CD = '2' THEN
             '关注'
            WHEN T1.LOAN_GRADE_CD = '3' THEN
             '次级'
            WHEN T1.LOAN_GRADE_CD = '4' THEN
             '可疑'
            WHEN T1.LOAN_GRADE_CD = '5' THEN
             '损失'
          END AS COL8 --五级分类
           FROM PM_RSDATA.CBRC_FDM_LNAC T
           LEFT JOIN PM_RSDATA.CBRC_FDM_LNAC_PMT T1
             ON T.LOAN_NUM = T1.LOAN_NUM
            AND T.DATA_DATE = T1.DATA_DATE
           LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
             ON T2.DATA_DATE = I_DATADATE
            AND T2.BASIC_CCY = T1.CURR_CD --基准币种
            AND T2.FORWARD_CCY = 'CNY'
          WHERE T.DATA_DATE = I_DATADATE
            AND T.ACCT_TYP LIKE '0101%' --djh20210813 个人贷款住房贷款判断条件   逻辑与G0107 2.21.3住房按揭贷款 保持一致
            AND T.LOAN_GRADE_CD IN (1, 2); --五级分类为非不良（正常，关注）
       COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取个人贷款住房贷款至A_REPT_DWD_G2502完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取非个人贷款住房贷款至A_REPT_DWD_G2502中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --5向个人、非金融机构、主权、公共部门实体和政策性金融机构等发放的贷款（不含住房抵押贷款）
    --5.2.2风险权重高于35%
     INSERT 
       INTO PM_RSDATA.CBRC_A_REPT_DWD_G2502 
         (DATA_DATE,
          ORG_NUM,
          DATA_DEPARTMENT,
          SYS_NAM,
          REP_NUM,
          ITEM_NUM,
          TOTAL_VALUE,
          COL_1,
          COL_2,
          COL_3,
          COL_4,
          COL_5,
          COL_6,
          COL_7,
          COL_8)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G2502' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_C < 180 AND T1.IDENTITY_CODE = '1') OR
                 (T1.IDENTITY_CODE = '2' AND PMT_REMAIN_TERM_C <= 90) THEN -- .<6个月 或者逾期小于90天（<-90）即欠本欠息小于90天
             'G25_2_2.5.2.A.2016'
            WHEN T1.PMT_REMAIN_TERM_C >= 180 AND T1.PMT_REMAIN_TERM_C < 360 AND
                 T1.IDENTITY_CODE = '1' THEN
              'G25_2_2.5.2.B.2016'
            WHEN T1.PMT_REMAIN_TERM_C >= 360 AND T1.IDENTITY_CODE = '1' THEN
             'G25_2_2.5.2.C.2016'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT * T2.CCY_RATE AS TOTAL_VALUE, --贷款余额
          T.LOAN_NUM AS COL1, --贷款编号
          T.CURR_CD AS COL2, --币种
          T.ITEM_CD AS COL3, --科目
          TO_CHAR(T.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
          TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --（到期日）还款计划利息到期日/没有还款计划的利息取下月21号 D_DATADATE_CCY + 21
          T.ACCT_NUM AS COL6, --贷款合同编号
          T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数） 还款计划利息到期日/没有还款计划的利息取下月21号D_DATADATE_CCY + 21
          CASE
            WHEN T1.LOAN_GRADE_CD = '1' THEN
             '正常'
            WHEN T1.LOAN_GRADE_CD = '2' THEN
             '关注'
            WHEN T1.LOAN_GRADE_CD = '3' THEN
             '次级'
            WHEN T1.LOAN_GRADE_CD = '4' THEN
             '可疑'
            WHEN T1.LOAN_GRADE_CD = '5' THEN
             '损失'
          END AS COL8 --五级分类
         FROM PM_RSDATA.CBRC_FDM_LNAC T
        LEFT JOIN PM_RSDATA.CBRC_FDM_LNAC_PMT T1
          ON T.LOAN_NUM = T1.LOAN_NUM
         AND T.DATA_DATE = T1.DATA_DATE
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
          ON T2.DATA_DATE = I_DATADATE
         AND T2.BASIC_CCY = T1.CURR_CD --基准币种
         AND T2.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_GRADE_CD IN (1, 2) --五级分类为非不良（正常，关注）
         AND T.ACCT_TYP NOT LIKE '0101%' --去除住房抵押贷款
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN  ('130102', '130105'); --G25去掉转帖现数据129060101面值，来源表验证是129060101面值
    COMMIT;

        --modiy by djh 20241210 5.2.2风险权重高于35% A列取：正常类+关注类（M0+M1+M2+M3） 信用卡
      INSERT
      INTO PM_RSDATA.CBRC_A_REPT_DWD_G2502 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE)
        SELECT I_DATADATE,
               '009803',
               null AS  DATA_DEPARTMENT,
               'CBRC' AS SYS_NAM,
               'G2502' AS REP_NUM,
               'G25_2_2.5.2.A.2016' AS ITEM_NUM,
               SUM(NVL(M0, 0) + NVL(T.M1, 0) + NVL(T.M2, 0) + NVL(T.M3, 0) +
                   NVL(T.M4, 0) + NVL(T.M5, 0) + NVL(T.M6, 0) +
                   NVL(T.M6_UP, 0)) AS TOTAL_VALUE
          FROM PM_RSDATA.SMTMODS_L_ACCT_CARD_CREDIT T
         WHERE T.DATA_DATE = I_DATADATE
           AND LXQKQS <= 3; --连续欠款期数3期，即90天

       COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取非个人贷款住房贷款至A_REPT_DWD_G2502中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取17.1信用和流动性便利（可无条件撤销）至A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --17.表外项目
    --17.1信用和流动性便利（可无条件撤销） 60301可撤销贷款承诺、商票放在6月内
    INSERT 
      INTO PM_RSDATA.CBRC_A_REPT_DWD_G2502 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE,
         COL_1,
         COL_2,
         COL_3,
         COL_4,
         COL_7,
         COL_8)
        SELECT DATA_DATE,
               ORG_NUM,
               DATA_DEPARTMENT,
               SYS_NAM,
               'G2502' AS REP_NUM,
               'G25_2_2.16.1.A.2016' AS ITEM_NUM,
               TOTAL_VALUE,
               COL_1,
               COL_2,
               COL_3,
               COL_4,
               COL_7,
               COL_8
          FROM PM_RSDATA.CBRC_A_REPT_DWD_G2501
         WHERE ITEM_NUM = 'G25_1_1.2.1.5.1.A.2014';
         COMMIT;

    /*
    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM as ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_2.16.1.A.2016' AS ITEM_NUM,
             SUM(T.ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.REP_NUM = 'G2501'
         AND ITEM_NUM = 'G25_1_1.2.1.5.1.A.2014'
       GROUP BY T.ORG_NUM;
    COMMIT;*/
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取17.1信用和流动性便利（可无条件撤销）至A_REPT_ITEM_VAL结果表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取17.2信用和流动性便利（不可无条件撤销）至A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --17.2信用和流动性便利（不可无条件撤销） 信用卡和承兑汇票、未使用授信额度放在6月内
      INSERT
      INTO PM_RSDATA.CBRC_A_REPT_DWD_G2502 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE,
         COL_1,
         COL_2,
         COL_3,
         COL_4,
         COL_7,
         COL_8)
        SELECT DATA_DATE,
               ORG_NUM,
               DATA_DEPARTMENT,
               SYS_NAM,
               'G2502' AS REP_NUM,
               'G25_2_2.16.2.A.2016' AS ITEM_NUM,
               TOTAL_VALUE,
               COL_1,
               COL_2,
               COL_3,
               COL_4,
               COL_7,
               COL_8
          FROM PM_RSDATA.CBRC_A_REPT_DWD_G2501
         WHERE ITEM_NUM IN
               ('G25_1_1.2.1.4.10.1.A.2014', 'G25_1_1.2.1.4.10.2.1.A.2014');
         COMMIT;


   /* INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM as ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_2.16.2.A.2016' AS ITEM_NUM,
             SUM(T.ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.REP_NUM = 'G2501'
         AND ITEM_NUM IN
             ('G25_1_1.2.1.4.10.1.A.2014', 'G25_1_1.2.1.4.10.2.1.A.2014')
       GROUP BY T.ORG_NUM;
    COMMIT;*/
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取17.2信用和流动性便利（不可无条件撤销）至A_REPT_ITEM_VAL结果表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取17.3 担保、信用证及其他贸易融资工具至A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
      INSERT 
      INTO PM_RSDATA.CBRC_A_REPT_DWD_G2502 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE,
         COL_1,
         COL_2,
         COL_3,
         COL_4,
         COL_7,
         COL_8)
        SELECT DATA_DATE,
               ORG_NUM,
               DATA_DEPARTMENT,
               SYS_NAM,
               'G2502' AS REP_NUM,
               'G25_2_2.16.3.A.2016' AS ITEM_NUM,
               TOTAL_VALUE,
               COL_1,
               COL_2,
               COL_3,
               COL_4,
               COL_7,
               COL_8
          FROM PM_RSDATA.CBRC_A_REPT_DWD_G2501
         WHERE ITEM_NUM IN
               ('G25_1_1.2.1.5.2.A.2014', 'G25_1_1.2.1.5.3.A.2014');
      COMMIT;

      INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         DATA_DEPARTMENT, --数据条线
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         B_CURR_CD)
        SELECT 
         I_DATADATE AS DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         SUM(TOTAL_VALUE) AS ITEM_VAL,
         '2' AS FLAG,
         'ALL' CURR_CD
          FROM PM_RSDATA.CBRC_A_REPT_DWD_G2502
         GROUP BY ORG_NUM, DATA_DEPARTMENT, SYS_NAM, REP_NUM, ITEM_NUM;

      COMMIT;

 /*   --17.3 担保、信用证及其他贸易融资工具 1开出信用证敞口 2保函敞口放在6月内
    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM as ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_2.16.3.A.2016' AS ITEM_NUM,
             SUM(T.ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.REP_NUM = 'G2501'
         AND ITEM_NUM IN
             ('G25_1_1.2.1.5.2.A.2014', 'G25_1_1.2.1.5.3.A.2014')
       GROUP BY T.ORG_NUM;
    COMMIT;*/
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取17.3 担保、信用证及其他贸易融资工具至A_REPT_ITEM_VAL结果表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -- ADD BY DJH 20230718  理财资管 1.一级和二级资本（监管扣除前，剩余期限不小于1年）
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取1.一级和二级资本（监管扣除前，剩余期限不小于1年）至A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --1.一级和二级资本（监管扣除前，剩余期限不小于1年）
    --前台初始化化，直接取 G01的 57.未分配利润
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取1.一级和二级资本（监管扣除前，剩余期限不小于1年至A_REPT_ITEM_VAL结果表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -- ADD BY DJH 20230718  理财资管 17.4非契约性义务   穿透前的全量资产G0602保持一致
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取17.4非契约性义务至A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --17.4非契约性义务
    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             T.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             'G25_2_2.16.4.A.2016' AS ITEM_NUM, --指标号
             SUM(T.INV_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.SMTMODS_L_FIMM_FIN_PENE T
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.DATA_TYP LIKE 'A%' --资产负债类型为资产
         AND T.INV_FLAY = '否' --穿透前
       GROUP BY T.ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '17.4非契约性义务至A_REPT_ITEM_VAL结果表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ----------------------------------------金融市场部取数 add by chm 20231012-------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取5.3担保融资至A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009804',
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.MATURE_DATE - A.DATA_DATE >= 360 THEN
                'G25_2_1.5.3.C.2016'
               WHEN A.MATURE_DATE - A.DATA_DATE >= 180 THEN
                'G25_2_1.5.3.B.2016'
               ELSE
                'G25_2_1.5.3.A.2016'
             END AS ITEM_NUM,
             SUM(BALANCE),
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_V_PUB_FUND_MMFUND A
       WHERE DATA_DATE = I_DATADATE
         AND ACCT_TYP IN ('20303', '20304') --20303 回购式再贴现  20304 买断式再贴现   取全行的再贴现
       GROUP BY CASE
                  WHEN A.MATURE_DATE - A.DATA_DATE >= 360 THEN
                   'G25_2_1.5.3.C.2016'
                  WHEN A.MATURE_DATE - A.DATA_DATE >= 180 THEN
                   'G25_2_1.5.3.B.2016'
                  ELSE
                   'G25_2_1.5.3.A.2016'
                END;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取5.3担保融资至A_REPT_ITEM_VAL结果表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取6.3担保融资至A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心，2111卖出回购外币折人民币本金余额
    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             ITEM_CD,
             SUM(ACCRUAL),
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT I_DATADATE AS DATA_DATE, --数据日期
                     ORG_NUM,
                     'CBRC' AS SYS_NAM, --模块简称
                     'G2502' AS REP_NUM, --报表编号
                     CASE
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 360 THEN
                        'G25_2_1.6.3.C.2016'
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 180 THEN
                        'G25_2_1.6.3.B.2016'
                       ELSE
                        'G25_2_1.6.3.A.2016'
                     END AS ITEM_CD,
                     SUM(A.ACCT_BAL_RMB) AS ACCRUAL,
                     '2' AS FLAG,
                     'ALL' AS B_CURR_CD
                FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
               WHERE FLAG = '07' --卖出回购
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY ORG_NUM,
                        CASE
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 360 THEN
                           'G25_2_1.6.3.C.2016'
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 180 THEN
                           'G25_2_1.6.3.B.2016'
                          ELSE
                           'G25_2_1.6.3.A.2016'
                        END
              UNION ALL --ADD BY DJH 20240510  金融市场部 009804 补充拆入 2003同业拆入
              SELECT I_DATADATE AS DATA_DATE, --数据日期
                     ORG_NUM,
                     'CBRC' AS SYS_NAM, --模块简称
                     'G2502' AS REP_NUM, --报表编号
                     CASE
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 360 THEN
                        'G25_2_1.6.3.C.2016'
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 180 THEN
                        'G25_2_1.6.3.B.2016'
                       ELSE
                        'G25_2_1.6.3.A.2016'
                     END,
                     SUM(A.ACCT_BAL_RMB) AS ACCRUAL,
                     '2' AS FLAG,
                     'ALL' AS B_CURR_CD
                FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
               WHERE A.FLAG = '05' --同业拆入(有其他机构)
                 AND ACCT_BAL_RMB <> 0
                 AND A.ORG_NUM = '009804'
               GROUP BY ORG_NUM,
                        CASE
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 360 THEN
                           'G25_2_1.6.3.C.2016'
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 180 THEN
                           'G25_2_1.6.3.B.2016'
                          ELSE
                           'G25_2_1.6.3.A.2016'
                        END)
       GROUP BY ITEM_CD,ORG_NUM;

    COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取6.3担保融资至A_REPT_ITEM_VAL结果表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取10.以上未包括的所有其它负债和权益至A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009804',
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             ITEM_CD,
             SUM(ACCRUAL),
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT CASE
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 360 THEN
                        'G25_2_1.10.C.2016'
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 180 THEN
                        'G25_2_1.10.B.2016'
                       ELSE
                        'G25_2_1.10.A.2016'
                     END AS ITEM_CD,
                     SUM(A.INTEREST_ACCURAL) AS ACCRUAL
                FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
               WHERE FLAG = '07' --卖出回购
                 AND A.DATA_DATE = I_DATADATE
                 AND A.MATUR_DATE > I_DATADATE
               GROUP BY CASE
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 360 THEN
                           'G25_2_1.10.C.2016'
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 180 THEN
                           'G25_2_1.10.B.2016'
                          ELSE
                           'G25_2_1.10.A.2016'
                        END
              UNION ALL
              SELECT 'G25_2_1.10.A.2016' AS ITEM_CD, -SUM(T.DEBIT_BAL)
                FROM PM_RSDATA.SMTMODS_L_FINA_GL T
               WHERE DATA_DATE = I_DATADATE
                 AND ITEM_CD = '20040202'
                 AND ORG_NUM = '990000'
                 AND T.CURR_CD = 'CNY' --再贴现的利息调整取全行，放进剩余期限<6个月
              UNION ALL  --ADD BY DJH 20240510  金融市场部 009804 补充拆入 2003同业拆入利息
              SELECT CASE
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 360 THEN
                        'G25_2_1.10.C.2016'
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 180 THEN
                        'G25_2_1.10.B.2016'
                       ELSE
                        'G25_2_1.10.A.2016'
                     END AS ITEM_CD,
                     SUM(A.INTEREST_ACCURAL) AS ACCRUAL
                FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
               WHERE A.FLAG = '05' --同业拆入(有其他机构)
                  AND INTEREST_ACCURAL <> 0
                  AND A.ORG_NUM = '009804'
               GROUP BY CASE
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 360 THEN
                           'G25_2_1.10.C.2016'
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 180 THEN
                           'G25_2_1.10.B.2016'
                          ELSE
                           'G25_2_1.10.A.2016'
                        END)
       GROUP BY ITEM_CD;

    COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取10.以上未包括的所有其它负债和权益至A_REPT_ITEM_VAL结果表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取7.3.1以一级资产作抵押且抵押物可用于再抵押至A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             B.ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN B.END_DT - B.DATA_DATE >= 360 THEN
                'G25_2_2.7.3.1.C.2016'
               WHEN B.END_DT - B.DATA_DATE >= 180 THEN
                'G25_2_2.7.3.1.B.2016'
               ELSE
                'G25_2_2.7.3.1.A.2016'
             END,
             SUM(A.BALANCE * TT.CCY_RATE),
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.SMTMODS_L_AGRE_REPURCHASE_GUARANTY_INFO A
       INNER JOIN PM_RSDATA.CBRC_V_PUB_FUND_REPURCHASE B
          ON A.ACCT_NUM = B.ACCT_NUM
         AND B.DATA_DATE = I_DATADATE
         AND B.BUSI_TYPE LIKE '1%' --买入返售
         AND B.ASS_TYPE = '1' --债券
         AND B.BALANCE > 0
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = B.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.PLEDGE_ASSETS_TYPE = 'A' --质押物为一级资产
       GROUP BY B.ORG_NUM,CASE
                  WHEN B.END_DT - B.DATA_DATE >= 360 THEN
                   'G25_2_2.7.3.1.C.2016'
                  WHEN B.END_DT - B.DATA_DATE >= 180 THEN
                   'G25_2_2.7.3.1.B.2016'
                  ELSE
                   'G25_2_2.7.3.1.A.2016'
                END;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取7.3.1以一级资产作抵押且抵押物可用于再抵押至A_REPT_ITEM_VAL结果表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取7.3.2其他贷款至A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

     INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              '009804',
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              ITEM_NUM,
              SUM(BALANCE),
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT CASE
                        WHEN A.MATURITY_DT - A.DATA_DATE >= 360 THEN
                         'G25_2_2.7.3.2.C.2016'
                        WHEN A.MATURITY_DT - A.DATA_DATE >= 180 THEN
                         'G25_2_2.7.3.2.B.2016'
                        ELSE
                         'G25_2_2.7.3.2.A.2016'
                      END AS ITEM_NUM,
                      SUM(LOAN_ACCT_BAL) AS BALANCE
                 FROM PM_RSDATA.SMTMODS_L_ACCT_LOAN A
                WHERE DATA_DATE = I_DATADATE
                  AND (A.ITEM_CD LIKE '130102%' OR A.ITEM_CD LIKE '130105%')
                  AND A.LOAN_ACCT_BAL > 0
                     --AND ORG_NUM NOT LIKE '51%'
                  AND A.ORG_NUM NOT LIKE '5%'
                  AND A.ORG_NUM NOT LIKE '6%' --ADD BY CH 20231031
                GROUP BY CASE
                           WHEN A.MATURITY_DT - A.DATA_DATE >= 360 THEN
                            'G25_2_2.7.3.2.C.2016'
                           WHEN A.MATURITY_DT - A.DATA_DATE >= 180 THEN
                            'G25_2_2.7.3.2.B.2016'
                           ELSE
                            'G25_2_2.7.3.2.A.2016'
                         END
               UNION ALL
               SELECT CASE
                        WHEN B.END_DT - B.DATA_DATE >= 360 THEN
                         'G25_2_2.7.3.2.C.2016'
                        WHEN B.END_DT - B.DATA_DATE >= 180 THEN
                         'G25_2_2.7.3.2.B.2016'
                        ELSE
                         'G25_2_2.7.3.2.A.2016'
                      END AS ITEM_NUM,
                      SUM(A.BALANCE * TT.CCY_RATE) AS BALANCE
                 FROM PM_RSDATA.SMTMODS_L_AGRE_REPURCHASE_GUARANTY_INFO A
                INNER JOIN PM_RSDATA.CBRC_V_PUB_FUND_REPURCHASE B
                   ON A.ACCT_NUM = B.ACCT_NUM
                  AND B.DATA_DATE = I_DATADATE
                  AND B.BUSI_TYPE LIKE '1%' --买入返售
                  AND B.ASS_TYPE = '1' --债券
                  AND B.BALANCE > 0
                 LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
                   ON TT.CCY_DATE = I_DATADATE
                  AND TT.BASIC_CCY = B.CURR_CD
                  AND TT.FORWARD_CCY = 'CNY'
                WHERE A.DATA_DATE = I_DATADATE
                  AND A.PLEDGE_ASSETS_TYPE <> 'A'
                  AND A.ORG_NUM NOT LIKE '5%'
                  AND A.ORG_NUM NOT LIKE '6%' --ADD BY CH 20231031
                GROUP BY CASE
                           WHEN B.END_DT - B.DATA_DATE >= 360 THEN
                            'G25_2_2.7.3.2.C.2016'
                           WHEN B.END_DT - B.DATA_DATE >= 180 THEN
                            'G25_2_2.7.3.2.B.2016'
                           ELSE
                            'G25_2_2.7.3.2.A.2016'
                         END
               UNION ALL   --ADD BY DJH 20240510  金融市场部 009804  补充买入返售票据
               SELECT CASE
                        WHEN A.END_DT - B.DATA_DATE >= 360 THEN
                         'G25_2_2.7.3.2.C.2016'
                        WHEN A.END_DT - B.DATA_DATE >= 180 THEN
                         'G25_2_2.7.3.2.B.2016'
                        ELSE
                         'G25_2_2.7.3.2.A.2016'
                      END AS ITEM_NUM,
                      SUM(A.BALANCE * U.CCY_RATE) AS BALANCE
                 FROM PM_RSDATA.CBRC_V_PUB_FUND_REPURCHASE A
                 LEFT JOIN PM_RSDATA.SMTMODS_L_AGRE_BILL_INFO B -- 商业汇票票面信息表
                   ON A.SUBJECT_CD = B.BILL_NUM
                  AND B.DATA_DATE = I_DATADATE
                 LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
                   ON U.CCY_DATE = I_DATADATE
                  AND U.BASIC_CCY = A.CURR_CD --基准币种
                  AND U.FORWARD_CCY = 'CNY' --折算币种
                WHERE A.DATA_DATE = I_DATADATE
                  AND A.GL_ITEM_CODE = '111102' --质押式买入返售票据
                  AND A.BALANCE > 0
                  AND A.ORG_NUM NOT LIKE '5%'
                  AND A.ORG_NUM NOT LIKE '6%'
                GROUP BY CASE
                           WHEN A.END_DT - B.DATA_DATE >= 360 THEN
                            'G25_2_2.7.3.2.C.2016'
                           WHEN A.END_DT - B.DATA_DATE >= 180 THEN
                            'G25_2_2.7.3.2.B.2016'
                           ELSE
                            'G25_2_2.7.3.2.A.2016'
                         END)
        GROUP BY ITEM_NUM;
    COMMIT;



    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取7.3.2其他贷款至A_REPT_ITEM_VAL结果表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取8.3.1 一级资产（未纳入以上项目）至A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ---依赖G21

    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN DC_DATE >= 360 THEN
                'G25_2_2.8.3.1.C.2016'
               WHEN DC_DATE >= 180 THEN
                'G25_2_2.8.3.1.B.2016'
               ELSE
                'G25_2_2.8.3.1.A.2016'
             END AS ITEM_NUM,
             SUM(A.PRINCIPAL_BALANCE_CNY *
                 (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) / A.ACCT_BAL_CNY),
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        from PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A --债券投资分析表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'
         AND ((A.ISSU_ORG = 'D02' AND A.STOCK_PRO_TYPE LIKE 'C%') OR
             (A.ISSU_ORG = 'A01' AND A.STOCK_PRO_TYPE = 'A')) --政策银行债 , 国债
         AND A.INVEST_TYP = '00'
         AND A.DC_DATE > 0 --不取逾期
         AND ACCT_BAL_CNY <> 0   --JLBA202411080004
       GROUP BY ORG_NUM,
                CASE
                  WHEN DC_DATE >= 360 THEN
                   'G25_2_2.8.3.1.C.2016'
                  WHEN DC_DATE >= 180 THEN
                   'G25_2_2.8.3.1.B.2016'
                  ELSE
                   'G25_2_2.8.3.1.A.2016'
                END;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取8.3.1 一级资产（未纳入以上项目）至A_REPT_ITEM_VAL结果表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取8.3.2 2A资产至A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN DC_DATE >= 360 THEN
                'G25_2_2.8.3.2.C.2016'
               WHEN DC_DATE >= 180 THEN
                'G25_2_2.8.3.2.B.2016'
               ELSE
                'G25_2_2.8.3.2.A.2016'
             END,
             SUM(A.PRINCIPAL_BALANCE_CNY *
                 (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) / A.ACCT_BAL_CNY),
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND ((A.STOCK_PRO_TYPE = 'A' AND A.ISSU_ORG = 'A02') OR --地方政府债
             (A.APPRAISE_TYPE IN ('1', '2', '3', '4') AND --信用评级是>=AA的债券
             A.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券，短期融资券，公司债，企业债，中期票据 且信用评级是AA的债券
             OR
             A.STOCK_CD IN ('032000573', '032001060', 'X0003118A1600001')) --20四平城投PPN001  20四平城投PPN002 RPA取数没有债券评级，此处特殊处理
         AND A.INVEST_TYP = '00'
         AND A.DC_DATE > 0 --不取逾期
         AND A.STOCK_NAM <> '18华阳经贸CP001' --特殊处理，算逾期
         AND ACCT_BAL_CNY <> 0   --JLBA202411080004
       GROUP BY ORG_NUM,
                CASE
                  WHEN DC_DATE >= 360 THEN
                   'G25_2_2.8.3.2.C.2016'
                  WHEN DC_DATE >= 180 THEN
                   'G25_2_2.8.3.2.B.2016'
                  ELSE
                   'G25_2_2.8.3.2.A.2016'
                END;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取8.3.2 2A资产至A_REPT_ITEM_VAL结果表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取8.3.3 2B资产至A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN DC_DATE >= 360 THEN
                'G25_2_2.8.3.3.C.2016'
               WHEN DC_DATE >= 180 THEN
                'G25_2_2.8.3.3.B.2016'
               ELSE
                'G25_2_2.8.3.3.A.2016'
             END,
             SUM(A.PRINCIPAL_BALANCE_CNY *
                 (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) / A.ACCT_BAL_CNY),
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND (A.APPRAISE_TYPE IN ('5', '6', '7', '8', '9', 'a') AND
             A.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券，短期融资券，公司债，企业债，中期票据 且信用评级是2B的债券
         AND A.INVEST_TYP = '00'
         AND A.DC_DATE > 0 --不取逾期
         AND A.STOCK_NAM <> '18华阳经贸CP001' --特殊处理
         AND ACCT_BAL_CNY <> 0   --JLBA202411080004
       GROUP BY ORG_NUM,
                CASE
                  WHEN DC_DATE >= 360 THEN
                   'G25_2_2.8.3.3.C.2016'
                  WHEN DC_DATE >= 180 THEN
                   'G25_2_2.8.3.3.B.2016'
                  ELSE
                   'G25_2_2.8.3.3.A.2016'
                END;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取8.3.3 2B资产至A_REPT_ITEM_VAL结果表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取9.2其他资产至A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -------9.2其他  一级资产，2A资产的抵押面额（账面余额*质押面额）/持有仓位）+其他信用评级的债券账面余额（抵押+未抵押）包含同业存单
    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.DC_DATE >= 360 THEN
                'G25_2_2.9.2.C.2016' ---1年以上
               WHEN A.DC_DATE >= 180 THEN
                'G25_2_2.9.2.B.2016' --6个月-1年
               ELSE
                'G25_2_2.9.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT A.ORG_NUM,
                     DC_DATE,
                     SUM(CASE
                           WHEN ((A.ISSU_ORG = 'D02' AND
                                A.STOCK_PRO_TYPE LIKE 'C%') OR --（发行主体类型：D02政策性银行，债券产品类型：C是金融债（大类）包含很多小类）
                                (A.ISSU_ORG = 'A01' AND A.STOCK_PRO_TYPE = 'A')) THEN --（发行主体类型：A01中央政府，债券产品类型：A政府债券（指我国政府发行债券））
                            A.PRINCIPAL_BALANCE_CNY * A.COLL_AMT_CNY / A.ACCT_BAL_CNY  --（账面余额*质押面额）/持有仓位）
                           WHEN ((A.STOCK_PRO_TYPE = 'A' AND A.ISSU_ORG = 'A02') OR --（发行主体类型：A02地方政府，债券产品类型：A政府债券（指我国政府发行债券）），
                                (A.APPRAISE_TYPE IN ('1', '2', '3', '4') AND --信用评级是>=AA的债券
                                A.STOCK_PRO_TYPE IN
                                ('D01', 'D02', 'D04', 'D05')) --（债券产品类型：D01短期融资券，D02中期票据，D04企业债，D05公司债， 且信用评级是AA的债券）
                                OR
                                A.STOCK_CD IN
                                ('032000573', '032001060', 'X0003118A1600001')) THEN --债券编号'032000573' 20四平城投PPN001, '032001060' 20四平城投PPN002-外部评级AA,18翔控01(X0003118A1600001)-外部评级AA+
                            A.PRINCIPAL_BALANCE_CNY * A.COLL_AMT_CNY / A.ACCT_BAL_CNY
                           ELSE
                            A.PRINCIPAL_BALANCE_CNY
                         END) AS ITEM_VAL
                FROM PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A
               WHERE A.INVEST_TYP = '00'
                 AND A.DC_DATE > 0 --不取逾期
                 AND A.STOCK_NAM <> '18华阳经贸CP001' --特殊处理，算逾期
                 AND ACCT_BAL_CNY <> 0   --JLBA202411080004
               GROUP BY A.ORG_NUM, DC_DATE
              UNION ALL
              SELECT A.ORG_NUM, DC_DATE, SUM(ACCT_BAL_RMB)
                FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE FLAG = '04'
                AND ORG_NUM = '009804' --此处不限制机构，同业存单 包含金融市场部，同业金融部2个部分数据  -ADD BY DJH 20240510  同业金融部 009820  分开写也可同数据源
               GROUP BY A.ORG_NUM, DC_DATE) A
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.DC_DATE >= 360 THEN
                   'G25_2_2.9.2.C.2016' ---1年以上
                  WHEN A.DC_DATE >= 180 THEN
                   'G25_2_2.9.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.9.2.A.2016'
                END;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取9.2其他资产至A_REPT_ITEM_VAL结果表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --ADD BY DJH 20240510  同业金融部 009820
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取6.1业务关系存款至A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --6.1业务关系存款
    /*分行的东北证券股份有限公司和永诚保险资产管理有限公司的持有仓位放<6个月中，资产类型为同业存放的定期中取字段原币金额按剩余期限划分报在009820机构*/

    INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM,  --分行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             'G25_2_1.6.1.A.2016' AS ITEM_NUM, --6个月内
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT A.GL_ITEM_CODE,
                     A.CUST_ID,
                     A.JYDSTYDM,
                     SUM(A.BALANCE * CCY_RATE) ITEM_VAL,
                     MATURE_DATE
                FROM PM_RSDATA.CBRC_V_PUB_FUND_MMFUND A
                LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
                  ON TT.CCY_DATE = I_DATADATE
                 AND TT.BASIC_CCY = A.CURR_CD
                 AND TT.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                -- AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201201' --同业存放活期款项
                 AND A.BALANCE <> 0
                 AND A.CUST_ID  IN ('8913402328', '8916869348') --8913402328东北证券股份有限公司 8916869348永诚保险资产管理有限公司
               GROUP BY A.GL_ITEM_CODE, A.CUST_ID, A.JYDSTYDM, MATURE_DATE) A;
    COMMIT;
    --ADD BY DJH 20240510  同业金融部 009820
      INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         B_CURR_CD)
        SELECT I_DATADATE AS DATA_DATE, --数据日期
               '009820' AS ORG_NUM, --分行报在009820机构
               'CBRC' AS SYS_NAM, --模块简称
               'G2502' AS REP_NUM, --报表编号
               CASE
                 WHEN A.MATURE_DATE - I_DATADATE >= 360 THEN
                  'G25_2_1.6.1.C.2016' ---1年以上
                 WHEN A.MATURE_DATE - I_DATADATE >= 180 THEN
                  'G25_2_1.6.1.B.2016' --6个月-1年
                 ELSE
                  'G25_2_1.6.1.A.2016'
               END AS ITEM_NUM,
               SUM(ITEM_VAL) AS ITEM_VAL,
               '2' AS FLAG,
               'ALL' AS B_CURR_CD
          FROM (SELECT A.GL_ITEM_CODE,
                       A.CUST_ID,
                       A.JYDSTYDM,
                       SUM(A.BALANCE * CCY_RATE) ITEM_VAL,
                       MATURE_DATE
                  FROM PM_RSDATA.CBRC_V_PUB_FUND_MMFUND A
                  LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
                    ON TT.CCY_DATE = I_DATADATE
                   AND TT.BASIC_CCY = A.CURR_CD
                   AND TT.FORWARD_CCY = 'CNY'
                 WHERE A.DATA_DATE = I_DATADATE
                   AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201202' --同业存放的定期
                   AND A.BALANCE <> 0
                   AND A.ORG_NUM NOT LIKE '5%'
                   AND A.ORG_NUM NOT LIKE '6%'
                 GROUP BY A.GL_ITEM_CODE, A.CUST_ID, A.JYDSTYDM, MATURE_DATE) A
         GROUP BY CASE
                    WHEN A.MATURE_DATE - I_DATADATE >= 360 THEN
                     'G25_2_1.6.1.C.2016' ---1年以上
                    WHEN A.MATURE_DATE - I_DATADATE >= 180 THEN
                     'G25_2_1.6.1.B.2016' --6个月-1年
                    ELSE
                     'G25_2_1.6.1.A.2016'
                  END;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取6.1业务关系存款至A_REPT_ITEM_VAL结果表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取6.2非业务关系存款及其他无担保借款至A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --6.2非业务关系存款及其他无担保借款
   /*1.分行：其他非结算的科目20120103贷+20120104贷+20120105贷+20120109贷+20120110贷-东北证券股份有限公司-永诚保险资产管理有限公司% 放到6个月中报在009820机构
     2.009820：同业拆入持有仓位+同业存单发行持有仓位按照剩余期限取值*/
   --ADD BY DJH 20240510  同业金融部 009820
     INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM,  --分行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             'G25_2_1.6.2.A.2016' AS ITEM_NUM, --6个月内
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT A.GL_ITEM_CODE,
                     A.CUST_ID,
                     A.JYDSTYDM,
                     SUM(A.BALANCE * CCY_RATE) ITEM_VAL,
                     MATURE_DATE
                FROM PM_RSDATA.CBRC_V_PUB_FUND_MMFUND A
                LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
                  ON TT.CCY_DATE = I_DATADATE
                 AND TT.BASIC_CCY = A.CURR_CD
                 AND TT.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.GL_ITEM_CODE IN('20120103','20120104','20120105','20120109','20120110')
                 AND A.CUST_ID NOT IN ('8913402328', '8916869348') --去掉8913402328东北证券股份有限公司 8916869348永诚保险资产管理有限公司
                 AND A.BALANCE <> 0
                 AND A.ORG_NUM NOT LIKE '5%'
                 AND A.ORG_NUM NOT LIKE '6%'
               GROUP BY A.GL_ITEM_CODE, A.CUST_ID, A.JYDSTYDM, MATURE_DATE) A;
    COMMIT;

     --ADD BY DJH 20240510  同业金融部 009820
     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心，2003同业拆入外币折人民币本金余额  加本条线同业代付 差异在于 G2501取分行同业代付30天内，G2502取所有
     INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              A.ORG_NUM AS ORG_NUM,
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              CASE
                WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                 'G25_2_1.6.2.C.2016' ---1年以上
                WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                 'G25_2_1.6.2.B.2016' --6个月-1年
                ELSE
                 'G25_2_1.6.2.A.2016'
              END AS ITEM_NUM,
              SUM(ITEM_VAL) AS ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT 
                A.GL_ITEM_CODE,
                A.CUST_ID,
                SUM(ACCT_BAL_RMB) ITEM_VAL,
                MATUR_DATE,
                A.ORG_NUM
                 FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
                WHERE A.FLAG IN ('05', '06','10') --同业拆入(有其他机构)  同业存单发行
                  AND ACCT_BAL_RMB <> 0
                  AND A.ORG_NUM IN ('009820','009801')
                GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
        GROUP BY A.ORG_NUM,
                 CASE
                   WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                    'G25_2_1.6.2.C.2016' ---1年以上
                   WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                    'G25_2_1.6.2.B.2016' --6个月-1年
                   ELSE
                    'G25_2_1.6.2.A.2016'
                 END;
    COMMIT;

     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心本条线同业代付 差异在于 G2501取分行同业代付30天内，G2502取所有
    INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009801' AS ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                'G25_2_1.6.2.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                'G25_2_1.6.2.B.2016' --6个月-1年
               ELSE
                'G25_2_1.6.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT A.DATA_DATE,
                     ACTUAL_MATURITY_DT AS MATUR_DATE,
                     A.LOAN_ACCT_BAL * U.CCY_RATE AS ITEM_VAL
                FROM PM_RSDATA.SMTMODS_L_ACCT_LOAN A --贷款借据信息表
                LEFT JOIN PM_RSDATA.SMTMODS_L_AGRE_LOAN_CONTRACT B
                  ON A.ACCT_NUM = B.CONTRACT_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD
                 AND U.FORWARD_CCY = 'CNY'
                 AND U.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND B.CP_ID = 'MR0020002'
                 AND LOAN_ACCT_BAL <> 0) A
       GROUP BY CASE
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                   'G25_2_1.6.2.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                   'G25_2_1.6.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_1.6.2.A.2016'
                END;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取6.2非业务关系存款及其他无担保借款至A_REPT_ITEM_VAL结果表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取10.以上未包括的所有其它负债和权益至A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --10.以上未包括的所有其它负债和权益
    /*1.分行：资产类型为同业存放的定期中的利息按剩余期限划分报在009820机构；
    2.009820：同业拆入应付利息按期限-存单发行的应付利息调整按期限+3001（清算间往来）贷方放在6个月内；其中同业存单发行的应付利息调整按负数填报；
    009817机构从G01的60.负债及所有者权益总计同步取值，放>1年中；
    009816机构从G01资产负债项目统计表 49.负债合计同步取值；*/
    /*
    特殊： 同业存单发行的应付利息调整按负数填报   实际上不是报送在2231科目，而是在250202科目借方（利息调整），本金在贷方
     SELECT T.ORG_NUM, ITEM_CD, DEBIT_BAL, T.CREDIT_BAL
       FROM PM_RSDATA.SMTMODS_L_FINA_GL T
      WHERE DATA_DATE = I_DATADATE
        AND CURR_CD = 'BWB'
        AND ITEM_CD IN ('250202')*/

     --ADD BY DJH 20240510  同业金融部 009820
      INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         B_CURR_CD)
        SELECT I_DATADATE AS DATA_DATE, --数据日期
               '009820' AS ORG_NUM, --分行报在009820机构
               'CBRC' AS SYS_NAM, --模块简称
               'G2502' AS REP_NUM, --报表编号
               CASE
                 WHEN A.MATURE_DATE - I_DATADATE >= 360 THEN
                  'G25_2_1.10.C.2016' ---1年以上
                 WHEN A.MATURE_DATE - I_DATADATE >= 180 THEN
                  'G25_2_1.10.B.2016' --6个月-1年
                 ELSE
                  'G25_2_1.10.A.2016'
               END AS ITEM_NUM,
               SUM(ITEM_VAL) AS ITEM_VAL,
               '2' AS FLAG,
               'ALL' AS B_CURR_CD
          FROM (SELECT A.GL_ITEM_CODE,
                       A.CUST_ID,
                       A.JYDSTYDM,
                       SUM(A.ACCRUAL * CCY_RATE) ITEM_VAL,
                       MATURE_DATE
                  FROM PM_RSDATA.CBRC_V_PUB_FUND_MMFUND A
                  LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
                    ON TT.CCY_DATE = I_DATADATE
                   AND TT.BASIC_CCY = A.CURR_CD
                   AND TT.FORWARD_CCY = 'CNY'
                 WHERE A.DATA_DATE = I_DATADATE
                   AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201202' --同业存放定期
                   AND A.ACCRUAL <> 0
                   AND A.ORG_NUM NOT LIKE '5%'
                   AND A.ORG_NUM NOT LIKE '6%'
                 GROUP BY A.GL_ITEM_CODE, A.CUST_ID, A.JYDSTYDM, MATURE_DATE) A
         GROUP BY CASE
                    WHEN A.MATURE_DATE - I_DATADATE >= 360 THEN
                     'G25_2_1.10.C.2016' ---1年以上
                    WHEN A.MATURE_DATE - I_DATADATE >= 180 THEN
                     'G25_2_1.10.B.2016' --6个月-1年
                    ELSE
                     'G25_2_1.10.A.2016'
                  END;
    COMMIT;

     --ADD BY DJH 20240510  同业金融部 009820
     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心，2003拆入资金交易产生的应付利息 与核对223111科目贷方余额应付利息核对
     INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              ORG_NUM,
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              CASE
                WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                 'G25_2_1.10.C.2016' ---1年以上
                WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                 'G25_2_1.10.B.2016' --6个月-1年
                ELSE
                 'G25_2_1.10.A.2016'
              END AS ITEM_NUM,
              SUM(ITEM_VAL) AS ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT 
                A.GL_ITEM_CODE,
                A.CUST_ID,
                SUM(INTEREST_ACCURAL) ITEM_VAL,
                MATUR_DATE,
                A.ORG_NUM
                 FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
                WHERE A.FLAG IN ('05', '10') --同业拆入 转贷款 应付利息
                  AND INTEREST_ACCURAL <> 0
                  AND A.ORG_NUM IN ('009820', '009801')
                GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
        GROUP BY CASE
                   WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                    'G25_2_1.10.C.2016' ---1年以上
                   WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                    'G25_2_1.10.B.2016' --6个月-1年
                   ELSE
                    'G25_2_1.10.A.2016'
                 END,
                 ORG_NUM;
    COMMIT;

    --ADD BY DJH 20240510  同业金融部 009820
     INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              '009820' AS ORG_NUM,
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              CASE
                WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                 'G25_2_1.10.C.2016' ---1年以上
                WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                 'G25_2_1.10.B.2016' --6个月-1年
                ELSE
                 'G25_2_1.10.A.2016'
              END AS ITEM_NUM,
              SUM(ITEM_VAL) AS ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT 
                A.GL_ITEM_CODE,
                A.CUST_ID,
                -1 * SUM(CYCB) ITEM_VAL, --利息调整  CYCB资产方的叫持有成本，负债方的利息调整   台账表中【利息收益（即利息调整）】
                MATUR_DATE,
                A.ORG_NUM
                 FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
                WHERE A.FLAG = '06' --同业存单发行
                  AND CYCB <> 0
                  AND A.ORG_NUM = '009820'
                GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
        GROUP BY CASE
                   WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                    'G25_2_1.10.C.2016' ---1年以上
                   WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                    'G25_2_1.10.B.2016' --6个月-1年
                   ELSE
                    'G25_2_1.10.A.2016'
                 END;
    COMMIT;
    --ADD BY DJH 20240510  同业金融部 009820
     INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              '009820' AS ORG_NUM,
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              'G25_2_1.10.A.2016' AS ITEM_NUM, --3001（清算间往来）贷方放在6个月内
              SUM(ITEM_VAL) AS ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT 
                A.ITEM_CD, SUM(CREDIT_BAL) ITEM_VAL, A.ORG_NUM
                 FROM PM_RSDATA.SMTMODS_L_FINA_GL A
                WHERE DATA_DATE = I_DATADATE
                  AND CURR_CD = 'BWB'
                  AND ITEM_CD = '3001'
                  AND A.ORG_NUM = '009820'
                GROUP BY A.ITEM_CD, A.ORG_NUM) A;
     COMMIT;

      --ADD BY DJH 20240510  投资银行部 009817
     -- 009817机构从G01的60.负债及所有者权益总计同步取值，放>1年中；

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取10.以上未包括的所有其它负债和权益至A_REPT_ITEM_VAL结果表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取6.2其他至A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --6.2其他
    /*全行的存放同业活期持有仓位按剩余期限划分+全行的存放同业保证金的人民币按剩余期限划分填报在009820，都放到6个月内,因为存放同业活期和存放同业保证金无到期日
     取人民币部分，不要外币*/
       --ADD BY DJH 20240510  同业金融部 009820
     INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              '009820' AS ORG_NUM, --全行报在009820机构
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              'G25_2_2.6.2.A.2016'AS ITEM_NUM,
              SUM(ITEM_VAL) AS ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT 
                A.GL_ITEM_CODE,
                A.CUST_ID,
                SUM(ACCT_BAL_RMB) ITEM_VAL,
                MATUR_DATE,
                A.ORG_NUM
                 FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
                WHERE A.FLAG = '01' --1011(存放同业)、 1031(存出保证金)
                  AND ACCT_BAL_RMB <> 0
                  AND SUBSTR(A.GL_ITEM_CODE, 1, 6) <> '101102' --存放同业定期不要
                  AND A.ACCT_CUR = 'CNY' --取人民币部分，不要外币
                  AND A.ORG_NUM NOT LIKE '5%'
                  AND A.ORG_NUM NOT LIKE '6%'
                GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A;
    COMMIT;
    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心取,业务状况表（机构990000，外币折人民币），101101存放同业活期款项借方余额；103101存出活期保证金借方余额。
     INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              '009801' AS ORG_NUM, --全行报在009820机构
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              'G25_2_2.6.2.A.2016' AS ITEM_NUM,
              SUM(DEBIT_BAL) ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM PM_RSDATA.SMTMODS_L_FINA_GL A
        WHERE DATA_DATE = I_DATADATE
          AND CURR_CD = 'CFC' --外币折人民币
          AND ITEM_CD IN('101101','103101')
          AND A.ORG_NUM = '990000'
        GROUP BY A.ITEM_CD, A.ORG_NUM;
        COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取6.2其他至A_REPT_ITEM_VAL结果表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取7.3.2其他贷款至A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --7.3.2其他贷款
    /*存放同业定期持有仓位（暂时全行都没有）+1302同业拆出/同业借出定期持有仓位按剩余期限划分填报在009820*/

    --ADD BY DJH 20240510  同业金融部 009820
    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心，外币折人民币1302拆放同业余额
      INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         B_CURR_CD)
        SELECT I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM AS ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G2502' AS REP_NUM, --报表编号
               CASE
                 WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                  'G25_2_2.7.3.2.C.2016' ---1年以上
                 WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                  'G25_2_2.7.3.2.B.2016' --6个月-1年
                 ELSE
                  'G25_2_2.7.3.2.A.2016'
               END AS ITEM_NUM,
               SUM(ITEM_VAL) AS ITEM_VAL,
               '2' AS FLAG,
               'ALL' AS B_CURR_CD
          FROM (SELECT 
                 A.GL_ITEM_CODE,
                 A.CUST_ID,
                 SUM(ACCT_BAL_RMB) ITEM_VAL,
                 MATUR_DATE,
                 A.ORG_NUM
                  FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
                 WHERE A.FLAG = '02' --1302(拆出资金/借出)
                   AND ACCT_BAL_RMB <> 0
                   AND A.ORG_NUM IN('009820','009801') --(有其他机构)
                 GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
         GROUP BY A.ORG_NUM,
                  CASE
                    WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                     'G25_2_2.7.3.2.C.2016' ---1年以上
                    WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                     'G25_2_2.7.3.2.B.2016' --6个月-1年
                    ELSE
                     'G25_2_2.7.3.2.A.2016'
                  END;
    COMMIT;
  --ADD BY DJH 20240510  同业金融部 009820
   --存放同业定期持有仓位（暂时全行都没有） 没有数
    INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                'G25_2_2.7.3.2.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                'G25_2_2.7.3.2.B.2016' --6个月-1年
               ELSE
                'G25_2_2.7.3.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               A.GL_ITEM_CODE,
               A.CUST_ID,
               SUM(ACCT_BAL_RMB) ITEM_VAL,
               MATUR_DATE,
               A.ORG_NUM
                FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.FLAG = '01' --1011(存放同业)、 1031(存出保证金)
                 AND ACCT_BAL_RMB <> 0
                 AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '101102' --此处存放同业定期
                 AND A.ORG_NUM NOT LIKE '5%'
                 AND A.ORG_NUM NOT LIKE '6%'
               GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
       GROUP BY CASE
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                   'G25_2_2.7.3.2.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                   'G25_2_2.7.3.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.7.3.2.A.2016'
                END;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取7.3.2其他贷款至A_REPT_ITEM_VAL结果表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取9.2其他至A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --9.2其他     /*同业存单投资中登净价金额+基金持有仓位+基金的公允按剩余期限划分；其中随时申赎的基金放<6个月，定开的按剩余期限划分填报在009820*/
    --ADD BY DJH 20240510  同业金融部 009820

    INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN DC_DATE >= 360 THEN
                'G25_2_2.9.2.C.2016' ---1年以上
               WHEN DC_DATE >= 180 THEN
                'G25_2_2.9.2.B.2016' --6个月-1年
               ELSE
                'G25_2_2.9.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT A.ORG_NUM, DC_DATE, SUM(ACCT_BAL_RMB) ITEM_VAL
                FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE FLAG = '04'
                 AND ORG_NUM = '009820' --此处不限制机构，同业存单 包含金融市场部，同业金融部2个部分数据  -ADD BY DJH 20240510  同业金融部 009820  分开写也可同数据源
               GROUP BY A.ORG_NUM, DC_DATE) A
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN DC_DATE >= 360 THEN
                   'G25_2_2.9.2.C.2016' ---1年以上
                  WHEN DC_DATE >= 180 THEN
                   'G25_2_2.9.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.9.2.A.2016'
                END;
    COMMIT;

    INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                'G25_2_2.9.2.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                'G25_2_2.9.2.B.2016' --6个月-1年
               ELSE
                'G25_2_2.9.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               A.GL_ITEM_CODE,
               A.CUST_ID,
               SUM(ACCT_BAL_RMB) ITEM_VAL,
               MATUR_DATE,
               A.ORG_NUM
                FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.FLAG = '06' --基金
                 AND A.REDEMPTION_TYPE = '定期赎回'
               GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                   'G25_2_2.9.2.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                   'G25_2_2.9.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.9.2.A.2016'
                END;
    COMMIT;
    --ADD BY DJH 20240510  同业金融部 009820
    INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             'G25_2_2.9.2.A.2016' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               A.GL_ITEM_CODE,
               A.CUST_ID,
               SUM(ACCT_BAL_RMB) ITEM_VAL,
               MATUR_DATE,
               A.ORG_NUM
                FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.FLAG = '06' --基金
                 AND A.REDEMPTION_TYPE = '随时赎回'
               GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
       GROUP BY A.ORG_NUM;
    COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取9.2其他至A_REPT_ITEM_VAL结果表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取16.其他资产至A_REPT_ITEM_VAL(009820)结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --16.其他资产
    --ADD BY DJH 20240510  同业金融部 009820
    /*009820：
    1.分行：（全行人民币101102+1302科目借方-同业110102+1302科目借方）+（全行人民币11321101、02、03、04、05、06、07、08、09、10、11借方-同业11321101、02、03、04、05、06、07、08、09、10、11借方）-17326.39
    2.009820：基金利息放<6个月+存放同业活期利息放<6个月+委外AC账户的持有仓位（取AC账户的委外资产，属于坏账的，但是要刨除AC账户的国民信托）按剩余期限分其中三笔逾期业务放<6个月
   +其他的委外取账户类型是FVTPL账户的持有仓位+公允放<6个月
   -所有的减值：-1013存放同业减值准备贷方-1231坏账准备贷方-1307拆出资金坏账准备贷方-1502债权投资减值准备贷方放<6个月+未收回的140万+63.32万放到6个月以内（因为没有本金，所以在统一报表平台不体现）；
  +存放同业定期和拆放同业的定期按照剩余期限划分+同业存单投资利息按期限划分+不良的委外（即AC账户的）的利息按期限划分*/
    INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             'G25_2_2.15.A.2016' AS ITEM_NUM,
             SUM(DEBIT_BAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT -- T.ORG_NUM,
               ITEM_CD,
               T.ORG_NUM,
               SUM(CASE
                     WHEN T.ORG_NUM = '009820' THEN
                      -1 * DEBIT_BAL
                     ELSE
                      DEBIT_BAL
                   END) DEBIT_BAL
                FROM PM_RSDATA.SMTMODS_L_FINA_GL T
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
                 AND ITEM_CD IN ('101102', 1302)
                 AND T.ORG_NUM in ('990000', '009820')
               GROUP BY ITEM_CD, T.ORG_NUM) A;
    COMMIT;

    --ADD BY DJH 20240510  同业金融部 009804
    INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             'G25_2_2.15.A.2016' AS ITEM_NUM,
             SUM(DEBIT_BAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT -- T.ORG_NUM,
               ITEM_CD,
               T.ORG_NUM,
               SUM(CASE
                     WHEN T.ORG_NUM = '009820' THEN
                      -1 * DEBIT_BAL
                     ELSE
                      DEBIT_BAL
                   END) DEBIT_BAL
                FROM PM_RSDATA.SMTMODS_L_FINA_GL T
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'BWB'
                 AND ITEM_CD IN ('11321101',
                                 '11321102',
                                 '11321103',
                                 '11321104',
                                 '11321105',
                                 '11321106',
                                 '11321107',
                                 '11321108',
                                 '11321109',
                                 '11321110',
                                 '11321111')
                 AND T.ORG_NUM in ('990000', '009820')
               GROUP BY ITEM_CD, T.ORG_NUM) A;
    COMMIT;

    --  -17326.39
    --ADD BY DJH 20240510  同业金融部 009804
    INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             'G25_2_2.15.A.2016' AS ITEM_NUM,
             -1 * SUM(INT_FINAL_RESLT) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT T.PRIN_SUBJ_NO INT_SUBJ_NO, -- 利息科目号,
                     CUST_NO, -- 客户号,
                     T.BELONG_ORG, -- 入账机构,
                     FIVE_TIER_CLS, -- 五级分类,
                     PRIN_FINAL_RESLT, -- 本金ECL最终结果,
                     INT_FINAL_RESLT, -- 利息ECL最终结果,
                     COLLBL_INT_FINAL_RESLT, -- 应收利息ECL最终结果,
                     OFBS_FINAL_RESLT, -- 表外ECL最终结果,
                     FEE_FINAL_RESLT, -- 费用ECL最终结果,
                     FINAL_ECL, -- 应计利息ECL最终结果,
                     RECVBL_PNLTINT_FINAL_RESLT, -- 应收罚息ECL最终结果,
                     ACRU_PNLTINT_FINAL_RESLT, -- 应计罚息ECL最终结果,
                     RECVBL_CINT_FINAL_RESLT, --应收复利ECL最终结果,
                     DATA_DATE,
                     SN,
                     LP_ORG_NO,
                     EVENT_NO,
                     DATA_SRC
                FROM PM_RSDATA.SMTMODS_L_FINA_ASSET_DEVALUE T --资产减值准备
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.PRIN_SUBJ_NO = '15010201'
                 AND T.BELONG_ORG = '100000') A;
    COMMIT;

    --ADD BY DJH 20240510  同业金融部 009804
    INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             'G25_2_2.15.A.2016' AS ITEM_NUM,
             -1 * SUM(CREDIT_BAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT ITEM_CD, T.ORG_NUM, SUM(T.CREDIT_BAL) CREDIT_BAL
                FROM PM_RSDATA.SMTMODS_L_FINA_GL T
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'BWB'
                 AND ITEM_CD IN ('1013', '1231', '1307', '1502')
                 AND T.ORG_NUM = '009820'
               GROUP BY ITEM_CD, T.ORG_NUM) A;
    COMMIT;

    --ADD BY DJH 20240510  同业金融部 009804
    INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             'G25_2_2.15.A.2016' AS ITEM_NUM, -- 12310101 其他应收款坏账准备固定值放逾期 63.32万
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               A.ITEM_CD, SUM(CREDIT_BAL) ITEM_VAL, A.ORG_NUM
                FROM PM_RSDATA.SMTMODS_L_FINA_GL A
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'BWB'
                 AND ITEM_CD = '12310101'
                 AND A.ORG_NUM = '009820'
               GROUP BY A.ITEM_CD, A.ORG_NUM) A;
    COMMIT;
    --ADD BY DJH 20240510  同业金融部 009804
    INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             'G25_2_2.15.A.2016' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT --140万固定值放逾期
               1400000 ITEM_VAL --009820
                FROM system.dual) A;
    COMMIT;

    /* 2.009820：基金利息放<6个月+存放同业活期利息放<6个月+委外AC账户的持有仓位（取AC账户的委外资产，属于坏账的，但是要刨除AC账户的国民信托）按剩余期限分其中三笔逾期业务放<6个月
    【其中3笔AC账户的特殊处理，取持有仓位（中国华阳经贸集团有限公司，方正证券股份有限公司，东吴基金管理公司）放逾期】
       +其他的委外取账户类型是FVTPL账户的持有仓位+公允放<6个月
       -所有的减值：-1013存放同业减值准备贷方-1231坏账准备贷方-1307拆出资金坏账准备贷方-1502债权投资减值准备贷方放<6个月+未收回的140万+63.32万放到6个月以内（因为没有本金，所以在统一报表平台不体现）；
       +存放同业定期和拆放同业的定期按照剩余期限划分+同业存单投资利息按期限划分+不良的委外（即AC账户的）的利息按期限划分
       */

    /*
    1、取资管+基金+其他在L_ACCT_FUND_INVEST，FVTPL账户和AC账户用投资的会计分类筛选，1 交易类   FVTPL账户
    2 可供出售类
    3 持有至到期  AC账户
    2、非标：L_ACCT_FUND_INVEST
    */
    --ADD BY DJH 20240510  同业金融部 009804
    --存放同业活期应收利息
    INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             'G25_2_2.15.A.2016' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               SUM(INTEREST_ACCURAL) ITEM_VAL
                FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.FLAG = '01' --114(存放同业)、 117(存出保证金)
                 AND SUBSTR(A.GL_ITEM_CODE, 1, 6) <> '101102' --存放同业定期不要
                 AND A.ORG_NUM = '009820');
    COMMIT;

    --ADD BY DJH 20240510  同业金融部 009804
    INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.FLAG = '06' THEN
                'G25_2_2.15.A.2016'
               WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               A.GL_ITEM_CODE,
               A.CUST_ID,
               SUM(INTEREST_ACCURAL) ITEM_VAL,
               MATUR_DATE,
               A.ORG_NUM,
               A.FLAG
                FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.FLAG IN ('06', '02', '04') ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
                 AND A.ORG_NUM = '009820'
               GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM,A.FLAG) A
       GROUP BY CASE
                  WHEN A.FLAG = '06' THEN
                   'G25_2_2.15.A.2016'
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                   'G25_2_2.15.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                   'G25_2_2.15.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.15.A.2016'
                END;
    COMMIT;

    --ADD BY DJH 20240510  同业金融部 009804
    INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.MATUR_DATE - I_DATADATE >= 360 AND
                    ACCT_NUM NOT IN
                    ('N000310000012993', 'N000310000008023', 'N000310000012013') THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 AND
                    ACCT_NUM NOT IN
                    ('N000310000012993', 'N000310000008023', 'N000310000012013') THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               A.GL_ITEM_CODE,
               A.CUST_ID,
               SUM(DECODE(A.GL_ITEM_CODE,'15010201',ACCT_BAL_RMB+INTEREST_ACCURAL,A.INTEREST_ACCURAL)) ITEM_VAL,--SUM(A.INTEREST_ACCURAL) ITEM_VAL,
               MATUR_DATE,
               A.ORG_NUM,
               ACCT_NUM
                FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.FLAG IN ('07', '08') ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户  '15010201' )
                 AND a.ORG_NUM = '009820'
               GROUP BY A.GL_ITEM_CODE,
                        A.CUST_ID,
                        MATUR_DATE,
                        A.ORG_NUM,
                        ACCT_NUM) A
       GROUP BY CASE
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 AND
                       ACCT_NUM NOT IN ('N000310000012993',
                                        'N000310000008023',
                                        'N000310000012013') THEN
                   'G25_2_2.15.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 AND
                       ACCT_NUM NOT IN ('N000310000012993',
                                        'N000310000008023',
                                        'N000310000012013') THEN
                   'G25_2_2.15.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.15.A.2016'
                END;
    COMMIT;

    --特定目的载体11010303 本金+公允价值
    INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN (A.DC_DATE < 0 OR C.REDEMPTION_TYPE = '随时赎回') THEN
                'G25_2_2.15.A.2016'
               WHEN A.DC_DATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.DC_DATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END AS ITEM_NUM,
             SUM(A.FACE_VAL +A.MK_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_V_PUB_FUND_INVEST A
       INNER JOIN PM_RSDATA.SMTMODS_L_AGRE_OTHER_SUBJECT_INFO C -- 其他标的物信息表
          ON A.SUBJECT_CD = C.SUBJECT_CD
         AND C.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009820'
         AND A.GL_ITEM_CODE = '11010303'
       GROUP BY CASE
                  WHEN (A.DC_DATE < 0 OR C.REDEMPTION_TYPE = '随时赎回') THEN
                   'G25_2_2.15.A.2016'
                  WHEN A.DC_DATE >= 360 THEN
                   'G25_2_2.15.C.2016' ---1年以上
                  WHEN A.DC_DATE >= 180 THEN
                   'G25_2_2.15.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.15.A.2016'
                END;
    COMMIT;

/*    --15010201  本金借方-贷方
    INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             'G25_2_2.15.C.2016' AS ITEM_NUM,
             SUM(A.DEBIT_BAL) - SUM(CREDIT_BAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.SMTMODS_L_FINA_GL A
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'BWB'
         AND ITEM_CD = '15010201'
         AND A.ORG_NUM = '009820'
       GROUP BY A.ITEM_CD, A.ORG_NUM;*/

    COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取16.其他资产至A_REPT_ITEM_VAL(009820)结果表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

  --由于与投行业务沟通后发现利息的期限无法准确划分 故 该报表的第16项不在系统取数，业务手填
    /*  --ADD BY DJH 20240510  投资银行部 009817
      --存量非标的本金+其他应收款+应收利息-存量非标本金的减值-其他应收款的减值-应收利息的减值，按剩余期限划分；逾期的放<6个月
      INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         B_CURR_CD)
        SELECT I_DATADATE AS DATA_DATE, --数据日期
               ORG_NUM AS ORG_NUM, --全行报在009820机构
               'CBRC' AS SYS_NAM, --模块简称
               'G2502' AS REP_NUM, --报表编号
               CASE
                 WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                  'G25_2_2.15.C.2016' ---1年以上
                 WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                  'G25_2_2.15.B.2016' --6个月-1年
                 ELSE
                  'G25_2_2.15.A.2016'
               END AS ITEM_NUM,
               SUM(ACCT_BAL_RMB+INTEREST_ACCURAL+QTYSK-PRIN_FINAL_RESLT-COLLBL_INT_FINAL_RESLT) AS ITEM_VAL,
               '2' AS FLAG,
               'ALL' AS B_CURR_CD
          FROM (SELECT A.ORG_NUM,
                       A.MATUR_DATE,
                       SUM(NVL(A.ACCT_BAL_RMB,0)) AS ACCT_BAL_RMB, --本金
                       SUM(NVL(A.INTEREST_ACCURAL,0)) AS INTEREST_ACCURAL, --其他应收款
                       SUM(NVL(A.QTYSK,0)) AS QTYSK, --其他应收款
                       SUM(NVL(PRIN_FINAL_RESLT,0)) AS PRIN_FINAL_RESLT, --本金的减值
                       SUM(NVL(COLLBL_INT_FINAL_RESLT,0)) AS COLLBL_INT_FINAL_RESLT, --应收利息的减值
                       0 AS QT --其他应收款的减值
                  FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
                  LEFT JOIN PM_RSDATA.CBRC_TMP_ASSET_DEVALUE_PREPARE_G B
                    ON A.ACCT_NUM = B.ACCT_NUM
                 WHERE A.DATA_DATE = I_DATADATE
                   AND FLAG = '09'
                 GROUP BY A.ORG_NUM, A.MATUR_DATE) A
         GROUP BY ORG_NUM,
                  CASE
                    WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                     'G25_2_2.15.C.2016' ---1年以上
                    WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                     'G25_2_2.15.B.2016' --6个月-1年
                    ELSE
                     'G25_2_2.15.A.2016'
                  END;
      COMMIT;
       --ADD BY DJH 20240510  投资银行部 009817
        --其他应收款的减值取科目12310101其他应收款坏账准备贷方，由于i9和投资银行系统中没有(其他应收款减值余额(科目：12310101))，期限要怎么放，是否6个月内
        INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
          (DATA_DATE, --数据日期
           ORG_NUM, --机构号
           SYS_NAM, --模块简称
           REP_NUM, --报表编号
           ITEM_NUM, --指标号
           ITEM_VAL, --指标值
           FLAG, --标志位
           B_CURR_CD)
          SELECT I_DATADATE AS DATA_DATE, --数据日期
                 '009817' AS ORG_NUM, --全行报在009820机构
                 'CBRC' AS SYS_NAM, --模块简称
                 'G2502' AS REP_NUM, --报表编号
                 'G25_2_2.15.A.2016' AS ITEM_NUM,
                 -1 * SUM(NVL(T.CREDIT_BAL, 0) * U.CCY_RATE) AS ITEM_VAL,
                 '2' AS FLAG,
                 'ALL' AS B_CURR_CD
            FROM PM_RSDATA.SMTMODS_L_FINA_GL T
            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
              ON U.CCY_DATE = I_DATADATE
             AND U.BASIC_CCY = T.CURR_CD --基准币种
             AND U.FORWARD_CCY = 'CNY' --折算币种
             AND U.DATA_DATE = I_DATADATE
           WHERE T.DATA_DATE = I_DATADATE
             AND T.ORG_NUM = '009817'
             AND T.ITEM_CD = '12310101';
        COMMIT;*/



    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取16.其他资产至A_REPT_ITEM_VAL(009804)结果表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --ADD BY DJH 20240510  同业金融部 009804
      /*16.其他资产   除了债券，其他的是不是需要写逾期；逻辑放在6个月内？？？？
      009804：
      <6个月+逾期
      1.债券:逾期债券的本金+逾期债券的应收+逾期的债券的本金减值+逾期债券的利息减值+正常债券的本金的减值+正常债券的应收利息的减值+正常债券应收
      2.同业存单的应收+同业存单本金和利息的减值
      3.转贴现的公允价值+转贴现的利息调整+转贴现的减值--全行，报在009804，刨除磐石
      4.买入返售的应收（票据+债券)+买入返售的减值
      6-12个月
      1.债券:正常债券的本金的减值+正常债券的应收利息的减值+正常债券应收
      2.同业存单的应收+同业存单本金和利息的减值
      3.转贴现的公允价值+转贴现的利息调整+转贴现的减值--全行，报在009804，刨除磐石
      4.买入返售的应收（票据+债券)+买入返售的减值
      >12个月
      1.债券:正常债券的本金的减值+正常债券的应收利息的减值+正常债券应收
      2.同业存单的应收+同业存单本金和利息的减值
      3.转贴现的公允价值+转贴现的利息调整+转贴现的减值--全行，报在009804，刨除磐石
      4.买入返售的应收（票据+债券)+买入返售的减值 */

      --1.债券:逾期债券的本金+逾期债券的应收+逾期的债券的本金减值+逾期债券的利息减值+正常债券的本金的减值+正常债券的应收利息的减值+正常债券应收
        --本金109159878133.68
 INSERT INTO PM_RSDATA.CBRC_TMP_FINANCIAL_MARKET
   (DATA_DATE,
    BALANCE,
    MK_VAL,
    INT_ADJEST_AMT,
    ACCRUAL,
    DISCOUNT_INTEREST,
    BJ_JZ,
    YSLX_JZ,
    YJLX_JZ,
    BW_JZ,
    ORG_NUM,
    ACCT_NUM,
    SUBJECT_CD,
    GL_ITEM_CODE,
    BOOK_TYPE,
    BIZ_NO,
    FIVE_TIER_CLS,
    DC_DATE,
    MATURITY_DT,
    ACCOUNTANT_TYPE,
    STOCK_PRO_TYPE,
    ISSU_ORG,
    FLAG)
   SELECT 
    I_DATADATE AS DATA_DATE, --数据日期
    NVL(A.PRINCIPAL_BALANCE, 0) * U.CCY_RATE AS PRINCIPAL_BALANCE, --剩余本金 本金
    0 AS MK_VAL, --公允价值
    0 AS INT_ADJEST_AMT, --利息调整
    NVL(A.ACCRUAL, 0) AS ACCRUAL, --应收
    0 AS DISCOUNT_INTEREST,
    CASE
      WHEN A.ACCOUNTANT_TYPE = '1' THEN
       0
      ELSE
       NVL(C.PRIN_FINAL_RESLT, 0) --交易性金融资产不算减值(不计入总账) 会计分类：1、交易类 2、可供出售类 3、持有至到期 4、贷款及应收款
    END AS BJ_JZ, --本金ECL最终结果(本金的减值)
    CASE
      WHEN A.ACCOUNTANT_TYPE = '1' THEN
       0
      ELSE
       NVL(C.COLLBL_INT_FINAL_RESLT, 0) --交易性金融资产不算减值(不计入总账) 会计分类：1、交易类 2、可供出售类 3、持有至到期 4、贷款及应收款
    END AS YSLX_JZ, --应收利息ECL最终结果
    CASE
      WHEN A.ACCOUNTANT_TYPE = '1' THEN
       0
      ELSE
       NVL(C.FINAL_ECL, 0) --交易性金融资产不算减值(不计入总账) 会计分类：1、交易类 2、可供出售类 3、持有至到期 4、贷款及应收款
    END AS YJLX_JZ, --应计利息ECL最终结果
    CASE
      WHEN A.ACCOUNTANT_TYPE = '1' THEN
       0
      ELSE
       NVL(C.OFBS_FINAL_RESLT, 0) --交易性金融资产不算减值(不计入总账) 会计分类：1、交易类 2、可供出售类 3、持有至到期 4、贷款及应收款
    END AS BW_JZ, --表外ECL最终结果
    A.ORG_NUM AS ORG_NUM, --机构号
    A.ACCT_NUM AS ACCT_NUM,
    A.SUBJECT_CD AS SUBJECT_CD,
    A.GL_ITEM_CODE AS GL_ITEM_CODE, --科目
    A.BOOK_TYPE AS BOOK_TYPE, --账户类型
    C.BIZ_NO,
    C.FIVE_TIER_CLS AS FIVE_TIER_CLS, --减值五级分类
    A.DC_DATE AS DC_DATE, --是否逾期通过待偿期查看！！！！
    null AS MATURITY_DT,
    A.ACCOUNTANT_TYPE AS ACCOUNTANT_TYPE, --会计分类 1:交易类 2:可供出售类 3:持有至到期 4: 贷款及应收款
    B.STOCK_PRO_TYPE AS STOCK_PRO_TYPE, --产品分类
    B.ISSU_ORG AS ISSU_ORG, --发行方式
    '01' AS FLAG --债券
     FROM PM_RSDATA.CBRC_V_PUB_FUND_INVEST A --投资业务信息表 A
     LEFT JOIN PM_RSDATA.SMTMODS_L_AGRE_BOND_INFO B --债券信息表
       ON A.SUBJECT_CD = B.STOCK_CD
      AND B.DATA_DATE = I_DATADATE
     LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
       ON U.CCY_DATE = I_DATADATE
      AND U.BASIC_CCY = A.CURR_CD --基准币种
      AND U.FORWARD_CCY = 'CNY' --折算币种
      AND U.DATA_DATE = I_DATADATE
     LEFT JOIN PM_RSDATA.CBRC_TMP_ASSET_DEVALUE_PREPARE_G C --资产减值准备
       ON C.ACCT_NUM = A.ACCT_NUM
      AND A.ACCT_NO = C.ACCT_ID --[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
      AND A.GL_ITEM_CODE = C.PRIN_SUBJ_NO
      AND C.DATA_DATE = I_DATADATE
    WHERE A.DATA_DATE = I_DATADATE
      AND NVL(A.PRINCIPAL_BALANCE, 0) <> 0
      AND A.INVEST_TYP = '00' --债券
   -- and C.ACCT_NUM='012383837'
   UNION ALL
   --2.同业存单的应收+同业存单本金和利息的减值
   SELECT 
    I_DATADATE AS DATA_DATE, --数据日期
    NVL(A.PRINCIPAL_BALANCE, 0) * U.CCY_RATE AS PRINCIPAL_BALANCE, --剩余本金 本金
    0 AS MK_VAL, --公允价值
    0 AS INT_ADJEST_AMT, --利息调整
    NVL(A.INTEREST_RECEIVABLE, 0) * U.CCY_RATE AS INTEREST_RECEIVABLE, --应收
    -- NVL(A.INTEREST_ACCURED, 0) * U.CCY_RATE AS INTEREST_ACCURED, --应计
    0 AS DISCOUNT_INTEREST,
    CASE
      WHEN A.ACCOUNTANT_TYPE = '1' THEN
       0
      ELSE
       NVL(C.PRIN_FINAL_RESLT, 0) --交易性金融资产不算减值(不计入总账) 会计分类：1、交易类 2、可供出售类 3、持有至到期 4、贷款及应收款
    END AS BJ_JZ, --本金ECL最终结果(本金的减值)
    CASE
      WHEN A.ACCOUNTANT_TYPE = '1' THEN
       0
      ELSE
       NVL(C.COLLBL_INT_FINAL_RESLT, 0) --交易性金融资产不算减值(不计入总账) 会计分类：1、交易类 2、可供出售类 3、持有至到期 4、贷款及应收款
    END AS YSLX_JZ, --应收利息ECL最终结果
    CASE
      WHEN A.ACCOUNTANT_TYPE = '1' THEN
       0
      ELSE
       NVL(C.FINAL_ECL, 0) --交易性金融资产不算减值(不计入总账) 会计分类：1、交易类 2、可供出售类 3、持有至到期 4、贷款及应收款
    END AS YJLX_JZ, --应计利息ECL最终结果
    CASE
      WHEN A.ACCOUNTANT_TYPE = '1' THEN
       0
      ELSE
       NVL(C.OFBS_FINAL_RESLT, 0) --交易性金融资产不算减值(不计入总账) 会计分类：1、交易类 2、可供出售类 3、持有至到期 4、贷款及应收款
    END AS BW_JZ, --表外ECL最终结果
    A.ORG_NUM AS ORG_NUM,
    A.ACCT_NUM AS ACCT_NUM,
    A.CDS_NO AS CDS_NO,
    A.GL_ITEM_CODE AS GL_ITEM_CODE,
    A.BOOK_TYPE AS BOOK_TYPE, --台账中只有2银行账户有减值，1交易账户没有减值 是否需要手工改为0 ？？？？ 但是系统中交易账户有减值
    C.BIZ_NO,
    C.FIVE_TIER_CLS AS FIVE_TIER_CLS, --减值五级分类
    A.DC_DATE AS DC_DATE,
    A.MATURITY_DT AS MATURITY_DT,
    null,
    null,
    null,
    '02' AS FLAG --同业存单
     FROM PM_RSDATA.SMTMODS_V_PUB_FUND_CDS_BAL A --存单投资与发行信息表
     LEFT JOIN PM_RSDATA.CBRC_TMP_ASSET_DEVALUE_PREPARE_G C --资产减值准备
       --ON SUBSTR(A.ACCT_NUM, 1, INSTR(A.ACCT_NUM, '_') - 1) = C.BIZ_NO
      --[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
       ON REPLACE(A.ACCT_NUM,'_','') = C.ACCT_NUM||C.ACCT_ID
      AND A.GL_ITEM_CODE = C.PRIN_SUBJ_NO
      AND A.ORG_NUM = C.RECORD_ORG --一个存单 对应多个机构
     LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
       ON U.CCY_DATE = I_DATADATE
      AND U.BASIC_CCY = A.CURR_CD --基准币种
      AND U.FORWARD_CCY = 'CNY' --折算币种
      AND U.DATA_DATE = I_DATADATE
    WHERE A.DATA_DATE = I_DATADATE
      AND A.STOCK_PRO_TYPE = 'A' --A同业存单 B大额存单
      AND A.PRODUCT_PROP = 'A' --A投资 B发行
      AND A.ORG_NUM = '009804'
      AND PRINCIPAL_BALANCE <> 0
   --AND A.BOOK_TYPE = '1';
   -- and C.ACCT_NUM='112406121'
   UNION ALL
   --3.转贴现的公允价值+转贴现的利息调整+转贴现的减值--全行，报在009804，刨除磐石
   SELECT I_DATADATE AS DATA_DATE, --数据日期
          NVL(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE AS PRINCIPAL_BALANCE, --剩余本金 本金
          NVL(MK_VAL, 0) * U.CCY_RATE AS MK_VAL, --公允价值
          NVL(A.INT_ADJEST_AMT, 0) * U.CCY_RATE AS INT_ADJEST_AMT, --利息调整
          NVL(A.OD_INT, 0) * U.CCY_RATE AS OD_INT, --应收
          -- NVL(A.ACCU_INT_AMT, 0) * U.CCY_RATE AS ACCU_INT_AMT, --应计
          NVL(A.DISCOUNT_INTEREST, 0) * U.CCY_RATE AS DISCOUNT_INTEREST, --贴现利息 (台账中应付利息)  是否需要填报 ？？？？口径中没有
          NVL(C.PRIN_FINAL_RESLT, 0) AS BJ_JZ, --本金ECL最终结果(本金的减值)
          NVL(C.COLLBL_INT_FINAL_RESLT, 0) AS YSLX_JZ, --应收利息ECL最终结果
          NVL(C.FINAL_ECL, 0) AS YJLX_JZ, --应计利息ECL最终结果
          NVL(C.OFBS_FINAL_RESLT, 0) AS BW_JZ, --表外ECL最终结果
          A.ORG_NUM AS ORG_NUM,
          A.ACCT_NUM AS ACCT_NUM,
          A.DRAFT_NBR AS CDS_NO,
          A.ITEM_CD AS GL_ITEM_CODE,
          A.BOOK_TYPE AS BOOK_TYPE,
          C.BIZ_NO,
          C.FIVE_TIER_CLS AS FIVE_TIER_CLS, --减值五级分类
          A.MATURITY_DT - I_DATADATE AS MATURITY_DT,
          A.MATURITY_DT,
          null,
          null,
          null,
          '03' AS FLAG --转贴现
     FROM PM_RSDATA.SMTMODS_L_ACCT_LOAN A -- 贷款借据信息表
     LEFT JOIN PM_RSDATA.SMTMODS_L_AGRE_BILL_INFO B -- 商业汇票票面信息表
       ON A.DRAFT_NBR = B.BILL_NUM
      AND B.DATA_DATE = I_DATADATE
     LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
       ON U.CCY_DATE = I_DATADATE
      AND U.BASIC_CCY = A.CURR_CD
      AND U.FORWARD_CCY = 'CNY'
     LEFT JOIN PM_RSDATA.CBRC_TMP_ASSET_DEVALUE_PREPARE_G C --资产减值准备
       ON C.ACCT_NUM = A.LOAN_NUM
      AND A.ORG_NUM = C.RECORD_ORG
      AND C.DATA_DATE = I_DATADATE
    WHERE A.DATA_DATE = I_DATADATE
      AND (ITEM_CD LIKE '130102%' --以摊余成本计量的转贴现
          OR ITEM_CD LIKE '130105%')
      AND A.LOAN_ACCT_BAL <> 0
      AND A.ORG_NUM NOT LIKE '5%'
      AND A.ORG_NUM NOT LIKE '6%'
   UNION ALL
   --  AND A.ORG_NUM = '009804'
   --  AND B.BILL_TYPE = '1' --票据类型 --1 银行承兑汇票   2 商业承兑汇票 --G1405只是取银行承兑汇票，G1403取商业承兑汇票
   --4.买入返售的应收（票据+债券)+买入返售的减值
   SELECT I_DATADATE AS DATA_DATE, --数据日期
          NVL(A.BALANCE, 0) * U.CCY_RATE AS BALANCE, --剩余本金 本金
          0 AS MK_VAL, --公允价值
          0 AS INT_ADJEST_AMT, --利息调整
          NVL(A.ACCRUAL, 0) * U.CCY_RATE AS ACCRUAL, --应收
          --   NVL(A.INTEREST_ACCURED, 0) * U.CCY_RATE AS INTEREST_ACCURED, --应计
          0 AS DISCOUNT_INTEREST,
          NVL(C.PRIN_FINAL_RESLT, 0)  AS BJ_JZ, --本金ECL最终结果(本金的减值)
          NVL(C.COLLBL_INT_FINAL_RESLT, 0) AS YSLX_JZ, --应收利息ECL最终结果
          NVL(C.FINAL_ECL, 0) AS YJLX_JZ, --应计利息ECL最终结果
          NVL(C.OFBS_FINAL_RESLT, 0) AS BW_JZ, --表外ECL最终结果
          A.ORG_NUM AS ORG_NUM,
          A.ACCT_NUM AS ACCT_NUM,
          A.REF_NUM AS BILL_NUM,
          A.GL_ITEM_CODE AS GL_ITEM_CODE,
          A.BOOK_TYPE AS BOOK_TYPE,
          C.BIZ_NO,
          C.FIVE_TIER_CLS AS FIVE_TIER_CLS, --减值五级分类
          A.END_DT - I_DATADATE AS MATURITY_DT,
          A.END_DT,
          null,
          null,
          null,
          '04' AS FLAG --买入返售（债券)
     FROM PM_RSDATA.CBRC_V_PUB_FUND_REPURCHASE A
     LEFT JOIN PM_RSDATA.CBRC_TMP_ASSET_DEVALUE_PREPARE_G C --资产减值准备
       ON A.REF_NUM = C.ACCT_NUM
      AND PRIN_SUBJ_NO LIKE '1111%'
      AND A.ORG_NUM = C.RECORD_ORG
     LEFT JOIN PM_RSDATA.SMTMODS_L_AGRE_BILL_INFO B -- 商业汇票票面信息表
       ON A.SUBJECT_CD = B.BILL_NUM
      AND B.DATA_DATE = I_DATADATE
     LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
       ON U.CCY_DATE = I_DATADATE
      AND U.BASIC_CCY = A.CURR_CD --基准币种
      AND U.FORWARD_CCY = 'CNY' --折算币种
    WHERE A.DATA_DATE = I_DATADATE
         --  AND A.ORG_NUM = '009804'
      AND A.GL_ITEM_CODE = '111101' --质押式买入返售债券,票据，（债券关联不上减值，是没有减值吗？？？）
      AND A.BALANCE > 0
   union all
   SELECT I_DATADATE AS DATA_DATE, --数据日期
          NVL(A.BALANCE, 0) * U.CCY_RATE AS BALANCE, --剩余本金 本金
          0 AS MK_VAL, --公允价值
          0 AS INT_ADJEST_AMT, --利息调整
          NVL(A.ACCRUAL, 0) * U.CCY_RATE AS ACCRUAL, --应收
          --   NVL(A.INTEREST_ACCURED, 0) * U.CCY_RATE AS INTEREST_ACCURED, --应计
          0 AS DISCOUNT_INTEREST,
          NVL(C.PRIN_FINAL_RESLT, 0)  AS BJ_JZ, --本金ECL最终结果(本金的减值)
          NVL(C.COLLBL_INT_FINAL_RESLT, 0) AS YSLX_JZ, --应收利息ECL最终结果
          NVL(C.FINAL_ECL, 0) AS YJLX_JZ, --应计利息ECL最终结果
          NVL(C.OFBS_FINAL_RESLT, 0) AS BW_JZ, --表外ECL最终结果
          A.ORG_NUM AS ORG_NUM,
          A.ACCT_NUM AS ACCT_NUM,
          B.BILL_NUM AS BILL_NUM,
          A.GL_ITEM_CODE AS GL_ITEM_CODE,
          A.BOOK_TYPE AS BOOK_TYPE,
          C.BIZ_NO,
          C.FIVE_TIER_CLS AS FIVE_TIER_CLS, --减值五级分类
          B.MATU_DATE - I_DATADATE AS MATU_DATE,
          B.MATU_DATE,
          null,
          null,
          null,
          '05' AS FLAG --买入返售（票据)
     FROM PM_RSDATA.CBRC_V_PUB_FUND_REPURCHASE A
     LEFT JOIN PM_RSDATA.CBRC_TMP_ASSET_DEVALUE_PREPARE_G C --资产减值准备
       ON A.REF_NUM = C.ACCT_NUM
      AND PRIN_SUBJ_NO LIKE '1111%'
      AND A.ORG_NUM = C.RECORD_ORG
     LEFT JOIN PM_RSDATA.SMTMODS_L_AGRE_BILL_INFO B -- 商业汇票票面信息表
       ON A.SUBJECT_CD = B.BILL_NUM
      AND B.DATA_DATE = I_DATADATE
     LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
       ON U.CCY_DATE = I_DATADATE
      AND U.BASIC_CCY = A.CURR_CD --基准币种
      AND U.FORWARD_CCY = 'CNY' --折算币种
    WHERE A.DATA_DATE = I_DATADATE
         --  AND A.ORG_NUM = '009804'
      AND A.GL_ITEM_CODE = '111102' --质押式买入返售债券,票据，（债券关联不上减值，是没有减值吗？？？）
      AND A.BALANCE > 0;
 COMMIT;

--债券逾期
 INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
   (DATA_DATE, --数据日期
    ORG_NUM, --机构号
    SYS_NAM, --模块简称
    REP_NUM, --报表编号
    ITEM_NUM, --指标号
    ITEM_VAL, --指标值
    FLAG, --标志位
    B_CURR_CD)
   SELECT I_DATADATE AS DATA_DATE, --数据日期
          A.ORG_NUM AS ORG_NUM,
          'CBRC' AS SYS_NAM, --模块简称
          'G2502' AS REP_NUM, --报表编号
          'G25_2_2.15.A.2016' AS ITEM_NUM,
          SUM(BALANCE + ACCRUAL - BJ_JZ - YSLX_JZ) AS ITEM_VAL,
          '2' AS FLAG,
          'ALL' AS B_CURR_CD
     FROM (SELECT 
            A.GL_ITEM_CODE,
            DC_DATE,
            A.ORG_NUM,
            ACCT_NUM,
            NVL(BALANCE, 0) BALANCE,
            NVL(MK_VAL, 0) MK_VAL,
            NVL(INT_ADJEST_AMT, 0) INT_ADJEST_AMT,
            NVL(ACCRUAL, 0) ACCRUAL,
            NVL(DISCOUNT_INTEREST, 0) DISCOUNT_INTEREST,
            NVL(BJ_JZ, 0) BJ_JZ,
            NVL(YSLX_JZ, 0) YSLX_JZ,
            NVL(YJLX_JZ, 0) YJLX_JZ,
            NVL(BW_JZ, 0) BW_JZ
             FROM PM_RSDATA.CBRC_TMP_FINANCIAL_MARKET A
            WHERE A.DATA_DATE = I_DATADATE
              AND A.FLAG = '01' --债券
              AND (A.DC_DATE <= 0 OR  ACCT_NUM='X0003120B2700001')) A -- ADD BY DJH 20240510  金融市场部 X0003120B2700001  18华阳经贸CP001  与G21判定规则相同，这笔默认逾期
    GROUP BY A.ORG_NUM;
 COMMIT;


 --债券正常
 INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
   (DATA_DATE, --数据日期
    ORG_NUM, --机构号
    SYS_NAM, --模块简称
    REP_NUM, --报表编号
    ITEM_NUM, --指标号
    ITEM_VAL, --指标值
    FLAG, --标志位
    B_CURR_CD)
   SELECT I_DATADATE AS DATA_DATE, --数据日期
          A.ORG_NUM AS ORG_NUM,
          'CBRC' AS SYS_NAM, --模块简称
          'G2502' AS REP_NUM, --报表编号
          CASE
            WHEN DC_DATE >= 360 THEN
             'G25_2_2.15.C.2016' ---1年以上
            WHEN DC_DATE >= 180 THEN
             'G25_2_2.15.B.2016' --6个月-1年
            ELSE
             'G25_2_2.15.A.2016'
          END AS ITEM_NUM,
          SUM(CASE
                WHEN A.ACCT_NUM = '1523004' THEN ACCRUAL - BJ_JZ - YSLX_JZ - YJLX_JZ
                ELSE ACCRUAL - BJ_JZ - YSLX_JZ - YJLX_JZ
               END) AS ITEM_VAL,
          '2' AS FLAG,
          'ALL' AS B_CURR_CD
     FROM (SELECT 
            A.GL_ITEM_CODE,
            DC_DATE,
            A.ORG_NUM,
            ACCT_NUM,
            NVL(BALANCE, 0) BALANCE,
            NVL(MK_VAL, 0) MK_VAL,
            NVL(INT_ADJEST_AMT, 0) INT_ADJEST_AMT,
            NVL(ACCRUAL, 0) ACCRUAL,
            NVL(DISCOUNT_INTEREST, 0) DISCOUNT_INTEREST,
            NVL(BJ_JZ, 0) BJ_JZ,
            NVL(YSLX_JZ, 0) YSLX_JZ,
            NVL(YJLX_JZ, 0) YJLX_JZ,
            NVL(BW_JZ, 0) BW_JZ
             FROM PM_RSDATA.CBRC_TMP_FINANCIAL_MARKET A
            WHERE A.DATA_DATE = I_DATADATE
              AND A.FLAG = '01' --债券
              AND A.DC_DATE > 0
              AND ACCT_NUM <>'X0003120B2700001') A  -- ADD BY DJH 20240510  金融市场部 X0003120B2700001  18华阳经贸CP001  与G21判定规则相同，这笔默认逾期,已放在上面，此处去掉
    GROUP BY A.ORG_NUM,
             CASE
               WHEN DC_DATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN DC_DATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END;
 COMMIT;
--同业存单  买入返售的应收（票据+债券)
 INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
   (DATA_DATE, --数据日期
    ORG_NUM, --机构号
    SYS_NAM, --模块简称
    REP_NUM, --报表编号
    ITEM_NUM, --指标号
    ITEM_VAL, --指标值
    FLAG, --标志位
    B_CURR_CD)
   SELECT I_DATADATE AS DATA_DATE, --数据日期
          ORG_NUM AS ORG_NUM,
          'CBRC' AS SYS_NAM, --模块简称
          'G2502' AS REP_NUM, --报表编号
          CASE
             WHEN A.DC_DATE >= 360 THEN
              'G25_2_2.15.C.2016' ---1年以上
             WHEN A.DC_DATE >= 180 THEN
              'G25_2_2.15.B.2016' --6个月-1年
             ELSE
              'G25_2_2.15.A.2016'
          END AS ITEM_NUM,
          SUM(ACCRUAL - BJ_JZ - YSLX_JZ) AS ITEM_VAL,
          '2' AS FLAG,
          'ALL' AS B_CURR_CD
     FROM (SELECT 
            A.GL_ITEM_CODE,
            A.DC_DATE,
            A.ORG_NUM,
            ACCT_NUM,
            NVL(BALANCE, 0) BALANCE,
            NVL(MK_VAL, 0) MK_VAL,
            NVL(INT_ADJEST_AMT, 0) INT_ADJEST_AMT,
            NVL(ACCRUAL, 0) ACCRUAL,
            NVL(DISCOUNT_INTEREST, 0) DISCOUNT_INTEREST,
            NVL(BJ_JZ, 0) BJ_JZ,
            NVL(YSLX_JZ, 0) YSLX_JZ,
            NVL(YJLX_JZ, 0) YJLX_JZ,
            NVL(BW_JZ, 0) BW_JZ
             FROM PM_RSDATA.CBRC_TMP_FINANCIAL_MARKET A
            WHERE A.DATA_DATE = I_DATADATE
              AND A.FLAG IN ('02', '04', '05')) A --同业存单  买入返售的应收（票据+债券)
    GROUP BY ORG_NUM,
             CASE
               WHEN A.DC_DATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.DC_DATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END;
 COMMIT;
 --转贴现的公允价值+转贴现的利息调整+转贴现的减值--全行，报在009804，刨除磐石
 INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
   (DATA_DATE, --数据日期
    ORG_NUM, --机构号
    SYS_NAM, --模块简称
    REP_NUM, --报表编号
    ITEM_NUM, --指标号
    ITEM_VAL, --指标值
    FLAG, --标志位
    B_CURR_CD)
   SELECT I_DATADATE AS DATA_DATE, --数据日期
          A.ORG_NUM AS ORG_NUM,
          'CBRC' AS SYS_NAM, --模块简称
          'G2502' AS REP_NUM, --报表编号
          CASE
            WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
             'G25_2_2.15.C.2016' ---1年以上
            WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
             'G25_2_2.15.B.2016' --6个月-1年
            ELSE
             'G25_2_2.15.A.2016'
          END AS ITEM_NUM,
          SUM(MK_VAL-INT_ADJEST_AMT-BJ_JZ) AS ITEM_VAL, -- 公允价值（有正有负） - 利息调整（贷方）  - 本金减值
          '2' AS FLAG,
          'ALL' AS B_CURR_CD
     FROM (SELECT 
            A.GL_ITEM_CODE,
            MATURITY_DT,
            A.ORG_NUM,
            ACCT_NUM,
            NVL(BALANCE, 0) BALANCE,
            NVL(MK_VAL, 0) MK_VAL,
            NVL(INT_ADJEST_AMT, 0) INT_ADJEST_AMT,
            NVL(ACCRUAL, 0) ACCRUAL,
            NVL(DISCOUNT_INTEREST, 0) DISCOUNT_INTEREST,
            NVL(BJ_JZ, 0) BJ_JZ,
            NVL(YSLX_JZ, 0) YSLX_JZ,
            NVL(YJLX_JZ, 0) YJLX_JZ,
            NVL(BW_JZ, 0) BW_JZ
             FROM PM_RSDATA.CBRC_TMP_FINANCIAL_MARKET A
            WHERE A.DATA_DATE = I_DATADATE
              AND A.FLAG = '03') A --转贴现
    GROUP BY A.ORG_NUM,
             CASE
               WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END;
 COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取16.其他资产至A_REPT_ITEM_VAL (009804)结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取16.其他资产至A_REPT_ITEM_VAL(009816)结果表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
     /*009816：
     16.其他资产.金额（按剩余期限）<6个月:G01资产总计减去BC列 小于180天;A列资产负债表资产总计期末余额（年末保持与G01利润结转后的资产总计一致）
     16.其他资产.金额（按剩余期限）6-12个月:G1.9其他有确定到期日的资产(理财资管回传表)180≦剩余期限<360
     16.其他资产.金额（按剩余期限）≥1年:G1.9其他有确定到期日的资产(理财资管回传表)剩余期限一年以上*/
   INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
     (DATA_DATE, --数据日期
      ORG_NUM, --机构号
      SYS_NAM, --模块简称
      REP_NUM, --报表编号
      ITEM_NUM, --指标号
      ITEM_VAL, --指标值
      FLAG, --标志位
      B_CURR_CD)
     SELECT I_DATADATE AS DATA_DATE, --数据日期
            A.ORG_NUM AS ORG_NUM,
            'CBRC' AS SYS_NAM, --模块简称
            'G2502' AS REP_NUM, --报表编号
            CASE
              WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
               'G25_2_2.15.C.2016' ---1年以上
              WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
               'G25_2_2.15.B.2016' --6个月-1年
             /* ELSE
               'G25_2_2.16.A.2016'*/
            END AS ITEM_NUM,
            SUM(RECVAPAY_AMT) AS ITEM_VAL,
            '2' AS FLAG,
            'ALL' AS B_CURR_CD
       FROM (SELECT A.ORG_NUM,COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) AS MATURITY_DT,
                    SUM(A.RECVAPAY_AMT) RECVAPAY_AMT
               FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
              WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
                AND FLAG = '1'
             GROUP BY A.ORG_NUM,COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE)
             UNION ALL
             SELECT A.ORG_NUM,REDEMP_DATE AS MATURITY_DT,
                    SUM(A.RECVAPAY_AMT)
               FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
              WHERE A.OPER_TYPE LIKE '2%' --运行方式是封闭式
                AND FLAG = '1'
              GROUP BY A.ORG_NUM,REDEMP_DATE) A
      GROUP BY A.ORG_NUM,
               CASE
                 WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
                  'G25_2_2.15.C.2016' ---1年以上
                 WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
                  'G25_2_2.15.B.2016' --6个月-1年
                /* ELSE
                  'G25_2_2.16.A.2016'*/
               END;
      COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取16.其他资产至A_REPT_ITEM_VAL(009816)结果表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取16.其他资产至A_REPT_ITEM_VAL(009803)结果表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

  --modiy by djh 20241210 16 其他次产 A列取：不良金额（M4+M5+M6+M6及以上）    信用卡
     INSERT INTO PM_RSDATA.CBRC_TMP_ITEM_VAL
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE,
              '009803',
              'CBRC' AS SYS_NAM,
              'G2502' AS REP_NUM,
              'G25_2_2.15.A.2016' AS ITEM_NUM,
              SUM(NVL(M0, 0) + NVL(T.M1, 0) + NVL(T.M2, 0) + NVL(T.M3, 0) +
                  NVL(T.M4, 0) + NVL(T.M5, 0) + NVL(T.M6, 0) +
                  NVL(T.M6_UP, 0)),
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM PM_RSDATA.SMTMODS_L_ACCT_CARD_CREDIT T
        WHERE T.DATA_DATE = I_DATADATE
          AND LXQKQS >= 4; --90天以上逾期

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取16.其他资产至A_REPT_ITEM_VAL(009803)结果表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



     INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT DATA_DATE, --数据日期
              ORG_NUM, --机构号
              SYS_NAM, --模块简称
              REP_NUM, --报表编号
              ITEM_NUM, --指标号
              SUM(ITEM_VAL) AS ITEM_VAL, --指标值
              FLAG, --标志位
              B_CURR_CD
         FROM PM_RSDATA.CBRC_TMP_ITEM_VAL
        GROUP BY DATA_DATE, --数据日期
                 ORG_NUM, --机构号
                 SYS_NAM, --模块简称
                 REP_NUM, --报表编号
                 ITEM_NUM, --指标值
                 FLAG, --标志位
                 B_CURR_CD;
     COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := V_PROCEDURE || '业务逻辑全部处理完成';
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
