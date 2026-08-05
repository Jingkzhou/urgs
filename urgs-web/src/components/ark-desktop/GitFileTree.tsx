import React, { useMemo, useState } from 'react';
import { Eye, FileText, Folder, FolderOpen } from 'lucide-react';
import type { GrokGitStatus } from '@/services/grokDesktop';

interface GitFileTreeNode {
    name: string;
    path: string;
    file?: GrokGitStatus['files'][number];
    children: GitFileTreeNode[];
}

interface GitFileTreeProps {
    files: GrokGitStatus['files'];
    selectedFile: string;
    selectedPaths: Set<string>;
    onTogglePath: (path: string) => void;
    onSelectFile: (path: string) => void;
    onOpenDiff: (path: string) => void;
}

const statusText = (file: GrokGitStatus['files'][number]) => {
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
            const path = parent.path ? `${parent.path}/${segment}` : segment;
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

const GitFileTree: React.FC<GitFileTreeProps> = ({ files, selectedFile, selectedPaths, onTogglePath, onSelectFile, onOpenDiff }) => {
    const [collapsed, setCollapsed] = useState<Set<string>>(() => new Set());
    const tree = useMemo(() => buildTree(files), [files]);

    const renderNode = (node: GitFileTreeNode, depth: number): React.ReactNode => {
        if (node.file) {
            const presentation = statusText(node.file);
            const selected = selectedFile === node.file.path;
            return <div key={node.path} className={`rounded-lg border px-2 py-1.5 transition ${selected ? 'border-indigo-200 bg-indigo-50/60' : 'border-transparent hover:border-slate-200 hover:bg-white'}`} style={{ marginLeft: depth * 14 }}>
                <div className="flex items-start gap-1.5">
                    <input type="checkbox" checked={selectedPaths.has(node.file.path)} onChange={() => onTogglePath(node.file!.path)} className="mt-1 accent-indigo-600" aria-label={`选择 ${node.file.path}`} />
                    <button type="button" onClick={() => { onSelectFile(node.file!.path); onOpenDiff(node.file!.path); }} className="min-w-0 flex-1 text-left">
                        <span className="flex items-center gap-1.5"><FileText size={13} className="shrink-0 text-slate-400" /><span className="min-w-0 flex-1 truncate font-mono text-[11px] text-slate-700" title={node.file.path}>{node.name}</span></span>
                        <span className="mt-1 flex items-center gap-2 pl-[19px] text-[10px] text-slate-400"><span className={`rounded-full px-1.5 py-0.5 ${presentation.className}`}>{presentation.label}</span><span className="text-emerald-600">+{node.file.additions}</span><span className="text-red-500">-{node.file.deletions}</span></span>
                    </button>
                    <button type="button" onClick={() => onOpenDiff(node.file!.path)} className="rounded-md p-1 text-slate-400 hover:bg-white hover:text-indigo-600" title="查看 Diff" aria-label={`查看 ${node.file.path} 的 Diff`}><Eye size={14} /></button>
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

    return <div className="space-y-0.5 rounded-xl border border-slate-200 bg-white p-1.5">{tree.length > 0 ? tree.map((node) => renderNode(node, 0)) : <EmptyState />}</div>;
};

export default GitFileTree;
