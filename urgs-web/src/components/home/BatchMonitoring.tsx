import React, { useEffect, useState } from 'react';
import { Server, Activity, CheckCircle, Cpu, AlertCircle, Clock, PieChart as PieChartIcon } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, AreaChart, Area, BarChart, Bar, Legend } from 'recharts';
import { fetchDailyStats, fetchHourlyThroughput, fetchWorkflowStats, TaskInstanceStatsVO, WorkflowStatsVO } from '../../api/stats';

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

const BatchMonitoring: React.FC = () => {
    const [stats, setStats] = useState<TaskInstanceStatsVO | null>(null);
    const [hourlyData, setHourlyData] = useState<any[]>([]);
    const [workflowStats, setWorkflowStats] = useState<WorkflowStatsVO[]>([]);
    const [currentTime, setCurrentTime] = useState(new Date());

    const loadData = async () => {
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
    };

    useEffect(() => {
        loadData();
        const timer = setInterval(() => setCurrentTime(new Date()), 1000);
        const dataTimer = setInterval(loadData, 30000); // Refresh every 30s
        return () => {
            clearInterval(timer);
            clearInterval(dataTimer);
        };
    }, []);

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

    return (
        <div className="min-h-screen bg-slate-50/30 text-slate-900 px-8 pb-8 pt-6 font-sans selection:bg-red-100 selection:text-red-900">
            {/* Header */}
            <div className="flex justify-between items-end mb-10">
                <div className="relative">
                    <div className="absolute -left-4 top-0 w-1 h-full bg-red-600 rounded-full" />
                    <h1 className="text-4xl font-black text-slate-900 tracking-tighter uppercase italic">
                        Batch <span className="text-red-600">Monitoring</span>
                    </h1>
                    <div className="flex items-center gap-2 mt-2">
                        <div className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse shadow-[0_0_8px_rgba(16,185,129,0.5)]" />
                        <span className="text-xs text-slate-400 font-bold uppercase tracking-widest">System Online</span>
                    </div>
                </div>
                <div className="flex flex-col items-end">
                    <div className="text-3xl font-black text-slate-800 tabular-nums tracking-tighter">
                        {currentTime.toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit' })}
                    </div>
                    <div className="text-[10px] text-slate-400 font-black uppercase tracking-[0.2em] mt-1 bg-slate-100 px-2 py-0.5 rounded">
                        {currentTime.toLocaleDateString('zh-CN', { weekday: 'long', month: 'short', day: 'numeric' })}
                    </div>
                </div>
            </div>

            {/* KPI Grid (Bento Box Style) */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-5 mb-6">
                <KpiCard
                    title="总任务数"
                    value={stats?.total || 0}
                    icon={<Server className="w-6 h-6" />}
                    color="gray"
                    subValue="Total Tasks"
                />
                <KpiCard
                    title="正在运行"
                    value={stats?.running || 0}
                    icon={<Activity className="w-6 h-6" />}
                    color="blue"
                    subValue="Running"
                    animate
                />
                <KpiCard
                    title="等待中"
                    value={stats?.waiting || 0}
                    icon={<Clock className="w-6 h-6" />}
                    color="purple"
                    subValue="Pending"
                />
                <KpiCard
                    title="失败任务"
                    value={stats?.failed || 0}
                    icon={<AlertCircle className="w-6 h-6" />}
                    color="red"
                    subValue="Attention Needed"
                    isAlert={stats?.failed > 0}
                />
                <KpiCard
                    title="成功率"
                    value={`${(stats?.successRate || 0).toFixed(1)}%`}
                    icon={<CheckCircle className="w-6 h-6" />}
                    color="green"
                    subValue="Success Rate"
                />
            </div>

            {/* Main Content Grid */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Workflow Stats Chart */}
                <div className="relative lg:col-span-2 bg-white/70 backdrop-blur-md rounded-[2.5rem] p-8 shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-slate-200/50 hover:shadow-[0_20px_40px_rgba(0,0,0,0.06)] transition-all duration-500 group overflow-hidden">
                    <div className="absolute top-0 left-0 w-full h-1.5 bg-gradient-to-r from-red-600 via-red-400 to-transparent opacity-40" />
                    <div className="flex justify-between items-center mb-10">
                        <div className="flex flex-col">
                            <h3 className="text-xl font-black text-slate-800 tracking-tight">
                                工作流执行概览
                            </h3>
                            <span className="text-[10px] text-slate-400 font-bold uppercase tracking-widest mt-1">Workflow Execution View</span>
                        </div>
                        <div className="p-3 bg-slate-50 rounded-2xl border border-slate-100 shadow-inner group-hover:scale-110 transition-transform duration-500">
                            <Activity className="w-5 h-5 text-red-600" />
                        </div>
                    </div>
                    <div className="h-[340px]">
                        <ResponsiveContainer width="100%" height="100%">
                            <BarChart data={workflowStats.map(stat => ({
                                ...stat,
                                remaining: Math.max(0, stat.total - stat.success - stat.failed)
                            }))} barCategoryGap="30%">
                                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#F1F5F9" />
                                <XAxis
                                    dataKey="workflowName"
                                    stroke="#94A3B8"
                                    fontSize={10}
                                    fontWeight={800}
                                    tickLine={false}
                                    axisLine={false}
                                    interval={0}
                                    angle={-15}
                                    textAnchor="end"
                                    height={60}
                                    tickMargin={12}
                                />
                                <YAxis
                                    stroke="#94A3B8"
                                    fontSize={10}
                                    fontWeight={800}
                                    tickLine={false}
                                    axisLine={false}
                                />
                                <Tooltip content={<CustomTooltip />} cursor={{ fill: 'rgba(241, 245, 249, 0.5)', radius: 12 }} />
                                <Legend
                                    iconType="circle"
                                    layout="horizontal"
                                    verticalAlign="top"
                                    align="right"
                                    iconSize={8}
                                    wrapperStyle={{ paddingBottom: '30px', fontSize: '11px', fontWeight: 800, color: '#64748B' }}
                                />
                                <Bar dataKey="success" name="成功" stackId="a" fill="#10B981" radius={[0, 0, 0, 0]} animationDuration={1000} barSize={32} />
                                <Bar dataKey="failed" name="失败" stackId="a" fill="#EF4444" radius={[0, 0, 0, 0]} animationDuration={1000} barSize={32} />
                                <Bar dataKey="remaining" name="剩余" stackId="a" fill="#F1F5F9" radius={[8, 8, 0, 0]} animationDuration={1000} barSize={32} />
                            </BarChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                {/* Status Distribution */}
                <div className="relative bg-white/70 backdrop-blur-md rounded-[2.5rem] p-8 shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-slate-200/50 hover:shadow-[0_20px_40px_rgba(0,0,0,0.06)] transition-all duration-500 group overflow-hidden">
                    <div className="absolute top-0 right-0 w-1.5 h-full bg-gradient-to-b from-blue-600 via-purple-400 to-transparent opacity-40" />
                    <div className="flex flex-col mb-10">
                        <h3 className="text-xl font-black text-slate-800 tracking-tight">
                            状态分布
                        </h3>
                        <span className="text-[10px] text-slate-400 font-bold uppercase tracking-widest mt-1">Status Distribution</span>
                    </div>

                    <div className="h-[260px] relative mt-2">
                        <ResponsiveContainer width="100%" height="100%">
                            <PieChart>
                                <Pie
                                    data={statusDataFixed}
                                    cx="50%"
                                    cy="50%"
                                    innerRadius={80}
                                    outerRadius={105}
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
                            <span className="text-4xl font-black text-slate-900 tracking-tighter">{stats?.total || 0}</span>
                            <span className="text-[10px] text-slate-400 font-black uppercase tracking-widest mt-0.5">Total</span>
                        </div>
                    </div>

                    <div className="mt-8 flex flex-col gap-4">
                        {statusDataFixed.map(item => (
                            <div key={item.name} className="flex flex-col gap-1.5 group/item">
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
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
};

// Simplified Apple-style Card
const KpiCard = ({ title, value, icon, color, subValue, animate, isAlert }: any) => {
    const colorStyles: any = {
        gray: { text: 'text-slate-600', bgIcon: 'bg-slate-50 text-slate-600', ring: 'ring-slate-100', glow: 'from-slate-100/30' },
        blue: { text: 'text-blue-600', bgIcon: 'bg-blue-50 text-blue-600', ring: 'ring-blue-100', glow: 'from-blue-100/30' },
        purple: { text: 'text-purple-600', bgIcon: 'bg-indigo-50 text-indigo-600', ring: 'ring-indigo-100', glow: 'from-indigo-100/30' },
        red: { text: 'text-red-600', bgIcon: 'bg-red-50 text-red-600', ring: 'ring-red-100', glow: 'from-red-100/30' },
        green: { text: 'text-emerald-600', bgIcon: 'bg-emerald-50 text-emerald-600', ring: 'ring-emerald-100', glow: 'from-emerald-100/30' },
    };

    const style = colorStyles[color] || colorStyles.gray;

    return (
        <div className={`relative bg-white/70 backdrop-blur-md rounded-[2rem] p-6 shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-slate-200/50 hover:shadow-[0_20px_40px_rgba(0,0,0,0.06)] hover:-translate-y-1.5 transition-all duration-500 overflow-hidden group ${isAlert ? 'ring-2 ring-red-400/30' : ''}`}>
            {/* Background Glow */}
            <div className={`absolute -inset-1 bg-gradient-to-br ${style.glow} to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-700`} />

            <div className="relative flex items-center justify-between mb-6">
                <div className={`p-3 rounded-2xl ${style.bgIcon} border border-white shadow-sm ring-4 ${style.ring} group-hover:rotate-12 transition-all duration-500`}>
                    {React.cloneElement(icon, { strokeWidth: 2.5, className: 'w-5 h-5' })}
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
                <span className={`text-3xl font-black text-slate-900 tracking-tighter tabular-nums ${isAlert && value > 0 ? 'text-red-600 animate-pulse' : ''}`}>{value}</span>
            </div>

            <div className="relative mt-4 pt-4 border-t border-slate-100/50 flex items-center justify-between">
                <span className="text-[9px] font-bold text-slate-400 uppercase tracking-tight">{subValue}</span>
                <div className="w-1.5 h-1.5 rounded-full bg-slate-200 group-hover:bg-red-500 transition-colors duration-500" />
            </div>
        </div>
    );
};

export default BatchMonitoring;

