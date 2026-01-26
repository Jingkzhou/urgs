import React, { useState } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import remarkMath from 'remark-math';
import remarkBreaks from 'remark-breaks';
import rehypeKatex from 'rehype-katex';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { oneLight } from 'react-syntax-highlighter/dist/esm/styles/prism';
import { Copy, Check, Sparkles, SearchX, Quote, ChevronDown, ChevronRight, HelpCircle, BookOpen, Scale, Wrench, MessageCircle } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { Message } from '../../api/chat';
import 'katex/dist/katex.min.css';
import { copyToClipboard } from '../../utils/clipboard';

interface ChatMessageProps {
    message: Message;
    isStreaming?: boolean;
}

interface ScoreDetailProps {
    details: Record<string, any>;
}

const getIntentConfig = (intent: string) => {
    switch (intent) {
        case 'WHAT_IS': return { label: '概念解释', color: 'bg-blue-100/50 text-blue-700', icon: <HelpCircle size={12} /> };
        case 'HOW_TO': return { label: '操作指南', color: 'bg-emerald-100/50 text-emerald-700', icon: <BookOpen size={12} /> };
        case 'COMPARE': return { label: '对比分析', color: 'bg-purple-100/50 text-purple-700', icon: <Scale size={12} /> };
        case 'TROUBLESHOOT': return { label: '故障排查', color: 'bg-orange-100/50 text-orange-700', icon: <Wrench size={12} /> };
        default: return { label: '通用对话', color: 'bg-slate-100/50 text-slate-600', icon: <MessageCircle size={12} /> };
    }
}

const ScoreTooltip: React.FC<ScoreDetailProps> = ({ details }) => {
    if (!details || Object.keys(details).length === 0) return null;

    // Check if RRF
    const isRRF = Object.keys(details).some(k => k.includes('rrf'));

    return (
        <div className="absolute bottom-full mb-2 left-0 w-48 bg-slate-800 text-white text-[10px] p-2 rounded-lg shadow-xl opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-10 flex flex-col gap-1">
            <div className="font-bold border-b border-slate-700 pb-1 mb-1 text-slate-300">
                {isRRF ? 'RRF Fusion Details' : 'Retrieval Details'}
            </div>
            {Object.entries(details).map(([key, val]) => {
                if (typeof val === 'number') {
                    // Filter out raw boolean flags or long strings
                    return (
                        <div key={key} className="flex justify-between">
                            <span className="opacity-70 capitalize">{key.replace('_', ' ')}:</span>
                            <span className="font-mono font-bold text-blue-300">
                                {Number.isInteger(val) ? `#${val}` : val.toFixed(4)}
                            </span>
                        </div>
                    );
                }
                return null;
            })}
        </div>
    );
};

const ChatMessage: React.FC<ChatMessageProps> = ({ message, isStreaming = false }) => {
    const isUser = message.role === 'user';
    const [isSourcesExpanded, setIsSourcesExpanded] = useState(false);

    return (
        <div className={`w-full group ${isUser ? 'flex justify-end' : 'flex justify-start'}`}>
            <div className={`flex gap-4 max-w-4xl w-full ${isUser ? 'flex-row-reverse' : ''}`}>
                {/* Avatar / Icon */}
                <div className="flex-shrink-0 mt-1">
                    {!isUser && (
                        <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-blue-600 via-purple-500 to-indigo-600 flex items-center justify-center text-white shadow-lg ring-4 ring-white ark-avatar-glow transition-transform duration-500 group-hover:rotate-12">
                            <Sparkles size={18} fill="currentColor" />
                        </div>
                    )}
                </div>

                {/* Content */}
                <div className={`flex-1 min-w-0 ${isUser ? 'flex justify-end' : ''}`}>
                    <div className={`
                        max-w-none w-full
                        ${isUser
                            ? 'bg-[#d3e3fd] px-6 py-3.5 rounded-[28px] rounded-tr-lg text-[#041e49] font-medium shadow-sm leading-relaxed inline-block'
                            : 'bg-transparent text-[#1f1f1f] text-[16px] leading-[1.8] font-normal transition-opacity duration-300'
                        }
                    `}>
                        {!isUser && !message.content ? (
                            <div className="flex items-center gap-3 py-4 h-9">
                                <motion.div
                                    animate={{
                                        scale: [1, 1.2, 1],
                                        opacity: [0.3, 1, 0.3]
                                    }}
                                    transition={{ duration: 1.5, repeat: Infinity, ease: "easeInOut" }}
                                    className="w-2.5 h-2.5 bg-blue-500 rounded-full shadow-[0_0_10px_rgba(59,130,246,0.5)]"
                                />
                                <span className="text-slate-400 text-sm font-medium animate-pulse">
                                    {message.status === 'searching' ? '正在检索知识库...' :
                                        message.status === 'compressing' ? '正在压缩对话历史...' :
                                            '思考中...'}
                                </span>
                            </div>
                        ) : (
                            <div className={`markdown-body ${isUser ? 'text-[#041e49]' : ''}`}>
                                {/* Intent Badge */}
                                {!isUser && message.intent && message.intent !== 'GENERAL' && (
                                    <div className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider mb-4 border border-white/50 shadow-sm ${getIntentConfig(message.intent).color}`}>
                                        {getIntentConfig(message.intent).icon}
                                        {getIntentConfig(message.intent).label}
                                    </div>
                                )}

                                <ReactMarkdown
                                    remarkPlugins={[remarkGfm, remarkMath, remarkBreaks]}
                                    rehypePlugins={[rehypeKatex]}
                                    components={{
                                        code({ node, inline, className, children, ...props }: any) {
                                            const match = /language-(\w+)/.exec(className || '');
                                            const codeContent = String(children).replace(/\n$/, '');
                                            if (!inline && match) {
                                                return <CodeBlock language={match[1]} value={codeContent} />;
                                            }
                                            return (
                                                <code className={`bg-slate-100 text-[#1f1f1f] px-1.5 py-0.5 rounded-md text-sm font-mono font-semibold`} {...props}>
                                                    {children}
                                                </code>
                                            );
                                        },
                                        p({ children }) {
                                            return <p className="mb-6 last:mb-0 leading-[1.8]">{children}</p>;
                                        },
                                        ul({ children }) {
                                            return <ul className="list-disc pl-6 mb-6 space-y-2">{children}</ul>;
                                        },
                                        ol({ children }) {
                                            return <ol className="list-decimal pl-6 mb-6 space-y-2">{children}</ol>;
                                        },
                                        li({ children }) {
                                            return <li className="pl-2">{children}</li>;
                                        },
                                        h1: ({ children }) => <h1 className="text-3xl font-bold mb-6 text-slate-900">{children}</h1>,
                                        h2: ({ children }) => <h2 className="text-2xl font-bold mb-5 mt-8 text-slate-800 border-b border-slate-100 pb-2">{children}</h2>,
                                        h3: ({ children }) => <h3 className="text-xl font-bold mb-4 mt-6 text-slate-800">{children}</h3>,
                                        blockquote: ({ children }) => (
                                            <blockquote className="border-l-4 border-blue-200 bg-blue-50/30 px-6 py-4 rounded-r-2xl mb-6 italic text-slate-600 flex gap-3">
                                                <Quote size={20} className="text-blue-300 flex-shrink-0" />
                                                <div>{children}</div>
                                            </blockquote>
                                        ),
                                        table({ children }) {
                                            return (
                                                <div className="overflow-x-auto my-8 rounded-2xl border border-slate-200/60 shadow-sm bg-white">
                                                    <table className="min-w-full divide-y divide-slate-200 text-[14px]">
                                                        {children}
                                                    </table>
                                                </div>
                                            );
                                        },
                                        thead: ({ children }) => <thead className="bg-[#f8fbff] text-slate-900">{children}</thead>,
                                        th: ({ children }) => <th className="px-5 py-4 text-left font-bold border-b border-slate-200/60">{children}</th>,
                                        td: ({ children }) => <td className="px-5 py-4 border-t border-slate-100/60 text-slate-700 leading-relaxed">{children}</td>
                                    }}
                                >
                                    {message.content}
                                </ReactMarkdown>
                            </div>
                        )}

                        {/* RAG Sources Citations */}
                        {message.sources && message.sources.length > 0 && (
                            <motion.div
                                initial={{ opacity: 0, y: 10 }}
                                animate={{ opacity: 1, y: 0 }}
                                className="mt-8 pt-4 border-t border-slate-200/40"
                            >
                                <button
                                    onClick={() => setIsSourcesExpanded(!isSourcesExpanded)}
                                    className="flex items-center gap-2 text-[11px] font-bold text-slate-400 uppercase tracking-widest mb-4 hover:text-blue-600 transition-colors group/btn"
                                >
                                    <Sparkles size={14} className="text-blue-600" />
                                    <span>发现的参考资料 ({message.sources.length})</span>
                                    <motion.div
                                        animate={{ rotate: isSourcesExpanded ? 180 : 0 }}
                                        transition={{ duration: 0.2 }}
                                    >
                                        <ChevronDown size={14} className="group-hover/btn:text-blue-600" />
                                    </motion.div>
                                </button>

                                <AnimatePresence>
                                    {isSourcesExpanded && (
                                        <motion.div
                                            initial={{ height: 0, opacity: 0 }}
                                            animate={{ height: "auto", opacity: 1 }}
                                            exit={{ height: 0, opacity: 0 }}
                                            transition={{ duration: 0.3, ease: "easeInOut" }}
                                            className="overflow-hidden"
                                        >
                                            <div className="flex flex-wrap gap-3 pb-2">
                                                {message.sources.map((source, idx) => (
                                                    <motion.div
                                                        key={idx}
                                                        whileHover={{ y: -3, scale: 1.02, backgroundColor: "#ffffff", borderColor: "#3b82f6" }}
                                                        className="bg-slate-50 border border-slate-200/50 rounded-2xl p-4 min-w-[200px] max-w-[280px] shadow-sm transition-all cursor-default"
                                                    >
                                                        <div className="font-bold text-slate-800 mb-2 flex justify-between items-center text-xs">
                                                            <span className="flex items-center gap-1.5 truncate">
                                                                📄 {source.fileName}
                                                            </span>
                                                            <span className={`px-2 py-0.5 rounded-full text-[9px] font-bold uppercase ${source.score >= 0.8 ? 'bg-emerald-100 text-emerald-700' :
                                                                source.score >= 0.6 ? 'bg-blue-100 text-blue-700' :
                                                                    'bg-slate-200 text-slate-600'
                                                                }`}>
                                                                {source.score > 0 ? (source.score < 0.1 ? `RRF ${(source.score).toFixed(4)}` : `${(source.score * 100).toFixed(0)}%`) : '召回'}
                                                            </span>
                                                        </div>
                                                        <div className="text-slate-500 line-clamp-2 text-[11px] leading-relaxed relative">
                                                            {source.content}
                                                            <ScoreTooltip details={(source as any).score_details} />
                                                        </div>
                                                    </motion.div>
                                                ))}
                                            </div>
                                        </motion.div>
                                    )}
                                </AnimatePresence>
                            </motion.div>
                        )}

                        {/* No content fallback */}
                        {message.sources && message.sources.length === 0 && (
                            <div className="mt-6 pt-4 border-t border-slate-100/50">
                                <div className="text-[11px] text-slate-400 font-bold uppercase tracking-widest flex items-center gap-2">
                                    <SearchX size={14} />
                                    未在知识库中找到精准匹配
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
};

const CodeBlock = ({ language, value }: { language: string, value: string }) => {
    const [copied, setCopied] = React.useState(false);
    const handleCopy = async () => {
        const success = await copyToClipboard(value);
        if (success) {
            setCopied(true);
            setTimeout(() => setCopied(false), 2000);
        }
    };

    return (
        <div className="rounded-[20px] overflow-hidden border border-slate-200/80 my-8 shadow-md bg-[#fafafa]">
            <div className="flex items-center justify-between px-6 py-3 bg-[#f8fbff] border-b border-slate-200/60">
                <span className="text-[11px] font-bold uppercase tracking-widest text-blue-600">{language}</span>
                <button
                    onClick={handleCopy}
                    className="flex items-center gap-2 text-[11px] font-bold uppercase tracking-widest text-[#1f1f1f] hover:text-blue-700 transition-colors"
                >
                    {copied ? <Check size={14} className="text-green-600" /> : <Copy size={14} />}
                    {copied ? '已复制' : '复制代码'}
                </button>
            </div>
            <SyntaxHighlighter
                language={language}
                style={oneLight}
                customStyle={{ margin: 0, padding: '1.5rem', background: 'transparent', fontSize: '14px', lineHeight: '1.6' }}
                showLineNumbers={true}
                lineNumberStyle={{ minWidth: '2.5em', paddingRight: '1.5em', color: '#cbd5e1', textAlign: 'right', fontSize: '12px' }}
                wrapLines={true}
            >
                {value}
            </SyntaxHighlighter>
        </div>
    );
};

export default React.memo(ChatMessage, (prev, next) => {
    return prev.message === next.message && prev.isStreaming === next.isStreaming;
});
