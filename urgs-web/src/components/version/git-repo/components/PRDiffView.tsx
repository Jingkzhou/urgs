import React, { useState, useMemo } from 'react';
import { ChevronDown, ChevronRight, FileCode, Copy, Check } from 'lucide-react';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { oneLight } from 'react-syntax-highlighter/dist/esm/styles/prism';

interface PRDiffViewProps {
    files: {
        name: string;
        status: 'added' | 'modified' | 'deleted' | 'renamed';
        additions: number;
        deletions: number;
        diff?: string;
    }[];
}

interface DiffLine {
    type: 'hunk' | 'normal' | 'add' | 'del';
    content: string;
    oldLineNo?: number;
    newLineNo?: number;
}

const getLanguage = (filename: string): string => {
    const ext = filename.split('.').pop()?.toLowerCase();
    switch (ext) {
        case 'ts':
        case 'tsx':
            return 'typescript';
        case 'js':
        case 'jsx':
            return 'javascript';
        case 'java':
            return 'java';
        case 'py':
            return 'python';
        case 'sql':
            return 'sql';
        case 'html':
            return 'html';
        case 'css':
            return 'css';
        case 'json':
            return 'json';
        case 'md':
            return 'markdown';
        case 'yml':
        case 'yaml':
            return 'yaml';
        case 'xml':
            return 'xml';
        case 'sh':
        case 'bash':
            return 'bash';
        default:
            return 'text';
    }
};

// Utility to parse unified diff string into lines with line numbers
const parseDiff = (diff: string): DiffLine[] => {
    if (!diff) return [];
    const lines = diff.split('\n');
    const result: DiffLine[] = [];
    let oldLine = 0;
    let newLine = 0;
    let inHunk = false;

    for (const line of lines) {
        if (line.startsWith('@@')) {
            inHunk = true;
            // Parse hunk header: @@ -oldStart,oldCount +newStart,newCount @@
            const match = line.match(/@@ \-(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@/);
            if (match) {
                oldLine = parseInt(match[1], 10) - 1; // -1 because we increment before using for content lines
                newLine = parseInt(match[2], 10) - 1;
            }
            result.push({ type: 'hunk', content: line });
        } else if (inHunk) {
            if (line.startsWith('+')) {
                newLine++;
                result.push({ type: 'add', content: line.substring(1), newLineNo: newLine });
            } else if (line.startsWith('-')) {
                oldLine++;
                result.push({ type: 'del', content: line.substring(1), oldLineNo: oldLine });
            } else if (!line.startsWith('\\')) { // Ignore "\ No newline at end of file"
                oldLine++;
                newLine++;
                result.push({ type: 'normal', content: line.substring(1), oldLineNo: oldLine, newLineNo: newLine });
            }
        }
    }
    return result;
};

const computeLineDiff = (oldLine: string, newLine: string) => {
    let prefixLen = 0;
    while (prefixLen < oldLine.length && prefixLen < newLine.length && oldLine[prefixLen] === newLine[prefixLen]) {
        prefixLen++;
    }

    let suffixLen = 0;
    while (
        suffixLen < oldLine.length - prefixLen &&
        suffixLen < newLine.length - prefixLen &&
        oldLine[oldLine.length - 1 - suffixLen] === newLine[newLine.length - 1 - suffixLen]
    ) {
        suffixLen++;
    }

    return {
        prefix: oldLine.substring(0, prefixLen),
        diff: oldLine.substring(prefixLen, oldLine.length - suffixLen),
        suffix: oldLine.substring(oldLine.length - suffixLen),
        newDiff: newLine.substring(prefixLen, newLine.length - suffixLen)
    };
};

const FileDiffCard: React.FC<{ file: PRDiffViewProps['files'][0] }> = ({ file }) => {
    const [expanded, setExpanded] = useState(true);
    // Parse lines and compute pairings for character diffs
    const { lines, pairings } = useMemo(() => {
        const parsedLines = parseDiff(file.diff || '');
        const pairMap = new Map<number, number>(); // delIdx -> addIdx

        for (let i = 0; i < parsedLines.length - 1; i++) {
            if (parsedLines[i].type === 'del' && parsedLines[i + 1].type === 'add') {
                // Found a potential pair (modification)
                pairMap.set(i, i + 1);
                pairMap.set(i + 1, i);
                i++; // Skip the next line as it's part of this pair
            }
        }
        return { lines: parsedLines, pairings: pairMap };
    }, [file.diff]);

    const language = useMemo(() => getLanguage(file.name), [file.name]);

    const renderCodeContent = (line: DiffLine, idx: number) => {
        const pairIdx = pairings.get(idx);
        let prefix = '', diffPart = '', suffix = '';

        // If this is part of a modified pair, compute character diff
        if (pairIdx !== undefined) {
            const otherLine = lines[pairIdx];
            // We need to re-compute diff on render because we need access to both lines. 
            // Ideally we'd optimize this but for UI purpose it's fast enough.
            if (line.type === 'del') {
                const diff = computeLineDiff(line.content, otherLine.content);
                prefix = diff.prefix;
                diffPart = diff.diff;
                suffix = diff.suffix;
            } else {
                const diff = computeLineDiff(otherLine.content, line.content);
                prefix = diff.prefix;
                diffPart = diff.newDiff;
                suffix = diff.suffix;
            }
        } else {
            // No pairing, treat whole line as content
            diffPart = line.content;
        }

        const commonStyle = {
            margin: 0,
            padding: 0,
            background: 'transparent',
            fontSize: 'inherit',
            lineHeight: 'inherit'
        };

        // If no diff part (empty line), render a space so line has height
        if (!prefix && !diffPart && !suffix) diffPart = ' ';

        return (
            <div className={line.type === 'hunk' ? 'text-blue-600/70 font-medium' : ''}>
                {line.type === 'hunk' ? (
                    line.content
                ) : (
                    <>
                        {prefix && (
                            <SyntaxHighlighter language={language} style={oneLight} customStyle={commonStyle} PreTag="span" codeTagProps={{ style: { background: 'transparent' } }}>
                                {prefix}
                            </SyntaxHighlighter>
                        )}
                        {diffPart && (
                            <span className={line.type === 'add' ? 'bg-green-200/60' : line.type === 'del' ? 'bg-red-200/60' : ''}>
                                <SyntaxHighlighter language={language} style={oneLight} customStyle={commonStyle} PreTag="span" codeTagProps={{ style: { background: 'transparent' } }}>
                                    {diffPart}
                                </SyntaxHighlighter>
                            </span>
                        )}
                        {suffix && (
                            <SyntaxHighlighter language={language} style={oneLight} customStyle={commonStyle} PreTag="span" codeTagProps={{ style: { background: 'transparent' } }}>
                                {suffix}
                            </SyntaxHighlighter>
                        )}
                    </>
                )}
            </div>
        );
    };

    return (
        <div className="border border-slate-200 rounded-lg overflow-hidden bg-white shadow-sm mb-4">
            {/* Header */}
            <div
                className="bg-slate-50/80 px-4 py-2.5 border-b border-slate-200 flex justify-between items-center cursor-pointer hover:bg-slate-100/80 transition-colors"
                onClick={() => setExpanded(!expanded)}
            >
                <div className="flex items-center gap-3">
                    <button className="text-slate-500 hover:text-slate-700 transition-transform duration-200" style={{ transform: expanded ? 'rotate(0deg)' : 'rotate(-90deg)' }}>
                        <ChevronDown size={18} />
                    </button>
                    <span className="text-slate-500"><FileCode size={16} /></span>
                    <span className="font-mono text-sm font-semibold text-slate-700">{file.name}</span>
                    <span className={`text-xs px-2 py-0.5 rounded-full border ${file.status === 'added' ? 'bg-green-50 text-green-700 border-green-200' :
                        file.status === 'deleted' ? 'bg-red-50 text-red-700 border-red-200' :
                            'bg-blue-50 text-blue-700 border-blue-200'
                        }`}>
                        {file.status}
                    </span>
                </div>
                <div className="flex items-center gap-4 text-sm">
                    <div className="flex items-center gap-1 font-mono text-xs">
                        <span className="text-green-600 bg-green-50 px-1 rounded">+{file.additions}</span>
                        <span className="text-red-600 bg-red-50 px-1 rounded">-{file.deletions}</span>
                    </div>
                </div>
            </div>

            {/* Content */}
            {expanded && (
                <div className="overflow-x-auto">
                    {lines.length > 0 ? (
                        <table className="w-full text-xs font-mono border-collapse">
                            <tbody>
                                {lines.map((line, idx) => (
                                    <tr key={idx} className={
                                        line.type === 'add' ? 'bg-[#e6ffec] hover:bg-[#d0fcd9]' :
                                            line.type === 'del' ? 'bg-[#ffebe9] hover:bg-[#fcdbd9]' :
                                                line.type === 'hunk' ? 'bg-[#f0f9ff] text-slate-500' :
                                                    'hover:bg-slate-50'
                                    }>
                                        {/* Old Line Number */}
                                        <td className="w-[1%] min-w-[3rem] px-2 py-0.5 text-right text-slate-400 select-none border-r border-slate-100 bg-slate-50/30">
                                            {line.type !== 'add' && line.type !== 'hunk' && line.oldLineNo}
                                        </td>
                                        {/* New Line Number */}
                                        <td className="w-[1%] min-w-[3rem] px-2 py-0.5 text-right text-slate-400 select-none border-r border-slate-100 bg-slate-50/30">
                                            {line.type !== 'del' && line.type !== 'hunk' && line.newLineNo}
                                        </td>
                                        {/* Code Content */}
                                        <td className="px-4 py-0.5 whitespace-pre break-all relative group text-left">
                                            {line.type === 'add' && <span className="absolute left-1 text-green-600 select-none">+</span>}
                                            {line.type === 'del' && <span className="absolute left-1 text-red-600 select-none">-</span>}
                                            {renderCodeContent(line, idx)}
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    ) : (
                        <div className="p-8 text-center text-slate-400 italic bg-slate-50/30">
                            No visual changes (binary file or empty diff)
                        </div>
                    )}
                </div>
            )}
        </div>
    );
};

const PRDiffView: React.FC<PRDiffViewProps> = ({ files }) => {
    return (
        <div className="space-y-6">
            <div className="flex justify-between items-center pb-2">
                <h3 className="text-lg font-semibold text-slate-800">Files Changed ({files.length})</h3>
                <div className="text-sm text-slate-500 font-mono">
                    <span className="text-green-600 font-bold">+{files.reduce((acc, f) => acc + f.additions, 0)}</span> additions,
                    <span className="text-red-600 font-bold ml-2">-{files.reduce((acc, f) => acc + f.deletions, 0)}</span> deletions
                </div>
            </div>
            {files.map((file, index) => (
                <FileDiffCard key={index} file={file} />
            ))}
        </div>
    );
};

export default PRDiffView;
