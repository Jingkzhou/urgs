import React, { useState, useEffect } from 'react';
import { Table, Button, Modal, Form, Input, Select, InputNumber, message, Space, Tag, Popconfirm, Card, Switch, Tooltip } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, ApiOutlined, StarOutlined, StarFilled, EyeOutlined, EyeInvisibleOutlined } from '@ant-design/icons';

interface AiApiConfig {
    id: number;
    name: string;
    provider: string;
    model: string;
    endpoint: string;
    apiKey: string;
    apiKeyBackup?: string;
    maxTokens: number;
    temperature: number;
    isDefault: number;
    status: number;
    remark?: string;
    createTime?: string;
    totalTokens?: number;    // 累计 Token
    totalRequests?: number;  // 累计请求数
}

interface Provider {
    code: string;
    name: string;
    models: string[];
}

const AiApiManager: React.FC = () => {
    const [configs, setConfigs] = useState<AiApiConfig[]>([]);
    const [providers, setProviders] = useState<Provider[]>([]);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingId, setEditingId] = useState<number | null>(null);
    const [form] = Form.useForm();
    const [loading, setLoading] = useState(false);
    const [testLoading, setTestLoading] = useState(false);
    const [selectedProvider, setSelectedProvider] = useState<string | null>(null);
    const [showApiKey, setShowApiKey] = useState<Record<number, boolean>>({});

    // 获取数据
    const fetchData = async () => {
        try {
            const token = localStorage.getItem('auth_token');
            const [configRes, providerRes] = await Promise.all([
                fetch('/api/ai/config', {
                    headers: { 'Authorization': `Bearer ${token}` }
                }).then(res => res.json()),
                fetch('/api/ai/config/providers', {
                    headers: { 'Authorization': `Bearer ${token}` }
                }).then(res => res.json())
            ]);
            setConfigs(configRes);
            setProviders(providerRes);
        } catch (error) {
            console.error('Failed to fetch data:', error);
            message.error('获取数据失败');
        }
    };

    useEffect(() => {
        fetchData();
    }, []);

    // 打开弹窗
    const handleOpenModal = (record?: AiApiConfig) => {
        form.resetFields();
        if (record) {
            setEditingId(record.id);
            setSelectedProvider(record.provider);
            form.setFieldsValue({
                ...record,
                status: record.status === 1
            });
        } else {
            setEditingId(null);
            setSelectedProvider(null);
            form.setFieldsValue({
                maxTokens: 4096,
                temperature: 0.7,
                status: true
            });
        }
        setIsModalOpen(true);
    };

    // 提供商变化
    const handleProviderChange = (provider: string) => {
        setSelectedProvider(provider);
        const providerInfo = providers.find(p => p.code === provider);
        if (providerInfo && providerInfo.models.length > 0) {
            form.setFieldValue('model', providerInfo.models[0]);
        }
        // 设置默认端点
        const defaultEndpoints: Record<string, string> = {
            openai: 'https://api.openai.com/v1',
            azure: 'https://YOUR_RESOURCE.openai.azure.com',
            anthropic: 'https://api.anthropic.com/v1',
            gemini: 'https://generativelanguage.googleapis.com/v1',
            deepseek: 'https://api.deepseek.com/v1',
            qwen: 'https://dashscope.aliyuncs.com/api/v1',
            glm: 'https://open.bigmodel.cn/api/paas/v4',
            ernie: 'https://aip.baidubce.com',
            moonshot: 'https://api.moonshot.cn/v1',
            ark: 'https://ark.cn-beijing.volces.com/api/v3',
        };
        if (defaultEndpoints[provider]) {
            form.setFieldValue('endpoint', defaultEndpoints[provider]);
        }
    };

    // 测试连接
    const handleTestConnection = async () => {
        try {
            const values = await form.validateFields();
            setTestLoading(true);
            const token = localStorage.getItem('auth_token');

            // 转换 status 布尔值为整数
            const payload = {
                ...values,
                status: values.status ? 1 : 0
            };

            const res = await fetch('/api/ai/config/test', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(payload)
            });
            const data = await res.json();
            if (data.success) {
                message.success('连接测试成功');
            } else {
                message.error(data.message || '连接测试失败');
            }
        } catch (error) {
            message.error('请先填写完整配置');
        } finally {
            setTestLoading(false);
        }
    };

    // 保存
    const handleSave = async () => {
        try {
            const values = await form.validateFields();
            setLoading(true);

            const payload = {
                ...values,
                status: values.status ? 1 : 0
            };

            const url = editingId ? `/api/ai/config/${editingId}` : '/api/ai/config';
            const method = editingId ? 'PUT' : 'POST';

            const token = localStorage.getItem('auth_token');
            const res = await fetch(url, {
                method,
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(payload)
            });

            const data = await res.json();
            if (data.success !== false) {
                message.success(editingId ? '更新成功' : '创建成功');
                setIsModalOpen(false);
                fetchData();
            } else {
                message.error('保存失败');
            }
        } catch (error) {
            console.error('Save failed:', error);
        } finally {
            setLoading(false);
        }
    };

    // 删除
    const handleDelete = async (id: number) => {
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch(`/api/ai/config/${id}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const data = await res.json();
            if (data.success) {
                message.success('删除成功');
                fetchData();
            } else {
                message.error('删除失败');
            }
        } catch (error) {
            console.error('Delete failed:', error);
        }
    };

    // 设置默认
    const handleSetDefault = async (id: number) => {
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch(`/api/ai/config/${id}/default`, {
                method: 'POST',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const data = await res.json();
            if (data.success) {
                message.success('已设为默认配置');
                fetchData();
            } else {
                message.error('操作失败');
            }
        } catch (error) {
            console.error('Set default failed:', error);
        }
    };

    // 获取提供商颜色
    const getProviderColor = (provider: string) => {
        const colors: Record<string, string> = {
            openai: 'green',
            azure: 'blue',
            anthropic: 'orange',
            gemini: 'purple',
            deepseek: 'cyan',
            qwen: 'magenta',
            glm: 'red',
            ernie: 'volcano',
            moonshot: 'gold',
            ark: 'geekblue',
            custom: 'default'
        };
        return colors[provider] || 'default';
    };

    // 表格列
    const columns = [
        {
            title: '配置名称',
            dataIndex: 'name',
            key: 'name',
            render: (text: string, record: AiApiConfig) => (
                <div className="flex items-center gap-2">
                    <span className="font-medium">{text}</span>
                    {record.isDefault === 1 && (
                        <Tag color="gold" icon={<StarFilled />}>默认</Tag>
                    )}
                </div>
            )
        },
        {
            title: 'AI 提供商',
            key: 'provider',
            render: (_: any, record: AiApiConfig) => {
                const provider = providers.find(p => p.code === record.provider);
                return (
                    <Tag color={getProviderColor(record.provider)}>
                        {provider?.name || record.provider}
                    </Tag>
                );
            }
        },
        {
            title: '模型',
            dataIndex: 'model',
            key: 'model',
            render: (text: string) => <code className="text-xs bg-slate-100 px-2 py-1 rounded">{text}</code>
        },
        {
            title: 'API 端点',
            dataIndex: 'endpoint',
            key: 'endpoint',
            ellipsis: true,
            render: (text: string) => (
                <Tooltip title={text}>
                    <span className="text-slate-500 text-xs font-mono">{text}</span>
                </Tooltip>
            )
        },
        {
            title: 'API 密钥',
            key: 'apiKey',
            width: 180,
            render: (_: any, record: AiApiConfig) => (
                <div className="flex items-center gap-2">
                    <code className="text-xs bg-slate-100 px-2 py-1 rounded">
                        {showApiKey[record.id] ? record.apiKey : '••••••••••••'}
                    </code>
                    <Button
                        type="text"
                        size="small"
                        icon={showApiKey[record.id] ? <EyeInvisibleOutlined /> : <EyeOutlined />}
                        onClick={() => setShowApiKey(prev => ({ ...prev, [record.id]: !prev[record.id] }))}
                    />
                </div>
            )
        },
        {
            title: '状态',
            dataIndex: 'status',
            key: 'status',
            width: 80,
            render: (status: number) => (
                <Tag color={status === 1 ? 'success' : 'default'}>
                    {status === 1 ? '启用' : '禁用'}
                </Tag>
            )
        },
        {
            title: '使用统计',
            key: 'usage',
            width: 140,
            render: (_: any, record: AiApiConfig) => (
                <div className="text-xs">
                    <div className="flex items-center gap-1">
                        <span className="text-slate-500">Token:</span>
                        <span className="font-medium text-blue-600">
                            {record.totalTokens ? record.totalTokens.toLocaleString() : '0'}
                        </span>
                    </div>
                    <div className="flex items-center gap-1">
                        <span className="text-slate-500">请求:</span>
                        <span className="font-medium text-green-600">
                            {record.totalRequests || 0} 次
                        </span>
                    </div>
                </div>
            )
        },
        {
            title: '操作',
            key: 'actions',
            align: 'right' as const,
            width: 150,
            render: (_: any, record: AiApiConfig) => (
                <Space>
                    {record.isDefault !== 1 && (
                        <Tooltip title="设为默认">
                            <Button
                                type="text"
                                size="small"
                                icon={<StarOutlined />}
                                onClick={() => handleSetDefault(record.id)}
                                className="text-yellow-500 hover:text-yellow-600"
                            />
                        </Tooltip>
                    )}
                    <Button
                        type="text"
                        size="small"
                        icon={<EditOutlined />}
                        onClick={() => handleOpenModal(record)}
                        className="text-blue-600 hover:text-blue-700"
                    />
                    <Popconfirm title="确定删除此配置?" onConfirm={() => handleDelete(record.id)}>
                        <Button
                            type="text"
                            size="small"
                            icon={<DeleteOutlined />}
                            className="text-red-500 hover:text-red-700"
                        />
                    </Popconfirm>
                </Space>
            )
        }
    ];

    const currentProvider = providers.find(p => p.code === selectedProvider);

    return (
        <div className="ai-api-manager-page min-h-full min-w-0 max-w-full bg-slate-50 p-6">
            <Card variant="borderless" className="ai-api-manager-card shadow-sm">
                <div className="ai-api-manager-header flex min-w-0 flex-wrap justify-between items-center gap-4 mb-4">
                    <h2 className="text-lg font-bold flex items-center gap-2">
                        <ApiOutlined className="text-blue-600" />
                        AI API 配置管理
                    </h2>
                    <Button type="primary" icon={<PlusOutlined />} onClick={() => handleOpenModal()}>
                        新增配置
                    </Button>
                </div>

                <Table
                    columns={columns}
                    dataSource={configs}
                    rowKey="id"
                    pagination={{ pageSize: 10 }}
                />
            </Card>

            <Modal
                rootClassName="ai-api-manager-modal"
                className="ai-api-manager-dialog"
                title={editingId ? "编辑 AI API 配置" : "新增 AI API 配置"}
                open={isModalOpen}
                onCancel={() => setIsModalOpen(false)}
                width={640}
                footer={[
                    <Button key="cancel" onClick={() => setIsModalOpen(false)}>
                        取消
                    </Button>,
                    <Button
                        key="test"
                        icon={<ApiOutlined />}
                        loading={testLoading}
                        onClick={handleTestConnection}
                    >
                        测试连接
                    </Button>,
                    <Button
                        key="submit"
                        type="primary"
                        loading={loading}
                        onClick={handleSave}
                    >
                        保存
                    </Button>
                ]}
            >
                <Form form={form} layout="vertical">
                    <div className="grid grid-cols-2 gap-4">
                        <Form.Item
                            name="name"
                            label="配置名称"
                            rules={[{ required: true, message: '请输入配置名称' }]}
                        >
                            <Input placeholder="例如: 生产环境 GPT-4" />
                        </Form.Item>
                        <Form.Item
                            name="provider"
                            label="AI 提供商"
                            rules={[{ required: true, message: '请选择提供商' }]}
                        >
                            <Select
                                placeholder="选择提供商"
                                onChange={handleProviderChange}
                                options={providers.map(p => ({ label: p.name, value: p.code }))}
                            />
                        </Form.Item>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <Form.Item
                            name="model"
                            label="模型"
                            rules={[{ required: true, message: '请选择或输入模型' }]}
                            extra="可从下拉列表选择，也可直接输入自定义模型名称"
                        >
                            <Select
                                placeholder="选择或输入模型名称"
                                options={currentProvider?.models?.map(m => ({ label: m, value: m })) || []}
                                showSearch
                                allowClear
                                mode={undefined}
                                filterOption={(input, option) =>
                                    (option?.label ?? '').toLowerCase().includes(input.toLowerCase())
                                }
                                dropdownRender={(menu) => (
                                    <>
                                        {menu}
                                        <div className="text-xs text-slate-400 p-2 border-t">
                                            💡 未找到需要的模型？可直接在输入框输入模型名称
                                        </div>
                                    </>
                                )}
                                onSearch={(value) => {
                                    // 允许用户输入任意值
                                    if (value) {
                                        form.setFieldValue('model', value);
                                    }
                                }}
                                onBlur={(e) => {
                                    // 失焦时保留输入的值
                                    const inputValue = (e.target as HTMLInputElement).value;
                                    if (inputValue) {
                                        form.setFieldValue('model', inputValue);
                                    }
                                }}
                            />
                        </Form.Item>
                        <Form.Item
                            name="endpoint"
                            label="API 端点"
                            rules={[{ required: true, message: '请输入 API 端点' }]}
                        >
                            <Input placeholder="https://api.example.com/v1" />
                        </Form.Item>
                    </div>

                    <Form.Item
                        name="apiKey"
                        label="API 密钥"
                        rules={[{ required: true, message: '请输入 API 密钥' }]}
                    >
                        <Input.Password placeholder="sk-xxxxxxxx" />
                    </Form.Item>

                    <Form.Item name="apiKeyBackup" label="备用密钥（可选）">
                        <Input.Password placeholder="备用 API 密钥" />
                    </Form.Item>

                    <div className="grid grid-cols-3 gap-4">
                        <Form.Item name="maxTokens" label="最大 Token">
                            <InputNumber min={100} max={128000} className="w-full" />
                        </Form.Item>
                        <Form.Item name="temperature" label="温度参数">
                            <InputNumber min={0} max={2} step={0.1} className="w-full" />
                        </Form.Item>
                        <Form.Item name="status" label="状态" valuePropName="checked">
                            <Switch checkedChildren="启用" unCheckedChildren="禁用" />
                        </Form.Item>
                    </div>

                    <Form.Item name="remark" label="备注">
                        <Input.TextArea rows={2} placeholder="可选备注信息" />
                    </Form.Item>
                </Form>
            </Modal>
        </div>
    );
};

export default AiApiManager;
