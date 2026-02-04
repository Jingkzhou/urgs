import React, { useState, useEffect } from 'react';
import { Table, Button, Modal, Form, Input, Select, Tag, Space, message, Popconfirm, Switch } from 'antd';
import { Plus, GitBranch, Trash2, Edit, ExternalLink, RefreshCw, LayoutList, LayoutGrid, MoreHorizontal, GitPullRequest } from 'lucide-react';
import { getGitRepositories, createGitRepository, updateGitRepository, deleteGitRepository, getSsoList, GitRepository, SsoConfig, getRepoPrCounts, syncGitLabProjects, importGitRepositories } from '@/api/version';
import GitRepoDetail from './GitRepoDetail';
import PageHeader from '../../common/PageHeader';
import StatusTag from '../../common/StatusTag';

const { Option } = Select;

const platformConfig = {
    gitee: { label: 'Gitee', color: 'red', icon: '🔴' },
    gitlab: { label: 'GitLab', color: 'orange', icon: '🟠' },
    github: { label: 'GitHub', color: 'default', icon: '⚫' },
};

const parseFullNameFromCloneUrl = (cloneUrl?: string): string | null => {
    if (!cloneUrl) {
        return null;
    }
    const trimmed = cloneUrl.trim();
    if (!trimmed) {
        return null;
    }
    if (trimmed.includes('://')) {
        try {
            const url = new URL(trimmed);
            const path = url.pathname.replace(/^\/+/, '').replace(/\.git$/, '');
            return path ? path : null;
        } catch (error) {
            return null;
        }
    }
    const colonIndex = trimmed.indexOf(':');
    if (colonIndex > -1) {
        const path = trimmed.substring(colonIndex + 1).replace(/^\/+/, '').replace(/\.git$/, '');
        return path ? path : null;
    }
    const fallback = trimmed.replace(/^\/+/, '').replace(/\.git$/, '');
    return fallback ? fallback : null;
};

const GitRepoManagement: React.FC = () => {
    const [repos, setRepos] = useState<GitRepository[]>([]);
    const [ssoList, setSsoList] = useState<SsoConfig[]>([]);
    const [loading, setLoading] = useState(false);
    const [modalVisible, setModalVisible] = useState(false);

    const [editingRepo, setEditingRepo] = useState<GitRepository | null>(null);
    const [selectedRepo, setSelectedRepo] = useState<GitRepository | null>(null);
    const [viewMode, setViewMode] = useState<'list' | 'card'>('card');
    const [form] = Form.useForm();

    useEffect(() => {
        fetchRepos();
        fetchSsoList();
    }, []);

    const fetchRepos = async () => {
        setLoading(true);
        try {
            const [data, prCounts] = await Promise.all([
                getGitRepositories(),
                getRepoPrCounts().catch(() => ({}))
            ]);

            const reposWithCounts = (data || []).map(repo => ({
                ...repo,
                pendingPrCount: prCounts ? prCounts[repo.id!] : 0
            }));

            setRepos(reposWithCounts);
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
            const fullName = parseFullNameFromCloneUrl(values.cloneUrl);
            if (!fullName) {
                message.error('无法从仓库地址解析仓库全名，请检查仓库地址');
                return;
            }
            const payload = { ...values, fullName };
            if (editingRepo?.id) {
                await updateGitRepository(editingRepo.id, payload);
                message.success('更新成功');
            } else {
                await createGitRepository(payload);
                message.success('添加成功');
            }
            setModalVisible(false);
            fetchRepos();
        } catch (error) {
            message.error('保存失败');
        }
    };

    const [syncModalVisible, setSyncModalVisible] = useState(false);
    const [syncLoading, setSyncLoading] = useState(false);
    const [gitLabProjects, setGitLabProjects] = useState<import('@/api/version').GitProjectVO[]>([]);
    const [selectedProjects, setSelectedProjects] = useState<import('@/api/version').GitProjectVO[]>([]);
    const [selectedSystemId, setSelectedSystemId] = useState<number | undefined>(undefined);

    const handleOpenSync = async () => {
        setSyncModalVisible(true);
        setSyncLoading(true);
        try {
            const projects = await syncGitLabProjects();
            setGitLabProjects(projects || []);
        } catch (error) {
            message.error('同步 GitLab 项目失败，请检查是否在个人设置中配置了 Token');
        } finally {
            setSyncLoading(false);
        }
    };

    const handleImport = async () => {
        if (!selectedSystemId) {
            message.error('请选择关联系统');
            return;
        }
        if (selectedProjects.length === 0) {
            message.error('请选择要导入的项目');
            return;
        }

        try {
            await importGitRepositories({
                systemId: selectedSystemId,
                projects: selectedProjects
            });
            message.success('导入成功');
            setSyncModalVisible(false);
            fetchRepos();
            setSelectedProjects([]);
            setGitLabProjects([]);
        } catch (error) {
            message.error('导入失败');
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
            title: '待合并 PR',
            dataIndex: 'pendingPrCount',
            key: 'pendingPrCount',
            width: 120,
            render: (count: number) => count > 0 ? (
                <Tag color="orange" className="flex items-center gap-1 w-fit rounded-full px-2">
                    <GitPullRequest size={12} /> {count} 待合并
                </Tag>
            ) : <span className="text-slate-400 text-xs">-</span>,
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
                        <div className="flex bg-slate-100 p-1 rounded-lg mr-2">
                            <button
                                onClick={() => setViewMode('card')}
                                className={`p-1.5 rounded-md transition-all ${viewMode === 'card' ? 'bg-white shadow text-indigo-600' : 'text-slate-400 hover:text-slate-600'}`}
                            >
                                <LayoutGrid size={16} />
                            </button>
                            <button
                                onClick={() => setViewMode('list')}
                                className={`p-1.5 rounded-md transition-all ${viewMode === 'list' ? 'bg-white shadow text-indigo-600' : 'text-slate-400 hover:text-slate-600'}`}
                            >
                                <LayoutList size={16} />
                            </button>
                        </div>
                        <Button icon={<RefreshCw className="w-4 h-4" />} onClick={fetchRepos}>刷新</Button>
                        <Button icon={<GitBranch className="w-4 h-4" />} onClick={handleOpenSync}>同步 GitLab 项目</Button>
                        <Button type="primary" icon={<Plus className="w-4 h-4" />} onClick={handleAdd}>
                            添加仓库
                        </Button>
                    </Space>
                }
            />

            {viewMode === 'list' ? (
                <Table
                    columns={columns}
                    dataSource={repos}
                    rowKey="id"
                    loading={loading}
                    pagination={{ pageSize: 10 }}
                />
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                    {repos.map(repo => {
                        const platform = platformConfig[repo.platform as keyof typeof platformConfig];
                        const ssoName = ssoList.find(s => s.id === repo.ssoId)?.name;

                        return (
                            <div key={repo.id} className="group bg-white rounded-xl border border-slate-200 p-4 hover:shadow-md transition-all hover:border-indigo-200 flex flex-col h-full">
                                <div className="flex justify-between items-start mb-3">
                                    <div className="flex items-center gap-3">
                                        <div className={`w-10 h-10 rounded-lg flex items-center justify-center text-xl bg-slate-50 border border-slate-100`}>
                                            {platform?.icon || '⚫'}
                                        </div>
                                        <div>
                                            <h3
                                                className="font-bold text-slate-800 cursor-pointer hover:text-indigo-600 transition-colors line-clamp-1"
                                                onClick={() => setSelectedRepo(repo)}
                                            >
                                                {repo.name}
                                            </h3>
                                            <div className="flex items-center gap-2 mt-0.5">
                                                <StatusTag status={repo.enabled ? 'enabled' : 'disabled'} />
                                                <span className="text-xs text-slate-400 px-1.5 py-0.5 bg-slate-50 rounded border border-slate-100">{platform?.label}</span>
                                                {(repo.pendingPrCount || 0) > 0 && (
                                                    <span className="flex items-center gap-1 text-[10px] text-orange-600 bg-orange-50 px-1.5 py-0.5 rounded-full border border-orange-100 font-medium">
                                                        <GitPullRequest size={10} /> {repo.pendingPrCount}
                                                    </span>
                                                )}
                                            </div>
                                        </div>
                                    </div>
                                    <Popconfirm title="确定删除？" onConfirm={() => handleDelete(repo.id!)}>
                                        <button className="text-slate-300 hover:text-red-500 transition-colors p-1">
                                            <Trash2 size={16} />
                                        </button>
                                    </Popconfirm>
                                </div>

                                <div className="flex-1 space-y-3 mb-4">
                                    <div className="flex items-center gap-2 text-xs text-slate-500 bg-slate-50 p-2 rounded border border-slate-100 font-mono break-all cursor-pointer hover:bg-slate-100" onClick={() => window.open(repo.cloneUrl, '_blank')}>
                                        <ExternalLink size={12} className="shrink-0" />
                                        <span className="truncate">{repo.cloneUrl?.replace(/^https?:\/\//, '')}</span>
                                    </div>

                                    <div className="flex items-center justify-between text-xs">
                                        <div className="flex items-center gap-1.5 text-slate-500">
                                            <GitBranch size={14} />
                                            <span>{repo.defaultBranch || 'master'}</span>
                                        </div>
                                        {ssoName && (
                                            <Tag className="mr-0 border-transparent bg-indigo-50 text-indigo-600">{ssoName}</Tag>
                                        )}
                                    </div>
                                </div>

                                <div className="flex items-center gap-2 pt-3 border-t border-slate-100 mt-auto">
                                    <Button
                                        type="primary"
                                        ghost
                                        size="small"
                                        className="flex-1"
                                        onClick={() => setSelectedRepo(repo)}
                                    >
                                        进入仓库
                                    </Button>
                                    <Button
                                        icon={<Edit size={14} />}
                                        size="small"
                                        onClick={() => handleEdit(repo)}
                                    />
                                </div>
                            </div>
                        );
                    })}
                </div>
            )}

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
                        name="cloneUrl"
                        label="仓库地址 (HTTPS)"
                        rules={[{ required: true, message: '请输入仓库地址' }]}
                        extra="系统将自动从仓库地址解析 owner/repo"
                    >
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

            <Modal
                title="同步 GitLab 项目"
                open={syncModalVisible}
                onOk={handleImport}
                onCancel={() => setSyncModalVisible(false)}
                width={800}
                confirmLoading={syncLoading}
                okText="导入选中项目"
            >
                <div className="space-y-4">
                    <div className="flex items-center gap-4">
                        <span className="text-sm font-medium">选择关联系统：</span>
                        <Select
                            placeholder="请选择要导入到的系统"
                            className="w-64"
                            value={selectedSystemId}
                            onChange={(val) => setSelectedSystemId(val)}
                        >
                            {ssoList.map(sso => (
                                <Option key={sso.id} value={sso.id}>{sso.name}</Option>
                            ))}
                        </Select>
                    </div>

                    <Table
                        dataSource={gitLabProjects}
                        rowKey="id"
                        loading={syncLoading}
                        rowSelection={{
                            onChange: (_, selectedRows) => {
                                // @ts-ignore
                                setSelectedProjects(selectedRows);
                            }
                        }}
                        pagination={{ pageSize: 5 }}
                        size="small"
                        scroll={{ y: 400 }}
                    >
                        <Table.Column title="项目名称" dataIndex="name" key="name" />
                        <Table.Column title="完整路径" dataIndex="pathWithNamespace" key="path" />
                        <Table.Column title="默认分支" dataIndex="defaultBranch" key="branch" />
                        <Table.Column title="可见性" dataIndex="visibility" key="visibility" render={(acc: string) => <Tag>{acc}</Tag>} />
                    </Table>
                </div>
            </Modal>
        </div>
    );
};

export default GitRepoManagement;
