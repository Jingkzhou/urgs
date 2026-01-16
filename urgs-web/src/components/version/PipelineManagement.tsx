import React, { useState, useEffect } from 'react';
import { Button, Modal, Form, Input, Select, Tag, Space, message, Popconfirm, Switch, Drawer, Timeline } from 'antd';
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

    const triggerLabelMap: Record<string, string> = {
        manual: '手动',
        webhook: 'Webhook',
        schedule: '定时',
    };

    const mockPipelines: Pipeline[] = [
        {
            id: 1001,
            name: '生产发布流水线',
            ssoId: ssoId ?? 0,
            repoId: repoId,
            triggerType: 'manual',
            enabled: true,
        },
        {
            id: 1002,
            name: '灰度回归验证',
            ssoId: ssoId ?? 0,
            repoId: repoId,
            triggerType: 'webhook',
            enabled: true,
        },
        {
            id: 1003,
            name: '安全基线巡检',
            ssoId: ssoId ?? 0,
            repoId: repoId,
            triggerType: 'schedule',
            enabled: false,
        },
    ];

    const mockRuns: PipelineRun[] = [
        {
            id: 501,
            pipelineId: 1001,
            runNumber: 248,
            status: 'running',
            triggerType: 'manual',
            branch: 'main',
            startedAt: '2 分钟前',
        },
        {
            id: 502,
            pipelineId: 1002,
            runNumber: 247,
            status: 'success',
            triggerType: 'webhook',
            branch: 'release/1.8',
            finishedAt: '12 分钟前',
        },
        {
            id: 503,
            pipelineId: 1003,
            runNumber: 246,
            status: 'failed',
            triggerType: 'schedule',
            branch: 'develop',
            finishedAt: '30 分钟前',
        },
    ];

    const pipelineItems = pipelines.length > 0 ? pipelines : mockPipelines;
    const runPreview = runs.length > 0 ? runs.slice(0, 3) : mockRuns;

    const primaryButtonClass =
        'bg-gradient-to-tr from-indigo-500 to-purple-600 border-none hover:from-indigo-600 hover:to-purple-700';
    const secondaryButtonClass =
        'border-indigo-200 text-indigo-600 hover:text-indigo-700 hover:border-indigo-300';
    const subtleButtonClass =
        'border-slate-200 text-slate-600 hover:text-indigo-700 hover:border-indigo-200';

    const overviewStats = [
        { label: '成功率', value: '98.2%', note: '近 30 天', tone: 'emerald' },
        { label: '平均耗时', value: '12m 34s', note: 'SLA 20m', tone: 'indigo' },
        { label: '排队时长', value: '2m 10s', note: 'P95 4m', tone: 'amber' },
        { label: '失败率', value: '1.8%', note: '下降 0.6%', tone: 'rose' },
    ];

    const stageNodes = [
        {
            id: 'source',
            title: 'Source',
            subtitle: '代码与制品',
            badge: 'Webhook',
            tone: 'indigo',
            left: '6%',
            top: '18%',
        },
        {
            id: 'build',
            title: 'Build',
            subtitle: '并行构建',
            badge: 'Cache',
            tone: 'emerald',
            left: '33%',
            top: '18%',
        },
        {
            id: 'test',
            title: 'Test',
            subtitle: '质量门禁',
            badge: 'Policy',
            tone: 'amber',
            left: '60%',
            top: '18%',
        },
        {
            id: 'deploy',
            title: 'Deploy',
            subtitle: '灰度发布',
            badge: 'Canary',
            tone: 'violet',
            left: '33%',
            top: '55%',
        },
        {
            id: 'observe',
            title: 'Observe',
            subtitle: '可观测',
            badge: 'SLO',
            tone: 'sky',
            left: '60%',
            top: '55%',
        },
    ];

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
                                <div className="text-xs uppercase tracking-[0.2em] text-indigo-100">Pipeline Studio</div>
                                <h3 className="text-xl font-semibold text-white">流水线控制台</h3>
                                <p className="text-sm text-indigo-100">全链路交付 · 合规门禁 · 运行洞察</p>
                            </div>
                            <Space>
                                <Button
                                    icon={<RefreshCw size={14} />}
                                    onClick={fetchPipelines}
                                    loading={loading}
                                    className="text-white border-white/40 hover:border-white"
                                >
                                    刷新
                                </Button>
                                <Button type="primary" icon={<Plus size={14} />} onClick={handleAdd} className={primaryButtonClass}>
                                    创建流水线
                                </Button>
                            </Space>
                        </div>
                        <div className="mt-5 grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-3">
                            {overviewStats.map((stat) => (
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
                    <div className="grid grid-cols-1 xl:grid-cols-[300px_minmax(0,1fr)_320px] gap-5">
                        <aside className="space-y-5">
                            <div className="rounded-2xl border border-slate-200 bg-white p-4">
                                <div className="flex items-center justify-between mb-3">
                                    <div>
                                        <div className="text-xs uppercase tracking-widest text-slate-400">目录</div>
                                        <div className="text-sm font-semibold text-slate-800">流水线列表</div>
                                    </div>
                                    <Tag color="blue">{pipelineItems.length}</Tag>
                                </div>
                                <Input placeholder="搜索流水线" className="border-slate-200" />
                                <div className="mt-3 flex flex-wrap gap-2">
                                    {['全部', '运行中', '成功', '失败', '草稿'].map((item) => (
                                        <span
                                            key={item}
                                            className="rounded-full border border-slate-200 px-2.5 py-1 text-[11px] font-semibold text-slate-500"
                                        >
                                            {item}
                                        </span>
                                    ))}
                                </div>
                                <div className="mt-4 space-y-3">
                                    {pipelineItems.map((pipeline) => {
                                        const repoName = repos.find(r => r.id === pipeline.repoId)?.name || '未绑定仓库';
                                        return (
                                            <div key={pipeline.id} className="rounded-xl border border-slate-200 bg-white p-3 shadow-sm">
                                                <div className="flex items-start justify-between gap-3">
                                                    <div>
                                                        <div className="flex items-center gap-2">
                                                            <GitBranch size={14} className="text-indigo-500" />
                                                            <span className="text-sm font-semibold text-slate-800">{pipeline.name}</span>
                                                        </div>
                                                        <div className="mt-1 text-xs text-slate-500">
                                                            {repoName} · {triggerLabelMap[pipeline.triggerType || 'manual']}
                                                        </div>
                                                    </div>
                                                    <Tag color={pipeline.enabled ? 'green' : 'default'}>
                                                        {pipeline.enabled ? '启用' : '禁用'}
                                                    </Tag>
                                                </div>
                                                <div className="mt-3 flex flex-wrap items-center gap-2">
                                                    <Button
                                                        type="primary"
                                                        size="small"
                                                        icon={<Play size={12} />}
                                                        onClick={() => handleTrigger(pipeline)}
                                                        disabled={!pipeline.enabled}
                                                        className={primaryButtonClass}
                                                    >
                                                        执行
                                                    </Button>
                                                    <Button size="small" className={subtleButtonClass} onClick={() => handleViewRuns(pipeline)}>
                                                        记录
                                                    </Button>
                                                    <Button size="small" className={subtleButtonClass} icon={<Edit size={12} />} onClick={() => handleEdit(pipeline)} />
                                                    <Popconfirm title="确定删除？" onConfirm={() => handleDelete(pipeline.id!)}>
                                                        <Button size="small" className={subtleButtonClass} danger icon={<Trash2 size={12} />} />
                                                    </Popconfirm>
                                                </div>
                                            </div>
                                        );
                                    })}
                                </div>
                            </div>

                            <div className="rounded-2xl border border-slate-200 bg-white p-4">
                                <div className="text-xs uppercase tracking-widest text-slate-400">模板库</div>
                                <div className="mt-2 text-sm font-semibold text-slate-800">推荐模版</div>
                                <div className="mt-3 space-y-2 text-xs text-slate-500">
                                    <div className="flex items-center justify-between rounded-lg border border-slate-100 px-3 py-2">
                                        <span>全链路发布 (含门禁)</span>
                                        <span className="text-indigo-600">v3</span>
                                    </div>
                                    <div className="flex items-center justify-between rounded-lg border border-slate-100 px-3 py-2">
                                        <span>灰度回归验证</span>
                                        <span className="text-indigo-600">v2</span>
                                    </div>
                                    <div className="flex items-center justify-between rounded-lg border border-slate-100 px-3 py-2">
                                        <span>安全基线检查</span>
                                        <span className="text-indigo-600">v4</span>
                                    </div>
                                </div>
                            </div>
                        </aside>

                        <section className="space-y-5">
                            <div className="rounded-2xl border border-slate-200 bg-white p-5">
                                <div className="flex items-center justify-between">
                                    <div>
                                        <div className="text-xs uppercase tracking-widest text-slate-400">Workflow Canvas</div>
                                        <div className="text-sm font-semibold text-slate-800">编排视图</div>
                                    </div>
                                    <div className="flex items-center gap-2 text-xs text-slate-500">
                                        <span className="rounded-full bg-slate-100 px-2 py-1">自动化 12</span>
                                        <span className="rounded-full bg-slate-100 px-2 py-1">门禁 4</span>
                                        <span className="rounded-full bg-slate-100 px-2 py-1">平均并发 6</span>
                                    </div>
                                </div>
                                <div className="mt-4 relative h-[420px] rounded-2xl border border-slate-200 bg-gradient-to-b from-slate-50 to-white overflow-hidden">
                                    <div className="absolute inset-0 opacity-40" style={{ backgroundImage: 'radial-gradient(#cbd5f5 1px, transparent 1px)', backgroundSize: '20px 20px' }} />
                                    <div className="absolute left-[19%] top-[26%] h-0.5 w-[14%] bg-slate-200/80" />
                                    <div className="absolute left-[47%] top-[26%] h-0.5 w-[13%] bg-slate-200/80" />
                                    <div className="absolute left-[41%] top-[42%] h-[70px] w-0.5 bg-slate-200/80" />
                                    <div className="absolute left-[47%] top-[62%] h-0.5 w-[13%] bg-slate-200/80" />
                                    {stageNodes.map((node) => (
                                        <div
                                            key={node.id}
                                            className="absolute w-48 rounded-2xl border border-slate-200 bg-white/90 px-4 py-3 shadow-sm backdrop-blur"
                                            style={{ left: node.left, top: node.top }}
                                        >
                                            <div className="flex items-center justify-between">
                                                <div className="text-sm font-semibold text-slate-800">{node.title}</div>
                                                <span className="rounded-full border border-slate-200 px-2 py-0.5 text-[10px] font-semibold text-slate-500">
                                                    {node.badge}
                                                </span>
                                            </div>
                                            <div className="mt-1 text-xs text-slate-500">{node.subtitle}</div>
                                            <div className="mt-3 flex items-center gap-2 text-[10px] text-slate-400">
                                                <span className="rounded-full bg-slate-100 px-2 py-0.5">并行</span>
                                                <span className="rounded-full bg-slate-100 px-2 py-0.5">缓存</span>
                                                <span className="rounded-full bg-slate-100 px-2 py-0.5">策略</span>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            </div>

                            <div className="rounded-2xl border border-slate-200 bg-white p-5">
                                <div className="flex items-center justify-between">
                                    <div>
                                        <div className="text-xs uppercase tracking-widest text-slate-400">Delivery Insights</div>
                                        <div className="text-sm font-semibold text-slate-800">交付洞察</div>
                                    </div>
                                    <span className="text-xs text-slate-400">近 24 小时</span>
                                </div>
                                <div className="mt-4 grid grid-cols-1 md:grid-cols-3 gap-3 text-xs">
                                    {[
                                        { label: '门禁通过率', value: '96%', hint: 'SAST/DAST/SCA' },
                                        { label: '制品可信度', value: 'SLSA L3', hint: '签名 + SBOM' },
                                        { label: '回滚就绪度', value: '98%', hint: '自动回滚' },
                                    ].map((item) => (
                                        <div key={item.label} className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-3">
                                            <div className="text-[10px] uppercase tracking-widest text-slate-400">{item.label}</div>
                                            <div className="mt-2 text-sm font-semibold text-slate-700">{item.value}</div>
                                            <div className="mt-1 text-[10px] text-slate-400">{item.hint}</div>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        </section>

                        <aside className="space-y-5">
                            <div className="rounded-2xl border border-slate-200 bg-white p-4">
                                <div className="text-xs uppercase tracking-widest text-slate-400">运行洞察</div>
                                <div className="mt-2 text-sm font-semibold text-slate-800">当前窗口</div>
                                <div className="mt-4 space-y-3 text-xs text-slate-500">
                                    <div className="rounded-xl border border-slate-100 bg-slate-50 px-3 py-3">
                                        <div className="flex items-center justify-between">
                                            <span>队列长度</span>
                                            <span className="font-semibold text-slate-700">3</span>
                                        </div>
                                        <div className="mt-2 h-1.5 rounded-full bg-slate-200">
                                            <div className="h-1.5 w-2/3 rounded-full bg-indigo-500" />
                                        </div>
                                    </div>
                                    <div className="rounded-xl border border-slate-100 bg-slate-50 px-3 py-3">
                                        <div className="flex items-center justify-between">
                                            <span>资源水位</span>
                                            <span className="font-semibold text-slate-700">72%</span>
                                        </div>
                                        <div className="mt-2 grid grid-cols-3 gap-2 text-[10px] text-slate-400">
                                            <span className="rounded-full bg-white px-2 py-1 text-center">CPU</span>
                                            <span className="rounded-full bg-white px-2 py-1 text-center">GPU</span>
                                            <span className="rounded-full bg-white px-2 py-1 text-center">IO</span>
                                        </div>
                                    </div>
                                    <div className="rounded-xl border border-slate-100 bg-slate-50 px-3 py-3">
                                        <div className="flex items-center justify-between">
                                            <span>合规门禁</span>
                                            <span className="font-semibold text-emerald-600">通过</span>
                                        </div>
                                        <div className="mt-2 text-[10px] text-slate-400">策略更新 6 分钟前</div>
                                    </div>
                                </div>
                            </div>

                            <div className="rounded-2xl border border-slate-200 bg-white p-4">
                                <div className="text-xs uppercase tracking-widest text-slate-400">风险预警</div>
                                <div className="mt-2 text-sm font-semibold text-slate-800">高风险阶段</div>
                                <div className="mt-4 space-y-3 text-xs text-slate-500">
                                    <div className="rounded-xl border border-rose-100 bg-rose-50 px-3 py-3">
                                        <div className="flex items-center justify-between">
                                            <span>集成测试波动</span>
                                            <span className="text-rose-600 font-semibold">3 次</span>
                                        </div>
                                        <div className="mt-2 text-[10px] text-rose-400">需复核失败用例</div>
                                    </div>
                                    <div className="rounded-xl border border-amber-100 bg-amber-50 px-3 py-3">
                                        <div className="flex items-center justify-between">
                                            <span>部署窗口冲突</span>
                                            <span className="text-amber-600 font-semibold">2</span>
                                        </div>
                                        <div className="mt-2 text-[10px] text-amber-400">建议调整时间</div>
                                    </div>
                                </div>
                            </div>
                        </aside>
                    </div>

                    <div className="mt-6 grid grid-cols-1 lg:grid-cols-[minmax(0,1fr)_320px] gap-5">
                        <div className="rounded-2xl border border-slate-200 bg-white p-5">
                            <div className="flex items-center justify-between">
                                <div>
                                    <div className="text-xs uppercase tracking-widest text-slate-400">Recent Runs</div>
                                    <div className="text-sm font-semibold text-slate-800">最近执行</div>
                                </div>
                                <Button size="small" className={secondaryButtonClass} onClick={() => pipelineItems[0] && handleViewRuns(pipelineItems[0])}>
                                    查看全部
                                </Button>
                            </div>
                            <div className="mt-4 space-y-3">
                                {runPreview.map((run) => {
                                    const status = statusConfig[run.status] || statusConfig.pending;
                                    return (
                                        <div key={run.id} className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-slate-100 bg-slate-50 px-4 py-3">
                                            <div className="flex items-center gap-2 text-sm font-semibold text-slate-700">
                                                {status.icon}
                                                #{run.runNumber}
                                            </div>
                                            <div className="text-xs text-slate-500">
                                                {run.branch || '-'} · {run.triggerType || 'manual'}
                                            </div>
                                            <Tag color={status.color}>{status.label}</Tag>
                                            <div className="text-xs text-slate-400">
                                                {run.startedAt || run.finishedAt || '刚刚'}
                                            </div>
                                        </div>
                                    );
                                })}
                            </div>
                        </div>

                        <div className="rounded-2xl border border-slate-200 bg-white p-5">
                            <div className="text-xs uppercase tracking-widest text-slate-400">Environment</div>
                            <div className="text-sm font-semibold text-slate-800">环境与门禁</div>
                            <div className="mt-4 space-y-3 text-xs text-slate-500">
                                {[
                                    { label: '预发环境', status: '通过', tone: 'emerald' },
                                    { label: '生产环境', status: '待审批', tone: 'amber' },
                                    { label: '回滚通道', status: '就绪', tone: 'indigo' },
                                ].map((item) => (
                                    <div key={item.label} className="flex items-center justify-between rounded-xl border border-slate-100 bg-slate-50 px-3 py-3">
                                        <span>{item.label}</span>
                                        <span className="font-semibold text-slate-700">{item.status}</span>
                                    </div>
                                ))}
                                <div className="rounded-xl border border-slate-100 bg-slate-50 px-3 py-3">
                                    <div className="text-[10px] uppercase tracking-widest text-slate-400">合规要点</div>
                                    <div className="mt-2 grid grid-cols-2 gap-2 text-[11px] text-slate-500">
                                        <span className="rounded-full bg-white px-2 py-1 text-center">SBOM</span>
                                        <span className="rounded-full bg-white px-2 py-1 text-center">SAST</span>
                                        <span className="rounded-full bg-white px-2 py-1 text-center">DAST</span>
                                        <span className="rounded-full bg-white px-2 py-1 text-center">签名</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

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
