import React, { useState, useEffect, useRef } from 'react';
import { MoreHorizontal, Paperclip, Mic, Send, Image, ZoomIn, ZoomOut, RotateCw, Download, X, Copy } from 'lucide-react';
import { message as antdMessage } from 'antd';
import { getAvatarUrl } from '../../utils/avatarUtils';
import { copyToClipboard } from '../../utils/clipboard';

interface Message {
    id: number;
    senderId: number;
    content: string;
    type: 'text' | 'image' | 'file';
    time: string;
    isSelf: boolean;
    senderName?: string;
    senderAvatar?: string;
}

interface ChatWindowProps {
    sessionName: string;
    messages: Message[];
    onSendMessage: (content: string, type?: 'text' | 'image' | 'file') => void;
    onFileUpload?: (file: File) => Promise<string>;
    onShowDetails?: () => void;
}

interface ContextMenuState {
    x: number;
    y: number;
    message?: Message;
}

interface FilePayload {
    url: string;
    name: string;
    size?: number;
    mimeType?: string;
}

const ChatWindow: React.FC<ChatWindowProps> = ({ sessionName, messages, onSendMessage, onFileUpload, onShowDetails }) => {
    const [inputValue, setInputValue] = useState('');
    const messagesEndRef = useRef<HTMLDivElement>(null);
    const imageInputRef = useRef<HTMLInputElement>(null);
    const fileInputRef = useRef<HTMLInputElement>(null);
    const [previewImage, setPreviewImage] = useState<string | null>(null);
    const [contextMenu, setContextMenu] = useState<ContextMenuState | null>(null);

    // Image Preview State
    const [scale, setScale] = useState(1);
    const [rotate, setRotate] = useState(0);
    const [position, setPosition] = useState({ x: 0, y: 0 });
    const [isDragging, setIsDragging] = useState(false);
    const [dragStart, setDragStart] = useState({ x: 0, y: 0 });

    const isFirstScroll = useRef(true);

    const scrollToBottom = (instant = false) => {
        if (instant) {
            messagesEndRef.current?.scrollIntoView({ behavior: 'auto' });
        } else {
            // Small timeout for subsequent smooth scrolls to allow DOM layout (e.g., images) to partly complete
            setTimeout(() => {
                messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
            }, 100);
        }
    };

    // Use useLayoutEffect for immediate scrolling after DOM updates but before paint
    React.useLayoutEffect(() => {
        if (messages.length === 0) return;

        if (isFirstScroll.current) {
            scrollToBottom(true);
            isFirstScroll.current = false;
        } else {
            scrollToBottom(false);
        }
    }, [messages]);

    useEffect(() => {
        if (!previewImage) {
            // Reset state on close
            setScale(1);
            setRotate(0);
            setPosition({ x: 0, y: 0 });
        }
    }, [previewImage]);

    useEffect(() => {
        const closeContextMenu = () => setContextMenu(null);
        window.addEventListener('click', closeContextMenu);
        window.addEventListener('scroll', closeContextMenu, true);
        return () => {
            window.removeEventListener('click', closeContextMenu);
            window.removeEventListener('scroll', closeContextMenu, true);
        };
    }, []);

    const handleSend = () => {
        if (!inputValue.trim()) return;
        onSendMessage(inputValue, 'text');
        setInputValue('');
    };

    const formatFileSize = (size?: number) => {
        if (!size || size <= 0) return '';
        if (size < 1024) return `${size} B`;
        if (size < 1024 * 1024) return `${(size / 1024).toFixed(1)} KB`;
        return `${(size / 1024 / 1024).toFixed(1)} MB`;
    };

    const parseFilePayload = (content: string): FilePayload => {
        try {
            const payload = JSON.parse(content);
            if (payload?.url) {
                return {
                    url: payload.url,
                    name: payload.name || '文件',
                    size: payload.size,
                    mimeType: payload.mimeType
                };
            }
        } catch (e) {
            // Older file messages may only store the URL.
        }
        return { url: content, name: content.split('/').pop() || '文件' };
    };

    const handleUploadAndSend = async (file: File, type: 'image' | 'file') => {
        if (!onFileUpload) return;
        try {
            const url = await onFileUpload(file);
            if (type === 'image') {
                onSendMessage(url, 'image');
                return;
            }
            onSendMessage(JSON.stringify({
                url,
                name: file.name || '文件',
                size: file.size,
                mimeType: file.type
            }), 'file');
        } catch (err) {
            console.error('Upload failed', err);
            antdMessage.error(type === 'image' ? '图片上传失败' : '文件上传失败');
        }
    };

    // ... (File handling logic same as before, simplified for brevity in this view if needed, but keeping full)
    const handleKeyDown = (e: React.KeyboardEvent) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            handleSend();
        }
    };

    // Image Viewer Handlers
    const handleZoomIn = (e?: React.MouseEvent) => {
        e?.stopPropagation();
        setScale(prev => Math.min(prev + 0.5, 4));
    };

    const handleZoomOut = (e?: React.MouseEvent) => {
        e?.stopPropagation();
        setScale(prev => Math.max(prev - 0.5, 0.5));
    };

    const handleRotate = (e?: React.MouseEvent) => {
        e?.stopPropagation();
        setRotate(prev => prev + 90);
    };

    const handleDownload = (e?: React.MouseEvent) => {
        e?.stopPropagation();
        if (!previewImage) return;
        const link = document.createElement('a');
        link.href = previewImage;
        link.download = `image_${Date.now()}.png`; // Simple download
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    };

    const handleWheel = (e: React.WheelEvent) => {
        e.stopPropagation();
        if (e.deltaY < 0) {
            setScale(prev => Math.min(prev + 0.1, 4));
        } else {
            setScale(prev => Math.max(prev - 0.1, 0.5));
        }
    };

    const handleMouseDown = (e: React.MouseEvent) => {
        e.preventDefault();
        setIsDragging(true);
        setDragStart({ x: e.clientX - position.x, y: e.clientY - position.y });
    };

    const handleMouseMove = (e: React.MouseEvent) => {
        if (!isDragging) return;
        e.preventDefault();
        setPosition({
            x: e.clientX - dragStart.x,
            y: e.clientY - dragStart.y
        });
    };

    const handleMouseUp = () => {
        setIsDragging(false);
    };

    const formatMessageForCopy = (msg: Message) => {
        const sender = msg.isSelf ? '我' : (msg.senderName || `User ${msg.senderId}`);
        const file = msg.type === 'file' ? parseFilePayload(msg.content) : null;
        const content = msg.type === 'image'
            ? `[图片] ${msg.content}`
            : msg.type === 'file'
                ? `[文件] ${file?.name} ${file?.url}`
                : msg.content;
        return `${msg.time ? `[${msg.time}] ` : ''}${sender}: ${content}`;
    };

    const handleOpenContextMenu = (e: React.MouseEvent, message?: Message) => {
        e.preventDefault();
        e.stopPropagation();
        setContextMenu({ x: e.clientX, y: e.clientY, message });
    };

    const handleCopyText = async (text: string) => {
        const success = await copyToClipboard(text);
        if (success) {
            antdMessage.success('已复制');
        } else {
            antdMessage.error('复制失败');
        }
        setContextMenu(null);
    };

    const handleCopyConversation = () => {
        const conversationText = messages.map(formatMessageForCopy).join('\n');
        handleCopyText(conversationText);
    };

    const renderMessageContent = (msg: Message, isSelf: boolean) => {
        if (msg.type === 'text') {
            return <p className="whitespace-pre-wrap break-all leading-relaxed">{msg.content}</p>;
        }
        if (msg.type === 'file') {
            const file = parseFilePayload(msg.content);
            return (
                <a
                    href={file.url}
                    download={file.name}
                    target="_blank"
                    rel="noreferrer"
                    className={`flex min-w-[220px] max-w-[320px] items-center gap-3 rounded-xl border p-3 transition-colors ${isSelf ? 'border-sky-100 bg-white/75 text-slate-800 hover:bg-white' : 'border-slate-200 bg-white text-slate-800 hover:bg-slate-50'}`}
                    onClick={(e) => e.stopPropagation()}
                >
                    <span className={`flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-lg ${isSelf ? 'bg-sky-100 text-sky-700' : 'bg-indigo-50 text-indigo-600'}`}>
                        <Paperclip size={18} />
                    </span>
                    <span className="min-w-0 flex-1">
                        <span className="block truncate text-[13px] font-medium">{file.name}</span>
                        <span className={`block text-[11px] ${isSelf ? 'text-slate-500' : 'text-slate-400'}`}>{formatFileSize(file.size) || '点击下载'}</span>
                    </span>
                    <Download size={16} className={isSelf ? 'text-slate-500' : 'text-slate-400'} />
                </a>
            );
        }
        return (
            <img
                src={msg.content}
                alt="Content"
                className={`rounded-lg max-w-full cursor-pointer hover:opacity-95 max-h-64 object-contain ${isSelf ? 'border border-sky-100 bg-white' : 'bg-white'}`}
                onDoubleClick={() => setPreviewImage(msg.content)}
            />
        );
    };

    // Default Avatar
    const defaultAvatar = getAvatarUrl(null, 'User');

    return (
        <div className="flex-1 bg-[#f3f5f8] flex flex-col relative h-full">
            {/* Header */}
            <div className="h-[68px] flex items-center justify-between px-6 z-10 border-b border-slate-200/70 bg-white/95 backdrop-blur-sm flex-shrink-0">
                <div className="flex items-center gap-3">
                    <h3 className="max-w-[360px] truncate font-semibold text-slate-800 text-[15px] tracking-tight" title={sessionName}>{sessionName}</h3>
                    <div className="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-pulse"></div>
                </div>
                {onShowDetails && (
                    <button onClick={onShowDetails} className="p-1.5 hover:bg-slate-100 rounded-md text-slate-400 hover:text-slate-600 transition-colors mr-8">
                        <MoreHorizontal size={18} />
                    </button>
                )}
            </div>

            {/* Messages */}
            <div className="flex-1 overflow-y-auto p-4 space-y-6 bg-[#f3f5f8]" onContextMenu={handleOpenContextMenu}>
                {messages.map((msg) => (
                    <div
                        key={msg.id}
                        className={`flex w-full ${msg.isSelf ? 'justify-end' : 'justify-start'} group animate-in fade-in slide-in-from-bottom-2 duration-300`}
                        onContextMenu={(e) => handleOpenContextMenu(e, msg)}
                    >
                        {/* Left Side (Other) */}
                        {!msg.isSelf && (
                            <>
                                <img
                                    src={getAvatarUrl(msg.senderAvatar, msg.senderName || `User ${msg.senderId}`)}
                                    className="w-9 h-9 rounded-xl mr-3 flex-shrink-0 cursor-pointer object-cover"
                                    alt="Avatar"
                                />
                                <div className="flex flex-col items-start max-w-[70%]">
                                    <span className="text-[11px] text-slate-400 mb-1 ml-1 opacity-0 group-hover:opacity-100 transition-opacity">{msg.senderName || `User ${msg.senderId}`} {msg.time && `· ${msg.time}`}</span>
                                    <div className="relative rounded-2xl rounded-tl-sm border border-slate-200 bg-white px-4 py-2.5 text-[14px] text-slate-800 shadow-sm">
                                        {renderMessageContent(msg, false)}
                                    </div>
                                </div>
                            </>
                        )}

                        {/* Right Side (Self) */}
                        {msg.isSelf && (
                            <>
                                <div className="flex flex-col items-end max-w-[70%]">
                                    {/* Time hidden unless hovered */}
                                    <span className="text-[11px] text-slate-400 mb-1 mr-1 opacity-0 group-hover:opacity-100 transition-opacity">{msg.time}</span>
                                    <div className="relative rounded-2xl rounded-tr-sm border border-sky-100 bg-[#dff1ff] px-4 py-2.5 text-[14px] text-slate-900 shadow-sm">
                                        {renderMessageContent(msg, true)}
                                    </div>
                                </div>
                                <img
                                    src={getAvatarUrl(msg.senderAvatar, msg.senderName || `User ${msg.senderId}`)}
                                    className="w-9 h-9 rounded-xl ml-3 flex-shrink-0 cursor-pointer object-cover"
                                    alt="Avatar"
                                />
                            </>
                        )}
                    </div>
                ))}
                <div ref={messagesEndRef} />
            </div>

            {contextMenu && (
                <div
                    className="fixed z-[80] min-w-[160px] overflow-hidden rounded-lg border border-slate-200 bg-white py-1 shadow-xl"
                    style={{ left: contextMenu.x, top: contextMenu.y }}
                    onClick={(e) => e.stopPropagation()}
                >
                    {contextMenu.message && (
                        <button
                            className="flex w-full items-center gap-2 px-3 py-2 text-left text-[13px] text-slate-700 hover:bg-slate-50"
                            onClick={() => handleCopyText(formatMessageForCopy(contextMenu.message!))}
                        >
                            <Copy size={14} className="text-slate-400" />
                            复制本条消息
                        </button>
                    )}
                    <button
                        className="flex w-full items-center gap-2 px-3 py-2 text-left text-[13px] text-slate-700 hover:bg-slate-50 disabled:cursor-not-allowed disabled:text-slate-300"
                        onClick={handleCopyConversation}
                        disabled={messages.length === 0}
                    >
                        <Copy size={14} className="text-slate-400" />
                        复制整个对话
                    </button>
                </div>
            )}

            {/* Input Area */}
            <div className="bg-white border-t border-slate-200/70 px-6 py-4 flex-shrink-0">
                <input
                    type="file"
                    ref={imageInputRef}
                    className="hidden"
                    accept="image/*"
                    onChange={async (e) => {
                        const file = e.target.files?.[0];
                        if (file) {
                            await handleUploadAndSend(file, 'image');
                        }
                        e.target.value = '';
                    }}
                />
                <input
                    type="file"
                    ref={fileInputRef}
                    className="hidden"
                    onChange={async (e) => {
                        const file = e.target.files?.[0];
                        if (file) {
                            await handleUploadAndSend(file, 'file');
                        }
                        e.target.value = '';
                    }}
                />
                
                {/* Toolbar */}
                <div className="flex gap-4 items-center mb-3 text-slate-400 px-1">
                    <button
                        onClick={() => imageInputRef.current?.click()}
                        className="hover:text-slate-600 transition-colors"
                        title="发送图片"
                    >
                        <Image size={20} strokeWidth={1.5} />
                    </button>
                    <button
                        onClick={() => fileInputRef.current?.click()}
                        className="hover:text-slate-600 transition-colors"
                        title="发送文件"
                    >
                        <Paperclip size={20} strokeWidth={1.5} />
                    </button>
                    <button className="hover:text-slate-600 transition-colors" title="语音消息">
                        <Mic size={20} strokeWidth={1.5} />
                    </button>
                </div>

                <div className="flex gap-4 items-end">
                    <textarea
                        value={inputValue}
                        onChange={(e) => setInputValue(e.target.value)}
                        onKeyDown={handleKeyDown}
                        onPaste={async (e) => {
                            const items = e.clipboardData.items;
                            for (let i = 0; i < items.length; i++) {
                                if (items[i].type.indexOf('image') !== -1) {
                                    const file = items[i].getAsFile();
                                    if (file) {
                                        await handleUploadAndSend(file, 'image');
                                    }
                                    e.preventDefault();
                                    return;
                                }
                            }
                        }}
                        placeholder="输入消息..."
                        className="flex-1 bg-transparent border-none outline-none text-[14px] text-slate-800 resize-none max-h-32 min-h-[44px] py-1 placeholder-slate-400"
                        rows={1}
                    />
                    <button
                        onClick={handleSend}
                        className={`${inputValue.trim() ? 'text-indigo-600 hover:text-indigo-700 hover:bg-indigo-50' : 'text-slate-300 cursor-not-allowed'} p-2 rounded-xl transition-all duration-200 flex items-center justify-center flex-shrink-0`}
                        disabled={!inputValue.trim()}
                        title="发送 (Enter)"
                    >
                        <Send size={22} strokeWidth={1.5} />
                    </button>
                </div>
            </div>

            {/* WeChat-style Image Viewer */}
            {previewImage && (
                <div
                    className="fixed inset-0 z-50 bg-black/95 flex flex-col items-center justify-center animate-in fade-in duration-200 select-none"
                    onClick={() => setPreviewImage(null)}
                    onWheel={handleWheel}
                >
                    {/* Header Controls */}
                    <div className="absolute top-0 w-full p-4 flex justify-between items-center z-50">
                        <span className="text-white/80 text-sm">Esc 关闭</span>
                        <button
                            className="text-white/70 hover:text-white p-2 rounded-full hover:bg-white/10 transition-colors"
                            onClick={(e) => { e.stopPropagation(); setPreviewImage(null); }}
                        >
                            <X size={24} />
                        </button>
                    </div>

                    {/* Image Area */}
                    <div
                        className="flex-1 w-full h-full flex items-center justify-center overflow-hidden cursor-move"
                        onClick={(e) => e.stopPropagation()} // Prevent close when clicking container
                        onMouseDown={handleMouseDown}
                        onMouseMove={handleMouseMove}
                        onMouseUp={handleMouseUp}
                        onMouseLeave={handleMouseUp}
                    >
                        <img
                            src={previewImage}
                            alt="Preview"
                            className="max-w-none transition-transform duration-75 ease-linear"
                            style={{
                                transform: `translate(${position.x}px, ${position.y}px) rotate(${rotate}deg) scale(${scale})`,
                            }}
                            draggable={false}
                        />
                    </div>

                    {/* Bottom Toolbar */}
                    <div
                        className="absolute bottom-8 flex gap-6 bg-white/10 backdrop-blur-md px-6 py-3 rounded-full border border-white/20 shadow-2xl z-50"
                        onClick={(e) => e.stopPropagation()}
                    >
                        <button onClick={handleZoomOut} className="text-white/90 hover:text-white hover:scale-110 transition-transform" title="Zoom Out">
                            <ZoomOut size={20} />
                        </button>
                        <button onClick={handleZoomIn} className="text-white/90 hover:text-white hover:scale-110 transition-transform" title="Zoom In">
                            <ZoomIn size={20} />
                        </button>
                        <div className="w-px bg-white/20 mx-1"></div>
                        <button onClick={handleRotate} className="text-white/90 hover:text-white hover:scale-110 transition-transform" title="Rotate">
                            <RotateCw size={20} />
                        </button>
                        <div className="w-px bg-white/20 mx-1"></div>
                        <button onClick={handleDownload} className="text-white/90 hover:text-white hover:scale-110 transition-transform" title="Download">
                            <Download size={20} />
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
};

export default ChatWindow;
