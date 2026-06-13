import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Empty, Input, Modal, Pagination, Select, Spin, Upload, message } from 'antd';
import type { UploadProps } from 'antd';
import { Download, Edit3, FilePlus2, FileText, RefreshCcw, Search, Trash2, UploadCloud } from 'lucide-react';
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

const blankTypeOptions: { value: BlankDocumentType; label: string; defaultTitle: string }[] = [
    { value: 'word', label: '文字文档', defaultTitle: '新建文档' },
    { value: 'cell', label: '电子表格', defaultTitle: '新建表格' },
    { value: 'slide', label: '演示文稿', defaultTitle: '新建演示' },
];

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

const OnlineDocsTool: React.FC = () => {
    const [documents, setDocuments] = useState<OnlineDocument[]>([]);
    const [keyword, setKeyword] = useState('');
    const [page, setPage] = useState(1);
    const [total, setTotal] = useState(0);
    const [loading, setLoading] = useState(false);
    const [editorDoc, setEditorDoc] = useState<OnlineDocument | null>(null);
    const [renamingDoc, setRenamingDoc] = useState<OnlineDocument | null>(null);
    const [renameValue, setRenameValue] = useState('');
    const [createOpen, setCreateOpen] = useState(false);
    const [createTitle, setCreateTitle] = useState('新建文档');
    const [createType, setCreateType] = useState<BlankDocumentType>('word');
    const [creating, setCreating] = useState(false);

    const loadDocuments = useCallback(async () => {
        setLoading(true);
        try {
            const result = await listOnlineDocuments({
                keyword: keyword || undefined,
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
    }, [keyword, page]);

    useEffect(() => {
        loadDocuments();
    }, [loadDocuments]);

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
        await updateOnlineDocument(renamingDoc.id, {
            title: nextTitle,
        });
        message.success('文档名称已更新');
        setRenamingDoc(null);
        loadDocuments();
    };

    const supportedCount = useMemo(() => documents.filter(doc => isOnlyOfficeSupported(doc.fileName || doc.title)).length, [documents]);

    return (
        <div className="flex h-full flex-col bg-slate-50">
            <div className="flex shrink-0 flex-wrap items-center justify-between gap-3 border-b border-slate-200 bg-white px-5 py-4">
                <div className="flex min-w-0 items-center gap-3">
                    <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-blue-50 text-blue-600">
                        <FileText size={20} />
                    </div>
                    <div className="min-w-0">
                        <h3 className="truncate text-sm font-black text-slate-900">在线文档</h3>
                        <p className="truncate text-xs text-slate-500">独立文档库，支持 ONLYOFFICE 预览、编辑与协同</p>
                    </div>
                </div>
                <div className="flex items-center gap-2">
                    <Input.Search
                        allowClear
                        className="w-64"
                        placeholder="搜索在线文档"
                        prefix={<Search size={14} className="text-slate-400" />}
                        onSearch={handleSearch}
                    />
                    <button
                        onClick={loadDocuments}
                        className="flex h-8 w-8 items-center justify-center rounded-lg border border-slate-200 bg-white text-slate-500 transition-colors hover:border-blue-200 hover:text-blue-600"
                        title="刷新"
                    >
                        <RefreshCcw size={15} />
                    </button>
                    <button
                        onClick={openCreate}
                        className="flex h-8 items-center gap-2 rounded-lg border border-blue-200 bg-blue-50 px-3 text-xs font-bold text-blue-700 transition-colors hover:border-blue-300 hover:bg-blue-100"
                    >
                        <FilePlus2 size={15} />
                        新建
                    </button>
                    <Upload
                        customRequest={handleUpload}
                        showUploadList={false}
                        accept=".doc,.docx,.xls,.xlsx,.ppt,.pptx,.pdf"
                    >
                        <button className="flex h-8 items-center gap-2 rounded-lg bg-blue-600 px-3 text-xs font-bold text-white transition-colors hover:bg-blue-700">
                            <UploadCloud size={15} />
                            上传
                        </button>
                    </Upload>
                </div>
            </div>

            <div className="flex shrink-0 items-center justify-between border-b border-slate-200 bg-white px-5 py-2 text-xs text-slate-500">
                <span>共 {total} 个在线文档</span>
                <span>当前页可在线打开 {supportedCount} 个</span>
            </div>

            <Spin spinning={loading}>
                <div className="min-h-[420px] flex-1 p-5">
                    {documents.length === 0 && !loading ? (
                        <div className="flex h-[420px] items-center justify-center">
                            <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="暂无在线文档" />
                        </div>
                    ) : (
                        <div className="grid grid-cols-1 gap-3 xl:grid-cols-2 2xl:grid-cols-3">
                            {documents.map(doc => (
                                <div
                                    key={doc.id}
                                    className="flex min-w-0 items-center gap-3 rounded-lg border border-slate-200 bg-white p-4 shadow-sm transition-colors hover:border-blue-200"
                                >
                                    <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg bg-slate-100 text-slate-500">
                                        <FileText size={22} />
                                    </div>
                                    <div className="min-w-0 flex-1">
                                        <button
                                            onClick={() => setEditorDoc(doc)}
                                            className="block max-w-full truncate text-left text-sm font-bold text-slate-900 hover:text-blue-600"
                                            title={doc.title}
                                        >
                                            {doc.title}
                                        </button>
                                        <div className="mt-1 flex flex-wrap items-center gap-x-3 gap-y-1 text-[11px] text-slate-500">
                                            <span>{formatFileSize(doc.fileSize)}</span>
                                            <span>{formatTime(doc.updateTime)}</span>
                                        </div>
                                    </div>
                                    <div className="flex shrink-0 items-center gap-1">
                                        <button
                                            onClick={() => setEditorDoc(doc)}
                                            className="rounded-lg p-2 text-slate-500 transition-colors hover:bg-blue-50 hover:text-blue-600"
                                            title="在线打开"
                                        >
                                            <Edit3 size={16} />
                                        </button>
                                        <button
                                            onClick={() => handleDownload(doc)}
                                            className="rounded-lg p-2 text-slate-500 transition-colors hover:bg-slate-100 hover:text-slate-700"
                                            title="下载"
                                        >
                                            <Download size={16} />
                                        </button>
                                        <button
                                            onClick={() => openRename(doc)}
                                            className="rounded-lg p-2 text-slate-500 transition-colors hover:bg-slate-100 hover:text-slate-700"
                                            title="重命名"
                                        >
                                            <FileText size={16} />
                                        </button>
                                        <button
                                            onClick={() => handleDelete(doc)}
                                            className="rounded-lg p-2 text-slate-500 transition-colors hover:bg-red-50 hover:text-red-600"
                                            title="删除"
                                        >
                                            <Trash2 size={16} />
                                        </button>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            </Spin>

            <div className="flex shrink-0 justify-end border-t border-slate-200 bg-white px-5 py-3">
                <Pagination
                    current={page}
                    pageSize={PAGE_SIZE}
                    total={total}
                    showSizeChanger={false}
                    onChange={setPage}
                />
            </div>

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
