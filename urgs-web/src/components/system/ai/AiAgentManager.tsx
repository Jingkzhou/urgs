
import React, { useState, useEffect } from 'react';
import { Table, Button, Card, Tag, Space, Modal, Form, Input, Switch, message, Segmented, Checkbox } from 'antd';
import { RobotOutlined, PlusOutlined, EditOutlined, DeleteOutlined, SearchOutlined } from '@ant-design/icons';
import { get, post, del, put } from '../../../utils/request';

interface RecommendedPrompt {
    title: string;
    content: string;
}

interface AgentConfig {
    id: number;
    name: string;
    description?: string;
    systemPrompt?: string;
    status: number;
    prompts?: any; // String from backend, parsed to RecommendedPrompt[] in frontend
    buildMode?: string;
    difyApiKey?: string;
    difyApiBase?: string;
    agentAppTools?: string[] | string;
    updatedAt: string;
}

const AiAgentManager: React.FC = () => {
    const [agents, setAgents] = useState<AgentConfig[]>([]);
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        fetchAgents();
    }, []);

    const fetchAgents = async () => {
        setLoading(true);
        try {
            const data = await get<AgentConfig[]>('/api/ai/agent/list');
            if (data) {
                // Parse prompts from JSON string if necessary
                const parsedData = data.map(agent => ({
                    ...agent,
                    prompts: typeof agent.prompts === 'string' ? JSON.parse(agent.prompts) : agent.prompts
                }));
                setAgents(parsedData);
            }
        } catch (e) {
            message.error('获取助手列表失败');
        } finally {
            setLoading(false);
        }
    };

    const [isModalOpen, setIsModalOpen] = useState(false);
    const [form] = Form.useForm();
    const [editingId, setEditingId] = useState<number | null>(null);
    const buildMode = Form.useWatch('buildMode', form) || 'DIRECT';

    const parseJsonArray = (value: any) => {
        if (!value) return [];
        if (Array.isArray(value)) return value;
        if (typeof value !== 'string') return [];
        try {
            return JSON.parse(value);
        } catch (e) {
            return [];
        }
    };

    const inferBuildMode = (agent: AgentConfig) => {
        const normalizedMode = typeof agent.buildMode === 'string' ? agent.buildMode.trim().toUpperCase() : '';
        if (normalizedMode === 'DIRECT' || normalizedMode === 'DIFY' || normalizedMode === 'AGENT_APP') return normalizedMode;
        if (agent.difyApiKey) return 'DIFY';
        return 'DIRECT';
    };

    const columns = [
        {
            title: '助手名称',
            dataIndex: 'name',
            key: 'name',
            render: (text: string) => <span className="font-bold">{text}</span>
        },
        {
            title: '构建方式',
            dataIndex: 'buildMode',
            key: 'buildMode',
            width: 120,
            render: (_: string, record: AgentConfig) => {
                const mode = inferBuildMode(record);
                const modeMeta = {
                    DIRECT: { label: '模型直连', color: 'green' },
                    DIFY: { label: 'Dify 引擎', color: 'blue' },
                    AGENT_APP: { label: 'Agent App', color: 'purple' }
                }[mode] || { label: mode || '未知', color: 'default' };
                return <Tag color={modeMeta.color}>{modeMeta.label}</Tag>;
            }
        },
        {
            title: '描述',
            dataIndex: 'description',
            key: 'description',
            ellipsis: true,
        },

        {
            title: '状态',
            dataIndex: 'status',
            key: 'status',
            render: (status: number) => (
                <Tag color={status === 1 ? 'success' : 'default'}>
                    {status === 1 ? '启用' : '禁用'}
                </Tag>
            )
        },
        {
            title: '更新时间',
            dataIndex: 'updatedAt',
            key: 'updatedAt',
            width: 180,
            className: 'text-slate-500 text-xs',
            render: (text: string) => text ? new Date(text).toLocaleString() : '-'
        },
        {
            title: '操作',
            key: 'actions',
            width: 150,
            align: 'right' as const,
            render: (_: any, record: AgentConfig) => (
                <Space>
                    <Button
                        type="text"
                        size="small"
                        icon={<EditOutlined />}
                        className="text-blue-600 hover:text-blue-700"
                        onClick={() => handleEdit(record)}
                    />
                    <Button
                        type="text"
                        size="small"
                        icon={<DeleteOutlined />}
                        className="text-red-500 hover:text-red-700"
                        onClick={() => handleDelete(record.id)}
                    />
                </Space>
            )
        }
    ];

    const handleEdit = (record: AgentConfig) => {
        setEditingId(record.id);
        form.setFieldsValue({
            ...record,
            buildMode: inferBuildMode(record),
            status: record.status === 1,
            prompts: typeof record.prompts === 'string' ? JSON.parse(record.prompts) : record.prompts,
            agentAppTools: parseJsonArray(record.agentAppTools)
        });
        setIsModalOpen(true);
    };

    const handleDelete = (id: number) => {
        Modal.confirm({
            title: '确认删除',
            content: '确定要删除该助手吗？',
            okType: 'danger',
            onOk: async () => {
                try {
                    await del(`/api/ai/agent/${id}`);
                    message.success('删除成功');
                    fetchAgents();
                } catch (e) {
                    message.error('删除失败');
                }
            }
        });
    };

    const handleSave = async () => {
        try {
            const values = await form.validateFields();
            const payload = {
                ...values,
                status: values.status ? 1 : 0,
                prompts: JSON.stringify(values.prompts || []),
                agentAppTools: JSON.stringify(values.agentAppTools || [])
            };

            if (payload.buildMode === 'DIFY') {
                payload.agentAppTools = JSON.stringify([]);
            } else if (payload.buildMode === 'AGENT_APP') {
                payload.difyApiKey = undefined;
                payload.difyApiBase = undefined;
            } else if (payload.buildMode === 'DIRECT') {
                payload.difyApiKey = undefined;
                payload.difyApiBase = undefined;
                payload.agentAppTools = JSON.stringify([]);
            }

            if (editingId) {
                await put(`/api/ai/agent/${editingId}`, payload);
                message.success('更新成功');
            } else {
                await post('/api/ai/agent/create', payload);
                message.success('创建成功');
            }
            setIsModalOpen(false);
            fetchAgents();
        } catch (e) {
            console.error(e);
            message.error('保存失败');
        }
    };

    return (
        <div className="ai-agent-manager-page min-w-0 p-6 bg-slate-50 min-h-[500px]">
            <Card variant="borderless" className="ai-agent-manager-card shadow-sm">
                <div className="ai-agent-manager-header flex min-w-0 flex-wrap justify-between items-center gap-4 mb-6">
                    <div>
                        <h3 className="text-lg font-bold text-slate-800 flex items-center gap-2">
                            <RobotOutlined className="text-purple-600" /> 智能体助手管理
                        </h3>
                        <p className="text-slate-500 text-sm mt-1">配置业务场景下的智能体提示词与模型参数</p>
                    </div>
                    <Button
                        type="primary"
                        className="ai-agent-manager-create shrink-0"
                        icon={<PlusOutlined />}
                        onClick={() => {
                            setEditingId(null);
                            form.resetFields();
                            form.setFieldsValue({ buildMode: 'DIRECT', status: true, prompts: [], agentAppTools: [] });
                            setIsModalOpen(true);
                        }}
                    >
                        新建助手
                    </Button>
                </div>

                <div className="ai-agent-manager-search mb-4 flex min-w-0 flex-wrap gap-2">
                    <Input prefix={<SearchOutlined className="text-slate-400" />} placeholder="搜索助手名称或描述" className="ai-agent-manager-search-input w-64" />
                </div>

                <Table
                    className="ai-agent-manager-table"
                    columns={columns}
                    dataSource={agents}
                    rowKey="id"
                    loading={loading}
                />
            </Card>

            <Modal
                title={editingId ? "编辑助手" : "新建助手"}
                rootClassName="ai-agent-manager-modal"
                open={isModalOpen}
                onCancel={() => setIsModalOpen(false)}
                onOk={handleSave}
                width={600}
            >
                <Form form={form} layout="vertical">
                    <Form.Item name="name" label="助手名称" rules={[{ required: true }]}>
                        <Input placeholder="例如: 财务报销助手" />
                    </Form.Item>

                    <Form.Item name="description" label="功能描述">
                        <Input.TextArea placeholder="简要描述该助手的用途" rows={2} />
                    </Form.Item>

                    <Form.Item name="buildMode" label="构建方式" rules={[{ required: true, message: '请选择构建方式' }]}>
                        <Segmented
                            block
                            options={[
                                { label: '模型直连', value: 'DIRECT' },
                                { label: 'Dify 引擎', value: 'DIFY' },
                                { label: 'Agent App', value: 'AGENT_APP' }
                            ]}
                        />
                    </Form.Item>

                    {buildMode === 'DIFY' && (
                        <div className="bg-blue-50/50 p-4 rounded-xl border border-blue-100 mb-4">
                            <h4 className="font-bold text-slate-800 mb-2 flex items-center gap-2">
                                <RobotOutlined className="text-blue-500" /> Dify 引擎配置
                            </h4>
                            <p className="text-xs text-slate-500 mb-4">
                                配置 Dify 后，该助手的所有对话将交由 Dify 引擎进行管理。
                            </p>
                            <Form.Item name="difyApiKey" label="Dify API Key (应用凭证)" rules={[{ required: true, message: '请输入 Dify API Key' }]}>
                                <Input.Password placeholder="例如: app-xxxxxxxxxxxxxxxx" />
                            </Form.Item>
                            <Form.Item name="difyApiBase" label="Dify API Base URL (可选)">
                                <Input placeholder="默认: https://api.dify.ai/v1" />
                            </Form.Item>
                        </div>
                    )}

                    {buildMode === 'AGENT_APP' && (
                        <div className="bg-purple-50/50 p-4 rounded-xl border border-purple-100 mb-4">
                            <h4 className="font-bold text-slate-800 mb-2 flex items-center gap-2">
                                <RobotOutlined className="text-purple-500" /> Agent App 工具配置
                            </h4>
                            <p className="text-xs text-slate-500 mb-4">
                                选择该 Agent App 允许编排调用的 CLI 工具，后续执行层按此白名单接入工具能力。
                            </p>
                            <Form.Item name="agentAppTools" label="允许调用的 CLI 工具" rules={[{ required: true, message: '请选择至少一个 CLI 工具' }]}>
                                <Checkbox.Group
                                    options={[
                                        { label: 'hermesagent', value: 'hermesagent' },
                                        { label: 'opencode', value: 'opencode' },
                                        { label: 'openclaw', value: 'openclaw' }
                                    ]}
                                />
                            </Form.Item>
                        </div>
                    )}

                    <Form.Item name="systemPrompt" label="系统提示词" rules={[{ required: false }]}>
                        <Input.TextArea placeholder="你是一个专业的..." rows={6} className="font-mono text-sm" />
                    </Form.Item>
                    <Form.Item name="status" label="启用状态" valuePropName="checked">
                        <Switch checkedChildren="启用" unCheckedChildren="禁用" />
                    </Form.Item>

                    <Form.List name="prompts">
                        {(fields, { add, remove }) => (
                            <>
                                <div className="flex justify-between items-center mb-2">
                                    <span className="text-sm font-medium">推荐提示词配置</span>
                                    <Space>
                                        <Button type="dashed" onClick={() => add()} icon={<PlusOutlined />} size="small">
                                            添加提示词
                                        </Button>
                                    </Space>
                                </div>
                                <div className="max-h-60 overflow-y-auto pr-2">
                                    {fields.map(({ key, name, ...restField }) => (
                                        <div key={key} className="flex gap-2 mb-2 items-start bg-slate-50 p-2 rounded relative group">
                                            <div className="flex-1 space-y-2">
                                                <Form.Item
                                                    {...restField}
                                                    name={[name, 'title']}
                                                    rules={[{ required: true, message: '请输入标题' }]}
                                                    noStyle
                                                >
                                                    <Input placeholder="标题 (如: 策划旅行)" className="mb-1" />
                                                </Form.Item>
                                                <Form.Item
                                                    {...restField}
                                                    name={[name, 'content']}
                                                    rules={[{ required: true, message: '请输入内容' }]}
                                                    noStyle
                                                >
                                                    <Input.TextArea placeholder="内容 (如: 去挪威看极光的行程)" rows={2} />
                                                </Form.Item>
                                            </div>
                                            <Button
                                                type="text"
                                                danger
                                                icon={<DeleteOutlined />}
                                                onClick={() => remove(name)}
                                                className="opacity-0 group-hover:opacity-100 transition-opacity absolute top-1 right-1"
                                            />
                                        </div>
                                    ))}
                                    {fields.length === 0 && (
                                        <div className="text-center text-slate-400 py-4 border border-dashed rounded">
                                            暂无推荐提示词，点击上方按钮添加
                                        </div>
                                    )}
                                </div>
                            </>
                        )}
                    </Form.List>
                </Form>
            </Modal>
        </div >
    );
};

export default AiAgentManager;
