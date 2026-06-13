import React from 'react';
import { Tag, Tooltip } from 'antd';
import { Activity, Clock3, ListTodo, ServerCog } from 'lucide-react';
import type { ExecutorPoolStatsState } from './useExecutorPoolStats';

interface ExecutorPoolStatsPanelProps {
    state: ExecutorPoolStatsState;
    waitingInstances: number;
}

const statusMeta = {
    loading: { color: 'default', label: '连接中' },
    live: { color: 'success', label: '实时' },
    stale: { color: 'warning', label: '刷新中断' },
    unavailable: { color: 'error', label: '不可用' },
} as const;

const ExecutorPoolStatsPanel: React.FC<ExecutorPoolStatsPanelProps> = ({ state, waitingInstances }) => {
    const { stats, status, lastUpdatedAt, error } = state;
    const currentStatus = statusMeta[status];

    if (!stats) {
        return (
            <div className="rounded-xl border border-dashed border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-500">
                <div className="flex items-center gap-2">
                    <span>执行器线程池指标</span>
                    <Tag color={currentStatus.color}>{currentStatus.label}</Tag>
                </div>
                {error && <div className="mt-1 text-xs text-red-500">{error}</div>}
            </div>
        );
    }

    const runningTaskKeysText = stats.runningTaskKeys.length > 0
        ? stats.runningTaskKeys.join('\n')
        : '当前无正在执行的任务';
    const queuedTaskKeysText = stats.queuedTaskKeys.length > 0
        ? stats.queuedTaskKeys.join('\n')
        : '当前无线程池排队任务';
    const diagnosis = stats.queueSize > 0
        ? `${stats.queueSize} 个任务正在等待线程池并发，可在 Queue Task Keys 中确认具体实例。`
        : waitingInstances > 0
            ? `线程池当前无排队，页面中的 ${waitingInstances} 个等待实例更可能在等待前置依赖或下一轮调度。`
            : '线程池当前无排队，任务执行通道正常。';
    const updatedTime = lastUpdatedAt
        ? new Date(lastUpdatedAt).toLocaleTimeString('zh-CN', { hour12: false })
        : '--';

    return (
        <div className="space-y-3">
            <div className="flex flex-wrap items-center justify-between gap-2">
                <div className="flex items-center gap-2 text-sm font-semibold text-slate-700">
                    执行器线程池
                    <Tag color={currentStatus.color}>{currentStatus.label}</Tag>
                </div>
                <div className="flex items-center gap-1 text-xs text-slate-400">
                    <Clock3 size={13} />
                    最近更新 {updatedTime}
                </div>
            </div>
            {status === 'stale' && error && (
                <div className="rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-xs text-amber-700">
                    当前展示最后一次成功数据：{error}
                </div>
            )}
            <div className="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-4">
                <div className="rounded-xl border border-blue-100 bg-blue-50 px-4 py-3">
                    <div className="flex items-center gap-2 text-xs font-medium text-blue-600">
                        <Activity size={14} />
                        Active
                    </div>
                    <div className="mt-1 text-xl font-bold text-blue-700">
                        {stats.activeCount}
                        <span className="ml-1 text-xs font-normal text-blue-500">/ {stats.maximumPoolSize}</span>
                    </div>
                    <div className="mt-1 text-xs text-blue-500">当前池大小 {stats.poolSize}</div>
                </div>
                <div className="rounded-xl border border-amber-100 bg-amber-50 px-4 py-3">
                    <div className="flex items-center gap-2 text-xs font-medium text-amber-600">
                        <ListTodo size={14} />
                        Queue
                    </div>
                    <div className="mt-1 text-xl font-bold text-amber-700">
                        {stats.queueSize}
                        <span className="ml-1 text-xs font-normal text-amber-500">/ {stats.queueCapacity}</span>
                    </div>
                    <div className="mt-1 text-xs text-amber-500">等待线程池并发的任务数</div>
                </div>
                <Tooltip title={<div className="max-h-64 overflow-auto whitespace-pre-wrap font-mono text-xs">{runningTaskKeysText}</div>}>
                    <div className="cursor-help rounded-xl border border-violet-100 bg-violet-50 px-4 py-3">
                        <div className="flex items-center gap-2 text-xs font-medium text-violet-600">
                            <ServerCog size={14} />
                            Running Task Keys
                        </div>
                        <div className="mt-1 text-xl font-bold text-violet-700">{stats.runningTaskKeys.length}</div>
                        <div className="mt-1 truncate text-xs text-violet-500">
                            {stats.runningTaskKeys[0] || `累计完成 ${stats.completedTaskCount}`}
                        </div>
                    </div>
                </Tooltip>
                <Tooltip title={<div className="max-h-64 overflow-auto whitespace-pre-wrap font-mono text-xs">{queuedTaskKeysText}</div>}>
                    <div className="cursor-help rounded-xl border border-orange-100 bg-orange-50 px-4 py-3">
                        <div className="flex items-center gap-2 text-xs font-medium text-orange-600">
                            <ListTodo size={14} />
                            Queue Task Keys
                        </div>
                        <div className="mt-1 text-xl font-bold text-orange-700">{stats.queuedTaskKeys.length}</div>
                        <div className="mt-1 truncate text-xs text-orange-500">
                            {stats.queuedTaskKeys[0] || '无线程池排队任务'}
                        </div>
                    </div>
                </Tooltip>
            </div>
            <div className={`rounded-lg border px-3 py-2 text-xs ${stats.queueSize > 0 ? 'border-amber-200 bg-amber-50 text-amber-700' : 'border-emerald-200 bg-emerald-50 text-emerald-700'}`}>
                {diagnosis}
            </div>
        </div>
    );
};

export default ExecutorPoolStatsPanel;
