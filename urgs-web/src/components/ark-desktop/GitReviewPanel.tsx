import React, { useCallback, useEffect, useRef, useState } from 'react';
import { AlertCircle, ChevronRight, FileCode2, GitBranch, LoaderCircle, Maximize2, Minimize2, PanelLeftClose, PanelLeftOpen, RefreshCw, X } from 'lucide-react';
import type { GrokGitDiff, GrokGitFile, GrokGitStatus } from '@/services/grokDesktop';
import type { ArkDesktopTask } from './types';
import type { ArkDesktopRuntime } from './useArkDesktopRuntime';
import GitDiffViewer from './GitDiffViewer';
import GitOperationsPanel from './GitOperationsPanel';
import { gitReviewCacheFor, gitStatusSignature, normalizeGitWorkspaceKey } from './gitReviewCache';

interface GitReviewPanelProps {
    task: ArkDesktopTask;
    runtime: ArkDesktopRuntime;
    onClose: () => void;
    visible: boolean;
}

const STATUS_REFRESH_INTERVAL_MS = 30_000;
const DEFAULT_PANEL_WIDTH = 620;
const MIN_PANEL_WIDTH = 440;
const MAX_PANEL_WIDTH = 840;
const PANEL_WIDTH_STORAGE_KEY = 'urgs_git_review_panel_width_v2';
const FILE_LIST_VISIBLE_STORAGE_KEY = 'urgs_git_review_file_list_visible';

const readFileListVisible = () => {
    if (typeof window === 'undefined') return true;
    return localStorage.getItem(FILE_LIST_VISIBLE_STORAGE_KEY) !== '0';
};

const workspaceName = (value: string) => value.split(/[\\/]/).filter(Boolean).pop() || value;

const clampPanelWidth = (value: number) => {
    const viewportMax = typeof window === 'undefined' ? MAX_PANEL_WIDTH : Math.floor(window.innerWidth * 0.72);
    return Math.min(Math.max(MIN_PANEL_WIDTH, value), Math.max(MIN_PANEL_WIDTH, Math.min(MAX_PANEL_WIDTH, viewportMax)));
};

const readPanelWidth = () => {
    if (typeof window === 'undefined') return DEFAULT_PANEL_WIDTH;
    const stored = Number(localStorage.getItem(PANEL_WIDTH_STORAGE_KEY));
    return Number.isFinite(stored) && stored > 0 ? clampPanelWidth(stored) : DEFAULT_PANEL_WIDTH;
};

const isNonGitRepositoryError = (message: string) => {
    const normalized = message.toLowerCase();
    return normalized.includes('not a git repository')
        || normalized.includes('无法启动 git')
        || normalized.includes('program not found')
        || normalized.includes('executable file not found')
        || normalized.includes('os error 2')
        || /不是(?:一个)?\s*git\s*仓库/.test(message);
};

const fileStatus = (file: GrokGitFile) => {
    if (file.conflicted) return { label: '冲突', className: 'bg-red-50 text-red-700' };
    if (file.untracked) return { label: '新增', className: 'bg-amber-50 text-amber-700' };
    if (file.staged && file.modified) return { label: '已暂存 · 又修改', className: 'bg-indigo-50 text-indigo-700' };
    if (file.staged) return { label: '已暂存', className: 'bg-emerald-50 text-emerald-700' };
    return { label: '已修改', className: 'bg-slate-100 text-slate-600' };
};

const formatRefreshTime = (timestamp?: number) => {
    if (!timestamp) return '尚未刷新';
    return new Intl.DateTimeFormat('zh-CN', { hour: '2-digit', minute: '2-digit', second: '2-digit' }).format(timestamp);
};

const GitReviewPanel: React.FC<GitReviewPanelProps> = ({ task, runtime, onClose, visible }) => {
    const workspace = task.workspace.trim();
    const workspaceKey = normalizeGitWorkspaceKey(workspace);
    const initialCache = gitReviewCacheFor(workspaceKey);
    const persistedStatus = task.gitContext?.status as GrokGitStatus | undefined;
    const [status, setStatus] = useState<GrokGitStatus | undefined>(initialCache.status || persistedStatus);
    const [selectedPath, setSelectedPath] = useState(initialCache.selectedPath || initialCache.status?.files[0]?.path || persistedStatus?.files[0]?.path || '');
    const [diff, setDiff] = useState<GrokGitDiff | null>(() => initialCache.selectedPath ? initialCache.diffs.get(initialCache.selectedPath) || null : null);
    const [statusLoading, setStatusLoading] = useState(!initialCache.status && !persistedStatus);
    const [diffLoading, setDiffLoading] = useState(false);
    const [error, setError] = useState('');
    const [activeView, setActiveView] = useState<'diff' | 'operations'>('diff');
    const [panelWidth, setPanelWidth] = useState(readPanelWidth);
    const [expanded, setExpanded] = useState(false);
    const [fileListVisible, setFileListVisible] = useState(readFileListVisible);
    const resizeStartRef = useRef<{ x: number; width: number } | null>(null);
    const statusRequestRef = useRef<Promise<GrokGitStatus> | null>(null);
    const diffRequestIdRef = useRef(0);
    const selectedPathRef = useRef(selectedPath);
    selectedPathRef.current = selectedPath;

    const { refreshTaskGitStatus, loadTaskGitDiff } = runtime;
    const files = status?.files || [];
    const selectedFile = files.find((file) => file.path === selectedPath);
    const isRepository = status?.isRepository !== false;
    const isClean = Boolean(status && files.length === 0);

    const applyStatus = useCallback((nextStatus: GrokGitStatus, options: { clearDiffs?: boolean; clearBranches?: boolean } = {}) => {
        const cache = gitReviewCacheFor(workspaceKey);
        const nextSignature = gitStatusSignature(nextStatus);
        if (options.clearDiffs || cache.statusSignature && cache.statusSignature !== nextSignature) cache.diffs.clear();
        if (options.clearBranches) {
            cache.branches = undefined;
            cache.branchesUpdatedAt = undefined;
        }
        cache.status = nextStatus;
        cache.statusSignature = nextSignature;
        cache.updatedAt = Date.now();
        const nextSelectedPath = cache.selectedPath && nextStatus.files.some((file) => file.path === cache.selectedPath)
            ? cache.selectedPath
            : nextStatus.files[0]?.path || '';
        cache.selectedPath = nextSelectedPath;
        setStatus(nextStatus);
        setSelectedPath(nextSelectedPath);
        setDiff(nextSelectedPath ? cache.diffs.get(nextSelectedPath) || null : null);
    }, [workspaceKey]);

    const refreshStatus = useCallback(async (foreground = false) => {
        if (!workspace || statusRequestRef.current) return statusRequestRef.current;
        if (foreground || !gitReviewCacheFor(workspaceKey).status) setStatusLoading(true);
        setError('');
        const request = refreshTaskGitStatus(task.id, false);
        statusRequestRef.current = request;
        try {
            const nextStatus = await request;
            applyStatus(nextStatus);
            return nextStatus;
        } catch (cause) {
            const message = cause instanceof Error ? cause.message : String(cause);
            setError(isNonGitRepositoryError(message) ? '当前文件夹不是 Git 仓库。' : message);
            throw cause;
        } finally {
            if (statusRequestRef.current === request) statusRequestRef.current = null;
            setStatusLoading(false);
        }
    }, [applyStatus, refreshTaskGitStatus, task.id, workspace, workspaceKey]);

    const loadDiff = useCallback(async (path: string, force = false) => {
        if (!path) {
            setDiff(null);
            return;
        }
        const cache = gitReviewCacheFor(workspaceKey);
        cache.selectedPath = path;
        setSelectedPath(path);
        const cached = cache.diffs.get(path);
        if (cached && !force) {
            setDiff(cached);
            return;
        }
        const requestId = diffRequestIdRef.current + 1;
        diffRequestIdRef.current = requestId;
        setDiffLoading(true);
        setError('');
        try {
            let nextDiff = await loadTaskGitDiff(task.id, path, false);
            if (!nextDiff.patch.trim() && selectedFile?.staged) {
                nextDiff = await loadTaskGitDiff(task.id, path, true);
            }
            if (diffRequestIdRef.current !== requestId) return;
            cache.diffs.set(path, nextDiff);
            setDiff(nextDiff);
        } catch (cause) {
            if (diffRequestIdRef.current === requestId) setError(cause instanceof Error ? cause.message : String(cause));
        } finally {
            if (diffRequestIdRef.current === requestId) setDiffLoading(false);
        }
    }, [loadTaskGitDiff, selectedFile?.staged, task.id, workspaceKey]);

    useEffect(() => {
        const cache = gitReviewCacheFor(workspaceKey);
        const nextStatus = cache.status || persistedStatus;
        const nextPath = cache.selectedPath && nextStatus?.files.some((file) => file.path === cache.selectedPath)
            ? cache.selectedPath
            : nextStatus?.files[0]?.path || '';
        setStatus(nextStatus);
        setSelectedPath(nextPath);
        setDiff(nextPath ? cache.diffs.get(nextPath) || null : null);
        setError('');
        setActiveView('diff');
        setStatusLoading(!nextStatus);
        diffRequestIdRef.current += 1;
    }, [task.id, workspaceKey]);

    useEffect(() => {
        if (!visible || !workspace) return undefined;
        const refreshVisibleData = async () => {
            const nextStatus = await refreshStatus(false);
            if (activeView !== 'diff') return;
            const path = nextStatus?.files.some((file) => file.path === selectedPathRef.current)
                ? selectedPathRef.current
                : nextStatus?.files[0]?.path || '';
            if (path) await loadDiff(path, true);
        };
        const cache = gitReviewCacheFor(workspaceKey);
        const cacheIsFresh = Boolean(cache.status && cache.updatedAt && Date.now() - cache.updatedAt < STATUS_REFRESH_INTERVAL_MS);
        if (!cacheIsFresh) void refreshVisibleData().catch(() => undefined);
        const timer = window.setInterval(() => {
            if (document.visibilityState === 'visible') void refreshVisibleData().catch(() => undefined);
        }, STATUS_REFRESH_INTERVAL_MS);
        return () => window.clearInterval(timer);
    }, [activeView, loadDiff, refreshStatus, visible, workspace, workspaceKey]);

    useEffect(() => {
        if (!visible || activeView !== 'diff' || !selectedPath || !isRepository) return;
        void loadDiff(selectedPath);
    }, [activeView, isRepository, loadDiff, selectedPath, visible]);

    useEffect(() => {
        localStorage.setItem(PANEL_WIDTH_STORAGE_KEY, String(panelWidth));
    }, [panelWidth]);

    useEffect(() => {
        localStorage.setItem(FILE_LIST_VISIBLE_STORAGE_KEY, fileListVisible ? '1' : '0');
    }, [fileListVisible]);

    useEffect(() => {
        const move = (event: PointerEvent) => {
            if (!resizeStartRef.current) return;
            setPanelWidth(clampPanelWidth(resizeStartRef.current.width - (event.clientX - resizeStartRef.current.x)));
        };
        const stop = () => { resizeStartRef.current = null; };
        window.addEventListener('pointermove', move);
        window.addEventListener('pointerup', stop);
        window.addEventListener('pointercancel', stop);
        return () => {
            window.removeEventListener('pointermove', move);
            window.removeEventListener('pointerup', stop);
            window.removeEventListener('pointercancel', stop);
        };
    }, []);

    const refreshAll = async () => {
        try {
            const nextStatus = await refreshStatus(true);
            if (activeView !== 'diff') return;
            const path = nextStatus?.files.some((file) => file.path === selectedPathRef.current)
                ? selectedPathRef.current
                : nextStatus?.files[0]?.path || '';
            if (path) await loadDiff(path, true);
        } catch {
            // refreshStatus 已将错误绑定到面板。
        }
    };

    const updatedAt = gitReviewCacheFor(workspaceKey).updatedAt;
    const repositoryTitle = status?.repoRoot ? workspaceName(status.repoRoot) : workspaceName(workspace);

    return <aside
        aria-hidden={!visible}
        className={`absolute flex min-h-0 flex-col bg-white shadow-[-16px_0_36px_rgba(15,23,42,0.08)] transition-transform duration-200 ${expanded
            ? 'inset-0 z-50 w-full max-w-none'
            : 'inset-y-0 right-0 z-40 max-w-[72%] border-l border-slate-200'} ${visible ? 'translate-x-0' : 'pointer-events-none translate-x-full'}`}
        style={{ width: expanded ? undefined : panelWidth }}
    >
        {!expanded && <div role="separator" aria-label="调整代码变更审查面板宽度" aria-orientation="vertical" tabIndex={0} onPointerDown={(event) => { resizeStartRef.current = { x: event.clientX, width: panelWidth }; }} className="absolute inset-y-0 left-0 z-10 w-1.5 -translate-x-1/2 cursor-col-resize focus-visible:bg-indigo-300" />}

        <header className="flex shrink-0 items-center gap-3 border-b border-slate-200 px-5 py-4">
            <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-indigo-50 text-indigo-600"><GitBranch size={20} /></span>
            <div className="min-w-0 flex-1">
                <h2 className="truncate text-[17px] font-semibold tracking-[-0.02em] text-slate-900">代码变更</h2>
                <p className="mt-0.5 truncate text-xs text-slate-500" title={workspace}>{repositoryTitle} · {status?.branch || '正在读取分支'}</p>
            </div>
            <button type="button" disabled={statusLoading} onClick={() => void refreshAll()} className="flex h-9 items-center gap-1.5 rounded-lg px-2.5 text-xs font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-700 disabled:opacity-40"><RefreshCw size={14} className={statusLoading ? 'animate-spin' : ''} />刷新</button>
            <button type="button" onClick={() => setExpanded((current) => !current)} className="flex h-9 w-9 items-center justify-center rounded-lg text-slate-400 transition hover:bg-slate-100 hover:text-slate-700" title={expanded ? '退出全屏' : '全屏覆盖对话窗口'} aria-label={expanded ? '退出全屏' : '全屏覆盖对话窗口'} aria-pressed={expanded}>{expanded ? <Minimize2 size={16} /> : <Maximize2 size={16} />}</button>
            <button type="button" disabled={activeView !== 'diff'} onClick={() => setFileListVisible((current) => !current)} className="flex h-9 w-9 items-center justify-center rounded-lg text-slate-400 transition hover:bg-slate-100 hover:text-slate-700 disabled:cursor-not-allowed disabled:opacity-40 disabled:hover:bg-transparent" title={fileListVisible ? '隐藏变更文件栏' : '显示变更文件栏'} aria-label={fileListVisible ? '隐藏变更文件栏' : '显示变更文件栏'} aria-pressed={fileListVisible}>{fileListVisible ? <PanelLeftClose size={16} /> : <PanelLeftOpen size={16} />}</button>
            <button type="button" onClick={onClose} className="flex h-9 w-9 items-center justify-center rounded-lg text-slate-400 hover:bg-slate-100 hover:text-slate-700" aria-label="关闭代码变更"><X size={18} /></button>
        </header>

        <div className="flex shrink-0 items-center gap-3 border-b border-slate-100 px-5 py-2.5 text-[11px] text-slate-500">
            <span>{files.length} 个变更文件</span>
            {status && <><span>{status.stagedCount} 已暂存</span><span>{status.untrackedCount} 新增</span><span>{status.conflictCount} 冲突</span></>}
            <span className="ml-auto">更新于 {formatRefreshTime(updatedAt)} · 每 30 秒检查状态</span>
        </div>

        {error && <div className="mx-5 mt-3 flex shrink-0 items-start gap-2 rounded-xl bg-red-50 px-3 py-2.5 text-xs leading-5 text-red-700"><AlertCircle size={15} className="mt-0.5 shrink-0" /><span className="min-w-0 flex-1 break-words">{error}</span></div>}

        <div className="flex shrink-0 border-b border-slate-200 px-5" role="tablist" aria-label="代码变更视图">
            <button type="button" role="tab" aria-selected={activeView === 'diff'} onClick={() => setActiveView('diff')} className={`h-10 border-b-2 px-3 text-xs font-semibold transition ${activeView === 'diff' ? 'border-indigo-600 text-indigo-600' : 'border-transparent text-slate-500 hover:text-slate-700'}`}>Diff</button>
            <button type="button" role="tab" aria-selected={activeView === 'operations'} onClick={() => setActiveView('operations')} className={`h-10 border-b-2 px-3 text-xs font-semibold transition ${activeView === 'operations' ? 'border-indigo-600 text-indigo-600' : 'border-transparent text-slate-500 hover:text-slate-700'}`}>Git 操作</button>
        </div>

        {activeView === 'diff' ? <div className={`grid min-h-0 flex-1 ${fileListVisible ? (expanded ? 'grid-cols-[minmax(200px,28%)_minmax(0,1fr)]' : 'grid-cols-[minmax(180px,34%)_minmax(0,1fr)]') : 'grid-cols-1'}`}>
            {fileListVisible && <nav className="min-h-0 overflow-y-auto border-r border-slate-100 bg-slate-50/60 p-2" aria-label="变更文件">
                {statusLoading && !status ? <div className="flex h-28 items-center justify-center gap-2 text-xs text-slate-400"><LoaderCircle size={15} className="animate-spin" />正在检查工作区</div>
                    : !isRepository ? <div className="px-3 py-8 text-center text-xs leading-5 text-slate-400">当前文件夹不是 Git 仓库</div>
                        : isClean ? <div className="px-3 py-8 text-center text-xs leading-5 text-slate-400">当前文件夹没有未提交变更</div>
                            : files.map((file) => {
                                const presentation = fileStatus(file);
                                const selected = selectedPath === file.path;
                                return <button key={file.path} type="button" onClick={() => void loadDiff(file.path)} className={`mb-1 w-full rounded-xl px-3 py-2.5 text-left transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-300 ${selected ? 'bg-white shadow-sm ring-1 ring-slate-200' : 'hover:bg-white/80'}`}>
                                    <span className="flex items-start gap-2"><FileCode2 size={14} className={`mt-0.5 shrink-0 ${selected ? 'text-indigo-600' : 'text-slate-400'}`} /><span className="min-w-0 flex-1"><span className="block truncate text-xs font-medium text-slate-700" title={file.path}>{file.path}</span><span className="mt-1 flex items-center gap-2"><span className={`rounded-md px-1.5 py-0.5 text-[9px] font-medium ${presentation.className}`}>{presentation.label}</span>{file.additions > 0 && <span className="text-[10px] text-emerald-600">+{file.additions}</span>}{file.deletions > 0 && <span className="text-[10px] text-red-500">-{file.deletions}</span>}</span></span><ChevronRight size={13} className={`mt-0.5 shrink-0 ${selected ? 'text-indigo-500' : 'text-slate-300'}`} /></span>
                                </button>;
                            })}
            </nav>}

            <section className="min-h-0 overflow-y-auto bg-[#181818] p-2">
                {diffLoading ? <div className="flex h-40 items-center justify-center gap-2 text-xs text-slate-400"><LoaderCircle size={15} className="animate-spin" />正在读取 {selectedPath}</div>
                    : diff?.patch.trim() ? <GitDiffViewer patch={diff.patch} filePath={selectedPath} truncated={diff.truncated} />
                        : selectedFile ? <div className="flex h-40 items-center justify-center px-6 text-center text-xs leading-5 text-slate-400">该文件没有可显示的文本 Diff，可能是二进制文件、空文件或仅包含 Git 元数据变更。</div>
                            : <div className="flex h-40 items-center justify-center text-xs text-slate-500">从左侧选择变更文件</div>}
            </section>
        </div> : <GitOperationsPanel task={task} runtime={runtime} status={status} workspaceKey={workspaceKey} onStatusChange={applyStatus} />}
    </aside>;
};

export default GitReviewPanel;
