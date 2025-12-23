import { get } from '@/utils/request';

export interface SsoConfig {
    id: number;
    name: string;
    protocol: string;
    clientId: string;
    status: string;
}

export const systemService = {
    list: () => get<SsoConfig[]>('/api/sys/system/list'),
};
