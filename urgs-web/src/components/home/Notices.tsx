import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Bell,
  FileClock,
  ChevronRight,
  Megaphone,
  Clock,
  Info,
  Calendar,
  Layers,
  Sparkles
} from 'lucide-react';
import { Notice } from '../../types';

const Notices: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'Announcement' | 'Log'>('Announcement');
  const [notices, setNotices] = useState<Notice[]>([]);
  const [loading, setLoading] = useState(false);
  const [unreadCount, setUnreadCount] = useState(0);

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
        size: '10', // 稍微多取一点确保排序效果
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
        const mapped = data.records.map((item: any) => ({
          id: item.id,
          title: item.title,
          type: item.type,
          category: item.category,
          date: new Date(item.createTime).toLocaleDateString(),
          createTime: item.createTime, // 保留原始时间用于排序
          content: item.content,
          systems: item.systems,
          createBy: item.createBy,
          hasRead: item.hasRead
        }));

        // 按发布时间倒序排列
        const sorted = mapped.sort((a: any, b: any) => 
          new Date(b.createTime).getTime() - new Date(a.createTime).getTime()
        );

        setNotices(sorted);
        setUnreadCount(sorted.filter((n: any) => !n.hasRead).length);
      }
    } catch (error) {
      console.error('Failed to fetch notices', error);
    } finally {
      setLoading(false);
    }
  };

  const getTagStyle = (type: string) => {
    switch (type) {
      case 'urgent': return 'bg-rose-500/10 text-rose-600 border-rose-200/50';
      case 'update': return 'bg-amber-500/10 text-amber-600 border-amber-200/50';
      case 'regulatory': return 'bg-violet-500/10 text-violet-600 border-violet-200/50';
      default: return 'bg-blue-500/10 text-blue-600 border-blue-200/50';
    }
  };

  return (
    <div className="bg-white/70 backdrop-blur-md rounded-[2.5rem] shadow-[0_25px_50px_-12px_rgba(0,0,0,0.08)] border border-slate-200/50 flex flex-col h-[260px] overflow-hidden group transition-all duration-500 hover:shadow-[0_40px_80px_-15px_rgba(0,0,0,0.12)]">

      {/* Dynamic Header */}
      <div className="px-8 py-5 flex items-center justify-between border-b border-slate-100/50 relative z-10">
        <div className="flex items-center gap-3">
          <div className="p-2.5 bg-gradient-to-br from-slate-800 to-slate-900 rounded-2xl shadow-lg ring-4 ring-slate-100/50">
            <Sparkles className="w-4 h-4 text-white animate-pulse" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-base font-black text-slate-800 tracking-tight leading-none">公告中心</h2>
              {unreadCount > 0 && (
                <span className="flex items-center justify-center px-1.5 py-0.5 min-w-[18px] bg-rose-500 text-white text-[9px] font-black rounded-full shadow-[0_4px_12px_rgba(244,63,94,0.3)] animate-bounce-subtle">
                  {unreadCount}
                </span>
              )}
            </div>
            <p className="text-[9px] text-slate-400 font-bold uppercase tracking-widest mt-1.5 flex items-center gap-1.5">
              <Layers className="w-2.5 h-2.5" />
              Information Feed
            </p>
          </div>
        </div>

        {/* Liquid Tab Switcher */}
        <div className="flex bg-slate-100/80 p-1.5 rounded-2xl border border-slate-200/50">
          <button
            onClick={() => setActiveTab('Announcement')}
            className={`relative px-4 py-1.5 text-[11px] font-black rounded-xl transition-all duration-500 ${activeTab === 'Announcement' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-400 hover:text-slate-600'
              }`}
          >
            通知公告
          </button>
          <button
            onClick={() => setActiveTab('Log')}
            className={`relative px-4 py-1.5 text-[11px] font-black rounded-xl transition-all duration-500 ${activeTab === 'Log' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-400 hover:text-slate-600'
              }`}
          >
            更新日志
          </button>
        </div>
      </div>

      {/* Feed Content */}
      <div className="flex-1 overflow-y-auto px-6 py-4 custom-scrollbar relative z-10">
        <div className="flex flex-col gap-4">
          {loading ? (
            <div className="flex flex-col gap-3 py-4">
              {[1, 2].map(i => <div key={i} className="h-16 bg-slate-50 rounded-2xl animate-pulse border border-slate-100" />)}
            </div>
          ) : notices.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-10 opacity-30">
              <Bell className="w-8 h-8 mb-2" />
              <span className="text-[10px] font-bold uppercase tracking-widest">No Updates</span>
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-3">
              {notices.map((notice, idx) => (
                <motion.div
                  key={notice.id || idx}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: idx * 0.1 }}
                  onClick={() => window.location.href = `#/announcement?id=${notice.id}`}
                  className={`group/item relative border rounded-3xl p-4 cursor-pointer transition-all duration-500 flex items-center gap-4 hover:shadow-xl hover:-translate-y-1 ${
                    notice.hasRead 
                    ? 'bg-white/30 border-slate-100 opacity-60' 
                    : 'bg-white border-slate-200/60 shadow-[0_8px_20px_-6px_rgba(0,0,0,0.05)] shadow-red-500/5'
                  }`}
                >
                  {/* Status Ring */}
                  <div className={`flex-shrink-0 w-10 h-10 rounded-2xl flex items-center justify-center border-2 transition-transform duration-500 group-hover/item:scale-110 ${getTagStyle(notice.type)}`}>
                    {notice.type === 'urgent' ? <Megaphone className="w-4 h-4" /> : <Info className="w-4 h-4" />}
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between gap-2 mb-1">
                      <h4 className={`text-sm font-black truncate tracking-tight transition-colors ${notice.hasRead ? 'text-slate-400' : 'text-slate-800'}`}>
                        {notice.title}
                      </h4>
                      <span className="text-[10px] font-bold text-slate-400 flex items-center gap-1 shrink-0 bg-slate-50 px-2 py-0.5 rounded-full border border-slate-100">
                        <Calendar className="w-2.5 h-2.5" />
                        {notice.date}
                      </span>
                    </div>
                    
                    {/* Content Preview */}
                    <p className={`text-[11px] line-clamp-1 mb-1 leading-relaxed transition-colors ${notice.hasRead ? 'text-slate-400' : 'text-slate-500 opacity-80'}`}>
                      {notice.content || '暂无详细内容'}
                    </p>

                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <div className="flex items-center gap-1.5 min-w-0">
                          <p className="text-[9px] text-slate-400 font-bold uppercase truncate">
                            BY {notice.createBy}
                          </p>
                          {!notice.hasRead && (
                            <div className="relative flex h-2 w-2">
                              <div className="animate-ping absolute inline-flex h-full w-full rounded-full bg-rose-400 opacity-75"></div>
                              <div className="relative inline-flex rounded-full h-2 w-2 bg-rose-500 shadow-[0_0_8px_rgba(244,63,94,0.6)]"></div>
                            </div>
                          )}
                        </div>

                        {/* Type Tag */}
                        <div className={`px-1.5 py-0.5 rounded-md text-[9px] font-black border ${getTagStyle(notice.type)}`}>
                          {notice.type === 'urgent' ? '紧急' : 
                           notice.type === 'update' ? '更新' : 
                           notice.type === 'regulatory' ? '合规' : '普通'}
                        </div>
                      </div>
                      
                      {/* Systems Badge */}
                      {notice.systems && (
                        <div className="flex items-center gap-1 bg-slate-50 px-1.5 py-0.5 rounded-md border border-slate-100 max-w-[50%] shrink-0">
                          <Layers className="w-2 h-2 text-slate-400 flex-shrink-0" />
                          <span className="text-[9px] font-bold text-slate-500 break-words leading-tight">
                            {(() => {
                              try {
                                const sys = typeof notice.systems === 'string' ? JSON.parse(notice.systems) : notice.systems;
                                return Array.isArray(sys) ? sys.join(', ') : sys;
                              } catch (e) {
                                return notice.systems;
                              }
                            })()}
                          </span>
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Hover Accent */}
                  <div className="absolute top-2 right-2 opacity-0 group-hover/item:opacity-100 transition-opacity">
                    <ChevronRight className="w-3.5 h-3.5 text-slate-300" />
                  </div>
                </motion.div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Futuristic Footer */}
      <div className="px-6 py-3 border-t border-slate-50 bg-slate-50/30 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse" />
          <span className="text-[9px] font-black text-slate-400 uppercase tracking-tighter">Systems are nominal</span>
        </div>
        <button
          className="px-4 py-1 bg-white hover:bg-slate-900 hover:text-white border border-slate-200/50 rounded-xl text-[10px] font-black transition-all duration-500 shadow-sm"
          onClick={() => window.location.href = '#/announcement'}
        >
          FULL ARCHIVE
        </button>
      </div>
    </div>
  );
};

export default Notices;