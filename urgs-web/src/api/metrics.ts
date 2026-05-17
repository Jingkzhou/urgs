import { del, get, post, put } from '@/utils/request';

export type MetricChartType = 'line' | 'area' | 'bar' | 'pie';

export interface MetricTypeVO {
    id?: number;
    systemId?: string;
    typeCode: string;
    typeName: string;
    unit: string;
    color: string;
    defaultChartType?: MetricChartType;
    supportedChartTypes?: string;
    sortOrder: number;
    status?: number;
}

export interface MetricTrendVO {
    timeLabel: string;
    avgValue: number;
    maxValue: number;
    minValue: number;
}

export interface MetricSystemVO {
    clientId: string;
    name: string;
}

export const fetchMetricSystems = async (): Promise<MetricSystemVO[]> => {
    try {
        const data = await get<any[]>('/api/metrics/systems');
        return (data || []).map((s: any) => ({ clientId: s.clientId, name: s.name }));
    } catch (error) {
        console.error('Error fetching metric systems:', error);
        return [];
    }
};

export const fetchMetricConfigSystems = async (): Promise<MetricSystemVO[]> => {
    const data = await get<any[]>('/api/metrics/admin/systems');
    return (data || []).map((s: any) => ({ clientId: s.clientId, name: s.name }));
};

export const fetchMetricTypes = async (systemId: string): Promise<MetricTypeVO[]> => {
    try {
        const data = await get<MetricTypeVO[]>('/api/metrics/types', { systemId });
        return data || [];
    } catch (error) {
        console.error('Error fetching metric types:', error);
        return [];
    }
};

export const fetchMetricTypeConfigs = async (systemId?: string): Promise<MetricTypeVO[]> => {
    return get<MetricTypeVO[]>('/api/metrics/admin/types', { systemId });
};

export const createMetricTypeConfig = async (payload: MetricTypeVO): Promise<MetricTypeVO> => {
    return post<MetricTypeVO>('/api/metrics/admin/types', payload);
};

export const updateMetricTypeConfig = async (id: number, payload: MetricTypeVO): Promise<MetricTypeVO> => {
    return put<MetricTypeVO>(`/api/metrics/admin/types/${id}`, payload);
};

export const deleteMetricTypeConfig = async (id: number): Promise<void> => {
    return del<void>(`/api/metrics/admin/types/${id}`);
};

export const fetchMetricTrend = async (params: {
    systemId: string;
    typeCode: string;
    startTime: string;
    endTime: string;
    granularity?: string;
}): Promise<MetricTrendVO[]> => {
    try {
        const data = await get<MetricTrendVO[]>('/api/metrics/trend', params);
        return data || [];
    } catch (error) {
        console.error('Error fetching metric trend:', error);
        return [];
    }
};
