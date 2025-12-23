CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g24(II_DATADATE  IN STRING --跑批日期
                                                 )
/******************************
  @AUTHOR:ZY
  @CREATE-DATE:2024-09-09
  @DESCRIPTION:G24
  @MODIFICATION HISTORY:
  G24最大百家金融机构同业融入情况表
  --JLBA202504300003_关于1104报送系统实现G24、G01、G18表自动化取数的需求 上线时间：20250619 修改人：石雨 提出人：苏桐
  需求编号：JLBA202505280011 上线日期：2025-09-19，修改人：狄家卉，提出人：赵翰君  修改原因：关于实现1104监管报送报表自动化采集加工的需求 增加009801清算中心(国际业务部)外币折人民币业务
  
目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_COLLECT_G24_TEMP
     CBRC_ORDER_TEMP
集市表：SMTMODS_L_ACCT_FUND_CDS_BAL
     SMTMODS_L_ACCT_FUND_MMFUND
     SMTMODS_L_ACCT_FUND_REPURCHASE
     SMTMODS_L_ACCT_LOAN
     SMTMODS_L_AGRE_LOAN_CONTRACT
     SMTMODS_L_CUST_BILL_TY
     SMTMODS_L_CUST_C
     SMTMODS_L_CUST_EXTERNAL_INFO
     SMTMODS_L_PUBL_RATE
  ********************************/
 IS
  V_PROCEDURE    VARCHAR(30); --当前储存过程名称
  V_REP_NUM      VARCHAR(30); --报表名称
  I_DATADATE     STRING; --数据日期(数值型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_ERRORDESC    VARCHAR(280); --错误内容
  D_DATADATE_CCY STRING; --数据日期(日期型)YYYYMMDD
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_CURR_LEVEL   NUMBER(20); ---变量序号
  V_SYSTEM       VARCHAR(30);
  
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    I_DATADATE := II_DATADATE;
  
    V_PROCEDURE    := UPPER('PROC_CBRC_IDX2_G24');
    V_REP_NUM      := 'G24';
	V_SYSTEM       := 'CBRC';
    D_DATADATE_CCY := I_DATADATE;
  
    V_STEP_FLAG := 1;
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
  
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_COLLECT_G24_TEMP';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_ORDER_TEMP';
  
    DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND REP_NUM = V_REP_NUM
       AND SYS_NAM = 'CBRC'
       AND FLAG = '2';
    COMMIT;
  
    V_STEP_FLAG := 2;
    V_STEP_DESC := 'G24 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    ------加工  附注：发行的同业存单 的金额，只有009820有这个业务
    INSERT INTO CBRC_COLLECT_G24_TEMP
      (DATA_DATE,
       ORG_NUM,
       CUST_ID,
       USCD,
       ORG_FULLNAME,
       ORG_TYPE_MCLS,
       ORG_TYPE_SCLS,
       FLAG,
       ORG_CODE,
       BALANCE_RMB)
      SELECT T.DATA_DATE,
             T.ORG_NUM, --内部机构号
             T.CUST_ID,
             T2.USCD,
             T2.ORG_FULLNAME,
             T2.ORG_TYPE_MCLS,
             T2.ORG_TYPE_SCLS,
             '10', --自定义标识，1表示发行的同业存单
             '', --预留的金融机构代码字段，业务反馈可以暂时不取
             SUM(T.FACE_VAL * T3.CCY_RATE) AS BALANCE_RMB --发行的同业存单金额
        FROM SMTMODS_L_ACCT_FUND_CDS_BAL T --存单投资与发行信息表
        LEFT JOIN SMTMODS_L_CUST_EXTERNAL_INFO T2 ---客户外部信息表
          ON T.CUST_ID = T2.CUST_ID
         AND T2.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE T3
          ON T3.BASIC_CCY = T.CURR_CD
         AND T3.FORWARD_CCY = 'CNY'
         AND T3.DATA_DATE = I_DATADATE
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND (SUBSTR(GL_ITEM_CODE, 1, 6) IN ('250202') OR
              GL_ITEM_CODE IN ('11010105', '15030105'))
         AND T.FACE_VAL > 0
         AND T.DATE_SOURCESD = '存单发行'
       GROUP BY T.DATA_DATE,
                T.ORG_NUM, --内部机构号
                T2.ORG_FULLNAME,
                T2.ORG_TYPE_MCLS,
                T.CUST_ID,
                T2.USCD,
                T2.ORG_TYPE_SCLS;
    COMMIT;
  
    ------加工  卖出回购 的金额，只有009804有这个业务
    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务2111卖出回购
    INSERT INTO CBRC_COLLECT_G24_TEMP
      (DATA_DATE,
       ORG_NUM,
       CUST_ID,
       USCD,
       ORG_FULLNAME,
       ORG_TYPE_MCLS,
       ORG_TYPE_SCLS,
       FLAG,
       ORG_CODE,
       BALANCE_RMB)
      SELECT A.DATA_DATE,
             A.ORG_NUM,
             A.CUST_ID,
             FR.USCD,
             FR.ORG_FULLNAME,
             FR.ORG_TYPE_MCLS,
             FR.ORG_TYPE_SCLS,
             '20', --自定义标识，2表示卖出回购
             '', ----预留的金融机构代码字段，业务反馈可以暂时不取
             SUM(A.BALANCE * U.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_REPURCHASE A ---回购信息表
        LEFT JOIN SMTMODS_L_CUST_EXTERNAL_INFO FR ---客户外部信息表
          ON A.DATA_DATE = FR.DATA_DATE
         AND A.CUST_ID = FR.CUST_ID
         AND FR.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
         AND U.DATA_DATE = I_DATADATE
       WHERE SUBSTR(A.GL_ITEM_CODE,1,6) = '211101' --债券卖出回购  211101
         AND A.DATA_DATE = I_DATADATE
        -- AND A.CURR_CD = 'CNY'
         AND A.BALANCE <> 0
       GROUP BY A.DATA_DATE,
                A.ORG_NUM,
                A.CUST_ID,
                FR.USCD,
                FR.ORG_FULLNAME,
                FR.ORG_TYPE_MCLS,
                FR.ORG_TYPE_SCLS;
    COMMIT;
  
    ------加工  其中：同业拆借(II开头) 、  其中：同业借款(LNZ开头的)  的金额，有009804和009820有这个业务
    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务2003拆入资金
    INSERT INTO CBRC_COLLECT_G24_TEMP
      (DATA_DATE,
       ORG_NUM,
       CUST_ID,
       ACCT_NUM,
       USCD,
       ORG_FULLNAME,
       ORG_TYPE_MCLS,
       ORG_TYPE_SCLS,
       FLAG,
       ORG_CODE,
       BALANCE_RMB)
      SELECT 
       T.DATA_DATE,
       T.ORG_NUM,
       FR.CUST_ID,
       CASE
         WHEN T.ORG_NUM = '009801' THEN
          'II' --009801清算中心外币业务都放入同业拆借里面
         WHEN ACCT_NUM LIKE 'II%' THEN
          'II'
         ELSE
          'LNZ'
       END AS ACCT_NUM,
       FR.USCD,
       FR.ORG_FULLNAME,
       FR.ORG_TYPE_MCLS,
       FR.ORG_TYPE_SCLS,
       '30', --自定义标识，2表示卖出回购
       '', ----预留的金融机构代码字段，业务反馈可以暂时不取
       SUM(T.BALANCE * C.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_MMFUND T --资金往来信息表
        LEFT JOIN SMTMODS_L_CUST_C BB
          ON T.CUST_ID = BB.CUST_ID
         AND BB.DATA_DATE = I_DATADATE
        LEFT JOIN (SELECT A.*,
                          ROW_NUMBER() OVER(PARTITION BY A.TYSHXYDM ORDER BY A.ECIF_CUST_ID) RN
                     FROM SMTMODS_L_CUST_BILL_TY A
                    WHERE A.DATA_DATE = I_DATADATE) TY --取法人统一社会信用代码
          ON BB.ID_NO = TY.TYSHXYDM
         AND TY.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C CC
          ON CC.TYSHXYDM = TY.LEGAL_TYSHXYDM
         AND CC.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_EXTERNAL_INFO FR ---客户外部信息表
          ON CC.DATA_DATE = FR.DATA_DATE
         AND CC.CUST_ID = FR.CUST_ID
         AND FR.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE C
          ON C.DATA_DATE = I_DATADATE
         AND C.BASIC_CCY = CURR_CD
         AND C.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(T.GL_ITEM_CODE, 1, 4) = '2003' ---同业拆放
         AND T.BALANCE <> 0
         AND T.ORG_NUM IN ('009804', '009820', '009801')
       GROUP BY T.DATA_DATE,
                CASE
                  WHEN T.ORG_NUM = '009801' THEN
                   'II' --009801清算中心外币业务都放入同业拆借里面
                  WHEN ACCT_NUM LIKE 'II%' THEN
                   'II'
                  ELSE
                   'LNZ'
                END,
                T.ORG_NUM,
                FR.CUST_ID,
                FR.USCD,
                FR.ORG_FULLNAME,
                FR.ORG_TYPE_MCLS,
                FR.ORG_TYPE_SCLS;
    COMMIT;
    
   -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务委托方同业代付 ：
   -- 委托方同业代付：指填报机构（委托方）委托其他金融机构（受托方）向企业客户付款，委托方在约定还款日偿还代付款项本息的资金融通款项。负债方：给金融机构利息
   --同业代付业务，也放入【同业拆放：其中：同业拆借】 中
       INSERT INTO CBRC_COLLECT_G24_TEMP
         (DATA_DATE,
          ORG_NUM,
          CUST_ID,
          USCD,
          ORG_FULLNAME,
          ORG_TYPE_MCLS,
          ORG_TYPE_SCLS,
          FLAG,
          ORG_CODE,
          BALANCE_RMB)
         SELECT A.DATA_DATE,
                '009801' AS ORG_NUM,
                A.CUST_ID,
                FR.USCD,
                FR.ORG_FULLNAME,
                FR.ORG_TYPE_MCLS,
                FR.ORG_TYPE_SCLS,
                '50', --自定义标识，5表示委托方同业代付
                '', 
                SUM(A.LOAN_ACCT_BAL * U.CCY_RATE)
           FROM SMTMODS_L_ACCT_LOAN A --贷款借据信息表
           LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT B
             ON A.ACCT_NUM = B.CONTRACT_NUM
            AND B.DATA_DATE = I_DATADATE
           LEFT JOIN SMTMODS_L_CUST_EXTERNAL_INFO FR ---客户外部信息表
             ON A.DATA_DATE = FR.DATA_DATE
            AND A.CUST_ID = FR.CUST_ID
            AND FR.DATA_DATE = I_DATADATE
           LEFT JOIN SMTMODS_L_PUBL_RATE U
             ON U.CCY_DATE = I_DATADATE
            AND U.BASIC_CCY = A.CURR_CD
            AND U.FORWARD_CCY = 'CNY'
            AND U.DATA_DATE = I_DATADATE
          WHERE A.DATA_DATE = I_DATADATE
            AND B.CP_ID = 'MR0020002'
            AND LOAN_ACCT_BAL <> 0
          GROUP BY A.DATA_DATE,
                   A.CUST_ID,
                   FR.USCD,
                   FR.ORG_FULLNAME,
                   FR.ORG_TYPE_MCLS,
                   FR.ORG_TYPE_SCLS;
    COMMIT;
  

  
    V_STEP_FLAG := 3;
    V_STEP_DESC := 'G24 加工顺序位置表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    ---顺序位置表 口径：按照 同业融入合计（D+G+H+I） 的值从大到小排序，其次按照附注：发行的同业存单的值排序
    INSERT INTO CBRC_ORDER_TEMP
      (DATA_DATE, ORG_NUM, CUST_ID, USCD, ORG_FULLNAME, BALANCE_RMB, RANK1)
      SELECT 
       T1.DATA_DATE,
       T1.ORG_NUM,
       T1.CUST_ID,
       T1.USCD,
       T1.ORG_FULLNAME,
       T1.BALANCE_RMB,
       ROW_NUMBER() OVER(PARTITION BY ORG_NUM ORDER BY T1.FLAG DESC, T1.BALANCE_RMB DESC) AS RANK1
        FROM (SELECT 
               T.DATA_DATE,
               T.ORG_NUM,
               T.CUST_ID,
               T.USCD,
               ORG_FULLNAME,
               '40' AS FLAG,
               SUM(BALANCE_RMB) BALANCE_RMB
                FROM CBRC_COLLECT_G24_TEMP T
               WHERE T.FLAG IN ('30', '20', '50') -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务委托方同业代付
               GROUP BY T.DATA_DATE,
                        T.ORG_NUM,
                        T.CUST_ID,
                        T.USCD,
                        ORG_FULLNAME
              UNION ALL
              SELECT 
               T.DATA_DATE,
               T.ORG_NUM,
               T.CUST_ID,
               T.USCD,
               T.ORG_FULLNAME,
               T.FLAG,
               SUM(BALANCE_RMB) BALANCE_RMB
                FROM CBRC_COLLECT_G24_TEMP T
               WHERE T.FLAG = '10'
                 AND NOT EXISTS (SELECT 
                       *
                        FROM CBRC_COLLECT_G24_TEMP T2
                       WHERE T2.FLAG IN ('30', '20', '50') -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务委托方同业代付
                         AND T.ORG_NUM = T2.ORG_NUM
                         AND T.USCD = T2.USCD)
               GROUP BY T.DATA_DATE,
                        T.ORG_NUM,
                        T.CUST_ID,
                        T.USCD,
                        T.ORG_FULLNAME,
                        T.FLAG) T1;
  
    COMMIT;
  
    ---加工指标的值
    V_STEP_FLAG := 4;
    V_STEP_DESC := 'G24 加工各个指标的值';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  
    FOR I_TMP IN 1 .. 100 LOOP
      V_CURR_LEVEL := I_TMP;
    
      ---加工机构类型
      INSERT INTO CBRC_A_REPT_ITEM_VAL
        (ITEM_VAL_V, --指标值
         DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         FLAG, --标志位
         IS_TOTAL)
        SELECT 
        DISTINCT (CASE
                   WHEN T.ORG_TYPE_MCLS = 'C' AND T.ORG_TYPE_SCLS IN ('C01') THEN
                    '政策性银行及开发银行'
                   WHEN T.ORG_TYPE_MCLS = 'C' AND
                        T.ORG_TYPE_SCLS IN ('C02', 'C14') THEN
                    '大型银行（含邮储银行）'
                   WHEN T.ORG_TYPE_MCLS = 'C' AND T.ORG_TYPE_SCLS IN ('C03') THEN
                    '全国股份制银行'
                   WHEN T.ORG_TYPE_MCLS = 'C' AND T.ORG_TYPE_SCLS IN ('C04') THEN
                    '城商行'
                   WHEN T.ORG_TYPE_MCLS = 'C' AND
                        T.ORG_TYPE_SCLS IN
                        ('C05', 'C06', 'C07', 'C08', 'C10') THEN
                    '农村中小金融机构'
                   WHEN T.ORG_TYPE_MCLS IN ('C', 'D', 'I') AND
                        T.ORG_TYPE_SCLS IN ('C09',
                                            'C13',
                                            'D03',
                                            'D04',
                                            'D05',
                                            'D06',
                                            'D07',
                                            'I01',
                                            'I02',
                                            'I03',
                                            'I04',
                                            'I05',
                                            'I06',
                                            'I07',
                                            'I08',
                                            'I09') THEN
                    '其他银行业金融机构'
                   WHEN T.ORG_TYPE_MCLS = 'C' AND T.ORG_TYPE_SCLS IN ('C11') THEN
                    '财务公司'
                   WHEN T.ORG_TYPE_MCLS = 'C' AND T.ORG_TYPE_SCLS IN ('C12') THEN
                    '外资银行'
                   WHEN T.ORG_TYPE_MCLS = 'D' AND T.ORG_TYPE_SCLS IN ('D01') THEN
                    '信托公司'
                   WHEN T.ORG_TYPE_MCLS = 'D' AND T.ORG_TYPE_SCLS IN ('D02') THEN
                    '金融资产投资公司'
                   WHEN T.ORG_TYPE_MCLS = 'E' AND T.ORG_TYPE_SCLS IN ('E05') THEN
                    '证券投资基金及其资管子公司'
                   WHEN T.ORG_TYPE_MCLS = 'E' AND
                        T.ORG_TYPE_SCLS IN ('E01',
                                            'E02',
                                            'E04', /*'E05',*/
                                            'E06',
                                            'E07',
                                            'E08',
                                            'E09') THEN
                    '券商及其资管子公司'
                   WHEN T.ORG_TYPE_MCLS = 'E' AND T.ORG_TYPE_SCLS IN ('E03') THEN
                    '期货及其资管子公司'
                   WHEN T.ORG_TYPE_MCLS = 'F' AND
                        T.ORG_TYPE_SCLS IN ('F01',
                                            'F02',
                                            'F03',
                                            'F04',
                                            'F05',
                                            'F06',
                                            'F07',
                                            'F08',
                                            'F09',
                                            'F10') THEN
                    '保险公司'
                   WHEN T.ORG_TYPE_MCLS = 'H' AND
                        T.ORG_TYPE_SCLS IN ('H01', 'H02') THEN
                    '金融资产投资公司'
                 END),
                 T.DATA_DATE,
                 T.ORG_NUM,
                 'CBRC',
                 V_REP_NUM,
                 CASE
                   WHEN T1.RANK1 = V_CURR_LEVEL THEN
                    'G24_' || V_CURR_LEVEL || '..A'
                 END ITEM_NUM,
                 '2',
                 'N'
          FROM CBRC_COLLECT_G24_TEMP T
         INNER JOIN CBRC_ORDER_TEMP T1
            ON T.DATA_DATE = T1.DATA_DATE
           AND T.ORG_NUM = T1.ORG_NUM
           AND T.USCD = T1.USCD
         WHERE T1.RANK1 = V_CURR_LEVEL
        --AND T.ORG_NUM <>'009820'
        ;
      COMMIT;
    
      --加工金融机构代码--JLBA202504300003_关于1104报送系统实现G24、G01、G18表自动化取数的需求 上线时间：20250619 修改人：石雨 提出人：苏桐
      INSERT INTO CBRC_A_REPT_ITEM_VAL
        (ITEM_VAL_V, --指标值
         DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         FLAG, --标志位
         IS_TOTAL)
        SELECT 
        DISTINCT (CASE
                   WHEN T.ORG_TYPE_MCLS = 'C' THEN
                    T2.FINA_ORG_CODE
                   ELSE
                    T.USCD
                 END), --非银行机构填报统一社会信用代码，银行机构填金融机构代码，银行机构无金融机构代码的，取空
                 T.DATA_DATE,
                 T.ORG_NUM,
                 'CBRC',
                 V_REP_NUM,
                 CASE
                   WHEN T1.RANK1 = V_CURR_LEVEL THEN
                    'G24_' || V_CURR_LEVEL || '..C'
                 END ITEM_NUM,
                 '2',
                 'N'
          FROM CBRC_COLLECT_G24_TEMP T
         INNER JOIN CBRC_ORDER_TEMP T1
            ON T.DATA_DATE = T1.DATA_DATE
           AND T.ORG_NUM = T1.ORG_NUM
           AND T.USCD = T1.USCD
          LEFT JOIN (SELECT A.*,
                            ROW_NUMBER() OVER(PARTITION BY A.TYSHXYDM ORDER BY A.ECIF_CUST_ID) RN
                       FROM SMTMODS_L_CUST_BILL_TY A
                      WHERE A.DATA_DATE = I_DATADATE) T2
            ON T2.TYSHXYDM = T.USCD
           AND T2.DATA_DATE = I_DATADATE
           AND T2.RN = 1
         WHERE T1.RANK1 = V_CURR_LEVEL;
      COMMIT;
    
      ---加工金融机构名称
      INSERT INTO CBRC_A_REPT_ITEM_VAL
        (ITEM_VAL_V, --指标值
         DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         FLAG, --标志位
         IS_TOTAL)
        SELECT 
        DISTINCT (T.ORG_FULLNAME),
                 T.DATA_DATE,
                 T.ORG_NUM,
                 'CBRC',
                 V_REP_NUM,
                 CASE
                   WHEN T1.RANK1 = V_CURR_LEVEL THEN
                    'G24_' || V_CURR_LEVEL || '..B'
                 END ITEM_NUM,
                 '2',
                 'N'
          FROM CBRC_COLLECT_G24_TEMP T
         INNER JOIN CBRC_ORDER_TEMP T1
            ON T.DATA_DATE = T1.DATA_DATE
           AND T.ORG_NUM = T1.ORG_NUM
           AND T.USCD = T1.USCD
         WHERE T1.RANK1 = V_CURR_LEVEL
        --AND T.ORG_NUM <>'009820'
        ;
      COMMIT;
    
      ---加工 其中：同业拆借 指标值
      INSERT INTO CBRC_A_REPT_ITEM_VAL
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         IS_TOTAL)
        SELECT 
         T.DATA_DATE,
         T.ORG_NUM,
         'CBRC',
         V_REP_NUM,
         CASE
           WHEN T1.RANK1 = V_CURR_LEVEL AND T.ACCT_NUM = 'II' THEN
            'G24_' || V_CURR_LEVEL || '..E'
         END ITEM_NUM,
         T.BALANCE_RMB,
         '2',
         'N'
          FROM CBRC_COLLECT_G24_TEMP T
         INNER JOIN CBRC_ORDER_TEMP T1
            ON T.DATA_DATE = T1.DATA_DATE
           AND T.ORG_NUM = T1.ORG_NUM
           AND T.USCD = T1.USCD
         WHERE T1.RANK1 = V_CURR_LEVEL
           AND T.FLAG = '30'
           AND T.ACCT_NUM = 'II'
        --AND T.ORG_NUM <>'009820'
        ;
      COMMIT;
    
      ---加工 其中：同业借款  指标值
      INSERT INTO CBRC_A_REPT_ITEM_VAL
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         IS_TOTAL)
        SELECT 
         T.DATA_DATE,
         T.ORG_NUM,
         'CBRC',
         V_REP_NUM,
         CASE
           WHEN T1.RANK1 = V_CURR_LEVEL AND T.ACCT_NUM = 'LNZ' THEN
            'G24_' || V_CURR_LEVEL || '..F'
         END ITEM_NUM,
         T.BALANCE_RMB,
         '2',
         'N'
          FROM CBRC_COLLECT_G24_TEMP T
         INNER JOIN CBRC_ORDER_TEMP T1
            ON T.DATA_DATE = T1.DATA_DATE
           AND T.ORG_NUM = T1.ORG_NUM
           AND T.USCD = T1.USCD
         WHERE T1.RANK1 = V_CURR_LEVEL
           AND T.FLAG = '30'
           AND T.ACCT_NUM = 'LNZ'
        --AND T.ORG_NUM <>'009820'
        ;
      COMMIT;
    
      ---加工 卖出回购  指标值
      INSERT INTO CBRC_A_REPT_ITEM_VAL
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         IS_TOTAL)
        SELECT 
         T.DATA_DATE,
         T.ORG_NUM,
         'CBRC',
         V_REP_NUM,
         CASE
           WHEN T1.RANK1 = V_CURR_LEVEL THEN
            'G24_' || V_CURR_LEVEL || '..H'
         END ITEM_NUM,
         T.BALANCE_RMB,
         '2',
         'N'
          FROM CBRC_COLLECT_G24_TEMP T
         INNER JOIN CBRC_ORDER_TEMP T1
            ON T.DATA_DATE = T1.DATA_DATE
           AND T.ORG_NUM = T1.ORG_NUM
           AND T.USCD = T1.USCD
         WHERE T1.RANK1 = V_CURR_LEVEL
           AND T.FLAG = '20'
        --AND T.ORG_NUM <>'009820'
        ;
      COMMIT;
    
      ---附注：发行的同业存单
      INSERT INTO CBRC_A_REPT_ITEM_VAL
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         IS_TOTAL)
        SELECT 
         T.DATA_DATE,
         T.ORG_NUM,
         'CBRC',
         V_REP_NUM,
         CASE
           WHEN T1.RANK1 = V_CURR_LEVEL THEN
            'G24_' || V_CURR_LEVEL || '..N'
         END ITEM_NUM,
         T.BALANCE_RMB,
         '2',
         'N'
          FROM CBRC_COLLECT_G24_TEMP T
         INNER JOIN CBRC_ORDER_TEMP T1
            ON T.DATA_DATE = T1.DATA_DATE
           AND T.ORG_NUM = T1.ORG_NUM
           AND nvl(T.USCD, '#') = nvl(T1.USCD, '#')
         WHERE T1.RANK1 = V_CURR_LEVEL
           AND T.FLAG = '10'
        --AND T.ORG_NUM <>'009820'
        ;
      COMMIT;
    
    END LOOP;
  
    ---全部同业合计
  
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       IS_TOTAL)
      SELECT 
       T.DATA_DATE,
       T.ORG_NUM,
       'CBRC',
       V_REP_NUM,
       'G24_102..N' ITEM_NUM,
       sum(BALANCE_RMB),
       '2',
       'N'
        FROM CBRC_COLLECT_G24_TEMP T
       where FLAG = '10'
         AND T.ORG_NUM = '009820'
       GROUP BY T.DATA_DATE, T.ORG_NUM;
    COMMIT;
    
     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君]  增加009801清算中心外币业务2003同业拆放
  
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       IS_TOTAL)
      SELECT 
       T.DATA_DATE,
       T.ORG_NUM,
       'CBRC',
       V_REP_NUM,
       'G24_102..D' ITEM_NUM,
       sum(BALANCE_RMB),
       '2',
       'N'
        FROM CBRC_COLLECT_G24_TEMP T
       where FLAG IN('30','50')
         AND T.ORG_NUM IN('009820','009801')
       GROUP BY T.DATA_DATE, T.ORG_NUM;
    COMMIT;
    
  
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       IS_TOTAL)
      SELECT 
       T.DATA_DATE,
       T.ORG_NUM,
       'CBRC',
       V_REP_NUM,
       'G24_102..F' ITEM_NUM,
       sum(BALANCE_RMB),
       '2',
       'N'
        FROM CBRC_COLLECT_G24_TEMP T
       where FLAG = '30'
         AND ORG_NUM ='009820'
         AND T.ACCT_NUM = 'LNZ'
       GROUP BY T.DATA_DATE, T.ORG_NUM;
  
    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君]  增加009801清算中心外币业务2003同业拆放  其中：同业拆借
    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君]  增加009801清算中心外币业务委托方同业代付

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       IS_TOTAL)
      SELECT 
       T.DATA_DATE,
       T.ORG_NUM,
       'CBRC',
       V_REP_NUM,
       'G24_102..E' ITEM_NUM,
       sum(BALANCE_RMB),
       '2',
       'N'
        FROM CBRC_COLLECT_G24_TEMP T
       where FLAG IN('30','50')
         AND ORG_NUM IN('009820','009801')
         AND T.ACCT_NUM = 'II'
       GROUP BY T.DATA_DATE, T.ORG_NUM;
    COMMIT;
    
    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君]  增加009801清算中心外币业务2111卖出回购
    
     INSERT INTO CBRC_A_REPT_ITEM_VAL
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        IS_TOTAL)
       SELECT 
        T.DATA_DATE,
        T.ORG_NUM,
        'CBRC',
        V_REP_NUM,
        'G24_102..H' ITEM_NUM,
        SUM(BALANCE_RMB),
        '2',
        'N'
         FROM CBRC_COLLECT_G24_TEMP T
        WHERE FLAG = '20'
        GROUP BY T.DATA_DATE, T.ORG_NUM;
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
   
END proc_cbrc_idx2_g24