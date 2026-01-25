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

  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      return (
        <div className="bg-white/80 backdrop-blur-md border border-slate-200/50 p-3 rounded-xl shadow-xl">
          <p className="text-xs font-black text-slate-800 mb-2 border-b border-slate-100 pb-1">{label}</p>
          {payload.map((entry: any, index: number) => (
            <div key={index} className="flex items-center gap-2 mt-1">
              <div className="w-2 h-2 rounded-full" style={{ backgroundColor: entry.color || entry.fill }} />
              <span className="text-[11px] text-slate-500 font-medium">{entry.name}:</span>
              <span className="text-[11px] font-bold text-slate-900 ml-auto">{entry.value}</span>
            </div>
          ))}
        </div>
      );
    }
    return null;
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {/* Chart 1: Batch Completion Status */}
      <div className="relative bg-white/70 backdrop-blur-md p-6 rounded-2xl shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-slate-200/50 flex flex-col h-[400px] overflow-hidden group">
        <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-red-500 to-transparent opacity-60" />

        <div className="flex items-center justify-between mb-8">
          <h2 className="text-lg font-black text-slate-800 flex items-center gap-3">
            <div className="p-2 bg-gradient-to-br from-red-50 to-red-100/50 rounded-xl border border-red-100 shadow-sm transition-all duration-500 group-hover:scale-110 group-hover:rotate-6">
              <BarChartIcon className="w-4 h-4 text-red-600" />
            </div>
            <div className="flex flex-col">
              <span className="tracking-tight">批量完成情况统计</span>
              <span className="text-[10px] text-slate-400 font-medium uppercase tracking-widest mt-0.5">Batch Status</span>
            </div>
          </h2>
          <div className="flex items-center gap-2">
            <button
              onClick={fetchStats}
              className="p-2 hover:bg-red-50 hover:text-red-600 rounded-xl transition-all duration-300 text-slate-400 border border-transparent hover:border-red-100"
              title="刷新数据"
            >
              <RefreshCw size={14} className={`${loading ? 'animate-spin' : ''}`} />
            </button>
            <select className="text-[11px] font-bold border-slate-100 bg-slate-50/50 rounded-lg text-slate-600 focus:ring-red-500/20 focus:border-red-500 py-1 pl-2 pr-8 transition-all hover:bg-white cursor-pointer shadow-sm">
              <option>本周 (This Week)</option>
              <option>本月 (This Month)</option>
            </select>
          </div>
        </div>

        <div className="flex-1 w-full min-h-[260px]">
          <ResponsiveContainer width="100%" height={260}>
            <BarChart
              data={batchStats}
              margin={{ top: 10, right: 10, left: -20, bottom: 0 }}
              barGap={8}
            >
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
              <XAxis
                dataKey="systemName"
                tick={{ fontSize: 11, fill: '#94a3b8', fontWeight: 600 }}
                axisLine={false}
                tickLine={false}
                dy={10}
              />
              <YAxis
                tick={{ fontSize: 11, fill: '#94a3b8', fontWeight: 600 }}
                axisLine={false}
                tickLine={false}
              />
              <Tooltip content={<CustomTooltip />} cursor={{ fill: 'rgba(241, 15, 15, 0.03)', radius: 8 }} />
              <Legend
                verticalAlign="top"
                align="right"
                iconType="circle"
                iconSize={8}
                wrapperStyle={{ paddingBottom: '20px', fontSize: '11px', fontWeight: 700, color: '#64748b' }}
              />
              <Bar dataKey="totalCompleted" name="已完成" stackId="a" fill="#e11d48" radius={[0, 0, 0, 0]} barSize={24} />
              <Bar dataKey="totalInProgress" name="进行中" stackId="a" fill="#f59e0b" barSize={24} />
              <Bar dataKey="totalNotStarted" name="未开始" stackId="a" fill="#f1f5f9" radius={[6, 6, 0, 0]} barSize={24} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Chart 2: Indicator Trends */}
      <div className="relative bg-white/70 backdrop-blur-md p-6 rounded-2xl shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-slate-200/50 flex flex-col h-[400px] overflow-hidden group">
        <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-amber-500 to-transparent opacity-60" />

        <div className="flex items-center justify-between mb-8">
          <h2 className="text-lg font-black text-slate-800 flex items-center gap-3">
            <div className="p-2 bg-gradient-to-br from-amber-50 to-amber-100/50 rounded-xl border border-amber-100 shadow-sm transition-all duration-500 group-hover:scale-110 group-hover:rotate-6">
              <TrendingUp className="w-4 h-4 text-amber-600" />
            </div>
            <div className="flex flex-col">
              <span className="tracking-tight">指标趋势</span>
              <span className="text-[10px] text-slate-400 font-medium uppercase tracking-widest mt-0.5">Trend Indicators</span>
            </div>
          </h2>
          <div className="flex gap-2">
            <div className="flex items-center gap-1.5 px-3 py-1.5 bg-emerald-50 text-emerald-700 rounded-xl font-black text-[10px] border border-emerald-100 shadow-sm">
              <div className="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-ping" />
              合规率 +2.4%
            </div>
          </div>
        </div>

        <div className="flex-1 w-full min-h-[260px]">
          <ResponsiveContainer width="100%" height={260}>
            <AreaChart
              data={TREND_STATS}
              margin={{ top: 10, right: 10, left: -20, bottom: 0 }}
            >
              <defs>
                <linearGradient id="colorCompliance" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#e11d48" stopOpacity={0.15} />
                  <stop offset="95%" stopColor="#e11d48" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="colorRisk" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#f59e0b" stopOpacity={0.15} />
                  <stop offset="95%" stopColor="#f59e0b" stopOpacity={0} />
                </linearGradient>
              </defs>
              <XAxis
                dataKey="month"
                tick={{ fontSize: 11, fill: '#94a3b8', fontWeight: 600 }}
                axisLine={false}
                tickLine={false}
                dy={10}
              />
              <YAxis
                tick={{ fontSize: 11, fill: '#94a3b8', fontWeight: 600 }}
                axisLine={false}
                tickLine={false}
              />
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
              <Tooltip content={<CustomTooltip />} />
              <Legend
                verticalAlign="top"
                align="right"
                iconType="circle"
                iconSize={8}
                wrapperStyle={{ paddingBottom: '20px', fontSize: '11px', fontWeight: 700, color: '#64748b' }}
              />
              <Area
                type="monotone"
                dataKey="complianceRate"
                name="合规率"
                stroke="#e11d48"
                fillOpacity={1}
                fill="url(#colorCompliance)"
                strokeWidth={3}
                dot={{ fill: '#e11d48', strokeWidth: 2, r: 4, fillOpacity: 1 }}
                activeDot={{ r: 6, strokeWidth: 0 }}
              />
              <Area
                type="monotone"
                dataKey="riskScore"
                name="风险指数"
                stroke="#f59e0b"
                fillOpacity={1}
                fill="url(#colorRisk)"
                strokeWidth={3}
                dot={{ fill: '#f59e0b', strokeWidth: 2, r: 4, fillOpacity: 1 }}
                activeDot={{ r: 6, strokeWidth: 0 }}
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
};

export default StatsSection;
