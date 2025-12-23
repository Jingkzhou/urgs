import React, { useState, useEffect } from 'react';
import { Database, FileText, History, Search, Share2, GitBranch, GitMerge } from 'lucide-react';
import AssetManagement from './metadata/AssetManagement';
import MetadataModel from './metadata/MetadataModel';
import CodeDirectory from './metadata/CodeDirectory';
import MaintenanceRecord from './metadata/MaintenanceRecord';
import SqlConsole from './SqlConsole';
import LineageOriginPage from './metadata/Lineage/origin';
import LineageAnalysisPage from './metadata/Lineage/analysis';
import Auth from './Auth';

const MetadataManagement: React.FC = () => {
    const [activeTab, setActiveTab] = useState<'asset' | 'model' | 'code' | 'maintenance' | 'query' | 'lineage-origin' | 'lineage-analysis'>('asset');

    useEffect(() => {
        const handleHashChange = () => {
            const hash = window.location.hash;
            if (hash.includes('?')) {
                const params = new URLSearchParams(hash.split('?')[1]);
                const subtab = params.get('subtab');
                if (subtab && ['asset', 'model', 'code', 'maintenance', 'query', 'lineage-origin', 'lineage-analysis'].includes(subtab)) {
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
        { id: 'lineage-origin', label: '血缘溯源', icon: GitMerge, code: 'metadata:lineage:origin', component: <LineageOriginPage mode="trace" /> },
        { id: 'lineage-analysis', label: '影响分析', icon: GitBranch, code: 'metadata:lineage:analysis', component: <LineageAnalysisPage mode="impact" /> },
        { id: 'code', label: '代码目录', icon: FileText, code: 'metadata:code', component: <CodeDirectory /> },
        { id: 'maintenance', label: '维护记录', icon: History, code: 'metadata:maintenance', component: <MaintenanceRecord /> },
        { id: 'query', label: '数据查询', icon: Search, code: 'metadata:query', component: <SqlConsole /> },
    ];

    return (
        <div className="space-y-6 animate-fade-in px-2 max-w-[1600px] mx-auto">
            {/* Header & Navigation */}
            <div className="flex flex-col md:flex-row justify-between items-end gap-6 pb-6 border-b border-slate-200/60">
                <div>
                    <h1 className="text-3xl font-bold text-slate-900 tracking-tight flex items-center gap-3">
                        数据管理
                    </h1>
                    <p className="text-slate-500 mt-2 font-medium">
                        统一管理全行监管技术元数据与业务资产
                    </p>
                </div>

                <div className="bg-slate-100/80 p-1.5 rounded-xl flex items-center gap-1 overflow-x-auto max-w-full backdrop-blur-sm shadow-inner">
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
            <div className="bg-white rounded-2xl border border-slate-200/60 shadow-sm min-h-[600px] relative overflow-hidden p-6">
                {tabs.map(tab => (
                    activeTab === tab.id && (
                        <div key={tab.id} className="animate-in fade-in zoom-in-95 duration-200 h-full">
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
