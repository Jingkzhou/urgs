import { get, post } from '@/utils/request';

/**
 * Get lineage graph data (仅 DERIVES_TO 关系)
 * @param tableName name of the table to search
 * @param depth search depth (default -1 for full lineage)
 */
export const getLineageGraph = (tableName: string, columnName?: string, depth: number = -1) => {
    const params: Record<string, string> = {
        tableName,
        depth: String(depth),
    };
    if (columnName) {
        params.columnName = columnName;
    }
    return get('/api/metadata/lineage/graph', params);
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
export const searchTables = (keyword: string, page: number = 1, size: number = 20) => {
    return get('/api/metadata/lineage/search', {
        keyword,
        page: String(page),
        size: String(size)
    });
};


/**
 * 导出血缘 Excel
 */
export const exportLineage = async (tableName: string, columnName?: string) => {
    const token = localStorage.getItem('auth_token');
    const headers: HeadersInit = {};
    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }

    const params = new URLSearchParams({ tableName });
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

// ============= 血缘引擎控制 API =============

export const getLineageEngineStatus = () => {
    return get('/api/metadata/lineage/engine/status');
};

export const startLineageEngine = () => {
    return post('/api/metadata/lineage/engine/start', {});
};

export const restartLineageEngine = () => {
    return post('/api/metadata/lineage/engine/restart', {});
};

export const stopLineageEngine = () => {
    return post('/api/metadata/lineage/engine/stop', {});
};

export const getLineageEngineLogs = (lines: number = 200) => {
    return get('/api/metadata/lineage/engine/logs', { lines: String(lines) });
};
