import React, { useState, useEffect } from 'react';
import { listWorks, getMarketTasks, Work, TaskMarketDTO } from '../../api/marketplace';
import { Briefcase, Rocket, ListTodo, Award, TrendingUp, CheckCircle2, Clock3, AlertCircle } from 'lucide-react';

const StatsPage: React.FC = () => {
    const [works, setWorks] = useState<Work[]>([]);
    const [marketTasks, setMarketTasks] = useState<TaskMarketDTO[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchStats();
    }, []);

    const fetchStats = async () => {
        setLoading(true);
        try {
            const [workRes, taskRes] = await Promise.all([
                listWorks({ current: 1, size: 100 }),
                getMarketTasks({ current: 1, size: 200 }),
            ]);
            setWorks(workRes?.records || []);
            setMarketTasks(taskRes?.records || []);
        } catch (error) {
            console.error('Failed to fetch stats', error);
        } finally {
            setLoading(false);
        }
    };

    // Compute KPIs from fetched data
    const totalWorks = works.length;
    const publishedWorks = works.filter(w => w.status === 'PUBLISHED').length;
    const draftWorks = works.filter(w => w.status === 'DRAFT').length;
    const inProgressWorks = works.filter(w => w.status === 'IN_PROGRESS').length;

    const openTasks = marketTasks.filter(t => t.status === 'OPEN').length;
    const assignedTasks = marketTasks.filter(t => t.status === 'ASSIGNED' || t.status === 'IN_PROGRESS').length;
    const completedTasks = marketTasks.filter(t => t.status === 'COMPLETED').length;

    const totalPoints = works.reduce((sum, w) => sum + (w.totalPoints || 0), 0);
    const taskCompletionRate = marketTasks.length > 0
        ? Math.round((completedTasks / marketTasks.length) * 100)
        : 0;

    const summaryCards = [
        {
            icon: Briefcase,
            label: '总工作数',
            value: totalWorks,
            color: 'text-slate-800',
            bg: 'bg-slate-50',
            border: 'border-slate-200',
        },
        {
            icon: Rocket,
            label: '已发布',
            value: publishedWorks,
            color: 'text-green-700',
            bg: 'bg-green-50',
            border: 'border-green-200',
        },
        {
            icon: ListTodo,
            label: '可领取任务',
            value: openTasks,
            color: 'text-blue-700',
            bg: 'bg-blue-50',
            border: 'border-blue-200',
        },
        {
            icon: Award,
            label: '总积分池',
            value: totalPoints,
            color: 'text-orange-700',
            bg: 'bg-orange-50',
            border: 'border-orange-200',
        },
    ];

    const breakdownData = [
        { label: '已发布', value: publishedWorks, color: 'bg-green-500' },
        { label: '草稿', value: draftWorks, color: 'bg-slate-400' },
        { label: '进行中', value: inProgressWorks, color: 'bg-blue-500' },
    ];

    const taskBreakdownData = [
        { label: '可领取', value: openTasks, color: 'bg-blue-500' },
        { label: '已被领', value: assignedTasks, color: 'bg-cyan-500' },
        { label: '已完成', value: completedTasks, color: 'bg-green-500' },
    ];

    const maxBreakdown = Math.max(
        ...breakdownData.map(d => d.value),
        ...taskBreakdownData.map(d => d.value),
        1,
    );

    if (loading) {
        return <div className="h-full flex items-center justify-center text-slate-400">加载中...</div>;
    }

    return (
        <div className="h-full flex flex-col p-6 overflow-y-auto">
            <div className="mb-6">
                <h2 className="text-xl font-bold text-slate-800">数据概览</h2>
                <p className="text-sm text-slate-500 mt-1">工作市场运营关键指标一览</p>
            </div>

            {/* Summary Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
                {summaryCards.map(card => (
                    <div key={card.label} className={`${card.bg} rounded-xl border ${card.border} p-5`}>
                        <div className="flex items-center gap-3 mb-3">
                            <card.icon size={20} className={`${card.color}`} />
                            <span className="text-sm text-slate-500 font-medium">{card.label}</span>
                        </div>
                        <div className={`text-3xl font-black ${card.color}`}>{card.value}</div>
                    </div>
                ))}
            </div>

            {/* Detailed Metrics */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 flex-1">
                {/* Work Status Breakdown */}
                <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
                    <div className="flex items-center gap-2 mb-4">
                        <Briefcase size={18} className="text-slate-500" />
                        <h3 className="font-bold text-slate-800">工作状态分布</h3>
                    </div>
                    <div className="space-y-4">
                        {breakdownData.map(item => (
                            <div key={item.label}>
                                <div className="flex items-center justify-between text-sm mb-1">
                                    <span className="text-slate-600">{item.label}</span>
                                    <span className="font-bold text-slate-800">{item.value}</span>
                                </div>
                                <div className="w-full h-2 bg-slate-100 rounded-full overflow-hidden">
                                    <div
                                        className={`h-full ${item.color} rounded-full transition-all`}
                                        style={{ width: `${maxBreakdown > 0 ? (item.value / maxBreakdown) * 100 : 0}%` }}
                                    />
                                </div>
                            </div>
                        ))}
                    </div>
                </div>

                {/* Task Status Breakdown */}
                <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
                    <div className="flex items-center gap-2 mb-4">
                        <ListTodo size={18} className="text-slate-500" />
                        <h3 className="font-bold text-slate-800">任务状态分布</h3>
                    </div>
                    <div className="space-y-4">
                        {taskBreakdownData.map(item => (
                            <div key={item.label}>
                                <div className="flex items-center justify-between text-sm mb-1">
                                    <span className="text-slate-600">{item.label}</span>
                                    <span className="font-bold text-slate-800">{item.value}</span>
                                </div>
                                <div className="w-full h-2 bg-slate-100 rounded-full overflow-hidden">
                                    <div
                                        className={`h-full ${item.color} rounded-full transition-all`}
                                        style={{ width: `${maxBreakdown > 0 ? (item.value / maxBreakdown) * 100 : 0}%` }}
                                    />
                                </div>
                            </div>
                        ))}
                    </div>
                </div>

                {/* KPI Highlights */}
                <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
                    <div className="flex items-center gap-2 mb-4">
                        <TrendingUp size={18} className="text-slate-500" />
                        <h3 className="font-bold text-slate-800">关键指标</h3>
                    </div>
                    <div className="space-y-4">
                        <div className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
                            <div className="flex items-center gap-2">
                                <CheckCircle2 size={16} className="text-green-500" />
                                <span className="text-sm text-slate-600">任务完成率</span>
                            </div>
                            <span className="font-black text-slate-800">{taskCompletionRate}%</span>
                        </div>
                        <div className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
                            <div className="flex items-center gap-2">
                                <Clock3 size={16} className="text-blue-500" />
                                <span className="text-sm text-slate-600">进行中工作</span>
                            </div>
                            <span className="font-black text-slate-800">{inProgressWorks}</span>
                        </div>
                        <div className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
                            <div className="flex items-center gap-2">
                                <AlertCircle size={16} className="text-orange-500" />
                                <span className="text-sm text-slate-600">草稿工作</span>
                            </div>
                            <span className="font-black text-slate-800">{draftWorks}</span>
                        </div>
                        <div className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
                            <div className="flex items-center gap-2">
                                <Award size={16} className="text-orange-500" />
                                <span className="text-sm text-slate-600">平均工作积分</span>
                            </div>
                            <span className="font-black text-slate-800">
                                {totalWorks > 0 ? Math.round(totalPoints / totalWorks) : 0}
                            </span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default StatsPage;
