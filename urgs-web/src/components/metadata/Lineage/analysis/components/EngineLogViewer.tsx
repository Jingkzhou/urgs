import React, { useState, useEffect, useRef, useMemo } from 'react';
import { Input, Switch, Button, Badge, Space, Tooltip, Empty } from 'antd';
import {
    SearchOutlined,
    ReloadOutlined,
    VerticalAlignBottomOutlined,
    StopOutlined,
    CopyOutlined,
    CheckCircleOutlined
} from '@ant-design/icons';

interface EngineLogViewerProps {
    logs: string[];
    loading: boolean;
    autoRefresh: boolean;
    onAutoRefreshChange: (checked: boolean) => void;
    onRefresh: () => void;
}

const LogLine: React.FC<{ content: string; searchTerm: string }> = ({ content, searchTerm }) => {
    const isError = content.includes('[ERROR]');
    const isWarn = content.includes('[WARN]');
    const isInfo = content.includes('[INFO]');
    const isDebug = content.includes('[DEBUG]');

    const getLevelStyle = () => {
        if (isError) return { color: '#f87171', backgroundColor: '#450a0a40' };
        if (isWarn) return { color: '#fbbf24', backgroundColor: '#451a0340' };
        if (isInfo) return { color: '#60a5fa' };
        if (isDebug) return { color: '#94a3b8', fontStyle: 'italic' };
        return { color: '#cbd5e1' };
    };

    const highlightText = (text: string, highlight: string) => {
        if (!highlight) return text;
        const parts = text.split(new RegExp(`(${highlight})`, 'gi'));
        return (
            <>
                {parts.map((part, i) =>
                    part.toLowerCase() === highlight.toLowerCase() ? (
                        <span key={i} style={{ backgroundColor: '#f59e0b', color: '#000', borderRadius: '2px', padding: '0 2px' }}>
                            {part}
                        </span>
                    ) : (
                        part
                    )
                )}
            </>
        );
    };

    // New format: [2025-12-29 14:42:04.123] [INFO] [Engine] - Message
    const match = content.match(/^\[(.*?)]\s+\[(.*?)]\s+\[(.*?)]\s+-\s+(.*)$/);
    if (match) {
        const [, timestamp, level, component, message] = match;
        return (
            <div style={{
                display: 'flex',
                gap: '12px',
                padding: '4px 8px',
                borderBottom: '1px solid #1e293b50',
                ...getLevelStyle(),
                borderRadius: '4px',
                marginBottom: '2px'
            }}>
                <span style={{ color: '#64748b', flexShrink: 0, fontSize: '11px', width: '150px' }}>{timestamp}</span>
                <span style={{
                    flexShrink: 0,
                    width: '60px',
                    fontSize: '10px',
                    fontWeight: 700,
                    textAlign: 'center',
                    border: '1px solid currentColor',
                    borderRadius: '3px',
                    height: '18px',
                    lineHeight: '16px'
                }}>{level}</span>
                <span style={{ color: '#94a3b8', flexShrink: 0, width: '80px', fontSize: '11px', overflow: 'hidden', textOverflow: 'ellipsis' }}>{component}</span>
                <span style={{ color: '#f1f5f9', wordBreak: 'break-all', flex: 1 }}>{highlightText(message, searchTerm)}</span>
            </div>
        );
    }

    return (
        <div style={{ ...getLevelStyle(), padding: '4px 8px', whiteSpace: 'pre-wrap', wordBreak: 'break-all', borderRadius: '4px' }}>
            {highlightText(content, searchTerm)}
        </div>
    );
};


const EngineLogViewer: React.FC<EngineLogViewerProps> = ({
    logs,
    loading,
    autoRefresh,
    onAutoRefreshChange,
    onRefresh
}) => {
    const [searchTerm, setSearchTerm] = useState('');
    const [copied, setCopied] = useState(false);
    const scrollRef = useRef<HTMLDivElement>(null);
    const [isAtBottom, setIsAtBottom] = useState(true);

    const filteredLogs = useMemo(() => {
        if (!searchTerm) return logs;
        return logs.filter(line => line.toLowerCase().includes(searchTerm.toLowerCase()));
    }, [logs, searchTerm]);

    const scrollToBottom = () => {
        if (scrollRef.current) {
            scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
        }
    };

    const handleScroll = () => {
        if (scrollRef.current) {
            const { scrollTop, scrollHeight, clientHeight } = scrollRef.current;
            const isBottom = Math.abs(scrollHeight - clientHeight - scrollTop) < 50;
            setIsAtBottom(isBottom);
        }
    };

    useEffect(() => {
        if (autoRefresh && isAtBottom) {
            scrollToBottom();
        }
    }, [logs, autoRefresh, isAtBottom]);

    const handleCopy = () => {
        navigator.clipboard.writeText(logs.join('\n'));
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
    };

    return (
        <div style={{
            display: 'flex',
            flexDirection: 'column',
            height: '500px',
            background: '#0f172a',
            borderRadius: '12px',
            border: '1px solid #1e293b',
            overflow: 'hidden',
            boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)'
        }}>
            {/* Header / Toolbar */}
            <div style={{
                padding: '12px 16px',
                borderBottom: '1px solid #1e293b',
                background: '#1e293b40',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                backdropFilter: 'blur(8px)'
            }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                    <Input
                        prefix={<SearchOutlined style={{ color: '#64748b' }} />}
                        placeholder="搜索日志..."
                        variant="borderless"
                        value={searchTerm}
                        onChange={e => setSearchTerm(e.target.value)}
                        style={{ background: '#0f172a', color: '#e2e8f0', width: '200px', borderRadius: '6px' }}
                    />
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <span style={{ color: '#94a3b8', fontSize: '12px' }}>自动刷新</span>
                        <Switch size="small" checked={autoRefresh} onChange={onAutoRefreshChange} />
                        {autoRefresh && <Badge color="cyan" status="processing" />}
                    </div>
                </div>
                <Space>
                    <Tooltip title="复制全部">
                        <Button
                            type="text"
                            icon={copied ? <CheckCircleOutlined style={{ color: '#10b981' }} /> : <CopyOutlined style={{ color: '#94a3b8' }} />}
                            onClick={handleCopy}
                        />
                    </Tooltip>
                    <Tooltip title="刷新">
                        <Button
                            type="text"
                            icon={<ReloadOutlined style={{ color: '#94a3b8' }} />}
                            onClick={onRefresh}
                            loading={loading}
                        />
                    </Tooltip>
                    {!isAtBottom && (
                        <Tooltip title="跳至底部">
                            <Button
                                type="primary"
                                size="small"
                                icon={<VerticalAlignBottomOutlined />}
                                onClick={scrollToBottom}
                                style={{
                                    animation: 'bounce 2s infinite',
                                    backgroundColor: '#3b82f6',
                                    border: 'none'
                                }}
                            >
                                到底部
                            </Button>
                        </Tooltip>
                    )}
                </Space>
            </div>

            {/* Log Content */}
            <div
                ref={scrollRef}
                onScroll={handleScroll}
                style={{
                    flex: 1,
                    padding: '16px',
                    overflowY: 'auto',
                    fontFamily: '"JetBrains Mono", "Fira Code", "Source Code Pro", monospace',
                    fontSize: '13px',
                    lineHeight: '1.6',
                    color: '#e2e8f0'
                }}
            >
                {filteredLogs.length === 0 ? (
                    <div style={{ height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <Empty
                            image={<StopOutlined style={{ fontSize: '48px', color: '#334155' }} />}
                            description={<span style={{ color: '#64748b' }}>{searchTerm ? '未匹配到日志' : '暂无日志输出'}</span>}
                        />
                    </div>
                ) : (
                    filteredLogs.map((line, index) => (
                        <LogLine key={index} content={line} searchTerm={searchTerm} />
                    ))
                )}
            </div>

            {/* Footer / Status */}
            <div style={{
                padding: '4px 16px',
                borderTop: '1px solid #1e293b',
                background: '#1e293b40',
                display: 'flex',
                justifyContent: 'space-between',
                fontSize: '11px',
                color: '#64748b'
            }}>
                <span>TOTAL: {logs.length} LINES</span>
                <span>{searchTerm ? `MATCHED: ${filteredLogs.length} LINES` : 'READY'}</span>
            </div>

            <style>{`
                @keyframes bounce {
                    0%, 20%, 50%, 80%, 100% {transform: translateY(0);}
                    40% {transform: translateY(-4px);}
                    60% {transform: translateY(-2px);}
                }
                div::-webkit-scrollbar {
                    width: 8px;
                }
                div::-webkit-scrollbar-track {
                    background: #0f172a;
                }
                div::-webkit-scrollbar-thumb {
                    background: #1e293b;
                    border-radius: 4px;
                }
                div::-webkit-scrollbar-thumb:hover {
                    background: #334155;
                }
            `}</style>
        </div>
    );
};

export default EngineLogViewer;
