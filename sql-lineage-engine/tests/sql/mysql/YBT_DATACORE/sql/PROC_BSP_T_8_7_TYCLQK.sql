DROP Procedure IF EXISTS `PROC_BSP_T_8_7_TYCLQK` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_8_7_TYCLQK"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN

  /******
      程序名称  ：同业存量情况
      程序功能  ：加工同业存量情况
      目标表：T_8_7
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
		-- JLBA202409120001_关于一表通监管数据报送系统修改逻辑的需求_二期 20241128 jlf
        -- JLBA202412200001_关于一表通监管数据报送系统修改逻辑及转EAST脚本的需求_20250116
        -- JLBA202505280002 上线日期：2025-06-19，修改人：巴启威  提出人：吴大为  修改原因：因一表通校验问题发现的代码逻辑调整
		 /*需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
  #声明变量
  DECLARE P_DATE   		DATE;			#数据日期
  DECLARE A_DATE   		VARCHAR(10);    #数据日期
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
	SET A_DATE = SUBSTR(I_DATE,1,4) || '-' || SUBSTR(I_DATE,5,2) || '-' || SUBSTR(I_DATE,7,2);		
	SET BEG_MON_DT = SUBSTR(I_DATE,1,6) || '01';	
	SET BEG_QUAR_DT = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY') || TRIM(TO_CHAR(QUARTER(TO_DATE(I_DATE,'YYYYMMDD')) * 3 - 2,'00')) || '01'; 
	SET BEG_YEAR_DT = SUBSTR(I_DATE,1,4) || '0101';	
    SET LAST_MON_DT = TO_CHAR(TO_DATE(BEG_MON_DT,'YYYYMMDD') - 1,'YYYYMMDD');	
    SET LAST_QUAR_DT = TO_CHAR(TO_DATE(BEG_QUAR_DT,'YYYYMMDD') - 1,'YYYYMMDD');	
    SET LAST_YEAR_DT = TO_CHAR(TO_DATE(BEG_YEAR_DT,'YYYYMMDD') - 1,'YYYYMMDD');	
	SET LAST_DT = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD') - 1,'YYYYMMDD'); 			
	SET P_PROC_NAME = 'PROC_BSP_T_8_7_TYCLQK';
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
	
	DELETE FROM T_8_7 WHERE H070017 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ;											
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '插入回购信息表';
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	
	
-- 回购信息表	
 INSERT INTO T_8_7
 (
   H070001    , -- 01 '同业业务ID'
   H070002    , -- 02 '交易机构ID'
   H070003    , -- 03 '协议ID'
   H070004    , -- 04 '同业业务种类'
   H070005    , -- 05 '科目ID'
   H070006    , -- 06 '科目名称'
   H070007    , -- 07 '账户类型'
   H070008    , -- 08 '合同金额'
   H070009    , -- 09 '合同余额'
   H070010    , -- 10 '币种'
   H070011    , -- 11 '合同起始日期'
   H070012    , -- 12 '合同终止日期'
   H070013    , -- 13 '合同执行利率'
   H070014    , -- 14 '业务目的'
   H070015    , -- 15 '担保协议ID'
   H070016    , -- 16 '投资标的ID'
   H070018    , -- 18 '本期投资收益'
   H070019    , -- 19 '累计投资收益'
   H070020    , -- 20 '自营业务大类'
   H070021    , -- 21 '自营业务小类'
   H070022    , -- 22 '分户账号'
   H070023    , -- 23 '钞汇类别'
   H070024    , -- 24 '上次动户日期'
   H070017    , -- 17 '采集日期'
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID   , -- 机构号
   DIS_DEPT      ,
   DEPARTMENT_ID , -- 业务条线
   H070025        -- 交易对手ID
 
 )
          SELECT 
                T.ACCT_NUM || T.REF_NUM         , -- 01 '同业业务ID'
                ORG.ORG_ID                      , -- 02 '交易机构ID'
                T.ACCT_NUM                      , -- 03 '协议ID'
                CASE 
                  WHEN T.BUSI_TYPE='102' THEN '01'  -- 买断式买入返售
                  WHEN T.BUSI_TYPE='101' THEN '02'  -- 质押式买入返售
                  WHEN T.BUSI_TYPE='202' THEN '03'  -- 买断式卖出回购
                  WHEN T.BUSI_TYPE='201' THEN '04'  -- 质押式卖出回购
                  else '00' 
                END                             , -- 04 '同业业务种类'
                T.GL_ITEM_CODE                  , -- 05 '科目ID'
                B.GL_CD_NAME                    , -- 06 '科目名称'
                case 
                  when T.BOOK_TYPE = '2' -- 2-银行账户
                 then '01'   -- 01-银行账户
                  when T.BOOK_TYPE = '1' -- 1-交易账户
                 then '02'   -- 02-交易账户
                end                             , -- 07 '账户类型'
                T.BALANCE                       , -- 08 '合同金额'
                T.BALANCE                       , -- 09 '合同余额'
                T.CURR_CD                       , -- 10 '币种'
                TO_CHAR(TO_DATE(T.BEG_DT,'YYYYMMDD'),'YYYY-MM-DD') , -- 11 '合同起始日期'
                TO_CHAR(TO_DATE(NVL(T.END_DT,'99991231'),'YYYYMMDD'),'YYYY-MM-DD') , -- 12 '合同终止日期'
                T.REAL_INT_RAT                  , -- 13 '合同执行利率'
                -- case when T.CURR_CD <> 'CNY' then '01' else  T.YWMD  end , -- 14 '业务目的'
                T.YWMD							, -- 14 '业务目的' -- 20240614 修改
                NULL                            , -- 15 '担保协议ID' -- 默认为空
                -- NVL(T.ACCT_NUM , T.SUBJECT_CD ) , -- 16 '投资标的ID'
               --  T.ACCT_NUM                      , -- 16 '投资标的ID'
                T.DEAL_ACCT_NUM                 , -- 16 '投资标的ID'
                T.BQTZSY                        , -- 18 '本期投资收益'
                T.TOTAL_INCOME                  , -- 19 '累计投资收益' 没到期没有累计收益？
                CASE WHEN T.BUSI_TYPE LIKE '1%' THEN  '01' -- 买入返售
                     WHEN T.BUSI_TYPE LIKE '2%' THEN  '02' -- 卖出回购
                     END              , -- 20 '自营业务大类'
                /*CASE 
                 WHEN  T.BUSI_TYPE LIKE '1%' AND  T.ASS_TYPE = '1' THEN  '0101' -- 买入返售证券 
                 -- WHEN  THEN  '0102' -- 买入返售债权 
                 -- WHEN THEN  '0103' -- 买入返售信贷资产 
                 WHEN  T.BUSI_TYPE LIKE '1%' AND  T.ASS_TYPE <> '1' THEN '0104' -- 其他买入返售 
                 WHEN  T.BUSI_TYPE LIKE '2%' AND  T.ASS_TYPE = '1' THEN  '0201' -- 卖出回购证券 
                 -- WHEN THEN  '0202' -- 卖出回购债权 
                 -- WHEN THEN '0203' -- 卖出回购信贷资产 
                 WHEN  T.BUSI_TYPE LIKE '2%' AND  T.ASS_TYPE <> '1' THEN '0204' -- 其他卖出回购  
                END                   , -- 21 '自营业务小类'*/
				CASE WHEN t.GL_ITEM_CODE = '111101' AND t.ASS_TYPE = '1' THEN '01010'
		     		 WHEN t.GL_ITEM_CODE = '111101' AND  t.ASS_TYPE <> '1' THEN '01040'
		 			 WHEN t.GL_ITEM_CODE = '211101' AND   t.ASS_TYPE = '1' THEN '02010'
		 			 WHEN t.GL_ITEM_CODE  = '211101' AND  t.ASS_TYPE <> '1' THEN '02040'
		 			 ELSE 	t1.gb_code
				end			  		  , -- 21 '自营业务小类' 
                T.ACCT_NUM            , -- 22 '分户账号'
                NULL                  , -- 23 '钞汇类别' -- 默认空值
                /*CASE WHEN SUBSTR(T.GL_ITEM_CODE,1,4) IN ('1302','2003') THEN NULL ELSE -- 同业金融部陈聪
                NVL(TO_CHAR(TO_DATE(A.TRAN_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') END , -- 24 '上次动户日期'*/
                NULL                  , -- 24 '上次动户日期' -- 发文：除同业存放外，其他业务类型可为空
                TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 17 '采集日期'
                TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
                T.ORG_NUM                                       , -- 机构号
                '回购',
                case 
                  when T.ORG_NUM = '009804' then '009804' -- 金融市场部
                  when T.ORG_NUM = '009820'  then '009820' -- 同业金融部
                  when T.CURR_CD <> 'CNY' then '0098GJ' -- 国际业务（贸易金融）部
                  when SUBSTR(T.GL_ITEM_CODE,1,4) = '2004' then '0098PH' -- 普惠
                  when SUBSTR(T.GL_ITEM_CODE,1,4) IN ('1011','1031','2003','2012') then '009820' -- 同业金融部    
                end                                   , -- 业务条线
                T.CUST_ID                               -- 交易对手ID
           FROM SMTMODS.L_ACCT_FUND_REPURCHASE T -- 回购信息表
            /*LEFT join (select CONTRACT_NUM,TRAN_DT from (
                         select CONTRACT_NUM,TRAN_DT,row_number() OVER(partition by CONTRACT_NUM order by TRAN_DT DESC) RN 
                           from SMTMODS.L_TRAN_FUND_FX A\* WHERE A.DATA_DATE = I_DATE*\)A
                         where A.RN = 1)A
             ON A.CONTRACT_NUM = T.ACCT_NUM*/
            LEFT JOIN SMTMODS.L_FINA_INNER B
                 ON T.GL_ITEM_CODE = B.STAT_SUB_NUM
                 AND T.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATE
            LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
                 ON T.ORG_NUM = ORG.ORG_NUM
                 AND ORG.DATA_DATE = I_DATE
		    LEFT JOIN (SELECT * FROM   m_dict_codetable WHERE l_code_table_code = 'C0002' AND substr(L_CODE,1,6) NOT IN ('111101','211101') ) T1  -- 20240614修改
				 ON T.GL_ITEM_CODE = substr(T1.L_CODE,1,6)
				 AND T1.l_code_table_code = 'C0002'  -- 自营业务小类 
            WHERE T.DATA_DATE = I_DATE 
               AND SUBSTR(T.BUSI_TYPE,1,1) IN ('1','2') -- 1-买入返售 ;2-卖出回购
               AND T.ASS_TYPE IN ('1','2','3') -- 1-债券 2-商业汇票 3-其他票据-- 票据报到6_14票据再贴现里面 20240618因流动性指标 将票据放开
              -- AND T.END_DT >= I_DATE -- 未到期或到期当日
			  -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
               AND (((T.ACCT_CLDATE > I_DATE OR T.ACCT_CLDATE IS null) AND T.BALANCE > 0) or (T.ACCT_CLDATE >= SUBSTR(I_DATE,1,4)||'0101' and T.BALANCE = 0) or  ACCRUAL <> 0) -- 与4.3，7.6同步  alter by djh 20240719 有利息无本金数据也加进来
              and  t.END_DT >= SUBSTR(I_DATE,1,4)||'0101' -- 9.2tongbu 
              -- AND (T.ACCT_CLDATE >= I_DATE OR T.ACCT_CLDATE IS NULL) 
              --  and T.BALANCE >0
          ;
          
          
    #4.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '插入资金往来信息表';
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
	
-- 资金往来信息表 
INSERT INTO T_8_7
 (
   H070001    , -- 01 '同业业务ID'
   H070002    , -- 02 '交易机构ID'
   H070003    , -- 03 '协议ID'
   H070004    , -- 04 '同业业务种类'
   H070005    , -- 05 '科目ID'
   H070006    , -- 06 '科目名称'
   H070007    , -- 07 '账户类型'
   H070008    , -- 08 '合同金额'
   H070009    , -- 09 '合同余额'
   H070010    , -- 10 '币种'
   H070011    , -- 11 '合同起始日期'
   H070012    , -- 12 '合同终止日期'
   H070013    , -- 13 '合同执行利率'
   H070014    , -- 14 '业务目的'
   H070015    , -- 15 '担保协议ID'
   H070016    , -- 16 '投资标的ID'
   H070018    , -- 18 '本期投资收益'
   H070019    , -- 19 '累计投资收益'
   H070020    , -- 20 '自营业务大类'
   H070021    , -- 21 '自营业务小类'
   H070022    , -- 22 '分户账号'
   H070023    , -- 23 '钞汇类别'
   H070024    , -- 24 '上次动户日期'
   H070017    , -- 17 '采集日期'
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID   , -- 机构号
   DIS_DEPT      ,
   DEPARTMENT_ID , -- 业务条线
   H070025         -- 交易对手ID
 
 )

SELECT 
      T.ACCT_NUM || T.REF_NUM  , -- 01 '同业业务ID'
      ORG.ORG_ID               , -- 02 '交易机构ID'
      -- T.ACCT_NUM               , -- 03 '协议ID'
      CASE WHEN T1.ITEM_ID='20040101' THEN 'JLZX'|| I_DATE 
       ELSE T.ACCT_NUM
        END AS XYID, -- 03 '协议ID'   JLBA202406180016 支小再贷款 20241128 
      case 
           when substr(T.gl_item_code, '1', '4') = '2003' AND T.ACCT_TYP = '20201' THEN '06' -- 拆入
           when T.gl_item_code = '20030105' THEN '06'                                        -- 拆入
           when substr(T.gl_item_code, '1', '4') = '1302' AND T.ACCT_TYP = '10201' THEN '05' -- 拆出
           when T.gl_item_code in ('20030102','20030106','20030104','20030301') THEN '09'    -- 同业借入
           when substr(T.ACCT_TYP,1,3)  IN ('105','205') THEN '10'                           -- 同业借出
           when T.gl_item_code = '13020104' THEN '10'                                        -- 同业借出
           when substr(T.gl_item_code, '1', '4') IN ('1011','1031')  THEN '07'               -- 存放同业
           when substr(T.gl_item_code, '1', '4') = '2012' THEN '08'                          -- 同业存放
           when substr(T.gl_item_code, '1', '4') = '2004' THEN '00'                          -- 其他
           else '00' 
      end                    , -- 04 '同业业务种类'
      T.GL_ITEM_CODE           , -- 05 '科目ID'
      B.GL_CD_NAME           , -- 06 '科目名称'
      -- BOOK_TYP               , -- 07 '账户类型'
      '01'                   , -- 07 '账户类型'  -- 经同业金融部确认，默认为01-银行账户
      T.BALANCE                , -- 08 '合同金额'
      T.BALANCE                , -- 09 '合同余额'
      T.CURR_CD                , -- 10 '币种'
      TO_CHAR(TO_DATE(START_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 11 '合同起始日期'
      TO_CHAR(TO_DATE(NVL(MATURE_DATE,'99991231'),'YYYYMMDD'),'YYYY-MM-DD') , -- 12 '合同终止日期'
      T.REAL_INT_RAT           , -- 13 '合同执行利率'
      case when T.CURR_CD <> 'CNY'  then '01' else T.YWMD end            , -- 14 '业务目的'
      NULL                   , -- 15 '担保协议ID'  -- 经同业金融部确认，默认空值
      -- T.TZBD_ID              , -- 16 '投资标的ID'     -- 新增字段 --数据由业务补录
      T.ACCT_NUM             , -- 16 '投资标的ID'
      case when T1.ACCT_NUM is not null then 0 else nvl(T.BQTZSY,0) end  , -- 18 '本期投资收益'  -- 新增字段
      case when T1.ACCT_NUM is not null then 0 else nvl(T.LJTZSY,0) end  , -- 19 '累计投资收益'  -- 新增字段
      case 
           when substr(T.gl_item_code, '1', '4') = '2003' AND T.ACCT_TYP = '20201' THEN '03' -- 拆入
           when T.gl_item_code = '20030105' THEN '03'                                        -- 拆入
           when substr(T.gl_item_code, '1', '4') = '1302' AND T.ACCT_TYP = '10201' THEN '04' -- 拆出
           when substr(T.ACCT_TYP,1,3)  IN ('105','205') THEN '05'                           -- 同业借款
           when T.gl_item_code = '13020104' THEN '05'                                        -- 同业借款
           when T.gl_item_code in ('20030102','20030106','20030104','20030301') THEN '05'    -- 同业借款
           when substr(T.gl_item_code, '1', '4') IN ('1011','1031')  THEN '07'               -- 存放同业
           when substr(T.gl_item_code, '1', '4') = '2012' THEN '08'                          -- 同业存放
           when substr(T.gl_item_code, '1', '4') = '2004' THEN '11'                          -- 其他
      end                   , -- 20 '自营业务大类'
	  T2.GB_CODE	        , -- 21 '自营业务小类'
      T.ACCT_NUM            , -- 22 '分户账号'
      /*case 
        when CURR_CD ='CNY' then null 
      END                   , -- 23 '钞汇类别' -- 经同业金融部确认，人民币默认为空，外币待访谈国结*/
      T.CHLB                , -- 23 '钞汇类别'
      CASE WHEN SUBSTR(T.GL_ITEM_CODE,1,4) IN ('1302','2003') THEN NULL ELSE -- 同业金融部陈聪
      TO_CHAR(TO_DATE(T.LAST_TX_DATE,'YYYYMMDD'),'YYYY-MM-DD') END , -- 24 '上次动户日期'
      /*CASE WHEN SUBSTR(T.GL_ITEM_CODE,1,4) IN ('1302','2003') THEN NULL ELSE -- 同业金融部陈聪
      NVL(TO_CHAR(TO_DATE(A.TRAN_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') END  , -- 24 '上次动户日期'*/
      TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 17 '采集日期'
      TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
      T.ORG_NUM                                       , -- 机构号
      '资金往来',
      case 
        when T.ORG_NUM = '009804' then '009804' -- 金融市场部
        when T.ORG_NUM = '009820'  then '009820' -- 同业金融部
        when T.CURR_CD <> 'CNY' then '0098GJ' -- 国际业务（贸易金融）部
        when SUBSTR(T.GL_ITEM_CODE,1,4) = '2004' then '0098PH' -- 普惠
        when SUBSTR(T.GL_ITEM_CODE,1,4) IN ('1011','1031','2003','2012') then '009820' -- 同业金融部
      end                                             , -- 业务条线
      T.CUST_ID                                         -- 交易对手ID
 FROM SMTMODS.L_ACCT_FUND_MMFUND T  -- 资金往来信息表 
   /*LEFT join (select REF_NUM,TRAN_DT from (
                         select REF_NUM,TRAN_DT,row_number() OVER(partition by REF_NUM order by TRAN_DT DESC) RN 
                           from SMTMODS.L_TRAN_FUND_FX A\* WHERE A.DATA_DATE = I_DATE*\)A
                         where A.RN = 1)A
             ON A.REF_NUM = T.REF_NUM*/
   LEFT JOIN SMTMODS.L_FINA_INNER B
     ON T.GL_ITEM_CODE = B.STAT_SUB_NUM
     AND T.ORG_NUM = B.ORG_NUM
     AND B.DATA_DATE = I_DATE
   LEFT JOIN SMTMODS.L_ACCT_INNER T1  -- 内部分户账 
     ON t.acct_num=t1.acct_num 
     AND T1.ITEM_ID='20040101' -- 借入央行款项
     AND T1.ACCT_NAME='吉林银行股份有限公司支小再贷款' 
     AND T1.DATA_DATE = I_DATE 
   LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
        ON T.ORG_NUM = ORG.ORG_NUM
        AND ORG.DATA_DATE = I_DATE
	LEFT JOIN m_dict_codetable T2   -- 20240614 修改
		ON T.GL_ITEM_CODE = T2.L_CODE
		AND T2.l_code_table_code = 'C0002'  -- '自营业务小类'
 WHERE T.DATA_DATE = I_DATE 
   -- AND BALANCE > 0
   -- AND (LOAN_ACTUAL_DUE_DATE is null or LOAN_ACTUAL_DUE_DATE >= I_DATE) -- 未到期或到期当日
   -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
   AND (((T.ACCT_CLDATE > I_DATE OR T.ACCT_CLDATE IS null) AND T.BALANCE > 0) or (T.ACCT_CLDATE >= SUBSTR(I_DATE,1,4)||'0101' and T.BALANCE = 0) or T.ACCRUAL <> 0)  -- 与4.3，7.6同步 alter by djh 20240719 有利息无本金数据也加进来
   and (substr(T.gl_item_code, '1', '4') = '2003'-- 拆入
           or T.gl_item_code = '20030105'            -- 拆入
           or ( substr(T.gl_item_code, '1', '4') = '1302' AND T.ACCT_TYP = '10201')  -- 拆出
           or t.GL_ITEM_CODE in ('13020102','13020104','13020106','20030102','20030104','20030106')-- 同业借入  同业借出
           or t.GL_ITEM_CODE like '101101%'or t.GL_ITEM_CODE like '101102%' or t.GL_ITEM_CODE like '1031%' -- 存放同业活期和存放同业定期
           or substr(T.gl_item_code, '1', '4') = '2012'   -- 同业存放
           or t.GL_ITEM_CODE = '20040101' -- 向央行借款
           ) -- 同步9.2
   and t.MATURE_DATE >= SUBSTR(I_DATE,1,4)||'0101'   -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
   ;

   
   
-- 20241128 新增债券发行  JLBA202409120001
-- [20250619][巴启威][JLBA202505280002][吴大为]：债券发行放到8.9中报送
/*INSERT INTO T_8_7
 (
   H070001    , -- 01 '同业业务ID'
   H070002    , -- 02 '交易机构ID'
   H070003    , -- 03 '协议ID'
   H070004    , -- 04 '同业业务种类'
   H070005    , -- 05 '科目ID'
   H070006    , -- 06 '科目名称'
   H070007    , -- 07 '账户类型'
   H070008    , -- 08 '合同金额'
   H070009    , -- 09 '合同余额'
   H070010    , -- 10 '币种'
   H070011    , -- 11 '合同起始日期'
   H070012    , -- 12 '合同终止日期'
   H070013    , -- 13 '合同执行利率'
   H070014    , -- 14 '业务目的'
   H070015    , -- 15 '担保协议ID'
   H070016    , -- 16 '投资标的ID'
   H070018    , -- 18 '本期投资收益'
   H070019    , -- 19 '累计投资收益'
   H070020    , -- 20 '自营业务大类'
   H070021    , -- 21 '自营业务小类'
   H070022    , -- 22 '分户账号'
   H070023    , -- 23 '钞汇类别'
   H070024    , -- 24 '上次动户日期'
   H070017    , -- 17 '采集日期'
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID   , -- 机构号
   DIS_DEPT      ,
   DEPARTMENT_ID , -- 业务条线
   H070025         -- 交易对手ID
 ) 
SELECT 
 A.ACCT_NUM||A.REF_NUM  AS H070001, -- -- 01 '同业业务ID'
 ORG.ORG_ID             AS H070002, -- 02 '交易机构ID'
 A.ACCT_NUM             AS H070003, -- 03 '协议ID'
 '00'                   AS H070004, -- 04 '同业业务种类'
 A.GL_ITEM_CODE         AS H070005, -- 05 '科目ID'
 B.GL_CD_NAME           AS H070006, -- 06 '科目名称'
 '01'                   AS H070007, -- 07 '账户类型'
 A.FACE_VAL             AS H070008, -- 08 '合同金额'
 A.FACE_VAL             AS H070009, -- 08 '合同余额'
 A.CURR_CD              AS H070010, -- 10 '币种'
 TO_CHAR(TO_DATE(A.INT_ST_DT,'YYYYMMDD'),'YYYY-MM-DD') AS H070011, -- 11 '合同起始日期'
 NVL(TO_CHAR(TO_DATE(A.MATURITY_DATE,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') AS H070012, -- 12 '合同终止日期'
 4                      AS H070013, -- 13 '合同执行利率'
 '02'                   AS H070014, -- 14 '业务目的'-融资
 NULL                   AS H070015, -- 15 '担保协议ID'
 A.ACCT_NUM||A.REF_NUM  AS H070016, -- 16 '投资标的ID' 20250116
 NULL                   AS H070018, -- 18 '本期投资收益'
 NULL                   AS H070019, -- 19 '累计投资收益'
 '10'                   AS H070020, -- 20 '自营业务大类' -债券发行
 '10020'                AS H070021, -- 21 '自营业务小类' -银行次级债
 A.ACCT_NUM             AS H070022, -- 22 '分户账号'
 NULL                   AS H070023, -- 23 '钞汇类别'
 NULL                   AS H070024, -- 24 '上次动户日期'
 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS H070017, -- 17 '采集日期'
 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE , -- 装入数据日期
 A.ORG_NUM AS DIS_BANK_ID   , -- 机构号
 '债券发行'      ,
 '009806'               AS DEPARTMENT_ID , -- 业务条线
 A.CUST_ID              AS H070025     -- 交易对手ID
  FROM SMTMODS.L_ACCT_FUND_BOND_ISSUE A  -- 债券发行
  LEFT JOIN SMTMODS.L_FINA_INNER B
    ON A.GL_ITEM_CODE = B.STAT_SUB_NUM
   AND A.ORG_NUM = B.ORG_NUM
   AND B.DATA_DATE = I_DATE
  LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
    ON A.ORG_NUM = ORG.ORG_NUM
   AND ORG.DATA_DATE = I_DATE
 WHERE A.DATA_DATE = I_DATE
   AND SUBSTR(A.GL_ITEM_CODE, 1, 4) = '2502'
   AND A.FACE_VAL <> 0 ; */

    #6.过程结束执行
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '过程结束执行';
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    SET OI_RETCODE = P_STATUS; 
    SET OI_REMESSAGE = P_DESCB;
    select OI_RETCODE,'|',OI_REMESSAGE;
END $$


