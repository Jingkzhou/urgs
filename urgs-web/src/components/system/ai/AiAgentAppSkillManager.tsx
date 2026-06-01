import React, { useEffect, useState } from 'react';
import { Button, Card, Form, Input, InputNumber, Modal, Select, Space, Switch, Table, Tag, message } from 'antd';
import { DeleteOutlined, EditOutlined, PlusOutlined, ReloadOutlined, ToolOutlined } from '@ant-design/icons';
import { del, get, post, put } from '../../../utils/request';

interface AgentAppSkill {
    id: number;
    appCode: string;
    name: string;
    code: string;
    description?: string;
    instruction?: string;
    status: number;
    sortOrder?: number;
    updatedAt?: string;
}

const AGENT_APP_OPTIONS = [
    { label: 'Hermes Agent', value: 'hermesagent' },
    { label: 'OpenCode', value: 'opencode' },
    { label: 'OpenClaw', value: 'openclaw' }
];

const getAgentAppLabel = (appCode?: string) => (
    AGENT_APP_OPTIONS.find(item => item.value === appCode)?.label || appCode || '-'
);

const AiAgentAppSkillManager: React.FC = () => {
    const [skills, setSkills] = useState<AgentAppSkill[]>([]);
    const [selectedAppCode, setSelectedAppCode] = useState('hermesagent');
    const [loading, setLoading] = useState(false);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingId, setEditingId] = useState<number | null>(null);
    const [form] = Form.useForm();

    const loadSkills = async () => {
        setLoading(true);
        try {
            const data = await get<AgentAppSkill[]>('/api/ai/agent-app-skills/list');
            setSkills((data || []).filter(skill => skill.appCode === selectedAppCode));
        } catch (e) {
            message.error('获取技能列表失败');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        loadSkills();
    }, [selectedAppCode]);

    const openCreateModal = () => {
        setEditingId(null);
        form.resetFields();
        form.setFieldsValue({
            appCode: selectedAppCode,
            status: true,
            sortOrder: (skills.length + 1) * 10
        });
        setIsModalOpen(true);
    };

    const openEditModal = (record: AgentAppSkill) => {
        setEditingId(record.id);
        form.setFieldsValue({
            ...record,
            status: record.status === 1
        });
        setIsModalOpen(true);
    };

    const handleSave = async () => {
        try {
            const values = await form.validateFields();
            const payload = {
                ...values,
                status: values.status ? 1 : 0
            };
            if (editingId) {
                await put(`/api/ai/agent-app-skills/${editingId}`, payload);
                message.success('更新成功');
            } else {
                await post('/api/ai/agent-app-skills/create', payload);
                message.success('创建成功');
            }
            setIsModalOpen(false);
            loadSkills();
        } catch (e: any) {
            if (!e?.errorFields) {
                message.error(e?.message || '保存失败');
            }
        }
    };

    const handleDelete = (id: number) => {
        Modal.confirm({
            title: '确认删除',
            content: '删除后该技能不会再出现在 chat 页 / 菜单中，确定继续吗？',
            okType: 'danger',
            onOk: async () => {
                await del(`/api/ai/agent-app-skills/${id}`);
                message.success('删除成功');
                loadSkills();
            }
        });
    };

    const handleSyncDefaults = async () => {
        try {
            const created = await post<AgentAppSkill[]>('/api/ai/agent-app-skills/sync-defaults', {}, {
                params: { appCode: selectedAppCode }
            });
            message.success(created?.length ? `已加载 ${created.length} 个默认技能` : '默认技能已是最新');
            loadSkills();
        } catch (e: any) {
            message.error(e?.message || '加载默认技能失败');
        }
    };

    const columns = [
        {
            title: 'Agent App',
            dataIndex: 'appCode',
            key: 'appCode',
            width: 130,
            render: (appCode: string) => <Tag color="purple">{getAgentAppLabel(appCode)}</Tag>
        },
        {
            title: '技能名称',
            dataIndex: 'name',
            key: 'name',
            render: (text: string, record: AgentAppSkill) => (
                <div>
                    <div className="font-bold text-slate-800">{text}</div>
                    <div className="text-xs text-slate-400">/{record.code}</div>
                </div>
            )
        },
        {
            title: '说明',
            dataIndex: 'description',
            key: 'description',
            ellipsis: true,
            render: (text: string) => text || <span className="text-slate-400">-</span>
        },
        {
            title: '状态',
            dataIndex: 'status',
            key: 'status',
            width: 90,
            render: (status: number) => <Tag color={status === 1 ? 'success' : 'default'}>{status === 1 ? '启用' : '禁用'}</Tag>
        },
        {
            title: '排序',
            dataIndex: 'sortOrder',
            key: 'sortOrder',
            width: 80
        },
        {
            title: '更新时间',
            dataIndex: 'updatedAt',
            key: 'updatedAt',
            width: 180,
            render: (text: string) => text ? new Date(text).toLocaleString() : '-'
        },
        {
            title: '操作',
            key: 'actions',
            width: 120,
            align: 'right' as const,
            render: (_: any, record: AgentAppSkill) => (
                <Space>
                    <Button type="text" size="small" icon={<EditOutlined />} onClick={() => openEditModal(record)} />
                    <Button type="text" danger size="small" icon={<DeleteOutlined />} onClick={() => handleDelete(record.id)} />
                </Space>
            )
        }
    ];

    return (
        <div className="p-6 bg-slate-50 min-h-[500px]">
            <Card variant="borderless" className="shadow-sm">
                <div className="flex justify-between items-start gap-4 mb-6">
                    <div>
                        <h3 className="text-lg font-bold text-slate-800 flex items-center gap-2">
                            <ToolOutlined className="text-purple-600" /> Agent App Skills 管理
                        </h3>
                        <p className="text-slate-500 text-sm mt-1">先选择 Agent App CLI，再维护该 CLI 下可在 chat 页 / 调用的技能。</p>
                    </div>
                    <Space>
                        <Button icon={<ReloadOutlined />} onClick={handleSyncDefaults}>
                            加载默认技能
                        </Button>
                        <Button type="primary" icon={<PlusOutlined />} onClick={openCreateModal}>
                            新建技能
                        </Button>
                    </Space>
                </div>

                <div className="mb-4 flex items-center gap-3">
                    <Select
                        className="w-72"
                        value={selectedAppCode}
                        options={AGENT_APP_OPTIONS}
                        onChange={setSelectedAppCode}
                    />
                    <div className="text-xs text-slate-500">
                        当前配置：{getAgentAppLabel(selectedAppCode)} 的技能
                    </div>
                </div>

                <Table
                    columns={columns}
                    dataSource={skills}
                    rowKey="id"
                    loading={loading}
                    pagination={false}
                />
            </Card>

            <Modal
                title={editingId ? '编辑技能' : '新建技能'}
                open={isModalOpen}
                onCancel={() => setIsModalOpen(false)}
                onOk={handleSave}
                width={640}
            >
                <Form form={form} layout="vertical">
                    <Form.Item name="appCode" label="Agent App" rules={[{ required: true, message: '请选择 Agent App' }]}>
                        <Select options={AGENT_APP_OPTIONS} disabled={!!editingId} />
                    </Form.Item>
                    <Form.Item name="name" label="技能名称" rules={[{ required: true, message: '请输入技能名称' }]}>
                        <Input placeholder="例如：代码审查" />
                    </Form.Item>
                    <Form.Item name="code" label="技能编码" rules={[{ required: true, message: '请输入技能编码' }]}>
                        <Input placeholder="例如：code-review，chat 页输入 / 后显示" disabled={!!editingId} />
                    </Form.Item>
                    <Form.Item name="description" label="技能说明">
                        <Input.TextArea rows={2} placeholder="简要说明这个技能适合处理什么任务" />
                    </Form.Item>
                    <Form.Item name="instruction" label="调用指令">
                        <Input.TextArea rows={5} placeholder="调用该技能时传给 Agent App 的技能指令" />
                    </Form.Item>
                    <div className="grid grid-cols-2 gap-4">
                        <Form.Item name="sortOrder" label="排序号">
                            <InputNumber className="w-full" min={0} />
                        </Form.Item>
                        <Form.Item name="status" label="启用状态" valuePropName="checked">
                            <Switch checkedChildren="启用" unCheckedChildren="禁用" />
                        </Form.Item>
                    </div>
                </Form>
            </Modal>
        </div>
    );
};

export default AiAgentAppSkillManager;
