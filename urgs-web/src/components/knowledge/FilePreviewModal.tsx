import React, { useState, useEffect, useCallback, useRef } from 'react';
import { createPortal } from 'react-dom';
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
import * as XLSX from 'xlsx';
import mammoth from 'mammoth/mammoth.browser';
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

// ==================== Excel 预览 ====================
const SpreadsheetPreview: React.FC<{ url: string }> = ({ url }) => {
    const [sheets, setSheets] = useState<Array<{ name: string; html: string }>>([]);
    const [activeSheet, setActiveSheet] = useState(0);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        setLoading(true);
        setError(null);
        setSheets([]);
        setActiveSheet(0);

        fetch(url)
            .then(res => {
                if (!res.ok) throw new Error('加载失败');
                return res.arrayBuffer();
            })
            .then(buffer => {
                const workbook = XLSX.read(buffer, { type: 'array' });
                const nextSheets = workbook.SheetNames.map(name => ({
                    name,
                    html: XLSX.utils.sheet_to_html(workbook.Sheets[name], { id: `sheet-${name}` }),
                }));
                setSheets(nextSheets);
                setLoading(false);
            })
            .catch(() => {
                setError('Excel 文件加载失败');
                setLoading(false);
            });
    }, [url]);

    if (loading) {
        return (
            <div className="flex items-center justify-center h-full">
                <Spin size="large" />
            </div>
        );
    }

    if (error) {
        return <div className="flex items-center justify-center h-full text-white/70">{error}</div>;
    }

    return (
        <div className="w-full h-full bg-white rounded-xl overflow-hidden flex flex-col">
            <div className="flex items-center gap-2 px-4 py-2 border-b border-slate-200 overflow-x-auto bg-slate-50">
                {sheets.map((sheet, index) => (
                    <button
                        key={sheet.name}
                        onClick={() => setActiveSheet(index)}
                        className={`px-3 py-1.5 rounded-lg text-xs font-bold whitespace-nowrap transition-colors ${
                            activeSheet === index
                                ? 'bg-blue-600 text-white'
                                : 'bg-white text-slate-500 hover:text-blue-600 border border-slate-200'
                        }`}
                    >
                        {sheet.name}
                    </button>
                ))}
            </div>
            <div
                className="flex-1 overflow-auto p-4 text-sm [&_table]:border-collapse [&_td]:border [&_td]:border-slate-200 [&_td]:px-2 [&_td]:py-1 [&_td]:align-top [&_td]:whitespace-pre [&_th]:border [&_th]:border-slate-200 [&_th]:bg-slate-50 [&_th]:px-2 [&_th]:py-1"
                dangerouslySetInnerHTML={{ __html: sheets[activeSheet]?.html || '' }}
            />
        </div>
    );
};

// ==================== Word 预览 ====================
const WordPreview: React.FC<{ url: string; fileName: string; onDownload: () => void }> = ({ url, fileName, onDownload }) => {
    const [html, setHtml] = useState<string | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const isDocx = fileName.toLowerCase().endsWith('.docx');

    useEffect(() => {
        setHtml(null);
        setError(null);
        setLoading(true);

        if (!isDocx) {
            setError('DOC 旧格式暂不支持本地解析，请下载或用 Office 在线方式打开。');
            setLoading(false);
            return;
        }

        fetch(url)
            .then(res => {
                if (!res.ok) throw new Error('加载失败');
                return res.arrayBuffer();
            })
            .then(buffer => mammoth.convertToHtml({ arrayBuffer: buffer }))
            .then(result => {
                setHtml(result.value);
                setLoading(false);
            })
            .catch(() => {
                setError('Word 文件加载失败');
                setLoading(false);
            });
    }, [url, isDocx]);

    if (loading) {
        return (
            <div className="flex items-center justify-center h-full">
                <Spin size="large" />
            </div>
        );
    }

    if (error) {
        return (
            <div className="flex flex-col items-center justify-center h-full gap-4 text-white/70">
                <p>{error}</p>
                <button
                    onClick={onDownload}
                    className="px-5 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium transition-all flex items-center gap-2"
                >
                    <Download size={16} />
                    下载文件
                </button>
            </div>
        );
    }

    return (
        <div className="w-full h-full overflow-auto bg-slate-100 rounded-xl p-6">
            <div
                className="max-w-5xl mx-auto min-h-full bg-white shadow-sm rounded-lg px-12 py-10 text-slate-800 leading-7 [&_table]:border-collapse [&_td]:border [&_td]:border-slate-300 [&_td]:px-2 [&_td]:py-1 [&_img]:max-w-full"
                dangerouslySetInnerHTML={{ __html: html || '' }}
            />
        </div>
    );
};

// ==================== Office 在线预览 ====================
const OfficeOnlinePreview: React.FC<{ url: string; fileName: string; onDownload: () => void }> = ({ url, fileName, onDownload }) => {
    const absoluteUrl = new URL(url, window.location.origin).href;
    const viewerUrl = `https://view.officeapps.live.com/op/embed.aspx?src=${encodeURIComponent(absoluteUrl)}`;

    return (
        <div className="w-full h-full bg-white rounded-xl overflow-hidden relative">
            <iframe
                src={viewerUrl}
                className="w-full h-full bg-white"
                title={`${fileName} Preview`}
            />
            {(absoluteUrl.includes('localhost') || absoluteUrl.includes('127.0.0.1')) && (
                <div className="absolute bottom-4 left-1/2 -translate-x-1/2 max-w-xl rounded-xl bg-slate-900/85 px-4 py-3 text-xs text-white/80 shadow-lg backdrop-blur">
                    Office 在线预览需要外部服务能访问文件地址；本地 localhost 环境如无法显示，请下载后打开。
                    <button className="ml-3 text-blue-300 hover:text-blue-200 font-bold" onClick={onDownload}>
                        下载
                    </button>
                </div>
            )}
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
            <div className="w-full h-full overflow-auto bg-slate-100 rounded-xl p-6">
                <div className="max-w-5xl mx-auto min-h-full bg-white rounded-xl shadow-sm px-10 py-8 text-slate-800">
                    <ReactMarkdown
                        remarkPlugins={[remarkGfm]}
                        components={{
                            h1: ({ children }) => <h1 className="mt-0 mb-6 border-b border-slate-200 pb-3 text-3xl font-black text-slate-900">{children}</h1>,
                            h2: ({ children }) => <h2 className="mt-8 mb-4 border-b border-slate-100 pb-2 text-2xl font-extrabold text-slate-900">{children}</h2>,
                            h3: ({ children }) => <h3 className="mt-6 mb-3 text-xl font-bold text-slate-900">{children}</h3>,
                            h4: ({ children }) => <h4 className="mt-5 mb-2 text-base font-bold text-slate-800">{children}</h4>,
                            p: ({ children }) => <p className="my-3 text-sm leading-7 text-slate-700">{children}</p>,
                            a: ({ children, href }) => <a className="font-medium text-blue-600 underline underline-offset-2 hover:text-blue-700" href={href} target="_blank" rel="noreferrer">{children}</a>,
                            ul: ({ children }) => <ul className="my-3 list-disc space-y-1 pl-6 text-sm leading-7 text-slate-700">{children}</ul>,
                            ol: ({ children }) => <ol className="my-3 list-decimal space-y-1 pl-6 text-sm leading-7 text-slate-700">{children}</ol>,
                            li: ({ children }) => <li className="pl-1">{children}</li>,
                            blockquote: ({ children }) => <blockquote className="my-4 border-l-4 border-blue-300 bg-blue-50 px-4 py-2 text-sm text-slate-700">{children}</blockquote>,
                            hr: () => <hr className="my-8 border-slate-200" />,
                            table: ({ children }) => <div className="my-5 overflow-auto rounded-lg border border-slate-200"><table className="min-w-full border-collapse text-sm">{children}</table></div>,
                            thead: ({ children }) => <thead className="bg-slate-50 text-left text-slate-700">{children}</thead>,
                            th: ({ children }) => <th className="border-b border-slate-200 px-3 py-2 font-bold">{children}</th>,
                            td: ({ children }) => <td className="border-t border-slate-100 px-3 py-2 align-top text-slate-700">{children}</td>,
                            code: ({ className, children }) => {
                                const match = /language-(\w+)/.exec(className || '');
                                if (match) {
                                    return (
                                        <SyntaxHighlighter
                                            language={match[1]}
                                            style={oneLight}
                                            customStyle={{ margin: '16px 0', borderRadius: '0.75rem', fontSize: '13px' }}
                                        >
                                            {String(children).replace(/\n$/, '')}
                                        </SyntaxHighlighter>
                                    );
                                }
                                return <code className="rounded bg-slate-100 px-1.5 py-0.5 font-mono text-[12px] text-rose-600">{children}</code>;
                            },
                            pre: ({ children }) => <>{children}</>,
                        }}
                    >
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

            case 'spreadsheet':
                return <SpreadsheetPreview url={fileUrl} />;

            case 'word':
                return (
                    <WordPreview
                        url={fileUrl}
                        fileName={fileName}
                        onDownload={() => onDownload(doc)}
                    />
                );

            case 'presentation':
                return (
                    <OfficeOnlinePreview
                        url={fileUrl}
                        fileName={fileName}
                        onDownload={() => onDownload(doc)}
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

    const previewModal = (
        <AnimatePresence>
            {open && doc && (
                <motion.div
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    transition={{ duration: 0.2 }}
                    className="fixed inset-0 z-[1000] bg-black/80 backdrop-blur-sm flex flex-col"
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

    return createPortal(previewModal, document.body);
};

export default FilePreviewModal;
