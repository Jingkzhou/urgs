DROP Procedure IF EXISTS `PROC_BSP_T_8_4_XYKZHZT` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_8_4_XYKZHZT"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN

  /******
      程序名称  ：信用卡账户状态
      程序功能  ：加工信用卡账户状态
      目标表：T_8_4
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
 /* 需求编号：JLBA202502200003 上线日期：20250415，修改人：姜俐锋，提出人：李逊昂,吴大为 
                     修改原因：  去掉信用卡核销数据*/
/* 需求编号：JLBA202502210009 上线日期：20250415，修改人：姜俐锋，提出人：吴大为 */
/* 需求编号：JLBA202504060003 上线日期：20250513，修改人：狄家卉，提出人：吴大为    关于一表通监管数据报送系统、EAST报送系统修改取数逻辑的需求*/
/* 需求编号：JLBA202507090010 上线日期：20250807，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
 #声明变量
  DECLARE P_DATE   		DATE;			#数据日期
  DECLARE A_DATE   		VARCHAR(10);    #数据日期
  DECLARE P_PROC_NAME  	VARCHAR(200);	#存储过程名称
  DECLARE P_STATUS  	INT;  			#执行状态
  DECLARE P_START_DT  	DATETIME;		#日志开始日期
  DECLARE P_END_TIME  	DATETIME;		#日志结束日期
  DECLARE P_SQLCDE		VARCHAR(200);	#日志错误代码
  DECLARE P_STATE  		VARCHAR(200);	#日志状态代码
  DECLARE P_SQLMSG		VARCHAR(2000);	#日志详细信息
  DECLARE P_STEP_NO   	INT;			#日志执行步骤
  DECLARE P_DESCB  		VARCHAR(200);	#日志执行步骤描述
  DECLARE BEG_MON_DT 	VARCHAR(8);		#月初
  DECLARE BEG_QUAR_DT 	VARCHAR(8);		#季初
  DECLARE BEG_YEAR_DT 	VARCHAR(8);		#年初
  DECLARE LAST_MON_DT  	VARCHAR(8);		#上月末
  DECLARE LAST_QUAR_DT  VARCHAR(8);		#上季末
  DECLARE LAST_YEAR_DT  VARCHAR(8);		#上年末
  DECLARE LAST_DT  		VARCHAR(8);		#上日
  DECLARE FINISH_FLG    VARCHAR(8);		#完成标志  
  #声明异常
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
   GET DIAGNOSTICS CONDITION 1 P_SQLCDE = GBASE_ERRNO,P_SQLMSG = MESSAGE_TEXT,P_STATE = RETURNED_SQLSTATE;
   SET P_STATUS = -1;
   SET P_START_DT = NOW();
   SET P_STEP_NO = P_STEP_NO + 1;
   SET P_DESCB = '程序异常';
   CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
   SET OI_RETCODE = P_STATUS; 
   SET OI_REMESSAGE = P_DESCB || ':' || P_SQLCDE || ' - ' || P_SQLMSG;
   select OI_RETCODE,'|',OI_REMESSAGE;         
  END;
  
    #变量初始化
         SET P_DATE = TO_DATE(I_DATE,'YYYYMMDD');         
         SET A_DATE = SUBSTR(I_DATE,1,4) || '-' || SUBSTR(I_DATE,5,2) || '-' || SUBSTR(I_DATE,7,2);                  
         SET BEG_MON_DT = SUBSTR(I_DATE,1,6) || '01';         
         SET BEG_QUAR_DT = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY') || TRIM(TO_CHAR(QUARTER(TO_DATE(I_DATE,'YYYYMMDD')) * 3 - 2,'00')) || '01'; 
         SET BEG_YEAR_DT = SUBSTR(I_DATE,1,4) || '0101';         
    SET LAST_MON_DT = TO_CHAR(TO_DATE(BEG_MON_DT,'YYYYMMDD') - 1,'YYYYMMDD');         
    SET LAST_QUAR_DT = TO_CHAR(TO_DATE(BEG_QUAR_DT,'YYYYMMDD') - 1,'YYYYMMDD');         
    SET LAST_YEAR_DT = TO_CHAR(TO_DATE(BEG_YEAR_DT,'YYYYMMDD') - 1,'YYYYMMDD');         
         SET LAST_DT = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD') - 1,'YYYYMMDD');                            
         SET P_PROC_NAME = 'PROC_BSP_T_8_4_XYKZHZT';
         SET OI_RETCODE = 0;
         SET P_STATUS = 0;
         SET P_STEP_NO = 0;
         SET OI_RETCODE = 0;
         
    #1.过程开始执行
         SET P_START_DT = NOW();
         SET P_STEP_NO = P_STEP_NO + 1;
         SET P_DESCB = '过程开始执行';
                                     
         CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);                                                                        

    #2.清除数据
         SET P_START_DT = NOW();
         SET P_STEP_NO = P_STEP_NO + 1;
         SET P_DESCB = '清除数据';
         
         DELETE FROM T_8_4 WHERE H040036 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');                                                                                 
         CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
         SET P_START_DT = NOW();
         SET P_STEP_NO = P_STEP_NO + 1;
         SET P_DESCB = '数据插入';
         
 INSERT INTO T_8_4
 (
    H040001   , -- 01 '客户ID'
    H040003   , -- 03 '信用卡账号'
    -- H040004   , -- 04 '开户机构ID'
    H040004   , -- 04 '核算机构ID' -- alter by wjb 20240703 一表通2.0升级：修改数据项名称：开户机构ID→核算机构ID
    H040005   , -- 05 '当前本币授信额度'
    H040006   , -- 06 '当前外币授信额度'
    H040007   , -- 07 '已使用本币授信额度'
    H040008   , -- 08 '已使用外币授信额度'
    H040009   , -- 09 '免息应收账款'
    H040010   , -- 10 '应收息费'
    H040011   , -- 11 '账户余额'
    H040012   , -- 12 '逾期金额'
    H040013   , -- 13 '币种'
    H040015   , -- 15 '五级分类'
    H040016   , -- 16 '其中本币临时额度'
    H040017   , -- 17 '其中外币临时额度'
    H040018   , -- 18 '冻结金额'
    H040019   , -- 19 '当月累计交易笔数'
    H040020   , -- 20 '当月累计透支金额'
    H040021   , -- 21 '本月累计消费金额'
    H040022   , -- 22 '本月累计取现转账金额'
    H040023   , -- 23 '本月累计分期交易金额'
    H040024   , -- 24 '本月累计收入'
    H040025   , -- 25 '当年累计信用卡收入金额'
    H040026   , -- 26 '已有信用卡发卡银行数'
    H040027   , -- 27 '已有他行授信金额'
    H040028   , -- 28 '催收标识'
    H040029   , -- 29 '催收方式'
    H040030   , -- 30 '新增授信类型'
    H040031   , -- 31 '逾期起始日期'
    H040032   , -- 32 '最近授信评估日期'
    H040033   , -- 33 '最近征信查询日期'
    H040034   , -- 34 '最近新增授信日期'
    H040035   , -- 35 '最后交易日期'
    H040037   , -- 37 '账户状态'
    H040038   , -- 38 '透支金额'   
    H040036   , -- 36 '采集日期'
    DIS_DATA_DATE , -- 装入数据日期
    DIS_BANK_ID   , -- 机构号
    DIS_DEPT      ,
    DEPARTMENT_ID , -- 业务条线
    H040039       , -- 分期余额
    H040040         -- 溢缴款余额
    
  )
    SELECT 
          T.CUST_ID                           , -- 01 '客户ID'
          T.ACCT_NUM                          , -- 03 '信用卡账号'
          'B0302H22201009803'                 , -- 04 '核算机构ID'
          T.QUANTUM_CNY                       , -- 05 '当前本币授信额度'
          nvl(T.QUANTUM_FCY ,0)                      , -- 06 '当前外币授信额度'
          -- T.QUANTUM_CNY - T.CREDIT_BAL_CNY    , -- 07 '已使用本币授信额度'
          -- T.QUANTUM_FCY - T.CREDIT_BAL_FCY    , -- 08 '已使用外币授信额度'
          -- T.QUANTUM_FCY - T.CREDIT_BAL_CNY*R.CCY_RATE , -- 08 '已使用外币授信额度' -- 经李逊昂确认，用   本币授信余额*汇率  作为外币授信余额
          T.M0+T.M1+T.M2+T.M3+T.M4+T.M5+T.M6+T.M6_UP    , -- 07 '已使用本币授信额度' 坤哥最新口径
          0                                   , -- 08 '已使用外币授信额度' 坤哥最新口径，外币默认0
          T.MXYSZK                            , -- 09 '免息应收账款' -- 李逊昂：改回来取这个
          -- T.M0                                , -- 09 '免息应收账款' ALTER BY WJB 20240624 一表通2.0升级 
          T.INTAMT                            , -- 10 '应收息费'
          CASE WHEN NVL(C.ACCT_BALANCE,0) > 0 THEN -C.ACCT_BALANCE
          ELSE NVL(T.M0,0)+NVL(T.M1,0)+NVL(T.M2,0)+NVL(T.M3,0)+NVL(T.M4,0)+NVL(T.M5,0)+NVL(T.M6,0)+NVL(T.M6_UP,0)
          +NVL(T.INTAMT,0)+NVL(T.I_OD_AMT,0)+NVL(T.O_OD_AMT,0)+NVL(T.FY,0)
          END                                 , -- 11 '账户余额' -- M0到M6+的和+利息+欠息金额+表外欠息+费用-溢缴款 0408修改逻辑
          CASE WHEN (T.P_OD_DATE IS NULL OR T.P_OD_DATE ='99991231') THEN 0
          ELSE NVL(T.M0,0)+NVL(T.M1,0)+NVL(T.M2,0)+NVL(T.M3,0)+NVL(T.M4,0)+NVL(T.M5,0)+NVL(T.M6,0)+NVL(T.M6_UP,0)
          END AS YQJE, -- 12 '逾期金额'  -- 20250116  -- [2023-03-21] [JLF] [邮件修改][吴大为]8.4信用卡逾期金额加M0;  
         T.CURR_CD                           , -- 13 '币种'
          CASE WHEN LXQKQS >=7 THEN '05'
               WHEN LXQKQS BETWEEN 5 AND 6 THEN '04'
               WHEN LXQKQS =4  THEN '03'
               WHEN LXQKQS BETWEEN 1 AND 3  THEN '02'
               ELSE '01' 
               END  AS WJFL                   , -- 15 '五级分类'
          GREATEST( T.BBLSED , 0 )            , -- 16 '其中本币临时额度' 20250116
          T.WBLSED                            , -- 17 '其中外币临时额度'
          T.FREEZE_BALANCE                    , -- 18 '冻结金额'
          NVL(T.DYLJJYBS,0)                          , -- 19 '当月累计交易笔数'
         -- NVL(T.DYLJTZJE,0)                          , -- 20 '当月累计透支金额'
          CASE WHEN NVL(T.LJXFJE,0) + NVL(T.LJQXZZJE,0) + NVL(D.INSTALLMENT_TOTALLYAMT,0) < 0 THEN 0
               ELSE NVL(T.LJXFJE,0) + NVL(T.LJQXZZJE,0) + NVL(D.INSTALLMENT_TOTALLYAMT,0) END AS H040020, -- 20 '当月累计透支金额'  -- [20250415][姜俐锋][JLBA202502210009][吴大为]: 剔除冲账为上月的交易。
          CASE WHEN NVL(T.LJXFJE,0) < 0 THEN 0  ELSE NVL(T.LJXFJE,0) END AS H040021 , -- 21 '本月累计消费金额'  -- [20250415][姜俐锋][JLBA202502210009][吴大为]: 剔除冲账为上月的交易。
          NVL(T.LJQXZZJE,0)                   , -- 22 '本月累计取现转账金额'
          -- T.LJFQJYJE                          , -- 23 '本月累计分期交易金额'
          NVL(D.INSTALLMENT_TOTALLYAMT,0)     , -- 23 '本月累计分期交易金额'
          CASE WHEN NVL(T.LJSR,0) <0
              THEN 0
              ELSE
              NVL(T.LJSR,0)  
          END                                 , -- 24 '本月累计收入' -- [20250513][狄家卉][JLBA202504060003][吴大为]: 如果为负数，则取0
          NVL(T.LJXYKSR,0)                    , -- 25 '当年累计信用卡收入金额'
          -- NVL(B.LAST_PBOC_OTHER_CARD_NUM,0)       , -- 26 '已有信用卡发卡银行数'
          NVL(B.LAST_PBOC_OTHER_CARD_NUM ,0)          , -- 26 '已有信用卡发卡银行数' 20240627修改,和east保持一致 口径来自李逊昂
          -- NVL(B.LAST_PBOC_OTHER_INS_AMT,0)     , -- 27 '已有他行授信金额'
          NVL(B.LAST_PBOC_OTHER_INS_AMT,0)           , -- 27 '已有他行授信金额'  20240627修改,和east保持一致 口径来自李逊昂
          -- T.COLLECTION_FLG                    , -- 28 '催收标识'
          CASE WHEN T.COLLECTION_FLG = 'Y' THEN '1'
          ELSE 0 END                          , -- 28 '催收标识' -- 20240628修改 按照银数提供的逻辑修改
          T.COLLECTION_TYPE                   , -- 29 '催收方式'
          -- B.NEW_INCREADE_CREDIT_TYPE_DESC     , -- 30 '新增授信类型'
          -- T.NEW_INCREADE_CREDIT_TYPE_DESC     , -- 30 '新增授信类型'
          CASE WHEN T.NEW_INCREADE_CREDIT_TYPE_DESC = '04' THEN '00'
          ELSE T.NEW_INCREADE_CREDIT_TYPE_DESC END , -- 30 '新增授信类型' -- ybt2.0升级修改          
          TO_CHAR(TO_DATE(T.P_OD_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 31 '逾期起始日期'
          -- TO_CHAR(TO_DATE(T.LATE_CREDIT_ASSESS_DATE,'YYYYMMDD'),'YYYY-MM-DD') 
          CASE WHEN T.LATE_CREDIT_ASSESS_DATE >I_DATE THEN  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')
          ELSE TO_CHAR(TO_DATE(T.LATE_CREDIT_ASSESS_DATE,'YYYYMMDD'),'YYYY-MM-DD')
          END AS  H040032, -- 32 '最近授信评估日期'  -- 20241231修改 新增字段
          /*TO_CHAR(TO_DATE(NVL(B.NEW_INCREADE_CREDIT_DATE,'99991231'),'YYYYMMDD'),'YYYY-MM-DD') , -- 33 '最近征信查询日期'  -- 新增字段*/
          TO_CHAR(TO_DATE(NVL(B.LAST_PBOC_INQUIRY_DATE,'99991231'),'YYYYMMDD'),'YYYY-MM-DD') , -- 33 '最近征信查询日期'  -- 新增字段 20240627修改
          CASE WHEN T.NEW_INCREADE_CREDIT_DATE >I_DATE THEN  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')
          ELSE TO_CHAR(TO_DATE(T.NEW_INCREADE_CREDIT_DATE,'YYYYMMDD'),'YYYY-MM-DD')
          END AS  H040034, -- 34 '最近新增授信日期'  -- 20241231修改 新增字段
          CASE WHEN T.ZHJYRQ > I_DATE THEN
            TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')
          ELSE
            TO_CHAR(TO_DATE(T.ZHJYRQ,'YYYYMMDD'),'YYYY-MM-DD')
          END                                  , -- 35 '最后交易日期'  -- 新增字段
          CASE 
            WHEN T.ACCOUNTSTAT IN ('Q','WQ') THEN '03' -- 销户
            WHEN T.ACCOUNTSTAT IN ('D','B')  THEN '04' -- 冻结
            WHEN T.ACCOUNTSTAT IN ('H')      THEN '05' -- 止付
            WHEN T.ACCOUNTSTAT IS NULL       THEN '01' -- 正常
            ELSE '06' -- 其他  -- 映射不上给其他  -- 以上逻辑来着业务老师李逊昂
          END                                    , -- 37 '账户状态'
           -- T.TZJE                              , -- 38 '透支金额'  -- 新增字段
          T.M0+T.M1+T.M2+T.M3+T.M4+T.M5+T.M6+T.M6_UP      , -- 38 '透支金额'  坤哥最新口径
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 36 '采集日期'
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
                    '009803'                                        , -- 机构号
                    null,
                    '009803',                                         -- 业务条线   信用卡中心
                    D1.INSTAL_BAL,                                    -- 分期余额  ALTER BY WJB 20240624 一表通2.0升级 取分期余额
                    C1.ACCT_BALANCE                                   -- 溢缴款余额
      FROM SMTMODS.L_ACCT_CARD_CREDIT T -- 信用卡账户信息表
      LEFT JOIN SMTMODS.L_AGRE_CARD_CREDIT A -- 信用卡补充信息表
        ON T.CARD_NO = A.CARD_NO
       AND A.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_AGRE_CARD_CREDITLINE B -- 信用卡授信额度补充信息表
        ON T.CUST_ID=B.CUST_ID
       AND B.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_ACCT_DEPOSIT C -- 存款账户信息表  -- 信用卡溢缴款现在是一个汇总账户，关联不上
        ON T.ACCT_NUM=C.ACCT_NUM
       AND C.DATA_DATE = I_DATE
      LEFT JOIN (select ACCT_NUM,SUM(INSTALLMENT_TOTALLYAMT) INSTALLMENT_TOTALLYAMT from SMTMODS.L_TRAN_CARDINSTALLMENT_CREDIT 
                     where DATA_DATE = I_DATE AND SUBSTR(INSTALLMENT_DATE,1,6) = SUBSTR(I_DATE,1,6)
                     group by ACCT_NUM
                   ) D -- 信用卡分期明细表
        ON T.ACCT_NUM=D.ACCT_NUM 
      LEFT JOIN (select ACCT_NUM,SUM(INSTAL_BAL) INSTAL_BAL from SMTMODS.L_TRAN_CARDINSTALLMENT_CREDIT 
                     where DATA_DATE = I_DATE AND SUBSTR(INSTALLMENT_DATE,1,6) = SUBSTR(I_DATE,1,6)
                     group by ACCT_NUM
                   ) D1 -- 信用卡分期明细表  ALTER BY WJB 20240624 一表通2.0升级 取分期余额
        ON T.ACCT_NUM=D1.ACCT_NUM   
      LEFT JOIN SMTMODS.L_PUBL_RATE R -- 汇率表
        ON R.DATA_DATE = T.DATA_DATE
       AND R.BASIC_CCY = 'CNY'
       AND R.FORWARD_CCY = T.CURR_CD
      LEFT JOIN SMTMODS.L_ACCT_DEPOSIT C1 -- 存款账户信息表  限制科目= '20110111' 取信用卡溢缴款   20240706 WJB 2.0升级修改
        ON T.ACCT_NUM=C1.ACCT_NUM
       AND C1.DATA_DATE = I_DATE
       AND C1.GL_ITEM_CODE='20110111' -- 个人信用卡存款 
     WHERE T.DATA_DATE = I_DATE
    -- add by haorui 20241119 JLBA202410090008信用卡收益权转让  start
       AND (T.DEALDATE = I_DATE OR T.DEALDATE ='00000000')   
	   	-- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
       AND (nvl(T.ACCOUNTSTAT,0) <> 'C' OR (T.ACCOUNTSTAT = 'C' AND T.ACCT_CLDATE >= SUBSTR(I_DATE,1,4)||'0101' ))  -- [20250415][姜俐锋][JLBA202502210009][吴大为]: 账户状态为销户的只取当日销户的	   
       AND (T.EDSQRQ <= I_DATE OR T.EDSQRQ IS NULL ) -- YBT_JYF09-93 20250428 同步8.13[吴大为]: 合同起始日大于采集日期，去掉，不取数了
       AND NOT EXISTS (SELECT 1 FROM SMTMODS.L_ACCT_WRITE_OFF W WHERE W.DATA_DATE = I_DATE AND W.DATE_SOURCESD ='信用卡核销'AND W.WRITE_OFF_DATE <> I_DATE AND T.ACCT_NUM=W.ACCT_NUM) --  -- [20250415][姜俐锋][JLBA202502200003][李逊昂,吴大为]: 去掉核销部分  
    UNION ALL 
                  SELECT 
          T.CUST_ID                           , -- 01 '客户ID'
          T.ACCT_NUM                          , -- 03 '信用卡账号'
          'B0302H22201009803'                 , -- 04 '核算机构ID'
          T.QUANTUM_CNY                       , -- 05 '当前本币授信额度'
          nvl(T.QUANTUM_FCY ,0)               , -- 06 '当前外币授信额度'
          -- T.QUANTUM_CNY - T.CREDIT_BAL_CNY    , -- 07 '已使用本币授信额度'
          -- T.QUANTUM_FCY - T.CREDIT_BAL_FCY    , -- 08 '已使用外币授信额度'
          -- T.QUANTUM_FCY - T.CREDIT_BAL_CNY*R.CCY_RATE , -- 08 '已使用外币授信额度' -- 经李逊昂确认，用   本币授信余额*汇率  作为外币授信余额
          T.M0+T.M1+T.M2+T.M3+T.M4+T.M5+T.M6+T.M6_UP    , -- 07 '已使用本币授信额度' 坤哥最新口径
          0                                   , -- 08 '已使用外币授信额度' 坤哥最新口径，外币默认0
          T.MXYSZK                           , -- 09 '免息应收账款' -- 李逊昂：改回来取这个
          -- T.M0                                , -- 09 '免息应收账款' ALTER BY WJB 20240624 一表通2.0升级 
          T.INTAMT                            , -- 10 '应收息费'
          CASE WHEN NVL(C.ACCT_BALANCE,0) > 0 THEN -C.ACCT_BALANCE
          ELSE NVL(T.M0,0)+NVL(T.M1,0)+NVL(T.M2,0)+NVL(T.M3,0)+NVL(T.M4,0)+NVL(T.M5,0)+NVL(T.M6,0)+NVL(T.M6_UP,0)
          +NVL(T.INTAMT,0)+NVL(T.I_OD_AMT,0)+NVL(T.O_OD_AMT,0)+NVL(T.FY,0)
          END                                 , -- 11 '账户余额' -- M0到M6+的和+利息+欠息金额+表外欠息+费用-溢缴款 0408修改逻辑
          CASE WHEN (T.P_OD_DATE IS NULL OR T.P_OD_DATE ='99991231') THEN 0
          ELSE NVL(T.M1,0)+ NVL(T.M1,0)+NVL(T.M2,0)+NVL(T.M3,0)+NVL(T.M4,0)+NVL(T.M5,0)+NVL(T.M6,0)+NVL(T.M6_UP,0)
          END AS YQJE, -- 12 '逾期金额'  -- 20250116 -- [2023-03-21] [JLF] [邮件修改][吴大为]8.4信用卡逾期金额加M0;  
          -- NVL(T.M1,0)+NVL(T.M2,0)+NVL(T.M3,0)+NVL(T.M4,0)+NVL(T.M5,0)+NVL(T.M6,0)+NVL(T.M6_UP,0), -- 12 '逾期金额'
          T.CURR_CD                           , -- 13 '币种'
          CASE WHEN LXQKQS >=7 THEN '05'
               WHEN LXQKQS BETWEEN 5 AND 6 THEN '04'
               WHEN LXQKQS =4  THEN '03'
               WHEN LXQKQS BETWEEN 1 AND 3  THEN '02'
               ELSE '01' 
               END  AS WJFL                   , -- 15 '五级分类'
          GREATEST( T.BBLSED , 0 )            , -- 16 '其中本币临时额度' 20250116 
          T.WBLSED                            , -- 17 '其中外币临时额度'
          T.FREEZE_BALANCE                    , -- 18 '冻结金额'
          NVL(T.DYLJJYBS,0)                          , -- 19 '当月累计交易笔数'
         -- NVL(T.DYLJTZJE,0)                          , -- 20 '当月累计透支金额'
          CASE WHEN NVL(T.LJXFJE,0) + NVL(T.LJQXZZJE,0) + NVL(D.INSTALLMENT_TOTALLYAMT,0)  < 0 THEN 0
               ELSE NVL(T.LJXFJE,0) + NVL(T.LJQXZZJE,0) + NVL(D.INSTALLMENT_TOTALLYAMT,0)  END  AS H040020, -- 20 '当月累计透支金额'  -- [20250415][姜俐锋][JLBA202502210009][吴大为]: 剔除冲账为上月的交易。
          CASE WHEN NVL(T.LJXFJE,0) < 0 THEN 0 ELSE   NVL(T.LJXFJE,0) END AS H040021 , -- 21 '本月累计消费金额'  -- [20250415][姜俐锋][JLBA202502210009][吴大为]: 剔除冲账为上月的交易。
          NVL(T.LJQXZZJE,0)                   , -- 22 '本月累计取现转账金额'
          -- T.LJFQJYJE                          , -- 23 '本月累计分期交易金额'
          NVL(D.INSTALLMENT_TOTALLYAMT,0)     , -- 23 '本月累计分期交易金额'
          CASE WHEN NVL(T.LJSR,0) <0
              THEN 0
              ELSE
              NVL(T.LJSR,0)  
          END                                 , -- 24 '本月累计收入' -- [20250513][狄家卉][JLBA202504060003][吴大为]: 如果为负数，则取0
          NVL(T.LJXYKSR,0)                    , -- 25 '当年累计信用卡收入金额'
          -- NVL(B.LAST_PBOC_OTHER_CARD_NUM,0)       , -- 26 '已有信用卡发卡银行数'
          NVL(B.LAST_PBOC_OTHER_CARD_NUM ,0)         , -- 26 '已有信用卡发卡银行数' 20240627修改,和east保持一致 口径来自李逊昂
          -- NVL(B.LAST_PBOC_OTHER_INS_AMT,0)     , -- 27 '已有他行授信金额'
          NVL(B.LAST_PBOC_OTHER_INS_AMT ,0)          , -- 27 '已有他行授信金额'  20240627修改,和east保持一致 口径来自李逊昂
          -- T.COLLECTION_FLG                    , -- 28 '催收标识'
          CASE WHEN T.COLLECTION_FLG = 'Y' THEN '1'
          ELSE 0 END                          , -- 28 '催收标识' -- 20240628修改 按照银数提供的逻辑修改
          T.COLLECTION_TYPE                   , -- 29 '催收方式'
          -- B.NEW_INCREADE_CREDIT_TYPE_DESC     , -- 30 '新增授信类型'
          -- T.NEW_INCREADE_CREDIT_TYPE_DESC     , -- 30 '新增授信类型'
          CASE WHEN T.NEW_INCREADE_CREDIT_TYPE_DESC = '04' THEN '00'
          ELSE T.NEW_INCREADE_CREDIT_TYPE_DESC END , -- 30 '新增授信类型' -- ybt2.0升级修改          
          TO_CHAR(TO_DATE(T.P_OD_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 31 '逾期起始日期'
          TO_CHAR(TO_DATE(T.LATE_CREDIT_ASSESS_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 32 '最近授信评估日期'  -- 新增字段
          /*TO_CHAR(TO_DATE(NVL(B.NEW_INCREADE_CREDIT_DATE,'99991231'),'YYYYMMDD'),'YYYY-MM-DD') , -- 33 '最近征信查询日期'  -- 新增字段*/
          TO_CHAR(TO_DATE(NVL(B.LAST_PBOC_INQUIRY_DATE,'99991231'),'YYYYMMDD'),'YYYY-MM-DD') , -- 33 '最近征信查询日期'  -- 新增字段 20240627修改
          TO_CHAR(TO_DATE(T.NEW_INCREADE_CREDIT_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 34 '最近新增授信日期'  -- 新增字段
          CASE WHEN T.ZHJYRQ > I_DATE THEN
            TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')
          ELSE
            TO_CHAR(TO_DATE(T.ZHJYRQ,'YYYYMMDD'),'YYYY-MM-DD')
          END                                  , -- 35 '最后交易日期'  -- 新增字段
          CASE 
            WHEN T.ACCOUNTSTAT IN ('Q','WQ') THEN '03' -- 销户
            WHEN T.ACCOUNTSTAT IN ('D','B')  THEN '04' -- 冻结
            WHEN T.ACCOUNTSTAT IN ('H')      THEN '05' -- 止付
            WHEN T.ACCOUNTSTAT IS NULL       THEN '01' -- 正常
            ELSE '06' -- 其他  -- 映射不上给其他  -- 以上逻辑来着业务老师李逊昂
          END                                    , -- 37 '账户状态'
           -- T.TZJE                              , -- 38 '透支金额'  -- 新增字段
          T.M0+T.M1+T.M2+T.M3+T.M4+T.M5+T.M6+T.M6_UP      , -- 38 '透支金额'  坤哥最新口径
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 36 '采集日期'
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
                    '009803'                                        , -- 机构号
                    null,
                    '009803',                                         -- 业务条线   信用卡中心
                    D1.INSTAL_BAL,                                    -- 分期余额  ALTER BY WJB 20240624 一表通2.0升级 取分期余额
                    C1.ACCT_BALANCE                                   -- 溢缴款余额
      FROM SMTMODS.L_ACCT_CARD_CREDIT T -- 信用卡账户信息表
      LEFT JOIN SMTMODS.L_ACCT_DEPOSIT T3
        ON T.DATA_DATE = T3.DATA_DATE
       AND T.ACCT_NUM = T3.ACCT_NUM
       AND T3.GL_ITEM_CODE ='20110111'
      LEFT JOIN SMTMODS.L_ACCT_DEPOSIT T4
        ON T.ACCT_NUM = T4.ACCT_NUM
       AND T4.DATA_DATE = LAST_DT
       AND T4.GL_ITEM_CODE ='20110111'
      LEFT JOIN SMTMODS.L_AGRE_CARD_CREDIT A -- 信用卡补充信息表
        ON T.CARD_NO = A.CARD_NO
       AND A.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_AGRE_CARD_CREDITLINE B -- 信用卡授信额度补充信息表
        ON T.CUST_ID=B.CUST_ID
       AND B.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_ACCT_DEPOSIT C -- 存款账户信息表  -- 信用卡溢缴款现在是一个汇总账户，关联不上
        ON T.ACCT_NUM=C.ACCT_NUM
       AND C.DATA_DATE = I_DATE
      LEFT JOIN (select ACCT_NUM,SUM(INSTALLMENT_TOTALLYAMT) INSTALLMENT_TOTALLYAMT from SMTMODS.L_TRAN_CARDINSTALLMENT_CREDIT 
                     where DATA_DATE = I_DATE AND SUBSTR(INSTALLMENT_DATE,1,6) = SUBSTR(I_DATE,1,6)
                     group by ACCT_NUM
                   ) D -- 信用卡分期明细表
        ON T.ACCT_NUM=D.ACCT_NUM 
      LEFT JOIN (SELECT ACCT_NUM,SUM(INSTAL_BAL) INSTAL_BAL FROM SMTMODS.L_TRAN_CARDINSTALLMENT_CREDIT 
                     WHERE DATA_DATE = I_DATE AND SUBSTR(INSTALLMENT_DATE,1,6) = SUBSTR(I_DATE,1,6)
                     GROUP BY ACCT_NUM
                   ) D1 -- 信用卡分期明细表  ALTER BY WJB 20240624 一表通2.0升级 取分期余额
        ON T.ACCT_NUM=D1.ACCT_NUM   
      LEFT JOIN SMTMODS.L_PUBL_RATE R -- 汇率表
        ON R.DATA_DATE = T.DATA_DATE
       AND R.BASIC_CCY = 'CNY'
       AND R.FORWARD_CCY = T.CURR_CD
      LEFT JOIN SMTMODS.L_ACCT_DEPOSIT C1 -- 存款账户信息表  限制科目= '20110111' 取信用卡溢缴款   20240706 WJB 2.0升级修改
        ON T.ACCT_NUM=C1.ACCT_NUM
       AND C1.DATA_DATE = I_DATE
       AND C1.GL_ITEM_CODE='20110111' -- 个人信用卡存款 
     WHERE T.DATA_DATE = I_DATE
       AND T.DEALDATE <> '00000000'   
       AND (T4.ACCT_NUM IS NOT NULL OR T4.ACCT_NUM IS NULL AND T3.ACCT_NUM IS NOT NULL)  -- 前一天有溢款款 或 前一天无溢缴款当有有溢缴款
	   -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
       AND (nvl(T.ACCOUNTSTAT,0) <> 'C' OR (T.ACCOUNTSTAT = 'C' AND T.ACCT_CLDATE >= SUBSTR(I_DATE,1,4)||'0101' ))  -- [20250415][姜俐锋][JLBA202502210009][吴大为]: 账户状态为销户的只取当日销户的
       AND (T.EDSQRQ <= I_DATE OR T.EDSQRQ IS NULL ) -- YBT_JYF09-93 20250428 同步8.13[吴大为]: 合同起始日大于采集日期，去掉，不取数了
       AND NOT EXISTS (SELECT 1 FROM SMTMODS.L_ACCT_WRITE_OFF W WHERE W.DATA_DATE = I_DATE AND W.DATE_SOURCESD ='信用卡核销'AND W.WRITE_OFF_DATE <> I_DATE AND T.ACCT_NUM=W.ACCT_NUM)  -- [20250415][姜俐锋][JLBA202502200003][李逊昂,吴大为]: 去掉核销部分  
         -- add by haorui 20241119 JLBA202410090008信用卡收益权转让 end
          ;
         CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);                  

    #4.过程结束执行
         SET P_START_DT = NOW();
         SET P_STEP_NO = P_STEP_NO + 1;
         SET P_DESCB = '过程结束执行';
         CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    SET OI_RETCODE = P_STATUS; 
    SET OI_REMESSAGE = P_DESCB;
    select OI_RETCODE,'|',OI_REMESSAGE;
END $$


