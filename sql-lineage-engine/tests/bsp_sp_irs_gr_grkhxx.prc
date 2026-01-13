CREATE OR REPLACE PROCEDURE BSP_SP_IRS_GR_GRKHXX(IS_DATE    IN VARCHAR2,
                                             OI_RETCODE OUT INTEGER,
                                             OI_RETCODE2 OUT VARCHAR2) AS
  ------------------------------------------------------------------------------------------------------
  -- 程序名
  --    SP_IRS_GR_GRKHXX
  -- 用途:生成接口表 DATACORE_IE_GR_GRKHXX  个人客户客户基础信息
  -- 参数
  --    IS_DATE 输入变量，传入跑批日期
  --    OI_RETCODE 输出变量，用来标识存储过程执行过程中是否出现异常
  --    CAEATE BY USER AT 20210528
  --    MODIFY BY GMY 20211222 取授信额度时增加条件FACILITY_TYP='2'，取单一法人授信信息
  -- 需求编号：JLBA202504160004 上线日期：2025-06-27，修改人：蒿蕊，提出人：黄俊铭 修改原因：数据管理部苏桐提出统一调整授信规则，黄俊铭确认修改授信额度和已用额度规则，与源系统一致。
  -- 需求编号：JLBA202507300010 上线日期：2025-09-29，修改人：蒿蕊，提出人：从需求  修改原因：添加普惠贷（个人经营贷款）取T+2当天放款当天结清逻辑
  -- 需求编号：数据维护单       上线日期：2025-12-17，修改人：蒿蕊，提出人：黄俊铭  修改原因：个体工商户判断优先以NGI客户类型为准，非NGI客户则根据柜面存款人类别判断
  ------------------------------------------------------------------------------------------------------

  VI_ERRORCODE NUMBER DEFAULT 0; --数值型  异常代码
  VS_TEXT      VARCHAR2(500) DEFAULT NULL; --字符型  过程描述
  VS_LAST_TEXT      VARCHAR2(10) DEFAULT NULL; --字符型  过程描述
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --字符型  存储过程调用用户
  VS_PROCEDURE_NAME VARCHAR2(32) DEFAULT NULL; --字符型  存储过程名称
  VS_STEP           VARCHAR2(10); --存储过程执行步骤标志
  /*NUM               INTEGER;*/
  --NUM1              INTEGER;
BEGIN
  VS_TEXT := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD');
  VS_LAST_TEXT := to_char(to_date(IS_DATE, 'yyyymmdd' )-1, 'yyyy-mm-dd');
  -- 记录日志使用
  SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
  VS_PROCEDURE_NAME := 'SP_IRS_GR_GRKHXX';

  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
  -------------------------------------------------------------------------


 --清除临时表数据

  EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_GR_GRKHXX_TEMP1 ';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_GR_GRKHXX_TEMP2 ';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_GR_GRKHXX_TEMP3 ';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_GR_GRKHXX_TEMP4 ';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_GR_GRKHXX_TEMP5 ';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_GR_GRKHXX_TEMP6 ';
  --EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_GR_GRKHXX_TEMP7 ';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_GR_GRKHXX_TEMP8 ';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_GR_GRKHXX_TEMP9 ';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_GR_GRKHXX_TEMP10 ';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_GR_GRKHXX_TEMP11 ';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_GR_GRKHXX_TEMP12 ';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_GR_GRKHXX ';


/*--创建全机构临时表
create table L_PUBL_ORG_BRA_TMP as
SELECT B.ORG_NUM,
               B.ORG_NAM,
               B.REGION_CD
  FROM (SELECT A.ORG_NUM,
               A.ORG_NAM,
               A.REGION_CD,
               ROW_NUMBER() OVER(PARTITION BY A.ORG_NUM ORDER BY A.DATA_DATE DESC) RN
          FROM SMTMODS.L_PUBL_ORG_BRA A) B
 WHERE B.RN = '1';*/

--每日更新机构表中数据
MERGE INTO L_PUBL_ORG_BRA_TMP A
USING (SELECT B.ORG_NUM, B.ORG_NAM, B.REGION_CD
         FROM SMTMODS.L_PUBL_ORG_BRA B
        WHERE B.DATA_DATE = IS_DATE) B
ON (A.ORG_NUM = B.ORG_NUM)
WHEN MATCHED THEN
  UPDATE SET A.REGION_CD = B.REGION_CD
WHEN NOT MATCHED THEN
  INSERT
    (A.ORG_NUM, A.ORG_NAM, A.REGION_CD)
  VALUES
    (B.ORG_NUM, B.ORG_NAM, B.REGION_CD);

  --授信额度临时表
  /*INSERT INTO DATACORE_IE_GR_GRKHXX_TEMP7
   SELECT T.CUST_ID,          --客户号
           SUM(T.FACILITY_AMT * R.CCY_RATE) FACILITY_AMT,    --授信额度
           SUM(T.UNDRAW_FACILITY_AMT * R.CCY_RATE) UNDRAW_FACILITY_AMT --已用授信
   FROM SMTMODS.L_AGRE_CREDITLINE T      --授信额度表
   LEFT JOIN SMTMODS.L_PUBL_RATE R       --汇率表
        ON T.CURR_CD = R.BASIC_CCY  ---币种
        AND R.FORWARD_CCY = 'CNY'   --折算币种为人民币
        AND R.DATA_DATE = IS_DATE
  WHERE T.DATA_DATE = IS_DATE
        AND T.FACILITY_STS = 'Y'   ---额度是否有效
        AND T.FACILITY_TYP='2'    --MODIFY BY GMY 20211222
        GROUP BY T.CUST_ID;
  COMMIT;


  --如果授信额度小于余额，取放款额度
  INSERT INTO DATACORE_IE_GR_GRKHXX_TEMP1
  SELECT T1.CUST_ID,       --客户号
         CASE
           WHEN T1.LOAN_ACCT_BAL > NVL(T2.FACILITY_AMT, 0) THEN
            T1.DRAWDOWN_AMT
           ELSE
            T2.FACILITY_AMT
         END FACILITY_AMT,
         CASE
           WHEN T1.LOAN_ACCT_BAL > NVL(T2.UNDRAW_FACILITY_AMT, 0) THEN
            T1.DRAWDOWN_AMT
           ELSE
            T2.UNDRAW_FACILITY_AMT
         END UNDRAW_FACILITY_AMT   --已用授信
    FROM (SELECT A.CUST_ID,        --客户号
                 SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL, --贷款余额
                 SUM(DRAWDOWN_AMT) DRAWDOWN_AMT      --放款金额
            FROM SMTMODS.L_ACCT_LOAN A  --贷款借据信息表
           WHERE A.DATA_DATE = IS_DATE
             --AND SUBSTR(A.ITEM_CD, 1, 3) IN ('122', '132') --截取科目号前3位为122，和132
             AND SUBSTR(A.ITEM_CD, 1, 4) IN ('1303', '1305') --截取科目号前3位为122，和132
             AND A.LOAN_ACCT_BAL > 0                --贷款余额大于0
           GROUP BY A.CUST_ID) T1
    LEFT JOIN DATACORE_IE_GR_GRKHXX_TEMP7 T2
      ON T1.CUST_ID = T2.CUST_ID;                   --客户号关联
  COMMIT;*/

  --包含吉商数贷的授信，也都通过合同金额，放款金额和贷款余额判断授信额度和已使用授信额度 mdf 20230803

      INSERT INTO DATACORE_IE_GR_GRKHXX_TEMP1
        SELECT T.CUST_ID, --客户号
	       --[2025-06-27] [蒿蕊] [JLBA202504160004] [黄俊铭]注释原有逻辑，改从授信额度表取
               -- T.CONTRACT_AMT AS FACILITY_AMT, --授信额度
               -- NVL(T1.DRAWDOWN_AMT, 0) AS USED_FACILITY_AMT --已使用额度
               T1.FACILITY_AMT, --授信额度     
               T1.USED_FACILITY_AMT --已用授信
          FROM (SELECT T.CUST_ID, SUM(T.CONTRACT_AMT) CONTRACT_AMT
                  FROM SMTMODS.L_AGRE_LOAN_CONTRACT T --合同信息表
                 WHERE T.DATA_DATE = IS_DATE
                   AND T.ACCT_STS = '1'
                   AND T.CUST_ID IS NOT NULL
                 GROUP BY T.CUST_ID) T
	  --[2025-06-27] [蒿蕊] [JLBA202504160004] [黄俊铭]注释原有逻辑，改从授信额度表取 start
          /*LEFT JOIN (SELECT A.CUST_ID,
                            SUM(CASE
                                  WHEN A.CIRCLE_LOAN_FLG = 'N' THEN
                                   A.DRAWDOWN_AMT
                                  WHEN A.CIRCLE_LOAN_FLG = 'Y' THEN
                                   A.LOAN_ACCT_BAL
                                END) DRAWDOWN_AMT ---CIRCLE_LOAN_FLG-循环贷款标志
                       FROM SMTMODS.L_ACCT_LOAN A --贷款借据信息表
                      WHERE A.DATA_DATE = IS_DATE
                        AND SUBSTR(A.ITEM_CD, 1, 4) IN ('1303', '1305') --截取科目号前3位为122，和132
                        AND A.CANCEL_FLG = 'N' --去掉核销数据
                        AND A.LOAN_ACCT_BAL > 0 --贷款余额大于0
            AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
                      GROUP BY A.CUST_ID) T1
            ON T.CUST_ID = T1.CUST_ID;*/
		  LEFT JOIN  (
                      SELECT T.CUST_ID,          --客户号
                               SUM(T.FACILITY_AMT * R.CCY_RATE) FACILITY_AMT,    --授信额度
                               SUM(T.USED_FACILITY_AMT * R.CCY_RATE) USED_FACILITY_AMT --已用授信
                        FROM SMTMODS.L_AGRE_CREDITLINE T      --授信额度表
                        LEFT JOIN SMTMODS.L_PUBL_RATE R       --汇率表
                            ON T.CURR_CD = R.BASIC_CCY  ---币种
                            AND R.FORWARD_CCY = 'CNY'   --折算币种为人民币
                            AND R.DATA_DATE = IS_DATE
                        WHERE T.DATA_DATE = IS_DATE
                            AND T.FACILITY_STS = 'Y'   ---额度是否有效
                            AND T.FACILITY_TYP IN ('2','4','5')
                            GROUP BY T.CUST_ID ) T1
	  --[2025-06-27] [蒿蕊] [JLBA202504160004] [黄俊铭]注释原有逻辑，改从授信额度表取 end
          ON T.CUST_ID = T1.CUST_ID;     
	COMMIT;

  --历史移植及核销数据
  INSERT INTO DATACORE_IE_GR_GRKHXX_TEMP2
    SELECT T.CUST_ID,                               --客户号
           COUNT(1) BS,                             --记录数
           SUM(DRAWDOWN_AMT),                       --放款金额
           SUM(LOAN_ACCT_BAL)                       --贷款余额
      FROM SMTMODS.L_ACCT_LOAN T                      --贷款借据信息表
    WHERE T.DATA_DATE = IS_DATE
       AND T.CANCEL_FLG = 'Y' --核销贷款
       AND T.CUST_ID NOT IN(SELECT T1.CUST_ID FROM SMTMODS.L_ACCT_LOAN T1 WHERE T1.DATA_DATE = IS_DATE  --去掉既有核销贷款又有未核销贷款客户
                                    AND T1.cancel_flg = 'N'
                  AND T1.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
                  )
     GROUP BY T.CUST_ID;
  COMMIT;

  insert into DATACORE_IE_GR_GRKHXX_TEMP11
    SELECT a.cust_id
      from SMTMODS.L_ACCT_DEPOSIT a
     where a.data_date = is_date
       --and a.ACCT_CLDATE IS NULL
       and (a.acct_sts <> 'C' or a.acct_cldate = to_date(is_date,'yyyymmdd') )   --取存款当天销户以及未销户的客户
       and a.gl_item_code is not null;


  INSERT INTO DATACORE_IE_GR_GRKHXX_TEMP10
  SELECT * FROM DATACORE_IE_GR_GRKHXX_TEMP2 T
  WHERE NOT EXISTS (SELECT 1
              FROM DATACORE_IE_GR_GRKHXX_TEMP11 B       --剔除贷款核销或遗留产品但是存款未核销的客户
             WHERE T.CUST_ID = B.CUST_ID);
   COMMIT;

  --贷款合同，余额大于0的
  INSERT INTO DATACORE_IE_GR_GRKHXX_TEMP3
    SELECT T.CUST_ID,               --客户号
           sum(LOAN_ACCT_BAL)       --贷款余额
      FROM SMTMODS.L_ACCT_LOAN T      --贷款借据信息表
          WHERE T.DATA_DATE = IS_DATE
           AND (T.ITEM_CD LIKE '130301%' OR T.ITEM_CD LIKE '130303%' OR T.ITEM_CD = '13030201' or T.ACCT_TYP LIKE '09%' )--取科目号为12201开头或者12203开头或者1220201
     -- 20210913 L_ACCT_LOAN增加产品代码字段，不需要关联产品代码表
         GROUP BY T.CUST_ID
      --HAVING SUM(LOAN_ACCT_BAL) > 0    20241111  将结清客户进行提取
      ;  --贷款金额大于0
 COMMIT;

  --add by chm 20231012 增加当天放款当天结清的个人客户信息

  INSERT INTO DATACORE_IE_GR_GRKHXX_TEMP3
    SELECT T.CUST_ID, '0'
      FROM SMTMODS.L_ACCT_LOAN T
     WHERE T.DATA_DATE = IS_DATE
       AND (SUBSTR(T.ITEM_CD, 1, 4) IN ('1303', '1305') OR
           T.ACCT_TYP LIKE '09%')
       AND T.CANCEL_FLG = 'N'
     AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       AND ((T.LOAN_ACCT_BAL = '0' AND T.DRAWDOWN_AMT > 0 AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = IS_DATE) OR --当天放款当天结清
           (T.INTERNET_LOAN_FLG = 'Y' AND T.LOAN_ACCT_BAL = '0' AND
           T.DRAWDOWN_AMT > 0 AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') =
           TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1),
                     'YYYYMMDD'))
		   OR T.CP_ID = 'DK001000100041' AND  T.LOAN_ACCT_BAL = '0' AND T.DRAWDOWN_AMT > 0 AND TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1), 'YYYYMMDD')  --[2025-09-29] [蒿蕊][JLBA202507300010][从需求]普惠贷取T+2当天放款当天结清
		   ) --互联网协议贷款，当天放款当天结清
       AND NOT EXISTS (SELECT 1
              FROM DATACORE_IE_GR_GRKHXX_TEMP3 T2
             WHERE T2.CUST_ID = T.CUST_ID);

  COMMIT;
---委托贷款的

  INSERT INTO DATACORE_IE_GR_GRKHXX_TEMP5
    SELECT T.CUST_ID,               --客户号
           sum(LOAN_ACCT_BAL)       --贷款余额
      FROM SMTMODS.L_ACCT_LOAN T      --贷款借据信息表
     WHERE T.DATA_DATE = IS_DATE
       AND T.ITEM_CD LIKE '3020%' --委托贷款
       AND T.CANCEL_FLG = 'N'--不取核销数据
     AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
      /* AND T.COD_PROD <> '10301002'*/--个人公积金委托贷款
     GROUP BY T.CUST_ID
    --HAVING SUM(LOAN_ACCT_BAL) > 0   20241111  将结清客户进行提取
    ;  --贷款金额大于0
  COMMIT;

---存款
INSERT INTO DATACORE_IE_GR_GRKHXX_TEMP6
  SELECT /*+PARALLEL(8)*/  A.CUST_ID,              --客户号
     SUM(A.ACCT_BALANCE)         --存款余额
    FROM SMTMODS.L_ACCT_DEPOSIT A
   LEFT JOIN SMTMODS.L_CUST_P C
   ON A.CUST_ID = C.CUST_ID
   AND A.DATA_DATE = C.DATA_DATE

WHERE  (A.GL_ITEM_CODE = '20110101'         --个人活期存款
         OR A.GL_ITEM_CODE LIKE '20110111%'     --个人信用卡存款
         OR A.GL_ITEM_CODE = '20110103'         --个人整存整取定期储蓄存款
         OR A.GL_ITEM_CODE = '20110104'         --个人零存整取定期储蓄存款
         OR A.GL_ITEM_CODE = '20110105'         --个人存本取息定期储蓄存款
         OR A.GL_ITEM_CODE = '20110108'         --个人教育储蓄存款
         OR A.GL_ITEM_CODE = '20110109'         --个人其他定期储蓄存款
         OR A.GL_ITEM_CODE = '20110102'         --个人定活两便存款
         OR A.GL_ITEM_CODE = '20110114'         --个人活期保证金存款
         OR A.GL_ITEM_CODE = '20110115'         --个人定期保证金存款
         OR A.GL_ITEM_CODE LIKE '20110110%'     --个人通知存款
         OR (A.GL_ITEM_CODE LIKE '20110201%' AND C.OPERATE_CUST_TYPE = 'A'))    --单位活期存款
     AND A.DATA_DATE = IS_DATE
     GROUP BY A.CUST_ID;

   COMMIT;

INSERT INTO DATACORE_IE_GR_GRKHXX_TEMP6
  SELECT /*+PARALLEL(8)*/  A.CUST_ID,              --客户号
     SUM(A.ACCT_BALANCE)         --存款余额
    FROM SMTMODS.L_ACCT_DEPOSIT A
   INNER JOIN SMTMODS.L_CUST_C C
   ON A.CUST_ID = C.CUST_ID
   AND A.DATA_DATE = C.DATA_DATE
   AND (C.IS_NGI_CUST ='1' AND NVL(C.CUST_TYP,'0') = '3' --个体工商户                     --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]若是NGI客户标识则以NIG客户类型判断
	    OR NVL(C.IS_NGI_CUST,'0')='0' AND NVL(C.DEPOSIT_CUSTTYPE,'0') IN ('13','14')      --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]非NGI客户通过存款人类型判断
       )
WHERE (A.GL_ITEM_CODE LIKE '20110201%'
           OR A.GL_ITEM_CODE LIKE '20110209%' --单位活期保证金存款
		   OR A.GL_ITEM_CODE LIKE '20110202%' --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]新增个体工商户的单位一般定期存款
		   OR A.GL_ITEM_CODE LIKE '20110205%' --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]新增个体工商户的单位通知存款
           OR A.GL_ITEM_CODE LIKE '20110210%') --单位定期保证金存款   新增个体工商户的保证金存款
     AND A.DATA_DATE = IS_DATE
     GROUP BY A.CUST_ID;

COMMIT;


   ---委托贷款-委托人
  INSERT INTO  DATACORE_IE_GR_GRKHXX_TEMP8
    SELECT /*+PARALLEL(8)*/  A.TRUSTOR_ID,               --客户号
           sum(LOAN_ACCT_BAL)       --贷款余额
      FROM SMTMODS.L_ACCT_LOAN T      --贷款借据信息表
       LEFT JOIN SMTMODS.L_ACCT_LOAN_ENTRUST A --委托贷款补充信息表
          ON T.LOAN_NUM = A.LOAN_NUM
          AND A.DATA_DATE = IS_DATE
     WHERE T.DATA_DATE = IS_DATE
       AND T.ITEM_CD LIKE '3020%' --委托贷款
       AND T.CANCEL_FLG = 'N'--不取核销数据
        and A.TRUSTOR_ID is not null
  AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
      /* AND T.COD_PROD <> '10301002'*/--个人公积金委托贷款
     GROUP BY A.TRUSTOR_ID
    --HAVING SUM(LOAN_ACCT_BAL) > 0    20241111  将结清客户进行提取
    ;  --贷款金额大于0
  COMMIT;


  --票据
      INSERT INTO DATACORE_IE_GR_GRKHXX_TEMP9
      SELECT /*+PARALLEL(8)*/
            T.CUST_ID, --客户号
            COUNT(1),  --记录数
            TO_CHAR(MIN(DRAWDOWN_DT), 'YYYY-MM-DD') RQ --贷款合同生效日期
       FROM SMTMODS.L_ACCT_LOAN T
       WHERE T.DATA_DATE=IS_DATE
       and (ITEM_CD LIKE '130101%'       --以摊余成本计量的贴现
       OR ITEM_CD LIKE '130104%'       --以公允价值计量变动计入权益的贴现
       OR ITEM_CD LIKE '130102%'       --以摊余成本计量的转贴现
       OR ITEM_CD LIKE '130105%')       --以公允价值计量变动计入权益的转贴现
           --and t.kmbh not like '1220101%'
           /*and T.prod_no <>'76002'*/
      GROUP BY CUST_ID;

      COMMIT;


   ---有存款发生额的

  INSERT INTO DATACORE_IE_GR_GRKHXX_TEMP4 --有授信
  SELECT T2.CUST_ID,'1' FROM DATACORE_IE_GR_GRKHXX_TEMP1 T2 ;
  COMMIT;
  INSERT INTO DATACORE_IE_GR_GRKHXX_TEMP4 --贷款合同，余额大于0的
  SELECT T4.CUST_ID,'2' FROM DATACORE_IE_GR_GRKHXX_TEMP3 T4 WHERE NOT EXISTS (SELECT 1 FROM DATACORE_IE_GR_GRKHXX_TEMP1 T2 WHERE T2.CUST_ID= T4.CUST_ID);
  COMMIT;
  INSERT INTO DATACORE_IE_GR_GRKHXX_TEMP4 --委托贷款借款人
  SELECT T4.CUST_ID,'3' FROM DATACORE_IE_GR_GRKHXX_TEMP5 T4 WHERE NOT EXISTS (SELECT 1 FROM DATACORE_IE_GR_GRKHXX_TEMP4 T2 WHERE T2.CUST_ID= T4.CUST_ID);
  COMMIT;
  INSERT INTO DATACORE_IE_GR_GRKHXX_TEMP4--存款
  SELECT T4.CUST_ID,'4' FROM DATACORE_IE_GR_GRKHXX_TEMP6 T4 WHERE NOT EXISTS (SELECT 1 FROM DATACORE_IE_GR_GRKHXX_TEMP4 T2 WHERE T2.CUST_ID= T4.CUST_ID);
  COMMIT;
  INSERT INTO DATACORE_IE_GR_GRKHXX_TEMP4--委托贷款委托人
  SELECT T4.WTRCUSTID,'5' FROM DATACORE_IE_GR_GRKHXX_TEMP8 T4 WHERE NOT EXISTS (SELECT 1 FROM DATACORE_IE_GR_GRKHXX_TEMP4 T2 WHERE T2.CUST_ID= T4.WTRCUSTID);
  COMMIT;
  INSERT INTO DATACORE_IE_GR_GRKHXX_TEMP4--委托贷款委托人
  SELECT T4.CUST_ID,'5' FROM DATACORE_IE_GR_GRKHXX_TEMP9 T4 WHERE NOT EXISTS (SELECT 1 FROM DATACORE_IE_GR_GRKHXX_TEMP4 T2 WHERE T2.CUST_ID= T4.CUST_ID);
  COMMIT;

  INSERT INTO DATACORE_IE_GR_GRKHXX_TEMP4 --补充上日余额>0的
    SELECT T.CUST_ID, '6'
      FROM SMTMODS.L_ACCT_LOAN T
     INNER JOIN SMTMODS.L_CUST_P T1
        ON T.CUST_ID = T1.CUST_ID
       AND T1.DATA_DATE =
           TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') - 1, 'YYYYMMDD')
     WHERE T.DATA_DATE =
           TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') - 1, 'YYYYMMDD')
       AND T.LOAN_ACCT_BAL > 0
       AND NOT EXISTS (SELECT 1
              FROM DATACORE_IE_GR_GRKHXX_TEMP4 T2
             WHERE T2.CUST_ID = T.CUST_ID)
  GROUP BY T.CUST_ID;
  COMMIT;




  ---结果表,包含吉林银行+磐石数据 , 对私

  INSERT /*+ append*/ INTO DATACORE_IE_GR_GRKHXX nologging
     (DATA_DATE, --1 数据日期
      CUST_ID,--客户号
      NBJGH,-- 内部机构号
      REG_REGION_CODE,--常住地行政区划代码
      FACILITY_AMT,--授信额度
      USED_FACILITY_AMT,--已用额度
      CUST_TYPE,--客户细类
      FLAG,--农户标志
      --CUST_ID_NO, --4 客户证件代码
      CJRQ --23采集日期
      )
   SELECT  /*+ leading (t t5)parallel(8)*/
   DATA_DATE, -- 1数据日期
   CUST_ID,--2客户号
   ORG_NUM,--3内部机构号
   REGION_CD, --4地区代码
   FACILITY_AMT , --5授信额度
   USED_FACILITY_AMT, --6已用额度
   CUST_TYPE, --7个人客户身份标识
   FLAG,--8农户标志
   --CUST_ID_NO, --9客户证件代码
   CJRQ --10采集日期
   FROM
   (SELECT
   IS_DATE DATA_DATE, --1数据日期
   T.CUST_ID,--2客户号
   --T.ORG_NUM,--3内部机构号
   T.CORE_ORG_NUM ORG_NUM,--3内部机构号               --信贷机构号存在客户机构与业务机构不一致情况，取核心机构号
   CASE WHEN (T.REGION_CD IS NOT NULL OR T.ORG_AREA IS NOT NULL OR T.ID_TYPE IN ('122','15','16'))
     THEN NVL(T.REGION_CD,T.ORG_AREA)
       WHEN T.REGION_CD IS NULL AND T.ORG_AREA IS NULL
     THEN T3.REGION_CD
       ELSE '220100' END REGION_CD, --4地区代码 保证上述客户信息表对应的字段能取值 20240222
   T2.FACILITY_AMT FACILITY_AMT , --5授信额度
   --T2.FACILITY_AMT  - T2.UNDRAW_FACILITY_AMT USED_FACILITY_AMT, --6已用额度
	CASE WHEN T2.USED_FACILITY_AMT > T2.FACILITY_AMT THEN T2.FACILITY_AMT
	     ELSE T2.USED_FACILITY_AMT
    END AS USED_FACILITY_AMT,   --6已用额度  --[2025-06-27] [蒿蕊] [JLBA202504160004] [黄俊铭]因源数据存在已用额度大于授信额度的情况，与黄俊铭沟通后确认已用额度大于授信额度取授信额度
   CASE
             WHEN T.OPERATE_CUST_TYPE = 'A' THEN
              'A' --个体工商户
             WHEN T.OPERATE_CUST_TYPE = 'B' THEN
              'B' --小微企业主

             ELSE
              'Z' --其他
           END CUST_TYPE, --7客户细类

     T.CITY_VILLAGE_FLG FLAG, -- 8农户标志 202403
     --NVL(T.CUST_ID_NO_LEGAL,T.ID_NO) CUST_ID_NO, --8客户证件代码
     IS_DATE CJRQ --9采集日期
   FROM SMTMODS.L_CUST_P T                  --对私客户补充信息表
   INNER JOIN DATACORE_IE_GR_GRKHXX_TEMP4 T5
      ON T.CUST_ID = T5.CUST_ID           --客户号关联

   LEFT JOIN DATACORE_IE_GR_GRKHXX_TEMP1 T2
        ON T.CUST_ID = T2.CUST_ID         --客户号关联

   LEFT JOIN L_PUBL_ORG_BRA_TMP T3
        ON T.CORE_ORG_NUM = T3.ORG_NUM

   WHERE  T.DATA_DATE = IS_DATE
     AND NOT EXISTS (SELECT 1 FROM DATACORE_IE_GR_GRKHXX_TEMP10 TEMP3 WHERE T.CUST_ID = TEMP3.CUST_ID)--历史遗留客户、核销客户 不保留
   )    M;
  COMMIT;
   ----在对公客户信息表里的个人客户(个人客户在核心标记为其他（企业），手动调整到个人客户表中)
 INSERT INTO DATACORE_IE_GR_GRKHXX nologging
     (DATA_DATE,          --1 数据日期
      CUST_ID,            --2客户号
      NBJGH,              --3内部机构号
      REG_REGION_CODE,    --4常住地行政区划代码
      FACILITY_AMT,       --5授信额度
      USED_FACILITY_AMT,  --6已用额度
      CUST_TYPE,          --7客户细类
      FLAG,               --8农户标志
      CJRQ                --10日期
      )
   SELECT   /*+ leading (t t5)parallel(8)*/
   DATA_DATE,              -- 1数据日期
   CUST_ID,                --2客户号
   ORG_NUM,                  --3内部机构号
   REG_REGION_CODE,        --4地区代码
   FACILITY_AMT ,           --5授信额度
   USED_FACILITY_AMT,       --6已用额度
   CUST_TYPE,               --7客户细类
   FARMING_FLAG,       --8农户标志
   --CUST_ID_NO,              --9客户证件代码
   CJRQ                     --10日期
   FROM
  (SELECT
       IS_DATE DATA_DATE, -- 1数据日期
       T.CUST_ID,--2客户号
       T.CORE_ORG_NUM ORG_NUM,--3内部机构号               --信贷机构号存在客户机构与业务机构不一致情况，取核心机构号
       CASE WHEN T.REGION_CD LIKE '%0000' THEN SUBSTR(T.ID_NO,0,6)
            WHEN (T.REGION_CD IS NOT NULL OR T.ORG_AREA IS NOT NULL OR T.ID_TYPE IN ('122','15','16'))
               then get_area_code(NVL(T.REGION_CD,T.ORG_AREA))
            WHEN T.REGION_CD IS NULL AND T.ORG_AREA IS NULL
               THEN T3.REGION_CD
         ELSE '220100' END REG_REGION_CODE, --4常住地行政区划代码 保证上述客户信息表对应的字段能取值 20240222
       T2.FACILITY_AMT FACILITY_AMT, --5授信额度
       CASE WHEN T2.USED_FACILITY_AMT > T2.FACILITY_AMT THEN T2.FACILITY_AMT
	        ELSE T2.USED_FACILITY_AMT
       END AS USED_FACILITY_AMT,   --6已用额度  --[2025-06-27] [蒿蕊] [JLBA202504160004] [黄俊铭]因源数据存在已用额度大于授信额度的情况，与黄俊铭沟通后确认已用额度大于授信额度取授信额度  
       CASE WHEN T.IS_NGI_CUST ='1' AND T.CUST_TYP = '3' THEN 'A'                           --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]添加NGI客户标识IS_NGI_CUST
	        WHEN NVL(T.IS_NGI_CUST,'0')='0' AND T.DEPOSIT_CUSTTYPE IN ('13','14') THEN 'A'  --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]增加存款人类型判断个体工商户
          ELSE 'Z' END CUST_TYPE, --7客户细类
       T.FARMING_FLAG, --8农户标志 202403
            IS_DATE CJRQ --12采集日期
  FROM SMTMODS.L_CUST_C T
  INNER JOIN DATACORE_IE_GR_GRKHXX_TEMP4 T5
        ON T.CUST_ID = T5.CUST_ID     --客户号关联
  LEFT  JOIN DATACORE_IE_GR_GRKHXX_TEMP1 T2
        ON T.CUST_ID = T2.CUST_ID     --客户号关联
  LEFT  JOIN DATACORE_IE_DW_DGKHXX_MAPPING M2 ---未知
          ON T.CUST_ID = M2.COD_CUST_ID
  LEFT JOIN L_PUBL_ORG_BRA_TMP T3
        ON T.CORE_ORG_NUM = T3.ORG_NUM
  WHERE  T.DATA_DATE = IS_DATE
        AND (T.CUST_ID IN('8410028844','8410028856','8410028857','8410028859','8410029031','8410029515','8410031272',
                        '8410031486','8410031509','8500042583','8500044403','8500060972','8500062533','8500071419',
                        '8500071486','8500071842','8500078626','8500078995','8500081236','8915832313','8915242461',
                        '8912668640','8911953837','8915587103','8915998116','8916156576','6000497482','8000565579'
                        ,'2999999999')
						OR (T.IS_NGI_CUST ='1' AND NVL(T.CUST_TYP,'0') = '3'   --个体工商户                   --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]若是NGI客户标识则以NIG客户类型判断
	                        OR NVL(T.IS_NGI_CUST,'0')='0' AND NVL(T.DEPOSIT_CUSTTYPE,'0') IN ('13','14')      --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]非NGI客户通过存款人类型判断
                           )
						) 
  ) M
 ;
   COMMIT;

--虚拟客户
INSERT /*+ append*/ INTO DATACORE_IE_GR_GRKHXX nologging
     (DATA_DATE, --1 数据日期
      CUST_ID,--客户号
      REG_REGION_CODE,--常住地行政区划代码
      NBJGH,-- 内部机构号
      CJRQ --23采集日期
      )
   SELECT
   IS_DATE DATA_DATE, --1数据日期
   T.CUST_ID,--2客户号
   '220100',--常住地行政区划代码
   --T.ORG_NUM,--3内部机构号
   T.CORE_ORG_NUM ORG_NUM,--3内部机构号               --信贷机构号存在客户机构与业务机构不一致情况，取核心机构号
   IS_DATE CJRQ --9采集日期
   FROM SMTMODS.L_CUST_C T                  --对公客户补充信息表
   WHERE T.CUST_ID LIKE '299%'
   AND T.DATA_DATE = IS_DATE
   --AND NOT EXISTS(SELECT 1 FROM grkhxx299 B WHERE T.CORE_ORG_NUM = B.ORG_NUM)
   AND EXISTS (SELECT 1 FROM DATACORE_IE_GR_GRKHXX_TEMP4 C WHERE T.CUST_ID = C.CUST_ID);
  COMMIT;



   ---------------------处理证件号是000000000000000000的数据--------------------------------------
 /* MERGE INTO DATACORE_IE_GR_GRKHXX T
  USING(
      SELECT B.EXTERNAL_CUSTOMER_IC,A.CUST_ID
      FROM DATACORE_IE_GR_GRKHXX A
      INNER JOIN ODS.FCR_CI_CUSTMAST_ALL@super B
      ON A.CUST_ID = B.COD_CUST_ID
      WHERE A.DATA_DATE = IS_DATE AND A.CUST_ID_NO = '000000000000000000') T1
  ON (T.CUST_ID = T1.CUST_ID AND T.DATA_DATE = IS_DATE)
  WHEN MATCHED THEN
  UPDATE SET T.CUST_ID_NO = T1.EXTERNAL_CUSTOMER_IC;
  COMMIT;*/
   ---------------------处理信贷与核心不同的机构号，以核心为准-------------------------------------------------------
  UPDATE DATACORE_IE_GR_GRKHXX T SET T.NBJGH = '090906' WHERE T.DATA_DATE = IS_DATE AND T.NBJGH = '090907';
  COMMIT;
  UPDATE DATACORE_IE_GR_GRKHXX T SET T.NBJGH = '050301' WHERE T.DATA_DATE = IS_DATE AND T.NBJGH = '050101';
  COMMIT;


        SP_IRS_PARTITIONS(IS_DATE,'IE_KH_GRKHXX',OI_RETCODE);

INSERT  INTO IE_KH_GRKHXX
     (DATADATE, --1数据日期
       CUSTID,--2客户号
       CORPID,--3内部机构号
       AREACODE,--4常住地行政区划代码
      CRDTLMT,--5授信额度
      USEDLMT,--6已用额度
      CUSTTYPE,--7客户细类
      FARMID,--8农户标志
      CJRQ, --10采集日期
      NBJGH,--内部机构号

      BIZ_LINE_ID,--业务条线
      VERIFY_STATUS,--校验状态
      BSCJRQ,        --报送周期
      IRS_CORP_ID      --21法人机构ID

     )
    select /*+PARALLEL(8)*/
    VS_TEXT DATA_DATE  , --1数据日期
    M.CUST_ID,           --2客户号
    M.NBJGH  ,            --3内部机构号
    CASE WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='00'
            THEN '220100'
        WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='01'
            THEN '220100'
        WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='02'
            THEN '220200'
        WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='03'
            THEN '220400'
        WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='04'
            THEN '220500'
        WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='05'
            THEN '220700'
        WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='06'
            THEN '222400'
        WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='07'
            THEN '220300'
        WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='08'
            THEN '220800'
        WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='09'
            THEN '220600'
         WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='10'
            THEN '210200'
        WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='11'
            THEN '210100'
        WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='13'
            THEN '220100'
        WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='51'
            THEN '220284'
        WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='52'
            THEN '225200'
        WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='53'
            THEN '220283'
        WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='54'
            THEN '220112'
        WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='55'
            THEN '130900'
        WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='56'
            THEN '131023'
        WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='57'
            THEN '222404'
        WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='58'
            THEN '220300'
        WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='59'
            THEN '220402'
        WHEN b.param_code IS  null and m.DQDM IS not null AND SUBSTR(M.NBJGH,1,2)='60'
            THEN '220281'
       ELSE M.DQDM END, --4常住地行政区划代码
    M.FACILITY_AMT    , --5授信额度
    M.USED_FACILITY_AMT, --6已用额度
    M.CUST_TYPE, --7客户细类
    M.FLAG          ,--8农户标志
    IS_DATE                ,--9采集日期
    M.nbjgh2,          --10内部机构号
    '99',                           --12业务条线
     '',                                 --13校验状态
     '',                                  --14报送周期
     CASE WHEN  M.NBJGH LIKE '51%' THEN '510000'
          WHEN  M.NBJGH LIKE '52%' THEN '520000'
          WHEN  M.NBJGH LIKE '53%' THEN '530000'
          WHEN  M.NBJGH LIKE '54%' THEN '540000'
          WHEN  M.NBJGH LIKE '55%' THEN '550000'
          WHEN  M.NBJGH LIKE '56%' THEN '560000'
          WHEN  M.NBJGH LIKE '57%' THEN '570000'
          WHEN  M.NBJGH LIKE '58%' THEN '580000'
          WHEN  M.NBJGH LIKE '59%' THEN '590000'
          WHEN  M.NBJGH LIKE '60%' THEN '600000'
           ELSE '990000' END  --21法人机构ID
     from
    (SELECT
     VS_TEXT DATA_DATE  , --1数据日期
     T.CUST_ID,           --2客户号
     case when c.nbjgh IS not null
          then c.new_nbjgh
          else t.nbjgh
          end NBJGH,            --3内部机构号
     --T.NBJGH,             --3内部机构号
     CASE

          WHEN TRIM(MN.XZQHDM) IS NOT NULL AND TRIM(MN.NEW_XZQUHM) IS NOT NULL
          THEN TRIM(MN.NEW_XZQUHM)
          ELSE TRIM(T.REG_REGION_CODE)
          END dqdm,--4地区代码
     --trim (NVL(BK.REG_REGION_CODE,T.REG_REGION_CODE))  , --4地区代码
     NVL(T.FACILITY_AMT,BK.CRDTLMT)  FACILITY_AMT    , --5授信额度
     NVL(T.USED_FACILITY_AMT,BK.USEDLMT) USED_FACILITY_AMT, --6已用额度
     NVL(T.CUST_TYPE,BK.CUSTTYPE) CUST_TYPE, --7客户细类
     T.FLAG          ,--8农户标志
     T.CJRQ ,                          --10采集日期
     case when c.nbjgh IS not null
          then c.new_nbjgh
          else t.nbjgh
          end  nbjgh2          --3内部机构号
     --T.NBJGH,                          --11内部机构号


     FROM DATACORE_IE_GR_GRKHXX T
        LEFT JOIN
        (select  cust_id,max(loan_num) as loan_num   from SMTMODS.L_ACCT_LOAN where data_Date = IS_DATE
        group by cust_id) T1
        ON T.CUST_ID=T1.CUST_ID
        LEFT JOIN (SELECT  loan_num , agrei_p_flg from SMTMODS.L_ACCT_LOAN_FARMING where data_date= IS_DATE
        ) T2
        ON T1.loan_num = T2.loan_num


        LEFT JOIN IE_KH_GRKHXX BK--取上期数据
        ON T.CUST_ID = BK.CUSTID --客户号关联
        AND BK.CJRQ = VS_LAST_TEXT


        LEFT JOIN DATACORE_XZQHDM MN
        ON T.REG_REGION_CODE=MN.XZQHDM

        LEFT JOIN DATACORE_NBJGH C
       ON t.NBJGH=C.NBJGH

      WHERE  T.DATA_DATE = IS_DATE

       )M

       left join M_EAST_META_FIELD_SCOPE b
       on M.DQDM=b.param_code
       and b.data_meta_code='C_REGION_CODE_CUST'
       and b.is_valid ='1'

       ;

   COMMIT;

----核心数据问题，暂时对数据进行处理
--贷款
insert into ie_kh_GRkhxx(datadate,custid,corpid,areacode,crdtlmt,usedlmt,custtype,farmid,cjrq,nbjgh,biz_line_id,verify_status,bscjrq,irs_corp_id)
select datadate,custid,'020701',areacode,crdtlmt,usedlmt,custtype,farmid,cjrq,'020701',biz_line_id,verify_status,bscjrq,'990000' from ie_kh_GRkhxx a where a.cjrq = IS_DATE and a.custid = '8915680383' ;
insert into ie_kh_GRkhxx(datadate,custid,corpid,areacode,crdtlmt,usedlmt,custtype,farmid,cjrq,nbjgh,biz_line_id,verify_status,bscjrq,irs_corp_id)
select datadate,custid,'020701',areacode,crdtlmt,usedlmt,custtype,farmid,cjrq,'020701',biz_line_id,verify_status,bscjrq,'990000' from ie_kh_GRkhxx a where a.cjrq = IS_DATE and a.custid = '8916238849' ;
insert into ie_kh_GRkhxx(datadate,custid,corpid,areacode,crdtlmt,usedlmt,custtype,farmid,cjrq,nbjgh,biz_line_id,verify_status,bscjrq,irs_corp_id)
select datadate,custid,'020701',areacode,crdtlmt,usedlmt,custtype,farmid,cjrq,'020701',biz_line_id,verify_status,bscjrq,'990000' from ie_kh_GRkhxx a where a.cjrq = IS_DATE and a.custid = '8917041640' ;

commit;
--存款
insert into ie_kh_GRkhxx(datadate,custid,corpid,areacode,crdtlmt,usedlmt,custtype,farmid,cjrq,nbjgh,biz_line_id,verify_status,bscjrq,irs_corp_id)
select datadate,custid,'510001',areacode,crdtlmt,usedlmt,custtype,farmid,cjrq,'510001',biz_line_id,verify_status,bscjrq,'510000' from ie_kh_GRkhxx a where a.cjrq = IS_DATE and a.custid = '2078555746' ;
insert into ie_kh_GRkhxx(datadate,custid,corpid,areacode,crdtlmt,usedlmt,custtype,farmid,cjrq,nbjgh,biz_line_id,verify_status,bscjrq,irs_corp_id)
select datadate,custid,'013101',areacode,crdtlmt,usedlmt,custtype,farmid,cjrq,'013101',biz_line_id,verify_status,bscjrq,'990000' from ie_kh_GRkhxx a where a.cjrq = IS_DATE and a.custid = '8912744056' ;
insert into ie_kh_GRkhxx(datadate,custid,corpid,areacode,crdtlmt,usedlmt,custtype,farmid,cjrq,nbjgh,biz_line_id,verify_status,bscjrq,irs_corp_id)
select datadate,custid,'021409',areacode,crdtlmt,usedlmt,custtype,farmid,cjrq,'021409',biz_line_id,verify_status,bscjrq,'990000' from ie_kh_GRkhxx a where a.cjrq = IS_DATE and a.custid = '8919744240' ;
insert into ie_kh_GRkhxx(datadate,custid,corpid,areacode,crdtlmt,usedlmt,custtype,farmid,cjrq,nbjgh,biz_line_id,verify_status,bscjrq,irs_corp_id)
select datadate,custid,'510006',areacode,crdtlmt,usedlmt,custtype,farmid,cjrq,'510006',biz_line_id,verify_status,bscjrq,'510000' from ie_kh_GRkhxx a where a.cjrq = IS_DATE and a.custid = '8913679176' ;

commit;


    -------------------------------------------------------------------------
  OI_RETCODE := 0; --设置异常状态为0 成功状态

  --返回中文描述
  OI_RETCODE2 := '成功!';

  /*COMMIT; --非特殊处理只能在最后一次提交*/
  -- 结束日志
  VS_STEP := 'END';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
EXCEPTION
  WHEN OTHERS THEN
    --如果出现异常
    VI_ERRORCODE := SQLCODE; --设置异常代码
    VS_TEXT      := VS_STEP || '|' || IS_DATE || '|' ||
                    SUBSTR(SQLERRM, 1, 200); --设置异常描述
    ROLLBACK; --数据回滚
    OI_RETCODE := -1; --设置异常状态为-1

    --返回中文描述

    OI_RETCODE2 := SUBSTR(SQLERRM, 1, 200);

    --插入日志表，记录错误
        SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, VS_TEXT, IS_DATE);
END;
/

