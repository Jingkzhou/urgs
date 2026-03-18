CREATE OR REPLACE PROCEDURE BSP_SP_IRS_DW_DGDWKHXX(IS_DATE     IN VARCHAR2,
                                                   OI_RETCODE  OUT INTEGER,
                                                   OI_RETCODE2 OUT VARCHAR2) AS
  ------------------------------------------------------------------------------------------------------
  -- 程序名
  --    SP_IRS_DW_DGDWKHXX
  -- 用途:生成接口表 IE_KH_DGKHXX  对公客户信息
  -- 参数
  --    IS_DATE 输入变量，传入跑批日期
  --    OI_RETCODE 输出变量，用来标识存储过程执行过程中是否出现异常
  --    CAEATE BY USER AT 20210528
  --    MODIFY BY GMY 20211222 取授信额度时增加条件FACILITY_TYP='2'，取单一法人授信信息
  -- 需求编号：无需求 上线日期：2025-05-12，修改人：蒿蕊，提出人：黄俊铭 修改原因：1.国门经济部门类型是C01或C02且企业规模是CS05其他、2.源系统企业规模为空时从DATACORE_TMP_DGKH_QYGM取
  -- 需求编号：无需求 上线日期：2025-05-14，修改人：蒿蕊，提出人：丹姐   
  --           修改原因：所属行业要求报送细类，但L_CUST_C.CORP_BUSINSESS_TYPE行业类别因反洗钱需求改造不允许为空，所以存在行业大类，修改为如果行业是大类，默认为空
  -- 需求编号：JLBA202504180011 上线日期：2025-05-27，修改人：蒿蕊，提出人：黄俊铭 修改原因：D1092取2005；D1095取2010；D1011取2008和2009；
  -- 需求编号：JLBA202504160004 上线日期：2025-06-27，修改人：蒿蕊，提出人：黄俊铭 修改原因：数据管理部苏桐提出统一调整授信规则，黄俊铭确认修改授信额度和已用额度规则，与源系统一致。
  -- 需求编号：JLBA202507210012 上线日期：2025-12-11，修改人：蒿蕊，提出人：王  铣 修改原因：2011吸收存款列入一般存款统计
  -- 需求编号：数据维护单       上线日期：2025-12-17，修改人：蒿蕊  提出人：黄俊铭 修改原因：个体工商户判断优先以NGI客户类型为准，非NGI客户则根据柜面存款人类别判断
  ------------------------------------------------------------------------------------------------------

  VI_ERRORCODE      NUMBER DEFAULT 0; --数值型  异常代码
  VS_TEXT           VARCHAR2(500) DEFAULT NULL; --字符型  过程描述
  VS_last_TEXT      VARCHAR2(500) DEFAULT NULL; --字符型  过程描述
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --字符型  存储过程调用用户
  VS_PROCEDURE_NAME VARCHAR2(32) DEFAULT NULL; --字符型  存储过程名称
  VS_STEP           VARCHAR2(10); --存储过程执行步骤标志
  /*NUM               INTEGER;*/
  /*NUM1               INTEGER;*/
BEGIN
  VS_TEXT      := to_char(to_date(IS_DATE, 'yyyymmdd'), 'yyyy-mm-dd');
  VS_LAST_TEXT := to_char(to_date(IS_DATE, 'yyyymmdd') - 1, 'yyyy-mm-dd');
  -- 记录日志使用
SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
VS_PROCEDURE_NAME := 'SP_IRS_DW_DGDWKHXX';

-- 开始日志
VS_STEP := 'START';
SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
-------------------------------------------------------------------------

--清除临时表数据
EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_DW_DGDWKHXX_TEMP1 ';
EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_DW_DGDWKHXX_TEMP2 ';
EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_DW_DGDWKHXX_TEMP3 ';
EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_DW_DGDWKHXX_TEMP4 ';
EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_DW_DGDWKHXX_TEMP5 ';
EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_DW_DGDWKHXX_TEMP6 ';
EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_DW_DGDWKHXX_TEMP7 ';
EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_DW_DGDWKHXX_TEMP8 ';
EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_DW_DGDWKHXX_TEMP9 ';
EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_DW_DGDWKHXX_TEMP10 ';
EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_DW_DGDWKHXX_TEMP11 ';
EXECUTE IMMEDIATE 'TRUNCATE TABLE  DATACORE_IE_DW_DGDWKHXX ';
EXECUTE IMMEDIATE 'TRUNCATE TABLE  GMJJBM_BL ';

INSERT INTO DATACORE_IE_DW_DGDWKHXX_TEMP10
  SELECT B.CUST_ID
    FROM SMTMODS.L_ACCT_DEPOSIT B --剔除贷款核销但是存款未核销的客户
   WHERE B.DATA_DATE = IS_DATE
     AND B.ACCT_CLDATE IS NULL
     AND B.GL_ITEM_CODE IS NOT NULL;
COMMIT;

INSERT INTO DATACORE_IE_DW_DGDWKHXX_TEMP11
  SELECT C.CUST_ID
    FROM SMTMODS.L_ACCT_LOAN C
   WHERE C.DATA_DATE = IS_DATE
     AND C.cancel_flg = 'N'
   AND C.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
   ;
COMMIT;

--首次建立信贷关系日期，使用贷款借据最早放款日期判断
INSERT INTO DATACORE_IE_DW_DGDWKHXX_TEMP1
  SELECT T.CUST_ID, --客户号
         TO_CHAR(MIN(T.DRAWDOWN_DT), 'YYYY-MM-DD'), --放款日期
         sum(t.LOAN_ACCT_BAL), --贷款余额
         sum(DRAWDOWN_AMT) --放款金额
    FROM SMTMODS.L_ACCT_LOAN T ---贷款借据信息表
   WHERE T.DATA_DATE = IS_DATE
        --AND T.ITEM_CD NOT LIKE '406%'   --科目号不为406开头
     AND T.ITEM_CD NOT LIKE '3010%' --委托业务
     AND T.ITEM_CD NOT LIKE '3020%'
     AND T.ITEM_CD NOT LIKE '3030%'
     AND T.ITEM_CD NOT LIKE '3040%'
	 AND T.ACCT_STS <> '3'  --[2025-06-27] [蒿蕊] [JLBA202504160004] [黄俊铭]统计未结清的借据余额
   GROUP BY T.CUST_ID;

COMMIT;

--授信额度临时表
INSERT INTO DATACORE_IE_DW_DGDWKHXX_TEMP6
  SELECT T.CUST_ID, --客户号
         SUM(T.FACILITY_AMT * R.CCY_RATE) FACILITY_AMT, --授信额度
         --SUM(T.UNDRAW_FACILITY_AMT * R.CCY_RATE) UNDRAW_FACILITY_AMT --已用额度
         SUM(T.USED_FACILITY_AMT * R.CCY_RATE) UNDRAW_FACILITY_AMT --已用额度
    FROM SMTMODS.L_AGRE_CREDITLINE T --授信额度表
    LEFT JOIN SMTMODS.L_PUBL_RATE R --汇率表
      ON T.CURR_CD = R.BASIC_CCY --基准币种关联
     AND R.FORWARD_CCY = 'CNY' --折算币种为人民币
     AND R.DATA_DATE = IS_DATE
   WHERE T.DATA_DATE = IS_DATE
        --AND T.FACILITY_STS = 'Y'      --20230828CHENGHM 注释掉这行
     AND T.FACILITY_TYP in ('2', '4','1') --[2025-06-27] [蒿蕊] [JLBA202504160004] [黄俊铭]添加码值1（供应链融资授信）
   GROUP BY T.CUST_ID;
COMMIT;

--如果授信额度小于余额，取放款额度
--[2025-06-27] [蒿蕊] [JLBA202504160004] [黄俊铭]注释授信额度和已用额度逻辑
--INSERT INTO DATACORE_IE_DW_DGDWKHXX_TEMP2
--  SELECT /*+PARALLEL(8)*/
--   T1.CUST_ID, --客户号
--   CASE
--     WHEN T1.LOAN_ACCT_BAL > NVL(T2.FACILITY_AMT, 0) THEN
--      T1.DRAWDOWN_AMT
--     ELSE
--      T2.FACILITY_AMT
--   END FACILITY_AMT,
--    CASE
--     WHEN T1.LOAN_ACCT_BAL = '0' THEN 0
--     WHEN T1.LOAN_ACCT_BAL > NVL(T2.UNDRAW_FACILITY_AMT, 0) THEN
--      T1.DRAWDOWN_AMT
--     ELSE
--      T2.UNDRAW_FACILITY_AMT
--   END UNDRAW_FACILITY_AMT   --已用额度
--    FROM (SELECT /*+PARALLEL(8)*/
--           A.CUST_ID, --客户号
--           SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL, --贷款余额
--           SUM(DRAWDOWN_AMT) DRAWDOWN_AMT --放款金额
--            FROM SMTMODS.L_ACCT_LOAN A --贷款借据信息表
--           WHERE A.DATA_DATE = IS_DATE
--                --AND A.ITEM_CD NOT LIKE '406%'                  --科目号不为406开头
--             AND A.ITEM_CD NOT LIKE '3010%' --委托业务
--             AND A.ITEM_CD NOT LIKE '3020%'
--             AND A.ITEM_CD NOT LIKE '3030%'
--             AND A.ITEM_CD NOT LIKE '3040%'
--             --AND A.LOAN_ACCT_BAL > 0 --贷款余额大于0 20240304 WXB已结清的取不到，所以放开条件
--           GROUP BY A.CUST_ID) T1
--    LEFT JOIN DATACORE_IE_DW_DGDWKHXX_TEMP6 T2
--      ON T1.CUST_ID = T2.CUST_ID; --客户号关联

--历史移植及核销数据
INSERT INTO DATACORE_IE_DW_DGDWKHXX_TEMP3
  (CUST_ID, LOAN_NUM)
  SELECT /*+ PARALLEL(8) use_hash(t,t1)*/
   T.CUST_ID, --客户号
   T.LOAN_NUM --记录数
  --SUM(DRAWDOWN_AMT), --放款金额
  --SUM(LOAN_ACCT_BAL) --贷款余额
    FROM SMTMODS.L_ACCT_LOAN T --贷款借据信息表
    LEFT JOIN SMTMODS.L_ACCT_WRITE_OFF T1 --贷款核销
      ON T.LOAN_NUM = T1.LOAN_NUM
     AND T1.DATA_DATE = IS_DATE
   WHERE T.DATA_DATE = IS_DATE
     AND T.CANCEL_FLG = 'Y'
     AND SUBSTR(T1.WRITE_OFF_DATE, 1, 6) <> SUBSTR(IS_DATE, 1, 6) /*AND T.HXRQ<= to_char(to_date('20200930','yyyymmdd'),'yyyymmdd')*/
     AND NOT EXISTS (SELECT 1
            FROM DATACORE_IE_DW_DGDWKHXX_TEMP10 B --剔除贷款核销但是存款未核销的客户
           WHERE T.CUST_ID = B.CUST_ID)
     AND NOT EXISTS (SELECT 1
            FROM DATACORE_IE_DW_DGDWKHXX_TEMP10 C
           WHERE T.CUST_ID = C.CUST_ID)
  -- AND CUST_ID<>'6000668295' --核销日期可能有问题
  --GROUP BY T.CUST_ID, T.LOAN_NUM
  ;
COMMIT;
--委托贷款委托人信息
INSERT /*+ append*/
INTO DATACORE_IE_DW_DGDWKHXX_TEMP3
  (CUST_ID, LOAN_NUM)
  SELECT /*+ PARALLEL(8) use_hash(t,t1,b)*/
   B.TRUSTOR_ID, --客户号
   T.LOAN_NUM --记录数
  --sum(DRAWDOWN_AMT),      --放款金额
  --sum(LOAN_ACCT_BAL)      --贷款余额
    FROM SMTMODS.L_ACCT_LOAN T --贷款借据信息表
    LEFT JOIN SMTMODS.L_ACCT_WRITE_OFF T1 --贷款核销
      ON T.LOAN_NUM = T1.LOAN_NUM
     AND T1.DATA_DATE = IS_DATE
    LEFT JOIN SMTMODS.L_ACCT_LOAN_ENTRUST B --委托贷款补充信息表
      ON B.DATA_DATE = IS_DATE
     AND T.LOAN_NUM = B.LOAN_NUM
   WHERE T.DATA_DATE = IS_DATE
     AND T.CANCEL_FLG = 'Y'
     and SUBSTR(T1.WRITE_OFF_DATE, 1, 6) <> SUBSTR(IS_DATE, 1, 6) /*AND T.HXRQ<= to_char(to_date('20200930','yyyymmdd'),'yyyymmdd')*/
     AND T.ITEM_CD LIKE '3020%' --委托贷款
  -- AND CUST_ID<>'6000668295' --核销日期可能有问题
  --GROUP BY T.WTRCUSTID,T.LOAN_NUM
  ;
COMMIT;

--有贷款合同，既有委贷又有正常贷款的客户
INSERT INTO DATACORE_IE_DW_DGDWKHXX_TEMP4
  SELECT T1.CUST_ID, BS, TO_CHAR(T1.RQ, 'YYYY-MM-DD')
    FROM (SELECT /*+ PARALLEL(8)*/
           T.CUST_ID, --客户号
           COUNT(1) BS, --记录数
           MIN(CONTRACT_EFF_DT) RQ --贷款合同生效日期
            FROM SMTMODS.L_AGRE_LOAN_CONTRACT T --贷款合同信息表
           WHERE T.DATA_DATE = IS_DATE
                --AND T.ACCT_TYP <> '90'           --科目编码不为406开头 暂时注释,L层账户类型不全，只有90和空
             AND (T.ACCT_TYP IS NULL OR T.ACCT_TYP <> '90')
           GROUP BY CUST_ID) T1
   INNER JOIN (SELECT T.CUST_ID, --客户号
                      COUNT(1), --记录数
                      MIN(CONTRACT_EFF_DT) RQ --贷款合同生效日期
                 FROM SMTMODS.L_AGRE_LOAN_CONTRACT T --贷款合同信息表
                WHERE T.DATA_DATE = IS_DATE
                  AND T.ACCT_TYP = '90' --委托贷款
                GROUP BY CUST_ID) T2
      ON T1.CUST_ID = T2.CUST_ID; --客户号关联
COMMIT;
--贷款合同，只有正常贷款的客户
INSERT INTO DATACORE_IE_DW_DGDWKHXX_TEMP4
  SELECT /*+PARALLEL(8)*/
   T.CUST_ID, --客户号
   COUNT(1), --记录数
   TO_CHAR(MIN(CONTRACT_EFF_DT), 'YYYY-MM-DD') RQ --贷款合同生效日期
    FROM SMTMODS.L_AGRE_LOAN_CONTRACT T --贷款合同信息表
   WHERE T.DATA_DATE = IS_DATE
        --AND T.ACCT_TYP <> '90'          --科目号不为406开头 暂时注释,L层账户类型不全，只有90和空
     AND (T.ACCT_TYP IS NULL OR T.ACCT_TYP <> '90')
        --and t.kmbh not like '1220101%'
        /*and T.prod_no <>'76002'*/
     AND NOT EXISTS (SELECT *
            FROM DATACORE_IE_DW_DGDWKHXX_TEMP4 A
           WHERE A.CUST_ID = T.CUST_ID) --客户号关联
   GROUP BY T.CUST_ID;
COMMIT;
--只有委托贷款去掉公积金贷款，去掉公积金委托贷款
INSERT INTO DATACORE_IE_DW_DGDWKHXX_TEMP4
  SELECT T.CUST_ID, --客户号
         COUNT(1), --记录数
         TO_CHAR(MIN(CONTRACT_EFF_DT), 'YYYY-MM-DD') RQ --贷款合同生效日期
    FROM SMTMODS.L_AGRE_LOAN_CONTRACT T --贷款合同信息表
   WHERE T.DATA_DATE = IS_DATE
     AND T.ACCT_TYP = '90' --委托贷款
        /*AND T.PROD_NO <> '72002'*/ --个人公积金委托贷款
     AND NOT EXISTS (SELECT *
            FROM DATACORE_IE_DW_DGDWKHXX_TEMP4 A
           WHERE A.CUST_ID = T.CUST_ID)
   GROUP BY CUST_ID;
COMMIT;
--只有委托贷款,委托人信息
INSERT INTO DATACORE_IE_DW_DGDWKHXX_TEMP4
  SELECT B.TRUSTOR_ID, --客户号
         COUNT(1), --记录数
         '' RQ --贷款合同生效日期
    FROM SMTMODS.L_ACCT_LOAN T --贷款信息表
    LEFT JOIN SMTMODS.L_ACCT_LOAN_ENTRUST B --委托贷款补充信息表
      ON B.DATA_DATE = IS_DATE
     AND T.LOAN_NUM = B.LOAN_NUM
   WHERE T.DATA_DATE = IS_DATE
     AND T.ITEM_CD LIKE '3020%' --委托贷款
     AND T.cancel_flg = 'N' --不取核销数据
   AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
        /*AND T.PROD_NO <> '72002'*/ --个人公积金委托贷款
     AND NOT EXISTS (SELECT *
            FROM DATACORE_IE_DW_DGDWKHXX_TEMP4 A
           WHERE A.CUST_ID = B.TRUSTOR_ID)
   GROUP BY B.TRUSTOR_ID
  --HAVING SUM(LOAN_ACCT_BAL) > 0    20241111  将结清客户进行提取
  ;
COMMIT;
--票据（贴现）
INSERT INTO DATACORE_IE_DW_DGDWKHXX_TEMP4
  SELECT /*+PARALLEL(8)*/
   T.CUST_ID, --客户号
   COUNT(1), --记录数
   TO_CHAR(MIN(DRAWDOWN_DT), 'YYYY-MM-DD') RQ --贷款合同生效日期
    FROM SMTMODS.L_ACCT_LOAN T
   WHERE T.DATA_DATE = IS_DATE
        --and item_cd  in ('12901','12905','12902','12906')         --科目号不为406开头
     and (ITEM_CD LIKE '130101%' --以摊余成本计量的贴现
         OR ITEM_CD LIKE '130104%' --以公允价值计量变动计入权益的贴现
         OR ITEM_CD LIKE '130102%' --以摊余成本计量的转贴现
         OR ITEM_CD LIKE '130105%') --以公允价值计量变动计入权益的转贴现
        --and t.kmbh not like '1220101%'
        /*and T.prod_no <>'76002'*/
     AND NOT EXISTS (SELECT *
            FROM DATACORE_IE_DW_DGDWKHXX_TEMP4 A
           WHERE A.CUST_ID = T.CUST_ID) --客户号关联
     AND NOT EXISTS (SELECT 1 FROM SMTMODS.L_CUST_C C  --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]刨除个体工商户
					 WHERE T.CUST_ID = C.CUST_ID AND C.DATA_DATE = IS_DATE
					   AND C.CUST_TYP = '3'
	                )
   GROUP BY T.CUST_ID;

COMMIT;


  INSERT INTO DATACORE_IE_DW_DGDWKHXX_TEMP4 --补充上日余额>0的
    SELECT T.CUST_ID,
           COUNT(1), --记录数
           '' RQ --贷款合同生效日期
      FROM SMTMODS.L_ACCT_LOAN T
     INNER JOIN SMTMODS.L_CUST_C T1
        ON T.CUST_ID = T1.CUST_ID
       AND T1.DATA_DATE =
           TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') - 1, 'YYYYMMDD')
     WHERE T.DATA_DATE =
           TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') - 1, 'YYYYMMDD')
       AND T.LOAN_ACCT_BAL > 0
       AND NOT EXISTS (SELECT 1
              FROM DATACORE_IE_DW_DGDWKHXX_TEMP4 T2
             WHERE T2.CUST_ID = T.CUST_ID)
     GROUP BY T.CUST_ID;

COMMIT;

--存款
INSERT INTO DATACORE_IE_DW_DGDWKHXX_TEMP4
  SELECT /*+parallel(8)*/
   A.CUST_ID, --客户号
   SUM(A.ACCT_BALANCE), --余额
   TO_CHAR(MIN(A.ST_INT_DT), 'YYYY-MM-DD') RQ --起始日期
    FROM SMTMODS.L_ACCT_DEPOSIT A --存款账户信息表
    LEFT JOIN SMTMODS.L_CUST_P C
      ON A.CUST_ID = C.CUST_ID
     AND A.DATA_DATE = C.DATA_DATE

   WHERE (A.GL_ITEM_CODE LIKE '20110202%' --单位一般定期存款
         OR A.GL_ITEM_CODE LIKE '20110203%' --单位大额可转让定期存单
         OR A.GL_ITEM_CODE LIKE '20110204%' --单位协议存款
         OR A.GL_ITEM_CODE LIKE '201107%' --国库定期存款
         OR A.GL_ITEM_CODE LIKE '20110207%' --单位结构性存款

         OR A.GL_ITEM_CODE LIKE '20110205%' --单位通知存款
         OR A.GL_ITEM_CODE LIKE '20110209%' --单位活期保证金存款
         OR A.GL_ITEM_CODE LIKE '20110210%' --单位定期保证金存款
         OR A.GL_ITEM_CODE LIKE '20110201%' --单位活期存款
		 /*[2025-05-27] [蒿蕊] [JLBA202504180011] [黄俊铭]D1092：待结算财政款项取2005财政性存款 D1095增加取2010国库定期存款 D1011取2008和2009 START*/ 
		 OR A.GL_ITEM_CODE LIKE '2005%'     
		 OR A.GL_ITEM_CODE LIKE '2010%'    
		 OR A.GL_ITEM_CODE LIKE '2008%'
		 OR A.GL_ITEM_CODE LIKE '2009%'
		 /*[2025-05-27] [蒿蕊] [JLBA202504180011] [黄俊铭]D1092：待结算财政款项取2005财政性存款 D1095增加取2010国库定期存款 D1011取2008和2009 end */
		 OR A.GL_ITEM_CODE LIKE '201103%' --[2025-12-11] [蒿蕊] [JLBA202507210012] [黄俊铭]增加201103科目
		 )
     AND (C.OPERATE_CUST_TYPE IS NULL OR C.OPERATE_CUST_TYPE <> 'A')
     AND A.DATA_DATE = IS_DATE
     AND NOT EXISTS (SELECT *
            FROM DATACORE_IE_DW_DGDWKHXX_TEMP4 T
           WHERE A.CUST_ID = T.CUST_ID) --客户号关联

     AND NOT EXISTS (SELECT 1
            FROM SMTMODS.L_CUST_C D
           WHERE A.CUST_ID = D.CUST_ID
             AND A.DATA_DATE = D.DATA_DATE
             AND (D.IS_NGI_CUST ='1' AND NVL(D.CUST_TYP,'0') = '3' --个体工商户                    --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]若是NGI客户标识则以NIG客户类型判断
				  OR NVL(D.IS_NGI_CUST,'0')='0' AND NVL(D.DEPOSIT_CUSTTYPE,'0') IN ('13','14')     --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]非NGI客户通过存款人类型判断
				 ) 
			 ) 
   GROUP BY A.CUST_ID;

COMMIT;

--同业存款客户


INSERT INTO DATACORE_IE_DW_DGDWKHXX_TEMP4
  SELECT /*+ USE_HASH(T,A) PARALLEL(8)*/
   A.CUST_ID --客户号     --20240909    NR表加工需要客户号，对数据进行提取，此前这个字段存的是交易对手客户名称
  ,
   SUM(A.BALANCE)
  ,'tyck'
    FROM SMTMODS.L_ACCT_FUND_MMFUND A
   WHERE A.DATA_DATE = IS_DATE
     AND SUBSTR(GL_ITEM_CODE, '1', '4') IN ('1011', '2012')
     /*AND (TO_CHAR(MATURE_DATE, 'YYYYMMDD') >= IS_DATE OR
         MATURE_DATE IS NULL)*/      --20241111  将结清客户进行提取
     AND A.CURR_CD IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD')
     AND NOT EXISTS (SELECT *
            FROM DATACORE_IE_DW_DGDWKHXX_TEMP4 T
           WHERE A.CUST_ID = T.CUST_ID) --客户号关联
   GROUP BY A.CUST_ID;

COMMIT;


--同业借贷客户

INSERT INTO DATACORE_IE_DW_DGDWKHXX_TEMP4
SELECT /*+ USE_HASH(T,A,B) PARALLEL(8)*/
 A.CUST_ID --客户号  add  by  zy  mmfund 已经补了全量客户号  20240909 新增同业客户号取数
,
 sum(A.balance),
 'tyjd'
  FROM SMTMODS.L_ACCT_FUND_MMFUND A
 WHERE A.DATA_DATE = IS_DATE
   and substr(A.gl_item_code, '1', '4') in
       ('2003' --拆入资金
       ,
        '1302') --拆出资金
   /*and (TO_CHAR(mature_date, 'YYYYMMDD') >= IS_DATE or
       ref_num in
       (select ref_num
           FROM SMTMODS.L_TRAN_FUND_FX t
          WHERE DATA_DATE = IS_DATE
            and substr(ITEM_CD, '1', '4') in
                ('2003' --拆入资金
                ,
                 '1302') --拆出资金
            AND AMOUNT IS NOT NULL
            and AMOUNT <> 0
            and CURR_CD IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD')
            and TO_CHAR(MATURITY_DT, 'YYYYMMDD') >= IS_DATE
            and t.tran_dt = to_date(IS_DATE, 'YYYYMMDD')))*/   --20241111  将结清客户进行提取
   and A.CURR_CD IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD')
   AND NOT EXISTS (SELECT *
            FROM DATACORE_IE_DW_DGDWKHXX_TEMP4 T
           WHERE A.CUST_ID = T.CUST_ID) --客户号关联
   GROUP BY A.CUST_ID;

  COMMIT;

INSERT INTO DATACORE_IE_DW_DGDWKHXX_TEMP5
  (DATA_DATE,
   CUST_ID,
   ORG_NUM,
   DEPT_TYPE,
   CORP_SCALE,
   CORP_HOLD_TYPE,
   REG_ADDRESS,
   CORP_BUSINSESS_TYPE,
   --TYSHXYDM,
   ID_NO,
   --ORGANIZATIONCODE,
   REGION_CD,
   --CONTRACT_EFF_DT,
   FKJE)
  SELECT IS_DATE AS DATA_DATE, --1数据日期
         T.CUST_ID, --2客户号
         T.ORG_NUM, --3内部机构号
         T.DEPT_TYPE, --4国民经济部门分类
         T.CORP_SCALE, --6企业规模
         T.CORP_HOLD_TYPE, --7控股类型
         T.BORROWER_REGISTER_ADDR, --8注册地址
         T.CORP_BUSINSESS_TYPE, --9所属行业

         T.ID_NO, --证件号码

         T.REGION_CD, --15经营所在地行政区划代码

         T.FKJE --17放款金额
    FROM (SELECT IS_DATE AS DATA_DATE,
                 T.CUST_ID, --2客户号
                 --T.ORG_NUM, --3内部机构号
                 T.CORE_ORG_NUM ORG_NUM, --3内部机构号               --信贷机构号存在客户机构与业务机构不一致情况，取核心机构号
                 T.CORP_SCALE, --6企业规模
                 T.CORP_HOLD_TYPE, --7控股类型
                 T.BORROWER_REGISTER_ADDR, --8注册地址
                 T.CORP_BUSINSESS_TYPE, --9所属行业
                 T.ID_NO, --证件号码
                 CASE
                   WHEN T.REGION_CD LIKE '%0000' AND
                        T.ORG_AREA NOT LIKE '%0000' THEN
                    SUBSTR(T.ORG_AREA, 0, 6)
                   WHEN T.REGION_CD LIKE '%0000' AND T.ORG_AREA LIKE '%0000' THEN
                    SUBSTR(T.ID_NO, 0, 6)
                   ELSE
                    IRS_DATACORE.GET_AREA_CODE(NVL(T.REGION_CD,T.ORG_AREA))
                 END AS REGION_CD, --15经营所在地行政区划代码
                 CASE
                   WHEN T2.DEPT_TYPE IN ('D01', 'D80') then
                    'D01'
                   WHEN T2.DEPT_TYPE IN ('E02', 'E021', 'E022') then
                    'E02'
                   WHEN T2.DEPT_TYPE IN ('E03', 'E032') then
                    'E03'
                   WHEN T2.DEPT_TYPE IN ('E05', 'E051') then
                    'E05'
                   ELSE
                    T2.DEPT_TYPE
                 END AS DEPT_TYPE, --国门经济部门分类

                 T1.FKJE
            FROM SMTMODS.L_CUST_C T --对公客户补充信息表
            LEFT JOIN DATACORE_IE_DW_DGDWKHXX_TEMP1 T1 --取首次建立信贷关系日期
              ON T.CUST_ID = T1.CUST_ID --客户号
            LEFT JOIN IE_DW_DGKHXX_MAPPING M
              ON T.CUST_ID = M.COD_CUST_ID --客户号关联
            LEFT JOIN SMTMODS.L_CUST_ALL T2
              ON T.CUST_ID = T2.CUST_ID
             AND T2.DATA_DATE = IS_DATE
           WHERE T.DATA_DATE = IS_DATE
                --------20230911 姜怀富
			 AND (T.IS_NGI_CUST ='1' AND NVL(T.CUST_TYP,'0') <> '3' --个体工商户                    --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]若是NGI客户标识则以NIG客户类型判断
	              OR NVL(T.IS_NGI_CUST,'0')='0' AND NVL(T.DEPOSIT_CUSTTYPE,'0') NOT IN ('13','14')  --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]非NGI客户通过存款人类型判断
                 )
          ) T; --数据来源为'CMS'
COMMIT;

--落地表，包含吉林银行+磐石数据
INSERT INTO DATACORE_IE_DW_DGDWKHXX
  (DATA_DATE, --1数据日期
   CUST_ID, --2客户号
   NBJGH, --3内部机构号
   DEPT_TYPE, --4国民经济部门分类
   JRJGBM, --5金融机构类型代码
   ENT_SCALE, --6企业规模
   CORP_HOLD_TYPE, --7控股类型
   JNJW_FLAG, --8境内境外标志
   XZQGHM, --9经营所在地行政区划代码
   ZCDZ, --10注册地址
   FACILITY_AMT, --11授信额度
   USED_FACILITY_AMT, --12已用额度
   INDUSTRY_TYPE --13所属行业

   )
  SELECT IS_DATE, --1数据日期
         T.CUST_ID, --2客户号
         T.ORG_NUM, --3内部机构号
         /* CASE WHEN T.CORP_SCALE IN ('B','T') AND T.DEPT_TYPE ='D010' THEN 'C01'
         WHEN T.CORP_SCALE IN ('B','T') AND T.DEPT_TYPE ='D020' THEN 'C99' ELSE
         SUBSTR(DECODE(T.DEPT_TYPE,'A099','A99',T.DEPT_TYPE),1,3) END,  */ --4国民经济部门分类
         CASE
           WHEN T.CORP_SCALE IN ('B', 'T') AND T.DEPT_TYPE = 'D01' THEN
            'C01'
           WHEN T.CORP_SCALE IN ('B', 'T') AND T.DEPT_TYPE = 'D02' THEN
            'C99'
           ELSE
            SUBSTR(DECODE(T.DEPT_TYPE, 'A099', 'A99', T.DEPT_TYPE), 1, 3)
         END, --4国民经济部门分类 mdf by chm 20231012
         '', /*OFF.BANK_CODE AS JRJGBM,             --5金融机构类型代码*/
         DECODE(trim(T.CORP_SCALE),
                'B',
                'CS01',
                'M',
                'CS02',
                'S',
                'CS03',
                'T',
                'CS04',
    'Z',
                'CS05'), --6企业规模 202403
         DECODE(T.CORP_HOLD_TYPE,
                'A01',
                'A0101',
                'A02',
                'A0102',
                'B01',
                'A0201',
                'B02',
                'A0202',
                'C01',
                'B0101',
                'C02',
                'B0102',
                'D01',
                'B0201',
                'D02',
                'B0202',
                'E01',
                'B0301',
                'E02',
                'B0302'), --7控股类型
         T5.INLANDORRSHORE_FLG as JNJW_FLAG, --8境内境外标志
         T.REGION_CD as XZQGHM, --9经营所在地行政区划代码
         T.REG_ADDRESS as ZCDZ, --10注册地址
         CASE
           WHEN T2.FACILITY_AMT IS NULL THEN
            T.FKJE
           ELSE
            T2.FACILITY_AMT
         END, --11授信额度
         CASE
           WHEN T2.FACILITY_AMT IS NULL THEN
            T.FKJE
           WHEN T2.UNDRAW_FACILITY_AMT>T2.FACILITY_AMT THEN
           T2.FACILITY_AMT          ----已用额度>授信额度  取授信额度
           ELSE
            T2.UNDRAW_FACILITY_AMT
         END, --12已用额度 
		 CASE WHEN LENGTHB(TRIM(T.CORP_BUSINSESS_TYPE))=1 THEN ''
		      ELSE SUBSTRB(TRIM(T.CORP_BUSINSESS_TYPE), 0, 3)
		 END  --13所属行业 --[2025-05-12] [蒿蕊] [无需求] [丹姐]集市针对该字段改造后存在行业大类，修改成如果行业是大类，默认为空

    FROM (SELECT * FROM DATACORE_IE_DW_DGDWKHXX_TEMP5) T
    LEFT JOIN DATACORE_IE_DW_DGDWKHXX_TEMP6 T2 --取授信额度 --[2025-06-27] [蒿蕊] [JLBA202504160004] [黄俊铭]由TEMP2改为TEMP6,从源系统取
      ON T.CUST_ID = T2.CUST_ID --客户号关联
    LEFT JOIN DATACORE_IE_DW_DGDWKHXX_TEMP3 T3 --历史遗留客户、核销客户 不保留
      ON T.CUST_ID = T3.CUST_ID --客户号关联

   INNER JOIN DATACORE_IE_DW_DGDWKHXX_TEMP4 HT --取有贷款合同数据
      ON T.CUST_ID = HT.CUST_ID
    LEFT JOIN IE_DW_DGKHXX_MAPPING M2 ---未知
      ON T.CUST_ID = M2.COD_CUST_ID

    LEFT JOIN SMTMODS.L_CUST_ALL T5 --全量客户信息表
      ON T.CUST_ID = T5.CUST_ID --客户号关联
     AND T5.DATA_DATE = IS_DATE
   WHERE /* T.RN = 1
             AND*/
   (T3.CUST_ID IS NULL OR T.CUST_ID IN ('8000692376', '8911498167')) --去掉核销客户，但8000692376 客户核销但又贷款业务，特殊 处理
  ;
COMMIT;

-------------------吉林银行目标表数据--------------------
INSERT INTO DATACORE_IE_DW_DGDWKHXX_TEMP7
  (DATA_DATE, --1数据日期
   CUST_ID, --2客户号
   NBJGH, --3内部机构号
   DEPT_TYPE, --4国民经济部门分类
   JRJGBM, --5金融机构类型代码
   ENT_SCALE, --6企业规模
   CORP_HOLD_TYPE, --7控股类型
   JNJW_FLAG, --8境内境外标志
   XZQGHM, --9经营所在地行政区划代码
   ZCDZ, --10注册地址
   FACILITY_AMT, --11授信额度
   USED_FACILITY_AMT, --12已用额度
   INDUSTRY_TYPE, --13所属行业
   /*CITY_FLAG,                --14农村城市标志*/
   --CUST_ID_NO,           --15客户证件号码
   CJRQ --16采集日期
   )
  SELECT DATA_DATE, --1数据日期
         CUST_ID, --2客户号
         NBJGH, --3内部机构号
         DEPT_TYPE, --4国民经济部门分类
         JRJGBM, --5金融机构类型代码
         ENT_SCALE, --6企业规模
         CORP_HOLD_TYPE, --7控股类型
         JNJW_FLAG, --8境内境外标志
         XZQGHM, --9经营所在地行政区划代码
         ZCDZ, --10注册地址
         FACILITY_AMT, --11授信额度
         USED_FACILITY_AMT, --12已用额度
         INDUSTRY_TYPE, --13所属行业
         /*  CITY_FLAG,          --14农村城市标志*/
         --CUST_ID_NO,           --15客户证件号码
         CJRQ --16采集日期
    FROM (SELECT /*+PARALLEL(8)*/
           VS_TEXT DATA_DATE, --1数据日期
           T.CUST_ID, --2客户号
           T.NBJGH, --3内部机构号
           SUBSTR(NVL(T1.DEPT_TYPE, T.DEPT_TYPE), 1, 3) DEPT_TYPE, --NVL(T1.DEPT_TYPE, T.DEPT_TYPE), --4国民经济部门分类
           NVL(T1.JRJGBM, T.JRJGBM) JRJGBM, --5金融机构代码
           CASE
             WHEN T1.ENT_SCALE = 'CS05' THEN
              'CS05' /*MOD BY YANLB AT20210109辉哥要求上期是CS05本期取CS05*/
             ELSE
              NVL(T.ENT_SCALE, T1.ENT_SCALE)
           END ENT_SCALE, --6企业规模
           CASE
             WHEN T1.ENT_SCALE = 'CS05' OR
                  NVL(T1.CORP_HOLD_TYPE, T.CORP_HOLD_TYPE) = 'CS05' THEN
              '' /*MOD BY YANLB AT20210109辉哥要求 CS05 经济成分置空*/
             ELSE
              NVL(T1.CORP_HOLD_TYPE, T.CORP_HOLD_TYPE)
           END CORP_HOLD_TYPE, --7控股类型
           T.JNJW_FLAG, --8境内境外标志
           IRS_DATACORE.GET_AREA_CODE(NVL(T1.XZQGHM, T.XZQGHM)) XZQGHM, --9注册地行政区划代码
           NVL(T.ZCDZ, T1.ZCDZ) ZCDZ, --10注册地
           NVL(T.FACILITY_AMT, T1.FACILITY_AMT) FACILITY_AMT, --11授信额度
           NVL(T.USED_FACILITY_AMT, T1.USED_FACILITY_AMT) USED_FACILITY_AMT, --12已用额度
           NVL(T.INDUSTRY_TYPE, T1.INDUSTRY_TYPE) INDUSTRY_TYPE, --13所属行业

           IS_DATE CJRQ --16采集日期

            FROM DATACORE_IE_DW_DGDWKHXX T

          --关联上期取已经报送数据
            LEFT JOIN IE_DW_DGKHXX_MAPPING M
              ON T.CUST_ID = M.COD_CUST_ID

            LEFT JOIN DATACORE_IE_DW_DGDWKHXX_TEMP7 T1
              ON (T.CUST_ID = T1.CUST_ID OR M.COD_CUST_ID = T1.CUST_ID)
             AND T1.CJRQ = VS_LAST_TEXT

           WHERE T.DATA_DATE = IS_DATE

          ) m;

COMMIT;

--将票据部分客户进行添加，由于客户表中没有这部分客户，将借据表中客户号添加到客户表中
INSERT INTO DATACORE_IE_DW_DGDWKHXX_TEMP9
  (DATA_DATE, --1数据日期
   CUST_ID, --2客户号
   NBJGH, --3内部机构号
   JNJW_FLAG, --境内外标识
   CJRQ --16采集日期
   )
  SELECT VS_TEXT AS DATADATE, A.CUST_ID, A.ORG_NUM,A.JNJW_FLAG,IS_DATE
    FROM (SELECT A.CUST_ID,
                 A.ORG_NUM,
                 'Y' AS JNJW_FLAG,
                 ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.ORG_NUM DESC) RN
            FROM SMTMODS.L_ACCT_LOAN A
           WHERE A.DATA_DATE = IS_DATE
             AND (ITEM_CD LIKE '130101%' --以摊余成本计量的贴现
                 OR ITEM_CD LIKE '130104%' --以公允价值计量变动计入权益的贴现
                 OR ITEM_CD LIKE '130102%' --以摊余成本计量的转贴现
                 OR ITEM_CD LIKE '130105%') --以公允价值计量变动计入权益的转贴现
			 AND NOT EXISTS (SELECT 1 FROM SMTMODS.L_CUST_C C  --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]刨除个体工商户
					 WHERE A.CUST_ID = C.CUST_ID AND C.DATA_DATE = IS_DATE
					   AND C.CUST_TYP = '3'
	                )
             /*AND (A.LOAN_ACCT_BAL > 0 OR
                 TO_CHAR(A.FINISH_DT, 'YYYYMMDD') = IS_DATE OR
                 (TO_CHAR(A.DRAWDOWN_DT, 'YYYY-MM-DD') = VS_TEXT AND
                 A.LOAN_ACCT_BAL = 0))*/      --20241204   取结清的票据客户
             AND A.ORG_NUM NOT LIKE '5100%') A
   WHERE RN = 1
     AND NOT EXISTS (SELECT 1
            FROM DATACORE_IE_DW_DGDWKHXX_TEMP7 B
           WHERE A.CUST_ID = B.CUST_ID);

INSERT INTO DATACORE_IE_DW_DGDWKHXX_TEMP9
  (DATA_DATE, --1数据日期
   CUST_ID, --2客户号
   NBJGH, --3内部机构号
   JNJW_FLAG, --境内外标识
   CJRQ --16采集日期
   )
  SELECT VS_TEXT AS DATADATE, A.CUST_ID, A.ORG_NUM,A.JNJW_FLAG,IS_DATE
    FROM (SELECT A.CUST_ID,
                 A.ORG_NUM,
                 'Y' AS JNJW_FLAG,
                 ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.ORG_NUM DESC) RN
            FROM SMTMODS.L_ACCT_LOAN A

           WHERE A.DATA_DATE = IS_DATE
             AND (ITEM_CD LIKE '130101%' --以摊余成本计量的贴现
                 OR ITEM_CD LIKE '130104%' --以公允价值计量变动计入权益的贴现
                 OR ITEM_CD LIKE '130102%' --以摊余成本计量的转贴现
                 OR ITEM_CD LIKE '130105%') --以公允价值计量变动计入权益的转贴现
             /*AND (A.LOAN_ACCT_BAL > 0 OR
                 TO_CHAR(A.FINISH_DT, 'YYYYMMDD') = IS_DATE OR
                 (TO_CHAR(A.DRAWDOWN_DT, 'YYYY-MM-DD') = VS_TEXT AND
                 A.LOAN_ACCT_BAL = 0))*/      --20241204   取结清的票据客户
             AND A.ORG_NUM LIKE '5100%') A
   WHERE RN = 1
     AND NOT EXISTS (SELECT 1
            FROM DATACORE_IE_DW_DGDWKHXX_TEMP7 B
           WHERE A.CUST_ID = B.CUST_ID);

INSERT INTO DATACORE_IE_DW_DGDWKHXX_TEMP7
  (DATA_DATE, --1数据日期
   CUST_ID, --2客户号
   NBJGH, --3内部机构号
   JNJW_FLAG, --境内外标识
   CJRQ --16采集日期
   )
  SELECT DATA_DATE, CUST_ID, NBJGH,JNJW_FLAG,CJRQ
    FROM DATACORE_IE_DW_DGDWKHXX_TEMP9;

COMMIT;

SP_IRS_PARTITIONS(IS_DATE, 'IE_KH_DGKHXX', OI_RETCODE);
INSERT INTO IE_KH_DGKHXX
  (DATADATE, --1数据日期
   CUSTID, --2客户号
   CORPID, --3内部机构号
   DEPTTYPE, -- 4国民经济部门分类
   ORGTPTPCODE, --5金融机构类型代码
   ENTSCALE, -- 6企业规模
   HOLDTYPE, --7控股类型
   DOOVFLG, --8境内境外标志
   AREACODE, --9经营所在地行政区划代码
   REGADDRESS, --10注册地址
   CRDTLMT, --11授信额度
   USEDLMT, --12已用额度
   INDNO, --13所属行业
   AREATYPE, --14农村城市标志
   CJRQ, --15采集日期
   NBJGH, --16内部机构号

   BIZ_LINE_ID, --18业务条线
   VERIFY_STATUS, --19校验状态
   BSCJRQ, --20报送日期
   IRS_CORP_ID --21法人机构ID
   )
  SELECT VS_TEXT, --1数据日期
         M.CUST_ID, --2客户号
         M.NBJGH, --3内部机构号
         CASE
           WHEN T1.CUST_ID IS NOT NULL THEN
            T1.NEW_GMJJBM

           ELSE
            M.DEPT_TYPE
         END, --4国民经济部门分类
         M.JRJGBM, --5金融机构类型代码
         /*CASE
           WHEN T2.CUST_ID IS NOT NULL THEN
            T2.NEW_QYGM
           ELSE
            M.ENT_SCALE
         END, --6企业规模 */
		 CASE WHEN (CASE WHEN T1.CUST_ID IS NOT NULL THEN T1.NEW_GMJJBM ELSE M.DEPT_TYPE END) IN ('C01','C02') AND M.ENT_SCALE='CS05'
		      THEN NVL(T2.NEW_QYGM,M.ENT_SCALE)
			  ELSE NVL(M.ENT_SCALE,T2.NEW_QYGM)
	     END,  --6企业规模  --[2025-05-12] [蒿蕊] [无需求] [黄俊铭]1.国门经济部门类型是C01或C02且企业规模是CS05其他、2.源系统企业规模为空时从DATACORE_TMP_DGKH_QYGM取
         M.CORP_HOLD_TYPE, --7控股类型
         CASE WHEN M.CUST_ID LIKE '2999%' THEN 'Y' ELSE M.JNJW_FLAG END, --8境内境外标志     20240909  内部户默认为境内客户
         CASE
           WHEN M.CUST_ID = '2999990000' THEN '220100'
           WHEN b.param_code IS null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1, 2) = '00' THEN
            '220100'
           WHEN b.param_code IS null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1, 2) = '01' THEN
            '220100'
           WHEN b.param_code IS null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1, 2) = '02' THEN
            '220200'
           WHEN b.param_code IS null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1, 2) = '03' THEN
            '220400'
           WHEN b.param_code IS null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1, 2) = '04' THEN
            '220500'
           WHEN b.param_code IS null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1, 2) = '05' THEN
            '220700'
           WHEN b.param_code IS null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1, 2) = '06' THEN
            '222400'
           WHEN b.param_code IS null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1, 2) = '07' THEN
            '220300'
           WHEN b.param_code IS null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1, 2) = '08' THEN
            '220800'
           WHEN b.param_code IS null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1, 2) = '09' THEN
            '220600'
           WHEN b.param_code IS null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1, 2) = '10' THEN
            '210200'
           WHEN b.param_code IS null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1, 2) = '11' THEN
            '210100'
           WHEN b.param_code IS null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1, 2) = '13' THEN
            '220100'
           WHEN b.param_code IS null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1, 2) = '51' THEN
            '220284'
           WHEN b.param_code IS null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1, 2) = '52' THEN
            '225200'
           WHEN b.param_code IS null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1, 2) = '53' THEN
            '220283'
           WHEN b.param_code IS null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1, 2) = '54' THEN
            '220112'
           WHEN b.param_code IS  null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1 ,2) = '55' THEN
            '130900'
           WHEN b.param_code IS null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1, 2) = '56' THEN
            '131023'
           WHEN b.param_code IS null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1, 2) = '57' THEN
            '222404'
           WHEN b.param_code IS null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1, 2) = '58' THEN
            '220300'
           WHEN b.param_code IS null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1, 2) = '59' THEN
            '220402'
           WHEN b.param_code IS null and m.DQDM IS not null AND
                SUBSTR(M.NBJGH, 1, 2) = '60' THEN
            '220402'
           ELSE
            M.DQDM
         END,
         --9经营所在地行政区划代码
         M.ZCDZ, --10注册地址
         M.FACILITY_AMT, --11授信额度
         M.USED_FACILITY_AMT, --12已用额度
         CASE
           WHEN T.CUST_ID IS NOT NULL THEN
            T.NEW_SSHY
           ELSE
            M.INDUSTRY_TYPE
         END, --13所属行业

         M.FLAG, --14农村城市标志
         IS_DATE, --15采集日期
         M.NBJGH2, --16内部机构号
         '99', --18业务条线
         '',
         '',
         CASE
           WHEN M.NBJGH LIKE '51%' THEN
            '510000'
           WHEN M.NBJGH LIKE '52%' THEN
            '520000'
           WHEN M.NBJGH LIKE '53%' THEN
            '530000'
           WHEN M.NBJGH LIKE '54%' THEN
            '540000'
           WHEN M.NBJGH LIKE '55%' THEN
            '550000'
           WHEN M.NBJGH LIKE '56%' THEN
            '560000'
           WHEN M.NBJGH LIKE '57%' THEN
            '570000'
           WHEN M.NBJGH LIKE '58%' THEN
            '580000'
           WHEN M.NBJGH LIKE '59%' THEN
            '590000'
           WHEN M.NBJGH LIKE '60%' THEN
            '600000'
           ELSE
            '990000'
         END --21法人机构ID
    FROM (SELECT A.DATA_DATE, --1数据日期
                 A.CUST_ID, --2客户号
                 CASE
                   WHEN C.NBJGH IS NOT NULL THEN
                    C.NEW_NBJGH
                   ELSE
                    A.NBJGH
                 END AS NBJGH, --3内部机构号
                 --NBJGH,                   --3内部机构号

                 trim(DEPT_TYPE) AS DEPT_TYPE, --4国民经济部门分类
                 trim(JRJGBM) AS JRJGBM, --5金融机构类型代码
                 ENT_SCALE, --6企业规模
                 A.CORP_HOLD_TYPE, --7控股类型
                 JNJW_FLAG, --8境内境外标志
                 CASE
                   WHEN TRIM(B.XZQHDM) IS NOT NULL THEN
                    TRIM(B.NEW_XZQUHM)
                   WHEN A.XZQGHM LIKE '%乾安县%' THEN
                    '220723'
                   WHEN A.XZQGHM LIKE '%龙山区%' THEN
                    '220402'
                   WHEN A.XZQGHM LIKE '%安图县%' THEN
                    '222426'

                  /*WHEN A.XZQGHM = '000000' THEN
                    ''*/
                   ELSE
                    TRIM(A.XZQGHM)
                 END AS DQDM, --9经营所在地行政区划代码
                 SDS_REPLACE_ASCII(ZCDZ) AS ZCDZ, --10注册地址
                 FACILITY_AMT, --11授信额度
                 USED_FACILITY_AMT, --12已用额度
                 CASE
                   WHEN translate(INDUSTRY_TYPE, '0123456789', ' ') <> ' ' then
                    INDUSTRY_TYPE
                   else
                    ''
                 end AS INDUSTRY_TYPE, --13所属行业
                  CASE
                    WHEN X.CITY_VILLAGE_FLG IN ('0', '1') THEN 'N'
                    WHEN X.CITY_VILLAGE_FLG IN ('2', '3') THEN 'Y'
                    ELSE X.FARMING_FLAG
                     END AS FLAG,                      --14农村城市标志 先取农村城镇标识这个字段识别，如果为空值的以农户标识作为补充 202403
                 /*CUST_ID_NO,           --15客户证件号码*/
                 CJRQ, --15采集日期
                 CASE
                   WHEN C.NBJGH IS NOT NULL THEN
                    C.NEW_NBJGH
                   ELSE
                    A.NBJGH
                 END NBJGH2 --16内部机构号

          /* --NBJGH，                --16内部机构号
          '99',                  --18业务条线
          '',
          ''*/
            FROM DATACORE_IE_DW_DGDWKHXX_TEMP7 A
            LEFT JOIN DATACORE_XZQHDM B
              ON TRIM(A.XZQGHM) = TRIM(B.XZQHDM)
            LEFT JOIN DATACORE_NBJGH C
              ON A.NBJGH = C.NBJGH
                --where lengthb(trim(XZQGHM))='6'
          LEFT JOIN SMTMODS.L_CUST_C X
                ON A.CUST_ID = X.CUST_ID
               AND X.DATA_DATE = IS_DATE
             WHERE A.DATA_DATE = VS_TEXT

          ) m

    LEFT JOIN DATACORE_tmp_dgkh_sshy T
      ON M.CUST_ID = T.CUST_ID
    left join DATACORE_tmp_dgkh_gmjjbm t1
      on m.cust_id = t1.cust_id
    left join DATACORE_TMP_DGKH_QYGM t2
      on M.cust_id = t2.cust_id

    left join M_EAST_META_FIELD_SCOPE b
      on m.DQDM = b.param_code
     and b.data_meta_code = 'C_REGION_CODE_CUST'
     and b.is_valid = '1'

  ;
COMMIT;

--解决委托贷款表委托人客户问题

UPDATE ie_kh_dgkhxx A
   SET A.CORPID = '010601'
 WHERE A.CJRQ = IS_DATE
   AND A.CUSTID = '8924036027';
UPDATE ie_kh_dgkhxx A
   SET A.NBJGH = '010601'
 WHERE A.CJRQ = IS_DATE
   AND A.CUSTID = '8924036027';
UPDATE ie_kh_dgkhxx A
   SET A.IRS_CORP_ID = '990000'
 WHERE A.CJRQ = IS_DATE
   AND A.CUSTID = '8924036027';
COMMIT;
---在97机构上游更改之前，用此过程
SP_TASK_IRS_97(IS_DATE, OI_RETCODE);

/*--每年第一期，把上年关停的企业状态改为关停状态
  IF (SUBSTR(IS_DATE,5,2) = '01') THEN
    UPDATE PBOCD.JS_102_FTYKHX A SET A.BUSI_STATUS = '02' WHERE A.CJRQ = IS_DATE AND A.CUST_ID_NO IN(
           SELECT B.CUST_ID_NO FROM PBOCD.JS_102_FTYKHX B WHERE B.CJRQ = VS_LAST_TEXT AND B.BUSI_STATUS IN('04','05','06','07'));
    COMMIT;
  END IF;*/
-----优化国民经济部门取数，减少运维手工补录 add by chm 口径同金数 20231012-----

--企业规模为CS01-大型至CS04-微型的，客户国民经济部门应该为C开头的非金融企业部门或者B开头的金融机构
INSERT INTO GMJJBM_BL
  SELECT A.CUSTID, B.CUST_NAM
    FROM IE_KH_DGKHXX A
    LEFT JOIN SMTMODS.L_CUST_ALL B
      ON A.CUSTID = B.CUST_ID
     AND B.DATA_DATE = IS_DATE
   WHERE A.CJRQ = IS_DATE
     AND A.CORPID = '990000'
     AND SUBSTR(A.DEPTTYPE, 1, 1) NOT IN ('B', 'C')
     AND A.ENTSCALE IN ('CS01', 'CS02', 'CS03', 'CS04')
     AND (B.CUST_NAM LIKE '%有限责任公司' OR B.CUST_NAM LIKE '%有限公司');

COMMIT;

--经业务确认，有限公司的国民经济部门都是C01

INSERT INTO GMJJBM_BL
  SELECT A.CUSTID, B.CUST_NAM
    FROM IE_KH_DGKHXX A
    LEFT JOIN SMTMODS.L_CUST_ALL B
      ON A.CUSTID = B.CUST_ID
     AND B.DATA_DATE = IS_DATE
   WHERE A.CJRQ = IS_DATE
     AND A.CORPID = '990000'
     AND (SUBSTR(A.DEPTTYPE, 1, 1) IN ('B', 'D') OR A.DEPTTYPE IS NULL)
     AND (B.CUST_NAM LIKE '%有限责任公司' OR B.CUST_NAM LIKE '%有限公司');

COMMIT;

UPDATE IE_KH_DGKHXX T
   SET DEPTTYPE = 'C01'
 WHERE T.CJRQ = IS_DATE
   AND CORPID = '990000'
   AND EXISTS (SELECT 1 FROM GMJJBM_BL A WHERE A.CUSTID = T.CUSTID);

COMMIT;

-------------------------------------------------------------------------
OI_RETCODE := 0; --设置异常状态为0 成功状态

--返回中文描述
OI_RETCODE2 := '成功!';

/*COMMIT; --非特殊处理只能在最后一次提交*/
-- 结束日志
VS_STEP := 'END';
SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
EXCEPTION WHEN OTHERS THEN
--如果出现异常
VI_ERRORCODE := SQLCODE; --设置异常代码
VS_TEXT := VS_STEP || '|' || IS_DATE || '|' || SUBSTR(SQLERRM, 1, 200); --设置异常描述
ROLLBACK; --数据回滚
OI_RETCODE := -1; --设置异常状态为-1

--返回中文描述

OI_RETCODE2 := SUBSTR(SQLERRM, 1, 200);

--插入日志表，记录错误
SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
END;
/

