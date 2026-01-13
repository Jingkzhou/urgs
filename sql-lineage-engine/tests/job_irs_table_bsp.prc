CREATE OR REPLACE PROCEDURE JOB_IRS_TABLE_BSP(IS_DATE IN VARCHAR2,
                                          OI_RETCODE OUT INTEGER,
                                          ERROR_DESC OUT VARCHAR2) IS
  ------------------------------------------------------------------------------------------------------
  -- 程序名
  -- JOB_IRS_TABLE   DATACORE.JOB_IRS_TABLE 的存储跑批
  -- 用途:总调表，调动存储跑批
  -- 参数
  -- IS_DATE 输入变量，传入跑批日期
  -- OI_RETCODE 输出变量，用来标识存储过程执行过程中是否出现异常
  -- 中软融鑫
  ------------------------------------------------------------------------------------------------------
  VI_ERRORCODE      NUMBER DEFAULT 0; --数值型  异常代码
  VS_TEXT           VARCHAR2(250) DEFAULT NULL; --字符型  过程描述
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --字符型  存储过程调用用户
  VS_PROCEDURE_NAME VARCHAR2(32) DEFAULT NULL; --字符型  存储过程名称
  VS_STEP           VARCHAR2(8); --存储过程执行步骤标志
  TABLE_STATUS      VARCHAR2(20); --判断上游表是否都完成
  ZONGFEN_STATUS    VARCHAR2(20); --判断总分校验是否完成
  --STATUS_FLAG1      VARCHAR2(20); --全部成功状态
  --STATUS_FLAG2      VARCHAR2(20); --全部失败状态
  --V_JOB_IRS_TABLE number default 0;

BEGIN
  VS_TEXT := IS_DATE;
  -- 记录日志使用
  SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
  VS_PROCEDURE_NAME := 'JOB_IRS_TABLE';
  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, VS_TEXT, IS_DATE);

  -------------------------------------------------------------------------
 /*--判断L层表是否都跑批完成
 --利率报备用到L层表的执行状态是否都是END
 LOOP
   SELECT COUNT(1)
     INTO TABLE_STATUS
     FROM SP_TABLE A
    WHERE NOT EXISTS (SELECT 1
             FROM SUPER.L_TABLE_FINSH B
            WHERE A.SP_NAME = B.TABLE_NAME
              AND B.FINSH_FLAG = 'Y'
              AND B.DATA_DATE = IS_DATE);

 --总分校验结果是否都为通过
    SELECT COUNT(1)
      INTO ZONGFEN_STATUS
      FROM SUPER.L_TABLE_FINSH A
     WHERE A.FINISH_GROUP = 'ACCOUNT_CHECK'
       AND A.FINSH_FLAG = 'N'
       AND A.DATA_DATE = IS_DATE;

\*  --提取所有开始状态的个数，防止存在重跑没跑完情况
   SELECT COUNT(1)
     INTO STATUS_FLAG1
     FROM L_TABLE_FINSH @SUPER A
    WHERE EXISTS(SELECT 1 FROM SP_TABLE B WHERE A.TABLE_NAME = B.SP_NAME)
      AND A.DATA_DATE = IS_DATE
      AND A.FINSH_FLAG = 'START';

  --提取所有结束状态的个数，防止存在重跑没跑完情况
   SELECT COUNT(1)
     INTO STATUS_FLAG2
     FROM L_TABLE_FINSH @SUPER A
    WHERE EXISTS(SELECT 1 FROM SP_TABLE B WHERE A.TABLE_NAME = B.SP_NAME)
      AND A.DATA_DATE = IS_DATE
      AND A.FINSH_FLAG = 'END';*\

  --当成功状态数等于
    --IF STATUS_FLAG1 = STATUS_FLAG2 AND TABLE_STATUS = '0' then
      IF TABLE_STATUS = '0' AND ZONGFEN_STATUS = '0' then
        SP_IRS_LOG(VS_OWNER, VS_PROCEDURE_NAME, '完成', VI_ERRORCODE, VS_TEXT);
         EXIT;

    ELSE
      SP_IRS_LOG(VS_OWNER, VS_PROCEDURE_NAME, 'wait', VI_ERRORCODE, VS_TEXT);

      DBMS_LOCK.SLEEP(600);

   END IF;

 END LOOP;*/


   --1金融机构分支信息
  SP_IRS_JG_JRJGFZXX(IS_DATE,OI_RETCODE);
  COMMIT;
  --2对公客户信息
  SP_IRS_DW_DGDWKHXX(IS_DATE,OI_RETCODE);
  COMMIT;
  --3个人客户信息
  SP_IRS_GR_GRKHXX(IS_DATE,OI_RETCODE);
  COMMIT;
  --4个人贷款基础信息
   SP_IRS_DK_GRDKJC(IS_DATE,OI_RETCODE);
  COMMIT;
  --5个人贷款余额信息
  SP_IRS_DK_GRDKYE(IS_DATE,OI_RETCODE);
  COMMIT;
  --6个人贷款放款信息
  SP_IRS_DK_GRDKFK(IS_DATE,OI_RETCODE);
  COMMIT;

  --7非同业单位贷款基础信息表
  SP_IRS_DK_FTYDWDKJC(IS_DATE,OI_RETCODE);
  COMMIT;
  --8非同业单位贷款余额信息表
  SP_IRS_DK_FTYDWDKYE(IS_DATE,OI_RETCODE);
  COMMIT;
  --9非同业单位贷款放款信息表
   SP_IRS_DK_FTYDWDKFK(IS_DATE,OI_RETCODE);
  COMMIT;
  --10委托贷款基础信息表
  SP_IRS_DK_WTDKJC(IS_DATE,OI_RETCODE);
  COMMIT;
  --11委托贷款余额信息表
  SP_IRS_DK_WTDKYE(IS_DATE,OI_RETCODE);
  COMMIT;
  --12委托贷款放款信息表
  SP_IRS_DK_WTDKFK(IS_DATE,OI_RETCODE);
  COMMIT;
  --13同业存款基础信息表
  SP_IRS_TY_TYCKJC(IS_DATE,OI_RETCODE);
  COMMIT;
  --14同业存款余额信息表
  SP_IRS_TY_TYCKYE(IS_DATE,OI_RETCODE);
  COMMIT;
  --15同业存款发生额信息表
  SP_IRS_TY_TYCKFS(IS_DATE,OI_RETCODE);
  COMMIT;
  --16同业借贷基础信息表
  SP_IRS_TY_TYJDJC(IS_DATE,OI_RETCODE);
  COMMIT;
  --17同业借贷余额信息表
   SP_IRS_TY_TYJDYE(IS_DATE,OI_RETCODE);
  COMMIT;
  --18同业借贷发生额信息表
  SP_IRS_TY_TYJDFS(IS_DATE,OI_RETCODE);
  COMMIT;
  --19个人存款基础信息表
  SP_IRS_CK_GRCKJB(IS_DATE,OI_RETCODE);
  COMMIT;
  --20个人存款余额信息表
   SP_IRS_CK_GRCKYEJB(IS_DATE,OI_RETCODE);
  COMMIT;
  --21个人存款发生额信息表
  SP_IRS_CK_GRCKFS(IS_DATE,OI_RETCODE);
  COMMIT;
  --22非同业单位存款基础信息表
  SP_IRS_CK_FTYDWCKJB(IS_DATE,OI_RETCODE);
  COMMIT;
  --23非同业单位存款余额信息表
  SP_IRS_CK_FTYDWCKYEJB(IS_DATE,OI_RETCODE);
  COMMIT;
  --24非同业单位存款发生额信息表
  SP_IRS_CK_DWCKFS(IS_DATE,OI_RETCODE);
  COMMIT;
  --25买入返售及卖出回购基础信息表
   SP_IRS_TY_MRFSJC(IS_DATE,OI_RETCODE);
  COMMIT;
  --26买入返售及卖出回购余额信息表
  SP_IRS_TY_MRFSYE(IS_DATE,OI_RETCODE);
  COMMIT;
  --27买入返售及卖出回购发生额信息表
  SP_IRS_TY_MRFSFS(IS_DATE,OI_RETCODE);
  COMMIT;
   --28票据贴现及转贴现基础信息表
   SP_IRS_PJ_PJTXJC(IS_DATE,OI_RETCODE);
  COMMIT;
  --29票据贴现及转贴现余额信息表
  SP_IRS_PJ_PJTXYE(IS_DATE,OI_RETCODE);
  COMMIT;
  --30票据贴现及转贴现发生额信息表
  SP_IRS_PJ_PJTXFS(IS_DATE,OI_RETCODE);
  COMMIT;
  --31FTP定价变动明细信息表
  SP_IRS_FTP_FTPDJB(IS_DATE,OI_RETCODE);
  COMMIT;
   --32金融机构法人信息表
  SP_IRS_JG_JRJGFRXX(IS_DATE,OI_RETCODE);
  COMMIT;
   --33透支业务余额信息表
  SP_IRS_DK_TZYWYE(IS_DATE,OI_RETCODE);
  COMMIT;
  --34透支业务交易流水信息表
  SP_IRS_DK_TZYWJY(IS_DATE,OI_RETCODE);
  COMMIT;
  --35人民币利差息差统计表
  SP_IRS_RATE_LCXCTJ(IS_DATE,OI_RETCODE);
  COMMIT;

  COMMIT;

  -------------------------------------------------------------------------------------
  OI_RETCODE := 0; --设置成功状态为0

  /*COMMIT; --非特殊处理只能在最后一次提交*/
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
    ERROR_DESC := VS_TEXT;
    --插入日志表，记录错误
    SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, VS_TEXT, IS_DATE);
END;
/

