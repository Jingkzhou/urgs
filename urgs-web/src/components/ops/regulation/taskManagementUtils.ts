import dayjs from 'dayjs';
import { QuartzTaskApiModel } from '@/api/ops';
import { QuartzTask } from './mockData';

// ===== 接口定义 =====

export interface TaskFormValues {
    task_name: string;
    task_type?: string;
    task_status: 0 | 1;
    task_system?: string;
    theme?: string;
    remark?: string;
    task_cron: string;
    offset?: number | null;
    depend_id?: string;
    data_depend_id?: string;
    control_depend_id?: string;
    period?: number | null;
    datasource_id?: number;
    script?: string;
    notification_completed?: string;
    notification_failed?: string;
    notification_completed_list?: NotificationContact[];
    notification_failed_list?: NotificationContact[];
}

export interface NotificationContact {
    name: string;
    custid: string;
}

export interface DataSourceOption {
    id: number;
    name: string;
    typeName?: string;
    typeCode?: string;
    category?: string;
    status?: number;
    connectionInfo?: string;
}

// ===== 常量 =====

export const supportedTaskTypes = ['SQL', 'SHELL'] as const;

export const editorLanguageMap: Record<string, string> = {
    SQL: 'sql',
    SHELL: 'shell',
};

export const statusMap: Record<number, { label: string; className: string }> = {
    0: { label: '正常', className: 'bg-emerald-50 text-emerald-600 border-emerald-200' },
    1: { label: '暂停', className: 'bg-amber-50 text-amber-600 border-amber-200' },
};

export const detailItemClass = 'rounded-xl border border-slate-200 bg-slate-50/70 px-4 py-3';
export const detailSectionClass = 'rounded-2xl border border-slate-200 bg-white';
export const detailMetaBadgeClass = 'inline-flex max-w-[160px] items-center rounded-lg border border-slate-200 bg-slate-50 px-2 py-1 text-[11px] leading-none text-slate-600';
export const actionButtonClass = 'inline-flex items-center gap-1 rounded-lg border px-3 py-1.5 text-xs font-medium transition-colors';
export const enabledActionClass = 'border-slate-200 text-slate-600 hover:bg-slate-50';
export const primaryActionClass = 'border-slate-200 bg-white text-slate-700 hover:bg-slate-50';

// ===== 工具函数 =====

export const emptyToNull = (value?: string) => {
    if (typeof value !== 'string') return null;
    const trimmed = value.trim();
    return trimmed === '' ? null : trimmed;
};

export const normalizeScript = (value?: string) => {
    if (typeof value !== 'string') return null;
    if (value.trim() === '') return null;
    return value.replace(/\r\n/g, '\n');
};

const weekLabelMap: Record<string, string> = {
    '1': '每周日',
    '2': '每周一',
    '3': '每周二',
    '4': '每周三',
    '5': '每周四',
    '6': '每周五',
    '7': '每周六',
};

export const describeCron = (cron?: string, offset?: number | null) => {
    if (!cron) return '尚未设置运行时间';

    const parts = cron.trim().split(/\s+/);
    if (parts.length < 6) {
        return `按 Cron ${cron} 执行`;
    }

    const minute = parts[1];
    const hour = parts[2];
    const day = parts[3];
    const month = parts[4];
    const week = parts[5];

    let schedule = `按 Cron ${cron} 执行`;

    if (minute.startsWith('*/')) {
        schedule = `每 ${minute.replace('*/', '')} 分钟执行一次`;
    } else if (hour.startsWith('*/')) {
        schedule = `每 ${hour.replace('*/', '')} 小时在 ${minute.padStart(2, '0')} 分执行`;
    } else if (day === '*' && month === '*' && week === '?') {
        schedule = `每天 ${hour.padStart(2, '0')}:${minute.padStart(2, '0')} 执行`;
    } else if (day !== '*' && day !== '?' && month === '*') {
        schedule = `每月 ${day} 日 ${hour.padStart(2, '0')}:${minute.padStart(2, '0')} 执行`;
    } else if (week !== '*' && week !== '?') {
        schedule = `${weekLabelMap[week] || `每周 ${week}`} ${hour.padStart(2, '0')}:${minute.padStart(2, '0')} 执行`;
    }

    if (offset !== undefined && offset !== null && offset !== 0) {
        return `${schedule}，数据偏移 ${offset} 天`;
    }

    return schedule;
};

export const describeDataSourceConnection = (params?: Record<string, any>, typeCode?: string) => {
    if (!params) return '连接信息待补充';

    const host = params.host ? String(params.host) : '';
    const port = params.port !== undefined && params.port !== null && params.port !== '' ? String(params.port) : '';
    const database = params.database ? String(params.database) : '';
    const serviceName = params.serviceName ? String(params.serviceName) : '';
    const rootPath = params.rootPath ? String(params.rootPath) : '';
    const endpoint = params.endpoint ? String(params.endpoint) : '';
    const jdbcUrl = params.jdbcUrl ? String(params.jdbcUrl) : '';
    const address = params.address ? String(params.address) : '';
    const defaultFS = params.defaultFS ? String(params.defaultFS) : '';
    const path = params.path ? String(params.path) : '';
    const masterAddresses = params.masterAddresses ? String(params.masterAddresses) : '';
    const zkQuorum = params.zkQuorum ? String(params.zkQuorum) : '';
    const url = params.url ? String(params.url) : '';

    if (jdbcUrl) return jdbcUrl;
    if (url) return url;
    if (endpoint) {
        const suffix = params.bucket || params.project || params.instanceName || params.method
            ? ` / ${[params.bucket, params.project, params.instanceName, params.method].filter(Boolean).join(' / ')}`
            : '';
        return `${endpoint}${suffix}`;
    }
    if (host) {
        const hostPort = port ? `${host}:${port}` : host;
        if (database) return `${hostPort}/${database}`;
        if (serviceName) return `${hostPort}/${serviceName}`;
        if (rootPath) return `${hostPort}${rootPath.startsWith('/') ? '' : '/'}${rootPath}`;
        return hostPort;
    }
    if (address) {
        return database ? `${address}/${database}` : address;
    }
    if (defaultFS) {
        return path ? `${defaultFS}${path}` : defaultFS;
    }
    if (masterAddresses) return masterAddresses;
    if (zkQuorum) return zkQuorum;
    if (path) return path;

    const preferredKeys = ['database', 'serviceName', 'bucket', 'project', 'instanceName', 'fileType', 'schema'];
    const summary = preferredKeys
        .map(key => params[key])
        .filter(Boolean)
        .map(value => String(value))
        .join(' / ');

    if (summary) return summary;
    return typeCode ? `${typeCode} 数据源` : '连接信息待补充';
};

export const getInitialFormValues = (task?: QuartzTask | null): TaskFormValues => ({
    task_name: task?.task_name || '',
    task_type: task?.task_type || 'SHELL',
    task_status: task?.task_status ?? 0,
    task_system: task?.task_system || undefined,
    theme: task?.theme || undefined,
    remark: task?.remark || undefined,
    task_cron: task?.task_cron || '0 0 * * * ?',
    offset: task?.offset ?? null,
    depend_id: task?.data_depend_id || task?.depend_id || undefined,
    data_depend_id: task?.data_depend_id || task?.depend_id || undefined,
    control_depend_id: task?.control_depend_id || undefined,
    period: task?.period ?? null,
    datasource_id: task?.datasource_id === null || task?.datasource_id === undefined
        ? undefined
        : Number(task.datasource_id),
    script: task?.script || undefined,
    notification_completed: task?.notification_completed || undefined,
    notification_failed: task?.notification_failed || undefined,
    notification_completed_list: parseNotificationContacts(task?.notification_completed),
    notification_failed_list: parseNotificationContacts(task?.notification_failed),
});

export const parseNotificationContacts = (value?: string | null): NotificationContact[] => {
    if (!value || !value.trim()) return [];
    const raw = value.trim();
    try {
        const parsed = JSON.parse(raw);
        if (!Array.isArray(parsed)) return [];
        return parsed
            .map((item: any) => ({
                name: String(item?.name ?? '').trim(),
                custid: String(item?.custid ?? '').trim(),
            }))
            .filter(item => item.name || item.custid);
    } catch {
        const normalized = raw
            .replace(/([{,]\s*)([a-zA-Z_][a-zA-Z0-9_]*)(\s*:)/g, '$1"$2"$3')
            .replace(/'/g, '"');
        try {
            const parsed = JSON.parse(normalized);
            if (!Array.isArray(parsed)) return [];
            return parsed
                .map((item: any) => ({
                    name: String(item?.name ?? '').trim(),
                    custid: String(item?.custid ?? '').trim(),
                }))
                .filter(item => item.name || item.custid);
        } catch {
            return [];
        }
    }
};

export const serializeNotificationContacts = (contacts?: NotificationContact[] | null) => {
    if (!contacts || contacts.length === 0) return null;
    const cleaned = contacts
        .map(item => ({
            name: String(item?.name ?? '').trim(),
            custid: String(item?.custid ?? '').trim(),
        }))
        .filter(item => item.name && item.custid);
    if (cleaned.length === 0) return null;
    return JSON.stringify(cleaned);
};

export const toTaskTypeCode = (taskType?: string | null) => (taskType === 'SQL' ? 2 : 1);

export const toTaskTypeLabel = (taskType?: number | null) => {
    if (taskType === 2) return 'SQL';
    if (taskType === 1) return 'SHELL';
    return 'SHELL';
};

export const normalizeQuartzTask = (item: QuartzTaskApiModel): QuartzTask => {
    const now = dayjs().format('YYYY-MM-DD HH:mm:ss');
    const datasourceId = item.datasourceId === null || item.datasourceId === undefined
        ? null
        : Number(item.datasourceId);
    return {
        id: Number(item.id),
        task_name: item.taskName || '',
        task_bean: item.taskBean ?? null,
        task_params: item.taskParams ?? null,
        task_cron: item.taskCron || '',
        task_status: Number(item.taskStatus ?? 0) as 0 | 1,
        remark: item.remark ?? null,
        update_time: item.updateTime || now,
        create_time: item.createTime || now,
        task_type: toTaskTypeLabel(item.taskType),
        url: item.url ?? null,
        script: item.exePath ?? null,
        depend_id: item.dataDependId ?? item.dependId ?? null,
        data_depend_id: item.dataDependId ?? item.dependId ?? null,
        control_depend_id: item.controlDependId ?? null,
        username: item.username ?? null,
        password: item.password ?? null,
        driver: item.driver ?? null,
        datasource_id: Number.isFinite(datasourceId) ? datasourceId : null,
        datasource_name: item.datasourceName ?? null,
        period: item.period ?? null,
        task_system: item.taskSystem ?? null,
        theme: item.theme ?? null,
        offset: item.offset ?? null,
        data_date: item.dataDate ?? null,
        job_key: item.jobKey ?? null,
        notification_completed: item.notificationCompleted ?? null,
        notification_failed: item.notificationFailed ?? null,
    };
};
