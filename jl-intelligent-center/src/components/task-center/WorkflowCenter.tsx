import React, { useMemo, useState } from 'react';
import {
    AlertCircle, CheckCircle2, Clock3, ExternalLink, LoaderCircle, Users, Workflow, XCircle,
} from 'lucide-react';
import type { ArkDesktopRuntime } from './useArkDesktopRuntime';
import type { ArkDesktopTask, ArkDesktopWorkflowRun } from './types';
import WorkflowRunControls, { type WorkflowCommandAction } from './WorkflowRunControls';
import WorkflowCatalogPanel from './WorkflowCatalogPanel';

interface WorkflowCenterProps {
    runtime: ArkDesktopRuntime;
    onOpenTask: (taskId: string) => void;
}

type WorkflowEntry = { task: ArkDesktopTask; run: ArkDesktopWorkflowRun };

const isTerminalWorkflow = (status: string) => /complete|completed|failed|interrupted|cancelled|stopped|cleared/i.test(status);

const statusPresentation = (status: string) => {
    switch (status.toLowerCase()) {
        case 'complete':
        case 'completed':
            return { label: '已完成', className: 'bg-emerald-50 text-emerald-700', Icon: CheckCircle2 };
        case 'failed':
            return { label: '失败', className: 'bg-red-50 text-red-700', Icon: XCircle };
        case 'interrupted':
        case 'cancelled':
        case 'stopped':
            return { label: '已停止', className: 'bg-slate-100 text-slate-600', Icon: XCircle };
        case 'paused':
        case 'user_paused':
            return { label: '已暂停', className: 'bg-amber-50 text-amber-700', Icon: Clock3 };
        default:
            return { label: '运行中', className: 'bg-blue-50 text-blue-700', Icon: LoaderCircle };
    }
};

const formatDuration = (elapsedMs: number) => {
    const seconds = Math.max(0, Math.floor(elapsedMs / 1000));
    if (seconds < 60) return `${seconds} 秒`;
    const minutes = Math.floor(seconds / 60);
    if (minutes < 60) return `${minutes} 分钟 ${seconds % 60} 秒`;
    return `${Math.floor(minutes / 60)} 小时 ${minutes % 60} 分钟`;
};

const shortWorkspace = (workspace: string) => workspace.split(/[\\/]/).filter(Boolean).pop() || workspace;

const WorkflowCenter: React.FC<WorkflowCenterProps> = ({ runtime, onOpenTask }) => {
    const [filter, setFilter] = useState<'active' | 'all'>('active');
    const entries = useMemo<WorkflowEntry[]>(() => runtime.snapshot.tasks
        .flatMap((task) => (task.workflowRuns || []).map((run) => ({ task, run })))
        .filter(({ run }) => run.status.toLowerCase() !== 'cleared')
        .sort((left, right) => {
            const leftActive = isTerminalWorkflow(left.run.status) ? 0 : 1;
            const rightActive = isTerminalWorkflow(right.run.status) ? 0 : 1;
            return rightActive - leftActive || right.run.updatedAt - left.run.updatedAt;
        }), [runtime.snapshot.tasks]);
    const activeCount = entries.filter(({ run }) => !isTerminalWorkflow(run.status)).length;
    const visibleEntries = filter === 'active'
        ? entries.filter(({ run }) => !isTerminalWorkflow(run.status))
        : entries;

    return <div className="mx-auto w-full max-w-6xl px-5 py-7 lg:px-10">
        <div className="flex flex-wrap items-start justify-between gap-4">
            <div>
                <div className="flex items-center gap-2 text-slate-900"><span className="flex h-9 w-9 items-center justify-center rounded-xl bg-[#eeeaff] text-[#6657d9]"><Workflow size={19} /></span><h1 className="text-xl font-semibold tracking-[-0.02em]">工作流运行中心</h1></div>
                <p className="mt-2 max-w-2xl text-sm leading-6 text-slate-500">集中查看不同会话中的 Grok Workflow。每个运行实例仍归属于自己的会话、工作区和权限上下文。</p>
            </div>
            <div className="flex items-center gap-1 rounded-lg bg-slate-100 p-1">
                {([['active', `运行中${activeCount ? ` ${activeCount}` : ''}`], ['all', '全部记录']] as const).map(([value, label]) => <button
                    key={value}
                    type="button"
                    onClick={() => setFilter(value)}
                    className={`rounded-md px-3 py-1.5 text-xs font-medium transition ${filter === value ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-500 hover:text-slate-700'}`}
                >{label}</button>)}
            </div>
        </div>

        <div className="mt-6 grid gap-3 sm:grid-cols-3">
            <div className="rounded-xl border border-slate-200 bg-white px-4 py-3"><div className="text-[11px] text-slate-400">当前运行</div><div className="mt-1 text-2xl font-semibold text-slate-800">{activeCount}</div></div>
            <div className="rounded-xl border border-slate-200 bg-white px-4 py-3"><div className="text-[11px] text-slate-400">会话数量</div><div className="mt-1 text-2xl font-semibold text-slate-800">{new Set(entries.map(({ task }) => task.id)).size}</div></div>
            <div className="rounded-xl border border-slate-200 bg-white px-4 py-3"><div className="text-[11px] text-slate-400">已记录运行</div><div className="mt-1 text-2xl font-semibold text-slate-800">{entries.length}</div></div>
        </div>

        <WorkflowCatalogPanel runtime={runtime} />

        {visibleEntries.length === 0 ? <div className="mt-8 rounded-2xl border border-dashed border-slate-200 bg-slate-50 px-6 py-14 text-center"><Workflow size={28} className="mx-auto text-slate-300" /><p className="mt-3 text-sm font-medium text-slate-500">{filter === 'active' ? '当前没有运行中的 Workflow' : '还没有 Workflow 运行记录'}</p><p className="mt-1 text-xs text-slate-400">在会话输入框中选择 /workflow，即可启动或管理运行。</p></div> : <div className="mt-6 grid gap-4 xl:grid-cols-2">
            {visibleEntries.map(({ task, run }) => {
                const presentation = statusPresentation(run.status);
                const StatusIcon = presentation.Icon;
                const phase = run.currentPhase || run.phases.find((item) => item.state === 'active')?.title;
                const canManage = Boolean(
                    task.availableCommands?.some((command) => command.name === 'workflow')
                    || (runtime.activeTaskId === task.id && runtime.availableCommands.some((command) => command.name === 'workflow')),
                );
                const command = (action: WorkflowCommandAction) => runtime.sendWorkflowCommand(task.id, action, run.name);
                return <article key={`${task.id}-${run.runId}`} className="rounded-2xl border border-slate-200 bg-white p-5 shadow-[0_6px_22px_rgba(15,23,42,0.04)]">
                    <div className="flex items-start gap-3">
                        <span className={`mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-lg ${presentation.className}`}><StatusIcon size={16} className={presentation.label === '运行中' ? 'animate-spin' : ''} /></span>
                        <div className="min-w-0 flex-1">
                            <div className="flex flex-wrap items-start gap-2">
                                <button type="button" onClick={() => onOpenTask(task.id)} className="min-w-0 truncate text-left text-sm font-semibold text-slate-800 hover:text-[#6657d9]" title="打开所属会话">{run.name}</button>
                                <span className={`rounded-full px-2 py-0.5 text-[10px] font-medium ${presentation.className}`}>{presentation.label}</span>
                            </div>
                            <div className="mt-1 flex flex-wrap items-center gap-x-2 gap-y-1 text-[11px] text-slate-400"><span className="truncate">会话：{task.title}</span><span>·</span><span>{shortWorkspace(task.workspace)}</span></div>
                        </div>
                        {canManage ? <WorkflowRunControls run={run} onCommand={command} onError={(error) => runtime.setRuntimeError(error instanceof Error ? error.message : String(error))} /> : <span className="text-[10px] text-slate-400">当前会话未声明控制能力</span>}
                    </div>
                    {run.objective && <p className="mt-4 line-clamp-3 text-sm leading-6 text-slate-600">{run.objective}</p>}
                    <div className="mt-4 rounded-xl bg-slate-50 px-3 py-3">
                        <div className="flex items-center justify-between gap-3 text-[11px] text-slate-500"><span>{phase ? `当前阶段：${phase}` : '当前阶段：准备中'}</span><span>{formatDuration(run.elapsedMs)}</span></div>
                        {run.phases.length > 0 && <div className="mt-2 flex gap-1.5">{run.phases.slice(0, 8).map((item, index) => <span key={`${item.title}-${index}`} className={`h-1.5 min-w-0 flex-1 rounded-full ${/complete|completed/i.test(item.state) ? 'bg-emerald-400' : item.title === phase ? 'bg-[#8a7cf0]' : 'bg-slate-200'}`} title={`${item.title}：${item.state}`} />)}</div>}
                        <div className="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-[11px] text-slate-500"><span className="inline-flex items-center gap-1"><Users size={12} />{run.activeAgents} 个活跃智能体</span>{run.agentBudget != null && <span>预算 {run.agentsUsed}/{run.agentBudget}</span>}{run.agentsRemaining != null && <span>剩余 {run.agentsRemaining}</span>}</div>
                    </div>
                    {run.agents.length > 0 && <div className="mt-4"><div className="mb-2 text-[11px] font-medium text-slate-500">智能体进度</div><div className="space-y-1.5">{run.agents.slice(0, 5).map((agent) => <div key={agent.agentId || agent.label} className="flex items-center gap-2 text-[11px]"><span className={`h-1.5 w-1.5 rounded-full ${/complete|done|success/i.test(agent.state) ? 'bg-emerald-400' : /fail|error|cancel/i.test(agent.state) ? 'bg-red-400' : 'bg-[#8a7cf0]'}`} /><span className="min-w-0 flex-1 truncate text-slate-600">{agent.label}</span><span className="shrink-0 text-slate-400">{agent.phase || agent.state}</span></div>)}</div></div>}
                    {run.pauseMessage && <div className="mt-4 flex items-start gap-2 rounded-lg bg-amber-50 px-3 py-2 text-[11px] leading-5 text-amber-700"><AlertCircle size={13} className="mt-0.5 shrink-0" />{run.pauseMessage}</div>}
                    {run.resultSummary && <div className="mt-4 rounded-lg border border-slate-100 px-3 py-2 text-[11px] leading-5 text-slate-500">{run.resultSummary}</div>}
                    <button type="button" onClick={() => onOpenTask(task.id)} className="mt-4 inline-flex items-center gap-1 text-[11px] font-medium text-[#6657d9] hover:text-[#5142c7]"><ExternalLink size={12} />打开所属会话查看完整时间线</button>
                </article>;
            })}
        </div>}
    </div>;
};

export default WorkflowCenter;
