import React from 'react';
import { Tooltip } from 'antd';
import { Activity, ListTodo, ServerCog } from 'lucide-react';
import type { ExecutorPoolStats } from '@/api/ops';

interface ExecutorPoolStatsPanelProps {
    stats: ExecutorPoolStats | null;
}

const ExecutorPoolStatsPanel: React.FC<ExecutorPoolStatsPanelProps> = ({ stats }) => {
    if (!stats) {
        return (
            <div className="rounded-xl border border-dashed border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-400">
                执行器线程池指标暂不可用
            </div>
        );
    }

    const runningTaskKeysText = stats.runningTaskKeys.length > 0
        ? stats.runningTaskKeys.join('\n')
        : '当前无已提交任务';

    return (
        <div className="grid grid-cols-1 gap-3 md:grid-cols-3">
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
        </div>
    );
};

export default ExecutorPoolStatsPanel;
