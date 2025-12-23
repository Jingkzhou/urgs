import React, { useState, useEffect } from 'react';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer,
  AreaChart, Area
} from 'recharts';
import { BarChart as BarChartIcon, TrendingUp, RefreshCw } from 'lucide-react';
import { TREND_STATS } from '../../constants';

import { fetchBatchStatusStats, TaskStatsVO } from '../../api/stats';

const StatsSection: React.FC = () => {
  const [batchStats, setBatchStats] = useState<TaskStatsVO[]>([]);
  const [loading, setLoading] = useState(false);

  const fetchStats = async () => {
    setLoading(true);
    try {
      const data = await fetchBatchStatusStats();
      setBatchStats(data);
    } catch (err) {
      console.error('Failed to fetch batch stats', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStats();
  }, []);

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {/* Chart 1: Batch Completion Status */}
      <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-200 flex flex-col h-[400px]">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-lg font-bold text-slate-800 flex items-center gap-2">
            <div className="p-1.5 bg-red-100 rounded-md">
              <BarChartIcon className="w-4 h-4 text-red-600" />
            </div>
            批量完成情况统计 (Batch Status)
          </h2>
          <div className="flex items-center gap-2">
            <button onClick={fetchStats} className="p-1 hover:bg-slate-100 rounded-full transition-colors" title="刷新数据">
              <RefreshCw size={14} className={`text-slate-400 ${loading ? 'animate-spin' : ''}`} />
            </button>
            <select className="text-sm border-slate-200 rounded-md text-slate-500 focus:ring-red-500 focus:border-red-500">
              <option>本周 (This Week)</option>
              <option>本月 (This Month)</option>
            </select>
          </div>
        </div>

        <div className="flex-1 w-full min-h-[260px]">
          <ResponsiveContainer width="100%" height={260} minWidth={0}>
            <BarChart
              data={batchStats}
              margin={{ top: 20, right: 30, left: 0, bottom: 5 }}
            >
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
              <XAxis dataKey="systemName" tick={{ fontSize: 12, fill: '#64748b' }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 12, fill: '#64748b' }} axisLine={false} tickLine={false} />
              <Tooltip
                contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                cursor={{ fill: '#fef2f2' }}
              />
              <Legend iconType="circle" wrapperStyle={{ paddingTop: '20px' }} />
              <Bar dataKey="totalCompleted" name="已完成 (Completed)" stackId="a" fill="#dc2626" radius={[0, 0, 4, 4]} />
              <Bar dataKey="totalInProgress" name="进行中 (In Progress)" stackId="a" fill="#f59e0b" />
              <Bar dataKey="totalNotStarted" name="未开始 (Not Started)" stackId="a" fill="#e2e8f0" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Chart 2: Indicator Trends */}
      <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-200 flex flex-col h-[400px]">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-lg font-bold text-slate-800 flex items-center gap-2">
            <div className="p-1.5 bg-amber-100 rounded-md">
              <TrendingUp className="w-4 h-4 text-amber-600" />
            </div>
            指标趋势 (Trend Indicators)
          </h2>
          <div className="flex gap-2 text-xs">
            <span className="px-2 py-1 bg-red-50 text-red-700 rounded font-medium border border-red-100">合规率 +2.4%</span>
          </div>
        </div>

        <div className="flex-1 w-full min-h-[260px]">
          <ResponsiveContainer width="100%" height={260} minWidth={0}>
            <AreaChart
              data={TREND_STATS}
              margin={{ top: 10, right: 30, left: 0, bottom: 0 }}
            >
              <defs>
                <linearGradient id="colorCompliance" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#dc2626" stopOpacity={0.1} />
                  <stop offset="95%" stopColor="#dc2626" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="colorRisk" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#f59e0b" stopOpacity={0.1} />
                  <stop offset="95%" stopColor="#f59e0b" stopOpacity={0} />
                </linearGradient>
              </defs>
              <XAxis dataKey="month" tick={{ fontSize: 12, fill: '#64748b' }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 12, fill: '#64748b' }} axisLine={false} tickLine={false} />
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
              <Tooltip
                contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
              />
              <Legend iconType="circle" wrapperStyle={{ paddingTop: '20px' }} />
              <Area
                type="monotone"
                dataKey="complianceRate"
                name="合规率 (Compliance %)"
                stroke="#dc2626"
                fillOpacity={1}
                fill="url(#colorCompliance)"
                strokeWidth={2}
              />
              <Area
                type="monotone"
                dataKey="riskScore"
                name="风险指数 (Risk Score)"
                stroke="#f59e0b"
                fillOpacity={1}
                fill="url(#colorRisk)"
                strokeWidth={2}
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
};

export default StatsSection;
