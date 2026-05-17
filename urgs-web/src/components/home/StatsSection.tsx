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
} from 'recharts';
import { motion, AnimatePresence } from 'framer-motion';
import {
  RefreshCw,
  Activity,
  Zap,
  Box,
} from 'lucide-react';
import { TaskStatsVO, fetchRealtimeDetails, TaskRealtimeMonitor } from '../../api/stats';
import { X } from 'lucide-react';
import { createPortal } from 'react-dom';
export { default as TrendAnalysisChart } from './TrendAnalysisChart';

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
