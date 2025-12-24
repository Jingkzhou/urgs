import React, { useState, useEffect, useRef } from 'react';
import { MoreHorizontal, Paperclip, Mic, Send, Image, ZoomIn, ZoomOut, RotateCw, Download, X } from 'lucide-react';
import { getAvatarUrl } from '../../utils/avatarUtils';

interface Message {
    id: number;
    senderId: number;
    content: string;
    type: 'text' | 'image';
    time: string;
    isSelf: boolean;
    senderName?: string;
    senderAvatar?: string;
}

interface ChatWindowProps {
    sessionName: string;
    messages: Message[];
    onSendMessage: (content: string, type?: 'text' | 'image') => void;
    onFileUpload?: (file: File) => Promise<string>;
    onShowDetails?: () => void;
}

const ChatWindow: React.FC<ChatWindowProps> = ({ sessionName, messages, onSendMessage, onFileUpload, onShowDetails }) => {
    const [inputValue, setInputValue] = useState('');
    const messagesEndRef = useRef<HTMLDivElement>(null);
    const fileInputRef = useRef<HTMLInputElement>(null);
    const [previewImage, setPreviewImage] = useState<string | null>(null);

    // Image Preview State
    const [scale, setScale] = useState(1);
    const [rotate, setRotate] = useState(0);
    const [position, setPosition] = useState({ x: 0, y: 0 });
    const [isDragging, setIsDragging] = useState(false);
    const [dragStart, setDragStart] = useState({ x: 0, y: 0 });

    const isFirstScroll = useRef(true);

    const scrollToBottom = (instant = false) => {
        // Small timeout to allow DOM layout to complete
        setTimeout(() => {
            messagesEndRef.current?.scrollIntoView({ behavior: instant ? 'auto' : 'smooth' });
        }, 100);
    };

    // Use useLayoutEffect for more immediate scrolling after render
    React.useLayoutEffect(() => {
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

    const handleSend = () => {
        if (!inputValue.trim()) return;
        onSendMessage(inputValue, 'text');
        setInputValue('');
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

    // Default Avatar
    const defaultAvatar = getAvatarUrl(null, 'User');

    return (
        <div className="flex-1 bg-[#F5F5F5] flex flex-col relative h-full"> {/* WeChat bg color closer to F5F5F5 */}
            {/* Header */}
            <div className="h-14 border-b border-slate-200 flex items-center justify-between px-4 bg-[#F5F5F5] z-10">
                <div className="flex items-center gap-2">
                    <h3 className="font-semibold text-slate-700">{sessionName}</h3>
                </div>
                <button
                    onClick={onShowDetails}
                    className="p-2 hover:bg-slate-200 rounded-lg text-slate-600">
                    <MoreHorizontal size={20} />
                </button>
            </div>

            {/* Messages */}
            <div className="flex-1 overflow-y-auto p-4 space-y-6">
                {messages.map((msg) => (
                    <div key={msg.id} className={`flex w-full ${msg.isSelf ? 'justify-end' : 'justify-start'}`}>
                        {/* Left Side (Other) */}
                        {!msg.isSelf && (
                            <>
                                <img
                                    src={getAvatarUrl(msg.senderAvatar, msg.senderId)}
                                    className="w-10 h-10 rounded-md mr-3 flex-shrink-0 cursor-pointer hover:opacity-90"
                                    alt="Avatar"
                                />
                                <div className="flex flex-col items-start max-w-[70%]">
                                    <span className="text-xs text-slate-400 mb-1 ml-0.5">{msg.senderName || `User ${msg.senderId}`}</span>
                                    <div className={`
                                        relative px-3 py-2.5 rounded-md text-sm shadow-sm
                                        bg-white border border-slate-100 text-slate-800
                                        before:content-[''] before:absolute before:top-3 before:-left-1.5 before:w-3 before:h-3 before:bg-white before:border-l before:border-b before:border-slate-100 before:rotate-45
                                    `}>
                                        {msg.type === 'text' ? (
                                            <p className="whitespace-pre-wrap break-all leading-6">{msg.content}</p>
                                        ) : (
                                            <img
                                                src={msg.content}
                                                alt="Content"
                                                className="rounded max-w-full cursor-pointer hover:opacity-90 max-h-64"
                                                onDoubleClick={() => setPreviewImage(msg.content)}
                                            />
                                        )}
                                    </div>
                                </div>
                            </>
                        )}

                        {/* Right Side (Self) */}
                        {msg.isSelf && (
                            <>
                                <div className="flex flex-col items-end max-w-[70%]">
                                    {/* Name usually hidden for self */}
                                    <div className={`
                                        relative px-3 py-2.5 rounded-md text-sm shadow-sm
                                        bg-[#95EC69] text-black
                                        before:content-[''] before:absolute before:top-3 before:-right-1.5 before:w-3 before:h-3 before:bg-[#95EC69] before:rotate-45
                                    `}>
                                        {msg.type === 'text' ? (
                                            <p className="whitespace-pre-wrap break-all leading-6">{msg.content}</p>
                                        ) : (
                                            <img
                                                src={msg.content}
                                                alt="Content"
                                                className="rounded max-w-full cursor-pointer hover:opacity-90 max-h-64"
                                                onDoubleClick={() => setPreviewImage(msg.content)}
                                            />
                                        )}
                                    </div>
                                </div>
                                <img
                                    src={getAvatarUrl(msg.senderAvatar, msg.senderId)}
                                    className="w-10 h-10 rounded-md ml-3 flex-shrink-0 cursor-pointer hover:opacity-90"
                                    alt="Avatar"
                                />
                            </>
                        )}
                    </div>
                ))}
                <div ref={messagesEndRef} />
            </div>

            {/* Input Area */}
            <div className="p-4 bg-white/50 border-t border-slate-100">
                <input
                    type="file"
                    ref={fileInputRef}
                    className="hidden"
                    accept="image/*"
                    onChange={async (e) => {
                        const file = e.target.files?.[0];
                        if (file && onFileUpload) {
                            try {
                                const url = await onFileUpload(file);
                                // Check if user wanted to send? Assuming yes based on flow
                                onSendMessage(url, 'image');
                            } catch (err) {
                                console.error('Upload failed', err);
                                alert('Upload failed');
                            }
                        }
                    }}
                />
                <div className="flex gap-2 items-center mb-2 text-slate-400">
                    <button
                        onClick={() => fileInputRef.current?.click()}
                        className="p-1.5 hover:bg-slate-100 rounded transition-colors"
                    >
                        <Image size={18} />
                    </button>
                    <button className="p-1.5 hover:bg-slate-100 rounded transition-colors"><Paperclip size={18} /></button>
                </div>
                <div className="flex gap-2">
                    <div className="flex-1 bg-white border border-slate-200 rounded-xl flex items-center px-3 py-2 focus-within:ring-2 focus-within:ring-[#10a37f]/20 focus-within:border-[#10a37f] transition-all">
                        <textarea
                            value={inputValue}
                            onChange={(e) => setInputValue(e.target.value)}
                            onKeyDown={handleKeyDown}
                            onPaste={async (e) => {
                                const items = e.clipboardData.items;
                                for (let i = 0; i < items.length; i++) {
                                    if (items[i].type.indexOf('image') !== -1) {
                                        const file = items[i].getAsFile();
                                        if (file && onFileUpload) {
                                            try {
                                                const url = await onFileUpload(file);
                                                onSendMessage(url, 'image');
                                            } catch (err) {
                                                console.error('Paste upload failed', err);
                                                alert('图片上传失败');
                                            }
                                        }
                                        e.preventDefault();
                                        return;
                                    }
                                }
                            }}
                            placeholder="输入消息..."
                            className="flex-1 bg-transparent border-none outline-none text-sm resize-none max-h-24 py-1"
                            rows={1}
                        />
                        <button className="p-1.5 text-slate-400 hover:text-slate-600">
                            <Mic size={18} />
                        </button>
                    </div>
                    <button
                        onClick={handleSend}
                        className={`${inputValue.trim() ? 'bg-[#10a37f] hover:bg-[#0e906f]' : 'bg-slate-200 cursor-not-allowed'} text-white p-3 rounded-xl transition-all duration-200 flex items-center justify-center`}
                        disabled={!inputValue.trim()}
                    >
                        <Send size={18} />
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
