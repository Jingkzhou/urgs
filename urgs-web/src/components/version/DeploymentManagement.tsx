import React, { useState, useEffect, useMemo } from 'react';
import { Button, Modal, Form, Input, Select, Tag, Space, message, Popconfirm, Badge } from 'antd';
import { Plus, Trash2, Edit, RefreshCw, Server, Rocket, RotateCcw, CheckCircle, XCircle, Loader, Clock, Globe } from 'lucide-react';
import {
    getDeployEnvironments, createDeployEnvironment, updateDeployEnvironment, deleteDeployEnvironment,
    getDeployments, executeDeploy, rollbackDeploy,
    getSsoList,
    DeployEnvironment, Deployment, SsoConfig
} from '@/api/version';
import { getInfrastructureAssets, InfrastructureAsset } from '@/api/ops';

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
    const [environments, setEnvironments] = useState<DeployEnvironment[]>([]);
    const [deployments, setDeployments] = useState<Deployment[]>([]);
    const [ssoList, setSsoList] = useState<SsoConfig[]>([]);
    const [infrastructureAssets, setInfrastructureAssets] = useState<InfrastructureAsset[]>([]);
    const [loading, setLoading] = useState(false);
    const [envSearchKeyword, setEnvSearchKeyword] = useState('');

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
        fetchInfrastructureAssets();
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

    const fetchInfrastructureAssets = async () => {
        try {
            const data = await getInfrastructureAssets({ appSystemId: ssoId });
            setInfrastructureAssets(data || []);
        } catch (error) {
            console.error('获取基础设施资产失败', error);
        }
    };

    // 按系统和环境类型分组的服务器资产
    const filteredAssets = useMemo(() => {
        return infrastructureAssets.filter(asset => {
            const matchSearch = !envSearchKeyword ||
                asset.hostname?.toLowerCase().includes(envSearchKeyword.toLowerCase()) ||
                asset.internalIp?.toLowerCase().includes(envSearchKeyword.toLowerCase());
            return matchSearch;
        });
    }, [infrastructureAssets, envSearchKeyword]);

    // 按环境类型分组
    const assetsByEnvType = useMemo(() => {
        const groups: Record<string, InfrastructureAsset[]> = {};
        filteredAssets.forEach(asset => {
            const envType = asset.envType || '未分类';
            if (!groups[envType]) {
                groups[envType] = [];
            }
            groups[envType].push(asset);
        });
        return groups;
    }, [filteredAssets]);

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

    const deployTypeLabelMap: Record<string, string> = {
        ssh: 'SSH',
        docker: 'Docker',
        k8s: 'Kubernetes',
    };

    const mockEnvironments: DeployEnvironment[] = [
        {
            id: 1,
            name: '开发环境',
            code: 'dev',
            ssoId: ssoId ?? 0,
            deployType: 'k8s',
            deployUrl: 'dev-cluster',
        },
        {
            id: 2,
            name: '预发环境',
            code: 'staging',
            ssoId: ssoId ?? 0,
            deployType: 'docker',
            deployUrl: 'staging-node-01',
        },
        {
            id: 3,
            name: '生产环境',
            code: 'prod',
            ssoId: ssoId ?? 0,
            deployType: 'k8s',
            deployUrl: 'prod-east',
        },
    ];

    const mockDeployments: Deployment[] = [
        {
            id: 101,
            ssoId: ssoId ?? 0,
            envId: 2,
            version: 'v2.4.8',
            status: 'deploying',
            deployedAt: '2 分钟前',
        },
        {
            id: 102,
            ssoId: ssoId ?? 0,
            envId: 3,
            version: 'v2.4.7',
            status: 'success',
            deployedAt: '15 分钟前',
        },
        {
            id: 103,
            ssoId: ssoId ?? 0,
            envId: 1,
            version: 'v2.4.6',
            status: 'failed',
            deployedAt: '1 小时前',
        },
    ];

    const envItems = environments.length > 0 ? environments : mockEnvironments;
    const deploymentItems = deployments.length > 0 ? deployments : mockDeployments;

    const primaryButtonClass =
        'bg-gradient-to-tr from-indigo-500 to-purple-600 border-none hover:from-indigo-600 hover:to-purple-700';
    const secondaryButtonClass =
        'border-indigo-200 text-indigo-600 hover:text-indigo-700 hover:border-indigo-300';
    const subtleButtonClass =
        'border-slate-200 text-slate-600 hover:text-indigo-700 hover:border-indigo-200';

    const overviewStats = [
        { label: '发布成功率', value: '98.1%', note: '近 30 天' },
        { label: '平均耗时', value: '11m 42s', note: 'P95 18m' },
        { label: '回滚率', value: '1.2%', note: '趋势下降' },
        { label: '风险指数', value: '低', note: '合规通过' },
    ];

    const rolloutStages = [
        { title: '制品准备', subtitle: '签名 / SBOM', badge: '可信链' },
        { title: '质量门禁', subtitle: 'SAST/DAST', badge: 'Policy' },
        { title: '灰度发布', subtitle: '5% → 30%', badge: 'Canary' },
        { title: '全量发布', subtitle: '多区域', badge: 'Global' },
        { title: '运行观测', subtitle: 'SLO / 回归', badge: 'Observe' },
    ];

    const envNameMap = (envId: number) => envItems.find(item => item.id === envId)?.name || '-';

    return (
        <div className="relative">
            <div className="rounded-2xl border border-slate-200 bg-white shadow-sm overflow-hidden">
                <div className="relative bg-gradient-to-r from-indigo-600 via-indigo-500 to-purple-600">
                    <div
                        className="absolute inset-0 opacity-20"
                        style={{
                            backgroundImage: 'radial-gradient(circle at 20% 20%, rgba(255,255,255,0.4), transparent 40%), radial-gradient(circle at 80% 0%, rgba(255,255,255,0.2), transparent 45%)',
                        }}
                    />
                    <div className="relative px-6 py-5 text-white">
                        <div className="flex flex-wrap items-center justify-between gap-4">
                            <div>
                                <div className="text-xs uppercase tracking-[0.2em] text-indigo-100">Deployment Control</div>
                                <h3 className="text-xl font-semibold text-white">部署管理中心</h3>
                                <p className="text-sm text-indigo-100">多环境发布 · 门禁合规 · 回滚保障</p>
                            </div>
                            <Space>
                                <Button
                                    icon={<RefreshCw size={14} />}
                                    onClick={() => {
                                        fetchDeployments();
                                        fetchEnvironments();
                                    }}
                                    loading={loading}
                                    className="text-white border-white/40 hover:border-white"
                                >
                                    刷新
                                </Button>
                                <Button type="primary" icon={<Rocket size={14} />} onClick={handleDeploy} className={primaryButtonClass}>
                                    执行部署
                                </Button>
                            </Space>
                        </div>
                        <div className="mt-5 grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-3">
                            {overviewStats.map(stat => (
                                <div key={stat.label} className="rounded-xl border border-white/30 bg-white/10 px-4 py-3 backdrop-blur">
                                    <div className="text-xs uppercase tracking-wide text-indigo-100">{stat.label}</div>
                                    <div className="mt-2 flex items-end justify-between">
                                        <span className="text-lg font-semibold text-white">{stat.value}</span>
                                        <span className="text-xs text-indigo-100">{stat.note}</span>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>

                <div className="bg-slate-50 px-6 py-6">
                    <div className="grid grid-cols-1 xl:grid-cols-[280px_minmax(0,1fr)_320px] gap-5">
                        <aside className="space-y-5">
                            <div className="rounded-2xl border border-slate-200 bg-white p-4">
                                <div className="flex items-center justify-between mb-3">
                                    <div>
                                        <div className="text-xs uppercase tracking-widest text-slate-400">服务器资产</div>
                                        <div className="text-sm font-semibold text-slate-800">关联服务器</div>
                                    </div>
                                    <Tag color="blue">{infrastructureAssets.length}</Tag>
                                </div>
                                <Input
                                    placeholder="搜索主机名或IP"
                                    className="border-slate-200"
                                    value={envSearchKeyword}
                                    onChange={(e) => setEnvSearchKeyword(e.target.value)}
                                    allowClear
                                />
                                <div className="mt-3 flex flex-wrap gap-2">
                                    {Object.keys(assetsByEnvType).map(envType => (
                                        <span
                                            key={envType}
                                            className="rounded-full border border-slate-200 px-2.5 py-1 text-[11px] font-semibold text-slate-500"
                                        >
                                            {envType} ({assetsByEnvType[envType].length})
                                        </span>
                                    ))}
                                </div>
                                <div className="mt-4 space-y-4 max-h-[400px] overflow-y-auto">
                                    {Object.entries(assetsByEnvType).map(([envType, assets]) => (
                                        <div key={envType}>
                                            <div className="flex items-center gap-2 mb-2">
                                                <Tag color={envType.includes('生产') ? 'red' : envType.includes('测试') ? 'blue' : 'default'} className="m-0">
                                                    {envType}
                                                </Tag>
                                                <span className="text-xs text-slate-400">{assets.length} 台服务器</span>
                                            </div>
                                            <div className="space-y-2">
                                                {assets.map(asset => (
                                                    <div key={asset.id} className="rounded-xl border border-slate-200 bg-white p-3 shadow-sm hover:border-indigo-200 transition-colors">
                                                        <div className="flex items-start justify-between gap-2">
                                                            <div className="flex-1 min-w-0">
                                                                <div className="flex items-center gap-2">
                                                                    <Server size={14} className="text-indigo-500 flex-shrink-0" />
                                                                    <span className="text-sm font-semibold text-slate-800 truncate">{asset.hostname}</span>
                                                                </div>
                                                                <div className="mt-1 text-xs text-slate-500 font-mono flex items-center gap-1">
                                                                    <Globe size={12} />
                                                                    {asset.internalIp}
                                                                </div>
                                                            </div>
                                                            <Badge
                                                                status={asset.status === 'active' ? 'success' : asset.status === 'maintenance' ? 'warning' : 'default'}
                                                                text={asset.status === 'active' ? '运行中' : asset.status === 'maintenance' ? '维护中' : '离线'}
                                                                className="text-[10px]"
                                                            />
                                                        </div>
                                                        <div className="mt-2 flex flex-wrap items-center gap-2 text-[10px] text-slate-400">
                                                            {asset.cpu && <span>CPU: {asset.cpu}</span>}
                                                            {asset.memory && <span>内存: {asset.memory}</span>}
                                                            {asset.role && <Tag className="m-0 text-[10px]">{asset.role}</Tag>}
                                                        </div>
                                                    </div>
                                                ))}
                                            </div>
                                        </div>
                                    ))}
                                    {Object.keys(assetsByEnvType).length === 0 && (
                                        <div className="text-center text-slate-400 text-sm py-8">
                                            <Server size={32} className="mx-auto mb-2 opacity-30" />
                                            <div>暂无关联服务器</div>
                                            <div className="text-xs mt-1">请在基础设施管理中添加服务器并关联系统</div>
                                        </div>
                                    )}
                                </div>
                                <Button type="primary" icon={<RefreshCw size={14} />} onClick={fetchInfrastructureAssets} className={`mt-4 w-full ${primaryButtonClass}`}>
                                    刷新资产
                                </Button>
                            </div>

                            <div className="rounded-2xl border border-slate-200 bg-white p-4">
                                <div className="text-xs uppercase tracking-widest text-slate-400">发布窗口</div>
                                <div className="mt-2 text-sm font-semibold text-slate-800">全局窗口状态</div>
                                <div className="mt-3 space-y-3 text-xs text-slate-500">
                                    <div className="rounded-xl border border-slate-100 bg-slate-50 px-3 py-3">
                                        <div className="flex items-center justify-between">
                                            <span>当前窗口</span>
                                            <span className="font-semibold text-emerald-600">开放</span>
                                        </div>
                                        <div className="mt-2 text-[10px] text-slate-400">下一次冻结: 周四 20:00</div>
                                    </div>
                                    <div className="rounded-xl border border-slate-100 bg-slate-50 px-3 py-3">
                                        <div className="flex items-center justify-between">
                                            <span>审批队列</span>
                                            <span className="font-semibold text-slate-700">2</span>
                                        </div>
                                        <div className="mt-2 text-[10px] text-slate-400">平均处理 18m</div>
                                    </div>
                                </div>
                            </div>
                        </aside>

                        <section className="space-y-5">
                            <div className="rounded-2xl border border-slate-200 bg-white p-5">
                                <div className="flex items-center justify-between">
                                    <div>
                                        <div className="text-xs uppercase tracking-widest text-slate-400">Release Orchestration</div>
                                        <div className="text-sm font-semibold text-slate-800">发布编排</div>
                                    </div>
                                    <div className="text-xs text-slate-500">策略: 金丝雀发布</div>
                                </div>
                                <div className="mt-4 grid grid-cols-1 md:grid-cols-5 gap-3">
                                    {rolloutStages.map(stage => (
                                        <div key={stage.title} className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-3">
                                            <div className="flex items-center justify-between">
                                                <span className="text-sm font-semibold text-slate-800">{stage.title}</span>
                                                <span className="rounded-full bg-white px-2 py-0.5 text-[10px] font-semibold text-slate-500">
                                                    {stage.badge}
                                                </span>
                                            </div>
                                            <div className="mt-1 text-xs text-slate-500">{stage.subtitle}</div>
                                        </div>
                                    ))}
                                </div>
                                <div className="mt-4 rounded-xl border border-slate-200 bg-white px-4 py-3 text-xs text-slate-500">
                                    <div className="flex items-center justify-between">
                                        <span>分流曲线</span>
                                        <span>5% → 30% → 60% → 100%</span>
                                    </div>
                                    <div className="mt-2 h-1.5 rounded-full bg-slate-200">
                                        <div className="h-1.5 w-3/5 rounded-full bg-indigo-500" />
                                    </div>
                                </div>
                            </div>

                            <div className="rounded-2xl border border-slate-200 bg-white p-5">
                                <div className="flex items-center justify-between">
                                    <div>
                                        <div className="text-xs uppercase tracking-widest text-slate-400">Live Delivery</div>
                                        <div className="text-sm font-semibold text-slate-800">部署队列</div>
                                    </div>
                                    <Button size="small" className={secondaryButtonClass}>
                                        查看策略
                                    </Button>
                                </div>
                                <div className="mt-4 space-y-3">
                                    {deploymentItems.slice(0, 3).map(deployment => {
                                        const config = statusConfig[deployment.status] || statusConfig.pending;
                                        return (
                                            <div key={deployment.id} className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-slate-100 bg-slate-50 px-4 py-3">
                                                <div className="flex items-center gap-2 text-sm font-semibold text-slate-700">
                                                    {config.icon}
                                                    {deployment.version || '-'}
                                                </div>
                                                <span className="text-xs text-slate-500">{envNameMap(deployment.envId)}</span>
                                                <Tag color={config.color}>{config.label}</Tag>
                                                <span className="text-xs text-slate-400">{deployment.deployedAt || '-'}</span>
                                            </div>
                                        );
                                    })}
                                </div>
                            </div>
                        </section>

                        <aside className="space-y-5">
                            <div className="rounded-2xl border border-slate-200 bg-white p-4">
                                <div className="text-xs uppercase tracking-widest text-slate-400">门禁与审批</div>
                                <div className="mt-2 text-sm font-semibold text-slate-800">合规矩阵</div>
                                <div className="mt-4 space-y-3 text-xs text-slate-500">
                                    {[
                                        { label: 'SAST 扫描', status: '通过', tone: 'emerald' },
                                        { label: 'DAST 扫描', status: '通过', tone: 'emerald' },
                                        { label: '依赖安全', status: '轻微警告', tone: 'amber' },
                                        { label: '签名验证', status: '通过', tone: 'emerald' },
                                    ].map(item => (
                                        <div key={item.label} className="flex items-center justify-between rounded-xl border border-slate-100 bg-slate-50 px-3 py-3">
                                            <span>{item.label}</span>
                                            <span className={`font-semibold ${item.tone === 'amber' ? 'text-amber-600' : 'text-emerald-600'}`}>
                                                {item.status}
                                            </span>
                                        </div>
                                    ))}
                                    <div className="rounded-xl border border-slate-100 bg-slate-50 px-3 py-3">
                                        <div className="text-[10px] uppercase tracking-widest text-slate-400">审批链</div>
                                        <div className="mt-2 text-xs text-slate-500">研发 → 安全 → 运维</div>
                                    </div>
                                </div>
                            </div>

                            <div className="rounded-2xl border border-slate-200 bg-white p-4">
                                <div className="text-xs uppercase tracking-widest text-slate-400">回滚保障</div>
                                <div className="mt-2 text-sm font-semibold text-slate-800">稳定性护栏</div>
                                <div className="mt-4 space-y-3 text-xs text-slate-500">
                                    <div className="rounded-xl border border-slate-100 bg-slate-50 px-3 py-3">
                                        <div className="flex items-center justify-between">
                                            <span>回滚准备度</span>
                                            <span className="font-semibold text-indigo-600">98%</span>
                                        </div>
                                        <div className="mt-2 text-[10px] text-slate-400">镜像可用 · 配置回滚</div>
                                    </div>
                                    <div className="rounded-xl border border-slate-100 bg-slate-50 px-3 py-3">
                                        <div className="flex items-center justify-between">
                                            <span>平均 MTTR</span>
                                            <span className="font-semibold text-slate-700">9m</span>
                                        </div>
                                        <div className="mt-2 text-[10px] text-slate-400">近 10 次回滚</div>
                                    </div>
                                    <Button className={`w-full ${secondaryButtonClass}`} icon={<RotateCcw size={14} />}>
                                        一键回滚预案
                                    </Button>
                                </div>
                            </div>
                        </aside>
                    </div>

                    <div className="mt-6 grid grid-cols-1 lg:grid-cols-[minmax(0,1fr)_320px] gap-5">
                        <div className="rounded-2xl border border-slate-200 bg-white p-5">
                            <div className="flex items-center justify-between">
                                <div>
                                    <div className="text-xs uppercase tracking-widest text-slate-400">Recent Deployments</div>
                                    <div className="text-sm font-semibold text-slate-800">部署记录</div>
                                </div>
                                <Button size="small" className={secondaryButtonClass} onClick={fetchDeployments}>
                                    刷新记录
                                </Button>
                            </div>
                            <div className="mt-4 space-y-3">
                                {deploymentItems.map(deployment => {
                                    const config = statusConfig[deployment.status] || statusConfig.pending;
                                    return (
                                        <div key={deployment.id} className="rounded-xl border border-slate-100 bg-slate-50 px-4 py-3">
                                            <div className="flex flex-wrap items-center justify-between gap-3">
                                                <div className="flex items-center gap-2 text-sm font-semibold text-slate-700">
                                                    {config.icon}
                                                    {deployment.version || '-'}
                                                    {deployment.rollbackTo ? <Tag color="orange" className="text-xs">回滚</Tag> : null}
                                                </div>
                                                <Tag color={config.color}>{config.label}</Tag>
                                            </div>
                                            <div className="mt-2 text-xs text-slate-500">
                                                环境: {envNameMap(deployment.envId)} · {deployment.deployedAt || '-'}
                                            </div>
                                            <div className="mt-3 flex flex-wrap items-center gap-2">
                                                {deployment.status === 'success' && !deployment.rollbackTo ? (
                                                    <Popconfirm title="确定回滚到此版本？" onConfirm={() => handleRollback(deployment)}>
                                                        <Button size="small" className={secondaryButtonClass} icon={<RotateCcw size={12} />}>
                                                            回滚
                                                        </Button>
                                                    </Popconfirm>
                                                ) : null}
                                                <Button size="small" className={subtleButtonClass} icon={<Rocket size={12} />} onClick={handleDeploy}>
                                                    复用发布
                                                </Button>
                                            </div>
                                        </div>
                                    );
                                })}
                            </div>
                        </div>

                        <div className="rounded-2xl border border-slate-200 bg-white p-5">
                            <div className="text-xs uppercase tracking-widest text-slate-400">Risk Radar</div>
                            <div className="text-sm font-semibold text-slate-800">风险与告警</div>
                            <div className="mt-4 space-y-3 text-xs text-slate-500">
                                <div className="rounded-xl border border-rose-100 bg-rose-50 px-3 py-3">
                                    <div className="flex items-center justify-between">
                                        <span>发布失败波动</span>
                                        <span className="text-rose-600 font-semibold">3 次</span>
                                    </div>
                                    <div className="mt-2 text-[10px] text-rose-400">建议提升集成测试稳定性</div>
                                </div>
                                <div className="rounded-xl border border-amber-100 bg-amber-50 px-3 py-3">
                                    <div className="flex items-center justify-between">
                                        <span>审批延迟</span>
                                        <span className="text-amber-600 font-semibold">2 项</span>
                                    </div>
                                    <div className="mt-2 text-[10px] text-amber-400">超出 SLA 15 分钟</div>
                                </div>
                                <div className="rounded-xl border border-slate-100 bg-slate-50 px-3 py-3">
                                    <div className="flex items-center justify-between">
                                        <span>环境漂移</span>
                                        <span className="text-slate-700 font-semibold">无</span>
                                    </div>
                                    <div className="mt-2 text-[10px] text-slate-400">GitOps 同步正常</div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

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
