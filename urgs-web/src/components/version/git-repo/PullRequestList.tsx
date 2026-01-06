import React, { useState } from 'react';
import { Input, Button, Select, Avatar } from 'antd';
import { Search, Filter, Plus, GitPullRequest, GitMerge, Clock, ArrowLeft } from 'lucide-react';
import PRStatusBadge, { PRStatus } from './components/PRStatusBadge';
import { GitPullRequest as APIGitPullRequest, getPullRequests } from '@/api/version';
import Pagination from '../../common/Pagination';

interface PullRequestListProps {
    repoId: number;
    onBack: () => void;
    onCreateClick: () => void;
    onPRClick: (prId: number) => void;
}

const PullRequestList: React.FC<PullRequestListProps> = ({ repoId, onBack, onCreateClick, onPRClick }) => {
    const [filterStatus, setFilterStatus] = useState<string>('all');
    const [searchText, setSearchText] = useState('');
    const [loading, setLoading] = useState(false);
    const [data, setData] = useState<APIGitPullRequest[]>([]);
    const [stats, setStats] = useState({
        open: 0,
        merged: 0,
        todayMerged: 0,
        pending: 0,
        avgDays: 0,
        closed: 0
    });

    // 分页状态
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(10);

    const fetchData = async () => {
        setLoading(true);
        try {
            const res = await getPullRequests(repoId, { state: 'all', perPage: 100 });
            if (res) {
                setData(res);

                // 基础状态统计
                const open = res.filter(p => p.state === 'open' || p.state === 'opened').length;
                const merged = res.filter(p => p.state === 'merged').length;
                const closed = res.filter(p => p.state === 'closed').length;

                // 今日合并数
                const today = new Date().toDateString();
                const todayMerged = res.filter(p =>
                    p.state === 'merged' && p.mergedAt && new Date(p.mergedAt).toDateString() === today
                ).length;

                // 待审核 = 开启中的 PR
                const pending = open;

                // 平均周期（天）
                const mergedPRs = res.filter(p => p.state === 'merged' && p.mergedAt && p.createdAt);
                let avgDays = 0;
                if (mergedPRs.length > 0) {
                    const totalDays = mergedPRs.reduce((sum, p) => {
                        const created = new Date(p.createdAt).getTime();
                        const mergedTime = new Date(p.mergedAt!).getTime();
                        return sum + (mergedTime - created) / (1000 * 60 * 60 * 24);
                    }, 0);
                    avgDays = Math.round(totalDays / mergedPRs.length * 10) / 10;
                }

                setStats({ open, merged, todayMerged, pending, avgDays, closed });
            }
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    React.useEffect(() => {
        fetchData();
    }, [repoId]);

    // Filter Logic
    const filteredPRs = data.filter(pr => {
        const state = pr.state === 'opened' ? 'open' : pr.state;

        if (filterStatus !== 'all' && state !== filterStatus) return false;

        const search = searchText.toLowerCase();
        if (searchText &&
            !pr.title.toLowerCase().includes(search) &&
            !pr.number.toString().includes(search) &&
            !pr.authorName?.toLowerCase().includes(search)) return false;

        return true;
    });

    // 分页后的数据
    const paginatedPRs = filteredPRs.slice((currentPage - 1) * pageSize, currentPage * pageSize);

    // 当筛选条件变化时重置页码
    React.useEffect(() => {
        setCurrentPage(1);
    }, [filterStatus, searchText]);

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
            {/* Header */}
            <div className="border-b border-slate-200 px-6 py-4 flex items-center justify-between bg-white -mx-6 -mt-6 mb-6">
                <div className="flex items-center gap-3">
                    <Button
                        icon={<ArrowLeft size={16} />}
                        onClick={onBack}
                        className="flex items-center"
                    >
                        返回
                    </Button>
                    <h2 className="text-lg font-bold m-0 flex items-center gap-2">
                        <GitPullRequest size={20} className="text-indigo-500" />
                        Pull Request 列表 ({data.length})
                    </h2>
                </div>
                <div className="flex items-center gap-2">
                    <Button onClick={() => fetchData()} icon={<Clock size={14} />}>刷新</Button>
                </div>
            </div>

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
                        {stats.todayMerged} <span className="text-slate-400 text-sm font-normal mb-1">Merged</span>
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
                        {stats.avgDays > 0 ? stats.avgDays : '-'} <span className="text-slate-400 text-sm font-normal mb-1">天</span>
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
                        paginatedPRs.map(pr => {
                            let status: PRStatus = 'open';
                            const state = pr.state === 'opened' ? 'open' : pr.state;
                            if (state === 'closed') status = 'closed';
                            if (state === 'merged') status = 'merged';
                            if (state === 'locked') status = 'closed';

                            return (
                                <div key={pr.id} className="p-4 hover:bg-slate-50 transition-colors group cursor-pointer" onClick={() => onPRClick(pr.number)}>
                                    <div className="flex items-start gap-3">
                                        <div className="mt-1">
                                            {status === 'open' && <GitPullRequest size={18} className="text-[#1a7f37]" />}
                                            {status === 'merged' && <GitMerge size={18} className="text-[#8250df]" />}
                                            {status === 'closed' && <GitPullRequest size={18} className="text-[#cf222e]" />}
                                            {status === 'draft' && <GitPullRequest size={18} className="text-slate-400" />}
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
                                                        style={{ backgroundColor: `${label.color ? '#' + label.color : '#e5e7eb'}`, color: label.color ? '#' + label.color : '#374151' }}
                                                    >
                                                        {label.name}
                                                    </span>
                                                ))}
                                            </div>
                                            <div className="flex items-center gap-3 text-xs text-slate-500">
                                                <span className="font-mono text-slate-400">#{pr.number}</span>
                                                <span>
                                                    <span className="font-medium text-slate-700">{pr.authorName}</span> 创建于 {new Date(pr.createdAt).toLocaleDateString()}
                                                </span>
                                                <span className="flex items-center bg-slate-100 px-1.5 py-0.5 rounded text-slate-500">
                                                    <span className="font-mono text-blue-600">{pr.baseRef}</span>
                                                    <span className="mx-1 text-slate-300">←</span>
                                                    <span className="font-mono text-blue-600">{pr.headRef}</span>
                                                </span>
                                                {(pr.comments || 0) > 0 && (
                                                    <span className="flex items-center gap-1 hover:text-blue-600">
                                                        <Clock size={12} /> {pr.comments}
                                                    </span>
                                                )}
                                                <div className="flex -space-x-1 ml-2">
                                                    <Avatar size={16} src={pr.authorAvatar} className="border border-white" >{pr.authorName?.charAt(0).toUpperCase()}</Avatar>
                                                </div>
                                            </div>
                                        </div>
                                        <div className="flex items-center gap-2 self-center">
                                            <PRStatusBadge status={status} />
                                        </div>
                                    </div>
                                </div>
                            );
                        })
                    )}
                </div>

                {/* Pagination */}
                {filteredPRs.length > 0 && (
                    <div className="p-4 border-t border-slate-200">
                        <Pagination
                            current={currentPage}
                            total={filteredPRs.length}
                            pageSize={pageSize}
                            showSizeChanger
                            pageSizeOptions={[10, 20, 50, 100]}
                            onChange={(page, size) => {
                                setCurrentPage(page);
                                setPageSize(size);
                            }}
                        />
                    </div>
                )}
            </div>
        </div>
    );
};

export default PullRequestList;
