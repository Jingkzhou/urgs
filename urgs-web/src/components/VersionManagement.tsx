import React, { useState, useEffect } from 'react';
import { GitBranch, ShieldCheck, Megaphone, BarChart3, Folder, Terminal, Gauge, ChevronRight, LayoutGrid, Timer, GitPullRequest, Calendar } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { hasPermission } from '../utils/permission';
import AppSystemList from './version/AppSystemList';
import AICodeAudit from './version/AICodeAudit';
import NoticeManagement from './version/NoticeManagement';
import ReleaseStats from './version/ReleaseStats';
import VersionOverview from './version/VersionOverview';
import GitRepoManagement from './version/git-repo/GitRepoManagement';

const VersionManagement: React.FC = () => {
    const [activeTab, setActiveTab] = useState<string>('');

    const TABS = [
        { id: 'app', label: '应用系统', subLabel: 'Applications', icon: LayoutGrid, code: 'version:app:list', component: AppSystemList },
        { id: 'repos', label: '仓库管理', subLabel: 'Repositories', icon: GitBranch, code: 'version:repo:list', component: GitRepoManagement },
        { id: 'code_audit', label: '智能走查', subLabel: 'AI Audit', icon: ShieldCheck, code: 'version:ai:audit', component: AICodeAudit },
        { id: 'notice', label: '公告配置', subLabel: 'Broadcast', icon: Megaphone, code: 'version:notice:config', component: NoticeManagement },
        { id: 'stats', label: '绩效统计', subLabel: 'Metrics', icon: BarChart3, code: 'version:stats', component: ReleaseStats },
    ];

    const visibleTabs = TABS.filter(tab => hasPermission(tab.code));

    useEffect(() => {
        if (!activeTab) {
            setActiveTab('overview');
        }
    }, [activeTab]);

    const allTabs = [
        { id: 'overview', label: '版本概览', subLabel: 'Overview', icon: Gauge, component: VersionOverview },
        ...visibleTabs
    ];

    const ActiveComponent = allTabs.find(tab => tab.id === activeTab)?.component;

    return (
        <div className="flex h-[calc(100vh-120px)] bg-slate-50 rounded-2xl overflow-hidden border border-slate-200 shadow-xl shadow-slate-200/50 font-sans">
            {/* Control Rail (Sidebar) - Light Theme "Lab" Style */}
            <aside className="w-64 bg-white flex flex-col z-20 shadow-[4px_0_24px_rgba(0,0,0,0.02)] border-r border-slate-200 relative overflow-hidden">
                {/* Decorative Grid Line */}
                <div className="absolute inset-0 opacity-[0.03] pointer-events-none"
                    style={{ backgroundImage: 'linear-gradient(#000 1px, transparent 1px), linear-gradient(90deg, #000 1px, transparent 1px)', backgroundSize: '20px 20px' }}>
                </div>

                {/* Header Brand */}
                <div className="h-16 flex items-center px-6 border-b border-slate-100 bg-white/80 backdrop-blur">
                    <div className="w-8 h-8 rounded bg-gradient-to-tr from-indigo-500 to-purple-600 flex items-center justify-center shadow-lg shadow-indigo-500/20 mr-3">
                        <GitBranch className="w-5 h-5 text-white" />
                    </div>
                    <div>
                        <h2 className="text-slate-800 font-bold tracking-tight text-sm">版本控制台</h2>
                        <p className="text-[10px] text-slate-400 font-mono tracking-wider">Release Center</p>
                    </div>
                </div>

                {/* Navigation */}
                <div className="flex-1 py-6 px-3 space-y-1 overflow-y-auto">
                    <div className="px-3 pb-2 text-[10px] font-bold text-slate-400 uppercase tracking-widest flex items-center gap-2">
                        <Terminal size={10} />
                        功能模块
                    </div>

                    {allTabs.map((tab) => {
                        const isActive = activeTab === tab.id;
                        return (
                            <button
                                key={tab.id}
                                onClick={() => setActiveTab(tab.id)}
                                className={`
                                    w-full group relative flex items-center justify-between px-3 py-3 rounded-lg transition-all duration-300 border border-transparent
                                    ${isActive ? 'bg-indigo-50 border-indigo-100 text-indigo-700' : 'hover:bg-slate-50 text-slate-500 hover:text-slate-800'}
                                `}
                            >
                                {/* Active Indicator Bar */}
                                {isActive && (
                                    <motion.div
                                        layoutId="activeRail"
                                        className="absolute left-0 top-0 bottom-0 w-1 bg-indigo-600 rounded-l-lg"
                                        transition={{ type: "spring", stiffness: 300, damping: 30 }}
                                    />
                                )}

                                <div className="flex items-center gap-3 pl-2">
                                    <tab.icon size={18} className={`transition-colors ${isActive ? 'text-indigo-600' : 'text-slate-400 group-hover:text-slate-600'}`} />
                                    <div className="text-left">
                                        <div className={`text-sm font-bold leading-none mb-1 ${isActive ? 'text-indigo-900' : 'text-slate-700'}`}>
                                            {tab.label}
                                        </div>
                                        <div className="text-[10px] opacity-60 font-mono tracking-wide uppercase">
                                            {tab.subLabel}
                                        </div>
                                    </div>
                                </div>

                                {isActive && (
                                    <ChevronRight size={14} className="text-indigo-400" />
                                )}
                            </button>
                        );
                    })}
                </div>

                {/* Footer Status - Release Window */}
                <div className="p-4 border-t border-slate-100 bg-slate-50/50">
                    <div className="flex items-center gap-3 p-3 rounded-lg bg-white border border-slate-200 shadow-sm">
                        <div className="flex items-center justify-center w-8 h-8 rounded-full bg-emerald-50 text-emerald-600">
                            <Calendar size={14} />
                        </div>
                        <div className="flex-1">
                            <p className="text-[10px] uppercase text-slate-400 font-bold mb-0.5">当前窗口</p>
                            <p className="text-xs font-mono text-slate-700 font-bold tracking-wider">每周四 20:00</p>
                        </div>
                    </div>
                </div>
            </aside>

            {/* Main Content Area */}
            <main className="flex-1 flex flex-col min-w-0 bg-[#F8FAFC] relative overflow-hidden">
                {/* Header Ticker */}
                <header className="h-14 bg-white/60 backdrop-blur border-b border-slate-200/60 flex items-center justify-between px-8 z-10 sticky top-0">
                    <div className="flex items-center gap-4">
                        <div className="flex items-center gap-2 text-slate-400">
                            <Folder size={16} />
                            <span className="text-xs font-mono">/</span >
                            <span className="text-xs font-bold uppercase tracking-wider text-slate-500">DevOps</span>
                            <span className="text-xs font-mono">/</span>
                            <span className="text-xs font-bold uppercase tracking-wider text-indigo-600">
                                {allTabs.find(t => t.id === activeTab)?.label || '未知模块'}
                            </span>
                        </div>
                    </div>

                    <div className="flex items-center gap-6">
                        <div className="hidden md:flex items-center gap-4 text-[10px] font-mono text-slate-400">
                            <div className="flex items-center gap-1.5 px-2 py-1 rounded bg-orange-50 border border-orange-100 text-orange-600 font-bold">
                                <Timer size={12} />
                                <span>待发布: 3</span>
                            </div>
                            <div className="w-px h-3 bg-slate-300"></div>
                            <div className="flex items-center gap-1.5 px-2 py-1 rounded bg-blue-50 border border-blue-100 text-blue-600 font-bold">
                                <GitPullRequest size={12} />
                                <span>合并请求: 12</span>
                            </div>
                        </div>
                    </div>
                </header>

                {/* Content Stage */}
                <div className="flex-1 overflow-y-auto overflow-x-hidden p-6 scrollbar-thin scrollbar-thumb-slate-200 scrollbar-track-transparent">
                    <AnimatePresence mode="wait">
                        <motion.div
                            key={activeTab}
                            initial={{ opacity: 0, y: 10, scale: 0.99 }}
                            animate={{ opacity: 1, y: 0, scale: 1 }}
                            exit={{ opacity: 0, y: -10, scale: 0.99 }}
                            transition={{ duration: 0.25, ease: [0.22, 1, 0.36, 1] }}
                            className="h-full"
                        >
                            {ActiveComponent ? <ActiveComponent /> : (
                                <div className="h-full flex flex-col items-center justify-center text-slate-400">
                                    <div className="w-16 h-16 rounded-2xl bg-white flex items-center justify-center mb-4 border border-slate-200 border-dashed shadow-sm">
                                        <ShieldCheck size={32} className="opacity-30" />
                                    </div>
                                    <p className="text-sm font-bold text-slate-500">该区域访问受限</p>
                                </div>
                            )}
                        </motion.div>
                    </AnimatePresence>
                </div>
            </main>
        </div>
    );
};

export default VersionManagement;
