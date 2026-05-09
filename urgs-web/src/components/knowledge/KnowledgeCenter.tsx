import React, { useState, useMemo, useCallback, useEffect } from 'react';
import { Dropdown, Upload, Modal, Checkbox, Form, Input, message } from 'antd';
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

const DOCUMENT_TITLE_MAX_LENGTH = 200;
const DOCUMENT_FILE_NAME_MAX_LENGTH = 255;

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

const splitFileNameForRename = (fileName: string) => {
    const lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex <= 0 || lastDotIndex === fileName.length - 1) {
        return { baseName: fileName, extension: '' };
    }
    return {
        baseName: fileName.slice(0, lastDotIndex),
        extension: fileName.slice(lastDotIndex),
    };
};

const KnowledgeCenter: React.FC = () => {
    const { state, actions, derived, permissions } = useKnowledgeStore();
    const { currentBreadcrumbs, currentSubFolders } = derived;
    const [docRenameForm] = Form.useForm<{ baseName: string }>();

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
    const [renamingDoc, setRenamingDoc] = useState<KnowledgeDocument | null>(null);
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

    const handleRenameDoc = (id: number, title: string) => {
        const targetDoc = state.documents.find(doc => doc.id === id);
        setRenamingDoc(targetDoc || ({
            id,
            title,
        } as KnowledgeDocument));
    };

    useEffect(() => {
        if (renamingDoc) {
            const originalFileName = renamingDoc.fileName || renamingDoc.title;
            const { baseName } = splitFileNameForRename(originalFileName);
            docRenameForm.setFieldsValue({ baseName });
        } else {
            docRenameForm.resetFields();
        }
    }, [renamingDoc, docRenameForm]);

    const handleSaveDocRename = async () => {
        if (!renamingDoc) return;
        try {
            const values = await docRenameForm.validateFields();
            const originalFileName = renamingDoc.fileName || renamingDoc.title;
            const { extension } = splitFileNameForRename(originalFileName);
            const nextFileName = `${values.baseName}${extension}`;
            await api.updateDocument(renamingDoc.id, {
                title: nextFileName,
                fileName: nextFileName,
            });
            message.success('附件重命名成功');
            setRenamingDoc(null);
            actions.loadDocuments();
            if (previewDoc?.id === renamingDoc.id) {
                setPreviewDoc(prev => prev ? { ...prev, title: nextFileName, fileName: nextFileName } : prev);
            }
        } catch (error) {
            // Form validation errors are handled by antd on the field itself.
            if (error && typeof error === 'object' && 'errorFields' in error) {
                return;
            }
            message.error(getErrorMessage(error, '附件重命名失败'));
        }
    };

    const renamingFileName = renamingDoc?.fileName || renamingDoc?.title || '';
    const renamingFileParts = splitFileNameForRename(renamingFileName);
    const renameBaseNameMaxLength = Math.max(
        1,
        Math.min(DOCUMENT_TITLE_MAX_LENGTH, DOCUMENT_FILE_NAME_MAX_LENGTH) - renamingFileParts.extension.length
    );

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

    const selectedFolderCount = useMemo(() => {
        return Array.from(state.selectedItems).filter(key => key.startsWith('folder-')).length;
    }, [state.selectedItems]);

    const getSelectedDocIds = useCallback((): number[] => {
        return Array.from(state.selectedItems)
            .filter(key => key.startsWith('doc-'))
            .map(key => parseInt(key.replace('doc-', ''), 10));
    }, [state.selectedItems]);

    const getSelectedFolderIds = useCallback((): number[] => {
        return Array.from(state.selectedItems)
            .filter(key => key.startsWith('folder-'))
            .map(key => parseInt(key.replace('folder-', ''), 10));
    }, [state.selectedItems]);

    const handleBatchDownload = useCallback(async () => {
        const docIds = getSelectedDocIds();
        const folderIds = getSelectedFolderIds();
        if (docIds.length === 0 && folderIds.length === 0) {
            message.warning('请选择要下载的项目');
            return;
        }

        const loadingKey = 'knowledge-batch-download';
        message.loading({ content: `正在打包 ${docIds.length + folderIds.length} 个项目...`, key: loadingKey, duration: 0 });
        try {
            const blob = await api.downloadSelectedArchive({ documentIds: docIds, folderIds });
            const url = URL.createObjectURL(blob);
            const link = document.createElement('a');
            link.href = url;
            link.download = '知识库打包下载.zip';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            URL.revokeObjectURL(url);
            message.success({ content: '打包下载已开始', key: loadingKey });
            actions.exitSelectionMode();
        } catch {
            message.error({ content: '打包下载失败', key: loadingKey });
        }
    }, [getSelectedDocIds, getSelectedFolderIds, actions]);

    const handleBatchDelete = useCallback(async () => {
        const docIds = getSelectedDocIds();
        const folderIds = getSelectedFolderIds();
        if (docIds.length === 0 && folderIds.length === 0) {
            message.warning('请选择要删除的项目');
            return;
        }
        try {
            if (docIds.length > 0) {
                await api.batchDeleteDocuments(docIds);
            }
            if (folderIds.length > 0) {
                await Promise.all(folderIds.map(id => api.deleteFolder(id)));
            }
            message.success(`已删除 ${docIds.length + folderIds.length} 个项目`);
            actions.exitSelectionMode();
            actions.loadFolders();
            actions.loadDocuments();
        } catch {
            message.error('批量删除失败');
        }
    }, [getSelectedDocIds, getSelectedFolderIds, actions]);

    const handleBatchMove = useCallback(async (folderId: number | null) => {
        const docIds = getSelectedDocIds();
        const folderIds = getSelectedFolderIds();
        if (folderIds.length > 0) {
            message.warning('移动操作只支持文档，请不要选择文件夹');
            return;
        }
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
    }, [getSelectedDocIds, getSelectedFolderIds, actions]);

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
        onRename: ({ id, name, type }: { id: number; name: string; type: 'folder' | 'doc' }) => {
            if (type === 'doc') {
                handleRenameDoc(id, name);
                return;
            }
            handleRename(id, name);
        },
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

            <Modal
                open={!!renamingDoc}
                title="重命名附件"
                onCancel={() => setRenamingDoc(null)}
                onOk={handleSaveDocRename}
                okText="保存"
                cancelText="取消"
                destroyOnHidden
            >
                <Form form={docRenameForm} layout="vertical" onFinish={handleSaveDocRename}>
                    <Form.Item
                        name="baseName"
                        label="名称"
                        rules={[
                            { required: true, message: '请输入名称' },
                            {
                                validator: async (_, value?: string) => {
                                    if (!value) return;
                                    const nextFileName = `${value}${renamingFileParts.extension}`;
                                    if (nextFileName.length > DOCUMENT_TITLE_MAX_LENGTH) {
                                        throw new Error(`完整名称不能超过 ${DOCUMENT_TITLE_MAX_LENGTH} 个字符`);
                                    }
                                    if (nextFileName.length > DOCUMENT_FILE_NAME_MAX_LENGTH) {
                                        throw new Error(`原始文件名不能超过 ${DOCUMENT_FILE_NAME_MAX_LENGTH} 个字符`);
                                    }
                                }
                            },
                        ]}
                        extra={renamingFileParts.extension ? `扩展名 ${renamingFileParts.extension} 将保持不变` : undefined}
                    >
                        <Input
                            placeholder="附件名称"
                            autoFocus
                            maxLength={renameBaseNameMaxLength}
                            showCount
                            addonAfter={renamingFileParts.extension || undefined}
                        />
                    </Form.Item>
                </Form>
            </Modal>

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
                hasSelectedFolders={selectedFolderCount > 0}
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
