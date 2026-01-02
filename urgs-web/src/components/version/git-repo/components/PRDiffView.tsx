import React from 'react';
import { GitFileContent } from '@/api/version';
// Using react-syntax-highlighter (or similar logic) if available, or just simple diff display
// For now, creating a simple visual diff placeholder

interface PRDiffViewProps {
    files: {
        name: string;
        status: 'added' | 'modified' | 'deleted';
        additions: number;
        deletions: number;
        diff?: string; // Optional raw diff content
    }[];
}

const PRDiffView: React.FC<PRDiffViewProps> = ({ files }) => {
    return (
        <div className="space-y-4">
            {files.map((file, index) => (
                <div key={index} className="border border-slate-200 rounded-lg overflow-hidden bg-white">
                    {/* File Header */}
                    <div className="bg-slate-50 px-4 py-2 border-b border-slate-200 flex justify-between items-center">
                        <div className="flex items-center gap-2">
                            <span className="font-mono text-sm font-medium text-slate-700">{file.name}</span>
                            <span className="text-xs px-1.5 py-0.5 rounded border bg-slate-100 text-slate-500 border-slate-200">
                                {file.status}
                            </span>
                        </div>
                        <div className="text-xs font-mono">
                            <span className="text-green-600">+{file.additions}</span>
                            <span className="mx-1 text-slate-300">|</span>
                            <span className="text-red-600">-{file.deletions}</span>
                        </div>
                    </div>

                    {/* Diff Content (Placeholder for visual style) */}
                    <div className="overflow-x-auto text-sm font-mono bg-white p-0">
                        {/* Mock Diff Lines */}
                        {file.diff ? (
                            <pre className="p-4 m-0">{file.diff}</pre>
                        ) : (
                            <div className="p-4 text-slate-400 text-center italic">
                                Diff content would be rendered here via a diff library.
                            </div>
                        )}
                    </div>
                </div>
            ))}
        </div>
    );
};

export default PRDiffView;
