import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
    Area,
    CartesianGrid,
    Cell,
    ComposedChart,
    Legend,
    Line,
    Pie,
    PieChart,
    ResponsiveContainer,
    Tooltip,
    XAxis,
    YAxis,
} from 'recharts';
import ReactMarkdown from 'react-markdown';
import { Calendar, ConfigProvider, Modal } from 'antd';
import zhCN from 'antd/locale/zh_CN';
import {
    BarChart3,
    Bot,
    Building2,
    CalendarRange,
    CheckCircle2,
    CircleAlert,
    Clock3,
    Loader2,
    RefreshCw,
    Sparkles,
    TrendingUp,
} from 'lucide-react';
import dayjs from 'dayjs';
import {
    getIncompleteWorkCalendarTasks,
    getWorkTasks,
    getWorkStatistics,
    WorkCalendarTask,
    WorkStatistics as WorkStatisticsData,
    WorkStatisticsSystemTask,
    WorkTask,
} from '../../api/marketplace';
import { streamChatResponse } from '../../api/chat';
import { getSystemList } from '../../api/ops';
import { searchUsers } from '../../api/user';
import { getTaskStageLabel, getTaskStatusLabel, getWorkStatusLabel } from './marketplaceLabels';

const WORK_STATUS_COLORS: Record<string, string> = {
    DRAFT: '#94a3b8',
    PUBLISHED: '#6366f1',
    ACTIVE: '#2563eb',
    PAUSED: '#f59e0b',
    ACCEPTANCE: '#f97316',
    COMPLETED: '#16a34a',
    CANCELLED: '#cbd5e1',
};

const formatDateTime = (value?: string) => value ? dayjs(value).format('YYYY-MM-DD HH:mm') : '-';
const isPausedTask = (status?: string) => status?.toUpperCase() === 'PAUSED';

const WorkStatistics: React.FC = () => {
    const [startDate, setStartDate] = useState(() => dayjs().startOf('year').format('YYYY-MM-DD'));
    const [endDate, setEndDate] = useState(() => dayjs().format('YYYY-MM-DD'));
    const [statistics, setStatistics] = useState<WorkStatisticsData | null>(null);
    const [assigneeLabels, setAssigneeLabels] = useState<Record<string, string>>({});
    const [systemNames, setSystemNames] = useState<Record<string, string>>({});
    const [loading, setLoading] = useState(true);
    const [loadError, setLoadError] = useState('');
    const [aiSummary, setAiSummary] = useState('');
    const [aiGenerating, setAiGenerating] = useState(false);
    const [aiError, setAiError] = useState('');
    const [aiGeneratedAt, setAiGeneratedAt] = useState('');
    const [isAiSummaryOpen, setIsAiSummaryOpen] = useState(false);
    const [calendarDate, setCalendarDate] = useState(() => dayjs());
    const [calendarTasks, setCalendarTasks] = useState<WorkCalendarTask[]>([]);
    const [calendarLoading, setCalendarLoading] = useState(true);
    const [calendarLoadError, setCalendarLoadError] = useState('');
    const [calendarWorkTasks, setCalendarWorkTasks] = useState<Record<string, WorkTask[]>>({});
    const [calendarDetailLoading, setCalendarDetailLoading] = useState(false);
    const [calendarDetailError, setCalendarDetailError] = useState('');
    const aiAbortControllerRef = useRef<AbortController | null>(null);
    const minStartDate = useMemo(() => dayjs(endDate).subtract(366, 'day').format('YYYY-MM-DD'), [endDate]);
    const maxEndDate = useMemo(() => {
        const today = dayjs();
        const maxFromStart = dayjs(startDate).add(366, 'day');
        return maxFromStart.isBefore(today) ? maxFromStart.format('YYYY-MM-DD') : today.format('YYYY-MM-DD');
    }, [startDate]);

    const resolveAssigneeLabels = async (data: WorkStatisticsData) => {
        const assigneeIds = Array.from(new Set([
            ...data.assigneeWorkloads.map(item => item.assigneeId),
            ...data.attentionItems.map(item => item.assigneeId),
        ].filter((id): id is string => Boolean(id) && id !== 'UNASSIGNED')));

        const entries = await Promise.all(assigneeIds.map(async (assigneeId) => {
            try {
                const users = await searchUsers(assigneeId);
                const matched = users.find(user => user.id.toString() === assigneeId) || users[0];
                return [assigneeId, matched?.name || assigneeId] as const;
            } catch {
                return [assigneeId, assigneeId] as const;
            }
        }));
        setAssigneeLabels(Object.fromEntries(entries));
    };

    const fetchStatistics = async () => {
        setLoading(true);
        setLoadError('');
        aiAbortControllerRef.current?.abort();
        setAiSummary('');
        setAiError('');
        setAiGeneratedAt('');
        try {
            const data = await getWorkStatistics({ startDate, endDate });
            setStatistics(data);
            await resolveAssigneeLabels(data);
        } catch (error) {
            console.error('Failed to fetch work statistics', error);
            setStatistics(null);
            setLoadError('需求统计加载失败，请稍后重试');
        } finally {
            setLoading(false);
        }
    };

    const fetchIncompleteCalendarTasks = async () => {
        setCalendarLoading(true);
        setCalendarLoadError('');
        try {
            const tasks = await getIncompleteWorkCalendarTasks({
                startDate: calendarDate.startOf('month').format('YYYY-MM-DD'),
                endDate: calendarDate.endOf('month').format('YYYY-MM-DD'),
            });
            setCalendarTasks((tasks || []).filter(task => !isPausedTask(task.status)));
        } catch (error) {
            console.error('Failed to fetch incomplete calendar tasks', error);
            setCalendarTasks([]);
            setCalendarLoadError('日历任务加载失败，请稍后重试');
        } finally {
            setCalendarLoading(false);
        }
    };

    useEffect(() => {
        fetchStatistics();
    }, [startDate, endDate]);

    useEffect(() => {
        getSystemList({ showAll: true })
            .then(systems => setSystemNames(Object.fromEntries(
                (systems || []).map(system => [String(system.id), system.name])
            )))
            .catch(error => console.error('Failed to fetch systems', error));
    }, []);

    const calendarMonth = calendarDate.format('YYYY-MM');

    useEffect(() => {
        fetchIncompleteCalendarTasks();
    }, [calendarMonth]);

    useEffect(() => () => aiAbortControllerRef.current?.abort(), []);

    const renderAssignee = (assigneeId?: string) => {
        if (!assigneeId || assigneeId === 'UNASSIGNED') return '未分配';
        return assigneeLabels[assigneeId] || assigneeId;
    };

    const renderTaskSystems = (systemIds?: number[]) => {
        if (!systemIds?.length) return '未设置';
        return systemIds.map(systemId => systemNames[String(systemId)] || `系统 ${systemId}`).join('、');
    };

    const trendData = useMemo(() => (statistics?.workTrend || []).map(item => ({
        ...item,
        displayDate: dayjs(item.date).format('MM-DD'),
    })), [statistics]);

    const workStatusData = useMemo(() => (statistics?.workStatusDistribution || []).map(item => ({
        ...item,
        label: getWorkStatusLabel(item.name),
    })), [statistics]);

    const systemTaskData = useMemo(
        () => statistics?.systemTaskStats || [],
        [statistics]
    );
    const calendarTasksByDate = useMemo(() => calendarTasks.reduce<Record<string, WorkCalendarTask[]>>((tasksByDate, task) => {
        const date = dayjs(task.deadline).format('YYYY-MM-DD');
        tasksByDate[date] = [...(tasksByDate[date] || []), task];
        return tasksByDate;
    }, {}), [calendarTasks]);
    const calendarWorksByDate = useMemo(() => Object.fromEntries(
        Object.entries(calendarTasksByDate).map(([date, tasks]) => [
            date,
            Array.from(new Set(tasks.map(task => task.workId))),
        ])
    ) as Record<string, string[]>, [calendarTasksByDate]);
    const selectedCalendarDate = calendarDate.format('YYYY-MM-DD');
    const selectedCalendarTasks = useMemo(
        () => calendarTasksByDate[selectedCalendarDate] || [],
        [calendarTasksByDate, selectedCalendarDate]
    );
    const selectedCalendarWorks = useMemo(() => Array.from(new Map(
        selectedCalendarTasks.map(task => [task.workId, { id: task.workId, title: task.workTitle }])
    ).values()), [selectedCalendarTasks]);

    useEffect(() => {
        let cancelled = false;
        if (selectedCalendarWorks.length === 0) {
            setCalendarWorkTasks({});
            setCalendarDetailError('');
            setCalendarDetailLoading(false);
            return undefined;
        }

        const loadCalendarWorkDetails = async () => {
            setCalendarDetailLoading(true);
            setCalendarDetailError('');
            try {
                const detailEntries = await Promise.all(selectedCalendarWorks.map(async work => [
                    work.id,
                    await getWorkTasks(work.id),
                ] as const));
                if (cancelled) return;

                const taskMap = Object.fromEntries(detailEntries.map(([workId, tasks]) => [
                    workId,
                    (tasks || []).filter(task => !isPausedTask(task.status)),
                ])) as Record<string, WorkTask[]>;
                setCalendarWorkTasks(taskMap);
                const assigneeIds = Array.from(new Set(Object.values(taskMap)
                    .flat()
                    .map(task => task.assigneeId)
                    .filter((id): id is string => Boolean(id))));
                const assigneeEntries = await Promise.all(assigneeIds.map(async assigneeId => {
                    try {
                        const users = await searchUsers(assigneeId);
                        const matched = users.find(user => user.id.toString() === assigneeId) || users[0];
                        return [assigneeId, matched?.name || assigneeId] as const;
                    } catch {
                        return [assigneeId, assigneeId] as const;
                    }
                }));
                if (!cancelled) {
                    setAssigneeLabels(previous => ({ ...previous, ...Object.fromEntries(assigneeEntries) }));
                }
            } catch (error) {
                console.error('Failed to fetch calendar work details', error);
                if (!cancelled) {
                    setCalendarWorkTasks({});
                    setCalendarDetailError('需求任务明细加载失败，请稍后重试');
                }
            } finally {
                if (!cancelled) setCalendarDetailLoading(false);
            }
        };

        loadCalendarWorkDetails();
        return () => {
            cancelled = true;
        };
    }, [selectedCalendarWorks]);

    const buildAiPrompt = (data: WorkStatisticsData) => {
        const workStatuses = data.workStatusDistribution
            .map(item => `${getWorkStatusLabel(item.name)} ${item.value} 个`)
            .join('、') || '暂无';
        const taskStatuses = data.taskStatusDistribution
            .map(item => `${getTaskStatusLabel(item.name)} ${item.value} 个`)
            .join('、') || '暂无';
        const workloads = data.assigneeWorkloads
            .slice(0, 5)
            .map(item => `${renderAssignee(item.assigneeId)}：总任务 ${item.totalCount}，已完成 ${item.completedCount}，待推进 ${Math.max(item.activeCount - item.pausedCount - item.overdueCount, 0)}，暂停 ${item.pausedCount}，逾期 ${item.overdueCount}`)
            .join('\n') || '暂无';
        const attentionItems = data.attentionItems
            .slice(0, 8)
            .map(item => `- ${item.workTitle} / ${item.taskTitle}：状态 ${getTaskStatusLabel(item.status)}，${item.overdue ? '已逾期' : item.attentionMessage || '阶段时限预警'}`)
            .join('\n') || '暂无';

        return `你是项目管理助手。请基于以下真实统计数据，生成简洁、专业的中文需求进展概要。
统计时间：${data.startDate} 至 ${data.endDate}，口径为按需求创建时间筛选，状态为查询时现状。
需求：共 ${data.totalWorks} 个，已完成 ${data.completedWorks} 个；状态分布：${workStatuses}。
任务现状：已完成 ${data.completedTasks} 个，进行中 ${data.activeTasks} 个，完成率 ${data.completionRate}%，逾期 ${data.overdueTasks} 个，风险报备 ${data.riskTasks} 个；状态分布：${taskStatuses}。
人员负载：
${workloads}
重点关注：
${attentionItems}

请严格只使用以上数据，不推测未提供的原因、时间或责任人。按以下四个小节输出 Markdown，每节 1-3 条短句：
### 整体进展
### 本期亮点
### 风险提醒
### 下一步建议`;
    };

    const generateAiSummary = async () => {
        if (!statistics || aiGenerating) return;

        aiAbortControllerRef.current?.abort();
        const controller = new AbortController();
        aiAbortControllerRef.current = controller;
        setAiSummary('');
        setAiError('');
        setAiGeneratedAt('');
        setAiGenerating(true);
        let content = '';

        await streamChatResponse(
            buildAiPrompt(statistics),
            chunk => {
                if (aiAbortControllerRef.current !== controller) return;
                content += chunk;
                setAiSummary(content);
            },
            () => {
                if (aiAbortControllerRef.current !== controller) return;
                setAiGenerating(false);
                setAiGeneratedAt(dayjs().format('YYYY-MM-DD HH:mm:ss'));
            },
            controller.signal
        );

        if (aiAbortControllerRef.current !== controller) return;
        setAiGenerating(false);
        if (!content.trim()) {
            setAiError('AI 暂未返回总结，请稍后重试');
        } else {
            setAiGeneratedAt(dayjs().format('YYYY-MM-DD HH:mm:ss'));
        }
    };

    const openAiSummary = () => {
        setIsAiSummaryOpen(true);
        if (!aiSummary && !aiGenerating) {
            generateAiSummary();
        }
    };

    const applyPreset = (days: number) => {
        setStartDate(dayjs().subtract(days - 1, 'day').format('YYYY-MM-DD'));
        setEndDate(dayjs().format('YYYY-MM-DD'));
    };

    if (loading) {
        return (
            <div className="flex min-h-[420px] items-center justify-center rounded-xl border border-slate-200 bg-white">
                <div className="flex items-center gap-3 text-sm text-slate-500">
                    <Loader2 size={20} className="animate-spin text-blue-500" />
                    正在汇总需求进展...
                </div>
            </div>
        );
    }

    if (!statistics || loadError) {
        return (
            <div className="flex min-h-[420px] flex-col items-center justify-center rounded-xl border border-dashed border-slate-200 bg-slate-50">
                <CircleAlert size={28} className="mb-3 text-rose-400" />
                <div className="text-sm text-slate-500">{loadError || '暂无统计数据'}</div>
                <button
                    type="button"
                    onClick={fetchStatistics}
                    className="mt-4 inline-flex items-center gap-2 rounded-lg bg-slate-900 px-3 py-2 text-sm font-bold text-white hover:bg-slate-800"
                >
                    <RefreshCw size={15} />重新加载
                </button>
            </div>
        );
    }

    return (
        <div className="space-y-4 pb-6">
            <div className="flex flex-wrap items-center gap-3 rounded-xl border border-slate-200 bg-white px-4 py-3 shadow-sm">
                <div className="flex items-center gap-2 text-sm font-bold text-slate-700">
                    <CalendarRange size={16} className="text-blue-600" />
                    统计时间
                </div>
                <input
                    type="date"
                    value={startDate}
                    min={minStartDate}
                    max={endDate}
                    onChange={event => event.target.value && setStartDate(event.target.value)}
                    className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-700 outline-none focus:border-blue-400"
                />
                <span className="text-sm text-slate-400">至</span>
                <input
                    type="date"
                    value={endDate}
                    min={startDate}
                    max={maxEndDate}
                    onChange={event => event.target.value && setEndDate(event.target.value)}
                    className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-700 outline-none focus:border-blue-400"
                />
                <div className="flex items-center gap-1 rounded-lg bg-slate-50 p-1">
                    {[7, 30, 90].map(days => (
                        <button
                            key={days}
                            type="button"
                            onClick={() => applyPreset(days)}
                            className="rounded-md px-2.5 py-1 text-xs font-bold text-slate-500 transition-colors hover:bg-white hover:text-blue-600 hover:shadow-sm"
                        >
                            近{days}天
                        </button>
                    ))}
                </div>
                <button
                    type="button"
                    onClick={fetchStatistics}
                    className="inline-flex items-center gap-1.5 rounded-lg px-2.5 py-1.5 text-xs font-bold text-slate-500 transition-colors hover:bg-slate-100 hover:text-blue-600"
                >
                    <RefreshCw size={14} />刷新
                </button>
                <div className="ml-auto flex flex-wrap items-center gap-3">
                    <span className="text-xs text-slate-400">统计口径：按需求创建时间筛选，展示当前任务状态</span>
                    <button
                        type="button"
                        onClick={openAiSummary}
                        disabled={statistics.totalWorks === 0}
                        className="inline-flex items-center gap-1.5 rounded-lg bg-indigo-600 px-3 py-1.5 text-xs font-bold text-white transition-colors hover:bg-indigo-500 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        {aiGenerating ? <Loader2 size={14} className="animate-spin" /> : <Sparkles size={14} />}
                        {aiGenerating ? '正在生成' : 'AI 需求概要'}
                    </button>
                </div>
            </div>

            <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-5">
                <MetricCard
                    icon={<BarChart3 size={17} />}
                    label="需求总数"
                    value={statistics.totalWorks}
                    hint="按需求创建时间统计"
                    color="blue"
                />
                <MetricCard
                    icon={<CheckCircle2 size={17} />}
                    label="完成需求数"
                    value={statistics.completedWorks}
                    hint="当前已完成需求"
                    color="green"
                />
                <MetricCard
                    icon={<Clock3 size={17} />}
                    label="进行中"
                    value={statistics.activeWorks}
                    hint="当前进行中需求"
                    color="indigo"
                />
                <MetricCard
                    icon={<Sparkles size={17} />}
                    label="暂停需求数"
                    value={statistics.pausedWorks}
                    hint="当前已暂停需求"
                    color="amber"
                />
                <MetricCard
                    icon={<CircleAlert size={17} />}
                    label="逾期需求"
                    value={statistics.overdueWorks}
                    hint="未完成且已过期需求"
                    color="red"
                />
            </div>

            <div className="flex flex-col gap-4">
                <div className="order-2 grid grid-cols-1 gap-4 xl:grid-cols-3">
                <ChartCard icon={<TrendingUp size={16} className="text-blue-600" />} title="需求趋势" subtitle="按统计时间展示新建与完成需求">
                    {trendData.some(item => item.createdWorkCount > 0 || item.completedWorkCount > 0) ? (
                        <ResponsiveContainer width="100%" height={250} minWidth={0}>
                            <ComposedChart data={trendData} margin={{ top: 8, right: 12, left: -18, bottom: 0 }}>
                                <defs>
                                    <linearGradient id="completionTrendFill" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor="#2563eb" stopOpacity={0.28} />
                                        <stop offset="95%" stopColor="#2563eb" stopOpacity={0.02} />
                                    </linearGradient>
                                </defs>
                                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" vertical={false} />
                                <XAxis dataKey="displayDate" tick={{ fontSize: 11, fill: '#64748b' }} minTickGap={28} />
                                <YAxis allowDecimals={false} tick={{ fontSize: 11, fill: '#64748b' }} />
                                <Tooltip labelFormatter={label => `${label}`} formatter={value => [`${value} 个`]} />
                                <Legend iconType="circle" wrapperStyle={{ fontSize: 12 }} />
                                <Area
                                    type="monotone"
                                    dataKey="completedWorkCount"
                                    stroke="#2563eb"
                                    strokeWidth={2}
                                    fill="url(#completionTrendFill)"
                                    name="完成需求"
                                />
                                <Line
                                    type="monotone"
                                    dataKey="createdWorkCount"
                                    stroke="#f59e0b"
                                    strokeWidth={2}
                                    dot={false}
                                    activeDot={{ r: 4 }}
                                    name="新增需求"
                                />
                            </ComposedChart>
                        </ResponsiveContainer>
                    ) : <EmptyChart text="该时间段内暂无需求趋势数据" />}
                </ChartCard>

                <ChartCard icon={<CheckCircle2 size={16} className="text-emerald-600" />} title="需求状态分布" subtitle="区间内需求的当前状态">
                    {workStatusData.length > 0 ? (
                        <ResponsiveContainer width="100%" height={250} minWidth={0}>
                            <PieChart>
                                <Pie
                                    data={workStatusData}
                                    dataKey="value"
                                    nameKey="label"
                                    innerRadius={52}
                                    outerRadius={82}
                                    paddingAngle={2}
                                >
                                    {workStatusData.map(item => (
                                        <Cell key={item.name} fill={WORK_STATUS_COLORS[item.name] || '#94a3b8'} />
                                    ))}
                                </Pie>
                                <Tooltip formatter={value => [`${value} 个`, '需求数']} />
                                <Legend iconType="circle" wrapperStyle={{ fontSize: 12 }} />
                            </PieChart>
                        </ResponsiveContainer>
                    ) : <EmptyChart text="该时间段内暂无需求" />}
                </ChartCard>

                <ChartCard
                    icon={<Building2 size={16} className="text-indigo-600" />}
                    title="涉及系统任务统计"
                    subtitle={systemTaskData.length > 0
                        ? `全部展示 ${systemTaskData.length} 个有需求系统，按有效任务量降序`
                        : "需求、完成与逾期数量"}
                >
                    {systemTaskData.length > 0 ? (
                        <SystemTaskList data={systemTaskData} />
                    ) : <EmptyChart text="暂无涉及系统的任务数据" />}
                </ChartCard>

                </div>

                <div className="order-1 grid items-stretch grid-cols-1 gap-4 xl:h-[800px] xl:grid-cols-[minmax(0,1.1fr)_minmax(420px,.9fr)]">
                <section className="h-full overflow-hidden rounded-xl border border-blue-100 bg-white shadow-sm">
                    <div className="border-b border-blue-100 bg-blue-50/60 px-4 py-3">
                        <div>
                            <div className="flex items-center gap-2 text-sm font-bold text-slate-800">
                                <CalendarRange size={17} className="text-blue-600" />
                              日历
                            </div>
                            <div className="mt-1 text-xs text-slate-500">按任务截止日期展示未完成事项，点击日期查看明细</div>
                        </div>
                    </div>
                    <div className="p-3">
                        <ConfigProvider locale={zhCN}>
                            <Calendar
                                fullscreen={false}
                                value={calendarDate}
                                onSelect={setCalendarDate}
                                onPanelChange={setCalendarDate}
                                dateCellRender={date => {
                                    const requirementCount = calendarWorksByDate[date.format('YYYY-MM-DD')]?.length || 0;
                                    return requirementCount > 0 ? (
                                        <div className="mt-0.5 truncate rounded bg-rose-50 px-1 text-center text-[10px] font-bold leading-4 text-rose-600">
                                            {requirementCount}
                                        </div>
                                    ) : null;
                                }}
                            />
                        </ConfigProvider>
                    </div>
                    <div className="border-t border-slate-100 px-4 py-3">
                        <div className="mb-2 flex items-center justify-between gap-3 text-xs">
                            <span className="font-bold text-slate-700">{selectedCalendarDate} 需求任务</span>
                            <span className="rounded-full bg-rose-50 px-2 py-0.5 font-bold text-rose-600">{selectedCalendarWorks.length} 个需求</span>
                        </div>
                        {calendarLoading ? (
                            <div className="flex h-20 items-center justify-center text-xs text-slate-400">
                                <Loader2 size={15} className="mr-2 animate-spin" />加载中...
                            </div>
                        ) : calendarLoadError ? (
                            <div className="py-3 text-xs text-rose-600">{calendarLoadError}</div>
                        ) : selectedCalendarWorks.length === 0 ? (
                            <div className="py-3 text-xs text-slate-400">当天没有未完成任务</div>
                        ) : calendarDetailLoading ? (
                            <div className="flex h-20 items-center justify-center text-xs text-slate-400">
                                <Loader2 size={15} className="mr-2 animate-spin" />加载需求任务树...
                            </div>
                        ) : calendarDetailError ? (
                            <div className="py-3 text-xs text-rose-600">{calendarDetailError}</div>
                        ) : (
                            <div className="max-h-72 space-y-3 overflow-y-auto pr-1">
                                {selectedCalendarWorks.map(work => {
                                    const tasks = calendarWorkTasks[work.id] || [];
                                    const mainTask = tasks.find(task => task.taskRole === 'MAIN');
                                    const subTasks = tasks.filter(task => task.taskRole !== 'MAIN');
                                    const renderTask = (task: WorkTask, isSubTask = false) => (
                                        <div key={task.id} className={`min-w-0 rounded-md border border-slate-100 bg-slate-50 px-2.5 py-2 ${isSubTask ? 'ml-5 before:-ml-4 before:text-slate-300 before:content-["└"]' : ''}`}>
                                            <div className="flex min-w-0 items-center gap-2">
                                                <span className={`shrink-0 rounded px-1.5 py-0.5 text-[10px] font-bold ${isSubTask ? 'bg-slate-200 text-slate-600' : 'bg-blue-100 text-blue-700'}`}>
                                                    {isSubTask ? '子任务' : '主任务'}
                                                </span>
                                                <span className="min-w-0 flex-1 truncate text-xs font-bold text-slate-700">{task.title}</span>
                                                <span className="shrink-0 text-[10px] text-blue-600">{getTaskStageLabel(task.currentStage, task.status)}</span>
                                                <span className="shrink-0 text-[10px] text-slate-500">{renderAssignee(task.assigneeId)}</span>
                                            </div>
                                            <div className="mt-1 flex min-w-0 items-center gap-3 text-[10px] text-slate-500">
                                                <span className="min-w-0 flex-1 truncate">对应系统：{renderTaskSystems(task.involvedSystemIds)}</span>
                                                <span className="shrink-0">截止：{formatDateTime(task.deadline)}</span>
                                            </div>
                                        </div>
                                    );
                                    return (
                                        <div key={work.id} className="rounded-lg border border-slate-200 bg-white p-2.5">
                                            <div className="mb-2 flex items-center justify-between gap-2 border-b border-slate-100 pb-2">
                                                <span className="min-w-0 truncate text-xs font-bold text-slate-800">{work.title}</span>
                                                <span className="shrink-0 text-[10px] text-slate-400">{tasks.length} 个任务</span>
                                            </div>
                                            <div className="space-y-1.5">
                                                {mainTask ? renderTask(mainTask) : null}
                                                {subTasks.map(task => renderTask(task, true))}
                                                {tasks.length === 0 && <div className="py-1 text-[11px] text-slate-400">暂无任务</div>}
                                            </div>
                                        </div>
                                    );
                                })}
                            </div>
                        )}
                    </div>
                </section>

                <section className="flex h-full min-h-0 flex-col overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
                    <div className="flex shrink-0 items-center justify-between border-b border-slate-100 px-4 py-3">
                        <div>
                            <div className="flex items-center gap-2 text-sm font-bold text-slate-800">
                                <CircleAlert size={16} className="text-amber-500" />
                                重点关注
                            </div>
                            <div className="mt-1 text-xs text-slate-400">展示全部逾期、提测与质量验收时限预警</div>
                        </div>
                        <span className="rounded-full bg-amber-50 px-2 py-0.5 text-xs font-bold text-amber-700">
                            {statistics.attentionItems.length}
                        </span>
                    </div>
                    {statistics.attentionItems.length === 0 ? (
                        <div className="flex flex-1 flex-col items-center justify-center text-sm text-slate-400">
                            <CheckCircle2 size={26} className="mb-3 text-emerald-400" />
                            当前没有逾期或阶段时限预警
                        </div>
                    ) : (
                        <div className="min-h-0 flex-1 divide-y divide-slate-100 overflow-y-auto">
                            {statistics.attentionItems.map(item => (
                                <div key={item.taskId} className="px-4 py-3 transition-colors hover:bg-slate-50">
                                    <div className="flex items-start justify-between gap-3">
                                        <div className="min-w-0">
                                            <div className="flex items-center gap-2">
                                                <span className={`shrink-0 rounded px-1.5 py-0.5 text-[10px] font-bold ${item.taskRole === 'MAIN' ? 'bg-blue-100 text-blue-700' : 'bg-slate-200 text-slate-600'}`}>
                                                    {item.taskRole === 'MAIN' ? '主任务' : '子任务'}
                                                </span>
                                                <span className="min-w-0 truncate text-sm font-bold text-slate-800">{item.taskTitle}</span>
                                            </div>
                                            <div className="mt-1 truncate text-xs text-slate-400">{item.workTitle}</div>
                                        </div>
                                        <div className="flex shrink-0 items-center gap-1">
                                            {item.overdue && (
                                                <span className="rounded bg-rose-50 px-1.5 py-0.5 text-[11px] font-bold text-rose-600">逾期</span>
                                            )}
                                            {item.attentionType === 'TEST_SUBMISSION' && (
                                                <span className="rounded bg-blue-50 px-1.5 py-0.5 text-[11px] font-bold text-blue-700">提测预警</span>
                                            )}
                                            {item.attentionType === 'QUALITY_ACCEPTANCE' && (
                                                <span className="rounded bg-purple-50 px-1.5 py-0.5 text-[11px] font-bold text-purple-700">质量验收预警</span>
                                            )}
                                        </div>
                                    </div>
                                    <div className="mt-2 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-slate-500">
                                        <span>{renderAssignee(item.assigneeId)}</span>
                                        <span>{getTaskStatusLabel(item.status)}</span>
                                        <span>任务截止日期 {formatDateTime(item.deadline)}</span>
                                    </div>
                                    {item.attentionMessage && (
                                        <div className={`mt-2 rounded-md px-2.5 py-2 text-xs leading-5 ${item.overdue ? 'bg-rose-50/70 text-rose-800' : 'bg-blue-50/70 text-blue-800'}`}>
                                            {item.attentionMessage}
                                        </div>
                                    )}
                                </div>
                            ))}
                        </div>
                    )}
                </section>
                </div>
            </div>
            <Modal
                open={isAiSummaryOpen}
                title={(
                    <span className="flex items-center gap-2 text-slate-800">
                        <Bot size={18} className="text-indigo-600" />
                        AI 需求概要
                    </span>
                )}
                footer={null}
                width={640}
                onCancel={() => setIsAiSummaryOpen(false)}
            >
                <div className="mb-4 flex items-center justify-between gap-3 rounded-lg bg-indigo-50 px-3 py-2 text-xs text-indigo-700">
                    <span>{statistics.startDate} 至 {statistics.endDate}</span>
                    <button
                        type="button"
                        onClick={generateAiSummary}
                        disabled={aiGenerating || statistics.totalWorks === 0}
                        className="inline-flex items-center gap-1.5 rounded-md bg-indigo-600 px-2.5 py-1.5 font-bold text-white transition-colors hover:bg-indigo-500 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        {aiGenerating ? <Loader2 size={13} className="animate-spin" /> : <Sparkles size={13} />}
                        {aiGenerating ? '正在生成' : aiSummary ? '重新生成' : '生成概要'}
                    </button>
                </div>
                {aiError ? (
                    <div className="rounded-lg bg-rose-50 px-4 py-3 text-sm text-rose-600">{aiError}</div>
                ) : aiSummary ? (
                    <div className="prose prose-sm max-h-[60vh] max-w-none overflow-y-auto pr-2 text-slate-700 prose-headings:mb-2 prose-headings:mt-4 prose-headings:text-sm prose-headings:text-slate-900 prose-li:my-1">
                        <ReactMarkdown>{aiSummary}</ReactMarkdown>
                        {aiGeneratedAt && (
                            <div className="mt-5 border-t border-slate-100 pt-3 text-xs text-slate-400">
                                生成时间：{aiGeneratedAt}
                            </div>
                        )}
                    </div>
                ) : (
                    <div className="flex min-h-48 flex-col items-center justify-center text-center">
                        <div className="mb-3 rounded-xl bg-indigo-50 p-3 text-indigo-500">
                            <Bot size={24} />
                        </div>
                        <div className="text-sm font-bold text-slate-700">正在准备需求概要</div>
                        <div className="mt-1 max-w-sm text-xs leading-5 text-slate-400">AI 将严格基于当前统计数据归纳，不会改动需求或任务信息。</div>
                    </div>
                )}
            </Modal>
        </div>
    );
};

interface MetricCardProps {
    icon: React.ReactNode;
    label: string;
    value: string | number;
    hint: string;
    color: 'blue' | 'slate' | 'green' | 'indigo' | 'red' | 'amber';
}

const METRIC_COLOR_CLASSES: Record<MetricCardProps['color'], string> = {
    blue: 'bg-blue-50 text-blue-600',
    slate: 'bg-slate-100 text-slate-600',
    green: 'bg-emerald-50 text-emerald-600',
    indigo: 'bg-indigo-50 text-indigo-600',
    red: 'bg-rose-50 text-rose-600',
    amber: 'bg-amber-50 text-amber-600',
};

const MetricCard: React.FC<MetricCardProps> = ({ icon, label, value, hint, color }) => (
    <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
        <div className="flex items-center justify-between gap-3">
            <span className="text-xs font-bold text-slate-500">{label}</span>
            <span className={`rounded-lg p-2 ${METRIC_COLOR_CLASSES[color]}`}>{icon}</span>
        </div>
        <div className="mt-3 text-2xl font-bold text-slate-900">{value}</div>
        <div className="mt-1 text-xs text-slate-400">{hint}</div>
    </div>
);

interface ChartCardProps {
    icon: React.ReactNode;
    title: string;
    subtitle: string;
    children: React.ReactNode;
}

const ChartCard: React.FC<ChartCardProps> = ({ icon, title, subtitle, children }) => (
    <section className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
        <div className="mb-3 flex items-start gap-2">
            <span className="mt-0.5">{icon}</span>
            <div>
                <h3 className="text-sm font-bold text-slate-800">{title}</h3>
                <p className="mt-0.5 text-xs text-slate-400">{subtitle}</p>
            </div>
        </div>
        {children}
    </section>
);

const EmptyChart: React.FC<{ text: string }> = ({ text }) => (
    <div className="flex h-[250px] items-center justify-center rounded-lg bg-slate-50 text-sm text-slate-400">
        {text}
    </div>
);

const SystemTaskList: React.FC<{ data: WorkStatisticsSystemTask[] }> = ({ data }) => (
    <div className="max-h-[420px] overflow-y-auto pr-1 custom-scrollbar">
        <div className="space-y-2">
            {data.map((item, index) => {
                const completionRate = Math.min(Math.max(item.completionRate || 0, 0), 100);
                return (
                    <div
                        key={`${item.systemName}-${index}`}
                        className="rounded-lg border border-slate-100 bg-slate-50/70 px-3 py-2.5 transition-colors hover:border-indigo-100 hover:bg-indigo-50/40"
                    >
                        <div className="flex items-start justify-between gap-3">
                            <div className="flex min-w-0 items-start gap-2.5">
                                <span className="mt-0.5 flex h-5 min-w-[1.25rem] shrink-0 items-center justify-center rounded-md bg-indigo-50 px-1 text-[11px] font-bold text-indigo-600">
                                    {index + 1}
                                </span>
                                <div className="min-w-0">
                                    <div className="truncate text-sm font-bold text-slate-800" title={item.systemName}>
                                        {item.systemName}
                                    </div>
                                    <div className="mt-1 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-slate-500">
                                        <span>需求 {item.requirementCount}</span>
                                        <span>有效任务 {item.totalTaskCount}</span>
                                        <span>已完成 {item.completedTaskCount}</span>
                                        <span className={item.overdueTaskCount > 0 ? 'font-bold text-rose-600' : ''}>
                                            逾期 {item.overdueTaskCount}
                                        </span>
                                    </div>
                                </div>
                            </div>
                            <div className="shrink-0 text-right">
                                <div className="text-sm font-bold text-slate-800">{item.completionRate}%</div>
                                <div className="text-[11px] text-slate-400">完成率</div>
                            </div>
                        </div>
                        <div className="mt-2 h-1.5 overflow-hidden rounded-full bg-slate-200">
                            <div
                                className="h-full rounded-full bg-emerald-500 transition-all"
                                style={{ width: `${completionRate}%` }}
                            />
                        </div>
                    </div>
                );
            })}
        </div>
    </div>
);

export default WorkStatistics;
