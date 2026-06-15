import React, { useCallback, useMemo, useState } from 'react';
import { Dropdown, Empty, Input, Modal, Pagination, Select, Spin, Table, Upload, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import type { MenuProps, UploadProps } from 'antd';
import {
    Copy,
    Download,
    Edit3,
    FilePlus2,
    FileSpreadsheet,
    FileText,
    FileType,
    Grid3X3,
    LayoutList,
    MoreHorizontal,
    RefreshCcw,
    Search,
    Share2,
    SlidersHorizontal,
    Star,
    Trash2,
    UploadCloud,
    Users,
} from 'lucide-react';
import type { OnlineDocument, OnlineDocumentPage } from '../../api/onlineDocs';
import {
    createBlankOnlineDocument,
    createOnlineDocument,
    deleteOnlineDocument,
    updateOnlineDocument,
    uploadOnlineDocumentFile,
} from '../../api/onlineDocs';
import OnlyOfficeEditorModal, { isOnlyOfficeSupported } from './OnlyOfficeEditorModal';
import { useDocumentList } from './hooks/useDocumentList';
import type { TabKey } from './hooks/useDocumentList';
import { usePermissionGroups } from './hooks/usePermissionGroups';
import { useDocumentPermissions } from './hooks/useDocumentPermissions';
import { useQuickAccess } from './hooks/useQuickAccess';

const PAGE_SIZE = 12;
type BlankDocumentType = 'word' | 'cell';

const blankTypeOptions: { value: BlankDocumentType; label: string; defaultTitle: string }[] = [
    { value: 'word', label: '文字文档', defaultTitle: '新建文档' },
    { value: 'cell', label: '电子表格', defaultTitle: '新建表格' },
];

// ---- helpers ----

const formatFileSize = (size?: number | null) => {
    if (!size) return '-';
    if (size < 1024) return `${size} B`;
    if (size < 1024 * 1024) return `${(size / 1024).toFixed(1)} KB`;
    return `${(size / 1024 / 1024).toFixed(1)} MB`;
};

const formatTime = (value?: string) => {
    if (!value) return '-';
    return value.replace('T', ' ').slice(0, 16);
};

type FileTypeKey = 'word' | 'excel' | 'pdf' | 'other';

const getFileTypeKey = (fileName?: string): FileTypeKey => {
    if (!fileName) return 'other';
    const ext = fileName.split('.').pop()?.toLowerCase() || '';
    if (['doc', 'docx'].includes(ext)) return 'word';
    if (['xls', 'xlsx'].includes(ext)) return 'excel';
    if (ext === 'pdf') return 'pdf';
    return 'other';
};

const fileTypeConfig: Record<FileTypeKey, { icon: React.FC<{ size?: number }>; color: string; bg: string }> = {
    word: { icon: FileText, color: '#1677FF', bg: '#E6F4FF' },
    excel: { icon: FileSpreadsheet, color: '#52C41A', bg: '#F6FFED' },
    pdf: { icon: FileType, color: '#FF4D4F', bg: '#FFF1F0' },
    other: { icon: FileText, color: '#8C8C8C', bg: '#FAFAFA' },
};

// ---- component ----

const OnlineDocsTool: React.FC = () => {
    // Hooks: document list
    const {
        documents, keyword, page, total, loading,
        activeTab, activeSpaceType, filterType,
        setPage, setActiveTab, setActiveSpaceType, setFilterType,
        loadDocuments, handleSearch, handleToggleFavorite, supportedCount,
    } = useDocumentList();

    // Hooks: quick access
    const [quickAccessToken, setQuickAccessToken] = useState(0);
    const { recentDocs } = useQuickAccess(quickAccessToken);

    // Hooks: permission groups
    const {
        groupManagerOpen, permissionGroups: groupList, editingGroupId,
        groupName, groupDescription, groupUserIds, groupOptions: groupUserOptions,
        groupSearchValue, groupLoading, groupSaving,
        openGroupManager, closeGroupManager, editPermissionGroup, savePermissionGroup,
        setGroupName, setGroupDescription, setGroupUserIds, setGroupSearchValue,
        searchGroupUsers, toGroupUserOptions,
    } = usePermissionGroups();

    // Hooks: document permissions
    const {
        permissionDoc, permissionUserIds, permissionOptions,
        permissionSearchValue, permissionGroups: permGroups,
        permissionLoading, permissionSaving,
        openPermissions, closePermissions, savePermissions,
        setPermissionUserIds, setPermissionSearchValue,
        searchPermissionUsers, applyPermissionGroup,
    } = useDocumentPermissions(toGroupUserOptions);

    // Local state
    const [editorDoc, setEditorDoc] = useState<OnlineDocument | null>(null);
    const [renamingDoc, setRenamingDoc] = useState<OnlineDocument | null>(null);
    const [renameValue, setRenameValue] = useState('');
    const [createOpen, setCreateOpen] = useState(false);
    const [createTitle, setCreateTitle] = useState('新建文档');
    const [createType, setCreateType] = useState<BlankDocumentType>('word');
    const [creating, setCreating] = useState(false);
    const [viewMode, setViewMode] = useState<'list' | 'grid'>('list');
    const [groupDeleteConfirm, setGroupDeleteConfirm] = useState<number | null>(null);

    // Refresh quick access after operations
    const refreshQuickAccess = useCallback(() => {
        setQuickAccessToken(t => t + 1);
    }, []);

    // ---- actions ----

    const handleUpload: UploadProps['customRequest'] = async (options) => {
        const file = options.file as File;
        const extension = file.name.split('.').pop()?.toLowerCase() || '';
        if (!['doc', 'docx', 'xls', 'xlsx', 'pdf'].includes(extension)) {
            message.warning('仅支持 doc、docx、xls、xlsx、pdf 文件');
            options.onError?.(new Error('不支持的文件类型'));
            return;
        }
        try {
            const uploaded = await uploadOnlineDocumentFile(file);
            await createOnlineDocument({
                title: uploaded.name || file.name,
                fileName: uploaded.name || file.name,
                fileUrl: uploaded.url,
                fileSize: file.size,
            });
            message.success('在线文档已上传');
            options.onSuccess?.(uploaded);
            setPage(1);
            refreshQuickAccess();
            loadDocuments();
        } catch (error) {
            options.onError?.(error as Error);
            message.error('在线文档上传失败');
        }
    };

    const handleDownload = useCallback((doc: OnlineDocument) => {
        window.open(doc.fileUrl, '_blank');
    }, []);

    const handleDelete = useCallback((doc: OnlineDocument) => {
        Modal.confirm({
            title: '删除在线文档',
            content: `确认删除「${doc.title}」吗？`,
            okText: '删除',
            okButtonProps: { danger: true },
            cancelText: '取消',
            onOk: async () => {
                await deleteOnlineDocument(doc.id);
                message.success('在线文档已删除');
                refreshQuickAccess();
                loadDocuments();
            },
        });
    }, [loadDocuments, refreshQuickAccess]);

    const handleCopyLink = useCallback((doc: OnlineDocument) => {
        navigator.clipboard.writeText(doc.fileUrl).then(() => {
            message.success('链接已复制');
        }).catch(() => {
            message.error('复制失败');
        });
    }, []);

    const openRename = useCallback((doc: OnlineDocument) => {
        setRenamingDoc(doc);
        setRenameValue(doc.title);
    }, []);

    const saveRename = useCallback(async () => {
        if (!renamingDoc) return;
        const nextTitle = renameValue.trim();
        if (!nextTitle) {
            message.warning('请输入文档名称');
            return;
        }
        await updateOnlineDocument(renamingDoc.id, { title: nextTitle });
        message.success('文档名称已更新');
        setRenamingDoc(null);
        refreshQuickAccess();
        loadDocuments();
    }, [renamingDoc, renameValue, loadDocuments, refreshQuickAccess]);

    const openCreate = useCallback(() => {
        setCreateType('word');
        setCreateTitle('新建文档');
        setCreateOpen(true);
    }, []);

    const handleCreateTypeChange = useCallback((value: BlankDocumentType) => {
        setCreateType(value);
        const option = blankTypeOptions.find(item => item.value === value);
        setCreateTitle(option?.defaultTitle || '新建文档');
    }, []);

    const saveCreate = useCallback(async () => {
        const title = createTitle.trim();
        if (!title) {
            message.warning('请输入文档名称');
            return;
        }
        setCreating(true);
        try {
            const doc = await createBlankOnlineDocument({ title, documentType: createType });
            message.success('在线文档已新建');
            setCreateOpen(false);
            if (page === 1) {
                await loadDocuments();
            } else {
                setPage(1);
            }
            refreshQuickAccess();
            setEditorDoc(doc);
        } catch {
            message.error('在线文档新建失败');
        } finally {
            setCreating(false);
        }
    }, [createTitle, createType, page, loadDocuments, setPage, refreshQuickAccess]);

    const handleWrappedSavePermissions = useCallback(async () => {
        await savePermissions();
        refreshQuickAccess();
        loadDocuments();
    }, [savePermissions, loadDocuments, refreshQuickAccess]);

    // ---- action menu ----

    const getActionItems = useCallback((doc: OnlineDocument): MenuProps['items'] => {
        const isOwner = doc.canManagePermissions === true;
        const items: MenuProps['items'] = [
            { key: 'edit', icon: <Edit3 size={14} />, label: '在线打开', onClick: () => setEditorDoc(doc) },
            { key: 'download', icon: <Download size={14} />, label: '下载', onClick: () => handleDownload(doc) },
        ];

        if (isOwner) {
            items.push(
                { key: 'rename', icon: <FileText size={14} />, label: '重命名', onClick: () => openRename(doc) },
                { type: 'divider' },
                { key: 'share', icon: <Share2 size={14} />, label: '授权', onClick: () => openPermissions(doc) },
            );
        }

        items.push(
            { type: 'divider' },
            {
                key: 'favorite',
                icon: <Star size={14} fill={doc.favorite ? '#FAAD14' : 'none'} stroke={doc.favorite ? '#FAAD14' : undefined} />,
                label: doc.favorite ? '取消收藏' : '收藏',
                onClick: () => handleToggleFavorite(doc),
            },
        );

        if (isOwner) {
            items.push(
                { type: 'divider' },
                { key: 'delete', icon: <Trash2 size={14} />, label: '删除', danger: true, onClick: () => handleDelete(doc) },
            );
        }

        return items;
    }, [handleDownload, openRename, openPermissions, handleToggleFavorite, handleDelete]);

    // ---- table columns ----

    const columns: ColumnsType<OnlineDocument> = useMemo(() => [
        {
            title: '名称',
            dataIndex: 'title',
            key: 'name',
            width: '35%',
            sorter: (a, b) => a.title.localeCompare(b.title),
            render: (_: string, record: OnlineDocument) => {
                const ft = fileTypeConfig[getFileTypeKey(record.fileName)];
                const Icon = ft.icon;
                return (
                    <div
                        className="flex items-center gap-3 cursor-pointer group/name"
                        onClick={() => setEditorDoc(record)}
                    >
                        <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-md"
                            style={{ backgroundColor: ft.bg, color: ft.color }}>
                            <Icon size={18} />
                        </span>
                        <span className="text-sm font-medium text-gray-900 truncate group-hover/name:text-[#1677FF] transition-colors">
                            {record.title}
                        </span>
                        {record.favorite && (
                            <Star size={12} fill="#FAAD14" stroke="#FAAD14" className="shrink-0" />
                        )}
                    </div>
                );
            },
        },
        {
            title: '所有者',
            dataIndex: 'userId',
            key: 'owner',
            width: '12%',
            render: (_: unknown, record: OnlineDocument) => (
                <span className="text-sm text-gray-500">
                    {record.canManagePermissions ? '我' : record.ownerName || `用户${record.userId}`}
                </span>
            ),
        },
        {
            title: '位置',
            dataIndex: 'fileName',
            key: 'location',
            width: '18%',
            render: (_: string, record: OnlineDocument) => (
                <span className="text-sm text-gray-400 truncate block max-w-[200px]">{record.fileName || record.title}</span>
            ),
        },
        {
            title: '最近查看',
            dataIndex: 'updateTime',
            key: 'updateTime',
            width: '16%',
            sorter: (a, b) => new Date(a.updateTime).getTime() - new Date(b.updateTime).getTime(),
            defaultSortOrder: 'descend',
            render: (value: string) => (
                <span className="text-sm text-gray-400">{formatTime(value)}</span>
            ),
        },
        {
            title: '文件大小',
            dataIndex: 'fileSize',
            key: 'fileSize',
            width: '10%',
            align: 'right',
            sorter: (a, b) => (a.fileSize || 0) - (b.fileSize || 0),
            render: (value: number | null) => (
                <span className="text-sm text-gray-400">{formatFileSize(value)}</span>
            ),
        },
        {
            title: '',
            key: 'actions',
            width: '9%',
            align: 'right',
            render: (_: unknown, record: OnlineDocument) => (
                <div className="flex items-center justify-end gap-1 opacity-0 group-hover/row:opacity-100 transition-opacity">
                    <button onClick={(e) => { e.stopPropagation(); handleCopyLink(record); }}
                        className="flex h-7 w-7 items-center justify-center rounded-md text-gray-400 transition-colors hover:bg-gray-100 hover:text-[#1677FF]"
                        title="复制链接">
                        <Copy size={14} />
                    </button>
                    <Dropdown menu={{ items: getActionItems(record) }} trigger={['click']}>
                        <button onClick={(e) => e.stopPropagation()}
                            className="flex h-7 w-7 items-center justify-center rounded-md text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600"
                            title="更多操作">
                            <MoreHorizontal size={14} />
                        </button>
                    </Dropdown>
                </div>
            ),
        },
    ], [handleCopyLink, getActionItems]);

    // ---- grid view card ----

    const renderGridCard = useCallback((doc: OnlineDocument) => {
        const ft = fileTypeConfig[getFileTypeKey(doc.fileName)];
        const Icon = ft.icon;
        return (
            <div key={doc.id} onClick={() => setEditorDoc(doc)}
                className="group/card flex flex-col rounded-xl border border-gray-100 bg-white p-4 transition-all hover:border-[#1677FF]/30 hover:shadow-md cursor-pointer">
                <div className="flex items-center justify-center h-28 rounded-lg mb-3"
                    style={{ backgroundColor: ft.bg }}>
                    <span style={{ color: ft.color }}><Icon size={40} /></span>
                </div>
                <div className="flex items-center gap-1 text-sm font-medium text-gray-900 truncate" title={doc.title}>
                    <span className="truncate">{doc.title}</span>
                    {doc.favorite && <Star size={12} fill="#FAAD14" stroke="#FAAD14" className="shrink-0" />}
                </div>
                <div className="text-xs text-gray-400 mt-1">{formatTime(doc.updateTime)}</div>
                <div className="flex items-center gap-1 mt-3 opacity-0 group-hover/card:opacity-100 transition-opacity">
                    <button onClick={(e) => { e.stopPropagation(); handleCopyLink(doc); }}
                        className="flex h-7 w-7 items-center justify-center rounded-md text-gray-400 transition-colors hover:bg-gray-100 hover:text-[#1677FF]"
                        title="复制链接">
                        <Copy size={14} />
                    </button>
                    <Dropdown menu={{ items: getActionItems(doc) }} trigger={['click']}>
                        <button onClick={(e) => e.stopPropagation()}
                            className="flex h-7 w-7 items-center justify-center rounded-md text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600"
                            title="更多操作">
                            <MoreHorizontal size={14} />
                        </button>
                    </Dropdown>
                </div>
            </div>
        );
    }, [handleCopyLink, getActionItems]);

    // ---- tab content ----

    const renderTabContent = useCallback(() => {
        if (documents.length === 0 && !loading) {
            return (
                <div className="flex items-center justify-center h-[420px]">
                    <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="暂无在线文档" />
                </div>
            );
        }

        if (viewMode === 'grid') {
            return (
                <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4 p-4">
                    {documents.map(doc => renderGridCard(doc))}
                </div>
            );
        }

        return (
            <Table<OnlineDocument>
                rowKey="id" columns={columns} dataSource={documents}
                loading={loading} pagination={false} showHeader={true} size="middle"
                className="online-docs-table" rowClassName="group/row"
                locale={{ emptyText: '暂无文档' }}
                onRow={(record) => ({
                    onDoubleClick: () => setEditorDoc(record),
                    style: { cursor: 'pointer' },
                })}
            />
        );
    }, [documents, loading, viewMode, columns, renderGridCard]);

    // ---- tabs config ----

    const tabs: { key: TabKey; label: string }[] = [
        { key: 'recent', label: '最近' },
        { key: 'space', label: '空间' },
        { key: 'favorite', label: '收藏' },
    ];

    // ---- render ----

    return (
        <div className="flex h-full flex-col bg-white">
            {/* Quick Access Bar */}
            {recentDocs.length > 0 && (
                <div className="shrink-0 border-b border-gray-100 bg-white px-6 py-4">
                    <div className="text-xs font-medium text-gray-400 mb-3 uppercase tracking-wide">快速访问</div>
                    <div className="flex flex-wrap gap-3">
                        {recentDocs.map(doc => {
                            const ft = fileTypeConfig[getFileTypeKey(doc.fileName)];
                            const Icon = ft.icon;
                            return (
                                <button key={doc.id} onClick={() => setEditorDoc(doc)}
                                    className="flex items-center gap-2.5 rounded-lg border border-gray-200 bg-white px-3.5 py-2.5 text-sm transition-all hover:border-[#1677FF]/30 hover:shadow-sm hover:-translate-y-0.5"
                                    title={doc.title}>
                                    <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded"
                                        style={{ backgroundColor: ft.bg, color: ft.color }}>
                                        <Icon size={14} />
                                    </span>
                                    <span className="flex items-center gap-1 text-gray-700 max-w-[160px] truncate text-left">
                                        <span className="truncate">{doc.title}</span>
                                        {doc.favorite && <Star size={10} fill="#FAAD14" stroke="#FAAD14" className="shrink-0" />}
                                    </span>
                                </button>
                            );
                        })}
                    </div>
                </div>
            )}

            {/* Tab Navigation + Toolbar */}
            <div className="flex shrink-0 items-center justify-between border-b border-gray-100 bg-white px-6">
                <div className="flex items-center gap-0 relative">
                    {tabs.map(tab => (
                        <button key={tab.key} onClick={() => setActiveTab(tab.key)}
                            className={`relative px-5 py-3 text-sm font-medium transition-colors ${
                                activeTab === tab.key ? 'text-[#1677FF]' : 'text-gray-500 hover:text-gray-700'}`}>
                            {tab.label}
                            {activeTab === tab.key && (
                                <span className="absolute bottom-0 left-1/2 -translate-x-1/2 w-5 h-0.5 bg-[#1677FF] rounded-full" />
                            )}
                        </button>
                    ))}
                    {/* Space Type Sub-tabs */}
                    {activeTab === 'space' && (
                        <div className="ml-4 flex items-center gap-1 pl-4 border-l border-gray-200">
                            {[
                                { key: 'all', label: '全部' },
                                { key: 'personal', label: '个人' },
                                { key: 'shared', label: '共享' },
                            ].map((space) => (
                                <button key={space.key} onClick={() => setActiveSpaceType(space.key as typeof activeSpaceType)}
                                    className={`px-3 py-1 text-xs rounded-md transition-colors ${
                                        activeSpaceType === space.key ? 'bg-[#E6F4FF] text-[#1677FF]' : 'text-gray-500 hover:bg-gray-50'}`}>
                                    {space.label}
                                </button>
                            ))}
                        </div>
                    )}
                </div>

                {/* Toolbar */}
                <div className="flex items-center gap-2">
                    <Input.Search allowClear className="w-56" placeholder="搜索在线文档"
                        prefix={<Search size={14} className="text-gray-400" />}
                        onSearch={handleSearch} size="small" />
                    <button onClick={loadDocuments} className="flex h-7 w-7 items-center justify-center rounded-md text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600"
                        title="刷新">
                        <RefreshCcw size={14} />
                    </button>
                    <button onClick={openGroupManager}
                        className="flex h-7 items-center gap-1.5 rounded-md border border-slate-200 bg-white px-2.5 text-xs font-medium text-slate-600 transition-colors hover:border-slate-300 hover:bg-slate-50">
                        <Users size={14} /> 授权组
                    </button>
                    <button onClick={openCreate}
                        className="flex h-7 items-center gap-1.5 rounded-md border border-[#1677FF]/20 bg-[#E6F4FF] px-2.5 text-xs font-medium text-[#1677FF] transition-colors hover:border-[#1677FF]/40 hover:bg-[#BAE0FF]">
                        <FilePlus2 size={14} /> 新建
                    </button>
                    <Upload customRequest={handleUpload} showUploadList={false} accept=".doc,.docx,.xls,.xlsx,.pdf">
                        <button className="flex h-7 items-center gap-1.5 rounded-md bg-[#1677FF] px-2.5 text-xs font-medium text-white transition-colors hover:bg-[#4096FF]">
                            <UploadCloud size={14} /> 上传
                        </button>
                    </Upload>
                    <span className="w-px h-5 bg-gray-200 mx-1" />
                    <button onClick={() => setViewMode(viewMode === 'list' ? 'grid' : 'list')}
                        className="flex h-7 w-7 items-center justify-center rounded-md text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600"
                        title={viewMode === 'list' ? '切换为网格视图' : '切换为列表视图'}>
                        {viewMode === 'list' ? <LayoutList size={15} /> : <Grid3X3 size={15} />}
                    </button>
                    <Dropdown menu={{
                        selectedKeys: [filterType],
                        onClick: ({ key }) => setFilterType(key),
                        items: [
                            { key: 'all', label: '全部文档' },
                            { key: 'word', label: '文字文档' },
                            { key: 'excel', label: '电子表格' },
                            { key: 'pdf', label: 'PDF 文档' },
                        ],
                    }} trigger={['click']}>
                        <button className="flex h-7 items-center gap-1 rounded-md border border-gray-200 bg-white px-2 text-xs text-gray-500 transition-colors hover:border-gray-300 hover:text-gray-700">
                            <SlidersHorizontal size={13} /> 筛选
                        </button>
                    </Dropdown>
                </div>
            </div>

            {/* Info Bar */}
            <div className="flex shrink-0 items-center justify-between bg-[#FAFAFA] px-6 py-1.5 text-xs text-gray-400 border-b border-gray-100">
                <span>共 {total} 个文档</span>
                <span>{supportedCount} 个支持在线编辑</span>
            </div>

            {/* Main Content */}
            <Spin spinning={loading}>
                <div className="flex-1 min-h-0 overflow-auto px-6 py-3">
                    {renderTabContent()}
                </div>
            </Spin>

            {/* Pagination */}
            {total > PAGE_SIZE && (
                <div className="flex shrink-0 justify-end border-t border-gray-100 bg-white px-6 py-3">
                    <Pagination current={page} pageSize={PAGE_SIZE} total={total}
                        showSizeChanger={false} showQuickJumper={false}
                        onChange={setPage} size="small" />
                </div>
            )}

            {/* ===== Modals ===== */}

            {/* Rename Modal */}
            <Modal open={!!renamingDoc} title="重命名在线文档"
                okText="保存" cancelText="取消"
                onOk={saveRename} onCancel={() => setRenamingDoc(null)} destroyOnHidden>
                <Input value={renameValue} maxLength={200} showCount autoFocus
                    onChange={(event) => setRenameValue(event.target.value)}
                    onPressEnter={saveRename} />
            </Modal>

            {/* Create Modal */}
            <Modal open={createOpen} title="新建在线文档"
                okText="新建" cancelText="取消"
                confirmLoading={creating}
                onOk={saveCreate} onCancel={() => setCreateOpen(false)} destroyOnHidden>
                <div className="space-y-4">
                    <div>
                        <label className="mb-1 block text-xs font-bold text-slate-500">类型</label>
                        <Select className="w-full" value={createType}
                            options={blankTypeOptions.map(item => ({ value: item.value, label: item.label }))}
                            onChange={handleCreateTypeChange} />
                    </div>
                    <div>
                        <label className="mb-1 block text-xs font-bold text-slate-500">名称</label>
                        <Input value={createTitle} maxLength={200} showCount autoFocus
                            onChange={(event) => setCreateTitle(event.target.value)}
                            onPressEnter={saveCreate} />
                    </div>
                </div>
            </Modal>

            {/* Permission Group Manager */}
            <Modal open={groupManagerOpen} title="我的授权组"
                okText="保存组" cancelText="关闭"
                confirmLoading={groupSaving}
                onOk={savePermissionGroup}
                onCancel={closeGroupManager}
                width={860} destroyOnHidden>
                <div className="grid min-h-[420px] grid-cols-[260px_1fr] gap-4">
                    <div className="border-r border-slate-100 pr-4">
                        <div className="mb-3 flex items-center justify-between">
                            <span className="text-xs font-bold text-slate-500">授权组</span>
                            <button type="button" onClick={() => { /* reset via close/open pattern */ }}
                                className="rounded-md px-2 py-1 text-xs font-medium text-[#1677FF] hover:bg-[#E6F4FF]">
                                新建
                            </button>
                        </div>
                        <div className="space-y-1">
                            {groupList.map(group => (
                                <button key={group.id} type="button" onClick={() => editPermissionGroup(group)}
                                    className={`flex w-full items-center justify-between rounded-md px-3 py-2 text-left text-sm transition-colors ${
                                        editingGroupId === group.id ? 'bg-[#E6F4FF] text-[#1677FF]' : 'text-slate-700 hover:bg-slate-50'}`}>
                                    <span className="min-w-0 truncate">{group.name}</span>
                                    <span className="ml-2 shrink-0 text-xs text-slate-400">{group.memberCount}人</span>
                                </button>
                            ))}
                            {groupList.length === 0 && (
                                <div className="py-10 text-center text-sm text-slate-400">暂无授权组</div>
                            )}
                        </div>
                    </div>
                    <div className="space-y-4">
                        <div>
                            <label className="mb-1 block text-xs font-bold text-slate-500">组名称</label>
                            <Input value={groupName} maxLength={100} placeholder="例如：EAST核对组"
                                onChange={(event) => setGroupName(event.target.value)} />
                        </div>
                        <div>
                            <label className="mb-1 block text-xs font-bold text-slate-500">描述</label>
                            <Input value={groupDescription} maxLength={500} placeholder="可选"
                                onChange={(event) => setGroupDescription(event.target.value)} />
                        </div>
                        <div>
                            <label className="mb-1 block text-xs font-bold text-slate-500">成员</label>
                            <Select mode="multiple" allowClear showSearch className="w-full"
                                placeholder="搜索用户加入授权组"
                                value={groupUserIds} searchValue={groupSearchValue}
                                options={groupUserOptions} loading={groupLoading}
                                filterOption={false}
                                onSearch={(value) => { setGroupSearchValue(value); searchGroupUsers(value); }}
                                onChange={(value) => { setGroupUserIds(value); setGroupSearchValue(''); searchGroupUsers('', value); }} />
                        </div>
                        <div className="flex items-center justify-between border-t border-slate-100 pt-3">
                            <span className="text-xs text-slate-400">保存后可在文档授权弹窗中选择该组，组成员会展开为具体授权人员。</span>
                            {editingGroupId && (
                                <button type="button" onClick={() => setGroupDeleteConfirm(editingGroupId)}
                                    className="rounded-md px-2 py-1 text-xs font-medium text-red-600 hover:bg-red-50">
                                    删除组
                                </button>
                            )}
                        </div>
                    </div>
                </div>
            </Modal>

            {/* Permission Modal */}
            <Modal open={!!permissionDoc} title="文档授权"
                okText="保存" cancelText="取消"
                confirmLoading={permissionSaving}
                onOk={handleWrappedSavePermissions}
                onCancel={closePermissions} destroyOnHidden>
                <div className="space-y-3">
                    <div className="text-sm font-medium text-gray-900 truncate">{permissionDoc?.title}</div>
                    <div>
                        <label className="mb-1 block text-xs font-bold text-slate-500">授权组</label>
                        <Select allowClear showSearch className="w-full"
                            placeholder="选择授权组快速添加成员" value={undefined}
                            options={permGroups.map(group => ({
                                value: group.id,
                                label: `${group.name}（${group.memberCount}人）`,
                            }))}
                            filterOption={(input, option) =>
                                String(option?.label ?? '').toLowerCase().includes(input.toLowerCase())}
                            onSelect={applyPermissionGroup} />
                    </div>
                    <Select mode="multiple" allowClear showSearch className="w-full"
                        placeholder="搜索用户并授权"
                        value={permissionUserIds} searchValue={permissionSearchValue}
                        options={permissionOptions} loading={permissionLoading}
                        filterOption={false}
                        onSearch={(value) => { setPermissionSearchValue(value); searchPermissionUsers(value); }}
                        onChange={(value) => { setPermissionUserIds(value); setPermissionSearchValue(''); searchPermissionUsers('', permissionDoc?.userId, value); }} />
                </div>
            </Modal>

            {/* Group Delete Confirm */}
            <Modal open={!!groupDeleteConfirm} title="删除授权组"
                okText="删除" cancelText="取消"
                okButtonProps={{ danger: true }}
                onOk={async () => {
                    if (groupDeleteConfirm) {
                        const { deleteOnlineDocumentPermissionGroup: delGroup } = await import('../../api/onlineDocs');
                        await delGroup(groupDeleteConfirm);
                        message.success('授权组已删除');
                        setGroupDeleteConfirm(null);
                        openGroupManager();
                    }
                }}
                onCancel={() => setGroupDeleteConfirm(null)}>
                确认删除该授权组吗？
            </Modal>

            {/* OnlyOffice Editor */}
            <OnlyOfficeEditorModal open={!!editorDoc} document={editorDoc}
                onClose={() => setEditorDoc(null)}
                onSaved={() => { loadDocuments(); refreshQuickAccess(); }}
                onDownload={handleDownload} />
        </div>
    );
};

export default OnlineDocsTool;
