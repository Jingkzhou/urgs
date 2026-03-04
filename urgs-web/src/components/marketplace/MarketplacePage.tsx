import React, { useState } from 'react';
import TaskMarket from './TaskMarket';
import WorkList from './WorkList';
import MyTasks from './MyTasks';

const MarketplacePage: React.FC = () => {
    const [activeTab, setActiveTab] = useState<'market' | 'publish' | 'mine'>('market');

    return (
        <div className="h-full flex flex-col gap-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-black text-slate-800 tracking-tight">工作市场</h1>
                    <p className="text-sm text-slate-500 mt-1">认领感兴趣的任务或发布您的工作需求</p>
                </div>

                <div className="flex bg-white rounded-xl p-1 border border-slate-200 shadow-sm">
                    <button
                        onClick={() => setActiveTab('market')}
                        className={`px-6 py-2 rounded-lg text-sm font-bold transition-all ${activeTab === 'market'
                                ? 'bg-red-50 text-red-600 shadow-sm'
                                : 'text-slate-500 hover:text-slate-800'
                            }`}
                    >
                        任务大厅
                    </button>
                    <button
                        onClick={() => setActiveTab('publish')}
                        className={`px-6 py-2 rounded-lg text-sm font-bold transition-all ${activeTab === 'publish'
                                ? 'bg-red-50 text-red-600 shadow-sm'
                                : 'text-slate-500 hover:text-slate-800'
                            }`}
                    >
                        发布工作
                    </button>
                    <button
                        onClick={() => setActiveTab('mine')}
                        className={`px-6 py-2 rounded-lg text-sm font-bold transition-all ${activeTab === 'mine'
                                ? 'bg-red-50 text-red-600 shadow-sm'
                                : 'text-slate-500 hover:text-slate-800'
                            }`}
                    >
                        我的任务
                    </button>
                </div>
            </div>

            <div className="flex-1 bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                {activeTab === 'market' && <TaskMarket />}
                {activeTab === 'publish' && <WorkList />}
                {activeTab === 'mine' && <MyTasks />}
            </div>
        </div>
    );
};

export default MarketplacePage;
