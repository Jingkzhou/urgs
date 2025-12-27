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
}

const statusConfig: Record<string, {
    gradient: string;
    bg: string;
    text: string;
    icon: React.ReactNode;
    label: string;
}> = {
    SUCCESS: {
        gradient: 'from-emerald-500 to-green-600',
        bg: 'bg-emerald-50',
        text: 'text-emerald-700',
        icon: <CheckCircle size={14} />,
        label: '成功'
    },
    FORCE_SUCCESS: {
        gradient: 'from-emerald-400 to-teal-500',
        bg: 'bg-teal-50',
        text: 'text-teal-700',
        icon: <CheckCircle size={14} />,
        label: '强制成功'
    },
    FAIL: {
        gradient: 'from-red-500 to-rose-600',
        bg: 'bg-red-50',
        text: 'text-red-700',
        icon: <XCircle size={14} />,
        label: '失败'
    },
    RUNNING: {
        gradient: 'from-blue-500 to-indigo-600',
        bg: 'bg-blue-50',
        text: 'text-blue-700',
        icon: <RotateCw size={14} className="animate-spin" />,
        label: '运行中'
    },
    WAITING: {
        gradient: 'from-amber-400 to-orange-500',
        bg: 'bg-amber-50',
        text: 'text-amber-700',
        icon: <Clock size={14} />,
        label: '等待中'
    },
    PENDING: {
        gradient: 'from-slate-400 to-slate-500',
        bg: 'bg-slate-50',
        text: 'text-slate-700',
        icon: <Clock size={14} />,
        label: '待执行'
    },
    STOPPED: {
        gradient: 'from-slate-500 to-slate-600',
        bg: 'bg-slate-100',
        text: 'text-slate-600',
        icon: <XCircle size={14} />,
        label: '已停止'
    }
};

const InstanceCard: React.FC<InstanceCardProps> = ({
    instance,
    onViewLog,
    onRerun,
    onStop,
    onForceSuccess
}) => {
    const config = statusConfig[instance.status] || statusConfig.PENDING;
    const isRunning = instance.status === 'RUNNING';
    const canRerun = ['SUCCESS', 'FAIL', 'FORCE_SUCCESS', 'STOPPED'].includes(instance.status);
    const canStop = ['RUNNING', 'WAITING', 'PENDING'].includes(instance.status);
    const canForceSuccess = ['FAIL', 'RUNNING', 'WAITING', 'PENDING'].includes(instance.status);

    return (
        <div className="group relative bg-white rounded-xl border border-slate-200 overflow-hidden transition-all duration-300 hover:shadow-xl hover:border-blue-300 hover:-translate-y-1">
            {/* Status gradient bar */}
            <div className={`h-1.5 bg-gradient-to-r ${config.gradient}`} />

            <div className="p-5">
                {/* Header */}
                <div className="flex items-start justify-between mb-3">
                    <div className="flex-1 min-w-0">
                        <h3 className="font-semibold text-slate-800 text-base truncate group-hover:text-blue-600 transition-colors">
                            {instance.taskName || instance.taskId}
                        </h3>
                        <p className="text-xs text-slate-400 font-mono mt-0.5">#{instance.id}</p>
                    </div>
                    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${config.bg} ${config.text}`}>
                        {config.icon}
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
                <div className="flex items-center gap-2 pt-3 border-t border-slate-100">
                    {onViewLog && (
                        <button
                            onClick={() => onViewLog(instance)}
                            className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 text-sm font-medium text-slate-600 bg-slate-50 hover:bg-slate-100 rounded-lg transition-colors"
                        >
                            <FileText size={14} />
                            日志
                        </button>
                    )}
                    {canRerun && onRerun && (
                        <button
                            onClick={() => onRerun(instance)}
                            className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 text-sm font-medium text-blue-600 bg-blue-50 hover:bg-blue-100 rounded-lg transition-colors"
                        >
                            <RotateCw size={14} />
                            重跑
                        </button>
                    )}
                    {canStop && onStop && (
                        <button
                            onClick={() => onStop(instance)}
                            className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 text-sm font-medium text-red-600 bg-red-50 hover:bg-red-100 rounded-lg transition-colors"
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
