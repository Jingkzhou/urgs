import React, { useMemo, useState } from 'react';
import { ChevronDown, ChevronUp, FileCode2, ListCollapse } from 'lucide-react';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { oneDark } from 'react-syntax-highlighter/dist/esm/styles/prism';

type DiffLineKind = 'context' | 'addition' | 'deletion';

interface DiffLine {
    kind: DiffLineKind;
    content: string;
    oldLine?: number;
    newLine?: number;
}

interface DiffHunk {
    header: string;
    oldStart: number;
    oldCount: number;
    newStart: number;
    newCount: number;
    lines: DiffLine[];
}

interface ParsedFileDiff {
    path: string;
    hunks: DiffHunk[];
    additions: number;
    deletions: number;
}

interface GitDiffViewerProps {
    patch: string;
    filePath?: string;
    additions?: number;
    deletions?: number;
    truncated?: boolean;
    summary?: {
        title: string;
        subtitle: string;
        fileCount: number;
        additions: number;
        deletions: number;
        staged: boolean;
        onStagedChange: (checked: boolean) => void;
    };
}

const normalizePath = (value: string) => value.replace(/^\.[\/]/, '').replace(/^[ab][\/]/, '');

const parseHunkHeader = (value: string) => {
    const match = value.match(/^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@(?: ?(.*))?$/);
    if (!match) return null;
    return {
        header: value,
        oldStart: Number(match[1]),
        oldCount: Number(match[2] || 1),
        newStart: Number(match[3]),
        newCount: Number(match[4] || 1),
    };
};

const parsePatch = (patch: string, fallbackPath: string): ParsedFileDiff[] => {
    const parsed: ParsedFileDiff[] = [];
    let current: ParsedFileDiff | undefined;
    let hunk: DiffHunk | undefined;

    const ensureFile = (path = fallbackPath) => {
        if (!current) {
            current = { path: normalizePath(path), hunks: [], additions: 0, deletions: 0 };
            parsed.push(current);
        }
        return current;
    };

    patch.replace(/\r\n/g, '\n').split('\n').forEach((rawLine) => {
        if (rawLine.startsWith('diff --git ')) {
            const match = rawLine.match(/^diff --git a\/(.*) b\/(.*)$/);
            current = undefined;
            hunk = undefined;
            ensureFile(match?.[2] || fallbackPath);
            return;
        }
        if (rawLine.startsWith('+++ ')) {
            const path = rawLine.slice(4).trim();
            if (path !== '/dev/null') ensureFile(path);
            return;
        }
        const nextHunk = parseHunkHeader(rawLine);
        if (nextHunk) {
            const file = ensureFile();
            hunk = { ...nextHunk, lines: [] };
            file.hunks.push(hunk);
            return;
        }
        if (!hunk || !rawLine || rawLine.startsWith('\\ No newline')) return;

        const file = ensureFile();
        const prefix = rawLine[0];
        if (prefix !== ' ' && prefix !== '+' && prefix !== '-') return;
        const kind: DiffLineKind = prefix === '+' ? 'addition' : prefix === '-' ? 'deletion' : 'context';
        const line: DiffLine = { kind, content: rawLine.slice(1) };
        const previous = hunk.lines[hunk.lines.length - 1];
        const previousOldLine = previous?.oldLine ?? hunk.oldStart - 1;
        const previousNewLine = previous?.newLine ?? hunk.newStart - 1;
        if (kind !== 'addition') line.oldLine = previousOldLine + 1;
        if (kind !== 'deletion') line.newLine = previousNewLine + 1;
        hunk.lines.push(line);
        if (kind === 'addition') file.additions += 1;
        if (kind === 'deletion') file.deletions += 1;
    });

    return parsed.filter((file) => file.hunks.length > 0);
};

const languageForPath = (path: string) => {
    const extension = path.split('.').pop()?.toLowerCase();
    if (extension === 'tsx') return 'tsx';
    if (extension === 'ts') return 'typescript';
    if (extension === 'jsx') return 'jsx';
    if (extension === 'js' || extension === 'mjs' || extension === 'cjs') return 'javascript';
    if (extension === 'css' || extension === 'scss' || extension === 'less') return 'css';
    if (extension === 'json') return 'json';
    if (extension === 'md' || extension === 'markdown') return 'markdown';
    if (extension === 'rs') return 'rust';
    if (extension === 'java') return 'java';
    if (extension === 'py') return 'python';
    if (extension === 'sql') return 'sql';
    if (extension === 'yml' || extension === 'yaml') return 'yaml';
    return 'text';
};

const lineGap = (previous: DiffHunk | undefined, next: DiffHunk) => {
    if (!previous) return Math.max(next.oldStart, next.newStart) - 1;
    const oldEnd = previous.oldStart + previous.oldCount;
    const newEnd = previous.newStart + previous.newCount;
    return Math.max(next.oldStart - oldEnd, next.newStart - newEnd, 0);
};

const CodeText: React.FC<{ value: string; path: string }> = ({ value, path }) => (
    <SyntaxHighlighter
        language={languageForPath(path)}
        style={oneDark}
        PreTag="span"
        CodeTag="span"
        customStyle={{ display: 'inline', margin: 0, padding: 0, background: 'transparent', fontFamily: 'inherit', fontSize: 'inherit', lineHeight: 'inherit' }}
    >
        {value || ' '}
    </SyntaxHighlighter>
);

const DiffRow: React.FC<{ line: DiffLine; path: string }> = ({ line, path }) => {
    const isAddition = line.kind === 'addition';
    const isDeletion = line.kind === 'deletion';
    return <div className={`group flex min-w-max text-[11px] leading-5 ${isAddition ? 'bg-[#183522]' : isDeletion ? 'bg-[#482025]' : 'bg-[#171717]'}`}>
        <span className={`w-12 shrink-0 select-none border-r border-[#2d2d2d] px-2 text-right text-[10px] ${isAddition ? 'bg-[#1d412b] text-[#7ee2a8]' : isDeletion ? 'bg-[#5a252c] text-[#ff8d94]' : 'text-[#777]'}`}>{line.oldLine || ''}</span>
        <span className={`w-12 shrink-0 select-none border-r border-[#2d2d2d] px-2 text-right text-[10px] ${isAddition ? 'bg-[#1d412b] text-[#7ee2a8]' : isDeletion ? 'bg-[#5a252c] text-[#ff8d94]' : 'text-[#777]'}`}>{line.newLine || ''}</span>
        <span className={`w-6 shrink-0 select-none text-center font-semibold ${isAddition ? 'text-[#7ee2a8]' : isDeletion ? 'text-[#ff8d94]' : 'text-[#666]'}`}>{isAddition ? '+' : isDeletion ? '-' : ' '}</span>
        <code className={`whitespace-pre px-2 font-mono ${isAddition ? 'text-[#c4f5d4]' : isDeletion ? 'text-[#ffc4c8]' : 'text-[#d4d4d4]'}`}><CodeText value={line.content} path={path} /></code>
    </div>;
};

interface DiffFileProps {
    file: ParsedFileDiff;
    additions?: number;
    deletions?: number;
    fileId: string;
    isCollapsed: boolean;
    onToggle: () => void;
}

const DiffFile: React.FC<DiffFileProps> = ({ file, additions, deletions, fileId, isCollapsed, onToggle }) => {
    const displayAdditions = additions ?? file.additions;
    const displayDeletions = deletions ?? file.deletions;
    return <section className="overflow-hidden rounded-xl border border-[#303030] bg-[#171717] shadow-[0_8px_24px_rgba(0,0,0,0.18)]">
        <div className="flex min-w-0 items-center gap-2 border-b border-[#343434] bg-[#232323] px-3 py-2.5">
            <button type="button" onClick={onToggle} aria-expanded={!isCollapsed} aria-controls={fileId} className="flex min-w-0 flex-1 items-center gap-2 text-left hover:text-white">
                {isCollapsed ? <ChevronDown size={14} className="shrink-0 text-[#9c9c9c]" /> : <ChevronUp size={14} className="shrink-0 text-[#9c9c9c]" />}
                <FileCode2 size={15} className="shrink-0 text-[#61dafb]" />
                <span className="min-w-0 truncate font-mono text-[12px] text-[#e7e7e7]" title={file.path}>{file.path}</span>
            </button>
            <span className="shrink-0 text-[12px] font-medium text-[#55d17d]">+{displayAdditions}</span>
            <span className="shrink-0 text-[12px] font-medium text-[#ff6670]">-{displayDeletions}</span>
        </div>
        {!isCollapsed && <div id={fileId} className="max-h-[calc(100vh-330px)] overflow-auto py-1">
            {file.hunks.map((hunk, index) => {
                const previous = file.hunks[index - 1];
                const gap = lineGap(previous, hunk);
                return <React.Fragment key={`${file.path}-${hunk.header}`}>
                    {gap > 0 && <div className="mx-1 my-1 flex h-8 items-center rounded-lg bg-[#303030] text-[11px] text-[#b5b5b5]"><span className="flex w-24 items-center justify-center text-[#9c9c9c]"><ChevronUp size={14} /></span><span>{gap} unmodified lines</span></div>}
                    <div className="border-y border-[#282828] bg-[#202020] px-3 py-1 font-mono text-[10px] text-[#8eb8d8]">{hunk.header}</div>
                    {hunk.lines.map((line, lineIndex) => <DiffRow key={`${hunk.header}-${lineIndex}`} line={line} path={file.path} />)}
                </React.Fragment>;
            })}
        </div>}
    </section>;
};

const GitDiffViewer: React.FC<GitDiffViewerProps> = ({ patch, filePath = '变更文件', additions, deletions, truncated, summary }) => {
    const files = useMemo(() => parsePatch(patch, filePath), [filePath, patch]);
    const fileIds = useMemo(() => files.map((file, index) => `git-diff-file-${index}-${file.path.replace(/[^a-zA-Z0-9_-]/g, '-')}`), [files]);
    const [collapsedFiles, setCollapsedFiles] = useState<Set<string>>(new Set());
    if (files.length === 0) return null;
    const allCollapsed = files.every((_, index) => collapsedFiles.has(fileIds[index]));
    const toggleAllFiles = () => setCollapsedFiles(allCollapsed ? new Set() : new Set(fileIds));
    const collapseActionLabel = allCollapsed ? '全部展开' : '全部折叠';
    return <div className="space-y-2">
        {truncated && <div className="rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-[10px] text-amber-700">Diff 内容较大，当前仅展示截断后的变更。</div>}
        {summary && <div className="min-w-0 rounded-xl border border-slate-200 bg-white px-3 py-2.5">
            <div className="min-w-0">
                <div className="text-xs font-semibold text-slate-800">{summary.title}</div>
                <div className="mt-0.5 text-[10px] text-slate-400">{summary.subtitle}</div>
            </div>
            <div className="mt-2 flex min-w-0 flex-wrap items-center justify-start gap-x-3 gap-y-1">
                <span className="shrink-0 text-[10px] text-slate-500">{summary.fileCount} 个文件</span>
                <span className="shrink-0 text-[11px] font-medium text-emerald-600">+{summary.additions}</span>
                <span className="shrink-0 text-[11px] font-medium text-red-500">-{summary.deletions}</span>
                <label className="flex shrink-0 items-center gap-1 text-[10px] text-slate-500"><input type="checkbox" checked={summary.staged} onChange={(event) => summary.onStagedChange(event.target.checked)} />已暂存</label>
                <button type="button" onClick={toggleAllFiles} className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-slate-100 text-slate-500 transition hover:bg-slate-200 hover:text-slate-700 focus:outline-none focus:ring-2 focus:ring-slate-300" aria-label={collapseActionLabel} title={collapseActionLabel}><ListCollapse size={16} strokeWidth={1.8} /></button>
            </div>
        </div>}
        {files.map((file, index) => {
            const fileId = fileIds[index];
            return <DiffFile
                key={fileId}
                file={file}
                additions={files.length === 1 ? additions : undefined}
                deletions={files.length === 1 ? deletions : undefined}
                fileId={fileId}
                isCollapsed={collapsedFiles.has(fileId)}
                onToggle={() => setCollapsedFiles((current) => {
                    const next = new Set(current);
                    if (next.has(fileId)) next.delete(fileId);
                    else next.add(fileId);
                    return next;
                })}
            />;
        })}
    </div>;
};

export default GitDiffViewer;
