import React from 'react';
import {
    CircleDashed, FileSearch, Gauge, Info, Network, Target,
} from 'lucide-react';
import type { ArkDesktopSlashCommand } from './types';

const commandCatalog: Array<{
    name: string;
    label: string;
    description: string;
    icon: React.ElementType;
}> = [
    { name: 'goal', label: '持续目标', description: '设置、查看、暂停或恢复自主目标', icon: Target },
    { name: 'workflow', label: '工作流', description: '启动或管理运行时工作流', icon: Network },
    { name: 'deep-research', label: '深度研究', description: '并行检索、交叉验证并生成研究报告', icon: FileSearch },
    { name: 'context', label: '上下文', description: '查看上下文窗口占用', icon: Gauge },
    { name: 'session-info', label: '会话信息', description: '查看模型、轮次与会话状态', icon: Info },
    { name: 'compact', label: '压缩上下文', description: '整理长会话并释放上下文空间', icon: CircleDashed },
];

const SessionCommandBar: React.FC<{
    commands: ArkDesktopSlashCommand[];
    disabled?: boolean;
    onSelect: (value: string) => void;
}> = ({ commands, disabled = false, onSelect }) => {
    const available = new Map(commands.map((command) => [command.name, command]));
    const actions = commandCatalog.filter((item) => available.has(item.name));
    if (actions.length === 0) return null;

    return <div className="mb-2 flex items-center gap-2 overflow-x-auto pb-0.5" aria-label="当前会话能力">
        <span className="shrink-0 px-1 text-[11px] font-medium text-slate-400">会话能力</span>
        {actions.map((action) => {
            const Icon = action.icon;
            const command = available.get(action.name)!;
            return <button
                key={action.name}
                type="button"
                disabled={disabled}
                onClick={() => onSelect(`/${action.name}${command.inputHint ? ' ' : ''}`)}
                className="flex h-8 shrink-0 items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-2.5 text-xs font-medium text-slate-600 transition hover:border-slate-300 hover:bg-slate-50 hover:text-slate-800 disabled:cursor-not-allowed disabled:opacity-45"
                title={action.description}
            >
                <Icon size={14} strokeWidth={1.8} />
                {action.label}
            </button>;
        })}
    </div>;
};

export default SessionCommandBar;
