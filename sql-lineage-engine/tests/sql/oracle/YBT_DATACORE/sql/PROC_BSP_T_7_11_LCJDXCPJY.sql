DROP Procedure IF EXISTS `PROC_BSP_T_7_11_LCJDXCPJY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_7_11_LCJDXCPJY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN


  /******
      程序名称  ：理财及代销产品交易
      程序功能  ：加工理财及代销产品交易
      目标表：T_7_11
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
 -- JLBA202411180016_关于修正一表通与综合理财系统数据对接准确性的需求 20241217
 /* 需求编号：JLBA202502280013_关于一表通监管报送系统金融市场部债券承分销业务变更的需求 上线日期：20250429，修改人：姜俐锋，提出人：徐晖 */
 -- 需求编号：JLBA202401110001 上线日期：2025-05-09，修改人：蒿蕊，提出人：从需求 修改原因：新理财信托业务修复缺陷
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
 SET P_PROC_NAME = 'PROC_BSP_T_7_11_LCJDXCPJY';
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
 
 DELETE FROM ybt_datacore.T_7_11 WHERE G110013 = TO_CHAR(P_DATE,'YYYY-MM-DD') ;
 
 COMMIT;
    
 CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
 SET P_START_DT = NOW();
 SET P_STEP_NO = P_STEP_NO + 1;
 SET P_DESCB = '数据插入';
 
 INSERT INTO ybt_datacore.T_7_11
 (
      G110001    , -- 01 '协议ID'
      G110002    , -- 02 '客户ID'
      G110003    , -- 03 '交易ID'
      G110014    , -- 14 '机构ID'
      G110004    , -- 04 '销售渠道'
      G110005    , -- 05 '销售日期'
      G110006    , -- 06 '销售时间'
      G110007    , -- 07 '关联存款账号'
      G110008    , -- 08 '关联存款账号开户行名称'
      G110009    , -- 09 '手续费金额'
      G110010    , -- 10 '手续费币种'
      G110011    , -- 11 '交易方向'
      G110012    , -- 12 '现转标识'
      G110015    , -- 15 '客户类型'
      G110016    , -- 16 '客户风险偏好评估结果'
      G110017    , -- 17 '经办员工ID'
      G110018    , -- 18 '本方清算账号'
      G110019    , -- 19 '对方清算账号'
      G110020    , -- 20 '对方清算行号'
      G110021    , -- 21 '交易币种'
      G110022    , -- 22 '交易金额'
      G110023    , -- 23 '是否有代理销售协议'
      G110024    , -- 24 '备注'
      G110013    ,  -- 13 '采集日期'
      DIS_DATA_DATE, 
      DIS_BANK_ID,   -- 机构号
      DEPARTMENT_ID ,      -- 业务条线
      DIS_DEPT


)
WITH FINANCE_FUND_XTBF AS 
(SELECT  DISTINCT T.CUST_ID,T.DLCP_ID, A.BFQSZH
  FROM  SMTMODS.L_AGRE_PROD_AGENCY T   -- 代理代销协议表
  LEFT JOIN TRAN_FINANCE_FUND_XT A
    ON  T.CUST_ID =A.CUST_ID
 WHERE DATA_DATE=I_DATE
   AND DLCPLX ='02'
   AND T.DLCP_ID IS NOT NULL)  --  JLBA202411180016 20241217 新增对于信托部分 本方清算账号 缺失的铺底

  SELECT 
       CASE WHEN A.BUSINESS_TYPE = '22' THEN A.REF_NUM
       ELSE 
       SUBSTR (A.ACCT_NUM || A.REF_NUM ,1,60)       
       END      , -- 01 '协议ID'
       A.CUST_ID                                          , -- 02 '客户ID'
       A.REF_NUM                                          , -- 03 '交易ID'
       substr(ORG.FIN_LIN_NUM,1,11)||ORG.ORG_NUM AS JGH                , -- 14 '机构ID'
       /*CASE 
         WHEN A.SELLING_CHANNEL = '1' THEN '01' -- 柜面
            WHEN A.SELLING_CHANNEL = '2' THEN '06' -- 手机银行
            ELSE '00' -- 其他
             END                                          , -- 04 '销售渠道' */
       CASE 
            WHEN A.SELLING_CHANNEL IN ('1','E','D') THEN '05' -- 网银
            WHEN A.SELLING_CHANNEL = '0' THEN '01' -- 柜面
            WHEN A.SELLING_CHANNEL ='7' THEN '06' -- 手机银行
            ELSE '00' -- 其他
       end                                                , -- 04 '销售渠道'   modify by haorui 20241226 JLBA202409290005(新理财贵金属) 
       TO_CHAR(TO_DATE(A.XSRQ,'YYYYMMDD'),'YYYY-MM-DD')   , -- 05 '销售日期'
       nvl(A.XSSJ,'00:00:00')                             , -- 06 '销售时间'
       A.GLCKZH                                           , -- 07 '关联存款账号'
       nvl(A.ACCT_BANKNAME,org.ORG_NAM)                   , -- 08 '关联存款账号开户行名称' 20240607 与EAST逻辑同步
       A.FEE_AMT                                          , -- 09 '手续费金额'
       A.FEE_CURR                                         , -- 10 '手续费币种'
       CASE
         WHEN (A.TRAN_TYPE IN ('1','2') OR A.BUSINESS_TYPE ='6')  THEN '01' -- '买入'     
         WHEN A.TRAN_TYPE IN ('3','4') THEN '02' -- '卖出'     
          END                                           , -- 11 '交易方向'
       CASE 
         WHEN A.CASH_FLG = '0' THEN '01' -- '现'               
         WHEN A.CASH_FLG = '1' THEN '02' -- '转'               
          END                                           , -- 12 '现转标识'
       CASE WHEN A.BUSINESS_TYPE = '22'  AND ( T3.FINA_CODE_NEW LIKE 'C%'OR T3.FINA_CODE_NEW LIKE 'D%') THEN '03'
            WHEN A.BUSINESS_TYPE = '22'  AND ( T3.FINA_CODE_NEW LIKE 'E%'OR T3.FINA_CODE_NEW LIKE 'F%'OR T3.FINA_CODE_NEW LIKE 'G%'
            OR T3.FINA_CODE_NEW LIKE 'H%'OR T3.FINA_CODE_NEW LIKE 'I%') THEN '04'
            WHEN A.BUSINESS_TYPE = '22' AND T3.FINA_CODE_NEW LIKE 'Z%' THEN '00'
            WHEN T1.CUST_ID IS NOT NULL AND T1.CUST_TYP <> '3' AND  A.BUSINESS_TYPE <> '22' THEN '01' -- 单一法人客户（非金融机构）
         WHEN (T2.CUST_ID IS NOT NULL OR T1.CUST_TYP = '3')AND  A.BUSINESS_TYPE <> '22'  THEN '05' -- 个人客户
         ELSE '00' -- 其他
         END                                          , -- 15 '客户类型'
      -- A.FXBHPGJG                                         , -- 16 '客户风险偏好评估结果'
       CASE WHEN A.FXBHPGJG IS NOT NULL THEN '0'||A.FXBHPGJG
            ELSE NULL 
            END                                 , -- 16 '客户风险偏好评估结果'  JLBA202411180016因校验规则 YBT_JYG11-34 20241217
   
       CASE WHEN C.EMP_ID IS NULL THEN  '自动' 
       ELSE A.EMP_ID 
       END AS JBYG                                        , -- 17 '经办员工ID'  陈开泰定逻辑
       NVL(DECODE(A.BUSINESS_TYPE,'3',D.BFQSZH, A.BFQSZH),A.BFQSZH)   , -- 18 '本方清算账号'A.BFQSZH [2025-05-09] [蒿蕊] [JLBA202401110001] [从需求]新理财-信托业务：TRAN_FINANCE_FUND_XT该表为铺底数据，信托关联不上的从源系统取
       A.DFQSZH                                           , -- 19 '对方清算账号'
       A.DFQSHH                                           , -- 20 '对方清算行号' 20240607 与EAST逻辑同步 原为 A.DFQSHH，可改为 B.ISSUER_SETTLE_BANK
       A.CURR_CD                                          , -- 21 '交易币种'
       A.AMT                                              , -- 22 '交易金额'
       '1'                                                , -- 23 '是否有代理销售协议'
       NULL                                               , -- 24 '备注'
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')                       ,  -- 13 '采集日期'        
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
       '990000' ,
       CASE WHEN A.BUSINESS_TYPE = '22' THEN A.ORG_NUM    -- 金融市场部 
          ELSE '009823'END , -- 条线 财富管理部 
       CASE   
          WHEN A.BUSINESS_TYPE='1'   THEN '理财产品'
          WHEN A.BUSINESS_TYPE='2'   THEN '基金'
          WHEN A.BUSINESS_TYPE='21'  THEN '股票基金'
          WHEN A.BUSINESS_TYPE='22'  THEN '债券基金'
          WHEN A.BUSINESS_TYPE='23'  THEN '货币市场基金'
          WHEN A.BUSINESS_TYPE='24'  THEN '混合基金'
          WHEN A.BUSINESS_TYPE='25'  THEN '其他类型基金'
          WHEN A.BUSINESS_TYPE='3'   THEN '信托计划'
          WHEN A.BUSINESS_TYPE='4'   THEN '资产管理计划'
          WHEN A.BUSINESS_TYPE='5'   THEN '保险产品'
          WHEN A.BUSINESS_TYPE='6'   THEN '贵金属'
          ELSE A.BUSINESS_TYPE
          END     -- 24 '备注'
 FROM SMTMODS.L_TRAN_FINANCE_FUND A -- 代理代销交易表 -- [20250427][姜俐锋][JLBA202502280013][徐晖]:L层新增债券承分销业务
 LEFT JOIN SMTMODS.L_PROD_AGENCY_PRODUCT B -- 代理代销产品信息表
   ON A.PROD_CODE = B.PROD_CODE
  AND B.DATA_DATE = I_DATE
 LEFT JOIN SMTMODS.L_CUST_C T1
   ON A.CUST_ID = T1.CUST_ID
  AND T1.DATA_DATE = I_DATE
 LEFT JOIN SMTMODS.L_CUST_P T2
   ON A.CUST_ID = T2.CUST_ID
  AND T2.DATA_DATE = I_DATE  
/* LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
   ON A.ORG_NUM = ORG.ORG_NUM
  AND ORG.DATA_DATE = I_DATE*/
 LEFT JOIN SMTMODS.L_PUBL_ORG_BRA ORG
   ON A.ORG_NUM = ORG.ORG_NUM
  AND ORG.DATA_DATE = I_DATE
 LEFT JOIN SMTMODS.L_CUST_BILL_TY T3
   ON A.CUST_ID = T3.CUST_ID
  AND T3.DATA_DATE = I_DATE
 LEFT JOIN SMTMODS.L_PUBL_EMP C
   ON A.EMP_ID = C.EMP_ID 
  AND C.DATA_DATE = I_DATE
 LEFT JOIN FINANCE_FUND_XTBF D -- --  JLBA202411180016 20241217
   ON A.PROD_CODE = D.DLCP_ID
WHERE A.DATA_DATE=I_DATE 
  AND A.TRAN_DATE = I_DATE   
  AND NVL(B.ISSUER_NAME,'@@') NOT LIKE '%吉林银行%' 
           ;
 
       
    COMMIT;
 
 
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

