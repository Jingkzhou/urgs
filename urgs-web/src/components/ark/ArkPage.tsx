import React, { useState, useEffect, useRef, useMemo, useLayoutEffect, useCallback } from 'react';
import { v4 as uuidv4 } from 'uuid';
import { RobotOutlined } from '@ant-design/icons';
import { Sparkles, Database, ChevronRight, User, Cpu, Layers, PenTool, Settings, Sliders, ArrowDown } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import Sidebar from './Sidebar';
import ChatMessage from './ChatMessage';
import ChatInput from './ChatInput';
import {
    Message, Session, getSessions, createSession, streamChatResponse, loadSessionMessages, generateSessionTitle, getAgents, getRoleAgents
} from '../../api/chat';

const STREAM_THROTTLE_MS = 80;
const ESTIMATED_MESSAGE_HEIGHT = 140;
const OVERSCAN_COUNT = 8;
const SCROLL_IDLE_MS = 120;

interface SessionState {
    scrollTop: number;
    itemHeights: Map<string, number>;
    isAtBottom: boolean;
}

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
    const [scrollTop, setScrollTop] = useState(0);
    const [viewportHeight, setViewportHeight] = useState(0);
    const [measurementVersion, setMeasurementVersion] = useState(0);

    // RAG Config
    const [showRagConfig, setShowRagConfig] = useState(false);
    const [ragConfig, setRagConfig] = useState({
        fusionStrategy: 'rrf', // rrf | weighted
        topK: 4
    });
    const [showScrollBottom, setShowScrollBottom] = useState(false);

    const abortControllerRef = useRef<AbortController | null>(null);
    const messagesEndRef = useRef<HTMLDivElement>(null);
    const isSwitchingSession = useRef(false);
    const streamingMessageIdRef = useRef<string | null>(null);
    const streamingMessageIndexRef = useRef<number | null>(null);
    const streamingContentRef = useRef('');
    const flushTimerRef = useRef<number | null>(null);
    const itemHeightsRef = useRef<Map<string, number>>(new Map());
    const pendingHeightsRef = useRef<Map<string, number>>(new Map());
    const startIndexRef = useRef(0);
    const scrollRafRef = useRef<number | null>(null);
    const scrollIdleTimerRef = useRef<number | null>(null);
    const isScrollingRef = useRef(false);
    const messagesRef = useRef<Message[]>([]);
    const sessionStatesRef = useRef<Map<string, SessionState>>(new Map());

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

    useEffect(() => {
        return () => {
            if (flushTimerRef.current !== null) {
                window.clearTimeout(flushTimerRef.current);
            }
            if (scrollRafRef.current !== null) {
                window.cancelAnimationFrame(scrollRafRef.current);
            }
            if (scrollIdleTimerRef.current !== null) {
                window.clearTimeout(scrollIdleTimerRef.current);
            }
        };
    }, []);

    const scrollContainerRef = useRef<HTMLDivElement>(null);
    const isAtBottom = useRef(true);

    useEffect(() => {
        // Save current session state before switching if there was a previous session
        // Note: This effect runs AFTER currentSessionId changes, so we can't save the OLD session here directly
        // unless we track 'previousSessionId'. 
        // Better strategy: The logic to save state should be in handleSessionSelect/handleNewChat
        // before setSessionId is called. But for restoration, we do it here.

        const state = currentSessionId ? sessionStatesRef.current.get(currentSessionId) : undefined;

        if (state) {
            itemHeightsRef.current = new Map(state.itemHeights);
            // pendingHeightsRef should technically be empty on switch usually
            pendingHeightsRef.current = new Map();
        } else {
            itemHeightsRef.current = new Map();
            pendingHeightsRef.current = new Map();
        }

        messagesRef.current = messages; // This might be redundant with line 130 but harmless
        setMeasurementVersion(prev => prev + 1);

        // Scroll restoration happens in the scroll effect or layout effect, 
        // but we need to reset scrollTop state here to avoid jitter if it's a new session
        if (state) {
            setScrollTop(state.scrollTop);
        } else {
            setScrollTop(0);
        }
    }, [currentSessionId]);

    useEffect(() => {
        messagesRef.current = messages;
    }, [messages]);

    useLayoutEffect(() => {
        const container = scrollContainerRef.current;
        if (!container) return;
        const updateViewport = () => {
            setViewportHeight(container.clientHeight);
        };
        updateViewport();
        const observer = new ResizeObserver(() => updateViewport());
        observer.observe(container);
        return () => observer.disconnect();
    }, []);

    const { offsets, totalHeight } = useMemo(() => {
        const nextOffsets = new Array(messages.length + 1);
        nextOffsets[0] = 0;
        for (let i = 0; i < messages.length; i += 1) {
            const msg = messages[i];
            const measured = itemHeightsRef.current.get(msg.id);
            const height = measured ?? ESTIMATED_MESSAGE_HEIGHT;
            nextOffsets[i + 1] = nextOffsets[i] + height;
        }
        return { offsets: nextOffsets, totalHeight: nextOffsets[messages.length] };
    }, [messages, measurementVersion]);

    const startIndex = useMemo(() => {
        if (messages.length === 0) return 0;
        let low = 0;
        let high = messages.length - 1;
        while (low < high) {
            const mid = Math.floor((low + high) / 2);
            if (offsets[mid + 1] <= scrollTop) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return low;
    }, [offsets, scrollTop, messages.length]);

    const endIndex = useMemo(() => {
        if (messages.length === 0) return 0;
        const target = scrollTop + viewportHeight;
        let low = 0;
        let high = messages.length;
        while (low < high) {
            const mid = Math.floor((low + high) / 2);
            if (offsets[mid] < target) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return low;
    }, [offsets, scrollTop, viewportHeight, messages.length]);

    const rangeStart = Math.max(0, startIndex - OVERSCAN_COUNT);
    const rangeEnd = Math.min(messages.length, endIndex + OVERSCAN_COUNT);
    const visibleMessages = useMemo(() => {
        return messages.slice(rangeStart, rangeEnd);
    }, [messages, rangeStart, rangeEnd]);

    useEffect(() => {
        startIndexRef.current = rangeStart;
    }, [rangeStart]);

    const flushPendingMeasurements = useCallback(() => {
        if (pendingHeightsRef.current.size === 0) return;
        const container = scrollContainerRef.current;
        const currentMessages = messagesRef.current;
        let updated = false;
        let delta = 0;
        for (let i = 0; i < currentMessages.length; i += 1) {
            const msg = currentMessages[i];
            const pendingHeight = pendingHeightsRef.current.get(msg.id);
            if (pendingHeight === undefined) continue;
            const prevHeight = itemHeightsRef.current.get(msg.id);
            if (prevHeight !== pendingHeight) {
                itemHeightsRef.current.set(msg.id, pendingHeight);
                updated = true;
                if (i < startIndexRef.current) {
                    delta += pendingHeight - (prevHeight ?? ESTIMATED_MESSAGE_HEIGHT);
                }
            }
        }
        pendingHeightsRef.current.clear();
        if (updated) {
            if (delta !== 0 && container) {
                container.scrollTop += delta;
                setScrollTop(container.scrollTop);
            }
            setMeasurementVersion(prev => prev + 1);
        }
    }, []);

    const handleItemResize = useCallback((id: string, height: number, index: number) => {
        if (!height) return;
        const nextHeight = Math.max(1, Math.round(height));
        if (isScrollingRef.current) {
            pendingHeightsRef.current.set(id, nextHeight);
            return;
        }
        const prevHeight = itemHeightsRef.current.get(id);
        if (prevHeight === nextHeight) return;
        itemHeightsRef.current.set(id, nextHeight);
        setMeasurementVersion(prev => prev + 1);
        const container = scrollContainerRef.current;
        if (container && index < startIndexRef.current) {
            const delta = nextHeight - (prevHeight ?? ESTIMATED_MESSAGE_HEIGHT);
            if (delta !== 0) {
                container.scrollTop += delta;
                setScrollTop(container.scrollTop);
            }
        }
    }, []);

    const handleScroll = () => {
        if (!scrollContainerRef.current) return;
        const { scrollTop, scrollHeight, clientHeight } = scrollContainerRef.current;
        const isBottom = Math.abs(scrollHeight - clientHeight - scrollTop) < 50; // Threshold of 50px
        isAtBottom.current = isBottom;
        setShowScrollBottom(!isBottom);
        isScrollingRef.current = true;
        if (scrollIdleTimerRef.current !== null) {
            window.clearTimeout(scrollIdleTimerRef.current);
        }
        scrollIdleTimerRef.current = window.setTimeout(() => {
            isScrollingRef.current = false;
            flushPendingMeasurements();
        }, SCROLL_IDLE_MS);
        if (scrollRafRef.current !== null) return;
        scrollRafRef.current = window.requestAnimationFrame(() => {
            scrollRafRef.current = null;
            if (!scrollContainerRef.current) return;
            setScrollTop(scrollContainerRef.current.scrollTop);
        });
    };

    const scrollToBottom = () => {
        const container = scrollContainerRef.current;
        if (container) {
            container.scrollTo({ top: container.scrollHeight, behavior: 'auto' });
            setScrollTop(container.scrollTop);
            return;
        }
        messagesEndRef.current?.scrollIntoView({ behavior: 'auto' });
    };

    useEffect(() => {
        if (isSwitchingSession.current) {
            const container = scrollContainerRef.current;
            if (!container || !currentSessionId) return;

            const state = sessionStatesRef.current.get(currentSessionId);
            if (state) {
                // Restore saved position
                container.scrollTop = state.scrollTop;
                setScrollTop(state.scrollTop);
                isAtBottom.current = state.isAtBottom;

                // If it was at bottom, ensure it stays at bottom even if new content came in
                if (state.isAtBottom) {
                    scrollToBottom();
                }
            } else {
                // New session or no saved state -> Go to bottom
                scrollToBottom();
                isAtBottom.current = true;
            }
            isSwitchingSession.current = false;
        } else if (isAtBottom.current) {
            scrollToBottom();
        }
    }, [messages, currentSessionId, totalHeight]); // Switched back to [messages] to trigger on streaming updates, but guarded by isAtBottom

    const saveSessionState = () => {
        if (!currentSessionId || !scrollContainerRef.current) return;
        const { scrollTop } = scrollContainerRef.current;
        sessionStatesRef.current.set(currentSessionId, {
            scrollTop,
            itemHeights: new Map(itemHeightsRef.current),
            isAtBottom: isAtBottom.current
        });
    };

    const handleSessionSelect = async (id: string, agentId?: number | string) => {
        if (currentSessionId === id && messages.length > 0) return;
        saveSessionState();
        isSwitchingSession.current = true;
        setCurrentSessionId(id);
        const msgs = await loadSessionMessages(id);
        setMessages(msgs);
        setInputValue('');
        setMetrics(null);
        if (agentId !== undefined && agentId !== null) {
            setActiveAgent(agents.find(a => String(a.id) === String(agentId)) || null);
        } else {
            setActiveAgent(null);
        }
        if (isGenerating) handleStop();
    };

    const handleNewChat = async (agentId?: number | string | React.MouseEvent) => {
        saveSessionState();
        const searchId = (typeof agentId === 'number' || typeof agentId === 'string') ? agentId : undefined;
        if (searchId !== undefined && searchId !== null) {
            const newSession = await createSession(searchId);
            setCurrentSessionId(newSession.id);
            setMessages([]);
            setInputValue('');
            setMetrics(null);
            setActiveAgent(agents.find(a => String(a.id) === String(searchId)) || null);
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

    const resetStreamingState = () => {
        if (flushTimerRef.current !== null) {
            window.clearTimeout(flushTimerRef.current);
            flushTimerRef.current = null;
        }
        streamingMessageIdRef.current = null;
        streamingMessageIndexRef.current = null;
        streamingContentRef.current = '';
    };

    const flushStreamingUpdate = () => {
        flushTimerRef.current = null;
        const currentId = streamingMessageIdRef.current;
        if (!currentId) return;
        const content = streamingContentRef.current;
        setMessages(prev => {
            if (prev.length === 0) return prev;
            let targetIndex = streamingMessageIndexRef.current;
            if (targetIndex === null || !prev[targetIndex] || prev[targetIndex].id !== currentId) {
                targetIndex = prev.findIndex(m => m.id === currentId);
                if (targetIndex === -1) return prev;
                streamingMessageIndexRef.current = targetIndex;
            }
            const current = prev[targetIndex];
            if (current.content === content) return prev;
            const next = prev.slice();
            next[targetIndex] = { ...current, content };
            return next;
        });
    };

    const scheduleFlush = () => {
        if (flushTimerRef.current !== null) return;
        flushTimerRef.current = window.setTimeout(() => {
            flushStreamingUpdate();
        }, STREAM_THROTTLE_MS);
    };

    const handleStop = () => {
        if (abortControllerRef.current) {
            abortControllerRef.current.abort();
            abortControllerRef.current = null;
        }
        flushStreamingUpdate();
        resetStreamingState();
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
        const aiMsgId = uuidv4();
        const aiMsgPlaceholder: Message = { id: aiMsgId, role: 'assistant', content: '', timestamp: Date.now() };
        streamingMessageIdRef.current = aiMsgId;
        streamingMessageIndexRef.current = null;
        streamingContentRef.current = '';
        setMessages(prev => {
            const next = [...prev, userMsg, aiMsgPlaceholder];
            streamingMessageIndexRef.current = next.length - 1;
            return next;
        });
        abortControllerRef.current = new AbortController();
        try {
            await streamChatResponse(
                userText,
                (chunk) => {
                    streamingContentRef.current += chunk;
                    scheduleFlush();
                },
                async () => {
                    flushStreamingUpdate();
                    resetStreamingState();
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
                    setMessages(prev => {
                        const index = prev.findIndex(m => m.id === aiMsgId);
                        if (index === -1) return prev;
                        const next = prev.slice();
                        next[index] = { ...prev[index], sources, status: null }; // Clear status when sources arrive
                        return next;
                    });
                },
                (status) => {
                    setMessages(prev => {
                        const index = prev.findIndex(m => m.id === aiMsgId);
                        if (index === -1) return prev;
                        const next = prev.slice();
                        next[index] = { ...prev[index], status };
                        return next;
                    });
                },
                (intent) => {
                    setMessages(prev => {
                        const index = prev.findIndex(m => m.id === aiMsgId);
                        if (index === -1) return prev;
                        const next = prev.slice();
                        next[index] = { ...prev[index], intent }; // Update intent
                        return next;
                    });
                },
                ragConfig // Pass config here
            );
        } catch (e) {
            flushStreamingUpdate();
            resetStreamingState();
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
        <div className="flex h-full ark-mesh-bg ark-noise-overlay font-sans text-slate-800 overflow-hidden">
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
                            <div className="text-center mb-16 relative z-10">
                                <motion.h1
                                    initial={{ y: 20 }}
                                    animate={{ y: 0 }}
                                    className="text-6xl ark-heading ark-heading-gradient mb-6"
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
                                        className="group relative flex flex-col items-start p-8 ark-agent-card rounded-[28px] text-left"
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
                                    className="group relative flex flex-col items-start p-8 ark-primary-card text-white rounded-[28px] transition-all duration-500 text-left"
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
                                    className="flex-1 flex flex-col items-center justify-center p-4 w-full max-w-3xl -mt-20 relative z-10"
                                >
                                    <div className="mb-10 text-center">
                                        <h1 className="text-5xl ark-heading ark-heading-gradient mb-4">
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
                                    <div className="w-full relative" style={{ height: totalHeight }}>
                                        {visibleMessages.map((msg, index) => {
                                            const messageIndex = rangeStart + index;
                                            const top = offsets[messageIndex] || 0;
                                            return (
                                                <VirtualizedMessageRow
                                                    key={msg.id}
                                                    message={msg}
                                                    top={top}
                                                    index={messageIndex}
                                                    isStreaming={isGenerating && msg.id === streamingMessageIdRef.current}
                                                    onHeightChange={handleItemResize}
                                                />
                                            );
                                        })}
                                        <div ref={messagesEndRef} className="absolute left-0 right-0" style={{ top: totalHeight + 1, height: 1 }} />
                                    </div>
                                </div>
                            )}
                        </motion.div>
                    )}
                </AnimatePresence>

                {/* Scroll to Bottom Button */}
                <AnimatePresence>
                    {showScrollBottom && currentSessionId && (
                        <motion.button
                            initial={{ opacity: 0, scale: 0.8, y: 10 }}
                            animate={{ opacity: 1, scale: 1, y: 0 }}
                            exit={{ opacity: 0, scale: 0.8, y: 10 }}
                            onClick={() => {
                                scrollToBottom();
                                setShowScrollBottom(false);
                            }}
                            className="absolute bottom-32 -translate-x-1/2 left-1/2 z-20 flex h-9 w-9 items-center justify-center rounded-full bg-white text-slate-500 shadow-md ring-1 ring-slate-200/50 transition-colors hover:bg-slate-50 hover:text-blue-600"
                        >
                            <ArrowDown size={16} />
                        </motion.button>
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
                <div className="absolute bottom-0 left-0 w-full px-6 pb-6 pt-16 bg-gradient-to-t from-[#f8fbff] via-[#f8fbff]/95 to-transparent pointer-events-none flex justify-center z-10">
                    <div className="w-full max-w-3xl pointer-events-auto">
                        <ChatInput
                            value={inputValue}
                            onChange={setInputValue}
                            onSubmit={handleSubmit}
                            isGenerating={isGenerating}
                            onStop={handleStop}
                        />
                        <div className="text-center mt-4 flex items-center justify-center gap-4 relative">
                            <span className="text-[11px] text-slate-400 font-medium tracking-tight">
                                Qwen3 驱动 · {activeAgent ? activeAgent.name : 'AI 助手'}
                            </span>

                            {/* RAG Config Toggle */}
                            <button
                                onClick={() => setShowRagConfig(!showRagConfig)}
                                className={`flex items-center gap-1 text-[10px] font-bold tracking-widest px-2 py-1 rounded-full transition-all border ${showRagConfig ? 'bg-blue-50 text-blue-600 border-blue-200' : 'text-slate-400 border-transparent hover:bg-white hover:border-slate-200'
                                    }`}
                            >
                                <Settings size={12} />
                                {ragConfig.fusionStrategy === 'rrf' ? 'RRF 模式' : '加权模式'}
                            </button>

                            {/* RAG Config Popup */}
                            <AnimatePresence>
                                {showRagConfig && (
                                    <motion.div
                                        initial={{ opacity: 0, y: 10, scale: 0.95 }}
                                        animate={{ opacity: 1, y: 0, scale: 1 }}
                                        exit={{ opacity: 0, y: 10, scale: 0.95 }}
                                        className="absolute bottom-full mb-3 bg-white/90 backdrop-blur-xl border border-white/40 shadow-xl rounded-2xl p-4 w-64 text-left z-30"
                                    >
                                        <div className="flex items-center gap-2 mb-3 text-slate-800 font-bold text-xs uppercase tracking-widest border-b border-slate-100 pb-2">
                                            <Sliders size={14} className="text-blue-500" />
                                            RAG 检索优化
                                        </div>

                                        <div className="mb-4">
                                            <label className="block text-[10px] text-slate-500 font-bold mb-2">融合策略</label>
                                            <div className="flex bg-slate-100/50 p-1 rounded-lg">
                                                <button
                                                    onClick={() => setRagConfig(prev => ({ ...prev, fusionStrategy: 'rrf' }))}
                                                    className={`flex-1 py-1.5 text-[10px] font-bold rounded-md transition-all ${ragConfig.fusionStrategy === 'rrf' ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-400 hover:text-slate-600'
                                                        }`}
                                                >
                                                    RRF 融合
                                                </button>
                                                <button
                                                    onClick={() => setRagConfig(prev => ({ ...prev, fusionStrategy: 'weighted' }))}
                                                    className={`flex-1 py-1.5 text-[10px] font-bold rounded-md transition-all ${ragConfig.fusionStrategy === 'weighted' ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-400 hover:text-slate-600'
                                                        }`}
                                                >
                                                    加权融合
                                                </button>
                                            </div>
                                        </div>

                                        <div>
                                            <div className="flex justify-between mb-2">
                                                <label className="text-[10px] text-slate-500 font-bold">召回数量 (Top K)</label>
                                                <span className="text-[10px] font-mono font-bold text-blue-600">{ragConfig.topK}</span>
                                            </div>
                                            <input
                                                type="range"
                                                min="2" max="10" step="1"
                                                value={ragConfig.topK}
                                                onChange={(e) => setRagConfig(prev => ({ ...prev, topK: parseInt(e.target.value) }))}
                                                className="w-full h-1.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-blue-500"
                                            />
                                        </div>
                                    </motion.div>
                                )}
                            </AnimatePresence>
                        </div>
                    </div>
                </div>
            </main>
        </div>
    );
};

interface VirtualizedMessageRowProps {
    message: Message;
    top: number;
    index: number;
    isStreaming: boolean;
    onHeightChange: (id: string, height: number, index: number) => void;
}

const VirtualizedMessageRow: React.FC<VirtualizedMessageRowProps> = React.memo(({
    message,
    top,
    index,
    isStreaming,
    onHeightChange
}) => {
    const rowRef = useRef<HTMLDivElement>(null);

    useLayoutEffect(() => {
        const node = rowRef.current;
        if (!node) return;
        const reportHeight = () => {
            const height = node.getBoundingClientRect().height;
            if (height) {
                onHeightChange(message.id, height, index);
            }
        };
        reportHeight();
        const observer = new ResizeObserver(() => reportHeight());
        observer.observe(node);
        return () => observer.disconnect();
    }, [message.id, index, onHeightChange]);

    return (
        <div ref={rowRef} className="absolute left-0 right-0 pb-8" style={{ top }}>
            <div className="w-full max-w-4xl mx-auto px-6">
                <motion.div
                    initial={{ opacity: 0, y: 15 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.4 }}
                >
                    <ChatMessage message={message} isStreaming={isStreaming} />
                </motion.div>
            </div>
        </div>
    );
});

export default ArkPage;
