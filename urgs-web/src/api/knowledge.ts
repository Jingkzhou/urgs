import { get, post, put, del } from '@/utils/request';

// ==================== 类型定义 ====================

/** 文件夹 */
export interface KnowledgeFolder {
    id: number;
    userId: number;
    parentId: number | null;
    name: string;
    scope: 'private' | 'shared';
    sortOrder: number;
    createTime: string;
    updateTime: string;
}

/** 文件夹 tree 节点 */
export interface FolderTreeNode {
    id: number;
    name: string;
    parentId: number | null;
    sortOrder: number;
    children: FolderTreeNode[];
}

/** 文档 (现仅作为附件文件) */
export interface KnowledgeDocument {
    id: number;
    userId: number;
    folderId: number | null;
    title: string;
    scope: 'private' | 'shared';
    sourceDocId: number | null;
    fileUrl: string | null;
    fileName: string | null;
    fileSize: number | null;
    isFavorite: number;
    viewCount: number;
    createTime: string;
    updateTime: string;
    /** 前端填充的标签列表 */
    tags?: KnowledgeTag[];
}

/** 标签 */
export interface KnowledgeTag {
    id: number;
    userId: number;
    name: string;
    color: string;
    createTime: string;
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
export const getFolderTree = (scope?: 'private' | 'shared') =>
    get<FolderTreeNode[]>('/api/wiki/folders', scope ? { scope } : undefined);

/** 创建文件夹 */
export const createFolder = (data: { name: string; parentId?: number; scope?: string }) =>
    post<KnowledgeFolder>('/api/wiki/folders', data);

/** 更新文件夹 */
export const updateFolder = (id: number, data: { name?: string; parentId?: number; sortOrder?: number }) =>
    put<KnowledgeFolder>(`/api/wiki/folders/${id}`, data);

/** 删除文件夹 */
export const deleteFolder = (id: number) =>
    del(`/api/wiki/folders/${id}`);

/** 确保文件夹存在（查找或创建） */
export const ensureFolder = (data: { name: string; parentId?: number | null; scope?: string }) =>
    post<KnowledgeFolder>('/api/wiki/folders/ensure', data);

// ==================== 文档 API ====================

/** 分页查询文档 */
export const listDocuments = (params: {
    folderId?: number;
    keyword?: string;
    favorite?: boolean;
    tagId?: number;
    page?: number;
    size?: number;
    scope?: string;
}) => get<PageResult<KnowledgeDocument>>('/api/wiki/documents', params);

/** 创建文档（附件上传后调用） */
export const createDocument = (data: {
    folderId?: number;
    title: string;
    scope?: string;
    fileUrl: string;
    fileName: string;
    fileSize: number;
    tagIds?: number[];
}) => post<KnowledgeDocument>('/api/wiki/documents', data);

/** 复制共享文档到个人空间 */
export const copyToPrivate = (id: number) =>
    post<KnowledgeDocument>(`/api/wiki/documents/${id}/copy-to-private`);

/** 更新文档信息 */
export const updateDocument = (id: number, data: {
    folderId?: number;
    title?: string;
    fileName?: string;
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

// 文件夹下载
export const getFolderDownloadUrl = (id: number) => `/api/wiki/folders/${id}/download`;

export const downloadFolderArchive = (id: number) =>
    get<Blob>(getFolderDownloadUrl(id), undefined, { isBlob: true });

export const downloadSelectedArchive = (data: { documentIds: number[]; folderIds: number[] }) =>
    post<Blob>('/api/wiki/folders/download-selected', data, { isBlob: true });

// ==================== 批量操作 API ====================

/** 批量删除文档 */
export const batchDeleteDocuments = (ids: number[]) =>
    post<{ count: number }>('/api/wiki/documents/batch-delete', { ids });

/** 批量移动文档到目标文件夹 */
export const batchMoveDocuments = (ids: number[], folderId: number | null) =>
    post<{ count: number }>('/api/wiki/documents/batch-move', { ids, folderId });

/** 批量给文档打标签 */
export const batchTagDocuments = (ids: number[], tagIds: number[]) =>
    post<{ count: number }>('/api/wiki/documents/batch-tag', { ids, tagIds });

/** 批量获取文档的标签映射 */
export const getDocumentTagsMap = (ids: number[]) =>
    post<Record<number, KnowledgeTag[]>>('/api/wiki/documents/tags-map', { ids });
