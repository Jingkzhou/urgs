CREATE OR REPLACE PROCEDURE PROC_CBRC_IDX2_G3301_DWD(II_DATADATE IN STRING --跑批日期
                                              )
/******************************
  @author:DJH  存款贷款逻辑修正
  @create-date:20220606
  @description:G3301
  @modification history:
  m0.author-create_date-description
  add by djh 20220704 只取人民币数据
  贷款去掉130604本金，对应利息不计利息
  存款去掉
  '20110111',个人信用卡存款
  '20110206',单位信用卡存款
  '20130101',应解汇票款项
  '20130201',临时存款
  '20130301',应解本票款项
  '20140101',开出汇票签发户
  '20140201',开出汇票移存户
  '20140301'开出汇票逾期未用退回户 科目本金，对应利息不计利息
  M1 20231215 上游信贷修改下一利率重定价日,导致数据情况变更，修改本表逻辑
  --    需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-27，修改人：石雨，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
  需求编号：JLBA202503070010_关于吉林银行统一监管报送平台升级的需求 上线日期： 2025-12-26，修改人：狄家卉，提出人：统一监管报送平台升级  修改原因：由汇总数据修改为明细以及汇总
    --需求编号：JLBA202504160004_关于吉林银行修改单一客户授信逻辑的需求 提出人：苏桐  上线时间：20250627 修改人：石雨 修改内容：客户授信逻辑
--[JLBA202507210012_关于调整财政性存款及一般性存款相关科目统计方式的相关需求][提出人：于佳禾][上线时间：20250918][修改人：石雨][修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]

PM_RSDATA.CBRC_A_REPT_DWD_G3301
PM_RSDATA.CBRC_A_REPT_ITEM_VAL
PM_RSDATA.CBRC_FDM_LNAC
PM_RSDATA.CBRC_FDM_LNAC_GL
PM_RSDATA.CBRC_FDM_LNAC_PMT
PM_RSDATA.CBRC_FDM_LNAC_PMT_BJ_Q
PM_RSDATA.CBRC_FDM_LNAC_PMT_LLCDJR
PM_RSDATA.CBRC_FDM_LNAC_PMT_LX
PM_RSDATA.CBRC_FDM_LNAC_PMT_LX_Q
PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP
PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKBJ
PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKLX
PM_RSDATA.CBRC_ID_G3301_ITEMDATA_DKBJ
PM_RSDATA.CBRC_ID_G3301_ITEMDATA_DKLX
PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI
PM_RSDATA.CBRC_ITEM_CD_TEMP
PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1_Q
PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP_Q
PM_RSDATA.CBRC_JTDP_INTERF_PAYHSRCCASHYIELD
PM_RSDATA.CBRC_JTDP_INTERF_PAYHSRCCASHYIELD_G3301
PM_RSDATA.CBRC_K_G3301
PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL
PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL
PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL
PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT
PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_SCALE_QQ
PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL
PM_RSDATA.SMTMODS_A_REPT_DWD_MAPPING
PM_RSDATA.SMTMODS_L_ACCT_CARD_CREDIT
PM_RSDATA.SMTMODS_L_ACCT_LOAN
PM_RSDATA.SMTMODS_L_AGRE_BOND_INFO
PM_RSDATA.SMTMODS_L_AGRE_CREDITLINE
PM_RSDATA.SMTMODS_L_CUST_BILL_TY
PM_RSDATA.SMTMODS_L_CUST_C
PM_RSDATA.SMTMODS_L_CUST_EXTERNAL_INFO
PM_RSDATA.SMTMODS_L_CUST_P
PM_RSDATA.SMTMODS_L_PUBL_HOLIDAY
PM_RSDATA.SMTMODS_L_PUBL_RATE
PM_RSDATA.SMTMODS_V_PUB_FUND_CDS_BAL
PM_RSDATA.CBRC_V_PUB_FUND_INVEST
PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL

  *******************************/

 AS
  V_PROCEDURE    VARCHAR2(32) DEFAULT NULL; --字符型  存储过程名称
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  I_DATADATE     STRING; --数据日期(数值型)YYYYMMDD
  D_DATADATE_CCY STRING; --数据日期(日期型)YYYYMMDD
  V_TAB_NAME     VARCHAR(30); --目标表名
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_TAB_NAME1    VARCHAR(30); --目标表名
  V_ERRORDESC    VARCHAR(280); --错误内容
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM       VARCHAR(30);
  
BEGIN
  set_env('inceptor.idempotent.check.exception', 'false');  --为了设置uuid不报错，uuid即幂等性，“幂等性检查异常”的配置项设置为 false，即在幂等性检查失败时不会抛出异常，而是允许系统继续执行后续操作
  
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';

    I_DATADATE     := II_DATADATE;
    D_DATADATE_CCY := I_DATADATE;
    V_SYSTEM       := 'CBRC';
    V_PROCEDURE    := UPPER('PROC_CBRC_IDX2_G3301_DWD');
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_TAB_NAME  := 'PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI';
    V_TAB_NAME1 := 'PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP';
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']表历史数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME1 || ']表历史数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --资产
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_FDM_LNAC_PMT_LLCDJR'; --浮动利率重定价日正常明细
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_FDM_LNAC_PMT_BJ_Q'; --零售+小微企业小于1000万本金1.2明细数据
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_FDM_LNAC_PMT_LX_Q'; --零售+小微企业小于1000利息1.2明细数据
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_ID_G3301_ITEMDATA_DKBJ'; --贷款本金期限汇总数据
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_ID_G3301_ITEMDATA_DKLX'; --贷款利息期限汇总数据

    --负债
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_SCALE_QQ'; --大中小微客户规模划分
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKBJ';--存款本金期限汇总数据
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKLX'; --存款利息期限汇总数据

    --利息补差值
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1_Q'; --科目明细差异对应补录期限
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP_Q'; --科目与明细差值表

    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI'; --本金+利息期限数据汇总
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP'; --指标数据

    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_JTDP_INTERF_PAYHSRCCASHYIELD_G3301'; --收益率曲线中间表

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 2;
    V_STEP_DESC := '初始化临时表数据';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    DELETE FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL T
     WHERE T.REP_NUM = 'G33'
       AND DATA_DATE = I_DATADATE;
    COMMIT;


    -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_A_REPT_DWD_G3301';

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    INSERT INTO PM_RSDATA.CBRC_JTDP_INTERF_PAYHSRCCASHYIELD_G3301
      (ID, MTRTY, YLD, YL)
      SELECT ID AS ID,
             MTRTY AS MTRTY,
             YLD AS YLD,
             CASE
                WHEN ID = '1' THEN 0 / 12
                WHEN ID = '2' THEN 1 / 12
                WHEN ID = '3' THEN 3 / 12
                WHEN ID = '4' THEN 6 / 12
                WHEN ID = '5' THEN 9 / 12
                WHEN ID = '6' THEN 1
                WHEN ID = '7' THEN 2
                WHEN ID = '8' THEN 3
                WHEN ID = '9' THEN 4
                WHEN ID = '10' THEN 5
                WHEN ID = '11' THEN 6
                WHEN ID = '12' THEN 7
                WHEN ID = '13' THEN 8
                WHEN ID = '14' THEN 9
                WHEN ID = '15' THEN 10
                WHEN ID = '16' THEN 15
                WHEN ID = '17' THEN 20
                WHEN ID = '18' THEN 30
                WHEN ID = '19' THEN 40
                WHEN ID = '20' THEN 50
                ELSE 0
              END AS YL
        FROM (SELECT uuid() AS ID, T.MTRTY AS MTRTY, T.YLD AS YLD
                FROM PM_RSDATA.CBRC_JTDP_INTERF_PAYHSRCCASHYIELD T
               WHERE T.CURVE_NAME = '中债国债收益率曲线'
                 AND T.CURVE_TYPE = '01' --曲线类型 ：即期
                 AND T.MTRTY <> 0.1700
                 AND T.DATA_DATE = I_DATADATE
               ORDER BY T.MTRTY)
       ORDER BY ID;
    COMMIT;
    --=============================================== 存款==============================================
    --整体处理思路如下：
    --G3301存款口径正常存款本金、利息+存款所有逾期；存款不可提前支取部分处理方式参考G2501，其他整理逻辑与G21相同

    --2.1 不考虑行为性期权的负债
    --2.1.3 定期存款
    --2.1.3.1 其中：以人民银行基准利率为定价基础的存款 (不可提前支取部分与与G2501相同，251保证金、存单质押、206国库定期、20504转股协议存款，219结构性存款本金+利息)
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：2.1.3.1 其中：以人民银行基准利率为定价基础的存款本金数据进ID_G3301_ITEMDATA_CKBJ中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKBJ 
      (ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T) --20年以上
      SELECT T1.ORG_NUM,
             I_DATADATE,
             T1.GL_ITEM_CODE,
             'G33_1_2.1.3.1' AS LOCAL_STATION,
             SUM(CASE
                   WHEN  REMAIN_TERM_CODE_QX = 1 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_B,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX IS NULL OR (REMAIN_TERM_CODE_QX < 1) OR (REMAIN_TERM_CODE_QX BETWEEN 2 AND 30) THEN  --与G21不同，期限为空，逾期放在隔夜-一个月（含）
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_C,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 31 AND 90 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_D,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 91 AND 180 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_E,

             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 181 AND 270 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_F,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 271 AND 360 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_G,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 361 AND 540 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_H,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 541 AND 720 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_I,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 721 AND 1080 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_J,

             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 1081 AND 1440 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_K,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 1441 AND 1800 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_L,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 1801 AND 360 * 6 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_M,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_N,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_O,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_P,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_Q,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 10 + 1 AND 360 * 15 THEN

                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_R,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_S,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX > 360 * 20 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_T
        FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT T1
       WHERE T1.DATA_DATE = I_DATADATE
        AND T1.SIGN IN ('A', 'B', 'D')--1保证金，2存单质押  3、国库定期，转股协议等
        AND T1.ACCT_CUR='CNY'
       GROUP BY T1.ORG_NUM, T1.GL_ITEM_CODE;
   COMMIT;

   --有奖储蓄放在G33_1_2.1.3.1 隔夜-一个月（含）
  
    --通知存款 放在G33_1_2.1.3.1 隔夜-一个月（含）
    INSERT 
    INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKBJ 
      (ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T) --20年以上
      SELECT 
       T1.ORG_NUM,
       I_DATADATE,
       T1.GL_ITEM_CODE,
       'G33_1_2.1.3.1' AS LOCAL_STATION,
       SUM(CASE
             WHEN REMAIN_TERM_CODE_QX = 1 THEN
              ACCT_BAL_RMB
             ELSE
              0
           END) AS AMOUNT_B, --只有1日通知的放在隔夜
       SUM(CASE
             WHEN REMAIN_TERM_CODE_QX = 7 THEN
              ACCT_BAL_RMB
             ELSE
              0
           END) AS AMOUNT_C,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T1
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.GL_ITEM_CODE IN ('20110205', '20110110')
         AND T1.ACCT_CUR='CNY'
       GROUP BY T1.ORG_NUM, T1.GL_ITEM_CODE;

    COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：2.1.3.1 其中：以人民银行基准利率为定价基础的存款本金数据进ID_G3301_ITEMDATA_CKBJ中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：2.2 无到期日存款本金数据进ID_G3301_ITEMDATA_CKBJ中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --2.2 无到期日存款(活期存款本金+利息)  在上面已经存在的还要去掉
    INSERT 
    INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKBJ 
      (ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T) --20年以上
      SELECT T1.ORG_NUM,
             I_DATADATE,
             T1.GL_ITEM_CODE,
             'G33_1_2.2.B.2019' AS LOCAL_STATION,
             SUM(T1.ACCT_BAL_RMB) AS AMOUNT_B,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T1
        LEFT JOIN (SELECT DISTINCT ACCT_NUM
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT
                    WHERE DATA_DATE = I_DATADATE
                      AND SIGN IN ('A', 'B', 'D')) T2 --去掉不可提前支取部分以外的活期存款
          ON T2.ACCT_NUM = T1.ACCT_NUM
         LEFT JOIN (SELECT DISTINCT ACCT_NUM
                            FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL T1
                           WHERE DATA_DATE = I_DATADATE
                             AND  FLAG_CODE = '03') T3 --去掉个体工商户存款(含有'201'的给工商户去掉，在2.2，2.3统计)
                  ON T3.ACCT_NUM = T1.ACCT_NUM
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.ACCT_NUM IS NULL
         AND T3.ACCT_NUM IS NULL
         AND (T1.GL_ITEM_CODE IN
             ('20110201', '20110101','20110102'/*, '217', '218', '243', '244'*/) OR
             T1.GL_ITEM_CODE = '20120106'
              OR T1.GL_ITEM_CODE IN ('22410101','20110301','20110302','20110303','22410102','20080101','20090101') --[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
             )  --与G21活期存款口径保持一致
         AND T1.ACCT_CUR='CNY'
          GROUP BY T1.ORG_NUM, T1.GL_ITEM_CODE;

   COMMIT;

   --个体工商户中活期部分放在2.2，定期部分放在2.3
   INSERT 
   INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKBJ 
     (ORGNO,
      RQ,
      SUBJECT,
      LOCAL_STATION,
      AMOUNT_B, --隔夜
      AMOUNT_C, --隔夜-一个月（含）
      AMOUNT_D, --1个月-3个月（含）
      AMOUNT_E, --3个月-6个月（含）
      AMOUNT_F, --6个月-9个月(含)
      AMOUNT_G, --9个月-1年(含)
      AMOUNT_H, --1年-1.5年(含)
      AMOUNT_I, --1.5年-2年(含)
      AMOUNT_J, --2年-3年(含)
      AMOUNT_K, --3年-4年(含)
      AMOUNT_L, --4年-5年(含)
      AMOUNT_M, --5年-6年(含)
      AMOUNT_N, --6年-7年(含)
      AMOUNT_O, --7年-8年(含)
      AMOUNT_P, --8年-9年(含)
      AMOUNT_Q, --9年-10年(含)
      AMOUNT_R, --10年-15年(含)
      AMOUNT_S, --15年-20年(含)
      AMOUNT_T) --20年以上
     SELECT 
      T1.ORG_NUM,
      I_DATADATE,
      T1.GL_ITEM_CODE,
      'G33_1_2.2.B.2019' AS LOCAL_STATION,
      SUM(T1.ACCT_BAL_RMB) AS AMOUNT_B,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0
       FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL T1
      WHERE FLAG_CODE = '03' --个体工商户存款
        AND DATA_DATE = I_DATADATE
        AND (T1.GL_ITEM_CODE IN
            ('20110201', '20110101','20110102'/*, '217', '218', '243', '244'*/) OR
            T1.GL_ITEM_CODE = '20120106'
            OR T1.GL_ITEM_CODE IN ('22410101','20110301','20110302','20110303','22410102','20080101','20090101') --[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
            ) --与G21活期存款口径保持一致
        AND T1.ACCT_CUR='CNY'
      GROUP BY T1.ORG_NUM, T1.GL_ITEM_CODE;

   COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：2.2 无到期日存款本金数据进ID_G3301_ITEMDATA_CKBJ中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：零售或者批发企业规模数据进TMP_DEPOSIT_WD_ACCT_SCALE_QQ中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  --去掉以上数据剩余部分，按照800万划分零售或者批发
    INSERT 
    INTO PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_SCALE_QQ 
      (DATA_DATE, ACCT_NUM, BAL_TOTAL, CUST_ID, GL_ITEM_CODE, REAL_SCALE)
      SELECT 
       I_DATADATE,
       ACCT_NUM,
       BAL_TOTAL,
       CUST_ID,
       GL_ITEM_CODE,
       CASE
         WHEN BAL_TOTAL <= 8000000 THEN
          'ST' --可提前支取的定期零售类存款
         ELSE
          'BM' --可提前支取的定期批发类存款
       END AS REAL_SCALE
        FROM (SELECT DISTINCT T.ACCT_NUM,
                              T.CUST_ID,
                              T.GL_ITEM_CODE,
                              SUM(T.ACCT_BAL_RMB) OVER(PARTITION BY T.CUST_ID) AS BAL_TOTAL
                FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T
                LEFT JOIN (SELECT DISTINCT ACCT_NUM
                            FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT
                           WHERE DATA_DATE = I_DATADATE
                             AND SIGN IN ('A', 'B', 'D')) T2 --去掉不可提前支取部分以外
                  ON T2.ACCT_NUM = T.ACCT_NUM
               WHERE T.DATA_DATE = I_DATADATE
                 AND T2.ACCT_NUM IS NULL
                 AND (T.GL_ITEM_CODE IN
                     (/*'202',
                       '203',*/ --通知存款放在 2.1.3.1隔夜-一个月（含），不在此处统计
                       '20110202',
                       '20110203',
                       '20110204',
                       '20110211',
                       '20110701',
                       '20110103',
                       '20110104',
                       '20110105',
                       '20110106',
                       '20110107',
                       '20110108',
                       '20110109',
                       '20110208',
                       '20110113',
                       '20110114',
                       '20110115',
                       '20110209',
                       '20110210',
                       '20110207',
                       '20110112') OR T.GL_ITEM_CODE = '20120204'
                       --    需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：石雨，提出人：王曦若 ，修改内容：20110701 改成 2010
                      OR T.GL_ITEM_CODE LIKE  '2010%'
                       )
                 AND T.ACCT_NUM NOT IN
                     (SELECT ACCT_NUM
                        FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL
                       WHERE FLAG_CODE = '03'
                         AND DATA_DATE = I_DATADATE) --去掉个体工商户放在零售部分数据
                 AND T.ACCT_CUR='CNY'

              ) T;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：零售或者批发企业规模数据进TMP_DEPOSIT_WD_ACCT_SCALE_QQ中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：2.3 可提前支取的定期零售类存款本金数据进ID_G3301_ITEMDATA_CKBJ中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --2.3 可提前支取的定期零售类存款
    INSERT 
    INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKBJ 
      (ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T) --20年以上
      SELECT T1.ORG_NUM,
             I_DATADATE,
             T1.GL_ITEM_CODE,
             'G33_1_2.3' AS LOCAL_STATION,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <= 1 THEN --空值或逾期放在隔夜同G21
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_B,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 2 AND 30 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_C,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 31 AND 90 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_D,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 91 AND 180 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_E,

             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 181 AND 270 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_F,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 271 AND 360 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_G,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 361 AND 540 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_H,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 541 AND 720 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_I,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 721 AND 1080 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_J,

             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 1081 AND 1440 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_K,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 1441 AND 1800 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_L,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 1801 AND 360 * 6 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_M,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_N,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_O,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_P,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_Q,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 10 + 1 AND 360 * 15 THEN

                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_R,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_S,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX > 360 * 20 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_T
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T1
       INNER JOIN (SELECT DISTINCT ACCT_NUM
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_SCALE_QQ
                    WHERE DATA_DATE = I_DATADATE
                      AND REAL_SCALE = 'ST') T2
          ON T1.ACCT_NUM = T2.ACCT_NUM
       WHERE T1.DATA_DATE = I_DATADATE
       AND T1.ACCT_CUR='CNY'
       GROUP BY T1.ORG_NUM, T1.GL_ITEM_CODE;
  COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：2.3 可提前支取的定期零售类存款本金数据进ID_G3301_ITEMDATA_CKBJ中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：2.3 可提前支取的定期零售类(个体工商户存款)数据进ID_G3301_ITEMDATA_CKBJ中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
   ----个体工商户存款 定期部分放在2.3
   INSERT 
   INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKBJ 
     (ORGNO,
      RQ,
      SUBJECT,
      LOCAL_STATION,
      AMOUNT_B, --隔夜
      AMOUNT_C, --隔夜-一个月（含）
      AMOUNT_D, --1个月-3个月（含）
      AMOUNT_E, --3个月-6个月（含）
      AMOUNT_F, --6个月-9个月(含)
      AMOUNT_G, --9个月-1年(含)
      AMOUNT_H, --1年-1.5年(含)
      AMOUNT_I, --1.5年-2年(含)
      AMOUNT_J, --2年-3年(含)
      AMOUNT_K, --3年-4年(含)
      AMOUNT_L, --4年-5年(含)
      AMOUNT_M, --5年-6年(含)
      AMOUNT_N, --6年-7年(含)
      AMOUNT_O, --7年-8年(含)
      AMOUNT_P, --8年-9年(含)
      AMOUNT_Q, --9年-10年(含)
      AMOUNT_R, --10年-15年(含)
      AMOUNT_S, --15年-20年(含)
      AMOUNT_T) --20年以上
     SELECT T1.ORG_NUM,
            I_DATADATE,
            T1.GL_ITEM_CODE,
            'G33_1_2.3' AS LOCAL_STATION,
            SUM(CASE
                  WHEN REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <= 1 THEN --空值或逾期放在隔夜同G21
                   ACCT_BAL_RMB
                  ELSE
                   0
                END) AS AMOUNT_B,
            SUM(CASE
                  WHEN REMAIN_TERM_CODE_QX BETWEEN 2 AND 30 THEN
                   ACCT_BAL_RMB
                  ELSE
                   0
                END) AS AMOUNT_C,
            SUM(CASE
                  WHEN REMAIN_TERM_CODE_QX BETWEEN 31 AND 90 THEN
                   ACCT_BAL_RMB
                  ELSE
                   0
                END) AS AMOUNT_D,
            SUM(CASE
                  WHEN REMAIN_TERM_CODE_QX BETWEEN 91 AND 180 THEN
                   ACCT_BAL_RMB
                  ELSE
                   0
                END) AS AMOUNT_E,

            SUM(CASE
                  WHEN REMAIN_TERM_CODE_QX BETWEEN 181 AND 270 THEN
                   ACCT_BAL_RMB
                  ELSE
                   0
                END) AS AMOUNT_F,
            SUM(CASE
                  WHEN REMAIN_TERM_CODE_QX BETWEEN 271 AND 360 THEN
                   ACCT_BAL_RMB
                  ELSE
                   0
                END) AS AMOUNT_G,
            SUM(CASE
                  WHEN REMAIN_TERM_CODE_QX BETWEEN 361 AND 540 THEN
                   ACCT_BAL_RMB
                  ELSE
                   0
                END) AS AMOUNT_H,
            SUM(CASE
                  WHEN REMAIN_TERM_CODE_QX BETWEEN 541 AND 720 THEN
                   ACCT_BAL_RMB
                  ELSE
                   0
                END) AS AMOUNT_I,
            SUM(CASE
                  WHEN REMAIN_TERM_CODE_QX BETWEEN 721 AND 1080 THEN
                   ACCT_BAL_RMB
                  ELSE
                   0
                END) AS AMOUNT_J,

            SUM(CASE
                  WHEN REMAIN_TERM_CODE_QX BETWEEN 1081 AND 1440 THEN
                   ACCT_BAL_RMB
                  ELSE
                   0
                END) AS AMOUNT_K,
            SUM(CASE
                  WHEN REMAIN_TERM_CODE_QX BETWEEN 1441 AND 1800 THEN
                   ACCT_BAL_RMB
                  ELSE
                   0
                END) AS AMOUNT_L,
            SUM(CASE
                  WHEN REMAIN_TERM_CODE_QX BETWEEN 1801 AND 360 * 6 THEN
                   ACCT_BAL_RMB
                  ELSE
                   0
                END) AS AMOUNT_M,
            SUM(CASE
                  WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
                   ACCT_BAL_RMB
                  ELSE
                   0
                END) AS AMOUNT_N,
            SUM(CASE
                  WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
                   ACCT_BAL_RMB
                  ELSE
                   0
                END) AS AMOUNT_O,
            SUM(CASE
                  WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
                   ACCT_BAL_RMB
                  ELSE
                   0
                END) AS AMOUNT_P,
            SUM(CASE
                  WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
                   ACCT_BAL_RMB
                  ELSE
                   0
                END) AS AMOUNT_Q,
            SUM(CASE
                  WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 10 + 1 AND 360 * 15 THEN

                   ACCT_BAL_RMB
                  ELSE
                   0
                END) AS AMOUNT_R,
            SUM(CASE
                  WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
                   ACCT_BAL_RMB
                  ELSE
                   0
                END) AS AMOUNT_S,
            SUM(CASE
                  WHEN REMAIN_TERM_CODE_QX > 360 * 20 THEN
                   ACCT_BAL_RMB
                  ELSE
                   0
                END) AS AMOUNT_T
       FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL T1
      WHERE FLAG_CODE = '03'  --个体工商户存款
        AND DATA_DATE = I_DATADATE
        AND (T1.GL_ITEM_CODE IN
                      (/*'202',
                       '203',*/ --通知存款放在 2.1.3.1隔夜-一个月（含），不在此处统计
                       '20110202',
                       '20110203',
                       '20110204',
                       '20110211',
                       '20110701',
                       '20110103',
                       '20110104',
                       '20110105',
                       '20110106',
                       '20110107',
                       '20110108',
                       '20110109',
                       '20110208',
                       '20110113',
                       '20110114',
                       '20110115',
                       '20110209',
                       '20110210',
                       '20110207',
                       '20110112')
                        --    需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：石雨，提出人：王曦若 ，修改内容：20110701 改成 2010
                      OR T1.GL_ITEM_CODE LIKE  '2010%'
                       OR T1.GL_ITEM_CODE = '20120204'
                       ) --限定定期存款，与G21定期存款同
        AND T1.ACCT_CUR='CNY'
        GROUP BY T1.ORG_NUM, T1.GL_ITEM_CODE;
  COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：2.3 可提前支取的定期零售类(个体工商户存款)数据进ID_G3301_ITEMDATA_CKBJ中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：2.4 可提前支取的定期批发类存款本金数据进ID_G3301_ITEMDATA_CKBJ中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --2.4 可提前支取的定期批发类存款(对公客户存款余额大于800万的为批发客户)
   INSERT 
    INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKBJ 
      (ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T) --20年以上
      SELECT T1.ORG_NUM,
             I_DATADATE,
             T1.GL_ITEM_CODE,
             'G33_1_2.4' AS LOCAL_STATION,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <= 1 THEN --空值或逾期放在隔夜同G21
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_B,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 2 AND 30 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_C,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 31 AND 90 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_D,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 91 AND 180 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_E,

             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 181 AND 270 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_F,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 271 AND 360 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_G,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 361 AND 540 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_H,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 541 AND 720 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_I,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 721 AND 1080 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_J,

             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 1081 AND 1440 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_K,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 1441 AND 1800 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_L,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 1801 AND 360 * 6 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_M,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_N,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_O,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_P,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_Q,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 10 + 1 AND 360 * 15 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_R,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_S,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX > 360 * 20 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_T
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T1
       INNER JOIN (SELECT DISTINCT ACCT_NUM
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_SCALE_QQ
                    WHERE DATA_DATE = I_DATADATE
                      AND REAL_SCALE = 'BM') T2
          ON T1.ACCT_NUM = T2.ACCT_NUM
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ACCT_CUR='CNY'
       GROUP BY T1.ORG_NUM, T1.GL_ITEM_CODE;
  COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：2.4 可提前支取的定期批发类存款本金数据进ID_G3301_ITEMDATA_CKBJ中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
     --=============================================== 存款利息==============================================

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：2.1.3.1 其中：以人民银行基准利率为定价基础的存款利息数据进ID_G3301_ITEMDATA_CKLX中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT 
    INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKLX 
      (ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T) --20年以上
      SELECT T1.ORG_NUM,
             I_DATADATE,
             T1.GL_ITEM_CODE,
             'G33_1_2.1.3.1' AS LOCAL_STATION,
             SUM(CASE
                   WHEN  T1.MATUR_DATE_ACCURED - I_DATADATE  = 1 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_B,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED IS NULL OR (T1.MATUR_DATE_ACCURED - I_DATADATE<1) OR (T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 2 AND 30) THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_C,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 31 AND 90 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_D,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 91 AND 180 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_E,

             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 181 AND 270 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_F,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 271 AND 360 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_G,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 361 AND 540 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_H,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 541 AND 720 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_I,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 721 AND 1080 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_J,

             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 1081 AND 1440 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_K,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 1441 AND 1800 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_L,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_M,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_N,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_O,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_P,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_Q,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 10 + 1 AND 360 * 15 THEN

                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_R,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_S,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE > 360 * 20 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_T
          FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T1
       INNER JOIN (SELECT DISTINCT ACCT_NUM
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT
                    WHERE DATA_DATE = I_DATADATE
                       AND SIGN IN ('A', 'B', 'D')
                       AND ACCT_CUR='CNY') T2 --1保证金存款，2存单质押 ,3国库定期转股协议等
          ON T2.ACCT_NUM = T1.ACCT_NUM
       WHERE T1.DATA_DATE = I_DATADATE
         GROUP BY T1.ORG_NUM, T1.GL_ITEM_CODE;

   COMMIT;

     --通知存款利息 放在G33_1_2.1.3.1 隔夜-一个月（含）
    INSERT 
    INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKLX 
      (ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T) --20年以上
      SELECT 
       T1.ORG_NUM,
       I_DATADATE,
       T1.GL_ITEM_CODE,
       'G33_1_2.1.3.1' AS LOCAL_STATION,
       SUM(CASE
             WHEN REMAIN_TERM_CODE_QX = 1 THEN
              NVL(INTEREST_ACCURED, 0) + NVL(INTEREST_ACCURAL, 0)
             ELSE
              0
           END) AS AMOUNT_B,  --只有1日通知的放在隔夜
       SUM(CASE
             WHEN REMAIN_TERM_CODE_QX = 7 THEN
              NVL(INTEREST_ACCURED, 0) + NVL(INTEREST_ACCURAL, 0)
             ELSE
              0
           END) AS AMOUNT_C,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T1
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.GL_ITEM_CODE IN ('20110205', '20110110')
         AND T1.ACCT_CUR='CNY'
       GROUP BY T1.ORG_NUM, T1.GL_ITEM_CODE;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：2.1.3.1 其中：以人民银行基准利率为定价基础的存款利息数据进ID_G3301_ITEMDATA_CKLX中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：2.2 无到期日存款利息数据进ID_G3301_ITEMDATA_CKLX中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --2.2 无到期日存款
    INSERT 
    INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKLX 
      (ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T) --20年以上
      SELECT T1.ORG_NUM,
             I_DATADATE,
             T1.GL_ITEM_CODE,
             'G33_1_2.2.B.2019' AS LOCAL_STATION,
             SUM(NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)) AS AMOUNT_B,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T1
        LEFT JOIN (SELECT DISTINCT ACCT_NUM
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT
                    WHERE DATA_DATE = I_DATADATE
                      AND SIGN IN ('A', 'B', 'D')) T2 --去掉不可提前支取部分以外的活期存款
          ON T2.ACCT_NUM = T1.ACCT_NUM
         LEFT JOIN (SELECT DISTINCT ACCT_NUM
                            FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL T1
                           WHERE DATA_DATE = I_DATADATE
                             AND  FLAG_CODE = '03') T3 --去掉个体工商户存款(含有'201'的给工商户去掉，在2.3统计)
                  ON T3.ACCT_NUM = T1.ACCT_NUM
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.ACCT_NUM IS NULL
         AND T3.ACCT_NUM IS NULL
         AND (T1.GL_ITEM_CODE IN
             ('20110201', '20110101','20110102'/*, '217', '218', '243', '244'*/) OR
             T1.GL_ITEM_CODE = '20120106'
              OR T1.GL_ITEM_CODE IN ('22410101','20110301','20110302','20110303','22410102','20080101','20090101') --[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
           
             )  --与G21活期存款口径保持一致
         AND T1.ACCT_CUR='CNY'
         GROUP BY T1.ORG_NUM, T1.GL_ITEM_CODE;

   COMMIT;
   --个体工商户活期部分
    INSERT 
    INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKLX 
      (ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T) --20年以上
      SELECT T1.ORG_NUM,
             I_DATADATE,
             T1.GL_ITEM_CODE,
             'G33_1_2.2.B.2019' AS LOCAL_STATION,
             SUM(NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)) AS AMOUNT_B,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0,
             0
     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL T1
      WHERE FLAG_CODE = '03'  --个体工商户存款
        AND DATA_DATE = I_DATADATE
         AND (T1.GL_ITEM_CODE IN
             ('20110201', '20110101','20110102'/*, '217', '218', '243', '244'*/) OR
             T1.GL_ITEM_CODE = '20120106'
              OR T1.GL_ITEM_CODE IN ('22410101','20110301','20110302','20110303','22410102','20080101','20090101') --[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
           
             )  --与G21活期存款口径保持一致
        AND T1.ACCT_CUR='CNY'
        GROUP BY T1.ORG_NUM, T1.GL_ITEM_CODE;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：2.2 无到期日存款利息数据进ID_G3301_ITEMDATA_CKLX中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：2.3 可提前支取的定期零售类存款利息数据进ID_G3301_ITEMDATA_CKLX中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --2.3 可提前支取的定期零售类存款
    INSERT 
    INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKLX 
      (ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T) --20年以上
      SELECT T1.ORG_NUM,
             I_DATADATE,
             T1.GL_ITEM_CODE,
             'G33_1_2.3' AS LOCAL_STATION,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED IS NULL OR T1.MATUR_DATE_ACCURED - I_DATADATE <= 1 THEN --空值或逾期放在隔夜同G21
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_B,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 2 AND 30 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_C,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 31 AND 90 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_D,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 91 AND 180 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_E,

             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 181 AND 270 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_F,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 271 AND 360 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_G,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 361 AND 540 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_H,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 541 AND 720 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_I,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 721 AND 1080 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_J,

             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 1081 AND 1440 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_K,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 1441 AND 1800 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_L,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_M,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_N,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_O,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_P,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_Q,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 10 + 1 AND 360 * 15 THEN

                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_R,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_S,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE > 360 * 20 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_T
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T1
       INNER JOIN (SELECT DISTINCT ACCT_NUM
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_SCALE_QQ
                    WHERE DATA_DATE = I_DATADATE
                      AND REAL_SCALE = 'ST') T2
          ON T1.ACCT_NUM = T2.ACCT_NUM
       WHERE T1.DATA_DATE = I_DATADATE
       AND T1.ACCT_CUR='CNY'
       GROUP BY T1.ORG_NUM, T1.GL_ITEM_CODE;
  COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：2.3 可提前支取的定期零售类存款利息数据进ID_G3301_ITEMDATA_CKLX中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：2.3 可提前支取的定期零售类(个体工商户存款)存款利息数据进ID_G3301_ITEMDATA_CKLX中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
   --个体工商户定期利息
   INSERT 
   INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKLX 
     (ORGNO,
      RQ,
      SUBJECT,
      LOCAL_STATION,
      AMOUNT_B, --隔夜
      AMOUNT_C, --隔夜-一个月（含）
      AMOUNT_D, --1个月-3个月（含）
      AMOUNT_E, --3个月-6个月（含）
      AMOUNT_F, --6个月-9个月(含)
      AMOUNT_G, --9个月-1年(含)
      AMOUNT_H, --1年-1.5年(含)
      AMOUNT_I, --1.5年-2年(含)
      AMOUNT_J, --2年-3年(含)
      AMOUNT_K, --3年-4年(含)
      AMOUNT_L, --4年-5年(含)
      AMOUNT_M, --5年-6年(含)
      AMOUNT_N, --6年-7年(含)
      AMOUNT_O, --7年-8年(含)
      AMOUNT_P, --8年-9年(含)
      AMOUNT_Q, --9年-10年(含)
      AMOUNT_R, --10年-15年(含)
      AMOUNT_S, --15年-20年(含)
      AMOUNT_T) --20年以上
     SELECT T1.ORG_NUM,
            I_DATADATE,
            T1.GL_ITEM_CODE,
            'G33_1_2.3' AS LOCAL_STATION,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED IS NULL OR T1.MATUR_DATE_ACCURED - I_DATADATE <= 1 THEN --空值或逾期放在隔夜同G21
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_B,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 2 AND 30 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_C,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 31 AND 90 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_D,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 91 AND 180 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_E,

             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 181 AND 270 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_F,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 271 AND 360 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_G,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 361 AND 540 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_H,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 541 AND 720 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_I,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 721 AND 1080 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_J,

             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 1081 AND 1440 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_K,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 1441 AND 1800 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_L,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_M,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_N,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_O,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_P,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_Q,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 10 + 1 AND 360 * 15 THEN

                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_R,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_S,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE > 360 * 20 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_T
       FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL T1
      WHERE FLAG_CODE = '03'  --个体工商户存款
        AND DATA_DATE = I_DATADATE
                 AND (T1.GL_ITEM_CODE IN
                     (/*'202',
                       '203',*/ --通知存款放在 2.1.3.1隔夜-一个月（含），不在此处统计
                       '20110202',
                       '20110203',
                       '20110204',
                       '20110211',
                       '20110701',
                       '20110103',
                       '20110104',
                       '20110105',
                       '20110106',
                       '20110107',
                       '20110108',
                       '20110109',
                       '20110208',
                       '20110113',
                       '20110114',
                       '20110115',
                       '20110209',
                       '20110210',
                       '20110207',
                       '20110112')
                         --    需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：石雨，提出人：王曦若 ，修改内容：20110701 改成 2010
                      OR T1.GL_ITEM_CODE LIKE  '2010%'
                       OR T1.GL_ITEM_CODE = '20120204') --限定定期存款，与G21定期存款同
       AND T1.ACCT_CUR='CNY'
       GROUP BY T1.ORG_NUM, T1.GL_ITEM_CODE;

  COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：2.3 可提前支取的定期零售类(个体工商户存款)存款利息数据进ID_G3301_ITEMDATA_CKLX中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据： 2.4 可提前支取的定期批发类存款利息数据进ID_G3301_ITEMDATA_CKLX中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --2.4 可提前支取的定期批发类存款(对公客户存款余额大于800万的为批发客户)
   INSERT 
    INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKLX 
      (ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T) --20年以上
      SELECT T1.ORG_NUM,
             I_DATADATE,
             T1.GL_ITEM_CODE,
             'G33_1_2.4' AS LOCAL_STATION,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED IS NULL OR T1.MATUR_DATE_ACCURED - I_DATADATE <= 1 THEN --空值或逾期放在隔夜同G21
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_B,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 2 AND 30 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_C,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 31 AND 90 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_D,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 91 AND 180 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_E,

             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 181 AND 270 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_F,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 271 AND 360 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_G,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 361 AND 540 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_H,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 541 AND 720 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_I,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 721 AND 1080 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_J,

             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 1081 AND 1440 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_K,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 1441 AND 1800 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_L,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_M,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_N,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_O,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_P,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_Q,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 10 + 1 AND 360 * 15 THEN

                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_R,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_S,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE > 360 * 20 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_T
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T1
       INNER JOIN (SELECT DISTINCT ACCT_NUM
                     FROM PM_RSDATA.CBRC_TMP_DEPOSIT_WD_ACCT_SCALE_QQ
                    WHERE DATA_DATE = I_DATADATE
                      AND REAL_SCALE = 'BM') T2
          ON T1.ACCT_NUM = T2.ACCT_NUM
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ACCT_CUR='CNY'
       GROUP BY T1.ORG_NUM, T1.GL_ITEM_CODE;


  COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：2.4 可提前支取的定期批发类存款利息数据进ID_G3301_ITEMDATA_CKLX中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --=============================================== 贷款==============================================

    --整体处理思路如下：
    --G3301贷款口径正常贷款本金、利息+90天以内本金利息；贷款本金和利息处理方式参考G21,逾期（本金）90天以上进总账，逾期（利息）90天以上不进总账，倒轧时候
    --=============================================== 浮动利率贷款==============================================

    --1.1.3.1 其中：以贷款市场报价利率（LPR）为定价基础的人民币浮动利率贷款
    --1.1.3.2 其中：以人民银行基准利率为定价基础的浮动利率贷款

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1.3.1、1.1.3.2、其他浮动利率贷款数据进ID_G3301_ITEMDATA_DKBJ中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1.3.1、1.1.3.2、其他浮动利率贷款（N99数据）';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
----------------------------------N99数据优先处理，无论是否重定价日准确与否或者为空,N99均按照还款计划处理
        --20231215
        INSERT 
        INTO PM_RSDATA.CBRC_FDM_LNAC_PMT_LLCDJR 
          (DATA_DATE,
           LOAN_NUM,
           CURR_CD,
           ITEM_CD,
           ORG_NUM,
           ACTUAL_MATURITY_DT,
           NEXT_PAYMENT_DT,
           REPAY_SEQ,
           ACCT_NUM,
           ACCT_STS,
           ACCU_INT_AMT,
           ACCT_STATUS_1104,
           NEXT_PAYMENT,
           ACCU_INT,
           LOAN_ACCT_BAL,
           PMT_REMAIN_TERM_C,
           PMT_REMAIN_TERM_C_MULT,
           LOAN_GRADE_CD,
           IDENTITY_CODE,
           OD_INT,
           BOOK_TYPE,
           INT_RATE_TYP,
           NEXT_REPRICING_DT,
           BENM_INRAT_TYPE,
           PMT_REMAIN_TERM_D,
           INRAT_RGLR_MODE,
           DATE_SOURCESD,
           FLAG,
           DATA_DEPARTMENT,--数据条线 -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
           REPRICE_PERIOD)--重定价周期_核算端 -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
          SELECT
           T1.DATA_DATE,
           T1.LOAN_NUM,
           T1.CURR_CD,
           T1.ITEM_CD,
           T1.ORG_NUM,
           T1.ACTUAL_MATURITY_DT,
           T1.NEXT_PAYMENT_DT,
           T1.REPAY_SEQ,
           T1.ACCT_NUM,
           T1.ACCT_STS,
           T1.ACCU_INT_AMT,
           T1.ACCT_STATUS_1104,
           T1.NEXT_PAYMENT,
           T1.ACCU_INT,
           T1.LOAN_ACCT_BAL,
           T1.PMT_REMAIN_TERM_C,
           T1.PMT_REMAIN_TERM_C_MULT,
           T1.LOAN_GRADE_CD,
           T1.IDENTITY_CODE,
           T1.OD_INT,
           T1.BOOK_TYPE,
           T1.INT_RATE_TYP,
           T1.NEXT_REPRICING_DT,
           T1.BENM_INRAT_TYPE,
           T1.PMT_REMAIN_TERM_D,
           T1.INRAT_RGLR_MODE,
           T1.DATE_SOURCESD,
           '1' FLAG,
           DATA_DEPARTMENT, --36数据条线 -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
           REPRICE_PERIOD -- 重定价周期_核算端 [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
            FROM PM_RSDATA.CBRC_FDM_LNAC_PMT T1
           INNER JOIN PM_RSDATA.SMTMODS_L_ACCT_LOAN T2
              ON T1.LOAN_NUM = T2.LOAN_NUM
             AND T2.DATA_DATE = I_DATADATE
             AND T2.REPRICE_PERIOD = 'N99'
             AND T2.LOAN_ACCT_BAL <> 0
             AND T2.ITEM_CD LIKE '1%'
             AND T2.INT_RATE_TYP LIKE 'L%'
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2' --账户种类  1  交易账户  2  银行账户
             AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
             AND T1.CURR_CD = 'CNY';
 COMMIT;

         -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
             INSERT 
             INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
               (DATA_DATE,
                ORG_NUM,
                DATA_DEPARTMENT,
                SYS_NAM,
                REP_NUM,
                ITEM_NUM,
                TOTAL_VALUE,
                COL_1,
                COL_2,
                COL_3,
                COL_4,
                COL_5,
                COL_6,
                COL_7,
                COL_8,
                COL_9,
                COL_10)
               SELECT 
                I_DATADATE,
                T1.ORG_NUM,
                T1.DATA_DEPARTMENT, --数据条线
                'CBRC' AS SYS_NAM,
                'G33' REP_NUM,
                CASE
                  WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                       (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                   'G33_I_1.1.3.2.B'
                  WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                       T1.IDENTITY_CODE = '1') or
                       (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                   'G33_I_1.1.3.2.C'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND   --1个月-3个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.D'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND  --3个月-6个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.E'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND  --6个月-9个月(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.F'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND  --9个月-1年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.G'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND  --1年-1.5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.H'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND  --1.5年-2年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.I'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.J'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND  --3年-4年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.K'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.L'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.M'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.N'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.O'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.P'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.Q'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.R'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND  --15年-20年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.S'
                  WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN  --20年以上
                   'G33_I_1.1.3.2.T'
                END AS ITEM_NUM,
                T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
                T1.LOAN_NUM AS COL1, --贷款编号
                T1.CURR_CD AS COL2, --币种
                T1.ITEM_CD AS COL3, --科目
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
                TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
                T1.ACCT_NUM AS COL6, --贷款合同编号
                T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
                CASE
                  WHEN T1.LOAN_GRADE_CD = '1' THEN
                   '正常'
                  WHEN T1.LOAN_GRADE_CD = '2' THEN
                   '关注'
                  WHEN T1.LOAN_GRADE_CD = '3' THEN
                   '次级'
                  WHEN T1.LOAN_GRADE_CD = '4' THEN
                   '可疑'
                  WHEN T1.LOAN_GRADE_CD = '5' THEN
                   '损失'
                END AS COL8, --五级分类
                CASE
                  WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                   'LPR'
                  WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                   '基准利率'
                  WHEN T1.BENM_INRAT_TYPE = '#' THEN
                   '其他利率'
                END AS COL9, --参考利率类型
                REPRICE_PERIOD AS  COL_10 --重定价周期_核算端
                 FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LLCDJR T1
                WHERE FLAG = '1'
                  AND (T1.BENM_INRAT_TYPE = 'A' OR
                      (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账'))--add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
                  AND T1.NEXT_PAYMENT <>0;
             COMMIT;

           INSERT 
           INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
             (DATA_DATE,
              ORG_NUM,
              DATA_DEPARTMENT,
              SYS_NAM,
              REP_NUM,
              ITEM_NUM,
              TOTAL_VALUE,
              COL_1,
              COL_2,
              COL_3,
              COL_4,
              COL_5,
              COL_6,
              COL_7,
              COL_8,
              COL_9,
              COL_10)
             SELECT 
             I_DATADATE,
              T1.ORG_NUM,
              T1.DATA_DEPARTMENT, --数据条线
              'CBRC' AS SYS_NAM,
              'G33' REP_NUM,
              CASE
                WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                     (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                 'G33_I_1.1.3.1.B'
                WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                     T1.IDENTITY_CODE = '1') or
                     (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                 'G33_I_1.1.3.1.C'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.D'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.E'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.F'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.G'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.H'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.I'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.J'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.K'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.L'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.M'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.N'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.O'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.P'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.Q'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.R'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.S'
                WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.T'
              END AS ITEM_NUM,
              T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
              T1.LOAN_NUM AS COL1, --贷款编号
              T1.CURR_CD AS COL2, --币种
              T1.ITEM_CD AS COL3, --科目
              TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
              TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
              T1.ACCT_NUM AS COL6, --贷款合同编号
              T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
              CASE
                WHEN T1.LOAN_GRADE_CD = '1' THEN
                 '正常'
                WHEN T1.LOAN_GRADE_CD = '2' THEN
                 '关注'
                WHEN T1.LOAN_GRADE_CD = '3' THEN
                 '次级'
                WHEN T1.LOAN_GRADE_CD = '4' THEN
                 '可疑'
                WHEN T1.LOAN_GRADE_CD = '5' THEN
                 '损失'
              END AS COL8, --五级分类
              CASE
                WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                 'LPR'
                WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                 '基准利率'
                WHEN T1.BENM_INRAT_TYPE = '#' THEN
                 '其他利率'
              END AS COL9, --参考利率类型
               REPRICE_PERIOD AS  COL_10 --重定价周期_核算端
               FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LLCDJR T1
              WHERE FLAG = '1'
                AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
                AND T1.NEXT_PAYMENT <>0;

        COMMIT;


         INSERT 
           INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
             (DATA_DATE,
              ORG_NUM,
              DATA_DEPARTMENT,
              SYS_NAM,
              REP_NUM,
              ITEM_NUM,
              TOTAL_VALUE,
              COL_1,
              COL_2,
              COL_3,
              COL_4,
              COL_5,
              COL_6,
              COL_7,
              COL_8,
              COL_9,
              COL_10)
             SELECT 
              I_DATADATE,
              T1.ORG_NUM,
              T1.DATA_DEPARTMENT, --数据条线
              'CBRC' AS SYS_NAM,
              'G33' REP_NUM,
              CASE
                WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                     (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                 'G33_I_1.1.3.3.B'
                WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                     T1.IDENTITY_CODE = '1') or
                     (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                 'G33_I_1.1.3.3.C'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.D'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.E'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.F'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.G'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.H'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.I'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.J'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.K'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.L'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.M'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.N'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.O'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.P'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.Q'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.R'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.S'
                WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.T'
              END AS ITEM_NUM,
              T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
              T1.LOAN_NUM AS COL1, --贷款编号
              T1.CURR_CD AS COL2, --币种
              T1.ITEM_CD AS COL3, --科目
              TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
              TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
              T1.ACCT_NUM AS COL6, --贷款合同编号
              T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
              CASE
                WHEN T1.LOAN_GRADE_CD = '1' THEN
                 '正常'
                WHEN T1.LOAN_GRADE_CD = '2' THEN
                 '关注'
                WHEN T1.LOAN_GRADE_CD = '3' THEN
                 '次级'
                WHEN T1.LOAN_GRADE_CD = '4' THEN
                 '可疑'
                WHEN T1.LOAN_GRADE_CD = '5' THEN
                 '损失'
              END AS COL8, --五级分类
              CASE
                WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                 'LPR'
                WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                 '基准利率'
                WHEN T1.BENM_INRAT_TYPE = '#' THEN
                 '其他利率'
              END AS COL9, --参考利率类型
               REPRICE_PERIOD AS  COL_10 --重定价周期_核算端
               FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LLCDJR T1
              WHERE FLAG = '1'
                AND T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'BMS-票据转贴' --给一个不存在指标号，为了放在1.1.3 贷款
                AND T1.NEXT_PAYMENT <>0;

        COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.1.3.1、1.1.3.2、其他浮动利率贷款（N99数据）';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1.3.1、1.1.3.2、其他浮动利率贷款（下一利率重定价日为空）';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
 ----------------------------------N99数据优先处理，无论是否重定价日准确与否,N99均按照还款计划处理

--20231215 N99处理后
/*1、利率重定价日为空，放到隔夜
2、利率重定价日小于当前日期，本金用还款计划表下一付款日处理
3、利率重定价日大于到日期，本金用还款计划表下一付款日处理*/

--重定价日为空的优先处理，否则有同时重定价日为空，且含有其他期限情况的数据

 INSERT 
        INTO PM_RSDATA.CBRC_FDM_LNAC_PMT_LLCDJR 
          (DATA_DATE,
           LOAN_NUM,
           CURR_CD,
           ITEM_CD,
           ORG_NUM,
           ACTUAL_MATURITY_DT,
           NEXT_PAYMENT_DT,
           REPAY_SEQ,
           ACCT_NUM,
           ACCT_STS,
           ACCU_INT_AMT,
           ACCT_STATUS_1104,
           NEXT_PAYMENT,
           ACCU_INT,
           LOAN_ACCT_BAL,
           PMT_REMAIN_TERM_C,
           PMT_REMAIN_TERM_C_MULT,
           LOAN_GRADE_CD,
           IDENTITY_CODE,
           OD_INT,
           BOOK_TYPE,
           INT_RATE_TYP,
           NEXT_REPRICING_DT,
           BENM_INRAT_TYPE,
           PMT_REMAIN_TERM_D,
           INRAT_RGLR_MODE,
           DATE_SOURCESD,
           FLAG,
           DATA_DEPARTMENT)--数据条线 -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
          SELECT
           DATA_DATE,
           LOAN_NUM,
           CURR_CD,
           ITEM_CD,
           ORG_NUM,
           ACTUAL_MATURITY_DT,
           NEXT_PAYMENT_DT,
           REPAY_SEQ,
           ACCT_NUM,
           ACCT_STS,
           ACCU_INT_AMT,
           ACCT_STATUS_1104,
           NEXT_PAYMENT,
           ACCU_INT,
           LOAN_ACCT_BAL,
           PMT_REMAIN_TERM_C,
           PMT_REMAIN_TERM_C_MULT,
           LOAN_GRADE_CD,
           IDENTITY_CODE,
           OD_INT,
           BOOK_TYPE,
           INT_RATE_TYP,
           NEXT_REPRICING_DT,
           BENM_INRAT_TYPE,
           PMT_REMAIN_TERM_D,
           INRAT_RGLR_MODE,
           DATE_SOURCESD,
           '2' FLAG,
           DATA_DEPARTMENT --数据条线 -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
            FROM PM_RSDATA.CBRC_FDM_LNAC_PMT T1
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2' --账户种类  1  交易账户  2  银行账户
             AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
             AND T1.CURR_CD = 'CNY'
             AND T1.NEXT_REPRICING_DT IS NULL
             AND T1.LOAN_NUM NOT IN
                 (SELECT LOAN_NUM FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LLCDJR WHERE FLAG = '1'); --在N99里面处理过的，不止N99，还有为空的都不在此处处理了
        COMMIT;

      -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_1,
           COL_2,
           COL_3,
           COL_4,
           COL_5,
           COL_6,
           COL_7,
           COL_8,
           COL_9,
           COL_11)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
             WHEN T1.BENM_INRAT_TYPE = 'A' OR
                  (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账') THEN --基准利率类型（B基准率,A LPR利率,#空值）
              'G33_I_1.1.3.2.B'
             WHEN (T1.BENM_INRAT_TYPE = 'B') THEN --基准利率类型（B基准率,A LPR利率,#空值）
              'G33_I_1.1.3.1.B'
             WHEN T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'BMS-票据转贴' THEN
              'G33_I_1.1.3.3.B' --给一个不存在指标号，为了放在1.1.3 贷款
           END AS ITEM_NUM,
           T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
           TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
           T1.ACCT_NUM AS COL6, --贷款合同编号
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           CASE
             WHEN T1.LOAN_GRADE_CD = '1' THEN
              '正常'
             WHEN T1.LOAN_GRADE_CD = '2' THEN
              '关注'
             WHEN T1.LOAN_GRADE_CD = '3' THEN
              '次级'
             WHEN T1.LOAN_GRADE_CD = '4' THEN
              '可疑'
             WHEN T1.LOAN_GRADE_CD = '5' THEN
              '损失'
           END AS COL8, --五级分类
           CASE
             WHEN T1.BENM_INRAT_TYPE = 'A' THEN
              'LPR'
             WHEN T1.BENM_INRAT_TYPE = 'B' THEN
              '基准利率'
             WHEN T1.BENM_INRAT_TYPE = '#' THEN
              '其他利率'
           END AS COL9, --参考利率类型
           TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYY-MM-DD')  AS COL_11--下一利率重定价日
            FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LLCDJR T1
           WHERE FLAG = '2'
            AND T1.NEXT_PAYMENT <>0;

     COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.1.3.1、1.1.3.2、其他浮动利率贷款（下一利率重定价日为空）';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1.3.1、1.1.3.2、其他浮动利率贷款（下一利率重定价小于当前日期或大于到日期）';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

       INSERT 
        INTO PM_RSDATA.CBRC_FDM_LNAC_PMT_LLCDJR 
          (DATA_DATE,
           LOAN_NUM,
           CURR_CD,
           ITEM_CD,
           ORG_NUM,
           ACTUAL_MATURITY_DT,
           NEXT_PAYMENT_DT,
           REPAY_SEQ,
           ACCT_NUM,
           ACCT_STS,
           ACCU_INT_AMT,
           ACCT_STATUS_1104,
           NEXT_PAYMENT,
           ACCU_INT,
           LOAN_ACCT_BAL,
           PMT_REMAIN_TERM_C,
           PMT_REMAIN_TERM_C_MULT,
           LOAN_GRADE_CD,
           IDENTITY_CODE,
           OD_INT,
           BOOK_TYPE,
           INT_RATE_TYP,
           NEXT_REPRICING_DT,
           BENM_INRAT_TYPE,
           PMT_REMAIN_TERM_D,
           INRAT_RGLR_MODE,
           DATE_SOURCESD,
           FLAG,
           DATA_DEPARTMENT) --数据条线 -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
          SELECT 
           DATA_DATE,
           LOAN_NUM,
           CURR_CD,
           ITEM_CD,
           ORG_NUM,
           ACTUAL_MATURITY_DT,
           NEXT_PAYMENT_DT,
           REPAY_SEQ,
           ACCT_NUM,
           ACCT_STS,
           ACCU_INT_AMT,
           ACCT_STATUS_1104,
           NEXT_PAYMENT,
           ACCU_INT,
           LOAN_ACCT_BAL,
           PMT_REMAIN_TERM_C,
           PMT_REMAIN_TERM_C_MULT,
           LOAN_GRADE_CD,
           IDENTITY_CODE,
           OD_INT,
           BOOK_TYPE,
           INT_RATE_TYP,
           NEXT_REPRICING_DT,
           BENM_INRAT_TYPE,
           PMT_REMAIN_TERM_D,
           INRAT_RGLR_MODE,
           DATE_SOURCESD,
           '3' FLAG,
           DATA_DEPARTMENT --数据条线 -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
            FROM PM_RSDATA.CBRC_FDM_LNAC_PMT T1
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2' --账户种类  1  交易账户  2  银行账户
             AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
             AND T1.CURR_CD = 'CNY'
             AND (TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') <= I_DATADATE OR
                 TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') >
                 TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYYMMDD')) --当前日期小于, 大于到期日按照还款计划划分期限
             AND T1.LOAN_NUM NOT IN
                 (SELECT LOAN_NUM FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LLCDJR WHERE FLAG IN ('1', '2'));
COMMIT;


        -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
             INSERT 
             INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
               (DATA_DATE,
                ORG_NUM,
                DATA_DEPARTMENT,
                SYS_NAM,
                REP_NUM,
                ITEM_NUM,
                TOTAL_VALUE,
                COL_1,
                COL_2,
                COL_3,
                COL_4,
                COL_5,
                COL_6,
                COL_7,
                COL_8,
                COL_9,
                COL_11)
               SELECT 
                I_DATADATE,
                T1.ORG_NUM,
                T1.DATA_DEPARTMENT, --数据条线
                'CBRC' AS SYS_NAM,
                'G33' REP_NUM,
                CASE
                  WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                       (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                   'G33_I_1.1.3.2.B'
                  WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                       T1.IDENTITY_CODE = '1') or
                       (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                   'G33_I_1.1.3.2.C'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND   --1个月-3个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.D'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND  --3个月-6个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.E'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND  --6个月-9个月(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.F'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND  --9个月-1年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.G'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND  --1年-1.5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.H'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND  --1.5年-2年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.I'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.J'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND  --3年-4年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.K'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.L'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.M'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.N'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.O'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.P'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.Q'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.R'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND  --15年-20年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.S'
                  WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN  --20年以上
                   'G33_I_1.1.3.2.T'
                END AS ITEM_NUM,
                T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
                T1.LOAN_NUM AS COL1, --贷款编号
                T1.CURR_CD AS COL2, --币种
                T1.ITEM_CD AS COL3, --科目
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
                TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
                T1.ACCT_NUM AS COL6, --贷款合同编号
                T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
                CASE
                  WHEN T1.LOAN_GRADE_CD = '1' THEN
                   '正常'
                  WHEN T1.LOAN_GRADE_CD = '2' THEN
                   '关注'
                  WHEN T1.LOAN_GRADE_CD = '3' THEN
                   '次级'
                  WHEN T1.LOAN_GRADE_CD = '4' THEN
                   '可疑'
                  WHEN T1.LOAN_GRADE_CD = '5' THEN
                   '损失'
                END AS COL8, --五级分类
                CASE
                  WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                   'LPR'
                  WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                   '基准利率'
                  WHEN T1.BENM_INRAT_TYPE = '#' THEN
                   '其他利率'
                END AS COL9, --参考利率类型
                TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYY-MM-DD')  AS COL_11--下一利率重定价日
                 FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LLCDJR T1
                WHERE FLAG = '3'
                  AND (T1.BENM_INRAT_TYPE = 'A' OR
                      (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账')) --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
                  AND T1.NEXT_PAYMENT <>0;
             COMMIT;

           INSERT 
           INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
             (DATA_DATE,
              ORG_NUM,
              DATA_DEPARTMENT,
              SYS_NAM,
              REP_NUM,
              ITEM_NUM,
              TOTAL_VALUE,
              COL_1,
              COL_2,
              COL_3,
              COL_4,
              COL_5,
              COL_6,
              COL_7,
              COL_8,
              COL_9,
              COL_11)
             SELECT 
             I_DATADATE,
              T1.ORG_NUM,
              T1.DATA_DEPARTMENT, --数据条线
              'CBRC' AS SYS_NAM,
              'G33' REP_NUM,
              CASE
                WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                     (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                 'G33_I_1.1.3.1.B'
                WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                     T1.IDENTITY_CODE = '1') or
                     (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                 'G33_I_1.1.3.1.C'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.D'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.E'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.F'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.G'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.H'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.I'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.J'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.K'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.L'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.M'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.N'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.O'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.P'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.Q'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.R'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.S'
                WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.T'
              END AS ITEM_NUM,
              T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
              T1.LOAN_NUM AS COL1, --贷款编号
              T1.CURR_CD AS COL2, --币种
              T1.ITEM_CD AS COL3, --科目
              TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
              TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
              T1.ACCT_NUM AS COL6, --贷款合同编号
              T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
              CASE
                WHEN T1.LOAN_GRADE_CD = '1' THEN
                 '正常'
                WHEN T1.LOAN_GRADE_CD = '2' THEN
                 '关注'
                WHEN T1.LOAN_GRADE_CD = '3' THEN
                 '次级'
                WHEN T1.LOAN_GRADE_CD = '4' THEN
                 '可疑'
                WHEN T1.LOAN_GRADE_CD = '5' THEN
                 '损失'
              END AS COL8, --五级分类
              CASE
                WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                 'LPR'
                WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                 '基准利率'
                WHEN T1.BENM_INRAT_TYPE = '#' THEN
                 '其他利率'
              END AS COL9, --参考利率类型
               TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYY-MM-DD') AS COL11--下一利率重定价日
               FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LLCDJR T1
              WHERE FLAG = '3'
                AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
                AND T1.NEXT_PAYMENT <>0;
        COMMIT;


         INSERT 
           INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
             (DATA_DATE,
              ORG_NUM,
              DATA_DEPARTMENT,
              SYS_NAM,
              REP_NUM,
              ITEM_NUM,
              TOTAL_VALUE,
              COL_1,
              COL_2,
              COL_3,
              COL_4,
              COL_5,
              COL_6,
              COL_7,
              COL_8,
              COL_9,
              COL_11)
             SELECT 
              I_DATADATE,
              T1.ORG_NUM,
              T1.DATA_DEPARTMENT, --数据条线
              'CBRC' AS SYS_NAM,
              'G33' REP_NUM,
              CASE
                WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                     (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                 'G33_I_1.1.3.3.B'
                WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                     T1.IDENTITY_CODE = '1') or
                     (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                 'G33_I_1.1.3.3.C'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.D'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.E'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.F'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.G'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.H'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.I'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.J'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.K'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.L'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.M'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.N'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.O'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.P'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.Q'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.R'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.S'
                WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.3.T'
              END AS ITEM_NUM,
              T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
              T1.LOAN_NUM AS COL1, --贷款编号
              T1.CURR_CD AS COL2, --币种
              T1.ITEM_CD AS COL3, --科目
              TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
              TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
              T1.ACCT_NUM AS COL6, --贷款合同编号
              T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
              CASE
                WHEN T1.LOAN_GRADE_CD = '1' THEN
                 '正常'
                WHEN T1.LOAN_GRADE_CD = '2' THEN
                 '关注'
                WHEN T1.LOAN_GRADE_CD = '3' THEN
                 '次级'
                WHEN T1.LOAN_GRADE_CD = '4' THEN
                 '可疑'
                WHEN T1.LOAN_GRADE_CD = '5' THEN
                 '损失'
              END AS COL8, --五级分类
              CASE
                WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                 'LPR'
                WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                 '基准利率'
                WHEN T1.BENM_INRAT_TYPE = '#' THEN
                 '其他利率'
              END AS COL9, --参考利率类型
               TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYY-MM-DD') AS COL11--下一利率重定价日
               FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LLCDJR T1
              WHERE FLAG = '3'
                AND T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'BMS-票据转贴'  --给一个不存在指标号，为了放在1.1.3 贷款
                AND T1.NEXT_PAYMENT <>0;
        COMMIT;



    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.1.3.1、1.1.3.2、其他浮动利率贷款（下一利率重定价小于当前日期或大于到日期）';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1.3.1、1.1.3.2、其他浮动利率贷款（按照正常下一利率重定价划分期限）';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

----------------------------------按照正常重定价日处理
   -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       INSERT 
       INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
         (DATA_DATE,
          ORG_NUM,
          DATA_DEPARTMENT,
          SYS_NAM,
          REP_NUM,
          ITEM_NUM,
          TOTAL_VALUE,
          COL_1,
          COL_2,
          COL_3,
          COL_4,
          COL_5,
          COL_6,
          COL_7,
          COL_8,
          COL_9,
          COL_11)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_D = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.1.3.2.B'
            WHEN (T1.PMT_REMAIN_TERM_D BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.1.3.2.C'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.D'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.E'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.F'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.G'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.H'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.I'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.J'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.K'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.L'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.M'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.N'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.O'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.P'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.Q'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.R'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.S'
            WHEN T1.PMT_REMAIN_TERM_D > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.1.3.2.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
          TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
          T1.ACCT_NUM AS COL6, --贷款合同编号
          CASE
            WHEN (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0 OR
                 T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN
             T1.PMT_REMAIN_TERM_C
            WHEN T1.PMT_REMAIN_TERM_D >= 1 AND T1.IDENTITY_CODE = '1' THEN
             T1.PMT_REMAIN_TERM_D
          END AS COL7, --剩余期限（天数）
          CASE
            WHEN T1.LOAN_GRADE_CD = '1' THEN
             '正常'
            WHEN T1.LOAN_GRADE_CD = '2' THEN
             '关注'
            WHEN T1.LOAN_GRADE_CD = '3' THEN
             '次级'
            WHEN T1.LOAN_GRADE_CD = '4' THEN
             '可疑'
            WHEN T1.LOAN_GRADE_CD = '5' THEN
             '损失'
          END AS COL8, --五级分类
          CASE
            WHEN T1.BENM_INRAT_TYPE = 'A' THEN
             'LPR'
            WHEN T1.BENM_INRAT_TYPE = 'B' THEN
             '基准利率'
            WHEN T1.BENM_INRAT_TYPE = '#' THEN
             '其他利率'
          END AS COL9, --参考利率类型
          TO_CHAR(NEXT_REPRICING_DT, 'YYYY-MM-DD') AS COL_11 --下一利率重定价日
           FROM PM_RSDATA.CBRC_FDM_LNAC_PMT T1
          WHERE T1.DATA_DATE = I_DATADATE
            AND T1.BOOK_TYPE = '2' --账户种类  1  交易账户  2  银行账户
            AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
            AND T1.CURR_CD = 'CNY'
            AND T1.NEXT_REPRICING_DT IS NOT NULL
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') > I_DATADATE
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') <=
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYYMMDD') --20231215 利率重定价日小于实际到期日，其他在下面处理
            AND T1.LOAN_NUM NOT IN
                (SELECT LOAN_NUM
                   FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LLCDJR
                  WHERE FLAG IN ('1', '2', '3'))
            AND (T1.BENM_INRAT_TYPE = 'A' OR
                (T1.BENM_INRAT_TYPE = '#' AND
                T1.DATE_SOURCESD = 'NGI-2-垫款台账')) --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
            AND T1.NEXT_PAYMENT <>0;
       COMMIT;

       INSERT 
       INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
         (DATA_DATE,
          ORG_NUM,
          DATA_DEPARTMENT,
          SYS_NAM,
          REP_NUM,
          ITEM_NUM,
          TOTAL_VALUE,
          COL_1,
          COL_2,
          COL_3,
          COL_4,
          COL_5,
          COL_6,
          COL_7,
          COL_8,
          COL_9,
          COL_11)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_D = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.1.3.1.B'
            WHEN (T1.PMT_REMAIN_TERM_D BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.1.3.1.C'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 31 AND 90 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.D'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 91 AND 180 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.E'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 181 AND 270 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.F'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 271 AND 360 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.G'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 361 AND 540 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.H'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 541 AND 720 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.I'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 721 AND 1080 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.J'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1081 AND 1440 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.K'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1441 AND 1800 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.L'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1801 AND 360 * 6 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.M'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 6 + 1 AND 360 * 7 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.N'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 7 + 1 AND 360 * 8 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.O'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 8 + 1 AND 360 * 9 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.P'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 9 + 1 AND 360 * 10 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.Q'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 10 + 1 AND 360 * 15 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.R'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 15 + 1 AND 360 * 20 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.S'
            WHEN T1.PMT_REMAIN_TERM_D > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
          TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
          T1.ACCT_NUM AS COL6, --贷款合同编号
          CASE
            WHEN (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0 OR
                 T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN
             T1.PMT_REMAIN_TERM_C
            WHEN T1.PMT_REMAIN_TERM_D >= 1 AND T1.IDENTITY_CODE = '1' THEN
             T1.PMT_REMAIN_TERM_D
          END AS COL7, --剩余期限（天数）
          CASE
            WHEN T1.LOAN_GRADE_CD = '1' THEN
             '正常'
            WHEN T1.LOAN_GRADE_CD = '2' THEN
             '关注'
            WHEN T1.LOAN_GRADE_CD = '3' THEN
             '次级'
            WHEN T1.LOAN_GRADE_CD = '4' THEN
             '可疑'
            WHEN T1.LOAN_GRADE_CD = '5' THEN
             '损失'
          END AS COL8, --五级分类
          CASE
            WHEN T1.BENM_INRAT_TYPE = 'A' THEN
             'LPR'
            WHEN T1.BENM_INRAT_TYPE = 'B' THEN
             '基准利率'
            WHEN T1.BENM_INRAT_TYPE = '#' THEN
             '其他利率'
          END AS COL9, --参考利率类型
          TO_CHAR(NEXT_REPRICING_DT, 'YYYY-MM-DD') AS COL_11 --下一利率重定价日
           FROM PM_RSDATA.CBRC_FDM_LNAC_PMT T1
          WHERE T1.DATA_DATE = I_DATADATE
            AND T1.BOOK_TYPE = '2' --账户种类  1  交易账户  2  银行账户
            AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
            AND T1.CURR_CD = 'CNY'
            AND T1.NEXT_REPRICING_DT IS NOT NULL
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') > I_DATADATE
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') <=
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYYMMDD') --20231215 利率重定价日小于实际到期日，其他在下面处理
            AND T1.LOAN_NUM NOT IN
                (SELECT LOAN_NUM
                   FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LLCDJR
                  WHERE FLAG IN ('1', '2', '3'))
            AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
            AND T1.NEXT_PAYMENT <>0;
       COMMIT;

       INSERT 
       INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
         (DATA_DATE,
          ORG_NUM,
          DATA_DEPARTMENT,
          SYS_NAM,
          REP_NUM,
          ITEM_NUM,
          TOTAL_VALUE,
          COL_1,
          COL_2,
          COL_3,
          COL_4,
          COL_5,
          COL_6,
          COL_7,
          COL_8,
          COL_9,
          COL_11)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_D = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.1.3.3.B'
            WHEN (T1.PMT_REMAIN_TERM_D BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.1.3.3.C'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 31 AND 90 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.3.D'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 91 AND 180 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.3.E'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 181 AND 270 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.3.F'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 271 AND 360 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.3.G'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 361 AND 540 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.3.H'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 541 AND 720 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.3.I'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 721 AND 1080 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.3.J'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1081 AND 1440 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.3.K'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1441 AND 1800 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.3.L'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1801 AND 360 * 6 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.3.M'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 6 + 1 AND 360 * 7 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.3.N'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 7 + 1 AND 360 * 8 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.3.O'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 8 + 1 AND 360 * 9 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.3.P'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 9 + 1 AND 360 * 10 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.3.Q'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 10 + 1 AND 360 * 15 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.3.R'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 15 + 1 AND 360 * 20 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.3.S'
            WHEN T1.PMT_REMAIN_TERM_D > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.3.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
          TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
          T1.ACCT_NUM AS COL6, --贷款合同编号
          CASE
            WHEN (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0 OR
                 T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN
             T1.PMT_REMAIN_TERM_C
            WHEN T1.PMT_REMAIN_TERM_D >= 1 AND T1.IDENTITY_CODE = '1' THEN
             T1.PMT_REMAIN_TERM_D
          END AS COL7, --剩余期限（天数）
          CASE
            WHEN T1.LOAN_GRADE_CD = '1' THEN
             '正常'
            WHEN T1.LOAN_GRADE_CD = '2' THEN
             '关注'
            WHEN T1.LOAN_GRADE_CD = '3' THEN
             '次级'
            WHEN T1.LOAN_GRADE_CD = '4' THEN
             '可疑'
            WHEN T1.LOAN_GRADE_CD = '5' THEN
             '损失'
          END AS COL8, --五级分类
          CASE
            WHEN T1.BENM_INRAT_TYPE = 'A' THEN
             'LPR'
            WHEN T1.BENM_INRAT_TYPE = 'B' THEN
             '基准利率'
            WHEN T1.BENM_INRAT_TYPE = '#' THEN
             '其他利率'
          END AS COL9, --参考利率类型
          TO_CHAR(NEXT_REPRICING_DT, 'YYYY-MM-DD') AS COL_11 --下一利率重定价日
           FROM PM_RSDATA.CBRC_FDM_LNAC_PMT T1
          WHERE T1.DATA_DATE = I_DATADATE
            AND T1.BOOK_TYPE = '2' --账户种类  1  交易账户  2  银行账户
            AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
            AND T1.CURR_CD = 'CNY'
            AND T1.NEXT_REPRICING_DT IS NOT NULL
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') > I_DATADATE
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') <=
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYYMMDD') --20231215 利率重定价日小于实际到期日，其他在下面处理
            AND T1.LOAN_NUM NOT IN
                (SELECT LOAN_NUM
                   FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LLCDJR
                  WHERE FLAG IN ('1', '2', '3'))
            AND T1.BENM_INRAT_TYPE = '#'
            AND T1.DATE_SOURCESD = 'BMS-票据转贴' --给一个不存在指标号，为了放在1.1.3 贷款
            AND T1.NEXT_PAYMENT <>0;
       COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.1.3.1、1.1.3.2、其他浮动利率贷款（按照正常下一利率重定价划分期限）';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


 ----------------------------------按照正常重定价日处理

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.1.3.1、1.1.3.2、其他浮动利率贷款数据进A_REPT_DWD_G3301中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1.3.1、1.1.3.2、其他浮动利率贷款利息数据进A_REPT_DWD_G3301';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --133应收利息  应计利息+应收利息
    -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_1,
           COL_2,
           COL_3,
           COL_4,
           COL_5,
           COL_6,
           COL_7,
           COL_8,
           COL_9)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --浮动利率,应计利息按还款计划表下一还款日
              'G33_I_1.1.3.2.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.1.3.2.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.1.3.2.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
           TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
           T1.ACCT_NUM AS COL6, --贷款合同编号
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数） 还款计划利息到期日/没有还款计划的利息取下月21号D_DATADATE_CCY + 21
           CASE
             WHEN T1.LOAN_GRADE_CD = '1' THEN
              '正常'
             WHEN T1.LOAN_GRADE_CD = '2' THEN
              '关注'
             WHEN T1.LOAN_GRADE_CD = '3' THEN
              '次级'
             WHEN T1.LOAN_GRADE_CD = '4' THEN
              '可疑'
             WHEN T1.LOAN_GRADE_CD = '5' THEN
              '损失'
           END AS COL8, --五级分类
           CASE
             WHEN T1.BENM_INRAT_TYPE = 'A' THEN
              'LPR'
             WHEN T1.BENM_INRAT_TYPE = 'B' THEN
              '基准利率'
             WHEN T1.BENM_INRAT_TYPE = '#' THEN
              '其他利率'
           END AS COL9 --参考利率类型
            FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LX T1
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
             AND T1.CURR_CD = 'CNY'
             AND (T1.BENM_INRAT_TYPE = 'A' OR
                 (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账')) --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);
        COMMIT;

        INSERT 
        INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_1,
           COL_2,
           COL_3,
           COL_4,
           COL_5,
           COL_6,
           COL_7,
           COL_8,
           COL_9)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --浮动利率,应计利息按还款计划表下一还款日
              'G33_I_1.1.3.1.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.1.3.1.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.1.3.1.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
           TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
           T1.ACCT_NUM AS COL6, --贷款合同编号
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数） 还款计划利息到期日/没有还款计划的利息取下月21号D_DATADATE_CCY + 21
           CASE
             WHEN T1.LOAN_GRADE_CD = '1' THEN
              '正常'
             WHEN T1.LOAN_GRADE_CD = '2' THEN
              '关注'
             WHEN T1.LOAN_GRADE_CD = '3' THEN
              '次级'
             WHEN T1.LOAN_GRADE_CD = '4' THEN
              '可疑'
             WHEN T1.LOAN_GRADE_CD = '5' THEN
              '损失'
           END AS COL8, --五级分类
           CASE
             WHEN T1.BENM_INRAT_TYPE = 'A' THEN
              'LPR'
             WHEN T1.BENM_INRAT_TYPE = 'B' THEN
              '基准利率'
             WHEN T1.BENM_INRAT_TYPE = '#' THEN
              '其他利率'
           END AS COL9 --参考利率类型
            FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LX T1
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
             AND T1.CURR_CD = 'CNY'
             AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);
        COMMIT;

        INSERT 
        INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_1,
           COL_2,
           COL_3,
           COL_4,
           COL_5,
           COL_6,
           COL_7,
           COL_8,
           COL_9)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --浮动利率,应计利息按还款计划表下一还款日
              'G33_I_1.1.3.3.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.1.3.3.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.3.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.3.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.3.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.3.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.3.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.3.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.3.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.3.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.3.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.3.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.3.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.3.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.3.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.3.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.3.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.3.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.1.3.3.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
           TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
           T1.ACCT_NUM AS COL6, --贷款合同编号
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数） 还款计划利息到期日/没有还款计划的利息取下月21号D_DATADATE_CCY + 21
           CASE
             WHEN T1.LOAN_GRADE_CD = '1' THEN
              '正常'
             WHEN T1.LOAN_GRADE_CD = '2' THEN
              '关注'
             WHEN T1.LOAN_GRADE_CD = '3' THEN
              '次级'
             WHEN T1.LOAN_GRADE_CD = '4' THEN
              '可疑'
             WHEN T1.LOAN_GRADE_CD = '5' THEN
              '损失'
           END AS COL8, --五级分类
           CASE
             WHEN T1.BENM_INRAT_TYPE = 'A' THEN
              'LPR'
             WHEN T1.BENM_INRAT_TYPE = 'B' THEN
              '基准利率'
             WHEN T1.BENM_INRAT_TYPE = '#' THEN
              '其他利率'
           END AS COL9 --参考利率类型
            FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LX T1
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
             AND T1.CURR_CD = 'CNY'
             AND T1.BENM_INRAT_TYPE = '#'
             AND T1.DATE_SOURCESD = 'BMS-票据转贴' --给一个不存在指标号，为了放在1.1.3 贷款
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);
        COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.1.3.1、1.1.3.2、其他浮动利率贷款利息数据进A_REPT_DWD_G3301完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1.3.1、1.1.3.2、其他浮动利率贷款利息数据进ID_G3301_ITEMDATA_DKLX中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --133应收利息  应计利息+应收利息   保留是为了与总账利息做轧差
    INSERT 
    INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_DKLX 
      (ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T) --20年以上
      SELECT 
       T1.ORG_NUM,
       I_DATADATE,
       T1.ITEM_CD,
       CASE --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
         WHEN T1.BENM_INRAT_TYPE = 'A' OR
              (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账') THEN --基准利率类型（B基准率,A LPR利率,#空值）
          'G33_I_1.1.3.1'
         WHEN (T1.BENM_INRAT_TYPE = 'B') THEN
          'G33_I_1.1.3.2'
         WHEN T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'BMS-票据转贴' THEN
          'G33_I_1.1.3.3' --给一个不存在指标号，为了放在1.1.3 贷款
       END,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --浮动利率,应计利息按还款计划表下一还款日
              T1.ACCU_INT_AMT
             ELSE
              0
           END) AS AMOUNT_B,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
             ELSE
              0
           END) + SUM(CASE
                        WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                             T1.IDENTITY_CODE = '4' THEN --逾期90天内利息
                         NVL(T1.OD_INT, 0)  +
                         NVL(T1.OD_INT_YGZ, 0)
                        ELSE
                         0
                      END) + SUM(CASE
                                   WHEN T1.IDENTITY_CODE = '3' THEN --没有逾期天数，算作正常数据的营改增挂账利息要取出来
                                    NVL(T1.OD_INT_YGZ, 0)
                                   ELSE
                                    0
                                 END) AS AMOUNT_C,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
             ELSE
              0
           END) AS AMOUNT_D,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
             ELSE
              0
           END) AS AMOUNT_E,

       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
             ELSE
              0
           END) AS AMOUNT_F,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
             ELSE
              0
           END) AS AMOUNT_G,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
             ELSE
              0
           END) AS AMOUNT_H,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
             ELSE
              0
           END) AS AMOUNT_I,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
             ELSE
              0
           END) AS AMOUNT_J,

       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
             ELSE
              0
           END) AS AMOUNT_K,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
             ELSE
              0
           END) AS AMOUNT_L,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
             ELSE
              0
           END) AS AMOUNT_M,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
             ELSE
              0
           END) AS AMOUNT_N,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
             ELSE
              0
           END) AS AMOUNT_O,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
             ELSE
              0
           END) AS AMOUNT_P,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
             ELSE
              0
           END) AS AMOUNT_Q,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
             ELSE
              0
           END) AS AMOUNT_R,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
             ELSE
              0
           END) AS AMOUNT_S,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
             ELSE
              0
           END) AS AMOUNT_T
        FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LX T1
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.BOOK_TYPE = '2'
         AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
         AND T1.CURR_CD='CNY'
       GROUP BY T1.ORG_NUM, T1.ITEM_CD,T1.BENM_INRAT_TYPE,T1.DATE_SOURCESD;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.1.3.1、1.1.3.2、其他浮动利率贷款利息数据进ID_G3301_ITEMDATA_DKLX中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.2 具备提前还款权的固定利率零售类贷款本金数据进FDM_LNAC_PMT_BJ_Q中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --=============================================== 浮动利率贷款==============================================

    --===============================================  1.2 具备提前还款权的固定利率零售类贷款  零售+小微企业授信额度1000万 ，其他都放在1.3==============================================
    --处理明细数据   零售+小微企业本金利息
        INSERT 
        INTO PM_RSDATA.CBRC_FDM_LNAC_PMT_BJ_Q
          (DATA_DATE,
           LOAN_NUM,
           ITEM_CD,
           ORG_NUM,
           NEXT_PAYMENT,
           PMT_REMAIN_TERM_C,
           IDENTITY_CODE,
           FLAG,
           ACCT_STATUS_1104,
           CUST_ID, --客户号 -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
           DATA_DEPARTMENT, --数据条线 -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
           CURR_CD --币种 -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
           )
          SELECT 
           T1.DATA_DATE,
           T1.LOAN_NUM,
           T1.ITEM_CD,
           T1.ORG_NUM,
           T1.NEXT_PAYMENT,
           T1.PMT_REMAIN_TERM_C,
           T1.IDENTITY_CODE,
           '01' AS FLAG,
           T1.ACCT_STATUS_1104,
           T.CUST_ID,
           T1.DATA_DEPARTMENT,
           T1.CURR_CD
            FROM PM_RSDATA.CBRC_FDM_LNAC T
           INNER JOIN PM_RSDATA.CBRC_FDM_LNAC_PMT T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
           INNER JOIN PM_RSDATA.SMTMODS_L_CUST_P B
              ON T.CUST_ID = B.CUST_ID
             AND T.DATA_DATE = B.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T.CURR_CD = 'CNY';

    COMMIT;
            INSERT 
            INTO PM_RSDATA.CBRC_FDM_LNAC_PMT_BJ_Q
              (DATA_DATE,
               LOAN_NUM,
               ITEM_CD,
               ORG_NUM,
               NEXT_PAYMENT,
               PMT_REMAIN_TERM_C,
               IDENTITY_CODE,
               FLAG,
               ACCT_STATUS_1104,
               CORP_SCALE, --企业规模 -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
               FACILITY_AMT,--授信额度 -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
               CUST_ID,--客户号-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
               DATA_DEPARTMENT,--数据条线-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
               CURR_CD) --币种 -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
              SELECT 
               T1.DATA_DATE,
               T1.LOAN_NUM,
               T1.ITEM_CD,
               T1.ORG_NUM,
               T1.NEXT_PAYMENT,
               T1.PMT_REMAIN_TERM_C,
               T1.IDENTITY_CODE,
               '02' AS FLAG,
               T1.ACCT_STATUS_1104,
               B.CORP_SCALE,
               A.FACILITY_AMT,
               T.CUST_ID,
               T1.DATA_DEPARTMENT,
               T1.CURR_CD
                FROM PM_RSDATA.CBRC_FDM_LNAC T
               INNER JOIN PM_RSDATA.CBRC_FDM_LNAC_PMT T1
                  ON T.LOAN_NUM = T1.LOAN_NUM
                 AND T.DATA_DATE = T1.DATA_DATE
               INNER JOIN (SELECT CUST_ID, SUM(FACILITY_AMT) FACILITY_AMT
                             FROM PM_RSDATA.SMTMODS_L_AGRE_CREDITLINE
                            WHERE DATA_DATE = I_DATADATE
                           /*AND ORG_NUM NOT LIKE '51%'*/
                            GROUP BY CUST_ID) A
                  ON T.CUST_ID = A.CUST_ID
               INNER JOIN PM_RSDATA.SMTMODS_L_CUST_C B
                  ON T.CUST_ID = B.CUST_ID
                 AND T.DATA_DATE = B.DATA_DATE
               WHERE T1.DATA_DATE = I_DATADATE
                 AND T1.BOOK_TYPE = '2'
                 AND T1.INT_RATE_TYP = 'F'
                 AND A.FACILITY_AMT <= '10000000' --授信额度  1000万的小微企业
                 AND B.CORP_SCALE IN ('S', 'T')
                 AND T.CURR_CD = 'CNY';
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.2 具备提前还款权的固定利率零售类贷款本金数据进FDM_LNAC_PMT_BJ_Q中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.2 具备提前还款权的固定利率零售类贷款利息数据进FDM_LNAC_PMT_LX_Q中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

        INSERT 
        INTO PM_RSDATA.CBRC_FDM_LNAC_PMT_LX_Q
          (DATA_DATE,
           LOAN_NUM,
           ITEM_CD,
           ORG_NUM,
           ACCU_INT_AMT,
           OD_INT,
           OD_INT_YGZ,
           PMT_REMAIN_TERM_C,
           IDENTITY_CODE,
           FLAG,
           CUST_ID, --客户号 -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
           DATA_DEPARTMENT, --数据条线 -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
           CURR_CD --币种 -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
           )
          SELECT 
           T1.DATA_DATE,
           T1.LOAN_NUM,
           T1.ITEM_CD,
           T1.ORG_NUM,
           T1.ACCU_INT_AMT,
           T1.OD_INT,
           T1.OD_INT_YGZ,
           T1.PMT_REMAIN_TERM_C,
           T1.IDENTITY_CODE,
           '01' AS FLAG,
           B.CUST_ID,
           T1.DATA_DEPARTMENT,
           T1.CURR_CD
            FROM PM_RSDATA.CBRC_FDM_LNAC T
           INNER JOIN PM_RSDATA.CBRC_FDM_LNAC_PMT_LX T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
           INNER JOIN PM_RSDATA.SMTMODS_L_CUST_P B --零售
              ON T.CUST_ID = B.CUST_ID
             AND T.DATA_DATE = B.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T.CURR_CD = 'CNY';
    COMMIT;

          INSERT 
          INTO PM_RSDATA.CBRC_FDM_LNAC_PMT_LX_Q
            (DATA_DATE,
             LOAN_NUM,
             ITEM_CD,
             ORG_NUM,
             ACCU_INT_AMT,
             OD_INT,
             OD_INT_YGZ,
             PMT_REMAIN_TERM_C,
             IDENTITY_CODE,
             FLAG,
             CORP_SCALE, --企业规模 -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
             FACILITY_AMT, --授信额度 -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
             CUST_ID, --客户号-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
             DATA_DEPARTMENT, --数据条线 -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
             CURR_CD) --币种 -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
            SELECT 
             T1.DATA_DATE,
             T1.LOAN_NUM,
             T1.ITEM_CD,
             T1.ORG_NUM,
             T1.ACCU_INT_AMT,
             T1.OD_INT,
             T1.OD_INT_YGZ,
             T1.PMT_REMAIN_TERM_C,
             T1.IDENTITY_CODE,
             '02' AS FLAG,
             B.CORP_SCALE,
             A.FACILITY_AMT,
             T.CUST_ID,
             T1.DATA_DEPARTMENT,
             T1.CURR_CD
              FROM PM_RSDATA.CBRC_FDM_LNAC T
             INNER JOIN PM_RSDATA.CBRC_FDM_LNAC_PMT_LX T1
                ON T.LOAN_NUM = T1.LOAN_NUM
               AND T.DATA_DATE = T1.DATA_DATE
             INNER JOIN (SELECT CUST_ID, SUM(FACILITY_AMT) FACILITY_AMT
                           FROM PM_RSDATA.SMTMODS_L_AGRE_CREDITLINE
                          WHERE DATA_DATE = I_DATADATE
                         /*AND ORG_NUM NOT LIKE '51%'*/
                          GROUP BY CUST_ID) A
                ON T.CUST_ID = A.CUST_ID
             INNER JOIN PM_RSDATA.SMTMODS_L_CUST_C B --小微企业
                ON T.CUST_ID = B.CUST_ID
               AND T.DATA_DATE = B.DATA_DATE
             WHERE T1.DATA_DATE = I_DATADATE
               AND T1.BOOK_TYPE = '2'
               AND T1.INT_RATE_TYP = 'F'
               AND A.FACILITY_AMT <= '10000000'
               AND B.CORP_SCALE IN ('S', 'T')
               AND T.CURR_CD = 'CNY';
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.2 具备提前还款权的固定利率零售类贷款利息数据进FDM_LNAC_PMT_LX_Q中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.2 具备提前还款权的固定利率零售类贷款本金数据进A_REPT_DWD_G3301';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

      -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       INSERT 
       INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
         (DATA_DATE,
          ORG_NUM,
          DATA_DEPARTMENT,
          SYS_NAM,
          REP_NUM,
          ITEM_NUM,
          TOTAL_VALUE,
          COL_1,
          COL_2,
          COL_3,
          COL_7,
          COL_12)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.3.B'
            WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.3.C'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.D'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.E'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.F'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.G'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.H'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.I'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.J'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.K'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.L'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.M'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.N'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.O'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.P'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.Q'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.R'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.S'
            WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.3.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
          CUST_ID AS COL_12 --客户号
           FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_BJ_Q T1
          WHERE T1.FLAG = '01' --零售
            AND T1.ORG_NUM <> '009804'
            AND T1.NEXT_PAYMENT <>0;
       COMMIT;

       INSERT 
       INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
         (DATA_DATE,
          ORG_NUM,
          DATA_DEPARTMENT,
          SYS_NAM,
          REP_NUM,
          ITEM_NUM,
          TOTAL_VALUE,
          COL_1,
          COL_2,
          COL_3,
          COL_7,
          COL_12,
          COL_13,
          COL_14)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.3.B'
            WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.3.C'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.D'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.E'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.F'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.G'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.H'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.I'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.J'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.K'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.L'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.M'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.N'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.O'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.P'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.Q'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.R'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.S'
            WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.3.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
          CUST_ID AS COL_12, --客户号
          T2.M_NAME AS COL_13, --企业规模
          FACILITY_AMT AS COL_14 --授信额度
           FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_BJ_Q T1
          LEFT JOIN PM_RSDATA.SMTMODS_A_REPT_DWD_MAPPING T2
            ON T1.CORP_SCALE = T2.M_CODE
            AND T2.M_TABLECODE = 'CORP_SCALE'
          WHERE T1.FLAG = '02' --小微企业授信1000万以下
            AND T1.ORG_NUM <> '009804'
            AND T1.NEXT_PAYMENT <>0;
       COMMIT;

       -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       --金融市场部 转贴现
       -- 小型企业：03、微型企业：04
        INSERT 
        INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_1,
           COL_2,
           COL_3,
           COL_4,
           COL_6,
           COL_7,
           COL_8,
           COL_13)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE <= 1 THEN
              'G33_I_1.3.B'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 2 AND 30 THEN
              'G33_I_1.3.C'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 31 AND 90 THEN
              'G33_I_1.3.D'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 91 AND 180 THEN
              'G33_I_1.3.E'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 181 AND 270 THEN
              'G33_I_1.3.F'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 271 AND 360 THEN
              'G33_I_1.3.G'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 361 AND 540 THEN
              'G33_I_1.3.H'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 541 AND 720 THEN
              'G33_I_1.3.I'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 721 AND 1080 THEN
              'G33_I_1.3.J'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1081 AND 1440 THEN
              'G33_I_1.3.K'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1441 AND 1800 THEN
              'G33_I_1.3.L'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
              'G33_I_1.3.M'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
              'G33_I_1.3.N'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
              'G33_I_1.3.O'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
              'G33_I_1.3.P'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
              'G33_I_1.3.Q'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 10 + 1 AND
                  360 * 15 THEN
              'G33_I_1.3.R'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 15 + 1 AND
                  360 * 20 THEN
              'G33_I_1.3.S'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE > 360 * 20 THEN
              'G33_I_1.3.T'
           END AS ITEM_NUM,
           T.LOAN_ACCT_BAL AS TOTAL_VALUE,
           T.LOAN_NUM AS COL1, --贷款编号
           T.CURR_CD AS COL2, --币种
           T.ITEM_CD AS COL3, --科目
           TO_CHAR(NVL(T1.HOLIDAY_DATE, T.MATURITY_DT), 'YYYY-MM-DD') AS COL4, --到期日（日期）
           T.ACCT_NUM AS COL6, --贷款合同编号
           NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) - I_DATADATE AS COL7, --剩余期限（天数）
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
           END AS COL8, --五级分类
           CASE
             WHEN T3.CORP_SIZE = '01' THEN
              '中型企业'
             WHEN T3.CORP_SIZE = '02' THEN
              '中型企业'
             WHEN T3.CORP_SIZE = '03' THEN
              '小型企业'
             WHEN T3.CORP_SIZE = '04' THEN
              '微型企业'
           END AS COL_13 --企业规模
            FROM PM_RSDATA.CBRC_FDM_LNAC T
           INNER JOIN (SELECT DISTINCT CUST_ID, LEGAL_TYSHXYDM
                         FROM PM_RSDATA.SMTMODS_L_CUST_BILL_TY T
                        WHERE T.DATA_DATE = I_DATADATE) T2
              ON T.CUST_ID = T2.CUST_ID
           INNER JOIN PM_RSDATA.SMTMODS_L_CUST_EXTERNAL_INFO T3
              ON T2.LEGAL_TYSHXYDM = T3.USCD
             AND T3.DATA_DATE = I_DATADATE
            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
              ON TT.DATA_DATE = T.DATA_DATE
             AND TT.BASIC_CCY = T.CURR_CD
             AND TT.FORWARD_CCY = 'CNY'
            LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,
                              MIN(T1.HOLIDAY_DATE) LASTDAY,
                              T.DATA_DATE AS DATADATE
                         FROM PM_RSDATA.SMTMODS_L_PUBL_HOLIDAY T
                         LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE
                                     FROM PM_RSDATA.SMTMODS_L_PUBL_HOLIDAY T
                                    WHERE T.COUNTRY = 'CHN'
                                      AND T.STATE = '220000'
                                      AND T.WORKING_HOLIDAY = 'W' --工作日
                                   ) T1
                           ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE
                          AND T.DATA_DATE = T1.DATA_DATE
                        WHERE T.COUNTRY = 'CHN'
                          AND T.STATE = '220000'
                          AND T.WORKING_HOLIDAY = 'H' --假日
                          AND T.HOLIDAY_DATE <= I_DATADATE
                        GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1
              ON T.MATURITY_DT = T1.HOLIDAY_DATE
             AND T.DATA_DATE = T1.DATADATE
           WHERE T.DATA_DATE = I_DATADATE
             AND T.ACCT_TYP NOT LIKE '90%'
             AND T.LOAN_ACCT_BAL <> 0
             AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
             AND T3.CORP_SIZE IN ('03', '04'); -- 企业规模：大型企业：01、中型企业：02、小型企业：03、微型企业：04

 COMMIT;
          -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]

       -- 大型企业：01、中型企业
       INSERT 
       INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
         (DATA_DATE,
          ORG_NUM,
          DATA_DEPARTMENT,
          SYS_NAM,
          REP_NUM,
          ITEM_NUM,
          TOTAL_VALUE,
           COL_1,
           COL_2,
           COL_3,
           COL_4,
           COL_6,
           COL_7,
           COL_8,
           COL_13)
         SELECT 
          I_DATADATE,
          T.ORG_NUM,
          T.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE <= 1 THEN
             'G33_I_1.4.B'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 2 AND 30 THEN
             'G33_I_1.4.C'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 31 AND 90 THEN
             'G33_I_1.4.D'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 91 AND 180 THEN
             'G33_I_1.4.E'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 181 AND 270 THEN
             'G33_I_1.4.F'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 271 AND 360 THEN
             'G33_I_1.4.G'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 361 AND 540 THEN
             'G33_I_1.4.H'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 541 AND 720 THEN
             'G33_I_1.4.I'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 721 AND 1080 THEN
             'G33_I_1.4.J'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1081 AND 1440 THEN
             'G33_I_1.4.K'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1441 AND 1800 THEN
             'G33_I_1.4.L'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
             'G33_I_1.4.M'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
             'G33_I_1.4.N'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
             'G33_I_1.4.O'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
             'G33_I_1.4.P'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
             'G33_I_1.4.Q'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 10 + 1 AND 360 * 15 THEN
             'G33_I_1.4.R'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
             'G33_I_1.4.S'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE > 360 * 20 THEN
             'G33_I_1.4.T'
          END AS ITEM_NUM,
          T.LOAN_ACCT_BAL AS TOTAL_VALUE,
          T.LOAN_NUM AS COL1, --贷款编号
          T.CURR_CD AS COL2, --币种
          T.ITEM_CD AS COL3, --科目
          TO_CHAR(NVL(T1.HOLIDAY_DATE, T.MATURITY_DT), 'YYYYMMDD') AS COL4, --到期日（日期）
          T.ACCT_NUM AS COL6, --贷款合同编号
          NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) - I_DATADATE AS COL7, --剩余期限（天数）
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
          END AS COL8, --五级分类
          CASE
            WHEN T3.CORP_SIZE = '01' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '02' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '03' THEN
             '小型企业'
            WHEN T3.CORP_SIZE = '04' THEN
             '微型企业'
          END AS COL_13 --企业规模
           FROM PM_RSDATA.CBRC_FDM_LNAC T
          INNER JOIN (SELECT DISTINCT CUST_ID, LEGAL_TYSHXYDM
                        FROM PM_RSDATA.SMTMODS_L_CUST_BILL_TY T
                       WHERE T.DATA_DATE = I_DATADATE) T2
             ON T.CUST_ID = T2.CUST_ID
          INNER JOIN PM_RSDATA.SMTMODS_L_CUST_EXTERNAL_INFO T3
             ON T2.LEGAL_TYSHXYDM = T3.USCD
            AND T3.DATA_DATE = I_DATADATE
           LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
             ON TT.DATA_DATE = T.DATA_DATE
            AND TT.BASIC_CCY = T.CURR_CD
            AND TT.FORWARD_CCY = 'CNY'
           LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,
                             MIN(T1.HOLIDAY_DATE) LASTDAY,
                             T.DATA_DATE AS DATADATE
                        FROM PM_RSDATA.SMTMODS_L_PUBL_HOLIDAY T
                        LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE
                                    FROM PM_RSDATA.SMTMODS_L_PUBL_HOLIDAY T
                                   WHERE T.COUNTRY = 'CHN'
                                     AND T.STATE = '220000'
                                     AND T.WORKING_HOLIDAY = 'W' --工作日
                                  ) T1
                          ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE
                         AND T.DATA_DATE = T1.DATA_DATE
                       WHERE T.COUNTRY = 'CHN'
                         AND T.STATE = '220000'
                         AND T.WORKING_HOLIDAY = 'H' --假日
                         AND T.HOLIDAY_DATE <= I_DATADATE
                       GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1
             ON T.MATURITY_DT = T1.HOLIDAY_DATE
            AND T.DATA_DATE = T1.DATADATE
          WHERE T.DATA_DATE = I_DATADATE
            AND T.ACCT_TYP NOT LIKE '90%'
            AND T.LOAN_ACCT_BAL <> 0
            AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
            AND T3.CORP_SIZE IN ('01', '02'); -- 企业规模：大型企业：01、中型企业：02、小型企业：03、微型企业：04

       COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.2 具备提前还款权的固定利率零售类贷款本金数据进A_REPT_DWD_G3301完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.2 具备提前还款权的固定利率零售类贷款利息数据进A_REPT_DWD_G3301';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
       -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]

      INSERT 
      INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE,
         COL_1,
         COL_2,
         COL_3,
         COL_7,
         COL_12)
        SELECT 
         I_DATADATE,
         T1.ORG_NUM,
         T1.DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         CASE
           WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
            'G33_I_1.3.B'
           WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                T1.IDENTITY_CODE = '3') or
                (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
            'G33_I_1.3.C'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.D'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.E'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.F'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.G'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.H'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.I'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.J'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.K'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.L'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.M'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.N'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.O'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.P'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.Q'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.R'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.S'
           WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
            'G33_I_1.3.T'
         END AS ITEM_NUM,
         CASE
           WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4' THEN
            NVL(T1.OD_INT, 0)
           WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
            T1.ACCU_INT_AMT
         END AS TOTAL_VALUE, --贷款余额
         T1.LOAN_NUM AS COL1, --贷款编号
         T1.CURR_CD AS COL2, --币种
         T1.ITEM_CD AS COL3, --科目
         T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
         CUST_ID AS COL_12 --客户号
          FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LX_Q T1
         WHERE T1.FLAG = '01' --零售利息
           AND T1.ORG_NUM <> '009804'
           AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);
      COMMIT;


        INSERT 
        INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_1,
           COL_2,
           COL_3,
           COL_7,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
           WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
            'G33_I_1.3.B'
           WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                T1.IDENTITY_CODE = '3') or
                (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
            'G33_I_1.3.C'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.D'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.E'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.F'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.G'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.H'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.I'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.J'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.K'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.L'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.M'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.N'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.O'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.P'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.Q'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.R'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.S'
           WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
            'G33_I_1.3.T'
          END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数） 还款计划利息到期日/没有还款计划的利息取下月21号D_DATADATE_CCY + 21
           T1.CUST_ID AS COL_12, --客户号
           T2.M_NAME AS COL_13, --企业规模
           T1.FACILITY_AMT COL_14 --授信额度
            FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LX_Q T1
            LEFT JOIN PM_RSDATA.SMTMODS_A_REPT_DWD_MAPPING T2
              ON T1.CORP_SCALE = T2.M_CODE
             AND T2.M_TABLECODE = 'CORP_SCALE'
           WHERE T1.FLAG = '02' --小微企业1000万以下利息
             AND T1.ORG_NUM <> '009804'
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);
        COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.2 具备提前还款权的固定利率零售类贷款利息数据进A_REPT_DWD_G3301完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.3 具备提前还款权的固定利率批发类贷款本金数据进A_REPT_DWD_G3301';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --===============================================  1.2 具备提前还款权的固定利率零售类贷款  零售+小微企业授信额度1000万 ，其他都放在1.3==============================================
    --===============================================  1.3 具备提前还款权的固定利率批发类贷款 ==============================================

    -- 1.3 具备提前还款权的固定利率批发类贷款
     -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_1,
           COL_2,
           COL_3,
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                  (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '1') or
                  (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM PM_RSDATA.CBRC_FDM_LNAC T
           INNER JOIN PM_RSDATA.CBRC_FDM_LNAC_PMT T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN PM_RSDATA.CBRC_FDM_LNAC_PMT_BJ_Q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有本金数据
             AND T.CURR_CD = 'CNY'
             AND T.ORG_NUM <> '009804'
             AND T1.NEXT_PAYMENT <>0;
COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.3 具备提前还款权的固定利率批发类贷款本金数据进A_REPT_DWD_G3301完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.3 具备提前还款权的固定利率批发类贷款利息数据进A_REPT_DWD_G3301';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
     -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_1,
           COL_2,
           COL_3,
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM PM_RSDATA.CBRC_FDM_LNAC T
           INNER JOIN PM_RSDATA.CBRC_FDM_LNAC_PMT_LX T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN PM_RSDATA.CBRC_FDM_LNAC_PMT_LX_Q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有利息数据
             AND T.CURR_CD = 'CNY'
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);
        COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.3 具备提前还款权的固定利率批发类贷款利息数据进A_REPT_DWD_G3301完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
   --===============================================  1.3 具备提前还款权的固定利率批发类贷款 ==============================================

    --===============================================  信用卡 ==============================================

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：信用卡本金数据进A_REPT_DWD_G3301';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --信用卡：信用卡90天内逾期  +信用卡利息
    --modiy by djh 20241210 1.2 具备提前还款权的固定利率零售类贷款 C列取:关注类（M1+M2+M3）加业务状况表(本外币合并)-科目”1132”
       INSERT 
       INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
         (DATA_DATE,
          ORG_NUM,
          DATA_DEPARTMENT,
          SYS_NAM,
          REP_NUM,
          ITEM_NUM,
          TOTAL_VALUE)
         SELECT  I_DATADATE,
                '009803' AS ORG_NUM,
                '' AS DATA_DEPARTMENT, --数据条线
                'CBRC' AS SYS_NAM,
                'G33' REP_NUM,
                'G33_I_1.3.C' AS ITEM_NUM,
                SUM((NVL(M0, 0) + NVL(T.M1, 0) + NVL(T.M2, 0) +
                    NVL(T.M3, 0) + NVL(T.M4, 0) + NVL(T.M5, 0) +
                    NVL(T.M6, 0) + NVL(T.M6_UP, 0)) * R.CCY_RATE) AS TOTAL_VALUE
           FROM PM_RSDATA.SMTMODS_L_ACCT_CARD_CREDIT T
           LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE R -- 汇率表
             ON R.DATA_DATE = T.DATA_DATE
            AND R.BASIC_CCY = 'CNY'
            AND R.FORWARD_CCY = T.CURR_CD
          WHERE T.DATA_DATE = I_DATADATE
            AND LXQKQS IN (1, 2, 3)
            AND NVL(M0, 0) + NVL(T.M1, 0) + NVL(T.M2, 0) + NVL(T.M3, 0) +
                NVL(T.M4, 0) + NVL(T.M5, 0) + NVL(T.M6, 0) +
                NVL(T.M6_UP, 0) <>0;
       COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：信用卡本金数据进A_REPT_DWD_G3301完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：信用卡利息数据进A_REPT_DWD_G3301';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --modiy by djh 20241210 1.2 具备提前还款权的固定利率零售类贷款 C列取:关注类（M1+M2+M3）加业务状况表(本外币合并)-科目”1132”
     INSERT 
     INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
       (DATA_DATE,
        ORG_NUM,
        DATA_DEPARTMENT,
        SYS_NAM,
        REP_NUM,
        ITEM_NUM,
        TOTAL_VALUE)
       SELECT  I_DATADATE,
              '009803' AS ORG_NUM,
              '' AS DATA_DEPARTMENT, --数据条线
              'CBRC' AS SYS_NAM,
              'G33' REP_NUM,
              'G33_I_1.3.C' AS ITEM_NUM,
              SUM(A.DEBIT_BAL) AS TOTAL_VALUE
         FROM PM_RSDATA.CBRC_FDM_LNAC_GL A
        WHERE A.DATA_DATE = I_DATADATE
          AND A.GL_ACCOUNT = '113201'
          AND A.CURR_CD = 'CNY'
          AND A.DEBIT_BAL <>0;
       COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：信用卡利息数据进A_REPT_DWD_G3301完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --===============================================  信用卡 ==============================================
     --=============================================== 总账与明细差补齐利息数据 ==============================================

    --总账与明细差补齐利息数据，90天以上逾期利息不进总账，因此不用考虑
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：计算133与总账差值利息数据插至ITEM_MINUS_AMT_TEMP1_Q中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --计算133与总账差值
    INSERT INTO PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1_Q
      (ORG_NUM, MINUS_AMT, ITEM_CD, CURR_CD)
      SELECT NVL(P.ORG_NUM, A.ORG_NUM),
             NVL(P.DEBIT_BAL, 0) - NVL(A.AMT, 0) MINUS_AMT,
             '1132',
             NVL(P.CURR_CD, A.CURR_CD)
        FROM (SELECT G.ORG_NUM, SUM(G.DEBIT_BAL) DEBIT_BAL, G.CURR_CD
                FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL G
               INNER JOIN PM_RSDATA.CBRC_ITEM_CD_TEMP TEMP
                  ON G.ITEM_CD = TEMP.ITEM_CD
               WHERE G.DEBIT_BAL <> 0
                 AND G.ITEM_CD LIKE '1132%'
                 AND G.DATA_DATE = I_DATADATE
                 AND G.CURR_CD <> 'BWB'
                 AND G.CURR_CD = 'CNY'
                 AND G.ORG_NUM NOT LIKE '%0000' --去掉分行，汇总时不需要
                 AND G.ORG_NUM NOT IN ('009803', --信用卡从明细出，此处不做差值
                                       /*'510000',*/ --磐石吉银村镇银行
                                       '222222', --东盛除双阳汇总
                                       '333333', --新双阳
                                       '444444', --净月潭除双阳
                                       '555555') --长春分行（除双阳、榆树、农安）
               GROUP BY G.ORG_NUM, G.CURR_CD) P
        FULL JOIN (SELECT 
                    CASE
                      WHEN ORG_NUM LIKE '%98%' THEN
                       ORG_NUM
                      WHEN ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                       '060300'
                      ELSE
                       SUBSTR(ORG_NUM, 1, 4) || '00' --支行
                    END ORG_NUM,
                    T1.CURR_CD,
                    SUM(CASE
                          WHEN T1.IDENTITY_CODE = '3' THEN
                           T1.ACCU_INT_AMT
                          ELSE
                           0
                        END) + SUM(CASE
                                     WHEN T1.PMT_REMAIN_TERM_C <= 90 AND
                                          T1.PMT_REMAIN_TERM_C >= 1 AND
                                          T1.IDENTITY_CODE = '4' THEN --逾期90天内利息
                                      NVL(T1.OD_INT, 0) + NVL(T1.OD_INT_YGZ, 0)
                                     ELSE
                                      0
                                   END) + SUM(CASE
                                                WHEN T1.IDENTITY_CODE = '3' THEN --没有逾期天数，算作正常数据的营改增挂账利息要取出来
                                                 NVL(T1.OD_INT_YGZ, 0)
                                                ELSE
                                                 0
                                              END) AS AMT
                     FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LX T1
                    WHERE T1.DATA_DATE = I_DATADATE
                      AND T1.IDENTITY_CODE IN ('3', '4')
                      AND T1.CURR_CD = 'CNY'
                   -- AND ORG_NUM NOT LIKE '51%'
                    GROUP BY CASE
                               WHEN ORG_NUM LIKE '%98%' THEN
                                ORG_NUM
                               WHEN ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                                '060300'
                               ELSE
                                SUBSTR(ORG_NUM, 1, 4) || '00' --支行
                             END,
                             T1.CURR_CD) A
          ON A.ORG_NUM = P.ORG_NUM
         AND P.CURR_CD = A.CURR_CD;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：计算133与总账差值利息数据插至ITEM_MINUS_AMT_TEMP1_Q中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：计算13301科目数比明细数据大的数据插至ITEM_MINUS_AMT_TEMP_Q中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --计算 13301科目数比明细数据大的
    INSERT INTO PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP_Q
      (ORG_NUM, MINUS_AMT, ITEM_CD, CURR_CD, QX)

      SELECT T.ORG_NUM,
             CASE
               WHEN A.ITEM_NUM = 'AMOUNT_B' THEN
                SUM(T.MINUS_AMT * (1 / 360)) --隔夜
               WHEN A.ITEM_NUM = 'AMOUNT_C' THEN
                SUM(T.MINUS_AMT * (29 / 360)) --隔夜-一个月（含）
               WHEN A.ITEM_NUM = 'AMOUNT_D' THEN
                SUM(T.MINUS_AMT * (60 / 360)) --1个月-3个月（含）
               WHEN A.ITEM_NUM = 'AMOUNT_E' THEN
                SUM(T.MINUS_AMT * (90 / 360)) --3个月-6个月（含）
               WHEN A.ITEM_NUM = 'AMOUNT_F' THEN
                SUM(T.MINUS_AMT * (90 / 360)) --6个月-9个月(含)
               WHEN A.ITEM_NUM = 'AMOUNT_G' THEN
                SUM(T.MINUS_AMT * (90 / 360)) --9个月-1年(含)
             END AMT,
             1132,
             T.CURR_CD,
             A.ITEM_NUM
        FROM PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1_Q T
       INNER JOIN (SELECT 'AMOUNT_B' ITEM_NUM
                     FROM SYSTEM.DUAL
                   UNION ALL
                   SELECT 'AMOUNT_C' ITEM_NUM
                     FROM SYSTEM.DUAL
                   UNION ALL
                   SELECT 'AMOUNT_D' ITEM_NUM
                     FROM SYSTEM.DUAL
                   UNION ALL
                   SELECT 'AMOUNT_E' ITEM_NUM
                     FROM SYSTEM.DUAL
                   UNION ALL
                   SELECT 'AMOUNT_F' ITEM_NUM
                     FROM SYSTEM.DUAL
                   UNION ALL
                   SELECT 'AMOUNT_G' ITEM_NUM
                     FROM SYSTEM.DUAL) A
          ON 1 = 1
       WHERE T.ITEM_CD = '1132'
         AND T.MINUS_AMT > 0
       GROUP BY T.ORG_NUM, A.ITEM_NUM, T.CURR_CD;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：计算13301科目数比明细数据大的数据插至ITEM_MINUS_AMT_TEMP_Q中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：计算13301科目数比明细数据小的数据插至ITEM_MINUS_AMT_TEMP_Q中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --计算 13301科目数比明细数据小的
    INSERT INTO PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP_Q
      (ORG_NUM, MINUS_AMT, ITEM_CD, CURR_CD, QX)
      SELECT C.ORGNO, TEMP.MINUS_AMT, TEMP.ITEM_CD, TEMP.CURR_CD, C.QX
        FROM (SELECT B.ORGNO, B.QX
                FROM (SELECT A.ORGNO,
                             A.QX,
                             SUM(AMT) AMT,
                             ROW_NUMBER() OVER(PARTITION BY A.ORGNO ORDER BY SUM(AMT) DESC) AS RN
                        FROM (SELECT CASE
                                       WHEN ORGNO LIKE '%98%' THEN
                                        ORGNO
                                       ELSE
                                        SUBSTR(ORGNO, 1, 4) || '00'
                                     END AS ORGNO,
                                     AMT,
                                     QX
                                FROM (select  ORGNO,AMOUNT_B AS AMT, 'AMOUNT_B' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_I_1.1.3.1' UNION ALL 
                                      select  ORGNO,AMOUNT_C AS AMT,  'AMOUNT_C' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_I_1.1.3.1' UNION ALL 
                                      select  ORGNO,AMOUNT_D AS AMT,  'AMOUNT_D' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_I_1.1.3.1' UNION ALL 
                                      select  ORGNO,AMOUNT_E AS AMT,  'AMOUNT_E' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_I_1.1.3.1' UNION ALL 
                                      select  ORGNO,AMOUNT_F AS AMT,  'AMOUNT_F' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_I_1.1.3.1' UNION ALL 
                                      select  ORGNO,AMOUNT_G AS AMT,  'AMOUNT_G' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_I_1.1.3.1' UNION ALL 
                                      select  ORGNO,AMOUNT_H AS AMT,  'AMOUNT_H' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_I_1.1.3.1' UNION ALL 
                                      select  ORGNO,AMOUNT_I AS AMT,  'AMOUNT_I' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_I_1.1.3.1' UNION ALL 
                                      select  ORGNO,AMOUNT_J AS AMT,  'AMOUNT_J' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_I_1.1.3.1' UNION ALL 
                                      select  ORGNO,AMOUNT_K AS AMT,  'AMOUNT_K' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_I_1.1.3.1' UNION ALL 
                                      select  ORGNO,AMOUNT_L AS AMT,  'AMOUNT_L' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_I_1.1.3.1' UNION ALL 
                                      select  ORGNO,AMOUNT_M AS AMT,  'AMOUNT_M' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_I_1.1.3.1' UNION ALL 
                                      select  ORGNO,AMOUNT_N AS AMT,  'AMOUNT_N' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_I_1.1.3.1' UNION ALL 
                                      select  ORGNO,AMOUNT_O AS AMT,  'AMOUNT_O' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_I_1.1.3.1' UNION ALL 
                                      select  ORGNO,AMOUNT_P AS AMT,  'AMOUNT_P' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_I_1.1.3.1' UNION ALL 
                                      select  ORGNO,AMOUNT_Q AS AMT,  'AMOUNT_Q' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_I_1.1.3.1' UNION ALL 
                                      select  ORGNO,AMOUNT_R AS AMT,  'AMOUNT_R' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_I_1.1.3.1' UNION ALL 
                                      select  ORGNO,AMOUNT_S AS AMT,  'AMOUNT_S' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_I_1.1.3.1' UNION ALL 
                                      select  ORGNO,AMOUNT_T AS AMT,  'AMOUNT_T' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_I_1.1.3.1' )) A
                       WHERE A.AMT > 0
                       GROUP BY A.ORGNO,
                                A.QX) B
               WHERE B.RN = 1) C
       INNER JOIN PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1_q TEMP
          ON C.ORGNO = TEMP.ORG_NUM
         AND TEMP.MINUS_AMT < 0
         AND TEMP.ITEM_CD LIKE '1132%';
    COMMIT;
    --133处理完成
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：计算13301科目数比明细数据小的数据插至ITEM_MINUS_AMT_TEMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：本金+利息+133与总账找齐利息数据插至ID_G3301_ITEMDATA_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --本金+利息+133与总账找齐利息数据进入汇总表
    -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --本金+利息 已在名细数据A_REPT_DWD_G3301中处理后直接插入VAL结果表
    INSERT 
    INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI 
      (ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T) --20年以上
       SELECT 
    ORG_NUM,
    I_DATADATE AS DATE_STR,
    ITEM_CD,
    'G33_I_1.1.3.1' AS LOCAL_STATION,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_B' THEN MINUS_AMT END), 0) AS AMOUNT_B,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_C' THEN MINUS_AMT END), 0) AS AMOUNT_C,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_D' THEN MINUS_AMT END), 0) AS AMOUNT_D,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_E' THEN MINUS_AMT END), 0) AS AMOUNT_E,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_F' THEN MINUS_AMT END), 0) AS AMOUNT_F,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_G' THEN MINUS_AMT END), 0) AS AMOUNT_G,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_H' THEN MINUS_AMT END), 0) AS AMOUNT_H,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_I' THEN MINUS_AMT END), 0) AS AMOUNT_I,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_J' THEN MINUS_AMT END), 0) AS AMOUNT_J,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_K' THEN MINUS_AMT END), 0) AS AMOUNT_K,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_L' THEN MINUS_AMT END), 0) AS AMOUNT_L,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_M' THEN MINUS_AMT END), 0) AS AMOUNT_M,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_N' THEN MINUS_AMT END), 0) AS AMOUNT_N,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_O' THEN MINUS_AMT END), 0) AS AMOUNT_O,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_P' THEN MINUS_AMT END), 0) AS AMOUNT_P,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_Q' THEN MINUS_AMT END), 0) AS AMOUNT_Q,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_R' THEN MINUS_AMT END), 0) AS AMOUNT_R,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_S' THEN MINUS_AMT END), 0) AS AMOUNT_S,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_T' THEN MINUS_AMT END), 0) AS AMOUNT_T
FROM 
    PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP_q
WHERE 
    ITEM_CD LIKE '1132%'
GROUP BY 
    ORG_NUM, ITEM_CD;
      
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：本金+利息+133与总账找齐利息数据插至ID_G3301_ITEMDATA_NGI中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：贷款利息轧差插至A_REPT_DWD_G3301表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

     -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --分项指标转换   此处插入利息轧差项目，其他在A_REPT_DWD_G3301明细中处理
    /* 1.1.3.1 其中：以贷款市场报价利率（LPR）为定价基础的人民币浮动利率贷款
    1.1.3.2 其中：以人民银行基准利率为定价基础的浮动利率贷款
    1.2 具备提前还款权的固定利率零售类贷款
    1.3 具备提前还款权的固定利率批发类贷款*/
      INSERT 
      INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE)
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.B' ITEM_NUM,
         SUM(T.AMOUNT_B) AS CUR_BAL
          FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_B <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.C' ITEM_NUM,
         SUM(T.AMOUNT_C) AS CUR_BAL
          FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_C <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.D' ITEM_NUM,
         SUM(T.AMOUNT_D) AS CUR_BAL
          FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_D <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.E' ITEM_NUM,
         SUM(T.AMOUNT_E) AS CUR_BAL
          FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_E <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.F' ITEM_NUM,
         SUM(T.AMOUNT_F) AS CUR_BAL
          FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_F <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.G' ITEM_NUM,
         SUM(T.AMOUNT_G) AS CUR_BAL
          FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_G <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.H' ITEM_NUM,
         SUM(T.AMOUNT_H) AS CUR_BAL
          FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_H <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.I' ITEM_NUM,
         SUM(T.AMOUNT_I) AS CUR_BAL
          FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_I <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.J' ITEM_NUM,
         SUM(T.AMOUNT_J) AS CUR_BAL
          FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_J <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.K' ITEM_NUM,
         SUM(T.AMOUNT_K) AS CUR_BAL
          FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_K <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.L' ITEM_NUM,
         SUM(T.AMOUNT_L) AS CUR_BAL
          FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_L <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.M' ITEM_NUM,
         SUM(T.AMOUNT_M) AS CUR_BAL
          FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_M <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.N' ITEM_NUM,
         SUM(T.AMOUNT_N) AS CUR_BAL
          FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_N <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.O' ITEM_NUM,
         SUM(T.AMOUNT_O) AS CUR_BAL
          FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_O <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.P' ITEM_NUM,
         SUM(T.AMOUNT_P) AS CUR_BAL
          FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_P <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.Q' ITEM_NUM,
         SUM(T.AMOUNT_Q) AS CUR_BAL
          FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_Q <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.R' ITEM_NUM,
         SUM(T.AMOUNT_R) AS CUR_BAL
          FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_R <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.S' ITEM_NUM,
         SUM(T.AMOUNT_S) AS CUR_BAL
          FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_S <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.T' ITEM_NUM,
         SUM(T.AMOUNT_T) AS CUR_BAL
          FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_T <> 0
         GROUP BY ORGNO;
      COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：贷款利息轧差数据插至A_REPT_DWD_G3301完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：总项指标汇总1.1.3 贷款至A_REPT_DWD_G3301';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO PM_RSDATA.CBRC_A_REPT_DWD_G3301 
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_1,
           COL_2,
           COL_3,
           COL_4,
           COL_5,
           COL_6,
           COL_7,
           COL_8,
           COL_9,
           COL_10,
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
           COL_1,
           COL_2,
           COL_3,
           COL_4,
           COL_5,
           COL_6,
           COL_7,
           COL_8,
           COL_9,
           COL_10,
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM PM_RSDATA.CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');
        COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：总项指标汇总1.1.3 贷款至A_REPT_DWD_G3301完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


      --2.1.2 发行债券  本金，利息

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：2.1.2 发行债券本金数据进ID_G3301_ITEMDATA_CKBJ中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
       INSERT 
    INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKBJ 
      (ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T) --20年以上
      SELECT T1.ORG_NUM,
             I_DATADATE,
             T1.GL_ITEM_CODE,
             'G33_1_2.1.2' AS LOCAL_STATION,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <= 1 THEN --空值或逾期放在隔夜同G21
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_B,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 2 AND 30 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_C,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 31 AND 90 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_D,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 91 AND 180 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_E,

             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 181 AND 270 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_F,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 271 AND 360 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_G,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 361 AND 540 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_H,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 541 AND 720 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_I,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 721 AND 1080 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_J,

             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 1081 AND 1440 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_K,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 1441 AND 1800 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_L,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 1801 AND 360 * 6 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_M,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_N,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_O,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_P,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_Q,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 10 + 1 AND 360 * 15 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_R,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_S,
             SUM(CASE
                   WHEN REMAIN_TERM_CODE_QX > 360 * 20 THEN
                    ACCT_BAL_RMB
                   ELSE
                    0
                 END) AS AMOUNT_T
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T1
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ACCT_CUR='CNY'
         --AND SUBSTR(T1.GL_ITEM_CODE, 1, 4) = '2502'
           AND T1.GL_ITEM_CODE='25020101'  --发行债券
       GROUP BY T1.ORG_NUM, T1.GL_ITEM_CODE;
  COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：2.1.2 发行债券本金数据进ID_G3301_ITEMDATA_CKBJ中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：2.1.2 发行债券利息数据进ID_G3301_ITEMDATA_CKLX中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

     INSERT 
    INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKLX 
      (ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T) --20年以上
      SELECT T1.ORG_NUM,
             I_DATADATE,
             T1.GL_ITEM_CODE,
             'G33_1_2.1.2' AS LOCAL_STATION,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED IS NULL OR T1.MATUR_DATE_ACCURED - I_DATADATE <= 1 THEN --空值或逾期放在隔夜同G21
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_B,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 2 AND 30 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_C,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 31 AND 90 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_D,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 91 AND 180 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_E,

             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 181 AND 270 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_F,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 271 AND 360 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_G,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 361 AND 540 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_H,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 541 AND 720 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_I,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 721 AND 1080 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_J,

             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 1081 AND 1440 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_K,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 1441 AND 1800 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_L,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_M,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_N,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_O,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_P,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_Q,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 10 + 1 AND 360 * 15 THEN

                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_R,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_S,
             SUM(CASE
                   WHEN T1.MATUR_DATE_ACCURED - I_DATADATE > 360 * 20 THEN
                    NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                   ELSE
                    0
                 END) AS AMOUNT_T
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL T1
       WHERE T1.DATA_DATE = I_DATADATE
       AND T1.ACCT_CUR='CNY'
       --AND SUBSTR(T1.GL_ITEM_CODE, 1, 4) = '2502'
       AND T1.GL_ITEM_CODE='25020101' --发行债券
       GROUP BY T1.ORG_NUM, T1.GL_ITEM_CODE;
  COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：2.1.2 发行债券利息数据进ID_G3301_ITEMDATA_CKLX中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：260科目与明细数据差异插至ITEM_MINUS_AMT_TEMP1_Q中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
--计算 260科目与明细数据差异
INSERT INTO PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1_Q
  (ORG_NUM, MINUS_AMT, ITEM_CD, CURR_CD)
  SELECT NVL(P.ORG_NUM, A.ORG_NUM),
         NVL(P.CREDIT_BAL, 0) - NVL(A.ITEM_VAL, 0) MINUS_AMT,
         '2231',
         NVL(P.CURR_CD, A.ACCT_CUR)
    FROM (SELECT G.ORG_NUM, SUM(G.CREDIT_BAL) CREDIT_BAL, G.CURR_CD
            FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL G
           INNER JOIN PM_RSDATA.CBRC_ITEM_CD_TEMP TEMP
              ON G.ITEM_CD = TEMP.ITEM_CD
           WHERE G.CREDIT_BAL <> 0
             AND G.ITEM_CD IN ('22310101',
                               '22310102',
                               '22310103',
                               '22310104',
                               '22310105',
                               '22310106',
                               '22310107',
                               '22310108',
                               '22310109',
                               '22310110',
                               '22310111',
                               '22310112',
                               '22310113',
                               '22310114',
                               '22310115',
                               '22310116',
                               '22310117',
                               '22310118',
                               '22310119',
                               '22310120',
                               '22310121',
                               '22310122',
                               '22310123',
                               '22310124',
                               '22310125',
                               '22310126',
                               '22310201',
                               '22310202',
                               '22310203',
                               '22310204',
                               '22310205',
                               '22310206',
                               '22310207',
                               '22310208',
                               '22310209',
                               '22310210',
                               '22310211',
                               '22310212',
                               '22310213',
                               '22310214',
                               '22310215',
                               '22310216',
                               '22310217',
                               '22310218',
                               '22310906',
                               '22310915',
                               '22310924',
                               '22311501',
                               '22311502') --债券+G21所有存款对应的利息科目（不包括存款表中同业），其他不要
             AND G.DATA_DATE = I_DATADATE
             AND G.CURR_CD <> 'BWB'
             AND G.CURR_CD = 'CNY'
             AND G.ORG_NUM NOT LIKE '%0000' --去掉分行，汇总时不需要
             AND G.ORG_NUM NOT IN ('009803', --信用卡从明细出，此处不做差值
                                   /*'510000',*/ --磐石吉银村镇银行
                                   '222222', --东盛除双阳汇总
                                   '333333', --新双阳
                                   '444444', --净月潭除双阳
                                   '555555') --长春分行（除双阳、榆树、农安）
           GROUP BY G.ORG_NUM, G.CURR_CD) P
    FULL JOIN (SELECT 
                CASE
                  WHEN A.ORG_NUM LIKE '%98%' THEN
                   A.ORG_NUM
                  WHEN A.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(A.ORG_NUM, 1, 4) || '00' --支行
                END ORG_NUM,
                SUM(NVL(INTEREST_ACCURED, 0) + NVL(INTEREST_ACCURAL, 0)) AS ITEM_VAL,
                ACCT_CUR
                 FROM (SELECT A.ORG_NUM,
                              INTEREST_ACCURED,
                              INTEREST_ACCURAL,
                              ACCT_CUR
                         FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
                        WHERE (A.GL_ITEM_CODE IN
                              ('20110201',
                                '20110101',
                                '20110102',
                                '20110205',
                                '20110110',
                                '20110202',
                                '20110203',
                                '20110204',
                                '20110211',
                                '20110701',
                                '20110103',
                                '20110104',
                                '20110105',
                                '20110106',
                                '20110107',
                                '20110108',
                                '20110109',
                                '20110208',
                                '20110113',
                                '20110114',
                                '20110115',
                                '20110209',
                                '20110210',
                                '20110207',
                                '20110112',
                                '25020101',
                                '25020102',
                                '25020103')
                                  --    需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：石雨，提出人：王曦若 ，修改内容：20110701 改成 2010
                                OR A.GL_ITEM_CODE LIKE  '2010%'
                                 OR A.GL_ITEM_CODE IN ('22410101','20110301','20110302','20110303','22410102','20080101','20090101') --[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
           
                                OR A.GL_ITEM_CODE IN ('20120106', '20120204')) --与G21存款口径保持一致,其他科目不需要取
                          AND (A.INTEREST_ACCURED <> 0 OR
                              INTEREST_ACCURAL <> 0)
                          AND A.ACCT_CUR = 'CNY') A
                GROUP BY CASE
                           WHEN A.ORG_NUM LIKE '%98%' THEN
                            A.ORG_NUM
                           WHEN A.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                            '060300'
                           ELSE
                            SUBSTR(A.ORG_NUM, 1, 4) || '00' --支行
                         END,
                         A.ACCT_CUR) A
      ON A.ORG_NUM = P.ORG_NUM
     AND P.CURR_CD = A.ACCT_CUR;
COMMIT;
/*
--明细虚拟账户应计利息，直接补齐分摊
INSERT INTO PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1_Q
  (ORG_NUM, MINUS_AMT, ITEM_CD, CURR_CD)
  SELECT P.ORG_NUM, P.ITEM_VAL AS MINUS_AMT, '260', P.CURR_CD
    FROM (SELECT \*+PARALLEL(A,4)*\
           CASE
             WHEN A.ORG_NUM LIKE '%98%' THEN
              A.ORG_NUM
             ELSE
              SUBSTR(A.ORG_NUM, 1, 4) || '00'
           END ORG_NUM,
           SUM(NVL(INTEREST_ACCURED, 0) + NVL(INTEREST_ACCURAL, 0)) AS ITEM_VAL,
           ACCT_CUR AS CURR_CD
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
           WHERE A.ACCT_TYP = '9999' --  虚拟账户应计利息
             AND (SUBSTR(A.GL_ITEM_CODE, 1, 6) IN
                 ('223102', '223101') AND A.GL_ITEM_CODE IN ( '22310201', '22310101','22310102','22310103', '22310208','22310209','22310118','22310119', '22310124','22310125','22310126'
                 ,'22310214','22310215','22310216') OR
                 A.GL_ITEM_CODE IN
                 ('26009010204', '26009020104', '26009020204'))
             AND (A.INTEREST_ACCURED <> 0 OR INTEREST_ACCURAL <> 0)
             AND A.ACCT_CUR='CNY'
           GROUP BY CASE
                      WHEN A.ORG_NUM LIKE '%98%' THEN
                       A.ORG_NUM
                      ELSE
                       SUBSTR(A.ORG_NUM, 1, 4) || '00'
                    END,
                    A.ACCT_CUR) P;

COMMIT;*/

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：260科目与明细数据差异插至ITEM_MINUS_AMT_TEMP1_Q中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：260科目数比明细数据大的数据插至ITEM_MINUS_AMT_TEMP_Q中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
--计算 260科目数比明细数据大的

INSERT INTO PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP_Q
  (ORG_NUM, MINUS_AMT, ITEM_CD, CURR_CD, QX)
  SELECT T.ORG_NUM,
         CASE
           WHEN A.ITEM_NUM = 'AMOUNT_B' THEN
            SUM(T.MINUS_AMT * (1 / 360)) --隔夜
           WHEN A.ITEM_NUM = 'AMOUNT_C' THEN
            SUM(T.MINUS_AMT * (29 / 360)) --隔夜-一个月（含）
           WHEN A.ITEM_NUM = 'AMOUNT_D' THEN
            SUM(T.MINUS_AMT * (60 / 360)) --1个月-3个月（含）
           WHEN A.ITEM_NUM = 'AMOUNT_E' THEN
            SUM(T.MINUS_AMT * (90 / 360)) --3个月-6个月（含）
           WHEN A.ITEM_NUM = 'AMOUNT_F' THEN
            SUM(T.MINUS_AMT * (90 / 360)) --6个月-9个月(含)
           WHEN A.ITEM_NUM = 'AMOUNT_G' THEN
            SUM(T.MINUS_AMT * (90 / 360)) --9个月-1年(含)
         END AMT,
         2231,
         T.CURR_CD,
         A.ITEM_NUM
    FROM PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1_Q T
   INNER JOIN (SELECT 'AMOUNT_B' ITEM_NUM
                 FROM SYSTEM.DUAL
               UNION ALL
               SELECT 'AMOUNT_C' ITEM_NUM
                 FROM SYSTEM.DUAL
               UNION ALL
               SELECT 'AMOUNT_D' ITEM_NUM
                 FROM SYSTEM.DUAL
               UNION ALL
               SELECT 'AMOUNT_E' ITEM_NUM
                 FROM SYSTEM.DUAL
               UNION ALL
               SELECT 'AMOUNT_F' ITEM_NUM
                 FROM SYSTEM.DUAL
               UNION ALL
               SELECT 'AMOUNT_G' ITEM_NUM
                 FROM SYSTEM.DUAL ) A
      ON 1 = 1
   WHERE T.ITEM_CD = '2231'
     AND T.MINUS_AMT > 0
   GROUP BY T.ORG_NUM, A.ITEM_NUM, T.CURR_CD, T.ITEM_CD;
 COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：260科目数比明细数据大的数据插至ITEM_MINUS_AMT_TEMP_Q中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：260科目数比明细数据小的数据插至ITEM_MINUS_AMT_TEMP_Q中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
INSERT INTO
 PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP_Q (
ORG_NUM ,
MINUS_AMT ,
ITEM_CD ,
CURR_CD,
QX
)
SELECT C.ORGNO, TEMP.MINUS_AMT, TEMP.ITEM_CD, TEMP.CURR_CD, C.QX
        FROM (SELECT B.ORGNO, B.QX
                FROM (SELECT A.ORGNO,
                             A.QX,
                             SUM(AMT) AMT,
                             ROW_NUMBER() OVER(PARTITION BY A.ORGNO ORDER BY SUM(AMT) DESC) AS RN
                        FROM (SELECT CASE
                                   WHEN ORGNO LIKE '%98%' THEN
                                    ORGNO
                                   WHEN ORGNO LIKE '060101' THEN '060300'
                                   ELSE
                                    SUBSTR(ORGNO, 1, 4) || '00'
                                 END AS ORGNO,
                                     AMT,
                                     QX
                                FROM ( select  ORGNO,AMOUNT_B AS AMT, 'AMOUNT_B' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_1_2.3' UNION ALL 
                                      select  ORGNO,AMOUNT_C AS AMT,  'AMOUNT_C' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_1_2.3' UNION ALL 
                                      select  ORGNO,AMOUNT_D AS AMT,  'AMOUNT_D' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_1_2.3' UNION ALL 
                                      select  ORGNO,AMOUNT_E AS AMT,  'AMOUNT_E' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_1_2.3' UNION ALL 
                                      select  ORGNO,AMOUNT_F AS AMT,  'AMOUNT_F' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_1_2.3' UNION ALL 
                                      select  ORGNO,AMOUNT_G AS AMT,  'AMOUNT_G' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_1_2.3' UNION ALL 
                                      select  ORGNO,AMOUNT_H AS AMT,  'AMOUNT_H' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_1_2.3' UNION ALL 
                                      select  ORGNO,AMOUNT_I AS AMT,  'AMOUNT_I' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_1_2.3' UNION ALL 
                                      select  ORGNO,AMOUNT_J AS AMT,  'AMOUNT_J' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_1_2.3' UNION ALL 
                                      select  ORGNO,AMOUNT_K AS AMT,  'AMOUNT_K' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_1_2.3' UNION ALL 
                                      select  ORGNO,AMOUNT_L AS AMT,  'AMOUNT_L' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_1_2.3' UNION ALL 
                                      select  ORGNO,AMOUNT_M AS AMT,  'AMOUNT_M' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_1_2.3' UNION ALL 
                                      select  ORGNO,AMOUNT_N AS AMT,  'AMOUNT_N' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_1_2.3' UNION ALL 
                                      select  ORGNO,AMOUNT_O AS AMT,  'AMOUNT_O' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_1_2.3' UNION ALL 
                                      select  ORGNO,AMOUNT_P AS AMT,  'AMOUNT_P' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_1_2.3' UNION ALL 
                                      select  ORGNO,AMOUNT_Q AS AMT,  'AMOUNT_Q' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_1_2.3' UNION ALL 
                                      select  ORGNO,AMOUNT_R AS AMT,  'AMOUNT_R' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_1_2.3' UNION ALL 
                                      select  ORGNO,AMOUNT_S AS AMT,  'AMOUNT_S' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_1_2.3' UNION ALL 
                                      select  ORGNO,AMOUNT_T AS AMT,  'AMOUNT_T' AS QX FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_dklx  WHERE LOCAL_STATION = 'G33_1_2.3')
                              ) A
                       WHERE A.AMT > 0
                       GROUP BY A.ORGNO, A.QX) B
               WHERE B.RN = 1) C
 INNER JOIN PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1_Q TEMP
    ON C.ORGNO = TEMP.ORG_NUM
   AND TEMP.MINUS_AMT < 0
   AND TEMP.ITEM_CD LIKE '2231%';
 COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：260科目数比明细数据小的数据插至ITEM_MINUS_AMT_TEMP_Q中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：本金+利息+260与总账找齐利息数据插至ID_G3301_ITEMDATA_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 --本金+利息+260与总账找齐利息数据进入汇总表

    INSERT 
    INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI 
      (ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T) --20年以上
      SELECT 
      --ORGNO,
       CASE
         WHEN ORGNO LIKE '%98%' THEN
          ORGNO
         WHEN ORGNO LIKE '060101' THEN --特殊机构处理 上级非截取00
          '060300'
         ELSE
          SUBSTR(ORGNO, 1, 4) || '00'
       END AS ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKBJ A
      UNION ALL
      SELECT 
       --ORGNO,
       CASE
         WHEN ORGNO LIKE '%98%' THEN
          ORGNO
         WHEN ORGNO LIKE '060101' THEN --特殊机构处理 上级非截取00
          '060300'
         ELSE
          SUBSTR(ORGNO, 1, 4) || '00'
       END AS ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKLX A
      UNION ALL
      SELECT 
    ORG_NUM,
    I_DATADATE AS DATE_STR,
    ITEM_CD,
    'G33_1_2.3' AS LOCAL_STATION,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_B' THEN MINUS_AMT END), 0) AS AMOUNT_B,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_C' THEN MINUS_AMT END), 0) AS AMOUNT_C,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_D' THEN MINUS_AMT END), 0) AS AMOUNT_D,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_E' THEN MINUS_AMT END), 0) AS AMOUNT_E,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_F' THEN MINUS_AMT END), 0) AS AMOUNT_F,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_G' THEN MINUS_AMT END), 0) AS AMOUNT_G,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_H' THEN MINUS_AMT END), 0) AS AMOUNT_H,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_I' THEN MINUS_AMT END), 0) AS AMOUNT_I,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_J' THEN MINUS_AMT END), 0) AS AMOUNT_J,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_K' THEN MINUS_AMT END), 0) AS AMOUNT_K,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_L' THEN MINUS_AMT END), 0) AS AMOUNT_L,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_M' THEN MINUS_AMT END), 0) AS AMOUNT_M,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_N' THEN MINUS_AMT END), 0) AS AMOUNT_N,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_O' THEN MINUS_AMT END), 0) AS AMOUNT_O,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_P' THEN MINUS_AMT END), 0) AS AMOUNT_P,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_Q' THEN MINUS_AMT END), 0) AS AMOUNT_Q,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_R' THEN MINUS_AMT END), 0) AS AMOUNT_R,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_S' THEN MINUS_AMT END), 0) AS AMOUNT_S,
    COALESCE(MAX(CASE WHEN QX = 'AMOUNT_T' THEN MINUS_AMT END), 0) AS AMOUNT_T
FROM 
    PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP_q
WHERE 
    ITEM_CD LIKE '2231%'
GROUP BY 
    ORG_NUM, ITEM_CD;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：本金+利息+260与总账找齐利息数据插至ID_G3301_ITEMDATA_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：存款指标数据插至G3301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 --2.1.3 定期存款 =2.1.3.1 其中：以人民银行基准利率为定价基础的存款
   INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.B.2019' ITEM_NUM,
       SUM(T.AMOUNT_B) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.C.2019' ITEM_NUM,
       SUM(T.AMOUNT_C) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.D.2019' ITEM_NUM,
       SUM(T.AMOUNT_D) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.E.2019' ITEM_NUM,
       SUM(T.AMOUNT_E) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.F.2019' ITEM_NUM,
       SUM(T.AMOUNT_F) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.G.2019' ITEM_NUM,
       SUM(T.AMOUNT_G) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.H.2019' ITEM_NUM,
       SUM(T.AMOUNT_H) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.I.2019' ITEM_NUM,
       SUM(T.AMOUNT_I) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.J.2019' ITEM_NUM,
       SUM(T.AMOUNT_J) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.K.2019' ITEM_NUM,
       SUM(T.AMOUNT_K) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.L.2019' ITEM_NUM,
       SUM(T.AMOUNT_L) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.M.2019' ITEM_NUM,
       SUM(T.AMOUNT_M) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.N.2019' ITEM_NUM,
       SUM(T.AMOUNT_N) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.O.2019' ITEM_NUM,
       SUM(T.AMOUNT_O) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.P.2019' ITEM_NUM,
       SUM(T.AMOUNT_P) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.Q.2019' ITEM_NUM,
       SUM(T.AMOUNT_Q) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.R.2019' ITEM_NUM,
       SUM(T.AMOUNT_R) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.S.2019' ITEM_NUM,
       SUM(T.AMOUNT_S) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.T.2019' ITEM_NUM,
       SUM(T.AMOUNT_T) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
  --2.1.3 定期存款
     INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.B.2019' ITEM_NUM,
       SUM(T.AMOUNT_B) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.C.2019' ITEM_NUM,
       SUM(T.AMOUNT_C) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.D.2019' ITEM_NUM,
       SUM(T.AMOUNT_D) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.E.2019' ITEM_NUM,
       SUM(T.AMOUNT_E) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.F.2019' ITEM_NUM,
       SUM(T.AMOUNT_F) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.G.2019' ITEM_NUM,
       SUM(T.AMOUNT_G) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.H.2019' ITEM_NUM,
       SUM(T.AMOUNT_H) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.I.2019' ITEM_NUM,
       SUM(T.AMOUNT_I) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.J.2019' ITEM_NUM,
       SUM(T.AMOUNT_J) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.K.2019' ITEM_NUM,
       SUM(T.AMOUNT_K) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.L.2019' ITEM_NUM,
       SUM(T.AMOUNT_L) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.M.2019' ITEM_NUM,
       SUM(T.AMOUNT_M) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.N.2019' ITEM_NUM,
       SUM(T.AMOUNT_N) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.O.2019' ITEM_NUM,
       SUM(T.AMOUNT_O) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.P.2019' ITEM_NUM,
       SUM(T.AMOUNT_P) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.Q.2019' ITEM_NUM,
       SUM(T.AMOUNT_Q) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.R.2019' ITEM_NUM,
       SUM(T.AMOUNT_R) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.S.2019' ITEM_NUM,
       SUM(T.AMOUNT_S) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.T.2019' ITEM_NUM,
       SUM(T.AMOUNT_T) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
 --2.2 无到期日存款
  INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.2.B.2019' ITEM_NUM,
       SUM(T.AMOUNT_B) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.2.B.2019'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
 --2.3 可提前支取的定期零售类存款
   INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.3.B.2019' ITEM_NUM,
       SUM(T.AMOUNT_B) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.3'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.3.C.2019' ITEM_NUM,
       SUM(T.AMOUNT_C) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.3'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.3.D.2019' ITEM_NUM,
       SUM(T.AMOUNT_D) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.3'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.3.E.2019' ITEM_NUM,
       SUM(T.AMOUNT_E) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.3'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.3.F.2019' ITEM_NUM,
       SUM(T.AMOUNT_F) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.3'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.3.G.2019' ITEM_NUM,
       SUM(T.AMOUNT_G) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.3'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.3.H.2019' ITEM_NUM,
       SUM(T.AMOUNT_H) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.3'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.3.I.2019' ITEM_NUM,
       SUM(T.AMOUNT_I) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.3'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.3.J.2019' ITEM_NUM,
       SUM(T.AMOUNT_J) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.3'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.3.K.2019' ITEM_NUM,
       SUM(T.AMOUNT_K) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.3'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.3.L.2019' ITEM_NUM,
       SUM(T.AMOUNT_L) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.3'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.3.M.2019' ITEM_NUM,
       SUM(T.AMOUNT_M) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.3'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.3.N.2019' ITEM_NUM,
       SUM(T.AMOUNT_N) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.3'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.3.O.2019' ITEM_NUM,
       SUM(T.AMOUNT_O) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.3'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.3.P.2019' ITEM_NUM,
       SUM(T.AMOUNT_P) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.3'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.3.Q.2019' ITEM_NUM,
       SUM(T.AMOUNT_Q) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.3'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.3.R.2019' ITEM_NUM,
       SUM(T.AMOUNT_R) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.3'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.3.S.2019' ITEM_NUM,
       SUM(T.AMOUNT_S) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.3'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.3.T.2019' ITEM_NUM,
       SUM(T.AMOUNT_T) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.3'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;

 --2.4 可提前支取的定期批发类存款
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.B.2019' ITEM_NUM,
       SUM(T.AMOUNT_B) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.C.2019' ITEM_NUM,
       SUM(T.AMOUNT_C) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.D.2019' ITEM_NUM,
       SUM(T.AMOUNT_D) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.E.2019' ITEM_NUM,
       SUM(T.AMOUNT_E) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.F.2019' ITEM_NUM,
       SUM(T.AMOUNT_F) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.G.2019' ITEM_NUM,
       SUM(T.AMOUNT_G) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.H.2019' ITEM_NUM,
       SUM(T.AMOUNT_H) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.I.2019' ITEM_NUM,
       SUM(T.AMOUNT_I) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.J.2019' ITEM_NUM,
       SUM(T.AMOUNT_J) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.K.2019' ITEM_NUM,
       SUM(T.AMOUNT_K) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.L.2019' ITEM_NUM,
       SUM(T.AMOUNT_L) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.M.2019' ITEM_NUM,
       SUM(T.AMOUNT_M) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.N.2019' ITEM_NUM,
       SUM(T.AMOUNT_N) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.O.2019' ITEM_NUM,
       SUM(T.AMOUNT_O) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.P.2019' ITEM_NUM,
       SUM(T.AMOUNT_P) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.Q.2019' ITEM_NUM,
       SUM(T.AMOUNT_Q) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.R.2019' ITEM_NUM,
       SUM(T.AMOUNT_R) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.S.2019' ITEM_NUM,
       SUM(T.AMOUNT_S) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.T.2019' ITEM_NUM,
       SUM(T.AMOUNT_T) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;

    --272 债券
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.B.2019' ITEM_NUM,
       SUM(T.AMOUNT_B) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.C.2019' ITEM_NUM,
       SUM(T.AMOUNT_C) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.D.2019' ITEM_NUM,
       SUM(T.AMOUNT_D) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.E.2019' ITEM_NUM,
       SUM(T.AMOUNT_E) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.F.2019' ITEM_NUM,
       SUM(T.AMOUNT_F) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.G.2019' ITEM_NUM,
       SUM(T.AMOUNT_G) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.H.2019' ITEM_NUM,
       SUM(T.AMOUNT_H) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.I.2019' ITEM_NUM,
       SUM(T.AMOUNT_I) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.J.2019' ITEM_NUM,
       SUM(T.AMOUNT_J) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.K.2019' ITEM_NUM,
       SUM(T.AMOUNT_K) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.L.2019' ITEM_NUM,
       SUM(T.AMOUNT_L) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.M.2019' ITEM_NUM,
       SUM(T.AMOUNT_M) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.N.2019' ITEM_NUM,
       SUM(T.AMOUNT_N) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.O.2019' ITEM_NUM,
       SUM(T.AMOUNT_O) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.P.2019' ITEM_NUM,
       SUM(T.AMOUNT_P) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.Q.2019' ITEM_NUM,
       SUM(T.AMOUNT_Q) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.R.2019' ITEM_NUM,
       SUM(T.AMOUNT_R) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.S.2019' ITEM_NUM,
       SUM(T.AMOUNT_S) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.T.2019' ITEM_NUM,
       SUM(T.AMOUNT_T) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：存款指标数据插至G3301_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


------------------------------------------------------------add by djh 20230911  金融市场部指标 ------------------------------------------------------------


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1.1 金融机构间同业资产本金数据进ID_G3301_ITEMDATA_DKBJ中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
 --1.1.1 金融机构间同业资产(本金)
INSERT 
INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_DKBJ 
  (ORGNO,
   RQ,
   SUBJECT,
   LOCAL_STATION,
   AMOUNT_B, --隔夜
   AMOUNT_C, --隔夜-一个月（含）
   AMOUNT_D, --1个月-3个月（含）
   AMOUNT_E, --3个月-6个月（含）
   AMOUNT_F, --6个月-9个月(含)
   AMOUNT_G, --9个月-1年(含)
   AMOUNT_H, --1年-1.5年(含)
   AMOUNT_I, --1.5年-2年(含)
   AMOUNT_J, --2年-3年(含)
   AMOUNT_K, --3年-4年(含)
   AMOUNT_L, --4年-5年(含)
   AMOUNT_M, --5年-6年(含)
   AMOUNT_N, --6年-7年(含)
   AMOUNT_O, --7年-8年(含)
   AMOUNT_P, --8年-9年(含)
   AMOUNT_Q, --9年-10年(含)
   AMOUNT_R, --10年-15年(含)
   AMOUNT_S, --15年-20年(含)
   AMOUNT_T) --20年以上
 SELECT 
  A.ORG_NUM,
  I_DATADATE,
  A.GL_ITEM_CODE,
  'G33_I_1_1.1' AS LOCAL_STATION,
  --  SUM(A.ACCT_BAL_RMB) AS ACCT_BAL_RMB, --账户余额_人民币
  SUM(CASE
        WHEN A.MATUR_DATE IS NULL OR
             A.MATUR_DATE - I_DATADATE <= 1 THEN --空值或逾期放在隔夜同G21
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_B,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 2 AND 30 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_C,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 31 AND 90 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_D,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 91 AND 180 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_E,

  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 181 AND 270 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_F,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 271 AND 360 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_G,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 361 AND 540 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_H,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 541 AND 720 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_I,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 721 AND 1080 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_J,

  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1081 AND 1440 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_K,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1441 AND 1800 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_L,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1801 AND
             360 * 6 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_M,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 6 + 1 AND
             360 * 7 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_N,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 7 + 1 AND
             360 * 8 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_O,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 8 + 1 AND
             360 * 9 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_P,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 9 + 1 AND
             360 * 10 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_Q,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 10 + 1 AND
             360 * 15 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_R,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 15 + 1 AND
             360 * 20 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_S,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE > 360 * 20 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_T --存款剩余期限代码
   FROM  PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
  WHERE FLAG = '03'  --取金融市场部买入返售本金
    AND ACCT_CUR = 'CNY'
    AND A.BOOK_TYPE = '2'
  GROUP BY A.ORG_NUM, I_DATADATE, A.GL_ITEM_CODE;

  COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.1.1 金融机构间同业资产本金数据进ID_G3301_ITEMDATA_DKBJ中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
 --1.1.1 金融机构间同业资产(利息)

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1.1 金融机构间同业资产利息数据进ID_G3301_ITEMDATA_DKLX中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
INSERT 
INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_DKLX 
  (ORGNO,
   RQ,
   SUBJECT,
   LOCAL_STATION,
   AMOUNT_B, --隔夜
   AMOUNT_C, --隔夜-一个月（含）
   AMOUNT_D, --1个月-3个月（含）
   AMOUNT_E, --3个月-6个月（含）
   AMOUNT_F, --6个月-9个月(含)
   AMOUNT_G, --9个月-1年(含)
   AMOUNT_H, --1年-1.5年(含)
   AMOUNT_I, --1.5年-2年(含)
   AMOUNT_J, --2年-3年(含)
   AMOUNT_K, --3年-4年(含)
   AMOUNT_L, --4年-5年(含)
   AMOUNT_M, --5年-6年(含)
   AMOUNT_N, --6年-7年(含)
   AMOUNT_O, --7年-8年(含)
   AMOUNT_P, --8年-9年(含)
   AMOUNT_Q, --9年-10年(含)
   AMOUNT_R, --10年-15年(含)
   AMOUNT_S, --15年-20年(含)
   AMOUNT_T) --20年以上
  SELECT A.ORG_NUM,
         I_DATADATE,
         CASE
           WHEN A.GL_ITEM_CODE = '111101' THEN --买入返售债券
            '11320901' --买入返售债券应收利息
           WHEN A.GL_ITEM_CODE = '111102' THEN --买入返售票据
            '11320902' --买入返售票据应收利息
         END AS SUBJECT,
         'G33_I_1_1.1' AS LOCAL_STATION,
         SUM(CASE
               WHEN A.MATUR_DATE IS NULL OR
                    A.MATUR_DATE - I_DATADATE <= 1 THEN --空值或逾期放在隔夜同G21
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_B,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 2 AND 30 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_C,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 31 AND 90 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_D,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 91 AND 180 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_E,

         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 181 AND 270 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_F,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 271 AND 360 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_G,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 361 AND 540 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_H,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 541 AND 720 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_I,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 721 AND 1080 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_J,

         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1081 AND 1440 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_K,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1441 AND 1800 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_L,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1801 AND
                    360 * 6 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_M,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN
                    360 * 6 + 1 AND 360 * 7 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_N,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN
                    360 * 7 + 1 AND 360 * 8 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_O,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN
                    360 * 8 + 1 AND 360 * 9 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_P,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN
                    360 * 9 + 1 AND 360 * 10 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_Q,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN
                    360 * 10 + 1 AND 360 * 15 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_R,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN
                    360 * 15 + 1 AND 360 * 20 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_S,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE > 360 * 20 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_T
    FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
   WHERE FLAG = '03' --取金融市场部买入返售应收利息
     AND ACCT_CUR = 'CNY'
     AND A.BOOK_TYPE = '2'
     AND MATUR_DATE - I_DATADATE > 0 --逾期的不要
   GROUP BY A.ORG_NUM,
            I_DATADATE,
            CASE
              WHEN A.GL_ITEM_CODE = '111101' THEN --买入返售债券
               '11320901' --买入返售债券应收利息
              WHEN A.GL_ITEM_CODE = '111102' THEN --买入返售票据
               '11320902' --买入返售票据应收利息
            END;
   COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.1.1 金融机构间同业资产利息数据进ID_G3301_ITEMDATA_DKLX中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.1.1 金融机构间同业资产利息数据进ID_G3301_ITEMDATA_DKLX中间表(009820)';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--存放同业009820（活期+定期）+拆放同业的本金和利息按照剩余期限划分；其中存放同业的活期本金+存放同业的活期利息+存放同业的保证金放入隔夜中填报；本金是持有仓位，利息是应收
    INSERT 
    INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_DKBJ 
      (ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T) --20年以上
    SELECT
        '009820' AS ORG_NUM,
        I_DATADATE AS DATA_DATE,
        A.GL_ITEM_CODE AS GL_ITEM_CODE,
        'G33_I_1_1.1' AS LOCAL_STATION,
        SUM(CASE WHEN AMOUNT_NUM = 'B' THEN AMOUNT ELSE 0 END) AS AMOUNT_B, --隔夜
        SUM(CASE WHEN AMOUNT_NUM = 'C' THEN AMOUNT ELSE 0 END) AS AMOUNT_C, --隔夜-一个月（含）
        SUM(CASE WHEN AMOUNT_NUM = 'D' THEN AMOUNT ELSE 0 END) AS AMOUNT_D, --1个月-3个月（含）
        SUM(CASE WHEN AMOUNT_NUM = 'E' THEN AMOUNT ELSE 0 END) AS AMOUNT_E, --3个月-6个月（含）
        SUM(CASE WHEN AMOUNT_NUM = 'F' THEN AMOUNT ELSE 0 END) AS AMOUNT_F, --6个月-9个月(含)
        SUM(CASE WHEN AMOUNT_NUM = 'G' THEN AMOUNT ELSE 0 END) AS AMOUNT_G, --9个月-1年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'H' THEN AMOUNT ELSE 0 END) AS AMOUNT_H, --1年-1.5年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'I' THEN AMOUNT ELSE 0 END) AS AMOUNT_I, --1.5年-2年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'J' THEN AMOUNT ELSE 0 END) AS AMOUNT_J, --2年-3年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'K' THEN AMOUNT ELSE 0 END) AS AMOUNT_K, --3年-4年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'L' THEN AMOUNT ELSE 0 END) AS AMOUNT_L, --4年-5年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'M' THEN AMOUNT ELSE 0 END) AS AMOUNT_M, --5年-6年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'N' THEN AMOUNT ELSE 0 END) AS AMOUNT_N, --6年-7年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'O' THEN AMOUNT ELSE 0 END) AS AMOUNT_O, --7年-8年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'P' THEN AMOUNT ELSE 0 END) AS AMOUNT_P, --8年-9年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'Q' THEN AMOUNT ELSE 0 END) AS AMOUNT_Q, --9年-10年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'R' THEN AMOUNT ELSE 0 END) AS AMOUNT_R, --10年-15年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'S' THEN AMOUNT ELSE 0 END) AS AMOUNT_S, --15年-20年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'T' THEN AMOUNT ELSE 0 END) AS AMOUNT_T
      FROM (SELECT 
             A.GL_ITEM_CODE AS GL_ITEM_CODE,
             CASE
               WHEN A.FLAG = '01' THEN --保证金放在隔夜取数
                'B'
               WHEN A.MATUR_DATE IS NULL OR A.MATUR_DATE - I_DATADATE <= 1 THEN
                'B'
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 2 AND 30 THEN
                'C'
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 31 AND 90 THEN
                'D'
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 91 AND 180 THEN
                'E'
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 181 AND 270 THEN
                'F'
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 271 AND 360 THEN
                'G'
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 361 AND 540 THEN
                'H'
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 541 AND 720 THEN
                'I'
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 721 AND 1080 THEN
                'J'
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1081 AND 1440 THEN
                'K'
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1441 AND 1800 THEN
                'L'
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
                'M'
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
                'N'
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
                'O'
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
                'P'
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
                'Q'
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 10 + 1 AND 360 * 15 THEN
                'R'
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
                'S'
               WHEN A.MATUR_DATE - I_DATADATE > 360 * 20 THEN
                'T'
             END AS AMOUNT_NUM, --存款剩余期限代码
             ACCT_BAL_RMB + INTEREST_ACCURAL AS AMOUNT
              FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
             WHERE A.FLAG IN ('01', '02') --114(存放同业)、 117(存出保证金)  '1011', '1031' 02
               AND A.ACCT_CUR = 'CNY'
               AND A.BOOK_TYPE = '2'
               AND A.ORG_NUM = '009820') A
     GROUP BY AMOUNT_NUM, GL_ITEM_CODE;
    COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.1.1 金融机构间同业资产利息数据进ID_G3301_ITEMDATA_DKLX中间表完成(009820)';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);




    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1.2 债券投资本金数据进ID_G3301_ITEMDATA_DKBJ中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

-- 1.1.2 债券投资,行权日问题在沟通

 --只取银行账户的债券投资，18华阳经贸CP001这个算逾期不取，去掉待偿期小于0数据，
 --行权日-报表日期>0,则代偿期取行权日-报表日期，
 --<0则取原代偿期；用代偿期划分剩余期限；取债券的账面余额+应收应计利息
  INSERT 
  INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_DKBJ 
    (ORGNO,
     RQ,
     SUBJECT,
     LOCAL_STATION,
     AMOUNT_B, --隔夜
     AMOUNT_C, --隔夜-一个月（含）
     AMOUNT_D, --1个月-3个月（含）
     AMOUNT_E, --3个月-6个月（含）
     AMOUNT_F, --6个月-9个月(含)
     AMOUNT_G, --9个月-1年(含)
     AMOUNT_H, --1年-1.5年(含)
     AMOUNT_I, --1.5年-2年(含)
     AMOUNT_J, --2年-3年(含)
     AMOUNT_K, --3年-4年(含)
     AMOUNT_L, --4年-5年(含)
     AMOUNT_M, --5年-6年(含)
     AMOUNT_N, --6年-7年(含)
     AMOUNT_O, --7年-8年(含)
     AMOUNT_P, --8年-9年(含)
     AMOUNT_Q, --9年-10年(含)
     AMOUNT_R, --10年-15年(含)
     AMOUNT_S, --15年-20年(含)
     AMOUNT_T) --20年以上
    SELECT 
     A.ORG_NUM,
     I_DATADATE,
     '',
     'G33_I_1_1.2' AS LOCAL_STATION, -- 1.1.2 债券投资
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END <= 1 THEN
            A.PRINCIPAL_BALANCE
           ELSE
            0
         END) AS AMOUNT_B,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 2 AND 30 THEN
            A.PRINCIPAL_BALANCE
           ELSE
            0
         END) AS AMOUNT_C,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 31 AND 90 THEN
            A.PRINCIPAL_BALANCE
           ELSE
            0
         END) AS AMOUNT_D,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 91 AND 180 THEN
            A.PRINCIPAL_BALANCE
           ELSE
            0
         END) AS AMOUNT_E,

     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 181 AND 270 THEN
            A.PRINCIPAL_BALANCE
           ELSE
            0
         END) AS AMOUNT_F,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 271 AND 360 THEN
            A.PRINCIPAL_BALANCE
           ELSE
            0
         END) AS AMOUNT_G,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 361 AND 540 THEN
            A.PRINCIPAL_BALANCE
           ELSE
            0
         END) AS AMOUNT_H,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 541 AND 720 THEN
            A.PRINCIPAL_BALANCE
           ELSE
            0
         END) AS AMOUNT_I,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 721 AND 1080 THEN
            A.PRINCIPAL_BALANCE
           ELSE
            0
         END) AS AMOUNT_J,

     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 1081 AND 1440 THEN
            A.PRINCIPAL_BALANCE
           ELSE
            0
         END) AS AMOUNT_K,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 1441 AND 1800 THEN
            A.PRINCIPAL_BALANCE
           ELSE
            0
         END) AS AMOUNT_L,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 1801 AND 360 * 6 THEN
            A.PRINCIPAL_BALANCE
           ELSE
            0
         END) AS AMOUNT_M,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
            A.PRINCIPAL_BALANCE
           ELSE
            0
         END) AS AMOUNT_N,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
            A.PRINCIPAL_BALANCE
           ELSE
            0
         END) AS AMOUNT_O,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
            A.PRINCIPAL_BALANCE
           ELSE
            0
         END) AS AMOUNT_P,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
            A.PRINCIPAL_BALANCE
           ELSE
            0
         END) AS AMOUNT_Q,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 360 * 10 + 1 AND 360 * 15 THEN
            A.PRINCIPAL_BALANCE
           ELSE
            0
         END) AS AMOUNT_R,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
            A.PRINCIPAL_BALANCE
           ELSE
            0
         END) AS AMOUNT_S,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END > 360 * 20 THEN
            A.PRINCIPAL_BALANCE
           ELSE
            0
         END) AS AMOUNT_T --存款剩余期限代码
      FROM PM_RSDATA.CBRC_V_PUB_FUND_INVEST A
     WHERE A.DATA_DATE = I_DATADATE
       AND A.INVEST_TYP = '00' --债券
       AND A.ORG_NUM = '009804' --同业金融
       AND A.BOOK_TYPE = '2' --银行账薄
       AND A.DC_DATE > 0
       AND A.SUBJECT_CD <> 'X0003120B2700001'
     GROUP BY A.ORG_NUM, I_DATADATE;
  COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1.2 债券投资本金数据进ID_G3301_ITEMDATA_DKBJ中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1.2 债券投资利息数据进ID_G3301_ITEMDATA_DKBJ中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


-- 1.1.2 债券投资

 --只取银行账户的债券投资，18华阳经贸CP001这个算逾期不取，去掉待偿期小于0数据，
 --行权日-报表日期>0,则代偿期取行权日-报表日期，
 --<0则取原代偿期；用代偿期划分剩余期限；取债券的账面余额+应收应计利息
  INSERT 
  INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_DKBJ 
    (ORGNO,
     RQ,
     SUBJECT,
     LOCAL_STATION,
     AMOUNT_B, --隔夜
     AMOUNT_C, --隔夜-一个月（含）
     AMOUNT_D, --1个月-3个月（含）
     AMOUNT_E, --3个月-6个月（含）
     AMOUNT_F, --6个月-9个月(含)
     AMOUNT_G, --9个月-1年(含)
     AMOUNT_H, --1年-1.5年(含)
     AMOUNT_I, --1.5年-2年(含)
     AMOUNT_J, --2年-3年(含)
     AMOUNT_K, --3年-4年(含)
     AMOUNT_L, --4年-5年(含)
     AMOUNT_M, --5年-6年(含)
     AMOUNT_N, --6年-7年(含)
     AMOUNT_O, --7年-8年(含)
     AMOUNT_P, --8年-9年(含)
     AMOUNT_Q, --9年-10年(含)
     AMOUNT_R, --10年-15年(含)
     AMOUNT_S, --15年-20年(含)
     AMOUNT_T) --20年以上
    SELECT 
     A.ORG_NUM,
     I_DATADATE,
     '',
     'G33_I_1_1.2' AS LOCAL_STATION, -- 1.1.2 债券投资
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END <= 1 THEN
            A.ACCRUAL
           ELSE
            0
         END) AS AMOUNT_B,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 2 AND 30 THEN
            A.ACCRUAL
           ELSE
            0
         END) AS AMOUNT_C,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 31 AND 90 THEN
            A.ACCRUAL
           ELSE
            0
         END) AS AMOUNT_D,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 91 AND 180 THEN
            A.ACCRUAL
           ELSE
            0
         END) AS AMOUNT_E,

     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 181 AND 270 THEN
            A.ACCRUAL
           ELSE
            0
         END) AS AMOUNT_F,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 271 AND 360 THEN
            A.ACCRUAL
           ELSE
            0
         END) AS AMOUNT_G,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 361 AND 540 THEN
            A.ACCRUAL
           ELSE
            0
         END) AS AMOUNT_H,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 541 AND 720 THEN
            A.ACCRUAL
           ELSE
            0
         END) AS AMOUNT_I,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 721 AND 1080 THEN
            A.ACCRUAL
           ELSE
            0
         END) AS AMOUNT_J,

     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 1081 AND 1440 THEN
            A.ACCRUAL
           ELSE
            0
         END) AS AMOUNT_K,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 1441 AND 1800 THEN
            A.ACCRUAL
           ELSE
            0
         END) AS AMOUNT_L,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 1801 AND 360 * 6 THEN
            A.ACCRUAL
           ELSE
            0
         END) AS AMOUNT_M,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
            A.ACCRUAL
           ELSE
            0
         END) AS AMOUNT_N,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
            A.ACCRUAL
           ELSE
            0
         END) AS AMOUNT_O,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
            A.ACCRUAL
           ELSE
            0
         END) AS AMOUNT_P,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
            A.ACCRUAL
           ELSE
            0
         END) AS AMOUNT_Q,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 360 * 10 + 1 AND 360 * 15 THEN
            A.ACCRUAL
           ELSE
            0
         END) AS AMOUNT_R,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
            A.ACCRUAL
           ELSE
            0
         END) AS AMOUNT_S,
     SUM(CASE
           WHEN CASE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NULL THEN  A.DC_DATE
                  WHEN A.INT_RATE_TYP LIKE 'L%' AND A.POWER_DAY IS NOT NULL THEN --浮动
                    CASE
                      WHEN A.POWER_DAY - I_DATADATE < 0 THEN A.DC_DATE
                      ELSE A.POWER_DAY - I_DATADATE
                    END
                 ELSE
                   A.DC_DATE
                END > 360 * 20 THEN
            A.ACCRUAL
           ELSE
            0
         END) AS AMOUNT_T --存款剩余期限代码
      FROM PM_RSDATA.CBRC_V_PUB_FUND_INVEST A
     WHERE A.DATA_DATE = I_DATADATE
       AND A.INVEST_TYP = '00' --债券
       AND A.ORG_NUM = '009804' --同业金融
       AND A.BOOK_TYPE = '2' --银行账薄
       AND A.DC_DATE > 0
       AND A.SUBJECT_CD <> 'X0003120B2700001'
     GROUP BY A.ORG_NUM, I_DATADATE;
  COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1.2 债券投资利息数据进ID_G3301_ITEMDATA_DKBJ中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1.4 其他本金（国民信托）数据进ID_G3301_ITEMDATA_DKBJ中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--1.1.4 其他  只取银行账户同业存单+信托资产（康星系统）取本金+利息按剩余期限划分
--国民信托(本金)
INSERT 
INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_DKBJ 
  (ORGNO,
   RQ,
   SUBJECT,
   LOCAL_STATION,
   AMOUNT_B, --隔夜
   AMOUNT_C, --隔夜-一个月（含）
   AMOUNT_D, --1个月-3个月（含）
   AMOUNT_E, --3个月-6个月（含）
   AMOUNT_F, --6个月-9个月(含)
   AMOUNT_G, --9个月-1年(含)
   AMOUNT_H, --1年-1.5年(含)
   AMOUNT_I, --1.5年-2年(含)
   AMOUNT_J, --2年-3年(含)
   AMOUNT_K, --3年-4年(含)
   AMOUNT_L, --4年-5年(含)
   AMOUNT_M, --5年-6年(含)
   AMOUNT_N, --6年-7年(含)
   AMOUNT_O, --7年-8年(含)
   AMOUNT_P, --8年-9年(含)
   AMOUNT_Q, --9年-10年(含)
   AMOUNT_R, --10年-15年(含)
   AMOUNT_S, --15年-20年(含)
   AMOUNT_T) --20年以上
 SELECT 
  A.ORG_NUM,
  I_DATADATE,
  A.GL_ITEM_CODE,
  'G33_I_1_1.4' AS LOCAL_STATION,
  --  SUM(A.ACCT_BAL_RMB) AS ACCT_BAL_RMB, --账户余额_人民币
  SUM(CASE
        WHEN A.MATURITY_DATE IS NULL OR
             A.MATURITY_DATE - I_DATADATE <= 1 THEN --空值或逾期放在隔夜同G21
         PRINCIPAL_BALANCE_CNY
        ELSE
         0
      END) AS AMOUNT_B,
  SUM(CASE
        WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 2 AND 30 THEN
         PRINCIPAL_BALANCE_CNY
        ELSE
         0
      END) AS AMOUNT_C,
  SUM(CASE
        WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 31 AND 90 THEN
         PRINCIPAL_BALANCE_CNY
        ELSE
         0
      END) AS AMOUNT_D,
  SUM(CASE
        WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 91 AND 180 THEN
         PRINCIPAL_BALANCE_CNY
        ELSE
         0
      END) AS AMOUNT_E,

  SUM(CASE
        WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 181 AND 270 THEN
         PRINCIPAL_BALANCE_CNY
        ELSE
         0
      END) AS AMOUNT_F,
  SUM(CASE
        WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 271 AND 360 THEN
         PRINCIPAL_BALANCE_CNY
        ELSE
         0
      END) AS AMOUNT_G,
  SUM(CASE
        WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 361 AND 540 THEN
         PRINCIPAL_BALANCE_CNY
        ELSE
         0
      END) AS AMOUNT_H,
  SUM(CASE
        WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 541 AND 720 THEN
         PRINCIPAL_BALANCE_CNY
        ELSE
         0
      END) AS AMOUNT_I,
  SUM(CASE
        WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 721 AND 1080 THEN
         PRINCIPAL_BALANCE_CNY
        ELSE
         0
      END) AS AMOUNT_J,

  SUM(CASE
        WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 1081 AND 1440 THEN
         PRINCIPAL_BALANCE_CNY
        ELSE
         0
      END) AS AMOUNT_K,
  SUM(CASE
        WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 1441 AND 1800 THEN
         PRINCIPAL_BALANCE_CNY
        ELSE
         0
      END) AS AMOUNT_L,
  SUM(CASE
        WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 1801 AND
             360 * 6 THEN
         PRINCIPAL_BALANCE_CNY
        ELSE
         0
      END) AS AMOUNT_M,
  SUM(CASE
        WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 360 * 6 + 1 AND
             360 * 7 THEN
         PRINCIPAL_BALANCE_CNY
        ELSE
         0
      END) AS AMOUNT_N,
  SUM(CASE
        WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 360 * 7 + 1 AND
             360 * 8 THEN
         PRINCIPAL_BALANCE_CNY
        ELSE
         0
      END) AS AMOUNT_O,
  SUM(CASE
        WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 360 * 8 + 1 AND
             360 * 9 THEN
         PRINCIPAL_BALANCE_CNY
        ELSE
         0
      END) AS AMOUNT_P,
  SUM(CASE
        WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 360 * 9 + 1 AND
             360 * 10 THEN
         PRINCIPAL_BALANCE_CNY
        ELSE
         0
      END) AS AMOUNT_Q,
  SUM(CASE
        WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 360 * 10 + 1 AND
             360 * 15 THEN
         PRINCIPAL_BALANCE_CNY
        ELSE
         0
      END) AS AMOUNT_R,
  SUM(CASE
        WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 360 * 15 + 1 AND
             360 * 20 THEN
         PRINCIPAL_BALANCE_CNY
        ELSE
         0
      END) AS AMOUNT_S,
  SUM(CASE
        WHEN A.MATURITY_DATE - I_DATADATE > 360 * 20 THEN
         PRINCIPAL_BALANCE_CNY
        ELSE
         0
      END) AS AMOUNT_T --存款剩余期限代码
    FROM PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A
    WHERE   A.GL_ITEM_CODE = '15010201' --业务口径：债权投资特定目的载体投资投资成本,目前就国民信托一笔
    AND A.ORG_NUM = '009804'
    AND A.CURR_CD = 'CNY'
    AND A.BOOK_TYPE = '2'
  GROUP BY A.ORG_NUM, I_DATADATE, A.GL_ITEM_CODE;

COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.1.4 其他本金（国民信托）数据进ID_G3301_ITEMDATA_DKBJ中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1.4 其他利息（国民信托）数据进ID_G3301_ITEMDATA_DKBJ中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 --国民信托(利息)
 INSERT 
 INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_DKLX 
   (ORGNO,
    RQ,
    SUBJECT,
    LOCAL_STATION,
    AMOUNT_B, --隔夜
    AMOUNT_C, --隔夜-一个月（含）
    AMOUNT_D, --1个月-3个月（含）
    AMOUNT_E, --3个月-6个月（含）
    AMOUNT_F, --6个月-9个月(含)
    AMOUNT_G, --9个月-1年(含)
    AMOUNT_H, --1年-1.5年(含)
    AMOUNT_I, --1.5年-2年(含)
    AMOUNT_J, --2年-3年(含)
    AMOUNT_K, --3年-4年(含)
    AMOUNT_L, --4年-5年(含)
    AMOUNT_M, --5年-6年(含)
    AMOUNT_N, --6年-7年(含)
    AMOUNT_O, --7年-8年(含)
    AMOUNT_P, --8年-9年(含)
    AMOUNT_Q, --9年-10年(含)
    AMOUNT_R, --10年-15年(含)
    AMOUNT_S, --15年-20年(含)
    AMOUNT_T) --20年以上
   SELECT 
    A.ORG_NUM,
    I_DATADATE,
    '11320702' AS SUBJECT, --债权投资特定目的载体投资应收利息
    'G33_I_1_1.4' AS LOCAL_STATION,
    --  SUM(A.ACCT_BAL_RMB) AS ACCT_BAL_RMB, --账户余额_人民币
    SUM(CASE
          WHEN A.MATURITY_DATE IS NULL OR
               A.MATURITY_DATE - I_DATADATE <= 1 THEN --空值或逾期放在隔夜同G21
           ACCRUAL_CNY
          ELSE
           0
        END) AS AMOUNT_B,
    SUM(CASE
          WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 2 AND 30 THEN
           ACCRUAL_CNY
          ELSE
           0
        END) AS AMOUNT_C,
    SUM(CASE
          WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 31 AND 90 THEN
           ACCRUAL_CNY
          ELSE
           0
        END) AS AMOUNT_D,
    SUM(CASE
          WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 91 AND 180 THEN
           ACCRUAL_CNY
          ELSE
           0
        END) AS AMOUNT_E,

    SUM(CASE
          WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 181 AND 270 THEN
           ACCRUAL_CNY
          ELSE
           0
        END) AS AMOUNT_F,
    SUM(CASE
          WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 271 AND 360 THEN
           ACCRUAL_CNY
          ELSE
           0
        END) AS AMOUNT_G,
    SUM(CASE
          WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 361 AND 540 THEN
           ACCRUAL_CNY
          ELSE
           0
        END) AS AMOUNT_H,
    SUM(CASE
          WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 541 AND 720 THEN
           ACCRUAL_CNY
          ELSE
           0
        END) AS AMOUNT_I,
    SUM(CASE
          WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 721 AND 1080 THEN
           ACCRUAL_CNY
          ELSE
           0
        END) AS AMOUNT_J,

    SUM(CASE
          WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 1081 AND 1440 THEN
           ACCRUAL_CNY
          ELSE
           0
        END) AS AMOUNT_K,
    SUM(CASE
          WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 1441 AND 1800 THEN
           ACCRUAL_CNY
          ELSE
           0
        END) AS AMOUNT_L,
    SUM(CASE
          WHEN A.MATURITY_DATE - I_DATADATE BETWEEN 1801 AND
               360 * 6 THEN
           ACCRUAL_CNY
          ELSE
           0
        END) AS AMOUNT_M,
    SUM(CASE
          WHEN A.MATURITY_DATE - I_DATADATE BETWEEN
               360 * 6 + 1 AND 360 * 7 THEN
           ACCRUAL_CNY
          ELSE
           0
        END) AS AMOUNT_N,
    SUM(CASE
          WHEN A.MATURITY_DATE - I_DATADATE BETWEEN
               360 * 7 + 1 AND 360 * 8 THEN
           ACCRUAL_CNY
          ELSE
           0
        END) AS AMOUNT_O,
    SUM(CASE
          WHEN A.MATURITY_DATE - I_DATADATE BETWEEN
               360 * 8 + 1 AND 360 * 9 THEN
           ACCRUAL_CNY
          ELSE
           0
        END) AS AMOUNT_P,
    SUM(CASE
          WHEN A.MATURITY_DATE - I_DATADATE BETWEEN
               360 * 9 + 1 AND 360 * 10 THEN
           ACCRUAL_CNY
          ELSE
           0
        END) AS AMOUNT_Q,
    SUM(CASE
          WHEN A.MATURITY_DATE - I_DATADATE BETWEEN
               360 * 10 + 1 AND 360 * 15 THEN
           ACCRUAL_CNY
          ELSE
           0
        END) AS AMOUNT_R,
    SUM(CASE
          WHEN A.MATURITY_DATE - I_DATADATE BETWEEN
               360 * 15 + 1 AND 360 * 20 THEN
           ACCRUAL_CNY
          ELSE
           0
        END) AS AMOUNT_S,
    SUM(CASE
          WHEN A.MATURITY_DATE - I_DATADATE > 360 * 20 THEN
           ACCRUAL_CNY
          ELSE
           0
        END) AS AMOUNT_T --存款剩余期限代码
     FROM PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A
    WHERE A.GL_ITEM_CODE = '15010201' --业务口径：债权投资特定目的载体投资投资成本,目前就国民信托一笔(账户种类为空)
      AND A.ORG_NUM = '009804'
      AND A.CURR_CD = 'CNY'
      AND A.BOOK_TYPE = '2'
    GROUP BY A.ORG_NUM, I_DATADATE, A.GL_ITEM_CODE;

COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.1.4 其他利息（国民信托）数据进ID_G3301_ITEMDATA_DKBJ中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1.4 其他利息数据进ID_G3301_ITEMDATA_DKBJ中间表(009820)';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


/*009820：
基金随时申赎放到隔夜-1个月中填报，取持有仓位+应收利息;
委外：科目为11010303，取账户类型是FVTPL账户的，类型为定向资管计划及收益权投资，集合信托计划及收益权投资，集合资管计划及收益权投资等都放到隔夜-1个月中取持有仓位+公允，其中中信信托2笔（属于信托计划及收益权投资）特殊处理按照到期日划分;
剩余的定开（康星有标识，债券基金投资含定开）按照剩余期限划分，取持有仓位+应收利息投资;
取AC账户（科目15010201）的资产按待偿期划分取持有仓位+应收，其中3笔AC账户的特殊处理（中国华阳经贸集团有限公司，方正证券股份有限公司，东吴基金管理公司）刨除，
其中2笔华创证券有限责任公司的到期日取20281130；）*/
    INSERT 
    INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_DKBJ 
      (ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T) --20年以上
    SELECT
        '009820' AS ORG_NUM,
        I_DATADATE AS DATA_DATE,
        A.GL_ITEM_CODE AS GL_ITEM_CODE,
        'G33_I_1_1.4' AS LOCAL_STATION,
        SUM(CASE WHEN AMOUNT_NUM = 'B' THEN AMOUNT ELSE 0 END) AS AMOUNT_B, --隔夜
        SUM(CASE WHEN AMOUNT_NUM = 'C' THEN AMOUNT ELSE 0 END) AS AMOUNT_C, --隔夜-一个月（含）
        SUM(CASE WHEN AMOUNT_NUM = 'D' THEN AMOUNT ELSE 0 END) AS AMOUNT_D, --1个月-3个月（含）
        SUM(CASE WHEN AMOUNT_NUM = 'E' THEN AMOUNT ELSE 0 END) AS AMOUNT_E, --3个月-6个月（含）
        SUM(CASE WHEN AMOUNT_NUM = 'F' THEN AMOUNT ELSE 0 END) AS AMOUNT_F, --6个月-9个月(含)
        SUM(CASE WHEN AMOUNT_NUM = 'G' THEN AMOUNT ELSE 0 END) AS AMOUNT_G, --9个月-1年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'H' THEN AMOUNT ELSE 0 END) AS AMOUNT_H, --1年-1.5年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'I' THEN AMOUNT ELSE 0 END) AS AMOUNT_I, --1.5年-2年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'J' THEN AMOUNT ELSE 0 END) AS AMOUNT_J, --2年-3年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'K' THEN AMOUNT ELSE 0 END) AS AMOUNT_K, --3年-4年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'L' THEN AMOUNT ELSE 0 END) AS AMOUNT_L, --4年-5年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'M' THEN AMOUNT ELSE 0 END) AS AMOUNT_M, --5年-6年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'N' THEN AMOUNT ELSE 0 END) AS AMOUNT_N, --6年-7年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'O' THEN AMOUNT ELSE 0 END) AS AMOUNT_O, --7年-8年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'P' THEN AMOUNT ELSE 0 END) AS AMOUNT_P, --8年-9年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'Q' THEN AMOUNT ELSE 0 END) AS AMOUNT_Q, --9年-10年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'R' THEN AMOUNT ELSE 0 END) AS AMOUNT_R, --10年-15年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'S' THEN AMOUNT ELSE 0 END) AS AMOUNT_S, --15年-20年(含)
        SUM(CASE WHEN AMOUNT_NUM = 'T' THEN AMOUNT ELSE 0 END) AS AMOUNT_T
      FROM (
      SELECT 
       A.GL_ITEM_CODE AS GL_ITEM_CODE,
       CASE
         WHEN A.FLAG = '06' AND A.REDEMPTION_TYPE = '随时赎回' THEN -- 基金随时申赎放到隔夜-1个月中填报，取持有仓位+应收利息
        'C'
      --委外：科目为11010303，取账户类型是FVTPL账户的，类型为定向资管计划及收益权投资，集合信托计划及收益权投资，
      --集合资管计划及收益权投资等都放到隔夜-1个月中取持有仓位+公允，其中中信信托2笔（属于信托计划及收益权投资）特殊处理按照到期日划分;
         WHEN A.FLAG = '07' AND A.ACCT_NUM NOT IN ('N000310000025496', 'N000310000025495') THEN --
        'C'
      --取AC账户（科目15010201）的资产按待偿期划分取持有仓位+应收，其中3笔AC账户的特殊处理（中国华阳经贸集团有限公司，方正证券股份有限公司，东吴基金管理公司）刨除
         WHEN A.MATUR_DATE IS NULL OR A.MATUR_DATE - I_DATADATE <= 1 THEN
        'B'
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 2 AND 30 THEN
        'C'
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 31 AND 90 THEN
        'D'
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 91 AND 180 THEN
        'E'
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 181 AND 270 THEN
        'F'
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 271 AND 360 THEN
        'G'
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 361 AND 540 THEN
        'H'
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 541 AND 720 THEN
        'I'
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 721 AND 1080 THEN
        'J'
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1081 AND 1440 THEN
        'K'
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1441 AND 1800 THEN
        'L'
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
        'M'
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
        'N'
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
        'O'
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
        'P'
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
        'Q'
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 10 + 1 AND 360 * 15 THEN
        'R'
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
        'S'
         WHEN A.MATUR_DATE - I_DATADATE > 360 * 20 THEN
        'T'
       END AS AMOUNT_NUM, --存款剩余期限代码
       ACCT_BAL_RMB + INTEREST_ACCURAL AS AMOUNT
       FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
      WHERE A.FLAG IN ('06', '07', '08') -- 基金 委外 AC账户
        AND A.ORG_NUM = '009820'
        AND A.BOOK_TYPE = '2'
        AND A.ACCT_NUM NOT IN ('N000310000012993', 'N000310000008023', 'N000310000012013')) A
    GROUP BY AMOUNT_NUM, GL_ITEM_CODE;
COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1.4 其他利息数据进ID_G3301_ITEMDATA_DKBJ中间表(009820)';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);




    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1.4 其他利息数据进ID_G3301_ITEMDATA_DKBJ中间表(009817)';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

/*009817：
存量非标的本金+应收的逾期>90天的不填，其他的按剩余期限填报*/
   INSERT 
   INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_DKLX 
     (ORGNO,
      RQ,
      SUBJECT,
      LOCAL_STATION,
      AMOUNT_B, --隔夜
      AMOUNT_C, --隔夜-一个月（含）
      AMOUNT_D, --1个月-3个月（含）
      AMOUNT_E, --3个月-6个月（含）
      AMOUNT_F, --6个月-9个月(含)
      AMOUNT_G, --9个月-1年(含)
      AMOUNT_H, --1年-1.5年(含)
      AMOUNT_I, --1.5年-2年(含)
      AMOUNT_J, --2年-3年(含)
      AMOUNT_K, --3年-4年(含)
      AMOUNT_L, --4年-5年(含)
      AMOUNT_M, --5年-6年(含)
      AMOUNT_N, --6年-7年(含)
      AMOUNT_O, --7年-8年(含)
      AMOUNT_P, --8年-9年(含)
      AMOUNT_Q, --9年-10年(含)
      AMOUNT_R, --10年-15年(含)
      AMOUNT_S, --15年-20年(含)
      AMOUNT_T) --20年以上
    SELECT 
     A.ORG_NUM,
     I_DATADATE,
     A.GL_ITEM_CODE AS SUBJECT, --债权投资特定目的载体投资应收利息
     'G33_I_1_1.4' AS LOCAL_STATION,
     SUM(CASE
           WHEN A.MATUR_DATE IS NULL OR
                A.MATUR_DATE - I_DATADATE <= 1 THEN --空值或逾期放在隔夜同G21
            ACCT_BAL_RMB
           ELSE
            0
         END) AS AMOUNT_B,
     SUM(CASE
           WHEN A.MATUR_DATE - I_DATADATE BETWEEN 2 AND 30 THEN
            ACCT_BAL_RMB
           ELSE
            0
         END) AS AMOUNT_C,
     SUM(CASE
           WHEN A.MATUR_DATE - I_DATADATE BETWEEN 31 AND 90 THEN
            ACCT_BAL_RMB
           ELSE
            0
         END) AS AMOUNT_D,
     SUM(CASE
           WHEN A.MATUR_DATE - I_DATADATE BETWEEN 91 AND 180 THEN
            ACCT_BAL_RMB
           ELSE
            0
         END) AS AMOUNT_E,

     SUM(CASE
           WHEN A.MATUR_DATE - I_DATADATE BETWEEN 181 AND 270 THEN
            ACCT_BAL_RMB
           ELSE
            0
         END) AS AMOUNT_F,
     SUM(CASE
           WHEN A.MATUR_DATE - I_DATADATE BETWEEN 271 AND 360 THEN
            ACCT_BAL_RMB
           ELSE
            0
         END) AS AMOUNT_G,
     SUM(CASE
           WHEN A.MATUR_DATE - I_DATADATE BETWEEN 361 AND 540 THEN
            ACCT_BAL_RMB
           ELSE
            0
         END) AS AMOUNT_H,
     SUM(CASE
           WHEN A.MATUR_DATE - I_DATADATE BETWEEN 541 AND 720 THEN
            ACCT_BAL_RMB
           ELSE
            0
         END) AS AMOUNT_I,
     SUM(CASE
           WHEN A.MATUR_DATE - I_DATADATE BETWEEN 721 AND 1080 THEN
            ACCT_BAL_RMB
           ELSE
            0
         END) AS AMOUNT_J,

     SUM(CASE
           WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1081 AND 1440 THEN
            ACCT_BAL_RMB
           ELSE
            0
         END) AS AMOUNT_K,
     SUM(CASE
           WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1441 AND 1800 THEN
            ACCT_BAL_RMB
           ELSE
            0
         END) AS AMOUNT_L,
     SUM(CASE
           WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1801 AND
                360 * 6 THEN
            ACCT_BAL_RMB
           ELSE
            0
         END) AS AMOUNT_M,
     SUM(CASE
           WHEN A.MATUR_DATE - I_DATADATE BETWEEN
                360 * 6 + 1 AND 360 * 7 THEN
            ACCT_BAL_RMB
           ELSE
            0
         END) AS AMOUNT_N,
     SUM(CASE
           WHEN A.MATUR_DATE - I_DATADATE BETWEEN
                360 * 7 + 1 AND 360 * 8 THEN
            ACCT_BAL_RMB
           ELSE
            0
         END) AS AMOUNT_O,
     SUM(CASE
           WHEN A.MATUR_DATE - I_DATADATE BETWEEN
                360 * 8 + 1 AND 360 * 9 THEN
            ACCT_BAL_RMB
           ELSE
            0
         END) AS AMOUNT_P,
     SUM(CASE
           WHEN A.MATUR_DATE - I_DATADATE BETWEEN
                360 * 9 + 1 AND 360 * 10 THEN
            ACCT_BAL_RMB
           ELSE
            0
         END) AS AMOUNT_Q,
     SUM(CASE
           WHEN A.MATUR_DATE - I_DATADATE BETWEEN
                360 * 10 + 1 AND 360 * 15 THEN
            ACCT_BAL_RMB
           ELSE
            0
         END) AS AMOUNT_R,
     SUM(CASE
           WHEN A.MATUR_DATE - I_DATADATE BETWEEN
                360 * 15 + 1 AND 360 * 20 THEN
            ACCT_BAL_RMB
           ELSE
            0
         END) AS AMOUNT_S,
     SUM(CASE
           WHEN A.MATUR_DATE - I_DATADATE > 360 * 20 THEN
            ACCT_BAL_RMB
           ELSE
            0
         END) AS AMOUNT_T --存款剩余期限代码
      FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
     WHERE A.FLAG = '09'
       AND A.BOOK_TYPE = '2'
       AND A.MATUR_DATE - I_DATADATE > -90  --逾期90天以上不要
     GROUP BY A.ORG_NUM, A.GL_ITEM_CODE;
 COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1.4 其他利息数据进ID_G3301_ITEMDATA_DKBJ中间表(009817)';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1.4 其他本金（存单）数据进ID_G3301_ITEMDATA_DKBJ中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 --存单本金(本金)
INSERT 
INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_DKBJ 
  (ORGNO,
   RQ,
   SUBJECT,
   LOCAL_STATION,
   AMOUNT_B, --隔夜
   AMOUNT_C, --隔夜-一个月（含）
   AMOUNT_D, --1个月-3个月（含）
   AMOUNT_E, --3个月-6个月（含）
   AMOUNT_F, --6个月-9个月(含)
   AMOUNT_G, --9个月-1年(含)
   AMOUNT_H, --1年-1.5年(含)
   AMOUNT_I, --1.5年-2年(含)
   AMOUNT_J, --2年-3年(含)
   AMOUNT_K, --3年-4年(含)
   AMOUNT_L, --4年-5年(含)
   AMOUNT_M, --5年-6年(含)
   AMOUNT_N, --6年-7年(含)
   AMOUNT_O, --7年-8年(含)
   AMOUNT_P, --8年-9年(含)
   AMOUNT_Q, --9年-10年(含)
   AMOUNT_R, --10年-15年(含)
   AMOUNT_S, --15年-20年(含)
   AMOUNT_T) --20年以上
  SELECT 
   A.ORG_NUM,
   I_DATADATE,
   A.GL_ITEM_CODE,
   'G33_I_1_1.4' AS LOCAL_STATION,
   --  SUM(A.ACCT_BAL_RMB) AS ACCT_BAL_RMB, --账户余额_人民币
   SUM(CASE
         WHEN A.MATUR_DATE IS NULL OR
              A.MATUR_DATE - I_DATADATE <= 1 THEN --空值或逾期放在隔夜同G21
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_B,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 2 AND 30 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_C,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 31 AND 90 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_D,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 91 AND 180 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_E,

   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 181 AND 270 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_F,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 271 AND 360 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_G,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 361 AND 540 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_H,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 541 AND 720 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_I,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 721 AND 1080 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_J,

   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1081 AND 1440 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_K,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1441 AND 1800 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_L,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1801 AND
              360 * 6 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_M,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 6 + 1 AND
              360 * 7 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_N,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 7 + 1 AND
              360 * 8 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_O,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 8 + 1 AND
              360 * 9 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_P,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 9 + 1 AND
              360 * 10 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_Q,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN
              360 * 10 + 1 AND 360 * 15 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_R,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN
              360 * 15 + 1 AND 360 * 20 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_S,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE > 360 * 20 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_T --存款剩余期限代码
    FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
   WHERE FLAG = '04'
     AND ACCT_CUR = 'CNY'
    -- AND A.ORG_NUM = '009804' --此处不限制机构，同业存单 包含金融市场部，同业金融部2个部分数据
     AND BOOK_TYPE = '2'
   GROUP BY A.ORG_NUM, I_DATADATE, A.GL_ITEM_CODE;

COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.1.4 其他本金（存单）数据进ID_G3301_ITEMDATA_DKBJ中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：2.1.1 金融机构间同业负债本金数据进ID_G3301_ITEMDATA_CKBJ中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
--存单(利息) 无利息科目

--2.1.1 金融机构间同业负债
INSERT 
INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKBJ 
  (ORGNO,
   RQ,
   SUBJECT,
   LOCAL_STATION,
   AMOUNT_B, --隔夜
   AMOUNT_C, --隔夜-一个月（含）
   AMOUNT_D, --1个月-3个月（含）
   AMOUNT_E, --3个月-6个月（含）
   AMOUNT_F, --6个月-9个月(含)
   AMOUNT_G, --9个月-1年(含)
   AMOUNT_H, --1年-1.5年(含)
   AMOUNT_I, --1.5年-2年(含)
   AMOUNT_J, --2年-3年(含)
   AMOUNT_K, --3年-4年(含)
   AMOUNT_L, --4年-5年(含)
   AMOUNT_M, --5年-6年(含)
   AMOUNT_N, --6年-7年(含)
   AMOUNT_O, --7年-8年(含)
   AMOUNT_P, --8年-9年(含)
   AMOUNT_Q, --9年-10年(含)
   AMOUNT_R, --10年-15年(含)
   AMOUNT_S, --15年-20年(含)
   AMOUNT_T) --20年以上
  SELECT 
   A.ORG_NUM,
   I_DATADATE,
   A.GL_ITEM_CODE,
   'G33_1_2_1.1' AS LOCAL_STATION,
   --  SUM(A.ACCT_BAL_RMB) AS ACCT_BAL_RMB, --账户余额_人民币
   SUM(CASE
         WHEN A.MATUR_DATE IS NULL OR
              A.MATUR_DATE - I_DATADATE <= 1 THEN --空值或逾期放在隔夜同G21
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_B,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 2 AND 30 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_C,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 31 AND 90 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_D,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 91 AND 180 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_E,

   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 181 AND 270 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_F,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 271 AND 360 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_G,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 361 AND 540 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_H,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 541 AND 720 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_I,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 721 AND 1080 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_J,

   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1081 AND 1440 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_K,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1441 AND 1800 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_L,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1801 AND
              360 * 6 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_M,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 6 + 1 AND
              360 * 7 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_N,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 7 + 1 AND
              360 * 8 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_O,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 8 + 1 AND
              360 * 9 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_P,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 9 + 1 AND
              360 * 10 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_Q,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN
              360 * 10 + 1 AND 360 * 15 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_R,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE BETWEEN
              360 * 15 + 1 AND 360 * 20 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_S,
   SUM(CASE
         WHEN A.MATUR_DATE - I_DATADATE > 360 * 20 THEN
          ACCT_BAL_RMB
         ELSE
          0
       END) AS AMOUNT_T
    FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
   WHERE FLAG IN ('07','05','06','10')--回购 拆入 存单发行 转贷款
     AND A.ORG_NUM IN ('009804','009820')
     AND ACCT_CUR = 'CNY'
     AND BOOK_TYPE = '2'
   GROUP BY A.ORG_NUM, I_DATADATE, A.GL_ITEM_CODE;

COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：2.1.1 金融机构间同业负债本金数据进ID_G3301_ITEMDATA_CKBJ中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：2.1.1 金融机构间同业负债利息数据进ID_G3301_ITEMDATA_CKLX中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

INSERT 
INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKLX 
  (ORGNO,
   RQ,
   SUBJECT,
   LOCAL_STATION,
   AMOUNT_B, --隔夜
   AMOUNT_C, --隔夜-一个月（含）
   AMOUNT_D, --1个月-3个月（含）
   AMOUNT_E, --3个月-6个月（含）
   AMOUNT_F, --6个月-9个月(含)
   AMOUNT_G, --9个月-1年(含)
   AMOUNT_H, --1年-1.5年(含)
   AMOUNT_I, --1.5年-2年(含)
   AMOUNT_J, --2年-3年(含)
   AMOUNT_K, --3年-4年(含)
   AMOUNT_L, --4年-5年(含)
   AMOUNT_M, --5年-6年(含)
   AMOUNT_N, --6年-7年(含)
   AMOUNT_O, --7年-8年(含)
   AMOUNT_P, --8年-9年(含)
   AMOUNT_Q, --9年-10年(含)
   AMOUNT_R, --10年-15年(含)
   AMOUNT_S, --15年-20年(含)
   AMOUNT_T) --20年以上
  SELECT A.ORG_NUM,
         I_DATADATE,
         CASE
           WHEN A.GL_ITEM_CODE = '211101' THEN --卖出回购债券
            '22311201' --卖出回购债券应付利息
           WHEN A.GL_ITEM_CODE = '211102' THEN --卖出回购票据
            '22311202' --卖出回购票据应付利息
         END SUBJECT,
         'G33_1_2_1.1' AS LOCAL_STATION,
         SUM(CASE
               WHEN A.MATUR_DATE IS NULL OR
                    A.MATUR_DATE - I_DATADATE <= 1 THEN --空值或逾期放在隔夜同G21
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_B,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 2 AND 30 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_C,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 31 AND 90 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_D,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 91 AND 180 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_E,

         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 181 AND 270 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_F,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 271 AND 360 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_G,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 361 AND 540 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_H,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 541 AND 720 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_I,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 721 AND 1080 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_J,

         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1081 AND 1440 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_K,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1441 AND 1800 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_L,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1801 AND
                    360 * 6 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_M,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN
                    360 * 6 + 1 AND 360 * 7 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_N,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN
                    360 * 7 + 1 AND 360 * 8 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_O,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN
                    360 * 8 + 1 AND 360 * 9 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_P,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN
                    360 * 9 + 1 AND 360 * 10 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_Q,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN
                    360 * 10 + 1 AND 360 * 15 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_R,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE BETWEEN
                    360 * 15 + 1 AND 360 * 20 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_S,
         SUM(CASE
               WHEN A.MATUR_DATE - I_DATADATE > 360 * 20 THEN
                INTEREST_ACCURAL
               ELSE
                0
             END) AS AMOUNT_T --存款剩余期限代码
    FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
   WHERE FLAG IN ('07','05','06','10')--回购 拆入 存单发行 转贷款
     AND ACCT_CUR = 'CNY'
     AND MATUR_DATE - I_DATADATE > 0 --逾期的不要
     AND A.ORG_NUM IN ('009804','009820')
     AND BOOK_TYPE = '2'
   GROUP BY A.ORG_NUM,
            I_DATADATE,
            CASE
              WHEN A.GL_ITEM_CODE = '211101' THEN --卖出回购债券
               '22311201' --卖出回购债券应付利息
              WHEN A.GL_ITEM_CODE = '211102' THEN --卖出回购票据
               '22311202' --卖出回购票据应付利息
            END;
COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：2.1.1 金融机构间同业负债利息数据进ID_G3301_ITEMDATA_CKLX中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：2.1.4 其他本金数据进ID_G3301_ITEMDATA_CKBJ中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 --  2.1.4 其他

INSERT 
INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKBJ 
  (ORGNO,
   RQ,
   SUBJECT,
   LOCAL_STATION,
   AMOUNT_B, --隔夜
   AMOUNT_C, --隔夜-一个月（含）
   AMOUNT_D, --1个月-3个月（含）
   AMOUNT_E, --3个月-6个月（含）
   AMOUNT_F, --6个月-9个月(含)
   AMOUNT_G, --9个月-1年(含)
   AMOUNT_H, --1年-1.5年(含)
   AMOUNT_I, --1.5年-2年(含)
   AMOUNT_J, --2年-3年(含)
   AMOUNT_K, --3年-4年(含)
   AMOUNT_L, --4年-5年(含)
   AMOUNT_M, --5年-6年(含)
   AMOUNT_N, --6年-7年(含)
   AMOUNT_O, --7年-8年(含)
   AMOUNT_P, --8年-9年(含)
   AMOUNT_Q, --9年-10年(含)
   AMOUNT_R, --10年-15年(含)
   AMOUNT_S, --15年-20年(含)
   AMOUNT_T) --20年以上
 SELECT 
  A.ORG_NUM,
  I_DATADATE,
  A.GL_ITEM_CODE,
  'G33_1_2_1.4' AS LOCAL_STATION,
  --  SUM(A.ACCT_BAL_RMB) AS ACCT_BAL_RMB, --账户余额_人民币
  SUM(CASE
        WHEN A.MATUR_DATE IS NULL OR
             A.MATUR_DATE - I_DATADATE <= 1 THEN --空值或逾期放在隔夜同G21
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_B,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 2 AND 30 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_C,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 31 AND 90 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_D,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 91 AND 180 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_E,

  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 181 AND 270 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_F,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 271 AND 360 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_G,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 361 AND 540 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_H,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 541 AND 720 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_I,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 721 AND 1080 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_J,

  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1081 AND 1440 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_K,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1441 AND 1800 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_L,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 1801 AND
             360 * 6 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_M,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 6 + 1 AND
             360 * 7 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_N,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 7 + 1 AND
             360 * 8 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_O,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 8 + 1 AND
             360 * 9 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_P,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 9 + 1 AND
             360 * 10 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_Q,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 10 + 1 AND
             360 * 15 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_R,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE BETWEEN 360 * 15 + 1 AND
             360 * 20 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_S,
  SUM(CASE
        WHEN A.MATUR_DATE - I_DATADATE > 360 * 20 THEN
         ACCT_BAL_RMB
        ELSE
         0
      END) AS AMOUNT_T --存款剩余期限代码
   FROM  PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
  WHERE FLAG ='02'
    AND A.ORG_NUM='009804'
    and ACCT_BAL_RMB<>0
    and a.gl_item_code='20040201' --再贴现面值,无利息科目
  GROUP BY A.ORG_NUM, I_DATADATE, A.GL_ITEM_CODE;

COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：2.1.4 其他本金数据进ID_G3301_ITEMDATA_CKBJ中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：金融市场部指标数据插至ID_G3301_ITEMDATA_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

     --金融市场部本金+利息数据进入汇总表

    INSERT 
    INTO PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI 
      (ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T) --20年以上
      SELECT 
       ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_DKBJ A
      WHERE A.LOCAL_STATION IN('G33_I_1_1.1','G33_I_1_1.2','G33_I_1_1.4')
      UNION ALL
      SELECT 
       ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_DKLX A
      WHERE A.LOCAL_STATION IN('G33_I_1_1.1','G33_I_1_1.2','G33_I_1_1.4')
       UNION ALL
       SELECT 
       ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKBJ A
      WHERE A.LOCAL_STATION IN('G33_1_2_1.1','G33_1_2_1.4')
      UNION ALL
      SELECT 
       ORGNO,
       RQ,
       SUBJECT,
       LOCAL_STATION,
       AMOUNT_B, --隔夜
       AMOUNT_C, --隔夜-一个月（含）
       AMOUNT_D, --1个月-3个月（含）
       AMOUNT_E, --3个月-6个月（含）
       AMOUNT_F, --6个月-9个月(含)
       AMOUNT_G, --9个月-1年(含)
       AMOUNT_H, --1年-1.5年(含)
       AMOUNT_I, --1.5年-2年(含)
       AMOUNT_J, --2年-3年(含)
       AMOUNT_K, --3年-4年(含)
       AMOUNT_L, --4年-5年(含)
       AMOUNT_M, --5年-6年(含)
       AMOUNT_N, --6年-7年(含)
       AMOUNT_O, --7年-8年(含)
       AMOUNT_P, --8年-9年(含)
       AMOUNT_Q, --9年-10年(含)
       AMOUNT_R, --10年-15年(含)
       AMOUNT_S, --15年-20年(含)
       AMOUNT_T
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_CKLX A
       WHERE A.LOCAL_STATION IN('G33_1_2_1.1','G33_1_2_1.4');

  COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：金融市场部数据插至ID_G3301_ITEMDATA_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：金融市场部指标数据插至G3301_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --总项指标汇总
    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
          'G33_I_1_1.1.B'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
          'G33_I_1_1.2.B'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
          'G33_I_1_1.4.B'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
          'G33_1_2_1.1.B'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
          'G33_1_2_1.4.B'
       END ITEM_NUM,
       SUM(T.AMOUNT_B) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                 'G33_I_1_1.2',
                                 'G33_I_1_1.4',
                                 'G33_1_2_1.1',
                                 'G33_1_2_1.4')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO,
                CASE
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                   'G33_I_1_1.1.B'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                   'G33_I_1_1.2.B'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                   'G33_I_1_1.4.B'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                   'G33_1_2_1.1.B'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                   'G33_1_2_1.4.B'
                END;
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
          'G33_I_1_1.1.C'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
          'G33_I_1_1.2.C'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
          'G33_I_1_1.4.C'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
          'G33_1_2_1.1.C'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
          'G33_1_2_1.4.C'
       END ITEM_NUM,
       SUM(T.AMOUNT_C) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                 'G33_I_1_1.2',
                                 'G33_I_1_1.4',
                                 'G33_1_2_1.1',
                                 'G33_1_2_1.4')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO,
                CASE
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                   'G33_I_1_1.1.C'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                   'G33_I_1_1.2.C'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                   'G33_I_1_1.4.C'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                   'G33_1_2_1.1.C'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                   'G33_1_2_1.4.C'
                END;
    COMMIT;


    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
          'G33_I_1_1.1.D'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
          'G33_I_1_1.2.D'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
          'G33_I_1_1.4.D'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
          'G33_1_2_1.1.D'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
          'G33_1_2_1.4.D'
       END ITEM_NUM,
       SUM(T.AMOUNT_D) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                 'G33_I_1_1.2',
                                 'G33_I_1_1.4',
                                 'G33_1_2_1.1',
                                 'G33_1_2_1.4')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO,
                CASE
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                   'G33_I_1_1.1.D'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                   'G33_I_1_1.2.D'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                   'G33_I_1_1.4.D'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                   'G33_1_2_1.1.D'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                   'G33_1_2_1.4.D'
                END;
    COMMIT;

   INSERT 
   INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
     (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
     SELECT 
      I_DATADATE AS DATA_DATE,
      ORGNO,
      CASE
        WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
         'G33_I_1_1.1.E'
        WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
         'G33_I_1_1.2.E'
        WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
         'G33_I_1_1.4.E'
        WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
         'G33_1_2_1.1.E'
        WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
         'G33_1_2_1.4.E'
      END ITEM_NUM,
      SUM(T.AMOUNT_E) AS CUR_BAL
       FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
      WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                'G33_I_1_1.2',
                                'G33_I_1_1.4',
                                'G33_1_2_1.1',
                                'G33_1_2_1.4')
        AND T.RQ = I_DATADATE
      GROUP BY ORGNO,
               CASE
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                  'G33_I_1_1.1.E'
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                  'G33_I_1_1.2.E'
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                  'G33_I_1_1.4.E'
                 WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                  'G33_1_2_1.1.E'
                 WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                  'G33_1_2_1.4.E'
               END;
    COMMIT;


   INSERT 
   INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
     (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
     SELECT 
      I_DATADATE AS DATA_DATE,
      ORGNO,
      CASE
        WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
         'G33_I_1_1.1.F'
        WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
         'G33_I_1_1.2.F'
        WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
         'G33_I_1_1.4.F'
        WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
         'G33_1_2_1.1.F'
        WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
         'G33_1_2_1.4.F'
      END ITEM_NUM,
      SUM(T.AMOUNT_F) AS CUR_BAL
       FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
      WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                'G33_I_1_1.2',
                                'G33_I_1_1.4',
                                'G33_1_2_1.1',
                                'G33_1_2_1.4')
        AND T.RQ = I_DATADATE
      GROUP BY ORGNO,
               CASE
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                  'G33_I_1_1.1.F'
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                  'G33_I_1_1.2.F'
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                  'G33_I_1_1.4.F'
                 WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                  'G33_1_2_1.1.F'
                 WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                  'G33_1_2_1.4.F'
               END;
    COMMIT;


   INSERT 
   INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
     (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
     SELECT 
      I_DATADATE AS DATA_DATE,
      ORGNO,
      CASE
        WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
         'G33_I_1_1.1.G'
        WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
         'G33_I_1_1.2.G'
        WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
         'G33_I_1_1.4.G'
        WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
         'G33_1_2_1.1.G'
        WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
         'G33_1_2_1.4.G'
      END ITEM_NUM,
      SUM(T.AMOUNT_G) AS CUR_BAL
       FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
      WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                'G33_I_1_1.2',
                                'G33_I_1_1.4',
                                'G33_1_2_1.1',
                                'G33_1_2_1.4')
        AND T.RQ = I_DATADATE
      GROUP BY ORGNO,
               CASE
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                  'G33_I_1_1.1.G'
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                  'G33_I_1_1.2.G'
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                  'G33_I_1_1.4.G'
                 WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                  'G33_1_2_1.1.G'
                 WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                  'G33_1_2_1.4.G'
               END;
    COMMIT;


   INSERT 
   INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
     (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
     SELECT 
      I_DATADATE AS DATA_DATE,
      ORGNO,
      CASE
        WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
         'G33_I_1_1.1.H'
        WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
         'G33_I_1_1.2.H'
        WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
         'G33_I_1_1.4.H'
        WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
         'G33_1_2_1.1.H'
        WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
         'G33_1_2_1.4.H'
      END ITEM_NUM,
      SUM(T.AMOUNT_H) AS CUR_BAL
       FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
      WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                'G33_I_1_1.2',
                                'G33_I_1_1.4',
                                'G33_1_2_1.1',
                                'G33_1_2_1.4')
        AND T.RQ = I_DATADATE
      GROUP BY ORGNO,
               CASE
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                  'G33_I_1_1.1.H'
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                  'G33_I_1_1.2.H'
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                  'G33_I_1_1.4.H'
                 WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                  'G33_1_2_1.1.H'
                 WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                  'G33_1_2_1.4.H'
               END;
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
          'G33_I_1_1.1.I'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
          'G33_I_1_1.2.I'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
          'G33_I_1_1.4.I'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
          'G33_1_2_1.1.I'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
          'G33_1_2_1.4.I'
       END ITEM_NUM,
       SUM(T.AMOUNT_I) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                 'G33_I_1_1.2',
                                 'G33_I_1_1.4',
                                 'G33_1_2_1.1',
                                 'G33_1_2_1.4')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO,
                CASE
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                   'G33_I_1_1.1.I'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                   'G33_I_1_1.2.I'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                   'G33_I_1_1.4.I'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                   'G33_1_2_1.1.I'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                   'G33_1_2_1.4.I'
                END;
    COMMIT;


    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
          'G33_I_1_1.1.J'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
          'G33_I_1_1.2.J'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
          'G33_I_1_1.4.J'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
          'G33_1_2_1.1.J'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
          'G33_1_2_1.4.J'
       END ITEM_NUM,
       SUM(T.AMOUNT_J) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                 'G33_I_1_1.2',
                                 'G33_I_1_1.4',
                                 'G33_1_2_1.1',
                                 'G33_1_2_1.4')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO,
                CASE
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                   'G33_I_1_1.1.J'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                   'G33_I_1_1.2.J'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                   'G33_I_1_1.4.J'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                   'G33_1_2_1.1.J'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                   'G33_1_2_1.4.J'
                END;
    COMMIT;


   INSERT 
   INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
     (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
     SELECT 
      I_DATADATE AS DATA_DATE,
      ORGNO,
      CASE
        WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
         'G33_I_1_1.1.K'
        WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
         'G33_I_1_1.2.K'
        WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
         'G33_I_1_1.4.K'
        WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
         'G33_1_2_1.1.K'
        WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
         'G33_1_2_1.4.K'
      END ITEM_NUM,
      SUM(T.AMOUNT_K) AS CUR_BAL
       FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
      WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                'G33_I_1_1.2',
                                'G33_I_1_1.4',
                                'G33_1_2_1.1',
                                'G33_1_2_1.4')
        AND T.RQ = I_DATADATE
      GROUP BY ORGNO,
               CASE
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                  'G33_I_1_1.1.K'
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                  'G33_I_1_1.2.K'
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                  'G33_I_1_1.4.K'
                 WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                  'G33_1_2_1.1.K'
                 WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                  'G33_1_2_1.4.K'
               END;
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
          'G33_I_1_1.1.L'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
          'G33_I_1_1.2.L'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
          'G33_I_1_1.4.L'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
          'G33_1_2_1.1.L'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
          'G33_1_2_1.4.L'
       END ITEM_NUM,
       SUM(T.AMOUNT_L) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                 'G33_I_1_1.2',
                                 'G33_I_1_1.4',
                                 'G33_1_2_1.1',
                                 'G33_1_2_1.4')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO,
                CASE
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                   'G33_I_1_1.1.L'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                   'G33_I_1_1.2.L'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                   'G33_I_1_1.4.L'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                   'G33_1_2_1.1.L'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                   'G33_1_2_1.4.L'
                END;
    COMMIT;

   INSERT 
   INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
     (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
     SELECT 
      I_DATADATE AS DATA_DATE,
      ORGNO,
      CASE
        WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
         'G33_I_1_1.1.M'
        WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
         'G33_I_1_1.2.M'
        WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
         'G33_I_1_1.4.M'
        WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
         'G33_1_2_1.1.M'
        WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
         'G33_1_2_1.4.M'
      END ITEM_NUM,
      SUM(T.AMOUNT_M) AS CUR_BAL
       FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
      WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                'G33_I_1_1.2',
                                'G33_I_1_1.4',
                                'G33_1_2_1.1',
                                'G33_1_2_1.4')
        AND T.RQ = I_DATADATE
      GROUP BY ORGNO,
               CASE
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                  'G33_I_1_1.1.M'
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                  'G33_I_1_1.2.M'
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                  'G33_I_1_1.4.M'
                 WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                  'G33_1_2_1.1.M'
                 WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                  'G33_1_2_1.4.M'
               END;
     COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
          'G33_I_1_1.1.N'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
          'G33_I_1_1.2.N'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
          'G33_I_1_1.4.N'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
          'G33_1_2_1.1.N'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
          'G33_1_2_1.4.N'
       END ITEM_NUM,
       SUM(T.AMOUNT_N) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                 'G33_I_1_1.2',
                                 'G33_I_1_1.4',
                                 'G33_1_2_1.1',
                                 'G33_1_2_1.4')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO,
                CASE
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                   'G33_I_1_1.1.N'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                   'G33_I_1_1.2.N'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                   'G33_I_1_1.4.N'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                   'G33_1_2_1.1.N'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                   'G33_1_2_1.4.N'
                END;
     COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
          'G33_I_1_1.1.O'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
          'G33_I_1_1.2.O'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
          'G33_I_1_1.4.O'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
          'G33_1_2_1.1.O'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
          'G33_1_2_1.4.O'
       END ITEM_NUM,
       SUM(T.AMOUNT_O) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                 'G33_I_1_1.2',
                                 'G33_I_1_1.4',
                                 'G33_1_2_1.1',
                                 'G33_1_2_1.4')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO,
                CASE
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                   'G33_I_1_1.1.O'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                   'G33_I_1_1.2.O'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                   'G33_I_1_1.4.O'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                   'G33_1_2_1.1.O'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                   'G33_1_2_1.4.O'
                END;
     COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
          'G33_I_1_1.1.P'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
          'G33_I_1_1.2.P'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
          'G33_I_1_1.4.P'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
          'G33_1_2_1.1.P'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
          'G33_1_2_1.4.P'
       END ITEM_NUM,
       SUM(T.AMOUNT_P) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                 'G33_I_1_1.2',
                                 'G33_I_1_1.4',
                                 'G33_1_2_1.1',
                                 'G33_1_2_1.4')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO,
                CASE
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                   'G33_I_1_1.1.P'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                   'G33_I_1_1.2.P'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                   'G33_I_1_1.4.P'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                   'G33_1_2_1.1.P'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                   'G33_1_2_1.4.P'
                END;
     COMMIT;

   INSERT 
   INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
     (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
     SELECT 
      I_DATADATE AS DATA_DATE,
      ORGNO,
      CASE
        WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
         'G33_I_1_1.1.Q'
        WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
         'G33_I_1_1.2.Q'
        WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
         'G33_I_1_1.4.Q'
        WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
         'G33_1_2_1.1.Q'
        WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
         'G33_1_2_1.4.Q'
      END ITEM_NUM,
      SUM(T.AMOUNT_Q) AS CUR_BAL
       FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
      WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                'G33_I_1_1.2',
                                'G33_I_1_1.4',
                                'G33_1_2_1.1',
                                'G33_1_2_1.4')
        AND T.RQ = I_DATADATE
      GROUP BY ORGNO,
               CASE
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                  'G33_I_1_1.1.Q'
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                  'G33_I_1_1.2.Q'
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                  'G33_I_1_1.4.Q'
                 WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                  'G33_1_2_1.1.Q'
                 WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                  'G33_1_2_1.4.Q'
               END;
     COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
          'G33_I_1_1.1.R'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
          'G33_I_1_1.2.R'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
          'G33_I_1_1.4.R'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
          'G33_1_2_1.1.R'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
          'G33_1_2_1.4.R'
       END ITEM_NUM,
       SUM(T.AMOUNT_R) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                 'G33_I_1_1.2',
                                 'G33_I_1_1.4',
                                 'G33_1_2_1.1',
                                 'G33_1_2_1.4')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO,
                CASE
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                   'G33_I_1_1.1.R'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                   'G33_I_1_1.2.R'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                   'G33_I_1_1.4.R'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                   'G33_1_2_1.1.R'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                   'G33_1_2_1.4.R'
                END;
     COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
          'G33_I_1_1.1.S'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
          'G33_I_1_1.2.S'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
          'G33_I_1_1.4.S'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
          'G33_1_2_1.1.S'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
          'G33_1_2_1.4.S'
       END ITEM_NUM,
       SUM(T.AMOUNT_S) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                 'G33_I_1_1.2',
                                 'G33_I_1_1.4',
                                 'G33_1_2_1.1',
                                 'G33_1_2_1.4')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO,
                CASE
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                   'G33_I_1_1.1.S'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                   'G33_I_1_1.2.S'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                   'G33_I_1_1.4.S'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                   'G33_1_2_1.1.S'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                   'G33_1_2_1.4.S'
                END;
     COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
          'G33_I_1_1.1.T'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
          'G33_I_1_1.2.T'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
          'G33_I_1_1.4.T'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
          'G33_1_2_1.1.T'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
          'G33_1_2_1.4.T'
       END ITEM_NUM,
       SUM(T.AMOUNT_T) AS CUR_BAL
        FROM PM_RSDATA.CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                 'G33_I_1_1.2',
                                 'G33_I_1_1.4',
                                 'G33_1_2_1.1',
                                 'G33_1_2_1.4')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO,
                CASE
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                   'G33_I_1_1.1.T'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                   'G33_I_1_1.2.T'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                   'G33_I_1_1.4.T'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                   'G33_1_2_1.1.T'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                   'G33_1_2_1.4.T'
                END;
     COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：金融市场部指标数据插至G3301_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);




    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：附注1：资产合计（银行账簿）数据至A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
--附注：银行账簿整体情况
--附注1：资产合计（银行账簿） G01资产总计-交易账户的账面余额-应收利息-应计利息（存单的和债券的交易账户）
INSERT 
INTO PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT 
   I_DATADATE AS DATA_DATE,
   '009804' AS ORG_NUM,
   'G33_I_X_1..A.2019' AS  ITEM_NUM,
   SUM(ACCT_BAL_RMB) AS ITEM_VAL
    FROM (SELECT 
           A.GL_ITEM_CODE, --机构号
           SUM(A.PRINCIPAL_BALANCE * CCY_RATE) AS ACCT_BAL_RMB
            FROM PM_RSDATA.CBRC_V_PUB_FUND_INVEST A
            LEFT JOIN PM_RSDATA.SMTMODS_L_AGRE_BOND_INFO B --债券信息表
              ON A.SUBJECT_CD = B.STOCK_CD
             AND B.DATA_DATE = I_DATADATE
            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
              ON U.CCY_DATE = I_DATADATE
             AND U.BASIC_CCY = A.CURR_CD --基准币种
             AND U.FORWARD_CCY = 'CNY' --折算币种
           WHERE A.DATA_DATE = I_DATADATE
             AND A.INVEST_TYP = '00' --债券
             AND A.CURR_CD = 'CNY'
             AND A.BOOK_TYPE = '1'
           GROUP BY A.GL_ITEM_CODE
          UNION ALL
          SELECT YSLX, SUM(ACCRUAL) ACCRUAL
            FROM (SELECT A.GL_ITEM_CODE,
                         --T.GL_CD_NAME,
                         CASE
                           WHEN A.GL_ITEM_CODE IN
                                ('11010101',
                                 '11010102',
                                 '11010103',
                                 '11010104') THEN
                            '11320501'
                           WHEN A.GL_ITEM_CODE IN
                                ('15010101',
                                 '15010102',
                                 '15010103',
                                 '15010104') THEN
                            '11320701'
                           WHEN A.GL_ITEM_CODE IN
                                ('15030101',
                                 '15030102',
                                 '15030103',
                                 '15030104') THEN
                            '11320801'
                         END YSLX, --应收利息
                         SUM(ACCRUAL * C.CCY_RATE) as ACCRUAL
                    FROM PM_RSDATA.CBRC_V_PUB_FUND_INVEST A
                    LEFT JOIN PM_RSDATA.SMTMODS_L_AGRE_BOND_INFO B --债券信息表
                      ON A.SUBJECT_CD = B.STOCK_CD
                     AND B.DATA_DATE = I_DATADATE
                   /* LEFT JOIN L_FINA_INNER T
                      ON T.STAT_SUB_NUM = A.GL_ITEM_CODE
                     AND T.DATA_DATE = I_DATADATE
                     AND T.ORG_NUM = '990000'*/
                    LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE C
                      ON A.DATA_DATE = C.DATA_DATE
                     AND A.CURR_CD = C.BASIC_CCY
                     AND C.FORWARD_CCY = 'CNY'
                   WHERE A.INVEST_TYP = '00'
                     AND A.DATA_DATE = I_DATADATE
                     AND A.CURR_CD = 'CNY'
                     AND BOOK_TYPE = '1'
                   GROUP BY A.GL_ITEM_CODE,
                           -- T.GL_CD_NAME,
                            CASE
                              WHEN A.GL_ITEM_CODE IN
                                   ('11010101',
                                    '11010102',
                                    '11010103',
                                    '11010104') THEN
                               '11320501'
                              WHEN A.GL_ITEM_CODE IN
                                   ('15010101',
                                    '15010102',
                                    '15010103',
                                    '15010104') THEN
                               '11320701'
                              WHEN A.GL_ITEM_CODE IN
                                   ('15030101',
                                    '15030102',
                                    '15030103',
                                    '15030104') THEN
                               '11320801'
                            END)
           GROUP BY YSLX
          union all
          SELECT 
           A.GL_ITEM_CODE, --机构号
           SUM(A.PRINCIPAL_BALANCE * U.CCY_RATE) AS ACCT_BAL_RMB
            FROM PM_RSDATA.SMTMODS_V_PUB_FUND_CDS_BAL A --存单投资与发行信息表
            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
              ON U.CCY_DATE = I_DATADATE
             AND U.BASIC_CCY = A.CURR_CD --基准币种
             AND U.FORWARD_CCY = 'CNY' --折算币种
           WHERE A.DATA_DATE = I_DATADATE
             AND STOCK_PRO_TYPE = 'A' --同业存单
             AND PRODUCT_PROP = 'A' --持有
             AND A.FACE_VAL <> 0
             AND A.ORG_NUM = '009804'
             AND A.CURR_CD = 'CNY'
             AND BOOK_TYPE = '1'
           GROUP BY A.GL_ITEM_CODE
          UNION ALL
          SELECT YSLX, SUM(INTEREST_RECEIVABLE) INTEREST_RECEIVABLE
            FROM (SELECT A.GL_ITEM_CODE,
                        -- T.GL_CD_NAME,
                         CASE
                           WHEN A.GL_ITEM_CODE = '11010105' THEN
                            '11320501'
                           WHEN A.GL_ITEM_CODE = '15010105' THEN
                            '11320701'
                           WHEN A.GL_ITEM_CODE = '15030105' THEN
                            '11320801'
                         END YSLX,
                         SUM(INTEREST_RECEIVABLE * B.CCY_RATE) as INTEREST_RECEIVABLE
                    FROM PM_RSDATA.SMTMODS_V_PUB_FUND_CDS_BAL A
                  /*  LEFT JOIN L_FINA_INNER T
                      ON T.STAT_SUB_NUM = A.GL_ITEM_CODE
                     AND T.DATA_DATE = I_DATADATE
                     AND T.ORG_NUM = '990000'*/
                    LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                      ON A.DATA_DATE = B.DATA_DATE
                     AND A.CURR_CD = B.BASIC_CCY
                     AND B.FORWARD_CCY = 'CNY'
                   WHERE A.DATA_DATE = I_DATADATE
                     AND STOCK_PRO_TYPE = 'A' --同业存单
                     AND PRODUCT_PROP = 'A' --持有
                     AND A.FACE_VAL <> 0
                     AND A.ORG_NUM = '009804'
                     AND A.CURR_CD = 'CNY'
                     AND BOOK_TYPE = '1'
                   GROUP BY A.GL_ITEM_CODE,
                          --  T.GL_CD_NAME,
                            CASE
                              WHEN A.GL_ITEM_CODE = '11010105' THEN
                               '11320501'
                              WHEN A.GL_ITEM_CODE = '15010105' THEN
                               '11320701'
                              WHEN A.GL_ITEM_CODE = '15030105' THEN
                               '11320801'
                            END)
           GROUP BY YSLX) B;
     COMMIT;
--附注2：负债合计（银行账簿）  G01的负债合计, 前台初始化


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：附注1：资产合计（银行账簿）据插至A_REPT_ITEM_VAL中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 -------------------------------------------------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '6.无风险收益率曲线取数';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
    SELECT I_DATADATE AS DATA_DATE,
           '009804' AS ORG_NUM,
           'CBRC' AS SYS_NAM,
           'G33' AS REP_NUM,
           CASE
             WHEN T.ID = 1 THEN 'G33_I_1_6.B'
             WHEN T.ID = 2 THEN 'G33_I_1_6.C'
             WHEN T.ID = 3 THEN 'G33_I_1_6.D'
             WHEN T.ID = 4 THEN 'G33_I_1_6.E'
             WHEN T.ID = 5 THEN 'G33_I_1_6.F'
             WHEN T.ID = 6 THEN 'G33_I_1_6.G'
             WHEN T.ID = 7 THEN 'G33_I_1_6.H'
             WHEN T.ID = 8 THEN 'G33_I_1_6.I'
             WHEN T.ID = 9 THEN 'G33_I_1_6.J'
             WHEN T.ID = 10 THEN 'G33_I_1_6.K'
             WHEN T.ID = 11 THEN 'G33_I_1_6.L'
             WHEN T.ID = 12 THEN 'G33_I_1_6.M'
             WHEN T.ID = 13 THEN 'G33_I_1_6.N'
             WHEN T.ID = 14 THEN 'G33_I_1_6.O'
             WHEN T.ID = 15 THEN 'G33_I_1_6.P'
             WHEN T.ID = 16 THEN 'G33_I_1_6.Q'
             WHEN T.ID = 17 THEN 'G33_I_1_6.R'
             WHEN T.ID = 18 THEN 'G33_I_1_6.S'
             WHEN T.ID = 19 THEN 'G33_I_1_6.T'
           END AS ITEM_NUM,
           --前台该指标配置为：百分比，四位小数
           CASE
             WHEN T.ID = 1 THEN T1.YLD/100
             WHEN T.ID = 2 THEN ((T.KID-T2.YL)*(T1.YLD-T2.YLD)/(T1.YL-T2.YL)+T2.YLD)/100
             WHEN T.ID = 3 THEN ((T.KID-T2.YL)*(T1.YLD-T2.YLD)/(T1.YL-T2.YL)+T2.YLD)/100
             WHEN T.ID = 4 THEN ((T.KID-T2.YL)*(T1.YLD-T2.YLD)/(T1.YL-T2.YL)+T2.YLD)/100
             WHEN T.ID = 5 THEN ((T.KID-T2.YL)*(T1.YLD-T2.YLD)/(T1.YL-T2.YL)+T2.YLD)/100
             WHEN T.ID = 6 THEN ((T.KID-T2.YL)*(T1.YLD-T2.YLD)/(T1.YL-T2.YL)+T2.YLD)/100
             WHEN T.ID = 7 THEN ((T.KID-T2.YL)*(T1.YLD-T2.YLD)/(T1.YL-T2.YL)+T2.YLD)/100
             WHEN T.ID = 8 THEN ((T.KID-T3.YL)*(T2.YLD-T3.YLD)/(T2.YL-T3.YL)+T3.YLD)/100
             WHEN T.ID = 9 THEN ((T.KID-T3.YL)*(T2.YLD-T3.YLD)/(T2.YL-T3.YL)+T3.YLD)/100
             WHEN T.ID = 10 THEN ((T.KID-T3.YL)*(T2.YLD-T3.YLD)/(T2.YL-T3.YL)+T3.YLD)/100
             WHEN T.ID = 11 THEN ((T.KID-T3.YL)*(T2.YLD-T3.YLD)/(T2.YL-T3.YL)+T3.YLD)/100
             WHEN T.ID = 12 THEN ((T.KID-T3.YL)*(T2.YLD-T3.YLD)/(T2.YL-T3.YL)+T3.YLD)/100
             WHEN T.ID = 13 THEN ((T.KID-T3.YL)*(T2.YLD-T3.YLD)/(T2.YL-T3.YL)+T3.YLD)/100
             WHEN T.ID = 14 THEN ((T.KID-T3.YL)*(T2.YLD-T3.YLD)/(T2.YL-T3.YL)+T3.YLD)/100
             WHEN T.ID = 15 THEN ((T.KID-T3.YL)*(T2.YLD-T3.YLD)/(T2.YL-T3.YL)+T3.YLD)/100
             WHEN T.ID = 16 THEN ((T.KID-T3.YL)*(T2.YLD-T3.YLD)/(T2.YL-T3.YL)+T3.YLD)/100
             WHEN T.ID = 17 THEN ((T.KID-T3.YL)*(T2.YLD-T3.YLD)/(T2.YL-T3.YL)+T3.YLD)/100
             WHEN T.ID = 18 THEN ((T.KID-T3.YL)*(T2.YLD-T3.YLD)/(T2.YL-T3.YL)+T3.YLD)/100
             WHEN T.ID = 19 THEN ((T.KID-T3.YL)*(T2.YLD-T3.YLD)/(T2.YL-T3.YL)+T3.YLD)/100
             ELSE 0
           END AS ITEM_VAL,
            '2' AS FLAG,
            'CNY' AS B_CURR_CD
      FROM PM_RSDATA.CBRC_K_G3301 T
      LEFT JOIN PM_RSDATA.CBRC_JTDP_INTERF_PAYHSRCCASHYIELD_G3301 T1
        ON T.ID = T1.ID
      LEFT JOIN PM_RSDATA.CBRC_JTDP_INTERF_PAYHSRCCASHYIELD_G3301 T2
        ON T.ID-1 = T2.ID
      LEFT JOIN PM_RSDATA.CBRC_JTDP_INTERF_PAYHSRCCASHYIELD_G3301 T3
        ON T.ID-2 = T3.ID
     ORDER BY T.ID;
    COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '6.无风险收益率曲线取数完成';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 ------------------------------------------------------------add by djh  20230911 金融市场部指标 ------------------------------------------------------------
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生存款贷款指标数据至A_REPT_ITEM_VAL结果表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

     -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    ----------------------结果表
         INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
           (DATA_DATE, --数据日期
            ORG_NUM, --机构号
            DATA_DEPARTMENT, --数据条线
            SYS_NAM, --模块简称
            REP_NUM, --报表编号
            ITEM_NUM, --指标号
            ITEM_VAL, --指标值
            FLAG, --标志位
            B_CURR_CD)
           SELECT I_DATADATE AS DATA_DATE,
                  ORG_NUM,
                  DATA_DEPARTMENT,
                  SYS_NAM,
                  REP_NUM,
                  ITEM_NUM,
                  SUM(ITEM_VAL) AS ITEM_VAL,
                  FLAG,
                  B_CURR_CD
             FROM (SELECT T.ORG_NUM,
                          '' AS DATA_DEPARTMENT,
                          'CBRC' AS SYS_NAM,
                          'G33' AS REP_NUM,
                          ITEM_NUM,
                          CASE
                            WHEN T.ITEM_NUM LIKE 'G33_1%' THEN
                             -1 * SUM(T.ITEM_VAL) --存款数据都处理成负值，在此做调整
                            ELSE
                             SUM(T.ITEM_VAL)
                          END AS ITEM_VAL,
                          '2' AS FLAG,
                          'CNY' AS B_CURR_CD
                     FROM PM_RSDATA.CBRC_G3301_DATA_COLLECT_TMP T
                    WHERE TRIM(T.DATA_DATE) = I_DATADATE
                      AND T.ITEM_NUM IS NOT NULL
                    GROUP BY T.ORG_NUM, ITEM_NUM
                   UNION ALL
                   SELECT 
                    CASE
                      WHEN (ORG_NUM LIKE '5%' OR ORG_NUM LIKE '6%') THEN
                       ORG_NUM
                      WHEN ORG_NUM LIKE '%98%' THEN
                       ORG_NUM
                      WHEN ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                       '060300'
                      ELSE
                       SUBSTR(ORG_NUM, 1, 4) || '00'
                    END AS ORG_NUM,
                    DATA_DEPARTMENT,
                    SYS_NAM,
                    REP_NUM,
                    ITEM_NUM,
                    SUM(TOTAL_VALUE) AS ITEM_VAL,
                    '2' AS FLAG,
                    'CNY' CURR_CD
                     FROM PM_RSDATA.CBRC_A_REPT_DWD_G3301
                    GROUP BY CASE
                               WHEN (ORG_NUM LIKE '5%' OR ORG_NUM LIKE '6%') THEN
                                ORG_NUM
                               WHEN ORG_NUM LIKE '%98%' THEN
                                ORG_NUM
                               WHEN ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                                '060300'
                               ELSE
                                SUBSTR(ORG_NUM, 1, 4) || '00'
                             END,
                             DATA_DEPARTMENT,
                             SYS_NAM,
                             REP_NUM,
                             ITEM_NUM)
            GROUP BY ORG_NUM,
                     DATA_DEPARTMENT,
                     SYS_NAM,
                     REP_NUM,
                     ITEM_NUM,
                     FLAG,
                     B_CURR_CD;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '产生存款贷款指标数据至A_REPT_ITEM_VAL结果表完成';
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
   
END ;
