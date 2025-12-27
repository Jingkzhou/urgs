import React, { useState, useEffect, useCallback } from 'react';
import {
    Layout,
    Tree,
    Input,
    Button,
    Card,
    List,
    Tag,
    Space,
    Modal,
    Form,
    message,
    Dropdown,
    Empty,
    Spin,
    Tooltip,
    Popconfirm,
    Upload,
    Segmented,
} from 'antd';
import {
    FolderOutlined,
    FolderOpenOutlined,
    FileTextOutlined,
    FileOutlined,
    PlusOutlined,
    SearchOutlined,
    StarOutlined,
    StarFilled,
    EditOutlined,
    DeleteOutlined,
    UploadOutlined,
    TagsOutlined,
    ClockCircleOutlined,
    EyeOutlined,
    MoreOutlined,
    HomeOutlined,
} from '@ant-design/icons';
import type { DataNode } from 'antd/es/tree';
import type { UploadProps } from 'antd';
import * as api from '../../api/knowledge';
import type {
    FolderTreeNode,
    KnowledgeDocument,
    KnowledgeTag,
    DocumentDetail,
} from '../../api/knowledge';

const { Sider, Content } = Layout;
const { Search } = Input;
const { TextArea } = Input;

// 简易 Markdown 编辑器组件
const MarkdownEditor: React.FC<{
    value?: string;
    onChange?: (value: string) => void;
    placeholder?: string;
}> = ({ value = '', onChange, placeholder }) => {
    return (
        <TextArea
            value={value}
            onChange={(e) => onChange?.(e.target.value)}
            placeholder={placeholder}
            autoSize={{ minRows: 15, maxRows: 30 }}
            style={{ fontFamily: 'monospace' }}
        />
    );
};

// 简易 Markdown 渲染组件
const MarkdownPreview: React.FC<{ content: string }> = ({ content }) => {
    // 简单的 Markdown 转 HTML（仅支持基础语法）
    const renderMarkdown = (md: string) => {
        let html = md
            .replace(/^### (.*$)/gim, '<h3>$1</h3>')
            .replace(/^## (.*$)/gim, '<h2>$1</h2>')
            .replace(/^# (.*$)/gim, '<h1>$1</h1>')
            .replace(/\*\*(.*)\*\*/gim, '<strong>$1</strong>')
            .replace(/\*(.*)\*/gim, '<em>$1</em>')
            .replace(/`([^`]+)`/gim, '<code>$1</code>')
            .replace(/\n/gim, '<br/>');
        return html;
    };

    return (
        <div
            className="markdown-preview"
            dangerouslySetInnerHTML={{ __html: renderMarkdown(content) }}
            style={{ padding: '16px', lineHeight: 1.8 }}
        />
    );
};

const KnowledgeCenter: React.FC = () => {
    // 状态
    const [folders, setFolders] = useState<FolderTreeNode[]>([]);
    const [documents, setDocuments] = useState<KnowledgeDocument[]>([]);
    const [tags, setTags] = useState<KnowledgeTag[]>([]);
    const [selectedFolder, setSelectedFolder] = useState<number | null>(null);
    const [selectedDocument, setSelectedDocument] = useState<DocumentDetail | null>(null);
    const [loading, setLoading] = useState(false);
    const [searchKeyword, setSearchKeyword] = useState('');
    const [viewMode, setViewMode] = useState<'list' | 'edit'>('list');
    const [currentPage, setCurrentPage] = useState(1);
    const [total, setTotal] = useState(0);

    // 弹窗状态
    const [folderModalOpen, setFolderModalOpen] = useState(false);
    const [documentModalOpen, setDocumentModalOpen] = useState(false);
    const [tagModalOpen, setTagModalOpen] = useState(false);
    const [editingFolder, setEditingFolder] = useState<FolderTreeNode | null>(null);
    const [editingDocument, setEditingDocument] = useState<KnowledgeDocument | null>(null);

    // 表单
    const [folderForm] = Form.useForm();
    const [documentForm] = Form.useForm();
    const [tagForm] = Form.useForm();

    // 加载数据
    const loadFolders = useCallback(async () => {
        try {
            const data = await api.getFolderTree();
            setFolders(data);
        } catch (error) {
            console.error('加载文件夹失败:', error);
        }
    }, []);

    const loadDocuments = useCallback(async () => {
        setLoading(true);
        try {
            const result = await api.listDocuments({
                folderId: selectedFolder ?? undefined,
                keyword: searchKeyword || undefined,
                page: currentPage,
                size: 20,
            });
            setDocuments(result.records || []);
            setTotal(result.total || 0);
        } catch (error) {
            console.error('加载文档失败:', error);
            setDocuments([]);
        } finally {
            setLoading(false);
        }
    }, [selectedFolder, searchKeyword, currentPage]);

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

    // 文件夹树转换为 Ant Design Tree 格式
    const convertToTreeData = (nodes: FolderTreeNode[]): DataNode[] => {
        return nodes.map((node) => ({
            key: node.id,
            title: node.name,
            icon: <FolderOutlined />,
            children: node.children ? convertToTreeData(node.children) : [],
        }));
    };

    // 文件夹操作
    const handleCreateFolder = async (values: { name: string }) => {
        try {
            await api.createFolder({
                name: values.name,
                parentId: editingFolder ? editingFolder.id : selectedFolder ?? undefined,
            });
            message.success('文件夹创建成功');
            setFolderModalOpen(false);
            folderForm.resetFields();
            loadFolders();
        } catch (error) {
            message.error('创建失败');
        }
    };

    const handleDeleteFolder = async (id: number) => {
        try {
            await api.deleteFolder(id);
            message.success('删除成功');
            if (selectedFolder === id) {
                setSelectedFolder(null);
            }
            loadFolders();
        } catch (error) {
            message.error('删除失败');
        }
    };

    // 文档操作
    const handleCreateDocument = () => {
        setEditingDocument(null);
        documentForm.resetFields();
        documentForm.setFieldsValue({
            docType: 'markdown',
            folderId: selectedFolder,
        });
        setDocumentModalOpen(true);
    };

    const handleEditDocument = async (doc: KnowledgeDocument) => {
        try {
            const detail = await api.getDocument(doc.id);
            setEditingDocument(doc);
            documentForm.setFieldsValue({
                title: doc.title,
                docType: doc.docType,
                content: doc.content,
                folderId: doc.folderId,
                tagIds: detail.tags.map((t) => t.id),
            });
            setDocumentModalOpen(true);
        } catch (error) {
            message.error('加载文档失败');
        }
    };

    const handleSaveDocument = async (values: any) => {
        try {
            if (editingDocument) {
                await api.updateDocument(editingDocument.id, values);
                message.success('更新成功');
            } else {
                await api.createDocument(values);
                message.success('创建成功');
            }
            setDocumentModalOpen(false);
            documentForm.resetFields();
            loadDocuments();
        } catch (error) {
            message.error('保存失败');
        }
    };

    const handleDeleteDocument = async (id: number) => {
        try {
            await api.deleteDocument(id);
            message.success('删除成功');
            loadDocuments();
        } catch (error) {
            message.error('删除失败');
        }
    };

    const handleToggleFavorite = async (doc: KnowledgeDocument) => {
        try {
            const result = await api.toggleFavorite(doc.id);
            message.success(result.favorite ? '已收藏' : '已取消收藏');
            loadDocuments();
        } catch (error) {
            message.error('操作失败');
        }
    };

    const handleViewDocument = async (doc: KnowledgeDocument) => {
        try {
            const detail = await api.getDocument(doc.id);
            setSelectedDocument(detail);
            setViewMode('edit');
        } catch (error) {
            message.error('加载文档失败');
        }
    };

    // 标签操作
    const handleCreateTag = async (values: { name: string; color: string }) => {
        try {
            await api.createTag(values);
            message.success('标签创建成功');
            setTagModalOpen(false);
            tagForm.resetFields();
            loadTags();
        } catch (error) {
            message.error('创建失败');
        }
    };

    const handleDeleteTag = async (id: number) => {
        try {
            await api.deleteTag(id);
            message.success('删除成功');
            loadTags();
        } catch (error) {
            message.error('删除失败');
        }
    };

    // 文件上传配置
    const uploadProps: UploadProps = {
        name: 'file',
        action: '/api/common/upload',
        onChange(info) {
            if (info.file.status === 'done') {
                const { url, name } = info.file.response;
                documentForm.setFieldsValue({
                    docType: 'file',
                    fileUrl: url,
                    fileName: name,
                    fileSize: info.file.size,
                    title: name,
                });
                message.success('文件上传成功');
            } else if (info.file.status === 'error') {
                message.error('文件上传失败');
            }
        },
    };

    // 渲染文档列表项
    const renderDocumentItem = (doc: KnowledgeDocument) => (
        <List.Item
            key={doc.id}
            className="document-item"
            style={{
                padding: '12px 16px',
                cursor: 'pointer',
                borderRadius: 8,
                marginBottom: 8,
                background: '#fafafa',
                transition: 'all 0.2s',
            }}
            onClick={() => handleViewDocument(doc)}
            actions={[
                <Tooltip title={doc.isFavorite ? '取消收藏' : '收藏'} key="favorite">
                    <Button
                        type="text"
                        size="small"
                        icon={doc.isFavorite ? <StarFilled style={{ color: '#faad14' }} /> : <StarOutlined />}
                        onClick={(e) => {
                            e.stopPropagation();
                            handleToggleFavorite(doc);
                        }}
                    />
                </Tooltip>,
                <Tooltip title="编辑" key="edit">
                    <Button
                        type="text"
                        size="small"
                        icon={<EditOutlined />}
                        onClick={(e) => {
                            e.stopPropagation();
                            handleEditDocument(doc);
                        }}
                    />
                </Tooltip>,
                <Popconfirm
                    key="delete"
                    title="确定删除此文档？"
                    onConfirm={(e) => {
                        e?.stopPropagation();
                        handleDeleteDocument(doc.id);
                    }}
                    onCancel={(e) => e?.stopPropagation()}
                >
                    <Button
                        type="text"
                        size="small"
                        danger
                        icon={<DeleteOutlined />}
                        onClick={(e) => e.stopPropagation()}
                    />
                </Popconfirm>,
            ]}
        >
            <List.Item.Meta
                avatar={
                    doc.docType === 'markdown' ? (
                        <FileTextOutlined style={{ fontSize: 24, color: '#1890ff' }} />
                    ) : (
                        <FileOutlined style={{ fontSize: 24, color: '#52c41a' }} />
                    )
                }
                title={<span style={{ fontWeight: 500 }}>{doc.title}</span>}
                description={
                    <Space size={16}>
                        <span>
                            <ClockCircleOutlined /> {new Date(doc.updateTime).toLocaleDateString()}
                        </span>
                        <span>
                            <EyeOutlined /> {doc.viewCount}
                        </span>
                        {doc.docType === 'file' && doc.fileSize && (
                            <span>{(doc.fileSize / 1024).toFixed(1)} KB</span>
                        )}
                    </Space>
                }
            />
        </List.Item>
    );

    return (
        <Layout style={{ minHeight: '100vh', background: '#f5f5f5' }}>
            {/* 左侧边栏 - 文件夹树 */}
            <Sider
                width={280}
                style={{
                    background: '#fff',
                    borderRight: '1px solid #f0f0f0',
                    padding: '16px 0',
                }}
            >
                <div style={{ padding: '0 16px', marginBottom: 16 }}>
                    <h3 style={{ margin: 0, marginBottom: 12 }}>📚 知识中心</h3>
                    <Button
                        type="dashed"
                        block
                        icon={<PlusOutlined />}
                        onClick={() => {
                            setEditingFolder(null);
                            folderForm.resetFields();
                            setFolderModalOpen(true);
                        }}
                    >
                        新建文件夹
                    </Button>
                </div>

                {/* 快捷入口 */}
                <div style={{ padding: '0 16px', marginBottom: 16 }}>
                    <div
                        style={{
                            padding: '8px 12px',
                            cursor: 'pointer',
                            borderRadius: 6,
                            background: selectedFolder === null ? '#e6f7ff' : 'transparent',
                        }}
                        onClick={() => setSelectedFolder(null)}
                    >
                        <HomeOutlined /> 全部文档
                    </div>
                </div>

                {/* 文件夹树 */}
                <div style={{ padding: '0 8px' }}>
                    <Tree
                        showIcon
                        defaultExpandAll
                        selectedKeys={selectedFolder ? [selectedFolder] : []}
                        treeData={convertToTreeData(folders)}
                        onSelect={(keys) => {
                            setSelectedFolder(keys[0] as number || null);
                        }}
                        titleRender={(node) => (
                            <Dropdown
                                menu={{
                                    items: [
                                        {
                                            key: 'rename',
                                            label: '重命名',
                                            icon: <EditOutlined />,
                                        },
                                        {
                                            key: 'delete',
                                            label: '删除',
                                            icon: <DeleteOutlined />,
                                            danger: true,
                                            onClick: () => handleDeleteFolder(node.key as number),
                                        },
                                    ],
                                }}
                                trigger={['contextMenu']}
                            >
                                <span>{node.title as string}</span>
                            </Dropdown>
                        )}
                    />
                </div>

                {/* 标签列表 */}
                <div style={{ padding: '16px', borderTop: '1px solid #f0f0f0', marginTop: 16 }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                        <span><TagsOutlined /> 标签</span>
                        <Button type="text" size="small" icon={<PlusOutlined />} onClick={() => setTagModalOpen(true)} />
                    </div>
                    <Space wrap>
                        {tags.map((tag) => (
                            <Tag
                                key={tag.id}
                                color={tag.color}
                                closable
                                onClose={() => handleDeleteTag(tag.id)}
                            >
                                {tag.name}
                            </Tag>
                        ))}
                    </Space>
                </div>
            </Sider>

            {/* 主内容区 */}
            <Content style={{ padding: 24 }}>
                {viewMode === 'list' ? (
                    <>
                        {/* 工具栏 */}
                        <Card style={{ marginBottom: 16 }} bodyStyle={{ padding: '12px 16px' }}>
                            <Space style={{ width: '100%', justifyContent: 'space-between' }}>
                                <Space>
                                    <Button type="primary" icon={<PlusOutlined />} onClick={handleCreateDocument}>
                                        新建文档
                                    </Button>
                                    <Upload {...uploadProps} showUploadList={false}>
                                        <Button icon={<UploadOutlined />}>上传文件</Button>
                                    </Upload>
                                </Space>
                                <Search
                                    placeholder="搜索文档..."
                                    allowClear
                                    style={{ width: 300 }}
                                    value={searchKeyword}
                                    onChange={(e) => setSearchKeyword(e.target.value)}
                                    onSearch={() => loadDocuments()}
                                />
                            </Space>
                        </Card>

                        {/* 文档列表 */}
                        <Card>
                            <Spin spinning={loading}>
                                {documents.length > 0 ? (
                                    <List
                                        dataSource={documents}
                                        renderItem={renderDocumentItem}
                                        pagination={{
                                            current: currentPage,
                                            total,
                                            pageSize: 20,
                                            onChange: setCurrentPage,
                                            showTotal: (t) => `共 ${t} 个文档`,
                                        }}
                                    />
                                ) : (
                                    <Empty description="暂无文档" />
                                )}
                            </Spin>
                        </Card>
                    </>
                ) : (
                    /* 文档查看/编辑模式 */
                    <Card
                        title={
                            <Space>
                                <Button type="text" onClick={() => setViewMode('list')}>
                                    ← 返回列表
                                </Button>
                                <span>{selectedDocument?.document.title}</span>
                            </Space>
                        }
                        extra={
                            <Space>
                                {selectedDocument?.tags.map((tag) => (
                                    <Tag key={tag.id} color={tag.color}>
                                        {tag.name}
                                    </Tag>
                                ))}
                            </Space>
                        }
                    >
                        {selectedDocument?.document.docType === 'markdown' ? (
                            <MarkdownPreview content={selectedDocument.document.content || ''} />
                        ) : (
                            <div style={{ textAlign: 'center', padding: 40 }}>
                                <FileOutlined style={{ fontSize: 64, color: '#52c41a' }} />
                                <p>{selectedDocument?.document.fileName}</p>
                                <Button type="primary" href={selectedDocument?.document.fileUrl || ''} target="_blank">
                                    下载文件
                                </Button>
                            </div>
                        )}
                    </Card>
                )}
            </Content>

            {/* 新建/编辑文件夹弹窗 */}
            <Modal
                title={editingFolder ? '编辑文件夹' : '新建文件夹'}
                open={folderModalOpen}
                onCancel={() => setFolderModalOpen(false)}
                onOk={() => folderForm.submit()}
            >
                <Form form={folderForm} layout="vertical" onFinish={handleCreateFolder}>
                    <Form.Item name="name" label="文件夹名称" rules={[{ required: true, message: '请输入文件夹名称' }]}>
                        <Input placeholder="请输入文件夹名称" />
                    </Form.Item>
                </Form>
            </Modal>

            {/* 新建/编辑文档弹窗 */}
            <Modal
                title={editingDocument ? '编辑文档' : '新建文档'}
                open={documentModalOpen}
                onCancel={() => setDocumentModalOpen(false)}
                onOk={() => documentForm.submit()}
                width={800}
            >
                <Form form={documentForm} layout="vertical" onFinish={handleSaveDocument}>
                    <Form.Item name="title" label="标题" rules={[{ required: true, message: '请输入标题' }]}>
                        <Input placeholder="请输入文档标题" />
                    </Form.Item>
                    <Form.Item name="docType" label="类型" initialValue="markdown">
                        <Segmented
                            options={[
                                { label: 'Markdown 文档', value: 'markdown' },
                                { label: '文件附件', value: 'file' },
                            ]}
                        />
                    </Form.Item>
                    <Form.Item noStyle shouldUpdate={(prev, cur) => prev.docType !== cur.docType}>
                        {({ getFieldValue }) =>
                            getFieldValue('docType') === 'markdown' ? (
                                <Form.Item name="content" label="内容">
                                    <MarkdownEditor placeholder="请输入 Markdown 内容..." />
                                </Form.Item>
                            ) : (
                                <Form.Item label="上传文件">
                                    <Upload {...uploadProps}>
                                        <Button icon={<UploadOutlined />}>选择文件</Button>
                                    </Upload>
                                </Form.Item>
                            )
                        }
                    </Form.Item>
                    <Form.Item name="tagIds" label="标签">
                        <Space wrap>
                            {tags.map((tag) => (
                                <Tag.CheckableTag
                                    key={tag.id}
                                    checked={documentForm.getFieldValue('tagIds')?.includes(tag.id)}
                                    onChange={(checked) => {
                                        const current = documentForm.getFieldValue('tagIds') || [];
                                        documentForm.setFieldsValue({
                                            tagIds: checked
                                                ? [...current, tag.id]
                                                : current.filter((id: number) => id !== tag.id),
                                        });
                                    }}
                                    style={{ border: `1px solid ${tag.color}`, borderRadius: 4 }}
                                >
                                    {tag.name}
                                </Tag.CheckableTag>
                            ))}
                        </Space>
                    </Form.Item>
                </Form>
            </Modal>

            {/* 新建标签弹窗 */}
            <Modal
                title="新建标签"
                open={tagModalOpen}
                onCancel={() => setTagModalOpen(false)}
                onOk={() => tagForm.submit()}
            >
                <Form form={tagForm} layout="vertical" onFinish={handleCreateTag}>
                    <Form.Item name="name" label="标签名称" rules={[{ required: true, message: '请输入标签名称' }]}>
                        <Input placeholder="请输入标签名称" />
                    </Form.Item>
                    <Form.Item name="color" label="颜色" initialValue="#1890ff">
                        <Input type="color" style={{ width: 100, height: 32 }} />
                    </Form.Item>
                </Form>
            </Modal>
        </Layout>
    );
};

export default KnowledgeCenter;
