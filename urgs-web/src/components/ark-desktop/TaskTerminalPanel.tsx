import React, { useCallback, useEffect, useRef, useState } from 'react';
import { listen } from '@tauri-apps/api/event';
import { FitAddon } from '@xterm/addon-fit';
import { WebglAddon } from '@xterm/addon-webgl';
import { Terminal as XtermTerminal } from '@xterm/xterm';
import '@xterm/xterm/css/xterm.css';
import { Check, Copy, GripHorizontal, Plus, Terminal as TerminalIcon, X } from 'lucide-react';
import {
    closeTerminalSession,
    createTerminalSession,
    resizeTerminalSession,
    writeTerminalSession,
} from '@/services/grokDesktop';
import { copyToClipboard } from '@/utils/clipboard';
import './TaskTerminalPanel.css';

interface TaskTerminalPanelProps {
    workspace: string;
    onClose: () => void;
}

interface TerminalOutputEvent {
    sessionId: string;
    dataBase64: string;
}

interface TerminalExitEvent {
    sessionId: string;
}

interface TerminalTab {
    id: string;
    title: string;
    status: 'connecting' | 'ready' | 'closed' | 'error';
}

interface TerminalScrollState {
    tabId: string;
    baseY: number;
    ydisp: number;
    rows: number;
}

const MIN_PANEL_HEIGHT = 160;
const MAX_PANEL_HEIGHT = 560;
const TERMINAL_THEME = {
    background: '#fbfcfe',
    foreground: '#27364d',
    cursor: '#7664ed',
    cursorAccent: '#fbfcfe',
    selectionBackground: 'rgba(65, 137, 214, 0.48)',
    selectionForeground: '#10243e',
    selectionInactiveBackground: 'rgba(65, 137, 214, 0.28)',
    black: '#27364d',
    red: '#dc2626',
    green: '#15803d',
    yellow: '#a16207',
    blue: '#2563eb',
    magenta: '#7c3aed',
    cyan: '#0e7490',
    white: '#f8fafc',
    brightBlack: '#64748b',
    brightRed: '#ef4444',
    brightGreen: '#16a34a',
    brightYellow: '#ca8a04',
    brightBlue: '#3b82f6',
    brightMagenta: '#8b5cf6',
    brightCyan: '#0891b2',
    brightWhite: '#0f172a',
};

const workspaceName = (value: string) => value.split(/[\\/]/).filter(Boolean).pop() || '工作区';

const decodeBase64Bytes = (value: string) => {
    const binary = window.atob(value);
    const bytes = new Uint8Array(binary.length);
    for (let index = 0; index < binary.length; index += 1) {
        bytes[index] = binary.charCodeAt(index);
    }
    return bytes;
};

const TaskTerminalPanel: React.FC<TaskTerminalPanelProps> = ({ workspace, onClose }) => {
    const name = workspaceName(workspace);
    const [panelHeight, setPanelHeight] = useState(280);
    const [isResizing, setIsResizing] = useState(false);
    const [activeTabId, setActiveTabId] = useState('terminal-1');
    const [tabs, setTabs] = useState<TerminalTab[]>([
        { id: 'terminal-1', title: name, status: 'connecting' },
    ]);
    const [selectedTabId, setSelectedTabId] = useState<string | null>(null);
    const [copyFeedback, setCopyFeedback] = useState(false);
    const [terminalScroll, setTerminalScroll] = useState<TerminalScrollState>({
        tabId: 'terminal-1',
        baseY: 0,
        ydisp: 0,
        rows: 0,
    });
    const resizeStartRef = useRef<{ y: number; height: number } | null>(null);
    const panelContentRef = useRef<HTMLDivElement | null>(null);
    const tabContainerRefs = useRef<Map<string, HTMLDivElement>>(new Map());
    const terminalsRef = useRef<Map<string, XtermTerminal>>(new Map());
    const fitAddonsRef = useRef<Map<string, FitAddon>>(new Map());
    const sessionIdsRef = useRef<Map<string, string>>(new Map());
    const unlistenRefs = useRef<Map<string, Array<() => void>>>(new Map());
    const disposableRefs = useRef<Map<string, Array<{ dispose: () => void }>>>(new Map());
    const selectionStateRef = useRef<Map<string, boolean>>(new Map());
    const tabSequenceRef = useRef(2);
    const isMountedRef = useRef(true);
    const tabsRef = useRef(tabs);
    const copyFeedbackTimeoutRef = useRef<number | null>(null);
    const scrollbarDragRef = useRef<{ tabId: string; pointerId: number } | null>(null);

    useEffect(() => {
        tabsRef.current = tabs;
    }, [tabs]);

    const fitTerminal = useCallback((tabId: string) => {
        const terminal = terminalsRef.current.get(tabId);
        const fitAddon = fitAddonsRef.current.get(tabId);
        const container = tabContainerRefs.current.get(tabId);
        if (!terminal || !fitAddon || !container || container.clientWidth === 0 || container.clientHeight === 0) {
            return;
        }
        fitAddon.fit();
        const sessionId = sessionIdsRef.current.get(tabId);
        if (sessionId) {
            void resizeTerminalSession(sessionId, terminal.cols, terminal.rows).catch(() => undefined);
        }
    }, []);

    const disposeTerminal = useCallback((tabId: string) => {
        const sessionId = sessionIdsRef.current.get(tabId);
        if (sessionId) {
            sessionIdsRef.current.delete(tabId);
            void closeTerminalSession(sessionId).catch(() => undefined);
        }

        unlistenRefs.current.get(tabId)?.forEach((unlisten) => unlisten());
        unlistenRefs.current.delete(tabId);
        disposableRefs.current.get(tabId)?.forEach((disposable) => disposable.dispose());
        disposableRefs.current.delete(tabId);
        fitAddonsRef.current.delete(tabId);
        terminalsRef.current.get(tabId)?.dispose();
        terminalsRef.current.delete(tabId);
        selectionStateRef.current.delete(tabId);
        setSelectedTabId((current) => current === tabId ? null : current);
    }, []);

    const copyTerminalSelection = useCallback(async (tabId: string) => {
        const terminal = terminalsRef.current.get(tabId);
        const selection = terminal?.getSelection() ?? '';
        if (!selection) return;
        if (!await copyToClipboard(selection)) return;

        setCopyFeedback(true);
        if (copyFeedbackTimeoutRef.current !== null) {
            window.clearTimeout(copyFeedbackTimeoutRef.current);
        }
        copyFeedbackTimeoutRef.current = window.setTimeout(() => {
            setCopyFeedback(false);
            copyFeedbackTimeoutRef.current = null;
        }, 1600);
    }, []);

    const syncTerminalScroll = useCallback((tabId: string, terminal: XtermTerminal) => {
        const buffer = terminal.buffer.active;
        const nextState = {
            tabId,
            baseY: buffer.baseY,
            ydisp: buffer.viewportY,
            rows: terminal.rows,
        };
        setTerminalScroll((current) => (
            current.tabId === nextState.tabId
                && current.baseY === nextState.baseY
                && current.ydisp === nextState.ydisp
                && current.rows === nextState.rows
                ? current
                : nextState
        ));
    }, []);

    const scrollTerminalToPointer = useCallback((event: React.PointerEvent<HTMLDivElement>) => {
        const terminal = terminalsRef.current.get(terminalScroll.tabId);
        if (!terminal || terminalScroll.baseY <= 0 || terminalScroll.rows <= 0) return;

        const track = event.currentTarget.getBoundingClientRect();
        const thumbHeight = Math.max(24, track.height * terminalScroll.rows / (terminalScroll.rows + terminalScroll.baseY));
        const maxThumbTop = Math.max(0, track.height - thumbHeight);
        const nextThumbTop = Math.max(0, Math.min(maxThumbTop, event.clientY - track.top - thumbHeight / 2));
        const nextLine = maxThumbTop === 0
            ? 0
            : Math.round(nextThumbTop / maxThumbTop * terminalScroll.baseY);
        terminal.scrollToLine(nextLine);
    }, [terminalScroll]);

    const handleScrollbarPointerDown = useCallback((event: React.PointerEvent<HTMLDivElement>) => {
        if (event.button !== 0 || terminalScroll.baseY <= 0) return;
        event.preventDefault();
        event.currentTarget.setPointerCapture(event.pointerId);
        scrollbarDragRef.current = { tabId: terminalScroll.tabId, pointerId: event.pointerId };
        scrollTerminalToPointer(event);
    }, [scrollTerminalToPointer, terminalScroll.baseY, terminalScroll.tabId]);

    const handleScrollbarPointerMove = useCallback((event: React.PointerEvent<HTMLDivElement>) => {
        const drag = scrollbarDragRef.current;
        if (!drag || drag.pointerId !== event.pointerId || drag.tabId !== terminalScroll.tabId) return;
        event.preventDefault();
        scrollTerminalToPointer(event);
    }, [scrollTerminalToPointer, terminalScroll.tabId]);

    const handleScrollbarPointerUp = useCallback((event: React.PointerEvent<HTMLDivElement>) => {
        const drag = scrollbarDragRef.current;
        if (!drag || drag.pointerId !== event.pointerId) return;
        scrollbarDragRef.current = null;
        event.currentTarget.releasePointerCapture(event.pointerId);
    }, []);

    const handleScrollbarKeyDown = useCallback((event: React.KeyboardEvent<HTMLDivElement>) => {
        const terminal = terminalsRef.current.get(terminalScroll.tabId);
        if (!terminal) return;
        const amount = event.key === 'ArrowUp' ? -1
            : event.key === 'ArrowDown' ? 1
                : event.key === 'PageUp' ? -terminal.rows
                    : event.key === 'PageDown' ? terminal.rows
                        : event.key === 'Home' ? -terminalScroll.baseY
                            : event.key === 'End' ? terminalScroll.baseY
                                : 0;
        if (!amount) return;
        event.preventDefault();
        terminal.scrollLines(amount);
    }, [terminalScroll.baseY, terminalScroll.tabId]);

    useEffect(() => {
        return () => {
            isMountedRef.current = false;
            Array.from(terminalsRef.current.keys()).forEach((tabId) => disposeTerminal(tabId));
            if (copyFeedbackTimeoutRef.current !== null) {
                window.clearTimeout(copyFeedbackTimeoutRef.current);
            }
        };
    }, [disposeTerminal]);

    const workspaceRef = useRef(workspace);
    useEffect(() => {
        if (workspaceRef.current === workspace) return;
        workspaceRef.current = workspace;
        Array.from(terminalsRef.current.keys()).forEach((tabId) => disposeTerminal(tabId));
        const firstTabId = 'terminal-1';
        tabSequenceRef.current = 2;
        setTabs([{ id: firstTabId, title: workspaceName(workspace), status: 'connecting' }]);
        setActiveTabId(firstTabId);
    }, [disposeTerminal, workspace]);

    useEffect(() => {
        const initializeTabs = async () => {
            for (const tab of tabs) {
                if (!isMountedRef.current || terminalsRef.current.has(tab.id)) continue;
                const container = tabContainerRefs.current.get(tab.id);
                if (!container) continue;

                const terminal = new XtermTerminal({
                    allowProposedApi: false,
                    convertEol: false,
                    cursorBlink: true,
                    cursorStyle: 'bar',
                    cursorWidth: 2,
                    drawBoldTextInBrightColors: true,
                    fontFamily: '"SFMono-Regular", "Cascadia Mono", "Cascadia Code", Menlo, Monaco, Consolas, "Liberation Mono", monospace',
                    fontSize: 14,
                    fontWeight: 400,
                    fontWeightBold: 600,
                    lineHeight: 1.35,
                    letterSpacing: 0,
                    macOptionClickForcesSelection: true,
                    minimumContrastRatio: 4.5,
                    rightClickSelectsWord: true,
                    scrollback: 10000,
                    smoothScrollDuration: 0,
                    tabStopWidth: 8,
                    theme: TERMINAL_THEME,
                });
                const fitAddon = new FitAddon();
                terminal.loadAddon(fitAddon);
                terminal.open(container);
                try {
                    // VS Code 的终端优先使用 GPU renderer。除性能收益外，这也避开
                    // Tauri CSP 对 xterm DOM renderer 动态样式的限制。
                    const webglAddon = new WebglAddon();
                    webglAddon.onContextLoss(() => webglAddon.dispose());
                    terminal.loadAddon(webglAddon);
                } catch (error) {
                    console.warn('xterm WebGL renderer unavailable, falling back to DOM renderer', error);
                }
                terminalsRef.current.set(tab.id, terminal);
                fitAddonsRef.current.set(tab.id, fitAddon);

                const unlistenOutput = await listen<TerminalOutputEvent>('terminal-output', (event) => {
                    const sessionId = sessionIdsRef.current.get(tab.id);
                    if (sessionId === event.payload.sessionId) {
                        // 与 VS Code 一样把 PTY 原始字节直接交给 xterm 解析，避免 UTF-8
                        // 分片和控制字符在事件桥接中发生二次解释。
                        terminal.write(decodeBase64Bytes(event.payload.dataBase64));
                    }
                });
                const unlistenExit = await listen<TerminalExitEvent>('terminal-exit', (event) => {
                    const sessionId = sessionIdsRef.current.get(tab.id);
                    if (sessionId === event.payload.sessionId) {
                        sessionIdsRef.current.delete(tab.id);
                        terminal.write('\r\n\r\n[终端进程已退出]\r\n');
                        setTabs((current) => current.map((item) => item.id === tab.id ? { ...item, status: 'closed' } : item));
                    }
                });
                unlistenRefs.current.set(tab.id, [unlistenOutput, unlistenExit]);

                try {
                    await document.fonts?.ready;
                    await new Promise<void>((resolve) => window.requestAnimationFrame(() => resolve()));
                    terminal.clearTextureAtlas();
                    fitAddon.fit();
                    // 与 VS Code 一样显式使用 8 列制表位。fit 可能从 xterm 的默认
                    // 尺寸调整到实际容器尺寸；PTY 尚未输出时重置空缓冲区，确保
                    // ls 等依赖 TAB 对齐的命令从干净的 tab stops 开始。
                    terminal.reset();
                    const session = await createTerminalSession(workspace, terminal.cols, terminal.rows);
                    if (!isMountedRef.current) {
                        void closeTerminalSession(session.sessionId);
                        return;
                    }
                    if (!tabsRef.current.some((item) => item.id === tab.id)) {
                        void closeTerminalSession(session.sessionId);
                        return;
                    }
                    sessionIdsRef.current.set(tab.id, session.sessionId);
                    // 会话创建期间容器可能已完成二次布局。再次同步当前尺寸，避免 PTY
                    // 保留旧列数，导致 ls 等命令输出硬换行后与屏幕选择网格错位。
                    await resizeTerminalSession(session.sessionId, terminal.cols, terminal.rows);
                    setTabs((current) => current.map((item) => item.id === tab.id ? { ...item, status: 'ready' } : item));

                    const dataDisposable = terminal.onData((data) => {
                        const sessionId = sessionIdsRef.current.get(tab.id);
                        if (sessionId) {
                            void writeTerminalSession(sessionId, data);
                        }
                    });
                    const resizeDisposable = terminal.onResize(({ cols, rows }) => {
                        const sessionId = sessionIdsRef.current.get(tab.id);
                        if (sessionId) {
                            void resizeTerminalSession(sessionId, cols, rows);
                        }
                        syncTerminalScroll(tab.id, terminal);
                    });
                    const scrollDisposable = terminal.onScroll(() => syncTerminalScroll(tab.id, terminal));
                    const selectionDisposable = terminal.onSelectionChange(() => {
                        const hasSelection = terminal.hasSelection();
                        selectionStateRef.current.set(tab.id, hasSelection);
                        setSelectedTabId(hasSelection ? tab.id : null);
                    });
                    terminal.attachCustomKeyEventHandler((event) => {
                        if (event.type !== 'keydown') return true;
                        const key = event.key.toLowerCase();
                        const isMacCopy = event.metaKey && key === 'c';
                        const isWindowsCopy = event.ctrlKey && event.shiftKey && key === 'c';
                        if ((isMacCopy || isWindowsCopy) && terminal.hasSelection()) {
                            event.preventDefault();
                            void copyTerminalSelection(tab.id);
                            return false;
                        }
                        if (event.metaKey && key === 'a') {
                            event.preventDefault();
                            terminal.selectAll();
                            return false;
                        }
                        return true;
                    });
                    disposableRefs.current.set(tab.id, [dataDisposable, resizeDisposable, scrollDisposable, selectionDisposable]);
                    fitAddon.fit();
                    syncTerminalScroll(tab.id, terminal);
                    terminal.focus();
                } catch (error) {
                    terminal.write(`\r\n[终端启动失败] ${error instanceof Error ? error.message : String(error)}\r\n`);
                    setTabs((current) => current.map((item) => item.id === tab.id ? { ...item, status: 'error' } : item));
                }
            }
        };

        void initializeTabs();
    }, [copyTerminalSelection, syncTerminalScroll, tabs, workspace]);

    useEffect(() => {
        const fitActiveTerminal = () => {
            window.requestAnimationFrame(() => fitTerminal(activeTabId));
        };
        fitActiveTerminal();
        window.addEventListener('resize', fitActiveTerminal);
        const observer = typeof ResizeObserver === 'undefined' || !panelContentRef.current
            ? null
            : new ResizeObserver(fitActiveTerminal);
        if (observer && panelContentRef.current) observer.observe(panelContentRef.current);
        return () => {
            window.removeEventListener('resize', fitActiveTerminal);
            observer?.disconnect();
        };
    }, [activeTabId, panelHeight, fitTerminal]);

    const selectTab = (tabId: string) => {
        setActiveTabId(tabId);
        setCopyFeedback(false);
        window.setTimeout(() => {
            fitTerminal(tabId);
            const terminal = terminalsRef.current.get(tabId);
            if (terminal) {
                syncTerminalScroll(tabId, terminal);
                terminal.focus();
            }
        }, 0);
    };

    const createTerminalTab = () => {
        const sequence = tabSequenceRef.current;
        tabSequenceRef.current += 1;
        const tabId = `terminal-${sequence}`;
        setTabs((current) => [...current, { id: tabId, title: `${name} ${sequence}`, status: 'connecting' }]);
        setActiveTabId(tabId);
        setSelectedTabId(null);
    };

    const closeTerminalTab = (tabId: string) => {
        const tabIndex = tabs.findIndex((tab) => tab.id === tabId);
        if (tabIndex < 0) return;

        disposeTerminal(tabId);
        const remainingTabs = tabs.filter((tab) => tab.id !== tabId);
        if (remainingTabs.length === 0) {
            onClose();
            return;
        }

        setTabs(remainingTabs);
        if (activeTabId === tabId) {
            const nextTab = remainingTabs[Math.min(tabIndex, remainingTabs.length - 1)];
            setActiveTabId(nextTab.id);
        }
    };

    useEffect(() => {
        if (!panelContentRef.current) return undefined;
        const observer = new MutationObserver(() => {
            const activeContainer = tabContainerRefs.current.get(activeTabId);
            if (activeContainer && !terminalsRef.current.has(activeTabId)) {
                window.requestAnimationFrame(() => fitTerminal(activeTabId));
            }
        });
        observer.observe(panelContentRef.current, { childList: true, subtree: true });
        return () => observer.disconnect();
    }, [activeTabId, fitTerminal]);

    return <section
        role="region"
        aria-label="底部终端面板"
        style={{ height: `${panelHeight}px` }}
        className="ark-terminal-panel relative flex shrink-0 flex-col overflow-hidden border-t border-[#dbe3ef] bg-white text-slate-700"
    >
        <button
            type="button"
            aria-label="调整终端面板高度"
            title="拖动调整终端面板高度"
            onMouseDown={(event) => {
                event.preventDefault();
                resizeStartRef.current = { y: event.clientY, height: panelHeight };
                setIsResizing(true);
            }}
            className={`absolute inset-x-0 top-0 z-20 flex h-2 -translate-y-1/2 cursor-row-resize items-center justify-center text-slate-400 transition hover:text-slate-600 ${isResizing ? 'text-slate-600' : ''}`}
        >
            <GripHorizontal size={18} />
        </button>
        <div className="flex h-10 shrink-0 items-center justify-between border-b border-[#e7edf5] bg-white px-3">
            <div className="flex h-full min-w-0 items-center gap-1">
                {tabs.map((tab) => (
                    <div key={tab.id} className={`group flex h-full items-center border-b-2 ${tab.id === activeTabId ? 'border-[#7664ed]' : 'border-transparent'}`}>
                        <button
                            type="button"
                            onClick={() => selectTab(tab.id)}
                            aria-current={tab.id === activeTabId ? 'page' : undefined}
                            className={`flex h-full min-w-0 items-center gap-2 px-2 text-xs transition ${tab.id === activeTabId ? 'text-slate-700' : 'text-slate-400 hover:bg-slate-50 hover:text-slate-700'}`}
                        >
                            <TerminalIcon size={14} />
                            <span className="max-w-56 truncate">{tab.title}</span>
                            <span className={`h-1.5 w-1.5 shrink-0 rounded-full ${tab.status === 'ready' ? 'bg-emerald-500' : tab.status === 'error' ? 'bg-red-500' : tab.status === 'closed' ? 'bg-slate-300' : 'bg-amber-400'}`} />
                        </button>
                        <button
                            type="button"
                            onClick={() => closeTerminalTab(tab.id)}
                            aria-label={`关闭终端 ${tab.title}`}
                            title={`关闭终端 ${tab.title}`}
                            className="mr-1 rounded p-1 text-slate-400 transition hover:bg-slate-100 hover:text-slate-700"
                        >
                            <X size={13} />
                        </button>
                    </div>
                ))}
                <button
                    type="button"
                    onClick={createTerminalTab}
                    aria-label="新建终端标签页"
                    title="新建终端标签页"
                    className="rounded p-1 text-slate-400 transition hover:bg-slate-100 hover:text-slate-700"
                >
                    <Plus size={14} />
                </button>
            </div>
            <div className="flex shrink-0 items-center gap-1">
                {copyFeedback && <span className="text-[11px] text-emerald-600">已复制</span>}
                <button
                    type="button"
                    onMouseDown={(event) => event.preventDefault()}
                    onClick={() => void copyTerminalSelection(activeTabId)}
                    disabled={selectedTabId !== activeTabId || !selectionStateRef.current.get(activeTabId)}
                    aria-label="复制选中内容"
                    title="复制选中内容（⌘C / Ctrl+Shift+C）"
                    className="rounded-md p-1.5 text-slate-400 transition hover:bg-slate-100 hover:text-slate-700 disabled:cursor-not-allowed disabled:opacity-35"
                >
                    {copyFeedback ? <Check size={15} /> : <Copy size={15} />}
                </button>
                <button type="button" onClick={onClose} aria-label="关闭底部终端面板" title="关闭底部终端面板" className="rounded-md p-1.5 text-slate-400 transition hover:bg-slate-100 hover:text-slate-700"><X size={15} /></button>
            </div>
        </div>
        <div ref={panelContentRef} className="relative min-h-0 flex-1 overflow-hidden bg-[#fbfcfe]">
            {tabs.map((tab) => (
                <div
                    key={tab.id}
                    ref={(node) => {
                        if (node) tabContainerRefs.current.set(tab.id, node);
                        else tabContainerRefs.current.delete(tab.id);
                    }}
                    className={`terminal-tab absolute inset-0 px-4 py-3 ${tab.id === activeTabId ? 'z-10 visible' : 'z-0 invisible pointer-events-none'}`}
                    aria-hidden={tab.id === activeTabId ? undefined : true}
                />
            ))}
            {terminalScroll.tabId === activeTabId && terminalScroll.baseY > 0 && terminalScroll.rows > 0 && (
                <div
                    className="ark-terminal-scrollbar"
                    role="scrollbar"
                    aria-label="终端滚动条"
                    aria-orientation="vertical"
                    aria-valuemin={0}
                    aria-valuemax={terminalScroll.baseY}
                    aria-valuenow={terminalScroll.ydisp}
                    tabIndex={0}
                    onKeyDown={handleScrollbarKeyDown}
                    onPointerDown={handleScrollbarPointerDown}
                    onPointerMove={handleScrollbarPointerMove}
                    onPointerUp={handleScrollbarPointerUp}
                    onPointerCancel={handleScrollbarPointerUp}
                >
                    <div
                        className="ark-terminal-scrollbar-thumb"
                        style={{
                            height: `${Math.max(12, Math.min(100, terminalScroll.rows / (terminalScroll.rows + terminalScroll.baseY) * 100))}%`,
                            top: `${terminalScroll.baseY === 0 ? 0 : terminalScroll.ydisp / terminalScroll.baseY * (100 - Math.max(12, Math.min(100, terminalScroll.rows / (terminalScroll.rows + terminalScroll.baseY) * 100)))}%`,
                        }}
                    />
                </div>
            )}
        </div>
    </section>;
};

export default TaskTerminalPanel;
