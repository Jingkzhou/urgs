import React, { useEffect, useMemo, useState } from 'react';
import { Command, CornerDownLeft } from 'lucide-react';
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
    loop: '按指定间隔重复执行提示词',
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

const SlashCommandMenu: React.FC<SlashCommandMenuProps> = ({ value, commands, onChange, disabled, children }) => {
    const query = slashQuery(value);
    const [activeIndex, setActiveIndex] = useState(0);
    const [dismissedValue, setDismissedValue] = useState<string | null>(null);
    const filteredCommands = useMemo(() => {
        if (query === null) return [];
        return commands
            .filter((command) => {
                const searchable = `${command.name} ${command.description} ${commandDescriptions[command.name] || ''}`.toLowerCase();
                return !query || searchable.includes(query);
            })
            .slice(0, 10);
    }, [commands, query]);
    const visible = !disabled && query !== null && dismissedValue !== value;

    useEffect(() => {
        setActiveIndex(0);
    }, [query, commands]);

    useEffect(() => {
        if (dismissedValue !== null && dismissedValue !== value) setDismissedValue(null);
    }, [dismissedValue, value]);

    const select = (command: ArkDesktopSlashCommand) => {
        onChange(`/${command.name}${command.inputHint ? ' ' : ''}`);
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
        {visible && <div className="absolute bottom-[calc(100%+10px)] left-0 right-0 z-30 overflow-hidden rounded-2xl border border-slate-200 bg-white/98 shadow-[0_18px_55px_rgba(15,23,42,0.16)] backdrop-blur-xl" role="listbox" aria-label="Grok 会话命令">
            <div className="flex items-center justify-between border-b border-slate-100 px-3.5 py-2 text-[11px] font-medium text-slate-400">
                <span className="flex items-center gap-1.5"><Command size={13} />Grok 会话命令</span>
                <span>↑↓ 选择 · Enter 填入 · Esc 关闭</span>
            </div>
            {filteredCommands.length > 0 ? <div className="custom-scrollbar max-h-72 overflow-y-auto p-1.5">
                {filteredCommands.map((command, index) => {
                    const description = commandDescriptions[command.name] || command.description || '执行 Grok 会话命令';
                    return <button
                        key={command.name}
                        type="button"
                        role="option"
                        aria-selected={index === activeIndex}
                        onMouseEnter={() => setActiveIndex(index)}
                        onMouseDown={(event) => event.preventDefault()}
                        onClick={() => select(command)}
                        className={`flex w-full items-start gap-3 rounded-xl px-3 py-2.5 text-left transition ${index === activeIndex ? 'bg-slate-100' : 'hover:bg-slate-50'}`}
                    >
                        <span className="mt-0.5 shrink-0 font-mono text-[13px] font-semibold text-slate-800">/{command.name}</span>
                        <span className="min-w-0 flex-1">
                            <span className="block text-xs leading-5 text-slate-500">{description}</span>
                            {command.inputHint && <span className="mt-0.5 block truncate font-mono text-[10px] text-slate-400">{command.inputHint}</span>}
                        </span>
                        <CornerDownLeft size={13} className={`mt-1 shrink-0 ${index === activeIndex ? 'text-slate-500' : 'text-slate-300'}`} />
                    </button>;
                })}
            </div> : <div className="px-4 py-5 text-center text-xs text-slate-400">没有匹配的当前会话命令</div>}
        </div>}
        {children}
    </div>;
};

export default SlashCommandMenu;
