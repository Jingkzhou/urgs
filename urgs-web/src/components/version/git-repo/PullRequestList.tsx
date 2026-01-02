import React, { useState } from 'react';
import { Input, Button, Select, Avatar, Dropdown, MenuProps, Tag, Pagination } from 'antd';
import { Search, Filter, Plus, GitPullRequest, GitMerge, CheckCircle, Clock } from 'lucide-react';
import PRStatusBadge, { PRStatus } from './components/PRStatusBadge';
import { GitRepository } from '@/api/version';

interface PullRequestListProps {
    repoId: number;
    onBack: () => void;
    onCreateClick: () => void;
    onPRClick: (prId: number) => void;
}

// Mock Data Types
export interface PullRequest {
    id: number;
    number: number;
    title: string;
    status: PRStatus;
    author: {
        name: string;
        avatar?: string;
    };
    createdAt: string;
    updatedAt: string;
    base: string;
    compare: string;
    commentsCount: number;
    reviewStatus?: 'approved' | 'changes_requested' | 'review_required';
    labels?: { name: string; color: string }[];
    checksStatus?: 'success' | 'failure' | 'pending';
}

const mockPRs: PullRequest[] = [
    {
        id: 1,
        number: 10,
        title: 'feat: add user authentication module',
        status: 'open',
        author: { name: 'zhangsan', avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=zhangsan' },
        createdAt: '2023-10-26T10:00:00Z',
        updatedAt: '2023-10-27T09:30:00Z',
        base: 'main',
        compare: 'feat/auth',
        commentsCount: 3,
        reviewStatus: 'review_required',
        labels: [{ name: 'feature', color: '#a2eeef' }, { name: 'backend', color: '#d4c5f9' }],
        checksStatus: 'success'
    },
    {
        id: 2,
        number: 9,
        title: 'fix: login page layout issue on mobile',
        status: 'merged',
        author: { name: 'lisi', avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=lisi' },
        createdAt: '2023-10-25T14:20:00Z',
        updatedAt: '2023-10-26T16:45:00Z',
        base: 'main',
        compare: 'fix/login-layout',
        commentsCount: 5,
        reviewStatus: 'approved',
        labels: [{ name: 'bug', color: '#d73a49' }],
        checksStatus: 'success'
    },
    {
        id: 3,
        number: 8,
        title: 'docs: update API documentation for v2 endpoints',
        status: 'merged',
        author: { name: 'wangwu', avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=wangwu' },
        createdAt: '2023-10-24T09:15:00Z',
        updatedAt: '2023-10-25T11:20:00Z',
        base: 'main',
        compare: 'docs/api-v2',
        commentsCount: 0,
        labels: [{ name: 'documentation', color: '#0075ca' }],
        checksStatus: 'success'
    },
    {
        id: 4,
        number: 11,
        title: 'WIP: refactor database schema for scalability',
        status: 'draft',
        author: { name: 'zhaoliu', avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=zhaoliu' },
        createdAt: '2023-10-27T15:00:00Z',
        updatedAt: '2023-10-27T15:00:00Z',
        base: 'main',
        compare: 'refactor/db-schema',
        commentsCount: 1,
        labels: [{ name: 'refactor', color: '#cfd3d7' }, { name: 'wip', color: '#e4e669' }],
        checksStatus: 'pending'
    },
    {
        id: 5,
        number: 7,
        title: 'feat: integrate payment gateway',
        status: 'closed',
        author: { name: 'qianqi', avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=qianqi' },
        createdAt: '2023-10-20T11:00:00Z',
        updatedAt: '2023-10-22T10:00:00Z',
        base: 'main',
        compare: 'feat/payment',
        commentsCount: 8,
        labels: [{ name: 'feature', color: '#a2eeef' }],
        checksStatus: 'failure'
    }
];

const PullRequestList: React.FC<PullRequestListProps> = ({ repoId, onBack, onCreateClick, onPRClick }) => {
    const [filterStatus, setFilterStatus] = useState<string>('all');
    const [searchText, setSearchText] = useState('');

    // Filter Logic
    const filteredPRs = mockPRs.filter(pr => {
        if (filterStatus !== 'all' && pr.status !== filterStatus) return false;
        if (searchText && !pr.title.toLowerCase().includes(searchText.toLowerCase()) && !pr.number.toString().includes(searchText)) return false;
        return true;
    });

    const stats = {
        open: mockPRs.filter(p => p.status === 'open').length,
        merged: mockPRs.filter(p => p.status === 'merged').filter(p => {
            // Mock logic: check simple date condition or just random for demo
            return true;
        }).length, // In real app, filter by date 'today'
        pending: mockPRs.filter(p => p.reviewStatus === 'review_required' && p.status === 'open').length,
    };

    const StatusFilterButton = ({ status, label, count, active }: any) => (
        <button
            onClick={() => setFilterStatus(status)}
            className={`flex items-center gap-2 px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${active
                    ? 'bg-slate-800 text-white'
                    : 'bg-white text-slate-600 hover:bg-slate-100'
                }`}
        >
            {label}
            {count !== undefined && <span className={`px-1.5 py-0.5 rounded-full text-xs ${active ? 'bg-slate-600 text-white' : 'bg-slate-100 text-slate-600'}`}>{count}</span>}
        </button>
    );

    return (
        <div className="bg-slate-50 min-h-screen -m-6 p-6">
            {/* Top Stats Area */}
            <div className="grid grid-cols-4 gap-4 mb-6">
                <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
                    <div className="text-slate-500 text-sm font-medium mb-1">开启中</div>
                    <div className="text-2xl font-bold text-slate-800 flex items-end gap-2">
                        {stats.open} <span className="text-slate-400 text-sm font-normal mb-1">Pull Requests</span>
                    </div>
                </div>
                <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
                    <div className="text-slate-500 text-sm font-medium mb-1">今日合并</div>
                    <div className="text-2xl font-bold text-green-600 flex items-end gap-2">
                        {stats.merged} <span className="text-slate-400 text-sm font-normal mb-1">Merged</span>
                    </div>
                </div>
                <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
                    <div className="text-slate-500 text-sm font-medium mb-1">待审核</div>
                    <div className="text-2xl font-bold text-orange-500 flex items-end gap-2">
                        {stats.pending} <span className="text-slate-400 text-sm font-normal mb-1">Pending</span>
                    </div>
                </div>
                <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
                    <div className="text-slate-500 text-sm font-medium mb-1">平均周期</div>
                    <div className="text-2xl font-bold text-blue-600 flex items-end gap-2">
                        1.2 <span className="text-slate-400 text-sm font-normal mb-1">天</span>
                    </div>
                </div>
            </div>

            {/* Main Content Area */}
            <div className="bg-white border border-slate-200 rounded-xl shadow-sm overflow-hidden">
                {/* Toolbar */}
                <div className="p-4 border-b border-slate-200 flex justify-between items-center bg-white sticky top-0 z-10">
                    <div className="flex items-center gap-2">
                        <div className="flex bg-slate-100 p-1 rounded-lg mr-4">
                            <StatusFilterButton status="all" label="全部" active={filterStatus === 'all'} />
                            <StatusFilterButton status="open" label="开启中" count={stats.open} active={filterStatus === 'open'} />
                            <StatusFilterButton status="closed" label="已关闭" active={filterStatus === 'closed'} />
                        </div>
                        <div className="relative">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
                            <Input
                                placeholder="搜索 PR 标题、编号或作者..."
                                className="pl-9 w-64 rounded-lg border-slate-200 hover:border-blue-400 focus:border-blue-500"
                                value={searchText}
                                onChange={e => setSearchText(e.target.value)}
                            />
                        </div>
                        <Button icon={<Filter size={14} />} className="text-slate-600 border-slate-200 rounded-lg">高级筛选</Button>
                    </div>
                    <div className="flex items-center gap-3">
                        <Select
                            defaultValue="newest"
                            style={{ width: 120 }}
                            variant="borderless"
                            className="bg-transparent hover:bg-slate-50 rounded"
                            options={[
                                { value: 'newest', label: '最新创建' },
                                { value: 'updated', label: '最近更新' },
                                { value: 'comments', label: '评论最多' },
                            ]}
                        />
                        <Button
                            type="primary"
                            icon={<Plus size={16} />}
                            className="bg-[#1a7f37] hover:bg-[#156d2e] border-none shadow-sm rounded-lg h-9 px-4 font-medium"
                            onClick={onCreateClick}
                        >
                            新建 Pull Request
                        </Button>
                    </div>
                </div>

                {/* List */}
                <div className="divide-y divide-slate-100">
                    {filteredPRs.length === 0 ? (
                        <div className="py-20 text-center text-slate-500">
                            <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-slate-50 mb-4">
                                <GitPullRequest size={32} className="text-slate-300" />
                            </div>
                            <p className="text-lg font-medium text-slate-700">没有找到匹配的 Pull Request</p>
                            <p className="text-slate-400 mt-1">尝试调整筛选条件或创建一个新的 PR</p>
                        </div>
                    ) : (
                        filteredPRs.map(pr => (
                            <div key={pr.id} className="p-4 hover:bg-slate-50 transition-colors group cursor-pointer" onClick={() => onPRClick(pr.id)}>
                                <div className="flex items-start gap-3">
                                    <div className="mt-1">
                                        {/* Status Icon Only - visual cue */}
                                        {pr.status === 'open' && <GitPullRequest size={18} className="text-[#1a7f37]" />}
                                        {pr.status === 'merged' && <GitMerge size={18} className="text-[#8250df]" />}
                                        {pr.status === 'closed' && <GitPullRequest size={18} className="text-[#cf222e]" />}
                                        {pr.status === 'draft' && <GitPullRequest size={18} className="text-slate-400" />}
                                    </div>
                                    <div className="flex-1 min-w-0">
                                        <div className="flex items-center gap-2 mb-1">
                                            <span className="font-semibold text-slate-800 text-base group-hover:text-blue-600 transition-colors truncate">
                                                {pr.title}
                                            </span>
                                            {pr.labels?.map(label => (
                                                <span
                                                    key={label.name}
                                                    className="px-2 py-0.5 rounded-full text-xs font-medium"
                                                    style={{ backgroundColor: `${label.color}30`, color: label.color }} // roughly lighter bg
                                                >
                                                    {label.name}
                                                </span>
                                            ))}
                                            {pr.status === 'draft' && (
                                                <span className="px-2 py-0.5 rounded-md bg-slate-100 text-slate-500 text-xs font-medium border border-slate-200">
                                                    Draft
                                                </span>
                                            )}
                                        </div>
                                        <div className="flex items-center gap-3 text-xs text-slate-500">
                                            <span className="font-mono text-slate-400">#{pr.number}</span>
                                            <span>
                                                <span className="font-medium text-slate-700">{pr.author.name}</span> 创建于 2 天前
                                            </span>
                                            <span className="flex items-center bg-slate-100 px-1.5 py-0.5 rounded text-slate-500">
                                                <span className="font-mono text-blue-600">{pr.base}</span>
                                                <span className="mx-1 text-slate-300">←</span>
                                                <span className="font-mono text-blue-600">{pr.compare}</span>
                                            </span>
                                            {pr.reviewStatus === 'approved' && (
                                                <span className="text-green-600 flex items-center gap-1">
                                                    <CheckCircle size={12} /> Approved
                                                </span>
                                            )}
                                            {pr.commentsCount > 0 && (
                                                <span className="flex items-center gap-1 hover:text-blue-600">
                                                    <Clock size={12} /> {pr.commentsCount}
                                                </span>
                                            )}
                                            <div className="flex -space-x-1 ml-2">
                                                <Avatar size={16} src={pr.author.avatar} className="border border-white" />
                                            </div>
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-2 self-center">
                                        {pr.checksStatus === 'success' && <CheckCircle size={16} className="text-green-500" />}
                                        {pr.checksStatus === 'failure' && <XCircle size={16} className="text-red-500" />}
                                        <PRStatusBadge status={pr.status} />
                                    </div>
                                </div>
                            </div>
                        ))
                    )}
                </div>

                {/* Pagination */}
                <div className="p-4 border-t border-slate-200 flex justify-center">
                    <Pagination defaultCurrent={1} total={50} size="small" />
                </div>
            </div>
        </div>
    );
};

export default PullRequestList;

import { XCircle } from 'lucide-react';
