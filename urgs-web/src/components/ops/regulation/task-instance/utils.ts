import dayjs from 'dayjs';
import {
    QuartzTaskApiModel,
    QuartzTaskLogApiModel,
    QuartzTaskStatusApiModel,
} from '@/api/ops';
import { QuartzTask, QuartzTaskExecutionLog, QuartzTaskStatus } from '../mockData';

export const parseDependIds = (dependId?: string | null): number[] => {
    if (!dependId) return [];
    return dependId
        .split(',')
        .map(item => Number(item.trim()))
        .filter(id => Number.isInteger(id));
};

export const formatDuration = (durationMs?: number | null) => {
    if (durationMs === undefined || durationMs === null) return '-';
    if (durationMs < 1000) return `${durationMs} ms`;
    const seconds = Math.floor(durationMs / 1000);
    if (seconds < 60) return `${seconds} 秒`;
    const minutes = Math.floor(seconds / 60);
    const remainSeconds = seconds % 60;
    return remainSeconds === 0 ? `${minutes} 分钟` : `${minutes} 分 ${remainSeconds} 秒`;
};

const toTaskTypeLabel = (taskType?: number | null) => {
    if (taskType === 2) return 'SQL';
    if (taskType === 1) return 'SHELL';
    return 'SHELL';
};

export const normalizeTask = (item: QuartzTaskApiModel): QuartzTask => {
    const now = dayjs().format('YYYY-MM-DD HH:mm:ss');
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
        script: item.exePath ?? null,
        depend_id: item.dependId ?? null,
        datasource_id: item.datasourceId ?? null,
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

export const normalizeStatus = (item: QuartzTaskStatusApiModel): QuartzTaskStatus => {
    const createTime = item.createTime || dayjs().format('YYYY-MM-DD HH:mm:ss');
    return {
        id: Number(item.id),
        plan_id: Number(item.planId),
        data_date: item.dataDate || '',
        status: item.status === null || item.status === undefined ? null : Number(item.status),
        begin_time: item.beginTime || null,
        update_time: item.updateTime || null,
        end_time: item.endTime || null,
        msg: item.msg || null,
        create_time: createTime,
        create_date: dayjs(createTime).format('YYYYMMDD'),
    };
};

export const normalizeLog = (item: QuartzTaskLogApiModel): QuartzTaskExecutionLog => {
    const processStatus = Number(item.processStatus ?? 0);
    const mappedStatus = processStatus === 0 ? 3 : processStatus === 1 ? 4 : 1;
    return {
        id: Number(item.id),
        task_id: Number(item.taskId),
        instance_id: null,
        data_date: null,
        status: mappedStatus as 0 | 1 | 2 | 3,
        trigger_type: '定时触发',
        begin_time: null,
        end_time: null,
        duration_ms: item.processDuration ?? null,
        summary: item.taskName || null,
        content: item.processLog || '',
        create_time: item.createTime || dayjs().format('YYYY-MM-DD HH:mm:ss'),
    };
};
