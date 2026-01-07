import React, { useState, useMemo } from 'react';
import { ChevronDown, ChevronRight, FileCode, Copy, Check } from 'lucide-react';

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

const FileDiffCard: React.FC<{ file: PRDiffViewProps['files'][0] }> = ({ file }) => {
    const [expanded, setExpanded] = useState(true);
    const lines = useMemo(() => parseDiff(file.diff || ''), [file.diff]);

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
                                        <td className="px-4 py-0.5 whitespace-pre break-all relative group">
                                            {line.type === 'add' && <span className="absolute left-1 text-green-600 select-none">+</span>}
                                            {line.type === 'del' && <span className="absolute left-1 text-red-600 select-none">-</span>}
                                            <span className={line.type === 'hunk' ? 'text-blue-600/70 font-medium' : 'text-slate-800'}>
                                                {line.content}
                                            </span>
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
