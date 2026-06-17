import React, { useEffect, useState } from 'react';
import { FileText, Wrench } from 'lucide-react';
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

    const activeToolConfig = tools.find(tool => tool.key === activeTool) || tools[0];

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
        <div className="flex h-full min-h-0 flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
            <section className="flex h-14 shrink-0 items-center justify-between border-b border-slate-100 px-5">
                <div className="flex min-w-0 items-center gap-3">
                    <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-[#E6F4FF] text-[#1677FF]">
                        <Wrench size={17} />
                    </div>
                    <div className="min-w-0">
                        <div className="flex items-center gap-2">
                            <h1 className="truncate text-base font-bold text-slate-950">工具箱</h1>
                            <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-medium text-slate-500">
                                在线文档工作台
                            </span>
                        </div>
                        <p className="truncate text-xs text-slate-500">文档创建、上传、授权与最近访问统一入口</p>
                    </div>
                </div>

                <div className="hidden items-center gap-2 md:flex">
                    {tools.map(tool => {
                        const Icon = tool.icon;
                        const active = tool.key === activeTool;
                        return (
                            <button
                                key={tool.key}
                                onClick={() => handleToolChange(tool.key)}
                                className={`flex items-center gap-2 rounded-lg border px-3 py-2 text-left transition-all ${
                                    active
                                        ? 'border-[#1677FF]/30 bg-[#E6F4FF] text-[#1677FF] shadow-sm'
                                        : 'border-slate-200 bg-white text-slate-600 hover:border-slate-300 hover:bg-slate-50'
                                }`}
                            >
                                <span className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-md ${
                                    active ? 'bg-white text-[#1677FF]' : 'bg-slate-100 text-slate-500'
                                }`}>
                                    <Icon size={15} />
                                </span>
                                <span className="min-w-0 flex-1">
                                    <span className="block truncate text-sm font-bold">{tool.title}</span>
                                    <span className="block truncate text-[11px] text-slate-500">{tool.status}</span>
                                </span>
                            </button>
                        );
                    })}
                </div>
            </section>

            <section className="flex min-h-0 flex-1 flex-col overflow-hidden bg-white">
                <div className="min-h-0 flex-1">
                    <ActiveToolComponent />
                </div>
            </section>
        </div>
    );
};

export default ToolsPage;
