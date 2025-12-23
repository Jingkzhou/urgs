import React, { useState } from 'react';
import { Bell, FileClock, ChevronRight, Megaphone } from 'lucide-react';
import { NOTICES } from '../../constants';
import { Notice } from '../../types';

const Notices: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'Announcement' | 'Log'>('Announcement');
  const [notices, setNotices] = useState<Notice[]>([]);
  const [loading, setLoading] = useState(false);

  React.useEffect(() => {
    fetchNotices();
  }, [activeTab]);

  const fetchNotices = async () => {
    setLoading(true);
    try {
      const token = localStorage.getItem('auth_token');
      const userStr = localStorage.getItem('auth_user');
      let userId = 'admin';
      let systems = '';
      if (userStr) {
        const user = JSON.parse(userStr);
        userId = user.empId || 'admin';
        systems = user.system || '';
      }

      const queryParams = new URLSearchParams({
        current: '1',
        size: '5', // Limit to 5
        category: activeTab
      });

      const res = await fetch(`/api/announcement/list?${queryParams.toString()}`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'X-User-Id': encodeURIComponent(userId),
          'X-User-Systems': encodeURIComponent(systems)
        }
      });

      if (res.ok) {
        const data = await res.json();
        // Map API response to UI model if needed, or use directly
        // Backend returns createTime, title, type, id.
        // UI expects date string.
        const mapped = data.records.map((item: any) => ({
          id: item.id,
          title: item.title,
          type: item.type,
          category: item.category,
          date: new Date(item.createTime).toLocaleDateString(),
          content: item.content,
          systems: item.systems,
          createBy: item.createBy,
          hasRead: item.hasRead
        }));
        setNotices(mapped);
      }
    } catch (error) {
      console.error('Failed to fetch notices', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 flex flex-col h-full">
      <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
        <h2 className="text-lg font-bold text-slate-800 flex items-center gap-2">
          {activeTab === 'Announcement' ? <Megaphone className="w-5 h-5 text-red-500" /> : <FileClock className="w-5 h-5 text-slate-500" />}
          公告与日志
        </h2>
        <div className="flex bg-slate-100 rounded-lg p-1">
          <button
            onClick={() => setActiveTab('Announcement')}
            className={`px-3 py-1 text-sm font-medium rounded-md transition-all ${activeTab === 'Announcement' ? 'bg-white text-red-600 shadow-sm' : 'text-slate-500 hover:text-slate-700'
              }`}
          >
            通知公告
          </button>
          <button
            onClick={() => setActiveTab('Log')}
            className={`px-3 py-1 text-sm font-medium rounded-md transition-all ${activeTab === 'Log' ? 'bg-white text-red-600 shadow-sm' : 'text-slate-500 hover:text-slate-700'
              }`}
          >
            更新日志
          </button>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-4 custom-scrollbar">
        <div className="space-y-3">
          {loading ? (
            <div className="text-center text-slate-400 py-8">加载中...</div>
          ) : notices.length === 0 ? (
            <div className="text-center text-slate-400 py-8">暂无数据</div>
          ) : (
            notices.map((notice) => (
              <div
                key={notice.id}
                className="group flex items-start gap-3 p-3 rounded-lg hover:bg-slate-50 transition-colors border border-transparent hover:border-slate-100 cursor-pointer"
                onClick={() => window.location.href = `#/announcement?id=${notice.id}`} // Navigate with ID
              >
                <div className="mt-1">
                  {notice.type === 'urgent' && <span className="w-2 h-2 rounded-full bg-red-600 block animate-pulse"></span>}
                  {notice.type === 'normal' && <span className="w-2 h-2 rounded-full bg-blue-400 block"></span>}
                  {notice.type === 'update' && <span className="w-2 h-2 rounded-full bg-amber-400 block"></span>}
                  {notice.type === 'regulatory' && <span className="w-2 h-2 rounded-full bg-purple-500 block"></span>}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <h4 className={`text-sm ${notice.hasRead ? 'text-slate-500 font-normal' : 'text-slate-800 font-bold'} truncate group-hover:text-red-700`}>
                      {!notice.hasRead && <span className="inline-block w-2 h-2 bg-red-500 rounded-full mr-1 align-middle"></span>}
                      {notice.title}
                    </h4>
                    <span className="text-xs text-slate-400 whitespace-nowrap ml-2 font-mono">
                      {notice.date}
                    </span>
                  </div>
                  <div className="flex justify-between items-center mt-1">
                    <p className="text-xs text-slate-500 line-clamp-1 flex-1">
                      {(() => {
                        try {
                          const sys = typeof notice.systems === 'string' ? JSON.parse(notice.systems) : notice.systems;
                          const sysStr = Array.isArray(sys) ? sys.join(', ') : sys;
                          return `[${sysStr}]`;
                        } catch (e) {
                          return notice.systems ? `[${notice.systems}]` : '';
                        }
                      })()}
                    </p>
                    <span className="text-xs text-slate-400 ml-2">
                      {notice.createBy}
                    </span>
                  </div>
                </div>
                <ChevronRight className="w-4 h-4 text-slate-300 opacity-0 group-hover:opacity-100 transition-opacity" />
              </div>
            )))}
        </div>
      </div>

      <div className="p-3 border-t border-slate-50 text-center">
        <button className="text-xs text-red-600 font-medium hover:underline" onClick={() => window.location.href = '#/announcement'}>
          查看全部 &rarr;
        </button>
      </div>
    </div>
  );
};

export default Notices;