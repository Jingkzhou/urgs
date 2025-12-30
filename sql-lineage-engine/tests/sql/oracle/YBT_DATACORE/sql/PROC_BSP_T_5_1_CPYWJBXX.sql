DROP Procedure IF EXISTS `PROC_BSP_T_5_1_CPYWJBXX` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_5_1_CPYWJBXX"(IN I_DATE VARCHAR(8),
                                        OUT OI_RETCODE   INT,-- 返回code
                                        OUT OI_REMESSAGE VARCHAR -- 返回message
)
BEGIN
/******
      程序名称  ：产品业务基本信息
      程序功能  ：加工产品业务基本信息
      目标表：T_5_1
      源表  ： 
      创建人  ：LZ
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
	-- 	JLBA202411180016_关于修正一表通与综合理财系统数据对接准确性的需求
	 -- 20250520 吴大为老师邮寄通知修改 债券发行部分取数规则将兑付日期与到期日写为固定日期修改产品号与产品名称取值将产品唯一 修改人姜俐锋 
	 -- JLBA202505280002 上线日期：2025-06-19，修改人：巴启威  提出人：吴大为  修改原因：因一表通校验问题发现的代码逻辑调整
	 /* JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
  #声明变量
  DECLARE P_DATE   		DATE;			#数据日期
  DECLARE P_PROC_NAME  	VARCHAR(200);	#存储过程名称
  DECLARE P_STATUS  	INT;  			#执行状态
  DECLARE P_START_DT  	DATETIME;		#日志开始日期
  DECLARE P_END_TIME  	DATETIME;		#日志结束日期
  DECLARE P_SQLCDE		VARCHAR(200);	#日志错误代码
  DECLARE P_STATE  		VARCHAR(200);	#日志状态代码
  DECLARE P_SQLMSG		VARCHAR(2000);	#日志详细信息
  DECLARE P_STEP_NO   	INT;			#日志执行步骤
  DECLARE P_DESCB  		VARCHAR(200);	#日志执行步骤描述
  DECLARE BEG_MON_DT 	VARCHAR(8);		#月初
  DECLARE BEG_QUAR_DT 	VARCHAR(8);		#季初
  DECLARE BEG_YEAR_DT 	VARCHAR(8);		#年初
  DECLARE LAST_MON_DT  	VARCHAR(8);		#上月末
  DECLARE LAST_QUAR_DT  VARCHAR(8);		#上季末
  DECLARE LAST_YEAR_DT  VARCHAR(8);		#上年末
  DECLARE LAST_DT  		VARCHAR(8);		#上日
  DECLARE FINISH_FLG    VARCHAR(8);		#完成标志  
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
	SET P_PROC_NAME = 'PROC_BSP_T_5_1_CPYWJBXX';
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
	
	DELETE FROM ybt_datacore.T_5_1 WHERE E010017 = to_char(P_DATE,'yyyy-mm-dd');
	
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
 INSERT  INTO ybt_datacore.T_5_1  (
     E010001,  -- 01.产品ID
     E010002,  -- 02.机构ID
     E010003,  -- 03.产品名称
     E010004,  -- 04.产品编号
     E010005,  -- 05.科目类型
     E010007,  -- 07.产品类别
     E010008,  -- 08.自营标识
     E010009,  -- 09.产品币种
     E010010,  -- 10.产品期限
     E010011,  -- 11.产品成立日期
     E010012,  -- 12.产品到期日期
     E010013,  -- 13.产品期次
     E010014,  -- 14.利率类型
     E010015,  -- 15.产品状态代码
     E010018,  -- 16.代客产品所属机构名称
     E010016,  -- 17.备注
     E010017,   -- 18.采集日期
     DIS_DATA_DATE,
     DIS_BANK_ID ,   -- 机构号
     DEPARTMENT_ID       -- 业务条线
   ) 
   select
      distinct 
       A.CP_ID                 ,  -- 01.产品ID
       CASE WHEN A.ORG_NUM = '00000' THEN 'B0302H22201990000'
            ELSE NVL(ORG.ORG_ID,'B0302H22201990000')
             END               ,  -- 02.机构ID
       NVL(A.CPMC,0)           ,  -- 03.产品名称
       A.CPBH                  ,  -- 04.产品编号
       CASE
             WHEN T1.GL_CD_TYPE = '1' THEN '01'
             WHEN T1.GL_CD_TYPE = '2' THEN '02'
             WHEN T1.GL_CD_TYPE = '3' THEN '03'
             WHEN T1.GL_CD_TYPE = '4' THEN '04'
             WHEN T1.GL_CD_TYPE = '5' THEN '05'
             WHEN T1.GL_CD_TYPE = '6' THEN '06'
             WHEN T1.GL_CD_TYPE = '7' THEN '00'
             else '00'
          END                  ,  -- 05.科目类型
       A.CPLB                  ,  -- 07.产品类别
       NVL(A.ZYBS,'01')                  ,  -- 08.自营标识
       NVL(A.CPZL,'CNY')                  ,  -- 09.产品币种
       CASE WHEN A.CPMC LIKE '%存款%' THEN '0' 
            WHEN A.DQRQ IS NULL OR SUBSTR(A.DQRQ,1,4) IN ('2999','2099') THEN '0'
            ELSE DATEDIFF(A.DQRQ,A.CLRQ)
             END               ,  -- 10.产品期限
    
       CASE WHEN LENGTH(A.CLRQ) = 10 then A.CLRQ
            else TO_CHAR(TO_DATE(A.CLRQ,'YYYYMMDD'),'YYYY-MM-DD')
            /*( case when A.CLRQ > I_DATE then TO_CHAR(TO_DATE(A.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD')
                    else TO_CHAR(TO_DATE(A.CLRQ,'YYYYMMDD'),'YYYY-MM-DD')  
                    end )*/
             END               ,  -- 11.产品成立日期
       CASE WHEN LENGTH(A.DQRQ) = 10 THEN A.DQRQ
            WHEN A.CPMC LIKE '%存款%' THEN '9999-12-31' 
            WHEN A.DQRQ IS NULL OR SUBSTR(A.DQRQ,1,4) IN ('2999','2099') THEN '9999-12-31'
            ELSE TO_CHAR(TO_DATE(A.DQRQ,'YYYYMMDD'),'YYYY-MM-DD')          
             END               ,  -- 12.产品到期日期
       A.CPQC                  ,  -- 13.产品期次
       A.LLLX                  ,  -- 14.利率类型
       CASE WHEN A.ZTDM IN ('N','O','1','01') THEN '01'
            WHEN A.ZTDM IN ('D','Z','0','2','3','02') THEN '02'
            ELSE '01'
             END               ,  -- 15.产品状态代码
       A.DKCPJGMC              ,  -- 16.代客产品所属机构名称
       -- A.BZ                    ,  -- 17.备注
       A.DATE_SOURCESD          ,
       TO_CHAR(TO_DATE(A.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD'),   -- 17.采集日期
       TO_CHAR(TO_DATE(A.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
       CASE WHEN A.ORG_NUM = '00000' THEN '990000'
            ELSE NVL(A.ORG_NUM,'990000')
             END   ,                                                   --  '机构号'
	   '0098SJ'                                                        -- 业务条线  默认数据管理部
       FROM SMTMODS.L_BASIC_PRODUCT A
       LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
              ON A.ORG_NUM = ORG.ORG_NUM
             AND ORG.DATA_DATE = I_DATE
       LEFT JOIN SMTMODS.L_FINA_INNER T1 -- 科目表
              ON a.GL_ITEM_CODE = t1.STAT_SUB_NUM
             AND t1.ORG_NUM ='990000'
             AND t1.DATA_DATE = I_DATE
       WHERE A.DATA_DATE = I_DATE
       and A.CP_ID <> '901686' --  -- 20250520 吴大为老师邮寄通知修改 债券发行单独取
    ;


  
    COMMIT;
    

	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);		
	
		  #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '代理代销产品数据插入';
	
 INSERT  INTO ybt_datacore.T_5_1  (
     E010001,  -- 01.产品ID
     E010002,  -- 02.机构ID
     E010003,  -- 03.产品名称
     E010004,  -- 04.产品编号
     E010005,  -- 05.科目类型
     E010007,  -- 07.产品类别
     E010008,  -- 08.自营标识
     E010009,  -- 09.产品币种
     E010010,  -- 10.产品期限
     E010011,  -- 11.产品成立日期
     E010012,  -- 12.产品到期日期
     E010013,  -- 13.产品期次
     E010014,  -- 14.利率类型
     E010015,  -- 15.产品状态代码
     E010018,  -- 16.代客产品所属机构名称
     E010016,  -- 17.备注
     E010017,   -- 18.采集日期
     DIS_DATA_DATE,
     DIS_BANK_ID ,   -- 机构号
     DEPARTMENT_ID       -- 业务条线
   ) 
   select
      DISTINCT
       A.PROD_CODE                    ,  -- 01.产品ID
       CASE when A.ORG_NUM ='009804' THEN 'B0302H22201009804'
            ELSE 'B0302H22201009823' end ,  -- 02.机构ID  20250507 吴大为老师提供口径修改 jlf
--        CASE WHEN ORG.ORG_ID IS NULL THEN 'B0302H22201990000'
--             ELSE ORG.ORG_ID
--             END                       ,  -- 02.机构ID
       A.PROD_NAME                    ,  -- 03.产品名称
       A.PROD_CODE                    ,  -- 04.产品编号
       CASE WHEN A.PROD_NAME LIKE '%债%' THEN '00' -- [20250619][巴启威][JLBA202505280002][吴大为]：债券承分销 默认 00-其他
            ELSE '06'
             END                      ,  -- 05.科目类型  -- 20250507 20250507 吴大为老师提供口径修改 jlf 原为01
       CASE WHEN A.PROD_NAME LIKE '%债%' THEN '3208;2101' -- [20250619][巴启威][JLBA202505280002][吴大为]：债券承分销 默认 3208;2101
            ELSE '3208'   
             END                      ,  -- 07.产品类别
       CASE WHEN A.PROD_NAME LIKE '%债%' THEN '03' -- [20250619][巴启威][JLBA202505280002][吴大为]：债券承分销 03-混合
            ELSE '02'                           
             END                      ,  -- 08.自营标识
       A.CURR_TYPE                    ,  -- 09.产品币种
       CASE WHEN A.ESTAB_DATE IS NULL OR A.END_DATE IS NULL OR SUBSTR(A.END_DATE,1,4) IN ('2100','2099','2098') OR A.ESTAB_DATE = '0' OR A.ISSUER_NAME LIKE '%基金%' THEN '0'
            ELSE DATEDIFF(A.END_DATE,A.ESTAB_DATE)
             END                      ,  -- 10.产品期限
       CASE WHEN     
       ( CASE WHEN LENGTH(A.ESTAB_DATE) = '8' THEN TO_CHAR(TO_DATE(A.ESTAB_DATE,'YYYYMMDD'),'YYYY-MM-DD')
            ELSE T.QYRQ
             END) > TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')
             THEN  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')
             ELSE ( CASE WHEN LENGTH(A.ESTAB_DATE) = '8' THEN TO_CHAR(TO_DATE(A.ESTAB_DATE,'YYYYMMDD'),'YYYY-MM-DD')
            ELSE T.QYRQ
             END)
             END 
             ,  -- 11.产品成立日期
       CASE WHEN LENGTH(A.END_DATE) = '8' THEN TO_CHAR(TO_DATE(A.END_DATE,'YYYYMMDD'),'YYYY-MM-DD')
            WHEN A.ESTAB_DATE IS NULL OR A.END_DATE IS NULL OR SUBSTR(A.END_DATE,1,4) IN ('2100','2099','2098') OR A.ESTAB_DATE = '0' OR A.ISSUER_NAME LIKE '%基金%' THEN '9999-12-31'
            ELSE t.DQRQ
             END                      ,  -- 12.产品到期日期
       null                           ,  -- 13.产品期次
       CASE WHEN A.PROD_NAME LIKE '%债%' THEN '02' -- [20250619][巴启威][JLBA202505280002][吴大为]：债券承分销 02-浮动利率
            ELSE ''
             END                      ,  -- 14.利率类型
       '01'                           ,  -- 15.产品状态代码
       A.ISSUER_NAME                  ,  -- 16.代客产品所属机构名称
       '代理代销产品'                  ,  -- 17.备注
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),   -- 17.采集日期
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
--        CASE WHEN A.ORG_NUM IS NULL THEN '990000'
--             ELSE A.ORG_NUM
--              END    
       CASE WHEN A.ORG_NUM ='009804' THEN '009804'
            ELSE '009823' end                            ,   --  '机构号'20250507 吴大为老师提供口径修改 jlf
	  -- CASE WHEN T.SYS_SOURCE = '02' AND  T.RZRHYLX  = '16' AND T.DLCPLX IN ('02','04','05','06','07') 
	   CASE WHEN A.ORG_NUM ='009804' THEN '009804'
            ELSE '009823' end  -- ID20250507 吴大为老师提供口径修改 jlf
--         CASE WHEN T.SYS_SOURCE = '02'  AND T.DLCPLX IN ('02','04','05','06','07')   -- modify by haorui 20241226 JLBA202409290005 贵金属的RZRHYLX是00-08 改为用系统来源区分
--            THEN '009823'  -- 吉林银行财富管理部 条线与8.11对应部分一致
--            ELSE '0098SJ'  END 
       FROM SMTMODS.L_PROD_AGENCY_PRODUCT A -- 代理代销产品信息表
       LEFT JOIN SMTMODS.L_AGRE_PROD_AGENCY T
              ON A.PROD_CODE= t.DLCP_ID
             AND T.DATA_DATE = I_DATE
       LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
              ON A.ORG_NUM = ORG.ORG_NUM
             AND ORG.DATA_DATE = I_DATE
       WHERE A.DATA_DATE = I_DATE
         AND A.PROD_NAME IS NOT NULL 
         -- and A.ESTAB_DATE <= I_DATE
         AND (A.ESTAB_DATE <= I_DATE OR t.QYRQ<= I_DATE)   -- JLBA202411180016 20241217 修改
       AND NOT EXISTS (SELECT 1 FROM ybt_datacore.T_5_1 B WHERE B.E010001 = A.PROD_CODE AND B.DIS_DATA_DATE = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'))
   ;
      COMMIT;
      
      CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
	
   #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '理财数据插入';
	
 INSERT  INTO ybt_datacore.T_5_1  (
     E010001,  -- 01.产品ID
     E010002,  -- 02.机构ID
     E010003,  -- 03.产品名称
     E010004,  -- 04.产品编号
     E010005,  -- 05.科目类型
     E010007,  -- 07.产品类别
     E010008,  -- 08.自营标识
     E010009,  -- 09.产品币种
     E010010,  -- 10.产品期限
     E010011,  -- 11.产品成立日期
     E010012,  -- 12.产品到期日期
     E010013,  -- 13.产品期次
     E010014,  -- 14.利率类型
     E010015,  -- 15.产品状态代码
     E010018,  -- 16.代客产品所属机构名称
     E010016,  -- 17.备注
     E010017,   -- 18.采集日期
     DIS_DATA_DATE,
     DIS_BANK_ID ,   -- 机构号
     DEPARTMENT_ID       -- 业务条线
   ) 
    -- 新增20241015上线JLBA202407090005_关于一表通监管数据报送系统中“表外业务手续费及收益表”及“产品业务基本信息表”改造的需求
   SELECT
       A.DJZXBM              AS       E010001         ,  -- 01.产品ID
       'B0302H22201009816'   AS       E010002         ,  -- 02.机构ID
       A.PROD_NAME           AS       E010003         ,  -- 03.产品名称
       A.PRODUCT_CODE        AS       E010004         ,  -- 04.产品编号
       '06'                  AS       E010005         ,  -- 05.科目类型
       '3201'                AS       E010007         ,  -- 07.产品类别
       '01'                  AS       E010008         ,  -- 08.自营标识
       'CNY'                 AS       E010009         ,  -- 09.产品币种
       to_char(ROUND(CASE
       WHEN SUBSTR( OPER_TYPE,1,1) ='1' THEN  TO_DATE( A.PRODUCT_END_DATE ,'YYYYMMDD')- TO_DATE(A.ST_INT_DT ,'YYYYMMDD')
       WHEN SUBSTR( OPER_TYPE,1,1) ='2' THEN  '0'
       ELSE '0'
       END))                AS E010010               ,  -- 10.产品期限
       TO_CHAR(TO_DATE(A.ST_INT_DT,'YYYYMMDD'),'YYYY-MM-DD')  AS  E010011 ,  -- 11.产品成立日期
       TO_CHAR(TO_DATE(A.PRODUCT_END_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS  E010013,  -- 12.产品到期日期
       A.CPQC               AS       E010013         ,  -- 13.产品期次
       '02'                 AS       E010014         ,  -- 14.利率类型
       CASE WHEN A.PRODUCT_END_DATE >=  I_DATE THEN  '01'
       ELSE '02'
       END                  AS       E010015         ,  -- 15.产品状态代码
       NULL                 AS       E010018         ,  -- 16.代客产品所属机构名称
       '理财产品'            AS       E010016         ,  -- 17.备注
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS E010017  ,   -- 17.采集日期
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE ,
       A.ORG_NUM            AS      DIS_BANK_ID      ,   -- 机构号,   
       '009816'             AS      DEPARTMENT_ID       -- 业务条线        
       FROM SMTMODS.L_FIMM_PRODUCT A 
       WHERE A.DATA_DATE = I_DATE
       AND A.PROD_NAME IS NOT NULL 
       AND A.DJZXBM  IS NOT NULL 

       --  AND SUBSTR(A.PRODUCT_END_DATE,1,4)=SUBSTR(I_DATE,1,4)
       AND NOT EXISTS (SELECT 1 FROM YBT_DATACORE.T_5_1 B WHERE B.E010001 = A.PRODUCT_CODE AND B.DIS_DATA_DATE = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'))
       -- [20250519][巴启威]:L层理财产品表中包含代理代销产品，代理代销产品已经在上边逻辑中加工，此处需要剔除
       UNION ALL 
 
 SELECT 
     '60211401'          AS       E010001,  -- 01.产品ID
     'B0302H22201009816' AS       E010002,  -- 02.机构ID
     '个人理财业务收入'   AS       E010003,  -- 03.产品名称
     '60211401'          AS       E010004,  -- 04.产品编号
     '06'                AS       E010005,  -- 05.科目类型
     '3201'              AS       E010007,  -- 07.产品类别
     '01'                AS       E010008,  -- 08.自营标识
     'CNY'               AS       E010009,  -- 09.产品币种
     '27758'             AS       E010010,  -- 10.产品期限
     '2024-01-01'        AS       E010011,  -- 11.产品成立日期
     '2099-12-31'        AS       E010012,  -- 12.产品到期日期
     '1'                 AS       E010013,  -- 13.产品期次
     '02'                AS       E010014,  -- 14.利率类型
     '01'                AS       E010015,  -- 15.产品状态代码
     NULL                AS       E010018,  -- 16.代客产品所属机构名称
     '理财产品'           AS       E010016,  -- 17.备注
     TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')       AS       E010017,   -- 18.采集日期
     TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')       AS       DIS_DATA_DATE,
     '009816'            AS       DIS_BANK_ID ,   -- 机构号          
     '009816'            AS       DEPARTMENT_ID       -- 业务条线
     FROM DUAL ; 
   
   /*
   SELECT
       A.PRODUCT_CODE                 ,  -- 01.产品ID
       ORG.ORG_ID                     ,  -- 02.机构ID
       A.PROD_NAME                    ,  -- 03.产品名称
       A.PRODUCT_CODE                             ,  -- 04.产品编号
       '01'                             ,  -- 05.科目类型
       ''                             ,  -- 07.产品类别
       CASE WHEN A.BANK_ISSUE_FLG = 'Y' THEN '01'
    	    ELSE '02'
			 END                      ,  -- 08.自营标识
       A.COLLECT_CURR_CD                  ,  -- 09.产品币种
       DATEDIFF(A.PRODUCT_END_DATE,A.ST_INT_DT)                    ,  -- 10.产品期限
       TO_CHAR(TO_DATE(A.ST_INT_DT,'YYYYMMDD'),'YYYY-MM-DD')       ,  -- 11.产品成立日期
       TO_CHAR(TO_DATE(A.PRODUCT_END_DATE,'YYYYMMDD'),'YYYY-MM-DD')          ,  -- 12.产品到期日期
       null                  ,  -- 13.产品期次
       ''                  ,  -- 14.利率类型
       '01'                ,  -- 15.产品状态代码
       ''                  ,  -- 16.代客产品所属机构名称
       '理财产品'                      ,  -- 17.备注
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),   -- 17.采集日期
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
       A.ORG_NUM,                                                   --  '机构号'
		 '0098SJ'                                                          -- 业务条线  默认数据管理部
       FROM SMTMODS.L_FIMM_PRODUCT A
       LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
              ON A.ORG_NUM = ORG.ORG_NUM
             AND ORG.DATA_DATE = I_DATE
       WHERE A.DATA_DATE = I_DATE
       AND A.PROD_NAME IS NOT NULL 
       AND NOT EXISTS (SELECT 1 FROM ybt_datacore.T_5_1 B WHERE B.E010001 = A.PRODUCT_CODE AND B.DIS_DATA_DATE = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'))
   ;
   */
  
    COMMIT;
    
	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	 
	
      
      		  #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '债券发行产品数据插入';
	
 INSERT  INTO ybt_datacore.T_5_1  (
     E010001,  -- 01.产品ID
     E010002,  -- 02.机构ID
     E010003,  -- 03.产品名称
     E010004,  -- 04.产品编号
     E010005,  -- 05.科目类型
     E010007,  -- 07.产品类别
     E010008,  -- 08.自营标识
     E010009,  -- 09.产品币种
     E010010,  -- 10.产品期限
     E010011,  -- 11.产品成立日期
     E010012,  -- 12.产品到期日期
     E010013,  -- 13.产品期次
     E010014,  -- 14.利率类型
     E010015,  -- 15.产品状态代码
     E010018,  -- 16.代客产品所属机构名称
     E010016,  -- 17.备注
     E010017,   -- 18.采集日期
     DIS_DATA_DATE,
     DIS_BANK_ID ,   -- 机构号
     DEPARTMENT_ID       -- 业务条线
   ) 
  -- 20250520 吴大为老师邮寄通知修改 债券发行部分取数规则将兑付日期与到期日写为固定日期修改产品号与产品名称取值将产品唯一 修改人姜俐锋 
  SELECT DISTINCT 
       T.SUBJECT_CD                   ,  -- 01.产品ID -- '2120113' 
       ORG.ORG_ID                     ,  -- 02.机构ID
       A.CPMC                         ,  -- 03.产品名称 -- '21吉林银行二级'
       T.SUBJECT_CD                   ,  -- 04.产品编号  -- '2120113' 
       '01'                           ,  -- 05.科目类型 
       '2801'                         ,  -- 07.产品类别 发行债券
       '01'                           ,  -- 08.自营标识 自营产品
       T.CURR_CD                      ,  -- 09.产品币种
       DATEDIFF(T.MATURITY_DATE,T.INT_ST_DT) as cpqx,  -- 10.产品期限
       '2021-12-10'                   ,  -- 11.产品成立日期  T.INT_ST_DT
       '9999-12-31'                   ,  -- 12.产品到期日期 T.MATURITY_DATE
       NULL                           ,  -- 13.产品期次
       NULL       			          ,  -- 14.利率类型
       '01'                           ,  -- 15.产品状态代码
        NULL                          ,  -- 16.代客产品所属机构名称
       '债券产品'                     ,  -- 17.备注
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),   -- 17.采集日期
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
       T.ORG_NUM                      ,   --  '机构号'
	  '009804'    -- 金融市场部
       FROM SMTMODS.L_ACCT_FUND_BOND_ISSUE T
       LEFT JOIN  SMTMODS.L_BASIC_PRODUCT A
         ON T.SUBJECT_CD=A.CP_ID
        AND A.DATA_DATE= I_DATE
       LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
              ON T.ORG_NUM = ORG.ORG_NUM
             AND ORG.DATA_DATE = I_DATE
       WHERE T.DATA_DATE = I_DATE
         AND T.GL_ITEM_CODE = '25020101'
		 -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
         AND (T.FACE_VAL > 0 or (T.FACE_VAL = 0 and T.MATURITY_DATE >= SUBSTR(I_DATE,1,4)||'0101')) -- 有票面金额或当天结清
      ;
      COMMIT;
      
      CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
      
	  #4.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '财管接数插入';
   
     INSERT  INTO ybt_datacore.T_5_1  (
     E010001,  -- 01.产品ID
     E010002,  -- 02.机构ID
     E010003,  -- 03.产品名称
     E010004,  -- 04.产品编号
     E010005,  -- 05.科目类型
     E010007,  -- 07.产品类别
     E010008,  -- 08.自营标识
     E010009,  -- 09.产品币种
     E010010,  -- 10.产品期限
     E010011,  -- 11.产品成立日期
     E010012,  -- 12.产品到期日期
     E010013,  -- 13.产品期次
     E010014,  -- 14.利率类型
     E010015,  -- 15.产品状态代码
     E010018,  -- 16.代客产品所属机构名称
     E010016,  -- 17.备注
     E010017,   -- 18.采集日期
     DIS_DATA_DATE,
     DIS_BANK_ID ,   -- 机构号
     DEPARTMENT_ID       -- 业务条线
   ) 
    select 
       E010001,  -- 01.产品ID
     E010002,  -- 02.机构ID
     E010003,  -- 03.产品名称
     E010004,  -- 04.产品编号
     E010005,  -- 05.科目类型
     E010007,  -- 07.产品类别
     E010008,  -- 08.自营标识
     E010009,  -- 09.产品币种
     E010010,  -- 10.产品期限
     E010011,  -- 11.产品成立日期
     E010012,  -- 12.产品到期日期
     E010013,  -- 13.产品期次
     E010014,  -- 14.利率类型
     E010015,  -- 15.产品状态代码
     E010018,  -- 16.代客产品所属机构名称
     '财管产品',  -- 17.备注
     E010017,   -- 18.采集日期
     TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), 
     '990000' ,   -- 机构号
     CASE WHEN  ywxt = '总行机关战略投资管理部' THEN  '0098ZT'
	      WHEN  ywxt = '总行机关运营管理部' THEN  '009801'
     END         -- 业务条线
     from smtmods.RSF_GQ_PRODUCT_BUSINESS t where  t.DATA_DATE=I_DATE;
 COMMIT;
    
  CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	 
  
	  #4.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = 'RPA接数插入';
   
-- RPA 债转股
 INSERT INTO YBT_DATACORE.T_5_1  (
     E010001,  -- 01.产品ID
     E010002,  -- 02.机构ID
     E010003,  -- 03.产品名称
     E010004,  -- 04.产品编号
     E010005,  -- 05.科目类型
     E010007,  -- 07.产品类别
     E010008,  -- 08.自营标识
     E010009,  -- 09.产品币种
     E010010,  -- 10.产品期限
     E010011,  -- 11.产品成立日期
     E010012,  -- 12.产品到期日期
     E010013,  -- 13.产品期次
     E010014,  -- 14.利率类型
     E010015,  -- 15.产品状态代码
     E010018,  -- 16.代客产品所属机构名称
     E010016,  -- 17.备注
     E010017,   -- 18.采集日期
     DIS_DATA_DATE,
     DIS_BANK_ID ,   -- 机构号
     DEPARTMENT_ID       -- 业务条线
   )  
 
SELECT 
     E010001,  -- 01.产品ID
     E010002,  -- 02.机构ID
     E010003,  -- 03.产品名称
     E010004,  -- 04.产品编号
     SUBSTR ( E010005,INSTR(E010005,'[',1,1) + 1 , INSTR(E010005, ']',1 ) -INSTR(E010005,'[',1,1) - 1 ) AS E010005,  -- 05.科目类型 
     SUBSTR ( E010007,INSTR(E010007,'[',1,1) + 1 , INSTR(E010007, ']',1 ) -INSTR(E010007,'[',1,1) - 1 ) AS E010007,  -- 07.产品类别
     SUBSTR ( E010008,INSTR(E010008,'[',1,1) + 1 , INSTR(E010008, ']',1 ) -INSTR(E010008,'[',1,1) - 1 ) AS E010008,  -- 08.自营标识
     SUBSTR ( E010009,INSTR(E010009,'[',1,1) + 1 , INSTR(E010009, ']',1 ) -INSTR(E010009,'[',1,1) - 1 ) AS E010009,  -- 09.产品币种
     E010010,  -- 10.产品期限
     E010011,  -- 11.产品成立日期
     E010012,  -- 12.产品到期日期
     E010013,  -- 13.产品期次
     E010014,  -- 14.利率类型
     SUBSTR ( E010015,INSTR(E010015,'[',1,1) + 1 , INSTR(E010015, ']',1 ) -INSTR(E010015,'[',1,1) - 1 ) AS E010015,  -- 15.产品状态代码
     E010018,  -- 16.代客产品所属机构名称
     E010016,  -- 17.备注
     TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,   -- 18.采集日期
     TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,
     '990000' ,   -- 机构号
     SUBSTR ( DEPARTMENT_ID,INSTR(DEPARTMENT_ID,'[',1,1) + 1 , INSTR(DEPARTMENT_ID, ']',1 ) -INSTR(DEPARTMENT_ID,'[',1,1) - 1 ) AS DEPARTMENT_ID       -- 业务条线
     FROM ybt_datacore.RPAJ_5_1_CPYW A
     WHERE DATA_DATE =I_DATE;
     COMMIT;
    
  CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
  
   -- 投管
  INSERT INTO YBT_DATACORE.T_5_1  (
     E010001,  -- 01.产品ID
     E010002,  -- 02.机构ID
     E010003,  -- 03.产品名称
     E010004,  -- 04.产品编号
     E010005,  -- 05.科目类型
     E010007,  -- 07.产品类别
     E010008,  -- 08.自营标识
     E010009,  -- 09.产品币种
     E010010,  -- 10.产品期限
     E010011,  -- 11.产品成立日期
     E010012,  -- 12.产品到期日期
     E010013,  -- 13.产品期次
     E010014,  -- 14.利率类型
     E010015,  -- 15.产品状态代码
     E010018,  -- 16.代客产品所属机构名称
     E010016,  -- 17.备注
     E010017,   -- 18.采集日期
     DIS_DATA_DATE,
     DIS_BANK_ID ,   -- 机构号
     DEPARTMENT_ID       -- 业务条线
   )  
     

SELECT 
  E010001  , -- 产品ID', 
  E010002  , -- 机构ID',
  E010003  , -- 产品名称',
  E010004  , -- 产品编号',
  SUBSTR ( E010005,INSTR(E010005,'[',1,1) + 1 , INSTR(E010005, ']',1 ) -INSTR(E010005,'[',1,1) - 1 ) AS E010005 , -- 科目类型',
  SUBSTR ( E010007,INSTR(E010007,'[',1,1) + 1 , INSTR(E010007, ']',1 ) -INSTR(E010007,'[',1,1) - 1 ) AS E010007  , -- 产品类别',
  SUBSTR ( E010008,INSTR(E010008,'[',1,1) + 1 , INSTR(E010008, ']',1 ) -INSTR(E010008,'[',1,1) - 1 ) AS E010008  , -- 自营标识',
  SUBSTR ( E010009,INSTR(E010009,'[',1,1) + 1 , INSTR(E010009, ']',1 ) -INSTR(E010009,'[',1,1) - 1 ) AS E010009  , -- 产品币种',
  E010010  , -- 产品期限',
  E010011  , -- 产品成立日期',
  E010012  , -- 产品到期日期',
  E010013  , -- 产品期次',
  E010014  , -- 利率类型',
  SUBSTR ( E010015,INSTR(E010015,'[',1,1) + 1 , INSTR(E010015, ']',1 ) -INSTR(E010015,'[',1,1) - 1 ) AS E010015  , -- 产品状态代码',
  E010018  , -- 代客产品所属机构名称',
  E010016  , -- 备注', 
  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
  '009806',
  SUBSTR ( E010006,INSTR(E010006,'[',1,1) + 1 , INSTR(E010006, ']',1 ) -INSTR(E010006,'[',1,1) - 1 ) AS E010006 
 FROM ybt_datacore.INTM_CPYWJBXX  
  WHERE DATA_DATE = I_DATE;
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


