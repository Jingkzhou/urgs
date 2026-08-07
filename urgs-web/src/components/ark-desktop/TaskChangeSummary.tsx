import React, { useMemo, useState } from 'react';
import { AlertTriangle, CheckCircle2, ChevronDown, FileDiff, LoaderCircle, RotateCcw, X } from 'lucide-react';
import { mergeFileChanges } from './fileChanges';
import TaskPlanPanel from './TaskPlanPanel';
import type { ArkDesktopPlanStep, ArkDesktopTask, ArkDesktopTaskStatus } from './types';

interface TaskChangeSummaryProps {
    taskId: string;
    workspace: string;
    promptIndex: number;
    tools: ArkDesktopTask['tools'];
    taskStatus: ArkDesktopTaskStatus;
    plan?: ArkDesktopPlanStep[];
    onRewind: (taskId: string, promptIndex: number, force?: boolean) => Promise<{ requiresConfirmation: boolean; conflicts: Array<{ path: string; conflictType: string }> }>;
}

const displayPath = (path: string, workspace: string) => {
    const normalizedWorkspace = workspace.replace(/\/$/, '');
    return path.startsWith(`${normalizedWorkspace}/`) ? path.slice(normalizedWorkspace.length + 1) : path;
};

const meaningfulLines = (lines: string[]) => lines.length === 1 && lines[0] === '' ? [] : lines;

const ConflictConfirmation: React.FC<{
    workspace: string;
    conflicts: Array<{ path: string; conflictType: string }>;
    busy: boolean;
    onCancel: () => void;
    onConfirm: () => void;
}> = ({ workspace, conflicts, busy, onCancel, onConfirm }) => <div className="fixed inset-0 z-[1250] flex items-center justify-center bg-slate-950/35 p-5 backdrop-blur-[2px]" role="dialog" aria-modal="true" aria-label="确认覆盖外部修改">
    <div className="w-[min(520px,94vw)] rounded-2xl border border-amber-200 bg-white p-5 shadow-2xl">
        <div className="flex gap-3"><span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-amber-50 text-amber-700"><AlertTriangle size={20} /></span><div><h3 className="text-base font-semibold text-slate-800">检测到外部修改</h3><p className="mt-1 text-sm leading-6 text-slate-600">这些文件在智能体完成后又发生了变化。继续撤销会用该轮开始前的版本覆盖它们。</p></div></div>
        <div className="mt-4 max-h-44 overflow-auto rounded-xl bg-slate-50 px-3 py-2">{conflicts.map((conflict) => <div key={`${conflict.path}-${conflict.conflictType}`} className="flex items-center justify-between gap-3 py-1.5 text-xs"><span className="min-w-0 truncate font-mono text-slate-600" title={conflict.path}>{displayPath(conflict.path, workspace)}</span><span className="shrink-0 text-amber-700">{conflict.conflictType === 'deleted_externally' ? '已在外部删除' : conflict.conflictType === 'created_externally' ? '已在外部创建' : '已在外部修改'}</span></div>)}</div>
        <div className="mt-5 flex justify-end gap-2"><button type="button" disabled={busy} onClick={onCancel} className="h-9 rounded-lg px-3 text-sm font-medium text-slate-600 hover:bg-slate-100">保留外部修改</button><button type="button" disabled={busy} onClick={onConfirm} className="flex h-9 items-center gap-1.5 rounded-lg bg-red-600 px-3 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60">{busy && <LoaderCircle size={14} className="animate-spin" />}仍然撤销并覆盖</button></div>
    </div>
</div>;

const DiffReview: React.FC<{
    workspace: string;
    files: ReturnType<typeof mergeFileChanges>;
    onClose: () => void;
}> = ({ workspace, files, onClose }) => {
    const [selectedPath, setSelectedPath] = useState(files[0]?.path || '');
    const selected = files.find((file) => file.path === selectedPath) || files[0];
    return <div className="fixed inset-0 z-[1200] flex items-center justify-center bg-slate-950/30 p-5 backdrop-blur-[2px]" role="dialog" aria-modal="true" aria-label="审核文件修改">
        <div className="flex h-[min(760px,88vh)] w-[min(1120px,94vw)] overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-2xl">
            <aside className="w-72 shrink-0 border-r border-slate-200 bg-slate-50/70 p-3">
                <div className="px-2 py-2 text-xs font-semibold tracking-wide text-slate-400">修改的文件</div>
                <div className="space-y-1">{files.map((file) => <button key={file.path} type="button" onClick={() => setSelectedPath(file.path)} className={`w-full rounded-lg px-2.5 py-2 text-left ${file.path === selected?.path ? 'bg-white shadow-sm ring-1 ring-slate-200' : 'hover:bg-white/70'}`}><div className="truncate text-xs font-medium text-slate-700" title={file.path}>{displayPath(file.path, workspace)}</div><div className="mt-1 text-[11px]"><span className="text-emerald-600">+{file.additions}</span><span className="ml-2 text-red-500">-{file.deletions}</span></div></button>)}</div>
            </aside>
            <section className="flex min-w-0 flex-1 flex-col">
                <header className="flex h-14 shrink-0 items-center justify-between border-b border-slate-200 px-4"><div className="min-w-0"><div className="truncate text-sm font-medium text-slate-800" title={selected?.path}>{selected ? displayPath(selected.path, workspace) : '文件修改'}</div>{selected?.previewTruncated && <div className="text-[11px] text-amber-600">文件较大，仅展示前部变更预览</div>}</div><button type="button" onClick={onClose} className="rounded-lg p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-700" aria-label="关闭审核"><X size={18} /></button></header>
                <div className="min-h-0 flex-1 overflow-auto bg-[#fbfbfc] p-4 font-mono text-[12px] leading-5">{selected?.hunks.map((hunk, hunkIndex) => <div key={`${selected.path}-${hunkIndex}`} className="mb-4 overflow-hidden rounded-lg border border-slate-200 bg-white"><div className="border-b border-slate-200 bg-slate-50 px-3 py-1.5 text-[11px] text-slate-400">@@ -{hunk.oldLine} +{hunk.newLine} @@</div>{meaningfulLines(hunk.oldLines).map((line, index) => <div key={`old-${index}`} className="grid grid-cols-[52px_1fr] bg-red-50/80 text-red-800"><span className="select-none border-r border-red-100 px-2 text-right text-red-300">{hunk.oldLine + index}</span><span className="whitespace-pre-wrap break-all px-3">- {line}</span></div>)}{meaningfulLines(hunk.newLines).map((line, index) => <div key={`new-${index}`} className="grid grid-cols-[52px_1fr] bg-emerald-50/80 text-emerald-800"><span className="select-none border-r border-emerald-100 px-2 text-right text-emerald-300">{hunk.newLine + index}</span><span className="whitespace-pre-wrap break-all px-3">+ {line}</span></div>)}</div>)}</div>
            </section>
        </div>
    </div>;
};

const RunningChangeProgress: React.FC<{
    files: ReturnType<typeof mergeFileChanges>;
    taskStatus: ArkDesktopTaskStatus;
    plan?: ArkDesktopPlanStep[];
}> = ({ files, taskStatus, plan }) => {
    const hasFiles = files.length > 0;
    const additions = files.reduce((total, file) => total + file.additions, 0);
    const deletions = files.reduce((total, file) => total + file.deletions, 0);
    const completedPlanCount = plan?.filter((step) => step.status === 'completed' || step.status === 'cancelled').length || 0;
    const activePlanIndex = plan?.findIndex((step) => step.status === 'in_progress') ?? -1;
    const currentPlanStep = plan?.length
        ? activePlanIndex >= 0 ? activePlanIndex + 1 : Math.min(completedPlanCount + 1, plan.length)
        : 0;

    const progressIconClass = taskStatus === 'running' ? 'animate-spin text-blue-500' : 'text-amber-500';
    return <section className="my-3 flex flex-wrap justify-center gap-2" aria-label="当前执行进度">
        {plan?.length ? <TaskPlanPanel
            plan={plan}
            taskStatus={taskStatus}
            trigger={<><LoaderCircle size={17} className={`shrink-0 ${progressIconClass}`} />{taskStatus === 'waiting_authorization' ? <span className="shrink-0 font-medium text-slate-700">等待授权</span> : <span className="shrink-0 font-medium text-slate-700">第 {currentPlanStep} / {plan.length} 步</span>}</>}
        /> : null}
        {hasFiles ? <div className="inline-flex max-w-full items-center gap-2 rounded-full border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-600 shadow-[0_1px_3px_rgba(15,23,42,0.05)]" aria-label="当前文件变更">
            <FileDiff size={17} className="shrink-0 text-slate-500" />
            <span className="shrink-0 font-medium text-slate-700">{taskStatus === 'waiting_authorization' ? '等待授权' : '正在执行'}</span>
            <span className="text-slate-300">·</span>
            <span className="truncate">{files.length} 个文件已更改</span>
            <span className="shrink-0 whitespace-nowrap"><span className="text-emerald-600">+{additions}</span><span className="ml-2 text-red-500">-{deletions}</span></span>
        </div> : null}
    </section>;
};

const TaskChangeSummary: React.FC<TaskChangeSummaryProps> = ({ taskId, workspace, promptIndex, tools, taskStatus, plan, onRewind }) => {
    const files = useMemo(() => mergeFileChanges(tools.flatMap((tool) => tool.fileChanges || [])), [tools]);
    const [expanded, setExpanded] = useState(false);
    const [reviewing, setReviewing] = useState(false);
    const [undoing, setUndoing] = useState(false);
    const [error, setError] = useState('');
    const [conflicts, setConflicts] = useState<Array<{ path: string; conflictType: string }> | null>(null);
    const activeTask = taskStatus === 'running' || taskStatus === 'waiting_authorization';
    if (activeTask && files.length === 0 && !plan?.length) return null;
    if (activeTask) return <RunningChangeProgress files={files} taskStatus={taskStatus} plan={plan} />;
    if (files.length === 0) return null;
    const additions = files.reduce((total, file) => total + file.additions, 0);
    const deletions = files.reduce((total, file) => total + file.deletions, 0);
    const reverted = tools.some((tool) => tool.fileChanges?.length && tool.changesRevertedAt);
    const visibleFiles = expanded ? files : files.slice(0, 3);
    const hiddenCount = files.length - visibleFiles.length;
    const undo = async () => {
        if (!window.confirm('撤销这一轮及其后由智能体产生的文件修改？会话内容会保留。')) return;
        setUndoing(true);
        setError('');
        try {
            const outcome = await onRewind(taskId, promptIndex);
            if (outcome.requiresConfirmation) setConflicts(outcome.conflicts);
        } catch (reason) {
            setError(reason instanceof Error ? reason.message : String(reason));
        } finally {
            setUndoing(false);
        }
    };
    const forceUndo = async () => {
        setUndoing(true);
        setError('');
        try {
            await onRewind(taskId, promptIndex, true);
            setConflicts(null);
        } catch (reason) {
            setError(reason instanceof Error ? reason.message : String(reason));
        } finally {
            setUndoing(false);
        }
    };
    return <>
        <section className="my-4 overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-[0_1px_2px_rgba(15,23,42,0.03)]" aria-label={`已编辑 ${files.length} 个文件`}>
            <div className="flex items-center gap-3 border-b border-slate-100 px-4 py-3.5"><span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-slate-100 text-slate-500"><FileDiff size={20} /></span><div className="min-w-0 flex-1"><div className="flex items-center gap-2 text-[15px] font-semibold text-slate-800">{reverted ? '文件修改已撤销' : `已编辑 ${files.length} 个文件`}{reverted && <CheckCircle2 size={16} className="text-emerald-600" />}</div><div className="mt-0.5 text-xs"><span className="text-emerald-600">+{additions}</span><span className="ml-2 text-red-500">-{deletions}</span></div></div><div className="flex items-center gap-1.5">{!reverted && <button type="button" disabled={undoing} onClick={() => void undo()} className="flex h-8 items-center gap-1.5 rounded-lg px-2.5 text-sm font-medium text-slate-600 hover:bg-slate-100 disabled:opacity-50">{undoing ? <LoaderCircle size={15} className="animate-spin" /> : <RotateCcw size={15} />}撤销</button>}<button type="button" onClick={() => setReviewing(true)} className="h-8 rounded-lg border border-slate-200 px-3 text-sm font-medium text-slate-700 shadow-sm hover:bg-slate-50">审核</button></div></div>
            <div className="px-4 py-2">{visibleFiles.map((file) => <button key={file.path} type="button" onClick={() => setReviewing(true)} className="flex w-full items-center gap-3 rounded-lg px-1 py-2 text-left hover:bg-slate-50"><span className="min-w-0 flex-1 truncate text-[13px] text-slate-600" title={file.path}>{displayPath(file.path, workspace)}</span><span className="shrink-0 text-xs"><span className="text-emerald-600">+{file.additions}</span><span className="ml-2 text-red-500">-{file.deletions}</span></span></button>)}{hiddenCount > 0 && <button type="button" onClick={() => setExpanded(true)} className="flex items-center gap-1 py-2 text-xs font-medium text-slate-600 hover:text-slate-900">再显示 {hiddenCount} 个文件<ChevronDown size={14} /></button>}{expanded && files.length > 3 && <button type="button" onClick={() => setExpanded(false)} className="flex items-center gap-1 py-2 text-xs font-medium text-slate-500 hover:text-slate-900">收起文件<ChevronDown size={14} className="rotate-180" /></button>}</div>
            {error && <div className="border-t border-red-100 bg-red-50 px-4 py-2.5 text-xs leading-5 text-red-700">{error}</div>}
        </section>
        {reviewing && <DiffReview workspace={workspace} files={files} onClose={() => setReviewing(false)} />}
        {conflicts && <ConflictConfirmation workspace={workspace} conflicts={conflicts} busy={undoing} onCancel={() => setConflicts(null)} onConfirm={() => void forceUndo()} />}
    </>;
};

export default TaskChangeSummary;
