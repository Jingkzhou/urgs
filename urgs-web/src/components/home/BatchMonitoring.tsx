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


    return (
        <div className="min-h-screen bg-[#F5F5F7] text-slate-900 px-8 pb-8 pt-4  font-sans">
            {/* Header */}
            <div className="flex justify-between items-center mb-8">
                <div>
                    <h1 className="text-3xl font-semibold text-slate-900 tracking-tight">
                        批量监控
                    </h1>
                    <div className="text-sm text-slate-500 font-medium mt-1">
                        System Status: Online
                    </div>
                </div>
                <div className="text-right">
                    <div className="text-xl font-medium text-slate-900 tabular-nums">
                        {currentTime.toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit' })}
                    </div>
                    <div className="text-sm text-slate-500 font-normal">
                        {currentTime.toLocaleDateString('zh-CN', { weekday: 'long', month: 'long', day: 'numeric' })}
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
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Workflow Stats Chart */}
                <div className="lg:col-span-2 bg-white rounded-3xl p-6 shadow-[0_2px_12px_rgba(0,0,0,0.04)] hover:shadow-[0_4px_16px_rgba(0,0,0,0.06)] transition-shadow duration-300">
                    <div className="flex justify-between items-center mb-6">
                        <h3 className="text-lg font-semibold text-slate-900">
                            工作流执行概览
                        </h3>

                    </div>
                    <div className="h-[320px]">
                        <ResponsiveContainer width="100%" height="100%">
                            <BarChart data={workflowStats.map(stat => ({
                                ...stat,
                                remaining: Math.max(0, stat.total - stat.success - stat.failed)
                            }))} barCategoryGap="25%">
                                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E5E5EA" />
                                <XAxis
                                    dataKey="workflowName"
                                    stroke="#8E8E93"
                                    fontSize={11}
                                    tickLine={false}
                                    axisLine={false}
                                    interval={0}
                                    angle={-45}
                                    textAnchor="end"
                                    height={80}
                                    tickMargin={10}
                                />
                                <YAxis stroke="#8E8E93" fontSize={11} tickLine={false} axisLine={false} />
                                <Tooltip
                                    cursor={{ fill: '#F2F2F7', opacity: 0.5 }}
                                    contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}
                                />
                                <Legend
                                    iconType="circle"
                                    layout="horizontal"
                                    verticalAlign="top"
                                    align="right"
                                    wrapperStyle={{ paddingBottom: '20px', fontSize: '12px', color: '#8E8E93' }}
                                />
                                <Bar dataKey="success" name="成功" stackId="a" fill="#34C759" radius={[0, 0, 4, 4]} animationDuration={500} />
                                <Bar dataKey="failed" name="失败" stackId="a" fill="#FF3B30" radius={[0, 0, 0, 0]} animationDuration={500} />
                                <Bar dataKey="remaining" name="剩余" stackId="a" fill="#E5E5EA" radius={[4, 4, 0, 0]} animationDuration={500} />
                            </BarChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                {/* Status Distribution */}
                <div className="bg-white rounded-3xl p-6 shadow-[0_2px_12px_rgba(0,0,0,0.04)] hover:shadow-[0_4px_16px_rgba(0,0,0,0.06)] transition-shadow duration-300">
                    <h3 className="text-lg font-semibold text-slate-900 mb-6">
                        状态分布
                    </h3>
                    <div className="h-[240px] relative">
                        <ResponsiveContainer width="100%" height="100%">
                            <PieChart>
                                <Pie
                                    data={statusDataFixed}
                                    cx="50%"
                                    cy="50%"
                                    innerRadius={70}
                                    outerRadius={90}
                                    paddingAngle={4}
                                    dataKey="value"
                                    stroke="none"
                                    animationDuration={500}
                                    animationBegin={0}
                                >
                                    {statusDataFixed.map((entry, index) => (
                                        <Cell key={`cell-${index}`} fill={entry.color} />
                                    ))}
                                </Pie>
                                <Tooltip
                                    contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}
                                />
                            </PieChart>
                        </ResponsiveContainer>
                        {/* Center Text */}
                        <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                            <span className="text-3xl font-semibold text-slate-900">{stats?.total || 0}</span>
                            <span className="text-xs text-slate-500 font-medium uppercase tracking-wide mt-1">Total</span>
                        </div>
                    </div>

                    <div className="mt-6 flex flex-col gap-3">
                        {statusDataFixed.map(item => (
                            <div key={item.name} className="flex items-center justify-between group">
                                <div className="flex items-center gap-3">
                                    <span className="w-3 h-3 rounded-full shadow-sm" style={{ backgroundColor: item.color }}></span>
                                    <span className="text-sm text-slate-600 font-medium">{item.name}</span>
                                </div>
                                <div className="flex items-center gap-2">
                                    <span className="text-sm font-semibold text-slate-900">{item.value}</span>
                                    <div className="w-16 h-1.5 bg-slate-100 rounded-full overflow-hidden">
                                        <div
                                            className="h-full rounded-full opacity-80"
                                            style={{
                                                width: `${stats?.total ? (item.value / stats.total) * 100 : 0}%`,
                                                backgroundColor: item.color
                                            }}
                                        ></div>
                                    </div>
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
    // Apple System Colors style map
    const colorStyles: any = {
        gray: { text: 'text-slate-500', bgIcon: 'bg-slate-100 text-slate-600' },
        blue: { text: 'text-blue-500', bgIcon: 'bg-blue-100 text-blue-600' },
        purple: { text: 'text-purple-500', bgIcon: 'bg-purple-100 text-purple-600' },
        red: { text: 'text-red-500', bgIcon: 'bg-red-100 text-red-600' },
        green: { text: 'text-green-500', bgIcon: 'bg-green-100 text-green-600' },
    };

    const style = colorStyles[color] || colorStyles.gray;

    return (
        <div className={`bg-white rounded-3xl p-6 shadow-[0_2px_12px_rgba(0,0,0,0.04)] hover:shadow-[0_4px_16px_rgba(0,0,0,0.06)] transition-all duration-300 relative group overflow-hidden ${isAlert ? 'ring-2 ring-red-100' : ''}`}>
            <div className="flex items-start justify-between mb-4">
                <div className={`p-2.5 rounded-full ${style.bgIcon} transition-transform group-hover:scale-110 duration-300`}>
                    {icon}
                </div>
                {animate && (
                    <span className="relative flex h-3 w-3">
                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-blue-400 opacity-75"></span>
                        <span className="relative inline-flex rounded-full h-3 w-3 bg-blue-500"></span>
                    </span>
                )}
            </div>

            <div className="flex flex-col">
                <span className="text-sm font-medium text-slate-500 mb-1">{title}</span>
                <span className="text-3xl font-semibold text-slate-900 tracking-tight">{value}</span>
            </div>
            <div className="mt-3 text-xs font-medium text-slate-400 flex items-center">
                {subValue}
            </div>
        </div>
    );
};

export default BatchMonitoring;

