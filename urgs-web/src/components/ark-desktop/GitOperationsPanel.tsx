import React, { useCallback, useEffect, useState } from 'react';
import {
    AlertCircle, Check, GitBranch, GitCommitHorizontal, LoaderCircle,
    RefreshCw, Sparkles, Upload,
} from 'lucide-react';
import type { GrokGitStatus } from '@/services/grokDesktop';
import type { ArkDesktopTask } from './types';
import type { ArkDesktopRuntime } from './useArkDesktopRuntime';
import { gitReviewCacheFor } from './gitReviewCache';

interface GitOperationsPanelProps {
    task: ArkDesktopTask | null;
    runtime: ArkDesktopRuntime;
    status?: GrokGitStatus;
    workspaceKey: string;
    onStatusChange: (status: GrokGitStatus, options?: { clearDiffs?: boolean; clearBranches?: boolean }) => void;
}

type GitAction = 'branches' | 'switch' | 'pull' | 'generate' | 'commit' | 'push';

const GitOperationsPanel: React.FC<GitOperationsPanelProps> = ({
    task, runtime, status, workspaceKey, onStatusChange,
}) => {
    const cache = gitReviewCacheFor(workspaceKey);
    const [branches, setBranches] = useState(cache.branches || []);
    const [selectedBranch, setSelectedBranch] = useState(status?.branch || '');
    const [commitMessage, setCommitMessage] = useState(cache.commitMessage || '');
    const [action, setAction] = useState<GitAction | null>(null);
    const [notice, setNotice] = useState('');
    const [error, setError] = useState('');

    const {
        listTaskGitBranches, switchTaskGitBranch, pullTaskGit,
        generateTaskGitCommitMessage, commitTaskGit, pushTaskGit,
    } = runtime;

    const runAction = async <T,>(name: GitAction, operation: () => Promise<T>) => {
        setAction(name);
        setNotice('');
        setError('');
        try {
            return await operation();
        } catch (cause) {
            setError(cause instanceof Error ? cause.message : String(cause));
            return undefined;
        } finally {
            setAction(null);
        }
    };

    const refreshBranches = useCallback(async (force = false) => {
        const currentCache = gitReviewCacheFor(workspaceKey);
        if (!force && currentCache.branches) {
            setBranches(currentCache.branches);
            return currentCache.branches;
        }
        if (!task) throw new Error('未创建任务');
        const nextBranches = await listTaskGitBranches(task.id);
        currentCache.branches = nextBranches;
        currentCache.branchesUpdatedAt = Date.now();
        setBranches(nextBranches);
        return nextBranches;
    }, [listTaskGitBranches, task, workspaceKey]);

    useEffect(() => {
        const currentCache = gitReviewCacheFor(workspaceKey);
        setBranches(currentCache.branches || []);
        setCommitMessage(currentCache.commitMessage || '');
        setSelectedBranch(status?.branch || '');
        setNotice('');
        setError('');
        if (!currentCache.branches && task) {
            void runAction('branches', () => refreshBranches()).catch(() => undefined);
        }
    }, [refreshBranches, status?.branch, task, workspaceKey]);

    const updateCommitMessage = (value: string) => {
        setCommitMessage(value);
        gitReviewCacheFor(workspaceKey).commitMessage = value;
    };

    const generateMessage = async () => {
        const message = await runAction('generate', () => generateTaskGitCommitMessage(task.id));
        if (!message) return;
        updateCommitMessage(message);
        setNotice('已生成提交说明，可直接修改后提交。');
    };

    const commit = async () => {
        const message = commitMessage.trim();
        if (!message) return;
        const result = await runAction('commit', () => commitTaskGit(task.id, message, { stageAll: true }));
        if (!result) return;
        updateCommitMessage('');
        onStatusChange(result.status, { clearDiffs: true });
        setNotice('提交成功。');
    };

    const pull = async () => {
        const result = await runAction('pull', () => pullTaskGit(task.id));
        if (!result) return;
        onStatusChange(result.status, { clearDiffs: true });
        setNotice(result.message || '拉取完成。');
    };

    const switchBranch = async () => {
        if (!selectedBranch || selectedBranch === status?.branch) return;
        const result = await runAction('switch', () => switchTaskGitBranch(task.id, selectedBranch));
        if (!result) return;
        onStatusChange(result.status, { clearDiffs: true, clearBranches: true });
        setSelectedBranch(result.status.branch || '');
        await runAction('branches', () => refreshBranches(true));
        setNotice(result.message || '分支切换完成。');
    };

    const push = async () => {
        const result = await runAction('push', () => pushTaskGit(task.id, !status?.upstream));
        if (!result) return;
        onStatusChange(result.status);
        setNotice(result.message || '推送成功。');
    };

    const busy = action !== null;
    const hasChanges = Boolean(status?.files.length);
    const worktreeDirty = Boolean(status?.isDirty);
    const canSwitch = Boolean(selectedBranch && selectedBranch !== status?.branch && !worktreeDirty && !busy);
    const canPull = Boolean(status?.branch && status?.upstream && !worktreeDirty && !busy);
    const canCommit = Boolean(hasChanges && commitMessage.trim() && !busy);
    const canPush = Boolean(status?.branch && status.ahead > 0 && !busy);

    if (!task) {
        return <div className="min-h-0 flex-1 overflow-y-auto bg-slate-50/60 px-5 py-5">
            <div className="mx-auto flex w-full max-w-2xl flex-col gap-5">
                <div className="flex items-start gap-2 rounded-xl bg-indigo-50 px-3 py-2.5 text-xs leading-5 text-indigo-700">
                    <AlertCircle size={15} className="mt-0.5 shrink-0" />
                    <span className="min-w-0 flex-1 break-words">当前为新建任务的工作区预览，仅可查看代码变更。提交、推送、分支切换等 Git 操作请在创建并打开任务后使用。</span>
                </div>
            </div>
        </div>;
    }

    return <div className="min-h-0 flex-1 overflow-y-auto bg-slate-50/60 px-5 py-5">
        <div className="mx-auto flex w-full max-w-2xl flex-col gap-5">
            {error && <div className="flex items-start gap-2 rounded-xl bg-red-50 px-3 py-2.5 text-xs leading-5 text-red-700"><AlertCircle size={15} className="mt-0.5 shrink-0" /><span className="min-w-0 flex-1 break-words">{error}</span></div>}
            {notice && <div className="flex items-center gap-2 rounded-xl bg-emerald-50 px-3 py-2.5 text-xs text-emerald-700"><Check size={15} />{notice}</div>}

            <section aria-labelledby="git-sync-heading">
                <div className="flex items-end justify-between gap-3">
                    <div>
                        <h3 id="git-sync-heading" className="text-sm font-semibold text-slate-900">分支与远端</h3>
                        <p className="mt-1 text-xs leading-5 text-slate-500">拉取采用快进模式；切换分支前需要先提交当前变更。</p>
                    </div>
                    <button type="button" disabled={busy} onClick={() => void runAction('branches', () => refreshBranches(true))} className="flex h-9 shrink-0 items-center gap-1.5 rounded-lg px-2.5 text-xs font-medium text-slate-500 hover:bg-slate-100 hover:text-slate-700 disabled:opacity-40"><RefreshCw size={14} className={action === 'branches' ? 'animate-spin' : ''} />刷新分支</button>
                </div>
                <div className="mt-3 flex min-w-0 items-stretch gap-2">
                    <div className="relative min-w-0 flex-1">
                        <GitBranch size={15} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                        <select aria-label="选择 Git 分支" value={selectedBranch} onChange={(event) => setSelectedBranch(event.target.value)} disabled={busy} className="h-10 w-full appearance-none rounded-xl border border-slate-200 bg-white pl-9 pr-8 text-sm text-slate-700 outline-none transition focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100 disabled:opacity-50">
                            {branches.map((branch) => <option key={`${branch.remote ? 'remote' : 'local'}:${branch.name}`} value={branch.name}>{!branch.remote && branch.name === status?.branch ? '当前 · ' : ''}{branch.remote ? '远端 · ' : ''}{branch.name}</option>)}
                        </select>
                    </div>
                    <button type="button" disabled={!canSwitch} onClick={() => void switchBranch()} className="flex h-10 shrink-0 items-center gap-1.5 rounded-xl border border-slate-200 bg-white px-3.5 text-xs font-semibold text-slate-700 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-35">{action === 'switch' ? <LoaderCircle size={14} className="animate-spin" /> : <GitBranch size={14} />}切换</button>
                    <button type="button" disabled={!canPull} onClick={() => void pull()} className="flex h-10 shrink-0 items-center gap-1.5 rounded-xl border border-slate-200 bg-white px-3.5 text-xs font-semibold text-slate-700 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-35">{action === 'pull' ? <LoaderCircle size={14} className="animate-spin" /> : <RefreshCw size={14} />}拉取{status?.behind ? ` ${status.behind}` : ''}</button>
                </div>
                {worktreeDirty && <p className="mt-2 text-[11px] leading-4 text-amber-700">当前有未提交变更，提交后才能拉取或切换分支。</p>}
                {!status?.upstream && !worktreeDirty && <p className="mt-2 text-[11px] leading-4 text-slate-400">当前分支没有上游分支，首次推送后即可使用拉取。</p>}
            </section>

            <div className="h-px bg-slate-200" />

            <section aria-labelledby="git-commit-heading">
                <div className="flex items-end justify-between gap-3">
                    <div>
                        <h3 id="git-commit-heading" className="text-sm font-semibold text-slate-900">提交与推送</h3>
                        <p className="mt-1 text-xs leading-5 text-slate-500">AI 根据当前 Diff 生成中文提交说明，提交会包含当前文件夹的全部变更。</p>
                    </div>
                    <button type="button" disabled={!hasChanges || busy} onClick={() => void generateMessage()} className="flex h-9 shrink-0 items-center gap-1.5 rounded-lg px-2.5 text-xs font-semibold text-indigo-600 hover:bg-indigo-50 disabled:cursor-not-allowed disabled:opacity-35">{action === 'generate' ? <LoaderCircle size={14} className="animate-spin" /> : <Sparkles size={14} />}AI 生成</button>
                </div>
                <textarea aria-label="Git 提交说明" value={commitMessage} onChange={(event) => updateCommitMessage(event.target.value)} placeholder="说明本次代码变更" rows={5} className="mt-3 w-full resize-y rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm leading-6 text-slate-800 outline-none transition placeholder:text-slate-400 focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100" />
                <div className="mt-3 flex justify-end gap-2">
                    <button type="button" disabled={!canCommit} onClick={() => void commit()} className="flex h-10 items-center gap-1.5 rounded-xl bg-slate-900 px-4 text-xs font-semibold text-white hover:bg-slate-700 disabled:cursor-not-allowed disabled:opacity-35">{action === 'commit' ? <LoaderCircle size={14} className="animate-spin" /> : <GitCommitHorizontal size={14} />}提交全部</button>
                    <button type="button" disabled={!canPush} onClick={() => void push()} className="flex h-10 items-center gap-1.5 rounded-xl border border-slate-200 bg-white px-4 text-xs font-semibold text-slate-700 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-35">{action === 'push' ? <LoaderCircle size={14} className="animate-spin" /> : <Upload size={14} />}推送{status?.ahead ? ` ${status.ahead}` : ''}</button>
                </div>
            </section>
        </div>
    </div>;
};

export default GitOperationsPanel;
