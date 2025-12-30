DROP Procedure IF EXISTS `PROC_BSP_T_6_19_DLXY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_19_DLXY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN


  /******
      程序名称  ：表6.19代理协议
      程序功能  ：加工表6.19代理协议
      目标表：T_6_19
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
 -- JLBA202411180016_关于修正一表通与综合理财系统数据对接准确性的需求 20241217
 /* 需求编号：JLBA202502280013_关于一表通监管报送系统金融市场部债券承分销业务变更的需求 上线日期：20250429，修改人：姜俐锋，提出人：徐晖 */
 /*需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
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
 SET P_PROC_NAME = 'PROC_BSP_T_6_19_DLXY';
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
 
 DELETE FROM T_6_19 WHERE F190023 = TO_CHAR(P_DATE,'YYYY-MM-DD') ;
 
 COMMIT;
    
 CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
 SET P_START_DT = NOW();
 SET P_STEP_NO = P_STEP_NO + 1;
 SET P_DESCB = '数据插入';
 
 -- 理财销售
 INSERT INTO T_6_19
 (
   F190001    , -- 01 '协议ID'
   F190002    , -- 02 '机构ID'
   F190003    , -- 03 '委托人ID'
   F190004    , -- 04 '委托人名称'
   F190005    , -- 05 '委托人类型'
   F190006    , -- 06 '代理产品类型'
   F190007    , -- 07 '代理产品ID'
   F190008    , -- 08 '发行机构评级'
   F190009    , -- 09 '发行机构评级机构'
   F190010    , -- 10 '融资人名称'
   F190011    , -- 11 '融资人行业类型'
   F190012    , -- 12 '签约日期'
   F190013    , -- 13 '生效日期'
   F190014    , -- 14 '到期日期'
   F190018    , -- 18 '经办员工ID'
   F190019    , -- 19 '审查员工ID'
   F190020    , -- 20 '审批员工ID'
   F190021    , -- 21 '协议状态'
   F190022    , -- 22 '备注'
   F190023    , -- 23 '采集日期' 
   DIS_DATA_DATE,
   DIS_BANK_ID,
   DEPARTMENT_ID,
   DIS_DEPT
 )
  SELECT   
   T.ACCT_NUM    AS F190001 , -- 01 '协议ID'
   T2.ORG_ID     AS F190002 , -- 02 '机构ID'
   T.CUST_ID     AS F190003 , -- 03 '委托人ID'
   T.CUST_NAM    AS F190004 , -- 04 '委托人名称'
   T.WTRLX       AS F190005 , -- 05 '委托人类型'
   T.DLCPLX      AS F190006 , -- 06 '代理产品类型'
   T.DLCP_ID     AS F190007 , -- 07 '代理产品ID'
   T.FXJGPJ      AS F190008 , -- 08 '发行机构评级'
   T.FXJGPJJG    AS F190009 , -- 09 '发行机构评级机构'
   T.RZRMC       AS F190010 , -- 10 '融资人名称'
   CASE WHEN T.DLCPLX='06' THEN 'J6640'  -- 理财            非货币银行服务
        WHEN T.DLCPLX='02' THEN 'J6911'  -- 信托计划    金融信息服务
        ELSE NULL 
        END      AS F190011 , -- 11 '融资人行业类型'  JLBA202411180016 20241217 修改
   T.QYRQ        AS F190012 , -- 12 '签约日期'
   T.SXRQ        AS F190013 , -- 13 '生效日期'
   '9999-12-31'  AS F190014 , -- 14 '到期日期'
   NVL(T.JBYG_ID ,'自动') AS F190018 , -- 18 '经办员工ID'
   NVL(T.SCYG_ID ,'自动') AS F190019 , -- 19 '审查员工ID'
   NVL(T.SPYG_ID ,'自动') AS F190020 , -- 20 '审批员工ID'
   CASE WHEN T.XYZT = '0' THEN '01'
        WHEN T.XYZT = '1' THEN '06'
        WHEN T.XYZT = '2' THEN '04'
        ELSE T.XYZT
        END              AS F190021 , -- 21 '协议状态'
   NULL                  AS F190022 , -- 22 '备注'
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')  AS F190023 , -- 23 '采集日期' 
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')  AS DIS_DATA_DATE ,
   '009823'  AS DIS_BANK_ID ,
   '009823'  AS DEPARTMENT_ID ,
   '理财销售'  AS DIS_DEPT 
  FROM SMTMODS.L_AGRE_PROD_AGENCY T  -- 代理代销协议表
    LEFT JOIN VIEW_L_PUBL_ORG_BRA T2 -- 机构表
     ON T.ORG_NUM = T2.ORG_NUM
    AND T2.DATA_DATE = T.DATA_DATE
WHERE T.DATA_DATE=I_DATE   
 AND T.SYS_SOURCE = '02'  
 AND T.SXRQ IS NOT NULL
 AND T.DLCP_ID IS NOT NULL;
 
 COMMIT; 
 
-- [20250427][姜俐锋][JLBA202502280013][徐晖]: 新增 债券承分销  金融市场部 
 
 INSERT INTO T_6_19
 (
   F190001    , -- 01 '协议ID'
   F190002    , -- 02 '机构ID'
   F190003    , -- 03 '委托人ID'
   F190004    , -- 04 '委托人名称'
   F190005    , -- 05 '委托人类型'
   F190006    , -- 06 '代理产品类型'
   F190007    , -- 07 '代理产品ID'
   F190008    , -- 08 '发行机构评级'
   F190009    , -- 09 '发行机构评级机构'
   F190010    , -- 10 '融资人名称'
   F190011    , -- 11 '融资人行业类型'
   F190012    , -- 12 '签约日期'
   F190013    , -- 13 '生效日期'
   F190014    , -- 14 '到期日期'
   F190018    , -- 18 '经办员工ID'
   F190019    , -- 19 '审查员工ID'
   F190020    , -- 20 '审批员工ID'
   F190021    , -- 21 '协议状态'
   F190022    , -- 22 '备注'
   F190023    , -- 23 '采集日期' 
   DIS_DATA_DATE,
   DIS_BANK_ID,
   DEPARTMENT_ID,
   DIS_DEPT
 )
  SELECT   
   T.ACCT_NUM                AS F190001 , -- 01 '协议ID'
   'B0302H22201009804'       AS F190002 , -- 02 '机构ID'T.ORG_NUM 
   T.CUST_ID                 AS F190003 , -- 03 '委托人ID'
   T.CUST_NAM                AS F190004   , -- 04 '委托人名称'
   CASE WHEN T3.FINA_CODE_NEW LIKE 'C%' THEN '01'
        WHEN T3.FINA_CODE_NEW LIKE 'D%' THEN '02'
        WHEN T3.FINA_CODE_NEW LIKE 'E%' THEN '03'
        WHEN T3.FINA_CODE_NEW LIKE 'F%' THEN '04'
        WHEN T3.FINA_CODE_NEW LIKE 'G%' THEN '05'
        WHEN T3.FINA_CODE_NEW LIKE 'H%' THEN '06'
        WHEN T3.FINA_CODE_NEW LIKE 'I%' THEN '08'
        WHEN T3.FINA_CODE_NEW LIKE 'Z%' THEN '00'
        ELSE '00'
    END                      AS F190005  , -- 05 '委托人类型'
   '01'                      AS F190006  , -- 06 '代理产品类型'
   T.DLCP_ID                 AS F190007  , -- 07 '代理产品ID'
   T.FXJGPJ                  AS F190008  , -- 08 '发行机构评级'
   T.FXJGPJJG                AS F190009  , -- 09 '发行机构评级机构'
   T.RZRMC                   AS F190010  , -- 10 '融资人名称'
   T.RZRHYLX                 AS F190011  , -- 11 '融资人行业类型'
   T.QYRQ                    AS F190012  , -- 12 '签约日期'
   T.SXRQ                    AS F190013  , -- 13 '生效日期'
   '9999-12-31'              AS F190014  , -- 14 '到期日期'
   NVL(G1.GB_CODE,'自动')    AS F190018  , -- 18 '经办员工ID'
   NVL(G2.GB_CODE,'自动')     AS F190019  , -- 19 '审查员工ID'
   NVL(G3.GB_CODE,'自动')     AS F190020  , -- 20 '审批员工ID'
   '01'                      AS F190021  , -- 21 '协议状态'
   NULL                      AS F190022  , -- 22 '备注'
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS F190023  , -- 23 '采集日期' 
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE  ,
   T.ORG_NUM                 AS DIS_BANK_ID,
   '009804'                  AS DEPARTMENT_ID,
   '债券承分销'               AS DIS_DEPT
 FROM SMTMODS.L_AGRE_PROD_AGENCY T  -- 代理代销协议表
 LEFT JOIN SMTMODS.L_PROD_AGENCY_PRODUCT B -- 代理代销产品信息表
   ON T.DLCP_ID = B.PROD_CODE
  AND B.DATA_DATE = I_DATE
  AND B.DATE_SOURCESD='CMST'
 LEFT JOIN SMTMODS.L_CUST_BILL_TY T3
   ON T.CUST_ID = T3.ECIF_CUST_ID 
  AND T3.DATA_DATE = I_DATE
 LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE G1
   ON G1.L_CODE =T.JBYG_ID
  AND G1.L_CODE_TABLE_CODE = 'C0013' 
 LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE G2
   ON G2.L_CODE =T.JBYG_ID
  AND G2.L_CODE_TABLE_CODE = 'C0013' 
 LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE G3
   ON G3.L_CODE =T.JBYG_ID
  AND G3.L_CODE_TABLE_CODE = 'C0013' 
WHERE T.DATA_DATE = I_DATE
  AND T.DLCPLX = '01'
  AND NVL(B.ISSUER_NAME,'@@') NOT LIKE '%吉林银行%'
  AND T.SYS_SOURCE = '01' 
  AND T.ORG_NUM='009804'
  AND T.SXFSQFS='JY'
  AND B.END_DATE >= SUBSTR(I_DATE,1,4)||'0101' -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
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


