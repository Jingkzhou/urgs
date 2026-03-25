import { get, post } from '@/utils/request';

export interface SqlExecuteRequest {
    sql: string;
    dataSourceId?: number | null;
    page?: number;
    pageSize?: number;
}

export interface SqlExecuteResponse {
    success: boolean;
    columns?: string[];
    data?: Record<string, any>[];
    error?: string;
    executionTimeMs?: number;
    page?: number;
    pageSize?: number;
    totalRows?: number;
}

export interface ColumnMeta {
    columnName: string;
    dataType: string;
    comment: string;
}

export interface TableMeta {
    tableName: string;
    columns: ColumnMeta[];
}

export interface SchemaMetadataResponse {
    tables: TableMeta[];
}

export const executeSql = (params: SqlExecuteRequest) =>
    post<SqlExecuteResponse>('/api/sql/execute', params);

export const fetchSchemaMetadata = (dataSourceId?: number) =>
    get<SchemaMetadataResponse>('/api/sql/schema', dataSourceId ? { dataSourceId } : undefined);
