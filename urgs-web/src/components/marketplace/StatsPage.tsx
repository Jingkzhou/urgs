import React, { useState, useEffect } from 'react';
import {
    generateKpiSnapshot,
    getKpiDetails,
    getKpiSnapshots,
    getMarketTasks,
    getTeamKpi,
    KpiDetailDTO,
    KpiSnapshot,
    listWorks,
    TaskMarketDTO,
    TeamKpiDTO,
    Work,
} from '../../api/marketplace';
import { AlertCircle, Award, Briefcase, CalendarCheck, CheckCircle2, Clock3, ListTodo, Medal, Rocket, TrendingUp } from 'lucide-react';

const formatDateInput = (date: Date) => {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
};

const getCurrentMonthRange = () => {
    const now = new Date();
    return {
        startDate: formatDateInput(new Date(now.getFullYear(), now.getMonth(), 1)),
        endDate: formatDateInput(new Date(now.getFullYear(), now.getMonth() + 1, 0)),
    };
};

const getCurrentPeriod = () => getCurrentMonthRange().startDate.slice(0, 7);

const StatsPage: React.FC = () => {
    const [works, setWorks] = useState<Work[]>([]);
    const [marketTasks, setMarketTasks] = useState<TaskMarketDTO[]>([]);
    const [teamKpi, setTeamKpi] = useState<TeamKpiDTO | null>(null);
    const [details, setDetails] = useState<KpiDetailDTO[]>([]);
    const [snapshots, setSnapshots] = useState<KpiSnapshot[]>([]);
    const [dateRange, setDateRange] = useState(getCurrentMonthRange);
    const [snapshotPeriod, setSnapshotPeriod] = useState(getCurrentPeriod);
    const [loading, setLoading] = useState(true);
    const [generatingSnapshot, setGeneratingSnapshot] = useState(false);

    useEffect(() => {
        fetchStats();
    }, [dateRange.startDate, dateRange.endDate, snapshotPeriod]);

    const fetchStats = async () => {
        setLoading(true);
        try {
            const [workRes, taskRes, teamRes, detailRes, snapshotRes] = await Promise.all([
                listWorks({ current: 1, size: 100 }),
                getMarketTasks({ current: 1, size: 200 }),
                getTeamKpi(dateRange),
                getKpiDetails(dateRange),
                getKpiSnapshots({ period: snapshotPeriod }),
            ]);
            setWorks(workRes?.records || []);
            setMarketTasks(taskRes?.records || []);
            setTeamKpi(teamRes || null);
            setDetails(detailRes || []);
            setSnapshots(snapshotRes || []);
        } catch (error) {
            console.error('Failed to fetch stats', error);
        } finally {
            setLoading(false);
        }
    };

    const resetToCurrentMonth = () => {
        setDateRange(getCurrentMonthRange());
        setSnapshotPeriod(getCurrentPeriod());
    };

    const handleGenerateSnapshot = async () => {
        setGeneratingSnapshot(true);
        try {
            const res = await generateKpiSnapshot(snapshotPeriod);
            setSnapshots(res || []);
        } catch (error) {
            console.error('Failed to generate KPI snapshot', error);
            alert('生成 KPI 快照失败，请稍后重试');
        } finally {
            setGeneratingSnapshot(false);
        }
    };

    // Compute KPIs from fetched data
    const totalWorks = works.length;
    const publishedWorks = works.filter(w => w.status === 'PUBLISHED').length;
    const draftWorks = works.filter(w => w.status === 'DRAFT').length;
    const inProgressWorks = works.filter(w => w.status === 'ACTIVE').length;

    const openTasks = marketTasks.filter(t => t.status === 'OPEN').length;
    const assignedTasks = marketTasks.filter(t =>
        ['READY', 'IN_PROGRESS', 'WAITING_REVIEW', 'REWORK', 'PAUSED'].includes(t.status)
    ).length;
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
            label: '已结算积分',
            value: teamKpi?.settledPoints ?? totalPoints,
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
                <h2 className="text-xl font-bold text-slate-800">KPI 看板</h2>
                <p className="text-sm text-slate-500 mt-1">按质量校准积分统计个人与团队绩效</p>
            </div>

            <div className="flex flex-wrap items-center gap-3 mb-4 bg-slate-50 border border-slate-100 rounded-xl px-4 py-3">
                <span className="text-sm font-bold text-slate-700">KPI 周期</span>
                <input
                    type="date"
                    value={dateRange.startDate}
                    onChange={e => setDateRange(prev => ({ ...prev, startDate: e.target.value }))}
                    className="border border-slate-200 rounded-lg px-3 py-1.5 text-sm"
                />
                <span className="text-slate-400 text-sm">至</span>
                <input
                    type="date"
                    value={dateRange.endDate}
                    onChange={e => setDateRange(prev => ({ ...prev, endDate: e.target.value }))}
                    className="border border-slate-200 rounded-lg px-3 py-1.5 text-sm"
                />
                <button
                    onClick={resetToCurrentMonth}
                    className="px-3 py-1.5 text-sm font-bold text-red-600 bg-red-50 hover:bg-red-100 rounded-lg"
                >
                    本月
                </button>
            </div>

            <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm mb-6">
                <div className="flex flex-wrap items-center justify-between gap-3 mb-4">
                    <div className="flex items-center gap-2">
                        <CalendarCheck size={18} className="text-red-500" />
                        <div>
                            <h3 className="font-bold text-slate-800">月度 KPI 结算快照</h3>
                            <p className="text-xs text-slate-500 mt-0.5">生成后会固化当月个人积分、质量、准时和返工数据</p>
                        </div>
                    </div>
                    <div className="flex items-center gap-2">
                        <input
                            type="month"
                            value={snapshotPeriod}
                            onChange={e => setSnapshotPeriod(e.target.value)}
                            className="border border-slate-200 rounded-lg px-3 py-1.5 text-sm"
                        />
                        <button
                            onClick={handleGenerateSnapshot}
                            disabled={generatingSnapshot}
                            className="px-3 py-1.5 text-sm font-bold text-white bg-red-600 hover:bg-red-700 rounded-lg disabled:opacity-60"
                        >
                            {generatingSnapshot ? '生成中...' : '生成快照'}
                        </button>
                    </div>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                    {snapshots.slice(0, 6).map(snapshot => (
                        <div key={snapshot.id} className="rounded-lg border border-slate-100 bg-slate-50 px-3 py-2">
                            <div className="flex items-center justify-between gap-3">
                                <div className="min-w-0">
                                    <div className="font-bold text-sm text-slate-800 truncate">{snapshot.userName || snapshot.userId}</div>
                                    <div className="text-xs text-slate-500 mt-1">
                                        质量 {snapshot.averageQualityScore} / 准时 {snapshot.onTimeRate}% / 返工 {snapshot.reworkCount}
                                    </div>
                                </div>
                                <div className="text-right shrink-0">
                                    <div className="text-lg font-black text-orange-600">{snapshot.finalPoints}</div>
                                    <div className="text-xs text-slate-400">最终积分</div>
                                </div>
                            </div>
                        </div>
                    ))}
                    {snapshots.length === 0 && (
                        <div className="md:col-span-3 text-center py-6 text-slate-400 bg-slate-50 rounded-lg">
                            当前周期暂无快照，点击"生成快照"后用于绩效复盘
                        </div>
                    )}
                </div>
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

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mt-6">
                <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
                    <div className="flex items-center gap-2 mb-4">
                        <Medal size={18} className="text-orange-500" />
                        <h3 className="font-bold text-slate-800">综合 KPI 排名</h3>
                    </div>
                    <div className="space-y-3">
                        {(teamKpi?.rankings || []).slice(0, 8).map((item, index) => (
                            <div key={item.userId} className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
                                <div className="flex items-center gap-3">
                                    <span className="w-6 h-6 rounded bg-white border border-slate-200 flex items-center justify-center text-xs font-black text-slate-600">{index + 1}</span>
                                    <div>
                                        <div className="text-sm font-bold text-slate-800">{item.userName || item.userId}</div>
                                        <div className="text-xs text-slate-500">质量 {item.averageQualityScore} / 准时 {item.onTimeRate}% / 返工 {item.reworkCount}</div>
                                    </div>
                                </div>
                                <div className="text-right">
                                    <div className="text-lg font-black text-orange-600">{item.finalPoints}</div>
                                    <div className="text-xs text-slate-400">最终积分</div>
                                </div>
                            </div>
                        ))}
                        {(!teamKpi?.rankings || teamKpi.rankings.length === 0) && (
                            <div className="text-center py-8 text-slate-400 bg-slate-50 rounded-lg">暂无已结算 KPI</div>
                        )}
                    </div>
                </div>

                <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
                    <div className="flex items-center gap-2 mb-4">
                        <Award size={18} className="text-slate-500" />
                        <h3 className="font-bold text-slate-800">积分明细</h3>
                    </div>
                    <div className="space-y-3">
                        {details.slice(0, 8).map(item => (
                            <div key={item.taskId} className="p-3 bg-slate-50 rounded-lg">
                                <div className="flex items-center justify-between gap-3">
                                    <div className="min-w-0">
                                        <div className="font-bold text-sm text-slate-800 truncate">{item.taskTitle}</div>
                                        <div className="text-xs text-slate-500 mt-1">{item.assigneeName || item.assigneeId} · 质量 {item.qualityScore || '-'} · {item.onTime ? '准时' : '延期'}</div>
                                    </div>
                                    <div className="text-right shrink-0">
                                        <div className="font-black text-orange-600">{item.finalPoints}</div>
                                        <div className="text-xs text-slate-400">/{item.basePoints}</div>
                                    </div>
                                </div>
                            </div>
                        ))}
                        {details.length === 0 && (
                            <div className="text-center py-8 text-slate-400 bg-slate-50 rounded-lg">暂无积分明细</div>
                        )}
                    </div>
                </div>
            </div>

            <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm mt-6">
                <div className="flex items-center gap-2 mb-4">
                    <TrendingUp size={18} className="text-slate-500" />
                    <h3 className="font-bold text-slate-800">规则配置</h3>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-3 text-sm">
                    <div className="bg-slate-50 rounded-lg p-3">
                        <div className="font-bold text-slate-700 mb-2">质量系数</div>
                        <div className="text-slate-500">5分=1.2，4分=1.0，3分=0.85，2分=0.6，1分=0</div>
                    </div>
                    <div className="bg-slate-50 rounded-lg p-3">
                        <div className="font-bold text-slate-700 mb-2">准时系数</div>
                        <div className="text-slate-500">准时=1.0，报备延期=0.9，轻微延期=0.7，严重延期=0.5</div>
                    </div>
                    <div className="bg-slate-50 rounded-lg p-3">
                        <div className="font-bold text-slate-700 mb-2">返工扣减</div>
                        <div className="text-slate-500">每次返工扣基础积分10%，最多扣到基础积分50%</div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default StatsPage;
