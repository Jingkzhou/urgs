import { get, post, put, del } from '@/utils/request';

// ==================== 类型定义 ====================

/** 文件夹 */
export interface KnowledgeFolder {
    id: number;
    userId: number;
    parentId: number | null;
    name: string;
    sortOrder: number;
    createTime: string;
    updateTime: string;
}

/** 文件夹树节点 */
export interface FolderTreeNode {
    id: number;
    name: string;
    parentId: number | null;
    sortOrder: number;
    children: FolderTreeNode[];
}

/** 文档 */
export interface KnowledgeDocument {
    id: number;
    userId: number;
    folderId: number | null;
    title: string;
    docType: 'markdown' | 'file';
    content: string | null;
    fileUrl: string | null;
    fileName: string | null;
    fileSize: number | null;
    isFavorite: number;
    viewCount: number;
    createTime: string;
    updateTime: string;
}

/** 标签 */
export interface KnowledgeTag {
    id: number;
    userId: number;
    name: string;
    color: string;
    createTime: string;
}

/** 文档详情 */
export interface DocumentDetail {
    document: KnowledgeDocument;
    tags: KnowledgeTag[];
}

/** 分页结果 */
export interface PageResult<T> {
    records: T[];
    total: number;
    size: number;
    current: number;
    pages: number;
}

// ==================== 文件夹 API ====================

/** 获取文件夹树 */
export const getFolderTree = () =>
    get<FolderTreeNode[]>('/api/wiki/folders');

/** 创建文件夹 */
export const createFolder = (data: { name: string; parentId?: number }) =>
    post<KnowledgeFolder>('/api/wiki/folders', data);

/** 更新文件夹 */
export const updateFolder = (id: number, data: { name?: string; parentId?: number; sortOrder?: number }) =>
    put<KnowledgeFolder>(`/api/wiki/folders/${id}`, data);

/** 删除文件夹 */
export const deleteFolder = (id: number) =>
    del(`/api/wiki/folders/${id}`);

// ==================== 文档 API ====================

/** 分页查询文档 */
export const listDocuments = (params: {
    folderId?: number;
    keyword?: string;
    docType?: string;
    favorite?: boolean;
    page?: number;
    size?: number;
}) => get<PageResult<KnowledgeDocument>>('/api/wiki/documents', params);

/** 获取文档详情 */
export const getDocument = (id: number) =>
    get<DocumentDetail>(`/api/wiki/documents/${id}`);

/** 创建文档 */
export const createDocument = (data: {
    folderId?: number;
    title: string;
    docType: 'markdown' | 'file';
    content?: string;
    fileUrl?: string;
    fileName?: string;
    fileSize?: number;
    tagIds?: number[];
}) => post<KnowledgeDocument>('/api/wiki/documents', data);

/** 更新文档 */
export const updateDocument = (id: number, data: {
    folderId?: number;
    title?: string;
    content?: string;
    fileUrl?: string;
    fileName?: string;
    fileSize?: number;
    tagIds?: number[];
}) => put<KnowledgeDocument>(`/api/wiki/documents/${id}`, data);

/** 删除文档 */
export const deleteDocument = (id: number) =>
    del(`/api/wiki/documents/${id}`);

/** 切换收藏状态 */
export const toggleFavorite = (id: number) =>
    put<{ favorite: boolean }>(`/api/wiki/documents/${id}/favorite`);

/** 获取最近访问的文档 */
export const getRecentDocuments = (limit?: number) =>
    get<KnowledgeDocument[]>('/api/wiki/documents/recent', { limit });

/** 获取收藏的文档 */
export const getFavoriteDocuments = () =>
    get<KnowledgeDocument[]>('/api/wiki/documents/favorites');

// ==================== 标签 API ====================

/** 获取所有标签 */
export const listTags = () =>
    get<KnowledgeTag[]>('/api/wiki/tags');

/** 创建标签 */
export const createTag = (data: { name: string; color?: string }) =>
    post<KnowledgeTag>('/api/wiki/tags', data);

/** 更新标签 */
export const updateTag = (id: number, data: { name?: string; color?: string }) =>
    put<KnowledgeTag>(`/api/wiki/tags/${id}`, data);

/** 删除标签 */
export const deleteTag = (id: number) =>
    del(`/api/wiki/tags/${id}`);

/** 获取文档的标签 */
export const getDocumentTags = (documentId: number) =>
    get<KnowledgeTag[]>(`/api/wiki/tags/document/${documentId}`);
