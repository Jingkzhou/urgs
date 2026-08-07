import React, { useState, useEffect, useRef, useMemo, useLayoutEffect, useCallback } from 'react';
import { v4 as uuidv4 } from 'uuid';
import { RobotOutlined } from '@ant-design/icons';
import { Sparkles, Database, Cpu, Layers, PenTool, ArrowDown, PanelLeftClose, PanelLeftOpen, SquarePen, Bot } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { WebviewWindow } from '@tauri-apps/api/webviewWindow';
import Sidebar from './Sidebar';
import ChatMessage from './ChatMessage';
import ChatInput from './ChatInput';
import { isDesktopRuntime } from '../../config';
import {
    Message, type AgentAppSkill, type ConversationContextMessage, createSession, streamChatResponse, loadSessionMessages, generateSessionTitle, getAgents, getRoleAgents, getAgentAppSkills
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

interface ArkLaunchTask {
    agentId?: number | string;
    prompt?: string;
    requestId: number;
}

interface ArkPageProps {
    launchTask?: ArkLaunchTask | null;
    onLaunchTaskHandled: () => void;
}

const parseAgentAppTools = (value: any) => {
    if (!value) return [];
    if (Array.isArray(value)) return value.map(String).map(item => item.trim().toLowerCase()).filter(Boolean);
    if (typeof value !== 'string') return [];
    try {
        const parsed = JSON.parse(value);
        if (Array.isArray(parsed)) {
            return parsed.map(String).map(item => item.trim().toLowerCase()).filter(Boolean);
        }
    } catch (e) {
        // Fallback to comma separated values.
    }
    return value.split(',').map(item => item.trim().toLowerCase()).filter(Boolean);
};

const buildConversationContext = (items: Message[]): ConversationContextMessage[] => {
    return items
        .filter(item => (item.role === 'user' || item.role === 'assistant') && item.content.trim())
        .map(item => ({
            role: item.role,
            content: item.content
        }));
};

const ArkPage: React.FC<ArkPageProps> = ({ launchTask, onLaunchTaskHandled }) => {
    // ... state remains the same ...
    const [currentSessionId, setCurrentSessionId] = useState<string | null>(null);
    const [messages, setMessages] = useState<Message[]>([]);
    const [inputValue, setInputValue] = useState('');
    const [isGenerating, setIsGenerating] = useState(false);
    const [metrics, setMetrics] = useState<{ used: number, limit: number } | null>(null);
    const [agents, setAgents] = useState<any[]>([]);
    const [activeAgent, setActiveAgent] = useState<any | null>(null);
    const [agentAppSkills, setAgentAppSkills] = useState<AgentAppSkill[]>([]);
    const [selectedAgentAppSkill, setSelectedAgentAppSkill] = useState<AgentAppSkill | null>(null);
    const [loading, setLoading] = useState(true);
    const [isDraftOpen, setIsDraftOpen] = useState(true);
    const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(true);
    const [scrollTop, setScrollTop] = useState(0);
    const [viewportHeight, setViewportHeight] = useState(0);
    const openingGrokTaskCenterRef = useRef<Promise<void> | null>(null);

    const focusGrokTaskCenter = async (window: WebviewWindow) => {
        await window.unminimize();
        await window.show();
        try {
            await window.setFullscreen(false);
        } catch (error) {
            console.warn('无法退出智能任务中心全屏状态，继续使用最大化窗口', error);
        }
        await window.maximize();
        await window.setFocus();
    };

    const openGrokTaskCenter = async () => {
        if (!isDesktopRuntime()) {
            window.open('#/grok-task-center', '_blank', 'noopener,noreferrer');
            return;
        }

        if (openingGrokTaskCenterRef.current) {
            await openingGrokTaskCenterRef.current;
            return;
        }

        const opening = (async () => {
            const existingWindow = await WebviewWindow.getByLabel('grok-task-center');
            if (existingWindow) {
                await focusGrokTaskCenter(existingWindow);
                return;
            }

            const taskCenterWindow = new WebviewWindow('grok-task-center', {
                url: '/#/grok-task-center',
                title: 'URGS 智能任务中心',
                width: 1440,
                height: 900,
                minWidth: 1100,
                minHeight: 700,
                maximized: true,
                decorations: true,
                resizable: true,
                visible: true,
                focus: true,
            });

            await new Promise<void>((resolve, reject) => {
                taskCenterWindow.once('tauri://created', async () => {
                    try {
                        await focusGrokTaskCenter(taskCenterWindow);
                        resolve();
                    } catch (error) {
                        reject(error);
                    }
                });
                taskCenterWindow.once('tauri://error', (event) => {
                    reject(new Error(`无法打开 URGS 智能任务中心窗口：${String(event.payload)}`));
                });
            });
        })();

        openingGrokTaskCenterRef.current = opening;
        try {
            await opening;
        } catch (error) {
            console.error('无法打开 URGS 智能任务中心窗口', error);
        } finally {
            if (openingGrokTaskCenterRef.current === opening) {
                openingGrokTaskCenterRef.current = null;
            }
        }
    };
    const [measurementVersion, setMeasurementVersion] = useState(0);

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
            await fetchAgents();
            setCurrentSessionId(null);
            setMessages([]);
            setActiveAgent(null);
            setInputValue('');
            setMetrics(null);
            setIsDraftOpen(true);
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

    useEffect(() => {
        const loadAgentAppSkills = async () => {
            setSelectedAgentAppSkill(null);
            if (activeAgent?.buildMode !== 'AGENT_APP') {
                setAgentAppSkills([]);
                return;
            }
            const appTools = parseAgentAppTools(activeAgent.agentAppTools);
            if (appTools.length === 0) {
                setAgentAppSkills([]);
                return;
            }
            const skills = await getAgentAppSkills(appTools);
            setAgentAppSkills(skills);
        };
        loadAgentAppSkills();
    }, [activeAgent?.id, activeAgent?.buildMode]);

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
        setIsDraftOpen(false);
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
        setCurrentSessionId(null);
        setMessages([]);
        setInputValue('');
        setMetrics(null);
        setIsDraftOpen(true);
        setActiveAgent(searchId !== undefined && searchId !== null
            ? agents.find(a => String(a.id) === String(searchId)) || null
            : null);
        if (isGenerating) handleStop();
    };

    useEffect(() => {
        if (!launchTask || loading) return;
        handleNewChat(launchTask.agentId);
        setInputValue(launchTask.prompt || '');
        onLaunchTaskHandled();
    }, [launchTask?.requestId, loading, agents]);

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
        if (!inputValue.trim()) return;
        const userText = inputValue;
        const conversationContext = buildConversationContext(messages);
        const isFirstMessage = messages.length === 0;
        setInputValue('');
        setIsGenerating(true);
        let sessionIdForRequest = currentSessionId;
        if (!sessionIdForRequest) {
            const newSession = await createSession(activeAgent?.id);
            sessionIdForRequest = newSession.id;
            isSwitchingSession.current = true;
            setCurrentSessionId(newSession.id);
            setIsDraftOpen(false);
        }
        const persistedSessionId = sessionIdForRequest;
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
                            await generateSessionTitle(persistedSessionId);
                            setSidebarRefreshTrigger(prev => prev + 1);
                        } catch (e) {
                            console.error("Title generation failed", e);
                        }
                    }
                },
                abortControllerRef.current.signal,
                persistedSessionId,
                (m) => setMetrics(m),
                (status) => {
                    setMessages(prev => {
                        const index = prev.findIndex(m => m.id === aiMsgId);
                        if (index === -1) return prev;
                        const next = prev.slice();
                        next[index] = { ...prev[index], status };
                        return next;
                    });
                },
                selectedAgentAppSkill,
                conversationContext
            );
        } catch (e) {
            flushStreamingUpdate();
            resetStreamingState();
            setIsGenerating(false);
        } finally {
            setSelectedAgentAppSkill(null);
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
        <div className="flex h-full min-h-0 flex-col overflow-hidden rounded-lg border border-slate-200 bg-white font-sans text-[#0d0d0d] shadow-sm">
            <header className="flex h-14 flex-shrink-0 items-center justify-between border-b border-slate-200 bg-white px-3">
                <div className="flex items-center gap-1.5">
                    <button
                        onClick={() => setIsSidebarCollapsed(prev => !prev)}
                        className="flex h-9 w-9 items-center justify-center rounded-lg text-slate-500 transition-colors hover:bg-[#f4f4f4] hover:text-slate-900"
                        title={isSidebarCollapsed ? '展开侧边栏' : '折叠侧边栏'}
                    >
                        {isSidebarCollapsed ? <PanelLeftOpen size={18} /> : <PanelLeftClose size={18} />}
                    </button>
                    <button
                        onClick={() => handleNewChat()}
                        className="flex h-9 w-9 items-center justify-center rounded-lg text-slate-500 transition-colors hover:bg-[#f4f4f4] hover:text-slate-900"
                        title="新建对话"
                    >
                        <SquarePen size={18} />
                    </button>
                    {isDesktopRuntime() && (
                        <button
                            onClick={() => void openGrokTaskCenter()}
                            className="flex h-9 items-center gap-1.5 rounded-lg px-2.5 text-sm font-medium text-slate-500 transition-colors hover:bg-[#f4f4f4] hover:text-slate-900"
                            title="打开独立的 URGS 智能任务中心"
                        >
                            <Bot size={17} />
                            <span className="hidden sm:inline">Agents</span>
                        </button>
                    )}
                </div>

                <div className="min-w-0 flex-1 px-3">
                    <button
                        type="button"
                        className="mx-auto flex max-w-full items-center gap-2 rounded-lg px-3 py-2 text-sm font-semibold text-slate-800 transition-colors hover:bg-[#f4f4f4]"
                        title={activeAgent?.description || '当前助手'}
                    >
                        <span className="truncate">{activeAgent ? activeAgent.name : 'ARK'}</span>
                        {activeAgent?.buildMode === 'AGENT_APP' && (
                            <span className="shrink-0 rounded-md bg-slate-100 px-2 py-0.5 text-[11px] font-medium text-slate-500">
                                Agent App
                            </span>
                        )}
                    </button>
                </div>

                <div className="w-9" />
            </header>

            <div className="flex min-h-0 flex-1">
                <AnimatePresence initial={false}>
                    {!isSidebarCollapsed && (
                        <Sidebar
                            currentSessionId={currentSessionId}
                            onSessionSelect={handleSessionSelect}
                            onNewChat={handleNewChat}
                            refreshTrigger={sidebarRefreshTrigger}
                            isCollapsed={false}
                        />
                    )}
                </AnimatePresence>

                <main className="relative flex min-w-0 flex-1 flex-col bg-white">
                    <AnimatePresence mode="wait">
                        {!isDraftOpen && !currentSessionId ? (
                        <motion.div
                            key="hub"
                            initial={{ opacity: 0, y: 8 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: -8 }}
                            className="flex-1 overflow-y-auto px-4 pb-48 pt-16 md:px-8"
                        >
                            <div className="mx-auto flex min-h-full w-full max-w-3xl flex-col items-center justify-center">
                                <button
                                    type="button"
                                    onClick={async () => {
                                        setCurrentSessionId(null);
                                        setMessages([]);
                                        setInputValue('');
                                        setActiveAgent(null);
                                        setIsDraftOpen(true);
                                    }}
                                    className="mb-6 flex h-12 w-12 items-center justify-center rounded-full border border-slate-200 bg-white text-slate-900 shadow-sm transition-colors hover:bg-[#f4f4f4]"
                                    title="打开通用助手"
                                >
                                    <Sparkles size={22} />
                                </button>
                                <h1 className="mb-8 text-center text-3xl font-semibold leading-tight text-[#0d0d0d] md:text-4xl">
                                    今天想做什么？
                                </h1>

                                <div className="grid w-full grid-cols-1 gap-2 sm:grid-cols-2">
                                    {agents.map(agent => (
                                        <button
                                            key={agent.id}
                                            type="button"
                                            onClick={() => handleNewChat(agent.id)}
                                            className="group flex min-h-[92px] items-start gap-3 rounded-lg border border-slate-200 bg-white p-4 text-left transition-colors hover:bg-[#f7f7f7]"
                                        >
                                            <span className="mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-[#f4f4f4] text-slate-700">
                                                <RobotOutlined className="text-base" />
                                            </span>
                                            <span className="min-w-0">
                                                <span className="block truncate text-sm font-semibold text-slate-900">{agent.name}</span>
                                                <span className="mt-1 line-clamp-2 block text-sm leading-5 text-slate-500">
                                                    {agent.description || '专业处理特定领域任务'}
                                                </span>
                                            </span>
                                        </button>
                                    ))}

                                    <button
                                        type="button"
                                        onClick={async () => {
                                            setCurrentSessionId(null);
                                            setMessages([]);
                                            setInputValue('');
                                            setActiveAgent(null);
                                            setIsDraftOpen(true);
                                        }}
                                        className="group flex min-h-[92px] items-start gap-3 rounded-lg border border-slate-200 bg-white p-4 text-left transition-colors hover:bg-[#f7f7f7]"
                                    >
                                        <span className="mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-[#f4f4f4] text-slate-700">
                                            <Sparkles size={16} />
                                        </span>
                                        <span>
                                            <span className="block text-sm font-semibold text-slate-900">通用助手</span>
                                            <span className="mt-1 block text-sm leading-5 text-slate-500">
                                                写作、分析、规划、代码和日常协作。
                                            </span>
                                        </span>
                                    </button>
                                </div>
                            </div>
                        </motion.div>
                    ) : (
                        <motion.div
                            key="chat"
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            ref={scrollContainerRef}
                            onScroll={handleScroll}
                            className="custom-scrollbar flex flex-1 flex-col items-center overflow-y-auto bg-white"
                        >
                            {messages.length === 0 ? (
                                <motion.div
                                    initial={{ opacity: 0, y: 20 }}
                                    animate={{ opacity: 1, y: 0 }}
                                    className="relative z-10 flex min-h-full w-full max-w-3xl flex-col items-center justify-center px-4 pb-48 pt-10"
                                >
                                    <div className="mb-8 text-center">
                                        <h1 className="mb-3 text-3xl font-semibold leading-tight text-[#0d0d0d] md:text-4xl">
                                            {activeAgent ? `你好，我是 ${activeAgent.name}` : '你好，今天有什么想聊的？'}
                                        </h1>
                                        <p className="mx-auto max-w-xl text-sm leading-6 text-slate-500">
                                            {activeAgent?.description || "我可以在写作、规划或解决问题方面为你提供帮助。"}
                                        </p>
                                    </div>

                                    <div className="grid w-full grid-cols-1 gap-2 sm:grid-cols-2">
                                        {(activeAgent?.prompts && activeAgent.prompts.length > 0 ? activeAgent.prompts : [
                                            { title: '提供建议', content: '如何更高效地管理时间？', icon: <Cpu size={16} /> },
                                            { title: '撰写内容', content: '写一篇关于可持续发展的演讲稿。', icon: <PenTool size={16} /> },
                                            { title: '数据分析', content: '解释什么是大模型微调及其原理。', icon: <Layers size={16} /> },
                                            { title: '辅助编码', content: '使用 React 实现一个深色模式切换功能。', icon: <Database size={16} /> },
                                        ]).slice(0, 4).map((item: any, i: number) => (
                                            <motion.button
                                                key={i}
                                                whileHover={{ backgroundColor: "#f7f7f7" }}
                                                onClick={() => setInputValue(`${item.content}`)}
                                                className="group flex min-h-[78px] items-start gap-3 rounded-lg border border-slate-200 bg-white p-4 text-left transition-colors"
                                            >
                                                <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-[#f4f4f4] text-slate-500 transition-colors group-hover:text-slate-900">
                                                    {item.icon || <Sparkles size={16} />}
                                                </div>
                                                <div className="min-w-0">
                                                    <span className="mb-1 block text-sm font-semibold text-slate-800">{item.title}</span>
                                                    <span className="line-clamp-1 text-sm text-slate-500">{item.content}</span>
                                                </div>
                                            </motion.button>
                                        ))}
                                    </div>
                                </motion.div>
                            ) : (
                                <div className="flex w-full flex-col items-center pb-48 pt-6">
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
                                                    isWide={false}
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
                            className="absolute bottom-32 -translate-x-1/2 left-1/2 z-20 flex h-9 w-9 items-center justify-center rounded-full bg-white text-slate-500 ring-1 ring-slate-200 transition-colors hover:bg-slate-50 hover:text-slate-900"
                        >
                            <ArrowDown size={16} />
                        </motion.button>
                    )}
                </AnimatePresence>

                {/* Metrics Badge */}
                {metrics && currentSessionId && (
                    <div className="absolute top-6 right-8 z-20">
                        <div className={`rounded-lg border px-3 py-2 text-[11px] font-semibold backdrop-blur-xl transition-all ${metrics.used > metrics.limit * 0.9
                            ? 'bg-red-50/80 text-red-600 border-red-200 animate-pulse'
                            : 'bg-white/80 text-slate-500 border-slate-200'
                            }`}>
                            Tokens: {metrics.used.toLocaleString()} / {metrics.limit.toLocaleString()}
                        </div>
                    </div>
                )}

                {/* Bottom Input Area */}
                <div className="pointer-events-none absolute bottom-0 left-0 z-10 flex w-full justify-center bg-gradient-to-t from-white via-white to-transparent px-4 pb-5 pt-16">
                    <div className="pointer-events-auto w-full max-w-3xl">
                        <ChatInput
                            value={inputValue}
                            onChange={setInputValue}
                            onSubmit={handleSubmit}
                            isGenerating={isGenerating}
                            onStop={handleStop}
                            isWide={false}
                            agentAppSkills={agentAppSkills}
                            selectedAgentAppSkill={selectedAgentAppSkill}
                            onAgentAppSkillSelect={setSelectedAgentAppSkill}
                            onAgentAppSkillClear={() => setSelectedAgentAppSkill(null)}
                        />
                    </div>
                </div>
                </main>
            </div>
        </div>
    );
};

interface VirtualizedMessageRowProps {
    message: Message;
    top: number;
    index: number;
    isStreaming: boolean;
    onHeightChange: (id: string, height: number, index: number) => void;
    isWide: boolean;
}

const VirtualizedMessageRow: React.FC<VirtualizedMessageRowProps> = React.memo(({
    message,
    top,
    index,
    isStreaming,
    onHeightChange,
    isWide
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
            <div className={`mx-auto w-full px-4 ${isWide ? 'max-w-4xl' : 'max-w-3xl'}`}>
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
