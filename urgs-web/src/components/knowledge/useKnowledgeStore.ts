import { useReducer, useCallback, useMemo, useEffect } from 'react';
import { message } from 'antd';
import * as api from '../../api/knowledge';
import type { FolderTreeNode, KnowledgeDocument, KnowledgeTag } from '../../api/knowledge';
import { hasPermission } from '../../utils/permission';

const getErrorMessage = (error: unknown, fallback: string) => {
    if (error instanceof Error && error.message) {
        try {
            const parsed = JSON.parse(error.message);
            if (parsed?.message) {
                return parsed.message as string;
            }
        } catch {
            return error.message;
        }
        return error.message;
    }
    return fallback;
};

// ==================== State ====================

interface KnowledgeState {
    folders: FolderTreeNode[];
    documents: KnowledgeDocument[];
    tags: KnowledgeTag[];
    selectedFolderId: number | null;
    scope: 'private' | 'shared';
    viewMode: 'browse' | 'favorites';
    searchKeyword: string;
    layoutMode: 'grid' | 'list';
    loading: boolean;
    // 标签筛选
    filterTagId: number | null;
    // Phase 3: 批量选择
    selectedItems: Set<string>;
    selectionMode: boolean;
    lastSelectedIndex: number | null;
}

const initialState: KnowledgeState = {
    folders: [],
    documents: [],
    tags: [],
    selectedFolderId: null,
    scope: 'private',
    viewMode: 'browse',
    searchKeyword: '',
    layoutMode: 'grid',
    loading: false,
    filterTagId: null,
    selectedItems: new Set(),
    selectionMode: false,
    lastSelectedIndex: null,
};

// ==================== Actions ====================

type KnowledgeAction =
    | { type: 'SET_FOLDERS'; payload: FolderTreeNode[] }
    | { type: 'SET_DOCUMENTS'; payload: KnowledgeDocument[] }
    | { type: 'SET_TAGS'; payload: KnowledgeTag[] }
    | { type: 'SET_SCOPE'; payload: 'private' | 'shared' }
    | { type: 'SET_SELECTED_FOLDER'; payload: number | null }
    | { type: 'SET_SEARCH'; payload: string }
    | { type: 'SET_LAYOUT'; payload: 'grid' | 'list' }
    | { type: 'SET_LOADING'; payload: boolean }
    | { type: 'SET_VIEW_MODE'; payload: 'browse' | 'favorites' }
    | { type: 'SET_FILTER_TAG'; payload: number | null }
    // Phase 3: 批量选择
    | { type: 'TOGGLE_SELECT'; payload: string }
    | { type: 'SELECT_RANGE'; payload: string[] }
    | { type: 'SELECT_ALL'; payload: string[] }
    | { type: 'DESELECT_ALL' }
    | { type: 'ENTER_SELECTION_MODE' }
    | { type: 'EXIT_SELECTION_MODE' }
    | { type: 'SET_LAST_SELECTED_INDEX'; payload: number | null };

function reducer(state: KnowledgeState, action: KnowledgeAction): KnowledgeState {
    switch (action.type) {
        case 'SET_FOLDERS':
            return { ...state, folders: action.payload };
        case 'SET_DOCUMENTS':
            return { ...state, documents: action.payload };
        case 'SET_TAGS':
            return { ...state, tags: action.payload };
        case 'SET_SCOPE':
            return {
                ...state,
                scope: action.payload,
                viewMode: 'browse',
                selectedFolderId: null,
                searchKeyword: '',
                filterTagId: null,
                selectedItems: new Set(),
                selectionMode: false,
            };
        case 'SET_VIEW_MODE':
            return {
                ...state,
                viewMode: action.payload,
                selectedFolderId: null,
                searchKeyword: '',
                filterTagId: null,
                selectedItems: new Set(),
                selectionMode: false,
            };
        case 'SET_SELECTED_FOLDER':
            return { ...state, selectedFolderId: action.payload, viewMode: 'browse' };
        case 'SET_SEARCH':
            return { ...state, searchKeyword: action.payload };
        case 'SET_LAYOUT':
            return { ...state, layoutMode: action.payload };
        case 'SET_LOADING':
            return { ...state, loading: action.payload };
        case 'SET_FILTER_TAG':
            return { ...state, filterTagId: action.payload };
        case 'TOGGLE_SELECT': {
            const next = new Set(state.selectedItems);
            if (next.has(action.payload)) {
                next.delete(action.payload);
            } else {
                next.add(action.payload);
            }
            return { ...state, selectedItems: next, selectionMode: true };
        }
        case 'SELECT_RANGE': {
            const next = new Set(state.selectedItems);
            action.payload.forEach(key => next.add(key));
            return { ...state, selectedItems: next, selectionMode: true };
        }
        case 'SELECT_ALL':
            return { ...state, selectedItems: new Set(action.payload), selectionMode: true };
        case 'DESELECT_ALL':
            return { ...state, selectedItems: new Set() };
        case 'ENTER_SELECTION_MODE':
            return { ...state, selectionMode: true };
        case 'EXIT_SELECTION_MODE':
            return { ...state, selectionMode: false, selectedItems: new Set(), lastSelectedIndex: null };
        case 'SET_LAST_SELECTED_INDEX':
            return { ...state, lastSelectedIndex: action.payload };
        default:
            return state;
    }
}

// ==================== Hook ====================

export function useKnowledgeStore() {
    const [state, dispatch] = useReducer(reducer, initialState);

    // ---- 权限 ----
    const permissions = useMemo(() => ({
        isShared: state.scope === 'shared',
        canSharedUpload: hasPermission('knowledge:shared:upload'),
        canSharedDelete: hasPermission('knowledge:shared:delete'),
        canSharedFolderCreate: hasPermission('knowledge:shared:folder:create'),
        canSharedFolderDelete: hasPermission('knowledge:shared:folder:delete'),
    }), [state.scope]);

    // ---- 数据加载 ----
    const loadFolders = useCallback(async () => {
        try {
            const data = await api.getFolderTree(state.scope);
            dispatch({ type: 'SET_FOLDERS', payload: data });
        } catch (error) {
            console.error('加载文件夹失败:', error);
        }
    }, [state.scope]);

    const loadDocuments = useCallback(async () => {
        dispatch({ type: 'SET_LOADING', payload: true });
        try {
            let docs: KnowledgeDocument[];
            if (state.viewMode === 'favorites') {
                const data = await api.getFavoriteDocuments();
                docs = state.searchKeyword
                    ? data.filter(d => d.title.includes(state.searchKeyword))
                    : data;
            } else {
                const result = await api.listDocuments({
                    folderId: state.selectedFolderId ?? undefined,
                    keyword: state.searchKeyword || undefined,
                    page: 1,
                    size: 200,
                    scope: state.scope,
                });
                docs = result.records || [];
            }

            // 批量获取文档标签
            if (docs.length > 0) {
                try {
                    const tagsMap = await api.getDocumentTagsMap(docs.map(d => d.id));
                    docs.forEach(d => { d.tags = tagsMap[d.id] || []; });
                } catch {
                    // 标签获取失败不影响文档展示
                }
            }

            // 标签筛选（客户端过滤）
            if (state.filterTagId) {
                docs = docs.filter(d => d.tags?.some(t => t.id === state.filterTagId));
            }

            dispatch({ type: 'SET_DOCUMENTS', payload: docs });
        } catch (error) {
            console.error('加载文档失败:', error);
            dispatch({ type: 'SET_DOCUMENTS', payload: [] });
        } finally {
            dispatch({ type: 'SET_LOADING', payload: false });
        }
    }, [state.selectedFolderId, state.searchKeyword, state.scope, state.viewMode, state.filterTagId]);

    const loadTags = useCallback(async () => {
        try {
            const data = await api.listTags();
            dispatch({ type: 'SET_TAGS', payload: data });
        } catch (error) {
            console.error('加载标签失败:', error);
        }
    }, []);

    useEffect(() => { loadFolders(); loadTags(); }, [loadFolders, loadTags]);
    useEffect(() => { loadDocuments(); }, [loadDocuments]);

    // ---- 派生数据 ----
    const currentBreadcrumbs = useMemo(() => {
        const path: Array<{ id: number | null; name: string }> = [{ id: null, name: '根目录' }];
        if (!state.selectedFolderId) return path;

        const resultPath: Array<{ id: number; name: string }> = [];
        const findFullPath = (nodes: FolderTreeNode[], targetId: number, acc: Array<{ id: number; name: string }>) => {
            for (const node of nodes) {
                const newAcc = [...acc, { id: node.id, name: node.name }];
                if (node.id === targetId) {
                    resultPath.push(...newAcc);
                    return true;
                }
                if (node.children && findFullPath(node.children, targetId, newAcc)) return true;
            }
            return false;
        };
        findFullPath(state.folders, state.selectedFolderId, []);
        return [...path, ...resultPath];
    }, [state.folders, state.selectedFolderId]);

    const currentSubFolders = useMemo(() => {
        if (!state.selectedFolderId) return state.folders;

        const findNode = (nodes: FolderTreeNode[], targetId: number): FolderTreeNode | null => {
            for (const node of nodes) {
                if (node.id === targetId) return node;
                if (node.children) {
                    const found = findNode(node.children, targetId);
                    if (found) return found;
                }
            }
            return null;
        };
        const currentNode = findNode(state.folders, state.selectedFolderId);
        return currentNode?.children || [];
    }, [state.folders, state.selectedFolderId]);

    // ---- 操作 ----
    const actions = useMemo(() => ({
        setScope: (val: 'private' | 'shared') => dispatch({ type: 'SET_SCOPE', payload: val }),
        setViewMode: (val: 'browse' | 'favorites') => dispatch({ type: 'SET_VIEW_MODE', payload: val }),
        setSelectedFolderId: (id: number | null) => dispatch({ type: 'SET_SELECTED_FOLDER', payload: id }),
        setSearchKeyword: (val: string) => dispatch({ type: 'SET_SEARCH', payload: val }),
        setLayoutMode: (val: 'grid' | 'list') => dispatch({ type: 'SET_LAYOUT', payload: val }),
        setFilterTagId: (id: number | null) => dispatch({ type: 'SET_FILTER_TAG', payload: id }),
        loadFolders,
        loadDocuments,
        loadTags,

        handleBack: () => {
            if (currentBreadcrumbs.length > 1) {
                const parent = currentBreadcrumbs[currentBreadcrumbs.length - 2];
                dispatch({ type: 'SET_SELECTED_FOLDER', payload: parent.id });
            }
        },

        onSaveFolder: async (values: { name: string }, editingFolder: FolderTreeNode | null) => {
            try {
                if (editingFolder) {
                    await api.updateFolder(editingFolder.id, { name: values.name });
                    message.success('重命名成功');
                } else {
                    await api.createFolder({
                        name: values.name,
                        parentId: state.selectedFolderId ?? undefined,
                        scope: state.scope,
                    });
                    message.success('文件夹创建成功');
                }
                loadFolders();
                return true;
            } catch (error) {
                message.error(getErrorMessage(error, '操作失败'));
                return false;
            }
        },

        onDeleteFolder: async (id: number) => {
            try {
                await api.deleteFolder(id);
                message.success('删除成功');
                loadFolders();
            } catch {
                message.error('删除失败');
            }
        },

        handleDeleteDocument: async (id: number) => {
            try {
                await api.deleteDocument(id);
                message.success('附件已删除');
                loadDocuments();
            } catch {
                message.error('删除失败');
            }
        },

        onToggleFavorite: async (doc: KnowledgeDocument) => {
            try {
                const result = await api.toggleFavorite(doc.id);
                message.success(result.favorite ? '已收藏' : '已取消收藏');
                loadDocuments();
            } catch {
                message.error('操作失败');
            }
        },

        handleCopyToPrivate: async (docId: number) => {
            try {
                await api.copyToPrivate(docId);
                message.success('已添加到我的空间');
            } catch {
                message.error('添加失败');
            }
        },

        handleDownloadItem: (doc: KnowledgeDocument) => {
            if (doc.fileUrl) {
                const link = document.createElement('a');
                link.href = doc.fileUrl;
                link.download = doc.fileName || doc.title;
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
            }
        },

        handleDownloadFolder: (id: number, title: string) => {
            const url = api.getFolderDownloadUrl(id);
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', `${title}.zip`);
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            message.loading('正在打包文件夹...', 2);
        },

        // Phase 3: 选择操作
        toggleSelect: (key: string) => dispatch({ type: 'TOGGLE_SELECT', payload: key }),
        selectRange: (keys: string[]) => dispatch({ type: 'SELECT_RANGE', payload: keys }),
        selectAll: (keys: string[]) => dispatch({ type: 'SELECT_ALL', payload: keys }),
        deselectAll: () => dispatch({ type: 'DESELECT_ALL' }),
        enterSelectionMode: () => dispatch({ type: 'ENTER_SELECTION_MODE' }),
        exitSelectionMode: () => dispatch({ type: 'EXIT_SELECTION_MODE' }),
        setLastSelectedIndex: (idx: number | null) => dispatch({ type: 'SET_LAST_SELECTED_INDEX', payload: idx }),
    }), [loadFolders, loadDocuments, loadTags, currentBreadcrumbs, state.selectedFolderId, state.scope]);

    return {
        state,
        actions,
        derived: { currentBreadcrumbs, currentSubFolders },
        permissions,
    };
}
