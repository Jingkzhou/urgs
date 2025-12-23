import React, { useState, useEffect } from 'react';
import { Table, Button, Modal, Form, Input, Select, Tag, Space, message, Popconfirm, Switch, Drawer, Timeline } from 'antd';
import { Plus, Play, Trash2, Edit, RefreshCw, GitBranch, Clock, CheckCircle, XCircle, Loader } from 'lucide-react';
import {
    getPipelines, createPipeline, updatePipeline, deletePipeline,
    getPipelineRuns, triggerPipeline,
    getSsoList, getGitRepositories,
    Pipeline, PipelineRun, SsoConfig, GitRepository
} from '@/api/version';

const { Option } = Select;

const statusConfig: Record<string, { color: string; icon: React.ReactNode; label: string }> = {
    pending: { color: 'default', icon: <Clock size={14} />, label: '等待中' },
    running: { color: 'processing', icon: <Loader size={14} className="animate-spin" />, label: '执行中' },
    success: { color: 'success', icon: <CheckCircle size={14} />, label: '成功' },
    failed: { color: 'error', icon: <XCircle size={14} />, label: '失败' },
    cancelled: { color: 'warning', icon: <XCircle size={14} />, label: '已取消' },
};

interface Props {
    ssoId?: number;
    repoId?: number;
}

const PipelineManagement: React.FC<Props> = ({ ssoId, repoId }) => {
    const [pipelines, setPipelines] = useState<Pipeline[]>([]);
    const [ssoList, setSsoList] = useState<SsoConfig[]>([]);
    const [repos, setRepos] = useState<GitRepository[]>([]);
    const [loading, setLoading] = useState(false);
    const [modalVisible, setModalVisible] = useState(false);
    const [editingPipeline, setEditingPipeline] = useState<Pipeline | null>(null);
    const [form] = Form.useForm();

    // 执行记录抽屉
    const [drawerVisible, setDrawerVisible] = useState(false);
    const [selectedPipeline, setSelectedPipeline] = useState<Pipeline | null>(null);
    const [runs, setRuns] = useState<PipelineRun[]>([]);
    const [runsLoading, setRunsLoading] = useState(false);

    useEffect(() => {
        fetchPipelines();
        fetchSsoList();
        fetchRepos();
    }, []);

    const fetchPipelines = async () => {
        setLoading(true);
        try {
            const data = await getPipelines({ ssoId, repoId });
            setPipelines(data || []);
        } catch (error) {
            message.error('获取流水线列表失败');
        } finally {
            setLoading(false);
        }
    };

    const fetchSsoList = async () => {
        try {
            const data = await getSsoList();
            setSsoList(data || []);
        } catch (error) {
            console.error('获取监管系统列表失败', error);
        }
    };

    const fetchRepos = async () => {
        try {
            const data = await getGitRepositories();
            setRepos(data || []);
        } catch (error) {
            console.error('获取仓库列表失败', error);
        }
    };

    const handleAdd = () => {
        setEditingPipeline(null);
        form.resetFields();
        form.setFieldsValue({
            triggerType: 'manual',
            enabled: true,
            ssoId: ssoId,
            repoId: repoId
        });
        setModalVisible(true);
    };

    const handleEdit = (record: Pipeline) => {
        setEditingPipeline(record);
        form.setFieldsValue(record);
        setModalVisible(true);
    };

    const handleDelete = async (id: number) => {
        try {
            await deletePipeline(id);
            message.success('删除成功');
            fetchPipelines();
        } catch (error) {
            message.error('删除失败');
        }
    };

    const handleSubmit = async () => {
        try {
            const values = await form.validateFields();
            if (editingPipeline?.id) {
                await updatePipeline(editingPipeline.id, values);
                message.success('更新成功');
            } else {
                await createPipeline(values);
                message.success('创建成功');
            }
            setModalVisible(false);
            fetchPipelines();
        } catch (error) {
            message.error('保存失败');
        }
    };

    const handleTrigger = async (pipeline: Pipeline) => {
        try {
            const repo = repos.find(r => r.id === pipeline.repoId);
            await triggerPipeline(pipeline.id!, { branch: repo?.defaultBranch || 'master' });
            message.success('已触发执行');
            if (selectedPipeline?.id === pipeline.id) {
                fetchRuns(pipeline.id!);
            }
        } catch (error) {
            message.error('触发失败');
        }
    };

    const handleViewRuns = async (pipeline: Pipeline) => {
        setSelectedPipeline(pipeline);
        setDrawerVisible(true);
        fetchRuns(pipeline.id!);
    };

    const fetchRuns = async (pipelineId: number) => {
        setRunsLoading(true);
        try {
            const data = await getPipelineRuns(pipelineId);
            setRuns(data || []);
        } catch (error) {
            message.error('获取执行记录失败');
        } finally {
            setRunsLoading(false);
        }
    };

    const columns = [
        {
            title: '流水线名称',
            dataIndex: 'name',
            key: 'name',
            render: (text: string) => (
                <div className="flex items-center gap-2">
                    <GitBranch size={16} className="text-blue-500" />
                    <span className="font-medium">{text}</span>
                </div>
            ),
        },
        !ssoId ? {
            title: '关联系统',
            dataIndex: 'ssoId',
            key: 'ssoId',
            render: (ssoId: number) => ssoList.find(s => s.id === ssoId)?.name || '-',
        } : null,
        !repoId ? {
            title: '关联仓库',
            dataIndex: 'repoId',
            key: 'repoId',
            render: (repoId: number) => repos.find(r => r.id === repoId)?.name || '-',
        } : null,
        {
            title: '触发方式',
            dataIndex: 'triggerType',
            key: 'triggerType',
            render: (type: string) => {
                const labels: Record<string, string> = { manual: '手动', webhook: 'Webhook', schedule: '定时' };
                return <Tag>{labels[type] || type}</Tag>;
            },
        },
        {
            title: '状态',
            dataIndex: 'enabled',
            key: 'enabled',
            render: (enabled: boolean) => (
                <Tag color={enabled ? 'green' : 'default'}>{enabled ? '启用' : '禁用'}</Tag>
            ),
        },
        {
            title: '操作',
            key: 'actions',
            render: (_: any, record: Pipeline) => (
                <Space>
                    <Button
                        type="primary"
                        size="small"
                        icon={<Play size={14} />}
                        onClick={() => handleTrigger(record)}
                        disabled={!record.enabled}
                    >
                        执行
                    </Button>
                    <Button type="text" size="small" onClick={() => handleViewRuns(record)}>
                        记录
                    </Button>
                    <Button type="text" icon={<Edit size={14} />} onClick={() => handleEdit(record)} />
                    <Popconfirm title="确定删除？" onConfirm={() => handleDelete(record.id!)}>
                        <Button type="text" danger icon={<Trash2 size={14} />} />
                    </Popconfirm>
                </Space>
            ),
        },
    ].filter(Boolean) as any;

    return (
        <div className="space-y-4">
            <div className="flex justify-between items-center">
                <h3 className="text-lg font-semibold text-slate-800">流水线管理</h3>
                <Space>
                    <Button icon={<RefreshCw size={14} />} onClick={fetchPipelines}>刷新</Button>
                    <Button type="primary" icon={<Plus size={14} />} onClick={handleAdd}>
                        创建流水线
                    </Button>
                </Space>
            </div>

            <Table
                columns={columns}
                dataSource={pipelines}
                rowKey="id"
                loading={loading}
                pagination={{ pageSize: 10 }}
            />

            {/* 创建/编辑流水线 Modal */}
            <Modal
                title={editingPipeline ? '编辑流水线' : '创建流水线'}
                open={modalVisible}
                onOk={handleSubmit}
                onCancel={() => setModalVisible(false)}
                width={600}
            >
                <Form form={form} layout="vertical" className="mt-4">
                    <Form.Item name="name" label="流水线名称" rules={[{ required: true, message: '请输入名称' }]}>
                        <Input placeholder="例如：生产环境部署" />
                    </Form.Item>

                    {!ssoId && (
                        <Form.Item name="ssoId" label="关联系统" rules={[{ required: true, message: '请选择系统' }]}>
                            <Select placeholder="选择监管系统">
                                {ssoList.map(sso => (
                                    <Option key={sso.id} value={sso.id}>{sso.name}</Option>
                                ))}
                            </Select>
                        </Form.Item>
                    )}

                    {!repoId && (
                        <Form.Item name="repoId" label="关联仓库">
                            <Select placeholder="选择 Git 仓库" allowClear>
                                {repos.map(repo => (
                                    <Option key={repo.id} value={repo.id}>{repo.name}</Option>
                                ))}
                            </Select>
                        </Form.Item>
                    )}

                    <Form.Item name="triggerType" label="触发方式">
                        <Select>
                            <Option value="manual">手动触发</Option>
                            <Option value="webhook">Webhook 触发</Option>
                            <Option value="schedule">定时触发</Option>
                        </Select>
                    </Form.Item>

                    <Form.Item name="enabled" label="启用" valuePropName="checked">
                        <Switch />
                    </Form.Item>
                </Form>
            </Modal>

            {/* 执行记录 Drawer */}
            <Drawer
                title={`执行记录 - ${selectedPipeline?.name || ''}`}
                open={drawerVisible}
                onClose={() => setDrawerVisible(false)}
                width={500}
            >
                <div className="mb-4 flex justify-between">
                    <Button
                        type="primary"
                        icon={<Play size={14} />}
                        onClick={() => selectedPipeline && handleTrigger(selectedPipeline)}
                    >
                        立即执行
                    </Button>
                    <Button icon={<RefreshCw size={14} />} onClick={() => selectedPipeline && fetchRuns(selectedPipeline.id!)}>
                        刷新
                    </Button>
                </div>

                {runsLoading ? (
                    <div className="text-center py-8 text-slate-500">加载中...</div>
                ) : runs.length === 0 ? (
                    <div className="text-center py-8 text-slate-500">暂无执行记录</div>
                ) : (
                    <Timeline>
                        {runs.map(run => {
                            const status = statusConfig[run.status] || statusConfig.pending;
                            return (
                                <Timeline.Item key={run.id} color={status.color}>
                                    <div className="flex items-center gap-2 mb-1">
                                        {status.icon}
                                        <span className="font-medium">#{run.runNumber}</span>
                                        <Tag color={status.color}>{status.label}</Tag>
                                    </div>
                                    <div className="text-xs text-slate-500">
                                        <div>分支: {run.branch}</div>
                                        <div>触发: {run.triggerType}</div>
                                        {run.startedAt && <div>开始: {run.startedAt}</div>}
                                        {run.finishedAt && <div>结束: {run.finishedAt}</div>}
                                    </div>
                                    {run.logs && (
                                        <pre className="mt-2 p-2 bg-slate-100 rounded text-xs overflow-auto max-h-40">
                                            {run.logs}
                                        </pre>
                                    )}
                                </Timeline.Item>
                            );
                        })}
                    </Timeline>
                )}
            </Drawer>
        </div>
    );
};

export default PipelineManagement;
