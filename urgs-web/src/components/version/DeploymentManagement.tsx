import React, { useEffect, useMemo, useState } from 'react';
import { Button, Card, Dropdown, Form, Modal, Space, Tag, message } from 'antd';
import * as XLSX from 'xlsx';
import {
    AlertTriangle, CheckCircle, Clock, Download, Edit, GitBranch, Globe, History,
    Info, MoreVertical, Package, RefreshCw, Rocket, Server,
    Trash2, XCircle
} from 'lucide-react';
import {
    buildProductionPackage as buildProductionPackageApi,
    deleteVersionPackage,
    downloadProductionPackage,
    downloadVersionPackage,
    gateCheckProductionPackage,
    getDeployEnvironments,
    getGitRepositories,
    getRepoCompareCommits,
    getRepoTags,
    getVersionPackages,
    recordOfflineDeploymentResult,
    DeployEnvironment,
    GitCommit,
    GitRepository,
    GitTag as IGitTag,
    ProductionPackageBuildResult,
    ProductionPackageGateResult,
    ProductionPackageRequest,
    VersionPackage
} from '@/api/version';
import ProductionPackagePanel from './ProductionPackagePanel';
import DeploymentPackageModals from './DeploymentPackageModals';

const statusConfig: Record<string, { color: string; icon: React.ReactNode; label: string }> = {
    draft: { color: 'default', icon: <Edit size={14} />, label: '草稿' },
    ready: { color: 'blue', icon: <CheckCircle size={14} />, label: '就绪' },
    deployed: { color: 'success', icon: <Rocket size={14} />, label: '已部署' },
    archived: { color: 'default', icon: <History size={14} />, label: '已归档' },
    pending: { color: 'default', icon: <Clock size={14} />, label: '待处理' },
    success: { color: 'success', icon: <CheckCircle size={14} />, label: '成功' },
    failed: { color: 'error', icon: <XCircle size={14} />, label: '失败' },
    blocked: { color: 'warning', icon: <AlertTriangle size={14} />, label: '已阻断' },
};
const formatCommitDate = (value?: string) => {
    if (!value) return '-';
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? value : date.toLocaleString();
};
const firstLine = (value?: string) => (value || '').split('\n')[0]?.trim() || '-';
const formatProductionDescription = (gitRef: string, previousGitRef: string, commits: GitCommit[]) => {
    const lines = [
        `投产版本: ${gitRef}`,
        `基线版本: ${previousGitRef}`,
        '',
        `提交记录（${previousGitRef}..${gitRef}，共 ${commits.length} 条）:`
    ];

    if (commits.length === 0) {
        lines.push('- 未读取到提交记录，请确认 Tag 区间或手工补充说明');
    } else {
        commits.forEach((commit, index) => {
            const sha = commit.sha || commit.fullSha?.slice(0, 8) || '-';
            lines.push(`${index + 1}. ${sha} ${firstLine(commit.message)}（${commit.authorName || '-'}，${formatCommitDate(commit.committedAt)}）`);
        });
    }

    return lines.join('\n');
};
const parseDeployLogStatus = (content: string): 'success' | 'failed' | 'blocked' | undefined => {
    const normalized = content.toLowerCase();
    if (content.includes('生产中的版本与GitLab中的投产前版本不一致')
        || content.includes('生产存储过程一致性校验')
        || content.includes('被存储过程一致性校验阻断')) {
        return 'blocked';
    }
    if (normalized.includes('"event": "deploy_end"') && normalized.includes('"status": "success"')) {
        return 'success';
    }
    if (normalized.includes('final status: success')) {
        return 'success';
    }
    if (normalized.includes('"event": "deploy_end"') && normalized.includes('"status": "failed"')) {
        return 'failed';
    }
    if (normalized.includes('final status: failed')
        || normalized.includes('"event": "step_fail"')
        || content.includes('部署中断')
        || content.includes('Step') && content.includes('失败')) {
        return 'failed';
    }
    return undefined;
};
const logBelongsToPackage = (content: string, packageId: number) => {
    const id = String(packageId);
    return content.includes(`PACKAGE_ID=${id}`)
        || content.includes(`"package_id": ${id}`)
        || content.includes(`"package_id":${id}`)
        || content.includes(`package_id=${id}`);
};
const fileNameSafe = (value?: string) => (value || 'unknown').replace(/[\\/:*?"<>|\p{C}]+/gu, '_');
interface Props {
    ssoId?: number;
    repoId?: number;
}
const DeploymentManagement: React.FC<Props> = ({ ssoId, repoId }) => {
    const [environments, setEnvironments] = useState<DeployEnvironment[]>([]);
    const [versionPackages, setVersionPackages] = useState<VersionPackage[]>([]);
    const [repos, setRepos] = useState<GitRepository[]>([]);
    const [tags, setTags] = useState<IGitTag[]>([]);
    const [loading, setLoading] = useState(false);
    const [fetchingGit, setFetchingGit] = useState(false);
    const [gateLoading, setGateLoading] = useState(false);
    const [buildLoading, setBuildLoading] = useState(false);
    const [activeTab, setActiveTab] = useState<'release' | 'history'>('release');
    const [selectedRepo, setSelectedRepo] = useState<number | null>(repoId || null);
    const [gateResult, setGateResult] = useState<ProductionPackageGateResult | null>(null);
    const [buildResult, setBuildResult] = useState<ProductionPackageBuildResult | null>(null);
    const [releaseCommits, setReleaseCommits] = useState<GitCommit[]>([]);
    const [commitLoading, setCommitLoading] = useState(false);
    const [recordModalVisible, setRecordModalVisible] = useState(false);
    const [recordPackage, setRecordPackage] = useState<VersionPackage | null>(null);
    const [logParseMessage, setLogParseMessage] = useState<string>('');
    const [logParseStatus, setLogParseStatus] = useState<'success' | 'error' | 'warning' | 'info'>('info');
    const [detailModalVisible, setDetailModalVisible] = useState(false);
    const [selectedPackageDetail, setSelectedPackageDetail] = useState<VersionPackage | null>(null);
    const [fileListModalVisible, setFileListModalVisible] = useState(false);
    const [fileListPackage, setFileListPackage] = useState<VersionPackage | null>(null);
    const [recordForm] = Form.useForm();
    const [productionForm] = Form.useForm<ProductionPackageRequest>();

    const currentUserId = useMemo(() => {
        try {
            const user = JSON.parse(localStorage.getItem('auth_user') || '{}');
            const id = user.userId || user.id;
            return Number.isFinite(Number(id)) ? Number(id) : undefined;
        } catch (error) {
            return undefined;
        }
    }, []);

    useEffect(() => {
        if (ssoId) {
            fetchData();
        }
    }, [ssoId]);

    useEffect(() => {
        if (repoId) {
            setSelectedRepo(repoId);
            productionForm.setFieldValue('repoId', repoId);
            loadTags(repoId);
        }
    }, [repoId]);

    const fetchData = async () => {
        setLoading(true);
        try {
            const [envs, pkgs, repositories] = await Promise.all([
                getDeployEnvironments(ssoId),
                getVersionPackages(ssoId!),
                getGitRepositories({ ssoId })
            ]);
            setEnvironments(envs || []);
            setVersionPackages(pkgs || []);
            setRepos(repositories || []);
        } catch (error) {
            message.error('加载数据失败');
        } finally {
            setLoading(false);
        }
    };

    const productionEnvId = useMemo(() => {
        const env = environments.find(item => ['prod', 'production'].includes((item.code || '').toLowerCase()))
            || environments.find(item => item.name?.includes('生产'));
        return env?.id;
    }, [environments]);

    const watchedRepoId = Form.useWatch('repoId', productionForm);
    const watchedGitRef = Form.useWatch('gitRef', productionForm);
    const watchedPreviousGitRef = Form.useWatch('previousGitRef', productionForm);
    const watchedRequirementNumber = Form.useWatch('requirementNumber', productionForm);
    const watchedRecordStatus = Form.useWatch('status', recordForm);
    const watchedManualChecked = Form.useWatch('manualChecked', recordForm);

    useEffect(() => {
        if (productionEnvId) {
            productionForm.setFieldValue('envId', productionEnvId);
        }
    }, [productionEnvId]);

    useEffect(() => {
        if (!watchedRepoId || !watchedGitRef || !watchedPreviousGitRef) {
            setReleaseCommits([]);
            return;
        }

        let cancelled = false;
        const loadReleaseCommits = async () => {
            setCommitLoading(true);
            try {
                const commits = await getRepoCompareCommits(Number(watchedRepoId), watchedPreviousGitRef, watchedGitRef);
                if (cancelled) return;
                setReleaseCommits(commits || []);
                productionForm.setFieldValue(
                    'description',
                    formatProductionDescription(watchedGitRef, watchedPreviousGitRef, commits || [])
                );
            } catch (error) {
                if (cancelled) return;
                setReleaseCommits([]);
                productionForm.setFieldValue(
                    'description',
                    formatProductionDescription(watchedGitRef, watchedPreviousGitRef, [])
                );
                message.error('读取 Tag 区间提交记录失败');
            } finally {
                if (!cancelled) {
                    setCommitLoading(false);
                }
            }
        };

        loadReleaseCommits();
        return () => {
            cancelled = true;
        };
    }, [watchedRepoId, watchedGitRef, watchedPreviousGitRef]);

    useEffect(() => {
        setGateResult(null);
        setBuildResult(null);
    }, [watchedRequirementNumber]);

    const loadTags = async (targetRepoId: number) => {
        setFetchingGit(true);
        setTags([]);
        setGateResult(null);
        setBuildResult(null);
        try {
            const repoTags = await getRepoTags(targetRepoId);
            const sortedTags = [...(repoTags || [])].sort((a, b) => {
                const dateA = a.taggerDate || '';
                const dateB = b.taggerDate || '';
                return dateB.localeCompare(dateA);
            });
            setTags(sortedTags);
        } catch (error) {
            message.error('获取仓库标签失败');
        } finally {
            setFetchingGit(false);
        }
    };

    const handleRepoChange = (targetRepoId: number) => {
        setSelectedRepo(targetRepoId);
        productionForm.setFieldsValue({ gitRef: undefined, previousGitRef: undefined, requirementNumber: undefined, description: undefined });
        setReleaseCommits([]);
        loadTags(targetRepoId);
    };

    const handleTagChange = (tagName: string) => {
        const idx = tags.findIndex(t => t.name === tagName);
        productionForm.setFieldsValue({
            previousGitRef: idx >= 0 && idx + 1 < tags.length ? tags[idx + 1].name : undefined,
            description: undefined
        });
        setReleaseCommits([]);
        setGateResult(null);
        setBuildResult(null);
    };

    const handlePreviousTagChange = () => {
        productionForm.setFieldValue('description', undefined);
        setReleaseCommits([]);
        setGateResult(null);
        setBuildResult(null);
    };

    const buildPayload = async (): Promise<ProductionPackageRequest> => {
        const values = await productionForm.validateFields();
        return {
            ...values,
            repoId: repoId || values.repoId,
            ssoId: ssoId!,
            envId: values.envId || productionEnvId,
            createdBy: currentUserId
        };
    };

    const handleGateCheck = async () => {
        try {
            const payload = await buildPayload();
            setGateLoading(true);
            const result = await gateCheckProductionPackage(payload);
            setGateResult(result);
            setBuildResult(null);
            if (result.status === 'passed') {
                message.success('生产投产门禁通过');
            } else {
                message.warning('生产投产门禁未通过');
            }
        } catch (error) {
            console.error(error);
            message.error('门禁校验失败');
        } finally {
            setGateLoading(false);
        }
    };

    const handleBuildPackage = async () => {
        if (!gateResult || gateResult.status !== 'passed') {
            message.warning('请先通过生产投产门禁');
            return;
        }
        try {
            const payload = await buildPayload();
            setBuildLoading(true);
            const result = await buildProductionPackageApi(payload);
            setBuildResult(result);
            message.success('生产投产包已生成');
            fetchData();
        } catch (error) {
            console.error(error);
            message.error('生成生产投产包失败');
        } finally {
            setBuildLoading(false);
        }
    };

    const downloadBlob = (blob: Blob, fileName: string) => {
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = fileName;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);
    };

    const handleDownloadProduction = async (packageId: number, fileName?: string) => {
        try {
            const blob = await downloadProductionPackage(packageId);
            downloadBlob(blob, fileName || `release-${packageId}.zip`);
            message.success('生产投产包下载开始');
        } catch (error) {
            message.error('下载生产投产包失败');
        }
    };

    const handleDownloadLegacy = async (pkg: VersionPackage) => {
        try {
            const blob = await downloadVersionPackage(pkg.id);
            downloadBlob(blob, `deploy-${pkg.version}-${pkg.gitRef}.zip`);
            message.success('数据库部署包下载开始');
        } catch (error) {
            message.error('下载部署包失败');
        }
    };

    const openRecordModal = (pkg?: VersionPackage) => {
        const packageId = pkg?.id || buildResult?.packageId;
        const envId = pkg?.envId || productionForm.getFieldValue('envId') || productionEnvId;
        const targetPackage = pkg
            || versionPackages.find(item => item.id === packageId)
            || (packageId ? {
                id: packageId,
                repoId: Number(watchedRepoId || repoId),
                ssoId: ssoId!,
                version: watchedGitRef || '',
                gitRef: watchedGitRef || '',
                commitSha: '',
                status: 'ready',
                envId,
                packageName: buildResult?.packageName
            } as VersionPackage : null);
        if (!packageId) {
            message.warning('请先选择生产投产包');
            return;
        }
        setRecordPackage(targetPackage);
        setLogParseMessage('请上传当前投产包执行 deploy.sh 产生的日志文件，系统会自动识别执行结果。');
        setLogParseStatus('info');
        recordForm.setFieldsValue({
            packageId,
            envId,
            status: undefined,
            logFileName: undefined,
            logs: '',
            manualChecked: false,
            remark: ''
        });
        setRecordModalVisible(true);
    };

    const handleDeploymentLogFile = async (file: File) => {
        const packageId = Number(recordForm.getFieldValue('packageId'));
        if (!packageId) {
            message.error('缺少投产包 ID，无法校验日志文件');
            return;
        }

        const content = await file.text();
        if (content.includes('ROLLBACK START') || content.includes('rollback_success') || content.includes('rollback_failed')) {
            setLogParseStatus('error');
            setLogParseMessage('请上传 deploy.sh 部署日志，不要上传 rollback.sh 回滚日志。');
            recordForm.setFieldsValue({ status: undefined, logs: '', logFileName: undefined, manualChecked: false });
            return;
        }
        if (!logBelongsToPackage(content, packageId)) {
            setLogParseStatus('error');
            setLogParseMessage(`日志文件不属于当前投产包，或缺少 PACKAGE_ID=${packageId} 标识。请上传该生产包 deploy.sh 产生的日志。`);
            recordForm.setFieldsValue({ status: undefined, logs: '', logFileName: undefined, manualChecked: false });
            return;
        }

        const parsedStatus = parseDeployLogStatus(content);
        if (!parsedStatus) {
            setLogParseStatus('warning');
            setLogParseMessage('日志属于当前投产包，但未识别到最终执行结果，请确认日志是否完整。');
            recordForm.setFieldsValue({ status: undefined, logs: content, logFileName: file.name, manualChecked: false });
            return;
        }

        const label = parsedStatus === 'success' ? '成功' : parsedStatus === 'blocked' ? '被存储过程一致性校验阻断' : '失败';
        setLogParseStatus(parsedStatus === 'success' ? 'success' : parsedStatus === 'blocked' ? 'warning' : 'error');
        setLogParseMessage(`已识别为：${label}。请手工核验日志内容后勾选确认。`);
        recordForm.setFieldsValue({
            status: parsedStatus,
            logs: content,
            logFileName: file.name,
            manualChecked: false
        });
    };

    const handleRecordResult = async () => {
        try {
            const values = await recordForm.validateFields();
            if (!values.logs || !values.status || !values.manualChecked) {
                message.error('请上传当前生产包部署日志并完成人工检核');
                return;
            }
            await recordOfflineDeploymentResult({
                ssoId: ssoId!,
                envId: values.envId,
                packageId: values.packageId,
                status: values.status,
                deployedBy: currentUserId,
                logs: `[日志文件] ${values.logFileName || '-'}\n${values.logs}`,
                remark: values.remark
            });
            message.success('部署结果已回填');
            setRecordModalVisible(false);
            setRecordPackage(null);
            setLogParseMessage('');
            setActiveTab('history');
            fetchData();
        } catch (error) {
            message.error('回填部署结果失败');
        }
    };

    const openPackageDetail = (pkg: VersionPackage) => {
        setSelectedPackageDetail(pkg);
        setDetailModalVisible(true);
    };

    const parsePackageFiles = (pkg?: VersionPackage | null) => {
        if (!pkg?.changedFiles) {
            return [];
        }
        try {
            const files = JSON.parse(pkg.changedFiles);
            return Array.isArray(files) ? files.filter(item => typeof item === 'string') : [];
        } catch (error) {
            return [];
        }
    };

    const packageDeployCommand = (pkg?: VersionPackage | null) => pkg?.deployCommand || 'bash deploy.sh --operator <姓名>';

    const packageRollbackCommand = (pkg?: VersionPackage | null) => pkg?.rollbackCommand || 'bash rollback.sh --operator <姓名>';

    const packageDeployLogPath = () => '生产包解压目录/.runtime/db/.meta/deploy_*.log';

    const exportPackageExcel = (pkg?: VersionPackage | null) => {
        if (!pkg) {
            return;
        }

        const envName = environments.find(e => String(e.id) === String(pkg.envId))?.name || '-';
        const files = parsePackageFiles(pkg);
        const workbook = XLSX.utils.book_new();

        const infoSheet = XLSX.utils.json_to_sheet([
            { 字段: '投产包ID', 内容: `VP-${pkg.id.toString().padStart(6, '0')}` },
            { 字段: '版本', 内容: pkg.version || '-' },
            { 字段: '包名', 内容: pkg.packageName || '-' },
            { 字段: '当前Tag', 内容: pkg.gitRef || '-' },
            { 字段: '基线Tag', 内容: pkg.previousGitRef || '-' },
            { 字段: '需求编号', 内容: pkg.requirementNumber || '-' },
            { 字段: '环境', 内容: envName },
            { 字段: '状态', 内容: (statusConfig[pkg.status] || statusConfig.ready).label },
            { 字段: '门禁', 内容: pkg.gateStatus || '-' },
            { 字段: '类型', 内容: pkg.packageType || '-' },
            { 字段: '部署命令', 内容: packageDeployCommand(pkg) },
            { 字段: '回滚命令', 内容: packageRollbackCommand(pkg) },
            { 字段: '创建时间', 内容: pkg.createdAt ? new Date(pkg.createdAt).toLocaleString() : '-' },
            { 字段: '投产说明', 内容: pkg.description || '-' },
            { 字段: '构建日志', 内容: pkg.buildLog || '-' }
        ]);
        XLSX.utils.book_append_sheet(workbook, infoSheet, '投产包信息');

        const logSheet = XLSX.utils.json_to_sheet([{
            日志文件路径: packageDeployLogPath(),
            用途: '回填生产执行结果的部署日志'
        }]);
        XLSX.utils.book_append_sheet(workbook, logSheet, '回填日志路径');

        const fileSheet = XLSX.utils.json_to_sheet(files.map((file, index) => ({
            序号: index + 1,
            投产文件: file
        })));
        XLSX.utils.book_append_sheet(workbook, fileSheet, '投产文件清单');

        XLSX.writeFile(workbook, `投产包_${fileNameSafe(pkg.version || pkg.packageName)}.xlsx`);
    };

    const openPackageFileList = (pkg: VersionPackage) => {
        setFileListPackage(pkg);
        setFileListModalVisible(true);
    };

    const handleDeletePackage = (pkg: VersionPackage) => {
        setDetailModalVisible(false);
        setSelectedPackageDetail(null);
        Modal.confirm({
            title: '删除投产包',
            content: `确认删除投产包 ${pkg.packageName || pkg.version || pkg.id}？`,
            okText: '删除',
            okButtonProps: { danger: true },
            cancelText: '取消',
            onOk: async () => {
                try {
                    await deleteVersionPackage(pkg.id);
                    message.success('投产包已删除');
                    if (selectedPackageDetail?.id === pkg.id) {
                        setDetailModalVisible(false);
                        setSelectedPackageDetail(null);
                    }
                    fetchData();
                } catch (error) {
                    message.error('删除投产包失败');
                }
            }
        });
    };

    const currentStep = useMemo(() => {
        if (!watchedRepoId || !watchedGitRef || !watchedPreviousGitRef) return 0;
        if (!watchedRequirementNumber) return 1;
        if (!gateResult) return 1;
        if (gateResult.status !== 'passed') return 2;
        if (!buildResult) return 3;
        return 4;
    }, [watchedRepoId, watchedGitRef, watchedPreviousGitRef, watchedRequirementNumber, gateResult, buildResult]);

    const renderPackageCard = (pkg: VersionPackage) => {
        const config = statusConfig[pkg.status] || statusConfig.ready;
        const repoName = repos.find(r => r.id === pkg.repoId)?.name || '未知仓库';
        const envName = environments.find(e => String(e.id) === String(pkg.envId))?.name || '-';
        const isProductionPackage = !!pkg.deployCommand || pkg.packageUrl?.startsWith('generated://production');
        return (
            <div
                key={pkg.id}
                className="rounded-lg border border-slate-200 p-4 bg-white hover:border-indigo-300 transition-colors cursor-pointer"
                onClick={() => openPackageDetail(pkg)}
            >
                <div className="flex items-start justify-between gap-3 mb-3">
                    <div>
                        <Space className="mb-1" wrap>
                            <span className="font-bold text-slate-800">版本: {pkg.version}</span>
                            <Tag color={config.color} className="inline-flex items-center gap-1">{config.icon} {config.label}</Tag>
                            {pkg.packageType && <Tag color="geekblue">{pkg.packageType}</Tag>}
                        </Space>
                        <div className="text-xs text-slate-400 font-mono">VP-{pkg.id.toString().padStart(6, '0')}</div>
                    </div>
                    <Dropdown
                        menu={{
                            items: [
                                {
                                    key: 'record',
                                    label: '回填生产执行结果',
                                    icon: <CheckCircle size={14} />,
                                    onClick: ({ domEvent }) => {
                                        domEvent.stopPropagation();
                                        openRecordModal(pkg);
                                    }
                                },
                                {
                                    key: 'delete',
                                    label: '删除',
                                    icon: <Trash2 size={14} />,
                                    danger: true,
                                    onClick: ({ domEvent }) => {
                                        domEvent.stopPropagation();
                                        handleDeletePackage(pkg);
                                    }
                                },
                            ]
                        }}
                        trigger={['click']}
                    >
                        <Button
                            type="text"
                            icon={<MoreVertical size={16} />}
                            onClick={(event) => event.stopPropagation()}
                        />
                    </Dropdown>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-2 text-sm text-slate-600">
                    <Space><Globe size={14} />仓库: {repoName}</Space>
                    <Space><GitBranch size={14} />Tag: {pkg.gitRef}</Space>
                    <Space><History size={14} />基线: {pkg.previousGitRef || '-'}</Space>
                    <Space><Info size={14} />需求: {pkg.requirementNumber || '-'}</Space>
                    <Space><Server size={14} />环境: {envName}</Space>
                    <Space><Info size={14} />门禁: {pkg.gateStatus || '-'}</Space>
                </div>
                {pkg.buildLog && (
                    <button
                        type="button"
                        className="mt-3 w-full rounded bg-slate-50 p-2 text-left text-xs text-slate-500 hover:bg-indigo-50 hover:text-indigo-700"
                        onClick={(event) => {
                            event.stopPropagation();
                            openPackageFileList(pkg);
                        }}
                    >
                        {pkg.buildLog}
                    </button>
                )}
                <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between">
                    <span className="text-xs text-slate-400">创建时间: {pkg.createdAt ? new Date(pkg.createdAt).toLocaleString() : '-'}</span>
                    <Button
                        size="small"
                        icon={<Download size={14} />}
                        onClick={(event) => {
                            event.stopPropagation();
                            isProductionPackage ? handleDownloadProduction(pkg.id, pkg.packageName) : handleDownloadLegacy(pkg);
                        }}
                    >
                        {isProductionPackage ? '下载生产包' : '下载数据库包'}
                    </Button>
                </div>
            </div>
        );
    };

    const activePackages = versionPackages.filter(p => !['deployed', 'archived', 'failed', 'blocked'].includes(p.status));
    const historyPackages = versionPackages.filter(p => p.status === 'deployed' || p.status === 'archived' || p.status === 'failed' || p.status === 'blocked');

    return (
        <div className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <Card className="border-slate-200 shadow-sm">
                    <Space>
                        <Package className="text-indigo-600" size={24} />
                        <div>
                            <div className="text-xs text-slate-400 font-medium">总投产包</div>
                            <div className="text-2xl font-bold text-slate-800">{versionPackages.length}</div>
                        </div>
                    </Space>
                </Card>
                <Card className="border-slate-200 shadow-sm">
                    <Space>
                        <CheckCircle className="text-emerald-600" size={24} />
                        <div>
                            <div className="text-xs text-slate-400 font-medium">已部署</div>
                            <div className="text-2xl font-bold text-slate-800">{versionPackages.filter(p => p.status === 'deployed').length}</div>
                        </div>
                    </Space>
                </Card>
                <Card className="border-slate-200 shadow-sm">
                    <Space>
                        <AlertTriangle className="text-amber-600" size={24} />
                        <div>
                            <div className="text-xs text-slate-400 font-medium">阻断/失败</div>
                            <div className="text-2xl font-bold text-slate-800">{versionPackages.filter(p => p.status === 'blocked' || p.status === 'failed').length}</div>
                        </div>
                    </Space>
                </Card>
            </div>

            <div className="rounded-lg border border-slate-200 bg-white shadow-sm overflow-hidden">
                <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-slate-50">
                    <Space size="large">
                        <button
                            className={`flex items-center gap-2 ${activeTab === 'release' ? 'text-indigo-600 font-bold' : 'text-slate-500 font-medium'}`}
                            onClick={() => setActiveTab('release')}
                        >
                            <Rocket size={18} /> 生产投产
                        </button>
                        <button
                            className={`flex items-center gap-2 ${activeTab === 'history' ? 'text-indigo-600 font-bold' : 'text-slate-500 font-medium'}`}
                            onClick={() => setActiveTab('history')}
                        >
                            <History size={18} /> 投产记录
                        </button>
                    </Space>
                    <Button icon={<RefreshCw size={14} className={loading ? 'animate-spin' : ''} />} onClick={fetchData}>
                        刷新
                    </Button>
                </div>
                <div className="p-6">
                    {activeTab === 'release' ? (
                        <div className="space-y-6">
                            <ProductionPackagePanel
                                productionForm={productionForm}
                                repoId={repoId}
                                repos={repos}
                                selectedRepo={selectedRepo}
                                tags={tags}
                                fetchingGit={fetchingGit}
                                gateLoading={gateLoading}
                                buildLoading={buildLoading}
                                commitLoading={commitLoading}
                                releaseCommits={releaseCommits}
                                watchedGitRef={watchedGitRef}
                                watchedPreviousGitRef={watchedPreviousGitRef}
                                gateResult={gateResult}
                                buildResult={buildResult}
                                currentStep={currentStep}
                                onRepoChange={handleRepoChange}
                                onTagChange={handleTagChange}
                                onPreviousTagChange={handlePreviousTagChange}
                                onGateCheck={handleGateCheck}
                                onBuildPackage={handleBuildPackage}
                                onDownloadProduction={handleDownloadProduction}
                                onOpenRecordModal={() => openRecordModal()}
                            />
                            <Card title="待执行投产包" className="border-slate-200 shadow-sm">
                                {activePackages.length === 0 ? (
                                    <div className="py-12 text-center text-slate-400">暂无待执行投产包</div>
                                ) : (
                                    <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
                                        {activePackages.map(renderPackageCard)}
                                    </div>
                                )}
                            </Card>
                        </div>
                    ) : (
                        <div className="space-y-4">
                            {historyPackages.length === 0 ? (
                                <div className="py-16 text-center text-slate-400">暂无投产历史</div>
                            ) : (
                                <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
                                    {historyPackages.map(renderPackageCard)}
                                </div>
                            )}
                        </div>
                    )}
                </div>
            </div>

            <DeploymentPackageModals
                statusConfig={statusConfig}
                environments={environments}
                detailModalVisible={detailModalVisible}
                selectedPackageDetail={selectedPackageDetail}
                fileListModalVisible={fileListModalVisible}
                fileListPackage={fileListPackage}
                recordModalVisible={recordModalVisible}
                recordPackage={recordPackage}
                recordForm={recordForm}
                watchedRecordStatus={watchedRecordStatus}
                watchedManualChecked={watchedManualChecked}
                logParseMessage={logParseMessage}
                logParseStatus={logParseStatus}
                setDetailModalVisible={setDetailModalVisible}
                setFileListModalVisible={setFileListModalVisible}
                setRecordModalVisible={setRecordModalVisible}
                setRecordPackage={setRecordPackage}
                setLogParseMessage={setLogParseMessage}
                setLogParseStatus={setLogParseStatus}
                handleRecordResult={handleRecordResult}
                handleDeploymentLogFile={handleDeploymentLogFile}
                handleDownloadProduction={handleDownloadProduction}
                handleDownloadLegacy={handleDownloadLegacy}
                openRecordModal={openRecordModal}
                openPackageFileList={openPackageFileList}
                exportPackageExcel={exportPackageExcel}
                parsePackageFiles={parsePackageFiles}
                packageDeployCommand={packageDeployCommand}
                packageRollbackCommand={packageRollbackCommand}
                packageDeployLogPath={packageDeployLogPath}
            />
        </div>
    );
};

export default DeploymentManagement;
