import React, { useEffect, useState } from 'react';
import { Alert, Avatar, Button, Input, message, Select, Spin, Tabs } from 'antd';
import { ArrowLeft, ArrowRight, CheckCircle2, GitBranch, GitCompareArrows, GitPullRequest, Info } from 'lucide-react';
import ReactMarkdown from 'react-markdown';
import { createPullRequest, getRepoBranches, getRepoLatestCommit, GitBranch as GitBranchType, GitCommit } from '@/api/version';
import { formatCommitTime } from '@/utils/dateUtils';

interface CreatePullRequestProps {
    repoId: number;
    onCancel: () => void;
    onSuccess: (id: number) => void;
}

const branchTitle = (sourceBranch: string, targetBranch: string) => (
    `合并分支 ${sourceBranch} 到 ${targetBranch}`
);

interface BranchCommitCardProps {
    title: string;
    branch: string;
    branches: GitBranchType[];
    commit: GitCommit | null;
    loading: boolean;
    onChange: (branch: string) => void;
}

const BranchCommitCard: React.FC<BranchCommitCardProps> = ({ title, branch, branches, commit, loading, onChange }) => (
    <section className="overflow-hidden rounded-lg border border-slate-200 bg-white">
        <div className="border-b border-slate-200 bg-slate-50 px-4 py-3 text-base font-semibold text-slate-800">{title}</div>
        <div className="p-4">
            <Select
                value={branch || undefined}
                placeholder="选择分支"
                loading={loading && !branch}
                onChange={onChange}
                options={branches.map(item => ({
                    label: <span className="flex items-center gap-2"><GitBranch size={14} className="text-slate-400" />{item.name}</span>,
                    value: item.name
                }))}
                showSearch
                optionFilterProp="label"
                className="w-full"
                size="large"
            />
        </div>
        <div className="min-h-[112px] border-t border-slate-100 px-4 py-4">
            <Spin spinning={loading && Boolean(branch)} size="small">
                {commit ? (
                    <div className="flex gap-3">
                        <Avatar size={36} src={commit.authorAvatar} className="shrink-0 bg-blue-500">
                            {commit.authorName?.charAt(0).toUpperCase()}
                        </Avatar>
                        <div className="min-w-0 flex-1">
                            <div className="line-clamp-2 font-medium leading-6 text-slate-800" title={commit.message}>{commit.message}</div>
                            <div className="mt-2 flex flex-wrap items-center gap-x-2 gap-y-1 text-xs text-slate-500">
                                <span>{commit.authorName || '未知提交人'}</span>
                                <span>提交于 {formatCommitTime(commit.committedAt)}</span>
                            </div>
                        </div>
                        <span className="h-fit rounded border border-slate-200 bg-slate-50 px-2 py-1 font-mono text-xs text-slate-600">
                            {commit.sha?.slice(0, 8)}
                        </span>
                    </div>
                ) : (
                    <div className="flex h-[72px] items-center text-sm text-slate-400">
                        {branch ? '暂无可展示的最新提交' : '选择分支后展示最新提交'}
                    </div>
                )}
            </Spin>
        </div>
    </section>
);

const CreatePullRequest: React.FC<CreatePullRequestProps> = ({ repoId, onCancel, onSuccess }) => {
    const [branches, setBranches] = useState<GitBranchType[]>([]);
    const [sourceBranch, setSourceBranch] = useState('');
    const [targetBranch, setTargetBranch] = useState('');
    const [sourceCommit, setSourceCommit] = useState<GitCommit | null>(null);
    const [targetCommit, setTargetCommit] = useState<GitCommit | null>(null);
    const [branchesLoading, setBranchesLoading] = useState(false);
    const [sourceCommitLoading, setSourceCommitLoading] = useState(false);
    const [targetCommitLoading, setTargetCommitLoading] = useState(false);
    const [step, setStep] = useState<'compare' | 'create'>('compare');
    const [title, setTitle] = useState('');
    const [titleTouched, setTitleTouched] = useState(false);
    const [description, setDescription] = useState('');
    const [descriptionTab, setDescriptionTab] = useState('write');
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        const loadBranches = async () => {
            setBranchesLoading(true);
            try {
                const data = await getRepoBranches(repoId);
                const nextBranches = data || [];
                const defaultBranch = nextBranches.find(item => item.isDefault) || nextBranches[0];
                const firstSourceBranch = nextBranches.find(item => item.name !== defaultBranch?.name) || defaultBranch;

                setBranches(nextBranches);
                setTargetBranch(defaultBranch?.name || '');
                setSourceBranch(firstSourceBranch?.name || '');
            } catch (error) {
                console.error('获取分支列表失败', error);
                message.error('获取分支列表失败');
            } finally {
                setBranchesLoading(false);
            }
        };

        loadBranches();
    }, [repoId]);

    useEffect(() => {
        if (!sourceBranch) {
            setSourceCommit(null);
            return;
        }
        setSourceCommitLoading(true);
        getRepoLatestCommit(repoId, sourceBranch)
            .then(data => setSourceCommit(data || null))
            .catch(error => {
                console.error('获取源分支最新提交失败', error);
                setSourceCommit(null);
            })
            .finally(() => setSourceCommitLoading(false));
    }, [repoId, sourceBranch]);

    useEffect(() => {
        if (!targetBranch) {
            setTargetCommit(null);
            return;
        }
        setTargetCommitLoading(true);
        getRepoLatestCommit(repoId, targetBranch)
            .then(data => setTargetCommit(data || null))
            .catch(error => {
                console.error('获取目标分支最新提交失败', error);
                setTargetCommit(null);
            })
            .finally(() => setTargetCommitLoading(false));
    }, [repoId, targetBranch]);

    useEffect(() => {
        if (sourceBranch && targetBranch && !titleTouched) {
            setTitle(branchTitle(sourceBranch, targetBranch));
        }
    }, [sourceBranch, targetBranch, titleTouched]);

    const handleSourceBranchChange = (branch: string) => {
        setSourceBranch(branch);
        setStep('compare');
    };

    const handleTargetBranchChange = (branch: string) => {
        setTargetBranch(branch);
        setStep('compare');
    };

    const handleContinue = () => {
        if (!sourceBranch || !targetBranch) {
            message.warning('请先选择源分支和目标分支');
            return;
        }
        if (sourceBranch === targetBranch) {
            message.warning('源分支和目标分支不能相同');
            return;
        }
        setStep('create');
    };

    const handleCreate = async () => {
        if (!title.trim()) {
            message.error('请输入合并标题');
            return;
        }
        setLoading(true);
        try {
            await createPullRequest(repoId, {
                title: title.trim(),
                body: description,
                head: sourceBranch,
                base: targetBranch
            });
            message.success('Pull Request 创建成功');
            onSuccess(0);
        } catch (error) {
            console.error('创建 Pull Request 失败', error);
            message.error('创建失败');
        } finally {
            setLoading(false);
        }
    };

    if (step === 'compare') {
        const canContinue = Boolean(sourceBranch && targetBranch && sourceBranch !== targetBranch);
        return (
            <div className="mx-auto max-w-7xl px-6 py-6">
                <Button type="text" icon={<ArrowLeft size={16} />} onClick={onCancel} className="mb-5 -ml-3 hover:bg-transparent hover:text-blue-600">
                    返回列表
                </Button>
                <div className="mb-6">
                    <h1 className="m-0 text-2xl font-semibold text-slate-800">创建一个新的 Pull Request</h1>
                    <p className="mt-2 text-slate-500">选择源分支和目标分支，比较最新提交后继续创建。</p>
                </div>

                <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
                    <BranchCommitCard title="源分支" branch={sourceBranch} branches={branches} commit={sourceCommit} loading={branchesLoading || sourceCommitLoading} onChange={handleSourceBranchChange} />
                    <BranchCommitCard title="目标分支" branch={targetBranch} branches={branches} commit={targetCommit} loading={branchesLoading || targetCommitLoading} onChange={handleTargetBranchChange} />
                </div>

                <div className="mt-6 flex flex-wrap items-center gap-4">
                    <Button
                        type="primary"
                        size="large"
                        icon={<GitCompareArrows size={17} />}
                        disabled={!canContinue}
                        onClick={handleContinue}
                        className="bg-[#1a7f37] hover:bg-[#156d2e]"
                    >
                        比较分支并继续
                    </Button>
                    {canContinue ? (
                        <span className="flex items-center gap-1.5 text-sm text-emerald-600"><CheckCircle2 size={16} />已选择可比较的分支</span>
                    ) : (
                        <span className="flex items-center gap-1.5 text-sm text-slate-400"><Info size={16} />请选择两个不同的分支</span>
                    )}
                </div>
            </div>
        );
    }

    return (
        <div className="mx-auto max-w-7xl px-6 py-6">
            <Button type="text" icon={<ArrowLeft size={16} />} onClick={() => setStep('compare')} className="mb-5 -ml-3 hover:bg-transparent hover:text-blue-600">
                返回分支选择
            </Button>
            <div className="mb-6 flex flex-wrap items-start justify-between gap-4">
                <div>
                    <h1 className="m-0 text-2xl font-semibold text-slate-800">创建一个新的 Pull Request</h1>
                    <p className="mt-2 flex flex-wrap items-center gap-2 text-slate-500">
                        <span className="rounded bg-slate-100 px-2 py-0.5 font-mono text-sm text-slate-700">{sourceBranch}</span>
                        <ArrowRight size={15} />
                        <span className="rounded bg-slate-100 px-2 py-0.5 font-mono text-sm text-slate-700">{targetBranch}</span>
                    </p>
                </div>
                <Alert type="success" showIcon message="分支已就绪，可创建 Pull Request" className="shrink-0" />
            </div>

            <div className="grid grid-cols-1 gap-8 lg:grid-cols-4">
                <main className="space-y-6 lg:col-span-3">
                    <div>
                        <label className="mb-2 block text-sm font-medium text-slate-700">合并标题 <span className="text-red-500">*</span></label>
                        <Input
                            size="large"
                            value={title}
                            onChange={event => {
                                setTitleTouched(true);
                                setTitle(event.target.value);
                            }}
                            placeholder="简短描述本次合并"
                        />
                        <div className="mt-2 text-xs text-slate-400">已默认带入源分支名称，可按需要修改。</div>
                    </div>

                    <div>
                        <label className="mb-2 block text-sm font-medium text-slate-700">描述（Markdown）</label>
                        <div className="overflow-hidden rounded-lg border border-slate-200">
                            <Tabs
                                activeKey={descriptionTab}
                                onChange={setDescriptionTab}
                                className="px-3 pt-1"
                                items={[
                                    { key: 'write', label: '编写' },
                                    { key: 'preview', label: '预览' }
                                ]}
                            />
                            <div className="min-h-[260px] border-t border-slate-100">
                                {descriptionTab === 'write' ? (
                                    <Input.TextArea
                                        rows={11}
                                        value={description}
                                        onChange={event => setDescription(event.target.value)}
                                        placeholder="详细描述本次合并的内容、影响范围和验证方式..."
                                        variant="borderless"
                                        className="p-4"
                                    />
                                ) : (
                                    <div className="prose max-w-none p-4 text-slate-700">
                                        {description ? <ReactMarkdown>{description}</ReactMarkdown> : <span className="text-slate-400">暂无描述内容</span>}
                                    </div>
                                )}
                            </div>
                            <div className="border-t border-slate-100 px-3 py-2 text-right text-xs text-slate-400">支持 Markdown 语法</div>
                        </div>
                    </div>

                    <div className="flex justify-end gap-3 border-t border-slate-100 pt-5">
                        <Button onClick={() => setStep('compare')}>返回修改分支</Button>
                        <Button type="primary" icon={<GitPullRequest size={16} />} onClick={handleCreate} loading={loading} className="bg-[#1a7f37] hover:bg-[#156d2e]">
                            创建 Pull Request
                        </Button>
                    </div>
                </main>

                <aside className="space-y-6">
                    <div className="border-b border-slate-100 pb-5">
                        <div className="mb-2 text-sm font-medium text-slate-700">审核人（Reviewers）</div>
                        <Select placeholder="选择审核人" mode="multiple" className="w-full" />
                        <div className="mt-2 text-xs text-slate-500">暂无建议的审核人</div>
                    </div>
                    <div className="border-b border-slate-100 pb-5">
                        <div className="mb-2 text-sm font-medium text-slate-700">指派给（Assignees）</div>
                        <Select placeholder="指派给自己" className="w-full" />
                    </div>
                    <div className="border-b border-slate-100 pb-5">
                        <div className="mb-2 text-sm font-medium text-slate-700">标签（Labels）</div>
                        <Select placeholder="添加标签" mode="multiple" className="w-full" />
                    </div>
                </aside>
            </div>
        </div>
    );
};

export default CreatePullRequest;
