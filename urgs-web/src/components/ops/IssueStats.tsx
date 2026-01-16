import React, { useState, useEffect } from 'react';
import { PieChart, Pie, Cell, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend, LineChart, Line } from 'recharts';
import { TrendingUp, Users, Clock, FileText, AlertCircle, CheckCircle, Hourglass, RefreshCw, Sparkles } from 'lucide-react';
import { Button, DatePicker, ConfigProvider } from 'antd';
import dayjs from 'dayjs';
import 'dayjs/locale/zh-cn';
import zhCN from 'antd/locale/zh_CN';

dayjs.locale('zh-cn');

import ReportGeneratorModal from './ReportGeneratorModal';

const { RangePicker } = DatePicker;

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
    systemStats: StatItem[];
    handlerStats: HandlerStats[];
    trend: TrendItem[];
    totalCount: number;
    newCount: number;
    inProgressCount: number;
    completedCount: number;
    leftoverCount: number;
    totalWorkHours: number;
}

const STATUS_COLORS = ['#3b82f6', '#f59e0b', '#22c55e', '#ef4444'];
const TYPE_COLORS = ['#8b5cf6', '#06b6d4', '#6366f1'];

const IssueStats: React.FC = () => {
    const [frequency, setFrequency] = useState('day');
    const [startDate, setStartDate] = useState<string>('');
    const [endDate, setEndDate] = useState<string>('');
    const [stats, setStats] = useState<IssueStats | null>(null);
    const [loading, setLoading] = useState(true);
    const [isReportModalOpen, setIsReportModalOpen] = useState(false);

    useEffect(() => {
        fetchStats();
    }, [frequency, startDate, endDate]);

    const fetchStats = async () => {
        setLoading(true);
        try {
            const token = localStorage.getItem('auth_token');
            let url = `/api/issue/stats?frequency=${frequency}`;
            if (startDate) url += `&startDate=${startDate}`;
            if (endDate) url += `&endDate=${endDate}`;

            const res = await fetch(url, {
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
            {/* Filter & Action Bar */}
            <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex flex-wrap items-center gap-4">
                <div className="flex items-center gap-2 text-sm text-slate-600 font-medium">
                    <Clock size={16} className="text-blue-500" />
                    <span>统计周期:</span>
                </div>
                <select
                    value={frequency}
                    onChange={(e) => {
                        setFrequency(e.target.value);
                        if (e.target.value !== 'custom') {
                            setStartDate('');
                            setEndDate('');
                        }
                    }}
                    className="bg-slate-50 border border-slate-200 text-slate-700 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block p-2.5 outline-none"
                >
                    <option value="day">日报表 (最近30天)</option>
                    <option value="month">月报表 (最近12个月)</option>
                    <option value="quarter">季报表</option>
                    <option value="half">半年报</option>
                    <option value="year">年报表</option>
                    <option value="custom">自定义范围</option>
                </select>

                {frequency === 'custom' && (
                    <div className="flex items-center gap-2 animate-fade-in">
                        <span className="text-sm text-slate-500">日期范围:</span>
                        <ConfigProvider locale={zhCN}>
                            <RangePicker
                                value={[
                                    startDate ? dayjs(startDate) : null,
                                    endDate ? dayjs(endDate) : null
                                ]}
                                onChange={(dates, dateStrings) => {
                                    if (dateStrings) {
                                        setStartDate(dateStrings[0]);
                                        setEndDate(dateStrings[1]);
                                    } else {
                                        setStartDate('');
                                        setEndDate('');
                                    }
                                }}
                                className="border-slate-200"
                            />
                        </ConfigProvider>
                    </div>
                )}

                <div className="ml-auto flex items-center gap-4">
                    {/* Compact Stats Strip */}
                    <div className="hidden xl:flex items-center gap-4 bg-slate-50 px-4 py-2 rounded-lg border border-slate-200">
                        {/* Total */}
                        <div className="flex items-center gap-3">
                            <div className="p-1.5 bg-blue-100 rounded-md">
                                <FileText className="w-3.5 h-3.5 text-blue-600" />
                            </div>
                            <div className="flex flex-col">
                                <span className="text-[10px] text-slate-500 leading-none mb-0.5">问题总数</span>
                                <span className="text-sm font-bold text-slate-700 leading-none">{stats.totalCount}</span>
                            </div>
                        </div>
                        <div className="w-px h-6 bg-slate-200"></div>

                        {/* New */}
                        <div className="flex items-center gap-3">
                            <div className="p-1.5 bg-cyan-100 rounded-md">
                                <Sparkles className="w-3.5 h-3.5 text-cyan-600" />
                            </div>
                            <div className="flex flex-col">
                                <span className="text-[10px] text-slate-500 leading-none mb-0.5">新建</span>
                                <span className="text-sm font-bold text-slate-700 leading-none">{stats.newCount}</span>
                            </div>
                        </div>
                        <div className="w-px h-6 bg-slate-200"></div>

                        {/* Processing */}
                        <div className="flex items-center gap-3">
                            <div className="p-1.5 bg-amber-100 rounded-md">
                                <Hourglass className="w-3.5 h-3.5 text-amber-600" />
                            </div>
                            <div className="flex flex-col">
                                <span className="text-[10px] text-slate-500 leading-none mb-0.5">处理中</span>
                                <span className="text-sm font-bold text-slate-700 leading-none">{stats.inProgressCount}</span>
                            </div>
                        </div>
                        <div className="w-px h-6 bg-slate-200"></div>

                        {/* Completed */}
                        <div className="flex items-center gap-3">
                            <div className="p-1.5 bg-green-100 rounded-md">
                                <CheckCircle className="w-3.5 h-3.5 text-green-600" />
                            </div>
                            <div className="flex flex-col">
                                <span className="text-[10px] text-slate-500 leading-none mb-0.5">已完成</span>
                                <span className="text-sm font-bold text-slate-700 leading-none">{stats.completedCount}</span>
                            </div>
                        </div>
                        <div className="w-px h-6 bg-slate-200"></div>

                        {/* Leftover */}
                        <div className="flex items-center gap-3">
                            <div className="p-1.5 bg-red-100 rounded-md">
                                <AlertCircle className="w-3.5 h-3.5 text-red-600" />
                            </div>
                            <div className="flex flex-col">
                                <span className="text-[10px] text-slate-500 leading-none mb-0.5">遗留</span>
                                <span className="text-sm font-bold text-slate-700 leading-none">{stats.leftoverCount}</span>
                            </div>
                        </div>
                        <div className="w-px h-6 bg-slate-200"></div>

                        {/* Hours */}
                        <div className="flex items-center gap-3">
                            <div className="p-1.5 bg-purple-100 rounded-md">
                                <Clock className="w-3.5 h-3.5 text-purple-600" />
                            </div>
                            <div className="flex flex-col">
                                <span className="text-[10px] text-slate-500 leading-none mb-0.5">总工时</span>
                                <span className="text-sm font-bold text-slate-700 leading-none">{stats.totalWorkHours?.toFixed(1) || 0}</span>
                            </div>
                        </div>
                    </div>

                    <Button
                        type="primary"
                        icon={<Sparkles size={16} />}
                        className="bg-purple-600 hover:bg-purple-700 border-none flex items-center gap-2 h-10 px-4"
                        onClick={() => setIsReportModalOpen(true)}
                    >
                        AI 生成工作报告
                    </Button>
                </div>
            </div>

            {/* 概览卡片 */}


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
                    <ResponsiveContainer width="100%" height={Math.max(200, (stats.handlerStats?.length || 0) * 40)} minWidth={0}>
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
