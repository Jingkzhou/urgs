DROP Procedure IF EXISTS `PROC_BSP_T_10_2_HLLL` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_10_2_HLLL"(IN I_DATE VARCHAR(8),
                                        OUT OI_RETCODE   INT,-- 返回code
                                        OUT OI_REMESSAGE VARCHAR -- 返回message
)
BEGIN
/******
      程序名称  ：汇率利率
      程序功能  ：加工汇率利率
      目标表：T_10_2
      源表  ：
      创建人  ：LZ
      创建日期  ：20240111
      版本号：V0.0.1 
  ******/
  
  #声明变量
  DECLARE P_DATE      DATE;     #数据日期
  DECLARE P_PROC_NAME   VARCHAR(200); #存储过程名称
  DECLARE P_STATUS    INT;        #执行状态
  DECLARE P_START_DT    DATETIME;   #日志开始日期
  DECLARE P_END_TIME    DATETIME;   #日志结束日期
  DECLARE P_SQLCDE    VARCHAR(200); #日志错误代码
  DECLARE P_STATE     VARCHAR(200); #日志状态代码
  DECLARE P_SQLMSG    VARCHAR(2000);  #日志详细信息
  DECLARE P_STEP_NO     INT;      #日志执行步骤
  DECLARE P_DESCB     VARCHAR(200); #日志执行步骤描述
  DECLARE BEG_MON_DT  VARCHAR(8);   #月初
  DECLARE BEG_QUAR_DT   VARCHAR(8);   #季初
  DECLARE BEG_YEAR_DT   VARCHAR(8);   #年初
  DECLARE LAST_MON_DT   VARCHAR(8);   #上月末
  DECLARE LAST_QUAR_DT  VARCHAR(8);   #上季末
  DECLARE LAST_YEAR_DT  VARCHAR(8);   #上年末
  DECLARE LAST_DT     VARCHAR(8);   #上日
  DECLARE FINISH_FLG    VARCHAR(8);   #完成标志  
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
  SET BEG_MON_DT = SUBSTR(I_DATE,1,6) || '01';  
  SET BEG_QUAR_DT = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY') || TRIM(TO_CHAR(QUARTER(TO_DATE(I_DATE,'YYYYMMDD')) * 3 - 2,'00')) || '01'; 
  SET BEG_YEAR_DT = SUBSTR(I_DATE,1,4) || '0101'; 
    SET LAST_MON_DT = TO_CHAR(TO_DATE(BEG_MON_DT,'YYYYMMDD') - 1,'YYYYMMDD'); 
    SET LAST_QUAR_DT = TO_CHAR(TO_DATE(BEG_QUAR_DT,'YYYYMMDD') - 1,'YYYYMMDD'); 
    SET LAST_YEAR_DT = TO_CHAR(TO_DATE(BEG_YEAR_DT,'YYYYMMDD') - 1,'YYYYMMDD'); 
  SET LAST_DT = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD') - 1,'YYYYMMDD');       
  SET P_PROC_NAME = 'BSP_T_10_2_HLLL';
  SET OI_RETCODE = 0;
  SET P_STATUS = 0;
  SET P_STEP_NO = 0;
  
    #1.过程开始执行
  SET P_START_DT = NOW();
  SET P_STEP_NO = P_STEP_NO + 1;
  SET P_DESCB = '过程开始执行';
         
  CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);                

    #2.清除数据
  SET P_START_DT = NOW();
  SET P_STEP_NO = P_STEP_NO + 1;
  SET P_DESCB = '清除数据';
  
  DELETE FROM T_10_2 WHERE K020009 = TO_CHAR(P_DATE,'yyyy-mm-dd');
  
  COMMIT;
                              
  CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
  SET P_START_DT = NOW();
  SET P_STEP_NO = P_STEP_NO + 1;
  SET P_DESCB = '数据插入';
  
INSERT  INTO T_10_2  (
     K020001,  -- 01.机构ID 
     K020002,  -- 02.汇率ID 
     K020003,  -- 03.外币币种 
     K020004,  -- 04.本币币种 
     K020005,  -- 05.中间价 
     K020006,  -- 06.基准价 
     K020007,  -- 07.基准（LPR）利率（一年期） 
     K020008,  -- 08.基准（LPR）利率（五年期） 
     K020009,   -- 09.采集日期
	 DIS_DATA_DATE, -- 装入数据日期
	 DIS_BANK_ID ,   -- 机构号
     DIS_DEPT,
     DEPARTMENT_ID
)

 SELECT   'B0302H22201'|| '990000' -- 1.内部机构号
           ,concat(T1.BASIC_CCY,'CNY',T1.DATA_DATE)   -- 02.汇率ID
           ,T1.BASIC_CCY AS  WBBZ -- 3.外币币种
           ,'CNY' AS BBBZ -- 4.本币币种
           ,T1.JBJ   as ZJJ  -- 05.中间价 
           ,100*CASE WHEN T1.CONVERT_TYP = 'M' THEN ROUND(T1.CCY_RATE, 6)
                     WHEN T1.CONVERT_TYP = 'D' THEN ROUND(100 / T1.CCY_RATE, 6)
                end /**T1.ZJJ**/  -- 06.基准价   0621_LHY同步east逻辑
           ,T1.YNQ_LPR  -- 07.基准（LPR）利率（一年期） 
           ,T1.WNQ_LPR  -- 08.基准（LPR）利率（五年期）
           ,TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') -- 9.采集日期
           ,TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')
           -- ,T3.ORG_NUM
           ,'990000'
           ,''
           ,'0098GJ'
      FROM SMTMODS.L_PUBL_RATE T1  -- 汇率表
     -- LEFT JOIN SMTMODS.L_PUBL_ORG_BRA T3  -- 机构表
       -- ON T3.ORG_NUM = '990000'
     --  ON T3.DATA_DATE =I_DATE
     WHERE T1.FORWARD_CCY = 'CNY'
    AND T1.DATA_DATE =  I_DATE;

    COMMIT;

 /* -- 单独加工处理磐石汇率信息
 INSERT  INTO T_10_2  (
     K020001,  -- 01.机构ID 
     K020002,  -- 02.汇率ID 
     K020003,  -- 03.外币币种 
     K020004,  -- 04.本币币种 
     K020005,  -- 05.中间价 
     K020006,  -- 06.基准价 
     K020007,  -- 07.基准（LPR）利率（一年期） 
     K020008,  -- 08.基准（LPR）利率（五年期） 
     K020009   -- 09.采集日期

)
SELECT     
           substr(TRIM(T3.FIN_LIN_NUM),1,11) || T3.ORG_NUM -- 1.内部机构号
           ,NULL  -- 02.汇率ID
           ,T1.BASIC_CCY AS  WBBZ -- 3.外币币种
           ,'CNY' AS BBBZ -- 4.本币币种
           ,NULL  -- 05.中间价 
           ,NULL   -- 06.基准价 
           ,NULL  -- 07.基准（LPR）利率（一年期） 
           ,NULL  -- 08.基准（LPR）利率（五年期）
           ,TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') -- 9.采集日期
              
      FROM SMTMODS.L_PUBL_RATE T1
      LEFT JOIN SMTMODS.L_PUBL_ORG_BRA T3
        ON T3.ORG_NUM IN('510000','520000','530000','540000','550000','560000','570000','580000','590000','600000')
      AND T3.DATA_DATE = I_DATE
    WHERE T1.FORWARD_CCY = 'CNY'
    AND T1.DATA_DATE =  I_DATE; */
  
    
  
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

