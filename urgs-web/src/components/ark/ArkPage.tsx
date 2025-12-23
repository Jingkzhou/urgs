import React, { useState, useEffect, useRef } from 'react';
import { v4 as uuidv4 } from 'uuid';
import { RobotOutlined } from '@ant-design/icons';
import { Sparkles, Database, ChevronRight, User, Cpu, Layers, PenTool } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import Sidebar from './Sidebar';
import ChatMessage from './ChatMessage';
import ChatInput from './ChatInput';
import {
    Message, Session, getSessions, createSession, streamChatResponse, loadSessionMessages, generateSessionTitle, getAgents, getRoleAgents
} from '../../api/chat';

const ArkPage: React.FC = () => {
    // ... state remains the same ...
    const [currentSessionId, setCurrentSessionId] = useState<string | null>(null);
    const [messages, setMessages] = useState<Message[]>([]);
    const [inputValue, setInputValue] = useState('');
    const [isGenerating, setIsGenerating] = useState(false);
    const [metrics, setMetrics] = useState<{ used: number, limit: number } | null>(null);
    const [agents, setAgents] = useState<any[]>([]);
    const [activeAgent, setActiveAgent] = useState<any | null>(null);
    const [sessions, setSessions] = useState<Session[]>([]);
    const [loading, setLoading] = useState(true);

    const abortControllerRef = useRef<AbortController | null>(null);
    const messagesEndRef = useRef<HTMLDivElement>(null);
    const isSwitchingSession = useRef(false);

    // ... fetchAgents and useEffect remain same ...
    const fetchAgents = async () => {
        // ... (omitted for brevity, assume same content) ...
        try {
            const allAgents = await getAgents();
            const userStr = localStorage.getItem('auth_user');
            const userInfo = userStr ? JSON.parse(userStr) : null;
            let filtered = [];
            if (userInfo && userInfo.roleId) {
                const authorizedIds = await getRoleAgents(userInfo.roleId);
                filtered = allAgents.filter(a => authorizedIds.includes(a.id));
            } else {
                console.error('ArkPage: roleId is missing from userInfo! Current user state:', userInfo);
                filtered = allAgents.filter(a => a.name === '通用助手');
            }
            setAgents(filtered);
            return filtered;
        } catch (e) {
            console.error('Failed to fetch/filter agents', e);
            return [];
        }
    };

    useEffect(() => {
        const init = async () => {
            const filteredAgents = await fetchAgents();
            const sessionList = await getSessions();
            setSessions(sessionList);
            if (sessionList.length > 0) {
                const firstId = sessionList[0].id;
                isSwitchingSession.current = true;
                setCurrentSessionId(firstId);
                const msgs = await loadSessionMessages(firstId);
                setMessages(msgs);
                const session = sessionList.find(s => s.id === firstId);
                if (session?.agentId) {
                    setActiveAgent(filteredAgents.find(a => a.id === session.agentId) || null);
                } else {
                    setActiveAgent(null);
                }
            } else {
                if (filteredAgents.length === 0) {
                    const newSession = await createSession();
                    setCurrentSessionId(newSession.id);
                    setMessages([]);
                    setActiveAgent(null);
                } else {
                    handleNewChat();
                }
            }
            setLoading(false);
        };
        init();
    }, []);

    const scrollContainerRef = useRef<HTMLDivElement>(null);
    const isAtBottom = useRef(true);

    const handleScroll = () => {
        if (!scrollContainerRef.current) return;
        const { scrollTop, scrollHeight, clientHeight } = scrollContainerRef.current;
        const isBottom = Math.abs(scrollHeight - clientHeight - scrollTop) < 50; // Threshold of 50px
        isAtBottom.current = isBottom;
    };

    const scrollToBottom = (instant = false) => {
        messagesEndRef.current?.scrollIntoView({ behavior: instant ? 'auto' : 'smooth' });
    };

    useEffect(() => {
        if (isSwitchingSession.current) {
            scrollToBottom(true);
            isSwitchingSession.current = false;
            isAtBottom.current = true; // Reset to true on session switch
        } else if (isAtBottom.current) {
            scrollToBottom();
        }
    }, [messages, currentSessionId]); // Switched back to [messages] to trigger on streaming updates, but guarded by isAtBottom

    const handleSessionSelect = async (id: string, agentId?: number) => {
        if (currentSessionId === id && messages.length > 0) return;
        isSwitchingSession.current = true;
        setCurrentSessionId(id);
        const msgs = await loadSessionMessages(id);
        setMessages(msgs);
        setInputValue('');
        setMetrics(null);
        if (agentId) {
            setActiveAgent(agents.find(a => a.id === agentId) || null);
        } else {
            setActiveAgent(null);
        }
        if (isGenerating) handleStop();
    };

    const handleNewChat = async (agentId?: number | React.MouseEvent) => {
        const searchId = typeof agentId === 'number' ? agentId : undefined;
        if (searchId) {
            const newSession = await createSession(searchId);
            setCurrentSessionId(newSession.id);
            setMessages([]);
            setInputValue('');
            setMetrics(null);
            setActiveAgent(agents.find(a => a.id === searchId) || null);
        } else {
            if (agents.length === 0) {
                const newSession = await createSession();
                setCurrentSessionId(newSession.id);
                setMessages([]);
                setInputValue('');
                setMetrics(null);
                setActiveAgent(null);
            } else {
                setCurrentSessionId(null);
                setMessages([]);
                setInputValue('');
                setMetrics(null);
                setActiveAgent(null);
            }
        }
        if (isGenerating) handleStop();
    };

    const handleStop = () => {
        if (abortControllerRef.current) {
            abortControllerRef.current.abort();
            abortControllerRef.current = null;
        }
        setIsGenerating(false);
    };

    const [sidebarRefreshTrigger, setSidebarRefreshTrigger] = useState(0);

    const handleSubmit = async () => {
        if (!inputValue.trim() || !currentSessionId) return;
        const userText = inputValue;
        const isFirstMessage = messages.length === 0;
        setInputValue('');
        setIsGenerating(true);
        const userMsg: Message = { id: uuidv4(), role: 'user', content: userText, timestamp: Date.now() };
        setMessages(prev => [...prev, userMsg]);
        const aiMsgId = uuidv4();
        const aiMsgPlaceholder: Message = { id: aiMsgId, role: 'assistant', content: '', timestamp: Date.now() };
        setMessages(prev => [...prev, aiMsgPlaceholder]);
        abortControllerRef.current = new AbortController();
        try {
            await streamChatResponse(
                userText,
                (chunk) => {
                    setMessages(prev => prev.map(m =>
                        m.id === aiMsgId ? { ...m, content: m.content + chunk } : m
                    ));
                },
                async () => {
                    setIsGenerating(false);
                    if (isFirstMessage || messages.length < 4) {
                        try {
                            await generateSessionTitle(currentSessionId);
                            setSidebarRefreshTrigger(prev => prev + 1);
                        } catch (e) {
                            console.error("Title generation failed", e);
                        }
                    }
                },
                abortControllerRef.current.signal,
                currentSessionId,
                (m) => setMetrics(m),
                (sources) => {
                    setMessages(prev => prev.map(m =>
                        m.id === aiMsgId ? { ...m, sources: sources } : m
                    ));
                }
            );
        } catch (e) {
            setIsGenerating(false);
        }
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center h-full bg-[#f8fbff]">
                <div className="w-8 h-8 rounded-full border-4 border-slate-200 border-t-blue-600 animate-spin"></div>
            </div>
        );
    }

    return (
        <div className="flex h-full bg-[#f8fbff] font-sans text-slate-800 overflow-hidden">
            <Sidebar
                currentSessionId={currentSessionId}
                onSessionSelect={handleSessionSelect}
                onNewChat={handleNewChat}
                refreshTrigger={sidebarRefreshTrigger}
            />

            <main className="flex-1 flex flex-col relative min-w-0">
                <AnimatePresence mode="wait">
                    {!currentSessionId ? (
                        // ... Welcome Hub Code (No changes here, omitted for brevity if possible, keeping context keys) ...
                        <motion.div
                            key="hub"
                            // ...
                            className="flex-1 flex flex-col items-center justify-center p-8 w-full max-w-6xl mx-auto overflow-y-auto"
                        >
                            {/* ... Content of Hub ... */}
                            <div className="text-center mb-16">
                                <motion.h1
                                    initial={{ y: 20 }}
                                    animate={{ y: 0 }}
                                    className="text-6xl font-extrabold text-slate-900 mb-6 tracking-tight bg-gradient-to-r from-blue-700 via-purple-600 to-indigo-600 bg-clip-text text-transparent"
                                >
                                    你好，今天我想如何协助你？
                                </motion.h1>
                                <p className="text-slate-500 text-xl font-medium max-w-2xl mx-auto">
                                    选择一个专业的 AI 智能体开启对话，或使用通用助手处理日常任务。
                                </p>
                            </div>

                            <motion.div
                                className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 w-full"
                                initial="hidden"
                                animate="visible"
                                variants={{
                                    visible: { transition: { staggerChildren: 0.1 } }
                                }}
                            >
                                {agents.map(agent => (
                                    <motion.button
                                        key={agent.id}
                                        variants={{
                                            hidden: { opacity: 0, y: 20 },
                                            visible: { opacity: 1, y: 0 }
                                        }}
                                        onClick={() => handleNewChat(agent.id)}
                                        className="group relative flex flex-col items-start p-8 bg-white border border-slate-200/60 hover:border-blue-300 hover:shadow-[0_20px_40px_-15px_rgba(37,99,235,0.12)] rounded-[32px] transition-all duration-500 text-left"
                                    >
                                        <div className="w-14 h-14 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center mb-6 group-hover:scale-110 group-hover:bg-blue-600 group-hover:text-white transition-all duration-300">
                                            <RobotOutlined className="text-2xl" />
                                        </div>
                                        <h3 className="text-xl font-bold text-slate-800 mb-3 group-hover:text-blue-700 transition-colors">{agent.name}</h3>
                                        <p className="text-slate-500 text-sm leading-relaxed line-clamp-2 mb-4 group-hover:text-slate-600 transition-colors">
                                            {agent.description || "专业处理特定领域任务"}
                                        </p>

                                        {agent.knowledgeBase && (
                                            <div className="mt-auto px-3 py-1 bg-slate-50 text-slate-500 text-[10px] font-bold rounded-full flex items-center gap-1.5 border border-slate-100">
                                                <Database size={12} className="text-blue-400" />
                                                <span className="truncate uppercase tracking-wider">{agent.knowledgeBase}</span>
                                            </div>
                                        )}
                                    </motion.button>
                                ))}

                                <motion.button
                                    variants={{
                                        hidden: { opacity: 0, y: 20 },
                                        visible: { opacity: 1, y: 0 }
                                    }}
                                    onClick={async () => {
                                        const newSession = await createSession();
                                        setCurrentSessionId(newSession.id);
                                        setMessages([]);
                                        setInputValue('');
                                        setActiveAgent(null);
                                    }}
                                    className="group relative flex flex-col items-start p-8 bg-gradient-to-br from-blue-600 to-indigo-700 text-white rounded-[32px] hover:shadow-[0_20px_40px_-15px_rgba(37,99,235,0.3)] transition-all duration-500 text-left"
                                >
                                    <div className="w-14 h-14 rounded-2xl bg-white/20 backdrop-blur-md text-white flex items-center justify-center mb-6 group-hover:scale-110 transition-transform duration-300">
                                        <Sparkles size={28} />
                                    </div>
                                    <h3 className="text-xl font-bold mb-3">通用助手</h3>
                                    <p className="text-white/80 text-sm leading-relaxed mb-4">
                                        全能协作、逻辑推理与创意输出。
                                    </p>
                                    <div className="mt-auto flex items-center gap-1 text-xs font-bold uppercase tracking-widest opacity-80">
                                        直接提问 <ChevronRight size={14} />
                                    </div>
                                </motion.button>
                            </motion.div>
                        </motion.div>
                    ) : (
                        <motion.div
                            key="chat"
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            ref={scrollContainerRef}
                            onScroll={handleScroll}
                            className="flex-1 overflow-y-auto custom-scrollbar flex flex-col items-center"
                        >
                            {messages.length === 0 ? (
                                <motion.div
                                    initial={{ opacity: 0, y: 20 }}
                                    animate={{ opacity: 1, y: 0 }}
                                    className="flex-1 flex flex-col items-center justify-center p-4 w-full max-w-3xl -mt-20"
                                >
                                    <div className="mb-10 text-center">
                                        <h1 className="text-5xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent mb-4">
                                            {activeAgent ? `你好，我是 ${activeAgent.name}` : '你好，今天有什么想聊的？'}
                                        </h1>
                                        <p className="text-slate-400 text-lg">
                                            {activeAgent?.description || "我可以在写作、规划或解决问题方面为你提供帮助。"}
                                        </p>
                                    </div>

                                    <div className="grid grid-cols-2 gap-4 w-full">
                                        {(activeAgent?.prompts && activeAgent.prompts.length > 0 ? activeAgent.prompts : [
                                            { title: '提供建议', content: '如何更高效地管理时间？', icon: <Cpu size={16} /> },
                                            { title: '撰写内容', content: '写一篇关于可持续发展的演讲稿。', icon: <PenTool size={16} /> },
                                            { title: '数据分析', content: '解释什么是大模型微调及其原理。', icon: <Layers size={16} /> },
                                            { title: '辅助编码', content: '使用 React 实现一个深色模式切换功能。', icon: <Database size={16} /> },
                                        ]).map((item: any, i: number) => (
                                            <motion.button
                                                key={i}
                                                whileHover={{ scale: 1.02, backgroundColor: "#ffffff", boxShadow: "0 10px 25px -10px rgba(0,0,0,0.05)" }}
                                                onClick={() => setInputValue(`${item.content}`)}
                                                className="text-left p-5 bg-white border border-slate-100 rounded-2xl transition-all flex flex-col gap-3 group"
                                            >
                                                <div className="w-8 h-8 rounded-lg bg-slate-50 flex items-center justify-center text-slate-500 group-hover:text-blue-600 transition-colors">
                                                    {item.icon || <Sparkles size={16} />}
                                                </div>
                                                <div>
                                                    <span className="font-bold text-slate-800 text-sm block mb-1">{item.title}</span>
                                                    <span className="text-slate-500 text-xs line-clamp-1">{item.content}</span>
                                                </div>
                                            </motion.button>
                                        ))}
                                    </div>
                                </motion.div>
                            ) : (
                                <div className="flex flex-col pb-48 w-full items-center pt-8">
                                    <div className="w-full max-w-4xl px-6 flex flex-col gap-8">
                                        {messages.map((msg, index) => (
                                            <motion.div
                                                key={msg.id}
                                                initial={{ opacity: 0, y: 15 }}
                                                animate={{ opacity: 1, y: 0 }}
                                                transition={{ duration: 0.4, delay: index === messages.length - 1 ? 0 : 0 }}
                                            >
                                                <ChatMessage message={msg} />
                                            </motion.div>
                                        ))}
                                    </div>
                                    <div ref={messagesEndRef} />
                                </div>
                            )}
                        </motion.div>
                    )}
                </AnimatePresence>

                {/* Metrics Badge */}
                {metrics && currentSessionId && (
                    <div className="absolute top-6 right-8 z-20">
                        <div className={`px-4 py-2 rounded-2xl text-[10px] font-bold tracking-widest uppercase backdrop-blur-xl shadow-sm border transition-all ${metrics.used > metrics.limit * 0.9
                            ? 'bg-red-50/80 text-red-600 border-red-200 animate-pulse'
                            : 'bg-white/70 text-slate-400 border-slate-200'
                            }`}>
                            Tokens: {metrics.used.toLocaleString()} / {metrics.limit.toLocaleString()}
                        </div>
                    </div>
                )}

                {/* Bottom Input Area */}
                <div className="absolute bottom-0 left-0 w-full px-6 pb-8 pt-12 bg-gradient-to-t from-[#f8fbff] via-[#f8fbff]/90 to-transparent pointer-events-none flex justify-center z-10">
                    <div className="w-full max-w-3xl pointer-events-auto">
                        <ChatInput
                            value={inputValue}
                            onChange={setInputValue}
                            onSubmit={handleSubmit}
                            isGenerating={isGenerating}
                            onStop={handleStop}
                        />
                        <div className="text-center mt-4">
                            <span className="text-[11px] text-slate-400 font-medium tracking-tight">
                                Gemini Powered · {activeAgent ? activeAgent.name : 'AI Assistant'}
                            </span>
                        </div>
                    </div>
                </div>
            </main>
        </div>
    );
};

export default ArkPage;
