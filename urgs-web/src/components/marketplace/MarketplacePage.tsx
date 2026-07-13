import React, { useEffect, useMemo, useState } from 'react';
import TaskMarket from './TaskMarket';
import WorkList from './WorkList';
import MyTasks from './MyTasks';
import StatsPage from './StatsPage';
import ReviewCenter from './ReviewCenter';
import PointRuleConfig from './PointRuleConfig';
import MarketplaceTodoPanel from './MarketplaceTodoPanel';
import { MarketplaceTodo } from '../../api/marketplace';
import { hasPermission } from '../../utils/permission';
import { MarketplaceTodoFocus } from './marketplaceTodoFocus';

type MarketplaceTab = 'market' | 'publish' | 'mine' | 'review' | 'stats' | 'rules';

const MARKETPLACE_TABS: Array<{
    id: MarketplaceTab;
    label: string;
    permission: string;
}> = [
    { id: 'market', label: '任务大厅', permission: 'marketplace:market' },
    { id: 'publish', label: '发布工作', permission: 'marketplace:publish' },
    { id: 'mine', label: '个人看板', permission: 'marketplace:mine' },
    { id: 'stats', label: 'KPI 看板', permission: 'marketplace:stats' },
    { id: 'review', label: '验收中心', permission: 'marketplace:review' },
    { id: 'rules', label: '规则配置', permission: 'marketplace:rules' },
];

const MarketplacePage: React.FC = () => {
    const [activeTab, setActiveTab] = useState<MarketplaceTab>('market');
    const [todoFocus, setTodoFocus] = useState<MarketplaceTodoFocus | null>(null);
    const visibleTabs = useMemo(
        () => MARKETPLACE_TABS.filter(tab => hasPermission(tab.permission)),
        []
    );
    const activeTabConfig = visibleTabs.find(tab => tab.id === activeTab);

    useEffect(() => {
        const syncTabFromHash = () => {
            const query = window.location.hash.includes('?') ? window.location.hash.split('?')[1] : '';
            const requestedTab = new URLSearchParams(query).get('tab') as MarketplaceTab | null;
            if (requestedTab && visibleTabs.some(tab => tab.id === requestedTab)) {
                setActiveTab(requestedTab);
            }
        };

        syncTabFromHash();
        window.addEventListener('hashchange', syncTabFromHash);
        return () => window.removeEventListener('hashchange', syncTabFromHash);
    }, [visibleTabs]);

    useEffect(() => {
        if (!activeTabConfig && visibleTabs.length > 0) {
            setActiveTab(visibleTabs[0].id);
        }
    }, [activeTabConfig, visibleTabs]);

    const handleSelectTodo = (todo: MarketplaceTodo) => {
        if (visibleTabs.some(item => item.id === todo.targetTab)) {
            setActiveTab(todo.targetTab as MarketplaceTab);
            setTodoFocus({
                type: todo.type,
                title: todo.title,
                count: todo.count,
                targetTab: todo.targetTab,
                targetTaskId: todo.targetTaskId,
                targetWorkId: todo.targetWorkId,
                sequence: Date.now(),
            });
        }
    };

    const currentTabFocus = todoFocus?.targetTab === activeTab ? todoFocus : null;

    const renderActiveTab = () => {
        switch (activeTab) {
            case 'market':
                return <TaskMarket />;
            case 'publish':
                return <WorkList todoFocus={currentTabFocus} />;
            case 'mine':
                return <MyTasks todoFocus={currentTabFocus} />;
            case 'stats':
                return <StatsPage />;
            case 'review':
                return <ReviewCenter todoFocus={currentTabFocus} />;
            case 'rules':
                return <PointRuleConfig />;
            default:
                return null;
        }
    };

    return (
        <div className="h-full flex flex-col gap-6">
            <div className="flex flex-col gap-4 xl:flex-row xl:items-center xl:justify-between">
                <div>
                    <h1 className="text-2xl font-black text-slate-800 tracking-tight">任务中心</h1>
                    <p className="text-sm text-slate-500 mt-1">认领感兴趣的任务或发布您的工作需求</p>
                </div>

                {visibleTabs.length > 0 && (
                    <div className="flex flex-wrap items-center gap-3 xl:justify-end">
                        <MarketplaceTodoPanel onSelectTodo={handleSelectTodo} />

                        <div className="flex overflow-x-auto bg-white rounded-xl p-1 border border-slate-200 shadow-sm">
                            {visibleTabs.map(tab => (
                                <button
                                    key={tab.id}
                                    onClick={() => setActiveTab(tab.id)}
                                    className={`whitespace-nowrap px-5 py-2 rounded-lg text-sm font-bold transition-all ${activeTab === tab.id
                                            ? 'bg-red-50 text-red-600 shadow-sm'
                                            : 'text-slate-500 hover:text-slate-800'
                                        }`}
                                >
                                    {tab.label}
                                </button>
                            ))}
                        </div>
                    </div>
                )}
            </div>

            <div className="flex-1 bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                {activeTabConfig ? renderActiveTab() : (
                    <div className="flex h-full items-center justify-center text-sm text-slate-400">
                        暂无任务中心模块权限
                    </div>
                )}
            </div>
        </div>
    );
};

export default MarketplacePage;
