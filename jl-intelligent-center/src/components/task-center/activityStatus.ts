export type ActivityStatusKind = 'pending' | 'running' | 'completed' | 'failed' | 'cancelled';

const statusText = (value: unknown, depth = 0): string => {
    if (depth > 3 || value === undefined || value === null) return '';
    if (typeof value === 'string' || typeof value === 'number') return String(value).trim();
    if (typeof value !== 'object' || Array.isArray(value)) return '';
    const record = value as Record<string, unknown>;
    for (const key of ['status', 'state', 'value', 'kind', 'type', 'name']) {
        const nested = statusText(record[key], depth + 1);
        if (nested) return nested;
    }
    return '';
};

const normalizeStatus = (value: unknown) => statusText(value).toLowerCase().replace(/[\s-]+/g, '_');

const exitCodeStatus = (value: string) => {
    const match = value.match(/(?:exit[_ ]?code|退出码)\s*[:=]?\s*(-?\d+)/i);
    if (!match) return undefined;
    return Number(match[1]) === 0 ? 'completed' : 'failed';
};

export const classifyActivityStatus = (value: unknown): ActivityStatusKind => {
    const status = normalizeStatus(value);
    if (!status) return 'running';
    const exitStatus = exitCodeStatus(status);
    if (exitStatus === 'completed') return 'completed';
    if (exitStatus === 'failed') return 'failed';
    if (/等待|排队|pending|queued|queue|awaiting|waiting|scheduled/.test(status)) return 'pending';
    if (/取消|中止|canceled|cancelled|aborted|interrupted|stopped|user_cancel/.test(status)) return 'cancelled';
    if (/失败|错误|拒绝|驳回|超时|终止|中止|failed|failure|error|errored|timeout|timed_out|killed|terminated|signal|denied|rejected|declined|nonzero/.test(status)) return 'failed';
    if (/运行|分析|活动|重试|进行|running|in_progress|inprogress|executing|streaming|retry|active|started/.test(status)) return 'running';
    if (/完成|成功|记录|不可用|未生成|退出|结束|关闭|complete|completed|success|succeeded|done|finished|resolved|recorded|unavailable|not_generated|exited|closed|ok/.test(status)) return 'completed';
    return 'running';
};

export const isSettledActivityStatus = (value: unknown) => {
    const kind = classifyActivityStatus(value);
    return kind === 'completed' || kind === 'failed' || kind === 'cancelled';
};

export const isActiveActivityStatus = (value: unknown) => {
    const kind = classifyActivityStatus(value);
    return kind === 'pending' || kind === 'running';
};

export const activityStatusLabel = (value: unknown, fallback = '运行中') => {
    const status = normalizeStatus(value);
    if (!status) return fallback;
    const kind = classifyActivityStatus(status);
    if (kind === 'pending') return '等待中';
    if (kind === 'running') return '运行中';
    if (kind === 'cancelled') {
        if (/停止|stopped/.test(status)) return '已停止';
        if (/中断|中止|aborted|interrupted/.test(status)) return '已中止';
        return '已取消';
    }
    if (/超时|timeout|timed_out/.test(status)) return '已超时';
    if (/拒绝|驳回|denied|rejected|declined/.test(status)) return '已拒绝';
    if (/终止|terminated|killed|signal/.test(status)) return '已终止';
    if (/退出|exited/.test(status)) return '已退出';
    if (/不可用|unavailable/.test(status)) return '不可用';
    if (/未生成|not_generated/.test(status)) return '未生成';
    if (/记录|recorded/.test(status)) return '已记录';
    return kind === 'failed' ? '失败' : '已完成';
};

const parsedJson = (value: string) => {
    try {
        return JSON.parse(value) as unknown;
    } catch {
        return undefined;
    }
};

type ResultStatus = { kind: Exclude<ActivityStatusKind, 'pending' | 'running'>; label: string };

const inspectResult = (value: unknown, depth = 0): ResultStatus | undefined => {
    if (depth > 5 || value === undefined || value === null) return undefined;
    if (typeof value === 'string') {
        const exitStatus = exitCodeStatus(value.toLowerCase());
        if (exitStatus === 'completed') return { kind: 'completed', label: '已完成' };
        if (exitStatus === 'failed') {
            const match = value.match(/(?:exit[_ ]?code|退出码)\s*[:=]?\s*(-?\d+)/i);
            return { kind: 'failed', label: match ? `退出码 ${match[1]}` : '失败' };
        }
        if (/已超时|timed[_ ]?out|command[_ ]?timed[_ ]?out/i.test(value)) return { kind: 'failed', label: '已超时' };
        const parsed = parsedJson(value);
        return parsed === undefined ? undefined : inspectResult(parsed, depth + 1);
    }
    if (Array.isArray(value)) {
        for (const item of value.slice(0, 32)) {
            const result = inspectResult(item, depth + 1);
            if (result) return result;
        }
        return undefined;
    }
    if (typeof value !== 'object') return undefined;
    const record = value as Record<string, unknown>;
    const explicitStatus = record.status ?? record.state ?? record.result_status ?? record.resultStatus;
    if (explicitStatus !== undefined) {
        const kind = classifyActivityStatus(explicitStatus);
        if (kind !== 'pending' && kind !== 'running') {
            return { kind, label: activityStatusLabel(explicitStatus) };
        }
    }
    const timedOut = record.timed_out ?? record.timedOut;
    if (timedOut === true || timedOut === 'true') return { kind: 'failed', label: '已超时' };
    const signal = record.signal;
    if (typeof signal === 'string' && signal.trim() && signal.toLowerCase() !== 'backgrounded') {
        return { kind: 'failed', label: `已终止（${signal.trim()}）` };
    }
    const exitCode = record.exit_code ?? record.exitCode;
    if (exitCode !== undefined && exitCode !== null && exitCode !== '') {
        const numericExitCode = Number(exitCode);
        if (Number.isFinite(numericExitCode)) {
            return numericExitCode === 0
                ? { kind: 'completed', label: '已完成' }
                : { kind: 'failed', label: `退出码 ${numericExitCode}` };
        }
    }
    if (typeof record.success === 'boolean' || typeof record.ok === 'boolean') {
        const success = record.success ?? record.ok;
        return success ? { kind: 'completed', label: '已完成' } : { kind: 'failed', label: '失败' };
    }
    for (const key of ['error', 'error_message', 'errorMessage', 'failure', 'error_details', 'errorDetails']) {
        const error = record[key];
        if (typeof error === 'string' && error.trim()) return { kind: 'failed', label: '失败' };
        if (error && typeof error === 'object') return { kind: 'failed', label: '失败' };
    }
    for (const key of ['result', 'output', 'raw_output', 'rawOutput', 'content', 'toolCall', 'tool_call', 'fields']) {
        const result = inspectResult(record[key], depth + 1);
        if (result) return result;
    }
    return undefined;
};

export const inferTerminalActivityStatus = (values: unknown[]) => {
    for (const value of values) {
        const result = inspectResult(value);
        if (result) return result.label;
    }
    return undefined;
};
