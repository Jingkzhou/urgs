import React, { useState, useEffect, useRef, useMemo } from 'react';
import {
    Box,
    Terminal,
    Search,
    RefreshCw,
    Download,
    Database,
    Activity,
    Filter,
    ChevronRight,
    Server,
    AlertCircle,
    FileText,
    Clock,
    ExternalLink,
    Cpu,
    Zap
} from 'lucide-react';
import { message, Tooltip, Input, Select, Button, Tag, Empty } from 'antd';
import dayjs from 'dayjs';
import Auth from '../../../Auth';
import { getDockerContainers, getDockerLogs, DockerContainer, DockerLog } from '@/api/ops';

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
    level: string; // Changed from union to string for API compatibility
    message: string;
    source: string;
}

// --- Mock Data ---
const MOCK_CONTAINERS: Container[] = [
    { id: 'c1', name: 'urgs-api-server', image: 'urgs-api:latest', status: 'running', ip: '172.18.0.2', cpu: '1.2%', memory: '256MB', uptime: '12d 4h' },
    { id: 'c2', name: 'urgs-web-portal', image: 'urgs-web:v1.2.0', status: 'running', ip: '172.18.0.5', cpu: '0.5%', memory: '128MB', uptime: '5d 2h' },
    { id: 'c3', name: 'mysql-db-01', image: 'mysql:8.0', status: 'running', ip: '172.18.0.3', cpu: '2.5%', memory: '1.2GB', uptime: '30d 12h' },
    { id: 'c4', name: 'redis-cache-master', image: 'redis:7-alpine', status: 'running', ip: '172.18.0.4', cpu: '0.8%', memory: '64MB', uptime: '30d 12h' },
    { id: 'c5', name: 'nginx-ingress', image: 'nginx:stable-alpine', status: 'stopped', ip: '172.18.0.1', cpu: '0%', memory: '0MB', uptime: '-' },
    { id: 'c6', name: 'elasticsearch-node-1', image: 'elasticsearch:8.10.0', status: 'restarting', ip: '172.18.0.8', cpu: '-', memory: '-', uptime: '-' },
];

const GENERATE_MOCK_LOGS = (containerName: string): LogEntry[] => {
    const levels: ('info' | 'warn' | 'error' | 'debug')[] = ['info', 'info', 'info', 'warn', 'error', 'debug'];
    const messages = [
        'Connection established with upstream service',
        'Executing batch task #8821...',
        'Incoming request: GET /api/v1/metadata/lineage',
        'Indexing documents into core_index_01',
        'Memory usage spiked to 85%',
        'Database connection pool reached maximum capacity',
        'Worker process 12 exited normally',
        'Failed to parse incoming payload: invalid JSON',
        'Heartbeat mission successful',
        'Starting health check routine...'
    ];

    return Array.from({ length: 50 }).map((_, i) => ({
        id: `log-${i}`,
        timestamp: dayjs().subtract(i * 30, 'second').format('YYYY-MM-DD HH:mm:ss.SSS'),
        level: levels[Math.floor(Math.random() * levels.length)],
        message: messages[Math.floor(Math.random() * messages.length)],
        source: containerName
    })).reverse();
};

const DockerLogManagement: React.FC = () => {
    const [containers, setContainers] = useState<Container[]>(MOCK_CONTAINERS);
    const [selectedContainerId, setSelectedContainerId] = useState<string>(MOCK_CONTAINERS[0].id);
    const [logs, setLogs] = useState<LogEntry[]>([]);
    const [searchText, setSearchText] = useState('');
    const [logFilter, setLogFilter] = useState('ALL');
    const [autoScroll, setAutoScroll] = useState(true);
    const [loading, setLoading] = useState(false);
    const logEndRef = useRef<HTMLDivElement>(null);

    const selectedContainer = useMemo(() =>
        containers.find(c => c.id === selectedContainerId),
        [containers, selectedContainerId]);

    useEffect(() => {
        const fetchContainers = async () => {
            try {
                const data = await getDockerContainers();
                if (data && data.length > 0) {
                    setContainers(data);
                    if (!selectedContainerId) {
                        setSelectedContainerId(data[0].id);
                    }
                }
            } catch (error) {
                console.warn('Backend API not available, using mock containers');
            }
        };
        fetchContainers();
    }, []);

    useEffect(() => {
        if (selectedContainerId) {
            const fetchLogs = async () => {
                setLoading(true);
                try {
                    const data = await getDockerLogs(selectedContainerId);
                    if (data) {
                        setLogs(data.map((l: any, i: number) => ({
                            id: `log-${i}`,
                            ...l,
                            source: selectedContainer?.name || ''
                        })));
                    }
                } catch (error) {
                    console.warn('Backend API not available, using mock logs');
                    setLogs(GENERATE_MOCK_LOGS(selectedContainer?.name || 'container'));
                } finally {
                    setLoading(false);
                }
            };
            fetchLogs();
        }
    }, [selectedContainerId]);

    useEffect(() => {
        if (autoScroll && logEndRef.current) {
            logEndRef.current.scrollIntoView({ behavior: 'smooth' });
        }
    }, [logs, autoScroll]);

    const filteredLogs = useMemo(() => {
        return logs.filter(log => {
            const matchesSearch = log.message.toLowerCase().includes(searchText.toLowerCase()) ||
                log.level.toLowerCase().includes(searchText.toLowerCase());
            const matchesLevel = logFilter === 'ALL' || log.level.toUpperCase() === logFilter;
            return matchesSearch && matchesLevel;
        });
    }, [logs, searchText, logFilter]);

    const handleDownload = () => {
        if (!selectedContainer) return;
        const content = filteredLogs.map(l => `[${l.timestamp}] [${l.level.toUpperCase()}] ${l.message}`).join('\n');
        const blob = new Blob([content], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `${selectedContainer.name}_logs_${dayjs().format('YYYYMMDD_HHmm')}.txt`;
        link.click();
        message.success('日志下载成功');
    };

    const handleCopyLog = (text: string) => {
        navigator.clipboard.writeText(text);
        message.success({ content: '已复制到剪切板', duration: 1, style: { marginTop: '10vh' } });
    };

    const statusColors = {
        running: 'bg-emerald-500',
        stopped: 'bg-slate-400',
        restarting: 'bg-amber-500'
    };

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
                            <button className="p-2 text-slate-400 hover:text-blue-600 transition-colors hover:bg-blue-50 rounded-lg">
                                <RefreshCw size={16} />
                            </button>
                        </Tooltip>
                    </Auth>
                </div>

                <div className="flex-1 overflow-y-auto custom-scrollbar p-3 space-y-1.5">
                    {containers.map((c) => (
                        <div
                            key={c.id}
                            onClick={() => setSelectedContainerId(c.id)}
                            className={`group relative p-3.5 rounded-xl cursor-pointer transition-all duration-300 border ${selectedContainerId === c.id
                                ? 'bg-white border-blue-200 shadow-sm shadow-blue-100 ring-1 ring-blue-50'
                                : 'border-transparent hover:bg-slate-200/50 hover:border-slate-200/50'
                                }`}
                        >
                            <div className="flex items-start justify-between mb-2">
                                <div className="flex items-center gap-2.5 overflow-hidden">
                                    <div className={`w-2 h-2 rounded-full ${statusColors[c.status]} ${c.status === 'running' ? 'animate-pulse' : ''}`} />
                                    <span className={`font-bold truncate text-sm tracking-wide ${selectedContainerId === c.id ? 'text-blue-700' : 'text-slate-600 group-hover:text-slate-900'}`}>
                                        {c.name}
                                    </span>
                                </div>
                                {selectedContainerId === c.id && (
                                    <ChevronRight size={14} className="text-blue-500" />
                                )}
                            </div>
                            <div className="flex items-center gap-3 text-[10px] text-slate-400 font-medium">
                                <div className="flex items-center gap-1">
                                    <Terminal size={10} />
                                    {c.image.split(':')[0]}
                                </div>
                                <div className="flex items-center gap-1">
                                    <Activity size={10} />
                                    {c.uptime}
                                </div>
                            </div>
                        </div>
                    ))}
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
                                    Terminal <span className="text-blue-600 font-medium px-2 py-0.5 rounded bg-blue-50 text-xs ml-2 tracking-normal border border-blue-100">LIVE</span>
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
                                    key={idx}
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
                            <p className="text-slate-400 text-sm">暂无匹配日志</p>
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
                            <div className="w-1.5 h-1.5 rounded-full bg-green-500" />
                            Stream Quality: Nominal
                        </div>
                        <div className="opacity-30">|</div>
                        <div>Buffer size: 50/1000</div>
                    </div>
                    <div className="flex items-center gap-3">
                        <span className="hover:text-slate-700 cursor-pointer transition-colors">v2.4.0-STABLE</span>
                        <span className="opacity-30">|</span>
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
