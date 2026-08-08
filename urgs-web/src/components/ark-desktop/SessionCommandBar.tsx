import React, { useEffect, useRef, useState } from 'react';
import {
    BarChart3, Check, CircleDashed, Code2, FileSearch, FileText, Gauge, Info,
    Network, Paperclip, Plug, Plus, RefreshCw, Search, Sparkles, Target, Workflow,
} from 'lucide-react';
import type { GrokDiscoveredPlugin } from '@/services/grokDesktop';
import type { ArkDesktopSkill, ArkDesktopSlashCommand } from './types';

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

const skillCategoryMeta: Record<ArkDesktopSkill['category'], { label: string; icon: React.ElementType }> = {
    office: { label: '办公', icon: FileText },
    data: { label: '数据', icon: BarChart3 },
    code: { label: '开发', icon: Code2 },
    research: { label: '研究', icon: Search },
    workflow: { label: '编排', icon: Workflow },
};

const SectionLabel: React.FC<{ children: React.ReactNode; action?: React.ReactNode }> = ({ children, action }) => (
    <div className="flex items-center justify-between px-3 pb-1 pt-3 text-[12px] font-medium text-slate-400">
        <span>{children}</span>{action}
    </div>
);

const SessionCommandBar: React.FC<{
    commands: ArkDesktopSlashCommand[];
    disabled?: boolean;
    onSelect: (value: string) => void;
    onChooseAttachments?: () => Promise<void>;
    skills?: ArkDesktopSkill[];
    selectedSkillIds?: string[];
    onToggleSkill?: (skillId: string) => void;
    plugins?: GrokDiscoveredPlugin[];
    sessionPluginDirs?: string[];
    capabilitiesLoading?: boolean;
    capabilitiesError?: string;
    onRefreshCapabilities?: () => Promise<void>;
    onManagePlugins?: () => void;
}> = ({
    commands,
    disabled = false,
    onSelect,
    onChooseAttachments,
    skills = [],
    selectedSkillIds = [],
    onToggleSkill,
    plugins = [],
    sessionPluginDirs = [],
    capabilitiesLoading = false,
    capabilitiesError = '',
    onRefreshCapabilities,
    onManagePlugins,
}) => {
    const [open, setOpen] = useState(false);
    const menuRef = useRef<HTMLDivElement>(null);
    const available = new Map(commands.map((command) => [command.name, command]));
    const actions = commandCatalog.filter((item) => available.has(item.name));

    useEffect(() => {
        if (!open) return undefined;
        const close = (event: MouseEvent) => {
            if (!menuRef.current?.contains(event.target as Node)) setOpen(false);
        };
        const closeOnEscape = (event: KeyboardEvent) => {
            if (event.key === 'Escape') setOpen(false);
        };
        window.addEventListener('mousedown', close);
        window.addEventListener('keydown', closeOnEscape);
        return () => {
            window.removeEventListener('mousedown', close);
            window.removeEventListener('keydown', closeOnEscape);
        };
    }, [open]);

    const enabledSkills = skills.filter((skill) => skill.enabled);
    const enabledPlugins = plugins.filter((plugin) => plugin.enabled);
    const showPlugins = Boolean(onManagePlugins || onRefreshCapabilities || enabledPlugins.length || sessionPluginDirs.length);

    if (actions.length === 0 && !onChooseAttachments && enabledSkills.length === 0 && !showPlugins) return null;

    const select = (name: string) => {
        onSelect(`/${name} `);
        setOpen(false);
    };

    return <div ref={menuRef} className="relative" aria-label="添加">
        <button
            type="button"
            onClick={() => setOpen((current) => !current)}
            className={`flex h-8 w-8 items-center justify-center rounded-lg text-slate-500 transition hover:bg-slate-100 hover:text-slate-700 ${open ? 'bg-slate-100 text-slate-700' : ''}`}
            title="添加"
            aria-label="添加"
            aria-haspopup="menu"
            aria-expanded={open}
        >
            <Plus size={17} strokeWidth={1.8} />
        </button>
        {open && <div className="absolute bottom-[calc(100%+10px)] left-0 z-40 w-[min(820px,calc(100vw-48px))] overflow-hidden rounded-[22px] border border-slate-200 bg-white p-2 shadow-[0_18px_45px_rgba(15,23,42,0.12)]" role="menu" aria-label="添加菜单">
            <div className="custom-scrollbar max-h-[min(420px,calc(100vh-240px))] overflow-y-auto pr-1">
            {onChooseAttachments && <SectionLabel>添加</SectionLabel>}
            {onChooseAttachments && <button
                type="button"
                role="menuitem"
                disabled={disabled}
                onClick={() => { setOpen(false); void onChooseAttachments(); }}
                className="flex h-11 w-full items-center gap-3 rounded-xl px-3 text-left transition hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-45"
                title={disabled ? '当前暂不可添加文件' : '从本地选择文件'}
            >
                <Paperclip size={18} strokeWidth={1.8} className="shrink-0 text-slate-500" />
                <span className="flex min-w-0 flex-1 items-baseline gap-3">
                    <span className="shrink-0 text-[14px] font-medium text-slate-700">文件</span>
                    <span className="min-w-0 truncate text-[13px] text-slate-400">从本地选择最多 20 个文件</span>
                </span>
            </button>}
            {actions.length > 0 && <SectionLabel>会话能力</SectionLabel>}
            {actions.map((action) => {
                const Icon = action.icon;
                return <button
                    key={action.name}
                    type="button"
                    role="menuitem"
                    disabled={disabled}
                    onClick={() => select(action.name)}
                    className="flex min-h-11 w-full items-center gap-3 rounded-xl px-3 py-2 text-left transition hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-45"
                    title={disabled ? '任务运行中暂不可使用' : action.description}
                >
                    <Icon size={18} strokeWidth={1.8} className="shrink-0 text-slate-500" />
                    <span className="flex min-w-0 flex-1 items-baseline gap-3">
                        <span className="shrink-0 text-[14px] font-medium text-slate-700">{action.label}</span>
                        <span className="min-w-0 truncate text-[13px] text-slate-400">{action.description}</span>
                    </span>
                </button>;
            })}
            {enabledSkills.length > 0 && <SectionLabel>技能</SectionLabel>}
            {enabledSkills.map((skill) => {
                const meta = skillCategoryMeta[skill.category];
                const Icon = meta.icon;
                const selected = selectedSkillIds.includes(skill.id);
                return <button
                    key={skill.id}
                    type="button"
                    role="menuitemcheckbox"
                    aria-checked={selected}
                    disabled={disabled || !onToggleSkill}
                    onClick={() => onToggleSkill?.(skill.id)}
                    className={`flex min-h-11 w-full items-center gap-3 rounded-xl px-3 py-2 text-left transition disabled:cursor-not-allowed disabled:opacity-45 ${selected ? 'bg-slate-100' : 'hover:bg-slate-100'}`}
                    title={`${selected ? '取消' : '添加'}“${skill.name}”技能`}
                >
                    <Icon size={18} strokeWidth={1.8} className="shrink-0 text-slate-500" />
                    <span className="flex min-w-0 flex-1 items-baseline gap-3">
                        <span className="shrink-0 text-[14px] font-medium text-slate-700">{skill.name}</span>
                        <span className="min-w-0 truncate text-[13px] text-slate-400">{meta.label} · {skill.description}</span>
                    </span>
                    {selected && <Check size={16} className="shrink-0 text-slate-700" />}
                </button>;
            })}
            {showPlugins && <SectionLabel action={onRefreshCapabilities ? <button
                type="button"
                disabled={capabilitiesLoading}
                onClick={() => void onRefreshCapabilities()}
                className="rounded-md p-1 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600 disabled:opacity-45"
                title="刷新会话能力"
                aria-label="刷新会话能力"
            ><RefreshCw size={13} className={capabilitiesLoading ? 'animate-spin' : ''} /></button> : undefined}>插件</SectionLabel>}
            {enabledPlugins.map((plugin) => <div key={`plugin-${plugin.id}`} role="menuitem" aria-disabled="true" className="flex min-h-11 w-full items-center gap-3 rounded-xl px-3 py-2 text-left">
                <Plug size={18} strokeWidth={1.8} className="shrink-0 text-emerald-600" />
                <span className="flex min-w-0 flex-1 items-baseline gap-3">
                    <span className="shrink-0 text-[14px] font-medium text-slate-700">{plugin.name}</span>
                    <span className="min-w-0 truncate text-[13px] text-slate-400">{plugin.version ? `v${plugin.version} · ` : ''}已启用，新会话自动加载</span>
                </span>
            </div>)}
            {sessionPluginDirs.map((directory) => <div key={`directory-${directory}`} role="menuitem" aria-disabled="true" className="flex min-h-11 w-full items-center gap-3 rounded-xl px-3 py-2 text-left">
                <Plug size={18} strokeWidth={1.8} className="shrink-0 text-blue-600" />
                <span className="flex min-w-0 flex-1 items-baseline gap-3">
                    <span className="shrink-0 text-[14px] font-medium text-slate-700">{directory.split(/[\\/]/).filter(Boolean).pop() || directory}</span>
                    <span className="min-w-0 truncate text-[13px] text-slate-400">临时插件目录 · 新会话自动加载</span>
                </span>
            </div>)}
            {showPlugins && <button
                type="button"
                role="menuitem"
                disabled={!onManagePlugins}
                onClick={() => { setOpen(false); onManagePlugins?.(); }}
                className="flex min-h-11 w-full items-center gap-3 rounded-xl px-3 py-2 text-left transition hover:bg-slate-100 disabled:cursor-default"
            >
                <Sparkles size={18} strokeWidth={1.8} className="shrink-0 text-slate-500" />
                <span className="flex min-w-0 flex-1 items-baseline gap-3">
                    <span className="shrink-0 text-[14px] font-medium text-slate-700">管理插件</span>
                    <span className="min-w-0 truncate text-[13px] text-slate-400">{capabilitiesError || (capabilitiesLoading ? '正在读取 Grok 插件…' : enabledPlugins.length > 0 || sessionPluginDirs.length > 0 ? '安装、启用或查看插件组件' : '暂无已启用插件，前往设置管理')}</span>
                </span>
            </button>}
            </div>
        </div>}
    </div>;
};

export default SessionCommandBar;
