import React, { useState, useMemo } from 'react';
import { Input, Button, Tag, Space, Select, Dropdown, Tabs } from 'antd';
import { Search, GitPullRequest, Plus, ChevronDown, Tag as TagIcon, Milestone, FileText, ArrowLeft } from 'lucide-react';

const { Option } = Select;

// Pull Request 状态类型
type PRStatus = 'all' | 'open' | 'merged' | 'closed';

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
    labels?: string[];
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
                pr.title.toLowerCase().includes(lower) ||
                pr.author.toLowerCase().includes(lower)
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

    // 筛选下拉菜单
    const filterMenuItems = [
        { key: 'reviewer', label: '审查 ▾' },
        { key: 'assignee', label: '测试 ▾' },
        { key: 'creator', label: '创建者 ▾' },
        { key: 'milestone', label: '里程碑 ▾' },
        { key: 'label', label: '标签 ▾' },
        { key: 'priority', label: '优先级 ▾' },
        { key: 'sort', label: '最近合并 ▾' },
    ];

    return (
        <div className="bg-white min-h-screen">
            {/* 页面头部及返回按钮 */}
            <div className="px-6 py-4 border-b border-slate-100 flex items-center gap-4">
                <Button
                    type="text"
                    icon={<ArrowLeft size={18} />}
                    onClick={onBack}
                    className="hover:bg-slate-100"
                />
                <div className="h-4 w-px bg-slate-200" />
                <h2 className="text-lg font-bold text-slate-800 m-0 flex items-center gap-2">
                    <GitPullRequest size={20} className="text-orange-500" />
                    Pull Requests
                </h2>
            </div>

            {/* 顶部工具栏 */}
            <div className="px-6 py-4 border-b border-slate-100 bg-slate-50/50">
                <div className="flex justify-between items-center">
                    <div className="flex items-center gap-3">
                        <Select
                            defaultValue="all"
                            className="w-20"
                            bordered={false}
                        >
                            <Option value="all">全部</Option>
                        </Select>
                        <Input
                            prefix={<Search size={14} className="text-slate-400" />}
                            placeholder="搜索 pull requests"
                            className="w-80 border-slate-200"
                            value={searchText}
                            onChange={e => setSearchText(e.target.value)}
                        />
                    </div>
                    <div className="flex items-center gap-3">
                        <Button
                            icon={<TagIcon size={14} />}
                            className="text-slate-600 hover:text-blue-600 border-slate-200"
                        >
                            标签管理
                        </Button>
                        <Button
                            icon={<Milestone size={14} />}
                            className="text-slate-600 hover:text-blue-600 border-slate-200"
                        >
                            里程碑
                        </Button>
                        <Button
                            type="primary"
                            icon={<Plus size={14} />}
                            className="bg-orange-500 hover:bg-orange-600 border-none"
                            onClick={onCreatePR}
                        >
                            新建 Pull Request
                        </Button>
                    </div>
                </div>
            </div>

            {/* 状态标签栏 */}
            <div className="px-6 py-3 border-b border-slate-100 flex justify-between items-center">
                <div className="flex items-center gap-6">
                    <button
                        onClick={() => setStatusFilter('all')}
                        className={`text-sm font-medium px-1 pb-2 border-b-2 transition-colors bg-transparent cursor-pointer ${statusFilter === 'all'
                            ? 'text-blue-600 border-blue-600'
                            : 'text-slate-500 border-transparent hover:text-slate-800'
                            }`}
                    >
                        全部
                    </button>
                    <button
                        onClick={() => setStatusFilter('open')}
                        className={`text-sm font-medium px-1 pb-2 border-b-2 transition-colors bg-transparent cursor-pointer ${statusFilter === 'open'
                            ? 'text-blue-600 border-blue-600'
                            : 'text-slate-500 border-transparent hover:text-slate-800'
                            }`}
                    >
                        开启的 <span className="ml-1 text-xs bg-slate-100 text-slate-500 px-1.5 py-0.5 rounded">{counts.open}</span>
                    </button>
                    <button
                        onClick={() => setStatusFilter('merged')}
                        className={`text-sm font-medium px-1 pb-2 border-b-2 transition-colors bg-transparent cursor-pointer ${statusFilter === 'merged'
                            ? 'text-blue-600 border-blue-600'
                            : 'text-slate-500 border-transparent hover:text-slate-800'
                            }`}
                    >
                        已合并 <span className="ml-1 text-xs bg-slate-100 text-slate-500 px-1.5 py-0.5 rounded">{counts.merged}</span>
                    </button>
                    <button
                        onClick={() => setStatusFilter('closed')}
                        className={`text-sm font-medium px-1 pb-2 border-b-2 transition-colors bg-transparent cursor-pointer ${statusFilter === 'closed'
                            ? 'text-blue-600 border-blue-600'
                            : 'text-slate-500 border-transparent hover:text-slate-800'
                            }`}
                    >
                        已关闭 <span className="ml-1 text-xs bg-slate-100 text-slate-500 px-1.5 py-0.5 rounded">{counts.closed}</span>
                    </button>
                </div>

                <div className="flex items-center gap-4 text-sm text-slate-500">
                    {filterMenuItems.map(item => (
                        <button
                            key={item.key}
                            className="hover:text-blue-600 transition-colors bg-transparent border-none cursor-pointer text-slate-500"
                        >
                            {item.label}
                        </button>
                    ))}
                </div>
            </div>

            {/* 内容区域 */}
            <div className="flex-1 flex items-center justify-center bg-slate-50/30" style={{ minHeight: 'calc(100vh - 250px)' }}>
                {filteredPRs.length === 0 ? (
                    <div className="text-center py-20">
                        {/* 空状态插图 */}
                        <div className="mb-6 opacity-60">
                            <div className="relative inline-block text-slate-300">
                                <GitPullRequest size={80} strokeWidth={1} />
                            </div>
                        </div>
                        <p className="text-slate-400 text-base">没有符合条件的 Pull Request</p>
                        <Button type="primary" className="mt-4 bg-orange-500 border-none" onClick={onCreatePR}>创建第一个 Pull Request</Button>
                    </div>
                ) : (
                    <div className="w-full px-6 py-4">
                        <div className="bg-white border border-slate-200 rounded-lg overflow-hidden">
                            {filteredPRs.map((pr, idx) => (
                                <div key={pr.id} className={`py-4 hover:bg-slate-50 px-4 cursor-pointer transition-colors ${idx !== filteredPRs.length - 1 ? 'border-b border-slate-100' : ''}`}>
                                    <div className="flex items-center gap-3">
                                        <GitPullRequest
                                            size={18}
                                            className={
                                                pr.status === 'open' ? 'text-green-500' :
                                                    pr.status === 'merged' ? 'text-purple-500' : 'text-red-500'
                                            }
                                        />
                                        <span className="text-slate-800 font-medium hover:text-blue-600">{pr.title}</span>
                                        <span className="text-slate-400">#{pr.number}</span>
                                    </div>
                                    <div className="text-xs text-slate-500 mt-1 ml-7">
                                        由 <span className="font-medium text-slate-700">{pr.author}</span> 创建于 {pr.createdAt}
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
};

export default PullRequestList;
