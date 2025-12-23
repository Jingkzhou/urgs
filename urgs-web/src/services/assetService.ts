import { get, post } from '@/utils/request';

export interface RegulatoryAsset {
    id?: number;
    name: string;
    code: string;
    systemCode?: string;
    parentId?: number;
    type: string;
    description: string;
    owner: string;
    status: number;
    createTime?: string;
    updateTime?: string;
}

const API_BASE = '/api/metadata/asset';

export const assetService = {
    list: (keyword?: string, systemCode?: string, parentId?: number, type?: string) => {
        const params: Record<string, string> = {};
        if (keyword) params.keyword = keyword;
        if (systemCode) params.systemCode = systemCode;
        if (parentId !== undefined) params.parentId = parentId.toString();
        if (type) params.type = type;
        return get<RegulatoryAsset[]>(`${API_BASE}/list`, params);
    },

    add: (asset: RegulatoryAsset) => {
        return post<boolean>(`${API_BASE}/add`, asset);
    },

    update: (asset: RegulatoryAsset) => {
        return post<boolean>(`${API_BASE}/update`, asset);
    },

    delete: (id: number) => {
        return post<boolean>(`${API_BASE}/delete/${id}`);
    }
};
