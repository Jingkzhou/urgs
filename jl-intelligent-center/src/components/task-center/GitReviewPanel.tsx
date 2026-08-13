import React, { useCallback, useEffect, useRef, useState } from 'react';
import { AlertCircle, ChevronRight, FileCode2, GitBranch, LoaderCircle, Maximize2, Minimize2, PanelLeftClose, PanelLeftOpen, RefreshCw, X } from 'lucide-react';
import { describeDesktopError, watchGrokGitWorkspace, writeDesktopLog, type GrokGitDiff, type GrokGitFile, type GrokGitStatus, type GrokGitWorkspaceChangedEvent } from '@/services/grokDesktop';
import type { ArkDesktopTask } from './types';
import type { ArkDesktopRuntime } from './useArkDesktopRuntime';
import GitDiffViewer from './GitDiffViewer';
import GitOperationsPanel from './GitOperationsPanel';
import { cacheGitDiffSnapshot, gitReviewCacheFor, gitStatusSignature, invalidateGitDiffPaths, normalizeGitWorkspaceKey } from './gitReviewCache';

interface GitReviewPanelProps {
    task: ArkDesktopTask | null;
    workspace: string;
    runtime: ArkDesktopRuntime;
    onClose: () => void;
    visible: boolean;
}

const DEFAULT_PANEL_WIDTH = 620;
const MIN_PANEL_WIDTH = 440;
const MAX_PANEL_WIDTH = 840;
const PANEL_WIDTH_STORAGE_KEY = 'urgs_git_review_panel_width_v2';
const FILE_LIST_VISIBLE_STORAGE_KEY = 'urgs_git_review_file_list_visible';
const FILE_LIST_WIDTH_PCT_STORAGE_KEY = 'urgs_git_review_file_list_width_pct';
const FILE_LIST_MIN_PCT = 20;
const FILE_LIST_MAX_PCT = 55;

const readFileListVisible = () => {
    if (typeof window === 'undefined') return true;
    return localStorage.getItem(FILE_LIST_VISIBLE_STORAGE_KEY) !== '0';
};

const readFileListPct = () => {
    if (typeof window === 'undefined') return undefined;
    const stored = Number(localStorage.getItem(FILE_LIST_WIDTH_PCT_STORAGE_KEY));
    return Number.isFinite(stored) && stored > 0 ? Math.min(Math.max(stored, FILE_LIST_MIN_PCT), FILE_LIST_MAX_PCT) : undefined;
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

const GitReviewPanel: React.FC<GitReviewPanelProps> = ({ task, workspace: workspaceProp, runtime, onClose, visible }) => {
    const workspace = workspaceProp.trim();
    const workspaceKey = normalizeGitWorkspaceKey(workspace);
    const initialCache = gitReviewCacheFor(workspaceKey);
    const persistedStatus = task?.gitContext?.status as GrokGitStatus | undefined;
    const [status, setStatus] = useState<GrokGitStatus | undefined>(initialCache.status || persistedStatus);
    const [selectedPath, setSelectedPath] = useState(initialCache.selectedPath || initialCache.status?.files[0]?.path || persistedStatus?.files[0]?.path || '');
    const [diff, setDiff] = useState<GrokGitDiff | null>(() => initialCache.selectedPath ? initialCache.diffs.get(initialCache.selectedPath) || null : null);
    const [statusLoading, setStatusLoading] = useState(!initialCache.status && !persistedStatus);
    const [loadingPath, setLoadingPath] = useState('');
    const [error, setError] = useState('');
    const [activeView, setActiveView] = useState<'diff' | 'operations'>('diff');
    const [panelWidth, setPanelWidth] = useState(readPanelWidth);
    const [expanded, setExpanded] = useState(false);
    const [fileListVisible, setFileListVisible] = useState(readFileListVisible);
    const [fileListPct, setFileListPct] = useState<number | undefined>(readFileListPct);
    const [syncMode, setSyncMode] = useState<'connecting' | 'live' | 'manual'>('connecting');
    const panelRef = useRef<HTMLElement | null>(null);
    const fileListRef = useRef<HTMLElement | null>(null);
    const resizeStartRef = useRef<{ x: number; width: number } | null>(null);
    const fileListResizeStartRef = useRef<{ x: number; width: number } | null>(null);
    const statusRequestRef = useRef<Promise<GrokGitStatus> | null>(null);
    const snapshotRequestRef = useRef<Promise<void> | null>(null);
    const diffRequestIdRef = useRef(0);
    const diffGenerationRef = useRef(0);
    const diffPathGenerationRef = useRef(new Map<string, number>());
    const snapshotGenerationRef = useRef(0);
    const initializingWorkspaceRef = useRef(false);
    const selectedPathRef = useRef(selectedPath);
    selectedPathRef.current = selectedPath;
    const activeViewRef = useRef(activeView);
    activeViewRef.current = activeView;
    const onCloseRef = useRef(onClose);
    onCloseRef.current = onClose;

    const { refreshTaskGitStatus, loadTaskGitDiff, refreshWorkspaceGitStatus, loadWorkspaceGitDiff } = runtime;
    const files = status?.files || [];
    const selectedFile = files.find((file) => file.path === selectedPath);
    const isRepository = status?.isRepository !== false;
    const isClean = Boolean(status && files.length === 0);

    const applyStatus = useCallback((nextStatus: GrokGitStatus, options: { clearDiffs?: boolean; clearBranches?: boolean; changedPaths?: string[] } = {}) => {
        const cache = gitReviewCacheFor(workspaceKey);
        const nextSignature = gitStatusSignature(nextStatus);
        const currentSignature = cache.statusSignature || (cache.status ? gitStatusSignature(cache.status) : '');
        const statusChanged = currentSignature !== nextSignature;
        if (options.clearDiffs || statusChanged) {
            cache.diffs.clear();
            cache.snapshotSignature = undefined;
        } else if (options.changedPaths?.length) {
            invalidateGitDiffPaths(cache, options.changedPaths);
        }
        if (options.clearDiffs || statusChanged) {
            diffGenerationRef.current += 1;
            snapshotGenerationRef.current += 1;
            snapshotRequestRef.current = null;
        }
        if (options.clearBranches) {
            cache.branches = undefined;
            cache.branchesUpdatedAt = undefined;
        }
        cache.status = nextStatus;
        cache.statusSignature = nextSignature;
        cache.updatedAt = Date.now();
        if (!statusChanged && !options.clearDiffs) return false;
        const nextSelectedPath = cache.selectedPath && nextStatus.files.some((file) => file.path === cache.selectedPath)
            ? cache.selectedPath
            : nextStatus.files[0]?.path || '';
        cache.selectedPath = nextSelectedPath;
        setStatus(nextStatus);
        setSelectedPath(nextSelectedPath);
        if (nextSelectedPath !== selectedPathRef.current) {
            setDiff(nextSelectedPath ? cache.diffs.get(nextSelectedPath) || null : null);
        }
        return true;
    }, [workspaceKey]);

    const refreshStatus = useCallback(async (foreground = false, changedPaths: string[] = []) => {
        if (!workspace) return undefined;
        if (statusRequestRef.current) {
            void writeDesktopLog('DEBUG', 'ark.git.panel', `phase=status_joined foreground=${foreground} visible=${visible} workspace=${JSON.stringify(workspace)}`, { taskId: task?.id, sessionId: task?.sessionId });
            return statusRequestRef.current;
        }
        if (foreground || !gitReviewCacheFor(workspaceKey).status) setStatusLoading(true);
        setError('');
        const startedAt = performance.now();
        void writeDesktopLog('INFO', 'ark.git.panel', `phase=status_started foreground=${foreground} visible=${visible} changed_count=${changedPaths.length} workspace=${JSON.stringify(workspace)}`, { taskId: task?.id, sessionId: task?.sessionId });
        const request = task ? refreshTaskGitStatus(task.id, false) : refreshWorkspaceGitStatus(workspace, false);
        statusRequestRef.current = request;
        try {
            const nextStatus = await request;
            applyStatus(nextStatus, { changedPaths });
            void writeDesktopLog('INFO', 'ark.git.panel', `phase=status_completed elapsed_ms=${Math.round(performance.now() - startedAt)} visible=${visible} files=${nextStatus.files.length} dirty=${nextStatus.isDirty} workspace=${JSON.stringify(workspace)}`, { taskId: task?.id, sessionId: task?.sessionId });
            return nextStatus;
        } catch (cause) {
            const message = cause instanceof Error ? cause.message : String(cause);
            void writeDesktopLog('ERROR', 'ark.git.panel', `phase=status_failed elapsed_ms=${Math.round(performance.now() - startedAt)} visible=${visible} workspace=${JSON.stringify(workspace)} error=${describeDesktopError(cause)}`, { taskId: task?.id, sessionId: task?.sessionId });
            setError(isNonGitRepositoryError(message) ? '当前文件夹不是 Git 仓库。' : message);
            throw cause;
        } finally {
            if (statusRequestRef.current === request) statusRequestRef.current = null;
            setStatusLoading(false);
        }
    }, [applyStatus, refreshTaskGitStatus, refreshWorkspaceGitStatus, task?.id, task?.sessionId, visible, workspace, workspaceKey]);

    const loadDiff = useCallback(async (path: string, force = false, silent = false) => {
        if (!path) {
            setDiff(null);
            return;
        }
        const cache = gitReviewCacheFor(workspaceKey);
        let cached = cache.diffs.get(path);
        if (cached && !force) {
            void writeDesktopLog('DEBUG', 'ark.git.panel', `phase=diff_cache_hit visible=${visible} path=${JSON.stringify(path)} patch_bytes=${cached.patch.length} workspace=${JSON.stringify(workspace)}`, { taskId: task?.id, sessionId: task?.sessionId });
            if (selectedPathRef.current === path) {
                setDiff(cached);
                setLoadingPath('');
            }
            return;
        }
        if (!force && snapshotRequestRef.current) {
            await snapshotRequestRef.current;
            cached = cache.diffs.get(path);
            if (cached) {
                if (selectedPathRef.current === path) {
                    setDiff(cached);
                    setLoadingPath('');
                }
                return;
            }
        }
        // The persisted file list can render before the latest repository status is ready.
        // Avoid starting status, diff and watcher Git processes at the same time: this is
        // especially expensive on Windows workspaces scanned by endpoint security software.
        const pendingStatus = statusRequestRef.current;
        if (pendingStatus) {
            try {
                await pendingStatus;
            } catch {
                return;
            }
            cached = cache.diffs.get(path);
            if (cached && !force) {
                if (selectedPathRef.current === path) {
                    setDiff(cached);
                    setLoadingPath('');
                }
                return;
            }
        }
        const requestId = diffRequestIdRef.current + 1;
        const generation = diffGenerationRef.current;
        const pathGeneration = diffPathGenerationRef.current.get(path) || 0;
        diffRequestIdRef.current = requestId;
        if (!silent && selectedPathRef.current === path) setLoadingPath(path);
        setError('');
        const startedAt = performance.now();
        void writeDesktopLog('INFO', 'ark.git.panel', `phase=diff_started panel_request_id=${requestId} force=${force} silent=${silent} visible=${visible} path=${JSON.stringify(path)} workspace=${JSON.stringify(workspace)}`, { taskId: task?.id, sessionId: task?.sessionId });
        try {
            const currentFile = cache.status?.files.find((file) => file.path === path);
            const context = { untracked: Boolean(currentFile?.untracked) };
            let nextDiff = task
                ? await loadTaskGitDiff(task.id, path, false, context)
                : await loadWorkspaceGitDiff(workspace, path, false, context);
            if (!nextDiff.patch.trim() && currentFile?.staged) {
                nextDiff = task
                    ? await loadTaskGitDiff(task.id, path, true, context)
                    : await loadWorkspaceGitDiff(workspace, path, true, context);
            }
            if (diffGenerationRef.current !== generation
                || (diffPathGenerationRef.current.get(path) || 0) !== pathGeneration) return;
            const currentDiff = cache.diffs.get(path);
            cache.diffs.set(path, nextDiff);
            if (diffRequestIdRef.current === requestId
                && selectedPathRef.current === path
                && (!currentDiff || currentDiff.patch !== nextDiff.patch || currentDiff.truncated !== nextDiff.truncated)) {
                setDiff(nextDiff);
            }
            void writeDesktopLog('INFO', 'ark.git.panel', `phase=diff_completed panel_request_id=${requestId} elapsed_ms=${Math.round(performance.now() - startedAt)} visible=${visible} patch_bytes=${nextDiff.patch.length} files=${nextDiff.files.length} truncated=${nextDiff.truncated} path=${JSON.stringify(path)} workspace=${JSON.stringify(workspace)}`, { taskId: task?.id, sessionId: task?.sessionId });
        } catch (cause) {
            void writeDesktopLog('ERROR', 'ark.git.panel', `phase=diff_failed panel_request_id=${requestId} elapsed_ms=${Math.round(performance.now() - startedAt)} visible=${visible} path=${JSON.stringify(path)} workspace=${JSON.stringify(workspace)} error=${describeDesktopError(cause)}`, { taskId: task?.id, sessionId: task?.sessionId });
            if (diffRequestIdRef.current === requestId) setError(cause instanceof Error ? cause.message : String(cause));
        } finally {
            if (!silent && diffRequestIdRef.current === requestId) setLoadingPath('');
        }
    }, [loadTaskGitDiff, loadWorkspaceGitDiff, task?.id, task?.sessionId, visible, workspace, workspaceKey]);

    const primeDiffCache = useCallback((currentStatus: GrokGitStatus) => {
        const statusSignature = gitStatusSignature(currentStatus);
        const currentCache = gitReviewCacheFor(workspaceKey);
        if (currentCache.snapshotSignature === statusSignature) return null;
        if (snapshotRequestRef.current || currentStatus.files.length < 2) return snapshotRequestRef.current;
        const generation = diffGenerationRef.current;
        const snapshotGeneration = snapshotGenerationRef.current;
        const context = {
            // VS Code also keeps untracked content as a working-tree model. Avoid spawning one
            // git --no-index process per untracked file while priming the tracked snapshot.
            untrackedPaths: [] as string[],
        };
        const request = (task
            ? loadTaskGitDiff(task.id, undefined, false, context)
            : loadWorkspaceGitDiff(workspace, undefined, false, context))
            .then((snapshot) => {
                const cache = gitReviewCacheFor(workspaceKey);
                if (cache.statusSignature !== statusSignature
                    || diffGenerationRef.current !== generation
                    || snapshotGenerationRef.current !== snapshotGeneration) return;
                cacheGitDiffSnapshot(cache, snapshot, currentStatus.files);
                cache.snapshotSignature = statusSignature;
                const currentPath = selectedPathRef.current;
                const cached = cache.diffs.get(currentPath);
                if (cached) {
                    diffRequestIdRef.current += 1;
                    setDiff(cached);
                    setLoadingPath('');
                }
            })
            .catch(() => undefined)
            .finally(() => {
                if (snapshotRequestRef.current === request) snapshotRequestRef.current = null;
            });
        snapshotRequestRef.current = request;
        return request;
    }, [loadTaskGitDiff, loadWorkspaceGitDiff, task?.id, workspace, workspaceKey]);

    const selectDiff = useCallback((path: string) => {
        const cache = gitReviewCacheFor(workspaceKey);
        if (selectedPathRef.current === path) {
            const cached = cache.diffs.get(path);
            if (cached) {
                setDiff(cached);
                setLoadingPath('');
            }
            return;
        }
        cache.selectedPath = path;
        selectedPathRef.current = path;
        diffRequestIdRef.current += 1;
        setSelectedPath(path);
        setDiff(cache.diffs.get(path) || null);
        setLoadingPath(cache.diffs.has(path) ? '' : path);
        setError('');
        if (initializingWorkspaceRef.current && !cache.diffs.has(path)) {
            void loadDiff(path);
        }
    }, [loadDiff, workspaceKey]);

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
        setLoadingPath('');
        setSyncMode('connecting');
        diffRequestIdRef.current += 1;
        diffGenerationRef.current += 1;
        diffPathGenerationRef.current.clear();
        snapshotGenerationRef.current += 1;
        snapshotRequestRef.current = null;
        void writeDesktopLog('INFO', 'ark.git.panel', `phase=workspace_changed visible=${visible} cache_status=${Boolean(nextStatus)} cached_diffs=${cache.diffs.size} workspace=${JSON.stringify(workspace)}`, { taskId: task?.id, sessionId: task?.sessionId });
    }, [task?.id, workspaceKey]);

    useEffect(() => {
        if (!visible || !status || !isRepository || status.files.length === 0) return;
        if (selectedPath && !gitReviewCacheFor(workspaceKey).diffs.has(selectedPath)) return;
        void primeDiffCache(status);
    }, [diff, isRepository, primeDiffCache, selectedPath, status, visible, workspaceKey]);

    // 点击面板外部任意区域时关闭代码变更窗口
    useEffect(() => {
        if (!visible) return undefined;
        const handlePointerDown = (event: PointerEvent) => {
            if (panelRef.current && !panelRef.current.contains(event.target as Node)) {
                onCloseRef.current();
            }
        };
        document.addEventListener('pointerdown', handlePointerDown);
        return () => document.removeEventListener('pointerdown', handlePointerDown);
    }, [visible]);

    useEffect(() => {
        if (!workspace) return undefined;
        const lifecycleStartedAt = performance.now();
        let disposed = false;
        let stopWatching: (() => void) | undefined;
        const refreshVisibleData = async (changedPaths: string[] = []) => {
            if (changedPaths.length > 0) {
                changedPaths.forEach((path) => diffPathGenerationRef.current.set(
                    path,
                    (diffPathGenerationRef.current.get(path) || 0) + 1,
                ));
                snapshotGenerationRef.current += 1;
                snapshotRequestRef.current = null;
                invalidateGitDiffPaths(gitReviewCacheFor(workspaceKey), changedPaths);
            }
            const previousSignature = gitReviewCacheFor(workspaceKey).statusSignature;
            const nextStatus = await refreshStatus(false, changedPaths);
            if (!nextStatus || activeViewRef.current !== 'diff') return nextStatus;
            const path = nextStatus?.files.some((file) => file.path === selectedPathRef.current)
                ? selectedPathRef.current
                : nextStatus?.files[0]?.path || '';
            const statusChanged = previousSignature !== gitStatusSignature(nextStatus);
            if (path && (statusChanged || changedPaths.includes(path))) await loadDiff(path, true, true);
            return nextStatus;
        };
        const handleVisibilityChange = () => {
            if (document.visibilityState === 'visible') void refreshVisibleData().catch(() => undefined);
        };
        const handleWorkspaceChanged = (event: GrokGitWorkspaceChangedEvent) => {
            void writeDesktopLog('INFO', 'ark.git.panel', `phase=watch_event visible=${visible} document_visible=${document.visibilityState === 'visible'} changed_count=${event.changedPaths.length} changed_paths=${JSON.stringify(event.changedPaths.slice(0, 20))} workspace=${JSON.stringify(workspace)}`, { taskId: task?.id, sessionId: task?.sessionId });
            if (!visible || document.visibilityState !== 'visible') {
                event.changedPaths.forEach((path) => diffPathGenerationRef.current.set(
                    path,
                    (diffPathGenerationRef.current.get(path) || 0) + 1,
                ));
                snapshotGenerationRef.current += 1;
                snapshotRequestRef.current = null;
                invalidateGitDiffPaths(gitReviewCacheFor(workspaceKey), event.changedPaths);
                return;
            }
            void refreshVisibleData(event.changedPaths).catch(() => undefined);
        };
        const initialize = async () => {
            void writeDesktopLog('INFO', 'ark.git.panel', `phase=watch_initialize visible=${visible} workspace=${JSON.stringify(workspace)}`, { taskId: task?.id, sessionId: task?.sessionId });
            initializingWorkspaceRef.current = visible;
            const nextStatus = visible
                ? await refreshVisibleData()
                : gitReviewCacheFor(workspaceKey).status;
            if (visible && nextStatus && activeViewRef.current === 'diff') {
                const path = nextStatus.files.some((file) => file.path === selectedPathRef.current)
                    ? selectedPathRef.current
                    : nextStatus.files[0]?.path || '';
                if (path) await loadDiff(path);
            }
            if (disposed) return;
            try {
                const stop = await watchGrokGitWorkspace(workspace, handleWorkspaceChanged, { taskId: task?.id, sessionId: task?.sessionId });
                if (disposed) stop();
                else {
                    stopWatching = stop;
                    initializingWorkspaceRef.current = false;
                    setSyncMode('live');
                    void writeDesktopLog('INFO', 'ark.git.panel', `phase=watch_ready elapsed_ms=${Math.round(performance.now() - lifecycleStartedAt)} visible=${visible} workspace=${JSON.stringify(workspace)}`, { taskId: task?.id, sessionId: task?.sessionId });
                }
            } catch (cause) {
                if (!disposed) {
                    initializingWorkspaceRef.current = false;
                    setSyncMode('manual');
                    void writeDesktopLog('ERROR', 'ark.git.panel', `phase=watch_failed elapsed_ms=${Math.round(performance.now() - lifecycleStartedAt)} visible=${visible} workspace=${JSON.stringify(workspace)} error=${describeDesktopError(cause)}`, { taskId: task?.id, sessionId: task?.sessionId });
                }
            }
        };
        void initialize().catch(() => {
            if (!disposed) {
                initializingWorkspaceRef.current = false;
                setSyncMode('manual');
            }
        });
        document.addEventListener('visibilitychange', handleVisibilityChange);
        return () => {
            disposed = true;
            initializingWorkspaceRef.current = false;
            stopWatching?.();
            void writeDesktopLog('INFO', 'ark.git.panel', `phase=watch_cleanup lifetime_ms=${Math.round(performance.now() - lifecycleStartedAt)} visible=${visible} had_watcher=${Boolean(stopWatching)} workspace=${JSON.stringify(workspace)}`, { taskId: task?.id, sessionId: task?.sessionId });
            document.removeEventListener('visibilitychange', handleVisibilityChange);
        };
    }, [loadDiff, refreshStatus, task?.id, task?.sessionId, visible, workspace, workspaceKey]);

    useEffect(() => {
        if (!visible || activeView !== 'diff' || !selectedPath || !isRepository || initializingWorkspaceRef.current) return;
        void loadDiff(selectedPath);
    }, [activeView, isRepository, loadDiff, selectedPath, syncMode, visible]);

    useEffect(() => {
        localStorage.setItem(PANEL_WIDTH_STORAGE_KEY, String(panelWidth));
    }, [panelWidth]);

    useEffect(() => {
        localStorage.setItem(FILE_LIST_VISIBLE_STORAGE_KEY, fileListVisible ? '1' : '0');
    }, [fileListVisible]);

    useEffect(() => {
        if (fileListPct === undefined) return;
        localStorage.setItem(FILE_LIST_WIDTH_PCT_STORAGE_KEY, String(fileListPct));
    }, [fileListPct]);

    useEffect(() => {
        const move = (event: PointerEvent) => {
            if (!fileListResizeStartRef.current || !panelRef.current) return;
            const panelWidthPx = panelRef.current.getBoundingClientRect().width;
            if (panelWidthPx <= 0) return;
            const width = fileListResizeStartRef.current.width + (event.clientX - fileListResizeStartRef.current.x);
            setFileListPct(Math.min(Math.max((width / panelWidthPx) * 100, FILE_LIST_MIN_PCT), FILE_LIST_MAX_PCT));
        };
        const stop = () => { fileListResizeStartRef.current = null; };
        window.addEventListener('pointermove', move);
        window.addEventListener('pointerup', stop);
        window.addEventListener('pointercancel', stop);
        return () => {
            window.removeEventListener('pointermove', move);
            window.removeEventListener('pointerup', stop);
            window.removeEventListener('pointercancel', stop);
        };
    }, []);

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
        ref={panelRef}
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
            <span className="ml-auto flex items-center gap-2">
                <span className={`h-1.5 w-1.5 rounded-full ${syncMode === 'live' ? 'bg-emerald-500' : syncMode === 'connecting' ? 'animate-pulse bg-amber-400' : 'bg-slate-300'}`} />
                <span>{syncMode === 'live' ? '实时同步' : syncMode === 'connecting' ? '正在连接' : '手动刷新'}</span>
                {updatedAt && <span className="text-slate-400">· {formatRefreshTime(updatedAt)} 更新</span>}
            </span>
        </div>

        {error && <div className="mx-5 mt-3 flex shrink-0 items-start gap-2 rounded-xl bg-red-50 px-3 py-2.5 text-xs leading-5 text-red-700"><AlertCircle size={15} className="mt-0.5 shrink-0" /><span className="min-w-0 flex-1 break-words">{error}</span></div>}

        <div className="flex shrink-0 border-b border-slate-200 px-5" role="tablist" aria-label="代码变更视图">
            <button type="button" role="tab" aria-selected={activeView === 'diff'} onClick={() => setActiveView('diff')} className={`h-10 border-b-2 px-3 text-xs font-semibold transition ${activeView === 'diff' ? 'border-indigo-600 text-indigo-600' : 'border-transparent text-slate-500 hover:text-slate-700'}`}>Diff</button>
            <button type="button" role="tab" aria-selected={activeView === 'operations'} onClick={() => setActiveView('operations')} className={`h-10 border-b-2 px-3 text-xs font-semibold transition ${activeView === 'operations' ? 'border-indigo-600 text-indigo-600' : 'border-transparent text-slate-500 hover:text-slate-700'}`}>Git 操作</button>
        </div>

        {activeView === 'diff' ? <div className="flex min-h-0 flex-1">
            {fileListVisible && <>
                <nav ref={fileListRef} className="min-h-0 shrink-0 overflow-y-auto border-r border-slate-100 bg-slate-50/60 p-2" style={{ width: `${fileListPct ?? (expanded ? 28 : 34)}%` }} aria-label="变更文件">
                {statusLoading && !status ? <div className="flex h-28 items-center justify-center gap-2 text-xs text-slate-400"><LoaderCircle size={15} className="animate-spin" />正在检查工作区</div>
                    : !isRepository ? <div className="px-3 py-8 text-center text-xs leading-5 text-slate-400">当前文件夹不是 Git 仓库</div>
                        : isClean ? <div className="px-3 py-8 text-center text-xs leading-5 text-slate-400">当前文件夹没有未提交变更</div>
                            : files.map((file) => {
                                const presentation = fileStatus(file);
                                const selected = selectedPath === file.path;
                                return <button key={file.path} type="button" onClick={() => selectDiff(file.path)} className={`mb-1 w-full rounded-xl px-3 py-2.5 text-left transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-300 ${selected ? 'bg-white shadow-sm ring-1 ring-slate-200' : 'hover:bg-white/80'}`}>
                                    <span className="flex items-start gap-2"><FileCode2 size={14} className={`mt-0.5 shrink-0 ${selected ? 'text-indigo-600' : 'text-slate-400'}`} /><span className="min-w-0 flex-1"><span className="block truncate text-xs font-medium text-slate-700" title={file.path}>{file.path}</span><span className="mt-1 flex items-center gap-2"><span className={`rounded-md px-1.5 py-0.5 text-[9px] font-medium ${presentation.className}`}>{presentation.label}</span>{file.additions > 0 && <span className="text-[10px] text-emerald-600">+{file.additions}</span>}{file.deletions > 0 && <span className="text-[10px] text-red-500">-{file.deletions}</span>}</span></span><ChevronRight size={13} className={`mt-0.5 shrink-0 ${selected ? 'text-indigo-500' : 'text-slate-300'}`} /></span>
                                </button>;
                            })}
            </nav>
                <div role="separator" aria-label="调整变更文件栏宽度" aria-orientation="vertical" tabIndex={0} onPointerDown={(event) => {
                    fileListResizeStartRef.current = { x: event.clientX, width: fileListRef.current?.getBoundingClientRect().width || 0 };
                    event.preventDefault();
                }} className="relative z-10 flex w-1.5 shrink-0 cursor-col-resize items-center justify-center focus-visible:bg-indigo-300 hover:bg-indigo-100"><span className="h-full w-px bg-slate-200" /></div>
            </>}

            <section className="min-h-0 flex-1 overflow-y-auto bg-[#181818] p-2">
                {loadingPath === selectedPath ? <div className="flex h-40 items-center justify-center gap-2 text-xs text-slate-400"><LoaderCircle size={15} className="animate-spin" />正在读取 {selectedPath}</div>
                    : diff?.patch.trim() ? <GitDiffViewer patch={diff.patch} filePath={selectedPath} truncated={diff.truncated} />
                        : selectedFile ? <div className="flex h-40 items-center justify-center px-6 text-center text-xs leading-5 text-slate-400">该文件没有可显示的文本 Diff，可能是二进制文件、空文件或仅包含 Git 元数据变更。</div>
                            : <div className="flex h-40 items-center justify-center text-xs text-slate-500">从左侧选择变更文件</div>}
            </section>
        </div> : <GitOperationsPanel task={task} workspace={workspace} runtime={runtime} status={status} workspaceKey={workspaceKey} onStatusChange={applyStatus} />}
    </aside>;
};

export default GitReviewPanel;
