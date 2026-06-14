import { del, get, post, put } from '@/utils/request';

export interface OnlineDocument {
    id: number;
    userId: number;
    title: string;
    fileUrl: string;
    fileName: string;
    fileSize: number | null;
    createTime: string;
    updateTime: string;
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

export const listOnlineDocuments = (params: {
    keyword?: string;
    fileType?: string;
    page?: number;
    size?: number;
}) => get<OnlineDocumentPage<OnlineDocument>>('/api/online-documents', params);

export const createOnlineDocument = (data: {
    title: string;
    fileUrl: string;
    fileName: string;
    fileSize?: number;
}) => post<OnlineDocument>('/api/online-documents', data);

export const createBlankOnlineDocument = (data: {
    title?: string;
    documentType: 'word' | 'cell' | 'slide';
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
