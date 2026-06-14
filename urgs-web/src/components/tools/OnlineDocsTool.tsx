import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Dropdown, Empty, Input, Modal, Pagination, Select, Spin, Table, Upload, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import type { UploadProps } from 'antd';
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
    Presentation,
    RefreshCcw,
    Search,
    SlidersHorizontal,
    Trash2,
    UploadCloud,
} from 'lucide-react';
import type { OnlineDocument } from '../../api/onlineDocs';
import {
    createBlankOnlineDocument,
    createOnlineDocument,
    deleteOnlineDocument,
    listOnlineDocuments,
    updateOnlineDocument,
    uploadOnlineDocumentFile,
} from '../../api/onlineDocs';
import OnlyOfficeEditorModal, { isOnlyOfficeSupported } from './OnlyOfficeEditorModal';

const PAGE_SIZE = 12;
type BlankDocumentType = 'word' | 'cell' | 'slide';
type TabKey = 'recent' | 'space' | 'favorite';

const blankTypeOptions: { value: BlankDocumentType; label: string; defaultTitle: string }[] = [
    { value: 'word', label: '文字文档', defaultTitle: '新建文档' },
    { value: 'cell', label: '电子表格', defaultTitle: '新建表格' },
    { value: 'slide', label: '演示文稿', defaultTitle: '新建演示' },
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

type FileTypeKey = 'word' | 'excel' | 'ppt' | 'pdf' | 'other';

const getFileTypeKey = (fileName?: string): FileTypeKey => {
    if (!fileName) return 'other';
    const ext = fileName.split('.').pop()?.toLowerCase() || '';
    if (['doc', 'docx'].includes(ext)) return 'word';
    if (['xls', 'xlsx'].includes(ext)) return 'excel';
    if (['ppt', 'pptx'].includes(ext)) return 'ppt';
    if (ext === 'pdf') return 'pdf';
    return 'other';
};

const fileTypeConfig: Record<FileTypeKey, { icon: React.FC<{ size?: number }>; color: string; bg: string }> = {
    word: { icon: FileText, color: '#1677FF', bg: '#E6F4FF' },
    excel: { icon: FileSpreadsheet, color: '#52C41A', bg: '#F6FFED' },
    ppt: { icon: Presentation, color: '#FA8C16', bg: '#FFF7E6' },
    pdf: { icon: FileType, color: '#FF4D4F', bg: '#FFF1F0' },
    other: { icon: FileText, color: '#8C8C8C', bg: '#FAFAFA' },
};

// ---- component ----

const OnlineDocsTool: React.FC = () => {
    // data
    const [documents, setDocuments] = useState<OnlineDocument[]>([]);
    const [keyword, setKeyword] = useState('');
    const [page, setPage] = useState(1);
    const [total, setTotal] = useState(0);
    const [loading, setLoading] = useState(false);

    // editor & modals
    const [editorDoc, setEditorDoc] = useState<OnlineDocument | null>(null);
    const [renamingDoc, setRenamingDoc] = useState<OnlineDocument | null>(null);
    const [renameValue, setRenameValue] = useState('');
    const [createOpen, setCreateOpen] = useState(false);
    const [createTitle, setCreateTitle] = useState('新建文档');
    const [createType, setCreateType] = useState<BlankDocumentType>('word');
    const [creating, setCreating] = useState(false);

    // ui state
    const [activeTab, setActiveTab] = useState<TabKey>('recent');
    const [viewMode, setViewMode] = useState<'list' | 'grid'>('list');
    const [filterType, setFilterType] = useState<string>('all');

    // ---- data loading ----

    const loadDocuments = useCallback(async () => {
        if (activeTab !== 'recent') return;
        setLoading(true);
        try {
            const result = await listOnlineDocuments({
                keyword: keyword || undefined,
                fileType: filterType === 'all' ? undefined : filterType,
                page,
                size: PAGE_SIZE,
            });
            setDocuments(result.records || []);
            setTotal(result.total || 0);
        } catch {
            message.error('在线文档加载失败');
        } finally {
            setLoading(false);
        }
    }, [keyword, page, activeTab, filterType]);

    useEffect(() => {
        loadDocuments();
    }, [loadDocuments]);

    // ---- actions ----

    const handleUpload: UploadProps['customRequest'] = async (options) => {
        const file = options.file as File;
        if (!isOnlyOfficeSupported(file.name)) {
            message.warning('仅支持 doc、docx、xls、xlsx、ppt、pptx、pdf 文件');
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
            loadDocuments();
        } catch (error) {
            options.onError?.(error as Error);
            message.error('在线文档上传失败');
        }
    };

    const handleSearch = (value: string) => {
        setKeyword(value.trim());
        setPage(1);
        setFilterType('all');
    };

    const handleDownload = (doc: OnlineDocument) => {
        window.open(doc.fileUrl, '_blank');
    };

    const handleDelete = (doc: OnlineDocument) => {
        Modal.confirm({
            title: '删除在线文档',
            content: `确认删除「${doc.title}」吗？`,
            okText: '删除',
            okButtonProps: { danger: true },
            cancelText: '取消',
            onOk: async () => {
                await deleteOnlineDocument(doc.id);
                message.success('在线文档已删除');
                loadDocuments();
            },
        });
    };

    const openRename = (doc: OnlineDocument) => {
        setRenamingDoc(doc);
        setRenameValue(doc.title);
    };

    const openCreate = () => {
        setCreateType('word');
        setCreateTitle('新建文档');
        setCreateOpen(true);
    };

    const handleCreateTypeChange = (value: BlankDocumentType) => {
        setCreateType(value);
        const option = blankTypeOptions.find(item => item.value === value);
        setCreateTitle(option?.defaultTitle || '新建文档');
    };

    const saveCreate = async () => {
        const title = createTitle.trim();
        if (!title) {
            message.warning('请输入文档名称');
            return;
        }
        setCreating(true);
        try {
            const doc = await createBlankOnlineDocument({
                title,
                documentType: createType,
            });
            message.success('在线文档已新建');
            setCreateOpen(false);
            if (page === 1) {
                await loadDocuments();
            } else {
                setPage(1);
            }
            setEditorDoc(doc);
        } catch {
            message.error('在线文档新建失败');
        } finally {
            setCreating(false);
        }
    };

    const saveRename = async () => {
        if (!renamingDoc) return;
        const nextTitle = renameValue.trim();
        if (!nextTitle) {
            message.warning('请输入文档名称');
            return;
        }
        await updateOnlineDocument(renamingDoc.id, { title: nextTitle });
        message.success('文档名称已更新');
        setRenamingDoc(null);
        loadDocuments();
    };

    const handleCopyLink = (doc: OnlineDocument) => {
        navigator.clipboard.writeText(doc.fileUrl).then(() => {
            message.success('链接已复制');
        }).catch(() => {
            message.error('复制失败');
        });
    };

    // ---- derived ----

    const quickAccessDocs = useMemo(() => documents.slice(0, 4), [documents]);
    const supportedCount = useMemo(
        () => documents.filter(doc => isOnlyOfficeSupported(doc.fileName || doc.title)).length,
        [documents],
    );

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
                        <span
                            className="flex h-8 w-8 shrink-0 items-center justify-center rounded-md"
                            style={{ backgroundColor: ft.bg, color: ft.color }}
                        >
                            <Icon size={18} />
                        </span>
                        <span className="text-sm font-medium text-gray-900 truncate group-hover/name:text-[#1677FF] transition-colors">
                            {record.title}
                        </span>
                    </div>
                );
            },
        },
        {
            title: '所有者',
            dataIndex: 'userId',
            key: 'owner',
            width: '12%',
            render: () => <span className="text-sm text-gray-500">我</span>,
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
                    <button
                        onClick={(e) => { e.stopPropagation(); handleCopyLink(record); }}
                        className="flex h-7 w-7 items-center justify-center rounded-md text-gray-400 transition-colors hover:bg-gray-100 hover:text-[#1677FF]"
                        title="复制链接"
                    >
                        <Copy size={14} />
                    </button>
                    <Dropdown
                        menu={{
                            items: [
                                { key: 'edit', icon: <Edit3 size={14} />, label: '在线打开', onClick: () => setEditorDoc(record) },
                                { key: 'download', icon: <Download size={14} />, label: '下载', onClick: () => handleDownload(record) },
                                { key: 'rename', icon: <FileText size={14} />, label: '重命名', onClick: () => openRename(record) },
                                { type: 'divider' },
                                { key: 'delete', icon: <Trash2 size={14} />, label: '删除', danger: true, onClick: () => handleDelete(record) },
                            ],
                        }}
                        trigger={['click']}
                    >
                        <button
                            onClick={(e) => e.stopPropagation()}
                            className="flex h-7 w-7 items-center justify-center rounded-md text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600"
                            title="更多操作"
                        >
                            <MoreHorizontal size={14} />
                        </button>
                    </Dropdown>
                </div>
            ),
        },
    ], []);

    // ---- grid view card ----

    const renderGridCard = (doc: OnlineDocument) => {
        const ft = fileTypeConfig[getFileTypeKey(doc.fileName)];
        const Icon = ft.icon;
        return (
            <div
                key={doc.id}
                onClick={() => setEditorDoc(doc)}
                className="group/card flex flex-col rounded-xl border border-gray-100 bg-white p-4 transition-all hover:border-[#1677FF]/30 hover:shadow-md cursor-pointer"
            >
                {/* file icon area */}
                <div
                    className="flex items-center justify-center h-28 rounded-lg mb-3"
                    style={{ backgroundColor: ft.bg }}
                >
                    <span style={{ color: ft.color }}>
                        <Icon size={40} />
                    </span>
                </div>
                {/* file name */}
                <div className="text-sm font-medium text-gray-900 truncate" title={doc.title}>
                    {doc.title}
                </div>
                {/* meta */}
                <div className="text-xs text-gray-400 mt-1">
                    {formatTime(doc.updateTime)}
                </div>
                {/* actions */}
                <div className="flex items-center gap-1 mt-3 opacity-0 group-hover/card:opacity-100 transition-opacity">
                    <button
                        onClick={(e) => { e.stopPropagation(); handleCopyLink(doc); }}
                        className="flex h-7 w-7 items-center justify-center rounded-md text-gray-400 transition-colors hover:bg-gray-100 hover:text-[#1677FF]"
                        title="复制链接"
                    >
                        <Copy size={14} />
                    </button>
                    <Dropdown
                        menu={{
                            items: [
                                { key: 'edit', icon: <Edit3 size={14} />, label: '在线打开', onClick: () => setEditorDoc(doc) },
                                { key: 'download', icon: <Download size={14} />, label: '下载', onClick: () => handleDownload(doc) },
                                { key: 'rename', icon: <FileText size={14} />, label: '重命名', onClick: () => openRename(doc) },
                                { type: 'divider' },
                                { key: 'delete', icon: <Trash2 size={14} />, label: '删除', danger: true, onClick: () => handleDelete(doc) },
                            ],
                        }}
                        trigger={['click']}
                    >
                        <button
                            onClick={(e) => e.stopPropagation()}
                            className="flex h-7 w-7 items-center justify-center rounded-md text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600"
                            title="更多操作"
                        >
                            <MoreHorizontal size={14} />
                        </button>
                    </Dropdown>
                </div>
            </div>
        );
    };

    // ---- tab content ----

    const renderTabContent = () => {
        if (activeTab !== 'recent') {
            return (
                <div className="flex items-center justify-center h-[420px]">
                    <Empty
                        image={Empty.PRESENTED_IMAGE_SIMPLE}
                        description={activeTab === 'space' ? '空间功能开发中' : '收藏功能开发中'}
                    />
                </div>
            );
        }

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
                rowKey="id"
                columns={columns}
                dataSource={documents}
                loading={loading}
                pagination={false}
                showHeader={true}
                size="middle"
                className="online-docs-table"
                rowClassName="group/row"
                locale={{ emptyText: '暂无文档' }}
                onRow={(record) => ({
                    onDoubleClick: () => setEditorDoc(record),
                    style: { cursor: 'pointer' },
                })}
            />
        );
    };

    // ---- tabs config ----

    const tabs: { key: TabKey; label: string }[] = [
        { key: 'recent', label: '最近' },
        { key: 'space', label: '空间' },
        { key: 'favorite', label: '收藏' },
    ];

    // ---- render ----

    return (
        <div className="flex h-full flex-col bg-white">
            {/* ===== Quick Access Bar ===== */}
            {quickAccessDocs.length > 0 && (
                <div className="shrink-0 border-b border-gray-100 bg-white px-6 py-4">
                    <div className="text-xs font-medium text-gray-400 mb-3 uppercase tracking-wide">快速访问</div>
                    <div className="flex flex-wrap gap-3">
                        {quickAccessDocs.map(doc => {
                            const ft = fileTypeConfig[getFileTypeKey(doc.fileName)];
                            const Icon = ft.icon;
                            return (
                                <button
                                    key={doc.id}
                                    onClick={() => setEditorDoc(doc)}
                                    className="flex items-center gap-2.5 rounded-lg border border-gray-200 bg-white px-3.5 py-2.5 text-sm transition-all hover:border-[#1677FF]/30 hover:shadow-sm hover:-translate-y-0.5"
                                    title={doc.title}
                                >
                                    <span
                                        className="flex h-6 w-6 shrink-0 items-center justify-center rounded"
                                        style={{ backgroundColor: ft.bg, color: ft.color }}
                                    >
                                        <Icon size={14} />
                                    </span>
                                    <span className="text-gray-700 max-w-[160px] truncate text-left">{doc.title}</span>
                                </button>
                            );
                        })}
                    </div>
                </div>
            )}

            {/* ===== Tab Navigation + Toolbar ===== */}
            <div className="flex shrink-0 items-center justify-between border-b border-gray-100 bg-white px-6">
                {/* Tabs */}
                <div className="flex items-center gap-0">
                    {tabs.map(tab => (
                        <button
                            key={tab.key}
                            onClick={() => { setActiveTab(tab.key); setPage(1); setFilterType('all'); }}
                            className={`relative px-5 py-3 text-sm font-medium transition-colors ${
                                activeTab === tab.key
                                    ? 'text-[#1677FF]'
                                    : 'text-gray-500 hover:text-gray-700'
                            }`}
                        >
                            {tab.label}
                            {activeTab === tab.key && (
                                <span className="absolute bottom-0 left-1/2 -translate-x-1/2 w-5 h-0.5 bg-[#1677FF] rounded-full" />
                            )}
                        </button>
                    ))}
                </div>

                {/* Toolbar */}
                <div className="flex items-center gap-2">
                    <Input.Search
                        allowClear
                        className="w-56"
                        placeholder="搜索在线文档"
                        prefix={<Search size={14} className="text-gray-400" />}
                        onSearch={handleSearch}
                        size="small"
                    />
                    <button
                        onClick={loadDocuments}
                        className="flex h-7 w-7 items-center justify-center rounded-md text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600"
                        title="刷新"
                    >
                        <RefreshCcw size={14} />
                    </button>
                    <button
                        onClick={openCreate}
                        className="flex h-7 items-center gap-1.5 rounded-md border border-[#1677FF]/20 bg-[#E6F4FF] px-2.5 text-xs font-medium text-[#1677FF] transition-colors hover:border-[#1677FF]/40 hover:bg-[#BAE0FF]"
                    >
                        <FilePlus2 size={14} />
                        新建
                    </button>
                    <Upload
                        customRequest={handleUpload}
                        showUploadList={false}
                        accept=".doc,.docx,.xls,.xlsx,.ppt,.pptx,.pdf"
                    >
                        <button className="flex h-7 items-center gap-1.5 rounded-md bg-[#1677FF] px-2.5 text-xs font-medium text-white transition-colors hover:bg-[#4096FF]">
                            <UploadCloud size={14} />
                            上传
                        </button>
                    </Upload>

                    {/* Divider */}
                    <span className="w-px h-5 bg-gray-200 mx-1" />

                    {/* View mode toggle */}
                    <button
                        onClick={() => setViewMode(viewMode === 'list' ? 'grid' : 'list')}
                        className="flex h-7 w-7 items-center justify-center rounded-md text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600"
                        title={viewMode === 'list' ? '切换为网格视图' : '切换为列表视图'}
                    >
                        {viewMode === 'list' ? <LayoutList size={15} /> : <Grid3X3 size={15} />}
                    </button>

                    {/* Filter */}
                    <Dropdown
                        menu={{
                            selectedKeys: [filterType],
                            onClick: ({ key }) => {
                                setFilterType(key);
                                setPage(1);
                            },
                            items: [
                                { key: 'all', label: '全部文档' },
                                { key: 'word', label: '文字文档' },
                                { key: 'excel', label: '电子表格' },
                                { key: 'ppt', label: '演示文稿' },
                                { key: 'pdf', label: 'PDF 文档' },
                            ],
                        }}
                        trigger={['click']}
                    >
                        <button className="flex h-7 items-center gap-1 rounded-md border border-gray-200 bg-white px-2 text-xs text-gray-500 transition-colors hover:border-gray-300 hover:text-gray-700">
                            <SlidersHorizontal size={13} />
                            筛选
                        </button>
                    </Dropdown>
                </div>
            </div>

            {/* ===== Info Bar ===== */}
            {activeTab === 'recent' && (
                <div className="flex shrink-0 items-center justify-between bg-[#FAFAFA] px-6 py-1.5 text-xs text-gray-400 border-b border-gray-100">
                    <span>共 {total} 个文档</span>
                    <span>{supportedCount} 个支持在线编辑</span>
                </div>
            )}

            {/* ===== Main Content ===== */}
            <Spin spinning={loading && activeTab === 'recent'}>
                <div className="flex-1 min-h-0 overflow-auto px-6 py-3">
                    {renderTabContent()}
                </div>
            </Spin>

            {/* ===== Pagination ===== */}
            {activeTab === 'recent' && total > PAGE_SIZE && (
                <div className="flex shrink-0 justify-end border-t border-gray-100 bg-white px-6 py-3">
                    <Pagination
                        current={page}
                        pageSize={PAGE_SIZE}
                        total={total}
                        showSizeChanger={false}
                        showQuickJumper={false}
                        onChange={setPage}
                        size="small"
                    />
                </div>
            )}

            {/* ===== Modals ===== */}

            {/* Rename Modal */}
            <Modal
                open={!!renamingDoc}
                title="重命名在线文档"
                okText="保存"
                cancelText="取消"
                onOk={saveRename}
                onCancel={() => setRenamingDoc(null)}
                destroyOnHidden
            >
                <Input
                    value={renameValue}
                    maxLength={200}
                    showCount
                    autoFocus
                    onChange={(event) => setRenameValue(event.target.value)}
                    onPressEnter={saveRename}
                />
            </Modal>

            {/* Create Modal */}
            <Modal
                open={createOpen}
                title="新建在线文档"
                okText="新建"
                cancelText="取消"
                confirmLoading={creating}
                onOk={saveCreate}
                onCancel={() => setCreateOpen(false)}
                destroyOnHidden
            >
                <div className="space-y-4">
                    <div>
                        <label className="mb-1 block text-xs font-bold text-slate-500">类型</label>
                        <Select
                            className="w-full"
                            value={createType}
                            options={blankTypeOptions.map(item => ({ value: item.value, label: item.label }))}
                            onChange={handleCreateTypeChange}
                        />
                    </div>
                    <div>
                        <label className="mb-1 block text-xs font-bold text-slate-500">名称</label>
                        <Input
                            value={createTitle}
                            maxLength={200}
                            showCount
                            autoFocus
                            onChange={(event) => setCreateTitle(event.target.value)}
                            onPressEnter={saveCreate}
                        />
                    </div>
                </div>
            </Modal>

            {/* OnlyOffice Editor */}
            <OnlyOfficeEditorModal
                open={!!editorDoc}
                document={editorDoc}
                onClose={() => setEditorDoc(null)}
                onSaved={loadDocuments}
                onDownload={handleDownload}
            />
        </div>
    );
};

export default OnlineDocsTool;
