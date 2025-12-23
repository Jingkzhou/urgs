DROP Procedure IF EXISTS `PROC_BSP_T_8_15_HKZT` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_8_15_HKZT"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回CODE
                                         OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
                                         )
BEGIN

  /******
      程序名称  ：还款状态
      程序功能  ：加工还款状态
      目标表：T_8_15
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
 -- JLBA202501240018_关于一表通监管数据报送系统变更的需求_20250311
 /* 需求编号：JLBA202502200003 上线日期：20250415，修改人：姜俐锋，提出人：李逊昂,吴大为 修改原因：  去掉信用卡核销数据*/
 /* 需求编号：JLBA202502210009 上线日期：20250415，修改人：姜俐锋，提出人：吴大为 */
 /* 需求编号：JLBA202504060003 上线日期：20250513，修改人：狄家卉，提出人：吴大为    关于一表通监管数据报送系统、EAST报送系统修改取数逻辑的需求*/
 /* 需求编号： JLBA202505280002 上线日期：2025-06-19，修改人：巴启威  提出人：吴大为  修改原因：因一表通校验问题发现的代码逻辑调整
 /* 需求编号：    JLBA202506030006 上线日期：20250729，修改人：姜俐锋，提出人：姚司桐 关于金融市场部一表通监管数据报送系统8.15还款状态表字段逻辑优化需求*/
 /* 需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
 /* 需求编号：JLBA202507300010 上线日期：2025-09-29，修改人：姜俐锋，提出人：信贷新增产品 修改原因：关于新一代信贷管理系统新增线上微贷板块的需求 */		
  #声明变量
  DECLARE P_DATE     DATE;   #数据日期
  DECLARE A_DATE     VARCHAR(10);    #数据日期
  DECLARE P_PROC_NAME   VARCHAR(200); #存储过程名称
  DECLARE P_STATUS   INT;     #执行状态
  DECLARE P_START_DT   DATETIME;  #日志开始日期
  DECLARE P_END_TIME   DATETIME;  #日志结束日期
  DECLARE P_SQLCDE  VARCHAR(200); #日志错误代码
  DECLARE P_STATE    VARCHAR(200); #日志状态代码
  DECLARE P_SQLMSG  VARCHAR(2000); #日志详细信息
  DECLARE P_STEP_NO    INT;   #日志执行步骤
  DECLARE P_DESCB    VARCHAR(200); #日志执行步骤描述
  DECLARE BEG_MON_DT  VARCHAR(8);  #月初
  DECLARE BEG_QUAR_DT  VARCHAR(8);  #季初
  DECLARE BEG_YEAR_DT  VARCHAR(8);  #年初
  DECLARE LAST_MON_DT   VARCHAR(8);  #上月末
  DECLARE LAST_QUAR_DT  VARCHAR(8);  #上季末
  DECLARE LAST_YEAR_DT  VARCHAR(8);  #上年末
  DECLARE LAST_DT    VARCHAR(8);  #上日
  DECLARE FINISH_FLG    VARCHAR(8);  #完成标志  
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
 SET P_PROC_NAME = 'PROC_BSP_T_8_15_HKZT';
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
 
 
 DELETE FROM T_8_15 WHERE H150026 = TO_CHAR(P_DATE,'YYYY-MM-DD') ;
 -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求:新增当年终结的贷款最后一期还款数据，持续报送至年末
 DELETE FROM T_8_15_FINISH T WHERE T.H150026 = TO_DATE(I_DATE,'YYYYMMDD')-1;
 -- 先将前一报送日期当天终结的数据插入到铺底表中
 INSERT INTO T_8_15_FINISH
   SELECT * FROM T_8_15 T 
           WHERE T.H150025 = T.H150026 
             AND T.H150025 = TO_DATE(I_DATE,'YYYYMMDD')-1
             AND T.H150026 = TO_DATE(I_DATE,'YYYYMMDD')-1
             AND NOT EXISTS (SELECT 1 FROM T_8_15_FINISH T1 WHERE T1.H150002||T1.H150003 = T.H150002||T.H150003 );
 
 COMMIT;
                 
 CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
 SET P_START_DT = NOW();
 SET P_STEP_NO = P_STEP_NO + 1;
 SET P_DESCB = '数据插入';
 
 
  set gcluster_hash_redistribute_join_optimize = 1;
   INSERT INTO T_8_15
         (
          H150001   , -- 01 '客户ID'
          H150002   , -- 02 '协议ID'
          H150003   , -- 03 '细分资产ID'
          H150027   , -- 27 '机构ID'
          H150004   , -- 04 '还本方式'
          H150005   , -- 05 '还息方式'
          H150006   , -- 06 '本期还款期数'
          H150007   , -- 07 '计划还款期数'
          H150008   , -- 08 '本期计划还款日期'
          H150009   , -- 09 '本期计划归还本金金额'
          H150010   , -- 10 '本期计划归还利息金额'
          H150011   , -- 11 '本期已归还本金'
          H150012   , -- 12 '本期已归还利息'
          H150013   , -- 13 '累计展期次数'
          H150014   , -- 14 '连续欠本天数'
          H150015   , -- 15 '连续欠息天数'
          H150016   , -- 16 '累积欠本天数'
          H150017   , -- 17 '累积欠息天数'
          H150018   , -- 18 '连续欠款期数'
          H150019   , -- 19 '累计欠款期数'
          H150020   , -- 20 '欠本金额'
          H150021   , -- 21 '表内欠款利息'
          H150022   , -- 22 '表外欠款利息'
          H150023   , -- 23 '欠本日期'
          H150024   , -- 24 '欠息日期'
          H150025   , -- 25 '终结日期'
          H150026   , -- 26 '采集日期' 
          DIS_DATA_DATE,
          DIS_BANK_ID,
          DEPARTMENT_ID ,
          H150028,-- 币种
          DIS_DEPT 
         )  
     WITH L_ACCT_LOAN_PAYM_SCHED_TMP AS  (
      SELECT t.LOAN_NUM, -- 贷款编号
             MAX(TO_NUMBER(t.REPAY_SEQ)) AS ZQS, -- 总期数
             MIN(TO_NUMBER(t.DQQS_1)) AS DQQS, -- 当前期数
             COUNT(t.LXQKQS_1) AS LXQKQS, -- 连续欠款期数
             COUNT(t.XQQS) AS XQQS, -- 待还期数
             MIN(LEAST(NVL(TO_CHAR(TO_DATE( t.DUE_DATE ,'YYYYMMDD'),'YYYY-MM-DD'), '9999-12-31'),  
             NVL(TO_CHAR(TO_DATE( t.DUE_DATE_INT,'YYYYMMDD'),'YYYY-MM-DD'), '9999-12-31'))) AS XQHKRQ, -- 下期还款日期
             COUNT(t.XQQS1) AS XQQS1, -- 本金待还期数
             COUNT(t.XQQS2) AS XQQS2, -- 利息待还期数
             MIN(t.OS_PPL) AS OS_PPL, -- 下期应还本金
             MIN(t.INTEREST) AS INTEREST, -- 下期应还利息
             MIN(t.OS_PPL_PAID) AS OS_PPL_PAID,
             MIN(t.INT_PAID) AS INT_PAID 
        FROM (SELECT F.LOAN_NUM, -- 贷款编号
                     F.REPAY_SEQ, -- 总期数
                     CASE
                       WHEN F.DUE_DATE >= I_DATE OR
                            F.DUE_DATE_INT >= I_DATE THEN
                        F.REPAY_SEQ
                     END AS DQQS_1, -- 当前期数 -- [20250605][巴启威][邮件需求][吴大为]:本期计划还款日期大于等于采集日期，加入采集日期等于 DUE_DATE本金到期日  的还款计划
                     CASE
                       WHEN (F.DUE_DATE < I_DATE OR
                            F.DUE_DATE_INT < I_DATE) AND
                            (NVL(F.OS_PPL, 0) - NVL(F.OS_PPL_PAID, 0) > 0 OR
                            NVL(F.INTEREST, 0) - NVL(F.INT_PAID, 0) > 0) THEN
                        1
                     END AS LXQKQS_1, -- 连续欠款期数
                     CASE
                       WHEN F.DUE_DATE > I_DATE OR F.DUE_DATE_INT > I_DATE THEN
                        1
                     END AS XQQS, -- 待还期数
                     CASE
                       WHEN F.DUE_DATE >= I_DATE OR F.DUE_DATE_INT >= I_DATE THEN
                          F.DUE_DATE 
                     END AS DUE_DATE, -- 本金到期日  -- [20250605][巴启威][邮件需求][吴大为]:本期计划还款日期大于等于采集日期，加入采集日期等于 DUE_DATE本金到期日  的还款计划
                     CASE
                       WHEN F.DUE_DATE >= I_DATE OR  F.DUE_DATE_INT >= I_DATE THEN
                        F.DUE_DATE_INT 
                     END AS DUE_DATE_INT, -- 利息到期日  -- [20250605][巴启威][邮件需求][吴大为]:本期计划还款日期大于等于采集日期，加入采集日期等于 DUE_DATE本金到期日  的还款计划
                     CASE
                       WHEN F.DUE_DATE > I_DATE THEN
                        1
                     END AS XQQS1, -- 本金待还期数
                     CASE
                       WHEN F.DUE_DATE_INT > I_DATE THEN
                        1
                     END AS XQQS2, -- 利息待还期数
                     F2.OS_PPL, -- 本金
                     F3.INTEREST, -- 利息
                     F2.OS_PPL_PAID,  -- 2025216
                     F3.INT_PAID  -- 2025216
                FROM SMTMODS.L_ACCT_LOAN_PAYM_SCHED F -- 贷款还款计划信息表
               LEFT JOIN (SELECT LOAN_NUM,
                                 OS_PPL as OS_PPL, -- 本金
                                 OS_PPL_PAID AS OS_PPL_PAID, -- 2025216
                                 ROW_NUMBER() OVER(PARTITION BY LOAN_NUM ORDER BY DUE_DATE) AS RN
                            FROM (SELECT LOAN_NUM,
                                         DUE_DATE,
                                         SUM(OS_PPL) AS OS_PPL,
                                         sum(OS_PPL_PAID) AS OS_PPL_PAID -- 2025216
                                    FROM SMTMODS.L_ACCT_LOAN_PAYM_SCHED -- 贷款还款计划信息表
                                   WHERE DUE_DATE >= I_DATE -- [20250605][巴启威][邮件需求][吴大为]:本期计划还款日期大于等于采集日期，加入采集日期等于 DUE_DATE本金到期日  的还款计划
                                     AND DATA_DATE = I_DATE 
                                     AND OS_PPL > 0
                                   GROUP BY LOAN_NUM, DUE_DATE) T1 -- 贷款还款计划信息表
                          ) F2
                  ON F.LOAN_NUM = F2.LOAN_NUM
                 AND F2.RN = 1
                LEFT JOIN (SELECT LOAN_NUM,
                                 INTEREST as INTEREST, -- 利息
                                 INT_PAID AS INT_PAID, -- 2025216
                                 ROW_NUMBER() OVER(PARTITION BY LOAN_NUM ORDER BY DUE_DATE) AS RN
                            FROM (SELECT LOAN_NUM,
                                         DUE_DATE,
                                         SUM(INTEREST) AS INTEREST,
                                         SUM(INT_PAID) AS INT_PAID -- 2025216
                                    FROM SMTMODS.L_ACCT_LOAN_PAYM_SCHED -- 贷款还款计划信息表
                                   WHERE DUE_DATE >= I_DATE -- [20250605][巴启威][邮件需求][吴大为]:本期计划还款日期大于等于采集日期，加入采集日期等于 DUE_DATE本金到期日  的还款计划
                                     AND DATA_DATE = I_DATE
                                     AND INTEREST > 0
                                   GROUP BY LOAN_NUM, DUE_DATE) T1 -- 贷款还款计划信息表
                          ) F3
                  ON F.LOAN_NUM = F3.LOAN_NUM
                 AND F3.RN = 1
               WHERE F.DATA_DATE = I_DATE
                -- AND f.DUE_DATE > I_DATE
                 ) T
       GROUP BY T.LOAN_NUM),
 
      L_ACCT_LOAN_LXQKQS_TMP AS( -- [20250619][巴启威][JLBA202505280002][吴大为]：临时表用于计算贷款逾期日期至采集日期，未还的贷款期数，即为连续欠款期数
      SELECT T.LOAN_NUM,
           SUM(CASE
               WHEN T1.DUE_DATE >= T.P_OD_DT OR T1.DUE_DATE >= T.I_OD_DT THEN 1 -- 本金到期日大于等于本金&利息逾期日期，即为未还的贷款期数
               ELSE 0
                END) AS LXQKQS
       FROM SMTMODS.L_ACCT_LOAN T
       LEFT JOIN SMTMODS.L_ACCT_LOAN_PAYM_SCHED T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T1.DATA_DATE = I_DATE
             AND T1.DUE_DATE <= T1.DATA_DATE -- 只取本金到期日小于等于采集日期的还款计划
           WHERE T.DATA_DATE = I_DATE
             AND T.OD_FLG = 'Y'
        GROUP BY T.LOAN_NUM
        )
SELECT  
             T.CUST_ID      , -- 01 '客户ID'
             T.ACCT_NUM     , -- 02 '协议ID'
             T.LOAN_NUM     , -- 03 '细分资产ID'
             SUBSTR(TRIM(G.FIN_LIN_NUM ),1,11)||T.ORG_NUM      , -- 27 '机构ID'
           CASE  
              WHEN T.REPAY_TYP = '1' THEN  '01' -- '按月'
              WHEN T.REPAY_TYP = '2' THEN  '02' -- '按季'
              WHEN T.REPAY_TYP = '3' THEN  '03' -- '按半年'
              WHEN T.REPAY_TYP = '4' THEN  '04' -- '按年'
              WHEN T.REPAY_TYP = '5' THEN  '05' -- '到期一次还本' 
              WHEN T.REPAY_TYP = '6' THEN  '06' -- '按进度还款' 
           ELSE '07'                            -- '其他'
           END AS HKFS    , -- 04 '还本方式'  一表通转EAST LMH
          CASE
             WHEN (T.ACCU_INT_FLG = 'Y' AND T.INT_REPAY_FREQ = '03') THEN '01' -- '按月'
             WHEN (T.ACCU_INT_FLG = 'Y' AND T.INT_REPAY_FREQ = '04') THEN '02' -- '按季'
             WHEN (T.ACCU_INT_FLG = 'Y' AND T.INT_REPAY_FREQ = '05') THEN '03' -- '按半年'
             WHEN (T.ACCU_INT_FLG = 'Y' AND T.INT_REPAY_FREQ = '06') THEN '04' -- '按年'
             WHEN (T.ACCU_INT_FLG = 'Y' AND T.INT_REPAY_FREQ = '07') THEN '05' -- '利随本清'
             ELSE '06'                                                         -- '其他利息归还方式'
            end AS HXFS   , -- 05 '还息方式'  一表通转EAST LMH
           --  coalesce(T.CURRENT_TERM_NUM,a.DQQS,'0')   , -- 06 '本期还款期数'
             CASE WHEN T.CURRENT_TERM_NUM ='0' THEN NVL(a.DQQS,T.REPAY_TERM_NUM)
            ELSE T.CURRENT_TERM_NUM
            END AS BQHKQS , -- 06 '本期还款期数
             CASE 
                  WHEN  NVL(T.CURRENT_TERM_NUM,a.DQQS) > NVL(T.REPAY_TERM_NUM,a.ZQS)  THEN  NVL(T.CURRENT_TERM_NUM,a.DQQS)
                  WHEN  T.REPAY_TERM_NUM IS NULL OR  T.REPAY_TERM_NUM = 0  THEN 1
                  ELSE  NVL(T.REPAY_TERM_NUM,a.ZQS) 
             END , -- 07 '计划还款期数'
            /*  CASE
               WHEN A.XQQS >= 1 THEN  A.XQHKRQ
               WHEN T.ACCT_STS = '3' THEN  '9999-12-31'
               WHEN A.XQHKRQ = '9999-12-31' AND T.OD_FLG = 'Y' THEN  NVL(SUBSTR( I_DATE, 1, 6) || '21', '9999-12-31')
              ELSE NVL(TO_CHAR(TO_DATE(T.ACTUAL_MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31')
             END AS XQHKRQ        , -- 08 '本期计划还款日期'
             -- NVL(A.OS_PPL,0) */
              CASE
               WHEN A.XQQS >= 1 THEN  A.XQHKRQ
               WHEN T.ACCT_STS = '3' THEN '9999-12-31'
               WHEN A.XQHKRQ = '9999-12-31' AND T.OD_FLG = 'Y' THEN TO_CHAR(TO_DATE(SUBSTR(to_char(add_months( TO_DATE(I_DATE,'YYYYMMDD'),1),'YYYYMMDD')  , 1, 6) || '21' ,'YYYYMMDD'),'YYYY-MM-DD') 
               WHEN A.XQQS1 IS NULL AND  NVL(T.OD_DAYS,0)= 0  AND T.LOAN_ACCT_BAL <>0 THEN TO_CHAR(TO_DATE(T.ACTUAL_MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD')  -- 没有还款计划的取借据实际到期日     modiy BY DJH 20240627 修改
               ELSE '9999-12-31'
               END AS XQHKRQ,  -- 08 '本期计划还款日期'
             CASE
             --  WHEN T.ACCT_TYP LIKE '09%' THEN  T.DRAWDOWN_AMT
               WHEN A.XQQS1 >= 1 THEN nvl(A.OS_PPL,0)
               WHEN (T.OD_DAYS = 0 OR T.OD_DAYS IS NULL) and T.ACTUAL_MATURITY_DT - P_DATE <=0 then  T.LOAN_ACCT_BAL  -- modiy BY DJH 20240627 保持与1104一致 -- 20240618 LDP 与EAST逻辑同步 原为 T.ACTUAL_MATURITY_DT - P_DATE <=0
               WHEN A.XQQS1 IS NULL AND NVL(T.OD_DAYS,0) = 0  AND T.LOAN_ACCT_BAL <>0 THEN T.LOAN_ACCT_BAL  -- 没有还款计划的取借据余额     modiy BY DJH 20240627 修改
               ELSE 0
               END AS XQYHBJ        , -- 09 '本期计划归还本金金额'   
            -- NVL(A.INTEREST,0) 
             CASE 
               WHEN T.ACCT_TYP LIKE '09%' THEN nvl(T.ACCU_INT_AMT,0)
               WHEN A.XQQS2 >= 1 THEN nvl(A.INTEREST,0)
               ELSE  0
               END AS XQYHLX, -- 10 '本期计划归还利息金额'
             NVL(A.OS_PPL_PAID,0) , -- 11 '本期已归还本金'
             NVL(A.INT_PAID,0)    , -- 12 '本期已归还利息'
             CASE WHEN T.EXTENDTERM_FLG = 'Y' THEN  NVL(T5.ZQCS, 0)
                  ELSE  0
                  END AS ZQCS  , -- 13 '累计展期次数'
             CASE WHEN  T.P_OD_DT = I_DATE THEN '1'
                  WHEN  T.P_OD_DT ='99991231' OR T.P_OD_DT IS NULL  THEN '0'
             ELSE NVL(P_DATE - TO_DATE(T.P_OD_DT,'YYYYMMDD'),0) 
             END , -- 14 '连续欠本天数'
             CASE WHEN  T.I_OD_DT = I_DATE THEN '1'
                  WHEN  T.I_OD_DT ='99991231' OR T.I_OD_DT IS NULL  THEN '0'
             ELSE NVL(P_DATE - TO_DATE(T.I_OD_DT,'YYYYMMDD'),0)  
             END , -- 15 '连续欠息天数'
             nvl(T.OVDUE_AMT_DAYS,0)  , -- 16 '累积欠本天数'-- [20250619][巴启威][JLBA202505280002][吴大为]：直取借据表新增字段【累积欠本天数】
             nvl(T.OVDUE_INT_DAYS,0)  , -- 17 '累积欠息天数'-- [20250619][巴启威][JLBA202505280002][吴大为]：直取借据表新增字段【累积欠息天数】
            -- CEIL ( TO_CHAR((P_DATE - TO_DATE( DECODE(T.P_OD_DT,'99991231',I_DATE,T.P_OD_DT),'YYYYMMDD'))) / 30) , -- 18 '连续欠款期数'
             NVL(B.LXQKQS,0), -- 18 '连续欠款期数' -- [20250619][巴启威][JLBA202505280002][吴大为]：使用临时表计算的 连续欠款期数
             GREATEST(NVL(T.CUMULATE_TERM_NUM,0),NVL(B.LXQKQS,0))  , -- 19 '累计欠款期数' [20250619][巴启威][JLBA202505280002][吴大为]：确认取数口径，原无逻辑
             NVL(T.OD_LOAN_ACCT_BAL, 0) AS  QBJE , -- 20 '欠本金额'
             -- CASE WHEN OD_FLG='N' THEN null ELSE NVL(T.OD_INT,0)  END AS BNQXYE , -- 21 '表内欠款利息'
             CASE WHEN OD_FLG='N' THEN '0' ELSE NVL(T.OD_INT_WT,T.OD_INT) END AS BNQXYE , -- 21 '表内欠款利息' 20241226 王金保修改 参考east逻辑
             -- T.OD_INT_OBS AS BWQXYE , -- 22 '表外欠款利息'
             CASE WHEN OD_FLG='N' THEN '0' ELSE T.OD_INT_OBS END AS BWQXYE , -- 22 '表外欠款利息' 20241226 王金保修改 参考east逻辑
             NVL(TO_CHAR(TO_DATE(T.P_OD_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') AS QBRQ       , -- 23 '欠本日期'
             -- NVL(TO_CHAR(TO_DATE(T.I_OD_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') AS QXRQ       , -- 24 '欠息日期'
             NVL(NVL(TO_CHAR(TO_DATE(T.I_OD_DT,'YYYYMMDD'),'YYYY-MM-DD'),CASE WHEN T.OD_FLG <> 'N' AND NVL(T.OD_INT_WT,T.OD_INT) > '0' THEN TO_CHAR(TO_DATE(T.I_OD_DT_FYJ,'YYYYMMDD'),'YYYY-MM-DD') END),'9999-12-31') AS QXRQ, -- MODIFY 王金保 20241226 欠息日期为空且欠息金额大于0,取应计转非应计日期
             NVL(TO_CHAR(TO_DATE(T.FINISH_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') AS ZJRQ    , -- 25 '终结日期'
             TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')  ,
             TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')  ,
             T.ORG_NUM,
            CASE  
             WHEN T.DEPARTMENTD ='信用卡' THEN '0098KG' -- 吉林银行总行卡部(信用卡中心管理)(0098KG)
             WHEN T.DEPARTMENTD ='公司金融' OR SUBSTR(T.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
             WHEN T.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
             WHEN T.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
             WHEN SUBSTR(T.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
             WHEN SUBSTR(T.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
             END AS TX,
             t.CURR_CD,  -- 币种  2.0 zdsj h 
             '贷款还款计划' as DIS_DEPT
            FROM SMTMODS.L_ACCT_LOAN T   -- 贷款借据信息表
           LEFT JOIN L_ACCT_LOAN_PAYM_SCHED_TMP A  -- 贷款还款计划信息表
          -- LEFT JOIN LOAN_PAYM_SCHED A  -- 贷款还款计划信息表
              ON T.LOAN_NUM = A.LOAN_NUM
           LEFT JOIN L_ACCT_LOAN_LXQKQS_TMP B
                  ON T.LOAN_NUM = B.LOAN_NUM 
           -- LEFT JOIN SMTMODS.L_ACCT_WRITE_OFF C  -- 资产核销 加工逻辑中未使用到此表 20250519注释掉
           --   ON T.LOAN_NUM = C.LOAN_NUM 
           --  AND C.DATA_DATE = I_DATE   
           -- LEFT JOIN L_ACCT_LOAN_PAYM_SCHED_TMP E -- 贷款还款计划信息表
           --   ON T.LOAN_NUM = E.LOAN_NUM
            LEFT JOIN (SELECT DISTINCT LOAN_NUM, COUNT(1) AS ZQCS
                        FROM SMTMODS.L_ACCT_LOAN_EXTENDTERM
                       WHERE DATA_DATE =  I_DATE  
                       GROUP BY LOAN_NUM ) T5 -- 展期表取展期次数
              ON T.LOAN_NUM = T5.LOAN_NUM                 
            LEFT JOIN SMTMODS.L_FINA_INNER J  -- 内部科目对照表
              ON T.ITEM_CD = J.STAT_SUB_NUM
             AND T.ORG_NUM = J.ORG_NUM
             AND J.DATA_DATE = I_DATE 
            LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT T6 -- 贷款合同信息表
              ON T.ACCT_NUM = T6.CONTRACT_NUM
             AND T6.DATA_DATE = I_DATE
            LEFT JOIN VIEW_L_PUBL_ORG_BRA G  -- 机构表
              ON T.ORG_NUM = G.ORG_NUM
             AND G.DATA_DATE = I_DATE
           WHERE T.DATA_DATE = I_DATE  
             AND NVL(T6.PROD_NAME,'##') NOT IN ('个人遗留贷款无本产品','公司遗留贷款无本产品') -- 剔除无本有息历史数据 
             AND (T.ACCT_STS <> '3'  -- 贷款核销修改：保留贷款核销数据 20211028 WQJ
              OR T.LOAN_ACCT_BAL > 0   
              OR T.FINISH_DT = I_DATE   
              OR (T.INTERNET_LOAN_FLG = 'Y' AND T.FINISH_DT= TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD')-1,'YYYYMMDD')) -- 互联网贷款数据晚一天下发，上月末数据当月取
              OR (T.CP_ID ='DK001000100041' AND T.FINISH_DT= TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD')-1,'YYYYMMDD')) -- [20250929][姜俐锋][JLBA202507300010][信贷新增产品]: 同网贷部分数据处理方式
              )
             AND NOT EXISTS(SELECT A.LOAN_NUM,A.WRITE_OFF_DATE -- 核销日期
                              FROM SMTMODS.L_ACCT_WRITE_OFF A -- 贷款核销
                             WHERE A.DATA_DATE = I_DATE
                               AND A.WRITE_OFF_DATE < I_DATE
                               AND A.LOAN_NUM = T.LOAN_NUM ) 
             AND (T.LOAN_STOCKEN_DATE IS NULL OR T.LOAN_STOCKEN_DATE = I_DATE)   -- add by haorui 20250311 JLBA202408200012 资产未转让
            ; 
                               
                               
          COMMIT; 
          
          
 -- 投资债券（累计和连续不一样）、委外投资（累计和连续一样） 
       
   INSERT INTO T_8_15
         (
          H150001   , -- 01 '客户ID'
          H150002   , -- 02 '协议ID'
          H150003   , -- 03 '细分资产ID'
          H150027   , -- 27 '机构ID'
          H150004   , -- 04 '还本方式'
          H150005   , -- 05 '还息方式'
          H150006   , -- 06 '本期还款期数'
          H150007   , -- 07 '计划还款期数'
          H150008   , -- 08 '本期计划还款日期'
          H150009   , -- 09 '本期计划归还本金金额'
          H150010   , -- 10 '本期计划归还利息金额'
          H150011   , -- 11 '本期已归还本金'
          H150012   , -- 12 '本期已归还利息'
          H150013   , -- 13 '累计展期次数'
          H150014   , -- 14 '连续欠本天数'
          H150015   , -- 15 '连续欠息天数'
          H150016   , -- 16 '累积欠本天数'
          H150017   , -- 17 '累积欠息天数'
          H150018   , -- 18 '连续欠款期数'
          H150019   , -- 19 '累计欠款期数'
          H150020   , -- 20 '欠本金额'
          H150021   , -- 21 '表内欠款利息'
          H150022   , -- 22 '表外欠款利息'
          H150023   , -- 23 '欠本日期'
          H150024   , -- 24 '欠息日期'
          H150025   , -- 25 '终结日期'
          H150026   , -- 26 '采集日期' 
          DIS_DATA_DATE,
          DIS_BANK_ID,
          DEPARTMENT_ID ,
          H150028,-- 币种
          DIS_DEPT
         )  
     SELECT   
           A.CUST_ID AS H150001   , -- 01 '客户ID'
           CASE WHEN A.INVEST_TYP = '00' THEN A.ACCT_NUM||A.REF_NUM
                WHEN A.INVEST_TYP <> '00' THEN A.ACCT_NUM 
                ELSE A.ACCT_NUM||A.REF_NUM 
                 END AS H150002   , -- 02 '协议ID' 
           A.SUBJECT_CD AS H150003   , -- 03 '细分资产ID'
           SUBSTR(TRIM(B.FIN_LIN_NUM ),1,11)||A.ORG_NUM AS H150027   , -- 27 '机构ID', -- 机构ID
           CASE WHEN T.BAL_REPAY_TYE = '01' THEN '01' -- '按月'
                WHEN T.BAL_REPAY_TYE = '02' THEN '02' -- '按季'
                WHEN T.BAL_REPAY_TYE = '03' THEN '03' -- '按半年'
                WHEN T.BAL_REPAY_TYE = '04' THEN '04' -- '按年'
                WHEN T.BAL_REPAY_TYE = '05' THEN '05' -- '到期一次还本'
                WHEN T.BAL_REPAY_TYE = '06' THEN '06' -- '按进度还款'
                ELSE '07' 
                END AS H150004   , -- 04 '还本方式'
           CASE WHEN T.INT_REPAY_TYE = '01' THEN '01' -- '按月'
                WHEN T.INT_REPAY_TYE = '02' THEN '02' -- '按季'
                WHEN T.INT_REPAY_TYE = '03' THEN '03' -- '按半年'
                WHEN T.INT_REPAY_TYE = '04' THEN '04' -- '按年'
                WHEN T.INT_REPAY_TYE = '05' THEN '05' -- '到期一次还本'
                ELSE '06' 
                END AS H150005   , -- 05 '还息方式'
           CASE WHEN A.OD_FLG='Y' THEN T1.SEQ + 1
                ELSE T.SEQ 
                END AS H150006   , -- 06 '本期还款期数'  -- [20250729][姜俐锋]JLBA202506030006[姚司桐]:投资业务 增加逾期部分判断
           CASE WHEN A.OD_FLG='Y' THEN T1.SEQ + 1
                ELSE T.SEQ 
                END AS H150007   , -- 07 '计划还款期数'  -- [20250729][姜俐锋]JLBA202506030006[姚司桐]:投资业务 增加逾期部分判断
           CASE WHEN A.OD_FLG='Y' THEN TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')
                ELSE TO_CHAR(TO_DATE(T.PLA_MATURITY_DATE,'YYYYMMDD'),'YYYY-MM-DD') 
                END AS H150008   , -- 08 '本期计划还款日期' -- [20250729][姜俐锋]JLBA202506030006[姚司桐]:投资业务 增加逾期部分判断
           CASE WHEN A.OD_FLG='Y' THEN A.OD_LOAN_ACCT_BAL
                ELSE NVL(T.OS_PPL,0) -- [20250916]校验不允许为空，为空置为0
                END AS H150009   , -- 09 '本期计划归还本金金额' -- [20250729][姜俐锋]JLBA202506030006[姚司桐]:投资业务 增加逾期部分判断[20250916]校验不允许为空，为空置为0
           CASE WHEN A.OD_FLG='Y' THEN A.OD_INT
                ELSE NVL(T.INT,0) -- [20250916]校验不允许为空，为空置为0
                END AS H150010 , -- 10 '本期计划归还利息金额' -- [20250729][姜俐锋]JLBA202506030006[姚司桐]:投资业务 增加逾期部分判断
           CASE WHEN A.OD_FLG='Y' THEN A.ATM
                ELSE NVL(T.OS_PPL_PAID,0) 
                END AS H150011   , -- 11 '本期已归还本金' -- [20250729][姜俐锋]JLBA202506030006[姚司桐]:投资业务 增加逾期部分判断
           NVL(T.INT_PAID,0) AS H150012   , -- 12 '本期已归还利息'
           '0' AS H150013   , -- 13 '累计展期次数'
           CASE WHEN A.P_OD_DT IS NULL  THEN '0'
                ELSE NVL(P_DATE - TO_DATE(A.P_OD_DT,'YYYYMMDD'),0)  
                END AS H150014   , -- 14 '连续欠本天数'
           CASE WHEN A.I_OD_DT IS NULL  THEN '0'
                ELSE NVL(P_DATE - TO_DATE(A.I_OD_DT,'YYYYMMDD'),0)  
                END AS H1500145, -- 连续欠息天数
           CASE WHEN  A.P_OD_DT IS NULL  THEN '0'
                ELSE NVL(P_DATE - TO_DATE(A.P_OD_DT,'YYYYMMDD'),0)  
                END AS H150016 , -- 16 '累积欠本天数'
           CASE WHEN  A.I_OD_DT IS NULL  THEN '0'
                ELSE NVL(P_DATE - TO_DATE(A.I_OD_DT,'YYYYMMDD'),0)  
                END AS H150017   , -- 17 '累积欠息天数'
           CASE WHEN  TO_DATE(A.MATURITY_DATE,'YYYYMMDD') < P_DATE AND (A.FACE_VAL - nvl(T.OS_PPL_PAID,0) > 0 OR A.ACCRUAL - nvl(T.INT_PAID,0) > 0)  -- 20250731 JLBA202506030006 因为校验公式问题修改
                THEN '1'  
                ELSE '0'
                END AS H150018   , -- 18 '连续欠款期数'
           CASE WHEN  TO_DATE(A.MATURITY_DATE,'YYYYMMDD') < P_DATE AND (A.FACE_VAL - nvl(T.OS_PPL_PAID,0) > 0 OR A.ACCRUAL - nvl(T.INT_PAID,0) > 0)  -- 20250731 JLBA202506030006 因为校验公式问题修改
                THEN '1'  
                ELSE '0'
                END AS H150019   , -- 19 '累计欠款期数'
           A.OD_LOAN_ACCT_BAL AS H150020   , -- 20 '欠本金额'
           A.OD_INT AS H150021   , -- 21 '表内欠款利息' 
           A.OD_INT_OBS AS H150022   , -- 22 '表外欠款利息'
           NVL(TO_CHAR(TO_DATE(NVL(A.MATURITY_DATE,A.P_OD_DT),'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') AS H150023   , -- 23 '欠本日期'
           NVL(TO_CHAR(TO_DATE(A.I_OD_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') AS H150024 , -- 24 '欠息日期'
           NVL(TO_CHAR(TO_DATE(A.MATURITY_DATE,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') AS H150025 , -- 25 '终结日期'
           TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),   -- 21 采集日期
           TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
           A.ORG_NUM,
           CASE WHEN A.INVEST_TYP = '00' THEN '009804'
                WHEN A.INVEST_TYP <> '00' THEN '009820'
                END AS DEPARTMENT_ID  ,
           A.CURR_CD AS H150028, -- 币种 
           '投资' as DIS_DEPT
      FROM SMTMODS.L_ACCT_FUND_INVEST A -- [20250729][姜俐锋]JLBA202506030006[姚司桐]:投资业务 增加逾期部分 修改主表取数
      LEFT JOIN (SELECT j.* FROM (SELECT  
                                    ROW_NUMBER() OVER(PARTITION BY ACCT_NUM ORDER BY PLA_MATURITY_DATE  )  AS RN ,
                                    T1.*
                                  FROM SMTMODS.L_ACCT_FUND_MMFUND_PAYM_SCHED T1
                                 WHERE DATA_DATE = I_DATE
                                   AND PLA_MATURITY_DATE >=I_DATE)j WHERE rn = 1 )  T  -- 20250226
        ON CASE WHEN A.INVEST_TYP = '00' THEN T.ACCT_NUM = A.ACCT_NUM||'_'||A.REF_NUM
           ELSE T.ACCT_NUM = A.ACCT_NUM 
            END 
       AND T.DATA_DATE = I_DATE 
       AND (A.OD_FLG<>'Y' OR A.OD_FLG IS NULL )
      LEFT JOIN (SELECT j.* FROM (SELECT  
                                    ROW_NUMBER() OVER(PARTITION BY ACCT_NUM ORDER BY PLA_MATURITY_DATE DESC  )  AS RN ,
                                    T1.*
                                   FROM SMTMODS.L_ACCT_FUND_MMFUND_PAYM_SCHED T1
                                  WHERE DATA_DATE = I_DATE)j  WHERE rn = 1 )  T1   -- [20250729][姜俐锋]JLBA202506030006[姚司桐]:投资业务 增加逾期部分
        ON CASE WHEN A.INVEST_TYP = '00' THEN T.ACCT_NUM = A.ACCT_NUM||'_'||A.REF_NUM
           ELSE T.ACCT_NUM = A.ACCT_NUM 
            END 
       AND T.DATA_DATE = I_DATE  
       AND A.OD_FLG = 'Y'
      LEFT JOIN VIEW_L_PUBL_ORG_BRA B -- 机构表
        ON A.ORG_NUM = B.ORG_NUM
       AND B.DATA_DATE = I_DATE
     WHERE A.DATA_DATE = I_DATE   
       AND (A.MATURITY_DATE = I_DATE OR A.FACE_VAL > 0) -- 应同业李佶阳要求，不判断到期日
       AND A.INVEST_TYP = '00' ;-- [20250513][狄家卉][JLBA202504060003][吴大为]: 剔除委外业务
         
    COMMIT; 
   
 --  回购（累计和连续一样）；取买入返售。
      INSERT INTO T_8_15
         (
          H150001   , -- 01 '客户ID'
          H150002   , -- 02 '协议ID'
          H150003   , -- 03 '细分资产ID'
          H150027   , -- 27 '机构ID'
          H150004   , -- 04 '还本方式'
          H150005   , -- 05 '还息方式'
          H150006   , -- 06 '本期还款期数'
          H150007   , -- 07 '计划还款期数'
          H150008   , -- 08 '本期计划还款日期'
          H150009   , -- 09 '本期计划归还本金金额'
          H150010   , -- 10 '本期计划归还利息金额'
          H150011   , -- 11 '本期已归还本金'
          H150012   , -- 12 '本期已归还利息'
          H150013   , -- 13 '累计展期次数'
          H150014   , -- 14 '连续欠本天数'
          H150015   , -- 15 '连续欠息天数'
          H150016   , -- 16 '累积欠本天数'
          H150017   , -- 17 '累积欠息天数'
          H150018   , -- 18 '连续欠款期数'
          H150019   , -- 19 '累计欠款期数'
          H150020   , -- 20 '欠本金额'
          H150021   , -- 21 '表内欠款利息'
          H150022   , -- 22 '表外欠款利息'
          H150023   , -- 23 '欠本日期'
          H150024   , -- 24 '欠息日期'
          H150025   , -- 25 '终结日期'
          H150026   , -- 26 '采集日期' 
          DIS_DATA_DATE,
          DIS_BANK_ID,
          DEPARTMENT_ID ,
          H150028,-- 币种
          DIS_DEPT
         )  
    SELECT 
          A.CUST_ID, -- 客户ID
          CASE WHEN A.ASS_TYPE = '1' THEN A.ACCT_NUM
               WHEN A.ASS_TYPE = '2' THEN A.ACCT_NUM||A.SUBJECT_CD
               END AS XYID, --  协议ID
          NVL(A.SUBJECT_CD ,A.ACCT_NUM) , -- 细分资产ID
          SUBSTR(TRIM(B.FIN_LIN_NUM ),1,11)||A.ORG_NUM , -- 机构ID     
          CASE 
           WHEN T.BAL_REPAY_TYE = '01' THEN '01' -- '按月'
           WHEN T.BAL_REPAY_TYE = '02' THEN '02' -- '按季'
           WHEN T.BAL_REPAY_TYE = '03' THEN '03' -- '按半年'
           WHEN T.BAL_REPAY_TYE = '04' THEN '04' -- '按年'
           WHEN T.BAL_REPAY_TYE = '05' THEN '05' -- '到期一次还本'
           WHEN T.BAL_REPAY_TYE = '06' THEN '06' -- '按进度还款'
           ELSE '07'                             -- '其他' 
           END  , -- 还本方式
           CASE 
           WHEN T.INT_REPAY_TYE = '01' THEN '01' -- '按月'
           WHEN T.INT_REPAY_TYE = '02' THEN '02' -- '按季'
           WHEN T.INT_REPAY_TYE = '03' THEN '03' -- '按半年'
           WHEN T.INT_REPAY_TYE = '04' THEN '04' -- '按年'
           WHEN T.INT_REPAY_TYE = '05' THEN '05' -- '到期一次还本'
           ELSE '06'
           END   , -- 还息方式
          CASE WHEN TO_DATE(A.END_DT,'YYYYMMDD') < P_DATE THEN '0' 
               ELSE '1'
               END , -- 本期还款期数
          '1' , -- 计划还款期数..
          TO_CHAR(TO_DATE(T.PLA_MATURITY_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 本期计划还款日期
          T.OS_PPL , -- 本期计划归还本金金额 
          T.INT , -- 本期计划归还利息金额
          NVL(T.OS_PPL_PAID,0) , -- 本期已归还本金
          NVL(T.INT_PAID,0) , -- 本期已归还利息
          '0' ,  -- 累计展期次数 
          CASE WHEN  A.P_OD_DT IS NULL  THEN '0'
             ELSE NVL(P_DATE - TO_DATE(A.P_OD_DT,'YYYYMMDD'),0)  
          END AS P_OD_DT, -- 连续欠本天数
            CASE WHEN  A.I_OD_DT IS NULL  THEN '0'
             ELSE NVL(P_DATE - TO_DATE(A.I_OD_DT,'YYYYMMDD'),0)  
          END AS I_OD_DT, -- 连续欠息天数
            CASE WHEN  A.P_OD_DT IS NULL  THEN '0'
             ELSE NVL(P_DATE - TO_DATE(A.P_OD_DT,'YYYYMMDD'),0)  
          END AS P_OD_DT,  -- 累积欠本天数
          CASE WHEN  A.I_OD_DT IS NULL  THEN '0'
             ELSE NVL(P_DATE - TO_DATE(A.I_OD_DT,'YYYYMMDD'),0)  
          END  AS I_OD_DT,  -- 累积欠息天数
           CASE WHEN TO_DATE(A.END_DT,'YYYYMMDD') < P_DATE THEN '0' 
               ELSE '1'
               END  AS LXQKQS ,-- 连续欠款期数
           CASE WHEN TO_DATE(A.END_DT,'YYYYMMDD') < P_DATE THEN '0' 
               ELSE '1'
               END  , -- 累计欠款期数
          A.OD_LOAN_ACCT_BAL,  -- 欠本金额
          A.OVERDUE_I, -- 表内欠款利息
          A.OD_INT_OBS, -- 表外欠款利息
          NVL(TO_CHAR(TO_DATE(A.P_OD_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31'), -- 欠本日期
          NVL(TO_CHAR(TO_DATE(A.I_OD_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31'), -- 欠息日期
          NVL(TO_CHAR(TO_DATE(A.END_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31'), -- 终结日期
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),   -- 21 采集日期
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
          A.ORG_NUM,
          '009804',
          a.CURR_CD,  -- 2.0zdsj h
          '回购' as DIS_DEPT
        FROM  -- SMTMODS.L_ACCT_FUND_MMFUND_PAYM_SCHED T  -- 资金往来还款计划信息表
           (SELECT j.* FROM (SELECT  
           ROW_NUMBER() OVER(PARTITION BY ACCT_NUM ORDER BY PLA_MATURITY_DATE  )  AS RN ,
           T1.*
           FROM SMTMODS.L_ACCT_FUND_MMFUND_PAYM_SCHED T1
          WHERE DATA_DATE = I_DATE 
            AND PLA_MATURITY_DATE >=I_DATE )j WHERE rn = 1 )  T  -- 20250226
       INNER JOIN SMTMODS.L_ACCT_FUND_REPURCHASE A -- 回购信息表
          ON CASE WHEN A.ASS_TYPE = '1' THEN T.ACCT_NUM = A.ACCT_NUM
                  WHEN A.ASS_TYPE = '2' THEN T.ACCT_NUM = A.ACCT_NUM||'_'||A.SUBJECT_CD
                  END 
         AND T.DATA_DATE = A.DATA_DATE 
        LEFT JOIN VIEW_L_PUBL_ORG_BRA B -- 机构表
          ON A.ORG_NUM = B.ORG_NUM
         AND B.DATA_DATE = I_DATE
       WHERE T.DATA_DATE = I_DATE  
         AND SUBSTR(BUSI_TYPE,1,1)='1'
         AND (A.ACCT_CLDATE >= I_DATE OR A.ACCT_CLDATE IS NULL)
         AND A.BALANCE > 0 ;
       COMMIT;
       
  -- 同业借贷（累计和连续一样）取同业拆出，存放同业。     
       INSERT INTO T_8_15
         (
          H150001   , -- 01 '客户ID'
          H150002   , -- 02 '协议ID'
          H150003   , -- 03 '细分资产ID'
          H150027   , -- 27 '机构ID'
          H150004   , -- 04 '还本方式'
          H150005   , -- 05 '还息方式'
          H150006   , -- 06 '本期还款期数'
          H150007   , -- 07 '计划还款期数'
          H150008   , -- 08 '本期计划还款日期'
          H150009   , -- 09 '本期计划归还本金金额'
          H150010   , -- 10 '本期计划归还利息金额'
          H150011   , -- 11 '本期已归还本金'
          H150012   , -- 12 '本期已归还利息'
          H150013   , -- 13 '累计展期次数'
          H150014   , -- 14 '连续欠本天数'
          H150015   , -- 15 '连续欠息天数'
          H150016   , -- 16 '累积欠本天数'
          H150017   , -- 17 '累积欠息天数'
          H150018   , -- 18 '连续欠款期数'
          H150019   , -- 19 '累计欠款期数'
          H150020   , -- 20 '欠本金额'
          H150021   , -- 21 '表内欠款利息'
          H150022   , -- 22 '表外欠款利息'
          H150023   , -- 23 '欠本日期'
          H150024   , -- 24 '欠息日期'
          H150025   , -- 25 '终结日期'
          H150026   , -- 26 '采集日期' 
          DIS_DATA_DATE,
          DIS_BANK_ID,
          DEPARTMENT_ID ,
          H150028,-- 币种
          DIS_DEPT
         )  
        SELECT 
          A.CUST_ID, -- 客户ID
          A.ACCT_NUM, --  协议ID
          A.ACCT_NUM||A.REF_NUM, -- 细分资产ID
          SUBSTR(TRIM(B.FIN_LIN_NUM ),1,11)||A.ORG_NUM , -- 机构ID     
          CASE 
           WHEN T.BAL_REPAY_TYE = '01' THEN '01' -- '按月'
           WHEN T.BAL_REPAY_TYE = '02' THEN '02' -- '按季'
           WHEN T.BAL_REPAY_TYE = '03' THEN '03' -- '按半年'
           WHEN T.BAL_REPAY_TYE = '04' THEN '04' -- '按年'
           WHEN T.BAL_REPAY_TYE = '05' THEN '05' -- '到期一次还本'
           WHEN T.BAL_REPAY_TYE = '06' THEN '06' -- '按进度还款'
           ELSE '07'                             -- '其他'
           END  , -- 还本方式
           CASE 
           WHEN T.INT_REPAY_TYE = '01' THEN '01' -- '按月'
           WHEN T.INT_REPAY_TYE = '02' THEN '02' -- '按季'
           WHEN T.INT_REPAY_TYE = '03' THEN '03' -- '按半年'
           WHEN T.INT_REPAY_TYE = '04' THEN '04' -- '按年'
           WHEN T.INT_REPAY_TYE = '05' THEN '05' -- '到期一次还本'
           ELSE '06'
           END   , -- 还息方式
          CASE WHEN TO_DATE(A.MATURE_DATE,'YYYYMMDD') < P_DATE THEN '0' 
               ELSE '1'
               END , -- 本期还款期数
          '1' , -- 计划还款期数..
          TO_CHAR(TO_DATE(T.PLA_MATURITY_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 本期计划还款日期
          T.OS_PPL , -- 本期计划归还本金金额 
          T.INT , -- 本期计划归还利息金额
          NVL(T.OS_PPL_PAID,0) , -- 本期已归还本金
          NVL(T.INT_PAID,0) , -- 本期已归还利息
          '0' ,  -- 累计展期次数 
          CASE WHEN  A.P_OD_DT IS NULL  THEN '0'
             ELSE NVL(P_DATE - TO_DATE(A.P_OD_DT,'YYYYMMDD'),0)  
          END AS P_OD_DT, -- 连续欠本天数
            CASE WHEN  A.I_OD_DT IS NULL  THEN '0'
             ELSE NVL(P_DATE - TO_DATE(A.I_OD_DT,'YYYYMMDD'),0)  
          END AS I_OD_DT, -- 连续欠息天数
            CASE WHEN  A.P_OD_DT IS NULL  THEN '0'
             ELSE NVL(P_DATE - TO_DATE(A.P_OD_DT,'YYYYMMDD'),0)  
          END AS P_OD_DT,  -- 累积欠本天数
          CASE WHEN  A.I_OD_DT IS NULL  THEN '0'
             ELSE NVL(P_DATE - TO_DATE(A.I_OD_DT,'YYYYMMDD'),0)  
          END  AS I_OD_DT,  -- 累积欠息天数
           CASE WHEN TO_DATE(A.MATURE_DATE,'YYYYMMDD') < P_DATE THEN '0' 
               ELSE '1'
               END  AS LXQKQS ,-- 连续欠款期数
           CASE WHEN TO_DATE(A.MATURE_DATE,'YYYYMMDD') < P_DATE THEN '0' 
               ELSE '1'
               END  , -- 累计欠款期数
          A.OD_LOAN_ACCT_BAL,  -- 欠本金额
          A.OVERDUE_I, -- 表内欠款利息
          A.OD_INT_OBS, -- 表外欠款利息
          NVL(TO_CHAR(TO_DATE(A.P_OD_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31'), -- 欠本日期
          NVL(TO_CHAR(TO_DATE(A.I_OD_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31'), -- 欠息日期
          NVL(TO_CHAR(TO_DATE(A.MATURE_DATE,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31'), -- 终结日期
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),   -- 21 采集日期
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
          A.ORG_NUM,
          '009804', 
          a.CURR_CD, -- 2.0 zdsj h
          '同业资金' as DIS_DEPT
       FROM  -- SMTMODS.L_ACCT_FUND_MMFUND_PAYM_SCHED T  -- 资金往来还款计划信息表
         (SELECT j.* FROM (SELECT  
           ROW_NUMBER() OVER(PARTITION BY ACCT_NUM ORDER BY PLA_MATURITY_DATE  )  AS RN ,
           T1.*
           FROM SMTMODS.L_ACCT_FUND_MMFUND_PAYM_SCHED T1
          WHERE DATA_DATE = I_DATE 
            AND PLA_MATURITY_DATE >=I_DATE )j WHERE rn = 1 )  T  -- 20250226
      INNER JOIN SMTMODS.L_ACCT_FUND_MMFUND A 
         ON T.ACCT_NUM = A.ACCT_NUM
        AND T.DATA_DATE = A.DATA_DATE 
       LEFT JOIN VIEW_L_PUBL_ORG_BRA B -- 机构表
         ON A.ORG_NUM = B.ORG_NUM
        AND B.DATA_DATE = I_DATE
      WHERE T.DATA_DATE = I_DATE  
        AND SUBSTR(A.GL_ITEM_CODE,1,4) IN ('1302','1011')  
        AND (A.ACCT_CLDATE >= I_DATE OR A.ACCT_CLDATE IS NULL )
        AND A.BALANCE > 0;
             COMMIT;
       
             
  -- 投资同业存单           
        INSERT INTO T_8_15
         (
          H150001   , -- 01 '客户ID'
          H150002   , -- 02 '协议ID'
          H150003   , -- 03 '细分资产ID'
          H150027   , -- 27 '机构ID'
          H150004   , -- 04 '还本方式'
          H150005   , -- 05 '还息方式'
          H150006   , -- 06 '本期还款期数'
          H150007   , -- 07 '计划还款期数'
          H150008   , -- 08 '本期计划还款日期'
          H150009   , -- 09 '本期计划归还本金金额'
          H150010   , -- 10 '本期计划归还利息金额'
          H150011   , -- 11 '本期已归还本金'
          H150012   , -- 12 '本期已归还利息'
          H150013   , -- 13 '累计展期次数'
          H150014   , -- 14 '连续欠本天数'
          H150015   , -- 15 '连续欠息天数'
          H150016   , -- 16 '累积欠本天数'
          H150017   , -- 17 '累积欠息天数'
          H150018   , -- 18 '连续欠款期数'
          H150019   , -- 19 '累计欠款期数'
          H150020   , -- 20 '欠本金额'
          H150021   , -- 21 '表内欠款利息'
          H150022   , -- 22 '表外欠款利息'
          H150023   , -- 23 '欠本日期'
          H150024   , -- 24 '欠息日期'
          H150025   , -- 25 '终结日期'
          H150026   , -- 26 '采集日期' 
          DIS_DATA_DATE,
          DIS_BANK_ID,
          DEPARTMENT_ID ,
          H150028,-- 币种
          DIS_DEPT
         )         
      SELECT 
          A.CUST_ID, -- A.CONT_PARTY_CODE  , -- 客户ID 20250311
          A.ACCT_NUM, --  协议ID
          A.CDS_NO, -- 细分资产ID
          SUBSTR(TRIM(B.FIN_LIN_NUM ),1,11)||A.ORG_NUM , -- 机构ID     
          CASE 
           WHEN T.BAL_REPAY_TYE = '01' THEN '01' -- '按月'
           WHEN T.BAL_REPAY_TYE = '02' THEN '02' -- '按季'
           WHEN T.BAL_REPAY_TYE = '03' THEN '03' -- '按半年'
           WHEN T.BAL_REPAY_TYE = '04' THEN '04' -- '按年'
           WHEN T.BAL_REPAY_TYE = '05' THEN '05' -- '到期一次还本'
           WHEN T.BAL_REPAY_TYE = '06' THEN '06' -- '按进度还款'
           ELSE '07'                             -- '其他'
           END  , -- 还本方式
           CASE 
           WHEN T.INT_REPAY_TYE = '01' THEN '01' -- '按月'
           WHEN T.INT_REPAY_TYE = '02' THEN '02' -- '按季'
           WHEN T.INT_REPAY_TYE = '03' THEN '03' -- '按半年'
           WHEN T.INT_REPAY_TYE = '04' THEN '04' -- '按年'
           WHEN T.INT_REPAY_TYE = '05' THEN '05' -- '到期一次还本'
           ELSE '06'
           END   , -- 还息方式
          CASE WHEN TO_DATE(A.MATURITY_DT,'YYYYMMDD') < P_DATE THEN '0' 
               ELSE '1'
               END , -- 本期还款期数
          '1' , -- 计划还款期数..
          TO_CHAR(TO_DATE(T.PLA_MATURITY_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 本期计划还款日期
          T.OS_PPL , -- 本期计划归还本金金额 
          T.INT , -- 本期计划归还利息金额
          NVL(T.OS_PPL_PAID,0) , -- 本期已归还本金
          NVL(T.INT_PAID,0) , -- 本期已归还利息
          '0' ,  -- 累计展期次数 
          CASE WHEN  A.P_OD_DT IS NULL  THEN '0'
             ELSE NVL(P_DATE - TO_DATE(A.P_OD_DT,'YYYYMMDD'),0)  
          END AS P_OD_DT, -- 连续欠本天数
            CASE WHEN  A.I_OD_DT IS NULL  THEN '0'
             ELSE NVL(P_DATE - TO_DATE(A.I_OD_DT,'YYYYMMDD'),0)  
          END AS I_OD_DT, -- 连续欠息天数
            CASE WHEN  A.P_OD_DT IS NULL  THEN '0'
             ELSE NVL(P_DATE - TO_DATE(A.P_OD_DT,'YYYYMMDD'),0)  
          END AS P_OD_DT,  -- 累积欠本天数
          CASE WHEN  A.I_OD_DT IS NULL  THEN '0'
             ELSE NVL(P_DATE - TO_DATE(A.I_OD_DT,'YYYYMMDD'),0)  
          END  AS I_OD_DT,  -- 累积欠息天数
           CASE WHEN TO_DATE(A.MATURITY_DT,'YYYYMMDD') < P_DATE THEN '0' 
               ELSE '1'
               END  AS LXQKQS ,-- 连续欠款期数
           CASE WHEN TO_DATE(A.MATURITY_DT,'YYYYMMDD') < P_DATE THEN '0' 
               ELSE '1'
               END  , -- 累计欠款期数
          A.OD_LOAN_ACCT_BAL,  -- 欠本金额
          A.OVERDUE_I, -- 表内欠款利息
          A.OD_INT_OBS, -- 表外欠款利息
          NVL(TO_CHAR(TO_DATE(A.P_OD_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31'), -- 欠本日期
          NVL(TO_CHAR(TO_DATE(A.I_OD_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31'), -- 欠息日期
          NVL(TO_CHAR(TO_DATE(A.MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31'), -- 终结日期
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),   -- 21 采集日期
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
          A.ORG_NUM,
          '009804', -- ??
          a.CURR_CD,  -- 2.0zdsj h
          '存单投资与发行' as DIS_DEPT
       FROM  -- SMTMODS.L_ACCT_FUND_MMFUND_PAYM_SCHED T  -- 资金往来还款计划信息表
          (SELECT j.* FROM (SELECT  
           ROW_NUMBER() OVER(PARTITION BY ACCT_NUM ORDER BY PLA_MATURITY_DATE  )  AS RN ,
           T1.*
           FROM SMTMODS.L_ACCT_FUND_MMFUND_PAYM_SCHED T1
          WHERE DATA_DATE = I_DATE 
            AND PLA_MATURITY_DATE >=I_DATE )j WHERE rn = 1 )  T  -- 20250226
      INNER JOIN SMTMODS.L_ACCT_FUND_CDS_BAL A -- 存单投资与发行信息表
         ON T.ACCT_NUM = A.ACCT_NUM
        AND T.DATA_DATE = A.DATA_DATE 
       LEFT JOIN VIEW_L_PUBL_ORG_BRA B -- 机构表
         ON A.ORG_NUM = B.ORG_NUM
        AND B.DATA_DATE = I_DATE
      WHERE T.DATA_DATE = I_DATE  
         AND A.PRODUCT_PROP ='A' 
         AND (A.ACCT_CLDATE >= I_DATE OR A.ACCT_CLDATE IS NULL) -- 范围与8.8、7.7、4.3同步
         ; 
                COMMIT;
     
                
     -- 信用卡 
    INSERT INTO T_8_15
         (
          H150001   , -- 01 '客户ID'
          H150002   , -- 02 '协议ID'
          H150003   , -- 03 '细分资产ID'
          H150027   , -- 27 '机构ID'
          H150004   , -- 04 '还本方式'
          H150005   , -- 05 '还息方式'
          H150006   , -- 06 '本期还款期数'
          H150007   , -- 07 '计划还款期数'
          H150008   , -- 08 '本期计划还款日期'
          H150009   , -- 09 '本期计划归还本金金额'
          H150010   , -- 10 '本期计划归还利息金额'
          H150011   , -- 11 '本期已归还本金'
          H150012   , -- 12 '本期已归还利息'
          H150013   , -- 13 '累计展期次数'
          H150014   , -- 14 '连续欠本天数'
          H150015   , -- 15 '连续欠息天数'
          H150016   , -- 16 '累积欠本天数'
          H150017   , -- 17 '累积欠息天数'
          H150018   , -- 18 '连续欠款期数'
          H150019   , -- 19 '累计欠款期数'
          H150020   , -- 20 '欠本金额'
          H150021   , -- 21 '表内欠款利息'
          H150022   , -- 22 '表外欠款利息'
          H150023   , -- 23 '欠本日期'
          H150024   , -- 24 '欠息日期'
          H150025   , -- 25 '终结日期'
          H150026   , -- 26 '采集日期' 
          DIS_DATA_DATE,
          DIS_BANK_ID,
          DEPARTMENT_ID ,
          H150028,-- 币种
          DIS_DEPT
         )             
                              
SELECT  
T.CUST_ID,  -- 客户ID
T.ACCT_NUM , -- 协议ID
T.ACCT_NUM , -- 细分资产ID
'B0302H22201009803', -- 机构ID
'01' , --  按月     还本方式
'01' , --  按月     还息方式
'0'  , -- 本期还款期数
NULL , -- 计划还款期数 20250311
T.BQJHHKR , -- 本期计划还款日期 
T.JHGHBJ , -- 本期计划归还本金金额
T.JHGHLX , -- 本期计划归还利息金额
NVL(T.YGHBJ,0) , -- 本期已归还本金
NVL(T.YGHLX,0) , -- 本期已归还利息
'0' , -- 累计展期次数
case when T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP > 0 and T.LXQKQS > 0 then T.LXQBTS 
     else 0
      end , -- 连续欠本天数 [20250519][巴启威]：欠本金额>0，MTHS_ODUE当前逾期期数大于0时,再取天数
case when nvl(T.I_OD_AMT,0) + nvl(T.O_OD_AMT,0) > 0 and T.LXQKQS > 0 then T.LXQXTS
     else 0 
      end , -- 连续欠息天数  [20250519][巴启威]：表内外欠息>0，MTHS_ODUE当前逾期期数大于0时,再取天数
T.LJQBTS , -- 累积欠本天数   [20250513][狄家卉][JLBA202504060003][吴大为]: 信用卡集市新增累积欠本天数取数口径
T.LJQXTS , -- 累积欠息天数   [20250513][狄家卉][JLBA202504060003][吴大为]: 信用卡集市新增累积欠息天数取数口径
T.LXQKQS , -- 连续欠款期数
T.LJQKQS , -- 累计欠款期数
CASE
   WHEN LXQKQS = 0 THEN
     0
   ELSE
   T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP
   END, -- 欠本金额    [20250513][狄家卉][JLBA202504060003][吴大为]: 当MTHS_ODUE当前逾期期数为0时，欠本金额，欠息金额设置为0
CASE
   WHEN LXQKQS = 0 THEN
     0
   ELSE
   T.I_OD_AMT 
   END, -- 表内欠款利息 [20250513][狄家卉][JLBA202504060003][吴大为]: 当MTHS_ODUE当前逾期期数为0时，欠本金额，欠息金额设置为0
CASE
   WHEN LXQKQS = 0 THEN
     0
   ELSE
   T.O_OD_AMT
   end, -- 表外欠款利息 [20250513][狄家卉][JLBA202504060003][吴大为]: 当MTHS_ODUE当前逾期期数为0时，欠本金额，欠息金额设置为0
NVL(TO_CHAR(TO_DATE(T.P_OD_DATE,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') , -- 欠本日期
NVL(TO_CHAR(TO_DATE(T.I_OD_DATE,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') , -- 欠息日期
'9999-12-31', -- 终结日期
TO_CHAR(P_DATE,'YYYY-MM-DD'),   -- 13 '采集日期'
TO_CHAR(P_DATE,'YYYY-MM-DD'),   -- 13 '采集日期'
'009803' ,
'009803',
t.CURR_CD,
'信用卡1' as DIS_DEPT
 FROM SMTMODS.L_ACCT_CARD_CREDIT T -- 信用卡账户信息表
WHERE T.DATA_DATE = I_DATE  
  AND (T.ACCT_CLDATE >= I_DATE OR T.ACCT_CLDATE IS NULL)
-- add by haorui 20241119 JLBA202410090008信用卡收益权转让  start
  AND (T.DEALDATE = I_DATE OR T.DEALDATE ='00000000')   
  AND (nvl(T.ACCOUNTSTAT,0) <> 'C' OR (T.ACCOUNTSTAT = 'C' AND T.ACCT_CLDATE =I_DATE))  -- [20250415][姜俐锋][JLBA202502210009][吴大为]: 账户状态为销户的只取当日销户的
  AND T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP > 0 -- [20250619][巴启威][JLBA202505280002][吴大为]：信用卡部分，没有欠款的账号不报送在该表
  AND T.BQJHHKR IS NOT NULL -- [20250619][巴启威][JLBA202505280002][吴大为]：信用卡部分，可能存在新产生的欠款但是未到账单日没出账单的情况，与李逊昂确认，这部分也不报送
  AND NOT EXISTS (SELECT 1 FROM SMTMODS.L_ACCT_WRITE_OFF W WHERE W.DATA_DATE = I_DATE AND W.DATE_SOURCESD ='信用卡核销' AND T.ACCT_NUM=W.ACCT_NUM) -- [20250415][姜俐锋][JLBA202502200003][李逊昂,吴大为]: 去掉核销部分  
UNION ALL
	SELECT  
	T.CUST_ID,  -- 客户ID
	T.ACCT_NUM , -- 协议ID
	T.ACCT_NUM , -- 细分资产ID
	'B0302H22201009803', -- 机构ID
	'01' , --  按月     还本方式
	'01' , --  按月     还息方式
	'0'  , -- 本期还款期数
	NULL , -- 计划还款期数 20250225
	T.BQJHHKR , -- 本期计划还款日期 
	T.JHGHBJ , -- 本期计划归还本金金额
	T.JHGHLX , -- 本期计划归还利息金额
	NVL(T.YGHBJ,0) , -- 本期已归还本金
	NVL(T.YGHLX,0) , -- 本期已归还利息
	'0' , -- 累计展期次数
	case when T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP > 0 and T.LXQKQS > 0 then T.LXQBTS 
         else 0
         end , -- 连续欠本天数 [20250519][巴启威]：欠本金额>0，MTHS_ODUE当前逾期期数大于0时,再取天数
    case when nvl(T.I_OD_AMT,0) + nvl(T.O_OD_AMT,0) > 0 and T.LXQKQS > 0 then T.LXQXTS
         else 0 
         end , -- 连续欠息天数  [20250519][巴启威]：表内外欠息>0，MTHS_ODUE当前逾期期数大于0时,再取天数
	T.LJQBTS , -- 累积欠本天数 [20250513][狄家卉][JLBA202504060003][吴大为]: 信用卡集市新增累积欠本天数取数口径
	T.LJQXTS , -- 累积欠息天数 [20250513][狄家卉][JLBA202504060003][吴大为]: 信用卡集市新增累积欠息天数取数口径
	T.LXQKQS , -- 连续欠款期数
	T.LJQKQS , -- 累计欠款期数
    CASE
      WHEN LXQKQS = 0 THEN
       0
      ELSE
       T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP
      END, -- 欠本金额    [20250513][狄家卉][JLBA202504060003][吴大为]: 当MTHS_ODUE当前逾期期数为0时，欠本金额，欠息金额设置为0
    CASE
     WHEN LXQKQS = 0 THEN
      0
     ELSE
      T.I_OD_AMT 
     END, -- 表内欠款利息 [20250513][狄家卉][JLBA202504060003][吴大为]: 当MTHS_ODUE当前逾期期数为0时，欠本金额，欠息金额设置为0
    CASE
      WHEN LXQKQS = 0 THEN
       0
      ELSE
       T.O_OD_AMT
     END, -- 表外欠款利息 [20250513][狄家卉][JLBA202504060003][吴大为]: 当MTHS_ODUE当前逾期期数为0时，欠本金额，欠息金额设置为0
	NVL(TO_CHAR(TO_DATE(T.P_OD_DATE,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') , -- 欠本日期
	NVL(TO_CHAR(TO_DATE(T.I_OD_DATE,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') , -- 欠息日期
	'9999-12-31', -- 终结日期
	TO_CHAR(P_DATE,'YYYY-MM-DD'),   -- 13 '采集日期'
	TO_CHAR(P_DATE,'YYYY-MM-DD'),   -- 13 '采集日期'
	'009803' ,
	'009803',
	t.CURR_CD,
	'信用卡2' as DIS_DEPT
	 FROM SMTMODS.L_ACCT_CARD_CREDIT T -- 信用卡账户信息表
     LEFT JOIN SMTMODS.L_ACCT_DEPOSIT T3
	   ON T.DATA_DATE = T3.DATA_DATE
	  AND T.ACCT_NUM = T3.ACCT_NUM
	  AND T3.GL_ITEM_CODE ='20110111'
     LEFT JOIN SMTMODS.L_ACCT_DEPOSIT T4
	   ON T.ACCT_NUM = T4.ACCT_NUM
	  AND T4.DATA_DATE = LAST_DT
	  AND T4.GL_ITEM_CODE ='20110111'
	WHERE T.DATA_DATE = I_DATE  
	  AND (T.ACCT_CLDATE >= I_DATE OR T.ACCT_CLDATE IS NULL)
	  AND T.DEALDATE <> '00000000'   
	  AND (T4.ACCT_NUM IS NOT NULL OR T4.ACCT_NUM IS NULL AND T3.ACCT_NUM IS NOT NULL)  -- 前一天有溢款款 或 前一天无溢缴款当有有溢缴款
	-- add by haorui 20241119 JLBA202410090008信用卡收益权转让 end
	  AND (nvl(T.ACCOUNTSTAT,0) <> 'C' OR (T.ACCOUNTSTAT = 'C' AND T.ACCT_CLDATE =I_DATE))  -- [20250415][姜俐锋][JLBA202502210009][吴大为]: 账户状态为销户的只取当日销户的
      AND NOT EXISTS (SELECT 1 FROM SMTMODS.L_ACCT_WRITE_OFF W WHERE W.DATA_DATE = I_DATE AND W.DATE_SOURCESD ='信用卡核销' AND T.ACCT_NUM=W.ACCT_NUM) -- [20250415][姜俐锋][JLBA202502200003][李逊昂,吴大为]: 去掉核销部分   

;
COMMIT ;
                                
 CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
 
 SET P_START_DT = NOW();
 SET P_STEP_NO = P_STEP_NO + 1;
 SET P_DESCB = 'RPA数据插入';

-- RPA 债转股 + 非标
INSERT INTO T_8_15
         (
          H150001   , -- 01 '客户ID'
          H150002   , -- 02 '协议ID'
          H150003   , -- 03 '细分资产ID'
          H150027   , -- 27 '机构ID'
          H150004   , -- 04 '还本方式'
          H150005   , -- 05 '还息方式'
          H150006   , -- 06 '本期还款期数'
          H150007   , -- 07 '计划还款期数'
          H150008   , -- 08 '本期计划还款日期'
          H150009   , -- 09 '本期计划归还本金金额'
          H150010   , -- 10 '本期计划归还利息金额'
          H150011   , -- 11 '本期已归还本金'
          H150012   , -- 12 '本期已归还利息'
          H150013   , -- 13 '累计展期次数'
          H150014   , -- 14 '连续欠本天数'
          H150015   , -- 15 '连续欠息天数'
          H150016   , -- 16 '累积欠本天数'
          H150017   , -- 17 '累积欠息天数'
          H150018   , -- 18 '连续欠款期数'
          H150019   , -- 19 '累计欠款期数'
          H150020   , -- 20 '欠本金额'
          H150021   , -- 21 '表内欠款利息'
          H150022   , -- 22 '表外欠款利息'
          H150023   , -- 23 '欠本日期'
          H150024   , -- 24 '欠息日期'
          H150025   , -- 25 '终结日期'
          H150026   , -- 26 '采集日期' 
          DIS_DATA_DATE,
          DIS_BANK_ID,
          DEPARTMENT_ID ,
          H150028, -- 币种
          DIS_DEPT
           )  
 SELECT   H150001   , -- 01 '客户ID'
          H150002   , -- 02 '协议ID'
          H150003   , -- 03 '细分资产ID'
          H150027   , -- 27 '机构ID'
          SUBSTR (H150004,INSTR(H150004,'[',1,1) + 1 , INSTR(H150004, ']',1 ) -INSTR(H150004,'[',1,1) - 1 ) AS H150004   , -- 04 '还本方式'
          SUBSTR (H150005,INSTR(H150005,'[',1,1) + 1 , INSTR(H150005, ']',1 ) -INSTR(H150005,'[',1,1) - 1 ) AS H150005   , -- 05 '还息方式'
          H150006   , -- 06 '本期还款期数'
          H150007   , -- 07 '计划还款期数'
          H150008   , -- 08 '本期计划还款日期'
          TO_NUMBER(REPLACE(H150009,',','')) AS H150009   , -- 09 '本期计划归还本金金额'
          TO_NUMBER(REPLACE(H150010,',','')) AS H150010   , -- 10 '本期计划归还利息金额'
          NVL(H150011,0)   , -- 11 '本期已归还本金'
          NVL(H150012,0)   , -- 12 '本期已归还利息'
          H150013   , -- 13 '累计展期次数'
          H150014   , -- 14 '连续欠本天数'
          H150015   , -- 15 '连续欠息天数'
          H150016   , -- 16 '累积欠本天数'
          H150017   , -- 17 '累积欠息天数'
          H150018   , -- 18 '连续欠款期数'
          H150019   , -- 19 '累计欠款期数'
          TO_NUMBER(REPLACE(H150020,',','')) AS H150020   , -- 20 '欠本金额'
          TO_NUMBER(REPLACE(H150021,',','')) AS H150021   , -- 21 '表内欠款利息'
          H150022   , -- 22 '表外欠款利息'
          H150023   , -- 23 '欠本日期'
          H150024   , -- 24 '欠息日期'
          H150025   , -- 25 '终结日期'
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS H130023, -- 23 '采集日期'
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE, -- 装入数据日期
          '990000',
          SUBSTR ( DEPARTMENT_ID,INSTR(DEPARTMENT_ID,'[',1,1) + 1 , INSTR(DEPARTMENT_ID, ']',1 ) -INSTR(DEPARTMENT_ID,'[',1,1) - 1 ) AS DEPARTMENT_ID  ,     -- 业务条线
          SUBSTR (H150028,INSTR(H150028,'[',1,1) + 1 , INSTR(H150028, ']',1 ) -INSTR(H150028,'[',1,1) - 1 ) AS H150028,-- 币种
          '债转股'
     FROM ybt_datacore.RPAJ_8_15_HKZT A
    WHERE A.DATA_DATE =I_DATE; 
    COMMIT ;

    CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);

      -- 投管
    INSERT INTO T_8_15
         (
          H150001   , -- 01 '客户ID'
          H150002   , -- 02 '协议ID'
          H150003   , -- 03 '细分资产ID'
          H150027   , -- 27 '机构ID'
          H150004   , -- 04 '还本方式'
          H150005   , -- 05 '还息方式'
          H150006   , -- 06 '本期还款期数'
          H150007   , -- 07 '计划还款期数'
          H150008   , -- 08 '本期计划还款日期'
          H150009   , -- 09 '本期计划归还本金金额'
          H150010   , -- 10 '本期计划归还利息金额'
          H150011   , -- 11 '本期已归还本金'
          H150012   , -- 12 '本期已归还利息'
          H150013   , -- 13 '累计展期次数'
          H150014   , -- 14 '连续欠本天数'
          H150015   , -- 15 '连续欠息天数'
          H150016   , -- 16 '累积欠本天数'
          H150017   , -- 17 '累积欠息天数'
          H150018   , -- 18 '连续欠款期数'
          H150019   , -- 19 '累计欠款期数'
          H150020   , -- 20 '欠本金额'
          H150021   , -- 21 '表内欠款利息'
          H150022   , -- 22 '表外欠款利息'
          H150023   , -- 23 '欠本日期'
          H150024   , -- 24 '欠息日期'
          H150025   , -- 25 '终结日期'
          H150026   , -- 26 '采集日期' 
          DIS_DATA_DATE,
          DIS_BANK_ID,
          DEPARTMENT_ID ,
          H150028, -- 币种
          DIS_DEPT
           )  
    SELECT 
          H150001   , -- 01 '客户ID'
          H150002   , -- 02 '协议ID'
          H150003   , -- 03 '细分资产ID'
          H150027   , -- 27 '机构ID'
          SUBSTR (H150004,INSTR(H150004,'[',1,1) + 1 , INSTR(H150004, ']',1 ) -INSTR(H150004,'[',1,1) - 1 ) AS H150004   , -- 04 '还本方式'
          SUBSTR (H150005,INSTR(H150005,'[',1,1) + 1 , INSTR(H150005, ']',1 ) -INSTR(H150005,'[',1,1) - 1 ) AS H150005   , -- 05 '还息方式'
          H150006   , -- 06 '本期还款期数'
          H150007   , -- 07 '计划还款期数'
          H150008   , -- 08 '本期计划还款日期'
          TO_NUMBER(REPLACE(H150009,',','')) AS H150009   , -- 09 '本期计划归还本金金额'
          TO_NUMBER(REPLACE(H150010,',','')) AS H150010   , -- 10 '本期计划归还利息金额'
          NVL(H150011,0)   , -- 11 '本期已归还本金'
          NVL(H150012,0)   , -- 12 '本期已归还利息'
          H150013   , -- 13 '累计展期次数'
          H150014   , -- 14 '连续欠本天数'
          H150015   , -- 15 '连续欠息天数'
          H150016   , -- 16 '累积欠本天数'
          H150017   , -- 17 '累积欠息天数'
          H150018   , -- 18 '连续欠款期数'
          H150019   , -- 19 '累计欠款期数'
          TO_NUMBER(REPLACE(H150020,',','')) AS H150020   , -- 20 '欠本金额'
          TO_NUMBER(REPLACE(H150021,',','')) AS H150021   , -- 21 '表内欠款利息'
          H150022   , -- 22 '表外欠款利息'
          H150023   , -- 23 '欠本日期'
          H150024   , -- 24 '欠息日期'
          H150025   , -- 25 '终结日期'
          TO_CHAR(TO_DATE( I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS H130023, -- 23 '采集日期'
          TO_CHAR(TO_DATE( I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE, -- 装入数据日期
          '009806',
          SUBSTR ( H150030,INSTR(H150030,'[',1,1) + 1 , INSTR(H150030, ']',1 ) -INSTR(H150030,'[',1,1) - 1 ) AS DEPARTMENT_ID  ,     -- 业务条线
          SUBSTR (H150028,INSTR(H150028,'[',1,1) + 1 , INSTR(H150028, ']',1 ) -INSTR(H150028,'[',1,1) - 1 ) AS H150028,-- 币种
          '投管'
      FROM ybt_datacore.INTM_HKZT T
    WHERE T.DATA_DATE= I_DATE;
    COMMIT;
     
    -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求:新增当年终结的贷款最后一期还款数据，持续报送至年末
    -- 插入当年t-1终结的还款信息
    INSERT INTO T_8_15
         (
          H150001   , -- 01 '客户ID'
          H150002   , -- 02 '协议ID'
          H150003   , -- 03 '细分资产ID'
          H150027   , -- 27 '机构ID'
          H150004   , -- 04 '还本方式'
          H150005   , -- 05 '还息方式'
          H150006   , -- 06 '本期还款期数'
          H150007   , -- 07 '计划还款期数'
          H150008   , -- 08 '本期计划还款日期'
          H150009   , -- 09 '本期计划归还本金金额'
          H150010   , -- 10 '本期计划归还利息金额'
          H150011   , -- 11 '本期已归还本金'
          H150012   , -- 12 '本期已归还利息'
          H150013   , -- 13 '累计展期次数'
          H150014   , -- 14 '连续欠本天数'
          H150015   , -- 15 '连续欠息天数'
          H150016   , -- 16 '累积欠本天数'
          H150017   , -- 17 '累积欠息天数'
          H150018   , -- 18 '连续欠款期数'
          H150019   , -- 19 '累计欠款期数'
          H150020   , -- 20 '欠本金额'
          H150021   , -- 21 '表内欠款利息'
          H150022   , -- 22 '表外欠款利息'
          H150023   , -- 23 '欠本日期'
          H150024   , -- 24 '欠息日期'
          H150025   , -- 25 '终结日期'
          H150026   , -- 26 '采集日期' 
          DIS_DATA_DATE,
          DIS_BANK_ID,
          DEPARTMENT_ID ,
          H150028,-- 币种
          DIS_DEPT
         )  
         SELECT 
          T1.H150001   , -- 01 '客户ID'
          T1.H150002   , -- 02 '协议ID'
          T1.H150003   , -- 03 '细分资产ID'
          T1.H150027   , -- 27 '机构ID'
          T1.H150004   , -- 04 '还本方式'
          T1.H150005   , -- 05 '还息方式'
          T1.H150006   , -- 06 '本期还款期数'
          T1.H150007   , -- 07 '计划还款期数'
          T1.H150008   , -- 08 '本期计划还款日期'
          T1.H150009   , -- 09 '本期计划归还本金金额'
          T1.H150010   , -- 10 '本期计划归还利息金额'
          T1.H150011   , -- 11 '本期已归还本金'
          T1.H150012   , -- 12 '本期已归还利息'
          T1.H150013   , -- 13 '累计展期次数'
          T1.H150014   , -- 14 '连续欠本天数'
          T1.H150015   , -- 15 '连续欠息天数'
          T1.H150016   , -- 16 '累积欠本天数'
          T1.H150017   , -- 17 '累积欠息天数'
          T1.H150018   , -- 18 '连续欠款期数'
          T1.H150019   , -- 19 '累计欠款期数'
          T1.H150020   , -- 20 '欠本金额'
          T1.H150021   , -- 21 '表内欠款利息'
          T1.H150022   , -- 22 '表外欠款利息'
          T1.H150023   , -- 23 '欠本日期'
          T1.H150024   , -- 24 '欠息日期'
          T1.H150025   , -- 25 '终结日期'
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')    , -- 26 '采集日期' 
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')    ,
          T1.DIS_BANK_ID,
          T1.DEPARTMENT_ID ,
          T1.H150028,-- 币种
          T1.DIS_DEPT
          FROM T_8_15_FINISH T1
         WHERE SUBSTR(T1.H150026,1,4) = SUBSTR(I_DATE,1,4)  -- 报送日期为当年
           AND T1.H150025 <= TO_DATE(I_DATE,'YYYYMMDD')-1
         ;
    
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

