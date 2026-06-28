import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
    Button,
    Empty,
    Segmented,
    Select,
    Space,
    Switch,
    Table,
    Tabs,
    Tooltip,
    message,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
    AlarmClock,
    CircleAlert,
    Database,
    Gauge,
    RefreshCw,
    Server,
    Settings2,
    ShieldCheck,
    WifiOff,
} from 'lucide-react';
import Auth from '@/components/Auth';
import { getDeployEnvironments, type DeployEnvironment } from '@/api/version';
import { getSystemList } from '@/api/ops';
import {
    collectMonitorTarget,
    getDatabaseMonitors,
    getMonitorOverview,
    getServerMonitors,
    type CollectionState,
    type DatabaseMonitorSummary,
    type MonitorOverview,
    type MonitorRange,
    type MonitorSeverity,
    type MonitorTargetType,
    type ServerMonitorSummary,
} from '@/api/systemMonitor';
import MonitorDetailDrawer from './MonitorDetailDrawer';
import ThresholdDrawer from './ThresholdDrawer';
import {
    CollectionStateTag,
    MetricProgress,
    MonitorError,
    SeverityTag,
    UnmonitoredMetric,
    formatDuration,
    formatPercent,
    formatRate,
    isServerMetricEnabled,
} from './monitorUtils';

type StatusFilter = CollectionState | MonitorSeverity;

interface SystemOption {
    id: number;
    name: string;
}

interface ThresholdTarget {
    targetType: MonitorTargetType;
    targetId?: number;
    targetName?: string;
}

interface SystemPerformanceMonitorProps {
    scopedSystemId?: number;
    systemOptions?: SystemOption[];
    onScopedSystemChange?: (systemId?: number) => void;
}

interface ActionTextButtonProps {
    children: React.ReactNode;
    onClick: () => void;
}

const ActionTextButton: React.FC<ActionTextButtonProps> = ({ children, onClick }) => (
    <button
        type="button"
        className="text-sm text-blue-600 outline-none hover:text-blue-500 focus-visible:text-blue-700 focus-visible:underline"
        onClick={onClick}
    >
        {children}
    </button>
);

const emptyOverview: MonitorOverview = {
    total: 0,
    normal: 0,
    warning: 0,
    critical: 0,
    unavailable: 0,
};

const SystemPerformanceMonitor: React.FC<SystemPerformanceMonitorProps> = ({
    scopedSystemId,
    systemOptions,
    onScopedSystemChange,
}) => {
    const [targetType, setTargetType] = useState<MonitorTargetType>('SERVER');
    const [range, setRange] = useState<MonitorRange>('24h');
    const [systemId, setSystemId] = useState<number>();
    const [envId, setEnvId] = useState<number>();
    const [status, setStatus] = useState<StatusFilter>();
    const [loadedSystems, setLoadedSystems] = useState<SystemOption[]>([]);
    const [environments, setEnvironments] = useState<DeployEnvironment[]>([]);
    const [overview, setOverview] = useState<MonitorOverview>(emptyOverview);
    const [servers, setServers] = useState<ServerMonitorSummary[]>([]);
    const [databases, setDatabases] = useState<DatabaseMonitorSummary[]>([]);
    const [loading, setLoading] = useState(false);
    const [autoRefresh, setAutoRefresh] = useState(true);
    const [selectedServer, setSelectedServer] = useState<ServerMonitorSummary | null>(null);
    const [selectedDatabase, setSelectedDatabase] = useState<DatabaseMonitorSummary | null>(null);
    const [thresholdTarget, setThresholdTarget] = useState<ThresholdTarget | null>(null);

    const loadSystems = useCallback(async () => {
        try {
            const data = await getSystemList({ showAll: true });
            setLoadedSystems((data || []).map(item => ({ id: Number(item.id), name: item.name })));
        } catch {
            setLoadedSystems([]);
        }
    }, []);

    const systems = systemOptions?.length ? systemOptions : loadedSystems;

    const loadData = useCallback(async (silent = false) => {
        if (!silent) setLoading(true);
        try {
            const query = {
                targetType,
                systemId: targetType === 'SERVER' ? systemId : undefined,
                envId: targetType === 'SERVER' ? envId : undefined,
                status,
            };
            const overviewRequest = getMonitorOverview(query);
            if (targetType === 'SERVER') {
                const [overviewData, serverData] = await Promise.all([
                    overviewRequest,
                    getServerMonitors({ systemId, envId, status }),
                ]);
                setOverview(overviewData);
                setServers(serverData || []);
            } else {
                const [overviewData, databaseData] = await Promise.all([
                    overviewRequest,
                    getDatabaseMonitors({ status }),
                ]);
                setOverview(overviewData);
                setDatabases(databaseData || []);
            }
        } catch {
            if (!silent) message.error('性能监控数据加载失败');
        } finally {
            if (!silent) setLoading(false);
        }
    }, [envId, status, systemId, targetType]);

    useEffect(() => {
        if (systemOptions?.length) return;
        loadSystems();
    }, [loadSystems, systemOptions]);

    useEffect(() => {
        setSystemId(scopedSystemId);
        setEnvId(undefined);
    }, [scopedSystemId]);

    useEffect(() => {
        if (!systemId) {
            setEnvironments([]);
            setEnvId(undefined);
            return;
        }
        getDeployEnvironments(systemId)
            .then(data => setEnvironments(data || []))
            .catch(() => setEnvironments([]));
    }, [systemId]);

    useEffect(() => {
        loadData();
    }, [loadData]);

    useEffect(() => {
        if (!autoRefresh) return;
        const timer = window.setInterval(() => {
            if (document.visibilityState === 'visible') void loadData(true);
        }, 15000);
        return () => window.clearInterval(timer);
    }, [autoRefresh, loadData]);

    const collect = async (type: MonitorTargetType, id: number) => {
        try {
            const result = await collectMonitorTarget(type, id);
            if (!result.accepted) {
                message.warning(result.message || '当前目标不可采集');
                return;
            }
            message.success('采集任务已提交');
            window.setTimeout(() => void loadData(true), 1500);
        } catch {
            message.error('提交采集任务失败');
        }
    };

    const serverColumns: ColumnsType<ServerMonitorSummary> = useMemo(() => [
        {
            title: '服务器',
            key: 'server',
            fixed: 'left',
            width: 190,
            render: (_, record) => (
                <button className="text-left" onClick={() => setSelectedServer(record)}>
                    <div className="font-medium text-slate-800 hover:text-red-600">{record.hostname}</div>
                    <div className="mt-0.5 text-xs text-slate-400">{record.internalIp} · {record.envType || '未分环境'}</div>
                </button>
            ),
        },
        {
            title: '状态',
            key: 'status',
            width: 155,
            render: (_, record) => (
                <Space size={2} wrap>
                    <SeverityTag severity={record.severity} />
                    <CollectionStateTag state={record.collectionState} />
                </Space>
            ),
        },
        {
            title: 'CPU',
            dataIndex: 'cpuPercent',
            width: 135,
            render: (value, record) => isServerMetricEnabled(record.enabledMetrics, 'CPU')
                ? <MetricProgress value={value} />
                : <UnmonitoredMetric />,
        },
        {
            title: '内存',
            dataIndex: 'memoryPercent',
            width: 135,
            render: (value, record) => isServerMetricEnabled(record.enabledMetrics, 'MEMORY')
                ? <MetricProgress value={value} />
                : <UnmonitoredMetric />,
        },
        {
            title: '磁盘',
            dataIndex: 'diskPercent',
            width: 135,
            render: (value, record) => isServerMetricEnabled(record.enabledMetrics, 'DISK')
                ? <MetricProgress value={value} />
                : <UnmonitoredMetric />,
        },
        {
            title: '负载',
            dataIndex: 'loadOne',
            width: 75,
            render: (value, record) => isServerMetricEnabled(record.enabledMetrics, 'LOAD')
                ? (value == null ? '-' : value.toFixed(2))
                : <UnmonitoredMetric />,
        },
        {
            title: '网络',
            key: 'network',
            width: 150,
            render: (_, record) => isServerMetricEnabled(record.enabledMetrics, 'NETWORK') ? (
                <div className="text-xs leading-5 text-slate-600">
                    <div>↓ {formatRate(record.networkRxBps)}</div>
                    <div>↑ {formatRate(record.networkTxBps)}</div>
                </div>
            ) : <UnmonitoredMetric />,
        },
        {
            title: '运行时间',
            dataIndex: 'uptimeSeconds',
            width: 130,
            render: (value, record) => (
                <span className="whitespace-nowrap">
                    {isServerMetricEnabled(record.enabledMetrics, 'UPTIME')
                        ? formatDuration(value)
                        : <UnmonitoredMetric />}
                </span>
            ),
        },
        {
            title: '采集信息',
            key: 'collection',
            width: 205,
            render: (_, record) => (
                <div>
                    <div className="text-xs text-slate-500">{record.collectedAt ? new Date(record.collectedAt).toLocaleString() : '-'}</div>
                    <MonitorError message={record.errorMessage} />
                </div>
            ),
        },
        {
            title: '操作',
            key: 'actions',
            fixed: 'right',
            width: 185,
            render: (_, record) => (
                <Space size={8} className="whitespace-nowrap">
                    <ActionTextButton onClick={() => setSelectedServer(record)}>详情</ActionTextButton>
                    <Auth code="sys:monitor:collect">
                        <ActionTextButton onClick={() => collect('SERVER', record.assetId)}>采集</ActionTextButton>
                    </Auth>
                    <Auth code="sys:monitor:config">
                        <ActionTextButton
                            onClick={() => setThresholdTarget({
                                targetType: 'SERVER',
                                targetId: record.assetId,
                                targetName: record.hostname,
                            })}
                        >
                            配置
                        </ActionTextButton>
                    </Auth>
                </Space>
            ),
        },
    ], [loadData]);

    const databaseColumns: ColumnsType<DatabaseMonitorSummary> = useMemo(() => [
        {
            title: 'MySQL数据源',
            key: 'database',
            fixed: 'left',
            width: 210,
            render: (_, record) => (
                <button className="text-left" onClick={() => setSelectedDatabase(record)}>
                    <div className="font-medium text-slate-800 hover:text-red-600">{record.name}</div>
                    <div className="mt-0.5 text-xs text-slate-400">
                        {record.host || '-'}:{record.port || '-'} · {record.databaseName || '-'}
                    </div>
                </button>
            ),
        },
        {
            title: '状态',
            key: 'status',
            width: 155,
            render: (_, record) => (
                <Space size={2} wrap>
                    <SeverityTag severity={record.severity} />
                    <CollectionStateTag state={record.collectionState} />
                </Space>
            ),
        },
        {
            title: '连接',
            key: 'connections',
            width: 155,
            render: (_, record) => (
                <div>
                    <MetricProgress value={record.connectionPercent} />
                    <div className="mt-1 text-xs text-slate-400">
                        {record.threadsConnected ?? '-'}/{record.maxConnections ?? '-'} · 活跃 {record.threadsRunning ?? '-'}
                    </div>
                </div>
            ),
        },
        { title: '延迟', dataIndex: 'latencyMs', width: 85, render: value => value == null ? '-' : `${value} ms` },
        { title: 'QPS', dataIndex: 'qps', width: 85, render: value => value == null ? '-' : value.toFixed(1) },
        { title: 'TPS', dataIndex: 'tps', width: 85, render: value => value == null ? '-' : value.toFixed(1) },
        {
            title: '慢SQL',
            key: 'slowSql',
            width: 115,
            render: (_, record) => (
                <div className="text-xs leading-5">
                    <div>{record.slowQueries ?? '-'} 条</div>
                    <div className="text-slate-400">
                        均值 {record.slowSqlAvgLatencyMs == null ? '-' : `${record.slowSqlAvgLatencyMs.toFixed(1)} ms`}
                    </div>
                </div>
            ),
        },
        {
            title: '缓冲池命中',
            dataIndex: 'bufferPoolHitPercent',
            width: 110,
            render: formatPercent,
        },
        { title: '锁等待', dataIndex: 'rowLockWaits', width: 85, render: value => value ?? '-' },
        {
            title: '采集信息',
            key: 'collection',
            width: 205,
            render: (_, record) => (
                <div>
                    <div className="text-xs text-slate-500">{record.collectedAt ? new Date(record.collectedAt).toLocaleString() : '-'}</div>
                    <MonitorError message={record.errorMessage} />
                </div>
            ),
        },
        {
            title: '操作',
            key: 'actions',
            fixed: 'right',
            width: 185,
            render: (_, record) => (
                <Space size={8} className="whitespace-nowrap">
                    <ActionTextButton onClick={() => setSelectedDatabase(record)}>详情</ActionTextButton>
                    <Auth code="sys:monitor:collect">
                        <ActionTextButton onClick={() => collect('DATABASE', record.datasourceId)}>采集</ActionTextButton>
                    </Auth>
                    <Auth code="sys:monitor:config">
                        <ActionTextButton
                            onClick={() => setThresholdTarget({
                                targetType: 'DATABASE',
                                targetId: record.datasourceId,
                                targetName: record.name,
                            })}
                        >
                            阈值
                        </ActionTextButton>
                    </Auth>
                </Space>
            ),
        },
    ], [loadData]);

    return (
        <div className="space-y-4">
            <MonitorOverviewStrip overview={overview} />

            <div className="rounded-lg border border-slate-200 bg-white p-3 shadow-sm">
                <div className="flex flex-wrap items-center justify-between gap-3">
                    <div className="flex flex-wrap items-center gap-2">
                        {targetType === 'SERVER' && (
                            <>
                                <Select
                                    allowClear
                                    showSearch
                                    optionFilterProp="label"
                                    className="w-40"
                                    placeholder="全部系统"
                                    value={systemId}
                                    onChange={value => {
                                        setSystemId(value);
                                        setEnvId(undefined);
                                        onScopedSystemChange?.(value);
                                    }}
                                    options={systems.map(item => ({ value: item.id, label: item.name }))}
                                />
                                <Select
                                    allowClear
                                    className="w-36"
                                    placeholder="全部环境"
                                    disabled={!systemId}
                                    value={envId}
                                    onChange={setEnvId}
                                    options={environments.map(item => ({ value: item.id!, label: item.name }))}
                                />
                            </>
                        )}
                        <Select
                            allowClear
                            className="w-32"
                            placeholder="全部状态"
                            value={status}
                            onChange={setStatus}
                            options={[
                                { value: 'NORMAL', label: '正常' },
                                { value: 'WARNING', label: '预警' },
                                { value: 'CRITICAL', label: '严重' },
                                { value: 'UNAVAILABLE', label: '不可达' },
                                { value: 'STALE', label: '数据过期' },
                            ]}
                        />
                        <Segmented
                            size="small"
                            value={range}
                            onChange={value => setRange(value as MonitorRange)}
                            options={[
                                { value: '1h', label: '1小时' },
                                { value: '24h', label: '24小时' },
                                { value: '7d', label: '7天' },
                            ]}
                        />
                    </div>
                    <div className="flex items-center gap-2">
                        <Tooltip title="页面每15秒获取最新采样，后台采集固定每60秒执行">
                            <span className="flex items-center gap-2 text-xs text-slate-500">
                                自动刷新 <Switch size="small" checked={autoRefresh} onChange={setAutoRefresh} />
                            </span>
                        </Tooltip>
                        <Button icon={<RefreshCw size={14} />} loading={loading} onClick={() => loadData()}>
                            刷新
                        </Button>
                        <Auth code="sys:monitor:config">
                            <Button
                                icon={<Settings2 size={14} />}
                                onClick={() => setThresholdTarget({ targetType })}
                            >
                                全局配置
                            </Button>
                        </Auth>
                    </div>
                </div>
            </div>

            <Tabs
                activeKey={targetType}
                onChange={key => {
                    setTargetType(key as MonitorTargetType);
                    setStatus(undefined);
                }}
                items={[
                    {
                        key: 'SERVER',
                        label: <span className="inline-flex items-center gap-1.5"><Server size={15} />服务器监控</span>,
                        children: (
                            <Table
                                rowKey="assetId"
                                size="small"
                                loading={loading}
                                columns={serverColumns}
                                dataSource={servers}
                                scroll={{ x: 1550 }}
                                pagination={{ pageSize: 15, showSizeChanger: true, showTotal: total => `共 ${total} 台` }}
                                locale={{ emptyText: <Empty description="暂无服务器监控目标" /> }}
                            />
                        ),
                    },
                    {
                        key: 'DATABASE',
                        label: <span className="inline-flex items-center gap-1.5"><Database size={15} />MySQL监控</span>,
                        children: (
                            <Table
                                rowKey="datasourceId"
                                size="small"
                                loading={loading}
                                columns={databaseColumns}
                                dataSource={databases}
                                scroll={{ x: 1450 }}
                                pagination={{ pageSize: 15, showSizeChanger: true, showTotal: total => `共 ${total} 个` }}
                                locale={{ emptyText: <Empty description="暂无已启用的MySQL数据源" /> }}
                            />
                        ),
                    },
                ]}
            />

            <MonitorDetailDrawer
                open={!!selectedServer || !!selectedDatabase}
                range={range}
                server={selectedServer}
                database={selectedDatabase}
                onRangeChange={setRange}
                onClose={() => { setSelectedServer(null); setSelectedDatabase(null); }}
            />

            {thresholdTarget && (
                <ThresholdDrawer
                    open
                    {...thresholdTarget}
                    onClose={() => setThresholdTarget(null)}
                    onSaved={() => loadData(true)}
                />
            )}
        </div>
    );
};

const MonitorOverviewStrip: React.FC<{ overview: MonitorOverview }> = ({ overview }) => {
    const items = [
        { label: '监控目标', value: overview.total, icon: <Gauge size={17} />, className: 'text-slate-700' },
        { label: '正常', value: overview.normal, icon: <ShieldCheck size={17} />, className: 'text-emerald-600' },
        { label: '预警', value: overview.warning, icon: <CircleAlert size={17} />, className: 'text-amber-600' },
        { label: '严重', value: overview.critical, icon: <AlarmClock size={17} />, className: 'text-red-600' },
        { label: '不可用/过期', value: overview.unavailable, icon: <WifiOff size={17} />, className: 'text-slate-500' },
    ];
    return (
        <div className="grid grid-cols-2 overflow-hidden rounded-lg border border-slate-200 bg-white shadow-sm sm:grid-cols-5">
            {items.map((item, index) => (
                <div
                    key={item.label}
                    className={`flex items-center justify-between px-4 py-3 ${index ? 'border-l border-slate-100' : ''}`}
                >
                    <div>
                        <div className="text-xs text-slate-400">{item.label}</div>
                        <div className={`mt-1 text-xl font-semibold tabular-nums ${item.className}`}>{item.value}</div>
                    </div>
                    <div className={item.className}>{item.icon}</div>
                </div>
            ))}
        </div>
    );
};

export default SystemPerformanceMonitor;
