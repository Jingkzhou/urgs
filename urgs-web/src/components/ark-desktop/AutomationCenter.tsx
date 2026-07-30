import React, { useMemo, useState } from 'react';
import {
    AlertCircle,
    CalendarClock,
    CheckCircle2,
    ChevronDown,
    Clock3,
    Folder,
    History,
    LoaderCircle,
    MessageCircle,
    Pause,
    Pencil,
    Play,
    Plus,
    Repeat2,
    Search,
    Trash2,
    X,
} from 'lucide-react';
import type { ArkDesktopRuntime } from './useArkDesktopRuntime';
import type { ArkDesktopAutomation, ArkDesktopScheduledTask, ArkDesktopTask } from './types';
import {
    automationScheduleLabel,
    formatAutomationDateTime,
    nextAutomationRunAt,
} from './automationSchedule';

type AutomationFilter = 'all' | 'active' | 'paused' | 'attention';

interface AutomationCenterProps {
    runtime: ArkDesktopRuntime;
    onEdit: (id: string) => void;
}

interface NativeLoop {
    scheduledTask: ArkDesktopScheduledTask;
    ownerTask: ArkDesktopTask;
}

const statusCopy = {
    running: { label: '运行中', className: 'bg-blue-50 text-blue-700', icon: LoaderCircle },
    waiting_authorization: { label: '等待处理', className: 'bg-amber-50 text-amber-700', icon: AlertCircle },
    completed: { label: '运行成功', className: 'bg-emerald-50 text-emerald-700', icon: CheckCircle2 },
    failed: { label: '运行失败', className: 'bg-red-50 text-red-700', icon: AlertCircle },
    cancelled: { label: '已停止', className: 'bg-slate-100 text-slate-600', icon: Pause },
};

const compactToggleClass = (checked: boolean) => `relative h-6 w-11 rounded-full transition-colors ${checked ? 'bg-slate-900' : 'bg-slate-300'}`;

const AutomationToggle: React.FC<{ checked: boolean; label: string; onChange: () => void }> = ({ checked, label, onChange }) => (
    <button type="button" role="switch" aria-checked={checked} aria-label={label} onClick={onChange} className={compactToggleClass(checked)}>
        <span className={`absolute top-1 h-4 w-4 rounded-full bg-white shadow-sm transition-transform ${checked ? 'translate-x-5' : 'translate-x-1'}`} />
    </button>
);

type AutomationRunTarget = 'new-task' | 'existing-task';
type LoopUnit = 'm' | 'h' | 'd';

const createAutomationId = () => `automation-${Date.now()}-${Math.random().toString(16).slice(2)}`;

const AutomationCreator: React.FC<{ runtime: ArkDesktopRuntime; onClose: () => void }> = ({ runtime, onClose }) => {
    const [title, setTitle] = useState('');
    const [prompt, setPrompt] = useState('');
    const [runTarget, setRunTarget] = useState<AutomationRunTarget>('new-task');
    const [schedule, setSchedule] = useState<ArkDesktopAutomation['schedule']>('daily');
    const [scheduleTime, setScheduleTime] = useState('09:00');
    const [scheduleWeekday, setScheduleWeekday] = useState(1);
    const [interval, setInterval] = useState(15);
    const [unit, setUnit] = useState<LoopUnit>('m');
    const [workspace, setWorkspace] = useState(runtime.snapshot.settings.workspace);
    const [agentId, setAgentId] = useState(runtime.snapshot.settings.defaultAgentId);
    const pinnedTasks = useMemo(() => runtime.snapshot.tasks
        .filter((task) => task.pinnedAt && !task.archivedAt && task.engine !== 'headless')
        .sort((left, right) => (right.pinnedAt || 0) - (left.pinnedAt || 0)), [runtime.snapshot.tasks]);
    const [taskId, setTaskId] = useState(pinnedTasks[0]?.id || '');
    const [submitting, setSubmitting] = useState(false);
    const [error, setError] = useState('');
    const workspaces = useMemo(() => Array.from(new Set([
        runtime.snapshot.settings.workspace,
        ...runtime.snapshot.tasks.map((task) => task.workspace),
    ].filter(Boolean))), [runtime.snapshot.settings.workspace, runtime.snapshot.tasks]);

    const submit = async () => {
        const normalizedTitle = title.trim();
        const normalizedPrompt = prompt.trim();
        if (!normalizedTitle) {
            setError('请输入自动化标题');
            return;
        }
        if (!normalizedPrompt) {
            setError('请输入自动化要完成的任务');
            return;
        }
        setSubmitting(true);
        setError('');
        try {
            if (runTarget === 'existing-task') {
                if (!Number.isInteger(interval) || interval < 1) throw new Error('执行间隔必须是大于 0 的整数');
                const task = pinnedTasks.find((item) => item.id === taskId);
                if (!task) throw new Error('请选择一个已固定的实时会话任务');
                await runtime.sendFollowUp(task.id, `/loop ${interval}${unit} ${normalizedTitle}\n\n${normalizedPrompt}`);
                runtime.setActiveTaskId(task.id);
            } else {
                if (!workspace) throw new Error('请选择工作区');
                const automation: ArkDesktopAutomation = {
                    id: createAutomationId(),
                    name: normalizedTitle,
                    description: '',
                    prompt: normalizedPrompt,
                    workspace,
                    agentId,
                    skillIds: [],
                    schedule,
                    scheduleTime,
                    scheduleWeekday,
                    enabled: true,
                    nextRunAt: nextAutomationRunAt(schedule, scheduleTime, scheduleWeekday),
                };
                runtime.setSnapshot((current) => ({
                    ...current,
                    automations: [...current.automations, automation],
                }));
            }
            onClose();
        } catch (cause) {
            setError(cause instanceof Error ? cause.message : String(cause));
        } finally {
            setSubmitting(false);
        }
    };

    return (
        <div className="fixed inset-0 z-[1200] flex items-center justify-center bg-slate-950/35 p-5 backdrop-blur-sm">
            <div className="max-h-[92vh] w-full max-w-4xl overflow-y-auto rounded-[28px] border border-slate-200 bg-white shadow-2xl">
                <div className="sticky top-0 z-20 flex items-start justify-between border-b border-slate-100 bg-white/95 px-7 py-5 backdrop-blur">
                    <div>
                        <div className="text-xs font-medium uppercase tracking-[0.16em] text-slate-400">New</div>
                        <div className="mt-1 text-xl font-semibold text-slate-950">新建自动化</div>
                    </div>
                    <button type="button" onClick={onClose} className="rounded-xl p-2 text-slate-400 transition hover:bg-slate-100 hover:text-slate-700" aria-label="关闭"><X size={18} /></button>
                </div>
                <div className="space-y-7 p-7">
                    <div>
                        <input
                            value={title}
                            onChange={(event) => setTitle(event.target.value)}
                            placeholder="自动化标题"
                            autoFocus
                            className="w-full border-0 bg-transparent px-0 text-2xl font-semibold tracking-[-0.02em] text-slate-950 outline-none placeholder:text-slate-300"
                        />
                    </div>
                    <textarea
                        rows={4}
                        value={prompt}
                        onChange={(event) => setPrompt(event.target.value)}
                        placeholder="描述智能任务应该做什么"
                        className="w-full resize-none rounded-2xl border border-slate-200 bg-white px-5 py-4 text-sm leading-6 text-slate-800 outline-none transition placeholder:text-slate-400 focus:border-slate-400 focus:ring-4 focus:ring-slate-100"
                    />

                    <section>
                        <div className="mb-3 text-sm font-semibold text-slate-500">详情</div>
                        <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white">
                            <label className="flex min-h-16 items-center gap-4 border-b border-slate-100 px-5">
                                <span className="w-28 shrink-0 text-sm font-medium text-slate-800">运行于</span>
                                <span className="ml-auto flex items-center gap-2">
                                    <select value={runTarget} onChange={(event) => setRunTarget(event.target.value as AutomationRunTarget)} className="appearance-none bg-transparent pr-7 text-right text-sm font-medium text-slate-800 outline-none">
                                        <option value="new-task">新任务</option>
                                        <option value="existing-task">现有任务</option>
                                    </select>
                                    <ChevronDown size={15} className="-ml-6 pointer-events-none text-slate-400" />
                                </span>
                            </label>
                            {runTarget === 'existing-task' ? (
                                <label className="flex min-h-16 items-center gap-4 px-5">
                                    <span className="w-28 shrink-0 text-sm font-medium text-slate-800">任务</span>
                                    <span className="ml-auto flex min-w-0 items-center gap-2">
                                        <select value={taskId} onChange={(event) => setTaskId(event.target.value)} className="max-w-[520px] appearance-none truncate bg-transparent pr-7 text-right text-sm font-medium text-slate-800 outline-none">
                                            {!pinnedTasks.length && <option value="">没有可用的已固定任务</option>}
                                            {pinnedTasks.map((task) => <option key={task.id} value={task.id}>{task.title}</option>)}
                                        </select>
                                        <ChevronDown size={15} className="-ml-6 pointer-events-none shrink-0 text-slate-400" />
                                    </span>
                                </label>
                            ) : (
                                <>
                                    <label className="flex min-h-16 items-center gap-4 border-b border-slate-100 px-5">
                                        <span className="w-28 shrink-0 text-sm font-medium text-slate-800">工作区</span>
                                        <span className="ml-auto flex min-w-0 items-center gap-2">
                                            <Folder size={16} className="shrink-0 text-slate-400" />
                                            <select value={workspace} onChange={(event) => setWorkspace(event.target.value)} className="max-w-[520px] appearance-none truncate bg-transparent pr-7 text-right text-sm font-medium text-slate-800 outline-none">
                                                {!workspaces.length && <option value="">尚未选择工作区</option>}
                                                {workspaces.map((item) => <option key={item} value={item}>{item}</option>)}
                                            </select>
                                            <ChevronDown size={15} className="-ml-6 pointer-events-none shrink-0 text-slate-400" />
                                        </span>
                                    </label>
                                    <label className="flex min-h-16 items-center gap-4 px-5">
                                        <span className="w-28 shrink-0 text-sm font-medium text-slate-800">智能体</span>
                                        <span className="ml-auto flex items-center gap-2">
                                            <select value={agentId} onChange={(event) => setAgentId(event.target.value)} className="appearance-none bg-transparent pr-7 text-right text-sm font-medium text-slate-800 outline-none">
                                                {runtime.snapshot.agents.filter((agent) => agent.enabled).map((agent) => <option key={agent.id} value={agent.id}>{agent.name}</option>)}
                                            </select>
                                            <ChevronDown size={15} className="-ml-6 pointer-events-none text-slate-400" />
                                        </span>
                                    </label>
                                </>
                            )}
                        </div>
                        {runTarget === 'existing-task' && !pinnedTasks.length && (
                            <p className="mt-2 text-xs leading-5 text-amber-600">请先在左侧任务列表中固定一个实时会话，再回来选择。</p>
                        )}
                    </section>

                    <section>
                        <div className="mb-3 text-sm font-semibold text-slate-500">频率</div>
                        <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white">
                            {runTarget === 'new-task' ? (
                                <>
                                    <label className="flex min-h-16 items-center gap-4 border-b border-slate-100 px-5">
                                        <span className="w-28 shrink-0 text-sm font-medium text-slate-800">重复</span>
                                        <span className="ml-auto flex items-center gap-2">
                                            <select value={schedule} onChange={(event) => setSchedule(event.target.value as ArkDesktopAutomation['schedule'])} className="appearance-none bg-transparent pr-7 text-right text-sm font-medium text-slate-800 outline-none">
                                                <option value="daily">每天</option>
                                                <option value="weekly">每周</option>
                                            </select>
                                            <ChevronDown size={15} className="-ml-6 pointer-events-none text-slate-400" />
                                        </span>
                                    </label>
                                    {schedule === 'weekly' && (
                                        <label className="flex min-h-16 items-center gap-4 border-b border-slate-100 px-5">
                                            <span className="w-28 shrink-0 text-sm font-medium text-slate-800">星期</span>
                                            <span className="ml-auto flex items-center gap-2">
                                                <select value={scheduleWeekday} onChange={(event) => setScheduleWeekday(Number(event.target.value))} className="appearance-none bg-transparent pr-7 text-right text-sm font-medium text-slate-800 outline-none">
                                                    {['周日', '周一', '周二', '周三', '周四', '周五', '周六'].map((label, index) => <option key={label} value={index}>{label}</option>)}
                                                </select>
                                                <ChevronDown size={15} className="-ml-6 pointer-events-none text-slate-400" />
                                            </span>
                                        </label>
                                    )}
                                    <label className="flex min-h-16 items-center gap-4 border-b border-slate-100 px-5">
                                        <span className="w-28 shrink-0 text-sm font-medium text-slate-800">时间</span>
                                        <input type="time" value={scheduleTime} onChange={(event) => setScheduleTime(event.target.value)} className="ml-auto bg-transparent text-right text-sm font-medium text-slate-800 outline-none" />
                                    </label>
                                </>
                            ) : (
                                <label className="flex min-h-16 items-center gap-4 border-b border-slate-100 px-5">
                                    <span className="w-28 shrink-0 text-sm font-medium text-slate-800">重复</span>
                                    <span className="ml-auto flex items-center overflow-hidden rounded-xl border border-slate-200 bg-slate-50">
                                        <span className="pl-3 text-sm text-slate-500">每隔</span>
                                        <input type="number" min={1} step={1} value={interval} onChange={(event) => setInterval(Number(event.target.value))} className="w-16 bg-transparent px-2 py-2 text-center text-sm font-medium text-slate-800 outline-none" />
                                        <select value={unit} onChange={(event) => setUnit(event.target.value as LoopUnit)} className="border-l border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-800 outline-none">
                                            <option value="m">分钟</option>
                                            <option value="h">小时</option>
                                            <option value="d">天</option>
                                        </select>
                                    </span>
                                </label>
                            )}
                            <div className="flex min-h-16 items-center gap-4 px-5">
                                <span className="w-28 shrink-0 text-sm font-medium text-slate-800">通知</span>
                                <span className="ml-auto text-sm font-medium text-slate-800">需要处理时在任务中心提醒</span>
                            </div>
                        </div>
                    </section>

                    <div className="rounded-2xl bg-slate-50 px-5 py-4 text-xs leading-5 text-slate-500">
                        {runTarget === 'existing-task'
                            ? '现有任务使用 Grok 原生循环：创建后立即运行，保留该任务上下文，最长运行 7 天。'
                            : '新任务按本机时区执行，每次创建独立任务；URGS Desktop 需要保持运行。'}
                    </div>
                    {error && <div className="flex items-start gap-2 rounded-xl border border-red-100 bg-red-50 px-4 py-3 text-sm text-red-700"><AlertCircle size={16} className="mt-0.5 shrink-0" />{error}</div>}
                    <div className="flex justify-end gap-2 border-t border-slate-100 pt-5">
                        <button type="button" onClick={onClose} className="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-medium text-slate-600">取消</button>
                        <button type="button" disabled={submitting || (runTarget === 'existing-task' && !pinnedTasks.length)} onClick={() => void submit()} className="inline-flex items-center gap-2 rounded-xl bg-slate-950 px-5 py-2.5 text-sm font-medium text-white disabled:cursor-not-allowed disabled:opacity-40">
                            {submitting ? <LoaderCircle size={16} className="animate-spin" /> : <Repeat2 size={16} />}
                            {runTarget === 'existing-task' ? '创建并立即运行' : '创建自动化'}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
};

const AutomationCenter: React.FC<AutomationCenterProps> = ({ runtime, onEdit }) => {
    const [filter, setFilter] = useState<AutomationFilter>('all');
    const [query, setQuery] = useState('');
    const [creatorOpen, setCreatorOpen] = useState(false);
    const [pendingId, setPendingId] = useState('');
    const normalizedQuery = query.trim().toLowerCase();
    const latestRunByAutomation = useMemo(() => {
        const result = new Map<string, ArkDesktopTask>();
        runtime.snapshot.tasks.forEach((task) => {
            if (!task.automationId || result.has(task.automationId)) return;
            result.set(task.automationId, task);
        });
        return result;
    }, [runtime.snapshot.tasks]);
    const nativeLoops = useMemo<NativeLoop[]>(() => runtime.snapshot.tasks.flatMap((ownerTask) => (
        ownerTask.scheduledTasks || []
    ).map((scheduledTask) => ({ ownerTask, scheduledTask }))), [runtime.snapshot.tasks]);

    const matchesSearch = (...values: Array<string | undefined>) => !normalizedQuery || values.join(' ').toLowerCase().includes(normalizedQuery);
    const standaloneVisible = runtime.snapshot.automations.filter((automation) => {
        const latestRun = latestRunByAutomation.get(automation.id);
        if (!matchesSearch(automation.name, automation.description, automation.prompt)) return false;
        if (filter === 'active') return automation.schedule !== 'manual' && automation.enabled;
        if (filter === 'paused') return automation.schedule !== 'manual' && !automation.enabled;
        if (filter === 'attention') return latestRun?.status === 'failed' || latestRun?.status === 'waiting_authorization';
        return true;
    });
    const loopsVisible = nativeLoops.filter(({ scheduledTask, ownerTask }) => {
        if (!matchesSearch(scheduledTask.prompt, scheduledTask.humanSchedule, ownerTask.title, ownerTask.workspace)) return false;
        if (filter === 'active') return Boolean(ownerTask.runtimeProcessId);
        if (filter === 'paused') return !ownerTask.runtimeProcessId;
        if (filter === 'attention') return !ownerTask.runtimeProcessId || ownerTask.status === 'failed' || ownerTask.status === 'waiting_authorization';
        return true;
    });

    const runningCount = runtime.snapshot.automations.filter((automation) => automation.schedule !== 'manual' && automation.enabled).length
        + nativeLoops.filter(({ ownerTask }) => ownerTask.runtimeProcessId).length;
    const attentionCount = runtime.snapshot.automations.filter((automation) => {
        const status = latestRunByAutomation.get(automation.id)?.status;
        return status === 'failed' || status === 'waiting_authorization';
    }).length + nativeLoops.filter(({ ownerTask }) => !ownerTask.runtimeProcessId).length;
    const nextStandaloneRun = runtime.snapshot.automations
        .filter((automation) => automation.enabled && automation.nextRunAt)
        .sort((left, right) => (left.nextRunAt || 0) - (right.nextRunAt || 0))[0]?.nextRunAt;
    const nextNativeRun = nativeLoops
        .map(({ scheduledTask }) => scheduledTask.nextFireAt)
        .filter((value): value is string => Boolean(value))
        .sort((left, right) => Date.parse(left) - Date.parse(right))[0];
    const nextRun = [nextStandaloneRun, nextNativeRun ? Date.parse(nextNativeRun) : undefined]
        .filter((value): value is number => typeof value === 'number' && Number.isFinite(value))
        .sort((left, right) => left - right)[0];

    const runAutomation = async (automation: ArkDesktopAutomation) => {
        setPendingId(automation.id);
        try {
            runtime.setActiveTaskId(await runtime.startTask({
                prompt: automation.prompt,
                workspace: automation.workspace,
                agentId: automation.agentId,
                skillIds: automation.skillIds,
                automationId: automation.id,
            }));
        } catch (error) {
            runtime.setRuntimeError(error instanceof Error ? error.message : String(error));
        } finally {
            setPendingId('');
        }
    };

    const toggleAutomation = (automation: ArkDesktopAutomation) => {
        runtime.setSnapshot((current) => ({
            ...current,
            automations: current.automations.map((item) => item.id === automation.id ? {
                ...item,
                enabled: !item.enabled,
                nextRunAt: !item.enabled ? nextAutomationRunAt(item.schedule, item.scheduleTime, item.scheduleWeekday) : undefined,
            } : item),
        }));
    };

    const stopLoop = async (loop: NativeLoop) => {
        if (!window.confirm(`停止会话循环“${loop.scheduledTask.prompt.slice(0, 36)}”？`)) return;
        setPendingId(loop.scheduledTask.id);
        try {
            await runtime.deleteScheduledTask(loop.ownerTask.id, loop.scheduledTask.id);
        } catch (error) {
            runtime.setRuntimeError(error instanceof Error ? error.message : String(error));
        } finally {
            setPendingId('');
        }
    };

    return (
        <div className="mx-auto w-full max-w-[1180px] px-6 py-7 md:px-8">
            <div className="flex flex-col gap-5 lg:flex-row lg:items-start lg:justify-between">
                <div>
                    <div className="flex items-center gap-2 text-sm font-medium text-slate-500"><CalendarClock size={17} />自动化中心</div>
                    <h1 className="mt-2 text-3xl font-semibold tracking-[-0.035em] text-slate-950">让任务按计划持续推进</h1>
                    <p className="mt-2 max-w-2xl text-sm leading-6 text-slate-500">独立计划适合日报、巡检和固定时点任务；Grok 会话循环适合轮询长任务并保留上下文。</p>
                </div>
                <button type="button" onClick={() => setCreatorOpen(true)} className="inline-flex items-center gap-2 rounded-xl bg-slate-950 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition hover:bg-slate-800"><Plus size={16} />新建自动化</button>
            </div>

            <div className="mt-7 grid gap-3 md:grid-cols-3">
                <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-[0_1px_2px_rgba(15,23,42,0.03)]">
                    <div className="flex items-center justify-between text-sm text-slate-500"><span>正在生效</span><Play size={16} className="text-emerald-600" /></div>
                    <div className="mt-3 text-2xl font-semibold text-slate-950">{runningCount}</div>
                    <div className="mt-1 text-xs text-slate-400">独立计划与在线会话循环</div>
                </div>
                <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-[0_1px_2px_rgba(15,23,42,0.03)]">
                    <div className="flex items-center justify-between text-sm text-slate-500"><span>下次执行</span><Clock3 size={16} className="text-blue-600" /></div>
                    <div className="mt-3 text-lg font-semibold text-slate-950">{nextRun ? formatAutomationDateTime(nextRun) : '暂无计划'}</div>
                    <div className="mt-1 text-xs text-slate-400">按本机当前时区显示</div>
                </div>
                <div className={`rounded-2xl border p-4 shadow-[0_1px_2px_rgba(15,23,42,0.03)] ${attentionCount ? 'border-amber-200 bg-amber-50/50' : 'border-slate-200 bg-white'}`}>
                    <div className="flex items-center justify-between text-sm text-slate-500"><span>需要处理</span><AlertCircle size={16} className={attentionCount ? 'text-amber-600' : 'text-slate-400'} /></div>
                    <div className="mt-3 text-2xl font-semibold text-slate-950">{attentionCount}</div>
                    <div className="mt-1 text-xs text-slate-400">失败、待授权或离线循环</div>
                </div>
            </div>

            <div className="mt-7 flex flex-col gap-3 border-b border-slate-200 pb-4 sm:flex-row sm:items-center sm:justify-between">
                <div className="flex flex-wrap gap-1 rounded-xl bg-slate-100 p-1">
                    {([
                        ['all', '全部'],
                        ['active', '运行中'],
                        ['paused', '已暂停'],
                        ['attention', '需处理'],
                    ] as Array<[AutomationFilter, string]>).map(([value, label]) => (
                        <button key={value} type="button" onClick={() => setFilter(value)} className={`rounded-lg px-3 py-1.5 text-xs font-medium transition ${filter === value ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-500 hover:text-slate-700'}`}>{label}</button>
                    ))}
                </div>
                <label className="flex h-9 min-w-[240px] items-center gap-2 rounded-xl border border-slate-200 bg-white px-3 text-slate-400 focus-within:border-slate-300 focus-within:ring-2 focus-within:ring-slate-100">
                    <Search size={15} />
                    <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="搜索自动化" className="min-w-0 flex-1 bg-transparent text-sm text-slate-700 outline-none placeholder:text-slate-400" />
                </label>
            </div>

            <div className="mt-5 space-y-3">
                {standaloneVisible.map((automation) => {
                    const latestRun = latestRunByAutomation.get(automation.id);
                    const status = latestRun ? statusCopy[latestRun.status] : undefined;
                    const StatusIcon = status?.icon;
                    return (
                        <article key={automation.id} className="rounded-2xl border border-slate-200 bg-white p-5 transition hover:border-slate-300 hover:shadow-[0_8px_30px_rgba(15,23,42,0.05)]">
                            <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                                <div className="min-w-0 flex-1">
                                    <div className="flex flex-wrap items-center gap-2">
                                        <h2 className="font-semibold text-slate-950">{automation.name}</h2>
                                        <span className="rounded-full bg-violet-50 px-2 py-1 text-[11px] font-medium text-violet-700">独立计划</span>
                                        {status && <span className={`inline-flex items-center gap-1 rounded-full px-2 py-1 text-[11px] font-medium ${status.className}`}>{StatusIcon && <StatusIcon size={11} className={latestRun?.status === 'running' ? 'animate-spin' : ''} />}{status.label}</span>}
                                        {!automation.enabled && <span className="rounded-full bg-slate-100 px-2 py-1 text-[11px] font-medium text-slate-500">已暂停</span>}
                                    </div>
                                    {automation.description && <p className="mt-1.5 text-sm text-slate-500">{automation.description}</p>}
                                    <p className="mt-3 line-clamp-2 max-w-3xl text-sm leading-6 text-slate-700">{automation.prompt}</p>
                                    <div className="mt-4 flex flex-wrap items-center gap-x-5 gap-y-2 text-xs text-slate-500">
                                        <span className="inline-flex items-center gap-1.5"><CalendarClock size={14} />{automationScheduleLabel(automation)}</span>
                                        <span className="inline-flex items-center gap-1.5"><Clock3 size={14} />下次 {automation.enabled && automation.nextRunAt ? formatAutomationDateTime(automation.nextRunAt) : '未安排'}</span>
                                        <span className="inline-flex items-center gap-1.5"><History size={14} />最近 {latestRun ? formatAutomationDateTime(latestRun.createdAt) : '尚未运行'}</span>
                                    </div>
                                    {latestRun?.error && <button type="button" onClick={() => runtime.setActiveTaskId(latestRun.id)} className="mt-3 inline-flex items-center gap-1.5 rounded-lg bg-red-50 px-2.5 py-1.5 text-xs text-red-700"><AlertCircle size={13} />{latestRun.error.slice(0, 90)}</button>}
                                </div>
                                <div className="flex shrink-0 items-center gap-2">
                                    {automation.schedule !== 'manual' && <AutomationToggle checked={automation.enabled} label={`${automation.enabled ? '暂停' : '启用'} ${automation.name}`} onChange={() => toggleAutomation(automation)} />}
                                    <button type="button" onClick={() => onEdit(automation.id)} className="rounded-xl border border-slate-200 p-2.5 text-slate-500 transition hover:bg-slate-50 hover:text-slate-800" aria-label={`编辑 ${automation.name}`}><Pencil size={16} /></button>
                                    <button type="button" disabled={pendingId === automation.id} onClick={() => void runAutomation(automation)} className="inline-flex items-center gap-1.5 rounded-xl bg-slate-950 px-3.5 py-2.5 text-xs font-medium text-white disabled:opacity-50">
                                        {pendingId === automation.id ? <LoaderCircle size={14} className="animate-spin" /> : <Play size={14} />}立即运行
                                    </button>
                                </div>
                            </div>
                        </article>
                    );
                })}

                {loopsVisible.map((loop) => {
                    const connected = Boolean(loop.ownerTask.runtimeProcessId);
                    return (
                        <article key={`${loop.ownerTask.id}-${loop.scheduledTask.id}`} className="rounded-2xl border border-blue-100 bg-gradient-to-br from-blue-50/60 to-white p-5 transition hover:border-blue-200 hover:shadow-[0_8px_30px_rgba(37,99,235,0.06)]">
                            <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                                <div className="min-w-0 flex-1">
                                    <div className="flex flex-wrap items-center gap-2">
                                        <h2 className="font-semibold text-slate-950">{loop.scheduledTask.prompt.slice(0, 56) || 'Grok 会话循环'}</h2>
                                        <span className="rounded-full bg-blue-100 px-2 py-1 text-[11px] font-medium text-blue-700">Grok 原生循环</span>
                                        <span className={`rounded-full px-2 py-1 text-[11px] font-medium ${connected ? 'bg-emerald-50 text-emerald-700' : 'bg-amber-50 text-amber-700'}`}>{connected ? '在线' : '会话未连接'}</span>
                                    </div>
                                    <button type="button" onClick={() => runtime.setActiveTaskId(loop.ownerTask.id)} className="mt-2 inline-flex items-center gap-1.5 text-sm text-slate-500 transition hover:text-slate-800"><MessageCircle size={14} />{loop.ownerTask.title}</button>
                                    <div className="mt-4 flex flex-wrap items-center gap-x-5 gap-y-2 text-xs text-slate-500">
                                        <span className="inline-flex items-center gap-1.5"><Repeat2 size={14} />{loop.scheduledTask.humanSchedule}</span>
                                        <span className="inline-flex items-center gap-1.5"><Clock3 size={14} />下次 {formatAutomationDateTime(loop.scheduledTask.nextFireAt)}</span>
                                        <span className="inline-flex items-center gap-1.5"><History size={14} />已触发 {loop.scheduledTask.firedCount} 次</span>
                                    </div>
                                    {!connected && <p className="mt-3 text-xs leading-5 text-amber-700">原生循环依赖关联会话进程；应用或会话关闭后不会继续执行。</p>}
                                </div>
                                <div className="flex shrink-0 items-center gap-2">
                                    <button type="button" onClick={() => runtime.setActiveTaskId(loop.ownerTask.id)} className="inline-flex items-center gap-1.5 rounded-xl border border-slate-200 bg-white px-3.5 py-2.5 text-xs font-medium text-slate-700"><MessageCircle size={14} />打开会话</button>
                                    <button type="button" disabled={!connected || pendingId === loop.scheduledTask.id} onClick={() => void stopLoop(loop)} className="inline-flex items-center gap-1.5 rounded-xl border border-red-100 bg-white px-3.5 py-2.5 text-xs font-medium text-red-600 disabled:cursor-not-allowed disabled:opacity-40">
                                        {pendingId === loop.scheduledTask.id ? <LoaderCircle size={14} className="animate-spin" /> : <Trash2 size={14} />}停止循环
                                    </button>
                                </div>
                            </div>
                        </article>
                    );
                })}

                {standaloneVisible.length === 0 && loopsVisible.length === 0 && (
                    <div className="rounded-3xl border border-dashed border-slate-300 bg-slate-50/60 px-6 py-14 text-center">
                        <CalendarClock size={30} className="mx-auto text-slate-300" />
                        <h2 className="mt-4 font-semibold text-slate-800">没有符合条件的自动化</h2>
                        <p className="mt-2 text-sm text-slate-500">在一个表单中选择新任务或现有任务，并设置对应的执行频率。</p>
                        <button type="button" onClick={() => setCreatorOpen(true)} className="mt-5 rounded-xl bg-slate-950 px-4 py-2 text-sm font-medium text-white">新建自动化</button>
                    </div>
                )}
            </div>

            <div className="mt-6 rounded-2xl border border-slate-200 bg-slate-50 px-5 py-4 text-xs leading-5 text-slate-500">
                <strong className="font-semibold text-slate-700">运行边界：</strong>
                独立计划仅在 URGS 桌面客户端运行时触发，每次创建独立会话；Grok 会话循环创建后立即执行，之后回到原会话，最多保留 7 天且同一会话最多 50 个。
            </div>
            {creatorOpen && <AutomationCreator runtime={runtime} onClose={() => setCreatorOpen(false)} />}
        </div>
    );
};

export default AutomationCenter;
