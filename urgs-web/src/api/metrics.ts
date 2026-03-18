import { get } from '@/utils/request';

export interface MetricTypeVO {
    typeCode: string;
    typeName: string;
    unit: string;
    color: string;
    sortOrder: number;
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

export const fetchMetricTypes = async (systemId: string): Promise<MetricTypeVO[]> => {
    try {
        const data = await get<MetricTypeVO[]>('/api/metrics/types', { systemId });
        return data || [];
    } catch (error) {
        console.error('Error fetching metric types:', error);
        return [];
    }
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
