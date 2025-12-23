import React, { useState, useEffect } from 'react';
import { Table, Button, Modal, Form, Input, Select, Tag, Space, message, Popconfirm, Switch } from 'antd';
import { Plus, GitBranch, Trash2, Edit, ExternalLink, RefreshCw } from 'lucide-react';
import { getGitRepositories, createGitRepository, updateGitRepository, deleteGitRepository, getSsoList, GitRepository, SsoConfig } from '@/api/version';
import GitRepoDetail from './GitRepoDetail';
import PageHeader from '../common/PageHeader';
import StatusTag from '../common/StatusTag';

const { Option } = Select;

const platformConfig = {
    gitee: { label: 'Gitee', color: 'red', icon: '🔴' },
    gitlab: { label: 'GitLab', color: 'orange', icon: '🟠' },
    github: { label: 'GitHub', color: 'default', icon: '⚫' },
};

const GitRepoManagement: React.FC = () => {
    const [repos, setRepos] = useState<GitRepository[]>([]);
    const [ssoList, setSsoList] = useState<SsoConfig[]>([]);
    const [loading, setLoading] = useState(false);
    const [modalVisible, setModalVisible] = useState(false);
    const [editingRepo, setEditingRepo] = useState<GitRepository | null>(null);
    const [selectedRepo, setSelectedRepo] = useState<GitRepository | null>(null);
    const [form] = Form.useForm();

    useEffect(() => {
        fetchRepos();
        fetchSsoList();
    }, []);

    const fetchRepos = async () => {
        setLoading(true);
        try {
            const data = await getGitRepositories();
            setRepos(data || []);
        } catch (error) {
            message.error('获取仓库列表失败');
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

    const handleAdd = () => {
        setEditingRepo(null);
        form.resetFields();
        form.setFieldsValue({ platform: 'gitee', enabled: true, defaultBranch: 'master' });
        setModalVisible(true);
    };

    const handleEdit = (record: GitRepository) => {
        setEditingRepo(record);
        form.setFieldsValue(record);
        setModalVisible(true);
    };

    const handleDelete = async (id: number) => {
        try {
            await deleteGitRepository(id);
            message.success('删除成功');
            fetchRepos();
        } catch (error) {
            message.error('删除失败');
        }
    };

    const handleSubmit = async () => {
        try {
            const values = await form.validateFields();
            if (editingRepo?.id) {
                await updateGitRepository(editingRepo.id, values);
                message.success('更新成功');
            } else {
                await createGitRepository(values);
                message.success('添加成功');
            }
            setModalVisible(false);
            fetchRepos();
        } catch (error) {
            message.error('保存失败');
        }
    };

    const columns = [
        {
            title: '仓库名称',
            dataIndex: 'name',
            key: 'name',
            render: (text: string, record: GitRepository) => (
                <div className="flex items-center gap-2 cursor-pointer hover:text-blue-600" onClick={() => setSelectedRepo(record)}>
                    <GitBranch size={16} className="text-slate-500" />
                    <span className="font-medium">{text}</span>
                </div>
            ),
        },
        {
            title: '平台',
            dataIndex: 'platform',
            key: 'platform',
            render: (platform: string) => {
                const config = platformConfig[platform as keyof typeof platformConfig];
                return <Tag color={config?.color}>{config?.icon} {config?.label || platform}</Tag>;
            },
        },
        {
            title: '关联系统',
            dataIndex: 'ssoId',
            key: 'ssoId',
            render: (ssoId: number) => ssoList.find(s => s.id === ssoId)?.name || '-',
        },
        {
            title: '默认分支',
            dataIndex: 'defaultBranch',
            key: 'defaultBranch',
            render: (text: string) => <Tag>{text || 'master'}</Tag>,
        },
        {
            title: '状态',
            dataIndex: 'enabled',
            key: 'enabled',
            render: (enabled: boolean) => (
                <StatusTag status={enabled ? 'enabled' : 'disabled'} />
            ),
        },
        {
            title: '操作',
            key: 'actions',
            render: (_: any, record: GitRepository) => (
                <Space>
                    <Button
                        type="text"
                        icon={<ExternalLink size={14} />}
                        onClick={() => window.open(record.cloneUrl, '_blank')}
                    />
                    <Button type="text" icon={<Edit size={14} />} onClick={() => handleEdit(record)} />
                    <Popconfirm title="确定删除？" onConfirm={() => handleDelete(record.id!)}>
                        <Button type="text" danger icon={<Trash2 size={14} />} />
                    </Popconfirm>
                </Space>
            ),
        },
    ];

    if (selectedRepo) {
        return (
            <GitRepoDetail
                repo={selectedRepo}
                ssoList={ssoList}
                onBack={() => setSelectedRepo(null)}
            />
        );
    }

    return (
        <div className="space-y-4">
            <PageHeader
                title="Git 仓库管理"
                extra={
                    <Space>
                        <Button icon={<RefreshCw className="w-4 h-4" />} onClick={fetchRepos}>刷新</Button>
                        <Button type="primary" icon={<Plus className="w-4 h-4" />} onClick={handleAdd}>
                            添加仓库
                        </Button>
                    </Space>
                }
            />

            <Table
                columns={columns}
                dataSource={repos}
                rowKey="id"
                loading={loading}
                pagination={{ pageSize: 10 }}
            />

            <Modal
                title={editingRepo ? '编辑仓库' : '添加仓库'}
                open={modalVisible}
                onOk={handleSubmit}
                onCancel={() => setModalVisible(false)}
                width={600}
            >
                <Form form={form} layout="vertical" className="mt-4">
                    <Form.Item name="ssoId" label="关联系统" rules={[{ required: true, message: '请选择监管系统' }]}>
                        <Select placeholder="选择监管系统">
                            {ssoList.map(sso => (
                                <Option key={sso.id} value={sso.id}>{sso.name}</Option>
                            ))}
                        </Select>
                    </Form.Item>

                    <Form.Item name="platform" label="Git 平台" rules={[{ required: true }]}>
                        <Select>
                            <Option value="gitee">🔴 Gitee</Option>
                            <Option value="gitlab">🟠 GitLab</Option>
                            <Option value="github">⚫ GitHub</Option>
                        </Select>
                    </Form.Item>

                    <Form.Item name="name" label="仓库名称" rules={[{ required: true, message: '请输入仓库名称' }]}>
                        <Input placeholder="例如：urgs-web" />
                    </Form.Item>

                    <Form.Item
                        name="fullName"
                        label="仓库全名 (owner/repo)"
                        rules={[{ required: true, message: '请输入仓库全名，例如 jingkzhou/urgs' }]}
                        extra="格式：用户名或组织名/仓库名，用于 API 调用"
                    >
                        <Input placeholder="例如：jingkzhou/urgs" />
                    </Form.Item>

                    <Form.Item name="cloneUrl" label="仓库地址 (HTTPS)" rules={[{ required: true, message: '请输入仓库地址' }]}>
                        <Input placeholder="https://gitee.com/your-org/your-repo.git" />
                    </Form.Item>

                    <Form.Item name="defaultBranch" label="默认分支">
                        <Input placeholder="master" />
                    </Form.Item>

                    <Form.Item
                        name="accessToken"
                        label="访问令牌 (Access Token)"
                        extra="用于拉取代码和调用平台 API。Gitee: 个人设置 → 私人令牌；GitHub: Settings → Developer settings → Personal access tokens"
                    >
                        <Input.Password placeholder="可选，但浏览代码功能需要此令牌" />
                    </Form.Item>

                    <Form.Item name="enabled" label="启用" valuePropName="checked">
                        <Switch />
                    </Form.Item>
                </Form>
            </Modal>
        </div>
    );
};

export default GitRepoManagement;
