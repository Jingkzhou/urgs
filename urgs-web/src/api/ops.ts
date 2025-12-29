import { get, post, put, del } from '@/utils/request';

// ===== Infrastructure Asset API =====

export interface InfrastructureUser {
    id?: number;
    username: string;
    password?: string;
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
    role?: string;
    appSystemId?: number;
    envId?: number;
    envType?: string;
    users?: InfrastructureUser[];
    status: 'active' | 'maintenance' | 'offline';
    description?: string;
    createdAt?: string;
    updatedAt?: string;
}

export const getInfrastructureAssets = (params?: { appSystemId?: number; envId?: number; envType?: string }) =>
    get<InfrastructureAsset[]>('/api/version/infrastructure', params || {});

export const createInfrastructureAsset = (data: InfrastructureAsset) =>
    post<InfrastructureAsset>('/api/version/infrastructure', data);

export const updateInfrastructureAsset = (id: number, data: InfrastructureAsset) =>
    put<InfrastructureAsset>(`/api/version/infrastructure/${id}`, data);

export const deleteInfrastructureAsset = (id: number) =>
    del(`/api/version/infrastructure/${id}`);

export const exportInfrastructureAssets = () =>
    get<Blob>('/api/version/infrastructure/export', undefined, { isBlob: true });

export const importInfrastructureAssets = (file: File) => {
    const formData = new FormData();
    formData.append('file', file);
    return post<void>('/api/version/infrastructure/import', formData);
};
