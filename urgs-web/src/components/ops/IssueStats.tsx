import React, { useState, useEffect } from 'react';
import { PieChart, Pie, Cell, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend, LineChart, Line } from 'recharts';
import { TrendingUp, Users, Clock, FileText, AlertCircle, CheckCircle, Hourglass, RefreshCw, Sparkles } from 'lucide-react';
import { Button } from 'antd';
import ReportGeneratorModal from './ReportGeneratorModal';

interface StatItem {
    name: string;
    value: number;
    [key: string]: any;
}

interface HandlerStats {
    handler: string;
    issueCount: number;
    totalWorkHours: number;
    [key: string]: any;
}

interface TrendItem {
    period: string; // Updated from month
    count: number;
    [key: string]: any;
}

interface IssueStats {
    statusStats: StatItem[];
    typeStats: StatItem[];
    systemStats: StatItem[]; // Added systemStats
    handlerStats: HandlerStats[];
    trend: TrendItem[]; // Updated from monthlyTrend
    totalCount: number;
    newCount: number;
    inProgressCount: number;
    completedCount: number;
    leftoverCount: number;
    totalWorkHours: number;
}

const STATUS_COLORS = ['#3b82f6', '#f59e0b', '#22c55e', '#ef4444'];
const TYPE_COLORS = ['#8b5cf6', '#06b6d4', '#6366f1'];

interface IssueStatsProps {
    frequency: string;
}

const IssueStats: React.FC<IssueStatsProps> = ({ frequency }) => {
    const [stats, setStats] = useState<IssueStats | null>(null);
    const [loading, setLoading] = useState(true);
    const [isReportModalOpen, setIsReportModalOpen] = useState(false);

    useEffect(() => {
        fetchStats();
    }, [frequency]);

    const fetchStats = async () => {
        setLoading(true);
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch(`/api/issue/stats?frequency=${frequency}`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const data = await res.json();
                console.log('IssueStats data:', data); // Debug logging

                // Ensure values are numbers
                if (data) {
                    data.totalCount = Number(data.totalCount);
                    data.newCount = Number(data.newCount);
                    data.inProgressCount = Number(data.inProgressCount);
                    data.completedCount = Number(data.completedCount);

                    if (data.statusStats) {
                        data.statusStats = data.statusStats.map((item: any) => ({
                            ...item,
                            value: Number(item.value)
                        }));
                    }
                    if (data.typeStats) {
                        data.typeStats = data.typeStats.map((item: any) => ({
                            ...item,
                            value: Number(item.value)
                        }));
                    }
                    if (data.systemStats) {
                        data.systemStats = data.systemStats.map((item: any) => ({
                            ...item,
                            value: Number(item.value)
                        }));
                    }
                }

                setStats(data);
            }
        } catch (error) {
            console.error('Failed to fetch stats:', error);
        } finally {
            setLoading(false);
        }
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center h-64">
                <RefreshCw className="w-8 h-8 animate-spin text-slate-400" />
            </div>
        );
    }

    if (!stats) {
        return <div className="text-center text-slate-500 py-8">暂无统计数据</div>;
    }

    return (
        <div className="space-y-6">
            {/* Action Bar */}
            <div className="flex justify-end">
                <Button
                    type="primary"
                    icon={<Sparkles size={16} />}
                    className="bg-purple-600 hover:bg-purple-700 border-none flex items-center gap-2"
                    onClick={() => setIsReportModalOpen(true)}
                >
                    AI 生成工作报告
                </Button>
            </div>

            {/* 概览卡片 */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
                    <div className="flex items-center gap-3">
                        <div className="p-2 bg-blue-100 rounded-lg">
                            <FileText className="w-5 h-5 text-blue-600" />
                        </div>
                        <div>
                            <div className="text-2xl font-bold text-slate-800">{stats.totalCount}</div>
                            <div className="text-sm text-slate-500">问题总数</div>
                        </div>
                    </div>
                </div>
                <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
                    <div className="flex items-center gap-3">
                        <div className="p-2 bg-amber-100 rounded-lg">
                            <Hourglass className="w-5 h-5 text-amber-600" />
                        </div>
                        <div>
                            <div className="text-2xl font-bold text-slate-800">{stats.inProgressCount}</div>
                            <div className="text-sm text-slate-500">处理中</div>
                        </div>
                    </div>
                </div>
                <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
                    <div className="flex items-center gap-3">
                        <div className="p-2 bg-green-100 rounded-lg">
                            <CheckCircle className="w-5 h-5 text-green-600" />
                        </div>
                        <div>
                            <div className="text-2xl font-bold text-slate-800">{stats.completedCount}</div>
                            <div className="text-sm text-slate-500">已完成</div>
                        </div>
                    </div>
                </div>
                <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
                    <div className="flex items-center gap-3">
                        <div className="p-2 bg-purple-100 rounded-lg">
                            <Clock className="w-5 h-5 text-purple-600" />
                        </div>
                        <div>
                            <div className="text-2xl font-bold text-slate-800">{stats.totalWorkHours?.toFixed(1) || 0}</div>
                            <div className="text-sm text-slate-500">总工时(h)</div>
                        </div>
                    </div>
                </div>
            </div>

            {/* 图表区域 */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* 状态分布饼图 */}
                <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
                    <h3 className="text-sm font-semibold text-slate-700 mb-4">问题状态分布</h3>
                    <ResponsiveContainer width="100%" height={200} minWidth={0}>
                        <PieChart>
                            <Pie
                                data={stats.statusStats}
                                cx="50%"
                                cy="50%"
                                innerRadius={40}
                                outerRadius={70}
                                paddingAngle={2}
                                dataKey="value"
                                nameKey="name"
                                label={({ name, value }) => `${name}: ${value}`}
                            >
                                {stats.statusStats.map((_, index) => (
                                    <Cell key={`cell-${index}`} fill={STATUS_COLORS[index % STATUS_COLORS.length]} />
                                ))}
                            </Pie>
                            <Tooltip />
                        </PieChart>
                    </ResponsiveContainer>
                </div>

                {/* 问题类型柱状图 */}
                <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
                    <h3 className="text-sm font-semibold text-slate-700 mb-4">问题类型分布</h3>
                    <ResponsiveContainer width="100%" height={200} minWidth={0}>
                        <BarChart data={stats.typeStats}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                            <XAxis dataKey="name" tick={{ fontSize: 12 }} />
                            <YAxis tick={{ fontSize: 12 }} />
                            <Tooltip />
                            <Bar dataKey="value" fill="#8b5cf6" radius={[4, 4, 0, 0]} />
                        </BarChart>
                    </ResponsiveContainer>
                </div>

                {/* 归属系统分布柱状图 */}
                <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
                    <h3 className="text-sm font-semibold text-slate-700 mb-4">归属系统分布</h3>
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
                            <Bar dataKey="value" fill="#ec4899" radius={[4, 4, 0, 0]} />
                        </BarChart>
                    </ResponsiveContainer>
                </div>

                {/* 趋势折线图 */}
                <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
                    <div className="flex items-center justify-between mb-4">
                        <h3 className="text-sm font-semibold text-slate-700">问题趋势</h3>
                    </div>
                    <ResponsiveContainer width="100%" height={200} minWidth={0}>
                        <LineChart data={stats.trend}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                            <XAxis dataKey="period" tick={{ fontSize: 12 }} />
                            <YAxis tick={{ fontSize: 12 }} />
                            <Tooltip />
                            <Line type="monotone" dataKey="count" stroke="#3b82f6" strokeWidth={2} dot={{ fill: '#3b82f6' }} />
                        </LineChart>
                    </ResponsiveContainer>
                </div>

                {/* 处理人工时统计 */}
                <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
                    <h3 className="text-sm font-semibold text-slate-700 mb-4">处理人工时统计</h3>
                    <ResponsiveContainer width="100%" height={200} minWidth={0}>
                        <BarChart data={stats.handlerStats} layout="vertical">
                            <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                            <XAxis type="number" tick={{ fontSize: 12 }} />
                            <YAxis dataKey="handler" type="category" tick={{ fontSize: 12 }} width={60} />
                            <Tooltip />
                            <Legend />
                            <Bar dataKey="issueCount" name="处理问题数" fill="#22c55e" radius={[0, 4, 4, 0]} />
                            <Bar dataKey="totalWorkHours" name="工时(h)" fill="#f59e0b" radius={[0, 4, 4, 0]} />
                        </BarChart>
                    </ResponsiveContainer>
                </div>
            </div>


            <ReportGeneratorModal
                open={isReportModalOpen}
                onCancel={() => setIsReportModalOpen(false)}
                data={stats}
            />
        </div >
    );
};

export default IssueStats;
