DROP Procedure IF EXISTS `PROC_BSP_T_8_11_BWYWSXFJSY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_8_11_BWYWSXFJSY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回CODE
                                         OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
                                         )
BEGIN


  /******
      程序名称  ：表外业务手续费及收益
      程序功能  ：加工表外业务手续费及收益
      目标表：T_8_11
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
   -- JLBA202411180016_关于修正一表通与综合理财系统数据对接准确性的需求
    /* 需求编号：JLBA202502280013_关于一表通监管报送系统金融市场部债券承分销业务变更的需求 上线日期：20250429，修改人：姜俐锋，提出人：徐晖 */
  #声明变量
  DECLARE P_DATE    DATE; #数据日期
  DECLARE A_DATE    VARCHAR(10);    #数据日期
  DECLARE P_PROC_NAME   VARCHAR(200); #存储过程名称
  DECLARE P_STATUS   INT;   #执行状态
  DECLARE P_START_DT   DATETIME; #日志开始日期
  DECLARE P_END_TIME   DATETIME; #日志结束日期
  DECLARE P_SQLCDE VARCHAR(200); #日志错误代码
  DECLARE P_STATE   VARCHAR(200); #日志状态代码
  DECLARE P_SQLMSG VARCHAR(2000); #日志详细信息
  DECLARE P_STEP_NO    INT; #日志执行步骤
  DECLARE P_DESCB   VARCHAR(200); #日志执行步骤描述
  DECLARE BEG_MON_DT  VARCHAR(8); #月初
  DECLARE BEG_QUAR_DT  VARCHAR(8); #季初
  DECLARE BEG_YEAR_DT  VARCHAR(8); #年初
  DECLARE LAST_MON_DT   VARCHAR(8); #上月末
  DECLARE LAST_QUAR_DT  VARCHAR(8); #上季末
  DECLARE LAST_YEAR_DT  VARCHAR(8); #上年末
  DECLARE LAST_DT   VARCHAR(8); #上日
  DECLARE FINISH_FLG    VARCHAR(8); #完成标志  
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
   SELECT OI_RETCODE,'|',OI_REMESSAGE;
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
 SET P_PROC_NAME = 'PROC_BSP_T_8_11_BWYWSXFJSY';
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
 
 DELETE FROM T_8_11 WHERE H110013 = TO_CHAR(P_DATE,'YYYY-MM-DD') ;
 
 COMMIT;
    
 CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
 SET P_START_DT = NOW();
 SET P_STEP_NO = P_STEP_NO + 1;
 SET P_DESCB = '数据插入';
 
           
 INSERT INTO T_8_11
      ( H110001   , -- 01 '机构ID'
        H110002   , -- 02 '协议ID'
        H110003   , -- 03 '业务类型'
        H110004   , -- 04 '业务余额'
        H110005   , -- 05 '本年累计发生额'
        H110006   , -- 06 '产品ID'
        H110007   , -- 07 '累计实现产品收益'
        H110008   , -- 08 '累计实现银行端收益'
        H110009   , -- 09 '累计实现客户端收益'
        H110010   , -- 10 '手续费计算方式'
        H110011   , -- 11 '手续费总额'
        H110012   , -- 12 '手续费收取方式'
        H110013   , -- 13 '采集日期'
        DIS_DATA_DATE,
        DIS_BANK_ID,
        DEPARTMENT_ID
        )
        
    WITH ACCT_OBS_LOAN AS
   (SELECT * FROM 
   (
    SELECT 
    T.ACCT_NO ,
    T.ACCT_STS,
    T.CP_ID,
    T.GL_ITEM_CODE,
    T.ORG_NUM,
    T.BALANCE,
    T.TRAN_AMT,
    T.COST_AMOUNT,
    T.DEPARTMENTD,
    T.DATA_DATE,
    ROW_NUMBER() OVER(PARTITION BY T.ACCT_NO,T.CP_ID ORDER BY T.COST_AMOUNT DESC) AS RN  
    FROM SMTMODS.L_ACCT_OBS_LOAN T
    WHERE T.DATA_DATE = I_DATE
    AND T.COST_AMOUNT >  0 
    -- AND SUBSTR(T.COST_DATE,1,4) = SUBSTR(I_DATE,1,4) 
    ) J
    WHERE J.RN = 1 )




SELECT 
     SUBSTR(TRIM(T2.FIN_LIN_NUM ),1,11)||T.ORG_NUM       , -- 01 '机构ID'
     T.ACCT_NO        , -- 02 '协议ID'
     CASE 
     WHEN SUBSTR(T.GL_ITEM_CODE,1,4) = '7020' THEN '0100' -- 承兑汇票
     WHEN SUBSTR(T.GL_ITEM_CODE,1,4) = '7010' THEN '0200' -- 跟单信用证 
     WHEN T.GL_ITEM_CODE IN ('70400101', '70400103', '70400201', '70400203') THEN   '0301'   -- 融资性保函
     WHEN T.GL_ITEM_CODE IN ('70400102', '70400104', '70400202', '70400204') THEN   '0302'   -- 非融资保函
     WHEN T.GL_ITEM_CODE = '70300301' THEN '0900' -- 其他担保类业务  商票保贴
     WHEN T.GL_ITEM_CODE = '70300101' THEN '0600' -- 可随时无条件撤销的贷款承诺
     WHEN T.GL_ITEM_CODE = '70300201' THEN '0700' -- 不可无条件撤销的贷款承诺
     END  , -- 03 '业务类型'
     NVL(SUM(CASE WHEN T.ACCT_STS = '1' THEN   T.BALANCE  
     ELSE  0 
     END ),0) AS ywye, -- 04 '业务余额'
     NVL(SUM(T.TRAN_AMT),0)      , -- 05 '本年累计发生额'
     CASE WHEN T.GL_ITEM_CODE = '70300301' THEN 'CD006000200001'
         WHEN T.GL_ITEM_CODE IN ( '70300101', '70300201' ) THEN 'DN0090001'
         ELSE  T.CP_ID 
         END  AS CPID, -- 06 '产品ID'
     0          , -- 07 '累计实现产品收益'
     0          , -- 08 '累计实现银行端收益'
     0          , -- 09 '累计实现客户端收益'
     '02'       , -- 10 '手续费计算方式'
     NVL(T.COST_AMOUNT ,0), -- 11 '手续费总额'
     '01'          , -- 12 '手续费收取方式'
     TO_CHAR(P_DATE,'YYYY-MM-DD'),   -- 13 '采集日期'
     TO_CHAR(P_DATE,'YYYY-MM-DD'),   -- 13 '采集日期'
     T.ORG_NUM ,
     CASE WHEN T.DEPARTMENTD= '普惠金融' THEN '0098PH'  
          WHEN (T.DEPARTMENTD= '公司金融' OR T.DEPARTMENTD IS NULL)  THEN '0098JR' 
      END  AS DEPARTMENT_ID 
   FROM ACCT_OBS_LOAN T
   LEFT JOIN VIEW_L_PUBL_ORG_BRA T2 -- 机构表
     ON T.ORG_NUM = T2.ORG_NUM
    AND T2.DATA_DATE = T.DATA_DATE
  WHERE T.DATA_DATE = I_DATE
    
    GROUP BY  
     SUBSTR(TRIM(T2.FIN_LIN_NUM ),1,11)||T.ORG_NUM       , -- 01 '机构ID'
     T.ACCT_NO        , -- 02 '协议ID'
     T.GL_ITEM_CODE,
     CASE 
     WHEN SUBSTR(T.GL_ITEM_CODE,1,4) = '7020' THEN '0100' -- 承兑汇票
     WHEN SUBSTR(T.GL_ITEM_CODE,1,4) = '7010' THEN '0200' -- 跟单信用证 
     WHEN T.GL_ITEM_CODE IN ('70400101', '70400103', '70400201', '70400203') THEN   '0301'   -- 融资性保函
     WHEN T.GL_ITEM_CODE IN ('70400102', '70400104', '70400202', '70400204') THEN   '0302'   -- 非融资保函
     WHEN T.GL_ITEM_CODE = '70300301' THEN '0900' -- 其他担保类业务  商票保贴
     WHEN T.GL_ITEM_CODE = '70300101' THEN '0600' -- 可随时无条件撤销的贷款承诺
     WHEN T.GL_ITEM_CODE = '70300201' THEN '0700' -- 不可无条件撤销的贷款承诺
     END  , -- 03 '业务类型'
     CASE WHEN T.GL_ITEM_CODE = '70300301' THEN 'CD006000200001'
          WHEN T.GL_ITEM_CODE IN ( '70300101', '70300201' ) THEN 'DN0090001'
          ELSE  T.CP_ID 
          END , -- 06 '产品ID' 
     T.COST_AMOUNT , -- 11 '手续费总额'
     T.ORG_NUM ,
     CASE WHEN T.DEPARTMENTD= '普惠金融' THEN '0098PH'  
          WHEN (T.DEPARTMENTD= '公司金融' OR T.DEPARTMENTD IS NULL)  THEN '0098JR' 
      END   ;
   
 COMMIT; 
 
 
 
 
 -- 委托贷款
  INSERT INTO T_8_11
      ( H110001   , -- 01 '机构ID'
        H110002   , -- 02 '协议ID'
        H110003   , -- 03 '业务类型'
        H110004   , -- 04 '业务余额'
        H110005   , -- 05 '本年累计发生额'
        H110006   , -- 06 '产品ID'
        H110007   , -- 07 '累计实现产品收益'
        H110008   , -- 08 '累计实现银行端收益'
        H110009   , -- 09 '累计实现客户端收益'
        H110010   , -- 10 '手续费计算方式'
        H110011   , -- 11 '手续费总额'
        H110012   , -- 12 '手续费收取方式'
        H110013   , -- 13 '采集日期'
        DIS_DATA_DATE,
        DIS_BANK_ID,
        DEPARTMENT_ID 
        )
 SELECT 
     SUBSTR(TRIM(T3.FIN_LIN_NUM ),1,11)||T.ORG_NUM       , -- 01 '机构ID'
     T.ACCT_NUM      , -- 02 '协议ID'
     '1100' , --  委托贷款 03 '业务类型'
     NVL(T.LOAN_ACCT_BAL,0)  , -- 04 '业务余额'
     NVL(T.LOAN_ACCT_BAL,0)  , -- 05 '本年累计发生额'
     T2.CP_ID    , -- 06 '产品ID'
     0          , -- 07 '累计实现产品收益'
     0          , -- 08 '累计实现银行端收益'
     0          , -- 09 '累计实现客户端收益'
     '02'       , -- 10 '手续费计算方式'
     NVL(T1.FEE_AMT,0) , -- 11 '手续费总额'
     '01'         , -- 12 '手续费收取方式'
     TO_CHAR(P_DATE,'YYYY-MM-DD'),   -- 13 '采集日期'
     TO_CHAR(P_DATE,'YYYY-MM-DD'),   -- 13 '采集日期'
     T.ORG_NUM ,
     CASE  
           WHEN T.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
           WHEN T.DEPARTMENTD ='公司金融' OR SUBSTR(T.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
           WHEN T.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
           WHEN T.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
           WHEN SUBSTR(T.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
           WHEN SUBSTR(T.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
           END AS DEPARTMENT_ID  
   FROM SMTMODS.L_ACCT_LOAN T
   LEFT JOIN SMTMODS.L_ACCT_LOAN_ENTRUST T1
     ON T.LOAN_NUM = T1.LOAN_NUM
    AND T1.DATA_DATE = I_DATE
   LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT T2 -- 贷款合同信息表
     ON T.ACCT_NUM = T2.CONTRACT_NUM
    AND T2.DATA_DATE = I_DATE 
   LEFT JOIN VIEW_L_PUBL_ORG_BRA T3 -- 机构表
     ON T.ORG_NUM = T3.ORG_NUM
    AND T3.DATA_DATE = I_DATE
  WHERE T.DATA_DATE = I_DATE
    AND T.ACCT_TYP LIKE '90%'
       AND NVL(T2.PROD_NAME,'##') NOT IN ('个人遗留贷款无本产品','公司遗留贷款无本产品') -- 剔除无本有息历史数据
          AND (T.ACCT_STS <> '3'
              OR T.LOAN_ACCT_BAL > 0 
              OR T.FINISH_DT =I_DATE );
 
 COMMIT;


 -- 信用卡未使用额度
 INSERT INTO T_8_11
      ( H110001   , -- 01 '机构ID'
        H110002   , -- 02 '协议ID'
        H110003   , -- 03 '业务类型'
        H110004   , -- 04 '业务余额'
        H110005   , -- 05 '本年累计发生额'
        H110006   , -- 06 '产品ID'
        H110007   , -- 07 '累计实现产品收益'
        H110008   , -- 08 '累计实现银行端收益'
        H110009   , -- 09 '累计实现客户端收益'
        H110010   , -- 10 '手续费计算方式'
        H110011   , -- 11 '手续费总额'
        H110012   , -- 12 '手续费收取方式'
        H110013   , -- 13 '采集日期'
        DIS_DATA_DATE,
        DIS_BANK_ID,
        DEPARTMENT_ID 
        )
 
 SELECT 
     'B0302H22201009803'   , -- 01 '机构ID'
     T.ACCT_NUM      , -- 02 '协议ID'
     '0800'            , -- 03 '业务类型'
     case when NVL(T.CREDIT_BAL_CNY,0) < 0 then 0 else NVL(T.CREDIT_BAL_CNY,0) end  , -- 04 '业务余额'
     0               , -- 05 '本年累计发生额'
     A.CP_ID         , -- 06 '产品ID'
     0               , -- 07 '累计实现产品收益'
     0               , -- 08 '累计实现银行端收益'
     0               , -- 09 '累计实现客户端收益'
     '02'             , -- 10 '手续费计算方式'
     0               , -- 11 '手续费总额'
     '01'            , -- 12 '手续费收取方式'
     TO_CHAR(P_DATE,'YYYY-MM-DD'),    -- 13 '采集日期'
     TO_CHAR(P_DATE,'YYYY-MM-DD'),    -- 13 '采集日期'
     '009803' ,
     '009803'
    FROM SMTMODS.L_ACCT_CARD_CREDIT T  -- 信用卡账户信息表 
    LEFT JOIN SMTMODS.L_AGRE_CARD_INFO A  -- 卡基本信息表
      ON T.CARD_NO=A.CARD_NO
     AND T.DATA_DATE=A.DATA_DATE 
   WHERE T.DATA_DATE = I_DATE;
  COMMIT; 


  
 /*
 -- 财富管理中心补录
  INSERT INTO T_8_11
      ( H110001   , -- 01 '机构ID'
        H110002   , -- 02 '协议ID'
        H110003   , -- 03 '业务类型'
        H110004   , -- 04 '业务余额'
        H110005   , -- 05 '本年累计发生额'
        H110006   , -- 06 '产品ID'
        H110007   , -- 07 '累计实现产品收益'
        H110008   , -- 08 '累计实现银行端收益'
        H110009   , -- 09 '累计实现客户端收益'
        H110010   , -- 10 '手续费计算方式'
        H110011   , -- 11 '手续费总额'
        H110012   , -- 12 '手续费收取方式'
        H110013   , -- 13 '采集日期'
        DIS_DATA_DATE,
        DIS_BANK_ID ,
        DEPARTMENT_ID 
        )
 SELECT  
  ORG_NUM  , --  '机构ID',
  ACCT_NUM , --  '协议ID',
  ACCT_TYP , --  '业务类型',
  BALANCE  , --  '业务余额',
  AMT      , --  '本年累计发生额',
  CP_ID    , --  '产品ID',
  LJSXCPSY , --  '累计实现产品收益',
  LJSXYHDSY, --  '累计实现银行端收益',
  LJSXKHDSY, --  '累计实现客户端收益',
  SXFJSFS  , --  '手续费计算方式',
  SXFZE    , --  '手续费总额',
  SXFSQ    , --  '手续费收取方式',
  TO_CHAR(P_DATE,'YYYY-MM-DD'),    -- 13 '采集日期'
  TO_CHAR(P_DATE,'YYYY-MM-DD'),    -- 13 '采集日期'
  ORG_NUM_ID,
  DIS_DEPT
  
 FROM T_8_11_BL T
 WHERE DATA_DATE = TO_CHAR( P_DATE -1 ,'YYYYMMDD');
 COMMIT;
  */
 
 
 
 
 -- 理财资管手续费
   INSERT INTO T_8_11
      ( H110001   , -- 01 '机构ID'
        H110002   , -- 02 '协议ID'
        H110003   , -- 03 '业务类型'
        H110004   , -- 04 '业务余额'
        H110005   , -- 05 '本年累计发生额'
        H110006   , -- 06 '产品ID'
        H110007   , -- 07 '累计实现产品收益'
        H110008   , -- 08 '累计实现银行端收益'
        H110009   , -- 09 '累计实现客户端收益'
        H110010   , -- 10 '手续费计算方式'
        H110011   , -- 11 '手续费总额'
        H110012   , -- 12 '手续费收取方式'
        H110013   , -- 13 '采集日期'
        DIS_DATA_DATE,
        DIS_BANK_ID,
        DEPARTMENT_ID 
        )
 -- 新增20241015上线JLBA202407090005_关于一表通监管数据报送系统中“表外业务手续费及收益表”及“产品业务基本信息表”改造的需求
 SELECT 
 'B0302H22201009816' AS ORG_NUM, -- 01机构ID
 T.PRODUCT_CODE, --  02协议ID  
 '1000', -- 03发行理财
 sum (NVL(T.END_PROD_AMT,0)), -- 04业务余额
 sum (NVL(T.TRANS_AMT,0)), -- 05本年累计发生额
 CASE WHEN T.PRODUCT_CODE= '60211401' THEN '60211401'
 ELSE A.DJZXBM
 END cp_id, -- 06产品ID -- 20241015上线
 sum (NVL(T.YHDSY,0) + NVL(T.KHDSY,0)) AS LXCPDSY ,-- 07累计实现产品收益
 sum (NVL(T.YHDSY,0)) AS LJYHDSY, -- 08累计实现银行端收益
 sum (NVL(T.KHDSY,0)) AS LJKHDSY, -- 09累计实现客户端收益
'02' , -- 10手续费计算方式
 sum (CASE WHEN NVL(T.YHDSY,0)= 0 THEN 0
 ELSE NVL(T.SXFZE,0)
 END ) AS SXFZE, -- 11手续费总额
'00'  , -- 12手续费收取方式
 TO_CHAR(P_DATE,'YYYY-MM-DD')  ,  -- 13 '采集日期'
 TO_CHAR(P_DATE,'YYYY-MM-DD')  ,  -- 13 '采集日期'
'009816',
'009816'
 FROM SMTMODS.L_FIMM_PRODUCT_BAL T
 LEFT JOIN  SMTMODS.L_FIMM_PRODUCT A  -- 20241015上线
 ON A.PRODUCT_CODE=T.PRODUCT_CODE
 AND A.DATA_DATE = I_DATE 
 WHERE T.DATA_DATE= I_DATE
 AND T.DATE_SOURCESD <> 'ZGXT'
 GROUP BY T.PRODUCT_CODE,A.DJZXBM
 ;
        
    /*    
SELECT 
 'B0302H22201009816' AS ORG_NUM, -- 01机构ID
 T.PRODUCT_CODE, -- 02协议ID
 '1000', -- 03发行理财
 sum (NVL(T.END_PROD_AMT,0)), -- 04业务余额
 sum (NVL(T.TRANS_AMT,0)), -- 05本年累计发生额
 T.PRODUCT_CODE, -- 06产品ID
 sum (NVL(T.YHDSY,0) + NVL(T.KHDSY,0)) ,-- 07累计实现产品收益
 sum (NVL(T.YHDSY,0)), -- 08累计实现银行端收益
 sum (NVL(T.KHDSY,0)), -- 09累计实现客户端收益
'02' , -- 10手续费计算方式
 sum (CASE WHEN NVL(T.YHDSY,0)= 0 THEN 0
 ELSE NVL(T.SXFZE,0)
 END ) , -- 11手续费总额
'00'  , -- 12手续费收取方式
 TO_CHAR(P_DATE,'YYYY-MM-DD')  ,  -- 13 '采集日期'
 TO_CHAR(P_DATE,'YYYY-MM-DD')  ,  -- 13 '采集日期'
'009816',
'009816'
 FROM SMTMODS.L_FIMM_PRODUCT_BAL T
 WHERE T.DATA_DATE= I_DATE
 AND T.DATE_SOURCESD <> 'ZGXT'
 GROUP BY T.PRODUCT_CODE
 ;
 */
  COMMIT;
 
   -- 理财销售手续费
   INSERT INTO T_8_11
      ( H110001   , -- 01 '机构ID'
        H110002   , -- 02 '协议ID'
        H110003   , -- 03 '业务类型'
        H110004   , -- 04 '业务余额'
        H110005   , -- 05 '本年累计发生额'
        H110006   , -- 06 '产品ID'
        H110007   , -- 07 '累计实现产品收益'
        H110008   , -- 08 '累计实现银行端收益'
        H110009   , -- 09 '累计实现客户端收益'
        H110010   , -- 10 '手续费计算方式'
        H110011   , -- 11 '手续费总额'
        H110012   , -- 12 '手续费收取方式'
        H110013   , -- 13 '采集日期'
        DIS_DATA_DATE,
        DIS_BANK_ID,
        DEPARTMENT_ID 
        )
  
SELECT 
 T2.ORG_ID  AS ORG_NUM, -- 01机构ID
 T.ACCT_NUM, -- 02协议ID
 CASE 
 WHEN  T.ACCT_NUM = 'JLBANK_XM_20240606' THEN '1601' 
 WHEN  T.ACCT_NUM = '大家人寿-JLBANK202303' THEN '1603'
 WHEN  T.RZRHYLX ='10' AND ACCT_NUM LIKE 'JLBANK00%' THEN '1000'
 WHEN  T.RZRHYLX ='10' THEN '1606'
 /*WHEN  T.RZRHYLX  = '16' THEN  
   (CASE 
    WHEN t.DLCPLX ='02' THEN  '1601' -- 代销信托
    WHEN t.DLCPLX ='06' THEN  '1606' -- 代销理财
    WHEN t.DLCPLX ='05' THEN  '1604' -- 代销基金
    WHEN t.DLCPLX ='04' THEN  '1603' -- 代销保险
    WHEN t.DLCPLX ='07' THEN  '1302' -- 代销贵金属
   END )*/   -- 注释 by haorui 20241226 JLBA202409290005
 WHEN t.DLCPLX ='02' THEN  '1601' -- 代销信托
 WHEN t.DLCPLX ='06' THEN  '1606' -- 代销理财
 WHEN t.DLCPLX ='05' THEN  '1604' -- 代销基金
 WHEN t.DLCPLX ='04' THEN  '1603' -- 代销保险
 WHEN t.DLCPLX ='07' THEN  '1302' -- 代销贵金属   -- modify by haorui JLBA202409290005 新理财贵金属
 ELSE  T.RZRHYLX|| '00'
  END  AS ywlx   , -- 业务类型  
 NVL(T.YWYE,0) AS YWUE, -- 04业务余额
 NVL(T.BNLJFSE ,0) AS BNLJFSE, -- 05本年累计发生额
 T.DLCP_ID AS CP, -- 06产品ID
 NVL(T.YHDSY,0) + 0 ,-- 07累计实现产品收益
 NVL(T.YHDSY,0) AS YHDSY, -- 08累计实现银行端收益 
 0 , -- 09累计实现客户端收益
 NVL(T.SXFJSFS,'00'), -- 10手续费计算方式
 NVL(T.SXFZE,0), -- 11手续费总额
 NVL(T.SXFSQFS,'00') AS SQFS, -- 12手续费收取方式 
 TO_CHAR(P_DATE,'YYYY-MM-DD')  ,  -- 13 '采集日期'
 TO_CHAR(P_DATE,'YYYY-MM-DD')  ,  -- 13 '采集日期'
'009823',
'009823'
 FROM SMTMODS.L_AGRE_PROD_AGENCY T  -- 代理代销协议表 
 LEFT JOIN VIEW_L_PUBL_ORG_BRA T2 -- 机构表
   ON T.ORG_NUM = T2.ORG_NUM
  AND T2.DATA_DATE = T.DATA_DATE
INNER JOIN SMTMODS.L_PROD_AGENCY_PRODUCT A -- 代理代销产品信息表      -- JLBA202411180016 20241217
   ON T.DLCP_ID =A.PROD_CODE
  AND A.DATA_DATE =  I_DATE
WHERE T.DATA_DATE= I_DATE 
  AND T.SYS_SOURCE = '02'
  AND T.DLCP_ID IS NOT NULL    -- JLBA202411180016 20241217 增加条件
  AND (A.ESTAB_DATE <= I_DATE OR A.ESTAB_DATE IS NULL);    -- JLBA202411180016 20241217 增加条件
 
    COMMIT;
  
 
  -- [20250427][姜俐锋][JLBA202502280013][徐晖]:新增债券承分销  009804 只取当年的手续费
   INSERT INTO T_8_11
      ( H110001   , -- 01 '机构ID'
        H110002   , -- 02 '协议ID'
        H110003   , -- 03 '业务类型'
        H110004   , -- 04 '业务余额'
        H110005   , -- 05 '本年累计发生额'
        H110006   , -- 06 '产品ID'
        H110007   , -- 07 '累计实现产品收益'
        H110008   , -- 08 '累计实现银行端收益'
        H110009   , -- 09 '累计实现客户端收益'
        H110010   , -- 10 '手续费计算方式'
        H110011   , -- 11 '手续费总额'
        H110012   , -- 12 '手续费收取方式'
        H110013   , -- 13 '采集日期'
        DIS_DATA_DATE,
        DIS_BANK_ID,
        DEPARTMENT_ID 
        )

SELECT 
      'B0302H22201009804' AS H110001, -- 01机构ID||T.ORG_NUM 
      T.ACCT_NUM AS H110002, -- 02协议ID
      '1400' AS H110003, -- 业务类型     1400-代理发行和承销债券
      0 AS H110004, -- 04业务余额
      T.BNLJFSE AS H110005, -- 05本年累计发生额
      NVL(T.DLCP_ID,T.ACCT_NUM) AS H110006, -- 06产品ID
      NVL(T.SXFZE,0) AS H110007,-- 07累计实现产品收益 202504430 姜俐锋修改：吴大为提供口径 累计实现产品收益 = 累计实现银行端收益 + 累计实现客户端收益
      NVL(T.SXFZE,0) AS H110008, -- 08累计实现银行端收益
      NULL AS H110009, -- 09累计实现客户端收益
      NVL(T.SXFJSFS,'00') AS H110010, -- 10手续费计算方式
      NVL(T.SXFZE,0) AS H110011 , -- 11手续费总额
      '01' AS H110012, -- 12手续费收取方式
      TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS H110013 ,  -- 13 '采集日期'
      TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE ,  -- 13 '采集日期'
      T.ORG_NUM AS DIS_BANK_ID,
      '009804'  AS DEPARTMENT_ID
 FROM SMTMODS.L_AGRE_PROD_AGENCY T  -- 代理代销协议表
 LEFT JOIN SMTMODS.L_PROD_AGENCY_PRODUCT B -- 代理代销产品信息表
   ON T.DLCP_ID = B.PROD_CODE
  AND B.DATA_DATE = I_DATE
WHERE T.DATA_DATE=I_DATE
  AND T.DLCPLX = '01'
  AND T.SYS_SOURCE = '01' 
  AND T.BNLJFSE > 0
  AND T.ORG_NUM='009804'
  AND SUBSTR(I_DATE,0,4)=SUBSTR(T.ACCT_NUM,3,4);
  COMMIT;
 
  
  
 CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB); 


    #4.过程结束执行
 SET P_START_DT = NOW();
 SET P_STEP_NO = P_STEP_NO + 1;
 SET P_DESCB = '过程结束执行';
 CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    SET OI_RETCODE = P_STATUS; 
    SET OI_REMESSAGE = P_DESCB;
    SELECT OI_RETCODE,'|',OI_REMESSAGE;
END $$

