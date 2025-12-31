import React from 'react';
import { RotateCw, CheckCircle, XCircle, Clock, Play, FileText, Server, Calendar } from 'lucide-react';

interface InstanceCardProps {
    instance: {
        id: string;
        taskId: string;
        taskName?: string;
        taskType?: string;
        systemName?: string;
        workflowName?: string;
        dataDate: string;
        status: string;
        startTime?: string;
        endTime?: string;
    };
    onViewLog?: (instance: any) => void;
    onRerun?: (instance: any) => void;
    onStop?: (instance: any) => void;
    onForceSuccess?: (instance: any) => void;
    onShowDetail?: (instance: any) => void;
}

const statusConfig: Record<string, {
    gradient: string;
    bg: string;
    text: string;
    icon: React.ReactNode;
    label: string;
    shadow: string;
    dot: string;
}> = {
    SUCCESS: {
        gradient: 'from-emerald-400 to-green-600',
        bg: 'bg-emerald-50/50',
        text: 'text-emerald-600',
        icon: <CheckCircle size={14} />,
        label: '成功',
        shadow: 'shadow-emerald-200/40',
        dot: 'bg-emerald-500'
    },
    FORCE_SUCCESS: {
        gradient: 'from-violet-400 to-purple-600',
        bg: 'bg-purple-50/50',
        text: 'text-purple-600',
        icon: <CheckCircle size={14} />,
        label: '强制成功',
        shadow: 'shadow-purple-200/40',
        dot: 'bg-purple-500'
    },
    FAIL: {
        gradient: 'from-rose-400 to-red-600',
        bg: 'bg-red-50/50',
        text: 'text-red-600',
        icon: <XCircle size={14} />,
        label: '失败',
        shadow: 'shadow-red-200/40',
        dot: 'bg-red-500'
    },
    RUNNING: {
        gradient: 'from-sky-400 to-blue-600',
        bg: 'bg-blue-50/50',
        text: 'text-blue-600',
        icon: <RotateCw size={14} className="animate-spin" />,
        label: '运行中',
        shadow: 'shadow-blue-200/40',
        dot: 'bg-blue-500'
    },
    WAITING: {
        gradient: 'from-amber-400 to-orange-500',
        bg: 'bg-amber-50/50',
        text: 'text-amber-600',
        icon: <Clock size={14} />,
        label: '等待下发',
        shadow: 'shadow-amber-200/40',
        dot: 'bg-amber-500'
    },
    PENDING: {
        gradient: 'from-slate-400 to-slate-500',
        bg: 'bg-slate-50/50',
        text: 'text-slate-600',
        icon: <Clock size={14} />,
        label: '依赖等待',
        shadow: 'shadow-slate-200/40',
        dot: 'bg-slate-400'
    },
    STOPPED: {
        gradient: 'from-slate-500 to-slate-700',
        bg: 'bg-slate-100/50',
        text: 'text-slate-600',
        icon: <XCircle size={14} />,
        label: '已停止',
        shadow: 'shadow-slate-300/40',
        dot: 'bg-slate-500'
    }
};

const InstanceCard: React.FC<InstanceCardProps> = ({
    instance,
    onViewLog,
    onRerun,
    onStop,
    onForceSuccess,
    onShowDetail
}) => {
    const config = statusConfig[instance.status] || statusConfig.PENDING;
    const isRunning = instance.status === 'RUNNING';
    const canRerun = ['SUCCESS', 'FAIL', 'FORCE_SUCCESS', 'STOPPED'].includes(instance.status);
    const canStop = ['RUNNING', 'WAITING', 'PENDING'].includes(instance.status);
    const canForceSuccess = ['FAIL', 'RUNNING', 'WAITING', 'PENDING'].includes(instance.status);

    return (
        <div
            onClick={() => onShowDetail?.(instance)}
            className={`group relative bg-white rounded-2xl border border-slate-200/80 overflow-hidden transition-all duration-300 hover:shadow-2xl hover:border-blue-400/50 hover:-translate-y-1.5 cursor-pointer flex flex-col ${config.shadow}`}
        >
            {/* Status gradient strip */}
            <div className={`h-1.5 w-full bg-gradient-to-r ${config.gradient}`} />

            <div className="p-5 flex-1 flex flex-col">
                {/* Header */}
                <div className="flex items-start justify-between mb-4">
                    <div className="flex-1 min-w-0 pr-2">
                        <div className="flex items-center gap-1.5 mb-1">
                            <h3 className="font-bold text-slate-800 text-base truncate group-hover:text-blue-600 transition-colors tracking-tight">
                                {instance.taskName || instance.taskId}
                            </h3>
                        </div>
                        <div className="flex items-center gap-2">
                            <span className="text-[10px] text-slate-400 font-mono bg-slate-50 px-1.5 py-0.5 rounded border border-slate-100">#{instance.id}</span>
                            <span className="text-[10px] text-slate-400 font-medium bg-slate-50 px-1.5 py-0.5 rounded border border-slate-100">{instance.taskType || '-'}</span>
                        </div>
                    </div>
                    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl text-xs font-bold ring-1 ring-inset ${config.bg} ${config.text} ${config.bg.replace('bg-', 'ring-').replace('/50', '/20')}`}>
                        <span className={`w-1.5 h-1.5 rounded-full ${config.dot} ${isRunning ? 'animate-pulse' : ''}`} />
                        {config.label}
                    </span>
                </div>

                {/* Info rows */}
                <div className="space-y-2 mb-4">
                    <div className="flex items-center gap-2 text-sm text-slate-600">
                        <Calendar size={14} className="text-slate-400 flex-shrink-0" />
                        <span>数据日期: <span className="font-medium">{instance.dataDate}</span></span>
                    </div>
                    {instance.workflowName && (
                        <div className="flex items-center gap-2 text-sm text-slate-600">
                            <Play size={14} className="text-slate-400 flex-shrink-0" />
                            <span className="truncate">{instance.workflowName}</span>
                        </div>
                    )}
                    {instance.systemName && (
                        <div className="flex items-center gap-2 text-sm text-slate-600">
                            <Server size={14} className="text-slate-400 flex-shrink-0" />
                            <span className="truncate">{instance.systemName}</span>
                        </div>
                    )}
                </div>

                {/* Time info */}
                <div className="text-xs text-slate-400 space-y-1 mb-4">
                    {instance.startTime && (
                        <div>开始: {instance.startTime}</div>
                    )}
                    {instance.endTime && (
                        <div>结束: {instance.endTime}</div>
                    )}
                </div>

                {/* Actions */}
                <div className="flex items-center gap-2 mt-auto pt-4 border-t border-slate-100" onClick={(e) => e.stopPropagation()}>
                    {onViewLog && (
                        <button
                            onClick={() => onViewLog(instance)}
                            className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 text-xs font-bold text-slate-600 bg-slate-50 hover:bg-slate-200 hover:text-slate-800 rounded-xl transition-all"
                        >
                            <FileText size={14} />
                            日志
                        </button>
                    )}
                    {canRerun && onRerun && (
                        <button
                            onClick={() => onRerun(instance)}
                            className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 text-xs font-bold text-blue-600 bg-blue-50 hover:bg-blue-600 hover:text-white rounded-xl transition-all shadow-sm shadow-blue-100"
                        >
                            <RotateCw size={14} />
                            重跑
                        </button>
                    )}
                    {canStop && onStop && (
                        <button
                            onClick={() => onStop(instance)}
                            className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 text-xs font-bold text-red-600 bg-red-50 hover:bg-red-600 hover:text-white rounded-xl transition-all shadow-sm shadow-red-100"
                        >
                            <XCircle size={14} />
                            停止
                        </button>
                    )}
                </div>
            </div>
        </div>
    );
};

export default InstanceCard;
