import React, { useState, useEffect, useCallback } from 'react';
import { motion } from 'framer-motion';
import { 
  Sun, 
  Moon, 
  Calendar, 
  ShieldCheck, 
  Building,
  User
} from 'lucide-react';
import SystemLinks from '../SystemLinks';
import Notices from '../Notices';
import { BatchStatusChart, TrendAnalysisChart } from '../StatsSection';
import Auth from '../../Auth';
import { hasPermission } from '../../../utils/permission';
import { fetchBatchStatusStats, TaskStatsVO } from '../../../api/stats';
import { useSmartPolling } from '../../../hooks/useSmartPolling';

const BusinessDashboardView: React.FC = () => {
  const [userInfo, setUserInfo] = useState<{
    name?: string;
    department?: string;
    roleName?: string;
    avatarUrl?: string;
  } | null>(null);

  const [batchData, setBatchData] = useState<TaskStatsVO[]>([]);
  const [loadingBatch, setLoadingBatch] = useState(false);

  const canViewNotice = hasPermission('dash:notice:view');
  const canViewBatchStatus = hasPermission('dash:stats');
  const canViewSystems = hasPermission('dash:systems');
  const canViewTrend = hasPermission('dash:stats');

  // Load user information
  useEffect(() => {
    try {
      const stored = localStorage.getItem('auth_user');
      if (stored) {
        setUserInfo(JSON.parse(stored));
      }
    } catch (e) {
      console.error('Failed to parse auth_user', e);
    }
  }, []);

  // Fetch batch status stats for the BatchStatusChart
  const loadBatchData = useCallback(async () => {
    if (!canViewBatchStatus) return;
    setLoadingBatch(true);
    try {
      const data = await fetchBatchStatusStats();
      setBatchData(data || []);
    } catch (err) {
      console.error('Failed to fetch stats in dashboard', err);
    } finally {
      setLoadingBatch(false);
    }
  }, [canViewBatchStatus]);

  useSmartPolling(loadBatchData, 30000, { enabled: canViewBatchStatus });

  // Greetings logic
  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 6) return '凌晨好';
    if (hour < 9) return '早上好';
    if (hour < 12) return '上午好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    return '晚上好';
  };

  const getGreetingIcon = () => {
    const hour = new Date().getHours();
    if (hour >= 6 && hour < 18) {
      return <Sun className="w-8 h-8 text-amber-500 animate-pulse" />;
    }
    return <Moon className="w-8 h-8 text-indigo-400 animate-pulse" />;
  };

  const getFormattedDate = () => {
    const date = new Date();
    const days = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    return `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日 ${days[date.getDay()]}`;
  };

  return (
    <div className="space-y-6 pb-12 pt-4">
      {/* 1. Welcome Banner */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="relative overflow-hidden rounded-[2.5rem] border border-slate-200/60 bg-white/75 p-6 backdrop-blur-xl shadow-[0_20px_45px_-12px_rgba(0,0,0,0.06)] hover:shadow-[0_30px_60px_-15px_rgba(0,0,0,0.1)] transition-all duration-500"
      >
        {/* Background ambient glow */}
        <div className="absolute -right-24 -top-24 w-80 h-80 bg-red-500/5 rounded-full blur-[80px] pointer-events-none" />
        
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-6 relative z-10">
          <div className="flex items-center gap-5">
            {/* User Avatar */}
            <div className="w-16 h-16 rounded-[1.5rem] bg-gradient-to-br from-red-500 to-rose-600 p-0.5 shadow-lg shadow-red-500/10 flex items-center justify-center text-white">
              {userInfo?.avatarUrl ? (
                <img 
                  src={userInfo.avatarUrl} 
                  alt={userInfo.name || 'User'} 
                  className="w-full h-full object-cover rounded-[1.35rem]" 
                />
              ) : (
                <User className="w-7 h-7" />
              )}
            </div>

            {/* Greeting Text */}
            <div>
              <div className="flex items-center gap-2">
                <span className="text-xl font-black text-slate-800 tracking-tight">
                  {getGreeting()}，{userInfo?.name || '尊敬的业务用户'}
                </span>
                {getGreetingIcon()}
              </div>
              
              <div className="flex flex-wrap items-center gap-x-3 gap-y-1 mt-1.5 text-xs text-slate-400 font-bold">
                {userInfo?.department && (
                  <span className="flex items-center gap-1.5">
                    <Building className="w-3.5 h-3.5" />
                    {userInfo.department}
                  </span>
                )}
                {userInfo?.department && userInfo?.roleName && (
                  <span className="w-1 h-1 rounded-full bg-slate-300" />
                )}
                {userInfo?.roleName && (
                  <span className="flex items-center gap-1.5 text-red-500">
                    <span className="px-1.5 py-0.5 bg-red-50 border border-red-100 rounded-md">
                      {userInfo.roleName}
                    </span>
                  </span>
                )}
              </div>
            </div>
          </div>

          {/* Quick Info / Date / System Status */}
          <div className="flex flex-col md:items-end justify-center gap-2">
            <div className="flex items-center gap-2 text-xs font-bold text-slate-500 bg-slate-50 border border-slate-100 px-3 py-1.5 rounded-2xl">
              <Calendar className="w-3.5 h-3.5 text-slate-400" />
              <span>{getFormattedDate()}</span>
            </div>
            
            <div className="flex items-center gap-2 text-xs font-bold text-emerald-600 bg-emerald-50 border border-emerald-100 px-3 py-1.5 rounded-2xl">
              <ShieldCheck className="w-3.5 h-3.5 text-emerald-500 animate-pulse" />
              <span>平台业务服务运行良好</span>
            </div>
          </div>
        </div>
      </motion.div>

      {/* 2. System Links (Full Width Navigation Belt) */}
      {canViewSystems && (
        <Auth code="dash:systems">
          <div className="relative transform transition-transform duration-500 hover:-translate-y-1">
            <SystemLinks fullWidth compact showStatusFooter={false} />
          </div>
        </Auth>
      )}

      {/* 3. Grid Dashboard Content (Left 8, Right 4) */}
      <div className="grid grid-cols-1 gap-6 xl:grid-cols-12 items-stretch">
        
        {/* Left Column (8/12) */}
        <div className="xl:col-span-8 flex flex-col gap-6">
          {/* Metric Trends */}
          {canViewTrend && (
            <Auth code="dash:stats">
              <div className="relative transform transition-transform duration-500 hover:-translate-y-1">
                <TrendAnalysisChart />
              </div>
            </Auth>
          )}
        </div>

        {/* Right Column (4/12) */}
        <div className="xl:col-span-4 flex flex-col gap-6">
          {/* Notices */}
          {canViewNotice && (
            <Auth code="dash:notice:view">
              <div className="relative transform transition-transform duration-500 hover:-translate-y-1">
                <Notices />
              </div>
            </Auth>
          )}

          {/* Batch Status Chart */}
          {canViewBatchStatus && (
            <Auth code="dash:stats">
              <div className="relative transform transition-transform duration-500 hover:-translate-y-1">
                <BatchStatusChart 
                  data={batchData} 
                  loading={loadingBatch} 
                  onRefresh={loadBatchData} 
                />
              </div>
            </Auth>
          )}
        </div>

      </div>
      
      {/* 3. Footer */}
      <footer className="text-center text-slate-400 text-[10px] py-12 relative mt-8">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-48 h-px bg-gradient-to-r from-transparent via-slate-200 to-transparent"></div>
        <div className="flex flex-col items-center gap-2 opacity-40">
          <p className="font-black tracking-[0.2em] uppercase">Financial Portal V2.4.0</p>
          <p className="font-medium tracking-tight">Copyright © 2026 Bank of Jilin. High Performance Cloud Infrastructure.</p>
        </div>
      </footer>
    </div>
  );
};

export default BusinessDashboardView;
