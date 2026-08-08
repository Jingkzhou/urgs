import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
    AlertTriangle, Archive, Check, Download, Eye, FileDiff, PanelLeftClose, PanelLeftOpen,
    GitBranch, GitCommitHorizontal, GitMerge, LoaderCircle, RefreshCw, Sparkles,
    ShieldCheck, Trash2, Upload, X,
} from 'lucide-react';
import { type GrokGitAuditEntry, type GrokGitDiff, type GrokGitRemote, type GrokGitStatus, type GrokGitWorktree } from '@/services/grokDesktop';
import type { ArkDesktopTask } from './types';
import type { ArkDesktopRuntime } from './useArkDesktopRuntime';
import GitFileTree from './GitFileTree';
import GitDiffViewer from './GitDiffViewer';

type ReviewTab = 'review' | 'commit' | 'worktree';

interface GitReviewPanelProps {
    task: ArkDesktopTask;
    runtime: ArkDesktopRuntime;
    onClose: () => void;
}

const workspaceName = (value: string) => value.split(/[\\/]/).filter(Boolean).pop() || value;
const NON_GIT_REPOSITORY_NOTICE = '当前工作区不是 Git 仓库，代码变更审查仅适用于 Git 仓库。';
const isNonGitRepositoryError = (message: string) => {
    const normalized = message.toLowerCase();
    return normalized.includes('not a git repository')
        || normalized.includes('无法启动 git')
        || normalized.includes('program not found')
        || normalized.includes('executable file not found')
        || normalized.includes('os error 2')
        || /不是(?:一个)?\s*git\s*仓库/.test(message);
};
const DEFAULT_PANEL_WIDTH = 560;
const MIN_PANEL_WIDTH = 420;
const MAX_PANEL_WIDTH = 720;
const PANEL_WIDTH_STORAGE_KEY = 'urgs_ark_desktop_git_review_panel_width_v1';

const clampPanelWidthValue = (value: number) => {
    const viewportMax = typeof window === 'undefined' ? MAX_PANEL_WIDTH : Math.floor(window.innerWidth * 0.65);
    return Math.min(Math.max(MIN_PANEL_WIDTH, value), Math.max(MIN_PANEL_WIDTH, Math.min(MAX_PANEL_WIDTH, viewportMax)));
};

const readStoredPanelWidth = () => {
    if (typeof window === 'undefined') return DEFAULT_PANEL_WIDTH;
    try {
        const stored = localStorage.getItem(PANEL_WIDTH_STORAGE_KEY);
        if (!stored) return DEFAULT_PANEL_WIDTH;
        const value = Number(stored);
        return Number.isFinite(value) ? clampPanelWidthValue(value) : DEFAULT_PANEL_WIDTH;
    } catch {
        return DEFAULT_PANEL_WIDTH;
    }
};

const persistPanelWidth = (value: number) => {
    if (typeof window === 'undefined') return;
    try {
        localStorage.setItem(PANEL_WIDTH_STORAGE_KEY, String(value));
    } catch {
        // 本地偏好写入失败不应影响审查面板使用。
    }
};

const GitReviewPanel: React.FC<GitReviewPanelProps> = ({ task, runtime, onClose }) => {
    const [tab, setTab] = useState<ReviewTab>('review');
    const [status, setStatus] = useState<GrokGitStatus | undefined>(task.gitContext?.status);
    const [diff, setDiff] = useState<GrokGitDiff | null>(null);
    const [selectedFile, setSelectedFile] = useState('');
    const [diffPath, setDiffPath] = useState('');
    const [selectedPaths, setSelectedPaths] = useState<string[]>([]);
    const [showStagedDiff, setShowStagedDiff] = useState(false);
    const [worktrees, setWorktrees] = useState<GrokGitWorktree[]>([]);
    const [remotes, setRemotes] = useState<GrokGitRemote[]>([]);
    const [auditEntries, setAuditEntries] = useState<GrokGitAuditEntry[]>([]);
    const [commitMessage, setCommitMessage] = useState('');
    const [stageAll, setStageAll] = useState(true);
    const [amend, setAmend] = useState(false);
    const [signoff, setSignoff] = useState(false);
    const [busy, setBusy] = useState<string | null>(null);
    const [error, setError] = useState('');
    const [notice, setNotice] = useState('');
    const [gitRepositoryUnavailable, setGitRepositoryUnavailable] = useState(false);
    const [confirmation, setConfirmation] = useState<{ title: string; body: string; confirmLabel: string; action: () => Promise<void>; refreshAfter?: boolean; busyLabel?: string } | null>(null);
    const [worktreeRemoved, setWorktreeRemoved] = useState(false);
    const [isFileNavOpen, setIsFileNavOpen] = useState(false);
    const [panelWidth, setPanelWidth] = useState(readStoredPanelWidth);
    const [isResizing, setIsResizing] = useState(false);
    const resizeStartRef = useRef<{ startX: number; startWidth: number } | null>(null);

    const { refreshTaskGitStatus, listTaskGitWorktrees, listTaskGitAudit, listTaskGitRemotes, loadTaskGitDiff } = runtime;

    const currentStatus = status || task.gitContext?.status;
    const files = currentStatus?.files || [];
    const aheadCount = currentStatus?.ahead || 0;
    const behindCount = currentStatus?.behind || 0;
    const isFetching = busy === 'fetch';
    const isPushing = busy === 'push';
    const selectedFileSet = useMemo(() => new Set(selectedPaths), [selectedPaths]);
    const isReadonly = task.gitContext?.mode === 'readonly';
    const isWorktree = task.gitContext?.mode === 'worktree';
    const repoRoot = task.gitContext?.repoRoot || task.sourceWorkspace || task.workspace;
    const isGitRepository = !gitRepositoryUnavailable && currentStatus?.isRepository !== false;

    const clampPanelWidth = useCallback((value: number) => {
        return clampPanelWidthValue(value);
    }, []);

    useEffect(() => {
        persistPanelWidth(panelWidth);
    }, [panelWidth]);

    const handleResizePointerDown = (event: React.PointerEvent<HTMLDivElement>) => {
        event.preventDefault();
        resizeStartRef.current = { startX: event.clientX, startWidth: panelWidth };
        setIsResizing(true);
    };

    const handleResizeKeyDown = (event: React.KeyboardEvent<HTMLDivElement>) => {
        if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
            event.preventDefault();
            setPanelWidth((current) => clampPanelWidth(current + (event.key === 'ArrowLeft' ? 16 : -16)));
        } else if (event.key === 'Home') {
            event.preventDefault();
            setPanelWidth(DEFAULT_PANEL_WIDTH);
        }
    };

    useEffect(() => {
        if (!isResizing) return undefined;
        const handlePointerMove = (event: PointerEvent) => {
            const start = resizeStartRef.current;
            if (!start) return;
            setPanelWidth(clampPanelWidth(start.startWidth - (event.clientX - start.startX)));
        };
        const stopResizing = () => {
            resizeStartRef.current = null;
            setIsResizing(false);
        };
        const previousCursor = document.body.style.cursor;
        const previousUserSelect = document.body.style.userSelect;
        document.body.style.cursor = 'col-resize';
        document.body.style.userSelect = 'none';
        window.addEventListener('pointermove', handlePointerMove);
        window.addEventListener('pointerup', stopResizing);
        window.addEventListener('pointercancel', stopResizing);
        return () => {
            document.body.style.cursor = previousCursor;
            document.body.style.userSelect = previousUserSelect;
            window.removeEventListener('pointermove', handlePointerMove);
            window.removeEventListener('pointerup', stopResizing);
            window.removeEventListener('pointercancel', stopResizing);
        };
    }, [clampPanelWidth, isResizing]);

    const refresh = useCallback(async () => {
        setBusy('refresh');
        setError('');
        try {
            const [nextStatus, nextWorktrees, nextAudit, nextRemotes] = await Promise.all([
                refreshTaskGitStatus(task.id),
                listTaskGitWorktrees(task.id).catch(() => []),
                listTaskGitAudit(task.id).catch(() => []),
                listTaskGitRemotes(task.id).catch(() => []),
            ]);
            setStatus(nextStatus);
            setGitRepositoryUnavailable(false);
            setWorktrees(nextWorktrees);
            setAuditEntries(nextAudit);
            setRemotes(nextRemotes);
            setSelectedPaths((current) => current.filter((path) => nextStatus.files.some((file) => file.path === path)));
            setSelectedFile((current) => current && nextStatus.files.some((file) => file.path === current)
                ? current
                : nextStatus.files[0]?.path || '');
            setDiffPath((current) => current && nextStatus.files.some((file) => file.path === current) ? current : '');
        } catch (nextError) {
            const message = nextError instanceof Error ? nextError.message : String(nextError);
            if (task.gitContext?.mode !== 'workspace' && /工作区不存在|does not exist|not found/i.test(message)) {
                setWorktreeRemoved(true);
                setNotice('此任务 Worktree 已清理，源仓库仍然保留。');
                return;
            }
            if (isNonGitRepositoryError(message)) {
                setGitRepositoryUnavailable(true);
                setDiff(null);
                setNotice(NON_GIT_REPOSITORY_NOTICE);
                return;
            }
            setError(message);
        } finally {
            setBusy(null);
        }
    }, [listTaskGitAudit, listTaskGitRemotes, listTaskGitWorktrees, refreshTaskGitStatus, task.gitContext?.mode, task.id]);

    const refreshRef = useRef(refresh);
    refreshRef.current = refresh;

    useEffect(() => {
        setDiffPath('');
        setGitRepositoryUnavailable(false);
        void refreshRef.current();
    }, [task.id]);

    useEffect(() => {
        setWorktreeRemoved(false);
    }, [task.id]);

    const loadDiff = useCallback(async (path: string | undefined, staged: boolean) => {
        setBusy('diff');
        setError('');
        try {
            setDiff(await loadTaskGitDiff(task.id, path, staged));
        } catch (nextError) {
            const message = nextError instanceof Error ? nextError.message : String(nextError);
            if (isNonGitRepositoryError(message)) {
                setGitRepositoryUnavailable(true);
                setDiff(null);
                setNotice(NON_GIT_REPOSITORY_NOTICE);
            } else {
                setError(message);
            }
        } finally {
            setBusy(null);
        }
    }, [loadTaskGitDiff, task.id]);

    useEffect(() => {
        if (tab === 'review') void loadDiff(diffPath || undefined, showStagedDiff);
    }, [diffPath, loadDiff, showStagedDiff, tab]);

    const runSafe = async (label: string, action: () => Promise<unknown>, refreshAfter = true) => {
        setBusy(label);
        setError('');
        setNotice('');
        try {
            await action();
            setNotice('操作已完成，审计记录已写入本机。');
            if (refreshAfter) await refresh();
        } catch (nextError) {
            setError(nextError instanceof Error ? nextError.message : String(nextError));
        } finally {
            setBusy(null);
        }
    };

    const askApproval = (title: string, body: string, confirmLabel: string, action: () => Promise<void>, refreshAfter = true, busyLabel?: string) => {
        setConfirmation({ title, body, confirmLabel, action, refreshAfter, busyLabel });
    };

    const confirmAction = async () => {
        if (!confirmation) return;
        const action = confirmation.action;
        setConfirmation(null);
        await runSafe(confirmation.busyLabel || 'confirm', action, confirmation.refreshAfter !== false);
    };

    const togglePath = (path: string) => setSelectedPaths((current) => current.includes(path) ? current.filter((item) => item !== path) : [...current, path]);
    const pathsForAction = selectedPaths.length > 0 ? selectedPaths : selectedFile ? [selectedFile] : [];

    const stageSelected = () => {
        if (!pathsForAction.length) return;
        askApproval(
            '确认暂存变更',
            `将把 ${pathsForAction.length} 个文件加入 ${workspaceName(task.workspace)} 的 Git 暂存区，不会创建提交。`,
            '暂存变更',
            async () => { await runtime.stageTaskGit(task.id, pathsForAction); },
        );
    };

    const unstageSelected = () => {
        if (!pathsForAction.length) return;
        askApproval(
            '确认取消暂存',
            `将把 ${pathsForAction.length} 个文件移出暂存区，工作区文件内容不会被删除。`,
            '取消暂存',
            async () => { await runtime.unstageTaskGit(task.id, pathsForAction); },
        );
    };

    const stageAllChanges = () => askApproval(
        '确认暂存全部变更',
        `将把 ${files.length} 个变更文件加入 ${workspaceName(task.workspace)} 的 Git 暂存区，不会创建提交。`,
        '暂存全部',
        async () => { await runtime.stageTaskGit(task.id, [], true); },
    );

    const gcWorktrees = () => askApproval(
        '确认清理 Worktree 记录',
        '只会清理 Git 已经不存在的 Worktree 记录，不会删除仍然存在的任务目录或未提交文件。',
        '清理记录',
        async () => { await runtime.gcTaskGitWorktrees(task.id); },
    );

    const discardSelected = () => {
        if (!pathsForAction.length) return;
        askApproval(
            '确认丢弃本地变更',
            `将从 ${workspaceName(task.workspace)} 丢弃 ${pathsForAction.length} 个文件的工作区变更；此操作不会进入 Git 历史，未跟踪文件也不会自动删除。`,
            '丢弃变更',
            async () => { await runtime.discardTaskGit(task.id, pathsForAction, false, true); },
        );
    };

    const openDiff = (path: string) => {
        setSelectedFile(path);
        setDiffPath(path);
        setTab('review');
    };

    const openAllDiff = () => {
        setSelectedFile('');
        setDiffPath('');
        setTab('review');
    };

    const runFileAction = async (label: string, action: () => Promise<unknown>, successMessage: string) => {
        setBusy(label);
        setError('');
        setNotice('');
        try {
            await action();
            setNotice(successMessage);
        } catch (nextError) {
            setError(nextError instanceof Error ? nextError.message : String(nextError));
        } finally {
            setBusy(null);
        }
    };

    const openFile = (path: string) => {
        void runFileAction('open-file', () => runtime.openTaskGitFile(task.id, path), '已在系统默认编辑器中打开文件。');
    };

    const openHeadFile = (path: string) => {
        void runFileAction('open-head-file', () => runtime.openTaskGitFile(task.id, path, 'HEAD'), '已在系统默认编辑器中打开 HEAD 版本。');
    };

    const revealInFinder = (path: string) => {
        void runFileAction('reveal-file', () => runtime.revealTaskGitFile(task.id, path), '已在查找器中显示文件。');
    };

    const stageFile = (path: string) => askApproval(
        '确认暂存变更',
        '将把文件 ' + path + ' 加入 ' + workspaceName(task.workspace) + ' 的 Git 暂存区，不会创建提交。',
        '暂存变更',
        async () => { await runtime.stageTaskGit(task.id, [path]); },
    );

    const discardFile = (path: string) => askApproval(
        '确认放弃本地变更',
        '将从 ' + workspaceName(task.workspace) + ' 放弃文件 ' + path + ' 的工作区变更；此操作不会进入 Git 历史。',
        '放弃更改',
        async () => { await runtime.discardTaskGit(task.id, [path], false, true); },
    );

    const addToGitignore = (path: string) => {
        void runSafe('gitignore', () => runtime.addTaskGitToIgnore(task.id, path));
    };

    const submitCommit = () => {
        const message = commitMessage.trim();
        if (!message) {
            setError('请填写 Commit message');
            return;
        }
        const branch = task.gitContext?.branch || currentStatus?.branch || '当前分支';
        askApproval(
            amend ? '确认修改最近一次提交' : '确认提交变更',
            `${workspaceName(task.workspace)} · ${branch}\n${stageAll ? '会先暂存全部变更，再创建提交。' : '只提交当前已暂存内容。'}${signoff ? '\n将追加 Signed-off-by。' : ''}`,
            amend ? '确认 Amend' : '创建 Commit',
            async () => {
                await runtime.commitTaskGit(task.id, message, { amend, signoff, stageAll });
                setCommitMessage('');
            },
        );
    };

    const generateCommitMessage = async () => {
        setBusy('commit-message-ai');
        setError('');
        setNotice('');
        try {
            const message = await runtime.generateTaskGitCommitMessage(task.id);
            setCommitMessage(message);
            setNotice('已根据当前 Diff 生成 Commit message，请确认后再提交。');
        } catch (nextError) {
            setError(nextError instanceof Error ? nextError.message : String(nextError));
        } finally {
            setBusy(null);
        }
    };

    const push = () => {
        const branch = task.gitContext?.branch || currentStatus?.branch || '当前分支';
        askApproval(
            '确认推送到远端',
            `${workspaceName(task.workspace)} 的 ${branch} 将推送到远端。推送只影响远程仓库，不会自动创建 PR/MR。`,
            '推送分支',
            async () => { await runtime.pushTaskGit(task.id, !currentStatus?.upstream); },
            true,
            'push',
        );
    };

    const stash = () => askApproval(
        '确认收入 Stash',
        `将把 ${workspaceName(task.workspace)} 的当前变更保存到本地 Stash，工作区会恢复干净；不会推送到远端。`,
        '创建 Stash',
        async () => { await runtime.stashTaskGit(task.id, `URGS task ${task.id}`, true); },
    );

    const syncBase = () => {
        const baseRef = task.gitContext?.baseRef || 'main';
        askApproval(
            '确认同步基线',
            `将把 ${task.gitContext?.branch || '当前任务分支'} rebase 到 ${baseRef}。这会重写任务分支提交历史，冲突时会进入冲突中心。`,
            '同步基线',
            async () => {
                const result = await runtime.syncTaskGitBase(task.id, baseRef);
                if (!result.success) throw new Error(result.message);
            },
        );
    };

    const abortOperation = () => askApproval(
        '确认中止当前 Git 操作',
        '将撤销当前 Worktree 中进行中的 rebase 或 merge，并保留操作前的提交。',
        '中止操作',
        async () => {
            const result = await runtime.abortTaskGitOperation(task.id, 'rebase', true);
            if (!result.success) throw new Error(result.message);
        },
    );

    const applyWorktree = () => {
        const branch = task.gitContext?.branch || '当前 Worktree 分支';
        const target = task.sourceWorkspace || task.gitContext?.repoRoot || repoRoot;
        askApproval(
            '确认应用 Worktree',
            `将已提交的 ${branch} 合并到主工作区 ${target}。目标工作区必须干净；如果发生冲突，会停留在冲突中心等待处理。`,
            '应用到主工作区',
            async () => {
                const result = await runtime.applyTaskWorktree(task.id, target);
                if (!result.success) throw new Error(`${result.message}${result.conflictPaths.length ? ` 冲突文件：${result.conflictPaths.join('、')}` : ''}`);
            },
        );
    };

    const removeWorktree = () => askApproval(
        '确认删除 Worktree',
        `将删除任务目录 ${task.workspace}。如果其中仍有未提交变更，系统会拒绝删除；请先完成审查、提交或 Stash。`,
        '删除 Worktree',
        async () => { await runtime.removeTaskGitWorktree(task.id, false, true); setWorktreeRemoved(true); },
        false,
    );

    return <aside className="relative flex h-full min-w-[320px] max-w-[65vw] shrink-0 flex-col border-l border-slate-200 bg-[#fbfbfc] shadow-[-12px_0_30px_rgba(15,23,42,0.04)]" style={{ width: `${panelWidth}px` }} aria-label="Git 变更审查">
        <div
            role="separator"
            aria-orientation="vertical"
            aria-label="调整 Git 审查面板宽度"
            aria-valuemin={MIN_PANEL_WIDTH}
            aria-valuemax={MAX_PANEL_WIDTH}
            aria-valuenow={panelWidth}
            tabIndex={0}
            onPointerDown={handleResizePointerDown}
            onKeyDown={handleResizeKeyDown}
            onDoubleClick={() => setPanelWidth(DEFAULT_PANEL_WIDTH)}
            title="拖动调整宽度，双击恢复默认宽度"
            className={`absolute -left-1 top-0 z-20 h-full w-2 cursor-col-resize touch-none rounded-l-sm transition-colors hover:bg-indigo-200/70 focus:bg-indigo-200/70 focus:outline-none ${isResizing ? 'bg-indigo-300/80' : ''}`}
        />
        <div className="border-b border-slate-200 bg-white px-4 py-3">
            <div className="flex items-start gap-3">
                <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-indigo-50 text-indigo-600"><GitBranch size={18} /></span>
                <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2"><h2 className="truncate text-sm font-semibold text-slate-900">代码变更审查</h2>{isWorktree && <span className="rounded-full bg-indigo-50 px-1.5 py-0.5 text-[10px] font-medium text-indigo-600">Worktree</span>}</div>
                    <p className="mt-1 truncate text-[11px] text-slate-400" title={repoRoot}>{workspaceName(repoRoot)} · {isGitRepository ? (task.gitContext?.branch || currentStatus?.branch || '未连接分支') : '非 Git 工作区'}</p>
                </div>
                <button type="button" onClick={onClose} className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 hover:text-slate-700" title="关闭审查面板" aria-label="关闭审查面板"><X size={16} /></button>
            </div>
            <div className="mt-3 grid grid-cols-4 gap-1.5 text-center">
                <Stat label="文件" value={currentStatus?.files.length || 0} />
                <Stat label="新增" value={`+${currentStatus?.additions || 0}`} className="text-emerald-600" />
                <Stat label="删除" value={`-${currentStatus?.deletions || 0}`} className="text-red-600" />
                <Stat label="冲突" value={currentStatus?.conflictCount || 0} className={currentStatus?.conflictCount ? 'text-red-600' : undefined} />
            </div>
        </div>

        <div className="flex border-b border-slate-200 bg-white px-2 pt-1" role="tablist" aria-label="Git 审查标签">
            {([['review', '变更 + Diff'], ['commit', '提交'], ['worktree', 'Worktree']] as const).map(([value, label]) => <button key={value} type="button" role="tab" aria-selected={tab === value} onClick={() => setTab(value)} disabled={!isGitRepository} className={`flex-1 border-b-2 px-1 py-2 text-[11px] font-medium transition ${tab === value ? 'border-indigo-500 text-indigo-600' : 'border-transparent text-slate-400 hover:text-slate-600'} disabled:cursor-not-allowed disabled:opacity-50`}>{label}</button>)}
        </div>

        <div className="min-h-0 flex-1 flex flex-col overflow-y-auto p-3">
            {(error || notice || !isGitRepository) && <div className={`mb-3 flex items-start gap-2 rounded-xl border px-3 py-2.5 text-[11px] leading-5 ${error ? 'border-red-200 bg-red-50 text-red-700' : !isGitRepository ? 'border-amber-200 bg-amber-50 text-amber-800' : 'border-emerald-200 bg-emerald-50 text-emerald-700'}`}><span className="mt-0.5 shrink-0">{error ? <AlertTriangle size={14} /> : !isGitRepository ? <GitBranch size={14} /> : <Check size={14} />}</span><span className="min-w-0 flex-1 whitespace-pre-wrap">{error || notice || NON_GIT_REPOSITORY_NOTICE}</span><button type="button" onClick={() => { setError(''); setNotice(''); }}><X size={13} /></button></div>}

            {!isGitRepository ? <div className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-6 text-center text-[11px] leading-5 text-amber-800"><GitBranch size={22} className="mx-auto mb-2 text-amber-600" /><p className="font-medium">当前工作区不是 Git 仓库</p><p className="mt-1 text-amber-700">请在 Git 仓库目录中打开任务，代码变更审查、Diff、提交和 Worktree 功能将自动恢复。</p></div> : <>

            {tab === 'review' && <section className="flex min-h-0 flex-1 flex-col gap-2">
                <div className="flex shrink-0 items-center gap-1.5">
                    <button type="button" onClick={() => setIsFileNavOpen((current) => !current)} aria-expanded={isFileNavOpen} aria-controls="git-file-navigation" className={`flex items-center gap-1.5 rounded-lg border px-2.5 py-2 text-[11px] font-medium transition ${isFileNavOpen ? 'border-indigo-200 bg-indigo-50 text-indigo-700' : 'border-slate-200 bg-white text-slate-600 hover:bg-slate-50'}`} title={isFileNavOpen ? '关闭文件导航' : '打开文件导航'}>{isFileNavOpen ? <PanelLeftClose size={13} /> : <PanelLeftOpen size={13} />}{isFileNavOpen ? '隐藏文件导航' : '文件导航'}</button>
                    <button type="button" onClick={() => void refresh()} disabled={busy !== null} className="flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-2.5 py-2 text-[11px] font-medium text-slate-600 hover:bg-slate-50 disabled:opacity-50"><RefreshCw size={13} className={busy === 'refresh' ? 'animate-spin' : ''} />刷新</button>
                    <button type="button" onClick={stageAllChanges} disabled={isReadonly || busy !== null || files.length === 0} className="rounded-lg bg-slate-900 px-2.5 py-2 text-[11px] font-medium text-white hover:bg-slate-700 disabled:opacity-40">暂存全部</button>
                    <button type="button" onClick={() => void runSafe('fetch', () => runtime.fetchTaskGit(task.id))} disabled={isReadonly || busy !== null} className="ml-auto flex items-center gap-1 rounded-lg px-2 py-2 text-[11px] text-slate-500 hover:bg-slate-100 disabled:opacity-40">{isFetching ? <LoaderCircle size={13} className="animate-spin" /> : <Download size={13} />}{isFetching ? '正在拉取…' : `拉取 ${behindCount}`}</button>
                </div>
                {isReadonly && <div className="flex shrink-0 items-start gap-2 rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-[11px] leading-5 text-slate-500"><Eye size={14} className="mt-0.5 shrink-0" />只读分析任务只提供状态和 Diff，不允许修改仓库。</div>}
                <div className={`grid min-h-0 flex-1 ${isFileNavOpen ? 'grid-cols-[minmax(132px,36%)_minmax(0,1fr)] gap-2' : 'grid-cols-1'}`}>
                    {isFileNavOpen && <div id="git-file-navigation" className="flex min-h-0 flex-col overflow-hidden rounded-xl border border-slate-200 bg-white">
                        <div className="shrink-0 border-b border-slate-100 p-1.5">
                            <div className="flex items-center gap-1">
                                <button type="button" onClick={openAllDiff} className={`flex min-w-0 flex-1 items-center gap-2 rounded-lg px-2.5 py-2 text-left transition ${!diffPath ? 'bg-indigo-50 text-indigo-700 ring-1 ring-indigo-100' : 'text-slate-600 hover:bg-slate-50'}`} aria-current={!diffPath ? 'page' : undefined}>
                                    <FileDiff size={14} className="shrink-0" />
                                    <span className="min-w-0 flex-1 truncate text-[11px] font-semibold">全部变更</span>
                                    <span className="shrink-0 text-[10px] text-slate-400">{files.length}</span>
                                </button>
                                <button type="button" onClick={() => setIsFileNavOpen(false)} className="shrink-0 rounded-lg p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-700" aria-label="关闭文件导航" title="关闭文件导航"><PanelLeftClose size={14} /></button>
                            </div>
                            <div className="mt-1 px-2.5 text-[10px] text-slate-400">文件导航</div>
                        </div>
                        <div className="min-h-0 flex-1 overflow-y-auto p-1.5">
                            <GitFileTree
                                compact
                                files={files}
                                selectedFile={selectedFile}
                                selectedPaths={selectedFileSet}
                                onTogglePath={togglePath}
                                onSelectFile={setSelectedFile}
                                onOpenDiff={openDiff}
                                onOpenFile={openFile}
                                onOpenHeadFile={openHeadFile}
                                onDiscardFile={discardFile}
                                onStageFile={stageFile}
                                onAddToGitignore={addToGitignore}
                                onRevealInFinder={revealInFinder}
                                readonly={isReadonly}
                            />
                        </div>
                        {files.length > 0 && <div className="flex shrink-0 flex-wrap items-center gap-1 border-t border-slate-100 p-1.5"><span className="mr-auto w-full truncate px-1 text-[10px] text-slate-400">已选 {selectedPaths.length || (selectedFile ? 1 : 0)} 个文件</span><button type="button" onClick={stageSelected} disabled={isReadonly || busy !== null || !pathsForAction.length} className="rounded-lg border border-slate-200 bg-white px-2 py-1.5 text-[10px] text-slate-600 hover:bg-slate-50 disabled:opacity-40">暂存</button><button type="button" onClick={unstageSelected} disabled={isReadonly || busy !== null || !pathsForAction.length} className="rounded-lg border border-slate-200 bg-white px-2 py-1.5 text-[10px] text-slate-600 hover:bg-slate-50 disabled:opacity-40">取消暂存</button><button type="button" onClick={discardSelected} disabled={isReadonly || busy !== null || !pathsForAction.length} className="rounded-lg border border-red-200 bg-white px-2 py-1.5 text-[10px] text-red-600 hover:bg-red-50 disabled:opacity-40">丢弃</button></div>}
                    </div>}
                    <div className="min-h-0 overflow-y-auto rounded-xl border border-slate-200 bg-[#fbfbfc] p-2">
                        {diff?.patch ? <GitDiffViewer
                            patch={diff.patch}
                            filePath={diffPath || '当前工作区'}
                            truncated={diff.truncated}
                            summary={{
                                title: diffPath || '全部变更',
                                subtitle: diffPath ? '当前文件的变更 · 可从左侧切换文件' : '按文件连续展示当前工作区的完整 Diff',
                                fileCount: diffPath ? 1 : files.length,
                                additions: diffPath ? (files.find((file) => file.path === diffPath)?.additions || 0) : (currentStatus?.additions || 0),
                                deletions: diffPath ? (files.find((file) => file.path === diffPath)?.deletions || 0) : (currentStatus?.deletions || 0),
                                staged: showStagedDiff,
                                onStagedChange: setShowStagedDiff,
                            }}
                        /> : <EmptyState text={busy === 'diff' ? '正在读取 Diff…' : '当前工作区没有可展示的 Diff'} />}
                    </div>
                </div>
            </section>}

            {tab === 'commit' && <section className="space-y-3">
                <div className="rounded-xl border border-slate-200 bg-white p-3"><div className="flex items-center gap-2 text-xs font-semibold text-slate-700"><GitCommitHorizontal size={15} className="text-indigo-600" />提交前检查</div><p className="mt-2 text-[11px] leading-5 text-slate-500">{currentStatus?.stagedCount || 0} 个已暂存文件，{currentStatus?.modifiedCount || 0} 个工作区修改，{currentStatus?.untrackedCount || 0} 个未跟踪文件。</p>{remotes.length > 0 ? <div className="mt-3 space-y-1.5 border-t border-slate-100 pt-3">{remotes.map((remote) => <div key={remote.name} className="rounded-lg bg-slate-50 px-2.5 py-2"><div className="flex items-center gap-2 text-[10px]"><span className="rounded-full bg-indigo-50 px-1.5 py-0.5 font-medium text-indigo-700">{remote.provider}</span><span className="font-medium text-slate-700">{remote.name}</span><span className="text-slate-400">{remote.host || '本地/自定义远端'}</span><span className="ml-auto text-slate-400">{remote.capabilities.join(' · ')}</span></div><p className="mt-1 truncate font-mono text-[10px] text-slate-500" title={remote.repository || remote.fetchUrl || remote.pushUrl || undefined}>{remote.repository || remote.fetchUrl || remote.pushUrl}</p>{remote.webUrl && <p className="mt-1 truncate text-[10px] text-slate-400">Web：{remote.webUrl}</p>}</div>)}</div> : <p className="mt-2 text-[10px] text-slate-400">未配置远端；Fetch/Push/Provider 操作不可用。</p>}<p className="mt-3 border-t border-slate-100 pt-3 text-[10px] leading-4 text-slate-400">当前 Provider 适配器只负责识别远端并提供 Git Fetch/Push 能力；PR/MR 不会被伪装成原生 Git 操作，后续需接入对应 Provider API。</p></div>
                <div className="rounded-xl border border-slate-200 bg-white p-3"><div className="mb-2 flex items-center justify-between gap-2"><label htmlFor="git-commit-message" className="text-xs font-semibold text-slate-700">Commit message</label><button type="button" onClick={() => void generateCommitMessage()} disabled={isReadonly || busy !== null || files.length === 0} className="flex h-7 w-7 items-center justify-center rounded-lg border border-indigo-100 bg-indigo-50 text-indigo-600 hover:bg-indigo-100 disabled:opacity-40" title="根据当前 Diff 生成 Commit message" aria-label="根据当前 Diff 生成 Commit message">{busy === 'commit-message-ai' ? <LoaderCircle size={14} className="animate-spin" /> : <Sparkles size={14} />}</button></div><textarea id="git-commit-message" value={commitMessage} onChange={(event) => setCommitMessage(event.target.value)} rows={4} placeholder="Commit message" className="w-full resize-y rounded-lg border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-800 outline-none focus:border-indigo-300 focus:ring-2 focus:ring-indigo-100" /></div>
                <div className="space-y-2 rounded-xl border border-slate-200 bg-white p-3 text-[11px] text-slate-600"><label className="flex items-center gap-2"><input type="checkbox" checked={stageAll} onChange={(event) => setStageAll(event.target.checked)} />提交前暂存全部变更</label><label className="flex items-center gap-2"><input type="checkbox" checked={amend} onChange={(event) => setAmend(event.target.checked)} />修改最近一次提交（Amend）</label><label className="flex items-center gap-2"><input type="checkbox" checked={signoff} onChange={(event) => setSignoff(event.target.checked)} />追加 Signed-off-by</label></div>
                <button type="button" onClick={submitCommit} disabled={isReadonly || busy !== null || !commitMessage.trim()} className="flex w-full items-center justify-center gap-2 rounded-xl bg-slate-900 px-3 py-2.5 text-xs font-medium text-white hover:bg-slate-700 disabled:opacity-40"><GitCommitHorizontal size={14} />创建提交</button>
                <div className="flex gap-2"><button type="button" onClick={() => void runSafe('fetch', () => runtime.fetchTaskGit(task.id))} disabled={isReadonly || busy !== null} className="flex flex-1 items-center justify-center gap-1.5 rounded-lg border border-slate-200 bg-white px-2.5 py-2 text-[11px] text-slate-600 hover:bg-slate-50 disabled:opacity-40" aria-label={isFetching ? '正在拉取' : `拉取 ${behindCount} 个提交`}>{isFetching ? <LoaderCircle size={13} className="animate-spin" /> : <Download size={13} />}{isFetching ? '正在拉取…' : `拉取 ${behindCount}`}</button><button type="button" onClick={push} disabled={isReadonly || busy !== null || !currentStatus?.headCommit} className="flex flex-1 items-center justify-center gap-1.5 rounded-lg border border-indigo-200 bg-indigo-50 text-[11px] text-indigo-700 hover:bg-indigo-100 disabled:opacity-40" aria-label={isPushing ? '正在推送' : `推送 ${aheadCount} 个提交`}>{isPushing ? <LoaderCircle size={13} className="animate-spin" /> : <Upload size={13} />}{isPushing ? '正在推送…' : `推送 ${aheadCount}`}</button></div>
                <button type="button" onClick={stash} disabled={isReadonly || busy !== null || !currentStatus?.isDirty} className="flex w-full items-center justify-center gap-1.5 rounded-lg border border-slate-200 bg-white px-2.5 py-2 text-[11px] text-slate-600 hover:bg-slate-50 disabled:opacity-40"><Archive size={13} />Stash 当前变更</button>
                <div className="rounded-xl border border-amber-200 bg-amber-50 px-3 py-2.5 text-[11px] leading-5 text-amber-800"><ShieldCheck size={13} className="mr-1 inline" />提交、推送和丢弃都会弹出明确审批，并记录操作者、任务、分支和目标路径。</div>
            </section>}

            {tab === 'worktree' && <section className="space-y-3">
                <div className="rounded-xl border border-slate-200 bg-white p-3"><div className="flex items-center gap-2 text-xs font-semibold text-slate-700"><GitMerge size={15} className="text-indigo-600" />任务 Worktree</div><dl className="mt-3 space-y-2 text-[11px]"><Row label="实际目录" value={task.workspace} /><Row label="源仓库" value={repoRoot} /><Row label="分支" value={task.gitContext?.branch || currentStatus?.branch || '—'} /><Row label="基准" value={task.gitContext?.baseRef || '—'} /><Row label="提交" value={currentStatus?.headCommit?.slice(0, 12) || '—'} /></dl></div>
                {currentStatus?.conflictCount ? <div className="rounded-xl border border-red-200 bg-red-50 p-3"><div className="flex items-center gap-2 text-xs font-semibold text-red-700"><AlertTriangle size={14} />冲突中心</div><p className="mt-1 text-[11px] leading-5 text-red-700">当前有 {currentStatus.conflictCount} 个冲突文件。请在编辑器中解决后暂存并提交，或中止当前操作。</p><div className="mt-2 space-y-1">{currentStatus.files.filter((file) => file.conflicted).map((file) => <div key={file.path} className="truncate font-mono text-[10px] text-red-700">{file.path}</div>)}</div><button type="button" onClick={abortOperation} disabled={busy !== null} className="mt-3 rounded-lg border border-red-200 bg-white px-2.5 py-1.5 text-[11px] font-medium text-red-700 hover:bg-red-100 disabled:opacity-40">中止当前操作</button></div> : null}
                {worktreeRemoved ? <div className="rounded-xl border border-emerald-200 bg-emerald-50 px-3 py-2.5 text-[11px] leading-5 text-emerald-700">此任务 Worktree 已清理，源仓库仍然保留。若要继续修改，请新建任务并重新选择隔离模式。</div> : isWorktree ? <><button type="button" onClick={syncBase} disabled={isReadonly || busy !== null || Boolean(currentStatus?.isDirty)} className="flex w-full items-center justify-center gap-2 rounded-xl border border-indigo-200 bg-white px-3 py-2.5 text-xs font-medium text-indigo-700 hover:bg-indigo-50 disabled:opacity-40"><RefreshCw size={14} />{currentStatus?.isDirty ? '先提交或 Stash 后同步' : '同步基线'}</button><button type="button" onClick={applyWorktree} disabled={isReadonly || busy !== null || Boolean(currentStatus?.isDirty) || Boolean(currentStatus?.conflictCount)} className="flex w-full items-center justify-center gap-2 rounded-xl bg-indigo-600 px-3 py-2.5 text-xs font-medium text-white hover:bg-indigo-700 disabled:opacity-40"><GitMerge size={14} />{currentStatus?.isDirty ? '先提交或 Stash 后应用' : '应用到主工作区'}</button><button type="button" onClick={removeWorktree} disabled={busy !== null || Boolean(currentStatus?.isDirty) || Boolean(currentStatus?.conflictCount)} className="flex w-full items-center justify-center gap-2 rounded-xl border border-red-200 bg-white px-3 py-2.5 text-xs font-medium text-red-600 hover:bg-red-50 disabled:opacity-40"><Trash2 size={14} />清理此 Worktree</button></> : isReadonly ? <><div className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-[11px] leading-5 text-slate-500">只读分析运行在独立的 Git 快照目录中，智能体或审查操作不会回写源仓库；完成后可以清理快照。</div><button type="button" onClick={removeWorktree} disabled={busy !== null || Boolean(currentStatus?.isDirty) || Boolean(currentStatus?.conflictCount)} className="flex w-full items-center justify-center gap-2 rounded-xl border border-red-200 bg-white px-3 py-2.5 text-xs font-medium text-red-600 hover:bg-red-50 disabled:opacity-40"><Trash2 size={14} />清理只读快照</button></> : <div className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-[11px] leading-5 text-slate-500">当前任务使用当前工作区，没有可应用的独立 Worktree。</div>}
                <div className="rounded-xl border border-slate-200 bg-white p-3"><div className="flex items-center justify-between gap-2"><span className="text-xs font-semibold text-slate-700">仓库 Worktree 列表</span><button type="button" onClick={gcWorktrees} disabled={busy !== null} className="flex items-center gap-1 text-[10px] text-slate-400 hover:text-slate-600"><RefreshCw size={11} />清理记录</button></div><div className="mt-2 space-y-1.5">{worktrees.map((item) => <div key={item.path} className="rounded-lg bg-slate-50 px-2.5 py-2"><div className="flex items-center gap-2"><GitBranch size={12} className="shrink-0 text-slate-400" /><span className="min-w-0 flex-1 truncate font-mono text-[10px] text-slate-600" title={item.path}>{workspaceName(item.path)}</span>{item.branch && <span className="max-w-32 truncate text-[10px] text-indigo-600">{item.branch}</span>}</div><p className="mt-1 truncate pl-[20px] text-[9px] text-slate-400" title={item.path}>{item.path}</p></div>)}{worktrees.length === 0 && <p className="text-[10px] text-slate-400">未读取到 Worktree。</p>}</div></div>
                {auditEntries.length > 0 && <details className="rounded-xl border border-slate-200 bg-white p-3"><summary className="cursor-pointer text-xs font-semibold text-slate-700">最近审计记录（{auditEntries.length}）</summary><div className="mt-2 space-y-1.5">{auditEntries.slice(0, 8).map((entry) => <div key={entry.id} className="rounded-lg bg-slate-50 px-2.5 py-2 text-[10px]"><div className="flex items-center gap-2"><span className={`font-medium ${entry.success ? 'text-emerald-600' : 'text-red-600'}`}>{entry.operation}</span><span className="ml-auto text-slate-400">{new Date(entry.createdAt).toLocaleString('zh-CN')}</span></div><p className="mt-1 leading-4 text-slate-500">{entry.summary}</p></div>)}</div></details>}
            </section>}
            </>}
        </div>

        {confirmation && <div className="fixed inset-0 z-[1300] flex items-center justify-center bg-slate-950/35 p-4 backdrop-blur-sm" role="dialog" aria-modal="true" aria-labelledby="git-approval-title"><div className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-5 shadow-2xl"><div className="flex items-start gap-3"><span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-amber-50 text-amber-700"><ShieldCheck size={17} /></span><div className="min-w-0 flex-1"><h2 id="git-approval-title" className="text-sm font-semibold text-slate-900">{confirmation.title}</h2><p className="mt-2 whitespace-pre-wrap text-[12px] leading-5 text-slate-600">{confirmation.body}</p></div></div><div className="mt-5 flex justify-end gap-2"><button type="button" onClick={() => setConfirmation(null)} className="rounded-lg border border-slate-200 px-3 py-2 text-xs text-slate-600 hover:bg-slate-50">取消</button><button type="button" onClick={() => void confirmAction()} className="rounded-lg bg-slate-900 px-3 py-2 text-xs font-medium text-white hover:bg-slate-700">{confirmation.confirmLabel}</button></div></div></div>}
    </aside>;
};

const Stat: React.FC<{ label: string; value: number | string; className?: string }> = ({ label, value, className = 'text-slate-700' }) => <div className="rounded-lg bg-slate-50 px-1.5 py-1.5"><div className={`text-[12px] font-semibold ${className}`}>{value}</div><div className="mt-0.5 text-[9px] text-slate-400">{label}</div></div>;
const Row: React.FC<{ label: string; value: string }> = ({ label, value }) => <div className="flex gap-3"><dt className="w-12 shrink-0 text-slate-400">{label}</dt><dd className="min-w-0 flex-1 truncate font-mono text-slate-600" title={value}>{value}</dd></div>;
const EmptyState: React.FC<{ text: string }> = ({ text }) => <div className="flex min-h-32 items-center justify-center rounded-xl border border-dashed border-slate-200 bg-white px-4 text-center text-[11px] text-slate-400"><Archive size={15} className="mr-2" />{text}</div>;

export default GitReviewPanel;
