import React, { useState } from 'react';
import { Megaphone, Plus, List } from 'lucide-react';
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
            <div className="flex flex-col items-center justify-center py-20">
                <div className="w-20 h-20 rounded-full bg-slate-100 flex items-center justify-center mb-4">
                    <Megaphone className="w-10 h-10 text-slate-400" />
                </div>
                <h3 className="text-lg font-medium text-slate-600 mb-2">暂无访问权限</h3>
                <p className="text-sm text-slate-400">请联系管理员获取公告管理权限</p>
            </div>
        );
    }

    const tabs = [
        { key: 'list' as const, label: '公告列表', icon: List, permission: 'announcement:list' },
        { key: 'publish' as const, label: editId ? '编辑公告' : '发布公告', icon: Plus, permission: 'announcement:publish' },
    ];

    return (
        <div className="space-y-6 animate-fade-in">
            {/* 顶部区域 - 精简渐变背景 */}
            <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-violet-600 via-purple-600 to-indigo-700 p-6 shadow-lg shadow-purple-200/40">
                {/* 装饰背景 */}
                <div className="absolute inset-0 opacity-10">
                    <div className="absolute -top-12 -right-12 w-48 h-48 rounded-full bg-white/30 blur-3xl" />
                    <div className="absolute bottom-0 left-0 w-32 h-32 rounded-full bg-white/20 blur-2xl" />
                </div>

                <div className="relative z-10">
                    <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                        <div className="flex items-center gap-4">
                            <div className="w-12 h-12 rounded-xl bg-white/20 backdrop-blur-sm flex items-center justify-center shadow-lg">
                                <Megaphone className="w-6 h-6 text-white" />
                            </div>
                            <div>
                                <h1 className="text-xl font-bold text-white">公告管理</h1>
                                <p className="text-xs text-white/70 italic">Announcement Management</p>
                            </div>
                        </div>

                        {/* 快捷操作 */}
                        <Auth code="announcement:publish">
                            <button
                                onClick={() => { setActiveTab('publish'); setEditId(null); }}
                                className="inline-flex items-center gap-2 px-6 py-2 bg-white text-violet-600 hover:bg-violet-50 rounded-xl font-bold transition-all duration-200 shadow-lg hover:shadow-xl hover:scale-105"
                            >
                                <Plus className="w-5 h-5" />
                                发布公告
                            </button>
                        </Auth>
                    </div>
                </div>
            </div>

            {/* 主内容区 */}
            <div className="bg-white rounded-2xl shadow-sm border border-slate-200/60 overflow-hidden">
                {/* Tab 导航 - 胶囊式 */}
                <div className="px-6 pt-5 pb-4 border-b border-slate-100 bg-slate-50/50">
                    <div className="inline-flex bg-slate-100 rounded-xl p-1 gap-1">
                        {tabs.map(tab => (
                            <Auth key={tab.key} code={tab.permission}>
                                <button
                                    onClick={() => { setActiveTab(tab.key); if (tab.key === 'list') setEditId(null); }}
                                    className={`relative flex items-center gap-2 px-6 py-2.5 text-sm font-bold rounded-lg transition-all duration-300 ${activeTab === tab.key
                                            ? 'bg-white text-violet-600 shadow-md'
                                            : 'text-slate-500 hover:text-slate-700 hover:bg-white/50'
                                        }`}
                                >
                                    <tab.icon className="w-4 h-4" />
                                    {tab.label}
                                </button>
                            </Auth>
                        ))}
                    </div>
                </div>

                {/* 内容区 */}
                <div className="p-6">
                    <div className="animate-fade-in">
                        {activeTab === 'list' && canList && <AnnouncementList onEdit={handleEdit} />}
                        {activeTab === 'publish' && canPublish && <PublishAnnouncement editId={editId} onSuccess={handlePublishSuccess} />}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default AnnouncementManagement;
