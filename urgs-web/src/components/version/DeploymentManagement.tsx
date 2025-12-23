import React, { useState, useEffect } from 'react';
import { Table, Button, Modal, Form, Input, Select, Tag, Space, message, Popconfirm, Tabs, Timeline, Card } from 'antd';
import { Plus, Trash2, Edit, RefreshCw, Server, Rocket, RotateCcw, CheckCircle, XCircle, Loader, Clock } from 'lucide-react';
import {
    getDeployEnvironments, createDeployEnvironment, updateDeployEnvironment, deleteDeployEnvironment,
    getDeployments, executeDeploy, rollbackDeploy,
    getSsoList,
    DeployEnvironment, Deployment, SsoConfig
} from '@/api/version';

const { Option } = Select;

const statusConfig: Record<string, { color: string; icon: React.ReactNode; label: string }> = {
    pending: { color: 'default', icon: <Clock size={14} />, label: '等待中' },
    deploying: { color: 'processing', icon: <Loader size={14} className="animate-spin" />, label: '部署中' },
    success: { color: 'success', icon: <CheckCircle size={14} />, label: '成功' },
    failed: { color: 'error', icon: <XCircle size={14} />, label: '失败' },
    rollback: { color: 'warning', icon: <RotateCcw size={14} />, label: '回滚' },
};

interface Props {
    ssoId?: number;
}

const DeploymentManagement: React.FC<Props> = ({ ssoId }) => {
    const [activeTab, setActiveTab] = useState('deployments');
    const [environments, setEnvironments] = useState<DeployEnvironment[]>([]);
    const [deployments, setDeployments] = useState<Deployment[]>([]);
    const [ssoList, setSsoList] = useState<SsoConfig[]>([]);
    const [loading, setLoading] = useState(false);

    // 环境 Modal
    const [envModalVisible, setEnvModalVisible] = useState(false);
    const [editingEnv, setEditingEnv] = useState<DeployEnvironment | null>(null);
    const [envForm] = Form.useForm();

    // 部署 Modal
    const [deployModalVisible, setDeployModalVisible] = useState(false);
    const [deployForm] = Form.useForm();

    useEffect(() => {
        fetchSsoList();
        fetchEnvironments();
        fetchDeployments();
    }, []);

    const fetchSsoList = async () => {
        try {
            const data = await getSsoList();
            setSsoList(data || []);
        } catch (error) {
            console.error('获取监管系统列表失败', error);
        }
    };

    const fetchEnvironments = async () => {
        try {
            const data = await getDeployEnvironments(ssoId);
            setEnvironments(data || []);
        } catch (error) {
            message.error('获取环境列表失败');
        }
    };

    const fetchDeployments = async () => {
        setLoading(true);
        try {
            const data = await getDeployments({ ssoId });
            setDeployments(data || []);
        } catch (error) {
            message.error('获取部署记录失败');
        } finally {
            setLoading(false);
        }
    };

    // ========== 环境管理 ==========
    const handleAddEnv = () => {
        setEditingEnv(null);
        envForm.resetFields();
        envForm.setFieldsValue({
            deployType: 'ssh',
            sortOrder: 0,
            ssoId: ssoId
        });
        setEnvModalVisible(true);
    };

    const handleEditEnv = (record: DeployEnvironment) => {
        setEditingEnv(record);
        envForm.setFieldsValue(record);
        setEnvModalVisible(true);
    };

    const handleDeleteEnv = async (id: number) => {
        try {
            await deleteDeployEnvironment(id);
            message.success('删除成功');
            fetchEnvironments();
        } catch (error) {
            message.error('删除失败');
        }
    };

    const handleEnvSubmit = async () => {
        try {
            const values = await envForm.validateFields();
            if (editingEnv?.id) {
                await updateDeployEnvironment(editingEnv.id, values);
                message.success('更新成功');
            } else {
                await createDeployEnvironment(values);
                message.success('创建成功');
            }
            setEnvModalVisible(false);
            fetchEnvironments();
        } catch (error) {
            message.error('保存失败');
        }
    };

    // ========== 部署操作 ==========
    const handleDeploy = () => {
        deployForm.resetFields();
        if (ssoId) {
            deployForm.setFieldsValue({ ssoId });
        }
        setDeployModalVisible(true);
    };

    const handleDeploySubmit = async () => {
        try {
            const values = await deployForm.validateFields();
            await executeDeploy(values);
            message.success('已开始部署');
            setDeployModalVisible(false);
            fetchDeployments();
        } catch (error) {
            message.error('部署失败');
        }
    };

    const handleRollback = async (deployment: Deployment) => {
        try {
            await rollbackDeploy(deployment.id!);
            message.success('已开始回滚');
            fetchDeployments();
        } catch (error) {
            message.error('回滚失败');
        }
    };

    const envColumns = [
        { title: '环境名称', dataIndex: 'name', key: 'name' },
        { title: '环境编码', dataIndex: 'code', key: 'code', render: (code: string) => <Tag>{code}</Tag> },
        !ssoId ? {
            title: '关联系统',
            dataIndex: 'ssoId',
            key: 'ssoId',
            render: (ssoId: number) => ssoList.find(s => s.id === ssoId)?.name || '-'
        } : null,
        { title: '部署方式', dataIndex: 'deployType', key: 'deployType' },
        { title: '目标地址', dataIndex: 'deployUrl', key: 'deployUrl', ellipsis: true },
        {
            title: '操作',
            key: 'actions',
            render: (_: any, record: DeployEnvironment) => (
                <Space>
                    <Button type="text" icon={<Edit size={14} />} onClick={() => handleEditEnv(record)} />
                    <Popconfirm title="确定删除？" onConfirm={() => handleDeleteEnv(record.id!)}>
                        <Button type="text" danger icon={<Trash2 size={14} />} />
                    </Popconfirm>
                </Space>
            ),
        },
    ].filter(Boolean) as any;

    const deployColumns = [
        {
            title: '版本',
            dataIndex: 'version',
            key: 'version',
            render: (version: string, record: Deployment) => (
                <div>
                    <div className="font-medium">{version || '-'}</div>
                    {record.rollbackTo && <Tag color="orange" className="text-xs">回滚</Tag>}
                </div>
            )
        },
        {
            title: '环境',
            dataIndex: 'envId',
            key: 'envId',
            render: (envId: number) => {
                const env = environments.find(e => e.id === envId);
                return env ? <Tag color="blue">{env.name}</Tag> : '-';
            }
        },
        !ssoId ? {
            title: '系统',
            dataIndex: 'ssoId',
            key: 'ssoId',
            render: (ssoId: number) => ssoList.find(s => s.id === ssoId)?.name || '-'
        } : null,
        {
            title: '状态',
            dataIndex: 'status',
            key: 'status',
            render: (status: string) => {
                const config = statusConfig[status] || statusConfig.pending;
                return (
                    <Tag color={config.color} className="flex items-center gap-1 w-fit">
                        {config.icon} {config.label}
                    </Tag>
                );
            }
        },
        { title: '部署时间', dataIndex: 'deployedAt', key: 'deployedAt' },
        {
            title: '操作',
            key: 'actions',
            render: (_: any, record: Deployment) => (
                <Space>
                    {record.status === 'success' && !record.rollbackTo && (
                        <Popconfirm title="确定回滚到此版本？" onConfirm={() => handleRollback(record)}>
                            <Button type="text" icon={<RotateCcw size={14} />}>回滚</Button>
                        </Popconfirm>
                    )}
                </Space>
            ),
        },
    ].filter(Boolean) as any;

    return (
        <div className="space-y-4">
            <div className="flex justify-between items-center">
                <h3 className="text-lg font-semibold text-slate-800">部署管理</h3>
            </div>

            <Tabs activeKey={activeTab} onChange={setActiveTab}>
                <Tabs.TabPane tab="部署记录" key="deployments">
                    <div className="mb-4 flex justify-end gap-2">
                        <Button icon={<RefreshCw size={14} />} onClick={fetchDeployments}>刷新</Button>
                        <Button type="primary" icon={<Rocket size={14} />} onClick={handleDeploy}>
                            执行部署
                        </Button>
                    </div>
                    <Table
                        columns={deployColumns}
                        dataSource={deployments}
                        rowKey="id"
                        loading={loading}
                        pagination={{ pageSize: 10 }}
                    />
                </Tabs.TabPane>

                <Tabs.TabPane tab="环境配置" key="environments">
                    <div className="mb-4 flex justify-end gap-2">
                        <Button icon={<RefreshCw size={14} />} onClick={fetchEnvironments}>刷新</Button>
                        <Button type="primary" icon={<Plus size={14} />} onClick={handleAddEnv}>
                            添加环境
                        </Button>
                    </div>
                    <Table
                        columns={envColumns}
                        dataSource={environments}
                        rowKey="id"
                        pagination={false}
                    />
                </Tabs.TabPane>
            </Tabs>

            {/* 环境 Modal */}
            <Modal
                title={editingEnv ? '编辑环境' : '添加环境'}
                open={envModalVisible}
                onOk={handleEnvSubmit}
                onCancel={() => setEnvModalVisible(false)}
                width={500}
            >
                <Form form={envForm} layout="vertical" className="mt-4">
                    {!ssoId && (
                        <Form.Item name="ssoId" label="关联系统" rules={[{ required: true }]}>
                            <Select placeholder="选择监管系统">
                                {ssoList.map(sso => (
                                    <Option key={sso.id} value={sso.id}>{sso.name}</Option>
                                ))}
                            </Select>
                        </Form.Item>
                    )}
                    <Form.Item name="name" label="环境名称" rules={[{ required: true }]}>
                        <Input placeholder="例如：生产环境" />
                    </Form.Item>
                    <Form.Item name="code" label="环境编码" rules={[{ required: true }]}>
                        <Select placeholder="选择环境编码">
                            <Option value="dev">dev - 开发环境</Option>
                            <Option value="test">test - 测试环境</Option>
                            <Option value="staging">staging - 预发环境</Option>
                            <Option value="prod">prod - 生产环境</Option>
                        </Select>
                    </Form.Item>
                    <Form.Item name="deployUrl" label="部署地址">
                        <Input placeholder="例如：192.168.1.100" />
                    </Form.Item>
                    <Form.Item name="deployType" label="部署方式">
                        <Select>
                            <Option value="ssh">SSH</Option>
                            <Option value="docker">Docker</Option>
                            <Option value="k8s">Kubernetes</Option>
                        </Select>
                    </Form.Item>
                </Form>
            </Modal>

            {/* 部署 Modal */}
            <Modal
                title="执行部署"
                open={deployModalVisible}
                onOk={handleDeploySubmit}
                onCancel={() => setDeployModalVisible(false)}
                width={500}
            >
                <Form form={deployForm} layout="vertical" className="mt-4">
                    {!ssoId && (
                        <Form.Item name="ssoId" label="选择系统" rules={[{ required: true }]}>
                            <Select placeholder="选择监管系统">
                                {ssoList.map(sso => (
                                    <Option key={sso.id} value={sso.id}>{sso.name}</Option>
                                ))}
                            </Select>
                        </Form.Item>
                    )}
                    <Form.Item name="envId" label="选择环境" rules={[{ required: true }]}>
                        <Select placeholder="选择部署环境">
                            {environments.map(env => (
                                <Option key={env.id} value={env.id}>{env.name} ({env.code})</Option>
                            ))}
                        </Select>
                    </Form.Item>
                    <Form.Item name="version" label="版本号" rules={[{ required: true }]}>
                        <Input placeholder="例如：v1.0.0" />
                    </Form.Item>
                    <Form.Item name="artifactUrl" label="制品地址">
                        <Input placeholder="可选，制品下载地址" />
                    </Form.Item>
                </Form>
            </Modal>
        </div>
    );
};

export default DeploymentManagement;
