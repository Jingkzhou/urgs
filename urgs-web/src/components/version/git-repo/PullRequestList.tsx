import React, { useState, useMemo } from 'react';
import { Input, Button } from 'antd';
import {
    Search,
    GitPullRequest,
    GitMerge,
    Plus,
    ChevronDown,
    Tag as TagIcon,
    Milestone,
    ArrowLeft,
    XCircle,
    CheckCircle2,
    AlertTriangle,
    Clock,
    MessageSquare,
    GitBranch,
} from 'lucide-react';

// Pull Request 状态类型
type PRStatus = 'all' | 'open' | 'merged' | 'closed';

type MergeState = 'clean' | 'conflict' | 'unknown';
type ChecksStatus = 'success' | 'pending' | 'failed';
type ReviewState = 'approved' | 'changes_requested' | 'review_required';

type LabelItem = {
    name: string;
    color?: string;
    textColor?: string;
};

type LabelLike = LabelItem | string;

// Mock数据类型
interface PullRequest {
    id: number;
    number: number;
    title: string;
    status: 'open' | 'merged' | 'closed';
    author: string;
    createdAt: string;
    sourceBranch: string;
    targetBranch: string;
    reviewers?: string[];
    labels?: LabelLike[];
    commentCount?: number;
    checksStatus?: ChecksStatus;
    mergeState?: MergeState;
    reviewState?: ReviewState;
    draft?: boolean;
}

interface Props {
    repoId: number;
    onBack?: () => void;
    onCreatePR?: () => void;
}

const PullRequestList: React.FC<Props> = ({ repoId, onBack, onCreatePR }) => {
    const [searchText, setSearchText] = useState('');
    const [statusFilter, setStatusFilter] = useState<PRStatus>('all');

    // Mock数据 - TODO: 从API获取
    const [pullRequests] = useState<PullRequest[]>([]);

    // 过滤逻辑
    const filteredPRs = useMemo(() => {
        let result = pullRequests;

        if (statusFilter !== 'all') {
            result = result.filter(pr => pr.status === statusFilter);
        }

        if (searchText) {
            const lower = searchText.toLowerCase();
            result = result.filter(pr =>
                (pr.title || '').toLowerCase().includes(lower) ||
                (pr.author || '').toLowerCase().includes(lower)
            );
        }

        return result;
    }, [pullRequests, statusFilter, searchText]);

    // 统计数量
    const counts = useMemo(() => ({
        all: pullRequests.length,
        open: pullRequests.filter(pr => pr.status === 'open').length,
        merged: pullRequests.filter(pr => pr.status === 'merged').length,
        closed: pullRequests.filter(pr => pr.status === 'closed').length,
    }), [pullRequests]);

    const statusTabs: Array<{ key: PRStatus; label: string; count: number }> = [
        { key: 'all', label: '全部', count: counts.all },
        { key: 'open', label: '开启的', count: counts.open },
        { key: 'merged', label: '已合并', count: counts.merged },
        { key: 'closed', label: '已关闭', count: counts.closed },
    ];

    const filterActions = [
        { key: 'author', label: '作者' },
        { key: 'reviewer', label: '审查人' },
        { key: 'assignee', label: '测试' },
        { key: 'sort', label: '排序' },
    ];

    const primaryButtonClass =
        'bg-gradient-to-tr from-indigo-500 to-purple-600 border-none hover:from-indigo-600 hover:to-purple-700';
    const secondaryButtonClass =
        'border-indigo-200 text-indigo-600 hover:text-indigo-700 hover:border-indigo-300';
    const filterButtonClass =
        'inline-flex items-center gap-1 rounded-md border border-indigo-200 bg-indigo-50/40 px-2.5 py-1.5 text-xs font-medium text-indigo-600 transition hover:border-indigo-300 hover:text-indigo-700 hover:bg-indigo-50';

    const statusMeta = {
        open: {
            label: 'Open',
            icon: <GitPullRequest size={14} />,
            className: 'text-emerald-600 bg-emerald-50 border-emerald-200',
        },
        merged: {
            label: 'Merged',
            icon: <GitMerge size={14} />,
            className: 'text-violet-600 bg-violet-50 border-violet-200',
        },
        closed: {
            label: 'Closed',
            icon: <XCircle size={14} />,
            className: 'text-rose-600 bg-rose-50 border-rose-200',
        },
    };

    const mergeStateMeta: Record<MergeState, { label: string; className: string; icon: React.ReactNode }> = {
        clean: {
            label: '可合并',
            icon: <GitMerge size={12} />,
            className: 'text-emerald-600 bg-emerald-50 border-emerald-200',
        },
        conflict: {
            label: '有冲突',
            icon: <AlertTriangle size={12} />,
            className: 'text-rose-600 bg-rose-50 border-rose-200',
        },
        unknown: {
            label: '检查中',
            icon: <Clock size={12} />,
            className: 'text-slate-500 bg-slate-100 border-slate-200',
        },
    };

    const checksMeta: Record<ChecksStatus, { label: string; className: string; icon: React.ReactNode }> = {
        success: {
            label: 'Checks 通过',
            icon: <CheckCircle2 size={12} />,
            className: 'text-emerald-600',
        },
        pending: {
            label: 'Checks 进行中',
            icon: <Clock size={12} />,
            className: 'text-amber-600',
        },
        failed: {
            label: 'Checks 失败',
            icon: <XCircle size={12} />,
            className: 'text-rose-600',
        },
    };

    const reviewMeta: Record<ReviewState, { label: string; className: string; icon: React.ReactNode }> = {
        approved: {
            label: '已批准',
            icon: <CheckCircle2 size={12} />,
            className: 'text-emerald-600',
        },
        changes_requested: {
            label: '需修改',
            icon: <AlertTriangle size={12} />,
            className: 'text-rose-600',
        },
        review_required: {
            label: '待审查',
            icon: <Clock size={12} />,
            className: 'text-slate-500',
        },
    };

    const normalizeLabel = (label: LabelLike): LabelItem => {
        if (typeof label === 'string') {
            return { name: label };
        }
        return label;
    };

    const getInitials = (name: string) => {
        const trimmed = name.trim();
        if (!trimmed) {
            return '';
        }
        return trimmed
            .split(/\s+/)
            .map(part => part[0])
            .join('')
            .slice(0, 2)
            .toUpperCase();
    };

    return (
        <div className="min-h-screen bg-slate-50">
            {/* Header */}
            <div className="border-b border-slate-200/70 bg-white/90 backdrop-blur sticky top-0 z-10">
                <div className="px-6 py-4 flex items-center justify-between gap-4">
                    <div className="flex items-center gap-3">
                        <Button
                            icon={<ArrowLeft size={16} />}
                            onClick={onBack}
                            className={`flex items-center ${secondaryButtonClass}`}
                        >
                            返回
                        </Button>
                        <div>
                            <div className="flex items-center gap-2 text-lg font-semibold text-slate-900">
                                <GitPullRequest size={20} className="text-emerald-600" />
                                Pull Requests
                                <span className="text-xs font-normal text-slate-400">#{repoId}</span>
                            </div>
                            <div className="text-xs text-slate-500">合并视图 · GitHub 风格过滤</div>
                        </div>
                    </div>
                    <div className="hidden md:flex items-center gap-2 text-xs text-slate-500">
                        <GitMerge size={14} className="text-violet-500" />
                        <span>模拟合并状态展示</span>
                    </div>
                </div>
            </div>

            {/* 过滤与操作栏 */}
            <div className="px-6 py-4 border-b border-slate-100 bg-white">
                <div className="flex flex-wrap items-center gap-3">
                    <div className="flex-1 min-w-[240px] max-w-[720px]">
                        <Input
                            prefix={<Search size={14} className="text-slate-400" />}
                            placeholder="搜索或过滤 (is:open label:bug author:you)"
                            className="border-slate-200"
                            value={searchText}
                            onChange={e => setSearchText(e.target.value)}
                        />
                    </div>
                    <div className="flex items-center gap-2 flex-wrap">
                        {filterActions.map(item => (
                            <button
                                key={item.key}
                                className={filterButtonClass}
                            >
                                {item.label}
                                <ChevronDown size={12} />
                            </button>
                        ))}
                        <Button
                            icon={<TagIcon size={14} />}
                            className={secondaryButtonClass}
                        >
                            标签管理
                        </Button>
                        <Button
                            icon={<Milestone size={14} />}
                            className={secondaryButtonClass}
                        >
                            里程碑
                        </Button>
                        <Button
                            type="primary"
                            icon={<Plus size={14} />}
                            className={primaryButtonClass}
                            onClick={onCreatePR}
                        >
                            新建 Pull Request
                        </Button>
                    </div>
                </div>
            </div>

            {/* 状态标签栏 */}
            <div className="px-6 py-3 border-b border-slate-100 bg-white">
                <div className="flex items-center gap-2 flex-wrap">
                    {statusTabs.map(tab => (
                        <button
                            key={tab.key}
                            onClick={() => setStatusFilter(tab.key)}
                            className={`flex items-center gap-2 rounded-full px-3 py-1.5 text-xs font-semibold transition border ${statusFilter === tab.key
                                ? 'border-indigo-200 bg-indigo-50 text-indigo-700'
                                : 'border-transparent bg-transparent text-slate-500 hover:text-indigo-700 hover:bg-indigo-50/60'
                                }`}
                        >
                            <span>{tab.label}</span>
                            <span className="rounded-full bg-white/70 px-1.5 py-0.5 text-[10px] text-slate-500">
                                {tab.count}
                            </span>
                        </button>
                    ))}
                </div>
            </div>

            {/* 内容区域 */}
            <div className="flex-1 px-6 py-6">
                {filteredPRs.length === 0 ? (
                    <div className="text-center py-20">
                        {/* 空状态插图 */}
                        <div className="mb-6 opacity-60">
                            <div className="relative inline-block text-slate-300">
                                <GitPullRequest size={80} strokeWidth={1} />
                            </div>
                        </div>
                        <p className="text-slate-400 text-base">没有符合条件的 Pull Request</p>
                        <Button type="primary" className={`mt-4 ${primaryButtonClass}`} onClick={onCreatePR}>创建第一个 Pull Request</Button>
                    </div>
                ) : (
                    <div className="w-full">
                        <div className="bg-white border border-slate-200 rounded-xl overflow-hidden shadow-sm">
                            {filteredPRs.map((pr, idx) => {
                                const statusInfo = statusMeta[pr.status];
                                const mergeStateInfo = pr.mergeState ? mergeStateMeta[pr.mergeState] : null;
                                const checksInfo = pr.checksStatus ? checksMeta[pr.checksStatus] : null;
                                const reviewInfo = pr.reviewState ? reviewMeta[pr.reviewState] : null;

                                return (
                                    <div
                                        key={pr.id}
                                        className={`group px-5 py-4 transition-colors hover:bg-slate-50 ${idx !== filteredPRs.length - 1 ? 'border-b border-slate-100' : ''}`}
                                    >
                                        <div className="flex items-start justify-between gap-4">
                                            <div className="flex items-start gap-3 min-w-0">
                                                <div className={`mt-0.5 flex h-8 w-8 items-center justify-center rounded-full border ${statusInfo.className}`}>
                                                    {statusInfo.icon}
                                                </div>
                                                <div className="min-w-0">
                                                    <div className="flex flex-wrap items-center gap-2">
                                                        <span className="text-slate-900 font-semibold group-hover:text-blue-600 cursor-pointer">
                                                            {pr.title || '未命名 Pull Request'}
                                                        </span>
                                                        {pr.draft ? (
                                                            <span className="rounded-full border border-slate-200 bg-slate-50 px-2 py-0.5 text-[10px] font-semibold text-slate-500">
                                                                Draft
                                                            </span>
                                                        ) : null}
                                                        {(pr.labels || []).map((label, index) => {
                                                            const data = normalizeLabel(label);
                                                            const bgColor = data.color || undefined;
                                                            const textColor = data.textColor || '#1f2937';
                                                            return (
                                                                <span
                                                                    key={`${data.name}-${index}`}
                                                                    className="rounded-full border px-2 py-0.5 text-[10px] font-semibold"
                                                                    style={{
                                                                        borderColor: bgColor || '#e2e8f0',
                                                                        backgroundColor: bgColor || '#f8fafc',
                                                                        color: bgColor ? textColor : '#475569',
                                                                    }}
                                                                >
                                                                    {data.name}
                                                                </span>
                                                            );
                                                        })}
                                                    </div>
                                                    <div className="mt-1 flex flex-wrap items-center gap-3 text-xs text-slate-500">
                                                        <span>#{pr.number}</span>
                                                        <span>
                                                            由 <span className="font-semibold text-slate-700">{pr.author}</span> 创建于 {pr.createdAt}
                                                        </span>
                                                        <span className="flex items-center gap-1 text-slate-400">
                                                            <GitBranch size={12} />
                                                            {pr.sourceBranch} → {pr.targetBranch}
                                                        </span>
                                                    </div>
                                                </div>
                                            </div>
                                            <div className="flex flex-wrap items-center gap-3 text-xs text-slate-500">
                                                <span className={`inline-flex items-center gap-1 rounded-full border px-2 py-1 font-semibold ${statusInfo.className}`}>
                                                    {statusInfo.icon}
                                                    {statusInfo.label}
                                                </span>
                                                {mergeStateInfo ? (
                                                    <span className={`inline-flex items-center gap-1 rounded-full border px-2 py-1 font-semibold ${mergeStateInfo.className}`}>
                                                        {mergeStateInfo.icon}
                                                        {mergeStateInfo.label}
                                                    </span>
                                                ) : null}
                                                {checksInfo ? (
                                                    <span className={`inline-flex items-center gap-1 font-semibold ${checksInfo.className}`}>
                                                        {checksInfo.icon}
                                                        {checksInfo.label}
                                                    </span>
                                                ) : null}
                                                {reviewInfo ? (
                                                    <span className={`inline-flex items-center gap-1 font-semibold ${reviewInfo.className}`}>
                                                        {reviewInfo.icon}
                                                        {reviewInfo.label}
                                                    </span>
                                                ) : null}
                                                {typeof pr.commentCount === 'number' ? (
                                                    <span className="inline-flex items-center gap-1">
                                                        <MessageSquare size={12} />
                                                        {pr.commentCount}
                                                    </span>
                                                ) : null}
                                                {pr.reviewers && pr.reviewers.length > 0 ? (
                                                    <div className="flex -space-x-1">
                                                        {pr.reviewers.slice(0, 3).map((reviewer, reviewerIndex) => (
                                                            <div
                                                                key={`${reviewer}-${reviewerIndex}`}
                                                                title={reviewer}
                                                                className="flex h-6 w-6 items-center justify-center rounded-full border border-white bg-slate-200 text-[10px] font-semibold text-slate-700 shadow-sm"
                                                            >
                                                                {getInitials(reviewer)}
                                                            </div>
                                                        ))}
                                                    </div>
                                                ) : null}
                                            </div>
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
};

export default PullRequestList;
