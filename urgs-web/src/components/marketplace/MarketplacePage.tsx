import React, { useEffect, useMemo, useState } from 'react';
import TaskMarket from './TaskMarket';
import WorkList from './WorkList';
import MyTasks from './MyTasks';
import StatsPage from './StatsPage';
import ReviewCenter from './ReviewCenter';
import PointRuleConfig from './PointRuleConfig';
import MarketplaceTodoPanel from './MarketplaceTodoPanel';
import { hasPermission } from '../../utils/permission';

type MarketplaceTab = 'market' | 'publish' | 'mine' | 'review' | 'stats' | 'rules';

const MARKETPLACE_TABS: Array<{
    id: MarketplaceTab;
    label: string;
    permission: string;
    component: React.ReactNode;
}> = [
    { id: 'market', label: '任务大厅', permission: 'marketplace:market', component: <TaskMarket /> },
    { id: 'publish', label: '发布工作', permission: 'marketplace:publish', component: <WorkList /> },
    { id: 'mine', label: '个人看板', permission: 'marketplace:mine', component: <MyTasks /> },
    { id: 'stats', label: 'KPI 看板', permission: 'marketplace:stats', component: <StatsPage /> },
    { id: 'review', label: '验收中心', permission: 'marketplace:review', component: <ReviewCenter /> },
    { id: 'rules', label: '规则配置', permission: 'marketplace:rules', component: <PointRuleConfig /> },
];

const MarketplacePage: React.FC = () => {
    const [activeTab, setActiveTab] = useState<MarketplaceTab>('market');
    const visibleTabs = useMemo(
        () => MARKETPLACE_TABS.filter(tab => hasPermission(tab.permission)),
        []
    );
    const activeTabConfig = visibleTabs.find(tab => tab.id === activeTab);

    useEffect(() => {
        if (!activeTabConfig && visibleTabs.length > 0) {
            setActiveTab(visibleTabs[0].id);
        }
    }, [activeTabConfig, visibleTabs]);

    const handleSelectTab = (tab: string) => {
        if (visibleTabs.some(item => item.id === tab)) {
            setActiveTab(tab as MarketplaceTab);
        }
    };

    return (
        <div className="h-full flex flex-col gap-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-black text-slate-800 tracking-tight">任务中心</h1>
                    <p className="text-sm text-slate-500 mt-1">认领感兴趣的任务或发布您的工作需求</p>
                </div>

                {visibleTabs.length > 0 && (
                    <div className="flex bg-white rounded-xl p-1 border border-slate-200 shadow-sm">
                        {visibleTabs.map(tab => (
                            <button
                                key={tab.id}
                                onClick={() => setActiveTab(tab.id)}
                                className={`px-6 py-2 rounded-lg text-sm font-bold transition-all ${activeTab === tab.id
                                        ? 'bg-red-50 text-red-600 shadow-sm'
                                        : 'text-slate-500 hover:text-slate-800'
                                    }`}
                            >
                                {tab.label}
                            </button>
                        ))}
                    </div>
                )}
            </div>

            {visibleTabs.length > 0 && <MarketplaceTodoPanel onSelectTab={handleSelectTab} />}

            <div className="flex-1 bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                {activeTabConfig?.component ?? (
                    <div className="flex h-full items-center justify-center text-sm text-slate-400">
                        暂无任务中心模块权限
                    </div>
                )}
            </div>
        </div>
    );
};

export default MarketplacePage;
