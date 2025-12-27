import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
    Input,
    Button,
    Card,
    Tag,
    Space,
    Modal,
    Form,
    message,
    Dropdown,
    Empty,
    Spin,
    Tooltip,
    Upload,
    Segmented,
    Breadcrumb,
} from 'antd';
import {
    Folder,
    File,
    Star,
    Plus,
    Search,
    Trash2,
    Upload as UploadIcon,
    Tags,
    ChevronLeft,
    MoreVertical,
    FolderPlus,
    ArrowLeft,
    LayoutGrid,
    List as ListIcon,
} from 'lucide-react';
import type { UploadProps } from 'antd';
import * as api from '../../api/knowledge';

import type {
    FolderTreeNode,
    KnowledgeDocument,
    KnowledgeTag,
} from '../../api/knowledge';

const KnowledgeCenter: React.FC = () => {
    // 状态
    const [folders, setFolders] = useState<FolderTreeNode[]>([]);
    const [documents, setDocuments] = useState<KnowledgeDocument[]>([]);
    const [tags, setTags] = useState<KnowledgeTag[]>([]);
    const [selectedFolderId, setSelectedFolderId] = useState<number | null>(null);
    const [loading, setLoading] = useState(false);
    const [searchKeyword, setSearchKeyword] = useState('');
    const [layoutMode, setLayoutMode] = useState<'grid' | 'list'>('grid');

    // 弹窗状态
    const [folderModalOpen, setFolderModalOpen] = useState(false);
    const [tagModalOpen, setTagModalOpen] = useState(false);
    const [editingFolder, setEditingFolder] = useState<FolderTreeNode | null>(null);

    // 表单
    const [folderForm] = Form.useForm();
    const [tagForm] = Form.useForm();

    // 加载文件夹
    const loadFolders = useCallback(async () => {
        try {
            const data = await api.getFolderTree();
            setFolders(data);
        } catch (error) {
            console.error('加载文件夹失败:', error);
        }
    }, []);

    // 加载文档
    const loadDocuments = useCallback(async () => {
        setLoading(true);
        try {
            const result = await api.listDocuments({
                folderId: selectedFolderId ?? undefined,
                keyword: searchKeyword || undefined,
                page: 1,
                size: 200,
            });
            setDocuments(result.records || []);
        } catch (error) {
            console.error('加载文档失败:', error);
            setDocuments([]);
        } finally {
            setLoading(false);
        }
    }, [selectedFolderId, searchKeyword]);

    const loadTags = useCallback(async () => {
        try {
            const data = await api.listTags();
            setTags(data);
        } catch (error) {
            console.error('加载标签失败:', error);
        }
    }, []);

    useEffect(() => {
        loadFolders();
        loadTags();
    }, [loadFolders, loadTags]);

    useEffect(() => {
        loadDocuments();
    }, [loadDocuments]);

    // 计算当前路径和面包屑
    const currentBreadcrumbs = useMemo(() => {
        const path: Array<{ id: number | null, name: string }> = [{ id: null, name: '根目录' }];
        if (!selectedFolderId) return path;

        const resultPath: Array<{ id: number, name: string }> = [];
        const findFullPath = (nodes: FolderTreeNode[], targetId: number, acc: Array<{ id: number, name: string }>) => {
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

        findFullPath(folders, selectedFolderId, []);
        return [...path, ...resultPath];
    }, [folders, selectedFolderId]);

    // 获取当前文件夹下的子文件夹
    const currentSubFolders = useMemo(() => {
        if (!selectedFolderId) return folders;

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

        const currentNode = findNode(folders, selectedFolderId);
        return currentNode?.children || [];
    }, [folders, selectedFolderId]);

    // 交互操作
    const handleFolderDoubleClick = (id: number) => {
        setSelectedFolderId(id);
    };

    const handleBack = () => {
        if (currentBreadcrumbs.length > 1) {
            const parent = currentBreadcrumbs[currentBreadcrumbs.length - 2];
            setSelectedFolderId(parent.id);
        }
    };

    // 文件夹操作
    const onSaveFolder = async (values: { name: string }) => {
        try {
            if (editingFolder) {
                await api.updateFolder(editingFolder.id, { name: values.name });
                message.success('重命名成功');
            } else {
                await api.createFolder({
                    name: values.name,
                    parentId: selectedFolderId ?? undefined,
                });
                message.success('文件夹创建成功');
            }
            setFolderModalOpen(false);
            folderForm.resetFields();
            loadFolders();
        } catch (error) {
            message.error('操作失败');
        }
    };

    const onDeleteFolder = async (id: number) => {
        try {
            await api.deleteFolder(id);
            message.success('删除成功');
            loadFolders();
        } catch (error) {
            message.error('删除失败');
        }
    };

    const handleDeleteDocument = async (id: number) => {
        try {
            await api.deleteDocument(id);
            message.success('附件已删除');
            loadDocuments();
        } catch (error) {
            message.error('删除失败');
        }
    }

    const onToggleFavorite = async (e: React.MouseEvent, doc: KnowledgeDocument) => {
        e.stopPropagation();
        try {
            const result = await api.toggleFavorite(doc.id);
            message.success(result.favorite ? '已收藏' : '已取消收藏');
            loadDocuments();
        } catch (error) {
            message.error('操作失败');
        }
    };

    // 文件上传配置
    const uploadProps: UploadProps = {
        name: 'file',
        action: '/api/common/upload',
        showUploadList: false,
        headers: {
            Authorization: `Bearer ${localStorage.getItem('auth_token')}`,
        },
        onChange(info) {
            if (info.file.status === 'done') {
                const { url, name } = info.file.response;
                api.createDocument({
                    title: name,
                    fileUrl: url,
                    fileName: name,
                    fileSize: info.file.size,
                    folderId: selectedFolderId ?? undefined,
                }).then(() => {
                    message.success('文件上传成功');
                    loadDocuments();
                });
            } else if (info.file.status === 'error') {
                message.error('文件上传失败');
            }
        },
    };

    // 桌面图标组件
    const ItemEntry = ({
        type,
        title,
        id,
        doc,
        onEnter
    }: {
        type: 'folder' | 'doc',
        title: string,
        id: number,
        doc?: KnowledgeDocument,
        onEnter: () => void
    }) => {
        const isDoc = type === 'doc';
        const isGrid = layoutMode === 'grid';
        const isFavorite = doc?.isFavorite === 1;

        const handleDownload = () => {
            if (isDoc) {
                if (doc?.fileUrl) {
                    const link = document.createElement('a');
                    link.href = doc.fileUrl;
                    link.download = doc.fileName || doc.title;
                    document.body.appendChild(link);
                    link.click();
                    document.body.removeChild(link);
                }
            } else {
                // 文件夹打包下载
                const url = api.getFolderDownloadUrl(id);
                const link = document.createElement('a');
                link.href = url;
                link.setAttribute('download', `${title}.zip`);
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
                message.loading('正在打包文件夹...', 2);
            }
        };

        const menuItems = [
            { key: 'open', label: '打开', onClick: onEnter },
            { key: 'download', label: isDoc ? '下载' : '打包下载', onClick: handleDownload },
            {
                key: 'edit',
                label: '重命名',
                onClick: () => {
                    if (!isDoc) {
                        setEditingFolder({ id, name: title } as any);
                        folderForm.setFieldsValue({ name: title });
                        setFolderModalOpen(true);
                    } else {
                        message.info('暂不支持重命名附件');
                    }
                }
            },
            { key: 'favorite', label: isFavorite ? '取消收藏' : '添加收藏', onClick: (e: any) => onToggleFavorite(e, doc!) },
            { key: 'delete', label: '删除', danger: true, onClick: () => isDoc ? handleDeleteDocument(id) : onDeleteFolder(id) },
        ];

        if (isGrid) {
            return (
                <Dropdown menu={{ items: menuItems }} trigger={['contextMenu']}>
                    <div
                        className="flex flex-col items-center p-2 rounded-lg cursor-pointer transition-all hover:bg-slate-200 group relative"
                        style={{ width: 100, height: 110 }}
                        onDoubleClick={onEnter}
                    >
                        <div className="mb-2 relative">
                            {isDoc ? (
                                <div className="w-14 h-14 bg-emerald-50 rounded-xl flex items-center justify-center text-emerald-500 shadow-sm group-hover:shadow-md transition-shadow">
                                    <File size={32} />
                                </div>
                            ) : (
                                <div className="w-14 h-14 bg-amber-50 rounded-xl flex items-center justify-center text-amber-500 shadow-sm group-hover:shadow-md transition-shadow">
                                    <Folder size={32} className="fill-amber-500/20" />
                                </div>
                            )}
                            {isFavorite && (
                                <div className="absolute -top-1 -right-1 bg-white rounded-full shadow-sm">
                                    <Star size={14} className="text-amber-500 fill-amber-500" />
                                </div>
                            )}
                        </div>
                        <span className="text-xs text-center line-clamp-2 px-1 break-all text-slate-700 font-medium group-hover:text-slate-900 leading-tight">
                            {title}
                        </span>
                    </div>
                </Dropdown>
            );
        }

        return (
            <Dropdown menu={{ items: menuItems }} trigger={['contextMenu']}>
                <div
                    className="flex items-center px-4 py-2 hover:bg-blue-50 cursor-pointer border-b border-slate-100 group text-sm"
                    onDoubleClick={onEnter}
                >
                    <div className="w-8 flex-shrink-0">
                        {isDoc ? (
                            <File size={18} className="text-emerald-500" />
                        ) : (
                            <Folder size={18} className="text-amber-400 fill-amber-400" />
                        )}
                    </div>
                    <div className="flex-1 truncate font-medium text-slate-700 group-hover:text-blue-600 mr-4">
                        {title}
                    </div>
                    <div className="w-32 text-slate-400 text-xs text-center">
                        {isDoc ? '附件' : '文件夹'}
                    </div>
                    <div className="w-44 text-slate-400 text-xs">
                        {isDoc ? new Date(doc.updateTime).toLocaleString() : '-'}
                    </div>
                    <div className="w-24 text-slate-400 text-xs text-right">
                        {isDoc && doc.fileSize ? `${(doc.fileSize / 1024).toFixed(1)} KB` : '-'}
                    </div>
                    <div className="w-10 flex justify-end ml-4">
                        {isFavorite && <Star size={14} className="text-amber-500 fill-amber-500" />}
                    </div>
                </div>
            </Dropdown>
        );
    };

    return (
        <div className="flex flex-col h-full bg-slate-50 overflow-hidden font-sans">
            {/* 顶部工具栏 & 面包屑 */}
            <header className="h-14 bg-white border-b border-slate-200 flex items-center px-4 justify-between flex-shrink-0">
                <div className="flex items-center gap-4">
                    <Button
                        icon={<ArrowLeft size={16} />}
                        disabled={selectedFolderId === null}
                        onClick={handleBack}
                        type="text"
                        className="hover:bg-slate-100"
                    />
                    <Breadcrumb
                        className="text-sm font-medium"
                        items={currentBreadcrumbs.map((b) => ({
                            title: b.name,
                            onClick: () => setSelectedFolderId(b.id),
                            className: "cursor-pointer hover:text-blue-600 transition-colors"
                        }))}
                    />
                </div>

                <div className="flex items-center gap-2">
                    <Input
                        prefix={<Search size={14} className="text-slate-400" />}
                        placeholder="搜索文件..."
                        className="w-48 sm:w-64 rounded-full bg-slate-100 border-none px-4"
                        value={searchKeyword}
                        onChange={e => setSearchKeyword(e.target.value)}
                    />
                    <Space size={8} className="ml-2">
                        <Upload {...uploadProps}>
                            <Button type="primary" icon={<UploadIcon size={18} />} className="bg-emerald-600 hover:bg-emerald-700 border-none">
                                上传文件
                            </Button>
                        </Upload>
                        <Button icon={<FolderPlus size={18} />} onClick={() => { setEditingFolder(null); folderForm.resetFields(); setFolderModalOpen(true); }}>
                            新建文件夹
                        </Button>
                        <div className="w-px h-6 bg-slate-200 mx-1"></div>
                        <Segmented
                            value={layoutMode}
                            onChange={val => setLayoutMode(val as any)}
                            options={[
                                { value: 'grid', icon: <LayoutGrid size={14} /> },
                                { value: 'list', icon: <ListIcon size={14} /> },
                            ]}
                        />
                    </Space>
                </div>
            </header>

            {/* 图标展示区 */}
            <main className="flex-1 overflow-auto bg-white flex flex-col relative">
                {layoutMode === 'list' && (currentSubFolders.length > 0 || documents.length > 0) && (
                    <div className="flex items-center px-4 py-2 border-b border-slate-200 bg-slate-50 text-[11px] font-bold text-slate-400 uppercase tracking-wider sticky top-0 z-10">
                        <div className="w-8"></div>
                        <div className="flex-1">名称</div>
                        <div className="w-32 text-center">类型</div>
                        <div className="w-44">最后修改</div>
                        <div className="w-24 text-right">大小</div>
                        <div className="w-10 ml-4"></div>
                    </div>
                )}

                <div className="flex-1 overflow-auto p-4 relative">
                    <Spin spinning={loading}>
                        {(currentSubFolders.length === 0 && documents.length === 0) ? (
                            <div className="h-full flex items-center justify-center py-20">
                                <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="这是一个空文件夹" />
                            </div>
                        ) : (
                            <div className={layoutMode === 'grid' ? "flex flex-wrap gap-4 content-start" : "flex flex-col"}>
                                {/* 文件夹 */}
                                {currentSubFolders.map(f => (
                                    <ItemEntry
                                        key={`folder-${f.id}`}
                                        type="folder"
                                        title={f.name}
                                        id={f.id}
                                        onEnter={() => handleFolderDoubleClick(f.id)}
                                    />
                                ))}
                                {/* 文档 */}
                                {documents.map(d => (
                                    <ItemEntry
                                        key={`doc-${d.id}`}
                                        type="doc"
                                        title={d.title}
                                        id={d.id}
                                        doc={d}
                                        onEnter={() => handleDownloadItem(d)}
                                    />
                                ))}
                            </div>
                        )}
                    </Spin>
                </div>

                {/* 底部信息栏 */}
                <div className="fixed bottom-4 left-1/2 -translate-x-1/2 bg-white/80 backdrop-blur shadow-lg border border-slate-200 rounded-full px-4 py-1.5 flex items-center gap-4 text-[10px] text-slate-500 uppercase tracking-widest font-bold z-20">
                    <span>{documents.length + currentSubFolders.length} 个项目</span>
                    <div className="w-1 h-1 bg-slate-300 rounded-full"></div>
                    <span className="flex items-center gap-1 cursor-pointer hover:text-blue-500" onClick={() => setTagModalOpen(true)}>
                        <Tags size={10} /> 标签管理
                    </span>
                </div>
            </main>

            {/* 新建文件夹 Modal */}
            <Modal
                title={editingFolder ? '重命名文件夹' : '新建文件夹'}
                open={folderModalOpen}
                onCancel={() => setFolderModalOpen(false)}
                onOk={() => folderForm.submit()}
                destroyOnClose
            >
                <Form form={folderForm} layout="vertical" onFinish={onSaveFolder}>
                    <Form.Item name="name" label="名称" rules={[{ required: true, message: '请输入名称' }]}>
                        <Input placeholder="文件夹名称" autoFocus />
                    </Form.Item>
                </Form>
            </Modal>

            {/* 标签管理弹窗 */}
            <Modal
                title="标签管理"
                open={tagModalOpen}
                onCancel={() => setTagModalOpen(false)}
                footer={null}
            >
                <div className="mb-6">
                    <Form form={tagForm} layout="inline" onFinish={async (v) => {
                        await api.createTag(v);
                        tagForm.resetFields();
                        loadTags();
                    }}>
                        <Form.Item name="name" rules={[{ required: true }]} style={{ flex: 1 }}>
                            <Input placeholder="新标签名称" />
                        </Form.Item>
                        <Form.Item name="color" initialValue="#3b82f6">
                            <Input type="color" className="w-12 p-0 h-8 border-none" />
                        </Form.Item>
                        <Form.Item>
                            <Button type="primary" htmlType="submit" icon={<Plus size={14} />} />
                        </Form.Item>
                    </Form>
                </div>
                <div className="flex flex-wrap gap-2">
                    {tags.map(t => (
                        <Tag
                            key={t.id}
                            color={t.color}
                            closable
                            onClose={() => api.deleteTag(t.id).then(loadTags)}
                            className="px-3 py-1 rounded-full border-none shadow-sm"
                        >
                            {t.name}
                        </Tag>
                    ))}
                </div>
            </Modal>
        </div>
    );

    function handleDownloadItem(doc: KnowledgeDocument) {
        if (doc.fileUrl) {
            const link = document.createElement('a');
            link.href = doc.fileUrl;
            link.download = doc.fileName || doc.title;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
    }
};

export default KnowledgeCenter;
