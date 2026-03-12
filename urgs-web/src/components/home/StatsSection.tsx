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
import { motion, AnimatePresence } from 'framer-motion';
import {
  RefreshCw,
  TrendingUp,
  Activity,
  Zap,
  Box
} from 'lucide-react';
import { TaskStatsVO, fetchRealtimeDetails, TaskRealtimeMonitor } from '../../api/stats';
import { X } from 'lucide-react';
import { createPortal } from 'react-dom';

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
      systemId: item.systemId || '',
      name: item.systemName || '未知系统',
      completed: item.totalCompleted || 0,
      running: item.totalInProgress || 0,
      failed: item.totalFailed || 0,
    }));
  }, [data]);

  const [selectedSystemId, setSelectedSystemId] = React.useState<string | null>(null);
  const [selectedSystemName, setSelectedSystemName] = React.useState<string>('');
  const [details, setDetails] = React.useState<TaskRealtimeMonitor[]>([]);
  const [loadingDetails, setLoadingDetails] = React.useState(false);

  const handleBarClick = async (dataItem: any) => {
    let payload = null;

    // 当点击 <Bar> 时，Recharts 返回的 dataItem 通常就是当前柱子的行数据（含我们自定义的 systemId）
    if (dataItem && dataItem.systemId) {
      payload = dataItem;
    } else if (dataItem && dataItem.payload && dataItem.payload.systemId) {
      payload = dataItem.payload;
    } else if (dataItem && dataItem.activePayload && dataItem.activePayload.length > 0) {
      payload = dataItem.activePayload[0].payload;
    }

    if (!payload || !payload.systemId) {
      console.warn("未在此元素中找到 systemId 参数:", dataItem);
      return;
    }

    const systemId = payload.systemId;
    setSelectedSystemId(systemId);
    setSelectedSystemName(payload.name);
    
    setLoadingDetails(true);
    try {
      const result = await fetchRealtimeDetails(systemId);
      setDetails(result);
    } catch (err) {
      console.error('Failed to fetch realtime details', err);
    } finally {
      setLoadingDetails(false);
    }
  };

  const closeDetails = () => {
    setSelectedSystemId(null);
    setDetails([]);
  };

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
                tick={{ fill: '#94a3b8', fontSize: 9, fontWeight: 700, cursor: 'pointer' }}
                dy={10}
              />
              <YAxis hide />
              <Tooltip content={<CustomTooltip />} cursor={{ fill: 'rgba(0,0,0,0.04)', radius: 8 }} />
              <Bar dataKey="completed" name="已完成" stackId="a" fill="#10b981" barSize={18} radius={[0, 0, 0, 0]} style={{ cursor: 'pointer' }} onClick={handleBarClick} />
              <Bar dataKey="running" name="运行中" stackId="a" fill="#3b82f6" barSize={18} radius={[0, 0, 0, 0]} style={{ cursor: 'pointer' }} onClick={handleBarClick} />
              <Bar dataKey="failed" name="已失败" stackId="a" fill="#ef4444" barSize={18} radius={[8, 8, 0, 0]} style={{ cursor: 'pointer' }} onClick={handleBarClick} />
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

      {/* Details Modal */}
      {typeof document !== 'undefined' ? createPortal(
        <AnimatePresence>
          {selectedSystemId && (
            <div className="fixed inset-0 z-[100] flex items-center justify-center">
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm"
                onClick={closeDetails}
              />
              <motion.div
                initial={{ opacity: 0, scale: 0.95, y: 20 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.95, y: 20 }}
                className="relative z-10 w-full max-w-2xl bg-white rounded-3xl shadow-2xl border border-slate-200 overflow-hidden flex flex-col max-h-[85vh] mx-4"
              >
                <div className="p-6 border-b border-slate-100 flex items-center justify-between bg-slate-50/50">
                  <div>
                    <h3 className="text-lg font-black text-slate-800 tracking-tight">今日任务明细</h3>
                    <p className="text-xs text-slate-500 font-bold mt-1">{selectedSystemName}</p>
                  </div>
                  <button
                    onClick={closeDetails}
                    className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-full transition-colors"
                  >
                    <X size={20} />
                  </button>
                </div>
                <div className="p-6 overflow-y-auto">
                  {loadingDetails ? (
                    <div className="flex items-center justify-center h-32">
                      <RefreshCw className="w-6 h-6 text-slate-300 animate-spin" />
                    </div>
                  ) : details.length === 0 ? (
                    <div className="text-center py-10 text-sm text-slate-500 font-medium">
                      当日暂无任务运行记录
                    </div>
                  ) : (
                    <div className="space-y-3">
                      {details.map((task) => (
                        <div key={task.id} className="flex items-center justify-between p-4 rounded-2xl border border-slate-100 bg-white hover:border-slate-200 transition-colors shadow-sm">
                          <div className="flex flex-col gap-1">
                            <span className="text-sm font-bold text-slate-800">{task.taskName}</span>
                            <span className="text-[10px] text-slate-400 font-medium flex gap-3">
                              <span>开始: {task.startTime ? new Date(task.startTime).toLocaleTimeString() : '-'}</span>
                              <span>结束: {task.endTime ? new Date(task.endTime).toLocaleTimeString() : '-'}</span>
                            </span>
                          </div>
                          <div className="flex items-center">
                            {task.taskStatus === 'SUCCESS' && (
                              <span className="px-2.5 py-1 bg-emerald-50 text-emerald-600 text-[10px] font-black tracking-widest uppercase rounded-lg border border-emerald-100/50">
                                完成
                              </span>
                            )}
                            {task.taskStatus === 'RUNNING' && (
                              <span className="px-2.5 py-1 bg-blue-50 text-blue-600 text-[10px] font-black tracking-widest uppercase rounded-lg border border-blue-100/50 flex items-center gap-1.5">
                                <span className="w-1.5 h-1.5 rounded-full bg-blue-500 animate-pulse" />
                                执行中
                              </span>
                            )}
                            {task.taskStatus === 'FAILED' && (
                              <span className="px-2.5 py-1 bg-red-50 text-red-600 text-[10px] font-black tracking-widest uppercase rounded-lg border border-red-100/50">
                                异常
                              </span>
                            )}
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </motion.div>
            </div>
          )}
        </AnimatePresence>,
        document.body
      ) : null}
    </div>
  );
};

// ----------------------------------------------------------------------
// 2. TrendAnalysisChart - Premium Flowing Glow Design
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

  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      return (
        <motion.div
          initial={{ opacity: 0, scale: 0.9, y: 10 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          className="bg-slate-900/90 backdrop-blur-xl border border-white/10 p-4 rounded-2xl shadow-2xl"
        >
          <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-3 border-b border-white/5 pb-2">
            Timeline: {label}
          </p>
          <div className="space-y-2">
            <div className="flex items-center justify-between gap-8">
              <span className="text-[11px] text-slate-300 font-bold flex items-center gap-2">
                <div className="w-1.5 h-1.5 rounded-full bg-red-500 shadow-[0_0_8px_rgba(239,68,68,0.8)]" />
                Requests
              </span>
              <span className="text-sm font-black text-white">{payload[0].value}</span>
            </div>
            <div className="flex items-center justify-between gap-8">
              <span className="text-[11px] text-slate-300 font-bold flex items-center gap-2">
                <div className="w-1.5 h-1.5 rounded-full bg-amber-500 shadow-[0_0_8px_rgba(245,158,11,0.8)]" />
                System Load
              </span>
              <span className="text-sm font-black text-white">{payload[0].payload.load}%</span>
            </div>
          </div>
        </motion.div>
      );
    }
    return null;
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.8, ease: "easeOut" }}
      className="relative bg-white/80 backdrop-blur-xl border border-slate-200/60 rounded-[3rem] shadow-[0_32px_64px_-16px_rgba(0,0,0,0.08)] flex flex-col h-[420px] overflow-hidden group transition-all duration-700 hover:shadow-[0_48px_96px_-24px_rgba(0,0,0,0.12)] hover:-translate-y-1"
    >
      {/* Dynamic Background Elements */}
      <div className="absolute -top-24 -right-24 w-64 h-64 bg-red-500/5 rounded-full blur-[80px] group-hover:bg-red-500/10 transition-colors duration-1000" />
      <div className="absolute -bottom-24 -left-24 w-64 h-64 bg-amber-500/5 rounded-full blur-[80px] group-hover:bg-amber-500/10 transition-colors duration-1000" />

      {/* Header Section */}
      <div className="flex items-center justify-between p-9 relative z-10">
        <div className="flex items-center gap-6">
          <div className="relative">
            <motion.div
              animate={{ rotate: 360 }}
              transition={{ duration: 20, repeat: Infinity, ease: "linear" }}
              className="absolute -inset-2 bg-gradient-to-r from-red-500/20 via-transparent to-amber-500/20 rounded-full blur-md opacity-0 group-hover:opacity-100 transition-opacity duration-1000"
            />
            <div className="relative p-3.5 bg-slate-900 rounded-2xl shadow-2xl shadow-slate-900/20 overflow-hidden group-hover:scale-110 transition-transform duration-500">
              <TrendingUp className="w-5 h-5 text-white" />
              <div className="absolute top-0 left-0 w-full h-full bg-gradient-to-tr from-white/10 to-transparent" />
            </div>
          </div>
          <div>
            <h2 className="text-xl font-black text-slate-900 tracking-tight leading-none mb-2.5">指标走势</h2>
            <div className="flex items-center gap-3">
              <span className="px-2 py-0.5 bg-red-50 text-[9px] font-black text-red-600 rounded-md border border-red-100/50 uppercase tracking-widest">Live Flow</span>
              <p className="text-[10px] text-slate-400 font-bold uppercase tracking-[0.2em] flex items-center gap-2">
                <Activity className="w-3 h-3 text-slate-300" />
                Network Latency Monitor
              </p>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-8">
          <div className="flex flex-col items-end">
            <div className="flex items-baseline gap-1.5">
              <span className="text-3xl font-black text-slate-900 leading-none tabular-nums">2.4k</span>
              <span className="text-xs font-black text-emerald-500 flex items-center gap-0.5">
                <TrendingUp size={12} />
                12.5%
              </span>
            </div>
            <span className="text-[9px] font-black text-slate-400 uppercase tracking-[0.2em] mt-2">Active Requests / Hr</span>
          </div>
          
          <div className="relative h-12 w-px bg-slate-100">
             <motion.div 
               animate={{ y: [0, 48, 0] }}
               transition={{ duration: 3, repeat: Infinity }}
               className="absolute top-0 left-[-1px] w-[3px] h-4 bg-red-500/30 blur-[1px]" 
             />
          </div>

          <div className="px-6 py-3 bg-slate-50 border border-slate-100 rounded-2xl group-hover:border-red-100 transition-colors">
            <span className="text-xs font-black text-slate-900 flex items-center gap-3">
              <div className="relative">
                <div className="w-2.5 h-2.5 bg-red-500 rounded-full" />
                <div className="absolute inset-0 w-2.5 h-2.5 bg-red-500 rounded-full animate-ping scale-150 opacity-40" />
              </div>
              NODE-01
            </span>
          </div>
        </div>
      </div>

      {/* Chart Canvas with Smooth Transitions */}
      <div className="flex-1 w-full px-4 pb-6 relative z-10 overflow-hidden">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={trendData} margin={{ top: 10, right: 30, left: 0, bottom: 0 }}>
            <defs>
              <linearGradient id="colorValue" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#ef4444" stopOpacity={0.15} />
                <stop offset="95%" stopColor="#ef4444" stopOpacity={0} />
              </linearGradient>
              <linearGradient id="colorGlow" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#ef4444" stopOpacity={0.3} />
                <stop offset="100%" stopColor="#ef4444" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid 
              strokeDasharray="4 4" 
              stroke="rgba(0,0,0,0.03)" 
              vertical={false} 
            />
            <XAxis
              dataKey="name"
              axisLine={false}
              tickLine={false}
              tick={{ fill: '#94a3b8', fontSize: 10, fontWeight: 800 }}
              dy={15}
            />
            <YAxis
              axisLine={false}
              tickLine={false}
              tick={{ fill: '#94a3b8', fontSize: 10, fontWeight: 800 }}
              dx={-10}
            />
            <Tooltip content={<CustomTooltip />} cursor={{ stroke: '#ef4444', strokeWidth: 1, strokeDasharray: '5 5' }} />
            
            {/* Soft Glow Layer */}
            <Area
              type="monotone"
              dataKey="value"
              stroke="none"
              fill="url(#colorGlow)"
              animationDuration={3000}
              animationBegin={500}
            />
            
            {/* Main Area Layer */}
            <Area
              type="monotone"
              dataKey="value"
              stroke="#ef4444"
              strokeWidth={4}
              strokeLinecap="round"
              fill="url(#colorValue)"
              animationDuration={2500}
              dot={(props: any) => {
                const { cx, cy, index } = props;
                if (index === trendData.length - 1) {
                  return (
                    <g key="pulsing-dot">
                      <circle cx={cx} cy={cy} r={10} fill="#ef4444" opacity={0.2} className="animate-pulse" />
                      <circle cx={cx} cy={cy} r={4} fill="#ef4444" stroke="#fff" strokeWidth={2} />
                    </g>
                  );
                }
                return null;
              }}
              activeDot={{ r: 6, fill: '#ef4444', stroke: '#fff', strokeWidth: 3 }}
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>

      {/* Futuristic Metadata Footer */}
      <div className="px-9 py-6 border-t border-slate-50 bg-slate-50/30 flex items-center justify-between">
        <div className="flex gap-8">
          <div className="flex flex-col">
            <span className="text-[8px] font-black text-slate-400 uppercase tracking-widest mb-1">Peak Utilization</span>
            <span className="text-xs font-bold text-slate-700">89.4% <span className="text-emerald-500 ml-1">Normal</span></span>
          </div>
          <div className="flex flex-col">
            <span className="text-[8px] font-black text-slate-400 uppercase tracking-widest mb-1">Avg Response</span>
            <span className="text-xs font-bold text-slate-700">124ms</span>
          </div>
        </div>
        <div className="flex items-center gap-3">
           <div className="flex -space-x-1.5">
             {[1,2,3].map(i => (
               <div key={i} className="w-5 h-5 rounded-full bg-slate-200 border-2 border-white" />
             ))}
           </div>
           <span className="text-[10px] font-black text-slate-500">+12 Nodes Active</span>
        </div>
      </div>
    </motion.div>
  );
};
