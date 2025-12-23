CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_l_cust_c_tmp(II_DATADATE IN STRING --跑批日期
                                             
)
/******************************
  @author:xiangxu
  @create-date:2015-09-19
  @description:对公客户信息处理（全量客户信息+对公补充信息）
  @modification history:
  m0.author-create_date-description
  源表：L_CUST_ALL
    L_CUST_C
  
目标表：CBRC_L_CUST_C_TMP
  *******************************/
 IS
  V_SCHEMA    STRING; --当前存储过程所属的模式名
  V_SYSTEM    STRING; --系统名
  V_PROCEDURE  STRING; --当前储存过程名称
  V_TAB_NAME  STRING; --目标表名
  I_DATADATE  STRING; --数据日期(数值型)YYYYMMDD
  V_DATADATE  STRING; --数据日期(字符型)YYYY-MM-DD
  V_STEP_ID   INTEGER; --任务号
  V_STEP_DESC STRING; --任务描述
  V_STEP_FLAG STRING; --任务执行状态标识
  V_ERRORCODE     STRING; --错误编码
  V_ERRORDESC     STRING; --错误内容
  II_STATUS    INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
BEGIN
  IF II_STATUS=0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';
    I_DATADATE := II_DATADATE;
    V_SYSTEM  := 'CBRC';
    V_SCHEMA   := 'USER';
    V_PROCEDURE := UPPER('PROC_CBRC_L_CUST_C_TMP');
    
    sp_rsbp_etl_log(V_SYSTEM,V_PROCEDURE, V_STEP_ID,  V_ERRORCODE,  V_STEP_DESC,  II_DATADATE);

    V_TAB_NAME := 'CBRC_L_CUST_C_TMP';
  
  
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']表历史数据';
    sp_rsbp_etl_log(V_SYSTEM,V_PROCEDURE, V_STEP_ID,  V_ERRORCODE,  V_STEP_DESC,  II_DATADATE);
    
    
    EXECUTE IMMEDIATE 'TRUNCATE TABLE pm_rsdata.CBRC_L_CUST_C_TMP' ;
    COMMIT;
    
    

  
    V_STEP_ID   := 2;
    V_STEP_DESC := '对公客户临时表处理(全量客户信息+对公补充信息)';
    V_STEP_FLAG := 0;
    sp_rsbp_etl_log(V_SYSTEM,V_PROCEDURE, V_STEP_ID,  V_ERRORCODE,  V_STEP_DESC,  II_DATADATE);


  
    INSERT 
    INTO PM_RSDATA.CBRC_L_CUST_C_TMP 
      (CUST_ID, --客户号
       CUST_NAM, --客户中文名称
       CUST_NAM_EN, --客户英文名称
       FINA_CODE, --金融机构类型代码
       CUST_TYPE, --客户大类
       CUST_TYP, --客户分类
       INLANDORRSHORE_FLG, --境内境外标志
       RESIDENT_FLG, --居民标志
       CORP_SCALE, --企业规模
       CORP_BUSINSESS_TYPE, --行业类别
       FINA_ORG_NUM_LEGAL, --法人金融机构代码
       FINA_ORG_NAME_LEGAL, --法人金融机构名称
       ORG_NUM, --机构号
       CUS_RISK_LEV, --客户风险评级分类
       CITY_VILLAGE_FLG, --农村城市标志
       SMALL_COR_FLG, --小企业客户标志
       INTERBANK_TYPE, --系统往来方类型
       IS_GROUP_ORG, --是否集团内机构
       CUS_MT_FLG, --母行标志
       CNCAPITAL_FLG, --中资标志
       CORP_HOLD_TYPE, --控股类型代码
       REGION_CD, --客户所属地区
       ID_NO, --证件号码
       LOAN_CARD_NO, --贷款卡编码
       ID_TYPE, --证件类型
       BUSINESS_RELA_TYP, --业务关系类型
       DATA_DATE, --数据日期
       CUS_RISK_LEV_EXT, --外部评级
       CUS_RISK_LV_DE, --信用评级结果
       CBRC_CODE, --银监会非现场监管统计机构编码
       NATION_CD, --国籍或注册地国家代码
       BUSSINES_TYPE, --企业经济类型
       SPECIAL_TYP, --特殊经济区类型
       BORROWER_BULID_YEAR, --成立日期
       BORROWER_PRODUCT_DESC, --经营（业务）范围
       CAPITAL_CURRENCY, --注册资金币种
       CAPITAL_AMT, --注册资金
       ORGANIZATION_TYPE, --组织机构类型细分
       CUST_STS --客户状态
       )
      SELECT T.CUST_ID, --客户号
             T.CUST_NAM, --客户中文名称
             T.CUST_NAM_EN, --客户英文名称
             C.FINA_CODE, --金融机构类型代码
             T.CUST_TYPE, --客户大类
             C.CUST_TYP, --客户分类
             T.INLANDORRSHORE_FLG, --境内境外标志
             T.RESIDENT_FLG, --居民标志
             C.CORP_SCALE, --企业规模
             C.CORP_BUSINSESS_TYPE, --行业类别
             C.FINA_ORG_NUM_LEGAL, --法人金融机构代码
             C.FINA_ORG_NAME_LEGAL, --法人金融机构名称
             T.ORG_NUM, --机构号
             C.CUS_RISK_LEV, --客户风险评级分类
             C.CITY_VILLAGE_FLG, --农村城市标志
             C.SMALL_COR_FLG, --小企业客户标志
             C.INTERBANK_TYPE, --系统往来方类型
             C.IS_GROUP_ORG, --是否集团内机构
             C.CUS_MT_FLG, --母行标志
             C.CNCAPITAL_FLG     AS CNCAPITAL_FLG, --中资标志
             C.CORP_HOLD_TYPE    AS CORP_HOLD_TYPE, --控股类型代码
             T.REGION_CD         AS REGION_CD, --客户所属地区
             T.ID_NO             AS ID_NO, --证件号码
             C.LOAN_CARD_NO      AS LOAN_CARD_NO, --贷款卡编码
             T.ID_TYPE           AS ID_TYPE, --证件类型
             T.BUSINESS_RELA_TYP, --业务关系类型
             T.DATA_DATE, --数据日期
             C.CUS_RISK_LEV_EXT, --外部评级
             C.CUS_RISK_LV_DE, --信用评级结果
             C.CBRC_CODE, --银监会非现场监管统计机构编码
             T.NATION_CD, --国籍或注册地国家代码
             C.BUSSINES_TYPE, --企业经济类型
             C.SPECIAL_TYP, --特殊经济区类型
             C.BORROWER_BULID_YEAR, --成立日期
             C.BORROWER_PRODUCT_DESC, --经营（业务）范围
             C.CAPITAL_CURRENCY, --注册资金币种
             C.CAPITAL_AMT, --注册资金
             C.ORGANIZATION_TYPE2, --组织机构类型细分
             T.CUST_STS --客户状态
        FROM PM_RSDATA.SMTMODS_L_CUST_ALL T
       INNER JOIN PM_RSDATA.SMTMODS_L_CUST_C C
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE;
     COMMIT;



   V_STEP_DESC := V_PROCEDURE || '的业务逻辑全部处理完成';
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
   
END proc_cbrc_l_cust_c_tmp