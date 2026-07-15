import React, { useEffect, useMemo, useState } from 'react';
import { Modal } from 'antd';
import {
    AlertTriangle,
    Award,
    CalendarCheck,
    CheckCircle2,
    Clock3,
    Gauge,
    ListTodo,
    Medal,
    RefreshCw,
    ShieldCheck,
    Sparkles,
    Trophy,
    Users,
} from 'lucide-react';
import {
    generateKpiSnapshot,
    getAssigneeTasks,
    getKpiSnapshots,
    getTeamKpi,
    KpiSnapshot,
    KpiSummaryDTO,
    TaskMarketDTO,
    TeamKpiDTO,
} from '../../api/marketplace';
import { getTaskStageLabel, getTaskStatusLabel } from './marketplaceLabels';

type RankingDimension = 'overall' | 'volume' | 'active' | 'quality' | 'ontime' | 'risk';

const numberFormatter = new Intl.NumberFormat('zh-CN');

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

const toNumber = (value?: number | null) => value ?? 0;

const getDisplayName = (item: KpiSummaryDTO | KpiSnapshot) => {
    if ('userName' in item && item.userName) return item.userName;
    return item.userId;
};

const getTaskVolume = (item: KpiSummaryDTO) =>
    toNumber(item.completedTaskCount) + toNumber(item.activeTaskCount) + toNumber(item.pausedTaskCount);

const getRiskCount = (item: KpiSummaryDTO) => toNumber(item.reworkCount) + toNumber(item.overdueCount);

const formatNumber = (value?: number | null) => numberFormatter.format(toNumber(value));

const formatRate = (value?: number | null) => `${toNumber(value).toFixed(1)}%`;

const formatQuality = (value?: number | null) => toNumber(value).toFixed(1);

const formatDateTime = (value?: string) => value ? new Date(value).toLocaleString('zh-CN', { hour12: false }) : '-';

const isClosedTaskStatus = (status?: string) => ['COMPLETED', 'CANCELLED'].includes(status || '');

const isOverdueTask = (task: TaskMarketDTO) => {
    if (!task.deadline || isClosedTaskStatus(task.status)) return false;
    return new Date(task.deadline).getTime() < Date.now();
};

const getTaskStatusBadgeClass = (status?: string) => {
    if (status === 'COMPLETED') return 'bg-emerald-50 text-emerald-700';
    if (status === 'CANCELLED') return 'bg-slate-100 text-slate-500';
    if (status === 'WAITING_REVIEW') return 'bg-orange-50 text-orange-700';
    if (status === 'REWORK') return 'bg-rose-50 text-rose-600';
    if (status === 'PAUSED') return 'bg-amber-50 text-amber-700';
    if (status === 'IN_PROGRESS') return 'bg-blue-50 text-blue-700';
    return 'bg-slate-100 text-slate-700';
};

const rankTieBreak = (a: KpiSummaryDTO, b: KpiSummaryDTO) => {
    const byPoints = toNumber(b.finalPoints) - toNumber(a.finalPoints);
    if (byPoints !== 0) return byPoints;
    const byCompleted = toNumber(b.completedTaskCount) - toNumber(a.completedTaskCount);
    if (byCompleted !== 0) return byCompleted;
    return getDisplayName(a).localeCompare(getDisplayName(b), 'zh-Hans-CN');
};

const sortRankings = (rankings: KpiSummaryDTO[], dimension: RankingDimension) => {
    return [...rankings].sort((a, b) => {
        if (dimension === 'quality') {
            return toNumber(b.averageQualityScore) - toNumber(a.averageQualityScore) || rankTieBreak(a, b);
        }
        if (dimension === 'ontime') {
            return toNumber(b.onTimeRate) - toNumber(a.onTimeRate)
                || toNumber(a.overdueCount) - toNumber(b.overdueCount)
                || rankTieBreak(a, b);
        }
        if (dimension === 'volume') {
            return toNumber(b.completedTaskCount) - toNumber(a.completedTaskCount)
                || toNumber(b.activeTaskCount) - toNumber(a.activeTaskCount)
                || rankTieBreak(a, b);
        }
        if (dimension === 'active') {
            return toNumber(b.activeTaskCount) - toNumber(a.activeTaskCount)
                || toNumber(b.pausedTaskCount) - toNumber(a.pausedTaskCount)
                || toNumber(b.overdueCount) - toNumber(a.overdueCount)
                || rankTieBreak(a, b);
        }
        if (dimension === 'risk') {
            return getRiskCount(a) - getRiskCount(b)
                || toNumber(a.overdueCount) - toNumber(b.overdueCount)
                || rankTieBreak(a, b);
        }
        return rankTieBreak(a, b);
    });
};

const RANKING_OPTIONS: Array<{ key: RankingDimension; label: string; valueLabel: string }> = [
    { key: 'overall', label: '综合积分', valueLabel: '最终积分' },
    { key: 'volume', label: '完成量', valueLabel: '完成任务' },
    { key: 'active', label: '当前负载', valueLabel: '在办任务' },
    { key: 'quality', label: '质量', valueLabel: '平均质量' },
    { key: 'ontime', label: '准时率', valueLabel: '准时率' },
    { key: 'risk', label: '风险控制', valueLabel: '返工+逾期' },
];

const getDimensionValue = (item: KpiSummaryDTO, dimension: RankingDimension) => {
    if (dimension === 'quality') return formatQuality(item.averageQualityScore);
    if (dimension === 'ontime') return formatRate(item.onTimeRate);
    if (dimension === 'volume') return formatNumber(item.completedTaskCount);
    if (dimension === 'active') return formatNumber(item.activeTaskCount);
    if (dimension === 'risk') return formatNumber(getRiskCount(item));
    return formatNumber(item.finalPoints);
};

const StatsPage: React.FC = () => {
    const [teamKpi, setTeamKpi] = useState<TeamKpiDTO | null>(null);
    const [snapshots, setSnapshots] = useState<KpiSnapshot[]>([]);
    const [dateRange, setDateRange] = useState(getCurrentMonthRange);
    const [snapshotPeriod, setSnapshotPeriod] = useState(getCurrentPeriod);
    const [rankingDimension, setRankingDimension] = useState<RankingDimension>('overall');
    const [loading, setLoading] = useState(true);
    const [loadError, setLoadError] = useState('');
    const [generatingSnapshot, setGeneratingSnapshot] = useState(false);
    const [selectedMember, setSelectedMember] = useState<KpiSummaryDTO | null>(null);
    const [memberTasks, setMemberTasks] = useState<TaskMarketDTO[]>([]);
    const [memberTasksLoading, setMemberTasksLoading] = useState(false);
    const [memberTasksError, setMemberTasksError] = useState('');

    const fetchStats = async () => {
        setLoading(true);
        setLoadError('');
        try {
            const [teamRes, snapshotRes] = await Promise.all([
                getTeamKpi(dateRange),
                getKpiSnapshots({ period: snapshotPeriod }),
            ]);
            setTeamKpi(teamRes || null);
            setSnapshots(snapshotRes || []);
        } catch (error) {
            console.error('Failed to fetch KPI dashboard', error);
            setTeamKpi(null);
            setSnapshots([]);
            setLoadError('KPI 数据加载失败，请稍后重试');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchStats();
    }, [dateRange.startDate, dateRange.endDate, snapshotPeriod]);

    const resetToCurrentMonth = () => {
        setDateRange(getCurrentMonthRange());
        setSnapshotPeriod(getCurrentPeriod());
    };

    const applyRecentDays = (days: number) => {
        const end = new Date();
        const start = new Date();
        start.setDate(end.getDate() - days + 1);
        setDateRange({
            startDate: formatDateInput(start),
            endDate: formatDateInput(end),
        });
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

    const openMemberDetail = async (member: KpiSummaryDTO) => {
        setSelectedMember(member);
        setMemberTasks([]);
        setMemberTasksError('');
        setMemberTasksLoading(true);
        try {
            const taskPage = await getAssigneeTasks(member.userId, {
                current: 1,
                size: 500,
            });
            setMemberTasks(taskPage?.records || []);
        } catch (error) {
            console.error('Failed to fetch KPI member tasks', error);
            setMemberTasksError('人员任务列表加载失败，请稍后重试');
        } finally {
            setMemberTasksLoading(false);
        }
    };

    const closeMemberDetail = () => {
        setSelectedMember(null);
        setMemberTasks([]);
        setMemberTasksError('');
        setMemberTasksLoading(false);
    };

    const rankings = teamKpi?.rankings || [];
    const sortedRankings = useMemo(
        () => sortRankings(rankings, rankingDimension),
        [rankings, rankingDimension]
    );
    const selectedRankingOption = RANKING_OPTIONS.find(option => option.key === rankingDimension) || RANKING_OPTIONS[0];

    const totalCompletedTasks = useMemo(
        () => rankings.reduce((sum, item) => sum + toNumber(item.completedTaskCount), 0),
        [rankings]
    );
    const totalActiveTasks = teamKpi?.inProgressTasks ?? rankings.reduce((sum, item) => sum + toNumber(item.activeTaskCount), 0);
    const totalPausedTasks = teamKpi?.pausedTasks ?? rankings.reduce((sum, item) => sum + toNumber(item.pausedTaskCount), 0);
    const totalOverdueTasks = teamKpi?.overdueTasks ?? rankings.reduce((sum, item) => sum + toNumber(item.overdueCount), 0);
    const totalReworkCount = rankings.reduce((sum, item) => sum + toNumber(item.reworkCount), 0);
    const totalHighPriorityTasks = rankings.reduce((sum, item) => sum + toNumber(item.highPriorityTaskCount), 0);
    const completionRate = teamKpi && teamKpi.totalWorks > 0
        ? Math.round((toNumber(teamKpi.completedWorks) / toNumber(teamKpi.totalWorks)) * 100)
        : 0;
    const settledRate = teamKpi && teamKpi.totalPointPool > 0
        ? Math.round((toNumber(teamKpi.settledPoints) / toNumber(teamKpi.totalPointPool)) * 100)
        : 0;
    const weightedQuality = totalCompletedTasks > 0
        ? rankings.reduce((sum, item) => sum + toNumber(item.averageQualityScore) * toNumber(item.completedTaskCount), 0) / totalCompletedTasks
        : 0;
    const weightedOnTimeRate = totalCompletedTasks > 0
        ? rankings.reduce((sum, item) => sum + toNumber(item.onTimeRate) * toNumber(item.completedTaskCount), 0) / totalCompletedTasks
        : 0;
    const workloadRankings = useMemo(
        () => [...rankings]
            .sort((a, b) => getTaskVolume(b) - getTaskVolume(a) || toNumber(b.overdueCount) - toNumber(a.overdueCount) || rankTieBreak(a, b))
            .slice(0, 8),
        [rankings]
    );
    const maxWorkload = Math.max(...workloadRankings.map(getTaskVolume), 1);

    if (loading && !teamKpi) {
        return (
            <div className="flex h-full items-center justify-center text-sm text-slate-400">
                <RefreshCw size={18} className="mr-2 animate-spin text-blue-500" />
                正在加载 KPI 看板...
            </div>
        );
    }

    if (!teamKpi && loadError) {
        return (
            <div className="flex h-full flex-col items-center justify-center gap-4 text-sm text-slate-500">
                <AlertTriangle size={30} className="text-rose-500" />
                <div>{loadError}</div>
                <button
                    type="button"
                    onClick={fetchStats}
                    className="inline-flex items-center gap-2 rounded-lg bg-slate-900 px-3 py-2 text-sm font-bold text-white hover:bg-slate-800"
                >
                    <RefreshCw size={15} />重新加载
                </button>
            </div>
        );
    }

    return (
        <div className="h-full overflow-y-auto p-6">
            <div className="mb-5 flex flex-wrap items-start justify-between gap-4">
                <div>
                    <h2 className="text-xl font-bold text-slate-900">KPI 看板</h2>
                    <p className="mt-1 text-sm text-slate-500">团队任务量、交付质量与当前负载</p>
                </div>
                <button
                    type="button"
                    onClick={fetchStats}
                    disabled={loading}
                    className="inline-flex items-center gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-bold text-slate-700 transition-colors hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-60"
                >
                    <RefreshCw size={15} className={loading ? 'animate-spin' : ''} />
                    刷新
                </button>
            </div>

            <div className="mb-4 flex flex-wrap items-center gap-3 rounded-lg border border-slate-200 bg-slate-50 px-4 py-3">
                <div className="flex items-center gap-2 text-sm font-bold text-slate-700">
                    <CalendarCheck size={16} className="text-blue-600" />
                    KPI 周期
                </div>
                <input
                    type="date"
                    value={dateRange.startDate}
                    max={dateRange.endDate}
                    onChange={event => event.target.value && setDateRange(prev => ({ ...prev, startDate: event.target.value }))}
                    className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm text-slate-700 outline-none focus:border-blue-400"
                />
                <span className="text-sm text-slate-400">至</span>
                <input
                    type="date"
                    value={dateRange.endDate}
                    min={dateRange.startDate}
                    onChange={event => event.target.value && setDateRange(prev => ({ ...prev, endDate: event.target.value }))}
                    className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm text-slate-700 outline-none focus:border-blue-400"
                />
                <div className="flex items-center gap-1 rounded-lg bg-white p-1">
                    <button type="button" onClick={resetToCurrentMonth} className="rounded-md px-2.5 py-1 text-xs font-bold text-slate-500 hover:bg-blue-50 hover:text-blue-600">本月</button>
                    <button type="button" onClick={() => applyRecentDays(30)} className="rounded-md px-2.5 py-1 text-xs font-bold text-slate-500 hover:bg-blue-50 hover:text-blue-600">近30天</button>
                    <button type="button" onClick={() => applyRecentDays(90)} className="rounded-md px-2.5 py-1 text-xs font-bold text-slate-500 hover:bg-blue-50 hover:text-blue-600">近90天</button>
                </div>
                <span className="ml-auto text-xs text-slate-400">公开团队口径</span>
            </div>

            {loadError && (
                <div className="mb-4 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-700">
                    {loadError}
                </div>
            )}

            <div className="mb-4 grid grid-cols-2 gap-3 lg:grid-cols-4 2xl:grid-cols-7">
                <MetricCard
                    icon={<Users size={17} />}
                    label="参评成员"
                    value={formatNumber(rankings.length)}
                    hint={`${formatNumber(totalCompletedTasks)} 个已完成任务`}
                    tone="blue"
                />
                <MetricCard
                    icon={<ListTodo size={17} />}
                    label="当前在办"
                    value={formatNumber(totalActiveTasks)}
                    hint={`不含暂停，逾期 ${formatNumber(totalOverdueTasks)}`}
                    tone={totalOverdueTasks > 0 ? 'rose' : 'cyan'}
                />
                <MetricCard
                    icon={<Clock3 size={17} />}
                    label="暂停中"
                    value={formatNumber(totalPausedTasks)}
                    hint="已从当前在办拆出"
                    tone={totalPausedTasks > 0 ? 'amber' : 'slate'}
                />
                <MetricCard
                    icon={<Award size={17} />}
                    label="已结算积分"
                    value={formatNumber(teamKpi?.settledPoints)}
                    hint={`积分池完成 ${settledRate}%`}
                    tone="amber"
                />
                <MetricCard
                    icon={<CheckCircle2 size={17} />}
                    label="需求完成率"
                    value={`${completionRate}%`}
                    hint={`${formatNumber(teamKpi?.completedWorks)} / ${formatNumber(teamKpi?.totalWorks)} 个需求`}
                    tone="emerald"
                />
                <MetricCard
                    icon={<Gauge size={17} />}
                    label="平均质量"
                    value={formatQuality(weightedQuality)}
                    hint={`准时 ${formatRate(weightedOnTimeRate)}`}
                    tone="violet"
                />
                <MetricCard
                    icon={<AlertTriangle size={17} />}
                    label="返工与逾期"
                    value={formatNumber(totalReworkCount + totalOverdueTasks)}
                    hint={`高优先级 ${formatNumber(totalHighPriorityTasks)}`}
                    tone={(totalReworkCount + totalOverdueTasks) > 0 ? 'rose' : 'slate'}
                />
            </div>

            <div className="grid grid-cols-1 gap-4 2xl:grid-cols-[minmax(0,1.35fr)_380px]">
                <section className="overflow-hidden rounded-lg border border-slate-200 bg-white">
                    <div className="flex flex-wrap items-start justify-between gap-3 border-b border-slate-100 px-4 py-3">
                        <div>
                            <div className="flex items-center gap-2 text-sm font-bold text-slate-900">
                                <Trophy size={17} className="text-amber-500" />
                                排名榜单
                            </div>
                            <div className="mt-1 text-xs text-slate-400">当前排序：{selectedRankingOption.label}</div>
                        </div>
                        <div className="flex flex-wrap items-center gap-1 rounded-lg bg-slate-50 p-1">
                            {RANKING_OPTIONS.map(option => (
                                <button
                                    key={option.key}
                                    type="button"
                                    onClick={() => setRankingDimension(option.key)}
                                    className={`rounded-md px-2.5 py-1 text-xs font-bold transition-colors ${
                                        rankingDimension === option.key
                                            ? 'bg-white text-blue-600 shadow-sm'
                                            : 'text-slate-500 hover:bg-white hover:text-slate-800'
                                    }`}
                                >
                                    {option.label}
                                </button>
                            ))}
                        </div>
                    </div>

                    {sortedRankings.length === 0 ? (
                        <div className="flex min-h-[360px] items-center justify-center text-sm text-slate-400">
                            当前周期暂无 KPI 数据
                        </div>
                    ) : (
                        <>
                            <div className="grid grid-cols-1 gap-3 border-b border-slate-100 p-4 lg:grid-cols-3">
                                {sortedRankings.slice(0, 3).map((item, index) => (
                                    <TopRankItem
                                        key={item.userId}
                                        item={item}
                                        rank={index + 1}
                                        value={getDimensionValue(item, rankingDimension)}
                                        valueLabel={selectedRankingOption.valueLabel}
                                        onViewDetail={openMemberDetail}
                                    />
                                ))}
                            </div>
                            <div className="overflow-x-auto">
                                <table className="w-full min-w-[1120px] table-fixed text-sm">
                                    <thead className="bg-slate-50 text-xs font-bold text-slate-500">
                                        <tr>
                                            <th className="w-[72px] px-4 py-3 text-left">排名</th>
                                            <th className="w-[190px] px-4 py-3 text-left">成员</th>
                                            <th className="w-[120px] px-4 py-3 text-right">最终积分</th>
                                            <th className="w-[150px] px-4 py-3 text-left">任务量</th>
                                            <th className="w-[130px] px-4 py-3 text-left">准时率</th>
                                            <th className="w-[120px] px-4 py-3 text-left">质量</th>
                                            <th className="w-[140px] px-4 py-3 text-left">风险</th>
                                            <th className="w-[120px] px-4 py-3 text-right">高优先级</th>
                                            <th className="w-[88px] px-4 py-3 text-right">操作</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-slate-100">
                                        {sortedRankings.map((item, index) => (
                                            <tr key={item.userId} className="hover:bg-slate-50/80">
                                                <td className="px-4 py-3">
                                                    <span className={`inline-flex h-7 w-7 items-center justify-center rounded-md text-xs font-black ${getRankClass(index + 1)}`}>
                                                        {index + 1}
                                                    </span>
                                                </td>
                                                <td className="px-4 py-3">
                                                    <div className="truncate font-bold text-slate-800">{getDisplayName(item)}</div>
                                                    <div className="mt-1 text-xs text-slate-400">ID {item.userId}</div>
                                                </td>
                                                <td className="px-4 py-3 text-right">
                                                    <div className="font-black text-amber-600">{formatNumber(item.finalPoints)}</div>
                                                    <div className="mt-1 text-xs text-slate-400">基础 {formatNumber(item.basePoints)}</div>
                                                </td>
                                                <td className="px-4 py-3">
                                                    <div className="text-xs font-bold text-slate-700">
                                                        完成 {formatNumber(item.completedTaskCount)} / 在办 {formatNumber(item.activeTaskCount)} / 暂停 {formatNumber(item.pausedTaskCount)}
                                                    </div>
                                                    <MiniBar value={getTaskVolume(item)} max={maxWorkload} color="bg-blue-500" />
                                                </td>
                                                <td className="px-4 py-3">
                                                    <div className="text-xs font-bold text-emerald-700">{formatRate(item.onTimeRate)}</div>
                                                    <MiniBar value={toNumber(item.onTimeRate)} max={100} color="bg-emerald-500" />
                                                </td>
                                                <td className="px-4 py-3">
                                                    <div className="text-xs font-bold text-violet-700">{formatQuality(item.averageQualityScore)}</div>
                                                    <MiniBar value={toNumber(item.averageQualityScore)} max={5} color="bg-violet-500" />
                                                </td>
                                                <td className="px-4 py-3">
                                                    <div className={`text-xs font-bold ${getRiskCount(item) > 0 ? 'text-rose-600' : 'text-slate-500'}`}>
                                                        返工 {formatNumber(item.reworkCount)} / 逾期 {formatNumber(item.overdueCount)}
                                                    </div>
                                                </td>
                                                <td className="px-4 py-3 text-right font-bold text-slate-700">
                                                    {formatNumber(item.highPriorityTaskCount)}
                                                </td>
                                                <td className="px-4 py-3 text-right">
                                                    <button
                                                        type="button"
                                                        onClick={() => openMemberDetail(item)}
                                                        className="rounded-md px-2.5 py-1 text-xs font-bold text-blue-600 transition-colors hover:bg-blue-50 hover:text-blue-800"
                                                    >
                                                        查看
                                                    </button>
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        </>
                    )}
                </section>

                <div className="space-y-4">
                    <section className="rounded-lg border border-slate-200 bg-white">
                        <div className="flex items-center justify-between border-b border-slate-100 px-4 py-3">
                        <div className="flex items-center gap-2 text-sm font-bold text-slate-900">
                            <Clock3 size={16} className="text-blue-600" />
                            当前任务情况
                        </div>
                        <div className="flex items-center gap-1.5">
                            <span className="rounded-md bg-blue-50 px-2 py-0.5 text-xs font-bold text-blue-700">
                                在办 {formatNumber(totalActiveTasks)}
                            </span>
                            <span className="rounded-md bg-amber-50 px-2 py-0.5 text-xs font-bold text-amber-700">
                                暂停 {formatNumber(totalPausedTasks)}
                            </span>
                        </div>
                        </div>
                        {workloadRankings.length === 0 ? (
                            <div className="px-4 py-10 text-center text-sm text-slate-400">暂无人员任务量</div>
                        ) : (
                            <div className="divide-y divide-slate-100">
                                {workloadRankings.map(item => (
                                    <div key={item.userId} className="px-4 py-3">
                                        <div className="mb-2 flex items-center justify-between gap-3">
                                            <div className="min-w-0 truncate text-sm font-bold text-slate-800">{getDisplayName(item)}</div>
                                            <div className="flex shrink-0 items-center gap-2">
                                                <span className="text-xs font-bold text-slate-500">
                                                    在办 {formatNumber(item.activeTaskCount)}
                                                </span>
                                                <button
                                                    type="button"
                                                    onClick={() => openMemberDetail(item)}
                                                    className="rounded px-1.5 py-0.5 text-xs font-bold text-blue-600 hover:bg-blue-50"
                                                >
                                                    查看
                                                </button>
                                            </div>
                                        </div>
                                        <MiniBar value={getTaskVolume(item)} max={maxWorkload} color={toNumber(item.overdueCount) > 0 ? 'bg-rose-500' : 'bg-cyan-500'} />
                                        <div className="mt-2 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-slate-500">
                                            <span>完成 {formatNumber(item.completedTaskCount)}</span>
                                            <span>在办 {formatNumber(item.activeTaskCount)}</span>
                                            <span className={toNumber(item.pausedTaskCount) > 0 ? 'font-bold text-amber-600' : ''}>
                                                暂停 {formatNumber(item.pausedTaskCount)}
                                            </span>
                                            <span className={toNumber(item.overdueCount) > 0 ? 'font-bold text-rose-600' : ''}>
                                                逾期 {formatNumber(item.overdueCount)}
                                            </span>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}
                    </section>

                    <section className="rounded-lg border border-slate-200 bg-white">
                        <div className="border-b border-slate-100 px-4 py-3">
                            <div className="flex flex-wrap items-center justify-between gap-3">
                                <div className="flex items-center gap-2 text-sm font-bold text-slate-900">
                                    <Medal size={16} className="text-amber-500" />
                                    月度快照
                                </div>
                                <div className="flex items-center gap-2">
                                    <input
                                        type="month"
                                        value={snapshotPeriod}
                                        onChange={event => event.target.value && setSnapshotPeriod(event.target.value)}
                                        className="rounded-md border border-slate-200 px-2 py-1 text-xs text-slate-700 outline-none focus:border-blue-400"
                                    />
                                    <button
                                        type="button"
                                        onClick={handleGenerateSnapshot}
                                        disabled={generatingSnapshot}
                                        className="inline-flex items-center gap-1.5 rounded-md bg-slate-900 px-2.5 py-1.5 text-xs font-bold text-white hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-60"
                                    >
                                        {generatingSnapshot ? <RefreshCw size={13} className="animate-spin" /> : <Sparkles size={13} />}
                                        生成
                                    </button>
                                </div>
                            </div>
                        </div>
                        {snapshots.length === 0 ? (
                            <div className="px-4 py-10 text-center text-sm text-slate-400">当前月份暂无快照</div>
                        ) : (
                            <div className="divide-y divide-slate-100">
                                {snapshots.slice(0, 6).map((snapshot, index) => (
                                    <div key={snapshot.id} className="flex items-center justify-between gap-3 px-4 py-3">
                                        <div className="flex min-w-0 items-center gap-3">
                                            <span className={`inline-flex h-6 w-6 shrink-0 items-center justify-center rounded-md text-xs font-black ${getRankClass(index + 1)}`}>
                                                {index + 1}
                                            </span>
                                            <div className="min-w-0">
                                                <div className="truncate text-sm font-bold text-slate-800">{getDisplayName(snapshot)}</div>
                                                <div className="mt-1 text-xs text-slate-400">
                                                    质量 {formatQuality(snapshot.averageQualityScore)} / 准时 {formatRate(snapshot.onTimeRate)}
                                                </div>
                                            </div>
                                        </div>
                                        <div className="shrink-0 text-right">
                                            <div className="font-black text-amber-600">{formatNumber(snapshot.finalPoints)}</div>
                                            <div className="text-xs text-slate-400">积分</div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}
                    </section>

                    <section className="rounded-lg border border-slate-200 bg-white px-4 py-3">
                        <div className="mb-3 flex items-center gap-2 text-sm font-bold text-slate-900">
                            <ShieldCheck size={16} className="text-emerald-600" />
                            指标构成
                        </div>
                        <div className="grid grid-cols-2 gap-2 text-xs">
                            <IndicatorPill label="任务量" value="完成 + 在办" />
                            <IndicatorPill label="质量" value="验收评分" />
                            <IndicatorPill label="准时" value="提交不晚于截止" />
                            <IndicatorPill label="风险" value="返工 + 逾期" />
                        </div>
                    </section>
                </div>
            </div>

            <MemberDetailModal
                member={selectedMember}
                tasks={memberTasks}
                loading={memberTasksLoading}
                error={memberTasksError}
                onClose={closeMemberDetail}
            />
        </div>
    );
};

interface MetricCardProps {
    icon: React.ReactNode;
    label: string;
    value: string | number;
    hint: string;
    tone: 'blue' | 'cyan' | 'emerald' | 'amber' | 'rose' | 'violet' | 'slate';
}

const METRIC_TONE_CLASSES: Record<MetricCardProps['tone'], string> = {
    blue: 'bg-blue-50 text-blue-600',
    cyan: 'bg-cyan-50 text-cyan-600',
    emerald: 'bg-emerald-50 text-emerald-600',
    amber: 'bg-amber-50 text-amber-600',
    rose: 'bg-rose-50 text-rose-600',
    violet: 'bg-violet-50 text-violet-600',
    slate: 'bg-slate-100 text-slate-600',
};

const MetricCard: React.FC<MetricCardProps> = ({ icon, label, value, hint, tone }) => (
    <div className="rounded-lg border border-slate-200 bg-white p-4">
        <div className="flex items-center justify-between gap-3">
            <span className="text-xs font-bold text-slate-500">{label}</span>
            <span className={`rounded-lg p-2 ${METRIC_TONE_CLASSES[tone]}`}>{icon}</span>
        </div>
        <div className="mt-3 text-2xl font-black text-slate-900">{value}</div>
        <div className="mt-1 truncate text-xs text-slate-400">{hint}</div>
    </div>
);

const TopRankItem: React.FC<{
    item: KpiSummaryDTO;
    rank: number;
    value: string;
    valueLabel: string;
    onViewDetail: (item: KpiSummaryDTO) => void;
}> = ({ item, rank, value, valueLabel, onViewDetail }) => (
    <div className="rounded-lg border border-slate-200 bg-slate-50 px-4 py-3">
        <div className="mb-3 flex items-start justify-between gap-3">
            <div className="min-w-0">
                <div className="truncate text-sm font-black text-slate-900">{getDisplayName(item)}</div>
                <div className="mt-1 text-xs text-slate-400">
                    完成 {formatNumber(item.completedTaskCount)} / 在办 {formatNumber(item.activeTaskCount)} / 暂停 {formatNumber(item.pausedTaskCount)}
                </div>
            </div>
            <span className={`inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-md text-sm font-black ${getRankClass(rank)}`}>
                {rank}
            </span>
        </div>
        <div className="text-2xl font-black text-slate-900">{value}</div>
        <div className="mt-1 text-xs text-slate-400">{valueLabel}</div>
        <div className="mt-3 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-slate-500">
            <span>质量 {formatQuality(item.averageQualityScore)}</span>
            <span>准时 {formatRate(item.onTimeRate)}</span>
            <span className={getRiskCount(item) > 0 ? 'font-bold text-rose-600' : ''}>风险 {formatNumber(getRiskCount(item))}</span>
        </div>
        <button
            type="button"
            onClick={() => onViewDetail(item)}
            className="mt-3 inline-flex items-center gap-1.5 rounded-md bg-white px-2.5 py-1.5 text-xs font-bold text-blue-600 shadow-sm ring-1 ring-slate-200 transition-colors hover:bg-blue-50 hover:text-blue-800"
        >
            <Users size={13} />
            人员详情
        </button>
    </div>
);

const MiniBar: React.FC<{ value: number; max: number; color: string }> = ({ value, max, color }) => (
    <div className="mt-2 h-1.5 overflow-hidden rounded-full bg-slate-100">
        <div
            className={`h-full rounded-full ${color}`}
            style={{ width: `${Math.min(100, max > 0 ? (value / max) * 100 : 0)}%` }}
        />
    </div>
);

const IndicatorPill: React.FC<{ label: string; value: string }> = ({ label, value }) => (
    <div className="rounded-md bg-slate-50 px-3 py-2">
        <div className="font-bold text-slate-700">{label}</div>
        <div className="mt-1 text-slate-400">{value}</div>
    </div>
);

const MemberDetailModal: React.FC<{
    member: KpiSummaryDTO | null;
    tasks: TaskMarketDTO[];
    loading: boolean;
    error: string;
    onClose: () => void;
}> = ({ member, tasks, loading, error, onClose }) => {
    const completedTasks = tasks.filter(task => task.status === 'COMPLETED').length;
    const activeTasks = tasks.filter(task => !isClosedTaskStatus(task.status) && task.status !== 'PAUSED').length;
    const pausedTasks = tasks.filter(task => task.status === 'PAUSED').length;
    const overdueTasks = tasks.filter(isOverdueTask).length;
    const waitingReviewTasks = tasks.filter(task => task.status === 'WAITING_REVIEW').length;
    const totalFinalPoints = tasks.reduce((sum, task) => sum + toNumber(task.finalPoints), 0);
    const totalBasePoints = tasks.reduce((sum, task) => sum + toNumber(task.points), 0);
    const statusSummary = ['READY', 'IN_PROGRESS', 'WAITING_REVIEW', 'REWORK', 'PAUSED', 'COMPLETED', 'CANCELLED']
        .map(status => ({
            status,
            count: tasks.filter(task => task.status === status).length,
        }))
        .filter(item => item.count > 0);

    return (
        <Modal
            title={member ? `${getDisplayName(member)} · 任务情况` : '任务情况'}
            open={!!member}
            onCancel={onClose}
            footer={null}
            width={1080}
            destroyOnHidden
        >
            {member && (
                <div className="space-y-4 pt-2">
                    <div className="flex flex-wrap items-center justify-between gap-3 rounded-lg bg-slate-50 px-4 py-3">
                        <div>
                            <div className="text-sm font-bold text-slate-800">{getDisplayName(member)}</div>
                            <div className="mt-1 text-xs text-slate-400">范围：该人员全部已分配任务，最多展示前 500 条</div>
                        </div>
                        <div className="text-xs text-slate-400">用户 ID：{member.userId}</div>
                    </div>

                    <div className="grid grid-cols-2 gap-3 md:grid-cols-5">
                        <PersonMetric label="全部任务" value={formatNumber(tasks.length)} hint={`基础积分 ${formatNumber(totalBasePoints)}`} tone="blue" />
                        <PersonMetric label="当前在办" value={formatNumber(activeTasks)} hint={`不含暂停，待审核 ${formatNumber(waitingReviewTasks)}`} tone="emerald" />
                        <PersonMetric label="暂停中" value={formatNumber(pausedTasks)} hint="单独统计暂停任务" tone={pausedTasks > 0 ? 'amber' : 'slate'} />
                        <PersonMetric label="已完成" value={formatNumber(completedTasks)} hint={`最终积分 ${formatNumber(totalFinalPoints)}`} tone="amber" />
                        <PersonMetric label="逾期风险" value={formatNumber(overdueTasks)} hint={`KPI 返工 ${formatNumber(member.reworkCount)}`} tone={overdueTasks > 0 ? 'rose' : 'slate'} />
                    </div>

                    <div className="overflow-hidden rounded-lg border border-slate-200">
                        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-100 bg-white px-4 py-3">
                            <div>
                                <div className="text-sm font-bold text-slate-900">全部任务台账</div>
                                <div className="mt-1 text-xs text-slate-400">
                                    {tasks.length} 个任务，{activeTasks} 个在办，{pausedTasks} 个暂停，{overdueTasks} 个已逾期
                                </div>
                            </div>
                            {loading && (
                                <div className="inline-flex items-center gap-2 text-xs font-bold text-blue-600">
                                    <RefreshCw size={13} className="animate-spin" />
                                    加载中
                                </div>
                            )}
                        </div>
                        {error ? (
                            <div className="bg-rose-50 px-4 py-6 text-center text-sm text-rose-600">{error}</div>
                        ) : loading ? (
                            <div className="px-4 py-10 text-center text-sm text-slate-400">正在加载人员任务...</div>
                        ) : tasks.length === 0 ? (
                            <div className="px-4 py-10 text-center text-sm text-slate-400">该人员暂无已分配任务</div>
                        ) : (
                            <>
                                <div className="flex flex-wrap gap-2 border-b border-slate-100 bg-slate-50 px-4 py-3">
                                    {statusSummary.map(item => (
                                        <span key={item.status} className={`rounded px-2 py-1 text-xs font-bold ${getTaskStatusBadgeClass(item.status)}`}>
                                            {getTaskStatusLabel(item.status)} {formatNumber(item.count)}
                                        </span>
                                    ))}
                                </div>
                                <div className="max-h-[420px] overflow-auto">
                                    <table className="w-full min-w-[1040px] table-fixed text-sm">
                                        <thead className="sticky top-0 z-10 bg-slate-50 text-xs font-bold text-slate-500 shadow-[0_1px_0_0_#e2e8f0]">
                                            <tr>
                                                <th className="w-[250px] px-4 py-3 text-left">任务</th>
                                                <th className="w-[210px] px-4 py-3 text-left">所属需求</th>
                                                <th className="w-[130px] px-4 py-3 text-left">状态 / 阶段</th>
                                                <th className="w-[160px] px-4 py-3 text-left">截止日期</th>
                                                <th className="w-[110px] px-4 py-3 text-right">积分</th>
                                                <th className="w-[120px] px-4 py-3 text-left">质量 / 返工</th>
                                                <th className="w-[160px] px-4 py-3 text-left">更新时间</th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-slate-100">
                                            {tasks.map(task => (
                                                <tr key={task.id} className="hover:bg-slate-50/80">
                                                    <td className="px-4 py-3">
                                                        <div className="truncate font-bold text-slate-800">{task.title}</div>
                                                        <div className="mt-1 text-xs text-slate-400">{task.taskRole === 'MAIN' ? '主任务' : '子任务'} · {task.taskType || '未分类'}</div>
                                                    </td>
                                                    <td className="px-4 py-3">
                                                        <div className="truncate text-slate-700">{task.workTitle || '-'}</div>
                                                        <div className="mt-1 text-xs text-slate-400">{task.requirementNumber || '-'}</div>
                                                    </td>
                                                    <td className="px-4 py-3">
                                                        <span className={`rounded px-1.5 py-0.5 text-xs font-bold ${getTaskStatusBadgeClass(task.status)}`}>
                                                            {getTaskStatusLabel(task.status)}
                                                        </span>
                                                        <div className="mt-1 text-xs text-slate-400">{getTaskStageLabel(task.currentStage, task.status)}</div>
                                                    </td>
                                                    <td className="px-4 py-3 text-xs">
                                                        <div className={isOverdueTask(task) ? 'font-bold text-rose-600' : 'text-slate-600'}>
                                                            {formatDateTime(task.deadline)}
                                                        </div>
                                                        {isOverdueTask(task) && <div className="mt-1 text-rose-500">已逾期</div>}
                                                    </td>
                                                    <td className="px-4 py-3 text-right">
                                                        <div className="font-black text-amber-600">{formatNumber(task.finalPoints)}</div>
                                                        <div className="mt-1 text-xs text-slate-400">基础 {formatNumber(task.points)}</div>
                                                    </td>
                                                    <td className="px-4 py-3 text-xs">
                                                        <div className="font-bold text-violet-700">质量 {task.qualityScore ?? '-'}</div>
                                                        <div className="mt-1 text-slate-500">返工 {formatNumber(task.reworkCount)}</div>
                                                    </td>
                                                    <td className="px-4 py-3 text-xs text-slate-500">{formatDateTime(task.updateTime)}</td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>
                                </div>
                            </>
                        )}
                    </div>
                </div>
            )}
        </Modal>
    );
};

const PERSON_METRIC_TONE_CLASSES: Record<'amber' | 'blue' | 'emerald' | 'rose' | 'slate', string> = {
    amber: 'text-amber-600',
    blue: 'text-blue-600',
    emerald: 'text-emerald-600',
    rose: 'text-rose-600',
    slate: 'text-slate-700',
};

const PersonMetric: React.FC<{
    label: string;
    value: string | number;
    hint: string;
    tone: 'amber' | 'blue' | 'emerald' | 'rose' | 'slate';
}> = ({ label, value, hint, tone }) => (
    <div className="rounded-lg border border-slate-200 bg-white px-4 py-3">
        <div className="text-xs font-bold text-slate-500">{label}</div>
        <div className={`mt-2 text-2xl font-black ${PERSON_METRIC_TONE_CLASSES[tone]}`}>{value}</div>
        <div className="mt-1 truncate text-xs text-slate-400">{hint}</div>
    </div>
);

const getRankClass = (rank: number) => {
    if (rank === 1) return 'bg-amber-100 text-amber-700';
    if (rank === 2) return 'bg-slate-200 text-slate-700';
    if (rank === 3) return 'bg-orange-100 text-orange-700';
    return 'bg-slate-100 text-slate-600';
};

export default StatsPage;
