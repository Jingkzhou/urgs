import React, { useMemo } from 'react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { motion, AnimatePresence } from 'framer-motion';
import {
  RefreshCw,
  Activity,
  Box,
  X,
} from 'lucide-react';
import { TaskStatsVO, fetchRealtimeDetails, TaskRealtimeMonitor } from '../../api/stats';
import { createPortal } from 'react-dom';
export { default as TrendAnalysisChart } from './TrendAnalysisChart';

interface ChartProps {
  loading?: boolean;
}

const MATERIAL_COLORS = {
  completed: '#81c995',
  running: '#aecbfa',
  failed: '#f28b82',
  completedText: '#188038',
  runningText: '#1a73e8',
  failedText: '#d93025',
  neutralText: '#5f6368',
};

const getStatusChipClass = (status: string) => {
  if (status === 'SUCCESS') return 'bg-[#e6f4ea] text-[#188038] border-[#ceead6]';
  if (status === 'RUNNING') return 'bg-[#e8f0fe] text-[#1a73e8] border-[#d2e3fc]';
  if (status === 'FAILED') return 'bg-[#fce8e6] text-[#d93025] border-[#fad2cf]';
  return 'bg-slate-100 text-slate-600 border-slate-200';
};

const getStatusLabel = (status: string) => {
  if (status === 'SUCCESS') return '完成';
  if (status === 'RUNNING') return '执行中';
  if (status === 'FAILED') return '异常';
  return status || '未知';
};

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
        <div className="rounded-2xl border border-slate-200 bg-white p-3 shadow-xl shadow-slate-900/10">
          <p className="mb-2 border-b border-slate-100 pb-1.5 text-[11px] font-semibold text-slate-700">{label}</p>
          {payload.map((entry: any, index: number) => (
            <div key={index} className="mt-1 flex items-center gap-2.5">
              <div className="h-2 w-2 rounded-full" style={{ backgroundColor: entry.fill }} />
              <span className="text-[11px] font-medium text-[#5f6368]">{entry.name}:</span>
              <span className="ml-auto text-[12px] font-semibold text-[#202124]">{entry.value}</span>
            </div>
          ))}
        </div>
      );
    }
    return null;
  };

  return (
    <div className="relative flex h-[320px] w-full flex-col overflow-hidden rounded-[2.5rem] border border-slate-200/50 bg-white/70 shadow-[0_25px_50px_-12px_rgba(0,0,0,0.08)] transition-shadow duration-500 hover:shadow-[0_40px_80px_-18px_rgba(0,0,0,0.12)]">
      <div className="relative z-10 flex items-center justify-between border-b border-slate-100/60 px-7 py-6">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-[#e8f0fe] text-[#1a73e8] shadow-sm ring-4 ring-blue-50/50">
            <Activity className="h-5 w-5" />
          </div>
          <div>
            <h2 className="text-base font-semibold leading-none tracking-tight text-[#202124]">实时任务态势</h2>
            <p className="mt-1.5 text-xs font-medium text-[#5f6368]">
              今日调度任务状态
            </p>
          </div>
        </div>

        <button
          onClick={onRefresh}
          disabled={loading}
          className="flex h-9 w-9 items-center justify-center rounded-full text-[#5f6368] transition-colors hover:bg-slate-100 hover:text-[#202124] disabled:cursor-not-allowed disabled:opacity-50"
          aria-label="刷新实时任务态势"
        >
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
        </button>
      </div>

      <div className="relative z-10 flex min-h-[180px] w-full flex-1 flex-col justify-center px-6 pb-6 pt-5">
        {loading ? (
          <div className="flex h-full items-center justify-center">
            <RefreshCw className="h-7 w-7 animate-spin text-[#1a73e8]" />
          </div>
        ) : chartData.length === 0 ? (
          <div className="flex h-full flex-col items-center justify-center gap-3 text-center">
            <div className="flex h-12 w-12 items-center justify-center rounded-full bg-slate-100">
              <Box className="h-5 w-5 text-[#5f6368]" />
            </div>
            <div>
              <p className="text-sm font-semibold text-[#3c4043]">所有系统静默待命</p>
              <p className="mt-1 text-xs font-medium text-[#5f6368]">今日暂无调度任务</p>
            </div>
          </div>
        ) : chartData.length <= 4 ? (
          <div className={`grid h-full w-full max-h-[220px] place-content-center overflow-y-auto px-1 pb-1 ${
            chartData.length === 1 ? 'mx-auto w-full max-w-[560px] grid-cols-1 gap-0' :
            chartData.length === 2 ? 'mx-auto max-w-[720px] grid-cols-2 gap-4' :
            chartData.length === 3 ? 'mx-auto max-w-[1000px] grid-cols-3 gap-4' :
            'mx-auto max-w-full grid-cols-2 gap-4 md:grid-cols-4'
          }`}>
            {chartData.map((sys) => {
              const total = sys.completed + sys.running + sys.failed;
              const completedPct = total === 0 ? 0 : (sys.completed / total) * 100;
              const runningPct = total === 0 ? 0 : (sys.running / total) * 100;
              const failedPct = total === 0 ? 0 : (sys.failed / total) * 100;
              const hasFailed = sys.failed > 0;

              return (
                <div 
                  key={sys.systemId}
                  onClick={() => handleBarClick(sys)}
                  className={`group/card flex cursor-pointer overflow-hidden rounded-[2rem] border bg-white/75 transition-all duration-300 hover:-translate-y-0.5 hover:border-slate-300 hover:bg-white hover:shadow-[0_18px_36px_-18px_rgba(15,23,42,0.24)] ${
                    hasFailed ? 'border-red-200/70' : 'border-slate-200/70'
                  } ${
                    chartData.length === 1 ? 'w-full flex-row items-center gap-6 p-5' : 'h-full flex-col justify-between p-4'
                  }`}
                >
                  <div className={`flex ${chartData.length === 1 ? 'min-w-[140px] flex-col' : 'mb-4 items-start justify-between'}`}>
                    <div className="min-w-0">
                      <h3 className={`line-clamp-2 font-semibold leading-tight text-[#202124] ${chartData.length === 1 ? 'max-w-[200px] text-lg' : 'max-w-[150px] text-sm'}`}>{sys.name}</h3>
                      <p className="mt-1 text-xs font-medium text-[#5f6368]">
                        今日任务数 <span className="font-semibold text-[#202124]">{total}</span>
                      </p>
                    </div>
                    {chartData.length !== 1 && (
                      <div className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-full transition-colors ${
                        hasFailed ? 'bg-[#fce8e6] text-[#d93025]' : 'bg-[#e8f0fe] text-[#1a73e8]'
                      }`}>
                        <Activity size={14} />
                      </div>
                    )}
                  </div>
                  
                  <div className={`flex w-full flex-col ${chartData.length === 1 ? 'flex-1 gap-3 border-l border-slate-100 pl-6' : 'gap-3'}`}>
                    <div className="grid grid-cols-3 gap-2">
                      <div className="rounded-2xl bg-[#e6f4ea] px-2 py-2 text-center">
                        <span className={`block font-semibold leading-none text-[#188038] ${chartData.length === 1 ? 'text-2xl' : 'text-xl'}`}>{sys.completed}</span>
                        <span className="mt-1 block text-[10px] font-medium text-[#188038]">完成</span>
                      </div>
                      <div className="rounded-2xl bg-[#e8f0fe] px-2 py-2 text-center">
                        <span className={`block font-semibold leading-none text-[#1a73e8] ${chartData.length === 1 ? 'text-2xl' : 'text-xl'}`}>{sys.running}</span>
                        <span className="mt-1 block text-[10px] font-medium text-[#1a73e8]">运行</span>
                      </div>
                      <div className={`rounded-2xl px-2 py-2 text-center ${hasFailed ? 'bg-[#fce8e6]' : 'bg-slate-50'}`}>
                        <span className={`block font-semibold leading-none ${hasFailed ? 'text-[#d93025]' : 'text-[#5f6368]'} ${chartData.length === 1 ? 'text-2xl' : 'text-xl'}`}>{sys.failed}</span>
                        <span className={`mt-1 block text-[10px] font-medium ${hasFailed ? 'text-[#d93025]' : 'text-[#5f6368]'}`}>失败</span>
                      </div>
                    </div>

                    <div className="flex items-center gap-3">
                      <div className={`flex flex-1 overflow-hidden rounded-full bg-slate-100 ${chartData.length === 1 ? 'h-2' : 'h-1.5'}`}>
                        {completedPct > 0 && <div style={{ width: `${completedPct}%`, backgroundColor: MATERIAL_COLORS.completedText }} className="transition-all duration-500" />}
                        {runningPct > 0 && <div style={{ width: `${runningPct}%`, backgroundColor: MATERIAL_COLORS.runningText }} className="transition-all duration-500" />}
                        {failedPct > 0 && <div style={{ width: `${failedPct}%`, backgroundColor: MATERIAL_COLORS.failedText }} className="transition-all duration-500" />}
                      </div>
                      <span className="w-9 text-right text-[11px] font-semibold tabular-nums text-[#5f6368]">{Math.round(completedPct)}%</span>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        ) : (
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={chartData} margin={{ top: 10, right: 12, left: -20, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#edf0f5" vertical={false} />
              <XAxis
                dataKey="name"
                axisLine={false}
                tickLine={false}
                tick={{ fill: MATERIAL_COLORS.neutralText, fontSize: 11, fontWeight: 500, cursor: 'pointer' }}
                dy={10}
              />
              <YAxis hide />
              <Tooltip content={<CustomTooltip />} cursor={{ fill: 'rgba(26,115,232,0.06)', radius: 8 }} />
              <Bar dataKey="completed" name="已完成" stackId="a" fill={MATERIAL_COLORS.completed} barSize={18} radius={[0, 0, 0, 0]} style={{ cursor: 'pointer' }} onClick={handleBarClick} />
              <Bar dataKey="running" name="运行中" stackId="a" fill={MATERIAL_COLORS.running} barSize={18} radius={[0, 0, 0, 0]} style={{ cursor: 'pointer' }} onClick={handleBarClick} />
              <Bar dataKey="failed" name="已失败" stackId="a" fill={MATERIAL_COLORS.failed} barSize={18} radius={[8, 8, 0, 0]} style={{ cursor: 'pointer' }} onClick={handleBarClick} />
            </BarChart>
          </ResponsiveContainer>
        )}
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
                className="absolute inset-0 bg-slate-900/40"
                onClick={closeDetails}
              />
              <motion.div
                initial={{ opacity: 0, scale: 0.95, y: 20 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.95, y: 20 }}
                className="relative z-10 mx-4 flex max-h-[85vh] w-full max-w-2xl flex-col overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl"
              >
                <div className="flex items-center justify-between border-b border-slate-100 px-6 py-5">
                  <div>
                    <h3 className="text-lg font-semibold tracking-tight text-[#202124]">今日任务明细</h3>
                    <p className="mt-1 text-xs font-medium text-[#5f6368]">{selectedSystemName}</p>
                  </div>
                  <button
                    onClick={closeDetails}
                    className="flex h-9 w-9 items-center justify-center rounded-full text-[#5f6368] transition-colors hover:bg-slate-100 hover:text-[#202124]"
                    aria-label="关闭任务明细"
                  >
                    <X size={20} />
                  </button>
                </div>
                <div className="overflow-y-auto p-6">
                  {loadingDetails ? (
                    <div className="flex h-32 items-center justify-center">
                      <RefreshCw className="h-6 w-6 animate-spin text-[#1a73e8]" />
                    </div>
                  ) : details.length === 0 ? (
                    <div className="py-10 text-center text-sm font-medium text-[#5f6368]">
                      当日暂无任务运行记录
                    </div>
                  ) : (
                    <div className="space-y-3">
                      {details.map((task) => (
                        <div key={task.id} className="flex items-center justify-between rounded-2xl border border-slate-100 bg-white p-4 shadow-sm transition-colors hover:border-slate-200 hover:bg-[#f8fafd]">
                          <div className="flex min-w-0 flex-col gap-1">
                            <span className="truncate text-sm font-semibold text-[#202124]">{task.taskName}</span>
                            <span className="flex flex-wrap gap-x-3 gap-y-1 text-[11px] font-medium text-[#5f6368]">
                              <span>数据日期: {task.dataDate || '-'}</span>
                              <span>开始: {task.startTime ? new Date(task.startTime).toLocaleTimeString() : '-'}</span>
                              <span>结束: {task.endTime ? new Date(task.endTime).toLocaleTimeString() : '-'}</span>
                            </span>
                          </div>
                          <span className={`ml-4 shrink-0 rounded-full border px-3 py-1 text-xs font-medium ${getStatusChipClass(task.taskStatus)}`}>
                            {getStatusLabel(task.taskStatus)}
                          </span>
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
