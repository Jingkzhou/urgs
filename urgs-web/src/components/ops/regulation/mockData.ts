export interface QuartzTask {
    id: number;
    task_name: string;
    task_bean?: string | null;
    task_params?: string | null;
    task_cron: string;
    task_status: 0 | 1;
    remark?: string | null;
    update_time: string;
    create_time: string;
    task_type?: string | null;
    url?: string | null;
    script?: string | null;
    depend_id?: string | null;
    data_depend_id?: string | null;
    control_depend_id?: string | null;
    username?: string | null;
    password?: string | null;
    driver?: string | null;
    datasource_id?: number | null;
    datasource_name?: string | null;
    period?: number | null;
    task_system?: string | null;
    theme?: string | null;
    offset?: number | null;
    data_date?: string | null;
    job_key?: string | null;
    notification_completed?: string | null;
    notification_failed?: string | null;
}

export interface QuartzTaskStatus {
    plan_id: number;
    data_date: string;
    status?: number | null;
    begin_time?: string | null;
    update_time?: string | null;
    end_time?: string | null;
    msg?: string | null;
    id: number;
    create_time: string;
    create_date: string;
}

export interface QuartzTaskExecutionLog {
    id: number;
    task_id: number;
    instance_id?: number | null;
    data_date?: string | null;
    status: number;
    trigger_type: '定时触发' | '手工执行' | '补偿重跑';
    begin_time?: string | null;
    end_time?: string | null;
    duration_ms?: number | null;
    summary?: string | null;
    content: string;
    create_time: string;
}

export const quartzTasksMock: QuartzTask[] = [
    {
        id: 10801,
        task_name: '监管报送日切任务',
        task_bean: 'regBatchTaskExecutor',
        task_params: '{"scene":"daily","channel":"cbirc"}',
        task_cron: '0 15 7 * * ?',
        task_status: 0,
        remark: '监管日报送主任务，负责生成与下发日批文件。',
        update_time: '2026-04-02 08:16:00',
        create_time: '2026-03-18 09:00:00',
        task_type: 'SHELL',
        url: 'jdbc:mysql://10.20.3.12:3306/urgs_batch',
        script: `#!/bin/bash
set -e

python /apps/urgs/batch/report_daily.py --date \${DATA_DATE}
sh /apps/urgs/bin/push_reg_report.sh \${DATA_DATE}`,
        depend_id: '10788,10792',
        username: 'batch_rw',
        password: '******',
        driver: 'com.mysql.cj.jdbc.Driver',
        datasource_id: 101,
        datasource_name: '监管批量 MySQL',
        period: 300000,
        task_system: '监管报送平台',
        theme: '日报',
        offset: -1,
        data_date: '20260401',
        job_key: 'REG_REPORT_DAILY',
        notification_completed: 'ops@company.com,reg@company.com',
        notification_failed: 'ops@company.com,duty@company.com',
    },
    {
        id: 10802,
        task_name: '监管校验回执拉取',
        task_bean: 'regReceiptCollector',
        task_params: '{"source":"sftp","retry":3}',
        task_cron: '0 0/30 8-22 * * ?',
        task_status: 0,
        remark: '轮询获取监管系统回执状态。',
        update_time: '2026-04-02 09:02:00',
        create_time: '2026-03-18 09:20:00',
        task_type: 'SHELL',
        url: 'sftp://reg-channel.company.com/outbound',
        script: `#!/bin/bash
set -e

python /apps/urgs/batch/receipt_collector.py --source sftp --retry 3`,
        depend_id: '10801',
        username: 'receipt_sync',
        password: '******',
        driver: null,
        datasource_id: 102,
        datasource_name: '监管通道 SFTP',
        period: 1800000,
        task_system: '监管报送平台',
        theme: '回执',
        offset: 0,
        data_date: '20260402',
        job_key: 'REG_RECEIPT_SYNC',
        notification_completed: 'reg@company.com',
        notification_failed: 'ops@company.com,duty@company.com',
    },
    {
        id: 10803,
        task_name: '批量数据装载',
        task_bean: 'regDataLoader',
        task_params: '{"target":"staging","mode":"append"}',
        task_cron: '0 45 6 * * ?',
        task_status: 0,
        remark: '将前置系统抽取数据装载到监管临时表。',
        update_time: '2026-04-01 18:20:00',
        create_time: '2026-03-17 14:12:00',
        task_type: 'SQL',
        url: 'jdbc:oracle:thin:@10.16.6.28:1521/REGDB',
        script: `INSERT INTO reg_staging_detail (
    batch_no,
    customer_id,
    loan_balance,
    data_date
)
SELECT
    batch_no,
    customer_id,
    loan_balance,
    '\${DATA_DATE}'
FROM ods_reg_batch_detail
WHERE dt = '\${DATA_DATE_MINUS_1}';`,
        depend_id: null,
        username: 'loader',
        password: '******',
        driver: 'oracle.jdbc.OracleDriver',
        datasource_id: 103,
        datasource_name: '监管装载 Oracle',
        period: 600000,
        task_system: '数据集市',
        theme: '装载',
        offset: -1,
        data_date: '20260401',
        job_key: 'REG_DATA_LOAD',
        notification_completed: 'loader@company.com',
        notification_failed: 'ops@company.com',
    },
    {
        id: 10804,
        task_name: '监管失败补偿任务',
        task_bean: 'regCompensationTask',
        task_params: '{"scope":"failed_only"}',
        task_cron: '0 0 10,14,18 * * ?',
        task_status: 1,
        remark: '补偿任务，目前暂停。',
        update_time: '2026-04-02 10:00:00',
        create_time: '2026-03-20 10:45:00',
        task_type: 'SHELL',
        url: null,
        script: `#!/bin/bash
set -e

python /apps/urgs/batch/compensate_failed_tasks.py --scope failed_only`,
        depend_id: '10801,10802',
        username: 'ops_batch',
        password: '******',
        driver: null,
        datasource_id: 104,
        datasource_name: '补偿任务执行节点',
        period: 900000,
        task_system: '监管报送平台',
        theme: '补偿',
        offset: 0,
        data_date: '20260402',
        job_key: 'REG_COMPENSATE',
        notification_completed: 'ops@company.com',
        notification_failed: 'ops@company.com,duty@company.com',
    },
    {
        id: 10805,
        task_name: '月报汇总生成',
        task_bean: 'regMonthlySummaryTask',
        task_params: '{"scope":"month_end","format":"zip"}',
        task_cron: '0 0 3 1 * ?',
        task_status: 0,
        remark: '月初生成上月月报汇总归档。',
        update_time: '2026-04-01 03:16:00',
        create_time: '2026-03-10 11:00:00',
        task_type: 'SHELL',
        url: 'oss://reg-archive/monthly',
        script: `#!/bin/bash
set -e

python /apps/urgs/batch/monthly_summary.py --month \${LAST_MONTH}
tar -czf /data/archive/reg_\${LAST_MONTH}.tar.gz /data/output/\${LAST_MONTH}`,
        depend_id: '10803',
        username: 'archive_bot',
        password: '******',
        driver: null,
        datasource_id: 105,
        datasource_name: '监管归档 OSS',
        period: 3600000,
        task_system: '档案中心',
        theme: '月报',
        offset: -1,
        data_date: '20260331',
        job_key: 'REG_MONTHLY_SUMMARY',
        notification_completed: 'archive@company.com',
        notification_failed: 'ops@company.com,archive@company.com',
    },
    {
        id: 10806,
        task_name: '监管主题重算',
        task_bean: 'regThemeRebuildTask',
        task_params: '{"theme":"loan_risk"}',
        task_cron: '0 30 1 * * ?',
        task_status: 0,
        remark: '为监管主题数据仓补算标签结果。',
        update_time: '2026-04-02 01:48:00',
        create_time: '2026-03-22 15:05:00',
        task_type: 'SQL',
        url: 'jdbc:postgresql://10.20.5.39:5432/reg_topic',
        script: `DELETE FROM reg_theme_result
WHERE data_date = '\${DATA_DATE_MINUS_1}';

INSERT INTO reg_theme_result (
    customer_id,
    theme_code,
    tag_value,
    data_date
)
SELECT
    customer_id,
    'loan_risk',
    risk_level,
    '\${DATA_DATE_MINUS_1}'
FROM dws_loan_risk_tag
WHERE dt = '\${DATA_DATE_MINUS_1}';`,
        depend_id: '10803',
        username: 'topic_job',
        password: '******',
        driver: 'org.postgresql.Driver',
        datasource_id: 106,
        datasource_name: '监管主题 PostgreSQL',
        period: 1200000,
        task_system: '监管主题库',
        theme: '贷款风险',
        offset: -1,
        data_date: '20260401',
        job_key: 'REG_THEME_REBUILD',
        notification_completed: 'topic@company.com',
        notification_failed: 'ops@company.com,topic@company.com',
    },
];

export const quartzTaskStatusesMock: QuartzTaskStatus[] = [
    {
        id: 230001,
        plan_id: 10801,
        data_date: '2026-04-02',
        status: 2,
        begin_time: '2026-04-02 07:15:00',
        update_time: '2026-04-02 07:24:11',
        end_time: '2026-04-02 07:24:11',
        msg: '文件生成完成，已下发监管通道。',
        create_time: '2026-04-02 07:14:52',
        create_date: '20260402',
    },
    {
        id: 230002,
        plan_id: 10802,
        data_date: '2026-04-02',
        status: 1,
        begin_time: '2026-04-02 09:00:00',
        update_time: '2026-04-02 09:12:25',
        end_time: null,
        msg: '正在轮询监管回执目录。',
        create_time: '2026-04-02 09:00:00',
        create_date: '20260402',
    },
    {
        id: 230003,
        plan_id: 10803,
        data_date: '2026-04-02',
        status: 2,
        begin_time: '2026-04-02 06:45:00',
        update_time: '2026-04-02 06:58:49',
        end_time: '2026-04-02 06:58:49',
        msg: '落库 18 张表，共 42.8 万行。',
        create_time: '2026-04-02 06:44:47',
        create_date: '20260402',
    },
    {
        id: 230004,
        plan_id: 10804,
        data_date: '2026-04-02',
        status: 0,
        begin_time: null,
        update_time: '2026-04-02 10:00:00',
        end_time: null,
        msg: '任务已暂停，未生成实例。',
        create_time: '2026-04-02 10:00:00',
        create_date: '20260402',
    },
    {
        id: 230005,
        plan_id: 10806,
        data_date: '2026-04-01',
        status: 3,
        begin_time: '2026-04-02 01:30:00',
        update_time: '2026-04-02 01:34:09',
        end_time: '2026-04-02 01:34:09',
        msg: '主题重算失败: 维表 `loan_tag_mapping` 缺少分区 20260401。',
        create_time: '2026-04-02 01:29:55',
        create_date: '20260402',
    },
    {
        id: 230006,
        plan_id: 10805,
        data_date: '2026-03-31',
        status: 2,
        begin_time: '2026-04-01 03:00:00',
        update_time: '2026-04-01 03:16:33',
        end_time: '2026-04-01 03:16:33',
        msg: '归档文件已写入对象存储。',
        create_time: '2026-04-01 02:59:45',
        create_date: '20260401',
    },
    {
        id: 230007,
        plan_id: 10801,
        data_date: '2026-04-01',
        status: 2,
        begin_time: '2026-04-01 07:15:00',
        update_time: '2026-04-01 07:23:40',
        end_time: '2026-04-01 07:23:40',
        msg: '上日监管报送成功。',
        create_time: '2026-04-01 07:14:53',
        create_date: '20260401',
    },
    {
        id: 230008,
        plan_id: 10802,
        data_date: '2026-04-01',
        status: 3,
        begin_time: '2026-04-01 09:00:00',
        update_time: '2026-04-01 09:07:12',
        end_time: '2026-04-01 09:07:12',
        msg: '回执拉取失败: SFTP 连接超时。',
        create_time: '2026-04-01 08:59:58',
        create_date: '20260401',
    },
];

export const quartzTaskExecutionLogsMock: QuartzTaskExecutionLog[] = [
    {
        id: 900001,
        task_id: 10801,
        instance_id: 230001,
        data_date: '2026-04-02',
        status: 2,
        trigger_type: '定时触发',
        begin_time: '2026-04-02 07:15:00',
        end_time: '2026-04-02 07:24:11',
        duration_ms: 551000,
        summary: '监管报送日切任务执行完成，报送文件已推送。',
        content: `[INFO] task=10801 instance=230001 begin
[INFO] resolve data_date=2026-04-01
[INFO] generate report file: reg_daily_20260401.dat
[INFO] push file to regulator channel success
[INFO] notify completed receivers: ops@company.com,reg@company.com
[INFO] task finished successfully`,
        create_time: '2026-04-02 07:24:11',
    },
    {
        id: 900002,
        task_id: 10801,
        instance_id: 230007,
        data_date: '2026-04-01',
        status: 2,
        trigger_type: '定时触发',
        begin_time: '2026-04-01 07:15:00',
        end_time: '2026-04-01 07:23:40',
        duration_ms: 520000,
        summary: '上日监管报送执行成功。',
        content: `[INFO] task=10801 instance=230007 begin
[INFO] resolve data_date=2026-03-31
[INFO] file checksum passed
[INFO] regulator upload accepted
[INFO] task finished successfully`,
        create_time: '2026-04-01 07:23:40',
    },
    {
        id: 900003,
        task_id: 10802,
        instance_id: 230002,
        data_date: '2026-04-02',
        status: 1,
        trigger_type: '定时触发',
        begin_time: '2026-04-02 09:00:00',
        end_time: null,
        duration_ms: null,
        summary: '正在轮询监管回执目录。',
        content: `[INFO] task=10802 instance=230002 begin
[INFO] connect sftp host=reg-channel.company.com
[INFO] scan outbound path=/receipt
[INFO] wait next polling window`,
        create_time: '2026-04-02 09:12:25',
    },
    {
        id: 900004,
        task_id: 10802,
        instance_id: 230008,
        data_date: '2026-04-01',
        status: 3,
        trigger_type: '定时触发',
        begin_time: '2026-04-01 09:00:00',
        end_time: '2026-04-01 09:07:12',
        duration_ms: 432000,
        summary: '回执拉取失败，SFTP 连接超时。',
        content: `[INFO] task=10802 instance=230008 begin
[INFO] connect sftp host=reg-channel.company.com timeout=10s
[ERROR] connect failed: java.net.SocketTimeoutException
[WARN] retry exhausted after 3 attempts
[INFO] notify failed receivers: ops@company.com,duty@company.com`,
        create_time: '2026-04-01 09:07:12',
    },
    {
        id: 900005,
        task_id: 10803,
        instance_id: 230003,
        data_date: '2026-04-02',
        status: 2,
        trigger_type: '定时触发',
        begin_time: '2026-04-02 06:45:00',
        end_time: '2026-04-02 06:58:49',
        duration_ms: 829000,
        summary: '批量数据装载成功，写入 42.8 万行。',
        content: `[INFO] task=10803 instance=230003 begin
[INFO] execute sql script on datasource=103
[INFO] affected rows=428316
[INFO] commit transaction
[INFO] task finished successfully`,
        create_time: '2026-04-02 06:58:49',
    },
    {
        id: 900006,
        task_id: 10804,
        instance_id: null,
        data_date: '2026-04-02',
        status: 0,
        trigger_type: '补偿重跑',
        begin_time: null,
        end_time: null,
        duration_ms: null,
        summary: '任务已暂停，未进入执行阶段。',
        content: `[INFO] task=10804 skipped
[INFO] current status=paused
[INFO] no instance created`,
        create_time: '2026-04-02 10:00:00',
    },
    {
        id: 900007,
        task_id: 10805,
        instance_id: 230006,
        data_date: '2026-03-31',
        status: 2,
        trigger_type: '定时触发',
        begin_time: '2026-04-01 03:00:00',
        end_time: '2026-04-01 03:16:33',
        duration_ms: 993000,
        summary: '月报汇总生成完成并归档到对象存储。',
        content: `[INFO] task=10805 instance=230006 begin
[INFO] generate monthly archive for 202603
[INFO] upload file to oss bucket=reg-archive
[INFO] archive checksum verified
[INFO] task finished successfully`,
        create_time: '2026-04-01 03:16:33',
    },
    {
        id: 900008,
        task_id: 10806,
        instance_id: 230005,
        data_date: '2026-04-01',
        status: 3,
        trigger_type: '手工执行',
        begin_time: '2026-04-02 01:30:00',
        end_time: '2026-04-02 01:34:09',
        duration_ms: 249000,
        summary: '监管主题重算失败，维表缺少分区。',
        content: `[INFO] task=10806 instance=230005 begin
[INFO] execute sql script on datasource=106
[ERROR] partition not found: loan_tag_mapping dt=20260401
[ERROR] rollback current transaction
[INFO] notify failed receivers: ops@company.com,topic@company.com`,
        create_time: '2026-04-02 01:34:09',
    },
];
