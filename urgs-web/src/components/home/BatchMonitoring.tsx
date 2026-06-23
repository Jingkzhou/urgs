import React, { useCallback, useState } from 'react';
import { Server, Activity, CheckCircle, Cpu, AlertCircle, Clock, PieChart as PieChartIcon } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, AreaChart, Area, BarChart, Bar, LabelList } from 'recharts';
import { fetchDailyStats, fetchHourlyThroughput, fetchWorkflowStats, TaskInstanceStatsVO, WorkflowStatsVO } from '../../api/stats';
import { useSmartPolling } from '../../hooks/useSmartPolling';

// Placeholder for Task Instance type
interface TaskInstance {
    id: string;
    taskId: string;
    status: string;
    progress?: number;
    startTime?: string;
    endTime?: string;
    logContent?: string;
}

const OPS_REGULATION_NAV_KEY = 'ops_regulation_nav';

const taskInstanceStatusMap: Record<string, string> = {
    WAITING_GROUP: '1',
    RUNNING: '2',
    SUCCESS: '3',
    FAIL: '4',
};

interface BatchMonitoringProps {
    density?: 'default' | 'compact';
}

const BatchMonitoring: React.FC<BatchMonitoringProps> = ({ density = 'default' }) => {
    const [stats, setStats] = useState<TaskInstanceStatsVO | null>(null);
    const [hourlyData, setHourlyData] = useState<any[]>([]);
    const [workflowStats, setWorkflowStats] = useState<WorkflowStatsVO[]>([]);
    const isCompact = density === 'compact';

    const loadData = useCallback(async () => {
        try {
            const [dailyStats, hourly, wfStats] = await Promise.all([
                fetchDailyStats(),
                fetchHourlyThroughput(),
                fetchWorkflowStats()
            ]);

            if (dailyStats) setStats(dailyStats);
            if (hourly) setHourlyData(hourly);
            if (wfStats) setWorkflowStats(wfStats);
        } catch (e) {
            console.error("Failed to load dashboard data", e);
        }
    }, []);

    useSmartPolling(loadData, 30000);

    const navigateToTaskInstance = (status?: string) => {
        sessionStorage.setItem(OPS_REGULATION_NAV_KEY, JSON.stringify({
            module: 'regulation',
            view: 'task-instance',
            filters: status ? { status: taskInstanceStatusMap[status] || status } : {}
        }));
        window.location.href = '#/ops';
    };

    // Derived Data for Charts
    const statusData = stats ? [
        { name: '成功', value: stats.success, color: '#34C759' }, // Apple Green
        { name: '失败', value: stats.failed, color: '#FF3B30' },   // Apple Red
        { name: '运行中', value: stats.running, color: '#007AFF' }, // Apple Blue
        { name: '等待中', value: stats.waiting, color: '#FF9500' }, // Apple Orange (using for waiting usually) or Indigo
    ] : [];

    // Use Indigo for waiting if preferred, but Orange is distinct. Let's start with Indigo to match previous if desired, but Apple Orange is nice for 'waiting'.
    // Actually let's stick to the color map in statusData for consistency.
    // waiting -> Indigo in previous, let's switch to a softer "Apple" indigo/purple or use Gray.
    // Let's use: Success=Green, Failed=Red, Running=Blue, Waiting=Purple (#AF52DE)

    const statusDataFixed = stats ? [
        { name: '成功', value: stats.success, color: '#34C759' },
        { name: '失败', value: stats.failed, color: '#FF3B30' },
        { name: '运行中', value: stats.running, color: '#007AFF' },
        { name: '等待中', value: stats.waiting, color: '#AF52DE' },
    ] : [];

    const workflowChartData = workflowStats.map(stat => ({
        ...stat,
        completed: stat.success + stat.failed,
        totalLabel: `总 ${Number(stat.total || 0)}`
    }));

    const workflowRowHeight = isCompact ? 34 : 38;
    const workflowChartContentHeight = workflowChartData.length
        ? Math.max(isCompact ? 112 : 136, workflowChartData.length * workflowRowHeight + 44)
        : isCompact ? 92 : 118;
    const workflowChartViewportHeight = workflowChartData.length
        ? Math.min(isCompact ? 260 : 360, workflowChartContentHeight)
        : workflowChartContentHeight;


    const CustomTooltip = ({ active, payload, label }: any) => {
        if (active && payload && payload.length) {
            return (
                <div className="bg-white/80 backdrop-blur-md border border-slate-200/50 p-3 rounded-2xl shadow-xl">
                    <p className="text-[11px] font-black text-slate-800 mb-2 border-b border-slate-100 pb-1 lowercase tracking-tight">{label}</p>
                    {payload.map((entry: any, index: number) => (
                        <div key={index} className="flex items-center gap-3 mt-1.5">
                            <div className="w-2 h-2 rounded-full shadow-[0_0_5px_rgba(0,0,0,0.1)]" style={{ backgroundColor: entry.color || entry.fill }} />
                            <span className="text-[11px] text-slate-500 font-bold">{entry.name}:</span>
                            <span className="text-[11px] font-black text-slate-900 ml-auto tabular-nums">{entry.value}</span>
                        </div>
                    ))}
                </div>
            );
        }
        return null;
    };

    const renderWorkflowBarValue = ({ x, y, width, height, value }: any) => {
        const numberValue = Number(value || 0);
        if (!numberValue || width < 20) return null;

        return (
            <text
                x={x + width / 2}
                y={y + height / 2}
                textAnchor="middle"
                dominantBaseline="central"
                fill="#FFFFFF"
                fontSize={11}
                fontWeight={900}
            >
                {numberValue}
            </text>
        );
    };

    return (
        <div className="text-slate-900 font-sans selection:bg-red-100 selection:text-red-900">
            {/* Header Removed to match Dashboard Section styling */}

            {/* KPI Grid (Bento Box Style) */}
            <div className={`grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 ${isCompact ? 'gap-3 mb-4' : 'gap-5 mb-6'}`}>
                <KpiCard
                    title="总任务数"
                    value={stats?.total || 0}
                    icon={<Server className="w-6 h-6" />}
                    color="gray"
                    subValue="Total Tasks"
                    compact={isCompact}
                />
                <KpiCard
                    title="正在运行"
                    value={stats?.running || 0}
                    icon={<Activity className="w-6 h-6" />}
                    color="blue"
                    subValue="Running"
                    animate
                    onClick={() => navigateToTaskInstance('RUNNING')}
                    compact={isCompact}
                />
                <KpiCard
                    title="等待中"
                    value={stats?.waiting || 0}
                    icon={<Clock className="w-6 h-6" />}
                    color="purple"
                    subValue="Pending"
                    onClick={() => navigateToTaskInstance('WAITING_GROUP')}
                    compact={isCompact}
                />
                <KpiCard
                    title="失败任务"
                    value={stats?.failed || 0}
                    icon={<AlertCircle className="w-6 h-6" />}
                    color="red"
                    subValue="Attention Needed"
                    isAlert={stats?.failed > 0}
                    onClick={() => navigateToTaskInstance('FAIL')}
                    compact={isCompact}
                />
                <KpiCard
                    title="成功率"
                    value={`${(stats?.successRate || 0).toFixed(1)}%`}
                    icon={<CheckCircle className="w-6 h-6" />}
                    color="green"
                    subValue="Success Rate"
                    compact={isCompact}
                />
            </div>

            {/* Main Content Grid */}
            <div className={`grid grid-cols-1 lg:grid-cols-3 ${isCompact ? 'gap-4' : 'gap-8'}`}>
                {/* Workflow Stats Chart */}
                <div className={`relative lg:col-span-2 bg-white/80 backdrop-blur-md ${isCompact ? 'rounded-[1.5rem] p-4' : 'rounded-[2rem] p-6'} shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-slate-200/60 hover:shadow-[0_18px_34px_rgba(15,23,42,0.06)] transition-all duration-500 group overflow-hidden`}>
                    <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-red-500 via-rose-300 to-transparent opacity-50" />
                    <div className={`flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between ${isCompact ? 'mb-3' : 'mb-5'}`}>
                        <div className="flex flex-col">
                            <div className="flex flex-wrap items-center gap-2">
                                <h3 className={`${isCompact ? 'text-lg' : 'text-xl'} font-black text-slate-800 tracking-tight`}>
                                    工作流执行概览
                                </h3>
                                {workflowChartData.length > 0 && (
                                    <span className="rounded-full border border-slate-200 bg-white/70 px-2 py-0.5 text-[10px] font-bold text-slate-500">
                                        共 {workflowChartData.length} 套系统
                                    </span>
                                )}
                            </div>
                            <span className="text-[10px] text-slate-400 font-bold uppercase tracking-widest mt-1">Workflow Execution</span>
                        </div>
                        <div className="flex flex-wrap items-center gap-2.5">
                            <div className="flex items-center gap-2 rounded-full border border-emerald-100 bg-emerald-50/80 px-2.5 py-1">
                                <span className="h-2 w-2 rounded-full bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.35)]" />
                                <span className="text-[11px] font-bold text-slate-500">成功</span>
                            </div>
                            <div className="flex items-center gap-2 rounded-full border border-rose-100 bg-rose-50/80 px-2.5 py-1">
                                <span className="h-2 w-2 rounded-full bg-rose-500 shadow-[0_0_8px_rgba(244,63,94,0.35)]" />
                                <span className="text-[11px] font-bold text-slate-500">失败</span>
                            </div>
                            <div className={`${isCompact ? 'h-8 w-8 rounded-xl' : 'h-9 w-9 rounded-2xl'} hidden sm:flex items-center justify-center bg-slate-50 border border-slate-100 shadow-inner`}>
                                <Activity className="h-4 w-4 text-red-600" />
                            </div>
                        </div>
                    </div>
                    <div className={`${isCompact ? 'rounded-2xl p-2' : 'rounded-[1.5rem] p-3'} w-full min-w-0 overflow-hidden border border-slate-100 bg-slate-50/60`}>
                        {workflowChartData.length ? (
                            <div className="overflow-auto pr-1" style={{ maxHeight: workflowChartViewportHeight }}>
                                <div style={{ height: workflowChartContentHeight, minWidth: 560 }}>
                                    <ResponsiveContainer width="100%" height="100%" minWidth={1} minHeight={1}>
                                        <BarChart
                                            data={workflowChartData}
                                            layout="vertical"
                                            barCategoryGap={isCompact ? 12 : 14}
                                            margin={{ top: 8, right: 38, left: 4, bottom: 4 }}
                                        >
                                            <defs>
                                                <linearGradient id="barSuccessGrad" x1="0" y1="0" x2="0" y2="1">
                                                    <stop offset="0%" stopColor="#34D399" />
                                                    <stop offset="100%" stopColor="#059669" />
                                                </linearGradient>
                                                <linearGradient id="barFailedGrad" x1="0" y1="0" x2="0" y2="1">
                                                    <stop offset="0%" stopColor="#FB7185" />
                                                    <stop offset="100%" stopColor="#E11D48" />
                                                </linearGradient>
                                            </defs>
                                            <CartesianGrid strokeDasharray="3 3" horizontal={false} stroke="#E2E8F0" />
                                            <XAxis
                                                type="number"
                                                stroke="#94A3B8"
                                                fontSize={10}
                                                fontWeight={700}
                                                tickLine={false}
                                                axisLine={false}
                                                allowDecimals={false}
                                                domain={[0, (dataMax: number) => Math.max(dataMax, 1)]}
                                            />
                                            <YAxis
                                                dataKey="workflowName"
                                                type="category"
                                                stroke="#94A3B8"
                                                fontSize={10}
                                                fontWeight={700}
                                                tickLine={false}
                                                axisLine={false}
                                                interval={0}
                                                width={isCompact ? 128 : 156}
                                                tickMargin={8}
                                                tickFormatter={(value: string) => value.length > (isCompact ? 10 : 14) ? `${value.slice(0, isCompact ? 10 : 14)}...` : value}
                                            />
                                            <Tooltip content={<CustomTooltip />} cursor={{ fill: 'rgba(241, 245, 249, 0.5)', radius: 10 }} />
                                            <Bar dataKey="success" name="成功" stackId="a" fill="url(#barSuccessGrad)" radius={[8, 0, 0, 8]} animationDuration={800} barSize={isCompact ? 14 : 16}>
                                                <LabelList dataKey="success" content={renderWorkflowBarValue} />
                                            </Bar>
                                            <Bar dataKey="failed" name="失败" stackId="a" fill="url(#barFailedGrad)" radius={[0, 8, 8, 0]} animationDuration={800} barSize={isCompact ? 14 : 16}>
                                                <LabelList dataKey="failed" content={renderWorkflowBarValue} />
                                                <LabelList dataKey="totalLabel" position="right" fill="#64748B" fontSize={11} fontWeight={800} />
                                            </Bar>
                                        </BarChart>
                                    </ResponsiveContainer>
                                </div>
                            </div>
                        ) : (
                            <div className={`${isCompact ? 'h-[92px]' : 'h-[118px]'} flex items-center justify-center rounded-2xl border border-dashed border-slate-200 bg-white/70`}>
                                <span className="text-[11px] font-bold text-slate-400">暂无工作流执行数据</span>
                            </div>
                        )}
                    </div>
                </div>

                {/* Status Distribution */}
                <div className={`relative bg-white/70 backdrop-blur-md ${isCompact ? 'rounded-[1.75rem] p-5' : 'rounded-[2.5rem] p-8'} shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-slate-200/50 hover:shadow-[0_20px_40px_rgba(0,0,0,0.06)] transition-all duration-500 group overflow-hidden`}>
                    <div className="absolute top-0 right-0 w-1.5 h-full bg-gradient-to-b from-blue-600 via-purple-400 to-transparent opacity-40" />
                    <div className={`flex flex-col ${isCompact ? 'mb-3' : 'mb-10'}`}>
                        <h3 className={`${isCompact ? 'text-lg' : 'text-xl'} font-black text-slate-800 tracking-tight`}>
                            状态分布
                        </h3>
                        <span className="text-[10px] text-slate-400 font-bold uppercase tracking-widest mt-1">Status Distribution</span>
                    </div>

                    <div className={`${isCompact ? 'h-[125px]' : 'h-[260px]'} w-full min-w-0 overflow-hidden relative mt-2`}>
                        <ResponsiveContainer width="100%" height="100%" minWidth={1} minHeight={1}>
                            <PieChart>
                                <Pie
                                    data={statusDataFixed}
                                    cx="50%"
                                    cy="50%"
                                    innerRadius={isCompact ? 38 : 80}
                                    outerRadius={isCompact ? 56 : 105}
                                    paddingAngle={6}
                                    dataKey="value"
                                    stroke="none"
                                    animationDuration={1000}
                                    animationBegin={0}
                                    cornerRadius={8}
                                >
                                    {statusDataFixed.map((entry, index) => (
                                        <Cell key={`cell-${index}`} fill={entry.color} />
                                    ))}
                                </Pie>
                                <Tooltip content={<CustomTooltip />} />
                            </PieChart>
                        </ResponsiveContainer>
                        {/* Center Text */}
                        <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                            <span className={`${isCompact ? 'text-2xl' : 'text-4xl'} font-black text-slate-900 tracking-tighter`}>{stats?.total || 0}</span>
                            <span className="text-[10px] text-slate-400 font-black uppercase tracking-widest mt-0.5">Total</span>
                        </div>
                    </div>

                    <div className={`${isCompact ? 'mt-3 gap-1.5' : 'mt-8 gap-4'} flex flex-col`}>
                        {statusDataFixed.map(item => (
                            <button
                                key={item.name}
                                type="button"
                                onClick={() => navigateToTaskInstance(
                                    item.name === '成功' ? 'SUCCESS' :
                                        item.name === '失败' ? 'FAIL' :
                                            item.name === '运行中' ? 'RUNNING' :
                                                'WAITING_GROUP'
                                )}
                                className={`flex flex-col group/item text-left rounded-2xl ${isCompact ? 'gap-1 p-1.5 -mx-1.5' : 'gap-1.5 p-2 -mx-2'} hover:bg-slate-50/80 transition-colors`}
                            >
                                <div className="flex items-center justify-between">
                                    <div className="flex items-center gap-3">
                                        <div className="w-2.5 h-2.5 rounded-full shadow-[0_0_8px_rgba(0,0,0,0.1)] transition-transform group-hover/item:scale-125" style={{ backgroundColor: item.color }} />
                                        <span className="text-[11px] text-slate-600 font-black uppercase tracking-tight">{item.name}</span>
                                    </div>
                                    <span className="text-xs font-black text-slate-900 tabular-nums">{item.value}</span>
                                </div>
                                <div className="w-full h-1.5 bg-slate-100/50 rounded-full overflow-hidden shadow-inner border border-slate-50">
                                    <div
                                        className="h-full rounded-full transition-all duration-1000 ease-out"
                                        style={{
                                            width: `${stats?.total ? (item.value / stats.total) * 100 : 0}%`,
                                            backgroundColor: item.color,
                                            boxShadow: `0 0 10px ${item.color}40`
                                        }}
                                    ></div>
                                </div>
                            </button>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
};

// Simplified Apple-style Card
const KpiCard = ({ title, value, icon, color, subValue, animate, isAlert, onClick, compact }: any) => {
    const colorStyles: any = {
        gray: { text: 'text-slate-600', bgIcon: 'bg-slate-50 text-slate-600', ring: 'ring-slate-100', glow: 'from-slate-100/30' },
        blue: { text: 'text-blue-600', bgIcon: 'bg-blue-50 text-blue-600', ring: 'ring-blue-100', glow: 'from-blue-100/30' },
        purple: { text: 'text-purple-600', bgIcon: 'bg-indigo-50 text-indigo-600', ring: 'ring-indigo-100', glow: 'from-indigo-100/30' },
        red: { text: 'text-red-600', bgIcon: 'bg-red-50 text-red-600', ring: 'ring-red-100', glow: 'from-red-100/30' },
        green: { text: 'text-emerald-600', bgIcon: 'bg-emerald-50 text-emerald-600', ring: 'ring-emerald-100', glow: 'from-emerald-100/30' },
    };

    const style = colorStyles[color] || colorStyles.gray;

    return (
        <div
            onClick={onClick}
            className={`relative bg-white/70 backdrop-blur-md ${compact ? 'rounded-[1.5rem] p-4' : 'rounded-[2rem] p-6'} shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-slate-200/50 hover:shadow-[0_20px_40px_rgba(0,0,0,0.06)] hover:-translate-y-1.5 transition-all duration-500 overflow-hidden group ${isAlert ? 'ring-2 ring-red-400/30' : ''} ${onClick ? 'cursor-pointer' : ''}`}
        >
            {/* Background Glow */}
            <div className={`absolute -inset-1 bg-gradient-to-br ${style.glow} to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-700`} />

            <div className={`relative flex items-center justify-between ${compact ? 'mb-3' : 'mb-6'}`}>
                <div className={`${compact ? 'p-2 rounded-xl' : 'p-3 rounded-2xl'} ${style.bgIcon} border border-white shadow-sm ring-4 ${style.ring} group-hover:rotate-12 transition-all duration-500`}>
                    {React.cloneElement(icon, { strokeWidth: 2.5, className: compact ? 'w-4 h-4' : 'w-5 h-5' })}
                </div>
                {animate && (
                    <div className="flex items-center gap-1.5 bg-blue-50 px-2 py-1 rounded-full border border-blue-100">
                        <span className="relative flex h-2 w-2">
                            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-blue-400 opacity-75"></span>
                            <span className="relative inline-flex rounded-full h-2 w-2 bg-blue-500"></span>
                        </span>
                        <span className="text-[8px] font-black text-blue-600 uppercase tracking-widest">Active</span>
                    </div>
                )}
            </div>

            <div className="relative flex flex-col">
                <span className="text-[10px] font-black text-slate-400 mb-1 uppercase tracking-widest">{title}</span>
                <span className={`${compact ? 'text-2xl' : 'text-3xl'} font-black text-slate-900 tracking-tighter tabular-nums ${isAlert && value > 0 ? 'text-red-600 animate-pulse' : ''}`}>{value}</span>
            </div>

            <div className={`relative ${compact ? 'mt-2 pt-2' : 'mt-4 pt-4'} border-t border-slate-100/50 flex items-center justify-between`}>
                <span className="text-[9px] font-bold text-slate-400 uppercase tracking-tight">{subValue}</span>
                <div className="w-1.5 h-1.5 rounded-full bg-slate-200 group-hover:bg-red-500 transition-colors duration-500" />
            </div>
        </div>
    );
};

export default BatchMonitoring;
