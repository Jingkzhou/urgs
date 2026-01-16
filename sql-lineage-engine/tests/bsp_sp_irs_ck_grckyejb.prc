CREATE OR REPLACE PROCEDURE BSP_SP_IRS_CK_GRCKYEJB(IS_DATE    IN VARCHAR2,
                                                 OI_RETCODE OUT INTEGER,
                                                 OI_RETCODE2 OUT VARCHAR2) AS
  ------------------------------------------------------------------------------------------------------
  -- 程序名
  --    IRS_PER_DEPOSIT_BALANCE_INFO
  -- 用途:生成个人存款余额基本信息表
  -- 参数
  --    IS_DATE 输入变量，传入跑批日期
  --    OI_RETCODE 输出变量，用来标识存储过程执行过程中是否出现异常
  -- 版本
  --    高铭言 20210520
  -- 版权
  --     中软融鑫
  --需求编号：数据维护单 上线日期：2025-12-17，修改人：蒿蕊 提出人：黄俊铭 修改原因：个体工商户判断优先以NGI客户类型为准，非NGI客户则根据柜面存款人类别判断
  ------------------------------------------------------------------------------------------------------
  VI_ERRORCODE      NUMBER DEFAULT 0; --数值型  异常代码
  VS_TEXT           VARCHAR2(500) DEFAULT NULL; --字符型  过程描述
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --字符型  存储过程调用用户
  VS_PROCEDURE_NAME VARCHAR2(40) DEFAULT NULL; --字符型  存储过程名称
  VS_STEP           VARCHAR2(30); --存储过程执行步骤标志
  VS_15_DATE        VARCHAR2(30);
  --NUM               INTEGER;
  --NEXTDATE          VARCHAR2(8);
  --OLDDATE           VARCHAR2(8); --清除历史数据用  20161215 add
  --NUM_OLD           INTEGER; --清除历史数据用  20161215 add
BEGIN
  VS_TEXT := IS_DATE;
  VS_15_DATE:=TO_CHAR(TO_DATE(IS_DATE,'YYYYMMDD')-16,'YYYYMMDD');
  -- 记录日志使用
  SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
  VS_PROCEDURE_NAME := 'SP_IRS_CK_GRCKYEJB';
  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, VS_TEXT, IS_DATE);
  --NEXTDATE := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') + 1, 'YYYYMMDD');
  --OLDDATE  := TO_CHAR(ADD_MONTHS(TO_DATE(IS_DATE, 'YYYYMMDD'), -12) + 1,
  --                    'YYYYMMDD'); --月初第一天  20151215 add

  --------------------------------------------------------------------------------------------------------------

 /* \*判断是否需要清除历史数据*\

  --查看此表是否有12月以前分区，如果有，清除分区数据
  SELECT COUNT(1)
    INTO NUM_OLD
    FROM USER_TAB_PARTITIONS
   WHERE TABLE_NAME = 'IRS_PER_DEPOSIT_BALANCE_INFO'
     AND PARTITION_NAME = 'P' || OLDDATE;

  --清除当前分区表的数据
  IF (NUM = 1) THEN
    EXECUTE IMMEDIATE 'ALTER TABLE IRS_PER_DEPOSIT_BALANCE_INFO TRUNCATE PARTITION P' ||
                      OLDDATE;
  END IF;

  \*新增完成*\ --20161215

  --查看此表是否已经建立分区
  SELECT COUNT(1)
    INTO NUM
    FROM USER_TAB_PARTITIONS
   WHERE TABLE_NAME = 'IRS_PER_DEPOSIT_BALANCE_INFO'
     AND PARTITION_NAME = 'P' || NEXTDATE;

  --如果没有建立分区，则增加分区
  IF (NUM = 0) THEN
    EXECUTE IMMEDIATE 'ALTER TABLE IRS_PER_DEPOSIT_BALANCE_INFO ADD PARTITION P' ||
                      NEXTDATE || ' VALUES LESS THAN (' || NEXTDATE || ')';
  END IF;

  --清除当前分区表的数据
  EXECUTE IMMEDIATE 'ALTER TABLE IRS_PER_DEPOSIT_BALANCE_INFO TRUNCATE PARTITION P' ||
                    NEXTDATE;*/

  --EXECUTE IMMEDIATE 'ALTER INDEX PK_IRS_PER_DEPOSIT_BALANCE_INFO REBUILD';

  EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_CK_GRCKYEJB';
  --EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_CK_GRCKYEJB_TMP1';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_CK_GRCKYEJB_TMP2';

 /*INSERT INTO DATACORE_IE_CK_GRCKYEJB_TMP1
 SELECT DISTINCT CUST_ID
 FROM SMTMODS.L_CUST_P
 WHERE DATA_DATE =IS_DATE
 AND ORG_NUM NOT LIKE '0215%';
 COMMIT;
 INSERT INTO DATACORE_IE_CK_GRCKYEJB_TMP1
 SELECT DISTINCT CUST_ID
 FROM SMTMODS.L_CUST_C
 WHERE DATA_DATE =IS_DATE
 AND ORG_NUM NOT LIKE '0215%';
 COMMIT;*/

  INSERT INTO DATACORE_IE_CK_GRCKYEJB
SELECT /*+ USE_HASH(A,C) PARALLEL(8)*/
     TO_CHAR(TO_DATE(IS_DATE,'YYYYMMDD'),'YYYY-MM-DD')       --数据日期
    ,A.ACCT_NUM                    --存款账户编码
    ,A.DEPOSIT_NUM                 --存款序号
    ,A.ORG_NUM                     --内部机构号
    ,A.CUST_ID                     --客户号
    ,A.CURR_CD                     --币种
    ,A.ACCT_BALANCE                --存款余额
  FROM SMTMODS.L_ACCT_DEPOSIT A    --存款账户信息表
 LEFT JOIN SMTMODS.L_CUST_P C
   ON A.CUST_ID = C.CUST_ID
   AND A.DATA_DATE = C.DATA_DATE
 WHERE /*(A.GL_ITEM_CODE = '21101' OR A.GL_ITEM_CODE LIKE '217%' OR
           A.GL_ITEM_CODE = '21501' OR A.GL_ITEM_CODE = '21502' OR
           A.GL_ITEM_CODE = '21503' OR A.GL_ITEM_CODE = '21506' OR
           A.GL_ITEM_CODE = '21510' OR A.GL_ITEM_CODE = '21102' OR
           A.GL_ITEM_CODE = '25101' OR A.GL_ITEM_CODE LIKE '203%'                     --modify by gmy 20220520 增加保证金科目25101
           OR (A.GL_ITEM_CODE LIKE '201%' AND C.OPERATE_CUST_TYPE = 'A')
           )*/
           (A.GL_ITEM_CODE = '20110101'         --个人活期存款
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
           AND A.ACCT_BALANCE > 0
           AND A.CURR_CD IN ('CNY','USD','JPY','EUR','HKD')
 AND A.DATA_DATE = IS_DATE;


  COMMIT;

--余额大于0的在L_CUST_C中的个体工商户
   INSERT INTO DATACORE_IE_CK_GRCKYEJB
SELECT /*+ USE_HASH(A,C) PARALLEL(8)*/
     TO_CHAR(TO_DATE(IS_DATE,'YYYYMMDD'),'YYYY-MM-DD')       --数据日期
    ,A.ACCT_NUM                    --存款账户编码
    ,A.DEPOSIT_NUM                 --存款序号
    ,A.ORG_NUM                     --内部机构号
    ,A.CUST_ID                     --客户号
    ,A.CURR_CD                     --币种
    ,A.ACCT_BALANCE                --存款余额
  FROM SMTMODS.L_ACCT_DEPOSIT A    --存款账户信息表
 INNER JOIN SMTMODS.L_CUST_C C
   ON A.CUST_ID = C.CUST_ID
   AND A.DATA_DATE = C.DATA_DATE
   AND (C.IS_NGI_CUST ='1' AND NVL(C.CUST_TYP,'0') = '3' --个体工商户                    --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]若是NGI客户标识则以NIG客户类型判断
	    OR NVL(C.IS_NGI_CUST,'0')='0' AND NVL(C.DEPOSIT_CUSTTYPE,'0') IN ('13','14')     --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]非NGI客户通过存款人类型判断
       )
 WHERE (A.GL_ITEM_CODE LIKE '20110201%'
           OR A.GL_ITEM_CODE LIKE '20110209%' --单位活期保证金存款
		   OR A.GL_ITEM_CODE LIKE '20110202%' --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]新增个体工商户的单位一般定期存款
		   OR A.GL_ITEM_CODE LIKE '20110205%' --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]新增个体工商户的单位通知存款
           OR A.GL_ITEM_CODE LIKE '20110210%') --单位定期保证金存款   新增个体工商户的保证金存款
           AND A.ACCT_BALANCE > 0
           AND A.CURR_CD IN ('CNY','USD','JPY','EUR','HKD')
 AND A.DATA_DATE = IS_DATE;


  COMMIT;

    INSERT INTO DATACORE_IE_CK_GRCKYEJB_TMP2
SELECT /*+ USE_HASH(A,C) PARALLEL(8)*/
     TO_CHAR(TO_DATE(IS_DATE,'YYYYMMDD'),'YYYY-MM-DD')       --数据日期
    ,A.ACCT_NUM                    --存款账户编码
    ,A.DEPOSIT_NUM                 --存款序号
    ,A.ORG_NUM                     --内部机构号
    ,A.CUST_ID                     --客户号
    ,A.CURR_CD                     --币种
    ,A.ACCT_BALANCE                --存款余额
  FROM SMTMODS.L_ACCT_DEPOSIT A    --存款账户信息表
 LEFT JOIN SMTMODS.L_CUST_P C
   ON A.CUST_ID = C.CUST_ID
   AND A.DATA_DATE = C.DATA_DATE
 WHERE /*(A.GL_ITEM_CODE = '21101' OR A.GL_ITEM_CODE LIKE '217%' OR
           A.GL_ITEM_CODE = '21501' OR A.GL_ITEM_CODE = '21502' OR
           A.GL_ITEM_CODE = '21503' OR A.GL_ITEM_CODE = '21506' OR
           A.GL_ITEM_CODE = '21510' OR A.GL_ITEM_CODE = '21102' OR
           A.GL_ITEM_CODE = '25101' OR A.GL_ITEM_CODE LIKE '203%'                     --modify by gmy 20220520 增加保证金科目25101
           OR (A.GL_ITEM_CODE LIKE '201%' AND C.OPERATE_CUST_TYPE = 'A')
           )*/
           (A.GL_ITEM_CODE = '20110101'         --个人活期存款
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
           AND A.ACCT_BALANCE = 0
           AND A.CURR_CD IN ('CNY','USD','JPY','EUR','HKD')
   AND A.DATA_DATE = IS_DATE
   ;


  COMMIT;

--余额等于0的在L_CUST_C中的个体工商户
    INSERT INTO DATACORE_IE_CK_GRCKYEJB_TMP2
SELECT /*+ USE_HASH(A,C) PARALLEL(8)*/
     TO_CHAR(TO_DATE(IS_DATE,'YYYYMMDD'),'YYYY-MM-DD')       --数据日期
    ,A.ACCT_NUM                    --存款账户编码
    ,A.DEPOSIT_NUM                 --存款序号
    ,A.ORG_NUM                     --内部机构号
    ,A.CUST_ID                     --客户号
    ,A.CURR_CD                     --币种
    ,A.ACCT_BALANCE                --存款余额
  FROM SMTMODS.L_ACCT_DEPOSIT A    --存款账户信息表
 INNER JOIN SMTMODS.L_CUST_C C
   ON A.CUST_ID = C.CUST_ID
   AND A.DATA_DATE = C.DATA_DATE
   AND (C.IS_NGI_CUST ='1' AND NVL(C.CUST_TYP,'0') = '3' --个体工商户                    --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]若是NGI客户标识则以NIG客户类型判断
	    OR NVL(C.IS_NGI_CUST,'0')='0' AND NVL(C.DEPOSIT_CUSTTYPE,'0') IN ('13','14')     --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]非NGI客户通过存款人类型判断
       )
 WHERE (A.GL_ITEM_CODE LIKE '20110201%'
           OR A.GL_ITEM_CODE LIKE '20110209%' --单位活期保证金存款
		   OR A.GL_ITEM_CODE LIKE '20110202%' --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]新增个体工商户的单位一般定期存款
		   OR A.GL_ITEM_CODE LIKE '20110205%' --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]新增个体工商户的单位通知存款
           OR A.GL_ITEM_CODE LIKE '20110210%') --单位定期保证金存款   新增个体工商户的保证金存款
           AND A.ACCT_BALANCE = 0
           AND A.CURR_CD IN ('CNY','USD','JPY','EUR','HKD')
   AND A.DATA_DATE = IS_DATE
   ;


  COMMIT;
  INSERT INTO DATACORE_IE_CK_GRCKYEJB
    SELECT *
      FROM DATACORE_IE_CK_GRCKYEJB_TMP2 A
     WHERE EXISTS (SELECT 1
              FROM SMTMODS.L_TRAN_TX T --交易信息表
             WHERE T.CUST_ID = A.CUST_ID
               AND T.ACCOUNT_CODE = A.ACCT_NUM
               AND T.DATA_DATE = IS_DATE
                 and t.PAYMENT_PROPERTY is null--交易过滤掉支付使用数据
       and t.PAYMENT_ORDER is null  --交易过滤掉支付使用数据
               );

   COMMIT;

  --为了加快查询速度，重建索引
  --EXECUTE IMMEDIATE 'ALTER INDEX 索引名 REBUILD';

  /* alter table DATACORE_IE_CK_GRCKYEJB
  add constraint PK_IE_CK_GRCKYEJB primary key (DATA_DATE, ACCT_NUM, DEPOSIT_NUM)
  using index
  local;*/

  --VS_STEP := 'analyze';
  --修改信息收集方式 by yanlingbo at 20181031
  --EXECUTE IMMEDIATE 'analyze table DATACORE_IE_CK_GRCKYEJB compute statistics';
  /*DBMS_STATS.GATHER_TABLE_STATS(OWNNAME          => VS_OWNER,
                                TABNAME          => 'DATACORE_IE_CK_GRCKYEJB',
                                ESTIMATE_PERCENT => 0.0001,
                                PARTNAME         => 'P' || NEXTDATE \*,METHOD_OPT => V_METHOD_OPT*\,
                                CASCADE          => TRUE);*/


--清除目标表中分区数据
--SP_IRS_PARTITIONS(VS_15_DATE,'IE_CK_GRCKYE',OI_RETCODE);--删除15天前的分区数据
SP_IRS_PARTITIONS(IS_DATE,'IE_CK_GRCKYE',OI_RETCODE);

--向目标表中插入数据

INSERT INTO IE_CK_GRCKYE ( DATADATE --数据日期
, ACCDEPCODE --存款账户编码
, DEPAGRSEQNO --存款序号
, CORPID --内部机构号
, CUSTID --客户号
, MONEYSYMB --币种
, BALANCE --存款余额
, CJRQ --采集日期
, NBJGH --内部机构号
, BIZ_LINE_ID --业务条线
, IRS_CORP_ID --法人机构ID
)
  SELECT A.DATA_DATE --数据日期
        ,A.ACCT_NUM --存款账户编码
        ,A.DEPOSIT_NUM --存款序号
        ,A.ORG_NUM --内部机构号
        ,A.CUST_ID --客户号
        ,A.CURR_CD --币种
        ,A.ACCT_BALANCE --存款余额
        ,IS_DATE --采集日期
        ,A.ORG_NUM  --内部机构号
        ,'99'    --业务条线
        , CASE WHEN A.ORG_NUM LIKE '51%' THEN '510000'
          WHEN A.ORG_NUM LIKE '52%' THEN '520000'
          WHEN A.ORG_NUM LIKE '53%' THEN '530000'
          WHEN A.ORG_NUM LIKE '54%' THEN '540000'
          WHEN A.ORG_NUM LIKE '55%' THEN '550000'
          WHEN A.ORG_NUM LIKE '56%' THEN '560000'
          WHEN A.ORG_NUM LIKE '57%' THEN '570000'
          WHEN A.ORG_NUM LIKE '58%' THEN '580000'
          WHEN A.ORG_NUM LIKE '59%' THEN '590000'
          WHEN A.ORG_NUM LIKE '60%' THEN '600000'
           ELSE '990000' END  --法人机构ID
    FROM DATACORE_IE_CK_GRCKYEJB A
    /*WHERE A.ORG_NUM NOT LIKE '0215%'
    AND EXISTS(SELECT 1 FROM DATACORE_IE_CK_GRCKYEJB_TMP1 C WHERE A.CUST_ID = C.CUST_ID)*/
    WHERE A.ACCT_NUM NOT IN ('9020790501000013_1','9019800217000015_1');  ---ADD BY 20230818 特殊处理，内部户有奖储蓄和信用卡，基准利率为0.刨除;

    COMMIT;


/*SP_IRS_PARTITIONS(IS_DATE,'IE_CK_GRCKYE_ALL',OI_RETCODE);
INSERT INTO IE_CK_GRCKYE_ALL select \*+ PARALLEL(8)*\ * from IE_CK_GRCKYE t WHERE T.CJRQ=IS_DATE;
COMMIT;*/
  ----------------------------------------------------------------------------------------------------------------
  OI_RETCODE := 0; --设置异常状态为0 成功状态

  --返回中文描述
  OI_RETCODE2 := '成功!';

  -- 结束日志
  VS_STEP := 'END';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, VS_TEXT, IS_DATE);

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

