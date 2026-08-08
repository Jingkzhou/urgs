import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Eye, FileText, Folder, FolderOpen } from 'lucide-react';
import type { GrokGitStatus } from '@/services/grokDesktop';

interface GitFileTreeNode {
    name: string;
    path: string;
    file?: GrokGitStatus['files'][number];
    children: GitFileTreeNode[];
}

interface GitFileTreeProps {
    compact?: boolean;
    files: GrokGitStatus['files'];
    selectedFile: string;
    selectedPaths: Set<string>;
    onTogglePath: (path: string) => void;
    onSelectFile: (path: string) => void;
    onOpenDiff: (path: string) => void;
    onOpenFile: (path: string) => void;
    onOpenHeadFile: (path: string) => void;
    onDiscardFile: (path: string) => void;
    onStageFile: (path: string) => void;
    onAddToGitignore: (path: string) => void;
    onRevealInFinder: (path: string) => void;
    readonly?: boolean;
}

type GitFile = GrokGitStatus['files'][number];

interface GitFileContextMenuState {
    file: GitFile;
    x: number;
    y: number;
}

const statusText = (file: GitFile) => {
    if (file.conflicted) return { label: '冲突', className: 'bg-red-50 text-red-600' };
    if (file.untracked) return { label: '未跟踪', className: 'bg-amber-50 text-amber-700' };
    if (file.staged && file.modified) return { label: '已暂存 + 修改', className: 'bg-indigo-50 text-indigo-600' };
    if (file.staged) return { label: '已暂存', className: 'bg-emerald-50 text-emerald-700' };
    return { label: '已修改', className: 'bg-slate-100 text-slate-600' };
};

const buildTree = (files: GrokGitStatus['files']) => {
    const root: GitFileTreeNode = { name: '', path: '', children: [] };
    files.forEach((file) => {
        const segments = file.path.split('/').filter(Boolean);
        let parent = root;
        segments.forEach((segment, index) => {
            const path = parent.path ? parent.path + '/' + segment : segment;
            let node = parent.children.find((item) => item.name === segment);
            if (!node) {
                node = { name: segment, path, children: [] };
                parent.children.push(node);
            }
            if (index === segments.length - 1) node.file = file;
            parent = node;
        });
    });
    const sort = (nodes: GitFileTreeNode[]) => {
        nodes.sort((left, right) => {
            if (Boolean(left.file) !== Boolean(right.file)) return left.file ? 1 : -1;
            return left.name.localeCompare(right.name, 'zh-CN');
        });
        nodes.forEach((node) => sort(node.children));
    };
    sort(root.children);
    return root.children;
};

const countFiles = (node: GitFileTreeNode): number => node.file
    ? 1
    : node.children.reduce((count, child) => count + countFiles(child), 0);

const EmptyState: React.FC = () => <div className="flex min-h-24 items-center justify-center px-4 text-center text-[11px] text-slate-400">当前工作区没有未提交变更</div>;

const ContextMenuButton: React.FC<{
    label: string;
    onClick: () => void;
    disabled?: boolean;
    destructive?: boolean;
}> = ({ label, onClick, disabled = false, destructive = false }) => (
    <button
        type="button"
        role="menuitem"
        disabled={disabled}
        onClick={onClick}
        className={
            'flex h-9 w-full items-center rounded-md px-3 text-left text-[13px] transition '
            + (destructive ? 'text-red-600 hover:bg-red-50' : 'text-slate-700 hover:bg-slate-100')
            + ' disabled:cursor-not-allowed disabled:text-slate-300 disabled:hover:bg-transparent'
        }
    >
        {label}
    </button>
);

const GitFileTree: React.FC<GitFileTreeProps> = ({
    compact = false,
    files,
    selectedFile,
    selectedPaths,
    onTogglePath,
    onSelectFile,
    onOpenDiff,
    onOpenFile,
    onOpenHeadFile,
    onDiscardFile,
    onStageFile,
    onAddToGitignore,
    onRevealInFinder,
    readonly = false,
}) => {
    const [collapsed, setCollapsed] = useState<Set<string>>(() => new Set());
    const [contextMenu, setContextMenu] = useState<GitFileContextMenuState | null>(null);
    const contextMenuRef = useRef<HTMLDivElement>(null);
    const fileRefs = useRef<Record<string, HTMLDivElement | null>>({});
    const tree = useMemo(() => buildTree(files), [files]);

    useEffect(() => {
        if (!contextMenu) return undefined;
        const closeOnOutside = (event: MouseEvent) => {
            if (!contextMenuRef.current?.contains(event.target as Node)) setContextMenu(null);
        };
        const closeOnEscape = (event: KeyboardEvent) => {
            if (event.key === 'Escape') setContextMenu(null);
        };
        const closeOnScroll = () => setContextMenu(null);
        window.addEventListener('mousedown', closeOnOutside);
        window.addEventListener('keydown', closeOnEscape);
        window.addEventListener('scroll', closeOnScroll, true);
        return () => {
            window.removeEventListener('mousedown', closeOnOutside);
            window.removeEventListener('keydown', closeOnEscape);
            window.removeEventListener('scroll', closeOnScroll, true);
        };
    }, [contextMenu]);

    useEffect(() => {
        setContextMenu(null);
    }, [files]);

    const revealInExplorer = (path: string) => {
        onSelectFile(path);
        const segments = path.split('/').filter(Boolean);
        const parentPaths = segments
            .slice(0, -1)
            .map((_, index) => segments.slice(0, index + 1).join('/'));
        setCollapsed((current) => {
            const next = new Set(current);
            parentPaths.forEach((parentPath) => next.delete(parentPath));
            return next;
        });
        window.requestAnimationFrame(() => fileRefs.current[path]?.scrollIntoView({ block: 'nearest' }));
    };

    const openContextMenu = (event: React.MouseEvent<HTMLDivElement>, file: GitFile) => {
        event.preventDefault();
        event.stopPropagation();
        onSelectFile(file.path);
        const menuWidth = 280;
        const menuHeight = 360;
        setContextMenu({
            file,
            x: Math.max(8, Math.min(event.clientX, window.innerWidth - menuWidth - 8)),
            y: Math.max(8, Math.min(event.clientY, window.innerHeight - menuHeight - 8)),
        });
    };

    const runContextAction = (action: () => void) => {
        setContextMenu(null);
        action();
    };

    const renderNode = (node: GitFileTreeNode, depth: number): React.ReactNode => {
        if (node.file) {
            const file = node.file;
            const presentation = statusText(file);
            const selected = selectedFile === file.path;
            const rowClassName = selected
                ? 'border-indigo-200 bg-indigo-50/60'
                : 'border-transparent hover:border-slate-200 hover:bg-white';
            return <div
                key={node.path}
                ref={(element) => { fileRefs.current[file.path] = element; }}
                data-git-file-path={file.path}
                onContextMenu={(event) => openContextMenu(event, file)}
                className={'rounded-lg border px-2 py-1.5 transition ' + rowClassName}
                style={{ marginLeft: depth * 14 }}
            >
                <div className="flex items-start gap-1.5">
                    <input type="checkbox" checked={selectedPaths.has(file.path)} onChange={() => onTogglePath(file.path)} className="mt-1 accent-indigo-600" aria-label={'选择 ' + file.path} />
                    <button type="button" onClick={() => { onSelectFile(file.path); onOpenDiff(file.path); }} className="min-w-0 flex-1 text-left">
                        <span className="flex items-center gap-1.5"><FileText size={13} className="shrink-0 text-slate-400" /><span className="min-w-0 flex-1 truncate font-mono text-[11px] text-slate-700" title={file.path}>{node.name}</span></span>
                        <span className="mt-1 flex items-center gap-2 pl-[19px] text-[10px] text-slate-400"><span className={'rounded-full px-1.5 py-0.5 ' + presentation.className}>{presentation.label}</span><span className="text-emerald-600">+{file.additions}</span><span className="text-red-500">-{file.deletions}</span></span>
                    </button>
                    <button type="button" onClick={() => onOpenDiff(file.path)} className="rounded-md p-1 text-slate-400 hover:bg-white hover:text-indigo-600" title="查看 Diff" aria-label={'查看 ' + file.path + ' 的 Diff'}><Eye size={14} /></button>
                </div>
            </div>;
        }

        const isCollapsed = collapsed.has(node.path);
        return <React.Fragment key={node.path}>
            <button type="button" onClick={() => setCollapsed((current) => { const next = new Set(current); if (next.has(node.path)) next.delete(node.path); else next.add(node.path); return next; })} className="flex w-full items-center gap-1.5 rounded-lg px-2 py-1.5 text-left text-[11px] font-medium text-slate-600 hover:bg-white" style={{ paddingLeft: 8 + depth * 14 }} aria-expanded={!isCollapsed}>
                <span className="w-3 text-center text-slate-400">{isCollapsed ? '›' : '⌄'}</span>
                {isCollapsed ? <Folder size={13} className="text-amber-500" /> : <FolderOpen size={13} className="text-amber-500" />}
                <span className="min-w-0 flex-1 truncate">{node.name}</span><span className="text-[10px] text-slate-400">{countFiles(node)}</span>
            </button>
            {!isCollapsed && node.children.map((child) => renderNode(child, depth + 1))}
        </React.Fragment>;
    };

    const contextFile = contextMenu?.file;
    const canDiscard = Boolean(contextFile && !readonly && !contextFile.untracked && (contextFile.staged || contextFile.modified));
    const canStage = Boolean(contextFile && !readonly && (!contextFile.staged || contextFile.modified));
    const canOpenHead = Boolean(contextFile && !contextFile.untracked);
    return <div className="relative">
        <div className={compact ? 'space-y-0.5' : 'space-y-0.5 rounded-xl border border-slate-200 bg-white p-1.5'}>{tree.length > 0 ? tree.map((node) => renderNode(node, 0)) : <EmptyState />}</div>
        {contextMenu && contextFile && <div
            ref={contextMenuRef}
            role="menu"
            aria-label={'文件操作 ' + contextFile.path}
            className="fixed z-[100] w-[280px] rounded-[16px] border border-slate-200 bg-white/95 p-2 shadow-[0_16px_42px_rgba(15,23,42,0.18)] backdrop-blur"
            style={{ left: contextMenu.x, top: contextMenu.y }}
        >
            <ContextMenuButton label="打开更改" onClick={() => runContextAction(() => onOpenDiff(contextFile.path))} />
            <ContextMenuButton label="打开文件" onClick={() => runContextAction(() => onOpenFile(contextFile.path))} />
            <ContextMenuButton label="打开文件 (HEAD)" disabled={!canOpenHead} onClick={() => runContextAction(() => onOpenHeadFile(contextFile.path))} />
            <div className="my-1 border-t border-slate-200" />
            <ContextMenuButton label="放弃更改" disabled={!canDiscard} destructive onClick={() => runContextAction(() => onDiscardFile(contextFile.path))} />
            <ContextMenuButton label="暂存更改" disabled={!canStage} onClick={() => runContextAction(() => onStageFile(contextFile.path))} />
            <ContextMenuButton label="添加到 .gitignore" disabled={readonly} onClick={() => runContextAction(() => onAddToGitignore(contextFile.path))} />
            <div className="my-1 border-t border-slate-200" />
            <ContextMenuButton label="在查找器中显示" onClick={() => runContextAction(() => onRevealInFinder(contextFile.path))} />
            <ContextMenuButton label="在资源管理器视图中显示" onClick={() => runContextAction(() => revealInExplorer(contextFile.path))} />
        </div>}
    </div>;
};

export default GitFileTree;
