import { del, get, post, put } from '@/utils/request';

export interface LineageSearchTableItem {
    ownerName: string;
    tableName: string;
    qualifiedName: string;
    columns: string[];
}

export interface LineageSearchOwnerGroup {
    ownerName: string;
    tableCount: number;
    tables: LineageSearchTableItem[];
}

export interface LineageSearchResponse {
    total: number;
    selectedOwnerTotal?: number;
    selectedOwner?: string;
    totalOwners: number;
    list: LineageSearchTableItem[];
    groupedList: LineageSearchOwnerGroup[];
}

export type LineageGraphDirection = 'upstream' | 'downstream' | 'both';
export type LineageGraphRelationLevel = 'table' | 'column';

export interface LineageGraphOptions {
    depth?: number;
    qualifiedName?: string;
    direction?: LineageGraphDirection;
    limit?: number;
    relationLevel?: LineageGraphRelationLevel;
}

export interface LineageGraphResponse {
    nodes: any[];
    edges: any[];
    truncated?: boolean;
    totalNodes?: number;
    totalEdges?: number;
    limit?: number;
    depth?: number;
    direction?: LineageGraphDirection;
    relationLevel?: LineageGraphRelationLevel;
}

/**
 * Get lineage graph data (仅 DERIVES_TO 关系)
 * @param tableName name of the table to search
 * @param depth search depth (default 2 for initial graph)
 */
export const getLineageGraph = (
    tableName: string,
    columnName?: string,
    optionsOrDepth: LineageGraphOptions | number = {},
    qualifiedName?: string
) => {
    const options: LineageGraphOptions = typeof optionsOrDepth === 'number'
        ? { depth: optionsOrDepth, qualifiedName }
        : optionsOrDepth;
    const params: Record<string, string> = {
        tableName,
        depth: String(options.depth ?? 2),
        direction: options.direction || 'both',
        limit: String(options.limit ?? 1000),
        relationLevel: options.relationLevel || (columnName ? 'column' : 'table'),
    };
    if (options.qualifiedName) {
        params.qualifiedName = options.qualifiedName;
    }
    if (columnName) {
        params.columnName = columnName;
    }
    return get('/api/metadata/lineage/graph', params) as Promise<LineageGraphResponse>;
};

/**
 * 影响分析 - 获取所有类型的下游依赖 (DERIVES_TO, FILTERS, JOINS 等)
 * @param tableName 表名
 * @param columnName 字段名
 * @param version 可选，指定版本
 * @param depth 追溯深度
 * @param types 可选，指定关系类型列表
 */
export const getImpactAnalysis = (
    tableName: string,
    columnName: string,
    version?: string,
    depth: number = 5,
    types?: string[]
) => {
    const params: Record<string, string> = {
        tableName,
        columnName,
        depth: String(depth),
    };
    if (version) params.version = version;
    if (types && types.length > 0) params.types = types.join(',');

    return get('/api/metadata/lineage/impact', params);
};

/**
 * 血缘追溯 - 只返回直接数据流 (DERIVES_TO)
 * @param tableName 表名
 * @param columnName 字段名
 * @param direction 方向: upstream 或 downstream
 * @param version 可选，指定版本
 * @param depth 追溯深度
 */
export const getLineageTrace = (
    tableName: string,
    columnName: string,
    direction: 'upstream' | 'downstream' = 'upstream',
    version?: string,
    depth: number = 5
) => {
    const params: Record<string, string> = {
        tableName,
        columnName,
        direction,
        depth: String(depth),
    };
    if (version) params.version = version;

    return get('/api/metadata/lineage/trace', params);
};

/**
 * 获取所有血缘版本列表
 */
export const getLineageVersions = () => {
    return get('/api/metadata/lineage/versions');
};

/**
 * Search tables by keyword with pagination
 * @param keyword search keyword
 * @param page page number (default 1)
 * @param size page size (default 20)
 */
export const searchTables = (keyword: string, page: number = 1, size: number = 20, ownerName?: string) => {
    const params: Record<string, string> = {
        keyword,
        page: String(page),
        size: String(size)
    };
    if (ownerName) {
        params.ownerName = ownerName;
    }
    return get('/api/metadata/lineage/search', {
        ...params
    }) as Promise<LineageSearchResponse>;
};


/**
 * 导出血缘 Excel
 */
export const exportLineage = async (tableName: string, columnName?: string, qualifiedName?: string) => {
    const token = localStorage.getItem('auth_token');
    const headers: HeadersInit = {};
    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }

    const params = new URLSearchParams({ tableName });
    if (qualifiedName) {
        params.append('qualifiedName', qualifiedName);
    }
    if (columnName) {
        params.append('columnName', columnName);
    }

    const response = await fetch(`/api/metadata/lineage/export?${params.toString()}`, {
        method: 'GET',
        headers
    });

    if (!response.ok) {
        throw new Error('Export failed');
    }
    return response.blob();
};

// ============= 血缘报告 API =============

export interface LineageReport {
    id?: number;
    tableName: string;
    columnName: string;
    reportContent: string;
    upstreamCount?: number;
    downstreamCount?: number;
    aiModel?: string;
    status?: string;
    createBy?: string;
    createTime?: string;
}

/**
 * 生成血缘报告 SSE URL
 * 注意：EventSource 无法携带 Authorization header，需要通过 URL 参数传递 token
 */
export const getGenerateReportUrl = (tableName: string, columnName: string, depth: number = 5) => {
    const token = localStorage.getItem('auth_token') || '';
    const params = new URLSearchParams({
        tableName,
        columnName,
        depth: String(depth),
        token  // 传递 token 用于认证
    });
    return `/api/lineage/report/generate?${params.toString()}`;
};

/**
 * 保存报告
 */
export const saveLineageReport = (report: LineageReport) => {
    return post('/api/lineage/report/save', report);
};

/**
 * 获取历史报告列表
 */
export const getReportHistory = (tableName: string, columnName?: string) => {
    const params: Record<string, string> = { tableName };
    if (columnName) params.columnName = columnName;
    return get('/api/lineage/report/history', params);
};

/**
 * 获取报告详情
 */
export const getReportById = (id: number) => {
    return get(`/api/lineage/report/${id}`);
};

/**
 * 删除报告
 */
export const deleteReport = (id: number) => {
    return fetch(`/api/lineage/report/${id}`, { method: 'DELETE' }).then(r => r.json());
};

/**
 * 导出报告 PDF URL
 */
export const getExportPdfUrl = (id: number) => `/api/lineage/report/export/pdf/${id}`;

/**
 * 导出报告 Word URL
 */
export const getExportWordUrl = (id: number) => `/api/lineage/report/export/word/${id}`;

// ============= 血缘事后校验 API =============

export interface LineageAnalysisRecordItem {
    id: string;
    repoId?: number;
    ref?: string;
    commitSha?: string;
    paths?: string[];
    versionId?: string;
    defaultUser?: string;
    language?: string;
    physicalDataSourceId?: number;
    metadataOwner?: string;
    metadataPackPath?: string;
    metadataPackHash?: string;
    metadataPackStatus?: string;
    metadataTableCount?: number;
    metadataFieldCount?: number;
    metadataGeneratedAt?: string;
    aiReviewEnabled?: boolean;
    status?: string;
    error?: string;
    startTime?: string;
    endTime?: string;
    createTime?: string;
    updateTime?: string;
}

export interface LineageReviewTask {
    id: number;
    analysisRecordId: string;
    repoId?: number;
    versionId?: string;
    ref?: string;
    systemKey?: string;
    pathPrefix?: string;
    taskName?: string;
    status?: string;
    objectCount?: number;
    processedCount?: number;
    issueCount?: number;
    failedCount?: number;
    aiCallCount?: number;
    cacheHitCount?: number;
    batchCount?: number;
    tokenBudget?: number;
    consumedTokens?: number;
    lastError?: string;
    startedAt?: string;
    finishedAt?: string;
    createTime?: string;
    updateTime?: string;
    pendingIssueCount?: number;
    confirmedIssueCount?: number;
    falsePositiveIssueCount?: number;
    resolvedIssueCount?: number;
    ignoredIssueCount?: number;
    reviewedIssueCount?: number;
    totalReviewIssueCount?: number;
    reviewCompletionRate?: number;
    executionProgressRate?: number;
}

export interface LineageReviewIssue {
    id: number;
    taskId: number;
    analysisRecordId: string;
    repoId?: number;
    versionId?: string;
    systemKey?: string;
    pathPrefix?: string;
    tableName?: string;
    columnName?: string;
    objectType?: string;
    issueType: string;
    severity: string;
    confidence?: number;
    verdict?: string;
    reason?: string;
    ruleHits?: string[];
    suggestedSources?: string[];
    evidenceRefs?: string[];
    graphSnapshot?: Record<string, unknown>;
    fingerprint?: string;
    cacheKey?: string;
    reviewStatus?: string;
    reviewerId?: number;
    reviewerNote?: string;
    confirmedProblemType?: string;
    confirmedProblemDescription?: string;
    reviewTime?: string;
    createTime?: string;
    updateTime?: string;
}

export interface LineageReviewMemory {
    id: number;
    title: string;
    status: string;
    content: string;
    targetPattern?: string;
    issueType?: string;
    ruleHits?: string[];
    sourceIssueId?: number;
    sourceTaskId?: number;
    analysisRecordId?: string;
    repoId?: number;
    versionId?: string;
    systemKey?: string;
    pathPrefix?: string;
    createdBy?: number;
    updatedBy?: number;
    createTime?: string;
    updateTime?: string;
}

export const getLineageReviewRecords = () =>
    get<LineageAnalysisRecordItem[]>('/api/metadata/lineage/review/records');

export const getLineageReviewTasks = (params?: { analysisRecordId?: string; status?: string }) =>
    get<LineageReviewTask[]>('/api/metadata/lineage/review/tasks', params || {});

export const triggerLineageReview = (data: { analysisRecordId: string; forceRerun?: boolean }) =>
    post<{ success: boolean; message: string }>('/api/metadata/lineage/review/tasks/trigger', data);

export const clearLineageReviewHistory = () =>
    del<{ success: boolean; message: string; taskCount: number; issueCount: number; cacheCount: number }>(
        '/api/metadata/lineage/review/history'
    );

export const getLineageReviewTask = (taskId: number) =>
    get<LineageReviewTask>(`/api/metadata/lineage/review/tasks/${taskId}`);

export const getLineageReviewTaskSqlPreview = (taskId: number) =>
    get<Array<{ snippet: string; sourceFiles: string[]; relationCount: number }>>(
        `/api/metadata/lineage/review/tasks/${taskId}/sql-preview`
    );

export const getLineageReviewIssues = (params?: {
    taskId?: number;
    severity?: string;
    issueType?: string;
    reviewStatus?: string;
}) =>
    get<LineageReviewIssue[]>('/api/metadata/lineage/review/issues', params || {});

export const getLineageReviewIssue = (issueId: number) =>
    get<LineageReviewIssue>(`/api/metadata/lineage/review/issues/${issueId}`);

export const decideLineageReviewIssue = (
    issueId: number,
    data: {
        reviewStatus: string;
        reviewerNote?: string;
        falsePositiveReason?: string;
        confirmedProblemType?: string;
        confirmedProblemDescription?: string;
    }
) =>
    put<LineageReviewIssue>(`/api/metadata/lineage/review/issues/${issueId}/decision`, data);

export const getLineageReviewMemories = (params?: { status?: string }) =>
    get<LineageReviewMemory[]>('/api/metadata/lineage/review/memories', params || {});

export const updateLineageReviewMemory = (
    memoryId: number,
    data: { title?: string; content?: string; status?: string }
) =>
    put<LineageReviewMemory>(`/api/metadata/lineage/review/memories/${memoryId}`, data);

export const getLineageReviewExportUrl = (taskId: number) =>
    `/api/metadata/lineage/review/export?taskId=${taskId}`;

export const downloadLineageReviewReportMarkdown = (taskId: number) =>
    get<Blob>('/api/metadata/lineage/review/export', { taskId }, { isBlob: true });

// ============= 血缘引擎控制 API =============

export const getLineageEngineStatus = () => {
    return get('/api/metadata/lineage/engine/status');
};

export interface LineageEngineStartByGitParams {
    sourceType: 'git';
    repoId: number;
    ref: string;
    paths: string[];
    physicalDataSourceId?: number;
    user?: string;
    language?: string;
    enableAiReview?: boolean;
}

export interface LineageEngineStartByUploadParams {
    sourceType: 'upload';
    files: File[];
    physicalDataSourceId?: number;
    user?: string;
    language?: string;
    enableAiReview?: boolean;
}

export type LineageEngineStartParams = LineageEngineStartByGitParams | LineageEngineStartByUploadParams;

export interface LineagePhysicalDataSource {
    id: number;
    name: string;
    metaId: number;
    status: number;
    metaName?: string;
    metaCategory?: string;
    metaCode?: string;
}

interface LineageDataSourceMeta {
    id: number;
    code: string;
    name: string;
    category: string;
}

interface LineageDataSourceConfig {
    id: number;
    name: string;
    metaId: number;
    status: number;
}

export const getLineagePhysicalDataSources = async () => {
    const [metaData, configData] = await Promise.all([
        get<LineageDataSourceMeta[]>('/api/datasource/meta'),
        get<LineageDataSourceConfig[]>('/api/datasource/config'),
    ]);

    const metas = Array.isArray(metaData) ? metaData : [];
    const configs = Array.isArray(configData) ? configData : [];
    const metaMap = new Map<number, LineageDataSourceMeta>();
    metas.forEach((meta) => metaMap.set(meta.id, meta));

    return configs
        .map((config) => {
            const meta = metaMap.get(config.metaId);
            return {
                ...config,
                metaName: meta?.name,
                metaCategory: meta?.category,
                metaCode: meta?.code,
            };
        })
        .filter((config) => ['RDBMS', 'BIG DATA'].includes((config.metaCategory || '').toUpperCase()));
};

export const getLineagePhysicalSchemas = (dataSourceId: number) =>
    get<string[]>('/api/metadata/model-table/owners', { dataSourceId: String(dataSourceId) });

export const startLineageEngine = (params: LineageEngineStartParams) => {
    const startEngineOptions = { timeoutMs: 90000 };

    if (params.sourceType === 'upload') {
        const formData = new FormData();
        params.files.forEach(file => {
            formData.append('files', file);
        });
        if (params.user) {
            formData.append('user', params.user);
        }
        if (params.language) {
            formData.append('language', params.language);
        }
        if (params.physicalDataSourceId) {
            formData.append('physicalDataSourceId', String(params.physicalDataSourceId));
        }
        formData.append('enableAiReview', String(params.enableAiReview !== false));
        return post('/api/metadata/lineage/engine/start', formData, startEngineOptions);
    }
    return post('/api/metadata/lineage/engine/start', params, startEngineOptions);
};

export const restartLineageEngine = () => {
    return post('/api/metadata/lineage/engine/restart', {});
};

export const stopLineageEngine = () => {
    return post('/api/metadata/lineage/engine/stop', {});
};

export const getLineageEngineLogs = (lines: number = 200, recordId?: string) => {
    return get('/api/metadata/lineage/engine/logs', {
        lines: String(lines),
        ...(recordId ? { recordId } : {}),
    });
};

export const checkLineageVersionConsistency = (repoId: number, ref?: string) => {
    return get('/api/metadata/lineage/engine/version-check', { repoId: String(repoId), ref: ref || '' });
};

export const clearLineageDatabase = () => {
    return post('/api/metadata/lineage/engine/clear-database', {});
};
