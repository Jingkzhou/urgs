import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
    Archive, ArchiveRestore, Check, Copy, Ellipsis, Folder,
    FolderOpen, LoaderCircle, Pencil, Pin, PinOff, Plus, Trash2, X,
} from 'lucide-react';
import { copyToClipboard } from '@/utils/clipboard';
import type { ArkDesktopTask } from './types';

type SessionView = 'active' | 'running' | 'archived';

interface WorkspaceSessionSidebarProps {
    tasks: ArkDesktopTask[];
    workspaces: string[];
    defaultWorkspace: string;
    searchValue: string;
    activeTaskId: string | null;
    onOpenTask: (taskId: string) => void;
    onAddWorkspace: () => Promise<void>;
    onCreateInWorkspace: (workspace: string) => void;
    onSetDefaultWorkspace: (workspace: string) => void;
    onRemoveWorkspace: (workspace: string) => void;
    onRevealWorkspace: (workspace: string) => Promise<void>;
    onRenameTask: (taskId: string, title: string) => void;
    onToggleTaskPin: (taskId: string) => void;
    onArchiveTask: (taskId: string) => void;
    onRestoreTask: (taskId: string) => void;
    onDeleteTask: (taskId: string) => Promise<void>;
    onError: (message: string) => void;
}

const isBusyTask = (task: ArkDesktopTask) => task.status === 'running' || task.status === 'waiting_authorization';
const DEFAULT_VISIBLE_TASK_COUNT = 5;

const MenuButton: React.FC<{
    icon: React.ElementType;
    label: string;
    onClick: () => void;
    disabled?: boolean;
    dangerous?: boolean;
}> = ({ icon: Icon, label, onClick, disabled = false, dangerous = false }) => (
    <button
        type="button"
        role="menuitem"
        disabled={disabled}
        onClick={onClick}
        className={`flex w-full items-center gap-2.5 rounded-lg px-2.5 py-2 text-left text-xs transition disabled:cursor-not-allowed disabled:opacity-40 ${dangerous ? 'text-red-600 hover:bg-red-50' : 'text-slate-600 hover:bg-slate-100 hover:text-slate-800'}`}
    >
        <Icon size={14} strokeWidth={1.8} />
        <span>{label}</span>
    </button>
);

const WorkspaceSessionSidebar: React.FC<WorkspaceSessionSidebarProps> = ({
    tasks,
    workspaces,
    defaultWorkspace,
    searchValue,
    activeTaskId,
    onOpenTask,
    onAddWorkspace,
    onCreateInWorkspace,
    onSetDefaultWorkspace,
    onRemoveWorkspace,
    onRevealWorkspace,
    onRenameTask,
    onToggleTaskPin,
    onArchiveTask,
    onRestoreTask,
    onDeleteTask,
    onError,
}) => {
    const [view, setView] = useState<SessionView>('active');
    const [collapsedWorkspaceKeys, setCollapsedWorkspaceKeys] = useState<Set<string>>(() => new Set());
    const [expandedTaskWorkspaceKeys, setExpandedTaskWorkspaceKeys] = useState<Set<string>>(() => new Set());
    const [openMenu, setOpenMenu] = useState<{ kind: 'workspace' | 'task'; id: string } | null>(null);
    const [renamingTaskId, setRenamingTaskId] = useState<string | null>(null);
    const [renameValue, setRenameValue] = useState('');
    const [deleteTarget, setDeleteTarget] = useState<ArkDesktopTask | null>(null);
    const [removeWorkspaceTarget, setRemoveWorkspaceTarget] = useState<string | null>(null);
    const [deleting, setDeleting] = useState(false);
    const [addingWorkspace, setAddingWorkspace] = useState(false);
    const [toast, setToast] = useState<{ message: string; restoreTaskId?: string } | null>(null);
    const menuRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        if (!openMenu) return undefined;
        const close = (event: MouseEvent) => {
            if (!menuRef.current?.contains(event.target as Node)) setOpenMenu(null);
        };
        const closeOnEscape = (event: KeyboardEvent) => {
            if (event.key === 'Escape') setOpenMenu(null);
        };
        window.addEventListener('mousedown', close);
        window.addEventListener('keydown', closeOnEscape);
        return () => {
            window.removeEventListener('mousedown', close);
            window.removeEventListener('keydown', closeOnEscape);
        };
    }, [openMenu]);

    useEffect(() => {
        if (!toast) return undefined;
        const timer = window.setTimeout(() => setToast(null), 4_500);
        return () => window.clearTimeout(timer);
    }, [toast]);

    const query = searchValue.trim().toLowerCase();
    const groups = useMemo(() => {
        return workspaces.map((workspace) => {
            const workspaceTasks = tasks.filter((task) => task.workspace === workspace);
            const filtered = workspaceTasks
                .filter((task) => !query || `${task.title} ${task.prompt} ${task.workspace}`.toLowerCase().includes(query))
                .filter((task) => view === 'archived'
                    ? Boolean(task.archivedAt)
                    : view === 'running'
                        ? !task.archivedAt && isBusyTask(task)
                        : !task.archivedAt)
                .sort((left, right) => {
                    if (Boolean(left.pinnedAt) !== Boolean(right.pinnedAt)) return left.pinnedAt ? -1 : 1;
                    if (isBusyTask(left) !== isBusyTask(right)) return isBusyTask(left) ? -1 : 1;
                    return right.updatedAt - left.updatedAt;
                });
            const latestAt = workspaceTasks.reduce((latest, task) => Math.max(latest, task.updatedAt), 0);
            return {
                workspace,
                label: workspace.split(/[\\/]/).filter(Boolean).pop() || workspace,
                tasks: filtered,
                latestAt,
                default: workspace === defaultWorkspace,
                busy: workspaceTasks.some((task) => !task.archivedAt && isBusyTask(task)),
            };
        }).filter((group) => {
            if (query || view !== 'active') return group.tasks.length > 0;
            return true;
        }).sort((left, right) => {
            if (left.default !== right.default) return left.default ? -1 : 1;
            return right.latestAt - left.latestAt;
        });
    }, [defaultWorkspace, query, tasks, view, workspaces]);

    const runningCount = tasks.filter((task) => !task.archivedAt && isBusyTask(task)).length;
    const archivedCount = tasks.filter((task) => task.archivedAt).length;

    const runAction = (action: () => void | Promise<void>) => {
        setOpenMenu(null);
        try {
            void Promise.resolve(action()).catch((error) => onError(error instanceof Error ? error.message : String(error)));
        } catch (error) {
            onError(error instanceof Error ? error.message : String(error));
        }
    };

    const beginRename = (task: ArkDesktopTask) => {
        setOpenMenu(null);
        setRenamingTaskId(task.id);
        setRenameValue(task.title);
    };

    const commitRename = (taskId: string) => {
        try {
            onRenameTask(taskId, renameValue);
            setRenamingTaskId(null);
            setRenameValue('');
        } catch (error) {
            onError(error instanceof Error ? error.message : String(error));
        }
    };

    const addWorkspace = async () => {
        setAddingWorkspace(true);
        try {
            await onAddWorkspace();
        } catch (error) {
            onError(error instanceof Error ? error.message : String(error));
        } finally {
            setAddingWorkspace(false);
        }
    };

    const archiveTask = (task: ArkDesktopTask) => {
        try {
            onArchiveTask(task.id);
            setOpenMenu(null);
            setToast({ message: `已归档“${task.title}”`, restoreTaskId: task.id });
        } catch (error) {
            onError(error instanceof Error ? error.message : String(error));
        }
    };

    const restoreTask = (task: ArkDesktopTask) => {
        onRestoreTask(task.id);
        setOpenMenu(null);
        setToast({ message: `已恢复“${task.title}”` });
    };

    const confirmDelete = async () => {
        if (!deleteTarget) return;
        setDeleting(true);
        try {
            await onDeleteTask(deleteTarget.id);
            setDeleteTarget(null);
            setToast({ message: `已永久删除“${deleteTarget.title}”` });
        } catch (error) {
            onError(error instanceof Error ? error.message : String(error));
        } finally {
            setDeleting(false);
        }
    };

    const confirmRemoveWorkspace = () => {
        if (!removeWorkspaceTarget) return;
        const label = removeWorkspaceTarget.split(/[\\/]/).filter(Boolean).pop() || removeWorkspaceTarget;
        onRemoveWorkspace(removeWorkspaceTarget);
        setRemoveWorkspaceTarget(null);
        setToast({ message: `已从列表移除“${label}”` });
    };

    return <div className="relative mt-5 flex min-h-0 flex-1 flex-col">
        <div className="flex items-center justify-between px-2">
            <span className="text-[11px] font-medium text-slate-400">工作空间</span>
            <button
                type="button"
                disabled={addingWorkspace}
                onClick={() => void addWorkspace()}
                className="flex h-7 w-7 items-center justify-center rounded-lg text-slate-400 transition hover:bg-[#e8e8ea] hover:text-slate-700 disabled:opacity-50"
                title="添加工作区并新建会话"
                aria-label="添加工作区并新建会话"
            >
                {addingWorkspace ? <LoaderCircle size={14} className="animate-spin" /> : <Plus size={15} />}
            </button>
        </div>

        <div className="mt-1 flex items-center gap-1 px-1" role="tablist" aria-label="会话筛选">
            {([
                ['active', '最近', undefined],
                ['running', '运行中', runningCount],
                ['archived', '已归档', archivedCount],
            ] as const).map(([value, label, count]) => <button
                key={value}
                type="button"
                role="tab"
                aria-selected={view === value}
                onClick={() => setView(value)}
                className={`flex min-w-0 flex-1 items-center justify-center gap-1 rounded-md px-1.5 py-1.5 text-[11px] transition ${view === value ? 'bg-white font-medium text-slate-700 shadow-sm' : 'text-slate-400 hover:bg-[#eeeeef] hover:text-slate-600'}`}
            >
                <span>{label}</span>
                {typeof count === 'number' && count > 0 && <span className="rounded-full bg-slate-100 px-1 text-[9px] text-slate-500">{count}</span>}
            </button>)}
        </div>

        <div className="custom-scrollbar mt-3 min-h-0 flex-1 space-y-3 overflow-y-auto pr-1">
            {groups.map((group) => {
                const collapsed = collapsedWorkspaceKeys.has(group.workspace);
                const expandedTasks = expandedTaskWorkspaceKeys.has(group.workspace);
                const visibleTasks = query || expandedTasks
                    ? group.tasks
                    : group.tasks.slice(0, DEFAULT_VISIBLE_TASK_COUNT);
                const selectedWorkspace = tasks.find((task) => task.id === activeTaskId)?.workspace === group.workspace;
                return <section key={group.workspace} className="group/workspace relative">
                    <div className={`relative flex items-center rounded-lg transition ${selectedWorkspace ? 'bg-[#efedff]' : 'hover:bg-[#eeeeef]'}`}>
                        <button
                            type="button"
                            onClick={() => setCollapsedWorkspaceKeys((current) => {
                                const next = new Set(current);
                                if (next.has(group.workspace)) next.delete(group.workspace);
                                else next.add(group.workspace);
                                return next;
                            })}
                            className="flex min-w-0 flex-1 items-center gap-2 px-2 py-2 text-left"
                            title={group.workspace}
                            aria-expanded={!collapsed}
                            aria-label={`${collapsed ? '展开' : '收起'} ${group.label} 工作区`}
                        >
                            {collapsed
                                ? <Folder size={17} strokeWidth={1.7} className="shrink-0 text-slate-500" />
                                : <FolderOpen size={17} strokeWidth={1.7} className="shrink-0 text-slate-600" />}
                            <span className="min-w-0 flex-1 truncate text-[13px] font-medium text-[#47484e]">{group.label}</span>
                            {group.default && <span className="rounded bg-[#e8e4ff] px-1 py-0.5 text-[9px] font-medium text-[#6657d9]">默认</span>}
                            {group.busy && <LoaderCircle size={14} strokeWidth={2} className="shrink-0 animate-spin text-slate-500" aria-label={`${group.label} 中有进行中的会话`} />}
                            <span className="text-[10px] text-slate-400">{group.tasks.length}</span>
                        </button>
                        <div className="mr-1 flex items-center opacity-0 transition group-hover/workspace:opacity-100 focus-within:opacity-100">
                            <button type="button" onClick={() => onCreateInWorkspace(group.workspace)} className="rounded-md p-1.5 text-slate-400 hover:bg-white hover:text-[#6657d9]" title={`在 ${group.label} 中新建会话`} aria-label={`在 ${group.label} 中新建会话`}><Plus size={13} /></button>
                            <button type="button" onClick={() => setOpenMenu((current) => current?.kind === 'workspace' && current.id === group.workspace ? null : { kind: 'workspace', id: group.workspace })} className="rounded-md p-1.5 text-slate-400 hover:bg-white hover:text-slate-700" title={`${group.label} 工作区操作`} aria-label={`${group.label} 工作区操作`}><Ellipsis size={14} /></button>
                        </div>
                        {openMenu?.kind === 'workspace' && openMenu.id === group.workspace && <div ref={menuRef} role="menu" className="absolute right-1 top-9 z-50 w-44 rounded-xl border border-slate-200 bg-white p-1.5 shadow-[0_16px_45px_rgba(15,23,42,0.16)]">
                            <MenuButton icon={Plus} label="新建会话" onClick={() => runAction(() => onCreateInWorkspace(group.workspace))} />
                            <MenuButton icon={Check} label={group.default ? '当前默认工作区' : '设为默认工作区'} disabled={group.default} onClick={() => runAction(() => onSetDefaultWorkspace(group.workspace))} />
                            <MenuButton icon={FolderOpen} label="在 Finder 中打开" onClick={() => runAction(() => onRevealWorkspace(group.workspace))} />
                            <MenuButton icon={Copy} label="复制文件夹路径" onClick={() => runAction(async () => {
                                if (!await copyToClipboard(group.workspace)) throw new Error('复制工作区路径失败');
                                setToast({ message: '已复制工作区路径' });
                            })} />
                            <div className="my-1 border-t border-slate-100" />
                            <MenuButton
                                icon={Trash2}
                                label={group.tasks.some(isBusyTask) ? '请先停止进行中的会话' : '从列表移除'}
                                disabled={group.tasks.some(isBusyTask)}
                                dangerous
                                onClick={() => {
                                    setOpenMenu(null);
                                    setRemoveWorkspaceTarget(group.workspace);
                                }}
                            />
                        </div>}
                    </div>

                    {!collapsed && <div className="mt-0.5 space-y-0.5 pl-2">
                        {visibleTasks.map((task) => {
                            const active = task.id === activeTaskId;
                            const busy = isBusyTask(task);
                            return <div key={task.id} className={`group/task relative flex items-center rounded-lg transition ${active ? 'bg-[#e8e8ea] text-[#25262b]' : 'text-[#55565c] hover:bg-[#eeeeef]'}`}>
                                {renamingTaskId === task.id ? <div className="flex min-w-0 flex-1 items-center gap-1.5 px-2 py-1.5">
                                    <input
                                        autoFocus
                                        value={renameValue}
                                        maxLength={80}
                                        onChange={(event) => setRenameValue(event.target.value)}
                                        onKeyDown={(event) => {
                                            if (event.key === 'Enter') commitRename(task.id);
                                            if (event.key === 'Escape') setRenamingTaskId(null);
                                        }}
                                        onBlur={() => {
                                            setRenamingTaskId(null);
                                            setRenameValue('');
                                        }}
                                        className="min-w-0 flex-1 rounded-md border border-[#8a7cf0] bg-white px-2 py-1 text-xs text-slate-700 outline-none ring-2 ring-[#ece9ff]"
                                        aria-label="会话名称"
                                    />
                                    <button type="button" onMouseDown={(event) => event.preventDefault()} onClick={() => setRenamingTaskId(null)} className="rounded p-1 text-slate-400 hover:bg-white" aria-label="取消重命名"><X size={12} /></button>
                                </div> : <>
                                    <button type="button" onClick={() => onOpenTask(task.id)} className="min-w-0 flex-1 px-2 py-2.5 text-left">
                                        <span className="flex items-center gap-1.5">
                                            <span className="min-w-0 flex-1 truncate text-[12px] font-medium">{task.title}</span>
                                            {task.pinnedAt && <Pin size={11} className="shrink-0 fill-current text-[#6657d9]" />}
                                            {task.status === 'running' && <LoaderCircle size={14} strokeWidth={2} className="shrink-0 animate-spin text-slate-500" aria-label="任务进行中" />}
                                        </span>
                                    </button>
                                    <button type="button" onClick={() => setOpenMenu((current) => current?.kind === 'task' && current.id === task.id ? null : { kind: 'task', id: task.id })} className="mr-1 rounded-md p-1.5 text-slate-400 opacity-0 transition hover:bg-white hover:text-slate-700 group-hover/task:opacity-100 focus:opacity-100" title={`${task.title} 会话操作`} aria-label={`${task.title} 会话操作`}><Ellipsis size={14} /></button>
                                </>}
                                {openMenu?.kind === 'task' && openMenu.id === task.id && <div ref={menuRef} role="menu" className="absolute right-1 top-9 z-50 w-44 rounded-xl border border-slate-200 bg-white p-1.5 shadow-[0_16px_45px_rgba(15,23,42,0.16)]">
                                    <MenuButton icon={task.pinnedAt ? PinOff : Pin} label={task.pinnedAt ? '取消固定' : '固定到顶部'} onClick={() => runAction(() => onToggleTaskPin(task.id))} />
                                    <MenuButton icon={Pencil} label="重命名" onClick={() => beginRename(task)} />
                                    {task.archivedAt
                                        ? <MenuButton icon={ArchiveRestore} label="恢复到最近会话" onClick={() => restoreTask(task)} />
                                        : <MenuButton icon={Archive} label="归档会话" disabled={busy} onClick={() => archiveTask(task)} />}
                                    <div className="my-1 border-t border-slate-100" />
                                    <MenuButton icon={Trash2} label={busy ? '请先停止会话' : '永久删除'} disabled={busy} dangerous onClick={() => { setOpenMenu(null); setDeleteTarget(task); }} />
                                </div>}
                            </div>;
                        })}
                        {group.tasks.length === 0 && <div className="px-3 py-3 text-[11px] text-slate-400">该工作区暂无会话，点击文件夹旁的 + 开始。</div>}
                        {!query && group.tasks.length > DEFAULT_VISIBLE_TASK_COUNT && <button
                            type="button"
                            aria-expanded={expandedTasks}
                            onClick={() => setExpandedTaskWorkspaceKeys((current) => {
                                const next = new Set(current);
                                if (next.has(group.workspace)) next.delete(group.workspace);
                                else next.add(group.workspace);
                                return next;
                            })}
                            className="w-full rounded-lg px-2 py-1.5 text-left text-[11px] font-medium text-slate-400 transition hover:bg-[#eeeeef] hover:text-slate-600"
                        >
                            {expandedTasks ? '收起' : `显示更多（${group.tasks.length - DEFAULT_VISIBLE_TASK_COUNT}）`}
                        </button>}
                    </div>}
                </section>;
            })}
            {groups.length === 0 && <div className="px-3 py-8 text-center text-xs leading-5 text-slate-400">{query ? '没有匹配的会话' : view === 'archived' ? '暂无已归档会话' : view === 'running' ? '当前没有运行中的会话' : '暂无本地会话'}</div>}
        </div>

        {deleteTarget && <div className="fixed inset-0 z-[1200] flex items-center justify-center bg-slate-950/35 p-5 backdrop-blur-sm" role="dialog" aria-modal="true" aria-labelledby="delete-session-title">
            <div className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-5 shadow-2xl">
                <div className="flex items-start gap-3">
                    <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-red-50 text-red-600"><Trash2 size={18} /></span>
                    <div className="min-w-0 flex-1">
                        <h2 id="delete-session-title" className="font-semibold text-slate-900">永久删除这个会话？</h2>
                        <p className="mt-2 text-sm leading-6 text-slate-500">“{deleteTarget.title}”将从 URGS{deleteTarget.sessionId ? ' 和本地 Grok 历史' : ''}中永久删除，且无法恢复。</p>
                    </div>
                </div>
                <div className="mt-5 flex justify-end gap-2">
                    <button type="button" disabled={deleting} onClick={() => setDeleteTarget(null)} className="rounded-lg border border-slate-200 px-3.5 py-2 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-50">取消</button>
                    <button type="button" disabled={deleting} onClick={() => void confirmDelete()} className="flex items-center gap-1.5 rounded-lg bg-red-600 px-3.5 py-2 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-50">{deleting && <LoaderCircle size={14} className="animate-spin" />}永久删除</button>
                </div>
            </div>
        </div>}

        {removeWorkspaceTarget && <div className="fixed inset-0 z-[1200] flex items-center justify-center bg-slate-950/35 p-5 backdrop-blur-sm" role="dialog" aria-modal="true" aria-labelledby="remove-workspace-title">
            <div className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-5 shadow-2xl">
                <div className="flex items-start gap-3">
                    <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-red-50 text-red-600"><Trash2 size={18} /></span>
                    <div className="min-w-0 flex-1">
                        <h2 id="remove-workspace-title" className="font-semibold text-slate-900">移除这个工作空间？</h2>
                        <p className="mt-2 text-sm leading-6 text-slate-500">
                            只会从 URGS 的工作空间列表移除“{removeWorkspaceTarget.split(/[\\/]/).filter(Boolean).pop() || removeWorkspaceTarget}”，不会删除磁盘文件或已有会话。重新添加该文件夹后，历史会话会恢复显示。
                        </p>
                    </div>
                </div>
                <div className="mt-5 flex justify-end gap-2">
                    <button type="button" onClick={() => setRemoveWorkspaceTarget(null)} className="rounded-lg border border-slate-200 px-3.5 py-2 text-sm text-slate-600 hover:bg-slate-50">取消</button>
                    <button type="button" onClick={confirmRemoveWorkspace} className="rounded-lg bg-red-600 px-3.5 py-2 text-sm font-medium text-white hover:bg-red-700">从列表移除</button>
                </div>
            </div>
        </div>}

        {toast && <div className="absolute bottom-2 left-2 right-2 z-40 flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-xs text-slate-600 shadow-[0_12px_35px_rgba(15,23,42,0.14)]">
            <span className="min-w-0 flex-1 truncate">{toast.message}</span>
            {toast.restoreTaskId && <button type="button" onClick={() => {
                onRestoreTask(toast.restoreTaskId as string);
                setToast({ message: '已恢复会话' });
            }} className="shrink-0 font-medium text-[#6657d9] hover:text-[#5142c7]">撤销</button>}
            <button type="button" onClick={() => setToast(null)} className="shrink-0 rounded p-0.5 text-slate-400 hover:bg-slate-100" aria-label="关闭提示"><X size={12} /></button>
        </div>}
    </div>;
};

export default WorkspaceSessionSidebar;
