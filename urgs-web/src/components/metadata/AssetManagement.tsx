import React, { useState } from 'react';
import { Code, History, Table2 } from 'lucide-react';
import CodeDirectory from './CodeDirectory';
import MaintenanceRecord from './MaintenanceRecord';
import RegulatoryAssetView from './RegulatoryAssetView';

const AssetManagement: React.FC = () => {
    // Top-level Tabs
    const [activeTab, setActiveTab] = useState<'regulatory' | 'codes' | 'maintenance'>('regulatory');

    return (
        <div className="flex flex-col h-full bg-slate-50 overflow-hidden">
            {/* Top Level Tabs */}
            <div className="flex bg-white border-b border-slate-200 px-4 pt-1 flex-none shadow-sm z-10">
                <button
                    onClick={() => setActiveTab('regulatory')}
                    className={`pb-3 px-4 text-sm font-bold border-b-2 transition-all flex items-center gap-2 ${activeTab === 'regulatory' ? 'border-indigo-600 text-indigo-700' : 'border-transparent text-slate-500 hover:text-slate-700 hover:bg-slate-50 rounded-t-lg'}`}
                >
                    <Table2 size={16} />
                    监管资产
                </button>
                <button
                    onClick={() => setActiveTab('codes')}
                    className={`pb-3 px-4 text-sm font-bold border-b-2 transition-all flex items-center gap-2 ${activeTab === 'codes' ? 'border-indigo-600 text-indigo-700' : 'border-transparent text-slate-500 hover:text-slate-700 hover:bg-slate-50 rounded-t-lg'}`}
                >
                    <Code size={16} />
                    代码目录
                </button>
                <button
                    onClick={() => setActiveTab('maintenance')}
                    className={`pb-3 px-4 text-sm font-bold border-b-2 transition-all flex items-center gap-2 ${activeTab === 'maintenance' ? 'border-indigo-600 text-indigo-700' : 'border-transparent text-slate-500 hover:text-slate-700 hover:bg-slate-50 rounded-t-lg'}`}
                >
                    <History size={16} />
                    维护记录
                </button>
            </div>

            {/* Tab Content Area */}
            <div className="flex-1 overflow-hidden relative">
                {activeTab === 'regulatory' && (
                    <div className="h-full p-4 overflow-hidden">
                        <RegulatoryAssetView />
                    </div>
                )}

                {activeTab === 'codes' && (
                    <div className="h-full p-4 overflow-hidden">
                        <CodeDirectory />
                    </div>
                )}

                {activeTab === 'maintenance' && (
                    <div className="h-full p-4 overflow-hidden">
                        <MaintenanceRecord />
                    </div>
                )}
            </div>

        </div>
    );
};

export default AssetManagement;
