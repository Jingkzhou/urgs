import React, { useEffect, useMemo, useState } from 'react';
import {
    AlertCircle, BookOpen, CheckCircle2, FileCode2, LoaderCircle, Play, RefreshCw, ShieldCheck,
} from 'lucide-react';
import type { GrokWorkflowFile, GrokWorkflowListing } from '@/services/grokDesktop';
import type { ArkDesktopRuntime } from './useArkDesktopRuntime';

interface WorkflowCatalogPanelProps {
    runtime: ArkDesktopRuntime;
}

const inputClass = 'w-full rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-800 outline-none transition focus:border-[#8a7cf0] focus:ring-2 focus:ring-[#eeeaff]';

const sourceLabel = (source: string) => {
    switch (source) {
        case 'builtin': return '内置';
        case 'project': return '项目';
        case 'user': return '个人';
        default: return source || '未知';
    }
};

const WorkflowCatalogPanel: React.FC<WorkflowCatalogPanelProps> = ({ runtime }) => {
    const { listTaskWorkflows, readTaskWorkflow, launchWorkflow, validateWorkflow } = runtime;
    const sessionTasks = useMemo(() => runtime.snapshot.tasks.filter((task) => task.sessionId), [runtime.snapshot.tasks]);
    const [taskId, setTaskId] = useState(runtime.activeTaskId || sessionTasks[0]?.id || '');
    const [workflows, setWorkflows] = useState<GrokWorkflowListing[]>([]);
    const [selectedName, setSelectedName] = useState('');
    const [selectedFile, setSelectedFile] = useState<GrokWorkflowFile | null>(null);
    const [args, setArgs] = useState('');
    const [loading, setLoading] = useState(false);
    const [pending, setPending] = useState<'launch' | 'validate' | null>(null);
    const [authorizing, setAuthorizing] = useState(false);
    const [error, setError] = useState('');
    const [message, setMessage] = useState('');

    const selectedTask = sessionTasks.find((task) => task.id === taskId);
    const selectedWorkflow = workflows.find((workflow) => workflow.name === selectedName);

    useEffect(() => {
        if (runtime.activeTaskId && sessionTasks.some((task) => task.id === runtime.activeTaskId)) {
            setTaskId(runtime.activeTaskId);
            return;
        }
        if (!sessionTasks.some((task) => task.id === taskId)) {
            setTaskId(sessionTasks[0]?.id || '');
        }
    }, [runtime.activeTaskId, sessionTasks, taskId]);

    const loadWorkflows = async () => {
        if (!taskId || !selectedTask) {
            setWorkflows([]);
            setSelectedName('');
            setSelectedFile(null);
            setError('请先打开一个已经建立 Grok 会话的任务');
            return;
        }
        setLoading(true);
        setError('');
        setMessage('');
        try {
            const next = await listTaskWorkflows(taskId);
            setWorkflows(next);
            setSelectedName((current) => next.some((workflow) => workflow.name === current) ? current : next[0]?.name || '');
        } catch (cause) {
            setWorkflows([]);
            setSelectedName('');
            setSelectedFile(null);
            setError(cause instanceof Error ? cause.message : String(cause));
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        void loadWorkflows();
        // The selected task is the only input that changes which ACP session is queried.
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [taskId]);

    useEffect(() => {
        if (!selectedTask || !selectedName) {
            setSelectedFile(null);
            return;
        }
        let cancelled = false;
        setSelectedFile(null);
        void runtime.readTaskWorkflow(taskId, selectedName)
            .then((file) => {
                if (!cancelled) setSelectedFile(file);
            })
            .catch((cause) => {
                if (!cancelled) setError(cause instanceof Error ? cause.message : String(cause));
            });
        return () => { cancelled = true; };
    }, [readTaskWorkflow, selectedName, selectedTask?.id, taskId]);

    const launch = async () => {
        if (!selectedName || !selectedTask) return;
        setPending('launch');
        setError('');
        setMessage('');
        try {
            await launchWorkflow(taskId, selectedName, args);
            setMessage(`已发送“${selectedName}”启动请求，运行进度会回到所属会话和工作流运行中心。`);
        } catch (cause) {
            setError(cause instanceof Error ? cause.message : String(cause));
        } finally {
            setPending(null);
        }
    };

    const validate = async () => {
        if (!selectedName || !selectedTask) return;
        setPending('validate');
        setError('');
        setMessage('');
        try {
            await validateWorkflow(taskId, selectedName, args);
            setMessage('已发送只校验请求；结果会显示在所属会话时间线中，不会启动实际 Workflow。');
        } catch (cause) {
            setError(cause instanceof Error ? cause.message : String(cause));
        } finally {
            setPending(null);
        }
    };

    const authorize = async () => {
        if (!selectedTask?.modelKeyAuthorization) return;
        setAuthorizing(true);
        setError('');
        try {
            await runtime.authorizeTaskModel(taskId);
            await loadWorkflows();
        } catch (cause) {
            setError(cause instanceof Error ? cause.message : String(cause));
        } finally {
            setAuthorizing(false);
        }
    };

    return <section className="mt-7 rounded-2xl border border-slate-200 bg-white p-5 shadow-[0_6px_22px_rgba(15,23,42,0.04)]">
        <div className="flex flex-wrap items-start justify-between gap-4">
            <div>
                <div className="flex items-center gap-2 text-sm font-semibold text-slate-800"><BookOpen size={16} className="text-[#6657d9]" />Workflow 目录</div>
                <p className="mt-1.5 max-w-2xl text-xs leading-5 text-slate-500">读取当前 Grok 会话发现的内置、项目和个人 Workflow。项目脚本来自工作区的 <code className="rounded bg-slate-100 px-1">.grok/workflows/*.rhai</code>。</p>
            </div>
            <button type="button" onClick={() => void loadWorkflows()} disabled={loading} className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 px-3 py-2 text-xs font-medium text-slate-600 hover:border-slate-300 hover:text-slate-800 disabled:cursor-not-allowed disabled:opacity-50"><RefreshCw size={13} className={loading ? 'animate-spin' : ''} />刷新目录</button>
        </div>

        {sessionTasks.length > 0 && <label className="mt-4 block max-w-xl"><span className="mb-1.5 block text-[11px] font-medium text-slate-500">读取会话</span><select className={inputClass} value={taskId} onChange={(event) => setTaskId(event.target.value)}><option value="">选择任务会话</option>{sessionTasks.map((task) => <option key={task.id} value={task.id}>{task.title} · {task.workspace.split(/[\\/]/).pop() || task.workspace}</option>)}</select></label>}

        {selectedTask?.modelKeyAuthorization && <div className="mt-4 flex flex-wrap items-center gap-3 rounded-xl border border-amber-200 bg-amber-50 px-3 py-2.5 text-xs text-amber-900"><div className="min-w-0 flex-1"><div className="font-medium">先解锁本地模型密钥</div><div className="mt-0.5 text-[11px] leading-5 text-amber-700">目录读取会恢复当前会话，仅从本机钥匙串读取，不连接外部服务。</div></div><button type="button" disabled={authorizing} onClick={() => void authorize()} className="inline-flex items-center gap-1.5 rounded-lg bg-amber-700 px-3 py-2 text-xs font-medium text-white hover:bg-amber-800 disabled:cursor-not-allowed disabled:opacity-50"><ShieldCheck size={13} />{authorizing ? '解锁中…' : '解锁密钥'}</button></div>}
        {error && <div className="mt-4 flex items-start gap-2 rounded-xl bg-red-50 px-3 py-2.5 text-xs leading-5 text-red-700"><AlertCircle size={14} className="mt-0.5 shrink-0" />{error}</div>}
        {message && <div className="mt-4 flex items-start gap-2 rounded-xl bg-emerald-50 px-3 py-2.5 text-xs leading-5 text-emerald-700"><CheckCircle2 size={14} className="mt-0.5 shrink-0" />{message}</div>}

        {loading ? <div className="flex items-center justify-center gap-2 py-10 text-xs text-slate-400"><LoaderCircle size={16} className="animate-spin" />读取 Workflow 目录…</div> : workflows.length === 0 ? <div className="mt-5 rounded-xl border border-dashed border-slate-200 bg-slate-50 px-4 py-8 text-center text-xs text-slate-400">当前会话没有返回可用 Workflow，或会话尚未挂载。</div> : <div className="mt-5 grid gap-3 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.15fr)]">
            <div className="space-y-2">
                {workflows.map((workflow) => <button key={workflow.name} type="button" onClick={() => { setSelectedName(workflow.name); setError(''); setMessage(''); }} className={`w-full rounded-xl border px-3.5 py-3 text-left transition ${selectedName === workflow.name ? 'border-[#b8aff8] bg-[#faf9ff] shadow-sm' : 'border-slate-200 bg-white hover:border-slate-300'}`}>
                    <div className="flex items-start gap-2"><FileCode2 size={15} className="mt-0.5 shrink-0 text-[#7668df]" /><span className="min-w-0 flex-1 truncate text-sm font-medium text-slate-800">{workflow.name}</span><span className="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] text-slate-500">{sourceLabel(workflow.source)}</span></div>
                    <p className="mt-1.5 line-clamp-2 pl-[23px] text-[11px] leading-5 text-slate-500">{workflow.description || '未提供说明'}</p>
                </button>)}
            </div>

            <div className="rounded-xl border border-slate-200 bg-slate-50/70 p-4">
                {selectedWorkflow ? <>
                    <div className="flex items-start gap-2"><div className="min-w-0 flex-1"><div className="text-sm font-semibold text-slate-800">{selectedWorkflow.name}</div><div className="mt-1 text-[11px] text-slate-400">来源：{sourceLabel(selectedWorkflow.source)}{selectedWorkflow.path ? ` · ${selectedWorkflow.path}` : ''}</div></div><ShieldCheck size={17} className="text-emerald-500" /></div>
                    {selectedWorkflow.whenToUse && <p className="mt-3 rounded-lg bg-white px-3 py-2 text-xs leading-5 text-slate-600">适用场景：{selectedWorkflow.whenToUse}</p>}
                    {selectedFile?.content && <details className="mt-3 rounded-lg border border-slate-200 bg-white"><summary className="cursor-pointer px-3 py-2 text-[11px] font-medium text-slate-600">查看脚本源码</summary><pre className="max-h-44 overflow-auto border-t border-slate-100 px-3 py-2 text-[10px] leading-4 text-slate-500">{selectedFile.content}</pre></details>}
                    <label className="mt-4 block"><span className="mb-1.5 block text-[11px] font-medium text-slate-600">运行参数（JSON 对象或查询文本）</span><textarea className={`${inputClass} min-h-20 resize-y`} value={args} onChange={(event) => setArgs(event.target.value)} placeholder={'例如：{"query":"本周监管政策变化","objective":"输出可核验摘要"}'} rows={3} /></label>
                    <div className="mt-3 flex flex-wrap items-center gap-2"><button type="button" onClick={() => void launch()} disabled={pending !== null || !selectedTask} className="inline-flex items-center gap-1.5 rounded-lg bg-slate-900 px-3 py-2 text-xs font-medium text-white hover:bg-slate-700 disabled:cursor-not-allowed disabled:opacity-50"><Play size={13} />{pending === 'launch' ? '发送中…' : '启动 Workflow'}</button><button type="button" onClick={() => void validate()} disabled={pending !== null || !selectedTask} className="inline-flex items-center gap-1.5 rounded-lg border border-[#c8c1fb] bg-[#faf9ff] px-3 py-2 text-xs font-medium text-[#5d50c7] hover:bg-[#f2efff] disabled:cursor-not-allowed disabled:opacity-50"><ShieldCheck size={13} />{pending === 'validate' ? '校验中…' : '只校验不启动'}</button></div>
                    <p className="mt-3 text-[10px] leading-4 text-slate-400">“只校验不启动”会通过当前会话请求 Grok 官方 Workflow 工具的 <code className="rounded bg-white px-1">validate_only=true</code> 路径；结果保留在会话时间线，便于追溯。</p>
                </> : <div className="flex min-h-56 items-center justify-center text-xs text-slate-400">选择一个 Workflow 查看详情</div>}
            </div>
        </div>}
    </section>;
};

export default WorkflowCatalogPanel;
