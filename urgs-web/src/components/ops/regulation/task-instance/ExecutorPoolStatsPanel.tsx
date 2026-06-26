import React from 'react';
import { Tag, Tooltip } from 'antd';
import { Activity, Clock3, Cpu, ListTree, Server, TimerReset } from 'lucide-react';
import type { ExecutorPoolStatsState } from './useExecutorPoolStats';

interface ExecutorPoolStatsPanelProps {
    state: ExecutorPoolStatsState;
    waitingInstances: number;
}

const statusMeta = {
    loading: { color: 'default', label: '连接中', dotClass: 'bg-slate-400' },
    live: { color: 'success', label: '实时', dotClass: 'bg-emerald-500' },
    stale: { color: 'warning', label: '刷新中断', dotClass: 'bg-amber-500' },
    unavailable: { color: 'error', label: '不可用', dotClass: 'bg-red-500' },
} as const;

const ExecutorPoolStatsPanel: React.FC<ExecutorPoolStatsPanelProps> = ({ state, waitingInstances }) => {
    const { stats, status, lastUpdatedAt, error } = state;
    const currentStatus = statusMeta[status];

    if (!stats) {
        return (
            <div className="rounded-lg border border-dashed border-slate-200 bg-slate-50 px-3 py-2 text-sm text-slate-500">
                <div className="flex flex-wrap items-center gap-2">
                    <Server size={15} className="text-slate-400" />
                    <span className="font-semibold text-slate-700">执行器线程池指标</span>
                    <Tag className="m-0" color={currentStatus.color}>{currentStatus.label}</Tag>
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
            ? `线程池当前无排队，后台统计的 ${waitingInstances} 个等待实例更可能在等待前置依赖或下一轮调度。`
            : '线程池当前无排队，任务执行通道正常。';
    const updatedTime = lastUpdatedAt
        ? new Date(lastUpdatedAt).toLocaleTimeString('zh-CN', { hour12: false })
        : '--';
    const summaryTextClass = stats.queueSize > 0
        ? 'border-amber-100 bg-amber-50 text-amber-700'
        : 'border-emerald-100 bg-emerald-50 text-emerald-700';
    const activePercent = stats.maximumPoolSize > 0
        ? Math.min(100, Math.round((stats.activeCount / stats.maximumPoolSize) * 100))
        : 0;
    const queuePercent = stats.queueCapacity > 0
        ? Math.min(100, Math.round((stats.queueSize / stats.queueCapacity) * 100))
        : 0;
    const metricCardClass = 'min-w-[128px] rounded-lg border border-slate-200 bg-white px-3 py-2 shadow-sm';
    const metricLabelClass = 'flex items-center gap-1.5 text-[11px] font-medium text-slate-500';
    const metricValueClass = 'mt-1 flex items-baseline gap-1 font-mono text-base font-semibold text-slate-800';
    const progressTrackClass = 'mt-2 h-1.5 overflow-hidden rounded-full bg-slate-100';

    return (
        <div className="flex min-w-0 flex-wrap items-stretch gap-2 text-xs text-slate-500">
            <div className="flex min-w-[210px] flex-col justify-center rounded-lg border border-slate-200 bg-slate-50 px-3 py-2">
                <div className="flex items-center gap-2">
                    <span className={`h-2 w-2 rounded-full ${currentStatus.dotClass}`} />
                    <span className="font-semibold text-slate-700">执行器线程池</span>
                    <Tag className="m-0" color={currentStatus.color}>{currentStatus.label}</Tag>
                </div>
                <div className="mt-1 flex items-center gap-1.5 text-[11px] text-slate-500">
                    <Clock3 size={12} />
                    <span>最近更新 {updatedTime}</span>
                </div>
            </div>

            <div className={metricCardClass}>
                <div className={metricLabelClass}>
                    <Cpu size={12} />
                    <span>Active</span>
                </div>
                <div className={metricValueClass}>
                    <span>{stats.activeCount}</span>
                    <span className="text-xs font-medium text-slate-400">/ {stats.maximumPoolSize}</span>
                </div>
                <div className={progressTrackClass}>
                    <div className="h-full rounded-full bg-blue-500" style={{ width: `${activePercent}%` }} />
                </div>
            </div>

            <div className={metricCardClass}>
                <div className={metricLabelClass}>
                    <ListTree size={12} />
                    <span>Queue</span>
                </div>
                <div className={metricValueClass}>
                    <span>{stats.queueSize}</span>
                    <span className="text-xs font-medium text-slate-400">/ {stats.queueCapacity}</span>
                </div>
                <div className={progressTrackClass}>
                    <div
                        className={`h-full rounded-full ${stats.queueSize > 0 ? 'bg-amber-500' : 'bg-emerald-500'}`}
                        style={{ width: `${queuePercent}%` }}
                    />
                </div>
            </div>

            <div className={metricCardClass}>
                <div className={metricLabelClass}>
                    <Server size={12} />
                    <span>当前池大小</span>
                </div>
                <div className={metricValueClass}>{stats.poolSize}</div>
            </div>

            <Tooltip title={<div className="max-h-64 overflow-auto whitespace-pre-wrap font-mono text-xs">{runningTaskKeysText}</div>}>
                <div className={`${metricCardClass} cursor-help`}>
                    <div className={metricLabelClass}>
                        <Activity size={12} />
                        <span>运行任务</span>
                    </div>
                    <div className={metricValueClass}>{stats.runningTaskKeys.length}</div>
                </div>
            </Tooltip>

            <Tooltip title={<div className="max-h-64 overflow-auto whitespace-pre-wrap font-mono text-xs">{queuedTaskKeysText}</div>}>
                <div className={`${metricCardClass} cursor-help`}>
                    <div className={metricLabelClass}>
                        <TimerReset size={12} />
                        <span>排队任务</span>
                    </div>
                    <div className={metricValueClass}>{stats.queuedTaskKeys.length}</div>
                </div>
            </Tooltip>

            {status === 'stale' && error && (
                <div className="flex items-center rounded-lg border border-amber-100 bg-amber-50 px-3 py-2 text-amber-700">
                    当前展示最后一次成功数据：{error}
                </div>
            )}
            <div className={`flex min-w-[260px] flex-1 items-center rounded-lg border px-3 py-2 ${summaryTextClass}`}>
                {diagnosis}
            </div>
        </div>
    );
};

export default ExecutorPoolStatsPanel;
