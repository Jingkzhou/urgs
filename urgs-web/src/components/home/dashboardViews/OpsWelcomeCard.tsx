import React, { useEffect, useState } from 'react';
import { Building, Calendar, Moon, ShieldCheck, Sun, User } from 'lucide-react';
import { motion } from 'framer-motion';
import { getAvatarUrl } from '@/utils/avatarUtils';

interface UserInfo {
  name?: string;
  department?: string;
  roleName?: string;
  avatarUrl?: string;
}

const getGreeting = () => {
  const hour = new Date().getHours();
  if (hour < 6) return '凌晨好';
  if (hour < 9) return '早上好';
  if (hour < 12) return '上午好';
  if (hour < 14) return '中午好';
  if (hour < 18) return '下午好';
  return '晚上好';
};

const formatDateTime = (date: Date) => {
  const days = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
  const time = date.toLocaleTimeString('zh-CN', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  });
  return `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日 ${days[date.getDay()]} ${time}`;
};

const OpsWelcomeCard: React.FC = () => {
  const [userInfo, setUserInfo] = useState<UserInfo | null>(null);
  const [currentTime, setCurrentTime] = useState(new Date());
  const isDaytime = currentTime.getHours() >= 6 && currentTime.getHours() < 18;

  useEffect(() => {
    try {
      const stored = localStorage.getItem('auth_user');
      if (stored) setUserInfo(JSON.parse(stored));
    } catch (error) {
      console.error('Failed to parse auth_user', error);
    }
  }, []);

  useEffect(() => {
    const timer = window.setInterval(() => setCurrentTime(new Date()), 60000);
    return () => window.clearInterval(timer);
  }, []);

  return (
    <motion.section
      initial={{ opacity: 0, y: -16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.45 }}
      className="relative overflow-hidden rounded-[2rem] border border-slate-200/60 bg-white/75 px-5 py-4 shadow-[0_18px_40px_-18px_rgba(15,23,42,0.16)] backdrop-blur-xl"
    >
      <div className="pointer-events-none absolute -right-20 -top-24 h-56 w-56 rounded-full bg-red-500/5 blur-[72px]" />

      <div className="relative flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
        <div className="flex min-w-0 items-center gap-3.5">
          <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br from-red-500 to-rose-600 p-0.5 text-white shadow-lg shadow-red-500/10">
            {userInfo?.avatarUrl ? (
              <img src={getAvatarUrl(userInfo.avatarUrl, userInfo.name)} alt={userInfo.name || '用户'} className="h-full w-full rounded-[0.85rem] object-cover" />
            ) : (
              <User className="h-5 w-5" />
            )}
          </div>

          <div className="min-w-0">
            <div className="flex items-center gap-2">
              <h1 className="truncate text-lg font-black tracking-tight text-slate-800">
                {getGreeting()}，{userInfo?.name || '运维人员'}
              </h1>
              {isDaytime ? <Sun className="h-5 w-5 shrink-0 text-amber-500" /> : <Moon className="h-5 w-5 shrink-0 text-indigo-400" />}
            </div>
            <div className="mt-1 flex flex-wrap items-center gap-x-2.5 gap-y-1 text-[11px] font-bold text-slate-400">
              {userInfo?.department && <span className="flex items-center gap-1"><Building className="h-3.5 w-3.5" />{userInfo.department}</span>}
              {userInfo?.department && userInfo?.roleName && <span className="h-1 w-1 rounded-full bg-slate-300" />}
              {userInfo?.roleName && <span className="rounded-md border border-red-100 bg-red-50 px-1.5 py-0.5 text-red-500">{userInfo.roleName}</span>}
            </div>
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-2 lg:justify-end">
          <div className="flex items-center gap-1.5 rounded-xl border border-slate-100 bg-slate-50 px-2.5 py-1.5 text-[11px] font-bold text-slate-500">
            <Calendar className="h-3.5 w-3.5 text-slate-400" />
            <span>{formatDateTime(currentTime)}</span>
          </div>
          <div className="flex items-center gap-1.5 rounded-xl border border-emerald-100 bg-emerald-50 px-2.5 py-1.5 text-[11px] font-bold text-emerald-600">
            <ShieldCheck className="h-3.5 w-3.5 text-emerald-500" />
            <span>运维服务运行良好</span>
          </div>
        </div>
      </div>
    </motion.section>
  );
};

export default OpsWelcomeCard;
