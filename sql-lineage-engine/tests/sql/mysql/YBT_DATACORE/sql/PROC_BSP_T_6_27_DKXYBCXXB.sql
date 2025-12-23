DROP PROCEDURE IF EXISTS PROC_BSP_T_6_27_DKXYBCXXB;

CREATE PROCEDURE PROC_BSP_T_6_27_DKXYBCXXB(
    IN I_DATE STRING,
    OUT OI_RETCODE INT,
    OUT OI_REMESSAGE STRING
)
LANGUAGE SQL
BEGIN
    /******
        程序名称  ：表6.27贷款协议补充信息
        程序功能  ：加工表6.27贷款协议补充信息
        目标表：T_6_27
        源表  ：
        创建人  ：JLF
        创建日期  ：20240119
        版本号：V0.0.1 
    ******/
    -- JLBA202409120001_关于一表通监管数据报送系统修改逻辑的需求_二期 20241128 jlf
    -- JLBA202411070004_关于一表通监管数据报送系统修改逻辑的需求 20241212
    -- JLBA202412200001_关于一表通监管数据报送系统修改逻辑及转EAST脚本的需求_20250116
    -- JLBA202501240018_关于一表通监管数据报送系统变更的需求_20250311
    --  20250730吴大为邮件通知修改与1104S70 科技贷口径一致 修改姜俐锋：去掉国家技术中心
    /*需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
                苏桐确认，与1104系统s70取数口径一致，其中创新型中小企业和国家技术中心通过码值表(smtmods.s7001_cust_temp)判断
    /* 需求编号：JLBA202504060003 上线日期： 20250513，修改人：狄家卉，提出人：吴大为    关于一表通监管数据报送系统、EAST报送系统修改取数逻辑的需求*/
	/*需求编号：JLBA202504160004   上线日期：20250708，修改人：姜俐锋，提出人：吴大为 关于吉林银行修改单一客户授信逻辑的需求*/	
    /*需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
    /*需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
	/*需求编号：JLBA202507300010 上线日期：2025-09-29，修改人：姜俐锋，提出人：信贷新增产品 修改原因：关于新一代信贷管理系统新增线上微贷板块的需求 */
	/*需求编号：JLBA202509280009 上线日期：2025-10-28，修改人：巴启威，提出人：吴大为 修改原因：关于一表通监管数据报送系统修改逻辑的需求 */

  #声明变量
  DECLARE P_DATE   		DATE;
  DECLARE A_DATE STRING;
  DECLARE P_PROC_NAME STRING;
  DECLARE P_STATUS INT DEFAULT 0;
  DECLARE P_START_DT TIMESTAMP;
  DECLARE P_SQLCDE STRING;
  DECLARE P_STATE STRING;
  DECLARE P_SQLMSG STRING;
  DECLARE P_STEP_NO INT DEFAULT 0;
  DECLARE P_DESCB STRING;
  DECLARE BEG_MON_DT STRING;
  DECLARE BEG_QUAR_DT STRING;
  DECLARE BEG_YEAR_DT STRING;
  DECLARE LAST_MON_DT STRING;
  DECLARE LAST_QUAR_DT STRING;
  DECLARE LAST_YEAR_DT STRING;
  DECLARE LAST_DT STRING;
  DECLARE FINISH_FLG STRING;

  SET P_DATE = to_date(from_unixtime(unix_timestamp(I_DATE,'yyyyMMdd')));
  SET A_DATE = concat(substr(I_DATE,1,4), '-', substr(I_DATE,5,2), '-', substr(I_DATE,7,2));
  SET BEG_MON_DT = date_format(trunc(P_DATE,'MM'),'yyyyMMdd');
  SET BEG_QUAR_DT = date_format(trunc(P_DATE,'Q'),'yyyyMMdd');
  SET BEG_YEAR_DT = date_format(trunc(P_DATE,'Y'),'yyyyMMdd');
  SET LAST_MON_DT = date_format(date_sub(to_date(concat(substr(I_DATE,1,6),'01')),1),'yyyyMMdd');
  SET LAST_QUAR_DT = date_format(date_sub(trunc(P_DATE,'Q'),1),'yyyyMMdd');
  SET LAST_YEAR_DT = date_format(date_sub(trunc(P_DATE,'Y'),1),'yyyyMMdd');
  SET LAST_DT = date_format(date_sub(P_DATE,1),'yyyyMMdd');
  SET P_PROC_NAME = 'PROC_BSP_T_6_27_DKXYBCXXB';
  SET OI_RETCODE = 0;

    #1.过程开始执行
    SET P_START_DT = current_timestamp;
    SET P_STEP_NO = P_STEP_NO + 1;
    SET P_DESCB = '过程开始执行'; 
				 
	CALL PROC_ETL_JOB_LOG(P_DATE, P_PROC_NAME, P_STATUS, P_START_DT, current_timestamp, P_SQLCDE, P_STATE, P_SQLMSG, P_STEP_NO, P_DESCB);								

    #2.清除数据
    SET P_START_DT = current_timestamp;
    SET P_STEP_NO = P_STEP_NO + 1;
    SET P_DESCB = '清除数据';
    TRUNCATE TABLE T_6_27_TMP;
    DELETE FROM T_6_27 WHERE F270069 = date_format(P_DATE,'yyyy-MM-dd');
    CALL PROC_ETL_JOB_LOG(P_DATE, P_PROC_NAME, P_STATUS, P_START_DT, current_timestamp, P_SQLCDE, P_STATE, P_SQLMSG, P_STEP_NO, P_DESCB);

    #3.插入数据
    SET P_START_DT = current_timestamp;
    SET P_STEP_NO = P_STEP_NO + 1;
    SET P_DESCB = '插入临时表';

    DROP TABLE IF EXISTS EAST_HKZH;
    CREATE TABLE EAST_HKZH (
        FHZH STRING,
        KHRQ STRING,
        O_ACCT_NUM STRING,
        ACCT_NUM STRING
    )
    STORED AS ORC;

    INSERT INTO TABLE EAST_HKZH
    SELECT CUST_ID,
           KHRQ,
           O_ACCT_NUM,
           ACCT_NUM
    FROM (
        SELECT ROW_NUMBER() OVER(PARTITION BY CUST_ID ORDER BY ACCT_OPDATE DESC, ACCT_NUM DESC) AS RN,
               CUST_ID,
               ACCT_OPDATE AS KHRQ,
               ACCT_NUM,
               O_ACCT_NUM
        FROM SMTMODS.L_ACCT_DEPOSIT
        WHERE DATA_DATE = I_DATE
    ) AA
    WHERE RN = 1;

    INSERT INTO  T_6_27_TMP
    SELECT
        T.DATA_DATE,
        CASE
            WHEN substr(T.ITEM_CD,1,6) IN ('130101','130104','130102','130105')
                THEN substr(concat(T.ACCT_NUM, nvl(T.DRAFT_RNG,'')),1,60)
            ELSE T.ACCT_NUM
        END AS ACCT_NUM,
        CASE
            WHEN substr(T.ITEM_CD,1,6) IN ('130101','130104','130102','130105')
                THEN substr(concat(T.ACCT_NUM, nvl(T.DRAFT_RNG,'')),1,60)
            ELSE T.LOAN_NUM
        END AS LOAN_NUM,             
         T.CUST_ID,                    
         T.ORG_NUM,              
         T.LOAN_FHZ_NUM,         
         T.CURR_CD,              
         T.ITEM_CD,              
         A.GL_CD_NAME,           
         CASE WHEN T.DRAWDOWN_AMT = 0 THEN T6.CONTRACT_AMT ELSE T.DRAWDOWN_AMT END,         
	     T.DRAWDOWN_TYPE_NEW ,   
		 NVL(T.LOAN_ACCT_NUM, CC.AFF_ACCT_NUM) AS LOAN_ACCT_NUM,  -- 一表通转EAST      
         -- NVL(T.LOAN_ACCT_NAME, CC.RECE_NAME) AS LOAN_ACCT_NAME, -- 一表通转EAST
          NVL(T.LOAN_ACCT_NAME, B.CUST_NAM) AS LOAN_ACCT_NAME, -- 一表通转EAST      
         CASE WHEN D.CUST_ID IS NOT NULL AND T.ITEM_CD NOT LIKE '130302%' THEN T.LOAN_ACCT_BANK 
         ELSE  NVL(NVL(T.LOAN_ACCT_BANK, CC.RECE_BANK_NAME), E.ORG_NAM) 
         END AS LOAN_ACCT_BANK,    -- 一表通转EAST       
         CASE WHEN SUBSTR(T.ITEM_CD, 0, 4) = '1301' THEN '' ELSE NVL(T.PAY_ACCT_NUM, CC.AFF_ACCT_NUM || '_1') END AS PAY_ACCT_NUM,  -- 一表通转EAST        
         CASE WHEN SUBSTR(T.ITEM_CD, 0, 4) = '1301' THEN NULL ELSE NVL(T.PAY_ACCT_BANK,BB.ORG_NAM) END AS PAY_ACCT_BANK,    -- 一表通转EAST  20240620 LMH
         T.DRAWDOWN_DT,          
         T.MATURITY_DT,          
         JJ.ACTUAL_MATURITY_DT,   
         T.LOAN_BUSINESS_TYP,    
         T.IS_FIRST_LOAN_TAG,    
	     T.GUARANTY_TYP,         
		 C.CORP_BUSINSESS_TYPE,  
         T.LOAN_PURPOSE_CD,      
		 T.ACCT_TYP,             
         B.INLANDORRSHORE_FLG,	 
         T.INTERNET_LOAN_FLG,	 
         C.GOV_LOAN_FLG,         
		 T.CIRCLE_LOAN_FLG,      
         T.DRAWDOWN_TYPE,        
         T.TAX_RELATED_FLG,      
		 T.GREEN_LOAN_FLG,       
		 C.CORP_SCALE,           
         B.CUST_TYPE,            
		 T.UNDERTAK_GUAR_TYPE,   
		 D.VOCATION_TYP,
		 D.QUALITY,
		 C.TECH_CORP_TYPE,
		 D.OPERATE_CUST_TYPE,
		 T.RENEW_FLG,             
		 T.IS_REPAY_OPTIONS,      
		 T.LINKAGE_TYPE,          
		 T.REPAY_TYP,             
		 T.FLOAT_TYPE, 
		 T.RATE_FLOAT, 
         T.LOAN_PURPOSE_AREA ,  
          concat(nvl(T.INDUST_RSTRUCT_FLG,'0'),
               decode(T.INDUST_TRAN_FLG,'1','1','2','0','0'),
               replace(nvl(T.INDUST_STG_TYPE,'0'),'#','0')) AS INDUST_RSTRUCT_FLG,  
         T.REPAY_FLG,
		 T.LOAN_NUM_OLD ,
		 T.CANCEL_FLG,
		 D.LOW_INSURANCE_FLG,
		 D.CONTRACT_FARMER_TYPE,
		 D.DEFORMITY_FLG,
		 E.FIN_LIN_NUM,
		 T.LOAN_GRADE_CD,
		 T.FXLL,
		 T.CZCS,
		 CASE  
           WHEN T.DEPARTMENTD ='信用卡' THEN '0098KG' -- 吉林银行总行卡部(信用卡中心管理)(0098KG)
           WHEN T.DEPARTMENTD ='公司金融' OR SUBSTR(T.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
           WHEN T.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
           WHEN T.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
           WHEN SUBSTR(T.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
           WHEN SUBSTR(T.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
           END AS   DEPARTMENTD,
         T.LOAN_KIND_CD,
         T.EXTENDTERM_FLG,
         D.CORP_TYP,
         T.USEOFUNDS,
		 B.REGION_CD,
		 T.GRXFDKYT,
		 T.DEPARTMENTD,
		 T.DRAFT_NBR ,
		 T.NON_COMPENSE_BAL_RMB,
		 CASE WHEN T.GUARANTY_TYP = 'A' AND T.QTDBFS1 IS NULL AND T.QTDBFS2 IS NULL THEN '01' -- 	质押贷款 
     WHEN T.GUARANTY_TYP = 'B' AND T.QTDBFS1 IS NULL AND T.QTDBFS2 IS NULL THEN '02' -- 	抵押贷款
     WHEN T.GUARANTY_TYP = 'C' AND T.QTDBFS1 IS NULL AND T.QTDBFS2 IS NULL THEN '03' -- 	保证贷款
     WHEN T.GUARANTY_TYP = 'B' AND T.QTDBFS1 = 'A'   AND T.QTDBFS2 IS NULL THEN '05' -- 	抵押+质押+其他
     WHEN T.GUARANTY_TYP = 'B' AND (T.QTDBFS1 = 'C' OR T.QTDBFS1='00') THEN '06' -- 	抵押+保证（或信用）
     WHEN T.GUARANTY_TYP = 'A' AND (T.QTDBFS1 = 'C' OR T.QTDBFS1='00') THEN '06' -- 	抵押+保证（或信用）
     WHEN T.GUARANTY_TYP = 'C' AND  T.QTDBFS1='00'  THEN '06' -- 	抵押+保证（或信用）
     ELSE '00'
     END  AS QTDBFS ,
     T.GREEN_LOAN_TYPE,
     T6.CP_ID,    -- [20250513] [狄家卉] [JLBA202504060003][吴大为]   新增产品号
     T.ENTRUST_PURPOSE_CD ,-- [20250513] [狄家卉] [JLBA202504060003][吴大为]  新增委托贷款特殊投向
	 C.CUST_TYP AS C_CUST_TYPE , --  [20250708] [姜俐锋] [JLBA202504160004][吴大为]  修改授信后需要取对应对公客户类型 新增字段
	 t.LOAN_NUM AS PH_LOAN_NUM   --  [20250708] [姜俐锋] [JLBA202504160004][吴大为]  修改授信后需要修改关联 新增字段
     FROM V_PUB_IDX_DK_YSDQRJJ T  -- 贷款借据信息表 
    INNER JOIN SMTMODS.L_FINA_INNER A -- 内部科目对照表
       ON T.ITEM_CD = A.STAT_SUB_NUM
      AND T.ORG_NUM =  A.ORG_NUM
      AND A.DATA_DATE = I_DATE
     LEFT JOIN SMTMODS.L_CUST_ALL B -- 全量客户信息表
       ON T.CUST_ID = B.CUST_ID
      AND B.DATA_DATE = I_DATE
     LEFT JOIN VIEW_L_PUBL_ORG_BRA E -- 机构表
       ON T.ORG_NUM = E.ORG_NUM
      AND E.DATA_DATE = I_DATE 
     LEFT JOIN SMTMODS.L_CUST_C C -- 对公客户补充信息表
       ON B.CUST_ID = C.CUST_ID
      AND C.DATA_DATE = I_DATE   
     LEFT JOIN SMTMODS.L_CUST_P D -- 对私客户补充信息表
       ON B.CUST_ID = D.CUST_ID
      AND D.DATA_DATE = I_DATE
    LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT T6 -- 贷款合同信息表
       ON T.ACCT_NUM = T6.CONTRACT_NUM
      AND T6.DATA_DATE = I_DATE
     LEFT JOIN SMTMODS.L_ACCT_WRITE_OFF T7  -- 核销
       ON T7.LOAN_NUM=T.LOAN_NUM
      AND T7.DATA_DATE = I_DATE
      AND T7.WRITE_OFF_DATE < I_DATE
     LEFT JOIN SMTMODS.L_ACCT_TRANSFER T8  
       ON T8.LOAN_NUM=T.LOAN_NUM
      AND T8.DATA_DATE = I_DATE
      AND T8.TRANS_DATE = I_DATE  
     LEFT JOIN SMTMODS.L_AGRE_BILL_INFO CC -- 商业汇票票面信息表  一表通转EAST
       ON T.DRAFT_NBR = CC.BILL_NUM
      AND CC.DATA_DATE = I_DATE
     LEFT JOIN  V_PUB_IDX_DK_ZQDQRJJ JJ
       ON T.LOAN_NUM=JJ.LOAN_NUM
      AND JJ.DATA_DATE=I_DATE
     LEFT JOIN (SELECT *
                   FROM (SELECT X.BANK_CD,
                                X.ORG_NAM,
                                ROW_NUMBER() OVER(PARTITION BY X.BANK_CD ORDER BY X.BANK_CD) AS NUM
                           FROM VIEW_L_PUBL_ORG_BRA X
                          WHERE X.DATA_DATE = I_DATE)TT
                  WHERE TT.NUM = 1)BB
       ON CC.AFF_ACCT_BANK = BB.BANK_CD       -- 一表通转EAST 20240620 LMH  还款账号所属行名称
    WHERE T.DATA_DATE = I_DATE
      AND (SUBSTR(T.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103')  -- 票据 ,福费廷 
           OR  SUBSTR(T.ITEM_CD,1,6) IN ('130302','130301','302001','302002')  -- 公司贷款 , 个人贷款,委托公司贷款 ,委托个人贷款
           OR  SUBSTR(T.ITEM_CD,1,4) IN ('1305','1306','7140'))  --  贸易融资  ,垫款  ,银团
      -- AND T6.ACCT_STS <> '2'
      AND nvl(T6.PROD_NAME,'##') NOT IN ('个人遗留贷款无本产品','公司遗留贷款无本产品') -- 剔除无本有息历史数据 
      AND (T.ACCT_STS <> '3'
           OR T.LOAN_ACCT_BAL > 0 
		   -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
           OR T.FINISH_DT >= concat(substr(I_DATE,1,4),'0101')
           OR (T6.INTERNET_LOAN_TAG = 'Y' AND T.FINISH_DT >= date_format(date_sub(to_date(concat(substr(I_DATE,1,4),'-01-01')),1),'yyyyMMdd')) 
           OR (t6.CP_ID ='DK001000100041' AND T.FINISH_DT >= date_format(date_sub(to_date(concat(substr(I_DATE,1,4),'-01-01')),1),'yyyyMMdd'))  -- [20250929][姜俐锋][JLBA202507300010][信贷新增产品]: 同网贷部分数据处理方式
           )
           
      and (T.LOAN_STOCKEN_DATE is null or T.LOAN_STOCKEN_DATE >= concat(substr(I_DATE,1,4),'0101')); -- add by haorui 20250311 JLBA202408200012_信贷不良资产收益权转让
           
           COMMIT;
	
 
 INSERT INTO  T_6_27
 (
    F270001     , -- 01 '借据ID'
	F270002     , -- 02 '客户ID'
    F270003     , -- 03 '协议ID'
    F270004     , -- 04 '机构ID'
    F270005     , -- 05 '分户账号'
    F270006     , -- 06 '币种'
    F270007     , -- 07 '科目ID'
    F270008     , -- 08 '科目名称'
    F270009     , -- 09 '借款金额'
    F270010     , -- 10 '贷款发放类型'
    F270011     , -- 11 '贷款入账账号'
    F270012     , -- 12 '贷款入账户名'
    F270013     , -- 13 '入账账号所属行名称'
    F270014     , -- 14 '还款账号'
    F270015     , -- 15 '还款账号所属行名称'
    F270016     , -- 16 '贷款实际发放日期'
    F270017     , -- 17 '贷款原始到期日期'
    F270018     , -- 18 '贷款实际到期日期'
    F270019     , -- 19 '贷款用途'
    F270020     , -- 20 '首贷户标识'
    F270021     , -- 21 '担保方式'
    F270022     , -- 22 '行业类型（按客户所属行业划分）'
    F270023     , -- 23 '行业类型（按贷款投向划分）'
    F270024     , -- 24 '个人非经营性贷款所属类别'
    F270025     , -- 25 '信贷业务种类'
    F270026     , -- 26 '保障性安居工程贷款标识'
    F270027     , -- 27 '贷款新规种类'
    F270028     , -- 28 '境内外贷款标识'
    F270029     , -- 29 '并购贷款标识'
    F270030     , -- 30 '住房抵押贷款标识'
    F270031     , -- 31 '互联网贷款标识'
    F270032     , -- 32 '贷款对象类型代码'
    F270033     , -- 33 '个人经营性贷款标识'
    F270034     , -- 34 '贷款主体为地方政府融资平台标识'
    F270035     , -- 35 '含行为性期权条款标识'
    F270036     , -- 36 '循环贷标识'
    F270037     , -- 37 '受托支付类型'
    F270038     , -- 38 '银税合作贷款 标识'
    F270039     , -- 39 '银团贷款标识'
    F270040     , -- 40 '绿色融资类型'
    F270041     , -- 41 '科技贷款标识'
    F270042     , -- 42 '涉农贷款标识'
    F270043     , -- 43 '普惠型小微企业和其它组织贷款标识（大类）'
    F270044     , -- 44 '普惠型小微企业和其它组织贷款标识（中类）'
    F270045     , -- 45 '普惠型小微企业和其它组织贷款标识（小类）'
    F270046     , -- 46 '普惠型涉农贷款标识（大类）'
    F270047     , -- 47 '普惠型涉农贷款标识（中类）'
    F270048     , -- 48 '普惠型涉农贷款标识（小类）'
    F270049     , -- 49 '普惠型消费贷款标识（大类）'
    F270050     , -- 50 '普惠型消费贷款标识（小类）'
    F270051     , -- 51 '创业担保贷款标识'
    F270052     , -- 52 '无还本续贷贷款标识'
    F270053     , -- 53 '具备提前还款权标识'
    F270054     , -- 54 '投贷联动业务标识'
    F270055     , -- 55 '投贷联动业务——联动方式标识'
    F270056     , -- 56 '投贷联动业务——企业成长阶段标识'
    F270057     , -- 57 '投贷联动业务——企业上市标识'
    F270058     , -- 58 '投贷联动业务——不良贷款处置方式标识'
    F270059     , -- 59 '计息方式'
    F270060     , -- 60 '贷款利率定价基础'
    F270061     , -- 61 '利率浮动'
    F270062     , -- 62 '罚息利率'
    F270063     , -- 63 '贷款投向地区'
    F270064     , -- 64 '债务重组次数'
    F270065     , -- 65 '重点产业标识'
    F270066     , -- 66 '是否为“调整后存贷比口径”的调整项'
    F270067     , -- 67 '上笔信贷借据号'
    F270068     , -- 68 '备注'
    F270069     , -- 69 '采集日期'
    DIS_DATA_DATE,
    DIS_BANK_ID,
    DEPARTMENT_ID,
    F270070 ,-- '房地产贷款类别',
    F270071 ,-- '住房租赁贷款类别',
    F270072,  -- '地方政府专项债券配套融资标识',
    F270073 ,-- '新型抵质押标识',
    F270074 ,-- '新型抵质押物价值',
    F270075  -- '融资担保机构尚未履行代偿责任金额'
 )
  
 WITH SDH_BS_TMP AS 
 (SELECT 
        T.ORG_NUM,
        T.CUST_ID,
        T.LOAN_NUM,
        T.DRAWDOWN_DT,
        NVL(T.DRAWDOWN_AMT , 0)DRAWDOWN_AMT ,
        T.CURR_CD,
        ROW_NUMBER() OVER(PARTITION BY T.CUST_ID ORDER BY T.DRAWDOWN_DT,T.LOAN_NUM) RNK
        FROM SMTMODS.L_ACCT_LOAN T
       WHERE T.DATA_DATE = I_DATE
         AND T.LOAN_ACCT_BAL <> 0 -- 贷款余额
         AND T.ACCT_TYP NOT LIKE '90%' -- 不含委托贷款
         AND T.IS_FIRST_LOAN_TAG = 'Y' -- 是否首次贷款 
         ),
      GUARANTEE_RELATION AS 
  (SELECT DISTINCT F.CONTRACT_NUM , '1' AS COLL_TYP
 FROM SMTMODS.L_AGRE_GUA_RELATION F -- 业务合同与担保合同对应关系表    
 LEFT JOIN SMTMODS.L_AGRE_GUARANTEE_RELATION G --  担保合同与担保信息对应关系表  
   ON G.GUAR_CONTRACT_NUM = F.GUAR_CONTRACT_NUM  
  AND G.DATA_DATE = I_DATE            
 LEFT JOIN SMTMODS.L_AGRE_GUARANTY_INFO H -- 抵质押物详细信息 
   ON G.GUARANTEE_SERIAL_NUM = H.GUARANTEE_SERIAL_NUM
  AND H.DATA_DATE = I_DATE            
   WHERE F.DATA_DATE = I_DATE
      AND SUBSTR(H.COLL_TYP, 1, 3) IN ('B01', 'B02') ),
      
        G5305_GUAR_TEMP1 AS -- 20241128 JLBA202409120001 
  ( SELECT DISTINCT   E.CONTRACT_NUM 
   FROM SMTMODS.L_AGRE_GUARANTEE_RELATION F1  -- 担保合同与担保信息对应关系表
        LEFT JOIN SMTMODS.L_AGRE_GUARANTEE_CONTRACT F  -- 担保合同表
          ON F.GUAR_CONTRACT_NUM = F1.GUAR_CONTRACT_NUM
         AND F.DATA_DATE = I_DATE
        LEFT JOIN SMTMODS.L_AGRE_GUA_RELATION E  -- 业务合同与担保合同对应关系表 E
          ON E.GUAR_CONTRACT_NUM = F.GUAR_CONTRACT_NUM
         AND E.DATA_DATE = I_DATE
        LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT B  -- 贷款合同信息表 B
          ON B.CONTRACT_NUM = E.CONTRACT_NUM
         AND B.DATA_DATE = I_DATE 
        INNER JOIN  FINANCE_COMPANY_LIST L
         ON TRIM(F1.GUARANTEE_NAME) = TRIM(L.COMPANY_NAME)
        WHERE F1.DATA_DATE = I_DATE
         AND F.GUAR_CONTRACT_STATUS = 'Y' -- 担保合同有效状态 
         AND B.ACCT_STS = '1' -- 合同状态：1有效
         AND L.GOV_FLG = 'Y'
         ) ,
         
  S6301_DATA_COLLECT_GUARANTEE AS (
    SELECT T2.CONTRACT_NUM,
        SUM(T4.COLL_MK_VAL * T6.CCY_RATE) AS COLL_MK_VAL_SUM  -- 押品市场价值
    FROM SMTMODS.L_AGRE_GUA_RELATION T2
       INNER JOIN SMTMODS.L_AGRE_GUARANTEE_RELATION T3
          ON T2.GUAR_CONTRACT_NUM = T3.GUAR_CONTRACT_NUM
         AND T3.DATA_DATE = I_DATE
       INNER JOIN SMTMODS.L_AGRE_GUARANTY_INFO T4
          ON T3.GUARANTEE_SERIAL_NUM = T4.GUARANTEE_SERIAL_NUM
         AND T4.DATA_DATE = I_DATE
        LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT T5
          ON T2.CONTRACT_NUM = T5.CONTRACT_NUM
         AND T5.DATA_DATE = I_DATE
        LEFT JOIN SMTMODS.L_PUBL_RATE T6
          ON T6.DATA_DATE = I_DATE
         AND T6.BASIC_CCY = T3.CURR_CD  --  担保物折币
         AND T6.FORWARD_CCY = 'CNY'
       WHERE T2.DATA_DATE = I_DATE
         AND T5.MAIN_GUARANTY_TYP IN ('A', 'B')  --  主要担保方式：抵押质押
         AND T4.COLL_MK_VAL <> 0 
         GROUP BY T2.CONTRACT_NUM ),
      
         
     ACCT_LOAN_FARMING_FULL AS 
     (SELECT A.LOAN_NUM,A.SNDKFL,F.COOP_LAON_FLAG,F.RUR_COLL_ECO_ORG_LOAN_FLG
FROM (SELECT T.LOAN_NUM,T.SNDKFL 
        FROM V_PUB_IDX_DK_GRSNDK  T -- 个人涉农贷款
       WHERE T.DATA_DATE = I_DATE
         AND SUBSTR(T.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103','P_201') -- 'P_101', 'P_102', 'P_103' 农户
       UNION ALL
      SELECT T.LOAN_NUM,T.SNDKFL 
        FROM V_PUB_IDX_DK_GTGSHSNDK T -- 个体工商户涉农贷款
       WHERE T.DATA_DATE = I_DATE
         AND SUBSTR(T.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103','P_201')
       UNION ALL
      SELECT A.LOAN_NUM,A.SNDKFL
        FROM V_PUB_IDX_DK_DGSNDK A -- 对公涉农   
       INNER JOIN SMTMODS.L_ACCT_LOAN B
          ON A.LOAN_NUM =B.LOAN_NUM
         AND B.DATA_DATE = I_DATE
       WHERE A.DATA_DATE = I_DATE
         AND (A.SNDKFL LIKE 'C_301%' OR SUBSTR(A.SNDKFL, 0, 5) = 'C_401' OR A.SNDKFL LIKE 'C_1%' OR SUBSTR(A.SNDKFL, 0, 3) = 'C_2' OR ((A.SNDKFL LIKE 'C_402%' OR A.SNDKFL LIKE 'C_302%') AND
             (CASE WHEN SUBSTR(A.SNDKFL, 0, 7) IN ('C_40202', 'C_30202') AND
             (NVL(A.AGR_USE_ADDL, '#') IN ('05') OR NVL(B.LOAN_PURPOSE_CD, '#') IN ('A0514', 'A0523')) THEN 1
              ELSE 0 END) = 0))) A
--        INNER JOIN SMTMODS.L_ACCT_LOAN B -- 贷款借据信息表
--           ON A.LOAN_NUM = B.LOAN_NUM
--          AND B.DATA_DATE = I_DATE
       INNER JOIN SMTMODS.L_ACCT_LOAN_FARMING F
          ON A.LOAN_NUM = F.LOAN_NUM
         AND F.DATA_DATE = I_DATE ) 
--        WHERE B.ACCT_TYP NOT IN ('B01', 'C01', 'D01','90') -- 去除委托贷款
--          AND B.CURR_CD = 'CNY' -- 人民币
--          AND B.ACCT_STS <> 3 -- 账户状态非注销
--          AND B.CANCEL_FLG = 'N' -- 核销标识为否
--          AND B.LOAN_STOCKEN_DATE IS NULL )
     
      

SELECT T.LOAN_NUM, -- 01 '借据ID'
--        CASE WHEN  SUBSTR(T.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN T6.ECIF_CUST_ID
--        ELSE T.CUST_ID
--        END AS F270002
       NVL(T6.ECIF_CUST_ID, T.CUST_ID) AS F270002, -- 02 '客户ID'  JLBA202411070004 YBT_JYF27-166 20241212 原 T.CUST_ID, -- 02 '客户ID' 
       T.ACCT_NUM, -- 03 '协议ID'
       concat(substr(trim(T.FIN_LIN_NUM),1,11), T.ORG_NUM), -- 04 '机构ID'
       T.LOAN_NUM , -- NVL(T.LOAN_FHZ_NUM,T.LOAN_NUM), -- 05 '分户账号'   一表通转EAST
       T.CURR_CD, -- 06 '币种'
       T.ITEM_CD, -- 07 '科目ID'
       T.GL_CD_NAME, -- 08 '科目名称'
       T.DRAWDOWN_AMT, -- 09 '借款金额'
       CASE
         WHEN T.EXTENDTERM_FLG = 'Y' THEN  '02' -- 展期
         WHEN T.LOAN_KIND_CD = '1' THEN  '01' -- 新增          
         WHEN T.LOAN_KIND_CD = '3' THEN  '03' -- 借新还旧
         WHEN T.LOAN_KIND_CD = '4' AND EXTENDTERM_FLG <> 'Y' THEN  '04' -- 重组，展期贷款除外
         WHEN T.LOAN_KIND_CD = '6' THEN '05' -- 无还本续贷
         ELSE '06'
       END, -- 10 '贷款发放类型' 
       /* CASE
       WHEN P2.LOAN_NUM IS NOT NULL THEN P2.ACC_NO
       WHEN T.ITEM_CD ='13060201' THEN P3.BILL_NUM
       WHEN SUBSTR(T.ITEM_CD,1,6) IN ('130102','130105') THEN NVL(P1.CUST_BANK_CD,'908290099998')
       WHEN SUBSTR(T.ITEM_CD,1,5) ='130103' THEN L.ORG_NUM 
       ELSE T.LOAN_ACCT_NUM
       END AS  DKRZZH */
       NVL(T.LOAN_ACCT_NUM,BB.O_ACCT_NUM), -- 11 '贷款入账账号'  
       T.LOAN_ACCT_NAME, -- 12 '贷款入账户名'
       T.LOAN_ACCT_BANK, -- 13 '入账账号所属行名称'
       T.PAY_ACCT_NUM, -- 14 '还款账号' 
       T.PAY_ACCT_BANK, -- 15 '还款账号所属行名称'
       date_format(from_unixtime(unix_timestamp(T.DRAWDOWN_DT,'yyyyMMdd')),'yyyy-MM-dd'), -- 16 '贷款实际发放日期'
       date_format(from_unixtime(unix_timestamp(T.MATURITY_DT,'yyyyMMdd')),'yyyy-MM-dd'), -- 17 '贷款原始到期日期'
       date_format(from_unixtime(unix_timestamp(T.ACTUAL_MATURITY_DT,'yyyyMMdd')),'yyyy-MM-dd'), -- 18 '贷款实际到期日期'         
      -- T.USEOFUNDS
       CASE 
         WHEN T.ACCT_TYP = '010201' THEN '商业用房贷款'
         WHEN T.ACCT_TYP = '010202' THEN '商用车贷款'
         WHEN T.ACCT_TYP = '010203' THEN '个人商住两用房贷款'
         WHEN T.ACCT_TYP = '010299' THEN '其他个人经营性贷款'
         WHEN T.GRXFDKYT = '01' THEN '住房按揭'
         WHEN T.GRXFDKYT = '02' THEN '商用房按揭'
         WHEN T.GRXFDKYT = '03' THEN '房屋装修'
         WHEN T.GRXFDKYT = '04' THEN '大件耐用消费品'
         WHEN T.GRXFDKYT = '05' THEN '汽车'
         WHEN T.GRXFDKYT = '06' THEN '旅游度假'
         WHEN T.GRXFDKYT = '07' THEN '教育'
         WHEN T.GRXFDKYT = '08' THEN '健康'
         WHEN T.GRXFDKYT = '09' THEN '婚育'
         WHEN T.GRXFDKYT = '10' THEN '其他'
         ELSE NVL(T.USEOFUNDS, '其他') -- 20241015
        END  AS YT    , -- 19 '贷款用途' 
       CASE
         WHEN P.RNK = 1 THEN
          '1'
         ELSE
          '0'
       END, -- 20 '首贷户标识'
       CASE
         WHEN T.GUARANTY_TYP = 'A' THEN
          '01' -- 质押
         WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) = 'B' THEN
          '02' -- 抵押
         WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) = 'C' THEN
          '03' -- 保证
         WHEN T.GUARANTY_TYP = 'D' THEN
          '04' -- 信用 
          ELSE '00'
       END AS GUARANTY_TYP ,
       -- T.QTDBFS , -- 21 '担保方式'
       -- NVL(T.CORP_BUSINSESS_TYPE, T.CORP_TYP), -- 22 '行业类型（按客户所属行业划分）'
       -- T.CORP_BUSINSESS_TYPE , -- 22 '行业类型（按客户所属行业划分）'  -- JLBA202411070004_YBT_JYF27-164 20241212
      /* CASE WHEN SUBSTR(T.ACCT_TYP,1,4) = '0102' THEN T.CORP_TYP --  20250311
            ELSE nvl(T.CORP_BUSINSESS_TYPE,T.LOAN_PURPOSE_CD )
            END , -- 22 '行业类型（按客户所属行业划分）'  20250311*/
       CASE  
         WHEN SUBSTR(T.ACCT_TYP, 1, 2) = '01'   
          AND T.ACCT_TYP NOT LIKE '0102%' THEN NULL -- 个人消费（01个人贷款去掉0102个人经营性贷款）
         ELSE NVL(T.CORP_BUSINSESS_TYPE,T.LOAN_PURPOSE_CD)
       END, -- 22 '行业类型（按客户所属行业划分） [20250513][狄家卉][JLBA202504060003][吴大为]: 单位名称取行业类型 ，自然人客户（个人名消费贷款默认为空，个人经营性），取贷款投向; 同2.4
       T.LOAN_PURPOSE_CD, -- 23 '行业类型（按贷款投向划分）'
       CASE
         WHEN T.ACCT_TYP  = '010301' THEN  -- '010202'商用车贷款 属于经营性贷款，应在此剔除 JLBA202411070004_YBT_JYF27-164 20241212
          '01' -- 汽车贷款
         WHEN T.ACCT_TYP IN ('010101', '010199') THEN
          '02' -- 住房按揭贷款
         -- WHEN T.ACCT_TYP IN ('019999','010399') AND T.GRXFDKYT= '05' THEN  '01'	-- 汽车贷款
         -- WHEN T.ACCT_TYP IN ('019999','010399') AND T.GRXFDKYT= '01' THEN  '02'	-- 住房按揭贷款
         -- WHEN T.ACCT_TYP IN ('019999','010399') AND T.GRXFDKYT= '03' THEN  '04'	-- 房屋装修贷款
         -- WHEN T.ACCT_TYP IN ('019999','010399') AND T.GRXFDKYT= '04' THEN  '05'	-- 大件耐用消费品贷款 
         WHEN SUBSTR(T.ACCT_TYP,1,2)='01' and SUBSTR(T.ACCT_TYP,1,4) <> '0102' THEN
          '06' -- 其它
         WHEN T.CP_ID = 'WD003000200005' and  T.ENTRUST_PURPOSE_CD = 'A02' THEN -- [20250513] [狄家卉] [JLBA202504060003][吴大为]  个人委托贷款(消费)且 委托贷款特殊投向A02汽车
          '01' -- 01-汽车贷款
         WHEN T.CP_ID = 'WD003000200005' and  T.ENTRUST_PURPOSE_CD = 'A03' then -- [20250513] [狄家卉] [JLBA202504060003][吴大为]  个人委托贷款(消费)且 委托贷款特殊投向A03住房按揭贷款
          '02' -- 02-住房按揭贷款
         WHEN T.CP_ID = 'WD003000200005' and  T.ENTRUST_PURPOSE_CD = 'A99' then -- [20250513] [狄家卉] [JLBA202504060003][吴大为]  个人委托贷款(消费)且 委托贷款特殊投向A99其他
          '06' -- 06-其他
         ELSE
          '00'
       END AS SSLB, -- 24个人非经营性贷款所属类别
       CASE
         WHEN T.ACCT_TYP LIKE '0202%' THEN
         '01' -- 流动资金贷款
         WHEN T.ACCT_TYP LIKE '0801%' THEN
         '02' -- 法人账户透支
         WHEN Q.ACCT_NUM IS NOT NULL AND L.SYNDICATEDLOAN_FLG='Y'  THEN  
         '04' -- 项目贷款（银团）
         WHEN Q.ACCT_NUM IS NOT NULL THEN 
         '03' -- 项目贷款 
         WHEN T.ACCT_TYP LIKE '0201%' THEN   -- 05，03执行顺序调换 0619_LHY
         '05' -- 一般固定资产贷款
        -- WHEN T.ACCT_TYP = '010101' THEN
         WHEN SUBSTR(T.ACCT_TYP, 1, 2) = '01' AND  -- 20250116
              T.ITEM_CD NOT LIKE '130302%' AND  -- 20250116
              T.ACCT_TYP LIKE '0101%' THEN
         '07' --  7 住房按揭贷款（非公转商）
         WHEN SUBSTR(T.ACCT_TYP, 1, 2) = '01' AND  -- 20250116
              T.ITEM_CD NOT LIKE '130302%' AND  -- 20250116
              T.ACCT_TYP LIKE '010201' THEN
         '08' -- 个人经营性商用房贷款
               --  9 个人消费性商用房贷款
         WHEN SUBSTR(T.ACCT_TYP, 1, 2) = '01' AND  -- 20250116
              T.ITEM_CD NOT LIKE '130302%' AND  -- 20250116
              T.ACCT_TYP LIKE '0104%' THEN
         '11' -- 助学贷款
         WHEN SUBSTR(T.ACCT_TYP, 1, 2) = '01' AND  -- 20250116
              T.ITEM_CD NOT LIKE '130302%' AND  -- 20250116
              (T.ACCT_TYP LIKE '0102%' AND T.ACCT_TYP NOT LIKE '010201%')  THEN   -- 0619 EAST该条数据为其他_个人贷款 LHY
         '13' -- 个人经营性贷款
         -- WHEN T.ACCT_TYP LIKE '010301%' OR (T.DEPARTMENTD ='个人信贷' AND GRXFDKYT ='05')  THEN
         WHEN SUBSTR(T.ACCT_TYP, 1, 2) = '01' AND  -- 20250116
              T.ITEM_CD NOT LIKE '130302%' AND  -- 20250116
              T.ACCT_TYP ='010301' THEN
         '10' -- 个人汽车贷款
         -- WHEN T.ACCT_TYP LIKE '0103%' OR (T.DEPARTMENTD ='个人信贷' AND T.ACCT_TYP ='019999' AND L.CP_ID <> 'GJ0100001000005')  THEN -- 线下吉房贷(经营) GJ0100001000005
         -- WHEN T.ACCT_TYP LIKE '010399%' THEN  -- 0618_LHY
         WHEN SUBSTR(T.ACCT_TYP, 1, 2) = '01' AND  -- 20250116
              T.ITEM_CD NOT LIKE '130302%' AND  -- 20250116
              T.ACCT_TYP IN  ('010399','019999','010302') THEN
         '12' -- 个人消费贷款
         WHEN SUBSTR(T.ITEM_CD, 1, 6) IN ('130101', '130104') THEN
         '14' -- 票据贴现
         WHEN T.ITEM_CD LIKE '130105%' THEN
         '15' -- 买断式转贴现
         WHEN (T.ACCT_TYP LIKE '04%' OR substr(T.ITEM_CD,1,6)='130103') -- 20240408 新增范围
              THEN
         '16' -- 贸易融资业务
         WHEN T.ACCT_TYP LIKE '05%' THEN
         '17' -- 融资租赁业务
         WHEN T.ACCT_TYP LIKE '09%' THEN
         '18' -- 垫款
         WHEN T.ACCT_TYP LIKE '90%' THEN
         '19' -- 委托贷款
         WHEN T.ACCT_TYP = '0399' THEN
         '20' -- 买断式其他票据类资产
       --  WHEN T.ACCT_TYP LIKE '010302%' THEN  '21'  -- 其他-互联网贷款    0618_LHY
         ELSE
          '00' -- 其他
       END AS XDYWZL, -- 25信贷业务种类
       DECODE(E.PROPERTYLOAN_TYP, '111', 1, 0), -- 26 保障性安居工程贷款标识
        CASE
         WHEN SUBSTR(T.ACCT_TYP, 1, 2) = '01' AND
              T.ITEM_CD NOT LIKE '130302%' THEN
          '01' -- 个人贷款                                       
         WHEN T.ACCT_TYP = '0202' THEN
          '02' -- 流动资金贷款
         WHEN Q.ACCT_NUM IS NOT NULL THEN
          '03' -- 项目贷款
         WHEN T.ACCT_TYP = '0201' THEN
          '04' -- 一般固定资产贷款
         ELSE
          '05' -- 其他
       END AS XGZL, -- 27 贷款新规种类  
       -- DECODE(T.INLANDORRSHORE_FLG, 'Y', '01', 'N', '02', '03')
       '01' , -- 28 境内外贷款标识             
       DECODE(T.ACCT_TYP, '0203', '1', '0'), -- 29 并购贷款标识                
       NVL(G.COLL_TYP, 0), -- 30 住房抵押贷款标识
       DECODE(T.INTERNET_LOAN_FLG, 'Y', '1', 'N', '0', '0'), -- 31 互联网贷款标识                    
       CASE
         WHEN T.CUST_TYPE = '00' THEN
          '02'
         WHEN T.CUST_TYPE IN ('11', '12') THEN
          '01'
         ELSE
          '00'
       END, -- 32 贷款对象类型代码                                                            
       DECODE(SUBSTR(T.ACCT_TYP, 1, 4), '0102', '1', '0'), -- 33 个人经营性贷款标识                           
       CASE
         WHEN T.GOV_LOAN_FLG IN ('A', 'B', 'C') THEN
          '01'
         ELSE
          '0'
       END, -- 34贷款主体为地方政府融资平台标识 
       '1', -- 35 含行为性期权条款标识                       
       DECODE(T.CIRCLE_LOAN_FLG, 'Y', '1', 'N', '0', '0'), -- 36 循环贷标识 
       DECODE(T.DRAWDOWN_TYPE, 'A', '01', 'B', '02', 'C', '03', '01' ), -- 37 受托支付类型   01 自主支付 02 受托支付 03 混合支付 
       DECODE(T.TAX_RELATED_FLG, 'Y', '1', 'N', '0', '0'), -- 38 银税合作贷款 标识                      
       DECODE(L.SYNDICATEDLOAN_FLG, 'Y', '1', 'N', '0', '0'), -- 39 银团贷款标识
       -- DECODE(T.GREEN_LOAN_FLG, 'Y', '1', 'N', '0', '0'), -- 40 绿色贷款标识
       T5.GB_CODE , -- 40 绿色融资类型
       -- 需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   
       -- 修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据,后续于佳禾问监管说专精特新大型企业也要报送，苏桐与吴大为和冯启航确认一表通与east也一起修改逻辑
       /*
       CASE
         WHEN TECH_CORP_TYPE IN ('C01', 'C02') THEN
          '1'
         ELSE
          '0'
       end*/
       CASE WHEN (C1.IF_HIGH_SALA_CORP = 'Y' -- 高新技术企业
             OR C1.IF_ST_SMAL_CORP = '1' -- 科技型中小企业
             OR (C1.IF_SPCLED_NEW_CUST = '1' and  C1.CORP_SCALE IN ('B','S', 'M','T')) -- 专精特新”中小企业
             OR C1.HUGE_SPCLED_NEW_CORP = '1' -- 专精特新“小巨人”企业
             OR C1.NAT_TECH_INVT_CORP = '1' -- 国家技术创新示范企业
             OR C1.MNFT_SIGL_FRST_CORP = '1' -- 制造业单项冠军企业
             OR(P5.CUST_NAME IS NOT NULL AND C1.CORP_SCALE IN ('S', 'M', 'T')) -- 创新型中小企业
            -- OR P6.CUST_NAME IS NOT NULL  20250730 吴大为邮件通知与1104 S70科技贷库口径一致 姜俐锋修改
             )  -- 国家技术中心
       THEN
          '1'
         ELSE
          '0'
       END, -- 41 科技贷款标识
        CASE WHEN K.LOAN_NUM IS NOT NULL  THEN '1' ELSE '0'
       END, -- 41 涉农贷款标识
       CASE 
         WHEN V.FACILITY_AMT<= 30000000 AND T1.PHXXWQYFRDK = '是' THEN
          '01' -- 普惠型小微企业法人贷款
         WHEN V.FACILITY_AMT<= 30000000 AND  T1.PHXQTZZDK = '是' THEN
          '02' -- 普惠型其它组织贷款
         WHEN V.FACILITY_AMT<= 30000000 AND  T1.PHXGTGSXWQYZDK = '是' THEN
          '03' -- 普惠型个体工商户和小微企业主贷款
         WHEN V.FACILITY_AMT<= 30000000 AND  T1.PHXQTGRJYXDK = '是' THEN
          '04' -- 普惠型其他个人（非农户）经营性贷款
         ELSE
          '00'
       END, -- 43 普惠型小微企业和其它组织贷款标识（大类）  
       CASE WHEN V.FACILITY_AMT<= 30000000 AND (T1.PHXSNXWQYFRDK = '是' OR T1.PHXKCXWQYFRDK = '是' OR T1.XWQYFRCYDBDK = '是' OR T1.PHXGTGSHDK = '是' OR T1.PHXXWQYZDK = '是' OR T1.GRCYDBDK = '是')  THEN 
          SUBSTR(DECODE(T1.PHXSNXWQYFRDK,'是','01;','') ||DECODE(T1.PHXKCXWQYFRDK,'是','02;','') ||DECODE(T1.XWQYFRCYDBDK,'是','03;','') ||DECODE(T1.PHXGTGSHDK,'是','04;','') ||DECODE(T1.PHXXWQYZDK,'是','05;','') ||DECODE(T1.GRCYDBDK,'是','06;','') 
                 ,1,LENGTH(DECODE(T1.PHXSNXWQYFRDK,'是','01;','') ||DECODE(T1.PHXKCXWQYFRDK,'是','02;','') ||DECODE(T1.XWQYFRCYDBDK,'是','03;','') ||DECODE(T1.PHXGTGSHDK,'是','04;','') ||DECODE(T1.PHXXWQYZDK,'是','05;','') ||DECODE(T1.GRCYDBDK,'是','06;',''))-1
                 )
          ELSE -- '01'普惠型涉农小微企业法人贷款  '02'普惠型科创小微企业法人贷款 '03'小微企业法人创业担保贷款 '04' 普惠型个体工商户贷款 '05'普惠型小微企业主贷款 '06'个人创业担保贷款
          '00'
       END, -- 44 普惠型小微企业和其它组织贷款标识（中类） 因校验公式YBT_JYF27-148 发现可能同时归属几类的贷款 87V
       CASE
         WHEN V.FACILITY_AMT<= 30000000 AND T1.PHXNCJTJJZZDK = '是' THEN
          '01' -- 普惠型农村集体经济组织贷款  
         WHEN V.FACILITY_AMT<= 30000000 AND T1.PHXNMZYHZSDK = '是' THEN
          '02' -- 普惠型农民专业合作社贷款
         WHEN V.FACILITY_AMT<= 30000000 AND T1.CJRCYDBDK = '是' THEN
          '03' -- 残疾人创业担保贷款
         ELSE
          '00'
       END, -- 45 普惠型小微企业和其它组织贷款标识（小类）   
        CASE
         WHEN V.FACILITY_AMT <= 5000000       
           AND T.ACCT_TYP NOT LIKE '90%'  
           AND T.CANCEL_FLG <> 'Y' 
           AND (K.LOAN_NUM IS NOT NULL  AND SUBSTR(K.SNDKFL,1,5)  IN ('P_101', 'P_102', 'P_103') 
           and (T.ACCT_TYP LIKE '0102%' -- 个人经营性标识  -- 20250401 修改条件原来是or
                 OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) ) -- 个体工商户贸易融资  
           THEN   
          '01' -- 普惠型农户经营性贷款 因校验公式 YBT_JYF27-149 建档立卡贫困户经营性贷款 应归为 普惠型农户经营性贷款 87V
         WHEN V.FACILITY_AMT <= 10000000 
           AND T.CORP_SCALE IN ('S', 'T') 
           AND (SUBSTR(T.C_CUST_TYPE, 0, 1) IN ('1', '0')   -- --  [20250708] [姜俐锋] [JLBA202504160004][吴大为]  修改授信后需要取对应对公客户类型 新增字段
               OR  SUBSTR(T.C_CUST_TYPE,0,2) ='91') -- [20251028][巴启威][JLBA202509280009][吴大为]: 91 民办非企业单位
           AND K.LOAN_NUM IS NOT NULL
            --  AND K.AGREI_P_FLG = 'Y'
              THEN
          '02' -- 普惠型涉农小微企业法人贷款
         ELSE
          '00'
       END, -- 46 普惠型涉农贷款标识（大类）
       CASE
         WHEN V.FACILITY_AMT <= 5000000 AND
              (T.ACCT_TYP LIKE '0102%' -- 个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) -- 个体工商户贸易融资 
              AND T.ACCT_TYP NOT LIKE '90%' -- 不含委托贷款  
              AND T.CANCEL_FLG <> 'Y' AND SUBSTR(K.SNDKFL,1,5) IN ('P_101', 'P_102', 'P_103') AND 
              T.CONTRACT_FARMER_TYPE = 'A' -- 承包方农户类型    
          THEN
          '01' --  家庭农场贷款
         WHEN V.FACILITY_AMT <= 5000000 
          AND T.OPERATE_CUST_TYPE IN ('A', '3', 'B') 
          AND SUBSTR(K.SNDKFL,1,5) IN ('P_101', 'P_102', 'P_103')
          AND  (T.ACCT_TYP LIKE '0102%' -- 个人经营性标识   -- 按照大类条件范围判断
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) -- 个体工商户贸易融资 
              AND T.ACCT_TYP NOT LIKE '90%' -- 不含委托贷款   
              AND T.CANCEL_FLG <> 'Y' 
          THEN
          '02' -- 普惠型农户个体工商户和农户小微企业主贷款
         WHEN V.FACILITY_AMT <= 5000000 
              AND K.LOAN_NUM IS NOT NULL 
              AND SUBSTR(K.SNDKFL,1,5) IN ('P_101', 'P_102', 'P_103')
              AND N.POV_RE_LOAN_TYPE = 'A01'  -- 按照1104建档立卡贫困户范围判断
              AND (T.ACCT_TYP LIKE '0102%' -- 个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) -- 个体工商户贸易融资  ZHOUJINGKUN 20210412
              AND T.CANCEL_FLG <> 'Y' AND T.ACCT_TYP NOT LIKE '90%' -- 不含委托贷款 
          THEN
          '03' -- 建档立卡贫困户经营性贷款
         WHEN V.FACILITY_AMT <= 10000000 
          AND T.CORP_SCALE IN ('S', 'T')   -- 按照大类条件范围判断
          AND K.RUR_COLL_ECO_ORG_LOAN_FLG = 'Y' THEN
          '04' -- 普惠型农村集体经济组织贷款
         WHEN V.FACILITY_AMT <= 10000000 
          AND T.CORP_SCALE IN ('S', 'T')   -- 按照大类条件范围判断
          AND K.COOP_LAON_FLAG = 'Y'
         THEN
          '05' -- 普惠型农民专业合作社贷款
         ELSE
          '00'
       END, -- 47 普惠型涉农贷款标识（中类）
       
       CASE
         WHEN (T.ACCT_TYP LIKE '0102%' -- 个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) -- 个体工商户贸易融资 
              AND datediff(
                     to_date(from_unixtime(unix_timestamp(T.MATURITY_DT,'yyyyMMdd'))),
                     to_date(from_unixtime(unix_timestamp(T.DRAWDOWN_DT,'yyyyMMdd')))
                 ) <= 1080
             AND V.FACILITY_AMT <= 5000000
             AND T.GUARANTY_TYP = 'D'
             AND T.CANCEL_FLG <> 'Y'
             AND T.ACCT_TYP NOT LIKE '90%'
            THEN
          '01' -- 扶贫小额信贷
         ELSE
          '00'
       END,
       CASE
         WHEN V.FACILITY_AMT <= 100000 AND substr(T.ACCT_TYP,1,4) = '0104' THEN '01'
         WHEN V.FACILITY_AMT <= 100000
              AND substr(T.ACCT_TYP,1,4) = '0103'
              AND T.ACCT_TYP NOT LIKE '010301%'
              AND (T.LOAN_PURPOSE_CD IS NULL OR T.LOAN_PURPOSE_CD NOT LIKE 'K%')
          THEN '03'  -- 普惠型农户消费贷款
         WHEN V.FACILITY_AMT <= 100000 AND PHXQTGRJYXDK<> '是' AND  T.LOW_INSURANCE_FLG = 'Y' THEN
          '04' -- 低保户消费贷款
         ELSE
          '00'
       END, -- 49 普惠型消费贷款标识（大类）
       CASE
         WHEN V.FACILITY_AMT <= 100000 
              AND substr(T.ACCT_TYP,1,4)= '0102'
              AND (T.LOAN_PURPOSE_CD IS NULL OR T.LOAN_PURPOSE_CD NOT LIKE 'K%') -- 消费贷款不含房地产贷款和汽车贷款
              AND substr(T.ITEM_CD, 1, 4) IN ('1305', '1303') -- 1305贸易融资  1303贷款
              AND T.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') -- 贷款五级分类
              AND T.ACCT_TYP NOT IN ('010301''010101') THEN
          '04'  -- 建档立卡贫困户消费贷款
         ELSE
          '00'
       END, -- 50 普惠型消费贷款标识（小类） 没有业务
       CASE
         WHEN T.UNDERTAK_GUAR_TYPE IN ('A', 'B', 'Z') THEN
          '1'
         ELSE
          '0'
       END, -- 51 创业担保贷款标识 
       
       DECODE(T.RENEW_FLG, 'Y', '1', 'N', '0', '0'), -- 52 无还本续贷贷款标识   20250116
       '1', -- 53 具备提前还款权标识
       '00', -- 54 投贷联动业务标识
       '00', -- 55 '投贷联动业务——联动方式标识'
       '00', -- 56 '投贷联动业务——企业成长阶段标识'
       '00', -- 57 '投贷联动业务——企业上市标识'
       '00', -- 58 '投贷联动业务——不良贷款处置方式标识'
       CASE
         WHEN T.REPAY_TYP = '1' THEN
          '01' -- 按月结息
         WHEN T.REPAY_TYP = '2' THEN
          '02' -- 按季结息
         WHEN T.REPAY_TYP = '3' THEN
          '03' -- 按半年结息
         WHEN T.REPAY_TYP = '4' THEN
          '04' -- 按年结息
         WHEN T.REPAY_TYP = '5' THEN
          '07' -- 利随本清
         ELSE
          '00'
       END, -- 59 计息方式 缺失 不定期结息 不记利息
       CASE
         WHEN T.FLOAT_TYPE = 'A' THEN
          '02' -- 以LPR为定价基础
         WHEN T.FLOAT_TYPE = 'B' THEN
          '01' -- 以人民银行基准利率为定价基础    
         WHEN T.FLOAT_TYPE = 'C' THEN
          '03' -- 其他
         ELSE
          '03'
       END, --  60 贷款利率定价基础
       L.FLOAT_BASIS_POINTS , -- 61 利率浮动 JLBA202409120001 20241128 新增字段 原T.RATE_FLOAT * 100
       T.FXLL, -- 62 罚息利率
       T.REGION_CD, -- 63 贷款投向地区  
       T.CZCS, -- 64 债务重组次数
       nvl(substr(T.INDUST_RSTRUCT_FLG,1,3),'0'), -- 65 重点产业标识 缺失工业转型升级标识
       '01', -- 66 是否为“调整后存贷比口径”的调整项  20250311
       CASE
         WHEN T.REPAY_FLG = 'Y' THEN T.LOAN_NUM_OLD
         ELSE NULL 
       END, -- 67 上笔信贷借据号
       CASE WHEN T.ITEM_CD NOT LIKE '130302%' THEN CASE WHEN LN.LOAN_NUM IS NOT NULL THEN LN.BZ ELSE NULL END
       WHEN LN.LOAN_NUM IS NOT NULL THEN LN.BZ 
       WHEN NVL(T.DRAWDOWN_DT, '99991231') < '20121119' THEN '历史遗留'    -- 同步EAST逻辑 0619_LHY
       ELSE NULL  END, -- 68 备注
       date_format(P_DATE,'yyyy-MM-dd'),
       date_format(P_DATE,'yyyy-MM-dd'),
       T.ORG_NUM,
       T.DIS_DEPT,
       CASE
         WHEN E.LOAN_NUM IS NOT NULL THEN
                CASE
                    WHEN L.CP_ID IN ('GA011000300017','GA011000300016') THEN '0501' -- 经营性物业贷款
                    WHEN L.CP_ID = 'DK001001300001' THEN '0502'  -- 房地产并购贷款
                    WHEN E.PROPERTYLOAN_TYP IN ('102','1021','1022','1023','1024','1026') THEN '0102'  -- 其他保障性安居工程贷款（地产）
                    WHEN E.PROPERTYLOAN_TYP = '1025' THEN '0101'  -- 棚户区改造贷款（地产）
                    WHEN E.PROPERTYLOAN_TYP IN ('1111','1112','1113','1114','1116' ) THEN '0202'  -- 棚户区改造贷款（地产）
                    WHEN E.PROPERTYLOAN_TYP = '103' THEN '0103'   -- 其他地产开发贷款
                    WHEN E.PROPERTYLOAN_TYP = '113' THEN '0203'   -- 其他住房开发贷款  [20250820][巴启威]：更正码值映射
                    WHEN E.PROPERTYLOAN_TYP = '114' THEN '0204'   -- 商业用房开发贷款
                    WHEN E.PROPERTYLOAN_TYP = '119' THEN '0205'   -- 其他房产开发贷款
                    WHEN E.PROPERTYLOAN_TYP IN ('2011','2021','2031' ) THEN '0301'  -- 商业用房购房贷款
                    WHEN E.PROPERTYLOAN_TYP IN ('203','2032','2033','2034','203401','2035','203501','2036' ) THEN '0401'  -- 商业用房购房贷款
                    ELSE '0503'
                END
            ELSE NULL
       END, -- '房地产贷款类别',
       E.HOUSE_RENT_TYP , -- '住房租赁贷款类别',
       '0',   -- '地方政府专项债券配套融资标识',
       CASE WHEN T4.CONTRACT_NUM IS NOT NULL THEN '1'
       ELSE '0' 
       END AS XXDZYBS,-- '新型抵质押标识',
       T4.COLL_MK_VAL_SUM ,-- '新型抵质押物价值',
        CASE WHEN T3.CONTRACT_NUM IS NOT NULL THEN T.NON_COMPENSE_BAL_RMB
        ELSE NULL 
        END -- '融资担保机构尚未履行代偿责任金额'
  FROM T_6_27_TMP T
         LEFT JOIN SMTMODS.L_ACCT_LOAN_REALESTATE E -- 房地产贷款补充信息
             ON T.LOAN_NUM = E.LOAN_NUM
            AND E.DATA_DATE = I_DATE
         LEFT JOIN GUARANTEE_RELATION G
             ON T.ACCT_NUM = G.CONTRACT_NUM
         LEFT JOIN SMTMODS.L_AGRE_LOAN_SYNDICATEDLOAN J -- 银团贷款补充信息表
             ON T.ACCT_NUM = J.CONTRACT_NUM
            AND J.DATA_DATE = I_DATE
         LEFT JOIN ACCT_LOAN_FARMING_FULL K  --   涉农贷款补充信息 20241128
             ON T.LOAN_NUM = K.LOAN_NUM
         LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT L -- 贷款合同信息表
             ON T.ACCT_NUM = L.CONTRACT_NUM
            AND L.DATA_DATE = I_DATE 
         LEFT JOIN LOAN_BAD_INFO LN     -- 新增码值表  0617 LHY
        ON T.LOAN_NUM = LN.LOAN_NUM  
  LEFT JOIN SMTMODS.L_ACCT_POVERTY_RELIF N -- 精准扶贫补充信息表
    ON T.LOAN_NUM = N.LOAN_NUM
   AND N.DATA_DATE = I_DATE
  -- LEFT JOIN OTDS_DATA.T_6_27 O
  --  ON T.LOAN_NUM = O.F270001
  -- AND O.F270069 = TO_CHAR(P_DATE - 1, 'YYYY-MM-DD') 20250311
  LEFT JOIN SDH_BS_TMP P
    ON T.LOAN_NUM = P.LOAN_NUM
  LEFT JOIN (SELECT DISTINCT  ACCT_NUM FROM SMTMODS.L_ACCT_PROJECT
                WHERE DATA_DATE = I_DATE) Q -- 项目贷款信息表
    ON T.ACCT_NUM = Q.ACCT_NUM  
  LEFT JOIN V_PUB_IDX_DK_PHJRDK T1 -- PUJR_6_27 T1       -- V_PUB_IDX_DK_PHJRDK
    ON T.PH_LOAN_NUM = T1.LOAN_NUM --  [20250708] [姜俐锋] [JLBA202504160004][吴大为]  修改授信后需要修改关联 新增字段
   AND T1.DATA_DATE = I_DATE
  LEFT JOIN  YBT_DATACORE.AGRE_CREDITLINE_INFO V
    ON T.CUST_ID = V.CUST_ID
   AND V.DATA_DATE = I_DATE
   LEFT JOIN EAST_HKZH BB     -- 一表通转EAST 20240701 LMH
     ON T.CUST_ID = BB.FHZH
   LEFT JOIN G5305_GUAR_TEMP1 T3
     ON T3.CONTRACT_NUM = T.ACCT_NUM
   LEFT JOIN  S6301_DATA_COLLECT_GUARANTEE T4
     ON T4.CONTRACT_NUM = T.ACCT_NUM
   LEFT JOIN M_DICT_CODETABLE T5              
     ON T5.L_CODE = T.GREEN_LOAN_TYPE
    AND T5.L_CODE_TABLE_CODE = 'C0098' 
   LEFT JOIN (SELECT T.CUST_ID,
                     T.ECIF_CUST_ID,
                     ROW_NUMBER() OVER(PARTITION BY T.CUST_ID ORDER BY T.ECIF_CUST_ID DESC) AS RN
                     FROM  SMTMODS.L_CUST_BILL_TY T 
               WHERE T.DATA_DATE=I_DATE) T6  -- JLBA202411070004 20241212 取一条         
     ON T.CUST_ID = T6.CUST_ID
    AND t6.rn = 1 
    -- --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
   left join smtmods.l_cust_c c1
      on t.CUST_ID =c1.CUST_ID
      and c1.DATA_DATE = i_date
   LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM smtmods.S7001_CUST_TEMP
                    where CUST_TYPE like '%创新型企业%'
                    GROUP BY TRIM(CUST_NAME)) P5
          ON replace(replace(TRIM(P5.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(c1.CUST_NAM), '(', '（'), ')', '）')
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM smtmods.S7001_CUST_TEMP
                    where CUST_TYPE like '%国家企业技术中心%'
                    GROUP BY TRIM(CUST_NAME)) P6
          ON replace(replace(TRIM(P6.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(c1.CUST_NAM), '(', '（'), ')', '）') 
    WHERE T.DATA_DATE = I_DATE
     -- AND ( L.ACCT_TYP NOT LIKE '90%' OR  L.ACCT_TYP IS NULL )

 /*   AND (L.ACCT_STS <> '2' OR
        L.CONTRACT_EXP_DT >= I_DATE  OR 
        (L.ACCT_STS = '1' AND L.CONTRACT_EXP_DT IS NULL AND L.CONTRACT_ORIG_MATURITY_DT >= I_DATE ))*/ ; -- 修改校验20241015;

                    
 COMMIT; 
	 
	CALL PROC_ETL_JOB_LOG(P_DATE, P_PROC_NAME, P_STATUS, P_START_DT, current_timestamp, P_SQLCDE, P_STATE, P_SQLMSG, P_STEP_NO, P_DESCB);		

    #4.过程结束执行
	SET P_START_DT = current_timestamp;
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '过程结束执行';
	CALL PROC_ETL_JOB_LOG(P_DATE, P_PROC_NAME, P_STATUS, P_START_DT, current_timestamp, P_SQLCDE, P_STATE, P_SQLMSG, P_STEP_NO, P_DESCB);
    SET OI_RETCODE = P_STATUS; 
    SET OI_REMESSAGE = P_DESCB;
    SELECT OI_RETCODE,'|',OI_REMESSAGE; 
 END;

