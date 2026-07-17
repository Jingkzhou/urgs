import React, { useState } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import remarkMath from 'remark-math';
import remarkBreaks from 'remark-breaks';
import rehypeKatex from 'rehype-katex';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { oneLight } from 'react-syntax-highlighter/dist/esm/styles/prism';
import { Copy, Check, Sparkles, SearchX, ChevronDown, HelpCircle, BookOpen, Scale, Wrench, MessageCircle } from 'lucide-react';
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

const normalizeMarkdownContent = (content: string) => {
    let inFence = false;
    return content
        .split('\n')
        .map(line => {
            const trimmed = line.trim();
            if (/^(```|~~~)/.test(trimmed)) {
                inFence = !inFence;
                return line;
            }
            if (/^[╭╮╰╯─━═┄┈│┊┆┌┐└┘\s]{8,}$/.test(trimmed)) {
                return '---';
            }
            if (!inFence && /^\s{4,}\S/.test(line) && /[\u4e00-\u9fff]/.test(trimmed)) {
                return trimmed;
            }
            return line;
        })
        .join('\n');
};

const isIndentedProseCode = (value: string) => {
    return value.length > 24 && /[\u4e00-\u9fff]/.test(value) && /[，。！？：；「」《》、]/.test(value);
};

const ScoreTooltip: React.FC<ScoreDetailProps> = ({ details }) => {
    if (!details || Object.keys(details).length === 0) return null;

    // Check if RRF
    const isRRF = Object.keys(details).some(k => k.includes('rrf'));

    return (
        <div className="absolute bottom-full mb-2 left-0 w-48 bg-slate-800 text-white text-[10px] p-2 rounded-lg shadow-xl opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-10 flex flex-col gap-1">
            <div className="font-bold border-b border-slate-700 pb-1 mb-1 text-slate-300">
                {isRRF ? 'RRF 融合详情' : '检索详情'}
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
        <div className={`group w-full ${isUser ? 'flex justify-end' : 'block'}`}>
            <div className={`w-full min-w-0 ${isUser ? 'flex justify-end' : ''}`}>
                    <div className={`
                        ${isUser ? 'max-w-[78%]' : 'w-full'}
                        ${isUser
                            ? 'inline-block rounded-[1.35rem] bg-[#f4f4f4] px-5 py-3 text-[15px] leading-7 text-[#0d0d0d]'
                            : 'text-[16px] font-normal leading-7 text-[#0d0d0d] transition-opacity duration-300'
                        }
                    `}>
                        {!isUser && !message.content ? (
                            <div className="flex h-9 items-center gap-3 py-4">
                                <motion.div
                                    animate={{
                                        scale: [1, 1.2, 1],
                                        opacity: [0.3, 1, 0.3]
                                    }}
                                    transition={{ duration: 1.5, repeat: Infinity, ease: "easeInOut" }}
                                    className="h-2.5 w-2.5 rounded-full bg-slate-900"
                                />
                                <span className="animate-pulse text-sm font-medium text-slate-500">
                                    {message.status === 'searching' ? '正在检索知识库...' :
                                        message.status === 'compressing' ? '正在压缩对话历史...' :
                                            message.status === 'agent_app_running' ? '正在调用 Agent App...' :
                                            '思考中...'}
                                </span>
                            </div>
                        ) : (
                            <div className={`markdown-body ${isUser ? 'text-[#0d0d0d]' : ''}`}>
                                {/* Intent Badge */}
                                {!isUser && message.intent && message.intent !== 'GENERAL' && (
                                    <div className={`mb-4 inline-flex items-center gap-1.5 rounded-lg px-3 py-1 text-[11px] font-semibold ${getIntentConfig(message.intent).color}`}>
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
                                            const isBlock = Boolean(match) || codeContent.includes('\n');
                                            if (isBlock) {
                                                return <CodeBlock language={match?.[1] || 'text'} value={codeContent} />;
                                            }
                                            if (!isUser && isIndentedProseCode(codeContent)) {
                                                return <span {...props}>{children}</span>;
                                            }
                                            return (
                                                <code className="rounded-md bg-slate-100 px-1.5 py-0.5 font-mono text-[0.9em] text-slate-900" {...props}>
                                                    {children}
                                                </code>
                                            );
                                        },
                                        p({ children }) {
                                            return <p className="mb-4 last:mb-0 leading-7">{children}</p>;
                                        },
                                        ul({ children }) {
                                            return <ul className="mb-4 list-disc space-y-1.5 pl-6">{children}</ul>;
                                        },
                                        ol({ children }) {
                                            return <ol className="mb-4 list-decimal space-y-1.5 pl-6">{children}</ol>;
                                        },
                                        li({ children }) {
                                            return <li className="pl-1 leading-7">{children}</li>;
                                        },
                                        h1: ({ children }) => <h1 className="mb-4 mt-7 text-2xl font-semibold leading-tight text-slate-950 first:mt-0">{children}</h1>,
                                        h2: ({ children }) => <h2 className="mb-3 mt-7 text-xl font-semibold leading-tight text-slate-950 first:mt-0">{children}</h2>,
                                        h3: ({ children }) => <h3 className="mb-3 mt-6 text-lg font-semibold leading-tight text-slate-900 first:mt-0">{children}</h3>,
                                        blockquote: ({ children }) => (
                                            <blockquote className="mb-4 border-l-2 border-slate-300 pl-4 text-slate-600">
                                                <div className="[&>p:last-child]:mb-0">{children}</div>
                                            </blockquote>
                                        ),
                                        table({ children }) {
                                            return (
                                                <div className="my-5 overflow-x-auto rounded-lg border border-slate-200 bg-white">
                                                    <table className="min-w-full divide-y divide-slate-200 text-sm">
                                                        {children}
                                                    </table>
                                                </div>
                                            );
                                        },
                                        thead: ({ children }) => <thead className="bg-slate-50 text-slate-900">{children}</thead>,
                                        th: ({ children }) => <th className="border-b border-slate-200 px-4 py-3 text-left font-semibold">{children}</th>,
                                        td: ({ children }) => <td className="border-t border-slate-100 px-4 py-3 leading-6 text-slate-700">{children}</td>,
                                        a: ({ children, href }) => <a href={href} target="_blank" rel="noreferrer" className="text-blue-600 underline underline-offset-2 hover:text-blue-700">{children}</a>,
                                        hr: () => <hr className="my-6 w-full border-0 border-t border-slate-200" />
                                    }}
                                >
                                    {normalizeMarkdownContent(message.content)}
                                </ReactMarkdown>
                            </div>
                        )}

                        {/* Historical source citations */}
                        {message.sources && message.sources.length > 0 && (
                            <motion.div
                                initial={{ opacity: 0, y: 10 }}
                                animate={{ opacity: 1, y: 0 }}
                                className="mt-7 border-t border-slate-200 pt-4"
                            >
                                <button
                                    onClick={() => setIsSourcesExpanded(!isSourcesExpanded)}
                                    className="group/btn mb-3 flex items-center gap-2 text-xs font-semibold text-slate-500 transition-colors hover:text-slate-900"
                                >
                                    <Sparkles size={14} />
                                    <span>发现的参考资料 ({message.sources.length})</span>
                                    <motion.div
                                        animate={{ rotate: isSourcesExpanded ? 180 : 0 }}
                                        transition={{ duration: 0.2 }}
                                    >
                                        <ChevronDown size={14} />
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
                                            <div className="grid gap-2 pb-2 sm:grid-cols-2">
                                                {message.sources.map((source, idx) => (
                                                    <motion.div
                                                        key={idx}
                                                        whileHover={{ backgroundColor: "#ffffff" }}
                                                        className="cursor-default rounded-lg border border-slate-200 bg-[#f7f7f7] p-3 transition-colors"
                                                    >
                                                        <div className="mb-2 flex items-center justify-between gap-2 text-xs font-semibold text-slate-800">
                                                            <span className="flex min-w-0 items-center gap-1.5 truncate">
                                                                <BookOpen size={13} />
                                                                <span className="truncate">{source.fileName}</span>
                                                            </span>
                                                            <span className={`shrink-0 rounded-md px-2 py-0.5 text-[10px] font-semibold ${source.score >= 0.8 ? 'bg-emerald-100 text-emerald-700' :
                                                                source.score >= 0.6 ? 'bg-blue-100 text-blue-700' :
                                                                    'bg-slate-200 text-slate-600'
                                                                }`}>
                                                                {source.score > 0 ? (source.score < 0.1 ? `RRF ${(source.score).toFixed(4)}` : `${(source.score * 100).toFixed(0)}%`) : '召回'}
                                                            </span>
                                                        </div>
                                                        <div className="relative line-clamp-2 text-xs leading-5 text-slate-500">
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
                            <div className="mt-6 border-t border-slate-100 pt-4">
                                <div className="flex items-center gap-2 text-xs font-semibold text-slate-500">
                                    <SearchX size={14} />
                                    未在知识库中找到精准匹配
                                </div>
                            </div>
                        )}
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
    const label = language === 'text' ? 'Plain text' : language;

    return (
        <div className="my-5 overflow-hidden rounded-lg bg-[#f4f4f4]">
            <div className="flex items-center justify-between px-4 py-3">
                <span className="text-sm font-semibold text-[#0d0d0d]">{label}</span>
                <button
                    onClick={handleCopy}
                    className="flex items-center gap-2 rounded-md px-2 py-1 text-sm font-semibold text-[#0d0d0d] transition-colors hover:bg-black/5"
                >
                    {copied ? <Check size={16} className="text-emerald-600" /> : <Copy size={16} />}
                    {copied ? '已复制' : '复制'}
                </button>
            </div>
            <SyntaxHighlighter
                language={language}
                style={oneLight}
                customStyle={{ margin: 0, padding: '0 1rem 1rem', background: '#f4f4f4', fontSize: '14px', lineHeight: '1.7' }}
                codeTagProps={{ style: { fontFamily: 'var(--font-mono)' } }}
                wrapLines={true}
                wrapLongLines={false}
            >
                {value}
            </SyntaxHighlighter>
        </div>
    );
};

export default React.memo(ChatMessage, (prev, next) => {
    return prev.message === next.message && prev.isStreaming === next.isStreaming;
});
