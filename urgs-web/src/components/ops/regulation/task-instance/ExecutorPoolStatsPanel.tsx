import React from 'react';
import { Tag, Tooltip } from 'antd';
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
    const summaryTextClass = stats.queueSize > 0 ? 'text-amber-600' : 'text-emerald-600';

    return (
        <div className="flex min-w-0 flex-wrap items-center gap-x-3 gap-y-1 text-xs text-slate-500">
            <Tag color={currentStatus.color}>{currentStatus.label}</Tag>
            <span>最近更新 {updatedTime}</span>
            {status === 'stale' && error && (
                <span className="text-amber-600">
                    当前展示最后一次成功数据：{error}
                </span>
            )}
            <span>Active {stats.activeCount}/{stats.maximumPoolSize}</span>
            <span>当前池大小 {stats.poolSize}</span>
            <span>Queue {stats.queueSize}/{stats.queueCapacity}</span>
            <Tooltip title={<div className="max-h-64 overflow-auto whitespace-pre-wrap font-mono text-xs">{runningTaskKeysText}</div>}>
                <span className="cursor-help">Running Task Keys {stats.runningTaskKeys.length}</span>
            </Tooltip>
            <Tooltip title={<div className="max-h-64 overflow-auto whitespace-pre-wrap font-mono text-xs">{queuedTaskKeysText}</div>}>
                <span className="cursor-help">Queue Task Keys {stats.queuedTaskKeys.length}</span>
            </Tooltip>
            <span className={summaryTextClass}>{diagnosis}</span>
        </div>
    );
};

export default ExecutorPoolStatsPanel;
