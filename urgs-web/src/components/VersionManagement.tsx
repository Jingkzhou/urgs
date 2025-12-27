import React, { useState, useEffect } from 'react';
import { GitBranch, Server, ClipboardList, ShieldCheck, Megaphone, BarChart3, Layers, MenuSquare, Settings, Folder, Workflow, Rocket } from 'lucide-react';
import { hasPermission } from '../utils/permission';
import AppSystemList from './version/AppSystemList';
import ReleaseLedger from './version/ReleaseLedger';
import AICodeAudit from './version/AICodeAudit';
import NoticeManagement from './version/NoticeManagement';
import ReleaseStats from './version/ReleaseStats';
import VersionOverview from './version/VersionOverview';
import GitRepoManagement from './version/GitRepoManagement';

const VersionManagement: React.FC = () => {
    const [activeTab, setActiveTab] = useState<string>('');

    const TABS = [
        { id: 'app', label: '应用系统库', icon: Server, code: 'version:app:list', component: AppSystemList },
        { id: 'repos', label: 'Git 仓库管理', icon: GitBranch, code: 'version:repo:list', component: GitRepoManagement },
        { id: 'code_audit', label: 'AI 代码走查', icon: ShieldCheck, code: 'version:audit:view', component: AICodeAudit },
        { id: 'notice', label: '业务公告管理', icon: Megaphone, code: 'version:notice:config', component: NoticeManagement },
        { id: 'stats', label: '绩效统计', icon: BarChart3, code: 'version:stats', component: ReleaseStats },
    ];

    const visibleTabs = TABS.filter(tab => hasPermission(tab.code));

    useEffect(() => {
        if (!activeTab) {
            setActiveTab('overview'); // 默认显示版本概览
        }
    }, [activeTab]);

    // 合并所有可点击的菜单项
    const allTabs = [
        { id: 'overview', label: '版本概览', icon: Folder, component: VersionOverview },
        ...visibleTabs
    ];

    const ActiveComponent = allTabs.find(tab => tab.id === activeTab)?.component;

    const sections = [
        {
            title: '项目概览',
            items: [{ id: 'overview', label: '版本概览', icon: Folder, component: VersionOverview }],
        },
        {
            title: '版本管理',
            items: visibleTabs.map(tab => ({ id: tab.id, label: tab.label, icon: tab.icon, code: tab.code })),
        },
        {
            title: 'RESOURCES',
            items: [{ id: 'config', label: '配置中心', icon: Settings, disabled: true }],
        },
    ];

    return (
        <div className="flex gap-4 animate-fade-in">
            {/* Left rail */}
            <aside className="w-64 bg-white border border-slate-200 rounded-xl shadow-sm">
                <div className="px-4 py-5 border-b border-slate-100 flex items-center gap-2">
                    <div className="w-9 h-9 rounded-lg bg-blue-100 flex items-center justify-center">
                        <GitBranch className="w-5 h-5 text-blue-600" />
                    </div>
                    <div>
                        <p className="text-sm font-semibold text-slate-900">版本管理</p>
                        <p className="text-xs text-slate-400">Version Console</p>
                    </div>
                </div>
                <div className="p-4 space-y-6">
                    {sections.map(section => (
                        <div key={section.title} className="space-y-2">
                            <p className="text-[11px] font-semibold text-slate-400 uppercase tracking-wide">{section.title}</p>
                            <div className="space-y-1">
                                {section.items.map(item => {
                                    const Icon = item.icon || Layers;
                                    const isActive = activeTab === item.id;
                                    const isDisabled = item.disabled || (!item.code && !item.component);
                                    const isAi = item.id === 'ai';
                                    // Only render permission-guarded items the user can see
                                    if (item.code && !hasPermission(item.code)) return null;
                                    return (
                                        <button
                                            key={item.id}
                                            disabled={isDisabled}
                                            onClick={() => !isDisabled && setActiveTab(item.id)}
                                            className={`
                                                w-full flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-all
                                                ${isActive
                                                    ? isAi
                                                        ? 'bg-gradient-to-r from-purple-50 via-indigo-50 to-blue-50 text-indigo-700'
                                                        : 'bg-blue-50 text-blue-700'
                                                    : 'text-slate-700 hover:bg-slate-50'}
                                                ${isDisabled ? 'opacity-50 cursor-not-allowed' : ''}
                                                ${isAi ? 'border border-indigo-100' : ''}
                                            `}
                                        >
                                            <Icon size={16} className={`${isActive ? 'text-indigo-600' : isAi ? 'text-indigo-500' : 'text-slate-500'}`} />
                                            <span>{item.label}</span>
                                            {isAi && (
                                                <span className="ml-auto text-[10px] px-2 py-0.5 rounded-full bg-gradient-to-r from-indigo-500 to-purple-500 text-white font-semibold shadow-sm">
                                                    AI
                                                </span>
                                            )}
                                        </button>
                                    );
                                })}
                            </div>
                        </div>
                    ))}
                </div>
            </aside>

            {/* Main content */}
            <div className="flex-1 bg-white rounded-xl shadow-sm border border-slate-200 p-6">


                <div className="min-h-[420px]">
                    {ActiveComponent ? <ActiveComponent /> : (
                        <div className="text-center py-16 text-slate-500">
                            暂无权限或未选择模块
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};

export default VersionManagement;
