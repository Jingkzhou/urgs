import React, { useState, useEffect, useRef, useMemo, useCallback } from 'react';
import {
    Box,
    Terminal,
    Search,
    RefreshCw,
    Download,
    Activity,
    ChevronRight,
    Server,
    FileText,
    Clock,
    Cpu,
    Zap,
    Play,
    Square,
    RotateCcw,
    Wifi,
    WifiOff,
    MoreVertical,
    Trash2
} from 'lucide-react';
import { message, Tooltip, Modal, Dropdown } from 'antd';
import type { MenuProps } from 'antd';
import dayjs from 'dayjs';
import Auth from '../../../Auth';
import {
    getDockerContainers,
    getDockerLogs,
    DockerContainer,
    DockerLog,
    getAllContainerStats,
    startDockerContainer,
    stopDockerContainer,
    restartDockerContainer
} from '@/api/ops';
import { useDockerLogStream, StreamLogEntry } from '@/hooks/useDockerLogStream';

// --- Types ---
interface Container {
    id: string;
    name: string;
    image: string;
    status: 'running' | 'stopped' | 'restarting';
    ip: string;
    cpu: string;
    memory: string;
    uptime: string;
}

interface LogEntry {
    id: string;
    timestamp: string;
    level: string;
    message: string;
    source: string;
}

const DockerLogManagement: React.FC = () => {
    const [containers, setContainers] = useState<Container[]>([]);
    const [selectedContainerId, setSelectedContainerId] = useState<string>('');
    const [restLogs, setRestLogs] = useState<LogEntry[]>([]);
    const [searchText, setSearchText] = useState('');
    const [logFilter, setLogFilter] = useState('ALL');
    const [autoScroll, setAutoScroll] = useState(true);
    const [loading, setLoading] = useState(false);
    const [useWebSocket, setUseWebSocket] = useState(true);
    const [operationLoading, setOperationLoading] = useState<string | null>(null);
    const [wsAutoDisabled, setWsAutoDisabled] = useState(false);
    const logEndRef = useRef<HTMLDivElement>(null);

    // WebSocket log stream
    const wsContainerIds = useMemo(
        () => (useWebSocket && selectedContainerId ? [selectedContainerId] : []),
        [useWebSocket, selectedContainerId]
    );
    const { logs: wsLogs, isConnected, connectionState, error: wsError, reconnect, clearLogs } =
        useDockerLogStream(wsContainerIds, { enabled: useWebSocket });

    // Auto-fallback: if WebSocket fails (max retries reached), switch to REST mode
    useEffect(() => {
        if (useWebSocket && wsError && wsError.includes('Max reconnection')) {
            setUseWebSocket(false);
            setWsAutoDisabled(true);
            console.warn('WebSocket unavailable, falling back to REST mode');
        }
    }, [wsError, useWebSocket]);

    const selectedContainer = useMemo(() =>
        containers.find(c => c.id === selectedContainerId),
        [containers, selectedContainerId]);

    // Fetch containers
    const fetchContainers = useCallback(async () => {
        try {
            const data = await getDockerContainers();
            if (data && data.length > 0) {
                setContainers(data);
                if (!selectedContainerId || !data.find(c => c.id === selectedContainerId)) {
                    setSelectedContainerId(data[0].id);
                }
            }
        } catch (error) {
            console.warn('Backend API not available for containers');
        }
    }, [selectedContainerId]);

    useEffect(() => {
        fetchContainers();
    }, []);

    // Poll container stats every 10s
    useEffect(() => {
        const pollStats = async () => {
            try {
                const stats = await getAllContainerStats();
                if (stats && stats.length > 0) {
                    setContainers(prev => prev.map(c => {
                        const stat = stats.find(s => s.containerId === c.id);
                        if (stat) {
                            return { ...c, cpu: stat.cpuPercent, memory: stat.memUsage };
                        }
                        return c;
                    }));
                }
            } catch {
                // silently fail
            }
        };

        pollStats();
        const interval = setInterval(pollStats, 10000);
        return () => clearInterval(interval);
    }, []);

    // Fetch REST logs as fallback when WebSocket is not used
    useEffect(() => {
        if (!useWebSocket && selectedContainerId) {
            const fetchLogs = async () => {
                setLoading(true);
                try {
                    const data = await getDockerLogs(selectedContainerId);
                    if (data) {
                        setRestLogs(data.map((l: any, i: number) => ({
                            id: `log-${i}`,
                            ...l,
                            source: selectedContainer?.name || ''
                        })));
                    }
                } catch (error) {
                    console.warn('Backend API not available, no logs');
                    setRestLogs([]);
                } finally {
                    setLoading(false);
                }
            };
            fetchLogs();
        }
    }, [selectedContainerId, useWebSocket]);

    // Combine logs: use WebSocket logs if connected, else REST logs
    const activeLogs = useMemo(() => {
        if (useWebSocket) {
            return wsLogs.map(l => ({
                id: l.id,
                timestamp: l.timestamp,
                level: l.level,
                message: l.message,
                source: l.source,
            }));
        }
        return restLogs;
    }, [useWebSocket, wsLogs, restLogs]);

    useEffect(() => {
        if (autoScroll && logEndRef.current) {
            logEndRef.current.scrollIntoView({ behavior: 'smooth' });
        }
    }, [activeLogs, autoScroll]);

    const filteredLogs = useMemo(() => {
        return activeLogs.filter(log => {
            const matchesSearch = log.message.toLowerCase().includes(searchText.toLowerCase()) ||
                log.level.toLowerCase().includes(searchText.toLowerCase());
            const matchesLevel = logFilter === 'ALL' || log.level.toUpperCase() === logFilter;
            return matchesSearch && matchesLevel;
        });
    }, [activeLogs, searchText, logFilter]);

    const handleDownload = () => {
        if (!selectedContainer) return;
        const content = filteredLogs.map(l => `[${l.timestamp}] [${l.level.toUpperCase()}] ${l.message}`).join('\n');
        const blob = new Blob([content], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `${selectedContainer.name}_logs_${dayjs().format('YYYYMMDD_HHmm')}.txt`;
        link.click();
        URL.revokeObjectURL(url);
        message.success('日志下载成功');
    };

    const handleCopyLog = (text: string) => {
        navigator.clipboard.writeText(text);
        message.success({ content: '已复制到剪切板', duration: 1, style: { marginTop: '10vh' } });
    };

    const handleContainerOperation = async (containerId: string, operation: 'start' | 'stop' | 'restart') => {
        const operationNames = { start: '启动', stop: '停止', restart: '重启' };
        const container = containers.find(c => c.id === containerId);

        Modal.confirm({
            title: `确认${operationNames[operation]}`,
            content: `确定要${operationNames[operation]}容器 "${container?.name || containerId}" 吗？`,
            okText: '确认',
            cancelText: '取消',
            onOk: async () => {
                setOperationLoading(containerId);
                try {
                    const fn = { start: startDockerContainer, stop: stopDockerContainer, restart: restartDockerContainer };
                    const result = await fn[operation](containerId);
                    if (result?.success) {
                        message.success(`容器${operationNames[operation]}成功`);
                        fetchContainers();
                    } else {
                        message.error(result?.message || `容器${operationNames[operation]}失败`);
                    }
                } catch (error) {
                    message.error(`容器${operationNames[operation]}失败`);
                } finally {
                    setOperationLoading(null);
                }
            }
        });
    };

    const getContainerMenuItems = (container: Container): MenuProps['items'] => {
        const items: MenuProps['items'] = [];
        if (container.status === 'stopped') {
            items.push({
                key: 'start',
                icon: <Play size={14} />,
                label: '启动',
                onClick: () => handleContainerOperation(container.id, 'start'),
            });
        }
        if (container.status === 'running') {
            items.push({
                key: 'stop',
                icon: <Square size={14} />,
                label: '停止',
                onClick: () => handleContainerOperation(container.id, 'stop'),
            });
        }
        items.push({
            key: 'restart',
            icon: <RotateCcw size={14} />,
            label: '重启',
            onClick: () => handleContainerOperation(container.id, 'restart'),
        });
        return items;
    };

    const statusColors: Record<string, string> = {
        running: 'bg-emerald-500',
        stopped: 'bg-slate-400',
        restarting: 'bg-amber-500'
    };

    const connectionIndicator = useMemo(() => {
        if (!useWebSocket) return null;
        switch (connectionState) {
            case 'connected':
                return { color: 'bg-green-500', text: 'LIVE', textColor: 'text-green-600', bgColor: 'bg-green-50', borderColor: 'border-green-100' };
            case 'connecting':
                return { color: 'bg-yellow-500', text: 'CONNECTING', textColor: 'text-yellow-600', bgColor: 'bg-yellow-50', borderColor: 'border-yellow-100' };
            case 'disconnected':
                return { color: 'bg-red-500', text: 'OFFLINE', textColor: 'text-red-600', bgColor: 'bg-red-50', borderColor: 'border-red-100' };
        }
    }, [connectionState, useWebSocket]);

    // Log level stats
    const logStats = useMemo(() => {
        const stats = { info: 0, warn: 0, error: 0, debug: 0 };
        activeLogs.forEach(l => {
            const level = l.level.toLowerCase();
            if (level in stats) stats[level as keyof typeof stats]++;
        });
        return stats;
    }, [activeLogs]);

    return (
        <div className="flex h-[calc(100vh-140px)] bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-sm font-sans selection:bg-blue-100">
            {/* --- Sidebar: Container List --- */}
            <div className="w-80 flex-shrink-0 border-r border-slate-200 flex flex-col bg-slate-50/50 backdrop-blur-md">
                <div className="p-5 border-b border-slate-200 flex items-center justify-between">
                    <div className="flex items-center gap-3">
                        <div className="p-2 bg-blue-50 rounded-lg text-blue-600">
                            <Box size={20} />
                        </div>
                        <h2 className="font-bold text-slate-700 tracking-tight">容器实例</h2>
                    </div>
                    <Auth code="sys:docker:log:list">
                        <Tooltip title="刷新列表">
                            <button
                                onClick={fetchContainers}
                                className="p-2 text-slate-400 hover:text-blue-600 transition-colors hover:bg-blue-50 rounded-lg"
                            >
                                <RefreshCw size={16} />
                            </button>
                        </Tooltip>
                    </Auth>
                </div>

                <div className="flex-1 overflow-y-auto custom-scrollbar p-3 space-y-1.5">
                    {containers.map((c) => (
                        <div
                            key={c.id}
                            onClick={() => {
                                if (useWebSocket) clearLogs();
                                setSelectedContainerId(c.id);
                            }}
                            className={`group relative p-3.5 rounded-xl cursor-pointer transition-all duration-300 border ${selectedContainerId === c.id
                                ? 'bg-white border-blue-200 shadow-sm shadow-blue-100 ring-1 ring-blue-50'
                                : 'border-transparent hover:bg-slate-200/50 hover:border-slate-200/50'
                                }`}
                        >
                            <div className="flex items-start justify-between mb-2">
                                <div className="flex items-center gap-2.5 overflow-hidden flex-1">
                                    <div className={`w-2 h-2 rounded-full ${statusColors[c.status]} ${c.status === 'running' ? 'animate-pulse' : ''}`} />
                                    <span className={`font-bold truncate text-sm tracking-wide ${selectedContainerId === c.id ? 'text-blue-700' : 'text-slate-600 group-hover:text-slate-900'}`}>
                                        {c.name}
                                    </span>
                                </div>
                                <div className="flex items-center gap-1">
                                    <Auth code="sys:docker:container:start">
                                        <Dropdown menu={{ items: getContainerMenuItems(c) }} trigger={['click']}>
                                            <button
                                                onClick={(e) => e.stopPropagation()}
                                                className={`p-1 rounded text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors ${operationLoading === c.id ? 'animate-spin' : ''}`}
                                            >
                                                <MoreVertical size={14} />
                                            </button>
                                        </Dropdown>
                                    </Auth>
                                    {selectedContainerId === c.id && (
                                        <ChevronRight size={14} className="text-blue-500" />
                                    )}
                                </div>
                            </div>
                            <div className="flex items-center gap-3 text-[10px] text-slate-400 font-medium">
                                <div className="flex items-center gap-1">
                                    <Terminal size={10} />
                                    {c.image.split(':')[0]}
                                </div>
                                <div className="flex items-center gap-1">
                                    <Cpu size={10} />
                                    {c.cpu}
                                </div>
                                <div className="flex items-center gap-1">
                                    <Zap size={10} />
                                    {c.memory}
                                </div>
                                <div className="flex items-center gap-1">
                                    <Activity size={10} />
                                    {c.uptime}
                                </div>
                            </div>
                        </div>
                    ))}
                    {containers.length === 0 && (
                        <div className="text-center text-slate-400 text-sm py-10">暂无容器</div>
                    )}
                </div>
            </div>

            {/* --- Main Content: Log Viewer --- */}
            <div className="flex-1 flex flex-col relative overflow-hidden bg-white">
                {/* --- Header / Toolbar --- */}
                <div className="p-4 border-b border-slate-200 bg-white flex items-center justify-between z-10">
                    <div className="flex items-center gap-4">
                        <div className="flex flex-col">
                            <div className="flex items-center gap-2">
                                <h1 className="text-lg font-black text-slate-800 tracking-widest uppercase">
                                    Terminal
                                    {connectionIndicator && (
                                        <span className={`${connectionIndicator.textColor} font-medium px-2 py-0.5 rounded ${connectionIndicator.bgColor} text-xs ml-2 tracking-normal border ${connectionIndicator.borderColor} inline-flex items-center gap-1.5`}>
                                            <span className={`w-1.5 h-1.5 rounded-full ${connectionIndicator.color} ${connectionState === 'connected' ? 'animate-pulse' : ''}`} />
                                            {connectionIndicator.text}
                                        </span>
                                    )}
                                    {!useWebSocket && (
                                        <span className="text-slate-500 font-medium px-2 py-0.5 rounded bg-slate-50 text-xs ml-2 tracking-normal border border-slate-200">
                                            REST
                                        </span>
                                    )}
                                </h1>
                            </div>
                            <div className="text-[11px] text-slate-400 flex items-center gap-2 mt-0.5 font-mono">
                                <Server size={10} /> {selectedContainer?.ip}
                                <span className="opacity-20">|</span>
                                <Cpu size={10} /> {selectedContainer?.cpu}
                                <span className="opacity-20">|</span>
                                <Zap size={10} /> {selectedContainer?.memory}
                            </div>
                        </div>
                    </div>

                    <div className="flex items-center gap-3">
                        <div className="relative">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={14} />
                            <input
                                type="text"
                                placeholder="搜索日志..."
                                value={searchText}
                                onChange={e => setSearchText(e.target.value)}
                                className="pl-9 pr-4 py-1.5 bg-slate-50 border border-slate-200 rounded-full text-xs text-slate-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500/50 w-64 transition-all placeholder:text-slate-400"
                            />
                        </div>

                        <div className="h-6 w-px bg-slate-200 mx-1" />

                        <Auth code="sys:docker:log:list">
                            <div className="flex bg-slate-50 p-1 rounded-lg border border-slate-200">
                                {['ALL', 'INFO', 'WARN', 'ERROR'].map((level) => (
                                    <button
                                        key={level}
                                        onClick={() => setLogFilter(level)}
                                        className={`px-3 py-1 text-[10px] font-bold rounded-md transition-all ${logFilter === level
                                            ? 'bg-white text-blue-600 shadow-sm border border-slate-200'
                                            : 'text-slate-500 hover:text-slate-700'
                                            }`}
                                    >
                                        {level}
                                    </button>
                                ))}
                            </div>
                        </Auth>

                        {/* WebSocket toggle */}
                        <Tooltip title={useWebSocket ? '切换到 REST 模式' : '切换到实时流模式'}>
                            <button
                                onClick={() => setUseWebSocket(!useWebSocket)}
                                className={`p-1.5 rounded-lg border transition-all ${useWebSocket
                                    ? 'bg-green-50 text-green-600 border-green-200'
                                    : 'bg-slate-50 text-slate-400 border-slate-200'
                                    }`}
                            >
                                {useWebSocket ? <Wifi size={14} /> : <WifiOff size={14} />}
                            </button>
                        </Tooltip>

                        {/* Reconnect button */}
                        {useWebSocket && connectionState === 'disconnected' && (
                            <Tooltip title="重新连接">
                                <button
                                    onClick={reconnect}
                                    className="p-1.5 rounded-lg border border-blue-200 bg-blue-50 text-blue-600 hover:bg-blue-100 transition-all"
                                >
                                    <RefreshCw size={14} />
                                </button>
                            </Tooltip>
                        )}

                        {/* Clear logs */}
                        {useWebSocket && (
                            <Tooltip title="清空日志">
                                <button
                                    onClick={clearLogs}
                                    className="p-1.5 rounded-lg border border-slate-200 bg-slate-50 text-slate-400 hover:text-slate-600 transition-all"
                                >
                                    <Trash2 size={14} />
                                </button>
                            </Tooltip>
                        )}

                        {/* REST refresh */}
                        {!useWebSocket && (
                            <Tooltip title="刷新日志">
                                <button
                                    onClick={() => {
                                        if (selectedContainerId) {
                                            setLoading(true);
                                            getDockerLogs(selectedContainerId).then(data => {
                                                if (data) setRestLogs(data.map((l: any, i: number) => ({ id: `log-${i}`, ...l, source: selectedContainer?.name || '' })));
                                            }).finally(() => setLoading(false));
                                        }
                                    }}
                                    className="p-1.5 rounded-lg border border-slate-200 bg-slate-50 text-slate-400 hover:text-slate-600 transition-all"
                                >
                                    <RefreshCw size={14} />
                                </button>
                            </Tooltip>
                        )}

                        <Auth code="sys:docker:log:download">
                            <button
                                onClick={handleDownload}
                                className="flex items-center gap-2 px-3 py-1.5 bg-white hover:bg-slate-50 text-slate-600 border border-slate-200 rounded-lg text-xs font-bold transition-all hover:scale-[1.02] shadow-sm"
                            >
                                <Download size={14} />
                                导出日志
                            </button>
                        </Auth>
                    </div>
                </div>

                {/* --- Log Body --- */}
                <div className="flex-1 bg-slate-50/50 overflow-y-auto custom-scrollbar-terminal p-4 font-mono text-[13px] relative group/log">
                    {loading ? (
                        <div className="absolute inset-0 flex flex-col items-center justify-center bg-white/80 z-20 backdrop-blur-sm">
                            <div className="w-8 h-8 border-2 border-blue-500/30 border-t-blue-500 rounded-full animate-spin mb-4" />
                            <div className="text-blue-500 text-[11px] font-bold tracking-widest uppercase animate-pulse">Establishing Stream...</div>
                        </div>
                    ) : filteredLogs.length > 0 ? (
                        <div className="space-y-1">
                            {filteredLogs.map((log, idx) => (
                                <div
                                    key={log.id || idx}
                                    className="flex gap-4 group/line hover:bg-slate-200/50 transition-all py-1 px-2 rounded-lg relative"
                                    onClick={() => handleCopyLog(`[${log.timestamp}] [${log.level.toUpperCase()}] ${log.message}`)}
                                >
                                    <span className="text-slate-400 select-none w-44 flex-shrink-0 font-mono text-[11px] pt-0.5">[{log.timestamp}]</span>
                                    <span className={`w-14 flex-shrink-0 font-black text-center rounded text-[9px] py-0.5 h-fit mt-0.5 ${log.level === 'error' ? 'bg-red-100 text-red-600 border border-red-200' :
                                        log.level === 'warn' ? 'bg-amber-100 text-amber-600 border border-amber-200' :
                                            log.level === 'debug' ? 'bg-purple-100 text-purple-600 border border-purple-200' :
                                                'bg-blue-100 text-blue-600 border border-blue-200'
                                        }`}>
                                        {log.level.toUpperCase()}
                                    </span>
                                    <span className="text-slate-600 leading-relaxed break-all flex-1 pr-8">
                                        {log.message}
                                    </span>
                                    <div className="absolute right-2 top-1.5 opacity-0 group-hover/line:opacity-100 transition-opacity">
                                        <Tooltip title="复制行">
                                            <button className="p-1 hover:bg-white rounded text-slate-400 hover:text-blue-600 shadow-sm border border-transparent hover:border-slate-200">
                                                <FileText size={12} />
                                            </button>
                                        </Tooltip>
                                    </div>
                                </div>
                            ))}
                            <div ref={logEndRef} />
                        </div>
                    ) : (
                        <div className="h-full flex flex-col items-center justify-center py-20 opacity-40">
                            <FileText size={48} className="text-slate-300 mb-4" />
                            <p className="text-slate-400 text-sm">
                                {selectedContainerId ? '暂无匹配日志' : '请选择一个容器'}
                            </p>
                            {wsError && <p className="text-red-400 text-xs mt-2">{wsError}</p>}
                        </div>
                    )}

                    {/* Floating Action Button: Scroll to Bottom toggle */}
                    <div className="absolute bottom-6 right-8 flex flex-col gap-2">
                        <button
                            onClick={() => setAutoScroll(!autoScroll)}
                            className={`p-2.5 rounded-xl shadow-lg transition-all border ${autoScroll
                                ? 'bg-blue-600 text-white border-blue-500 scale-110 shadow-blue-200'
                                : 'bg-white text-slate-400 border-slate-200 hover:text-slate-600 hover:border-slate-300'
                                }`}
                            title={autoScroll ? "Disable Auto-scroll" : "Enable Auto-scroll"}
                        >
                            <RefreshCw size={18} className={autoScroll ? 'animate-spin-slow' : ''} />
                        </button>
                    </div>
                </div>

                {/* --- Footer / Quick Stats --- */}
                <div className="px-4 py-2 bg-slate-50 border-t border-slate-200 flex items-center justify-between text-[10px] font-bold text-slate-500">
                    <div className="flex items-center gap-4 uppercase tracking-wider">
                        <div className="flex items-center gap-1.5">
                            <div className={`w-1.5 h-1.5 rounded-full ${isConnected ? 'bg-green-500' : useWebSocket ? 'bg-red-500' : 'bg-slate-400'}`} />
                            {useWebSocket
                                ? (isConnected ? 'Stream: Connected' : connectionState === 'connecting' ? 'Stream: Reconnecting...' : 'Stream: Disconnected')
                                : 'Mode: REST Poll'
                            }
                        </div>
                        <div className="opacity-30">|</div>
                        <div>Buffer: {activeLogs.length}/5000</div>
                        <div className="opacity-30">|</div>
                        <div className="flex items-center gap-2">
                            <span className="text-blue-500">INFO:{logStats.info}</span>
                            <span className="text-amber-500">WARN:{logStats.warn}</span>
                            <span className="text-red-500">ERR:{logStats.error}</span>
                        </div>
                    </div>
                    <div className="flex items-center gap-3">
                        <Clock size={10} />
                        {dayjs().format('HH:mm:ss')} (LOCAL)
                    </div>
                </div>
            </div>

            {/* --- Global Embedded Styles --- */}
            <style>{`
        .custom-scrollbar::-webkit-scrollbar {
          width: 4px;
        }
        .custom-scrollbar::-webkit-scrollbar-track {
          background: transparent;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb {
          background: rgba(148, 163, 184, 0.2);
          border-radius: 10px;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb:hover {
          background: rgba(148, 163, 184, 0.4);
        }

        .custom-scrollbar-terminal::-webkit-scrollbar {
          width: 6px;
        }
        .custom-scrollbar-terminal::-webkit-scrollbar-track {
          background: #f8fafc;
        }
        .custom-scrollbar-terminal::-webkit-scrollbar-thumb {
          background: #cbd5e1;
          border-radius: 10px;
        }
        .custom-scrollbar-terminal::-webkit-scrollbar-thumb:hover {
          background: #94a3b8;
        }

        @keyframes spin-slow {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
        .animate-spin-slow {
          animation: spin-slow 8s linear infinite;
        }

        @keyframes scale-in {
          from { transform: scale(0.95); opacity: 0; }
          to { transform: scale(1); opacity: 1; }
        }
        .animate-scale-in {
          animation: scale-in 0.2s ease-out;
        }
      `}</style>
        </div>
    );
};

export default DockerLogManagement;
