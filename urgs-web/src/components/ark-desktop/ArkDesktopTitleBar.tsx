import React from 'react';
import { Folder, PanelLeft, Settings } from 'lucide-react';

export const ArkDesktopSidebarToggle: React.FC<{
    collapsed: boolean;
    onToggle: () => void;
}> = ({ collapsed, onToggle }) => (
    <button
        type="button"
        onClick={onToggle}
        className="absolute left-[80px] top-[16px] flex h-7 w-7 -translate-y-1/2 items-center justify-center rounded-md text-[#8b8e92] transition hover:bg-slate-100 hover:text-slate-700"
        title={collapsed ? '展开左侧工具栏' : '折叠左侧工具栏'}
        aria-label={collapsed ? '展开左侧工具栏' : '折叠左侧工具栏'}
    >
        <PanelLeft className="h-4 w-4" strokeWidth={1.6} />
    </button>
);

export const ArkDesktopTitleContent: React.FC<{
    title: string;
    settingsActive: boolean;
    onOpenSettings: () => void;
}> = ({ title, settingsActive, onOpenSettings }) => (
    <div className="flex min-w-0 flex-1 items-center justify-between gap-4 px-4">
        <div data-tauri-drag-region className="flex min-w-0 items-center gap-2.5">
            <Folder size={16} strokeWidth={1.8} className="shrink-0 text-[#44454a]" />
            <div className="truncate text-[16px] font-semibold tracking-[-0.02em] text-[#303136]">{title}</div>
        </div>
        <button
            type="button"
            onClick={onOpenSettings}
            className={`shrink-0 rounded-md p-1 text-slate-500 transition hover:bg-slate-100 hover:text-slate-800 ${settingsActive ? 'bg-slate-100 text-slate-900' : ''}`}
            title="设置"
            aria-label="设置"
        >
            <Settings size={17} strokeWidth={1.8} />
        </button>
    </div>
);
