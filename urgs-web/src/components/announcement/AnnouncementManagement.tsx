import React, { useState, useEffect } from 'react';
import { Megaphone, Plus, List, TrendingUp, AlertCircle, TrendingDown, BellRing, FileText } from 'lucide-react';
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
    const canLog = hasPermission('announcement:log');
    const canPublish = hasPermission('announcement:publish');

    // Initialize active tab based on permissions
    const getInitialTab = () => {
        if (canList) return 'list';
        if (canLog) return 'log';
        if (canPublish) return 'publish';
        return 'list';
    };

    const [activeTab, setActiveTab] = useState<'list' | 'log' | 'publish'>(getInitialTab());
    const [editId, setEditId] = useState<string | null>(null);
    const [publishCategoryIntent, setPublishCategoryIntent] = useState<'Announcement' | 'Log'>('Announcement');
    const [initialSelectedId, setInitialSelectedId] = useState<string | null>(null);
    const [stats, setStats] = useState({
        monthlyCount: 0,
        urgentCount: 0,
        pendingCount: 0
    });

    const fetchStats = async () => {
        try {
            const token = localStorage.getItem('auth_token');
            const userStr = localStorage.getItem('auth_user');
            let systems = '';
            let userId = 'admin';
            if (userStr) {
                const user = JSON.parse(userStr);
                systems = user.system || '';
                userId = user.empId || 'admin';
            }

            const res = await fetch('/api/announcement/stats', {
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'X-User-Id': encodeURIComponent(userId),
                    'X-User-Systems': encodeURIComponent(systems)
                }
            });
            if (res.ok) {
                const data = await res.json();
                setStats(data);
            }
        } catch (err) {
            console.error("Failed to fetch announcement stats", err);
        }
    };

    // Read navigation params from sessionStorage (one-time, not persisted in URL)
    useEffect(() => {
        const navData = sessionStorage.getItem('announcement_nav');
        if (navData) {
            sessionStorage.removeItem('announcement_nav');
            try {
                const { id, type } = JSON.parse(navData);
                if (id) {
                    setInitialSelectedId(id);
                    setActiveTab(type === 'log' ? 'log' : 'list');
                } else if (type === 'log') {
                    setActiveTab('log');
                }
            } catch (e) {
                // ignore invalid data
            }
        }
        fetchStats();
    }, []);

    const handleEdit = (id: string) => {
        setEditId(id);
        setActiveTab('publish');
    };

    const handlePublishSuccess = (category?: string) => {
        setEditId(null);
        setActiveTab(category === 'Log' ? 'log' : 'list');
        fetchStats();
    };

    const handleTabChange = (key: 'list' | 'log' | 'publish') => {
        if (key === 'publish' && activeTab !== 'publish') {
            setPublishCategoryIntent(activeTab === 'log' ? 'Log' : 'Announcement');
        }
        setActiveTab(key);
        if (key === 'list' || key === 'log') setEditId(null);
    };

    // No permission view
    if (!canList && !canLog && !canPublish) {
        return (
            <div className="flex flex-col items-center justify-center min-h-[60vh]">
                <div className="p-8 bg-slate-50 rounded-3xl border border-dashed border-slate-200 text-center max-w-md mx-auto">
                    <div className="w-20 h-20 mx-auto rounded-full bg-slate-100 flex items-center justify-center mb-6 shadow-inner">
                        <Megaphone className="w-8 h-8 text-slate-300" />
                    </div>
                    <h3 className="text-xl font-bold text-slate-700 mb-2">暂无访问权限</h3>
                    <p className="text-slate-400 leading-relaxed">
                        您当前没有查看公告的权限。<br />
                        如需访问，请联系管理员为您添加以下权限：<br />
                        <code className="text-xs bg-slate-100 px-2 py-1 rounded mt-2 inline-block text-slate-500 font-mono">announcement:list</code> 或者 <code className="text-xs bg-slate-100 px-2 py-1 rounded mt-2 inline-block text-slate-500 font-mono">announcement:log</code>
                    </p>
                </div>
            </div>
        );
    }

    const tabs = [
        { key: 'list' as const, label: '公告列表', icon: List, permission: 'announcement:list' },
        { key: 'log' as const, label: '更新日志', icon: FileText, permission: 'announcement:log' },
        { key: 'publish' as const, label: editId ? '编辑公告' : '发布内容', icon: Plus, permission: 'announcement:publish' },
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
                        公告
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
                        value={stats.monthlyCount}
                        trend="up"
                        trendValue="+12%"
                    />
                    <StatCard
                        icon={AlertCircle}
                        iconColor="text-rose-600"
                        iconBg="bg-rose-50"
                        label="紧急通知"
                        value={stats.urgentCount}
                    />
                    <StatCard
                        icon={BellRing}
                        iconColor="text-amber-500"
                        iconBg="bg-amber-50"
                        label="待审核"
                        value={stats.pendingCount}
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
                            {(activeTab === 'list' || activeTab === 'log') && (
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
                                    <AnnouncementList 
                                        onEdit={handleEdit} 
                                        defaultSelectedId={initialSelectedId} 
                                        forceCategory="Announcement"
                                    />
                                </div>
                            )}
                            {activeTab === 'log' && canLog && (
                                <div className="p-6">
                                    <AnnouncementList 
                                        onEdit={handleEdit} 
                                        defaultSelectedId={initialSelectedId} 
                                        forceCategory="Log"
                                    />
                                </div>
                            )}
                            {activeTab === 'publish' && canPublish && (
                                <div className="p-6">
                                    <PublishAnnouncement 
                                        editId={editId} 
                                        onSuccess={handlePublishSuccess} 
                                        defaultCategory={publishCategoryIntent}
                                    />
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
