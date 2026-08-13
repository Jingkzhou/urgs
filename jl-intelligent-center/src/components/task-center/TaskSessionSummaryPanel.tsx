import React, { useState } from 'react';
import { Activity, Bot, ListTree, RefreshCw, Server, Workflow, X } from 'lucide-react';
import type { ArkDesktopTask } from './types';
import type { ArkDesktopRuntime } from './useArkDesktopRuntime';
import WorkflowRunControls from './WorkflowRunControls';

interface TaskSessionSummaryPanelProps {
    task: ArkDesktopTask;
    runtime: ArkDesktopRuntime;
    visible: boolean;
    onClose: () => void;
}

const isBackgroundActive = (status: string) => !/完成|退出码|取消/i.test(status);
const isSubagentActive = (status: string) => !/完成|失败|取消|退出/i.test(status);
const isWorkflowActive = (status: string) => !/complete|completed|failed|interrupted|cancelled|stopped|cleared/i.test(status);

const workflowStatusPresentation = (status: string) => {
    switch (status.toLowerCase()) {
        case 'complete':
        case 'completed': return { label: '已完成', className: 'bg-emerald-50 text-emerald-700' };
        case 'failed': return { label: '失败', className: 'bg-red-50 text-red-700' };
        case 'interrupted':
        case 'cancelled': return { label: '已取消', className: 'bg-slate-100 text-slate-600' };
        case 'stopped': return { label: '已停止', className: 'bg-slate-100 text-slate-600' };
        case 'paused':
        case 'user_paused': return { label: '已暂停', className: 'bg-amber-50 text-amber-700' };
        case 'cleared': return { label: '已清理', className: 'bg-slate-100 text-slate-500' };
        default: return { label: '运行中', className: 'bg-blue-50 text-blue-700' };
    }
};

const taskStatusPresentation = (status: ArkDesktopTask['status']) => {
    switch (status) {
        case 'running': return { label: '运行中', className: 'bg-blue-50 text-blue-700' };
        case 'waiting_authorization': return { label: '等待授权', className: 'bg-amber-50 text-amber-700' };
        case 'completed': return { label: '已完成', className: 'bg-emerald-50 text-emerald-700' };
        case 'failed': return { label: '失败', className: 'bg-red-50 text-red-700' };
        case 'cancelled': return { label: '已取消', className: 'bg-slate-100 text-slate-600' };
    }
};

const TaskSessionSummaryPanel: React.FC<TaskSessionSummaryPanelProps> = ({ task, runtime, visible, onClose }) => {
    const [pending, setPending] = useState<string | null>(null);
    const backgroundCount = (task.backgroundTasks || []).filter((item) => isBackgroundActive(item.status)).length;
    const subagentCount = (task.subagents || []).filter((item) => isSubagentActive(item.status)).length;
    const workflowCount = (task.workflowRuns || []).filter((item) => isWorkflowActive(item.status)).length;
    const activeCount = backgroundCount + subagentCount + workflowCount;
    const status = taskStatusPresentation(task.status);
    const workflowCommandAvailable = Boolean(
        task.availableCommands?.some((command) => command.name === 'workflow')
        || (runtime.activeTaskId === task.id && runtime.availableCommands.some((command) => command.name === 'workflow')),
    );
    const hasSummary = Boolean(
        task.runtimeMode
        || task.recap
        || task.backgroundTasks?.length
        || task.subagents?.length
        || task.workflowRuns?.length
        || task.mcpServers?.length,
    );

    const run = async (action: string, callback: () => Promise<unknown>) => {
        if (pending) return;
        setPending(action);
        try {
            await callback();
        } catch (error) {
            runtime.setRuntimeError(error instanceof Error ? error.message : String(error));
        } finally {
            setPending(null);
        }
    };

    return <aside
        id="task-session-summary-panel"
        className={`${visible ? 'flex' : 'hidden'} h-full w-[336px] min-w-[300px] max-w-[38vw] shrink-0 flex-col border-l border-slate-200 bg-[#fbfbfc] shadow-[-12px_0_30px_rgba(15,23,42,0.04)]`}
        aria-label="置顶摘要"
        aria-hidden={visible ? undefined : true}
    >
        <div className="shrink-0 border-b border-slate-200 bg-white px-4 py-3">
            <div className="flex items-start gap-3">
                <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-indigo-50 text-indigo-600"><ListTree size={18} /></span>
                <div className="min-w-0 flex-1">
                    <div className="flex min-w-0 items-center gap-2">
                        <h2 className="truncate text-sm font-semibold text-slate-900">置顶摘要</h2>
                        <span className={`shrink-0 rounded-full px-1.5 py-0.5 text-[10px] font-medium ${status.className}`}>{status.label}</span>
                    </div>
                    <p className="mt-1 truncate text-[11px] text-slate-400" title={task.title}>{task.title}</p>
                </div>
                <button type="button" onClick={onClose} className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg text-slate-400 transition hover:bg-slate-100 hover:text-slate-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-300" title="关闭置顶摘要" aria-label="关闭置顶摘要"><X size={16} /></button>
            </div>
            <div className="mt-3 flex items-center justify-between gap-3 text-[11px] text-slate-500">
                <span className="flex items-center gap-1.5"><Activity size={13} className={activeCount > 0 ? 'text-indigo-500' : 'text-slate-400'} />{activeCount > 0 ? `${activeCount} 项正在运行` : '当前没有运行项'}</span>
                {task.runtimeMode && <code className="max-w-32 truncate rounded bg-slate-100 px-1.5 py-0.5 text-[10px] text-slate-500" title={task.runtimeMode}>{task.runtimeMode}</code>}
            </div>
        </div>

        <div className="custom-scrollbar min-h-0 flex-1 overflow-y-auto">
            {!hasSummary && <div className="px-5 py-12 text-center"><ListTree size={22} className="mx-auto text-slate-300" /><p className="mt-2 text-xs font-medium text-slate-500">当前会话暂无摘要</p><p className="mt-1 text-[11px] leading-5 text-slate-400">工作流、后台任务和会话能力出现后会集中显示在这里。</p></div>}

            {task.recap && <section className="border-b border-slate-200 px-4 py-4">
                <details open>
                    <summary className="cursor-pointer list-none text-xs font-semibold text-slate-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-300">最近会话摘要</summary>
                    <p className="mt-2 whitespace-pre-wrap break-words text-[11px] leading-5 text-slate-500">{task.recap}</p>
                </details>
            </section>}

            {(task.workflowRuns?.length || task.backgroundTasks?.length || task.subagents?.length) ? <section className="border-b border-slate-200 px-4 py-4">
                <div className="mb-3 flex items-center justify-between gap-2">
                    <h2 className="text-xs font-semibold text-slate-800">当前运行</h2>
                    {activeCount > 0 && <span aria-live="polite" className="rounded-full bg-indigo-50 px-2 py-0.5 text-[10px] font-medium text-indigo-600">{activeCount} 运行中</span>}
                </div>

                {task.workflowRuns?.length ? <details open className="group border-t border-slate-100 py-2 first:border-t-0 first:pt-0">
                    <summary className="flex cursor-pointer list-none items-center gap-2 py-1 text-[11px] font-medium text-slate-600 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-300"><Workflow size={13} className="text-indigo-500" /><span>工作流运行</span><span className="ml-auto text-[10px] text-slate-400">{task.workflowRuns.length}</span></summary>
                    <div className="mt-2 space-y-2">
                        {task.workflowRuns.map((item) => {
                            const presentation = workflowStatusPresentation(item.status);
                            const phase = item.currentPhase || item.phases.find((value) => value.state === 'active')?.title;
                            return <div key={`workflow-${item.runId}`} className="rounded-xl bg-white px-3 py-2.5 ring-1 ring-slate-200/80">
                                <div className="flex items-center gap-2"><span className="min-w-0 flex-1 truncate text-[11px] font-medium text-slate-700" title={item.name}>{item.name}</span><span className={`shrink-0 rounded-full px-1.5 py-0.5 text-[10px] ${presentation.className}`}>{presentation.label}</span></div>
                                {item.objective && <p className="mt-1.5 break-words text-[10px] leading-4 text-slate-500">{item.objective}</p>}
                                <div className="mt-1.5 flex flex-wrap gap-x-3 gap-y-1 text-[10px] text-slate-400"><span>{phase ? `阶段：${phase}` : '阶段：准备中'}</span><span>{item.activeAgents} 个活跃智能体</span>{item.agentBudget != null && <span>预算 {item.agentsUsed}/{item.agentBudget}</span>}</div>
                                {item.pauseMessage && <p className="mt-1.5 text-[10px] leading-4 text-amber-700">{item.pauseMessage}</p>}
                                {item.resultSummary && <details className="mt-1.5"><summary className="cursor-pointer text-[10px] font-medium text-slate-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-300">查看运行结果</summary><p className="mt-1 whitespace-pre-wrap break-words text-[10px] leading-4 text-slate-400">{item.resultSummary}</p></details>}
                                {workflowCommandAvailable && <div className="mt-2 border-t border-slate-100 pt-2"><WorkflowRunControls compact run={item} onCommand={(action) => runtime.sendWorkflowCommand(task.id, action, item.name)} onError={(error) => runtime.setRuntimeError(error instanceof Error ? error.message : String(error))} /></div>}
                            </div>;
                        })}
                    </div>
                </details> : null}

                {(task.backgroundTasks?.length || task.subagents?.length) ? <details open={backgroundCount + subagentCount > 0} className="group border-t border-slate-100 py-2 last:pb-0">
                    <summary className="flex cursor-pointer list-none items-center gap-2 py-1 text-[11px] font-medium text-slate-600 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-300"><Bot size={13} className="text-slate-500" /><span>后台任务与子智能体</span><span className="ml-auto text-[10px] text-slate-400">{(task.backgroundTasks?.length || 0) + (task.subagents?.length || 0)}</span></summary>
                    <div className="mt-2 flex items-center justify-between gap-2"><span className="text-[10px] text-slate-400">活动归属于当前会话</span><button type="button" disabled={!task.sessionId || pending !== null} onClick={() => void run('background', () => runtime.refreshTaskBackgroundTasks(task.id))} className="flex h-8 items-center gap-1 rounded-lg px-2 text-[10px] font-medium text-slate-500 hover:bg-white disabled:opacity-40"><RefreshCw size={11} className={pending === 'background' ? 'animate-spin' : ''} />刷新</button></div>
                    <div className="space-y-2">
                        {(task.backgroundTasks || []).map((item) => <div key={`background-${item.taskId}`} className="rounded-xl bg-white px-3 py-2.5 ring-1 ring-slate-200/80"><div className="flex items-center gap-2"><span className="min-w-0 flex-1 truncate text-[11px] font-medium text-slate-700" title={item.title}>{item.title}</span><span className="shrink-0 text-[10px] text-slate-400">{item.status}</span></div>{item.output && <details className="mt-1.5"><summary className="cursor-pointer text-[10px] font-medium text-slate-500">查看输出</summary><p className="mt-1 whitespace-pre-wrap break-words text-[10px] leading-4 text-slate-400">{item.output}</p></details>}{isBackgroundActive(item.status) && <div className="mt-2 flex justify-end gap-1.5"><button type="button" onClick={() => void run(`wait:${item.taskId}`, () => runtime.waitTaskBackgroundTask(task.id, item.taskId))} className="h-8 rounded-lg px-2 text-[10px] text-slate-600 hover:bg-slate-50">等待</button><button type="button" onClick={() => void run(`kill:${item.taskId}`, () => runtime.killTaskBackgroundTask(task.id, item.taskId))} className="h-8 rounded-lg px-2 text-[10px] text-red-600 hover:bg-red-50">停止</button></div>}</div>)}
                        {(task.subagents || []).map((item) => <div key={`subagent-${item.subagentId}`} className="rounded-xl bg-white px-3 py-2.5 ring-1 ring-slate-200/80"><div className="flex items-center gap-2"><span className="min-w-0 flex-1 truncate text-[11px] font-medium text-slate-700" title={item.title}>{item.title}</span><span className="shrink-0 text-[10px] text-slate-400">{item.status}</span></div>{item.output && <details className="mt-1.5"><summary className="cursor-pointer text-[10px] font-medium text-slate-500">查看输出</summary><p className="mt-1 whitespace-pre-wrap break-words text-[10px] leading-4 text-slate-400">{item.output}</p></details>}{isSubagentActive(item.status) && <div className="mt-2 flex justify-end gap-1.5"><button type="button" onClick={() => void run(`wait-subagent:${item.subagentId}`, () => runtime.waitTaskSubagent(task.id, item.subagentId))} className="h-8 rounded-lg px-2 text-[10px] text-slate-600 hover:bg-slate-50">等待</button><button type="button" onClick={() => void run(`subagent:${item.subagentId}`, () => runtime.cancelTaskSubagent(task.id, item.subagentId))} className="h-8 rounded-lg px-2 text-[10px] text-red-600 hover:bg-red-50">取消</button></div>}</div>)}
                    </div>
                </details> : null}
            </section> : null}

            {(task.runtimeMode || task.mcpServers?.length) ? <section className="px-4 py-4">
                <h2 className="mb-3 text-xs font-semibold text-slate-800">会话能力</h2>
                {task.runtimeMode && <div className="flex items-center justify-between gap-3 border-t border-slate-100 py-2 text-[11px]"><span className="text-slate-500">运行模式</span><code className="max-w-40 truncate rounded bg-slate-100 px-1.5 py-0.5 text-[10px] text-slate-600" title={task.runtimeMode}>{task.runtimeMode}</code></div>}
                {task.mcpServers?.length ? <details className="border-t border-slate-100 py-2"><summary className="flex cursor-pointer list-none items-center gap-2 py-1 text-[11px] font-medium text-slate-600 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-300"><Server size={13} /><span>当前会话 MCP</span><span className="ml-auto text-[10px] text-slate-400">{task.mcpServers.length}</span></summary><div className="mt-2 space-y-2">{task.mcpServers.map((server) => <div key={server.name} className="rounded-xl bg-white px-3 py-2.5 ring-1 ring-slate-200/80"><div className="flex items-center gap-2"><span className="min-w-0 flex-1 truncate text-[11px] font-medium text-slate-700" title={server.name}>{server.name}</span><span className="shrink-0 rounded bg-slate-100 px-1.5 py-0.5 text-[10px] text-slate-500">{server.transport}</span></div><p className="mt-1 text-[10px] text-slate-400">{server.health || 'configured'} · {server.tools.length} 个工具</p></div>)}<button type="button" disabled={pending !== null} onClick={() => void run('mcp', () => runtime.reloadTaskMcp(task.id))} className="flex h-8 w-full items-center justify-center gap-1.5 rounded-lg border border-slate-200 bg-white text-[10px] font-medium text-slate-600 hover:bg-slate-50 disabled:opacity-40"><RefreshCw size={11} className={pending === 'mcp' ? 'animate-spin' : ''} />热更新当前会话 MCP</button></div></details> : null}
            </section> : null}
        </div>
    </aside>;
};

export default TaskSessionSummaryPanel;
