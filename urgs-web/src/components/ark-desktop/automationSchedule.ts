import type { ArkDesktopAutomation, AutomationSchedule } from './types';

const WEEKDAYS = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];

export const nextAutomationRunAt = (
    schedule: AutomationSchedule,
    scheduleTime: string,
    weekday = 1,
    from = Date.now(),
) => {
    if (schedule === 'manual') return undefined;
    const [hour = 9, minute = 0] = scheduleTime.split(':').map(Number);
    const next = new Date(from);
    next.setHours(hour, minute, 0, 0);
    if (schedule === 'daily') {
        if (next.getTime() <= from) next.setDate(next.getDate() + 1);
        return next.getTime();
    }
    const distance = (weekday - next.getDay() + 7) % 7;
    next.setDate(next.getDate() + distance);
    if (next.getTime() <= from) next.setDate(next.getDate() + 7);
    return next.getTime();
};

export const automationScheduleLabel = (automation: ArkDesktopAutomation) => {
    if (automation.schedule === 'manual') return '仅手动运行';
    if (automation.schedule === 'daily') return `每天 ${automation.scheduleTime}`;
    return `每${WEEKDAYS[automation.scheduleWeekday ?? 1]} ${automation.scheduleTime}`;
};

export const formatAutomationDateTime = (value?: number | string) => {
    if (!value) return '暂无';
    const timestamp = typeof value === 'number' ? value : Date.parse(value);
    if (!Number.isFinite(timestamp)) return '时间待同步';
    return new Intl.DateTimeFormat('zh-CN', {
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
    }).format(timestamp);
};
