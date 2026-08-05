import React, { useState, useEffect } from 'react';
import { Database, Search, GitBranch } from 'lucide-react';
import AssetManagement from './metadata/AssetManagement';
import MetadataModel from './metadata/MetadataModel';
import SqlConsole from './SqlConsole';
import LineageAnalysisPage from './metadata/Lineage/analysis';
import Auth from './Auth';

const MetadataManagement: React.FC = () => {
    const [activeTab, setActiveTab] = useState<'asset' | 'model' | 'code' | 'maintenance' | 'query' | 'lineage'>('asset');

    useEffect(() => {
        const handleHashChange = () => {
            const hash = window.location.hash;
            if (hash.includes('?')) {
                const params = new URLSearchParams(hash.split('?')[1]);
                const subtab = params.get('subtab');
                if (subtab === 'lineage-origin' || subtab === 'lineage-analysis') {
                    setActiveTab('lineage');
                    return;
                }
                if (subtab && ['asset', 'model', 'code', 'maintenance', 'query', 'lineage'].includes(subtab)) {
                    setActiveTab(subtab as any);
                }
            }
        };

        handleHashChange(); // Check on mount
        window.addEventListener('hashchange', handleHashChange);
        return () => window.removeEventListener('hashchange', handleHashChange);
    }, []);

    const tabs = [
        { id: 'asset', label: '资产管理', icon: Database, code: 'metadata:asset', component: <AssetManagement /> },
        { id: 'model', label: '物理模型', icon: Database, code: 'metadata:model', component: <MetadataModel /> },
        { id: 'lineage', label: '血缘模块', icon: GitBranch, code: 'metadata:lineage', component: <LineageAnalysisPage /> },
        { id: 'query', label: '数据查询', icon: Search, code: 'metadata:query', component: <SqlConsole /> },
    ];

    return (
        <div className="flex h-full min-h-[720px] min-w-0 w-full max-w-[1600px] mx-auto animate-fade-in flex-col gap-6 px-2">
            {/* Header & Navigation */}
            <div className="flex min-w-0 w-full flex-col md:flex-row md:items-end md:justify-between gap-6 pb-6 border-b border-slate-200/60">
                <div className="min-w-0 shrink-0">
                    <h1 className="text-3xl font-bold text-slate-900 tracking-tight flex items-center gap-3">
                        数据管理
                    </h1>
                    <p className="text-slate-500 mt-2 font-medium">
                        统一管理全行监管技术元数据与业务资产
                    </p>
                </div>

                <div className="flex min-w-0 max-w-full shrink items-center gap-1 overflow-x-auto rounded-xl bg-slate-100/80 p-1.5 backdrop-blur-sm shadow-inner md:ml-6 md:flex-1 md:justify-end">
                    {tabs.map((tab) => (
                        <Auth key={tab.id} code={tab.code}>
                            <button
                                onClick={() => setActiveTab(tab.id as any)}
                                className={`
                                    flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold transition-all duration-200 whitespace-nowrap
                                    ${activeTab === tab.id
                                        ? 'bg-white text-slate-900 shadow-sm shadow-slate-200 scale-[1.02]'
                                        : 'text-slate-500 hover:text-slate-700 hover:bg-slate-200/50'
                                    }
                                `}
                            >
                                <tab.icon
                                    size={16}
                                    strokeWidth={2.5}
                                    className={`transition-colors ${activeTab === tab.id ? 'text-red-500' : 'text-slate-400'}`}
                                />
                                <span>{tab.label}</span>
                            </button>
                        </Auth>
                    ))}
                </div>
            </div>

            {/* Content Area */}
            <div className="relative min-h-0 min-w-0 flex-1 overflow-hidden rounded-2xl border border-slate-200/60 bg-white p-6 shadow-sm">
                {tabs.map(tab => (
                    activeTab === tab.id && (
                        <div key={tab.id} className="h-full min-h-0 min-w-0 animate-in fade-in zoom-in-95 duration-200">
                            <Auth code={tab.code}>
                                {tab.component}
                            </Auth>
                        </div>
                    )
                ))}
            </div>
        </div>
    );
};

export default MetadataManagement;
