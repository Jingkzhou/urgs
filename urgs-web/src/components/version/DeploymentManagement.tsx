import React, { useState, useEffect, useMemo } from 'react';
import { Button, Modal, Form, Input, Select, Tag, Space, message, Popconfirm, Badge, List, Card, Timeline, Divider, Dropdown } from 'antd';
import { 
    Plus, Trash2, Edit, RefreshCw, Server, Rocket, RotateCcw, 
    CheckCircle, XCircle, Loader, Clock, Globe, Download, 
    ChevronRight, Info, Package, GitBranch, Tag as TagIcon, MoreVertical, 
    Play, Activity, ShieldCheck, History, Settings, Zap, AlertTriangle
} from 'lucide-react';
import {
    getDeployEnvironments, 
    getDeployments, 
    getSsoList,
    getGitRepositories,
    getRepoBranches,
    getRepoTags,
    getVersionPackages,
    createVersionPackage,
    downloadVersionPackage,
    updatePackageStatus,
    deployWithPackage,
    createDeployEnvironment,
    deleteDeployEnvironment,
    DeployEnvironment, 
    Deployment, 
    SsoConfig,
    GitRepository,
    GitBranch as IGitBranch,
    GitTag as IGitTag,
    VersionPackage
} from '@/api/version';

const { Option } = Select;

const statusConfig: Record<string, { color: string; icon: React.ReactNode; label: string }> = {
    draft: { color: 'default', icon: <Edit size={14} />, label: '草稿' },
    ready: { color: 'blue', icon: <CheckCircle size={14} />, label: '就绪' },
    deployed: { color: 'success', icon: <Rocket size={14} />, label: '已部署' },
    archived: { color: 'default', icon: <History size={14} />, label: '已归档' },
    pending: { color: 'default', icon: <Clock size={14} />, label: '待处理' },
    success: { color: 'success', icon: <CheckCircle size={14} />, label: '成功' },
    failed: { color: 'error', icon: <XCircle size={14} />, label: '失败' },
};

interface Props {
    ssoId?: number;
    repoId?: number; // 新增：指定默认使用的版本库ID
}

const DeploymentManagement: React.FC<Props> = ({ ssoId, repoId }) => {
    const [environments, setEnvironments] = useState<DeployEnvironment[]>([]);
    const [deployments, setDeployments] = useState<Deployment[]>([]);
    const [versionPackages, setVersionPackages] = useState<VersionPackage[]>([]);
    const [repos, setRepos] = useState<GitRepository[]>([]);
    const [loading, setLoading] = useState(false);
    const [activeTab, setActiveTab] = useState<'packages' | 'history'>('packages');

    // 版本包 Modal
    const [packageModalVisible, setPackageModalVisible] = useState(false);
    const [packageForm] = Form.useForm();
    const [selectedRepo, setSelectedRepo] = useState<number | null>(null);
    const [branches, setBranches] = useState<IGitBranch[]>([]);
    const [tags, setTags] = useState<IGitTag[]>([]);
    const [fetchingGit, setFetchingGit] = useState(false);

    // 部署确认 Modal
    const [deployConfirmVisible, setDeployConfirmVisible] = useState(false);
    const [selectedPackage, setSelectedPackage] = useState<VersionPackage | null>(null);
    const [deployForm] = Form.useForm();

    // 环境管理 Modal
    const [envModalVisible, setEnvModalVisible] = useState(false);
    const [envForm] = Form.useForm();
    const [envLoading, setEnvLoading] = useState(false);

    useEffect(() => {
        if (ssoId) {
            fetchData();
        }
    }, [ssoId]);

    const fetchData = async () => {
        setLoading(true);
        try {
            const [envs, deps, pkgs, repositories] = await Promise.all([
                getDeployEnvironments(ssoId),
                getDeployments({ ssoId }),
                getVersionPackages(ssoId!),
                getGitRepositories({ ssoId })
            ]);
            setEnvironments(envs || []);
            setDeployments(deps || []);
            setVersionPackages(pkgs || []);
            setRepos(repositories || []);
        } catch (error) {
            message.error('加载数据失败');
        } finally {
            setLoading(false);
        }
    };

    // ========== 版本包操作 ==========
    const handleRepoChange = async (repoId: number) => {
        setSelectedRepo(repoId);
        setFetchingGit(true);
        packageForm.setFieldsValue({ gitRef: undefined });
        try {
            const [b, t] = await Promise.all([
                getRepoBranches(repoId),
                getRepoTags(repoId)
            ]);
            setBranches(b || []);
            setTags(t || []);
        } catch (error) {
            message.error('获取仓库分支/标签失败');
        } finally {
            setFetchingGit(false);
        }
    };

    const handleCreatePackage = async () => {
        try {
            const values = await packageForm.validateFields();
            await createVersionPackage({
                ...values,
                ssoId: ssoId!
            });
            message.success('版本包创建成功');
            setPackageModalVisible(false);
            fetchData();
        } catch (error) {
            console.error(error);
        }
    };

    const handleDownload = async (pkg: VersionPackage) => {
        try {
            const blob = await downloadVersionPackage(pkg.id);
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `deploy-${pkg.version}-${pkg.gitRef}.zip`;
            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(url);
            message.success('部署包下载开始');
        } catch (error) {
            message.error('下载部署包失败');
        }
    };

    const handleUpdateStatus = async (id: number, status: string) => {
        try {
            await updatePackageStatus(id, status);
            message.success('状态更新成功');
            fetchData();
        } catch (error) {
            message.error('更新状态失败');
        }
    };

    // ========== 环境管理操作 ==========
    const handleAddEnvironment = async () => {
        try {
            const values = await envForm.validateFields();
            await createDeployEnvironment({
                ...values,
                ssoId: ssoId!
            });
            message.success('环境添加成功');
            envForm.resetFields();
            fetchData();
        } catch (error) {
            console.error(error);
        }
    };

    const handleDeleteEnv = async (id: number) => {
        try {
            await deleteDeployEnvironment(id);
            message.success('环境已删除');
            fetchData();
        } catch (error) {
            message.error('删除失败');
        }
    };

    const handleQuickInitEnvs = async () => {
        setEnvLoading(true);
        try {
            const defaults = [
                { name: '测试环境', code: 'SIT', sortOrder: 10 },
                { name: '预发布环境', code: 'UAT', sortOrder: 20 },
                { name: '生产环境', code: 'PROD', sortOrder: 30 },
            ];
            
            await Promise.all(defaults.map(env => 
                createDeployEnvironment({
                    ...env,
                    ssoId: ssoId!,
                    deployType: 'ssh'
                })
            ));
            
            message.success('环境快速初始化成功');
            fetchData();
        } catch (error) {
            message.error('部分环境初始化失败，可能已存在');
        } finally {
            setEnvLoading(false);
        }
    };

    // ========== 部署操作 ==========
    const openDeployConfirm = (pkg: VersionPackage) => {
        setSelectedPackage(pkg);
        deployForm.setFieldsValue({
            packageId: pkg.id,
            envId: environments.length > 0 ? environments[0].id : undefined
        });
        setDeployConfirmVisible(true);
    };

    const handleDeployConfirm = async () => {
        try {
            const values = await deployForm.validateFields();
            await deployWithPackage({
                ...values,
                ssoId: ssoId!,
                deployedBy: 1, // 实际应用中应从当前用户获取
            });
            message.success('部署记录已成功创建');
            setDeployConfirmVisible(false);
            fetchData();
            setActiveTab('history');
        } catch (error) {
            message.error('记录部署失败');
        }
    };

    const primaryButtonClass = 'bg-gradient-to-tr from-indigo-500 to-purple-600 border-none hover:from-indigo-600 hover:to-purple-700';

    return (
        <div className="space-y-6">
            {/* 统计概览 */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <Card className="rounded-2xl border-slate-200 shadow-sm overflow-hidden bg-white">
                    <div className="flex items-center gap-4">
                        <div className="p-3 bg-indigo-50 rounded-xl text-indigo-600">
                            <Package size={24} />
                        </div>
                        <div>
                            <div className="text-xs text-slate-400 font-medium uppercase tracking-wider">总版本包</div>
                            <div className="text-2xl font-bold text-slate-800">{versionPackages.length}</div>
                        </div>
                    </div>
                </Card>
                <Card className="rounded-2xl border-slate-200 shadow-sm overflow-hidden bg-white">
                    <div className="flex items-center gap-4">
                        <div className="p-3 bg-emerald-50 rounded-xl text-emerald-600">
                            <CheckCircle size={24} />
                        </div>
                        <div>
                            <div className="text-xs text-slate-400 font-medium uppercase tracking-wider">最近已部署</div>
                            <div className="text-2xl font-bold text-slate-800">
                                {versionPackages.filter(p => p.status === 'deployed').length}
                            </div>
                        </div>
                    </div>
                </Card>
                <Card className="rounded-2xl border-slate-200 shadow-sm overflow-hidden bg-white">
                    <div className="flex items-center gap-4">
                        <div className="p-3 bg-blue-50 rounded-xl text-blue-600">
                            <History size={24} />
                        </div>
                        <div>
                            <div className="text-xs text-slate-400 font-medium uppercase tracking-wider">部署记录</div>
                            <div className="text-2xl font-bold text-slate-800">{deployments.length}</div>
                        </div>
                    </div>
                </Card>
            </div>

            {/* 操作主区域 */}
            <div className="rounded-2xl border border-slate-200 bg-white shadow-sm overflow-hidden">
                <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-slate-50/50">
                    <div className="flex items-center gap-8">
                        <div 
                            className={`flex items-center gap-2 cursor-pointer transition-colors ${activeTab === 'packages' ? 'text-indigo-600 font-bold' : 'text-slate-500 font-medium'}`}
                            onClick={() => setActiveTab('packages')}
                        >
                            <Package size={18} />
                            版本包管理
                            {activeTab === 'packages' && <div className="ml-1 w-1.5 h-1.5 rounded-full bg-indigo-600" />}
                        </div>
                        <div 
                            className={`flex items-center gap-2 cursor-pointer transition-colors ${activeTab === 'history' ? 'text-indigo-600 font-bold' : 'text-slate-500 font-medium'}`}
                            onClick={() => setActiveTab('history')}
                        >
                            <History size={18} />
                            部署历史
                            {activeTab === 'history' && <div className="ml-1 w-1.5 h-1.5 rounded-full bg-indigo-600" />}
                        </div>
                    </div>
                    <Space>
                        <Button 
                            icon={<RefreshCw size={14} className={loading ? 'animate-spin' : ''} />} 
                            onClick={fetchData}
                        >
                            刷新
                        </Button>
                        <Button 
                            icon={<Settings size={14} />} 
                            onClick={() => setEnvModalVisible(true)}
                        >
                            管理环境
                        </Button>
                        <Button 
                            type="primary" 
                            icon={<Plus size={16} />} 
                            className={primaryButtonClass}
                            onClick={() => {
                                setPackageModalVisible(true);
                                // 如果是从具体仓库页面进来的，自动填充 repoId
                                if (repoId) {
                                    packageForm.setFieldsValue({ repoId });
                                    // 延迟一小会儿执行加载，确保 Modal 内部状态同步
                                    setTimeout(() => handleRepoChange(repoId), 0);
                                }
                            }}
                        >
                            创建版本包
                        </Button>
                    </Space>
                </div>

                <div className="p-6">
                    {activeTab === 'packages' ? (
                        <div className="space-y-4">
                            {versionPackages.length === 0 ? (
                                <div className="py-20 text-center flex flex-col items-center justify-center opacity-40">
                                    <Package size={64} strokeWidth={1} className="mb-4" />
                                    <p>暂无版本包记录，请点击上方按钮从 Git 仓库创建</p>
                                </div>
                            ) : (
                                <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
                                    {versionPackages.map(pkg => {
                                        const config = statusConfig[pkg.status] || statusConfig.draft;
                                        return (
                                            <div key={pkg.id} className="rounded-2xl border border-slate-200 p-5 hover:border-indigo-300 transition-all hover:shadow-md bg-white group">
                                                <div className="flex items-start justify-between mb-4">
                                                    <div>
                                                        <div className="flex items-center gap-2 mb-1">
                                                            <h4 className="text-base font-bold text-slate-800 m-0">版本: {pkg.version}</h4>
                                                            <Tag color={config.color} className="flex items-center gap-1">
                                                                {config.icon} {config.label}
                                                            </Tag>
                                                        </div>
                                                        <div className="text-xs text-slate-400 font-mono">ID: VP-{pkg.id.toString().padStart(6, '0')}</div>
                                                    </div>
                                                    <Dropdown menu={{
                                                        items: [
                                                            { key: 'deployed', label: '标记为已部署', onClick: () => handleUpdateStatus(pkg.id, 'deployed') },
                                                            { key: 'archived', label: '标记为归档', onClick: () => handleUpdateStatus(pkg.id, 'archived') },
                                                            { key: 'delete', label: '删除', danger: true, onClick: () => message.info('功能暂未开放') },
                                                        ]
                                                    }}>
                                                        <Button type="text" icon={<MoreVertical size={16} />} />
                                                    </Dropdown>
                                                </div>

                                                <div className="grid grid-cols-2 gap-y-3 gap-x-6 text-sm">
                                                    <div className="flex items-center gap-2 text-slate-600">
                                                        <Globe size={14} className="text-slate-400" />
                                                        <span className="truncate">仓库: {repos.find(r => r.id === pkg.repoId)?.name || '未知'}</span>
                                                    </div>
                                                    <div className="flex items-center gap-2 text-slate-600">
                                                        <GitBranch size={14} className="text-slate-400" />
                                                        <span>引用: {pkg.gitRef}</span>
                                                    </div>
                                                    <div className="col-span-2 flex items-start gap-2 text-slate-600">
                                                        <Info size={14} className="text-slate-400 mt-1" />
                                                        <span>说明: {pkg.description || '无'}</span>
                                                    </div>
                                                </div>

                                                <div className="mt-5 pt-4 border-t border-slate-100 flex items-center justify-between">
                                                    <div className="text-xs text-slate-400">
                                                        创建时间: {pkg.createdAt ? new Date(pkg.createdAt).toLocaleString() : '-'}
                                                    </div>
                                                    <Space>
                                                        <Button 
                                                            size="small" 
                                                            icon={<Download size={14} />} 
                                                            onClick={() => handleDownload(pkg)}
                                                        >
                                                            下载安装包
                                                        </Button>
                                                        <Button 
                                                            size="small" 
                                                            type="primary" 
                                                            icon={<Rocket size={14} />} 
                                                            ghost
                                                            onClick={() => openDeployConfirm(pkg)}
                                                        >
                                                            登记部署
                                                        </Button>
                                                    </Space>
                                                </div>
                                            </div>
                                        );
                                    })}
                                </div>
                            )}
                        </div>
                    ) : (
                        <div className="max-w-3xl mx-auto">
                            <Timeline
                                mode="left"
                                items={deployments.map(dep => {
                                    const config = statusConfig[dep.status] || statusConfig.success;
                                    return {
                                        label: <span className="text-slate-400 text-xs">{dep.deployedAt}</span>,
                                        children: (
                                            <div className="mb-8">
                                                <div className="flex items-center gap-3 mb-2">
                                                    <div className="text-base font-bold text-slate-800">
                                                        {dep.version || (dep.packageId ? `版本包 #${dep.packageId}` : '未命名发布')}
                                                    </div>
                                                    <Tag color={config.color} className="m-0">{config.label}</Tag>
                                                </div>
                                                <div className="bg-slate-50 rounded-xl p-3 border border-slate-100 text-sm text-slate-600">
                                                    <div className="flex flex-wrap gap-x-6 gap-y-2">
                                                        <div className="flex items-center gap-2">
                                                            <Server size={14} className="text-slate-400" />
                                                            环境: {environments.find(e => e.id === dep.envId)?.name || '未知'}
                                                        </div>
                                                        <div className="flex items-center gap-2 text-slate-400 text-xs italic">
                                                            <Edit size={12} />
                                                            备注: {dep.remark || '无'}
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        ),
                                        dot: <div className={`w-3 h-3 rounded-full ${dep.status === 'success' ? 'bg-emerald-500' : 'bg-slate-300'}`} />,
                                        color: dep.status === 'success' ? 'green' : 'gray'
                                    };
                                })}
                            />
                            {deployments.length === 0 && (
                                <div className="text-center py-10 opacity-40">暂无部署历史记录</div>
                            )}
                        </div>
                    )}
                </div>
            </div>

            {/* 创建版本包 Modal */}
            <Modal
                title={
                    <div className="flex items-center gap-3 py-1">
                        <div className="p-1.5 bg-indigo-50 rounded-lg text-indigo-600">
                            <Package size={18} />
                        </div>
                        <span>创建新版本包</span>
                    </div>
                }
                open={packageModalVisible}
                onOk={handleCreatePackage}
                onCancel={() => setPackageModalVisible(false)}
                okText="创建版本包"
                cancelText="取消"
                width={550}
                centered
            >
                <Form form={packageForm} layout="vertical" className="mt-4 px-1">
                    <Form.Item name="repoId" label="项目仓库" rules={[{ required: true }]}>
                        {repoId ? (
                            <div className="p-3 bg-slate-50 rounded-xl border border-slate-100">
                                <div className="flex items-center gap-2 mb-1">
                                    <Globe size={14} className="text-indigo-500" />
                                    <span className="font-bold text-slate-800">
                                        {repos.find(r => r.id === repoId)?.name || '正在加载...'}
                                    </span>
                                </div>
                                <div className="text-xs text-slate-400 font-mono break-all pl-6">
                                    {repos.find(r => r.id === repoId)?.cloneUrl}
                                </div>
                            </div>
                        ) : (
                            <Select placeholder="选择关联的 Git 仓库" onChange={handleRepoChange}>
                                {repos.map(repo => (
                                    <Option key={repo.id} value={repo.id}>
                                        <div className="flex items-center gap-2">
                                            <Globe size={14} className="text-slate-400" />
                                            <span>{repo.name} {repo.fullName && `(${repo.fullName})`}</span>
                                        </div>
                                    </Option>
                                ))}
                            </Select>
                        )}
                    </Form.Item>

                    <Form.Item name="gitRef" label="版本标签 (Tag)" rules={[{ required: true }]}>
                        <Select 
                            placeholder={selectedRepo ? "选择一个 Git 标签 (Tag)" : "请先选择仓库"} 
                            disabled={!selectedRepo} 
                            loading={fetchingGit}
                            showSearch
                        >
                            {tags.map(tag => (
                                <Option key={`tag-${tag.name}`} value={tag.name}>
                                    <div className="flex items-center gap-2">
                                        <TagIcon size={14} className="text-indigo-500"/>
                                        <span>{tag.name}</span>
                                    </div>
                                </Option>
                            ))}
                        </Select>
                    </Form.Item>

                    <Form.Item name="envId" label="投产环境" rules={[{ required: true, message: '请选择投产环境' }]}>
                        <Select 
                            placeholder="选择该版本拟投产的目标环境" 
                            showSearch
                            optionFilterProp="children"
                        >
                            {environments.map(env => (
                                <Option key={env.id} value={env.id}>
                                    {env.name} ({env.code})
                                </Option>
                            ))}
                        </Select>
                    </Form.Item>

                    <Form.Item name="description" label="版本说明">
                        <Input.TextArea rows={3} placeholder="填写该版本的变更点、注意事项等" />
                    </Form.Item>
                    
                    {environments.length === 0 && (
                        <div className="mt-2 p-3 bg-amber-50 rounded-xl border border-amber-100 flex items-start gap-3">
                            <AlertTriangle size={16} className="text-amber-500 mt-0.5" />
                            <div className="text-xs text-amber-700">
                                <b>注意：</b> 当前系统暂未配置任何投产环境。请关闭此弹窗并点击右上角的“管理环境”进行配置。
                            </div>
                        </div>
                    )}
                </Form>
            </Modal>

            {/* 环境管理 Modal */}
            <Modal
                title={
                    <div className="flex items-center gap-3 py-1">
                        <div className="p-1.5 bg-indigo-50 rounded-lg text-indigo-600">
                            <Settings size={18} />
                        </div>
                        <span>部署环境管理</span>
                    </div>
                }
                open={envModalVisible}
                onCancel={() => setEnvModalVisible(false)}
                footer={null}
                width={650}
                centered
            >
                <div className="space-y-6 mt-4">
                    {/* 环境列表 */}
                    <div>
                        <div className="text-xs font-bold text-slate-400 uppercase mb-3 flex items-center justify-between">
                            <span>当前系统环境列表</span>
                            {environments.length === 0 && (
                                <Button 
                                    type="link" 
                                    size="small" 
                                    icon={<Zap size={12} />} 
                                    onClick={handleQuickInitEnvs}
                                    loading={envLoading}
                                >
                                    快速初始化 (SIT/UAT/PROD)
                                </Button>
                            )}
                        </div>
                        <div className="bg-slate-50 rounded-2xl border border-slate-100 divide-y divide-slate-100 overflow-hidden">
                            {environments.length === 0 ? (
                                <div className="py-8 text-center text-slate-400 text-sm italic">暂无环境配置</div>
                            ) : (
                                environments.map(env => (
                                    <div key={env.id} className="p-3 flex items-center justify-between hover:bg-white transition-colors">
                                        <div className="flex items-center gap-4">
                                            <div className="bg-white p-2 rounded-lg border border-slate-200">
                                                <Server size={14} className="text-slate-500" />
                                            </div>
                                            <div>
                                                <div className="text-sm font-bold text-slate-800">{env.name}</div>
                                                <div className="text-xs text-slate-400 font-mono">{env.code} · {env.deployType}</div>
                                            </div>
                                        </div>
                                        <Popconfirm 
                                            title="确定删除此环境吗？" 
                                            onConfirm={() => env.id && handleDeleteEnv(env.id)}
                                            okButtonProps={{ danger: true }}
                                        >
                                            <Button type="text" danger icon={<Trash2 size={14} />} />
                                        </Popconfirm>
                                    </div>
                                ))
                            )}
                        </div>
                    </div>

                    <Divider className="my-0" />

                    {/* 添加环境表单 */}
                    <div>
                        <div className="text-xs font-bold text-slate-400 uppercase mb-3 font-bold">添加新环境</div>
                        <Form form={envForm} layout="vertical" onFinish={handleAddEnvironment}>
                            <div className="grid grid-cols-2 gap-x-4">
                                <Form.Item name="name" label="环境名称" rules={[{ required: true }]}>
                                    <Input placeholder="例如: 准生产环境" />
                                </Form.Item>
                                <Form.Item name="code" label="环境代码" rules={[{ required: true }]}>
                                    <Input placeholder="例如: PRE" />
                                </Form.Item>
                                <Form.Item name="deployType" label="部署方式" initialValue="ssh">
                                    <Select>
                                        <Option value="ssh">SSH (常规发布)</Option>
                                        <Option value="docker">Docker (镜像发布)</Option>
                                        <Option value="k8s">K8s (容器发布)</Option>
                                    </Select>
                                </Form.Item>
                                <Form.Item name="sortOrder" label="排序权重" initialValue={10}>
                                    <Input type="number" />
                                </Form.Item>
                            </div>
                            <Button type="dashed" block icon={<Plus size={14} />} onClick={() => envForm.submit()}>
                                点击添加环境
                            </Button>
                        </Form>
                    </div>
                </div>
            </Modal>

            {/* 登记部署 Modal */}
            <Modal
                title="登记部署执行结果"
                open={deployConfirmVisible}
                onOk={handleDeployConfirm}
                onCancel={() => setDeployConfirmVisible(false)}
                okText="确认登记"
                centered
            >
                <Form form={deployForm} layout="vertical" className="mt-4">
                    <div className="mb-4 p-3 bg-indigo-50 rounded-xl border border-indigo-100 flex items-center gap-3">
                        <Rocket size={18} className="text-indigo-600" />
                        <div>
                            <div className="text-xs text-indigo-400">正在为以下版本登记部署</div>
                            <div className="text-sm font-bold text-indigo-900">{selectedPackage?.version} ({selectedPackage?.gitRef})</div>
                        </div>
                    </div>
                    
                    <Form.Item name="envId" label="部署目标环境" rules={[{ required: true }]}>
                        <Select placeholder="选择实际部署的环境">
                            {environments.map(env => (
                                <Option key={env.id} value={env.id}>{env.name} ({env.code})</Option>
                            ))}
                        </Select>
                    </Form.Item>

                    <Form.Item name="remark" label="部署备注">
                        <Input.TextArea placeholder="手工部署后的执行发现、通过情况等" />
                    </Form.Item>
                </Form>
            </Modal>
        </div>
    );
};

export default DeploymentManagement;
