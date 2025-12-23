CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g2501(II_DATADATE IN STRING --跑批日期
)
/******************************
  @author:DJH
  @create-date:20210930
  @description:G2501
  @modification history:
  m0.author-create_date-description
  --需求编号：JLBA202502280012 上线日期：2025-04-15,修改人：石雨,提出人：刘名赫 修改原因：2.1.3担保融资流出指标通过康星手工调仓表取数据
  --需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-27,修改人：石雨,提出人：王曦若
    需求编号：JLBA202505280011 上线日期：2025-09-19,修改人：狄家卉,提出人：赵翰君  修改原因：关于实现1104监管报送报表自动化采集加工的需求 增加009801清算中心(国际业务部)外币折人民币业务
    [JLBA202507210012_关于调整财政性存款及一般性存款相关科目统计方式的相关需求][提出人：于佳禾][上线时间：20250918][修改人：石雨][修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
目标表： PM_RSDATA.CBRC_A_REPT_ITEM_VAL
         PM_RSDATA.CBRC_EBDT_BATCHTRANSDTL_ACCT
         PM_RSDATA.CBRC_FDM_CUST_LNAC_INFO
         PM_RSDATA.CBRC_FDM_LNAC
         PM_RSDATA.CBRC_FDM_LNAC_PMT
         PM_RSDATA.CBRC_FDM_LNAC_PMT_BW
         PM_RSDATA.CBRC_FDM_LNAC_PMT_BW_G2501
         PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
         PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI
         PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
         PM_RSDATA.CBRC_ID_G25_ITEMDATA_NGI
         PM_RSDATA.CBRC_L_PUBL_HOLIDAY_G2501
         PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL
         PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL
         PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL
         PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT
         PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_BRO
         PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_SCALE
         PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_BIG
         PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL
         PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY1
         PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY2
         PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY3
         PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL
         PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY1
         PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY2
         PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY3
         PM_RSDATA.CBRC_TMP_L_CUST_BILL_TY
集市表： PM_RSDATA.SMTMODS_L_ACCT_DEPOSIT
         PM_RSDATA.SMTMODS_L_ACCT_FUND_INVEST
         PM_RSDATA.SMTMODS_L_ACCT_LOAN
         PM_RSDATA.SMTMODS_L_ACCT_OBS_LOAN
         PM_RSDATA.SMTMODS_L_AGRE_BOND_INFO
         PM_RSDATA.SMTMODS_L_AGRE_GUARANTEE_RELATION
         PM_RSDATA.SMTMODS_L_AGRE_GUARANTY_INFO
         PM_RSDATA.SMTMODS_L_AGRE_GUA_RELATION
         PM_RSDATA.SMTMODS_L_AGRE_LOAN_CONTRACT
         PM_RSDATA.SMTMODS_L_AGRE_REPURCHASE_GUARANTY_INFO
         PM_RSDATA.SMTMODS_L_CUST_BILL_TY
         PM_RSDATA.SMTMODS_L_CUST_C
         PM_RSDATA.SMTMODS_L_CUST_P
         PM_RSDATA.SMTMODS_L_FINA_GL
         PM_RSDATA.SMTMODS_L_PUBL_HOLIDAY
         PM_RSDATA.SMTMODS_L_PUBL_RATE
视图表   PM_RSDATA.SMTMODS_V_PUB_IDX_CK_GTGSHDQ
         PM_RSDATA.SMTMODS_V_PUB_IDX_CK_GTGSHHQ
         PM_RSDATA.SMTMODS_V_PUB_IDX_CK_GTGSHTZ
         PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL
         PM_RSDATA.SMTMODS_V_PUB_FUND_CDS_BAL
         PM_RSDATA.CBRC_V_PUB_FUND_MMFUND
         PM_RSDATA.CBRC_V_PUB_FUND_REPURCHASE

  *******************************/
 IS
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE    VARCHAR(30); --当前储存过程名称
  V_TAB_NAME     VARCHAR(30); --目标表名
  I_DATADATE     STRING; --数据日期(数值型)YYYYMMDD
  V_DATADATE     VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  D_DATADATE_CCY STRING; --数据日期(日期型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  V_ERRORDESC    VARCHAR(280); --错误内容
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时,用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM       VARCHAR2(30);
  
BEGIN

    set_env('inceptor.idempotent.check.exception', 'false');  --为了设置uuid不报错，uuid即幂等性，“幂等性检查异常”的配置项设置为 false，即在幂等性检查失败时不会抛出异常，而是允许系统继续执行后续操作
    
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';

    I_DATADATE  := II_DATADATE;
    V_SYSTEM    := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G2501');
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_TAB_NAME     := 'PM_RSDATA.CBRC_A_REPT_ITEM_VAL';
    V_DATADATE     := TO_CHAR(D_DATADATE_CCY, 'YYYY-MM-DD');
    D_DATADATE_CCY := I_DATADATE;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']G2501当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --资产
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_ID_G25_ITEMDATA_NGI';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_FDM_LNAC_PMT_BW_G2501';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_FDM_CUST_LNAC_INFO';
    --负债
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT'; --存款稳定分类：代发工资,2保证金存款,3存单质押
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL'; --零售账户
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL'; --小微型
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_BRO'; --有无业务关系判定
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_BIG'; --大中型
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_SCALE'; --大中小微客户规模划分
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY1'; --零售存款保险划分基础数据
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY2';--零售存款保险划分特殊数据
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY3';--零售存款保险划分结果数据
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY1'; --小微型存款保险划分基础数据
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY2';--小微型存款保险划分特殊数据
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY3';--小微型存款保险划分结果数据
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_L_CUST_BILL_TY'; --ADD BY DJH 20240510  金融市场部 009804

    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_L_PUBL_HOLIDAY_G2501'; --节假日临时表

    --开始处理存款部分
    DELETE FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL T
     WHERE T.REP_NUM = 'G2501'
       AND DATA_DATE = I_DATADATE
        AND T.ITEM_NUM <> 'G25_1_1.1.1.1.A.2014'; --现金从总账配置表出数

    COMMIT;

    V_STEP_FLAG := V_STEP_FLAG + 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '加工节假日临时表数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO PM_RSDATA.CBRC_L_PUBL_HOLIDAY_G2501
      (HOLIDAY_DATE, LASTDAY, DCQ)
       SELECT T.HOLIDAY_DATE AS HOLIDAY_DATE,
             MIN(T1.HOLIDAY_DATE) LASTDAY,
             MIN(T1.HOLIDAY_DATE) - I_DATADATE AS DCQ
        FROM PM_RSDATA.SMTMODS_L_PUBL_HOLIDAY T
        LEFT JOIN (SELECT T.HOLIDAY_DATE
                     FROM PM_RSDATA.SMTMODS_L_PUBL_HOLIDAY T
                    WHERE T.DATA_DATE = I_DATADATE
                      AND T.COUNTRY = 'CHN'
                      AND T.STATE = '220000'
                      AND T.WORKING_HOLIDAY = 'W' --工作日
                   ) T1
          ON  1=1
       WHERE T.DATA_DATE = I_DATADATE
         AND T.COUNTRY = 'CHN'
         AND T.STATE = '220000'
         AND T.WORKING_HOLIDAY = 'H' --假日
         AND T.HOLIDAY_DATE <= I_DATADATE
         AND  T.HOLIDAY_DATE < T1.HOLIDAY_DATE
       GROUP BY T.HOLIDAY_DATE;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '加工节假日临时表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取发工资全量客户标识更新至CBRC_EBDT_BATCHTRANSDTL_ACCT中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    -- 1代发工资,2保证金存款,3存单质押
    --把三类账户统一处理 ,  1代发工资,2保证金存款,3存单质押  客户范围如下

    --代发工资规则：1、代发工资全量客户标识更新,2、如果没有需要插入表中
    MERGE INTO PM_RSDATA.CBRC_EBDT_BATCHTRANSDTL_ACCT A
    USING (SELECT 
           DISTINCT O_ACCT_NUM AS ACCNO, STABLE_DEP_TYPE
             FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL B
            WHERE STABLE_DEP_TYPE = 'A01' --上游判定逻辑已经是一年内,因此直接更新掉全量数据就可以
              AND DATA_DATE = I_DATADATE) B
    ON (A.ACCNO = B.ACCNO)
    WHEN MATCHED THEN
      UPDATE
         SET A.WORKDATE = I_DATADATE
    WHEN NOT MATCHED THEN
      INSERT (A.ACCNO, A.WORKDATE) VALUES (B.ACCNO, I_DATADATE);
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取代发工资全量客户标识更新至CBRC_EBDT_BATCHTRANSDTL_ACCT中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取稳定存款分类至TMP_DEPOSIT_WD_ACCT中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
   --保证金
    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT 
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
       SIGN,
       REMAIN_TERM_CODE_QX,
       INTEREST_ACCURAL,
       INTEREST_ACCURAL_ITEM,
       INTEREST_ACCURED,
       MATUR_DATE_ACCURED)
      SELECT 
       DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ACCT_TYP, --账户类型
       ACCT_CUR, --账户币种
       ACCT_BAL, --账户余额
       ACCT_BAL_RMB, --账户余额_人民币
       FLAG, --数据标识
       GL_ITEM_CODE, --科目号
       CUST_ID, --客户号
       T.ACCT_NAM, --账户名称
       T.MATUR_DATE, --到期日
       REMAIN_TERM_CODE, --剩余期限代码
       ACCT_NUM, --账号
       'A' AS SIGN,
       REMAIN_TERM_CODE_QX,
       INTEREST_ACCURAL,
       INTEREST_ACCURAL_ITEM,
       INTEREST_ACCURED,
       MATUR_DATE_ACCURED
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.GL_ITEM_CODE IN ('20110114','20110115','20110209','20110210')
         AND T.ACCT_BAL<>0;
    COMMIT;

   --存单质押
    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT 
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
       SIGN,
       REMAIN_TERM_CODE_QX,
       INTEREST_ACCURAL,
       INTEREST_ACCURAL_ITEM,
       INTEREST_ACCURED,
       MATUR_DATE_ACCURED)
    --存单质押：押品为本行存单 ,到期日小于30
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
       DEP_MATURITY,--到期日
       case when  T1.DEP_MATURITY - D_DATADATE_CCY <= 30 then
         'A'
         else
           'Z' end AS REMAIN_TERM_CODE, --剩余期限代码
       T.ACCT_NUM, --账号
       'B' AS SIGN,
       T1.DEP_MATURITY - D_DATADATE_CCY AS  REMAIN_TERM_CODE_QX, --特殊需要取押品的到期日
       T.INTEREST_ACCURAL,
       T.INTEREST_ACCURAL_ITEM,
       T.INTEREST_ACCURED,
       T.MATUR_DATE_ACCURED
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T
       INNER JOIN (SELECT COLL_BILL_ACCT, DEP_MATURITY
                     FROM (SELECT 
                            COLL_BILL_ACCT,
                            DEP_MATURITY,
                            ROW_NUMBER() OVER(PARTITION BY COLL_BILL_ACCT ORDER BY DEP_MATURITY DESC) AS RN
                             FROM PM_RSDATA.SMTMODS_L_AGRE_GUARANTY_INFO
                            WHERE DATA_DATE = I_DATADATE
                              AND COLL_TYP = 'A0201'
                              AND COLL_STATUS='Y' --押品状态有效
                              ) T
                    WHERE RN = 1) T1 --本行存单
          ON T.O_ACCT_NUM = T1.COLL_BILL_ACCT --外部账号关联
       LEFT JOIN (SELECT DISTINCT ACCT_NUM FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT WHERE SIGN='A') T2
             ON T.ACCT_NUM=T2.ACCT_NUM
       WHERE T.DATA_DATE = I_DATADATE
       AND T2.ACCT_NUM  IS NULL;
    --存单质押有一笔编号对应多笔,去最新的止付日期在三个月内的

    COMMIT;


     --代发工资,如果一年内有流水情况客户算代发工资
    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT 
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
       SIGN, --客户标识
       REMAIN_TERM_CODE_QX,
       INTEREST_ACCURAL,
       INTEREST_ACCURAL_ITEM,
       INTEREST_ACCURED,
       MATUR_DATE_ACCURED)
      SELECT 
       DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ACCT_TYP, --账户类型
       ACCT_CUR, --账户币种
       ACCT_BAL, --账户余额
       ACCT_BAL_RMB, --账户余额_人民币
       FLAG, --数据标识
       GL_ITEM_CODE, --科目号
       CUST_ID, --客户号
       T.ACCT_NAM, --账户名称
       T.MATUR_DATE, --到期日
       REMAIN_TERM_CODE, --剩余期限代码
       T.ACCT_NUM, --账号
       'C' AS SIGN,
       REMAIN_TERM_CODE_QX,
       INTEREST_ACCURAL,
       INTEREST_ACCURAL_ITEM,
       INTEREST_ACCURED,
       MATUR_DATE_ACCURED
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T
       INNER JOIN (SELECT DISTINCT ACCNO
                     FROM PM_RSDATA.CBRC_EBDT_BATCHTRANSDTL_ACCT
                    WHERE WORKDATE BETWEEN
                          TO_CHAR(ADD_MONTHS(D_DATADATE_CCY,
                                             -12),
                                  'YYYYMMDD') AND I_DATADATE) T1
          ON T.O_ACCT_NUM = T1.ACCNO
       LEFT JOIN (SELECT DISTINCT ACCT_NUM FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT WHERE SIGN IN('A','B')) T2
             ON T.ACCT_NUM=T2.ACCT_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T.GL_ITEM_CODE LIKE '20110101%' --LIUD MF 代发工资只取21101科目
         AND T2.ACCT_NUM  IS NULL;
    COMMIT;


    --206国库定期,219结构性存款,20504转股协议存款一定是不可以提前支取在30天以内

    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT 
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
       SIGN,
       REMAIN_TERM_CODE_QX,
       INTEREST_ACCURAL,
       INTEREST_ACCURAL_ITEM,
       INTEREST_ACCURED,
       MATUR_DATE_ACCURED)
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
       T.REMAIN_TERM_CODE, --剩余期限代码
       T.ACCT_NUM, --账号
       'D' AS SIGN,
       REMAIN_TERM_CODE_QX,
       INTEREST_ACCURAL,
       INTEREST_ACCURAL_ITEM,
       INTEREST_ACCURED,
       MATUR_DATE_ACCURED
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T
        LEFT JOIN (SELECT DISTINCT ACCT_NUM
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT
                    WHERE SIGN IN ('A', 'B','C')) T1
          ON T.ACCT_NUM = T1.ACCT_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND ( T.GL_ITEM_CODE IN ('20110701', '20110211' ) -- /*,'21901'*/) --219结构性存款以后也不会有
           OR T.GL_ITEM_CODE LIKE '2010%' ) --ALTER BY 石雨 20250527 JLBA202504180011
         AND ACCT_BAL <> 0
         AND T1.ACCT_NUM  IS NULL;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取稳定存款分类至TMP_DEPOSIT_WD_ACCT中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    ---------------------------------------------零售、小企业,大中型,稳定存款明细数据---------------------------------------------
    ----------------------零售稳定存款
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取零售基础数据至TMP_DEPOSIT_WD_DIFF_PERSONAL中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --科目范围：211活期储蓄存款,203个人通知存款,215定期储蓄存款,25101个人保证金存款, 22002发行个人大额存单
    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL 
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
       FLAG_CODE,
       REMAIN_TERM_CODE_QX,
       INTEREST_ACCURAL,
       INTEREST_ACCURAL_ITEM,
       INTEREST_ACCURED,
       MATUR_DATE_ACCURED,
       SIGN)
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
       T.REMAIN_TERM_CODE, --剩余期限代码
       T.ACCT_NUM, --账号
       0 AS BAL_TOTAL,
       '01' AS FLAG_CODE, --零售
       REMAIN_TERM_CODE_QX,
       INTEREST_ACCURAL,
       INTEREST_ACCURAL_ITEM,
       INTEREST_ACCURED,
       MATUR_DATE_ACCURED,
       `SIGN`
       FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT T
       WHERE T.DATA_DATE = I_DATADATE
         AND (T.GL_ITEM_CODE IN ('20110101','20110102', '20110103','20110104','20110105','20110106','20110107','20110108','20110109') OR
             T.GL_ITEM_CODE IN ('20110110', '20110114','20110115', '20110113', '20110111')
             )
        -- AND T.REMAIN_TERM_CODE IN ('A', 'B', 'C') --暂时不限制30天内
         AND SIGN IN ('A', 'B', 'C'); --30日以内

    COMMIT;

    --零售,去掉零售稳定存款
    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL 
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
       FLAG_CODE,
       REMAIN_TERM_CODE_QX,
       INTEREST_ACCURAL,
       INTEREST_ACCURAL_ITEM,
       INTEREST_ACCURED,
       MATUR_DATE_ACCURED)
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
       T.REMAIN_TERM_CODE, --剩余期限代码
       T.ACCT_NUM, --账号
       0 AS BAL_TOTAL,
       '02' AS FLAG_CODE, --零售
       REMAIN_TERM_CODE_QX,
       INTEREST_ACCURAL,
       INTEREST_ACCURAL_ITEM,
       INTEREST_ACCURED,
       MATUR_DATE_ACCURED
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T
        LEFT JOIN (SELECT DISTINCT ACCT_NUM
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT
                    WHERE DATA_DATE = I_DATADATE
                      AND SIGN IN ('A', 'B', 'C')) T2 --去掉1代发工资,2保证金存款,3存单质押
          ON T2.ACCT_NUM = T.ACCT_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T2.ACCT_NUM IS NULL
         AND (T.GL_ITEM_CODE IN ('20110101','20110102', '20110103','20110104','20110105','20110106','20110107','20110108','20110109') OR
             T.GL_ITEM_CODE IN ('20110110', '20110114','20110115', '20110113', '20110111')
              OR T.GL_ITEM_CODE ='22410102'  --[JLBA202507210012][石雨][修改内容：22410102个人久悬未取款]
             );
    COMMIT;
    --对公：单位存款业务中发生的个体工商户,要放在零售
    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL 
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
       FLAG_CODE,
       REMAIN_TERM_CODE_QX,
       INTEREST_ACCURAL,
       INTEREST_ACCURAL_ITEM,
       INTEREST_ACCURED,
       MATUR_DATE_ACCURED)
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
       T.REMAIN_TERM_CODE, --剩余期限代码
       T.ACCT_NUM, --账号
       0 AS BAL_TOTAL,
       '03' AS FLAG_CODE, --零售
       REMAIN_TERM_CODE_QX,
       INTEREST_ACCURAL,
       INTEREST_ACCURAL_ITEM,
       INTEREST_ACCURED,
       MATUR_DATE_ACCURED
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T
       INNER JOIN (SELECT ACCT_NUM
          FROM PM_RSDATA.SMTMODS_V_PUB_IDX_CK_GTGSHHQ T
         WHERE T.DATA_DATE = I_DATADATE
        UNION ALL
        SELECT ACCT_NUM
          FROM PM_RSDATA.SMTMODS_V_PUB_IDX_CK_GTGSHDQ T
         WHERE T.DATA_DATE = I_DATADATE
        UNION ALL
        SELECT ACCT_NUM
          FROM PM_RSDATA.SMTMODS_V_PUB_IDX_CK_GTGSHTZ T
         WHERE T.DATA_DATE = I_DATADATE
        --[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
        UNION ALL
        SELECT 
    T.ACCT_NUM 
     FROM PM_RSDATA.SMTMODS_L_ACCT_DEPOSIT T
    INNER JOIN PM_RSDATA.SMTMODS_L_CUST_C C
       ON T.DATA_DATE = C.DATA_DATE
      AND T.CUST_ID = C.CUST_ID
    INNER JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B --汇率表
       ON T.DATA_DATE = B.DATA_DATE
      AND T.CURR_CD = B.BASIC_CCY
      AND B.FORWARD_CCY = 'CNY' --折人民币
    WHERE C.DEPOSIT_CUSTTYPE IN ('13', '14')
      AND T.GL_ITEM_CODE IN ('20110301', '20110302', '20110303', '22410101') --201104 一般单位活期  22410101单位久悬未取款
      AND T.DATA_DATE = I_DATADATE
    GROUP BY T.ACCT_NUM 
         
         
         ) T1  --个体工商户{活期/定期/通知存款}(M_INDEX_META) add by djh20220614
          ON T.ACCT_NUM = T1.ACCT_NUM
        LEFT JOIN (SELECT DISTINCT ACCT_NUM
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT
                    WHERE DATA_DATE = I_DATADATE) T2
          ON t.ACCT_NUM = T2.ACCT_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T2.ACCT_NUM IS NULL
         AND (T.GL_ITEM_CODE IN
             ('20110201', '20110205', '20110701', '20110206', '20110208', '20120204', '20120106') OR 
             T.GL_ITEM_CODE IN ('20110202','20110203','20110204','20110211', '20130101','20130201','20130301', '20140101','20140201','20140301') OR
             T.GL_ITEM_CODE IN ('20110209','20110210')
             OR T.GL_ITEM_CODE LIKE '2010%'  --ALTER BY 石雨 20250527 JLBA202504180011
             OR T.GL_ITEM_CODE IN ('22410101','20110301','20110302','20110303','20080101','20090101') --[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
             );
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取零售基础数据至TMP_DEPOSIT_WD_DIFF_PERSONAL中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    ---------------------------------------------零售、小企业,大中型,稳定存款明细数据---------------------------------------------
    ---------------------------------------------按存款保险拆分---------------------------------------------
    --G2501,G2502规则：--不可提前支取需要按照优先级别,数据顺序：1保证金存款,2存单质押,3代发工资,4其它 先短期后长期
    --总体逻辑是只对不可提前支取部分进行50万存款保险划分
    --处理账户数据（按客户分组,小于50万进稳定存款（不满足有效存款保险附加标准）,大于50万进50万以上欠稳定存款（无存款保险））
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取零售按存款保险拆分明细中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
INSERT 
INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY1 
  (ACCT_NUM,
   BAL_TOTAL,
   CUST_ID,
   GL_ITEM_CODE,
   REAL_SCALE,
   ACCT_BAL_RMB,
   MATUR_DATE,
   REMAIN_TERM_CODE,
   REMAIN_TERM_CODE_QX,
   SIGN,
   SAFETY_FLAG,
   ORG_NUM)
  SELECT 
   ACCT_NUM,
   BAL_TOTAL,
   CUST_ID,
   GL_ITEM_CODE,
   REAL_SCALE,
   ACCT_BAL_RMB,
   MATUR_DATE,
   REMAIN_TERM_CODE,
   REMAIN_TERM_CODE_QX,
   SIGN,
   '001' AS SAFETY_FLAG,
   ORG_NUM
    FROM (SELECT 
           ACCT_NUM,
           BAL_TOTAL,
           CUST_ID,
           GL_ITEM_CODE,
           CASE
             WHEN BAL_TOTAL <= 500000 THEN
              '小于'
             ELSE
              '大于'
           END AS REAL_SCALE,
           ACCT_BAL_RMB,
           MATUR_DATE,
           REMAIN_TERM_CODE,
           REMAIN_TERM_CODE_QX,
           SIGN,
           ORG_NUM
            FROM (SELECT 
                   T.ACCT_NUM,
                   T.CUST_ID,
                   T.GL_ITEM_CODE,
                   SUM(T.ACCT_BAL_RMB) OVER(PARTITION BY T.CUST_ID) AS BAL_TOTAL,
                   ACCT_BAL_RMB,
                   T.MATUR_DATE,
                   T.SIGN,
                   REMAIN_TERM_CODE,
                   REMAIN_TERM_CODE_QX,
                   ORG_NUM
                    FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL T
                   WHERE T.FLAG_CODE = '01'
                     AND T.ACCT_BAL_RMB <> 0))
   WHERE REAL_SCALE = '小于';

COMMIT;

INSERT 
INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY1 
  (ACCT_NUM,
   BAL_TOTAL,
   CUST_ID,
   GL_ITEM_CODE,
   REAL_SCALE,
   ACCT_BAL_RMB,
   MATUR_DATE,
   REMAIN_TERM_CODE,
   REMAIN_TERM_CODE_QX,
   SIGN,
   SAFETY_FLAG,
   ROWNN,
   ORG_NUM)
  SELECT 
   ACCT_NUM,
   BAL_TOTAL,
   CUST_ID,
   GL_ITEM_CODE,
   REAL_SCALE,
   ACCT_BAL_RMB,
   MATUR_DATE,
   REMAIN_TERM_CODE,
   REMAIN_TERM_CODE_QX,
   SIGN,
   '002' AS SAFETY_FLAG,
   ROWNN,
   ORG_NUM
    FROM (SELECT 
           ACCT_NUM,
           BAL_TOTAL,
           CUST_ID,
           GL_ITEM_CODE,
           CASE
             WHEN BAL_TOTAL <= 500000 THEN
              '小于'
             ELSE
              '大于'
           END AS REAL_SCALE,
           ACCT_BAL_RMB,
           MATUR_DATE,
           REMAIN_TERM_CODE,
           REMAIN_TERM_CODE_QX,
           SIGN,
           UUID() AS ROWNN,
           ORG_NUM
            FROM (SELECT 
                   T.ACCT_NUM,
                   T.CUST_ID,
                   T.GL_ITEM_CODE,
                   SUM(T.ACCT_BAL_RMB) OVER(PARTITION BY T.CUST_ID) AS BAL_TOTAL,
                   ACCT_BAL_RMB,
                   T.MATUR_DATE,
                   T.SIGN,
                   REMAIN_TERM_CODE,
                   REMAIN_TERM_CODE_QX,
                   ORG_NUM
                    FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL T
                   WHERE T.FLAG_CODE = '01'
                     AND T.ACCT_BAL_RMB <> 0))
   WHERE REAL_SCALE = '大于';
 COMMIT;
--处理所有在50万节点上的账号,处理数据为两余额,一余额进50万以下稳定存款（不满足有效存款保险附加标准）,另一余额进50万以上欠稳定存款（无存款保险）
INSERT 
INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY2 
  (ACCT_NUM,
   BAL_TOTAL,
   CUST_ID,
   GL_ITEM_CODE,
   REAL_SCALE,
   ACCT_BAL_RMB,
   MATUR_DATE,
   REMAIN_TERM_CODE,
   REMAIN_TERM_CODE_QX,
   SIGN,
   SAFETY_FLAG,
   ROWNN,
   LEIJIA,
   FLAG,
   RN,
   OTHER_BAL,
   NORMAL_BAL,
   RNUMBER,
   ORG_NUM)
  SELECT 
   ACCT_NUM,
   BAL_TOTAL,
   CUST_ID,
   GL_ITEM_CODE,
   REAL_SCALE,
   ACCT_BAL_RMB,
   MATUR_DATE,
   REMAIN_TERM_CODE,
   REMAIN_TERM_CODE_QX,
   SIGN,
   SAFETY_FLAG,
   ROWNN,
   LEIJIA,
   FLAG,
   RN,
   OTHER_BAL,
   NORMAL_BAL,
   RNUMBER,
   ORG_NUM
    FROM (SELECT ACCT_NUM,
                 BAL_TOTAL,
                 CUST_ID,
                 GL_ITEM_CODE,
                 REAL_SCALE,
                 ACCT_BAL_RMB,
                 MATUR_DATE,
                 REMAIN_TERM_CODE,
                 REMAIN_TERM_CODE_QX,
                 SIGN,
                 SAFETY_FLAG,
                 ROWNN,
                 LEIJIA,
                 FLAG,
                 RN,
                 LEIJIA - 500000 OTHER_BAL,
                 ACCT_BAL_RMB - (LEIJIA - 500000) NORMAL_BAL,
                 ROW_NUMBER() OVER(PARTITION BY CUST_ID ORDER BY RN) AS RNUMBER,
                 ORG_NUM
            FROM (SELECT ACCT_NUM,
                         BAL_TOTAL,
                         CUST_ID,
                         GL_ITEM_CODE,
                         REAL_SCALE,
                         ACCT_BAL_RMB,
                         MATUR_DATE,
                         REMAIN_TERM_CODE,
                         REMAIN_TERM_CODE_QX,
                         SIGN,
                         SAFETY_FLAG,
                         ROWNN,
                         LEIJIA,
                         CASE
                           WHEN LEIJIA > 500000 THEN
                            '大于'
                           ELSE
                            '小于'
                         END FLAG,
                         ROW_NUMBER() OVER(PARTITION BY CUST_ID ORDER BY SIGN, MATUR_DATE, LEIJIA) AS RN, --按照保证金,存单质押,其他,到期日顺序排序,
                         ORG_NUM
                    FROM (SELECT ACCT_NUM,
                                 BAL_TOTAL,
                                 CUST_ID,
                                 GL_ITEM_CODE,
                                 REAL_SCALE,
                                 ACCT_BAL_RMB,
                                 MATUR_DATE,
                                 REMAIN_TERM_CODE,
                                 REMAIN_TERM_CODE_QX,
                                 SIGN,
                                 SAFETY_FLAG,
                                 ROWNN,
                                 SUM(T.ACCT_BAL_RMB) OVER(PARTITION BY CUST_ID ORDER BY SIGN, MATUR_DATE, ACCT_BAL_RMB, ACCT_NUM) LEIJIA, --按照保证金,存单质押,其他,到期日进行余额累加

                                 ORG_NUM
                            FROM (SELECT 
                                   ACCT_NUM,
                                   BAL_TOTAL,
                                   CUST_ID,
                                   GL_ITEM_CODE,
                                   REAL_SCALE,
                                   ACCT_BAL_RMB,
                                   MATUR_DATE,
                                   REMAIN_TERM_CODE,
                                   REMAIN_TERM_CODE_QX,
                                   SIGN,
                                   SAFETY_FLAG,
                                   ROWNN,
                                   ORG_NUM
                                    FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY1
                                   WHERE SAFETY_FLAG = '002') T) K
                  ) T
           WHERE T.FLAG = '大于') T
   WHERE T.RNUMBER = 1;
 COMMIT;
--从大于50万数据剔除特殊处理数据,取特殊处理数据
INSERT 
INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY3 
  (ACCT_NUM,
   BAL_TOTAL,
   CUST_ID,
   GL_ITEM_CODE,
   REAL_SCALE,
   ACCT_BAL_RMB,
   MATUR_DATE,
   REMAIN_TERM_CODE,
   REMAIN_TERM_CODE_QX,
   SIGN,
   SAFETY_FLAG,
   ROWNN,
   DIFF,
   ORG_NUM)
  SELECT T1.ACCT_NUM,
         T1.BAL_TOTAL,
         T1.CUST_ID,
         T1.GL_ITEM_CODE,
         T1.REAL_SCALE,
         T1.ACCT_BAL_RMB, --正常存款保险
         T1.MATUR_DATE,
         T1.REMAIN_TERM_CODE,
         T1.REMAIN_TERM_CODE_QX,
         T1.SIGN,
         T1.SAFETY_FLAG,
         T1.ROWNN,
         'A' AS DIFF,
         ORG_NUM
    FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY1 T1
   WHERE T1.SAFETY_FLAG = '001' --001 50万以下存款保险部分
  UNION ALL
  SELECT T1.ACCT_NUM,
         T1.BAL_TOTAL,
         T1.CUST_ID,
         T1.GL_ITEM_CODE,
         T1.REAL_SCALE,
         T1.ACCT_BAL_RMB, --正常存款保险
         T1.MATUR_DATE,
         T1.REMAIN_TERM_CODE,
         T1.REMAIN_TERM_CODE_QX,
         T1.SIGN,
         T1.SAFETY_FLAG,
         T1.ROWNN,
         'B' AS DIFF,
         T1.ORG_NUM
    FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY1 T1
    LEFT JOIN PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY2 T2
      ON T1.ROWNN = T2.ROWNN
   WHERE T1.SAFETY_FLAG = '002' --  002 50万以上存款保险部分
     AND T2.ROWNN IS NULL
  UNION ALL
  SELECT ACCT_NUM,
         BAL_TOTAL,
         CUST_ID,
         GL_ITEM_CODE,
         REAL_SCALE,
         NORMAL_BAL AS ACCT_BAL_RMB, --50万以下存款保险部分
         MATUR_DATE,
         REMAIN_TERM_CODE,
         REMAIN_TERM_CODE_QX,
         SIGN,
         SAFETY_FLAG,
         ROWNN,
         'C' AS DIFF,
         ORG_NUM
    FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY2 T2
  UNION ALL
  SELECT ACCT_NUM,
         BAL_TOTAL,
         CUST_ID,
         GL_ITEM_CODE,
         REAL_SCALE,
         OTHER_BAL AS ACCT_BAL_RMB, --50万以上存款保险部分
         MATUR_DATE,
         REMAIN_TERM_CODE,
         REMAIN_TERM_CODE_QX,
         SIGN,
         SAFETY_FLAG,
         ROWNN,
         'D' AS DIFF,
         ORG_NUM
    FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY2 T2;

  COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取零售按存款保险拆分明细中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    ---------------------------------------------零售
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取零售按存款保险拆分至G2501_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --30日内到期  1代发工资,2保证金存款,3存单质押
    --存款按客户分组,50万以内稳定存款（不满足有效存款保险附加标准）,50万以上欠稳定存款（无存款保险）

    INSERT INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.1.2.A.2014',
             SUM(A.ACCT_BAL_RMB) VAL
        FROM (SELECT 
               T.CUST_ID,
               CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY3 T
               WHERE T.DIFF IN ('A', 'C')
               AND (T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <=30)
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM
    UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.1.4.A.2014',
             SUM(A.ACCT_BAL_RMB) VAL
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY3 T
               WHERE T.DIFF IN ('B', 'D')
               AND (T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <=30)
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM;
    COMMIT;

    -- 除以上3类账户   按客户分组

          INSERT INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM, --明细不能取机构,有可能客户在不同机构与数据,关联时卉产生重复数据,翻倍等
             'G25_1_1.2.1.1.3.A.2014' AS ITEM_NUM, ---2.1.1.3欠稳定存款（有存款保险）
             SUM(CASE
                   WHEN 500000 - NVL(A.ACCT_BAL_RMB, 0) >= 0 THEN
                    A.ACCT_BAL_RMB
                   WHEN 500000 - NVL(A.ACCT_BAL_RMB, 0)
                        < 0 THEN
                    500000
                 END) AS LOAN_ACCT_BAL_RMB
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL T
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.FLAG_CODE IN ('02', '03')
               GROUP BY T.CUST_ID,
               CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM
       UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.1.4.A.2014' AS ITEM_NUM, ---2.1.1.4欠稳定存款（无存款保险）
             SUM(CASE
                   WHEN (500000 - NVL(A.ACCT_BAL_RMB, 0)  < 0) THEN
                    (NVL(A.ACCT_BAL_RMB, 0) - 500000 )
                   ELSE
                    0
                 END) AS LOAN_ACCT_BAL_RMB
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL T
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.FLAG_CODE IN ('02', '03')
                 AND T.ACCT_BAL_RMB <> 0
               GROUP BY T.CUST_ID,
               CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM
        ;
    COMMIT;

   /* -----3.5.1其中：定期存款 '21510'其他定期储蓄存款（含有奖储蓄）没有到期日放次日
    INSERT INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
      SELECT I_DATADATE,
             '990000' AS ORG_NUM,
             'G25_1_1.2.1.1.3.A.2014', --2.1.1.3欠稳定存款（有存款保险）
             sum(A.CREDIT_BAL * B.CCY_RATE)
        FROM  PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '20110109' --'21510'其他定期储蓄存款（含有奖储蓄）
         AND A.CURR_CD <> 'BWB' --本外币合计去掉
         and A.ORG_NUM = '990000';
    COMMIT;*/

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取零售按存款保险拆分至G2501_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    ----------------------对公存款 基础数据处理----------------------
    --首先按照客户规模大中小微划分,如果没有规模按照存款余额是否大于800万
    /* 科目范围： 201单位活期存款,202单位通知存款,205单位定期存款,206国库定期,218单位信用卡存款,22001发行单位大额存单,
     243应解汇款及临时存款,244开出汇票,25102单位保证金存款（2510201单位活期保证金存款,2510202单位定期保证金存款）,
    '2340204', '234010204',219结构性存款*/

    /* 1、保证金 30天以内 单独处理 不区分是否有业务关系都放在有业务关系中
    2、存单质押按照是否担保在30天以内,
    3、206国库定期和219结构性存款按照不可提前支取在30天以内,
    4、20504转股协议存款一定是不可以提前支取在30天以内
    5、其他存款原来都可视为活期*/

    --其中特殊处理：206国库定期,219结构性存款按照在30天以内,20504转股协议存款一定是不可以提前支取在30天以内
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取企业规模划分至TMP_DEPOSIT_WD_ACCT_SCALE中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_SCALE 
      (DATA_DATE, ACCT_NUM, BAL_TOTAL, CUST_ID, GL_ITEM_CODE, REAL_SCALE)
      SELECT 
       I_DATADATE,
       ACCT_NUM,
       BAL_TOTAL,
       CUST_ID,
       GL_ITEM_CODE,
       CASE
         WHEN BAL_TOTAL <= 8000000 THEN
          'ST' --小微企业
         ELSE
          'BM' --大中企业
       END AS REAL_SCALE
        FROM (SELECT DISTINCT T.ACCT_NUM,
                              T.CUST_ID,
                              T.GL_ITEM_CODE,
                              SUM(T.ACCT_BAL_RMB) OVER(PARTITION BY T.CUST_ID) AS BAL_TOTAL
                FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.ACCT_NUM NOT IN
                     (SELECT ACCT_NUM
                        FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL
                       WHERE FLAG_CODE = '03'
                         AND DATA_DATE = I_DATADATE) --去掉个体工商户放在零售部分数据
                 AND (T.GL_ITEM_CODE IN ('20110201',
                                         '20110205',
                                         '20110701',
                                         '20110206',
                                         '20110208',
                                         '20120204',
                                         '20120106') OR
                                          T.GL_ITEM_CODE LIKE '2010%' OR --ALTER BY 石雨 20250527 JLBA202504180011
                     T.GL_ITEM_CODE IN ('20110202','20110203','20110204','20110211', '20130101','20130201','20130301', '20140101','20140201','20140301') OR
                     T.GL_ITEM_CODE IN ('20110209','20110210')
                     OR T.GL_ITEM_CODE IN ('22410101','20110301','20110302','20110303','20080101','20090101') --[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
             
                     )) T;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取企业规模划分至TMP_DEPOSIT_WD_ACCT_SCALE中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    ----------------------对公存款  基础数据处理----------------------
    ---------------------小微型 --------------------------------------------
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取小微企业基础数据至TMP_DEPOSIT_WD_DIFF_SMALL中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

INSERT 
INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL 
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
   FLAG_CODE,
   SIGN,
   REMAIN_TERM_CODE_QX)
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
   T.REMAIN_TERM_CODE, --剩余期限代
   T.ACCT_NUM, --账号
   0 AS BAL_TOTAL,
   '01' AS FLAG_CODE,
   SIGN, --零售
   REMAIN_TERM_CODE_QX
    FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT T
   INNER JOIN (SELECT DISTINCT ACCT_NUM, REAL_SCALE
                 FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_SCALE
                WHERE DATA_DATE = I_DATADATE) T1
      ON T.ACCT_NUM = T1.ACCT_NUM
   WHERE T.DATA_DATE = I_DATADATE
     AND T1.REAL_SCALE = 'ST' --客户规模小微型或规模小于800万
        --  AND T.REMAIN_TERM_CODE IN ('A', 'B', 'C') --暂时不限制30天内
     AND SIGN IN ('A', 'B', 'C');

    COMMIT;

    --对公,去掉对公稳定存款
    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL 
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
       FLAG_CODE,
       REMAIN_TERM_CODE_QX)
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
       T.REMAIN_TERM_CODE, --剩余期限代
       T.ACCT_NUM, --账号
        0 AS BAL_TOTAL,
       '02' AS FLAG_CODE, --零售
       REMAIN_TERM_CODE_QX
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T
       INNER JOIN (SELECT DISTINCT ACCT_NUM, REAL_SCALE--所有存款+206国库定期,219结构性存款,20504转股协议存款其他科目数据30天以内
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_SCALE
                    WHERE DATA_DATE = I_DATADATE) T1
          ON T.ACCT_NUM = T1.ACCT_NUM
        LEFT JOIN (SELECT DISTINCT ACCT_NUM
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT
                    WHERE DATA_DATE = I_DATADATE
                      AND SIGN IN ('A', 'B', 'C')) T2
          ON T.ACCT_NUM = T2.ACCT_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T2.ACCT_NUM IS NULL --包含非206国库定期,219结构性存款,20504转股协议存款全部
         AND T1.REAL_SCALE = 'ST'; --客户规模小微型或规模小于800万
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取小微企业基础数据至TMP_DEPOSIT_WD_DIFF_SMALL中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取小微企业存款保险拆分明细中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

INSERT 
INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY1 
  (ACCT_NUM,
   BAL_TOTAL,
   CUST_ID,
   GL_ITEM_CODE,
   REAL_SCALE,
   ACCT_BAL_RMB,
   MATUR_DATE,
   REMAIN_TERM_CODE,
   REMAIN_TERM_CODE_QX,
   SIGN,
   SAFETY_FLAG,
   ORG_NUM)
  SELECT 
   ACCT_NUM,
   BAL_TOTAL,
   CUST_ID,
   GL_ITEM_CODE,
   REAL_SCALE,
   ACCT_BAL_RMB,
   MATUR_DATE,
   REMAIN_TERM_CODE,
   REMAIN_TERM_CODE_QX,
   SIGN,
   '001' AS SAFETY_FLAG,
   ORG_NUM
    FROM (SELECT 
           ACCT_NUM,
           BAL_TOTAL,
           CUST_ID,
           GL_ITEM_CODE,
           CASE
             WHEN BAL_TOTAL <= 500000 THEN
              '小于'
             ELSE
              '大于'
           END AS REAL_SCALE,
           ACCT_BAL_RMB,
           MATUR_DATE,
           REMAIN_TERM_CODE,
           REMAIN_TERM_CODE_QX,
           SIGN,
           ORG_NUM
            FROM (SELECT 
                   T.ACCT_NUM,
                   T.CUST_ID,
                   T.GL_ITEM_CODE,
                   SUM(T.ACCT_BAL_RMB) OVER(PARTITION BY T.CUST_ID) AS BAL_TOTAL,
                   ACCT_BAL_RMB,
                   T.MATUR_DATE,
                   T.SIGN,
                   REMAIN_TERM_CODE,
                   REMAIN_TERM_CODE_QX,
                   ORG_NUM
                    FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL T
                   WHERE T.FLAG_CODE = '01'
                     AND T.ACCT_BAL_RMB <> 0))
   WHERE REAL_SCALE = '小于';

COMMIT;

INSERT 
INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY1 
  (ACCT_NUM,
   BAL_TOTAL,
   CUST_ID,
   GL_ITEM_CODE,
   REAL_SCALE,
   ACCT_BAL_RMB,
   MATUR_DATE,
   REMAIN_TERM_CODE,
   REMAIN_TERM_CODE_QX,
   SIGN,
   SAFETY_FLAG,
   ROWNN,
   ORG_NUM)
  SELECT 
   ACCT_NUM,
   BAL_TOTAL,
   CUST_ID,
   GL_ITEM_CODE,
   REAL_SCALE,
   ACCT_BAL_RMB,
   MATUR_DATE,
   REMAIN_TERM_CODE,
   REMAIN_TERM_CODE_QX,
   SIGN,
   '002' AS SAFETY_FLAG,
   ROWNN,
   ORG_NUM
    FROM (SELECT 
           ACCT_NUM,
           BAL_TOTAL,
           CUST_ID,
           GL_ITEM_CODE,
           CASE
             WHEN BAL_TOTAL <= 500000 THEN
              '小于'
             ELSE
              '大于'
           END AS REAL_SCALE,
           ACCT_BAL_RMB,
           MATUR_DATE,
           REMAIN_TERM_CODE,
           REMAIN_TERM_CODE_QX,
           SIGN,
           UUID() AS ROWNN,
           ORG_NUM
            FROM (SELECT 
                   T.ACCT_NUM,
                   T.CUST_ID,
                   T.GL_ITEM_CODE,
                   SUM(T.ACCT_BAL_RMB) OVER(PARTITION BY T.CUST_ID) AS BAL_TOTAL,
                   ACCT_BAL_RMB,
                   T.MATUR_DATE,
                   T.SIGN,
                   REMAIN_TERM_CODE,
                   REMAIN_TERM_CODE_QX,
                   ORG_NUM
                    FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL T
                   WHERE T.FLAG_CODE = '01'
                     AND T.ACCT_BAL_RMB <> 0))
   WHERE REAL_SCALE = '大于';
 COMMIT;
--处理所有在50万节点上的账号,处理数据为两余额,一余额进稳定存款（不满足有效存款保险附加标准）,另一余额进50万以上欠稳定存款（无存款保险）
INSERT 
INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY2 
  (ACCT_NUM,
   BAL_TOTAL,
   CUST_ID,
   GL_ITEM_CODE,
   REAL_SCALE,
   ACCT_BAL_RMB,
   MATUR_DATE,
   REMAIN_TERM_CODE,
   REMAIN_TERM_CODE_QX,
   SIGN,
   SAFETY_FLAG,
   ROWNN,
   LEIJIA,
   FLAG,
   RN,
   OTHER_BAL,
   NORMAL_BAL,
   RNUMBER,
   ORG_NUM)
  SELECT 
   ACCT_NUM,
   BAL_TOTAL,
   CUST_ID,
   GL_ITEM_CODE,
   REAL_SCALE,
   ACCT_BAL_RMB,
   MATUR_DATE,
   REMAIN_TERM_CODE,
   REMAIN_TERM_CODE_QX,
   SIGN,
   SAFETY_FLAG,
   ROWNN,
   LEIJIA,
   FLAG,
   RN,
   OTHER_BAL,
   NORMAL_BAL,
   RNUMBER,
   ORG_NUM
    FROM (SELECT ACCT_NUM,
                 BAL_TOTAL,
                 CUST_ID,
                 GL_ITEM_CODE,
                 REAL_SCALE,
                 ACCT_BAL_RMB,
                 MATUR_DATE,
                 REMAIN_TERM_CODE,
                 REMAIN_TERM_CODE_QX,
                 SIGN,
                 SAFETY_FLAG,
                 ROWNN,
                 LEIJIA,
                 FLAG,
                 RN,
                 LEIJIA - 500000 OTHER_BAL,
                 ACCT_BAL_RMB - (LEIJIA - 500000) NORMAL_BAL,
                 ROW_NUMBER() OVER(PARTITION BY CUST_ID ORDER BY RN) AS RNUMBER,
                 ORG_NUM
            FROM (SELECT ACCT_NUM,
                         BAL_TOTAL,
                         CUST_ID,
                         GL_ITEM_CODE,
                         REAL_SCALE,
                         ACCT_BAL_RMB,
                         MATUR_DATE,
                         REMAIN_TERM_CODE,
                         REMAIN_TERM_CODE_QX,
                         SIGN,
                         SAFETY_FLAG,
                         ROWNN,
                         LEIJIA,
                         CASE
                           WHEN LEIJIA > 500000 THEN
                            '大于'
                           ELSE
                            '小于'
                         END FLAG,
                         ROW_NUMBER() OVER(PARTITION BY CUST_ID ORDER BY SIGN, MATUR_DATE, LEIJIA) AS RN, --按照保证金,存单质押,其他,到期日顺序排序
                         ORG_NUM
                    FROM (SELECT ACCT_NUM,
                                 BAL_TOTAL,
                                 CUST_ID,
                                 GL_ITEM_CODE,
                                 REAL_SCALE,
                                 ACCT_BAL_RMB,
                                 MATUR_DATE,
                                 REMAIN_TERM_CODE,
                                 REMAIN_TERM_CODE_QX,
                                 SIGN,
                                 SAFETY_FLAG,
                                 ROWNN,
                                 SUM(T.ACCT_BAL_RMB) OVER(PARTITION BY CUST_ID ORDER BY SIGN, MATUR_DATE, ACCT_BAL_RMB, ACCT_NUM) LEIJIA, --按照保证金,存单质押,其他,到期日进行余额累加
                                 ORG_NUM
                            FROM (SELECT 
                                   ACCT_NUM,
                                   BAL_TOTAL,
                                   CUST_ID,
                                   GL_ITEM_CODE,
                                   REAL_SCALE,
                                   ACCT_BAL_RMB,
                                   MATUR_DATE,
                                   REMAIN_TERM_CODE,
                                   REMAIN_TERM_CODE_QX,
                                   SIGN,
                                   SAFETY_FLAG,
                                   ROWNN,
                                   ORG_NUM
                                    FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY1
                                   WHERE SAFETY_FLAG = '002') T) K
                  ) T
           WHERE T.FLAG = '大于') T
   WHERE T.RNUMBER = 1;
 COMMIT;
--从大于50万数据剔除特殊处理数据,取特殊处理数据
INSERT 
INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY3 
  (ACCT_NUM,
   BAL_TOTAL,
   CUST_ID,
   GL_ITEM_CODE,
   REAL_SCALE,
   ACCT_BAL_RMB,
   MATUR_DATE,
   REMAIN_TERM_CODE,
   REMAIN_TERM_CODE_QX,
   SIGN,
   SAFETY_FLAG,
   ROWNN,
   DIFF,
   ORG_NUM)
  SELECT T1.ACCT_NUM,
         T1.BAL_TOTAL,
         T1.CUST_ID,
         T1.GL_ITEM_CODE,
         T1.REAL_SCALE,
         T1.ACCT_BAL_RMB, --正常存款保险
         T1.MATUR_DATE,
         T1.REMAIN_TERM_CODE,
         T1.REMAIN_TERM_CODE_QX,
         T1.SIGN,
         T1.SAFETY_FLAG,
         T1.ROWNN,
         'A' AS DIFF,
         ORG_NUM
    FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY1 T1
   WHERE T1.SAFETY_FLAG = '001' --001 50万以下存款保险部分
  UNION ALL
  SELECT T1.ACCT_NUM,
         T1.BAL_TOTAL,
         T1.CUST_ID,
         T1.GL_ITEM_CODE,
         T1.REAL_SCALE,
         T1.ACCT_BAL_RMB, --正常存款保险
         T1.MATUR_DATE,
         T1.REMAIN_TERM_CODE,
         T1.REMAIN_TERM_CODE_QX,
         T1.SIGN,
         T1.SAFETY_FLAG,
         T1.ROWNN,
         'B' AS DIFF,
         T1.ORG_NUM
    FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY1 T1
    LEFT JOIN PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY2 T2
      ON T1.ROWNN = T2.ROWNN
   WHERE T1.SAFETY_FLAG = '002' --  002 50万以上存款保险部分
     AND T2.ROWNN IS NULL
  UNION ALL
  SELECT ACCT_NUM,
         BAL_TOTAL,
         CUST_ID,
         GL_ITEM_CODE,
         REAL_SCALE,
         NORMAL_BAL AS ACCT_BAL_RMB, --50万以下存款保险部分
         MATUR_DATE,
         REMAIN_TERM_CODE,
         REMAIN_TERM_CODE_QX,
         SIGN,
         SAFETY_FLAG,
         ROWNN,
         'C' AS DIFF,
         ORG_NUM
    FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY2 T2
  UNION ALL
  SELECT ACCT_NUM,
         BAL_TOTAL,
         CUST_ID,
         GL_ITEM_CODE,
         REAL_SCALE,
         OTHER_BAL AS ACCT_BAL_RMB, --50万以上存款保险部分
         MATUR_DATE,
         REMAIN_TERM_CODE,
         REMAIN_TERM_CODE_QX,
         SIGN,
         SAFETY_FLAG,
         ROWNN,
         'D' AS DIFF,
         ORG_NUM
    FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY2 T2;

  COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取小微企业存款保险拆分明细中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --30日内到期  1对公代发工资,2保证金存款,3存单质押
    --存款按客户分组,50万以内稳定存款（不满足有效存款保险附加标准）,50万以上欠稳定存款（无存款保险）
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取小微企业存款保险拆分至G2501_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

  INSERT INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM,
            'G25_1_1.2.1.2.1.2.A.2014',
             SUM(A.ACCT_BAL_RMB) VAL
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY3 T
               WHERE T.DIFF IN ('A', 'C')
               AND (T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <=30)
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM
    UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
              'G25_1_1.2.1.2.1.4.A.2014',
             SUM(A.ACCT_BAL_RMB) VAL
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY3 T
               WHERE T.DIFF IN ('B', 'D')
               AND (T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <=30)
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM;
    COMMIT;

    -- 除以上3类账户   按客户分组

    INSERT INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
          SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM, --明细不能取机构,有可能客户在不同机构与数据,关联时卉产生重复数据,翻倍等
             'G25_1_1.2.1.2.1.3.A.2014' AS ITEM_NUM, ---          2.1.2.1.3欠稳定存款（有存款保险）
             SUM(CASE
                   WHEN 500000 - NVL(A.ACCT_BAL_RMB, 0) >= 0 THEN
                    A.ACCT_BAL_RMB
                   WHEN 500000 - NVL(A.ACCT_BAL_RMB, 0)  < 0 THEN
                    500000
                 END) AS LOAN_ACCT_BAL_RMB
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL T
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.FLAG_CODE = '02'
                 AND T.ACCT_BAL_RMB <> 0
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM

       UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.2.1.4.A.2014' AS ITEM_NUM, --          2.1.2.1.4欠稳定存款（无存款保险）
             SUM(CASE
                   WHEN (500000 - NVL(A.ACCT_BAL_RMB, 0) < 0) THEN
                    (NVL(A.ACCT_BAL_RMB, 0) - 500000)
                   ELSE
                    0
                 END) AS LOAN_ACCT_BAL_RMB
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_SMALL T
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.FLAG_CODE = '02'
                 AND T.ACCT_BAL_RMB <> 0
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取小微企业存款保险拆分至G2501_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ----------------------大中型 ----------------------
    --科目范围：201单位活期存款,202单位通知存款,205单位定期存款,206国库定期,218单位信用卡存款,22001发行单位大额存单,243应解汇款及临时存款,244开出汇票,25102单位保证金存款,
    --由于保证金不区分有无业务关系,只是需要30天内,以单独处理
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取大中型企业基础数据至TMP_DEPOSIT_WD_DIFF_BIG中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_BIG 
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
       T.REMAIN_TERM_CODE, --剩余期限代
       T.ACCT_NUM, --账号
       0 AS BAL_TOTAL,
       '01' AS FLAG_CODE
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T
       INNER JOIN (SELECT DISTINCT ACCT_NUM
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT
                    WHERE DATA_DATE = I_DATADATE
                      AND SIGN IN ('A', 'B', 'C', 'D')) T2 --1、对公代发工资,2保证金存款,3存单质押
          ON T.ACCT_NUM = T2.ACCT_NUM
       INNER JOIN (SELECT DISTINCT ACCT_NUM, REAL_SCALE --所有存款+206国库定期,219结构性存款,20504转股协议存款其他科目数据30天以内
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_SCALE
                    WHERE DATA_DATE = I_DATADATE) T1
          ON T.ACCT_NUM = T1.ACCT_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T1.REAL_SCALE = 'BM'
         AND T.REMAIN_TERM_CODE IN ('A', 'B', 'C'); --30日内
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_BIG 
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
       T.REMAIN_TERM_CODE, --剩余期限代
       T.ACCT_NUM, --账号
       0 AS BAL_TOTAL,
       '02' AS FLAG_CODE
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T
       INNER JOIN (SELECT DISTINCT ACCT_NUM, REAL_SCALE --所有存款+206国库定期,219结构性存款,20504转股协议存款其他科目数据30天以内
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_SCALE
                    WHERE DATA_DATE = I_DATADATE) T2
          ON T.ACCT_NUM = T2.ACCT_NUM
        LEFT JOIN (SELECT DISTINCT ACCT_NUM
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT
                    WHERE DATA_DATE = I_DATADATE
                      AND SIGN IN ('A', 'B', 'C', 'D')) T3 --1对公代发工资,2保证金存款,3存单质押
          ON T.ACCT_NUM = T3.ACCT_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T3.ACCT_NUM IS NULL --去掉对公代发工资,保证金 ,存单质押,在上面已经有了
         AND T2.REAL_SCALE = 'BM'; --客户规模大中型

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取大中型企业基础数据至TMP_DEPOSIT_WD_DIFF_BIG中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取大中型企业有业务关系划分至TMP_DEPOSIT_WD_ACCT_BRO中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /*有无业务关系划分：
    1,机构类客户
    2,保证金
    3,有贷款的客户
    4、对公代发工资户
    5、存单质押
    6、基本户
    为有业务关系的客户,其它的为无业务关系*/
    /* CUST_NO in ('2999999999', '2999999998') AND
    SUBSTR(A.LIAB_ITEM, 0, 3) IN ('243', '244') 这种都是无业务关系,目前数据都是在无业务关系里面*/
    ---有业务关系可能有交叉重复数据,需要去重复
    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_BRO 
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
       SIGN --客户标识
       )
      SELECT 
       DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ACCT_TYP, --账户类型
       ACCT_CUR, --账户币种
       ACCT_BAL, --账户余额
       ACCT_BAL_RMB, --账户余额_人民币
       FLAG, --数据标识
       GL_ITEM_CODE, --科目号
       CUST_ID, --客户号
       T.ACCT_NAM, --账户名称
       T.MATUR_DATE, --到期日
       REMAIN_TERM_CODE, --剩余期限代码
       ACCT_NUM, --账号
       SIGN
        FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT T
       WHERE T.DATA_DATE = I_DATADATE
         AND SIGN IN ('A', 'B','C') --代发工资,保证金,存单质押 上面已取过,直接沿用
      UNION ALL
      SELECT 
       DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ACCT_TYP, --账户类型
       ACCT_CUR, --账户币种
       ACCT_BAL, --账户余额
       ACCT_BAL_RMB, --账户余额_人民币
       FLAG, --数据标识
       GL_ITEM_CODE, --科目号
       CUST_ID, --客户号
       T.ACCT_NAM, --账户名称
       T.MATUR_DATE, --到期日
       REMAIN_TERM_CODE, --剩余期限代码
       ACCT_NUM, --账号
       'C' AS SIGN
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T
        WHERE T.DATA_DATE = I_DATADATE
         AND BUS_REL = 'Y' --机构类客户用是否业务关系判断
      UNION ALL
      SELECT 
       DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ACCT_TYP, --账户类型
       ACCT_CUR, --账户币种
       ACCT_BAL, --账户余额
       ACCT_BAL_RMB, --账户余额_人民币
       FLAG, --数据标识
       GL_ITEM_CODE, --科目号
       T.CUST_ID, --客户号
       T.ACCT_NAM, --账户名称
       T.MATUR_DATE, --到期日
       REMAIN_TERM_CODE, --剩余期限代码
       ACCT_NUM, --账号
       'D' AS SIGN
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T
       INNER JOIN (SELECT CUST_ID, COUNT(*)
                     FROM PM_RSDATA.SMTMODS_L_ACCT_LOAN T
                    WHERE T.DATA_DATE = I_DATADATE
                      AND T.LOAN_ACCT_BAL <> 0
                    GROUP BY CUST_ID) T1
          ON T.CUST_ID = T1.CUST_ID
       WHERE T.DATA_DATE = I_DATADATE
       UNION ALL
       SELECT 
       DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ACCT_TYP, --账户类型
       ACCT_CUR, --账户币种
       ACCT_BAL, --账户余额
       ACCT_BAL_RMB, --账户余额_人民币
       FLAG, --数据标识
       GL_ITEM_CODE, --科目号
       T.CUST_ID, --客户号
       T.ACCT_NAM, --账户名称
       T.MATUR_DATE, --到期日
       REMAIN_TERM_CODE, --剩余期限代码
       T.ACCT_NUM, --账号
       'E' AS SIGN
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T
       INNER JOIN (SELECT  DISTINCT T.ACCT_NUM
                     FROM PM_RSDATA.SMTMODS_L_ACCT_DEPOSIT T
                    WHERE T.DATA_DATE = I_DATADATE
                      AND T.PBOC_ACCT_NATURE_CD = '0011'
                      AND T.ACCT_BALANCE<>0) T1 --基本户
          ON T.ACCT_NUM = T1.ACCT_NUM
       WHERE T.DATA_DATE = I_DATADATE;

       COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取大中型企业有业务关系划分至TMP_DEPOSIT_WD_ACCT_BRO中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取大中型企业存款保险拆分至G2501_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --存款按客户分组,50万以内稳定存款（有存款保险）,50万以上欠稳定存款（无存款保险）
    --2.1.2.2.2有业务关系且有存款保险（不满足有效存款保险附加标准）
    INSERT INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.2.2.2.A.2014',
             sum(CASE
                   WHEN A.ACCT_BAL_RMB - 500000 <= 0 THEN
                    A.ACCT_BAL_RMB
                   when A.ACCT_BAL_RMB - 500000 > 0 then
                    500000
                 end) val
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_BIG T
               INNER JOIN (SELECT DISTINCT ACCT_NUM
                            FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_BRO
                           WHERE DATA_DATE = I_DATADATE) T1 --有业务关系
                  ON T.ACCT_NUM = T1.ACCT_NUM
               WHERE T.DATA_DATE = I_DATADATE
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) a
               GROUP BY ORG_NUM
      union all
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.2.2.3.A.2014',
             sum(case
                   when A.ACCT_BAL_RMB - 500000 > 0 then
                    A.ACCT_BAL_RMB - 500000
                 end) val
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_BIG T
               INNER JOIN (SELECT DISTINCT ACCT_NUM
                            FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_BRO
                           WHERE DATA_DATE = I_DATADATE) T1 --有业务关系
                  ON T.ACCT_NUM = T1.ACCT_NUM
               WHERE T.DATA_DATE = I_DATADATE
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM;


    COMMIT;
    --2.1.2.2.3有业务关系且无存款保险
    INSERT INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )

      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.2.2.4.A.2014',
             sum(CASE
                   WHEN A.ACCT_BAL_RMB - 500000 <= 0 THEN
                    A.ACCT_BAL_RMB
                   when A.ACCT_BAL_RMB - 500000 > 0 then
                    500000
                 end) val
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_BIG T
                LEFT JOIN (SELECT DISTINCT ACCT_NUM
                            FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_BRO
                           WHERE DATA_DATE = I_DATADATE) T1
                  ON T.ACCT_NUM = T1.ACCT_NUM
               WHERE T.DATA_DATE = I_DATADATE
                 AND T1.ACCT_NUM IS NULL --无业务关系
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
               GROUP BY ORG_NUM
      union all
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.2.2.5.A.2014',
             sum(case
                   when A.ACCT_BAL_RMB - 500000 > 0 then
                    A.ACCT_BAL_RMB - 500000
                 end) val
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_BIG T
                LEFT JOIN (SELECT DISTINCT ACCT_NUM
                            FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_BRO
                           WHERE DATA_DATE = I_DATADATE) T1
                  ON T.ACCT_NUM = T1.ACCT_NUM
               WHERE T.DATA_DATE = I_DATADATE
                 AND T1.ACCT_NUM IS NULL --无业务关系
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
               GROUP BY ORG_NUM;

    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取大中型企业存款保险拆分至G2501_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ---------------------------------------------按存款保险拆分---------------------------------------------


    ---------------------------------------------以上存款---------------------------------------------
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取个人贷款至ID_G25_ITEMDATA_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --2.2.2完全正常履约的协议性现金流入
    ---2.2.2.1零售客户   个人贷款=个人经营性贷款+个人消费贷款+信用卡部分
    INSERT 
    INTO PM_RSDATA.CBRC_ID_G25_ITEMDATA_NGI 
      (ORG_NUM,
       CORP_SCALE,
       NEXT_YS,
       NEXT_WEEK,
       NEXT_MONTH,
       NEXT_QUARTER,
       NEXT_YEAR,
       NEXT_FIVE,
       NEXT_TEN,
       MORE_TEN,
       YQ,
       YQ_90,
       BAL,
       FLAG)
    ----------------------------个人经营性贷款
      SELECT 
       T.ORG_NUM AS ORG_NUM,
       'P' AS CORP_SCALE,
       SUM(CASE--ADD BY DJH 20220518如果逾期天数是空值或者0,但是实际到期日小于等于当前日期数据,放在次日
             WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') or (T1.ACCT_STATUS_1104='10'AND T1.PMT_REMAIN_TERM_C <=0) THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS NEXT_DAY,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 7 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS NEXT_WEEK,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 8 AND 30 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS NEXT_MONTH,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS NEXT_QUARTER,

       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 360 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS NEXT_YEAR,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 360 * 5 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS NEXT_FIVE,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN (360 * 5 + 1) AND 360 * 10 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS NEXT_TEN,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 10 AND T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS MORE_TEN,
       SUM(CASE
             WHEN T1.IDENTITY_CODE = '2' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS YQ,
       SUM(CASE
             WHEN T1.IDENTITY_CODE = '2' AND PMT_REMAIN_TERM_C <= 90 --逾期小于90天（<-90）即欠本欠息小于90天
              THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS YQ_90,
       SUM(T1.NEXT_PAYMENT * T3.CCY_RATE) BAL,
       'LN_01' AS FLAG
        FROM PM_RSDATA.CBRC_FDM_LNAC T
       INNER JOIN PM_RSDATA.CBRC_FDM_LNAC_PMT T1
          ON T.LOAN_NUM = T1.LOAN_NUM
         AND T.DATA_DATE = T1.DATA_DATE
       INNER JOIN PM_RSDATA.SMTMODS_L_CUST_P T2
          ON T.CUST_ID = T2.CUST_ID
         AND T.DATA_DATE = T2.DATA_DATE
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T3
          ON T3.DATA_DATE = I_DATADATE
         AND T3.BASIC_CCY = T1.CURR_CD --基准币种
         AND T3.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND (T.ACCT_TYP LIKE '0102%' or T.ACCT_TYP like '04%') --0102 个人经营性    04个体工商户贸易融资  zhoujingkun 20210412
         AND T.LOAN_GRADE_CD IN ('1', '2') --取正常,关注
       GROUP BY T.ORG_NUM
      UNION ALL
      ----------------------------个人消费贷款
      SELECT 
       T.ORG_NUM AS ORG_NUM,
       'P' AS CORP_SCALE,
       SUM(CASE--ADD BY DJH 20220518如果逾期天数是空值或者0,但是实际到期日小于等于当前日期数据,放在次日
             WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') or (T1.ACCT_STATUS_1104='10'AND T1.PMT_REMAIN_TERM_C <=0) THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS NEXT_DAY,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 7 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS NEXT_WEEK,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 8 AND 30 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS NEXT_MONTH,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS NEXT_QUARTER,

       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 360 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS NEXT_YEAR,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 360 * 5 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS NEXT_FIVE,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN (360 * 5 + 1) AND 360 * 10 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS NEXT_TEN,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 10 AND T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS MORE_TEN,
       SUM(CASE
             WHEN T1.IDENTITY_CODE = '2' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS YQ,
       SUM(CASE
             WHEN T1.IDENTITY_CODE = '2' AND PMT_REMAIN_TERM_C <= 90 --逾期小于90天（<-90）即欠本欠息小于90天
              THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS YQ_90,
       SUM(T1.NEXT_PAYMENT * T3.CCY_RATE) BAL,
       'LN_02' AS FLAG
        FROM PM_RSDATA.CBRC_FDM_LNAC T
       INNER JOIN PM_RSDATA.CBRC_FDM_LNAC_PMT T1
          ON T.LOAN_NUM = T1.LOAN_NUM
         AND T.DATA_DATE = T1.DATA_DATE
       INNER JOIN PM_RSDATA.SMTMODS_L_CUST_P T2
          ON T.CUST_ID = T2.CUST_ID
         AND T.DATA_DATE = T2.DATA_DATE
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T3
          ON T3.DATA_DATE = I_DATADATE
         AND T3.BASIC_CCY = T1.CURR_CD --基准币种
         AND T3.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(T.ACCT_TYP, 1, 4) in ('0199', '0103', '0101') --0103 个人消费  0199 其他   0101房地产贷款;
         AND T.LOAN_GRADE_CD IN ('1', '2') --五级分类为非不良（正常,关注）
       GROUP BY T.ORG_NUM;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取个人贷款至ID_G25_ITEMDATA_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取大中企业贷款至ID_G25_ITEMDATA_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --2.2.2.3大中型企业   2.2.2.2小企业
    INSERT 
    INTO PM_RSDATA.CBRC_ID_G25_ITEMDATA_NGI 
      (ORG_NUM,
       CORP_SCALE,
       NEXT_YS,
       NEXT_WEEK,
       NEXT_MONTH,
       NEXT_QUARTER,
       NEXT_YEAR,
       NEXT_FIVE,
       NEXT_TEN,
       MORE_TEN,
       YQ,
       YQ_90,
       BAL,
       FLAG)
    ----------------------------大中企业贷款
      SELECT 
       T.ORG_NUM, --ADD BY DJH 20220528由于 码值为z和9都是原来为空值,赋予数值9
       CASE
         WHEN A.CORP_SCALE = 'Z' OR A.CORP_SCALE IS NULL THEN
          '9'
         ELSE
          A.CORP_SCALE
       END AS CORP_SCALE,
       SUM(CASE--ADD BY DJH 20220518如果逾期天数是空值或者0,但是实际到期日小于等于当前日期数据,放在次日
             WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') or (T1.ACCT_STATUS_1104='10'AND T1.PMT_REMAIN_TERM_C <=0) THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS NEXT_DAY,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 7 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS NEXT_WEEK,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 8 AND 30 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS NEXT_MONTH,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS NEXT_QUARTER,

       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 360 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS NEXT_YEAR,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 360 * 5 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS NEXT_FIVE,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN (360 * 5 + 1) AND 360 * 10 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS NEXT_TEN,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 10 AND T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS MORE_TEN,
       SUM(CASE
             WHEN T1.IDENTITY_CODE = '2' THEN --DJH20210804参考G0102逾期天数计算方法
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS YQ,
       SUM(CASE
             WHEN T1.IDENTITY_CODE = '2' AND PMT_REMAIN_TERM_C <= 90 --逾期小于90天（<-90）即欠本欠息小于90天
              THEN
              T1.NEXT_PAYMENT * T3.CCY_RATE
             ELSE
              0
           END) AS YQ_90,
       SUM(T1.NEXT_PAYMENT * T3.CCY_RATE) BAL,
       'LN_04' AS FLAG
        FROM PM_RSDATA.CBRC_FDM_LNAC T
       INNER JOIN PM_RSDATA.CBRC_FDM_LNAC_PMT T1
          ON T.LOAN_NUM = T1.LOAN_NUM
         AND T.DATA_DATE = T1.DATA_DATE
       INNER JOIN PM_RSDATA.SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T3
          ON T3.DATA_DATE = I_DATADATE
         AND T3.BASIC_CCY = T1.CURR_CD --基准币种
         AND T3.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
            --AND A.CORP_SCALE IN ('B', 'M', 'S', 'T','9') --大、中、小、微、其他
         AND SUBSTR(T.ITEM_CD,1,6) NOT IN ('130102'/*, '12904'*/, '130105'/*, '12907'*/) --G25去掉转帖现数据129060101面值,来源表验证是129060101面值
         AND T.LOAN_GRADE_CD IN ('1', '2') --五级分类为非不良（正常,关注）
       GROUP BY CASE
                  WHEN A.CORP_SCALE = 'Z' OR A.CORP_SCALE IS NULL THEN
                   '9'
                  ELSE
                   A.CORP_SCALE
                END,
                T.ORG_NUM;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取大中企业贷款至ID_G25_ITEMDATA_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取表外敞口至FDM_LNAC_PMT_BW_G2501中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --2.1.4.10未提取的不可无条件撤销的信用便利和流动性便利
    --G25涉及表外逻辑
    --由于余额,保证金,担保物币种均不一样,因此折币后处理
    INSERT 
    INTO PM_RSDATA.CBRC_FDM_LNAC_PMT_BW_G2501 
      (DATA_DATE, --01数据日期
       ACCT_NUM, --02表外账号
       CURR_CD, --03币种
       ITEM_CD, --04科目号
       ORG_NUM, --05机构
       ACTUAL_MATURITY_DT, --06实际到期日期
       ACCT_TYP, --10账户类型
       NEXT_PAYMENT, --13下次付款额
       PMT_REMAIN_TERM_C, --16剩余期限
       PMT_REMAIN_TERM_C_MULT, --17单位
       LOAN_GRADE_CD, --18五级分类状态
       IDENTITY_CODE --19标识符
       )
      SELECT 
       T1.DATA_DATE,
       T1.ACCT_NUM,
       T1.CURR_CD,
       T1.GL_ITEM_CODE,
       T1.ORG_NUM,
       MATURITY_DT AS ACTUAL_MATURITY_DT,
       T1.ACCT_TYP, --贷款承诺类型511无条件撤销承诺521不可撤销承诺-循环包销便利522不可撤销承诺-票据发行便利523不可撤销承诺-其他531有条件撤销承诺
       CASE
         WHEN NVL(T1.BALANCE * T2.CCY_RATE, 0) -
              NVL(T1.SECURITY_AMT * T3.CCY_RATE, 0) - NVL(TM.DEP_AMT, 0) -
              NVL(TM.COLL_BILL_AMOUNT, 0) > 0 THEN
          NVL(T1.BALANCE * T2.CCY_RATE, 0) -
          NVL(T1.SECURITY_AMT * T3.CCY_RATE, 0) - NVL(TM.DEP_AMT, 0) -
          NVL(TM.COLL_BILL_AMOUNT, 0)
         ELSE
          0
       END AS NEXT_PAYMENT, --612保函、601-开出信用证 扣除保证金、本行存单、国债敞口部分
       T1.MATURITY_DT - D_DATADATE_CCY PMT_REMAIN_TERM_C,
       'D' PMT_REMAIN_TERM_C_MULT,
       T1.LOAN_GRADE_CD,
       '1' AS IDENTITY_CODE
        FROM PM_RSDATA.SMTMODS_L_ACCT_OBS_LOAN T1
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
          ON T2.DATA_DATE = I_DATADATE
         AND T2.BASIC_CCY = T1.CURR_CD --表外余额折币
         AND T2.FORWARD_CCY = 'CNY'
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T3
          ON T3.DATA_DATE = I_DATADATE
         AND T3.BASIC_CCY = T1.SECURITY_CURR --表外保证金折币
         AND T3.FORWARD_CCY = 'CNY'
        LEFT JOIN (SELECT T2.CONTRACT_NUM,
                          sum(nvl(T4.DEP_AMT * T6.CCY_RATE, 0)) as DEP_AMT,
                          sum(NVL(T5.COLL_BILL_AMOUNT * T6.CCY_RATE, 0)) as COLL_BILL_AMOUNT
                     FROM PM_RSDATA.SMTMODS_L_AGRE_GUA_RELATION T2

                     LEFT JOIN PM_RSDATA.SMTMODS_L_AGRE_GUARANTEE_RELATION T3
                       ON T2.GUAR_CONTRACT_NUM = T3.GUAR_CONTRACT_NUM
                      AND T3.DATA_DATE = I_DATADATE
                     LEFT JOIN PM_RSDATA.SMTMODS_L_AGRE_GUARANTY_INFO T4
                       ON T3.GUARANTEE_SERIAL_NUM = T4.GUARANTEE_SERIAL_NUM
                      AND T4.DATA_DATE = I_DATADATE
                      AND T4.COLL_TYP = 'A0201' --  是本行存单
                     LEFT JOIN PM_RSDATA.SMTMODS_L_AGRE_GUARANTY_INFO T5
                       ON T3.GUARANTEE_SERIAL_NUM = T5.GUARANTEE_SERIAL_NUM
                      AND T5.DATA_DATE = I_DATADATE
                      AND T5.COLL_TYP IN ('A0602', 'A0603')
                     LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T6
                       ON T6.DATA_DATE = I_DATADATE
                      AND T6.BASIC_CCY = T3.CURR_CD --担保物折币
                      AND T6.FORWARD_CCY = 'CNY'
                    where T2.DATA_DATE = I_DATADATE
                    GROUP BY T2.CONTRACT_NUM) TM --押品类型为 A0602一级国家及地区的国债 A0603二级国家及地区的国债
          ON T1.ACCT_NUM = TM.CONTRACT_NUM
       WHERE T1.DATA_DATE = I_DATADATE
         AND (T1.GL_ITEM_CODE LIKE '7010%' OR T1.GL_ITEM_CODE LIKE '7040%');
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取表外敞口至FDM_LNAC_PMT_BW_G2501中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取表外零售客户和小企业数据至FDM_CUST_LNAC_INFO中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /* 1、602 承兑汇票 正常表外30以内+所有逾期  逾期与G21一样都取
    2、未使用额度 30天内有效的未使用额度,不需要限制到期日所有都取
    3、60302不可撤销贷款承诺*/
    --2.1.4.10.1零售客户和小企业
    INSERT 
    INTO PM_RSDATA.CBRC_FDM_CUST_LNAC_INFO 
      (DATA_DATE, CORP_SCALE, ACCT_NUM, ORG_NUM, BAL_1_30, FLAG)
      SELECT 
       T1.DATA_DATE,
       T1.CORP_SCALE,
       T1.ACCT_NUM,
       CASE WHEN  T1.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T1.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T1.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T1.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T1.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T1.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T1.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T1.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T1.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T1.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       SUM(T1.NEXT_PAYMENT * T2.CCY_RATE) BAL_1_30,
       '01' AS FLAG
        FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_BW T1
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
          ON T2.DATA_DATE = I_DATADATE
         AND T2.BASIC_CCY = T1.CURR_CD --基准币种N
         AND T2.FORWARD_CCY = 'CNY'
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD in ('70200101','70200201', '70300201') --602承兑汇票
         AND T1.PMT_REMAIN_TERM_C >= 1
         AND T1.PMT_REMAIN_TERM_C <= 30
         AND T1.CORP_SCALE IN ('P', 'S', 'T') --零售  小型  微型
       GROUP BY T1.DATA_DATE,CASE WHEN  T1.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T1.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T1.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T1.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T1.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T1.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T1.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T1.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T1.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T1.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END,
              T1.CORP_SCALE, T1.ACCT_NUM --折算币种
      UNION ALL
      SELECT 
       T1.DATA_DATE,
       T1.CORP_SCALE,
       T1.ACCT_NUM,
       CASE WHEN  T1.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T1.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T1.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T1.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T1.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T1.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T1.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T1.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T1.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T1.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       SUM(T1.NEXT_PAYMENT * T2.CCY_RATE) BAL_1_30,
       '01' AS FLAG
        FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_BW T1
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
          ON T2.DATA_DATE = I_DATADATE
         AND T2.BASIC_CCY = T1.CURR_CD --基准币种N
         AND T2.FORWARD_CCY = 'CNY'
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD in ('70200101','70200201', '70300201')
         AND T1.PMT_REMAIN_TERM_C <= 0
         AND T1.CORP_SCALE IN ('P', 'S', 'T') --零售  小型  微型
       GROUP BY T1.DATA_DATE,CASE WHEN  T1.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T1.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T1.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T1.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T1.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T1.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T1.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T1.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T1.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T1.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END, T1.CORP_SCALE, T1.ACCT_NUM --折算币种
      UNION ALL
      SELECT 
       T1.DATA_DATE,
       T1.CORP_SCALE,
       T1.ACCT_NUM,
       CASE WHEN  T1.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T1.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T1.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T1.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T1.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T1.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T1.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T1.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T1.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T1.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       SUM(T1.NEXT_PAYMENT * T2.CCY_RATE) BAL_1_30,
       '01' AS FLAG
        FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_BW T1
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
          ON T2.DATA_DATE = I_DATADATE
         AND T2.BASIC_CCY = T1.CURR_CD --基准币种N
         AND T2.FORWARD_CCY = 'CNY'
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD = '60302_G25' --未使用额度
         AND T1.CORP_SCALE IN ('P', 'S', 'T') --零售  小型  微型
       GROUP BY T1.DATA_DATE,CASE WHEN  T1.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T1.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T1.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T1.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T1.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T1.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T1.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T1.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T1.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T1.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END, T1.CORP_SCALE, T1.ACCT_NUM; --折算币种
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取表外零售客户和小企业数据至FDM_CUST_LNAC_INFO中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取大中型企业数据至FDM_CUST_LNAC_INFO中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --2.1.4.10.2大中型企业
    --2.1.4.10.2.1信用便利
    INSERT 
    INTO PM_RSDATA.CBRC_FDM_CUST_LNAC_INFO 
      (DATA_DATE, CORP_SCALE, ACCT_NUM, ORG_NUM, BAL_1_30, FLAG)
      SELECT 
       T1.DATA_DATE,
       T1.CORP_SCALE,
       T1.ACCT_NUM,
       CASE WHEN  T1.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T1.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T1.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T1.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T1.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T1.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T1.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T1.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T1.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T1.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       SUM(T1.NEXT_PAYMENT * T2.CCY_RATE) BAL_1_30,
       '02' AS FLAG
        FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_BW T1
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
          ON T2.DATA_DATE = I_DATADATE
         AND T2.BASIC_CCY = T1.CURR_CD --基准币种N
         AND T2.FORWARD_CCY = 'CNY'
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD in ('70200101','70200201', '70300201')
         AND T1.PMT_REMAIN_TERM_C >= 1
         AND T1.PMT_REMAIN_TERM_C <= 30
         AND T1.CORP_SCALE IN ('B', 'M', '9') --大型   中型
       GROUP BY T1.DATA_DATE,CASE WHEN  T1.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T1.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T1.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T1.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T1.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T1.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T1.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T1.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T1.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T1.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END, T1.CORP_SCALE, T1.ACCT_NUM --折算币种
      UNION ALL
      SELECT 
       T1.DATA_DATE,
       T1.CORP_SCALE,
       T1.ACCT_NUM,
       CASE WHEN  T1.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T1.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T1.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T1.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T1.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T1.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T1.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T1.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T1.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T1.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       SUM(T1.NEXT_PAYMENT * T2.CCY_RATE) BAL_1_30,
       '02' AS FLAG
        FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_BW T1
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
          ON T2.DATA_DATE = I_DATADATE
         AND T2.BASIC_CCY = T1.CURR_CD --基准币种N
         AND T2.FORWARD_CCY = 'CNY'
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD in ('70200101','70200201', '70300201')
         AND T1.PMT_REMAIN_TERM_C <= 0
         AND T1.CORP_SCALE IN ('B', 'M', '9') --大型   中型
       GROUP BY T1.DATA_DATE,CASE WHEN  T1.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T1.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T1.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T1.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T1.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T1.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T1.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T1.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T1.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T1.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END
             , T1.CORP_SCALE, T1.ACCT_NUM --折算币种
      UNION ALL
      SELECT 
       T1.DATA_DATE,
       T1.CORP_SCALE,
       T1.ACCT_NUM,
       CASE WHEN  T1.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T1.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T1.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T1.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T1.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T1.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T1.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T1.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T1.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T1.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       SUM(T1.NEXT_PAYMENT * T2.CCY_RATE) BAL_1_30,
       '02' AS FLAG
        FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_BW T1
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
          ON T2.DATA_DATE = I_DATADATE
         AND T2.BASIC_CCY = T1.CURR_CD --基准币种N
         AND T2.FORWARD_CCY = 'CNY'
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD = '60302_G25'
         AND T1.CORP_SCALE IN ('B', 'M', '9') --大型   中型
       GROUP BY T1.DATA_DATE,CASE WHEN  T1.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T1.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T1.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T1.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T1.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T1.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T1.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T1.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T1.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T1.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END
             , T1.CORP_SCALE, T1.ACCT_NUM; --折算币种
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取大中型企业数据至FDM_CUST_LNAC_INFO中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取表外其他或有融资义务数据至FDM_CUST_LNAC_INFO中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --603 60301可撤销贷款承诺、60303商票   612保函、601-开出信用证  所有数据,不限制期限全放进去
    --2.1.5其他或有融资义务
    --2.1.5.1无条件可撤销的信用及流动性便利
    INSERT 
    INTO PM_RSDATA.CBRC_FDM_CUST_LNAC_INFO 
      (DATA_DATE, CORP_SCALE, ACCT_NUM, ORG_NUM, BAL_1_30, FLAG)
      SELECT 
       T1.DATA_DATE,
       T1.CORP_SCALE,
       T1.ACCT_NUM,
       CASE WHEN  T1.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T1.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T1.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T1.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T1.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T1.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T1.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T1.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T1.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T1.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       SUM(T1.NEXT_PAYMENT * T2.CCY_RATE) BAL_1_30,
       '03' AS FLAG
        FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_BW T1
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
          ON T2.DATA_DATE = I_DATADATE
         AND T2.BASIC_CCY = T1.CURR_CD --基准币种N
         AND T2.FORWARD_CCY = 'CNY'
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD = '70300101'
         AND T1.IDENTITY_CODE IN ('3', '4')
       GROUP BY T1.DATA_DATE,
                CASE WHEN  T1.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T1.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T1.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T1.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T1.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T1.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T1.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T1.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T1.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T1.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END,
                T1.CORP_SCALE,
                T1.ACCT_NUM
      --60303商票保贴从总账取数
      UNION ALL
      SELECT 
       A.DATA_DATE,
       '' AS CORP_SCALE,
       '' AS ACCT_NUM,
       CASE WHEN  A.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  A.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  A.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  A.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  A.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  A.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  A.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  A.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  A.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  A.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       SUM(A.CREDIT_BAL * B.CCY_RATE),
       '03' AS FLAG
        FROM  PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '70300301'
         AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
         AND ORG_NUM NOT LIKE '%0000'
         AND ORG_NUM NOT IN (/*'510000',*/ --磐石吉银村镇银行
                             '222222', --东盛除双阳汇总
                             '333333', --新双阳
                             '444444', --净月潭除双阳
                             '555555') --长春分行（除双阳、榆树、农安）
       GROUP BY A.DATA_DATE,CASE WHEN  A.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  A.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  A.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  A.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  A.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  A.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  A.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  A.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  A.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  A.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END
      UNION ALL
      --2.1.5.2保函
      SELECT 
       T1.DATA_DATE,
       '' AS CORP_SCALE,
       T1.ACCT_NUM,
       CASE WHEN  T1.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T1.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T1.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T1.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T1.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T1.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T1.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T1.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T1.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T1.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       SUM(T1.NEXT_PAYMENT * T2.CCY_RATE) BAL_1_30,
       '04' AS FLAG
        FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_BW_G2501 T1
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
          ON T2.DATA_DATE = I_DATADATE
         AND T2.BASIC_CCY = T1.CURR_CD --基准币种N
         AND T2.FORWARD_CCY = 'CNY'
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD like '7040%'
       GROUP BY T1.DATA_DATE,CASE WHEN  T1.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T1.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T1.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T1.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T1.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T1.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T1.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T1.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T1.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T1.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END, T1.ACCT_NUM --折算币种
      UNION ALL
      --2.1.5.3信用证
      SELECT 
       T1.DATA_DATE,
       '' AS CORP_SCALE,
       T1.ACCT_NUM,
       CASE WHEN  T1.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T1.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T1.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T1.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T1.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T1.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T1.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T1.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T1.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T1.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       SUM(T1.NEXT_PAYMENT * T2.CCY_RATE) BAL_1_30,
       '05' AS FLAG
        FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_BW_G2501 T1
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
          ON T2.DATA_DATE = I_DATADATE
         AND T2.BASIC_CCY = T1.CURR_CD --基准币种N
         AND T2.FORWARD_CCY = 'CNY'
       WHERE T1.DATA_DATE = I_DATADATE
        ---- AND T1.ITEM_CD  =  '7010'
         AND T1.ITEM_CD  LIKE  '7010%'
       GROUP BY T1.DATA_DATE,CASE WHEN  T1.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T1.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T1.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T1.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T1.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T1.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T1.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T1.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T1.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T1.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END, T1.ACCT_NUM; --折算币种
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取表外其他或有融资义务数据至FDM_CUST_LNAC_INFO中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取2.2.2完全正常履约协议性现金流入至G2501_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --贷款
    --2.2.2完全正常履约协议性现金流入
    INSERT 
    INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    --2.2.2.1零售客户
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'G25_1_1_2.2.2.1.A.2012' ITEM_NUM, --折算前
       SUM(T.NEXT_YS + T.NEXT_WEEK + T.NEXT_MONTH) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G25_ITEMDATA_NGI T
       WHERE T.FLAG IN ('LN_01', 'LN_02')
       GROUP BY ORG_NUM
      ----------------------------信用卡部分
      --modiy by djh 20241210 去掉此处填报逻辑,文博确认不填报此处
      /*UNION ALL
      --modiy by djh 20241210 信用卡规则修改信用卡正常部分 G2501不算逾期90天内数据
      SELECT \*+PARALLEL(T,4)*\
       I_DATADATE,
       '009803',
       'G25_1_1_2.2.2.1.A.2012' AS ITEM_NUM,
       sum(T.DEBIT_BAL)
        FROM FDM_LNAC_GL T --信用卡
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_CD='1.6.A'*/
      UNION ALL
      --2.2.2.2小企业   （小、微）
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'G25_1_1_2.2.2.2.A.2012' ITEM_NUM,
       SUM(T.NEXT_YS + T.NEXT_WEEK + T.NEXT_MONTH) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G25_ITEMDATA_NGI T
       WHERE T.FLAG = 'LN_04'
         AND T.CORP_SCALE IN ('S', 'T') --小  微
       GROUP BY ORG_NUM
      UNION ALL
      --2.2.2.3大中企业  （大、中）
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'G25_1_1_2.2.2.3.A.2012' ITEM_NUM,
       SUM(T.NEXT_YS + T.NEXT_WEEK + T.NEXT_MONTH) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G25_ITEMDATA_NGI T
       WHERE T.FLAG = 'LN_04'
         AND T.CORP_SCALE IN ('B', 'M', '9')
       GROUP BY ORG_NUM; --大、中
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取2.2.2完全正常履约协议性现金流入至G2501_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取2.1.4.10未提取的不可无条件撤销的信用便利和流动性便利至G2501_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --表外 1
    --2.1.4.10未提取的不可无条件撤销的信用便利和流动性便利
    --2.1.4.10.1零售客户和小企业
    INSERT 
    INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'G25_1_1.2.1.4.10.1.A.2014' ITEM_NUM, --折算前
       SUM(T.BAL_1_30) AS CUR_BAL
        FROM PM_RSDATA.CBRC_FDM_CUST_LNAC_INFO T
       WHERE T.FLAG = '01'
       GROUP BY ORG_NUM;
    /* UNION ALL --信用卡未使用额度  取数逻辑不对暂时不取
    SELECT I_DATADATE AS DATA_DATE,
           '009803',
           'G25_1_1.2.1.4.10.1.A.2014' ITEM_NUM, --折算前
           SUM(NVL(CRED_LIMIT, 0) + NVL(TEMP_LIMIT, 0)
               +NVL(MP_BAL, 0)) - SUM(NVL(DEBIT_BAL, 0))
      FROM DATACORE.CUP_ACCT_ALL T1
      LEFT JOIN (SELECT SUM(DEBIT_BAL) AS DEBIT_BAL
                   FROM FDM_LNAC_GL
                  WHERE DATA_DATE = I_DATADATE
                    AND (GL_ACCOUNT LIKE '13604%' OR
                        GL_ACCOUNT LIKE '12203%')) T2 ON 1 = 1
     WHERE T1.ODS_DATA_DATE <= I_DATADATE;*/
    COMMIT;
    --2.1.4.10.2大中型企业
    --2.1.4.10.2.1信用便利
    INSERT 
    INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'G25_1_1.2.1.4.10.2.1.A.2014' ITEM_NUM, --折算前
       SUM(T.BAL_1_30) AS CUR_BAL
        FROM PM_RSDATA.CBRC_FDM_CUST_LNAC_INFO T
       WHERE T.FLAG = '02'
       GROUP BY ORG_NUM;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取2.1.4.10未提取的不可无条件撤销的信用便利和流动性便利至G2501_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取2.1.5其他或有融资义务至G2501_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --表外 2
    --2.1.5其他或有融资义务
    --2.1.5.1无条件可撤销的信用及流动性便利

    INSERT 
    INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'G25_1_1.2.1.5.1.A.2014' ITEM_NUM, --折算前
       SUM(T.BAL_1_30) AS CUR_BAL
        FROM PM_RSDATA.CBRC_FDM_CUST_LNAC_INFO T
       WHERE T.FLAG = '03'
       GROUP BY ORG_NUM;
    COMMIT;

    --2.1.5.2保函
    INSERT 
    INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'G25_1_1.2.1.5.2.A.2014' ITEM_NUM, --折算前
       SUM(T.BAL_1_30) AS CUR_BAL
        FROM PM_RSDATA.CBRC_FDM_CUST_LNAC_INFO T
       WHERE T.FLAG = '04'
       GROUP BY ORG_NUM;
    COMMIT;
    --2.1.5.3信用证
    INSERT 
    INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'G25_1_1.2.1.5.3.A.2014' ITEM_NUM, --折算前
       SUM(T.BAL_1_30) AS CUR_BAL
        FROM PM_RSDATA.CBRC_FDM_CUST_LNAC_INFO T
       WHERE T.FLAG = '05'
       GROUP BY ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取2.1.5其他或有融资义务至G2501_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取2.1.5.5.1其中：属于理财产品的部分至G2501_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
 --ADD BY DJH 20230417 2.1.5.5.1其中：属于理财产品的部分  G21封闭式+开放式,30日内到期
 INSERT 
 INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP 
   (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
   SELECT I_DATADATE AS DATA_DATE,
          B.ORG_NUM,
          'G25_1_1.2.1.5.5.1.A.2014' ITEM_NUM, --折算前
          SUM(B.ITEM_VAL) --期末产品余额折人民币
     FROM PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI B
    WHERE B.ITEM_NUM IN ('G21_16.1.A.2021',
                         'G21_16.1.B.2021',
                         'G21_16.1.C.2021',
                         'G21_16.2.A.2021',
                         'G21_16.2.B.2021',
                         'G21_16.2.C.2021')
    GROUP BY B.ORG_NUM;
 COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取2.1.5.5.1其中：属于理财产品的部分至G2501_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取2.2.2.6.3其他借款和现金流入的部分至G2501_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
 ----ADD BY DJH 20241205,数仓逻辑变更自动取数  2.2.2.6.3其他借款和现金流入  取值中收计提表中剩余期限一个月数据【本期累计计提中收】 ,同G22
 INSERT 
 INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP 
   (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
   SELECT I_DATADATE AS DATA_DATE,
          B.ORG_NUM,
          'G25_1_1.2.2.2.6.3.A.2014' ITEM_NUM, --折算前
          SUM(B.ITEM_VAL) --期末产品余额折人民币
     FROM PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI B
    WHERE B.ITEM_NUM IN ('G22R_1.5.A',
                         'G22R_1.5.B')
    AND ORG_NUM NOT IN('009804','009820') --ADD BY CHM 金融市场部 G2501 G25_1_1.2.2.2.6.3.A.2014 同G22 G22R_1.5.A口径不一致  --ADD BY DJH 20240510 同业金融部 同G22 G22R_1.5.A口径不一致
    GROUP BY B.ORG_NUM;
 COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取2.2.2.6.3其他借款和现金流入部分至G2501_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

---------------------------------------------金融市场部取数 add by 20230727---------------------------------------------

    ----1.合格优质流动性资产

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取1.1一级资产至G2501_DATA_COLLECT_TMP临时表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

         INSERT 
         INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
           (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
           SELECT I_DATADATE AS DATA_DATE,
                  A.ORG_NUM,
                  CASE
                    WHEN A.ISSU_ORG = 'A01' AND A.STOCK_PRO_TYPE = 'A' THEN
                     'G25_1_1.1.1.3.1.A.2014' --主权国家发行的
                    WHEN A.ISSU_ORG = 'D02' AND A.STOCK_PRO_TYPE LIKE 'C%' THEN
                     'G25_1_1.1.1.3.2.A.2014' ---主权国家担保的
                  END AS ITEM_NUM,
                  SUM(CASE
                        WHEN A.ACCOUNTANT_TYPE = '2' AND A.BOOK_TYPE = 1 THEN
                         (A.PRINCIPAL_BALANCE_CNY *
                         (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) / A.ACCT_BAL_CNY)
                        ELSE
                         (A.ZD_NET_AMT_CNY * (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) /
                         A.ACCT_BAL_CNY)
                      END) AS AMT ---中登净价金额*可用面额/持有仓位
             FROM PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A --债券投资分析表
            WHERE A.DATA_DATE = I_DATADATE
              AND ACCT_BAL_CNY <> 0   --JLBA202411080004
              AND A.INVEST_TYP = '00'
              AND A.DC_DATE > -30 --逾期超过一个月不取
            GROUP BY A.ORG_NUM,
                     CASE
                       WHEN A.ISSU_ORG = 'A01' AND A.STOCK_PRO_TYPE = 'A' THEN
                        'G25_1_1.1.1.3.1.A.2014'
                       WHEN A.ISSU_ORG = 'D02' AND
                            A.STOCK_PRO_TYPE LIKE 'C%' THEN
                        'G25_1_1.1.1.3.2.A.2014'
                     END ;
        COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取1.1一级资产至G2501_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取1.2二级资产至G2501_DATA_COLLECT_TMP临时表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

       INSERT 
       INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
         (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
         SELECT I_DATADATE AS DATA_DATE,
                A.ORG_NUM,
                CASE
                  WHEN ((A.APPRAISE_TYPE IN ('1', '2', '3', '4') AND --信用评级是>=AA的债券
                       A.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券,短期融资券,公司债,企业债,中期票据 且信用评级是AA的债券
                       OR A.STOCK_CD IN ('032000573', '032001060')) THEN
                   'G25_1_1.1.2.1.A.2014'
                  WHEN (A.STOCK_PRO_TYPE = 'A' AND A.ISSU_ORG = 'A02') THEN
                   'G25_1_1.1.2.3.4.A.2014' --地方政府债
                  WHEN (A.APPRAISE_TYPE IN ('5', '6', '7', '8', '9', 'a') AND
                       A.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券,短期融资券,公司债,企业债,中期票据 且信用评级是2B的债券
                   THEN  'G25_1_1.1.2.4.A.2014'
                END AS ITEM_NUM,
                SUM(CASE
                      WHEN A.ACCOUNTANT_TYPE = '2' AND A.BOOK_TYPE = 1 THEN
                       (A.PRINCIPAL_BALANCE_CNY *
                       (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) / A.ACCT_BAL_CNY)
                      ELSE
                       (A.ZD_NET_AMT_CNY * (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) /
                       A.ACCT_BAL_CNY)
                    END) AS AMT ---中登净价金额*可用面额/持有仓位
           FROM PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A --债券投资分析表
          WHERE A.DATA_DATE = I_DATADATE
            AND ACCT_BAL_CNY <> 0    --JLBA202411080004
            AND A.INVEST_TYP = '00'
            AND A.DC_DATE > -30
          GROUP BY A.ORG_NUM,
                   CASE
                     WHEN ((A.APPRAISE_TYPE IN ('1', '2', '3', '4') AND --信用评级是>=AA的债券
                          A.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券,短期融资券,公司债,企业债,中期票据 且信用评级是AA的债券
                          OR A.STOCK_CD IN ('032000573', '032001060')) THEN
                      'G25_1_1.1.2.1.A.2014'
                     WHEN (A.STOCK_PRO_TYPE = 'A' AND A.ISSU_ORG = 'A02') THEN
                      'G25_1_1.1.2.3.4.A.2014' --地方政府债
                     WHEN (A.APPRAISE_TYPE IN ('5', '6', '7', '8', '9', 'a') AND
                          A.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券,短期融资券,公司债,企业债,中期票据 且信用评级是2B的债券
                      THEN  'G25_1_1.1.2.4.A.2014'
                   END;
               COMMIT;

              V_STEP_FLAG := 1;
              V_STEP_DESC := '提取1.2二级资产至G2501_DATA_COLLECT_TMP中间表完成';
              SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                          V_STEP_ID,
                          V_ERRORCODE,
                          V_STEP_DESC,
                          II_DATADATE);


    ---- 2.净现金流出

      V_STEP_ID   := V_STEP_ID + 1;
      V_STEP_DESC := '提取2.1.3.1与央行进行的担保融资至G2501_DATA_COLLECT_TMP临时表';
      V_STEP_FLAG := 0;
      SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                  V_STEP_ID,
                  V_ERRORCODE,
                  V_STEP_DESC,
                  II_DATADATE);

          INSERT 
          INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
            (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
            SELECT I_DATADATE AS DATA_DATE,
                   '009804', --填报在金融市场部
                   'G25_1_1.2.1.3.1.A.2014' AS ITEM_NUM,
                   SUM(BALANCE)
              FROM PM_RSDATA.CBRC_V_PUB_FUND_MMFUND A
             WHERE DATA_DATE = I_DATADATE
               AND A.MATURE_DATE - D_DATADATE_CCY >= 0
               AND A.MATURE_DATE - D_DATADATE_CCY <= 30
               AND ACCT_TYP IN ('20303', '20304') --20303 回购式再贴现  20304 买断式再贴现
             GROUP BY A.ORG_NUM
            UNION ALL
            SELECT I_DATADATE AS DATA_DATE,
                   CASE
                     WHEN A.ORG_NUM = '009801' THEN
                      '009804'
                   END,     ---中期便利账在清算中心,报在金融市场部
                   'G25_1_1.2.1.3.1.A.2014' AS ITEM_NUM,
                   SUM(A.BALANCE)
              FROM PM_RSDATA.CBRC_V_PUB_FUND_MMFUND A
             WHERE DATA_DATE = I_DATADATE
               AND (A.MATURE_DATE - D_DATADATE_CCY >= 0 AND
                   A.MATURE_DATE - D_DATADATE_CCY <= 30)
               AND A.GL_ITEM_CODE = '20040501' --中期借贷便利
             GROUP BY A.ORG_NUM ;

           COMMIT;



          V_STEP_FLAG := 1;
          V_STEP_DESC := '提取2.1.3.1与央行进行的担保融资至G2501_DATA_COLLECT_TMP中间表完成';
          SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                      V_STEP_ID,
                      V_ERRORCODE,
                      V_STEP_DESC,
                      II_DATADATE);


          V_STEP_ID   := V_STEP_ID + 1;
          V_STEP_DESC := '提取2.1.3.1.1其中,以合格优质流动性资产为押品的融资至G2501_DATA_COLLECT_TMP临时表';
          V_STEP_FLAG := 0;
          SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                      V_STEP_ID,
                      V_ERRORCODE,
                      V_STEP_DESC,
                      II_DATADATE);

          INSERT 
          INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
            (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
            SELECT I_DATADATE AS DATA_DATE,
                   CASE
                     WHEN A.ORG_NUM = '009801' THEN
                      '009804'
                   END, ---中期便利账在清算中心,报在金融市场部
                   'G25_1_1.2.1.3.1.1.A.2014' AS ITEM_NUM,
                   SUM(A.BALANCE)
              FROM PM_RSDATA.CBRC_V_PUB_FUND_MMFUND A
             WHERE DATA_DATE = I_DATADATE
               AND (A.MATURE_DATE - D_DATADATE_CCY >= 0 AND
                   A.MATURE_DATE - D_DATADATE_CCY <= 30)
               AND A.GL_ITEM_CODE = '20040501' --中期借贷便利
             GROUP BY A.ORG_NUM;

             COMMIT;

          V_STEP_FLAG := 1;
          V_STEP_DESC := '提取2.1.3.1.1其中,以合格优质流动性资产为押品的融资至G2501_DATA_COLLECT_TMP中间表完成';
          SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                      V_STEP_ID,
                      V_ERRORCODE,
                      V_STEP_DESC,
                      II_DATADATE);

          V_STEP_ID   := V_STEP_ID + 1;
          V_STEP_DESC := '提取2.1.3.1.1.1 一级资产押品市值、2.1.3.1.1.2 2A资产押品市值、2.1.3.1.1.3 2B资产押品市值至G2501_DATA_COLLECT_TMP临时表';
          V_STEP_FLAG := 0;
          SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                      V_STEP_ID,
                      V_ERRORCODE,
                      V_STEP_DESC,
                      II_DATADATE);

          -- [2025-04-18] [石雨] [JLBA202502280012] [刘名赫]取按手动调仓表类型区分融资流出方式,备注中取出融资到期金额
           INSERT 
          INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
            (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
       B.ORG_NUM,
       case
         when (B.ISSU_ORG = 'A01' AND B.STOCK_PRO_TYPE = 'A') or
              (B.ISSU_ORG = 'D02' AND B.STOCK_PRO_TYPE LIKE 'C%') --一级资产 （国债、政策债）
          then
          'G25_1_1.2.1.3.1.1.1.A.2014'
         when (B.STOCK_PRO_TYPE = 'A' AND B.ISSU_ORG = 'A02') --地方债
              or ((B.APPRAISE_TYPE IN ('1', '2', '3', '4') AND --信用评级是>=AA的债券
              B.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券,短期融资券,公司债,企业债,中期票据 且信用评级是AA的债券
              OR B.STOCK_CD IN ('032000573', '032001060')) then   --2A资产（地方政府,信用债（企业债）） 信用评级是2A及2A以上
          'G25_1_1.2.1.3.1.1.2.A.2014'
         when (B.APPRAISE_TYPE IN ('5', '6', '7', '8', '9', 'a') AND
              B.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券,短期融资券,公司债,企业债,中期票据 且信用评级是2B的债券
          then         -- 2B资产：  企业债 信用评级是BB-到A+的债券（现吉林银行暂时无2B及资产）
          'G25_1_1.2.1.3.1.1.3.A.2014'
       end AS ITEM_NUM,
       SUM(B.RZDQ_AMT *A.JJ /100 * U.CCY_RATE )  --alter by 20250527 石雨 康立军确认改成手工调仓表押品价值
       FROM /*PM_RSDATA.SMTMODS_L_ACCT_FUND_INVEST*/( select distinct  A.SUBJECT_CD,a.data_date ,A.JJ , A.CURR_CD ,A.INVEST_TYP from PM_RSDATA.SMTMODS_L_ACCT_FUND_INVEST a
                            where a.data_date =I_DATADATE  AND A.INVEST_TYP = '00' ---投资业务品种
                            ) A --投资业务信息表
       INNER JOIN PM_RSDATA.SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00' ---投资业务品种
         AND B.STOCK_ASSET_TYPE IS NULL
         AND B.ISSUER_INLAND_FLG = 'Y'
        and B.RZDQ_AMT is not null
 GROUP BY B.ORG_NUM,
          case
            when (B.ISSU_ORG = 'A01' AND B.STOCK_PRO_TYPE = 'A') or  --国债
                 (B.ISSU_ORG = 'D02' AND B.STOCK_PRO_TYPE LIKE 'C%') --政策债
             then
             'G25_1_1.2.1.3.1.1.1.A.2014'
            when (B.STOCK_PRO_TYPE = 'A' AND B.ISSU_ORG = 'A02') --地方债
                 or ((B.APPRAISE_TYPE IN ('1', '2', '3', '4') AND --信用评级是>=AA的债券
                 B.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券,短期融资券,公司债,企业债,中期票据 且信用评级是AA的债券
                 OR B.STOCK_CD IN ('032000573', '032001060')) then
             'G25_1_1.2.1.3.1.1.2.A.2014'

            when (B.APPRAISE_TYPE IN ('5', '6', '7', '8', '9', 'a') AND
                 B.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券,短期融资券,公司债,企业债,中期票据 且信用评级是2B的债券
             then
             'G25_1_1.2.1.3.1.1.3.A.2014'
          end;
          commit;

          V_STEP_FLAG := 1;
          V_STEP_DESC := '提取2.1.3.1.1.1 一级资产押品市值、2.1.3.1.1.2 2A资产押品市值、2.1.3.1.1.3 2B资产押品市值至G2501_DATA_COLLECT_TMP中间表完成';
          SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                      V_STEP_ID,
                      V_ERRORCODE,
                      V_STEP_DESC,
                      II_DATADATE);

          V_STEP_ID   := V_STEP_ID + 1;
          V_STEP_DESC := '提取2.1.3.2/2.1.3.3由一级/2A资产担保的融资交易（与央行以外其他交易对手）至G2501_DATA_COLLECT_TMP临时表';
          V_STEP_FLAG := 0;
          SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                      V_STEP_ID,
                      V_ERRORCODE,
                      V_STEP_DESC,
                      II_DATADATE);

        --同业客户信息表去重
           INSERT INTO PM_RSDATA.CBRC_TMP_L_CUST_BILL_TY
                     SELECT CUST_ID, FINA_CODE_NEW
                       FROM (SELECT ROW_NUMBER() OVER(PARTITION BY CUST_ID ORDER BY ECIF_CUST_ID) RN,
                                    T.*
                               FROM PM_RSDATA.SMTMODS_L_CUST_BILL_TY T
                              WHERE DATA_DATE = I_DATADATE)
                      WHERE RN = 1;
               COMMIT;

              INSERT 
              INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
                (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
                SELECT I_DATADATE AS DATA_DATE,
                       A.ORG_NUM,
                       CASE
                         WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN
                          'G25_1_1.2.1.3.2.A.2014' --由一级资产担保的融资交易（与央行以外其他交易对手）
                         WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                          'G25_1_1.2.1.3.3.A.2014' --由2A级资产担保的融资交易（与央行以外其他交易对手）
                       END AS ITEM_NUM,
                  SUM(A.BALANCE * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB
             FROM PM_RSDATA.SMTMODS_L_AGRE_REPURCHASE_GUARANTY_INFO A
            INNER JOIN PM_RSDATA.CBRC_V_PUB_FUND_REPURCHASE B
               ON A.ACCT_NUM = B.ACCT_NUM
              AND B.DATA_DATE = I_DATADATE
              AND B.BUSI_TYPE LIKE '2%' --卖出回购
              AND B.ASS_TYPE = '1' --债券
              AND B.BALANCE > 0
             LEFT JOIN PM_RSDATA.CBRC_TMP_L_CUST_BILL_TY C
               ON B.CUST_ID = C.CUST_ID
             LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
               ON TT.CCY_DATE = D_DATADATE_CCY
              AND TT.BASIC_CCY = B.CURR_CD
              AND TT.FORWARD_CCY = 'CNY'
            WHERE A.DATA_DATE = I_DATADATE
              AND (C.FINA_CODE_NEW NOT LIKE 'A%' OR C.FINA_CODE_NEW IS NULL) --非货币当局
              AND (B.END_DT - D_DATADATE_CCY >= 0 AND
                  B.END_DT - D_DATADATE_CCY <= 30)
            GROUP BY A.ORG_NUM,
                     CASE
                       WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN
                        'G25_1_1.2.1.3.2.A.2014'
                       WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                        'G25_1_1.2.1.3.3.A.2014'
                     END;
               /* SELECT I_DATADATE AS DATA_DATE,
                       A.ORG_NUM,
                       CASE
                         WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN
                          'G25_1_1.2.1.3.2.A.2014' --由一级资产担保的融资交易（与央行以外其他交易对手）
                         WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                          'G25_1_1.2.1.3.3.A.2014' --由2A级资产担保的融资交易（与央行以外其他交易对手）
                       END AS ITEM_NUM,
                       SUM(A.BALANCE * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
                  FROM PM_RSDATA.CBRC_V_PUB_FUND_REPURCHASE A --回购信息表
                  LEFT JOIN PM_RSDATA.CBRC_TMP_L_CUST_BILL_TY B
                    ON A.CUST_ID = B.CUST_ID
                  LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
                    ON U.CCY_DATE = D_DATADATE_CCY
                   AND U.BASIC_CCY = A.CURR_CD --基准币种
                   AND U.FORWARD_CCY = 'CNY' --折算币种
                 WHERE A.BUSI_TYPE LIKE '2%' --卖出回购
                   AND (B.FINA_CODE_NEW NOT LIKE 'A%' OR
                       B.FINA_CODE_NEW IS NULL) --非货币当局
                   AND (A.END_DT - D_DATADATE_CCY >= 0 AND
                       A.END_DT - D_DATADATE_CCY <= 30)
                   AND A.DATA_DATE = I_DATADATE
                   AND ASS_TYPE = '1' --债券。回购业务只有债券有评级
                   AND A.BALANCE > 0
                 GROUP BY A.ORG_NUM,
                          CASE
                            WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN
                             'G25_1_1.2.1.3.2.A.2014'
                            WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                             'G25_1_1.2.1.3.3.A.2014'
                          END;*/

                 COMMIT;
                 
          -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心,30天以内外币折人民币2111卖出回购余额     
             
           INSERT 
           INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
             (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
             SELECT 
              I_DATADATE AS DATA_DATE,
              ORG_NUM,
              'G25_1_1.2.1.3.2.A.2014' AS ITEM_NUM,
              SUM(ACCT_BAL_RMB) ACCT_BAL_RMB
               FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL
              WHERE DATA_DATE = I_DATADATE
                AND ACCT_CUR <> 'CNY'
                AND FLAG = '07'
                AND REMAIN_TERM_CODE IN ('A', 'B', 'C')
               GROUP BY ORG_NUM;
           COMMIT;
       
           V_STEP_FLAG := 1;
           V_STEP_DESC := '提取2.1.3.2/2.1.3.3由一级/2A资产担保的融资交易（与央行以外其他交易对手）至G2501_DATA_COLLECT_TMP中间表完成';
           SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                      V_STEP_ID,
                      V_ERRORCODE,
                      V_STEP_DESC,
                      II_DATADATE);

           V_STEP_ID   := V_STEP_ID + 1;
           V_STEP_DESC := '提取押品市场价值至G2501_DATA_COLLECT_TMP临时表';
           V_STEP_FLAG := 0;
           SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                      V_STEP_ID,
                      V_ERRORCODE,
                      V_STEP_DESC,
                      II_DATADATE);

----该部分需要手动调仓的数据,暂时出数不准,待接入,接入后使用L_AGRE_REPURCHASE_GUARANTY_INFO表添加MOR_AMT字段重新开发程序
   /*             INSERT \*+ APPEND *\
                 INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
                   (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
                   SELECT I_DATADATE AS DATA_DATE,
                          A.ORG_NUM,
                          CASE
                            WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN --担保品风险分类为一级资产 缺失外汇抵押（暂时不取）
                             'G25_1_1.2.1.3.2.1.A.2014'
                            WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                             'G25_1_1.2.1.3.3.1.A.2014' --担保品风险分类为2A级资产
                          END AS ITEM_NUM,
                          SUM(A.MOR_AMT * U.CCY_RATE)*10000 AS LOAN_ACCT_BAL_RMB ---上游加工是质押券面总额(万)*中登净价价格/100 ,质押券面总额直取
                     FROM PM_RSDATA.CBRC_V_PUB_FUND_REPURCHASE A --回购信息表
                     LEFT JOIN PM_RSDATA.CBRC_TMP_L_CUST_BILL_TY B
                       ON A.CUST_ID = B.CUST_ID
                     LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
                       ON U.CCY_DATE = D_DATADATE_CCY
                      AND U.BASIC_CCY = A.CURR_CD --基准币种
                      AND U.FORWARD_CCY = 'CNY' --折算币种
                    WHERE A.BUSI_TYPE LIKE '2%' --卖出回购
                      AND (B.FINA_CODE_NEW NOT LIKE 'A%' OR
                          B.FINA_CODE_NEW IS NULL) --非货币当局
                      AND (A.END_DT - D_DATADATE_CCY >= 0 AND
                          A.END_DT - D_DATADATE_CCY <= 30)
                      AND A.DATA_DATE = I_DATADATE
                      AND ASS_TYPE = '1' --回购业务只有债券有评级
                      AND A.BALANCE > 0
                    GROUP BY A.ORG_NUM,
                             CASE
                               WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN
                                'G25_1_1.2.1.3.2.1.A.2014'
                               WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                                'G25_1_1.2.1.3.3.1.A.2014' --担保品风险分类为2A级资产
                             END;*/
         -- [2025-04-18] [石雨] [JLBA202502280012] [刘名赫]取康星系统一级资产一个月内到期的债券正回购押品的市场价值=押品的面额*中登净价价格/100

            INSERT 
            INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
              (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
              SELECT I_DATADATE AS DATA_DATE,
                     A.ORG_NUM,
                     CASE
                       WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN
                        'G25_1_1.2.1.3.2.1.A.2014' --由一级资产担保的融资交易（与央行以外其他交易对手）
                       WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                        'G25_1_1.2.1.3.3.1.A.2014' --由2A级资产担保的融资交易（与央行以外其他交易对手）
                     END AS ITEM_NUM,
                     SUM(CASE
                           WHEN E.POSITION_ADJUST_REM LIKE '%外汇%' THEN
                            NVL(A.COLL_MK_VAL, 0)   --外汇取市值金额
                           ELSE
                            NVL(a.BOND_VAL, 0) * (NVL(a.COLL_MK_VAL, 0) / 100)
                         END) AS LOAN_ACCT_BAL_RMB
                FROM PM_RSDATA.SMTMODS_L_AGRE_REPURCHASE_GUARANTY_INFO A --回购抵质押信息表
               INNER JOIN PM_RSDATA.CBRC_V_PUB_FUND_REPURCHASE B --回购信息表
                  ON A.ACCT_NUM = B.ACCT_NUM
                 AND B.DATA_DATE = I_DATADATE
                 AND B.BUSI_TYPE LIKE '2%' --卖出回购
                 AND B.ASS_TYPE = '1' --债券
                 AND B.BALANCE > 0
                LEFT JOIN PM_RSDATA.CBRC_TMP_L_CUST_BILL_TY C
                  ON B.CUST_ID = C.CUST_ID
                LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
                  ON TT.CCY_DATE = D_DATADATE_CCY
                 AND TT.BASIC_CCY = B.CURR_CD
                 AND TT.FORWARD_CCY = 'CNY'
                LEFT JOIN PM_RSDATA.SMTMODS_L_AGRE_BOND_INFO E
                  ON A.SUBJECT_CD = E.STOCK_CD
                 AND E.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND (C.FINA_CODE_NEW NOT LIKE 'A%' OR
                     C.FINA_CODE_NEW IS NULL) --非货币当局
                 AND (B.END_DT - D_DATADATE_CCY >= 0 AND
                     B.END_DT - D_DATADATE_CCY <= 30)
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN
                           'G25_1_1.2.1.3.2.1.A.2014' --由一级资产担保的融资交易（与央行以外其他交易对手）
                          WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                           'G25_1_1.2.1.3.3.1.A.2014' --由2A级资产担保的融资交易（与央行以外其他交易对手）
                        END;

                 COMMIT;
           -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心,30天以内外币折人民币2111卖出回购所对应的抵押品面值
           
             INSERT 
             INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
               (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
               SELECT I_DATADATE AS DATA_DATE,
                      A.ORG_NUM,
                      'G25_1_1.2.1.3.2.1.A.2014' AS ITEM_NUM, --由一级资产担保的融资交易（与央行以外其他交易对手）
                      SUM(A.BOND_VAL) AS LOAN_ACCT_BAL_RMB
                 FROM PM_RSDATA.SMTMODS_L_AGRE_REPURCHASE_GUARANTY_INFO A --回购抵质押信息表
                INNER JOIN PM_RSDATA.CBRC_V_PUB_FUND_REPURCHASE B --回购信息表
                   ON A.ACCT_NUM = B.ACCT_NUM
                  AND SUBSTR(B.GL_ITEM_CODE, 1, 4) = '2111'
                  AND B.CURR_CD <> 'CNY'
                WHERE A.DATA_DATE = I_DATADATE
                  AND (B.END_DT - I_DATADATE >= 0 AND
                      B.END_DT - I_DATADATE <= 30)
                GROUP BY A.ORG_NUM;

              COMMIT;
        
           V_STEP_FLAG := 1;
           V_STEP_DESC := '提取押品市场价值至G2501_DATA_COLLECT_TMP中间表完成';
           SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                      V_STEP_ID,
                      V_ERRORCODE,
                      V_STEP_DESC,
                      II_DATADATE);


           V_STEP_ID   := V_STEP_ID + 1;
           V_STEP_DESC := '提取2.1.3.5.2其他交易对手至G2501_DATA_COLLECT_TMP临时表';
           V_STEP_FLAG := 0;
           SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                      V_STEP_ID,
                      V_ERRORCODE,
                      V_STEP_DESC,
                      II_DATADATE);

                 INSERT 
                 INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
                   (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
                   SELECT I_DATADATE AS DATA_DATE,
                          A.ORG_NUM,
                          'G25_1_1.2.1.3.5.2.A.2014' --  2.1.3.5.2其他交易对手
                          AS ITEM_NUM,
                          SUM(A.BALANCE * U.CCY_RATE)  AS LOAN_ACCT_BAL_RMB
                     FROM PM_RSDATA.CBRC_V_PUB_FUND_REPURCHASE A --回购信息表
                     LEFT JOIN PM_RSDATA.CBRC_TMP_L_CUST_BILL_TY B
                       ON A.CUST_ID = B.CUST_ID
                     LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
                       ON U.CCY_DATE = D_DATADATE_CCY
                      AND U.BASIC_CCY = A.CURR_CD --基准币种
                      AND U.FORWARD_CCY = 'CNY' --折算币种
                    WHERE A.BUSI_TYPE LIKE '2%' --卖出回购
                      AND (B.FINA_CODE_NEW NOT LIKE 'A%' OR
                          B.FINA_CODE_NEW IS NULL) --非货币当局
                      AND (A.END_DT - D_DATADATE_CCY >= 0 AND
                          A.END_DT - D_DATADATE_CCY <= 30)
                      AND A.DATA_DATE = I_DATADATE
                      AND ASS_TYPE = '2' --回购业务票据
                      AND A.BALANCE > 0
                    GROUP BY A.ORG_NUM;
               COMMIT;

           V_STEP_FLAG := 1;
           V_STEP_DESC := '提取2.1.3.5.2其他交易对手至G2501_DATA_COLLECT_TMP中间表完成';
           SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                      V_STEP_ID,
                      V_ERRORCODE,
                      V_STEP_DESC,
                      II_DATADATE);



           V_STEP_ID   := V_STEP_ID + 1;
           V_STEP_DESC := '提取2.1.6其他所有没有包含在以上类别中的本金、利息等现金流出至G2501_DATA_COLLECT_TMP临时表';
           V_STEP_FLAG := 0;
           SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                      V_STEP_ID,
                      V_ERRORCODE,
                      V_STEP_DESC,
                      II_DATADATE);

                     INSERT 
                     INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
                       (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
                       SELECT I_DATADATE AS DATA_DATE,
                              ORG_NUM,
                              'G25_1_1.2.1.6.A.2014' AS ITEM_NUM,
                              SUM(A.ACCRUAL * TT.CCY_RATE)
                         FROM PM_RSDATA.CBRC_V_PUB_FUND_REPURCHASE A
                         LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
                           ON TT.CCY_DATE = D_DATADATE_CCY
                          AND TT.BASIC_CCY = A.CURR_CD
                          AND TT.FORWARD_CCY = 'CNY'
                        WHERE A.DATA_DATE = I_DATADATE
                          AND A.BUSI_TYPE LIKE '2%' --卖出回购
                          AND (A.END_DT - D_DATADATE_CCY >= 0 AND
                              A.END_DT - D_DATADATE_CCY <= 30)
                          AND A.BALANCE > 0
                        GROUP BY ORG_NUM;
                   COMMIT;

           V_STEP_FLAG := 1;
           V_STEP_DESC := '提取2.1.6其他所有没有包含在以上类别中的本金、利息等现金流出至G2501_DATA_COLLECT_TMP中间表完成';
           SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                      V_STEP_ID,
                      V_ERRORCODE,
                      V_STEP_DESC,
                      II_DATADATE);


           V_STEP_ID   := V_STEP_ID + 1;
           V_STEP_DESC := '提取2.2.1.2押品未用于再抵押（质押式）至G2501_DATA_COLLECT_TMP临时表';
           V_STEP_FLAG := 0;
           SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                      V_STEP_ID,
                      V_ERRORCODE,
                      V_STEP_DESC,
                      II_DATADATE);

                ---一个月内到期质押式逆回购本金
                         INSERT 
                         INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
                           (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
                           SELECT I_DATADATE AS DATA_DATE,
                                  ORG_NUM,
                                  'G25_1_1.2.2.1.2.A.2014' AS ITEM_NUM,
                                  SUM(A.BALANCE * TT.CCY_RATE)
                             FROM PM_RSDATA.CBRC_V_PUB_FUND_REPURCHASE A
                             LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
                               ON TT.CCY_DATE =
                                  D_DATADATE_CCY
                              AND TT.BASIC_CCY = A.CURR_CD
                              AND TT.FORWARD_CCY = 'CNY'
                            WHERE A.DATA_DATE = I_DATADATE
                              AND A.BUSI_TYPE LIKE '1%' --买入返售
                              AND (A.END_DT - D_DATADATE_CCY >= 0 AND
                                  A.END_DT - D_DATADATE_CCY <= 30)
                              AND A.BALANCE > 0
                            GROUP BY ORG_NUM;
                       COMMIT;
             V_STEP_FLAG := 1;
             V_STEP_DESC := '提取2.2.1.2押品未用于再抵押（质押式）至G2501_DATA_COLLECT_TMP中间表完成';
             SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                        V_STEP_ID,
                        V_ERRORCODE,
                        V_STEP_DESC,
                        II_DATADATE);


            V_STEP_ID   := V_STEP_ID + 1;
            V_STEP_DESC := '提取2.2.2.6.3其他借款和现金流入至G2501_DATA_COLLECT_TMP临时表';
            V_STEP_FLAG := 0;
            SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

             INSERT 
             INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
               (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
               SELECT I_DATADATE AS DATA_DATE, ORG_NUM, ITEM_NUM, SUM(AMT)
                 FROM --一个月内到期的同业存单投资账面 + 同业存单应收利息
                      (SELECT ORG_NUM,
                              'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                              SUM(A.PRINCIPAL_BALANCE * TT.CCY_RATE +
                                  A.INTEREST_RECEIVABLE * TT.CCY_RATE) AS AMT
                         FROM PM_RSDATA.SMTMODS_V_PUB_FUND_CDS_BAL A
                         LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
                           ON TT.CCY_DATE = D_DATADATE_CCY
                          AND TT.BASIC_CCY = A.CURR_CD
                          AND TT.FORWARD_CCY = 'CNY'
                        WHERE A.DATA_DATE = I_DATADATE
                          AND DC_DATE >= 0
                          AND DC_DATE <= 30
                          AND STOCK_PRO_TYPE = 'A' --同业存单
                          AND PRODUCT_PROP = 'A' --持有
                          AND ORG_NUM = '009804' --ADD BY DJH 20240510  与同业金融部单独处理
                        GROUP BY ORG_NUM
                       UNION ALL

                       --一个月内到期逆回购应收利息

                       SELECT ORG_NUM,
                              'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                              SUM(A.ACCRUAL * TT.CCY_RATE) AS AMT
                         FROM PM_RSDATA.CBRC_V_PUB_FUND_REPURCHASE A
                         LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
                           ON TT.CCY_DATE = D_DATADATE_CCY
                          AND TT.BASIC_CCY = A.CURR_CD
                          AND TT.FORWARD_CCY = 'CNY'
                        WHERE A.DATA_DATE = I_DATADATE
                          AND A.BUSI_TYPE LIKE '1%' --买入返售
                          AND (A.END_DT - D_DATADATE_CCY >= 0 AND
                              A.END_DT - D_DATADATE_CCY <= 30)
                          AND A.END_DT > D_DATADATE_CCY
                          --AND ORG_NUM = '009804'
                        GROUP BY ORG_NUM
                       UNION ALL

                       --一个月到期的转贴现票面金额
                       SELECT ORG_NUM,
                              'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                              SUM(A.LOAN_ACCT_BAL * TT.CCY_RATE) AS AMT
                         FROM PM_RSDATA.SMTMODS_L_ACCT_LOAN A
                         LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
                           ON TT.CCY_DATE = D_DATADATE_CCY
                          AND TT.BASIC_CCY = A.CURR_CD
                          AND TT.FORWARD_CCY = 'CNY'
                         LEFT JOIN PM_RSDATA.CBRC_L_PUBL_HOLIDAY_G2501 B
                          ON A.MATURITY_DT = B.HOLIDAY_DATE
                        WHERE A.DATA_DATE = I_DATADATE
                          AND (A.ITEM_CD LIKE '130102%' --以摊余成本计量的转贴现
                              OR ITEM_CD LIKE '130105%') --以公允价值计量变动计入权益的转贴现
                          AND ORG_NUM = '009804'
                          AND (NVL(B.LASTDAY,A.MATURITY_DT) - D_DATADATE_CCY >= 0 AND NVL(B.LASTDAY,A.MATURITY_DT) - D_DATADATE_CCY <= 30)
                        GROUP BY ORG_NUM
                        UNION ALL

                        -- 一个月内债券借贷融出的未到期余额（金额为：融出面额*中登净价价格/100）
                        -- 融出科目72100101 做为主表原因 同一标的存在只有融入没有融出情况 当为这种情况时 融入额是不需要计算的
                       SELECT A.ORG_NUM,'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,SUM(NVL(A.BALANCE,0)-NVL(B.BALANCE,0))AMT
                          FROM (
                                SELECT T.TZBD_ID TZBD_ID,T.ORG_NUM,SUM(T.BALANCE*T.ZD_NET_AMT/100) BALANCE
                                  FROM PM_RSDATA.CBRC_V_PUB_FUND_MMFUND T
                                 WHERE T.GL_ITEM_CODE = '72100101' -- 债券借贷 应收借出债券 融出
                                   AND T.DATA_DATE = I_DATADATE
                                   AND T.BALANCE <> 0
                                   AND T.DATE_SOURCESD = '康星_债券借贷'
                                   AND T.ORG_NUM = '009804'
                                   AND (T.MATURE_DATE - D_DATADATE_CCY >= 0 AND T.MATURE_DATE - D_DATADATE_CCY <= 30)
                                 GROUP BY T.TZBD_ID, T.GL_ITEM_CODE,T.ORG_NUM) A
                          LEFT JOIN (
                                 SELECT T.TZBD_ID TZBD_ID,T.ORG_NUM, SUM(T.BALANCE*T.ZD_NET_AMT/100) BALANCE
                                  FROM PM_RSDATA.CBRC_V_PUB_FUND_MMFUND T
                                 WHERE T.GL_ITEM_CODE ='72400101' -- 债券借贷  应付借入债券 融入
                                   AND T.DATA_DATE = I_DATADATE
                                   AND T.BALANCE <> 0
                                   AND T.DATE_SOURCESD = '康星_债券借贷'
                                   AND T.ORG_NUM = '009804'
                                   AND (T.MATURE_DATE - D_DATADATE_CCY >= 0 AND T.MATURE_DATE - D_DATADATE_CCY <= 30)
                                 GROUP BY T.TZBD_ID, T.GL_ITEM_CODE,T.ORG_NUM) B
                                ON A.TZBD_ID = B.TZBD_ID
                          GROUP BY A.ORG_NUM
                        )
                GROUP BY ORG_NUM, ITEM_NUM;
         COMMIT;

              V_STEP_FLAG := 1;
              V_STEP_DESC := '提取2.2.2.6.3其他借款和现金流入至G2501_DATA_COLLECT_TMP中间表完成';
              SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                      V_STEP_ID,
                      V_ERRORCODE,
                      V_STEP_DESC,
                      II_DATADATE);

              V_STEP_ID   := V_STEP_ID + 1;
              V_STEP_DESC := '提取2.2.2.7到期证券投资至G2501_DATA_COLLECT_TMP临时表';
              V_STEP_FLAG := 0;
              SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                      V_STEP_ID,
                      V_ERRORCODE,
                      V_STEP_DESC,
                      II_DATADATE);

          INSERT 
          INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
            (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
            SELECT I_DATADATE AS DATA_DATE,
                   A.ORG_NUM,
                   'G25_1_1.2.2.2.7.A.2014' AS ITEM_NUM,
                   SUM(A.PRINCIPAL_BALANCE_CNY) AS AMT ---剩余本金
              FROM PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A
             WHERE INVEST_TYP = '00'
               AND DATA_DATE = I_DATADATE
               AND (A.APPRAISE_TYPE = 'b' AND --信用评级是BBB-级以下的债券(债券评级是C的债券)
                   (A.STOCK_PRO_TYPE IN ('C01', 'C0101') ---次级债+二级工具+非公司金融债
                   OR (A.ISSU_ORG = 'D03' AND STOCK_PRO_TYPE LIKE 'C%')) --商业银行债
                   )
              -- AND A.ACCOUNTANT_TYPE = '1' --交易性金融资产   --ADD BY DJH 20240510  金融市场部 G21交易金融资产特殊处理放2-7日,其他不需要区分会计分类,按照待偿期区分即可
               AND A.DC_DATE >= 0
               AND A.DC_DATE <= 30
             GROUP BY A.ORG_NUM;
               /*SELECT I_DATADATE AS DATA_DATE,
                      A.ORG_NUM,
                      'G25_1_1.2.2.2.7.A.2014' AS ITEM_NUM,
                      SUM(A.PRINCIPAL_BALANCE * TT.CCY_RATE)  AS AMT ---剩余本金
                 FROM PM_RSDATA.SMTMODS_L_ACCT_FUND_INVEST A
                INNER JOIN PM_RSDATA.SMTMODS_L_AGRE_BOND_INFO B
                   ON A.SUBJECT_CD = B.STOCK_CD
                  AND B.DATA_DATE = I_DATADATE
                 LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
                   ON TT.CCY_DATE = D_DATADATE_CCY
                  AND TT.BASIC_CCY = A.CURR_CD
                  AND TT.FORWARD_CCY = 'CNY'
                WHERE A.DATA_DATE = I_DATADATE
                  AND (B.APPRAISE_TYPE = 'b' AND --信用评级是BBB-级以下的债券(债券评级是C的债券)
                      (B.STOCK_PRO_TYPE IN ('C01', 'C0101') ---次级债+二级工具+非公司金融债
                      OR (B.ISSU_ORG = 'D03' AND STOCK_PRO_TYPE LIKE 'C%')) --商业银行债
                      )
                  AND A.INVEST_TYP = '00'
                  AND A.ACCOUNTANT_TYPE = '1' --交易性金融资产
                  AND A.DC_DATE >= 0
                  AND A.DC_DATE <= 30
                GROUP BY A.ORG_NUM;*/

               COMMIT;

              V_STEP_FLAG := 1;
              V_STEP_DESC := '提取2.2.2.7到期证券投资至G2501_DATA_COLLECT_TMP中间表完成';
              SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                      V_STEP_ID,
                      V_ERRORCODE,
                      V_STEP_DESC,
                      II_DATADATE);
   --ADD BY DJH 20240510  同业金融部 009820
   ---------------------------------------------除了以上存款---------------------------------------------
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_DESC := '提取2.1.2.4.3银行存款,有业务关系且无存款保险至G2501_DATA_COLLECT_TMP临时表';
        V_STEP_FLAG := 0;
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --2.1.2.4.3银行存款,有业务关系且无存款保险
   -- 一个月内到期的同业拆入+同业存放定期（全行的定期报送在009820）本金+结算性同业存放活期(20120101和20120102的全行数取进009820,从业务状况表取,都属于1个月内)
   -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心30天以内外币折人民币2003拆入资金本金
        INSERT 
        INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 A.ORG_NUM,
                 'G25_1_1.2.1.2.4.3.A.2014' AS ITEM_NUM,
                 SUM(A.ACCT_BAL_RMB) AS ITEM_VAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
           WHERE A.FLAG  IN ('05','10') --同业拆入(有其他机构) 转贷款
             AND ACCT_BAL_RMB <> 0
             AND A.ORG_NUM IN ('009804', '009820') 
             AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
                 A.MATUR_DATE - D_DATADATE_CCY <= 30)
           GROUP BY A.ORG_NUM;
         COMMIT;

        INSERT 
        INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 '009820' AS ORG_NUM,
                 'G25_1_1.2.1.2.4.3.A.2014' AS ITEM_NUM,
                 SUM(A.BALANCE * CCY_RATE) ITEM_VAL
            FROM PM_RSDATA.CBRC_V_PUB_FUND_MMFUND A
            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
              ON TT.CCY_DATE = D_DATADATE_CCY
             AND TT.BASIC_CCY = A.CURR_CD
             AND TT.FORWARD_CCY = 'CNY'
           WHERE A.DATA_DATE = I_DATADATE
             AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201202' --同业存放的定期
             AND A.BALANCE <> 0
             AND A.ORG_NUM NOT LIKE '5%'
             AND A.ORG_NUM NOT LIKE '6%'
             AND (A.MATURE_DATE - D_DATADATE_CCY >= 0 AND
                 A.MATURE_DATE - D_DATADATE_CCY <= 30);
         COMMIT;
      --20240331填报上没有这块？
        INSERT 
        INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT 
           I_DATADATE AS DATA_DATE,
           '009820' AS ORG_NUM,
           'G25_1_1.2.1.2.4.3.A.2014' AS ITEM_NUM,
           SUM(CREDIT_BAL) ITEM_VAL
            FROM PM_RSDATA.SMTMODS_L_FINA_GL A
           WHERE DATA_DATE = I_DATADATE
             AND CURR_CD = 'BWB'
             AND ITEM_CD IN('20120101','20120102')
             AND A.ORG_NUM='990000'
           GROUP BY A.ITEM_CD, A.ORG_NUM;
        COMMIT;
        
        
         -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心,30天以内外币折人民币1302拆放同业余额
        
        INSERT 
        INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 '009801' AS ORG_NUM,
                 'G25_1_1.2.1.2.4.3.A.2014' AS ITEM_NUM,
                 SUM(NVL(ACCT_BAL_RMB, 0)) ITEM_VAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
           WHERE A.FLAG = '02' -- 02(1302拆出资金)
             AND A.ORG_NUM = '009801'
             AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
                 A.MATUR_DATE - D_DATADATE_CCY <= 30);

        COMMIT;
        

        V_STEP_FLAG := 1;
        V_STEP_DESC := '提取2.1.2.4.3银行存款,有业务关系且无存款保险至G2501_DATA_COLLECT_TMP中间表完成';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_DESC := '提取2.1.2.4.6其他金融机构存款,有业务关系且无存款保险至G2501_DATA_COLLECT_TMP临时表';
        V_STEP_FLAG := 0;
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --2.1.2.4.6其他金融机构存款,有业务关系且无存款保险
    --同业存放余额搜东北证券股份有限公司和LIKE '永诚保险资产管理有限公司%'的余额填报该指标
        V_STEP_FLAG := 1;
        V_STEP_DESC := '提取2.1.2.4.6其他金融机构存款,有业务关系且无存款至G2501_DATA_COLLECT_TMP中间表完成';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

        INSERT 
        INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT 
           I_DATADATE AS DATA_DATE,
           '009820' AS ORG_NUM,
           'G25_1_1.2.1.2.4.6.A.2014' AS ITEM_NUM,
           SUM(A.BALANCE * CCY_RATE) ITEM_VAL
            FROM PM_RSDATA.CBRC_V_PUB_FUND_MMFUND A
            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
              ON TT.CCY_DATE = D_DATADATE_CCY
             AND TT.BASIC_CCY = A.CURR_CD
             AND TT.FORWARD_CCY = 'CNY'
           WHERE A.DATA_DATE = I_DATADATE
                -- AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201201' --同业存放活期款项
             AND A.BALANCE <> 0
             AND A.CUST_ID IN ('8913402328', '8916869348') ; --8913402328东北证券股份有限公司 8916869348永诚保险资产管理有限公司

        COMMIT;
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_DESC := '提取2.1.2.4.8无业务关系的金融机构存款至G2501_DATA_COLLECT_TMP临时表';
        V_STEP_FLAG := 0;
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --2.1.2.4.8无业务关系的金融机构存款
    --扣除东北证券和保险后的非结算性同业存放活期余额（全行口径）
         INSERT 
         INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
           (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
           SELECT 
            I_DATADATE AS DATA_DATE,
            '009820' AS ORG_NUM,
            'G25_1_1.2.1.2.4.8.A.2014' AS ITEM_NUM,
            SUM(A.BALANCE * CCY_RATE) ITEM_VAL
             FROM PM_RSDATA.CBRC_V_PUB_FUND_MMFUND A
             LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
               ON TT.CCY_DATE = I_DATADATE
              AND TT.BASIC_CCY = A.CURR_CD
              AND TT.FORWARD_CCY = 'CNY'
            WHERE A.DATA_DATE = I_DATADATE
              AND A.GL_ITEM_CODE IN
                  ('20120103', '20120104', '20120105', '20120109', '20120110')
              AND A.CUST_ID NOT IN ('8913402328', '8916869348') --去掉8913402328东北证券股份有限公司 8916869348永诚保险资产管理有限公司
              AND A.BALANCE <> 0
              AND A.ORG_NUM NOT LIKE '5%'
              AND A.ORG_NUM NOT LIKE '6%';
       COMMIT;
       
      -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心,30天以内外币折人民币2003同业拆入及同业代付余额,业务说同业代付包含009801清算中心以及分支行业务
       INSERT 
       INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
         (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
         SELECT 
          I_DATADATE AS DATA_DATE,
          ORG_NUM,
          'G25_1_1.2.1.2.4.8.A.2014' AS ITEM_NUM,
          SUM(ACCT_BAL_RMB) ACCT_BAL_RMB
           FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL
          WHERE DATA_DATE = I_DATADATE
            AND ACCT_CUR <> 'CNY'
            AND FLAG = '05'
            AND REMAIN_TERM_CODE IN ('A', 'B', 'C')
          GROUP BY ORG_NUM;
       COMMIT;
       
     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君]   G2501取分行同业代付30天内,G2502取所有
      /*新国结系统,会传给ngi系统
      1、负债方：委托代付,是我行委托他行,业务提供新国结系统进口代付业务明细表页面数据,所以从ngi系统取数
      2、资产方：受托代付,是他行委托我行,这个功能没上线*/  
      
     --备注： 委托方同业代付：是指填报机构（委托方）委托其他金融机构（受托方）向企业客户付款,委托方在约定还款日偿还代付款项本息的资金融通款项。

      
       INSERT 
       INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
         (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
         SELECT A.DATA_DATE,
                '009801' AS ORG_NUM,
                'G25_1_1.2.1.2.4.8.A.2014' AS ITEM_NUM,
                SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL
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
            AND LOAN_ACCT_BAL <> 0
            AND (A.ACTUAL_MATURITY_DT - D_DATADATE_CCY >= 0 AND
                 A.ACTUAL_MATURITY_DT - D_DATADATE_CCY <= 30)
          GROUP BY A.DATA_DATE;
          
    
        V_STEP_FLAG := 1;
        V_STEP_DESC := '提取2.1.2.4.8无业务关系的金融机构存款至G2501_DATA_COLLECT_TMP中间表完成';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_DESC := '提取2.1.2.5未包含在以上无担保批发现金流出分类的其他类别至G2501_DATA_COLLECT_TMP临时表';
        V_STEP_FLAG := 0;
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --2.1.2.5未包含在以上无担保批发现金流出分类的其他类别
    --一个月内到期的同业存单持有仓位(账面余额)
     INSERT 
     INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
       (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
       SELECT 
        I_DATADATE AS DATA_DATE,
        '009820' AS ORG_NUM,
        'G25_1_1.2.1.2.5.A.2014' AS ITEM_NUM,
        SUM(ACCT_BAL_RMB) ITEM_VAL
         FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
        WHERE A.FLAG = '06'--同业存单发行
          AND ACCT_BAL_RMB <> 0
          AND A.ORG_NUM = '009820'
          AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
              A.MATUR_DATE - D_DATADATE_CCY <= 30);
       COMMIT;

    --一个月内到期同业拆入应付利息
       INSERT 
        INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 A.ORG_NUM,
                 'G25_1_1.2.1.2.5.A.2014' AS ITEM_NUM,
                 SUM(A.INTEREST_ACCURAL) AS ITEM_VAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
           WHERE A.FLAG = '05' --同业拆入(有其他机构)
             AND ACCT_BAL_RMB <> 0
             AND A.ORG_NUM IN ('009804')
             AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
                 A.MATUR_DATE - D_DATADATE_CCY <= 30)
           GROUP BY A.ORG_NUM;
         COMMIT;



        V_STEP_FLAG := 1;
        V_STEP_DESC := '提取2.1.2.5未包含在以上无担保批发现金流出分类的其他类别至G2501_DATA_COLLECT_TMP中间表完成';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_DESC := '提取2.1.6其他所有没有包含在以上类别中的本金、利息等现金流出至G2501_DATA_COLLECT_TMP临时表';
        V_STEP_FLAG := 0;
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --2.1.6其他所有没有包含在以上类别中的本金、利息等现金流出
    /*一个月内到期009820同业拆入利息
    +全行一个月内到期同业存放定期利息
    +全行一个月内到期非结算性同业存放活期利息,其中同业存放活期利息扣除保险类利息（22310906科目）；
    同业存放活期利息及其保险类部分从总账出,其他从明细出;涉及科目'22310903','22310904','22310905','22310907','22310908','22310909','22310910','22310911'*/

    --一个月内到期009820同业拆入利息
     INSERT 
     INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
       (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
       SELECT I_DATADATE AS DATA_DATE,
              '009820' AS ORG_NUM,
              'G25_1_1.2.1.6.A.2014' AS ITEM_NUM,
              SUM(INTEREST_ACCURAL) ITEM_VAL
         FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
        WHERE A.FLAG IN ('05','10') --同业拆入应付利息
          AND INTEREST_ACCURAL <> 0
          AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
              A.MATUR_DATE - D_DATADATE_CCY <= 30)
          AND A.ORG_NUM = '009820';
     COMMIT;

    --全行一个月内到期同业存放定期利息
     INSERT 
     INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
       (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
       SELECT I_DATADATE AS DATA_DATE,
              '009820' AS ORG_NUM,
              'G25_1_1.2.1.6.A.2014' AS ITEM_NUM,
              SUM(A.ACCRUAL * CCY_RATE) ITEM_VAL
         FROM PM_RSDATA.CBRC_V_PUB_FUND_MMFUND A
         LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
           ON TT.CCY_DATE = D_DATADATE_CCY
          AND TT.BASIC_CCY = A.CURR_CD
          AND TT.FORWARD_CCY = 'CNY'
        WHERE A.DATA_DATE = I_DATADATE
          AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201202' --同业存放定期
          AND A.ACCRUAL <> 0
          AND (A.MATURE_DATE - D_DATADATE_CCY >= 0 AND
              A.MATURE_DATE - D_DATADATE_CCY <= 30)
          AND A.ORG_NUM NOT LIKE '5%'
          AND A.ORG_NUM NOT LIKE '6%';
     COMMIT;

     --全行一个月内到期非结算性同业存放活期利息,其中同业存放活期利息扣除保险类利息（22310906科目）
      --同业存放活期利息及其保险类部分从总账出,其他从明细出;涉及科目'22310903','22310904','22310905','22310907','22310908','22310909','22310910','22310911'
       INSERT 
       INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
         (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
         SELECT I_DATADATE AS DATA_DATE,
                '009820' AS ORG_NUM,
                'G25_1_1.2.1.6.A.2014' AS ITEM_NUM,
                SUM(T.CREDIT_BAL * CCY_RATE) ITEM_VAL
           FROM PM_RSDATA.SMTMODS_L_FINA_GL T
           LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
             ON TT.CCY_DATE = D_DATADATE_CCY
            AND TT.BASIC_CCY = T.CURR_CD
            AND TT.FORWARD_CCY = 'CNY'
          WHERE T.ITEM_CD IN ('22310903',
                              '22310904',
                              '22310905',
                              '22310907',
                              '22310908',
                              '22310909',
                              '22310910',
                              '22310911')
            AND T.DATA_DATE = I_DATADATE
            AND T.CURR_CD <> 'BWB'
            AND T.ORG_NUM = '990000';
     COMMIT;



        V_STEP_FLAG := 1;
        V_STEP_DESC := '提取2.1.6其他所有没有包含在以上类别中的本金、利息等现金流出至G2501_DATA_COLLECT_TMP中间表完成';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_DESC := '提取2.2.2.6.1有业务关系的款项至G2501_DATA_COLLECT_TMP临时表';
        V_STEP_FLAG := 0;
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --2.2.2.6.1有业务关系的款项 一个月内到期全行的存放同业活期的本金+利息
        INSERT 
        INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT 
           I_DATADATE AS DATA_DATE,
           '009820' AS ORG_NUM,
           'G25_1_1.2.2.2.6.1.A.2014' AS ITEM_NUM,
           SUM(ACCT_BAL_RMB) ITEM_VAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
           WHERE A.FLAG = '01' --1011(存放同业)、 1031(存出保证金)
             AND ACCT_BAL_RMB <> 0
             AND SUBSTR(A.GL_ITEM_CODE, 1, 6) ='101101' --存放同业活期
             AND A.ACCT_CUR = 'CNY' --取人民币部分,不要外币
             AND A.ORG_NUM NOT LIKE '5%'
             AND A.ORG_NUM NOT LIKE '6%'
          UNION ALL
          SELECT I_DATADATE AS DATA_DATE,
                 '009820' AS ORG_NUM,
                 'G25_1_1.2.2.2.6.1.A.2014' AS ITEM_NUM,
                 SUM(INTEREST_ACCURAL) ITEM_VAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
           WHERE (A.FLAG = '01' AND SUBSTR(A.GL_ITEM_CODE, 1, 6) ='101101') --存放同业活期 ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
             AND A.ORG_NUM NOT LIKE '5%'
             AND A.ORG_NUM NOT LIKE '6%';
       COMMIT;
       
        -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心,取报告期末业务状况表（机构990000,外币折人民币）,存放同业活期101101借方余额

        INSERT 
        INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT 
           I_DATADATE AS DATA_DATE,
           '009801' AS ORG_NUM,
           'G25_1_1.2.2.2.6.1.A.2014' AS ITEM_NUM,
           SUM(DEBIT_BAL) ITEM_VAL
            FROM PM_RSDATA.SMTMODS_L_FINA_GL A
           WHERE DATA_DATE = I_DATADATE
             AND CURR_CD = 'CFC'  --外币折人民币
             AND ITEM_CD = '101101'
             AND A.ORG_NUM='990000'
           GROUP BY A.ORG_NUM;
        COMMIT;
       

        V_STEP_FLAG := 1;
        V_STEP_DESC := '提取2.2.2.6.1有业务关系的款项至G2501_DATA_COLLECT_TMP中间表完成';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_DESC := '提取2.2.2.6.3其他借款和现金流入至G2501_DATA_COLLECT_TMP临时表';
        V_STEP_FLAG := 0;
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --2.2.2.6.3其他借款和现金流入
   /* 取人民币的：一个月内到期全行的存放同业活期的保证金账户（103101）的本金;
    +一个月内到期009820机构存放同业定期本金和利息
    +一个月内到期009820机构拆放同业（包括借出同业）本金和利息;
    +一个月内到期009820机构其他投资本金和利息
    （包括1.基金的持有仓位+公允+利息;
    2.同业存单投资的剩余本金+应收;
    3.委外的投资：科目为11010303,取一个月内到期的账户类型是FVTPL的账户的持有仓位+公允,其中中信信托2笔特殊处理不填报于此）
    +一个月内到期的债券借贷*/
      INSERT 
      INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
        (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
        SELECT 
         I_DATADATE AS DATA_DATE,
         '009820' AS ORG_NUM,
         'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
         SUM(ACCT_BAL_RMB) ITEM_VAL
          FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
         WHERE A.FLAG = '01' --1011(存放同业)、 1031(存出保证金)
           AND ACCT_BAL_RMB <> 0
           AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '103101' --同业活期的保证金账户
           AND A.ACCT_CUR = 'CNY' --取人民币部分,不要外币
           AND A.ORG_NUM NOT LIKE '5%'
           AND A.ORG_NUM NOT LIKE '6%'
         /*  AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
               A.MATUR_DATE - D_DATADATE_CCY <= 30)*/;

        COMMIT;

        --一个月内到期009820机构存放同业定期本金和利息 取全行还是同业金融部？
        INSERT 
        INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT 
           I_DATADATE AS DATA_DATE,
           '009820' AS ORG_NUM,
           'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
           SUM(ACCT_BAL_RMB) ITEM_VAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
           WHERE A.FLAG = '01' --1011(存放同业)、 1031(存出保证金)
             AND ACCT_BAL_RMB <> 0
             AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '101102' --此处存放同业定期
             AND A.ORG_NUM NOT LIKE '5%'
             AND A.ORG_NUM NOT LIKE '6%'
             AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND A.MATUR_DATE - D_DATADATE_CCY <= 30)
          UNION ALL
          SELECT I_DATADATE AS DATA_DATE,
                 '009820' AS ORG_NUM,
                 'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                 SUM(INTEREST_ACCURAL) ITEM_VAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
           WHERE (A.FLAG = '01' AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '101102') --存放同业定期  ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
            AND A.ORG_NUM NOT LIKE '5%'
            AND A.ORG_NUM NOT LIKE '6%'
            AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND A.MATUR_DATE - D_DATADATE_CCY <= 30);

        COMMIT;

       --一个月内到期009820机构拆放同业（包括借出同业）本金和利息
        INSERT 
        INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 '009820' AS ORG_NUM,
                 'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                 SUM(NVL(ACCT_BAL_RMB,0)+NVL(INTEREST_ACCURAL,0)) ITEM_VAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
           WHERE A.FLAG = '02' --01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
             AND A.ORG_NUM = '009820'
             AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND A.MATUR_DATE - D_DATADATE_CCY <= 30);

        COMMIT;

     /* 一个月内到期009820机构其他投资本金和利息
      （包括1.基金的持有仓位+公允+利息;
            2.同业存单投资的剩余本金+应收;
            3.委外的投资：科目为11010303,取一个月内到期的账户类型是FVTPL的账户的持有仓位+公允,其中中信信托2笔特殊处理不填报于此）*/
        INSERT 
        INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 '009820' AS ORG_NUM,
                 'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                 SUM(NVL(ACCT_BAL_RMB,0)+NVL(INTEREST_ACCURAL,0)) ITEM_VAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
           WHERE A.FLAG IN('06') --01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
             AND A.ORG_NUM = '009820'
             AND A.REMAIN_TERM_CODE IN ('A','B','C');
        COMMIT;


        INSERT 
        INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 '009820' AS ORG_NUM,
                 'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                 SUM(NVL(ACCT_BAL_RMB,0)) ITEM_VAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
           WHERE A.FLAG IN('07') --01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
             AND A.ORG_NUM = '009820'
             AND ACCT_NUM NOT IN ('N000310000025496', 'N000310000025495')
             AND A.REMAIN_TERM_CODE IN ('A','B','C');


        COMMIT;
        INSERT 
        INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 '009820' AS ORG_NUM,
                 'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                 SUM(NVL(ACCT_BAL_RMB, 0) + NVL(INTEREST_ACCURAL, 0)) ITEM_VAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
           WHERE A.FLAG = '04' --01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
             AND A.ORG_NUM = '009820'
             AND (DC_DATE >= 0 AND DC_DATE <= 30);
       COMMIT;
       
       -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心,30天以内外币折人民币1302拆放同业余额 + 报告期末业务状况表（990000,外币折人民币）,1031借方余额
        
        INSERT 
        INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 '009801' AS ORG_NUM,
                 'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                 SUM(NVL(ACCT_BAL_RMB, 0)) ITEM_VAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
           WHERE A.FLAG = '02' -- 02(1302拆出资金)
             AND A.ORG_NUM = '009801'
             AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
                 A.MATUR_DATE - D_DATADATE_CCY <= 30);

        COMMIT;

        INSERT 
        INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT 
           I_DATADATE AS DATA_DATE,
           '009801' AS ORG_NUM,
           'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
           SUM(DEBIT_BAL) ITEM_VAL
            FROM PM_RSDATA.SMTMODS_L_FINA_GL A
           WHERE DATA_DATE = I_DATADATE
             AND CURR_CD = 'CFC' --外币折人民币
             AND ITEM_CD = '1031'
             AND A.ORG_NUM='990000'
           GROUP BY A.ITEM_CD, A.ORG_NUM;
        COMMIT;
        


        V_STEP_FLAG := 1;
        V_STEP_DESC := '提取2.2.2.6.3其他借款和现金流入至G2501_DATA_COLLECT_TMP中间表完成';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_DESC := '提取2.2.2.3大中型企业至G2501_DATA_COLLECT_TMP临时表';
        V_STEP_FLAG := 0;
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --ADD BY DJH 20240510  投资银行部 009817
    --2.2.2.3大中型企业
    --存量非标业务的一个月内到期的本金+应收利息+其他应收款,包括不良资产
    INSERT 
    INTO PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       '009817' AS ORG_NUM,
       'G25_1_1_2.2.2.3.A.2012' AS ITEM_NUM,
       NVL(SUM(ACCT_BAL_RMB + INTEREST_ACCURAL + QTYSK),0) AS ITEM_VAL
        FROM (SELECT A.ORG_NUM,
                     A.MATUR_DATE,
                     SUM(NVL(A.ACCT_BAL_RMB, 0)) AS ACCT_BAL_RMB, --本金
                     SUM(NVL(A.INTEREST_ACCURAL, 0)) AS INTEREST_ACCURAL, --其他应收款
                     SUM(NVL(A.QTYSK, 0)) AS QTYSK --其他应收款
                FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.DATA_DATE = I_DATADATE
                 AND FLAG = '09'
                 AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
                     A.MATUR_DATE - D_DATADATE_CCY <= 30)
               GROUP BY A.ORG_NUM, A.MATUR_DATE) A;
       COMMIT;


        V_STEP_FLAG := 1;
        V_STEP_DESC := '提取2.2.2.3大中型企业至G2501_DATA_COLLECT_TMP中间表完成';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
   ----------------------------------------------------------------------------------------------------------------


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据G2501至1104目标表CBRC_A_REPT_ITEM_VAL';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


      ----------------------结果表
    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD,
       IS_TOTAL
       )
      SELECT I_DATADATE AS DATA_DATE,
             --'990000' AS ORG_NUM,
             ORG_NUM,   --ADD BY DJH 20230718 恢复机构
             'CBRC' AS SYS_NAM,
             'G2501' AS REP_NUM,
             ITEM_NUM,
             SUM(T.ITEM_VAL) AS ITEM_VAL,
             '1' AS FLAG,
             'ALL' AS B_CURR_CD,
             CASE WHEN T.ORG_NUM = '990000' THEN  'N'
                  ELSE
                    'Y'
                  END AS IS_TOTAL  ----ADD BY DJH 20230718 含有总行不汇总,其他机构正常按指标汇总
        FROM PM_RSDATA.CBRC_G2501_DATA_COLLECT_TMP T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY ITEM_NUM,ORG_NUM;

    COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据G2501至1104目标表CBRC_A_REPT_ITEM_VAL完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

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
   
END proc_cbrc_idx2_g2501;
