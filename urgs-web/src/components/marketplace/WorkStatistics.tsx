import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
    Area,
    AreaChart,
    Bar,
    BarChart,
    CartesianGrid,
    Cell,
    Legend,
    Pie,
    PieChart,
    ResponsiveContainer,
    Tooltip,
    XAxis,
    YAxis,
} from 'recharts';
import ReactMarkdown from 'react-markdown';
import {
    BarChart3,
    Bot,
    CalendarRange,
    CheckCircle2,
    CircleAlert,
    Clock3,
    Loader2,
    RefreshCw,
    Sparkles,
    TrendingUp,
    Users,
} from 'lucide-react';
import dayjs from 'dayjs';
import {
    getWorkStatistics,
    WorkStatistics as WorkStatisticsData,
    WorkStatisticsAssigneeWorkload,
} from '../../api/marketplace';
import { streamChatResponse } from '../../api/chat';
import { searchUsers } from '../../api/user';
import { getTaskStatusLabel, getWorkStatusLabel } from './marketplaceLabels';

const WORK_STATUS_COLORS: Record<string, string> = {
    DRAFT: '#94a3b8',
    PUBLISHED: '#6366f1',
    ACTIVE: '#2563eb',
    PAUSED: '#f59e0b',
    ACCEPTANCE: '#f97316',
    COMPLETED: '#16a34a',
    CANCELLED: '#cbd5e1',
};

const PROGRESS_COLORS = ['#cbd5e1', '#60a5fa', '#818cf8', '#22c55e', '#94a3b8'];

const formatDate = (value?: string) => value ? dayjs(value).format('YYYY-MM-DD') : '-';

const WorkStatistics: React.FC = () => {
    const [startDate, setStartDate] = useState(() => dayjs().subtract(29, 'day').format('YYYY-MM-DD'));
    const [endDate, setEndDate] = useState(() => dayjs().format('YYYY-MM-DD'));
    const [statistics, setStatistics] = useState<WorkStatisticsData | null>(null);
    const [assigneeLabels, setAssigneeLabels] = useState<Record<string, string>>({});
    const [loading, setLoading] = useState(true);
    const [loadError, setLoadError] = useState('');
    const [aiSummary, setAiSummary] = useState('');
    const [aiGenerating, setAiGenerating] = useState(false);
    const [aiError, setAiError] = useState('');
    const [aiGeneratedAt, setAiGeneratedAt] = useState('');
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
            setLoadError('工作统计加载失败，请稍后重试');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchStatistics();
    }, [startDate, endDate]);

    useEffect(() => () => aiAbortControllerRef.current?.abort(), []);

    const renderAssignee = (assigneeId?: string) => {
        if (!assigneeId || assigneeId === 'UNASSIGNED') return '未分配';
        return assigneeLabels[assigneeId] || assigneeId;
    };

    const trendData = useMemo(() => (statistics?.completionTrend || []).map(item => ({
        ...item,
        displayDate: dayjs(item.date).format('MM-DD'),
    })), [statistics]);

    const workStatusData = useMemo(() => (statistics?.workStatusDistribution || []).map(item => ({
        ...item,
        label: getWorkStatusLabel(item.name),
    })), [statistics]);

    const workloadData = useMemo(() => (statistics?.assigneeWorkloads || []).map(item => ({
        ...item,
        name: renderAssignee(item.assigneeId),
    })), [statistics, assigneeLabels]);

    const buildAiPrompt = (data: WorkStatisticsData) => {
        const workStatuses = data.workStatusDistribution
            .map(item => `${getWorkStatusLabel(item.name)} ${item.value} 个`)
            .join('、') || '暂无';
        const taskStatuses = data.taskStatusDistribution
            .map(item => `${getTaskStatusLabel(item.name)} ${item.value} 个`)
            .join('、') || '暂无';
        const workloads = data.assigneeWorkloads
            .slice(0, 5)
            .map(item => `${renderAssignee(item.assigneeId)}：总任务 ${item.totalCount}，已完成 ${item.completedCount}，待推进 ${item.activeCount}，逾期 ${item.overdueCount}`)
            .join('\n') || '暂无';
        const attentionItems = data.attentionItems
            .slice(0, 8)
            .map(item => `- ${item.workTitle} / ${item.taskTitle}：状态 ${getTaskStatusLabel(item.status)}，${item.overdue ? '已逾期' : '未逾期'}，${item.riskReported ? `存在风险${item.riskNote ? `（${item.riskNote}）` : ''}` : '无风险报备'}`)
            .join('\n') || '暂无';

        return `你是项目管理助手。请基于以下真实统计数据，生成简洁、专业的中文工作进展概要。
统计时间：${data.startDate} 至 ${data.endDate}，口径为按工作创建时间筛选，状态为查询时现状。
工作：共 ${data.totalWorks} 个，已完成 ${data.completedWorks} 个；状态分布：${workStatuses}。
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

    const applyPreset = (days: number) => {
        setStartDate(dayjs().subtract(days - 1, 'day').format('YYYY-MM-DD'));
        setEndDate(dayjs().format('YYYY-MM-DD'));
    };

    if (loading) {
        return (
            <div className="flex min-h-[420px] items-center justify-center rounded-xl border border-slate-200 bg-white">
                <div className="flex items-center gap-3 text-sm text-slate-500">
                    <Loader2 size={20} className="animate-spin text-blue-500" />
                    正在汇总工作进展...
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
                <span className="ml-auto text-xs text-slate-400">统计口径：按工作创建时间筛选，展示当前任务状态</span>
            </div>

            <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-5">
                <MetricCard
                    icon={<BarChart3 size={17} />}
                    label="工作总数"
                    value={statistics.totalWorks}
                    hint={`已完成 ${statistics.completedWorks}`}
                    color="blue"
                />
                <MetricCard
                    icon={<CheckCircle2 size={17} />}
                    label="任务完成率"
                    value={`${statistics.completionRate}%`}
                    hint="已取消任务不计入"
                    color="green"
                />
                <MetricCard
                    icon={<Clock3 size={17} />}
                    label="进行中"
                    value={statistics.activeTasks}
                    hint="含审核与返工"
                    color="indigo"
                />
                <MetricCard
                    icon={<CircleAlert size={17} />}
                    label="逾期任务"
                    value={statistics.overdueTasks}
                    hint="未完成且已过期"
                    color="red"
                />
                <MetricCard
                    icon={<Sparkles size={17} />}
                    label="风险任务"
                    value={statistics.riskTasks}
                    hint="已提交风险报备"
                    color="amber"
                />
            </div>

            <div className="grid grid-cols-1 gap-4 xl:grid-cols-2">
                <ChartCard icon={<TrendingUp size={16} className="text-blue-600" />} title="任务完成趋势" subtitle="按实际完成日期统计">
                    {statistics.completedTasks > 0 ? (
                        <ResponsiveContainer width="100%" height={250} minWidth={0}>
                            <AreaChart data={trendData} margin={{ top: 8, right: 12, left: -18, bottom: 0 }}>
                                <defs>
                                    <linearGradient id="completionTrendFill" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor="#2563eb" stopOpacity={0.28} />
                                        <stop offset="95%" stopColor="#2563eb" stopOpacity={0.02} />
                                    </linearGradient>
                                </defs>
                                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" vertical={false} />
                                <XAxis dataKey="displayDate" tick={{ fontSize: 11, fill: '#64748b' }} minTickGap={28} />
                                <YAxis allowDecimals={false} tick={{ fontSize: 11, fill: '#64748b' }} />
                                <Tooltip labelFormatter={label => `${label}`} formatter={value => [`${value} 个`, '完成任务']} />
                                <Area
                                    type="monotone"
                                    dataKey="completedCount"
                                    stroke="#2563eb"
                                    strokeWidth={2}
                                    fill="url(#completionTrendFill)"
                                    name="完成任务"
                                />
                            </AreaChart>
                        </ResponsiveContainer>
                    ) : <EmptyChart text="该时间段内暂无已完成任务" />}
                </ChartCard>

                <ChartCard icon={<CheckCircle2 size={16} className="text-emerald-600" />} title="工作状态分布" subtitle="区间内工作的当前状态">
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
                                <Tooltip formatter={value => [`${value} 个`, '工作数']} />
                                <Legend iconType="circle" wrapperStyle={{ fontSize: 12 }} />
                            </PieChart>
                        </ResponsiveContainer>
                    ) : <EmptyChart text="该时间段内暂无工作" />}
                </ChartCard>

                <ChartCard icon={<BarChart3 size={16} className="text-indigo-600" />} title="工作进度区间" subtitle="按任务完成比例划分">
                    {statistics.progressDistribution.some(item => item.value > 0) ? (
                        <ResponsiveContainer width="100%" height={250} minWidth={0}>
                            <BarChart data={statistics.progressDistribution} margin={{ top: 8, right: 12, left: -18, bottom: 18 }}>
                                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" vertical={false} />
                                <XAxis dataKey="name" tick={{ fontSize: 10, fill: '#64748b' }} interval={0} />
                                <YAxis allowDecimals={false} tick={{ fontSize: 11, fill: '#64748b' }} />
                                <Tooltip formatter={value => [`${value} 个`, '工作数']} />
                                <Bar dataKey="value" radius={[5, 5, 0, 0]} name="工作数">
                                    {statistics.progressDistribution.map((item, index) => (
                                        <Cell key={item.name} fill={PROGRESS_COLORS[index % PROGRESS_COLORS.length]} />
                                    ))}
                                </Bar>
                            </BarChart>
                        </ResponsiveContainer>
                    ) : <EmptyChart text="暂无可计算的工作进度" />}
                </ChartCard>

                <ChartCard icon={<Users size={16} className="text-cyan-600" />} title="人员任务负载" subtitle="最多展示任务量前 8 人">
                    {workloadData.length > 0 ? (
                        <ResponsiveContainer width="100%" height={250} minWidth={0}>
                            <BarChart data={workloadData} layout="vertical" margin={{ top: 8, right: 18, left: 8, bottom: 0 }}>
                                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" horizontal={false} />
                                <XAxis type="number" allowDecimals={false} tick={{ fontSize: 11, fill: '#64748b' }} />
                                <YAxis
                                    type="category"
                                    dataKey="name"
                                    width={72}
                                    tick={{ fontSize: 11, fill: '#475569' }}
                                    tickFormatter={value => value.length > 6 ? `${value.slice(0, 6)}…` : value}
                                />
                                <Tooltip content={<WorkloadTooltip />} />
                                <Legend iconType="circle" wrapperStyle={{ fontSize: 12 }} />
                                <Bar dataKey="completedCount" name="已完成" stackId="workload" fill="#22c55e" />
                                <Bar dataKey="activeCount" name="待推进" stackId="workload" fill="#60a5fa" radius={[0, 5, 5, 0]} />
                            </BarChart>
                        </ResponsiveContainer>
                    ) : <EmptyChart text="暂无人员任务负载数据" />}
                </ChartCard>
            </div>

            <div className="grid grid-cols-1 gap-4 xl:grid-cols-[minmax(0,1.1fr)_minmax(420px,.9fr)]">
                <section className="overflow-hidden rounded-xl border border-indigo-100 bg-white shadow-sm">
                    <div className="flex flex-wrap items-center justify-between gap-3 border-b border-indigo-100 bg-indigo-50/60 px-4 py-3">
                        <div>
                            <div className="flex items-center gap-2 text-sm font-bold text-slate-800">
                                <Bot size={17} className="text-indigo-600" />
                                AI 工作概要
                            </div>
                            <div className="mt-1 text-xs text-slate-500">基于当前统计数据生成进展、亮点、风险和建议</div>
                        </div>
                        <button
                            type="button"
                            onClick={generateAiSummary}
                            disabled={aiGenerating || statistics.totalWorks === 0}
                            className="inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-3 py-2 text-xs font-bold text-white transition-colors hover:bg-indigo-500 disabled:cursor-not-allowed disabled:opacity-50"
                        >
                            {aiGenerating ? <Loader2 size={14} className="animate-spin" /> : <Sparkles size={14} />}
                            {aiGenerating ? '正在生成' : aiSummary ? '重新生成' : '生成 AI 总结'}
                        </button>
                    </div>
                    <div className="min-h-[280px] p-5">
                        {aiError ? (
                            <div className="rounded-lg bg-rose-50 px-4 py-3 text-sm text-rose-600">{aiError}</div>
                        ) : aiSummary ? (
                            <div className="prose prose-sm max-w-none text-slate-700 prose-headings:mb-2 prose-headings:mt-4 prose-headings:text-sm prose-headings:text-slate-900 prose-li:my-1">
                                <ReactMarkdown>{aiSummary}</ReactMarkdown>
                                {aiGeneratedAt && (
                                    <div className="mt-5 border-t border-slate-100 pt-3 text-xs text-slate-400">
                                        生成时间：{aiGeneratedAt}
                                    </div>
                                )}
                            </div>
                        ) : (
                            <div className="flex min-h-[240px] flex-col items-center justify-center text-center">
                                <div className="mb-3 rounded-xl bg-indigo-50 p-3 text-indigo-500">
                                    <Bot size={24} />
                                </div>
                                <div className="text-sm font-bold text-slate-700">尚未生成工作概要</div>
                                <div className="mt-1 max-w-sm text-xs leading-5 text-slate-400">
                                    AI 将严格基于本页统计数据归纳，不会改动工作或任务信息。
                                </div>
                            </div>
                        )}
                    </div>
                </section>

                <section className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
                    <div className="flex items-center justify-between border-b border-slate-100 px-4 py-3">
                        <div>
                            <div className="flex items-center gap-2 text-sm font-bold text-slate-800">
                                <CircleAlert size={16} className="text-amber-500" />
                                重点关注
                            </div>
                            <div className="mt-1 text-xs text-slate-400">风险与逾期任务，最多展示 10 条</div>
                        </div>
                        <span className="rounded-full bg-amber-50 px-2 py-0.5 text-xs font-bold text-amber-700">
                            {statistics.attentionItems.length}
                        </span>
                    </div>
                    {statistics.attentionItems.length === 0 ? (
                        <div className="flex min-h-[280px] flex-col items-center justify-center text-sm text-slate-400">
                            <CheckCircle2 size={26} className="mb-3 text-emerald-400" />
                            当前没有风险或逾期任务
                        </div>
                    ) : (
                        <div className="max-h-[380px] divide-y divide-slate-100 overflow-y-auto">
                            {statistics.attentionItems.map(item => (
                                <div key={item.taskId} className="px-4 py-3 transition-colors hover:bg-slate-50">
                                    <div className="flex items-start justify-between gap-3">
                                        <div className="min-w-0">
                                            <div className="truncate text-sm font-bold text-slate-800">{item.taskTitle}</div>
                                            <div className="mt-1 truncate text-xs text-slate-400">{item.workTitle}</div>
                                        </div>
                                        <div className="flex shrink-0 items-center gap-1">
                                            {item.riskReported && (
                                                <span className="rounded bg-amber-50 px-1.5 py-0.5 text-[11px] font-bold text-amber-700">风险</span>
                                            )}
                                            {item.overdue && (
                                                <span className="rounded bg-rose-50 px-1.5 py-0.5 text-[11px] font-bold text-rose-600">逾期</span>
                                            )}
                                        </div>
                                    </div>
                                    <div className="mt-2 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-slate-500">
                                        <span>{renderAssignee(item.assigneeId)}</span>
                                        <span>{getTaskStatusLabel(item.status)}</span>
                                        <span>截止 {formatDate(item.deadline)}</span>
                                    </div>
                                    {item.riskNote && (
                                        <div className="mt-2 line-clamp-2 rounded-md bg-amber-50/70 px-2.5 py-2 text-xs leading-5 text-amber-800">
                                            {item.riskNote}
                                        </div>
                                    )}
                                </div>
                            ))}
                        </div>
                    )}
                </section>
            </div>
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

const WorkloadTooltip: React.FC<{
    active?: boolean;
    payload?: Array<{ payload: WorkStatisticsAssigneeWorkload & { name: string } }>;
}> = ({ active, payload }) => {
    if (!active || !payload?.length) return null;
    const data = payload[0].payload;
    return (
        <div className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-xs shadow-lg">
            <div className="mb-1.5 font-bold text-slate-800">{data.name}</div>
            <div className="space-y-1 text-slate-600">
                <div>总任务：{data.totalCount}</div>
                <div>已完成：{data.completedCount}</div>
                <div>待推进：{data.activeCount}</div>
                <div className={data.overdueCount > 0 ? 'font-bold text-rose-600' : ''}>逾期：{data.overdueCount}</div>
            </div>
        </div>
    );
};

export default WorkStatistics;
