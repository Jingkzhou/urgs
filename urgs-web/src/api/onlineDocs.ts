import { del, get, post, put } from '@/utils/request';

export interface OnlineDocument {
    id: number;
    userId: number;
    ownerName?: string;
    title: string;
    fileUrl: string;
    fileName: string;
    fileSize: number | null;
    favorite?: boolean;
    spaceType?: 'personal' | 'shared';
    createTime: string;
    updateTime: string;
    shared?: boolean;
    canManagePermissions?: boolean;
}

export interface OnlineDocumentPage<T> {
    records: T[];
    total: number;
    size: number;
    current: number;
    pages: number;
}

export interface UploadResult {
    url: string;
    name: string;
}

export interface OnlyOfficeEditorConfig {
    documentServerUrl: string;
    config: Record<string, unknown>;
}

export interface OnlineDocumentPermission {
    userId: number;
    userName: string;
    empId?: string;
    createTime: string;
}

export interface OnlineDocumentPermissionUser {
    id: string | number;
    name: string;
    empId?: string;
}

export interface OnlineDocumentPermissionGroup {
    id: number;
    name: string;
    description?: string;
    memberCount: number;
    members: OnlineDocumentPermissionUser[];
}

export const listOnlineDocuments = (params: {
    keyword?: string;
    fileType?: string;
    page?: number;
    size?: number;
}) => get<OnlineDocumentPage<OnlineDocument>>('/api/online-documents', params);

export const listFavoriteDocuments = (params: {
    keyword?: string;
    fileType?: string;
    page?: number;
    size?: number;
}) => get<OnlineDocumentPage<OnlineDocument>>('/api/online-documents/favorite', params);

export const listSpaceDocuments = (params: {
    spaceType?: 'personal' | 'shared' | 'all';
    keyword?: string;
    fileType?: string;
    page?: number;
    size?: number;
}) => get<OnlineDocumentPage<OnlineDocument>>('/api/online-documents/space', params);

export const toggleFavorite = (id: number) => post<OnlineDocument>(`/api/online-documents/${id}/favorite`, {});

export const setSpaceType = (id: number, spaceType: 'personal' | 'shared') =>
    put<OnlineDocument>(`/api/online-documents/${id}/space`, { spaceType });

export const createOnlineDocument = (data: {
    title: string;
    fileUrl: string;
    fileName: string;
    fileSize?: number;
}) => post<OnlineDocument>('/api/online-documents', data);

export const createBlankOnlineDocument = (data: {
    title?: string;
    documentType: 'word' | 'cell';
}) => post<OnlineDocument>('/api/online-documents/blank', data);

export const updateOnlineDocument = (id: number, data: {
    title?: string;
    fileName?: string;
}) => put<OnlineDocument>(`/api/online-documents/${id}`, data);

export const deleteOnlineDocument = (id: number) =>
    del(`/api/online-documents/${id}`);

export const uploadOnlineDocumentFile = (file: File) => {
    const formData = new FormData();
    formData.append('file', file);
    return post<UploadResult>('/api/common/upload', formData);
};

export const getOnlineDocumentOnlyOfficeConfig = (id: number) =>
    get<OnlyOfficeEditorConfig>(`/api/online-documents/${id}/onlyoffice/config`);

export const listOnlineDocumentPermissions = (id: number) =>
    get<OnlineDocumentPermission[]>(`/api/online-documents/${id}/permissions`);

export const searchOnlineDocumentPermissionUsers = (keyword: string = '') =>
    get<OnlineDocumentPermissionUser[]>('/api/online-documents/permission-users', { keyword });

export const listOnlineDocumentPermissionGroups = () =>
    get<OnlineDocumentPermissionGroup[]>('/api/online-documents/permission-groups');

export const createOnlineDocumentPermissionGroup = (data: {
    name: string;
    description?: string;
    userIds: number[];
}) => post<OnlineDocumentPermissionGroup>('/api/online-documents/permission-groups', data);

export const updateOnlineDocumentPermissionGroup = (id: number, data: {
    name: string;
    description?: string;
    userIds: number[];
}) => put<OnlineDocumentPermissionGroup>(`/api/online-documents/permission-groups/${id}`, data);

export const deleteOnlineDocumentPermissionGroup = (id: number) =>
    del(`/api/online-documents/permission-groups/${id}`);

export const saveOnlineDocumentPermissions = (id: number, userIds: number[]) =>
    put<OnlineDocumentPermission[]>(`/api/online-documents/${id}/permissions`, { userIds });
