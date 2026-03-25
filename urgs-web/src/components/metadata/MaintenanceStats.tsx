import React, { useState, useEffect } from 'react';
import {
    PieChart, Pie, Cell, BarChart, Bar, XAxis, YAxis, CartesianGrid,
    Tooltip, ResponsiveContainer, Legend, AreaChart, Area
} from 'recharts';
import {
    ArrowLeft, RefreshCw, TrendingUp, Plus, Edit, Trash2,
    Database, Users, BarChart3, Calendar, FileText, Hash
} from 'lucide-react';
import { DatePicker, ConfigProvider } from 'antd';
import dayjs from 'dayjs';
import 'dayjs/locale/zh-cn';
import zhCN from 'antd/locale/zh_CN';

dayjs.locale('zh-cn');

const { RangePicker } = DatePicker;

// ---- Types ----

interface GroupCount {
    name: string;
    value: number;
}

interface TrendItem {
    period: string;
    addCount: number;
    updateCount: number;
    deleteCount: number;
}

interface StatsDetail {
    systemStats: GroupCount[];
    operatorStats: GroupCount[];
    modTypeStats: GroupCount[];
    trend: TrendItem[];
    totalCount: number;
    addCount: number;
    updateCount: number;
    deleteCount: number;
}

interface ReqSummary {
    reqId: string;
    reqName: string;
    operator: string;
    plannedDate: string;
    changeCount: number;
}

interface MaintenanceStatsProps {
    onBack: () => void;
}

// ---- Colors ----

const SYSTEM_COLORS = ['#6366f1', '#8b5cf6', '#a78bfa', '#c4b5fd', '#818cf8', '#7c3aed', '#4f46e5', '#4338ca'];
const MOD_TYPE_COLORS = ['#22c55e', '#3b82f6', '#ef4444', '#f59e0b', '#8b5cf6', '#06b6d4'];
const TREND_COLORS = { add: '#22c55e', update: '#3b82f6', delete: '#ef4444' };

// ---- Component ----

const MaintenanceStats: React.FC<MaintenanceStatsProps> = ({ onBack }) => {
    const [startDate, setStartDate] = useState<string>(() => dayjs().startOf('month').format('YYYY-MM-DD'));
    const [endDate, setEndDate] = useState<string>(() => dayjs().format('YYYY-MM-DD'));
    const [stats, setStats] = useState<StatsDetail | null>(null);
    const [reqList, setReqList] = useState<ReqSummary[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchData();
    }, [startDate, endDate]);

    const fetchData = async () => {
        setLoading(true);
        try {
            const token = localStorage.getItem('auth_token');
            const headers = { 'Authorization': `Bearer ${token}` };

            const [statsRes, reqRes] = await Promise.all([
                fetch(`/api/metadata/maintenance-record/stats/detail?startDate=${startDate}&endDate=${endDate}`, { headers }),
                fetch(`/api/metadata/maintenance-record/stats/req-summary?startDate=${startDate}&endDate=${endDate}`, { headers })
            ]);

            if (statsRes.ok) {
                const data = await statsRes.json();
                setStats(data);
            }
            if (reqRes.ok) {
                const data = await reqRes.json();
                setReqList(data);
            }
        } catch (error) {
            console.error('Failed to fetch stats:', error);
        } finally {
            setLoading(false);
        }
    };

    if (loading) {
        return (
            <div className="flex flex-col items-center justify-center h-64 gap-3">
                <RefreshCw className="w-8 h-8 animate-spin text-indigo-400" />
                <span className="text-sm text-slate-500">加载统计数据...</span>
            </div>
        );
    }

    if (!stats) {
        return (
            <div className="text-center text-slate-500 py-8">
                <p>暂无统计数据</p>
                <button onClick={onBack} className="mt-4 text-indigo-600 hover:text-indigo-700 text-sm font-medium">
                    返回维护记录
                </button>
            </div>
        );
    }

    return (
        <div className="h-full overflow-y-auto space-y-5 pb-6">
            {/* Header Bar */}
            <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex flex-wrap items-center gap-4">
                <button
                    onClick={onBack}
                    className="flex items-center gap-1.5 text-sm font-medium text-slate-600 hover:text-indigo-600 transition-colors px-3 py-1.5 rounded-lg hover:bg-indigo-50"
                >
                    <ArrowLeft size={16} />
                    返回维护记录
                </button>

                <div className="w-px h-6 bg-slate-200" />

                <div className="flex items-center gap-2 text-sm text-slate-600 font-medium">
                    <Calendar size={16} className="text-indigo-500" />
                    <span>时间范围:</span>
                </div>

                <ConfigProvider locale={zhCN}>
                    <RangePicker
                        value={[
                            startDate ? dayjs(startDate) : null,
                            endDate ? dayjs(endDate) : null
                        ]}
                        onChange={(_dates, dateStrings) => {
                            if (dateStrings && dateStrings[0] && dateStrings[1]) {
                                setStartDate(dateStrings[0]);
                                setEndDate(dateStrings[1]);
                            }
                        }}
                        className="border-slate-200"
                    />
                </ConfigProvider>

                {/* Compact KPI strip */}
                <div className="ml-auto hidden lg:flex items-center gap-4 bg-slate-50 px-4 py-2 rounded-lg border border-slate-200">
                    <div className="flex items-center gap-2">
                        <div className="p-1.5 bg-indigo-100 rounded-md">
                            <Database className="w-3.5 h-3.5 text-indigo-600" />
                        </div>
                        <div className="flex flex-col">
                            <span className="text-[10px] text-slate-500 leading-none mb-0.5">总变更</span>
                            <span className="text-sm font-bold text-slate-700 leading-none">{stats.totalCount}</span>
                        </div>
                    </div>
                    <div className="w-px h-6 bg-slate-200" />
                    <div className="flex items-center gap-2">
                        <div className="p-1.5 bg-emerald-100 rounded-md">
                            <Plus className="w-3.5 h-3.5 text-emerald-600" />
                        </div>
                        <div className="flex flex-col">
                            <span className="text-[10px] text-slate-500 leading-none mb-0.5">新增</span>
                            <span className="text-sm font-bold text-emerald-600 leading-none">{stats.addCount}</span>
                        </div>
                    </div>
                    <div className="w-px h-6 bg-slate-200" />
                    <div className="flex items-center gap-2">
                        <div className="p-1.5 bg-blue-100 rounded-md">
                            <Edit className="w-3.5 h-3.5 text-blue-600" />
                        </div>
                        <div className="flex flex-col">
                            <span className="text-[10px] text-slate-500 leading-none mb-0.5">修改</span>
                            <span className="text-sm font-bold text-blue-600 leading-none">{stats.updateCount}</span>
                        </div>
                    </div>
                    <div className="w-px h-6 bg-slate-200" />
                    <div className="flex items-center gap-2">
                        <div className="p-1.5 bg-red-100 rounded-md">
                            <Trash2 className="w-3.5 h-3.5 text-red-600" />
                        </div>
                        <div className="flex flex-col">
                            <span className="text-[10px] text-slate-500 leading-none mb-0.5">删除</span>
                            <span className="text-sm font-bold text-red-600 leading-none">{stats.deleteCount}</span>
                        </div>
                    </div>
                </div>
            </div>

            {/* Mobile KPI Cards */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-3 lg:hidden">
                <KpiCard label="总变更" value={stats.totalCount} color="indigo" icon={<Database size={18} />} />
                <KpiCard label="新增" value={stats.addCount} color="emerald" icon={<Plus size={18} />} />
                <KpiCard label="修改" value={stats.updateCount} color="blue" icon={<Edit size={18} />} />
                <KpiCard label="删除" value={stats.deleteCount} color="red" icon={<Trash2 size={18} />} />
            </div>

            {/* Charts Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                {/* System Distribution Bar Chart */}
                <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
                    <div className="flex items-center gap-2 mb-4">
                        <BarChart3 size={16} className="text-indigo-500" />
                        <h3 className="text-sm font-semibold text-slate-700">系统变更分布</h3>
                    </div>
                    {stats.systemStats.length > 0 ? (
                        <ResponsiveContainer width="100%" height={250} minWidth={0}>
                            <BarChart data={stats.systemStats} margin={{ bottom: 60 }}>
                                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                                <XAxis
                                    dataKey="name"
                                    tick={{ fontSize: 10, angle: -45, textAnchor: 'end' } as any}
                                    interval={0}
                                    height={60}
                                />
                                <YAxis tick={{ fontSize: 12 }} />
                                <Tooltip />
                                <Bar dataKey="value" name="变更数" radius={[4, 4, 0, 0]}>
                                    {stats.systemStats.map((_, index) => (
                                        <Cell key={`sys-${index}`} fill={SYSTEM_COLORS[index % SYSTEM_COLORS.length]} />
                                    ))}
                                </Bar>
                            </BarChart>
                        </ResponsiveContainer>
                    ) : (
                        <EmptyChart />
                    )}
                </div>

                {/* Mod Type Pie Chart */}
                <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
                    <div className="flex items-center gap-2 mb-4">
                        <TrendingUp size={16} className="text-violet-500" />
                        <h3 className="text-sm font-semibold text-slate-700">变更类型占比</h3>
                    </div>
                    {stats.modTypeStats.length > 0 ? (
                        <ResponsiveContainer width="100%" height={250} minWidth={0}>
                            <PieChart>
                                <Pie
                                    data={stats.modTypeStats}
                                    cx="50%"
                                    cy="50%"
                                    innerRadius={50}
                                    outerRadius={85}
                                    paddingAngle={2}
                                    dataKey="value"
                                    nameKey="name"
                                    label={({ name, value }) => `${name}: ${value}`}
                                >
                                    {stats.modTypeStats.map((_, index) => (
                                        <Cell key={`type-${index}`} fill={MOD_TYPE_COLORS[index % MOD_TYPE_COLORS.length]} />
                                    ))}
                                </Pie>
                                <Tooltip />
                                <Legend />
                            </PieChart>
                        </ResponsiveContainer>
                    ) : (
                        <EmptyChart />
                    )}
                </div>

                {/* Operator Horizontal Bar Chart */}
                <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
                    <div className="flex items-center gap-2 mb-4">
                        <Users size={16} className="text-cyan-500" />
                        <h3 className="text-sm font-semibold text-slate-700">操作人统计</h3>
                    </div>
                    {stats.operatorStats.length > 0 ? (
                        <ResponsiveContainer width="100%" height={Math.max(200, stats.operatorStats.length * 40)} minWidth={0}>
                            <BarChart data={stats.operatorStats} layout="vertical">
                                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                                <XAxis type="number" tick={{ fontSize: 12 }} />
                                <YAxis dataKey="name" type="category" tick={{ fontSize: 12 }} width={70} />
                                <Tooltip />
                                <Bar dataKey="value" name="变更数" fill="#06b6d4" radius={[0, 4, 4, 0]} />
                            </BarChart>
                        </ResponsiveContainer>
                    ) : (
                        <EmptyChart />
                    )}
                </div>

                {/* Trend Area Chart */}
                <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
                    <div className="flex items-center gap-2 mb-4">
                        <TrendingUp size={16} className="text-blue-500" />
                        <h3 className="text-sm font-semibold text-slate-700">变更趋势</h3>
                    </div>
                    {stats.trend.length > 0 ? (
                        <ResponsiveContainer width="100%" height={250} minWidth={0}>
                            <AreaChart data={stats.trend}>
                                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                                <XAxis dataKey="period" tick={{ fontSize: 10 }} />
                                <YAxis tick={{ fontSize: 12 }} />
                                <Tooltip />
                                <Legend />
                                <Area type="monotone" dataKey="addCount" name="新增" stackId="1" stroke={TREND_COLORS.add} fill={TREND_COLORS.add} fillOpacity={0.3} />
                                <Area type="monotone" dataKey="updateCount" name="修改" stackId="1" stroke={TREND_COLORS.update} fill={TREND_COLORS.update} fillOpacity={0.3} />
                                <Area type="monotone" dataKey="deleteCount" name="删除" stackId="1" stroke={TREND_COLORS.delete} fill={TREND_COLORS.delete} fillOpacity={0.3} />
                            </AreaChart>
                        </ResponsiveContainer>
                    ) : (
                        <EmptyChart />
                    )}
                </div>
            </div>

            {/* Requirement Summary Table */}
            <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
                <div className="flex items-center gap-2 p-4 border-b border-slate-100">
                    <FileText size={16} className="text-amber-500" />
                    <h3 className="text-sm font-semibold text-slate-700">需求变更汇总</h3>
                    <span className="ml-2 text-xs text-slate-400 bg-slate-100 px-2 py-0.5 rounded-full">
                        {reqList.length} 条需求
                    </span>
                </div>

                <div className="overflow-x-auto">
                    <table className="w-full text-sm">
                        <thead>
                            <tr className="bg-slate-50 text-slate-600">
                                <th className="text-left px-4 py-3 font-medium">
                                    <div className="flex items-center gap-1.5">
                                        <Hash size={13} />
                                        需求编号
                                    </div>
                                </th>
                                <th className="text-left px-4 py-3 font-medium">需求名称</th>
                                <th className="text-left px-4 py-3 font-medium">
                                    <div className="flex items-center gap-1.5">
                                        <Users size={13} />
                                        执行人
                                    </div>
                                </th>
                                <th className="text-left px-4 py-3 font-medium">
                                    <div className="flex items-center gap-1.5">
                                        <Calendar size={13} />
                                        上线日期
                                    </div>
                                </th>
                                <th className="text-right px-4 py-3 font-medium">变更数量</th>
                            </tr>
                        </thead>
                        <tbody>
                            {reqList.length === 0 ? (
                                <tr>
                                    <td colSpan={5} className="text-center py-8 text-slate-400">
                                        该时间范围内暂无需求变更记录
                                    </td>
                                </tr>
                            ) : (
                                reqList.map((req, idx) => (
                                    <tr key={req.reqId || idx} className="border-t border-slate-100 hover:bg-slate-50 transition-colors">
                                        <td className="px-4 py-3">
                                            <span className="font-mono text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded text-xs">
                                                {req.reqId}
                                            </span>
                                        </td>
                                        <td className="px-4 py-3 text-slate-700">
                                            {req.reqName || '-'}
                                        </td>
                                        <td className="px-4 py-3 text-slate-600">
                                            {req.operator || '-'}
                                        </td>
                                        <td className="px-4 py-3 text-slate-600">
                                            {req.plannedDate || '-'}
                                        </td>
                                        <td className="px-4 py-3 text-right">
                                            <span className="inline-flex items-center justify-center min-w-[28px] h-6 bg-amber-100 text-amber-700 rounded-full text-xs font-bold">
                                                {req.changeCount}
                                            </span>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
};

// ---- Helper Components ----

const KpiCard: React.FC<{ label: string; value: number; color: string; icon: React.ReactNode }> = ({ label, value, color, icon }) => {
    const colorMap: Record<string, string> = {
        indigo: 'bg-indigo-50 text-indigo-600 border-indigo-100',
        emerald: 'bg-emerald-50 text-emerald-600 border-emerald-100',
        blue: 'bg-blue-50 text-blue-600 border-blue-100',
        red: 'bg-red-50 text-red-600 border-red-100'
    };
    return (
        <div className={`rounded-xl border p-3 ${colorMap[color] || colorMap.indigo}`}>
            <div className="flex items-center gap-2 mb-1 opacity-70">{icon}<span className="text-xs font-medium">{label}</span></div>
            <div className="text-2xl font-bold">{value}</div>
        </div>
    );
};

const EmptyChart: React.FC = () => (
    <div className="flex items-center justify-center h-[200px] text-slate-400 text-sm">
        暂无数据
    </div>
);

export default MaintenanceStats;
