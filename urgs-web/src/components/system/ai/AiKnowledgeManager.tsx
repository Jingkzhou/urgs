import React, { useState, useEffect } from 'react';
import { Table, Button, Card, Tag, Space, Modal, Form, Input, Select, message, Drawer, Upload, Tooltip } from 'antd';
import { DatabaseOutlined, PlusOutlined, DeleteOutlined, SearchOutlined, ReloadOutlined, FolderOpenOutlined, UploadOutlined, ThunderboltOutlined, FileOutlined } from '@ant-design/icons';
import { get, post, del } from '../../../utils/request';
import type { UploadFile } from 'antd/es/upload/interface';
import VectorDbDashboard from './VectorDbDashboard';

interface KnowledgeBaseConfig {
    id?: number;
    name: string;
    description?: string;
    collectionName?: string;
    createdAt?: string;
    embeddingModel?: string; // Kept for frontend form, though not in Entity explicitly yet (can be in description or separate)
}

interface KBFile {
    id: number;
    kbId: number;
    fileName: string;
    fileSize: number;
    status: string; // UPLOADED, VECTORIZING, COMPLETED, FAILED
    uploadTime: string;
    vectorTime?: string;
    chunkCount?: number;
    tokenCount?: number;
    errorMessage?: string;
    hitCount?: number;
    priority?: number;
}

const AiKnowledgeManager: React.FC = () => {
    const [kbs, setKbs] = useState<KnowledgeBaseConfig[]>([]);
    const [loading, setLoading] = useState(false);

    // KB Management Modal
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [form] = Form.useForm();

    // File Manager Drawer
    const [isFileDrawerOpen, setIsFileDrawerOpen] = useState(false);
    const [currentKb, setCurrentKb] = useState<KnowledgeBaseConfig | null>(null);
    const [files, setFiles] = useState<KBFile[]>([]);
    const [fileLoading, setFileLoading] = useState(false);
    const [ingesting, setIngesting] = useState(false);
    const [selectedFileKeys, setSelectedFileKeys] = useState<React.Key[]>([]);

    // Vector DB Modal
    const [vectorModalOpen, setVectorModalOpen] = useState(false);
    const [currentVectorCollection, setCurrentVectorCollection] = useState<string | null>(null);

    const fetchKbs = async () => {
        setLoading(true);
        try {
            const data = await get<KnowledgeBaseConfig[]>('/api/ai/knowledge/list');
            setKbs(data || []);
        } catch (e) {
            message.error('获取知识库列表失败');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchKbs();
    }, []);

    // Polling for file statuses if any is VECTORIZING
    useEffect(() => {
        let timer: any;
        if (isFileDrawerOpen && currentKb && files.some(f => f.status === 'VECTORIZING')) {
            timer = setInterval(() => {
                fetchFiles(currentKb.name);
            }, 3000); // Poll every 3 seconds
        }
        return () => {
            if (timer) clearInterval(timer);
        };
    }, [isFileDrawerOpen, currentKb, files]);

    const fetchFiles = async (kbName: string) => {
        setFileLoading(true);
        try {
            const data = await get<KBFile[]>(`/api/ai/knowledge/files`, { kbName });
            setFiles(data || []);
        } catch (e) {
            message.error('获取文件列表失败');
        } finally {
            setFileLoading(false);
        }
    };

    const handleOpenFileManager = (record: KnowledgeBaseConfig) => {
        setCurrentKb(record);
        setIsFileDrawerOpen(true);
        setSelectedFileKeys([]); // Reset selection
        fetchFiles(record.name);
    };

    const handleUpload = async (file: File) => {
        if (!currentKb) return false;

        const formData = new FormData();
        formData.append('file', file);
        formData.append('kbName', currentKb.name);

        try {
            await fetch(`/api/ai/knowledge/files/upload`, {
                method: 'POST',
                body: formData
            });
            message.success('上传成功');
            fetchFiles(currentKb.name);
        } catch (e) {
            message.error('上传失败');
        }
        return false; // Prevent default upload behavior
    };

    const handleDeleteFile = async (kf: KBFile) => {
        if (!currentKb) return;
        try {
            await del(`/api/ai/knowledge/files`, { kbName: currentKb.name, fileName: kf.fileName });
            message.success('删除成功');
            fetchFiles(currentKb.name);
        } catch (e) {
            message.error('删除失败');
        }
    };

    const handleIngestSingleFile = async (kf: KBFile) => {
        if (!currentKb) return;
        setFileLoading(true);
        try {
            const res = await post<any>(`/api/ai/knowledge/files/ingest`, {
                kbName: currentKb.name,
                fileName: kf.fileName
            }, {
                params: { kbName: currentKb.name, fileName: kf.fileName }
            });
            if (res.status === 'success') {
                message.success(`${kf.fileName} 向量化成功`);
            } else {
                message.error(`${kf.fileName} 向量化失败: ${res.message}`);
            }
            fetchFiles(currentKb.name);
        } catch (e: any) {
            message.error(e.message || '触发向量化失败');
            fetchFiles(currentKb.name);
        } finally {
            setFileLoading(false);
        }
    };

    const handleTriggerIngestion = async () => {
        if (!currentKb) return;
        setIngesting(true);
        try {
            const res = await post<any>(`/api/ai/knowledge/ingest?kbName=${currentKb.name}`, {}, {
                params: { kbName: currentKb.name }
            });
            if (res.status === 'success') {
                message.success(res.message);
                fetchFiles(currentKb.name); // Refresh file statuses
            } else {
                message.warning(res.message);
            }
        } catch (e: any) {
            message.error(e.message || '向量化失败');
        } finally {
            setIngesting(false);
        }
    };

    const handleBatchIngest = async () => {
        if (!currentKb || selectedFileKeys.length === 0) return;

        const selectedFileNames = files
            .filter(f => selectedFileKeys.includes(f.id))
            .map(f => f.fileName);

        setIngesting(true);
        try {
            const res = await post<any>(`/api/ai/knowledge/files/batch-ingest`, selectedFileNames, {
                params: { kbName: currentKb.name }
            });
            if (res.status === 'success') {
                message.success(`成功触发 ${selectedFileNames.length} 个文件的向量化`);
                setSelectedFileKeys([]);
                fetchFiles(currentKb.name);
            } else {
                message.error(res.message || '批量任务启动失败');
            }
        } catch (e: any) {
            message.error(e.message || '批量操作异常');
        } finally {
            setIngesting(false);
        }
    };

    const columns = [
        {
            title: '知识库名称 (Collection)',
            dataIndex: 'name',
            key: 'name',
            render: (text: string) => <span className="font-bold">{text}</span>
        },
        {
            title: 'Embedding 模型',
            dataIndex: 'embeddingModel',
            key: 'embeddingModel',
            render: (text: string) => text ? <Tag color="blue">{text}</Tag> : <span className="text-slate-300">-</span>
        },
        {
            title: '描述',
            dataIndex: 'description',
            key: 'description',
            ellipsis: true,
        },
        {
            title: '创建时间',
            dataIndex: 'createdAt',
            key: 'createdAt',
            width: 180,
            className: 'text-slate-500 text-xs',
            render: (text: string) => text ? new Date(text).toLocaleString() : '-'
        },
        {
            title: '操作',
            key: 'actions',
            width: 240,
            align: 'right' as const,
            render: (_: any, record: KnowledgeBaseConfig) => (
                <Space>
                    <Tooltip title="文件管理 & 向量化">
                        <Button
                            type="text"
                            size="small"
                            icon={<FolderOpenOutlined />}
                            className="text-blue-600 hover:text-blue-700"
                            onClick={() => handleOpenFileManager(record)}
                        >
                            管理
                        </Button>
                    </Tooltip>
                    {/* View Vectors Button */}
                    <Tooltip title="查看向量详情">
                        <Button
                            type="text"
                            size="small"
                            icon={<DatabaseOutlined />}
                            className="text-purple-600 hover:text-purple-700"
                            onClick={() => {
                                setCurrentVectorCollection(record.name);
                                setVectorModalOpen(true);
                            }}
                        >
                            预览
                        </Button>
                    </Tooltip>
                    <Tooltip title="重置向量库 (清空数据)">
                        <Button
                            type="text"
                            size="small"
                            icon={<ReloadOutlined />}
                            className="text-amber-600 hover:text-amber-700"
                            onClick={() => handleResetKB(record)}
                        />
                    </Tooltip>
                    <Button
                        type="text"
                        size="small"
                        icon={<DeleteOutlined />}
                        className="text-red-500 hover:text-red-700"
                        onClick={() => handleDelete(record.id!)}
                    />
                </Space>
            )
        }
    ];

    const handleResetKB = (record: KnowledgeBaseConfig) => {
        Modal.confirm({
            title: '确认重置知识库',
            icon: <ReloadOutlined className="text-amber-500" />,
            content: (
                <div>
                    <p>确定要清除知识库 <span className="font-bold text-red-500">{record.name}</span> 下的所有向量数据吗？</p>
                    <p className="text-xs text-slate-500">此操作将清空向量库内容，并将所有文件状态恢复为“已上传”。该操作不可撤销。</p>
                </div>
            ),
            okText: '确认重置',
            okType: 'danger',
            cancelText: '取消',
            onOk: async () => {
                try {
                    setLoading(true);
                    const res = await post<any>(`/api/ai/knowledge/reset`, {}, {
                        params: { kbName: record.name }
                    });
                    if (res.status === 'success') {
                        message.success('知识库已重置');
                    } else {
                        message.error(res.message || '重置失败');
                    }
                } catch (e: any) {
                    message.error(e.message || '操作异常');
                } finally {
                    setLoading(false);
                }
            }
        });
    };

    const handleDelete = (id: number) => {
        Modal.confirm({
            title: '确认删除',
            content: `确定要删除该知识库吗？此操作不可恢复。`,
            okType: 'danger',
            onOk: async () => {
                try {
                    await del(`/api/ai/knowledge/${id}`);
                    message.success('删除成功');
                    fetchKbs();
                } catch (e) {
                    message.error('删除失败');
                }
            }
        });
    };

    const handleSave = async () => {
        try {
            const values = await form.validateFields();
            await post('/api/ai/knowledge/create', {
                name: values.name,
                description: values.description,
                collectionName: values.name,
                embeddingModel: values.embeddingModel
            });
            message.success('创建成功');
            setIsModalOpen(false);
            fetchKbs();
        } catch (e) {
            message.error('创建失败，可能是名称已存在');
        }
    };

    const fileColumns = [
        {
            title: '文件名',
            dataIndex: 'fileName',
            key: 'fileName',
            render: (text: string, record: KBFile) => (
                <Space direction="vertical" size={0}>
                    <Space>
                        <FileOutlined className="text-blue-500" />
                        <span className="font-medium">{text}</span>
                    </Space>
                    {record.errorMessage && (
                        <span className="text-[10px] text-red-400 max-w-[200px] block truncate">
                            {record.errorMessage}
                        </span>
                    )}
                </Space>
            )
        },
        {
            title: '状态',
            dataIndex: 'status',
            key: 'status',
            width: 100,
            render: (status: string) => {
                const statusMap: any = {
                    'UPLOADED': { color: 'default', text: '已上传' },
                    'VECTORIZING': { color: 'processing', text: '处理中' },
                    'COMPLETED': { color: 'success', text: '已入库' },
                    'FAILED': { color: 'error', text: '解析失败' }
                };
                const config = statusMap[status] || statusMap['UPLOADED'];
                return <Tag color={config.color}>{config.text}</Tag>;
            }
        },
        {
            title: '大小',
            dataIndex: 'fileSize',
            key: 'fileSize',
            width: 80,
            render: (size: number) => (size / 1024).toFixed(1) + ' KB'
        },
        {
            title: '统计 (分片)',
            dataIndex: 'chunkCount',
            key: 'chunkCount',
            width: 90,
            render: (count: number) => count !== undefined ? <Tag>{count} Chunks</Tag> : '-'
        },
        {
            title: '命中次数',
            dataIndex: 'hitCount',
            key: 'hitCount',
            width: 80,
            render: (count: number) => (
                <Space>
                    <ThunderboltOutlined className={(count || 0) > 0 ? "text-amber-500" : "text-slate-300"} />
                    <span className={(count || 0) > 0 ? "font-bold text-amber-600" : "text-slate-400"}>
                        {count || 0}
                    </span>
                </Space>
            )
        },
        {
            title: '上传日期',
            dataIndex: 'uploadTime',
            key: 'uploadTime',
            width: 150,
            className: 'text-[11px] text-slate-500',
            render: (time: string) => time ? new Date(time).toLocaleString() : '-'
        },
        {
            title: '向量化日期',
            dataIndex: 'vectorTime',
            key: 'vectorTime',
            width: 150,
            className: 'text-[11px] text-slate-500',
            render: (time: string) => time ? new Date(time).toLocaleString() : '-'
        },
        {
            title: '操作',
            key: 'actions',
            width: 100,
            align: 'right' as const,
            render: (_: any, record: KBFile) => (
                <Space>
                    <Tooltip title={record.status === 'COMPLETED' ? "由于已向量化，建议不要重复操作" : "向量化此文件"}>
                        <Button
                            type="text"
                            size="small"
                            icon={<ThunderboltOutlined />}
                            disabled={record.status === 'VECTORIZING' || record.status === 'COMPLETED'}
                            className={`${record.status === 'COMPLETED' ? 'text-slate-300' : 'text-amber-500'}`}
                            onClick={() => handleIngestSingleFile(record)}
                        />
                    </Tooltip>
                    <Button
                        type="text"
                        danger
                        size="small"
                        icon={<DeleteOutlined />}
                        onClick={() => handleDeleteFile(record)}
                    />
                </Space>
            )
        }
    ];

    return (
        <div className="p-6 bg-slate-50 min-h-[500px]">
            <Card variant="borderless" className="shadow-sm">
                <div className="flex justify-between items-center mb-6">
                    <div>
                        <h3 className="text-lg font-bold text-slate-800 flex items-center gap-2">
                            <DatabaseOutlined className="text-blue-600" /> 知识库管理
                        </h3>
                        <p className="text-slate-500 text-sm mt-1">管理服务器端 Vector DB 中的文档集合与 Embedding 配置</p>
                    </div>
                    <Space>
                        <Button
                            icon={<ReloadOutlined />}
                            onClick={fetchKbs}
                            loading={loading}
                        >
                            刷新
                        </Button>
                        <Button
                            type="primary"
                            icon={<PlusOutlined />}
                            onClick={() => {
                                form.resetFields();
                                form.setFieldsValue({ embeddingModel: 'text-embedding-3-small' });
                                setIsModalOpen(true);
                            }}
                        >
                            新建知识库
                        </Button>
                    </Space>
                </div>

                <div className="mb-4 flex gap-2">
                    <Input prefix={<SearchOutlined className="text-slate-400" />} placeholder="搜索知识库..." className="w-64" />
                </div>

                <Table
                    columns={columns}
                    dataSource={kbs}
                    rowKey="name"
                    loading={loading}
                />
            </Card>

            <Modal
                title="新建知识库"
                open={isModalOpen}
                onCancel={() => setIsModalOpen(false)}
                onOk={handleSave}
                width={600}
            >
                <Form form={form} layout="vertical">
                    <Form.Item
                        name="name"
                        label="知识库名称 (Collection Name)"
                        rules={[
                            { required: true, message: '请输入名称' },
                            { pattern: /^[a-zA-Z0-9_-]+$/, message: '仅支持字母、数字、下划线和连字符' }
                        ]}
                        tooltip="将作为 ChromaDB 的 Collection Name，需保证唯一性"
                    >
                        <Input placeholder="例如: finance_docs_v1" />
                    </Form.Item>
                    <Form.Item name="embeddingModel" label="Embedding 模型" rules={[{ required: true }]}>
                        <Select placeholder="选择 Embedding 模型">
                            <Select.Option value="text-embedding-3-small">text-embedding-3-small (OpenAI)</Select.Option>
                            <Select.Option value="text-embedding-3-large">text-embedding-3-large (OpenAI)</Select.Option>
                            <Select.Option value="bge-m3">BGE-M3 (Local)</Select.Option>
                        </Select>
                    </Form.Item>
                    <Form.Item name="description" label="描述">
                        <Input.TextArea rows={3} placeholder="备注说明" />
                    </Form.Item>
                </Form>
            </Modal>

            <Drawer
                title={`文件管理 - ${currentKb?.name}`}
                size="large"
                open={isFileDrawerOpen}
                onClose={() => setIsFileDrawerOpen(false)}
                extra={
                    <Space>
                        <Upload
                            beforeUpload={(file) => handleUpload(file as any)}
                            showUploadList={false}
                            multiple
                        >
                            <Button icon={<UploadOutlined />}>上传文件</Button>
                        </Upload>
                        <Button
                            icon={<ThunderboltOutlined />}
                            loading={ingesting}
                            disabled={selectedFileKeys.length === 0}
                            onClick={handleBatchIngest}
                        >
                            选择项向量化 ({selectedFileKeys.length})
                        </Button>
                        <Button
                            type="primary"
                            icon={<PlusOutlined />}
                            loading={ingesting}
                            onClick={handleTriggerIngestion}
                        >
                            全库向量化
                        </Button>
                    </Space>
                }
            >
                <div className="mb-4 text-slate-500 text-sm">
                    上传文件到该知识库空间，点击“开始向量化”将文件处理并存入向量数据库。
                </div>
                <Table
                    rowSelection={{
                        selectedRowKeys: selectedFileKeys,
                        onChange: (keys) => setSelectedFileKeys(keys),
                        getCheckboxProps: (record: KBFile) => ({
                            disabled: record.status === 'VECTORIZING' || record.status === 'COMPLETED',
                        }),
                    }}
                    columns={fileColumns}
                    dataSource={files}
                    rowKey="id"
                    loading={fileLoading}
                    pagination={false}
                    size="small"
                />
            </Drawer>

            <Modal
                title={`向量库详情 - ${currentVectorCollection}`}
                open={vectorModalOpen}
                onCancel={() => setVectorModalOpen(false)}
                width={1300}
                footer={null}
                destroyOnClose
                styles={{ body: { padding: 0, height: '80vh', overflow: 'hidden' } }}
            >
                <VectorDbDashboard initialCollection={currentVectorCollection} />
            </Modal>
        </div>
    );
};

export default AiKnowledgeManager;
