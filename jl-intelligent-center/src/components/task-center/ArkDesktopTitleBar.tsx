import React from 'react';
import { PanelLeft, Settings } from 'lucide-react';

export const ArkDesktopSidebarToggle: React.FC<{
    collapsed: boolean;
    onToggle: () => void;
}> = ({ collapsed, onToggle }) => (
    <button
        type="button"
        onClick={onToggle}
        className="flex h-8 w-8 shrink-0 items-center justify-center rounded-md border border-transparent bg-transparent text-slate-400 transition-colors duration-150 hover:bg-slate-50 hover:text-slate-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-300 focus-visible:ring-offset-1"
        title={collapsed ? '展开左侧工具栏' : '折叠左侧工具栏'}
        aria-label={collapsed ? '展开左侧工具栏' : '折叠左侧工具栏'}
    >
        <PanelLeft size={16} strokeWidth={1.8} />
    </button>
);

export const ArkDesktopTitleContent: React.FC<{
    title: string;
    meta?: string;
    settingsActive: boolean;
    onOpenSettings: () => void;
    icon: React.ReactNode;
    status?: React.ReactNode;
}> = ({ title, meta, settingsActive, onOpenSettings, icon, status }) => (
    <div className="flex min-w-0 flex-1 items-center justify-between gap-4 px-4">
        <div data-tauri-drag-region className="flex min-w-0 items-center gap-2.5">
            <span className="shrink-0 text-[#44454a]">{icon}</span>
            <div className="min-w-0">
                <div className="flex min-w-0 items-center gap-2">
                    <div className="truncate text-[15px] font-semibold tracking-[-0.02em] text-[#303136]">{title}</div>
                    {status}
                </div>
                {meta && <div className="mt-0.5 truncate text-[10px] leading-none text-slate-400">{meta}</div>}
            </div>
        </div>
        <div className="flex shrink-0 items-center gap-1">
            <button
                type="button"
                onClick={onOpenSettings}
                className={`rounded-md p-1 text-slate-500 transition hover:bg-slate-100 hover:text-slate-800 ${settingsActive ? 'bg-slate-100 text-slate-900' : ''}`}
                title="设置"
                aria-label="设置"
            >
                <Settings size={17} strokeWidth={1.8} />
            </button>
        </div>
    </div>
);
