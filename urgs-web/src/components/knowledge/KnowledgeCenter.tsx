import React, { useState, useMemo, useCallback } from 'react';
import { Dropdown, Upload, Modal, Checkbox, message } from 'antd';
import { FolderPlus, Upload as UploadIcon, Tags } from 'lucide-react';
import type { KnowledgeTag } from '../../api/knowledge';
import type { FolderTreeNode, KnowledgeDocument } from '../../api/knowledge';
import { useKnowledgeStore } from './useKnowledgeStore';
import { useUpload } from './useUpload';
import KnowledgeToolbar from './KnowledgeToolbar';
import DocumentGrid from './DocumentGrid';
import DocumentList from './DocumentList';
import FolderModal from './FolderModal';
import TagManagerModal from './TagManagerModal';
import FilePreviewModal from './FilePreviewModal';
import BatchActionBar from './BatchActionBar';
import { UploadProgressPanel } from './UploadProgressPanel';
import * as api from '../../api/knowledge';

const KnowledgeCenter: React.FC = () => {
    const { state, actions, derived, permissions } = useKnowledgeStore();
    const { currentBreadcrumbs, currentSubFolders } = derived;

    // 上传
    const upload = useUpload({
        selectedFolderId: state.selectedFolderId,
        scope: state.scope,
        onDocumentsChanged: actions.loadDocuments,
        onFoldersChanged: actions.loadFolders,
    });

    // 弹窗状态
    const [folderModalOpen, setFolderModalOpen] = useState(false);
    const [editingFolder, setEditingFolder] = useState<FolderTreeNode | null>(null);
    const [tagModalOpen, setTagModalOpen] = useState(false);

    // 预览状态
    const [previewDoc, setPreviewDoc] = useState<KnowledgeDocument | null>(null);

    // 单文档打标签状态
    const [tagTargetDoc, setTagTargetDoc] = useState<KnowledgeDocument | null>(null);
    const [tagSelectedIds, setTagSelectedIds] = useState<number[]>([]);

    const previewIndex = useMemo(() => {
        if (!previewDoc) return -1;
        return state.documents.findIndex(d => d.id === previewDoc.id);
    }, [previewDoc, state.documents]);

    const handlePreviewNext = useCallback(() => {
        if (previewIndex >= 0 && previewIndex < state.documents.length - 1) {
            setPreviewDoc(state.documents[previewIndex + 1]);
        }
    }, [previewIndex, state.documents]);

    const handlePreviewPrev = useCallback(() => {
        if (previewIndex > 0) {
            setPreviewDoc(state.documents[previewIndex - 1]);
        }
    }, [previewIndex, state.documents]);

    // 文件夹操作
    const handleNewFolder = () => {
        setEditingFolder(null);
        setFolderModalOpen(true);
    };

    const handleSaveFolder = async (values: { name: string }) => {
        const success = await actions.onSaveFolder(values, editingFolder);
        if (success) {
            setFolderModalOpen(false);
        }
    };

    const handleRename = (id: number, name: string) => {
        setEditingFolder({ id, name } as FolderTreeNode);
        setFolderModalOpen(true);
    };

    const handleDelete = (id: number, type: 'folder' | 'doc') => {
        if (type === 'folder') {
            actions.onDeleteFolder(id);
        } else {
            actions.handleDeleteDocument(id);
        }
    };

    // 单文档打标签
    const handleOpenTagEditor = (doc: KnowledgeDocument) => {
        setTagTargetDoc(doc);
        setTagSelectedIds(doc.tags?.map(t => t.id) || []);
    };

    const handleSaveDocTags = async () => {
        if (!tagTargetDoc) return;
        try {
            await api.updateDocument(tagTargetDoc.id, { tagIds: tagSelectedIds });
            message.success('标签已更新');
            setTagTargetDoc(null);
            actions.loadDocuments();
        } catch {
            message.error('更新标签失败');
        }
    };

    // 选择操作
    const handleSelect = (key: string, e: React.MouseEvent) => {
        if (e.shiftKey && state.lastSelectedIndex !== null) {
            // 范围选择
            const allKeys = [
                ...currentSubFolders.map(f => `folder-${f.id}`),
                ...state.documents.map(d => `doc-${d.id}`),
            ];
            const currentIdx = allKeys.indexOf(key);
            if (currentIdx >= 0) {
                const start = Math.min(state.lastSelectedIndex, currentIdx);
                const end = Math.max(state.lastSelectedIndex, currentIdx);
                actions.selectRange(allKeys.slice(start, end + 1));
            }
        } else {
            actions.toggleSelect(key);
        }
        // 记录最后选择索引
        const allKeys = [
            ...currentSubFolders.map(f => `folder-${f.id}`),
            ...state.documents.map(d => `doc-${d.id}`),
        ];
        actions.setLastSelectedIndex(allKeys.indexOf(key));
    };

    // 批量操作
    const allItemKeys = useMemo(() => [
        ...currentSubFolders.map(f => `folder-${f.id}`),
        ...state.documents.map(d => `doc-${d.id}`),
    ], [currentSubFolders, state.documents]);

    const handleSelectAll = () => actions.selectAll(allItemKeys);

    const getSelectedDocIds = useCallback((): number[] => {
        return Array.from(state.selectedItems)
            .filter(key => key.startsWith('doc-'))
            .map(key => parseInt(key.replace('doc-', ''), 10));
    }, [state.selectedItems]);

    const handleBatchDownload = useCallback(() => {
        const docIds = getSelectedDocIds();
        const docs = state.documents.filter(d => docIds.includes(d.id));
        docs.forEach((doc, i) => {
            setTimeout(() => actions.handleDownloadItem(doc), i * 100);
        });
        message.success(`正在下载 ${docs.length} 个文件`);
        actions.exitSelectionMode();
    }, [getSelectedDocIds, state.documents, actions]);

    const handleBatchDelete = useCallback(async () => {
        const docIds = getSelectedDocIds();
        if (docIds.length === 0) {
            message.warning('请选择文档');
            return;
        }
        try {
            await api.batchDeleteDocuments(docIds);
            message.success(`已删除 ${docIds.length} 个文档`);
            actions.exitSelectionMode();
            actions.loadDocuments();
        } catch {
            message.error('批量删除失败');
        }
    }, [getSelectedDocIds, actions]);

    const handleBatchMove = useCallback(async (folderId: number | null) => {
        const docIds = getSelectedDocIds();
        if (docIds.length === 0) {
            message.warning('请选择文档');
            return;
        }
        try {
            await api.batchMoveDocuments(docIds, folderId);
            message.success(`已移动 ${docIds.length} 个文档`);
            actions.exitSelectionMode();
            actions.loadDocuments();
        } catch {
            message.error('批量移动失败');
        }
    }, [getSelectedDocIds, actions]);

    const handleBatchTag = useCallback(async (tagIds: number[]) => {
        const docIds = getSelectedDocIds();
        if (docIds.length === 0) {
            message.warning('请选择文档');
            return;
        }
        try {
            await api.batchTagDocuments(docIds, tagIds);
            message.success(`已为 ${docIds.length} 个文档添加标签`);
            actions.exitSelectionMode();
            actions.loadDocuments();
        } catch {
            message.error('批量打标签失败');
        }
    }, [getSelectedDocIds, actions]);

    // 空白区域右键菜单
    const containerMenuItems = useMemo(() => {
        const items: any[] = [];
        const canUpload = !permissions.isShared || permissions.canSharedUpload;
        const canCreateFolder = !permissions.isShared || permissions.canSharedFolderCreate;

        if (canUpload) {
            items.push({
                key: 'upload',
                label: '上传文件',
                icon: <UploadIcon size={16} />,
                onClick: () => document.getElementById('hidden-context-upload')?.click()
            });
        }
        if (canCreateFolder) {
            items.push({
                key: 'newFolder',
                label: '新建文件夹',
                icon: <FolderPlus size={16} />,
                onClick: handleNewFolder,
            });
        }
        return items;
    }, [permissions]);

    // 共享 props
    const isFavoritesView = state.viewMode === 'favorites';
    const viewProps = {
        folders: isFavoritesView ? [] as FolderTreeNode[] : currentSubFolders,
        documents: state.documents,
        emptyText: isFavoritesView ? "暂无收藏的文件" : undefined,
        loading: state.loading,
        isShared: permissions.isShared,
        permissions: {
            canSharedDelete: permissions.canSharedDelete,
            canSharedFolderDelete: permissions.canSharedFolderDelete,
        },
        selectionMode: state.selectionMode,
        selectedItems: state.selectedItems,
        onFolderEnter: actions.setSelectedFolderId,
        onPreview: (doc: KnowledgeDocument) => setPreviewDoc(doc),
        onDelete: handleDelete,
        onRename: handleRename,
        onToggleFavorite: actions.onToggleFavorite,
        onCopyToPrivate: actions.handleCopyToPrivate,
        onDownloadDoc: actions.handleDownloadItem,
        onDownloadFolder: actions.handleDownloadFolder,
        onSelect: handleSelect,
        onTagDocument: handleOpenTagEditor,
    };

    return (
        <div className="flex flex-col h-full bg-slate-50 overflow-hidden font-sans">
            <KnowledgeToolbar
                scope={state.scope}
                viewMode={state.viewMode}
                onScopeChange={actions.setScope}
                onViewModeChange={actions.setViewMode}
                selectedFolderId={state.selectedFolderId}
                breadcrumbs={currentBreadcrumbs}
                onBreadcrumbClick={actions.setSelectedFolderId}
                onBack={actions.handleBack}
                searchKeyword={state.searchKeyword}
                onSearch={actions.setSearchKeyword}
                layoutMode={state.layoutMode}
                onLayoutChange={actions.setLayoutMode}
                uploadProps={upload.uploadProps}
                canUpload={!permissions.isShared || permissions.canSharedUpload}
                canCreateFolder={!permissions.isShared || permissions.canSharedFolderCreate}
                onNewFolder={handleNewFolder}
                tags={state.tags}
                filterTagId={state.filterTagId}
                onFilterTag={actions.setFilterTagId}
                selectionMode={state.selectionMode}
                onEnterSelectionMode={actions.enterSelectionMode}
                onExitSelectionMode={actions.exitSelectionMode}
            />

            <main
                className="flex-1 bg-white flex flex-col relative overflow-hidden"
                onDragOver={(e) => { e.preventDefault(); e.stopPropagation(); }}
                onDrop={upload.handleDrop}
            >
                <Dropdown menu={{ items: containerMenuItems }} trigger={['contextMenu']}>
                    <div className="flex-1 flex flex-col overflow-auto h-full">
                        <div className="flex-1 p-4 relative h-full min-h-[400px]">
                            {state.layoutMode === 'grid'
                                ? <DocumentGrid {...viewProps} />
                                : <DocumentList {...viewProps} />
                            }
                        </div>
                    </div>
                </Dropdown>

                {/* 底部信息栏 */}
                {!state.selectionMode && (
                    <div className="fixed bottom-4 left-1/2 -translate-x-1/2 bg-white/80 backdrop-blur shadow-lg border border-slate-200 rounded-full px-4 py-1.5 flex items-center gap-4 text-[10px] text-slate-500 uppercase tracking-widest font-bold z-20">
                        <span>{isFavoritesView ? `${state.documents.length} 个收藏` : `${state.documents.length + currentSubFolders.length} 个项目`}</span>
                        <div className="w-1 h-1 bg-slate-300 rounded-full"></div>
                        <span className="flex items-center gap-1 cursor-pointer hover:text-blue-500" onClick={() => setTagModalOpen(true)}>
                            <Tags size={10} /> 标签管理
                        </span>
                    </div>
                )}
            </main>

            <FolderModal
                open={folderModalOpen}
                editingFolder={editingFolder}
                onSave={handleSaveFolder}
                onCancel={() => setFolderModalOpen(false)}
            />

            <TagManagerModal
                open={tagModalOpen}
                tags={state.tags}
                onClose={() => setTagModalOpen(false)}
                onCreateTag={async (v) => { await api.createTag(v); actions.loadTags(); }}
                onDeleteTag={async (id) => { await api.deleteTag(id); actions.loadTags(); }}
            />

            {/* 隐藏的右键上传触发器 */}
            <Upload {...upload.uploadProps} style={{ display: 'none' }}>
                <span id="hidden-context-upload" />
            </Upload>

            <UploadProgressPanel
                visible={upload.uploadPanelVisible}
                files={upload.uploadFiles}
                onClose={() => upload.setUploadPanelVisible(false)}
            />

            <BatchActionBar
                visible={state.selectionMode}
                selectedCount={state.selectedItems.size}
                totalCount={allItemKeys.length}
                onSelectAll={handleSelectAll}
                onDeselectAll={actions.deselectAll}
                onBatchDownload={handleBatchDownload}
                onBatchDelete={handleBatchDelete}
                onBatchMove={handleBatchMove}
                onBatchTag={handleBatchTag}
                onCancel={actions.exitSelectionMode}
                folders={state.folders}
                tags={state.tags}
            />

            <FilePreviewModal
                open={!!previewDoc}
                document={previewDoc}
                onClose={() => setPreviewDoc(null)}
                onDownload={actions.handleDownloadItem}
                onNext={handlePreviewNext}
                onPrev={handlePreviewPrev}
                hasNext={previewIndex >= 0 && previewIndex < state.documents.length - 1}
                hasPrev={previewIndex > 0}
            />

            {/* 单文档打标签弹窗 */}
            <Modal
                open={!!tagTargetDoc}
                title={`为「${tagTargetDoc?.title || ''}」设置标签`}
                onCancel={() => setTagTargetDoc(null)}
                onOk={handleSaveDocTags}
                okText="保存"
                cancelText="取消"
                width={360}
            >
                <div className="space-y-1 max-h-64 overflow-auto py-2">
                    {state.tags.length === 0 ? (
                        <p className="text-slate-400 text-sm text-center py-4">
                            暂无标签，请先在标签管理中创建
                        </p>
                    ) : (
                        state.tags.map(t => (
                            <div
                                key={t.id}
                                className="flex items-center gap-2 px-2 py-1.5 hover:bg-slate-50 rounded-lg cursor-pointer transition-colors"
                                onClick={() => {
                                    setTagSelectedIds(prev =>
                                        prev.includes(t.id)
                                            ? prev.filter(x => x !== t.id)
                                            : [...prev, t.id]
                                    );
                                }}
                            >
                                <Checkbox checked={tagSelectedIds.includes(t.id)} />
                                <div
                                    className="w-3 h-3 rounded-full flex-shrink-0"
                                    style={{ backgroundColor: t.color }}
                                />
                                <span className="text-sm text-slate-700">{t.name}</span>
                            </div>
                        ))
                    )}
                </div>
            </Modal>
        </div>
    );
};

export default KnowledgeCenter;
