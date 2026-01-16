import React, { useState, useMemo, useEffect } from 'react';
import {
    X,
    ChevronDown,
    ChevronUp,
    CheckCircle2,
    AlertCircle,
    Loader2
} from 'lucide-react';
import { Progress, Button, Tooltip } from 'antd';
import { getFileIcon } from '../../utils/fileIcons';

export interface UploadFileItem {
    uid: string;
    name: string;
    size: number;
    status: 'uploading' | 'success' | 'error' | 'pending';
    progress: number; // 0-100
    speed?: string; // e.g. "1.2 MB/s"
    errorMsg?: string;
}

interface UploadProgressPanelProps {
    files: UploadFileItem[];
    visible: boolean;
    onClose: () => void;
}

export const UploadProgressPanel: React.FC<UploadProgressPanelProps> = ({
    files,
    visible,
    onClose
}) => {
    const [minimized, setMinimized] = useState(false);

    // Auto-expand when new files are added (if not explicitly minimized by user? 
    // actually simpler to just respect user choice, but maybe expand on initial appear)
    const [hasAppeared, setHasAppeared] = useState(false);

    useEffect(() => {
        if (visible && !hasAppeared) {
            setHasAppeared(true);
            setMinimized(false);
        }
        if (!visible) {
            setHasAppeared(false);
        }
    }, [visible, hasAppeared]);

    // Derived stats
    const totalFiles = files.length;
    const completedFiles = files.filter(f => f.status === 'success').length;
    const errorFiles = files.filter(f => f.status === 'error').length;
    const uploadingFiles = files.filter(f => f.status === 'uploading' || f.status === 'pending').length;

    // Calculate overall progress
    const overallProgress = useMemo(() => {
        if (totalFiles === 0) return 0;
        const totalProgress = files.reduce((acc, curr) => acc + curr.progress, 0);
        return Math.floor(totalProgress / totalFiles);
    }, [files, totalFiles]);

    // Sorting: Uploading > Pending > Error > Success
    const sortedFiles = useMemo(() => {
        return [...files].sort((a, b) => {
            const priority = { uploading: 0, pending: 1, error: 2, success: 3 };
            return priority[a.status] - priority[b.status];
        });
    }, [files]);

    if (!visible && files.length === 0) return null;

    // Helper to format size
    const formatSize = (bytes: number) => {
        if (bytes === 0) return '0 B';
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
    };

    return (
        <div
            className={`fixed bottom-6 left-6 z-50 bg-white shadow-2xl rounded-xl border border-slate-200 overflow-hidden transition-all duration-300 ease-in-out flex flex-col font-sans
                ${visible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-10 pointer-events-none'}
                ${minimized ? 'w-80 h-14' : 'w-96 max-h-[500px]'}
            `}
        >
            {/* Header */}
            <div
                className="h-14 bg-slate-50 border-b border-slate-100 flex items-center justify-between px-4 cursor-pointer hover:bg-slate-100 transition-colors"
                onClick={() => setMinimized(!minimized)}
            >
                <div className="flex items-center gap-3">
                    {uploadingFiles > 0 ? (
                        <div className="relative w-8 h-8 flex items-center justify-center">
                            <Progress
                                type="circle"
                                percent={overallProgress}
                                size={32}
                                showInfo={false}
                                strokeColor="#10b981"
                                railColor="#e2e8f0"
                                strokeWidth={8}
                            />
                            <div className="absolute text-[10px] font-bold text-emerald-600">
                                {Math.round(overallProgress)}
                            </div>
                        </div>
                    ) : (
                        <div className="w-8 h-8 rounded-full bg-emerald-100 flex items-center justify-center text-emerald-600">
                            {errorFiles > 0 ? <AlertCircle size={18} className="text-red-500" /> : <CheckCircle2 size={18} />}
                        </div>
                    )}

                    <div className="flex flex-col">
                        <span className="text-sm font-bold text-slate-800 leading-tight">
                            {uploadingFiles > 0 ? '正在上传...' : (errorFiles > 0 ? '上传完成 (有错误)' : '上传完成')}
                        </span>
                        <span className="text-xs text-slate-500">
                            {completedFiles}/{totalFiles} 个文件
                        </span>
                    </div>
                </div>

                <div className="flex items-center gap-1">
                    <Button
                        type="text"
                        size="small"
                        icon={minimized ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
                        onClick={(e) => { e.stopPropagation(); setMinimized(!minimized); }}
                        className="text-slate-400 hover:text-slate-600 hover:bg-slate-200/50"
                    />
                    <Button
                        type="text"
                        size="small"
                        icon={<X size={16} />}
                        onClick={(e) => { e.stopPropagation(); onClose(); }}
                        className="text-slate-400 hover:text-red-500 hover:bg-red-50"
                    />
                </div>
            </div>

            {/* List */}
            {!minimized && (
                <div className="flex-1 overflow-y-auto p-2 bg-white scrollbar-thin scrollbar-thumb-slate-200 scrollbar-track-transparent">
                    <div className="flex flex-col gap-2">
                        {sortedFiles.map(file => (
                            <div key={file.uid} className="flex items-center gap-3 p-3 rounded-lg hover:bg-slate-50 transition-colors border border-transparent hover:border-slate-100 group">
                                <div className="flex-shrink-0">
                                    {getFileIcon(file.name, 32)}
                                </div>
                                <div className="flex-1 min-w-0">
                                    <div className="flex items-center justify-between mb-1">
                                        <div className="flex items-center gap-2 max-w-[70%]">
                                            <span className="text-sm font-medium text-slate-700 truncate" title={file.name}>
                                                {file.name}
                                            </span>
                                        </div>
                                        <div className="text-xs font-mono text-slate-400">
                                            {file.status === 'uploading' ? (
                                                <span className="text-emerald-500 font-bold">{file.speed}</span>
                                            ) : (
                                                <span>{formatSize(file.size)}</span>
                                            )}
                                        </div>
                                    </div>

                                    <div className="relative h-1.5 w-full bg-slate-100 rounded-full overflow-hidden">
                                        <div
                                            className={`absolute top-0 left-0 h-full rounded-full transition-all duration-300
                                                ${file.status === 'error' ? 'bg-red-500' : 'bg-blue-500'}
                                                ${file.status === 'success' ? 'bg-emerald-500' : ''}
                                            `}
                                            style={{ width: `${file.progress}%` }}
                                        />
                                    </div>

                                    <div className="flex items-center justify-between mt-1 h-4">
                                        <span className={`text-[10px] uppercase font-bold tracking-wider
                                             ${file.status === 'error' ? 'text-red-500' : ''}
                                             ${file.status === 'success' ? 'text-emerald-500' : ''}
                                             ${file.status === 'uploading' ? 'text-blue-500' : 'text-slate-400'}
                                        `}>
                                            {file.status === 'error' ? 'Failed' :
                                                file.status === 'success' ? 'Completed' :
                                                    file.status === 'uploading' ? 'Uploading' : 'Pending'}
                                        </span>
                                        {file.status === 'error' && (
                                            <Tooltip title={file.errorMsg}>
                                                <AlertCircle size={12} className="text-red-500 cursor-help" />
                                            </Tooltip>
                                        )}
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            )}
        </div>
    );
};
