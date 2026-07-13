import { get, post, put, del } from '@/utils/request';

// ===== Infrastructure Asset API =====

export interface InfrastructureUser {
    id?: number;
    username: string;
    password?: string;
    userType?: string;  // os(操作系统) / db(数据库)
    description?: string;
    createdAt?: string;
    updatedAt?: string;
}

export interface InfrastructureAsset {
    id?: number;
    hostname: string;
    internalIp: string;
    externalIp?: string;
    osType?: string;
    osVersion?: string;
    cpu?: string;
    memory?: string;
    disk?: string;
    hardwareModel?: string;
    role?: string;
    dbType?: string;
    dbPort?: number;
    dbName?: string;
    dbServiceName?: string;
    appSystemId?: number;
    envId?: number;
    envType?: string;
    users?: InfrastructureUser[];
    status: 'active' | 'maintenance' | 'offline';
    description?: string;
    createdAt?: string;
    updatedAt?: string;
}

export interface InfrastructureSystemManual {
    id?: number;
    appSystemId: number;
    title: string;
    fileName: string;
    fileUrl: string;
    fileSize?: number;
    description?: string;
    createdAt?: string;
    updatedAt?: string;
}

export interface CommonUploadResult {
    url: string;
    name: string;
}

export const getInfrastructureAssets = (params?: { appSystemId?: number; envId?: number; envType?: string }) =>
    get<InfrastructureAsset[]>('/api/ops/infrastructure', params || {});

export const createInfrastructureAsset = (data: InfrastructureAsset) =>
    post<InfrastructureAsset>('/api/ops/infrastructure', data);

export const updateInfrastructureAsset = (id: number, data: InfrastructureAsset) =>
    put<InfrastructureAsset>(`/api/ops/infrastructure/${id}`, data);

export const deleteInfrastructureAsset = (id: number) =>
    del(`/api/ops/infrastructure/${id}`);

export const exportInfrastructureAssets = () =>
    get<Blob>('/api/ops/infrastructure/export', undefined, { isBlob: true });

export const importInfrastructureAssets = (file: File) => {
    const formData = new FormData();
    formData.append('file', file);
    return post<void>('/api/ops/infrastructure/import', formData);
};

export const getInfrastructureSystemManuals = (params?: { appSystemId?: number; keyword?: string }) =>
    get<InfrastructureSystemManual[]>('/api/ops/infrastructure/manuals', params || {});

export const createInfrastructureSystemManual = (data: InfrastructureSystemManual) =>
    post<InfrastructureSystemManual>('/api/ops/infrastructure/manuals', data);

export const deleteInfrastructureSystemManual = (id: number) =>
    del(`/api/ops/infrastructure/manuals/${id}`);

export const uploadCommonFile = (file: File) => {
    const formData = new FormData();
    formData.append('file', file);
    return post<CommonUploadResult>('/api/common/upload', formData);
};

// ===== Issue Tracking API =====

export const streamSolutionGeneration = async (
    params: { systemPrompt: string; userPrompt: string },
    onChunk: (content: string) => void,
    onDone: () => void,
    onError: (error: string) => void
) => {
    try {
        const token = localStorage.getItem('auth_token');
        const response = await fetch('/api/ai/chat/stream', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify(params)
        });

        if (!response.ok) {
            throw new Error('Failed to start generation');
        }

        const reader = response.body?.getReader();
        const decoder = new TextDecoder();

        if (!reader) return;

        let buffer = '';
        while (true) {
            const { done, value } = await reader.read();
            if (done) break;

            const chunk = decoder.decode(value, { stream: true });
            buffer += chunk;
            const lines = buffer.split('\n');
            buffer = lines.pop() || '';

            for (const line of lines) {
                const trimmedLine = line.trim();
                if (!trimmedLine) continue;
                if (trimmedLine.startsWith('data:')) {
                    const dataStr = trimmedLine.replace(/^data:\s?/, '').trim();
                    if (dataStr === '[DONE]') {
                        onDone();
                        break;
                    }
                    try {
                        const parsed = JSON.parse(dataStr);
                        if (parsed.content) {
                            onChunk(parsed.content);
                        } else if (parsed.error) {
                            onError(parsed.error);
                        }
                    } catch (e) {
                        console.error('JSON parse error', e);
                    }
                }
            }
        }
    } catch (error: any) {
        console.error('Generation failed:', error);
        onError(error.message || 'Generation failed');
    }
};

// ===== System API =====

export const getSystemList = (params?: { showAll?: boolean }) =>
    get<any[]>('/api/sys/system/list', params);

export const jumpSystem = (id: number | string) =>
    post<{ targetUrl: string }>(`/api/system/${id}/jump`);

// ===== Datasource API (Used in Forms) =====

export const getDatasourceConfig = () =>
    get<any>('/api/datasource/options');

export const getDatasourcePools = () =>
    get<DataSourcePoolApiModel[]>('/api/datasource/pool/options');

// ===== Quartz Task API =====

export interface ApiResponse<T> {
    success: boolean;
    code: number;
    msg: string;
    data: T;
}

export interface PageResult<T> {
    pageNum: number;
    pageSize: number;
    total: number;
    pages: number;
    list: T[];
}

export interface DataSourcePoolMemberApiModel {
    id?: number;
    poolId?: number;
    datasourceId: number;
    datasourceName?: string | null;
    typeName?: string | null;
    typeCode?: string | null;
    category?: string | null;
    enabled?: number;
    weight?: number;
    maxConcurrency?: number | null;
    sortNo?: number;
    remark?: string | null;
}

export interface DataSourcePoolApiModel {
    id?: number;
    name: string;
    poolType?: string | null;
    strategy?: string | null;
    status?: number;
    remark?: string | null;
    memberCount?: number;
    enabledMemberCount?: number;
    members?: DataSourcePoolMemberApiModel[];
}

export interface QuartzTaskApiModel {
    id?: number;
    taskName: string;
    taskBean?: string | null;
    taskParams?: string | null;
    taskCron: string;
    taskStatus?: number;
    remark?: string | null;
    updateTime?: string | null;
    createTime?: string | null;
    taskType?: number;
    url?: string | null;
    exePath?: string | null;
    dependId?: string | null;
    dataDependId?: string | null;
    controlDependId?: string | null;
    username?: string | null;
    password?: string | null;
    driver?: string | null;
    datasourceId?: number | null;
    datasourceName?: string | null;
    datasourcePoolId?: number | null;
    datasourcePoolName?: string | null;
    period?: number | null;
    taskSystem?: string | null;
    theme?: string | null;
    offset?: number | null;
    dataDate?: string | null;
    jobKey?: string | null;
    notificationCompleted?: string | null;
    notificationFailed?: string | null;
}

export interface QuartzTaskQueryParams {
    pageNum?: number;
    pageSize?: number;
    id?: number;
    taskName?: string;
    taskStatus?: number;
    taskType?: number;
    taskSystem?: string;
    theme?: string;
    remark?: string;
}

export interface QuartzTaskSavePayload {
    id?: number;
    taskName: string;
    taskBean?: string | null;
    taskParams?: string | null;
    taskCron: string;
    taskStatus?: number;
    remark?: string | null;
    dependId?: string | null;
    dataDependId?: string | null;
    controlDependId?: string | null;
    exePath?: string | null;
    url?: string | null;
    taskType: number;
    period?: number | null;
    username?: string | null;
    password?: string | null;
    driver?: string | null;
    datasourceId?: number | null;
    datasourcePoolId?: number | null;
    taskSystem?: string | null;
    theme?: string | null;
    offset?: number;
    notificationFailed?: string | null;
    notificationCompleted?: string | null;
}

export const queryQuartzTasks = (params: QuartzTaskQueryParams) =>
    post<ApiResponse<PageResult<QuartzTaskApiModel>>>('/api/quartz/task/query', params);

export type QuartzDependencyType = 'DATA' | 'CONTROL';

export const queryQuartzTaskDependencies = (taskId: number, dependencyType?: QuartzDependencyType) =>
    get<ApiResponse<QuartzTaskApiModel[]>>(
        `/api/quartz/task/dependencies/${taskId}`,
        dependencyType ? { dependencyType } : undefined
    );

export const saveOrUpdateQuartzTask = (payload: QuartzTaskSavePayload) =>
    post<ApiResponse<string>>('/api/quartz/task/saveOrUpdate', payload);

export const pauseQuartzTask = (taskId: number) =>
    get<ApiResponse<string>>(`/api/quartz/task/pause/${taskId}`);

export const resumeQuartzTask = (taskId: number) =>
    get<ApiResponse<string>>(`/api/quartz/task/resume/${taskId}`);

export const deleteQuartzTask = (taskId: number) =>
    get<ApiResponse<string>>(`/api/quartz/task/delete/${taskId}`);

export interface QuartzTaskStatusApiModel {
    id: number;
    planId: number;
    taskName?: string;
    dataDate: string;
    dependId?: string | null;
    dataDependId?: string | null;
    controlDependId?: string | null;
    taskType?: string | number | null;
    taskCron?: string | null;
    exePath?: string | null;
    datasourceId?: number | null;
    datasourceName?: string | null;
    datasourcePoolId?: number | null;
    datasourcePoolName?: string | null;
    executePoolId?: number | null;
    executePoolName?: string | null;
    executeDatasourceId?: number | null;
    executeDatasourceName?: string | null;
    period?: string | number | null;
    status?: string | number | null;
    beginTime?: string | null;
    endTime?: string | null;
    updateTime?: string | null;
    theme?: string | null;
    taskSystem?: string | null;
    remark?: string | null;
    msg?: string | null;
    jobKey?: string | null;
    createTime?: string | null;
}

export interface QuartzTaskStatusQueryParams {
    pageNum?: number;
    pageSize?: number;
    dataDate?: string;
    id?: number;
    ids?: string[];
    statusId?: number;
    taskName?: string;
    taskSystem?: string;
    theme?: string;
    remark?: string;
    status?: string;
    beginDate?: string;
}

export interface QuartzTaskStatusStatsApiModel {
    totalInstances?: number | null;
    waitingInstances?: number | null;
    runningInstances?: number | null;
    successInstances?: number | null;
    failedInstances?: number | null;
}

export interface QuartzDependencyImpactQueryParams {
    pageNum?: number;
    pageSize?: number;
    statusId?: number;
    planId: number;
    dataDate: string;
    keyword?: string;
    status?: string;
    impactedOnly?: boolean;
}

export interface QuartzDependencyImpactItemApiModel {
    taskId: number;
    taskName: string;
    taskSystem?: string | null;
    theme?: string | null;
    statusId?: number | null;
    dataDate?: string | null;
    status?: number | null;
    beginTime?: string | null;
    updateTime?: string | null;
    endTime?: string | null;
    createTime?: string | null;
    msg?: string | null;
    level: number;
    dependencyTypes?: string[] | null;
    missingTask?: boolean | null;
    impacted?: boolean | null;
    hasImpactedDescendant?: boolean | null;
    directChildCount?: number | null;
    descendantCount?: number | null;
}

export interface QuartzDependencyImpactPageApiModel {
    pageNum: number;
    pageSize: number;
    total: number;
    pages: number;
    list: QuartzDependencyImpactItemApiModel[];
    maxLevel?: number | null;
    waitingCount?: number | null;
    runningCount?: number | null;
    successCount?: number | null;
    failedCount?: number | null;
    missingCount?: number | null;
    impactedCount?: number | null;
}

export interface QuartzBlockingRootQueryParams {
    statusId?: number;
    planId: number;
    dataDate: string;
    status?: string;
    pageNum?: number;
    pageSize?: number;
}

export interface QuartzBlockingPathQueryParams {
    statusId?: number;
    planId: number;
    dataDate: string;
    rootTaskId: number;
    pageNum?: number;
    pageSize?: number;
}

export interface QuartzBlockingRootCauseApiModel {
    root: QuartzDependencyImpactItemApiModel;
    pathCount: number;
    level: number;
    representativePath: QuartzDependencyImpactItemApiModel[];
}

export interface QuartzBlockingRootPageApiModel {
    pageNum: number;
    pageSize: number;
    total: number;
    pages: number;
    list: QuartzBlockingRootCauseApiModel[];
    blockingNodeCount: number;
    maxLevel: number;
    failedRootCount: number;
    truncated?: boolean | null;
}

export interface QuartzBlockingPathPageApiModel {
    pageNum: number;
    pageSize: number;
    total: number;
    pages: number;
    list: QuartzDependencyImpactItemApiModel[][];
}

export interface QuartzTaskLogApiModel {
    id: number;
    taskId: number;
    taskName?: string | null;
    taskParams?: string | null;
    triggerType?: string | null;
    processStatus?: number | null;
    processDuration?: number | null;
    processLog?: string | null;
    createTime?: string | null;
    ipAddress?: string | null;
}

export const queryQuartzTaskStatus = (params: QuartzTaskStatusQueryParams) =>
    post<ApiResponse<PageResult<QuartzTaskStatusApiModel>>>('/api/quartz/task/status/query', params);

export const queryQuartzTaskStatusStats = (params: QuartzTaskStatusQueryParams) =>
    post<ApiResponse<QuartzTaskStatusStatsApiModel>>('/api/quartz/task/status/stats', params);

export const queryQuartzDependencyImpact = (params: QuartzDependencyImpactQueryParams) =>
    post<ApiResponse<QuartzDependencyImpactPageApiModel>>('/api/quartz/task/status/dependencyImpact', params);

export const queryQuartzBlockingRoots = (params: QuartzBlockingRootQueryParams) =>
    post<ApiResponse<QuartzBlockingRootPageApiModel>>('/api/quartz/task/status/blockingRoots', params);

export const queryQuartzBlockingPaths = (params: QuartzBlockingPathQueryParams) =>
    post<ApiResponse<QuartzBlockingPathPageApiModel>>('/api/quartz/task/status/blockingPaths', params);

export interface ExecutorPoolStats {
    activeCount: number;
    poolSize: number;
    maximumPoolSize: number;
    queueSize: number;
    queueCapacity: number;
    completedTaskCount: number;
    runningTaskKeys: string[];
    queuedTaskKeys: string[];
}

export const getExecutorPoolStats = () =>
    get<ApiResponse<ExecutorPoolStats>>('/api/quartz/executor/pool/stats', undefined, { timeoutMs: 6000 });

export interface QuartzMissedTaskQueryParams {
    pageNum?: number;
    pageSize?: number;
    startDate: string;
    endDate: string;
    taskName?: string;
    taskSystem?: string;
    theme?: string;
}

export interface QuartzMissedTaskApiModel {
    taskId: number;
    taskName?: string | null;
    taskSystem?: string | null;
    theme?: string | null;
    taskCron?: string | null;
    dependId?: string | null;
    taskType?: number | null;
    expectedDate: string;
    missedStatus?: string | null;
    waitingMinutes?: number | null;
    lastSuccessDate?: string | null;
    lastSuccessTime?: string | null;
}

export const queryQuartzMissedTasks = (params: QuartzMissedTaskQueryParams) =>
    post<ApiResponse<PageResult<QuartzMissedTaskApiModel>>>('/api/quartz/task/missed/query', params);

export const batchExecuteQuartzTaskStatus = (statusIds: number[], withDataDownstream: boolean = true) =>
    post<ApiResponse<string>>('/api/quartz/task/status/batchExecute', { statusIds, withDataDownstream });

export const batchForceStopQuartzTaskStatus = (statusIds: number[]) =>
    post<ApiResponse<string>>('/api/quartz/task/status/batchForceStop', { statusIds });

export const batchForcePassQuartzTaskStatus = (statusIds: number[]) =>
    post<ApiResponse<string>>('/api/quartz/task/status/batchForcePass', { statusIds });

export const triggerNowQuartzTask = (planId: number, dataDate: string) =>
    post<ApiResponse<string>>('/api/quartz/task/status/triggerNow', { planId, dataDate });

export const queryQuartzTaskLog = (taskId: number, pageNum: number = 1, pageSize: number = 200) =>
    post<ApiResponse<PageResult<QuartzTaskLogApiModel>>>('/api/quartz/task/queryLog', { taskId, pageNum, pageSize });

// ===== Docker Management API =====

export interface DockerContainer {
    id: string;
    name: string;
    image: string;
    status: 'running' | 'stopped' | 'restarting';
    ip: string;
    cpu: string;
    memory: string;
    uptime: string;
}

export interface DockerLog {
    timestamp: string;
    level: string;
    message: string;
}

export interface DockerContainerStats {
    containerId: string;
    containerName: string;
    cpuPercent: string;
    memUsage: string;
    memLimit: string;
    netIO: string;
    blockIO: string;
}

export interface DockerOperationResult {
    success: boolean;
    containerId: string;
    operation: string;
    message: string;
}

export const getDockerContainers = () =>
    get<DockerContainer[]>('/api/ops/docker/containers');

export const getDockerLogs = (containerId: string, params?: { lines?: number; tail?: boolean }) =>
    get<DockerLog[]>(`/api/ops/docker/containers/${containerId}/logs`, params || { lines: 100 });

export const getAllContainerStats = () =>
    get<DockerContainerStats[]>('/api/ops/docker/containers/stats');

export const startDockerContainer = (containerId: string) =>
    post<DockerOperationResult>(`/api/ops/docker/containers/${containerId}/start`);

export const stopDockerContainer = (containerId: string) =>
    post<DockerOperationResult>(`/api/ops/docker/containers/${containerId}/stop`);

export const restartDockerContainer = (containerId: string) =>
    post<DockerOperationResult>(`/api/ops/docker/containers/${containerId}/restart`);
