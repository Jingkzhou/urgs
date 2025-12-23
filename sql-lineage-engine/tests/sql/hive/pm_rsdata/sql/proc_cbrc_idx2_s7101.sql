CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_s7101(II_DATADATE  IN STRING --跑批日期
                                                   )
/****************************** 
   @AUTHOR:DJH
   @CREATE-DATE:20250811
   @DESCRIPTION: S7101明细数据
   --M1:20220126 SHIYU 修改【当年累放贷款额】、【当年累放贷款户数】、【当年累放贷款年化利息收益】相关指标
   --M2:ALTER BY WANGJB 20220128 4.普惠型其他个人（非农户）经营性贷款: 1.个人去掉职业为军人的  2.去掉单位性质为 国有企业的、事业单位的
   --M3:20220129  SHIYU  新增指标1.1其中：普惠型涉农小微企业法人贷款（其中：单户授信1000万元（含）以下不含票据融资合计）
        贷款余额(S71_I_1.1.A5.2022)、贷款户数(S71_I_1.1.B5.2022)、不良贷款(S71_I_1.1.C5.2022)
   --M4:新建临时表 S7101_BAL_TMP1 贷款余额宽表 、S7101_DATA_COLLECT_TMPE  s7101指标结果表、S7101_AMT_TMP1 贷款累放宽表
   --M5:20220223 shiyu 修改授信额度：贴现在授信额度表中未统计,按照贷款余额统计贴现业务
   --M6:4项：剔除3100  国家权力机关  3200  国家行政机关  3300  国家司法机关 3400  政党机关 3500  政协组织  --20220224 吴吴大为确认
   --M7:新建临时表s7101_amt_tmp 统计累计发放贷款
   --M8:20220712 SHIYU 新建临时表S7101_CREDITLINE_LJ 累计放款额度按照放款当月的额度计算
   --m9: 单位性质引用新码值
   --M10 :20221117  授信表中存在磐石机构的授信额度,在统计授信时剔除这部分
   --m11:20230828 shiyu 修改内容：单位客户及单位名称的个体工商户取客户授信协议金额,不考虑授信协议状态,自然人客户取客户合同金额合计
   --M12.20231012.ZJM.对涉及累放的指标进行开发,将村镇铺底数据逻辑放进
   --S7101_AMT_TMP1_HIS 新建临时表存放累放数据,保留历史数据
    --alter by zy 20241024     V_ACCT_LOAN_FARMING 修改内容：涉农贷款修改试图统计,新增存储过程PROC_SNDK_SG 处理贷款涉农问题
   --M14 20241128 shiyu 修改内容：授信新增两个模块：表内银行承兑余额、国内保理（无追索权保理）、吉信链产品授信
   --M15 20241224 SHIYU 修改内容：修改为授信视图出数据
   --M16 20250124 2025年制度升级
   --m17 20250327 修改涉农取数逻辑,与大集中1433保持一致；新增临时表
   --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”,“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
   --需求编号：JLBA202504160004_关于吉林银行修改单一客户授信逻辑的需求 提出人：苏桐  上线时间：20250627 修改人：石雨 修改内容：客户授信逻辑
                需求编号：JLBA202503070010_关于吉林银行统一监管报送平台升级的需求 上线日期： 2025-12-26,修改人：狄家卉,提出人：数据管理部  修改原因：由汇总数据修改为明细以及汇总
          
目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_A_REPT_DWD_S7101
CBRC_S7101_AMT_TMP
CBRC_S7101_AMT_TMP1
CBRC_S7101_CREDITLINE_HZ
CBRC_S7101_CREDITLINE_LJ
CBRC_S7101_SNDK_TEMP
CBRC_S7101_UNDERTAK_GUAR_INFO
码值表：SMTMODS_S7001_CUST_TEMP
SMTMODS_A_REPT_DWD_MAPPING
集市表：SMTMODS_L_ACCT_LOAN
SMTMODS_L_ACCT_LOAN_FARMING
SMTMODS_L_CUST_ALL
SMTMODS_L_CUST_C
SMTMODS_L_CUST_P
SMTMODS_L_PUBL_RATE
SMTMODS_L_V_PUB_IDX_DK_PHJRDK
视图表：
SMTMODS_V_PUB_IDX_DK_DGSNDK
SMTMODS_V_PUB_IDX_DK_GRSNDK
SMTMODS_V_PUB_IDX_DK_GTGSHSNDK
SMTMODS_V_PUB_IDX_DK_YSDQRJJ
SMTMODS_V_PUB_IDX_SX_PHJRDKSX
       
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
  NEXTDATE       VARCHAR2(10);
  CURRENTDATE    VARCHAR2(10);
  NUM            INTEGER;
  V_ERRORCODE    VARCHAR(280); --错误内容
  V_ERRORDESC    VARCHAR(280); --错误内容
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时,用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM       VARCHAR2(30);
  

BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';
    I_DATADATE  := II_DATADATE;
    V_SYSTEM    := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_S7101');
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_TAB_NAME     := 'CBRC_A_REPT_ITEM_VAL';
    D_DATADATE_CCY := I_DATADATE;
    V_STEP_FLAG    := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']S7101当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -- SMTMODS_A_REPT_DWD_MAPPING 码值映射表

    CURRENTDATE := TO_CHAR(I_DATADATE, 'YYYYMMDD');
    NEXTDATE := TO_CHAR(I_DATADATE + 1, 'YYYYMMDD');

    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'S7101';
    COMMIT;

     EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_A_REPT_DWD_S7101';
      EXECUTE IMMEDIATE ('DELETE FROM  CBRC_S7101_CREDITLINE_HZ T WHERE  T.DATA_DATE = ' || '''' ||
                      I_DATADATE || '''' || ''); --保留历史数据


         INSERT INTO CBRC_S7101_CREDITLINE_HZ
      (CUST_ID, FACILITY_AMT, DATA_DATE)
      SELECT 
       CUST_ID, FACILITY_AMT, DATA_DATE
        FROM SMTMODS_V_PUB_IDX_SX_PHJRDKSX
       WHERE DATA_DATE = I_DATADATE;
    COMMIT;

   



    --【当年累放所有用到的临时表 开始】

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '加工授信至S7101_CREDITLINE_LJ中间表(放款额度)';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    EXECUTE IMMEDIATE ('DELETE FROM  CBRC_S7101_CREDITLINE_LJ T WHERE  T.DATA_DATE = ' || '''' ||
                      I_DATADATE || '''' || ''); --保留历史数据

    INSERT INTO CBRC_S7101_CREDITLINE_LJ
      (CUST_ID, FACILITY_AMT, DATA_DATE)
    SELECT 
       CUST_ID, FACILITY_AMT, DATA_DATE
        FROM SMTMODS_V_PUB_IDX_SX_PHJRDKSX
       WHERE DATA_DATE = I_DATADATE;
       COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '加工涉农贷款宽表至S7101_SNDK_TEMP临时表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S7101_SNDK_TEMP';

    ----20250327 新增涉农贷款逻辑

    INSERT INTO CBRC_S7101_SNDK_TEMP
      (DATA_DATE,
       LOAN_NUM,
       SNDKFL,
       IF_CT_UA,
       AGR_USE_ADDL,
       COOP_LAON_FLAG,
       RUR_COLL_ECO_ORG_LOAN_FLG)

      SELECT I_DATADATE DATA_DATE,
             F.LOAN_NUM,
             F.SNDKFL,
             F.IF_CT_UA,
             F.AGR_USE_ADDL,
             K.COOP_LAON_FLAG,
             K.RUR_COLL_ECO_ORG_LOAN_FLG
        FROM (SELECT T.LOAN_NUM, T.SNDKFL, T.IF_CT_UA, T.AGR_USE_ADDL
                FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
               WHERE T.DATA_DATE = I_DATADATE
                 AND SUBSTR(T.SNDKFL, 1, 5) IN
                     ('P_101', 'P_102', 'P_103', 'P_201')
              UNION ALL
              SELECT T.LOAN_NUM, T.SNDKFL, T.IF_CT_UA, T.AGR_USE_ADDL
                FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
               WHERE T.DATA_DATE = I_DATADATE
                 AND SUBSTR(T.SNDKFL, 1, 5) IN
                     ('P_101', 'P_102', 'P_103', 'P_201')
              UNION ALL
              SELECT A.LOAN_NUM, A.SNDKFL, A.IF_CT_UA, A.AGR_USE_ADDL
                FROM SMTMODS_V_PUB_IDX_DK_DGSNDK A --对公涉农
                LEFT JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND A.DATA_DATE = B.DATA_DATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND (A.SNDKFL LIKE 'C_301%' OR
                     SUBSTR(A.SNDKFL, 0, 5) = 'C_401' OR
                     A.SNDKFL LIKE 'C_1%' OR SUBSTR(A.SNDKFL, 0, 3) = 'C_2' OR
                     ((A.SNDKFL LIKE 'C_402%' OR A.SNDKFL LIKE 'C_302%') AND
                     (CASE
                       WHEN SUBSTR(A.SNDKFL, 0, 7) IN ('C_40202', 'C_30202') AND
                            (NVL(A.AGR_USE_ADDL, '#') IN ('05') OR
                             NVL(B.LOAN_PURPOSE_CD, '#') IN
                             ('A0514', 'A0523')) THEN
                        1
                       ELSE
                        0
                     END) = 0))) F

       INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING K
          ON F.LOAN_NUM = K.LOAN_NUM
         AND K.DATA_DATE = I_DATADATE;
      COMMIT;


    --加工当年累计 3000万以下合计
    --年初删除本年累计

    IF SUBSTR(I_DATADATE, 5, 2) = 01 THEN
      EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S7101_AMT_TMP';
    ELSE
      EXECUTE IMMEDIATE ('DELETE FROM  CBRC_S7101_AMT_TMP T WHERE  T.DATA_DATE = ' || '''' ||
                        I_DATADATE || '''' || ''); --删除当前日期数据
    END IF;

    COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '单户授信累放表 保留历史,每个月的授信相关都放在此表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --单户授信累放表 保留历史,每个月的授信相关都放在此表

    INSERT INTO CBRC_S7101_AMT_TMP
      (ORG_NUM, --机构号
       CUST_ID, --客户号
       FACILITY_AMT, --授信额度
       LOAN_ACCT_AMT, --累放金额
       NHSY, --年化收益
       LOAN_NUM, --拮据编号
       CORP_SCALE, --企业规模
       OPERATE_CUST_TYPE, --个人经营型标识
       AGREI_P_FLG, --是否涉农
       CUST_NAM, --客户名称
       QT_FLAG, --其他组织标志
       DATA_DATE,
       ITEM_CD, --科目号
       CUST_TYP, --对公客户类型
       UNDERTAK_GUAR_TYPE, --创业担保贷款类型
       COOP_LAON_FLAG, --农民合作社贷款标志
       RUR_COLL_ECO_ORG_LOAN_FLG, --农村集体经济组织贷款标志
       TECH_CORP_TYPE, --科技型企业类型
       MATURITY_DT, --原始到期日期
       DRAWDOWN_DT, --放款日期
       GUARANTY_TYP, --贷款担保方式
       LOAN_KIND_CD, --贷款形式
       DEFORMITY_FLG, --残疾人标志
       CURR_CD,
       --需求JLBA202412270003_一期 新增 24-30字段
       IF_HIGH_SALA_CORP, -- 24是否高新技术
       IF_GJJSCXSFQY, --25是否国家技术创新示范企业
       IF_ZCYDXGJQY, --26是否制造业单项冠军企业
       IF_ZJTXKH, --27是否专精特新客户
       IF_ZJTXXJRQY, --28是否专精特新小巨人企业
       IF_CXXQY, --29创新型企业
       IF_GJQYJSZX --30国家企业技术中心
       )
      SELECT 
       A.ORG_NUM, --机构号
       T.CUST_ID, --客户号
       T.FACILITY_AMT, --授信金额
       A.DRAWDOWN_AMT AS LOAN_ACCT_AMT, --累放金额
       A.DRAWDOWN_AMT * A.REAL_INT_RAT / 100 NHSY, --年化收益
       A.LOAN_NUM, --借据号
       B.CORP_SCALE, --企业规模
       ----shiyu 20220128 修改内容：原逻辑判断个人经营性标识应根据借据账户累计和客户及客户类型判断
       case
         when (A.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND A.ITEM_CD LIKE '1305%')) then
          COALESCE(P.OPERATE_CUST_TYPE, B.CUST_TYP) --个体工商户：一部分在对私:A、一部分在对公:3  tanglei20220406
       end OPERATE_CUST_TYPE,
       CASE
         WHEN F.LOAN_NUM IS NOT NULL THEN
          'Y'
         ELSE
          'N'
       END AS AGREI_P_FLG, --涉农标志
       C.CUST_NAM, --客户名称
       CASE
         WHEN B.CUST_TYP IN ('4', '5', '24') THEN ---社会团体、事业单位、其他机关
          'Y'
         ELSE
          'N'
       END AS QT_FLAG, --其它组织标志
       I_DATADATE,
       A.ITEM_CD, --科目号
       B.CUST_TYP, --对公客户类型
       A.UNDERTAK_GUAR_TYPE, --创业担保贷款类型
       F.COOP_LAON_FLAG, --农民合作社贷款标志
       F.RUR_COLL_ECO_ORG_LOAN_FLG, --农村集体经济组织贷款标志
       CASE
         --    需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”,“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
        -- WHEN B.TECH_CORP_TYPE = 'C01' THEN
        WHEN B.IF_ST_SMAL_CORP ='1' THEN
          '1'
         ELSE
          '0'
       END, --科技型中小企业
       A.MATURITY_DT, --原始到期日期
       A.DRAWDOWN_DT, --放款日期
       A.GUARANTY_TYP, --贷款担保方式
       A.LOAN_KIND_CD, --贷款形式
       P.DEFORMITY_FLG, --残疾人标志
       A.CURR_CD, --币种
       b.IF_HIGH_SALA_CORP, -- 24是否高新技术
       CASE
         WHEN b.NAT_TECH_INVT_CORP ='1' THEN
          'Y'
         ELSE
          'N'
       END IF_GJJSCXSFQY, --25是否国家技术创新示范企业
       CASE
         WHEN b.MNFT_SIGL_FRST_CORP ='1' THEN
          'Y'
         ELSE
          'N'
       END IF_ZCYDXGJQY, --26是否制造业单项冠军企业
       CASE
         WHEN b.IF_SPCLED_NEW_CUST ='1' AND B.CORP_SCALE IN ('M','S','T') THEN
          'Y'
         ELSE
          'N'
       END IF_ZJTXKH, --27是否专精特新中小企业
       CASE
         WHEN B.HUGE_SPCLED_NEW_CORP ='1' THEN
          'Y'
         ELSE
          'N'
       END IF_ZJTXXJRQY, --28是否专精特新小巨人企业
       CASE
         WHEN P5.CUST_NAME IS NOT NULL AND B.CORP_SCALE IN ('M','S','T') THEN
          'Y'
         ELSE
          'N'
       END IF_CXXQY, --创新型企业
       NULL AS  IF_GJQYJSZX --国家企业技术中心
        FROM  SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
       INNER JOIN  SMTMODS_V_PUB_IDX_SX_PHJRDKSX T --授信加工临时表
          ON T.CUST_ID = A.CUST_ID
         AND T.DATA_DATE = TO_CHAR(A.DRAWDOWN_DT,'YYYYMMDD') --取放款时的授信--需求编号：JLBA202504160004_关于吉林银行修改单一客户授信逻辑的需求 提出人：苏桐  上线时间：20250627 修改人：石雨 修改内容：客户授信逻辑
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C B --对公表 取小微企业
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对私表 取个体工商户&小微企业主
          ON A.CUST_ID = P.CUST_ID
         and p.data_date = I_DATADATE
        LEFT JOIN CBRC_S7101_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_CUST_ALL C --客户表 取农民专业合作社
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    where CUST_TYPE like '%创新型企业%'
                    GROUP BY TRIM(CUST_NAME)) P5
          ON replace(replace(TRIM(P5.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(C.CUST_NAM), '(', '（'), ')', '）')
        
       WHERE A.DATA_DATE = I_DATADATE
         AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元以下,含本数 属于普惠型
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and a.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
         AND A.ITEM_CD NOT IN ('13010201',
                               '13010202',
                               '13010203',
                               '13010204',
                               '13010205',
                               '13010206',
                               '13010501',
                               '13010502',
                               '13010503',
                               '13010504',
                               '13010505',
                               '13010506',
                               '13010507',
                               '13010508') --刨除票据转贴现
         AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组 SHIYU 20220210  新口径吴大为
         AND (SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) = ---取当月
             SUBSTR(I_DATADATE, 1, 6) OR
             (A.INTERNET_LOAN_FLG = 'Y' AND
             A.DRAWDOWN_DT =
             (TRUNC(I_DATADATE, 'MM') - 1)) --modify by 87v : 互联网贷款数据晚一天下发,上月末数据当月取
             );
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '单户授信累放表 取当年累放贷款的最新信息：存在最新维护信息';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --删除临时表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S7101_AMT_TMP1';

    ---取当年累放贷款的最新信息：存在最新维护信息

    INSERT INTO CBRC_S7101_AMT_TMP1
      (ORG_NUM, --机构号
       CUST_ID, --客户号
       FACILITY_AMT, --授信额度
       LOAN_ACCT_AMT, --累放金额
       NHSY, --年化收益
       LOAN_NUM, --拮据编号
       CORP_SCALE, --企业规模
       OPERATE_CUST_TYPE, --个人经营型标识
       AGREI_P_FLG, --是否涉农
       CUST_NAM, --客户名称
       QT_FLAG, --其他组织标志
       DATA_DATE,
       ITEM_CD, --科目号
       CUST_TYP, --对公客户类型
       UNDERTAK_GUAR_TYPE, --创业担保贷款类型
       COOP_LAON_FLAG, --农民合作社贷款标志
       RUR_COLL_ECO_ORG_LOAN_FLG, --农村集体经济组织贷款标志
       TECH_CORP_TYPE, --科技型企业类型
       MATURITY_DT, --原始到期日期
       DRAWDOWN_DT, --放款日期
       GUARANTY_TYP, --贷款担保方式
       LOAN_KIND_CD, --贷款形式
       DEFORMITY_FLG, --残疾人标志
       IF_HIGH_SALA_CORP, -- 24是否高新技术
       IF_GJJSCXSFQY, --25是否国家技术创新示范企业
       IF_ZCYDXGJQY, --26是否制造业单项冠军企业
       IF_ZJTXKH, --27是否专精特新客户
       IF_ZJTXXJRQY, --28是否专精特新小巨人企业
       IF_CXXQY, --创新型企业
       IF_GJQYJSZX, --国家企业技术中心
       CP_ID, --产品ID    --从此处增加字段20250815 djh
       CP_NAME, --产品名称
       DEPARTMENTD, --归属部门
       ACCT_NUM, --合同号
       SNDKFL --涉农贷款分类
       )
      select

       t.ORG_NUM, --机构号
       t.CUST_ID, --客户号
       t.FACILITY_AMT, --授信额度
       t.LOAN_ACCT_AMT * TT.CCY_RATE, --累放金额
       t.NHSY * TT.CCY_RATE, --年化收益
       t.LOAN_NUM, --拮据编号
       c.CORP_SCALE, --企业规模
       case
         when (A.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND A.ITEM_CD LIKE '1305%')) then
          COALESCE(P.OPERATE_CUST_TYPE, c.CUST_TYP) --个体工商户：一部分在对私:A、一部分在对公:3  tanglei20220406
       end OPERATE_CUST_TYPE,
       CASE
         WHEN F.LOAN_NUM IS NOT NULL THEN
          'Y'
         ELSE
          'N'
       END AGREI_P_FLG, --是否涉农
       nvl(p.cust_nam, c.cust_nam), --客户名称
       CASE
         WHEN c.CUST_TYP IN ('4', '5', '24') THEN ---社会团体、事业单位、其他机关
          'Y'
         ELSE
          'N'
       END AS QT_FLAG, --其他组织标志
       t.DATA_DATE,
       t.ITEM_CD, --科目号
       c.CUST_TYP, --对公客户类型
       t.UNDERTAK_GUAR_TYPE, --创业担保贷款类型
       F.COOP_LAON_FLAG, --农民合作社贷款标志
       F.RUR_COLL_ECO_ORG_LOAN_FLG, --农村集体经济组织贷款标志
       --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”,“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
       CASE
         WHEN c.IF_ST_SMAL_CORP ='1' THEN
          '1'
         ELSE
          '0'
       END, --是否科技中小企业
       t.MATURITY_DT, --原始到期日期
       t.DRAWDOWN_DT, --放款日期
       t.GUARANTY_TYP, --贷款担保方式
       t.LOAN_KIND_CD, --贷款形式
       P.DEFORMITY_FLG, --残疾人标志
       --需求JLBA202412270003_一期 新增字段
       c.IF_HIGH_SALA_CORP, -- 24是否高新技术
       --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”,“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
       CASE
         WHEN C.NAT_TECH_INVT_CORP ='1' THEN
          'Y'
         ELSE
          'N'
       END IF_GJJSCXSFQY, --25是否国家技术创新示范企业
       CASE
         WHEN C.MNFT_SIGL_FRST_CORP ='1' THEN
          'Y'
         ELSE
          'N'
       END IF_ZCYDXGJQY, --26是否制造业单项冠军企业
       CASE
         WHEN C.IF_SPCLED_NEW_CUST ='1' AND C.CORP_SCALE IN ('M','S','T') THEN
          'Y'
         ELSE
          'N'
       END IF_ZJTXKH, --27是否专精特新中小企业
       CASE
         WHEN C.HUGE_SPCLED_NEW_CORP='1' THEN
          'Y'
         ELSE
          'N'
       END IF_ZJTXXJRQY, --28是否专精特新小巨人企业
       CASE
         WHEN P5.CUST_NAME IS NOT NULL AND C.CORP_SCALE IN ('M','S','T') THEN
          'Y'
         ELSE
          'N'
       END IF_CXXQY, --创新型企业
       CASE
         WHEN P6.CUST_NAME IS NOT NULL THEN
          'Y'
         ELSE
          'N'
       END IF_GJQYJSZX, --国家企业技术中心
       A.CP_ID, --产品ID
       A.CP_NAME, --产品名称
       A.DEPARTMENTD, --归属部门
       A.ACCT_NUM, --合同号
       F.SNDKFL --涉农贷款分类
        from CBRC_S7101_AMT_TMP t
        left join SMTMODS_l_acct_loan a
          on t.loan_num = a.loan_num
         and a.data_date = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = t.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C c --对公表 取小微企业
          ON t.CUST_ID = c.CUST_ID
         AND c.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对私表 取个体工商户&小微企业主
          ON t.CUST_ID = P.CUST_ID
         and p.data_date = I_DATADATE
        LEFT JOIN CBRC_S7101_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND t.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    where CUST_TYPE like '%创新型企业%'
                    GROUP BY TRIM(CUST_NAME)) P5
          ON replace(replace(TRIM(P5.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(C.CUST_NAM), '(', '（'), ')', '）')
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    where CUST_TYPE like '%国家企业技术中心%'
                    GROUP BY TRIM(CUST_NAME)) P6
          ON replace(replace(TRIM(P6.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(C.CUST_NAM), '(', '（'), ')', '）');
    COMMIT;

     -- 【当年累放所有用到的临时表 结束】

    ------------------------------------------
    --1.普惠型小微企业法人贷款
    ------------------------------------------

    --【1.普惠型小微企业法人贷款 贷款余额】
      V_STEP_ID   := V_STEP_ID + 1;
      V_STEP_FLAG := 0;
      V_STEP_DESC := '1.普惠型小微企业法人贷款 贷款余额';
      SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                  V_STEP_ID,
                  V_ERRORCODE,
                  V_STEP_DESC,
                  II_DATADATE);

      -- 1.普惠型小微企业法人贷款 贷款余额
          INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3,
           COL_4,
           COL_6,
           COL_7,
           COL_8,
           COL_9,
           COL_10,
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT T.DATA_DATE,
                 T.ORG_NUM,
                 T.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 CASE
                   WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                    'S71_I_1..A4.2018'
                   WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                    'S71_I_1..A3.2018'
                   WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                    'S71_I_1..A2.2018'
                   WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                    'S71_I_1..A1.2018'
                 END AS ITEM_NUM,
                 T.LOAN_ACCT_BAL,
                 --T.INST_NAME AS COL_1,
                 T.CUST_ID AS COL_2,
                 T.CUST_NAM AS COL_3,
                 T.LOAN_NUM AS COL_4,
                 --T.LOAN_ACCT_BAL AS COL_5,
                 T.FACILITY_AMT AS COL_6,
                 T.ACCT_NUM AS COL_7,
                 T.DRAWDOWN_DT AS COL_8,
                 T.MATURITY_DT AS COL_9,
                 T.ITEM_CD AS COL_10,
                 T.DEPARTMENTD AS COL_11,
                 T.CORP_SCALE AS COL_12,
                 T.CP_NAME AS COL_13,
                 T.LOAN_GRADE_CD AS COL_14
            FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
           WHERE DATA_DATE = I_DATADATE
             AND T.LOAN_ACCT_BAL <> 0
             AND T.PHXXWQYFRDK = '是';

      COMMIT;

      -- 其中：单户授信1000万元（含）以下不含票据融资合计

        INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           --COL_1,
           COL_2,
           COL_3,
           COL_4,
           --COL_5,
           COL_6,
           COL_7,
           COL_8,
           COL_9,
           COL_10,
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT T.DATA_DATE,
                 T.ORG_NUM,
                 T.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 'S71_I_1..A5.2021' AS ITEM_NUM,
                 T.LOAN_ACCT_BAL,
                 --T.INST_NAME AS COL_1,
                 T.CUST_ID AS COL_2,
                 T.CUST_NAM AS COL_3,
                 T.LOAN_NUM AS COL_4,
                 --T.LOAN_ACCT_BAL AS COL_5,
                 T.FACILITY_AMT AS COL_6,
                 T.ACCT_NUM AS COL_7,
                 T.DRAWDOWN_DT AS COL_8,
                 T.MATURITY_DT AS COL_9,
                 T.ITEM_CD AS COL_10,
                 T.DEPARTMENTD AS COL_11,
                 T.CORP_SCALE AS COL_12,
                 T.CP_NAME AS COL_13,
                 T.LOAN_GRADE_CD AS COL_14
            FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
           WHERE DATA_DATE = I_DATADATE
             AND PHXXWQYFRDK = '是'
             AND T.LOAN_ACCT_BAL <> 0
             AND ITEM_CD NOT LIKE '1301%' --不含贴现
             AND FACILITY_AMT <= 10000000;
      COMMIT;

     --【1.普惠型小微企业法人贷款 不良贷款余额】
      V_STEP_ID   := V_STEP_ID + 1;
      V_STEP_FLAG := 0;
      V_STEP_DESC := '1.普惠型小微企业法人贷款 不良贷款余额';
      SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                  V_STEP_ID,
                  V_ERRORCODE,
                  V_STEP_DESC,
                  II_DATADATE);


          -- 1.普惠型小微企业法人贷款 不良贷款余额
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             --COL_1,
             COL_2,
             COL_3,
             COL_4,
             --COL_5,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_1..C4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_1..C3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_1..C2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_1..C1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL,
                   --T.INST_NAME AS COL_1,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   --T.LOAN_ACCT_BAL AS COL_5,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXXWQYFRDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失'); --不良贷款
         COMMIT;

           -- 其中：单户授信1000万元（含）以下不含票据融资合计

           INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             --COL_1,
             COL_2,
             COL_3,
             COL_4,
             --COL_5,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_1..C5.2021' AS ITEM_NUM,
                   T.LOAN_ACCT_BAL,
                   --T.INST_NAME AS COL_1,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   --T.LOAN_ACCT_BAL AS COL_5,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXXWQYFRDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失')--不良贷款
               AND ITEM_CD NOT LIKE '1301%' --不含贴现
               AND FACILITY_AMT <= 10000000;
         COMMIT;

       --【1.普惠型小微企业法人贷款 贷款余额户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.普惠型小微企业法人贷款 贷款余额户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

          -- 1.普惠型小微企业法人贷款 贷款余额户数
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             --DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             --COL_1,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   --T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_1..B4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_1..B3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_1..B2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_1..B1.2018'
                   END AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                   --T.INST_NAME AS COL_1,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXXWQYFRDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
             GROUP BY T.SXFW,
                      T.DATA_DATE,
                      T.ORG_NUM,
                      --T.INST_NAME,
                      T.CUST_ID,
                      T.CUST_NAM;
           COMMIT;

             -- 其中：单户授信1000万元（含）以下不含票据融资合计
             INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             --DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             --COL_1,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   --T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_1..B5.2021' AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                   --T.INST_NAME AS COL_1,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXXWQYFRDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND ITEM_CD NOT LIKE '1301%' --不含贴现
               AND FACILITY_AMT <= 10000000
             GROUP BY T.DATA_DATE,
                      T.ORG_NUM,
                      --T.INST_NAME,
                      T.CUST_ID,
                      T.CUST_NAM;
           COMMIT;

        --【1.普惠型小微企业法人贷款 当年累放贷款额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.普惠型小微企业法人贷款  当年累放贷款额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);


         -- 1.普惠型小微企业法人贷款  当年累放贷款额
        INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           --COL_1,
           COL_2,
           COL_3,
           COL_4,
           --COL_5,
           COL_6,
           COL_7,
           COL_8,
           COL_9,
           COL_10,
           COL_11,
           COL_12,
           COL_13)
          SELECT I_DATADATE,
                 T.ORG_NUM,
                 T.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 CASE
                   WHEN T.FACILITY_AMT <= 1000000 THEN
                    'S71_I_1..D1.2018'
                   WHEN T.FACILITY_AMT > 1000000 AND
                        T.FACILITY_AMT <= 5000000 THEN
                    'S71_I_1..D2.2018'
                   WHEN T.FACILITY_AMT > 5000000 AND
                        T.FACILITY_AMT <= 10000000 THEN
                    'S71_I_1..D3.2018'
                   WHEN T.FACILITY_AMT > 10000000 AND
                        T.FACILITY_AMT <= 30000000 THEN
                    'S71_I_1..D4.2018'
                 END AS ITEM_NUM,
                 T.LOAN_ACCT_AMT,
                 --T1.INST_NAME AS COL_1,
                 T.CUST_ID AS COL_2,
                 T.CUST_NAM AS COL_3,
                 T.LOAN_NUM AS COL_4,
                 --T.LOAN_ACCT_AMT AS COL_5,
                 T.FACILITY_AMT AS COL_6,
                 T.ACCT_NUM AS COL_7,
                 T.DRAWDOWN_DT AS COL_8,
                 T.MATURITY_DT AS COL_9,
                 T.ITEM_CD AS COL_10,
                 T.DEPARTMENTD AS COL_11,
                 T2.M_NAME AS COL_12,
                 T.CP_NAME AS COL_13
            FROM CBRC_S7101_AMT_TMP1 T
            --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
            --  ON T.ORG_NUM = T1.INST_ID
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
              ON T.CORP_SCALE = T2.M_CODE
             AND T2.M_TABLECODE = 'CORP_SCALE'
           WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
             AND T.DATA_DATE <= I_DATADATE
             --AND T.LOAN_ACCT_AMT <> 0
             AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
             AND T.CORP_SCALE IN ('S', 'T'); --小微企业

          COMMIT;

           -- 其中：单户授信1000万元（含）以下不含票据融资合计

           INSERT INTO CBRC_A_REPT_DWD_S7101
             (DATA_DATE,
              ORG_NUM,
              DATA_DEPARTMENT,
              SYS_NAM,
              REP_NUM,
              ITEM_NUM,
              TOTAL_VALUE,
              --COL_1,
              COL_2,
              COL_3,
              COL_4,
              --COL_5,
              COL_6,
              COL_7,
              COL_8,
              COL_9,
              COL_10,
              COL_11,
              COL_12,
              COL_13)
             SELECT I_DATADATE,
                    T.ORG_NUM,
                    T.DEPARTMENTD,
                    'CBRC' AS SYS_NAM,
                    'S7101' AS REP_NUM,
                    'S71_I_1..D5.2021' AS ITEM_NUM,
                    T.LOAN_ACCT_AMT,
                    --T1.INST_NAME AS COL_1,
                    T.CUST_ID AS COL_2,
                    T.CUST_NAM AS COL_3,
                    T.LOAN_NUM AS COL_4,
                    --T.LOAN_ACCT_AMT AS COL_5,
                    T.FACILITY_AMT AS COL_6,
                    T.ACCT_NUM AS COL_7,
                    T.DRAWDOWN_DT AS COL_8,
                    T.MATURITY_DT AS COL_9,
                    T.ITEM_CD AS COL_10,
                    T.DEPARTMENTD AS COL_11,
                    T2.M_NAME AS COL_12,
                    T.CP_NAME AS COL_13
               FROM CBRC_S7101_AMT_TMP1 T
               --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
               --  ON T.ORG_NUM = T1.INST_ID
               LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
                 ON T.CORP_SCALE = T2.M_CODE
                AND T2.M_TABLECODE = 'CORP_SCALE'
              WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
                AND T.DATA_DATE <= I_DATADATE
                --AND T.LOAN_ACCT_AMT <> 0
                AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                AND T.CORP_SCALE IN ('S', 'T') --小微企业
                AND ITEM_CD NOT LIKE '1301%' --不含贴现
                AND FACILITY_AMT <= 10000000;

          COMMIT;

        --【1.普惠型小微企业法人贷款 当年累放贷款户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.普惠型小微企业法人贷款  当年累放贷款户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        -- 1.普惠型小微企业法人贷款  当年累放贷款户数
        INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           --DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           --COL_1,
           COL_2,
           COL_3)
          SELECT I_DATADATE,
                 TT.ORG_NUM,
                 --TT.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 CASE
                   WHEN NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 1000000 THEN
                    'S71_I_1..E1.2018'
                   WHEN NVL(T.FACILITY_AMT, TT.FACILITY_AMT) > 1000000 AND
                        NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 5000000 THEN
                    'S71_I_1..E2.2018'
                   WHEN NVL(T.FACILITY_AMT, TT.FACILITY_AMT) > 5000000 AND
                        NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 10000000 THEN
                    'S71_I_1..E3.2018'
                   WHEN NVL(T.FACILITY_AMT, TT.FACILITY_AMT) > 10000000 AND
                        NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 30000000 THEN
                    'S71_I_1..E4.2018'
                 END AS ITEM_NUM,
                 '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计SUM值
                 --T1.INST_NAME AS COL_1,
                 TT.CUST_ID AS COL_2,
                 TT.CUST_NAM AS COL_3
            FROM CBRC_S7101_AMT_TMP1 TT
            --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
            --  ON TT.ORG_NUM = T1.INST_ID
            LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
              ON T.CUST_ID = TT.CUST_ID
             AND T.DATA_DATE = I_DATADATE --取当月的授信金额
             AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元以下,含本数 属于普惠型
           WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
             AND TT.DATA_DATE <= I_DATADATE
             AND SUBSTR(TT.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
             AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 30000000
             AND TT.CORP_SCALE IN ('S', 'T') --小微企业
             --AND TT.LOAN_ACCT_AMT <> 0
           GROUP BY --T1.INST_NAME,
                    TT.ORG_NUM,
                    TT.CUST_ID,
                    TT.CUST_NAM,
                    NVL(T.FACILITY_AMT, TT.FACILITY_AMT);
        COMMIT;

         -- 其中：单户授信1000万元（含）以下不含票据融资合计
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            --DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            --COL_1,
            COL_2,
            COL_3)
           SELECT I_DATADATE,
                  TT.ORG_NUM,
                  --TT.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1..E5.2021' AS ITEM_NUM,
                  '1' AS TOTAL_VALUE, --为了统计户数,定义字段5(默认为1,分组后客户不重复,就是1户,结果统计SUM值
                  --T1.INST_NAME AS COL_1,
                  TT.CUST_ID AS COL_2,
                  TT.CUST_NAM AS COL_3
             FROM CBRC_S7101_AMT_TMP1 TT
             --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
             --  ON TT.ORG_NUM = T1.INST_ID
             LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
               ON T.CUST_ID = TT.CUST_ID
              AND T.DATA_DATE = I_DATADATE --取当月的授信金额
              AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元元以下,含本数 属于普惠型
            WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND TT.DATA_DATE <= I_DATADATE
              AND SUBSTR(TT.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
              AND TT.CORP_SCALE IN ('S', 'T') --小微企业
              AND ITEM_CD NOT LIKE '1301%' --不含贴现
              --AND TT.LOAN_ACCT_AMT <> 0
              AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 10000000
            GROUP BY --T1.INST_NAME,
                     TT.ORG_NUM,
                     TT.CUST_ID,
                     TT.CUST_NAM;
        COMMIT;

        --【1.普惠型小微企业法人贷款 当年累放贷款年化利息收益】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.普惠型小微企业法人贷款  当年累放贷款年化利息收益';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        -- 1.普惠型小微企业法人贷款  当年累放贷款年化利息收益
         INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           --COL_1,
           COL_2,
           COL_3,
           COL_4,
           --COL_5,
           COL_6,
           COL_7,
           COL_8,
           COL_9,
           COL_10,
           COL_11,
           COL_12,
           COL_13)
          SELECT I_DATADATE,
                 T.ORG_NUM,
                 T.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 CASE
                   WHEN T.FACILITY_AMT <= 1000000 THEN
                    'S71_I_1..F1.2018'
                   WHEN T.FACILITY_AMT > 1000000 AND
                        T.FACILITY_AMT <= 5000000 THEN
                    'S71_I_1..F2.2018'
                   WHEN T.FACILITY_AMT > 5000000 AND
                        T.FACILITY_AMT <= 10000000 THEN
                    'S71_I_1..F3.2018'
                   WHEN T.FACILITY_AMT > 10000000 AND
                        T.FACILITY_AMT <= 30000000 THEN
                    'S71_I_1..F4.2018'
                 END AS ITEM_NUM,
                 T.NHSY AS TOTAL_VALUE,
                 --T1.INST_NAME AS COL_1,
                 T.CUST_ID AS COL_2,
                 T.CUST_NAM AS COL_3,
                 T.LOAN_NUM AS COL_4,
                 --T.NHSY AS COL_5,
                 T.FACILITY_AMT  AS COL_6,
                 T.ACCT_NUM AS COL_7,
                 T.DRAWDOWN_DT AS COL_8,
                 T.MATURITY_DT AS COL_9,
                 T.ITEM_CD AS COL_10,
                 T.DEPARTMENTD AS COL_11,
                 T2.M_NAME AS COL_12,
                 T.CP_NAME AS COL_13
            FROM CBRC_S7101_AMT_TMP1 T
            --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
            --  ON T.ORG_NUM = T1.INST_ID
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
              ON T.CORP_SCALE = T2.M_CODE
             AND T2.M_TABLECODE = 'CORP_SCALE'
           WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
             AND T.DATA_DATE <= I_DATADATE
             --AND T.NHSY <> 0
             AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
             AND T.CORP_SCALE IN ('S', 'T'); --小微企业

         COMMIT;

          -- 其中：单户授信1000万元（含）以下不含票据融资合计

          INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           --COL_1,
           COL_2,
           COL_3,
           COL_4,
           --COL_5,
           COL_6,
           COL_7,
           COL_8,
           COL_9,
           COL_10,
           COL_11,
           COL_12,
           COL_13)
          SELECT I_DATADATE,
                 T.ORG_NUM,
                 T.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 'S71_I_1..F5.2021' AS ITEM_NUM,
                 T.NHSY AS TOTAL_VALUE,
                 --T1.INST_NAME AS COL_1,
                 T.CUST_ID AS COL_2,
                 T.CUST_NAM AS COL_3,
                 T.LOAN_NUM AS COL_4,
                 --T.NHSY AS COL_5,
                 T.FACILITY_AMT  AS COL_6,
                 T.ACCT_NUM AS COL_7,
                 T.DRAWDOWN_DT AS COL_8,
                 T.MATURITY_DT AS COL_9,
                 T.ITEM_CD AS COL_10,
                 T.DEPARTMENTD AS COL_11,
                 T2.M_NAME AS COL_12,
                 T.CP_NAME AS COL_13
            FROM CBRC_S7101_AMT_TMP1 T
            --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
            --  ON T.ORG_NUM = T1.INST_ID
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
              ON T.CORP_SCALE = T2.M_CODE
             AND T2.M_TABLECODE = 'CORP_SCALE'
           WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
             AND T.DATA_DATE <= I_DATADATE
             --AND T.NHSY <> 0
             AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
             AND T.CORP_SCALE IN ('S', 'T') --小微企业
             AND ITEM_CD NOT LIKE '1301%' --不含贴现
             AND T.FACILITY_AMT <= 10000000;

         COMMIT;
    ------------------------------------------
    --1.1其中：普惠型涉农小微企业法人贷款
    ------------------------------------------

      --【1.1其中：普惠型涉农小微企业法人贷款  当年累放贷款额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1其中：普惠型涉农小微企业法人贷款  单户授信3000万元（含）以下合计 当年累放贷款额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

       -- 1.1其中：普惠型涉农小微企业法人贷款  单户授信3000万元（含）以下合计 当年累放贷款额
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            --COL_1,
            COL_2,
            COL_3,
            COL_4,
            --COL_5,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13,
            COL_15)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.1.D.2018' AS ITEM_NUM,
                  T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                  --T1.INST_NAME AS COL_1,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  --T.LOAN_ACCT_AMT AS COL_5,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13,
                  T3.M_NAME AS COL_15
             FROM CBRC_S7101_AMT_TMP1 T
             --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
             --  ON T.ORG_NUM = T1.INST_ID
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
               ON REPLACE(REPLACE(T.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
              AND T.CORP_SCALE IN ('S', 'T') --小微企业
              AND T.AGREI_P_FLG = 'Y'
              --AND T.LOAN_ACCT_AMT <> 0
              AND T.FACILITY_AMT <= 30000000; --取涉农

          COMMIT;

        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1其中：普惠型涉农小微企业法人贷款  单户授信1000万元（含）以下合计 当年累放贷款额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

         -- 1.1其中：普惠型涉农小微企业法人贷款   单户授信1000万元（含）以下合计 当年累放贷款额
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            --COL_1,
            COL_2,
            COL_3,
            COL_4,
            --COL_5,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13,
            COL_15)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.1.D0.2022' AS ITEM_NUM,
                  T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                  --T1.INST_NAME AS COL_1,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  --T.LOAN_ACCT_AMT AS COL_5,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13,
                  T3.M_NAME AS COL_15
             FROM CBRC_S7101_AMT_TMP1 T
             --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
             --  ON T.ORG_NUM = T1.INST_ID
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
               ON REPLACE(REPLACE(T.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
              AND T.CORP_SCALE IN ('S', 'T') --小微企业
              AND T.AGREI_P_FLG = 'Y' --取涉农
              --AND T.LOAN_ACCT_AMT <> 0
              AND FACILITY_AMT <= 10000000;

          COMMIT;

        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1其中：普惠型涉农小微企业法人贷款  其中：单户授信1000万元（含）以下不含票据融资合计 当年累放贷款额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

         -- 1.1其中：普惠型涉农小微企业法人贷款   其中：单户授信1000万元（含）以下不含票据融资合计 当年累放贷款额
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            --COL_1,
            COL_2,
            COL_3,
            COL_4,
            --COL_5,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13,
            COL_15)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.1.D5.2022' AS ITEM_NUM,
                  T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                  --T1.INST_NAME AS COL_1,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  --T.LOAN_ACCT_AMT AS COL_5,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13,
                  T3.M_NAME AS COL_15
             FROM CBRC_S7101_AMT_TMP1 T
             --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
             -- ON T.ORG_NUM = T1.INST_ID
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
              ON REPLACE(REPLACE(T.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
              AND T.CORP_SCALE IN ('S', 'T') --小微企业
              AND T.AGREI_P_FLG = 'Y' --取涉农
              AND T.ITEM_CD NOT LIKE '1301%' --刨除票据
              --AND T.LOAN_ACCT_AMT <> 0
              AND FACILITY_AMT <= 10000000;

          COMMIT;

       --【1.1其中：普惠型涉农小微企业法人贷款  当年累放贷款户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1其中：普惠型涉农小微企业法人贷款  单户授信3000万元（含）以下合计 当年累放贷款户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);
        --1.1其中：普惠型涉农小微企业法人贷款  单户授信3000万元（含）以下合计 当年累放贷款户数
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             --DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             --COL_1,
             COL_2,
             COL_3)
            SELECT I_DATADATE,
                   TT.ORG_NUM,
                   --TT.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_1.1.E.2018' AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计SUM值
                   --T1.INST_NAME AS COL_1,
                   TT.CUST_ID AS COL_2,
                   TT.CUST_NAM AS COL_3
              FROM CBRC_S7101_AMT_TMP1 TT
              --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
              --  ON TT.ORG_NUM = T1.INST_ID
              LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
                ON T.CUST_ID = TT.CUST_ID
               AND T.DATA_DATE = I_DATADATE --取当月的授信金额
               AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元以下,含本数 属于普惠型
             INNER JOIN CBRC_S7101_SNDK_TEMP F
                ON F.DATA_DATE = I_DATADATE
               AND TT.LOAN_NUM = F.LOAN_NUM
             WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
               AND TT.DATA_DATE <= I_DATADATE
               AND SUBSTR(TT.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
               AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 30000000
               AND TT.CORP_SCALE IN ('S', 'T') --小微企业
             GROUP BY --T1.INST_NAME,
                      TT.ORG_NUM,
                      TT.CUST_ID,
                      TT.CUST_NAM;
        COMMIT;

        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1其中：普惠型涉农小微企业法人贷款  单户授信1000万元（含）以下合计 当年累放贷款户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        --1.1其中：普惠型涉农小微企业法人贷款  单户授信1000万元（含）以下合计 当年累放贷款户数
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             --DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             --COL_1,
             COL_2,
             COL_3)
            SELECT I_DATADATE,
                   TT.ORG_NUM,
                   --TT.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_1.1.E0.2022' AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计SUM值
                   --T1.INST_NAME AS COL_1,
                   TT.CUST_ID AS COL_2,
                   TT.CUST_NAM AS COL_3
              FROM CBRC_S7101_AMT_TMP1 TT
              --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
              --  ON TT.ORG_NUM = T1.INST_ID
              LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
                ON T.CUST_ID = TT.CUST_ID
               AND T.DATA_DATE = I_DATADATE --取当月的授信金额
               AND T.FACILITY_AMT <= 10000000 --单户授信总额1000万元以下,含本数 属于普惠型
             INNER JOIN CBRC_S7101_SNDK_TEMP F
                ON F.DATA_DATE = I_DATADATE
               AND TT.LOAN_NUM = F.LOAN_NUM
             WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
               AND TT.DATA_DATE <= I_DATADATE
               AND SUBSTR(TT.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
               AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 10000000
               AND TT.FACILITY_AMT <= 10000000
               AND TT.CORP_SCALE IN ('S', 'T') --小微企业
             GROUP BY --T1.INST_NAME,
                      TT.ORG_NUM,
                      TT.CUST_ID,
                      TT.CUST_NAM;
        COMMIT;

        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1其中：普惠型涉农小微企业法人贷款  其中：单户授信1000万元（含）以下不含票据融资合计 当年累放贷款户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

       --1.1其中：普惠型涉农小微企业法人贷款  其中：单户授信1000万元（含）以下不含票据融资合计 当年累放贷款户数
        INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           --DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           --COL_1,
           COL_2,
           COL_3)
          SELECT I_DATADATE,
                 TT.ORG_NUM,
                 --TT.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 'S71_I_1.1.E5.2022' AS ITEM_NUM,
                 '1' AS TOTAL_VALUE, --为了统计户数,定义字段5(默认为1,分组后客户不重复,就是1户,结果统计SUM值
                 --T1.INST_NAME AS COL_1,
                 TT.CUST_ID AS COL_2,
                 TT.CUST_NAM AS COL_3
            FROM CBRC_S7101_AMT_TMP1 TT
            --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
            --  ON TT.ORG_NUM = T1.INST_ID
            LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
              ON T.CUST_ID = TT.CUST_ID
             AND T.DATA_DATE = I_DATADATE --取当月的授信金额
             AND T.FACILITY_AMT <= 10000000 --单户授信总额1000万元以下,含本数 属于普惠型
           INNER JOIN CBRC_S7101_SNDK_TEMP F
              ON F.DATA_DATE = I_DATADATE
             AND TT.LOAN_NUM = F.LOAN_NUM
           WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
             AND TT.DATA_DATE <= I_DATADATE
             AND SUBSTR(TT.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
             AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 10000000
             AND TT.FACILITY_AMT <= 10000000
             AND TT.CORP_SCALE IN ('S', 'T') --小微企业
             AND TT.ITEM_CD NOT LIKE '1301%' --刨除票据
           GROUP BY --T1.INST_NAME,
                    TT.ORG_NUM,
                    TT.CUST_ID,
                    TT.CUST_NAM;
        COMMIT;

       --【1.1其中：普惠型涉农小微企业法人贷款  当年累放贷款年化利息收益】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1其中：普惠型涉农小微企业法人贷款 单户授信3000万元（含）以下合计 当年累放贷款年化利息收益';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        -- 1.1其中：普惠型涉农小微企业法人贷款 单户授信3000万元（含）以下合计 当年累放贷款年化利息收益
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            --COL_1,
            COL_2,
            COL_3,
            COL_4,
            --COL_5,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13,
            COL_15)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.1.F.2018' AS ITEM_NUM,
                  T.NHSY AS TOTAL_VALUE,
                  --T1.INST_NAME AS COL_1,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  --T.NHSY AS COL_5,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13,
                  T3.M_NAME AS COL_15
             FROM CBRC_S7101_AMT_TMP1 T
             --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
             --  ON T.ORG_NUM = T1.INST_ID
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
               ON REPLACE(REPLACE(T.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
              AND T.CORP_SCALE IN ('S', 'T') --小微企业
              AND T.FACILITY_AMT <= 30000000
              --AND T.LOAN_ACCT_AMT <> 0
              AND AGREI_P_FLG = 'Y'; --取涉农

         COMMIT;

        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1其中：普惠型涉农小微企业法人贷款 单户授信1000万元（含）以下合计 当年累放贷款年化利息收益';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

         -- 1.1其中：普惠型涉农小微企业法人贷款 单户授信1000万元（含）以下合计 当年累放贷款年化利息收益
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            --COL_1,
            COL_2,
            COL_3,
            COL_4,
            --COL_5,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13,
            COL_15)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.1.F0.2022' AS ITEM_NUM,
                  T.NHSY AS TOTAL_VALUE,
                  --T1.INST_NAME AS COL_1,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  --T.NHSY AS COL_5,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13,
                  T3.M_NAME AS COL_15
             FROM CBRC_S7101_AMT_TMP1 T
             --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
             --  ON T.ORG_NUM = T1.INST_ID
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
               ON REPLACE(REPLACE(T.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              --AND T.NHSY <> 0
              AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
              AND T.CORP_SCALE IN ('S', 'T') --小微企业
              AND T.FACILITY_AMT <= 10000000
              AND AGREI_P_FLG = 'Y';

         COMMIT;

        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1其中：普惠型涉农小微企业法人贷款 其中：单户授信1000万元（含）以下不含票据融资合计 当年累放贷款年化利息收益';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

         -- 1.1其中：普惠型涉农小微企业法人贷款 其中：单户授信1000万元（含）以下不含票据融资合计 当年累放贷款年化利息收益
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            --COL_1,
            COL_2,
            COL_3,
            COL_4,
            --COL_5,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13 ,
            COL_15)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.1.F5.2022' AS ITEM_NUM,
                  T.NHSY AS TOTAL_VALUE,
                  --T1.INST_NAME AS COL_1,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  --T.NHSY AS COL_5,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13,
                  T3.M_NAME AS COL_15
             FROM CBRC_S7101_AMT_TMP1 T
             --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
             --  ON T.ORG_NUM = T1.INST_ID
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
               ON REPLACE(REPLACE(T.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
              AND T.CORP_SCALE IN ('S', 'T') --小微企业
              AND T.ITEM_CD NOT LIKE '1301%' --刨除票据
              AND T.FACILITY_AMT <= 10000000
              --AND T.NHSY <> 0
              AND AGREI_P_FLG = 'Y';


         COMMIT;

        --【1.1其中：普惠型涉农小微企业法人贷款  贷款余额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1其中：普惠型涉农小微企业法人贷款  贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

         -- 1.1其中：普惠型涉农小微企业法人贷款  贷款余额
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             --COL_1,
             COL_2,
             COL_3,
             COL_4,
             --COL_5,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14,
             COL_15)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_1.1.A4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_1.1.A3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_1.1.A2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_1.1.A1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   --T.INST_NAME AS COL_1,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   --T.LOAN_ACCT_BAL AS COL_5,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14,
                   T2.M_NAME AS COL_15
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON REPLACE(REPLACE(T.SNDKFL, 'P_', ''), 'C_', '') = T2.M_CODE
             WHERE DATA_DATE = I_DATADATE
               AND LOAN_ACCT_BAL <> 0
               AND PHXSNXWQYFRDK = '是';

      COMMIT;

       -- 其中：单户授信1000万元（含）以下不含票据融资合计
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            --COL_1,
            COL_2,
            COL_3,
            COL_4,
            --COL_5,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13,
            COL_14,
            COL_15)
           SELECT T.DATA_DATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.1.A5.2022' AS ITEM_NUM,
                  T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                  --T.INST_NAME AS COL_1,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  --T.LOAN_ACCT_BAL AS COL_5,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T.CORP_SCALE AS COL_12,
                  T.CP_NAME AS COL_13,
                  T.LOAN_GRADE_CD AS COL_14,
                  T2.M_NAME AS COL_15
             FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON REPLACE(REPLACE(T.SNDKFL, 'P_', ''), 'C_', '') = T2.M_CODE
            WHERE DATA_DATE = I_DATADATE
              AND PHXSNXWQYFRDK = '是'
              AND T.LOAN_ACCT_BAL <> 0
              AND ITEM_CD NOT LIKE '1301%' --不含贴现
              AND FACILITY_AMT <= 10000000;

      COMMIT;

    --【1.1其中：普惠型涉农小微企业法人贷款  贷款余额户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1其中：普惠型涉农小微企业法人贷款  贷款余额户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

      -- 1.1其中：普惠型涉农小微企业法人贷款 贷款余额户数
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             --DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             --COL_1,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   --T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_1.1.B4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_1.1.B3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_1.1.B2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_1.1.B1.2018'
                   END AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                   --T.INST_NAME AS COL_1,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXSNXWQYFRDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
             GROUP BY T.SXFW,
                      T.DATA_DATE,
                      T.ORG_NUM,
                      --T.INST_NAME,
                      T.CUST_ID,
                      T.CUST_NAM;
           COMMIT;

            -- 其中：单户授信1000万元（含）以下不含票据融资合计
            INSERT INTO CBRC_A_REPT_DWD_S7101
              (DATA_DATE,
               ORG_NUM,
               --DATA_DEPARTMENT,
               SYS_NAM,
               REP_NUM,
               ITEM_NUM,
               TOTAL_VALUE,
               --COL_1,
               COL_2,
               COL_3)
              SELECT T.DATA_DATE,
                     T.ORG_NUM,
                     --T.DEPARTMENTD,
                     'CBRC' AS SYS_NAM,
                     'S7101' AS REP_NUM,
                     'S71_I_1.1.B5.2022' AS ITEM_NUM,
                     '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                     --T.INST_NAME AS COL_1,
                     T.CUST_ID AS COL_2,
                     T.CUST_NAM AS COL_3
                FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
               WHERE DATA_DATE = I_DATADATE
                 AND PHXSNXWQYFRDK = '是'
                 AND T.LOAN_ACCT_BAL <> 0
                 AND ITEM_CD NOT LIKE '1301%' --不含贴现
                 AND FACILITY_AMT <= 10000000
               GROUP BY T.DATA_DATE,
                        T.ORG_NUM,
                        --T.INST_NAME,
                        T.CUST_ID,
                        T.CUST_NAM;
           COMMIT;

     --【1.1其中：普惠型涉农小微企业法人贷款  不良贷款余额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1其中：普惠型涉农小微企业法人贷款  不良贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

      -- 1.1其中：普惠型涉农小微企业法人贷款 不良贷款余额
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             --COL_1,
             COL_2,
             COL_3,
             COL_4,
             --COL_5,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14,
             COL_15)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_1.1.C4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_1.1.C3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_1.1.C2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_1.1.C1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   --T.INST_NAME AS COL_1,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   --T.LOAN_ACCT_BAL AS COL_5,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14,
                   T2.M_NAME AS COL_15
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
              LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON REPLACE(REPLACE(T.SNDKFL, 'P_', ''), 'C_', '') = T2.M_CODE
             WHERE DATA_DATE = I_DATADATE
               AND PHXSNXWQYFRDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失'); --不良贷款
         COMMIT;

           -- 其中：单户授信1000万元（含）以下不含票据融资合计

           INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             --COL_1,
             COL_2,
             COL_3,
             COL_4,
             --COL_5,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14,
             COL_15)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_1.1.C5.2022' AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   --T.INST_NAME AS COL_1,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   --T.LOAN_ACCT_BAL AS COL_5,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14,
                   T2.M_NAME AS COL_15
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
              LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON REPLACE(REPLACE(T.SNDKFL, 'P_', ''), 'C_', '') = T2.M_CODE
             WHERE DATA_DATE = I_DATADATE
               AND PHXSNXWQYFRDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失')--不良贷款
               AND ITEM_CD NOT LIKE '1301%' --不含贴现
               AND FACILITY_AMT <= 10000000;
         COMMIT;


    ------------------------------------------
    --1.1.1 其中：普惠型农村集体经济组织贷款
    ------------------------------------------
       --【1.1.1 其中：普惠型农村集体经济组织贷款 当年累放贷款额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1.1 其中：普惠型农村集体经济组织贷款  当年累放贷款额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             --COL_1,
             COL_2,
             COL_3,
             COL_4,
             --COL_5,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13)
            SELECT I_DATADATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_1.4.D.2018' AS ITEM_NUM,
                   T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                   --T1.INST_NAME AS COL_1,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   --T.LOAN_ACCT_AMT AS COL_5,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T2.M_NAME AS COL_12,
                   T.CP_NAME AS COL_13
              FROM CBRC_S7101_AMT_TMP1 T
              --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
              -- ON T.ORG_NUM = T1.INST_ID
              LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
                ON T.CORP_SCALE = T2.M_CODE
               AND T2.M_TABLECODE = 'CORP_SCALE'
             WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
               AND T.DATA_DATE <= I_DATADATE
               AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
               AND T.CORP_SCALE IN ('S', 'T') --小微企业
               AND T.RUR_COLL_ECO_ORG_LOAN_FLG = 'Y' --农村集体经济组织贷款标志
               AND AGREI_P_FLG = 'Y'; ---涉农标志

          COMMIT;


        --【1.1.1 其中：普惠型农村集体经济组织贷款 当年累放贷款户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1.1 其中：普惠型农村集体经济组织贷款  当年累放贷款户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           --DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           --COL_1,
           COL_2,
           COL_3)
          SELECT I_DATADATE,
                 TT.ORG_NUM,
                 --TT.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 'S71_I_1.4.E.2018' AS ITEM_NUM,
                 '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计SUM值
                 --T1.INST_NAME AS COL_1,
                 TT.CUST_ID AS COL_2,
                 TT.CUST_NAM AS COL_3
            FROM CBRC_S7101_AMT_TMP1 TT
            --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
            --  ON TT.ORG_NUM = T1.INST_ID
            LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
              ON T.CUST_ID = TT.CUST_ID
             AND T.DATA_DATE = I_DATADATE --取当月的授信金额
             AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元以下,含本数 属于普惠型
           WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
             AND TT.DATA_DATE <= I_DATADATE
             AND SUBSTR(TT.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
             AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 30000000
             AND TT.CORP_SCALE IN ('S', 'T') --小微企业
             AND TT.RUR_COLL_ECO_ORG_LOAN_FLG = 'Y' --农村集体经济组织贷款标志
             AND TT.AGREI_P_FLG = 'Y' ---涉农标志
           GROUP BY --T1.INST_NAME,
                    TT.ORG_NUM,
                    TT.CUST_ID,
                    TT.CUST_NAM;
        COMMIT;


        --【1.1.1 其中：普惠型农村集体经济组织贷款 当年累放贷款年化利息收益】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1.1 其中：普惠型农村集体经济组织贷款  当年累放贷款年化利息收益';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            --COL_1,
            COL_2,
            COL_3,
            COL_4,
            --COL_5,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.4.F.2018' AS ITEM_NUM,
                  T.NHSY AS TOTAL_VALUE,
                  --T1.INST_NAME AS COL_1,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  --T.NHSY AS COL_5,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
             -- ON T.ORG_NUM = T1.INST_ID
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
              AND T.CORP_SCALE IN ('S', 'T') --小微企业
              AND T.RUR_COLL_ECO_ORG_LOAN_FLG = 'Y' --农村集体经济组织贷款标志
              AND T.AGREI_P_FLG = 'Y'; ---涉农标志

         COMMIT;


       --【1.1.1 其中：普惠型农村集体经济组织贷款  贷款余额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1.1 其中：普惠型农村集体经济组织贷款  贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             --COL_1,
             COL_2,
             COL_3,
             COL_4,
             --COL_5,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_1.4.A4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_1.4.A3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_1.4.A2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_1.4.A1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   --T.INST_NAME AS COL_1,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   --T.LOAN_ACCT_BAL AS COL_5,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND T.LOAN_ACCT_BAL <> 0
               AND PHXNCJTJJZZDK = '是';

      COMMIT;


    --【1.1.1 其中：普惠型农村集体经济组织贷款  贷款余额户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1.1 其中：普惠型农村集体经济组织贷款  贷款余额户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             --DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             --COL_1,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   --T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_1.4.B4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_1.4.B3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_1.4.B2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_1.4.B1.2018'
                   END AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                   --T.INST_NAME AS COL_1,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXNCJTJJZZDK = '是'
             GROUP BY T.SXFW,
                      T.DATA_DATE,
                      T.ORG_NUM,
                      --T.INST_NAME,
                      T.CUST_ID,
                      T.CUST_NAM;
           COMMIT;



     --【1.1.1 其中：普惠型农村集体经济组织贷款  不良贷款余额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1.1 其中：普惠型农村集体经济组织贷款  不良贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             --COL_1,
             COL_2,
             COL_3,
             COL_4,
             --COL_5,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_1.4.C4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_1.4.C3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_1.4.C2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_1.4.C1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   --T.INST_NAME AS COL_1,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   --T.LOAN_ACCT_BAL AS COL_5,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXNCJTJJZZDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失'); --不良贷款
         COMMIT;


    ------------------------------------------
    --1.1.2 其中：普惠型农民专业合作社贷款
    ------------------------------------------
      --【1.1.2 其中：普惠型农民专业合作社贷款 当年累放贷款额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1.2 其中：普惠型农民专业合作社贷款  当年累放贷款额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             --COL_1,
             COL_2,
             COL_3,
             COL_4,
             --COL_5,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13)
            SELECT I_DATADATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_1.5.D.2018' AS ITEM_NUM,
                   T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                   --T1.INST_NAME AS COL_1,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   --T.LOAN_ACCT_AMT AS COL_5,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T2.M_NAME AS COL_12,
                   T.CP_NAME AS COL_13
              FROM CBRC_S7101_AMT_TMP1 T
              --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
              --  ON T.ORG_NUM = T1.INST_ID
              LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
             WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
               AND T.DATA_DATE <= I_DATADATE
               AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
               AND T.CORP_SCALE IN ('S', 'T') --小微企业
               AND T.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
               AND AGREI_P_FLG = 'Y'; ---涉农标志

          COMMIT;


        --【1.1.2 其中：普惠型农民专业合作社贷款 当年累放贷款户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1.2 其中：普惠型农民专业合作社贷款  当年累放贷款户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           --DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           --COL_1,
           COL_2,
           COL_3 )
          SELECT I_DATADATE,
                 TT.ORG_NUM,
                 --TT.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 'S71_I_1.5.E.2018' AS ITEM_NUM,
                 '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计SUM值
                 --T1.INST_NAME AS COL_1,
                 TT.CUST_ID AS COL_2,
                 TT.CUST_NAM AS COL_3
            FROM CBRC_S7101_AMT_TMP1 TT
            --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
            --  ON TT.ORG_NUM = T1.INST_ID
            LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
              ON T.CUST_ID = TT.CUST_ID
             AND T.DATA_DATE = I_DATADATE --取当月的授信金额
             AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元以下,含本数 属于普惠型
           WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
             AND TT.DATA_DATE <= I_DATADATE
             AND SUBSTR(TT.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
             AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 30000000
             AND TT.CORP_SCALE IN ('S', 'T') --小微企业
             AND TT.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
             AND TT.AGREI_P_FLG = 'Y' ---涉农标志
           GROUP BY --T1.INST_NAME,
                    TT.ORG_NUM,
                    TT.CUST_ID,
                    TT.CUST_NAM;
        COMMIT;


        --【1.1.2 其中：普惠型农民专业合作社贷款 当年累放贷款年化利息收益】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1.2 其中：普惠型农民专业合作社贷款  当年累放贷款年化利息收益';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            --COL_1,
            COL_2,
            COL_3,
            COL_4,
            --COL_5,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.5.F.2018' AS ITEM_NUM,
                  T.NHSY AS TOTAL_VALUE,
                  --T1.INST_NAME AS COL_1,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  --T.NHSY AS COL_5,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
             --  ON T.ORG_NUM = T1.INST_ID
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
              AND T.CORP_SCALE IN ('S', 'T') --小微企业
              AND T.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
              AND T.AGREI_P_FLG = 'Y'; ---涉农标志

         COMMIT;


       --【1.1.2 其中：普惠型农民专业合作社贷款   贷款余额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1.2 其中：普惠型农民专业合作社贷款   贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_1.5.A3.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_1.5.A3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_1.5.A2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_1.5.A1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND T.LOAN_ACCT_BAL <> 0
               AND PHXNMZYHZSDK = '是';

      COMMIT;


       --【1.1.2 其中：普惠型农民专业合作社贷款  贷款余额户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1.2 其中：普惠型农民专业合作社贷款  贷款余额户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             --DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   --T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_1.5.B4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_1.5.B3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_1.5.B2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_1.5.B1.2018'
                   END AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXNMZYHZSDK = '是'
               AND LOAN_ACCT_BAL <> 0
             GROUP BY T.SXFW,
                      T.DATA_DATE,
                      T.ORG_NUM,
                      T.CUST_ID,
                      T.CUST_NAM;
           COMMIT;



     --【1.1.2 其中：普惠型农民专业合作社贷款  不良贷款余额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.1.2 其中：普惠型农民专业合作社贷款  不良贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_1.5.C4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_1.5.C3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_1.5.C2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_1.5.C1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXNMZYHZSDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失'); --不良贷款
         COMMIT;


    ------------------------------------------
    --1.2其中：普惠型科技型小微企业法人贷款
    ------------------------------------------
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.2其中：普惠型科技型小微企业法人贷款  当年累放贷款额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_16,
             COL_17,
             COL_18,
             COL_19,
             COL_20,
             COL_21,
             COL_22)
            SELECT I_DATADATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_1.2.D.2025' AS ITEM_NUM,
                   T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T2.M_NAME AS COL_12,
                   T.CP_NAME AS COL_13,
                   DECODE(TECH_CORP_TYPE,'1','是','否') AS COL_16,
                   DECODE(IF_HIGH_SALA_CORP,'Y','是','否') AS COL_17,
                   DECODE(IF_GJJSCXSFQY,'Y','是','否') AS COL_18,
                   DECODE(IF_ZCYDXGJQY,'Y','是','否') AS COL_19,
                   DECODE(IF_ZJTXKH,'Y','是','否') AS COL_20,
                   DECODE(IF_ZJTXXJRQY,'Y','是','否') AS COL_21,
                   DECODE(IF_CXXQY,'Y','是','否') AS COL_22
              FROM CBRC_S7101_AMT_TMP1 T
              LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
             WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
               AND T.DATA_DATE <= I_DATADATE
               AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
               AND T.CORP_SCALE IN ('S', 'T') --小微企业
               AND (TECH_CORP_TYPE = '1' --科技型企业类型
                   OR IF_HIGH_SALA_CORP = 'Y' --是否高新技术
                   OR IF_GJJSCXSFQY = 'Y' --是否国家技术创新示范企业
                   OR IF_ZCYDXGJQY = 'Y' --是否制造业单项冠军企业
                   OR IF_ZJTXKH = 'Y' --是否专精特新客户
                   OR IF_ZJTXXJRQY = 'Y' --是否专精特新小巨人企业
                   OR IF_CXXQY = 'Y' --创新型企业
                   );

          COMMIT;


        --【1.2其中：普惠型科技型小微企业法人贷款 当年累放贷款户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.2其中：普惠型科技型小微企业法人贷款  当年累放贷款户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           --DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3)
          SELECT I_DATADATE,
                 TT.ORG_NUM,
                 --TT.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 'S71_I_1.2.E.2025' AS ITEM_NUM,
                 '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计SUM值
                 TT.CUST_ID AS COL_2,
                 TT.CUST_NAM AS COL_3
            FROM CBRC_S7101_AMT_TMP1 TT
            LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
              ON T.CUST_ID = TT.CUST_ID
             AND T.DATA_DATE = I_DATADATE --取当月的授信金额
             AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元以下,含本数 属于普惠型
           WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
             AND TT.DATA_DATE <= I_DATADATE
             AND SUBSTR(TT.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
             AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 30000000
             AND TT.CORP_SCALE IN ('S', 'T') --小微企业
             AND (TECH_CORP_TYPE = '1' --科技型企业类型
                 OR IF_HIGH_SALA_CORP = 'Y' --是否高新技术
                 OR IF_GJJSCXSFQY = 'Y' --是否国家技术创新示范企业
                 OR IF_ZCYDXGJQY = 'Y' --是否制造业单项冠军企业
                 OR IF_ZJTXKH = 'Y' --是否专精特新客户
                 OR IF_ZJTXXJRQY = 'Y' --是否专精特新小巨人企业
                 OR IF_CXXQY = 'Y' --创新型企业
                 )
           GROUP BY TT.ORG_NUM,
                    TT.CUST_ID,
                    TT.CUST_NAM;
        COMMIT;


        --【1.2其中：普惠型科技型小微企业法人贷款 当年累放贷款年化利息收益】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.2其中：普惠型科技型小微企业法人贷款  当年累放贷款年化利息收益';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13,
            COL_16,
            COL_17,
            COL_18,
            COL_19,
            COL_20,
            COL_21,
            COL_22)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.2.F.2025' AS ITEM_NUM,
                  T.NHSY AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13,
                  DECODE(TECH_CORP_TYPE, '1', '是', '否') AS COL_16,
                  DECODE(IF_HIGH_SALA_CORP, 'Y', '是', '否') AS COL_17,
                  DECODE(IF_GJJSCXSFQY, 'Y', '是', '否') AS COL_18,
                  DECODE(IF_ZCYDXGJQY, 'Y', '是', '否') AS COL_19,
                  DECODE(IF_ZJTXKH, 'Y', '是', '否') AS COL_20,
                  DECODE(IF_ZJTXXJRQY, 'Y', '是', '否') AS COL_21,
                  DECODE(IF_CXXQY, 'Y', '是', '否') AS COL_22
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
              AND T.CORP_SCALE IN ('S', 'T') --小微企业
              AND (TECH_CORP_TYPE = '1' --科技型企业类型
                  OR IF_HIGH_SALA_CORP = 'Y' --是否高新技术
                  OR IF_GJJSCXSFQY = 'Y' --是否国家技术创新示范企业
                  OR IF_ZCYDXGJQY = 'Y' --是否制造业单项冠军企业
                  OR IF_ZJTXKH = 'Y' --是否专精特新客户
                  OR IF_ZJTXXJRQY = 'Y' --是否专精特新小巨人企业
                  OR IF_CXXQY = 'Y' --创新型企业
                  );

         COMMIT;


       --【1.2其中：普惠型科技型小微企业法人贷款   贷款余额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.2其中：普惠型科技型小微企业法人贷款   贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14,
             COL_16,
             COL_17,
             COL_18,
             COL_19,
             COL_20,
             COL_21,
             COL_22)
          SELECT T.DATA_DATE,
                 T.ORG_NUM,
                 T.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 CASE
                   WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                    'S71_I_1.2.A4.2025'
                   WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                    'S71_I_1.2.A3.2025'
                   WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                    'S71_I_1.2.A2.2025'
                   WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                    'S71_I_1.2.A1.2025'
                 END AS ITEM_NUM,
                 T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                 T.CUST_ID AS COL_2,
                 T.CUST_NAM AS COL_3,
                 T.LOAN_NUM AS COL_4,
                 T.FACILITY_AMT AS COL_6,
                 T.ACCT_NUM AS COL_7,
                 T.DRAWDOWN_DT AS COL_8,
                 T.MATURITY_DT AS COL_9,
                 T.ITEM_CD AS COL_10,
                 T.DEPARTMENTD AS COL_11,
                 T.CORP_SCALE AS COL_12,
                 T.CP_NAME AS COL_13,
                 T.LOAN_GRADE_CD AS COL_14,
                 NVL(IF_TECH_CORP_TYPE,'否') AS COL_16,
                 NVL(IF_HIGH_SALA_CORP,'否') AS COL_17,
                 NVL(IF_GJJSCXSFQY,'否') AS COL_18,
                 NVL(IF_ZCYDXGJQY,'否') AS COL_19,
                 NVL(IF_ZJTXKH,'否') AS COL_20,
                 NVL(IF_ZJTXXJRQY,'否') AS COL_21,
                 NVL(IF_CXXQY,'否') AS COL_22
            FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
           WHERE DATA_DATE = I_DATADATE
             AND T.LOAN_ACCT_BAL <> 0
             AND PHXKCXWQYFRDK = '是';

      COMMIT;


       --【1.2其中：普惠型科技型小微企业法人贷款  贷款余额户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.2其中：普惠型科技型小微企业法人贷款  贷款余额户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             --DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   --T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_1.2.B4.2025'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_1.2.B3.2025'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_1.2.B2.2025'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_1.2.B1.2025'
                   END AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXKCXWQYFRDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
             GROUP BY T.SXFW,
                      T.DATA_DATE,
                      T.ORG_NUM,
                      T.CUST_ID,
                      T.CUST_NAM;
           COMMIT;



     --【1.2其中：普惠型科技型小微企业法人贷款  不良贷款余额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.2其中：普惠型科技型小微企业法人贷款  不良贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14,
             COL_16,
             COL_17,
             COL_18,
             COL_19,
             COL_20,
             COL_21,
             COL_22)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_1.2.C4.2025'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_1.2.C3.2025'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_1.2.C2.2025'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_1.2.C1.2025'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14,
                   DECODE(IF_TECH_CORP_TYPE,'1','是','否') AS COL_16,
                   DECODE(IF_HIGH_SALA_CORP,'Y','是','否') AS COL_17,
                   DECODE(IF_GJJSCXSFQY,'Y','是','否') AS COL_18,
                   DECODE(IF_ZCYDXGJQY,'Y','是','否') AS COL_19,
                   DECODE(IF_ZJTXKH,'Y','是','否') AS COL_20,
                   DECODE(IF_ZJTXXJRQY,'Y','是','否') AS COL_21,
                   DECODE(IF_CXXQY,'Y','是','否') AS COL_22
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
             WHERE DATA_DATE = I_DATADATE
               AND PHXKCXWQYFRDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失'); --不良贷款
         COMMIT;

    ------------------------------------------
    --1.3其中：小微企业法人创业担保贷款
    ------------------------------------------
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.3其中：小微企业法人创业担保贷款  当年累放贷款额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13)
            SELECT I_DATADATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_1.3.D.2018' AS ITEM_NUM,
                   T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T2.M_NAME AS COL_12,
                   T.CP_NAME AS COL_13
              FROM CBRC_S7101_AMT_TMP1 T
              LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
             WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
               AND T.DATA_DATE <= I_DATADATE
               AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
               AND T.CORP_SCALE IN ('S', 'T') --小微企业
               AND T.UNDERTAK_GUAR_TYPE IN ('A', 'B'); ---创业担保  口径 曲得光

          COMMIT;


        --【1.3其中：小微企业法人创业担保贷款 当年累放贷款户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.3其中：小微企业法人创业担保贷款  当年累放贷款户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           --DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3)
          SELECT I_DATADATE,
                 TT.ORG_NUM,
                 --TT.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 'S71_I_1.3.E.2018' AS ITEM_NUM,
                 '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计SUM值
                 TT.CUST_ID AS COL_2,
                 TT.CUST_NAM AS COL_3
            FROM CBRC_S7101_AMT_TMP1 TT
            LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
              ON T.CUST_ID = TT.CUST_ID
             AND T.DATA_DATE = I_DATADATE --取当月的授信金额
             AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元以下,含本数 属于普惠型
           WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
             AND TT.DATA_DATE <= I_DATADATE
             AND SUBSTR(TT.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
             AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 30000000
             AND TT.CORP_SCALE IN ('S', 'T') --小微企业
             AND TT.UNDERTAK_GUAR_TYPE IN ('A', 'B') ---创业担保  口径 曲得光
           GROUP BY TT.ORG_NUM,
                    TT.CUST_ID,
                    TT.CUST_NAM;
        COMMIT;


        --【1.3其中：小微企业法人创业担保贷款 当年累放贷款年化利息收益】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.3其中：小微企业法人创业担保贷款  当年累放贷款年化利息收益';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.3.F.2018' AS ITEM_NUM,
                  T.NHSY AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
              AND T.CORP_SCALE IN ('S', 'T') --小微企业
              AND T.UNDERTAK_GUAR_TYPE IN ('A', 'B'); ---创业担保  口径 曲得光

         COMMIT;


       --【1.3其中：小微企业法人创业担保贷款   贷款余额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.3其中：小微企业法人创业担保贷款   贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_1.3.A4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_1.3.A3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_1.3.A2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_1.3.A1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND T.LOAN_ACCT_BAL <> 0
               AND XWQYFRCYDBDK = '是';

      COMMIT;


       --【1.3其中：小微企业法人创业担保贷款  贷款余额户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.3其中：小微企业法人创业担保贷款  贷款余额户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             --DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   --T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_1.3.B4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_1.3.B3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_1.3.B2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_1.3.B1.2018'
                   END AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND XWQYFRCYDBDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
             GROUP BY T.SXFW,
                      T.DATA_DATE,
                      T.ORG_NUM,
                      T.CUST_ID,
                      T.CUST_NAM;
           COMMIT;



     --【1.3其中：小微企业法人创业担保贷款  不良贷款余额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.3其中：小微企业法人创业担保贷款  不良贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_1.3.C4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_1.3.C3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_1.3.C2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_1.3.C1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND XWQYFRCYDBDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失'); --不良贷款
         COMMIT;

    ------------------------------------------
    --1.4 普惠型小微企业法人中长期贷款
    ------------------------------------------

        --【1.4 普惠型小微企业法人中长期贷款 贷款余额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.4 普惠型小微企业法人中长期贷款 贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);


         -- 其中：单户授信1000万元（含）以下不含票据融资合计

         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13,
            COL_14)
           SELECT T.DATA_DATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.4.A5.2025' AS ITEM_NUM,
                  T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T.CORP_SCALE AS COL_12,
                  T.CP_NAME AS COL_13,
                  T.LOAN_GRADE_CD AS COL_14
             FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
            WHERE DATA_DATE = I_DATADATE
              AND PHXXWQYFRZCQDK = '是'
              AND T.LOAN_ACCT_BAL <> 0
              AND ITEM_CD NOT LIKE '1301%' --不含贴现
              AND FACILITY_AMT <= 10000000;
       COMMIT;

       --【1.4 普惠型小微企业法人中长期贷款 贷款余额户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.4 普惠型小微企业法人中长期贷款 贷款余额户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);


         -- 其中：单户授信1000万元（含）以下不含票据融资合计
        INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           --DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3)
          SELECT T.DATA_DATE,
                 T.ORG_NUM,
                 --T.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 'S71_I_1.4.B5.2025' AS ITEM_NUM,
                 '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                 T.CUST_ID AS COL_2,
                 T.CUST_NAM AS COL_3
            FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
           WHERE DATA_DATE = I_DATADATE
             AND PHXXWQYFRZCQDK = '是'
             AND T.LOAN_ACCT_BAL <> 0
             AND ITEM_CD NOT LIKE '1301%' --不含贴现
             AND FACILITY_AMT <= 10000000
           GROUP BY T.DATA_DATE,
                    T.ORG_NUM,
                    T.CUST_ID,
                    T.CUST_NAM;
       COMMIT;

    ------------------------------------------
    --1.a普惠型小型企业法人贷款
    ------------------------------------------
     --【1.a普惠型小型企业法人贷款 贷款余额】
      V_STEP_ID   := V_STEP_ID + 1;
      V_STEP_FLAG := 0;
      V_STEP_DESC := '1.a普惠型小型企业法人贷款 单户授信1000万元（含）以下合计 贷款余额';
      SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                  V_STEP_ID,
                  V_ERRORCODE,
                  V_STEP_DESC,
                  II_DATADATE);

      -- 1.a普惠型小型企业法人贷款  单户授信1000万元（含）以下合计 贷款余额
      INSERT INTO CBRC_A_REPT_DWD_S7101
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE,
         COL_2,
         COL_3,
         COL_4,
         COL_6,
         COL_7,
         COL_8,
         COL_9,
         COL_10,
         COL_11,
         COL_12,
         COL_13,
         COL_14)
        SELECT T.DATA_DATE,
               T.ORG_NUM,
               T.DEPARTMENTD,
               'CBRC' AS SYS_NAM,
               'S7101' AS REP_NUM,
               'S71_I_1.a.A0.2025' AS ITEM_NUM,
               T.LOAN_ACCT_BAL AS TOTAL_VALUE,
               T.CUST_ID AS COL_2,
               T.CUST_NAM AS COL_3,
               T.LOAN_NUM AS COL_4,
               T.FACILITY_AMT AS COL_6,
               T.ACCT_NUM AS COL_7,
               T.DRAWDOWN_DT AS COL_8,
               T.MATURITY_DT AS COL_9,
               T.ITEM_CD AS COL_10,
               T.DEPARTMENTD AS COL_11,
               T.CORP_SCALE AS COL_12,
               T.CP_NAME AS COL_13,
               T.LOAN_GRADE_CD AS COL_14
          FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
         WHERE DATA_DATE = I_DATADATE
           AND PHXXXQYFRDK = '是'
           AND T.LOAN_ACCT_BAL <> 0
           AND FACILITY_AMT <= 10000000;

      COMMIT;

      -- 其中：单户授信1000万元（含）以下不含票据融资合计

      INSERT INTO CBRC_A_REPT_DWD_S7101
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE,
         COL_2,
         COL_3,
         COL_4,
         COL_6,
         COL_7,
         COL_8,
         COL_9,
         COL_10,
         COL_11,
         COL_12,
         COL_13,
         COL_14)
        SELECT T.DATA_DATE,
               T.ORG_NUM,
               T.DEPARTMENTD,
               'CBRC' AS SYS_NAM,
               'S7101' AS REP_NUM,
               'S71_I_1.a.A5.2025' AS ITEM_NUM,
               T.LOAN_ACCT_BAL AS TOTAL_VALUE,
               T.CUST_ID AS COL_2,
               T.CUST_NAM AS COL_3,
               T.LOAN_NUM AS COL_4,
               T.FACILITY_AMT AS COL_6,
               T.ACCT_NUM AS COL_7,
               T.DRAWDOWN_DT AS COL_8,
               T.MATURITY_DT AS COL_9,
               T.ITEM_CD AS COL_10,
               T.DEPARTMENTD AS COL_11,
               T.CORP_SCALE AS COL_12,
               T.CP_NAME AS COL_13,
               T.LOAN_GRADE_CD AS COL_14
          FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
         WHERE DATA_DATE = I_DATADATE
           AND PHXXXQYFRDK = '是'
           AND ITEM_CD NOT LIKE '1301%' --不含贴现
           AND T.LOAN_ACCT_BAL <> 0
           AND FACILITY_AMT <= 10000000;
      COMMIT;



       --【1.a普惠型小型企业法人贷款 贷款余额户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.a普惠型小型企业法人贷款 贷款余额户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

          -- 1.a普惠型小型企业法人贷款 贷款余额户数
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             --DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   --T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_1.a.B0.2025' AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXXXQYFRDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND FACILITY_AMT <= 10000000
             GROUP BY T.DATA_DATE,
                      T.ORG_NUM,
                      T.CUST_ID,
                      T.CUST_NAM;
           COMMIT;

             -- 其中：单户授信1000万元（含）以下不含票据融资合计
             INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             --DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   --T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_1.a.B5.2025' AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXXXQYFRDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND ITEM_CD NOT LIKE '1301%' --不含贴现
               AND FACILITY_AMT <= 10000000
             GROUP BY T.DATA_DATE,
                      T.ORG_NUM,
                      T.CUST_ID,
                      T.CUST_NAM;
           COMMIT;

         --【1.a普惠型小型企业法人贷款 不良贷款余额】
      V_STEP_ID   := V_STEP_ID + 1;
      V_STEP_FLAG := 0;
      V_STEP_DESC := '1.a普惠型小型企业法人贷款 不良贷款余额';
      SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                  V_STEP_ID,
                  V_ERRORCODE,
                  V_STEP_DESC,
                  II_DATADATE);


          -- 1.a普惠型小型企业法人贷款 不良贷款余额
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_1.a.C0.2025' AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXXXQYFRDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失') --不良贷款
               AND FACILITY_AMT <= 10000000;
         COMMIT;

           -- 其中：单户授信1000万元（含）以下不含票据融资合计

           INSERT INTO CBRC_A_REPT_DWD_S7101
             (DATA_DATE,
              ORG_NUM,
              DATA_DEPARTMENT,
              SYS_NAM,
              REP_NUM,
              ITEM_NUM,
              TOTAL_VALUE,
              COL_2,
              COL_3,
              COL_4,
              COL_6,
              COL_7,
              COL_8,
              COL_9,
              COL_10,
              COL_11,
              COL_12,
              COL_13,
              COL_14)
             SELECT T.DATA_DATE,
                    T.ORG_NUM,
                    T.DEPARTMENTD,
                    'CBRC' AS SYS_NAM,
                    'S7101' AS REP_NUM,
                    'S71_I_1.a.C5.2025' AS ITEM_NUM,
                    T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                    T.CUST_ID AS COL_2,
                    T.CUST_NAM AS COL_3,
                    T.LOAN_NUM AS COL_4,
                    T.FACILITY_AMT AS COL_6,
                    T.ACCT_NUM AS COL_7,
                    T.DRAWDOWN_DT AS COL_8,
                    T.MATURITY_DT AS COL_9,
                    T.ITEM_CD AS COL_10,
                    T.DEPARTMENTD AS COL_11,
                    T.CORP_SCALE AS COL_12,
                    T.CP_NAME AS COL_13,
                    T.LOAN_GRADE_CD AS COL_14
               FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
              WHERE DATA_DATE = I_DATADATE
                AND PHXXXQYFRDK = '是'
                AND LOAN_GRADE_CD IN ('次级', '可疑', '损失') --不良贷款
                AND ITEM_CD NOT LIKE '1301%' --不含贴现
                AND T.LOAN_ACCT_BAL <> 0
                AND FACILITY_AMT <= 10000000;
         COMMIT;



        --【1.a普惠型小型企业法人贷款 当年累放贷款额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.a普惠型小型企业法人贷款  当年累放贷款额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);


         -- 1.a普惠型小型企业法人贷款  当年累放贷款额
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.a.D0.2025' AS ITEM_NUM,
                  T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND t.CORP_SCALE IN ('S') --小型
              AND SUBSTR(t.CUST_TYP, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
              AND t.FACILITY_AMT <= 10000000 --授信额度1000万以下
              AND NOT EXISTS
            (SELECT 1
                     FROM CBRC_S7101_AMT_TMP1 C
                    WHERE (C.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志 --ADDED BY YHY 20211221
                          OR RUR_COLL_ECO_ORG_LOAN_FLG = 'Y')
                      AND SUBSTR(C.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                      AND C.AGREI_P_FLG = 'Y' ---涉农标志
                      AND C.CORP_SCALE IN ('S', 'T') --小微企业
                      AND T.LOAN_NUM = C.LOAN_NUM);

          COMMIT;

           -- 其中：单户授信1000万元（含）以下不含票据融资合计

         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.a.D5.2025' AS ITEM_NUM,
                  T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND T.CORP_SCALE IN ('S') --小型
              AND SUBSTR(T.CUST_TYP, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
              AND T.ITEM_CD NOT LIKE '1301%' --刨除票据
              AND T.FACILITY_AMT <= 10000000 --授信额度1000万以下
              AND NOT EXISTS
            (SELECT 1
                     FROM CBRC_S7101_AMT_TMP1 C
                    WHERE (C.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志 --ADDED BY YHY 20211221
                          OR RUR_COLL_ECO_ORG_LOAN_FLG = 'Y')
                      AND SUBSTR(C.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                      AND C.AGREI_P_FLG = 'Y' ---涉农标志
                      AND C.CORP_SCALE IN ('S', 'T') --小微企业
                      AND T.LOAN_NUM = C.LOAN_NUM);

          COMMIT;

        --【1.a普惠型小型企业法人贷款 当年累放贷款户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.a普惠型小型企业法人贷款  当年累放贷款户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        -- 1.a普惠型小型企业法人贷款  当年累放贷款户数
        INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           --DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3)
          SELECT I_DATADATE,
                 TT.ORG_NUM,
                 --TT.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 'S71_I_1.a.E0.2025' AS ITEM_NUM,
                 '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计SUM值
                 TT.CUST_ID AS COL_2,
                 TT.CUST_NAM AS COL_3
            FROM CBRC_S7101_AMT_TMP1 TT
            LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
              ON T.CUST_ID = TT.CUST_ID
             AND T.DATA_DATE = I_DATADATE --取当月的授信金额
             AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元以下,含本数 属于普惠型
           WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
             AND TT.DATA_DATE <= I_DATADATE
             AND TT.CORP_SCALE IN ('S') --小型
             AND SUBSTR(TT.CUST_TYP, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
             AND NOT EXISTS
           (SELECT 1
                    FROM CBRC_S7101_AMT_TMP1 C
                   WHERE (C.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志 --ADDED BY YHY 20211221
                         OR RUR_COLL_ECO_ORG_LOAN_FLG = 'Y')
                     AND SUBSTR(C.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                     AND C.AGREI_P_FLG = 'Y' ---涉农标志
                     AND C.CORP_SCALE IN ('S', 'T') --小微企业
                     AND TT.LOAN_NUM = C.LOAN_NUM)
             AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 10000000
           GROUP BY TT.ORG_NUM,
                    TT.CUST_ID,
                    TT.CUST_NAM;
        COMMIT;

         -- 其中：单户授信1000万元（含）以下不含票据融资合计
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            --DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3)
           SELECT I_DATADATE,
                  TT.ORG_NUM,
                  --TT.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.a.E5.2025' AS ITEM_NUM,
                  '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计SUM值
                  TT.CUST_ID AS COL_2,
                  TT.CUST_NAM AS COL_3
             FROM CBRC_S7101_AMT_TMP1 TT
             LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
               ON T.CUST_ID = TT.CUST_ID
              AND T.DATA_DATE = I_DATADATE --取当月的授信金额
              AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元元以下,含本数 属于普惠型
            WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND TT.DATA_DATE <= I_DATADATE
              AND TT.CORP_SCALE IN ('S') --小型
              AND SUBSTR(TT.CUST_TYP, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
              AND TT.ITEM_CD NOT LIKE '1301%' --刨除票据
              AND NOT EXISTS
            (SELECT 1
                     FROM CBRC_S7101_AMT_TMP1 C
                    WHERE (C.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志 --ADDED BY YHY 20211221
                          OR RUR_COLL_ECO_ORG_LOAN_FLG = 'Y')
                      AND SUBSTR(C.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                      AND C.AGREI_P_FLG = 'Y' ---涉农标志
                      AND C.CORP_SCALE IN ('S', 'T') --小微企业
                      AND TT.LOAN_NUM = C.LOAN_NUM)
              AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 10000000
            GROUP BY TT.ORG_NUM,
                     TT.CUST_ID,
                     TT.CUST_NAM;
        COMMIT;

        --【1.a普惠型小型企业法人贷款 当年累放贷款年化利息收益】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.a普惠型小型企业法人贷款  当年累放贷款年化利息收益';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        -- 1.a普惠型小型企业法人贷款  当年累放贷款年化利息收益
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.a.F0.2025' AS ITEM_NUM,
                  T.NHSY AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND T.CORP_SCALE IN ('S') --小型
              AND SUBSTR(T.CUST_TYP, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
              AND T.FACILITY_AMT <= 10000000 --授信额度1000万以下
              AND NOT EXISTS
            (SELECT 1
                     FROM CBRC_S7101_AMT_TMP1 C
                    WHERE (C.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志 --ADDED BY YHY 20211221
                          OR RUR_COLL_ECO_ORG_LOAN_FLG = 'Y')
                      AND SUBSTR(C.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                      AND C.AGREI_P_FLG = 'Y' ---涉农标志
                      AND C.CORP_SCALE IN ('S', 'T') --小微企业
                      AND T.LOAN_NUM = C.LOAN_NUM);

         COMMIT;

          -- 其中：单户授信1000万元（含）以下不含票据融资合计

         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.a.F5.2025' AS ITEM_NUM,
                  T.NHSY AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND T.CORP_SCALE IN ('S') --小型
              AND SUBSTR(T.CUST_TYP, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
              AND T.ITEM_CD NOT LIKE '1301%' --刨除票据
              AND T.FACILITY_AMT <= 10000000 --授信额度1000万以下
              AND NOT EXISTS
            (SELECT 1
                     FROM CBRC_S7101_AMT_TMP1 C
                    WHERE (C.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志 --ADDED BY YHY 20211221
                          OR RUR_COLL_ECO_ORG_LOAN_FLG = 'Y')
                      AND SUBSTR(C.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                      AND C.AGREI_P_FLG = 'Y' ---涉农标志
                      AND C.CORP_SCALE IN ('S', 'T') --小微企业
                      AND T.LOAN_NUM = C.LOAN_NUM);
         COMMIT;

    ------------------------------------------
    --1.b普惠型微型企业法人贷款
    ------------------------------------------
    --【1.b普惠型微型企业法人贷款 贷款余额】
      V_STEP_ID   := V_STEP_ID + 1;
      V_STEP_FLAG := 0;
      V_STEP_DESC := '1.b普惠型微型企业法人贷款 单户授信1000万元（含）以下合计 贷款余额';
      SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                  V_STEP_ID,
                  V_ERRORCODE,
                  V_STEP_DESC,
                  II_DATADATE);

      -- 1.b普惠型微型企业法人贷款  单户授信1000万元（含）以下合计 贷款余额
      INSERT INTO CBRC_A_REPT_DWD_S7101
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE,
         COL_2,
         COL_3,
         COL_4,
         COL_6,
         COL_7,
         COL_8,
         COL_9,
         COL_10,
         COL_11,
         COL_12,
         COL_13,
         COL_14)
        SELECT T.DATA_DATE,
               T.ORG_NUM,
               T.DEPARTMENTD,
               'CBRC' AS SYS_NAM,
               'S7101' AS REP_NUM,
               'S71_I_1.b.A0.2025' AS ITEM_NUM,
               T.LOAN_ACCT_BAL AS TOTAL_VALUE,
               T.CUST_ID AS COL_2,
               T.CUST_NAM AS COL_3,
               T.LOAN_NUM AS COL_4,
               T.FACILITY_AMT AS COL_6,
               T.ACCT_NUM AS COL_7,
               T.DRAWDOWN_DT AS COL_8,
               T.MATURITY_DT AS COL_9,
               T.ITEM_CD AS COL_10,
               T.DEPARTMENTD AS COL_11,
               T.CORP_SCALE AS COL_12,
               T.CP_NAME AS COL_13,
               T.LOAN_GRADE_CD AS COL_14
          FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
         WHERE DATA_DATE = I_DATADATE
           AND PHXWXQYFRDK = '是'
           AND T.LOAN_ACCT_BAL <> 0
           AND FACILITY_AMT <= 10000000;

      COMMIT;

      -- 其中：单户授信1000万元（含）以下不含票据融资合计

      INSERT INTO CBRC_A_REPT_DWD_S7101
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE,
         COL_2,
         COL_3,
         COL_4,
         COL_6,
         COL_7,
         COL_8,
         COL_9,
         COL_10,
         COL_11,
         COL_12,
         COL_13,
         COL_14)
        SELECT T.DATA_DATE,
               T.ORG_NUM,
               T.DEPARTMENTD,
               'CBRC' AS SYS_NAM,
               'S7101' AS REP_NUM,
               'S71_I_1.b.A5.2025' AS ITEM_NUM,
               T.LOAN_ACCT_BAL AS TOTAL_VALUE,
               T.CUST_ID AS COL_2,
               T.CUST_NAM AS COL_3,
               T.LOAN_NUM AS COL_4,
               T.FACILITY_AMT AS COL_6,
               T.ACCT_NUM AS COL_7,
               T.DRAWDOWN_DT AS COL_8,
               T.MATURITY_DT AS COL_9,
               T.ITEM_CD AS COL_10,
               T.DEPARTMENTD AS COL_11,
               T.CORP_SCALE AS COL_12,
               T.CP_NAME AS COL_13,
               T.LOAN_GRADE_CD AS COL_14
          FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
         WHERE DATA_DATE = I_DATADATE
           AND PHXWXQYFRDK = '是'
           AND T.LOAN_ACCT_BAL <> 0
           AND ITEM_CD NOT LIKE '1301%' --不含贴现
           AND FACILITY_AMT <= 10000000;
      COMMIT;



       --【1.b普惠型微型企业法人贷款 贷款余额户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.b普惠型微型企业法人贷款 贷款余额户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

          -- 1.b普惠型微型企业法人贷款 贷款余额户数
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             --DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   --T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_1.b.B0.2025' AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXWXQYFRDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND FACILITY_AMT <= 10000000
             GROUP BY T.DATA_DATE,
                      T.ORG_NUM,
                      T.CUST_ID,
                      T.CUST_NAM;
           COMMIT;

             -- 其中：单户授信1000万元（含）以下不含票据融资合计
             INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             --DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   --T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_1.b.B5.2025' AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXWXQYFRDK = '是'
               AND ITEM_CD NOT LIKE '1301%' --不含贴现
               AND FACILITY_AMT <= 10000000
               AND T.LOAN_ACCT_BAL <> 0
             GROUP BY T.DATA_DATE,
                      T.ORG_NUM,
                      T.CUST_ID,
                      T.CUST_NAM;
           COMMIT;

         --【1.b普惠型微型企业法人贷款 不良贷款余额】
      V_STEP_ID   := V_STEP_ID + 1;
      V_STEP_FLAG := 0;
      V_STEP_DESC := '1.b普惠型微型企业法人贷款 不良贷款余额';
      SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                  V_STEP_ID,
                  V_ERRORCODE,
                  V_STEP_DESC,
                  II_DATADATE);


          -- 1.b普惠型微型企业法人贷款 不良贷款余额
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_1.b.C0.2025' AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXWXQYFRDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失') --不良贷款
               AND FACILITY_AMT <= 10000000;
         COMMIT;

           -- 其中：单户授信1000万元（含）以下不含票据融资合计

           INSERT INTO CBRC_A_REPT_DWD_S7101
             (DATA_DATE,
              ORG_NUM,
              DATA_DEPARTMENT,
              SYS_NAM,
              REP_NUM,
              ITEM_NUM,
              TOTAL_VALUE,
              COL_2,
              COL_3,
              COL_4,
              COL_6,
              COL_7,
              COL_8,
              COL_9,
              COL_10,
              COL_11,
              COL_12,
              COL_13,
              COL_14)
             SELECT T.DATA_DATE,
                    T.ORG_NUM,
                    T.DEPARTMENTD,
                    'CBRC' AS SYS_NAM,
                    'S7101' AS REP_NUM,
                    'S71_I_1.b.C5.2025' AS ITEM_NUM,
                    T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                    T.CUST_ID AS COL_2,
                    T.CUST_NAM AS COL_3,
                    T.LOAN_NUM AS COL_4,
                    T.FACILITY_AMT AS COL_6,
                    T.ACCT_NUM AS COL_7,
                    T.DRAWDOWN_DT AS COL_8,
                    T.MATURITY_DT AS COL_9,
                    T.ITEM_CD AS COL_10,
                    T.DEPARTMENTD AS COL_11,
                    T.CORP_SCALE AS COL_12,
                    T.CP_NAME AS COL_13,
                    T.LOAN_GRADE_CD AS COL_14
               FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
              WHERE DATA_DATE = I_DATADATE
                AND PHXWXQYFRDK = '是'
                AND T.LOAN_ACCT_BAL <> 0
                AND LOAN_GRADE_CD IN ('次级', '可疑', '损失') --不良贷款
                AND ITEM_CD NOT LIKE '1301%' --不含贴现
                AND FACILITY_AMT <= 10000000;
         COMMIT;



        --【1.b普惠型微型企业法人贷款 当年累放贷款额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.b普惠型微型企业法人贷款  当年累放贷款额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);


         -- 1.b普惠型微型企业法人贷款  当年累放贷款额
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.b.D0.2025' AS ITEM_NUM,
                  T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND t.CORP_SCALE IN ('T') --微型
              AND SUBSTR(t.CUST_TYP, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
              AND t.FACILITY_AMT <= 10000000 --授信额度1000万以下
              AND NOT EXISTS
            (SELECT 1
                     FROM CBRC_S7101_AMT_TMP1 C
                    WHERE (C.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志 --ADDED BY YHY 20211221
                          OR RUR_COLL_ECO_ORG_LOAN_FLG = 'Y')
                      AND SUBSTR(C.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                      AND C.AGREI_P_FLG = 'Y' ---涉农标志
                      AND C.CORP_SCALE IN ('S', 'T') --小微企业
                      AND T.LOAN_NUM = C.LOAN_NUM);

          COMMIT;

           -- 其中：单户授信1000万元（含）以下不含票据融资合计

         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.b.D5.2025' AS ITEM_NUM,
                  T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND T.CORP_SCALE IN ('T') --小型
              AND SUBSTR(T.CUST_TYP, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
              AND T.ITEM_CD NOT LIKE '1301%' --刨除票据
              AND T.FACILITY_AMT <= 10000000 --授信额度1000万以下
              AND NOT EXISTS
            (SELECT 1
                     FROM CBRC_S7101_AMT_TMP1 C
                    WHERE (C.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志 --ADDED BY YHY 20211221
                          OR RUR_COLL_ECO_ORG_LOAN_FLG = 'Y')
                      AND SUBSTR(C.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                      AND C.AGREI_P_FLG = 'Y' ---涉农标志
                      AND C.CORP_SCALE IN ('S', 'T') --小微企业
                      AND T.LOAN_NUM = C.LOAN_NUM);

          COMMIT;

        --【1.b普惠型微型企业法人贷款 当年累放贷款户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.b普惠型微型企业法人贷款  当年累放贷款户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        -- 1.b普惠型微型企业法人贷款  当年累放贷款户数
        INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3)
          SELECT I_DATADATE,
                 TT.ORG_NUM,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 'S71_I_1.b.E0.2025' AS ITEM_NUM,
                 '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计SUM值
                 TT.CUST_ID AS COL_2,
                 TT.CUST_NAM AS COL_3
            FROM CBRC_S7101_AMT_TMP1 TT
            LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
              ON T.CUST_ID = TT.CUST_ID
             AND T.DATA_DATE = I_DATADATE --取当月的授信金额
             AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元以下,含本数 属于普惠型
           WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
             AND TT.DATA_DATE <= I_DATADATE
             AND TT.CORP_SCALE IN ('T') --微型
             AND SUBSTR(TT.CUST_TYP, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
             AND NOT EXISTS
           (SELECT 1
                    FROM CBRC_S7101_AMT_TMP1 C
                   WHERE (C.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志 --ADDED BY YHY 20211221
                         OR RUR_COLL_ECO_ORG_LOAN_FLG = 'Y')
                     AND SUBSTR(C.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                     AND C.AGREI_P_FLG = 'Y' ---涉农标志
                     AND C.CORP_SCALE IN ('S', 'T') --小微企业
                     AND TT.LOAN_NUM = C.LOAN_NUM)
             AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 10000000
           GROUP BY TT.ORG_NUM,
                    TT.CUST_ID,
                    TT.CUST_NAM;
        COMMIT;

         -- 其中：单户授信1000万元（含）以下不含票据融资合计
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3)
           SELECT I_DATADATE,
                  TT.ORG_NUM,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.b.E5.2025' AS ITEM_NUM,
                  '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计SUM值
                  TT.CUST_ID AS COL_2,
                  TT.CUST_NAM AS COL_3
             FROM CBRC_S7101_AMT_TMP1 TT
             LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
               ON T.CUST_ID = TT.CUST_ID
              AND T.DATA_DATE = I_DATADATE --取当月的授信金额
              AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元元以下,含本数 属于普惠型
            WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND TT.DATA_DATE <= I_DATADATE
              AND TT.CORP_SCALE IN ('T') --微型
              AND SUBSTR(TT.CUST_TYP, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
              AND TT.ITEM_CD NOT LIKE '1301%' --刨除票据
              AND NOT EXISTS
            (SELECT 1
                     FROM CBRC_S7101_AMT_TMP1 C
                    WHERE (C.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志 --ADDED BY YHY 20211221
                          OR RUR_COLL_ECO_ORG_LOAN_FLG = 'Y')
                      AND SUBSTR(C.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                      AND C.AGREI_P_FLG = 'Y' ---涉农标志
                      AND C.CORP_SCALE IN ('S', 'T') --小微企业
                      AND TT.LOAN_NUM = C.LOAN_NUM)
              AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 10000000
            GROUP BY TT.ORG_NUM,
                     TT.CUST_ID,
                     TT.CUST_NAM;
        COMMIT;

        --【1.b普惠型微型企业法人贷款 当年累放贷款年化利息收益】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '1.b普惠型微型企业法人贷款  当年累放贷款年化利息收益';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        -- 1.b普惠型微型企业法人贷款  当年累放贷款年化利息收益
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.b.F0.2025' AS ITEM_NUM,
                  T.NHSY AS COL_5,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND T.CORP_SCALE IN ('T') --微型
              AND SUBSTR(T.CUST_TYP, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
              AND T.FACILITY_AMT <= 10000000 --授信额度1000万以下
              AND NOT EXISTS
            (SELECT 1
                     FROM CBRC_S7101_AMT_TMP1 C
                    WHERE (C.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志 --ADDED BY YHY 20211221
                          OR RUR_COLL_ECO_ORG_LOAN_FLG = 'Y')
                      AND SUBSTR(C.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                      AND C.AGREI_P_FLG = 'Y' ---涉农标志
                      AND C.CORP_SCALE IN ('S', 'T') --小微企业
                      AND T.LOAN_NUM = C.LOAN_NUM);

         COMMIT;

          -- 其中：单户授信1000万元（含）以下不含票据融资合计

         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.b.F5.2025' AS ITEM_NUM,
                  T.NHSY AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND T.CORP_SCALE IN ('T') --微型
              AND SUBSTR(T.CUST_TYP, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
              AND T.ITEM_CD NOT LIKE '1301%' --刨除票据
              AND T.FACILITY_AMT <= 10000000 --授信额度1000万以下
              AND NOT EXISTS
            (SELECT 1
                     FROM CBRC_S7101_AMT_TMP1 C
                    WHERE (C.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志 --ADDED BY YHY 20211221
                          OR RUR_COLL_ECO_ORG_LOAN_FLG = 'Y')
                      AND SUBSTR(C.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                      AND C.AGREI_P_FLG = 'Y' ---涉农标志
                      AND C.CORP_SCALE IN ('S', 'T') --小微企业
                      AND T.LOAN_NUM = C.LOAN_NUM);
         COMMIT;

        ------------------------------------------
        --2.普惠型其它组织贷款
        ------------------------------------------

         --【2.普惠型其它组织贷款 贷款余额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '2.普惠型其它组织贷款 贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

       -- 2.普惠型其它组织贷款 贷款余额
          INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3,
           COL_4,
           COL_6,
           COL_7,
           COL_8,
           COL_9,
           COL_10,
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT T.DATA_DATE,
                 T.ORG_NUM,
                 T.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 CASE
                   WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                    'S71_I_2..A4.2018'
                   WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                    'S71_I_2..A3.2018'
                   WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                    'S71_I_2..A2.2018'
                   WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                    'S71_I_2..A1.2018'
                 END AS ITEM_NUM,
                 T.LOAN_ACCT_BAL AS COL_5,
                 T.CUST_ID AS COL_2,
                 T.CUST_NAM AS COL_3,
                 T.LOAN_NUM AS COL_4,
                 T.FACILITY_AMT AS COL_6,
                 T.ACCT_NUM AS COL_7,
                 T.DRAWDOWN_DT AS COL_8,
                 T.MATURITY_DT AS COL_9,
                 T.ITEM_CD AS COL_10,
                 T.DEPARTMENTD AS COL_11,
                 T.CORP_SCALE AS COL_12,
                 T.CP_NAME AS COL_13,
                 T.LOAN_GRADE_CD AS COL_14
            FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
           WHERE DATA_DATE = I_DATADATE
             AND T.LOAN_ACCT_BAL <> 0
             AND PHXQTZZDK = '是';

      COMMIT;

      -- 其中：单户授信1000万元（含）以下不含票据融资合计

        INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3,
           COL_4,
           COL_6,
           COL_7,
           COL_8,
           COL_9,
           COL_10,
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT T.DATA_DATE,
                 T.ORG_NUM,
                 T.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 'S71_I_2..A5.2021' AS ITEM_NUM,
                 T.LOAN_ACCT_BAL AS COL_5,
                 T.CUST_ID AS COL_2,
                 T.CUST_NAM AS COL_3,
                 T.LOAN_NUM AS COL_4,
                 T.FACILITY_AMT AS COL_6,
                 T.ACCT_NUM AS COL_7,
                 T.DRAWDOWN_DT AS COL_8,
                 T.MATURITY_DT AS COL_9,
                 T.ITEM_CD AS COL_10,
                 T.DEPARTMENTD AS COL_11,
                 T.CORP_SCALE AS COL_12,
                 T.CP_NAME AS COL_13,
                 T.LOAN_GRADE_CD AS COL_14
            FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
           WHERE DATA_DATE = I_DATADATE
             AND PHXQTZZDK = '是'
             AND ITEM_CD NOT LIKE '1301%' --不含贴现
             AND T.LOAN_ACCT_BAL <> 0
             AND FACILITY_AMT <= 10000000;
      COMMIT;

     --【2.普惠型其它组织贷款 贷款余额户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '2.普惠型其它组织贷款 贷款余额户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

          -- 2.普惠型其它组织贷款 贷款余额户数
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_2..B4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_2..B3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_2..B2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_2..B1.2018'
                   END AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXQTZZDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
             GROUP BY T.SXFW,
                      T.DATA_DATE,
                      T.ORG_NUM,
                      T.CUST_ID,
                      T.CUST_NAM;
           COMMIT;

             -- 其中：单户授信1000万元（含）以下不含票据融资合计
             INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_2..B5.2021' AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXQTZZDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND ITEM_CD NOT LIKE '1301%' --不含贴现
               AND FACILITY_AMT <= 10000000
             GROUP BY T.DATA_DATE,
                      T.ORG_NUM,
                      T.CUST_ID,
                      T.CUST_NAM;
           COMMIT;
     --【2.普惠型其它组织贷款 不良贷款余额】
      V_STEP_ID   := V_STEP_ID + 1;
      V_STEP_FLAG := 0;
      V_STEP_DESC := '2.普惠型其它组织贷款 不良贷款余额';
      SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                  V_STEP_ID,
                  V_ERRORCODE,
                  V_STEP_DESC,
                  II_DATADATE);


          -- 2.普惠型其它组织贷款 不良贷款余额
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_2..C4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_2..C3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_2..C2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_2..C1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXQTZZDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失'); --不良贷款
         COMMIT;

           -- 其中：单户授信1000万元（含）以下不含票据融资合计

           INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_2..C5.2021' AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXQTZZDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失')--不良贷款
               AND ITEM_CD NOT LIKE '1301%' --不含贴现
               AND FACILITY_AMT <= 10000000;
         COMMIT;

        --【2.普惠型其它组织贷款 当年累放贷款额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '2.普惠型其它组织贷款  当年累放贷款额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);


         -- 2.普惠型其它组织贷款  当年累放贷款额
        INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3,
           COL_4,
           COL_6,
           COL_7,
           COL_8,
           COL_9,
           COL_10,
           COL_11,
           COL_12,
           COL_13)
          SELECT I_DATADATE,
                 T.ORG_NUM,
                 T.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 CASE
                   WHEN T.FACILITY_AMT <= 1000000 THEN
                    'S71_I_2..D1.2018'
                   WHEN T.FACILITY_AMT > 1000000 AND
                        T.FACILITY_AMT <= 5000000 THEN
                    'S71_I_2..D2.2018'
                   WHEN T.FACILITY_AMT > 5000000 AND
                        T.FACILITY_AMT <= 10000000 THEN
                    'S71_I_2..D3.2018'
                   WHEN T.FACILITY_AMT > 10000000 AND
                        T.FACILITY_AMT <= 30000000 THEN
                    'S71_I_2..D4.2018'
                 END AS ITEM_NUM,
                 T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                 T.CUST_ID AS COL_2,
                 T.CUST_NAM AS COL_3,
                 T.LOAN_NUM AS COL_4,
                 T.FACILITY_AMT AS COL_6,
                 T.ACCT_NUM AS COL_7,
                 T.DRAWDOWN_DT AS COL_8,
                 T.MATURITY_DT AS COL_9,
                 T.ITEM_CD AS COL_10,
                 T.DEPARTMENTD AS COL_11,
                 T2.M_NAME AS COL_12,
                 T.CP_NAME AS COL_13
            FROM CBRC_S7101_AMT_TMP1 T
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
           WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
             AND T.DATA_DATE <= I_DATADATE
             AND T.QT_FLAG = 'Y';  --取其它组织贷款

          COMMIT;

           -- 其中：单户授信1000万元（含）以下不含票据融资合计

           INSERT INTO CBRC_A_REPT_DWD_S7101
             (DATA_DATE,
              ORG_NUM,
              DATA_DEPARTMENT,
              SYS_NAM,
              REP_NUM,
              ITEM_NUM,
              TOTAL_VALUE,
              COL_2,
              COL_3,
              COL_4,
              COL_6,
              COL_7,
              COL_8,
              COL_9,
              COL_10,
              COL_11,
              COL_12,
              COL_13)
             SELECT I_DATADATE,
                    T.ORG_NUM,
                    T.DEPARTMENTD,
                    'CBRC' AS SYS_NAM,
                    'S7101' AS REP_NUM,
                    'S71_I_2..D5.2021' AS ITEM_NUM,
                    T.LOAN_ACCT_AMT AS COL_5,
                    T.CUST_ID AS COL_2,
                    T.CUST_NAM AS COL_3,
                    T.LOAN_NUM AS COL_4,
                    T.FACILITY_AMT AS COL_6,
                    T.ACCT_NUM AS COL_7,
                    T.DRAWDOWN_DT AS COL_8,
                    T.MATURITY_DT AS COL_9,
                    T.ITEM_CD AS COL_10,
                    T.DEPARTMENTD AS COL_11,
                    T2.M_NAME AS COL_12,
                    T.CP_NAME AS COL_13
               FROM CBRC_S7101_AMT_TMP1 T
               LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
                 ON T.CORP_SCALE = T2.M_CODE
                AND T2.M_TABLECODE = 'CORP_SCALE'
              WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
                AND T.DATA_DATE <= I_DATADATE
                AND T.QT_FLAG = 'Y' --取其它组织贷款
                AND ITEM_CD NOT LIKE '1301%' --不含贴现
                AND FACILITY_AMT <= 10000000;

          COMMIT;

         --【2.普惠型其它组织贷款 当年累放贷款户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '2.普惠型其它组织贷款  当年累放贷款户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        -- 2.普惠型其它组织贷款  当年累放贷款户数
        INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3)
          SELECT I_DATADATE,
                 TT.ORG_NUM,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 CASE
                   WHEN NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 1000000 THEN
                    'S71_I_2..E1.2018'
                   WHEN NVL(T.FACILITY_AMT, TT.FACILITY_AMT) > 1000000 AND
                        NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 5000000 THEN
                    'S71_I_2..E2.2018'
                   WHEN NVL(T.FACILITY_AMT, TT.FACILITY_AMT) > 5000000 AND
                        NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 10000000 THEN
                    'S71_I_2..E3.2018'
                   WHEN NVL(T.FACILITY_AMT, TT.FACILITY_AMT) > 10000000 AND
                        NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 30000000 THEN
                    'S71_I_2..E4.2018'
                 END AS ITEM_NUM,
                 '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计SUM值
                 TT.CUST_ID AS COL_2,
                 TT.CUST_NAM AS COL_3
            FROM CBRC_S7101_AMT_TMP1 TT
            LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
              ON T.CUST_ID = TT.CUST_ID
             AND T.DATA_DATE = I_DATADATE --取当月的授信金额
             AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元以下,含本数 属于普惠型
           WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
             AND TT.DATA_DATE <= I_DATADATE
             AND TT.QT_FLAG = 'Y' --取其它组织贷款
           GROUP BY TT.ORG_NUM,
                    TT.CUST_ID,
                    TT.CUST_NAM,
                    NVL(T.FACILITY_AMT, TT.FACILITY_AMT);
        COMMIT;

         -- 其中：单户授信1000万元（含）以下不含票据融资合计
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3)
           SELECT I_DATADATE,
                  TT.ORG_NUM,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_2..E5.2021' AS ITEM_NUM,
                  '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计SUM值
                  TT.CUST_ID AS COL_2,
                  TT.CUST_NAM AS COL_3
             FROM CBRC_S7101_AMT_TMP1 TT
             LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
               ON T.CUST_ID = TT.CUST_ID
              AND T.DATA_DATE = I_DATADATE --取当月的授信金额
              AND T.FACILITY_AMT <= 10000000 --单户授信总额1000万元元以下,含本数 属于普惠型
            WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND TT.DATA_DATE <= I_DATADATE
              AND TT.QT_FLAG = 'Y' --取其它组织贷款
              AND ITEM_CD NOT LIKE '1301%' --不含贴现
              AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 10000000
            GROUP BY TT.ORG_NUM,
                     TT.CUST_ID,
                     TT.CUST_NAM;
        COMMIT;

         --【2.普惠型其它组织贷款 当年累放贷款年化利息收益】
            V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '2.普惠型其它组织贷款  当年累放贷款年化利息收益';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        -- 2.普惠型其它组织贷款  当年累放贷款年化利息收益
         INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3,
           COL_4,
           COL_6,
           COL_7,
           COL_8,
           COL_9,
           COL_10,
           COL_11,
           COL_12,
           COL_13)
          SELECT I_DATADATE,
                 T.ORG_NUM,
                 T.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 CASE
                   WHEN T.FACILITY_AMT <= 1000000 THEN
                    'S71_I_2..F1.2018'
                   WHEN T.FACILITY_AMT > 1000000 AND
                        T.FACILITY_AMT <= 5000000 THEN
                    'S71_I_2..F2.2018'
                   WHEN T.FACILITY_AMT > 5000000 AND
                        T.FACILITY_AMT <= 10000000 THEN
                    'S71_I_2..F3.2018'
                   WHEN T.FACILITY_AMT > 10000000 AND
                        T.FACILITY_AMT <= 30000000 THEN
                    'S71_I_2..F4.2018'
                 END AS ITEM_NUM,
                 T.NHSY AS TOTAL_VALUE,
                 T.CUST_ID AS COL_2,
                 T.CUST_NAM AS COL_3,
                 T.LOAN_NUM AS COL_4,
                 T.FACILITY_AMT  AS COL_6,
                 T.ACCT_NUM AS COL_7,
                 T.DRAWDOWN_DT AS COL_8,
                 T.MATURITY_DT AS COL_9,
                 T.ITEM_CD AS COL_10,
                 T.DEPARTMENTD AS COL_11,
                 T2.M_NAME AS COL_12,
                 T.CP_NAME AS COL_13
            FROM CBRC_S7101_AMT_TMP1 T
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
           WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
             AND T.DATA_DATE <= I_DATADATE
             AND T.QT_FLAG = 'Y'; --取其它组织贷款

         COMMIT;

          -- 其中：单户授信1000万元（含）以下不含票据融资合计

          INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3,
           COL_4,
           COL_6,
           COL_7,
           COL_8,
           COL_9,
           COL_10,
           COL_11,
           COL_12,
           COL_13)
          SELECT I_DATADATE,
                 T.ORG_NUM,
                 T.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 'S71_I_2..F5.2021' AS ITEM_NUM,
                 T.NHSY AS TOTAL_VALUE,
                 T.CUST_ID AS COL_2,
                 T.CUST_NAM AS COL_3,
                 T.LOAN_NUM AS COL_4,
                 T.FACILITY_AMT  AS COL_6,
                 T.ACCT_NUM AS COL_7,
                 T.DRAWDOWN_DT AS COL_8,
                 T.MATURITY_DT AS COL_9,
                 T.ITEM_CD AS COL_10,
                 T.DEPARTMENTD AS COL_11,
                 T2.M_NAME AS COL_12,
                 T.CP_NAME AS COL_13
            FROM CBRC_S7101_AMT_TMP1 T
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
              ON T.CORP_SCALE = T2.M_CODE
             AND T2.M_TABLECODE = 'CORP_SCALE'
           WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
             AND T.DATA_DATE <= I_DATADATE
             AND T.QT_FLAG = 'Y' --取其它组织贷款
             AND T.ITEM_CD NOT LIKE '1301%' --不含贴现
             AND T.FACILITY_AMT <= 10000000;

         COMMIT;
    ------------------------------------------
    --3.普惠型个体工商户和小微企业主贷款
    ------------------------------------------

     --【3.普惠型个体工商户和小微企业主贷款 当年累放贷款额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.普惠型个体工商户和小微企业主贷款  当年累放贷款额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);


         -- 3.普惠型个体工商户和小微企业主贷款  当年累放贷款额
        INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3,
           COL_4,
           COL_6,
           COL_7,
           COL_8,
           COL_9,
           COL_10,
           COL_11,
           COL_12,
           COL_13,
           COL_23)
          SELECT I_DATADATE,
                 T.ORG_NUM,
                 T.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 CASE
                   WHEN T.FACILITY_AMT <= 1000000 THEN
                    'S71_I_3..D1.2018'
                   WHEN T.FACILITY_AMT > 1000000 AND
                        T.FACILITY_AMT <= 5000000 THEN
                    'S71_I_3..D2.2018'
                   WHEN T.FACILITY_AMT > 5000000 AND
                        T.FACILITY_AMT <= 10000000 THEN
                    'S71_I_3..D3.2018'
                   WHEN T.FACILITY_AMT > 10000000 AND
                        T.FACILITY_AMT <= 30000000 THEN
                    'S71_I_3..D4.2018'
                 END AS ITEM_NUM,
                 T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                 T.CUST_ID AS COL_2,
                 T.CUST_NAM AS COL_3,
                 T.LOAN_NUM AS COL_4,
                 T.FACILITY_AMT AS COL_6,
                 T.ACCT_NUM AS COL_7,
                 T.DRAWDOWN_DT AS COL_8,
                 T.MATURITY_DT AS COL_9,
                 T.ITEM_CD AS COL_10,
                 T.DEPARTMENTD AS COL_11,
                 T2.M_NAME AS COL_12,
                 T.CP_NAME AS COL_13,
                 CASE
                   WHEN T.OPERATE_CUST_TYPE IN ('A', '3') THEN
                    '个体工商户'
                   WHEN T.OPERATE_CUST_TYPE IN ('B') THEN
                    '小微企业主'
                   ELSE
                    '其他个人'
                 END AS COL_23
            FROM CBRC_S7101_AMT_TMP1 T
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
              ON T.CORP_SCALE = T2.M_CODE
             AND T2.M_TABLECODE = 'CORP_SCALE'
           WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
             AND T.DATA_DATE <= I_DATADATE
             AND T.OPERATE_CUST_TYPE IN ('A', 'B', '3'); --个人（A个体工商户和B小微企业主）对公（3个体工商户）

          COMMIT;

           -- 其中：单户授信1000万元（含）以下不含票据融资合计

         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13,
            COL_23)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_3..D5.2021' AS ITEM_NUM,
                  T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13,
                  CASE
                    WHEN T.OPERATE_CUST_TYPE IN ('A', '3') THEN
                     '个体工商户'
                    WHEN T.OPERATE_CUST_TYPE IN ('B') THEN
                     '小微企业主'
                    ELSE
                     '其他个人'
                  END AS COL_23
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND OPERATE_CUST_TYPE IN ('A', 'B', '3') --个人（A个体工商户和B小微企业主）对公（3个体工商户）
              AND FACILITY_AMT <= 10000000 --单户授信总额1000万元以下,含本数
              AND ITEM_CD NOT LIKE '1301%'; --刨除票据

          COMMIT;

        --【3.普惠型个体工商户和小微企业主贷款 当年累放贷款户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.普惠型个体工商户和小微企业主贷款  当年累放贷款户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        -- 3.普惠型个体工商户和小微企业主贷款  当年累放贷款户数
        INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3)
          SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'CBRC' AS SYS_NAM,
        'S7101' AS REP_NUM,
       CASE
         WHEN t.FACILITY_AMT <= 1000000 THEN
          'S71_I_3..E1.2018'
         WHEN t.FACILITY_AMT > 1000000 AND
              t.FACILITY_AMT <= 5000000 THEN
          'S71_I_3..E2.2018'
         WHEN t.FACILITY_AMT > 5000000 AND
              t.FACILITY_AMT <= 10000000 THEN
          'S71_I_3..E3.2018'
         WHEN t.FACILITY_AMT > 10000000 AND
              t.FACILITY_AMT <= 30000000 THEN
          'S71_I_3..E4.2018'
       END AS ITEM_NUM,
       '1' AS TOTAL_VALUE,
       T.CUST_ID AS COL_2,--客户号
       A.CUST_NAM AS COL_3--客户名称
      --SHIYU 20220126 修改内容：当年累放贷款户数按照本月最新额度范围划分
        FROM (

              --SHIYU 20220126 修改内容：当年累放贷款户数需按照本月最新授信额度划分
              SELECT  TT.CUST_ID,
                      TT.ORG_NUM,
                      MAX(nvl(T.FACILITY_AMT, tt.facility_amt))  FACILITY_AMT
                FROM CBRC_S7101_AMT_TMP1 TT
                left JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
                  ON T.CUST_ID = TT.CUST_ID
                 AND T.DATA_DATE = I_DATADATE --取当月的授信金额
                 AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元以下,含本数 属于普惠型
               WHERE TT.OPERATE_CUST_TYPE IN ('A', '3','B') --取个体工商户 对私：A,对公：3
                 and nvl(T.FACILITY_AMT, tt.facility_amt) <= 30000000
                 --AND   TT.ORG_NUM LIKE '050301%'
               GROUP BY TT.CUST_ID, TT.ORG_NUM
              ) T
             LEFT JOIN SMTMODS_L_CUST_ALL A
                ON T.CUST_ID =A.CUST_ID
                AND A.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN t.FACILITY_AMT <= 1000000 THEN
                   'S71_I_3..E1.2018'
                  WHEN t.FACILITY_AMT > 1000000 AND
                       t.FACILITY_AMT <= 5000000 THEN
                   'S71_I_3..E2.2018'
                  WHEN t.FACILITY_AMT > 5000000 AND
                       t.FACILITY_AMT <= 10000000 THEN
                   'S71_I_3..E3.2018'
                  WHEN t.FACILITY_AMT > 10000000 AND
                       t.FACILITY_AMT <= 30000000 THEN
                   'S71_I_3..E4.2018'
                END,T.CUST_ID,A.CUST_NAM;
        COMMIT;

         -- 其中：单户授信1000万元（含）以下不含票据融资合计
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3)
           SELECT I_DATADATE,
                  TT.ORG_NUM,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_3..E5.2021' AS ITEM_NUM,
                  '1' AS TOTAL_VALUE, --为了统计户数,定义字段5(默认为1,分组后客户不重复,就是1户,结果统计SUM值
                  TT.CUST_ID AS COL_2,
                  TT.CUST_NAM AS COL_3
             FROM CBRC_S7101_AMT_TMP1 TT
             LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
               ON T.CUST_ID = TT.CUST_ID
              AND T.DATA_DATE = I_DATADATE --取当月的授信金额
              AND T.FACILITY_AMT <= 10000000 --单户授信总额1000万元元以下,含本数 属于普惠型
            WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND TT.DATA_DATE <= I_DATADATE
              AND TT.OPERATE_CUST_TYPE IN ('A', 'B', '3') --个人（A个体工商户和B小微企业主）对公（3个体工商户）
              AND ITEM_CD NOT LIKE '1301%' --不含贴现
              AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 10000000
              AND TT.FACILITY_AMT <= 10000000
            GROUP BY TT.ORG_NUM,
                     TT.CUST_ID,
                     TT.CUST_NAM;
        COMMIT;

        --【3.普惠型个体工商户和小微企业主贷款 当年累放贷款年化利息收益】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.普惠型个体工商户和小微企业主贷款  当年累放贷款年化利息收益';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        -- 3.普惠型个体工商户和小微企业主贷款  当年累放贷款年化利息收益
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13,
            COL_23)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  CASE
                    WHEN T.FACILITY_AMT <= 1000000 THEN
                     'S71_I_3..F1.2018'
                    WHEN T.FACILITY_AMT > 1000000 AND
                         T.FACILITY_AMT <= 5000000 THEN
                     'S71_I_3..F2.2018'
                    WHEN T.FACILITY_AMT > 5000000 AND
                         T.FACILITY_AMT <= 10000000 THEN
                     'S71_I_3..F3.2018'
                    WHEN T.FACILITY_AMT > 10000000 AND
                         T.FACILITY_AMT <= 30000000 THEN
                     'S71_I_3..F4.2018'
                  END AS ITEM_NUM,
                  T.NHSY AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13,
                  CASE
                    WHEN T.OPERATE_CUST_TYPE IN ('A', '3') THEN
                     '个体工商户'
                    WHEN T.OPERATE_CUST_TYPE IN ('B') THEN
                     '小微企业主'
                    ELSE
                     '其他个人'
                  END AS COL_23
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND T.OPERATE_CUST_TYPE IN ('A', 'B', '3'); --个人（A个体工商户和B小微企业主）对公（3个体工商户）

         COMMIT;

          -- 其中：单户授信1000万元（含）以下不含票据融资合计

          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_23)
            SELECT I_DATADATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_3..F5.2021' AS ITEM_NUM,
                   T.NHSY AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T2.M_NAME AS COL_12,
                   T.CP_NAME AS COL_13,
                   CASE
                     WHEN T.OPERATE_CUST_TYPE IN ('A', '3') THEN
                      '个体工商户'
                     WHEN T.OPERATE_CUST_TYPE IN ('B') THEN
                      '小微企业主'
                     ELSE
                      '其他个人'
                   END AS COL_23
              FROM CBRC_S7101_AMT_TMP1 T
              LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
                ON T.CORP_SCALE = T2.M_CODE
               AND T2.M_TABLECODE = 'CORP_SCALE'
             WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
               AND T.DATA_DATE <= I_DATADATE
               AND T.OPERATE_CUST_TYPE IN ('A', 'B', '3') --个人（A个体工商户和B小微企业主）对公（3个体工商户）
               AND T.ITEM_CD NOT LIKE '1301%' --不含贴现
               AND T.FACILITY_AMT <= 10000000;

         COMMIT;

    ------------------------------------------
    --3.1其中：普惠型个体工商户贷款
    ------------------------------------------
      --【3.1其中：普惠型个体工商户贷款     当年累放贷款额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.1其中：普惠型个体工商户贷款  单户授信3000万元（含）以下合计 当年累放贷款额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

       -- 3.1其中：普惠型个体工商户贷款    单户授信3000万元（含）以下合计 当年累放贷款额
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_3.1.D.2018' AS ITEM_NUM,
                  T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND T.OPERATE_CUST_TYPE IN ('A', '3') --对私是：A,对公是：3 --取个体工商户
              AND T.FACILITY_AMT <= 30000000;

          COMMIT;



       --【3.1其中：普惠型个体工商户贷款  当年累放贷款户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.1其中：普惠型个体工商户贷款  单户授信3000万元（含）以下合计 当年累放贷款户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);
        --3.1其中：普惠型个体工商户贷款  单户授信3000万元（含）以下合计 当年累放贷款户数
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT I_DATADATE,
                   TT.ORG_NUM,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_3.1.E.2018' AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计SUM值
                   TT.CUST_ID AS COL_2,
                   TT.CUST_NAM AS COL_3
              FROM CBRC_S7101_AMT_TMP1 TT
              LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
                ON T.CUST_ID = TT.CUST_ID
               AND T.DATA_DATE = I_DATADATE --取当月的授信金额
               AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元以下,含本数 属于普惠型
             WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
               AND TT.DATA_DATE <= I_DATADATE
               AND TT.OPERATE_CUST_TYPE IN ('A', '3') --对私是：A,对公是：3 --取个体工商户
               AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 30000000
             GROUP BY TT.ORG_NUM,
                      TT.CUST_ID,
                      TT.CUST_NAM;
        COMMIT;


       --【3.1其中：普惠型个体工商户贷款  当年累放贷款年化利息收益】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.1其中：普惠型个体工商户贷款 单户授信3000万元（含）以下合计 当年累放贷款年化利息收益';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        -- 3.1其中：普惠型个体工商户贷款 单户授信3000万元（含）以下合计 当年累放贷款年化利息收益
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_3.1.F.2018' AS ITEM_NUM,
                  T.NHSY AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND T.OPERATE_CUST_TYPE IN ('A', '3') --对私是：A,对公是：3 --取个体工商户
              AND T.FACILITY_AMT <= 30000000;

         COMMIT;

          --【3.1其中：普惠型个体工商户贷款  贷款余额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.1其中：普惠型个体工商户贷款  贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

         -- 3.1其中：普惠型个体工商户贷款  贷款余额
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_3.1.A4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_3.1.A3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_3.1.A2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_3.1.A1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND T.LOAN_ACCT_BAL <> 0
               AND PHXGTGSHDK = '是';

      COMMIT;

       -- 其中：单户授信1000万元（含）以下不含票据融资合计
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13,
            COL_14)
           SELECT T.DATA_DATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_3.1.A5.2021' AS ITEM_NUM,
                  T.LOAN_ACCT_BAL AS COL_5,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T.CORP_SCALE AS COL_12,
                  T.CP_NAME AS COL_13,
                  T.LOAN_GRADE_CD AS COL_14
             FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
            WHERE DATA_DATE = I_DATADATE
              AND PHXGTGSHDK = '是'
              AND T.LOAN_ACCT_BAL <> 0
              AND ITEM_CD NOT LIKE '1301%' --不含贴现
              AND FACILITY_AMT <= 10000000;

      COMMIT;

    --【3.1其中：普惠型个体工商户贷款  贷款余额户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.1其中：普惠型个体工商户贷款  贷款余额户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

      -- 3.1其中：普惠型个体工商户贷款 贷款余额户数
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_3.1.B4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_3.1.B3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_3.1.B2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_3.1.B1.2018'
                   END AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXGTGSHDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
             GROUP BY T.SXFW,
                      T.DATA_DATE,
                      T.ORG_NUM,
                      T.CUST_ID,
                      T.CUST_NAM;
           COMMIT;

            -- 其中：单户授信1000万元（含）以下不含票据融资合计
            INSERT INTO CBRC_A_REPT_DWD_S7101
              (DATA_DATE,
               ORG_NUM,
               SYS_NAM,
               REP_NUM,
               ITEM_NUM,
               TOTAL_VALUE,
               COL_2,
               COL_3)
              SELECT T.DATA_DATE,
                     T.ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     'S7101' AS REP_NUM,
                     'S71_I_3.1.B5.2021' AS ITEM_NUM,
                     '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                     T.CUST_ID AS COL_2,
                     T.CUST_NAM AS COL_3
                FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
               WHERE DATA_DATE = I_DATADATE
                 AND PHXGTGSHDK = '是'
                 AND T.LOAN_ACCT_BAL <> 0
                 AND ITEM_CD NOT LIKE '1301%' --不含贴现
                 AND FACILITY_AMT <= 10000000
               GROUP BY T.DATA_DATE,
                        T.ORG_NUM,
                        T.CUST_ID,
                        T.CUST_NAM;
           COMMIT;

     --【3.1其中：普惠型个体工商户贷款  不良贷款余额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.1其中：普惠型个体工商户贷款  不良贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

      -- 3.1其中：普惠型个体工商户贷款 不良贷款余额
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_3.1.C4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_3.1.C3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_3.1.C2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_3.1.C1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXGTGSHDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失'); --不良贷款
         COMMIT;

           -- 其中：单户授信1000万元（含）以下不含票据融资合计

           INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_3.1.C5.2021' AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXGTGSHDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失')--不良贷款
               AND ITEM_CD NOT LIKE '1301%' --不含贴现
               AND FACILITY_AMT <= 10000000;
         COMMIT;




    ------------------------------------------
    --3.2其中：普惠型小微企业主贷款
    ------------------------------------------
     --【3.2其中：普惠型小微企业主贷款       当年累放贷款额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.2其中：普惠型小微企业主贷款    单户授信3000万元（含）以下合计 当年累放贷款额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

       -- 3.2其中：普惠型小微企业主贷款      单户授信3000万元（含）以下合计 当年累放贷款额
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_3.2.D.2018' AS ITEM_NUM,
                  T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND T.OPERATE_CUST_TYPE = 'B' --取小微企业住
              AND T.FACILITY_AMT <= 30000000;

          COMMIT;



       --【3.2其中：普惠型小微企业主贷款    当年累放贷款户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.2其中：普惠型小微企业主贷款    单户授信3000万元（含）以下合计 当年累放贷款户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);
        --3.2其中：普惠型小微企业主贷款    单户授信3000万元（含）以下合计 当年累放贷款户数
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT I_DATADATE,
                   TT.ORG_NUM,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_3.2.E.2018' AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计SUM值
                   TT.CUST_ID AS COL_2,
                   TT.CUST_NAM AS COL_3
              FROM CBRC_S7101_AMT_TMP1 TT
              LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
                ON T.CUST_ID = TT.CUST_ID
               AND T.DATA_DATE = I_DATADATE --取当月的授信金额
             WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
               AND TT.DATA_DATE <= I_DATADATE
               AND TT.OPERATE_CUST_TYPE = 'B' --取小微企业住
               AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 30000000
             GROUP BY TT.ORG_NUM,
                      TT.CUST_ID,
                      TT.CUST_NAM;
        COMMIT;


       --【3.2其中：普惠型小微企业主贷款    当年累放贷款年化利息收益】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.2其中：普惠型小微企业主贷款   单户授信3000万元（含）以下合计 当年累放贷款年化利息收益';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        -- 3.2其中：普惠型小微企业主贷款   单户授信3000万元（含）以下合计 当年累放贷款年化利息收益
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_3.2.F.2018' AS ITEM_NUM,
                  T.NHSY AS COL_5,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND T.OPERATE_CUST_TYPE = 'B' --取小微企业住
              AND T.FACILITY_AMT <= 30000000;

         COMMIT;

          --【3.2其中：普惠型小微企业主贷款    贷款余额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.2其中：普惠型小微企业主贷款    贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

         -- 3.2其中：普惠型小微企业主贷款    贷款余额
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_3.2.A4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_3.2.A3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_3.2.A2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_3.2.A1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND T.LOAN_ACCT_BAL <> 0
               AND PHXXWQYZDK = '是';

      COMMIT;

       -- 其中：单户授信1000万元（含）以下不含票据融资合计
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13,
            COL_14)
           SELECT T.DATA_DATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_3.2.A5.2021' AS ITEM_NUM,
                  T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T.CORP_SCALE AS COL_12,
                  T.CP_NAME AS COL_13,
                  T.LOAN_GRADE_CD AS COL_14
             FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
            WHERE DATA_DATE = I_DATADATE
              AND PHXXWQYZDK = '是'
              AND T.LOAN_ACCT_BAL <> 0
              AND ITEM_CD NOT LIKE '1301%' --不含贴现
              AND FACILITY_AMT <= 10000000;

      COMMIT;

    --【3.2其中：普惠型小微企业主贷款    贷款余额户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.2其中：普惠型小微企业主贷款    贷款余额户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

      -- 3.2其中：普惠型小微企业主贷款   贷款余额户数
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_3.2.B4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_3.2.B3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_3.2.B2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_3.2.B1.2018'
                   END AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXXWQYZDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
             GROUP BY T.SXFW,
                      T.DATA_DATE,
                      T.ORG_NUM,
                      T.CUST_ID,
                      T.CUST_NAM;
           COMMIT;

            -- 其中：单户授信1000万元（含）以下不含票据融资合计
            INSERT INTO CBRC_A_REPT_DWD_S7101
              (DATA_DATE,
               ORG_NUM,
               SYS_NAM,
               REP_NUM,
               ITEM_NUM,
               TOTAL_VALUE,
               COL_2,
               COL_3)
              SELECT T.DATA_DATE,
                     T.ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     'S7101' AS REP_NUM,
                     'S71_I_3.2.B5.2021' AS ITEM_NUM,
                     '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                     T.CUST_ID AS COL_2,
                     T.CUST_NAM AS COL_3
                FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
               WHERE DATA_DATE = I_DATADATE
                 AND PHXXWQYZDK = '是'
                 AND ITEM_CD NOT LIKE '1301%' --不含贴现
                 AND FACILITY_AMT <= 10000000
               GROUP BY T.DATA_DATE,
                        T.ORG_NUM,
                        T.CUST_ID,
                        T.CUST_NAM;
           COMMIT;

     --【3.2其中：普惠型小微企业主贷款    不良贷款余额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.2其中：普惠型小微企业主贷款    不良贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

      -- 3.2其中：普惠型小微企业主贷款   不良贷款余额
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_3.2.C4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_3.2.C3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_3.2.C2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_3.2.C1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXXWQYZDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失'); --不良贷款
         COMMIT;

           -- 其中：单户授信1000万元（含）以下不含票据融资合计

           INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_3.2.C5.2021' AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXXWQYZDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失')--不良贷款
               AND ITEM_CD NOT LIKE '1301%' --不含贴现
               AND FACILITY_AMT <= 10000000;
         COMMIT;

    ------------------------------------------
    --3.3其中：个人创业担保贷款
    ------------------------------------------
     --【3.3其中：个人创业担保贷款        当年累放贷款额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.3其中：个人创业担保贷款   单户授信3000万元（含）以下合计 当年累放贷款额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

       -- 3.3其中：个人创业担保贷款     单户授信3000万元（含）以下合计 当年累放贷款额
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_3.3.D.2018' AS ITEM_NUM,
                  T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND OPERATE_CUST_TYPE IN ('A', 'B', '3', 'Z') --口径 吴大为 20210728 --ADD BY YHY 20211221 其他自然人
              AND T.UNDERTAK_GUAR_TYPE IN ('A', 'B') ---创业担保  口径 曲得光
              AND T.FACILITY_AMT <= 30000000;

          COMMIT;



       --【3.3其中：个人创业担保贷款     当年累放贷款户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.3其中：个人创业担保贷款     单户授信3000万元（含）以下合计 当年累放贷款户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);
        --3.3其中：个人创业担保贷款     单户授信3000万元（含）以下合计 当年累放贷款户数
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT I_DATADATE,
                   TT.ORG_NUM,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_3.3.E.2018' AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计SUM值
                   TT.CUST_ID AS COL_2,
                   TT.CUST_NAM AS COL_3
              FROM CBRC_S7101_AMT_TMP1 TT
              LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
                ON T.CUST_ID = TT.CUST_ID
               AND T.DATA_DATE = I_DATADATE --取当月的授信金额
               AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元以下,含本数 属于普惠型
             WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
               AND TT.DATA_DATE <= I_DATADATE
               AND TT.OPERATE_CUST_TYPE IN ('A', 'B', '3', 'Z') --口径 吴大为 20210728 --ADD BY YHY 20211221 其他自然人
               AND TT.UNDERTAK_GUAR_TYPE IN ('A', 'B') ---创业担保  口径 曲得光
               AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 30000000
             GROUP BY TT.ORG_NUM,
                      TT.CUST_ID,
                      TT.CUST_NAM;
        COMMIT;


       --【3.3其中：个人创业担保贷款     当年累放贷款年化利息收益】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.3其中：个人创业担保贷款    单户授信3000万元（含）以下合计 当年累放贷款年化利息收益';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        -- 3.3其中：个人创业担保贷款    单户授信3000万元（含）以下合计 当年累放贷款年化利息收益
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_3.3.F.2018' AS ITEM_NUM,
                  T.NHSY AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND T.OPERATE_CUST_TYPE IN ('A', 'B', '3', 'Z') --口径 吴大为 20210728 --ADD BY YHY 20211221 其他自然人
              AND T.UNDERTAK_GUAR_TYPE IN ('A', 'B') ---创业担保  口径 曲得光
              AND T.FACILITY_AMT <= 30000000;

         COMMIT;

          --【3.3其中：个人创业担保贷款     贷款余额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.3其中：个人创业担保贷款   贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

         -- 3.3其中：个人创业担保贷款     贷款余额
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_3.3.A4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_3.3.A3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_3.3.A2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_3.3.A1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND T.LOAN_ACCT_BAL <> 0
               AND GRCYDBDK = '是';

      COMMIT;



    --【3.3其中：个人创业担保贷款     贷款余额户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.3其中：个人创业担保贷款     贷款余额户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

      -- 3.3其中：个人创业担保贷款    贷款余额户数
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_3.3.B4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_3.3.B3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_3.3.B2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_3.3.B1.2018'
                   END AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND GRCYDBDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
             GROUP BY T.SXFW,
                      T.DATA_DATE,
                      T.ORG_NUM,
                      T.CUST_ID,
                      T.CUST_NAM;
           COMMIT;



     --【3.3其中：个人创业担保贷款     不良贷款余额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.3其中：个人创业担保贷款     不良贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

      -- 3.3其中：个人创业担保贷款    不良贷款余额
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_3.3.C4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_3.3.C3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_3.3.C2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_3.3.C1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND GRCYDBDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失'); --不良贷款
         COMMIT;


    ------------------------------------------
    --3.3.1其中：残疾人创业担保贷款
    ------------------------------------------
       --【3.3.1其中：残疾人创业担保贷款        当年累放贷款额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.3.1其中：残疾人创业担保贷款     单户授信3000万元（含）以下合计 当年累放贷款额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

       -- 3.3.1其中：残疾人创业担保贷款       单户授信3000万元（含）以下合计 当年累放贷款额
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_3.3.1.D.2018' AS ITEM_NUM,
                  T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND T.OPERATE_CUST_TYPE IN ('A', 'B', '3', 'Z')
              AND T.UNDERTAK_GUAR_TYPE IN ('A', 'B') ---创业担保  口径 曲得光
              AND T.DEFORMITY_FLG = 'Y'
              AND T.FACILITY_AMT <= 30000000;

          COMMIT;



       --【3.3.1其中：残疾人创业担保贷款     当年累放贷款户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.3.1其中：残疾人创业担保贷款     单户授信3000万元（含）以下合计 当年累放贷款户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);
        --3.3.1其中：残疾人创业担保贷款     单户授信3000万元（含）以下合计 当年累放贷款户数
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT I_DATADATE,
                   TT.ORG_NUM,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_3.3.1.E.2018' AS ITEM_NUM,
                   '1' AS TOTAL_VALUE,
                   TT.CUST_ID AS COL_2,
                   TT.CUST_NAM AS COL_3
              FROM CBRC_S7101_AMT_TMP1 TT
              LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
                ON T.CUST_ID = TT.CUST_ID
               AND T.DATA_DATE = I_DATADATE --取当月的授信金额
               AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元以下,含本数 属于普惠型
             INNER JOIN CBRC_S7101_SNDK_TEMP F
                ON F.DATA_DATE = I_DATADATE
               AND TT.LOAN_NUM = F.LOAN_NUM
             WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
               AND TT.DATA_DATE <= I_DATADATE
               AND TT.OPERATE_CUST_TYPE IN ('A', 'B', '3', 'Z')
               AND TT.UNDERTAK_GUAR_TYPE IN ('A', 'B') ---创业担保  口径 曲得光
               AND TT.DEFORMITY_FLG = 'Y'
               AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 30000000
             GROUP BY TT.ORG_NUM,
                      TT.CUST_ID,
                      TT.CUST_NAM;
        COMMIT;


       --【3.3.1其中：残疾人创业担保贷款     当年累放贷款年化利息收益】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.3.1其中：残疾人创业担保贷款    单户授信3000万元（含）以下合计 当年累放贷款年化利息收益';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        -- 3.3.1其中：残疾人创业担保贷款    单户授信3000万元（含）以下合计 当年累放贷款年化利息收益
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_3.3.1.F.2018' AS ITEM_NUM,
                  T.NHSY AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND T.OPERATE_CUST_TYPE IN ('A', 'B', '3', 'Z')
              AND T.UNDERTAK_GUAR_TYPE IN ('A', 'B') ---创业担保  口径 曲得光
              AND T.DEFORMITY_FLG = 'Y'
              AND T.FACILITY_AMT <= 30000000;

         COMMIT;

          --【3.3.1其中：残疾人创业担保贷款     贷款余额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.3.1其中：残疾人创业担保贷款     贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

         -- 3.3.1其中：残疾人创业担保贷款     贷款余额
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_3.3.1.A4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_3.3.1.A3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_3.3.1.A2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_3.3.1.A1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND T.LOAN_ACCT_BAL <> 0
               AND CJRCYDBDK = '是';

      COMMIT;



    --【3.3.1其中：残疾人创业担保贷款     贷款余额户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.3.1其中：残疾人创业担保贷款     贷款余额户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

      -- 3.3.1其中：残疾人创业担保贷款    贷款余额户数
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_3.3.1.B4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_3.3.1.B3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_3.3.1.B2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_3.3.1.B1.2018'
                   END AS ITEM_NUM,
                   '1' AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND CJRCYDBDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
             GROUP BY T.SXFW,
                      T.DATA_DATE,
                      T.ORG_NUM,
                      T.CUST_ID,
                      T.CUST_NAM;
           COMMIT;



     --【3.3.1其中：残疾人创业担保贷款     不良贷款余额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '3.3.1其中：残疾人创业担保贷款     不良贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

      -- 3.3.1其中：残疾人创业担保贷款    不良贷款余额
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_3.3.1.C4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_3.3.1.C3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_3.3.1.C2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_3.3.1.C1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS COL_5,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND CJRCYDBDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失'); --不良贷款
         COMMIT;


    ------------------------------------------
    --4.普惠型其他个人（非农户）经营性贷款
    ------------------------------------------

    --【4.普惠型其他个人（非农户）经营性贷款 贷款余额】
      V_STEP_ID   := V_STEP_ID + 1;
      V_STEP_FLAG := 0;
      V_STEP_DESC := '4.普惠型其他个人（非农户）经营性贷款 贷款余额';
      SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                  V_STEP_ID,
                  V_ERRORCODE,
                  V_STEP_DESC,
                  II_DATADATE);

      -- 4.普惠型其他个人（非农户）经营性贷款 贷款余额
          INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3,
           COL_4,
           COL_6,
           COL_7,
           COL_8,
           COL_9,
           COL_10,
           COL_11,
           COL_13,
           COL_14)
          SELECT T.DATA_DATE,
                 T.ORG_NUM,
                 T.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 CASE
                   WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                    'S71_I_4..A4.2018'
                   WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                    'S71_I_4..A3.2018'
                   WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                    'S71_I_4..A2.2018'
                   WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                    'S71_I_4..A1.2018'
                 END AS ITEM_NUM,
                 T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                 T.CUST_ID AS COL_2,
                 T.CUST_NAM AS COL_3,
                 T.LOAN_NUM AS COL_4,
                 T.FACILITY_AMT AS COL_6,
                 T.ACCT_NUM AS COL_7,
                 T.DRAWDOWN_DT AS COL_8,
                 T.MATURITY_DT AS COL_9,
                 T.ITEM_CD AS COL_10,
                 T.DEPARTMENTD AS COL_11,
                 T.CP_NAME AS COL_13,
                 T.LOAN_GRADE_CD AS COL_14
            FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
           WHERE DATA_DATE = I_DATADATE
             AND T.LOAN_ACCT_BAL <> 0
             AND PHXQTGRJYXDK = '是';

      COMMIT;

      -- 其中：单户授信1000万元（含）以下不含票据融资合计

        INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3,
           COL_4,
           COL_6,
           COL_7,
           COL_8,
           COL_9,
           COL_10,
           COL_11,
           COL_13,
           COL_14)
          SELECT T.DATA_DATE,
                 T.ORG_NUM,
                 T.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 'S71_I_4..A5.2021' AS ITEM_NUM,
                 T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                 T.CUST_ID AS COL_2,
                 T.CUST_NAM AS COL_3,
                 T.LOAN_NUM AS COL_4,
                 T.FACILITY_AMT AS COL_6,
                 T.ACCT_NUM AS COL_7,
                 T.DRAWDOWN_DT AS COL_8,
                 T.MATURITY_DT AS COL_9,
                 T.ITEM_CD AS COL_10,
                 T.DEPARTMENTD AS COL_11,
                 T.CP_NAME AS COL_13,
                 T.LOAN_GRADE_CD AS COL_14
            FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
           WHERE DATA_DATE = I_DATADATE
             AND PHXQTGRJYXDK = '是'
             AND T.LOAN_ACCT_BAL <> 0
             AND ITEM_CD NOT LIKE '1301%' --不含贴现
             AND FACILITY_AMT <= 10000000;
      COMMIT;



       --【4.普惠型其他个人（非农户）经营性贷款 贷款余额户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '4.普惠型其他个人（非农户）经营性贷款 贷款余额户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

          -- 4.普惠型其他个人（非农户）经营性贷款 贷款余额户数
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_4..B4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_4..B3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_4..B2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_4..B1.2018'
                   END AS ITEM_NUM,
                   '1' AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXQTGRJYXDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
             GROUP BY T.SXFW,
                      T.DATA_DATE,
                      T.ORG_NUM,
                      T.CUST_ID,
                      T.CUST_NAM;
           COMMIT;

             -- 其中：单户授信1000万元（含）以下不含票据融资合计
             INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_4..B5.2021' AS ITEM_NUM,
                   '1' AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXQTGRJYXDK = '是'
               AND ITEM_CD NOT LIKE '1301%' --不含贴现
               AND FACILITY_AMT <= 10000000
               AND T.LOAN_ACCT_BAL <> 0
             GROUP BY T.DATA_DATE,
                      T.ORG_NUM,
                      T.CUST_ID,
                      T.CUST_NAM;
           COMMIT;

        --【4.普惠型其他个人（非农户）经营性贷款 不良贷款余额】
      V_STEP_ID   := V_STEP_ID + 1;
      V_STEP_FLAG := 0;
      V_STEP_DESC := '4.普惠型其他个人（非农户）经营性贷款 不良贷款余额';
      SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                  V_STEP_ID,
                  V_ERRORCODE,
                  V_STEP_DESC,
                  II_DATADATE);


          -- 4.普惠型其他个人（非农户）经营性贷款 不良贷款余额
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_4..C4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_4..C3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_4..C2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_4..C1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXQTGRJYXDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失'); --不良贷款
         COMMIT;

           -- 其中：单户授信1000万元（含）以下不含票据融资合计

           INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_4..C5.2021' AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXQTGRJYXDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失')--不良贷款
               AND ITEM_CD NOT LIKE '1301%' --不含贴现
               AND FACILITY_AMT <= 10000000;
         COMMIT;

        --【4.普惠型其他个人（非农户）经营性贷款 当年累放贷款额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '4.普惠型其他个人（非农户）经营性贷款  当年累放贷款额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);


         -- 4.普惠型其他个人（非农户）经营性贷款  当年累放贷款额
       INSERT INTO CBRC_A_REPT_DWD_S7101
         (DATA_DATE,
          ORG_NUM,
          DATA_DEPARTMENT,
          SYS_NAM,
          REP_NUM,
          ITEM_NUM,
          TOTAL_VALUE,
          COL_2,
          COL_3,
          COL_4,
          COL_6,
          COL_7,
          COL_8,
          COL_9,
          COL_10,
          COL_11,
          COL_13)
         SELECT I_DATADATE,
                T.ORG_NUM,
                T.DEPARTMENTD,
                'CBRC' AS SYS_NAM,
                'S7101' AS REP_NUM,
                CASE
                  WHEN T.FACILITY_AMT <= 1000000 THEN
                   'S71_I_4..D1.2018'
                  WHEN T.FACILITY_AMT > 1000000 AND
                       T.FACILITY_AMT <= 5000000 THEN
                   'S71_I_4..D2.2018'
                  WHEN T.FACILITY_AMT > 5000000 AND
                       T.FACILITY_AMT <= 10000000 THEN
                   'S71_I_4..D3.2018'
                  WHEN T.FACILITY_AMT > 10000000 AND
                       T.FACILITY_AMT <= 30000000 THEN
                   'S71_I_4..D4.2018'
                END AS ITEM_NUM,
                T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                T.CUST_ID AS COL_2,
                T.CUST_NAM AS COL_3,
                T.LOAN_NUM AS COL_4,
                T.FACILITY_AMT AS COL_6,
                T.ACCT_NUM AS COL_7,
                T.DRAWDOWN_DT AS COL_8,
                T.MATURITY_DT AS COL_9,
                T.ITEM_CD AS COL_10,
                T.DEPARTMENTD AS COL_11,
                T.CP_NAME AS COL_13
           FROM CBRC_S7101_AMT_TMP1 T
           LEFT JOIN SMTMODS_L_CUST_P P --对私客户补充信息表
             ON P.DATA_DATE = I_DATADATE
            AND T.CUST_ID = P.CUST_ID
          WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
            AND T.DATA_DATE <= I_DATADATE
            AND T.OPERATE_CUST_TYPE = 'Z' --其他个人
            AND T.AGREI_P_FLG = 'N' --非涉农
            AND (P.VOCATION_TYP <> 'X' OR P.VOCATION_TYP IS NULL) --ALTER BY WJB 20220128 去掉职业为军人的
            AND (P.QUALITY NOT IN ('10', '20'));  --ALTER BY shiyu m9 去掉10 机关、事业单位  20 国有企业

          COMMIT;

           -- 其中：单户授信1000万元（含）以下不含票据融资合计

           INSERT INTO CBRC_A_REPT_DWD_S7101
             (DATA_DATE,
              ORG_NUM,
              DATA_DEPARTMENT,
              SYS_NAM,
              REP_NUM,
              ITEM_NUM,
              TOTAL_VALUE,
              COL_2,
              COL_3,
              COL_4,
              COL_6,
              COL_7,
              COL_8,
              COL_9,
              COL_10,
              COL_11,
              COL_13)
             SELECT I_DATADATE,
                    T.ORG_NUM,
                    T.DEPARTMENTD,
                    'CBRC' AS SYS_NAM,
                    'S7101' AS REP_NUM,
                    'S71_I_4..D5.2021' AS ITEM_NUM,
                    T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                    T.CUST_ID AS COL_2,
                    T.CUST_NAM AS COL_3,
                    T.LOAN_NUM AS COL_4,
                    T.FACILITY_AMT AS COL_6,
                    T.ACCT_NUM AS COL_7,
                    T.DRAWDOWN_DT AS COL_8,
                    T.MATURITY_DT AS COL_9,
                    T.ITEM_CD AS COL_10,
                    T.DEPARTMENTD AS COL_11,
                    T.CP_NAME AS COL_13
               FROM CBRC_S7101_AMT_TMP1 T
               LEFT JOIN SMTMODS_L_CUST_P P --对私客户补充信息表
                 ON P.DATA_DATE = I_DATADATE
                AND T.CUST_ID = P.CUST_ID
              WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
                AND T.DATA_DATE <= I_DATADATE
                AND T.OPERATE_CUST_TYPE = 'Z' --其他个人
                AND T.AGREI_P_FLG = 'N' --非涉农
                AND (P.VOCATION_TYP <> 'X' OR P.VOCATION_TYP IS NULL) --ALTER BY WJB 20220128 去掉职业为军人的
                AND (P.QUALITY NOT IN ('10', '20'))  --ALTER BY shiyu m9 去掉10 机关、事业单位  20 国有企业
                AND ITEM_CD NOT LIKE '1301%' --不含贴现
                AND FACILITY_AMT <= 10000000;

          COMMIT;

        --【4.普惠型其他个人（非农户）经营性贷款 当年累放贷款户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '4.普惠型其他个人（非农户）经营性贷款  当年累放贷款户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        -- 4.普惠型其他个人（非农户）经营性贷款  当年累放贷款户数
        INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3)
          SELECT I_DATADATE,
                 TT.ORG_NUM,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 CASE
                   WHEN NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 1000000 THEN
                    'S71_I_4..E1.2018'
                   WHEN NVL(T.FACILITY_AMT, TT.FACILITY_AMT) > 1000000 AND
                        NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 5000000 THEN
                    'S71_I_4..E2.2018'
                   WHEN NVL(T.FACILITY_AMT, TT.FACILITY_AMT) > 5000000 AND
                        NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 10000000 THEN
                    'S71_I_4..E3.2018'
                   WHEN NVL(T.FACILITY_AMT, TT.FACILITY_AMT) > 10000000 AND
                        NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 30000000 THEN
                    'S71_I_4..E4.2018'
                 END AS ITEM_NUM,
                 '1' AS TOTAL_VALUE,
                 TT.CUST_ID AS COL_2,
                 TT.CUST_NAM AS COL_3
            FROM CBRC_S7101_AMT_TMP1 TT
            LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
              ON T.CUST_ID = TT.CUST_ID
             AND T.DATA_DATE = I_DATADATE --取当月的授信金额
             AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元以下,含本数 属于普惠型
            LEFT JOIN SMTMODS_L_CUST_P P --对私客户补充信息表
              ON P.DATA_DATE = I_DATADATE
             AND TT.CUST_ID = P.CUST_ID
           WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
             AND TT.DATA_DATE <= I_DATADATE
             AND TT.OPERATE_CUST_TYPE = 'Z' --其他个人
             AND TT.AGREI_P_FLG = 'N' --非涉农
             AND (P.VOCATION_TYP <> 'X' OR P.VOCATION_TYP IS NULL) --ALTER BY WJB 20220128 去掉职业为军人的
             AND (P.QUALITY NOT IN ('10', '20')) --ALTER BY shiyu m9 去掉10 机关、事业单位  20 国有企业
           GROUP BY TT.ORG_NUM,
                    TT.CUST_ID,
                    TT.CUST_NAM,
                    NVL(T.FACILITY_AMT, TT.FACILITY_AMT);
        COMMIT;

         -- 其中：单户授信1000万元（含）以下不含票据融资合计
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3)
           SELECT I_DATADATE,
                  TT.ORG_NUM,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_4..E5.2021' AS ITEM_NUM,
                  '1' AS TOTAL_VALUE,
                  TT.CUST_ID AS COL_2,
                  TT.CUST_NAM AS COL_3
             FROM CBRC_S7101_AMT_TMP1 TT
             LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
               ON T.CUST_ID = TT.CUST_ID
              AND T.DATA_DATE = I_DATADATE --取当月的授信金额
              AND T.FACILITY_AMT <= 10000000 --单户授信总额1000万元元以下,含本数 属于普惠型
             LEFT JOIN SMTMODS_L_CUST_P P --对私客户补充信息表
               ON P.DATA_DATE = I_DATADATE
              AND TT.CUST_ID = P.CUST_ID
            WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND TT.DATA_DATE <= I_DATADATE
              AND TT.OPERATE_CUST_TYPE = 'Z' --其他个人
              AND TT.AGREI_P_FLG = 'N' --非涉农
              AND (P.VOCATION_TYP <> 'X' OR P.VOCATION_TYP IS NULL) --ALTER BY WJB 20220128 去掉职业为军人的
              AND (P.QUALITY NOT IN ('10', '20')) --ALTER BY shiyu m9 去掉10 机关、事业单位  20 国有企业
              AND ITEM_CD NOT LIKE '1301%' --不含贴现
              AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 10000000
              AND TT.FACILITY_AMT <= 10000000
            GROUP BY TT.ORG_NUM,
                     TT.CUST_ID,
                     TT.CUST_NAM;
        COMMIT;

        --【4.普惠型其他个人（非农户）经营性贷款 当年累放贷款年化利息收益】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '4.普惠型其他个人（非农户）经营性贷款  当年累放贷款年化利息收益';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        -- 4.普惠型其他个人（非农户）经营性贷款  当年累放贷款年化利息收益
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  CASE
                    WHEN T.FACILITY_AMT <= 1000000 THEN
                     'S71_I_4..F1.2018'
                    WHEN T.FACILITY_AMT > 1000000 AND
                         T.FACILITY_AMT <= 5000000 THEN
                     'S71_I_4..F2.2018'
                    WHEN T.FACILITY_AMT > 5000000 AND
                         T.FACILITY_AMT <= 10000000 THEN
                     'S71_I_4..F3.2018'
                    WHEN T.FACILITY_AMT > 10000000 AND
                         T.FACILITY_AMT <= 30000000 THEN
                     'S71_I_4..F4.2018'
                  END AS ITEM_NUM,
                  T.NHSY AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_L_CUST_P P --对私客户补充信息表
               ON P.DATA_DATE = I_DATADATE
              AND T.CUST_ID = P.CUST_ID
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND T.OPERATE_CUST_TYPE = 'Z' --其他个人
              AND T.AGREI_P_FLG = 'N' --非涉农
              AND (P.VOCATION_TYP <> 'X' OR P.VOCATION_TYP IS NULL) --ALTER BY WJB 20220128 去掉职业为军人的
              AND (P.QUALITY NOT IN ('10', '20')); --ALTER BY shiyu m9 去掉10 机关、事业单位  20 国有企业

         COMMIT;

          -- 其中：单户授信1000万元（含）以下不含票据融资合计

          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_13)
            SELECT I_DATADATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_4..F5.2021' AS ITEM_NUM,
                   T.NHSY AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CP_NAME AS COL_13
              FROM CBRC_S7101_AMT_TMP1 T
              LEFT JOIN SMTMODS_L_CUST_P P --对私客户补充信息表
                ON P.DATA_DATE = I_DATADATE
               AND T.CUST_ID = P.CUST_ID
             WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
               AND T.DATA_DATE <= I_DATADATE
               AND T.OPERATE_CUST_TYPE = 'Z' --其他个人
               AND T.AGREI_P_FLG = 'N' --非涉农
               AND (P.VOCATION_TYP <> 'X' OR P.VOCATION_TYP IS NULL) --ALTER BY WJB 20220128 去掉职业为军人的
               AND (P.QUALITY NOT IN ('10', '20')) --ALTER BY shiyu m9 去掉10 机关、事业单位  20 国有企业
               AND ITEM_CD NOT LIKE '1301%' --不含贴现
               AND T.FACILITY_AMT <= 10000000;

         COMMIT;

    -- 6.普惠型小微企业贷款
    ------------------------------------------
    -- 6.1其中：信用贷款
    ------------------------------------------
    --【6.1其中：信用贷款 贷款余额】
      V_STEP_ID   := V_STEP_ID + 1;
      V_STEP_FLAG := 0;
      V_STEP_DESC := '6.1其中：信用贷款 贷款余额';
      SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                  V_STEP_ID,
                  V_ERRORCODE,
                  V_STEP_DESC,
                  II_DATADATE);


      -- 其中：单户授信1000万元（含）以下不含票据融资合计

        INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3,
           COL_4,
           COL_6,
           COL_7,
           COL_8,
           COL_9,
           COL_10,
           COL_11,
           COL_13,
           COL_14)
          SELECT T.DATA_DATE,
                 T.ORG_NUM,
                 T.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 'S71_I_6.1.A5.2022' AS ITEM_NUM,
                 T.LOAN_ACCT_BAL AS COL_5,
                 T.CUST_ID AS COL_2,
                 T.CUST_NAM AS COL_3,
                 T.LOAN_NUM AS COL_4,
                 T.FACILITY_AMT AS COL_6,
                 T.ACCT_NUM AS COL_7,
                 T.DRAWDOWN_DT AS COL_8,
                 T.MATURITY_DT AS COL_9,
                 T.ITEM_CD AS COL_10,
                 T.DEPARTMENTD AS COL_11,
                 T.CP_NAME AS COL_13,
                 T.LOAN_GRADE_CD AS COL_14
            FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
           WHERE DATA_DATE = I_DATADATE
             AND XWQYXYKD = '是'
             AND T.LOAN_ACCT_BAL <> 0
             AND ITEM_CD NOT LIKE '1301%' --不含贴现
             AND FACILITY_AMT <= 10000000;
      COMMIT;



       --【6.1其中：信用贷款 贷款余额户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '6.1其中：信用贷款 贷款余额户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

           -- 其中：单户授信1000万元（含）以下不含票据融资合计
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_6.1.B5.2022' AS ITEM_NUM,
                   '1' AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND XWQYXYKD = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND ITEM_CD NOT LIKE '1301%' --不含贴现
               AND FACILITY_AMT <= 10000000
             GROUP BY T.DATA_DATE,
                      T.ORG_NUM,
                      T.CUST_ID,
                      T.CUST_NAM;
           COMMIT;


        --【6.1其中：信用贷款 当年累放贷款额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '6.1其中：信用贷款  当年累放贷款额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);


           -- 其中：单户授信1000万元（含）以下不含票据融资合计

           INSERT INTO CBRC_A_REPT_DWD_S7101
             (DATA_DATE,
              ORG_NUM,
              DATA_DEPARTMENT,
              SYS_NAM,
              REP_NUM,
              ITEM_NUM,
              TOTAL_VALUE,
              COL_2,
              COL_3,
              COL_4,
              COL_6,
              COL_7,
              COL_8,
              COL_9,
              COL_10,
              COL_11,
              COL_13)
             SELECT I_DATADATE,
                    T.ORG_NUM,
                    T.DEPARTMENTD,
                    'CBRC' AS SYS_NAM,
                    'S7101' AS REP_NUM,
                    'S71_I_6.1.D5.2022' AS ITEM_NUM,
                    T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                    T.CUST_ID AS COL_2,
                    T.CUST_NAM AS COL_3,
                    T.LOAN_NUM AS COL_4,
                    T.FACILITY_AMT AS COL_6,
                    T.ACCT_NUM AS COL_7,
                    T.DRAWDOWN_DT AS COL_8,
                    T.MATURITY_DT AS COL_9,
                    T.ITEM_CD AS COL_10,
                    T.DEPARTMENTD AS COL_11,
                    T.CP_NAME AS COL_13
               FROM CBRC_S7101_AMT_TMP1 T
              WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
                AND T.DATA_DATE <= I_DATADATE
                AND ((SUBSTR(T.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                    AND T.CORP_SCALE IN ('S', 'T')) --小微企业
                    OR T.OPERATE_CUST_TYPE IN ('A', 'B', '3'))
                AND T.GUARANTY_TYP = 'D'
                AND ITEM_CD NOT LIKE '1301%' --不含贴现
                AND FACILITY_AMT <= 10000000;


          COMMIT;

        --【6.1其中：信用贷款 当年累放贷款户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '6.1其中：信用贷款  当年累放贷款户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

         -- 其中：单户授信1000万元（含）以下不含票据融资合计
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3)
           SELECT I_DATADATE,
                  TT.ORG_NUM,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_6.1.E5.2022' AS ITEM_NUM,
                  '1' AS TOTAL_VALUE,
                  TT.CUST_ID AS COL_2,
                  TT.CUST_NAM AS COL_3
             FROM CBRC_S7101_AMT_TMP1 TT
             LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
               ON T.CUST_ID = TT.CUST_ID
              AND T.DATA_DATE = I_DATADATE --取当月的授信金额
              AND T.FACILITY_AMT <= 10000000 --单户授信总额1000万元元以下,含本数 属于普惠型
            WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND TT.DATA_DATE <= I_DATADATE
              AND ((SUBSTR(TT.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                  AND TT.CORP_SCALE IN ('S', 'T'))--小微企业
               OR TT.OPERATE_CUST_TYPE IN ('A', 'B', '3')) --个人（A个体工商户和B小微企业主）对公（3个体工商户）
              AND TT.GUARANTY_TYP = 'D'
              AND ITEM_CD NOT LIKE '1301%' --不含贴现
              AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 10000000
              AND TT.FACILITY_AMT <= 10000000
            GROUP BY TT.ORG_NUM,
                     TT.CUST_ID,
                     TT.CUST_NAM;
        COMMIT;


    ------------------------------------------
    -- 6.2其中：中长期贷款
    ------------------------------------------
    --【6.2其中：中长期贷款 贷款余额】
      V_STEP_ID   := V_STEP_ID + 1;
      V_STEP_FLAG := 0;
      V_STEP_DESC := '6.2其中：中长期贷款 贷款余额';
      SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                  V_STEP_ID,
                  V_ERRORCODE,
                  V_STEP_DESC,
                  II_DATADATE);


      -- 其中：单户授信1000万元（含）以下不含票据融资合计

        INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3,
           COL_4,
           COL_6,
           COL_7,
           COL_8,
           COL_9,
           COL_10,
           COL_11,
           COL_13,
           COL_14)
          SELECT T.DATA_DATE,
                 T.ORG_NUM,
                 T.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 'S71_I_6.2.A5.2022' AS ITEM_NUM,
                 T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                 T.CUST_ID AS COL_2,
                 T.CUST_NAM AS COL_3,
                 T.LOAN_NUM AS COL_4,
                 T.FACILITY_AMT AS COL_6,
                 T.ACCT_NUM AS COL_7,
                 T.DRAWDOWN_DT AS COL_8,
                 T.MATURITY_DT AS COL_9,
                 T.ITEM_CD AS COL_10,
                 T.DEPARTMENTD AS COL_11,
                 T.CP_NAME AS COL_13,
                 T.LOAN_GRADE_CD AS COL_14
            FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
           WHERE DATA_DATE = I_DATADATE
             AND XWQYZCQDK = '是'
             AND T.LOAN_ACCT_BAL <> 0
             AND ITEM_CD NOT LIKE '1301%' --不含贴现
             AND FACILITY_AMT <= 10000000;
      COMMIT;



       --【6.2其中：中长期贷款 贷款余额户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '6.2其中：中长期贷款 贷款余额户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);



             -- 其中：单户授信1000万元（含）以下不含票据融资合计
            INSERT INTO CBRC_A_REPT_DWD_S7101
              (DATA_DATE,
               ORG_NUM,
               SYS_NAM,
               REP_NUM,
               ITEM_NUM,
               TOTAL_VALUE,
               COL_2,
               COL_3)
              SELECT T.DATA_DATE,
                     T.ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     'S7101' AS REP_NUM,
                     'S71_I_6.2.B5.2022' AS ITEM_NUM,
                     '1' AS TOTAL_VALUE,
                     T.CUST_ID AS COL_2,
                     T.CUST_NAM AS COL_3
                FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
               WHERE DATA_DATE = I_DATADATE
                 AND XWQYZCQDK = '是'
                 AND T.LOAN_ACCT_BAL <> 0
                 AND ITEM_CD NOT LIKE '1301%' --不含贴现
                 AND FACILITY_AMT <= 10000000
               GROUP BY T.DATA_DATE,
                        T.ORG_NUM,
                        T.CUST_ID,
                        T.CUST_NAM;
           COMMIT;


        --【6.2其中：中长期贷款 当年累放贷款额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '6.2其中：中长期贷款  当年累放贷款额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);



           -- 其中：单户授信1000万元（含）以下不含票据融资合计

          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_13)
            SELECT I_DATADATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_6.2.D5.2022' AS ITEM_NUM,
                   T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CP_NAME AS COL_13
              FROM CBRC_S7101_AMT_TMP1 T
             WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
               AND T.DATA_DATE <= I_DATADATE
               AND ((SUBSTR(T.CUST_TYP, 0, 1) IN ('0', '1') AND -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                   T.CORP_SCALE IN ('S', 'T')) --小微企业
                OR T.OPERATE_CUST_TYPE IN ('A', 'B', '3')) --个人（A个体工商户和B小微企业主）对公（3个体工商户）
               AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12
               AND ITEM_CD NOT LIKE '1301%' --不含贴现
               AND FACILITY_AMT <= 10000000;


          COMMIT;

        --【6.2其中：中长期贷款 当年累放贷款户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '6.2其中：中长期贷款  当年累放贷款户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);



         -- 其中：单户授信1000万元（含）以下不含票据融资合计
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3)
           SELECT I_DATADATE,
                  TT.ORG_NUM,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_6.2.E5.2022' AS ITEM_NUM,
                  '1' AS TOTAL_VALUE,
                  TT.CUST_ID AS COL_2,
                  TT.CUST_NAM AS COL_3
             FROM CBRC_S7101_AMT_TMP1 TT
            WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND TT.DATA_DATE <= I_DATADATE
              AND (SUBSTR(TT.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                  AND TT.CORP_SCALE IN ('S', 'T') --小微企业
                  OR TT.OPERATE_CUST_TYPE IN ('A', 'B', '3')) --个人（A个体工商户和B小微企业主）对公（3个体工商户）
              AND MONTHS_BETWEEN(TT.MATURITY_DT, TT.DRAWDOWN_DT) > 12
              AND ITEM_CD NOT LIKE '1301%' --不含贴现
              AND TT.FACILITY_AMT <= 10000000
            GROUP BY TT.ORG_NUM,
                     TT.CUST_ID,
                     TT.CUST_NAM;

        COMMIT;

    ------------------------------------------
    -- 6.3其中：无还本续贷
    ------------------------------------------
    --【6.3其中：无还本续贷 贷款余额】
      V_STEP_ID   := V_STEP_ID + 1;
      V_STEP_FLAG := 0;
      V_STEP_DESC := '6.3其中：无还本续贷 贷款余额';
      SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                  V_STEP_ID,
                  V_ERRORCODE,
                  V_STEP_DESC,
                  II_DATADATE);


      -- 其中：单户授信1000万元（含）以下不含票据融资合计

        INSERT INTO CBRC_A_REPT_DWD_S7101
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3,
           COL_4,
           COL_6,
           COL_7,
           COL_8,
           COL_9,
           COL_10,
           COL_11,
           COL_13,
           COL_14)
          SELECT T.DATA_DATE,
                 T.ORG_NUM,
                 T.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 'S71_I_6.3.A5.2022' AS ITEM_NUM,
                 T.LOAN_ACCT_BAL AS COL_5,
                 T.CUST_ID AS COL_2,
                 T.CUST_NAM AS COL_3,
                 T.LOAN_NUM AS COL_4,
                 T.FACILITY_AMT AS COL_6,
                 T.ACCT_NUM AS COL_7,
                 T.DRAWDOWN_DT AS COL_8,
                 T.MATURITY_DT AS COL_9,
                 T.ITEM_CD AS COL_10,
                 T.DEPARTMENTD AS COL_11,
                 T.CP_NAME AS COL_13,
                 T.LOAN_GRADE_CD AS COL_14
            FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
           WHERE DATA_DATE = I_DATADATE
             AND XWQYWHBXD = '是'
             AND T.LOAN_ACCT_BAL <> 0
             AND ITEM_CD NOT LIKE '1301%' --不含贴现
             AND FACILITY_AMT <= 10000000;
      COMMIT;



       --【6.3其中：无还本续贷 贷款余额户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '6.3其中：无还本续贷 贷款余额户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);



             -- 其中：单户授信1000万元（含）以下不含票据融资合计
            INSERT INTO CBRC_A_REPT_DWD_S7101
              (DATA_DATE,
               ORG_NUM,
               SYS_NAM,
               REP_NUM,
               ITEM_NUM,
               TOTAL_VALUE,
               COL_2,
               COL_3)
              SELECT T.DATA_DATE,
                     T.ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     'S7101' AS REP_NUM,
                     'S71_I_6.3.B5.2022' AS ITEM_NUM,
                     '1' AS TOTAL_VALUE,
                     T.CUST_ID AS COL_2,
                     T.CUST_NAM AS COL_3
                FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
               WHERE DATA_DATE = I_DATADATE
                 AND XWQYWHBXD = '是'
                 AND T.LOAN_ACCT_BAL <> 0
                 AND ITEM_CD NOT LIKE '1301%' --不含贴现
                 AND FACILITY_AMT <= 10000000
               GROUP BY T.DATA_DATE,
                        T.ORG_NUM,
                        T.CUST_ID,
                        T.CUST_NAM;
           COMMIT;


        --【6.3其中：无还本续贷 当年累放贷款额】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '6.3其中：无还本续贷  当年累放贷款额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);



           -- 其中：单户授信1000万元（含）以下不含票据融资合计
            INSERT INTO CBRC_A_REPT_DWD_S7101
              (DATA_DATE,
               ORG_NUM,
               DATA_DEPARTMENT,
               SYS_NAM,
               REP_NUM,
               ITEM_NUM,
               TOTAL_VALUE,
               COL_2,
               COL_3,
               COL_4,
               COL_6,
               COL_7,
               COL_8,
               COL_9,
               COL_10,
               COL_11,
               COL_13)
              SELECT I_DATADATE,
                     T.ORG_NUM,
                     T.DEPARTMENTD,
                     'CBRC' AS SYS_NAM,
                     'S7101' AS REP_NUM,
                     'S71_I_6.3.D5.2022' AS ITEM_NUM,
                     T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                     T.CUST_ID AS COL_2,
                     T.CUST_NAM AS COL_3,
                     T.LOAN_NUM AS COL_4,
                     T.FACILITY_AMT AS COL_6,
                     T.ACCT_NUM AS COL_7,
                     T.DRAWDOWN_DT AS COL_8,
                     T.MATURITY_DT AS COL_9,
                     T.ITEM_CD AS COL_10,
                     T.DEPARTMENTD AS COL_11,
                     T.CP_NAME AS COL_13
                FROM CBRC_S7101_AMT_TMP1 T
               WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
                 AND T.DATA_DATE <= I_DATADATE
                 AND (SUBSTR(T.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                     AND T.CORP_SCALE IN ('S', 'T') OR --小微企业
                     T.OPERATE_CUST_TYPE IN ('A', 'B', '3')) --个人（A个体工商户和B小微企业主）对公（3个体工商户）
                 AND T.LOAN_KIND_CD = '6'
                 AND ITEM_CD NOT LIKE '1301%' --不含贴现
                 AND FACILITY_AMT <= 10000000;


          COMMIT;

        --【6.3其中：无还本续贷 当年累放贷款户数】
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '6.3其中：无还本续贷  当年累放贷款户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);


         -- 其中：单户授信1000万元（含）以下不含票据融资合计
         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3)
           SELECT I_DATADATE,
                  TT.ORG_NUM,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_6.3.E5.2022' AS ITEM_NUM,
                  '1' AS TOTAL_VALUE,
                  TT.CUST_ID AS COL_2,
                  TT.CUST_NAM AS COL_3
             FROM CBRC_S7101_AMT_TMP1 TT
            WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND TT.DATA_DATE <= I_DATADATE
              AND ((SUBSTR(TT.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                  AND TT.CORP_SCALE IN ('S', 'T')) --小微企业
                  OR TT.OPERATE_CUST_TYPE IN ('A', 'B', '3')) --个人（A个体工商户和B小微企业主）对公（3个体工商户）
              AND TT.LOAN_KIND_CD = '6'
              AND ITEM_CD NOT LIKE '1301%' --不含贴现
              AND TT.FACILITY_AMT <= 10000000
            GROUP BY TT.ORG_NUM,
                     TT.CUST_ID,
                     TT.CUST_NAM;

        COMMIT;

    -- 6.4按贷款逾期情况
    ------------------------------------------
    -- 6.4.1逾期30天以内、 6.4.2逾期31天-60天、6.4.3逾期61天-90天、6.4.4逾期91天到180天、6.4.5逾期181天到270天、6.4.6逾期271天到360天、 6.4.7逾期361天以上
    ------------------------------------------
        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '6.4按贷款逾期情况 贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);



    --其中：单户授信1000万元（含）以下不含票据融资合计  贷款余额
          INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_13,
             COL_14,
             COL_24)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.YQDK1 = '是' THEN --6.4.1逾期30天以内
                      'S71_I_6.4.1.A5.2025'
                     WHEN T.YQDK2 = '是' THEN --6.4.2逾期31天-60天
                      'S71_I_6.4.2.A5.2025'
                     WHEN T.YQDK3 = '是' THEN --6.4.3逾期61天-90天
                      'S71_I_6.4.3.A5.2025'
                     WHEN T.YQDK4 = '是' THEN --6.4.4逾期91天到180天
                      'S71_I_6.4.4.A5.2025'
                     WHEN T.YQDK5 = '是' THEN --6.4.5逾期181天到270天
                      'S71_I_6.4.5.A5.2025'
                     WHEN T.YQDK6 = '是' THEN --6.4.6逾期270天到360天
                      'S71_I_6.4.6.A5.2025'
                     WHEN T.YQDK7 = '是' THEN --6.4.7逾期361天以上
                      'S71_I_6.4.7.A5.2025'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14,
                   T.OD_DAYS AS COL_24
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND T.LOAN_ACCT_BAL <> 0
               AND (YQDK1 = '是' OR YQDK2 = '是' OR YQDK3 = '是' OR
                   YQDK4 = '是' OR YQDK5 = '是' OR YQDK6 = '是' OR
                   YQDK7 = '是')
               AND T.OD_DAYS > 0;
      COMMIT;

       --其中：单户授信1000万元（含）以下不含票据融资合计  贷款余额户数

        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '6.4按贷款逾期情况 贷款余额户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

       INSERT INTO CBRC_A_REPT_DWD_S7101
         (DATA_DATE,
          ORG_NUM,
          SYS_NAM,
          REP_NUM,
          ITEM_NUM,
          TOTAL_VALUE,
          COL_2,
          COL_3)
         SELECT T.DATA_DATE,
                T.ORG_NUM,
                'CBRC' AS SYS_NAM,
                'S7101' AS REP_NUM,
                CASE
                  WHEN T.YQDK1 = '是' THEN --6.4.1逾期30天以内
                   'S71_I_6.4.1.B5.2025'
                  WHEN T.YQDK2 = '是' THEN --6.4.2逾期31天-60天
                   'S71_I_6.4.2.B5.2025'
                  WHEN T.YQDK3 = '是' THEN --6.4.3逾期61天-90天
                   'S71_I_6.4.3.B5.2025'
                  WHEN T.YQDK4 = '是' THEN --6.4.4逾期91天到180天
                   'S71_I_6.4.4.B5.2025'
                  WHEN T.YQDK5 = '是' THEN --6.4.5逾期181天到270天
                   'S71_I_6.4.5.B5.2025'
                  WHEN T.YQDK6 = '是' THEN --6.4.6逾期270天到360天
                   'S71_I_6.4.6.B5.2025'
                  WHEN T.YQDK7 = '是' THEN --6.4.7逾期361天以上
                   'S71_I_6.4.7.B5.2025'
                END AS ITEM_NUM,
                '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                T.CUST_ID AS COL_2,
                T.CUST_NAM AS COL_3
           FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
          WHERE DATA_DATE = I_DATADATE
            AND T.LOAN_ACCT_BAL <> 0
            AND (YQDK1 = '是' OR YQDK2 = '是' OR YQDK3 = '是' OR YQDK4 = '是' OR
                YQDK5 = '是' OR YQDK6 = '是' OR YQDK7 = '是')
            AND T.OD_DAYS > 0
          GROUP BY T.YQDK1,
                   T.YQDK2,
                   T.YQDK3,
                   T.YQDK4,
                   T.YQDK5,
                   T.YQDK6,
                   T.YQDK7,
                   T.DATA_DATE,
                   T.ORG_NUM,
                   T.CUST_ID,
                   T.CUST_NAM;
           COMMIT;


        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '6.4按贷款逾期情况 不良贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

       --其中：单户授信1000万元（含）以下不含票据融资合计  不良贷款余额
       INSERT INTO CBRC_A_REPT_DWD_S7101
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_13,
             COL_14,
             COL_24)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.YQDK1 = '是' THEN --6.4.1逾期30天以内
                      'S71_I_6.4.1.C5.2025'
                     WHEN T.YQDK2 = '是' THEN --6.4.2逾期31天-60天
                      'S71_I_6.4.2.C5.2025'
                     WHEN T.YQDK3 = '是' THEN --6.4.3逾期61天-90天
                      'S71_I_6.4.3.C5.2025'
                     WHEN T.YQDK4 = '是' THEN --6.4.4逾期91天到180天
                      'S71_I_6.4.4.C5.2025'
                     WHEN T.YQDK5 = '是' THEN --6.4.5逾期181天到270天
                      'S71_I_6.4.5.C5.2025'
                     WHEN T.YQDK6 = '是' THEN --6.4.6逾期270天到360天
                      'S71_I_6.4.6.C5.2025'
                     WHEN T.YQDK7 = '是' THEN --6.4.7逾期361天以上
                      'S71_I_6.4.7.C5.2025'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14,
                   T.OD_DAYS AS COL_24
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND T.LOAN_ACCT_BAL <> 0
               AND (YQDK1 = '是' OR YQDK2 = '是' OR YQDK3 = '是' OR
                   YQDK4 = '是' OR YQDK5 = '是' OR YQDK6 = '是' OR
                   YQDK7 = '是')
               AND T.LOAN_GRADE_CD IN ('次级', '可疑', '损失')
               AND T.OD_DAYS > 0;

      COMMIT;
    ------------------------------------------
    -- 7.创业担保贷款
    ------------------------------------------


        IF SUBSTR(I_DATADATE, 5, 2) = 01 THEN
          EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S7101_UNDERTAK_GUAR_INFO';
        ELSE
          EXECUTE IMMEDIATE ('DELETE FROM  CBRC_S7101_UNDERTAK_GUAR_INFO T WHERE  T.DATA_DATE = ' || '''' ||
                            I_DATADATE || '''' || ''); --删除当前日期数据
        END IF;

        COMMIT;

        INSERT INTO CBRC_S7101_UNDERTAK_GUAR_INFO
          SELECT I_DATADATE DATA_DATE,
                 A.ORG_NUM, --机构号
                 A.ACCT_NUM,
                 A.LOAN_NUM, --借据号
                 A.CUST_ID, --客户号
                 NVL(C.CUST_NAM, P.CUST_NAM) AS CUST_NAM, --客户名称
                 T.FACILITY_AMT, --授信金额
                 A.DRAWDOWN_AMT AS LOAN_ACCT_AMT, --累放金额
                 A.DRAWDOWN_AMT * A.REAL_INT_RAT / 100 NHSY, --年化收益
                 C.CORP_SCALE, --企业规模
                 P.OPERATE_CUST_TYPE, --个人经营性类型
                 A.ITEM_CD, --科目号
                 C.CUST_TYP, --对公客户类型
                 A.UNDERTAK_GUAR_TYPE, --创业担保贷款类型
                 A.MATURITY_DT, --原始到期日期
                 A.DRAWDOWN_DT, --放款日期
                 A.CURR_CD, --币种
                 A.CP_NAME,--产品名称 -- DJH
                 A.DEPARTMENTD
            FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
            LEFT JOIN SMTMODS_V_PUB_IDX_SX_PHJRDKSX T --授信加工临时表
              ON T.CUST_ID = A.CUST_ID
             AND T.DATA_DATE = TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD') --取放款时的授信--需求编号：JLBA202504160004_关于吉林银行修改单一客户授信逻辑的需求 提出人：苏桐  上线时间：20250627 修改人：石雨 修改内容：客户授信逻辑
            LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
              ON TT.CCY_DATE = I_DATADATE
             AND TT.BASIC_CCY = A.CURR_CD
             AND TT.FORWARD_CCY = 'CNY'
            LEFT JOIN SMTMODS_L_CUST_C C --对公表 取小微企业
              ON A.CUST_ID = C.CUST_ID
             AND C.DATA_DATE = I_DATADATE
            LEFT JOIN SMTMODS_L_CUST_P P --对私表 取个体工商户&小微企业主
              ON A.CUST_ID = P.CUST_ID
             AND P.DATA_DATE = I_DATADATE
           WHERE A.DATA_DATE = I_DATADATE
             AND A.ACCT_STS <> '3'
             AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款
             AND A.ITEM_CD NOT LIKE '1301%' ---刨除票据
             AND A.UNDERTAK_GUAR_TYPE IN ('A', 'B') --创业担保
             AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组
             AND (SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) = ---取当月
                 SUBSTR(I_DATADATE, 1, 6) OR
                 (A.INTERNET_LOAN_FLG = 'Y' AND
                 A.DRAWDOWN_DT =
                 (TRUNC(I_DATADATE, 'MM') - 1)) --modify by 87v : 互联网贷款数据晚一天下发,上月末数据当月取
                 );
       COMMIT;

        --【7.创业担保贷款 贷款余额】

        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '7.创业担保贷款 贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13,
            COL_14)
           SELECT T.DATA_DATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_7.A.2025' AS ITEM_NUM,
                  T.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  NVL(C.CUST_NAM, P.CUST_NAM) AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T2.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T3.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13,
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
                  END AS COL_14
             FROM SMTMODS_L_ACCT_LOAN T
             LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
               ON TT.CCY_DATE = I_DATADATE
              AND TT.BASIC_CCY = T.CURR_CD
              AND TT.FORWARD_CCY = 'CNY'
             LEFT JOIN SMTMODS_L_CUST_C C --对公表 取小微企业
               ON T.CUST_ID = C.CUST_ID
              AND C.DATA_DATE = I_DATADATE
             LEFT JOIN SMTMODS_L_CUST_P P --对私表 取个体工商户&小微企业主
               ON T.CUST_ID = P.CUST_ID
              AND P.DATA_DATE = I_DATADATE
             LEFT JOIN SMTMODS_V_PUB_IDX_SX_PHJRDKSX T2 --授信额度
               ON T.CUST_ID = T2.CUST_ID
              AND T2.DATA_DATE = I_DATADATE
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
               ON C.CORP_SCALE = T3.M_CODE
              AND T3.M_TABLECODE='CORP_SCALE'
            WHERE T.DATA_DATE = I_DATADATE
              AND T.ACCT_STS <> '3'
              AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
              AND T.ITEM_CD NOT LIKE '1301%' ---刨除票据
              AND T.UNDERTAK_GUAR_TYPE IN ('A', 'B') --创业担保
              AND T.LOAN_ACCT_BAL <> 0;

         COMMIT;

         --【7.创业担保贷款 贷款余额户数】

        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '7.创业担保贷款 贷款余额户数';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3)
           SELECT T.DATA_DATE,
                  T.ORG_NUM,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_7.B.2025' AS ITEM_NUM,
                  '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                  T.CUST_ID AS COL_2,
                  NVL(C.CUST_NAM, P.CUST_NAM) AS COL_3
             FROM SMTMODS_L_ACCT_LOAN T
             LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
               ON TT.CCY_DATE = I_DATADATE
              AND TT.BASIC_CCY = T.CURR_CD
              AND TT.FORWARD_CCY = 'CNY'
             LEFT JOIN SMTMODS_L_CUST_C C --对公表 取小微企业
               ON T.CUST_ID = C.CUST_ID
              AND C.DATA_DATE = I_DATADATE
             LEFT JOIN SMTMODS_L_CUST_P P --对私表 取个体工商户&小微企业主
               ON T.CUST_ID = P.CUST_ID
              AND P.DATA_DATE = I_DATADATE
            WHERE T.DATA_DATE = I_DATADATE
              AND T.ACCT_STS <> '3'
              AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
              AND T.ITEM_CD NOT LIKE '1301%' ---刨除票据
              AND T.UNDERTAK_GUAR_TYPE IN ('A', 'B') --创业担保
              AND T.LOAN_ACCT_BAL <> 0
            GROUP BY T.DATA_DATE,
                     T.ORG_NUM,
                     T.CUST_ID,
                     NVL(C.CUST_NAM, P.CUST_NAM);
         COMMIT;

         --【7.创业担保贷款 不良贷款余额】

        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '7.创业担保贷款 不良贷款余额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13,
            COL_14)
           SELECT T.DATA_DATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_7.C.2025' AS ITEM_NUM,
                  T.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  NVL(C.CUST_NAM, P.CUST_NAM) AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T2.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T3.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13,
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
                  END AS COL_14
             FROM SMTMODS_L_ACCT_LOAN T
             LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
               ON TT.CCY_DATE = I_DATADATE
              AND TT.BASIC_CCY = T.CURR_CD
              AND TT.FORWARD_CCY = 'CNY'
             LEFT JOIN SMTMODS_L_CUST_C C --对公表 取小微企业
               ON T.CUST_ID = C.CUST_ID
              AND C.DATA_DATE = I_DATADATE
             LEFT JOIN SMTMODS_L_CUST_P P --对私表 取个体工商户&小微企业主
               ON T.CUST_ID = P.CUST_ID
              AND P.DATA_DATE = I_DATADATE
             LEFT JOIN SMTMODS_V_PUB_IDX_SX_PHJRDKSX T2 --授信额度
               ON T.CUST_ID = T2.CUST_ID
              AND T2.DATA_DATE = I_DATADATE
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
               ON C.CORP_SCALE = T3.M_CODE
            WHERE T.DATA_DATE = I_DATADATE
              AND T.ACCT_STS <> '3'
              AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
              AND T.ITEM_CD NOT LIKE '1301%' ---刨除票据
              AND T.UNDERTAK_GUAR_TYPE IN ('A', 'B') --创业担保
              AND T.LOAN_ACCT_BAL <> 0
              AND T.LOAN_GRADE_CD IN ('3', '4', '5'); --不良贷款

         COMMIT;

        --【7.创业担保贷款 当年累放贷款额】

        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_FLAG := 0;
        V_STEP_DESC := '7.创业担保贷款 当年累放贷款额';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

            INSERT INTO CBRC_A_REPT_DWD_S7101
              (DATA_DATE,
               ORG_NUM,
               DATA_DEPARTMENT,
               SYS_NAM,
               REP_NUM,
               ITEM_NUM,
               TOTAL_VALUE,
               COL_2,
               COL_3,
               COL_4,
               COL_6,
               COL_7,
               COL_8,
               COL_9,
               COL_10,
               COL_11,
               COL_12,
               COL_13)
              SELECT I_DATADATE,
                     T.ORG_NUM,
                     T.DEPARTMENTD,
                     'CBRC' AS SYS_NAM,
                     'S7101' AS REP_NUM,
                     'S71_I_7.D.2025' AS ITEM_NUM,
                     T.LOAN_ACCT_AMT * TT.CCY_RATE AS TOTAL_VALUE,
                     T.CUST_ID AS COL_2,
                     T.CUST_NAM AS COL_3,
                     T.LOAN_NUM AS COL_4,
                     T.FACILITY_AMT AS COL_6,
                     T.ACCT_NUM AS COL_7,
                     T.DRAWDOWN_DT AS COL_8,
                     T.MATURITY_DT AS COL_9,
                     T.ITEM_CD AS COL_10,
                     T.DEPARTMENTD AS COL_11,
                     T2.M_NAME AS COL_12,
                     T.CP_NAME AS COL_13
                FROM CBRC_S7101_UNDERTAK_GUAR_INFO T
                LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
                   ON T.CORP_SCALE = T2.M_CODE
                  AND T2.M_TABLECODE = 'CORP_SCALE'
                LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
                  ON TT.CCY_DATE = I_DATADATE
                 AND TT.BASIC_CCY = T.CURR_CD
                 AND TT.FORWARD_CCY = 'CNY';

          COMMIT;

          --【7.创业担保贷款 当年累放贷款户数】
         V_STEP_ID   := V_STEP_ID + 1;
         V_STEP_FLAG := 0;
         V_STEP_DESC := '7.创业担保贷款 当年累放贷款户数';
         SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

              INSERT INTO CBRC_A_REPT_DWD_S7101
                (DATA_DATE,
                 ORG_NUM,
                 SYS_NAM,
                 REP_NUM,
                 ITEM_NUM,
                 TOTAL_VALUE,
                 COL_2,
                 COL_3)
                SELECT I_DATADATE,
                       T.ORG_NUM,
                       'CBRC' AS SYS_NAM,
                       'S7101' AS REP_NUM,
                       'S71_I_7.E.2025' AS ITEM_NUM,
                       '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计SUM值
                       T.CUST_ID AS COL_2,
                       T.CUST_NAM AS COL_3
                  FROM CBRC_S7101_UNDERTAK_GUAR_INFO T
                 GROUP BY T.ORG_NUM,
                          T.CUST_ID,
                          T.CUST_NAM;
        COMMIT;


          --【7.创业担保贷款 当年累放贷款年化利息收益】
         V_STEP_ID   := V_STEP_ID + 1;
         V_STEP_FLAG := 0;
         V_STEP_DESC := '7.创业担保贷款 当年累放贷款年化利息收益';
         SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

             INSERT INTO CBRC_A_REPT_DWD_S7101
               (DATA_DATE,
                ORG_NUM,
                DATA_DEPARTMENT,
                SYS_NAM,
                REP_NUM,
                ITEM_NUM,
                TOTAL_VALUE,
                COL_2,
                COL_3,
                COL_4,
                COL_6,
                COL_7,
                COL_8,
                COL_9,
                COL_10,
                COL_11,
                COL_12,
                COL_13)
               SELECT I_DATADATE,
                      T.ORG_NUM,
                      T.DEPARTMENTD,
                      'CBRC' AS SYS_NAM,
                      'S7101' AS REP_NUM,
                      'S71_I_7.F.2025' AS ITEM_NUM,
                      T.NHSY * TT.CCY_RATE AS TOTAL_VALUE,
                      T.CUST_ID AS COL_2,
                      T.CUST_NAM AS COL_3,
                      T.LOAN_NUM AS COL_4,
                      T.FACILITY_AMT AS COL_6,
                      T.ACCT_NUM AS COL_7,
                      T.DRAWDOWN_DT AS COL_8,
                      T.MATURITY_DT AS COL_9,
                      T.ITEM_CD AS COL_10,
                      T.DEPARTMENTD AS COL_11,
                      T2.M_NAME AS COL_12,
                      T.CP_NAME AS COL_13
                 FROM CBRC_S7101_UNDERTAK_GUAR_INFO T
                 LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
                   ON T.CORP_SCALE = T2.M_CODE
                  AND T2.M_TABLECODE = 'CORP_SCALE'
                 LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
                   ON TT.CCY_DATE = I_DATADATE
                  AND TT.BASIC_CCY = T.CURR_CD
                  AND TT.FORWARD_CCY = 'CNY';

           COMMIT;
    ------------------------------------------
    -- 7.1其他创业担保贷款
    ------------------------------------------

      --1）借款主体非小型微型企业、个体工商户、小微企业主、农户的创业担保贷款；
      --2）向单户授信总额1000万元以上的小型微型企业、个体工商户、小微企业主,以及单户授信总额500万元以上的农户,发放的创业担保贷款


       --【7.1其他创业担保贷款 贷款余额】
         V_STEP_ID   := V_STEP_ID + 1;
         V_STEP_FLAG := 0;
         V_STEP_DESC := '7.1其他创业担保贷款 贷款余额';
         SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

       INSERT INTO CBRC_A_REPT_DWD_S7101
         (DATA_DATE,
          ORG_NUM,
          DATA_DEPARTMENT,
          SYS_NAM,
          REP_NUM,
          ITEM_NUM,
          TOTAL_VALUE,
          COL_2,
          COL_3,
          COL_4,
          COL_6,
          COL_7,
          COL_8,
          COL_9,
          COL_10,
          COL_11,
          COL_12,
          COL_13,
          COL_14)
         SELECT T.DATA_DATE,
                T.ORG_NUM,
                T.DEPARTMENTD,
                'CBRC' AS SYS_NAM,
                'S7101' AS REP_NUM,
                'S71_I_7.1.A.2025' AS ITEM_NUM,
                T.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE,
                T.CUST_ID AS COL_2,
                NVL(C.CUST_NAM, P.CUST_NAM) AS COL_3,
                T.LOAN_NUM AS COL_4,
                T2.FACILITY_AMT AS COL_6,
                T.ACCT_NUM AS COL_7,
                T.DRAWDOWN_DT AS COL_8,
                T.MATURITY_DT AS COL_9,
                T.ITEM_CD AS COL_10,
                T.DEPARTMENTD AS COL_11,
                T3.M_NAME AS COL_12,
                T.CP_NAME AS COL_13,
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
                END AS COL_14
           FROM SMTMODS_L_ACCT_LOAN T
           LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
             ON TT.CCY_DATE = I_DATADATE
            AND TT.BASIC_CCY = T.CURR_CD
            AND TT.FORWARD_CCY = 'CNY'
           LEFT JOIN SMTMODS_L_CUST_C C --对公表 取小微企业
             ON T.CUST_ID = C.CUST_ID
            AND C.DATA_DATE = I_DATADATE
           LEFT JOIN SMTMODS_L_CUST_P P --对私表 取个体工商户&小微企业主
             ON T.CUST_ID = P.CUST_ID
            AND P.DATA_DATE = I_DATADATE
           LEFT JOIN SMTMODS_V_PUB_IDX_SX_PHJRDKSX T2 --授信额度
             ON T.CUST_ID = T2.CUST_ID
            AND T2.DATA_DATE = I_DATADATE
           LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
             ON C.CORP_SCALE = T3.M_CODE
           LEFT JOIN (SELECT *
                        FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                       WHERE T.DATA_DATE = I_DATADATE
                         AND SUBSTR(T.SNDKFL, 1, 5) IN
                             ('P_101', 'P_102', 'P_103')
                      UNION ALL
                      SELECT *
                        FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                       WHERE T.DATA_DATE = I_DATADATE
                         AND SUBSTR(T.SNDKFL, 1, 5) IN
                             ('P_101', 'P_102', 'P_103')) F --农户贷款
             ON T.LOAN_NUM = F.LOAN_NUM
            AND F.DATA_DATE = I_DATADATE
           LEFT JOIN CBRC_S7101_CREDITLINE_HZ Z
             ON T.CUST_ID = Z.CUST_ID
            AND Z.DATA_DATE = I_DATADATE
          WHERE T.DATA_DATE = I_DATADATE
            AND T.ACCT_STS <> '3'
            AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
            AND T.ITEM_CD NOT LIKE '1301%' ---刨除票据
            AND T.UNDERTAK_GUAR_TYPE IN ('A', 'B') --创业担保
            AND T.LOAN_ACCT_BAL <> 0
            AND ((NOT EXISTS (SELECT 1
                                FROM SMTMODS_L_CUST_C C1
                               WHERE C1.DATA_DATE = I_DATADATE
                                 AND C1.CUST_ID = T.CUST_ID
                                 AND C1.CORP_SCALE IN ('S', 'T') --小型 微型
                                 AND SUBSTR(C1.CUST_TYP, 0, 1) IN ('1', '0') -- 企业
                              ) --非小型微型企业
                 AND C.CUST_TYP <> '3' AND
                 P.OPERATE_CUST_TYPE NOT IN ('A', 'B') --非个体工商户、小微企业主
                 AND F.LOAN_NUM IS NULL --非农户
                ) OR ((((C.CUST_TYP <> '3' OR
                P.OPERATE_CUST_TYPE NOT IN ('A', 'B')) --个体工商户、小微企业主
                OR (C.CORP_SCALE IN ('S', 'T') /* 小型 微型*/
                AND SUBSTR(C.CUST_TYP, 0, 1) IN ('1', '0')) --小型微型企业
                ) AND Z.FACILITY_AMT > 10000000 /*授信总额1000万元以上*/
                ) OR (F.LOAN_NUM IS NOT NULL --非农户
                AND Z.FACILITY_AMT > 5000000 /*单户授信总额500万元以上*/
                )));

       COMMIT;

         --【7.1其他创业担保贷款 贷款余额户数】

         V_STEP_ID   := V_STEP_ID + 1;
         V_STEP_FLAG := 0;
         V_STEP_DESC := '7.1其他创业担保贷款 贷款余额户数';
         SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3)
           SELECT T.DATA_DATE,
                  T.ORG_NUM,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_7.1.B.2025' AS ITEM_NUM,
                  '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                  T.CUST_ID AS COL_2,
                  NVL(C.CUST_NAM, P.CUST_NAM) AS COL_3
             FROM SMTMODS_L_ACCT_LOAN T
             LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
               ON TT.CCY_DATE = I_DATADATE
              AND TT.BASIC_CCY = T.CURR_CD
              AND TT.FORWARD_CCY = 'CNY'
             LEFT JOIN SMTMODS_L_CUST_C C --对公表 取小微企业
               ON T.CUST_ID = C.CUST_ID
              AND C.DATA_DATE = I_DATADATE
             LEFT JOIN SMTMODS_L_CUST_P P --对私表 取个体工商户&小微企业主
               ON T.CUST_ID = P.CUST_ID
             AND P.DATA_DATE = I_DATADATE
             LEFT JOIN (SELECT *
                          FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                         WHERE T.DATA_DATE = I_DATADATE
                           AND SUBSTR(T.SNDKFL, 1, 5) IN
                               ('P_101', 'P_102', 'P_103')
                        UNION ALL
                        SELECT *
                          FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                         WHERE T.DATA_DATE = I_DATADATE
                           AND SUBSTR(T.SNDKFL, 1, 5) IN
                               ('P_101', 'P_102', 'P_103')) F --农户贷款
               ON T.LOAN_NUM = F.LOAN_NUM
              AND F.DATA_DATE = I_DATADATE
             LEFT JOIN CBRC_S7101_CREDITLINE_HZ Z
               ON T.CUST_ID = Z.CUST_ID
              AND Z.DATA_DATE = I_DATADATE
            WHERE T.DATA_DATE = I_DATADATE
              AND T.ACCT_STS <> '3'
              AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
              AND T.ITEM_CD NOT LIKE '1301%' ---刨除票据
              AND T.UNDERTAK_GUAR_TYPE IN ('A', 'B') --创业担保
              AND T.LOAN_ACCT_BAL <> 0
              AND ((NOT EXISTS
                   (SELECT 1
                       FROM SMTMODS_L_CUST_C C1
                      WHERE C1.DATA_DATE = I_DATADATE
                        AND C1.CUST_ID = T.CUST_ID
                        AND C1.CORP_SCALE IN ('S', 'T') --小型 微型
                        AND SUBSTR(C1.CUST_TYP, 0, 1) IN ('1', '0') -- 企业
                     ) --非小型微型企业
                   AND C.CUST_TYP <> '3' AND
                   P.OPERATE_CUST_TYPE NOT IN ('A', 'B') --非个体工商户、小微企业主
                   AND F.LOAN_NUM IS NULL --非农户
                  ) OR ((((C.CUST_TYP <> '3' OR
                  P.OPERATE_CUST_TYPE NOT IN ('A', 'B')) --个体工商户、小微企业主
                  OR (C.CORP_SCALE IN ('S', 'T') /* 小型 微型*/
                  AND SUBSTR(C.CUST_TYP, 0, 1) IN ('1', '0')) --小型微型企业
                  ) AND Z.FACILITY_AMT > 10000000 /*授信总额1000万元以上*/
                  ) OR (F.LOAN_NUM IS NOT NULL --非农户
                  AND Z.FACILITY_AMT > 5000000 /*单户授信总额500万元以上*/
                  )))
            GROUP BY T.DATA_DATE,
                     T.ORG_NUM,
                     T.CUST_ID,
                     NVL(C.CUST_NAM, P.CUST_NAM);
         COMMIT;

         --【7.1其他创业担保贷款 不良贷款余额】
         V_STEP_ID   := V_STEP_ID + 1;
         V_STEP_FLAG := 0;
         V_STEP_DESC := '7.1其他创业担保贷款 不良贷款余额';
         SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13,
            COL_14)
           SELECT T.DATA_DATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_7.1.C.2025' AS ITEM_NUM,
                  T.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  NVL(C.CUST_NAM, P.CUST_NAM) AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T2.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T3.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13,
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
                  END AS COL_14
             FROM SMTMODS_L_ACCT_LOAN T
             LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
               ON TT.CCY_DATE = I_DATADATE
              AND TT.BASIC_CCY = T.CURR_CD
              AND TT.FORWARD_CCY = 'CNY'
             LEFT JOIN SMTMODS_L_CUST_C C --对公表 取小微企业
               ON T.CUST_ID = C.CUST_ID
              AND C.DATA_DATE = I_DATADATE
             LEFT JOIN SMTMODS_L_CUST_P P --对私表 取个体工商户&小微企业主
               ON T.CUST_ID = P.CUST_ID
              AND P.DATA_DATE = I_DATADATE
             LEFT JOIN SMTMODS_V_PUB_IDX_SX_PHJRDKSX T2 --授信额度
               ON T.CUST_ID = T2.CUST_ID
              AND T2.DATA_DATE = I_DATADATE
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
               ON C.CORP_SCALE = T3.M_CODE
             LEFT JOIN (SELECT *
                          FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                         WHERE T.DATA_DATE = I_DATADATE
                           AND SUBSTR(T.SNDKFL, 1, 5) IN
                               ('P_101', 'P_102', 'P_103')
                        UNION ALL
                        SELECT *
                          FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                         WHERE T.DATA_DATE = I_DATADATE
                           AND SUBSTR(T.SNDKFL, 1, 5) IN
                               ('P_101', 'P_102', 'P_103')) F --农户贷款
               ON T.LOAN_NUM = F.LOAN_NUM
              AND F.DATA_DATE = I_DATADATE
             LEFT JOIN CBRC_S7101_CREDITLINE_HZ Z
               ON T.CUST_ID = Z.CUST_ID
              AND Z.DATA_DATE = I_DATADATE
            WHERE T.DATA_DATE = I_DATADATE
              AND T.ACCT_STS <> '3'
              AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
              AND T.ITEM_CD NOT LIKE '1301%' ---刨除票据
              AND T.UNDERTAK_GUAR_TYPE IN ('A', 'B') --创业担保
              AND T.LOAN_ACCT_BAL <> 0
              AND ((NOT EXISTS
                   (SELECT 1
                       FROM SMTMODS_L_CUST_C C1
                      WHERE C1.DATA_DATE = I_DATADATE
                        AND C1.CUST_ID = T.CUST_ID
                        AND C1.CORP_SCALE IN ('S', 'T') --小型 微型
                        AND SUBSTR(C1.CUST_TYP, 0, 1) IN ('1', '0') -- 企业
                     ) --非小型微型企业
                   AND C.CUST_TYP <> '3' AND
                   P.OPERATE_CUST_TYPE NOT IN ('A', 'B') --非个体工商户、小微企业主
                   AND F.LOAN_NUM IS NULL --非农户
                  ) OR ((((C.CUST_TYP <> '3' OR
                  P.OPERATE_CUST_TYPE NOT IN ('A', 'B')) --个体工商户、小微企业主
                  OR (C.CORP_SCALE IN ('S', 'T') /* 小型 微型*/
                  AND SUBSTR(C.CUST_TYP, 0, 1) IN ('1', '0')) --小型微型企业
                  ) AND Z.FACILITY_AMT > 10000000 /*授信总额1000万元以上*/
                  ) OR (F.LOAN_NUM IS NOT NULL --非农户
                  AND Z.FACILITY_AMT > 5000000 /*单户授信总额500万元以上*/
                  )))
              AND T.LOAN_GRADE_CD IN ('3', '4', '5'); --不良贷款

         COMMIT;

         --【7.1其他创业担保贷款 当年累放贷款额】
         V_STEP_ID   := V_STEP_ID + 1;
         V_STEP_FLAG := 0;
         V_STEP_DESC := '7.1其他创业担保贷款 当年累放贷款额';
         SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

         INSERT INTO CBRC_A_REPT_DWD_S7101
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3,
            COL_4,
            COL_6,
            COL_7,
            COL_8,
            COL_9,
            COL_10,
            COL_11,
            COL_12,
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_7.1.D.2025' AS ITEM_NUM,
                  T.LOAN_ACCT_AMT * TT.CCY_RATE AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_UNDERTAK_GUAR_INFO T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
             LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
               ON TT.CCY_DATE = I_DATADATE
              AND TT.BASIC_CCY = T.CURR_CD
              AND TT.FORWARD_CCY = 'CNY'
             LEFT JOIN (SELECT *
                          FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                         WHERE T.DATA_DATE = I_DATADATE
                           AND SUBSTR(T.SNDKFL, 1, 5) IN
                               ('P_101', 'P_102', 'P_103')
                        UNION ALL
                        SELECT *
                          FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                         WHERE T.DATA_DATE = I_DATADATE
                           AND SUBSTR(T.SNDKFL, 1, 5) IN
                               ('P_101', 'P_102', 'P_103')) F --农户贷款
               ON T.LOAN_NUM = F.LOAN_NUM
              AND F.DATA_DATE = I_DATADATE
            WHERE T.DATA_DATE = I_DATADATE
              AND ((NOT EXISTS
                   (SELECT 1
                       FROM SMTMODS_L_CUST_C C1
                      WHERE C1.DATA_DATE = I_DATADATE
                        AND C1.CUST_ID = T.CUST_ID
                        AND C1.CORP_SCALE IN ('S', 'T') --小型 微型
                        AND SUBSTR(C1.CUST_TYP, 0, 1) IN ('1', '0') -- 企业
                     ) --非小型微型企业
                   AND T.CUST_TYP <> '3' AND
                   T.OPERATE_CUST_TYPE NOT IN ('A', 'B') --非个体工商户、小微企业主
                   AND F.LOAN_NUM IS NULL --非农户
                  ) OR ((((T.CUST_TYP <> '3' OR
                  T.OPERATE_CUST_TYPE NOT IN ('A', 'B')) --个体工商户、小微企业主
                  OR (T.CORP_SCALE IN ('S', 'T') /* 小型 微型*/
                  AND SUBSTR(T.CUST_TYP, 0, 1) IN ('1', '0')) --小型微型企业
                  ) AND T.FACILITY_AMT > 10000000 /*授信总额1000万元以上*/
                  ) OR (F.LOAN_NUM IS NOT NULL --非农户
                  AND T.FACILITY_AMT > 5000000 /*单户授信总额500万元以上*/
                  )));

          COMMIT;

        --【7.1其他创业担保贷款 当年累放贷款户数】
         V_STEP_ID   := V_STEP_ID + 1;
         V_STEP_FLAG := 0;
         V_STEP_DESC := '7.1其他创业担保贷款 当年累放贷款户数';
         SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

            INSERT INTO CBRC_A_REPT_DWD_S7101
              (DATA_DATE,
               ORG_NUM,
               SYS_NAM,
               REP_NUM,
               ITEM_NUM,
               TOTAL_VALUE,
               COL_2,
               COL_3)
              SELECT I_DATADATE,
                     T.ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     'S7101' AS REP_NUM,
                     'S71_I_7.1.E.2025' AS ITEM_NUM,
                     '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计SUM值
                     T.CUST_ID AS COL_2,
                     T.CUST_NAM AS COL_3
                FROM CBRC_S7101_UNDERTAK_GUAR_INFO T
                LEFT JOIN (SELECT *
                             FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                            WHERE T.DATA_DATE = I_DATADATE
                              AND SUBSTR(T.SNDKFL, 1, 5) IN
                                  ('P_101', 'P_102', 'P_103')
                           UNION ALL
                           SELECT *
                             FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                            WHERE T.DATA_DATE = I_DATADATE
                              AND SUBSTR(T.SNDKFL, 1, 5) IN
                                  ('P_101', 'P_102', 'P_103')) F --农户贷款
                  ON T.LOAN_NUM = F.LOAN_NUM
                 AND F.DATA_DATE = I_DATADATE
               WHERE T.DATA_DATE = I_DATADATE
                 AND ((NOT EXISTS
                      (SELECT 1
                          FROM SMTMODS_L_CUST_C C1
                         WHERE C1.DATA_DATE = I_DATADATE
                           AND C1.CUST_ID = T.CUST_ID
                           AND C1.CORP_SCALE IN ('S', 'T') --小型 微型
                           AND SUBSTR(C1.CUST_TYP, 0, 1) IN ('1', '0') -- 企业
                        ) --非小型微型企业
                      AND T.CUST_TYP <> '3' AND
                      T.OPERATE_CUST_TYPE NOT IN ('A', 'B') --非个体工商户、小微企业主
                      AND F.LOAN_NUM IS NULL --非农户
                     ) OR
                     ((((T.CUST_TYP <> '3' OR
                     T.OPERATE_CUST_TYPE NOT IN ('A', 'B')) --个体工商户、小微企业主
                     OR (T.CORP_SCALE IN ('S', 'T') /* 小型 微型*/
                     AND SUBSTR(T.CUST_TYP, 0, 1) IN ('1', '0')) --小型微型企业
                     ) AND T.FACILITY_AMT > 10000000 /*授信总额1000万元以上*/
                     ) OR (F.LOAN_NUM IS NOT NULL --非农户
                     AND T.FACILITY_AMT > 5000000 /*单户授信总额500万元以上*/
                     )))
               GROUP BY T.ORG_NUM,
                        T.CUST_ID,
                        T.CUST_NAM;
        COMMIT;


         --【7.1其他创业担保贷款 当年累放贷款年化利息收益】
         V_STEP_ID   := V_STEP_ID + 1;
         V_STEP_FLAG := 0;
         V_STEP_DESC := '7.1其他创业担保贷款 当年累放贷款年化利息收益';
         SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

             INSERT INTO CBRC_A_REPT_DWD_S7101
               (DATA_DATE,
                ORG_NUM,
                DATA_DEPARTMENT,
                SYS_NAM,
                REP_NUM,
                ITEM_NUM,
                TOTAL_VALUE,
                COL_2,
                COL_3,
                COL_4,
                COL_6,
                COL_7,
                COL_8,
                COL_9,
                COL_10,
                COL_11,
                COL_12,
                COL_13)
               SELECT I_DATADATE,
                      T.ORG_NUM,
                      T.DEPARTMENTD,
                      'CBRC' AS SYS_NAM,
                      'S7101' AS REP_NUM,
                      'S71_I_7.1.F.2025' AS ITEM_NUM,
                      T.NHSY * TT.CCY_RATE AS TOTAL_VALUE,
                      T.CUST_ID AS COL_2,
                      T.CUST_NAM AS COL_3,
                      T.LOAN_NUM AS COL_4,
                      T.FACILITY_AMT AS COL_6,
                      T.ACCT_NUM AS COL_7,
                      T.DRAWDOWN_DT AS COL_8,
                      T.MATURITY_DT AS COL_9,
                      T.ITEM_CD AS COL_10,
                      T.DEPARTMENTD AS COL_11,
                      T2.M_NAME AS COL_12,
                      T.CP_NAME AS COL_13
                 FROM CBRC_S7101_UNDERTAK_GUAR_INFO T
                 LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
                   ON T.CORP_SCALE = T2.M_CODE
                  AND T2.M_TABLECODE = 'CORP_SCALE'
                 LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
                   ON TT.CCY_DATE = I_DATADATE
                  AND TT.BASIC_CCY = T.CURR_CD
                  AND TT.FORWARD_CCY = 'CNY'
                 LEFT JOIN (SELECT *
                              FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                             WHERE T.DATA_DATE = I_DATADATE
                               AND SUBSTR(T.SNDKFL, 1, 5) IN
                                   ('P_101', 'P_102', 'P_103')
                            UNION ALL
                            SELECT *
                              FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                             WHERE T.DATA_DATE = I_DATADATE
                               AND SUBSTR(T.SNDKFL, 1, 5) IN
                                   ('P_101', 'P_102', 'P_103')) F --农户贷款
                   ON T.LOAN_NUM = F.LOAN_NUM
                  AND F.DATA_DATE = I_DATADATE
                WHERE T.DATA_DATE = I_DATADATE
                  AND ((NOT EXISTS
                       (SELECT 1
                           FROM SMTMODS_L_CUST_C C1
                          WHERE C1.DATA_DATE = I_DATADATE
                            AND C1.CUST_ID = T.CUST_ID
                            AND C1.CORP_SCALE IN ('S', 'T') --小型 微型
                            AND SUBSTR(C1.CUST_TYP, 0, 1) IN ('1', '0') -- 企业
                         ) --非小型微型企业
                       AND T.CUST_TYP <> '3' AND
                       T.OPERATE_CUST_TYPE NOT IN ('A', 'B') --非个体工商户、小微企业主
                       AND F.LOAN_NUM IS NULL --非农户
                      ) OR
                      ((((T.CUST_TYP <> '3' OR
                      T.OPERATE_CUST_TYPE NOT IN ('A', 'B')) --个体工商户、小微企业主
                      OR (T.CORP_SCALE IN ('S', 'T') /* 小型 微型*/
                      AND SUBSTR(T.CUST_TYP, 0, 1) IN ('1', '0')) --小型微型企业
                      ) AND T.FACILITY_AMT > 10000000 /*授信总额1000万元以上*/
                      ) OR (F.LOAN_NUM IS NOT NULL --非农户
                      AND T.FACILITY_AMT > 5000000 /*单户授信总额500万元以上*/
                      )));

          COMMIT;


        --插入结果表
         V_STEP_ID   := V_STEP_ID + 1;
         V_STEP_FLAG := 0;
         V_STEP_DESC := '插入结果表CBRC_A_REPT_ITEM_VAL';
         SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);

        INSERT INTO CBRC_A_REPT_ITEM_VAL
          (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, DATA_DEPARTMENT, ITEM_VAL)
          SELECT T.DATA_DATE,
                 T.ORG_NUM,
                 T.SYS_NAM,
                 T.REP_NUM,
                 T.ITEM_NUM,
                 T.DATA_DEPARTMENT,
                 SUM(TOTAL_VALUE) AS ITEM_VAL
            FROM CBRC_A_REPT_DWD_S7101 T
           GROUP BY T.DATA_DATE,
                    T.ORG_NUM,
                    T.SYS_NAM,
                    T.REP_NUM,
                    T.ITEM_NUM,
                    T.DATA_DEPARTMENT;
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
   
END proc_cbrc_idx2_s7101;
