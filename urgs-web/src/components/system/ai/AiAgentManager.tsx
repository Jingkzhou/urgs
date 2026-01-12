
import React, { useState, useEffect } from 'react';
import { Table, Button, Card, Tag, Space, Modal, Form, Input, Select, Switch, message } from 'antd';
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
    knowledgeBase?: string;
    updatedAt: string;
}

const AiAgentManager: React.FC = () => {
    const [knowledgeBases, setKnowledgeBases] = useState<any[]>([]);
    const [agents, setAgents] = useState<AgentConfig[]>([]);
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        get('/api/ai/knowledge/list').then(data => {
            if (data) {
                setKnowledgeBases(data);
            }
        });
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

    const columns = [
        {
            title: '助手名称',
            dataIndex: 'name',
            key: 'name',
            render: (text: string) => <span className="font-bold">{text}</span>
        },
        {
            title: '关联知识库',
            dataIndex: 'knowledgeBase',
            key: 'knowledgeBase',
            width: 150,
            render: (kbValue: string) => {
                const kb = knowledgeBases.find(k => String(k.id) === kbValue || k.name === kbValue);
                const display = kb ? kb.name : kbValue;
                return display ? <Tag color="cyan">{display}</Tag> : <span className="text-slate-400">-</span>;
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
        form.setFieldsValue({ ...record, status: record.status === 1, prompts: typeof record.prompts === 'string' ? JSON.parse(record.prompts) : record.prompts });
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
                prompts: JSON.stringify(values.prompts || [])
            };

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
        <div className="p-6 bg-slate-50 min-h-[500px]">
            <Card variant="borderless" className="shadow-sm">
                <div className="flex justify-between items-center mb-6">
                    <div>
                        <h3 className="text-lg font-bold text-slate-800 flex items-center gap-2">
                            <RobotOutlined className="text-purple-600" /> 智能体助手管理
                        </h3>
                        <p className="text-slate-500 text-sm mt-1">配置业务场景下的智能体提示词与模型参数</p>
                    </div>
                    <Button
                        type="primary"
                        icon={<PlusOutlined />}
                        onClick={() => {
                            setEditingId(null);
                            form.resetFields();
                            form.setFieldsValue({ status: true, prompts: [] }); // Initialize prompts as empty array for new agent
                            setIsModalOpen(true);
                        }}
                    >
                        新建助手
                    </Button>
                </div>

                <div className="mb-4 flex gap-2">
                    <Input prefix={<SearchOutlined className="text-slate-400" />} placeholder="搜索助手名称或描述" className="w-64" />
                </div>

                <Table
                    columns={columns}
                    dataSource={agents}
                    rowKey="id"
                    loading={loading}
                />
            </Card>

            <Modal
                title={editingId ? "编辑助手" : "新建助手"}
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
                    <Form.Item name="knowledgeBase" label="关联知识库">
                        <Select placeholder="选择关联的知识库" allowClear>
                            {knowledgeBases.map(kb => (
                                <Select.Option key={kb.id} value={String(kb.id)}>
                                    {kb.name} {kb.description ? `(${kb.description})` : ''}
                                </Select.Option>
                            ))}
                        </Select>
                    </Form.Item>

                    <Form.Item label="RAG 指令配置 (可选)">
                        <div className="flex gap-2 mb-2">
                            <Button size="small" onClick={() => form.setFieldValue('ragInstruction', `[RAG 模式已启用]\n你是一个严谨的 AI 知识助手。\n1. 你必须【仅基于】我们提供的【参考资料】来回答用户的问题。\n2. 严禁使用你训练数据中的外部知识，除非参考资料中明确提及。\n3. 如果参考资料中没有相关信息，请直接回答：“根据已有资料，无法回答该问题”，不要编造。\n4. 回答需专业、客观，引用资料中的事实。\n[指令结束]\n`)}>🛡️ 严谨模式</Button>

                            <Button size="small" onClick={() => form.setFieldValue('ragInstruction', `[RAG 模式已启用]\n你是一个知识丰富的 AI 助手。\n1. 请优先基于提供的【参考资料】回答问题。\n2. 如果资料信息不全，你可以使用你的通用知识进行补充，但请优先确保资料内容的准确性。\n3. 回答应当全面、通俗易懂。\n[指令结束]\n`)}>⚖️ 平衡模式</Button>

                            <Button size="small" onClick={() => form.setFieldValue('ragInstruction', `[RAG 模式已启用]\n你是一个极具创意的 AI 伙伴。\n1. 提供的【参考资料】仅作为你的灵感来源和背景参考。\n2. 你不需要局限于资料内容，可以自由发散、联想和创作。\n3. 请提供丰富、有趣且富有洞察力的回答。\n[指令结束]\n`)}>🎨 创意模式</Button>
                        </div>
                        <Form.Item name="ragInstruction" noStyle>
                            <Input.TextArea
                                placeholder="配置 RAG 模式下的特定系统指令，将覆盖默认的严格指令..."
                                rows={4}
                                className="font-mono text-xs bg-slate-50"
                            />
                        </Form.Item>
                        <div className="text-xs text-slate-400 mt-1">
                            * 当关联知识库时生效。留空则使用系统默认的严格指令。
                        </div>
                    </Form.Item>

                    <Form.Item name="systemPrompt" label="系统提示词 (System Prompt)" rules={[{ required: true }]}>
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
                                        <Button
                                            type="dashed"
                                            size="small"
                                            icon={<SearchOutlined />}
                                            onClick={async () => {
                                                const kbId = form.getFieldValue('knowledgeBase');
                                                if (!kbId) {
                                                    message.warning('请先选择关联知识库');
                                                    return;
                                                }
                                                // 通过 kb id 找到对应的 collection_name
                                                const kb = knowledgeBases.find(k => String(k.id) === kbId);
                                                if (!kb?.collectionName) {
                                                    message.warning('所选知识库未配置集合名称');
                                                    return;
                                                }
                                                const currentPrompts = form.getFieldValue('prompts') || [];

                                                try {
                                                    const res = await get<{ questions: { title: string; content: string }[], message: string }>(
                                                        `/api/rag/vector-db/collections/${kb.collectionName}/random-qa?count=4`
                                                    );

                                                    if (res?.questions?.length) {
                                                        const newQuestions = res.questions;
                                                        form.setFieldsValue({ prompts: [...currentPrompts, ...newQuestions] });
                                                        message.success(`已添加 ${newQuestions.length} 个随机问题`);
                                                    } else {
                                                        message.info(res?.message || '该知识库暂无模拟问答数据');
                                                    }
                                                } catch (e: any) {
                                                    message.error(e?.message || '获取随机问题失败');
                                                }
                                            }}
                                        >
                                            随机抽取问题
                                        </Button>
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
