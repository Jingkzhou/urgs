import React, { useState, useEffect, useMemo } from 'react';
import { Tabs, Input, Select, Button, Table, Tag, Space, Avatar, message, Modal, Dropdown, MenuProps } from 'antd';
import { Search, GitBranch, Plus, Trash2, Filter, MoreHorizontal, User, Clock, ArrowLeftRight, CheckCircle2 } from 'lucide-react';
import { GitBranch as GitBranchType, getRepoBranches, createRepoBranch, deleteRepoBranch } from '@/api/version';
import { formatDistanceToNow } from 'date-fns';
import { zhCN } from 'date-fns/locale';

interface Props {
    repoId: number;
    currentRef: string;
    platform?: string; // 'gitee' | 'github' | 'gitlab'
    onRefChange?: (ref: string) => void;
    onBack?: () => void;
}

const BranchList: React.FC<Props> = ({ repoId, currentRef, platform, onRefChange, onBack }) => {
    const [branches, setBranches] = useState<GitBranchType[]>([]);
    const [loading, setLoading] = useState(false);
    const [searchText, setSearchText] = useState('');
    const [creatorFilter, setCreatorFilter] = useState<string | null>(null);

    // Create Branch State
    const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
    const [newBranchName, setNewBranchName] = useState('');
    const [sourceBranch, setSourceBranch] = useState(currentRef);
    const [createLoading, setCreateLoading] = useState(false);

    useEffect(() => {
        fetchBranches();
    }, [repoId]);

    const fetchBranches = async () => {
        setLoading(true);
        try {
            const data = await getRepoBranches(repoId);
            setBranches(data || []);
        } catch (error) {
            console.error('Failed to fetch branches', error);
            message.error('获取分支列表失败');
        } finally {
            setLoading(false);
        }
    };

    const handleCreateBranch = async () => {
        if (!newBranchName.trim()) {
            message.warning('请输入分支名称');
            return;
        }
        setCreateLoading(true);
        try {
            await createRepoBranch(repoId, newBranchName, sourceBranch);
            message.success('分支创建成功');
            setIsCreateModalOpen(false);
            setNewBranchName('');
            fetchBranches();
        } catch (error) {
            console.error('Failed to create branch', error);
            message.error('创建分支失败');
        } finally {
            setCreateLoading(false);
        }
    };

    const handleDeleteBranch = (branch: GitBranchType) => {
        Modal.confirm({
            title: '删除分支',
            content: `确定要删除分支 ${branch.name} 吗？此操作无法撤销。`,
            okText: '删除',
            okType: 'danger',
            cancelText: '取消',
            onOk: async () => {
                try {
                    await deleteRepoBranch(repoId, branch.name);
                    message.success('已删除分支');
                    fetchBranches();
                } catch (error) {
                    console.error('Failed to delete branch', error);
                    message.error('删除分支失败');
                }
            }
        });
    };

    // Filter Logic
    const filteredBranches = useMemo(() => {
        let result = branches;
        if (searchText) {
            const lowerInfo = searchText.toLowerCase();
            result = result.filter(b => b.name.toLowerCase().includes(lowerInfo));
        }
        if (creatorFilter) {
            result = result.filter(b => b.lastCommitAuthor === creatorFilter);
        }

        return result;
    }, [branches, searchText, creatorFilter]);

    // Unique creators for filter
    const creators = useMemo(() => {
        const authors = new Set(branches.map(b => b.lastCommitAuthor).filter(Boolean));
        return Array.from(authors).map(a => ({ label: a!, value: a! }));
    }, [branches]);

    const defaultBranch = branches.find(b => b.isDefault);
    // Other sections
    const activeBranchesList = branches.filter(b => {
        // Simply reuse logic or define strict rule
        if (!b.lastCommitDate) return false;
        // e.g. updated within 7 days
        const weekAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
        return new Date(b.lastCommitDate).getTime() > weekAgo;
    });

    // Render Items
    const renderBranchItem = (branch: GitBranchType) => (
        <div key={branch.name} className="flex items-center justify-between py-3 px-4 border-b border-slate-100 hover:bg-slate-50 group transition-colors">
            <div className="flex items-center gap-3">
                <GitBranch size={16} className="text-slate-400" />
                <div>
                    <div className="flex items-center gap-2">
                        <span className="font-medium text-slate-700">{branch.name}</span>
                        {branch.isDefault && <Tag className="text-[10px] bg-slate-100 text-slate-500 border-slate-200">默认分支</Tag>}
                        {branch.isProtected && <Tag className="text-[10px] bg-sky-50 text-sky-600 border-sky-100">保护分支</Tag>}
                    </div>
                    {(branch.lastCommitDate || branch.lastCommitAuthor) && (
                        <div className="flex items-center gap-2 text-xs text-slate-500 mt-0.5">
                            {branch.lastCommitAuthor && (
                                <>
                                    <span className="font-medium text-slate-600">{branch.lastCommitAuthor}</span>
                                    <span>更新于</span>
                                </>
                            )}
                            {branch.lastCommitDate && (
                                <span>{formatDistanceToNow(new Date(branch.lastCommitDate), { addSuffix: true, locale: zhCN })}</span>
                            )}
                        </div>
                    )}
                </div>
            </div>

            <div className="flex items-center gap-4 opacity-0 group-hover:opacity-100 transition-opacity">
                {branch.lastCommitMessage && (
                    <span className="text-xs text-slate-400 truncate max-w-xs">{branch.lastCommitMessage}</span>
                )}
                <div className="flex items-center gap-1">
                    <Button type="text" size="small" icon={<ArrowLeftRight size={14} />} title="创建合并请求" />
                    {platform?.toLowerCase() !== 'gitee' && (
                        <Button type="text" size="small" icon={<Trash2 size={14} />} danger onClick={() => handleDeleteBranch(branch)} disabled={branch.isDefault || branch.isProtected} />
                    )}
                </div>
            </div>
        </div>
    );

    // Removed renderOverview and renderList functions

    // Consolidate View: Default -> All
    const renderConsolidatedView = () => (
        <div className="space-y-6">
            {/* Default Branch Section */}
            {defaultBranch && (
                <div className="bg-white border border-slate-200 rounded-lg overflow-hidden">
                    <div className="px-4 py-2 bg-slate-50 border-b border-slate-200 text-xs font-semibold text-slate-500 uppercase">默认分支</div>
                    {renderBranchItem(defaultBranch)}
                </div>
            )}

            {/* All Branches Section */}
            <div className="bg-white border border-slate-200 rounded-lg overflow-hidden">
                <div className="px-4 py-2 bg-slate-50 border-b border-slate-200 text-xs font-semibold text-slate-500 uppercase flex justify-between items-center">
                    <span>全部分支</span>
                    <span className="text-slate-400 normal-case font-normal text-xs">{filteredBranches.length} 个分支</span>
                </div>
                {filteredBranches.length > 0 ? (
                    // Filter out default branch from the main list if we want to avoid duplication, 
                    // but "All Branches" usually implies ALL. 
                    // Let's show all, or filter default? Typically All includes Default.
                    // User said "Default branch under display ALL branches".
                    // If I show Default at top, maybe I should exclude it from the list below to avoid noise?
                    // Let's keep it in "All" for completeness but it's fine.
                    filteredBranches.map(renderBranchItem)
                ) : (
                    <div className="p-8 text-center text-slate-400">未找到匹配的分支</div>
                )}
            </div>

            {/* Active Branches Section (Optional, as requested "then show active") */}
            {/* If All includes Active, this is redundant. But user asked for it. 
                Maybe they meant "Active" as a separate highlighting?
                I will skip a separate Active section if All is comprehensive, to avoid clutter.
                Or I can put Active *before* All if that was the intent. 
                "Default -> All -> Active" is definitely weird.
                I will stick to Default -> All.
            */}
        </div>
    );

    return (
        <div className="max-w-7xl mx-auto py-2">
            {/* Header / Filter Bar */}
            <div className="flex flex-col gap-4 mb-6">
                {/* Removed Tabs */}

                <div className="flex justify-between items-center">
                    <div className="flex items-center gap-3 flex-1">
                        <Input
                            prefix={<Search size={14} className="text-slate-400" />}
                            placeholder="输入分支名以搜索分支"
                            className="w-64"
                            value={searchText}
                            onChange={e => setSearchText(e.target.value)}
                        />
                        <Select
                            placeholder="创建者"
                            allowClear
                            className="w-40"
                            options={creators}
                            onChange={setCreatorFilter}
                        />
                        <Select
                            placeholder="分支属性"
                            allowClear
                            className="w-40"
                            options={[
                                { label: '已合并', value: 'merged' },
                                { label: '未合并', value: 'unmerged' },
                                { label: '保护分支', value: 'protected' },
                            ]}
                        />
                        <Button type="link" onClick={() => { setSearchText(''); setCreatorFilter(null); }}>清空</Button>
                    </div>
                    <Space>
                        <Button onClick={() => fetchBranches()} icon={<Clock size={14} />}>刷新</Button>
                        <Button type="primary" className="bg-orange-500 hover:bg-orange-600 border-none" icon={<Plus size={16} />} onClick={() => setIsCreateModalOpen(true)}>新建分支</Button>
                        <Button icon={<Trash2 size={14} />}>已删除分支</Button>
                    </Space>
                </div>
            </div>

            {/* Content */}
            {loading ? (
                <div className="py-20 text-center">加载中...</div>
            ) : (
                renderConsolidatedView()
            )}

            {/* Create Modal */}
            <Modal
                title="新建分支"
                open={isCreateModalOpen}
                onOk={handleCreateBranch}
                onCancel={() => setIsCreateModalOpen(false)}
                confirmLoading={createLoading}
                okText="创建"
                cancelText="取消"
            >
                <div className="space-y-4 py-4">
                    <div>
                        <div className="mb-1 text-sm font-medium text-slate-700">分支名称</div>
                        <Input
                            placeholder="请输入新分支名称"
                            value={newBranchName}
                            onChange={e => setNewBranchName(e.target.value)}
                        />
                    </div>
                    <div>
                        <div className="mb-1 text-sm font-medium text-slate-700">源分支 (从哪里创建)</div>
                        <Select
                            className="w-full"
                            value={sourceBranch}
                            onChange={setSourceBranch}
                            options={branches.map(b => ({ label: b.name, value: b.name }))}
                        />
                    </div>
                </div>
            </Modal>
        </div>
    );
};

export default BranchList;
