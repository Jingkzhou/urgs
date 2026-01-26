import React, { useState } from 'react';
import { Megaphone, Plus, List, TrendingUp, AlertCircle, TrendingDown, BellRing } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import AnnouncementList from './AnnouncementList';
import PublishAnnouncement from './PublishAnnouncement';
import { hasPermission } from '../../utils/permission';
import Auth from '../Auth';

// --- Sub-components & Types ---

interface StatCardProps {
    icon: React.ElementType;
    iconColor: string;
    iconBg: string;
    label: string;
    value: string | number;
    trend?: 'up' | 'down' | 'neutral';
    trendValue?: string;
}

const StatCard: React.FC<StatCardProps> = ({ icon: Icon, iconColor, iconBg, label, value, trend, trendValue }) => (
    <motion.div
        whileHover={{ y: -2 }}
        className="hidden lg:flex items-center gap-4 px-6 py-4 bg-white/80 backdrop-blur-md rounded-2xl border border-white/20 shadow-sm hover:shadow-md transition-all duration-300"
    >
        <div className={`w-12 h-12 rounded-xl ${iconBg} flex items-center justify-center ${iconColor} shadow-inner`}>
            <Icon size={22} className="stroke-[2.5px]" />
        </div>
        <div>
            <p className="text-[11px] font-bold text-slate-400 uppercase tracking-wider mb-0.5">{label}</p>
            <div className="flex items-end gap-2">
                <p className="text-xl font-black text-slate-800 leading-none tracking-tight">{value}</p>
                {trend && (
                    <div className={`flex items-center text-[10px] font-bold ${trend === 'up' ? 'text-emerald-500' : 'text-rose-500'}`}>
                        {trend === 'up' ? <TrendingUp size={12} className="mr-0.5" /> : <TrendingDown size={12} className="mr-0.5" />}
                        {trendValue}
                    </div>
                )}
            </div>
        </div>
    </motion.div>
);

// --- Main Component ---

const AnnouncementManagement: React.FC = () => {
    const canList = hasPermission('announcement:list');
    const canPublish = hasPermission('announcement:publish');

    // Initialize active tab based on permissions
    const getInitialTab = () => {
        if (canList) return 'list';
        if (canPublish) return 'publish';
        return 'list';
    };

    const [activeTab, setActiveTab] = useState<'list' | 'publish'>(getInitialTab());
    const [editId, setEditId] = useState<string | null>(null);

    const handleEdit = (id: string) => {
        setEditId(id);
        setActiveTab('publish');
    };

    const handlePublishSuccess = () => {
        setEditId(null);
        setActiveTab('list');
    };

    const handleTabChange = (key: 'list' | 'publish') => {
        setActiveTab(key);
        if (key === 'list') setEditId(null);
    };

    // No permission view
    if (!canList && !canPublish) {
        return (
            <div className="flex flex-col items-center justify-center min-h-[60vh]">
                <div className="p-8 bg-slate-50 rounded-3xl border border-dashed border-slate-200 text-center max-w-md mx-auto">
                    <div className="w-20 h-20 mx-auto rounded-full bg-slate-100 flex items-center justify-center mb-6 shadow-inner">
                        <Megaphone className="w-8 h-8 text-slate-300" />
                    </div>
                    <h3 className="text-xl font-bold text-slate-700 mb-2">暂无访问权限</h3>
                    <p className="text-slate-400 leading-relaxed">
                        您当前没有查看公告管理的权限。<br />
                        如需访问，请联系管理员为您添加以下权限：<br />
                        <code className="text-xs bg-slate-100 px-2 py-1 rounded mt-2 inline-block text-slate-500 font-mono">announcement:list</code>
                    </p>
                </div>
            </div>
        );
    }

    const tabs = [
        { key: 'list' as const, label: '公告列表', icon: List, permission: 'announcement:list' },
        { key: 'publish' as const, label: editId ? '编辑公告' : '发布公告', icon: Plus, permission: 'announcement:publish' },
    ];

    return (
        <div className="space-y-8 animate-fade-in max-w-[1600px] mx-auto p-1">
            {/* Header Section */}
            <header className="flex flex-col md:flex-row md:items-end justify-between gap-6 pb-2">
                <div className="space-y-2">
                    <motion.div
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        className="flex items-center gap-2"
                    >
                        <span className="px-2.5 py-0.5 rounded-full bg-violet-100 text-violet-600 text-[10px] font-extrabold uppercase tracking-widest border border-violet-200/50">
                            Management
                        </span>
                    </motion.div>
                    <h1 className="text-4xl font-black text-slate-800 tracking-tight">
                        公告管理
                        <span className="text-violet-500 ml-1">.</span>
                    </h1>
                    <p className="text-slate-500 font-medium max-w-xl text-lg">
                        发布重要通知，同步监管政策，连接每一位关注者。
                    </p>
                </div>

                {/* Quick Stats Dashboard */}
                <div className="flex gap-4">
                    <StatCard
                        icon={TrendingUp}
                        iconColor="text-violet-600"
                        iconBg="bg-violet-50"
                        label="本月发布"
                        value="24"
                        trend="up"
                        trendValue="+12%"
                    />
                    <StatCard
                        icon={AlertCircle}
                        iconColor="text-rose-600"
                        iconBg="bg-rose-50"
                        label="紧急通知"
                        value="3"
                    />
                    <StatCard
                        icon={BellRing}
                        iconColor="text-amber-500"
                        iconBg="bg-amber-50"
                        label="待审核"
                        value="5"
                    />
                </div>
            </header>

            {/* Main Content Area */}
            <div className="space-y-6">
                {/* Navigation & Toolbar */}
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 sticky top-0 z-30 py-2 bg-gradient-to-b from-[#f8fafc] to-[#f8fafc]/90 backdrop-blur-sm -mx-4 px-4 lg:static lg:bg-none lg:p-0 lg:m-0">

                    {/* Tabs */}
                    <div className="inline-flex bg-white p-1.5 rounded-2xl shadow-sm border border-slate-100 ring-1 ring-slate-100/50">
                        {tabs.map(tab => (
                            <Auth key={tab.key} code={tab.permission}>
                                <button
                                    onClick={() => handleTabChange(tab.key)}
                                    className={`relative px-6 py-2.5 rounded-xl text-sm font-bold transition-all duration-300 flex items-center gap-2 z-10 select-none ${activeTab === tab.key
                                            ? 'text-violet-700'
                                            : 'text-slate-500 hover:text-slate-700'
                                        }`}
                                >
                                    {activeTab === tab.key && (
                                        <motion.div
                                            layoutId="activeTab"
                                            className="absolute inset-0 bg-violet-50 rounded-xl"
                                            initial={false}
                                            transition={{ type: "spring", stiffness: 300, damping: 30 }}
                                            style={{ zIndex: -1 }}
                                        />
                                    )}
                                    <tab.icon size={16} strokeWidth={activeTab === tab.key ? 2.5 : 2} />
                                    {tab.label}
                                </button>
                            </Auth>
                        ))}
                    </div>

                    {/* Quick Action */}
                    <Auth code="announcement:publish">
                        <AnimatePresence>
                            {activeTab === 'list' && (
                                <motion.div
                                    initial={{ opacity: 0, scale: 0.9, x: 20 }}
                                    animate={{ opacity: 1, scale: 1, x: 0 }}
                                    exit={{ opacity: 0, scale: 0.9, x: 20 }}
                                >
                                    <motion.button
                                        whileHover={{ scale: 1.02, boxShadow: "0 10px 25px -5px rgba(124, 58, 237, 0.3)" }}
                                        whileTap={{ scale: 0.98 }}
                                        onClick={() => handleTabChange('publish')}
                                        className="flex items-center gap-2 px-6 py-3 bg-violet-600 text-white rounded-xl font-bold shadow-lg shadow-violet-200 hover:bg-violet-700 transition-all"
                                    >
                                        <Plus size={18} strokeWidth={2.5} />
                                        <span className="text-sm">快速发布</span>
                                    </motion.button>
                                </motion.div>
                            )}
                        </AnimatePresence>
                    </Auth>
                </div>

                {/* Content Panel */}
                <div className="relative min-h-[500px]">
                    <AnimatePresence mode="wait">
                        <motion.div
                            key={activeTab}
                            initial={{ opacity: 0, y: 15, filter: 'blur(5px)' }}
                            animate={{ opacity: 1, y: 0, filter: 'blur(0px)' }}
                            exit={{ opacity: 0, y: -15, filter: 'blur(5px)' }}
                            transition={{ duration: 0.3, ease: 'easeOut' }}
                            className="bg-white rounded-[2rem] border border-slate-100 shadow-xl shadow-slate-200/40 p-1 overflow-hidden"
                        >
                            {activeTab === 'list' && canList && (
                                <div className="p-6">
                                    <AnnouncementList onEdit={handleEdit} />
                                </div>
                            )}
                            {activeTab === 'publish' && canPublish && (
                                <div className="p-6">
                                    <PublishAnnouncement editId={editId} onSuccess={handlePublishSuccess} />
                                </div>
                            )}
                        </motion.div>
                    </AnimatePresence>
                </div>
            </div>
        </div>
    );
};

export default AnnouncementManagement;
