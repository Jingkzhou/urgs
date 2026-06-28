import React from 'react';
import { Tag } from 'antd';
import { AlertTriangle, CirclePause, CircleX, Clock3, Radio, ShieldQuestion } from 'lucide-react';
import type { CollectionState, MonitorSeverity, ServerMetricKey } from '@/api/systemMonitor';

const severityConfig: Record<MonitorSeverity, { color: string; label: string }> = {
    NORMAL: { color: 'success', label: '正常' },
    WARNING: { color: 'warning', label: '预警' },
    CRITICAL: { color: 'error', label: '严重' },
};

const stateConfig: Record<CollectionState, { color: string; label: string; icon: React.ReactNode }> = {
    LIVE: { color: 'processing', label: '实时', icon: <Radio size={12} /> },
    STALE: { color: 'warning', label: '数据过期', icon: <Clock3 size={12} /> },
    UNAVAILABLE: { color: 'error', label: '不可达', icon: <CircleX size={12} /> },
    PAUSED: { color: 'default', label: '已暂停', icon: <CirclePause size={12} /> },
    UNSUPPORTED: { color: 'default', label: '暂不支持', icon: <ShieldQuestion size={12} /> },
};

export const SeverityTag: React.FC<{ severity: MonitorSeverity }> = ({ severity }) => {
    const config = severityConfig[severity];
    return <Tag color={config.color}>{config.label}</Tag>;
};

export const CollectionStateTag: React.FC<{ state: CollectionState }> = ({ state }) => {
    const config = stateConfig[state];
    return (
        <Tag color={config.color}>
            <span className="inline-flex items-center gap-1">{config.icon}{config.label}</span>
        </Tag>
    );
};

export const formatPercent = (value?: number) => value == null ? '-' : `${value.toFixed(1)}%`;

export const formatRate = (value?: number) => {
    if (value == null) return '-';
    if (value >= 1024 * 1024) return `${(value / 1024 / 1024).toFixed(1)} MB/s`;
    if (value >= 1024) return `${(value / 1024).toFixed(1)} KB/s`;
    return `${value} B/s`;
};

export const formatBytes = (value?: number) => {
    if (value == null) return '-';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    let size = value;
    let index = 0;
    while (size >= 1024 && index < units.length - 1) {
        size /= 1024;
        index++;
    }
    return `${size.toFixed(index > 1 ? 1 : 0)} ${units[index]}`;
};

export const formatDuration = (seconds?: number) => {
    if (seconds == null) return '-';
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    if (days > 0) return `${days}天 ${hours}小时`;
    const minutes = Math.floor((seconds % 3600) / 60);
    return `${hours}小时 ${minutes}分`;
};

export const isServerMetricEnabled = (enabledMetrics: ServerMetricKey[] | undefined, metric: ServerMetricKey) =>
    !enabledMetrics || enabledMetrics.length === 0 || enabledMetrics.includes(metric);

export const UnmonitoredMetric: React.FC = () => <span className="text-xs text-slate-400">未监控</span>;

export const MetricProgress: React.FC<{ value?: number }> = ({ value }) => {
    if (value == null) return <span className="text-slate-400">-</span>;
    const status = value >= 90 ? 'exception' : value >= 80 ? 'active' : 'success';
    return (
        <div className="min-w-[105px]">
            <ProgressBar value={value} status={status} />
        </div>
    );
};

const ProgressBar: React.FC<{ value: number; status: 'exception' | 'active' | 'success' }> = ({ value, status }) => {
    const color = status === 'exception' ? 'bg-red-500' : status === 'active' ? 'bg-amber-500' : 'bg-emerald-500';
    return (
        <div className="flex items-center gap-2">
            <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-slate-100">
                <div className={`h-full rounded-full ${color}`} style={{ width: `${Math.min(100, value)}%` }} />
            </div>
            <span className="w-11 text-right text-xs tabular-nums text-slate-600">{value.toFixed(1)}%</span>
        </div>
    );
};

export const MonitorError: React.FC<{ message?: string }> = ({ message }) => message ? (
    <span className="inline-flex max-w-[220px] items-center gap-1 truncate text-xs text-red-500" title={message}>
        <AlertTriangle size={12} />{message}
    </span>
) : null;
