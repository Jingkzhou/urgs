import React, { useEffect, useMemo, useState } from 'react';
import { FileText, Hammer, Search, Sparkles, Wrench } from 'lucide-react';
import OnlineDocsTool from './OnlineDocsTool';

type ToolKey = 'online-docs';

interface ToolDefinition {
    key: ToolKey;
    title: string;
    description: string;
    icon: React.ComponentType<{ size?: number; className?: string }>;
    status: string;
    component: React.ComponentType;
}

const tools: ToolDefinition[] = [
    {
        key: 'online-docs',
        title: '在线文档',
        description: 'Office 文件在线预览、编辑与多人协同',
        icon: FileText,
        status: 'ONLYOFFICE Docs',
        component: OnlineDocsTool,
    },
];

const HASH_PREFIX = 'tools/';

const ToolsPage: React.FC = () => {
    const [activeTool, setActiveTool] = useState<ToolKey>('online-docs');
    const [searchText, setSearchText] = useState('');

    const activeToolConfig = tools.find(tool => tool.key === activeTool) || tools[0];
    const ActiveIcon = activeToolConfig.icon;

    // Filter tools by search text
    const filteredTools = useMemo(() => {
        if (!searchText.trim()) return tools;
        const lower = searchText.toLowerCase();
        return tools.filter(
            tool =>
                tool.title.toLowerCase().includes(lower) ||
                tool.description.toLowerCase().includes(lower),
        );
    }, [searchText]);

    // Sync active tool from URL hash
    useEffect(() => {
        const syncToolFromHash = () => {
            const path = window.location.hash.split('?')[0].replace('#/', '');
            if (path.startsWith(HASH_PREFIX)) {
                const requestedKey = path.slice(HASH_PREFIX.length);
                const match = tools.find(tool => tool.key === requestedKey);
                if (match) {
                    setActiveTool(match.key);
                }
            }
        };
        syncToolFromHash();
        window.addEventListener('hashchange', syncToolFromHash);
        return () => window.removeEventListener('hashchange', syncToolFromHash);
    }, []);

    const handleToolChange = (key: ToolKey) => {
        setActiveTool(key);
        window.location.hash = `#/${HASH_PREFIX}${key}`;
    };

    const ActiveToolComponent = activeToolConfig.component;

    return (
        <div className="flex h-full min-h-0 overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
            <aside className="flex w-80 shrink-0 flex-col border-r border-slate-200 bg-slate-50/80">
                <div className="border-b border-slate-200 px-5 py-5">
                    <div className="mb-4 flex items-center gap-3">
                        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-red-50 text-red-600">
                            <Hammer size={20} />
                        </div>
                        <div>
                            <h1 className="text-base font-black text-slate-900">工具箱</h1>
                            <p className="text-xs font-medium text-slate-500">常用效率工具集中入口</p>
                        </div>
                    </div>
                    <div className={`flex items-center gap-2 rounded-xl border px-3 py-2 transition-colors ${
                        searchText ? 'border-[#1677FF]/30 bg-white text-slate-600' : 'border-slate-200 bg-white text-slate-400'
                    }`}>
                        <Search size={15} />
                        <input
                            type="text"
                            className="flex-1 bg-transparent text-xs outline-none placeholder:text-slate-400"
                            placeholder="搜索工具"
                            value={searchText}
                            onChange={e => setSearchText(e.target.value)}
                        />
                        {searchText && (
                            <button onClick={() => setSearchText('')}
                                className="text-slate-400 hover:text-slate-600">
                                ✕
                            </button>
                        )}
                    </div>
                </div>

                <div className="flex-1 space-y-2 overflow-y-auto p-3">
                    {filteredTools.map(tool => {
                        const Icon = tool.icon;
                        const active = tool.key === activeTool;
                        return (
                            <button
                                key={tool.key}
                                onClick={() => handleToolChange(tool.key)}
                                className={`w-full rounded-xl border p-4 text-left transition-all ${
                                    active
                                        ? 'border-red-200 bg-white text-red-600 shadow-sm'
                                        : 'border-transparent bg-transparent text-slate-600 hover:border-slate-200 hover:bg-white'
                                }`}
                            >
                                <div className="flex items-start gap-3">
                                    <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl ${
                                        active ? 'bg-red-50 text-red-600' : 'bg-slate-100 text-slate-500'
                                    }`}>
                                        <Icon size={19} />
                                    </div>
                                    <div className="min-w-0 flex-1">
                                        <div className="flex items-center justify-between gap-2">
                                            <p className="truncate text-sm font-black">{tool.title}</p>
                                            <Sparkles size={14} className={active ? 'text-red-400' : 'text-slate-300'} />
                                        </div>
                                        <p className="mt-1 line-clamp-2 text-xs leading-5 text-slate-500">{tool.description}</p>
                                        <p className="mt-2 text-[10px] font-black uppercase tracking-widest text-slate-400">{tool.status}</p>
                                    </div>
                                </div>
                            </button>
                        );
                    })}
                    {filteredTools.length === 0 && (
                        <div className="py-10 text-center text-xs text-slate-400">未找到匹配的工具</div>
                    )}
                </div>
            </aside>

            <section className="flex min-w-0 flex-1 flex-col bg-white">
                <div className="flex h-16 shrink-0 items-center justify-between border-b border-slate-200 px-5">
                    <div className="flex min-w-0 items-center gap-3">
                        <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-slate-100 text-slate-600">
                            <ActiveIcon size={18} />
                        </div>
                        <div className="min-w-0">
                            <h2 className="truncate text-sm font-black text-slate-900">{activeToolConfig.title}</h2>
                            <p className="truncate text-xs text-slate-500">{activeToolConfig.description}</p>
                        </div>
                    </div>
                    <div className="flex items-center gap-2 rounded-full border border-slate-200 px-3 py-1.5 text-[11px] font-bold text-slate-500">
                        <Wrench size={13} />
                        {activeToolConfig.status}
                    </div>
                </div>

                <div className="min-h-0 flex-1">
                    <ActiveToolComponent />
                </div>
            </section>
        </div>
    );
};

export default ToolsPage;
