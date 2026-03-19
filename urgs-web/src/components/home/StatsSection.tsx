import React, { useMemo, useState, useEffect, useCallback, useRef } from 'react';
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
  Box,
  BarChart3,
  ChevronDown
} from 'lucide-react';
import { TaskStatsVO, fetchRealtimeDetails, TaskRealtimeMonitor } from '../../api/stats';
import { fetchMetricTypes, fetchMetricTrend, fetchMetricSystems, MetricTypeVO, MetricTrendVO } from '../../api/metrics';
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

      {/* Interactive Cards / Chart Canvas */}
      <div className="flex-1 w-full px-6 pb-6 relative z-10 flex flex-col justify-center min-h-[180px]">
        {loading ? (
          <div className="flex items-center justify-center h-full">
            <RefreshCw className="w-8 h-8 text-slate-200 animate-spin" />
          </div>
        ) : chartData.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full gap-4 opacity-60">
            <div className="relative">
              <div className="w-16 h-16 rounded-full bg-slate-100/50 flex items-center justify-center relative z-10 shadow-sm border border-white">
                <Box className="w-6 h-6 text-slate-400" />
              </div>
              <div className="absolute inset-0 bg-slate-200 rounded-full animate-ping opacity-20" />
            </div>
            <div className="text-center">
              <p className="text-sm font-black text-slate-500 tracking-wide">所有系统静默待命</p>
              <p className="text-[10px] font-bold text-slate-400 mt-1 uppercase tracking-widest">今日暂无调度任务</p>
            </div>
          </div>
        ) : chartData.length <= 4 ? (
          <div className={`grid w-full h-full max-h-[220px] overflow-y-auto mt-2 px-2 pb-2 place-content-center ${
            chartData.length === 1 ? 'grid-cols-1 w-full max-w-[560px] mx-auto gap-0' :
            chartData.length === 2 ? 'grid-cols-2 max-w-[720px] mx-auto gap-6' : 
            chartData.length === 3 ? 'grid-cols-3 max-w-[1000px] mx-auto gap-5' :
            'grid-cols-2 md:grid-cols-4 max-w-full mx-auto gap-4'
          }`}>
            {chartData.map((sys) => {
              const total = sys.completed + sys.running + sys.failed;
              const completedPct = total === 0 ? 0 : (sys.completed / total) * 100;
              const runningPct = total === 0 ? 0 : (sys.running / total) * 100;
              const failedPct = total === 0 ? 0 : (sys.failed / total) * 100;

              return (
                <div 
                  key={sys.systemId}
                  onClick={() => handleBarClick(sys)}
                  className={`group/card relative bg-white/60 hover:bg-white/95 backdrop-blur-xl border border-slate-200/60 rounded-[2rem] cursor-pointer transition-all duration-500 hover:shadow-[0_20px_40px_-15px_rgba(0,0,0,0.1)] hover:-translate-y-1 overflow-hidden flex ${
                    chartData.length === 1 ? 'flex-row items-center p-6 gap-6 w-full' : 'flex-col h-full justify-between p-5'
                  }`}
                >
                  {/* Background decoration */}
                  <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-slate-100/50 to-transparent rounded-full blur-2xl -mr-10 -mt-10 pointer-events-none group-hover/card:from-blue-50/50 transition-colors duration-500" />
                  
                  <div className={`relative z-10 flex ${chartData.length === 1 ? 'flex-col min-w-[120px]' : 'items-start justify-between mb-5'}`}>
                    <div>
                      <h3 className={`font-black text-slate-800 tracking-tight leading-tight line-clamp-2 ${chartData.length === 1 ? 'text-lg max-w-[180px]' : 'text-base max-w-[140px]'}`}>{sys.name}</h3>
                      <p className={`font-bold text-slate-400 mt-1 uppercase tracking-wider ${chartData.length === 1 ? 'text-[11px]' : 'text-[9px]'}`}>今日任务数: <span className="text-slate-600 font-black">{total}</span></p>
                    </div>
                    {chartData.length !== 1 && (
                      <div className="w-8 h-8 shrink-0 rounded-full bg-slate-50/80 flex items-center justify-center border border-slate-200/50 group-hover/card:bg-slate-800 transition-colors duration-500 shadow-sm">
                        <Activity size={12} className="text-slate-500 group-hover/card:text-white transition-colors duration-500" />
                      </div>
                    )}
                  </div>
                  
                  <div className={`relative z-10 flex flex-col w-full ${chartData.length === 1 ? 'flex-1 pl-6 border-l border-slate-100/80 gap-3' : 'gap-4'}`}>
                    <div className="grid grid-cols-3 gap-2">
                       <div className={`flex flex-col items-center justify-center bg-emerald-50/60 border border-emerald-100/50 rounded-2xl group-hover/card:bg-emerald-50 transition-colors duration-300 ${chartData.length === 1 ? 'py-3' : 'py-2.5'}`}>
                         <span className={`font-black text-emerald-600 leading-none ${chartData.length === 1 ? 'text-2xl' : 'text-xl'}`}>{sys.completed}</span>
                         <span className="text-[10px] font-bold text-emerald-500 mt-1 uppercase">完成</span>
                       </div>
                       <div className={`flex flex-col items-center justify-center bg-blue-50/60 border border-blue-100/50 rounded-2xl group-hover/card:bg-blue-50 transition-colors duration-300 ${chartData.length === 1 ? 'py-3' : 'py-2.5'}`}>
                         <span className={`font-black text-blue-600 leading-none ${chartData.length === 1 ? 'text-2xl' : 'text-xl'}`}>{sys.running}</span>
                         <span className="text-[10px] font-bold text-blue-500 mt-1 uppercase">运行</span>
                       </div>
                       <div className={`flex flex-col items-center justify-center bg-red-50/60 border border-red-100/50 rounded-2xl group-hover/card:bg-red-50 transition-colors duration-300 ${chartData.length === 1 ? 'py-3' : 'py-2.5'}`}>
                         <span className={`font-black text-red-600 leading-none ${chartData.length === 1 ? 'text-2xl' : 'text-xl'}`}>{sys.failed}</span>
                         <span className="text-[10px] font-bold text-red-500 mt-1 uppercase">失败</span>
                       </div>
                    </div>

                    <div className={`flex items-center gap-3 ${chartData.length === 1 ? '' : 'mt-1'}`}>
                      <div className={`flex-1 flex rounded-full overflow-hidden bg-slate-100 ${chartData.length === 1 ? 'h-2' : 'h-1.5'}`}>
                        {completedPct > 0 && <div style={{ width: `${completedPct}%` }} className="bg-emerald-500 transition-all duration-1000" />}
                        {runningPct > 0 && <div style={{ width: `${runningPct}%` }} className="bg-blue-500 animate-pulse" />}
                        {failedPct > 0 && <div style={{ width: `${failedPct}%` }} className="bg-red-500 transition-all duration-1000" />}
                      </div>
                      <span className="text-[10px] font-black text-slate-300 w-8 text-right tabular-nums">{completedPct > 0 ? Math.round(completedPct) : 0}%</span>
                    </div>
                  </div>
                </div>
              );
            })}
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
// 2. TrendAnalysisChart - Dynamic Metrics Trend with System Switching
// ----------------------------------------------------------------------

type TimeRange = 'today' | '7d' | '30d';

const TIME_RANGE_OPTIONS: { key: TimeRange; label: string }[] = [
  { key: 'today', label: '今日' },
  { key: '7d', label: '7天' },
  { key: '30d', label: '30天' },
];

function getTimeRange(range: TimeRange): { startTime: string; endTime: string; granularity: string } {
  const now = new Date();
  const pad = (n: number) => String(n).padStart(2, '0');
  const fmt = (d: Date) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
  const endTime = fmt(now);

  if (range === 'today') {
    const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    return { startTime: fmt(start), endTime, granularity: 'HOUR' };
  } else if (range === '7d') {
    const start = new Date(now);
    start.setDate(start.getDate() - 7);
    start.setHours(0, 0, 0, 0);
    return { startTime: fmt(start), endTime, granularity: 'DAY' };
  } else {
    const start = new Date(now);
    start.setDate(start.getDate() - 30);
    start.setHours(0, 0, 0, 0);
    return { startTime: fmt(start), endTime, granularity: 'DAY' };
  }
}

function formatNumber(val: number): string {
  if (val >= 10000) return (val / 10000).toFixed(1) + 'w';
  if (val >= 1000) return (val / 1000).toFixed(1) + 'k';
  return val.toFixed(val % 1 === 0 ? 0 : 2);
}

export const TrendAnalysisChart: React.FC = () => {
  const [systems, setSystems] = useState<{ clientId: string; name: string }[]>([]);
  const [selectedSystemId, setSelectedSystemId] = useState<string>('');
  const [metricTypes, setMetricTypes] = useState<MetricTypeVO[]>([]);
  const [selectedTypeCode, setSelectedTypeCode] = useState<string>('');
  const [trendData, setTrendData] = useState<MetricTrendVO[]>([]);
  const [timeRange, setTimeRange] = useState<TimeRange>('today');
  const [loading, setLoading] = useState(false);
  const [systemDropdownOpen, setSystemDropdownOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const refreshTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Get current metric type info
  const currentMetric = useMemo(
    () => metricTypes.find((m) => m.typeCode === selectedTypeCode),
    [metricTypes, selectedTypeCode]
  );
  const chartColor = currentMetric?.color || '#ef4444';

  // Stats computed from trend data
  const stats = useMemo(() => {
    if (trendData.length === 0) return null;
    const values = trendData.map((d) => d.avgValue);
    const maxVal = Math.max(...trendData.map((d) => d.maxValue));
    const minVal = Math.min(...trendData.map((d) => d.minValue));
    const avg = values.reduce((a, b) => a + b, 0) / values.length;
    const latest = values[values.length - 1];
    const prev = values.length > 1 ? values[values.length - 2] : latest;
    const changePercent = prev !== 0 ? ((latest - prev) / prev) * 100 : 0;
    return { maxVal, minVal, avg, latest, changePercent };
  }, [trendData]);

  // Close dropdown on outside click
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setSystemDropdownOpen(false);
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  // 1. Load systems (use existing system management API with user permissions)
  useEffect(() => {
    const loadSystems = async () => {
      try {
        const list = await fetchMetricSystems();
        if (!list || list.length === 0) return;
        setSystems(list);
        setSelectedSystemId(list[0].clientId);
      } catch (err) {
        console.error('Failed to load systems for metrics', err);
      }
    };
    loadSystems();
  }, []);

  // 2. Load metric types when system changes
  useEffect(() => {
    if (!selectedSystemId) return;
    const loadTypes = async () => {
      const types = await fetchMetricTypes(selectedSystemId);
      setMetricTypes(types);
      if (types.length > 0) {
        setSelectedTypeCode(types[0].typeCode);
      } else {
        setSelectedTypeCode('');
        setTrendData([]);
      }
    };
    loadTypes();
  }, [selectedSystemId]);

  // 3. Load trend data when type/range changes
  const loadTrend = useCallback(async () => {
    if (!selectedSystemId || !selectedTypeCode) return;
    setLoading(true);
    try {
      const { startTime, endTime, granularity } = getTimeRange(timeRange);
      const data = await fetchMetricTrend({
        systemId: selectedSystemId,
        typeCode: selectedTypeCode,
        startTime,
        endTime,
        granularity,
      });
      setTrendData(data);
    } catch (err) {
      console.error('Failed to load trend data', err);
    } finally {
      setLoading(false);
    }
  }, [selectedSystemId, selectedTypeCode, timeRange]);

  useEffect(() => {
    loadTrend();
  }, [loadTrend]);

  // 4. Auto-refresh every 60s
  useEffect(() => {
    refreshTimerRef.current = setInterval(loadTrend, 60000);
    return () => {
      if (refreshTimerRef.current) clearInterval(refreshTimerRef.current);
    };
  }, [loadTrend]);

  const selectedSystemName = systems.find((s) => s.clientId === selectedSystemId)?.name || '';

  // Chart data formatted for recharts
  const chartData = useMemo(
    () =>
      trendData.map((d) => ({
        name: timeRange === 'today' ? d.timeLabel.slice(11, 16) : d.timeLabel.slice(5, 10),
        value: d.avgValue,
        max: d.maxValue,
        min: d.minValue,
      })),
    [trendData, timeRange]
  );

  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      return (
        <motion.div
          initial={{ opacity: 0, scale: 0.9, y: 10 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          className="bg-slate-900/90 backdrop-blur-xl border border-white/10 p-4 rounded-2xl shadow-2xl"
        >
          <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-3 border-b border-white/5 pb-2">
            {label}
          </p>
          <div className="space-y-2">
            <div className="flex items-center justify-between gap-8">
              <span className="text-[11px] text-slate-300 font-bold flex items-center gap-2">
                <div className="w-1.5 h-1.5 rounded-full shadow-[0_0_8px]" style={{ backgroundColor: chartColor }} />
                {currentMetric?.typeName || '均值'}
              </span>
              <span className="text-sm font-black text-white">
                {formatNumber(payload[0].value)} {currentMetric?.unit || ''}
              </span>
            </div>
            <div className="flex items-center justify-between gap-8">
              <span className="text-[11px] text-slate-300 font-bold flex items-center gap-2">
                <div className="w-1.5 h-1.5 rounded-full bg-amber-500 shadow-[0_0_8px_rgba(245,158,11,0.8)]" />
                MAX
              </span>
              <span className="text-sm font-black text-white">
                {formatNumber(payload[0].payload.max)} {currentMetric?.unit || ''}
              </span>
            </div>
            <div className="flex items-center justify-between gap-8">
              <span className="text-[11px] text-slate-300 font-bold flex items-center gap-2">
                <div className="w-1.5 h-1.5 rounded-full bg-sky-400 shadow-[0_0_8px_rgba(56,189,248,0.8)]" />
                MIN
              </span>
              <span className="text-sm font-black text-white">
                {formatNumber(payload[0].payload.min)} {currentMetric?.unit || ''}
              </span>
            </div>
          </div>
        </motion.div>
      );
    }
    return null;
  };

  const gradientId = `metric-gradient-${selectedTypeCode || 'default'}`;
  const glowId = `metric-glow-${selectedTypeCode || 'default'}`;

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.8, ease: 'easeOut' }}
      className="relative bg-white/80 backdrop-blur-xl border border-slate-200/60 rounded-[3rem] shadow-[0_32px_64px_-16px_rgba(0,0,0,0.08)] flex flex-col group transition-all duration-700 hover:shadow-[0_48px_96px_-24px_rgba(0,0,0,0.12)] hover:-translate-y-1"
    >
      {/* Dynamic Background Elements */}
      <div className="absolute -top-24 -right-24 w-64 h-64 rounded-full blur-[80px] transition-colors duration-1000 pointer-events-none" style={{ backgroundColor: `${chartColor}08` }} />
      <div className="absolute -bottom-24 -left-24 w-64 h-64 bg-amber-500/5 rounded-full blur-[80px] group-hover:bg-amber-500/10 transition-colors duration-1000 pointer-events-none" />

      {/* Header Section */}
      <div className="flex items-center justify-between px-9 pt-8 pb-4 relative z-10">
        <div className="flex items-center gap-6">
          <div className="relative">
            <motion.div
              animate={{ rotate: 360 }}
              transition={{ duration: 20, repeat: Infinity, ease: 'linear' }}
              className="absolute -inset-2 rounded-full blur-md opacity-0 group-hover:opacity-100 transition-opacity duration-1000"
              style={{ background: `linear-gradient(to right, ${chartColor}33, transparent, #f59e0b33)` }}
            />
            <div className="relative p-3.5 bg-slate-900 rounded-2xl shadow-2xl shadow-slate-900/20 overflow-hidden group-hover:scale-110 transition-transform duration-500">
              <TrendingUp className="w-5 h-5 text-white" />
              <div className="absolute top-0 left-0 w-full h-full bg-gradient-to-tr from-white/10 to-transparent" />
            </div>
          </div>
          <div>
            <h2 className="text-xl font-black text-slate-900 tracking-tight leading-none mb-2.5">指标走势</h2>
            <div className="flex items-center gap-3">
              <span className="px-2 py-0.5 text-[9px] font-black rounded-md border uppercase tracking-widest" style={{ backgroundColor: `${chartColor}10`, color: chartColor, borderColor: `${chartColor}30` }}>
                Live Flow
              </span>
              <p className="text-[10px] text-slate-400 font-bold uppercase tracking-[0.2em] flex items-center gap-2">
                <Activity className="w-3 h-3 text-slate-300" />
                Metrics Monitor
              </p>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-6">
          {/* Stats summary */}
          {stats && (
            <div className="flex flex-col items-end">
              <div className="flex items-baseline gap-1.5">
                <span className="text-3xl font-black text-slate-900 leading-none tabular-nums">
                  {formatNumber(stats.latest)}
                </span>
                {stats.changePercent !== 0 && (
                  <span className={`text-xs font-black flex items-center gap-0.5 ${stats.changePercent > 0 ? 'text-emerald-500' : 'text-red-500'}`}>
                    <TrendingUp size={12} className={stats.changePercent < 0 ? 'rotate-180' : ''} />
                    {Math.abs(stats.changePercent).toFixed(1)}%
                  </span>
                )}
              </div>
              <span className="text-[9px] font-black text-slate-400 uppercase tracking-[0.2em] mt-2">
                {currentMetric?.typeName || 'Latest'} {currentMetric?.unit ? `(${currentMetric.unit})` : ''}
              </span>
            </div>
          )}

          {/* System Selector Dropdown */}
          {systems.length > 0 && (
            <div className="relative" ref={dropdownRef}>
              <button
                onClick={() => setSystemDropdownOpen(!systemDropdownOpen)}
                className="flex items-center gap-2.5 px-5 py-2.5 bg-slate-50 border border-slate-200/80 rounded-2xl hover:border-slate-300 transition-all duration-300 group/sys"
              >
                <div className="relative">
                  <div className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: chartColor }} />
                  <div className="absolute inset-0 w-2.5 h-2.5 rounded-full animate-ping scale-150 opacity-40" style={{ backgroundColor: chartColor }} />
                </div>
                <span className="text-xs font-black text-slate-800 max-w-[100px] truncate">{selectedSystemName}</span>
                <ChevronDown size={14} className={`text-slate-400 transition-transform duration-300 ${systemDropdownOpen ? 'rotate-180' : ''}`} />
              </button>

              <AnimatePresence>
                {systemDropdownOpen && (
                  <motion.div
                    initial={{ opacity: 0, y: -8, scale: 0.96 }}
                    animate={{ opacity: 1, y: 0, scale: 1 }}
                    exit={{ opacity: 0, y: -8, scale: 0.96 }}
                    transition={{ duration: 0.2 }}
                    className="absolute right-0 top-full mt-2 bg-white/95 backdrop-blur-xl border border-slate-200 rounded-2xl shadow-2xl py-2 min-w-[180px] max-h-[320px] overflow-y-auto z-50"
                  >
                    {systems.map((sys) => (
                      <button
                        key={sys.clientId}
                        onClick={() => {
                          setSelectedSystemId(sys.clientId);
                          setSystemDropdownOpen(false);
                        }}
                        className={`w-full text-left px-4 py-2.5 text-xs font-bold transition-colors ${
                          sys.clientId === selectedSystemId
                            ? 'bg-slate-100 text-slate-900'
                            : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
                        }`}
                      >
                        <div className="flex items-center gap-2.5">
                          {sys.clientId === selectedSystemId && (
                            <div className="w-1.5 h-1.5 rounded-full" style={{ backgroundColor: chartColor }} />
                          )}
                          <span className={sys.clientId === selectedSystemId ? '' : 'ml-4'}>{sys.name}</span>
                        </div>
                      </button>
                    ))}
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          )}

          {/* Refresh button */}
          <button
            onClick={loadTrend}
            disabled={loading}
            className="p-2.5 bg-slate-100/50 hover:bg-slate-200/50 rounded-2xl border border-slate-200/50 transition-all duration-300 disabled:opacity-50"
          >
            <RefreshCw size={14} className={`text-slate-500 hover:text-slate-800 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {/* Metric Type Pills + Time Range */}
      <div className="flex items-center justify-between px-9 pb-4 relative z-10">
        {/* Metric type pills */}
        <div className="flex items-center gap-2 overflow-x-auto scrollbar-hide">
          {metricTypes.length > 0 ? (
            metricTypes.map((mt) => (
              <button
                key={mt.typeCode}
                onClick={() => setSelectedTypeCode(mt.typeCode)}
                className={`relative flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-[11px] font-black tracking-wide whitespace-nowrap transition-all duration-300 border ${
                  mt.typeCode === selectedTypeCode
                    ? 'text-white shadow-lg'
                    : 'bg-white/60 text-slate-600 border-slate-200/60 hover:border-slate-300'
                }`}
                style={
                  mt.typeCode === selectedTypeCode
                    ? { backgroundColor: mt.color || '#ef4444', borderColor: mt.color || '#ef4444', boxShadow: `0 4px 14px ${mt.color || '#ef4444'}40` }
                    : {}
                }
              >
                <div
                  className={`w-1.5 h-1.5 rounded-full ${mt.typeCode === selectedTypeCode ? 'bg-white/60' : ''}`}
                  style={mt.typeCode !== selectedTypeCode ? { backgroundColor: mt.color || '#94a3b8' } : {}}
                />
                {mt.typeName}
              </button>
            ))
          ) : (
            <span className="text-[11px] text-slate-400 font-medium">暂无指标类型</span>
          )}
        </div>

        {/* Time range */}
        <div className="flex items-center bg-slate-100/60 rounded-xl p-0.5 border border-slate-200/40 shrink-0 ml-4">
          {TIME_RANGE_OPTIONS.map((opt) => (
            <button
              key={opt.key}
              onClick={() => setTimeRange(opt.key)}
              className={`px-3 py-1 rounded-lg text-[10px] font-black uppercase tracking-wider transition-all duration-300 ${
                timeRange === opt.key
                  ? 'bg-white text-slate-900 shadow-sm'
                  : 'text-slate-500 hover:text-slate-700'
              }`}
            >
              {opt.label}
            </button>
          ))}
        </div>
      </div>

      {/* Chart Canvas */}
      <div className="flex-1 w-full px-4 pb-6 relative z-10 overflow-hidden min-h-[240px]">
        <AnimatePresence mode="wait">
          {loading ? (
            <motion.div
              key="loading"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="flex items-center justify-center h-full"
            >
              <RefreshCw className="w-8 h-8 text-slate-200 animate-spin" />
            </motion.div>
          ) : chartData.length === 0 ? (
            <motion.div
              key="empty"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0 }}
              className="flex flex-col items-center justify-center h-full gap-4 opacity-60"
            >
              <div className="relative">
                <div className="w-16 h-16 rounded-full bg-slate-100/50 flex items-center justify-center relative z-10 shadow-sm border border-white">
                  <BarChart3 className="w-6 h-6 text-slate-400" />
                </div>
                <div className="absolute inset-0 bg-slate-200 rounded-full animate-ping opacity-20" />
              </div>
              <div className="text-center">
                <p className="text-sm font-black text-slate-500 tracking-wide">暂无指标数据</p>
                <p className="text-[10px] font-bold text-slate-400 mt-1 uppercase tracking-widest">No Metrics Available</p>
              </div>
            </motion.div>
          ) : (
            <motion.div
              key={`chart-${selectedTypeCode}-${timeRange}`}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.4 }}
              className="w-full h-full"
            >
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={chartData} margin={{ top: 10, right: 30, left: 0, bottom: 0 }}>
                  <defs>
                    <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor={chartColor} stopOpacity={0.15} />
                      <stop offset="95%" stopColor={chartColor} stopOpacity={0} />
                    </linearGradient>
                    <linearGradient id={glowId} x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor={chartColor} stopOpacity={0.3} />
                      <stop offset="100%" stopColor={chartColor} stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="4 4" stroke="rgba(0,0,0,0.03)" vertical={false} />
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
                  <Tooltip content={<CustomTooltip />} cursor={{ stroke: chartColor, strokeWidth: 1, strokeDasharray: '5 5' }} />
                  <Area
                    type="monotone"
                    dataKey="value"
                    stroke="none"
                    fill={`url(#${glowId})`}
                    animationDuration={3000}
                    animationBegin={500}
                  />
                  <Area
                    type="monotone"
                    dataKey="value"
                    stroke={chartColor}
                    strokeWidth={4}
                    strokeLinecap="round"
                    fill={`url(#${gradientId})`}
                    animationDuration={2500}
                    dot={(props: any) => {
                      const { cx, cy, index } = props;
                      if (index === chartData.length - 1) {
                        return (
                          <g key="pulsing-dot">
                            <circle cx={cx} cy={cy} r={10} fill={chartColor} opacity={0.2} className="animate-pulse" />
                            <circle cx={cx} cy={cy} r={4} fill={chartColor} stroke="#fff" strokeWidth={2} />
                          </g>
                        );
                      }
                      return null;
                    }}
                    activeDot={{ r: 6, fill: chartColor, stroke: '#fff', strokeWidth: 3 }}
                  />
                </AreaChart>
              </ResponsiveContainer>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Dynamic Metadata Footer */}
      <div className="px-9 py-5 border-t border-slate-50 bg-slate-50/30 flex items-center justify-between">
        {stats ? (
          <div className="flex gap-8">
            <div className="flex flex-col">
              <span className="text-[8px] font-black text-slate-400 uppercase tracking-widest mb-1">
                {currentMetric?.typeName || ''} MAX
              </span>
              <span className="text-xs font-bold text-slate-700">
                {formatNumber(stats.maxVal)} {currentMetric?.unit || ''}
              </span>
            </div>
            <div className="flex flex-col">
              <span className="text-[8px] font-black text-slate-400 uppercase tracking-widest mb-1">AVG</span>
              <span className="text-xs font-bold text-slate-700">
                {formatNumber(stats.avg)} {currentMetric?.unit || ''}
              </span>
            </div>
            <div className="flex flex-col">
              <span className="text-[8px] font-black text-slate-400 uppercase tracking-widest mb-1">MIN</span>
              <span className="text-xs font-bold text-slate-700">
                {formatNumber(stats.minVal)} {currentMetric?.unit || ''}
              </span>
            </div>
          </div>
        ) : (
          <div className="text-[10px] text-slate-400 font-bold">--</div>
        )}
        <div className="flex items-center gap-3">
          <div className="w-1.5 h-1.5 rounded-full animate-pulse" style={{ backgroundColor: chartColor }} />
          <span className="text-[10px] font-black text-slate-500">
            {selectedSystemName} {currentMetric?.typeName ? `/ ${currentMetric.typeName}` : ''}
          </span>
        </div>
      </div>
    </motion.div>
  );
};
