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

    return (
        <div className="space-y-6">
            <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
                <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
                    <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-lg bg-red-100 flex items-center justify-center">
                            <Megaphone className="w-5 h-5 text-red-600" />
                        </div>
                        <div>
                            <h1 className="text-2xl font-bold text-slate-800">公告管理</h1>
                            <p className="text-sm text-slate-500">Announcement Management</p>
                        </div>
                    </div>

                    <div className="flex bg-slate-100 rounded-lg p-1">
                        <Auth code="announcement:list">
                            <button
                                onClick={() => setActiveTab('list')}
                                className={`flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-md transition-all ${activeTab === 'list'
                                    ? 'bg-white text-red-600 shadow-sm'
                                    : 'text-slate-500 hover:text-slate-700'
                                    }`}
                            >
                                <List className="w-4 h-4" />
                                公告列表
                            </button>
                        </Auth>
                        <Auth code="announcement:publish">
                            <button
                                onClick={() => setActiveTab('publish')}
                                className={`flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-md transition-all ${activeTab === 'publish'
                                    ? 'bg-white text-red-600 shadow-sm'
                                    : 'text-slate-500 hover:text-slate-700'
                                    }`}
                            >
                                <Plus className="w-4 h-4" />
                                发布公告
                            </button>
                        </Auth>
                    </div>
                </div>

                <div className="animate-fade-in">
                    {activeTab === 'list' && canList && <AnnouncementList />}
                    {activeTab === 'publish' && canPublish && <PublishAnnouncement />}
                </div>
            </div>
        </div>
    );
};

export default AnnouncementManagement;
