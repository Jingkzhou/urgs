import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Alert, Descriptions, Drawer, Empty, Segmented, Spin, Table, Tabs } from 'antd';
import {
    CartesianGrid,
    Legend,
    Line,
    LineChart,
    ResponsiveContainer,
    Tooltip,
    XAxis,
    YAxis,
} from 'recharts';
import type {
    DatabaseMonitorSummary,
    MonitorRange,
    MonitorTrendPoint,
    ServerMonitorSummary,
    SlowSqlItem,
} from '@/api/systemMonitor';
import { getDatabaseTrend, getServerTrend, getSlowSql } from '@/api/systemMonitor';
import {
    CollectionStateTag,
    SeverityTag,
    UnmonitoredMetric,
    formatBytes,
    formatDuration,
    formatPercent,
    formatRate,
    isServerMetricEnabled,
} from './monitorUtils';

interface MonitorDetailDrawerProps {
    open: boolean;
    range: MonitorRange;
    server?: ServerMonitorSummary | null;
    database?: DatabaseMonitorSummary | null;
    onRangeChange: (range: MonitorRange) => void;
    onClose: () => void;
}

const rangeOptions = [
    { label: '1小时', value: '1h' },
    { label: '24小时', value: '24h' },
    { label: '7天', value: '7d' },
];

const MonitorDetailDrawer: React.FC<MonitorDetailDrawerProps> = ({
    open, range, server, database, onRangeChange, onClose,
}) => {
    const [trend, setTrend] = useState<MonitorTrendPoint[]>([]);
    const [slowSql, setSlowSql] = useState<SlowSqlItem[]>([]);
    const [loading, setLoading] = useState(false);
    const targetType = server ? 'SERVER' : 'DATABASE';

    const loadDetails = useCallback((silent = false) => {
        if (!open || (!server && !database)) return;
        if (!silent) setLoading(true);
        const trendRequest = server
            ? getServerTrend(server.assetId, range)
            : getDatabaseTrend(database!.datasourceId, range);
        const slowSqlRequest = database?.slowSqlAvailable
            ? getSlowSql(database.datasourceId, range)
            : Promise.resolve([]);
        Promise.all([trendRequest, slowSqlRequest])
            .then(([trendData, slowSqlData]) => {
                setTrend(trendData || []);
                setSlowSql(slowSqlData || []);
            })
            .catch(() => {
                if (!silent) {
                    setTrend([]);
                    setSlowSql([]);
                }
            })
            .finally(() => {
                if (!silent) setLoading(false);
            });
    }, [database, open, range, server]);

    useEffect(() => {
        loadDetails();
        if (!open) return;
        const timer = window.setInterval(() => {
            if (document.visibilityState === 'visible') loadDetails(true);
        }, 15000);
        return () => window.clearInterval(timer);
    }, [loadDetails, open]);

    const chartData = useMemo(() => trend.map(item => ({
        ...item,
        label: new Date(item.time).toLocaleString('zh-CN', {
            month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit',
        }),
    })), [trend]);

    const title = server ? `${server.hostname} · 服务器性能` : `${database?.name || ''} · MySQL性能`;
    const errorMessage = server?.errorMessage || database?.errorMessage;

    return (
        <Drawer open={open} width="min(920px, 92vw)" title={title} onClose={onClose}>
            <div className="mb-4 flex items-center justify-between gap-3">
                <div className="flex items-center gap-2">
                    {(server || database) && <CollectionStateTag state={(server || database)!.collectionState} />}
                    {(server || database) && <SeverityTag severity={(server || database)!.severity} />}
                </div>
                <Segmented
                    size="small"
                    value={range}
                    options={rangeOptions}
                    onChange={value => onRangeChange(value as MonitorRange)}
                />
            </div>

            {errorMessage && <Alert className="mb-4" type="warning" showIcon message={errorMessage} />}

            <Spin spinning={loading}>
                {targetType === 'SERVER' && server ? (
                    <ServerDetail server={server} chartData={chartData} />
                ) : database ? (
                    <DatabaseDetail database={database} chartData={chartData} slowSql={slowSql} />
                ) : null}
            </Spin>
        </Drawer>
    );
};

const ServerDetail: React.FC<{ server: ServerMonitorSummary; chartData: any[] }> = ({ server, chartData }) => {
    const percentLines: Array<[string, string, string]> = [
        isServerMetricEnabled(server.enabledMetrics, 'CPU') ? ['cpuPercent', 'CPU', '#ef4444'] : null,
        isServerMetricEnabled(server.enabledMetrics, 'MEMORY') ? ['memoryPercent', '内存', '#3b82f6'] : null,
        isServerMetricEnabled(server.enabledMetrics, 'DISK') ? ['diskPercent', '磁盘', '#f59e0b'] : null,
    ].filter(Boolean) as Array<[string, string, string]>;
    const operationalLines: Array<[string, string, string]> = [
        isServerMetricEnabled(server.enabledMetrics, 'LOAD') ? ['loadOne', '负载', '#8b5cf6'] : null,
        isServerMetricEnabled(server.enabledMetrics, 'NETWORK') ? ['networkRxBps', '接收B/s', '#06b6d4'] : null,
        isServerMetricEnabled(server.enabledMetrics, 'NETWORK') ? ['networkTxBps', '发送B/s', '#10b981'] : null,
    ].filter(Boolean) as Array<[string, string, string]>;
    const diskEnabled = isServerMetricEnabled(server.enabledMetrics, 'DISK');

    return (
        <Tabs
            items={[
                {
                    key: 'trend',
                    label: '资源趋势',
                    children: (
                        <div className="space-y-5">
                            <Descriptions size="small" bordered column={3}>
                                <Descriptions.Item label="主机">{server.internalIp}</Descriptions.Item>
                                <Descriptions.Item label="系统">{server.osType || '-'}</Descriptions.Item>
                                <Descriptions.Item label="运行时间">
                                    {isServerMetricEnabled(server.enabledMetrics, 'UPTIME')
                                        ? formatDuration(server.uptimeSeconds)
                                        : <UnmonitoredMetric />}
                                </Descriptions.Item>
                                <Descriptions.Item label="CPU">
                                    {isServerMetricEnabled(server.enabledMetrics, 'CPU')
                                        ? formatPercent(server.cpuPercent)
                                        : <UnmonitoredMetric />}
                                </Descriptions.Item>
                                <Descriptions.Item label="内存">
                                    {isServerMetricEnabled(server.enabledMetrics, 'MEMORY')
                                        ? formatPercent(server.memoryPercent)
                                        : <UnmonitoredMetric />}
                                </Descriptions.Item>
                                <Descriptions.Item label="磁盘">
                                    {diskEnabled ? formatPercent(server.diskPercent) : <UnmonitoredMetric />}
                                </Descriptions.Item>
                                <Descriptions.Item label="负载">
                                    {isServerMetricEnabled(server.enabledMetrics, 'LOAD')
                                        ? (server.loadOne?.toFixed(2) || '-')
                                        : <UnmonitoredMetric />}
                                </Descriptions.Item>
                                <Descriptions.Item label="接收">
                                    {isServerMetricEnabled(server.enabledMetrics, 'NETWORK')
                                        ? formatRate(server.networkRxBps)
                                        : <UnmonitoredMetric />}
                                </Descriptions.Item>
                                <Descriptions.Item label="发送">
                                    {isServerMetricEnabled(server.enabledMetrics, 'NETWORK')
                                        ? formatRate(server.networkTxBps)
                                        : <UnmonitoredMetric />}
                                </Descriptions.Item>
                            </Descriptions>
                            {percentLines.length > 0 && <TrendChart data={chartData} lines={percentLines} unit="%" />}
                            {operationalLines.length > 0 && <TrendChart data={chartData} lines={operationalLines} />}
                        </div>
                    ),
                },
                {
                    key: 'disks',
                    label: `磁盘挂载点 (${diskEnabled ? server.disks.length : 0})`,
                    children: diskEnabled ? (
                        <Table
                            size="small"
                            rowKey={record => `${record.filesystem}-${record.mountPoint}`}
                            pagination={false}
                            dataSource={server.disks}
                            locale={{ emptyText: <Empty description="暂无磁盘明细" /> }}
                            columns={[
                                { title: '文件系统', dataIndex: 'filesystem' },
                                { title: '挂载点', dataIndex: 'mountPoint' },
                                { title: '已使用', dataIndex: 'usedBytes', render: formatBytes },
                                { title: '总容量', dataIndex: 'totalBytes', render: formatBytes },
                                { title: '使用率', dataIndex: 'usedPercent', render: formatPercent },
                            ]}
                        />
                    ) : (
                        <Alert type="info" showIcon message="磁盘未纳入当前服务器监控内容" />
                    ),
                },
            ]}
        />
    );
};

const DatabaseDetail: React.FC<{
    database: DatabaseMonitorSummary;
    chartData: any[];
    slowSql: SlowSqlItem[];
}> = ({ database, chartData, slowSql }) => (
    <Tabs
        items={[
            {
                key: 'trend',
                label: '运行趋势',
                children: (
                    <div className="space-y-5">
                        <Descriptions size="small" bordered column={3}>
                            <Descriptions.Item label="地址">{database.host || '-'}:{database.port || '-'}</Descriptions.Item>
                            <Descriptions.Item label="数据库">{database.databaseName || '-'}</Descriptions.Item>
                            <Descriptions.Item label="版本">{database.version || '-'}</Descriptions.Item>
                            <Descriptions.Item label="连接">
                                {database.threadsConnected ?? '-'}/{database.maxConnections ?? '-'}
                            </Descriptions.Item>
                            <Descriptions.Item label="QPS">{database.qps?.toFixed(1) || '-'}</Descriptions.Item>
                            <Descriptions.Item label="TPS">{database.tps?.toFixed(1) || '-'}</Descriptions.Item>
                            <Descriptions.Item label="慢SQL均值">
                                {database.slowSqlAvgLatencyMs == null ? '-' : `${database.slowSqlAvgLatencyMs.toFixed(1)} ms`}
                            </Descriptions.Item>
                            <Descriptions.Item label="延迟">{database.latencyMs ?? '-'} ms</Descriptions.Item>
                            <Descriptions.Item label="缓冲池命中率">
                                {formatPercent(database.bufferPoolHitPercent)}
                            </Descriptions.Item>
                            <Descriptions.Item label="锁等待">{database.rowLockWaits ?? '-'}</Descriptions.Item>
                        </Descriptions>
                        <TrendChart
                            data={chartData}
                            lines={[
                                ['qps', 'QPS', '#3b82f6'],
                                ['tps', 'TPS', '#10b981'],
                            ]}
                        />
                        <TrendChart
                            data={chartData}
                            lines={[
                                ['connectionPercent', '连接使用率', '#f59e0b'],
                                ['bufferPoolHitPercent', '缓冲池命中率', '#8b5cf6'],
                            ]}
                            unit="%"
                        />
                    </div>
                ),
            },
            {
                key: 'slow-sql',
                label: '慢SQL摘要',
                children: database.slowSqlAvailable ? (
                    <Table
                        size="small"
                        rowKey="digest"
                        dataSource={slowSql}
                        scroll={{ x: 900 }}
                        pagination={{ pageSize: 10, showSizeChanger: false }}
                        locale={{ emptyText: <Empty description="当前时间范围无慢SQL摘要" /> }}
                        columns={[
                            {
                                title: 'SQL摘要',
                                dataIndex: 'digestText',
                                width: 430,
                                render: (text: string) => (
                                    <code className="block max-h-20 overflow-auto whitespace-normal text-xs text-slate-700">
                                        {text}
                                    </code>
                                ),
                            },
                            { title: '执行次数', dataIndex: 'executions', width: 90 },
                            {
                                title: '平均耗时',
                                dataIndex: 'avgLatencyMs',
                                width: 110,
                                render: (value?: number) => value == null ? '-' : `${value.toFixed(1)} ms`,
                            },
                            {
                                title: '总耗时',
                                dataIndex: 'totalLatencyMs',
                                width: 110,
                                render: (value?: number) => value == null ? '-' : `${value.toFixed(1)} ms`,
                            },
                            { title: '扫描行数', dataIndex: 'rowsExamined', width: 100 },
                            { title: '返回行数', dataIndex: 'rowsSent', width: 100 },
                        ]}
                    />
                ) : (
                    <Alert type="info" showIcon message="当前监控账号无法读取 performance_schema 慢SQL摘要" />
                ),
            },
        ]}
    />
);

const TrendChart: React.FC<{
    data: any[];
    lines: Array<[string, string, string]>;
    unit?: string;
}> = ({ data, lines, unit }) => {
    if (!data.length) return <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="暂无趋势数据" />;
    return (
        <div className="h-64 rounded-lg border border-slate-100 bg-white p-3">
            <ResponsiveContainer width="100%" height="100%">
                <LineChart data={data}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                    <XAxis dataKey="label" minTickGap={40} tick={{ fontSize: 11 }} />
                    <YAxis unit={unit} tick={{ fontSize: 11 }} />
                    <Tooltip />
                    <Legend />
                    {lines.map(([key, name, color]) => (
                        <Line
                            key={key}
                            type="monotone"
                            dataKey={key}
                            name={name}
                            stroke={color}
                            dot={false}
                            connectNulls
                            strokeWidth={2}
                        />
                    ))}
                </LineChart>
            </ResponsiveContainer>
        </div>
    );
};

export default MonitorDetailDrawer;
