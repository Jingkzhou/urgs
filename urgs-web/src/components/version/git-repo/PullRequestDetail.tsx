import React, { useState, useEffect } from 'react';
import { Button, Tabs, Input, Avatar, Tag, Dropdown } from 'antd';
import { ArrowLeft, GitPullRequest, GitMerge, Check, X, Clock, MessageSquare, ChevronDown, MonitorCheck, ExternalLink } from 'lucide-react';
import { message, Modal } from 'antd';
import PRStatusBadge, { PRStatus } from './components/PRStatusBadge';
import PRTimeline, { TimelineEvent } from './components/PRTimeline';
import PRDiffView from './components/PRDiffView';
import ReactMarkdown from 'react-markdown';
import {
    getPullRequest,
    getPullRequestCommits,
    getPullRequestFiles,
    mergePullRequest,
    closePullRequest,
    GitPullRequest as APIGitPullRequest,
    GitCommit,
    GitCommitDiff,
    getRepoCommits
} from '@/api/version';

interface PullRequestDetailProps {
    repoId: number;
    prId: number;
    onBack: () => void;
}


const PullRequestDetail: React.FC<PullRequestDetailProps> = ({ repoId, prId, onBack }) => {
    const [activeTab, setActiveTab] = useState('conversation');
    const [pr, setPr] = useState<APIGitPullRequest | null>(null);
    const [commits, setCommits] = useState<GitCommit[]>([]);
    const [files, setFiles] = useState<GitCommitDiff[]>([]);
    const [loading, setLoading] = useState(false);
    const [actionLoading, setActionLoading] = useState(false);

    const fetchData = async () => {
        setLoading(true);
        try {
            // 1. Fetch PR details first to get info
            const prRes = await getPullRequest(repoId, prId);
            if (!prRes) return;

            setPr(prRes);

            // 2. Fetch Commits (using PR specific API to show only source branch commits) and Files in parallel
            const [commitsRes, filesRes] = await Promise.all([
                getPullRequestCommits(repoId, prId),
                getPullRequestFiles(repoId, prId)
            ]);

            if (commitsRes) setCommits(commitsRes);
            if (filesRes) setFiles(filesRes);

        } catch (error) {
            console.error(error);
            message.error('加载 Pull Request 详情失败');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchData();
    }, [repoId, prId]);

    const handleMerge = async () => {
        Modal.confirm({
            title: '确认合并',
            content: '确定要合并此 Pull Request 吗？',
            onOk: async () => {
                setActionLoading(true);
                try {
                    await mergePullRequest(repoId, prId);
                    message.success('合并成功');
                    fetchData(); // Refresh status
                } catch (error) {
                    message.error('合并失败');
                } finally {
                    setActionLoading(false);
                }
            }
        });
    };

    const handleClose = async () => {
        Modal.confirm({
            title: '确认关闭',
            content: '确定要关闭此 Pull Request 吗？',
            okType: 'danger',
            onOk: async () => {
                setActionLoading(true);
                try {
                    await closePullRequest(repoId, prId);
                    message.success('已关闭 PR');
                    fetchData(); // Refresh status
                } catch (error) {
                    message.error('关闭失败');
                } finally {
                    setActionLoading(false);
                }
            }
        });
    };

    if (loading) return <div className="p-10 text-center">Loading...</div>;
    if (!pr) return <div className="p-10 text-center">Pull Request not found</div>;

    // Map status
    let status: PRStatus = 'open';
    const state = pr.state === 'opened' ? 'open' : pr.state;
    if (state === 'closed') status = 'closed';
    if (state === 'merged') status = 'merged';

    return (
        <div className="bg-white min-h-screen">
            {/* Header */}
            <div className="border-b border-slate-200 bg-slate-50/50 sticky top-0 z-10 backdrop-blur-sm">
                <div className="max-w-7xl mx-auto px-6 py-4">

                    <div className="flex justify-between items-start">
                        <div>
                            <div className="flex items-center gap-3 mb-2">
                                <h1 className="text-2xl font-semibold text-slate-900 m-0">{pr.title} <span className="text-slate-400 font-normal">#{pr.number}</span></h1>
                                <PRStatusBadge status={status} className="text-sm" />
                            </div>
                            <div className="flex items-center gap-2 text-slate-600 text-sm">
                                <span className="font-semibold text-slate-800">{pr.authorName}</span>
                                <span>想合并 commits 到 <span className="font-mono bg-slate-100 rounded px-1 text-slate-700">{pr.baseRef}</span></span>
                                <span>从 <span className="font-mono bg-slate-100 rounded px-1 text-slate-700">{pr.headRef}</span></span>
                            </div>
                        </div>
                        <div className="flex gap-2">
                            <Button>编辑</Button>
                            <Button danger onClick={handleClose} loading={actionLoading} disabled={status !== 'open'}>
                                关闭 PR
                            </Button>
                            <Button
                                type="primary"
                                className="bg-[#1a7f37] hover:bg-[#156d2e]"
                                icon={<GitMerge size={16} />}
                                onClick={handleMerge}
                                loading={actionLoading}
                                disabled={status !== 'open'}
                            >
                                合并 Pull Request
                            </Button>
                        </div>
                    </div>
                </div>

                {/* Tabs */}
                <div className="max-w-7xl mx-auto px-6">
                    <Tabs
                        activeKey={activeTab}
                        onChange={setActiveTab}
                        className="custom-tabs"
                        items={[
                            { label: '对话', key: 'conversation' },
                            { label: `提交 (${commits.length})`, key: 'commits' },
                            { label: `文件变更 (${files.length})`, key: 'files' },
                        ]}
                    />
                </div>
            </div>

            <div className="max-w-7xl mx-auto px-6 py-6 grid grid-cols-1 lg:grid-cols-4 gap-8">
                {/* Main Content */}
                <div className="lg:col-span-3">
                    {activeTab === 'conversation' && (
                        <div className="space-y-6">
                            {/* Description Box */}
                            <div className="border border-slate-200 rounded-lg bg-white overflow-hidden">
                                <div className="bg-slate-50 px-4 py-2 border-b border-slate-200 flex justify-between items-center">
                                    <div className="font-semibold text-slate-700 text-sm">描述</div>
                                    <Button type="text" size="small" className="text-slate-500">Edit</Button>
                                </div>
                                <div className="p-4 text-slate-800 prose prose-sm max-w-none">
                                    {/* Using description from PR */}
                                    <ReactMarkdown>{pr.body || 'No description provided.'}</ReactMarkdown>

                                </div>
                            </div>

                            {/* Timeline */}
                            {/* Timeline */}
                            <PRTimeline events={
                                commits.map(c => ({
                                    id: c.sha,
                                    type: 'commit',
                                    user: { name: c.authorName, avatar: c.authorAvatar },
                                    time: c.committedAt,
                                    sha: c.sha,
                                    content: c.message
                                } as TimelineEvent))
                            } />

                            {/* Comment Input */}
                            <div className="flex gap-4 mt-8 pt-6 border-t border-slate-200">
                                <Avatar size="large" className="mt-1">ME</Avatar>
                                <div className="flex-1">
                                    <div className="border border-slate-200 rounded-lg shadow-sm bg-white focus-within:ring-2 focus-within:ring-blue-100 focus-within:border-blue-400 transition-all overflow-hidden">
                                        <div className="bg-slate-50 border-b border-slate-200 px-2 py-1 flex gap-2 text-xs">
                                            <button className="px-2 py-1 font-medium text-slate-700 bg-white rounded shadow-sm">Write</button>
                                            <button className="px-2 py-1 text-slate-500 hover:bg-slate-100 rounded">Preview</button>
                                        </div>
                                        <Input.TextArea
                                            rows={4}
                                            placeholder="留下评论..."
                                            variant="borderless"
                                            className="p-3"
                                        />
                                        <div className="flex justify-end p-2 bg-slate-50 border-t border-slate-200">
                                            <Button type="primary" className="bg-[#1a7f37]">Comment</Button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    )}

                    {activeTab === 'files' && (
                        <PRDiffView files={files.map(f => ({
                            name: f.newPath || f.oldPath,
                            status: f.status as any, // 'added' | 'modified' | 'deleted'
                            additions: f.additions || 0,
                            deletions: f.deletions || 0,
                            diff: f.diff
                        }))} />
                    )}

                    {activeTab === 'commits' && (
                        <div className="border border-slate-200 rounded-lg overflow-hidden divide-y divide-slate-100">
                            {/* Mock Commits Table */}
                            {commits.map((commit, i) => (
                                <div key={commit.sha} className="p-4 hover:bg-slate-50 flex justify-between items-center group">
                                    <div className="flex items-center gap-3">
                                        <GitPullRequest className="text-slate-400" size={16} />
                                        <div>
                                            <div className="font-medium text-slate-700">{commit.message}</div>
                                            <div className="text-xs text-slate-500">{commit.authorName} committed on {commit.committedAt}</div>
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-2 font-mono text-sm text-slate-500">
                                        <span>{commit.sha?.substring(0, 7)}</span>
                                        <Button size="small" type="text" icon={<ExternalLink size={14} />} className="opacity-0 group-hover:opacity-100" />
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>

                {/* Sidebar */}
                <div className="space-y-6 text-sm">
                    <div className="pb-4 border-b border-slate-100">
                        <div className="text-slate-500 font-medium mb-2 flex justify-between items-center group">
                            审核人 (Reviewers)
                            <span className="text-blue-600 opacity-0 group-hover:opacity-100 cursor-pointer text-xs">编辑</span>
                        </div>
                        {pr.reviewers && pr.reviewers.length > 0 ? (
                            pr.reviewers.map((reviewer, idx) => (
                                <div key={idx} className="flex items-center gap-2 mb-2">
                                    <span className={`w-2 h-2 rounded-full ${reviewer.status === 'approved' ? 'bg-green-500' : 'bg-orange-400'}`}></span>
                                    <span className="font-medium">{reviewer.name}</span>
                                    <span className="text-slate-400 ml-auto flex items-center gap-1">
                                        {reviewer.status === 'approved' ? <Check size={12} /> : <MonitorCheck size={12} />}
                                        {reviewer.status === 'approved' ? 'Approved' : 'Pending'}
                                    </span>
                                </div>
                            ))
                        ) : (
                            <div className="text-slate-400 italic text-xs">暂无审核人</div>
                        )}
                    </div>

                    <div className="pb-4 border-b border-slate-100">
                        <div className="text-slate-500 font-medium mb-2 flex justify-between items-center group">
                            负责人 (Assignees)
                            <span className="text-blue-600 opacity-0 group-hover:opacity-100 cursor-pointer text-xs">编辑</span>
                        </div>
                        {pr.assignees && pr.assignees.length > 0 ? (
                            <div className="flex flex-wrap gap-2">
                                {pr.assignees.map((assignee, idx) => (
                                    <div key={idx} className="flex items-center gap-2">
                                        <Avatar size="small" src={assignee.avatar}>{assignee.name.substring(0, 2).toUpperCase()}</Avatar>
                                        <span>{assignee.name}</span>
                                    </div>
                                ))}
                            </div>
                        ) : (
                            <div className="text-slate-400 italic text-xs">暂无负责人</div>
                        )}
                    </div>

                    <div className="pb-4 border-b border-slate-100">
                        <div className="text-slate-500 font-medium mb-2 flex justify-between items-center group">
                            标签 (Labels)
                            <span className="text-blue-600 opacity-0 group-hover:opacity-100 cursor-pointer text-xs">编辑</span>
                        </div>
                        <div className="flex flex-wrap gap-1">
                            {pr.labels && pr.labels.length > 0 ? (
                                pr.labels.map((label, idx) => (
                                    <Tag key={idx} color={label.color || 'blue'}>{label.name}</Tag>
                                ))
                            ) : (
                                <div className="text-slate-400 italic text-xs">暂无标签</div>
                            )}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default PullRequestDetail;
