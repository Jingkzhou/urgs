CREATE OR REPLACE PROCEDURE BSP_SP_IRS_TY_TYCKJC(IS_DATE    IN VARCHAR2,
                                                OI_RETCODE OUT INTEGER,
                                               OI_RETCODE2 OUT VARCHAR2) AS
  ------------------------------------------------------------------------------------------------------
  -- ������
  --    SP_IRS_FTY_FTYDWDKJCXXB
  -- ��;:���ɽӿڱ� JS_201_CLGRDK �������˴�����Ϣ
  -- ����
  --    IS_DATE ���������������������
  --    OI_RETCODE ���������������ʶ�洢����ִ�й������Ƿ�����쳣
  --    CAEATE BY USER AT 20200819
  --    MOD BY YANLINGBO AT 20200819
  --    add ҵ��¼���ڻ������ʹ���
  ------------------------------------------------------------------------------------------------------

  VI_ERRORCODE      NUMBER DEFAULT 0; --��ֵ��  �쳣����
  VS_TEXT           VARCHAR2(500) DEFAULT NULL; --�ַ���  ��������
  VS_LAST_TEXT      VARCHAR2(10) DEFAULT NULL; --�ַ���  ��������
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --�ַ���  �洢���̵����û�
  VS_PROCEDURE_NAME VARCHAR2(32) DEFAULT NULL; --�ַ���  �洢��������
  VS_STEP           VARCHAR2(10); --�洢����ִ�в����־
  NUM               INTEGER;
  VS_LAST_DAY       VARCHAR2(10) DEFAULT NULL;
BEGIN
  VS_TEXT := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD');
  VS_LAST_TEXT := TO_CHAR(ADD_MONTHS(TO_DATE(IS_DATE, 'YYYYMMDD'), -1),
                          'YYYYMMDD');
  VS_LAST_DAY  := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') - 1, 'YYYYMMDD');
  -- ��¼��־ʹ��
  SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
  VS_PROCEDURE_NAME := 'SP_IRS_TY_TYCKJC';
  -- ��ʼ��־
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
  -------------------------------------------------------------------------

EXECUTE IMMEDIATE'TRUNCATE TABLE CUST_TY_NEW';
EXECUTE IMMEDIATE'TRUNCATE TABLE L_CUST_BILL_TY_CKTMP';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE TX_JRJG_YESTERDAY';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE TX_JRJG_DIF';
/*INSERT INTO CUST_TY_NEW
SELECT *
  FROM (SELECT CUST_NAM,
               ID_NO,
               CUST_ID,
               ROW_NUMBER() OVER(PARTITION BY CUST_NAM, ID_NO ORDER BY CUST_ID) AS RN
          FROM SMTMODS.L_CUST_ALL A
         WHERE A.DATA_DATE = IS_DATE) A
 WHERE A.RN = '1';

COMMIT;*/
  -----ҵ��¼���ڽ��ڻ�������-----

  ---ǰһ���������ڵ�ͬҵ�ͻ��ͽ��ڻ������ʹ���

  INSERT INTO TX_JRJG_YESTERDAY
    SELECT DISTINCT CUST_NAM, ORGTPCODE
      FROM (SELECT A.ACCDEPCODE,
                   B.REF_NUM,
                   B.CUST_ID,
                   C.CUST_NAM   AS CUST_NAM,
                   A.ORGTPCODE  AS ORGTPCODE
              FROM IE_TY_TYCKJC_YD A
              LEFT JOIN SMTMODS.L_ACCT_FUND_MMFUND B
                ON A.ACCDEPCODE = B.REF_NUM
               AND B.DATA_DATE = VS_LAST_DAY
               AND SUBSTR(B.GL_ITEM_CODE, '1', '4') IN ('1011', '2012')
               AND (TO_CHAR(B.MATURE_DATE, 'YYYYMMDD') >= VS_LAST_DAY OR
                   B.MATURE_DATE IS NULL)
               AND B.CURR_CD IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD')
              LEFT JOIN SMTMODS.L_CUST_ALL C
                ON B.CUST_ID = C.CUST_ID
               AND C.DATA_DATE = VS_LAST_DAY
/*             WHERE A.CJRQ = VS_LAST_DAY);*/--20231030wxb
             WHERE A.CJRQ = VS_LAST_DAY
             AND A.ORGTPCODE IS NOT NULL);

  COMMIT;

  ---ǰһ�첹¼��ͬҵ�ͻ����ڻ������� ���½����ñ� ���������˱�����֤��¼���Ĳ����ظ���¼

  MERGE INTO DATACORE_TMP_TX_JRJG A
  USING TX_JRJG_YESTERDAY B
  ON (A.CUST_ID = B.CUST_NAM)
  WHEN MATCHED THEN
    UPDATE SET A.JRJG = B.ORGTPCODE
  WHEN NOT MATCHED THEN
    INSERT (A.CUST_ID, A.JRJG) VALUES (B.CUST_NAM, B.ORGTPCODE);
  COMMIT;

  -----��ʽ�߼�������ʼ-----

INSERT INTO CUST_TY_NEW
SELECT CUST_NAM, ID_NO, CUST_ID, '1'
  FROM SMTMODS.L_CUST_ALL A
 WHERE A.DATA_DATE = IS_DATE;

COMMIT;

--ͬҵ�ͻ�������Ϣ��ȥ��   add by chm 20230615
INSERT INTO L_CUST_BILL_TY_CKTMP
SELECT
  data_date              ,
  org_num               ,
  cust_id                ,
  legal_name             ,
  fina_org_code          ,
  fina_code_new          ,
  fina_org_name          ,
  capital_amt            ,
  borrower_register_addr ,
  tyshxydm               ,
  organizationcode       ,
  ecif_cust_id           ,
  legal_flag             ,
  legal_tyshxydm         ,
  cbrc_code              ,
  nation_cd              ,
  org_area               ,
  aswift_code            ,
  cust_bank_cd           ,
  corp_scale             ,
  corp_hold_type         ,
  bussines_type          ,
  fina_olic_num          ,
  cus_risk_lev           ,
  cust_short_name        ,
  rn

  FROM (SELECT A.data_date              ,
  A.org_num               ,
  A.cust_id                ,
  A.legal_name             ,
  A.fina_org_code          ,
  A.fina_code_new          ,
  A.fina_org_name          ,
  A.capital_amt            ,
  A.borrower_register_addr ,
  A.tyshxydm               ,
  A.organizationcode       ,
  A.ecif_cust_id           ,
  A.legal_flag             ,
  A.legal_tyshxydm         ,
  A.cbrc_code              ,
  A.nation_cd              ,
  A.org_area               ,
  A.aswift_code            ,
  A.cust_bank_cd           ,
  A.corp_scale             ,
  A.corp_hold_type         ,
  A.bussines_type          ,
  A.fina_olic_num          ,
  A.cus_risk_lev           ,
  A.cust_short_name        ,
  rn ROW_NUMBER() OVER(PARTITION BY A.FINA_ORG_NAME ORDER BY A.CUST_ID) RN
          FROM SMTMODS.L_CUST_BILL_TY A
         WHERE A.DATA_DATE = IS_DATE ) B
 WHERE B.RN = '1';

 COMMIT ;

EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_TY_TYCKJC ';
INSERT INTO  DATACORE_IE_TY_TYCKJC
    (datadate --��������
    ,
     corpid --�ڲ�������
    ,
     custid --�ͻ���
    ,
     orgtpcode --���ڻ������ʹ���
    ,
     accdepcode --����˻�����
    ,
     finadeptype --���ҵ������
    ,
     startdate --��ʼ����
    ,
     maturedate --��������
    ,
     deptermtype --�����������
    ,
     pricingtype --���ۻ�׼����
    ,
     ratetype --��������
    ,
     realrate --ʵ������
    ,
     baserate --��׼����
    ,
     floatfreq --���ʸ���Ƶ��
    ,
     cust_name --�ͻ�����    --20240909  �����ͻ������ֶΣ�����֮ǰ�Ŀͻ����ֶα��潻�׶��ֿͻ�����
     )

SELECT /*+ USE_HASH(T,A) PARALLEL(8)*/
VS_TEXT    --��������
    ,
     T.org_num --�ڲ�������
     /*,CASE WHEN T.CUST_ID = '6000884761' THEN '�������йɷ����޹�˾'
     WHEN T.CUST_ID = '8913394106' THEN '�������йɷ����޹�˾'
       ELSE NVL(A.CUST_NAM,T.CUST_ID) END  --�ͻ���*/,
     T.CUST_ID --�ͻ���     --20240909    NR���ӹ���Ҫ�ͻ��ţ������ݽ�����ȡ����ǰ����ֶδ���ǽ��׶��ֿͻ�����
     --,t.CPTYS_SHORT_NAME  --�ͻ��ţ����׶��ֿͻ�����
    ,
     '' --���ڻ������ʹ���
    ,
    ref_num   --����˻�����
/*,CASE WHEN t.gl_item_code like '11401%' THEN 'A021'         --���ͬҵ���ڿ���
      WHEN t.gl_item_code like '11402%' THEN 'A022'         --���ͬҵ���ڿ���
      WHEN t.gl_item_code like '23401%' THEN 'A011'         --ͬҵ��Ż��ڿ���
      WHEN t.gl_item_code like '23402%' THEN 'A012'         --ͬҵ��Ŷ��ڿ���
      WHEN t.gl_item_code like '23403%' AND t.mature_date IS NOT NULL THEN 'A012'
      WHEN t.gl_item_code like '23403%' AND t.gl_item_code IS NULL THEN 'A011'
     ELSE NULL  END  --���ҵ������*/,
     CASE
       WHEN t.gl_item_code like '101101%' THEN
        'A021' --���ͬҵ���ڿ���
       WHEN t.gl_item_code like '101102%' THEN
        'A022' --���ͬҵ���ڿ���
       WHEN t.gl_item_code like '201201%' THEN
        'A011' --ͬҵ��Ż��ڿ���
       WHEN t.gl_item_code like '201202%' THEN
        'A012' --ͬҵ��Ŷ��ڿ���
       WHEN t.gl_item_code like '250202%' AND mature_date IS NOT NULL THEN
        'A012' --����ͬҵ�浥
       WHEN t.gl_item_code like '250202%' AND gl_item_code IS NULL THEN
        'A011'
       ELSE
        NULL
     END --���ҵ������
    ,
     TO_CHAR(t.start_date, 'YYYY-MM-DD') --��ʼ����
    ,
     CASE
       WHEN TO_CHAR(t.mature_date, 'YYYYMMDD') = '99991231' THEN
        ''
       ELSE
        TO_CHAR(t.mature_date, 'YYYY-MM-DD')
     END --��������
    ,
     CASE
       WHEN t.mature_date IS NULL THEN
        ''
       ELSE
        TO_CHAR(t.months_between(mature_date, start_date))
     END --�����������
    ,
     'TR99' --���ۻ�׼����
    ,
     'RF01' --��������
    ,
     t.real_int_rat --ʵ������
    ,
     '' --��׼����
    ,
     '' --���ʸ���Ƶ��

    ,NVL(A.CUST_NAM, T.CUST_ID) --�ͻ�����  20240909  �����ͻ������ֶΣ�����֮ǰ�Ŀͻ����ֶα��潻�׶��ֿͻ�����
FROM SMTMODS.L_ACCT_FUND_MMFUND  t
/*LEFT JOIN SMTMODS.L_TY_CUSTID_INFO f
ON T.CUST_ID=F.CUST_NM*/
LEFT JOIN CUST_TY_NEW A
ON (T.CUST_ID = A.CUST_ID OR T.CUST_ID = A.ID_NO)
WHERE T.DATA_DATE=IS_DATE
--AND substr(t.gl_item_code,'1','3') in ('114','234')
AND substr(t.gl_item_code,'1','4') in ('1011','2012')
/*AND (substr(t.gl_item_code,'1','4') in ('1011')   --���ͬҵ
     OR substr(t.gl_item_code,'1','6') in ('201202','201203'))--ͬҵ���*/
AND TO_CHAR(t.mature_date,'YYYYMMDD') >=IS_DATE  --modify by haorui 20241219 ɾ��OR mature_date IS NULL ������ʷ��Ч���ݣ�5����
AND T.CURR_CD IN ('CNY','USD','JPY','EUR','HKD')
--AND T.REF_NUM <> '41038441'
--AND T.ACCT_STS NOT LIKE 'D%'
--AND T.ORG_NUM NOT LIKE '0215%'
;
COMMIT;
/*
INSERT INTO  DATACORE_IE_TY_TYCKJC
    (datadate --��������
    ,
     corpid --�ڲ�������
    ,
     custid --�ͻ���
    ,
     orgtpcode --���ڻ������ʹ���
    ,
     accdepcode --����˻�����
    ,
     finadeptype --���ҵ������
    ,
     startdate --��ʼ����
    ,
     maturedate --��������
    ,
     deptermtype --�����������
    ,
     pricingtype --���ۻ�׼����
    ,
     ratetype --��������
    ,
     realrate --ʵ������
    ,
     baserate --��׼����
    ,
     floatfreq --���ʸ���Ƶ��
     )
    SELECT \*+ USE_HASH(T,A) PARALLEL(8)*\
     VS_TEXT --��������
    ,
     '510001' --�ڲ�������
    ,
     NVL(A.CUST_NAM, T.CUST_ID) --�ͻ���
     --,t.CPTYS_SHORT_NAME  --�ͻ��ţ����׶��ֿͻ�����
    ,
     'C07' --���ڻ������ʹ���
    ,
     ACCT_NUM --����˻�����
\*,CASE WHEN gl_item_code like '11401%' THEN 'A021'         --���ͬҵ���ڿ���
      WHEN gl_item_code like '11402%' THEN 'A022'         --���ͬҵ���ڿ���
      WHEN gl_item_code like '23401%' THEN 'A011'         --ͬҵ��Ż��ڿ���
      WHEN gl_item_code like '23402%' THEN 'A012'         --ͬҵ��Ŷ��ڿ���
      WHEN gl_item_code like '23403%' AND mature_date IS NOT NULL THEN 'A012'
      WHEN gl_item_code like '23403%' AND gl_item_code IS NULL THEN 'A011'
     ELSE NULL  END  --���ҵ������*\,
     CASE
       WHEN t.gl_item_code like '101101%' THEN
        'A011' --���ͬҵ���ڿ���
       WHEN t.gl_item_code like '101102%' THEN
        'A022' --���ͬҵ���ڿ���
       WHEN t.gl_item_code like '201201%' THEN
        'A021' --ͬҵ��Ż��ڿ���
       WHEN t.gl_item_code like '201202%' THEN
        'A022' --ͬҵ��Ŷ��ڿ���
       WHEN t.gl_item_code like '250202%' AND mature_date IS NOT NULL THEN
        'A022' --����ͬҵ�浥
       WHEN t.gl_item_code like '250202%' AND gl_item_code IS NULL THEN
        'A021'
       ELSE
        NULL
     END --���ҵ������
    ,
     TO_CHAR(t.start_date, 'YYYY-MM-DD') --��ʼ����
    ,
     CASE
       WHEN TO_CHAR(t.mature_date, 'YYYYMMDD') = '99991231' THEN
        ''
       ELSE
        TO_CHAR(t.mature_date, 'YYYY-MM-DD')
    END--��������
    ,
     CASE
       WHEN t.mature_date IS NULL OR
            TO_CHAR(T.MATURE_DATE, 'YYYYMMDD') = '99991231' THEN
        ''
       ELSE
        TO_CHAR(months_between(t.mature_date, start_date))
     END --�����������
    ,
     'TR99' --���ۻ�׼����
    ,
     'RF01' --��������
    ,
     t.real_int_rat --ʵ������
    ,
     '' --��׼����
    ,
     '' --���ʸ���Ƶ��
FROM SMTMODS.L_ACCT_FUND_MMFUND  t

LEFT JOIN CUST_TY_NEW A
ON (T.CUST_ID = A.CUST_ID OR T.CUST_ID = A.ID_NO)
WHERE T.DATA_DATE=IS_DATE
AND substr(gl_item_code,'1','4') in ('1011','2012')

AND (TO_CHAR(mature_date,'YYYYMMDD') >=IS_DATE OR
mature_date IS NULL )
AND T.CURR_CD IN ('CNY','USD','JPY','EUR','HKD')
\*AND T.ACCT_NUM IN('60599235000000437_1')*\
--20231109wxb��������ɾ��AND T.ACCT_NUM IN('60599235000000437_1')�������

;
COMMIT;*/--20231120wxb������߼����Գ���ʯ������

  ----��ǰ��������������ͬҵ���ҵ��Ŀͻ������ڻ������ʹ��� add by chm 20231012

  INSERT INTO TX_JRJG_DIF
    SELECT DISTINCT CUST_NAM, ORGTPCODE
      FROM (SELECT A.CUST_NAME AS CUST_NAM, --�ͻ���      --��֮ǰ��cust_idȡ���Լ���صĹ���������Ϊcust_name
                   NVL(NVL(B.JRJG, TRIM(C.FINA_CODE_NEW)), A.ORGTPCODE) AS ORGTPCODE, --���ڻ������ʹ���
                   a.ACCDEPCODE --����˻�����
              FROM DATACORE_IE_TY_TYCKJC A
              LEFT JOIN DATACORE_TMP_TX_JRJG B
                ON A.CUST_NAME = B.CUST_ID
              LEFT JOIN L_CUST_BILL_TY_CKTMP C
                ON A.CUST_NAME = C.FINA_ORG_NAME
             WHERE /*A.CORPID NOT LIKE '5100%'
               AND*/ A.DATADATE = VS_TEXT
               AND NOT EXISTS (SELECT 1
                      FROM L_CUST_BILL_TY_CKTMP B
                     WHERE A.CUST_NAME = B.FINA_ORG_NAME)
               AND NOT EXISTS (SELECT 1
                      FROM DATACORE_TMP_TX_JRJG B
                     WHERE A.CUST_NAME = B.CUST_ID))
    MINUS
    SELECT *
      FROM TX_JRJG_YESTERDAY;

  COMMIT;
 SP_IRS_PARTITIONS(IS_DATE,'IE_TY_TYCKJC',OI_RETCODE);

INSERT INTO  IE_TY_TYCKJC
    (datadate --��������
    ,
     corpid --�ڲ�������
    ,
     custid --�ͻ���
    ,
     orgtpcode --���ڻ������ʹ���
    ,
     accdepcode --����˻�����
    ,
     finadeptype --���ҵ������
    ,
     startdate --��ʼ����
    ,
     maturedate --��������
    ,
     deptermtype --�����������
    ,
     pricingtype --���ۻ�׼����
    ,
     ratetype --��������
    ,
     realrate --ʵ������
    ,
     baserate --��׼����
    ,
     floatfreq --���ʸ���Ƶ��
    ,
     cjrq --�ɼ�����
    ,
     nbjgh --�ڲ�������
    ,
     biz_line_id --ҵ������
    ,
     IRS_CORP_ID --���˻���ID
     )

   SELECT a.DATADATE --��������
          ,
           a.CORPID --�ڲ�������
          ,
           A.CUSTID --�ͻ���   add by chm 20231012 ҵ���ֶ���¼���ڻ������ʹ���   20240909    NR���ӹ���Ҫ�ͻ��ţ������ݽ�����ȡ����ǰ����ֶδ���ǽ��׶��ֿͻ�����
          ,
           CASE
             WHEN D.CUST_NAM IS NOT NULL THEN
              '��'
             ELSE
              NVL(NVL(B.JRJG, TRIM(C.FINA_CODE_NEW)), A.ORGTPCODE)
           END --���ڻ������ʹ��� MDF BY CHM 20231012
          ,
           a.ACCDEPCODE --����˻�����
          ,
           a.FINADEPTYPE --���ҵ������
          ,
           a.STARTDATE --��ʼ����
          ,
           a.MATUREDATE --��������
          ,
           CASE
             WHEN (a.DEPTERMTYPE = '' OR a.DEPTERMTYPE IS NULL OR FINADEPTYPE = 'A011' OR FINADEPTYPE = 'A021') THEN   -- ���ҵ������ΪA011��A021���ڴ��ʱ�������������Ϊ01���� mdf 20240220
              '01'
             WHEN a.DEPTERMTYPE < 1 THEN
              '02'
             WHEN a.DEPTERMTYPE = '1' THEN
              '03'
             WHEN a.DEPTERMTYPE < 3 THEN
              '04'
             WHEN a.DEPTERMTYPE = '3' THEN
              '05'
             WHEN a.DEPTERMTYPE < 6 THEN
              '06'
             WHEN a.DEPTERMTYPE = '6' THEN
              '07'
             WHEN a.DEPTERMTYPE < 12 THEN
              '08'
             WHEN a.DEPTERMTYPE = '12' THEN
              '09'
             WHEN a.DEPTERMTYPE < 24 THEN
              '10'
             WHEN a.DEPTERMTYPE = '24' THEN
              '11'
             WHEN a.DEPTERMTYPE < 36 THEN
              '12'
             WHEN a.DEPTERMTYPE = '36' THEN
              '13'
             WHEN a.DEPTERMTYPE < 60 THEN
              '14'
             WHEN a.DEPTERMTYPE = '60' THEN
              '15'
             WHEN a.DEPTERMTYPE > 60 THEN
              '16'
             ELSE
              NULL
           END --�����������
          ,
           a.PRICINGTYPE --���ۻ�׼����
          ,
           a.RATETYPE --��������
          ,
           a.REALRATE --ʵ������
          ,
           a.BASERATE --��׼����
          ,
           '' --���ʸ���Ƶ��
          ,
           IS_DATE --�ɼ�����
          ,
           a.CORPID --�ڲ�������
          ,
           '99' --ҵ������
,CASE WHEN A.CORPID LIKE '51%' THEN '510000'
          WHEN A.CORPID LIKE '52%' THEN '520000'
          WHEN A.CORPID LIKE '53%' THEN '530000'
          WHEN A.CORPID LIKE '54%' THEN '540000'
          WHEN A.CORPID LIKE '55%' THEN '550000'
          WHEN A.CORPID LIKE '56%' THEN '560000'
          WHEN A.CORPID LIKE '57%' THEN '570000'
          WHEN A.CORPID LIKE '58%' THEN '580000'
          WHEN A.CORPID LIKE '59%' THEN '590000'
          WHEN A.CORPID LIKE '60%' THEN '600000'
           ELSE '990000' END  --���˻���ID
FROM DATACORE_IE_TY_TYCKJC A
LEFT JOIN DATACORE_TMP_TX_JRJG B
       ON A.CUST_NAME=B.CUST_ID
LEFT JOIN L_CUST_BILL_TY_CKTMP C  --add by chm 20230615 ���ٽ��ڻ������ʹ����ֶ���¼
 ON A.CUST_NAME = C.FINA_ORG_NAME
      LEFT JOIN TX_JRJG_DIF D --ADD BY CHM 20231012 ����ͬҵ�ͻ���������Ӧ�öˣ�ҵ���ֶ���¼���ڻ������ʹ���
        ON A.CUST_NAME = D.CUST_NAM
  --WHERE A.CORPID NOT LIKE '5100%';
  WHERE A.CORPID NOT IN ('550005','550013')--add by wxb 20240221 ���������������ѳ���
  ;
COMMIT;



--ͨ������߼���ҵ���ѯ���׶�������
/*


select * from DATACORE_IE_TY_TYCKJC a where a.cust_id = '';




SELECT    a.custid,CASE
             WHEN D.CUST_NAM IS NOT NULL THEN
              D.CUST_NAM
             ELSE
              ''
           END AS CUST_ID --�ͻ���   add by chm 20231012 ҵ���ֶ���¼���ڻ������ʹ���
FROM DATACORE_IE_TY_TYCKJC A
LEFT JOIN DATACORE_TMP_TX_JRJG B
       ON A.CUST_NAME=B.CUST_ID
LEFT JOIN L_CUST_BILL_TY_CKTMP C  --add by chm 20230615 ���ٽ��ڻ������ʹ����ֶ���¼
 ON A.CUST_NAME = C.FINA_ORG_NAME
      LEFT JOIN TX_JRJG_DIF D --ADD BY CHM 20231012 ����ͬҵ�ͻ���������Ӧ�öˣ�ҵ���ֶ���¼���ڻ������ʹ���
        ON A.CUST_NAME = D.CUST_NAM
  WHERE A.CORPID NOT IN ('550005','550013')--add by wxb 20240221 ���������������ѳ���
  and a.custid = ''
  ;*/




/*
 \* INSERT INTO IE_TY_TYCKJC
    (datadate --��������
    ,
     corpid --�ڲ�������
    ,
     custid --�ͻ���
    ,
     orgtpcode --���ڻ������ʹ���
    ,
     accdepcode --����˻�����
    ,
     finadeptype --���ҵ������
    ,
     startdate --��ʼ����
    ,
     maturedate --��������
    ,
     deptermtype --�����������
    ,
     pricingtype --���ۻ�׼����
    ,
     ratetype --��������
    ,
     realrate --ʵ������
    ,
     baserate --��׼����
    ,
     floatfreq --���ʸ���Ƶ��
    ,
     cjrq --�ɼ�����
    ,
     nbjgh --�ڲ�������
    ,
     biz_line_id --ҵ������
    ,
     IRS_CORP_ID --���˻���ID
     )
SELECT a.DATADATE --��������
          ,
           a.CORPID --�ڲ�������
          ,
           '' --�ͻ���
          ,
           CASE
             WHEN B.JRJG IS NOT NULL THEN
              B.JRJG
             ELSE
              A.ORGTPCODE
           END --���ڻ������ʹ���
          ,
          a.ACCDEPCODE --����˻�����
          ,
           a.FINADEPTYPE --���ҵ������
          ,
           a.STARTDATE --��ʼ����
          ,
           a.MATUREDATE --��������
          ,
           CASE
             WHEN (a.DEPTERMTYPE = '' OR a.DEPTERMTYPE IS NULL OR FINADEPTYPE = 'A011' OR FINADEPTYPE = 'A021') THEN -- ���ҵ������ΪA011��A021���ڴ��ʱ�������������Ϊ01���� mdf 20240220
              '01'
             WHEN a.DEPTERMTYPE < 1 THEN
              '02'
             WHEN a.DEPTERMTYPE = '1' THEN
              '03'
             WHEN a.DEPTERMTYPE < 3 THEN
              '04'
             WHEN a.DEPTERMTYPE = '3' THEN
              '05'
             WHEN a.DEPTERMTYPE < 6 THEN
              '06'
             WHEN a.DEPTERMTYPE = '6' THEN
              '07'
             WHEN a.DEPTERMTYPE < 12 THEN
              '08'
             WHEN a.DEPTERMTYPE = '12' THEN
              '09'
             WHEN a.DEPTERMTYPE < 24 THEN
              '10'
             WHEN a.DEPTERMTYPE = '24' THEN
              '11'
             WHEN a.DEPTERMTYPE < 36 THEN
              '12'
             WHEN a.DEPTERMTYPE = '36' THEN
              '13'
             WHEN a.DEPTERMTYPE < 60 THEN
              '14'
             WHEN a.DEPTERMTYPE = '60' THEN
              '15'
             WHEN a.DEPTERMTYPE > 60 THEN
              '16'
             ELSE
              NULL
           END --�����������
          ,
           a.PRICINGTYPE --���ۻ�׼����
          ,
           a.RATETYPE --��������
          ,
           a.REALRATE --ʵ������
          ,
           a.BASERATE --��׼����
          ,
           a.FLOATFREQ --���ʸ���Ƶ��
          ,
           IS_DATE --�ɼ�����
          ,
           a.CORPID --�ڲ�������
          ,
           '99' --ҵ������
          ,
           '510000' --���˻���ID
FROM DATACORE_IE_TY_TYCKJC A
LEFT JOIN DATACORE_TMP_TX_JRJG B
       ON A.CUSTID=B.CUST_ID
WHERE A.CORPID LIKE '5100%'*\
 \*AND A.ACCDEPCODE = '60599235000000437_1'*\ ;
 --20231109wxb��������ɾ���������AND A.ACCDEPCODE = '60599235000000437_1'
\*COMMIT;*\*/
  -------------------------------------------------------------------------
  OI_RETCODE := 0; --�����쳣״̬Ϊ0 �ɹ�״̬
--������������
  OI_RETCODE2 := '�ɹ�!';
  /*COMMIT; --�����⴦��ֻ�������һ���ύ*/
  -- ������־
  VS_STEP := 'END';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
EXCEPTION
  WHEN OTHERS THEN
    --��������쳣
    VI_ERRORCODE := SQLCODE; --�����쳣����
    VS_TEXT      := VS_STEP || '|' || IS_DATE || '|' ||
                    SUBSTR(SQLERRM, 1, 200); --�����쳣����
    ROLLBACK; --���ݻع�
    OI_RETCODE := -1; --�����쳣״̬Ϊ-1
    --������־������¼����
    --������������

    OI_RETCODE2 := SUBSTR(SQLERRM, 1, 200);

    SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, VS_TEXT, IS_DATE);
END;
/

