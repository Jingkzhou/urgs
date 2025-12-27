import React, { useState } from 'react';
import { Megaphone, Plus, List, TrendingUp, AlertCircle, FileText, Bell } from 'lucide-react';
import { motion } from 'framer-motion';
import AnnouncementList from './AnnouncementList';
import PublishAnnouncement from './PublishAnnouncement';
import { hasPermission } from '../../utils/permission';
import Auth from '../Auth';

const AnnouncementManagement: React.FC = () => {
    const canList = hasPermission('announcement:list');
    const canPublish = hasPermission('announcement:publish');
    const [activeTab, setActiveTab] = useState<'list' | 'publish'>(canList ? 'list' : (canPublish ? 'publish' : 'list'));
    const [editId, setEditId] = useState<string | null>(null);

    const handleEdit = (id: string) => {
        setEditId(id);
        setActiveTab('publish');
    };

    const handlePublishSuccess = () => {
        setEditId(null);
        setActiveTab('list');
    };

    // 无权限提示
    if (!canList && !canPublish) {
        return (
            <div className="flex flex-col items-center justify-center py-32 bg-slate-50 rounded-3xl border border-dashed border-slate-200">
                <div className="w-24 h-24 rounded-full bg-slate-100 flex items-center justify-center mb-6 shadow-inner">
                    <Megaphone className="w-10 h-10 text-slate-300" />
                </div>
                <h3 className="text-xl font-bold text-slate-600 mb-2">暂无访问权限</h3>
                <p className="text-slate-400">请联系管理员获取公告管理权限</p>
            </div>
        );
    }

    const tabs = [
        { key: 'list' as const, label: '公告列表', icon: List, permission: 'announcement:list' },
        { key: 'publish' as const, label: editId ? '编辑公告' : '发布公告', icon: Plus, permission: 'announcement:publish' },
    ];

    return (
        <div className="space-y-8 animate-fade-in max-w-[1600px] mx-auto">
            {/* Header Section */}
            <header className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <h1 className="text-3xl font-black text-slate-800 tracking-tight mb-2">
                        公告管理
                        <span className="text-violet-500">.</span>
                    </h1>
                    <p className="text-slate-500 font-medium">
                        发布重要通知，同步监管政策，连接每一位关注者。
                    </p>
                </div>

                {/* Quick Stats Mini-Dashboard - Visual Only for Design Demo */}
                <div className="flex gap-4">
                    <div className="hidden lg:flex items-center gap-4 px-6 py-3 bg-white rounded-2xl border border-slate-100 shadow-sm">
                        <div className="w-10 h-10 rounded-xl bg-violet-50 flex items-center justify-center text-violet-600">
                            <TrendingUp size={20} />
                        </div>
                        <div>
                            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">本月发布</p>
                            <p className="text-lg font-black text-slate-800 leading-none">24</p>
                        </div>
                    </div>
                    <div className="hidden lg:flex items-center gap-4 px-6 py-3 bg-white rounded-2xl border border-slate-100 shadow-sm">
                        <div className="w-10 h-10 rounded-xl bg-red-50 flex items-center justify-center text-red-600">
                            <AlertCircle size={20} />
                        </div>
                        <div>
                            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">紧急通知</p>
                            <p className="text-lg font-black text-slate-800 leading-none">3</p>
                        </div>
                    </div>
                </div>
            </header>

            {/* Main Content Area */}
            <div className="space-y-6">
                {/* Navigation Tabs */}
                <div className="flex items-center justify-between">
                    <div className="inline-flex bg-slate-100/80 p-1.5 rounded-2xl backdrop-blur-sm">
                        {tabs.map(tab => (
                            <Auth key={tab.key} code={tab.permission}>
                                <button
                                    onClick={() => { setActiveTab(tab.key); if (tab.key === 'list') setEditId(null); }}
                                    className={`relative px-6 py-2.5 rounded-xl text-sm font-bold transition-all duration-300 flex items-center gap-2 z-10 ${activeTab === tab.key ? 'text-violet-600' : 'text-slate-500 hover:text-slate-700'
                                        }`}
                                >
                                    {activeTab === tab.key && (
                                        <motion.div
                                            layoutId="activeTab"
                                            className="absolute inset-0 bg-white rounded-xl shadow-sm border border-slate-200/50"
                                            initial={false}
                                            transition={{ type: "spring", stiffness: 500, damping: 30 }}
                                            style={{ zIndex: -1 }}
                                        />
                                    )}
                                    <tab.icon size={16} />
                                    {tab.label}
                                </button>
                            </Auth>
                        ))}
                    </div>

                    {/* Quick Action for Publish */}
                    <Auth code="announcement:publish">
                        {activeTab === 'list' && (
                            <motion.button
                                whileHover={{ scale: 1.02 }}
                                whileTap={{ scale: 0.98 }}
                                onClick={() => { setActiveTab('publish'); setEditId(null); }}
                                className="hidden md:flex items-center gap-2 px-6 py-2.5 bg-violet-600 text-white rounded-xl font-bold shadow-lg shadow-violet-200 hover:bg-violet-700 transition-colors"
                            >
                                <Plus size={18} />
                                <span className="text-sm">快速发布</span>
                            </motion.button>
                        )}
                    </Auth>
                </div>

                {/* Content Panel */}
                <motion.div
                    key={activeTab}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -10 }}
                    transition={{ duration: 0.3 }}
                >
                    {activeTab === 'list' && canList && <AnnouncementList onEdit={handleEdit} />}
                    {activeTab === 'publish' && canPublish && <PublishAnnouncement editId={editId} onSuccess={handlePublishSuccess} />}
                </motion.div>
            </div>
        </div>
    );
};

export default AnnouncementManagement;
