import React from 'react';
import { Play, Edit, Trash2, GitFork, Clock, Server, FileCode } from 'lucide-react';

interface TaskCardProps {
    task: {
        id: string;
        name: string;
        type: string;
        systemName?: string;
        workflowName?: string;
        cronExpression?: string;
        updateTime?: string;
        status?: number;
    };
    onEdit?: (task: any) => void;
    onDelete?: (task: any) => void;
    onRun?: (task: any) => void;
    onShowDependencies?: (taskId: string) => void;
}

const typeColors: Record<string, { bg: string; text: string; border: string }> = {
    SHELL: { bg: 'bg-emerald-50', text: 'text-emerald-700', border: 'border-emerald-200' },
    SQL: { bg: 'bg-blue-50', text: 'text-blue-700', border: 'border-blue-200' },
    PYTHON: { bg: 'bg-amber-50', text: 'text-amber-700', border: 'border-amber-200' },
    DATAX: { bg: 'bg-purple-50', text: 'text-purple-700', border: 'border-purple-200' },
    HTTP: { bg: 'bg-cyan-50', text: 'text-cyan-700', border: 'border-cyan-200' },
    PROCEDURE: { bg: 'bg-pink-50', text: 'text-pink-700', border: 'border-pink-200' },
    DEPENDENT: { bg: 'bg-slate-50', text: 'text-slate-700', border: 'border-slate-200' }
};

const TaskCard: React.FC<TaskCardProps> = ({
    task,
    onEdit,
    onDelete,
    onRun,
    onShowDependencies
}) => {
    const colors = typeColors[task.type] || typeColors.SHELL;

    return (
        <div className="group relative bg-white rounded-xl border border-slate-200 p-5 transition-all duration-300 hover:shadow-xl hover:border-blue-300 hover:-translate-y-1">
            {/* Status indicator bar */}
            <div className={`absolute left-0 top-0 bottom-0 w-1 rounded-l-xl ${task.status === 0 ? 'bg-slate-300' : 'bg-gradient-to-b from-blue-500 to-indigo-600'}`} />

            {/* Header */}
            <div className="flex items-start justify-between mb-3 pl-2">
                <div className="flex-1 min-w-0">
                    <h3 className="font-semibold text-slate-800 text-base truncate group-hover:text-blue-600 transition-colors">
                        {task.name}
                    </h3>
                    <p className="text-xs text-slate-400 font-mono mt-0.5">{task.id}</p>
                </div>
                <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${colors.bg} ${colors.text} border ${colors.border}`}>
                    {task.type}
                </span>
            </div>

            {/* Info rows */}
            <div className="space-y-2 pl-2 mb-4">
                {task.workflowName && (
                    <div className="flex items-center gap-2 text-sm text-slate-600">
                        <GitFork size={14} className="text-slate-400 flex-shrink-0" />
                        <span className="truncate">{task.workflowName}</span>
                    </div>
                )}
                {task.systemName && (
                    <div className="flex items-center gap-2 text-sm text-slate-600">
                        <Server size={14} className="text-slate-400 flex-shrink-0" />
                        <span className="truncate">{task.systemName}</span>
                    </div>
                )}
                {task.cronExpression && (
                    <div className="flex items-center gap-2 text-sm text-slate-600">
                        <Clock size={14} className="text-slate-400 flex-shrink-0" />
                        <span className="font-mono text-xs">{task.cronExpression}</span>
                    </div>
                )}
            </div>

            {/* Footer */}
            <div className="flex items-center justify-between pt-3 border-t border-slate-100 pl-2">
                <span className="text-xs text-slate-400">
                    更新于 {task.updateTime ? new Date(task.updateTime).toLocaleDateString() : '-'}
                </span>
                <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                    {onShowDependencies && (
                        <button
                            onClick={() => onShowDependencies(task.id)}
                            className="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                            title="查看依赖"
                        >
                            <GitFork size={16} />
                        </button>
                    )}
                    {onEdit && (
                        <button
                            onClick={() => onEdit(task)}
                            className="p-1.5 text-slate-400 hover:text-amber-600 hover:bg-amber-50 rounded-lg transition-colors"
                            title="编辑"
                        >
                            <Edit size={16} />
                        </button>
                    )}
                    {onRun && (
                        <button
                            onClick={() => onRun(task)}
                            className="p-1.5 text-slate-400 hover:text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors"
                            title="运行"
                        >
                            <Play size={16} />
                        </button>
                    )}
                    {onDelete && (
                        <button
                            onClick={() => onDelete(task)}
                            className="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                            title="删除"
                        >
                            <Trash2 size={16} />
                        </button>
                    )}
                </div>
            </div>
        </div>
    );
};

export default TaskCard;
