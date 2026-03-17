import React, { useState, useEffect, useMemo } from 'react';
import { Button, Modal, Form, Input, Select, Tag, Space, message, Popconfirm, Badge, List, Card, Timeline, Divider, Dropdown } from 'antd';
import { 
    Plus, Trash2, Edit, RefreshCw, Server, Rocket, RotateCcw, 
    CheckCircle, XCircle, Loader, Clock, Globe, Download, 
    ChevronRight, Info, Package, GitBranch, Tag as TagIcon, MoreVertical, 
    Play, Activity, ShieldCheck, History, Zap, AlertTriangle
} from 'lucide-react';
import {
    getDeployEnvironments, 
    getDeployments, 
    getSsoList,
} from '@/api/version';
import {
    getInfrastructureAssets,
    InfrastructureAsset
} from '@/api/ops';
import {
    getGitRepositories,
    getRepoBranches,
    getRepoTags,
    getVersionPackages,
    createVersionPackage,
    downloadVersionPackage,
    updatePackageStatus,
    deployWithPackage,
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
    const [infraAssets, setInfraAssets] = useState<InfrastructureAsset[]>([]);
    const [availableUsers, setAvailableUsers] = useState<string[]>([]);
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


    useEffect(() => {
        if (ssoId) {
            fetchData();
        }
    }, [ssoId]);

    const fetchData = async () => {
        setLoading(true);
        try {
            const [envs, deps, pkgs, repositories, assets] = await Promise.all([
                getDeployEnvironments(ssoId),
                getDeployments({ ssoId }),
                getVersionPackages(ssoId!),
                getGitRepositories({ ssoId }),
                getInfrastructureAssets({ appSystemId: Number(ssoId) })
            ]);
            setEnvironments(envs || []);
            setDeployments(deps || []);
            setVersionPackages(pkgs || []);
            setRepos(repositories || []);
            setInfraAssets(assets || []);
        } catch (error) {
            message.error('加载数据失败');
        } finally {
            setLoading(false);
        }
    };

    // ========== 派生数据 ==========
    // 筛选出 role=db 的数据库服务器，供版本包创建时选择单台服务器
    const dbAssets = useMemo(() => {
        return infraAssets.filter(a => a.role === 'db');
    }, [infraAssets]);

    const handleAssetChange = (assetId: any) => {
        if (!assetId) {
            setAvailableUsers([]);
            packageForm.setFieldsValue({ execUser: undefined });
            return;
        }

        const asset = infraAssets.find(a => a.id === assetId);
        if (asset) {
            // 从该服务器的 users 中筛选 userType=db 的数据库用户
            const dbUsers = (asset.users || [])
                .filter((u: any) => u.userType === 'db')
                .map((u: any) => u.username)
                .filter(Boolean);

            console.log(`Selected Asset: ${asset.hostname} (${asset.internalIp}), DB Users:`, dbUsers);
            setAvailableUsers(dbUsers);

            // 智能选中：如果只有一个 db 用户，自动填入
            const current = packageForm.getFieldValue('execUser');
            if (dbUsers.length === 1 && (!current || !dbUsers.includes(current))) {
                packageForm.setFieldsValue({ execUser: dbUsers[0] });
            } else if (!dbUsers.includes(current)) {
                packageForm.setFieldsValue({ execUser: undefined });
            }
        } else {
            setAvailableUsers([]);
        }
    };

    const watchedAssetId = Form.useWatch('assetId', packageForm);

    useEffect(() => {
        if (watchedAssetId) {
            handleAssetChange(watchedAssetId);
        } else {
            setAvailableUsers([]);
        }
    }, [watchedAssetId, infraAssets]);

    // ========== 版本包操作 ==========
    const handleRepoChange = async (repoId: number) => {
        setSelectedRepo(repoId);
        setFetchingGit(true);
        packageForm.setFieldsValue({ gitRef: undefined, previousGitRef: undefined });
        try {
            const [b, t] = await Promise.all([
                getRepoBranches(repoId),
                getRepoTags(repoId)
            ]);
            setBranches(b || []);
            // 按 taggerDate 时间倒序排列
            const sortedTags = [...(t || [])].sort((a, b) => {
                const dateA = a.taggerDate || '';
                const dateB = b.taggerDate || '';
                return dateB.localeCompare(dateA);
            });
            setTags(sortedTags);
        } catch (error) {
            message.error('获取仓库分支/标签失败');
        } finally {
            setFetchingGit(false);
        }
    };

    // 选择当前 tag 后，自动填入基线 tag（时间线上的前一个）
    const handleTagChange = (tagName: string) => {
        const idx = tags.findIndex(t => t.name === tagName);
        if (idx >= 0 && idx + 1 < tags.length) {
            packageForm.setFieldsValue({ previousGitRef: tags[idx + 1].name });
        } else {
            packageForm.setFieldsValue({ previousGitRef: undefined });
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
                                                    <div className="flex items-center gap-2 text-slate-600">
                                                        <Server size={14} className="text-slate-400" />
                                                        <span className="truncate">环境: {environments.find(e => String(e.id) === String(pkg.envId))?.name || '-'}</span>
                                                    </div>
                                                    <div className="flex items-center gap-2 text-slate-600">
                                                        <ShieldCheck size={14} className="text-emerald-500" />
                                                        <span>执行用户: {pkg.execUser || '-'}</span>
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
                            onChange={handleTagChange}
                        >
                            {tags.map(tag => (
                                <Option key={`tag-${tag.name}`} value={tag.name}>
                                    <div className="flex items-center gap-2">
                                        <TagIcon size={14} className="text-indigo-500"/>
                                        <span>{tag.name}</span>
                                        {tag.taggerDate && (
                                            <span className="text-[10px] text-slate-400 ml-auto">{tag.taggerDate.split('T')[0]}</span>
                                        )}
                                    </div>
                                </Option>
                            ))}
                        </Select>
                    </Form.Item>

                    <Form.Item name="previousGitRef" label="基线标签 (上一版本 Tag)" rules={[{ required: true, message: '请选择基线标签' }]}
                        tooltip="用于对比差异，只打包两个标签之间变更的数据库脚本"
                    >
                        <Select
                            placeholder={selectedRepo ? "自动选择上一版本标签（可手动修改）" : "请先选择仓库"}
                            disabled={!selectedRepo}
                            loading={fetchingGit}
                            showSearch
                        >
                            {tags
                                .filter(tag => tag.name !== packageForm.getFieldValue('gitRef'))
                                .map(tag => (
                                <Option key={`prev-${tag.name}`} value={tag.name}>
                                    <div className="flex items-center gap-2">
                                        <History size={14} className="text-slate-400"/>
                                        <span>{tag.name}</span>
                                        {tag.taggerDate && (
                                            <span className="text-[10px] text-slate-400 ml-auto">{tag.taggerDate.split('T')[0]}</span>
                                        )}
                                    </div>
                                </Option>
                            ))}
                        </Select>
                    </Form.Item>

                    <Form.Item name="envId" label="目标环境" rules={[{ required: true, message: '请选择目标投产环境' }]}>
                        <Select placeholder="选择该版本包对应的投产环境" optionLabelProp="label">
                            {environments.map(env => (
                                <Option key={env.id} value={env.id} label={env.name}>
                                    <div className="py-1">
                                        <span className="font-bold text-slate-800">{env.name}</span>
                                        <span className="ml-2 text-[10px] text-slate-400">{env.code}</span>
                                    </div>
                                </Option>
                            ))}
                        </Select>
                    </Form.Item>

                    <Form.Item name="assetId" label="投产数据库服务器" rules={[{ required: true, message: '请选择投产数据库服务器' }]}>
                        <Select
                            placeholder="选择该版本拟投产的目标数据库服务器"
                            showSearch
                            optionFilterProp="label"
                            onChange={handleAssetChange}
                        >
                            {dbAssets.map(asset => (
                                <Option key={asset.id} value={asset.id} label={`${asset.hostname} ${asset.internalIp}`}>
                                    <div className="flex items-center justify-between py-1">
                                        <div className="flex items-center gap-2 overflow-hidden">
                                            <Server size={14} className="text-indigo-500 shrink-0" />
                                            <span className="font-bold text-slate-800 truncate">{asset.hostname || '未命名'}</span>
                                            <span className="text-slate-400 text-xs shrink-0">{asset.internalIp}</span>
                                        </div>
                                        <div className="flex items-center gap-2 shrink-0">
                                            {asset.dbType && <Tag color="purple" className="m-0 text-[10px]">{asset.dbType}</Tag>}
                                            {asset.envType && <Tag color="blue" className="m-0 text-[10px]">{asset.envType}</Tag>}
                                        </div>
                                    </div>
                                </Option>
                            ))}
                        </Select>
                    </Form.Item>
                    
                    <Form.Item name="execUser" label="执行用户" rules={[{ required: true, message: '请选择执行用户' }]}>
                        <Select 
                            placeholder={availableUsers.length > 0 ? "选择环境鉴权账号" : "该环境暂未配置鉴权账号"}
                            allowClear
                            showSearch
                        >
                            {availableUsers.map(user => (
                                <Option key={user} value={user}>
                                    <div className="flex items-center gap-2">
                                        <ShieldCheck size={14} className="text-emerald-500" />
                                        <span>{user}</span>
                                    </div>
                                </Option>
                            ))}
                        </Select>
                    </Form.Item>

                    <Form.Item name="description" label="版本说明">
                        <Input.TextArea rows={3} placeholder="填写该版本的变更点、注意事项等" />
                    </Form.Item>
                    
                    {dbAssets.length === 0 && (
                        <div className="mt-2 p-3 bg-amber-50 rounded-xl border border-amber-100 flex items-start gap-3">
                            <AlertTriangle size={16} className="text-amber-500 mt-0.5" />
                            <div className="text-xs text-amber-700">
                                <b>{'注意：'}</b> {'当前系统暂未配置任何数据库服务器(role=db)，请前往基础设施管理添加数据库服务器。'}
                            </div>
                        </div>
                    )}
                </Form>
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
                        <Select 
                            placeholder="选择实际部署的环境"
                            optionLabelProp="label"
                        >
                            {environments.map(env => (
                                <Option key={env.id} value={env.id} label={env.name}>
                                    <div className="py-1">
                                        <span className="font-bold text-slate-800">{env.name}</span>
                                        <span className="ml-2 text-[10px] text-slate-400">{env.code}</span>
                                    </div>
                                </Option>
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
