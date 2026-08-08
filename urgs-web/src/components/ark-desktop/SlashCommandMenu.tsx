import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
    Box,
    Brain,
    CircleDashed,
    CircleHelp,
    Code2,
    Command,
    CornerDownLeft,
    FileSearch,
    GitPullRequest,
    Info,
    Network,
    Repeat2,
    Search,
    ShieldCheck,
    Sparkles,
    Target,
    WandSparkles,
    Wrench,
} from 'lucide-react';
import type { ArkDesktopSlashCommand } from './types';

const commandDescriptions: Record<string, string> = {
    compact: '压缩当前会话上下文，可补充需要保留的内容',
    'always-approve': '切换无需逐次确认的工具权限模式',
    flush: '立即把当前会话的重要内容写入记忆',
    dream: '整理并合并已经保存的记忆',
    memory: '查看或开关跨会话记忆',
    context: '查看上下文窗口占用和会话统计',
    'hooks-trust': '信任当前项目并允许执行 Hooks',
    'hooks-list': '查看当前会话加载的 Hooks',
    'hooks-add': '添加 Hook 文件或目录',
    'hooks-remove': '移除 Hook 文件或目录',
    'hooks-untrust': '取消当前项目的 Hooks 信任',
    plugins: '查看、重载、安装或移除插件',
    'reload-plugins': '重新加载本地插件',
    'session-info': '查看当前模型、轮次和上下文信息',
    feedback: '提交当前会话的反馈',
    goal: '设置、查看、暂停或恢复自主目标',
    workflow: '启动或管理运行时工作流',
    'deep-research': '并行检索、交叉验证并生成研究报告',
    loop: '按指定间隔重复执行提示词',
};

const commandLabels: Record<string, string> = {
    compact: '压缩',
    'always-approve': '完全访问',
    flush: '写入记忆',
    dream: '整理记忆',
    memory: '记忆',
    context: '上下文',
    'session-info': '会话信息',
    goal: '目标',
    workflow: '工作流',
    'deep-research': '深度研究',
    'check-work': '检查工作',
    'code-review': '代码审查',
    'create-skill': '创建技能',
    help: '帮助',
    imagine: '图像创作',
    'find-skills': '查找技能',
    feedback: '反馈',
    loop: '循环执行',
    plugins: '插件',
    'reload-plugins': '重载插件',
    'hooks-trust': '信任 Hooks',
    'hooks-list': '查看 Hooks',
    'hooks-add': '添加 Hook',
    'hooks-remove': '移除 Hook',
    'hooks-untrust': '取消 Hooks 信任',
    'open-knowledge-discovery': '探索知识库',
    'open-knowledge-write-skill': '编写技能',
};

const commandIcon = (name: string) => {
    if (name === 'compact') return CircleDashed;
    if (name === 'context') return Sparkles;
    if (name === 'always-approve') return ShieldCheck;
    if (name === 'session-info') return Info;
    if (name === 'goal') return Target;
    if (name === 'workflow') return Network;
    if (name === 'deep-research') return FileSearch;
    if (name.includes('review')) return GitPullRequest;
    if (name.includes('check')) return FileSearch;
    if (name.includes('skill')) return WandSparkles;
    if (name.includes('memory') || name === 'flush' || name === 'dream') return Brain;
    if (name.includes('plugin') || name.includes('hook')) return Wrench;
    if (name === 'feedback') return CircleHelp;
    if (name === 'loop') return Repeat2;
    if (name.includes('find') || name === 'help') return Search;
    if (name === 'imagine') return Sparkles;
    return Code2;
};

const commandLabel = (name: string) => {
    const displayName = name.includes(':') ? name.slice(name.lastIndexOf(':') + 1) : name;
    return commandLabels[name]
        || commandLabels[displayName]
        || displayName.replace(/[-_]/g, ' ').replace(/\b\w/g, (letter) => letter.toUpperCase());
};

const coreSessionCommands: ArkDesktopSlashCommand[] = [
    { name: 'compact', description: 'Compress conversation history', inputHint: 'optional context about what to preserve' },
    { name: 'always-approve', description: 'Toggle always-approve mode', inputHint: 'on|off' },
    { name: 'context', description: 'Show context window usage and session stats' },
    { name: 'session-info', description: 'Show session details' },
];

const availableCommands = (commands: ArkDesktopSlashCommand[]) => commands.length > 0 ? commands : coreSessionCommands;

const selectedSlashCommand = (value: string, commands: ArkDesktopSlashCommand[]) => {
    const match = value.match(/^\/([^\s/]+)\s([\s\S]*)$/);
    if (!match) return undefined;
    const command = availableCommands(commands).find((item) => item.name === match[1]);
    return command ? { command, prefix: `/${command.name} ` } : undefined;
};

const slashQuery = (value: string) => {
    const match = value.match(/^\/([^\s/]*)$/);
    return match ? match[1].toLowerCase() : null;
};

export interface SlashCommandMenuProps {
    value: string;
    commands: ArkDesktopSlashCommand[];
    onChange: (value: string) => void;
    disabled?: boolean;
    children: React.ReactNode;
}

export interface ConversationPromptInputProps {
    value: string;
    commands?: ArkDesktopSlashCommand[];
    onChange: (value: string) => void;
    onSubmit: () => void | Promise<void>;
    disabled?: boolean;
    slashDisabled?: boolean;
    placeholder: string;
    rows?: number;
    className?: string;
}

const SlashCommandMenu: React.FC<SlashCommandMenuProps> = ({ value, commands, onChange, disabled, children }) => {
    const query = slashQuery(value);
    const [activeIndex, setActiveIndex] = useState(0);
    const [dismissedValue, setDismissedValue] = useState<string | null>(null);
    const menuRef = useRef<HTMLDivElement>(null);
    const filteredCommands = useMemo(() => {
        if (query === null) return [];
        return availableCommands(commands)
            .filter((command) => {
                const searchable = `${command.name} ${command.description} ${commandDescriptions[command.name] || ''}`.toLowerCase();
                return !query || searchable.includes(query);
            });
    }, [commands, query]);
    const visible = !disabled && query !== null && dismissedValue !== value;

    useEffect(() => {
        setActiveIndex(0);
    }, [query, commands]);

    useEffect(() => {
        if (dismissedValue !== null && dismissedValue !== value) setDismissedValue(null);
    }, [dismissedValue, value]);

    useEffect(() => {
        if (!visible) return;
        const closeOnOutsideInteraction = (event: Event) => {
            if (event.target instanceof Node && menuRef.current?.contains(event.target)) return;
            setDismissedValue(value);
        };
        document.addEventListener('pointerdown', closeOnOutsideInteraction, true);
        document.addEventListener('click', closeOnOutsideInteraction, true);
        return () => {
            document.removeEventListener('pointerdown', closeOnOutsideInteraction, true);
            document.removeEventListener('click', closeOnOutsideInteraction, true);
        };
    }, [value, visible]);

    const select = (command: ArkDesktopSlashCommand) => {
        const nextValue = `/${command.name} `;
        setDismissedValue(nextValue);
        onChange(nextValue);
    };

    const handleKeyDownCapture = (event: React.KeyboardEvent<HTMLDivElement>) => {
        if (!visible) return;
        if (event.key === 'Escape') {
            event.preventDefault();
            event.stopPropagation();
            setDismissedValue(value);
            return;
        }
        if (filteredCommands.length === 0) return;
        if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
            event.preventDefault();
            event.stopPropagation();
            const direction = event.key === 'ArrowDown' ? 1 : -1;
            setActiveIndex((current) => (current + direction + filteredCommands.length) % filteredCommands.length);
            return;
        }
        if (event.key === 'Tab' || event.key === 'Enter') {
            event.preventDefault();
            event.stopPropagation();
            select(filteredCommands[activeIndex] || filteredCommands[0]);
        }
    };

    return <div className="relative" onKeyDownCapture={handleKeyDownCapture}>
        {visible && <div ref={menuRef} className="absolute bottom-[calc(100%+12px)] left-0 right-0 z-30 overflow-hidden rounded-[22px] border border-white/10 bg-[#292929]/[0.98] p-2 shadow-[0_24px_72px_rgba(15,23,42,0.32)] backdrop-blur-2xl" role="listbox" aria-label="Grok 会话命令">
            <div className="sr-only">{commands.length > 0 ? 'Grok 当前会话命令' : 'Grok 基础会话命令'}，使用上下方向键选择，按 Enter 填入命令。</div>
            {filteredCommands.length > 0 ? <div className="custom-scrollbar max-h-[min(440px,calc(100vh-220px))] overflow-y-auto">
                {filteredCommands.map((command, index) => {
                    const description = commandDescriptions[command.name] || command.description || '执行 Grok 会话命令';
                    const CommandIcon = commandIcon(command.name);
                    return <button
                        key={command.name}
                        type="button"
                        role="option"
                        aria-selected={index === activeIndex}
                        onMouseEnter={() => setActiveIndex(index)}
                        onMouseDown={(event) => event.preventDefault()}
                        onClick={() => select(command)}
                        className={`grid w-full grid-cols-[minmax(0,0.88fr)_minmax(210px,1.12fr)_16px] items-center gap-4 rounded-2xl px-3.5 py-3 text-left transition-colors duration-150 ${index === activeIndex ? 'bg-white/[0.12]' : 'hover:bg-white/[0.06]'}`}
                    >
                        <span className="flex min-w-0 items-center gap-3">
                            <CommandIcon size={20} strokeWidth={1.8} className={`shrink-0 ${index === activeIndex ? 'text-zinc-100' : 'text-zinc-300'}`} />
                            <span className="min-w-0 truncate text-[15px] font-medium leading-5 text-zinc-100">
                                {commandLabel(command.name)} <span className="font-mono text-[12px] font-normal text-zinc-500">/{command.name}</span>
                            </span>
                        </span>
                        <span className="min-w-0 text-right">
                            <span className="block truncate text-[13px] leading-5 text-zinc-400">{description}{command.inputHint ? ` · ${command.inputHint}` : ''}</span>
                        </span>
                        <CornerDownLeft size={15} className={`shrink-0 transition-opacity ${index === activeIndex ? 'text-zinc-300 opacity-100' : 'text-zinc-600 opacity-0'}`} />
                    </button>;
                })}
            </div> : <div className="flex min-h-28 flex-col items-center justify-center gap-2 px-4 py-5 text-center text-sm text-zinc-400"><Command size={18} className="text-zinc-500" /><span>没有匹配的当前会话命令</span></div>}
        </div>}
        {children}
    </div>;
};

export const ConversationPromptInput: React.FC<ConversationPromptInputProps> = ({
    value,
    commands = [],
    onChange,
    onSubmit,
    disabled = false,
    slashDisabled = false,
    placeholder,
    rows = 2,
    className = 'block w-full resize-none bg-transparent px-2.5 py-2 text-[15px] leading-6 text-slate-800 outline-none placeholder:text-slate-400 disabled:cursor-not-allowed',
}) => {
    const selected = useMemo(() => selectedSlashCommand(value, commands), [commands, value]);
    const visibleValue = selected ? value.slice(selected.prefix.length) : value;
    const handleChange = (nextValue: string) => onChange(selected ? `${selected.prefix}${nextValue}` : nextValue);
    const textareaClassName = selected ? className.replace(/\bw-full\b/, 'min-w-0 flex-1') : className;

    return <SlashCommandMenu value={value} commands={commands} onChange={onChange} disabled={disabled || slashDisabled}>
        <div className="relative flex min-w-0 flex-nowrap items-start">
            {selected && <span className="mt-2 ml-2 inline-flex max-w-[min(48%,420px)] shrink-0 items-center gap-2 whitespace-nowrap rounded-[14px] bg-transparent px-3 py-0 text-[15px] font-normal leading-6 text-[#60a5fa]" aria-label={`已选择命令 ${commandLabel(selected.command.name)}`}>
                <Box size={18} strokeWidth={1.8} className="shrink-0 text-[#60a5fa]" />
                <span className="truncate">{commandLabel(selected.command.name)}</span>
            </span>}
            <textarea
                value={visibleValue}
                onChange={(event) => handleChange(event.target.value)}
                onKeyDown={(event) => {
                    if (event.key === 'Backspace' && selected && !visibleValue) {
                        event.preventDefault();
                        onChange('');
                        return;
                    }
                    if (event.key !== 'Enter' || event.shiftKey || disabled || !value.trim()) return;
                    event.preventDefault();
                    void onSubmit();
                }}
                disabled={disabled}
                placeholder={placeholder}
                rows={rows}
                className={textareaClassName}
            />
        </div>
    </SlashCommandMenu>;
};

export default SlashCommandMenu;
