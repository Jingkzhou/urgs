CREATE OR REPLACE PROCEDURE BSP_SP_IRS_DK_TZYWYE(IS_DATE    IN VARCHAR2,
                                                OI_RETCODE OUT INTEGER,
                                               OI_RETCODE2 OUT VARCHAR2) AS
  ------------------------------------------------------------------------------------------------------
  -- 程序名
  --    SP_IRS_DK_TZYWYE
  -- 用途:生成透支业务余额信息表
  -- 参数
  --    IS_DATE 输入变量，传入跑批日期
  --    OI_RETCODE 输出变量，用来标识存储过程执行过程中是否出现异常
  -- 版本
  --    高铭言 20210722
  -- 版权
  --     中软融鑫
  ------------------------------------------------------------------------------------------------------
  VI_ERRORCODE      NUMBER DEFAULT 0; --数值型  异常代码
  VS_TEXT           VARCHAR2(500) DEFAULT NULL; --字符型  过程描述
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --字符型  存储过程调用用户
  VS_PROCEDURE_NAME VARCHAR2(40) DEFAULT NULL; --字符型  存储过程名称
  VS_STEP           VARCHAR2(30); --存储过程执行步骤标志
  --NUM               INTEGER;
  --NEXTDATE          VARCHAR2(8);
  --OLDDATE           VARCHAR2(8); --清除历史数据用  20161215 add
  --NUM_OLD           INTEGER; --清除历史数据用  20161215 add
BEGIN
  VS_TEXT := IS_DATE;
  -- 记录日志使用
  SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
  VS_PROCEDURE_NAME := 'SP_IRS_DK_TZYWYE';
  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, VS_TEXT, IS_DATE);
  --NEXTDATE := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') + 1, 'YYYYMMDD');
  --OLDDATE  := TO_CHAR(ADD_MONTHS(TO_DATE(IS_DATE, 'YYYYMMDD'), -12) + 1,
  --                    'YYYYMMDD'); --月初第一天  20151215 add
--IRS.IE_FTP_FTPDJB
  --------------------------------------------------------------------------------------------------------------


--清除目标表中分区数据

SP_IRS_PARTITIONS(IS_DATE,'IE_DK_TZYWYE',OI_RETCODE);

  INSERT INTO IE_DK_TZYWYE
  (DATADATE           --数据日期
  ,CUSTID             --客户号
  ,CORPID             --内部机构号
  ,ACCOUNT            --账号
  ,ODBUSITYPE         --透支业务类型
  ,MONEYSYMB          --币种
  ,BALANCE            --余额
  ,REALRATE           --实际利率
  ,RATETYPE           --利率类型
  ,PRICINGTYPE        --定价基准类型
  ,BASERATE           --基准利率
  ,FLOATFREQ          --利率浮动频率
  ,CREDITCARDFLG      --是否信用卡透支
  ,CJRQ               --采集日期
  ,NBJGH              --内部机构号
  ,BIZ_LINE_ID        --业务条线
  )
SELECT /*+parallel(16)*/
 DATADATE           --数据日期
  ,CUSTID             --客户号
  ,'019803'             --内部机构号
  ,ACCOUNT            --账号
  ,ODBUSITYPE         --透支业务类型
  ,MONEYSYMB          --币种
  ,BALANCE            --余额
  ,REALRATE           --实际利率
  ,RATETYPE           --利率类型
  ,PRICINGTYPE        --定价基准类型
  ,BASERATE           --基准利率
  ,FLOATFREQ          --利率浮动频率
  ,CREDITCARDFLG      --是否信用卡透支
,
 IS_DATE --采集日期
,
 '019803' --内部机构号
,
 '99' --业务条线
  FROM IE_DK_TZYWYE1 A
  ;


  COMMIT;

  --为了加快查询速度，重建索引
  --EXECUTE IMMEDIATE 'ALTER INDEX 索引名 REBUILD';

  /* alter table IE_CK_GRCKYEJB
  add constraint PK_IE_CK_GRCKYEJB primary key (DATA_DATE, ACCT_NUM, DEPOSIT_NUM)
  using index
  local;*/

  --VS_STEP := 'analyze';
  --修改信息收集方式 by yanlingbo at 20181031
  --EXECUTE IMMEDIATE 'analyze table IE_CK_GRCKYEJB compute statistics';
  /*DBMS_STATS.GATHER_TABLE_STATS(OWNNAME          => VS_OWNER,
                                TABNAME          => 'IE_CK_GRCKYEJB',
                                ESTIMATE_PERCENT => 0.0001,
                                PARTNAME         => 'P' || NEXTDATE \*,METHOD_OPT => V_METHOD_OPT*\,
                                CASCADE          => TRUE);*/

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

