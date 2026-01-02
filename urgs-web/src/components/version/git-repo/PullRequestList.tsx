import React, { useState, useMemo } from 'react';
import { Input, Button, Dropdown, MenuProps } from 'antd';
import {
    Search,
    GitPullRequest,
    GitMerge,
    Plus,
    ChevronDown,
    Tag as TagIcon,
    Milestone,
    XCircle,
    CheckCircle2,
    Check,
    AlertTriangle,
    MessageSquare,
    GitBranch,
    ArrowLeft,
    Filter
} from 'lucide-react';

// Pull Request 状态类型
type PRStatus = 'open' | 'merged' | 'closed';

// 视图过滤状态 (类似 GitHub 的 Tabs)
type ViewFilter = 'open' | 'closed';

type MergeState = 'clean' | 'conflict' | 'unknown';
type ChecksStatus = 'success' | 'pending' | 'failed';
type ReviewState = 'approved' | 'changes_requested' | 'review_required';

type LabelItem = {
    name: string;
    color?: string;
    textColor?: string;
    description?: string;
};

type LabelLike = LabelItem | string;

// Mock数据类型
interface PullRequest {
    id: number;
    number: number;
    title: string;
    status: PRStatus;
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
    updatedAt?: string;
}

interface Props {
    repoId: number;
    onBack?: () => void;
    onCreatePR?: () => void;
}

const PullRequestList: React.FC<Props> = ({ repoId, onBack, onCreatePR }) => {
    const [searchText, setSearchText] = useState('');
    const [viewFilter, setViewFilter] = useState<ViewFilter>('open');

    // Mock数据 - 填充一些示例数据以便展示
    const [pullRequests] = useState<PullRequest[]>([
        {
            id: 1,
            number: 45,
            title: 'Feat: Add support for OAuth2 authentication',
            status: 'open',
            author: 'johndoe',
            createdAt: '2 hours ago',
            sourceBranch: 'feat/oauth2',
            targetBranch: 'main',
            commentCount: 3,
            checksStatus: 'success',
            labels: [{ name: 'enhancement', color: 'a2eeef', textColor: '#003d3f' }, { name: 'backend', color: 'd4c5f9', textColor: '#2a0a55' }],
            reviewers: ['alice'],
            reviewState: 'approved'
        },
        {
            id: 2,
            number: 44,
            title: 'Fix: Resolve concurrent modification exception in cache',
            status: 'open',
            author: 'bobsmith',
            createdAt: '5 hours ago',
            sourceBranch: 'fix/cache-race-condition',
            targetBranch: 'main',
            checksStatus: 'failed',
            labels: [{ name: 'bug', color: 'd73a4a', textColor: '#ffffff' }, { name: 'critical', color: 'b60205', textColor: '#ffffff' }]
        },
        {
            id: 3,
            number: 42,
            title: 'Docs: Update API documentation for v2 endpoints',
            status: 'merged',
            author: 'sarah',
            createdAt: '1 day ago',
            sourceBranch: 'docs/v2-api',
            targetBranch: 'main',
            commentCount: 1,
            checksStatus: 'success',
            labels: ['documentation']
        },
        {
            id: 4,
            number: 38,
            title: 'Refactor: Improve database query performance',
            status: 'closed',
            author: 'mike',
            createdAt: '3 days ago',
            sourceBranch: 'refactor/db-query',
            targetBranch: 'main',
            checksStatus: 'success'
        }
    ]);

    // 过滤逻辑
    const filteredPRs = useMemo(() => {
        let result = pullRequests;

        // View Filter (Open vs Closed)
        if (viewFilter === 'open') {
            result = result.filter(pr => pr.status === 'open');
        } else {
            result = result.filter(pr => pr.status === 'closed' || pr.status === 'merged');
        }

        // Search Text
        if (searchText) {
            const lower = searchText.toLowerCase();
            result = result.filter(pr =>
                (pr.title || '').toLowerCase().includes(lower) ||
                (pr.author || '').toLowerCase().includes(lower) ||
                String(pr.number).includes(lower)
            );
        }

        return result;
    }, [pullRequests, viewFilter, searchText]);

    // 统计数量
    const counts = useMemo(() => ({
        open: pullRequests.filter(pr => pr.status === 'open').length,
        closed: pullRequests.filter(pr => pr.status === 'closed' || pr.status === 'merged').length,
    }), [pullRequests]);

    const normalizeLabel = (label: LabelLike): LabelItem => {
        if (typeof label === 'string') {
            return { name: label };
        }
        return label;
    };

    const StatusIcon = ({ status, draft }: { status: PRStatus, draft?: boolean }) => {
        if (status === 'open') {
            if (draft) {
                return <GitPullRequest size={16} className="text-slate-400" />;
            }
            return <GitPullRequest size={16} className="text-[#1a7f37]" />; // GitHub Open Green
        }
        if (status === 'merged') {
            return <GitMerge size={16} className="text-[#8250df]" />; // GitHub Merged Purple
        }
        return <GitPullRequest size={16} className="text-[#cf222e]" />; // GitHub Closed Red (Use PR icon for closed PRs traditionally, or XCircle)
    };

    // GitHub Button Styles
    const btnBaseClass = "bg-[#f6f8fa] border-[#d0d7de] text-[#24292f] shadow-sm hover:bg-[#f3f4f6] hover:border-[#d0d7de] transition-all text-xs font-medium px-3 h-[32px] flex items-center gap-2 rounded-md";
    const primaryBtnClass = "bg-[#1f883d] text-white border-[rgba(27,31,36,0.15)] shadow-sm hover:bg-[#1a7f37] hover:border-[rgba(27,31,36,0.15)] transition-all text-xs font-bold px-3 h-[32px] flex items-center gap-2 rounded-md";

    const filterMenu: MenuProps['items'] = [
        { key: 'author', label: '作者' },
        { key: 'label', label: '标签' },
        { key: 'projects', label: '项目' },
        { key: 'milestones', label: '里程碑' },
        { key: 'assignee', label: '指派给' },
        { key: 'sort', label: '排序' },
    ];

    return (
        <div className="min-h-screen bg-white">
            {/* Context Header with Back Button */}
            <div className="border-b border-slate-200 px-6 py-4 flex items-center gap-3 bg-white">
                <Button
                    type="text"
                    icon={<ArrowLeft size={16} />}
                    onClick={onBack}
                    className="text-slate-500 hover:text-slate-700"
                />
                <div>
                    <h2 className="text-lg font-semibold text-slate-900 m-0 leading-tight">Pull Requests</h2>
                    <div className="text-xs text-slate-500 mt-1">仓库 #{repoId}</div>
                </div>
            </div>

            <div className="px-4 md:px-8 py-6 max-w-[1280px] mx-auto">
                {/* Top Controls: Search & Actions */}
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-4">
                    <div className="flex items-center gap-2 flex-1 w-full md:max-w-3xl">
                        <Dropdown menu={{ items: filterMenu }} trigger={['click']}>
                            <button className={`${btnBaseClass} rounded-r-none border-r-0 px-3 bg-[#f6f8fa] text-slate-600`}>
                                筛选 <ChevronDown size={10} />
                            </button>
                        </Dropdown>

                        <div className="relative flex-1">
                            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                <Search size={14} className="text-slate-500" />
                            </div>
                            <input
                                type="text"
                                className="block w-full rounded-md rounded-l-none border-[#d0d7de] pl-9 py-1.5 text-sm text-[#24292f] placeholder-slate-500 focus:border-[#0969da] focus:ring-1 focus:ring-[#0969da] focus:outline-none transition-shadow shadow-sm bg-[#f6f8fa] focus:bg-white"
                                placeholder={`搜索 is:${viewFilter} `}
                                value={searchText}
                                onChange={e => setSearchText(e.target.value)}
                            />
                        </div>
                    </div>

                    <div className="flex items-center gap-2 md:gap-3 overflow-x-auto pb-1 md:pb-0">
                        <button className={btnBaseClass}>
                            <TagIcon size={14} className="text-slate-500" />
                            标签
                        </button>
                        <button className={btnBaseClass}>
                            <Milestone size={14} className="text-slate-500" />
                            里程碑
                        </button>
                        <button className={primaryBtnClass} onClick={onCreatePR}>
                            新建 Pull Request
                        </button>
                    </div>
                </div>

                {/* List Container */}
                <div className="border border-[#d0d7de] rounded-md overflow-hidden bg-white shadow-sm">
                    {/* List Header / Filter Tabs */}
                    <div className="flex items-center justify-between bg-[#f6f8fa] px-4 py-3 border-b border-[#d0d7de]">
                        <div className="flex items-center gap-4">
                            <button
                                onClick={() => setViewFilter('open')}
                                className={`flex items-center gap-1.5 text-sm font-medium transition-colors ${viewFilter === 'open' ? 'text-[#24292f]' : 'text-slate-500 hover:text-[#24292f]'
                                    }`}
                            >
                                <GitPullRequest size={16} />
                                {counts.open} 开启
                            </button>
                            <button
                                onClick={() => setViewFilter('closed')}
                                className={`flex items-center gap-1.5 text-sm font-medium transition-colors ${viewFilter === 'closed' ? 'text-[#24292f]' : 'text-slate-500 hover:text-[#24292f]'
                                    }`}
                            >
                                <Check size={16} />
                                {counts.closed} 已关闭
                            </button>
                        </div>

                        <div className="flex items-center gap-4 text-sm text-slate-500 hidden md:flex">
                            <div className="hover:text-slate-800 cursor-pointer flex items-center gap-1">
                                作者 <ChevronDown size={12} />
                            </div>
                            <div className="hover:text-slate-800 cursor-pointer flex items-center gap-1">
                                标签 <ChevronDown size={12} />
                            </div>
                            <div className="hover:text-slate-800 cursor-pointer flex items-center gap-1">
                                项目 <ChevronDown size={12} />
                            </div>
                            <div className="hover:text-slate-800 cursor-pointer flex items-center gap-1">
                                排序 <ChevronDown size={12} />
                            </div>
                        </div>
                    </div>

                    {/* List Items */}
                    <div className="divide-y divide-[#d0d7de}">
                        {filteredPRs.length === 0 ? (
                            <div className="py-16 text-center">
                                <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-slate-100 mb-3">
                                    <GitPullRequest size={24} className="text-slate-400" />
                                </div>
                                <h3 className="text-sm font-medium text-slate-900">未找到匹配的 Pull Request。</h3>
                                <p className="mt-1 text-sm text-slate-500">
                                    尝试移除一些筛选条件以查看更多结果。
                                </p>
                            </div>
                        ) : (
                            filteredPRs.map((pr) => (
                                <div key={pr.id} className="group p-3 sm:px-4 sm:py-3 hover:bg-[#f6f8fa] transition-colors flex items-start gap-2 sm:gap-3">
                                    <div className="mt-1 flex-shrink-0">
                                        <StatusIcon status={pr.status} draft={pr.draft} />
                                    </div>
                                    <div className="flex-1 min-w-0">
                                        <div className="flex items-center gap-2 flex-wrap">
                                            <a href="#" className="text-[16px] font-semibold text-[#24292f] hover:text-[#0969da] leading-snug">
                                                {pr.title}
                                            </a>
                                            {pr.draft && (
                                                <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-slate-100 text-slate-600 border border-slate-200">
                                                    草稿
                                                </span>
                                            )}
                                            {(pr.labels || []).map((label, idx) => {
                                                const l = normalizeLabel(label);
                                                return (
                                                    <span
                                                        key={idx}
                                                        className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium border"
                                                        style={{
                                                            backgroundColor: `#${l.color || 'eaeaea'}40`, // Low opacity background
                                                            borderColor: 'transparent',
                                                            color: l.textColor || '#24292f'
                                                        }}
                                                    >
                                                        {l.name}
                                                    </span>
                                                )
                                            })}
                                        </div>
                                        <div className="mt-1 text-xs text-slate-500 flex flex-wrap items-center gap-1">
                                            <span>#{pr.number}</span>
                                            <span>创建于 {pr.createdAt} 由 <span className="text-slate-700 font-medium hover:underline cursor-pointer">{pr.author}</span></span>
                                            <span className="mx-1 hidden sm:inline">•</span>
                                            <span className="flex items-center gap-1 bg-slate-100 px-1.5 py-0.5 rounded text-slate-600 border border-slate-200/50">
                                                <GitBranch size={10} />
                                                <span className="font-mono">{pr.targetBranch}</span>
                                                <span className="text-slate-400">←</span>
                                                <span className="font-mono">{pr.sourceBranch}</span>
                                            </span>
                                        </div>
                                    </div>
                                    <div className="hidden sm:flex items-center gap-4 ml-4 flex-shrink-0">
                                        {pr.checksStatus === 'success' && <CheckCircle2 size={16} className="text-[#1a7f37]" />}
                                        {pr.checksStatus === 'failed' && <XCircle size={16} className="text-[#cf222e]" />}
                                        {pr.checksStatus === 'pending' && <div className="w-3 h-3 rounded-full border-2 border-amber-500 border-t-transparent animate-spin" />}

                                        {pr.commentCount && pr.commentCount > 0 ? (
                                            <div className="flex items-center gap-1 text-slate-500 hover:text-[#0969da] cursor-pointer">
                                                <MessageSquare size={14} />
                                                <span className="text-xs font-medium">{pr.commentCount}</span>
                                            </div>
                                        ) : null}

                                        {pr.reviewers && (
                                            <div className="flex -space-x-1">
                                                {pr.reviewers.slice(0, 3).map((r, i) => (
                                                    <div key={i} className="w-5 h-5 rounded-full bg-slate-200 border border-white flex items-center justify-center text-[10px] text-slate-600 font-medium" title={r}>
                                                        {r[0].toUpperCase()}
                                                    </div>
                                                ))}
                                            </div>
                                        )}
                                    </div>
                                </div>
                            ))
                        )}
                    </div>
                </div>

                {/* Pagination placeholder */}
                {filteredPRs.length > 0 && (
                    <div className="mt-4 text-center text-xs text-slate-500">
                        提示：使用 <span className="font-mono bg-slate-100 px-1 rounded">cmd+click</span> 可以打开多个标签页。
                    </div>
                )}
            </div>
        </div>
    );
};

export default PullRequestList;
