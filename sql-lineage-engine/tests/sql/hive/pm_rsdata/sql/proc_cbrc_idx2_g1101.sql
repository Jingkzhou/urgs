CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g1101(II_DATADATE IN STRING
                                              )
/******************************
  @author:chenghuimin
  @create-date:2021-03-16
  @description:G1101
  @modification history:
  m1.20241224 shiyu JLBA202410250008 修改内容：修改个人消费贷款逾期的规则：如果不是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款取贷款余额；
                             如果是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款在逾期时间90天以内的取逾期部分，逾期90天以上的取贷款余额
  m2.20241224 信用卡重新取数JLBA202412040012
  m3.20240318 JLBA202412270003 制度升级 5项贷款重组新增指标正常类
  --需求编号: JLBA202507300010_关于新一代信贷管理系统新增线上微贷板块的需求 上线日期：20250929 修改人：石雨 提出人：于佳禾 新增吉慧贷产品

目标表：CBRC_A_REPT_ITEM_VAL
     CBRC_A_REPT_LOAN_BAL_G1101
     CBRC_PUB_DATA_COLLECT_G1101
     CBRC_TM_CBRC_G1101_TEMP1
集市表：SMTMODS_L_ACCT_CARD_CREDIT
     SMTMODS_L_ACCT_LOAN
     SMTMODS_L_CUST_ALL
     SMTMODS_L_PUBL_RATE
     SMTMODS_L_TRAN_LOAN_PAYM


  *******************************/

 IS
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE    VARCHAR(30); --当前储存过程名称
  V_TAB_NAME     VARCHAR(30); --目标表名
  I_DATADATE     VARCHAR2(30); --数据日期(数值型)YYYYMMDD
  D_DATADATE_CCY VARCHAR2(30);  --数据日期(日期型)YYYYMMDD
  V_DATADATE     VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_ERRORDESC    VARCHAR(280); --错误内容
  I_BEGINOFYEAR  VARCHAR2(30); --年初日期
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM       VARCHAR2(30);
  
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';
    I_DATADATE  := II_DATADATE;
    V_SYSTEM    := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G1101');

    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_DATADATE     := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYYMMDD');
    V_TAB_NAME     := 'G1101';
    I_BEGINOFYEAR  := TO_CHAR(TRUNC(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYY'),'YYYYMMDD');
    D_DATADATE_CCY := I_DATADATE;

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']表历史数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND REP_NUM = V_TAB_NAME
       AND FLAG = '2';
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 0;
    V_STEP_DESC := '2.1农业截止2.20国际组织 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   G1101 2.1农业 截止 2.20国际组织
    --====================================================
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_PUB_DATA_COLLECT_G1101';

    INSERT INTO CBRC_PUB_DATA_COLLECT_G1101
      (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
      SELECT ORG_NUM AS ORG_NUM,
             CASE
               WHEN LOAN_GRADE_CD = '1' THEN
                (CASE
                  WHEN LOAN_PURPOSE_CD LIKE 'A01%' THEN 1
                  WHEN LOAN_PURPOSE_CD LIKE 'A02%' THEN 2
                  WHEN LOAN_PURPOSE_CD LIKE 'A03%' THEN 3
                  WHEN LOAN_PURPOSE_CD LIKE 'A04%' THEN 4
                  WHEN LOAN_PURPOSE_CD LIKE 'A05%' THEN 5
                  WHEN LOAN_PURPOSE_CD LIKE 'B06%' THEN 6
                  WHEN LOAN_PURPOSE_CD LIKE 'B07%' THEN 7
                  WHEN LOAN_PURPOSE_CD LIKE 'B08%' THEN 8
                  WHEN LOAN_PURPOSE_CD LIKE 'B09%' THEN 9
                  WHEN LOAN_PURPOSE_CD LIKE 'B10%' THEN 10
                  WHEN LOAN_PURPOSE_CD LIKE 'B11%' THEN 11
                  WHEN LOAN_PURPOSE_CD LIKE 'B12%' THEN 12
                  WHEN LOAN_PURPOSE_CD LIKE 'C13%' THEN 13
                  WHEN LOAN_PURPOSE_CD LIKE 'C14%' THEN 14
                  WHEN LOAN_PURPOSE_CD LIKE 'C15%' THEN 15
                  WHEN LOAN_PURPOSE_CD LIKE 'C16%' THEN 16
                  WHEN LOAN_PURPOSE_CD LIKE 'C17%' THEN 17
                  WHEN LOAN_PURPOSE_CD LIKE 'C18%' THEN 18
                  WHEN LOAN_PURPOSE_CD LIKE 'C19%' THEN 19
                  WHEN LOAN_PURPOSE_CD LIKE 'C20%' THEN 20
                  WHEN LOAN_PURPOSE_CD LIKE 'C21%' THEN 21
                  WHEN LOAN_PURPOSE_CD LIKE 'C22%' THEN 22
                  WHEN LOAN_PURPOSE_CD LIKE 'C23%' THEN 23
                  WHEN LOAN_PURPOSE_CD LIKE 'C24%' THEN 24
                  WHEN LOAN_PURPOSE_CD LIKE 'C25%' THEN 25
                  WHEN LOAN_PURPOSE_CD LIKE 'C26%' THEN 26
                  WHEN LOAN_PURPOSE_CD LIKE 'C27%' THEN 27
                  WHEN LOAN_PURPOSE_CD LIKE 'C28%' THEN 28
                  WHEN LOAN_PURPOSE_CD LIKE 'C29%' THEN 29
                  WHEN LOAN_PURPOSE_CD LIKE 'C30%' THEN 30
                  WHEN LOAN_PURPOSE_CD LIKE 'C31%' THEN 31
                  WHEN LOAN_PURPOSE_CD LIKE 'C32%' THEN 32
                  WHEN LOAN_PURPOSE_CD LIKE 'C33%' THEN
                   33
                  WHEN LOAN_PURPOSE_CD LIKE 'C34%' THEN
                   34
                  WHEN LOAN_PURPOSE_CD LIKE 'C35%' THEN
                   35
                  WHEN LOAN_PURPOSE_CD LIKE 'C36%' THEN
                   36
                  WHEN LOAN_PURPOSE_CD LIKE 'C37%' THEN
                   37
                  WHEN LOAN_PURPOSE_CD LIKE 'C38%' THEN
                   38
                  WHEN LOAN_PURPOSE_CD LIKE 'C39%' THEN
                   39
                  WHEN LOAN_PURPOSE_CD LIKE 'C40%' THEN
                   40
                  WHEN LOAN_PURPOSE_CD LIKE 'C41%' THEN
                   41
                  WHEN LOAN_PURPOSE_CD LIKE 'C42%' THEN
                   42
                  WHEN LOAN_PURPOSE_CD LIKE 'C43%' THEN
                   43
                  WHEN LOAN_PURPOSE_CD LIKE 'D44%' THEN
                   44
                  WHEN LOAN_PURPOSE_CD LIKE 'D45%' THEN
                   45
                  WHEN LOAN_PURPOSE_CD LIKE 'D46%' THEN
                   46
                  WHEN LOAN_PURPOSE_CD LIKE 'E47%' THEN
                   47
                  WHEN LOAN_PURPOSE_CD LIKE 'E48%' THEN
                   48
                  WHEN LOAN_PURPOSE_CD LIKE 'E49%' THEN
                   49
                  WHEN LOAN_PURPOSE_CD LIKE 'E50%' THEN
                   50
                  WHEN LOAN_PURPOSE_CD LIKE 'F51%' THEN
                   51
                  WHEN LOAN_PURPOSE_CD LIKE 'F52%' THEN
                   52
                  WHEN LOAN_PURPOSE_CD LIKE 'G53%' THEN
                   53
                  WHEN LOAN_PURPOSE_CD LIKE 'G54%' THEN
                   54
                  WHEN LOAN_PURPOSE_CD LIKE 'G55%' THEN
                   55
                  WHEN LOAN_PURPOSE_CD LIKE 'G56%' THEN
                   56
                  WHEN LOAN_PURPOSE_CD LIKE 'G57%' THEN
                   57
                  WHEN LOAN_PURPOSE_CD LIKE 'G58%' THEN
                   58
                  WHEN LOAN_PURPOSE_CD LIKE 'G59%' THEN
                   59
                  WHEN LOAN_PURPOSE_CD LIKE 'G60%' THEN
                   60
                  WHEN LOAN_PURPOSE_CD LIKE 'H61%' THEN
                   61
                  WHEN LOAN_PURPOSE_CD LIKE 'H62%' THEN
                   62
                  WHEN LOAN_PURPOSE_CD LIKE 'I63%' THEN
                   63
                  WHEN LOAN_PURPOSE_CD LIKE 'I64%' THEN
                   64
                  WHEN LOAN_PURPOSE_CD LIKE 'I65%' THEN
                   65
                  WHEN LOAN_PURPOSE_CD LIKE 'J66%' THEN
                   66
                  WHEN LOAN_PURPOSE_CD LIKE 'J67%' THEN
                   67
                  WHEN LOAN_PURPOSE_CD LIKE 'J68%' THEN
                   68
                  WHEN LOAN_PURPOSE_CD LIKE 'J69%' THEN
                   69
                  WHEN LOAN_PURPOSE_CD LIKE 'K70%' THEN
                   70
                  WHEN LOAN_PURPOSE_CD LIKE 'L71%' THEN
                   71
                  WHEN LOAN_PURPOSE_CD LIKE 'L72%' THEN
                   72
                  WHEN LOAN_PURPOSE_CD LIKE 'M73%' THEN
                   73
                  WHEN LOAN_PURPOSE_CD LIKE 'M74%' THEN
                   74
                  WHEN LOAN_PURPOSE_CD LIKE 'M75%' THEN
                   75
                  WHEN LOAN_PURPOSE_CD LIKE 'N76%' THEN
                   76
                  WHEN LOAN_PURPOSE_CD LIKE 'N77%' THEN
                   77
                  WHEN LOAN_PURPOSE_CD LIKE 'N78%' THEN
                   78
                  WHEN LOAN_PURPOSE_CD LIKE 'N79%' THEN
                   490
                /*WHEN LOAN_PURPOSE_CD LIKE 'O79%' THEN
                79*/ --20190110 ljp modify
                  WHEN LOAN_PURPOSE_CD LIKE 'O80%' THEN
                   79
                  WHEN LOAN_PURPOSE_CD LIKE 'O81%' THEN
                   80
                --zhoujingkun  update 20210331  缺少O82投向
                  WHEN LOAN_PURPOSE_CD LIKE 'O82%' THEN
                   81
                  WHEN LOAN_PURPOSE_CD LIKE 'P83%' THEN
                   82
                /*WHEN LOAN_PURPOSE_CD LIKE 'Q83%' THEN
                83*/
                  WHEN LOAN_PURPOSE_CD LIKE 'Q84%' THEN
                   83
                  WHEN LOAN_PURPOSE_CD LIKE 'Q85%' THEN
                   84
                  WHEN LOAN_PURPOSE_CD LIKE 'R86%' THEN
                   85
                  WHEN LOAN_PURPOSE_CD LIKE 'R87%' THEN
                   86
                  WHEN LOAN_PURPOSE_CD LIKE 'R88%' THEN
                   87
                  WHEN LOAN_PURPOSE_CD LIKE 'R89%' THEN
                   88
                  WHEN LOAN_PURPOSE_CD LIKE 'R90%' THEN
                   89
                  WHEN LOAN_PURPOSE_CD LIKE 'S91%' THEN
                   90
                  WHEN LOAN_PURPOSE_CD LIKE 'S92%' THEN
                   91
                  WHEN LOAN_PURPOSE_CD LIKE 'S93%' THEN
                   92
                  WHEN LOAN_PURPOSE_CD LIKE 'S94%' THEN
                   93
                  WHEN LOAN_PURPOSE_CD LIKE 'S95%' THEN
                   94
                  WHEN LOAN_PURPOSE_CD LIKE 'S96%' THEN
                   95
                  WHEN LOAN_PURPOSE_CD LIKE 'T96%' THEN
                   96
                END)
               WHEN LOAN_GRADE_CD = '2' THEN
                (CASE
                  WHEN LOAN_PURPOSE_CD LIKE 'A01%' THEN
                   97
                  WHEN LOAN_PURPOSE_CD LIKE 'A02%' THEN
                   98
                  WHEN LOAN_PURPOSE_CD LIKE 'A03%' THEN
                   99
                  WHEN LOAN_PURPOSE_CD LIKE 'A04%' THEN
                   100
                  WHEN LOAN_PURPOSE_CD LIKE 'A05%' THEN
                   101
                  WHEN LOAN_PURPOSE_CD LIKE 'B06%' THEN
                   102
                  WHEN LOAN_PURPOSE_CD LIKE 'B07%' THEN
                   103
                  WHEN LOAN_PURPOSE_CD LIKE 'B08%' THEN
                   104
                  WHEN LOAN_PURPOSE_CD LIKE 'B09%' THEN
                   105
                  WHEN LOAN_PURPOSE_CD LIKE 'B10%' THEN
                   106
                  WHEN LOAN_PURPOSE_CD LIKE 'B11%' THEN
                   107
                  WHEN LOAN_PURPOSE_CD LIKE 'B12%' THEN
                   108
                  WHEN LOAN_PURPOSE_CD LIKE 'C13%' THEN
                   109
                  WHEN LOAN_PURPOSE_CD LIKE 'C14%' THEN
                   110
                  WHEN LOAN_PURPOSE_CD LIKE 'C15%' THEN
                   111
                  WHEN LOAN_PURPOSE_CD LIKE 'C16%' THEN
                   112
                  WHEN LOAN_PURPOSE_CD LIKE 'C17%' THEN
                   113
                  WHEN LOAN_PURPOSE_CD LIKE 'C18%' THEN
                   114
                  WHEN LOAN_PURPOSE_CD LIKE 'C19%' THEN
                   115
                  WHEN LOAN_PURPOSE_CD LIKE 'C20%' THEN
                   116
                  WHEN LOAN_PURPOSE_CD LIKE 'C21%' THEN
                   117
                  WHEN LOAN_PURPOSE_CD LIKE 'C22%' THEN
                   118
                  WHEN LOAN_PURPOSE_CD LIKE 'C23%' THEN
                   119
                  WHEN LOAN_PURPOSE_CD LIKE 'C24%' THEN
                   120
                  WHEN LOAN_PURPOSE_CD LIKE 'C25%' THEN
                   121
                  WHEN LOAN_PURPOSE_CD LIKE 'C26%' THEN
                   122
                  WHEN LOAN_PURPOSE_CD LIKE 'C27%' THEN
                   123
                  WHEN LOAN_PURPOSE_CD LIKE 'C28%' THEN
                   124
                  WHEN LOAN_PURPOSE_CD LIKE 'C29%' THEN
                   125
                  WHEN LOAN_PURPOSE_CD LIKE 'C30%' THEN
                   126
                  WHEN LOAN_PURPOSE_CD LIKE 'C31%' THEN
                   127
                  WHEN LOAN_PURPOSE_CD LIKE 'C32%' THEN
                   128
                  WHEN LOAN_PURPOSE_CD LIKE 'C33%' THEN
                   129
                  WHEN LOAN_PURPOSE_CD LIKE 'C34%' THEN
                   130
                  WHEN LOAN_PURPOSE_CD LIKE 'C35%' THEN
                   131
                  WHEN LOAN_PURPOSE_CD LIKE 'C36%' THEN
                   132
                  WHEN LOAN_PURPOSE_CD LIKE 'C37%' THEN
                   133
                  WHEN LOAN_PURPOSE_CD LIKE 'C38%' THEN
                   134
                  WHEN LOAN_PURPOSE_CD LIKE 'C39%' THEN
                   135
                  WHEN LOAN_PURPOSE_CD LIKE 'C40%' THEN
                   136
                  WHEN LOAN_PURPOSE_CD LIKE 'C41%' THEN
                   137
                  WHEN LOAN_PURPOSE_CD LIKE 'C42%' THEN
                   138
                  WHEN LOAN_PURPOSE_CD LIKE 'C43%' THEN
                   139
                  WHEN LOAN_PURPOSE_CD LIKE 'D44%' THEN
                   140
                  WHEN LOAN_PURPOSE_CD LIKE 'D45%' THEN
                   141
                  WHEN LOAN_PURPOSE_CD LIKE 'D46%' THEN
                   142
                  WHEN LOAN_PURPOSE_CD LIKE 'E47%' THEN
                   143
                  WHEN LOAN_PURPOSE_CD LIKE 'E48%' THEN
                   144
                  WHEN LOAN_PURPOSE_CD LIKE 'E49%' THEN
                   145
                  WHEN LOAN_PURPOSE_CD LIKE 'E50%' THEN
                   146
                  WHEN LOAN_PURPOSE_CD LIKE 'F51%' THEN
                   147
                  WHEN LOAN_PURPOSE_CD LIKE 'F52%' THEN
                   148
                  WHEN LOAN_PURPOSE_CD LIKE 'G53%' THEN
                   149
                  WHEN LOAN_PURPOSE_CD LIKE 'G54%' THEN
                   150
                  WHEN LOAN_PURPOSE_CD LIKE 'G55%' THEN
                   151
                  WHEN LOAN_PURPOSE_CD LIKE 'G56%' THEN
                   152
                  WHEN LOAN_PURPOSE_CD LIKE 'G57%' THEN
                   153
                  WHEN LOAN_PURPOSE_CD LIKE 'G58%' THEN
                   154
                  WHEN LOAN_PURPOSE_CD LIKE 'G59%' THEN
                   155
                  WHEN LOAN_PURPOSE_CD LIKE 'G60%' THEN
                   156
                  WHEN LOAN_PURPOSE_CD LIKE 'H61%' THEN
                   157
                  WHEN LOAN_PURPOSE_CD LIKE 'H62%' THEN
                   158
                  WHEN LOAN_PURPOSE_CD LIKE 'I63%' THEN
                   159
                  WHEN LOAN_PURPOSE_CD LIKE 'I64%' THEN
                   160
                  WHEN LOAN_PURPOSE_CD LIKE 'I65%' THEN
                   161
                  WHEN LOAN_PURPOSE_CD LIKE 'J66%' THEN
                   162
                  WHEN LOAN_PURPOSE_CD LIKE 'J67%' THEN
                   163
                  WHEN LOAN_PURPOSE_CD LIKE 'J68%' THEN
                   164
                  WHEN LOAN_PURPOSE_CD LIKE 'J69%' THEN
                   165
                  WHEN LOAN_PURPOSE_CD LIKE 'K70%' THEN
                   166
                  WHEN LOAN_PURPOSE_CD LIKE 'L71%' THEN
                   167
                  WHEN LOAN_PURPOSE_CD LIKE 'L72%' THEN
                   168
                  WHEN LOAN_PURPOSE_CD LIKE 'M73%' THEN
                   169
                  WHEN LOAN_PURPOSE_CD LIKE 'M74%' THEN
                   170
                  WHEN LOAN_PURPOSE_CD LIKE 'M75%' THEN
                   171
                  WHEN LOAN_PURPOSE_CD LIKE 'N76%' THEN
                   172
                  WHEN LOAN_PURPOSE_CD LIKE 'N77%' THEN
                   173
                  WHEN LOAN_PURPOSE_CD LIKE 'N78%' THEN
                   174
                  WHEN LOAN_PURPOSE_CD LIKE 'N79%' THEN
                   491
                /*WHEN LOAN_PURPOSE_CD LIKE 'O79%' THEN
                175*/ --20190110 ljp modify
                  WHEN LOAN_PURPOSE_CD LIKE 'O80%' THEN
                   175
                  WHEN LOAN_PURPOSE_CD LIKE 'O81%' THEN
                   176
                --zhoujingkun  update 20210331  缺少O82投向
                  WHEN LOAN_PURPOSE_CD LIKE 'O82%' THEN
                   177
                  WHEN LOAN_PURPOSE_CD LIKE 'P83%' THEN
                   178
                /*WHEN LOAN_PURPOSE_CD LIKE 'Q83%' THEN
                179*/
                  WHEN LOAN_PURPOSE_CD LIKE 'Q84%' THEN
                   179
                  WHEN LOAN_PURPOSE_CD LIKE 'Q85%' THEN
                   180
                  WHEN LOAN_PURPOSE_CD LIKE 'R86%' THEN
                   181
                  WHEN LOAN_PURPOSE_CD LIKE 'R87%' THEN
                   182
                  WHEN LOAN_PURPOSE_CD LIKE 'R88%' THEN
                   183
                  WHEN LOAN_PURPOSE_CD LIKE 'R89%' THEN
                   184
                  WHEN LOAN_PURPOSE_CD LIKE 'R90%' THEN
                   185
                  WHEN LOAN_PURPOSE_CD LIKE 'S91%' THEN
                   186
                  WHEN LOAN_PURPOSE_CD LIKE 'S92%' THEN
                   187
                  WHEN LOAN_PURPOSE_CD LIKE 'S93%' THEN
                   188
                  WHEN LOAN_PURPOSE_CD LIKE 'S94%' THEN
                   189
                  WHEN LOAN_PURPOSE_CD LIKE 'S95%' THEN
                   190
                  WHEN LOAN_PURPOSE_CD LIKE 'S96%' THEN
                   191
                  WHEN LOAN_PURPOSE_CD LIKE 'T96%' THEN
                   192
                END) --192
               WHEN LOAN_GRADE_CD = '3' THEN
                (CASE
                  WHEN LOAN_PURPOSE_CD LIKE 'A01%' THEN
                   193
                  WHEN LOAN_PURPOSE_CD LIKE 'A02%' THEN
                   194
                  WHEN LOAN_PURPOSE_CD LIKE 'A03%' THEN
                   195
                  WHEN LOAN_PURPOSE_CD LIKE 'A04%' THEN
                   196
                  WHEN LOAN_PURPOSE_CD LIKE 'A05%' THEN
                   197
                  WHEN LOAN_PURPOSE_CD LIKE 'B06%' THEN
                   198
                  WHEN LOAN_PURPOSE_CD LIKE 'B07%' THEN
                   199
                  WHEN LOAN_PURPOSE_CD LIKE 'B08%' THEN
                   200
                  WHEN LOAN_PURPOSE_CD LIKE 'B09%' THEN
                   201
                  WHEN LOAN_PURPOSE_CD LIKE 'B10%' THEN
                   202
                  WHEN LOAN_PURPOSE_CD LIKE 'B11%' THEN
                   203
                  WHEN LOAN_PURPOSE_CD LIKE 'B12%' THEN
                   204
                  WHEN LOAN_PURPOSE_CD LIKE 'C13%' THEN
                   205
                  WHEN LOAN_PURPOSE_CD LIKE 'C14%' THEN
                   206
                  WHEN LOAN_PURPOSE_CD LIKE 'C15%' THEN
                   207
                  WHEN LOAN_PURPOSE_CD LIKE 'C16%' THEN
                   208
                  WHEN LOAN_PURPOSE_CD LIKE 'C17%' THEN
                   209
                  WHEN LOAN_PURPOSE_CD LIKE 'C18%' THEN
                   210
                  WHEN LOAN_PURPOSE_CD LIKE 'C19%' THEN
                   211
                  WHEN LOAN_PURPOSE_CD LIKE 'C20%' THEN
                   212
                  WHEN LOAN_PURPOSE_CD LIKE 'C21%' THEN
                   213
                  WHEN LOAN_PURPOSE_CD LIKE 'C22%' THEN
                   214
                  WHEN LOAN_PURPOSE_CD LIKE 'C23%' THEN
                   215
                  WHEN LOAN_PURPOSE_CD LIKE 'C24%' THEN
                   216
                  WHEN LOAN_PURPOSE_CD LIKE 'C25%' THEN
                   217
                  WHEN LOAN_PURPOSE_CD LIKE 'C26%' THEN
                   218
                  WHEN LOAN_PURPOSE_CD LIKE 'C27%' THEN
                   219
                  WHEN LOAN_PURPOSE_CD LIKE 'C28%' THEN
                   220
                  WHEN LOAN_PURPOSE_CD LIKE 'C29%' THEN
                   221
                  WHEN LOAN_PURPOSE_CD LIKE 'C30%' THEN
                   222
                  WHEN LOAN_PURPOSE_CD LIKE 'C31%' THEN
                   223
                  WHEN LOAN_PURPOSE_CD LIKE 'C32%' THEN
                   224
                  WHEN LOAN_PURPOSE_CD LIKE 'C33%' THEN
                   225
                  WHEN LOAN_PURPOSE_CD LIKE 'C34%' THEN
                   226
                  WHEN LOAN_PURPOSE_CD LIKE 'C35%' THEN
                   227
                  WHEN LOAN_PURPOSE_CD LIKE 'C36%' THEN
                   228
                  WHEN LOAN_PURPOSE_CD LIKE 'C37%' THEN
                   229
                  WHEN LOAN_PURPOSE_CD LIKE 'C38%' THEN
                   230
                  WHEN LOAN_PURPOSE_CD LIKE 'C39%' THEN
                   231
                  WHEN LOAN_PURPOSE_CD LIKE 'C40%' THEN
                   232
                  WHEN LOAN_PURPOSE_CD LIKE 'C41%' THEN
                   233
                  WHEN LOAN_PURPOSE_CD LIKE 'C42%' THEN
                   234
                  WHEN LOAN_PURPOSE_CD LIKE 'C43%' THEN
                   235
                  WHEN LOAN_PURPOSE_CD LIKE 'D44%' THEN
                   236
                  WHEN LOAN_PURPOSE_CD LIKE 'D45%' THEN
                   237
                  WHEN LOAN_PURPOSE_CD LIKE 'D46%' THEN
                   238
                  WHEN LOAN_PURPOSE_CD LIKE 'E47%' THEN
                   239
                  WHEN LOAN_PURPOSE_CD LIKE 'E48%' THEN
                   240
                  WHEN LOAN_PURPOSE_CD LIKE 'E49%' THEN
                   241
                  WHEN LOAN_PURPOSE_CD LIKE 'E50%' THEN
                   242
                  WHEN LOAN_PURPOSE_CD LIKE 'F51%' THEN
                   243
                  WHEN LOAN_PURPOSE_CD LIKE 'F52%' THEN
                   244
                  WHEN LOAN_PURPOSE_CD LIKE 'G53%' THEN
                   245
                  WHEN LOAN_PURPOSE_CD LIKE 'G54%' THEN
                   246
                  WHEN LOAN_PURPOSE_CD LIKE 'G55%' THEN
                   247
                  WHEN LOAN_PURPOSE_CD LIKE 'G56%' THEN
                   248
                  WHEN LOAN_PURPOSE_CD LIKE 'G57%' THEN
                   249
                  WHEN LOAN_PURPOSE_CD LIKE 'G58%' THEN
                   250
                  WHEN LOAN_PURPOSE_CD LIKE 'G59%' THEN
                   251
                  WHEN LOAN_PURPOSE_CD LIKE 'G60%' THEN
                   252
                  WHEN LOAN_PURPOSE_CD LIKE 'H61%' THEN
                   253
                  WHEN LOAN_PURPOSE_CD LIKE 'H62%' THEN
                   254
                  WHEN LOAN_PURPOSE_CD LIKE 'I63%' THEN
                   255
                  WHEN LOAN_PURPOSE_CD LIKE 'I64%' THEN
                   256
                  WHEN LOAN_PURPOSE_CD LIKE 'I65%' THEN
                   257
                  WHEN LOAN_PURPOSE_CD LIKE 'J66%' THEN
                   258
                  WHEN LOAN_PURPOSE_CD LIKE 'J67%' THEN
                   259
                  WHEN LOAN_PURPOSE_CD LIKE 'J68%' THEN
                   260
                  WHEN LOAN_PURPOSE_CD LIKE 'J69%' THEN
                   261
                  WHEN LOAN_PURPOSE_CD LIKE 'K70%' THEN
                   262
                  WHEN LOAN_PURPOSE_CD LIKE 'L71%' THEN
                   263
                  WHEN LOAN_PURPOSE_CD LIKE 'L72%' THEN
                   264
                  WHEN LOAN_PURPOSE_CD LIKE 'M73%' THEN
                   265
                  WHEN LOAN_PURPOSE_CD LIKE 'M74%' THEN
                   266
                  WHEN LOAN_PURPOSE_CD LIKE 'M75%' THEN
                   267
                  WHEN LOAN_PURPOSE_CD LIKE 'N76%' THEN
                   268
                  WHEN LOAN_PURPOSE_CD LIKE 'N77%' THEN
                   269
                  WHEN LOAN_PURPOSE_CD LIKE 'N78%' THEN
                   270
                  WHEN LOAN_PURPOSE_CD LIKE 'N79%' THEN
                   492
                /*WHEN LOAN_PURPOSE_CD LIKE 'O79%' THEN
                271*/ --20190110 ljp modify
                  WHEN LOAN_PURPOSE_CD LIKE 'O80%' THEN
                   271
                  WHEN LOAN_PURPOSE_CD LIKE 'O81%' THEN
                   272
                --zhoujingkun  update 20210331  缺少O82投向
                  WHEN LOAN_PURPOSE_CD LIKE 'O82%' THEN
                   273
                  WHEN LOAN_PURPOSE_CD LIKE 'P83%' THEN
                   274
                /*WHEN LOAN_PURPOSE_CD LIKE 'Q83%' THEN
                275*/
                  WHEN LOAN_PURPOSE_CD LIKE 'Q84%' THEN
                   275
                  WHEN LOAN_PURPOSE_CD LIKE 'Q85%' THEN
                   276
                  WHEN LOAN_PURPOSE_CD LIKE 'R86%' THEN
                   277
                  WHEN LOAN_PURPOSE_CD LIKE 'R87%' THEN
                   278
                  WHEN LOAN_PURPOSE_CD LIKE 'R88%' THEN
                   279
                  WHEN LOAN_PURPOSE_CD LIKE 'R89%' THEN
                   280
                  WHEN LOAN_PURPOSE_CD LIKE 'R90%' THEN
                   281
                  WHEN LOAN_PURPOSE_CD LIKE 'S91%' THEN
                   282
                  WHEN LOAN_PURPOSE_CD LIKE 'S92%' THEN
                   283
                  WHEN LOAN_PURPOSE_CD LIKE 'S93%' THEN
                   284
                  WHEN LOAN_PURPOSE_CD LIKE 'S94%' THEN
                   285
                  WHEN LOAN_PURPOSE_CD LIKE 'S95%' THEN
                   286
                  WHEN LOAN_PURPOSE_CD LIKE 'S96%' THEN
                   287
                  WHEN LOAN_PURPOSE_CD LIKE 'T96%' THEN
                   288
                END) --288
               WHEN LOAN_GRADE_CD = '4' THEN
                (CASE
                  WHEN LOAN_PURPOSE_CD LIKE 'A01%' THEN
                   289
                  WHEN LOAN_PURPOSE_CD LIKE 'A02%' THEN
                   290
                  WHEN LOAN_PURPOSE_CD LIKE 'A03%' THEN
                   291
                  WHEN LOAN_PURPOSE_CD LIKE 'A04%' THEN
                   292
                  WHEN LOAN_PURPOSE_CD LIKE 'A05%' THEN
                   293
                  WHEN LOAN_PURPOSE_CD LIKE 'B06%' THEN
                   294
                  WHEN LOAN_PURPOSE_CD LIKE 'B07%' THEN
                   295
                  WHEN LOAN_PURPOSE_CD LIKE 'B08%' THEN
                   296
                  WHEN LOAN_PURPOSE_CD LIKE 'B09%' THEN
                   297
                  WHEN LOAN_PURPOSE_CD LIKE 'B10%' THEN
                   298
                  WHEN LOAN_PURPOSE_CD LIKE 'B11%' THEN
                   299
                  WHEN LOAN_PURPOSE_CD LIKE 'B12%' THEN
                   300
                  WHEN LOAN_PURPOSE_CD LIKE 'C13%' THEN
                   301
                  WHEN LOAN_PURPOSE_CD LIKE 'C14%' THEN
                   302
                  WHEN LOAN_PURPOSE_CD LIKE 'C15%' THEN
                   303
                  WHEN LOAN_PURPOSE_CD LIKE 'C16%' THEN
                   304
                  WHEN LOAN_PURPOSE_CD LIKE 'C17%' THEN
                   305
                  WHEN LOAN_PURPOSE_CD LIKE 'C18%' THEN
                   306
                  WHEN LOAN_PURPOSE_CD LIKE 'C19%' THEN
                   307
                  WHEN LOAN_PURPOSE_CD LIKE 'C20%' THEN
                   308
                  WHEN LOAN_PURPOSE_CD LIKE 'C21%' THEN
                   309
                  WHEN LOAN_PURPOSE_CD LIKE 'C22%' THEN
                   310
                  WHEN LOAN_PURPOSE_CD LIKE 'C23%' THEN
                   311
                  WHEN LOAN_PURPOSE_CD LIKE 'C24%' THEN
                   312
                  WHEN LOAN_PURPOSE_CD LIKE 'C25%' THEN
                   313
                  WHEN LOAN_PURPOSE_CD LIKE 'C26%' THEN
                   314
                  WHEN LOAN_PURPOSE_CD LIKE 'C27%' THEN
                   315
                  WHEN LOAN_PURPOSE_CD LIKE 'C28%' THEN
                   316
                  WHEN LOAN_PURPOSE_CD LIKE 'C29%' THEN
                   317
                  WHEN LOAN_PURPOSE_CD LIKE 'C30%' THEN
                   318
                  WHEN LOAN_PURPOSE_CD LIKE 'C31%' THEN
                   319
                  WHEN LOAN_PURPOSE_CD LIKE 'C32%' THEN
                   320
                  WHEN LOAN_PURPOSE_CD LIKE 'C33%' THEN
                   321
                  WHEN LOAN_PURPOSE_CD LIKE 'C34%' THEN
                   322
                  WHEN LOAN_PURPOSE_CD LIKE 'C35%' THEN
                   323
                  WHEN LOAN_PURPOSE_CD LIKE 'C36%' THEN
                   324
                  WHEN LOAN_PURPOSE_CD LIKE 'C37%' THEN
                   325
                  WHEN LOAN_PURPOSE_CD LIKE 'C38%' THEN
                   326
                  WHEN LOAN_PURPOSE_CD LIKE 'C39%' THEN
                   327
                  WHEN LOAN_PURPOSE_CD LIKE 'C40%' THEN
                   328
                  WHEN LOAN_PURPOSE_CD LIKE 'C41%' THEN
                   329
                  WHEN LOAN_PURPOSE_CD LIKE 'C42%' THEN
                   330
                  WHEN LOAN_PURPOSE_CD LIKE 'C43%' THEN
                   331
                  WHEN LOAN_PURPOSE_CD LIKE 'D44%' THEN
                   332
                  WHEN LOAN_PURPOSE_CD LIKE 'D45%' THEN
                   333
                  WHEN LOAN_PURPOSE_CD LIKE 'D46%' THEN
                   334
                  WHEN LOAN_PURPOSE_CD LIKE 'E47%' THEN
                   335
                  WHEN LOAN_PURPOSE_CD LIKE 'E48%' THEN
                   336
                  WHEN LOAN_PURPOSE_CD LIKE 'E49%' THEN
                   337
                  WHEN LOAN_PURPOSE_CD LIKE 'E50%' THEN
                   338
                  WHEN LOAN_PURPOSE_CD LIKE 'F51%' THEN
                   339
                  WHEN LOAN_PURPOSE_CD LIKE 'F52%' THEN
                   340
                  WHEN LOAN_PURPOSE_CD LIKE 'G53%' THEN
                   341
                  WHEN LOAN_PURPOSE_CD LIKE 'G54%' THEN
                   342
                  WHEN LOAN_PURPOSE_CD LIKE 'G55%' THEN
                   343
                  WHEN LOAN_PURPOSE_CD LIKE 'G56%' THEN
                   344
                  WHEN LOAN_PURPOSE_CD LIKE 'G57%' THEN
                   345
                  WHEN LOAN_PURPOSE_CD LIKE 'G58%' THEN
                   346
                  WHEN LOAN_PURPOSE_CD LIKE 'G59%' THEN
                   347
                  WHEN LOAN_PURPOSE_CD LIKE 'G60%' THEN
                   348
                  WHEN LOAN_PURPOSE_CD LIKE 'H61%' THEN
                   349
                  WHEN LOAN_PURPOSE_CD LIKE 'H62%' THEN
                   350
                  WHEN LOAN_PURPOSE_CD LIKE 'I63%' THEN
                   351
                  WHEN LOAN_PURPOSE_CD LIKE 'I64%' THEN
                   352
                  WHEN LOAN_PURPOSE_CD LIKE 'I65%' THEN
                   353
                  WHEN LOAN_PURPOSE_CD LIKE 'J66%' THEN
                   354
                  WHEN LOAN_PURPOSE_CD LIKE 'J67%' THEN
                   355
                  WHEN LOAN_PURPOSE_CD LIKE 'J68%' THEN
                   356
                  WHEN LOAN_PURPOSE_CD LIKE 'J69%' THEN
                   357
                  WHEN LOAN_PURPOSE_CD LIKE 'K70%' THEN
                   358
                  WHEN LOAN_PURPOSE_CD LIKE 'L71%' THEN
                   359
                  WHEN LOAN_PURPOSE_CD LIKE 'L72%' THEN
                   360
                  WHEN LOAN_PURPOSE_CD LIKE 'M73%' THEN
                   361
                  WHEN LOAN_PURPOSE_CD LIKE 'M74%' THEN
                   362
                  WHEN LOAN_PURPOSE_CD LIKE 'M75%' THEN
                   363
                  WHEN LOAN_PURPOSE_CD LIKE 'N76%' THEN
                   364
                  WHEN LOAN_PURPOSE_CD LIKE 'N77%' THEN
                   365
                  WHEN LOAN_PURPOSE_CD LIKE 'N78%' THEN
                   366
                  WHEN LOAN_PURPOSE_CD LIKE 'N79%' THEN
                   493
                /* WHEN LOAN_PURPOSE_CD LIKE 'O79%' THEN
                367*/ --20190110 ljp modify
                  WHEN LOAN_PURPOSE_CD LIKE 'O80%' THEN
                   367
                  WHEN LOAN_PURPOSE_CD LIKE 'O81%' THEN
                   368
                --zhoujingkun  update 20210331  缺少O82投向
                  WHEN LOAN_PURPOSE_CD LIKE 'O82%' THEN
                   369
                  WHEN LOAN_PURPOSE_CD LIKE 'P83%' THEN
                   370
                /* WHEN LOAN_PURPOSE_CD LIKE 'Q83%' THEN
                371*/
                  WHEN LOAN_PURPOSE_CD LIKE 'Q84%' THEN
                   371
                  WHEN LOAN_PURPOSE_CD LIKE 'Q85%' THEN
                   372
                  WHEN LOAN_PURPOSE_CD LIKE 'R86%' THEN
                   373
                  WHEN LOAN_PURPOSE_CD LIKE 'R87%' THEN
                   374
                  WHEN LOAN_PURPOSE_CD LIKE 'R88%' THEN
                   375
                  WHEN LOAN_PURPOSE_CD LIKE 'R89%' THEN
                   376
                  WHEN LOAN_PURPOSE_CD LIKE 'R90%' THEN
                   377
                  WHEN LOAN_PURPOSE_CD LIKE 'S91%' THEN
                   378
                  WHEN LOAN_PURPOSE_CD LIKE 'S92%' THEN
                   379
                  WHEN LOAN_PURPOSE_CD LIKE 'S93%' THEN
                   380
                  WHEN LOAN_PURPOSE_CD LIKE 'S94%' THEN
                   381
                  WHEN LOAN_PURPOSE_CD LIKE 'S95%' THEN
                   382
                  WHEN LOAN_PURPOSE_CD LIKE 'S96%' THEN
                   383
                  WHEN LOAN_PURPOSE_CD LIKE 'T96%' THEN
                   384
                END) --384
               WHEN LOAN_GRADE_CD = '5' THEN
                (CASE
                  WHEN LOAN_PURPOSE_CD LIKE 'A01%' THEN
                   385
                  WHEN LOAN_PURPOSE_CD LIKE 'A02%' THEN
                   386
                  WHEN LOAN_PURPOSE_CD LIKE 'A03%' THEN
                   387
                  WHEN LOAN_PURPOSE_CD LIKE 'A04%' THEN
                   388
                  WHEN LOAN_PURPOSE_CD LIKE 'A05%' THEN
                   389
                  WHEN LOAN_PURPOSE_CD LIKE 'B06%' THEN
                   390
                  WHEN LOAN_PURPOSE_CD LIKE 'B07%' THEN
                   391
                  WHEN LOAN_PURPOSE_CD LIKE 'B08%' THEN
                   392
                  WHEN LOAN_PURPOSE_CD LIKE 'B09%' THEN
                   393
                  WHEN LOAN_PURPOSE_CD LIKE 'B10%' THEN
                   394
                  WHEN LOAN_PURPOSE_CD LIKE 'B11%' THEN
                   395
                  WHEN LOAN_PURPOSE_CD LIKE 'B12%' THEN
                   396
                  WHEN LOAN_PURPOSE_CD LIKE 'C13%' THEN
                   397
                  WHEN LOAN_PURPOSE_CD LIKE 'C14%' THEN
                   398
                  WHEN LOAN_PURPOSE_CD LIKE 'C15%' THEN
                   399
                  WHEN LOAN_PURPOSE_CD LIKE 'C16%' THEN
                   400
                  WHEN LOAN_PURPOSE_CD LIKE 'C17%' THEN
                   401
                  WHEN LOAN_PURPOSE_CD LIKE 'C18%' THEN
                   402
                  WHEN LOAN_PURPOSE_CD LIKE 'C19%' THEN
                   403
                  WHEN LOAN_PURPOSE_CD LIKE 'C20%' THEN
                   404
                  WHEN LOAN_PURPOSE_CD LIKE 'C21%' THEN
                   405
                  WHEN LOAN_PURPOSE_CD LIKE 'C22%' THEN
                   406
                  WHEN LOAN_PURPOSE_CD LIKE 'C23%' THEN
                   407
                  WHEN LOAN_PURPOSE_CD LIKE 'C24%' THEN
                   408
                  WHEN LOAN_PURPOSE_CD LIKE 'C25%' THEN
                   409
                  WHEN LOAN_PURPOSE_CD LIKE 'C26%' THEN
                   410
                  WHEN LOAN_PURPOSE_CD LIKE 'C27%' THEN
                   411
                  WHEN LOAN_PURPOSE_CD LIKE 'C28%' THEN
                   412
                  WHEN LOAN_PURPOSE_CD LIKE 'C29%' THEN
                   413
                  WHEN LOAN_PURPOSE_CD LIKE 'C30%' THEN
                   414
                  WHEN LOAN_PURPOSE_CD LIKE 'C31%' THEN
                   415
                  WHEN LOAN_PURPOSE_CD LIKE 'C32%' THEN
                   416
                  WHEN LOAN_PURPOSE_CD LIKE 'C33%' THEN
                   417
                  WHEN LOAN_PURPOSE_CD LIKE 'C34%' THEN
                   418
                  WHEN LOAN_PURPOSE_CD LIKE 'C35%' THEN
                   419
                  WHEN LOAN_PURPOSE_CD LIKE 'C36%' THEN
                   420
                  WHEN LOAN_PURPOSE_CD LIKE 'C37%' THEN
                   421
                  WHEN LOAN_PURPOSE_CD LIKE 'C38%' THEN
                   422
                  WHEN LOAN_PURPOSE_CD LIKE 'C39%' THEN
                   423
                  WHEN LOAN_PURPOSE_CD LIKE 'C40%' THEN
                   424
                  WHEN LOAN_PURPOSE_CD LIKE 'C41%' THEN
                   425
                  WHEN LOAN_PURPOSE_CD LIKE 'C42%' THEN
                   426
                  WHEN LOAN_PURPOSE_CD LIKE 'C43%' THEN
                   427
                  WHEN LOAN_PURPOSE_CD LIKE 'D44%' THEN
                   428
                  WHEN LOAN_PURPOSE_CD LIKE 'D45%' THEN
                   429
                  WHEN LOAN_PURPOSE_CD LIKE 'D46%' THEN
                   430
                  WHEN LOAN_PURPOSE_CD LIKE 'E47%' THEN
                   431
                  WHEN LOAN_PURPOSE_CD LIKE 'E48%' THEN
                   432
                  WHEN LOAN_PURPOSE_CD LIKE 'E49%' THEN
                   433
                  WHEN LOAN_PURPOSE_CD LIKE 'E50%' THEN
                   434
                  WHEN LOAN_PURPOSE_CD LIKE 'F51%' THEN
                   435
                  WHEN LOAN_PURPOSE_CD LIKE 'F52%' THEN
                   436
                  WHEN LOAN_PURPOSE_CD LIKE 'G53%' THEN
                   437
                  WHEN LOAN_PURPOSE_CD LIKE 'G54%' THEN
                   438
                  WHEN LOAN_PURPOSE_CD LIKE 'G55%' THEN
                   439
                  WHEN LOAN_PURPOSE_CD LIKE 'G56%' THEN
                   440
                  WHEN LOAN_PURPOSE_CD LIKE 'G57%' THEN
                   441
                  WHEN LOAN_PURPOSE_CD LIKE 'G58%' THEN
                   442
                  WHEN LOAN_PURPOSE_CD LIKE 'G59%' THEN
                   443
                  WHEN LOAN_PURPOSE_CD LIKE 'G60%' THEN
                   444
                  WHEN LOAN_PURPOSE_CD LIKE 'H61%' THEN
                   445
                  WHEN LOAN_PURPOSE_CD LIKE 'H62%' THEN
                   446
                  WHEN LOAN_PURPOSE_CD LIKE 'I63%' THEN
                   447
                  WHEN LOAN_PURPOSE_CD LIKE 'I64%' THEN
                   448
                  WHEN LOAN_PURPOSE_CD LIKE 'I65%' THEN
                   449
                  WHEN LOAN_PURPOSE_CD LIKE 'J66%' THEN
                   450
                  WHEN LOAN_PURPOSE_CD LIKE 'J67%' THEN
                   451
                  WHEN LOAN_PURPOSE_CD LIKE 'J68%' THEN
                   452
                  WHEN LOAN_PURPOSE_CD LIKE 'J69%' THEN
                   453
                  WHEN LOAN_PURPOSE_CD LIKE 'K70%' THEN
                   454
                  WHEN LOAN_PURPOSE_CD LIKE 'L71%' THEN
                   455
                  WHEN LOAN_PURPOSE_CD LIKE 'L72%' THEN
                   456
                  WHEN LOAN_PURPOSE_CD LIKE 'M73%' THEN
                   457
                  WHEN LOAN_PURPOSE_CD LIKE 'M74%' THEN
                   458
                  WHEN LOAN_PURPOSE_CD LIKE 'M75%' THEN
                   459
                  WHEN LOAN_PURPOSE_CD LIKE 'N76%' THEN
                   460
                  WHEN LOAN_PURPOSE_CD LIKE 'N77%' THEN
                   461
                  WHEN LOAN_PURPOSE_CD LIKE 'N78%' THEN
                   462
                  WHEN LOAN_PURPOSE_CD LIKE 'N79%' THEN
                   494
                /*WHEN LOAN_PURPOSE_CD LIKE 'O79%' THEN
                463*/
                  WHEN LOAN_PURPOSE_CD LIKE 'O80%' THEN
                   463
                  WHEN LOAN_PURPOSE_CD LIKE 'O81%' THEN
                   464
                --zhoujingkun  update 20210331  缺少O82投向
                  WHEN LOAN_PURPOSE_CD LIKE 'O82%' THEN
                   465
                  WHEN LOAN_PURPOSE_CD LIKE 'P83%' THEN
                   466
                /*WHEN LOAN_PURPOSE_CD LIKE 'Q83%' THEN
                467*/
                  WHEN LOAN_PURPOSE_CD LIKE 'Q84%' THEN
                   467
                  WHEN LOAN_PURPOSE_CD LIKE 'Q85%' THEN
                   468
                  WHEN LOAN_PURPOSE_CD LIKE 'R86%' THEN
                   469
                  WHEN LOAN_PURPOSE_CD LIKE 'R87%' THEN
                   470
                  WHEN LOAN_PURPOSE_CD LIKE 'R88%' THEN
                   471
                  WHEN LOAN_PURPOSE_CD LIKE 'R89%' THEN
                   472
                  WHEN LOAN_PURPOSE_CD LIKE 'R90%' THEN
                   473
                  WHEN LOAN_PURPOSE_CD LIKE 'S91%' THEN
                   474
                  WHEN LOAN_PURPOSE_CD LIKE 'S92%' THEN
                   475
                  WHEN LOAN_PURPOSE_CD LIKE 'S93%' THEN
                   476
                  WHEN LOAN_PURPOSE_CD LIKE 'S94%' THEN
                   477
                  WHEN LOAN_PURPOSE_CD LIKE 'S95%' THEN
                   478
                  WHEN LOAN_PURPOSE_CD LIKE 'S96%' THEN
                   479
                  WHEN LOAN_PURPOSE_CD LIKE 'T96%' THEN
                   480
                END) --480
             END COLLECT_TYPE,
             NVL(LOAN_ACCT_BAL * U.CCY_RATE, 0) +
             NVL(INT_ADJEST_AMT * U.CCY_RATE, 0) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND (A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%')
         AND A.ACCT_TYP NOT LIKE '0301%' --shiwenbo by 20170317-12901 单独取直贴
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         and A.acct_sts <> '3'
         and A.ACCT_TYP NOT LIKE '90%'
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
         AND SUBSTR(A.LOAN_PURPOSE_CD, 1, 3) IN
             ('A01',
              'A02',
              'A03',
              'A04',
              'A05',
              'B06',
              'B07',
              'B08',
              'B09',
              'B10',
              'B11',
              'B12',
              'C13',
              'C14',
              'C15',
              'C16',
              'C17',
              'C18',
              'C19',
              'C20',
              'C21',
              'C22',
              'C23',
              'C24',
              'C25',
              'C26',
              'C27',
              'C28',
              'C29',
              'C30',
              'C31',
              'C32',
              'C33',
              'C34',
              'C35',
              'C36',
              'C37',
              'C38',
              'C39',
              'C40',
              'C41',
              'C42',
              'C43',
              'D44',
              'D45',
              'D46',
              'E47',
              'E48',
              'E49',
              'E50',
              'F51',
              'F52',
              'G53',
              'G54',
              'G55',
              'G56',
              'G57',
              'G58',
              'G59',
              'G60',
              'H61',
              'H62',
              'I63',
              'I64',
              'I65',
              'J66',
              'J67',
              'J68',
              'J69',
              'K70',
              'L71',
              'L72',
              'M73',
              'M74',
              'M75',
              'N76',
              'N77',
              'N78',
              'N79',
              -- 'O79',
              'O80',
              'O81',
              'O82',
              'P83',
              'Q83',
              'Q84',
              'Q85',
              'R85',
              'R86',
              'R87',
              'R88',
              'R89',
              'R90',
              'S90',
              'S91',
              'S92',
              'S93',
              'S94',
              'S95',
              'S96',
              'T96')
      --shiwenbo by 20170317-12901 单独取直贴
      UNION ALL
      SELECT ORG_NUM AS ORG_NUM,
             CASE
               WHEN LOAN_GRADE_CD = '1' THEN
                (CASE
                  WHEN LOAN_PURPOSE_CD LIKE 'A01%' THEN
                   1
                  WHEN LOAN_PURPOSE_CD LIKE 'A02%' THEN
                   2
                  WHEN LOAN_PURPOSE_CD LIKE 'A03%' THEN
                   3
                  WHEN LOAN_PURPOSE_CD LIKE 'A04%' THEN
                   4
                  WHEN LOAN_PURPOSE_CD LIKE 'A05%' THEN
                   5
                  WHEN LOAN_PURPOSE_CD LIKE 'B06%' THEN
                   6
                  WHEN LOAN_PURPOSE_CD LIKE 'B07%' THEN
                   7
                  WHEN LOAN_PURPOSE_CD LIKE 'B08%' THEN
                   8
                  WHEN LOAN_PURPOSE_CD LIKE 'B09%' THEN
                   9
                  WHEN LOAN_PURPOSE_CD LIKE 'B10%' THEN
                   10
                  WHEN LOAN_PURPOSE_CD LIKE 'B11%' THEN
                   11
                  WHEN LOAN_PURPOSE_CD LIKE 'B12%' THEN
                   12
                  WHEN LOAN_PURPOSE_CD LIKE 'C13%' THEN
                   13
                  WHEN LOAN_PURPOSE_CD LIKE 'C14%' THEN
                   14
                  WHEN LOAN_PURPOSE_CD LIKE 'C15%' THEN
                   15
                  WHEN LOAN_PURPOSE_CD LIKE 'C16%' THEN
                   16
                  WHEN LOAN_PURPOSE_CD LIKE 'C17%' THEN
                   17
                  WHEN LOAN_PURPOSE_CD LIKE 'C18%' THEN
                   18
                  WHEN LOAN_PURPOSE_CD LIKE 'C19%' THEN
                   19
                  WHEN LOAN_PURPOSE_CD LIKE 'C20%' THEN
                   20
                  WHEN LOAN_PURPOSE_CD LIKE 'C21%' THEN
                   21
                  WHEN LOAN_PURPOSE_CD LIKE 'C22%' THEN
                   22
                  WHEN LOAN_PURPOSE_CD LIKE 'C23%' THEN
                   23
                  WHEN LOAN_PURPOSE_CD LIKE 'C24%' THEN
                   24
                  WHEN LOAN_PURPOSE_CD LIKE 'C25%' THEN
                   25
                  WHEN LOAN_PURPOSE_CD LIKE 'C26%' THEN
                   26
                  WHEN LOAN_PURPOSE_CD LIKE 'C27%' THEN
                   27
                  WHEN LOAN_PURPOSE_CD LIKE 'C28%' THEN
                   28
                  WHEN LOAN_PURPOSE_CD LIKE 'C29%' THEN
                   29
                  WHEN LOAN_PURPOSE_CD LIKE 'C30%' THEN
                   30
                  WHEN LOAN_PURPOSE_CD LIKE 'C31%' THEN
                   31
                  WHEN LOAN_PURPOSE_CD LIKE 'C32%' THEN
                   32
                  WHEN LOAN_PURPOSE_CD LIKE 'C33%' THEN
                   33
                  WHEN LOAN_PURPOSE_CD LIKE 'C34%' THEN
                   34
                  WHEN LOAN_PURPOSE_CD LIKE 'C35%' THEN
                   35
                  WHEN LOAN_PURPOSE_CD LIKE 'C36%' THEN
                   36
                  WHEN LOAN_PURPOSE_CD LIKE 'C37%' THEN
                   37
                  WHEN LOAN_PURPOSE_CD LIKE 'C38%' THEN
                   38
                  WHEN LOAN_PURPOSE_CD LIKE 'C39%' THEN
                   39
                  WHEN LOAN_PURPOSE_CD LIKE 'C40%' THEN
                   40
                  WHEN LOAN_PURPOSE_CD LIKE 'C41%' THEN
                   41
                  WHEN LOAN_PURPOSE_CD LIKE 'C42%' THEN
                   42
                  WHEN LOAN_PURPOSE_CD LIKE 'C43%' THEN
                   43
                  WHEN LOAN_PURPOSE_CD LIKE 'D44%' THEN
                   44
                  WHEN LOAN_PURPOSE_CD LIKE 'D45%' THEN
                   45
                  WHEN LOAN_PURPOSE_CD LIKE 'D46%' THEN
                   46
                  WHEN LOAN_PURPOSE_CD LIKE 'E47%' THEN
                   47
                  WHEN LOAN_PURPOSE_CD LIKE 'E48%' THEN
                   48
                  WHEN LOAN_PURPOSE_CD LIKE 'E49%' THEN
                   49
                  WHEN LOAN_PURPOSE_CD LIKE 'E50%' THEN
                   50
                  WHEN LOAN_PURPOSE_CD LIKE 'F51%' THEN
                   51
                  WHEN LOAN_PURPOSE_CD LIKE 'F52%' THEN
                   52
                  WHEN LOAN_PURPOSE_CD LIKE 'G53%' THEN
                   53
                  WHEN LOAN_PURPOSE_CD LIKE 'G54%' THEN
                   54
                  WHEN LOAN_PURPOSE_CD LIKE 'G55%' THEN
                   55
                  WHEN LOAN_PURPOSE_CD LIKE 'G56%' THEN
                   56
                  WHEN LOAN_PURPOSE_CD LIKE 'G57%' THEN
                   57
                  WHEN LOAN_PURPOSE_CD LIKE 'G58%' THEN
                   58
                  WHEN LOAN_PURPOSE_CD LIKE 'G59%' THEN
                   59
                  WHEN LOAN_PURPOSE_CD LIKE 'G60%' THEN
                   60
                  WHEN LOAN_PURPOSE_CD LIKE 'H61%' THEN
                   61
                  WHEN LOAN_PURPOSE_CD LIKE 'H62%' THEN
                   62
                  WHEN LOAN_PURPOSE_CD LIKE 'I63%' THEN
                   63
                  WHEN LOAN_PURPOSE_CD LIKE 'I64%' THEN
                   64
                  WHEN LOAN_PURPOSE_CD LIKE 'I65%' THEN
                   65
                  WHEN LOAN_PURPOSE_CD LIKE 'J66%' THEN
                   66
                  WHEN LOAN_PURPOSE_CD LIKE 'J67%' THEN
                   67
                  WHEN LOAN_PURPOSE_CD LIKE 'J68%' THEN
                   68
                  WHEN LOAN_PURPOSE_CD LIKE 'J69%' THEN
                   69
                  WHEN LOAN_PURPOSE_CD LIKE 'K70%' THEN
                   70
                  WHEN LOAN_PURPOSE_CD LIKE 'L71%' THEN
                   71
                  WHEN LOAN_PURPOSE_CD LIKE 'L72%' THEN
                   72
                  WHEN LOAN_PURPOSE_CD LIKE 'M73%' THEN
                   73
                  WHEN LOAN_PURPOSE_CD LIKE 'M74%' THEN
                   74
                  WHEN LOAN_PURPOSE_CD LIKE 'M75%' THEN
                   75
                  WHEN LOAN_PURPOSE_CD LIKE 'N76%' THEN
                   76
                  WHEN LOAN_PURPOSE_CD LIKE 'N77%' THEN
                   77
                  WHEN LOAN_PURPOSE_CD LIKE 'N78%' THEN
                   78
                  WHEN LOAN_PURPOSE_CD LIKE 'N79%' THEN
                   490
                /* WHEN LOAN_PURPOSE_CD LIKE 'O79%' THEN
                79*/
                  WHEN LOAN_PURPOSE_CD LIKE 'O80%' THEN
                   79
                  WHEN LOAN_PURPOSE_CD LIKE 'O81%' THEN
                   80
                --zhoujingkun  update 20210331  缺少O82投向
                  WHEN LOAN_PURPOSE_CD LIKE 'O82%' THEN
                   81
                  WHEN LOAN_PURPOSE_CD LIKE 'P83%' THEN
                   82
                /*WHEN LOAN_PURPOSE_CD LIKE 'Q83%' THEN
                83*/
                  WHEN LOAN_PURPOSE_CD LIKE 'Q84%' THEN
                   83
                  WHEN LOAN_PURPOSE_CD LIKE 'Q85%' THEN
                   84
                  WHEN LOAN_PURPOSE_CD LIKE 'R86%' THEN
                   85
                  WHEN LOAN_PURPOSE_CD LIKE 'R87%' THEN
                   86
                  WHEN LOAN_PURPOSE_CD LIKE 'R88%' THEN
                   87
                  WHEN LOAN_PURPOSE_CD LIKE 'R89%' THEN
                   88
                  WHEN LOAN_PURPOSE_CD LIKE 'R90%' THEN
                   89
                  WHEN LOAN_PURPOSE_CD LIKE 'S91%' THEN
                   90
                  WHEN LOAN_PURPOSE_CD LIKE 'S92%' THEN
                   91
                  WHEN LOAN_PURPOSE_CD LIKE 'S93%' THEN
                   92
                  WHEN LOAN_PURPOSE_CD LIKE 'S94%' THEN
                   93
                  WHEN LOAN_PURPOSE_CD LIKE 'S95%' THEN
                   94
                  WHEN LOAN_PURPOSE_CD LIKE 'S96%' THEN
                   95
                  WHEN LOAN_PURPOSE_CD LIKE 'T96%' THEN
                   96
                END)
               WHEN LOAN_GRADE_CD = '2' THEN
                (CASE
                  WHEN LOAN_PURPOSE_CD LIKE 'A01%' THEN
                   97
                  WHEN LOAN_PURPOSE_CD LIKE 'A02%' THEN
                   98
                  WHEN LOAN_PURPOSE_CD LIKE 'A03%' THEN
                   99
                  WHEN LOAN_PURPOSE_CD LIKE 'A04%' THEN
                   100
                  WHEN LOAN_PURPOSE_CD LIKE 'A05%' THEN
                   101
                  WHEN LOAN_PURPOSE_CD LIKE 'B06%' THEN
                   102
                  WHEN LOAN_PURPOSE_CD LIKE 'B07%' THEN
                   103
                  WHEN LOAN_PURPOSE_CD LIKE 'B08%' THEN
                   104
                  WHEN LOAN_PURPOSE_CD LIKE 'B09%' THEN
                   105
                  WHEN LOAN_PURPOSE_CD LIKE 'B10%' THEN
                   106
                  WHEN LOAN_PURPOSE_CD LIKE 'B11%' THEN
                   107
                  WHEN LOAN_PURPOSE_CD LIKE 'B12%' THEN
                   108
                  WHEN LOAN_PURPOSE_CD LIKE 'C13%' THEN
                   109
                  WHEN LOAN_PURPOSE_CD LIKE 'C14%' THEN
                   110
                  WHEN LOAN_PURPOSE_CD LIKE 'C15%' THEN
                   111
                  WHEN LOAN_PURPOSE_CD LIKE 'C16%' THEN
                   112
                  WHEN LOAN_PURPOSE_CD LIKE 'C17%' THEN
                   113
                  WHEN LOAN_PURPOSE_CD LIKE 'C18%' THEN
                   114
                  WHEN LOAN_PURPOSE_CD LIKE 'C19%' THEN
                   115
                  WHEN LOAN_PURPOSE_CD LIKE 'C20%' THEN
                   116
                  WHEN LOAN_PURPOSE_CD LIKE 'C21%' THEN
                   117
                  WHEN LOAN_PURPOSE_CD LIKE 'C22%' THEN
                   118
                  WHEN LOAN_PURPOSE_CD LIKE 'C23%' THEN
                   119
                  WHEN LOAN_PURPOSE_CD LIKE 'C24%' THEN
                   120
                  WHEN LOAN_PURPOSE_CD LIKE 'C25%' THEN
                   121
                  WHEN LOAN_PURPOSE_CD LIKE 'C26%' THEN
                   122
                  WHEN LOAN_PURPOSE_CD LIKE 'C27%' THEN
                   123
                  WHEN LOAN_PURPOSE_CD LIKE 'C28%' THEN
                   124
                  WHEN LOAN_PURPOSE_CD LIKE 'C29%' THEN
                   125
                  WHEN LOAN_PURPOSE_CD LIKE 'C30%' THEN
                   126
                  WHEN LOAN_PURPOSE_CD LIKE 'C31%' THEN
                   127
                  WHEN LOAN_PURPOSE_CD LIKE 'C32%' THEN
                   128
                  WHEN LOAN_PURPOSE_CD LIKE 'C33%' THEN
                   129
                  WHEN LOAN_PURPOSE_CD LIKE 'C34%' THEN
                   130
                  WHEN LOAN_PURPOSE_CD LIKE 'C35%' THEN
                   131
                  WHEN LOAN_PURPOSE_CD LIKE 'C36%' THEN
                   132
                  WHEN LOAN_PURPOSE_CD LIKE 'C37%' THEN
                   133
                  WHEN LOAN_PURPOSE_CD LIKE 'C38%' THEN
                   134
                  WHEN LOAN_PURPOSE_CD LIKE 'C39%' THEN
                   135
                  WHEN LOAN_PURPOSE_CD LIKE 'C40%' THEN
                   136
                  WHEN LOAN_PURPOSE_CD LIKE 'C41%' THEN
                   137
                  WHEN LOAN_PURPOSE_CD LIKE 'C42%' THEN
                   138
                  WHEN LOAN_PURPOSE_CD LIKE 'C43%' THEN
                   139
                  WHEN LOAN_PURPOSE_CD LIKE 'D44%' THEN
                   140
                  WHEN LOAN_PURPOSE_CD LIKE 'D45%' THEN
                   141
                  WHEN LOAN_PURPOSE_CD LIKE 'D46%' THEN
                   142
                  WHEN LOAN_PURPOSE_CD LIKE 'E47%' THEN
                   143
                  WHEN LOAN_PURPOSE_CD LIKE 'E48%' THEN
                   144
                  WHEN LOAN_PURPOSE_CD LIKE 'E49%' THEN
                   145
                  WHEN LOAN_PURPOSE_CD LIKE 'E50%' THEN
                   146
                  WHEN LOAN_PURPOSE_CD LIKE 'F51%' THEN
                   147
                  WHEN LOAN_PURPOSE_CD LIKE 'F52%' THEN
                   148
                  WHEN LOAN_PURPOSE_CD LIKE 'G53%' THEN
                   149
                  WHEN LOAN_PURPOSE_CD LIKE 'G54%' THEN
                   150
                  WHEN LOAN_PURPOSE_CD LIKE 'G55%' THEN
                   151
                  WHEN LOAN_PURPOSE_CD LIKE 'G56%' THEN
                   152
                  WHEN LOAN_PURPOSE_CD LIKE 'G57%' THEN
                   153
                  WHEN LOAN_PURPOSE_CD LIKE 'G58%' THEN
                   154
                  WHEN LOAN_PURPOSE_CD LIKE 'G59%' THEN
                   155
                  WHEN LOAN_PURPOSE_CD LIKE 'G60%' THEN
                   156
                  WHEN LOAN_PURPOSE_CD LIKE 'H61%' THEN
                   157
                  WHEN LOAN_PURPOSE_CD LIKE 'H62%' THEN
                   158
                  WHEN LOAN_PURPOSE_CD LIKE 'I63%' THEN
                   159
                  WHEN LOAN_PURPOSE_CD LIKE 'I64%' THEN
                   160
                  WHEN LOAN_PURPOSE_CD LIKE 'I65%' THEN
                   161
                  WHEN LOAN_PURPOSE_CD LIKE 'J66%' THEN
                   162
                  WHEN LOAN_PURPOSE_CD LIKE 'J67%' THEN
                   163
                  WHEN LOAN_PURPOSE_CD LIKE 'J68%' THEN
                   164
                  WHEN LOAN_PURPOSE_CD LIKE 'J69%' THEN
                   165
                  WHEN LOAN_PURPOSE_CD LIKE 'K70%' THEN
                   166
                  WHEN LOAN_PURPOSE_CD LIKE 'L71%' THEN
                   167
                  WHEN LOAN_PURPOSE_CD LIKE 'L72%' THEN
                   168
                  WHEN LOAN_PURPOSE_CD LIKE 'M73%' THEN
                   169
                  WHEN LOAN_PURPOSE_CD LIKE 'M74%' THEN
                   170
                  WHEN LOAN_PURPOSE_CD LIKE 'M75%' THEN
                   171
                  WHEN LOAN_PURPOSE_CD LIKE 'N76%' THEN
                   172
                  WHEN LOAN_PURPOSE_CD LIKE 'N77%' THEN
                   173
                  WHEN LOAN_PURPOSE_CD LIKE 'N78%' THEN
                   174
                  WHEN LOAN_PURPOSE_CD LIKE 'N79%' THEN
                   491
                /* WHEN LOAN_PURPOSE_CD LIKE 'O79%' THEN
                175*/
                  WHEN LOAN_PURPOSE_CD LIKE 'O80%' THEN
                   175
                  WHEN LOAN_PURPOSE_CD LIKE 'O81%' THEN
                   176
                --zhoujingkun  update 20210331  缺少O82投向
                  WHEN LOAN_PURPOSE_CD LIKE 'O82%' THEN
                   177
                  WHEN LOAN_PURPOSE_CD LIKE 'P83%' THEN
                   178
                /*WHEN LOAN_PURPOSE_CD LIKE 'Q83%' THEN
                179*/
                  WHEN LOAN_PURPOSE_CD LIKE 'Q84%' THEN
                   179
                  WHEN LOAN_PURPOSE_CD LIKE 'Q85%' THEN
                   180
                  WHEN LOAN_PURPOSE_CD LIKE 'R86%' THEN
                   181
                  WHEN LOAN_PURPOSE_CD LIKE 'R87%' THEN
                   182
                  WHEN LOAN_PURPOSE_CD LIKE 'R88%' THEN
                   183
                  WHEN LOAN_PURPOSE_CD LIKE 'R89%' THEN
                   184
                  WHEN LOAN_PURPOSE_CD LIKE 'R90%' THEN
                   185
                  WHEN LOAN_PURPOSE_CD LIKE 'S91%' THEN
                   186
                  WHEN LOAN_PURPOSE_CD LIKE 'S92%' THEN
                   187
                  WHEN LOAN_PURPOSE_CD LIKE 'S93%' THEN
                   188
                  WHEN LOAN_PURPOSE_CD LIKE 'S94%' THEN
                   189
                  WHEN LOAN_PURPOSE_CD LIKE 'S95%' THEN
                   190
                  WHEN LOAN_PURPOSE_CD LIKE 'S96%' THEN
                   191
                  WHEN LOAN_PURPOSE_CD LIKE 'T96%' THEN
                   192
                END) --192
               WHEN LOAN_GRADE_CD = '3' THEN
                (CASE
                  WHEN LOAN_PURPOSE_CD LIKE 'A01%' THEN
                   193
                  WHEN LOAN_PURPOSE_CD LIKE 'A02%' THEN
                   194
                  WHEN LOAN_PURPOSE_CD LIKE 'A03%' THEN
                   195
                  WHEN LOAN_PURPOSE_CD LIKE 'A04%' THEN
                   196
                  WHEN LOAN_PURPOSE_CD LIKE 'A05%' THEN
                   197
                  WHEN LOAN_PURPOSE_CD LIKE 'B06%' THEN
                   198
                  WHEN LOAN_PURPOSE_CD LIKE 'B07%' THEN
                   199
                  WHEN LOAN_PURPOSE_CD LIKE 'B08%' THEN
                   200
                  WHEN LOAN_PURPOSE_CD LIKE 'B09%' THEN
                   201
                  WHEN LOAN_PURPOSE_CD LIKE 'B10%' THEN
                   202
                  WHEN LOAN_PURPOSE_CD LIKE 'B11%' THEN
                   203
                  WHEN LOAN_PURPOSE_CD LIKE 'B12%' THEN
                   204
                  WHEN LOAN_PURPOSE_CD LIKE 'C13%' THEN
                   205
                  WHEN LOAN_PURPOSE_CD LIKE 'C14%' THEN
                   206
                  WHEN LOAN_PURPOSE_CD LIKE 'C15%' THEN
                   207
                  WHEN LOAN_PURPOSE_CD LIKE 'C16%' THEN
                   208
                  WHEN LOAN_PURPOSE_CD LIKE 'C17%' THEN
                   209
                  WHEN LOAN_PURPOSE_CD LIKE 'C18%' THEN
                   210
                  WHEN LOAN_PURPOSE_CD LIKE 'C19%' THEN
                   211
                  WHEN LOAN_PURPOSE_CD LIKE 'C20%' THEN
                   212
                  WHEN LOAN_PURPOSE_CD LIKE 'C21%' THEN
                   213
                  WHEN LOAN_PURPOSE_CD LIKE 'C22%' THEN
                   214
                  WHEN LOAN_PURPOSE_CD LIKE 'C23%' THEN
                   215
                  WHEN LOAN_PURPOSE_CD LIKE 'C24%' THEN
                   216
                  WHEN LOAN_PURPOSE_CD LIKE 'C25%' THEN
                   217
                  WHEN LOAN_PURPOSE_CD LIKE 'C26%' THEN
                   218
                  WHEN LOAN_PURPOSE_CD LIKE 'C27%' THEN
                   219
                  WHEN LOAN_PURPOSE_CD LIKE 'C28%' THEN
                   220
                  WHEN LOAN_PURPOSE_CD LIKE 'C29%' THEN
                   221
                  WHEN LOAN_PURPOSE_CD LIKE 'C30%' THEN
                   222
                  WHEN LOAN_PURPOSE_CD LIKE 'C31%' THEN
                   223
                  WHEN LOAN_PURPOSE_CD LIKE 'C32%' THEN
                   224
                  WHEN LOAN_PURPOSE_CD LIKE 'C33%' THEN
                   225
                  WHEN LOAN_PURPOSE_CD LIKE 'C34%' THEN
                   226
                  WHEN LOAN_PURPOSE_CD LIKE 'C35%' THEN
                   227
                  WHEN LOAN_PURPOSE_CD LIKE 'C36%' THEN
                   228
                  WHEN LOAN_PURPOSE_CD LIKE 'C37%' THEN
                   229
                  WHEN LOAN_PURPOSE_CD LIKE 'C38%' THEN
                   230
                  WHEN LOAN_PURPOSE_CD LIKE 'C39%' THEN
                   231
                  WHEN LOAN_PURPOSE_CD LIKE 'C40%' THEN
                   232
                  WHEN LOAN_PURPOSE_CD LIKE 'C41%' THEN
                   233
                  WHEN LOAN_PURPOSE_CD LIKE 'C42%' THEN
                   234
                  WHEN LOAN_PURPOSE_CD LIKE 'C43%' THEN
                   235
                  WHEN LOAN_PURPOSE_CD LIKE 'D44%' THEN
                   236
                  WHEN LOAN_PURPOSE_CD LIKE 'D45%' THEN
                   237
                  WHEN LOAN_PURPOSE_CD LIKE 'D46%' THEN
                   238
                  WHEN LOAN_PURPOSE_CD LIKE 'E47%' THEN
                   239
                  WHEN LOAN_PURPOSE_CD LIKE 'E48%' THEN
                   240
                  WHEN LOAN_PURPOSE_CD LIKE 'E49%' THEN
                   241
                  WHEN LOAN_PURPOSE_CD LIKE 'E50%' THEN
                   242
                  WHEN LOAN_PURPOSE_CD LIKE 'F51%' THEN
                   243
                  WHEN LOAN_PURPOSE_CD LIKE 'F52%' THEN
                   244
                  WHEN LOAN_PURPOSE_CD LIKE 'G53%' THEN
                   245
                  WHEN LOAN_PURPOSE_CD LIKE 'G54%' THEN
                   246
                  WHEN LOAN_PURPOSE_CD LIKE 'G55%' THEN
                   247
                  WHEN LOAN_PURPOSE_CD LIKE 'G56%' THEN
                   248
                  WHEN LOAN_PURPOSE_CD LIKE 'G57%' THEN
                   249
                  WHEN LOAN_PURPOSE_CD LIKE 'G58%' THEN
                   250
                  WHEN LOAN_PURPOSE_CD LIKE 'G59%' THEN
                   251
                  WHEN LOAN_PURPOSE_CD LIKE 'G60%' THEN
                   252
                  WHEN LOAN_PURPOSE_CD LIKE 'H61%' THEN
                   253
                  WHEN LOAN_PURPOSE_CD LIKE 'H62%' THEN
                   254
                  WHEN LOAN_PURPOSE_CD LIKE 'I63%' THEN
                   255
                  WHEN LOAN_PURPOSE_CD LIKE 'I64%' THEN
                   256
                  WHEN LOAN_PURPOSE_CD LIKE 'I65%' THEN
                   257
                  WHEN LOAN_PURPOSE_CD LIKE 'J66%' THEN
                   258
                  WHEN LOAN_PURPOSE_CD LIKE 'J67%' THEN
                   259
                  WHEN LOAN_PURPOSE_CD LIKE 'J68%' THEN
                   260
                  WHEN LOAN_PURPOSE_CD LIKE 'J69%' THEN
                   261
                  WHEN LOAN_PURPOSE_CD LIKE 'K70%' THEN
                   262
                  WHEN LOAN_PURPOSE_CD LIKE 'L71%' THEN
                   263
                  WHEN LOAN_PURPOSE_CD LIKE 'L72%' THEN
                   264
                  WHEN LOAN_PURPOSE_CD LIKE 'M73%' THEN
                   265
                  WHEN LOAN_PURPOSE_CD LIKE 'M74%' THEN
                   266
                  WHEN LOAN_PURPOSE_CD LIKE 'M75%' THEN
                   267
                  WHEN LOAN_PURPOSE_CD LIKE 'N76%' THEN
                   268
                  WHEN LOAN_PURPOSE_CD LIKE 'N77%' THEN
                   269
                  WHEN LOAN_PURPOSE_CD LIKE 'N78%' THEN
                   270
                  WHEN LOAN_PURPOSE_CD LIKE 'N79%' THEN
                   492
                /*WHEN LOAN_PURPOSE_CD LIKE 'O79%' THEN
                271*/
                  WHEN LOAN_PURPOSE_CD LIKE 'O80%' THEN
                   271
                  WHEN LOAN_PURPOSE_CD LIKE 'O81%' THEN
                   272
                --zhoujingkun  update 20210331  缺少O82投向
                  WHEN LOAN_PURPOSE_CD LIKE 'O82%' THEN
                   273
                  WHEN LOAN_PURPOSE_CD LIKE 'P83%' THEN
                   274
                /*WHEN LOAN_PURPOSE_CD LIKE 'Q83%' THEN
                275*/
                  WHEN LOAN_PURPOSE_CD LIKE 'Q84%' THEN
                   275
                  WHEN LOAN_PURPOSE_CD LIKE 'Q85%' THEN
                   276
                  WHEN LOAN_PURPOSE_CD LIKE 'R86%' THEN
                   277
                  WHEN LOAN_PURPOSE_CD LIKE 'R87%' THEN
                   278
                  WHEN LOAN_PURPOSE_CD LIKE 'R88%' THEN
                   279
                  WHEN LOAN_PURPOSE_CD LIKE 'R89%' THEN
                   280
                  WHEN LOAN_PURPOSE_CD LIKE 'R90%' THEN
                   281
                  WHEN LOAN_PURPOSE_CD LIKE 'S91%' THEN
                   282
                  WHEN LOAN_PURPOSE_CD LIKE 'S92%' THEN
                   283
                  WHEN LOAN_PURPOSE_CD LIKE 'S93%' THEN
                   284
                  WHEN LOAN_PURPOSE_CD LIKE 'S94%' THEN
                   285
                  WHEN LOAN_PURPOSE_CD LIKE 'S95%' THEN
                   286
                  WHEN LOAN_PURPOSE_CD LIKE 'S96%' THEN
                   287
                  WHEN LOAN_PURPOSE_CD LIKE 'T96%' THEN
                   288
                END) --288
               WHEN LOAN_GRADE_CD = '4' THEN
                (CASE
                  WHEN LOAN_PURPOSE_CD LIKE 'A01%' THEN
                   289
                  WHEN LOAN_PURPOSE_CD LIKE 'A02%' THEN
                   290
                  WHEN LOAN_PURPOSE_CD LIKE 'A03%' THEN
                   291
                  WHEN LOAN_PURPOSE_CD LIKE 'A04%' THEN
                   292
                  WHEN LOAN_PURPOSE_CD LIKE 'A05%' THEN
                   293
                  WHEN LOAN_PURPOSE_CD LIKE 'B06%' THEN
                   294
                  WHEN LOAN_PURPOSE_CD LIKE 'B07%' THEN
                   295
                  WHEN LOAN_PURPOSE_CD LIKE 'B08%' THEN
                   296
                  WHEN LOAN_PURPOSE_CD LIKE 'B09%' THEN
                   297
                  WHEN LOAN_PURPOSE_CD LIKE 'B10%' THEN
                   298
                  WHEN LOAN_PURPOSE_CD LIKE 'B11%' THEN
                   299
                  WHEN LOAN_PURPOSE_CD LIKE 'B12%' THEN
                   300
                  WHEN LOAN_PURPOSE_CD LIKE 'C13%' THEN
                   301
                  WHEN LOAN_PURPOSE_CD LIKE 'C14%' THEN
                   302
                  WHEN LOAN_PURPOSE_CD LIKE 'C15%' THEN
                   303
                  WHEN LOAN_PURPOSE_CD LIKE 'C16%' THEN
                   304
                  WHEN LOAN_PURPOSE_CD LIKE 'C17%' THEN
                   305
                  WHEN LOAN_PURPOSE_CD LIKE 'C18%' THEN
                   306
                  WHEN LOAN_PURPOSE_CD LIKE 'C19%' THEN
                   307
                  WHEN LOAN_PURPOSE_CD LIKE 'C20%' THEN
                   308
                  WHEN LOAN_PURPOSE_CD LIKE 'C21%' THEN
                   309
                  WHEN LOAN_PURPOSE_CD LIKE 'C22%' THEN
                   310
                  WHEN LOAN_PURPOSE_CD LIKE 'C23%' THEN
                   311
                  WHEN LOAN_PURPOSE_CD LIKE 'C24%' THEN
                   312
                  WHEN LOAN_PURPOSE_CD LIKE 'C25%' THEN
                   313
                  WHEN LOAN_PURPOSE_CD LIKE 'C26%' THEN
                   314
                  WHEN LOAN_PURPOSE_CD LIKE 'C27%' THEN
                   315
                  WHEN LOAN_PURPOSE_CD LIKE 'C28%' THEN
                   316
                  WHEN LOAN_PURPOSE_CD LIKE 'C29%' THEN
                   317
                  WHEN LOAN_PURPOSE_CD LIKE 'C30%' THEN
                   318
                  WHEN LOAN_PURPOSE_CD LIKE 'C31%' THEN
                   319
                  WHEN LOAN_PURPOSE_CD LIKE 'C32%' THEN
                   320
                  WHEN LOAN_PURPOSE_CD LIKE 'C33%' THEN
                   321
                  WHEN LOAN_PURPOSE_CD LIKE 'C34%' THEN
                   322
                  WHEN LOAN_PURPOSE_CD LIKE 'C35%' THEN
                   323
                  WHEN LOAN_PURPOSE_CD LIKE 'C36%' THEN
                   324
                  WHEN LOAN_PURPOSE_CD LIKE 'C37%' THEN
                   325
                  WHEN LOAN_PURPOSE_CD LIKE 'C38%' THEN
                   326
                  WHEN LOAN_PURPOSE_CD LIKE 'C39%' THEN
                   327
                  WHEN LOAN_PURPOSE_CD LIKE 'C40%' THEN
                   328
                  WHEN LOAN_PURPOSE_CD LIKE 'C41%' THEN
                   329
                  WHEN LOAN_PURPOSE_CD LIKE 'C42%' THEN
                   330
                  WHEN LOAN_PURPOSE_CD LIKE 'C43%' THEN
                   331
                  WHEN LOAN_PURPOSE_CD LIKE 'D44%' THEN
                   332
                  WHEN LOAN_PURPOSE_CD LIKE 'D45%' THEN
                   333
                  WHEN LOAN_PURPOSE_CD LIKE 'D46%' THEN
                   334
                  WHEN LOAN_PURPOSE_CD LIKE 'E47%' THEN
                   335
                  WHEN LOAN_PURPOSE_CD LIKE 'E48%' THEN
                   336
                  WHEN LOAN_PURPOSE_CD LIKE 'E49%' THEN
                   337
                  WHEN LOAN_PURPOSE_CD LIKE 'E50%' THEN
                   338
                  WHEN LOAN_PURPOSE_CD LIKE 'F51%' THEN
                   339
                  WHEN LOAN_PURPOSE_CD LIKE 'F52%' THEN
                   340
                  WHEN LOAN_PURPOSE_CD LIKE 'G53%' THEN
                   341
                  WHEN LOAN_PURPOSE_CD LIKE 'G54%' THEN
                   342
                  WHEN LOAN_PURPOSE_CD LIKE 'G55%' THEN
                   343
                  WHEN LOAN_PURPOSE_CD LIKE 'G56%' THEN
                   344
                  WHEN LOAN_PURPOSE_CD LIKE 'G57%' THEN
                   345
                  WHEN LOAN_PURPOSE_CD LIKE 'G58%' THEN
                   346
                  WHEN LOAN_PURPOSE_CD LIKE 'G59%' THEN
                   347
                  WHEN LOAN_PURPOSE_CD LIKE 'G60%' THEN
                   348
                  WHEN LOAN_PURPOSE_CD LIKE 'H61%' THEN
                   349
                  WHEN LOAN_PURPOSE_CD LIKE 'H62%' THEN
                   350
                  WHEN LOAN_PURPOSE_CD LIKE 'I63%' THEN
                   351
                  WHEN LOAN_PURPOSE_CD LIKE 'I64%' THEN
                   352
                  WHEN LOAN_PURPOSE_CD LIKE 'I65%' THEN
                   353
                  WHEN LOAN_PURPOSE_CD LIKE 'J66%' THEN
                   354
                  WHEN LOAN_PURPOSE_CD LIKE 'J67%' THEN
                   355
                  WHEN LOAN_PURPOSE_CD LIKE 'J68%' THEN
                   356
                  WHEN LOAN_PURPOSE_CD LIKE 'J69%' THEN
                   357
                  WHEN LOAN_PURPOSE_CD LIKE 'K70%' THEN
                   358
                  WHEN LOAN_PURPOSE_CD LIKE 'L71%' THEN
                   359
                  WHEN LOAN_PURPOSE_CD LIKE 'L72%' THEN
                   360
                  WHEN LOAN_PURPOSE_CD LIKE 'M73%' THEN
                   361
                  WHEN LOAN_PURPOSE_CD LIKE 'M74%' THEN
                   362
                  WHEN LOAN_PURPOSE_CD LIKE 'M75%' THEN
                   363
                  WHEN LOAN_PURPOSE_CD LIKE 'N76%' THEN
                   364
                  WHEN LOAN_PURPOSE_CD LIKE 'N77%' THEN
                   365
                  WHEN LOAN_PURPOSE_CD LIKE 'N78%' THEN
                   366
                  WHEN LOAN_PURPOSE_CD LIKE 'N79%' THEN
                   493
                /*WHEN LOAN_PURPOSE_CD LIKE 'O79%' THEN
                367*/
                  WHEN LOAN_PURPOSE_CD LIKE 'O80%' THEN
                   367
                  WHEN LOAN_PURPOSE_CD LIKE 'O81%' THEN
                   368
                --zhoujingkun  update 20210331  缺少O82投向
                  WHEN LOAN_PURPOSE_CD LIKE 'O82%' THEN
                   369
                  WHEN LOAN_PURPOSE_CD LIKE 'P83%' THEN
                   370
                /* WHEN LOAN_PURPOSE_CD LIKE 'Q83%' THEN
                371*/
                  WHEN LOAN_PURPOSE_CD LIKE 'Q84%' THEN
                   371
                  WHEN LOAN_PURPOSE_CD LIKE 'Q85%' THEN
                   372
                  WHEN LOAN_PURPOSE_CD LIKE 'R86%' THEN
                   373
                  WHEN LOAN_PURPOSE_CD LIKE 'R87%' THEN
                   374
                  WHEN LOAN_PURPOSE_CD LIKE 'R88%' THEN
                   375
                  WHEN LOAN_PURPOSE_CD LIKE 'R89%' THEN
                   376
                  WHEN LOAN_PURPOSE_CD LIKE 'R90%' THEN
                   377
                  WHEN LOAN_PURPOSE_CD LIKE 'S91%' THEN
                   378
                  WHEN LOAN_PURPOSE_CD LIKE 'S92%' THEN
                   379
                  WHEN LOAN_PURPOSE_CD LIKE 'S93%' THEN
                   380
                  WHEN LOAN_PURPOSE_CD LIKE 'S94%' THEN
                   381
                  WHEN LOAN_PURPOSE_CD LIKE 'S95%' THEN
                   382
                  WHEN LOAN_PURPOSE_CD LIKE 'S96%' THEN
                   383
                  WHEN LOAN_PURPOSE_CD LIKE 'T96%' THEN
                   384
                END) --384
               WHEN LOAN_GRADE_CD = '5' THEN
                (CASE
                  WHEN LOAN_PURPOSE_CD LIKE 'A01%' THEN
                   385
                  WHEN LOAN_PURPOSE_CD LIKE 'A02%' THEN
                   386
                  WHEN LOAN_PURPOSE_CD LIKE 'A03%' THEN
                   387
                  WHEN LOAN_PURPOSE_CD LIKE 'A04%' THEN
                   388
                  WHEN LOAN_PURPOSE_CD LIKE 'A05%' THEN
                   389
                  WHEN LOAN_PURPOSE_CD LIKE 'B06%' THEN
                   390
                  WHEN LOAN_PURPOSE_CD LIKE 'B07%' THEN
                   391
                  WHEN LOAN_PURPOSE_CD LIKE 'B08%' THEN
                   392
                  WHEN LOAN_PURPOSE_CD LIKE 'B09%' THEN
                   393
                  WHEN LOAN_PURPOSE_CD LIKE 'B10%' THEN
                   394
                  WHEN LOAN_PURPOSE_CD LIKE 'B11%' THEN
                   395
                  WHEN LOAN_PURPOSE_CD LIKE 'B12%' THEN
                   396
                  WHEN LOAN_PURPOSE_CD LIKE 'C13%' THEN
                   397
                  WHEN LOAN_PURPOSE_CD LIKE 'C14%' THEN
                   398
                  WHEN LOAN_PURPOSE_CD LIKE 'C15%' THEN
                   399
                  WHEN LOAN_PURPOSE_CD LIKE 'C16%' THEN
                   400
                  WHEN LOAN_PURPOSE_CD LIKE 'C17%' THEN
                   401
                  WHEN LOAN_PURPOSE_CD LIKE 'C18%' THEN
                   402
                  WHEN LOAN_PURPOSE_CD LIKE 'C19%' THEN
                   403
                  WHEN LOAN_PURPOSE_CD LIKE 'C20%' THEN
                   404
                  WHEN LOAN_PURPOSE_CD LIKE 'C21%' THEN
                   405
                  WHEN LOAN_PURPOSE_CD LIKE 'C22%' THEN
                   406
                  WHEN LOAN_PURPOSE_CD LIKE 'C23%' THEN
                   407
                  WHEN LOAN_PURPOSE_CD LIKE 'C24%' THEN
                   408
                  WHEN LOAN_PURPOSE_CD LIKE 'C25%' THEN
                   409
                  WHEN LOAN_PURPOSE_CD LIKE 'C26%' THEN
                   410
                  WHEN LOAN_PURPOSE_CD LIKE 'C27%' THEN
                   411
                  WHEN LOAN_PURPOSE_CD LIKE 'C28%' THEN
                   412
                  WHEN LOAN_PURPOSE_CD LIKE 'C29%' THEN
                   413
                  WHEN LOAN_PURPOSE_CD LIKE 'C30%' THEN
                   414
                  WHEN LOAN_PURPOSE_CD LIKE 'C31%' THEN
                   415
                  WHEN LOAN_PURPOSE_CD LIKE 'C32%' THEN
                   416
                  WHEN LOAN_PURPOSE_CD LIKE 'C33%' THEN
                   417
                  WHEN LOAN_PURPOSE_CD LIKE 'C34%' THEN
                   418
                  WHEN LOAN_PURPOSE_CD LIKE 'C35%' THEN
                   419
                  WHEN LOAN_PURPOSE_CD LIKE 'C36%' THEN
                   420
                  WHEN LOAN_PURPOSE_CD LIKE 'C37%' THEN
                   421
                  WHEN LOAN_PURPOSE_CD LIKE 'C38%' THEN
                   422
                  WHEN LOAN_PURPOSE_CD LIKE 'C39%' THEN
                   423
                  WHEN LOAN_PURPOSE_CD LIKE 'C40%' THEN
                   424
                  WHEN LOAN_PURPOSE_CD LIKE 'C41%' THEN
                   425
                  WHEN LOAN_PURPOSE_CD LIKE 'C42%' THEN
                   426
                  WHEN LOAN_PURPOSE_CD LIKE 'C43%' THEN
                   427
                  WHEN LOAN_PURPOSE_CD LIKE 'D44%' THEN
                   428
                  WHEN LOAN_PURPOSE_CD LIKE 'D45%' THEN
                   429
                  WHEN LOAN_PURPOSE_CD LIKE 'D46%' THEN
                   430
                  WHEN LOAN_PURPOSE_CD LIKE 'E47%' THEN
                   431
                  WHEN LOAN_PURPOSE_CD LIKE 'E48%' THEN
                   432
                  WHEN LOAN_PURPOSE_CD LIKE 'E49%' THEN
                   433
                  WHEN LOAN_PURPOSE_CD LIKE 'E50%' THEN
                   434
                  WHEN LOAN_PURPOSE_CD LIKE 'F51%' THEN
                   435
                  WHEN LOAN_PURPOSE_CD LIKE 'F52%' THEN
                   436
                  WHEN LOAN_PURPOSE_CD LIKE 'G53%' THEN
                   437
                  WHEN LOAN_PURPOSE_CD LIKE 'G54%' THEN
                   438
                  WHEN LOAN_PURPOSE_CD LIKE 'G55%' THEN
                   439
                  WHEN LOAN_PURPOSE_CD LIKE 'G56%' THEN
                   440
                  WHEN LOAN_PURPOSE_CD LIKE 'G57%' THEN
                   441
                  WHEN LOAN_PURPOSE_CD LIKE 'G58%' THEN
                   442
                  WHEN LOAN_PURPOSE_CD LIKE 'G59%' THEN
                   443
                  WHEN LOAN_PURPOSE_CD LIKE 'G60%' THEN
                   444
                  WHEN LOAN_PURPOSE_CD LIKE 'H61%' THEN
                   445
                  WHEN LOAN_PURPOSE_CD LIKE 'H62%' THEN
                   446
                  WHEN LOAN_PURPOSE_CD LIKE 'I63%' THEN
                   447
                  WHEN LOAN_PURPOSE_CD LIKE 'I64%' THEN
                   448
                  WHEN LOAN_PURPOSE_CD LIKE 'I65%' THEN
                   449
                  WHEN LOAN_PURPOSE_CD LIKE 'J66%' THEN
                   450
                  WHEN LOAN_PURPOSE_CD LIKE 'J67%' THEN
                   451
                  WHEN LOAN_PURPOSE_CD LIKE 'J68%' THEN
                   452
                  WHEN LOAN_PURPOSE_CD LIKE 'J69%' THEN
                   453
                  WHEN LOAN_PURPOSE_CD LIKE 'K70%' THEN
                   454
                  WHEN LOAN_PURPOSE_CD LIKE 'L71%' THEN
                   455
                  WHEN LOAN_PURPOSE_CD LIKE 'L72%' THEN
                   456
                  WHEN LOAN_PURPOSE_CD LIKE 'M73%' THEN
                   457
                  WHEN LOAN_PURPOSE_CD LIKE 'M74%' THEN
                   458
                  WHEN LOAN_PURPOSE_CD LIKE 'M75%' THEN
                   459
                  WHEN LOAN_PURPOSE_CD LIKE 'N76%' THEN
                   460
                  WHEN LOAN_PURPOSE_CD LIKE 'N77%' THEN
                   461
                  WHEN LOAN_PURPOSE_CD LIKE 'N78%' THEN
                   462
                  WHEN LOAN_PURPOSE_CD LIKE 'N79%' THEN
                   494
                /*WHEN LOAN_PURPOSE_CD LIKE 'O79%' THEN
                463*/
                  WHEN LOAN_PURPOSE_CD LIKE 'O80%' THEN
                   463
                  WHEN LOAN_PURPOSE_CD LIKE 'O81%' THEN
                   464
                --zhoujingkun  update 20210331  缺少O82投向
                  WHEN LOAN_PURPOSE_CD LIKE 'O82%' THEN
                   465
                  WHEN LOAN_PURPOSE_CD LIKE 'P83%' THEN
                   466
                /*WHEN LOAN_PURPOSE_CD LIKE 'Q83%' THEN
                467*/
                  WHEN LOAN_PURPOSE_CD LIKE 'Q84%' THEN
                   467
                  WHEN LOAN_PURPOSE_CD LIKE 'Q85%' THEN
                   468
                  WHEN LOAN_PURPOSE_CD LIKE 'R86%' THEN
                   469
                  WHEN LOAN_PURPOSE_CD LIKE 'R87%' THEN
                   470
                  WHEN LOAN_PURPOSE_CD LIKE 'R88%' THEN
                   471
                  WHEN LOAN_PURPOSE_CD LIKE 'R89%' THEN
                   472
                  WHEN LOAN_PURPOSE_CD LIKE 'R90%' THEN
                   473
                  WHEN LOAN_PURPOSE_CD LIKE 'S91%' THEN
                   474
                  WHEN LOAN_PURPOSE_CD LIKE 'S92%' THEN
                   475
                  WHEN LOAN_PURPOSE_CD LIKE 'S93%' THEN
                   476
                  WHEN LOAN_PURPOSE_CD LIKE 'S94%' THEN
                   477
                  WHEN LOAN_PURPOSE_CD LIKE 'S95%' THEN
                   478
                  WHEN LOAN_PURPOSE_CD LIKE 'S96%' THEN
                   479
                  WHEN LOAN_PURPOSE_CD LIKE 'T96%' THEN
                   480
                END) --480
             END COLLECT_TYPE,
             NVL(LOAN_ACCT_BAL, 0) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_LOAN A
       WHERE --ITEM_CD IN ('130101', '130104')
         SUBSTR(ITEM_CD,1,6) IN ('130101', '130104')
         AND FUND_USE_LOC_CD = 'I'
         AND DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND SUBSTR(LOAN_PURPOSE_CD, 1, 3) IN
             ('A01',
              'A02',
              'A03',
              'A04',
              'A05',
              'B06',
              'B07',
              'B08',
              'B09',
              'B10',
              'B11',
              'B12',
              'C13',
              'C14',
              'C15',
              'C16',
              'C17',
              'C18',
              'C19',
              'C20',
              'C21',
              'C22',
              'C23',
              'C24',
              'C25',
              'C26',
              'C27',
              'C28',
              'C29',
              'C30',
              'C31',
              'C32',
              'C33',
              'C34',
              'C35',
              'C36',
              'C37',
              'C38',
              'C39',
              'C40',
              'C41',
              'C42',
              'C43',
              'D44',
              'D45',
              'D46',
              'E47',
              'E48',
              'E49',
              'E50',
              'F51',
              'F52',
              'G53',
              'G54',
              'G55',
              'G56',
              'G57',
              'G58',
              'G59',
              'G60',
              'H61',
              'H62',
              'I63',
              'I64',
              'I65',
              'J66',
              'J67',
              'J68',
              'J69',
              'K70',
              'L71',
              'L72',
              'M73',
              'M74',
              'M75',
              'N76',
              'N77',
              'N78',
              'N79',
              -- 'O79',
              'O80',
              'O81',
              'O82',
              'P83',
              'Q83',
              'Q84',
              'Q85',
              'R85',
              'R86',
              'R87',
              'R88',
              'R89',
              'R90',
              'S90',
              'S91',
              'S92',
              'S93',
              'S94',
              'S95',
              'S96',
              'T96');

COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G1101' AS REP_NUM,
             CASE
               WHEN COLLECT_TYPE = 1 THEN
                'G11_1_2.1.1.C.2021'
               WHEN COLLECT_TYPE = 2 THEN
                'G11_1_2.1.2.C.2021'
               WHEN COLLECT_TYPE = 3 THEN
                'G11_1_2.1.3.C.2021'
               WHEN COLLECT_TYPE = 4 THEN
                'G11_1_2.1.4.C.2021'
               WHEN COLLECT_TYPE = 5 THEN
                'G11_1_2.1.5.C.2021'
               WHEN COLLECT_TYPE = 6 THEN
                'G11_1_2.2.1.C.2021'
               WHEN COLLECT_TYPE = 7 THEN
                'G11_1_2.2.2.C.2021'
               WHEN COLLECT_TYPE = 8 THEN
                'G11_1_2.2.3.C.2021'
               WHEN COLLECT_TYPE = 9 THEN
                'G11_1_2.2.4.C.2021'
               WHEN COLLECT_TYPE = 10 THEN
                'G11_1_2.2.5.C.2021'
               WHEN COLLECT_TYPE = 11 THEN
                'G11_1_2.2.6.C.2021'
               WHEN COLLECT_TYPE = 12 THEN
                'G11_1_2.2.7.C.2021'
               WHEN COLLECT_TYPE = 13 THEN
                'G11_1_2.3.1.C.2021'
               WHEN COLLECT_TYPE = 14 THEN
                'G11_1_2.3.2.C.2021'
               WHEN COLLECT_TYPE = 15 THEN
                'G11_1_2.3.3.C.2021'
               WHEN COLLECT_TYPE = 16 THEN
                'G11_1_2.3.4.C.2021'
               WHEN COLLECT_TYPE = 17 THEN
                'G11_1_2.3.5.C.2021'
               WHEN COLLECT_TYPE = 18 THEN
                'G11_1_2.3.6.C.2021'
               WHEN COLLECT_TYPE = 19 THEN
                'G11_1_2.3.7.C.2021'
               WHEN COLLECT_TYPE = 20 THEN
                'G11_1_2.3.8.C.2021'
               WHEN COLLECT_TYPE = 21 THEN
                'G11_1_2.3.9.C.2021'
               WHEN COLLECT_TYPE = 22 THEN
                'G11_1_2.3.10.C.2021'
               WHEN COLLECT_TYPE = 23 THEN
                'G11_1_2.3.11.C.2021'
               WHEN COLLECT_TYPE = 24 THEN
                'G11_1_2.3.12.C.2021'
               WHEN COLLECT_TYPE = 25 THEN
                'G11_1_2.3.13.C.2021'
               WHEN COLLECT_TYPE = 26 THEN
                'G11_1_2.3.14.C.2021'
               WHEN COLLECT_TYPE = 27 THEN
                'G11_1_2.3.15.C.2021'
               WHEN COLLECT_TYPE = 28 THEN
                'G11_1_2.3.16.C.2021'
               WHEN COLLECT_TYPE = 29 THEN
                'G11_1_2.3.17.C.2021'
               WHEN COLLECT_TYPE = 30 THEN
                'G11_1_2.3.18.C.2021'
               WHEN COLLECT_TYPE = 31 THEN
                'G11_1_2.3.19.C.2021'
               WHEN COLLECT_TYPE = 32 THEN
                'G11_1_2.3.20.C.2021'
               WHEN COLLECT_TYPE = 33 THEN
                'G11_1_2.3.21.C.2021'
               WHEN COLLECT_TYPE = 34 THEN
                'G11_1_2.3.22.C.2021'
               WHEN COLLECT_TYPE = 35 THEN
                'G11_1_2.3.23.C.2021'
               WHEN COLLECT_TYPE = 36 THEN
                'G11_1_2.3.24.C.2021'
               WHEN COLLECT_TYPE = 37 THEN
                'G11_1_2.3.25.C.2021'
               WHEN COLLECT_TYPE = 38 THEN
                'G11_1_2.3.26.C.2021'
               WHEN COLLECT_TYPE = 39 THEN
                'G11_1_2.3.27.C.2021'
               WHEN COLLECT_TYPE = 40 THEN
                'G11_1_2.3.28.C.2021'
               WHEN COLLECT_TYPE = 41 THEN
                'G11_1_2.3.29.C.2021'
               WHEN COLLECT_TYPE = 42 THEN
                'G11_1_2.3.30.C.2021'
               WHEN COLLECT_TYPE = 43 THEN
                'G11_1_2.3.31.C.2021'
               WHEN COLLECT_TYPE = 44 THEN
                'G11_1_2.4.1.C.2021'
               WHEN COLLECT_TYPE = 45 THEN
                'G11_1_2.4.2.C.2021'
               WHEN COLLECT_TYPE = 46 THEN
                'G11_1_2.4.3.C.2021'
               WHEN COLLECT_TYPE = 47 THEN
                'G11_1_2.5.1.C.2021'
               WHEN COLLECT_TYPE = 48 THEN
                'G11_1_2.5.2.C.2021'
               WHEN COLLECT_TYPE = 49 THEN
                'G11_1_2.5.3.C.2021'
               WHEN COLLECT_TYPE = 50 THEN
                'G11_1_2.5.4.C.2021'
               WHEN COLLECT_TYPE = 51 THEN
                'G11_1_2.6.1.C.2021'
               WHEN COLLECT_TYPE = 52 THEN
                'G11_1_2.6.2.C.2021'
               WHEN COLLECT_TYPE = 53 THEN
                'G11_1_2.7.1.C.2021'
               WHEN COLLECT_TYPE = 54 THEN
                'G11_1_2.7.2.C.2021'
               WHEN COLLECT_TYPE = 55 THEN
                'G11_1_2.7.3.C.2021'
               WHEN COLLECT_TYPE = 56 THEN
                'G11_1_2.7.4.C.2021'
               WHEN COLLECT_TYPE = 57 THEN
                'G11_1_2.7.5.C.2021'
               WHEN COLLECT_TYPE = 58 THEN
                'G11_1_2.7.6.C.2021'
               WHEN COLLECT_TYPE = 59 THEN
                'G11_1_2.7.7.C.2021'
               WHEN COLLECT_TYPE = 60 THEN
                'G11_1_2.7.8.C.2021'
               WHEN COLLECT_TYPE = 61 THEN
                'G11_1_2.8.1.C.2021'
               WHEN COLLECT_TYPE = 62 THEN
                'G11_1_2.8.2.C.2021'
               WHEN COLLECT_TYPE = 63 THEN
                'G11_1_2.9.1.C.2021'
               WHEN COLLECT_TYPE = 64 THEN
                'G11_1_2.9.2.C.2021'
               WHEN COLLECT_TYPE = 65 THEN
                'G11_1_2.9.3.C.2021'
               WHEN COLLECT_TYPE = 66 THEN
                'G11_1_2.10.1.C.2021'
               WHEN COLLECT_TYPE = 67 THEN
                'G11_1_2.10.2.C.2021'
               WHEN COLLECT_TYPE = 68 THEN
                'G11_1_2.10.3.C.2021'
               WHEN COLLECT_TYPE = 69 THEN
                'G11_1_2.10.4.C.2021'
               WHEN COLLECT_TYPE = 70 THEN
                'G11_1_2.11.1.C.2021'
               WHEN COLLECT_TYPE = 71 THEN
                'G11_1_2.12.1.C.2021'
               WHEN COLLECT_TYPE = 72 THEN
                'G11_1_2.12.2.C.2021'
               WHEN COLLECT_TYPE = 73 THEN
                'G11_1_2.13.1.C.2021'
               WHEN COLLECT_TYPE = 74 THEN
                'G11_1_2.13.2.C.2021'
               WHEN COLLECT_TYPE = 75 THEN
                'G11_1_2.13.3.C.2021'
               WHEN COLLECT_TYPE = 76 THEN
                'G11_1_2.14.1.C.2021'
               WHEN COLLECT_TYPE = 77 THEN
                'G11_1_2.14.2.C.2021'
               WHEN COLLECT_TYPE = 78 THEN
                'G11_1_2.14.3.C.2021'
               WHEN COLLECT_TYPE = 490 THEN
                'G11_1_2.14.4.C.2021'
             --'G11_1_2.14.4.C.2021' 过程中没有，但是取数报表有？
               WHEN COLLECT_TYPE = 79 THEN
                'G11_1_2.15.1.C.2021'
               WHEN COLLECT_TYPE = 80 THEN
                'G11_1_2.15.2.C.2021'
               WHEN COLLECT_TYPE = 81 THEN
                'G11_1_2.15.3.C.2021'
               WHEN COLLECT_TYPE = 82 THEN
                'G11_1_2.16.1.C.2021'
               WHEN COLLECT_TYPE = 83 THEN
                'G11_1_2.17.1.C.2021'
               WHEN COLLECT_TYPE = 84 THEN
                'G11_1_2.17.2.C.2021'
               WHEN COLLECT_TYPE = 85 THEN
                'G11_1_2.18.1.C.2021'
               WHEN COLLECT_TYPE = 86 THEN
                'G11_1_2.18.2.C.2021'
               WHEN COLLECT_TYPE = 87 THEN
                'G11_1_2.18.3.C.2021'
               WHEN COLLECT_TYPE = 88 THEN
                'G11_1_2.18.4.C.2021'
               WHEN COLLECT_TYPE = 89 THEN
                'G11_1_2.18.5.C.2021'
               WHEN COLLECT_TYPE = 90 THEN
                'G11_1_2.19.1.C.2021'
               WHEN COLLECT_TYPE = 91 THEN
                'G11_1_2.19.2.C.2021'
               WHEN COLLECT_TYPE = 92 THEN
                'G11_1_2.19.3.C.2021'
               WHEN COLLECT_TYPE = 93 THEN
                'G11_1_2.19.4.C.2021'
               WHEN COLLECT_TYPE = 94 THEN
                'G11_1_2.19.5.C.2021'
               WHEN COLLECT_TYPE = 95 THEN
                'G11_1_2.19.6.C.2021'
               WHEN COLLECT_TYPE = 96 THEN
                'G11_1_2.20.1.C.2021'
               WHEN COLLECT_TYPE = 97 THEN
                'G11_1_2.1.1.D.2021'
               WHEN COLLECT_TYPE = 98 THEN
                'G11_1_2.1.2.D.2021'
               WHEN COLLECT_TYPE = 99 THEN
                'G11_1_2.1.3.D.2021'
               WHEN COLLECT_TYPE = 100 THEN
                'G11_1_2.1.4.D.2021'
               WHEN COLLECT_TYPE = 101 THEN
                'G11_1_2.1.5.D.2021'
               WHEN COLLECT_TYPE = 102 THEN
                'G11_1_2.2.1.D.2021'
               WHEN COLLECT_TYPE = 103 THEN
                'G11_1_2.2.2.D.2021'
               WHEN COLLECT_TYPE = 104 THEN
                'G11_1_2.2.3.D.2021'
               WHEN COLLECT_TYPE = 105 THEN
                'G11_1_2.2.4.D.2021'
               WHEN COLLECT_TYPE = 106 THEN
                'G11_1_2.2.5.D.2021'
               WHEN COLLECT_TYPE = 107 THEN
                'G11_1_2.2.6.D.2021'
               WHEN COLLECT_TYPE = 108 THEN
                'G11_1_2.2.7.D.2021'
               WHEN COLLECT_TYPE = 109 THEN
                'G11_1_2.3.1.D.2021'
               WHEN COLLECT_TYPE = 110 THEN
                'G11_1_2.3.2.D.2021'
               WHEN COLLECT_TYPE = 111 THEN
                'G11_1_2.3.3.D.2021'
               WHEN COLLECT_TYPE = 112 THEN
                'G11_1_2.3.4.D.2021'
               WHEN COLLECT_TYPE = 113 THEN
                'G11_1_2.3.5.D.2021'
               WHEN COLLECT_TYPE = 114 THEN
                'G11_1_2.3.6.D.2021'
               WHEN COLLECT_TYPE = 115 THEN
                'G11_1_2.3.7.D.2021'
               WHEN COLLECT_TYPE = 116 THEN
                'G11_1_2.3.8.D.2021'
               WHEN COLLECT_TYPE = 117 THEN
                'G11_1_2.3.9.D.2021'
               WHEN COLLECT_TYPE = 118 THEN
                'G11_1_2.3.10.D.2021'
               WHEN COLLECT_TYPE = 119 THEN
                'G11_1_2.3.11.D.2021'
               WHEN COLLECT_TYPE = 120 THEN
                'G11_1_2.3.12.D.2021'
               WHEN COLLECT_TYPE = 121 THEN
                'G11_1_2.3.13.D.2021'
               WHEN COLLECT_TYPE = 122 THEN
                'G11_1_2.3.14.D.2021'
               WHEN COLLECT_TYPE = 123 THEN
                'G11_1_2.3.15.D.2021'
               WHEN COLLECT_TYPE = 124 THEN
                'G11_1_2.3.16.D.2021'
               WHEN COLLECT_TYPE = 125 THEN
                'G11_1_2.3.17.D.2021'
               WHEN COLLECT_TYPE = 126 THEN
                'G11_1_2.3.18.D.2021'
               WHEN COLLECT_TYPE = 127 THEN
                'G11_1_2.3.19.D.2021'
               WHEN COLLECT_TYPE = 128 THEN
                'G11_1_2.3.20.D.2021'
               WHEN COLLECT_TYPE = 129 THEN
                'G11_1_2.3.21.D.2021'
               WHEN COLLECT_TYPE = 130 THEN
                'G11_1_2.3.22.D.2021'
               WHEN COLLECT_TYPE = 131 THEN
                'G11_1_2.3.23.D.2021'
               WHEN COLLECT_TYPE = 132 THEN
                'G11_1_2.3.24.D.2021'
               WHEN COLLECT_TYPE = 133 THEN
                'G11_1_2.3.25.D.2021'
               WHEN COLLECT_TYPE = 134 THEN
                'G11_1_2.3.26.D.2021'
               WHEN COLLECT_TYPE = 135 THEN
                'G11_1_2.3.27.D.2021'
               WHEN COLLECT_TYPE = 136 THEN
                'G11_1_2.3.28.D.2021'
               WHEN COLLECT_TYPE = 137 THEN
                'G11_1_2.3.29.D.2021'
               WHEN COLLECT_TYPE = 138 THEN
                'G11_1_2.3.30.D.2021'
               WHEN COLLECT_TYPE = 139 THEN
                'G11_1_2.3.31.D.2021'
               WHEN COLLECT_TYPE = 140 THEN
                'G11_1_2.4.1.D.2021'
               WHEN COLLECT_TYPE = 141 THEN
                'G11_1_2.4.2.D.2021'
               WHEN COLLECT_TYPE = 142 THEN
                'G11_1_2.4.3.D.2021'
               WHEN COLLECT_TYPE = 143 THEN
                'G11_1_2.5.1.D.2021'
               WHEN COLLECT_TYPE = 144 THEN
                'G11_1_2.5.2.D.2021'
               WHEN COLLECT_TYPE = 145 THEN
                'G11_1_2.5.3.D.2021'
               WHEN COLLECT_TYPE = 146 THEN
                'G11_1_2.5.4.D.2021'
               WHEN COLLECT_TYPE = 147 THEN
                'G11_1_2.6.1.D.2021'
               WHEN COLLECT_TYPE = 148 THEN
                'G11_1_2.6.2.D.2021'
               WHEN COLLECT_TYPE = 149 THEN
                'G11_1_2.7.1.D.2021'
               WHEN COLLECT_TYPE = 150 THEN
                'G11_1_2.7.2.D.2021'
               WHEN COLLECT_TYPE = 151 THEN
                'G11_1_2.7.3.D.2021'
               WHEN COLLECT_TYPE = 152 THEN
                'G11_1_2.7.4.D.2021'
               WHEN COLLECT_TYPE = 153 THEN
                'G11_1_2.7.5.D.2021'
               WHEN COLLECT_TYPE = 154 THEN
                'G11_1_2.7.6.D.2021'
               WHEN COLLECT_TYPE = 155 THEN
                'G11_1_2.7.7.D.2021'
               WHEN COLLECT_TYPE = 156 THEN
                'G11_1_2.7.8.D.2021'
               WHEN COLLECT_TYPE = 157 THEN
                'G11_1_2.8.1.D.2021'
               WHEN COLLECT_TYPE = 158 THEN
                'G11_1_2.8.2.D.2021'
               WHEN COLLECT_TYPE = 159 THEN
                'G11_1_2.9.1.D.2021'
               WHEN COLLECT_TYPE = 160 THEN
                'G11_1_2.9.2.D.2021'
               WHEN COLLECT_TYPE = 161 THEN
                'G11_1_2.9.3.D.2021'
               WHEN COLLECT_TYPE = 162 THEN
                'G11_1_2.10.1.D.2021'
               WHEN COLLECT_TYPE = 163 THEN
                'G11_1_2.10.2.D.2021'
               WHEN COLLECT_TYPE = 164 THEN
                'G11_1_2.10.3.D.2021'
               WHEN COLLECT_TYPE = 165 THEN
                'G11_1_2.10.4.D.2021'
               WHEN COLLECT_TYPE = 166 THEN
                'G11_1_2.11.1.D.2021'
               WHEN COLLECT_TYPE = 167 THEN
                'G11_1_2.12.1.D.2021'
               WHEN COLLECT_TYPE = 168 THEN
                'G11_1_2.12.2.D.2021'
               WHEN COLLECT_TYPE = 169 THEN
                'G11_1_2.13.1.D.2021'
               WHEN COLLECT_TYPE = 170 THEN
                'G11_1_2.13.2.D.2021'
               WHEN COLLECT_TYPE = 171 THEN
                'G11_1_2.13.3.D.2021'
               WHEN COLLECT_TYPE = 172 THEN
                'G11_1_2.14.1.D.2021'
               WHEN COLLECT_TYPE = 173 THEN
                'G11_1_2.14.2.D.2021'
               WHEN COLLECT_TYPE = 174 THEN
                'G11_1_2.14.3.D.2021'
               WHEN COLLECT_TYPE = 491 THEN
                'G11_1_2.14.4.D.2021'
               WHEN COLLECT_TYPE = 175 THEN
                'G11_1_2.15.1.D.2021'
               WHEN COLLECT_TYPE = 176 THEN
                'G11_1_2.15.2.D.2021'
               WHEN COLLECT_TYPE = 177 THEN
                'G11_1_2.15.3.D.2021'
               WHEN COLLECT_TYPE = 178 THEN
                'G11_1_2.16.1.D.2021'
               WHEN COLLECT_TYPE = 179 THEN
                'G11_1_2.17.1.D.2021'
               WHEN COLLECT_TYPE = 180 THEN
                'G11_1_2.17.2.D.2021'
               WHEN COLLECT_TYPE = 181 THEN
                'G11_1_2.18.1.D.2021'
               WHEN COLLECT_TYPE = 182 THEN
                'G11_1_2.18.2.D.2021'
               WHEN COLLECT_TYPE = 183 THEN
                'G11_1_2.18.3.D.2021'
               WHEN COLLECT_TYPE = 184 THEN
                'G11_1_2.18.4.D.2021'
               WHEN COLLECT_TYPE = 185 THEN
                'G11_1_2.18.5.D.2021'
               WHEN COLLECT_TYPE = 186 THEN
                'G11_1_2.19.1.D.2021'
               WHEN COLLECT_TYPE = 187 THEN
                'G11_1_2.19.2.D.2021'
               WHEN COLLECT_TYPE = 188 THEN
                'G11_1_2.19.3.D.2021'
               WHEN COLLECT_TYPE = 189 THEN
                'G11_1_2.19.4.D.2021'
               WHEN COLLECT_TYPE = 190 THEN
                'G11_1_2.19.5.D.2021'
               WHEN COLLECT_TYPE = 191 THEN
                'G11_1_2.19.6.D.2021'
               WHEN COLLECT_TYPE = 192 THEN
                'G11_1_2.20.1.D.2021'
               WHEN COLLECT_TYPE = 193 THEN
                'G11_1_2.1.1.F.2021'
               WHEN COLLECT_TYPE = 194 THEN
                'G11_1_2.1.2.F.2021'
               WHEN COLLECT_TYPE = 195 THEN
                'G11_1_2.1.3.F.2021'
               WHEN COLLECT_TYPE = 196 THEN
                'G11_1_2.1.4.F.2021'
               WHEN COLLECT_TYPE = 197 THEN
                'G11_1_2.1.5.F.2021'
               WHEN COLLECT_TYPE = 198 THEN
                'G11_1_2.2.1.F.2021'
               WHEN COLLECT_TYPE = 199 THEN
                'G11_1_2.2.2.F.2021'
               WHEN COLLECT_TYPE = 200 THEN
                'G11_1_2.2.3.F.2021'
               WHEN COLLECT_TYPE = 201 THEN
                'G11_1_2.2.4.F.2021'
               WHEN COLLECT_TYPE = 202 THEN
                'G11_1_2.2.5.F.2021'
               WHEN COLLECT_TYPE = 203 THEN
                'G11_1_2.2.6.F.2021'
               WHEN COLLECT_TYPE = 204 THEN
                'G11_1_2.2.7.F.2021'
               WHEN COLLECT_TYPE = 205 THEN
                'G11_1_2.3.1.F.2021'
               WHEN COLLECT_TYPE = 206 THEN
                'G11_1_2.3.2.F.2021'
               WHEN COLLECT_TYPE = 207 THEN
                'G11_1_2.3.3.F.2021'
               WHEN COLLECT_TYPE = 208 THEN
                'G11_1_2.3.4.F.2021'
               WHEN COLLECT_TYPE = 209 THEN
                'G11_1_2.3.5.F.2021'
               WHEN COLLECT_TYPE = 210 THEN
                'G11_1_2.3.6.F.2021'
               WHEN COLLECT_TYPE = 211 THEN
                'G11_1_2.3.7.F.2021'
               WHEN COLLECT_TYPE = 212 THEN
                'G11_1_2.3.8.F.2021'
               WHEN COLLECT_TYPE = 213 THEN
                'G11_1_2.3.9.F.2021'
               WHEN COLLECT_TYPE = 214 THEN
                'G11_1_2.3.10.F.2021'
               WHEN COLLECT_TYPE = 215 THEN
                'G11_1_2.3.11.F.2021'
               WHEN COLLECT_TYPE = 216 THEN
                'G11_1_2.3.12.F.2021'
               WHEN COLLECT_TYPE = 217 THEN
                'G11_1_2.3.13.F.2021'
               WHEN COLLECT_TYPE = 218 THEN
                'G11_1_2.3.14.F.2021'
               WHEN COLLECT_TYPE = 219 THEN
                'G11_1_2.3.15.F.2021'
               WHEN COLLECT_TYPE = 220 THEN
                'G11_1_2.3.16.F.2021'
               WHEN COLLECT_TYPE = 221 THEN
                'G11_1_2.3.17.F.2021'
               WHEN COLLECT_TYPE = 222 THEN
                'G11_1_2.3.18.F.2021'
               WHEN COLLECT_TYPE = 223 THEN
                'G11_1_2.3.19.F.2021'
               WHEN COLLECT_TYPE = 224 THEN
                'G11_1_2.3.20.F.2021'
               WHEN COLLECT_TYPE = 225 THEN
                'G11_1_2.3.21.F.2021'
               WHEN COLLECT_TYPE = 226 THEN
                'G11_1_2.3.22.F.2021'
               WHEN COLLECT_TYPE = 227 THEN
                'G11_1_2.3.23.F.2021'
               WHEN COLLECT_TYPE = 228 THEN
                'G11_1_2.3.24.F.2021'
               WHEN COLLECT_TYPE = 229 THEN
                'G11_1_2.3.25.F.2021'
               WHEN COLLECT_TYPE = 230 THEN
                'G11_1_2.3.26.F.2021'
               WHEN COLLECT_TYPE = 231 THEN
                'G11_1_2.3.27.F.2021'
               WHEN COLLECT_TYPE = 232 THEN
                'G11_1_2.3.28.F.2021'
               WHEN COLLECT_TYPE = 233 THEN
                'G11_1_2.3.29.F.2021'
               WHEN COLLECT_TYPE = 234 THEN
                'G11_1_2.3.30.F.2021'
               WHEN COLLECT_TYPE = 235 THEN
                'G11_1_2.3.31.F.2021'
               WHEN COLLECT_TYPE = 236 THEN
                'G11_1_2.4.1.F.2021'
               WHEN COLLECT_TYPE = 237 THEN
                'G11_1_2.4.2.F.2021'
               WHEN COLLECT_TYPE = 238 THEN
                'G11_1_2.4.3.F.2021'
               WHEN COLLECT_TYPE = 239 THEN
                'G11_1_2.5.1.F.2021'
               WHEN COLLECT_TYPE = 240 THEN
                'G11_1_2.5.2.F.2021'
               WHEN COLLECT_TYPE = 241 THEN
                'G11_1_2.5.3.F.2021'
               WHEN COLLECT_TYPE = 242 THEN
                'G11_1_2.5.4.F.2021'
               WHEN COLLECT_TYPE = 243 THEN
                'G11_1_2.6.1.F.2021'
               WHEN COLLECT_TYPE = 244 THEN
                'G11_1_2.6.2.F.2021'
               WHEN COLLECT_TYPE = 245 THEN
                'G11_1_2.7.1.F.2021'
               WHEN COLLECT_TYPE = 246 THEN
                'G11_1_2.7.2.F.2021'
               WHEN COLLECT_TYPE = 247 THEN
                'G11_1_2.7.3.F.2021'
               WHEN COLLECT_TYPE = 248 THEN
                'G11_1_2.7.4.F.2021'
               WHEN COLLECT_TYPE = 249 THEN
                'G11_1_2.7.5.F.2021'
               WHEN COLLECT_TYPE = 250 THEN
                'G11_1_2.7.6.F.2021'
               WHEN COLLECT_TYPE = 251 THEN
                'G11_1_2.7.7.F.2021'
               WHEN COLLECT_TYPE = 252 THEN
                'G11_1_2.7.8.F.2021'
               WHEN COLLECT_TYPE = 253 THEN
                'G11_1_2.8.1.F.2021'
               WHEN COLLECT_TYPE = 254 THEN
                'G11_1_2.8.2.F.2021'
               WHEN COLLECT_TYPE = 255 THEN
                'G11_1_2.9.1.F.2021'
               WHEN COLLECT_TYPE = 256 THEN
                'G11_1_2.9.2.F.2021'
               WHEN COLLECT_TYPE = 257 THEN
                'G11_1_2.9.3.F.2021'
               WHEN COLLECT_TYPE = 258 THEN
                'G11_1_2.10.1.F.2021'
               WHEN COLLECT_TYPE = 259 THEN
                'G11_1_2.10.2.F.2021'
               WHEN COLLECT_TYPE = 260 THEN
                'G11_1_2.10.3.F.2021'
               WHEN COLLECT_TYPE = 261 THEN
                'G11_1_2.10.4.F.2021'
               WHEN COLLECT_TYPE = 262 THEN
                'G11_1_2.11.1.F.2021'
               WHEN COLLECT_TYPE = 263 THEN
                'G11_1_2.12.1.F.2021'
               WHEN COLLECT_TYPE = 264 THEN
                'G11_1_2.12.2.F.2021'
               WHEN COLLECT_TYPE = 265 THEN
                'G11_1_2.13.1.F.2021'
               WHEN COLLECT_TYPE = 266 THEN
                'G11_1_2.13.2.F.2021'
               WHEN COLLECT_TYPE = 267 THEN
                'G11_1_2.13.3.F.2021'
               WHEN COLLECT_TYPE = 268 THEN
                'G11_1_2.14.1.F.2021'
               WHEN COLLECT_TYPE = 269 THEN
                'G11_1_2.14.2.F.2021'
               WHEN COLLECT_TYPE = 270 THEN
                'G11_1_2.14.3.F.2021'
               WHEN COLLECT_TYPE = 492 THEN
                'G11_1_2.14.4.F.2021'
               WHEN COLLECT_TYPE = 271 THEN
                'G11_1_2.15.1.F.2021'
               WHEN COLLECT_TYPE = 272 THEN
                'G11_1_2.15.2.F.2021'
               WHEN COLLECT_TYPE = 273 THEN
                'G11_1_2.15.3.F.2021'
               WHEN COLLECT_TYPE = 274 THEN
                'G11_1_2.16.1.F.2021'
               WHEN COLLECT_TYPE = 275 THEN
                'G11_1_2.17.1.F.2021'
               WHEN COLLECT_TYPE = 276 THEN
                'G11_1_2.17.2.F.2021'
               WHEN COLLECT_TYPE = 277 THEN
                'G11_1_2.18.1.F.2021'
               WHEN COLLECT_TYPE = 278 THEN
                'G11_1_2.18.2.F.2021'
               WHEN COLLECT_TYPE = 279 THEN
                'G11_1_2.18.3.F.2021'
               WHEN COLLECT_TYPE = 280 THEN
                'G11_1_2.18.4.F.2021'
               WHEN COLLECT_TYPE = 281 THEN
                'G11_1_2.18.5.F.2021'
               WHEN COLLECT_TYPE = 282 THEN
                'G11_1_2.19.1.F.2021'
               WHEN COLLECT_TYPE = 283 THEN
                'G11_1_2.19.2.F.2021'
               WHEN COLLECT_TYPE = 284 THEN
                'G11_1_2.19.3.F.2021'
               WHEN COLLECT_TYPE = 285 THEN
                'G11_1_2.19.4.F.2021'
               WHEN COLLECT_TYPE = 286 THEN
                'G11_1_2.19.5.F.2021'
               WHEN COLLECT_TYPE = 287 THEN
                'G11_1_2.19.6.F.2021'
               WHEN COLLECT_TYPE = 288 THEN
                'G11_1_2.20.1.F.2021'
               WHEN COLLECT_TYPE = 289 THEN
                'G11_1_2.1.1.G.2021'
               WHEN COLLECT_TYPE = 290 THEN
                'G11_1_2.1.2.G.2021'
               WHEN COLLECT_TYPE = 291 THEN
                'G11_1_2.1.3.G.2021'
               WHEN COLLECT_TYPE = 292 THEN
                'G11_1_2.1.4.G.2021'
               WHEN COLLECT_TYPE = 293 THEN
                'G11_1_2.1.5.G.2021'
               WHEN COLLECT_TYPE = 294 THEN
                'G11_1_2.2.1.G.2021'
               WHEN COLLECT_TYPE = 295 THEN
                'G11_1_2.2.2.G.2021'
               WHEN COLLECT_TYPE = 296 THEN
                'G11_1_2.2.3.G.2021'
               WHEN COLLECT_TYPE = 297 THEN
                'G11_1_2.2.4.G.2021'
               WHEN COLLECT_TYPE = 298 THEN
                'G11_1_2.2.5.G.2021'
               WHEN COLLECT_TYPE = 299 THEN
                'G11_1_2.2.6.G.2021'
               WHEN COLLECT_TYPE = 300 THEN
                'G11_1_2.2.7.G.2021'
               WHEN COLLECT_TYPE = 301 THEN
                'G11_1_2.3.1.G.2021'
               WHEN COLLECT_TYPE = 302 THEN
                'G11_1_2.3.2.G.2021'
               WHEN COLLECT_TYPE = 303 THEN
                'G11_1_2.3.3.G.2021'
               WHEN COLLECT_TYPE = 304 THEN
                'G11_1_2.3.4.G.2021'
               WHEN COLLECT_TYPE = 305 THEN
                'G11_1_2.3.5.G.2021'
               WHEN COLLECT_TYPE = 306 THEN
                'G11_1_2.3.6.G.2021'
               WHEN COLLECT_TYPE = 307 THEN
                'G11_1_2.3.7.G.2021'
               WHEN COLLECT_TYPE = 308 THEN
                'G11_1_2.3.8.G.2021'
               WHEN COLLECT_TYPE = 309 THEN
                'G11_1_2.3.9.G.2021'
               WHEN COLLECT_TYPE = 310 THEN
                'G11_1_2.3.10.G.2021'
               WHEN COLLECT_TYPE = 311 THEN
                'G11_1_2.3.11.G.2021'
               WHEN COLLECT_TYPE = 312 THEN
                'G11_1_2.3.12.G.2021'
               WHEN COLLECT_TYPE = 313 THEN
                'G11_1_2.3.13.G.2021'
               WHEN COLLECT_TYPE = 314 THEN
                'G11_1_2.3.14.G.2021'
               WHEN COLLECT_TYPE = 315 THEN
                'G11_1_2.3.15.G.2021'
               WHEN COLLECT_TYPE = 316 THEN
                'G11_1_2.3.16.G.2021'
               WHEN COLLECT_TYPE = 317 THEN
                'G11_1_2.3.17.G.2021'
               WHEN COLLECT_TYPE = 318 THEN
                'G11_1_2.3.18.G.2021'
               WHEN COLLECT_TYPE = 319 THEN
                'G11_1_2.3.19.G.2021'
               WHEN COLLECT_TYPE = 320 THEN
                'G11_1_2.3.20.G.2021'
               WHEN COLLECT_TYPE = 321 THEN
                'G11_1_2.3.21.G.2021'
               WHEN COLLECT_TYPE = 322 THEN
                'G11_1_2.3.22.G.2021'
               WHEN COLLECT_TYPE = 323 THEN
                'G11_1_2.3.23.G.2021'
               WHEN COLLECT_TYPE = 324 THEN
                'G11_1_2.3.24.G.2021'
               WHEN COLLECT_TYPE = 325 THEN
                'G11_1_2.3.25.G.2021'
               WHEN COLLECT_TYPE = 326 THEN
                'G11_1_2.3.26.G.2021'
               WHEN COLLECT_TYPE = 327 THEN
                'G11_1_2.3.27.G.2021'
               WHEN COLLECT_TYPE = 328 THEN
                'G11_1_2.3.28.G.2021'
               WHEN COLLECT_TYPE = 329 THEN
                'G11_1_2.3.29.G.2021'
               WHEN COLLECT_TYPE = 330 THEN
                'G11_1_2.3.30.G.2021'
               WHEN COLLECT_TYPE = 331 THEN
                'G11_1_2.3.31.G.2021'
               WHEN COLLECT_TYPE = 332 THEN
                'G11_1_2.4.1.G.2021'
               WHEN COLLECT_TYPE = 333 THEN
                'G11_1_2.4.2.G.2021'
               WHEN COLLECT_TYPE = 334 THEN
                'G11_1_2.4.3.G.2021'
               WHEN COLLECT_TYPE = 335 THEN
                'G11_1_2.5.1.G.2021'
               WHEN COLLECT_TYPE = 336 THEN
                'G11_1_2.5.2.G.2021'
               WHEN COLLECT_TYPE = 337 THEN
                'G11_1_2.5.3.G.2021'
               WHEN COLLECT_TYPE = 338 THEN
                'G11_1_2.5.4.G.2021'
               WHEN COLLECT_TYPE = 339 THEN
                'G11_1_2.6.1.G.2021'
               WHEN COLLECT_TYPE = 340 THEN
                'G11_1_2.6.2.G.2021'
               WHEN COLLECT_TYPE = 341 THEN
                'G11_1_2.7.1.G.2021'
               WHEN COLLECT_TYPE = 342 THEN
                'G11_1_2.7.2.G.2021'
               WHEN COLLECT_TYPE = 343 THEN
                'G11_1_2.7.3.G.2021'
               WHEN COLLECT_TYPE = 344 THEN
                'G11_1_2.7.4.G.2021'
               WHEN COLLECT_TYPE = 345 THEN
                'G11_1_2.7.5.G.2021'
               WHEN COLLECT_TYPE = 346 THEN
                'G11_1_2.7.6.G.2021'
               WHEN COLLECT_TYPE = 347 THEN
                'G11_1_2.7.7.G.2021'
               WHEN COLLECT_TYPE = 348 THEN
                'G11_1_2.7.8.G.2021'
               WHEN COLLECT_TYPE = 349 THEN
                'G11_1_2.8.1.G.2021'
               WHEN COLLECT_TYPE = 350 THEN
                'G11_1_2.8.2.G.2021'
               WHEN COLLECT_TYPE = 351 THEN
                'G11_1_2.9.1.G.2021'
               WHEN COLLECT_TYPE = 352 THEN
                'G11_1_2.9.2.G.2021'
               WHEN COLLECT_TYPE = 353 THEN
                'G11_1_2.9.3.G.2021'
               WHEN COLLECT_TYPE = 354 THEN
                'G11_1_2.10.1.G.2021'
               WHEN COLLECT_TYPE = 355 THEN
                'G11_1_2.10.2.G.2021'
               WHEN COLLECT_TYPE = 356 THEN
                'G11_1_2.10.3.G.2021'
               WHEN COLLECT_TYPE = 357 THEN
                'G11_1_2.10.4.G.2021'
               WHEN COLLECT_TYPE = 358 THEN
                'G11_1_2.11.1.G.2021'
               WHEN COLLECT_TYPE = 359 THEN
                'G11_1_2.12.1.G.2021'
               WHEN COLLECT_TYPE = 360 THEN
                'G11_1_2.12.2.G.2021'
               WHEN COLLECT_TYPE = 361 THEN
                'G11_1_2.13.1.G.2021'
               WHEN COLLECT_TYPE = 362 THEN
                'G11_1_2.13.2.G.2021'
               WHEN COLLECT_TYPE = 363 THEN
                'G11_1_2.13.3.G.2021'
               WHEN COLLECT_TYPE = 364 THEN
                'G11_1_2.14.1.G.2021'
               WHEN COLLECT_TYPE = 365 THEN
                'G11_1_2.14.2.G.2021'
               WHEN COLLECT_TYPE = 366 THEN
                'G11_1_2.14.3.G.2021'
               WHEN COLLECT_TYPE = 493 THEN
                'G11_1_2.14.4.G.2021'
               WHEN COLLECT_TYPE = 367 THEN
                'G11_1_2.15.1.G.2021'
               WHEN COLLECT_TYPE = 368 THEN
                'G11_1_2.15.2.G.2021'
               WHEN COLLECT_TYPE = 369 THEN
                'G11_1_2.15.3.G.2021'
               WHEN COLLECT_TYPE = 370 THEN
                'G11_1_2.16.1.G.2021'
               WHEN COLLECT_TYPE = 371 THEN
                'G11_1_2.17.1.G.2021'
               WHEN COLLECT_TYPE = 372 THEN
                'G11_1_2.17.2.G.2021'
               WHEN COLLECT_TYPE = 373 THEN
                'G11_1_2.18.1.G.2021'
               WHEN COLLECT_TYPE = 374 THEN
                'G11_1_2.18.2.G.2021'
               WHEN COLLECT_TYPE = 375 THEN
                'G11_1_2.18.3.G.2021'
               WHEN COLLECT_TYPE = 376 THEN
                'G11_1_2.18.4.G.2021'
               WHEN COLLECT_TYPE = 377 THEN
                'G11_1_2.18.5.G.2021'
               WHEN COLLECT_TYPE = 378 THEN
                'G11_1_2.19.1.G.2021'
               WHEN COLLECT_TYPE = 379 THEN
                'G11_1_2.19.2.G.2021'
               WHEN COLLECT_TYPE = 380 THEN
                'G11_1_2.19.3.G.2021'
               WHEN COLLECT_TYPE = 381 THEN
                'G11_1_2.19.4.G.2021'
               WHEN COLLECT_TYPE = 382 THEN
                'G11_1_2.19.5.G.2021'
               WHEN COLLECT_TYPE = 383 THEN
                'G11_1_2.19.6.G.2021'
               WHEN COLLECT_TYPE = 384 THEN
                'G11_1_2.20.1.G.2021'
               WHEN COLLECT_TYPE = 385 THEN
                'G11_1_2.1.1.H.2021'
               WHEN COLLECT_TYPE = 386 THEN
                'G11_1_2.1.2.H.2021'
               WHEN COLLECT_TYPE = 387 THEN
                'G11_1_2.1.3.H.2021'
               WHEN COLLECT_TYPE = 388 THEN
                'G11_1_2.1.4.H.2021'
               WHEN COLLECT_TYPE = 389 THEN
                'G11_1_2.1.5.H.2021'
               WHEN COLLECT_TYPE = 390 THEN
                'G11_1_2.2.1.H.2021'
               WHEN COLLECT_TYPE = 391 THEN
                'G11_1_2.2.2.H.2021'
               WHEN COLLECT_TYPE = 392 THEN
                'G11_1_2.2.3.H.2021'
               WHEN COLLECT_TYPE = 393 THEN
                'G11_1_2.2.4.H.2021'
               WHEN COLLECT_TYPE = 394 THEN
                'G11_1_2.2.5.H.2021'
               WHEN COLLECT_TYPE = 395 THEN
                'G11_1_2.2.6.H.2021'
               WHEN COLLECT_TYPE = 396 THEN
                'G11_1_2.2.7.H.2021'
               WHEN COLLECT_TYPE = 397 THEN
                'G11_1_2.3.1.H.2021'
               WHEN COLLECT_TYPE = 398 THEN
                'G11_1_2.3.2.H.2021'
               WHEN COLLECT_TYPE = 399 THEN
                'G11_1_2.3.3.H.2021'
               WHEN COLLECT_TYPE = 400 THEN
                'G11_1_2.3.4.H.2021'
               WHEN COLLECT_TYPE = 401 THEN
                'G11_1_2.3.5.H.2021'
               WHEN COLLECT_TYPE = 402 THEN
                'G11_1_2.3.6.H.2021'
               WHEN COLLECT_TYPE = 403 THEN
                'G11_1_2.3.7.H.2021'
               WHEN COLLECT_TYPE = 404 THEN
                'G11_1_2.3.8.H.2021'
               WHEN COLLECT_TYPE = 405 THEN
                'G11_1_2.3.9.H.2021'
               WHEN COLLECT_TYPE = 406 THEN
                'G11_1_2.3.10.H.2021'
               WHEN COLLECT_TYPE = 407 THEN
                'G11_1_2.3.11.H.2021'
               WHEN COLLECT_TYPE = 408 THEN
                'G11_1_2.3.12.H.2021'
               WHEN COLLECT_TYPE = 409 THEN
                'G11_1_2.3.13.H.2021'
               WHEN COLLECT_TYPE = 410 THEN
                'G11_1_2.3.14.H.2021'
               WHEN COLLECT_TYPE = 411 THEN
                'G11_1_2.3.15.H.2021'
               WHEN COLLECT_TYPE = 412 THEN
                'G11_1_2.3.16.H.2021'
               WHEN COLLECT_TYPE = 413 THEN
                'G11_1_2.3.17.H.2021'
               WHEN COLLECT_TYPE = 414 THEN
                'G11_1_2.3.18.H.2021'
               WHEN COLLECT_TYPE = 415 THEN
                'G11_1_2.3.19.H.2021'
               WHEN COLLECT_TYPE = 416 THEN
                'G11_1_2.3.20.H.2021'
               WHEN COLLECT_TYPE = 417 THEN
                'G11_1_2.3.21.H.2021'
               WHEN COLLECT_TYPE = 418 THEN
                'G11_1_2.3.22.H.2021'
               WHEN COLLECT_TYPE = 419 THEN
                'G11_1_2.3.23.H.2021'
               WHEN COLLECT_TYPE = 420 THEN
                'G11_1_2.3.24.H.2021'
               WHEN COLLECT_TYPE = 421 THEN
                'G11_1_2.3.25.H.2021'
               WHEN COLLECT_TYPE = 422 THEN
                'G11_1_2.3.26.H.2021'
               WHEN COLLECT_TYPE = 423 THEN
                'G11_1_2.3.27.H.2021'
               WHEN COLLECT_TYPE = 424 THEN
                'G11_1_2.3.28.H.2021'
               WHEN COLLECT_TYPE = 425 THEN
                'G11_1_2.3.29.H.2021'
               WHEN COLLECT_TYPE = 426 THEN
                'G11_1_2.3.30.H.2021'
               WHEN COLLECT_TYPE = 427 THEN
                'G11_1_2.3.31.H.2021'
               WHEN COLLECT_TYPE = 428 THEN
                'G11_1_2.4.1.H.2021'
               WHEN COLLECT_TYPE = 429 THEN
                'G11_1_2.4.2.H.2021'
               WHEN COLLECT_TYPE = 430 THEN
                'G11_1_2.4.3.H.2021'
               WHEN COLLECT_TYPE = 431 THEN
                'G11_1_2.5.1.H.2021'
               WHEN COLLECT_TYPE = 432 THEN
                'G11_1_2.5.2.H.2021'
               WHEN COLLECT_TYPE = 433 THEN
                'G11_1_2.5.3.H.2021'
               WHEN COLLECT_TYPE = 434 THEN
                'G11_1_2.5.4.H.2021'
               WHEN COLLECT_TYPE = 435 THEN
                'G11_1_2.6.1.H.2021'
               WHEN COLLECT_TYPE = 436 THEN
                'G11_1_2.6.2.H.2021'
               WHEN COLLECT_TYPE = 437 THEN
                'G11_1_2.7.1.H.2021'
               WHEN COLLECT_TYPE = 438 THEN
                'G11_1_2.7.2.H.2021'
               WHEN COLLECT_TYPE = 439 THEN
                'G11_1_2.7.3.H.2021'
               WHEN COLLECT_TYPE = 440 THEN
                'G11_1_2.7.4.H.2021'
               WHEN COLLECT_TYPE = 441 THEN
                'G11_1_2.7.5.H.2021'
               WHEN COLLECT_TYPE = 442 THEN
                'G11_1_2.7.6.H.2021'
               WHEN COLLECT_TYPE = 443 THEN
                'G11_1_2.7.7.H.2021'
               WHEN COLLECT_TYPE = 444 THEN
                'G11_1_2.7.8.H.2021'
               WHEN COLLECT_TYPE = 445 THEN
                'G11_1_2.8.1.H.2021'
               WHEN COLLECT_TYPE = 446 THEN
                'G11_1_2.8.2.H.2021'
               WHEN COLLECT_TYPE = 447 THEN
                'G11_1_2.9.1.H.2021'
               WHEN COLLECT_TYPE = 448 THEN
                'G11_1_2.9.2.H.2021'
               WHEN COLLECT_TYPE = 449 THEN
                'G11_1_2.9.3.H.2021'
               WHEN COLLECT_TYPE = 450 THEN
                'G11_1_2.10.1.H.2021'
               WHEN COLLECT_TYPE = 451 THEN
                'G11_1_2.10.2.H.2021'
               WHEN COLLECT_TYPE = 452 THEN
                'G11_1_2.10.3.H.2021'
               WHEN COLLECT_TYPE = 453 THEN
                'G11_1_2.10.4.H.2021'
               WHEN COLLECT_TYPE = 454 THEN
                'G11_1_2.11.1.H.2021'
               WHEN COLLECT_TYPE = 455 THEN
                'G11_1_2.12.1.H.2021'
               WHEN COLLECT_TYPE = 456 THEN
                'G11_1_2.12.2.H.2021'
               WHEN COLLECT_TYPE = 457 THEN
                'G11_1_2.13.1.H.2021'
               WHEN COLLECT_TYPE = 458 THEN
                'G11_1_2.13.2.H.2021'
               WHEN COLLECT_TYPE = 459 THEN
                'G11_1_2.13.3.H.2021'
               WHEN COLLECT_TYPE = 460 THEN
                'G11_1_2.14.1.H.2021'
               WHEN COLLECT_TYPE = 461 THEN
                'G11_1_2.14.2.H.2021'
               WHEN COLLECT_TYPE = 462 THEN
                'G11_1_2.14.3.H.2021'
               WHEN COLLECT_TYPE = 494 THEN
                'G11_1_2.14.4.H.2021'
               WHEN COLLECT_TYPE = 463 THEN
                'G11_1_2.15.1.H.2021'
               WHEN COLLECT_TYPE = 464 THEN
                'G11_1_2.15.2.H.2021'
               WHEN COLLECT_TYPE = 465 THEN
                'G11_1_2.15.3.H.2021'
               WHEN COLLECT_TYPE = 466 THEN
                'G11_1_2.16.1.H.2021'
               WHEN COLLECT_TYPE = 467 THEN
                'G11_1_2.17.1.H.2021'
               WHEN COLLECT_TYPE = 468 THEN
                'G11_1_2.17.2.H.2021'
               WHEN COLLECT_TYPE = 469 THEN
                'G11_1_2.18.1.H.2021'
               WHEN COLLECT_TYPE = 470 THEN
                'G11_1_2.18.2.H.2021'
               WHEN COLLECT_TYPE = 471 THEN
                'G11_1_2.18.3.H.2021'
               WHEN COLLECT_TYPE = 472 THEN
                'G11_1_2.18.4.H.2021'
               WHEN COLLECT_TYPE = 473 THEN
                'G11_1_2.18.5.H.2021'
               WHEN COLLECT_TYPE = 474 THEN
                'G11_1_2.19.1.H.2021'
               WHEN COLLECT_TYPE = 475 THEN
                'G11_1_2.19.2.H.2021'
               WHEN COLLECT_TYPE = 476 THEN
                'G11_1_2.19.3.H.2021'
               WHEN COLLECT_TYPE = 477 THEN
                'G11_1_2.19.4.H.2021'
               WHEN COLLECT_TYPE = 478 THEN
                'G11_1_2.19.5.H.2021'
               WHEN COLLECT_TYPE = 479 THEN
                'G11_1_2.19.6.H.2021'
               WHEN COLLECT_TYPE = 480 THEN
                'G11_1_2.20.1.H.2021'
             END AS ITEM_NUM,
             SUM(COLLECT_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_PUB_DATA_COLLECT_G1101
       WHERE COLLECT_TYPE IS NOT NULL
       GROUP BY ORG_NUM,
                CASE
                  WHEN COLLECT_TYPE = 1 THEN
                   'G11_1_2.1.1.C.2021'
                  WHEN COLLECT_TYPE = 2 THEN
                   'G11_1_2.1.2.C.2021'
                  WHEN COLLECT_TYPE = 3 THEN
                   'G11_1_2.1.3.C.2021'
                  WHEN COLLECT_TYPE = 4 THEN
                   'G11_1_2.1.4.C.2021'
                  WHEN COLLECT_TYPE = 5 THEN
                   'G11_1_2.1.5.C.2021'
                  WHEN COLLECT_TYPE = 6 THEN
                   'G11_1_2.2.1.C.2021'
                  WHEN COLLECT_TYPE = 7 THEN
                   'G11_1_2.2.2.C.2021'
                  WHEN COLLECT_TYPE = 8 THEN
                   'G11_1_2.2.3.C.2021'
                  WHEN COLLECT_TYPE = 9 THEN
                   'G11_1_2.2.4.C.2021'
                  WHEN COLLECT_TYPE = 10 THEN
                   'G11_1_2.2.5.C.2021'
                  WHEN COLLECT_TYPE = 11 THEN
                   'G11_1_2.2.6.C.2021'
                  WHEN COLLECT_TYPE = 12 THEN
                   'G11_1_2.2.7.C.2021'
                  WHEN COLLECT_TYPE = 13 THEN
                   'G11_1_2.3.1.C.2021'
                  WHEN COLLECT_TYPE = 14 THEN
                   'G11_1_2.3.2.C.2021'
                  WHEN COLLECT_TYPE = 15 THEN
                   'G11_1_2.3.3.C.2021'
                  WHEN COLLECT_TYPE = 16 THEN
                   'G11_1_2.3.4.C.2021'
                  WHEN COLLECT_TYPE = 17 THEN
                   'G11_1_2.3.5.C.2021'
                  WHEN COLLECT_TYPE = 18 THEN
                   'G11_1_2.3.6.C.2021'
                  WHEN COLLECT_TYPE = 19 THEN
                   'G11_1_2.3.7.C.2021'
                  WHEN COLLECT_TYPE = 20 THEN
                   'G11_1_2.3.8.C.2021'
                  WHEN COLLECT_TYPE = 21 THEN
                   'G11_1_2.3.9.C.2021'
                  WHEN COLLECT_TYPE = 22 THEN
                   'G11_1_2.3.10.C.2021'
                  WHEN COLLECT_TYPE = 23 THEN
                   'G11_1_2.3.11.C.2021'
                  WHEN COLLECT_TYPE = 24 THEN
                   'G11_1_2.3.12.C.2021'
                  WHEN COLLECT_TYPE = 25 THEN
                   'G11_1_2.3.13.C.2021'
                  WHEN COLLECT_TYPE = 26 THEN
                   'G11_1_2.3.14.C.2021'
                  WHEN COLLECT_TYPE = 27 THEN
                   'G11_1_2.3.15.C.2021'
                  WHEN COLLECT_TYPE = 28 THEN
                   'G11_1_2.3.16.C.2021'
                  WHEN COLLECT_TYPE = 29 THEN
                   'G11_1_2.3.17.C.2021'
                  WHEN COLLECT_TYPE = 30 THEN
                   'G11_1_2.3.18.C.2021'
                  WHEN COLLECT_TYPE = 31 THEN
                   'G11_1_2.3.19.C.2021'
                  WHEN COLLECT_TYPE = 32 THEN
                   'G11_1_2.3.20.C.2021'
                  WHEN COLLECT_TYPE = 33 THEN
                   'G11_1_2.3.21.C.2021'
                  WHEN COLLECT_TYPE = 34 THEN
                   'G11_1_2.3.22.C.2021'
                  WHEN COLLECT_TYPE = 35 THEN
                   'G11_1_2.3.23.C.2021'
                  WHEN COLLECT_TYPE = 36 THEN
                   'G11_1_2.3.24.C.2021'
                  WHEN COLLECT_TYPE = 37 THEN
                   'G11_1_2.3.25.C.2021'
                  WHEN COLLECT_TYPE = 38 THEN
                   'G11_1_2.3.26.C.2021'
                  WHEN COLLECT_TYPE = 39 THEN
                   'G11_1_2.3.27.C.2021'
                  WHEN COLLECT_TYPE = 40 THEN
                   'G11_1_2.3.28.C.2021'
                  WHEN COLLECT_TYPE = 41 THEN
                   'G11_1_2.3.29.C.2021'
                  WHEN COLLECT_TYPE = 42 THEN
                   'G11_1_2.3.30.C.2021'
                  WHEN COLLECT_TYPE = 43 THEN
                   'G11_1_2.3.31.C.2021'
                  WHEN COLLECT_TYPE = 44 THEN
                   'G11_1_2.4.1.C.2021'
                  WHEN COLLECT_TYPE = 45 THEN
                   'G11_1_2.4.2.C.2021'
                  WHEN COLLECT_TYPE = 46 THEN
                   'G11_1_2.4.3.C.2021'
                  WHEN COLLECT_TYPE = 47 THEN
                   'G11_1_2.5.1.C.2021'
                  WHEN COLLECT_TYPE = 48 THEN
                   'G11_1_2.5.2.C.2021'
                  WHEN COLLECT_TYPE = 49 THEN
                   'G11_1_2.5.3.C.2021'
                  WHEN COLLECT_TYPE = 50 THEN
                   'G11_1_2.5.4.C.2021'
                  WHEN COLLECT_TYPE = 51 THEN
                   'G11_1_2.6.1.C.2021'
                  WHEN COLLECT_TYPE = 52 THEN
                   'G11_1_2.6.2.C.2021'
                  WHEN COLLECT_TYPE = 53 THEN
                   'G11_1_2.7.1.C.2021'
                  WHEN COLLECT_TYPE = 54 THEN
                   'G11_1_2.7.2.C.2021'
                  WHEN COLLECT_TYPE = 55 THEN
                   'G11_1_2.7.3.C.2021'
                  WHEN COLLECT_TYPE = 56 THEN
                   'G11_1_2.7.4.C.2021'
                  WHEN COLLECT_TYPE = 57 THEN
                   'G11_1_2.7.5.C.2021'
                  WHEN COLLECT_TYPE = 58 THEN
                   'G11_1_2.7.6.C.2021'
                  WHEN COLLECT_TYPE = 59 THEN
                   'G11_1_2.7.7.C.2021'
                  WHEN COLLECT_TYPE = 60 THEN
                   'G11_1_2.7.8.C.2021'
                  WHEN COLLECT_TYPE = 61 THEN
                   'G11_1_2.8.1.C.2021'
                  WHEN COLLECT_TYPE = 62 THEN
                   'G11_1_2.8.2.C.2021'
                  WHEN COLLECT_TYPE = 63 THEN
                   'G11_1_2.9.1.C.2021'
                  WHEN COLLECT_TYPE = 64 THEN
                   'G11_1_2.9.2.C.2021'
                  WHEN COLLECT_TYPE = 65 THEN
                   'G11_1_2.9.3.C.2021'
                  WHEN COLLECT_TYPE = 66 THEN
                   'G11_1_2.10.1.C.2021'
                  WHEN COLLECT_TYPE = 67 THEN
                   'G11_1_2.10.2.C.2021'
                  WHEN COLLECT_TYPE = 68 THEN
                   'G11_1_2.10.3.C.2021'
                  WHEN COLLECT_TYPE = 69 THEN
                   'G11_1_2.10.4.C.2021'
                  WHEN COLLECT_TYPE = 70 THEN
                   'G11_1_2.11.1.C.2021'
                  WHEN COLLECT_TYPE = 71 THEN
                   'G11_1_2.12.1.C.2021'
                  WHEN COLLECT_TYPE = 72 THEN
                   'G11_1_2.12.2.C.2021'
                  WHEN COLLECT_TYPE = 73 THEN
                   'G11_1_2.13.1.C.2021'
                  WHEN COLLECT_TYPE = 74 THEN
                   'G11_1_2.13.2.C.2021'
                  WHEN COLLECT_TYPE = 75 THEN
                   'G11_1_2.13.3.C.2021'
                  WHEN COLLECT_TYPE = 76 THEN
                   'G11_1_2.14.1.C.2021'
                  WHEN COLLECT_TYPE = 77 THEN
                   'G11_1_2.14.2.C.2021'
                  WHEN COLLECT_TYPE = 78 THEN
                   'G11_1_2.14.3.C.2021'
                  WHEN COLLECT_TYPE = 490 THEN
                   'G11_1_2.14.4.C.2021'
                --'G11_1_2.14.4.C.2021' 过程中没有，报表设计器没有，但是取数报表有，手工填报还是重新取数？
                  WHEN COLLECT_TYPE = 79 THEN
                   'G11_1_2.15.1.C.2021'
                  WHEN COLLECT_TYPE = 80 THEN
                   'G11_1_2.15.2.C.2021'
                  WHEN COLLECT_TYPE = 81 THEN
                   'G11_1_2.15.3.C.2021'
                  WHEN COLLECT_TYPE = 82 THEN
                   'G11_1_2.16.1.C.2021'
                  WHEN COLLECT_TYPE = 83 THEN
                   'G11_1_2.17.1.C.2021'
                  WHEN COLLECT_TYPE = 84 THEN
                   'G11_1_2.17.2.C.2021'
                  WHEN COLLECT_TYPE = 85 THEN
                   'G11_1_2.18.1.C.2021'
                  WHEN COLLECT_TYPE = 86 THEN
                   'G11_1_2.18.2.C.2021'
                  WHEN COLLECT_TYPE = 87 THEN
                   'G11_1_2.18.3.C.2021'
                  WHEN COLLECT_TYPE = 88 THEN
                   'G11_1_2.18.4.C.2021'
                  WHEN COLLECT_TYPE = 89 THEN
                   'G11_1_2.18.5.C.2021'
                  WHEN COLLECT_TYPE = 90 THEN
                   'G11_1_2.19.1.C.2021'
                  WHEN COLLECT_TYPE = 91 THEN
                   'G11_1_2.19.2.C.2021'
                  WHEN COLLECT_TYPE = 92 THEN
                   'G11_1_2.19.3.C.2021'
                  WHEN COLLECT_TYPE = 93 THEN
                   'G11_1_2.19.4.C.2021'
                  WHEN COLLECT_TYPE = 94 THEN
                   'G11_1_2.19.5.C.2021'
                  WHEN COLLECT_TYPE = 95 THEN
                   'G11_1_2.19.6.C.2021'
                  WHEN COLLECT_TYPE = 96 THEN
                   'G11_1_2.20.1.C.2021'
                  WHEN COLLECT_TYPE = 97 THEN
                   'G11_1_2.1.1.D.2021'
                  WHEN COLLECT_TYPE = 98 THEN
                   'G11_1_2.1.2.D.2021'
                  WHEN COLLECT_TYPE = 99 THEN
                   'G11_1_2.1.3.D.2021'
                  WHEN COLLECT_TYPE = 100 THEN
                   'G11_1_2.1.4.D.2021'
                  WHEN COLLECT_TYPE = 101 THEN
                   'G11_1_2.1.5.D.2021'
                  WHEN COLLECT_TYPE = 102 THEN
                   'G11_1_2.2.1.D.2021'
                  WHEN COLLECT_TYPE = 103 THEN
                   'G11_1_2.2.2.D.2021'
                  WHEN COLLECT_TYPE = 104 THEN
                   'G11_1_2.2.3.D.2021'
                  WHEN COLLECT_TYPE = 105 THEN
                   'G11_1_2.2.4.D.2021'
                  WHEN COLLECT_TYPE = 106 THEN
                   'G11_1_2.2.5.D.2021'
                  WHEN COLLECT_TYPE = 107 THEN
                   'G11_1_2.2.6.D.2021'
                  WHEN COLLECT_TYPE = 108 THEN
                   'G11_1_2.2.7.D.2021'
                  WHEN COLLECT_TYPE = 109 THEN
                   'G11_1_2.3.1.D.2021'
                  WHEN COLLECT_TYPE = 110 THEN
                   'G11_1_2.3.2.D.2021'
                  WHEN COLLECT_TYPE = 111 THEN
                   'G11_1_2.3.3.D.2021'
                  WHEN COLLECT_TYPE = 112 THEN
                   'G11_1_2.3.4.D.2021'
                  WHEN COLLECT_TYPE = 113 THEN
                   'G11_1_2.3.5.D.2021'
                  WHEN COLLECT_TYPE = 114 THEN
                   'G11_1_2.3.6.D.2021'
                  WHEN COLLECT_TYPE = 115 THEN
                   'G11_1_2.3.7.D.2021'
                  WHEN COLLECT_TYPE = 116 THEN
                   'G11_1_2.3.8.D.2021'
                  WHEN COLLECT_TYPE = 117 THEN
                   'G11_1_2.3.9.D.2021'
                  WHEN COLLECT_TYPE = 118 THEN
                   'G11_1_2.3.10.D.2021'
                  WHEN COLLECT_TYPE = 119 THEN
                   'G11_1_2.3.11.D.2021'
                  WHEN COLLECT_TYPE = 120 THEN
                   'G11_1_2.3.12.D.2021'
                  WHEN COLLECT_TYPE = 121 THEN
                   'G11_1_2.3.13.D.2021'
                  WHEN COLLECT_TYPE = 122 THEN
                   'G11_1_2.3.14.D.2021'
                  WHEN COLLECT_TYPE = 123 THEN
                   'G11_1_2.3.15.D.2021'
                  WHEN COLLECT_TYPE = 124 THEN
                   'G11_1_2.3.16.D.2021'
                  WHEN COLLECT_TYPE = 125 THEN
                   'G11_1_2.3.17.D.2021'
                  WHEN COLLECT_TYPE = 126 THEN
                   'G11_1_2.3.18.D.2021'
                  WHEN COLLECT_TYPE = 127 THEN
                   'G11_1_2.3.19.D.2021'
                  WHEN COLLECT_TYPE = 128 THEN
                   'G11_1_2.3.20.D.2021'
                  WHEN COLLECT_TYPE = 129 THEN
                   'G11_1_2.3.21.D.2021'
                  WHEN COLLECT_TYPE = 130 THEN
                   'G11_1_2.3.22.D.2021'
                  WHEN COLLECT_TYPE = 131 THEN
                   'G11_1_2.3.23.D.2021'
                  WHEN COLLECT_TYPE = 132 THEN
                   'G11_1_2.3.24.D.2021'
                  WHEN COLLECT_TYPE = 133 THEN
                   'G11_1_2.3.25.D.2021'
                  WHEN COLLECT_TYPE = 134 THEN
                   'G11_1_2.3.26.D.2021'
                  WHEN COLLECT_TYPE = 135 THEN
                   'G11_1_2.3.27.D.2021'
                  WHEN COLLECT_TYPE = 136 THEN
                   'G11_1_2.3.28.D.2021'
                  WHEN COLLECT_TYPE = 137 THEN
                   'G11_1_2.3.29.D.2021'
                  WHEN COLLECT_TYPE = 138 THEN
                   'G11_1_2.3.30.D.2021'
                  WHEN COLLECT_TYPE = 139 THEN
                   'G11_1_2.3.31.D.2021'
                  WHEN COLLECT_TYPE = 140 THEN
                   'G11_1_2.4.1.D.2021'
                  WHEN COLLECT_TYPE = 141 THEN
                   'G11_1_2.4.2.D.2021'
                  WHEN COLLECT_TYPE = 142 THEN
                   'G11_1_2.4.3.D.2021'
                  WHEN COLLECT_TYPE = 143 THEN
                   'G11_1_2.5.1.D.2021'
                  WHEN COLLECT_TYPE = 144 THEN
                   'G11_1_2.5.2.D.2021'
                  WHEN COLLECT_TYPE = 145 THEN
                   'G11_1_2.5.3.D.2021'
                  WHEN COLLECT_TYPE = 146 THEN
                   'G11_1_2.5.4.D.2021'
                  WHEN COLLECT_TYPE = 147 THEN
                   'G11_1_2.6.1.D.2021'
                  WHEN COLLECT_TYPE = 148 THEN
                   'G11_1_2.6.2.D.2021'
                  WHEN COLLECT_TYPE = 149 THEN
                   'G11_1_2.7.1.D.2021'
                  WHEN COLLECT_TYPE = 150 THEN
                   'G11_1_2.7.2.D.2021'
                  WHEN COLLECT_TYPE = 151 THEN
                   'G11_1_2.7.3.D.2021'
                  WHEN COLLECT_TYPE = 152 THEN
                   'G11_1_2.7.4.D.2021'
                  WHEN COLLECT_TYPE = 153 THEN
                   'G11_1_2.7.5.D.2021'
                  WHEN COLLECT_TYPE = 154 THEN
                   'G11_1_2.7.6.D.2021'
                  WHEN COLLECT_TYPE = 155 THEN
                   'G11_1_2.7.7.D.2021'
                  WHEN COLLECT_TYPE = 156 THEN
                   'G11_1_2.7.8.D.2021'
                  WHEN COLLECT_TYPE = 157 THEN
                   'G11_1_2.8.1.D.2021'
                  WHEN COLLECT_TYPE = 158 THEN
                   'G11_1_2.8.2.D.2021'
                  WHEN COLLECT_TYPE = 159 THEN
                   'G11_1_2.9.1.D.2021'
                  WHEN COLLECT_TYPE = 160 THEN
                   'G11_1_2.9.2.D.2021'
                  WHEN COLLECT_TYPE = 161 THEN
                   'G11_1_2.9.3.D.2021'
                  WHEN COLLECT_TYPE = 162 THEN
                   'G11_1_2.10.1.D.2021'
                  WHEN COLLECT_TYPE = 163 THEN
                   'G11_1_2.10.2.D.2021'
                  WHEN COLLECT_TYPE = 164 THEN
                   'G11_1_2.10.3.D.2021'
                  WHEN COLLECT_TYPE = 165 THEN
                   'G11_1_2.10.4.D.2021'
                  WHEN COLLECT_TYPE = 166 THEN
                   'G11_1_2.11.1.D.2021'
                  WHEN COLLECT_TYPE = 167 THEN
                   'G11_1_2.12.1.D.2021'
                  WHEN COLLECT_TYPE = 168 THEN
                   'G11_1_2.12.2.D.2021'
                  WHEN COLLECT_TYPE = 169 THEN
                   'G11_1_2.13.1.D.2021'
                  WHEN COLLECT_TYPE = 170 THEN
                   'G11_1_2.13.2.D.2021'
                  WHEN COLLECT_TYPE = 171 THEN
                   'G11_1_2.13.3.D.2021'
                  WHEN COLLECT_TYPE = 172 THEN
                   'G11_1_2.14.1.D.2021'
                  WHEN COLLECT_TYPE = 173 THEN
                   'G11_1_2.14.2.D.2021'
                  WHEN COLLECT_TYPE = 174 THEN
                   'G11_1_2.14.3.D.2021'
                  WHEN COLLECT_TYPE = 491 THEN
                   'G11_1_2.14.4.D.2021'
                  WHEN COLLECT_TYPE = 175 THEN
                   'G11_1_2.15.1.D.2021'
                  WHEN COLLECT_TYPE = 176 THEN
                   'G11_1_2.15.2.D.2021'
                  WHEN COLLECT_TYPE = 177 THEN
                   'G11_1_2.15.3.D.2021'
                  WHEN COLLECT_TYPE = 178 THEN
                   'G11_1_2.16.1.D.2021'
                  WHEN COLLECT_TYPE = 179 THEN
                   'G11_1_2.17.1.D.2021'
                  WHEN COLLECT_TYPE = 180 THEN
                   'G11_1_2.17.2.D.2021'
                  WHEN COLLECT_TYPE = 181 THEN
                   'G11_1_2.18.1.D.2021'
                  WHEN COLLECT_TYPE = 182 THEN
                   'G11_1_2.18.2.D.2021'
                  WHEN COLLECT_TYPE = 183 THEN
                   'G11_1_2.18.3.D.2021'
                  WHEN COLLECT_TYPE = 184 THEN
                   'G11_1_2.18.4.D.2021'
                  WHEN COLLECT_TYPE = 185 THEN
                   'G11_1_2.18.5.D.2021'
                  WHEN COLLECT_TYPE = 186 THEN
                   'G11_1_2.19.1.D.2021'
                  WHEN COLLECT_TYPE = 187 THEN
                   'G11_1_2.19.2.D.2021'
                  WHEN COLLECT_TYPE = 188 THEN
                   'G11_1_2.19.3.D.2021'
                  WHEN COLLECT_TYPE = 189 THEN
                   'G11_1_2.19.4.D.2021'
                  WHEN COLLECT_TYPE = 190 THEN
                   'G11_1_2.19.5.D.2021'
                  WHEN COLLECT_TYPE = 191 THEN
                   'G11_1_2.19.6.D.2021'
                  WHEN COLLECT_TYPE = 192 THEN
                   'G11_1_2.20.1.D.2021'
                  WHEN COLLECT_TYPE = 193 THEN
                   'G11_1_2.1.1.F.2021'
                  WHEN COLLECT_TYPE = 194 THEN
                   'G11_1_2.1.2.F.2021'
                  WHEN COLLECT_TYPE = 195 THEN
                   'G11_1_2.1.3.F.2021'
                  WHEN COLLECT_TYPE = 196 THEN
                   'G11_1_2.1.4.F.2021'
                  WHEN COLLECT_TYPE = 197 THEN
                   'G11_1_2.1.5.F.2021'
                  WHEN COLLECT_TYPE = 198 THEN
                   'G11_1_2.2.1.F.2021'
                  WHEN COLLECT_TYPE = 199 THEN
                   'G11_1_2.2.2.F.2021'
                  WHEN COLLECT_TYPE = 200 THEN
                   'G11_1_2.2.3.F.2021'
                  WHEN COLLECT_TYPE = 201 THEN
                   'G11_1_2.2.4.F.2021'
                  WHEN COLLECT_TYPE = 202 THEN
                   'G11_1_2.2.5.F.2021'
                  WHEN COLLECT_TYPE = 203 THEN
                   'G11_1_2.2.6.F.2021'
                  WHEN COLLECT_TYPE = 204 THEN
                   'G11_1_2.2.7.F.2021'
                  WHEN COLLECT_TYPE = 205 THEN
                   'G11_1_2.3.1.F.2021'
                  WHEN COLLECT_TYPE = 206 THEN
                   'G11_1_2.3.2.F.2021'
                  WHEN COLLECT_TYPE = 207 THEN
                   'G11_1_2.3.3.F.2021'
                  WHEN COLLECT_TYPE = 208 THEN
                   'G11_1_2.3.4.F.2021'
                  WHEN COLLECT_TYPE = 209 THEN
                   'G11_1_2.3.5.F.2021'
                  WHEN COLLECT_TYPE = 210 THEN
                   'G11_1_2.3.6.F.2021'
                  WHEN COLLECT_TYPE = 211 THEN
                   'G11_1_2.3.7.F.2021'
                  WHEN COLLECT_TYPE = 212 THEN
                   'G11_1_2.3.8.F.2021'
                  WHEN COLLECT_TYPE = 213 THEN
                   'G11_1_2.3.9.F.2021'
                  WHEN COLLECT_TYPE = 214 THEN
                   'G11_1_2.3.10.F.2021'
                  WHEN COLLECT_TYPE = 215 THEN
                   'G11_1_2.3.11.F.2021'
                  WHEN COLLECT_TYPE = 216 THEN
                   'G11_1_2.3.12.F.2021'
                  WHEN COLLECT_TYPE = 217 THEN
                   'G11_1_2.3.13.F.2021'
                  WHEN COLLECT_TYPE = 218 THEN
                   'G11_1_2.3.14.F.2021'
                  WHEN COLLECT_TYPE = 219 THEN
                   'G11_1_2.3.15.F.2021'
                  WHEN COLLECT_TYPE = 220 THEN
                   'G11_1_2.3.16.F.2021'
                  WHEN COLLECT_TYPE = 221 THEN
                   'G11_1_2.3.17.F.2021'
                  WHEN COLLECT_TYPE = 222 THEN
                   'G11_1_2.3.18.F.2021'
                  WHEN COLLECT_TYPE = 223 THEN
                   'G11_1_2.3.19.F.2021'
                  WHEN COLLECT_TYPE = 224 THEN
                   'G11_1_2.3.20.F.2021'
                  WHEN COLLECT_TYPE = 225 THEN
                   'G11_1_2.3.21.F.2021'
                  WHEN COLLECT_TYPE = 226 THEN
                   'G11_1_2.3.22.F.2021'
                  WHEN COLLECT_TYPE = 227 THEN
                   'G11_1_2.3.23.F.2021'
                  WHEN COLLECT_TYPE = 228 THEN
                   'G11_1_2.3.24.F.2021'
                  WHEN COLLECT_TYPE = 229 THEN
                   'G11_1_2.3.25.F.2021'
                  WHEN COLLECT_TYPE = 230 THEN
                   'G11_1_2.3.26.F.2021'
                  WHEN COLLECT_TYPE = 231 THEN
                   'G11_1_2.3.27.F.2021'
                  WHEN COLLECT_TYPE = 232 THEN
                   'G11_1_2.3.28.F.2021'
                  WHEN COLLECT_TYPE = 233 THEN
                   'G11_1_2.3.29.F.2021'
                  WHEN COLLECT_TYPE = 234 THEN
                   'G11_1_2.3.30.F.2021'
                  WHEN COLLECT_TYPE = 235 THEN
                   'G11_1_2.3.31.F.2021'
                  WHEN COLLECT_TYPE = 236 THEN
                   'G11_1_2.4.1.F.2021'
                  WHEN COLLECT_TYPE = 237 THEN
                   'G11_1_2.4.2.F.2021'
                  WHEN COLLECT_TYPE = 238 THEN
                   'G11_1_2.4.3.F.2021'
                  WHEN COLLECT_TYPE = 239 THEN
                   'G11_1_2.5.1.F.2021'
                  WHEN COLLECT_TYPE = 240 THEN
                   'G11_1_2.5.2.F.2021'
                  WHEN COLLECT_TYPE = 241 THEN
                   'G11_1_2.5.3.F.2021'
                  WHEN COLLECT_TYPE = 242 THEN
                   'G11_1_2.5.4.F.2021'
                  WHEN COLLECT_TYPE = 243 THEN
                   'G11_1_2.6.1.F.2021'
                  WHEN COLLECT_TYPE = 244 THEN
                   'G11_1_2.6.2.F.2021'
                  WHEN COLLECT_TYPE = 245 THEN
                   'G11_1_2.7.1.F.2021'
                  WHEN COLLECT_TYPE = 246 THEN
                   'G11_1_2.7.2.F.2021'
                  WHEN COLLECT_TYPE = 247 THEN
                   'G11_1_2.7.3.F.2021'
                  WHEN COLLECT_TYPE = 248 THEN
                   'G11_1_2.7.4.F.2021'
                  WHEN COLLECT_TYPE = 249 THEN
                   'G11_1_2.7.5.F.2021'
                  WHEN COLLECT_TYPE = 250 THEN
                   'G11_1_2.7.6.F.2021'
                  WHEN COLLECT_TYPE = 251 THEN
                   'G11_1_2.7.7.F.2021'
                  WHEN COLLECT_TYPE = 252 THEN
                   'G11_1_2.7.8.F.2021'
                  WHEN COLLECT_TYPE = 253 THEN
                   'G11_1_2.8.1.F.2021'
                  WHEN COLLECT_TYPE = 254 THEN
                   'G11_1_2.8.2.F.2021'
                  WHEN COLLECT_TYPE = 255 THEN
                   'G11_1_2.9.1.F.2021'
                  WHEN COLLECT_TYPE = 256 THEN
                   'G11_1_2.9.2.F.2021'
                  WHEN COLLECT_TYPE = 257 THEN
                   'G11_1_2.9.3.F.2021'
                  WHEN COLLECT_TYPE = 258 THEN
                   'G11_1_2.10.1.F.2021'
                  WHEN COLLECT_TYPE = 259 THEN
                   'G11_1_2.10.2.F.2021'
                  WHEN COLLECT_TYPE = 260 THEN
                   'G11_1_2.10.3.F.2021'
                  WHEN COLLECT_TYPE = 261 THEN
                   'G11_1_2.10.4.F.2021'
                  WHEN COLLECT_TYPE = 262 THEN
                   'G11_1_2.11.1.F.2021'
                  WHEN COLLECT_TYPE = 263 THEN
                   'G11_1_2.12.1.F.2021'
                  WHEN COLLECT_TYPE = 264 THEN
                   'G11_1_2.12.2.F.2021'
                  WHEN COLLECT_TYPE = 265 THEN
                   'G11_1_2.13.1.F.2021'
                  WHEN COLLECT_TYPE = 266 THEN
                   'G11_1_2.13.2.F.2021'
                  WHEN COLLECT_TYPE = 267 THEN
                   'G11_1_2.13.3.F.2021'
                  WHEN COLLECT_TYPE = 268 THEN
                   'G11_1_2.14.1.F.2021'
                  WHEN COLLECT_TYPE = 269 THEN
                   'G11_1_2.14.2.F.2021'
                  WHEN COLLECT_TYPE = 270 THEN
                   'G11_1_2.14.3.F.2021'
                  WHEN COLLECT_TYPE = 492 THEN
                   'G11_1_2.14.4.F.2021'
                  WHEN COLLECT_TYPE = 271 THEN
                   'G11_1_2.15.1.F.2021'
                  WHEN COLLECT_TYPE = 272 THEN
                   'G11_1_2.15.2.F.2021'
                  WHEN COLLECT_TYPE = 273 THEN
                   'G11_1_2.15.3.F.2021'
                  WHEN COLLECT_TYPE = 274 THEN
                   'G11_1_2.16.1.F.2021'
                  WHEN COLLECT_TYPE = 275 THEN
                   'G11_1_2.17.1.F.2021'
                  WHEN COLLECT_TYPE = 276 THEN
                   'G11_1_2.17.2.F.2021'
                  WHEN COLLECT_TYPE = 277 THEN
                   'G11_1_2.18.1.F.2021'
                  WHEN COLLECT_TYPE = 278 THEN
                   'G11_1_2.18.2.F.2021'
                  WHEN COLLECT_TYPE = 279 THEN
                   'G11_1_2.18.3.F.2021'
                  WHEN COLLECT_TYPE = 280 THEN
                   'G11_1_2.18.4.F.2021'
                  WHEN COLLECT_TYPE = 281 THEN
                   'G11_1_2.18.5.F.2021'
                  WHEN COLLECT_TYPE = 282 THEN
                   'G11_1_2.19.1.F.2021'
                  WHEN COLLECT_TYPE = 283 THEN
                   'G11_1_2.19.2.F.2021'
                  WHEN COLLECT_TYPE = 284 THEN
                   'G11_1_2.19.3.F.2021'
                  WHEN COLLECT_TYPE = 285 THEN
                   'G11_1_2.19.4.F.2021'
                  WHEN COLLECT_TYPE = 286 THEN
                   'G11_1_2.19.5.F.2021'
                  WHEN COLLECT_TYPE = 287 THEN
                   'G11_1_2.19.6.F.2021'
                  WHEN COLLECT_TYPE = 288 THEN
                   'G11_1_2.20.1.F.2021'
                  WHEN COLLECT_TYPE = 289 THEN
                   'G11_1_2.1.1.G.2021'
                  WHEN COLLECT_TYPE = 290 THEN
                   'G11_1_2.1.2.G.2021'
                  WHEN COLLECT_TYPE = 291 THEN
                   'G11_1_2.1.3.G.2021'
                  WHEN COLLECT_TYPE = 292 THEN
                   'G11_1_2.1.4.G.2021'
                  WHEN COLLECT_TYPE = 293 THEN
                   'G11_1_2.1.5.G.2021'
                  WHEN COLLECT_TYPE = 294 THEN
                   'G11_1_2.2.1.G.2021'
                  WHEN COLLECT_TYPE = 295 THEN
                   'G11_1_2.2.2.G.2021'
                  WHEN COLLECT_TYPE = 296 THEN
                   'G11_1_2.2.3.G.2021'
                  WHEN COLLECT_TYPE = 297 THEN
                   'G11_1_2.2.4.G.2021'
                  WHEN COLLECT_TYPE = 298 THEN
                   'G11_1_2.2.5.G.2021'
                  WHEN COLLECT_TYPE = 299 THEN
                   'G11_1_2.2.6.G.2021'
                  WHEN COLLECT_TYPE = 300 THEN
                   'G11_1_2.2.7.G.2021'
                  WHEN COLLECT_TYPE = 301 THEN
                   'G11_1_2.3.1.G.2021'
                  WHEN COLLECT_TYPE = 302 THEN
                   'G11_1_2.3.2.G.2021'
                  WHEN COLLECT_TYPE = 303 THEN
                   'G11_1_2.3.3.G.2021'
                  WHEN COLLECT_TYPE = 304 THEN
                   'G11_1_2.3.4.G.2021'
                  WHEN COLLECT_TYPE = 305 THEN
                   'G11_1_2.3.5.G.2021'
                  WHEN COLLECT_TYPE = 306 THEN
                   'G11_1_2.3.6.G.2021'
                  WHEN COLLECT_TYPE = 307 THEN
                   'G11_1_2.3.7.G.2021'
                  WHEN COLLECT_TYPE = 308 THEN
                   'G11_1_2.3.8.G.2021'
                  WHEN COLLECT_TYPE = 309 THEN
                   'G11_1_2.3.9.G.2021'
                  WHEN COLLECT_TYPE = 310 THEN
                   'G11_1_2.3.10.G.2021'
                  WHEN COLLECT_TYPE = 311 THEN
                   'G11_1_2.3.11.G.2021'
                  WHEN COLLECT_TYPE = 312 THEN
                   'G11_1_2.3.12.G.2021'
                  WHEN COLLECT_TYPE = 313 THEN
                   'G11_1_2.3.13.G.2021'
                  WHEN COLLECT_TYPE = 314 THEN
                   'G11_1_2.3.14.G.2021'
                  WHEN COLLECT_TYPE = 315 THEN
                   'G11_1_2.3.15.G.2021'
                  WHEN COLLECT_TYPE = 316 THEN
                   'G11_1_2.3.16.G.2021'
                  WHEN COLLECT_TYPE = 317 THEN
                   'G11_1_2.3.17.G.2021'
                  WHEN COLLECT_TYPE = 318 THEN
                   'G11_1_2.3.18.G.2021'
                  WHEN COLLECT_TYPE = 319 THEN
                   'G11_1_2.3.19.G.2021'
                  WHEN COLLECT_TYPE = 320 THEN
                   'G11_1_2.3.20.G.2021'
                  WHEN COLLECT_TYPE = 321 THEN
                   'G11_1_2.3.21.G.2021'
                  WHEN COLLECT_TYPE = 322 THEN
                   'G11_1_2.3.22.G.2021'
                  WHEN COLLECT_TYPE = 323 THEN
                   'G11_1_2.3.23.G.2021'
                  WHEN COLLECT_TYPE = 324 THEN
                   'G11_1_2.3.24.G.2021'
                  WHEN COLLECT_TYPE = 325 THEN
                   'G11_1_2.3.25.G.2021'
                  WHEN COLLECT_TYPE = 326 THEN
                   'G11_1_2.3.26.G.2021'
                  WHEN COLLECT_TYPE = 327 THEN
                   'G11_1_2.3.27.G.2021'
                  WHEN COLLECT_TYPE = 328 THEN
                   'G11_1_2.3.28.G.2021'
                  WHEN COLLECT_TYPE = 329 THEN
                   'G11_1_2.3.29.G.2021'
                  WHEN COLLECT_TYPE = 330 THEN
                   'G11_1_2.3.30.G.2021'
                  WHEN COLLECT_TYPE = 331 THEN
                   'G11_1_2.3.31.G.2021'
                  WHEN COLLECT_TYPE = 332 THEN
                   'G11_1_2.4.1.G.2021'
                  WHEN COLLECT_TYPE = 333 THEN
                   'G11_1_2.4.2.G.2021'
                  WHEN COLLECT_TYPE = 334 THEN
                   'G11_1_2.4.3.G.2021'
                  WHEN COLLECT_TYPE = 335 THEN
                   'G11_1_2.5.1.G.2021'
                  WHEN COLLECT_TYPE = 336 THEN
                   'G11_1_2.5.2.G.2021'
                  WHEN COLLECT_TYPE = 337 THEN
                   'G11_1_2.5.3.G.2021'
                  WHEN COLLECT_TYPE = 338 THEN
                   'G11_1_2.5.4.G.2021'
                  WHEN COLLECT_TYPE = 339 THEN
                   'G11_1_2.6.1.G.2021'
                  WHEN COLLECT_TYPE = 340 THEN
                   'G11_1_2.6.2.G.2021'
                  WHEN COLLECT_TYPE = 341 THEN
                   'G11_1_2.7.1.G.2021'
                  WHEN COLLECT_TYPE = 342 THEN
                   'G11_1_2.7.2.G.2021'
                  WHEN COLLECT_TYPE = 343 THEN
                   'G11_1_2.7.3.G.2021'
                  WHEN COLLECT_TYPE = 344 THEN
                   'G11_1_2.7.4.G.2021'
                  WHEN COLLECT_TYPE = 345 THEN
                   'G11_1_2.7.5.G.2021'
                  WHEN COLLECT_TYPE = 346 THEN
                   'G11_1_2.7.6.G.2021'
                  WHEN COLLECT_TYPE = 347 THEN
                   'G11_1_2.7.7.G.2021'
                  WHEN COLLECT_TYPE = 348 THEN
                   'G11_1_2.7.8.G.2021'
                  WHEN COLLECT_TYPE = 349 THEN
                   'G11_1_2.8.1.G.2021'
                  WHEN COLLECT_TYPE = 350 THEN
                   'G11_1_2.8.2.G.2021'
                  WHEN COLLECT_TYPE = 351 THEN
                   'G11_1_2.9.1.G.2021'
                  WHEN COLLECT_TYPE = 352 THEN
                   'G11_1_2.9.2.G.2021'
                  WHEN COLLECT_TYPE = 353 THEN
                   'G11_1_2.9.3.G.2021'
                  WHEN COLLECT_TYPE = 354 THEN
                   'G11_1_2.10.1.G.2021'
                  WHEN COLLECT_TYPE = 355 THEN
                   'G11_1_2.10.2.G.2021'
                  WHEN COLLECT_TYPE = 356 THEN
                   'G11_1_2.10.3.G.2021'
                  WHEN COLLECT_TYPE = 357 THEN
                   'G11_1_2.10.4.G.2021'
                  WHEN COLLECT_TYPE = 358 THEN
                   'G11_1_2.11.1.G.2021'
                  WHEN COLLECT_TYPE = 359 THEN
                   'G11_1_2.12.1.G.2021'
                  WHEN COLLECT_TYPE = 360 THEN
                   'G11_1_2.12.2.G.2021'
                  WHEN COLLECT_TYPE = 361 THEN
                   'G11_1_2.13.1.G.2021'
                  WHEN COLLECT_TYPE = 362 THEN
                   'G11_1_2.13.2.G.2021'
                  WHEN COLLECT_TYPE = 363 THEN
                   'G11_1_2.13.3.G.2021'
                  WHEN COLLECT_TYPE = 364 THEN
                   'G11_1_2.14.1.G.2021'
                  WHEN COLLECT_TYPE = 365 THEN
                   'G11_1_2.14.2.G.2021'
                  WHEN COLLECT_TYPE = 366 THEN
                   'G11_1_2.14.3.G.2021'
                  WHEN COLLECT_TYPE = 493 THEN
                   'G11_1_2.14.4.G.2021'
                  WHEN COLLECT_TYPE = 367 THEN
                   'G11_1_2.15.1.G.2021'
                  WHEN COLLECT_TYPE = 368 THEN
                   'G11_1_2.15.2.G.2021'
                  WHEN COLLECT_TYPE = 369 THEN
                   'G11_1_2.15.3.G.2021'
                  WHEN COLLECT_TYPE = 370 THEN
                   'G11_1_2.16.1.G.2021'
                  WHEN COLLECT_TYPE = 371 THEN
                   'G11_1_2.17.1.G.2021'
                  WHEN COLLECT_TYPE = 372 THEN
                   'G11_1_2.17.2.G.2021'
                  WHEN COLLECT_TYPE = 373 THEN
                   'G11_1_2.18.1.G.2021'
                  WHEN COLLECT_TYPE = 374 THEN
                   'G11_1_2.18.2.G.2021'
                  WHEN COLLECT_TYPE = 375 THEN
                   'G11_1_2.18.3.G.2021'
                  WHEN COLLECT_TYPE = 376 THEN
                   'G11_1_2.18.4.G.2021'
                  WHEN COLLECT_TYPE = 377 THEN
                   'G11_1_2.18.5.G.2021'
                  WHEN COLLECT_TYPE = 378 THEN
                   'G11_1_2.19.1.G.2021'
                  WHEN COLLECT_TYPE = 379 THEN
                   'G11_1_2.19.2.G.2021'
                  WHEN COLLECT_TYPE = 380 THEN
                   'G11_1_2.19.3.G.2021'
                  WHEN COLLECT_TYPE = 381 THEN
                   'G11_1_2.19.4.G.2021'
                  WHEN COLLECT_TYPE = 382 THEN
                   'G11_1_2.19.5.G.2021'
                  WHEN COLLECT_TYPE = 383 THEN
                   'G11_1_2.19.6.G.2021'
                  WHEN COLLECT_TYPE = 384 THEN
                   'G11_1_2.20.1.G.2021'
                  WHEN COLLECT_TYPE = 385 THEN
                   'G11_1_2.1.1.H.2021'
                  WHEN COLLECT_TYPE = 386 THEN
                   'G11_1_2.1.2.H.2021'
                  WHEN COLLECT_TYPE = 387 THEN
                   'G11_1_2.1.3.H.2021'
                  WHEN COLLECT_TYPE = 388 THEN
                   'G11_1_2.1.4.H.2021'
                  WHEN COLLECT_TYPE = 389 THEN
                   'G11_1_2.1.5.H.2021'
                  WHEN COLLECT_TYPE = 390 THEN
                   'G11_1_2.2.1.H.2021'
                  WHEN COLLECT_TYPE = 391 THEN
                   'G11_1_2.2.2.H.2021'
                  WHEN COLLECT_TYPE = 392 THEN
                   'G11_1_2.2.3.H.2021'
                  WHEN COLLECT_TYPE = 393 THEN
                   'G11_1_2.2.4.H.2021'
                  WHEN COLLECT_TYPE = 394 THEN
                   'G11_1_2.2.5.H.2021'
                  WHEN COLLECT_TYPE = 395 THEN
                   'G11_1_2.2.6.H.2021'
                  WHEN COLLECT_TYPE = 396 THEN
                   'G11_1_2.2.7.H.2021'
                  WHEN COLLECT_TYPE = 397 THEN
                   'G11_1_2.3.1.H.2021'
                  WHEN COLLECT_TYPE = 398 THEN
                   'G11_1_2.3.2.H.2021'
                  WHEN COLLECT_TYPE = 399 THEN
                   'G11_1_2.3.3.H.2021'
                  WHEN COLLECT_TYPE = 400 THEN
                   'G11_1_2.3.4.H.2021'
                  WHEN COLLECT_TYPE = 401 THEN
                   'G11_1_2.3.5.H.2021'
                  WHEN COLLECT_TYPE = 402 THEN
                   'G11_1_2.3.6.H.2021'
                  WHEN COLLECT_TYPE = 403 THEN
                   'G11_1_2.3.7.H.2021'
                  WHEN COLLECT_TYPE = 404 THEN
                   'G11_1_2.3.8.H.2021'
                  WHEN COLLECT_TYPE = 405 THEN
                   'G11_1_2.3.9.H.2021'
                  WHEN COLLECT_TYPE = 406 THEN
                   'G11_1_2.3.10.H.2021'
                  WHEN COLLECT_TYPE = 407 THEN
                   'G11_1_2.3.11.H.2021'
                  WHEN COLLECT_TYPE = 408 THEN
                   'G11_1_2.3.12.H.2021'
                  WHEN COLLECT_TYPE = 409 THEN
                   'G11_1_2.3.13.H.2021'
                  WHEN COLLECT_TYPE = 410 THEN
                   'G11_1_2.3.14.H.2021'
                  WHEN COLLECT_TYPE = 411 THEN
                   'G11_1_2.3.15.H.2021'
                  WHEN COLLECT_TYPE = 412 THEN
                   'G11_1_2.3.16.H.2021'
                  WHEN COLLECT_TYPE = 413 THEN
                   'G11_1_2.3.17.H.2021'
                  WHEN COLLECT_TYPE = 414 THEN
                   'G11_1_2.3.18.H.2021'
                  WHEN COLLECT_TYPE = 415 THEN
                   'G11_1_2.3.19.H.2021'
                  WHEN COLLECT_TYPE = 416 THEN
                   'G11_1_2.3.20.H.2021'
                  WHEN COLLECT_TYPE = 417 THEN
                   'G11_1_2.3.21.H.2021'
                  WHEN COLLECT_TYPE = 418 THEN
                   'G11_1_2.3.22.H.2021'
                  WHEN COLLECT_TYPE = 419 THEN
                   'G11_1_2.3.23.H.2021'
                  WHEN COLLECT_TYPE = 420 THEN
                   'G11_1_2.3.24.H.2021'
                  WHEN COLLECT_TYPE = 421 THEN
                   'G11_1_2.3.25.H.2021'
                  WHEN COLLECT_TYPE = 422 THEN
                   'G11_1_2.3.26.H.2021'
                  WHEN COLLECT_TYPE = 423 THEN
                   'G11_1_2.3.27.H.2021'
                  WHEN COLLECT_TYPE = 424 THEN
                   'G11_1_2.3.28.H.2021'
                  WHEN COLLECT_TYPE = 425 THEN
                   'G11_1_2.3.29.H.2021'
                  WHEN COLLECT_TYPE = 426 THEN
                   'G11_1_2.3.30.H.2021'
                  WHEN COLLECT_TYPE = 427 THEN
                   'G11_1_2.3.31.H.2021'
                  WHEN COLLECT_TYPE = 428 THEN
                   'G11_1_2.4.1.H.2021'
                  WHEN COLLECT_TYPE = 429 THEN
                   'G11_1_2.4.2.H.2021'
                  WHEN COLLECT_TYPE = 430 THEN
                   'G11_1_2.4.3.H.2021'
                  WHEN COLLECT_TYPE = 431 THEN
                   'G11_1_2.5.1.H.2021'
                  WHEN COLLECT_TYPE = 432 THEN
                   'G11_1_2.5.2.H.2021'
                  WHEN COLLECT_TYPE = 433 THEN
                   'G11_1_2.5.3.H.2021'
                  WHEN COLLECT_TYPE = 434 THEN
                   'G11_1_2.5.4.H.2021'
                  WHEN COLLECT_TYPE = 435 THEN
                   'G11_1_2.6.1.H.2021'
                  WHEN COLLECT_TYPE = 436 THEN
                   'G11_1_2.6.2.H.2021'
                  WHEN COLLECT_TYPE = 437 THEN
                   'G11_1_2.7.1.H.2021'
                  WHEN COLLECT_TYPE = 438 THEN
                   'G11_1_2.7.2.H.2021'
                  WHEN COLLECT_TYPE = 439 THEN
                   'G11_1_2.7.3.H.2021'
                  WHEN COLLECT_TYPE = 440 THEN
                   'G11_1_2.7.4.H.2021'
                  WHEN COLLECT_TYPE = 441 THEN
                   'G11_1_2.7.5.H.2021'
                  WHEN COLLECT_TYPE = 442 THEN
                   'G11_1_2.7.6.H.2021'
                  WHEN COLLECT_TYPE = 443 THEN
                   'G11_1_2.7.7.H.2021'
                  WHEN COLLECT_TYPE = 444 THEN
                   'G11_1_2.7.8.H.2021'
                  WHEN COLLECT_TYPE = 445 THEN
                   'G11_1_2.8.1.H.2021'
                  WHEN COLLECT_TYPE = 446 THEN
                   'G11_1_2.8.2.H.2021'
                  WHEN COLLECT_TYPE = 447 THEN
                   'G11_1_2.9.1.H.2021'
                  WHEN COLLECT_TYPE = 448 THEN
                   'G11_1_2.9.2.H.2021'
                  WHEN COLLECT_TYPE = 449 THEN
                   'G11_1_2.9.3.H.2021'
                  WHEN COLLECT_TYPE = 450 THEN
                   'G11_1_2.10.1.H.2021'
                  WHEN COLLECT_TYPE = 451 THEN
                   'G11_1_2.10.2.H.2021'
                  WHEN COLLECT_TYPE = 452 THEN
                   'G11_1_2.10.3.H.2021'
                  WHEN COLLECT_TYPE = 453 THEN
                   'G11_1_2.10.4.H.2021'
                  WHEN COLLECT_TYPE = 454 THEN
                   'G11_1_2.11.1.H.2021'
                  WHEN COLLECT_TYPE = 455 THEN
                   'G11_1_2.12.1.H.2021'
                  WHEN COLLECT_TYPE = 456 THEN
                   'G11_1_2.12.2.H.2021'
                  WHEN COLLECT_TYPE = 457 THEN
                   'G11_1_2.13.1.H.2021'
                  WHEN COLLECT_TYPE = 458 THEN
                   'G11_1_2.13.2.H.2021'
                  WHEN COLLECT_TYPE = 459 THEN
                   'G11_1_2.13.3.H.2021'
                  WHEN COLLECT_TYPE = 460 THEN
                   'G11_1_2.14.1.H.2021'
                  WHEN COLLECT_TYPE = 461 THEN
                   'G11_1_2.14.2.H.2021'
                  WHEN COLLECT_TYPE = 462 THEN
                   'G11_1_2.14.3.H.2021'
                  WHEN COLLECT_TYPE = 494 THEN
                   'G11_1_2.14.4.H.2021'
                  WHEN COLLECT_TYPE = 463 THEN
                   'G11_1_2.15.1.H.2021'
                  WHEN COLLECT_TYPE = 464 THEN
                   'G11_1_2.15.2.H.2021'
                  WHEN COLLECT_TYPE = 465 THEN
                   'G11_1_2.15.3.H.2021'
                  WHEN COLLECT_TYPE = 466 THEN
                   'G11_1_2.16.1.H.2021'
                  WHEN COLLECT_TYPE = 467 THEN
                   'G11_1_2.17.1.H.2021'
                  WHEN COLLECT_TYPE = 468 THEN
                   'G11_1_2.17.2.H.2021'
                  WHEN COLLECT_TYPE = 469 THEN
                   'G11_1_2.18.1.H.2021'
                  WHEN COLLECT_TYPE = 470 THEN
                   'G11_1_2.18.2.H.2021'
                  WHEN COLLECT_TYPE = 471 THEN
                   'G11_1_2.18.3.H.2021'
                  WHEN COLLECT_TYPE = 472 THEN
                   'G11_1_2.18.4.H.2021'
                  WHEN COLLECT_TYPE = 473 THEN
                   'G11_1_2.18.5.H.2021'
                  WHEN COLLECT_TYPE = 474 THEN
                   'G11_1_2.19.1.H.2021'
                  WHEN COLLECT_TYPE = 475 THEN
                   'G11_1_2.19.2.H.2021'
                  WHEN COLLECT_TYPE = 476 THEN
                   'G11_1_2.19.3.H.2021'
                  WHEN COLLECT_TYPE = 477 THEN
                   'G11_1_2.19.4.H.2021'
                  WHEN COLLECT_TYPE = 478 THEN
                   'G11_1_2.19.5.H.2021'
                  WHEN COLLECT_TYPE = 479 THEN
                   'G11_1_2.19.6.H.2021'
                  WHEN COLLECT_TYPE = 480 THEN
                   'G11_1_2.20.1.H.2021'
                END;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '2.1农业 截止 2.20国际组织 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 2;
    V_STEP_FLAG := 0;
    V_STEP_DESC := ' 2.21 个人贷款  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   G1101 2.21.1 信用卡
    --====================================================
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_PUB_DATA_COLLECT_G1101';

    --信用卡系统取数，009803机构
INSERT INTO CBRC_PUB_DATA_COLLECT_G1101
  (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)

    --ALTER BY SHIYU 20241217 信用卡修改取数逻辑
    SELECT '009803' AS ORG_NUM,
             CASE
               WHEN LXQKQS >= 7 THEN
                'G11_1_2.21.1.H'
               WHEN LXQKQS BETWEEN 5 AND 6 THEN
                'G11_1_2.21.1.G'
               WHEN LXQKQS = 4 THEN
                'G11_1_2.21.1.F'
               WHEN LXQKQS BETWEEN 1 AND 3 THEN
                'G11_1_2.21.1.D'
               ELSE
                'G11_1_2.21.1.C'
             END AS COLLECT_TYPE,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY  CASE
               WHEN LXQKQS >= 7 THEN
                'G11_1_2.21.1.H'
               WHEN LXQKQS BETWEEN 5 AND 6 THEN
                'G11_1_2.21.1.G'
               WHEN LXQKQS = 4 THEN
                'G11_1_2.21.1.F'
               WHEN LXQKQS BETWEEN 1 AND 3 THEN
                'G11_1_2.21.1.D'
               ELSE
                'G11_1_2.21.1.C'
             END;

    --2.21.1.1 DSR<=30%
    --2.21.1.2 30%<=DSR <=50%
    --2.21.1.3 DSR >=50%

    V_STEP_FLAG := 1;
    V_STEP_DESC := '信用卡 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   V_STEP_ID   := 3;
    V_STEP_FLAG := 0;
    V_STEP_DESC := ' 2.21.2 汽车  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   G1101 2.21.2 汽车
    --====================================================
    INSERT INTO CBRC_PUB_DATA_COLLECT_G1101
      (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
    
      SELECT ORG_NUM AS ORG_NUM,
             CASE
               WHEN LOAN_GRADE_CD = '1' THEN
                'G11_1_2.21.2.C'
               WHEN LOAN_GRADE_CD = '2' THEN
                'G11_1_2.21.2.D'
               WHEN LOAN_GRADE_CD = '3' THEN
                'G11_1_2.21.2.F'
               WHEN LOAN_GRADE_CD = '4' THEN
                'G11_1_2.21.2.G'
               WHEN LOAN_GRADE_CD = '5' THEN
                'G11_1_2.21.2.H'
             END AS ITEM_NUM,
             SUM(LOAN_ACCT_BAL * U.CCY_RATE) +
             SUM(INT_ADJEST_AMT * U.CCY_RATE) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ACCT_TYP = '010301'
         AND a.acct_typ not LIKE '90%'
         AND A.FUND_USE_LOC_CD = 'I'
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         and A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY ORG_NUM,
                CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_2.21.2.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_2.21.2.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_2.21.2.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_2.21.2.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_2.21.2.H'
                END;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '2.21.2 汽车 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 4;
    V_STEP_FLAG := 0;
    V_STEP_DESC := ' 2.21.3 住房按揭贷款  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   G1101 2.21.3 住房按揭贷款
    --====================================================
    INSERT INTO CBRC_PUB_DATA_COLLECT_G1101
      (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
    
      SELECT ORG_NUM AS ORG_NUM,
             CASE
               WHEN LOAN_GRADE_CD = '1' THEN
                'G11_1_2.21.3.C'
               WHEN LOAN_GRADE_CD = '2' THEN
                'G11_1_2.21.3.D'
               WHEN LOAN_GRADE_CD = '3' THEN
                'G11_1_2.21.3.F'
               WHEN LOAN_GRADE_CD = '4' THEN
                'G11_1_2.21.3.G'
               WHEN LOAN_GRADE_CD = '5' THEN
                'G11_1_2.21.3.H'
             END AS ITEM_NUM,
             SUM(LOAN_ACCT_BAL * U.CCY_RATE) +
             SUM(INT_ADJEST_AMT * U.CCY_RATE) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ACCT_TYP LIKE '0101%'
         AND A.FUND_USE_LOC_CD = 'I'
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.ACCT_STS <> '3'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_2.21.3.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_2.21.3.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_2.21.3.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_2.21.3.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_2.21.3.H'
                END;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '2.21.3 住房按揭贷款 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 5;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '2.21.4 助学贷款  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   G1101 2.21.4 助学贷款
    --====================================================

    V_STEP_FLAG := 1;
    V_STEP_DESC := '2.21.4 助学贷款 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 6;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '2.21.5 其他  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   G1101 2.21.5 其他 （未刨去助学贷款？）
    --====================================================

    INSERT INTO CBRC_PUB_DATA_COLLECT_G1101
      (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
    
      SELECT ORG_NUM AS ORG_NUM,
             CASE
               WHEN LOAN_GRADE_CD = '1' THEN
                'G11_1_2.21.4.C'
               WHEN LOAN_GRADE_CD = '2' THEN
                'G11_1_2.21.4.D'
               WHEN LOAN_GRADE_CD = '3' THEN
                'G11_1_2.21.4.F'
               WHEN LOAN_GRADE_CD = '4' THEN
                'G11_1_2.21.4.G'
               WHEN LOAN_GRADE_CD = '5' THEN
                'G11_1_2.21.4.H'
             END AS ITEM_NUM,
             SUM(LOAN_ACCT_BAL * u.ccy_rate) +
             SUM(INT_ADJEST_AMT * u.ccy_rate) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_LOAN a
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ACCT_TYP LIKE '01%'
         AND A.ACCT_TYP NOT LIKE '0102%'
         AND A.ACCT_TYP NOT IN ('010301', '010101', '010199')
         AND A.FUND_USE_LOC_CD = 'I'
         and A.acct_typ not LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.ACCT_STS <> '3'
         and A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY ORG_NUM,
                CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_2.21.4.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_2.21.4.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_2.21.4.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_2.21.4.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_2.21.4.H'
                END;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '2.21.5 其他 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 7;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '2.22 买断式转贴现  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   G1101 2.22 买断式转贴现
    --====================================================
    INSERT INTO CBRC_PUB_DATA_COLLECT_G1101
      (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
      SELECT ORG_NUM AS ORG_NUM,
             CASE
               WHEN LOAN_GRADE_CD = '1' THEN
                'G11_1_2.22..C.091231'
               WHEN LOAN_GRADE_CD = '2' THEN
                'G11_1_2.22..D.091231'
               WHEN LOAN_GRADE_CD = '3' THEN
                'G11_1_2.22..F.091231'
               WHEN LOAN_GRADE_CD = '4' THEN
                'G11_1_2.22..G.091231'
               WHEN LOAN_GRADE_CD = '5' THEN
                'G11_1_2.22..H.091231'
             END AS ITEM_NUM,
             SUM(LOAN_ACCT_BAL) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_LOAN A
       WHERE 
       SUBSTR(ITEM_CD,1,6) IN ('130102', '130105')
         AND FUND_USE_LOC_CD = 'I'
         AND DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY ORG_NUM,
                CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_2.22..C.091231'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_2.22..D.091231'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_2.22..F.091231'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_2.22..G.091231'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_2.22..H.091231'
                END;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '2.22 买断式转贴现 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 8;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '3 对境外贷款  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --   G1101 2.23 买断其他票据类资产 无逻辑，目前不取数

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G1101' AS REP_NUM,
             COLLECT_TYPE, --指标号
             SUM(COLLECT_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_PUB_DATA_COLLECT_G1101
       WHERE COLLECT_TYPE IS NOT NULL
       GROUP BY ORG_NUM, --机构号
                COLLECT_TYPE; --报表类型
    COMMIT;

    --====================================================
    --   G1101 3 对境外贷款
    --====================================================
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
    
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             CASE
               WHEN LOAN_GRADE_CD = '1' THEN
                'G11_1_3..C'
               WHEN LOAN_GRADE_CD = '2' THEN
                'G11_1_3..D'
               WHEN LOAN_GRADE_CD = '3' THEN
                'G11_1_3..F'
               WHEN LOAN_GRADE_CD = '4' THEN
                'G11_1_3..G'
               WHEN LOAN_GRADE_CD = '5' THEN
                'G11_1_3..H'
             END AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL * U.CCY_RATE) +
             SUM(INT_ADJEST_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.FUND_USE_LOC_CD = 'O'
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_3..C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_3..D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_3..F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_3..G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_3..H'
                END;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '3 对境外贷款 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    V_STEP_ID   := 9;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '7.个人经营性贷款  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   G1101 7 个人经营性贷款
    --====================================================

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             t.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G1101' AS REP_NUM,
              CASE
               WHEN LOAN_GRADE_CD = '1' THEN
                'G11_1_7..C.091231'
               WHEN LOAN_GRADE_CD = '2' THEN
                'G11_1_7..D.091231'
               WHEN LOAN_GRADE_CD = '3' THEN
                'G11_1_7..F.091231'
               WHEN LOAN_GRADE_CD = '4' THEN
                'G11_1_7..G.091231'
               WHEN LOAN_GRADE_CD = '5' THEN
                'G11_1_7..H.091231'
             END AS ITEM_NUM,
             SUM(LOAN_ACCT_BAL * U.CCY_RATE + INT_ADJEST_AMT * U.CCY_RATE) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.ACCT_TYP LIKE '0102%'
         AND T.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_STS <> '3'
         and  t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY t.ORG_NUM, --机构号
                 CASE
               WHEN LOAN_GRADE_CD = '1' THEN
                'G11_1_7..C.091231'
               WHEN LOAN_GRADE_CD = '2' THEN
                'G11_1_7..D.091231'
               WHEN LOAN_GRADE_CD = '3' THEN
                'G11_1_7..F.091231'
               WHEN LOAN_GRADE_CD = '4' THEN
                'G11_1_7..G.091231'
               WHEN LOAN_GRADE_CD = '5' THEN
                'G11_1_7..H.091231'
             END;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '7.个人经营性贷款 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 10;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '4.1其中：逾期30天以内的贷款  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   G1101 4 逾期贷款
    --====================================================

    --====================================================
    --   G1101 4.1其中：逾期30天以内的贷款,求和分别插入临时表中
    --====================================================
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_A_REPT_LOAN_BAL_G1101';
    INSERT INTO CBRC_A_REPT_LOAN_BAL_G1101
      (OD_LOAN_ACCT_BAL_RMB, --逾期金额_人民币
       LOAN_ACCT_BAL_RMB, --贷款余额_人民币
       ORG_NUM,
       FLAG_TMP)
    ---  刨除网贷数据 经营性
      SELECT 0 AS OD_LOAN_ACCT_BAL_RMB, --逾期金额_人民币

             SUM(LOAN_ACCT_BAL * U.CCY_RATE) +
             SUM(INT_ADJEST_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
             ORG_NUM,
             CASE
               WHEN LOAN_GRADE_CD = '1' THEN
                1
               WHEN LOAN_GRADE_CD = '2' THEN
                2
               WHEN LOAN_GRADE_CD = '3' THEN
                3
               WHEN LOAN_GRADE_CD = '4' THEN
                4
               WHEN LOAN_GRADE_CD = '5' THEN
                5
             END FLAG_TMP
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE OD_DAYS > 0
         AND OD_DAYS <= 30 -- 20210323 chm modify 之前是 < 30
         AND OD_FLG = 'Y'
            -- AND VERSION_CBRC = 'CBRC'
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND (ACCT_TYP NOT LIKE '0101%' AND ACCT_TYP NOT LIKE '0103%' AND
             ACCT_TYP NOT LIKE '0104%' AND ACCT_TYP NOT LIKE '0199%' AND
             ACCT_TYP <> 'E01' AND ACCT_TYP <> 'E02' AND
             ACCT_TYP NOT LIKE '90%')
            --   AND A.DATE_SOURCESD NOT IN ('10301057', '10301059')
         AND ORG_NUM <> '009803' --20210323 modify chm
         AND SUBSTR(a.item_cd,1,6) not in ('130102', '130105') --转帖现 不算逾期   20210323 modify chm
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY ORG_NUM,
                CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   1
                  WHEN LOAN_GRADE_CD = '2' THEN
                   2
                  WHEN LOAN_GRADE_CD = '3' THEN
                   3
                  WHEN LOAN_GRADE_CD = '4' THEN
                   4
                  WHEN LOAN_GRADE_CD = '5' THEN
                   5
                END;

    COMMIT;
    --==================================逾期金额   消费型
    INSERT INTO CBRC_A_REPT_LOAN_BAL_G1101
      (OD_LOAN_ACCT_BAL_RMB, --逾期金额_人民币
       LOAN_ACCT_BAL_RMB, --贷款余额_人民币
       ORG_NUM,
       FLAG_TMP)
      SELECT 
       /*alter by shiyu 20241105 修改个人消费贷款逾期的规则：如果不是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款取贷款余额；
            如果是按月分期还款的个人消费贷款本金或利息逾期 */
       SUM(CASE
             WHEN a.REPAY_TYP ='1' and  a.PAY_TYPE in   ('01','02','10','11')   then --还款方式不为按月JLBA202412040012
               OD_LOAN_ACCT_BAL* U.CCY_RATE
             ELSE
               LOAN_ACCT_BAL* U.CCY_RATE
           END) AS OD_LOAN_ACCT_BAL_RMB,
       0 AS LOAN_ACCT_BAL_RMB_,
       ORG_NUM,
       CASE
         WHEN LOAN_GRADE_CD = '1' THEN
          1
         WHEN LOAN_GRADE_CD = '2' THEN
          2
         WHEN LOAN_GRADE_CD = '3' THEN
          3
         WHEN LOAN_GRADE_CD = '4' THEN
          4
         WHEN LOAN_GRADE_CD = '5' THEN
          5
       END FLAG_TMP
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE OD_DAYS > 0
         AND OD_DAYS <= 30 -- 20210323 chm modify 之前是 < 30
         AND OD_FLG = 'Y'
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND (ACCT_TYP LIKE '0101%' OR ACCT_TYP LIKE '0103%' OR
             ACCT_TYP LIKE '0104%' OR ACCT_TYP LIKE '0199%' 
             )AND ACCT_TYP NOT LIKE '90%'
         AND ORG_NUM <> '009803'
         AND SUBSTR(A.ITEM_CD,1,6) not in ('130102', '130105') --转帖现 不算逾期   20210323 modify chm
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY ORG_NUM,
                CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   1
                  WHEN LOAN_GRADE_CD = '2' THEN
                   2
                  WHEN LOAN_GRADE_CD = '3' THEN
                   3
                  WHEN LOAN_GRADE_CD = '4' THEN
                   4
                  WHEN LOAN_GRADE_CD = '5' THEN
                   5
                END;

    COMMIT;
    --==================================信用卡
    INSERT INTO CBRC_A_REPT_LOAN_BAL_G1101
      (OD_LOAN_ACCT_BAL_RMB, --逾期金额_人民币
       LOAN_ACCT_BAL_RMB, --贷款余额_人民币
       ORG_NUM,
       FLAG_TMP)
    
    --JLBA202412040012
      SELECT SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 U.CCY_RATE) AS OD_LOAN_ACCT_BAL_RMB, --逾期金额_人民币
             0 AS LOAN_ACCT_BAL_RMB,
             '009803',
             2
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
        and LXQKQS=1
       ;
    COMMIT;
    --====================================================
    --   G1101 4.1其中：逾期30天以内的贷款
    --====================================================
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             CASE
               WHEN FLAG_TMP = '1' THEN
                'G11_1_4.1.C'
               WHEN FLAG_TMP = '2' THEN
                'G11_1_4.1.D'
               WHEN FLAG_TMP = '3' THEN
                'G11_1_4.1.F'
               WHEN FLAG_TMP = '4' THEN
                'G11_1_4.1.G'
               WHEN FLAG_TMP = '5' THEN
                'G11_1_4.1.H'
             END AS ITEM_NUM, --指标号
             SUM(NVL(LOAN_ACCT_BAL_RMB, 0) + NVL(OD_LOAN_ACCT_BAL_RMB, 0)) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM CBRC_A_REPT_LOAN_BAL_G1101
       WHERE FLAG_TMP IN ('1', '2', '3', '4', '5')
       GROUP BY ORG_NUM,
                CASE
                  WHEN FLAG_TMP = '1' THEN
                   'G11_1_4.1.C'
                  WHEN FLAG_TMP = '2' THEN
                   'G11_1_4.1.D'
                  WHEN FLAG_TMP = '3' THEN
                   'G11_1_4.1.F'
                  WHEN FLAG_TMP = '4' THEN
                   'G11_1_4.1.G'
                  WHEN FLAG_TMP = '5' THEN
                   'G11_1_4.1.H'
                END;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '4.1其中：逾期30天以内的贷款 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 11;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '4.2逾期31天到60天贷款  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   G1101 4.2逾期31天到60天贷款,求和分别插入临时表中   消费型
    --====================================================
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_A_REPT_LOAN_BAL_G1101';
    INSERT INTO CBRC_A_REPT_LOAN_BAL_G1101
      (OD_LOAN_ACCT_BAL_RMB, --逾期金额_人民币
       LOAN_ACCT_BAL_RMB, --贷款余额_人民币
       ORG_NUM,
       FLAG_TMP)

      SELECT --SUM(OD_LOAN_ACCT_BAL * U.CCY_RATE) AS OD_LOAN_ACCT_BAL_RMB, --逾期金额_人民币

      /*alter by shiyu 20241105 修改个人消费贷款逾期的规则：如果不是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款取贷款余额；
            如果是按月分期还款的个人消费贷款本金或利息逾期 */
       SUM(CASE
             WHEN /*A.PAY_TYPE NOT IN ('01', '02') THEN*/ a.REPAY_TYP ='1' and  a.PAY_TYPE in   ('01','02','10','11')  then
        --还款方式不为按月JLBA202412040012
                OD_LOAN_ACCT_BAL* U.CCY_RATE
             ELSE
            LOAN_ACCT_BAL  * U.CCY_RATE
           END) AS OD_LOAN_ACCT_BAL_RMB,
       -- 20210323 modify chm 个人消费 还款方式 是 一次还本 取 贷款余额 否则 取 本金逾期金额
       0 AS LOAN_ACCT_BAL_RMB,
       ORG_NUM,
       CASE
         WHEN LOAN_GRADE_CD = '1' THEN
          1
         WHEN LOAN_GRADE_CD = '2' THEN
          2
         WHEN LOAN_GRADE_CD = '3' THEN
          3
         WHEN LOAN_GRADE_CD = '4' THEN
          4
         WHEN LOAN_GRADE_CD = '5' THEN
          5
       END FLAG_TMP
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE OD_DAYS > 30
         AND OD_DAYS < 61
         AND OD_FLG = 'Y'
            --AND VERSION_CBRC = 'CBRC'
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND (ACCT_TYP LIKE '0101%' OR ACCT_TYP LIKE '0103%' OR
             ACCT_TYP LIKE '0104%' OR ACCT_TYP LIKE '0199%' /*OR ACCT_TYP = 'E01'*/
             AND ACCT_TYP NOT LIKE '90%')
            --AND A.DATE_SOURCESD NOT IN ('10301057', '10301059')
         AND ORG_NUM <> '009803'
         AND SUBSTR(a.item_cd,1,6) not in ('130102', '130105') ---20210323 modify chm   12906 转帖现 不算逾期
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY ORG_NUM,
                CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   1
                  WHEN LOAN_GRADE_CD = '2' THEN
                   2
                  WHEN LOAN_GRADE_CD = '3' THEN
                   3
                  WHEN LOAN_GRADE_CD = '4' THEN
                   4
                  WHEN LOAN_GRADE_CD = '5' THEN
                   5
                END;

    COMMIT;
    --==================================逾期金额  经营性
    INSERT INTO CBRC_A_REPT_LOAN_BAL_G1101
      (OD_LOAN_ACCT_BAL_RMB, --逾期金额_人民币
       LOAN_ACCT_BAL_RMB, --贷款余额_人民币
       ORG_NUM,
       FLAG_TMP)

      SELECT 0 AS OD_LOAN_ACCT_BAL_RMB, --逾期金额_人民币
             SUM(LOAN_ACCT_BAL * U.CCY_RATE) +
             SUM(INT_ADJEST_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB, --贷款余额_人民币
             ORG_NUM,
             CASE
               WHEN LOAN_GRADE_CD = '1' THEN
                1
               WHEN LOAN_GRADE_CD = '2' THEN
                2
               WHEN LOAN_GRADE_CD = '3' THEN
                3
               WHEN LOAN_GRADE_CD = '4' THEN
                4
               WHEN LOAN_GRADE_CD = '5' THEN
                5
             END FLAG_TMP
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE OD_DAYS > 30
         AND OD_DAYS < 61
         AND OD_FLG = 'Y'
            --AND VERSION_CBRC = 'CBRC'
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND (ACCT_TYP NOT LIKE '0101%' AND ACCT_TYP NOT LIKE '0103%' AND
             ACCT_TYP NOT LIKE '0104%' AND ACCT_TYP NOT LIKE '0199%' AND
             ACCT_TYP <> 'E01' AND ACCT_TYP <> 'E02' AND
             ACCT_TYP NOT LIKE '90%')
            --AND A.DATE_SOURCESD NOT IN ('10301057', '10301059')
         AND ORG_NUM <> '009803'
         AND SUBSTR(a.item_cd,1,6) not in ('130102', '130105') ---20210323 modify chm   12906 转帖现 不算逾期
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY ORG_NUM,
                CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   1
                  WHEN LOAN_GRADE_CD = '2' THEN
                   2
                  WHEN LOAN_GRADE_CD = '3' THEN
                   3
                  WHEN LOAN_GRADE_CD = '4' THEN
                   4
                  WHEN LOAN_GRADE_CD = '5' THEN
                   5
                END;

    COMMIT;
    --==================================信用卡
    INSERT INTO CBRC_A_REPT_LOAN_BAL_G1101
      (OD_LOAN_ACCT_BAL_RMB, --逾期金额_人民币
       LOAN_ACCT_BAL_RMB, --贷款余额_人民币
       ORG_NUM,
       FLAG_TMP)
  
      --JLBA202412040012
      SELECT SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 U.CCY_RATE) AS OD_LOAN_ACCT_BAL_RMB, --逾期金额_人民币
             0 AS LOAN_ACCT_BAL_RMB,
             '009803',
             2
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
           AND T.LXQKQS=2
       ;
    COMMIT;

     --====================================================
    --   G1101 4.2逾期31天到60天贷款
    --====================================================
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             CASE
               WHEN FLAG_TMP = '1' THEN
                'G11_1_4.2.C'
               WHEN FLAG_TMP = '2' THEN
                'G11_1_4.2.D'
               WHEN FLAG_TMP = '3' THEN
                'G11_1_4.2.F'
               WHEN FLAG_TMP = '4' THEN
                'G11_1_4.2.G'
               WHEN FLAG_TMP = '5' THEN
                'G11_1_4.2.H'
             END AS ITEM_NUM, --指标号
             SUM(NVL(LOAN_ACCT_BAL_RMB, 0) + NVL(OD_LOAN_ACCT_BAL_RMB, 0)) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM CBRC_A_REPT_LOAN_BAL_G1101
       WHERE FLAG_TMP IN ('1', '2', '3', '4', '5')
       GROUP BY ORG_NUM,
                CASE
                  WHEN FLAG_TMP = '1' THEN
                   'G11_1_4.2.C'
                  WHEN FLAG_TMP = '2' THEN
                   'G11_1_4.2.D'
                  WHEN FLAG_TMP = '3' THEN
                   'G11_1_4.2.F'
                  WHEN FLAG_TMP = '4' THEN
                   'G11_1_4.2.G'
                  WHEN FLAG_TMP = '5' THEN
                   'G11_1_4.2.H'
                END;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '4.2逾期31天到60天贷款 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 12;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '4.3逾期61天到90天贷款  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   G1101 4.3逾期61天到90天贷款,求和分别插入临时表中
    --====================================================
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_A_REPT_LOAN_BAL_G1101';
    INSERT INTO CBRC_A_REPT_LOAN_BAL_G1101
      (OD_LOAN_ACCT_BAL_RMB, --逾期金额_人民币
       LOAN_ACCT_BAL_RMB, --贷款余额_人民币
       ORG_NUM,
       FLAG_TMP)
      SELECT --SUM(OD_LOAN_ACCT_BAL * U.CCY_RATE) AS OD_LOAN_ACCT_BAL_RMB, --逾期金额_人民币
    /*alter by shiyu 20241105 修改个人消费贷款逾期的规则：如果不是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款取贷款余额；
            如果是按月分期还款的个人消费贷款本金或利息逾期 */
       SUM(CASE
             WHEN /*A.PAY_TYPE NOT IN ('01', '02') THEN */--zhoujungkun 20211014 新信贷伤心对比差异
                a.REPAY_TYP ='1' and  a.PAY_TYPE in   ('01','02','10','11')  then --还款方式不为按月JLBA202412040012
               OD_LOAN_ACCT_BAL * U.CCY_RATE
             ELSE
              LOAN_ACCT_BAL * U.CCY_RATE
           END) AS OD_LOAN_ACCT_BAL_RMB,
       -- 20210323 modify chm 个人消费 还款方式 是 一次还本 取 贷款余额 否则 取 本金逾期金额
       0 AS LOAN_ACCT_BAL_RMB,
       ORG_NUM,
       CASE
         WHEN LOAN_GRADE_CD = '1' THEN
          1
         WHEN LOAN_GRADE_CD = '2' THEN
          2
         WHEN LOAN_GRADE_CD = '3' THEN
          3
         WHEN LOAN_GRADE_CD = '4' THEN
          4
         WHEN LOAN_GRADE_CD = '5' THEN
          5
       END FLAG_TMP
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE OD_DAYS > 60
            /*and OD_DAYs < 90*/
         AND OD_DAYS <= 90 -- 20210323 modify chm
         AND OD_FLG = 'Y'
            --AND VERSION_CBRC = 'CBRC'
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND (ACCT_TYP LIKE '0101%' OR ACCT_TYP LIKE '0103%' OR
             ACCT_TYP LIKE '0104%' OR ACCT_TYP LIKE '0199%' /*OR ACCT_TYP = 'E01'*/
             AND ACCT_TYP NOT LIKE '90%')
            --AND A.DATE_SOURCESD NOT IN ('10301057', '10301059')
         AND ORG_NUM <> '009803'
         AND SUBSTR(a.item_cd ,1,6)not in ('130102', '130105') ---20210323 modify chm   12906 转帖现 不算逾期
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY ORG_NUM,
                CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   1
                  WHEN LOAN_GRADE_CD = '2' THEN
                   2
                  WHEN LOAN_GRADE_CD = '3' THEN
                   3
                  WHEN LOAN_GRADE_CD = '4' THEN
                   4
                  WHEN LOAN_GRADE_CD = '5' THEN
                   5
                END;

    COMMIT;
    --==================================逾期金额
    INSERT INTO CBRC_A_REPT_LOAN_BAL_G1101
      (OD_LOAN_ACCT_BAL_RMB, --逾期金额_人民币
       LOAN_ACCT_BAL_RMB, --贷款余额_人民币
       ORG_NUM,
       FLAG_TMP)
      SELECT 0 AS OD_LOAN_ACCT_BAL_RMB, --逾期金额_人民币
             SUM(LOAN_ACCT_BAL * U.CCY_RATE) +
             SUM(INT_ADJEST_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB, --贷款余额_人民币
             ORG_NUM,
             CASE
               WHEN LOAN_GRADE_CD = '1' THEN
                1
               WHEN LOAN_GRADE_CD = '2' THEN
                2
               WHEN LOAN_GRADE_CD = '3' THEN
                3
               WHEN LOAN_GRADE_CD = '4' THEN
                4
               WHEN LOAN_GRADE_CD = '5' THEN
                5
             END FLAG_TMP
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE OD_DAYS > 60
            /*and OD_DAYs < 90*/
         AND OD_DAYS <= 90 -- 20210323 modify chm
         AND OD_FLG = 'Y'
            --AND VERSION_CBRC = 'CBRC'
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND (ACCT_TYP NOT LIKE '0101%' AND ACCT_TYP NOT LIKE '0103%' AND
             ACCT_TYP NOT LIKE '0104%' AND ACCT_TYP NOT LIKE '0199%' AND
             ACCT_TYP <> 'E01' AND ACCT_TYP <> 'E02' AND
             ACCT_TYP NOT LIKE '90%')
            --AND A.DATE_SOURCESD NOT IN ('10301057', '10301059')
         AND ORG_NUM <> '009803'
         AND SUBSTR(a.item_cd,1,6) not in ('130102', '130105') ---20210323 modify chm   12906 转帖现 不算逾期
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY ORG_NUM,
                CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   1
                  WHEN LOAN_GRADE_CD = '2' THEN
                   2
                  WHEN LOAN_GRADE_CD = '3' THEN
                   3
                  WHEN LOAN_GRADE_CD = '4' THEN
                   4
                  WHEN LOAN_GRADE_CD = '5' THEN
                   5
                END;

    COMMIT;

     --==================================信用卡
    INSERT INTO CBRC_A_REPT_LOAN_BAL_G1101
      (OD_LOAN_ACCT_BAL_RMB, --逾期金额_人民币
       LOAN_ACCT_BAL_RMB, --贷款余额_人民币
       ORG_NUM,
       FLAG_TMP)
    --JLBA202412040012
      SELECT SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 U.CCY_RATE) AS OD_LOAN_ACCT_BAL_RMB, --逾期金额_人民币
             0 AS LOAN_ACCT_BAL_RMB,
             '009803',
             2
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
           AND T.LXQKQS=3
       ;
    --====================================================
    --   G1101 4.3逾期61天到90天贷款
    --====================================================
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             CASE
               WHEN FLAG_TMP = '1' THEN
                'G11_1_4.7.C'
               WHEN FLAG_TMP = '2' THEN
                'G11_1_4.7.D'
               WHEN FLAG_TMP = '3' THEN
                'G11_1_4.7.F'
               WHEN FLAG_TMP = '4' THEN
                'G11_1_4.7.G'
               WHEN FLAG_TMP = '5' THEN
                'G11_1_4.7.H'
             END AS ITEM_NUM, --指标号
             SUM(NVL(LOAN_ACCT_BAL_RMB, 0) + NVL(OD_LOAN_ACCT_BAL_RMB, 0)) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM CBRC_A_REPT_LOAN_BAL_G1101
       WHERE FLAG_TMP IN ('1', '2', '3', '4', '5')
       GROUP BY ORG_NUM,
                CASE
                  WHEN FLAG_TMP = '1' THEN
                   'G11_1_4.7.C'
                  WHEN FLAG_TMP = '2' THEN
                   'G11_1_4.7.D'
                  WHEN FLAG_TMP = '3' THEN
                   'G11_1_4.7.F'
                  WHEN FLAG_TMP = '4' THEN
                   'G11_1_4.7.G'
                  WHEN FLAG_TMP = '5' THEN
                   'G11_1_4.7.H'
                END;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '4.3逾期61天到90天贷款 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 13;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '4.4逾期91天到180天贷款-4.7逾期361天以上贷款  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --==================================================
    --   G1101 4.4逾期91天到180天贷款-4.7逾期361天以上贷款
    --==================================================
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )

      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             CASE
               WHEN OD_DAY = '180D' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.3.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.3.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.3.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.3.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.3.H'
                END)
               WHEN OD_DAY = '270D' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.4.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.4.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.4.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.4.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.4.H'
                END)
               WHEN OD_DAY = '360D' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.5.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.5.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.5.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.5.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.5.H'
                END)
               WHEN OD_DAY = '360AD' THEN
                (CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_4.6.C'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_4.6.D'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_4.6.F'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_4.6.G'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_4.6.H'
                END)
             END AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL * U.CCY_RATE) +
             SUM(INT_ADJEST_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM (SELECT CASE
                       WHEN A.OD_DAYS > 360 THEN
                        '360AD'
                       WHEN A.OD_DAYS IS NULL THEN
                        '360AD' --shiwenbo by 20170313-OD_DAY 增加逾期天数为空的判断，将数据放入一年以上
                       WHEN A.OD_DAYS > 270 THEN
                        '360D'
                       WHEN A.OD_DAYS > 180 THEN
                        '270D'
                       WHEN A.OD_DAYS > 90 THEN
                        '180D'
                       WHEN A.OD_DAYS > 60 THEN
                        '60D' -- 20200114 modify ljp 增加 60天 期限
                       WHEN A.OD_DAYS > 30 THEN
                        '90D'
                       WHEN A.OD_DAYS > 0 THEN
                        '30D'
                     END AS OD_DAY,
                     A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL,
                     A.INT_ADJEST_AMT AS INT_ADJEST_AMT,
                     A.CURR_CD AS CURR_CD,
                     A.OD_FLG AS OD_FLG,
                     A.DATA_DATE AS DATA_DATE,
                     A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
                     A.ACCT_STS AS ACCT_STS,
                     A.ORG_NUM AS ORG_NUM,
                     A.ACCT_TYP AS ACCT_TYP
                FROM SMTMODS_L_ACCT_LOAN A
                where A.CANCEL_FLG <> 'Y'
                  AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
        ) A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.OD_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.OD_DAY IN ('180D', '270D', '360D', '360AD')
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.ACCT_TYP not LIKE '90%'
         AND A.ACCT_STS <> '3'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN OD_DAY = '180D' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.3.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.3.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.3.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.3.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.3.H'
                   END)
                  WHEN OD_DAY = '270D' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.4.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.4.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.4.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.4.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.4.H'
                   END)
                  WHEN OD_DAY = '360D' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.5.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.5.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.5.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.5.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.5.H'
                   END)
                  WHEN OD_DAY = '360AD' THEN
                   (CASE
                     WHEN LOAN_GRADE_CD = '1' THEN
                      'G11_1_4.6.C'
                     WHEN LOAN_GRADE_CD = '2' THEN
                      'G11_1_4.6.D'
                     WHEN LOAN_GRADE_CD = '3' THEN
                      'G11_1_4.6.F'
                     WHEN LOAN_GRADE_CD = '4' THEN
                      'G11_1_4.6.G'
                     WHEN LOAN_GRADE_CD = '5' THEN
                      'G11_1_4.6.H'
                   END)
                END;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
    --JLBA202412040012
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009803' AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             'G11_1_4.3.F' AS ITEM_NUM, --指标号
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = t.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         and LXQKQS = 4;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
    --JLBA202412040012
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009803' AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             'G11_1_4.3.G' AS ITEM_NUM, --指标号
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
          and LXQKQS in (5,6);
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       ) --该部分开发未测试，且需上游提供欠本欠息日期字段
    --JLBA202412040012
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009803' AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             'G11_1_4.4.H' AS ITEM_NUM, --指标号
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
       /*  and t.p_od_date > t.i_od_date
         and ((D_DATADATE_CCY - t.i_od_date + 1) > 180 or
             (D_DATADATE_CCY - t.i_od_date + 1) < 271)*/
        and LXQKQS in (7,8,9);

    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      --JLBA202412040012
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009803' AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             'G11_1_4.5.H' AS ITEM_NUM, --指标号
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
             and LXQKQS in (10,11,12);
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
    
      --JLBA202412040012
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009803' AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             'G11_1_4.6.H' AS ITEM_NUM, --指标号
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
        /* and t.p_od_date < t.i_od_date
         and (D_DATADATE_CCY - t.p_od_date + 1) > 360;*/
            and LXQKQS >= 13;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '4.4逾期91天到180天贷款-4.7逾期361天以上贷款 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


      V_STEP_ID   := 14;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '5.1--5.2重组贷款-年初重组贷款,期间新重组方案 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   G1101 重组贷款-年初重组贷款,期间新重组方案
    --====================================================

    --5.1年初重组贷款 次级类、可疑类、损失类
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      
       SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G1101' AS REP_NUM, --报表编号
       CASE
         WHEN A.LOAN_GRADE_CD = '3' THEN
          'G11_1_5.1.F'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          'G11_1_5.1.G'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          'G11_1_5.1.H'
  --2024年新增制度指标G11_1_5.1.D.2024 alter by shiyu 20240314
   --5.1年初重组贷款 关注类
         when A.LOAN_GRADE_CD = '2' THEN
           'G11_1_5.1.D.2024'
    ----20250318 2025年制度升级
         when A.LOAN_GRADE_CD = '1' THEN
           'G11_1_5.1.C.2025'
       END AS ITEM_NUM, --指标号
       SUM(LOAN_ACCT_BAL * U.CCY_RATE) + SUM(INT_ADJEST_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
       '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE RESCHED_FLG = 'Y'
         AND A.DATA_DATE = SUBSTR(I_DATADATE, 0, 4) - 1 || '1231'
         AND LOAN_GRADE_CD IN ('3', '4', '5','2','1')
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
         /*AND A.ORG_NUM NOT LIKE '5100%'*/ --ADD 刘晟典
      --AND TO_CHAR(DRAWDOWN_DT,'YYYYMMDD') = SUBSTR(I_DATADATE, 0, 4) - 1 ||'1231'
       GROUP BY ORG_NUM,
                CASE
                  WHEN A.LOAN_GRADE_CD = '3' THEN
                   'G11_1_5.1.F'
                  WHEN A.LOAN_GRADE_CD = '4' THEN
                   'G11_1_5.1.G'
                  WHEN A.LOAN_GRADE_CD = '5' THEN
                   'G11_1_5.1.H'
                  when A.LOAN_GRADE_CD = '2' THEN
                   'G11_1_5.1.D.2024'
                  when A.LOAN_GRADE_CD = '1' THEN
                   'G11_1_5.1.C.2025'
                END;
    COMMIT;


   --5.2期间新重组方案

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G1101' AS REP_NUM, --报表编号
       CASE
         WHEN LOAN_GRADE_CD = '3' AND
              DRAWDOWN_DT >
              SUBSTR(I_DATADATE, 1, 4) || '0101' AND
              DRAWDOWN_DT <= I_DATADATE THEN
          'G11_1_5.2.F'
         WHEN LOAN_GRADE_CD = '4' AND
              DRAWDOWN_DT >
              SUBSTR(I_DATADATE, 1, 4) || '0101' AND
              DRAWDOWN_DT <= I_DATADATE THEN
          'G11_1_5.2.G'
         WHEN LOAN_GRADE_CD = '5' AND
              DRAWDOWN_DT >
              SUBSTR(I_DATADATE, 1, 4) || '0101' AND
              DRAWDOWN_DT <= I_DATADATE THEN
          'G11_1_5.2.H'
          --2024年新增制度指标G11_1_5.2.D.2024 alter by shiyu 20240314
          --5.2期间新重组方案 关注类
          WHEN LOAN_GRADE_CD = '2' AND
              DRAWDOWN_DT >
             SUBSTR(I_DATADATE, 1, 4) || '0101' AND
              DRAWDOWN_DT <= I_DATADATE THEN
          'G11_1_5.2.D.2024'
          -- 20250318 2025年制度升级
          WHEN LOAN_GRADE_CD = '1' AND
              DRAWDOWN_DT >
              SUBSTR(I_DATADATE, 1, 4) || '0101' AND
              DRAWDOWN_DT <= I_DATADATE THEN
          'G11_1_5.2.C.2025'

       END AS ITEM_NUM, --指标号
       SUM(LOAN_ACCT_BAL * U.CCY_RATE) + SUM(INT_ADJEST_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
       '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE RESCHED_FLG = 'Y' --重组标志
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('3', '4', '5','2','1')
         AND A.CANCEL_FLG = 'N'
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
     AND  DRAWDOWN_DT > SUBSTR(I_DATADATE, 1, 4) || '0101'
  
       GROUP BY ORG_NUM,
                CASE
         WHEN LOAN_GRADE_CD = '3' AND
              DRAWDOWN_DT >
              SUBSTR(I_DATADATE, 1, 4) || '0101' AND
              DRAWDOWN_DT <= I_DATADATE THEN
          'G11_1_5.2.F'
         WHEN LOAN_GRADE_CD = '4' AND
              DRAWDOWN_DT >
              SUBSTR(I_DATADATE, 1, 4) || '0101' AND
              DRAWDOWN_DT <= I_DATADATE THEN
          'G11_1_5.2.G'
         WHEN LOAN_GRADE_CD = '5' AND
              DRAWDOWN_DT >
              SUBSTR(I_DATADATE, 1, 4) || '0101' AND
              DRAWDOWN_DT <= I_DATADATE THEN
          'G11_1_5.2.H'
          --2024年新增制度指标G11_1_5.2.D.2024 alter by shiyu 20240314
          --5.2期间新重组方案 关注类
          WHEN LOAN_GRADE_CD = '2' AND
              DRAWDOWN_DT >
             SUBSTR(I_DATADATE, 1, 4) || '0101' AND
              DRAWDOWN_DT <= I_DATADATE THEN
          'G11_1_5.2.D.2024'
          -- 20250318 2025年制度升级
          WHEN LOAN_GRADE_CD = '1' AND
              DRAWDOWN_DT >
              SUBSTR(I_DATADATE, 1, 4) || '0101' AND
              DRAWDOWN_DT <= I_DATADATE THEN
          'G11_1_5.2.C.2025'

       END ;
    COMMIT;




    V_STEP_FLAG := 1;
    V_STEP_DESC := '5.1--5.2重组贷款-年初重组贷款,期间新重组方案 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 30;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '5.3重组贷款-不再认定为重组贷款逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --ALTER BY WJB 20220719 5.3需从5.1、5.2两个结果集出，因此建立临时表  TM_CBRC_G1101_TEMP1

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TM_CBRC_G1101_TEMP1';

    --5.1结果集插入临时表
    INSERT INTO CBRC_TM_CBRC_G1101_TEMP1
      (LOAN_NUM, LOAN_GRADE_CD,ORG_NUM)
      SELECT 
      DISTINCT LOAN_NUM, LOAN_GRADE_CD,ORG_NUM
        FROM SMTMODS_L_ACCT_LOAN A
       WHERE RESCHED_FLG = 'Y'
         AND A.DATA_DATE = SUBSTR(I_DATADATE, 0, 4) - 1 || '1231'
         AND A.LOAN_GRADE_CD IN ('3', '4', '5','2','1')
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
   ;
         /*AND A.ORG_NUM NOT LIKE '5100%'*/ --ADD 刘晟典;

    COMMIT;

    --5.2结果集插入临时表
    INSERT INTO CBRC_TM_CBRC_G1101_TEMP1
      (LOAN_NUM, LOAN_GRADE_CD,ORG_NUM)
      SELECT 
      DISTINCT LOAN_NUM, LOAN_GRADE_CD,ORG_NUM
        FROM SMTMODS_L_ACCT_LOAN A
       WHERE RESCHED_FLG = 'Y'
         AND A.LOAN_GRADE_CD IN ('3', '4', '5','2','1')
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
         /*AND A.ORG_NUM NOT LIKE '5100%'*/ --ADD 刘晟典
         AND ((A.DRAWDOWN_DT >=
             SUBSTR(I_DATADATE, 1, 4) || '0101'
         AND A.DRAWDOWN_DT <= I_DATADATE) OR
         (A.INTERNET_LOAN_FLG = 'Y' AND
           A.DRAWDOWN_DT = TO_CHAR(DATE((TRUNC(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYY') ),'YYYYMMDD')-1,'YYYYMMDD')    ) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
         OR (A.cp_id IN  ('DK001000100041') AND A.DRAWDOWN_DT = TO_CHAR(DATE((TRUNC(DATE(I_DATADATE, 'YYYYMMDD'), 'MM') ),'YYYYMMDD')-1,'YYYYMMDD')  )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]
        )

     ;


    COMMIT;

    --5.3减：不再认定为重组贷款  2024年新制度 年初是重组贷款本期不是重组贷款
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       A.ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G1101' AS REP_NUM, --报表编号
       CASE
         WHEN C.LOAN_GRADE_CD ='2'  THEN
           'G11_1_5.3.D.2024'
         WHEN C.LOAN_GRADE_CD = '3' THEN
          'G11_1_5.3.F'
         WHEN C.LOAN_GRADE_CD = '4' THEN
          'G11_1_5.3.G'
         WHEN C.LOAN_GRADE_CD = '5' THEN
          'G11_1_5.3.H'
         --20250318 2025年制度升级
         WHEN C.LOAN_GRADE_CD = '1' THEN
          'G11_1_5.3.C.2025'

       END AS ITEM_NUM, --指标号
       SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) +
       SUM(A.INT_ADJEST_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
       '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN cbrc_TM_CBRC_G1101_TEMP1 C
          ON A.LOAN_NUM = C.LOAN_NUM
          AND A.ORG_NUM = C.ORG_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE RESCHED_FLG = 'N'
         AND A.DATA_DATE = I_DATADATE
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN C.LOAN_GRADE_CD ='2'  THEN
                    'G11_1_5.3.D.2024'
                  WHEN C.LOAN_GRADE_CD = '3' THEN
                   'G11_1_5.3.F'
                  WHEN C.LOAN_GRADE_CD = '4' THEN
                   'G11_1_5.3.G'
                  WHEN C.LOAN_GRADE_CD = '5' THEN
                   'G11_1_5.3.H'
                  WHEN C.LOAN_GRADE_CD = '1' THEN
                   'G11_1_5.3.C.2025'
                END;

    COMMIT;



    V_STEP_FLAG := 1;
    V_STEP_ID   := 31;
    V_STEP_DESC := '5.3重组贷款-不再认定为重组贷款逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := 32;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '5.4重组贷款-重组贷款收回现金、以物抵债、核销、其他 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --G1101 5.4重组贷款-重组贷款收回现金、以物抵债、核销、其他
    --====================================================
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       B.ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G1101' AS REP_NUM, --报表编号
       CASE
         WHEN A.LOAN_GRADE_CD = '3' THEN
          'G11_1_5.4.F'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          'G11_1_5.4.G'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          'G11_1_5.4.H'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          'G11_1_5.4.D.2024'
          --20250318 2025年制度升级‘
         WHEN A.LOAN_GRADE_CD = '1' THEN
          'G11_1_5.4.C.2025'
       END AS ITEM_NUM, --指标号
       SUM(B.PAY_AMT) AS ITEM_VAL, --指标值
       '2' AS FLAG
        FROM CBRC_TM_CBRC_G1101_TEMP1 A
       INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM B
          ON A.LOAN_NUM = B.LOAN_NUM
          AND A.ORG_NUM = B.ORG_NUM
          AND SUBSTR(B.REPAY_DT,1,4)=SUBSTR(I_DATADATE,1,4)
       WHERE A.LOAN_GRADE_CD IN ('3', '4', '5','2','1')
       GROUP BY B.ORG_NUM,
                CASE
                  WHEN A.LOAN_GRADE_CD = '3' THEN
                   'G11_1_5.4.F'
                  WHEN A.LOAN_GRADE_CD = '4' THEN
                   'G11_1_5.4.G'
                  WHEN A.LOAN_GRADE_CD = '5' THEN
                   'G11_1_5.4.H'
                  WHEN A.LOAN_GRADE_CD = '2' THEN
                    'G11_1_5.4.D.2024'
                  WHEN A.LOAN_GRADE_CD = '1' THEN
                    'G11_1_5.4.C.2025'
                END;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_ID   := 33;
    V_STEP_DESC := '5.4重组贷款-重组贷款收回现金、以物抵债、核销、其他 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 34;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '5.5期末重组贷款  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   G1101 5.5期末重组贷款
    --====================================================
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       A.ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G1101' AS REP_NUM, --报表编号
       CASE
         WHEN A.LOAN_GRADE_CD = '3' THEN
          'G11_1_5.5.F'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          'G11_1_5.5.G'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          'G11_1_5.5.H'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          'G11_1_5.5.D.2024'
          --20250318 2025年制度升级
          WHEN A.LOAN_GRADE_CD = '1' THEN
          'G11_1_5.5.C.2025'
       END AS ITEM_NUM, --指标号
       SUM(LOAN_ACCT_BAL * U.CCY_RATE) + SUM(INT_ADJEST_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
       '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN cbrc_TM_CBRC_G1101_TEMP1 C
          ON A.LOAN_NUM = C.LOAN_NUM
          AND A.ORG_NUM = C.ORG_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.RESCHED_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_GRADE_CD IN ('3', '4', '5','2','1')
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.LOAN_GRADE_CD = '3' THEN
                   'G11_1_5.5.F'
                  WHEN A.LOAN_GRADE_CD = '4' THEN
                   'G11_1_5.5.G'
                  WHEN A.LOAN_GRADE_CD = '5' THEN
                   'G11_1_5.5.H'
                  WHEN A.LOAN_GRADE_CD = '2' THEN
                   'G11_1_5.5.D.2024'
                   WHEN A.LOAN_GRADE_CD = '1' THEN
                    'G11_1_5.5.C.2025'
                END;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_ID   := 35;
    V_STEP_DESC := '5.5期末重组贷款 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := 36;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '5.5.1其中：逾期超过90天  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   G1101 5.5.1其中：逾期超过90天
    --====================================================
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       A.ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G1101' AS REP_NUM, --报表编号
       CASE
         WHEN A.LOAN_GRADE_CD = '3' THEN
          'G11_1_5.5.1.F'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          'G11_1_5.5.1.G'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          'G11_1_5.5.1.H'
          WHEN A.LOAN_GRADE_CD = '2' THEN
          'G11_1_5.5.1.D.2024'
          --20250318 2025年制度升级
           WHEN A.LOAN_GRADE_CD = '1' THEN
          'G11_1_5.5.1.C.2025'
       END AS ITEM_NUM, --指标号
       SUM(LOAN_ACCT_BAL * U.CCY_RATE) + SUM(INT_ADJEST_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
       '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN cbrc_TM_CBRC_G1101_TEMP1 C
          ON A.LOAN_NUM = C.LOAN_NUM
          AND A.ORG_NUM = C.ORG_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.RESCHED_FLG = 'Y'
         AND OD_DAYS > 90
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_GRADE_CD IN ('3', '4', '5','2','1')
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL      --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.LOAN_GRADE_CD = '3' THEN
                   'G11_1_5.5.1.F'
                  WHEN A.LOAN_GRADE_CD = '4' THEN
                   'G11_1_5.5.1.G'
                  WHEN A.LOAN_GRADE_CD = '5' THEN
                   'G11_1_5.5.1.H'
                  WHEN A.LOAN_GRADE_CD = '2' THEN
                   'G11_1_5.5.1.D.2024'
                    WHEN A.LOAN_GRADE_CD = '1' THEN
                   'G11_1_5.5.1.C.2025'
                END;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_ID   := 37;
    V_STEP_DESC := '5.5.1其中：逾期超过90天 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 18;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '6.展期贷款  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   G1101 6.展期贷款
    --====================================================
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
   
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G1101' AS REP_NUM, --报表编号
             CASE
               WHEN LOAN_GRADE_CD = '1' THEN
                'G11_1_6..C.091231'
               WHEN LOAN_GRADE_CD = '2' THEN
                'G11_1_6..D.091231'
               WHEN LOAN_GRADE_CD = '3' THEN
                'G11_1_6..F.091231'
               WHEN LOAN_GRADE_CD = '4' THEN
                'G11_1_6..G.091231'
               WHEN LOAN_GRADE_CD = '5' THEN
                'G11_1_6..H.091231'
             END AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL * U.CCY_RATE) +
             SUM(INT_ADJEST_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.EXTENDTERM_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.ACCT_STS <> '3'
         and A.CANCEL_FLG <> 'Y'
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN LOAN_GRADE_CD = '1' THEN
                   'G11_1_6..C.091231'
                  WHEN LOAN_GRADE_CD = '2' THEN
                   'G11_1_6..D.091231'
                  WHEN LOAN_GRADE_CD = '3' THEN
                   'G11_1_6..F.091231'
                  WHEN LOAN_GRADE_CD = '4' THEN
                   'G11_1_6..G.091231'
                  WHEN LOAN_GRADE_CD = '5' THEN
                   'G11_1_6..H.091231'
                END;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '6.展期贷款 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
				
				
    V_STEP_ID   := V_STEP_ID+1;
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
   
END proc_cbrc_idx2_g1101