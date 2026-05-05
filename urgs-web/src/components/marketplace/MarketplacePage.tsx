import React, { useState } from 'react';
import TaskMarket from './TaskMarket';
import WorkList from './WorkList';
import MyTasks from './MyTasks';
import StatsPage from './StatsPage';
import ReviewCenter from './ReviewCenter';
import PointRuleConfig from './PointRuleConfig';
import MarketplaceTodoPanel from './MarketplaceTodoPanel';

type MarketplaceTab = 'market' | 'publish' | 'mine' | 'review' | 'stats' | 'rules';

const MarketplacePage: React.FC = () => {
    const [activeTab, setActiveTab] = useState<MarketplaceTab>('market');

    const handleSelectTab = (tab: string) => {
        if (['market', 'publish', 'mine', 'review', 'stats', 'rules'].includes(tab)) {
            setActiveTab(tab as MarketplaceTab);
        }
    };

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
                        个人看板
                    </button>
                    <button
                        onClick={() => setActiveTab('stats')}
                        className={`px-6 py-2 rounded-lg text-sm font-bold transition-all ${activeTab === 'stats'
                                ? 'bg-red-50 text-red-600 shadow-sm'
                                : 'text-slate-500 hover:text-slate-800'
                            }`}
                    >
                        KPI 看板
                    </button>
                    <button
                        onClick={() => setActiveTab('review')}
                        className={`px-6 py-2 rounded-lg text-sm font-bold transition-all ${activeTab === 'review'
                                ? 'bg-red-50 text-red-600 shadow-sm'
                                : 'text-slate-500 hover:text-slate-800'
                            }`}
                    >
                        验收中心
                    </button>
                    <button
                        onClick={() => setActiveTab('rules')}
                        className={`px-6 py-2 rounded-lg text-sm font-bold transition-all ${activeTab === 'rules'
                                ? 'bg-red-50 text-red-600 shadow-sm'
                                : 'text-slate-500 hover:text-slate-800'
                            }`}
                    >
                        规则配置
                    </button>
                </div>
            </div>

            <MarketplaceTodoPanel onSelectTab={handleSelectTab} />

            <div className="flex-1 bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                {activeTab === 'market' && <TaskMarket />}
                {activeTab === 'publish' && <WorkList />}
                {activeTab === 'mine' && <MyTasks />}
                {activeTab === 'review' && <ReviewCenter />}
                {activeTab === 'stats' && <StatsPage />}
                {activeTab === 'rules' && <PointRuleConfig />}
            </div>
        </div>
    );
};

export default MarketplacePage;
