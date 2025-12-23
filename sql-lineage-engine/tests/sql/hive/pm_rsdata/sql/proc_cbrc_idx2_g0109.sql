CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g0109(II_DATADATE IN STRING --跑批日期
                                               )
/******************************
  @author:fanxiaoyu  / manan
  @create-date:2015-09-20
  @description:G0109
  @modification history:
  m0.20150919-fanxiaoyu-G0109 月跑批
  m1.2021129 shiyu 新增月日均铺底数据逻辑，只用于测试和第一次上线
     铺底数据存放在临时表TMP_G0109_ITEM_VAL_TMP
  -- 需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求
             上线日期：2025-05-27，修改人：巴启威，提出人：王曦若 ，修改内容：调整代理国库业务会计科目

  [JLBA202507210012_关于调整财政性存款及一般性存款相关科目统计方式的相关需求][提出人：于佳禾][上线时间：20250918][修改人：石雨][修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]


目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_TMP_G0109_A_REPT_ITEM_VAL
视图表：SMTMODS_V_PUB_IDX_FINA_GL
集市表：SMTMODS_L_PUBL_RATE


  *******************************/
 IS
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE    VARCHAR(50); --当前储存过程名称
  V_REP_NUM      VARCHAR(30); --报表名称
  I_DATADATE     STRING; --数据日期(数值型)YYYYMMDD
  V_DATADATE     VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  D_DATADATE_CCY STRING; --数据日期(日期型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  V_ERRORCODE    VARCHAR(100); --错误编码
  V_ERRORDESC    VARCHAR(400); --错误内容
  I_MONTH_NUM    INTEGER; --本月天数
  II_STATUS    INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM      VARCHAR(30);
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_DESC := '参数初始化处理';
	I_DATADATE     := II_DATADATE;
    V_DATADATE     := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYY-MM-DD');
    D_DATADATE_CCY := I_DATADATE;
    V_PROCEDURE    := UPPER('PROC_CBRC_IDX2_G0109');
    V_REP_NUM      := 'G01_9';
	V_SYSTEM       := 'CBRC';
    I_MONTH_NUM    := TO_NUMBER(SUBSTR(I_DATADATE, -2));

    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '1.月日均存款余额   逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --==================================================
    --   G0109 1.从明细取数的数据需要个性化重新加工，加工前先清理数据
    --==================================================
    --因为L_FINA_GL无整月数据，将铺底数据导入临时表CBRC_TMP_G0109_ITEM_VAL_TMP=20230201,只适用于测试和20230228第一次上线
    --if 判断条件需按实际情况修改
     
      EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP_G0109_A_REPT_ITEM_VAL';

    COMMIT;

    DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND REP_NUM = V_REP_NUM
       AND FLAG = '2';
    COMMIT;
    --==================================================
    --   G0109 2.月日均存款余额 月日均存款应当以每日存款相加，除以当月天数，故应从总账表中取，并且此步骤仅计算总计值即可，后续统一除以天数。--20170525 manan
    --==================================================
    --G01_9_2..A  月日均存款余额 人民币
    INSERT INTO CBRC_TMP_G0109_A_REPT_ITEM_VAL
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
             'G01_9_2..A' AS ITEM_NUM, --指标号
             SUM(CREDIT_BAL) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM   SMTMODS_V_PUB_IDX_FINA_GL
       WHERE DATA_DATE BETWEEN SUBSTR(I_DATADATE, 0, 6) || '01' AND  I_DATADATE
         AND CURR_CD = 'CNY'
         AND ITEM_CD IN ('20110201',
                         '20110205',
                         '20110202',
                         '20110203',
                         '20110204',
                         '20110211',
                         '20110101',
                         '20110102',
                         '20110103',
                         '20110104',
                         '20110105',
                         '20110106',
                         '20110107',
                         '20110108',
                         '20110109',
                         '20110111',
                         '20110206',
                         '20130101',
                         '20130201',
                         '20130301',
                         '20140101',
                         '20140201',
                         '20140301',
                         '20110114',
                         '20110115',
                         '20110209',
                         '20110210',
                         '20110110',
                         '20110208',
                         '20110113',
                         '20110701',
                         '20100101',-- 需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：巴启威，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
                         '20110207',
                         '20110112',
                         '22410101','20110301','20110302','20110303','22410102','20080101','20090101' ,--[JLBA202507210012][石雨][修改内容：22410101单位久悬未取款 22410102个人久悬未取款、201103（财政性存款）调整为 一般单位活期存款]
                         '20120106',--保险业金融机构存放款项
                         '20120204') --保险业金融机构存放款项
       GROUP BY I_DATADATE, ORG_NUM, V_REP_NUM;

    COMMIT;

    --G01_9_2..B  月日均存款余额  外币折人民币
   
    --20170826 manan 修改，日元、美元、欧元、港币 直接转人民币，乘以月末最后一天汇率；
    --除了日元、美元、欧元、港币以外的币种 需要转美元后，再转人民币，乘以月末最后一天汇率
    
    INSERT INTO CBRC_TMP_G0109_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
    --日元、美元、欧元、港币 直接转人民币，乘以月末最后一天汇率
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_9_2..B' AS ITEM_NUM, --指标号
             SUM(T.CREDIT_BAL * LPR.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM  SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE LPR
          ON LPR.DATA_DATE = I_DATADATE
         AND T.CURR_CD = LPR.BASIC_CCY
       WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 0, 6) || '01' AND I_DATADATE
         AND T.CURR_CD in ('JPY', 'USD', 'EUR', 'HKD') --<> 'CNY'
         AND LPR.FORWARD_CCY = 'CNY'
         AND ITEM_CD IN ('20110201',
                         '20110205',
                         '20110202',
                         '20110203',
                         '20110204',
                         '20110211',
                         '20110101',
                         '20110102',
                         '20110103',
                         '20110104',
                         '20110105',
                         '20110106',
                         '20110107',
                         '20110108',
                         '20110109',
                         '20110111',
                         '20110206',
                         '20130101',
                         '20130201',
                         '20130301',
                         '20140101',
                         '20140201',
                         '20140301',
                         '20110114',
                         '20110115',
                         '20110209',
                         '20110210',
                         '20110110',
                         '20110208',
                         '20110113',
                         '20110701',
                         '20100101',-- 需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：巴启威，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
                         '20110207',
                         '20110112',
                         '22410101','20110301','20110302','20110303','22410102','20080101','20090101' ,--[JLBA202507210012][石雨][修改内容：22410101单位久悬未取款 22410102个人久悬未取款、201103（财政性存款）调整为 一般单位活期存款]
                         '20120106',--保险业金融机构存放款项
                         '20120204') --保险业金融机构存放款项
       GROUP BY I_DATADATE, ORG_NUM, V_REP_NUM
      --除了日元、美元、欧元、港币以外的币种 需要转美元后，再转人民币，乘以月末最后一天汇率
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_9_2..B' AS ITEM_NUM, --指标号
             SUM(USD_TMP.ITEM_VAL * L1.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM (SELECT ORG_NUM AS ORG_NUM, --机构号
                     SUM(T.CREDIT_BAL * LPR.CCY_RATE) AS ITEM_VAL, --指标值
                     'USD' AS CURR_CD --币种
                FROM 
                SMTMODS_V_PUB_IDX_FINA_GL T
                LEFT JOIN SMTMODS_L_PUBL_RATE LPR
                  ON LPR.DATA_DATE = I_DATADATE
                 AND T.CURR_CD = LPR.BASIC_CCY
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 0, 6) || '01' AND
                     I_DATADATE
                 AND T.CURR_CD not in ('JPY', 'USD', 'EUR', 'HKD', 'CNY','BWB')
                 AND LPR.FORWARD_CCY = 'USD'
                 AND ITEM_CD IN ('20110201',
                         '20110205',
                         '20110202',
                         '20110203',
                         '20110204',
                         '20110211',
                         '20110101',
                         '20110102',
                         '20110103',
                         '20110104',
                         '20110105',
                         '20110106',
                         '20110107',
                         '20110108',
                         '20110109',
                         '20110111',
                         '20110206',
                         '20130101',
                         '20130201',
                         '20130301',
                         '20140101',
                         '20140201',
                         '20140301',
                         '20110114',
                         '20110115',
                         '20110209',
                         '20110210',
                         '20110110',
                         '20110208',
                         '20110113',
                         '20110701',
                         '20100101',-- 需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：巴启威，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
                         '20110207',
                         '20110112',
                         '22410101','20110301','20110302','20110303','22410102' ,'20080101','20090101',--[JLBA202507210012][石雨][修改内容：22410101单位久悬未取款 22410102个人久悬未取款、201103（财政性存款）调整为 一般单位活期存款]
                         '20120106',--保险业金融机构存放款项
                         '20120204') --保险业金融机构存放款项
               GROUP BY ORG_NUM) USD_TMP
        LEFT JOIN SMTMODS_L_PUBL_RATE L1
          ON L1.DATA_DATE = I_DATADATE
         AND USD_TMP.CURR_CD = L1.BASIC_CCY
       WHERE L1.FORWARD_CCY = 'CNY'
       GROUP BY ORG_NUM, V_REP_NUM, I_DATADATE;
    --修改完成
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '2.月日均存款余额   逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 2;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '4.月日均贷款余额   逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --==================================================
    --   G0109 4.月日均贷款余额  月日均贷款应当以每日贷款相加，除以当月天数，故应从总账表中取，并且此步骤仅计算总计值即可，后续统一除以天数。--20170525 manan
    --==================================================
    --G01_9_4..A  月日均贷款余额 人民币
    INSERT INTO CBRC_TMP_G0109_A_REPT_ITEM_VAL
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
             'G01_9_4..A' AS ITEM_NUM, --指标号
             SUM(DEBIT_BAL) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM 
        SMTMODS_V_PUB_IDX_FINA_GL
       WHERE DATA_DATE BETWEEN SUBSTR(I_DATADATE, 0, 6) || '01' AND
             I_DATADATE
         AND CURR_CD = 'CNY'
         AND ITEM_CD IN ('13030101', /*'129'*/
                         '13030102',
                         '13030103',
                         '13030201',
                         '13030202',
                         '13030203',
                         '13030301',
                         '13030302',
                         '13030303',
                         '13050101',
                         '13050102',
                         '13050103',
                         '13060101',
                         '13060102',
                         '13060103',
                         '13060201',
                         '13060202',
                         '13060203',
                         '13060301',
                         '13060302',
                         '13060303',
                         '13060401',
                         '13060402',
                         '13060403',
                         '13060501',
                         '13060502',
                         '13060503',
                         '13010101', --以摊余成本计量的银行承兑汇票贴现面值
                         '13010103', --以摊余成本计量的银行承兑汇票贴现已减值
                         '13010104', --以摊余成本计量的商业承兑汇票贴现面值
                         '13010106', --以摊余成本计量的商业承兑汇票贴现已减值
                         '13010201', --以摊余成本计量的银行承兑汇票转贴现面值
                         '13010203', --以摊余成本计量的银行承兑汇票转贴现已减值
                         '13010204', --以摊余成本计量的商业承兑汇票转贴现面值
                         '13010206', --以摊余成本计量的商业承兑汇票转贴现已减值
                         '13010301', --买入外币票据面值
                         '13010303', --买入外币票据已减值
                        /* '1290401', --以摊余成本计量的自承自贴转贴现面值
                         '1290403', --以摊余成本计量的自承自贴转贴现已减值*/
                         '13010401', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票贴现面值
                         '13010403', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票贴现已减值
                         '13010405', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票贴现面值
                         '13010407', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票贴现已减值
                         '13010501', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票转贴现面值
                         '13010503', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票转贴现已减值
                         '13010505', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票转贴现面值
                         '13010507' --以公允价值计量且其变动计入其他综合收益的商业承兑汇票转贴现已减值
          /*               '1290701', --以公允价值计量且其变动计入其他综合收益的自承自贴转贴现面值
                         '1290703'*/) --以公允价值计量且其变动计入其他综合收益的自承自贴转贴现已减值
       GROUP BY I_DATADATE, ORG_NUM, V_REP_NUM;

    COMMIT;

    --G01_9_4..B  月日均贷款余额  外币折人民币

    --20170826 manan 修改，日元、美元、欧元、港币 直接转人民币，乘以月末最后一天汇率；
    --除了日元、美元、欧元、港币以外的币种 需要转美元后，再转人民币，乘以月末最后一天汇率
    INSERT INTO CBRC_TMP_G0109_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
    --日元、美元、欧元、港币 直接转人民币，乘以月末最后一天汇率
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_9_4..B' AS ITEM_NUM, --指标号
             SUM(T.DEBIT_BAL * LPR.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM 
        SMTMODS_V_PUB_IDX_FINA_GL t
        LEFT JOIN SMTMODS_L_PUBL_RATE LPR
          ON LPR.DATA_DATE = I_DATADATE
         AND T.CURR_CD = LPR.BASIC_CCY
       WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 0, 6) || '01' AND
             I_DATADATE
         AND T.CURR_CD in ('JPY', 'USD', 'EUR', 'HKD') --<> 'CNY'
         AND LPR.FORWARD_CCY = 'CNY'
         AND ITEM_CD IN ('13030101', /*'129'*/
                         '13030102',
                         '13030103',
                         '13030201',
                         '13030202',
                         '13030203',
                         '13030301',
                         '13030302',
                         '13030303',
                         '13050101',
                         '13050102',
                         '13050103',
                         '13060101',
                         '13060102',
                         '13060103',
                         '13060201',
                         '13060202',
                         '13060203',
                         '13060301',
                         '13060302',
                         '13060303',
                         '13060401',
                         '13060402',
                         '13060403',
                         '13060501',
                         '13060502',
                         '13060503',
                         '13010101', --以摊余成本计量的银行承兑汇票贴现面值
                         '13010103', --以摊余成本计量的银行承兑汇票贴现已减值
                         '13010104', --以摊余成本计量的商业承兑汇票贴现面值
                         '13010106', --以摊余成本计量的商业承兑汇票贴现已减值
                         '13010201', --以摊余成本计量的银行承兑汇票转贴现面值
                         '13010203', --以摊余成本计量的银行承兑汇票转贴现已减值
                         '13010204', --以摊余成本计量的商业承兑汇票转贴现面值
                         '13010206', --以摊余成本计量的商业承兑汇票转贴现已减值
                         '13010301', --买入外币票据面值
                         '13010303', --买入外币票据已减值
                        /* '1290401', --以摊余成本计量的自承自贴转贴现面值
                         '1290403', --以摊余成本计量的自承自贴转贴现已减值*/
                         '13010401', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票贴现面值
                         '13010403', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票贴现已减值
                         '13010405', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票贴现面值
                         '13010407', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票贴现已减值
                         '13010501', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票转贴现面值
                         '13010503', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票转贴现已减值
                         '13010505', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票转贴现面值
                         '13010507' --以公允价值计量且其变动计入其他综合收益的商业承兑汇票转贴现已减值
          /*               '1290701', --以公允价值计量且其变动计入其他综合收益的自承自贴转贴现面值
                         '1290703'*/) --以公允价值计量且其变动计入其他综合收益的自承自贴转贴现已减值
       GROUP BY I_DATADATE, ORG_NUM, V_REP_NUM
      --除了日元、美元、欧元、港币以外的币种 需要转美元后，再转人民币，乘以月末最后一天汇率
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_9_4..B' AS ITEM_NUM, --指标号
             SUM(USD_TMP.ITEM_VAL * L1.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM (SELECT ORG_NUM AS ORG_NUM, --机构号
                     SUM(T.DEBIT_BAL * LPR.CCY_RATE) AS ITEM_VAL, --指标值
                     'USD' AS CURR_CD --币种
                FROM 
                SMTMODS_V_PUB_IDX_FINA_GL T
                LEFT JOIN SMTMODS_L_PUBL_RATE LPR
                  ON LPR.DATA_DATE = I_DATADATE
                 AND T.CURR_CD = LPR.BASIC_CCY
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 0, 6) || '01' AND
                     I_DATADATE
                 AND T.CURR_CD not in ('JPY', 'USD', 'EUR', 'HKD', 'CNY','BWB')
                 AND LPR.FORWARD_CCY = 'USD'
                 AND ITEM_CD IN ('13030101', /*'129'*/
                         '13030102',
                         '13030103',
                         '13030201',
                         '13030202',
                         '13030203',
                         '13030301',
                         '13030302',
                         '13030303',
                         '13050101',
                         '13050102',
                         '13050103',
                         '13060101',
                         '13060102',
                         '13060103',
                         '13060201',
                         '13060202',
                         '13060203',
                         '13060301',
                         '13060302',
                         '13060303',
                         '13060401',
                         '13060402',
                         '13060403',
                         '13060501',
                         '13060502',
                         '13060503',
                         '13010101', --以摊余成本计量的银行承兑汇票贴现面值
                         '13010103', --以摊余成本计量的银行承兑汇票贴现已减值
                         '13010104', --以摊余成本计量的商业承兑汇票贴现面值
                         '13010106', --以摊余成本计量的商业承兑汇票贴现已减值
                         '13010201', --以摊余成本计量的银行承兑汇票转贴现面值
                         '13010203', --以摊余成本计量的银行承兑汇票转贴现已减值
                         '13010204', --以摊余成本计量的商业承兑汇票转贴现面值
                         '13010206', --以摊余成本计量的商业承兑汇票转贴现已减值
                         '13010301', --买入外币票据面值
                         '13010303', --买入外币票据已减值
                        /* '1290401', --以摊余成本计量的自承自贴转贴现面值
                         '1290403', --以摊余成本计量的自承自贴转贴现已减值*/
                         '13010401', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票贴现面值
                         '13010403', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票贴现已减值
                         '13010405', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票贴现面值
                         '13010407', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票贴现已减值
                         '13010501', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票转贴现面值
                         '13010503', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票转贴现已减值
                         '13010505', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票转贴现面值
                         '13010507' --以公允价值计量且其变动计入其他综合收益的商业承兑汇票转贴现已减值
          /*               '1290701', --以公允价值计量且其变动计入其他综合收益的自承自贴转贴现面值
                         '1290703'*/) --以公允价值计量且其变动计入其他综合收益的自承自贴转贴现已减值
               GROUP BY ORG_NUM) USD_TMP
        LEFT JOIN SMTMODS_L_PUBL_RATE L1
          ON L1.DATA_DATE = I_DATADATE
         AND USD_TMP.CURR_CD = L1.BASIC_CCY
       WHERE L1.FORWARD_CCY = 'CNY'
       GROUP BY ORG_NUM, V_REP_NUM, I_DATADATE;
    --修改完成
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '4.月日均贷款余额   逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --按照吉林银行情况，月日均存款余额和月日均存款余额（按调整后存贷比口径计算）逻辑一致，故6 沿用上述2；8 沿用上述4
    --==================================================
    --   G0109 6.月日均存款余额（按调整后存贷比口径计算）
    --==================================================
    --G01_9_6..A.2014   月日均存款余额 人民币
    INSERT INTO CBRC_TMP_G0109_A_REPT_ITEM_VAL
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
             'G01_9_6..A.2014' AS ITEM_NUM, --指标号
             SUM(CREDIT_BAL) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM 
        SMTMODS_V_PUB_IDX_FINA_GL
       WHERE DATA_DATE BETWEEN SUBSTR(I_DATADATE, 0, 6) || '01' AND
             I_DATADATE
         AND CURR_CD = 'CNY'
         AND ITEM_CD IN ('20110201',
                         '20110205',
                         '20110202',
                         '20110203',
                         '20110204',
                         '20110211',
                         '20110101',
                         '20110102',
                         '20110103',
                         '20110104',
                         '20110105',
                         '20110106',
                         '20110107',
                         '20110108',
                         '20110109',
                         '20110111',
                         '20110206',
                         '20130101',
                         '20130201',
                         '20130301',
                         '20140101',
                         '20140201',
                         '20140301',
                         '20110114',
                         '20110115',
                         '20110209',
                         '20110210',
                         '20110110',
                         '20110208',
                         '20110113',
                         '20110701',
                         '20100101',-- 需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：巴启威，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
                         '20110207',
                         '20110112',
                         '22410101','20110301','20110302','20110303','22410102','20080101','20090101', --[JLBA202507210012][石雨][修改内容：22410101单位久悬未取款 22410102个人久悬未取款、201103（财政性存款）调整为 一般单位活期存款]
                         '20120106',--保险业金融机构存放款项
                         '20120204') --保险业金融机构存放款项
       GROUP BY I_DATADATE, ORG_NUM, V_REP_NUM;

    COMMIT;

    --G01_9_6..B.2014 月日均存款余额  外币折人民币
    INSERT INTO CBRC_TMP_G0109_A_REPT_ITEM_VAL
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
             'G01_9_6..B.2014' AS ITEM_NUM, --指标号
             SUM(T.CREDIT_BAL * LPR.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM 
            SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE LPR
          ON T.DATA_DATE = LPR.DATA_DATE
         AND T.CURR_CD = LPR.BASIC_CCY
       WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 0, 6) || '01' AND
             I_DATADATE
         AND T.CURR_CD NOT IN ( 'CNY','BWB')
         AND LPR.FORWARD_CCY = 'CNY'
         AND ITEM_CD IN ('20110201',
                         '20110205',
                         '20110202',
                         '20110203',
                         '20110204',
                         '20110211',
                         '20110101',
                         '20110102',
                         '20110103',
                         '20110104',
                         '20110105',
                         '20110106',
                         '20110107',
                         '20110108',
                         '20110109',
                         '20110111',
                         '20110206',
                         '20130101',
                         '20130201',
                         '20130301',
                         '20140101',
                         '20140201',
                         '20140301',
                         '20110114',
                         '20110115',
                         '20110209',
                         '20110210',
                         '20110110',
                         '20110208',
                         '20110113',
                         '20110701',
                         '20100101',-- 需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：巴启威，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
                         '20110207',
                         '20110112',
                         '22410101','20110301','20110302','20110303','22410102','20080101','20090101', --[JLBA202507210012][石雨][修改内容：22410101单位久悬未取款 22410102个人久悬未取款、201103（财政性存款）调整为 一般单位活期存款]
                         '20120106',--保险业金融机构存放款项
                         '20120204') --保险业金融机构存放款项
       GROUP BY I_DATADATE, ORG_NUM, V_REP_NUM;


    COMMIT;

    --==================================================
    --   G0109 8.月日均贷款余额（按调整后存贷比口径计算）
    --==================================================
    --G01_9_8..A.2014 月日均贷款余额 人民币
    INSERT INTO CBRC_TMP_G0109_A_REPT_ITEM_VAL
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
             'G01_9_8..A.2014' AS ITEM_NUM, --指标号
             SUM(DEBIT_BAL) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM 
             SMTMODS_V_PUB_IDX_FINA_GL
       WHERE DATA_DATE BETWEEN SUBSTR(I_DATADATE, 0, 6) || '01' AND
             I_DATADATE
         AND CURR_CD = 'CNY'
         AND ITEM_CD IN ('13030101', /*'129'*/
                         '13030102',
                         '13030103',
                         '13030201',
                         '13030202',
                         '13030203',
                         '13030301',
                         '13030302',
                         '13030303',
                         '13050101',
                         '13050102',
                         '13050103',
                         '13060101',
                         '13060102',
                         '13060103',
                         '13060201',
                         '13060202',
                         '13060203',
                         '13060301',
                         '13060302',
                         '13060303',
                         '13060401',
                         '13060402',
                         '13060403',
                         '13060501',
                         '13060502',
                         '13060503',
                         '13010101', --以摊余成本计量的银行承兑汇票贴现面值
                         '13010103', --以摊余成本计量的银行承兑汇票贴现已减值
                         '13010104', --以摊余成本计量的商业承兑汇票贴现面值
                         '13010106', --以摊余成本计量的商业承兑汇票贴现已减值
                         '13010201', --以摊余成本计量的银行承兑汇票转贴现面值
                         '13010203', --以摊余成本计量的银行承兑汇票转贴现已减值
                         '13010204', --以摊余成本计量的商业承兑汇票转贴现面值
                         '13010206', --以摊余成本计量的商业承兑汇票转贴现已减值
                         '13010301', --买入外币票据面值
                         '13010303', --买入外币票据已减值
                        /* '1290401', --以摊余成本计量的自承自贴转贴现面值
                         '1290403', --以摊余成本计量的自承自贴转贴现已减值*/
                         '13010401', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票贴现面值
                         '13010403', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票贴现已减值
                         '13010405', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票贴现面值
                         '13010407', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票贴现已减值
                         '13010501', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票转贴现面值
                         '13010503', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票转贴现已减值
                         '13010505', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票转贴现面值
                         '13010507' --以公允价值计量且其变动计入其他综合收益的商业承兑汇票转贴现已减值
          /*               '1290701', --以公允价值计量且其变动计入其他综合收益的自承自贴转贴现面值
                         '1290703'*/) --以公允价值计量且其变动计入其他综合收益的自承自贴转贴现已减值
       GROUP BY I_DATADATE, ORG_NUM, V_REP_NUM;

    COMMIT;

    --G01_9_8..B.2014  月日均贷款余额  外币折人民币
    INSERT INTO CBRC_TMP_G0109_A_REPT_ITEM_VAL
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
             'G01_9_8..B.2014' AS ITEM_NUM, --指标号
             SUM(T.DEBIT_BAL * LPR.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM
             SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE LPR
          ON T.DATA_DATE = LPR.DATA_DATE
         AND T.CURR_CD = LPR.BASIC_CCY
       WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 0, 6) || '01' AND
             I_DATADATE
         AND T.CURR_CD NOT IN ( 'CNY','BWB')
         AND LPR.FORWARD_CCY = 'CNY'
         AND ITEM_CD IN ('13030101', /*'129'*/
                         '13030102',
                         '13030103',
                         '13030201',
                         '13030202',
                         '13030203',
                         '13030301',
                         '13030302',
                         '13030303',
                         '13050101',
                         '13050102',
                         '13050103',
                         '13060101',
                         '13060102',
                         '13060103',
                         '13060201',
                         '13060202',
                         '13060203',
                         '13060301',
                         '13060302',
                         '13060303',
                         '13060401',
                         '13060402',
                         '13060403',
                         '13060501',
                         '13060502',
                         '13060503',
                         '13010101', --以摊余成本计量的银行承兑汇票贴现面值
                         '13010103', --以摊余成本计量的银行承兑汇票贴现已减值
                         '13010104', --以摊余成本计量的商业承兑汇票贴现面值
                         '13010106', --以摊余成本计量的商业承兑汇票贴现已减值
                         '13010201', --以摊余成本计量的银行承兑汇票转贴现面值
                         '13010203', --以摊余成本计量的银行承兑汇票转贴现已减值
                         '13010204', --以摊余成本计量的商业承兑汇票转贴现面值
                         '13010206', --以摊余成本计量的商业承兑汇票转贴现已减值
                         '13010301', --买入外币票据面值
                         '13010303', --买入外币票据已减值
                        /* '1290401', --以摊余成本计量的自承自贴转贴现面值
                         '1290403', --以摊余成本计量的自承自贴转贴现已减值*/
                         '13010401', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票贴现面值
                         '13010403', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票贴现已减值
                         '13010405', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票贴现面值
                         '13010407', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票贴现已减值
                         '13010501', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票转贴现面值
                         '13010503', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票转贴现已减值
                         '13010505', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票转贴现面值
                         '13010507' --以公允价值计量且其变动计入其他综合收益的商业承兑汇票转贴现已减值
          /*               '1290701', --以公允价值计量且其变动计入其他综合收益的自承自贴转贴现面值
                         '1290703'*/) --以公允价值计量且其变动计入其他综合收益的自承自贴转贴现已减值
       GROUP BY I_DATADATE, ORG_NUM, V_REP_NUM;

    COMMIT;

    --均值处理
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
             ORG_NUM, --机构号
             SYS_NAM, --模块简称
             REP_NUM, --报表编号
             ITEM_NUM, --指标号
             SUM(ITEM_VAL) / I_MONTH_NUM, --指标值
             FLAG --标志位
        FROM CBRC_TMP_G0109_A_REPT_ITEM_VAL
       GROUP BY ORG_NUM, --机构号
                SYS_NAM, --模块简称
                REP_NUM, --报表编号
                ITEM_NUM, --指标号
                FLAG --标志位
      ;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '8.月日均贷款余额（按调整后存贷比口径计算）  逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --==================================================
    --   G0109 11.存款偏离度
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
    

      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM, --机构号
             A.SYS_NAM, --模块简称
             A.REP_NUM, --模块简称
             'G01_9_11.C.2016' AS ITEM_NUM, --指标号
             CASE
               WHEN substr(I_DATADATE, 5, 2) in ('03', '06', '09', '12') then
                (VAL1 -
                least(VAL2,
                       VAL3 *
                       (1 + ((VAL4 - VAL5) / VAL5) + ((VAL6 - VAL7) / VAL7) +
                       ((VAL8 - VAL9) / VAL9) + ((VAL10 - VAL11) / VAL11)))) --待确认
               else
                (VAL1 - VAL2) / VAL2
             end AS ITEM_VAL, --指标值
             A.FLAG --标志位
        FROM (SELECT SUM(ITEM_VAL) VAL2, ORG_NUM, REP_NUM, SYS_NAM, FLAG
                FROM CBRC_A_REPT_ITEM_VAL
               WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                 AND DATA_DATE = I_DATADATE
               GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) A
       INNER JOIN (SELECT SUM(ITEM_VAL) VAL1, ORG_NUM, SYS_NAM, REP_NUM
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_1..A', 'G01_9_1..B')
                      AND replace(DATA_DATE, '-', '') = I_DATADATE
                    GROUP BY ORG_NUM, SYS_NAM, REP_NUM) B
          ON A.ORG_NUM = B.ORG_NUM
         AND A.REP_NUM = B.REP_NUM
         AND A.SYS_NAM = B.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL3,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -1),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C3
          ON A.ORG_NUM = C3.ORG_NUM
         AND A.REP_NUM = C3.REP_NUM
         AND A.SYS_NAM = C3.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL4,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -3),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C4
          ON A.ORG_NUM = C4.ORG_NUM
         AND A.REP_NUM = C4.REP_NUM
         AND A.SYS_NAM = C4.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL5,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -4),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C5
          ON A.ORG_NUM = C5.ORG_NUM
         AND A.REP_NUM = C5.REP_NUM
         AND A.SYS_NAM = C5.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL6,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -6),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C6
          ON A.ORG_NUM = C6.ORG_NUM
         AND A.REP_NUM = C6.REP_NUM
         AND A.SYS_NAM = C6.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL7,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -7),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C7
          ON A.ORG_NUM = C7.ORG_NUM
         AND A.REP_NUM = C7.REP_NUM
         AND A.SYS_NAM = C7.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL8,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -9),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C8
          ON A.ORG_NUM = C8.ORG_NUM
         AND A.REP_NUM = C8.REP_NUM
         AND A.SYS_NAM = C8.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL9,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -10),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C9
          ON A.ORG_NUM = C9.ORG_NUM
         AND A.REP_NUM = C9.REP_NUM
         AND A.SYS_NAM = C9.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL10,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -12),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C10
          ON A.ORG_NUM = C10.ORG_NUM
         AND A.REP_NUM = C10.REP_NUM
         AND A.SYS_NAM = C10.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL11,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -13),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C11
          ON A.ORG_NUM = C11.ORG_NUM
         AND A.REP_NUM = C11.REP_NUM
         AND A.SYS_NAM = C11.SYS_NAM
      
      ;
    commit;



    V_STEP_FLAG := 1;
    V_STEP_DESC := '11.存款偏离度    逻辑处理完成';
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
END proc_cbrc_idx2_g0109