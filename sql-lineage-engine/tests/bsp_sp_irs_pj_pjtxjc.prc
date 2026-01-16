CREATE OR REPLACE PROCEDURE BSP_SP_IRS_PJ_PJTXJC(IS_DATE     IN VARCHAR2,
                                                     OI_RETCODE  OUT INTEGER,
                                                     OI_RETCODE2 OUT VARCHAR2) AS
  ------------------------------------------------------------------------------------------------------
  -- 程序名
  --   SP_IRS_PJ_PJTXJC
  -- 用途:生成接口表 JS_201_CLGRDK 票据基础信息表
  -- 参数
  --    IS_DATE 输入变量，传入跑批日期
  --    OI_RETCODE 输出变量，用来标识存储过程执行过程中是否出现异常
  --    CAEATE BY USER AT 20200819
  --    MOD BY YANLINGBO AT 20200819
  ------------------------------------------------------------------------------------------------------

  VI_ERRORCODE NUMBER DEFAULT 0; --数值型  异常代码
  VS_TEXT      VARCHAR2(500) DEFAULT NULL; --字符型  过程描述
  /*VS_LAST_TEXT      VARCHAR2(10) DEFAULT NULL; --字符型  过程描述*/
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --字符型  存储过程调用用户
  VS_PROCEDURE_NAME VARCHAR2(32) DEFAULT NULL; --字符型  存储过程名称
  VS_STEP           VARCHAR2(10); --存储过程执行步骤标志
  /* NUM               INTEGER;*/
  VS_LAST_TEXT VARCHAR2(500) DEFAULT NULL; --字符型  过程描述

BEGIN
  VS_TEXT := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD');
  /*VS_LAST_TEXT := TO_CHAR(LAST_DAY(ADD_MONTHS(TO_DATE(IS_DATE, 'YYYYMMDD'), -1)),'YYYYMMDD'); --上月月末*/
  VS_LAST_TEXT := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') - 1, 'YYYYMMDD');
  -- 记录日志使用
  SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
  VS_PROCEDURE_NAME := 'SP_IRS_PJ_PJTXJC';
  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
  -------------------------------------------------------------------------
  /* --删除当天日志
  DELETE FROM RUN_STEP_LOG WHERE TAB_NAME = 'IRS_GRDKYEXXB' and to_char(RUN_TIME,'yyyymmdd')=to_char(sysdate,'yyyymmdd');
   COMMIT;*/
  --创建分区
  /*SELECT COUNT(1)
      INTO NUM
      FROM USER_TAB_PARTITIONS
     WHERE TABLE_NAME = 'IE_PJ_PJTXJC'
       AND PARTITION_NAME = 'IE_PJ_PJTXJC_' || IS_DATE;
  */
  /*  --如果没有建立分区，则增加分区
    IF (NUM = 0) THEN
      EXECUTE IMMEDIATE 'ALTER TABLE datacore.IRS_GRDKYEXXB ADD PARTITION IRS_GRDKYEXXB_' ||
                        IS_DATE || ' VALUES (' || IS_DATE || ')';
    END IF;
  
    EXECUTE IMMEDIATE 'ALTER TABLE datacore.IRS_GRDKYEXXB TRUNCATE PARTITION IRS_GRDKYEXXB_' ||
                      IS_DATE;
  */

  /* INSERT INTO RUN_STEP_LOG VALUES (1, 'IE_PJ_PJTXJC', '', SYSDATE);
    COMMIT;
  */
  /* EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_PJ_PJTXJC_TMP1';
  INSERT INTO DATACORE_IE_PJ_PJTXJC_TMP1
   SELECT DISTINCT CUST_ID
   FROM SMTMODS.L_CUST_P
   WHERE DATA_DATE =IS_DATE
   AND ORG_NUM NOT LIKE '0215%';
   COMMIT;
   INSERT INTO DATACORE_IE_PJ_PJTXJC_TMP1
   SELECT DISTINCT CUST_ID
   FROM SMTMODS.L_CUST_C
   WHERE DATA_DATE =IS_DATE
   AND ORG_NUM NOT LIKE '0215%';
   COMMIT;*/

  /*EXECUTE IMMEDIATE 'TRUNCATE TABLE CUST_0215';*/
  EXECUTE IMMEDIATE 'TRUNCATE TABLE l_cust_bill_ty_test';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE L_ACCT_LOAN_LAST';

  --前一天的借据表信息
  INSERT INTO L_ACCT_LOAN_LAST
    SELECT /* +parallel(8)*/
     T.LOAN_NUM, T.LOAN_ACCT_BAL, T.ACCT_STS
      FROM SMTMODS.L_ACCT_LOAN T
     where t.data_date = VS_LAST_TEXT
       and (ITEM_CD IN ('13010101', '13010104') --以摊余成本计量的贴现
           OR ITEM_CD IN ('13010401', '13010405') --以公允价值计量变动计入权益的贴现
           OR ITEM_CD IN ('13010201', '13010204') --以摊余成本计量的转贴现
           OR ITEM_CD IN ('13010501', '13010505'));

  --L_CUST_BILL_TY表中客户号去重
/*  INSERT INTO L_CUST_BILL_TY_TEST(CUST_ID,DATA_DATE,FINA_CODE_NEW)
    SELECT B.CUST_ID, B.DATA_DATE, B.FINA_CODE_NEW
      FROM (SELECT A.*,
                   ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.CUST_ID) RN
              FROM SMTMODS.L_CUST_BILL_TY A
             WHERE A.DATA_DATE = IS_DATE) B
     WHERE B.RN = '1';*/


INSERT INTO L_CUST_BILL_TY_TEST
  SELECT data_date,
         org_num,
         cust_id,
         legal_name,
         fina_org_code,
         fina_code_new,
         fina_org_name,
         capital_amt,
         borrower_register_addr,
         tyshxydm,
         organizationcode,
         ecif_cust_id,
         legal_flag,
         legal_tyshxydm,
         cbrc_code,
         nation_cd,
         org_area,
         aswift_code,
         cust_bank_cd,
         corp_scale,
         corp_hold_type,
         bussines_type,
         fina_olic_num,
         cus_risk_lev,
         cust_short_name,
         rn
  
    FROM (SELECT A.*,
                 ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.CUST_ID) RN
            FROM SMTMODS.L_CUST_BILL_TY A
           WHERE A.DATA_DATE = IS_DATE) B
   WHERE B.RN = '1';
 
  /*INSERT INTO CUST_0215
    SELECT A.CUST_ID
      FROM SMTMODS.L_CUST_P A
     WHERE A.ORG_NUM IS NOT NULL
       AND A.DATA_DATE = IS_DATE;
  COMMIT;
  
  INSERT INTO CUST_0215
    SELECT A.CUST_ID
      FROM SMTMODS.L_CUST_C A
     WHERE A.ORG_NUM IS NOT NULL
       AND A.DATA_DATE = IS_DATE;
  COMMIT;*/

  EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_PJ_PJTXJC';
  ---不含同业 转贴现
  INSERT /* +append*/
  INTO DATACORE_IE_PJ_PJTXJC
    (datadate, --1数据日期
     corpid, --2内部机构号
     custid, --3客户号
     ORGTPCODE, --4金融机构类型代码
     contractnum, --5业务编码
     billbusitype, --6票据融资业务类型
     startdate, --7起始日期
     maturedate, --8到期日期
     billtermtype, --9票据融资期限类型
     REALRATE --10贴现利率
     )
    SELECT /* +parallel(8)*/
     T.DATA_DATE, --1数据日期
     T.ORG_NUM, --2机构号
     T.CUST_ID, --3客户号
     NVL(A.FINA_CODE_NEW, TRIM(C.FINA_CODE_NEW)) as ORGTPCODE, --4金融机构类型代码
     T.LOAN_NUM, --5贷款编号  （业务编码）
     CASE
       WHEN T.ITEM_CD IN ('13010101', '13010401') THEN
        'A01' --贴现 银行承兑汇票
       WHEN T.ITEM_CD IN ('13010104', '13010405') THEN
        'A02' --贴现 商业承兑汇票
       WHEN T.ITEM_CD IN ('13010201', '13010501') THEN
        'B01' --买断式转贴现 银行承兑汇票
       WHEN T.ITEM_CD IN ('13010204', '13010505') THEN
        'B02' --买断式转贴现 商业承兑汇票
     END ITEM_CD, --6票据融资期限类型      20240906  修改取数范围 增加商业承兑汇票逻辑
     TO_CHAR(T.DRAWDOWN_DT, 'YYYY-MM-DD'), --7放款日期（起始日期）
     CASE WHEN TO_CHAR(T.DRAWDOWN_DT, 'YYYY-MM-DD') = VS_TEXT AND T.LOAN_ACCT_BAL = 0 AND T.ACCT_STS = '3'   --20250207 当天放款当天结清的没有结清日期字段，给到当天日期
       THEN VS_TEXT 
         ELSE TO_CHAR(T.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') END, --8实际到期日期（结束日期）  
     case
       when months_between(T.ACTUAL_MATURITY_DT, T.DRAWDOWN_DT) <= 3 then
        '01'
       when months_between(T.ACTUAL_MATURITY_DT, T.DRAWDOWN_DT) > 3 and
            months_between(T.ACTUAL_MATURITY_DT, T.DRAWDOWN_DT) <= 6 then
        '02'
       when months_between(T.ACTUAL_MATURITY_DT, T.DRAWDOWN_DT) > 6 and
            months_between(T.ACTUAL_MATURITY_DT, T.DRAWDOWN_DT) <= 12 then
        '03'
     
     end, --9票据融资期限类型
     T.REAL_INT_RAT as REALRATE --10贴现利率
      FROM SMTMODS.L_ACCT_LOAN T
    /*INNER JOIN DATACORE_IE_PJ_PJTXJC_TMP1 T1
    ON T.CUST_ID = T1.CUST_ID*/
      LEFT JOIN SMTMODS.L_CUST_C A
        ON T.CUST_ID = A.CUST_ID
       AND A.DATA_DATE = IS_DATE
      LEFT JOIN L_CUST_BILL_TY_TEST C ---MDF BY CHM 20230309
        ON T.CUST_ID = C.CUST_ID
       AND C.DATA_DATE = IS_DATE
      LEFT JOIN L_ACCT_LOAN_LAST D
        ON T.LOAN_NUM = D.LOAN_NUM
    /*INNER JOIN CUST_0215 E
    ON T.CUST_ID = E.CUST_ID*/
     WHERE T.DATA_DATE = IS_DATE
          --AND T.ORG_NUM NOT LIKE '0215%'
          --and item_cd in ('12901', '12905', '12902', '12906')
       AND (T.ITEM_CD IN ('13010101', '13010104') --以摊余成本计量的贴现
           OR T.ITEM_CD IN ('13010401', '13010405') --以公允价值计量变动计入权益的贴现
           OR T.ITEM_CD IN ('13010201', '13010204') --以摊余成本计量的转贴现
           OR T.ITEM_CD IN ('13010501', '13010505')) --以公允价值计量变动计入权益的转贴现    20240906  修改取数范围
       AND (T.LOAN_ACCT_BAL > 0 OR
           TO_CHAR(T.FINISH_DT, 'YYYYMMDD') = IS_DATE OR
           (TO_CHAR(T.DRAWDOWN_DT, 'YYYY-MM-DD') = VS_TEXT AND T.LOAN_ACCT_BAL = 0)) --add by chm 20230428 取入当天发生但余额为0的贴现，由于时点问题，有放款，未进余额
    --AND T.LOAN_ACCT_BAL > 0
    ;

  COMMIT;

  --当月结清的数据
  INSERT /* +append*/
  INTO DATACORE_IE_PJ_PJTXJC
    (datadate, --1数据日期
     corpid, --2内部机构号
     custid, --3客户号
     ORGTPCODE, --4金融机构类型代码
     contractnum, --5业务编码
     billbusitype, --6票据融资业务类型
     startdate, --7起始日期
     maturedate, --8到期日期
     billtermtype, --9票据融资期限类型
     REALRATE --10贴现利率
     )
    SELECT /* +parallel(8)*/
     T.DATA_DATE, --1数据日期
     T.ORG_NUM, --2机构号
     T.CUST_ID, --3客户号
     NVL(A.FINA_CODE_NEW, TRIM(C.FINA_CODE_NEW)) as ORGTPCODE, --4金融机构类型代码
     T.LOAN_NUM, --5贷款编号  （业务编码）
     CASE
       WHEN T.ITEM_CD IN ('13010101', '13010401') THEN
        'A01' --贴现 银行承兑汇票
       WHEN T.ITEM_CD IN ('13010104', '13010405') THEN
        'A02' --贴现 商业承兑汇票
       WHEN T.ITEM_CD IN ('13010201', '13010501') THEN
        'B01' --买断式转贴现 银行承兑汇票
       WHEN T.ITEM_CD IN ('13010204', '13010505') THEN
        'B02' --买断式转贴现 商业承兑汇票
     END ITEM_CD, --6票据融资期限类型      20240906  修改取数范围 增加商业承兑汇票逻辑
     TO_CHAR(T.DRAWDOWN_DT, 'YYYY-MM-DD'), --7放款日期（起始日期）
     TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD'), --8实际到期日期（结束日期）  由于上游数据存在问题，结清数据取余额为0的当天
     case
       when months_between(T.ACTUAL_MATURITY_DT, T.DRAWDOWN_DT) <= 3 then
        '01'
       when months_between(T.ACTUAL_MATURITY_DT, T.DRAWDOWN_DT) > 3 and
            months_between(T.ACTUAL_MATURITY_DT, T.DRAWDOWN_DT) <= 6 then
        '02'
       when months_between(T.ACTUAL_MATURITY_DT, T.DRAWDOWN_DT) > 6 and
            months_between(T.ACTUAL_MATURITY_DT, T.DRAWDOWN_DT) <= 12 then
        '03'
     
     end, --9票据融资期限类型
     T.REAL_INT_RAT as REALRATE --10贴现利率
      FROM SMTMODS.L_ACCT_LOAN T
    /*INNER JOIN DATACORE_IE_PJ_PJTXJC_TMP1 T1
    ON T.CUST_ID = T1.CUST_ID*/
      LEFT JOIN SMTMODS.L_CUST_C A
        ON T.CUST_ID = A.CUST_ID
       AND A.DATA_DATE = IS_DATE
      LEFT JOIN L_CUST_BILL_TY_TEST C ---MDF BY CHM 20230309
        ON T.CUST_ID = C.CUST_ID
       AND C.DATA_DATE = IS_DATE
      LEFT JOIN L_ACCT_LOAN_LAST D
        ON T.LOAN_NUM = D.LOAN_NUM
    /*INNER JOIN CUST_0215 E
    ON T.CUST_ID = E.CUST_ID*/
     WHERE T.DATA_DATE = IS_DATE
          --AND T.ORG_NUM NOT LIKE '0215%'
          --and item_cd in ('12901', '12905', '12902', '12906')
       AND (T.ITEM_CD IN ('13010101', '13010104') --以摊余成本计量的贴现
           OR T.ITEM_CD IN ('13010401', '13010405') --以公允价值计量变动计入权益的贴现
           OR T.ITEM_CD IN ('13010201', '13010204') --以摊余成本计量的转贴现
           OR T.ITEM_CD IN ('13010501', '13010505')) --以公允价值计量变动计入权益的转贴现    20240906  修改取数范围
       AND (T.FINISH_DT IS NULL OR TO_CHAR(T.FINISH_DT,'YYYYMMDD') > IS_DATE)
       AND T.LOAN_ACCT_BAL = 0
       AND D.LOAN_ACCT_BAL <> 0 --20241016   结清余额为0，但是没有结清日期，对比前一天的余额
       AND T.ACCT_STS = '3' --账户状态为结清
    --AND T.LOAN_ACCT_BAL > 0
    ;

  SP_IRS_PARTITIONS(IS_DATE, 'IE_PJ_PJTXJC', OI_RETCODE);
  INSERT INTO IE_PJ_PJTXJC
    (DATADATE, --1数据日期
     CORPID, --2内部机构号
     CUSTID, --3客户号
     ORGTPCODE, --4金融机构类型代码
     CONTRACTNUM, --5业务编码
     BILLBUSITYPE, --6票据融资业务类型
     STARTDATE, --7起始日期
     MATUREDATE, --8到期日期
     BILLTERMTYPE, --9票据融资期限类型
     REALRATE, --10贴现利率
     CJRQ, --11采集日期
     NBJGH, --12内部机构号
     /*REPORT_ID，          --13报送ID*/
     BIZ_LINE_ID, --14业务条线
     VERIFY_STATUS, --15校验状态
     BSCJRQ, --16报送周期
     IRS_CORP_ID --17法人机构ID
     )
    SELECT VS_TEXT AS DATADATE, --1数据日期
           CORPID, --2内部机构号
           CUSTID, --3客户号
           /*CASE
           WHEN    ORGTPCODE='1' THEN 'C01'
           WHEN    ORGTPCODE='3' THEN 'C02'
           WHEN    ORGTPCODE='4' THEN 'C03'
           WHEN    ORGTPCODE='5' THEN 'C04'
           WHEN    ORGTPCODE='6' THEN 'C05'
           WHEN    ORGTPCODE='7' THEN 'C06'
           WHEN    ORGTPCODE='8' THEN 'C09'
           WHEN    ORGTPCODE='10' THEN 'C07'
           WHEN    ORGTPCODE='11' THEN 'C10'
           WHEN    ORGTPCODE='12' THEN 'D05'
           WHEN    ORGTPCODE='13' THEN 'C12'
           WHEN    ORGTPCODE='15' THEN 'C11'
           WHEN    ORGTPCODE='16' THEN 'D01'
           WHEN    ORGTPCODE='17' THEN 'D03'
           WHEN    ORGTPCODE='18' THEN 'D04'
           WHEN    ORGTPCODE='19' THEN 'D06'
           WHEN    ORGTPCODE='20' THEN 'D07'
           WHEN    ORGTPCODE='22' THEN 'E'
           WHEN    ORGTPCODE='27' THEN 'Z'
           WHEN    B.CUST_ID IS NOT NULL
           THEN    B.JRJG
           END*/
           NVL(ORGTPCODE, B.JRJG), --4金融机构类型代码  ---MDF BY CHM 20230309
           CONTRACTNUM, --5业务编码
           BILLBUSITYPE, --6票据融资业务类型
           STARTDATE, --7起始日期
           MATUREDATE, --8到期日期
           BILLTERMTYPE, --9票据融资期限类型
           REALRATE, --10贴现利率
           IS_DATE AS CJRQ, --11采集日期
           CORPID AS NBJGH, --12内部机构号
           '99' AS BIZ_LINE_ID, --14业务条线
           '' AS VERIFY_STATUS, --15校验状态
           '' AS BSCJRQ, --16报送周期
           CASE
             WHEN CORPID LIKE '51%' THEN
              '510000'
             WHEN CORPID LIKE '52%' THEN
              '520000'
             WHEN CORPID LIKE '53%' THEN
              '530000'
             WHEN CORPID LIKE '54%' THEN
              '540000'
             WHEN CORPID LIKE '55%' THEN
              '550000'
             WHEN CORPID LIKE '56%' THEN
              '560000'
             WHEN CORPID LIKE '57%' THEN
              '570000'
             WHEN CORPID LIKE '58%' THEN
              '580000'
             WHEN CORPID LIKE '59%' THEN
              '590000'
             WHEN CORPID LIKE '60%' THEN
              '600000'
             ELSE
              '990000'
           END --法人机构ID
      FROM DATACORE_IE_PJ_PJTXJC A
      LEFT JOIN DATACORE_tmp_tyxx_jrjg B
        ON A.CUSTID = B.CUST_ID
     WHERE DATADATE = IS_DATE;

  COMMIT;
  -------------------------------------------------------------------------
  OI_RETCODE := 0; --设置异常状态为0 成功状态
  --返回中文描述
  OI_RETCODE2 := '成功!';
  /*COMMIT; --非特殊处理只能在最后一次提交*/
  -- 结束日志
  VS_STEP := 'END';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
EXCEPTION
  WHEN OTHERS THEN
    --如果出现异常
    VI_ERRORCODE := SQLCODE; --设置异常代码
    VS_TEXT      := VS_STEP || '|' || IS_DATE || '|' ||
                    SUBSTR(SQLERRM, 1, 200); --设置异常描述
    ROLLBACK; --数据回滚
    OI_RETCODE := -1; --设置异常状态为-1
    --插入日志表，记录错误
    --返回中文描述
  
    OI_RETCODE2 := SUBSTR(SQLERRM, 1, 200);
    SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
END;
/

