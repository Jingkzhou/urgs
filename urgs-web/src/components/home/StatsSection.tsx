import React, { useMemo } from 'react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Cell,
  AreaChart,
  Area
} from 'recharts';
import {
  RefreshCw,
  TrendingUp,
  Activity,
  Zap,
  Box
} from 'lucide-react';
import { TaskStatsVO } from '../../api/stats';

interface ChartProps {
  loading?: boolean;
}

// ----------------------------------------------------------------------
// 1. BatchStatusChart - Glassmorphism Capsule Design
// ----------------------------------------------------------------------
export const BatchStatusChart: React.FC<ChartProps & { data: TaskStatsVO[], onRefresh: () => void }> = ({ data, loading, onRefresh }) => {
  const chartData = useMemo(() => {
    if (!data || data.length === 0) return [];
    // Show top 6 systems to maintain clean look
    return data.slice(0, 6).map(item => ({
      name: item.systemName || '未知系统',
      completed: item.totalCompleted || 0,
      running: item.totalInProgress || 0,
      failed: item.totalFailed || 0,
    }));
  }, [data]);

  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      return (
        <div className="bg-white/95 backdrop-blur-xl border border-slate-200 p-3 rounded-2xl shadow-2xl ring-1 ring-black/5">
          <p className="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] mb-2 border-b border-slate-100 pb-1.5">{label}</p>
          {payload.map((entry: any, index: number) => (
            <div key={index} className="flex items-center gap-2.5 mt-1">
              <div className="w-1.5 h-1.5 rounded-full" style={{ backgroundColor: entry.fill }} />
              <span className="text-[10px] text-slate-500 font-bold">{entry.name}:</span>
              <span className="text-xs font-black text-slate-900 ml-auto">{entry.value}</span>
            </div>
          ))}
        </div>
      );
    }
    return null;
  };

  return (
    <div className="relative bg-white/70 backdrop-blur-md rounded-[2.5rem] shadow-[0_25px_50px_-12px_rgba(0,0,0,0.08)] border border-slate-200/50 flex flex-col h-[320px] overflow-hidden group w-full transition-all duration-700 hover:shadow-[0_45px_90px_-20px_rgba(0,0,0,0.12)]">
      {/* Decorative Gradient Background */}
      <div className="absolute top-0 right-0 w-64 h-64 bg-red-500/5 rounded-full blur-3xl pointer-events-none" />

      {/* Header */}
      <div className="flex items-center justify-between p-7 relative z-10">
        <div className="flex items-center gap-4">
          <div className="relative">
            <div className="absolute -inset-1 bg-gradient-to-r from-red-500/20 to-amber-500/20 rounded-2xl blur opacity-30 group-hover:opacity-60 transition duration-1000"></div>
            <div className="relative p-2.5 bg-white rounded-2xl border border-slate-100 shadow-sm">
              <Activity className="w-4 h-4 text-red-500" />
            </div>
          </div>
          <div>
            <h2 className="text-base font-black text-slate-800 tracking-tight leading-none">实时任务态势</h2>
            <p className="text-[9px] text-slate-400 font-bold uppercase tracking-[0.3em] mt-1.5 flex items-center gap-1.5">
              <Zap className="w-2.5 h-2.5 text-amber-500 animate-pulse" />
              Pulse Monitor
            </p>
          </div>
        </div>

        <button
          onClick={onRefresh}
          disabled={loading}
          className="group/btn relative p-2.5 bg-slate-100/50 hover:bg-slate-200/50 rounded-2xl border border-slate-200/50 transition-all duration-300 disabled:opacity-50"
        >
          <RefreshCw size={14} className={`text-slate-500 group-hover/btn:text-slate-800 ${loading ? 'animate-spin' : ''}`} />
        </button>
      </div>

      {/* Chart Canvas */}
      <div className="flex-1 w-full px-6 pb-6 relative z-10 min-h-[180px]">
        {loading ? (
          <div className="flex items-center justify-center h-full">
            <RefreshCw className="w-8 h-8 text-slate-200 animate-spin" />
          </div>
        ) : (
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.03)" vertical={false} />
              <XAxis
                dataKey="name"
                axisLine={false}
                tickLine={false}
                tick={{ fill: '#94a3b8', fontSize: 9, fontWeight: 700 }}
                dy={10}
              />
              <YAxis hide />
              <Tooltip content={<CustomTooltip />} cursor={{ fill: 'rgba(0,0,0,0.02)' }} />
              <Bar dataKey="completed" name="已完成" stackId="a" fill="#10b981" barSize={18} radius={[0, 0, 0, 0]} />
              <Bar dataKey="running" name="运行中" stackId="a" fill="#3b82f6" barSize={18} radius={[0, 0, 0, 0]} />
              <Bar dataKey="failed" name="已失败" stackId="a" fill="#ef4444" barSize={18} radius={[8, 8, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        )}
      </div>

      {/* Decorative Bottom Accents */}
      <div className="absolute bottom-4 left-7 flex items-center gap-6 opacity-30 group-hover:opacity-60 transition-opacity">
        <div className="flex items-center gap-2">
          <div className="w-1.5 h-1.5 bg-emerald-500 rounded-full" />
          <span className="text-[7px] font-black text-slate-500 uppercase tracking-widest">Global Sync</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-1.5 h-1.5 bg-red-500 rounded-full" />
          <span className="text-[7px] font-black text-slate-500 uppercase tracking-widest">Active Thread</span>
        </div>
      </div>
    </div>
  );
};

// ----------------------------------------------------------------------
// 2. TrendAnalysisChart - Neon Waveglow Design
// ----------------------------------------------------------------------
export const TrendAnalysisChart: React.FC = () => {
  const trendData = [
    { name: '00:00', value: 320, load: 45 },
    { name: '04:00', value: 280, load: 38 },
    { name: '08:00', value: 650, load: 72 },
    { name: '12:00', value: 890, load: 88 },
    { name: '16:00', value: 720, load: 65 },
    { name: '20:00', value: 540, load: 52 },
    { name: '24:00', value: 410, load: 42 }
  ];

  return (
    <div className="relative bg-white border border-slate-100 rounded-[2.5rem] shadow-[0_20px_40px_rgba(0,0,0,0.03)] flex flex-col h-[400px] overflow-hidden group transition-all duration-700 hover:shadow-[0_40px_80px_rgba(0,0,0,0.06)]">
      {/* Clean Gradient Backdrop */}
      <div className="absolute top-0 right-0 w-1/2 h-full bg-gradient-to-l from-slate-50 to-transparent opacity-50 pointer-events-none" />

      {/* Header */}
      <div className="flex items-center justify-between p-8 relative z-10">
        <div className="flex items-center gap-5">
          <div className="p-3 bg-slate-900 rounded-2xl shadow-xl shadow-slate-900/20">
            <TrendingUp className="w-5 h-5 text-white" />
          </div>
          <div>
            <h2 className="text-xl font-black text-slate-900 tracking-tight leading-none">指标走势</h2>
            <p className="text-[10px] text-slate-400 font-bold uppercase tracking-[0.2em] mt-2 flex items-center gap-1.5">
              <Box className="w-3 h-3 text-red-500" />
              Global Trend Metrics
            </p>
          </div>
        </div>

        <div className="flex items-center gap-6">
          <div className="flex flex-col items-end">
            <span className="text-2xl font-black text-slate-900 leading-none">2.4k</span>
            <span className="text-[9px] font-black text-emerald-500 uppercase tracking-widest mt-1">+12.5% VOL</span>
          </div>
          <div className="w-px h-10 bg-slate-100" />
          <div className="px-5 py-2.5 bg-slate-50 border border-slate-100 rounded-xl">
            <span className="text-xs font-black text-slate-900 flex items-center gap-2">
              <div className="w-2 h-2 bg-red-500 rounded-full animate-ping" />
              REAL-TIME
            </span>
          </div>
        </div>
      </div>

      {/* Chart Canvas */}
      <div className="flex-1 w-full px-4 pb-4">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={trendData} margin={{ top: 20, right: 30, left: 0, bottom: 0 }}>
            <defs>
              <linearGradient id="colorValue" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#ef4444" stopOpacity={0.15} />
                <stop offset="95%" stopColor="#ef4444" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
            <XAxis
              dataKey="name"
              axisLine={false}
              tickLine={false}
              tick={{ fill: '#94a3b8', fontSize: 10, fontWeight: 700 }}
              dy={15}
            />
            <YAxis
              axisLine={false}
              tickLine={false}
              tick={{ fill: '#94a3b8', fontSize: 10, fontWeight: 700 }}
            />
            <Tooltip
              contentStyle={{
                backgroundColor: 'rgba(15, 23, 42, 0.95)',
                borderRadius: '20px',
                border: 'none',
                color: '#fff',
                boxShadow: '0 25px 50px -12px rgba(0,0,0,0.5)'
              }}
            />
            <Area
              type="monotone"
              dataKey="value"
              stroke="#ef4444"
              strokeWidth={4}
              fillOpacity={1}
              fill="url(#colorValue)"
              animationDuration={2500}
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
};
