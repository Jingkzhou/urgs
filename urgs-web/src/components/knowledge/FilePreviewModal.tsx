import React, { useState, useEffect, useCallback, useRef } from 'react';
import { Spin } from 'antd';
import { motion, AnimatePresence } from 'framer-motion';
import {
    X, Download, ChevronLeft, ChevronRight,
    ZoomIn, ZoomOut, RotateCcw, Maximize2,
} from 'lucide-react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { oneLight } from 'react-syntax-highlighter/dist/esm/styles/prism';
import type { KnowledgeDocument } from '../../api/knowledge';
import { getPreviewType } from '../../utils/filePreview';
import { getFileIcon } from '../../utils/fileIcons';

interface FilePreviewModalProps {
    open: boolean;
    document: KnowledgeDocument | null;
    onClose: () => void;
    onDownload: (doc: KnowledgeDocument) => void;
    onNext?: () => void;
    onPrev?: () => void;
    hasNext?: boolean;
    hasPrev?: boolean;
}

// ==================== 图片预览 ====================
const ImagePreview: React.FC<{ url: string }> = ({ url }) => {
    const [scale, setScale] = useState(1);
    const [position, setPosition] = useState({ x: 0, y: 0 });
    const [dragging, setDragging] = useState(false);
    const dragStart = useRef({ x: 0, y: 0, posX: 0, posY: 0 });

    const handleWheel = (e: React.WheelEvent) => {
        e.stopPropagation();
        const delta = e.deltaY > 0 ? -0.15 : 0.15;
        setScale(prev => Math.min(5, Math.max(0.25, prev + delta)));
    };

    const handleMouseDown = (e: React.MouseEvent) => {
        if (scale <= 1) return;
        e.preventDefault();
        setDragging(true);
        dragStart.current = { x: e.clientX, y: e.clientY, posX: position.x, posY: position.y };
    };

    const handleMouseMove = (e: React.MouseEvent) => {
        if (!dragging) return;
        setPosition({
            x: dragStart.current.posX + (e.clientX - dragStart.current.x),
            y: dragStart.current.posY + (e.clientY - dragStart.current.y),
        });
    };

    const handleMouseUp = () => setDragging(false);

    const resetView = () => { setScale(1); setPosition({ x: 0, y: 0 }); };

    return (
        <div className="relative w-full h-full flex flex-col items-center justify-center">
            <div
                className="flex-1 w-full flex items-center justify-center overflow-hidden cursor-grab active:cursor-grabbing"
                onWheel={handleWheel}
                onMouseDown={handleMouseDown}
                onMouseMove={handleMouseMove}
                onMouseUp={handleMouseUp}
                onMouseLeave={handleMouseUp}
                onDoubleClick={resetView}
            >
                <img
                    src={url}
                    alt="preview"
                    className="max-w-full max-h-full object-contain select-none transition-transform duration-100"
                    style={{
                        transform: `scale(${scale}) translate(${position.x / scale}px, ${position.y / scale}px)`,
                    }}
                    draggable={false}
                />
            </div>
            {/* 缩放控制条 */}
            <div className="absolute bottom-6 left-1/2 -translate-x-1/2 bg-black/60 backdrop-blur-md rounded-full px-4 py-2 flex items-center gap-3">
                <button onClick={() => setScale(prev => Math.max(0.25, prev - 0.25))} className="text-white/80 hover:text-white transition-colors">
                    <ZoomOut size={18} />
                </button>
                <span className="text-white/80 text-xs font-mono min-w-[48px] text-center">
                    {Math.round(scale * 100)}%
                </span>
                <button onClick={() => setScale(prev => Math.min(5, prev + 0.25))} className="text-white/80 hover:text-white transition-colors">
                    <ZoomIn size={18} />
                </button>
                <div className="w-px h-4 bg-white/20"></div>
                <button onClick={resetView} className="text-white/80 hover:text-white transition-colors">
                    <RotateCcw size={16} />
                </button>
            </div>
        </div>
    );
};

// ==================== 文本内容预览 (代码/MD/纯文本) ====================
const TextContentPreview: React.FC<{
    url: string;
    kind: 'code' | 'markdown' | 'text';
    language?: string;
}> = ({ url, kind, language }) => {
    const [content, setContent] = useState<string | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        setLoading(true);
        setContent(null);
        fetch(url)
            .then(res => res.text())
            .then(text => { setContent(text); setLoading(false); })
            .catch(() => { setContent('加载失败'); setLoading(false); });
    }, [url]);

    if (loading) {
        return (
            <div className="flex items-center justify-center h-full">
                <Spin size="large" />
            </div>
        );
    }

    if (kind === 'markdown') {
        return (
            <div className="w-full h-full overflow-auto bg-white rounded-xl p-8">
                <div className="prose prose-slate max-w-4xl mx-auto">
                    <ReactMarkdown remarkPlugins={[remarkGfm]}>
                        {content || ''}
                    </ReactMarkdown>
                </div>
            </div>
        );
    }

    if (kind === 'code') {
        return (
            <div className="w-full h-full overflow-auto rounded-xl">
                <SyntaxHighlighter
                    language={language || 'text'}
                    style={oneLight}
                    showLineNumbers
                    customStyle={{
                        margin: 0,
                        borderRadius: '0.75rem',
                        fontSize: '13px',
                        minHeight: '100%',
                    }}
                >
                    {content || ''}
                </SyntaxHighlighter>
            </div>
        );
    }

    // 纯文本
    return (
        <div className="w-full h-full overflow-auto bg-white rounded-xl p-6">
            <pre className="font-mono text-sm text-slate-700 whitespace-pre-wrap break-words">
                {content}
            </pre>
        </div>
    );
};

// ==================== 不支持预览 ====================
const UnsupportedPreview: React.FC<{
    fileName: string;
    fileSize: number | null;
    onDownload: () => void;
}> = ({ fileName, fileSize, onDownload }) => {
    const formatSize = (bytes: number) => {
        if (bytes === 0) return '0 B';
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
    };

    return (
        <div className="flex flex-col items-center justify-center h-full gap-6">
            <div className="w-24 h-24 bg-slate-100 rounded-2xl flex items-center justify-center">
                {getFileIcon(fileName, 48)}
            </div>
            <div className="text-center">
                <p className="text-white/90 text-lg font-medium mb-1">{fileName}</p>
                {fileSize && <p className="text-white/50 text-sm">{formatSize(fileSize)}</p>}
            </div>
            <p className="text-white/40 text-sm">该文件类型不支持在线预览</p>
            <button
                onClick={onDownload}
                className="px-6 py-2.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium shadow-lg transition-all flex items-center gap-2"
            >
                <Download size={18} />
                下载文件
            </button>
        </div>
    );
};

// ==================== 主组件 ====================
const FilePreviewModal: React.FC<FilePreviewModalProps> = ({
    open, document: doc, onClose, onDownload,
    onNext, onPrev, hasNext, hasPrev,
}) => {
    // 键盘导航
    const handleKeyDown = useCallback((e: KeyboardEvent) => {
        if (e.key === 'Escape') onClose();
        if (e.key === 'ArrowRight' && hasNext && onNext) onNext();
        if (e.key === 'ArrowLeft' && hasPrev && onPrev) onPrev();
    }, [onClose, onNext, onPrev, hasNext, hasPrev]);

    useEffect(() => {
        if (open) {
            window.addEventListener('keydown', handleKeyDown);
            return () => window.removeEventListener('keydown', handleKeyDown);
        }
    }, [open, handleKeyDown]);

    const fileName = doc?.fileName || doc?.title || '';
    const fileUrl = doc?.fileUrl || '';
    const previewType = fileName ? getPreviewType(fileName) : { kind: 'unsupported' as const };

    const renderPreview = () => {
        if (!doc || !fileUrl) return null;

        switch (previewType.kind) {
            case 'image':
                return <ImagePreview url={fileUrl} />;

            case 'pdf':
                return (
                    <iframe
                        src={fileUrl}
                        className="w-full h-full rounded-xl bg-white"
                        title="PDF Preview"
                    />
                );

            case 'video':
                return (
                    <div className="flex items-center justify-center h-full">
                        <video
                            controls
                            autoPlay
                            src={fileUrl}
                            className="max-w-full max-h-full rounded-xl shadow-2xl"
                        />
                    </div>
                );

            case 'audio':
                return (
                    <div className="flex flex-col items-center justify-center h-full gap-8">
                        <div className="w-32 h-32 bg-white/10 rounded-3xl flex items-center justify-center backdrop-blur">
                            {getFileIcon(fileName, 64)}
                        </div>
                        <p className="text-white/80 text-lg font-medium">{fileName}</p>
                        <audio controls src={fileUrl} className="w-96 max-w-full" />
                    </div>
                );

            case 'code':
                return <TextContentPreview url={fileUrl} kind="code" language={previewType.language} />;

            case 'markdown':
                return <TextContentPreview url={fileUrl} kind="markdown" />;

            case 'text':
                return <TextContentPreview url={fileUrl} kind="text" />;

            case 'unsupported':
                return (
                    <UnsupportedPreview
                        fileName={fileName}
                        fileSize={doc.fileSize}
                        onDownload={() => onDownload(doc)}
                    />
                );
        }
    };

    return (
        <AnimatePresence>
            {open && doc && (
                <motion.div
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    transition={{ duration: 0.2 }}
                    className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex flex-col"
                    onClick={onClose}
                >
                    {/* 顶部栏 */}
                    <div
                        className="h-14 flex items-center justify-between px-6 flex-shrink-0"
                        onClick={(e) => e.stopPropagation()}
                    >
                        <div className="flex-1" />
                        <p className="text-white/90 text-sm font-medium truncate max-w-md text-center">
                            {fileName}
                        </p>
                        <div className="flex-1 flex items-center justify-end gap-2">
                            <button
                                onClick={() => doc && onDownload(doc)}
                                className="p-2 rounded-lg text-white/60 hover:text-white hover:bg-white/10 transition-all"
                                title="下载"
                            >
                                <Download size={18} />
                            </button>
                            <button
                                onClick={onClose}
                                className="p-2 rounded-lg text-white/60 hover:text-white hover:bg-white/10 transition-all"
                                title="关闭 (Esc)"
                            >
                                <X size={18} />
                            </button>
                        </div>
                    </div>

                    {/* 内容区 */}
                    <motion.div
                        initial={{ opacity: 0, scale: 0.96 }}
                        animate={{ opacity: 1, scale: 1 }}
                        exit={{ opacity: 0, scale: 0.96 }}
                        transition={{ duration: 0.2, ease: 'easeOut' }}
                        className="flex-1 mx-6 mb-6 overflow-hidden"
                        onClick={(e) => e.stopPropagation()}
                    >
                        {renderPreview()}
                    </motion.div>

                    {/* 左右导航箭头 */}
                    {hasPrev && (
                        <button
                            onClick={(e) => { e.stopPropagation(); onPrev?.(); }}
                            className="fixed left-4 top-1/2 -translate-y-1/2 p-3 rounded-full bg-black/40 text-white/70 hover:text-white hover:bg-black/60 transition-all backdrop-blur-sm"
                        >
                            <ChevronLeft size={24} />
                        </button>
                    )}
                    {hasNext && (
                        <button
                            onClick={(e) => { e.stopPropagation(); onNext?.(); }}
                            className="fixed right-4 top-1/2 -translate-y-1/2 p-3 rounded-full bg-black/40 text-white/70 hover:text-white hover:bg-black/60 transition-all backdrop-blur-sm"
                        >
                            <ChevronRight size={24} />
                        </button>
                    )}
                </motion.div>
            )}
        </AnimatePresence>
    );
};

export default FilePreviewModal;
