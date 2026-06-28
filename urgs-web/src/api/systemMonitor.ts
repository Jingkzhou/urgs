import { get, post, put } from '@/utils/request';

export type MonitorTargetType = 'SERVER' | 'DATABASE';
export type CollectionState = 'LIVE' | 'STALE' | 'UNAVAILABLE' | 'PAUSED' | 'UNSUPPORTED';
export type MonitorSeverity = 'NORMAL' | 'WARNING' | 'CRITICAL';
export type MonitorRange = '1h' | '24h' | '7d';
export type ServerMetricKey = 'CPU' | 'MEMORY' | 'DISK' | 'LOAD' | 'NETWORK' | 'UPTIME';

export interface MonitorOverview {
    total: number;
    normal: number;
    warning: number;
    critical: number;
    unavailable: number;
    latestCollectedAt?: string;
}

export interface DiskUsage {
    filesystem: string;
    mountPoint: string;
    totalBytes: number;
    usedBytes: number;
    usedPercent: number;
}

export interface ServerMonitorSummary {
    assetId: number;
    hostname: string;
    internalIp: string;
    osType?: string;
    systemId?: number;
    envId?: number;
    envType?: string;
    assetStatus: string;
    monitorEnabled: boolean;
    collectionState: CollectionState;
    severity: MonitorSeverity;
    cpuPercent?: number;
    memoryPercent?: number;
    diskPercent?: number;
    loadOne?: number;
    networkRxBps?: number;
    networkTxBps?: number;
    uptimeSeconds?: number;
    collectedAt?: string;
    errorMessage?: string;
    disks: DiskUsage[];
    enabledMetrics: ServerMetricKey[];
}

export interface DatabaseMonitorSummary {
    datasourceId: number;
    name: string;
    host?: string;
    port?: number;
    databaseName?: string;
    version?: string;
    collectionState: CollectionState;
    severity: MonitorSeverity;
    latencyMs?: number;
    threadsConnected?: number;
    maxConnections?: number;
    threadsRunning?: number;
    connectionPercent?: number;
    qps?: number;
    tps?: number;
    slowQueries?: number;
    slowSqlAvgLatencyMs?: number;
    bufferPoolHitPercent?: number;
    rowLockWaits?: number;
    uptimeSeconds?: number;
    collectedAt?: string;
    slowSqlAvailable: boolean;
    errorMessage?: string;
}

export interface MonitorTrendPoint {
    time: string;
    cpuPercent?: number;
    memoryPercent?: number;
    diskPercent?: number;
    loadOne?: number;
    networkRxBps?: number;
    networkTxBps?: number;
    latencyMs?: number;
    connectionPercent?: number;
    qps?: number;
    tps?: number;
    slowQueries?: number;
    bufferPoolHitPercent?: number;
    rowLockWaits?: number;
}

export interface SlowSqlItem {
    digest: string;
    digestText: string;
    executions: number;
    avgLatencyMs?: number;
    totalLatencyMs?: number;
    rowsExamined?: number;
    rowsSent?: number;
    collectedAt: string;
}

export interface ThresholdConfig {
    targetType: MonitorTargetType;
    targetId: number;
    enabled: boolean;
    thresholds?: Record<string, number>;
    enabledMetrics?: ServerMetricKey[];
}

export interface MonitorQuery {
    targetType?: MonitorTargetType;
    systemId?: number;
    envId?: number;
    status?: CollectionState | MonitorSeverity;
    includeDisabled?: boolean;
}

export const getMonitorOverview = (params: MonitorQuery) =>
    get<MonitorOverview>('/api/system-monitor/overview', { ...params });

export const getServerMonitors = (params: Omit<MonitorQuery, 'targetType'>) =>
    get<ServerMonitorSummary[]>('/api/system-monitor/servers', params);

export const getDatabaseMonitors = (params: Pick<MonitorQuery, 'status'>) =>
    get<DatabaseMonitorSummary[]>('/api/system-monitor/databases', params);

export const getServerTrend = (assetId: number, range: MonitorRange) =>
    get<MonitorTrendPoint[]>(`/api/system-monitor/servers/${assetId}/trend`, { range });

export const getDatabaseTrend = (datasourceId: number, range: MonitorRange) =>
    get<MonitorTrendPoint[]>(`/api/system-monitor/databases/${datasourceId}/trend`, { range });

export const getSlowSql = (datasourceId: number, range: MonitorRange, limit = 20) =>
    get<SlowSqlItem[]>(`/api/system-monitor/databases/${datasourceId}/slow-sql`, { range, limit });

export const getThresholds = (targetType: MonitorTargetType, targetId?: number) =>
    get<ThresholdConfig>('/api/system-monitor/thresholds', { targetType, targetId });

export const updateThresholds = (config: ThresholdConfig) =>
    put<ThresholdConfig>('/api/system-monitor/thresholds', config);

export const setServerMonitorEnabled = (assetId: number, enabled: boolean) =>
    updateThresholds({ targetType: 'SERVER', targetId: assetId, enabled });

export const collectMonitorTarget = (targetType: MonitorTargetType, targetId: number) =>
    post<{ accepted: boolean; message: string }>(
        `/api/system-monitor/collect/${targetType}/${targetId}`,
    );
